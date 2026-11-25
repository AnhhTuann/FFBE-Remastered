extends Node

## Narrow autoload service: the only runtime entry point for normalized content.
## Scenes never read raw source files or JSON paths directly.

signal content_loaded(summary: Dictionary)
signal load_failed(message: String)

const CATALOG_PATH := "res://data/content_catalog.json"

var loaded: bool = false
var _catalog: Dictionary = {}
var _units: Array[UnitRecord] = []
var _units_by_id: Dictionary = {}
var _animations: Dictionary = {}
var _atlas_info: Dictionary = {}
var _settings_defaults: Dictionary = {}
var _battles: Dictionary = {}


func _ready() -> void:
	var error: Error = load_content()
	if error != OK:
		var message: String = "ContentRepository failed to load with error %d" % error
		DebugLog.error(message)
		load_failed.emit(message)


func load_content() -> Error:
	_catalog = _read_json(CATALOG_PATH)
	if _catalog.is_empty():
		return ERR_FILE_NOT_FOUND

	var files_variant: Variant = _catalog.get("files", {})
	if not files_variant is Dictionary:
		DebugLog.error("content_catalog.json has no files dictionary")
		return ERR_INVALID_DATA
	var files: Dictionary = files_variant

	var units_data: Dictionary = _read_json(str(files.get("units", "")))
	var animations_data: Dictionary = _read_json(str(files.get("animations", "")))
	var settings_data: Dictionary = _read_json(str(files.get("settings_defaults", "")))
	var battles_data: Dictionary = _read_json(str(files.get("battles", "")))
	if units_data.is_empty() or animations_data.is_empty() or settings_data.is_empty() or battles_data.is_empty():
		return ERR_FILE_NOT_FOUND

	_units.clear()
	_units_by_id.clear()
	var units_variant: Variant = units_data.get("units", [])
	if units_variant is Array:
		for entry in units_variant:
			if not entry is Dictionary:
				continue
			var record: UnitRecord = UnitRecord.from_dict(entry)
			if not record.content_id.is_valid():
				DebugLog.warn("Skipping invalid content identity: %s" % record.id)
				continue
			if _units_by_id.has(record.id):
				DebugLog.warn("Duplicate composite identity skipped: %s" % record.id)
				continue
			_units.append(record)
			_units_by_id[record.id] = record

	var animations_variant: Variant = animations_data.get("clips", {})
	if animations_variant is Dictionary:
		_animations = animations_variant.duplicate(true)
	var atlas_variant: Variant = animations_data.get("atlas", {})
	if atlas_variant is Dictionary:
		_atlas_info = atlas_variant.duplicate(true)
	var defaults_variant: Variant = settings_data.get("settings", {})
	if defaults_variant is Dictionary:
		_settings_defaults = defaults_variant.duplicate(true)

	if str(battles_data.get("fixture_marker", "")) != "SYNTHETIC_FIXTURE":
		DebugLog.error("Battle package is not marked SYNTHETIC_FIXTURE")
		return ERR_INVALID_DATA
	_battles = battles_data.duplicate(true)

	loaded = true
	DebugLog.info("Loaded %d synthetic unit records" % _units.size())
	content_loaded.emit(summary())
	return OK


func get_units() -> Array[UnitRecord]:
	return _units.duplicate()


func get_units_for_region(region: String) -> Array[UnitRecord]:
	var result: Array[UnitRecord] = []
	for unit: UnitRecord in _units:
		if unit.region == region:
			result.append(unit)
	return result


func get_unit(id: String) -> UnitRecord:
	return _units_by_id.get(id, null) as UnitRecord


func get_animation_id_for_unit(unit: UnitRecord) -> String:
	return unit.animation_id if unit != null else ""


func get_clip_names(animation_id: String) -> Array[String]:
	var result: Array[String] = []
	if not _animations.has(animation_id):
		return result
	var clips_variant: Variant = _animations.get(animation_id, {})
	if not clips_variant is Dictionary:
		return result
	var clips: Dictionary = clips_variant
	for key in clips.keys():
		result.append(str(key))
	return result


func get_animation_clip(animation_id: String, clip_name: String) -> Dictionary:
	if not _animations.has(animation_id):
		return {}
	var clips_variant: Variant = _animations.get(animation_id, {})
	if not clips_variant is Dictionary:
		return {}
	var clips: Dictionary = clips_variant
	var clip_variant: Variant = clips.get(clip_name, {})
	if not clip_variant is Dictionary:
		return {}
	return clip_variant.duplicate(true)


func get_atlas_info() -> Dictionary:
	return _atlas_info.duplicate(true)


func get_settings_defaults() -> Dictionary:
	return _settings_defaults.duplicate(true)


func get_battle_package() -> Dictionary:
	return _battles.duplicate(true)


func get_battle_combatant(id: String) -> Dictionary:
	var section_variant: Variant = _battles.get("combatants", {})
	if not section_variant is Dictionary:
		return {}
	var value: Variant = (section_variant as Dictionary).get(id, {})
	return value.duplicate(true) if value is Dictionary else {}


func get_ability_definition(id: String) -> Dictionary:
	var section_variant: Variant = _battles.get("abilities", {})
	if not section_variant is Dictionary:
		return {}
	var value: Variant = (section_variant as Dictionary).get(id, {})
	return value.duplicate(true) if value is Dictionary else {}


func get_item_definition(id: String) -> Dictionary:
	var section_variant: Variant = _battles.get("items", {})
	if not section_variant is Dictionary:
		return {}
	var value: Variant = (section_variant as Dictionary).get(id, {})
	return value.duplicate(true) if value is Dictionary else {}


func get_encounter(id: String) -> Dictionary:
	var section_variant: Variant = _battles.get("encounters", {})
	if not section_variant is Dictionary:
		return {}
	var value: Variant = (section_variant as Dictionary).get(id, {})
	return value.duplicate(true) if value is Dictionary else {}


func get_encounter_ids() -> Array[String]:
	var result: Array[String] = []
	var encounters_variant: Variant = _battles.get("encounters", {})
	if encounters_variant is Dictionary:
		for key in (encounters_variant as Dictionary).keys():
			result.append(str(key))
	result.sort()
	return result


func summary() -> Dictionary:
	return {
		"content_version": str(_catalog.get("content_version", "")),
		"fixture_marker": str(_catalog.get("fixture_marker", "")),
		"unit_count": _units.size(),
		"animation_group_count": _animations.size(),
		"encounter_count": (_battles.get("encounters", {}) as Dictionary).size(),
		"regions": ["GL", "JP"]
	}


func _read_json(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		DebugLog.error("Missing content file: %s" % path)
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		DebugLog.error("Cannot open content file: %s (error %d)" % [path, FileAccess.get_open_error()])
		return {}
	var text: String = file.get_as_text()
	file.close()

	var parser := JSON.new()
	var error: Error = parser.parse(text)
	if error != OK:
		DebugLog.error(
			"JSON parse failed for %s at line %d: %s"
			% [path, parser.get_error_line(), parser.get_error_message()]
		)
		return {}
	if not parser.data is Dictionary:
		DebugLog.error("Expected a JSON object in %s" % path)
		return {}
	return parser.data
