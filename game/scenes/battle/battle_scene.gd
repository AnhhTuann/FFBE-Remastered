extends Control

## Playable offline battle screen. All simulation is owned by BattleManager; this
## scene only collects commands, renders explicit events and drives the visual clock.
## Mouse and keyboard are supported. Controller input is intentionally NOT supported.

const BATTLE_MANAGER_SCRIPT := "res://battle/battle_manager.gd"
const BATTLE_SPRITE_SCRIPT := "res://battle/battle_sprite.gd"
const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"
const DEFAULT_ENCOUNTER := "encounter:GL:950001@skirmish"
const SPEEDS: Array[int] = [1, 2, 4]
## Layout budgets are deliberately small enough to fit the 1280x720 baseline
## with the eight-combatant boss encounter and the longest localized labels.
const CARD_WIDTH := 130
const CARD_HEIGHT := 168
const CARD_SPRITE_HEIGHT := 64
const CARD_SPRITE_TOP_INSET := 0
const ROW_SEPARATION := 3
const ROLE_COLORS := {
	"physical_attacker": Color(0.95, 0.72, 0.45),
	"magical_attacker": Color(0.62, 0.72, 1.0),
	"healer": Color(0.62, 1.0, 0.74),
	"support": Color(1.0, 0.88, 0.55),
	"defensive": Color(0.72, 0.84, 1.0),
	"boss": Color(1.0, 0.45, 0.48),
	"magical_enemy": Color(0.86, 0.58, 1.0),
	"physical_enemy": Color(1.0, 0.66, 0.52)
}

var manager: RefCounted = null
var _speed_index: int = 0
var _paused: bool = false
var _executing: bool = false
var _selected_index: int = 0
var _pending_target: Dictionary = {}
var _command_mode: String = ""
var _party_cards: Array[Dictionary] = []
var _enemy_cards: Array[Dictionary] = []
var _background: ColorRect
var _top_bar: HBoxContainer
var _main_layout: VBoxContainer
var _field: PanelContainer
var _field_row: HBoxContainer
var _debug_row: HBoxContainer
var _debug_label: Label
var _speed_button: Button
var _encounter_option: OptionButton
var _encounter_ids: Array[String] = []
var _turn_label: Label
var _phase_label: Label
var _chain_label: Label
var _center_label: Label
var _enemy_area: HBoxContainer
var _party_area: HBoxContainer
var _character_row: HBoxContainer
var _character_buttons: Array[Button] = []
var _command_row: HBoxContainer
var _attack_button: Button
var _ability_button: Button
var _limit_button: Button
var _item_button: Button
var _guard_button: Button
var _execute_button: Button
var _clear_button: Button
var _ability_scroll: ScrollContainer
var _ability_grid: GridContainer
var _hint_label: Label
var _log_label: Label
var _damage_layer: Control
var _result_overlay: PanelContainer
var _result_title: Label
var _result_body: Label
var _pause_overlay: PanelContainer
var _tick_timer: Timer
var _qa_freeze_frame: int = -1
var _result_recorded: bool = false
var _reward_status_key: String = "battle.reward_unavailable"
var _result_snapshot: Dictionary = {}
var _title_label: Label
var _pause_button: Button
var _menu_button: Button
var _party_source_key: String = ""
var _run_id: String = ""
var _seed_source: String = "independent"
var _battle_blocked: bool = false
var _world_context: Dictionary = {}
var _return_scene_path: String = MAIN_MENU_PATH
var _encounter_override: String = ""

## Run ids are presentation-scoped: retrying the same encounter always creates
## a new settlement identity even inside one process.
static var _scene_run_counter: int = 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	if not LocaleManager.locale_changed.is_connected(_apply_locale):
		LocaleManager.locale_changed.connect(_apply_locale)
	_world_context = WorldContext.consume()
	_encounter_override = str(_world_context.get("encounter_id", ""))
	_return_scene_path = str(_world_context.get("return_scene", MAIN_MENU_PATH))
	if _return_scene_path.is_empty():
		_return_scene_path = MAIN_MENU_PATH
	_qa_read_freeze_frame()
	_start_battle(_preferred_encounter())
	if _qa_mode():
		var scenario: String = OS.get_environment("FFBE_QA_SCENARIO")
		if not scenario.is_empty():
			_qa_apply_scenario(scenario)


