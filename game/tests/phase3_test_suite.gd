class_name Phase3TestSuite
extends RefCounted

## Deterministic Phase 3 progression, inventory, build, locale, save-migration
## and scene-instantiation coverage. All fixtures are project-authored
## SYNTHETIC_FIXTURE data; no original FFBE value is asserted here.
##
## Every test starts from PlayerState.default_state(). The caller's player
## state and locale are restored on exit so this suite is safe to run repeatedly.

const PLAYER_STATE_PATH := "user://player_state_v3.json"

const V1 := "unit:GL:910101:0001@base" # vanguard, first copy
const V2 := "unit:GL:910102:0002@base" # arcanist
const V3 := "unit:GL:910103:0003@base" # mender
const JP1 := "unit:JP:910104:0004@base" # warden
const V5 := "unit:GL:910105:0005@base" # bulwark
const V6 := "unit:GL:910101:0006@base" # vanguard, second copy
const VANGUARD_DEF := "unit:GL:910101@base"
const ARCANIST_DEF := "unit:GL:910102@base"
const JP_DEF := "unit:JP:910104@base"

const BLADE := "owned:GL:500001:0001@blade"
const STAFF := "owned:GL:500002:0002@staff"
const SHIELD := "owned:GL:500003:0003@shield"
const ARMOR := "owned:GL:510001:0004@armor"
const ACCESSORY := "owned:GL:520001:0006@accessory"
const JP_ACCESSORY := "owned:JP:520002:0007@accessory"
const MAT_ATK_1 := "owned:GL:600001:0008@base"
const MAT_ATK_2 := "owned:GL:600001:0009@base"
const MAT_MAG := "owned:GL:600002:0010@base"
const MAT_SPR_1 := "owned:GL:600003:0011@base"
const MAT_DW := "owned:GL:600005:0013@base"
const VC_GL := "owned:GL:700001:0015@base"
const VC_JP := "owned:JP:700002:0016@base"
const VC_ARCANE := "owned:GL:700003:0017@base"

const SLB_VANGUARD := "ability:GL:952101@base"
const OVERDRIVE_VANGUARD := "ability:GL:953101@base"
const SHIFT_ABILITY := "ability:GL:941102@brave_shift"
const SKIRMISH := "encounter:GL:950001@skirmish"

const PHASE3_SCENES: Array[String] = [
	"res://scenes/phase3/collection.tscn",
	"res://scenes/phase3/character_details.tscn",
	"res://scenes/phase3/upgrade.tscn",
	"res://scenes/phase3/awakening.tscn",
	"res://scenes/phase3/equipment.tscn",
	"res://scenes/phase3/vision_card.tscn",
	"res://scenes/phase3/party.tscn"
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
		_ok(false, "phase3 services available")
		return false

	var original_data: Dictionary = _data().duplicate(true)
	var original_locale: String = str(locale_manager.get("current_locale"))
	var had_state_file: bool = FileAccess.file_exists(PLAYER_STATE_PATH)
	var original_instance_env: String = OS.get_environment("FFBE_QA_INSTANCE_ID")
	var original_party_env: String = OS.get_environment("FFBE_QA_PARTY_ID")

	_run("test_composite_identity_and_copies")
	_run("test_exp_level_pot_caps")
	_run("test_duplicate_conversion_resource_safety")
	_run("test_awakening_star_nv_ex_nv_plus")
	_run("test_trust_and_tmr_stmr_claims")
	_run("test_equipment_restrictions_and_stat_recalculation")
	_run("test_vision_card_assignment_and_level_bonuses")
	_run("test_leader_skill_and_brave_shift_builds")
	_run("test_advanced_mechanic_labels")
	_run("test_invalid_transactions_preserve_resources")
	_run("test_save_v2_to_v4_migration")
	_run("test_locale_fallback_and_localized_text")
	_run("test_battle_reward_idempotency")
	_run("test_battle_reward_bucket_settlement")
	_run("test_battle_reward_save_failure_rollback")
	_run("test_phase3_scenes_instantiate")

	# Restore the caller's state. Tests intentionally commit to the same
	# user:// file that the game uses; the snapshot is written back verbatim.
	state.set("data", original_data)
	state.call("rebuild_systems")
	state.call("save")
	if not had_state_file and FileAccess.file_exists(PLAYER_STATE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PLAYER_STATE_PATH))
	locale_manager.call("set_locale", original_locale, false)
	OS.set_environment("FFBE_QA_INSTANCE_ID", original_instance_env)
	OS.set_environment("FFBE_QA_PARTY_ID", original_party_env)
	return true


func _run(test_name: String) -> void:
	if call(test_name) != true:
		_ok(false, "phase3 %s did not finish (runtime error?)" % test_name)


# --- assertion and state helpers ------------------------------------------------

func _ok(condition: bool, label: String) -> void:
	runner.call("assert_true", condition, label)


func _eq(actual: Variant, expected: Variant, label: String) -> void:
	runner.call("assert_eq", actual, expected, label)


func _result_ok(result: Dictionary, label: String) -> bool:
	var success: bool = bool(result.get("ok", false))
	_ok(success, label)
	return success


func _result_fail(result: Dictionary, reason: String, label: String) -> bool:
	_ok(not bool(result.get("ok", false)), "%s rejected" % label)
	_eq(str(result.get("reason", "")), reason, "%s reason" % label)
	return not bool(result.get("ok", false))


func _data() -> Dictionary:
	var value: Variant = state.get("data")
	return value if value is Dictionary else {}


func _resources() -> Dictionary:
	return state.call("get_resources")


func _resource(key: String) -> int:
	return int(_resources().get(key, 0))


func _owned() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Variant in state.call("owned_units"):
		if entry is Dictionary:
			result.append(entry as Dictionary)
	return result


func _unit(instance_id: String) -> Dictionary:
	var value: Variant = state.call("get_unit_instance", instance_id)
	return value if value is Dictionary else {}


func _fresh() -> void:
	state.call("reset_to_defaults")


func _snapshot() -> String:
	return JSON.stringify({
		"resources": _resources(),
		"owned_units": (_data().get("owned_units", []) as Array).duplicate(true),
		"inventory": (_data().get("inventory", {}) as Dictionary).duplicate(true),
		"parties": state.call("parties")
	})


func _assert_unchanged(before: String, label: String) -> void:
	_eq(_snapshot(), before, "%s left state unchanged" % label)


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


func _resolve(instance_id: String, party_id: String = "") -> Dictionary:
	var value: Variant = state.get("build_resolver")
	if not (value is RefCounted) or not (value as RefCounted).has_method("resolve_unit"):
		return {}
	var resolved: Variant = (value as RefCounted).call("resolve_unit", instance_id, party_id, true)
	return resolved if resolved is Dictionary else {}


func _stats(instance_id: String, party_id: String = "") -> Dictionary:
	var resolved: Dictionary = _resolve(instance_id, party_id)
	return resolved.get("stats", {}) if resolved.get("stats", {}) is Dictionary else {}


func _has_diagnostic(resolved: Dictionary, key: String) -> bool:
	for entry_variant: Variant in resolved.get("diagnostics", []):
		if entry_variant is Dictionary and str((entry_variant as Dictionary).get("key", "")) == key:
			return true
	return false


func _inventory_uid(definition_id: String) -> String:
	for entry: Dictionary in state.call("inventory_section", "equipment"):
		if str(entry.get("definition_id", "")) == definition_id:
			return str(entry.get("uid", ""))
	for entry: Dictionary in state.call("inventory_section", "materia"):
		if str(entry.get("definition_id", "")) == definition_id:
			return str(entry.get("uid", ""))
	for entry: Dictionary in state.call("inventory_section", "vision_cards"):
		if str(entry.get("definition_id", "")) == definition_id:
			return str(entry.get("uid", ""))
	return ""


func _count_definition(definition_id: String) -> int:
	var count: int = 0
	for entry: Dictionary in _owned():
		if str(entry.get("definition_id", "")) == definition_id:
			count += 1
	return count


# --- identity -------------------------------------------------------------------

