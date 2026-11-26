extends Control

## First scene: initializes services before presenting any UI.

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"
const ECONOMY_CLASS_NAME := "EconomySystem"
const ECONOMY_SCRIPT_PATHS: Array[String] = [
	"res://systems/economy_system.gd",
	"res://core/economy_system.gd",
	"res://systems/phase4/economy_system.gd"
]

@onready var status_label: Label = $Layout/StatusLabel
@onready var title_label: Label = $Layout/TitleLabel

var _offline_done: bool = false


func _ready() -> void:
	title_label.text = t("boot.title")
	status_label.text = t("boot.loading")
	if not ContentRepository.loaded:
		var error: Error = ContentRepository.load_content()
		if error != OK:
			status_label.text = t("boot.content_failed", {"error": error})
			return

	var summary: Dictionary = ContentRepository.summary()
	status_label.text = t("boot.loaded", {
		"count": summary.get("unit_count", 0),
		"marker": summary.get("fixture_marker", "SYNTHETIC_FIXTURE")
	})
	# Offline settlement is opt-in in QA or runs only when a pending payout is
	# reported. It never changes the original 0.35 s boot transition.
	var offline_summary := _settle_offline_once()
	if not offline_summary.is_empty():
		status_label.text = offline_summary
	await get_tree().create_timer(0.35).timeout
	var change_error: Error = get_tree().change_scene_to_file(MAIN_MENU_PATH)
	if change_error != OK:
		status_label.text = t("boot.open_failed", {"error": change_error})


func t(key: String, args: Dictionary = {}) -> String:
	return LocaleManager.t(key, args)


func _settle_offline_once() -> String:
	if _offline_done:
		return ""
	_offline_done = true
	var system := _economy_system()
	if system == null or not system.has_method("settle"):
		return ""
	var now := _now()
	var qa_forced := not OS.get_environment("FFBE_QA_OFFLINE_SECONDS").is_empty() or \
		not OS.get_environment("FFBE_QA_NOW_UNIX").is_empty()
	if not qa_forced:
		var status := _call(system, "status", [now])
		if status.is_empty() or not _has_pending(status):
			return ""
	var result := _call(system, "settle", [now])
	if result.is_empty() or not bool(result.get("ok", true)):
		return ""
	var data := _detail(result)
	var granted: Variant = data.get("granted", {})
	var count: int = 0
	if granted is Dictionary:
		count = (granted as Dictionary).size()
	if count <= 0:
		count = _first_int(data, ["payouts", "count", "claimed_count", "payout_count", "pending_seconds"], 0)
	if count <= 0 and not qa_forced:
		return ""
	# EconomySystem.settle() commits exactly once. Do not commit a second time.
	var seconds := _first_int(data, ["pending_seconds", "seconds", "offline_seconds", "elapsed", "elapsed_seconds"], 0)
	var qa_seconds := OS.get_environment("FFBE_QA_OFFLINE_SECONDS")
	if not qa_seconds.is_empty() and qa_seconds.is_valid_int():
		seconds = maxi(0, qa_seconds.to_int())
	return t("boot.offline_summary", {"count": count, "seconds": seconds})


func _economy_system() -> Object:
	var path := _script_path(ECONOMY_CLASS_NAME, ECONOMY_SCRIPT_PATHS)
	if path.is_empty():
		return null
	var script: Script = load(path) as Script
	if script == null:
		return null
	var instance: Variant = script.new(PlayerState)
	if instance is Object:
		return instance as Object
	return null


func _script_path(class_id: String, candidates: Array[String]) -> String:
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		if str(entry.get("class", "")) == class_id:
			var path := str(entry.get("path", ""))
			if not path.is_empty() and ResourceLoader.exists(path):
				return path
	for candidate: String in candidates:
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


func _call(system: Object, method: String, args: Array) -> Dictionary:
	if system == null or not system.has_method(method):
		return {}
	var value: Variant = system.callv(method, args)
	if value is Dictionary:
		return value as Dictionary
	return {}


func _detail(result: Dictionary) -> Dictionary:
	# Prompt 05 systems merge payload fields at the top level while leaving an
	# empty "data" dictionary. Treat that empty data as an absent wrapper.
	var data: Variant = result.get("data", {})
	if data is Dictionary and not (data as Dictionary).is_empty():
		return data as Dictionary
	return result


func _has_pending(status: Dictionary) -> bool:
	for key: String in ["pending", "pending_count", "pending_seconds", "resources", "claimable", "can_settle", "unclaimed", "payouts", "eligible"]:
		if not status.has(key):
			continue
		var value: Variant = status[key]
		if value is bool:
			if bool(value):
				return true
		elif value is Dictionary:
			if not (value as Dictionary).is_empty():
				return true
		elif value is Array:
			if not (value as Array).is_empty():
				return true
		elif _to_int(value) > 0:
			return true
	return false


func _first_int(data: Dictionary, keys: Array[String], default_value: int) -> int:
	for key: String in keys:
		if data.has(key):
			var parsed := _to_int(data[key])
			if parsed > 0:
				return parsed
	return default_value


func _to_int(value: Variant) -> int:
	if value is int or value is float:
		return int(value)
	if value is String:
		var text := value as String
		return text.to_int() if text.is_valid_int() else 0
	return 0


func _now() -> int:
	var now := Time.get_unix_time_from_system()
	var override := OS.get_environment("FFBE_QA_NOW_UNIX")
	if not override.is_empty() and override.is_valid_int():
		return maxi(0, override.to_int())
	var seconds := OS.get_environment("FFBE_QA_OFFLINE_SECONDS")
	if not seconds.is_empty() and seconds.is_valid_int():
		return now + maxi(0, seconds.to_int())
	return now