func _exit_tree() -> void:
	if _tick_timer != null and is_instance_valid(_tick_timer):
		_tick_timer.stop()
	if LocaleManager.locale_changed.is_connected(_apply_locale):
		LocaleManager.locale_changed.disconnect(_apply_locale)


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_background = ColorRect.new()
	_background.color = Color(0.055, 0.075, 0.12)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	# One full-rect VBox owns all primary bands. The battlefield expands; the
	# command panel sizes to its content, so opening the ability grid cannot
	# push the hint/log/debug rows below the viewport.
	_main_layout = VBoxContainer.new()
	_main_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_layout.offset_left = 18.0
	_main_layout.offset_top = 8.0
	_main_layout.offset_right = -18.0
	_main_layout.offset_bottom = -10.0
	_main_layout.add_theme_constant_override("separation", 8)
	add_child(_main_layout)

	_top_bar = HBoxContainer.new()
	_top_bar.custom_minimum_size = Vector2(0, 40)
	_top_bar.add_theme_constant_override("separation", 10)
	_main_layout.add_child(_top_bar)

	_title_label = _label(LocaleManager.t("battle.scene_title"), 18, HORIZONTAL_ALIGNMENT_LEFT)
	_title_label.custom_minimum_size = Vector2(200, 0)
	_title_label.modulate = Color(0.95, 0.96, 1.0)
	_top_bar.add_child(_title_label)
	_turn_label = _label(LocaleManager.t("battle.turn", {"turn": 1}), 16, HORIZONTAL_ALIGNMENT_LEFT)
	_turn_label.custom_minimum_size = Vector2(60, 0)
	_top_bar.add_child(_turn_label)
	_phase_label = _label(LocaleManager.t("battle.player_phase"), 16, HORIZONTAL_ALIGNMENT_LEFT)
	_phase_label.custom_minimum_size = Vector2(100, 0)
	_top_bar.add_child(_phase_label)
	_chain_label = _label(LocaleManager.t("battle.chain_status", {"count": 0, "bonus": 0}), 16, HORIZONTAL_ALIGNMENT_LEFT)
	_chain_label.custom_minimum_size = Vector2(110, 0)
	_chain_label.modulate = Color(1.0, 0.84, 0.42)
	_top_bar.add_child(_chain_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_bar.add_child(spacer)
	_speed_button = _button(LocaleManager.t("battle.speed_button", {"speed": SPEEDS[0]}), 90)
	_speed_button.pressed.connect(_on_speed_pressed)
	_top_bar.add_child(_speed_button)
	_pause_button = _button(LocaleManager.t("battle.pause"), 80)
	_pause_button.pressed.connect(_on_pause_pressed)
	_top_bar.add_child(_pause_button)
	_menu_button = _button(LocaleManager.t("battle.menu"), 90)
	_menu_button.pressed.connect(_on_menu_pressed)
	_top_bar.add_child(_menu_button)

	_field = PanelContainer.new()
	_field.custom_minimum_size = Vector2(0, 220)
	_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var field_style := StyleBoxFlat.new()
	field_style.bg_color = Color(0.10, 0.14, 0.20, 0.94)
	field_style.border_color = Color(0.32, 0.44, 0.58)
	field_style.set_border_width_all(2)
	field_style.set_corner_radius_all(8)
	_field.add_theme_stylebox_override("panel", field_style)
	_main_layout.add_child(_field)

	var field_margin := MarginContainer.new()
	field_margin.add_theme_constant_override("margin_left", 12)
	field_margin.add_theme_constant_override("margin_right", 12)
	field_margin.add_theme_constant_override("margin_top", 12)
	field_margin.add_theme_constant_override("margin_bottom", 12)
	_field.add_child(field_margin)

	_field_row = HBoxContainer.new()
	_field_row.add_theme_constant_override("separation", 6)
	field_margin.add_child(_field_row)

	_enemy_area = HBoxContainer.new()
	_enemy_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_area.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_area.add_theme_constant_override("separation", 6)
	_field_row.add_child(_enemy_area)

	var center_slot := CenterContainer.new()
	center_slot.custom_minimum_size = Vector2(72, 0)
	_field_row.add_child(center_slot)
	_center_label = _label(LocaleManager.t("battle.vs"), 26, HORIZONTAL_ALIGNMENT_CENTER)
	_center_label.modulate = Color(0.78, 0.86, 1.0)
	center_slot.add_child(_center_label)

	_party_area = HBoxContainer.new()
	_party_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_party_area.alignment = BoxContainer.ALIGNMENT_CENTER
	_party_area.add_theme_constant_override("separation", 6)
	_field_row.add_child(_party_area)

	var command_panel := PanelContainer.new()
	command_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	var command_style := StyleBoxFlat.new()
	command_style.bg_color = Color(0.09, 0.12, 0.18, 0.97)
	command_style.border_color = Color(0.30, 0.42, 0.56)
	command_style.set_border_width_all(2)
	command_style.set_corner_radius_all(8)
	command_panel.add_theme_stylebox_override("panel", command_style)
	_main_layout.add_child(command_panel)

	var command_margin := MarginContainer.new()
	command_margin.add_theme_constant_override("margin_left", 12)
	command_margin.add_theme_constant_override("margin_right", 12)
	command_margin.add_theme_constant_override("margin_top", 8)
	command_margin.add_theme_constant_override("margin_bottom", 8)
	command_panel.add_child(command_margin)
	var command_vbox := VBoxContainer.new()
	command_vbox.add_theme_constant_override("separation", 6)
	command_margin.add_child(command_vbox)

	_character_row = HBoxContainer.new()
	_character_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_character_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_character_row.add_theme_constant_override("separation", 5)
	command_vbox.add_child(_character_row)

	_command_row = HBoxContainer.new()
	_command_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_command_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_command_row.add_theme_constant_override("separation", 5)
	command_vbox.add_child(_command_row)
	_attack_button = _button(LocaleManager.t("battle.command_attack"), 96)
	_attack_button.pressed.connect(_on_attack_pressed)
	_command_row.add_child(_attack_button)
	_ability_button = _button(LocaleManager.t("battle.command_abilities"), 110)
	_ability_button.pressed.connect(_on_abilities_pressed)
	_command_row.add_child(_ability_button)
	_limit_button = _button(LocaleManager.t("battle.command_limit"), 125)
	_limit_button.pressed.connect(_on_limit_pressed)
	_command_row.add_child(_limit_button)
	_item_button = _button(LocaleManager.t("battle.command_items"), 90)
	_item_button.pressed.connect(_on_items_pressed)
	_command_row.add_child(_item_button)
	_guard_button = _button(LocaleManager.t("battle.command_guard"), 90)
	_guard_button.pressed.connect(_on_guard_pressed)
	_command_row.add_child(_guard_button)
	_execute_button = _button(LocaleManager.t("battle.command_execute"), 130)
	_execute_button.pressed.connect(_on_execute_pressed)
	_command_row.add_child(_execute_button)
	_clear_button = _button(LocaleManager.t("battle.clear"), 70)
	_clear_button.pressed.connect(_on_clear_pressed)
	_command_row.add_child(_clear_button)

	_ability_scroll = ScrollContainer.new()
	_ability_scroll.custom_minimum_size = Vector2(0, 82)
	_ability_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ability_scroll.visible = false
	command_vbox.add_child(_ability_scroll)
	_ability_grid = GridContainer.new()
	_ability_grid.columns = 5
	_ability_scroll.add_child(_ability_grid)

	_hint_label = _label(LocaleManager.t("battle.hint_initial"), 14, HORIZONTAL_ALIGNMENT_LEFT)
	_hint_label.custom_minimum_size = Vector2(0, 20)
	_hint_label.modulate = Color(0.82, 0.88, 0.98)
	command_vbox.add_child(_hint_label)
	_log_label = _label("", 12, HORIZONTAL_ALIGNMENT_LEFT)
	_log_label.custom_minimum_size = Vector2(0, 18)
	_log_label.modulate = Color(0.68, 0.78, 0.90)
	command_vbox.add_child(_log_label)

	# QA/debug controls live in their own visually separated footer. The top
	# bar and battlefield stay player-facing; the encounter selector is no
	# longer mixed with turn/phase/chain information.
	command_vbox.add_child(HSeparator.new())
	_debug_row = HBoxContainer.new()
	_debug_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_debug_row.add_theme_constant_override("separation", 8)
	_debug_label = _label(LocaleManager.t("settings.debug"), 11, HORIZONTAL_ALIGNMENT_LEFT)
	_debug_label.custom_minimum_size = Vector2(72, 0)
	_debug_label.modulate = Color(0.50, 0.58, 0.70)
	_debug_row.add_child(_debug_label)
	_encounter_option = OptionButton.new()
	_encounter_option.custom_minimum_size = Vector2(220, 28)
	_encounter_option.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_encounter_option.clip_text = true
	_encounter_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_encounter_option.item_selected.connect(_on_encounter_selected)
	_debug_row.add_child(_encounter_option)
	var debug_spacer := Control.new()
	debug_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_debug_row.add_child(debug_spacer)
	command_vbox.add_child(_debug_row)

	_damage_layer = Control.new()
	_damage_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_damage_layer)

	_result_overlay = _make_overlay(LocaleManager.t("battle.result"))
	_result_title = _result_overlay.find_child("TitleLabel", true, false) as Label
	_result_body = _result_overlay.find_child("BodyLabel", true, false) as Label
	var result_retry := _result_overlay.find_child("PrimaryButton", true, false) as Button
	var result_menu := _result_overlay.find_child("SecondaryButton", true, false) as Button
	result_retry.text = LocaleManager.t("battle.retry")
	result_menu.text = LocaleManager.t("battle.return_menu")
	result_retry.pressed.connect(_on_retry_pressed)
	result_menu.pressed.connect(_on_menu_pressed)
	_result_overlay.visible = false
	add_child(_result_overlay)

	_pause_overlay = _make_overlay(LocaleManager.t("battle.paused"))
	var pause_title := _pause_overlay.find_child("TitleLabel", true, false) as Label
	pause_title.text = LocaleManager.t("battle.paused")
	var pause_body := _pause_overlay.find_child("BodyLabel", true, false) as Label
	pause_body.text = LocaleManager.t("battle.pause_detail")
	var resume_button := _pause_overlay.find_child("PrimaryButton", true, false) as Button
	var pause_menu_button := _pause_overlay.find_child("SecondaryButton", true, false) as Button
	resume_button.text = LocaleManager.t("battle.resume")
	pause_menu_button.text = LocaleManager.t("battle.return_menu")
	resume_button.pressed.connect(_on_pause_pressed)
	pause_menu_button.pressed.connect(_on_menu_pressed)
	_pause_overlay.visible = false
	add_child(_pause_overlay)

	_tick_timer = Timer.new()
	_tick_timer.wait_time = 0.05
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)