func test_composite_identity_and_copies() -> bool:
	_fresh()
	var gl: Variant = ContentRepository.call("parse_composite_id", "unit:GL:900001@base")
	var jp: Variant = ContentRepository.call("parse_composite_id", "unit:JP:900001@base")
	_ok(gl != null, "GL composite ID parses")
	_ok(jp != null, "JP composite ID parses")
	if gl == null or jp == null:
		return true
	_ok(bool(gl.call("is_valid")), "GL identity valid")
	_ok(bool(jp.call("is_valid")), "JP identity valid")
	_eq(str(gl.call("as_text")), "unit:GL:900001@base", "GL identity round trip")
	_eq(str(jp.call("as_text")), "unit:JP:900001@base", "JP identity round trip")
	_eq(str(gl.get("region")), "GL", "GL region retained")
	_eq(str(jp.get("region")), "JP", "JP region retained")
	_eq(str(gl.get("native_id")), str(jp.get("native_id")), "same native ID in both regions")
	_eq(str(gl.get("form")), "base", "GL form retained")
	_ok(str(gl.call("as_text")) != str(jp.call("as_text")), "no GL/JP numeric ID collapse")
	var invalid: Object = ContentRepository.call("parse_composite_id", "unit:ZZ:1@base")
	_ok(invalid == null or not bool(invalid.call("is_valid")), "invalid region rejected")

	var gl_def: Dictionary = ContentRepository.call("get_unit_definition", VANGUARD_DEF)
	var jp_def: Dictionary = ContentRepository.call("get_unit_definition", JP_DEF)
	_eq(str(gl_def.get("id", "")), VANGUARD_DEF, "GL definition identity")
	_eq(str(jp_def.get("id", "")), JP_DEF, "JP definition identity")
	_ok(str(gl_def.get("id", "")) != str(jp_def.get("id", "")), "definitions stay region-distinct")
	_eq(str(gl_def.get("region", "")), "GL", "GL definition region")
	_eq(str(jp_def.get("region", "")), "JP", "JP definition region")
	_ok(not str(jp_def.get("native_id", "")).is_empty(), "JP definition keeps native ID")

	var units: Array[Dictionary] = _owned()
	_eq(units.size(), 6, "default owned unit count")
	var ids: Array[String] = []
	for entry: Dictionary in units:
		ids.append(str(entry.get("instance_id", "")))
	var unique_ids: Dictionary = {}
	for id: String in ids:
		unique_ids[id] = true
	_eq(unique_ids.size(), 6, "owned instance IDs are unique")
	for expected: String in [V1, V2, V3, JP1, V5, V6]:
		_ok(ids.has(expected), "owned instance present: %s" % expected)
	_ok(V1 != V6, "copies have distinct instance IDs")
	_eq(_count_definition(VANGUARD_DEF), 2, "two copies of the GL vanguard definition")
	_eq(_count_definition(JP_DEF), 1, "one JP warden copy")

	var first: Dictionary = _unit(V1)
	_eq(str(first.get("definition_id", "")), VANGUARD_DEF, "first copy definition")
	_eq(int(first.get("serial", 0)), 1, "first copy serial")
	_eq(str(first.get("region", "")), "GL", "first copy region")
	_eq(str(first.get("native_id", "")), "910101", "first copy native ID")
	_eq(str(first.get("form", "")), "base", "first copy form")
	var second: Dictionary = _unit(V6)
	_eq(str(second.get("definition_id", "")), VANGUARD_DEF, "second copy definition")
	_eq(int(second.get("serial", 0)), 6, "second copy serial")
	_eq(str(second.get("base_id", "")), "unit:GL:910101", "copy shares base ID")
	var warden: Dictionary = _unit(JP1)
	_eq(str(warden.get("region", "")), "JP", "JP instance region")
	_eq(str(warden.get("definition_id", "")), JP_DEF, "JP instance definition")
	_ok(_unit("unit:GL:910101:9999@base").is_empty(), "unknown instance is empty")

	var detached: Dictionary = _unit(V1)
	detached["level"] = 99
	_eq(int(_unit(V1).get("level", 0)), 1, "get_unit_instance returns a defensive copy")
	_ok(bool(state.call("mutate_unit_instance", V1, {"favorite": true})), "mutate known instance")
	_ok(bool(_unit(V1).get("favorite", false)), "mutation persisted")
	_ok(not bool(state.call("mutate_unit_instance", "unit:GL:999999:1@base", {"favorite": true})), "mutate unknown instance fails")
	return true


# --- EXP, levels, pots and caps -------------------------------------------------

func test_exp_level_pot_caps() -> bool:
	_fresh()
	var progression: RefCounted = state.get("progression") as RefCounted
	var summary: Dictionary = progression.call("cost_summary", V1)
	_eq(int(summary.get("exp_required", 0)), 120, "level 1 EXP requirement from fixture curve")
	_eq(int(summary.get("level_cap", 0)), 80, "star 5 level cap")

	var result: Dictionary = progression.call("gain_exp", V1, 120)
	_ok(bool(result.get("ok", false)), "positive EXP accepted")
	_eq(int(result.get("levels_gained", -1)), 1, "one level gained")
	_eq(int(result.get("level", 0)), 2, "level advanced to 2")
	_eq(int(_unit(V1).get("exp", -1)), 0, "EXP remainder consumed")
	_ok((_unit(V1).get("learned_abilities", []) as Array).has("ability:GL:931101@base"), "level ability learned")
	_ok(not (_unit(V1).get("learned_abilities", []) as Array).has("ability:GL:941101@base"), "star-gated ability still locked")

	var before: String = _snapshot()
	_result_fail(progression.call("gain_exp", V1, 0), "invalid_amount", "zero EXP")
	_result_fail(progression.call("gain_exp", "unit:GL:999999:1@base", 10), "unknown_instance", "EXP for unknown instance")
	_assert_unchanged(before, "invalid EXP requests")

	result = progression.call("gain_exp", V1, 100)
	_ok(bool(result.get("ok", false)), "partial EXP accepted")
	_eq(int(_unit(V1).get("level", 0)), 2, "partial EXP does not level")
	_eq(int(_unit(V1).get("exp", 0)), 100, "partial EXP stored")

	before = _snapshot()
	_result_fail(progression.call("use_pot", V1, "hp", -1), "invalid_pot", "negative pot count")
	_result_fail(progression.call("use_pot", V1, "speed", 1), "invalid_pot", "unknown pot stat")
	_assert_unchanged(before, "invalid pot requests")

	result = progression.call("use_pot", V1, "hp", 1)
	_ok(bool(result.get("ok", false)), "one HP pot applied")
	_eq(int(result.get("applied", 0)), 20, "HP pot amount from rules")
	_eq(int(result.get("total", 0)), 20, "HP allocation total")
	_eq(int(result.get("cap", 0)), 500, "HP pot cap from fixture")
	_eq(_resource("item:GL:810001@base"), 39, "one pot item consumed")

	result = progression.call("use_pot", V1, "hp", 100)
	_ok(bool(result.get("ok", false)), "bulk pot clamps to cap")
	_eq(int(result.get("applied", 0)), 480, "bulk pot applies remaining capacity")
	_eq(int(result.get("total", 0)), 500, "HP pot reaches cap")
	_eq(_resource("item:GL:810001@base"), 15, "only required pot items consumed")
	before = _snapshot()
	_result_fail(progression.call("use_pot", V1, "hp", 1), "pot_cap_reached", "pot beyond cap")
	_assert_unchanged(before, "pot at cap")

	result = progression.call("gain_exp", V2, 1000000000000)
	_ok(bool(result.get("ok", false)), "large EXP accepted")
	_eq(int(result.get("level", 0)), 80, "level stops at star 5 cap")
	_ok(bool(result.get("cap_reached", false)), "cap_reached reported")
	_eq(int(_unit(V2).get("level", 0)), 80, "capped level persisted")
	_eq(int(progression.call("cost_summary", V2).get("level_cap", 0)), 80, "cost summary reports cap")
	_ok(int(_unit(V2).get("exp", 0)) >= 0, "EXP remainder is non-negative")
	return true


# --- duplicate conversion -------------------------------------------------------

func test_duplicate_conversion_resource_safety() -> bool:
	_fresh()
	var progression: RefCounted = state.get("progression") as RefCounted
	var inventory: RefCounted = state.get("inventory") as RefCounted
	var before: String = _snapshot()
	_result_fail(progression.call("convert_duplicate", "unit:GL:999999:1@base"), "unknown_instance", "convert unknown instance")
	_assert_unchanged(before, "unknown conversion")

	_ok(bool(state.call("mutate_unit_instance", V6, {"locked": true})), "lock second copy")
	before = _snapshot()
	_result_fail(progression.call("convert_duplicate", V6), "locked", "convert locked copy")
	_assert_unchanged(before, "locked conversion")
	_ok(bool(state.call("mutate_unit_instance", V6, {"locked": false})), "unlock second copy")

	_ok(bool(inventory.call("equip", V6, "weapon", BLADE).get("ok", false)), "equip blade on second copy")
	before = _snapshot()
	_result_fail(progression.call("convert_duplicate", V6), "equipped", "convert equipped copy")
	_assert_unchanged(before, "equipped conversion")
	_ok(bool(inventory.call("unequip", V6, "weapon").get("ok", false)), "unequip second copy")

	_ok(bool(state.call("mutate_unit_instance", V6, {"favorite": true})), "favorite second copy")
	_ok(bool(_unit(V6).get("favorite", false)), "favorite persisted on the copy")
	var profile: Dictionary = _data().get("profile", {})
	profile["favorites"] = [V6]
	_data()["profile"] = profile
	var favorites_before: Array = (_data().get("profile", {}) as Dictionary).get("favorites", [])
	_ok(favorites_before.has(V6), "favorite recorded before conversion")
	var fragments_before: int = _resource("fragment:GL:910101@base")
	_eq(fragments_before, 0, "fragment starts at zero")
	var result: Dictionary = progression.call("convert_duplicate", V6)
	_ok(bool(result.get("ok", false)), "duplicate converted")
	_eq(str(result.get("fragment_id", "")), "fragment:GL:910101@base", "fragment ID derived from unit identity")
	_eq(int(result.get("fragments", 0)), 50, "fixture fragment yield")
	_eq(_resource("fragment:GL:910101@base"), 50, "fragments granted")
	_eq(_owned().size(), 5, "converted copy removed")
	_ok(_unit(V6).is_empty(), "converted instance no longer owned")
	_eq(_count_definition(VANGUARD_DEF), 1, "one vanguard copy remains")
	var favorites_after: Array = (_data().get("profile", {}) as Dictionary).get("favorites", [])
	_ok(not favorites_after.has(V6), "favorites cleaned up")

	before = _snapshot()
	_result_fail(progression.call("convert_duplicate", V1), "not_duplicate", "convert sole remaining copy")
	_assert_unchanged(before, "non-duplicate conversion")
	return true


# --- awakening, NV, NV+, EX -----------------------------------------------------

