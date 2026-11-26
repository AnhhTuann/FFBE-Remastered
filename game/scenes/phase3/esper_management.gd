extends Control

## Phase 4 Esper screen. Definitions and costs come from synthetic fixtures;
## the evidence line explicitly labels them as remastered design.

const HUB_PATH := "res://scenes/phase3/economy_hub.tscn"
const TRANSIT_NAME := "selection"
const ESPER_CLASS_NAME := "EsperSystem"
const ESPER_SCRIPT_PATHS: Array[String] = [
	"res://systems/esper_system.gd",
	"res://core/esper_system.gd",
	"res://systems/phase4/esper_system.gd"
]

var _party_id: String = "default"
var _definitions: Array[Dictionary] = []
var _owned_ids: Dictionary = {}
var _title_label: Label
var _back_button: Button
var _content: VBoxContainer
var _status_label: Label
var _status_key: String = ""
var _status_args: Dictionary = {}
var _status_suffix: String = ""
var _system_cache: Dictionary = {}


func _ready() -> void:
	theme = _make_theme()
	_party_id = OS.get_environment("FFBE_QA_PARTY_ID")
	if _party_id.is_empty():
		_party_id = str(PlayerState.data.get("active_party", "default"))
	_build_background()
	LocaleManager.locale_changed.connect(_apply_locale)

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
	layout.add_child(_header("esper.title", HUB_PATH))

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
	_set_status("common.none")
	_load_definitions()
	_render()


func _exit_tree() -> void:
	if LocaleManager.locale_changed.is_connected(_apply_locale):
		LocaleManager.locale_changed.disconnect(_apply_locale)


func t(key: String, args: Dictionary = {}) -> String:
	return LocaleManager.t(key, args)


func _apply_locale(_locale: String = "") -> void:
	if _title_label != null:
		_title_label.text = t("esper.title")
	if _back_button != null:
		_back_button.text = t("common.back")
	_render()
	_update_status()


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


func _set_status(key: String, args: Dictionary = {}, suffix: String = "") -> void:
	_status_key = key
	_status_args = args
	_status_suffix = suffix
	_update_status()


func _update_status() -> void:
	if _status_label == null:
		return
	var text := t(_status_key, _status_args) if not _status_key.is_empty() else ""
	_status_label.text = text + (" " + _status_suffix if not _status_suffix.is_empty() else "")


func _button(text_value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 36)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	return button


func _header(title_key: String, back_path: String) -> Control:
	var bar := HBoxContainer.new()
	_title_label = Label.new()
	_title_label.text = t(title_key)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 24)
	_back_button = _button(t("common.back"), func() -> void: _goto(back_path))
	bar.add_child(_title_label)
	bar.add_child(_back_button)
	return _styled_panel(bar)


func _goto(path: String) -> void:
	var old := get_tree().root.get_node_or_null(NodePath(TRANSIT_NAME))
	if old != null:
		old.queue_free()
	var transit := Node.new()
	transit.name = TRANSIT_NAME
	transit.set_meta("party_id", _party_id)
	var instance_id := OS.get_environment("FFBE_QA_INSTANCE_ID")
	if not instance_id.is_empty():
		transit.set_meta("instance_id", instance_id)
	get_tree().root.add_child(transit)
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		transit.queue_free()
		_set_status("common.diagnostic", {}, "error=%d" % error)


func _panel(title_key: String) -> VBoxContainer:
	var panel := _styled_panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var heading := Label.new()
	heading.text = t(title_key)
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


func _load_definitions() -> void:
	_definitions.clear()
	_owned_ids.clear()
	var system := _esper_system()
	if system == null:
		return
	_definitions = _as_array(system.call("definitions"))
	# owned() is a dictionary keyed by esper id whose entries do not repeat the
	# id; preserve the key so unlock/set-active buttons can target the record.
	for entry: Dictionary in _as_keyed(system.call("owned"), "esper_id"):
		var id := _id_from(entry)
		if not id.is_empty():
			_owned_ids[id] = true


