extends Control

## Phase 3 awakening and form shifts. Ineligible actions are disabled with visible requirements.

const DETAILS_PATH := "res://scenes/phase3/character_details.tscn"
const TRANSIT_NAME := "selection"

var _selected_id: String = ""
var _status_label: Label
var _content: VBoxContainer


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
	layout.add_child(_header(t("awakening.title"), DETAILS_PATH, _selected_id))

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

	var summary := _panel(t("awakening.title"))
	_line(summary, LocaleManager.label_for(definition) + "    " + t("common.uid") + ": " + _selected_id)
	_line(summary, t("awakening.star") + ": " + str(instance.get("star", 0)) + "    " + \
		t("awakening.nv") + ": " + _state(bool(instance.get("nv_unlocked", false))) + "    " + \
		t("awakening.ex") + ": " + str(instance.get("ex_level", 0)) + "    " + \
		t("awakening.nv_plus") + ": " + _state(bool(instance.get("nv_plus", false))))
	_line(summary, t("awakening.requirement") + ": " + t("common.level") + " " + str(instance.get("level", 0)))

	var cost_box := _panel(t("awakening.cost"))
	var cost_summary: Dictionary = {}
	if PlayerState.progression != null and PlayerState.progression.has_method("cost_summary"):
		cost_summary = _as_dict(PlayerState.progression.call("cost_summary", _selected_id))
	if cost_summary.is_empty():
		_line(cost_box, t("common.none"))
	else:
		for key: String in cost_summary.keys():
			_line(cost_box, LocaleManager.identified(LocaleManager.resource_label(key), key) + " = " + str(cost_summary[key]))

	var actions := _panel(t("awakening.awaken"))
	var target_star := _next_star(definition, instance)
	if target_star > 0:
		var star_spec: Dictionary = _section(definition, "awakening").get(str(target_star), {})
		_add_action(actions, t("awakening.star") + " " + str(target_star), _requirement_text(star_spec),
			_can_star(definition, instance, target_star),
			func() -> void: _run("awaken_star", [_selected_id, target_star], t("awakening.success")))

	var nv_spec: Dictionary = definition.get("nv", {})
	_add_action(actions, t("awakening.nv"), _requirement_text(nv_spec),
		_can_nv(definition, instance),
		func() -> void: _run("awaken_nv", [_selected_id], t("awakening.success")))

	var ex_specs: Dictionary = definition.get("ex", {})
	for level: int in [1, 2, 3]:
		var spec: Dictionary = ex_specs.get(str(level), {})
		_add_action(actions, t("awakening.ex") + " +" + str(level), _requirement_text(spec),
			_can_ex(definition, instance, level),
			func() -> void: _run("awaken_ex", [_selected_id, level], t("awakening.success")))

	var nv_plus_spec: Dictionary = definition.get("nv_plus", {})
	_add_action(actions, t("awakening.nv_plus"), _requirement_text(nv_plus_spec),
		_can_nv_plus(definition, instance),
		func() -> void: _run("awaken_nv_plus", [_selected_id], t("awakening.success")))

	var shift_spec: Dictionary = definition.get("nv", {})
	_add_action(actions, t("details.forms") + ": " + t("awakening.nv"),
		_requirement_text({"requires_nv": true}), _can_shift(definition, instance),
		func() -> void: _run("shift_form", [_selected_id], t("awakening.success")))

	_abilities_panel(instance)


func _abilities_panel(instance: Dictionary) -> void:
	var box := _panel(t("common.abilities"))
	var abilities: Array[Dictionary] = []
	if PlayerState.progression != null and PlayerState.progression.has_method("eligible_abilities"):
		var value: Variant = PlayerState.progression.call("eligible_abilities", _selected_id)
		if value is Array:
			for raw: Variant in value:
				if raw is Dictionary:
					abilities.append(raw as Dictionary)
	if abilities.is_empty():
		_line(box, t("common.none"))
		return
	for ability: Dictionary in abilities:
		var ability_id := str(ability.get("ability_id", ability.get("id", "")))
		var resolved: Dictionary = ability.duplicate(true)
		var from_content: Dictionary = ContentRepository.get_advanced_ability(ability_id)
		if not from_content.is_empty():
			resolved = from_content
		var enabled: bool = bool(ability.get("can_awaken", ability.get("eligible", true))) and \
			PlayerState.can_pay(_cost(ability))
		var requirement := _requirement_text(ability)
		_add_action(box, LocaleManager.label_for(resolved) + "    " + ability_id, requirement, enabled,
			func() -> void: _run("awaken_ability", [_selected_id, ability_id], t("awakening.success")))
	_line(box, t("upgrade.level_cap") + ": " + str(instance.get("ex_level", 0)))