func test_awakening_star_nv_ex_nv_plus() -> bool:
	_fresh()
	var progression: RefCounted = state.get("progression") as RefCounted
	state.call("grant", {"gil": 3000000, "fragment:GL:910101@base": 500})
	var def: Dictionary = ContentRepository.call("get_unit_definition", VANGUARD_DEF)
	var summary: Dictionary = progression.call("cost_summary", V1)
	_eq(JSON.stringify(summary.get("star", {})), JSON.stringify(def.get("awakening", {}).get("6", {})), "star 6 cost summary")
	_eq(JSON.stringify(summary.get("nv", {})), JSON.stringify(def.get("nv", {})), "NV cost summary")
	_eq(JSON.stringify(summary.get("ex", {})), JSON.stringify(def.get("ex", {}).get("1", {})), "EX +1 cost summary")
	_eq(JSON.stringify(summary.get("nv_plus", {})), JSON.stringify(def.get("nv_plus", {})), "NV+ cost summary")
	_eq(int((def.get("ex", {}) as Dictionary).get("1", {}).get("cost", {}).get("fragment:GL:910101@base", 0)), 25, "EX +1 fragment cost is 25")
	_eq(int((def.get("ex", {}) as Dictionary).get("2", {}).get("cost", {}).get("fragment:GL:910101@base", 0)), 50, "EX +2 fragment cost is 50")
	_eq(int((def.get("ex", {}) as Dictionary).get("3", {}).get("cost", {}).get("fragment:GL:910101@base", 0)), 100, "EX +3 fragment cost is 100")
	_eq(int((def.get("nv_plus", {}) as Dictionary).get("cost", {}).get("fragment:GL:910101@base", 0)), 150, "NV+ fragment cost is 150")

	var before: String = _snapshot()
	_result_fail(progression.call("awaken_star", V1, 9), "no_transition", "missing star transition")
	_result_fail(progression.call("awaken_star", V1, 7), "requirement", "skip from star 5 to 7")
	_result_fail(progression.call("awaken_nv", V1), "requirement", "NV before star 7")
	_result_fail(progression.call("awaken_ex", V1, 1), "nv_required", "EX before NV")
	_result_fail(progression.call("awaken_ex", V1, 4), "invalid_ex", "EX +4 out of range")
	_result_fail(progression.call("shift_form", V1), "nv_required", "shift before NV")
	_result_fail(progression.call("awaken_nv_plus", V1), "requirement", "NV+ before EX +3")
	_result_fail(progression.call("awaken_nv", JP1), "no_transition", "JP unit without NV transition")
	_assert_unchanged(before, "invalid awakening transitions")

	var gil_before: int = _resource("gil")
	var result: Dictionary = progression.call("awaken_star", V1, 6)
	_ok(bool(result.get("ok", false)), "awaken to star 6")
	_eq(int(_unit(V1).get("star", 0)), 6, "star 6 persisted")
	_eq(_resource("gil"), gil_before - 50000, "star 6 gil cost charged")
	_eq(_resource("material:GL:900101@base"), 115, "star 6 material charged")
	_ok((_unit(V1).get("learned_abilities", []) as Array).has("ability:GL:941101@base"), "star-gated ability learned")
	gil_before = _resource("gil")
	result = progression.call("awaken_star", V1, 7)
	_ok(bool(result.get("ok", false)), "awaken to star 7")
	_eq(int(_unit(V1).get("star", 0)), 7, "star 7 persisted")
	_eq(_resource("gil"), gil_before - 150000, "star 7 gil cost charged")
	_eq(_resource("material:GL:900102@base"), 70, "star 7 material charged")

	gil_before = _resource("gil")
	result = progression.call("awaken_nv", V1)
	_ok(bool(result.get("ok", false)), "NV awakening succeeds")
	_eq(str(result.get("label", "")), "UNVERIFIED_RULE", "NV rule explicitly unverified")
	_ok(bool(_unit(V1).get("nv_unlocked", false)), "NV flag set")
	_eq(int(_unit(V1).get("star", 0)), 7, "NV retains star 7")
	_eq(str(_unit(V1).get("definition_id", "")), "unit:GL:910101@brave_shift", "NV switches definition")
	_eq(str(_unit(V1).get("form", "")), "brave_shift", "NV switches form")
	var nv_cost: Dictionary = result.get("cost", {})
	_eq(int(nv_cost.get("gil", 0)), 300000, "NV gil cost from data")
	_eq(int(nv_cost.get("material:GL:900103@base", 0)), 20, "NV material cost from data")
	_eq(_resource("gil"), gil_before - int(nv_cost.get("gil", 0)), "NV gil cost charged")
	_eq(_resource("material:GL:900103@base"), 40 - int(nv_cost.get("material:GL:900103@base", 0)), "NV material charged")
	before = _snapshot()
	_result_fail(progression.call("awaken_nv", V1), "already_nv", "repeat NV")
	_assert_unchanged(before, "repeat NV")

	result = progression.call("shift_form", V1)
	_ok(bool(result.get("ok", false)), "shift back to base form")
	_eq(str(_unit(V1).get("form", "")), "base", "base form restored")
	_eq(str(result.get("label", "")), "REMASTERED_DESIGN", "shift is remastered design")
	_eq(str(_unit(V1).get("definition_id", "")), VANGUARD_DEF, "base definition restored")

	before = _snapshot()
	_result_fail(progression.call("awaken_ex", V1, 3), "requirement", "EX +3 before EX +1")
	_assert_unchanged(before, "out-of-order EX")
	var fragments_before: int = _resource("fragment:GL:910101@base")
	gil_before = _resource("gil")
	result = progression.call("awaken_ex", V1, 1)
	_ok(bool(result.get("ok", false)), "EX +1 succeeds")
	_eq(int(result.get("ex_level", -1)), 1, "EX +1 level reported")
	_eq(int(_unit(V1).get("ex_level", 0)), 1, "EX +1 persisted")
	_eq(_resource("fragment:GL:910101@base"), fragments_before - 25, "EX +1 fragment cost charged")
	_eq(_resource("gil"), gil_before - 100000, "EX +1 gil cost charged")
	fragments_before = _resource("fragment:GL:910101@base")
	result = progression.call("awaken_ex", V1, 2)
	_ok(bool(result.get("ok", false)), "EX +2 succeeds")
	_eq(int(_unit(V1).get("ex_level", 0)), 2, "EX +2 persisted")
	_eq(_resource("fragment:GL:910101@base"), fragments_before - 50, "EX +2 fragment cost charged")
	fragments_before = _resource("fragment:GL:910101@base")
	_result_fail(progression.call("awaken_nv_plus", V1), "requirement", "NV+ before EX +3")
	result = progression.call("awaken_ex", V1, 3)
	_ok(bool(result.get("ok", false)), "EX +3 succeeds")
	_eq(int(_unit(V1).get("ex_level", 0)), 3, "EX +3 persisted")
	_eq(_resource("fragment:GL:910101@base"), fragments_before - 100, "EX +3 fragment cost charged")
	before = _snapshot()
	_result_fail(progression.call("awaken_ex", V1, 3), "already_unlocked", "repeat EX +3")
	_assert_unchanged(before, "repeat EX")

	fragments_before = _resource("fragment:GL:910101@base")
	gil_before = _resource("gil")
	result = progression.call("awaken_nv_plus", V1)
	_ok(bool(result.get("ok", false)), "NV+ succeeds after EX +3")
	_eq(str(result.get("label", "")), "UNVERIFIED_RULE", "NV+ rule explicitly unverified")
	_ok(bool(_unit(V1).get("nv_plus", false)), "NV+ flag set")
	_eq(_resource("fragment:GL:910101@base"), fragments_before - 150, "NV+ fragment cost charged")
	_eq(_resource("gil"), gil_before - 750000, "NV+ gil cost charged")
	before = _snapshot()
	_result_fail(progression.call("awaken_nv_plus", V1), "already_nv_plus", "repeat NV+")
	_assert_unchanged(before, "repeat NV+")

	_data().get("resources", {})["gil"] = 0
	before = _snapshot()
	_result_fail(progression.call("awaken_star", V2, 6), "insufficient_resources", "awakening without gil")
	_assert_unchanged(before, "unaffordable awakening")
	return true


# --- trust and reward claims ----------------------------------------------------

