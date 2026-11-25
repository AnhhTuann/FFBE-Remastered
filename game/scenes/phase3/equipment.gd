extends Control

## Phase 3 equipment and materia screen. Inventory operations route through PlayerState.inventory.

const DETAILS_PATH := "res://scenes/phase3/character_details.tscn"
const TRANSIT_NAME := "selection"
const SLOTS: Array[String] = [
	"weapon", "armor", "accessory", "materia_0", "materia_1", "materia_2", "materia_3", "vision_card"
]
const FILTERS: Array[String] = ["weapon", "armor", "accessory", "materia", "vision_card"]

var _selected_id: String = ""
var _slot_filter: String = "weapon"
var _materia_index: int = 0
var _selected_uid: String = ""
var _status_label: Label
var _content: VBoxContainer
var _unit_option: OptionButton
var _filter_option: OptionButton
var _inventory_option: OptionButton


func _ready() -> void:
	theme = _make_theme()
	_selected_id = _consume_instance_id()
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
	layout.add_child(_header(t("equipment.title"), DETAILS_PATH, _selected_id))

	var unit_row := HBoxContainer.new()
	var unit_label := Label.new()
	unit_label.text = t("common.uid")
	unit_label.custom_minimum_size = Vector2(110, 0)
	_unit_option = OptionButton.new()
	_unit_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var unit_items: Array[Dictionary] = []
	for instance: Dictionary in PlayerState.owned_units():
		var id := str(instance.get("instance_id", ""))
		var definition := PlayerState.definition_for(instance)
		unit_items.append({"label": LocaleManager.label_for(definition) + " " + id, "value": id})
	_fill_option(_unit_option, unit_items)
	for index: int in range(_unit_option.item_count):
		if str(_unit_option.get_item_metadata(index)) == _selected_id:
			_unit_option.selected = index
			break
	_unit_option.item_selected.connect(func(index: int) -> void: _on_unit_changed(index))
	unit_row.add_child(unit_label)
	unit_row.add_child(_unit_option)
	layout.add_child(_styled_panel(unit_row))

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


func t(key: String) -> String:
	return LocaleManager.t(key)


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
		_set_status(t("common.note") + " " + str(error))


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


func _on_unit_changed(index: int) -> void:
	_selected_id = str(_unit_option.get_item_metadata(index))
	_selected_uid = ""
	_refresh()


func _party_id() -> String:
	var from_env := OS.get_environment("FFBE_QA_PARTY_ID")
	return from_env if not from_env.is_empty() else str(PlayerState.data.get("active_party", "default"))


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
	var summary := _panel(t("equipment.title"))
	_line(summary, LocaleManager.label_for(definition) + "    " + t("common.uid") + ": " + _selected_id)
	_line(summary, t("common.region") + ": " + str(instance.get("region", "")) + "    " + \
		t("common.role") + ": " + str(definition.get("role", "")))

	_rebuild_slots(instance)
	_rebuild_inventory(instance)
	_rebuild_stats()


func _rebuild_slots(instance: Dictionary) -> void:
	var box := _panel(t("equipment.slots"))
	var equipped: Dictionary = instance.get("equipped", {})
	for slot: String in SLOTS:
		var row := HBoxContainer.new()
		var uid := _uid_string(equipped.get(slot, ""))
		var label := _body_label()
		label.text = t("equipment.slots") + ": " + slot + " = " + (uid if not uid.is_empty() else t("common.none"))
		var unequip := _button(t("equipment.unequip"), func() -> void: _unequip_slot(slot))
		unequip.disabled = uid.is_empty()
		row.add_child(label)
		row.add_child(unequip)
		box.add_child(row)


