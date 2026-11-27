extends Control

## Prompt 07 Event Center with the Prompt 07.2 presentation redesign.
## All displayed copy resolves through LocaleManager; all definitions remain
## read-only synthetic fixtures. Gameplay services, WorldContext navigation and
## save behaviour are intentionally unchanged from Prompt 07.1.

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"
const EVENT_CENTER_PATH := "res://scenes/event/event_center.tscn"
const BATTLE_PATH := "res://scenes/battle/battle_scene.tscn"
const SUMMON_PATH := "res://scenes/phase3/summon.tscn"

var _repository: EventRepository = null
var _schedule: EventSchedule = null
var _service: EventStateService = null
var _status_filter: String = "all"
var _category_filter: String = "all"
var _region: String = "GL"
var _selected_event_id: String = ""
var _selected_stage_id: String = ""
var _result_message: String = ""
var _qa_focus_key: String = ""
var _portrait: bool = false
var _portrait_override: int = -1
var _compact: bool = false
var _wide: bool = false
var _layout_key_current: String = ""
var _building: bool = false
var _detail_box: VBoxContainer = null
var _list_box: VBoxContainer = null
var _status_label: Label = null
var _region_button: Button = null


func _ready() -> void:
	set_theme(EventTheme.build_theme())
	_repository = EventRepository.new()
	var clock: Callable = Callable()
	var qa_now: String = OS.get_environment("FFBE_QA_EVENT_NOW_UNIX")
	if qa_now.is_valid_int():
		clock = func() -> int: return maxi(0, qa_now.to_int())
	_schedule = EventSchedule.new(clock)
	_service = EventStateService.new(PlayerState, _repository)
	_apply_return_context()
	_apply_scenario_hooks()
	resized.connect(_on_resized)
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_rebuild()


func t(key: String, args: Dictionary = {}) -> String:
	return LocaleManager.t(key, args)


func _apply_return_context() -> void:
	var context: Dictionary = WorldContext.peek()
	if context.is_empty() or not context.has("event_id"):
		return
	if OS.get_environment("FFBE_QA_MODE").strip_edges() == "1":
		print("EVENT_CENTER_QA_RETURN event=%s stage=%s" % [
			str(context.get("event_id", "")), str(context.get("stage_id", ""))
		])
	WorldContext.consume()
	_region = str(context.get("region", _region))
	_selected_event_id = str(context.get("event_id", ""))
	_selected_stage_id = str(context.get("stage_id", ""))
	var battle_result_variant: Variant = context.get("battle_result", {})
	var battle_result: Dictionary = battle_result_variant if battle_result_variant is Dictionary else {}
	_result_message = _result_message_for(battle_result)


func _result_message_for(result: Dictionary) -> String:
	if result.is_empty():
		return ""
	if bool(result.get("duplicate", false)):
		return t("event.center.result.duplicate")
	var reason: String = str(result.get("reason", ""))
	if reason == "save_failed":
		return t("event.center.result.save_failed")
	if bool(result.get("victory", false)):
		return t("event.center.result.victory")
	return t("event.center.result.defeat")


func _apply_scenario_hooks() -> void:
	var scenario: String = OS.get_environment("FFBE_QA_EVENT_CENTER_VIEW")
	var requested_event: String = OS.get_environment("FFBE_QA_EVENT_ID")
	var requested_region: String = OS.get_environment("FFBE_QA_REGION")
	if not requested_region.is_empty():
		_region = requested_region
	if not requested_event.is_empty():
		_selected_event_id = requested_event
		_selected_stage_id = ""
	_qa_focus_key = ""
	match scenario:
		"overview":
			_selected_event_id = ""
			_selected_stage_id = ""
			_status_filter = "all"
			_category_filter = "all"
		"active":
			_selected_event_id = ""
			_selected_stage_id = ""
			_status_filter = "active"
			_category_filter = "all"
		"upcoming":
			_selected_event_id = ""
			_selected_stage_id = ""
			_status_filter = "upcoming"
			_category_filter = "all"
		"ended":
			_selected_event_id = ""
			_selected_stage_id = ""
			_status_filter = "ended"
			_category_filter = "all"
		"categories":
			_selected_event_id = ""
			_selected_stage_id = ""
			_status_filter = "all"
			_category_filter = "story"
		"detail":
			if _selected_event_id.is_empty():
				_selected_event_id = "event:GL:980001@stargarden"
		"stages":
			_selected_event_id = "event:GL:980001@stargarden"
			_selected_stage_id = "stage:GL:980101@gate"
			_qa_focus_key = "event.center.stages"
		"rewards":
			_selected_event_id = "event:GL:980001@stargarden"
			_qa_focus_key = "event.center.rewards"
		"shop":
			_selected_event_id = "event:GL:980001@stargarden"
			_qa_focus_key = "event.center.shop"
		"summon":
			if _selected_event_id.is_empty():
				_selected_event_id = "event:GL:980001@stargarden"
			_qa_focus_key = "event.center.summon_nav"
		"archive":
			_selected_event_id = "event:GL:980004@archive"
			_status_filter = "archive"
		"replay":
			_selected_event_id = "event:GL:980003@lumenguest"
			_selected_stage_id = "stage:GL:980121@guest"
			_status_filter = "archive"
			_qa_focus_key = "event.center.stages"
		"collaboration":
			_selected_event_id = "event:GL:980003@lumenguest"
			_category_filter = "collaboration"
		_:
			pass