func test_trust_and_tmr_stmr_claims() -> bool:
	_fresh()
	var progression: RefCounted = state.get("progression") as RefCounted
	var rules: Dictionary = ContentRepository.call("get_progression_rules")
	_eq(int(rules.get("max_trust", 0)), 300, "fixture trust cap")

	var before: String = _snapshot()
	_result_fail(progression.call("give_trust", V1, -1), "invalid_amount", "negative trust")
	_assert_unchanged(before, "negative trust")

	var result: Dictionary = progression.call("give_trust", V1, 1000)
	_ok(bool(result.get("ok", false)), "trust gain accepted")
	_eq(int(_unit(V1).get("trust", 0)), 300, "trust clamped to fixture cap")
	_eq(int(result.get("cap", 0)), 300, "trust cap reported")

	before = _snapshot()
	result = progression.call("claim_tmr", V1)
	_ok(bool(result.get("ok", false)), "vanguard ability TMR claimed")
	_eq(str(result.get("reward_id", "")), "ability:GL:940101@base", "vanguard ability TMR reward ID")
	_eq(state.call("inventory_section", "abilities").size(), 1, "ability TMR added to inventory")
	var ability_tmr_uid: String = str(result.get("uid", ""))
	_eq(str(state.call("find_inventory_entry", ability_tmr_uid).get("source", "")), "tmr_claim", "ability TMR entry source")
	_ok(bool(_unit(V1).get("tmr_claimed", false)), "ability TMR flag persisted")
	before = _snapshot()
	_result_fail(progression.call("claim_tmr", V1), "already_claimed", "repeat ability TMR")
	_assert_unchanged(before, "repeat ability TMR claim")

	result = progression.call("give_trust", V2, 120)
	_ok(bool(result.get("ok", false)), "arcanist trust gained")
	_eq(int(_unit(V2).get("trust", 0)), 120, "arcanist trust persisted")
	before = _snapshot()
	_result_fail(progression.call("claim_stmr", V2), "trust_required", "STMR below trust threshold")
	_assert_unchanged(before, "premature STMR")

	var materia_before: int = state.call("inventory_section", "materia").size()
	result = progression.call("claim_tmr", V2)
	_ok(bool(result.get("ok", false)), "arcanist TMR claimed")
	_eq(str(result.get("reward_id", "")), "materia:GL:600001@base", "TMR reward ID")
	_eq(state.call("inventory_section", "materia").size(), materia_before + 1, "TMR added to inventory")
	_ok(bool(_unit(V2).get("tmr_claimed", false)), "TMR claim flag persisted")
	var tmr_uid: String = str(result.get("uid", ""))
	_eq(str(state.call("find_inventory_entry", tmr_uid).get("source", "")), "tmr_claim", "TMR entry source")
	before = _snapshot()
	_result_fail(progression.call("claim_tmr", V2), "already_claimed", "repeat TMR")
	_assert_unchanged(before, "repeat TMR claim")

	result = progression.call("give_trust", V2, 80)
	_ok(bool(result.get("ok", false)), "remaining trust gained")
	_eq(int(_unit(V2).get("trust", 0)), 200, "STMR trust threshold reached")
	materia_before = state.call("inventory_section", "materia").size()
	result = progression.call("claim_stmr", V2)
	_ok(bool(result.get("ok", false)), "arcanist STMR claimed")
	_eq(str(result.get("reward_id", "")), "materia:GL:600002@base", "STMR reward ID")
	_eq(state.call("inventory_section", "materia").size(), materia_before + 1, "STMR added to inventory")
	_ok(bool(_unit(V2).get("stmr_claimed", false)), "STMR claim flag persisted")
	var stmr_uid: String = str(result.get("uid", ""))
	_eq(str(state.call("find_inventory_entry", stmr_uid).get("source", "")), "stmr_claim", "STMR entry source")
	before = _snapshot()
	_result_fail(progression.call("claim_stmr", V2), "already_claimed", "repeat STMR")
	_assert_unchanged(before, "repeat STMR claim")
	return true


# --- equipment, ownership, materia, stat drift ----------------------------------

func test_equipment_restrictions_and_stat_recalculation() -> bool:
	_fresh()
	var inventory: RefCounted = state.get("inventory") as RefCounted
	var base_stats: Dictionary = _stats(V1)
	_eq(int(base_stats.get("hp", 0)), 5600, "base HP from definition")
	_eq(int(base_stats.get("mp", 0)), 100, "base MP from definition")
	_eq(int(base_stats.get("atk", 0)), 450, "base ATK from definition")
	_eq(int(base_stats.get("def", 0)), 320, "base DEF from definition")
	_eq(int(base_stats.get("mag", 0)), 180, "base MAG from definition")
	_eq(int(base_stats.get("spr", 0)), 250, "base SPR from definition")

	_eq((inventory.call("inventory_for_slot", "weapon") as Array).size(), 3, "weapon inventory count")
	_eq((inventory.call("inventory_for_slot", "armor") as Array).size(), 2, "armor inventory count")
	_eq((inventory.call("inventory_for_slot", "accessory") as Array).size(), 2, "accessory inventory count")
	_eq((inventory.call("inventory_for_slot", "materia_0") as Array).size(), 7, "materia inventory count")
	_eq((state.call("inventory_section", "vision_cards") as Array).size(), 3, "vision card inventory count")

	var before: String = _snapshot()
	_result_fail(inventory.call("equip", V1, "weapon", ARMOR), "restriction", "armor in weapon slot")
	_result_fail(inventory.call("equip", V1, "weapon", SHIELD), "restriction", "shield role restriction")
	_result_fail(inventory.call("equip", JP1, "armor", BLADE), "restriction", "blade in armor slot")
	_assert_unchanged(before, "restricted equipment")

	_ok(bool(inventory.call("equip", V5, "weapon", SHIELD).get("ok", false)), "shield equips on defensive unit")
	_ok(bool(inventory.call("equip", V1, "weapon", BLADE).get("ok", false)), "blade equips on vanguard")
	_eq(int(_stats(V1).get("atk", 0)), 530, "blade ATK reflected in build")
	before = _snapshot()
	_result_fail(inventory.call("equip", V2, "weapon", BLADE), "already_equipped", "unique blade cannot be shared")
	_result_fail(inventory.call("sell", BLADE), "equipped", "equipped blade cannot be sold")
	_assert_unchanged(before, "unique ownership violations")
	_ok(bool(inventory.call("unequip", V1, "weapon").get("ok", false)), "blade unequipped")
	_eq(JSON.stringify(_stats(V1)), JSON.stringify(base_stats), "stats return after blade unequip")

	_ok(bool(inventory.call("toggle_lock", BLADE).get("ok", false)), "blade locked")
	before = _snapshot()
	_result_fail(inventory.call("equip", V1, "weapon", BLADE), "locked", "locked item cannot be equipped")
	_result_fail(inventory.call("sell", BLADE), "locked", "locked item cannot be sold")
	_assert_unchanged(before, "locked item violations")
	_ok(bool(inventory.call("toggle_lock", BLADE).get("ok", false)), "blade unlocked")
	_ok(bool(inventory.call("equip", V2, "weapon", BLADE).get("ok", false)), "blade re-equipped on another unit")
	_ok(bool(inventory.call("unequip", V2, "weapon").get("ok", false)), "blade unequipped from other unit")

	_ok(bool(inventory.call("equip", V1, "accessory", ACCESSORY).get("ok", false)), "accessory equipped")
	_eq(JSON.stringify((_resolve(V1).get("percent", {}) as Dictionary)), JSON.stringify({"atk": 5}), "accessory passive percent")
	_eq(int(_stats(V1).get("atk", 0)), 504, "accessory flat and percent stats combined")
	_eq(int(_stats(V1).get("mag", 0)), 210, "accessory MAG applied")
	_ok(bool(inventory.call("unequip", V1, "accessory").get("ok", false)), "accessory unequipped")
	_eq(JSON.stringify(_stats(V1)), JSON.stringify(base_stats), "no drift after accessory cycle")

	_ok(bool(inventory.call("equip_materia", V1, 0, MAT_ATK_1).get("ok", false)), "attack materia equipped")
	_eq(JSON.stringify((_resolve(V1).get("percent", {}) as Dictionary)), JSON.stringify({"atk": 10}), "attack materia percent")
	_eq(int(_stats(V1).get("atk", 0)), 495, "attack materia raises ATK")
	before = _snapshot()
	_result_fail(inventory.call("equip_materia", V1, 1, MAT_ATK_2), "stack_limit", "attack materia stack limit")
	_assert_unchanged(before, "materia stack violation")
	_ok(bool(inventory.call("equip_materia", V2, 1, MAT_ATK_2).get("ok", false)), "second copy equips on another unit")
	_ok(bool(inventory.call("unequip_materia", V1, 0).get("ok", false)), "attack materia unequipped")
	_eq(JSON.stringify(_stats(V1)), JSON.stringify(base_stats), "no drift after materia cycle")

	_ok(bool(inventory.call("grant_item", "materia:GL:600003@base", "test").get("ok", false)), "second SPR materia granted")
	var spr_uid: String = _inventory_uid("materia:GL:600003@base")
	var spr_entries: Array[Dictionary] = []
	for entry: Dictionary in state.call("inventory_section", "materia"):
		if str(entry.get("definition_id", "")) == "materia:GL:600003@base":
			spr_entries.append(entry)
	_eq(spr_entries.size(), 2, "two SPR materia copies owned")
	_ok(bool(inventory.call("equip_materia", V1, 0, MAT_SPR_1).get("ok", false)), "first SPR materia equipped")
	_ok(bool(inventory.call("equip_materia", V1, 1, spr_uid).get("ok", false)), "second SPR materia stacks")
	_eq(JSON.stringify((_resolve(V1).get("percent", {}) as Dictionary)), JSON.stringify({"spr": 16}), "SPR stack totals 16 percent")
	_eq(int(_stats(V1).get("spr", 0)), 290, "SPR stack applied")
	_ok(bool(inventory.call("unequip_materia", V1, 0).get("ok", false)), "first SPR materia removed")
	_ok(bool(inventory.call("unequip_materia", V1, 1).get("ok", false)), "second SPR materia removed")
	_eq(JSON.stringify(_stats(V1)), JSON.stringify(base_stats), "no drift after SPR stack cycle")

	for cycle: int in range(3):
		_ok(bool(inventory.call("equip", V1, "weapon", BLADE).get("ok", false)), "cycle %d equip" % cycle)
		_ok(bool(inventory.call("equip_materia", V1, 0, MAT_ATK_1).get("ok", false)), "cycle %d materia" % cycle)
		_ok(bool(inventory.call("unequip_materia", V1, 0).get("ok", false)), "cycle %d unequip materia" % cycle)
		_ok(bool(inventory.call("unequip", V1, "weapon").get("ok", false)), "cycle %d unequip" % cycle)
	_eq(JSON.stringify(_stats(V1)), JSON.stringify(base_stats), "repeated equip cycles do not drift stats")
	return true


