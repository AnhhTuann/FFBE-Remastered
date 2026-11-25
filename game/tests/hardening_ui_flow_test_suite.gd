class_name HardeningUiFlowTestSuite
extends RefCounted

## End-to-end UI hardening coverage for boot/menu, locale, Phase 3 screens,
## party launch and battle reward persistence.
##
## The suite drives real Godot controls (pressed.emit(), OptionButton signals and
## InputEventAction) through real change_scene_to_file navigation. It uses only
## project-authored SYNTHETIC_FIXTURE ids from game/data/phase3 and restores the
## owner's user:// files, in-memory service state and environment variables.

const PLAYER_STATE_PATH := "user://player_state_v3.json"
const SETTINGS_PATH := "user://settings.json"
const BATTLE_PROGRESS_PATH := "user://battle_progress.json"

const BOOT_PATH := "res://scenes/boot/boot.tscn"
const MENU_PATH := "res://scenes/menu/main_menu.tscn"
const SETTINGS_PATH_RES := "res://scenes/settings/settings.tscn"
const COLLECTION_PATH := "res://scenes/phase3/collection.tscn"
const DETAILS_PATH := "res://scenes/phase3/character_details.tscn"
const UPGRADE_PATH := "res://scenes/phase3/upgrade.tscn"
const EQUIPMENT_PATH := "res://scenes/phase3/equipment.tscn"
const VISION_PATH := "res://scenes/phase3/vision_card.tscn"
const PARTY_PATH := "res://scenes/phase3/party.tscn"
const BATTLE_PATH := "res://scenes/battle/battle_scene.tscn"

const V1 := "unit:GL:910101:0001@base"
const V2 := "unit:GL:910102:0002@base"
const V3 := "unit:GL:910103:0003@base"
const JP1 := "unit:JP:910104:0004@base"
const V5 := "unit:GL:910105:0005@base"
const PARTY_IDS: Array[String] = [V1, V2, V3, JP1, V5]

const BLADE := "owned:GL:500001:0001@blade"
const MAT_ATK := "owned:GL:600001:0008@base"
const VC_GL := "owned:GL:700001:0015@base"
const VC_ARCANE := "owned:GL:700003:0017@base"
const POT_HP_KEY := "item:GL:810001@base"
const QA_PARTY := "qa_ui_flow"

var runner: Object
var tree: SceneTree
var state: Node
var saves: Node
var locale_manager: Node
var repository: Node
var _tracked: Array[Node] = []
var _file_snapshot: Dictionary = {}
var _env_snapshot: Dictionary = {}
var _original_data: Dictionary = {}
var _original_settings: Dictionary = {}
var _original_locale: String = ""
var _original_last_error: String = ""
var _flow_failures: int = 0


func _init(p_runner: Object) -> void:
	runner = p_runner
	tree = p_runner as SceneTree
	if tree != null:
		state = tree.root.get_node_or_null("PlayerState")
		saves = tree.root.get_node_or_null("SaveManager")
		locale_manager = tree.root.get_node_or_null("LocaleManager")
		repository = tree.root.get_node_or_null("ContentRepository")


func run() -> bool:
	_flow_failures = 0
	if runner == null or tree == null or state == null or saves == null or locale_manager == null or repository == null:
		_ok(false, "ui-flow services available")
		return false

	await tree.process_frame
	if not bool(repository.get("loaded")):
		repository.call("load_content")
	_ok(bool(repository.get("loaded")), "content loaded before UI flows")

	_snapshot_environment()
	_snapshot_files()
	_original_data = _data().duplicate(true)
	_original_settings = (saves.get("_settings") as Dictionary).duplicate(true)
	_original_locale = str(locale_manager.get("current_locale"))
	_original_last_error = str(state.get("last_error"))

	_seed_synthetic_state()

	await _run_flow("test_boot_menu_and_locale")
	await _run_flow("test_collection_and_upgrade")
	await _run_flow("test_equipment_and_vision_card")
	await _run_flow("test_party_battle_and_rewards")
	await _run_flow("test_save_migration_and_refusal")

	_cleanup_transit()
	_restore_environment()
	_restore_files()
	state.set("data", _original_data)
	state.set("last_error", _original_last_error)
	state.call("rebuild_systems")
	saves.set("_settings", _original_settings)
	locale_manager.call("set_locale", _original_locale, false)
	_free_tracked()
	if tree.current_scene != null:
		tree.current_scene = null
	return _flow_failures == 0


