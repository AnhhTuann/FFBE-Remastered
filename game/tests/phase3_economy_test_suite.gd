class_name Phase3EconomyTestSuite
extends RefCounted

## Prompt 05 economy and synthetic data-pack regression suite.
##
## All fixtures are project-authored SYNTHETIC_FIXTURE / REMASTERED_DESIGN data;
## no FFBE banner, rate, shop stock, recipe or esper value is asserted here.
## The caller's PlayerState data and user save file are restored on exit.
##
## run() returns bool so it plugs into tests/test_runner.gd, which is owned by
## another agent; assertions use the same assert_true/assert_eq style as
## phase3_test_suite.gd. A null runner is supported for isolated harnesses.

const PLAYER_STATE_PATH := "user://player_state_v3.json"
const ESPER_1 := "esper:GL:960001@base"
const ESPER_2 := "esper:GL:960002@base"
const ESPER_JP := "esper:JP:960003@base"
const BANNER_1 := "summon:GL:970001@base"
const BANNER_2 := "summon:GL:970002@base"
const BANNER_JP := "summon:JP:970003@base"
const RECIPE_1 := "recipe:GL:990001@base"
const RECIPE_2 := "recipe:GL:990002@base"
const RECIPE_3 := "recipe:JP:990003@base"
const SHOP_1 := "shop:GL:980001@base"
const SHOP_2 := "shop:JP:980002@base"
const STOCK_MATERIAL := "synthetic_material_pack"
const STOCK_SHIELD := "synthetic_guard_shield"
const STOCK_MATERIA := "synthetic_defense_materia"

var runner: Object = null
var state: Node = null
var _repo_node: Node = null
var _standalone_passed: int = 0
var _standalone_failed: int = 0


func _init(p_runner: Object = null) -> void:
	runner = p_runner
	var tree: SceneTree = p_runner as SceneTree
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree != null:
		state = tree.root.get_node_or_null("PlayerState")


func run() -> bool:
	if state == null:
		_ok(false, "economy suite services available")
		return _finish()

	var original_data: Dictionary = (_data().duplicate(true) as Dictionary)
	var had_state_file: bool = FileAccess.file_exists(PLAYER_STATE_PATH)
	var repo: Node = _repo()
	if repo == null or not bool(repo.get("loaded")):
		if repo != null:
			repo.call("load_content")

	_run("test_catalog_gate")
	_run("test_invalid_identities_rejected")
	_run("test_player_state_timestamp_contract")
	_run("test_esper_system")
	_run("test_summon_system")
	_run("test_summon_receipt_validation")
	_run("test_summon_commit_rollback")
	_run("test_economy_system")
	_run("test_shop_system")
	_run("test_shop_receipt_and_uid_integrity")
	_run("test_shop_commit_rollback")
	_run("test_crafting_system")
	_run("test_crafting_output_rollback")
	_run("test_crafting_save_reload")
	_run("test_end_to_end_flow")

	state.set("data", original_data)
	state.call("save")
	if not had_state_file and FileAccess.file_exists(PLAYER_STATE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PLAYER_STATE_PATH))
	return _finish()


func _run(test_name: String) -> void:
	if call(test_name) != true:
		_ok(false, "economy %s did not finish (runtime error?)" % test_name)


func _finish() -> bool:
	if runner == null:
		print("Economy suite: %d passed, %d failed" % [_standalone_passed, _standalone_failed])
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		if tree != null:
			tree.quit(1 if _standalone_failed > 0 else 0)
	return _standalone_failed == 0 and (runner != null or _standalone_passed > 0)


func _repo() -> Node:
	if _repo_node != null:
		return _repo_node
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		_repo_node = tree.root.get_node_or_null("ContentRepository")
	if _repo_node == null:
		var script: Script = load("res://core/content_repository.gd") as Script
		if script != null:
			_repo_node = script.new() as Node
			if _repo_node != null:
				_repo_node.call("load_content")
	return _repo_node


# --- assertion and state helpers ------------------------------------------------

func _ok(condition: bool, label: String) -> void:
	if runner != null:
		runner.call("assert_true", condition, label)
		return
	if condition:
		_standalone_passed += 1
	else:
		_standalone_failed += 1
		push_error("FAIL %s: expected true" % label)


func _eq(actual: Variant, expected: Variant, label: String) -> void:
	if runner != null:
		runner.call("assert_eq", actual, expected, label)
		return
	if actual == expected:
		_standalone_passed += 1
	else:
		_standalone_failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])


func _result_ok(result: Dictionary, label: String) -> bool:
	var success: bool = bool(result.get("ok", false))
	_ok(success, label)
	return success


func _result_fail(result: Dictionary, reason: String, label: String) -> bool:
	var failed: bool = not bool(result.get("ok", false))
	_ok(failed, "%s rejected" % label)
	_eq(str(result.get("reason", "")), reason, "%s reason" % label)
	return failed


func _data() -> Dictionary:
	var value: Variant = state.get("data")
	return value if value is Dictionary else {}


func _resource(key: String) -> int:
	var resources: Dictionary = _data().get("resources", {})
	return maxi(int(resources.get(key, 0)), 0)


func _system(path: String) -> RefCounted:
	var script: Script = load(path) as Script
	var system: RefCounted = script.new(state) as RefCounted
	_ok(system != null, "%s instantiates" % path)
	return system


func _save_manager() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("SaveManager") if tree != null else null


func _fresh(now_unix: int = 0) -> void:
	var data: Dictionary = state.call("default_state", now_unix) as Dictionary
	if not (data.get("espers") is Dictionary):
		data["espers"] = {"owned": {}, "active_by_party": {}, "claims": {}}
	if not (data.get("summon") is Dictionary):
		data["summon"] = {"pity": {}, "history": [], "claims": {}}
	var economy_variant: Variant = data.get("economy", {})
	var economy: Dictionary = economy_variant if economy_variant is Dictionary else {}
	if not economy.has("last_settled_unix"):
		economy["last_settled_unix"] = now_unix
	if not (economy.get("claims") is Dictionary):
		economy["claims"] = {}
	data["economy"] = economy
	if not (data.get("shops") is Dictionary):
		data["shops"] = {"purchases": {}, "claims": {}}
	if not (data.get("crafting") is Dictionary):
		data["crafting"] = {"jobs": {}, "claims": {}}
	if not (data.get("flags") is Dictionary):
		data["flags"] = {}
	state.set("data", data)


func _section(section: String) -> Dictionary:
	var value: Variant = _data().get(section, {})
	return value if value is Dictionary else {}


func _fingerprint() -> String:
	var data: Dictionary = _data()
	# Rollback restores from JSON, which normalizes integers to floats. Round-trip
	# both sides here so a restored snapshot compares equal to the live state.
	var payload: String = JSON.stringify({
		"resources": data.get("resources", {}),
		"owned_units": data.get("owned_units", []),
		"inventory": data.get("inventory", {}),
		"parties": data.get("parties", {}),
		"next_unit_serial": data.get("next_unit_serial", 0),
		"next_equip_serial": data.get("next_equip_serial", 0),
		"espers": data.get("espers", {}),
		"summon": data.get("summon", {}),
		"economy": data.get("economy", {}),
		"shops": data.get("shops", {}),
		"crafting": data.get("crafting", {}),
		"flags": data.get("flags", {})
	})
	var parser := JSON.new()
	if parser.parse(payload) == OK and parser.data is Dictionary:
		return JSON.stringify(parser.data)
	return payload