func _region_text() -> String:
	return t("code.region.%s" % _region.to_lower())


func _layout_key() -> String:
	var size: Vector2 = get_viewport_rect().size
	if _portrait_override == 1:
		return "portrait"
	if _portrait_override == 0:
		if size.x < 1150:
			return "compact"
		return "wide" if size.x >= 1600 else "standard"
	if size.y > size.x:
		return "portrait"
	if size.x < 1150:
		return "compact"
	return "wide" if size.x >= 1600 else "standard"


func _update_profile() -> void:
	var key: String = _layout_key()
	_layout_key_current = key
	_portrait = key == "portrait"
	_compact = key == "compact"
	_wide = key == "wide"


func _on_resized() -> void:
	if _building or _portrait_override >= 0:
		return
	if _layout_key() != _layout_key_current:
		_rebuild()


func _on_locale_changed(_locale: String) -> void:
	_rebuild()


func _rebuild() -> void:
	if _repository == null:
		return
	_building = true
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_update_profile()
	set_theme(EventTheme.build_theme())

	var backdrop := EventBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset: int = 10 if _portrait else 12 if _compact else 18 if not _wide else 24
	margin.add_theme_constant_override("margin_left", inset)
	margin.add_theme_constant_override("margin_top", inset)
	margin.add_theme_constant_override("margin_right", inset)
	margin.add_theme_constant_override("margin_bottom", inset)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6 if _compact else 8)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(layout)
	layout.add_child(_build_header())
	layout.add_child(_build_filters())
	var main: Node = _build_main()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(main)
	_status_label = EventTheme.make_label(
		_result_message, EventTheme.FONT_SMALL,
		EventTheme.CYAN if not _result_message.is_empty() else EventTheme.TEXT_MUTED
	)
	_status_label.custom_minimum_size = Vector2(0, 26 if _portrait else 22)
	layout.add_child(_status_label)

	_building = false
	call_deferred("_apply_qa_focus")
	call_deferred("_emit_qa_ready")


## Emitted only for QA captures after two rendered frames, so the capture wrapper
## waits for a laid-out window instead of a transient pre-layout grey frame.
func _emit_qa_ready() -> void:
	if OS.get_environment("FFBE_QA_EVENT_CENTER_VIEW").is_empty():
		return
	await get_tree().process_frame
	await get_tree().process_frame
	print("EVENT_CENTER_QA_READY view=%s" % OS.get_environment("FFBE_QA_EVENT_CENTER_VIEW"))


## QA-only detail scroll positioning. It moves an existing rendered section into
## view; it does not synthesize a mock screen or alter gameplay state.
func _apply_qa_focus() -> void:
	if _qa_focus_key.is_empty():
		return
	var target_text: String = t(_qa_focus_key)
	var label: Label = _find_label_text(self, target_text)
	if label == null:
		return
	var scroll: ScrollContainer = _scroll_for_label(label)
	if scroll == null:
		return
	var offset: float = _logical_y_in(label, scroll.get_child(0))
	scroll.scroll_vertical = maxi(0, int(offset - 8))


## Computes an unscrolled Y offset from declared control sizes, so QA focus does
## not depend on a canvas transform that may not have settled yet.
func _logical_y_in(node: Node, ancestor: Node) -> float:
	var result: float = 0.0
	var cursor: Node = node
	while cursor != null and cursor != ancestor:
		var parent: Node = cursor.get_parent()
		if parent == null:
			break
		if parent is VBoxContainer:
			var separation: float = float((parent as VBoxContainer).get_theme_constant("separation"))
			for sibling: Node in parent.get_children():
				if sibling == cursor:
					break
				if sibling is Control:
					result += (sibling as Control).get_combined_minimum_size().y + separation
		elif parent is HBoxContainer:
			pass
		elif cursor is Control:
			var local_y: float = (cursor as Control).position.y
			if is_zero_approx(local_y):
				local_y = 9.0
			result += local_y
		cursor = parent
	return result


func _scroll_for_label(node: Node) -> ScrollContainer:
	var cursor: Node = node
	while cursor != null:
		if cursor is ScrollContainer:
			return cursor as ScrollContainer
		cursor = cursor.get_parent()
	return null


func _find_first_scroll(node: Node) -> ScrollContainer:
	if node.is_queued_for_deletion():
		return null
	if node is ScrollContainer:
		return node as ScrollContainer
	for child: Node in node.get_children():
		var found: ScrollContainer = _find_first_scroll(child)
		if found != null:
			return found
	return null


