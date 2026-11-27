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

const EVENT_INTEGRITY_A := "event:GL:990101@integrity_a"
const EVENT_INTEGRITY_B := "event:GL:990102@integrity_b"
const EVENT_INTEGRITY_C := "event:GL:990103@integrity_c"
const EVENT_INTEGRITY_D := "event:GL:990104@integrity_d"
const EVENT_INTEGRITY_INVALID := "event:GL:990105@integrity_invalid"
const EVENT_INTEGRITY_UNKNOWN := "event:GL:990106@integrity_unknown"
const EVENT_INTEGRITY_REGION := "event:GL:990107@integrity_region"
const EVENT_INTEGRITY_PERMANENT := "event:GL:990108@integrity_permanent"
const EVENT_INTEGRITY_SCHEDULED := "event:GL:990109@integrity_scheduled"
const STAGE_INTEGRITY_A := "stage:GL:990161@integrity_a"
const STAGE_INTEGRITY_B := "stage:GL:990162@integrity_b"
const STAGE_INTEGRITY_C := "stage:GL:990163@integrity_c"
const STAGE_INTEGRITY_D := "stage:GL:990164@integrity_d"
const STAGE_INTEGRITY_INVALID := "stage:GL:990165@integrity_invalid"
const STAGE_INTEGRITY_UNKNOWN := "stage:GL:990166@integrity_unknown"
const STAGE_INTEGRITY_REGION := "stage:GL:990167@integrity_region"
const STAGE_INTEGRITY_PERMANENT := "stage:GL:990168@integrity_permanent"
const STAGE_INTEGRITY_SCHEDULED := "stage:GL:990169@integrity_scheduled"
const QUEST_OATH := "quest:GL:3100@oath"

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
	_run("test_mission_objective_qualification")
	_run("test_mission_objective_fail_closed")
	_run("test_nonrepeatable_cycles")
	_run("test_repeatable_cycles")
	_run("test_repeatable_cycles_and_fault_injection")
	_run("test_mission_cycle_ui")
	_run("test_event_unlock_evaluator")
	_run("test_collaboration_fixture")
	_run("test_battle_context_and_return")
	_run("test_battle_qa_event_context")
	_run("test_summon_navigation")
	_run("test_save_reload_and_migration")
	_run("test_fault_injection_rollback")
	_run("test_visual_theme_and_reduced_motion")
	_run("test_visual_card_signal")
	_run("test_visual_shop_localization")
	_run("test_visual_filter_and_focus")
	_run("test_visual_scroll_and_focus_structure")
	_run("test_visual_progress_widget_uniqueness")
	_run("test_visual_qa_focus_distinct")
	_run("test_visual_qa_replay_stage_selection")
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


func _claim_keys() -> Dictionary:
	var claims_variant: Variant = _data().get("reward_claims", {})
	return claims_variant if claims_variant is Dictionary else {}


func _reload() -> Dictionary:
	_ok(_write_file(PLAYER_STATE_PATH, JSON.stringify(_data())), "state fixture written")
	return state.call("load_state", 0)


func _integrity_event(id: String, stage_id: String, unlock: Dictionary, mode: String = "scheduled") -> Dictionary:
	var definition: Dictionary = events.get_event(EVENT_STORY).duplicate(true)
	var start_unix: int = 1700000000 if mode == "scheduled" else 0
	var end_unix: int = 1800000000 if mode == "scheduled" else 0
	definition["id"] = id
	definition["availability"] = {"mode": mode}
	definition["unlock"] = unlock.duplicate(true)
	definition["stage_ids"] = [stage_id]
	definition["regions"] = {
		"GL": {
			"start_unix": start_unix, "end_unix": end_unix,
			"stage_ids": [], "banner_ref": ""
		}
	}
	definition["event_currency"] = CURRENCY_STAR
	definition["shop_ref"] = ""
	definition["banner_ref"] = ""
	definition["boss_encounter"] = ENCOUNTER_GATE
	definition["replay_policy"] = {
		"archive_after_end": true, "replay_enabled": true, "keep_rewards_on_replay": true
	}
	definition["missions"] = []
	definition["shop"] = {"id": "", "items": []}
	definition["guests"] = []
	return definition


func _integrity_stage(id: String, event_id: String) -> Dictionary:
	var definition: Dictionary = events.get_event_stage(STAGE_GATE).duplicate(true)
	definition["id"] = id
	definition["event_id"] = event_id
	definition["region"] = "GL"
	definition["encounter_id"] = ENCOUNTER_GATE
	definition["unlock_after"] = []
	definition["completion_target"] = 1
	definition["first_clear_reward"] = {"gil": 10, "items": []}
	definition["repeat_reward"] = {"gil": 10, "items": []}
	definition["currency"] = {"id": CURRENCY_STAR, "amount": 1}
	return definition


