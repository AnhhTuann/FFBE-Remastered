extends Control

## Phase 4 shop screen. Stock, prices and limits are synthetic fixture data;
## no original FFBE shop inventory is asserted.

const HUB_PATH := "res://scenes/phase3/economy_hub.tscn"
const TRANSIT_NAME := "selection"
const SHOP_CLASS_NAME := "ShopSystem"
const SHOP_SCRIPT_PATHS: Array[String] = [
	"res://systems/shop_system.gd",
	"res://core/shop_system.gd",
	"res://systems/phase4/shop_system.gd"
]
const QUANTITIES: Array[int] = [1, 2, 3, 5, 10]

var _shops: Array[Dictionary] = []
var _stock: Array[Dictionary] = []
var _selected_shop_id: String = ""
var _quantity: int = 1
var _shop_option: OptionButton = null
var _quantity_option: OptionButton = null
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
	layout.add_child(_header("shop.title", HUB_PATH))

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
	_load_shops()
	_render()


func _exit_tree() -> void:
	if LocaleManager.locale_changed.is_connected(_apply_locale):
		LocaleManager.locale_changed.disconnect(_apply_locale)


func t(key: String, args: Dictionary = {}) -> String:
	return LocaleManager.t(key, args)


func _apply_locale(_locale: String = "") -> void:
	if _title_label != null:
		_title_label.text = t("shop.title")
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


func _load_shops() -> void:
	_shops.clear()
	var system := _shop_system()
	if system == null:
		return
	_shops = _as_array(system.call("shops"))
	if _shops.is_empty():
		_selected_shop_id = ""
		return
	for shop: Dictionary in _shops:
		var id := str(shop.get("id", ""))
		if _selected_shop_id.is_empty() or id == _selected_shop_id:
			_selected_shop_id = id
			break
	_load_stock()


func _load_stock() -> void:
	_stock.clear()
	var system := _shop_system()
	if system == null or _selected_shop_id.is_empty():
		return
	_stock = _as_array(_call(system, "stock", [_selected_shop_id]))


func _render() -> void:
	if _content == null:
		return
	for child: Node in _content.get_children():
		child.queue_free()

	var system := _shop_system()
	if system == null:
		_line(_panel("common.system_unavailable"), t("common.system_unavailable", {"name": SHOP_CLASS_NAME}))
		return

	var shop_box := _panel("shop.shops")
	if _shops.is_empty():
		_line(shop_box, t("shop.empty"))
	else:
		_shop_option = OptionButton.new()
		_shop_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for shop: Dictionary in _shops:
			var id := str(shop.get("id", ""))
			var index: int = _shop_option.item_count
			_shop_option.add_item(LocaleManager.label_for(shop))
			_shop_option.set_item_metadata(index, id)
			if id == _selected_shop_id:
				_shop_option.selected = index
		_shop_option.item_selected.connect(func(index: int) -> void: _on_shop_selected(index))
		shop_box.add_child(_shop_option)

	var buy_box := _panel("common.buy")
	_quantity_option = OptionButton.new()
	_quantity_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for value: int in QUANTITIES:
		var index: int = _quantity_option.item_count
		_quantity_option.add_item(str(value))
		_quantity_option.set_item_metadata(index, value)
		if value == _quantity:
			_quantity_option.selected = index
	_quantity_option.item_selected.connect(func(index: int) -> void: _on_quantity_selected(index))
	_line(buy_box, t("common.quantity") + ": " + str(_quantity))
	buy_box.add_child(_quantity_option)

	var stock_box := _panel("shop.stock")
	if _selected_shop_id.is_empty():
		_line(stock_box, t("shop.select_shop"))
	elif _stock.is_empty():
		_line(stock_box, t("shop.stock.empty"))
	else:
		for entry: Dictionary in _stock:
			stock_box.add_child(_stock_row(entry))

	_line(_panel("common.evidence"), LocaleManager.mechanic_status_label("REMASTERED_DESIGN") + " · " + \
		LocaleManager.verification_label("SYNTHETIC_FIXTURE"))


