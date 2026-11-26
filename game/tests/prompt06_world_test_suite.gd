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
var _original_locale: String = ""
var _original_files: Dictionary = {}
var _original_env: Dictionary = {}


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
	_run("test_scene_smoke")

	_restore_files()
	_restore_environment()
	state.set("data", _original_data)
	state.set("last_error", _original_last_error)
	saves.call("clear_write_failure")
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
	state.set("data", state.call("default_state", 0))
	state.set("last_error", "")
	saves.call("clear_write_failure")


func _fingerprint() -> String:
	var parser := JSON.new()
	var text: String = JSON.stringify(_data())
	if parser.parse(text) == OK:
		return JSON.stringify(parser.data)
	return text


func _resource(key: String) -> int:
	return int(state.call("get_resource", key))


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
	_ok(bool(retry_claim.get("ok", false)), "retry uses a new run identity")

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
