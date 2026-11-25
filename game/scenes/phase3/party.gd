extends Control

## Phase 3 party management with five distinct slots, presets and battle launch.

const COLLECTION_PATH := "res://scenes/phase3/collection.tscn"
const VISION_PATH := "res://scenes/phase3/vision_card.tscn"
const BATTLE_PATH := "res://scenes/battle/battle_scene.tscn"
const TRANSIT_NAME := "selection"
const SLOT_COUNT := 5

var _party_id: String = "default"
var _working: Dictionary = {}
var _preset_option: OptionButton
var _preset_name: LineEdit
var _slot_options: Array[OptionButton] = []
var _status_label: Label
var _content: VBoxContainer
var _last_preview: String = ""


func _ready() -> void:
	theme = _make_theme()
	_party_id = _consume_party_id()
	_load_party()
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
	var header_bar := HBoxContainer.new()
	var title := Label.new()
	title.text = t("party.title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	header_bar.add_child(title)
	header_bar.add_child(_button(t("vision.title"), func() -> void: _goto(VISION_PATH)))
	header_bar.add_child(_button(t("common.back"), func() -> void: _goto(COLLECTION_PATH)))
	layout.add_child(_styled_panel(header_bar))

	var preset_row := HBoxContainer.new()
	_preset_option = OptionButton.new()
	_preset_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preset_option.item_selected.connect(func(index: int) -> void: _on_preset_selected(index))
	_preset_name = LineEdit.new()
	_preset_name.placeholder_text = t("party.preset")
	_preset_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_row.add_child(_preset_option)
	preset_row.add_child(_preset_name)
	preset_row.add_child(_button(t("party.save_preset"), func() -> void: _save_preset()))
	preset_row.add_child(_button(t("party.load_preset"), func() -> void: _load_selected_preset()))
	layout.add_child(_styled_panel(preset_row))
	_refresh_preset_options()

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


func _consume_party_id() -> String:
	var id := ""
	var transit := get_tree().root.get_node_or_null(NodePath(TRANSIT_NAME))
	if transit != null:
		id = str(transit.get_meta("party_id", ""))
		transit.queue_free()
	if id.is_empty():
		id = OS.get_environment("FFBE_QA_PARTY_ID")
	if id.is_empty():
		id = str(PlayerState.data.get("active_party", "default"))
	return id if not id.is_empty() else "default"


func _load_party() -> void:
	_working = PlayerState.get_party(_party_id)
	if _working.is_empty():
		_working = {"display_name": _party_id, "slots": [], "leader_slot": 0}
	var slots_variant: Variant = _working.get("slots", [])
	var slots: Array = slots_variant if slots_variant is Array else []
	while slots.size() < SLOT_COUNT:
		slots.append("")
	while slots.size() > SLOT_COUNT:
		slots.pop_back()
	_working["slots"] = slots
	_working["leader_slot"] = clampi(int(_working.get("leader_slot", 0)), 0, SLOT_COUNT - 1)
	if _preset_name != null:
		_preset_name.text = str(_working.get("display_name", _party_id))


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
	_slot_options.clear()

	var summary := _panel(t("party.build_summary"))
	var slot_ids: Array[String] = []
	for index: int in range(SLOT_COUNT):
		slot_ids.append(_slot_id(index))
	_line(summary, t("party.build_summary") + ": " + " ".join(slot_ids))
	_line(summary, t("party.leader") + ": " + t("party.slot") + " " + str(int(_working.get("leader_slot", 0)) + 1))

	var slots_box := _panel(t("party.slot"))
	for index: int in range(SLOT_COUNT):
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = t("party.slot") + " " + str(index + 1)
		label.custom_minimum_size = Vector2(110, 0)
		var option := OptionButton.new()
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var items: Array[Dictionary] = [{"label": t("common.none"), "value": ""}]
		for instance: Dictionary in PlayerState.owned_units():
			var id := str(instance.get("instance_id", ""))
			items.append({"label": _unit_label(id), "value": id})
		_fill_option(option, items)
		for item_index: int in range(option.item_count):
			if str(option.get_item_metadata(item_index)) == _slot_id(index):
				option.selected = item_index
				break
		option.item_selected.connect(func(item_index: int) -> void: _on_slot_changed(index, item_index))
		_slot_options.append(option)
		var leader := _button(t("party.set_leader"), func() -> void: _set_leader(index))
		leader.disabled = _slot_id(index).is_empty() or int(_working.get("leader_slot", 0)) == index
		var clear := _button(t("party.clear_slot"), func() -> void: _clear_slot(index))
		clear.disabled = _slot_id(index).is_empty()
		row.add_child(label)
		row.add_child(option)
		row.add_child(leader)
		row.add_child(clear)
		slots_box.add_child(row)

	var diagnostics := _validate()
	var validity := _panel(t("party.invalid"))
	if diagnostics.is_empty():
		_line(validity, t("common.enabled") + " " + t("party.build_summary"))
	else:
		for diagnostic: String in diagnostics:
			_line(validity, t("party.invalid") + ": " + diagnostic)

	var actions := _panel(t("party.preview"))
	actions.add_child(_button(t("party.preview"), func() -> void: _preview()))
	var launch := _button(t("party.launch"), func() -> void: _launch())
	launch.disabled = not diagnostics.is_empty()
	launch.tooltip_text = t("party.invalid") + " " + str(diagnostics.size())
	actions.add_child(launch)

	var preview_box := _panel(t("party.preview"))
	_line(preview_box, _last_preview if not _last_preview.is_empty() else t("common.none"))


func _slot_id(index: int) -> String:
	var slots: Array = _working.get("slots", [])
	if index < 0 or index >= slots.size():
		return ""
	return str(slots[index])


func _unit_label(id: String) -> String:
	var instance := PlayerState.get_unit_instance(id)
	if instance.is_empty():
		return id
	return LocaleManager.label_for(PlayerState.definition_for(instance)) + " " + id


func _fill_option(option: OptionButton, items: Array[Dictionary]) -> void:
	for item: Dictionary in items:
		var index: int = option.item_count
		option.add_item(str(item.get("label", "")))
		option.set_item_metadata(index, item.get("value", ""))
	if option.item_count > 0 and option.selected < 0:
		option.selected = 0


func _validate() -> Array[String]:
	var diagnostics: Array[String] = []
	var seen: Array[String] = []
	for index: int in range(SLOT_COUNT):
		var id := _slot_id(index)
		if id.is_empty():
			diagnostics.append(t("party.error.empty_slot", {"slot": index + 1}))
			continue
		if seen.has(id):
			diagnostics.append(t("party.error.duplicate", {"id": id}))
		seen.append(id)
		if PlayerState.get_unit_instance(id).is_empty():
			diagnostics.append(t("collection.empty") + " " + LocaleManager.diagnostic_text(id))
	if _slot_id(int(_working.get("leader_slot", 0))).is_empty():
		diagnostics.append(t("party.error.leader_missing"))
	return diagnostics


func _on_slot_changed(index: int, item_index: int) -> void:
	if index < 0 or index >= _slot_options.size():
		return
	var option := _slot_options[index]
	if item_index < 0 or item_index >= option.item_count:
		return
	var slots: Array = _working.get("slots", [])
	slots[index] = str(option.get_item_metadata(item_index))
	_working["slots"] = slots
	_last_preview = ""
	_refresh()


func _set_leader(index: int) -> void:
	if _slot_id(index).is_empty():
		return
	_working["leader_slot"] = index
	_refresh()


func _clear_slot(index: int) -> void:
	var slots: Array = _working.get("slots", [])
	slots[index] = ""
	_working["slots"] = slots
	_last_preview = ""
	_refresh()


func _refresh_preset_options() -> void:
	_preset_option.clear()
	var parties := PlayerState.parties()
	var ids: Array[String] = []
	for key: String in parties.keys():
		ids.append(key)
	ids.sort()
	for id: String in ids:
		var raw: Variant = parties.get(id, {})
		var party: Dictionary = raw if raw is Dictionary else {}
		var labeled := party.duplicate(true)
		labeled["id"] = id
		var index: int = _preset_option.item_count
		_preset_option.add_item(LocaleManager.label_for(labeled))
		_preset_option.set_item_metadata(index, id)
		if id == _party_id:
			_preset_option.selected = index
	if _preset_option.item_count > 0 and _preset_option.selected < 0:
		_preset_option.selected = 0


func _selected_preset_id() -> String:
	if _preset_option == null or _preset_option.selected < 0:
		return _party_id
	return str(_preset_option.get_item_metadata(_preset_option.selected))


func _on_preset_selected(_index: int) -> void:
	_load_selected_preset()


func _load_selected_preset() -> void:
	var id := _selected_preset_id()
	if id.is_empty() or not PlayerState.parties().has(id):
		_set_status(t("party.invalid") + " " + LocaleManager.diagnostic_text(id))
		return
	_party_id = id
	_load_party()
	PlayerState.data["active_party"] = _party_id
	PlayerState.call("commit", "parties")
	_last_preview = ""
	_refresh()


func _save_preset() -> void:
	var name := _preset_name.text.strip_edges()
	if name.is_empty():
		_set_status(t("party.preset"))
		return
	var party := _working.duplicate(true)
	if party.has("name_key"):
		party.erase("name_key")
	party["display_name"] = name
	PlayerState.set_party(name, party)
	PlayerState.data["active_party"] = name
	PlayerState.call("commit", "parties")
	_party_id = name
	_load_party()
	_refresh_preset_options()
	_refresh()
	_set_status(t("common.save") + " " + name)


func _preview() -> void:
	var diagnostics := _validate()
	if not diagnostics.is_empty():
		_set_status(t("party.invalid") + ": " + " ".join(diagnostics))
		return
	PlayerState.set_party(_party_id, _working)
	var resolved: Dictionary = {}
	if PlayerState.build_resolver != null and PlayerState.build_resolver.has_method("resolve_party"):
		resolved = _as_dict(PlayerState.build_resolver.call("resolve_party", _party_id))
	if resolved.is_empty():
		_last_preview = t("common.note") + " " + t("party.preview")
	else:
		var parts: Array[String] = []
		parts.append(t("common.enabled") + "=" + str(resolved.get("valid", false)))
		var totals: Variant = resolved.get("totals", resolved.get("stats", {}))
		parts.append(t("common.stats") + "=" + _dict_text(totals))
		parts.append(LocaleManager.diagnostic_text(_labels_text(resolved.get("diagnostics", []))))
		_last_preview = " ".join(parts)
	_refresh()
	_set_status(_last_preview)


func _launch() -> void:
	var diagnostics := _validate()
	if not diagnostics.is_empty():
		_set_status(t("party.invalid") + ": " + " ".join(diagnostics))
		return
	PlayerState.set_party(_party_id, _working)
	PlayerState.data["active_party"] = _party_id
	PlayerState.call("commit", "parties")
	var error: Error = get_tree().change_scene_to_file(BATTLE_PATH)
	if error != OK:
		_set_status(LocaleManager.diagnostic_text("error=%d" % error))


func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _dict_text(value: Variant) -> String:
	if not value is Dictionary or (value as Dictionary).is_empty():
		return t("common.none")
	var parts: Array[String] = []
	for key: String in (value as Dictionary).keys():
		parts.append(LocaleManager.identified(LocaleManager.stat_label(str(key)), str(key)) + "=" + str((value as Dictionary)[key]))
	return " ".join(parts)


func _labels_text(value: Variant) -> String:
	if not value is Array or (value as Array).is_empty():
		return t("common.none")
	var parts: Array[String] = []
	for entry: Variant in value:
		parts.append(str(entry))
	return " ".join(parts)