func _assert_unchanged(before: String, label: String) -> void:
	_eq(_fingerprint(), before, "%s left state unchanged" % label)


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


func _copy_via_json(value: Dictionary) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(JSON.stringify(value)) != OK or not parser.data is Dictionary:
		return {}
	return parser.data


# --- catalog gate ---------------------------------------------------------------

func test_catalog_gate() -> bool:
	_ok(bool(_repo().get("loaded")), "ContentRepository loaded economy packs")
	var summary: Dictionary = _repo().call("summary")
	_eq(str(summary.get("fixture_marker", "")), "SYNTHETIC_FIXTURE", "catalog fixture marker")
	_eq(str(summary.get("rights_gate", "")), "not_passed", "rights gate not passed")
	_eq(int(summary.get("esper_definition_count", 0)), 3, "esper count")
	_eq(int(summary.get("summon_banner_count", 0)), 3, "banner count")
	_eq(int(summary.get("offline_economy_rule_count", 0)), 1, "offline rule count")
	_eq(int(summary.get("shop_definition_count", 0)), 4, "shop count")
	_eq(int(summary.get("crafting_recipe_count", 0)), 3, "recipe count")

	var packs: Dictionary = {
		"espers": _read_json("res://data/phase3/espers.json"),
		"banners": _read_json("res://data/phase3/summon_banners.json"),
		"rules": _read_json("res://data/phase3/offline_economy_rules.json"),
		"shops": _read_json("res://data/phase3/shops.json"),
		"recipes": _read_json("res://data/phase3/crafting_recipes.json")
	}
	var expected_kind: Dictionary = {
		"espers": "esper", "banners": "summon", "rules": "offline_rule",
		"shops": "shop", "recipes": "recipe"
	}
	for key: String in packs.keys():
		var pack: Dictionary = packs[key]
		_eq(str(pack.get("fixture_marker", "")), "SYNTHETIC_FIXTURE", "%s fixture marker" % key)
		var policy: Dictionary = pack.get("policy", {})
		_eq(str(policy.get("rights_gate", "")), "not_passed", "%s rights gate" % key)
		_ok(not bool(policy.get("source_data_imported", false)), "%s imports no source data" % key)
		var records: Array = pack.get(key, [])
		_ok(not records.is_empty(), "%s has records" % key)
		for entry_variant: Variant in records:
			var entry: Dictionary = entry_variant
			var id: String = str(entry.get("id", ""))
			var parsed: Variant = _repo().call("parse_composite_id", id)
			_ok(parsed != null and bool(parsed.call("is_valid")), "%s valid ID %s" % [key, id])
			_eq(str(parsed.call("as_text")), id, "%s canonical round trip %s" % [key, id])
			_eq(str(parsed.get("kind")), str(expected_kind[key]), "%s kind %s" % [key, id])
			_ok(str(parsed.get("region")) == "GL" or str(parsed.get("region")) == "JP", "%s region %s" % [key, id])
			var status: String = str(entry.get("verification_status", ""))
			_ok(status == "SYNTHETIC_FIXTURE" or status == "REMASTERED_DESIGN", "%s evidence label %s" % [key, id])
			var name_key: String = str(entry.get("name_key", entry.get("display_name_key", "")))
			_ok(not name_key.is_empty(), "%s name key %s" % [key, id])

	var banner: Dictionary = _repo().call("get_summon_banner", BANNER_1)
	_eq(str(banner.get("rate_label", "")), "SYNTHETIC_FIXTURE", "banner rates explicitly synthetic")
	_ok(str(banner.get("description", banner.get("rate_notice", ""))).is_empty(), "banner record carries no copied description")
	var manifest: Dictionary = _repo().call("get_imported_manifest")
	_eq((manifest.get("active_packs", []) as Array).size(), 0, "no protected packs active")
	_ok(not bool((manifest.get("policy", {}) as Dictionary).get("allow_recovered_without_rights", true)), "recovered data disabled")
	return true


# --- fail-closed validation -----------------------------------------------------

func test_invalid_identities_rejected() -> bool:
	var template: Dictionary = _repo().call("get_esper_definition", ESPER_1)
	_ok(not template.is_empty(), "esper template available")
	if template.is_empty():
		return true
	var pack: Dictionary = {
		"fixture_marker": "SYNTHETIC_FIXTURE",
		"policy": {"rights_gate": "not_passed", "source_data_imported": false},
		"espers": [template]
	}
	_ok(bool(_repo().call("_fixture_gate", pack)), "valid pack passes fixture gate")
	var wrong_marker: Dictionary = pack.duplicate(true)
	wrong_marker["fixture_marker"] = "REMASTERED_DESIGN"
	_ok(not bool(_repo().call("_fixture_gate", wrong_marker)), "wrong marker fails closed")
	var wrong_rights: Dictionary = pack.duplicate(true)
	wrong_rights["policy"] = {"rights_gate": "passed", "source_data_imported": false}
	_ok(not bool(_repo().call("_fixture_gate", wrong_rights)), "wrong rights gate fails closed")
	var imported: Dictionary = pack.duplicate(true)
	imported["policy"] = {"rights_gate": "not_passed", "source_data_imported": true}
	_ok(not bool(_repo().call("_fixture_gate", imported)), "source import claim fails closed")

	_ok(not (_repo().call("_validated_records", pack, "espers", "esper") as Dictionary).is_empty(), "valid record accepted")
	var invalid_region: Dictionary = _with_id(template, "esper:ZZ:960099@base")
	_ok((_repo().call("_validated_records", {"espers": [invalid_region]}, "espers", "esper") as Dictionary).is_empty(), "invalid region rejected")
	var malformed: Dictionary = _with_id(template, "esper:GL:960099")
	_ok((_repo().call("_validated_records", {"espers": [malformed]}, "espers", "esper") as Dictionary).is_empty(), "malformed ID rejected")
	var canonical_mismatch: Dictionary = _with_id(template, "esper:GL:960099@brave_shift")
	_ok((_repo().call("_validated_records", {"espers": [canonical_mismatch]}, "espers", "esper") as Dictionary).is_empty(), "form mismatch rejected")
	var wrong_kind: Dictionary = _with_id(template, "unit:GL:960099@base")
	_ok((_repo().call("_validated_records", {"espers": [wrong_kind]}, "espers", "esper") as Dictionary).is_empty(), "wrong kind rejected")
	var duplicate_pack: Dictionary = {"espers": [template, _copy_via_json(template)]}
	_ok((_repo().call("_validated_records", duplicate_pack, "espers", "esper") as Dictionary).is_empty(), "duplicate ID rejected")
	var bad_evidence: Dictionary = _copy_via_json(template)
	bad_evidence["verification_status"] = "RECOVERED"
	_ok((_repo().call("_validated_records", {"espers": [bad_evidence]}, "espers", "esper") as Dictionary).is_empty(), "non-synthetic evidence rejected")
	var bad_provenance: Dictionary = _copy_via_json(template)
	bad_provenance["provenance"]["rights_gate"] = "passed"
	_ok((_repo().call("_validated_records", {"espers": [bad_provenance]}, "espers", "esper") as Dictionary).is_empty(), "record rights gate rejected")

	var banner: Dictionary = _repo().call("get_summon_banner", BANNER_1)
	_ok(bool(_repo().call("_validate_banners", {BANNER_1: banner})), "valid banner cross references")
	var bad_banner: Dictionary = _copy_via_json(banner)
	bad_banner["pool"] = ["unit:GL:999999@base"]
	_ok(not bool(_repo().call("_validate_banners", {"bad": bad_banner})), "unknown pool reference rejected")
	var bad_weight: Dictionary = _copy_via_json(banner)
	bad_weight["weights"]["unit:GL:910101@base"] = 0
	_ok(not bool(_repo().call("_validate_banners", {"bad": bad_weight})), "non-positive weight rejected")
	var bad_threshold: Dictionary = _copy_via_json(banner)
	bad_threshold["pity"]["threshold"] = int(banner["guarantee"]["within"]) + 1
	_ok(not bool(_repo().call("_validate_banners", {"bad": bad_threshold})), "pity/guarantee mismatch rejected")
	var shop: Dictionary = _repo().call("get_shop", SHOP_1)
	_ok(bool(_repo().call("_validate_shops", {SHOP_1: shop})), "valid shop stock references")
	var bad_shop: Dictionary = _copy_via_json(shop)
	bad_shop["stock"][0]["definition_id"] = "equip:GL:999999@base"
	_ok(not bool(_repo().call("_validate_shops", {"bad": bad_shop})), "unknown stock definition rejected")
	var wrong_region_shop: Dictionary = _copy_via_json(shop)
	wrong_region_shop["stock"][0]["definition_id"] = "materia:JP:600004@base"
	_ok(not bool(_repo().call("_validate_shops", {"bad": wrong_region_shop})), "region-mismatched stock rejected")
	var recipe: Dictionary = _repo().call("get_crafting_recipe", RECIPE_1)
	_ok(bool(_repo().call("_validate_recipes", {RECIPE_1: recipe})), "valid recipe references")
	var bad_recipe: Dictionary = _copy_via_json(recipe)
	bad_recipe["outputs"] = {"material:GL:999999@base": 1}
	_ok(not bool(_repo().call("_validate_recipes", {"bad": bad_recipe})), "unknown recipe output rejected")
	return true