func _rebuild_inventory(instance: Dictionary) -> void:
	var box := _panel(t("equipment.inventory"))
	var filter_row := HBoxContainer.new()
	var filter_option := OptionButton.new()
	_filter_option = filter_option
	filter_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var filter_items: Array[Dictionary] = []
	for filter: String in FILTERS:
		filter_items.append({"label": t("equipment.slots") + ": " + filter, "value": filter})
	_fill_option(filter_option, filter_items)
	for index: int in range(filter_option.item_count):
		if str(filter_option.get_item_metadata(index)) == _slot_filter:
			filter_option.selected = index
			break
	filter_option.item_selected.connect(func(index: int) -> void: _on_filter_changed(index))
	filter_row.add_child(filter_option)
	if _slot_filter == "materia":
		var materia_option := OptionButton.new()
		for index: int in range(4):
			materia_option.add_item(t("equipment.materia") + " " + str(index + 1))
			materia_option.set_item_metadata(index, index)
		materia_option.selected = clampi(_materia_index, 0, 3)
		materia_option.item_selected.connect(func(index: int) -> void: _on_materia_index_changed(index))
		filter_row.add_child(materia_option)
	box.add_child(filter_row)

	var items := _items_for_slot(_slot_filter)
	var inventory_option := OptionButton.new()
	_inventory_option = inventory_option
	inventory_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var item_items: Array[Dictionary] = []
	for entry: Dictionary in items:
		item_items.append({"label": _item_label(entry), "value": str(entry.get("uid", ""))})
	_fill_option(inventory_option, item_items)
	for index: int in range(inventory_option.item_count):
		if str(inventory_option.get_item_metadata(index)) == _selected_uid:
			inventory_option.selected = index
			break
	inventory_option.item_selected.connect(func(index: int) -> void: _on_inventory_selected(index))
	box.add_child(inventory_option)

	var entry := PlayerState.find_inventory_entry(_selected_uid)
	if entry.is_empty() and not items.is_empty():
		_selected_uid = str(items[0].get("uid", ""))
		entry = PlayerState.find_inventory_entry(_selected_uid)
	if entry.is_empty():
		_line(box, t("equipment.no_item"))
	else:
		var definition := _definition_for_item(entry)
		_line(box, LocaleManager.label_for(definition) + "    " + t("common.uid") + ": " + _selected_uid)
		_line(box, t("common.stats") + ": " + _dict_text(definition.get("stats", {})))
		_line(box, t("common.abilities") + ": " + _labels_text(definition.get("passives", [])))
		_line(box, t("equipment.restriction") + ": " + str(definition.get("restrictions", {})))
		_line(box, t("equipment.unique") + ": " + _state(bool(definition.get("unique", false))) + "    " + \
			t("common.locked") + ": " + _state(bool(entry.get("locked", false))))
		var actions := HBoxContainer.new()
		actions.add_child(_button(t("equipment.equip"), func() -> void: _equip_selected()))
		actions.add_child(_button(t("equipment.lock"), func() -> void: _run_inventory("toggle_lock", [_selected_uid])))
		actions.add_child(_button(t("equipment.sell"), func() -> void: _sell_selected()))
		box.add_child(actions)
	_line(box, t("common.note") + ": " + str(instance.get("equipped", {})))


func _rebuild_stats() -> void:
	var box := _panel(t("common.stats"))
	var resolved: Dictionary = {}
	if PlayerState.build_resolver != null and PlayerState.build_resolver.has_method("resolve_unit"):
		resolved = _as_dict(PlayerState.build_resolver.call("resolve_unit", _selected_id, _party_id(), true))
	if resolved.is_empty():
		_line(box, t("common.note") + " " + t("common.stats"))
		return
	_line(box, t("common.stats") + ": " + _dict_text(resolved.get("stats", {})))
	_line(box, t("common.abilities") + ": " + _labels_text(resolved.get("passives", [])))
	_line(box, t("equipment.restriction") + ": " + _labels_text(resolved.get("restrictions", [])))
	_line(box, t("common.provenance") + ": " + _labels_text(resolved.get("labels", [])))
	_line(box, t("common.note") + ": " + _labels_text(resolved.get("diagnostics", [])))


func _on_filter_changed(index: int) -> void:
	if _filter_option != null and index >= 0 and index < _filter_option.item_count:
		_slot_filter = str(_filter_option.get_item_metadata(index))
	_selected_uid = ""
	_refresh()


func _on_materia_index_changed(index: int) -> void:
	_materia_index = clampi(index, 0, 3)
	_refresh()


func _on_inventory_selected(index: int) -> void:
	if _inventory_option != null and index >= 0 and index < _inventory_option.item_count:
		_selected_uid = str(_inventory_option.get_item_metadata(index))
	_refresh()