func _find_label_text(node: Node, needle: String) -> Label:
	if node.is_queued_for_deletion():
		return null
	if node is Label and str((node as Label).text) == needle:
		return node as Label
	for child: Node in node.get_children():
		var found: Label = _find_label_text(child, needle)
		if found != null:
			return found
	return null


func _build_header() -> Node:
	var panel := EventTheme.make_panel(true, true)
	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 2)
	panel.add_child(shell)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := EventTheme.make_label(
		t("event.center.title"),
		EventTheme.FONT_HERO if not _compact else EventTheme.FONT_TITLE,
		EventTheme.GOLD
	)
	titles.add_child(title)
	var subtitle := EventTheme.make_label(
		t("event.center.subtitle"), EventTheme.FONT_SMALL, EventTheme.TEXT_MUTED
	)
	titles.add_child(subtitle)
	top.add_child(titles)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 6)
	var currency := EventTheme.make_label(
		_currency_summary(), EventTheme.FONT_SMALL, EventTheme.CYAN
	)
	currency.custom_minimum_size = Vector2(0, 30)
	controls.add_child(currency)

	_region_button = Button.new()
	_region_button.text = "%s: %s" % [t("event.center.region"), _region_text()]
	_region_button.custom_minimum_size = Vector2(96 if _portrait else 108, 34)
	_region_button.pressed.connect(_toggle_region)
	_style_secondary_button(_region_button)
	controls.add_child(_region_button)

	var back := Button.new()
	back.text = t("event.center.back")
	back.custom_minimum_size = Vector2(80 if _portrait else 104, 34)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MAIN_MENU_PATH))
	_style_secondary_button(back)
	controls.add_child(back)
	top.add_child(controls)
	shell.add_child(top)
	return panel


func _currency_summary() -> String:
	var currency_id: String = str(_repository.get_event(_selected_event_id).get("event_currency", ""))
	if currency_id.is_empty():
		for event: Dictionary in _repository.get_events():
			if _repository.region_config(str(event.get("id", "")), _region).is_empty():
				continue
			var candidate: String = str(event.get("event_currency", ""))
			if not candidate.is_empty():
				currency_id = candidate
				break
	var amount: int = _service.currency_amount(currency_id) if not currency_id.is_empty() else 0
	return t("event.center.currency_summary", {"amount": amount})


func _build_filters() -> Node:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 3)
	outer.add_child(_build_filter_row(
		t("event.center.availability"),
		[
			["all", "event.center.filter.all"], ["active", "event.center.filter.active"],
			["upcoming", "event.center.filter.upcoming"], ["ended", "event.center.filter.ended"],
			["archive", "event.center.filter.archive"],
			["collaboration", "event.center.filter.collaboration"]
		],
		_status_filter,
		_set_status_filter
	))
	outer.add_child(_build_filter_row(
		t("event.center.category.heading"),
		[
			["all", "event.center.category.all"], ["story", "event.center.category.story"],
			["limited", "event.center.category.limited"],
			["permanent", "event.center.category.permanent"],
			["collaboration", "event.center.category.collaboration"],
			["seasonal", "event.center.category.seasonal"],
			["challenge", "event.center.category.challenge"]
		],
		_category_filter,
		_set_category_filter
	))
	return outer


func _build_filter_row(heading: String, items: Array, selected: String, handler: Callable) -> Node:
	var shell := EventTheme.make_panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	shell.add_child(box)
	box.add_child(EventTheme.make_label(heading, EventTheme.FONT_TINY, EventTheme.TEXT_MUTED))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 38)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)
	for item: Array in items:
		var value: String = str(item[0])
		var button := Button.new()
		button.text = t(str(item[1]))
		button.toggle_mode = true
		button.button_pressed = value == selected
		button.custom_minimum_size = Vector2(78 if _compact else 92, 30)
		button.pressed.connect(handler.bind(value))
		_style_filter_button(button, value == selected)
		row.add_child(button)
	return shell


func _style_filter_button(button: Button, selected: bool) -> void:
	var border: Color = EventTheme.CYAN if selected else EventTheme.GOLD_DIM
	var bg: Color = EventTheme.PANEL_ELEVATED if selected else EventTheme.PANEL
	button.add_theme_stylebox_override(
		"normal", EventTheme.make_style(bg, border, EventTheme.RADIUS, 2 if selected else 1, 8)
	)
	button.add_theme_stylebox_override(
		"hover", EventTheme.make_style(bg.lightened(0.06), EventTheme.CYAN, EventTheme.RADIUS, 2, 8)
	)
	button.add_theme_stylebox_override(
		"pressed", EventTheme.make_style(EventTheme.PANEL, EventTheme.GOLD, EventTheme.RADIUS, 2, 8)
	)
	button.add_theme_stylebox_override(
		"focus", EventTheme.make_style(Color(0, 0, 0, 0), EventTheme.CYAN, EventTheme.RADIUS, 2, 8)
	)
	button.add_theme_color_override(
		"font_color", EventTheme.CYAN if selected else EventTheme.TEXT
	)


