extends Control

## Phase 3 character collection. All static copy is resolved through LocaleManager.

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"
const DETAILS_PATH := "res://scenes/phase3/character_details.tscn"
const TRANSIT_NAME := "selection"

var _status_label: Label
var _summary_label: Label
var _rows: VBoxContainer
var _search: LineEdit
var _filters: Dictionary = {}


func _ready() -> void:
	theme = _make_theme()
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

	layout.add_child(_header(t("collection.title"), MAIN_MENU_PATH))

	var search_row := HBoxContainer.new()
	var search_label := Label.new()
	search_label.text = t("collection.search")
	search_label.custom_minimum_size = Vector2(110, 0)
	_search = LineEdit.new()
	_search.placeholder_text = t("collection.search")
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_text: String) -> void: _rebuild())
	search_row.add_child(search_label)
	search_row.add_child(_search)
	layout.add_child(_styled_panel(search_row))

	var filters := VBoxContainer.new()
	filters.add_theme_constant_override("separation", 6)
	_add_filter_row(filters, "region", t("collection.filter.region"), _values_for("region"))
	_add_filter_row(filters, "rarity", t("collection.filter.rarity"), _values_for("rarity"))
	_add_filter_row(filters, "role", t("collection.filter.role"), _values_for("role"))
	_add_filter_row(filters, "category", t("collection.filter.category"), _values_for("category"))
	_add_filter_row(filters, "element", t("collection.filter.element"), _values_for("element"))
	_add_filter_row(filters, "status", t("collection.filter.status"), [])
	layout.add_child(_styled_panel(filters))

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 760

	var list_panel := _styled_panel()
	list_panel.custom_minimum_size = Vector2(520, 260)
	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 8)
	list_scroll.add_child(_rows)
	list_panel.add_child(list_scroll)

	var summary_panel := _styled_panel()
	summary_panel.custom_minimum_size = Vector2(300, 260)
	_summary_label = _body_label()
	summary_panel.add_child(_summary_label)

	split.add_child(list_panel)
	split.add_child(summary_panel)
	layout.add_child(split)

	_status_label = _status_label_node()
	layout.add_child(_status_label)
	_rebuild()


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
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return label


func _status_label_node() -> Label:
	var label := _body_label()
	label.custom_minimum_size = Vector2(0, 42)
	return label


func _set_status(text: String) -> void:
	_status_label.text = text


func _header(title: String, back_path: String) -> Control:
	var bar := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 24)
	var back := Button.new()
	back.text = t("common.back")
	back.pressed.connect(func() -> void: _goto(back_path, ""))
	bar.add_child(label)
	bar.add_child(back)
	return _styled_panel(bar)


func _goto(path: String, instance_id: String = "", extra: Dictionary = {}) -> void:
	var old := get_tree().root.get_node_or_null(NodePath(TRANSIT_NAME))
	if old != null:
		old.queue_free()
	var transit := Node.new()
	transit.name = TRANSIT_NAME
	transit.set_meta("instance_id", instance_id)
	for key: String in extra.keys():
		transit.set_meta(key, extra[key])
	get_tree().root.add_child(transit)
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		transit.queue_free()
		_set_status(LocaleManager.diagnostic_text("error=%d" % error))


func _fill_option(option: OptionButton, items: Array[Dictionary]) -> void:
	for item: Dictionary in items:
		var index: int = option.item_count
		option.add_item(str(item.get("label", "")))
		option.set_item_metadata(index, item.get("value", ""))
	if option.item_count > 0 and option.selected < 0:
		option.selected = 0


func _selected_value(option: OptionButton) -> String:
	if option == null or option.selected < 0:
		return ""
	return str(option.get_item_metadata(option.selected))


