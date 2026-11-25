extends Control

const BATTLE_PATH := "res://scenes/battle/battle_scene.tscn"
const VIEWER_PATH := "res://scenes/viewer/character_viewer.tscn"
const SETTINGS_PATH := "res://scenes/settings/settings.tscn"

@onready var battle_button: Button = $Layout/BattleButton
@onready var viewer_button: Button = $Layout/ViewerButton
@onready var settings_button: Button = $Layout/SettingsButton
@onready var quit_button: Button = $Layout/QuitButton
@onready var status_label: Label = $Layout/StatusLabel


func _ready() -> void:
	battle_button.pressed.connect(_on_battle_pressed)
	viewer_button.pressed.connect(_on_viewer_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	var settings: Dictionary = SaveManager.get_settings()
	status_label.text = "Offline build · synthetic fixtures only · last unit: %s" % str(
		settings.get("last_unit_id", "none")
	)
	battle_button.grab_focus()


func _on_battle_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_PATH)


func _on_viewer_pressed() -> void:
	get_tree().change_scene_to_file(VIEWER_PATH)


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