func _run_flow(test_name: String) -> void:
	var result: Variant = await call(test_name)
	if result != true:
		_flow_failures += 1
		_ok(false, "ui-flow %s did not finish" % test_name)


# --- assertion helpers ---------------------------------------------------------

func _ok(condition: bool, label: String) -> void:
	runner.call("assert_true", condition, label)


func _no(condition: bool, label: String) -> void:
	runner.call("assert_false", condition, label)


func _eq(actual: Variant, expected: Variant, label: String) -> void:
	runner.call("assert_eq", actual, expected, label)


# --- state and UI helpers ------------------------------------------------------

func _data() -> Dictionary:
	var value: Variant = state.get("data")
	return value if value is Dictionary else {}


func _unit(instance_id: String) -> Dictionary:
	var value: Variant = state.call("get_unit_instance", instance_id)
	return value if value is Dictionary else {}


func _party(party_id: String) -> Dictionary:
	var value: Variant = state.call("get_party", party_id)
	return value if value is Dictionary else {}


func _t(key: String) -> String:
	return str(locale_manager.call("t", key))


func _snapshot_environment() -> void:
	for key: String in [
		"FFBE_QA_INSTANCE_ID", "FFBE_QA_PARTY_ID", "FFBE_QA_LOCALE",
		"FFBE_QA_ENCOUNTER", "FFBE_QA_SEED", "FFBE_QA_FREEZE_FRAME",
		"FFBE_QA_SCENARIO"
	]:
		_env_snapshot[key] = OS.get_environment(key)


func _restore_environment() -> void:
	for key: String in _env_snapshot.keys():
		OS.set_environment(key, str(_env_snapshot[key]))


func _managed_paths() -> Array[String]:
	var paths: Array[String] = [PLAYER_STATE_PATH, SETTINGS_PATH, BATTLE_PROGRESS_PATH]
	for slot: int in range(3):
		paths.append("user://save_slot_%d.json" % slot)
	return paths


func _snapshot_files() -> void:
	for base: String in _managed_paths():
		for suffix: String in ["", ".bak", ".tmp"]:
			var path := base + suffix
			var exists := FileAccess.file_exists(path)
			_file_snapshot[path] = {
				"exists": exists,
				"text": FileAccess.get_file_as_string(path) if exists else ""
			}


func _restore_files() -> void:
	for path: String in _file_snapshot.keys():
		var record: Dictionary = _file_snapshot[path]
		var exists := bool(record.get("exists", false))
		if FileAccess.file_exists(path):
			var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			_ok(error == OK or error == ERR_FILE_NOT_FOUND, "remove QA file %s" % path)
		if exists:
			var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string(str(record.get("text", "")))
				file.close()
			else:
				_ok(false, "restore QA file %s" % path)


func _seed_synthetic_state() -> void:
	OS.set_environment("FFBE_QA_INSTANCE_ID", V1)
	OS.set_environment("FFBE_QA_PARTY_ID", QA_PARTY)
	OS.set_environment("FFBE_QA_LOCALE", "")
	OS.set_environment("FFBE_QA_ENCOUNTER", "encounter:GL:950001@skirmish")
	OS.set_environment("FFBE_QA_SEED", "424242")
	OS.set_environment("FFBE_QA_FREEZE_FRAME", "")
	OS.set_environment("FFBE_QA_SCENARIO", "")
	locale_manager.call("set_locale", _original_locale, false)
	state.call("reset_to_defaults")
	var party := {
		"display_name": "QA UI Flow",
		"slots": ["", "", "", "", ""],
		"leader_slot": 0
	}
	state.call("set_party", QA_PARTY, party)
	state.call("commit", "parties")
	_eq(str(state.call("locale")), _original_locale, "synthetic state starts from caller locale")