func _integrity_service() -> EventStateService:
	var repository_pack: Dictionary = {
		"events": {
			EVENT_INTEGRITY_A: _integrity_event(
				EVENT_INTEGRITY_A, STAGE_INTEGRITY_A, {"kind": "none", "id": ""}
			),
			EVENT_INTEGRITY_B: _integrity_event(
				EVENT_INTEGRITY_B, STAGE_INTEGRITY_B,
				{"kind": "event", "id": EVENT_INTEGRITY_A}
			),
			EVENT_INTEGRITY_C: _integrity_event(
				EVENT_INTEGRITY_C, STAGE_INTEGRITY_C,
				{"kind": "stage", "id": STAGE_INTEGRITY_A}
			),
			EVENT_INTEGRITY_D: _integrity_event(
				EVENT_INTEGRITY_D, STAGE_INTEGRITY_D,
				{"kind": "quest", "id": QUEST_OATH}
			),
			EVENT_INTEGRITY_INVALID: _integrity_event(
				EVENT_INTEGRITY_INVALID, STAGE_INTEGRITY_INVALID,
				{"kind": "event", "id": "event:GL:999999@missing"}
			),
			EVENT_INTEGRITY_UNKNOWN: _integrity_event(
				EVENT_INTEGRITY_UNKNOWN, STAGE_INTEGRITY_UNKNOWN,
				{"kind": "unknown", "id": STAGE_INTEGRITY_A}
			),
			EVENT_INTEGRITY_REGION: _integrity_event(
				EVENT_INTEGRITY_REGION, STAGE_INTEGRITY_REGION,
				{"kind": "none", "id": ""}
			),
			EVENT_INTEGRITY_PERMANENT: _integrity_event(
				EVENT_INTEGRITY_PERMANENT, STAGE_INTEGRITY_PERMANENT,
				{"kind": "event", "id": EVENT_INTEGRITY_A}, "permanent"
			),
			EVENT_INTEGRITY_SCHEDULED: _integrity_event(
				EVENT_INTEGRITY_SCHEDULED, STAGE_INTEGRITY_SCHEDULED,
				{"kind": "event", "id": EVENT_INTEGRITY_A}
			)
		},
		"stages": {
			STAGE_INTEGRITY_A: _integrity_stage(STAGE_INTEGRITY_A, EVENT_INTEGRITY_A),
			STAGE_INTEGRITY_B: _integrity_stage(STAGE_INTEGRITY_B, EVENT_INTEGRITY_B),
			STAGE_INTEGRITY_C: _integrity_stage(STAGE_INTEGRITY_C, EVENT_INTEGRITY_C),
			STAGE_INTEGRITY_D: _integrity_stage(STAGE_INTEGRITY_D, EVENT_INTEGRITY_D),
			STAGE_INTEGRITY_INVALID: _integrity_stage(STAGE_INTEGRITY_INVALID, EVENT_INTEGRITY_INVALID),
			STAGE_INTEGRITY_UNKNOWN: _integrity_stage(STAGE_INTEGRITY_UNKNOWN, EVENT_INTEGRITY_UNKNOWN),
			STAGE_INTEGRITY_REGION: _integrity_stage(STAGE_INTEGRITY_REGION, EVENT_INTEGRITY_REGION),
			STAGE_INTEGRITY_PERMANENT: _integrity_stage(STAGE_INTEGRITY_PERMANENT, EVENT_INTEGRITY_PERMANENT),
			STAGE_INTEGRITY_SCHEDULED: _integrity_stage(STAGE_INTEGRITY_SCHEDULED, EVENT_INTEGRITY_SCHEDULED)
		}
	}
	var injected: EventRepository = EventRepository.new(repository, repository_pack)
	return EventStateService.new(state, injected)


func _integrity_result(run_id: String, event_id: String, stage_id: String) -> Dictionary:
	var payload: Dictionary = _result(run_id, event_id, stage_id)
	payload["region"] = "GL"
	payload["encounter_id"] = ENCOUNTER_GATE
	return payload


func _objective_pack(objective: Dictionary) -> Dictionary:
	var repository_pack: Dictionary = {"events": {}, "stages": {}}
	for event: Dictionary in events.get_events():
		(repository_pack["events"] as Dictionary)[str(event.get("id", ""))] = event.duplicate(true)
	for stage: Dictionary in events.get_event_stages():
		(repository_pack["stages"] as Dictionary)[str(stage.get("id", ""))] = stage.duplicate(true)
	var story: Dictionary = (repository_pack["events"] as Dictionary)[EVENT_STORY]
	(story["missions"] as Array)[0]["objective"] = objective.duplicate(true)
	(repository_pack["events"] as Dictionary)[EVENT_STORY] = story
	return repository_pack


func _mission_count(event_id: String, mission_id: String) -> int:
	var key: String = "%s|%s" % [event_id, mission_id]
	var progress_variant: Variant = (_event_section() as Dictionary).get("mission_progress", {})
	var progress: Dictionary = progress_variant if progress_variant is Dictionary else {}
	return int(progress.get(key, 0))


func _status_count(event_id: String, mission_id: String) -> int:
	return int(service.mission_status(event_id, mission_id).get("count", 0))


func _find_button_containing(node: Node, needle: String) -> Button:
	if needle.is_empty():
		return null
	if node is Button and str((node as Button).text).find(needle) >= 0:
		return node as Button
	for child: Node in node.get_children():
		var found: Button = _find_button_containing(child, needle)
		if found != null:
			return found
	return null


func _find_label_text(node: Node, needle: String) -> Label:
	if needle.is_empty():
		return null
	if node is Label and str((node as Label).text) == needle:
		return node as Label
	for child: Node in node.get_children():
		var found: Label = _find_label_text(child, needle)
		if found != null:
			return found
	return null


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