# --- vision cards ---------------------------------------------------------------

func test_vision_card_assignment_and_level_bonuses() -> bool:
	_fresh()
	var inventory: RefCounted = state.get("inventory") as RefCounted
	var default_party: Dictionary = state.call("get_party", "default")
	default_party["slots"] = [V1, V2, V3, JP1, V5]
	default_party["leader_slot"] = 0
	state.call("set_party", "default", default_party)
	var base_atk: int = int(_stats(V1, "").get("atk", 0))
	_eq(base_atk, 450, "base ATK before vision card")
	var result: Dictionary = inventory.call("assign_vision_card", "default", VC_GL)
	_ok(bool(result.get("ok", false)), "GL vision card assigned")
	_eq(str(state.call("get_party", "default").get("vision_card", "")), VC_GL, "party stores assigned UID")
	_eq(JSON.stringify((_resolve(V1, "default").get("percent", {}) as Dictionary)), JSON.stringify({"atk": 23}), "card category passive plus leader skill")
	_eq(int(_stats(V1, "default").get("atk", 0)), 558, "vision card level 1 ATK bonus")
	_eq(int(_stats(V1, "default").get("hp", 0)), 5640, "vision card level 1 HP bonus")

	state.call("set_party", "alt", {"name_key": "party.preset.default", "slots": [V1, V2, V3, JP1, V5], "leader_slot": 0})
	var before: String = _snapshot()
	_result_fail(inventory.call("assign_vision_card", "alt", VC_GL), "already_assigned", "card assigned twice")
	_assert_unchanged(before, "duplicate vision card assignment")
	_ok(bool(inventory.call("unassign_vision_card", "default").get("ok", false)), "card unassigned")
	_eq(JSON.stringify((_resolve(V1, "default").get("percent", {}) as Dictionary)), JSON.stringify({"atk": 20}), "only leader remains after unassign")
	_ok(bool(inventory.call("assign_vision_card", "alt", VC_GL).get("ok", false)), "card assigned to second party")

	var gil_before: int = _resource("gil")
	var material_before: int = _resource("material:GL:900101@base")
	result = inventory.call("upgrade_vision_card", VC_GL)
	_ok(bool(result.get("ok", false)), "vision card upgraded")
	_eq(int(result.get("level", 0)), 2, "vision card reaches level 2")
	_eq(_resource("gil"), gil_before - 10000, "vision card gil cost")
	_eq(_resource("material:GL:900101@base"), material_before - 2, "vision card material cost")
	_eq(JSON.stringify((_resolve(V1, "alt").get("percent", {}) as Dictionary)), JSON.stringify({"atk": 26}), "card passive scales with level")
	_eq(int(_stats(V1, "alt").get("atk", 0)), 577, "level 2 card ATK bonus")

	_ok(bool(inventory.call("unassign_vision_card", "alt").get("ok", false)), "card removed before mismatch test")
	_ok(bool(inventory.call("assign_vision_card", "alt", VC_ARCANE).get("ok", false)), "arcane card assigned")
	var resolved: Dictionary = _resolve(V1, "alt")
	_ok(_has_diagnostic(resolved, "build.error.vision_category"), "category mismatch diagnosed with stable key")
	_eq(JSON.stringify((resolved.get("percent", {}) as Dictionary)), JSON.stringify({"atk": 20}), "mismatched card passive not applied")
	_eq(int((resolved.get("stats", {}) as Dictionary).get("mag", 0)), 185, "mismatched card still grants flat stats")

	_ok(bool(inventory.call("unassign_vision_card", "alt").get("ok", false)), "arcane card unassigned")
	_ok(bool(inventory.call("assign_vision_card", "alt", VC_JP).get("ok", false)), "JP card assigned")
	state.call("set_party", "third", {"name_key": "party.preset.default", "slots": [V1, V2, V3, JP1, V5], "leader_slot": 0})
	before = _snapshot()
	_result_fail(inventory.call("assign_vision_card", "third", VC_JP), "already_assigned", "card cannot be assigned twice")
	_assert_unchanged(before, "duplicate card assignment")
	_ok(bool(inventory.call("unassign_vision_card", "alt").get("ok", false)), "JP card unassigned")
	_ok(bool(inventory.call("toggle_lock", VC_JP).get("ok", false)), "JP card locked")
	before = _snapshot()
	_result_fail(inventory.call("assign_vision_card", "alt", VC_JP), "locked", "locked card cannot be assigned")
	_result_fail(inventory.call("upgrade_vision_card", VC_JP), "locked", "locked card cannot be upgraded")
	_assert_unchanged(before, "locked vision card violations")

	_ok(bool(inventory.call("assign_vision_card_to_unit", V2, VC_ARCANE).get("ok", false)),
		"vision card assigned directly to unit")
	_ok(bool(inventory.call("assign_vision_card", "default", VC_GL).get("ok", false)),
		"legacy party card assigned for precedence check")
	var unit_card: Dictionary = _resolve(V2, "default")
	_eq(JSON.stringify((unit_card.get("percent", {}) as Dictionary)), JSON.stringify({"mag": 3}),
		"unit card outranks legacy party card")
	_ok((unit_card.get("labels", {}) as Dictionary).has("vision_card:GL:700003@base"),
		"vision card source label recorded")
	before = _snapshot()
	_result_fail(inventory.call("assign_vision_card_to_unit", V1, VC_ARCANE),
		"already_assigned", "unit card cannot be reused")
	_assert_unchanged(before, "duplicate unit vision card assignment")
	_ok(bool(inventory.call("unassign_vision_card_from_unit", V2).get("ok", false)),
		"unit vision card unassigned")
	var party_card: Dictionary = _resolve(V2, "default")
	_eq(JSON.stringify((party_card.get("percent", {}) as Dictionary)), JSON.stringify({"atk": 6}),
		"legacy level-2 party card applies after unit card is removed")
	return true


# --- leader skills, categories and form builds ---------------------------------

func test_leader_skill_and_brave_shift_builds() -> bool:
	_fresh()
	var progression: RefCounted = state.get("progression") as RefCounted
	var default_party: Dictionary = state.call("get_party", "default")
	default_party["slots"] = [V1, V2, V3, JP1, V5]
	default_party["leader_slot"] = 0
	state.call("set_party", "default", default_party)
	var vanguard_leader: Dictionary = _resolve(V1, "default")
	_eq(JSON.stringify((vanguard_leader.get("percent", {}) as Dictionary)), JSON.stringify({"atk": 20}), "default leader grants ATK")
	_ok((vanguard_leader.get("labels", {}) as Dictionary).has("leader:GL:910101@base"), "leader label present")
	_eq(int(_stats(V1, "default").get("atk", 0)), 540, "leader ATK bonus applied")
	var arcanist_non_leader: Dictionary = _resolve(V2, "default")
	_eq(JSON.stringify((arcanist_non_leader.get("percent", {}) as Dictionary)), JSON.stringify({}), "non-leader gets no leader bonus")

	var party: Dictionary = state.call("get_party", "default")
	party["leader_slot"] = 1
	state.call("set_party", "default", party)
	var arcanist_leader: Dictionary = _resolve(V2, "default")
	_eq(JSON.stringify((arcanist_leader.get("percent", {}) as Dictionary)), JSON.stringify({"mag": 25}), "category-filtered leader skill")
	_ok((arcanist_leader.get("labels", {}) as Dictionary).has("leader:GL:910102@base"), "arcanist leader label")
	_eq(int(_stats(V2, "default").get("mag", 0)), 575, "leader MAG bonus applied")
	_eq(JSON.stringify((_resolve(V1, "default").get("percent", {}) as Dictionary)), JSON.stringify({}), "former leader loses bonus")

	var before: String = _snapshot()
	_result_fail(progression.call("shift_form", V1), "nv_required", "shift requires NV")
	_assert_unchanged(before, "pre-NV shift")

	state.call("grant", {"gil": 1000000, "fragment:GL:910101@base": 200})
	_ok(bool(progression.call("awaken_star", V1, 6).get("ok", false)), "star 6 for form test")
	_ok(bool(progression.call("awaken_star", V1, 7).get("ok", false)), "star 7 for form test")
	_ok(bool(progression.call("awaken_nv", V1).get("ok", false)), "NV for form test")
	var shifted: Dictionary = _resolve(V1)
	_eq(str(shifted.get("form", "")), "brave_shift", "NV form resolves as brave_shift")
	_eq(str(shifted.get("definition_id", "")), "unit:GL:910101@brave_shift", "NV definition in build")
	_eq(int((shifted.get("stats", {}) as Dictionary).get("atk", 0)), 340, "brave_shift ATK base")
	_eq(int((shifted.get("stats", {}) as Dictionary).get("mag", 0)), 520, "brave_shift MAG base")
	_ok((shifted.get("labels", {}) as Dictionary).has("passive:GL:910101@brave_shift"), "brave_shift passive label present")
	_eq(str((shifted.get("labels", {}) as Dictionary).get("passive:GL:910101@brave_shift", "")), "REMASTERED_DESIGN", "brave_shift form label value")
	_ok((shifted.get("abilities", []) as Array).has("ability:GL:941102@brave_shift"), "brave_shift ability keeps composite ID")
	_ok(not (shifted.get("labels", {}) as Dictionary).has(SLB_VANGUARD), "SLB absent at EX +0")

	_ok(bool(progression.call("shift_form", V1).get("ok", false)), "shift back to base")
	var restored: Dictionary = _resolve(V1)
	_eq(str(restored.get("form", "")), "base", "base form restored in build")
	_eq(int((restored.get("stats", {}) as Dictionary).get("atk", 0)), 450, "base ATK restored")
	_eq(int((restored.get("stats", {}) as Dictionary).get("mag", 0)), 180, "base MAG restored")
	_ok((_unit(V1).get("learned_abilities", []) as Array).has("ability:GL:931101@base"), "base form ability learned")
	_ok((restored.get("labels", {}) as Dictionary).has("passive:GL:910101@base"), "base form passive label present")

	_ok(bool(progression.call("awaken_ex", V1, 1).get("ok", false)), "EX +1 for SLB")
	var slb_build: Dictionary = _resolve(V1)
	_eq(str((slb_build.get("labels", {}) as Dictionary).get(SLB_VANGUARD, "")), "UNVERIFIED_RULE", "SLB label is unverified")
	_ok(bool(progression.call("awaken_ex", V1, 2).get("ok", false)), "EX +2 for overdrive")
	var overdrive_build: Dictionary = _resolve(V1)
	_eq(str((overdrive_build.get("labels", {}) as Dictionary).get(OVERDRIVE_VANGUARD, "")), "UNVERIFIED_RULE", "overdrive label is unverified")
	_eq(str((overdrive_build.get("labels", {}) as Dictionary).get(OVERDRIVE_VANGUARD, "")), "UNVERIFIED_RULE", "overdrive label is unverified")
	var combatant: Dictionary = ContentRepository.call("get_battle_combatant", VANGUARD_DEF)
	_ok(not combatant.is_empty(), "battle combatant fixture available")
	var built: Dictionary = (state.get("build_resolver") as RefCounted).call("build_combatant_def", V1)
	_eq(str(built.get("id", "")), V1, "combatant ID is owned instance")
	_eq(int(built.get("level", 0)), 1, "combatant level from instance")
	_eq(str((built.get("mechanic_labels", {}) as Dictionary).get(SLB_VANGUARD, "")), "UNVERIFIED_RULE", "combatant carries mechanic label")
	_ok((built.get("abilities", []) as Array).has(OVERDRIVE_VANGUARD), "combatant includes EX ability")

	_ok(bool(progression.call("shift_form", V1).get("ok", false)), "shift to brave_shift after EX")
	var shifted_ex: Dictionary = _resolve(V1)
	_eq(str(shifted_ex.get("form", "")), "brave_shift", "form-specific build after shift")
	_eq(str(shifted_ex.get("definition_id", "")), "unit:GL:910101@brave_shift", "form-specific definition after shift")
	_eq(int((shifted_ex.get("stats", {}) as Dictionary).get("atk", 0)), 340, "form-specific ATK after shift")
	_ok(not (shifted_ex.get("labels", {}) as Dictionary).has(SLB_VANGUARD), "SLB belongs to base form definition")
	_ok((shifted_ex.get("labels", {}) as Dictionary).has("passive:GL:910101@brave_shift"), "shifted form label retained")
	_ok((shifted_ex.get("abilities", []) as Array).has("ability:GL:941102@brave_shift"), "EX build keeps form-specific ability ID")
	return true


