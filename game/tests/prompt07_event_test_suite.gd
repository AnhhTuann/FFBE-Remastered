class_name Prompt07EventTestSuite
extends RefCounted

## Prompt 07 offline Event Center suite. Every record is project-authored
## SYNTHETIC_FIXTURE / REMASTERED_DESIGN. The suite restores PlayerState data,
## user:// files, environment variables and locale, and never uses owner saves.

const PLAYER_STATE_PATH := "user://player_state_v3.json"
const BATTLE_PROGRESS_PATH := "user://battle_progress.json"
const SETTINGS_PATH := "user://settings.json"

const EVENT_STORY := "event:GL:980001@stargarden"
const EVENT_MOON := "event:JP:980002@moonlit"
const EVENT_COLLAB := "event:GL:980003@lumenguest"
const EVENT_ARCHIVE := "event:GL:980004@archive"
const EVENT_FUTURE := "event:JP:980005@future"
const EVENT_PERMANENT := "event:GL:980006@evergreen"
const STAGE_GATE := "stage:GL:980101@gate"
const STAGE_WARDEN := "stage:GL:980102@warden"
const ENCOUNTER_GATE := "encounter:GL:950001@skirmish"
const CURRENCY_STAR := "event_currency:GL:980901@stardust"
const REWARD_ITEM := "item:GL:940001@base"
const ETHER_ITEM := "item:GL:940002@base"
const EVENT_CENTER_SCENE := "res://scenes/event/event_center.tscn"

const NOW_FIXED := 1740000000

var runner: Object = null
var tree: SceneTree = null
var state: Node = null
var saves: Node = null
var repository: Node = null
var events: EventRepository = null
var schedule: EventSchedule = null
var service: EventStateService = null
var _original_data: Dictionary = {}
var _original_last_error: String = ""
var _original_save_status: String = "NORMAL"
var _original_locale: String = ""
var _original_files: Dictionary = {}
var _original_env: Dictionary = {}
var _failures: int = 0


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
		_ok(false, "prompt07 suite services available")
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

	events = EventRepository.new(repository)
	schedule = EventSchedule.new(func() -> int: return NOW_FIXED)
	service = EventStateService.new(state, events)

	_run("test_definition_validation")
	_run("test_schedule_boundaries")
	_run("test_permanent_archive_replay")
	_run("test_stage_unlocks")
	_run("test_first_clear_and_repeatable_rewards")
	_run("test_duplicate_settlement")
	_run("test_currency_and_shop_transactions")
	_run("test_mission_claims")
	_run("test_collaboration_fixture")
	_run("test_battle_context_and_return")
	_run("test_battle_qa_event_context")
	_run("test_summon_navigation")
	_run("test_save_reload_and_migration")
	_run("test_fault_injection_rollback")
	_run("test_localization")
	_run("test_responsive_geometry")
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


func _run(test_name: String) -> void:
	if call(test_name) != true:
		_failures += 1
		_ok(false, "prompt07 %s did not finish" % test_name)


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
	for key: String in [
		"FFBE_QA_MODE", "FFBE_QA_EVENT_CENTER_VIEW", "FFBE_QA_EVENT_ID",
		"FFBE_QA_EVENT_STAGE_ID", "FFBE_QA_REGION", "FFBE_QA_EVENT_NOW_UNIX",
		"FFBE_QA_SCENARIO", "FFBE_QA_RETURN_SCENE"
	]:
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
		_write_file(path, str(record.get("text", "")))


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _write_file(path: String, text: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true


func _data() -> Dictionary:
	var value: Variant = state.get("data") if state != null else null
	return value if value is Dictionary else {}


func _fresh() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".mig.bak"]:
		_remove_file(PLAYER_STATE_PATH + suffix)
	state.set("data", state.call("default_state", 0))
	state.set("last_error", "")
	state.call("set_save_status", "NORMAL", "")
	state.call("clear_pending_battle_result")
	saves.call("clear_write_failure")
	saves.call("clear_migration_backup_failure")


func _resource(item_id: String) -> int:
	var resources_variant: Variant = _data().get("resources", {})
	var resources: Dictionary = resources_variant if resources_variant is Dictionary else {}
	return int(resources.get(item_id, 0))


