extends Control

## Phase 3 vision-card management: levels, party assignment, lock and sell guards.

const PARTY_PATH := "res://scenes/phase3/party.tscn"
const TRANSIT_NAME := "selection"

var _party_id: String = ""
var _cards: Array[Dictionary] = []
var _selected_uid: String = ""
var _status_label: Label
var _content: VBoxContainer
var _list: ItemList


func _ready() -> void:
	theme = _make_theme()
	_party_id = OS.get_environment("FFBE_QA_PARTY_ID")
	if _party_id.is_empty():
		_party_id = str(PlayerState.data.get("active_party", "default"))
	_build_background()

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
	layout.add_child(_header(t("vision.title"), PARTY_PATH))

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
	_load_cards()
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


func _header(title: String, back_path: String) -> Control:
	var bar := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 24)
	bar.add_child(label)
	bar.add_child(_button(t("common.back"), func() -> void: _goto(back_path)))
	return _styled_panel(bar)


func _goto(path: String) -> void:
	var old := get_tree().root.get_node_or_null(NodePath(TRANSIT_NAME))
	if old != null:
		old.queue_free()
	var transit := Node.new()
	transit.name = TRANSIT_NAME
	transit.set_meta("party_id", _party_id)
	get_tree().root.add_child(transit)
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		transit.queue_free()
		_set_status(LocaleManager.diagnostic_text("error=%d" % error))


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


func _load_cards() -> void:
	_cards = PlayerState.inventory_section("vision_cards")
	if _cards.is_empty():
		_selected_uid = ""
		return
	for entry: Dictionary in _cards:
		if str(entry.get("uid", "")) == _selected_uid:
			return
	_selected_uid = str(_cards[0].get("uid", ""))


func _refresh() -> void:
	_load_cards()
	for child: Node in _content.get_children():
		child.queue_free()
	if _cards.is_empty():
		_line(_panel(t("collection.empty")), t("collection.empty"))
		_set_status(t("collection.empty"))
		return

	var list_panel := _styled_panel()
	var list := ItemList.new()
	_list = list
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(0, 190)
	for entry: Dictionary in _cards:
		var uid := str(entry.get("uid", ""))
		var index: int = list.add_item(_item_label(entry))
		list.set_item_metadata(index, uid)
		if uid == _selected_uid:
			list.select(index)
	list.item_selected.connect(func(index: int) -> void: _on_card_selected(index))
	list_panel.add_child(list)
	_content.add_child(list_panel)

	var entry := PlayerState.find_inventory_entry(_selected_uid)
	if entry.is_empty():
		entry = _cards[0]
		_selected_uid = str(entry.get("uid", ""))
	var definition := ContentRepository.get_vision_card_definition(str(entry.get("definition_id", "")))
	var level := maxi(1, int(entry.get("level", 1)))
	var assigned := _assigned_uid() == _selected_uid

	var detail := _panel(t("vision.title"))
	_line(detail, LocaleManager.label_for(definition) + "    " + t("common.uid") + ": " + _selected_uid)
	var region := str(definition.get("region", ""))
	_line(detail, t("vision.level") + ": " + str(level) + "/" + str(definition.get("max_level", 1)) + "    " + \
		t("common.region") + ": " + LocaleManager.identified(LocaleManager.region_label(region), region) + "    " + \
		t("common.locked") + ": " + _state(bool(entry.get("locked", false))))
	_line(detail, t("party.leader") + ": " + _state(assigned) + "    " + t("equipment.restriction") + ": " + \
		LocaleManager.diagnostic_text(_party_id))
	var stats_per_level: Dictionary = definition.get("stats_per_level", {})
	for stat: String in stats_per_level.keys():
		_line(detail, t("vision.bonus") + ": " + LocaleManager.identified(LocaleManager.stat_label(stat), stat) + " +" + str(int(stats_per_level[stat]) * level))
	for passive: Variant in definition.get("passives", []):
		if passive is Dictionary:
			_line(detail, t("vision.bonus") + ": " + LocaleManager.label_for(passive as Dictionary))

	var cost_box := _panel(t("awakening.cost"))
	var costs: Dictionary = definition.get("upgrade_costs", {})
	var next_cost: Dictionary = costs.get(str(level + 1), {})
	if next_cost.is_empty():
		_line(cost_box, t("common.none"))
	else:
		for key: String in next_cost.keys():
			_line(cost_box, t("common.cost") + ": " + LocaleManager.identified(LocaleManager.resource_label(key), key) + " = " + \
				str(next_cost[key]) + "/" + str(PlayerState.get_resource(key)))

	var actions := _panel(t("common.owned"))
	var upgrade := _button(t("vision.upgrade"), func() -> void: _run("upgrade_vision_card", [_selected_uid]))
	upgrade.disabled = bool(entry.get("locked", false)) or level >= int(definition.get("max_level", 1))
	upgrade.tooltip_text = t("vision.level") + " " + str(level)
	actions.add_child(upgrade)
	actions.add_child(_button(t("vision.assign"), func() -> void: _run("assign_vision_card", [_party_id, _selected_uid])))
	var unassign := _button(t("vision.unassign"), func() -> void: _run("unassign_vision_card", [_party_id]))
	unassign.disabled = not assigned
	actions.add_child(unassign)
	actions.add_child(_button(t("equipment.lock"), func() -> void: _run("toggle_lock", [_selected_uid])))
	actions.add_child(_button(t("equipment.sell"), func() -> void: _sell_selected()))


func _on_card_selected(index: int) -> void:
	if _list != null and index >= 0 and index < _list.item_count:
		_selected_uid = str(_list.get_item_metadata(index))
	_refresh()


func _item_label(entry: Dictionary) -> String:
	var definition := ContentRepository.get_vision_card_definition(str(entry.get("definition_id", "")))
	return LocaleManager.label_for(definition) + "    " + t("vision.level") + ": " + \
		str(entry.get("level", 1)) + "    " + str(entry.get("uid", ""))


func _assigned_uid() -> String:
	var party := PlayerState.get_party(_party_id)
	for key: String in ["vision_card", "vision_card_uid"]:
		var value: Variant = party.get(key, "")
		if value is String:
			return value as String
		if value is Dictionary:
			return str((value as Dictionary).get("uid", ""))
	return ""


func _sell_selected() -> void:
	var entry := PlayerState.find_inventory_entry(_selected_uid)
	if bool(entry.get("locked", false)):
		_set_status(t("common.locked") + " " + LocaleManager.diagnostic_text(_selected_uid))
		return
	if _assigned_uid() == _selected_uid:
		_set_status(t("vision.unassign") + " " + LocaleManager.diagnostic_text(_selected_uid))
		return
	_run("sell", [_selected_uid])


func _run(method: String, args: Array) -> void:
	if PlayerState.inventory == null or not PlayerState.inventory.has_method(method):
		_set_status(LocaleManager.diagnostic_text(method))
		return
	var result: Dictionary = _as_dict(PlayerState.inventory.callv(method, args))
	if result.is_empty() or not bool(result.get("ok", false)):
		_set_status(_failure(result, method))
		return
	PlayerState.call("commit", "inventory")
	_set_status(LocaleManager.diagnostic_text(_summary(result)))
	_refresh()


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
