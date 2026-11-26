extends Control

## Phase 4 summon screen. Pools, costs and rates are synthetic fixtures;
## the evidence line explicitly refuses to assert original FFBE rates.

const HUB_PATH := "res://scenes/phase3/economy_hub.tscn"
const TRANSIT_NAME := "selection"
const SUMMON_CLASS_NAME := "SummonSystem"
const SUMMON_SCRIPT_PATHS: Array[String] = [
	"res://systems/summon_system.gd",
	"res://core/summon_system.gd",
	"res://systems/phase4/summon_system.gd"
]

var _banners: Array[Dictionary] = []
var _banner_option: OptionButton = null
var _selected_banner_id: String = ""
var _last_result_unit: String = ""
var _last_receipt: String = ""
var _receipt_counter: int = 0
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
	layout.add_child(_header("summon.title", HUB_PATH))

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
	_load_banners()
	_render()


func _exit_tree() -> void:
	if LocaleManager.locale_changed.is_connected(_apply_locale):
		LocaleManager.locale_changed.disconnect(_apply_locale)


func t(key: String, args: Dictionary = {}) -> String:
	return LocaleManager.t(key, args)


func _apply_locale(_locale: String = "") -> void:
	if _title_label != null:
		_title_label.text = t("summon.title")
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
	var party_id := OS.get_environment("FFBE_QA_PARTY_ID")
	if party_id.is_empty():
		party_id = str(PlayerState.data.get("active_party", "default"))
	transit.set_meta("party_id", party_id)
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


func _load_banners() -> void:
	_banners.clear()
	var system := _summon_system()
	if system == null:
		return
	_banners = _as_array(system.call("banners"))
	if _banners.is_empty():
		_selected_banner_id = ""
		return
	for banner: Dictionary in _banners:
		var id := str(banner.get("id", ""))
		if _selected_banner_id.is_empty() or id == _selected_banner_id:
			_selected_banner_id = id
			return


func _render() -> void:
	if _content == null:
		return
	for child: Node in _content.get_children():
		child.queue_free()

	var system := _summon_system()
	if system == null:
		_line(_panel("common.system_unavailable"), t("common.system_unavailable", {"name": SUMMON_CLASS_NAME}))
		return

	var list_box := _panel("summon.banners")
	if _banners.is_empty():
		_line(list_box, t("summon.empty"))
	else:
		var option := OptionButton.new()
		_banner_option = option
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for banner: Dictionary in _banners:
			var id := str(banner.get("id", ""))
			var index: int = option.item_count
			option.add_item(LocaleManager.label_for(banner))
			option.set_item_metadata(index, id)
			if id == _selected_banner_id:
				option.selected = index
		option.item_selected.connect(func(index: int) -> void: _on_banner_selected(index))
		list_box.add_child(option)

	var banner := _selected_banner()
	var detail_box := _panel("common.details")
	if banner.is_empty():
		_line(detail_box, t("summon.empty"))
	else:
		_line(detail_box, LocaleManager.identified(LocaleManager.label_for(banner), str(banner.get("id", ""))))
		var cost: Variant = banner.get("cost", {})
		if not (cost is Dictionary and (cost as Dictionary).is_empty()):
			_line(detail_box, t("summon.cost") + ": " + _value_text("cost", cost))
		var pity := _pity_counts(banner)
		var pity_limit := _to_int(pity.get("limit", 0))
		var pity_count := _to_int(pity.get("count", 0))
		if pity_limit > 0:
			_line(detail_box, t("summon.pity", {"count": pity_count, "limit": pity_limit}))
		for line: String in _lines_for(banner, ["id", "name_key", "display_name", "cost", "pity", "pity_count", "pity_limit", "pity_max", "pity_threshold", "pool"]):
			_line(detail_box, line)
		_line(detail_box, t("summon.pool") + ": " + _pool_preview(banner))

	var evidence_box := _panel("common.evidence")
	_line(evidence_box, t("summon.rates_note"))
	_line(evidence_box, LocaleManager.mechanic_status_label("UNVERIFIED_RULE") + " · " + \
		LocaleManager.verification_label("SYNTHETIC_FIXTURE"))

	var draw_box := _panel("common.result")
	_line(draw_box, t("summon.seed", {"seed": _seed()}))
	if _last_receipt.is_empty():
		_line(draw_box, t("summon.result.empty"))
	else:
		_line(draw_box, t("summon.receipt", {"receipt": _last_receipt}))
		_line(draw_box, t("summon.result.unit", {"unit": _last_result_unit}))
	draw_box.add_child(_button(t("summon.draw"), func() -> void: _perform_draw(system)))


func _on_banner_selected(index: int) -> void:
	if _banner_option == null or index < 0 or index >= _banner_option.item_count:
		return
	_selected_banner_id = str(_banner_option.get_item_metadata(index))
	_render()


func _selected_banner() -> Dictionary:
	for banner: Dictionary in _banners:
		if str(banner.get("id", "")) == _selected_banner_id:
			return banner
	var system := _summon_system()
	if system != null and not _selected_banner_id.is_empty():
		return _detail(_call(system, "banner", [_selected_banner_id]))
	return {}