func _event_section() -> Dictionary:
	var value: Variant = _data().get("events", {})
	return value if value is Dictionary else {}


func _progress(event_id: String, stage_id: String) -> Dictionary:
	return service.get_stage_progress(event_id, stage_id)


func _result(run_id: String, event_id: String, stage_id: String, victory: bool = true) -> Dictionary:
	var stage: Dictionary = events.get_event_stage(stage_id)
	return {
		"run_id": run_id,
		"event_id": event_id,
		"stage_id": stage_id,
		"region": str(stage.get("region", "GL")),
		"encounter_id": str(stage.get("encounter_id", "")),
		"victory": victory,
		"outcome": "victory" if victory else "defeat",
		"turns": 3,
		"seed": 42,
		"rewards": {"gil": 999, "items": []}
	}


func _context(event_id: String, stage_id: String, victory: bool = true) -> Dictionary:
	return _result("context-%s-%s" % [event_id, stage_id], event_id, stage_id, victory)


# --- tests ----------------------------------------------------------------------

func test_definition_validation() -> bool:
	_ok(events.is_loaded(), "event repository loaded")
	_eq(events.get_events().size(), 6, "six synthetic events")
	_eq(events.get_event_stages().size(), 8, "eight synthetic stages")
	var summary: Dictionary = repository.call("summary")
	_eq(int(summary.get("event_count", 0)), 6, "summary event count")
	_eq(int(summary.get("event_stage_count", 0)), 8, "summary stage count")
	for event: Dictionary in events.get_events():
		_eq(str(event.get("verification_status", "")), "REMASTERED_DESIGN", "event evidence label")
		_eq(str((event.get("provenance", {}) as Dictionary).get("rights_gate", "")), "not_passed", "event rights gate")
		_no(bool((event.get("provenance", {}) as Dictionary).get("source_data_imported", false)), "event source import flag false")
		for stage_id_variant: Variant in (event.get("stage_ids", []) as Array):
			_ok(not events.get_event_stage(str(stage_id_variant)).is_empty(), "stage reference resolves")
	return true


func test_schedule_boundaries() -> bool:
	var event: Dictionary = events.get_event(EVENT_STORY)
	_eq(schedule.state(event, "GL", true, 1699999999), EventSchedule.STATE_UPCOMING, "upcoming before start")
	_eq(schedule.state(event, "GL", true, 1700000000), EventSchedule.STATE_ACTIVE, "active at inclusive start")
	_eq(schedule.state(event, "GL", true, 1799999999), EventSchedule.STATE_ACTIVE, "active before exclusive end")
	_eq(schedule.state(event, "GL", true, 1800000000), EventSchedule.STATE_REPLAYABLE, "replayable at end")
	_no(schedule.can_enter(event, "GL", true, 1699999999), "upcoming cannot enter")
	_ok(schedule.can_enter(event, "GL", true, 1700000000), "active can enter")
	_ok(schedule.can_enter(event, "GL", true, 1800000000), "replayable can enter")
	_ok(schedule.state(event, "JP", true, 1740000000) == EventSchedule.STATE_ENDED, "missing region is unavailable")
	return true


func test_permanent_archive_replay() -> bool:
	var permanent: Dictionary = events.get_event(EVENT_PERMANENT)
	_eq(schedule.state(permanent, "GL", true, 0), EventSchedule.STATE_PERMANENT, "permanent event state")
	_ok(schedule.can_enter(permanent, "GL", true, 9999999999), "permanent remains enterable")
	var archived: Dictionary = events.get_event(EVENT_ARCHIVE)
	_eq(schedule.state(archived, "GL", true, 1600000000), EventSchedule.STATE_REPLAYABLE, "archive event is replayable")
	var future: Dictionary = events.get_event(EVENT_FUTURE)
	_eq(schedule.state(future, "JP", true, NOW_FIXED), EventSchedule.STATE_UPCOMING, "future scheduled event")
	_no(bool((future.get("replay_policy", {}) as Dictionary).get("replay_enabled", false)), "future replay disabled")
	return true


