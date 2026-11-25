extends Control

## Phase 3 character details built from immutable definitions and player instances.

const COLLECTION_PATH := "res://scenes/phase3/collection.tscn"
const UPGRADE_PATH := "res://scenes/phase3/upgrade.tscn"
const AWAKENING_PATH := "res://scenes/phase3/awakening.tscn"
const EQUIPMENT_PATH := "res://scenes/phase3/equipment.tscn"
const PARTY_PATH := "res://scenes/phase3/party.tscn"
const TRANSIT_NAME := "selection"

var _selected_id: String = ""
var _status_label: Label
var _content: VBoxContainer
var _favorite_button: Button


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
	layout.add_child(_header(t("details.title"), COLLECTION_PATH))

	var actions := HBoxContainer.new()
	actions.add_child(_button(t("details.upgrade"), func() -> void: _goto(UPGRADE_PATH, _selected_id)))
	actions.add_child(_button(t("details.awaken"), func() -> void: _goto(AWAKENING_PATH, _selected_id)))
	actions.add_child(_button(t("details.equipment"), func() -> void: _goto(EQUIPMENT_PATH, _selected_id)))
	actions.add_child(_button(t("details.party"), func() -> void: _goto(PARTY_PATH, "")))
	_favorite_button = _button(t("common.favorite"), func() -> void: _toggle_favorite())
	actions.add_child(_favorite_button)
	layout.add_child(_styled_panel(actions))

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


func _header(title: String, back_path: String) -> Control:
	var bar := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 24)
	bar.add_child(label)
	bar.add_child(_button(t("common.back"), func() -> void: _goto(back_path, "")))
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


func _consume_instance_id() -> String:
	var id := ""
	var transit := get_tree().root.get_node_or_null(NodePath(TRANSIT_NAME))
	if transit != null:
		id = str(transit.get_meta("instance_id", ""))
		transit.queue_free()
	if id.is_empty():
		id = str(get_meta("instance_id", ""))
	if id.is_empty():
		var selection := get_node_or_null(NodePath("selection"))
		if selection != null:
			id = str(selection.get_meta("instance_id", ""))
			selection.queue_free()
	if id.is_empty():
		id = OS.get_environment("FFBE_QA_INSTANCE_ID")
	if id.is_empty():
		var profile: Dictionary = PlayerState.data.get("profile", {})
		id = str(profile.get("last_unit_id", ""))
	if id.is_empty() and not PlayerState.owned_units().is_empty():
		id = str(PlayerState.owned_units()[0].get("instance_id", ""))
	return id


func _party_id() -> String:
	var from_env := OS.get_environment("FFBE_QA_PARTY_ID")
	return from_env if not from_env.is_empty() else str(PlayerState.data.get("active_party", "default"))


func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _refresh() -> void:
	for child: Node in _content.get_children():
		child.queue_free()
	var instance := PlayerState.get_unit_instance(_selected_id)
	if instance.is_empty():
		_line(_panel(t("collection.empty")), t("collection.empty") + " " + LocaleManager.diagnostic_text(_selected_id))
		_set_status(t("collection.empty"))
		return
	var definition := PlayerState.definition_for(instance)
	_identity_panel(instance, definition)
	_progress_panel(instance, definition)
	_stats_panel()
	_abilities_panel(instance, definition)
	_provenance_panel(definition)
	var favorite_text := t("common.favorite") + ": " + ("★" if bool(instance.get("favorite", false)) else "☆")
	_favorite_button.text = favorite_text


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


func _identity_panel(instance: Dictionary, definition: Dictionary) -> void:
	var box := _panel(t("details.title"))
	var form := str(definition.get("form", instance.get("form", "")))
	var region := str(instance.get("region", definition.get("region", "")))
	var role := str(definition.get("role", ""))
	var element := str(definition.get("element", ""))
	var rarity := str(definition.get("rarity", ""))
	_line(box, LocaleManager.label_for(definition) + "    " + t("common.uid") + ": " + _selected_id)
	_line(box, t("details.forms") + ": " + LocaleManager.identified(LocaleManager.form_label(form), form) + "    " + \
		t("common.region") + ": " + LocaleManager.identified(LocaleManager.region_label(region), region))
	_line(box, t("common.role") + ": " + LocaleManager.identified(LocaleManager.role_label(role), role) + "    " + \
		t("common.element") + ": " + LocaleManager.identified(LocaleManager.element_label(element), element) + "    " + \
		t("common.rarity") + ": " + LocaleManager.identified(LocaleManager.rarity_label(rarity), rarity))
	var categories: Array[String] = []
	for category: Variant in definition.get("categories", []):
		var value := str(category)
		categories.append(LocaleManager.identified(LocaleManager.category_label(value), value))
	_line(box, t("details.categories") + ": " + " ".join(categories))
	_line(box, t("common.level") + ": " + str(instance.get("level", 0)) + "    " + \
		t("awakening.star") + ": " + str(instance.get("star", 0)) + "    " + \
		t("awakening.ex") + ": " + str(instance.get("ex_level", 0)) + "    " + \
		t("awakening.nv") + ": " + _state(bool(instance.get("nv_unlocked", false))) + "    " + \
		t("awakening.nv_plus") + ": " + _state(bool(instance.get("nv_plus", false))))