func _style_secondary_button(button: Button) -> void:
	button.add_theme_stylebox_override(
		"normal", EventTheme.make_style(EventTheme.PANEL_ELEVATED, EventTheme.GOLD_DIM, EventTheme.RADIUS, 1, 10)
	)
	button.add_theme_stylebox_override(
		"hover", EventTheme.make_style(EventTheme.PANEL_ELEVATED.lightened(0.06), EventTheme.CYAN, EventTheme.RADIUS, 2, 10)
	)
	button.add_theme_stylebox_override(
		"pressed", EventTheme.make_style(EventTheme.PANEL, EventTheme.GOLD, EventTheme.RADIUS, 2, 10)
	)
	button.add_theme_stylebox_override(
		"focus", EventTheme.make_style(Color(0, 0, 0, 0), EventTheme.CYAN, EventTheme.RADIUS, 2, 10)
	)


func _style_primary_button(button: Button) -> void:
	button.add_theme_stylebox_override(
		"normal", EventTheme.make_style(EventTheme.CYAN.darkened(0.22), EventTheme.GOLD, EventTheme.RADIUS, 2, 12)
	)
	button.add_theme_stylebox_override(
		"hover", EventTheme.make_style(EventTheme.CYAN.darkened(0.12), EventTheme.CYAN, EventTheme.RADIUS, 2, 12)
	)
	button.add_theme_stylebox_override(
		"pressed", EventTheme.make_style(EventTheme.PANEL_ELEVATED, EventTheme.GOLD, EventTheme.RADIUS, 2, 12)
	)
	button.add_theme_stylebox_override(
		"focus", EventTheme.make_style(Color(0, 0, 0, 0), EventTheme.CYAN, EventTheme.RADIUS, 2, 12)
	)
	button.add_theme_color_override("font_color", EventTheme.TEXT)


func _make_scroll() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return scroll


func _build_main() -> Node:
	var main: Node = VBoxContainer.new() if _portrait else HBoxContainer.new()
	(main as Container).add_theme_constant_override("separation", 8 if _compact else 10)

	var list_panel := EventTheme.make_panel()
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if _portrait else Control.SIZE_FILL
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list_width: int = 0 if _portrait else 268 if _compact else 314 if not _wide else 356
	if list_width > 0:
		list_panel.custom_minimum_size = Vector2(list_width, 0)
	var list_scroll := _make_scroll()
	list_panel.add_child(list_scroll)
	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 6)
	list_scroll.add_child(_list_box)
	main.add_child(list_panel)
	_populate_event_list()

	var detail_panel := EventTheme.make_panel(true, true)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var detail_scroll := _make_scroll()
	detail_panel.add_child(detail_scroll)
	_detail_box = VBoxContainer.new()
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_box.add_theme_constant_override("separation", 7)
	detail_scroll.add_child(_detail_box)
	main.add_child(detail_panel)
	_populate_detail()

	if _wide:
		main.add_child(_build_status_rail())
	return main


func _build_status_rail() -> Node:
	var rail := EventTheme.make_panel(true, true)
	rail.custom_minimum_size = Vector2(240, 0)
	rail.size_flags_horizontal = Control.SIZE_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	rail.add_child(box)
	box.add_child(EventTheme.make_label(t("event.center.detail.title"), EventTheme.FONT_TITLE, EventTheme.GOLD))
	box.add_child(EventTheme.make_label(t("event.center.status"), EventTheme.FONT_TINY, EventTheme.TEXT_MUTED))
	box.add_child(EventTheme.make_label(_result_message if not _result_message.is_empty() else t("event.center.detail.empty"), EventTheme.FONT_SMALL, EventTheme.TEXT))
	box.add_child(EventTheme.make_label(t("event.center.region"), EventTheme.FONT_TINY, EventTheme.TEXT_MUTED))
	box.add_child(EventTheme.make_label(_region_text(), EventTheme.FONT_BODY, EventTheme.CYAN))
	box.add_child(EventTheme.make_label(t("event.center.currency"), EventTheme.FONT_TINY, EventTheme.TEXT_MUTED))
	box.add_child(EventTheme.make_label(_currency_summary(), EventTheme.FONT_BODY, EventTheme.CYAN))
	return rail