func _track(node: Node) -> void:
	if node != null and not _tracked.has(node):
		_tracked.append(node)


func _free_tracked() -> void:
	for node: Node in _tracked:
		if is_instance_valid(node):
			node.free()
	_tracked.clear()
	_cleanup_transit()


func _cleanup_transit() -> void:
	for child: Node in tree.root.get_children():
		if child.name == "selection" and is_instance_valid(child):
			child.free()


func _wait_for_scene(path: String, max_frames: int) -> Control:
	var frames := 0
	while frames < max_frames:
		await tree.process_frame
		frames += 1
		var scene: Node = tree.current_scene
		if scene != null and str(scene.scene_file_path) == path:
			_track(scene)
			return scene as Control
	_ok(false, "scene ready: %s after %d frames" % [path, frames])
	return null


func _find_buttons(node: Node, text: String, exact: bool) -> Array[Button]:
	var result: Array[Button] = []
	if node == null:
		return result
	if node is Button:
		var button := node as Button
		var matches := button.text == text if exact else button.text.findn(text) >= 0
		if matches:
			result.append(button)
	for child: Node in node.get_children():
		for found: Button in _find_buttons(child, text, exact):
			result.append(found)
	return result


func _find_button(node: Node, text: String, exact: bool = true) -> Button:
	var buttons := _find_buttons(node, text, exact)
	return buttons[0] if not buttons.is_empty() else null


func _find_enabled_button(node: Node, text: String, exact: bool = true) -> Button:
	for button: Button in _find_buttons(node, text, exact):
		if not button.disabled:
			return button
	return null


func _press(node: Node, text: String = "", exact: bool = true) -> bool:
	var button: Button = null
	if text.is_empty():
		button = node as Button
		if button != null and button.disabled:
			button = null
	else:
		button = _find_enabled_button(node, text, exact)
	if button == null:
		_ok(false, "button available: %s" % (text if not text.is_empty() else str(node.name if node != null else "null")))
		return false
	button.pressed.emit()
	return true


func _option_index(option: OptionButton, value: String) -> int:
	if option == null:
		return -1
	for index: int in range(option.item_count):
		if str(option.get_item_metadata(index)) == value:
			return index
	return -1


func _emit_option(option: OptionButton, value: String, label: String) -> bool:
	var index := _option_index(option, value)
	_ok(index >= 0, "%s option present: %s" % [label, value])
	if index < 0:
		return false
	option.selected = index
	option.item_selected.emit(index)
	return true