# --- data-driven mechanic labels ------------------------------------------------

func test_advanced_mechanic_labels() -> bool:
	var labels_file: Dictionary = _read_json_dict("res://data/phase3/mechanic_labels.json")
	_eq(str(labels_file.get("fixture_marker", "")), "SYNTHETIC_FIXTURE", "mechanic labels fixture marker")
	var mechanics: Dictionary = labels_file.get("mechanics", {})
	var repository_labels: Dictionary = ContentRepository.call("get_mechanic_labels")
	_eq(JSON.stringify(repository_labels), JSON.stringify(mechanics), "repository exposes mechanic label file verbatim")
	_eq(str((mechanics.get("brave_shift", {}) as Dictionary).get("label", "")), "REMASTERED_DESIGN", "brave shift evidence label")
	_eq(str((mechanics.get("super_limit_burst", {}) as Dictionary).get("label", "")), "UNVERIFIED_RULE", "SLB evidence label")
	_eq(str((mechanics.get("overdrive", {}) as Dictionary).get("label", "")), "UNVERIFIED_RULE", "overdrive evidence label")
	_eq(str((mechanics.get("dual_wield", {}) as Dictionary).get("label", "")), "VERIFIED_RULE", "dual wield evidence label")
	_eq(str((mechanics.get("multicast", {}) as Dictionary).get("label", "")), "PARTIAL_RULE", "multicast evidence label")
	_eq(str((mechanics.get("leader_skill", {}) as Dictionary).get("label", "")), "REMASTERED_DESIGN", "leader skill evidence label")
	_eq(str((mechanics.get("vision_card_bonuses", {}) as Dictionary).get("label", "")), "REMASTERED_DESIGN", "vision card evidence label")
	_ok(not str((mechanics.get("dual_wield", {}) as Dictionary).get("note", "")).is_empty(), "evidence note retained")

	var abilities_file: Dictionary = _read_json_dict("res://data/phase3/advanced_abilities.json")
	_eq(str(abilities_file.get("fixture_marker", "")), "SYNTHETIC_FIXTURE", "advanced abilities fixture marker")
	var abilities: Dictionary = abilities_file.get("abilities", {})
	_eq(abilities.size(), 7, "advanced ability count")
	var package: Dictionary = ContentRepository.call("get_battle_package")
	var package_abilities: Dictionary = package.get("abilities", {})
	for id: String in abilities.keys():
		_ok(package_abilities.has(id), "advanced ability merged into battle package: %s" % id)
		_eq(ContentRepository.call("get_advanced_ability", id), abilities[id], "ability definition matches file: %s" % id)
	var slb: Dictionary = ContentRepository.call("get_advanced_ability", SLB_VANGUARD)
	_ok(bool(slb.get("is_super_limit_burst", false)), "SLB flag present")
	_ok(bool(slb.get("is_limit_burst", false)), "SLB is a limit burst")
	_eq(int(slb.get("requires_ex", 0)), 1, "SLB EX requirement")
	_eq(int(slb.get("uses_per_battle", 0)), 1, "SLB uses per battle")
	_eq(str(slb.get("mechanic_label", "")), "UNVERIFIED_RULE", "SLB file label")
	_eq(str(slb.get("verification_status", "")), "SYNTHETIC_FIXTURE", "SLB fixture status")
	var overdrive: Dictionary = ContentRepository.call("get_advanced_ability", OVERDRIVE_VANGUARD)
	_ok(bool(overdrive.get("is_overdrive", false)), "overdrive flag present")
	_eq(int(overdrive.get("requires_ex", 0)), 2, "overdrive EX requirement")
	_eq(str(overdrive.get("mechanic_label", "")), "UNVERIFIED_RULE", "overdrive file label")
	var shift_ability: Dictionary = ContentRepository.call("get_advanced_ability", SHIFT_ABILITY)
	_eq(str(shift_ability.get("id", "")), SHIFT_ABILITY, "brave shift ability identity")
	_eq(str(shift_ability.get("mechanic_label", "")), "REMASTERED_DESIGN", "brave shift ability label")

	var rules_file: Dictionary = _read_json_dict("res://data/phase3/progression_rules.json")
	_eq(JSON.stringify(ContentRepository.call("get_progression_rules")), JSON.stringify(rules_file), "progression rules match fixture")
	_eq(str((rules_file.get("mechanic_labels", {}) as Dictionary).get("nv_awakening", "")), "UNVERIFIED_RULE", "NV rule label")
	_eq(str((rules_file.get("mechanic_labels", {}) as Dictionary).get("tmr_claim", "")), "REMASTERED_DESIGN", "TMR rule label")
	var manifest: Dictionary = ContentRepository.call("get_imported_manifest")
	_eq((manifest.get("active_packs", []) as Array).size(), 0, "no protected source packs active")
	_ok(bool((manifest.get("policy", {}) as Dictionary).get("region_keys_preserved", false)), "manifest preserves region keys")
	_ok(not bool((manifest.get("policy", {}) as Dictionary).get("allow_recovered_without_rights", true)), "no unreviewed recovered data enabled")
	return true


# --- failure semantics ----------------------------------------------------------