func test_mission_objective_qualification() -> bool:
	_fresh()
	_eq(_mission_count(EVENT_STORY, "clear_gate"), 0, "mission starts empty")
	_eq(_status_count(EVENT_STORY, "clear_gate"), 0, "mission status starts empty")
	var locked_warden: Dictionary = state.call(
		"settle_event_battle", _result("obj-warden-locked", EVENT_STORY, STAGE_WARDEN),
		_context(EVENT_STORY, STAGE_WARDEN)
	)
	_no(bool(locked_warden.get("ok", false)), "locked stage cannot be settled")
	_eq(_status_count(EVENT_STORY, "clear_gate"), 0, "locked stage does not advance missions")

	var gate_payload: Dictionary = _result("obj-gate-1", EVENT_STORY, STAGE_GATE)
	var gate_context: Dictionary = _context(EVENT_STORY, STAGE_GATE)
	_ok(bool(state.call("settle_event_battle", gate_payload, gate_context).get("ok", false)), "qualifying stage settles")
	_eq(_status_count(EVENT_STORY, "clear_gate"), 1, "qualifying stage advances its mission")
	var farm_after_gate: int = _mission_count(EVENT_STORY, "farm_gate")
	_eq(farm_after_gate, 1, "repeat mission advances on its own stage")

	var warden: Dictionary = state.call(
		"settle_event_battle", _result("obj-warden", EVENT_STORY, STAGE_WARDEN),
		_context(EVENT_STORY, STAGE_WARDEN)
	)
	_ok(bool(warden.get("ok", false)), "unlocked wrong stage settles")
	_eq(_status_count(EVENT_STORY, "clear_gate"), 1, "unrelated stage does not advance gate mission")
	_eq(_mission_count(EVENT_STORY, "farm_gate"), farm_after_gate, "unrelated stage does not advance repeat mission")

	var story_before: int = _status_count(EVENT_STORY, "clear_gate")
	var collab_stage: String = "stage:GL:980121@guest"
	var other_event: Dictionary = state.call(
		"settle_event_battle", _result("obj-other-event", EVENT_COLLAB, collab_stage),
		_context(EVENT_COLLAB, collab_stage)
	)
	_ok(bool(other_event.get("ok", false)), "other event stage settles")
	_eq(_status_count(EVENT_STORY, "clear_gate"), story_before, "other event does not advance this event's mission")

	var defeat: Dictionary = state.call(
		"settle_event_battle", _result("obj-defeat", EVENT_STORY, STAGE_GATE, false),
		_context(EVENT_STORY, STAGE_GATE, false)
	)
	_ok(bool(defeat.get("ok", false)), "defeat settlement records cleanly")
	_eq(_status_count(EVENT_STORY, "clear_gate"), 1, "defeat does not advance mission")

	var duplicate: Dictionary = state.call("settle_event_battle", gate_payload, gate_context)
	_ok(bool(duplicate.get("ok", false)), "duplicate settlement returns clean no-op")
	_eq(_status_count(EVENT_STORY, "clear_gate"), 1, "duplicate settlement does not advance mission")
	return true


func test_mission_objective_fail_closed() -> bool:
	var cases: Array[Dictionary] = [
		{
			"label": "invalid objective reference",
			"objective": {"type": "stage_clear", "ref": "stage:GL:999999@missing"}
		},
		{
			"label": "unknown objective type",
			"objective": {"type": "event_clear", "ref": STAGE_GATE}
		}
	]
	for index: int in range(cases.size()):
		_fresh()
		var case: Dictionary = cases[index]
		var injected: EventRepository = EventRepository.new(repository, _objective_pack(case["objective"]))
		var isolated: EventStateService = EventStateService.new(state, injected)
		var label: String = str(case.get("label", "objective case"))
		var status: Dictionary = isolated.mission_status(EVENT_STORY, "clear_gate")
		_no(bool(status.get("ok", false)), "%s is rejected" % label)
		_eq(str(status.get("reason", "")), "invalid_objective", "%s reason" % label)
		var claim: Dictionary = isolated.claim_mission(EVENT_STORY, "clear_gate")
		_eq(str(claim.get("reason", "")), "invalid_objective", "%s claim refused" % label)
		var outcome: Dictionary = isolated.settle_battle(
			_result("obj-invalid-%d" % index, EVENT_STORY, STAGE_GATE),
			_context(EVENT_STORY, STAGE_GATE)
		)
		_ok(bool(outcome.get("ok", false)), "%s stage settlement still succeeds" % label)
		_eq(_mission_count(EVENT_STORY, "clear_gate"), 0, "%s advances no mission" % label)
	return true


func test_nonrepeatable_cycles() -> bool:
	_fresh()
	for index: int in range(2):
		state.call(
			"settle_event_battle", _result("nonrepeat-%d" % index, EVENT_STORY, STAGE_GATE),
			_context(EVENT_STORY, STAGE_GATE)
		)
	var ready: Dictionary = service.mission_status(EVENT_STORY, "clear_gate")
	_ok(bool(ready.get("complete", false)), "non-repeatable mission completes")
	_ok(bool(ready.get("claimable", false)), "non-repeated claim becomes available")
	_eq(int(ready.get("claimed_cycles", -1)), 0, "non-repeated mission starts unclaimed")
	_eq(int(ready.get("next_claimable_cycle", -1)), 1, "non-repeatable next cycle is one")

	var gil_before: int = _resource("gil")
	var claim: Dictionary = service.claim_mission(EVENT_STORY, "clear_gate")
	_ok(bool(claim.get("ok", false)), "non-repeatable first claim succeeds")
	_eq(str(claim.get("key", "")), "world|event|mission|%s|clear_gate" % EVENT_STORY, "canonical claim identity preserved")
	_eq(_resource("gil") - gil_before, 200, "non-repeatable reward granted once")
	_ok(_claim_keys().has(str(claim.get("key", ""))), "non-repeatable claim recorded in canonical ledger")
	var duplicate: Dictionary = service.claim_mission(EVENT_STORY, "clear_gate")
	_eq(str(duplicate.get("reason", "")), "already_claimed", "non-repeatable duplicate claim refused")

	var extra: Dictionary = state.call(
		"settle_event_battle", _result("nonrepeat-extra", EVENT_STORY, STAGE_GATE),
		_context(EVENT_STORY, STAGE_GATE)
	)
	_ok(bool(extra.get("ok", false)), "additional qualifying run settles")
	var after_extra: Dictionary = service.mission_status(EVENT_STORY, "clear_gate")
	_no(bool(after_extra.get("claimable", false)), "additional run does not reopen claim")
	_ok(bool(after_extra.get("claimed", false)), "additional run preserves claimed state")

	_reload()
	var reloaded: Dictionary = service.mission_status(EVENT_STORY, "clear_gate")
	_ok(bool(reloaded.get("claimed", false)), "reload preserves claimed status")
	_no(bool(reloaded.get("claimable", false)), "reload does not reopen non-repeatable claim")
	_eq(str(service.claim_mission(EVENT_STORY, "clear_gate").get("reason", "")), "already_claimed", "post-reload duplicate claim refused")
	return true