func _populate_event_list() -> void:
	for child: Node in _list_box.get_children():
		_list_box.remove_child(child)
		child.queue_free()
	var now_unix: int = _schedule.now()
	for event: Dictionary in _repository.get_events():
		var region_config: Dictionary = _repository.region_config(str(event.get("id", "")), _region)
		if region_config.is_empty():
			continue
		if _category_filter != "all" and str(event.get("category", "")) != _category_filter:
			continue
		var event_id: String = str(event.get("id", ""))
		var unlocked: bool = _service != null and _service.is_event_unlocked(event_id, _region)
		var current_state: String = _schedule.state(event, _region, unlocked, now_unix)
		if not _matches_status_filter(current_state, str(event.get("category", ""))):
			continue
		var state_text: String = t(_schedule.state_key(current_state)) if unlocked else t("event.center.locked")
		var category: String = str(event.get("category", ""))
		var card_width: float = 300.0 if not _portrait and not _compact else 660.0 if _portrait else 250.0
		var art_width: float = 600.0 if _portrait else 216.0 if _compact else 272.0
		var art_height: float = 104.0 if _portrait else 64.0 if _compact else 92.0
		var card: EventCard = _make_card({
			"kind": "event",
			"payload": {"event_id": event_id},
			"badge": state_text,
			"title": t(str(event.get("name_key", ""))),
			"state": state_text,
			"state_key": current_state if unlocked else "locked",
			"subtitle": t("event.center.category.%s" % category),
			"meta": _schedule_text(region_config),
			"show_art": true,
			"art_event_id": event_id,
			"art_category": category,
			"art_caption": t("event.center.art.placeholder"),
			"art_minimum_size": Vector2(art_width, art_height),
			"selected": event_id == _selected_event_id,
			"minimum_size": Vector2(card_width, 190.0 if not _compact and not _portrait else 154.0)
		}, func(payload: Dictionary) -> void: _select_event(str(payload.get("event_id", ""))))
		_list_box.add_child(card)


func _matches_status_filter(current_state: String, category: String) -> bool:
	match _status_filter:
		"active":
			return current_state == EventSchedule.STATE_ACTIVE
		"upcoming":
			return current_state == EventSchedule.STATE_UPCOMING
		"ended":
			return current_state == EventSchedule.STATE_ENDED \
				or current_state == EventSchedule.STATE_ARCHIVED \
				or current_state == EventSchedule.STATE_REPLAYABLE
		"archive":
			return current_state == EventSchedule.STATE_ARCHIVED \
				or current_state == EventSchedule.STATE_REPLAYABLE
		"collaboration":
			return category == "collaboration"
		_:
			return true


func _populate_detail() -> void:
	for child: Node in _detail_box.get_children():
		_detail_box.remove_child(child)
		child.queue_free()
	var event: Dictionary = _repository.get_event(_selected_event_id)
	if event.is_empty():
		var empty := EventTheme.make_panel()
		empty.add_child(EventTheme.make_label(t("event.center.detail.empty"), EventTheme.FONT_BODY, EventTheme.TEXT_MUTED))
		_detail_box.add_child(empty)
		return

	var now_unix: int = _schedule.now()
	var event_id: String = str(event.get("id", ""))
	var category: String = str(event.get("category", ""))
	var unlocked: bool = _service != null and _service.is_event_unlocked(event_id, _region)
	var current_state: String = _schedule.state(event, _region, unlocked, now_unix)
	var config: Dictionary = _repository.region_config(event_id, _region)
	var state_text: String = t(_schedule.state_key(current_state)) if unlocked else t("event.center.locked")

	_detail_box.add_child(_build_hero(event, category, state_text, config))

	_add_section_heading("event.center.stages")
	var stages: Array[Dictionary] = _repository.stages_for_event(event_id)
	var stage_grid := _make_grid()
	for stage: Dictionary in stages:
		stage_grid.add_child(_stage_card(event, stage, current_state))
	_detail_box.add_child(stage_grid)

	_add_section_heading("event.center.rewards")
	var reward_grid := _make_grid()
	for stage: Dictionary in stages:
		reward_grid.add_child(_reward_card(stage))
	_detail_box.add_child(reward_grid)

	_add_section_heading("event.center.missions")
	var mission_grid := _make_grid()
	for mission_variant: Variant in (event.get("missions", []) as Array):
		mission_grid.add_child(_mission_card(event_id, mission_variant))
	_detail_box.add_child(mission_grid)

	var shop_items: Array[Dictionary] = _repository.shop_items(event_id)
	if not shop_items.is_empty():
		_add_section_heading("event.center.shop")
		var shop_grid := _make_grid()
		for item: Dictionary in shop_items:
			shop_grid.add_child(_shop_card(event_id, item))
		_detail_box.add_child(shop_grid)

	var banner_ref: String = _repository.banner_ref(event_id, _region)
	if not banner_ref.is_empty():
		var summon_card: EventCard = _make_card({
			"kind": "summon",
			"payload": {"event_id": event_id},
			"badge": t("event.center.banner"),
			"title": t("event.center.summon_nav"),
			"state": t("event.center.summon_nav"),
			"state_key": "active",
			"subtitle": t("event.center.detail.title"),
			"minimum_size": Vector2(280.0, 92.0)
		}, func(payload: Dictionary) -> void: _open_banner(str(payload.get("event_id", ""))))
		_detail_box.add_child(summon_card)