func test_invalid_transactions_preserve_resources() -> bool:
	_fresh()
	var progression: RefCounted = state.get("progression") as RefCounted
	var inventory: RefCounted = state.get("inventory") as RefCounted
	var before: String = _snapshot()
	_result_fail(progression.call("gain_exp", V1, -10), "invalid_amount", "negative EXP")
	_result_fail(progression.call("give_trust", V1, 0), "invalid_amount", "zero trust")
	_result_fail(progression.call("use_pot", V1, "hp", 0), "invalid_pot", "zero pot")
	_result_fail(progression.call("convert_duplicate", "missing"), "unknown_instance", "unknown duplicate")
	_result_fail(progression.call("awaken_star", V1, 8), "no_transition", "unknown star target")
	_result_fail(progression.call("awaken_ex", V1, 1), "nv_required", "EX without NV")
	_result_fail(progression.call("shift_form", JP1), "nv_required", "shift without NV")
	_result_fail(progression.call("claim_tmr", V1), "trust_required", "TMR without trust")
	_result_fail(inventory.call("equip", V1, "weapon", "owned:missing:0001@base"), "unknown_item", "unknown equipment")
	_result_fail(inventory.call("unequip", V1, "weapon"), "empty_slot", "unequip empty slot")
	_result_fail(inventory.call("equip_materia", V1, 9, MAT_ATK_1), "invalid_slot", "invalid materia slot")
	_result_fail(inventory.call("assign_vision_card", "missing", VC_GL), "unknown_party", "unknown party")
	_result_fail(inventory.call("sell", "owned:missing:0001@base"), "unknown_item", "sell unknown item")
	_result_fail(inventory.call("upgrade_vision_card", "owned:missing:0001@base"), "unknown_item", "upgrade unknown card")
	_result_fail(state.call("claim_battle_reward", {"victory": false}), "not_victory", "defeat reward claim")
	_assert_unchanged(before, "invalid transaction batch")

	_data().get("resources", {})["gil"] = 0
	_data().get("resources", {})["item:GL:810001@base"] = 0
	before = _snapshot()
	_result_fail(progression.call("awaken_star", V1, 6), "insufficient_resources", "unaffordable star awakening")
	_result_fail(progression.call("use_pot", V1, "hp", 1), "insufficient_items", "missing pot item")
	_result_fail(inventory.call("upgrade_vision_card", VC_GL), "insufficient_resources", "unaffordable card upgrade")
	_assert_unchanged(before, "unaffordable transactions")
	_eq(int(_unit(V1).get("star", 0)), 5, "failed awakening leaves star unchanged")
	_eq(int(_unit(V1).get("pot_allocations", {}).get("hp", 0)), 0, "failed pot leaves allocation unchanged")

	_ok(bool(inventory.call("toggle_lock", BLADE).get("ok", false)), "blade locked for consumption test")
	before = _snapshot()
	_result_fail(inventory.call("equip", V1, "weapon", BLADE), "locked", "locked blade equip")
	_result_fail(inventory.call("sell", BLADE), "locked", "locked blade sale")
	_assert_unchanged(before, "locked consumption")
	_ok(bool(inventory.call("toggle_lock", BLADE).get("ok", false)), "blade unlocked")

	_ok(bool(inventory.call("equip", V1, "weapon", BLADE).get("ok", false)), "blade equipped for consumption test")
	before = _snapshot()
	_result_fail(inventory.call("sell", BLADE), "equipped", "equipped blade sale")
	_assert_unchanged(before, "equipped consumption")
	_ok(bool(inventory.call("unequip", V1, "weapon").get("ok", false)), "blade unequipped")
	_ok(bool(state.call("mutate_unit_instance", V6, {"locked": true})), "second copy locked")
	before = _snapshot()
	_result_fail(progression.call("convert_duplicate", V6), "locked", "locked copy conversion")
	_assert_unchanged(before, "locked unit consumption")
	return true


# --- save migration -------------------------------------------------------------

func test_save_v2_to_v4_migration() -> bool:
	var fixture: Dictionary = _read_json_dict("res://data/save_fixtures/v2_player_state.json")
	_eq(int(fixture.get("version", 0)), 2, "fixture is a version 2 save")
	var migrated: Dictionary = state.call("migrate_state", fixture)
	_eq(int(fixture.get("version", 0)), 2, "migration does not mutate fixture")
	_eq(int(migrated.get("version", 0)), 4, "v2 migrated to v4")
	_ok(bool(state.call("validate_state", migrated)), "migrated state validates")
	var profile: Dictionary = migrated.get("profile", {})
	_eq(str(profile.get("locale", "")), "vi", "profile locale retained")
	_ok((profile.get("favorites", []) as Array).has("unit:GL:900001@base"), "profile favorites retained")
	var legacy: Dictionary = migrated.get("legacy", {})
	_eq(int(legacy.get("version", 0)), 2, "legacy version retained")
	_ok(legacy.has("settings_summary"), "settings summary retained")
	_ok(legacy.has("battle_progress"), "battle progress retained")
	var battle_progress: Dictionary = legacy.get("battle_progress", {})
	_eq(int(battle_progress.get("attempts", 0)), 2, "battle attempts preserved")
	_eq(int((battle_progress.get("clears", {}) as Dictionary).get(SKIRMISH, 0)), 1, "battle clears preserved")
	_eq(int((battle_progress.get("best_turns", {}) as Dictionary).get(SKIRMISH, 0)), 7, "best turns preserved")
	_eq(int(battle_progress.get("total_gil", 0)), 400, "battle gil preserved")
	_eq(int((battle_progress.get("item_counts", {}) as Dictionary).get("item:GL:800101@base", 0)), 1, "battle item progress preserved")
	_ok((migrated.get("resources", {}) as Dictionary).has("gil"), "new v3 resources field")
	_eq((migrated.get("owned_units", []) as Array).size(), 6, "new v3 owned units field")
	_ok((migrated.get("inventory", {}) as Dictionary).has("equipment"), "new v3 inventory field")
	_ok((migrated.get("inventory", {}) as Dictionary).has("materia"), "new v3 materia field")
	_ok((migrated.get("inventory", {}) as Dictionary).has("vision_cards"), "new v3 vision card field")
	_ok((migrated.get("parties", {}) as Dictionary).has("default"), "new v3 parties field")
	_eq((((migrated.get("parties", {}) as Dictionary).get("default", {}) as Dictionary).get("slots", []) as Array).size(), 5, "party slots present")
	_ok((migrated.get("claimed_rewards", {}) as Dictionary).is_empty(), "legacy claimed rewards field retained")
	for section: String in ["reward_claims", "mission_progress", "espers", "summon", "economy", "shops", "crafting"]:
		_ok((migrated.get(section, {}) as Dictionary).is_empty(), "v4 section backfilled: %s" % section)
	var runs: Dictionary = migrated.get("battle_runs", {})
	_ok(runs is Dictionary, "v4 battle_runs section backfilled")
	_ok(runs.has("legacy"), "legacy battle progress mapped into battle_runs")
	_eq(int((runs.get("legacy", {}) as Dictionary).get("attempts", 0)), 2,
		"legacy battle attempts retained in battle_runs")
	_eq(int(migrated.get("next_unit_serial", 0)), 7, "new unit serial field")
	_eq(int(migrated.get("next_equip_serial", 0)), 1, "new equipment serial field")

	var json_roundtrip: Variant = JSON.parse_string(JSON.stringify(migrated))
	_ok(json_roundtrip is Dictionary, "migrated state serializes to JSON")
	_ok(bool(state.call("validate_state", json_roundtrip as Dictionary)), "JSON round-trip still validates")
	var future: Dictionary = fixture.duplicate(true)
	future["version"] = 12
	_ok((state.call("migrate_state", future) as Dictionary).is_empty(), "newer player save refused")
	_eq(str(state.get("last_error")), "save.error.newer", "newer save error key")
	_eq(int((state.call("migrate_state", {}) as Dictionary).get("version", 0)), 4, "empty save gets v4 defaults")
	return true


# --- locale ---------------------------------------------------------------------

func test_locale_fallback_and_localized_text() -> bool:
	_fresh()
	var english: Dictionary = locale_manager.call("dictionary", "en")
	var english_file: Dictionary = _read_json_dict("res://data/localization/en.json")
	_eq(english.size(), english_file.size(), "English locale key count matches file")
	_eq((locale_manager.call("missing_keys", "vi") as Array).size(), 0, "no Vietnamese key gaps")
	_eq((locale_manager.call("missing_keys", "ja") as Array).size(), 0, "no Japanese key gaps")

	_eq(locale_manager.call("set_locale", "en", false), OK, "set English locale")
	_eq(str(locale_manager.get("current_locale")), "en", "English active")
	_eq(str(locale_manager.call("t", "common.rewards")), "Rewards", "English reward label")
	_eq(str(locale_manager.call("t", "battle.result")), "Battle Result", "English result label")

	_eq(locale_manager.call("set_locale", "vi", false), OK, "set Vietnamese locale")
	_ok(str(locale_manager.call("t", "common.rewards")) != "Rewards", "Vietnamese reward label differs")
	_ok(str(locale_manager.call("t", "battle.result")) != "Battle Result", "Vietnamese result label differs")
	_ok(str(locale_manager.call("t", "battle.rewards")) != "battle.rewards", "no unresolved battle rewards key")
	_eq(str(locale_manager.get("current_locale")), "vi", "Vietnamese active")

	for key: String in english.keys():
		_ok(str(locale_manager.call("t", key)) != key, "vi resolves %s" % key)
	_eq(locale_manager.call("set_locale", "ja", false), OK, "set Japanese locale")
	for key: String in english.keys():
		_ok(str(locale_manager.call("t", key)) != key, "ja resolves %s" % key)
	_eq(str(locale_manager.call("t", "common.rewards")), "報酬", "Japanese reward label")

	const UNKNOWN_KEY := "phase3.test.missing.key"
	_eq(str(locale_manager.call("t", UNKNOWN_KEY)), UNKNOWN_KEY, "unknown key falls back to stable key")
	_ok(not bool(locale_manager.call("has_key", UNKNOWN_KEY)), "unknown key reported missing")
	_eq(str(locale_manager.call("normalize_locale", "en-US")), "en", "English locale tag normalized")
	_eq(str(locale_manager.call("normalize_locale", "ja_JP")), "ja", "Japanese locale tag normalized")
	_eq(str(locale_manager.call("normalize_locale", "xx")), "vi", "unknown locale defaults to vi")
	_eq(str(state.call("normalize_locale", "en-GB")), "en", "player state normalizes locale")

	var dynamic: Dictionary = {"name_key": "common.rewards", "display_name": "Ignored", "id": "fallback.id"}
	_eq(str(locale_manager.call("label_for", dynamic)), "報酬", "dynamic label uses name key")
	dynamic.erase("name_key")
	_eq(str(locale_manager.call("label_for", dynamic)), "Ignored", "dynamic label falls back to display name")
	dynamic.erase("display_name")
	_eq(str(locale_manager.call("label_for", dynamic)), "fallback.id", "dynamic label falls back to ID")

	_eq(locale_manager.call("set_locale", "en", false), OK, "English for result text")
	var args: Dictionary = {"name": "Synthetic Skirmish", "turns": 3, "seed": 4242, "gil": 400, "items": "item:GL:940001@base"}
	var detail: String = str(locale_manager.call("t", "battle.result_detail", args))
	_ok(detail.contains("Synthetic Skirmish"), "result text includes encounter name")
	_ok(detail.contains("Turns: 3"), "English result text includes turns")
	_ok(detail.contains("Seed: 4242"), "result text includes seed")
	_ok(detail.contains("Gil: 400"), "result text includes gil")
	_ok(detail.contains("item:GL:940001@base"), "result text includes items")
	_ok(not detail.contains("{"), "no unresolved placeholders in result text")
	_eq(str(locale_manager.call("t", "save.saved")), "Saved", "reward save message localized")
	_eq(locale_manager.call("set_locale", "vi", false), OK, "Vietnamese for result text")
	var vietnamese_detail: String = str(locale_manager.call("t", "battle.result_detail", args))
	_ok(vietnamese_detail != detail, "result text is localized")
	_ok(vietnamese_detail.contains("Synthetic Skirmish"), "localized result keeps encounter name")
	_ok(vietnamese_detail.contains("400"), "localized result keeps gil")
	_ok(not vietnamese_detail.contains("{"), "no unresolved placeholders in localized result")
	_ok(str(locale_manager.call("t", "save.saved")) != "Saved", "localized save message")
	_eq(locale_manager.call("set_locale", "ja", false), OK, "Japanese for result text")
	var japanese_rewards: String = str(locale_manager.call("t", "common.rewards"))
	_ok(japanese_rewards != "Rewards", "Japanese rewards text localized")
	return true