func test_repeatable_cycles() -> bool:
	_fresh()
	var first_payload: Dictionary = _result("repeat-1", EVENT_STORY, STAGE_GATE)
	var first_context: Dictionary = _context(EVENT_STORY, STAGE_GATE)
	_ok(bool(state.call("settle_event_battle", first_payload, first_context).get("ok", false)), "first repeat run settles")
	var duplicate: Dictionary = state.call("settle_event_battle", first_payload, first_context)
	_ok(bool(duplicate.get("ok", false)), "duplicate repeat run is a no-op")
	_eq(_mission_count(EVENT_STORY, "farm_gate"), 1, "duplicate repeat run adds no progress")
	for index: int in range(2):
		state.call(
			"settle_event_battle", _result("repeat-%d" % (index + 2), EVENT_STORY, STAGE_GATE),
			_context(EVENT_STORY, STAGE_GATE)
		)
	var ready: Dictionary = service.mission_status(EVENT_STORY, "farm_gate")
	_ok(bool(ready.get("repeatable", false)), "repeat mission reports repeatability")
	_eq(int(ready.get("count", -1)), 3, "cycle requires configured target count")
	_eq(int(ready.get("target", -1)), 3, "cycle target is data-driven")
	_ok(bool(ready.get("claimable", false)), "first completed cycle is claimable")
	_eq(int(ready.get("completed_cycles", -1)), 1, "one completed cycle recorded")
	_eq(int(ready.get("next_claimable_cycle", -1)), 1, "next claimable cycle is one")

	var gil_before: int = _resource("gil")
	var item_before: int = _resource(REWARD_ITEM)
	var claim_one: Dictionary = service.claim_mission(EVENT_STORY, "farm_gate")
	_ok(bool(claim_one.get("ok", false)), "first cycle claim succeeds")
	_eq(int(claim_one.get("cycle", -1)), 1, "first cycle identity is one")
	_eq(_resource("gil") - gil_before, 300, "first cycle gil granted")
	_eq(_resource(REWARD_ITEM) - item_before, 1, "first cycle item granted")
	var key_one: String = "world|event|mission|%s|farm_gate|cycle:1" % EVENT_STORY
	_eq(str(claim_one.get("key", "")), key_one, "first cycle claim identity is deterministic")
	_ok(_claim_keys().has(key_one), "first cycle recorded in canonical ledger")
	_eq(str(service.claim_mission(EVENT_STORY, "farm_gate").get("reason", "")), "already_claimed", "first cycle cannot be claimed twice")

	_reload()
	for index: int in range(3):
		state.call(
			"settle_event_battle", _result("repeat-cycle2-%d" % index, EVENT_STORY, STAGE_GATE),
			_context(EVENT_STORY, STAGE_GATE)
		)
	var second_ready: Dictionary = service.mission_status(EVENT_STORY, "farm_gate")
	_eq(int(second_ready.get("completed_cycles", -1)), 2, "save/reload preserves completed cycles")
	_eq(int(second_ready.get("claimed_cycles", -1)), 1, "save/reload preserves claimed cycles")
	_eq(int(second_ready.get("next_claimable_cycle", -1)), 2, "second cycle becomes claimable")
	var claim_two: Dictionary = service.claim_mission(EVENT_STORY, "farm_gate")
	_ok(bool(claim_two.get("ok", false)), "second cycle claim succeeds")
	_eq(int(claim_two.get("cycle", -1)), 2, "second cycle identity is two")
	var key_two: String = "world|event|mission|%s|farm_gate|cycle:2" % EVENT_STORY
	_eq(str(claim_two.get("key", "")), key_two, "second cycle claim identity is distinct")
	_no(key_one == key_two, "cycle claim identities differ")
	_ok(_claim_keys().has(key_two), "second cycle recorded in canonical ledger")
	return true


func test_repeatable_cycles_and_fault_injection() -> bool:
	_fresh()
	for index: int in range(6):
		state.call(
			"settle_event_battle", _result("queue-%d" % index, EVENT_STORY, STAGE_GATE),
			_context(EVENT_STORY, STAGE_GATE)
		)
	var queued: Dictionary = service.mission_status(EVENT_STORY, "farm_gate")
	_eq(int(queued.get("completed_cycles", -1)), 2, "multiple completed cycles are retained")
	_eq(int(queued.get("claimed_cycles", -1)), 0, "no cycle claimed yet")
	_eq(int(queued.get("next_claimable_cycle", -1)), 1, "oldest unclaimed cycle is next")

	var gil_before: int = _resource("gil")
	saves.call("fail_next_atomic_write")
	var failed: Dictionary = service.claim_mission(EVENT_STORY, "farm_gate")
	_eq(str(failed.get("reason", "")), "save_failed", "failed claim is reported")
	_eq(_resource("gil"), gil_before, "failed claim grants no reward")
	_no(_claim_keys().has("world|event|mission|%s|farm_gate|cycle:1" % EVENT_STORY), "failed claim records no cycle")
	var after_fault: Dictionary = service.mission_status(EVENT_STORY, "farm_gate")
	_eq(int(after_fault.get("completed_cycles", -1)), 2, "failed claim keeps completed cycles")
	_eq(int(after_fault.get("claimed_cycles", -1)), 0, "failed claim does not consume a cycle")
	_ok(bool(after_fault.get("claimable", false)), "failed claim leaves cycle claimable")

	saves.call("clear_write_failure")
	var claim_one: Dictionary = service.claim_mission(EVENT_STORY, "farm_gate")
	_ok(bool(claim_one.get("ok", false)), "first queued cycle claims after failed save")
	_eq(int(service.mission_status(EVENT_STORY, "farm_gate").get("next_claimable_cycle", -1)), 2, "second queued cycle remains claimable")
	var claim_two: Dictionary = service.claim_mission(EVENT_STORY, "farm_gate")
	_ok(bool(claim_two.get("ok", false)), "second queued cycle claims")
	var final_status: Dictionary = service.mission_status(EVENT_STORY, "farm_gate")
	_eq(int(final_status.get("claimed_cycles", -1)), 2, "all completed cycles are claimed")
	_no(bool(final_status.get("claimable", false)), "no extra cycle is claimable")
	return true


