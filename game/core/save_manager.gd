extends Node

## Versioned local persistence for settings and viewer profile state.
## No gameplay progression, inventory, or battle state is stored in M2/M3.

signal settings_changed(settings: Dictionary)
signal slot_saved(slot: int, path: String)
signal slot_loaded(slot: int, data: Dictionary)
signal save_failed(slot: int, message: String)

const SAVE_VERSION := 2
const SLOT_COUNT := 3
const SETTINGS_PATH := "user://settings.json"

var _settings: Dictionary = {}


func _ready() -> void:
	_settings = load_settings()
	DebugLog.info("SaveManager ready (format version %d)" % SAVE_VERSION)


func get_settings() -> Dictionary:
	return _settings.duplicate(true)


func update_settings(patch: Dictionary) -> Error:
	_settings.merge(patch, true)
	_settings["version"] = SAVE_VERSION
	var error: Error = atomic_write(SETTINGS_PATH, _settings)
	if error != OK:
		DebugLog.error("Settings write failed with error %d" % error)
		return error
	settings_changed.emit(get_settings())
	return OK


func load_settings() -> Dictionary:
	var defaults: Dictionary = {"nearest_neighbor": true, "debug_logging": true, "last_region": "GL", "last_unit_id": ""}
	if ContentRepository.loaded:
		var from_content: Dictionary = ContentRepository.get_settings_defaults()
		if not from_content.is_empty():
			defaults = from_content

	var result: Dictionary = _read_json_with_fallback(SETTINGS_PATH)
	if result.get("ok", false):
		var data: Dictionary = result.get("data", {})
		var stored: Variant = data.get("settings", data)
		if stored is Dictionary:
			defaults.merge(stored, true)

	DebugLog.enabled = bool(defaults.get("debug_logging", true))
	return defaults


func slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot


func has_save(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	return FileAccess.file_exists(slot_path(slot)) or FileAccess.file_exists(slot_path(slot) + ".bak")


func build_viewer_state(selected_unit_id: String, favorites: Array) -> Dictionary:
	var settings: Dictionary = get_settings()
	return {
		"version": SAVE_VERSION,
		"profile": {
			"selected_unit_id": selected_unit_id,
			"favorites": favorites.duplicate()
		},
		"settings_summary": {
			"last_region": str(settings.get("last_region", "GL")),
			"last_unit_id": selected_unit_id
		}
	}


func save_slot(slot: int, state: Dictionary) -> Error:
	if not _is_valid_slot(slot):
		return ERR_INVALID_PARAMETER
	if not validate_state(state):
		return ERR_INVALID_DATA

	var path: String = slot_path(slot)
	var error: Error = atomic_write(path, state)
	if error != OK:
		var message: String = "Slot %d write failed with error %d" % [slot, error]
		DebugLog.error(message)
		save_failed.emit(slot, message)
		return error

	slot_saved.emit(slot, path)
	return OK


func load_slot(slot: int) -> Dictionary:
	if not _is_valid_slot(slot):
		return {}

	var result: Dictionary = _read_json_with_fallback(slot_path(slot))
	if not result.get("ok", false):
		return {}

	var data: Dictionary = migrate_to_current(result.get("data", {}))
	if not validate_state(data):
		var message: String = "Slot %d contains an invalid save" % slot
		DebugLog.error(message)
		save_failed.emit(slot, message)
		return {}

	slot_loaded.emit(slot, data)
	return data


func delete_slot(slot: int) -> Error:
	if not _is_valid_slot(slot):
		return ERR_INVALID_PARAMETER
	var base: String = slot_path(slot)
	for path: String in [base, base + ".bak", base + ".tmp"]:
		if not FileAccess.file_exists(path):
			continue
		var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if error != OK:
			return error
	return OK


func migrate_to_current(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}

	var version: int = int(data.get("version", 1))
	if version > SAVE_VERSION:
		DebugLog.warn("Refusing save from newer version %d" % version)
		return {}

	var working: Dictionary = data.duplicate(true)
	while version < SAVE_VERSION:
		match version:
			1:
				working = _migrate_1_to_2(working)
			_:
				DebugLog.error("No migration available from version %d" % version)
				return {}
		version += 1
		working["version"] = version
	return working


func validate_state(data: Dictionary) -> bool:
	if data.is_empty() or int(data.get("version", 0)) != SAVE_VERSION:
		return false
	var profile_variant: Variant = data.get("profile", {})
	if not profile_variant is Dictionary:
		return false
	var profile: Dictionary = profile_variant
	if not profile.has("selected_unit_id") or not str(profile.get("selected_unit_id", "")).begins_with("unit:"):
		return false
	if not profile.has("favorites") or not (profile.get("favorites") is Array):
		return false
	return true


func atomic_write(path: String, data: Dictionary) -> Error:
	var temp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	if not file.store_string(JSON.stringify(data, "  ")):
		file.close()
		return ERR_FILE_CANT_WRITE
	file.close()

	var directory: DirAccess = DirAccess.open(path.get_base_dir())
	if directory == null:
		return DirAccess.get_open_error()

	var target_name: String = path.get_file()
	var backup_name: String = target_name + ".bak"
	var temp_name: String = temp_path.get_file()

	if directory.file_exists(target_name):
		if directory.file_exists(backup_name):
			var remove_error: Error = directory.remove(backup_name)
			if remove_error != OK:
				return remove_error
		var backup_error: Error = directory.rename(target_name, backup_name)
		if backup_error != OK:
			return backup_error

	return directory.rename(temp_name, target_name)


func _read_json_with_fallback(path: String) -> Dictionary:
	for candidate: String in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var parser := JSON.new()
		var error: Error = parser.parse(FileAccess.get_file_as_string(candidate))
		if error == OK and parser.data is Dictionary:
			return {"ok": true, "data": parser.data, "path": candidate}
		DebugLog.warn("Could not parse %s; trying backup" % candidate)
	return {"ok": false, "data": {}, "path": ""}


func _migrate_1_to_2(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var profile_variant: Variant = result.get("profile", {})
	if not profile_variant is Dictionary:
		profile_variant = {}
	var profile: Dictionary = profile_variant
	if not profile.has("selected_unit_id") and profile.has("selected_unit"):
		profile["selected_unit_id"] = profile["selected_unit"]
		profile.erase("selected_unit")
	if not profile.has("favorites"):
		profile["favorites"] = []
	result["profile"] = profile
	if not result.has("settings_summary"):
		result["settings_summary"] = {
			"last_region": "GL",
			"last_unit_id": str(profile.get("selected_unit_id", ""))
		}
	return result


func _is_valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SLOT_COUNT