func _add_filter_row(parent: VBoxContainer, key: String, label_text: String, values: Array[String]) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(110, 0)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var items: Array[Dictionary] = [{"label": t("common.all"), "value": ""}]
	if key == "status":
		items = [
			{"label": t("common.all"), "value": ""},
			{"label": t("collection.owned"), "value": "owned"},
			{"label": t("collection.unowned"), "value": "unowned"},
			{"label": t("collection.favorites"), "value": "favorites"},
			{"label": t("collection.locked"), "value": "locked"}
		]
	else:
		for value: String in values:
			items.append({"label": LocaleManager.filter_value_label(key, value), "value": value})
	_fill_option(option, items)
	option.item_selected.connect(func(_index: int) -> void: _rebuild())
	_filters[key] = option
	row.add_child(label)
	row.add_child(option)
	parent.add_child(row)


func _values_for(field: String) -> Array[String]:
	var seen: Dictionary = {}
	for instance: Dictionary in PlayerState.owned_units():
		_remember_value(seen, str(instance.get(field, "")))
	var definitions: Dictionary = ContentRepository.get_unit_definitions()
	for raw: Variant in definitions.values():
		if not raw is Dictionary:
			continue
		var definition: Dictionary = raw
		if field == "category":
			for category: Variant in definition.get("categories", []):
				_remember_value(seen, str(category))
		else:
			_remember_value(seen, str(definition.get(field, "")))
	var result: Array[String] = []
	for value: String in seen.keys():
		result.append(value)
	result.sort()
	return result


func _remember_value(seen: Dictionary, value: String) -> void:
	if not value.is_empty():
		seen[value] = true


func _rebuild() -> void:
	for child: Node in _rows.get_children():
		child.queue_free()
	var definitions: Dictionary = ContentRepository.get_unit_definitions()
	var counts: Dictionary = {}
	var owned: Array[Dictionary] = PlayerState.owned_units()
	for instance: Dictionary in owned:
		var definition_id := str(instance.get("definition_id", ""))
		counts[definition_id] = int(counts.get(definition_id, 0)) + 1

	var query := _search.text.strip_edges().to_lower()
	var shown := 0
	var status := _selected_value(_filters.get("status") as OptionButton)
	for instance: Dictionary in owned:
		if status == "unowned" or not _instance_passes(instance, definitions, query):
			continue
		_rows.add_child(_instance_row(instance, definitions, counts))
		shown += 1
	if status == "unowned":
		for raw: Variant in definitions.values():
			if not raw is Dictionary:
				continue
			var definition: Dictionary = raw
			var definition_id := str(definition.get("id", ""))
			if int(counts.get(definition_id, 0)) != 0 or not _definition_text_matches(definition, query):
				continue
			_rows.add_child(_unowned_row(definition))
			shown += 1
	if shown == 0:
		var empty := _body_label()
		empty.text = t("collection.empty")
		_rows.add_child(empty)

	_summary_label.text = t("collection.owned") + ": " + str(owned.size()) + "    " + \
		t("common.all") + ": " + str(definitions.size()) + "    " + \
		t("collection.copy_count") + ": " + str(shown)


func _instance_passes(instance: Dictionary, definitions: Dictionary, query: String) -> bool:
	var definition: Dictionary = definitions.get(str(instance.get("definition_id", "")), {})
	var status := _selected_value(_filters.get("status") as OptionButton)
	match status:
		"favorites":
			if not bool(instance.get("favorite", false)):
				return false
		"locked":
			if not bool(instance.get("locked", false)):
				return false
	if not _filter_matches("region", str(instance.get("region", definition.get("region", "")))):
		return false
	if not _filter_matches("rarity", str(definition.get("rarity", ""))):
		return false
	if not _filter_matches("role", str(definition.get("role", ""))):
		return false
	if not _filter_matches("element", str(definition.get("element", ""))):
		return false
	var category_ok := true
	var selected_category := _selected_value(_filters.get("category") as OptionButton)
	if not selected_category.is_empty():
		category_ok = false
		for category: Variant in definition.get("categories", []):
			if str(category) == selected_category:
				category_ok = true
				break
	if not category_ok:
		return false
	return _definition_text_matches(definition, query) or \
		str(instance.get("instance_id", "")).to_lower().findn(query) >= 0 or \
		str(instance.get("definition_id", "")).to_lower().findn(query) >= 0