func _make_overlay(title_text: String) -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_preset(Control.PRESET_CENTER)
	overlay.offset_left = -260.0
	overlay.offset_top = -130.0
	overlay.offset_right = 260.0
	overlay.offset_bottom = 130.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.16, 0.98)
	style.border_color = Color(0.48, 0.66, 0.88)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	overlay.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	overlay.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var title := _label(title_text, 28, HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "TitleLabel"
	vbox.add_child(title)
	var body := _label("", 16, HORIZONTAL_ALIGNMENT_CENTER)
	body.name = "BodyLabel"
	vbox.add_child(body)
	var buttons := CenterContainer.new()
	vbox.add_child(buttons)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	buttons.add_child(hbox)
	var primary := _button("", 170)
	primary.name = "PrimaryButton"
	hbox.add_child(primary)
	var secondary := _button("", 190)
	secondary.name = "SecondaryButton"
	hbox.add_child(secondary)
	return overlay


func _label(text: String, size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = alignment
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Long localized strings must not inflate a Container's minimum width.
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	return label


func _button(text: String, minimum_width: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(minimum_width, 32)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.clip_text = true
	return button


func _bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.max_value = 1.0
	bar.value = 1.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(0.12, 0.14, 0.18)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background_style)
	return bar


func _build_encounter_options() -> void:
	_encounter_ids.clear()
	var call_result: Variant = ContentRepository.call("get_encounter_ids")
	if call_result is Array:
		for id_variant: Variant in call_result:
			_encounter_ids.append(str(id_variant))
	_encounter_ids.sort_custom(func(a: String, b: String) -> bool:
		var a_boss: bool = bool(ContentRepository.call("get_encounter", a).get("boss", false))
		var b_boss: bool = bool(ContentRepository.call("get_encounter", b).get("boss", false))
		return not a_boss and b_boss
	)
	_encounter_option.clear()
	for encounter_id: String in _encounter_ids:
		var encounter: Dictionary = ContentRepository.call("get_encounter", encounter_id)
		_encounter_option.add_item(str(encounter.get("name", encounter_id)))
	var preferred: int = maxi(_encounter_ids.find(_preferred_encounter()), 0)
	_encounter_option.select(preferred)


func _qa_mode() -> bool:
	return OS.get_environment("FFBE_QA_MODE").strip_edges() == "1"


func _preferred_encounter() -> String:
	if not _encounter_override.is_empty() and ContentRepository.call(
		"get_encounter", _encounter_override
	).size() > 0:
		return _encounter_override
	if _qa_mode():
		var requested: String = OS.get_environment("FFBE_QA_ENCOUNTER")
		if not requested.is_empty() and ContentRepository.call("get_encounter", requested).size() > 0:
			return requested
	return DEFAULT_ENCOUNTER


func _new_run_id() -> String:
	_scene_run_counter += 1
	# Godot 4.7 has no OS.get_unix_time_us(); the monotonic microsecond clock is
	# sufficient to make retry/run identities unique inside one process.
	return "run:scene:%d:%d:%d" % [
		Time.get_ticks_usec(), _scene_run_counter, absi(randi() % 1000000007)
	]


func _block_battle_start(reason_key: String) -> void:
	_battle_blocked = true
	_party_source_key = reason_key
	manager = null
	if _hint_label != null:
		_hint_label.text = LocaleManager.t(reason_key)
	if _debug_label != null:
		_debug_label.text = LocaleManager.t(reason_key)
	for button: Button in [
		_attack_button, _ability_button, _limit_button, _item_button,
		_guard_button, _execute_button, _clear_button
	]:
		if button != null:
			button.disabled = true


# ---------------------------------------------------------------------------
# Battle lifecycle
# ---------------------------------------------------------------------------

func _start_battle(encounter_id: String) -> void:
	if _tick_timer != null:
		_tick_timer.stop()
	var script: Script = load(BATTLE_MANAGER_SCRIPT) as Script
	if script == null:
		push_error("FAIL battle manager script missing")
		return
	var encounter: Dictionary = (ContentRepository.call("get_encounter", encounter_id) as Dictionary).duplicate(true)
	if encounter.is_empty():
		encounter = (ContentRepository.call("get_encounter", DEFAULT_ENCOUNTER) as Dictionary).duplicate(true)

	var combatants: Dictionary = {}
	var package: Dictionary = ContentRepository.call("get_battle_package")
	var combatants_variant: Variant = package.get("combatants", {})
	if combatants_variant is Dictionary:
		combatants = (combatants_variant as Dictionary).duplicate(true)

	# The active PlayerState party replaces the fixture party only when the full
	# build resolver accepts it. Outside QA mode an invalid party blocks battle;
	# QA mode may use the labelled fixture fallback for deterministic captures.
	_battle_blocked = false
	_party_source_key = ""
	var party_id: String = _active_party_id()
	var resolved_party: Dictionary = {}
	var party_valid: bool = false
	var player_state: Node = get_node_or_null("/root/PlayerState")
	if player_state != null and player_state.build_resolver != null \
			and player_state.build_resolver.has_method("resolve_party") \
			and not party_id.is_empty():
		var validation: Dictionary = player_state.build_resolver.call("resolve_party", party_id)
		party_valid = bool(validation.get("ok", false)) and bool(validation.get("valid", false))
		if party_valid:
			resolved_party = _party_combatants(party_id)
			party_valid = resolved_party.size() == 5
	if party_valid:
		encounter["party"] = resolved_party.keys()
		for instance_id: String in resolved_party.keys():
			combatants[instance_id] = resolved_party[instance_id]
	elif _qa_mode():
		_party_source_key = "battle.party_fallback_labeled"
	else:
		_block_battle_start("battle.party_invalid")
		return
	var abilities: Dictionary = {}
	var abilities_variant: Variant = package.get("abilities", {})
	if abilities_variant is Dictionary:
		abilities = abilities_variant
	var items: Dictionary = {}
	var items_variant: Variant = package.get("items", {})
	if items_variant is Dictionary:
		items = items_variant

	_seed_source = "independent"
	var seed_value: int = (Time.get_ticks_usec() ^ (randi() * 2654435761)) & 0x7FFFFFFFFFFFFFFF
	var seed_text: String = ""
	if _qa_mode():
		seed_text = OS.get_environment("FFBE_QA_SEED")
	if not seed_text.is_empty() and seed_text.is_valid_int():
		seed_value = seed_text.to_int()
		_seed_source = "qa_deterministic"
	_run_id = _new_run_id()

	manager = script.new(encounter, combatants, abilities, items, seed_value, _seed_source, _run_id)
	manager.connect("event_emitted", _on_battle_event)
	manager.call("start_battle")
	_build_encounter_options()
	_executing = false
	_paused = false
	_pending_target = {}
	_command_mode = ""
	_selected_index = 0
	_result_recorded = false
	_reward_status_key = "battle.reward_unavailable"
	_result_snapshot = {}
	_result_overlay.visible = false
	_pause_overlay.visible = false
	_ability_scroll.visible = false
	if _build_encounter_option_index(encounter_id) >= 0:
		_encounter_option.select(_build_encounter_option_index(encounter_id))
	_rebuild_cards()
	_refresh()


func _build_encounter_option_index(encounter_id: String) -> int:
	for index: int in range(_encounter_ids.size()):
		if _encounter_ids[index] == encounter_id:
			return index
	return -1


func _rebuild_cards() -> void:
	for child: Node in _enemy_area.get_children():
		child.queue_free()
	for child: Node in _party_area.get_children():
		child.queue_free()
	_enemy_cards.clear()
	_party_cards.clear()
	for combatant in manager.get("state").get("enemies"):
		_enemy_cards.append(_make_card(combatant, false))

	# The reserved companion slot was empty in every verified encounter. It
	# consumed battlefield width and pushed the party row past the viewport,
	# so actual combatants are the only cards laid out here.
	for combatant in manager.get("state").get("party"):
		_party_cards.append(_make_card(combatant, true))


func _make_card(combatant: RefCounted, is_party: bool) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.19, 0.27)
	style.border_color = Color(0.36, 0.48, 0.62)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 28)
	button.flat = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 12)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.clip_text = true
	button.text = str(combatant.get("display_name"))
	button.tooltip_text = _card_button_tooltip(combatant)
	button.pressed.connect(_on_card_pressed.bind(combatant.get("id")))
	vbox.add_child(button)

	var sprite_host := Control.new()
	sprite_host.custom_minimum_size = Vector2(0, CARD_SPRITE_HEIGHT)
	sprite_host.clip_contents = true
	vbox.add_child(sprite_host)
	var sprite_script: Script = load(BATTLE_SPRITE_SCRIPT) as Script
	if sprite_script != null:
		var sprite: AnimatedSprite2D = sprite_script.new() as AnimatedSprite2D
		var role_color: Color = ROLE_COLORS.get(str(combatant.get("role")), Color(0.8, 0.85, 0.95))
		sprite.setup(str(combatant.get("animation_id")), role_color)
		_fit_sprite_to_host(sprite, float(CARD_WIDTH))
		# BattleSprite reapplies frame origins on every frame; recentre after it
		# so the sprite never drifts over the name button or the stat bars.
		sprite.frame_changed.connect(_center_sprite.bind(sprite, float(CARD_WIDTH)))
		sprite_host.add_child(sprite)

	var hp_bar := _bar(Color(0.35, 0.85, 0.48))
	vbox.add_child(hp_bar)
	var hp_text := _label("", 11, HORIZONTAL_ALIGNMENT_CENTER)
	vbox.add_child(hp_text)
	var mp_bar := _bar(Color(0.40, 0.62, 1.0))
	vbox.add_child(mp_bar)
	var lb_bar := _bar(Color(1.0, 0.78, 0.28))
	vbox.add_child(lb_bar)
	var status_label := _label("", 10, HORIZONTAL_ALIGNMENT_CENTER)
	status_label.clip_text = true
	vbox.add_child(status_label)

	var host: HBoxContainer = _party_area if is_party else _enemy_area
	host.add_child(panel)
	return {
		"panel": panel,
		"button": button,
		"hp_bar": hp_bar,
		"hp_text": hp_text,
		"mp_bar": mp_bar,
		"lb_bar": lb_bar,
		"status": status_label,
		"combatant": combatant,
		"style": style
	}