func _read_json_dict(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	var error: Error = parser.parse(file.get_as_text())
	file.close()
	if error != OK or not parser.data is Dictionary:
		return {}
	return parser.data


# --- boot, menu and locale -----------------------------------------------------

func test_boot_menu_and_locale() -> bool:
	var bootstrap := Node.new()
	tree.root.add_child(bootstrap)
	var change_error: Error = tree.change_scene_to_file(BOOT_PATH)
	_eq(change_error, OK, "boot scene change requested")
	bootstrap.free()

	var menu := await _wait_for_scene(MENU_PATH, 600)
	if menu == null:
		return false
	_eq(str(menu.scene_file_path), MENU_PATH, "boot advances to main menu")
	var boot_status := str(locale_manager.call("t", "boot.loaded", {"count": 4, "marker": "SYNTHETIC_FIXTURE"}))
	_ok(not boot_status.is_empty(), "boot loaded copy resolves")
	_eq(str(menu.get_node("Layout/TitleLabel").text), _t("menu.title"), "menu title localized")
	_ok(str(menu.get_node("Layout/StatusLabel").text).find("unit:") >= 0 or \
		str(menu.get_node("Layout/StatusLabel").text).length() > 0, "menu status rendered")

	if not _press(menu.get_node("Layout/SettingsButton")):
		return false
	var settings_scene := await _wait_for_scene(SETTINGS_PATH_RES, 60)
	if settings_scene == null:
		return false
	var target_locale := "ja" if str(locale_manager.get("current_locale")) != "ja" else "en"
	var option := settings_scene.get("locale_option") as OptionButton
	if not _emit_option(option, target_locale, "settings locale"):
		return false
	_eq(str(locale_manager.get("current_locale")), target_locale, "locale switches live")
	_eq(str(saves.call("load_settings").get("locale", "")), target_locale, "locale preference persisted")
	_eq(str(state.call("locale")), target_locale, "PlayerState locale follows live switch")
	if not _press(settings_scene.get_node("Layout/SaveButton")):
		return false
	_eq(str(settings_scene.get_node("Layout/StatusLabel").text), _t("settings.saved"), "settings save visible")
	if not _press(settings_scene.get_node("Layout/BackButton")):
		return false
	menu = await _wait_for_scene(MENU_PATH, 60)
	if menu == null:
		return false
	_eq(str(menu.get_node("Layout/TitleLabel").text), _t("menu.title"), "menu relocalizes after settings")

	if not _press(menu.get_node("Layout/CollectionButton")):
		return false
	var collection := await _wait_for_scene(COLLECTION_PATH, 60)
	if collection == null:
		return false
	_ok((collection.get("_rows") as Node).get_child_count() > 0, "collection rows built from synthetic state")
	if not _press(_find_button(collection, _t("common.back"))):
		return false
	menu = await _wait_for_scene(MENU_PATH, 60)
	if menu == null:
		return false
	_ok(true, "main menu <- collection navigation completed")
	if not _press(menu.get_node("Layout/CollectionButton")):
		return false
	collection = await _wait_for_scene(COLLECTION_PATH, 60)
	if collection == null:
		return false
	return true


# --- collection and upgrade ----------------------------------------------------

func test_collection_and_upgrade() -> bool:
	var collection := tree.current_scene as Control
	if collection == null or str(collection.scene_file_path) != COLLECTION_PATH:
		_ok(false, "collection active for selection flow")
		return false

	var search := collection.get("_search") as LineEdit
	search.text = V1
	search.text_changed.emit(V1)
	await tree.process_frame
	_ok((collection.get("_rows") as Node).get_child_count() > 0, "search filters owned instances")
	var details_button := _find_button(collection.get("_rows"), _t("collection.details"))
	_ok(details_button != null, "details button available for searched row")
	if details_button == null:
		return false
	details_button.pressed.emit()
	var details := await _wait_for_scene(DETAILS_PATH, 60)
	if details == null:
		return false
	_eq(str(details.get("_selected_id")), V1, "details receives selected instance")
	_ok(_find_button(details, _t("common.favorite"), false) != null, "favorite control rendered")

	var favorite := _find_enabled_button(details, _t("common.favorite"), false)
	favorite.pressed.emit()
	_ok(bool(_unit(V1).get("favorite", false)), "favorite toggled on from details button")
	favorite = _find_enabled_button(details, _t("common.favorite"), false)
	favorite.pressed.emit()
	_no(bool(_unit(V1).get("favorite", false)), "favorite toggled off from details button")

	if not _press(details, _t("details.upgrade")):
		return false
	var upgrade := await _wait_for_scene(UPGRADE_PATH, 60)
	if upgrade == null:
		return false
	_eq(str(upgrade.get("_selected_id")), V1, "upgrade receives selected instance")
	var before_level := int(_unit(V1).get("level", 0))
	var gain := _find_enabled_button(upgrade, _t("upgrade.gain_exp"), false)
	_ok(gain != null, "gain EXP button present")
	if gain == null:
		return false
	gain.pressed.emit()
	_eq(int(_unit(V1).get("level", 0)), before_level + 1, "gain EXP button levels unit")
	_eq(int(_unit(V1).get("exp", -1)), 0, "gain EXP consumes required EXP")
	_ok(FileAccess.file_exists(PLAYER_STATE_PATH), "upgrade commits player state file")

	var stat_option := upgrade.get("_stat_option") as OptionButton
	if not _emit_option(stat_option, "hp", "upgrade stat"):
		return false
	var before_pots := int(state.call("get_resource", POT_HP_KEY))
	var pot_button := _find_enabled_button(upgrade, _t("upgrade.use_pot"))
	_ok(pot_button != null, "use-pot button present")
	if pot_button == null:
		return false
	pot_button.pressed.emit()
	var allocations: Dictionary = (_unit(V1).get("pot_allocations", {}) as Dictionary)
	_eq(int(allocations.get("hp", 0)), 20, "selected pot applied to hp")
	_eq(int(state.call("get_resource", POT_HP_KEY)), before_pots - 1, "pot item consumed")
	return true


# --- equipment and vision card -------------------------------------------------

func test_equipment_and_vision_card() -> bool:
	if not _press(tree.current_scene, _t("common.back")):
		return false
	var details := await _wait_for_scene(DETAILS_PATH, 60)
	if details == null:
		return false
	if not _press(details, _t("details.equipment")):
		return false
	var equipment := await _wait_for_scene(EQUIPMENT_PATH, 60)
	if equipment == null:
		return false
	_eq(str(equipment.get("_selected_id")), V1, "equipment receives selected instance")
	_eq(str(equipment.get("_slot_filter")), "weapon", "equipment starts on weapon filter")

	if not _press(equipment, _t("equipment.equip")):
		return false
	var equipped: Dictionary = (_unit(V1).get("equipped", {}) as Dictionary)
	_eq(str(equipped.get("weapon", "")), BLADE, "equip button writes weapon slot")
	var unequip := _find_enabled_button(equipment, _t("equipment.unequip"))
	_ok(unequip != null, "enabled unequip button present after equip")
	if unequip == null:
		return false
	unequip.pressed.emit()
	equipped = (_unit(V1).get("equipped", {}) as Dictionary)
	_eq(str(equipped.get("weapon", "")), "", "unequip button clears weapon slot")

	var filter_option := equipment.get("_filter_option") as OptionButton
	if not _emit_option(filter_option, "materia", "equipment filter"):
		return false
	await tree.process_frame
	_eq(str(equipment.get("_slot_filter")), "materia", "materia filter selected")
	_eq(str(equipment.get("_selected_uid")), MAT_ATK, "first materia selected")
	if not _press(equipment, _t("equipment.equip")):
		return false
	equipped = (_unit(V1).get("equipped", {}) as Dictionary)
	_eq(str(equipped.get("materia_0", "")), MAT_ATK, "materia equipped through UI")
	var materia_unequip := _find_enabled_button(equipment, _t("equipment.unequip"))
	_ok(materia_unequip != null, "enabled materia unequip button present")
	if materia_unequip == null:
		return false
	materia_unequip.pressed.emit()
	equipped = (_unit(V1).get("equipped", {}) as Dictionary)
	_eq(str(equipped.get("materia_0", "")), "", "materia unequip clears slot")

	filter_option = equipment.get("_filter_option") as OptionButton
	if not _emit_option(filter_option, "vision_card", "equipment filter"):
		return false
	await tree.process_frame
	_eq(str(equipment.get("_slot_filter")), "vision_card", "vision-card filter selected")
	_eq(str(equipment.get("_selected_uid")), VC_GL, "first vision card selected")
	if not _press(equipment, _t("equipment.equip")):
		return false
	_eq(str(_party(QA_PARTY).get("vision_card", "")), VC_GL, "vision card assigned to QA party")

	if not _press(equipment, _t("common.back")):
		return false
	details = await _wait_for_scene(DETAILS_PATH, 60)
	if details == null:
		return false
	if not _press(details, _t("details.party")):
		return false
	var party := await _wait_for_scene(PARTY_PATH, 60)
	if party == null:
		return false
	if not _press(party, _t("vision.title")):
		return false
	var vision := await _wait_for_scene(VISION_PATH, 60)
	if vision == null:
		return false
	_eq(str(vision.get("_party_id")), QA_PARTY, "vision screen reads QA party id")
	_eq(str(vision.get("_selected_uid")), VC_GL, "assigned vision card selected")
	if not _press(vision, _t("vision.unassign")):
		return false
	_eq(str(_party(QA_PARTY).get("vision_card", "")), "", "vision unassign button clears party card")
	var list := vision.get("_list") as ItemList
	var arcane_index := -1
	for index: int in range(list.item_count):
		if str(list.get_item_metadata(index)) == VC_ARCANE:
			arcane_index = index
			break
	_ok(arcane_index >= 0, "synthetic arcane vision card listed")
	if arcane_index >= 0:
		list.item_selected.emit(arcane_index)
		_eq(str(vision.get("_selected_uid")), VC_ARCANE, "vision card selection changes detail")
		if not _press(vision, _t("vision.assign")):
			return false
		_eq(str(_party(QA_PARTY).get("vision_card", "")), VC_ARCANE, "assign button writes party card")
	if not _press(vision, _t("common.back")):
		return false
	party = await _wait_for_scene(PARTY_PATH, 60)
	if party == null:
		return false
	return true


# --- party, battle and rewards -------------------------------------------------

func test_party_battle_and_rewards() -> bool:
	var party := tree.current_scene as Control
	if party == null or str(party.scene_file_path) != PARTY_PATH:
		_ok(false, "party active for launch flow")
		return false

	for index: int in range(PARTY_IDS.size()):
		var options: Array = party.get("_slot_options")
		if index >= options.size():
			_ok(false, "slot option %d available" % index)
			return false
		var option := options[index] as OptionButton
		var item_index := _option_index(option, PARTY_IDS[index])
		_ok(item_index >= 0, "party slot %d has synthetic unit" % index)
		if item_index < 0:
			return false
		option.item_selected.emit(item_index)
		options = party.get("_slot_options")
		_eq(str((options[index] as OptionButton).get_item_metadata(
			(options[index] as OptionButton).selected)), PARTY_IDS[index],
			"party slot %d selection" % index)

	var working: Dictionary = party.get("_working")
	var slots: Array = working.get("slots", [])
	_eq(slots.size(), PARTY_IDS.size(), "five party slots updated")
	for index: int in range(PARTY_IDS.size()):
		_eq(str(slots[index]), PARTY_IDS[index], "working slot %d" % index)

	if not _press(party, _t("party.preview")):
		return false
	_ok(str(party.get("_last_preview")).length() > 0, "party preview rendered")
	var gil_before := int(state.call("get_resource", "gil"))
	if not _press(party, _t("party.launch")):
		return false
	var battle := await _wait_for_scene(BATTLE_PATH, 60)
	if battle == null:
		return false
	var saved_party := _party(QA_PARTY)
	var saved_slots: Array = saved_party.get("slots", [])
	for index: int in range(PARTY_IDS.size()):
		_eq(str(saved_slots[index]), PARTY_IDS[index], "saved party slot %d" % index)
	_eq(str(_data().get("active_party", "")), QA_PARTY, "active party persisted on launch")

	var manager: RefCounted = battle.get("manager") as RefCounted
	_ok(manager != null, "battle manager created")
	if manager == null:
		return false
	var battle_state: RefCounted = manager.get("state") as RefCounted
	var party_combatants: Array = battle_state.get("party")
	var combatant_ids: Array[String] = []
	for combatant: RefCounted in party_combatants:
		combatant_ids.append(str(combatant.get("id")))
	for expected: String in PARTY_IDS:
		_ok(combatant_ids.has(expected), "battle uses selected party unit %s" % expected)

	_ok(InputMap.has_action("battle_abilities"), "battle abilities InputMap action exists")
	var key_event := InputEventAction.new()
	key_event.action = "battle_abilities"
	key_event.pressed = true
	battle.call("_unhandled_input", key_event)
	_ok(bool((battle.get("_ability_scroll") as Control).visible), "keyboard action opens ability grid")
	_ok((battle.get("_ability_grid") as Node).get_child_count() > 0, "ability grid populated")

	var first_combatant: RefCounted = ((battle.get("_party_cards") as Array)[0] as Dictionary).get("combatant") as RefCounted
	var basic_attack := str(first_combatant.get("basic_attack"))
	battle.call("_choose_action", basic_attack, "ability")
	_ok(not (battle.get("_pending_target") as Dictionary).is_empty(), "ability choice requests a target")
	var enemy_cards: Array = []
	for card: Dictionary in (battle.get("_enemy_cards") as Array):
		if card.get("combatant") != null and card.get("button") != null:
			enemy_cards.append(card)
	_ok(enemy_cards.size() > 0, "synthetic enemies present")
	if enemy_cards.is_empty():
		return false
	(enemy_cards[0] as Dictionary).get("button").pressed.emit()
	_eq(int(manager.call("summary").get("queue_size", 0)), 1, "enemy button queues ability")

	for enemy: RefCounted in (battle_state.get("enemies") as Array):
		enemy.set("hp", 1)
	for enemy_index: int in range(1, enemy_cards.size()):
		var party_cards: Array = battle.get("_party_cards")
		var card_index := enemy_index % party_cards.size()
		battle.call("_on_character_pressed", card_index)
		var actor: RefCounted = (party_cards[card_index] as Dictionary).get("combatant") as RefCounted
		var action_id := str(actor.get("basic_attack"))
		var target_id := str((battle_state.get("enemies")[enemy_index] as RefCounted).get("id"))
		battle.call("_submit_action", action_id, "ability", target_id)
	_eq(int(manager.call("summary").get("queue_size", 0)), enemy_cards.size(), "all enemies targeted")

	if not _press(battle, _t("battle.command_execute")):
		return false
	var ticks := 0
	while battle_state.get("result") == null and ticks < 3000:
		battle.call("_on_tick")
		ticks += 1
	_ok(ticks < 3000, "battle reaches a result")
	var result_variant: Variant = battle_state.get("result")
	if result_variant == null:
		return false
	var result: RefCounted = result_variant as RefCounted
	var result_dict: Dictionary = result.call("to_dict")
	_ok(bool(result_dict.get("victory", false)), "battle completes in victory")
	_ok(bool((battle.get("_result_overlay") as Control).visible), "result overlay shown")
	var result_snapshot: Dictionary = battle.get("_result_snapshot")
	var reward_key := str(state.call("battle_reward_key", result_snapshot))
	_ok(((_data().get("claimed_rewards", {}) as Dictionary).has(reward_key)), "victory reward marked claimed")
	_ok(int(state.call("get_resource", "gil")) > gil_before, "victory gil credited")
	var progress: Dictionary = saves.call("load_battle_progress")
	var progress_data: Dictionary = progress.get("progress", {})
	_ok(int((progress_data.get("clears", {}) as Dictionary).get("encounter:GL:950001@skirmish", 0)) > 0,
		"battle clear written to SaveManager progress")
	_eq(str((progress_data.get("last_result", {}) as Dictionary).get("encounter_id", "")),
		"encounter:GL:950001@skirmish", "last battle result persisted")

	var reopened: Dictionary = state.call("load_state")
	_ok(not reopened.is_empty(), "PlayerState reload path returns state")
	_eq(int((reopened.get("resources", {}) as Dictionary).get("gil", 0)),
		int(state.call("get_resource", "gil")), "reloaded gil matches persisted reward")
	_ok(((reopened.get("claimed_rewards", {}) as Dictionary).has(reward_key)), "reloaded save keeps reward idempotency key")
	_eq(int((reopened.get("owned_units", []) as Array).size()), 6, "reloaded save keeps synthetic units")
	state.set("data", reopened)
	state.call("rebuild_systems")

	var result_menu := (battle.get("_result_overlay") as Control).find_child("SecondaryButton", true, false) as Button
	_ok(result_menu != null, "result overlay menu control present")
	if result_menu != null:
		result_menu.pressed.emit()
		var menu := await _wait_for_scene(MENU_PATH, 60)
		_ok(menu != null, "result overlay returns to main menu")
	return true


# --- migration and save-slot checks --------------------------------------------

func test_save_migration_and_refusal() -> bool:
	var v1_slot := _read_json_dict("res://data/save_fixtures/v1_save_slot_0.json")
	_ok(not v1_slot.is_empty(), "v1 slot fixture readable")
	var migrated_v2: Dictionary = saves.call("migrate_to_current", v1_slot)
	_eq(int(migrated_v2.get("version", 0)), 2, "SaveManager migrates v1 slot to v2")
	_ok(bool(saves.call("validate_state", migrated_v2)), "migrated v2 slot validates")
	var migrated_profile: Dictionary = migrated_v2.get("profile", {})
	_ok(str(migrated_profile.get("selected_unit_id", "")).begins_with("unit:"),
		"v1 selected unit renamed into v2 profile")

	var v2_player := _read_json_dict("res://data/save_fixtures/v2_player_state.json")
	_ok(not v2_player.is_empty(), "v2 player fixture readable")
	var migrated_v3: Dictionary = state.call("migrate_state", v2_player)
	_eq(int(migrated_v3.get("version", 0)), 3, "PlayerState migrates v2 fixture to v3")
	var legacy: Dictionary = migrated_v3.get("legacy", {})
	_ok(legacy.has("battle_progress") and legacy.has("settings_summary"), "v2 metadata preserved in v3 legacy")
	var v1_player := {
		"version": 1,
		"selected_unit": V1,
		"profile": {"locale": "vi", "favorites": [V1], "last_unit_id": V1},
		"battle_progress": {"attempts": 1}
	}
	var migrated_chain: Dictionary = state.call("migrate_state", v1_player)
	_eq(int(migrated_chain.get("version", 0)), 3, "PlayerState migrates v1 through v2 to v3")
	_ok(((migrated_chain.get("profile", {}) as Dictionary).get("favorites", []) as Array).has(V1),
		"v1 favorites survive chained migration")

	var future_save := {"version": 12, "profile": {"selected_unit_id": V1, "favorites": []}}
	_ok((saves.call("migrate_to_current", future_save) as Dictionary).is_empty(), "SaveManager refuses newer save")
	var future_player := {"version": 4, "profile": {"locale": "en", "favorites": [], "last_unit_id": V1}}
	_ok((state.call("migrate_state", future_player) as Dictionary).is_empty(), "PlayerState refuses newer save")
	_eq(str(state.get("last_error")), "save.error.newer", "newer-save refusal reports stable error")

	var slot_state: Dictionary = saves.call("build_viewer_state", V1, [V1, V2])
	_eq(int(saves.call("save_slot", 0, slot_state)), OK, "QA save slot written")
	var loaded_slot: Dictionary = saves.call("load_slot", 0)
	var loaded_profile: Dictionary = loaded_slot.get("profile", {})
	_eq(str(loaded_profile.get("selected_unit_id", "")), V1, "QA save slot reloads selected unit")
	_eq((loaded_profile.get("favorites", []) as Array).size(), 2, "QA save slot reloads favorites")
	return true
