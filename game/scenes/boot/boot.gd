extends Control

## First scene: initializes services before presenting any UI.

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"

@onready var status_label: Label = $Layout/StatusLabel


func _ready() -> void:
	status_label.text = "Loading synthetic content..."
	if not ContentRepository.loaded:
		var error: Error = ContentRepository.load_content()
		if error != OK:
			status_label.text = "Content load failed (error %d). See logs." % error
			return

	var summary: Dictionary = ContentRepository.summary()
	status_label.text = "Loaded %d %s records" % [
		summary.get("unit_count", 0),
		summary.get("fixture_marker", "SYNTHETIC_FIXTURE")
	]
	await get_tree().create_timer(0.35).timeout
	var change_error: Error = get_tree().change_scene_to_file(MAIN_MENU_PATH)
	if change_error != OK:
		status_label.text = "Could not open main menu (error %d)" % change_error