func _fit_sprite_to_host(sprite: AnimatedSprite2D, host_width: float) -> void:
	if sprite.sprite_frames == null:
		return
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null or texture.get_size().x <= 0.0 or texture.get_size().y <= 0.0:
		return
	var scaled: Vector2 = texture.get_size() * sprite.scale
	var longest: float = maxf(scaled.x, scaled.y)
	if longest > CARD_SPRITE_HEIGHT:
		sprite.scale *= CARD_SPRITE_HEIGHT / longest
	_center_sprite(sprite, host_width)


func _center_sprite(sprite: AnimatedSprite2D, host_width: float) -> void:
	if not is_instance_valid(sprite) or sprite.sprite_frames == null:
		return
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return
	var scaled: Vector2 = texture.get_size() * sprite.scale
	var desired: Vector2 = Vector2(
		(host_width - scaled.x) * 0.5,
		(CARD_SPRITE_HEIGHT - scaled.y) * 0.5 + CARD_SPRITE_TOP_INSET
	)
	var top_left_from_position: Vector2 = sprite.offset * sprite.scale
	if sprite.centered:
		top_left_from_position -= scaled * 0.5
	sprite.position = desired - top_left_from_position


func _card_button_tooltip(combatant: RefCounted) -> String:
	var details: String = _card_tooltip(combatant)
	var name: String = str(combatant.get("display_name"))
	if details.is_empty():
		return name
	return name + "\n" + details


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

func _refresh() -> void:
	if manager == null:
		return
	var state: RefCounted = manager.get("state")
	_turn_label.text = LocaleManager.t("battle.turn", {"turn": int(state.get("turn"))})
	_phase_label.text = _phase_text(str(state.get("phase")))
	_chain_label.text = LocaleManager.t("battle.chain_status", {
		"count": int(state.get("chain_count")),
		"bonus": int(state.get("chain_modifier"))
	})
	_center_label.text = LocaleManager.t("battle.center_chain", {"count": int(state.get("chain_count"))}) if int(state.get("chain_count")) > 0 else LocaleManager.t("battle.vs")

	for index: int in range(_enemy_cards.size()):
		var card: Dictionary = _enemy_cards[index]
		if card.get("combatant") == null:
			continue
		_update_card(card, false, index)
	for index: int in range(_party_cards.size()):
		_update_card(_party_cards[index], true, index)

	while _character_row.get_child_count() < _party_cards.size():
		var index: int = _character_row.get_child_count()
		var button := _button("", 150)
		button.custom_minimum_size = Vector2(150, 54)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.add_theme_font_size_override("font_size", 12)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_character_pressed.bind(index))
		_character_row.add_child(button)
		_character_buttons.append(button)
	for index: int in range(_character_buttons.size()):
		var button: Button = _character_buttons[index]
		if index >= _party_cards.size():
			button.visible = false
			continue
		var combatant: RefCounted = _party_cards[index].get("combatant")
		button.visible = true
		button.text = LocaleManager.t("battle.character_card", {
			"slot": index + 1,
			"name": str(combatant.get("display_name")),
			"hp": int(combatant.get("hp")),
			"max_hp": int(combatant.get("max_hp")),
			"mp": int(combatant.get("mp")),
			"lb": int(combatant.get("lb_gauge")),
			"lb_cost": int(combatant.get("lb_cost")),
			"queued": "  " + LocaleManager.t("battle.queued") if _has_queued(str(combatant.get("id"))) else ""
		})
		button.disabled = not bool(combatant.call("is_alive")) or _executing or str(state.get("phase")) != "player"
		button.modulate = Color(1.0, 0.88, 0.55) if index == _selected_index else Color(1, 1, 1)

	var input_allowed: bool = str(state.get("phase")) == "player" and not _executing and state.get("result") == null
	_selected_index = clampi(_selected_index, 0, maxi(_party_cards.size() - 1, 0))
	var selected_party: RefCounted = _party_cards[_selected_index].get("combatant") if not _party_cards.is_empty() else null
	var alive: bool = selected_party != null and bool(selected_party.call("is_alive"))
	_attack_button.disabled = not input_allowed or not alive
	_ability_button.disabled = not input_allowed or not alive
	_limit_button.disabled = not input_allowed or not alive or not bool(selected_party.call("lb_ready"))
	_item_button.disabled = not input_allowed or not alive
	_guard_button.disabled = not input_allowed or not alive
	_execute_button.disabled = not input_allowed
	_clear_button.disabled = not input_allowed or int(manager.call("summary").get("queue_size", 0)) == 0

	var log_lines: Array[String] = state.get("log")
	var display_lines: Array[String] = []
	for line: String in log_lines:
		display_lines.append(line)
	if display_lines.size() > 3:
		display_lines = display_lines.slice(display_lines.size() - 3)
	_log_label.text = " | ".join(display_lines)
	_hint_label.text = _hint_text()


