extends Control

## Main menu. Static copy is resolved through LocaleManager so the language can
## change without restarting the application.

const BATTLE_PATH := "res://scenes/battle/battle_scene.tscn"
const VIEWER_PATH := "res://scenes/viewer/character_viewer.tscn"
const SETTINGS_PATH := "res://scenes/settings/settings.tscn"
const COLLECTION_PATH := "res://scenes/phase3/collection.tscn"
const PARTY_PATH := "res://scenes/phase3/party.tscn"

@onready var title_label: Label = $Layout/TitleLabel
@onready var subtitle_label: Label = $Layout/SubtitleLabel
@onready var battle_button: Button = $Layout/BattleButton
@onready var collection_button: Button = $Layout/CollectionButton
@onready var party_button: Button = $Layout/PartyButton
@onready var viewer_button: Button = $Layout/ViewerButton
@onready var settings_button: Button = $Layout/SettingsButton
@onready var quit_button: Button = $Layout/QuitButton
@onready var status_label: Label = $Layout/StatusLabel


func _ready() -> void:
	battle_button.pressed.connect(_on_battle_pressed)
	collection_button.pressed.connect(func() -> void: _goto(COLLECTION_PATH))
	party_button.pressed.connect(func() -> void: _goto(PARTY_PATH))
	viewer_button.pressed.connect(_on_viewer_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	LocaleManager.locale_changed.connect(_apply_locale)
	_apply_locale(LocaleManager.current_locale)
	battle_button.grab_focus()


func t(key: String, args: Dictionary = {}) -> String:
	return LocaleManager.t(key, args)


func _apply_locale(_locale: String = "") -> void:
	title_label.text = t("menu.title")
	subtitle_label.text = t("menu.subtitle")
	battle_button.text = t("menu.battle")
	collection_button.text = t("menu.collection")
	party_button.text = t("menu.party")
	viewer_button.text = t("viewer.title")
	settings_button.text = t("settings.title")
	quit_button.text = t("menu.quit")
	var settings: Dictionary = SaveManager.get_settings()
	status_label.text = t("menu.offline_status", {"unit": str(settings.get("last_unit_id", "none"))})


func _goto(path: String) -> void:
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		status_label.text = t("common.note") + " " + str(error)


func _on_battle_pressed() -> void:
	_goto(BATTLE_PATH)


func _on_viewer_pressed() -> void:
	_goto(VIEWER_PATH)


func _on_settings_pressed() -> void:
	_goto(SETTINGS_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
