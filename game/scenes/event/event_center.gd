extends Control

## Prompt 07 Event Center. All displayed copy resolves through LocaleManager;
## all definitions are read-only synthetic fixtures. The scene adapts between
## landscape and portrait without changing gameplay or save behaviour.

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
var _building: bool = false
var _detail_box: VBoxContainer = null
var _list_box: VBoxContainer = null
var _status_label: Label = null
var _region_button: Button = null


func _ready() -> void:
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
			_selected_event_id = "event:GL:980001@stargarden"
			_qa_focus_key = "event.center.summon_nav"
		"archive":
			_selected_event_id = "event:GL:980004@archive"
			_status_filter = "archive"
		"replay":
			_selected_event_id = "event:GL:980004@archive"
			_status_filter = "archive"
			_qa_focus_key = "event.center.stages"
		"collaboration":
			_selected_event_id = "event:GL:980003@lumenguest"
			_category_filter = "collaboration"
		_:
			pass


func _on_resized() -> void:
	if _building or _portrait_override >= 0:
		return
	var size: Vector2 = get_viewport_rect().size
	var next_portrait: bool = size.y > size.x
	if next_portrait != _portrait:
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
	var size: Vector2 = get_viewport_rect().size
	_portrait = _portrait_override == 1 if _portrait_override >= 0 else size.y > size.x
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset: int = 12 if _portrait else 18
	margin.add_theme_constant_override("margin_left", inset)
	margin.add_theme_constant_override("margin_top", inset)
	margin.add_theme_constant_override("margin_right", inset)
	margin.add_theme_constant_override("margin_bottom", inset)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(layout)
	layout.add_child(_build_header())
	layout.add_child(_build_filters())
	var main: Node = _build_main()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(main)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0, 30 if _portrait else 22)
	_status_label.text = _result_message
	layout.add_child(_status_label)
	_building = false
	_apply_qa_focus()


## QA-only detail scroll positioning. It moves an existing rendered section into
## view; it does not synthesize a mock screen or alter gameplay state.
func _apply_qa_focus() -> void:
	if _qa_focus_key.is_empty():
		return
	var target_text: String = t(_qa_focus_key)
	var scroll: ScrollContainer = _find_first_scroll(self)
	var label: Label = _find_label_text(self, target_text)
	if scroll == null or label == null:
		return
	var delta: float = label.get_global_transform_with_canvas().origin.y \
		- scroll.get_global_transform_with_canvas().origin.y
	scroll.scroll_vertical = maxi(0, int(scroll.scroll_vertical + delta - 8))


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
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = t("event.center.title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22 if not _portrait else 19)
	header.add_child(title)
	_region_button = Button.new()
	_region_button.text = _region
	_region_button.custom_minimum_size = Vector2(72, 36)
	_region_button.pressed.connect(_toggle_region)
	header.add_child(_region_button)
	var back := Button.new()
	back.text = t("event.center.back")
	back.custom_minimum_size = Vector2(84 if _portrait else 110, 36)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MAIN_MENU_PATH))
	header.add_child(back)
	return header


func _build_filters() -> Node:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 5)
	var statuses := HBoxContainer.new()
	statuses.add_theme_constant_override("separation", 5)
	for item: Array in [
		["all", "event.center.filter.all"], ["active", "event.center.filter.active"],
		["upcoming", "event.center.filter.upcoming"], ["ended", "event.center.filter.ended"],
		["archive", "event.center.filter.archive"], ["collaboration", "event.center.filter.collaboration"]
	]:
		var button := Button.new()
		button.text = t(str(item[1]))
		button.toggle_mode = true
		button.button_pressed = _status_filter == str(item[0])
		button.pressed.connect(_set_status_filter.bind(str(item[0])))
		statuses.add_child(button)
	outer.add_child(statuses)
	var categories := HBoxContainer.new()
	categories.add_theme_constant_override("separation", 5)
	for item: Array in [
		["all", "event.center.category.all"], ["story", "event.center.category.story"],
		["limited", "event.center.category.limited"], ["permanent", "event.center.category.permanent"],
		["collaboration", "event.center.category.collaboration"], ["seasonal", "event.center.category.seasonal"],
		["challenge", "event.center.category.challenge"]
	]:
		var button := Button.new()
		button.text = t(str(item[1]))
		button.toggle_mode = true
		button.button_pressed = _category_filter == str(item[0])
		button.pressed.connect(_set_category_filter.bind(str(item[0])))
		categories.add_child(button)
	outer.add_child(categories)
	return outer