func _apply_locale(_locale: String = "") -> void:
	if _debug_label != null:
		_debug_label.text = LocaleManager.t("settings.debug")
	if _title_label != null:
		_title_label.text = LocaleManager.t("battle.scene_title")
	if _speed_button != null:
		_speed_button.text = LocaleManager.t("battle.speed_button", {"speed": SPEEDS[_speed_index]})
	if _pause_button != null:
		_pause_button.text = LocaleManager.t("battle.pause")
	if _menu_button != null:
		_menu_button.text = LocaleManager.t("battle.menu")
	_attack_button.text = LocaleManager.t("battle.command_attack")
	_ability_button.text = LocaleManager.t("battle.command_abilities")
	_limit_button.text = LocaleManager.t("battle.command_limit")
	_item_button.text = LocaleManager.t("battle.command_items")
	_guard_button.text = LocaleManager.t("battle.command_guard")
	_execute_button.text = LocaleManager.t("battle.command_execute")
	_clear_button.text = LocaleManager.t("battle.clear")

	for card: Dictionary in _enemy_cards + _party_cards:
		var combatant: RefCounted = card.get("combatant")
		var button: Button = card.get("button") as Button
		if combatant != null and button != null:
			button.tooltip_text = _card_button_tooltip(combatant)
		elif button == null:
			var panel: PanelContainer = card.get("panel") as PanelContainer
			var companion_label: Label = null
			if panel != null:
				companion_label = panel.find_child("Label", true, false) as Label
			if companion_label != null:
				companion_label.text = LocaleManager.t("battle.companion")

	var result_title: Label = _result_overlay.find_child("TitleLabel", true, false) as Label
	var result_retry: Button = _result_overlay.find_child("PrimaryButton", true, false) as Button
	var result_menu: Button = _result_overlay.find_child("SecondaryButton", true, false) as Button
	if not _result_overlay.visible and result_title != null:
		result_title.text = LocaleManager.t("battle.result")
	if result_retry != null:
		result_retry.text = LocaleManager.t("battle.retry")
	if result_menu != null:
		result_menu.text = LocaleManager.t("battle.return_menu")
	var pause_title: Label = _pause_overlay.find_child("TitleLabel", true, false) as Label
	var pause_body: Label = _pause_overlay.find_child("BodyLabel", true, false) as Label
	var resume_button: Button = _pause_overlay.find_child("PrimaryButton", true, false) as Button
	var pause_menu_button: Button = _pause_overlay.find_child("SecondaryButton", true, false) as Button
	if pause_title != null:
		pause_title.text = LocaleManager.t("battle.paused")
	if pause_body != null:
		pause_body.text = LocaleManager.t("battle.pause_detail")
	if resume_button != null:
		resume_button.text = LocaleManager.t("battle.resume")
	if pause_menu_button != null:
		pause_menu_button.text = LocaleManager.t("battle.return_menu")

	if _ability_scroll.visible:
		if _command_mode == "abilities":
			_populate_ability_grid()
		elif _command_mode == "items":
			_populate_item_grid()
	_refresh()
	if _result_overlay.visible:
		_render_result()
	if manager != null:
		var current_id: String = str(manager.get("state").get("encounter_id"))
		_build_encounter_options()
		var selected: int = _build_encounter_option_index(current_id)
		if selected >= 0:
			_encounter_option.select(selected)


func _update_card(card: Dictionary, is_party: bool, index: int) -> void:
	var combatant: RefCounted = card.get("combatant")
	var max_hp: int = maxi(int(combatant.get("max_hp")), 1)
	var hp: int = int(combatant.get("hp"))
	var max_mp: int = maxi(int(combatant.get("max_mp")), 1)
	var mp: int = int(combatant.get("mp"))
	card.get("hp_bar").value = float(hp) / float(max_hp)
	card.get("mp_bar").value = float(mp) / float(max_mp)
	card.get("hp_text").text = LocaleManager.t("battle.hp", {"hp": hp, "max_hp": max_hp})
	if is_party:
		var cost: int = maxi(int(combatant.get("lb_cost")), 1)
		card.get("lb_bar").value = float(int(combatant.get("lb_gauge"))) / float(cost)
		var statuses: Dictionary = combatant.get("statuses")
		card.get("status").text = ", ".join(_status_names(statuses))
	else:
		card.get("lb_bar").visible = false
		card.get("mp_bar").visible = false
		card.get("status").text = ""
	var button: Button = card.get("button")
	if button != null:
		button.disabled = hp <= 0
		var valid: Array = _pending_target.get("valid", [])
		if not valid.is_empty():
			button.modulate = Color(1.0, 0.86, 0.48) if valid.has(str(combatant.get("id"))) else Color(0.5, 0.55, 0.62)
		elif is_party and index == _selected_index:
			button.modulate = Color(1.0, 0.88, 0.55)
		else:
			button.modulate = Color(1, 1, 1)
	card.get("style").border_color = Color(1.0, 0.78, 0.32) if _pending_target.get("valid", []).has(str(combatant.get("id"))) else Color(0.36, 0.48, 0.62)


