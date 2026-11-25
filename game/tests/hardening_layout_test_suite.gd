extends RefCounted

## Prompt 04.6 Battle Screen geometry regression suite.
##
## This suite is intentionally synchronous so it can be wired into the existing
## headless runner like phase3_test_suite.gd. A --script SceneTree has no active
## tree during _initialize(), so real Control rects cannot be sorted there.
## Instead the suite instantiates the real battle script, builds its UI, and
## checks the Container minimum sizes, clamped label widths, card budgets and
## sprite-local geometry that determine the sorted rects in a live viewport.
##
## The caller's PlayerState, locale and FFBE_QA_* environment are restored.

const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"
const MANAGER_SCRIPT := "res://battle/battle_manager.gd"
const ENCOUNTER_ID := "encounter:GL:950001@skirmish"
const BOSS_ENCOUNTER_ID := "encounter:GL:950002@boss"
const SEED := 20261125
const CARD_WIDTH := 130.0
const CARD_HEIGHT := 168.0
const CARD_SPRITE_HEIGHT := 64.0
const MAIN_MARGIN_X := 36.0
const MAIN_MARGIN_Y := 18.0
const FIELD_MARGIN_X := 24.0
const FIELD_SEPARATION := 6.0
const MAIN_SEPARATION := 8.0
const ENV_KEYS: Array[String] = [
	"FFBE_QA_SCENARIO", "FFBE_QA_SEED", "FFBE_QA_ENCOUNTER",
	"FFBE_QA_PARTY_ID", "FFBE_QA_FREEZE_FRAME", "FFBE_QA_LOCALE"
]

var runner: Object = null
var state: Node = null
var locale_manager: Node = null


func _init(p_runner: Object) -> void:
	runner = p_runner
	var tree: SceneTree = p_runner as SceneTree
	if tree != null:
		state = tree.root.get_node_or_null("PlayerState")
		locale_manager = tree.root.get_node_or_null("LocaleManager")


func run() -> bool:
	if runner == null or state == null or locale_manager == null:
		_ok(false, "layout suite services available")
		return false

	var original_data: Dictionary = (_data().duplicate(true) as Dictionary)
	var original_locale: String = str(locale_manager.get("current_locale"))
	var original_env: Dictionary = {}
	for key: String in ENV_KEYS:
		original_env[key] = OS.get_environment(key)

	if not bool(ContentRepository.get("loaded")):
		ContentRepository.call("load_content")

	OS.set_environment("FFBE_QA_SCENARIO", "abilities")
	OS.set_environment("FFBE_QA_SEED", str(SEED))
	OS.set_environment("FFBE_QA_ENCOUNTER", ENCOUNTER_ID)
	OS.set_environment("FFBE_QA_PARTY_ID", "")
	OS.set_environment("FFBE_QA_FREEZE_FRAME", "1")
	OS.set_environment("FFBE_QA_LOCALE", "ja")
	locale_manager.call("set_locale", "ja", false)

	var packed: PackedScene = load(BATTLE_SCENE) as PackedScene
	_ok(packed != null, "battle scene loads for layout suite")
	if packed == null:
		_restore(original_data, original_locale, original_env)
		return false

	var manager_script: Script = load(MANAGER_SCRIPT) as Script
	var package: Dictionary = ContentRepository.call("get_battle_package")
	var combatants: Dictionary = (package.get("combatants", {}) as Dictionary).duplicate(true)
	var abilities: Dictionary = package.get("abilities", {})
	var items: Dictionary = package.get("items", {})

	# A fresh instance per encounter avoids queue_free() cards from the previous
	# layout lingering in a detached tree where no frame ever processes them.
	for encounter_id: String in [ENCOUNTER_ID, BOSS_ENCOUNTER_ID]:
		var battle: Control = packed.instantiate() as Control
		_ok(battle != null, "battle scene instantiates as Control")
		if battle == null:
			continue
		# Build the real script tree without calling _ready(): absolute autoload
		# lookups in _start_battle() are unavailable outside an active SceneTree.
		battle.set_anchors_preset(Control.PRESET_TOP_LEFT)
		battle.call("_build_ui")
		var encounter: Dictionary = (ContentRepository.call("get_encounter", encounter_id) as Dictionary).duplicate(true)
		battle.manager = manager_script.new(encounter, combatants, abilities, items, SEED)
		battle.manager.call("start_battle")
		battle.call("_rebuild_cards")
		battle.call("_apply_locale", "ja")
		battle.call("_populate_ability_grid")
		battle.call("_refresh")
		var ability_scroll: Control = battle.get("_ability_scroll") as Control
		ability_scroll.visible = true

		var main_layout: Control = battle.get("_main_layout") as Control
		var field: Control = battle.get("_field") as Control
		var field_row: Control = battle.get("_field_row") as Control
		var top_bar: Control = battle.get("_top_bar") as Control
		var character_row: Control = battle.get("_character_row") as Control
		var command_row: Control = battle.get("_command_row") as Control
		var debug_row: Control = battle.get("_debug_row") as Control
		var enemy_area: Control = battle.get("_enemy_area") as Control
		var party_area: Control = battle.get("_party_area") as Control
		var command_panel: Control = main_layout.get_child(2) as Control

		var containers_ok: bool = main_layout != null and field != null and field_row != null \
			and top_bar != null and character_row != null and command_row != null \
			and debug_row != null and enemy_area != null and party_area != null \
			and command_panel != null
		_ok(containers_ok, "responsive layout containers exist for %s" % encounter_id)
		if containers_ok:
			_check_viewports(battle, main_layout, field_row, top_bar, character_row,
				command_row, debug_row, enemy_area, party_area, command_panel)
			_check_cards(battle)
			_check_labels_and_debug(battle, command_panel, top_bar, debug_row)
		battle.free()

	_restore(original_data, original_locale, original_env)
	return true


