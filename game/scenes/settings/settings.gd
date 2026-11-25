extends Control

## Settings screen, including live locale switching without restarting.

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"

@onready var title_label: Label = $Layout/TitleLabel
@onready var locale_option: OptionButton = $Layout/LocaleOption
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
	_fill_locales(str(settings.get("locale", LocaleManager.current_locale)))

	nearest_button.toggled.connect(_on_nearest_toggled)
	debug_button.toggled.connect(_on_debug_toggled)
	locale_option.item_selected.connect(_on_locale_selected)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)
	LocaleManager.locale_changed.connect(_apply_locale)
	_apply_locale(LocaleManager.current_locale)


func t(key: String, args: Dictionary = {}) -> String:
	return LocaleManager.t(key, args)


func _fill_locales(selected: String) -> void:
	locale_option.clear()
	for locale: String in LocaleManager.supported_locales():
		var index: int = locale_option.item_count
		locale_option.add_item("%s (%s)" % [t("settings.locale"), locale])
		locale_option.set_item_metadata(index, locale)
		if locale == LocaleManager.normalize_locale(selected):
			locale_option.selected = index
	if locale_option.selected < 0 and locale_option.item_count > 0:
		locale_option.selected = 0


func _apply_locale(_locale: String = "") -> void:
	title_label.text = t("settings.title")
	nearest_button.text = t("settings.nearest")
	debug_button.text = t("settings.debug")
	save_button.text = t("settings.save")
	back_button.text = t("settings.back")
	path_label.text = t("settings.path", {"path": OS.get_user_data_dir()})
	status_label.text = t("settings.status")
	var selected: int = locale_option.selected
	_fill_locales(LocaleManager.current_locale)
	if selected >= 0 and selected < locale_option.item_count:
		locale_option.selected = selected


func _on_locale_selected(index: int) -> void:
	if index < 0 or index >= locale_option.item_count:
		return
	var locale := str(locale_option.get_item_metadata(index))
	var error: Error = LocaleManager.set_locale(locale, true)
	if error == OK:
		status_label.text = t("settings.locale_changed", {"locale": locale})
	else:
		status_label.text = t("settings.save_failed", {"error": error})


func _on_nearest_toggled(pressed: bool) -> void:
	status_label.text = t("settings.nearest") + ": " + _state(pressed)


func _on_debug_toggled(pressed: bool) -> void:
	DebugLog.enabled = pressed
	status_label.text = t("settings.debug") + ": " + _state(pressed)


func _state(value: bool) -> String:
	return t("common.enabled") if value else t("common.disabled")


func _on_save_pressed() -> void:
	var patch: Dictionary = {
		"nearest_neighbor": nearest_button.is_pressed(),
		"debug_logging": debug_button.is_pressed(),
		"locale": LocaleManager.current_locale
	}
	var error: Error = SaveManager.update_settings(patch)
	if error == OK:
		status_label.text = t("settings.saved")
	else:
		status_label.text = t("settings.save_failed", {"error": error})


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