func _items_for_slot(filter: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if PlayerState.inventory != null and PlayerState.inventory.has_method("inventory_for_slot"):
		var value: Variant = PlayerState.inventory.call("inventory_for_slot", filter)
		if value is Array:
			for raw: Variant in value:
				if raw is Dictionary:
					result.append(raw as Dictionary)
	if not result.is_empty():
		return result
	var section := "equipment"
	if filter == "materia":
		section = "materia"
	elif filter == "vision_card":
		section = "vision_cards"
	for entry: Dictionary in PlayerState.inventory_section(section):
		if filter == "weapon" or filter == "armor" or filter == "accessory":
			var definition := _definition_for_item(entry)
			if str(definition.get("slots", [])).find(filter) < 0:
				continue
		result.append(entry)
	return result


func _definition_for_item(entry: Dictionary) -> Dictionary:
	var definition_id := str(entry.get("definition_id", ""))
	if definition_id.begins_with("materia:"):
		return ContentRepository.get_materia_definition(definition_id)
	if definition_id.begins_with("vision_card:"):
		return ContentRepository.get_vision_card_definition(definition_id)
	return ContentRepository.get_equipment_definition(definition_id)


func _item_label(entry: Dictionary) -> String:
	return LocaleManager.label_for(_definition_for_item(entry)) + "    " + str(entry.get("uid", ""))


func _fill_option(option: OptionButton, items: Array[Dictionary]) -> void:
	for item: Dictionary in items:
		var index: int = option.item_count
		option.add_item(str(item.get("label", "")))
		option.set_item_metadata(index, item.get("value", ""))
	if option.item_count > 0 and option.selected < 0:
		option.selected = 0


func _uid_string(value: Variant) -> String:
	if value is String:
		return value as String
	if value is Dictionary:
		return str((value as Dictionary).get("uid", ""))
	if value is Array and not (value as Array).is_empty():
		return _uid_string((value as Array)[0])
	return ""


func _equip_selected() -> void:
	if _selected_uid.is_empty():
		_set_status(t("equipment.no_item"))
		return
	if _slot_filter == "vision_card":
		_run_inventory("assign_vision_card", [_party_id(), _selected_uid])
	elif _slot_filter == "materia":
		_run_inventory("equip_materia", [_selected_id, clampi(_materia_index, 0, 3), _selected_uid])
	else:
		_run_inventory("equip", [_selected_id, _slot_filter, _selected_uid])


func _unequip_slot(slot: String) -> void:
	if slot.begins_with("materia_"):
		_run_inventory("unequip_materia", [_selected_id, int(slot.substr(8))])
	elif slot == "vision_card":
		_run_inventory("unassign_vision_card", [_party_id()])
	else:
		_run_inventory("unequip", [_selected_id, slot])


func _sell_selected() -> void:
	if _selected_uid.is_empty():
		_set_status(t("equipment.no_item"))
		return
	var entry := PlayerState.find_inventory_entry(_selected_uid)
	if bool(entry.get("locked", false)):
		_set_status(t("common.locked") + " " + _selected_uid)
		return
	if _uid_is_equipped(_selected_uid):
		_set_status(t("equipment.unique") + " " + _selected_uid)
		return
	_run_inventory("sell", [_selected_uid])


func _uid_is_equipped(uid: String) -> bool:
	var instance := PlayerState.get_unit_instance(_selected_id)
	var equipped: Dictionary = instance.get("equipped", {})
	for key: String in equipped.keys():
		if _uid_string(equipped[key]) == uid:
			return true
	var party := PlayerState.get_party(_party_id())
	for key: String in ["vision_card", "vision_card_uid"]:
		if str(party.get(key, "")) == uid:
			return true
	return false


func _run_inventory(method: String, args: Array) -> void:
	if PlayerState.inventory == null or not PlayerState.inventory.has_method(method):
		_set_status(t("common.note") + " " + method)
		return
	var result: Dictionary = _as_dict(PlayerState.inventory.callv(method, args))
	if result.is_empty() or not bool(result.get("ok", false)):
		_set_status(t("common.note") + " " + _failure(result, method))
		return
	PlayerState.call("commit", "inventory")
	_set_status(t("equipment.equip") + " " + _summary(result))
	if method.begins_with("un") or method == "sell":
		_selected_uid = ""
	else:
		_selected_uid = str(args[args.size() - 1])
	_refresh()


func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _failure(result: Dictionary, method: String) -> String:
	for key: String in ["message", "reason"]:
		var text := str(result.get(key, ""))
		if not text.is_empty():
			return LocaleManager.t(text)
	return method


func _summary(result: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in result.keys():
		if key == "ok" or key == "reason" or key == "message":
			continue
		parts.append(str(key) + "=" + str(result[key]))
	return " ".join(parts)


func _dict_text(value: Variant) -> String:
	if not value is Dictionary or (value as Dictionary).is_empty():
		return t("common.none")
	var parts: Array[String] = []
	for key: String in (value as Dictionary).keys():
		parts.append(str(key) + "=" + str((value as Dictionary)[key]))
	return " ".join(parts)


func _labels_text(value: Variant) -> String:
	if not value is Array or (value as Array).is_empty():
		return t("common.none")
	var parts: Array[String] = []
	for entry: Variant in value:
		if entry is Dictionary:
			parts.append(LocaleManager.label_for(entry as Dictionary))
		else:
			parts.append(str(entry))
	return " ".join(parts)


func _state(value: bool) -> String:
	return t("common.enabled") if value else t("common.disabled")