func _status_names(statuses: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key: String in statuses.keys():
		match key:
			"status:disease":
				result.append(LocaleManager.t("status.disease"))
			"status:silence":
				result.append(LocaleManager.t("status.silence"))
			_:
				result.append(key.replace("status:", "").replace("buff:", "").replace("break:", ""))
	return result


func _has_queued(actor_id: String) -> bool:
	var queue_ref: RefCounted = manager.get("queue")
	if queue_ref == null:
		return false
	var actions_variant: Variant = queue_ref.get("actions")
	if not actions_variant is Array:
		return false
	for action: RefCounted in actions_variant:
		if str(action.actor_id) == actor_id:
			return true
	return false


func _phase_text(phase: String) -> String:
	match phase:
		"player":
			return LocaleManager.t("battle.player_phase")
		"enemy":
			return LocaleManager.t("battle.enemy_phase")
		"player_execution", "enemy_execution":
			return LocaleManager.t("battle.execution_phase")
		_:
			return LocaleManager.t("battle.phase", {"phase": phase})


func _target_label(targeting: String) -> String:
	match targeting:
		"enemy":
			return LocaleManager.t("target.enemy")
		"ally":
			return LocaleManager.t("target.ally")
		"self":
			return LocaleManager.t("target.self")
		"all_allies":
			return LocaleManager.t("target.all_allies")
		"all_enemies":
			return LocaleManager.t("target.all_enemies")
		_:
			return targeting


func _localized_token(token: String) -> String:
	match token:
		"REMASTERED_DESIGN":
			return LocaleManager.t("mechanic.remastered_design")
		"VERIFIED_RULE":
			return LocaleManager.t("mechanic.verified_rule")
		"PARTIAL_RULE":
			return LocaleManager.t("mechanic.partial_rule")
		"UNVERIFIED_RULE":
			return LocaleManager.t("mechanic.unverified_rule")
		"SYNTHETIC_FIXTURE":
			return LocaleManager.t("verification.synthetic_fixture")
		_:
			return token


func _card_tooltip(combatant: RefCounted) -> String:
	var definition_variant: Variant = combatant.get("definition_data")
	var definition: Dictionary = definition_variant if definition_variant is Dictionary else {}
	var labels_variant: Variant = definition.get("mechanic_labels", {})
	var labels: Dictionary = labels_variant if labels_variant is Dictionary else {}
	var status: String = str(definition.get("verification_status", ""))
	if labels.is_empty() and status.is_empty():
		return ""
	var label_texts: Array[String] = []
	for key: String in labels.keys():
		label_texts.append(_localized_token(str(labels[key])))
	return LocaleManager.t("battle.card_tooltip", {
		"labels": ", ".join(label_texts),
		"status": _localized_token(status)
	})


func _hint_text() -> String:
	if not _pending_target.is_empty():
		return LocaleManager.t("battle.hint_target", {
			"targeting": _target_label(str(_pending_target.get("targeting", "")))
		})
	if _command_mode == "abilities":
		return LocaleManager.t("battle.hint_abilities")
	if _command_mode == "items":
		return LocaleManager.t("battle.hint_items")
	if _executing:
		return LocaleManager.t("battle.hint_executing", {"speed": SPEEDS[_speed_index]})
	return LocaleManager.t("battle.hint_select", {"slot": _selected_index + 1})


# ---------------------------------------------------------------------------
# Player commands
# ---------------------------------------------------------------------------

func _current_actor() -> RefCounted:
	if _party_cards.is_empty():
		return null
	return _party_cards[clampi(_selected_index, 0, _party_cards.size() - 1)].get("combatant")


func _on_character_pressed(index: int) -> void:
	if _executing:
		return
	_selected_index = index
	_pending_target = {}
	_command_mode = ""
	_ability_scroll.visible = false
	_refresh()


func _on_attack_pressed() -> void:
	var actor: RefCounted = _current_actor()
	if actor == null:
		return
	_choose_action(str(actor.get("basic_attack")), "ability")


func _on_abilities_pressed() -> void:
	_command_mode = "abilities"
	_pending_target = {}
	_populate_ability_grid()
	_ability_scroll.visible = true
	_refresh()


func _on_limit_pressed() -> void:
	var actor: RefCounted = _current_actor()
	if actor == null:
		return
	_choose_action(str(actor.get("limit_ability")), "ability")


func _on_items_pressed() -> void:
	_command_mode = "items"
	_pending_target = {}
	_populate_item_grid()
	_ability_scroll.visible = true
	_refresh()


func _on_guard_pressed() -> void:
	var actor: RefCounted = _current_actor()
	if actor == null:
		return
	var result: Dictionary = manager.call("queue_guard", str(actor.get("id")))
	if bool(result.get("ok", false)):
		_pending_target = {}
		_command_mode = ""
		_ability_scroll.visible = false
	_refresh()


func _populate_ability_grid() -> void:
	for child: Node in _ability_grid.get_children():
		child.queue_free()
	var actor: RefCounted = _current_actor()
	if actor == null:
		return
	var ability_ids: Array = actor.get("abilities")
	for ability_id_variant: Variant in ability_ids:
		var ability_id: String = str(ability_id_variant)
		var definition: Dictionary = manager.call("get_ability_def", ability_id)
		var ability_name: String = str(definition.get("name", ability_id))
		var name_key: String = str(definition.get("name_key", ""))
		if not name_key.is_empty() and LocaleManager.has_key(name_key):
			ability_name = LocaleManager.t(name_key)
		var button := _button(LocaleManager.t("battle.ability_button", {
			"name": ability_name,
			"mp": int(definition.get("mp_cost", 0))
		}), 170)
		var mechanic: String = str(definition.get("mechanic_label", ""))
		var status: String = str(definition.get("verification_status", ""))
		if not mechanic.is_empty() or not status.is_empty():
			button.tooltip_text = LocaleManager.t("battle.ability_tooltip", {
				"label": _localized_token(mechanic),
				"status": _localized_token(status)
			})
		button.pressed.connect(_choose_action.bind(ability_id, "ability"))
		_ability_grid.add_child(button)


func _populate_item_grid() -> void:
	for child: Node in _ability_grid.get_children():
		child.queue_free()
	var package: Dictionary = ContentRepository.call("get_battle_package")
	var items_variant: Variant = package.get("items", {})
	if not items_variant is Dictionary:
		return
	for item_id: String in (items_variant as Dictionary).keys():
		var definition: Dictionary = manager.call("get_item_def", item_id)
		var button := _button(str(definition.get("name", item_id)), 170)
		button.pressed.connect(_choose_action.bind(item_id, "item"))
		_ability_grid.add_child(button)


func _choose_action(action_id: String, source_type: String) -> void:
	var actor: RefCounted = _current_actor()
	if actor == null or _executing:
		return
	var definition: Dictionary = manager.call("get_item_def", action_id) if source_type == "item" else manager.call("get_ability_def", action_id)
	if definition.is_empty():
		return
	var targeting: String = str(definition.get("targeting", "enemy"))
	if targeting in ["self", "all_allies", "all_enemies"]:
		_submit_action(action_id, source_type, "")
		return
	var valid: Array[String] = []
	var want_party: bool = targeting == "ally"
	var cards: Array[Dictionary] = _party_cards if want_party else _enemy_cards
	for card: Dictionary in cards:
		var target: RefCounted = card.get("combatant")
		if target == null or not bool(target.call("is_alive")):
			continue
		valid.append(str(target.get("id")))
	_pending_target = {
		"actor_id": str(actor.get("id")),
		"action_id": action_id,
		"source_type": source_type,
		"targeting": targeting,
		"valid": valid
	}
	_refresh()


func _on_card_pressed(target_id: String) -> void:
	if _pending_target.is_empty():
		return
	var valid: Array = _pending_target.get("valid", [])
	if not valid.has(target_id):
		return
	_submit_action(str(_pending_target.get("action_id")), str(_pending_target.get("source_type")), target_id)


func _submit_action(action_id: String, source_type: String, target_id: String) -> void:
	var actor: RefCounted = _current_actor()
	if actor == null:
		return
	var result: Dictionary = manager.call("queue_action", str(actor.get("id")), action_id, target_id, source_type)
	if bool(result.get("ok", false)):
		_pending_target = {}
		_command_mode = ""
		_ability_scroll.visible = false
	_refresh()


func _on_clear_pressed() -> void:
	manager.call("clear_queue")
	_pending_target = {}
	_refresh()


func _on_execute_pressed() -> void:
	if _executing:
		return
	_pending_target = {}
	var result: Dictionary = manager.call("begin_execution")
	if not bool(result.get("ok", false)):
		return
	_executing = true
	_tick_timer.start()
	_refresh()


func _on_tick() -> void:
	if manager == null or manager.get("state").get("result") != null:
		_tick_timer.stop()
		return
	var events: Array[Dictionary] = manager.call("advance_frames", SPEEDS[_speed_index])
	for event: Dictionary in events:
		_spawn_event_label(event)
	var state: RefCounted = manager.get("state")
	if state.get("result") != null:
		_tick_timer.stop()
		_executing = false
		_record_result(state)
		_show_result(state)
		return
	if _qa_freeze_frame >= 0 and int(manager.call("summary").get("frame", 0)) >= _qa_freeze_frame:
		_tick_timer.stop()
		_executing = false
		_refresh()
		return
	if str(state.get("phase")) == "player":
		_tick_timer.stop()
		_executing = false
	_refresh()


func _spawn_event_label(event: Dictionary) -> void:
	var data: Dictionary = event.get("data", {})
	var target_id: String = str(data.get("target_id", ""))
	var text: String = ""
	var color: Color = Color(1, 1, 1)
	match str(event.get("type", "")):
		"damage":
			text = "-%d" % int(data.get("amount", 0))
			color = Color(1.0, 0.42, 0.40)
		"heal":
			text = "+%d" % int(data.get("amount", 0))
			color = Color(0.45, 1.0, 0.58)
		"chain":
			var chain: Dictionary = data.get("chain", {})
			if int(chain.get("count", 0)) > 0:
				var kind: String = str(chain.get("kind", ""))
				if kind.is_empty():
					kind = LocaleManager.t("battle.chain")
				text = LocaleManager.t("battle.chain_event", {"kind": kind, "count": int(chain.get("count", 0))})
				color = Color(1.0, 0.84, 0.35)
		_:
			return
	if text.is_empty():
		return
	var anchor: Control = _damage_layer
	var actor_id: String = str(data.get("actor_id", ""))
	for card: Dictionary in _enemy_cards + _party_cards:
		var combatant: RefCounted = card.get("combatant")
		if combatant == null:
			continue
		var combatant_id: String = str(combatant.get("id"))
		if combatant_id == target_id or (str(event.get("type", "")) == "chain" and combatant_id == actor_id):
			anchor = card.get("panel")
			break
	var label := _label(text, 22, HORIZONTAL_ALIGNMENT_CENTER)
	label.modulate = color
	label.position = anchor.get_global_position() - get_global_position() + Vector2(24, 34)
	_damage_layer.add_child(label)
	if _qa_freeze_frame >= 0:
		return
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 46.0, 0.75)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.75)
	tween.tween_callback(label.queue_free)