func _with_id(entry: Dictionary, id: String) -> Dictionary:
	var copy: Dictionary = entry.duplicate(true)
	copy["id"] = id
	return copy


# --- player state timestamp contract ---------------------------------------------

func test_player_state_timestamp_contract() -> bool:
	# Explicit now_unix values keep migration and fresh-profile checks deterministic.
	var fresh: Dictionary = state.call("default_state", 5000) as Dictionary
	_eq(int((fresh.get("economy", {}) as Dictionary).get("last_settled_unix", -1)), 5000,
		"fresh profile anchors offline clock")
	_eq(int((fresh.get("economy", {}) as Dictionary).get("claims", {}).size()), 0,
		"fresh profile has no retroactive claim")

	var v1: Dictionary = {
		"version": 1,
		"resources": {"gil": 1234},
		"owned_units": [],
		"inventory": {},
		"parties": {},
		"claimed_rewards": {},
		"profile": {"locale": "en"}
	}
	var migrated_v1: Dictionary = state.call("migrate_state", v1, 5000) as Dictionary
	_eq(int(migrated_v1.get("version", 0)), 4, "v1 migrates to v4")
	_eq(int((migrated_v1.get("resources", {}) as Dictionary).get("gil", 0)), 1234, "v1 resources preserved")
	_eq(int((migrated_v1.get("economy", {}) as Dictionary).get("last_settled_unix", -1)), 5000,
		"v1 migration anchors offline clock")
	_ok(bool(state.call("validate_state", migrated_v1)), "v1 migrated state validates")

	var v3: Dictionary = {
		"version": 3,
		"profile": {"locale": "ja", "favorites": ["unit:GL:910101@base"], "last_unit_id": ""},
		"resources": {"gil": 4321},
		"owned_units": [],
		"inventory": {"equipment": []},
		"parties": {"default": {"slots": [], "leader_slot": 0}},
		"claimed_rewards": {"legacy|one": {"gil": 10}},
		"legacy": {"battle_progress": {"attempts": 2}}
	}
	var migrated_v3: Dictionary = state.call("migrate_state", v3, 5000) as Dictionary
	_eq(int(migrated_v3.get("version", 0)), 4, "v3 migrates to v4")
	_eq(int((migrated_v3.get("resources", {}) as Dictionary).get("gil", 0)), 4321, "v3 resources preserved")
	_ok((migrated_v3.get("reward_claims", {}) as Dictionary).has("legacy|one"), "v3 legacy claim preserved")
	_eq(int(((migrated_v3.get("battle_runs", {}) as Dictionary).get("legacy", {}) as Dictionary).get("attempts", 0)), 2,
		"v3 legacy battle progress preserved")
	_eq(int((migrated_v3.get("economy", {}) as Dictionary).get("last_settled_unix", -1)), 5000,
		"v3 migration anchors offline clock")
	_eq((migrated_v3.get("economy", {}) as Dictionary).get("claims", {}).size(), 0,
		"migration grants no retroactive offline claim")
	_ok(bool(state.call("validate_state", migrated_v3)), "v3 migrated state validates")

	var v4: Dictionary = migrated_v3.duplicate(true)
	v4["economy"] = {
		"last_settled_unix": 12345,
		"claims": {"offline|1000|12345": {"resources": {"gil": 1}}}
	}
	var preserved_v4: Dictionary = state.call("migrate_state", v4, 5000) as Dictionary
	_eq(int((preserved_v4.get("economy", {}) as Dictionary).get("last_settled_unix", -1)), 12345,
		"existing v4 timestamp is not reset")
	_ok(((preserved_v4.get("economy", {}) as Dictionary).get("claims", {}) as Dictionary).has("offline|1000|12345"),
		"existing v4 claim is preserved")
	_eq(int((preserved_v4.get("resources", {}) as Dictionary).get("gil", 0)), 4321,
		"existing v4 resources are preserved")

	_fresh(0)
	state.call("grant", {"gil": 777})
	_eq(state.call("save"), OK, "save contract writes player state")
	_ok(FileAccess.file_exists(PLAYER_STATE_PATH), "save uses version-3 path")
	var reloaded: Dictionary = state.call("load_state", 0) as Dictionary
	_eq(int(reloaded.get("version", 0)), 4, "reloaded state keeps internal version 4")
	_eq(int((reloaded.get("resources", {}) as Dictionary).get("gil", 0)),
		int((_data().get("resources", {}) as Dictionary).get("gil", 0)), "reload preserves resources")
	_eq(int((reloaded.get("economy", {}) as Dictionary).get("last_settled_unix", -1)), 0,
		"explicit zero anchor survives reload")
	return true


# --- esper system ---------------------------------------------------------------