func _definition_text_matches(definition: Dictionary, query: String) -> bool:
	if query.is_empty():
		return true
	var region := str(definition.get("region", ""))
	var role := str(definition.get("role", ""))
	var element := str(definition.get("element", ""))
	var rarity := str(definition.get("rarity", ""))
	var haystack := LocaleManager.label_for(definition).to_lower() + " " + \
		LocaleManager.region_label(region).to_lower() + " " + region.to_lower() + " " + \
		LocaleManager.role_label(role).to_lower() + " " + role.to_lower() + " " + \
		LocaleManager.element_label(element).to_lower() + " " + element.to_lower() + " " + \
		LocaleManager.rarity_label(rarity).to_lower() + " " + rarity.to_lower()
	for category: Variant in definition.get("categories", []):
		var value := str(category)
		haystack += " " + LocaleManager.category_label(value).to_lower() + " " + value.to_lower()
	haystack += " " + str(definition.get("id", "")).to_lower()
	return haystack.findn(query) >= 0


func _filter_matches(key: String, value: String) -> bool:
	var selected := _selected_value(_filters.get(key) as OptionButton)
	return selected.is_empty() or selected == value


func _instance_row(instance: Dictionary, definitions: Dictionary, counts: Dictionary) -> Control:
	var id := str(instance.get("instance_id", ""))
	var definition: Dictionary = definitions.get(str(instance.get("definition_id", "")), {})
	var panel := _styled_panel(null, Color(0.094, 0.173, 0.271))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var name_label := _body_label()
	name_label.text = LocaleManager.label_for(definition) + "    " + t("common.uid") + ": " + id
	name_label.add_theme_font_size_override("font_size", 17)
	box.add_child(name_label)

	var details: Array[String] = []
	var region := str(instance.get("region", ""))
	details.append(t("common.region") + ": " + LocaleManager.identified(LocaleManager.region_label(region), region))
	details.append(t("common.level") + ": " + str(instance.get("level", 0)))
	details.append(t("awakening.star") + ": " + str(instance.get("star", 0)))
	details.append(t("awakening.ex") + ": " + str(instance.get("ex_level", 0)))
	details.append(t("collection.copy_count") + ": " + str(counts.get(str(instance.get("definition_id", "")), 0)))
	if bool(instance.get("nv_unlocked", false)):
		details.append(t("awakening.nv"))
	if bool(instance.get("nv_plus", false)):
		details.append(t("awakening.nv_plus"))
	var meta_label := _body_label()
	meta_label.text = "   ".join(details)
	box.add_child(meta_label)

	var buttons := HBoxContainer.new()
	var open := Button.new()
	open.text = t("collection.details")
	open.pressed.connect(func() -> void: _goto(DETAILS_PATH, id))
	var favorite := Button.new()
	favorite.text = t("common.favorite") + ": " + ("★" if bool(instance.get("favorite", false)) else "☆")
	favorite.pressed.connect(func() -> void: _toggle_favorite(id))
	buttons.add_child(open)
	buttons.add_child(favorite)
	box.add_child(buttons)

	panel.add_child(box)
	return panel


func _unowned_row(definition: Dictionary) -> Control:
	var panel := _styled_panel(null, Color(0.071, 0.129, 0.204))
	var label := _body_label()
	label.text = LocaleManager.label_for(definition) + "    " + t("collection.unowned") + "    " + \
		t("collection.copy_count") + ": 0"
	panel.add_child(label)
	return panel


func _toggle_favorite(id: String) -> void:
	var instance := PlayerState.get_unit_instance(id)
	if instance.is_empty():
		_set_status(t("collection.empty") + " " + LocaleManager.diagnostic_text(id))
		return
	var changed: bool = PlayerState.mutate_unit_instance(id, {"favorite": not bool(instance.get("favorite", false))})
	if not changed:
		_set_status(LocaleManager.diagnostic_text(id))
		return
	PlayerState.call("commit", "units")
	_rebuild()
