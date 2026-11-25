extends Control

## First scene: initializes services before presenting any UI.

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"

@onready var status_label: Label = $Layout/StatusLabel
@onready var title_label: Label = $Layout/TitleLabel


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
	await get_tree().create_timer(0.35).timeout
	var change_error: Error = get_tree().change_scene_to_file(MAIN_MENU_PATH)
	if change_error != OK:
		status_label.text = t("boot.open_failed", {"error": change_error})


func t(key: String, args: Dictionary = {}) -> String:
	return LocaleManager.t(key, args)