func _build_main() -> Node:
	var main: Node = VBoxContainer.new() if _portrait else HBoxContainer.new()
	(main as Container).add_theme_constant_override("separation", 10)
	var list_panel := PanelContainer.new()
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if _portrait else Control.SIZE_FILL
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if not _portrait:
		list_panel.custom_minimum_size = Vector2(310, 0)
	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_child(list_scroll)
	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 7)
	list_scroll.add_child(_list_box)
	main.add_child(list_panel)
	_populate_event_list()

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_child(detail_scroll)
	_detail_box = VBoxContainer.new()
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_box.add_theme_constant_override("separation", 7)
	detail_scroll.add_child(_detail_box)
	main.add_child(detail_panel)
	_populate_detail()
	return main


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
		var current_state: String = _schedule.state(event, _region, true, now_unix)
		if not _matches_status_filter(current_state, str(event.get("category", ""))):
			continue
		var card := Button.new()
		card.custom_minimum_size = Vector2(0, 72 if _portrait else 64)
		card.text = "%s\n%s · %s" % [
			t(str(event.get("name_key", ""))),
			t(_schedule.state_key(current_state)),
			t("event.center.category.%s" % str(event.get("category", "")))
		]
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.pressed.connect(_select_event.bind(str(event.get("id", ""))))
		if str(event.get("id", "")) == _selected_event_id:
			card.modulate = Color(0.72, 0.88, 1.0)
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
		var empty := Label.new()
		empty.text = t("event.center.detail.empty")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail_box.add_child(empty)
		return
	var now_unix: int = _schedule.now()
	var current_state: String = _schedule.state(event, _region, true, now_unix)
	_add_heading(t(str(event.get("name_key", ""))), 21)
	var art_variant: Variant = event.get("art", {})
	var art: Dictionary = art_variant if art_variant is Dictionary else {}
	_add_art_panel(str(art.get("label_key", "event.center.art.placeholder")))
	_add_line("%s: %s" % [t("event.center.status"), t(_schedule.state_key(current_state))])
	_add_line("%s: %s" % [t("event.center.region"), _region])
	var config: Dictionary = _repository.region_config(str(event.get("id", "")), _region)
	var start_unix: int = int(config.get("start_unix", 0))
	var end_unix: int = int(config.get("end_unix", 0))
	var schedule_text: String = t("event.state.permanent") if start_unix == 0 and end_unix == 0 else "%d – %d" % [start_unix, end_unix]
	_add_line("%s: %s" % [t("event.center.schedule"), schedule_text])
	var description := Label.new()
	description.text = t(str(event.get("description_key", "")))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_box.add_child(description)

	var currency_id: String = str(event.get("event_currency", ""))
	var amount: int = _service.currency_amount(currency_id)
	_add_heading(t("event.center.currency"), 16)
	_add_line("%s: %d" % [currency_id, amount])

	_add_heading(t("event.center.stages"), 17)
	var detail_stages: Array[Dictionary] = _repository.stages_for_event(str(event.get("id", "")))
	for stage: Dictionary in detail_stages:
		_add_stage_button(event, stage, current_state)
	_add_heading(t("event.center.rewards"), 17)
	for stage: Dictionary in detail_stages:
		_add_stage_rewards(stage)
	_add_heading(t("event.center.missions"), 17)
	for mission_variant: Variant in (event.get("missions", []) as Array):
		var mission: Dictionary = mission_variant
		_add_mission_button(str(event.get("id", "")), mission)
	_add_heading(t("event.center.shop"), 17)
	for item: Dictionary in _repository.shop_items(str(event.get("id", ""))):
		_add_shop_button(str(event.get("id", "")), item)
	var banner_ref: String = _repository.banner_ref(str(event.get("id", "")), _region)
	if not banner_ref.is_empty():
		var banner_button := Button.new()
		banner_button.text = "%s (%s)" % [t("event.center.summon_nav"), banner_ref]
		banner_button.pressed.connect(_open_banner.bind(str(event.get("id", ""))))
		_detail_box.add_child(banner_button)


func _add_heading(text: String, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	_detail_box.add_child(label)


func _add_line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_box.add_child(label)


func _add_art_panel(label_key: String) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 84 if _portrait else 72)
	var frame := ColorRect.new()
	frame.color = Color(0.12, 0.16, 0.30, 1.0)
	frame.custom_minimum_size = Vector2(0, 84 if _portrait else 72)
	var caption := Label.new()
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.text = "%s\n%s" % [t(label_key), t("event.center.art.placeholder")]
	caption.add_theme_font_size_override("font_size", 13)
	frame.add_child(caption)
	panel.add_child(frame)
	_detail_box.add_child(panel)