func test_mission_cycle_ui() -> bool:
	_fresh()
	for index: int in range(3):
		state.call(
			"settle_event_battle", _result("ui-cycle-%d" % index, EVENT_STORY, STAGE_GATE),
			_context(EVENT_STORY, STAGE_GATE)
		)
	var locale_node: Node = tree.root.get_node_or_null("LocaleManager")
	if locale_node == null:
		_ok(false, "locale manager available for cycle UI")
		return true
	WorldContext.clear()
	OS.set_environment("FFBE_QA_MODE", "1")
	OS.set_environment("FFBE_QA_EVENT_NOW_UNIX", str(NOW_FIXED))
	OS.set_environment("FFBE_QA_EVENT_CENTER_VIEW", "detail")
	OS.set_environment("FFBE_QA_EVENT_ID", EVENT_STORY)
	OS.set_environment("FFBE_QA_REGION", "GL")
	var packed: PackedScene = load(EVENT_CENTER_SCENE) as PackedScene
	_ok(packed != null, "event center scene loads for cycle UI")
	if packed == null:
		return true
	var center: Control = packed.instantiate() as Control
	tree.root.add_child(center)
	var claim_text: String = str(locale_node.call("t", "event.center.cycle", {"cycle": 1}))
	var claim_button: Button = _find_button_containing(center, claim_text)
	_ok(claim_button != null, "claimable cycle is exposed in localized UI")
	if claim_button != null:
		_no(claim_button.disabled, "claimable cycle button is enabled")
		_ok(claim_button.text.find(EVENT_STORY) < 0, "cycle label exposes no technical IDs")

	_ok(bool(service.claim_mission(EVENT_STORY, "farm_gate").get("ok", false)), "cycle claimed before UI refresh")
	center.call("_rebuild")
	var next_text: String = str(locale_node.call("t", "event.center.next_cycle", {"cycle": 2}))
	var next_button: Button = _find_button_containing(center, next_text)
	_ok(next_button != null, "next claimable cycle is exposed in localized UI")
	if next_button != null:
		_ok(next_button.disabled, "incomplete next cycle stays disabled")

	tree.root.remove_child(center)
	center.free()
	WorldContext.clear()
	for key: String in [
		"FFBE_QA_MODE", "FFBE_QA_EVENT_NOW_UNIX", "FFBE_QA_EVENT_CENTER_VIEW",
		"FFBE_QA_EVENT_ID", "FFBE_QA_REGION"
	]:
		OS.set_environment(key, "")
	return true


func test_event_unlock_evaluator() -> bool:
	_fresh()
	var integrity: EventStateService = _integrity_service()
	_ok(integrity.is_event_unlocked(EVENT_INTEGRITY_A, "GL"), "no-prerequisite event is unlocked")

	_no(integrity.is_event_unlocked(EVENT_INTEGRITY_B, "GL"), "event prerequisite starts locked")
	_no(integrity.is_event_unlocked(EVENT_INTEGRITY_C, "GL"), "stage prerequisite starts locked")
	_no(integrity.is_event_unlocked(EVENT_INTEGRITY_D, "GL"), "quest prerequisite starts locked")
	_no(integrity.is_event_unlocked(EVENT_INTEGRITY_INVALID, "GL"), "invalid prerequisite reference fails closed")
	_no(integrity.is_event_unlocked(EVENT_INTEGRITY_UNKNOWN, "GL"), "unknown unlock type fails closed")
	_no(integrity.is_event_unlocked(EVENT_INTEGRITY_REGION, "JP"), "region mismatch fails closed")
	_eq(str(integrity.event_unlock_status(EVENT_INTEGRITY_REGION, "JP").get("reason", "")), "region_mismatch", "region mismatch reason")
	_eq(str(integrity.event_unlock_status(EVENT_INTEGRITY_UNKNOWN, "GL").get("reason", "")), "unknown_unlock", "unknown unlock reason")

	var permanent_event: Dictionary = integrity.repository().get_event(EVENT_INTEGRITY_PERMANENT)
	_eq(schedule.state(permanent_event, "GL", false, NOW_FIXED), EventSchedule.STATE_PERMANENT, "permanent availability is separate")
	_no(integrity.is_event_unlocked(EVENT_INTEGRITY_PERMANENT, "GL"), "permanent event still needs prerequisite")
	_no(bool(integrity.can_launch_stage(EVENT_INTEGRITY_PERMANENT, STAGE_INTEGRITY_PERMANENT, "GL").get("ok", false)), "permanent locked event cannot launch")

	var scheduled_event: Dictionary = integrity.repository().get_event(EVENT_INTEGRITY_SCHEDULED)
	_ok(schedule.can_enter(scheduled_event, "GL", true, NOW_FIXED), "scheduled event is available while active")
	_no(integrity.is_event_unlocked(EVENT_INTEGRITY_SCHEDULED, "GL"), "scheduled event prerequisite is unmet")
	_no(bool(integrity.can_launch_stage(EVENT_INTEGRITY_SCHEDULED, STAGE_INTEGRITY_SCHEDULED, "GL").get("ok", false)), "scheduled locked event cannot launch")

	var blocked: Dictionary = integrity.settle_battle(
		_integrity_result("unlock-blocked", EVENT_INTEGRITY_C, STAGE_INTEGRITY_C),
		_integrity_result("unlock-blocked", EVENT_INTEGRITY_C, STAGE_INTEGRITY_C)
	)
	_eq(str(blocked.get("reason", "")), "prerequisite_unmet", "gameplay service refuses locked stage")

	var prerequisite_payload: Dictionary = _integrity_result("unlock-prerequisite", EVENT_INTEGRITY_A, STAGE_INTEGRITY_A)
	_ok(bool(integrity.settle_battle(prerequisite_payload, prerequisite_payload).get("ok", false)), "prerequisite stage settles")
	_ok(integrity.is_event_unlocked(EVENT_INTEGRITY_B, "GL"), "event prerequisite unlocks after completion")
	_ok(integrity.is_event_unlocked(EVENT_INTEGRITY_C, "GL"), "stage prerequisite unlocks after completion")
	_ok(bool(integrity.can_launch_stage(EVENT_INTEGRITY_B, STAGE_INTEGRITY_B, "GL").get("ok", false)), "unlocked event launches stage")
	_ok(bool(integrity.can_launch_stage(EVENT_INTEGRITY_C, STAGE_INTEGRITY_C, "GL").get("ok", false)), "unlocked stage launches battle")

	var world_variant: Variant = _data().get("world", {})
	var world: Dictionary = world_variant if world_variant is Dictionary else {}
	var quests_variant: Variant = world.get("quests", {})
	var quests: Dictionary = quests_variant if quests_variant is Dictionary else {}
	quests[QUEST_OATH] = {"status": "completed"}
	world["quests"] = quests
	state.data["world"] = world
	_ok(integrity.is_event_unlocked(EVENT_INTEGRITY_D, "GL"), "quest prerequisite unlocks after completion")
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