func test_stage_unlocks() -> bool:
	_fresh()
	_no(service.is_stage_unlocked(EVENT_STORY, STAGE_WARDEN), "second stage locked initially")
	_ok(service.is_stage_unlocked(EVENT_STORY, STAGE_GATE), "first stage unlocked initially")
	var outcome: Dictionary = state.call("settle_event_battle", _result("unlock-1", EVENT_STORY, STAGE_GATE), _context(EVENT_STORY, STAGE_GATE))
	_ok(bool(outcome.get("ok", false)), "first stage settlement succeeds")
	_ok(service.is_stage_unlocked(EVENT_STORY, STAGE_WARDEN), "second stage unlocked after first clear")
	return true


func test_first_clear_and_repeatable_rewards() -> bool:
	_fresh()
	var gil_before: int = _resource("gil")
	var item_before: int = _resource(REWARD_ITEM)
	var first: Dictionary = state.call("settle_event_battle", _result("reward-1", EVENT_STORY, STAGE_GATE), _context(EVENT_STORY, STAGE_GATE))
	_ok(bool(first.get("ok", false)), "first settlement succeeds")
	_eq(_resource("gil") - gil_before, 420, "first clear plus repeat gil granted once")
	_eq(_resource(REWARD_ITEM) - item_before, 1, "first clear item granted")
	_eq(service.currency_amount(CURRENCY_STAR), 2, "event currency granted")
	_eq(int(_progress(EVENT_STORY, STAGE_GATE).get("runs", 0)), 1, "progress counted")
	_ok(bool(_progress(EVENT_STORY, STAGE_GATE).get("cleared", false)), "first clear recorded")

	var second: Dictionary = state.call("settle_event_battle", _result("reward-2", EVENT_STORY, STAGE_GATE), _context(EVENT_STORY, STAGE_GATE))
	_ok(bool(second.get("ok", false)), "repeat settlement succeeds")
	_eq(_resource("gil") - gil_before, 540, "repeat grants only repeatable gil")
	_eq(_resource(REWARD_ITEM) - item_before, 1, "first clear item not repeated")
	_eq(service.currency_amount(CURRENCY_STAR), 4, "repeat currency granted")
	_ok(bool(_progress(EVENT_STORY, STAGE_GATE).get("completed", false)), "completion target reached")
	return true


func test_duplicate_settlement() -> bool:
	_fresh()
	var payload: Dictionary = _result("dup-1", EVENT_STORY, STAGE_GATE)
	var context: Dictionary = _context(EVENT_STORY, STAGE_GATE)
	_ok(bool(state.call("settle_event_battle", payload, context).get("ok", false)), "initial settlement succeeds")
	var gil_after: int = _resource("gil")
	var duplicate: Dictionary = state.call("settle_event_battle", payload, context)
	_ok(bool(duplicate.get("ok", false)), "duplicate settlement returns clean no-op")
	_ok(bool(duplicate.get("duplicate", false)), "duplicate flag set")
	_eq(_resource("gil"), gil_after, "duplicate grants no gil")
	_eq(service.currency_amount(CURRENCY_STAR), 2, "duplicate grants no currency")
	var wrong_context: Dictionary = context.duplicate(true)
	wrong_context["stage_id"] = STAGE_WARDEN
	var mismatched: Dictionary = state.call("settle_event_battle", payload, wrong_context)
	_no(bool(mismatched.get("ok", false)), "run identity cannot be moved to another stage")
	return true


func test_currency_and_shop_transactions() -> bool:
	_fresh()
	for index: int in range(2):
		state.call("settle_event_battle", _result("shop-%d" % index, EVENT_STORY, STAGE_GATE), _context(EVENT_STORY, STAGE_GATE))
	_eq(service.currency_amount(CURRENCY_STAR), 4, "two runs fund the shop")
	var gil_before: int = _resource("gil")
	var item_before: int = _resource(REWARD_ITEM)
	var purchase: Dictionary = service.purchase_shop_item(EVENT_STORY, "stargarden_potion")
	_ok(bool(purchase.get("ok", false)), "shop purchase succeeds")
	_eq(service.currency_amount(CURRENCY_STAR), 1, "shop currency deducted")
	_eq(_resource(REWARD_ITEM) - item_before, 1, "shop item granted")
	_eq(_resource("gil"), gil_before, "shop reward adds no gil")
	var duplicate: Dictionary = service.purchase_shop_item(EVENT_STORY, "stargarden_potion")
	_eq(str(duplicate.get("reason", "")), "already_claimed", "shop purchase is idempotent")
	_eq(service.currency_amount(CURRENCY_STAR), 1, "duplicate purchase does not deduct")
	var insufficient: Dictionary = service.purchase_shop_item(EVENT_STORY, "stargarden_ether")
	_eq(str(insufficient.get("reason", "")), "insufficient_currency", "insufficient currency refused")
	return true