# --- multi-viewport invariants ---------------------------------------------------

func _check_viewports(
	battle: Control,
	main_layout: Control,
	field_row: Control,
	top_bar: Control,
	character_row: Control,
	command_row: Control,
	debug_row: Control,
	enemy_area: Control,
	party_area: Control,
	command_panel: Control
) -> void:
	# canvas_items + expand maps these physical windows to these logical sizes.
	var windows: Array[Vector2i] = [Vector2i(1024, 640), Vector2i(1280, 720), Vector2i(1920, 1080)]
	for window: Vector2i in windows:
		var logical: Vector2 = _logical_size(window)
		var expected: Vector2 = Vector2(1280.0, 800.0) if window == Vector2i(1024, 640) else Vector2(1280.0, 720.0)
		_ok(_near(logical, expected), "logical viewport for %dx%d is %.0fx%.0f" % [
			window.x, window.y, logical.x, logical.y
		])

		var available_width: float = logical.x - MAIN_MARGIN_X
		var available_height: float = logical.y - MAIN_MARGIN_Y
		_ok(top_bar.get_combined_minimum_size().x <= available_width,
			"top bar fits %dx%d (min %.1f <= %.1f)" % [
				window.x, window.y, top_bar.get_combined_minimum_size().x, available_width
			])
		_ok(character_row.get_combined_minimum_size().x <= available_width,
			"character row fits %dx%d (min %.1f <= %.1f)" % [
				window.x, window.y, character_row.get_combined_minimum_size().x, available_width
			])
		_ok(command_row.get_combined_minimum_size().x <= available_width,
			"command row fits %dx%d (min %.1f <= %.1f)" % [
				window.x, window.y, command_row.get_combined_minimum_size().x, available_width
			])
		_ok(debug_row.get_combined_minimum_size().x <= available_width,
			"debug row fits %dx%d (min %.1f <= %.1f)" % [
				window.x, window.y, debug_row.get_combined_minimum_size().x, available_width
			])

		var field_width: float = available_width - FIELD_MARGIN_X
		var field_row_min: float = enemy_area.get_combined_minimum_size().x \
			+ 72.0 + party_area.get_combined_minimum_size().x + 2.0 * FIELD_SEPARATION
		_ok(field_row_min <= field_width,
			"battlefield rows fit %dx%d (min %.1f <= %.1f)" % [
				window.x, window.y, field_row_min, field_width
			])

		var stack_min: float = top_bar.get_combined_minimum_size().y \
			+ 220.0 + command_panel.get_combined_minimum_size().y + 2.0 * MAIN_SEPARATION
		_ok(stack_min <= available_height,
			"vertical stack fits %dx%d with ability grid (min %.1f <= %.1f)" % [
				window.x, window.y, stack_min, available_height
			])

		# The simulated scene size is only used to keep the assertion context
		# explicit; no sorted rects are read from a detached tree.
		battle.size = logical