func _on_shop_selected(index: int) -> void:
	if _shop_option == null or index < 0 or index >= _shop_option.item_count:
		return
	_selected_shop_id = str(_shop_option.get_item_metadata(index))
	_load_stock()
	_render()


func _on_quantity_selected(index: int) -> void:
	if _quantity_option == null or index < 0 or index >= _quantity_option.item_count:
		return
	_quantity = _to_int(_quantity_option.get_item_metadata(index))
	_render()


func _stock_row(entry: Dictionary) -> Control:
	var stock_id := _id_from(entry)
	var panel := _styled_panel(null, Color(0.071, 0.129, 0.204))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_line(box, LocaleManager.identified(LocaleManager.label_for(entry), stock_id))
	var cost: Variant = entry.get("cost", entry.get("price", {}))
	if not (cost is Dictionary and (cost as Dictionary).is_empty()):
		_line(box, t("common.cost") + ": " + _value_text("cost", cost))
	_line(box, t("common.limit") + ": " + _limit_text(entry, stock_id))
	for line: String in _lines_for(entry, ["id", "stock_id", "name_key", "display_name", "cost", "price", "purchased", "limit"]):
		_line(box, line)
	box.add_child(_button(t("common.buy"), func() -> void: _buy(stock_id)))
	panel.add_child(box)
	return panel


func _buy(stock_id: String) -> void:
	var system := _shop_system()
	if system == null or _selected_shop_id.is_empty() or stock_id.is_empty():
		_set_status("reason.invalid_id")
		return
	_receipt_counter += 1
	var receipt := "qa-%d-%d-%d" % [_now(), Time.get_ticks_usec(), _receipt_counter]
	var result := _call(system, "buy", [_selected_shop_id, stock_id, _quantity, receipt])
	if result.is_empty():
		_set_status("common.system_unavailable", {"name": SHOP_CLASS_NAME})
		return
	if not bool(result.get("ok", true)):
		_set_status("common.failed", {}, _reason_suffix(result))
		_render()
		return
	# ShopSystem.buy() already commits the save once.
	_set_status("shop.bought")
	_load_stock()
	_render()


func _limit_text(entry: Dictionary, stock_id: String) -> String:
	var used := _first_int(entry, ["purchased", "bought", "claimed"], 0)
	var purchase_key := _selected_shop_id + "|" + stock_id
	var section: Variant = PlayerState.data.get("shops", {})
	if section is Dictionary:
		var purchases: Variant = (section as Dictionary).get("purchases", {})
		if purchases is Dictionary and (purchases as Dictionary).has(purchase_key):
			used = maxi(used, _to_int((purchases as Dictionary)[purchase_key]))
	var limit := _first_int(entry, ["limit", "max_purchases", "stock_limit"], 0)
	if limit <= 0:
		return str(used) + " / " + t("common.unavailable")
	return str(used) + " / " + str(limit)


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
		for key: String in ["stock_id", "id", "definition_id", "item_id"]:
			if record.has(key):
				return str(record[key])
		return ""
	if entry is String:
		return entry as String
	return ""


func _now() -> int:
	var override := OS.get_environment("FFBE_QA_NOW_UNIX")
	if not override.is_empty() and override.is_valid_int():
		return maxi(0, override.to_int())
	return Time.get_unix_time_from_system()


func _shop_system() -> Object:
	if _system_cache.has("shop"):
		var cached: Variant = _system_cache["shop"]
		if cached is Object and is_instance_valid(cached):
			return cached as Object
		_system_cache.erase("shop")
	var path := _script_path(SHOP_CLASS_NAME, SHOP_SCRIPT_PATHS)
	if path.is_empty():
		return null
	var script: Script = load(path) as Script
	if script == null:
		return null
	var instance: Variant = script.new(PlayerState)
	if instance is Object:
		_system_cache["shop"] = instance
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
