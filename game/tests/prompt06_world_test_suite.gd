class_name Prompt06WorldTestSuite
extends RefCounted

## Prompt 06 synthetic world, exploration, dialogue, quest and persistence suite.
##
## Every record is project-authored SYNTHETIC_FIXTURE / REMASTERED_DESIGN. The
## suite restores PlayerState data, user:// files, environment variables and
## locale, and never depends on the owner's real save.

const PLAYER_STATE_PATH := "user://player_state_v3.json"
const BATTLE_PROGRESS_PATH := "user://battle_progress.json"
const SETTINGS_PATH := "user://settings.json"

const REGION := "region:GL:1001@vale"
const HAVEN := "loc:GL:1101@haven"
const MEADOW := "loc:GL:1102@meadow"
const SPIRE := "loc:GL:1103@spire"
const KEEPER := "npc:GL:2101@keeper"
const SCOUT := "npc:GL:2102@scout"
const CHEST := "treasure:GL:4101@meadow"
const MEADOW_TRIGGER := "encounter_trigger:GL:5101@meadow"
const SPIRE_TRIGGER := "encounter_trigger:GL:5102@spire"
const OATH := "quest:GL:3100@oath"
const LANTERN := "quest:GL:3101@lantern"
const SKIRMISH := "encounter:GL:950001@skirmish"
const BOSS := "encounter:GL:950002@boss"
const FRAGMENT := "fragment:GL:910101@base"
const REWARD_ITEM := "item:GL:940001@base"

const WORLD_MAP_SCENE := "res://scenes/world/world_map.tscn"
const EXPLORATION_SCENE := "res://scenes/world/exploration_area.tscn"
const DIALOGUE_SCENE := "res://scenes/world/dialogue_panel.tscn"
const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"

var runner: Object = null
var tree: SceneTree = null
var state: Node = null
var saves: Node = null
var repository: Node = null
var locations: WorldLocationRepository = null
var world: WorldStateService = null
var quests: QuestManager = null
var dialogue: DialogueManager = null
var interaction: InteractionController = null
var _original_data: Dictionary = {}
var _original_last_error: String = ""
var _original_save_status: String = "NORMAL"
var _original_locale: String = ""
var _original_files: Dictionary = {}
var _original_env: Dictionary = {}


## Test-only quest definition with a two-win objective. It is never written to
## the content repository; settlement accepts it through the optional seam so a
## duplicate run can be proven to advance nothing.
class MultiVictoryQuestRepository extends QuestRepository:
	const MULTI_ID := "quest:GL:9999@multi_victory"
	const OBJECTIVE_ID := "objective:GL:999901@two_wins"
	const TARGET := "encounter:GL:950001@skirmish"

	func get_quest_ids() -> Array[String]:
		return [MULTI_ID]

	func get_quest(id: String) -> Dictionary:
		if id != MULTI_ID:
			return {}
		return {
			"id": MULTI_ID,
			"rewards": {"gil": 77, "items": []},
			"unlocks": []
		}

	func get_objectives(id: String) -> Array[Dictionary]:
		if id != MULTI_ID:
			return []
		return [{
			"id": OBJECTIVE_ID, "type": "defeat_encounter",
			"target": TARGET, "count": 2
		}]


func _init(p_runner: Object = null) -> void:
	runner = p_runner
	tree = p_runner as SceneTree
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree != null:
		state = tree.root.get_node_or_null("PlayerState")
		saves = tree.root.get_node_or_null("SaveManager")
		repository = tree.root.get_node_or_null("ContentRepository")


func run() -> bool:
	if runner == null or tree == null or state == null or saves == null or repository == null:
		_ok(false, "prompt06 suite services available")
		return false
	await tree.process_frame
	if not bool(repository.get("loaded")):
		repository.call("load_content")

	_original_data = _data().duplicate(true)
	_original_last_error = str(state.get("last_error"))
	_original_save_status = str(state.get("save_status"))
	_original_files = _snapshot_files()
	_original_env = _snapshot_environment()
	var locale_node: Node = tree.root.get_node_or_null("LocaleManager")
	_original_locale = str(locale_node.get("current_locale")) if locale_node != null else "vi"

	locations = WorldLocationRepository.new(repository)
	world = WorldStateService.new(state)
	quests = QuestManager.new()
	quests.configure(state, QuestRepository.new(repository), world)
	dialogue = DialogueManager.new()
	dialogue.configure(DialogueRepository.new(repository), world, quests)
	interaction = InteractionController.new(state, locations, world, quests)

	_run("test_catalog_gate")
	_run("test_world_state_defaults")
	_run("test_migration_backup_and_newer_refusal")
	_run("test_version_matrix_normalization")
	_run("test_write_rollback")
	_run("test_location_gating")
	_run("test_dialogue_flow")
	_run("test_treasure_one_time")
	_run("test_quest_lifecycle_and_idempotence")
	_run("test_exploration_controller")
	_run("test_battle_context_and_rewards")
	_run("test_fault_injection_scenarios")
	_run("test_duplicate_settlement_and_pending_recovery")
	_run("test_scene_smoke")

	_restore_files()
	_restore_environment()
	state.set("data", _original_data)
	state.set("last_error", _original_last_error)
	state.call("set_save_status", _original_save_status, "")
	state.call("clear_pending_battle_result")
	saves.call("clear_write_failure")
	saves.call("clear_migration_backup_failure")
	if locale_node != null:
		locale_node.call("set_locale", _original_locale, false)
	WorldContext.clear()
	return _failures == 0


var _failures: int = 0


func _run(test_name: String) -> void:
	_failures_before = _failures
	if call(test_name) != true:
		_failures += 1
		_ok(false, "prompt06 %s did not finish" % test_name)


var _failures_before: int = 0


# --- assertions -----------------------------------------------------------------

func _ok(condition: bool, label: String) -> void:
	if runner == null:
		if not condition:
			_failures += 1
			push_error("FAIL %s: expected true" % label)
		return
	runner.call("assert_true", condition, label)


func _no(condition: bool, label: String) -> void:
	_ok(not condition, label)


func _eq(actual: Variant, expected: Variant, label: String) -> void:
	if runner == null:
		if actual != expected:
			_failures += 1
			push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])
		return
	runner.call("assert_eq", actual, expected, label)


# --- environment, files and state ------------------------------------------------

func _snapshot_environment() -> Dictionary:
	var result: Dictionary = {}
	for key: String in ["FFBE_QA_MODE", "FFBE_QA_ENCOUNTER", "FFBE_QA_SCENARIO"]:
		result[key] = OS.get_environment(key)
		OS.set_environment(key, "")
	return result


func _restore_environment() -> void:
	for key: String in _original_env.keys():
		OS.set_environment(key, str(_original_env[key]))