func test_visual_theme_and_reduced_motion() -> bool:
	_ok(EventTheme.BG == Color("#081321"), "visual palette background token")
	_ok(EventTheme.PANEL == Color("#13263B"), "visual palette panel token")
	_ok(EventTheme.GOLD == Color("#D7B36A"), "visual palette gold token")
	_ok(EventTheme.CYAN == Color("#55C7CF"), "visual palette cyan token")
	var original: String = OS.get_environment("FFBE_REDUCED_MOTION")
	OS.set_environment("FFBE_REDUCED_MOTION", "1")
	_no(EventTheme.motion_enabled(), "reduced motion disables visual tweens")
	var node := Control.new()
	tree.root.add_child(node)
	var tween: Tween = EventTheme.tween_property(
		node, "modulate", Color(0.5, 0.5, 0.5, 1.0), 0.1
	)
	_ok(tween == null, "reduced motion sets properties immediately")
	_ok(is_equal_approx(node.modulate.r, 0.5), "reduced motion applies final value")
	tree.root.remove_child(node)
	node.free()
	OS.set_environment("FFBE_REDUCED_MOTION", original)
	return true


func test_visual_card_signal() -> bool:
	var card := EventCard.new()
	tree.root.add_child(card)
	card.configure({
		"kind": "shop",
		"title": "Synthetic item",
		"state": "Purchase",
		"payload": {"item_id": "synthetic_item"},
		"minimum_size": Vector2(280, 100)
	})
	var received: Array[Dictionary] = []
	card.activated.connect(func(payload: Dictionary) -> void: received.append(payload.duplicate(true)))
	card.pressed.emit()
	_ok(received.size() > 0, "card activation emits a payload")
	if received.size() > 0:
		_eq(str(received[0].get("item_id", "")), "synthetic_item", "card activation emits payload")
	_ok(card.text.find("Synthetic item") >= 0, "card mirrors visible copy for accessibility")
	card.set_selected(true)
	_ok(card.is_selected(), "card selected state is visible to tests")
	card.configure({
		"kind": "shop", "title": "Synthetic item", "disabled": true,
		"payload": {"item_id": "synthetic_item"}
	})
	_ok(card.disabled, "card disabled state blocks interaction")
	tree.root.remove_child(card)
	card.free()
	return true


func test_visual_shop_localization() -> bool:
	var locale_node: Node = tree.root.get_node_or_null("LocaleManager")
	if locale_node == null:
		_ok(false, "locale manager available for visual localization")
		return true
	var shop_name: String = str(locale_node.call("token", "event_shop", "stargarden_potion", ""))
	_ok(not shop_name.is_empty() and shop_name != "stargarden_potion", "shop item has a localized display name")
	WorldContext.clear()
	OS.set_environment("FFBE_QA_MODE", "1")
	OS.set_environment("FFBE_QA_EVENT_NOW_UNIX", str(NOW_FIXED))
	OS.set_environment("FFBE_QA_EVENT_CENTER_VIEW", "shop")
	OS.set_environment("FFBE_QA_EVENT_ID", EVENT_STORY)
	OS.set_environment("FFBE_QA_REGION", "GL")
	var packed: PackedScene = load(EVENT_CENTER_SCENE) as PackedScene
	var center: Control = packed.instantiate() as Control
	tree.root.add_child(center)
	_no(_has_text(center, "stargarden_potion"), "shop UI hides raw item IDs")
	_no(_has_text(center, "event_currency:GL:980901@stardust"), "shop UI hides raw currency IDs")
	_no(_has_text(center, "summon:GL:970001@base"), "summon UI hides raw banner IDs")
	_ok(_has_text(center, shop_name), "shop UI shows localized item name")
	tree.root.remove_child(center)
	center.free()
	WorldContext.clear()
	for key: String in [
		"FFBE_QA_MODE", "FFBE_QA_EVENT_NOW_UNIX", "FFBE_QA_EVENT_CENTER_VIEW",
		"FFBE_QA_EVENT_ID", "FFBE_QA_REGION"
	]:
		OS.set_environment(key, "")
	return true