# Renamed from _draw: Control already owns that virtual method.
func _perform_draw(system: Object) -> void:
	if _selected_banner_id.is_empty():
		_set_status("reason.invalid_id")
		return
	_receipt_counter += 1
	_last_receipt = "qa-%d-%d-%d" % [_now(), Time.get_ticks_usec(), _receipt_counter]
	var result := _call(system, "summon", [_selected_banner_id, _seed(), _last_receipt])
	if result.is_empty():
		_set_status("common.system_unavailable", {"name": SUMMON_CLASS_NAME})
		return
	if not bool(result.get("ok", true)):
		_set_status("common.failed", {}, _reason_suffix(result))
		_render()
		return
	# SummonSystem.summon() grants the unit and commits once internally.
	var data := _detail(result)
	var unit_id := _first_string(data, ["unit_id", "id", "definition_id"], "")
	_last_result_unit = _unit_label(unit_id) if not unit_id.is_empty() else t("summon.result.unknown")
	_set_status("summon.drawn")
	_load_banners()
	_render()


func _pool_preview(banner: Dictionary) -> String:
	var pool: Variant = banner.get("pool", [])
	if not (pool is Array) or (pool as Array).is_empty():
		return t("summon.pool.empty")
	var labels: Array[String] = []
	for item: Variant in pool:
		var id := _id_from(item)
		if id.is_empty():
			continue
		labels.append(_unit_label(id))
	return ", ".join(labels) if not labels.is_empty() else t("summon.pool.empty")


func _pity_counts(banner: Dictionary) -> Dictionary:
	var rule: Variant = banner.get("pity", {})
	var guarantee: Variant = banner.get("guarantee", {})
	var rule_map := {}
	if rule is Dictionary:
		rule_map = rule as Dictionary
	var limit := _first_int(rule_map, ["threshold", "within", "max"], 0)
	if limit <= 0 and guarantee is Dictionary:
		limit = _first_int(guarantee as Dictionary, ["within"], 0)
	var current := 0
	var section: Variant = PlayerState.data.get("summon", {})
	if section is Dictionary:
		var pity_state: Variant = (section as Dictionary).get("pity", {})
		if pity_state is Dictionary:
			current = _to_int((pity_state as Dictionary).get(_selected_banner_id, 0))
	return {"count": current, "limit": limit}


func _entry_label(entry: Dictionary) -> String:
	var id := _id_from(entry)
	var label := LocaleManager.label_for(entry)
	return LocaleManager.identified(label, id) if not id.is_empty() else label


func _unit_label(id: String) -> String:
	var definition := {}
	if ContentRepository.has_method("get_unit_definition"):
		definition = ContentRepository.call("get_unit_definition", id)
	if definition is Dictionary and not (definition as Dictionary).is_empty():
		return LocaleManager.identified(LocaleManager.label_for(definition as Dictionary), id)
	return LocaleManager.identified(LocaleManager.resource_label(id), id)


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


func _id_from(entry: Variant) -> String:
	if entry is Dictionary:
		var record: Dictionary = entry as Dictionary
		for key: String in ["id", "unit_id", "definition_id", "banner_id"]:
			if record.has(key):
				return str(record[key])
		return ""
	if entry is String:
		return entry as String
	return ""


func _seed() -> int:
	var raw := OS.get_environment("FFBE_QA_SEED")
	if raw.is_empty() or not raw.is_valid_int():
		return 0
	return raw.to_int()


func _now() -> int:
	var now := Time.get_unix_time_from_system()
	var override := OS.get_environment("FFBE_QA_NOW_UNIX")
	if not override.is_empty() and override.is_valid_int():
		return maxi(0, override.to_int())
	return now


func _summon_system() -> Object:
	if _system_cache.has("summon"):
		var cached: Variant = _system_cache["summon"]
		if cached is Object and is_instance_valid(cached):
			return cached as Object
		_system_cache.erase("summon")
	var path := _script_path(SUMMON_CLASS_NAME, SUMMON_SCRIPT_PATHS)
	if path.is_empty():
		return null
	var script: Script = load(path) as Script
	if script == null:
		return null
	var instance: Variant = script.new(PlayerState)
	if instance is Object:
		_system_cache["summon"] = instance
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


func _detail(result: Dictionary) -> Dictionary:
	# Systems merge payload fields at the top level while leaving empty data.
	var data: Variant = result.get("data", {})
	if data is Dictionary and not (data as Dictionary).is_empty():
		return data as Dictionary
	return result


func _first_int(data: Dictionary, keys: Array[String], default_value: int) -> int:
	for key: String in keys:
		if data.has(key):
			var parsed := _to_int(data[key])
			if parsed > 0:
				return parsed
	return default_value


func _first_string(data: Dictionary, keys: Array[String], default_value: String) -> String:
	for key: String in keys:
		if data.has(key):
			var value := str(data[key])
			if not value.is_empty():
				return value
	return default_value


func _to_int(value: Variant) -> int:
	if value is int or value is float:
		return int(value)
	if value is String:
		var text := value as String
		return text.to_int() if text.is_valid_int() else 0
	return 0


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