func _add_stage_button(event: Dictionary, stage: Dictionary, current_state: String) -> void:
	var event_id: String = str(event.get("id", ""))
	var stage_id: String = str(stage.get("id", ""))
	var progress: Dictionary = _service.get_stage_progress(event_id, stage_id)
	var state_suffix: String = t("event.center.stage_unlocked")
	if bool(progress.get("completed", false)):
		state_suffix = t("event.center.stage_completed")
	elif bool(progress.get("cleared", false)):
		state_suffix = t("event.center.stage_cleared")
	var button := Button.new()
	button.text = "%s · %s · %d/%d" % [
		t(str(stage.get("name_key", ""))), state_suffix,
		int(progress.get("runs", 0)), maxi(1, int(stage.get("completion_target", 1)))
	]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var unlocked: bool = _service.is_stage_unlocked(event_id, stage_id)
	var enterable: bool = _schedule.can_enter(event, _region, true, _schedule.now())
	button.disabled = not unlocked or not enterable or current_state == EventSchedule.STATE_ARCHIVED
	button.pressed.connect(_launch_stage.bind(event_id, stage_id))
	_detail_box.add_child(button)


func _add_stage_rewards(stage: Dictionary) -> void:
	var stage_name: String = t(str(stage.get("name_key", "")))
	var first_variant: Variant = stage.get("first_clear_reward", {})
	var repeat_variant: Variant = stage.get("repeat_reward", {})
	var first: Dictionary = first_variant if first_variant is Dictionary else {}
	var repeat: Dictionary = repeat_variant if repeat_variant is Dictionary else {}
	var first_ids: Array[String] = []
	var repeat_ids: Array[String] = []
	for item_variant: Variant in (first.get("items", []) as Array):
		first_ids.append(str(item_variant))
	for item_variant: Variant in (repeat.get("items", []) as Array):
		repeat_ids.append(str(item_variant))
	var first_items: String = ", ".join(first_ids) if not first_ids.is_empty() else t("common.none")
	var repeat_items: String = ", ".join(repeat_ids) if not repeat_ids.is_empty() else t("common.none")
	_add_line("%s · %s: %d · %s" % [
		stage_name, t("event.center.first_clear"), int(first.get("gil", 0)), first_items
	])
	_add_line("%s · %s: %d · %s" % [
		stage_name, t("event.center.repeat"), int(repeat.get("gil", 0)), repeat_items
	])


func _add_mission_button(event_id: String, mission: Dictionary) -> void:
	var mission_id: String = str(mission.get("id", ""))
	var status: Dictionary = _service.mission_status(event_id, mission_id)
	var button := Button.new()
	if bool(status.get("claimed", false)):
		button.text = "%s · %s" % [t(str(mission.get("key", ""))), t("event.center.claimed")]
		button.disabled = true
	else:
		button.text = "%s · %d/%d · %s" % [
			t(str(mission.get("key", ""))), int(status.get("count", 0)),
			int(status.get("target", 1)), t("event.center.claim")
		]
		button.disabled = not bool(status.get("complete", false))
		button.pressed.connect(_claim_mission.bind(event_id, mission_id))
	_detail_box.add_child(button)


func _add_shop_button(event_id: String, item: Dictionary) -> void:
	var button := Button.new()
	button.text = "%s · %d %s" % [
		str(item.get("id", "")), int(item.get("cost", 0)), str(item.get("currency", ""))
	]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(_purchase_item.bind(event_id, str(item.get("id", ""))))
	_detail_box.add_child(button)


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
	if not _schedule.can_enter(event, _region, true, _schedule.now()) \
			or not _service.is_stage_unlocked(event_id, stage_id):
		_set_status(t("event.center.locked"))
		return
	WorldContext.write(stage_context(event_id, stage_id))
	var error: Error = get_tree().change_scene_to_file(BATTLE_PATH)
	if error != OK:
		WorldContext.clear()
		_set_status(str(error))


func _open_banner(event_id: String) -> void:
	WorldContext.write(banner_context(event_id))
	var error: Error = get_tree().change_scene_to_file(SUMMON_PATH)
	if error != OK:
		WorldContext.clear()
		_set_status(str(error))


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