func test_esper_system() -> bool:
	_fresh(0)
	var esper: RefCounted = _system("res://systems/esper_system.gd")
	_eq((esper.call("definitions") as Dictionary).size(), 3, "esper definitions exposed")
	_ok(not (esper.call("definition", ESPER_1) as Dictionary).is_empty(), "esper definition getter")
	var before: String = _fingerprint()
	_result_fail(esper.call("unlock", "esper:GL:999999@base"), "unknown_esper", "unknown esper unlock")
	_assert_unchanged(before, "unknown esper unlock")

	_data()["resources"]["gil"] = 0
	_data()["resources"]["material:GL:900101@base"] = 0
	before = _fingerprint()
	_result_fail(esper.call("unlock", ESPER_1), "insufficient_resources", "unaffordable esper")
	_assert_unchanged(before, "unaffordable esper")
	_fresh(0)

	var result: Dictionary = esper.call("unlock", ESPER_1)
	_result_ok(result, "esper unlocked")
	_eq(_resource("gil"), 480000, "esper unlock gil cost")
	_eq(_resource("material:GL:900101@base"), 118, "esper unlock material cost")
	_eq(int((esper.call("owned") as Dictionary).get(ESPER_1, {}).get("level", 0)), 1, "unlocked esper starts at level 1")
	_ok(_section("espers").get("claims", {}).has("esper|%s|unlock" % ESPER_1), "esper unlock claim recorded")
	before = _fingerprint()
	_result_fail(esper.call("unlock", ESPER_1), "already_claimed", "repeat esper unlock")
	_assert_unchanged(before, "repeat esper unlock")

	var active: Dictionary = esper.call("set_active", "default", ESPER_1)
	_result_ok(active, "esper linked to party")
	_eq(str(_section("espers").get("active_by_party", {}).get("default", "")), ESPER_1, "active esper persisted")
	_result_fail(esper.call("clear_active", "missing"), "unknown_party", "clear unknown party")
	_result_ok(esper.call("clear_active", "default"), "active esper cleared")
	_eq((_section("espers").get("active_by_party", {}) as Dictionary).has("default"), false, "active esper removed")
	before = _fingerprint()
	_result_ok(esper.call("clear_active", "default"), "repeat clear is idempotent")
	_assert_unchanged(before, "repeat clear")
	_result_ok(esper.call("set_active", "default", ESPER_1), "esper relinked after clear")
	var status: Dictionary = esper.call("status_for", "default")
	_result_ok(status, "esper status synthesized")
	_eq(int((status.get("stats", {}) as Dictionary).get("atk", 0)), 60, "synthetic ATK from fixture base")
	_eq(str(status.get("evidence", "")), "REMASTERED_DESIGN", "synthetic stats labeled as design")
	before = _fingerprint()
	_result_fail(esper.call("set_active", "missing", ESPER_1), "unknown_party", "unknown party link")
	_result_fail(esper.call("set_active", "default", ESPER_JP), "not_owned", "unowned esper link")
	_assert_unchanged(before, "invalid esper links")

	_ok(bool(esper.call("unlock", ESPER_2).get("ok", false)), "second esper unlocked")
	state.call("set_party", "alt", {"slots": [], "leader_slot": 0, "region": "JP"})
	state.call("set_party", "third", {"slots": [], "leader_slot": 0, "region": "GL"})
	state.call("set_party", "fourth", {"slots": [], "leader_slot": 0, "region": "GL"})
	before = _fingerprint()
	_result_fail(esper.call("set_active", "alt", ESPER_1), "region_mismatch", "JP party rejects GL esper")
	_assert_unchanged(before, "region-mismatched esper link")
	_result_ok(esper.call("set_active", "third", ESPER_2), "second esper linked once")
	_result_fail(esper.call("set_active", "fourth", ESPER_2), "link_limit", "esper link limit enforced")
	before = _fingerprint()
	_result_ok(esper.call("set_active", "third", ESPER_2), "repeat activation is idempotent")
	_assert_unchanged(before, "repeat activation does not rewrite the save")

	var gil_before: int = _resource("gil")
	var sp_result: Dictionary = esper.call("add_sp", ESPER_1, 10)
	_result_ok(sp_result, "esper SP added")
	_eq(int((esper.call("owned") as Dictionary).get(ESPER_1, {}).get("sp", 0)), 10, "SP persisted")
	_eq(_resource("gil"), gil_before - 50000, "SP cost charged once")
	_result_ok(esper.call("add_sp", ESPER_1, 10), "repeat SP purchase succeeds")
	_eq(int((esper.call("owned") as Dictionary).get(ESPER_1, {}).get("sp", 0)), 20, "repeat SP persisted")
	_eq(_resource("gil"), gil_before - 100000, "repeat SP cost charged")
	_eq((_section("espers").get("sp_purchases", []) as Array).size(), 2, "SP purchase history recorded")
	before = _fingerprint()
	_result_fail(esper.call("add_sp", ESPER_1, -5), "invalid_amount", "negative SP rejected")
	_assert_unchanged(before, "negative SP")
	return true


# --- summon system --------------------------------------------------------------

func test_summon_system() -> bool:
	_fresh(0)
	var summon: RefCounted = _system("res://systems/summon_system.gd")
	_eq((summon.call("banners") as Dictionary).size(), 3, "banners exposed")
	_ok(not (summon.call("banner", BANNER_1) as Dictionary).is_empty(), "banner getter")
	_eq(int((summon.call("cost", BANNER_1) as Dictionary).get("lapis", 0)), 200, "synthetic banner cost")
	state.call("grant", {"lapis": 1000})
	var first: Dictionary = summon.call("summon", BANNER_1, 4242, "receipt-alpha")
	_result_ok(first, "first summon succeeds")
	_ok(str(first.get("unit_id", "")).begins_with("unit:GL:"), "summoned synthetic GL unit")
	_eq(_resource("lapis"), 800, "one summon charged once")
	_ok(str(first.get("key", "")) == "summon|%s|receipt-alpha" % BANNER_1, "summon claim key format")
	_eq(int(first.get("guarantee_within", -1)),
		int(((summon.call("banner", BANNER_1) as Dictionary).get("guarantee", {}) as Dictionary).get("within", -1)),
		"engine guarantee uses fixture within")
	var before_fingerprint: String = _fingerprint()
	var repeated: Dictionary = summon.call("summon", BANNER_1, 4242, "receipt-alpha")
	_result_fail(repeated, "already_claimed", "same receipt idempotent")
	_assert_unchanged(before_fingerprint, "same receipt")

	var second: Dictionary = summon.call("summon", BANNER_1, 4242, "receipt-beta")
	_result_ok(second, "different receipt independent")
	_eq(_resource("lapis"), 600, "second summon charged once")
	_eq((summon.call("history") as Array).size(), 2, "history records both summons")

	_fresh(0)
	state.call("grant", {"lapis": 1000})
	var deterministic: Dictionary = summon.call("summon", BANNER_1, 4242, "receipt-alpha")
	_eq(str(deterministic.get("unit_id", "")), str(first.get("unit_id", "")), "same seed/receipt yields same unit")
	_eq(str(deterministic.get("instance_id", "")), str(first.get("instance_id", "")), "same seed/receipt yields same instance")
	_fresh(0)
	state.call("grant", {"lapis": 1000})
	var changed_seed: Dictionary = summon.call("summon", BANNER_1, 4243, "receipt-alpha")
	_ok(bool(changed_seed.get("ok", false)), "different seed still succeeds")

	_fresh(0)
	state.call("grant", {"lapis": 20})
	before_fingerprint = _fingerprint()
	_result_fail(summon.call("summon", BANNER_1, 1, "receipt-poor"), "insufficient_resources", "poor summon rejected")
	_assert_unchanged(before_fingerprint, "poor summon")
	_result_fail(summon.call("summon", "summon:GL:999999@base", 1, "receipt-bad"), "unknown_banner", "unknown banner rejected")
	_assert_unchanged(before_fingerprint, "unknown banner")

	_fresh(0)
	state.call("grant", {"lapis": 2000})
	for index: int in range(6):
		var draw: Dictionary = summon.call("summon", BANNER_1, 900 + index, "pity-%d" % index)
		_result_ok(draw, "pity draw %d" % index)
	_eq((_section("summon").get("claims", {}) as Dictionary).size(), 6, "six receipts recorded exactly once")
	var jp_draws: Dictionary = {}
	for index: int in range(4):
		var draw: Dictionary = summon.call("summon", BANNER_JP, 700 + index, "jp-%d" % index)
		_result_ok(draw, "JP pity draw %d" % index)
		jp_draws[str(draw.get("key", ""))] = draw
	_eq(jp_draws.size(), 4, "JP receipts distinct")
	_ok(bool(jp_draws.get("summon|%s|jp-3" % BANNER_JP, {}).get("guaranteed", false)), "fourth synthetic draw guaranteed")
	_eq(int(jp_draws.get("summon|%s|jp-3" % BANNER_JP, {}).get("pity", -1)), 0, "guarantee resets synthetic pity")
	var history: Array = _section("summon").get("history", [])
	while history.size() < 205:
		history.append({"banner_id": BANNER_1, "unit_id": "unit:GL:910101@base"})
	_data()["summon"]["history"] = history
	state.call("grant", {"lapis": 200})
	_result_ok(summon.call("summon", BANNER_JP, 777, "history-cap"), "summon after history overflow")
	_ok((summon.call("history") as Array).size() <= 200, "summon history bounded")
	return true