func test_mission_claims() -> bool:
	_fresh()
	var incomplete: Dictionary = service.claim_mission(EVENT_STORY, "farm_gate")
	_eq(str(incomplete.get("reason", "")), "mission_incomplete", "incomplete mission refuses claim")
	state.call("settle_event_battle", _result("mission-1", EVENT_STORY, STAGE_GATE), _context(EVENT_STORY, STAGE_GATE))
	var status: Dictionary = service.mission_status(EVENT_STORY, "clear_gate")
	_ok(bool(status.get("complete", false)), "one-run mission completes")
	var gil_before: int = _resource("gil")
	var claim: Dictionary = service.claim_mission(EVENT_STORY, "clear_gate")
	_ok(bool(claim.get("ok", false)), "mission claim succeeds")
	_eq(_resource("gil") - gil_before, 200, "mission reward granted")
	var duplicate: Dictionary = service.claim_mission(EVENT_STORY, "clear_gate")
	_eq(str(duplicate.get("reason", "")), "already_claimed", "mission claim is idempotent")
	return true


func test_collaboration_fixture() -> bool:
	_fresh()
	var collab: Dictionary = events.get_event(EVENT_COLLAB)
	_eq(str(collab.get("category", "")), "collaboration", "collaboration category")
	var guests_variant: Variant = collab.get("guests", [])
	_ok(guests_variant is Array and not (guests_variant as Array).is_empty(), "synthetic guest reference exists")
	var guest: Dictionary = (guests_variant as Array)[0]
	_eq(str(guest.get("rights_gate", "")), "not_passed", "guest rights gate stays closed")
	_ok(str(guest.get("id", "")).begins_with("guest:"), "guest uses synthetic identity")
	_ok(not events.banner_ref(EVENT_COLLAB, "GL").is_empty(), "collaboration banner reference exists")
	var outcome: Dictionary = state.call("settle_event_battle", _result("collab-1", EVENT_COLLAB, "stage:GL:980121@guest"), _context(EVENT_COLLAB, "stage:GL:980121@guest"))
	_ok(bool(outcome.get("ok", false)), "collaboration stage settles")
	return true


func test_battle_context_and_return() -> bool:
	_fresh()
	WorldContext.clear()
	var packed: PackedScene = load(EVENT_CENTER_SCENE) as PackedScene
	_ok(packed != null, "event center scene loads")
	if packed == null:
		return true
	var center: Control = packed.instantiate() as Control
	var context: Dictionary = center.call("stage_context", EVENT_STORY, STAGE_GATE)
	_eq(str(context.get("event_id", "")), EVENT_STORY, "stage context carries event")
	_eq(str(context.get("stage_id", "")), STAGE_GATE, "stage context carries stage")
	_eq(str(context.get("encounter_id", "")), ENCOUNTER_GATE, "stage context carries encounter")
	_eq(str(context.get("return_scene", "")), EVENT_CENTER_SCENE, "stage context returns to Event Center")
	_no(context.has("trigger_id"), "event context omits world trigger")
	WorldContext.write(context)
	_eq(str(WorldContext.peek().get("event_id", "")), EVENT_STORY, "WorldContext preserves event id")
	center.free()

	var battle_packed: PackedScene = load("res://scenes/battle/battle_scene.tscn") as PackedScene
	_ok(battle_packed != null, "battle scene loads")
	if battle_packed == null:
		return true
	var battle: Control = battle_packed.instantiate() as Control
	battle.set("_world_context", context)
	battle.set("_return_scene_path", EVENT_CENTER_SCENE)
	var result := BattleResult.new()
	result.encounter_id = ENCOUNTER_GATE
	result.encounter_name = "Synthetic event encounter"
	result.victory = true
	result.outcome = "victory"
	result.turns = 3
	result.seed = 42
	result.run_id = "event-context-run"
	var battle_state := BattleState.new()
	battle_state.result = result
	battle.call("_record_result", battle_state)
	var payload: Dictionary = battle.call("_world_return_context")
	_eq(str(payload.get("return_scene", "")), EVENT_CENTER_SCENE, "battle returns to Event Center")
	_eq(str(payload.get("event_id", "")), EVENT_STORY, "battle preserves event id")
	var carried: Dictionary = payload.get("battle_result", {})
	_eq(str(carried.get("run_id", "")), "event-context-run", "battle preserves unique run identity")
	_ok(bool(_progress(EVENT_STORY, STAGE_GATE).get("cleared", false)), "battle scene routed to event settlement")
	battle.free()
	WorldContext.clear()
	return true