func test_visual_filter_and_focus() -> bool:
	var locale_node: Node = tree.root.get_node_or_null("LocaleManager")
	if locale_node == null:
		_ok(false, "locale manager available for visual filters")
		return true
	WorldContext.clear()
	OS.set_environment("FFBE_QA_MODE", "1")
	OS.set_environment("FFBE_QA_EVENT_NOW_UNIX", str(NOW_FIXED))
	OS.set_environment("FFBE_QA_EVENT_CENTER_VIEW", "shop")
	OS.set_environment("FFBE_QA_EVENT_ID", EVENT_STORY)
	OS.set_environment("FFBE_QA_REGION", "GL")
	var packed: PackedScene = load(EVENT_CENTER_SCENE) as PackedScene
	var center: Control = packed.instantiate() as Control
	tree.root.add_child(center)
	var all_text: String = str(locale_node.call("t", "event.center.filter.all"))
	var all_button: Button = _find_button_containing(center, all_text)
	_ok(all_button != null and all_button.button_pressed, "all filter is selected")
	var shop_text: String = str(locale_node.call("t", "event.center.shop"))
	_ok(_find_label_text(center, shop_text) != null, "shop section heading is present")
	center.call("_apply_qa_focus")
	_ok(true, "visual focus pass completed")
	tree.root.remove_child(center)
	center.free()
	WorldContext.clear()
	for key: String in [
		"FFBE_QA_MODE", "FFBE_QA_EVENT_NOW_UNIX", "FFBE_QA_EVENT_CENTER_VIEW",
		"FFBE_QA_EVENT_ID", "FFBE_QA_REGION"
	]:
		OS.set_environment(key, "")
	return true


func test_visual_scroll_and_focus_structure() -> bool:
	WorldContext.clear()
	OS.set_environment("FFBE_QA_MODE", "1")
	OS.set_environment("FFBE_QA_EVENT_NOW_UNIX", str(NOW_FIXED))
	OS.set_environment("FFBE_QA_EVENT_CENTER_VIEW", "shop")
	OS.set_environment("FFBE_QA_EVENT_ID", EVENT_STORY)
	OS.set_environment("FFBE_QA_REGION", "GL")
	var packed: PackedScene = load(EVENT_CENTER_SCENE) as PackedScene
	var center: Control = packed.instantiate() as Control
	tree.root.add_child(center)
	var counts: Dictionary = {"horizontal": 0, "vertical": 0, "focusable": 0}
	_count_visual_scrolls(center, counts)
	_ok(int(counts.get("horizontal", 0)) >= 2, "status and category filters are horizontally scrollable")
	_ok(int(counts.get("vertical", 0)) >= 2, "event list and detail are vertically scrollable")
	_ok(int(counts.get("focusable", 0)) >= 2, "designed cards are keyboard focusable")
	tree.root.remove_child(center)
	center.free()
	WorldContext.clear()
	for key: String in [
		"FFBE_QA_MODE", "FFBE_QA_EVENT_NOW_UNIX", "FFBE_QA_EVENT_CENTER_VIEW",
		"FFBE_QA_EVENT_ID", "FFBE_QA_REGION"
	]:
		OS.set_environment(key, "")
	return true


func _count_visual_scrolls(node: Node, counts: Dictionary) -> void:
	if node is ScrollContainer:
		var scroll: ScrollContainer = node as ScrollContainer
		if scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO:
			counts["horizontal"] = int(counts.get("horizontal", 0)) + 1
		if scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO:
			counts["vertical"] = int(counts.get("vertical", 0)) + 1
	if node is EventCard and (node as EventCard).focus_mode == Control.FOCUS_ALL:
		counts["focusable"] = int(counts.get("focusable", 0)) + 1
	for child: Node in node.get_children():
		_count_visual_scrolls(child, counts)


func test_visual_progress_widget_uniqueness() -> bool:
	WorldContext.clear()
	OS.set_environment("FFBE_QA_MODE", "1")
	OS.set_environment("FFBE_QA_EVENT_NOW_UNIX", str(NOW_FIXED))
	OS.set_environment("FFBE_QA_EVENT_CENTER_VIEW", "shop")
	OS.set_environment("FFBE_QA_EVENT_ID", EVENT_STORY)
	OS.set_environment("FFBE_QA_REGION", "GL")
	var packed: PackedScene = load(EVENT_CENTER_SCENE) as PackedScene
	var center: Control = packed.instantiate() as Control
	tree.root.add_child(center)
	var progress_nodes: Array[EventProgress] = []
	_collect_progress_nodes(center, progress_nodes)
	var visible_count: int = 0
	var bad_bars: int = 0
	var bad_labels: int = 0
	var bad_maximum: int = 0
	for progress: EventProgress in progress_nodes:
		if not progress.visible:
			continue
		visible_count += 1
		var counts: Dictionary = {"bars": 0, "labels": 0}
		_count_direct_children(progress, counts)
		if int(counts.get("bars", 0)) != 1:
			bad_bars += 1
		if int(counts.get("labels", 0)) != 1:
			bad_labels += 1
		if progress.bar == null \
				or absf(progress.bar.max_value - float(progress.target_value)) > 0.01:
			bad_maximum += 1
	_ok(visible_count > 0, "visible mission progress cards exist")
	_eq(bad_bars, 0, "each progress card has exactly one bar")
	_eq(bad_labels, 0, "each progress card has exactly one value label")
	_eq(bad_maximum, 0, "each progress card uses the configured target")
	tree.root.remove_child(center)
	center.free()
	WorldContext.clear()
	for key: String in [
		"FFBE_QA_MODE", "FFBE_QA_EVENT_NOW_UNIX", "FFBE_QA_EVENT_CENTER_VIEW",
		"FFBE_QA_EVENT_ID", "FFBE_QA_REGION"
	]:
		OS.set_environment(key, "")
	return true