func test_summon_receipt_validation() -> bool:
	_fresh(0)
	var summon: RefCounted = _system("res://systems/summon_system.gd")
	state.call("grant", {"lapis": 1000})
	var before: String = _fingerprint()
	_result_fail(summon.call("summon", BANNER_1, 4242, ""), "invalid_receipt", "empty summon receipt")
	_result_fail(summon.call("summon", BANNER_1, 4242, "   "), "invalid_receipt", "whitespace summon receipt")
	_result_fail(summon.call("summon", BANNER_1, 4242, "r".repeat(129)), "invalid_receipt", "oversized summon receipt")
	_assert_unchanged(before, "invalid summon receipts")

	var padded: Dictionary = summon.call("summon", BANNER_1, 4242, "  receipt-padded  ")
	_result_ok(padded, "padded summon receipt normalized")
	_eq(str(padded.get("key", "")), "summon|%s|receipt-padded" % BANNER_1, "normalized summon key")
	_eq(str((_section("summon").get("claims", {}) as Dictionary).get(
		"summon|%s|receipt-padded" % BANNER_1, {}).get("receipt", "")), "receipt-padded",
		"normalized receipt stored once")
	var after_pad: String = _fingerprint()
	_result_fail(summon.call("summon", BANNER_1, 4242, "receipt-padded"), "already_claimed",
		"normalized receipt cannot charge twice")
	_assert_unchanged(after_pad, "normalized receipt idempotency")

	var max_receipt: Dictionary = summon.call("summon", BANNER_1, 4242, "m".repeat(128))
	_result_ok(max_receipt, "maximum-length receipt accepted")
	return true


func test_summon_commit_rollback() -> bool:
	_fresh(0)
	var summon: RefCounted = _system("res://systems/summon_system.gd")
	state.call("grant", {"lapis": 1000})
	var before: String = _fingerprint()
	var save_manager: Node = _save_manager()
	if save_manager == null:
		_ok(false, "summon rollback fixture has SaveManager")
		return true
	save_manager.call("fail_next_atomic_write")
	var result: Dictionary = summon.call("summon", BANNER_1, 4242, "receipt-fault")
	_result_fail(result, "grant_failed", "summon commit failure rejected")
	_eq(_resource("lapis"), 1000, "failed summon restores currency")
	_eq((_data().get("owned_units", []) as Array).size(), 6, "failed summon restores unit inventory")
	_eq((_section("summon").get("claims", {}) as Dictionary).size(), 0, "failed summon records no claim")
	var normalized_before: String = JSON.stringify(JSON.parse_string(before))
	_eq(_fingerprint(), normalized_before, "summon commit failure restores full state")
	_result_ok(summon.call("summon", BANNER_1, 4242, "receipt-after-fault"), "summon succeeds after fault consumed")
	return true


# --- offline economy system -----------------------------------------------------

func test_economy_system() -> bool:
	_fresh(0)
	var economy: RefCounted = _system("res://systems/economy_system.gd")
	_eq((economy.call("rules") as Dictionary).size(), 1, "offline rule exposed")
	_data()["economy"]["last_settled_unix"] = 1000
	var before: String = _fingerprint()
	_result_fail(economy.call("status", -5), "invalid_time", "negative timestamp rejected")
	_assert_unchanged(before, "negative status time")
	var small: Dictionary = economy.call("status", 1030)
	_result_ok(small, "short status is read-only")
	_eq(int(small.get("pending_seconds", -1)), 0, "minimum interval clamps pending seconds")
	_eq(str(small.get("reason", "")), "minimum_interval", "minimum interval reason")
	_assert_unchanged(before, "status does not mutate")

	var preview: Dictionary = economy.call("status", 8200)
	_result_ok(preview, "status previews pending time")
	_eq(int(preview.get("pending_seconds", -1)), 7200, "pending seconds from last settlement")
	_eq(int((preview.get("resources", {}) as Dictionary).get("gil", 0)), 2200, "full party synthetic modifier applied")
	_eq(int((preview.get("resources", {}) as Dictionary).get("material:GL:900101@base", 0)), 4, "material rate scaled from fixture")
	_eq(str(preview.get("claim_key", "")), "offline|1000|8200", "offline claim key format")
	_assert_unchanged(before, "preview does not mutate")

	var settled: Dictionary = economy.call("settle", 8200)
	_result_ok(settled, "offline settlement succeeds")
	_eq(_resource("gil"), 502200, "settled gil granted")
	_eq(_resource("material:GL:900101@base"), 124, "settled material granted")
	_eq(int(_section("economy").get("last_settled_unix", 0)), 8200, "last settlement advanced")
	var after_settle: String = _fingerprint()
	_result_fail(economy.call("settle", 8200), "already_claimed", "same window not granted twice")
	_assert_unchanged(after_settle, "repeat settlement")
	_result_ok(economy.call("settle", 15400), "next window settles")
	_eq(int(_section("economy").get("last_settled_unix", 0)), 15400, "second window advanced")
	_result_fail(economy.call("settle", 100), "no_pending_time", "negative delta rejected")
	_assert_unchanged(_fingerprint(), "negative settlement")

	_fresh(0)
	var cap_preview: Dictionary = economy.call("status", 1000000)
	_eq(int(cap_preview.get("pending_seconds", 0)), 28800, "offline reward time capped")
	_eq(int(cap_preview.get("elapsed_seconds", 0)), 1000000, "full elapsed period reported")
	_eq(bool(cap_preview.get("capped", false)), true, "capped flag reported")
	_eq(int(cap_preview.get("consumed_until", 0)), 1000000, "capped claim consumes elapsed end")
	_eq(str(cap_preview.get("claim_key", "")), "offline|0|1000000", "capped claim key uses elapsed end")
	_eq(int((cap_preview.get("resources", {}) as Dictionary).get("gil", 0)), 8000, "gil capped per resource")
	_eq(int((cap_preview.get("resources", {}) as Dictionary).get("material:GL:900101@base", 0)), 16, "material capped per resource")
	var capped: Dictionary = economy.call("settle", 1000000)
	_result_ok(capped, "capped settlement succeeds")
	_eq(int(_section("economy").get("last_settled_unix", 0)), 1000000, "whole away period consumed once")
	var after_capped: String = _fingerprint()
	_result_fail(economy.call("settle", 1000000), "already_claimed", "same away period not reclaimed")
	_assert_unchanged(after_capped, "repeated capped settlement")
	_result_ok(economy.call("settle", 1007200), "new away period after cap settles")
	_eq(int(_section("economy").get("last_settled_unix", 0)), 1007200, "next session starts at new timestamp")

	_fresh(0)
	var party: Dictionary = state.call("get_party", "default")
	party["slots"] = [party["slots"][0], party["slots"][1]]
	state.call("set_party", "default", party)
	var small_party: Dictionary = economy.call("status", 3600)
	_eq(int((small_party.get("resources", {}) as Dictionary).get("gil", 0)), 900, "small party modifier applied")
	_eq(str(small_party.get("modifier", "")), "synthetic_small_party", "modifier labeled synthetic")
	return true