func test_battle_qa_event_context() -> bool:
	# QA captures launch the battle scene directly. The seeded context must be
	# the same event contract Event Center writes, without a world trigger.
	var packed: PackedScene = load("res://scenes/battle/battle_scene.tscn") as PackedScene
	_ok(packed != null, "battle scene loads for QA context test")
	if packed == null:
		return true
	var battle: Control = packed.instantiate() as Control
	var context: Dictionary = battle.call(
		"qa_event_context", EVENT_STORY, STAGE_GATE, EVENT_CENTER_SCENE
	)
	_eq(str(context.get("event_id", "")), EVENT_STORY, "QA context carries event id")
	_eq(str(context.get("stage_id", "")), STAGE_GATE, "QA context carries stage id")
	_eq(str(context.get("encounter_id", "")), ENCOUNTER_GATE, "QA context carries encounter")
	_eq(str(context.get("region", "")), "GL", "QA context carries region")
	_eq(str(context.get("return_scene", "")), EVENT_CENTER_SCENE, "QA context returns to Event Center")
	_no(context.has("trigger_id"), "QA event context omits world trigger")
	battle.free()
	return true


func test_summon_navigation() -> bool:
	var packed: PackedScene = load(EVENT_CENTER_SCENE) as PackedScene
	var center: Control = packed.instantiate() as Control
	var context: Dictionary = center.call("banner_context", EVENT_STORY)
	_eq(str(context.get("event_id", "")), EVENT_STORY, "banner context carries event")
	_eq(str(context.get("region", "")), "GL", "banner context carries region")
	_eq(str(context.get("return_scene", "")), EVENT_CENTER_SCENE, "banner context returns to Event Center")
	_ok(not events.banner_ref(EVENT_STORY, "GL").is_empty(), "story banner reference resolves")
	center.free()
	WorldContext.write(context)
	var summon_packed: PackedScene = load("res://scenes/phase3/summon.tscn") as PackedScene
	_ok(summon_packed != null, "summon scene loads")
	if summon_packed != null:
		var summon: Control = summon_packed.instantiate() as Control
		_eq(str(summon.call("_return_destination")), EVENT_CENTER_SCENE, "summon returns to Event Center")
		summon.free()
	WorldContext.clear()
	return true


func test_save_reload_and_migration() -> bool:
	_fresh()
	var raw: Dictionary = state.call("default_state", 0)
	raw.erase("events")
	raw["version"] = 3
	_ok(_write_file(PLAYER_STATE_PATH, JSON.stringify(raw)), "v3 fixture written")
	var migrated: Dictionary = state.call("load_state", 0)
	_eq(int(migrated.get("version", 0)), 4, "v3 normalized to format v4")
	_ok((migrated.get("events", {}) as Dictionary).has("processed_runs"), "events section backfilled")
	_ok(FileAccess.file_exists(PLAYER_STATE_PATH + ".mig.bak"), "migration backup created")
	_eq(int((migrated.get("resources", {}) as Dictionary).get("gil", 0)), 500000, "existing resources preserved")

	var future: Dictionary = state.call("default_state", 0)
	var future_events: Dictionary = future["events"]
	future_events["version"] = 2
	future["events"] = future_events
	_ok(_write_file(PLAYER_STATE_PATH, JSON.stringify(future)), "future fixture written")
	var refused: Dictionary = state.call("load_state", 0)
	_eq(str(state.get("save_status")), state.get("SAVE_STATUS_READ_ONLY_FUTURE_VERSION"), "future events version locks profile")
	_ok((refused.get("events", {}) as Dictionary).has("version"), "future load returns safe in-memory default")
	_no(state.call("is_write_allowed"), "future save refuses writes")
	_fresh()
	return true