func _progress_panel(instance: Dictionary, definition: Dictionary) -> void:
	var box := _panel(t("upgrade.exp"))
	var trust: Dictionary = definition.get("trust", {})
	var resources := PlayerState.get_resources()
	var region := str(instance.get("region", ""))
	var native_id := str(instance.get("native_id", ""))
	var fragment_key := "fragment:%s:%s@base" % [region, native_id]
	_line(box, t("details.trust") + ": " + str(instance.get("trust", 0)) + "/" + str(trust.get("max", 0)))
	var tmr_reward := str(trust.get("tmr_reward", ""))
	var stmr_reward := str(trust.get("stmr_reward", ""))
	_line(box, t("details.tmr") + ": " + _state(bool(instance.get("tmr_claimed", false))) + "    " + \
		LocaleManager.identified(LocaleManager.resource_label(tmr_reward), tmr_reward))
	_line(box, t("details.stmr") + ": " + _state(bool(instance.get("stmr_claimed", false))) + "    " + \
		LocaleManager.identified(LocaleManager.resource_label(stmr_reward), stmr_reward))
	_line(box, t("details.fragments") + ": " + str(resources.get(fragment_key, 0)) + "    " + \
		LocaleManager.identified(LocaleManager.resource_label(fragment_key), fragment_key))
	_line(box, t("upgrade.level_cap") + ": " + _level_cap(definition, instance))


func _stats_panel() -> void:
	var box := _panel(t("common.stats"))
	var resolved: Dictionary = {}
	if PlayerState.build_resolver != null and PlayerState.build_resolver.has_method("resolve_unit"):
		resolved = _as_dict(PlayerState.build_resolver.call("resolve_unit", _selected_id, _party_id(), true))
	if resolved.is_empty():
		_line(box, t("common.note") + ": " + t("common.stats"))
		return
	_line(box, t("common.stats") + ": " + _dict_text(resolved.get("stats", {})))
	_line(box, t("common.abilities") + ": " + _labels_text(resolved.get("abilities", [])))
	_line(box, t("equipment.restriction") + ": " + _labels_text(resolved.get("restrictions", [])))
	_line(box, t("common.provenance") + ": " + _labels_text(resolved.get("labels", [])))
	_line(box, LocaleManager.diagnostic_text(_labels_text(resolved.get("diagnostics", []))))


func _abilities_panel(instance: Dictionary, definition: Dictionary) -> void:
	var box := _panel(t("common.abilities"))
	var learned: Array = instance.get("learned_abilities", [])
	var awakened: Array = instance.get("awakened_abilities", [])
	if definition.get("abilities", []) is Array:
		for raw: Variant in definition.get("abilities", []):
			if not raw is Dictionary:
				continue
			var ability: Dictionary = raw
			var ability_id := str(ability.get("id", ""))
			var status_key := t("common.disabled")
			if awakened.has(ability_id):
				status_key = t("common.enabled")
			elif learned.has(ability_id):
				status_key = t("common.owned")
			_line(box, LocaleManager.label_for(ability) + "    " + ability_id + "    " + status_key)
	for key: String in ["leader_skill", "super_lb", "overdrive"]:
		if definition.has(key) and definition[key] is Dictionary:
			var ability: Dictionary = definition[key]
			var prefix := t("details.leader")
			if key == "super_lb":
				prefix = t("details.super_lb")
			elif key == "overdrive":
				prefix = t("details.overdrive")
			_line(box, prefix + ": " + _label_of(ability) + "    " + str(ability.get("id", "")))
	if definition.has("super_lb") and int(instance.get("ex_level", 0)) < 1:
		_line(box, t("details.no_slb"))


func _provenance_panel(definition: Dictionary) -> void:
	var box := _panel(t("common.provenance"))
	var provenance: Dictionary = definition.get("provenance", {})
	var source := str(provenance.get("source", provenance.get("origin", "")))
	var license := str(provenance.get("license", ""))
	var verification := str(definition.get("verification_status", ""))
	_line(box, t("viewer.source") + ": " + LocaleManager.identified(LocaleManager.provenance_label(source), source))
	_line(box, t("viewer.license") + ": " + LocaleManager.identified(LocaleManager.provenance_label(license), license))
	_line(box, t("menu.status") + ": " + LocaleManager.identified(LocaleManager.verification_label(verification), verification) + "    " + \
		LocaleManager.diagnostic_text(str(definition.get("id", ""))))
	var mechanics := ContentRepository.get_mechanic_labels()
	for key: String in [
		"brave_shift", "super_limit_burst", "leader_skill", "unit_categories", "trust_ability",
		"equipment_passives", "vision_card_bonuses", "dual_wield", "multicast", "killers",
		"overdrive", "nv_awakening", "ex_awakening", "nv_plus"
	]:
		if not mechanics.has(key) or not mechanics[key] is Dictionary:
			continue
		var mechanic: Dictionary = mechanics[key]
		_line(box, "%s - %s - %s" % [
			LocaleManager.mechanic_name(key),
			LocaleManager.mechanic_status_label(str(mechanic.get("label", ""))),
			LocaleManager.mechanic_note(key)
		])


func _level_cap(definition: Dictionary, instance: Dictionary) -> String:
	var caps: Dictionary = definition.get("level_caps", {})
	var star := str(instance.get("star", 0))
	if bool(instance.get("nv_unlocked", false)) and caps.has("nv"):
		return str(caps.get("nv", 0))
	return str(caps.get(star, caps.get("5", 0)))


func _state(value: bool) -> String:
	return t("common.enabled") if value else t("common.disabled")


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
		parts.append(_label_of(entry))
	return " ".join(parts)


func _label_of(entry: Variant) -> String:
	if entry is Dictionary:
		return LocaleManager.label_for(entry as Dictionary)
	return str(entry)


func _toggle_favorite() -> void:
	var instance := PlayerState.get_unit_instance(_selected_id)
	if instance.is_empty():
		return
	var changed: bool = PlayerState.mutate_unit_instance(_selected_id, {"favorite": not bool(instance.get("favorite", false))})
	if not changed:
		_set_status(LocaleManager.diagnostic_text(_selected_id))
		return
	PlayerState.call("commit", "units")
	_refresh()