# --- shop system ---------------------------------------------------------------

func test_shop_system() -> bool:
	_fresh(0)
	var shops: RefCounted = _system("res://systems/shop_system.gd")
	_eq((shops.call("shops") as Dictionary).size(), 4, "shops exposed")
	_eq((shops.call("stock", SHOP_1) as Array).size(), 2, "stock exposed")
	_data()["resources"]["gil"] = 100000
	var before: String = _fingerprint()
	_result_fail(shops.call("buy", "shop:GL:999999@base", STOCK_MATERIAL, 1, "bad-shop"), "unknown_shop", "unknown shop rejected")
	_result_fail(shops.call("buy", SHOP_1, "missing_stock", 1, "bad-stock"), "unknown_stock", "unknown stock rejected")
	_result_fail(shops.call("buy", SHOP_1, STOCK_MATERIAL, 0, "zero-qty"), "invalid_quantity", "zero quantity rejected")
	_result_fail(shops.call("buy", SHOP_1, STOCK_MATERIAL, 100, "large-qty"), "invalid_quantity", "quantity above cap rejected")
	_assert_unchanged(before, "invalid shop purchases")

	var bought: Dictionary = shops.call("buy", SHOP_1, STOCK_MATERIAL, 2, "receipt-1")
	_result_ok(bought, "material stock purchased")
	_eq(_resource("gil"), 95000, "shop gil cost charged")
	_eq(_resource("material:GL:900101@base"), 122, "material output granted")
	_ok(_section("shops").get("claims", {}).has("shop|%s|%s|receipt-1" % [SHOP_1, STOCK_MATERIAL]), "shop claim format")
	_eq(int(_section("shops").get("purchases", {}).get("%s|%s" % [SHOP_1, STOCK_MATERIAL], 0)), 2, "purchase count recorded")
	var after_buy: String = _fingerprint()
	_result_fail(shops.call("buy", SHOP_1, STOCK_MATERIAL, 2, "receipt-1"), "already_claimed", "same shop receipt idempotent")
	_assert_unchanged(after_buy, "repeat shop receipt")
	_result_fail(shops.call("buy", SHOP_1, STOCK_MATERIAL, 2, "receipt-2"), "limit_reached", "stock limit enforced")
	_assert_unchanged(after_buy, "stock limit")
	_result_ok(shops.call("buy", SHOP_1, STOCK_MATERIAL, 1, "receipt-3"), "last stock unit purchased")
	_result_fail(shops.call("buy", SHOP_1, STOCK_MATERIAL, 1, "receipt-4"), "limit_reached", "stock exhausted")

	var gated: Dictionary = shops.call("buy", SHOP_1, STOCK_SHIELD, 1, "shield-1")
	_result_fail(gated, "flag_required", "flag-gated stock rejected")
	_assert_unchanged(_fingerprint(), "flag-gated stock")
	_data()["flags"]["shop_synthetic_advanced"] = true
	var equipment_before: int = state.call("inventory_section", "equipment").size()
	var shield: Dictionary = shops.call("buy", SHOP_1, STOCK_SHIELD, 1, "shield-2")
	_result_ok(shield, "flag-gated stock purchased after flag")
	_eq(state.call("inventory_section", "equipment").size(), equipment_before + 1, "shield added to inventory")
	var uids: Array = shield.get("uids", [])
	var uid: String = str(uids[0]) if not uids.is_empty() else ""
	_ok(uid.begins_with("owned:GL:500003:") and uid.ends_with("@shield"), "item UID format %s" % uid)
	_ok(not state.call("find_inventory_entry", uid).is_empty(), "purchased item findable")
	_data()["resources"]["gil"] = 0
	var poor: String = _fingerprint()
	_result_fail(shops.call("buy", SHOP_2, STOCK_MATERIA, 1, "poor"), "insufficient_resources", "poor shop purchase rejected")
	_assert_unchanged(poor, "poor shop purchase")
	_data()["resources"]["gil"] = 20000
	var materia_before: int = state.call("inventory_section", "materia").size()
	_result_ok(shops.call("buy", SHOP_2, STOCK_MATERIA, 1, "jp-1"), "JP shop purchase succeeds")
	_eq(state.call("inventory_section", "materia").size(), materia_before + 1, "JP materia added")
	var jp_buy: Dictionary = shops.call("buy", SHOP_2, STOCK_MATERIA, 1, "jp-2")
	var jp_uids: Array = jp_buy.get("uids", [])
	var jp_uid: String = str(jp_uids[0]) if not jp_uids.is_empty() else ""
	_ok(jp_uid.begins_with("owned:JP:600004:"), "JP item UID retains region")
	return true