func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _section(definition: Dictionary, key: String) -> Dictionary:
	var value: Variant = definition.get(key, {})
	return value if value is Dictionary else {}


func _cost(spec: Dictionary) -> Dictionary:
	return _section(spec, "cost")


func _next_star(definition: Dictionary, instance: Dictionary) -> int:
	var current := int(instance.get("star", 0))
	var best := 0
	for key: String in _section(definition, "awakening").keys():
		var target := int(key)
		if target > current and (best == 0 or target < best):
			best = target
	return best


func _can_star(definition: Dictionary, instance: Dictionary, target: int) -> bool:
	if target <= 0 or int(instance.get("star", 0)) >= target:
		return false
	var spec: Dictionary = _section(definition, "awakening").get(str(target), {})
	if int(spec.get("requires_star", 0)) > int(instance.get("star", 0)):
		return false
	return PlayerState.can_pay(_cost(spec))


func _can_nv(definition: Dictionary, instance: Dictionary) -> bool:
	if bool(instance.get("nv_unlocked", false)):
		return false
	var spec: Dictionary = definition.get("nv", {})
	if int(spec.get("requires_star", 0)) > int(instance.get("star", 0)):
		return false
	return PlayerState.can_pay(_cost(spec))


func _can_ex(definition: Dictionary, instance: Dictionary, level: int) -> bool:
	if int(instance.get("ex_level", 0)) >= level:
		return false
	var spec: Dictionary = _section(definition, "ex").get(str(level), {})
	if bool(spec.get("requires_nv", false)) and not bool(instance.get("nv_unlocked", false)):
		return false
	if int(spec.get("requires_ex", 0)) > int(instance.get("ex_level", 0)):
		return false
	return PlayerState.can_pay(_cost(spec))


func _can_nv_plus(definition: Dictionary, instance: Dictionary) -> bool:
	if bool(instance.get("nv_plus", false)):
		return false
	var spec: Dictionary = definition.get("nv_plus", {})
	if int(spec.get("requires_ex", 0)) > int(instance.get("ex_level", 0)):
		return false
	return PlayerState.can_pay(_cost(spec))


func _can_shift(definition: Dictionary, instance: Dictionary) -> bool:
	if not bool(instance.get("nv_unlocked", false)):
		return false
	var target := str(_section(definition, "shift").get("to", ""))
	return not target.is_empty() and str(instance.get("definition_id", "")) != target


func _requirement_text(spec: Dictionary) -> String:
	var parts: Array[String] = []
	if spec.has("requires_star"):
		parts.append(t("awakening.requirement") + " " + t("awakening.star") + " " + str(spec.get("requires_star", 0)))
	if bool(spec.get("requires_nv", false)):
		parts.append(t("awakening.requirement") + " " + t("awakening.nv"))
	if spec.has("requires_ex"):
		parts.append(t("awakening.requirement") + " " + t("awakening.ex") + " " + str(spec.get("requires_ex", 0)))
	var cost := _cost(spec)
	if not cost.is_empty():
		parts.append(t("awakening.cost") + " " + _cost_text(cost))
	if parts.is_empty():
		parts.append(t("awakening.requirement"))
	return " ".join(parts)


func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in cost.keys():
		parts.append(LocaleManager.identified(LocaleManager.resource_label(key), key) + "=" + str(cost[key]) + "/" + str(PlayerState.get_resource(key)))
	return " ".join(parts)


func _add_action(parent: VBoxContainer, title: String, requirement: String, enabled: bool, action: Callable) -> void:
	var button := _button(title, action)
	button.disabled = not enabled
	button.tooltip_text = requirement
	parent.add_child(button)
	_line(parent, requirement)


func _run(method: String, args: Array, success_key: String) -> void:
	if PlayerState.progression == null or not PlayerState.progression.has_method(method):
		_set_status(LocaleManager.diagnostic_text(method))
		return
	var result: Dictionary = _as_dict(PlayerState.progression.callv(method, args))
	if result.is_empty() or not bool(result.get("ok", false)):
		_set_status(_failure(result, method))
		return
	PlayerState.call("commit", "progression")
	var message := t(success_key) + " " + LocaleManager.diagnostic_text(_summary(result))
	_set_status(message)
	_refresh()


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