# --- battle reward idempotency --------------------------------------------------

func test_battle_reward_idempotency() -> bool:
	_fresh()
	var result: Dictionary = {
		"victory": true,
		"encounter_id": SKIRMISH,
		"run_id": "run:phase3:0001",
		"seed": 4242,
		"turns": 7,
		"seed_source": "independent",
		"rewards": {
			"gil": 400,
			"items": ["item:GL:940001@base"],
			"repeat": {"gil": 400, "items": ["item:GL:940001@base"]},
			"claim_keys": {"repeat": "battle|run|run:phase3:0001"}
		}
	}
	var key: String = "battle|run|run:phase3:0001"
	_ok(str(state.call("battle_reward_key", result)).begins_with("battle|"),
		"legacy reward key remains a diagnostic string")
	var gil_before: int = _resource("gil")
	var item_before: int = _resource("item:GL:940001@base")
	var claim: Dictionary = state.call("claim_battle_reward", result)
	_ok(bool(claim.get("ok", false)), "first battle reward claim succeeds")
	_eq(str(claim.get("key", "")), key, "claim reports canonical run key")
	_eq(str(claim.get("message", "")), "reward.saved", "claim reports stable status key")
	_eq(_resource("gil"), gil_before + 400, "gil granted once")
	_eq(_resource("item:GL:940001@base"), item_before + 1, "item reward granted once")
	_ok(((_data().get("claimed_rewards", {}) as Dictionary)).has(key), "legacy mirror records canonical key")
	_ok(((_data().get("reward_claims", {}) as Dictionary)).has(key), "canonical claim recorded")
	_ok(((_data().get("battle_runs", {}) as Dictionary)).has("run:phase3:0001"), "run identity recorded")

	var resources_after_first: Dictionary = _resources()
	var repeat: Dictionary = state.call("claim_battle_reward", result)
	_result_fail(repeat, "already_claimed", "repeat battle reward claim")
	_eq(str(repeat.get("key", "")), key, "repeat claim reports same key")
	_eq(JSON.stringify(_resources()), JSON.stringify(resources_after_first), "repeat claim grants no resources")

	var other: Dictionary = result.duplicate(true)
	other["run_id"] = "run:phase3:0002"
	other["rewards"]["claim_keys"] = {"repeat": "battle|run|run:phase3:0002"}
	_ok(bool((state.call("claim_battle_reward", other) as Dictionary).get("ok", false)),
		"distinct run is claimable")
	_eq(_resource("gil"), gil_before + 800, "distinct run grants gil again")

	var defeat: Dictionary = result.duplicate(true)
	defeat["victory"] = false
	resources_after_first = _resources()
	_result_fail(state.call("claim_battle_reward", defeat), "not_victory", "defeat reward claim")
	_eq(JSON.stringify(_resources()), JSON.stringify(resources_after_first), "defeat grants nothing")

	_eq(state.call("save"), OK, "reward state saved")
	state.call("load_state")
	_eq(JSON.stringify(_resources()), JSON.stringify(resources_after_first), "reward state survives reload")
	_result_fail(state.call("claim_battle_reward", result), "already_claimed", "claim after reload")
	return true


func test_battle_reward_bucket_settlement() -> bool:
	_fresh()
	var gil_before: int = _resource("gil")
	var result: Dictionary = {
		"victory": true,
		"encounter_id": SKIRMISH,
		"run_id": "run:phase3:0100",
		"seed": 4242,
		"turns": 3,
		"seed_source": "qa_deterministic",
		"reward_policy": {"repeatable": true, "first_clear": true, "reward_revision": 1},
		"rewards": {
			"repeat": {"gil": 400, "items": []},
			"first_clear": {"gil": 100, "items": []},
			"missions": [{
				"id": "swift_skirmish",
				"key": "battle|mission|%s|swift_skirmish|run:phase3:0100" % SKIRMISH,
				"repeatable": true,
				"reward": {"gil": 50, "items": []}
			}],
			"claim_keys": {
				"repeat": "battle|run|run:phase3:0100",
				"first_clear": "battle|first|%s" % SKIRMISH,
				"mission:swift_skirmish": "battle|mission|%s|swift_skirmish|run:phase3:0100" % SKIRMISH
			}
		}
	}
	var claim: Dictionary = state.call("claim_battle_reward", result)
	_ok(bool(claim.get("ok", false)), "all reward buckets settle together")
	_eq(_resource("gil"), gil_before + 550, "repeat, first-clear and mission gil granted")
	_eq(((_data().get("mission_progress", {}) as Dictionary).size()), 1, "mission progress recorded")
	_result_fail(state.call("claim_battle_reward", result), "already_claimed", "same run cannot re-settle buckets")

	# A later run still receives its repeat reward after the first-clear key is
	# spent; only the one-time bucket must be skipped.
	var second: Dictionary = result.duplicate(true)
	second["run_id"] = "run:phase3:0101"
	second["rewards"]["repeat"] = {"gil": 400, "items": []}
	second["rewards"]["first_clear"] = {"gil": 100, "items": []}
	second["rewards"]["mission:swift_skirmish"] = {}
	second["rewards"]["claim_keys"] = {
		"repeat": "battle|run|run:phase3:0101",
		"first_clear": "battle|first|%s" % SKIRMISH
	}
	var second_claim: Dictionary = state.call("claim_battle_reward", second)
	_ok(bool(second_claim.get("ok", false)), "later run claims its repeat bucket")
	_eq(_resource("gil"), gil_before + 950, "spent first-clear bucket is not granted twice")
	return true


func test_battle_reward_save_failure_rollback() -> bool:
	_fresh()
	var before: String = _snapshot()
	var result: Dictionary = {
		"victory": true,
		"encounter_id": SKIRMISH,
		"run_id": "run:phase3:0200",
		"seed": 4242,
		"turns": 4,
		"rewards": {
			"repeat": {"gil": 400, "items": ["item:GL:940001@base"]},
			"claim_keys": {"repeat": "battle|run|run:phase3:0200"}
		}
	}
	SaveManager.call("fail_next_atomic_write")
	var failed: Dictionary = state.call("claim_battle_reward", result)
	_result_fail(failed, "save_failed", "reward commit failure reported")
	_assert_unchanged(before, "failed reward settlement rolls back every section")
	SaveManager.call("clear_write_failure")
	_ok(bool((state.call("claim_battle_reward", result) as Dictionary).get("ok", false)),
		"reward can be claimed after write fault is cleared")
	return true


# --- scene instantiation --------------------------------------------------------

func test_phase3_scenes_instantiate() -> bool:
	_fresh()
	OS.set_environment("FFBE_QA_INSTANCE_ID", V1)
	OS.set_environment("FFBE_QA_PARTY_ID", "default")
	for path: String in PHASE3_SCENES:
		var packed: PackedScene = load(path) as PackedScene
		_ok(packed != null, "scene loads: %s" % path)
		if packed == null:
			continue
		var scene: Control = packed.instantiate() as Control
		_ok(scene != null, "scene instantiates as Control: %s" % path)
		if scene == null:
			continue
		# In a --script SceneTree run, Phase 3 _ready handlers are deferred until
		# the next frame and call get_tree().root. Instantiation alone is the
		# deterministic contract for this suite; UI behaviour is covered by QA.
		var instance_id: int = scene.get_instance_id()
		_ok(scene.get_script() != null, "scene script attached: %s" % path)
		scene.free()
		_ok(not is_instance_id_valid(instance_id), "scene freed: %s" % path)
	return true