func test_shop_receipt_and_uid_integrity() -> bool:
	_fresh(0)
	var shops: RefCounted = _system("res://systems/shop_system.gd")
	_data()["resources"]["gil"] = 20000
	var before: String = _fingerprint()
	_result_fail(shops.call("buy", SHOP_1, STOCK_MATERIAL, 1, ""), "invalid_receipt", "empty shop receipt")
	_result_fail(shops.call("buy", SHOP_1, STOCK_MATERIAL, 1, "   "), "invalid_receipt", "whitespace shop receipt")
	_result_fail(shops.call("buy", SHOP_1, STOCK_MATERIAL, 1, "s".repeat(129)), "invalid_receipt", "oversized shop receipt")
	_assert_unchanged(before, "invalid shop receipts")

	var padded: Dictionary = shops.call("buy", SHOP_1, STOCK_MATERIAL, 1, "  shop-padded  ")
	_result_ok(padded, "padded shop receipt normalized")
	_eq(str(padded.get("key", "")), "shop|%s|%s|shop-padded" % [SHOP_1, STOCK_MATERIAL],
		"normalized shop claim key")
	var after_pad: String = _fingerprint()
	_result_fail(shops.call("buy", SHOP_1, STOCK_MATERIAL, 1, "shop-padded"), "already_claimed",
		"normalized shop receipt cannot charge twice")
	_assert_unchanged(after_pad, "normalized shop receipt idempotency")

	_fresh(0)
	_data()["resources"]["gil"] = 50000
	var materia_before: int = state.call("inventory_section", "materia").size()
	var multi: Dictionary = shops.call("buy", SHOP_2, STOCK_MATERIA, 2, "jp-multi")
	_result_ok(multi, "multi-quantity shop purchase succeeds")
	var uids: Array = multi.get("uids", [])
	_eq(uids.size(), 2, "two item UIDs granted")
	_ok(str(uids[0]) != str(uids[1]), "multi-quantity UIDs are unique")
	_eq(state.call("inventory_section", "materia").size(), materia_before + 2, "JP materia added once per unit")
	for uid_variant: Variant in uids:
		_ok(str(uid_variant).begins_with("owned:JP:600004:"), "JP UID keeps shop region")
	return true


func test_shop_commit_rollback() -> bool:
	_fresh(0)
	var shops: RefCounted = _system("res://systems/shop_system.gd")
	_data()["resources"]["gil"] = 50000
	var save_manager: Node = _save_manager()
	if save_manager == null:
		_ok(false, "shop rollback fixture has SaveManager")
		return true
	var before: String = _fingerprint()
	save_manager.call("fail_next_atomic_write")
	_result_fail(shops.call("buy", SHOP_1, STOCK_MATERIAL, 1, "shop-fault"), "save_failed",
		"shop commit failure rejected")
	_eq(_fingerprint(), before, "failed shop commit restores full state")
	_eq((_section("shops").get("claims", {}) as Dictionary).size(), 0, "failed shop purchase records no claim")
	_eq((_section("shops").get("purchases", {}) as Dictionary).size(), 0, "failed shop purchase records no stock use")
	_result_ok(shops.call("buy", SHOP_1, STOCK_MATERIAL, 1, "shop-after-fault"),
		"shop succeeds after fault consumed")
	return true


# --- crafting system -----------------------------------------------------------

func test_crafting_system() -> bool:
	_fresh(0)
	var crafting: RefCounted = _system("res://systems/crafting_system.gd")
	_eq((crafting.call("recipes") as Dictionary).size(), 3, "recipes exposed")
	var before: String = _fingerprint()
	_result_fail(crafting.call("start", "recipe:GL:999999@base", 1000), "unknown_recipe", "unknown recipe rejected")
	_result_fail(crafting.call("start", RECIPE_2, 1000), "flag_required", "flag-gated recipe rejected")
	_assert_unchanged(before, "invalid starts")
	_data()["resources"]["gil"] = 0
	_data()["resources"]["material:GL:900101@base"] = 0
	_result_fail(crafting.call("start", RECIPE_1, 1000), "insufficient_resources", "unaffordable recipe rejected")
	_assert_unchanged(_fingerprint(), "unaffordable recipe")

	_fresh(0)
	var started: Dictionary = crafting.call("start", RECIPE_1, 1000)
	_result_ok(started, "crafting started")
	var job: Dictionary = started.get("job", {})
	_eq(str(job.get("id", "")), "craft:1", "job sequence ID")
	_eq(int(job.get("ready_at", 0)), 1120, "job ready time from synthetic duration")
	_eq(_resource("gil"), 497000, "crafting inputs charged")
	_eq(_resource("material:GL:900101@base"), 117, "crafting material charged")
	var status: Dictionary = crafting.call("status", 1000)
	_ok((status.get("jobs", {}) as Dictionary).has("craft:1"), "status lists active job")
	var early: Dictionary = crafting.call("settle", 1119)
	_eq((early.get("changed", []) as Array).size(), 0, "early settle changes nothing")
	_result_ok(crafting.call("settle", 1120), "ready job settled")
	_eq(str((_section("crafting").get("jobs", {}) as Dictionary).get("craft:1", {}).get("status", "")), "claimable", "settled job claimable")
	_result_ok(crafting.call("settle", 1121), "repeat settle is a no-op")

	var equipment_before: int = state.call("inventory_section", "equipment").size()
	var claimed: Dictionary = crafting.call("claim", "craft:1", 1120)
	_result_ok(claimed, "claimable job claimed")
	_eq(state.call("inventory_section", "equipment").size(), equipment_before + 1, "craft output added to inventory")
	_ok(_section("crafting").get("claims", {}).has("craft|craft:1|claim"), "craft claim key format")
	var after_claim: String = _fingerprint()
	_result_fail(crafting.call("claim", "craft:1", 1120), "already_claimed", "repeat craft claim rejected")
	_assert_unchanged(after_claim, "repeat craft claim")
	_result_fail(crafting.call("claim", "craft:999"), "unknown_job", "unknown craft job rejected")

	var second: Dictionary = crafting.call("start", RECIPE_1, 2000)
	_result_ok(second, "second crafting job started")
	before = _fingerprint()
	_result_ok(crafting.call("settle", 2100), "early settle succeeds with no change")
	_assert_unchanged(before, "early settle does not mutate")
	var gil_before: int = _resource("gil")
	var material_before: int = _resource("material:GL:900101@base")
	_result_ok(crafting.call("cancel", "craft:2", 2100), "in-progress job cancelled")
	_eq(_resource("gil"), gil_before + 3000, "cancel refunds gil exactly once")
	_eq(_resource("material:GL:900101@base"), material_before + 3, "cancel refunds material exactly once")
	before = _fingerprint()
	_result_fail(crafting.call("cancel", "craft:2"), "job_ready", "cancelled job cannot refund twice")
	_result_fail(crafting.call("claim", "craft:2"), "not_claimable", "cancelled job cannot be claimed")
	_assert_unchanged(before, "cancelled job claims")

	_data()["flags"]["craft_synthetic_advanced"] = true
	_result_ok(crafting.call("start", RECIPE_2, 3000), "gated recipe starts after flag")
	_result_ok(crafting.call("settle", 3060), "gated job settles")
	var recipe_claim: Dictionary = crafting.call("claim", "craft:3", 3060)
	_result_ok(recipe_claim, "gated recipe claimed")
	_ok((recipe_claim.get("granted", {}) as Dictionary).has("material:GL:900103@base"), "recipe material output granted")

	var exchange: Dictionary = crafting.call("start", RECIPE_3, 4000)
	_result_ok(exchange, "JP recipe starts")
	_result_ok(crafting.call("settle", 4030), "JP recipe settles")
	var material_900101: int = _resource("material:GL:900101@base")
	_result_ok(crafting.call("claim", "craft:4", 4030), "JP recipe claimed")
	_eq(_resource("material:GL:900101@base"), material_900101 + 2, "JP recipe resource output granted")
	return true