func _build_hero(
	event: Dictionary, category: String, state_text: String, config: Dictionary
) -> Node:
	var panel := EventTheme.make_panel(true, true)
	var shell: Container = VBoxContainer.new() if _portrait else HBoxContainer.new()
	shell.add_theme_constant_override("separation", 10)
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(shell)
	var event_id: String = str(event.get("id", ""))
	var art := EventArtwork.new()
	art.configure(
		event_id, category, EventTheme.accent_for_category(category),
		t("event.center.art.placeholder"), _hero_art_size()
	)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL if _portrait else Control.SIZE_FILL
	shell.add_child(art)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	shell.add_child(info)
	info.add_child(EventTheme.make_label(
		t(str(event.get("name_key", ""))),
		EventTheme.FONT_TITLE if _compact else EventTheme.FONT_HERO,
		EventTheme.GOLD
	))
	info.add_child(EventTheme.make_label(
		t(str(event.get("description_key", ""))), EventTheme.FONT_SMALL, EventTheme.TEXT
	))
	info.add_child(EventTheme.make_label(
		"%s: %s" % [t("event.center.status"), state_text], EventTheme.FONT_SMALL, EventTheme.CYAN
	))
	info.add_child(EventTheme.make_label(
		"%s: %s" % [t("event.center.region"), _region_text()], EventTheme.FONT_SMALL, EventTheme.TEXT_MUTED
	))
	info.add_child(EventTheme.make_label(
		"%s: %s" % [t("event.center.schedule"), _schedule_text(config)],
		EventTheme.FONT_SMALL, EventTheme.TEXT_MUTED
	))
	var currency_id: String = str(event.get("event_currency", ""))
	info.add_child(EventTheme.make_label(
		"%s: %s" % [
			t("event.center.currency"),
			_currency_text(currency_id, _service.currency_amount(currency_id))
		],
		EventTheme.FONT_SMALL, EventTheme.CYAN
	))
	info.add_child(_primary_action(event))
	return panel


func _hero_art_size() -> Vector2:
	if _portrait:
		return Vector2(300, 140)
	if _compact:
		return Vector2(250, 108)
	return Vector2(400, 158) if not _wide else Vector2(460, 176)


func _primary_action(event: Dictionary) -> Node:
	var event_id: String = str(event.get("id", ""))
	var stages: Array[Dictionary] = _repository.stages_for_event(event_id)
	var event_unlocked: bool = _service.is_event_unlocked(event_id, _region)
	var action_stage: Dictionary = {}
	var enterable: bool = _schedule.can_enter(event, _region, event_unlocked, _schedule.now())
	for stage: Dictionary in stages:
		if enterable and bool(_service.can_launch_stage(
			event_id, str(stage.get("id", "")), _region
		).get("ok", false)):
			action_stage = stage
			break
	var button := Button.new()
	button.text = "%s%s" % [
		t("event.center.enter"),
		"" if action_stage.is_empty() else " · " + t(str(action_stage.get("name_key", "")))
	]
	button.custom_minimum_size = Vector2(0, 34)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = action_stage.is_empty()
	if not action_stage.is_empty():
		button.pressed.connect(_launch_stage.bind(event_id, str(action_stage.get("id", ""))))
	_style_primary_button(button)
	return button


func _make_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 1 if _portrait or _compact else 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return grid


func _add_section_heading(key: String) -> void:
	var heading := EventTheme.make_label(t(key), EventTheme.FONT_TITLE, EventTheme.GOLD)
	heading.custom_minimum_size = Vector2(0, 26)
	_detail_box.add_child(heading)


func _make_card(data: Dictionary, handler: Callable) -> EventCard:
	var card := EventCard.new()
	card.configure(data)
	card.activated.connect(handler)
	return card


func _stage_card(event: Dictionary, stage: Dictionary, current_state: String) -> EventCard:
	var event_id: String = str(event.get("id", ""))
	var stage_id: String = str(stage.get("id", ""))
	var progress: Dictionary = _service.get_stage_progress(event_id, stage_id)
	var runs: int = int(progress.get("runs", 0))
	var target: int = maxi(1, int(stage.get("completion_target", 1)))
	var state_text: String = t("event.center.stage_unlocked")
	var state_key: String = ""
	if bool(progress.get("completed", false)):
		state_text = t("event.center.stage_completed")
		state_key = "complete"
	elif bool(progress.get("cleared", false)):
		state_text = t("event.center.stage_cleared")
		state_key = "claimable"
	var launch: Dictionary = _service.can_launch_stage(event_id, stage_id, _region)
	var unlocked: bool = bool(launch.get("ok", false))
	var event_unlocked: bool = _service.is_event_unlocked(event_id, _region)
	var enterable: bool = _schedule.can_enter(event, _region, event_unlocked, _schedule.now())
	if not unlocked:
		state_text = t("event.center.locked")
		state_key = "locked"
	var first_reward: Dictionary = _reward_dict(stage.get("first_clear_reward", {}))
	var repeat_reward: Dictionary = _reward_dict(stage.get("repeat_reward", {}))
	return _make_card({
		"kind": "stage",
		"payload": {"event_id": event_id, "stage_id": stage_id},
		"badge": t("event.center.stages"),
		"title": t(str(stage.get("name_key", ""))),
		"state": state_text,
		"state_key": state_key,
		"subtitle": t("event.center.runs", {"current": runs, "target": target}),
		"meta": "%s: %s" % [t("event.center.enter"), state_text],
		"reward": "%s: %s · %s: %s" % [
			t("event.center.first_clear"), _reward_text(first_reward),
			t("event.center.repeat"), _reward_text(repeat_reward)
		],
		"disabled": not unlocked or not enterable or current_state == EventSchedule.STATE_ARCHIVED,
		"selected": stage_id == _selected_stage_id,
		"minimum_size": Vector2(300.0 if not _compact else 250.0, 126.0)
	}, func(payload: Dictionary) -> void: _launch_stage(
		str(payload.get("event_id", "")), str(payload.get("stage_id", ""))
	))