func _record_result(state: RefCounted) -> void:
	if _result_recorded:
		return
	_result_recorded = true
	var result_variant: Variant = state.get("result")
	if result_variant is RefCounted:
		var result_dict: Dictionary = result_variant.call("to_dict")
		_result_snapshot = result_dict.duplicate(true)
		# Resolve through the active SceneTree so a headless test can call this
		# settlement hook before the battle scene is attached to a scene tree.
		var player_state: Node = null
		var loop: Variant = Engine.get_main_loop()
		if loop is SceneTree:
			player_state = (loop as SceneTree).root.get_node_or_null("PlayerState")
		var claim: Dictionary = {}
		if player_state != null and player_state.has_method("claim_battle_reward"):
			claim = player_state.call("claim_battle_reward", result_dict)
		_reward_status_key = _claim_status_key(claim)
		SaveManager.call("record_battle_result", result_dict, str(result_dict.get("run_id", _run_id)))


func _show_result(state: RefCounted) -> void:
	var result_variant: Variant = state.get("result")
	if result_variant == null:
		return
	var result: RefCounted = result_variant as RefCounted
	if result == null:
		return
	if _result_snapshot.is_empty():
		var snapshot_variant: Variant = result.call("to_dict")
		if snapshot_variant is Dictionary:
			_result_snapshot = snapshot_variant
	_render_result()
	_result_overlay.visible = true


func _render_result() -> void:
	if _result_snapshot.is_empty():
		return
	var victory: bool = bool(_result_snapshot.get("victory", false))
	var rewards_variant: Variant = _result_snapshot.get("rewards", {})
	var rewards: Dictionary = rewards_variant if rewards_variant is Dictionary else {}
	var items_variant: Variant = rewards.get("items", [])
	var items: Array = items_variant if items_variant is Array else []
	if victory:
		_result_title.text = LocaleManager.t("battle.victory")
	else:
		_result_title.text = LocaleManager.t("battle.defeat")
	_result_title.modulate = Color(0.55, 1.0, 0.64) if victory else Color(1.0, 0.52, 0.52)
	_result_body.text = LocaleManager.t("battle.result_detail", {
		"name": str(_result_snapshot.get("encounter_name", "")),
		"turns": int(_result_snapshot.get("turns", 0)),
		"seed": int(_result_snapshot.get("seed", 0)),
		"gil": int(rewards.get("gil", 0)),
		"items": ", ".join(items)
	}) + "\n" + LocaleManager.t("battle.run_id", {
		"id": str(_result_snapshot.get("run_id", _run_id))
	}) + "\n" + LocaleManager.t("battle.seed_source", {
		"source": str(_result_snapshot.get("seed_source", _seed_source))
	}) + "\n" + LocaleManager.t("battle.reward_status", {
		"status": LocaleManager.t(_reward_status_key)
	})
	if not _party_source_key.is_empty():
		_result_body.text += "\n" + LocaleManager.t(_party_source_key)


func _active_party_id() -> String:
	if _qa_mode():
		var qa_party: String = OS.get_environment("FFBE_QA_PARTY_ID")
		if not qa_party.is_empty():
			return qa_party
	var player_state: Node = get_node_or_null("/root/PlayerState")
	if player_state == null:
		return "default"
	var state_variant: Variant = player_state.get("data")
	if not state_variant is Dictionary:
		return "default"
	return str((state_variant as Dictionary).get("active_party", "default"))


func _party_combatants(party_id: String) -> Dictionary:
	var player_state: Node = get_node_or_null("/root/PlayerState")
	if party_id.is_empty() or player_state == null or player_state.build_resolver == null:
		return {}
	var party: Dictionary = player_state.call("get_party", party_id)
	if party.is_empty():
		return {}
	var slots_variant: Variant = party.get("slots", [])
	if not slots_variant is Array:
		return {}
	var slots: Array = slots_variant
	if slots.is_empty() or slots.size() > 5:
		return {}
	var result: Dictionary = {}
	var seen: Dictionary = {}
	for slot_variant: Variant in slots:
		var instance_id: String = str(slot_variant)
		if instance_id.is_empty() or seen.has(instance_id):
			return {}
		seen[instance_id] = true
		var definition: Dictionary = player_state.build_resolver.call("build_combatant_def", instance_id, party_id)
		if definition.is_empty():
			return {}
		result[instance_id] = definition
	return result