func _managed_paths() -> Array[String]:
	var paths: Array[String] = [PLAYER_STATE_PATH, BATTLE_PROGRESS_PATH, SETTINGS_PATH]
	for slot: int in range(3):
		paths.append("user://save_slot_%d.json" % slot)
	return paths


func _snapshot_files() -> Dictionary:
	var result: Dictionary = {}
	for base: String in _managed_paths():
		for suffix: String in ["", ".bak", ".tmp", ".mig.bak"]:
			var path: String = base + suffix
			var exists: bool = FileAccess.file_exists(path)
			result[path] = {
				"exists": exists,
				"text": FileAccess.get_file_as_string(path) if exists else ""
			}
	return result


func _restore_files() -> void:
	for path: String in _snapshot_files().keys():
		_remove_file(path)
	for path: String in _original_files.keys():
		var record: Dictionary = _original_files[path]
		if not bool(record.get("exists", false)):
			continue
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(str(record.get("text", "")))
			file.close()


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _write_file(path: String, text: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var written: bool = file.store_string(text)
	file.close()
	return written


func _write_json(path: String, payload: Dictionary) -> bool:
	return _write_file(path, JSON.stringify(payload))


func _read_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	var error: Error = parser.parse(file.get_as_text())
	file.close()
	if error != OK or not parser.data is Dictionary:
		return {}
	return parser.data


func _data() -> Dictionary:
	var value: Variant = state.get("data") if state != null else null
	return value if value is Dictionary else {}


func _fresh() -> void:
	# Isolate each test from a previous fault-injection save and unlock the in-memory
	# profile explicitly. A future-version fixture is removed inside this isolated
	# test profile before any further settlement is attempted.
	for suffix: String in ["", ".bak", ".tmp", ".mig.bak"]:
		_remove_file(PLAYER_STATE_PATH + suffix)
	state.set("data", state.call("default_state", 0))
	state.set("last_error", "")
	state.call("set_save_status", "NORMAL", "")
	state.call("clear_pending_battle_result")
	saves.call("clear_write_failure")
	saves.call("clear_migration_backup_failure")


func _battle_payload(encounter_id: String, victory: bool, run_id: String) -> Dictionary:
	return {
		"encounter_id": encounter_id,
		"encounter_name": "Synthetic encounter",
		"victory": victory,
		"outcome": "victory" if victory else "defeat",
		"turns": 3,
		"seed": 42,
		"run_id": run_id,
		"rewards": {
			"repeat": {"gil": 100, "items": [REWARD_ITEM]},
			"first_clear": {"gil": 50, "items": []},
			"missions": []
		}
	}


func _make_battle(context: Dictionary) -> Control:
	var packed: PackedScene = load(BATTLE_SCENE) as PackedScene
	var battle: Control = packed.instantiate() as Control
	battle.set("_world_context", context.duplicate(true))
	battle.set("_return_scene_path", EXPLORATION_SCENE)
	return battle


func _record_battle(battle: Control, payload: Dictionary) -> Dictionary:
	var result := BattleResult.new()
	result.encounter_id = str(payload.get("encounter_id", ""))
	result.encounter_name = str(payload.get("encounter_name", ""))
	result.victory = bool(payload.get("victory", false))
	result.outcome = str(payload.get("outcome", ""))
	result.turns = int(payload.get("turns", 0))
	result.seed = int(payload.get("seed", 0))
	result.run_id = str(payload.get("run_id", ""))
	result.rewards = (payload.get("rewards", {}) as Dictionary).duplicate(true)
	var battle_state := BattleState.new()
	battle_state.result = result
	battle.call("_record_result", battle_state)
	return battle.call("_world_return_context")


func _make_battle_in_tree(context: Dictionary) -> Control:
	var packed: PackedScene = load(BATTLE_SCENE) as PackedScene
	var battle: Control = packed.instantiate() as Control
	tree.root.add_child(battle)
	# Set after _ready() so WorldContext.consume() cannot overwrite the fixture.
	battle.set("_world_context", context.duplicate(true))
	battle.set("_return_scene_path", EXPLORATION_SCENE)
	return battle


func _fingerprint() -> String:
	var parser := JSON.new()
	var text: String = JSON.stringify(_data())
	if parser.parse(text) == OK:
		return JSON.stringify(parser.data)
	return text


func _resource(key: String) -> int:
	return int(state.call("get_resource", key))


func _quest_progress(quest_id: String, objective_id: String) -> int:
	var world_variant: Variant = _data().get("world", {})
	if not world_variant is Dictionary:
		return 0
	var quests_variant: Variant = (world_variant as Dictionary).get("quests", {})
	if not quests_variant is Dictionary:
		return 0
	var record_variant: Variant = (quests_variant as Dictionary).get(quest_id, {})
	if not record_variant is Dictionary:
		return 0
	var progress_variant: Variant = (record_variant as Dictionary).get("progress", {})
	if not progress_variant is Dictionary:
		return 0
	return int((progress_variant as Dictionary).get(objective_id, 0))


# --- tests ----------------------------------------------------------------------

func test_catalog_gate() -> bool:
	var summary: Dictionary = repository.call("summary")
	_eq(str(summary.get("fixture_marker", "")), "SYNTHETIC_FIXTURE", "world fixture marker")
	_eq(str(summary.get("rights_gate", "")), "not_passed", "world rights gate")
	_eq(int(summary.get("world_region_count", 0)), 1, "region count")
	_eq(int(summary.get("world_location_count", 0)), 3, "location count")
	_eq(int(summary.get("world_connection_count", 0)), 2, "connection count")
	_eq(int(summary.get("world_interactable_count", 0)), 9, "interactable count")
	_eq(int(summary.get("world_dialogue_count", 0)), 2, "dialogue count")
	_eq(int(summary.get("world_quest_count", 0)), 2, "quest count")

	for path: String in [
		"res://data/world/regions.json", "res://data/world/locations.json",
		"res://data/world/location_connections.json", "res://data/world/interactables.json",
		"res://data/world/dialogues.json", "res://data/world/quests.json"
	]:
		var pack: Dictionary = _read_json(path)
		_eq(str(pack.get("fixture_marker", "")), "SYNTHETIC_FIXTURE", "%s marker" % path)
		var policy: Dictionary = pack.get("policy", {})
		_eq(str(policy.get("rights_gate", "")), "not_passed", "%s rights gate" % path)
		_no(bool(policy.get("source_data_imported", true)), "%s imports no source data" % path)

	for id: String in [REGION, HAVEN, MEADOW, SPIRE, KEEPER, SCOUT, CHEST, MEADOW_TRIGGER, SPIRE_TRIGGER, OATH, LANTERN]:
		var parsed: Variant = repository.call("parse_composite_id", id)
		_ok(parsed != null and bool(parsed.call("is_valid")), "canonical world ID %s" % id)
		_eq(str(parsed.call("as_text")), id, "world ID round trip %s" % id)
		_ok(str(parsed.get("region")) == "GL", "world ID region %s" % id)
	return true


func test_world_state_defaults() -> bool:
	var defaults: Dictionary = state.call("default_world_state")
	_eq(int(defaults.get("version", 0)), 1, "world state version")
	_eq(str(defaults.get("current_region", "")), REGION, "default region")
	_eq(str(defaults.get("current_location", "")), HAVEN, "default location")
	_eq((defaults.get("discovered_locations", []) as Array).size(), 1, "default discovered count")
	_eq((defaults.get("unlocked_locations", []) as Array).size(), 1, "default unlocked count")
	_fresh()
	_ok(bool(state.call("validate_state", _data())), "default state validates with world")
	var stripped: Dictionary = _data().duplicate(true)
	stripped.erase("world")
	_no(bool(state.call("validate_state", stripped)), "missing world fails validation")
	return true


func test_migration_backup_and_newer_refusal() -> bool:
	_fresh()
	var legacy: Dictionary = _data().duplicate(true)
	legacy.erase("world")
	legacy["version"] = 3
	(legacy["resources"] as Dictionary)["material:GL:900101@base"] = 987
	_ok(_write_json(PLAYER_STATE_PATH, legacy), "legacy save written")
	_remove_file(PLAYER_STATE_PATH + ".mig.bak")

	var migrated: Dictionary = state.call("load_state", 0)
	state.set("data", migrated)
	_eq(int((migrated.get("world", {}) as Dictionary).get("version", 0)), 1, "world section backfilled")
	_eq(_resource("material:GL:900101@base"), 987, "legacy resources preserved")
	_ok(FileAccess.file_exists(PLAYER_STATE_PATH + ".mig.bak"), "migration backup created")
	var backup_text: String = FileAccess.get_file_as_string(PLAYER_STATE_PATH + ".mig.bak")
	_no(backup_text.contains("\"world\""), "backup is pre-migration snapshot")

	var future: Dictionary = legacy.duplicate(true)
	future["version"] = 999
	future["resources"]["material:GL:900101@base"] = 123
	_ok(_write_json(PLAYER_STATE_PATH, future), "future save written")
	var before_error: String = str(state.get("last_error"))
	var refusal: Dictionary = state.call("load_state", 0)
	_eq(str(state.get("last_error")), "save.error.newer", "newer save refused")
	_eq(int((refusal.get("resources", {}) as Dictionary).get("material:GL:900101@base", 0)), 120, "future save not loaded")
	state.set("last_error", before_error)
	return true


func test_version_matrix_normalization() -> bool:
	_fresh()
	state.set("last_error", "")
	for source_version: int in [1, 2, 3, 4]:
		var raw: Dictionary = _data().duplicate(true)
		raw["version"] = source_version
		raw.erase("world")
		if source_version < 4:
			for section: String in [
				"reward_claims", "mission_progress", "battle_runs", "espers",
				"summon", "economy", "shops", "crafting"
			]:
				raw.erase(section)
		(raw["resources"] as Dictionary)["material:GL:900101@base"] = 700 + source_version
		var migrated: Dictionary = state.call("migrate_state", raw, 100)
		var world_section: Dictionary = migrated.get("world", {})
		_eq(int(migrated.get("version", 0)), 4, "v%d reaches v4" % source_version)
		_eq(int(world_section.get("version", 0)), 1, "v%d world section normalized" % source_version)
		_eq(str(world_section.get("current_location", "")), HAVEN, "v%d keeps starting location" % source_version)
		_eq(int((migrated["resources"] as Dictionary).get("material:GL:900101@base", 0)), 700 + source_version, "v%d preserves resources" % source_version)
		_ok(bool(state.call("validate_state", migrated)), "v%d migrated state validates" % source_version)
	return true


func test_write_rollback() -> bool:
	_fresh()
	var before: String = _fingerprint()
	saves.call("fail_next_atomic_write")
	var result: bool = world.set_flag("rollback_test", true)
	_no(result, "failed commit reports failure")
	_eq(_fingerprint(), before, "failed commit restores complete state")
	saves.call("clear_write_failure")
	_ok(world.set_flag("rollback_test", true), "write succeeds after failure cleared")
	return true


func test_location_gating() -> bool:
	_fresh()
	_no(locations.meets_requirements(MEADOW, world.state()), "meadow starts locked")
	_ok(locations.meets_requirements(HAVEN, world.state()), "haven starts unlocked")
	_ok(locations.has_connection(HAVEN, MEADOW), "haven-meadow edge exists")
	_ok(locations.connection_requirement(HAVEN, MEADOW).has("location_id"), "edge requirement present")
	_no(locations.can_travel(HAVEN, SPIRE, world.state()), "no direct haven-spire route")
	_ok(world.unlock_location(MEADOW), "meadow unlock committed")
	_ok(locations.meets_requirements(MEADOW, world.state()), "meadow unlocked after state write")
	_ok(locations.can_travel(HAVEN, MEADOW, world.state()), "travel allowed after unlock")
	_no(locations.validate_reference("loc:ZZ:9999@fake"), "invalid region identity rejected")
	_no(locations.validate_reference("quest:GL:3100@oath", "location"), "wrong kind rejected")
	return true


func test_dialogue_flow() -> bool:
	_fresh()
	var page: Dictionary = dialogue.start("dialogue:GL:2101@keeper")
	_ok(bool(page.get("ok", false)), "keeper dialogue starts")
	_eq(str(page.get("speaker_key", "")), "world.npc.keeper.name", "keeper speaker key")
	_eq(int(page.get("page_count", 0)), 2, "keeper has two pages")
	page = dialogue.advance()
	_eq(str(page.get("line_key", "")), "dialogue.keeper.line2", "keeper second page")
	page = dialogue.advance()
	_ok(bool(page.get("awaiting_choice", false)), "keeper awaits choice")
	_eq((page.get("choices", []) as Array).size(), 2, "keeper offers two choices")
	var chosen: Dictionary = dialogue.choose("accept_oath")
	_ok(bool(chosen.get("ok", false)), "keeper choice applied")
	_ok(world.get_flag("keeper_intro"), "dialogue flag persisted")
	_eq(quests.status(OATH), "completed", "accepting oath completes talk objective")
	_ok(world.is_unlocked(MEADOW), "dialogue unlocks meadow")
	_eq(_resource(REWARD_ITEM), 1, "oath reward granted once")

	var scout_page: Dictionary = dialogue.start("dialogue:GL:2102@scout")
	_eq(str(scout_page.get("line_key", "")), "dialogue.scout.intro", "scout conditional intro")
	scout_page = dialogue.advance()
	_ok(bool(scout_page.get("awaiting_choice", false)), "scout choices available after pages")
	var scout_choice: Dictionary = dialogue.choose("accept_lantern")
	_ok(bool(scout_choice.get("ok", false)), "scout choice applied")
	_ok(quests.status(LANTERN) == "active", "scout choice accepts lantern")
	_eq(str(dialogue.current().get("line_key", "")), "dialogue.scout.line2", "conditional follow-up line")
	_ok(bool(dialogue.close().get("ok", false)), "dialogue closes")
	return true


func test_treasure_one_time() -> bool:
	_fresh()
	_ok(interaction.configure_area(MEADOW), "meadow interaction area configured")
	var gil_before: int = _resource("gil")
	var first: Dictionary = interaction.resolve_by_id(CHEST)
	_ok(bool(first.get("ok", false)), "chest opens once")
	_eq(str(first.get("action", "")), "treasure", "chest resolves as treasure")
	_ok(world.was_treasure_opened(CHEST), "opened chest persisted")
	_eq(_resource(FRAGMENT), 1, "chest fragment granted")
	_eq(_resource("gil"), gil_before + 150, "chest gil granted once")
	var second: Dictionary = interaction.resolve_by_id(CHEST)
	_no(bool(second.get("ok", false)), "one-time chest cannot open again")
	_eq(str(second.get("reason", "")), "already_claimed", "duplicate chest rejected by claim key")
	_eq(_resource("gil"), gil_before + 150, "duplicate chest grants no gil")
	return true


func test_quest_lifecycle_and_idempotence() -> bool:
	_fresh()
	var accepted_oath: Dictionary = quests.accept(OATH)
	_ok(bool(accepted_oath.get("ok", false)), "oath accepted")
	var recorded: Dictionary = quests.record_event({"type": "talk_to", "target": KEEPER, "count": 1})
	_ok(bool(recorded.get("ok", false)), "oath objective recorded")
	_eq(quests.status(OATH), "completed", "oath completed")
	_ok((recorded.get("completed", []) as Array).has(OATH), "completion reported")
	var gil_after_oath: int = _resource("gil")
	quests.record_event({"type": "talk_to", "target": KEEPER, "count": 1})
	_eq(_resource("gil"), gil_after_oath, "duplicate objective grants no reward")

	var accepted_lantern: Dictionary = quests.accept(LANTERN)
	_ok(bool(accepted_lantern.get("ok", false)), "lantern accepted after oath")
	for event: Dictionary in [
		{"type": "talk_to", "target": SCOUT, "count": 1},
		{"type": "visit_location", "target": MEADOW, "count": 1},
		{"type": "complete_quest", "target": OATH, "count": 1}
	]:
		_ok(bool(quests.record_event(event).get("ok", false)), "lantern event recorded")
	_ok(interaction.configure_area(MEADOW), "meadow configured for chest objective")
	_ok(bool(interaction.resolve_by_id(CHEST).get("ok", false)), "chest objective opened")
	quests.record_event({"type": "collect", "target": FRAGMENT, "count": 1})
	var battle_progress: Dictionary = quests.record_event({
		"type": "defeat_encounter", "target": SKIRMISH, "count": 1
	})
	_ok(bool(battle_progress.get("ok", false)), "battle objective recorded")
	_eq(quests.status(LANTERN), "completed", "lantern completed")
	_ok(world.is_unlocked(SPIRE), "lantern unlocks spire")
	var claims: Dictionary = (_data().get("reward_claims", {}) as Dictionary)
	_ok(claims.has("world|quest|%s" % OATH), "oath claim key recorded")
	_ok(claims.has("world|quest|%s" % LANTERN), "lantern claim key recorded")
	_eq(_resource(REWARD_ITEM), 3, "quest rewards granted once each")
	var gil_after_lantern: int = _resource("gil")
	quests.record_event({"type": "defeat_encounter", "target": SKIRMISH, "count": 1})
	_eq(_resource("gil"), gil_after_lantern, "completed quest cannot be rewarded twice")
	_eq(quests.journal().size(), 2, "journal lists both quests")
	return true


func test_exploration_controller() -> bool:
	var movement := ExplorationController.new()
	movement.configure(Vector2(100, 100), Rect2(0, 0, 320, 240), [Rect2(150, 60, 60, 80)])
	_no(movement.can_occupy(Vector2(160, 100)), "obstacle rejects position")
	_ok(movement.can_occupy(Vector2(100, 100)), "open position accepted")
	movement.speed = 100.0
	movement.move(0.1, Vector2.RIGHT)
	_eq(movement.position.x, 110.0, "keyboard movement applies")
	movement.move(1.0, Vector2.RIGHT)
	_eq(movement.position.x, 110.0, "obstacle blocks movement")
	movement.set_move_target(Vector2(9999, 9999))
	_ok(movement.is_finite_vector(movement.move_target), "mouse target clamped to finite bounds")
	_no(movement.can_occupy(Vector2(-50, 100)), "left boundary blocks position")

	_fresh()
	_ok(interaction.configure_area(HAVEN), "haven configured for interaction")
	var nearby: Dictionary = interaction.nearest(Vector2(300, 430))
	_eq(str(nearby.get("id", "")), KEEPER, "nearest NPC resolved by position")
	_ok(interaction.nearest(Vector2(10, 10)).is_empty(), "no interaction out of range")
	return true


func test_battle_context_and_rewards() -> bool:
	_fresh()
	WorldContext.clear()
	WorldContext.write({
		"encounter_id": BOSS,
		"location_id": SPIRE,
		"return_scene": EXPLORATION_SCENE,
		"trigger_id": SPIRE_TRIGGER
	})
	var context: Dictionary = WorldContext.peek()
	_eq(str(context.get("encounter_id", "")), BOSS, "world context carries encounter")
	_eq(str(context.get("trigger_id", "")), SPIRE_TRIGGER, "world context carries trigger")
	WorldContext.clear()
	_ok(WorldContext.peek().is_empty(), "world context consumed")

	var packed: PackedScene = load(BATTLE_SCENE) as PackedScene
	_ok(packed != null, "battle scene loads")
	if packed == null:
		return true
	var battle: Control = packed.instantiate() as Control
	battle.set("_world_context", context)
	battle.set("_return_scene_path", EXPLORATION_SCENE)
	var result := BattleResult.new()
	result.encounter_id = BOSS
	result.encounter_name = "Synthetic boss"
	result.victory = true
	result.outcome = "victory"
	result.turns = 3
	result.seed = 42
	result.run_id = "prompt06-run-1"
	result.rewards = {"gil": 500, "items": [REWARD_ITEM]}
	var battle_state := BattleState.new()
	battle_state.result = result
	battle.call("_record_result", battle_state)
	var payload: Dictionary = battle.call("_world_return_context")
	_ok(not payload.is_empty(), "battle prepares world return payload")
	_eq(str(payload.get("return_scene", "")), EXPLORATION_SCENE, "battle returns to exploration")
	var carried: Dictionary = payload.get("battle_result", {})
	_eq(str(carried.get("encounter_id", "")), BOSS, "result preserves encounter identity")
	_ok(bool(carried.get("victory", false)), "result preserves victory")
	_eq(str(carried.get("run_id", "")), "prompt06-run-1", "result preserves run identity")
	battle.free()

	var gil_after_battle: int = _resource("gil")
	var duplicate_claim: Dictionary = state.call("claim_battle_reward", carried)
	_no(bool(duplicate_claim.get("ok", false)), "same run cannot claim twice")
	_eq(str(duplicate_claim.get("reason", "")), "already_claimed", "duplicate claim reason")
	_eq(_resource("gil"), gil_after_battle, "duplicate claim grants no gil")
	var retry: Dictionary = carried.duplicate(true)
	retry["run_id"] = "prompt06-run-2"
	var retry_claim: Dictionary = state.call("claim_battle_reward", retry)
	# A world one-time boss is keyed by encounter identity, not attempt identity.
	_no(bool(retry_claim.get("ok", false)), "one-time boss cannot be farmed by a new run")
	_eq(str(retry_claim.get("reason", "")), "already_claimed", "one-time boss retry reason")

	_fresh()
	var defeat_result: Dictionary = carried.duplicate(true)
	defeat_result["victory"] = false
	defeat_result["run_id"] = "prompt06-defeat"
	_no(bool(state.call("claim_battle_reward", defeat_result).get("ok", false)), "defeat grants no battle reward")
	_ok(bool(quests.accept(OATH).get("ok", false)), "oath active before defeat")
	var progress_before: Dictionary = quests.progress(OATH)
	var handled: Dictionary = interaction.on_battle_result({
		"encounter_id": SKIRMISH, "trigger_id": MEADOW_TRIGGER
	}, defeat_result)
	_eq(str(handled.get("reason", "")), "defeat", "defeat is reported")
	_eq(quests.status(OATH), "active", "defeat does not complete quest")
	_eq(JSON.stringify(quests.progress(OATH)), JSON.stringify(progress_before), "defeat does not advance objectives")
	return true


func test_fault_injection_scenarios() -> bool:
	# --- Future save load -----------------------------------------------------
	_fresh()
	var future: Dictionary = _data().duplicate(true)
	future["version"] = 999
	var future_text: String = JSON.stringify(future)
	_ok(_write_file(PLAYER_STATE_PATH, future_text), "future fixture written")
	var loaded: Dictionary = state.call("load_state", 0)
	_eq(str(state.get("save_status")), "READ_ONLY_FUTURE_VERSION", "Future save load locks profile")
	_eq(str(state.get("last_error")), "save.error.newer", "Future save load reports stable error")
	_eq(FileAccess.get_file_as_string(PLAYER_STATE_PATH), future_text, "Future save bytes unchanged after load")
	_no(FileAccess.file_exists(PLAYER_STATE_PATH + ".mig.bak"), "future save creates no migration backup")
	_no(FileAccess.file_exists(PLAYER_STATE_PATH + ".tmp"), "future save creates no temp file")
	_ok(bool(saves.call("is_path_read_only", PLAYER_STATE_PATH)), "future save path guarded in writer")
	_eq(int(loaded.get("version", 0)), 4, "future save not installed in memory")

	# --- Future save commit ---------------------------------------------------
	_no(int(state.call("save")) == OK, "Future save commit blocks save")
	_no(int(state.call("commit", "future")) == OK, "Future save commit blocks section commit")
	_no(int(state.call("reset_to_defaults")) == OK, "Future save commit blocks reset")
	_no(int(state.call("set_locale", "en")) == OK, "Future save commit blocks locale change")
	_no(bool(state.call("pay", {"gil": 1})), "Future save commit blocks spending")
	_ok((state.call("migrate_state", future) as Dictionary).is_empty(), "Future save commit blocks migration")
	_no(int(state.call("recover_from_load_failure")) == OK, "Future save recovery refuses newer bytes")
	_eq(str(state.get("save_status")), "READ_ONLY_FUTURE_VERSION", "Future save recovery keeps lock")

	# --- Future save reward ---------------------------------------------------
	var future_result: Dictionary = _battle_payload(BOSS, true, "fixture-future-run")
	var battle_claim: Dictionary = state.call("claim_battle_reward", future_result)
	_eq(str(battle_claim.get("reason", "")), "read_only", "Future save reward blocks battle claim")
	var world_claim: Dictionary = state.call("claim_world_reward", "treasure", CHEST, {"gil": 1})
	_eq(str(world_claim.get("reason", "")), "read_only", "Future save reward blocks world claim")
	var allow_mutation: Callable = func() -> Dictionary: return {"ok": true}
	var mutation: Dictionary = state.call("transact_world", "future", allow_mutation)
	_eq(str(mutation.get("reason", "")), "read_only", "Future save reward blocks staged mutation")
	_no(int(saves.call("atomic_write", PLAYER_STATE_PATH, {"version": 4})) == OK, "Future save reward blocks direct writer")
	_eq(FileAccess.get_file_as_string(PLAYER_STATE_PATH), future_text, "Future save bytes unchanged after all attempts")

	# --- Migration failure ----------------------------------------------------
	_fresh()
	var legacy: Dictionary = _data().duplicate(true)
	legacy.erase("world")
	legacy["version"] = 3
	var legacy_text: String = JSON.stringify(legacy)
	_ok(_write_file(PLAYER_STATE_PATH, legacy_text), "migration fixture written")
	saves.call("fail_next_migration_backup")
	var failed_migration: Dictionary = state.call("load_state", 0)
	_eq(str(state.get("save_status")), "LOAD_FAILED", "Migration failure locks profile")
	_eq(str(state.get("last_error")), "save.error.migration_backup", "Migration failure reports stable error")
	_eq(FileAccess.get_file_as_string(PLAYER_STATE_PATH), legacy_text, "Migration failure preserves source bytes")
	_no(int(state.call("commit", "migration")) == OK, "Migration failure blocks commit")
	_no(FileAccess.file_exists(PLAYER_STATE_PATH + ".mig.bak"), "Migration failure leaves no partial backup")
	_no(bool(failed_migration.get("world", {}).is_empty()), "Migration failure returns safe defaults")

	# --- Treasure commit failure ---------------------------------------------
	_fresh()
	_ok(interaction.configure_area(MEADOW), "meadow configured for treasure fault")
	var treasure_before: String = _fingerprint()
	saves.call("fail_next_atomic_write")
	var failed_treasure: Dictionary = interaction.resolve_by_id(CHEST)
	_no(bool(failed_treasure.get("ok", false)), "Treasure commit failure reported")
	_eq(str(failed_treasure.get("reason", "")), "save_failed", "Treasure commit failure reason")
	_eq(_fingerprint(), treasure_before, "Treasure commit failure rolls back entire action")
	_no(world.was_treasure_opened(CHEST), "Treasure commit failure does not mark opened")
	saves.call("clear_write_failure")
	_ok(bool(interaction.resolve_by_id(CHEST).get("ok", false)), "Treasure retry after write failure succeeds")

	# --- Battle settlement failure -------------------------------------------
	_fresh()
	var battle_context: Dictionary = {
		"encounter_id": BOSS, "location_id": SPIRE, "trigger_id": SPIRE_TRIGGER
	}
	var failed_battle: Control = _make_battle(battle_context)
	var battle_before: String = _fingerprint()
	saves.call("fail_next_atomic_write")
	_record_battle(failed_battle, _battle_payload(BOSS, true, "fixture-settlement-fail"))
	_eq(str(failed_battle.get("_reward_status_key")), "battle.reward_save_failed", "Battle settlement failure status key")
	_eq(_fingerprint(), battle_before, "Battle settlement failure rolls back reward and world state")
	_eq(str((state.call("get_pending_battle_result") as Dictionary).get("run_id", "")),
		"fixture-settlement-fail", "Battle settlement failure preserves pending result")
	failed_battle.free()
	saves.call("clear_write_failure")
	var settled_battle: Control = _make_battle(battle_context)
	var settled_payload: Dictionary = _record_battle(
		settled_battle, _battle_payload(BOSS, true, "fixture-settlement-retry")
	)
	_ok(bool(settled_payload.get("battle_result", {}).get("victory", false)), "Battle settlement retry succeeds")
	_ok((state.call("get_pending_battle_result") as Dictionary).is_empty(), "Successful settlement clears pending result")
	settled_battle.free()

	# --- Quest staging failure ------------------------------------------------
	_fresh()
	_ok(bool(quests.accept(OATH).get("ok", false)), "quest accepted before staging fault")
	var quest_before: String = _fingerprint()
	saves.call("fail_next_atomic_write")
	var failed_event: Dictionary = quests.record_event({"type": "talk_to", "target": KEEPER, "count": 1})
	_no(bool(failed_event.get("ok", false)), "Quest staging failure reported")
	_eq(str(failed_event.get("reason", "")), "save_failed", "Quest staging failure reason")
	_eq(_fingerprint(), quest_before, "Quest staging failure rolls back progress and rewards")
	saves.call("clear_write_failure")
	_ok(bool(quests.record_event({"type": "talk_to", "target": KEEPER, "count": 1}).get("ok", false)),
		"Quest staging retry after write failure succeeds")

	# --- Duplicate treasure event --------------------------------------------
	var gil_before_event: int = _resource("gil")
	var duplicate_treasure_event: Dictionary = quests.record_event({
		"type": "open_treasure", "target": CHEST, "count": 1
	})
	_ok(bool(duplicate_treasure_event.get("ok", false)), "Duplicate treasure event is accepted idempotently")
	_eq(_resource("gil"), gil_before_event, "Duplicate treasure event grants no extra currency")

	# --- Duplicate battle result ---------------------------------------------
	_fresh()
	var duplicate_battle: Control = _make_battle(battle_context)
	var duplicate_payload: Dictionary = _record_battle(
		duplicate_battle, _battle_payload(BOSS, true, "fixture-duplicate-run")
	)
	duplicate_battle.free()
	var settled_result: Dictionary = duplicate_payload.get("battle_result", {})
	var state_after_settle: String = _fingerprint()
	var first_return: Dictionary = interaction.on_battle_result(duplicate_payload, settled_result)
	var second_return: Dictionary = interaction.on_battle_result(duplicate_payload, settled_result)
	_ok(bool(first_return.get("settled", false)), "Duplicate battle result first return is a no-op settlement")
	_ok(bool(second_return.get("settled", false)), "Duplicate battle result second return is a no-op settlement")
	_eq(_fingerprint(), state_after_settle, "Duplicate battle result cannot change settled state")

	# --- Battle return after success ------------------------------------------
	var gil_after_battle: int = _resource("gil")
	var claims_after_battle: String = JSON.stringify(
		(_data().get("reward_claims", {}) as Dictionary)
	)
	var battle_return: Dictionary = interaction.on_battle_result(duplicate_payload, settled_result)
	_ok(bool(battle_return.get("progressed", false)), "Battle return after success reports victory")
	_eq(_resource("gil"), gil_after_battle, "Battle return after success grants no second reward")
	_eq(JSON.stringify((_data().get("reward_claims", {}) as Dictionary)), claims_after_battle,
		"Battle return after success preserves claim ledger")

	# --- One-time boss victory -------------------------------------------------
	_fresh()
	var victory_battle: Control = _make_battle(battle_context)
	var victory_payload: Dictionary = _record_battle(
		victory_battle, _battle_payload(BOSS, true, "fixture-boss-victory")
	)
	var claims: Dictionary = _data().get("reward_claims", {})
	_ok(claims.has("battle|once|%s" % BOSS), "One-time boss victory records stable encounter claim")
	_no(claims.has("battle|run|fixture-boss-victory"), "One-time boss victory never uses per-run claim")
	_ok(world.was_one_time_encounter_defeated(BOSS), "One-time boss victory records defeat flag during battle")
	var processed: Dictionary = (world.state().get("processed_battle_runs", {}) as Dictionary)
	_ok(processed.has("fixture-boss-victory"), "One-time boss victory records run receipt during battle")
	_no(bool(victory_battle.call("retry_allowed")), "One-time boss victory hides Retry")
	_ok(bool(victory_payload.get("battle_result", {}).get("one_time", false)),
		"One-time boss victory carries one_time policy to return")
	victory_battle.free()

	# --- One-time boss retry after victory ------------------------------------
	var farmed_run: Dictionary = _battle_payload(BOSS, true, "fixture-boss-farm")
	farmed_run["one_time"] = true
	var farmed_claim: Dictionary = state.call("claim_battle_reward", farmed_run)
	_no(bool(farmed_claim.get("ok", false)), "One-time boss retry after victory cannot claim again")
	_eq(str(farmed_claim.get("reason", "")), "already_claimed", "One-time boss retry after victory reason")
	_no(interaction.can_interact({
		"id": SPIRE_TRIGGER, "kind": "encounter_trigger",
		"interaction_policy": "one_time", "encounter_id": BOSS,
		"position": {"x": 640, "y": 360}
	}), "One-time boss trigger blocked after victory")

	# --- One-time boss retry after defeat -------------------------------------
	_fresh()
	var defeat_battle: Control = _make_battle(battle_context)
	_record_battle(defeat_battle, _battle_payload(BOSS, false, "fixture-boss-defeat"))
	_ok(bool(defeat_battle.call("retry_allowed")), "One-time boss retry after defeat remains available")
	_no(world.was_one_time_encounter_defeated(BOSS), "One-time boss defeat does not mark encounter cleared")
	defeat_battle.free()
	var retry_battle: Control = _make_battle(battle_context)
	_record_battle(retry_battle, _battle_payload(BOSS, true, "fixture-boss-retry"))
	_ok(world.was_one_time_encounter_defeated(BOSS), "One-time boss retry after defeat can clear encounter")
	_no(bool(retry_battle.call("retry_allowed")), "One-time boss retry victory closes Retry")
	retry_battle.free()

	# --- Repeatable encounter retry -------------------------------------------
	_fresh()
	var repeat_context: Dictionary = {
		"encounter_id": SKIRMISH, "location_id": MEADOW, "trigger_id": MEADOW_TRIGGER
	}
	var gil_before_repeat: int = _resource("gil")
	var repeat_battle: Control = _make_battle(repeat_context)
	_record_battle(repeat_battle, _battle_payload(SKIRMISH, true, "fixture-repeat-1"))
	var gil_after_first: int = _resource("gil")
	_ok(gil_after_first > gil_before_repeat, "Repeatable encounter first run grants rewards")
	_ok(bool(repeat_battle.call("retry_allowed")), "Repeatable encounter keeps Retry after victory")
	repeat_battle.free()
	var repeat_retry: Control = _make_battle(repeat_context)
	_record_battle(repeat_retry, _battle_payload(SKIRMISH, true, "fixture-repeat-2"))
	repeat_retry.free()
	_ok(_resource("gil") > gil_after_first, "Repeatable encounter retry grants rewards again")
	var repeat_claims: Dictionary = _data().get("reward_claims", {})
	_ok(repeat_claims.has("battle|run|fixture-repeat-1"), "Repeatable encounter run 1 claim recorded")
	_ok(repeat_claims.has("battle|run|fixture-repeat-2"), "Repeatable encounter run 2 claim recorded")
	return true


func test_duplicate_settlement_and_pending_recovery() -> bool:
	# --- Duplicate settlement with a multi-victory quest ----------------------
	_fresh()
	_ok(LocaleManager.has_key("battle.retry_save"), "retry-save action is localized")
	var quest_repo := MultiVictoryQuestRepository.new()
	var quest_id: String = MultiVictoryQuestRepository.MULTI_ID
	var objective_id: String = MultiVictoryQuestRepository.OBJECTIVE_ID
	var mutable: Dictionary = _data()
	var world_state: Dictionary = mutable.get("world", {})
	var quest_map: Dictionary = world_state.get("quests", {})
	quest_map[quest_id] = {"status": "active", "progress": {}, "completed": false}
	world_state["quests"] = quest_map
	mutable["world"] = world_state
	state.set("data", mutable)

	var repeat_context: Dictionary = {
		"encounter_id": SKIRMISH, "location_id": MEADOW, "trigger_id": MEADOW_TRIGGER
	}
	var first_result: Dictionary = _battle_payload(SKIRMISH, true, "fixture-multi-first")
	var first: Dictionary = state.call("settle_world_battle", first_result, repeat_context, quest_repo)
	_ok(bool(first.get("ok", false)), "first multi-victory settlement succeeds")
	_eq(_quest_progress(quest_id, objective_id), 1, "first victory advances multi-victory objective")

	var memory_before_duplicate: String = _fingerprint()
	var disk_before_duplicate: String = FileAccess.get_file_as_string(PLAYER_STATE_PATH)
	var duplicate: Dictionary = state.call(
		"settle_world_battle", first_result.duplicate(true), repeat_context.duplicate(true), quest_repo
	)
	_ok(bool(duplicate.get("ok", false)), "duplicate settlement reports success")
	_ok(bool(duplicate.get("duplicate", false)), "duplicate settlement is marked duplicate")
	_eq(_fingerprint(), memory_before_duplicate, "duplicate settlement changes no in-memory state")
	_eq(FileAccess.get_file_as_string(PLAYER_STATE_PATH), disk_before_duplicate,
		"duplicate settlement changes no persisted bytes")
	_eq(_quest_progress(quest_id, objective_id), 1,
		"duplicate settlement does not advance a multi-victory objective")
	var quest_after_duplicate: Dictionary = (world_state.get("quests", {}) as Dictionary)
	_no(bool((quest_after_duplicate[quest_id] as Dictionary).get("completed", false)),
		"duplicate settlement does not complete the quest")
	_no((_data().get("reward_claims", {}) as Dictionary).has("world|quest|%s" % quest_id),
		"duplicate settlement does not grant the quest reward")

	var distinct: Dictionary = state.call(
		"settle_world_battle", _battle_payload(SKIRMISH, true, "fixture-multi-second"),
		repeat_context, quest_repo
	)
	_ok(bool(distinct.get("ok", false)), "distinct repeatable run settles independently")
	_eq(_quest_progress(quest_id, objective_id), 2, "distinct victory advances the same objective")
	var persisted_after: Dictionary = _read_json(PLAYER_STATE_PATH)
	var persisted_world: Dictionary = persisted_after.get("world", {})
	var persisted_runs: Dictionary = persisted_world.get("processed_battle_runs", {})
	_ok(persisted_runs.has("fixture-multi-first"), "first run persisted")
	_ok(persisted_runs.has("fixture-multi-second"), "second run persisted")
	_ok((persisted_after.get("reward_claims", {}) as Dictionary).has("world|quest|%s" % quest_id),
		"second run completes and persists the quest reward")

	# --- Pending settlement fault and no-refight retry ------------------------
	_fresh()
	_ok(int(state.call("save")) == OK, "baseline save written before settlement fault")
	var baseline: String = FileAccess.get_file_as_string(PLAYER_STATE_PATH)
	var pending_context: Dictionary = {
		"encounter_id": BOSS, "location_id": SPIRE, "trigger_id": SPIRE_TRIGGER
	}
	var battle: Control = _make_battle_in_tree(pending_context)
	saves.call("fail_next_atomic_write")
	_record_battle(battle, _battle_payload(BOSS, true, "fixture-pending-fail"))

	var pending_result: Dictionary = state.call("get_pending_battle_result")
	var preserved_context: Dictionary = state.call("get_pending_battle_context")
	_eq(str(pending_result.get("run_id", "")), "fixture-pending-fail", "failed settlement preserves result")
	_eq(str(preserved_context.get("trigger_id", "")), SPIRE_TRIGGER, "failed settlement preserves trigger context")
	_eq(str(preserved_context.get("location_id", "")), SPIRE, "failed settlement preserves location context")
	_eq(str(preserved_context.get("encounter_id", "")), BOSS, "failed settlement preserves encounter context")
	_eq(str(state.call("get_pending_battle_kind")), "world", "failed world settlement is tagged for world retry")
	_eq(str(battle.get("_reward_status_key")), "battle.reward_save_failed", "failed settlement reports save error")
	_eq(FileAccess.get_file_as_string(PLAYER_STATE_PATH), baseline,
		"failed settlement leaves persisted save unchanged")
	_no(bool(battle.call("retry_allowed")), "pending settlement blocks battle restart")
	_no(bool(battle.call("can_leave_battle")), "pending settlement blocks navigation")
	var menu_button: Button = battle.get("_menu_button") as Button
	_ok(menu_button != null and menu_button.disabled, "top Menu button disabled while pending")
	var result_retry: Button = battle.find_child("PrimaryButton", true, false) as Button
	_ok(result_retry != null and result_retry.disabled, "result Retry disabled while pending")
	var retry_save: Button = battle.find_child("TertiaryButton", true, false) as Button
	_ok(retry_save != null and retry_save.visible, "localized Retry Save action visible while pending")
	if retry_save != null:
		_eq(retry_save.text, LocaleManager.t("battle.retry_save"), "Retry Save uses localized label")

	WorldContext.clear()
	var run_before_guards: String = str(battle.get("_run_id"))
	battle.call("_on_retry_pressed")
	battle.call("_on_menu_pressed")
	_eq(str(battle.get("_run_id")), run_before_guards, "pending settlement prevents a refight")
	_ok(WorldContext.peek().is_empty(), "pending settlement prevents battle-return navigation")

	saves.call("clear_write_failure")
	battle.call("_on_retry_save_pressed")
	_eq(str(battle.get("_reward_status_key")), "reward.saved", "retry-save settles without refighting")
	_ok((state.call("get_pending_battle_result") as Dictionary).is_empty(), "successful retry clears pending result")
	_ok((state.call("get_pending_battle_context") as Dictionary).is_empty(), "successful retry clears pending context")
	_ok(bool(battle.call("can_leave_battle")), "successful retry restores navigation")
	_no(retry_save.visible, "successful retry hides Retry Save")
	_no(menu_button.disabled, "successful retry re-enables Menu")
	var saved: Dictionary = _read_json(PLAYER_STATE_PATH)
	var saved_world: Dictionary = saved.get("world", {})
	var saved_runs: Dictionary = saved_world.get("processed_battle_runs", {})
	_ok(saved_runs.has("fixture-pending-fail"), "retried settlement persists the original run receipt")
	_eq(str((saved_runs.get("fixture-pending-fail", {}) as Dictionary).get("trigger_id", "")),
		SPIRE_TRIGGER, "retried settlement persists the preserved context")
	_ok((saved.get("reward_claims", {}) as Dictionary).has("battle|once|%s" % BOSS),
		"retried settlement persists the original reward claim")

	# --- Ordinary battle reward retry stays on the reward path ---------------
	var reward_run: String = "fixture-pending-reward-fail"
	saves.call("fail_next_atomic_write")
	var failed_claim: Dictionary = state.call("claim_battle_reward", _battle_payload(SKIRMISH, true, reward_run))
	_eq(str(failed_claim.get("reason", "")), "save_failed", "ordinary reward save failure is preserved")
	_eq(str(state.call("get_pending_battle_kind")), "reward", "ordinary battle failure is tagged for claim retry")
	saves.call("clear_write_failure")
	var retried_claim: Dictionary = state.call("retry_pending_battle_settlement")
	_ok(bool(retried_claim.get("ok", false)), "ordinary pending reward retries without world settlement")
	_ok((state.call("get_pending_battle_result") as Dictionary).is_empty(), "ordinary retry clears pending result")
	_eq(str(state.call("get_pending_battle_kind")), "", "successful retry clears pending kind")
	var reward_saved: Dictionary = _read_json(PLAYER_STATE_PATH)
	_ok((reward_saved.get("reward_claims", {}) as Dictionary).has("battle|run|%s" % reward_run),
		"ordinary retry persists the original run reward claim")

	tree.root.remove_child(battle)
	battle.free()
	return true


func test_scene_smoke() -> bool:
	_fresh()
	WorldContext.clear()
	var world_map_packed: PackedScene = load(WORLD_MAP_SCENE) as PackedScene
	_ok(world_map_packed != null, "world map scene loads")
	if world_map_packed == null:
		return true
	var world_map: Control = world_map_packed.instantiate() as Control
	tree.root.add_child(world_map)
	_eq(str((world_map.get("title_label") as Label).text), LocaleManager.t("world.map.title"), "map title localized")
	_eq((world_map.get("location_ids") as Array).size(), 3, "map markers from data")
	_no((world_map.get("enter_button") as Button).disabled, "starting location enterable")
	tree.root.remove_child(world_map)
	world_map.free()

	var exploration_packed: PackedScene = load(EXPLORATION_SCENE) as PackedScene
	_ok(exploration_packed != null, "exploration scene loads")
	if exploration_packed == null:
		return true
	var exploration: Control = exploration_packed.instantiate() as Control
	tree.root.add_child(exploration)
	_eq(str(exploration.get("area_id")), HAVEN, "exploration uses world context location")
	_ok((exploration.get("marker_buttons") as Dictionary).size() >= 3, "exploration markers created")
	_eq(str((exploration.get("title_label") as Label).text).contains(LocaleManager.t("world.explore.title")), true, "exploration title localized")
	exploration.set("_viewport_scale", Vector2(0.8, 0.8))
	var design_point: Vector2 = exploration.call("_screen_to_design", Vector2(640, 360))
	_eq(int(design_point.x), 800, "small-window mouse maps to design width")
	_eq(int(design_point.y), 450, "small-window mouse maps to design height")
	tree.root.remove_child(exploration)
	exploration.free()

	var dialogue_packed: PackedScene = load(DIALOGUE_SCENE) as PackedScene
	_ok(dialogue_packed != null, "dialogue panel scene loads")
	if dialogue_packed == null:
		return true
	var panel: PanelContainer = dialogue_packed.instantiate() as PanelContainer
	tree.root.add_child(panel)
	panel.call("show_page", {
		"speaker_key": "world.npc.keeper.name",
		"line_key": "dialogue.keeper.line1",
		"page": 1,
		"page_count": 2,
		"awaiting_choice": false,
		"finished": false,
		"choices": []
	})
	_eq(str((panel.get("speaker_label") as Label).text), LocaleManager.t("world.npc.keeper.name"), "dialogue speaker localized")
	_eq(str((panel.get("text_label") as Label).text), LocaleManager.t("dialogue.keeper.line1"), "dialogue line localized")
	tree.root.remove_child(panel)
	panel.free()
	return true