func _render() -> void:
	if _content == null:
		return
	for child: Node in _content.get_children():
		child.queue_free()

	var system := _esper_system()
	if system == null:
		_line(_panel("common.system_unavailable"), t("common.system_unavailable", {"name": ESPER_CLASS_NAME}))
		return

	var summary_box := _panel("common.status")
	_line(summary_box, t("esper.party", {"party_id": _party_id}))
	var status := _call(system, "status_for", [_party_id])
	var data := _detail(status)
	var active := _first_string(data, ["active_esper", "esper_id", "active", "current"], "")
	if active.is_empty():
		_line(summary_box, t("esper.current") + ": " + t("esper.none_active"))
	else:
		_line(summary_box, t("esper.current") + ": " + _name_for_id(active))
	for line: String in _lines_for(data, ["active_esper", "esper_id", "active", "current"]):
		_line(summary_box, line)
	var clear_active := _button(t("esper.clear_active"), func() -> void: _run("clear_active", [_party_id], "esper.cleared", "espers"))
	clear_active.disabled = active.is_empty()
	summary_box.add_child(clear_active)

	var list_box := _panel("esper.definitions")
	if _definitions.is_empty():
		_line(list_box, t("esper.empty"))
	for definition: Dictionary in _definitions:
		list_box.add_child(_definition_row(definition))

	_line(_panel("common.evidence"), _evidence())


func _definition_row(definition: Dictionary) -> Control:
	var id := str(definition.get("id", ""))
	var owned := _owned_ids.has(id)
	var panel := _styled_panel(null, Color(0.071, 0.129, 0.204))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_line(box, LocaleManager.identified(LocaleManager.label_for(definition), id))
	_line(box, t("common.status") + ": " + (t("common.owned") if owned else t("collection.unowned")))
	var cost: Variant = definition.get("unlock_cost", definition.get("cost", {}))
	if cost is Dictionary and not (cost as Dictionary).is_empty():
		_line(box, t("esper.unlock_cost") + ": " + _cost_text(cost as Dictionary))
	var stats: Variant = definition.get("stats", definition.get("bonuses", {}))
	if stats is Dictionary and not (stats as Dictionary).is_empty():
		_line(box, t("esper.stats") + ": " + _value_text("stats", stats))
	_line(box, t("common.evidence") + ": " + _evidence())
	var actions := HBoxContainer.new()
	var unlock := _button(t("esper.unlock"), func() -> void: _run("unlock", [id], "esper.unlocked", "espers"))
	unlock.disabled = owned
	actions.add_child(unlock)
	var set_active := _button(t("esper.set_active"), func() -> void: _run("set_active", [_party_id, id], "esper.activated", "espers"))
	set_active.disabled = not owned
	actions.add_child(set_active)
	box.add_child(actions)
	panel.add_child(box)
	return panel


func _run(method: String, args: Array, ok_key: String, section: String) -> void:
	var system := _esper_system()
	if system == null:
		_set_status("common.system_unavailable", {"name": ESPER_CLASS_NAME})
		return
	var result := _call(system, method, args)
	if result.is_empty():
		_set_status("common.system_unavailable", {"name": ESPER_CLASS_NAME})
		return
	if not bool(result.get("ok", true)):
		_set_status("common.failed", {}, _reason_suffix(result))
		_render()
		return
	# EsperSystem.unlock()/set_active() commit their own save snapshots.
	_set_status(ok_key)
	_load_definitions()
	_render()


func _reason_suffix(result: Dictionary) -> String:
	var message := str(result.get("message", ""))
	if not message.is_empty() and LocaleManager.has_key(message):
		return t(message)
	var reason := str(result.get("reason", ""))
	if not reason.is_empty() and LocaleManager.has_token("reason", reason):
		return LocaleManager.reason_label(reason)
	if not message.is_empty():
		return LocaleManager.diagnostic_text(message)
	return ""


func _evidence() -> String:
	return LocaleManager.mechanic_status_label("REMASTERED_DESIGN") + " · " + \
		LocaleManager.verification_label("SYNTHETIC_FIXTURE")


func _name_for_id(id: String) -> String:
	for definition: Dictionary in _definitions:
		if str(definition.get("id", "")) == id:
			return LocaleManager.identified(LocaleManager.label_for(definition), id)
	return LocaleManager.identified(LocaleManager.resource_label(id), id)


func _id_from(entry: Variant) -> String:
	if entry is Dictionary:
		var record: Dictionary = entry as Dictionary
		for key: String in ["id", "esper_id", "definition_id"]:
			if record.has(key):
				return str(record[key])
		return ""
	if entry is String:
		return entry as String
	return ""


func _first_string(data: Dictionary, keys: Array[String], default_value: String) -> String:
	for key: String in keys:
		if data.has(key):
			var value := str(data[key])
			if not value.is_empty():
				return value
	return default_value


func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in cost.keys():
		parts.append(LocaleManager.resource_label(key) + " = " + str(cost[key]) + \
			"/" + str(PlayerState.get_resource(key)))
	return ", ".join(parts)