func _claim_status_key(claim: Dictionary) -> String:
	if claim.is_empty():
		return "battle.reward_unavailable"
	match str(claim.get("reason", "")):
		"already_claimed":
			return "battle.reward_already_claimed"
		"not_victory":
			return "battle.reward_not_victory"
		"save_failed":
			return "battle.reward_save_failed"
	if bool(claim.get("ok", false)):
		return "reward.saved"
	var message_key: String = str(claim.get("message", ""))
	if not message_key.is_empty() and LocaleManager.has_key(message_key):
		return message_key
	return "battle.reward_unavailable"


# ---------------------------------------------------------------------------
# Misc controls and QA hooks
# ---------------------------------------------------------------------------

func _on_speed_pressed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	_speed_button.text = LocaleManager.t("battle.speed_button", {"speed": SPEEDS[_speed_index]})
	_refresh()


func _on_pause_pressed() -> void:
	_paused = not _paused
	_pause_overlay.visible = _paused
	if _paused:
		_tick_timer.stop()
	elif _executing:
		_tick_timer.start()


func _on_encounter_selected(index: int) -> void:
	if index < 0 or index >= _encounter_ids.size():
		return
	_start_battle(_encounter_ids[index])


func _on_retry_pressed() -> void:
	var current: String = str(manager.get("state").get("encounter_id"))
	_start_battle(current)


## Build the return payload for a world encounter. Kept separate from scene
## navigation so the transition contract is directly testable headlessly.
func _world_return_context() -> Dictionary:
	if _return_scene_path == MAIN_MENU_PATH or not ResourceLoader.exists(_return_scene_path):
		return {}
	var payload: Dictionary = _world_context.duplicate(true)
	payload["return_scene"] = _return_scene_path
	if not _result_snapshot.is_empty():
		payload["battle_result"] = _result_snapshot.duplicate(true)
	return payload


func _on_menu_pressed() -> void:
	# A world encounter returns to its exploration area and carries the settled
	# battle result back. Reward claiming happens only in _record_result(), so a
	# retry or scene reload cannot grant the same run twice.
	var payload: Dictionary = _world_return_context()
	var destination: String = MAIN_MENU_PATH
	if not payload.is_empty():
		destination = _return_scene_path
		WorldContext.write(payload)
	else:
		WorldContext.clear()
	get_tree().change_scene_to_file(destination)


func _on_battle_event(event: Dictionary) -> void:
	if str(event.get("type", "")) == "phase_changed":
		_center_label.text = LocaleManager.t("battle.enemy_phase")
	elif str(event.get("type", "")) == "turn_started":
		_center_label.text = LocaleManager.t("battle.center_turn", {
			"turn": int((event.get("data", {}) as Dictionary).get("turn", 0))
		})


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.pressed:
		return
	if event.is_action_pressed("battle_pause"):
		_on_pause_pressed()
	elif event.is_action_pressed("battle_speed"):
		_on_speed_pressed()
	elif event.is_action_pressed("battle_cancel"):
		_pending_target = {}
		_command_mode = ""
		_ability_scroll.visible = false
		_refresh()
	elif event.is_action_pressed("battle_attack"):
		_on_attack_pressed()
	elif event.is_action_pressed("battle_abilities"):
		_on_abilities_pressed()
	elif event.is_action_pressed("battle_limit"):
		_on_limit_pressed()
	elif event.is_action_pressed("battle_items"):
		_on_items_pressed()
	elif event.is_action_pressed("battle_guard"):
		_on_guard_pressed()
	elif event.is_action_pressed("battle_execute"):
		_on_execute_pressed()
	elif event is InputEventKey:
		var key: InputEventKey = event
		if key.keycode >= KEY_1 and key.keycode <= KEY_6:
			_on_character_pressed(key.keycode - KEY_1)


func _qa_read_freeze_frame() -> void:
	if not _qa_mode():
		return
	var text: String = OS.get_environment("FFBE_QA_FREEZE_FRAME")
	if not text.is_empty() and text.is_valid_int():
		_qa_freeze_frame = text.to_int()


func _qa_apply_scenario(scenario: String) -> void:
	if not _qa_mode() or manager == null or _battle_blocked:
		return
	var state: RefCounted = manager.get("state")
	match scenario:
		"formation":
			for card: Dictionary in _party_cards:
				var actor: RefCounted = card.get("combatant")
				_selected_index = _party_cards.find(card)
				_choose_action(str(actor.get("basic_attack")), "ability")
				_submit_action(str(actor.get("basic_attack")), "ability", str(_enemy_cards[0].get("combatant").get("id")))
		"abilities":
			_on_abilities_pressed()
		"chain":
			_selected_index = 0
			_choose_action("ability:GL:931101@base", "ability")
			_submit_action("ability:GL:931101@base", "ability", str(_enemy_cards[0].get("combatant").get("id")))
			_selected_index = 1
			_choose_action("ability:GL:931102@base", "ability")
			_submit_action("ability:GL:931102@base", "ability", str(_enemy_cards[0].get("combatant").get("id")))
			_on_execute_pressed()
		"limit":
			for combatant in state.get("party"):
				combatant.set("lb_gauge", int(combatant.get("lb_cost")))
			_selected_index = 0
			_choose_action(str(_party_cards[0].get("combatant").get("limit_ability")), "ability")
			_submit_action(str(_party_cards[0].get("combatant").get("limit_ability")), "ability", str(_enemy_cards[0].get("combatant").get("id")))
			_selected_index = 1
			_choose_action(str(_party_cards[1].get("combatant").get("limit_ability")), "ability")
			_submit_action(str(_party_cards[1].get("combatant").get("limit_ability")), "ability", str(_enemy_cards[0].get("combatant").get("id")))
			_on_execute_pressed()
		"victory":
			for enemy in state.get("enemies"):
				enemy.set("hp", 1)
			var basic: String = str(_party_cards[0].get("combatant").get("basic_attack"))
			for enemy_card: Dictionary in _enemy_cards:
				var enemy_combatant: RefCounted = enemy_card.get("combatant") as RefCounted
				if enemy_combatant == null:
					continue
				_selected_index = 0
				_choose_action(basic, "ability")
				_submit_action(basic, "ability", str(enemy_combatant.get("id")))
			_on_execute_pressed()
		"defeat":
			for combatant in state.get("party"):
				combatant.set("hp", 1)
			var forced_ai: Dictionary = {
				"max_actions": 1,
				"action_start_frames": [4],
				"pattern": [{
					"ability": "ability:GL:933002@base", "weight": 1,
					"min_hp_percent": 0, "max_hp_percent": 100,
					"target_rule": "all_enemies", "cooldown": 0
				}]
			}
			for enemy in state.get("enemies"):
				var enemy_data: Dictionary = enemy.get("definition_data")
				enemy_data["ai"] = forced_ai.duplicate(true)
			_on_execute_pressed()
		_:
			pass
	_refresh()
