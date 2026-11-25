extends Control

## Phase 3 upgrade actions. Every mutation goes through PlayerState.progression and commits.

const DETAILS_PATH := "res://scenes/phase3/character_details.tscn"
const TRANSIT_NAME := "selection"
const POT_STATS: Array[String] = ["hp", "atk", "def", "mag", "spr"]

var _selected_id: String = ""
var _status_label: Label
var _content: VBoxContainer
var _stat_option: OptionButton
var _result_label: Label
var _exp_amount: int = 0
var _pot_rules: Dictionary = {}
var _moogle_amount: int = 0
var _moogle_key: String = ""


func _ready() -> void:
	theme = _make_theme()
	_selected_id = _consume_instance_id()
	_build_background()

	var rules := ContentRepository.get_progression_rules()
	var exp_curve: Dictionary = rules.get("exp_curve", {})
	_exp_amount = maxi(1, int(exp_curve.get("base", 120)))
	_pot_rules = rules.get("stat_pots", {})
	var moogle: Dictionary = rules.get("trust_moogle", {})
	_moogle_key = str(moogle.get("id", ""))
	_moogle_amount = maxi(1, int(moogle.get("amount", 1)))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	layout.add_child(_header(t("upgrade.title"), DETAILS_PATH, _selected_id))

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)
	layout.add_child(scroll)

	_status_label = _status_label_node()
	layout.add_child(_status_label)
	_refresh()


func t(key: String, args: Dictionary = {}) -> String:
	return LocaleManager.t(key, args)


func _make_theme() -> Theme:
	var result := Theme.new()
	for theme_type: String in ["Button", "Label", "LineEdit", "OptionButton", "ItemList", "RichTextLabel"]:
		result.set_font_size("font_size", theme_type, 16)
	return result


func _build_background() -> void:
	var background := ColorRect.new()
	background.color = Color(0.043, 0.086, 0.149)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)


func _styled_panel(child: Control = null, fill: Color = Color(0.078, 0.149, 0.239)) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = Color(0.784, 0.659, 0.294)
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", box)
	if child != null:
		panel.add_child(child)
	return panel


func _body_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _status_label_node() -> Label:
	var label := _body_label()
	label.custom_minimum_size = Vector2(0, 42)
	return label


func _set_status(text: String) -> void:
	_status_label.text = text


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	return button


func _header(title: String, back_path: String, instance_id: String) -> Control:
	var bar := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 24)
	bar.add_child(label)
	bar.add_child(_button(t("common.back"), func() -> void: _goto(back_path, instance_id)))
	return _styled_panel(bar)


func _goto(path: String, instance_id: String = "") -> void:
	var old := get_tree().root.get_node_or_null(NodePath(TRANSIT_NAME))
	if old != null:
		old.queue_free()
	var transit := Node.new()
	transit.name = TRANSIT_NAME
	transit.set_meta("instance_id", instance_id)
	get_tree().root.add_child(transit)
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		transit.queue_free()
		_set_status(LocaleManager.diagnostic_text("error=%d" % error))


func _consume_instance_id() -> String:
	var id := ""
	var transit := get_tree().root.get_node_or_null(NodePath(TRANSIT_NAME))
	if transit != null:
		id = str(transit.get_meta("instance_id", ""))
		transit.queue_free()
	if id.is_empty():
		id = str(get_meta("instance_id", ""))
	var selection := get_node_or_null(NodePath("selection"))
	if id.is_empty() and selection != null:
		id = str(selection.get_meta("instance_id", ""))
		selection.queue_free()
	if id.is_empty():
		id = OS.get_environment("FFBE_QA_INSTANCE_ID")
	if id.is_empty() and not PlayerState.owned_units().is_empty():
		id = str(PlayerState.owned_units()[0].get("instance_id", ""))
	return id


func _panel(title: String) -> VBoxContainer:
	var panel := _styled_panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 18)
	box.add_child(heading)
	panel.add_child(box)
	_content.add_child(panel)
	return box


func _line(parent: VBoxContainer, text: String) -> Label:
	var label := _body_label()
	label.text = text
	parent.add_child(label)
	return label


