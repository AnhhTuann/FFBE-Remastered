extends Node

## Locale service for static UI strings and structured dynamic content.
## vi is the default locale; en and ja are supported. Missing keys fall back
## through en and then to the stable key so gaps are visible, not silent.

signal locale_changed(locale: String)

const SUPPORTED_LOCALES: Array[String] = ["vi", "en", "ja"]
const DEFAULT_LOCALE := "vi"
const FALLBACK_LOCALE := "en"

var current_locale: String = DEFAULT_LOCALE
var _dictionaries: Dictionary = {}


func _ready() -> void:
	load_dictionaries()
	var settings: Dictionary = {}
	if root_node_has_save_manager():
		settings = SaveManager.call("get_settings")
	current_locale = normalize_locale(str(settings.get("locale", DEFAULT_LOCALE)))
	# QA-only capture override. It does not write settings and is never used by
	# the normal game path; GUI evidence needs a deterministic starting locale.
	var qa_locale: String = OS.get_environment("FFBE_QA_LOCALE")
	if not qa_locale.is_empty():
		current_locale = normalize_locale(qa_locale)
	TranslationServer.set_locale(current_locale)
	DebugLog.info("LocaleManager ready (%s)" % current_locale)


func root_node_has_save_manager() -> bool:
	return get_node_or_null("/root/SaveManager") != null


func load_dictionaries() -> void:
	_dictionaries.clear()
	for locale: String in SUPPORTED_LOCALES:
		var path := "res://data/localization/%s.json" % locale
		var parsed: Variant = _read_json(path)
		if parsed is Dictionary:
			_dictionaries[locale] = (parsed as Dictionary).duplicate(true)
		else:
			DebugLog.error("Missing or invalid localization dictionary: %s" % path)
			_dictionaries[locale] = {}


func normalize_locale(locale: String) -> String:
	var tag: String = locale.strip_edges().replace("-", "_").to_lower()
	if tag.begins_with("vi"):
		return "vi"
	if tag.begins_with("ja"):
		return "ja"
	if tag.begins_with("en"):
		return "en"
	return DEFAULT_LOCALE


func supported_locales() -> Array[String]:
	return SUPPORTED_LOCALES.duplicate()


func t(key: String, args: Dictionary = {}) -> String:
	# SceneTree-based headless runners can call services before autoload _ready.
	if _dictionaries.is_empty():
		load_dictionaries()
	var text := _lookup(key, current_locale)
	if text.is_empty():
		text = _lookup(key, FALLBACK_LOCALE)
	if text.is_empty():
		text = key
	if args.is_empty():
		return text
	return text.format(args)


func _lookup(key: String, locale: String) -> String:
	if not _dictionaries.has(locale):
		return ""
	var dictionary: Dictionary = _dictionaries[locale]
	return str(dictionary.get(key, ""))


func has_key(key: String, locale: String = "") -> bool:
	if locale.is_empty():
		locale = current_locale
	return not _lookup(key, locale).is_empty()


func dictionary(locale: String = "") -> Dictionary:
	if locale.is_empty():
		locale = current_locale
	var result: Variant = _dictionaries.get(locale, {})
	return result.duplicate(true) if result is Dictionary else {}


func set_locale(locale: String, persist: bool = true) -> Error:
	var normalized := normalize_locale(locale)
	if not SUPPORTED_LOCALES.has(normalized):
		return ERR_INVALID_PARAMETER
	current_locale = normalized
	TranslationServer.set_locale(normalized)
	if persist and root_node_has_save_manager():
		var error: Error = SaveManager.call("update_settings", {"locale": normalized})
		if error != OK:
			return error
	# Autoload absolute paths are only valid while the node is inside the active
	# tree. Headless SceneTree runners call this before the first frame.
	if is_inside_tree():
		var player_state := get_node_or_null("/root/PlayerState")
		if player_state != null and player_state.has_method("set_locale"):
			player_state.call("set_locale", normalized)
	locale_changed.emit(normalized)
	return OK


func label_for(dynamic_record: Dictionary, key_field: String = "name_key") -> String:
	var key := str(dynamic_record.get(key_field, ""))
	if not key.is_empty():
		var localized := t(key)
		if localized != key:
			return localized
	var fallback := str(dynamic_record.get("display_name", ""))
	if not fallback.is_empty():
		return fallback
	return str(dynamic_record.get("id", key))


func missing_keys(locale: String) -> Array[String]:
	var reference: Dictionary = _dictionaries.get(FALLBACK_LOCALE, {})
	var target: Dictionary = _dictionaries.get(locale, {})
	var result: Array[String] = []
	for key: String in reference.keys():
		if not target.has(key) or str(target[key]).is_empty():
			result.append(key)
	result.sort()
	return result


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parser := JSON.new()
	var error: Error = parser.parse(file.get_as_text())
	file.close()
	return null if error != OK else parser.data