func _logical_size(window: Vector2i) -> Vector2:
	var base_x: float = float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
	var base_y: float = float(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
	var scale: float = minf(float(window.x) / base_x, float(window.y) / base_y)
	return Vector2(float(window.x) / scale, float(window.y) / scale)


# --- combatant cards ------------------------------------------------------------

func _check_cards(battle: Control) -> void:
	var enemy_cards: Array = battle.get("_enemy_cards")
	var party_cards: Array = battle.get("_party_cards")
	var enemies: Array = battle.manager.get("state").get("enemies")
	var party: Array = battle.manager.get("state").get("party")
	_eq(enemy_cards.size(), enemies.size(), "enemy cards match encounter enemies")
	_eq(party_cards.size(), party.size(), "party cards match encounter party")
	_eq((battle.get("_enemy_area") as Control).get_child_count(), enemies.size(),
		"enemy area has no reserved companion slot")

	for group: String in ["party", "enemy"]:
		var cards: Array = party_cards if group == "party" else enemy_cards
		for index: int in cards.size():
			var card: Dictionary = cards[index]
			var panel: Control = card.get("panel") as Control
			_ok(panel != null, "%s card %d has a panel" % [group, index])
			if panel == null:
				continue
			_ok(_near(panel.custom_minimum_size, Vector2(CARD_WIDTH, CARD_HEIGHT)),
				"%s card %d uses fixed %.0fx%.0f budget" % [group, index, CARD_WIDTH, CARD_HEIGHT])
			_ok(panel.size_flags_horizontal == Control.SIZE_SHRINK_CENTER
				and panel.size_flags_vertical == Control.SIZE_SHRINK_CENTER,
				"%s card %d does not stretch across the battlefield" % [group, index])

			var button: Button = card.get("button") as Button
			_ok(button != null and button.clip_text
				and button.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS,
				"%s card %d name is clamped with ellipsis" % [group, index])
			if button != null:
				_ok(button.get_combined_minimum_size().x <= CARD_WIDTH,
					"%s card %d name cannot inflate card width" % [group, index])

			var host: Control = null
			for child: Node in panel.find_children("*", "Control", true, false):
				var control: Control = child as Control
				if control != null and _near(control.custom_minimum_size, Vector2(0.0, CARD_SPRITE_HEIGHT)):
					host = control
					break
			_ok(host != null, "%s card %d has a sprite host" % [group, index])
			if host == null:
				continue

			var sprites: Array[Node] = host.find_children("*", "AnimatedSprite2D", true, false)
			_ok(sprites.size() == 1, "%s card %d has one synthetic sprite" % [group, index])
			if sprites.is_empty():
				continue
			var sprite: AnimatedSprite2D = sprites[0] as AnimatedSprite2D
			if sprite == null or sprite.sprite_frames == null:
				_ok(false, "%s card %d sprite frames available" % [group, index])
				continue
			var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
			if texture == null:
				_ok(false, "%s card %d sprite texture available" % [group, index])
				continue
			var scaled: Vector2 = texture.get_size() * sprite.scale
			var top_left: Vector2 = sprite.position + sprite.offset * sprite.scale
			if sprite.centered:
				top_left -= scaled * 0.5
			_ok(top_left.x >= -0.5 and top_left.y >= -0.5
				and top_left.x + scaled.x <= CARD_WIDTH + 0.5
				and top_left.y + scaled.y <= CARD_SPRITE_HEIGHT + 0.5,
				"%s card %d sprite stays inside its host" % [group, index])
			_ok(absf(sprite.scale.x - sprite.scale.y) <= 0.001
				and absf((scaled.x / maxf(scaled.y, 0.001)) - (texture.get_size().x / maxf(texture.get_size().y, 0.001))) <= 0.01,
				"%s card %d keeps original sprite proportions" % [group, index])


# --- clamped text and QA/debug separation --------------------------------------

func _check_labels_and_debug(battle: Control, command_panel: Control, top_bar: Control, debug_row: Control) -> void:
	var encounter_option: Control = battle.get("_encounter_option") as Control
	_ok(encounter_option != null and encounter_option.get_parent() == debug_row,
		"encounter selector lives in the debug footer")
	var has_option_in_top_bar: bool = false
	for child: Node in top_bar.get_children():
		if child is OptionButton:
			has_option_in_top_bar = true
	_ok(not has_option_in_top_bar, "player top bar has no QA selector")
	if debug_row != null and command_panel != null:
		var parent: Node = debug_row.get_parent()
		_ok(parent != null and parent.get_parent() != null and parent.get_parent().get_parent() == command_panel,
			"debug footer is inside the command panel, not the battlefield")
		var debug_index: int = debug_row.get_index()
		_ok(debug_index > 0 and parent.get_child(debug_index - 1) is HSeparator,
			"debug footer is separated from player commands")
	_ok((battle.get("_debug_label") as Label).text == LocaleManager.t("settings.debug"),
		"debug footer label follows locale")

	var character_buttons: Array = battle.get("_character_buttons")
	_ok(character_buttons.size() == (battle.get("_party_cards") as Array).size(),
		"one character button per party member")
	for index: int in character_buttons.size():
		var button: Button = character_buttons[index] as Button
		if button == null:
			_ok(false, "character button %d exists" % index)
			continue
		_ok(button.custom_minimum_size.x >= 150.0 and button.clip_text
			and button.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS,
			"character button %d uses a fixed, clamped width" % index)

	# Longest supported localized strings must not inflate minimum widths.
	var long_text: String = LocaleManager.t("battle.hint_abilities").repeat(3)
	var hint: Label = battle.get("_hint_label") as Label
	var log: Label = battle.get("_log_label") as Label
	hint.text = long_text
	log.text = long_text
	_ok(hint.get_combined_minimum_size().x <= 1.0,
		"long hint text is ellipsized, not expanded")
	_ok(log.get_combined_minimum_size().x <= 1.0,
		"long battle log text is ellipsized, not expanded")


# --- helpers --------------------------------------------------------------------

func _data() -> Dictionary:
	var value: Variant = state.get("data")
	return value if value is Dictionary else {}


func _ok(condition: bool, label: String) -> void:
	runner.call("assert_true", condition, "layout %s" % label)


func _eq(actual: Variant, expected: Variant, label: String) -> void:
	runner.call("assert_eq", actual, expected, "layout %s" % label)


func _near(actual: Vector2, expected: Vector2) -> bool:
	return absf(actual.x - expected.x) <= 0.5 and absf(actual.y - expected.y) <= 0.5


func _restore(original_data: Dictionary, original_locale: String, original_env: Dictionary) -> void:
	if JSON.stringify(_data()) != JSON.stringify(original_data):
		state.set("data", original_data)
		state.call("rebuild_systems")
	locale_manager.call("set_locale", original_locale, false)
	for key: String in ENV_KEYS:
		OS.set_environment(key, str(original_env.get(key, "")))