func _refresh() -> void:
	for child: Node in _content.get_children():
		child.queue_free()
	var instance := PlayerState.get_unit_instance(_selected_id)
	if instance.is_empty():
		_line(_panel(t("collection.empty")), t("collection.empty") + " " + _selected_id)
		_set_status(t("collection.empty"))
		return
	var definition := PlayerState.definition_for(instance)

	var summary := _panel(t("upgrade.title"))
	_line(summary, LocaleManager.label_for(definition) + "    " + t("common.uid") + ": " + _selected_id)
	var rarity := str(definition.get("rarity", ""))
	_line(summary, t("common.level") + ": " + str(instance.get("level", 0)) + "    " + \
		t("upgrade.exp") + ": " + str(instance.get("exp", 0)) + "    " + \
		t("common.rarity") + ": " + LocaleManager.identified(LocaleManager.rarity_label(rarity), rarity))
	_line(summary, t("details.trust") + ": " + str(instance.get("trust", 0)) + "    " + \
		t("details.tmr") + ": " + _state(bool(instance.get("tmr_claimed", false))) + "    " + \
		t("details.stmr") + ": " + _state(bool(instance.get("stmr_claimed", false))))

	_resources_panel(instance)

	var actions := _panel(t("upgrade.result"))
	_add_action(actions, t("upgrade.gain_exp") + ": " + str(_exp_amount), t("upgrade.exp"), true,
		func() -> void: _run("gain_exp", [_selected_id, _exp_amount]))

	_stat_option = OptionButton.new()
	_stat_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pot_items: Array[Dictionary] = []
	for stat: String in POT_STATS:
		var pot: Dictionary = _pot_rules.get(stat, {})
		pot_items.append({"label": LocaleManager.stat_label(stat) + " +" + str(pot.get("amount", 0)), "value": stat})
	_fill_option(_stat_option, pot_items)
	var pot_row := HBoxContainer.new()
	pot_row.add_child(_stat_option)
	pot_row.add_child(_button(t("upgrade.use_pot"), func() -> void: _use_pot()))
	var pot_label := _body_label()
	pot_label.text = t("upgrade.pot")
	actions.add_child(pot_label)
	actions.add_child(pot_row)

	_add_action(actions, t("upgrade.convert_duplicate"), t("common.confirm"), true,
		func() -> void: _confirm_convert())
	_add_action(actions, t("upgrade.give_trust") + ": " + str(_moogle_amount), t("upgrade.trust_moogle"), true,
		func() -> void: _run("give_trust", [_selected_id, _moogle_amount]))
	_add_action(actions, t("upgrade.claim_tmr"), t("details.tmr"), true,
		func() -> void: _run("claim_tmr", [_selected_id]))
	_add_action(actions, t("upgrade.claim_stmr"), t("details.stmr"), true,
		func() -> void: _run("claim_stmr", [_selected_id]))

	var result_panel := _panel(t("upgrade.result"))
	_result_label = _body_label()
	_result_label.custom_minimum_size = Vector2(0, 48)
	result_panel.add_child(_result_label)


func _resources_panel(instance: Dictionary) -> void:
	var box := _panel(t("common.cost"))
	var resources := PlayerState.get_resources()
	var keys: Array[String] = ["gil", _moogle_key]
	for stat: String in POT_STATS:
		var pot: Dictionary = _pot_rules.get(stat, {})
		var key := str(pot.get("id", ""))
		if not key.is_empty():
			keys.append(key)
	keys.append("fragment:%s:%s@base" % [
		str(instance.get("region", "")), str(instance.get("native_id", ""))
	])
	for key: String in keys:
		if key.is_empty():
			continue
		_line(box, t("common.cost") + ": " + LocaleManager.identified(LocaleManager.resource_label(key), key) + " = " + str(resources.get(key, 0)))


func _fill_option(option: OptionButton, items: Array[Dictionary]) -> void:
	for item: Dictionary in items:
		var index: int = option.item_count
		option.add_item(str(item.get("label", "")))
		option.set_item_metadata(index, item.get("value", ""))
	if option.item_count > 0 and option.selected < 0:
		option.selected = 0


func _selected_stat() -> String:
	if _stat_option == null or _stat_option.selected < 0:
		return ""
	return str(_stat_option.get_item_metadata(_stat_option.selected))


func _add_action(parent: VBoxContainer, title: String, requirement: String, enabled: bool, action: Callable) -> void:
	var button := _button(title, action)
	button.disabled = not enabled
	button.tooltip_text = requirement
	parent.add_child(button)
	_line(parent, requirement)


func _use_pot() -> void:
	var stat := _selected_stat()
	if stat.is_empty():
		_set_status(t("common.note") + " " + t("upgrade.pot"))
		return
	_run("use_pot", [_selected_id, stat, 1])


func _confirm_convert() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = t("common.confirm")
	dialog.dialog_text = t("upgrade.convert_duplicate") + "\n" + _selected_id
	dialog.get_ok_button().text = t("common.yes")
	dialog.add_cancel_button(t("common.no"))
	dialog.confirmed.connect(func() -> void: _run("convert_duplicate", [_selected_id]))
	add_child(dialog)
	dialog.popup_centered(Vector2i(520, 220))


func _run(method: String, args: Array) -> void:
	if PlayerState.progression == null or not PlayerState.progression.has_method(method):
		_set_status(LocaleManager.diagnostic_text(method))
		return
	var result: Dictionary = _as_dict(PlayerState.progression.callv(method, args))
	if result.is_empty() or not bool(result.get("ok", false)):
		_set_status(_failure(result, method))
		return
	var message := t("upgrade.result") + " " + LocaleManager.diagnostic_text(_summary(result))
	PlayerState.call("commit", "progression")
	_refresh()
	_result_label.text = message
	_set_status(message)


func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _failure(result: Dictionary, method: String) -> String:
	var reason := str(result.get("reason", ""))
	if LocaleManager.has_token("reason", reason):
		return LocaleManager.t("common.failed") + " " + LocaleManager.reason_label(reason)
	var message := str(result.get("message", ""))
	if not message.is_empty():
		return LocaleManager.diagnostic_text(message)
	return LocaleManager.t("common.failed") + " " + LocaleManager.diagnostic_text(method)


func _summary(result: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in result.keys():
		if key == "ok" or key == "reason" or key == "message":
			continue
		parts.append(str(key) + "=" + str(result[key]))
	return " ".join(parts)


func _state(value: bool) -> String:
	return t("common.enabled") if value else t("common.disabled")
