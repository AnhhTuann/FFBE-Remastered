extends Control

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"

@onready var nearest_button: CheckButton = $Layout/NearestButton
@onready var debug_button: CheckButton = $Layout/DebugButton
@onready var save_button: Button = $Layout/SaveButton
@onready var back_button: Button = $Layout/BackButton
@onready var status_label: Label = $Layout/StatusLabel
@onready var path_label: Label = $Layout/PathLabel


func _ready() -> void:
	var settings: Dictionary = SaveManager.get_settings()
	nearest_button.set_pressed_no_signal(bool(settings.get("nearest_neighbor", true)))
	debug_button.set_pressed_no_signal(bool(settings.get("debug_logging", true)))
	path_label.text = "Save location: %s" % OS.get_user_data_dir()
	status_label.text = "Settings are stored under user://; no gameplay state is saved."

	nearest_button.toggled.connect(_on_nearest_toggled)
	debug_button.toggled.connect(_on_debug_toggled)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _on_nearest_toggled(pressed: bool) -> void:
	status_label.text = "Nearest-neighbour pixel filter: %s" % ("on" if pressed else "off")


func _on_debug_toggled(pressed: bool) -> void:
	DebugLog.enabled = pressed
	status_label.text = "Debug logging: %s" % ("on" if pressed else "off")


func _on_save_pressed() -> void:
	var patch: Dictionary = {
		"nearest_neighbor": nearest_button.is_pressed(),
		"debug_logging": debug_button.is_pressed()
	}
	var error: Error = SaveManager.update_settings(patch)
	if error == OK:
		status_label.text = "Settings saved."
	else:
		status_label.text = "Settings save failed (error %d)." % error


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