func _reward_card(stage: Dictionary) -> EventCard:
	var first_reward: Dictionary = _reward_dict(stage.get("first_clear_reward", {}))
	var repeat_reward: Dictionary = _reward_dict(stage.get("repeat_reward", {}))
	return _make_card({
		"kind": "reward",
		"payload": {"stage_id": str(stage.get("id", ""))},
		"badge": t("event.center.rewards"),
		"title": t(str(stage.get("name_key", ""))),
		"state": t("event.center.reward_summary"),
		"state_key": "complete",
		"subtitle": "%s: %s" % [t("event.center.first_clear"), _reward_text(first_reward)],
		"meta": "%s: %s" % [t("event.center.repeat"), _reward_text(repeat_reward)],
		"minimum_size": Vector2(300.0 if not _compact else 250.0, 104.0)
	}, func(_payload: Dictionary) -> void: pass)


func _mission_card(event_id: String, mission_variant: Variant) -> EventCard:
	if not mission_variant is Dictionary:
		return _make_card({"kind": "mission", "title": "", "minimum_size": Vector2(300, 96)}, func(_payload: Dictionary) -> void: pass)
	var mission: Dictionary = mission_variant
	var mission_id: String = str(mission.get("id", ""))
	var status: Dictionary = _service.mission_status(event_id, mission_id)
	var claimable: bool = bool(status.get("claimable", false))
	var repeatable: bool = bool(status.get("repeatable", false))
	var claimed: bool = bool(status.get("claimed", false))
	var state_text: String = t("event.center.claim")
	var state_key: String = "claimable"
	# A repeatable mission is never globally "claimed"; it always exposes the
	# next cycle, even when that cycle is incomplete and the button is disabled.
	if not claimable:
		if not repeatable and claimed:
			state_text = t("event.center.claimed")
			state_key = "claimed"
		else:
			state_text = t("event.center.locked")
			state_key = "locked"
	var cycle_label: String = ""
	if repeatable:
		var cycle: int = int(status.get("next_claimable_cycle", 0))
		if cycle > 0 and claimable:
			cycle_label = " · %s" % t("event.center.cycle", {"cycle": cycle})
		else:
			if cycle <= 0:
				cycle = int(status.get("completed_cycles", 0)) + 1
			cycle_label = " · %s" % t("event.center.next_cycle", {"cycle": cycle})
	var label: String = t(str(mission.get("key", "")))
	var count: int = int(status.get("count", 0))
	var target: int = maxi(1, int(status.get("target", 1)))
	return _make_card({
		"kind": "mission",
		"payload": {"event_id": event_id, "mission_id": mission_id},
		"badge": t("event.center.missions"),
		"title": "%s%s" % [label, cycle_label],
		"state": state_text,
		"state_key": state_key,
		"subtitle": t("event.center.runs", {"current": count, "target": target}),
		"meta": "%s%s · %d/%d · %s" % [label, cycle_label, count, target, state_text],
		"reward": "%s: %s" % [t("event.center.reward_summary"), _reward_text(_reward_dict(mission.get("reward", {})))],
		"progress_current": count,
		"progress_target": target,
		"progress_text": "%d/%d" % [count, target],
		"disabled": not claimable,
		"minimum_size": Vector2(300.0 if not _compact else 250.0, 134.0)
	}, func(payload: Dictionary) -> void: _claim_mission(
		str(payload.get("event_id", "")), str(payload.get("mission_id", ""))
	))


func _shop_card(event_id: String, item: Dictionary) -> EventCard:
	var item_id: String = str(item.get("id", ""))
	var currency_id: String = str(item.get("currency", ""))
	var cost: int = int(item.get("cost", 0))
	var amount: int = _service.currency_amount(currency_id)
	var claims_variant: Variant = PlayerState.data.get("reward_claims", {})
	var claims: Dictionary = claims_variant if claims_variant is Dictionary else {}
	var purchased: bool = claims.has("world|event|shop|%s|%s" % [event_id, item_id])
	var insufficient: bool = amount < cost
	var display_name: String = LocaleManager.token("event_shop", item_id, t("common.none"))
	var state_text: String = t("event.center.buy")
	var state_key: String = "available"
	if purchased:
		state_text = t("event.center.purchased")
		state_key = "purchased"
	elif insufficient:
		state_text = t("event.center.insufficient")
		state_key = "insufficient"
	return _make_card({
		"kind": "shop",
		"payload": {"event_id": event_id, "item_id": item_id},
		"badge": t("event.center.shop"),
		"title": display_name,
		"state": state_text,
		"state_key": state_key,
		"subtitle": "%d %s" % [cost, _display_name(currency_id)],
		"meta": "%s: %d" % [t("event.center.currency"), amount],
		"reward": "%s: %s" % [t("event.center.reward_summary"), _reward_text(_reward_dict(item.get("reward", {})))],
		"disabled": purchased or insufficient,
		"minimum_size": Vector2(300.0 if not _compact else 250.0, 112.0)
	}, func(payload: Dictionary) -> void: _purchase_item(
		str(payload.get("event_id", "")), str(payload.get("item_id", ""))
	))