func _esper_system() -> Object:
	if _system_cache.has("esper"):
		var cached: Variant = _system_cache["esper"]
		if cached is Object and is_instance_valid(cached):
			return cached as Object
		_system_cache.erase("esper")
	var path := _script_path(ESPER_CLASS_NAME, ESPER_SCRIPT_PATHS)
	if path.is_empty():
		return null
	var script: Script = load(path) as Script
	if script == null:
		return null
	var instance: Variant = script.new(PlayerState)
	if instance is Object:
		_system_cache["esper"] = instance
		return instance as Object
	return null


func _script_path(class_id: String, candidates: Array[String]) -> String:
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		if str(entry.get("class", "")) == class_id:
			var path := str(entry.get("path", ""))
			if not path.is_empty() and ResourceLoader.exists(path):
				return path
	for candidate: String in candidates:
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


func _call(system: Object, method: String, args: Array = []) -> Dictionary:
	if system == null or not system.has_method(method):
		return {}
	var value: Variant = system.callv(method, args)
	if value is Dictionary:
		return value as Dictionary
	return {}


func _as_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item: Variant in value:
			if item is Dictionary:
				result.append(item as Dictionary)
	elif value is Dictionary:
		for item: Variant in (value as Dictionary).values():
			if item is Dictionary:
				result.append(item as Dictionary)
	return result


func _as_keyed(value: Variant, id_field: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Dictionary:
		for key: Variant in (value as Dictionary).keys():
			var item: Variant = (value as Dictionary)[key]
			if item is Dictionary:
				var record := (item as Dictionary).duplicate(true)
				if not record.has("id") and not record.has(id_field):
					record[id_field] = str(key)
				result.append(record)
	elif value is Array:
		for item: Variant in value:
			if item is Dictionary:
				result.append(item as Dictionary)
	return result


func _detail(result: Dictionary) -> Dictionary:
	# Systems merge payload fields at the top level while leaving empty data.
	var data: Variant = result.get("data", {})
	if data is Dictionary and not (data as Dictionary).is_empty():
		return data as Dictionary
	return result


func _lines_for(data: Dictionary, skip: Array[String] = []) -> Array[String]:
	var lines: Array[String] = []
	var keys: Array[String] = []
	for key: String in data.keys():
		var envelope_keys := ["ok", "reason", "message", "data", "key", "uids", "granted", "now_unix"]
		if not skip.has(key) and not envelope_keys.has(key):
			keys.append(key)
	keys.sort()
	for key: String in keys:
		if data[key] is Dictionary and (data[key] as Dictionary).is_empty():
			continue
		lines.append(_key_label(key) + ": " + _value_text(key, data[key]))
	return lines


func _key_label(key: String) -> String:
	match key:
		"cost", "price":
			return t("common.cost")
		"inputs":
			return t("common.inputs")
		"outputs", "rewards":
			return t("common.outputs")
		"duration", "remaining", "seconds", "elapsed":
			return t("common.duration")
		"status", "state":
			return t("common.status")
		"evidence", "verification":
			return t("common.evidence")
		"seed":
			return t("common.seed")
		"receipt":
			return t("common.receipt")
		"id", "esper_id", "banner_id", "shop_id", "recipe_id", "job_id", "unit_id", "stock_id":
			return t("common.id")
		"pity":
			return t("common.limit")
	if LocaleManager.has_token("stat", key):
		return LocaleManager.stat_label(key)
	if LocaleManager.has_token("resource", key):
		return LocaleManager.resource_label(key)
	if LocaleManager.has_key(key):
		return t(key)
	return LocaleManager.field_label(key)


func _value_text(key: String, value: Variant) -> String:
	if value == null:
		return t("common.none")
	if value is bool:
		return t("common.yes") if bool(value) else t("common.no")
	if value is Dictionary:
		var parts: Array[String] = []
		for child_key: String in (value as Dictionary).keys():
			parts.append(_key_label(child_key) + " = " + _value_text(child_key, (value as Dictionary)[child_key]))
		return ", ".join(parts)
	if value is Array:
		var parts: Array[String] = []
		for item: Variant in value:
			parts.append(_value_text(key, item))
		return ", ".join(parts)
	var text := str(value)
	if LocaleManager.has_token("resource", text):
		return LocaleManager.resource_label(text)
	if key in ["verification", "evidence"] and LocaleManager.has_token("verification", text):
		return LocaleManager.verification_label(text)
	if key in ["status", "state"] and LocaleManager.has_token("status", text):
		return LocaleManager.status_label(text)
	if LocaleManager.has_token("reason", text):
		return LocaleManager.reason_label(text)
	if LocaleManager.has_key(text):
		return t(text)
	return text