func _collect_progress_nodes(node: Node, output: Array[EventProgress]) -> void:
	if node is EventProgress:
		output.append(node as EventProgress)
	for child: Node in node.get_children():
		_collect_progress_nodes(child, output)


func _count_direct_children(node: Node, counts: Dictionary) -> void:
	for child: Node in node.get_children():
		if child is ProgressBar:
			counts["bars"] = int(counts.get("bars", 0)) + 1
		if child is Label:
			counts["labels"] = int(counts.get("labels", 0)) + 1


func test_visual_qa_focus_distinct() -> bool:
	var locale_node: Node = tree.root.get_node_or_null("LocaleManager")
	if locale_node == null:
		_ok(false, "locale manager available for QA focus")
		return true
	WorldContext.clear()
	var scenarios: Array[String] = ["stages", "rewards", "shop", "summon"]
	var keys: Dictionary = {
		"stages": "event.center.stages",
		"rewards": "event.center.rewards",
		"shop": "event.center.shop",
		"summon": "event.center.summon_nav",
	}
	var packed: PackedScene = load(EVENT_CENTER_SCENE) as PackedScene
	var offsets: Dictionary = {}
	for scenario: String in scenarios:
		OS.set_environment("FFBE_QA_MODE", "1")
		OS.set_environment("FFBE_QA_EVENT_NOW_UNIX", str(NOW_FIXED))
		OS.set_environment("FFBE_QA_EVENT_CENTER_VIEW", scenario)
		OS.set_environment("FFBE_QA_EVENT_ID", EVENT_STORY)
		OS.set_environment("FFBE_QA_REGION", "GL")
		var center: Control = packed.instantiate() as Control
		tree.root.add_child(center)
		center.call("_apply_qa_focus")
		var target: String = str(locale_node.call("t", str(keys.get(scenario, ""))))
		var label: Label = _find_label_text(center, target)
		var scroll: ScrollContainer = _scroll_ancestor(label)
		offsets[scenario] = scroll.scroll_vertical if scroll != null else -1
		tree.root.remove_child(center)
		center.free()
	for scenario: String in scenarios:
		_ok(int(offsets.get(scenario, -1)) > 0, "%s QA focus scrolls into view" % scenario)
	var unique: Dictionary = {}
	for scenario: String in scenarios:
		unique[str(offsets.get(scenario, -1))] = true
	_ok(unique.size() >= 3, "QA focus produces distinct section views")
	WorldContext.clear()
	for key: String in [
		"FFBE_QA_MODE", "FFBE_QA_EVENT_NOW_UNIX", "FFBE_QA_EVENT_CENTER_VIEW",
		"FFBE_QA_EVENT_ID", "FFBE_QA_REGION"
	]:
		OS.set_environment(key, "")
	return true


func test_visual_qa_replay_stage_selection() -> bool:
	WorldContext.clear()
	for key: String in [
		"FFBE_QA_MODE", "FFBE_QA_EVENT_NOW_UNIX", "FFBE_QA_EVENT_CENTER_VIEW",
		"FFBE_QA_EVENT_ID", "FFBE_QA_EVENT_STAGE_ID", "FFBE_QA_REGION"
	]:
		OS.set_environment(key, "")
	OS.set_environment("FFBE_QA_MODE", "1")
	OS.set_environment("FFBE_QA_EVENT_NOW_UNIX", str(NOW_FIXED))
	OS.set_environment("FFBE_QA_EVENT_CENTER_VIEW", "replay")
	OS.set_environment("FFBE_QA_EVENT_ID", "event:GL:980003@lumenguest")
	OS.set_environment("FFBE_QA_EVENT_STAGE_ID", "stage:GL:980121@guest")
	OS.set_environment("FFBE_QA_REGION", "GL")
	var packed: PackedScene = load(EVENT_CENTER_SCENE) as PackedScene
	var center: Control = packed.instantiate() as Control
	tree.root.add_child(center)
	_eq(
		str(center.get("_selected_stage_id")), "stage:GL:980121@guest",
		"replay QA view highlights the archive stage"
	)
	tree.root.remove_child(center)
	center.free()
	WorldContext.clear()
	for key: String in [
		"FFBE_QA_MODE", "FFBE_QA_EVENT_NOW_UNIX", "FFBE_QA_EVENT_CENTER_VIEW",
		"FFBE_QA_EVENT_ID", "FFBE_QA_EVENT_STAGE_ID", "FFBE_QA_REGION"
	]:
		OS.set_environment(key, "")
	return true


func _scroll_ancestor(node: Node) -> ScrollContainer:
	var cursor: Node = node
	while cursor != null:
		if cursor is ScrollContainer:
			return cursor as ScrollContainer
		cursor = cursor.get_parent()
	return null


func test_localization() -> bool:
	var locale_node: Node = tree.root.get_node_or_null("LocaleManager")
	if locale_node == null:
		_ok(false, "locale manager available")
		return true
	for locale: String in ["vi", "en", "ja"]:
		locale_node.call("set_locale", locale, false)
		var name_text: String = str(locale_node.call("t", "event.stargarden.name"))
		var status_text: String = str(locale_node.call("t", "event.state.active"))
		var cycle_text: String = str(locale_node.call("t", "event.center.cycle", {"cycle": 2}))
		var next_text: String = str(locale_node.call("t", "event.center.next_cycle", {"cycle": 3}))
		_no(name_text.is_empty(), "event name localized in %s" % locale)
		_no(status_text.is_empty(), "event status localized in %s" % locale)
		_no(cycle_text.is_empty(), "cycle label localized in %s" % locale)
		_no(next_text.is_empty(), "next-cycle label localized in %s" % locale)
		_no(name_text.begins_with("event."), "event name key resolved in %s" % locale)
		_no(cycle_text.begins_with("event."), "cycle key resolved in %s" % locale)
		_no(next_text.begins_with("event."), "next-cycle key resolved in %s" % locale)
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