func _reward_dict(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


func _reward_text(reward: Dictionary) -> String:
	var parts: Array[String] = []
	var gil: int = int(reward.get("gil", 0))
	if gil > 0:
		parts.append("%d %s" % [gil, t("resource.gil")])
	for item_variant: Variant in (reward.get("items", []) as Array):
		parts.append(_display_name(str(item_variant)))
	return ", ".join(parts) if not parts.is_empty() else t("common.none")


func _display_name(id: String) -> String:
	return LocaleManager.token("resource", id, t("common.none"))


func _schedule_text(config: Dictionary) -> String:
	var start_unix: int = int(config.get("start_unix", 0))
	var end_unix: int = int(config.get("end_unix", 0))
	if start_unix == 0 and end_unix == 0:
		return t("event.state.permanent")
	return t("event.center.schedule_range", {"start": start_unix, "end": end_unix})


func _currency_text(currency_id: String, amount: int) -> String:
	return "%s · %d" % [_display_name(currency_id), amount]


func _select_event(event_id: String) -> void:
	_selected_event_id = event_id
	_selected_stage_id = ""
	_result_message = ""
	_rebuild()


func _toggle_region() -> void:
	_region = "JP" if _region == "GL" else "GL"
	_selected_event_id = ""
	_selected_stage_id = ""
	_rebuild()


func _set_status_filter(value: String) -> void:
	_status_filter = value
	_rebuild()


func _set_category_filter(value: String) -> void:
	_category_filter = value
	_rebuild()


func _ensure_repository() -> void:
	if _repository == null:
		_repository = EventRepository.new()


func stage_context(event_id: String, stage_id: String) -> Dictionary:
	_ensure_repository()
	var stage: Dictionary = _repository.get_event_stage(stage_id)
	if stage.is_empty():
		return {}
	return {
		"event_id": event_id,
		"stage_id": stage_id,
		"region": _region,
		"encounter_id": str(stage.get("encounter_id", "")),
		"return_scene": EVENT_CENTER_PATH
	}


func banner_context(event_id: String) -> Dictionary:
	return {"event_id": event_id, "region": _region, "return_scene": EVENT_CENTER_PATH}


func _launch_stage(event_id: String, stage_id: String) -> void:
	var event: Dictionary = _repository.get_event(event_id)
	var stage: Dictionary = _repository.get_event_stage(stage_id)
	if event.is_empty() or stage.is_empty():
		_set_status(t("event.center.locked"))
		return
	var unlocked: bool = _service.is_event_unlocked(event_id, _region)
	if not _schedule.can_enter(event, _region, unlocked, _schedule.now()) \
			or not bool(_service.can_launch_stage(event_id, stage_id, _region).get("ok", false)):
		_set_status(t("event.center.locked"))
		return
	WorldContext.write(stage_context(event_id, stage_id))
	var error: Error = get_tree().change_scene_to_file(BATTLE_PATH)
	if error != OK:
		WorldContext.clear()
		_set_status(t("event.center.scene_error"))


func _open_banner(event_id: String) -> void:
	WorldContext.write(banner_context(event_id))
	var error: Error = get_tree().change_scene_to_file(SUMMON_PATH)
	if error != OK:
		WorldContext.clear()
		_set_status(t("event.center.scene_error"))


func _claim_mission(event_id: String, mission_id: String) -> void:
	var outcome: Dictionary = _service.claim_mission(event_id, mission_id)
	_set_status(_outcome_message(outcome))


func _purchase_item(event_id: String, item_id: String) -> void:
	var outcome: Dictionary = _service.purchase_shop_item(event_id, item_id)
	_set_status(_outcome_message(outcome))


func _outcome_message(outcome: Dictionary) -> String:
	if bool(outcome.get("ok", false)):
		return t("event.center.reward_summary")
	match str(outcome.get("reason", "")):
		"insufficient_currency":
			return t("event.center.no_currency")
		"already_claimed":
			return t("event.center.claimed")
		"save_failed":
			return t("event.center.result.save_failed")
		_:
			return t("event.center.locked")


func _set_status(message: String) -> void:
	_result_message = message
	if _status_label != null:
		_status_label.text = message
		_status_label.add_theme_color_override(
			"font_color", EventTheme.CYAN if not message.is_empty() else EventTheme.TEXT_MUTED
		)