func test_fault_injection_rollback() -> bool:
	_fresh()
	var gil_before: int = _resource("gil")
	saves.call("fail_next_atomic_write")
	var failed: Dictionary = state.call("settle_event_battle", _result("fault-1", EVENT_STORY, STAGE_GATE), _context(EVENT_STORY, STAGE_GATE))
	_eq(str(failed.get("reason", "")), "save_failed", "failed write reported")
	_eq(_resource("gil"), gil_before, "failed transaction rolled back resources")
	_eq(int(_progress(EVENT_STORY, STAGE_GATE).get("runs", 0)), 0, "failed transaction rolled back progress")
	_eq(str(state.call("get_pending_battle_kind")), "event", "event settlement preserved for retry")
	var retry: Dictionary = state.call("retry_pending_battle_settlement")
	_ok(bool(retry.get("ok", false)), "retry succeeds after fault cleared")
	_eq(int(_progress(EVENT_STORY, STAGE_GATE).get("runs", 0)), 1, "retry records progress once")
	return true


func test_localization() -> bool:
	var locale_node: Node = tree.root.get_node_or_null("LocaleManager")
	if locale_node == null:
		_ok(false, "locale manager available")
		return true
	for locale: String in ["vi", "en", "ja"]:
		locale_node.call("set_locale", locale, false)
		var name_text: String = str(locale_node.call("t", "event.stargarden.name"))
		var status_text: String = str(locale_node.call("t", "event.state.active"))
		_no(name_text.is_empty(), "event name localized in %s" % locale)
		_no(status_text.is_empty(), "event status localized in %s" % locale)
		_no(name_text.begins_with("event."), "event name key resolved in %s" % locale)
	return true


func test_responsive_geometry() -> bool:
	var packed: PackedScene = load(EVENT_CENTER_SCENE) as PackedScene
	var center: Control = packed.instantiate() as Control
	tree.root.add_child(center)
	for portrait: bool in [false, true]:
		center.set("_portrait_override", 1 if portrait else 0)
		center.call("_rebuild")
		_eq(bool(center.get("_portrait")), portrait, "layout profile applied")
		_ok(center.get_child_count() > 0, "layout has a root container")
		_validate_control_geometry(center, "landscape" if not portrait else "portrait")
	tree.root.remove_child(center)
	center.free()
	return true


func _validate_control_geometry(node: Node, label: String) -> void:
	if node is Control:
		var control: Control = node as Control
		_ok(control.size.x >= 0 and control.size.y >= 0, "%s control size is finite" % label)
	if node.get_child_count() == 0:
		return
	for child: Node in node.get_children():
		_validate_control_geometry(child, label)


func test_scene_smoke() -> bool:
	OS.set_environment("FFBE_QA_MODE", "1")
	OS.set_environment("FFBE_QA_EVENT_NOW_UNIX", str(NOW_FIXED))
	OS.set_environment("FFBE_QA_EVENT_CENTER_VIEW", "detail")
	var packed: PackedScene = load(EVENT_CENTER_SCENE) as PackedScene
	var center: Control = packed.instantiate() as Control
	tree.root.add_child(center)
	_ok(center.get_child_count() > 0, "event center renders controls")
	var locale_node: Node = tree.root.get_node_or_null("LocaleManager")
	var title_text: String = str(locale_node.call("t", "event.center.title")) if locale_node != null else ""
	_ok(_has_text(center, title_text), "localized event center title rendered")
	_ok(true, "event center scene smoke completed")
	tree.root.remove_child(center)
	center.free()
	return true


func _has_text(node: Node, needle: String) -> bool:
	if needle.is_empty():
		return false
	if node is Label and str((node as Label).text).find(needle) >= 0:
		return true
	if node is Button and str((node as Button).text).find(needle) >= 0:
		return true
	for child: Node in node.get_children():
		if _has_text(child, needle):
			return true
	return false