func test_crafting_output_rollback() -> bool:
	_fresh(0)
	var crafting: RefCounted = _system("res://systems/crafting_system.gd")
	var save_manager: Node = _save_manager()
	if save_manager == null:
		_ok(false, "crafting rollback fixture has SaveManager")
		return true
	var before_start: String = _fingerprint()
	save_manager.call("fail_next_atomic_write")
	_result_fail(crafting.call("start", RECIPE_1, 1000), "save_failed", "crafting start commit failure rejected")
	_eq(_fingerprint(), before_start, "failed craft start restores input resources")
	_result_ok(crafting.call("start", RECIPE_1, 1000), "crafting start succeeds after fault consumed")

	_result_ok(crafting.call("settle", 1120), "job settled for grant checks")
	var tampered: Dictionary = _data()
	((tampered.get("crafting", {}) as Dictionary).get("jobs", {}) as Dictionary)["craft:1"]["outputs"] = {
		"item:GL:999999@base": 1
	}
	state.set("data", tampered)
	var before_grant: String = _fingerprint()
	_result_fail(crafting.call("claim", "craft:1", 1120), "invalid_definition", "invalid craft output rejected")
	_assert_unchanged(before_grant, "invalid craft output")

	_fresh(0)
	_result_ok(crafting.call("start", RECIPE_1, 1000), "crafting restart for commit failure")
	_result_ok(crafting.call("settle", 1120), "restarted job settled")
	var before_claim: String = _fingerprint()
	save_manager.call("fail_next_atomic_write")
	_result_fail(crafting.call("claim", "craft:1", 1120), "save_failed", "craft claim commit failure rejected")
	_eq(_fingerprint(), before_claim, "failed craft claim restores full state")
	_result_ok(crafting.call("claim", "craft:1", 1120), "craft claim succeeds after fault consumed")

	_result_ok(crafting.call("start", RECIPE_1, 2000), "second craft job started")
	var before_cancel: String = _fingerprint()
	save_manager.call("fail_next_atomic_write")
	_result_fail(crafting.call("cancel", "craft:2", 2010), "save_failed", "craft refund commit failure rejected")
	_eq(_fingerprint(), before_cancel, "failed craft refund restores full state")
	_result_ok(crafting.call("cancel", "craft:2", 2010), "craft refund succeeds after fault consumed")
	return true


func test_crafting_save_reload() -> bool:
	_fresh(0)
	var crafting: RefCounted = _system("res://systems/crafting_system.gd")
	var claimed_job: Dictionary = crafting.call("start", RECIPE_1, 1000)
	var claim_id: String = str(claimed_job.get("key", ""))
	_result_ok(crafting.call("settle", 1120), "claimed job settled")
	_result_ok(crafting.call("claim", claim_id, 1120), "claimed job granted")

	var cancelled_job: Dictionary = crafting.call("start", RECIPE_1, 2000)
	var cancel_id: String = str(cancelled_job.get("key", ""))
	_result_ok(crafting.call("cancel", cancel_id, 2010), "cancelled job refunded")

	_eq(state.call("save"), OK, "crafting save/reload fixture saves")
	var reloaded: Dictionary = state.call("load_state", 0) as Dictionary
	_ok(not reloaded.is_empty(), "crafting state reloads")
	var jobs: Dictionary = ((reloaded.get("crafting", {}) as Dictionary).get("jobs", {}) as Dictionary)
	_eq(str((jobs.get(claim_id, {}) as Dictionary).get("status", "")), "claimed", "claimed job status reloaded")
	_eq(str((jobs.get(cancel_id, {}) as Dictionary).get("status", "")), "cancelled", "cancelled job status reloaded")
	var claims: Dictionary = (reloaded.get("crafting", {}) as Dictionary).get("claims", {})
	_ok(claims.has("craft|%s|claim" % claim_id), "craft claim survives reload")
	_ok(claims.has("craft|%s|refund" % cancel_id), "refund claim survives reload")

	state.set("data", reloaded)
	var after_reload: String = _fingerprint()
	_result_fail(crafting.call("claim", claim_id, 3000), "already_claimed", "reloaded claim not repeated")
	_result_fail(crafting.call("cancel", cancel_id, 3000), "job_ready", "reloaded refund not repeated")
	_assert_unchanged(after_reload, "reloaded craft idempotency")
	return true


func test_end_to_end_flow() -> bool:
	_fresh(0)
	state.call("grant", {"gil": 1000000, "lapis": 2000, "material:GL:900101@base": 200})

	# Battle result -> separated reward buckets -> idempotent settlement.
	var battle_result: Dictionary = {
		"victory": true,
		"encounter_id": "encounter:GL:950002@boss",
		"run_id": "run:qa:e2e",
		"reward_policy": {"repeatable": true, "first_clear": true},
		"rewards": {
			"repeat": {"gil": 1000},
			"first_clear": {"lapis": 100},
			"missions": [{"id": "kill_boss", "reward": {"gil": 500}}]
		}
	}
	var battle_claim: Dictionary = state.call("claim_battle_reward", battle_result)
	_result_ok(battle_claim, "E2E battle reward claim")
	_result_fail(state.call("claim_battle_reward", battle_result), "already_claimed", "E2E duplicate battle claim")

	var economy: RefCounted = _system("res://systems/economy_system.gd")
	_result_ok(economy.call("settle", 8200), "E2E offline settlement")
	var shop: RefCounted = _system("res://systems/shop_system.gd")
	_result_ok(shop.call("buy", SHOP_1, STOCK_MATERIAL, 1, "e2e-shop"), "E2E shop purchase")
	var crafting: RefCounted = _system("res://systems/crafting_system.gd")
	var craft_start: Dictionary = crafting.call("start", RECIPE_1, 100)
	_result_ok(craft_start, "E2E crafting start")
	var craft_id: String = str(craft_start.get("key", ""))
	_result_ok(crafting.call("settle", 300), "E2E crafting settle")
	_result_ok(crafting.call("claim", craft_id, 300), "E2E crafting claim")
	var summon: RefCounted = _system("res://systems/summon_system.gd")
	_result_ok(summon.call("summon", BANNER_1, 4242, "e2e-summon"), "E2E summon")

	# Explicit save/reload pass: all namespaced ledgers and owned instances survive.
	_eq(state.call("save"), OK, "E2E save")
	var reloaded: Dictionary = state.call("load_state")
	_ok(not reloaded.is_empty(), "E2E reload returns state")
	state.set("data", reloaded)
	_ok((_section("reward_claims") as Dictionary).has("battle|run|run:qa:e2e"), "E2E battle claim reloaded")
	_ok(((_section("economy") as Dictionary).get("claims", {}) as Dictionary).has("offline|0|8200"), "E2E offline claim reloaded")
	_ok(((_section("shops") as Dictionary).get("claims", {}) as Dictionary).has("shop|%s|%s|e2e-shop" % [SHOP_1, STOCK_MATERIAL]), "E2E shop claim reloaded")
	_ok(((_section("crafting") as Dictionary).get("claims", {}) as Dictionary).has("craft|%s|claim" % craft_id), "E2E craft claim reloaded")
	_ok(((_section("summon") as Dictionary).get("claims", {}) as Dictionary).has("summon|%s|e2e-summon" % BANNER_1), "E2E summon claim reloaded")
	_ok((_data().get("owned_units", []) as Array).size() > 6, "E2E summoned unit reloaded")
	return true
