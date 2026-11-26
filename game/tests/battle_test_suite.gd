class_name BattleTestSuite
extends RefCounted

## Deterministic combat assertions driven by the UI-independent engine.
## All fixtures come from ContentRepository and are marked SYNTHETIC_FIXTURE.

const SKIRMISH := "encounter:GL:950001@skirmish"
const BOSS := "encounter:GL:950002@boss"
const VANGUARD := "unit:GL:910101@base"
const ARCANIST := "unit:GL:910102@base"
const MENDER := "unit:GL:910103@base"
const WARDEN := "unit:JP:910104@base"
const BULWARK := "unit:GL:910105@base"
const BOSS_ID := "enemy:GL:920001@boss"
const ADEPT := "enemy:GL:920002@base"
const BRUTE := "enemy:GL:920003@base"

var runner: Object
var manager_script: Script
var rng_script: Script
var clock_script: Script
var chain_script: Script
var damage_script: Script
var status_script: Script
var lb_script: Script
var element_script: Script
var target_script: Script
var ai_script: Script
var reward_script: Script
var combatant_script: Script
var state_script: Script
var action_script: Script


func _init(p_runner: Object) -> void:
	runner = p_runner
	manager_script = load("res://battle/battle_manager.gd") as Script
	rng_script = load("res://battle/battle_rng.gd") as Script
	clock_script = load("res://battle/battle_clock.gd") as Script
	chain_script = load("res://battle/chain_manager.gd") as Script
	damage_script = load("res://battle/damage_calculator.gd") as Script
	status_script = load("res://battle/status_effect_manager.gd") as Script
	lb_script = load("res://battle/limit_burst_manager.gd") as Script
	element_script = load("res://battle/element_resolver.gd") as Script
	target_script = load("res://battle/target_resolver.gd") as Script
	ai_script = load("res://battle/enemy_ai.gd") as Script
	reward_script = load("res://battle/reward_resolver.gd") as Script
	combatant_script = load("res://battle/combatant_state.gd") as Script
	state_script = load("res://battle/battle_state.gd") as Script
	action_script = load("res://battle/battle_action.gd") as Script


func run() -> bool:
	if manager_script == null or runner == null:
		push_error("FAIL battle suite scripts unavailable")
		return false

	test_initialization()
	test_definition_immutability()
	test_action_validation()
	test_target_resolution()
	test_turn_transitions()
	test_physical_and_magical_damage()
	test_guard_and_elements()
	test_healing_and_mp()
	test_buffs_breaks_and_statuses()
	test_multi_hit_and_chains()
	test_limit_burst()
	test_enemy_ai()
	test_victory_and_rewards()
	test_defeat()
	test_unsupported_effects()
	test_items()
	test_deterministic_replay()
	test_clock_and_events()
	return true


func _ok(condition: bool, label: String) -> void:
	runner.call("assert_true", condition, label)


func _eq(actual: Variant, expected: Variant, label: String) -> void:
	runner.call("assert_eq", actual, expected, label)


func _package() -> Dictionary:
	return ContentRepository.call("get_battle_package")


func _manager(encounter_id: String = SKIRMISH, seed_value: int = 4242) -> RefCounted:
	var package: Dictionary = _package()
	return manager_script.new(
		ContentRepository.call("get_encounter", encounter_id),
		package.get("combatants", {}),
		package.get("abilities", {}),
		package.get("items", {}),
		seed_value
	)


func _combatant(definition_id: String, side: String = "party") -> RefCounted:
	return combatant_script.call(
		"from_definition", ContentRepository.call("get_battle_combatant", definition_id), side
	)


func _run_turn(manager: RefCounted, actions: Array[Dictionary] = []) -> Dictionary:
	for action: Dictionary in actions:
		var queued: Dictionary = manager.call(
			"queue_action",
			str(action.get("actor", "")),
			str(action.get("ability", "")),
			str(action.get("target", "")),
			str(action.get("source", "ability"))
		)
		_ok(bool(queued.get("ok", false)), "queued %s" % str(action.get("ability", "")))
	return manager.call("execute_turn")


func _events_of_type(manager: RefCounted, event_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event: Dictionary in manager.get("state").get("events"):
		if str(event.get("type", "")) == event_type:
			result.append(event)
	return result


# ---------------------------------------------------------------------------
# Initialization and validation
# ---------------------------------------------------------------------------

func test_initialization() -> void:
	var manager: RefCounted = _manager()
	manager.call("start_battle")
	var state: RefCounted = manager.get("state")
	_eq(state.party.size(), 5, "party size")
	_eq(state.enemies.size(), 2, "skirmish enemy count")
	_eq(state.turn, 1, "initial turn")
	_eq(state.phase, "player", "initial phase")
	_eq(str(ContentRepository.call("get_encounter", SKIRMISH).get("fixture_marker", "")), "SYNTHETIC_FIXTURE", "skirmish marker present")

	var roles: Array[String] = []
	for combatant in state.party:
		roles.append(str(combatant.role))
		_eq(str(combatant.side), "party", "party side")
		_ok(str(ContentRepository.call("get_battle_combatant", combatant.id).get("verification_status", "")) == "SYNTHETIC_FIXTURE", "party fixture marker")
	for expected_role: String in ["physical_attacker", "magical_attacker", "healer", "support", "defensive"]:
		_ok(roles.has(expected_role), "role present: %s" % expected_role)
	for combatant in state.enemies:
		_eq(str(combatant.side), "enemy", "enemy side")
		_ok(str(ContentRepository.call("get_battle_combatant", combatant.id).get("verification_status", "")) == "SYNTHETIC_FIXTURE", "enemy fixture marker")

	var boss_manager: RefCounted = _manager(BOSS)
	boss_manager.call("start_battle")
	_ok(bool(boss_manager.get("state").boss), "boss encounter flag")
	_eq(boss_manager.get("state").enemies.size(), 3, "boss encounter enemies")
	_ok(boss_manager.get("state").find_combatant(BOSS_ID) != null, "boss present")


func test_definition_immutability() -> void:
	var before: Dictionary = ContentRepository.call("get_battle_combatant", VANGUARD)
	var manager: RefCounted = _manager()
	manager.call("start_battle")
	_run_turn(manager, [{"actor": VANGUARD, "ability": "ability:GL:931001@base", "target": ADEPT}])
	var after: Dictionary = ContentRepository.call("get_battle_combatant", VANGUARD)
	_eq(JSON.stringify(after), JSON.stringify(before), "immutable fixture definition unchanged")


func test_action_validation() -> void:
	var manager: RefCounted = _manager()
	manager.call("start_battle")
	_eq(str(manager.call("validate_action", "unit:GL:999999@base", "ability:GL:931001@base", ADEPT).get("reason", "")), "actor_unavailable", "unknown actor rejected")
	_eq(str(manager.call("validate_action", VANGUARD, "ability:GL:999999@base", ADEPT).get("reason", "")), "unknown_action", "unknown ability rejected")
	_ok(str(manager.call("validate_action", VANGUARD, "ability:GL:931001@base", VANGUARD).get("reason", "")).begins_with("wrong_side:"), "wrong side target rejected")
	_eq(str(manager.call("validate_action", VANGUARD, "ability:GL:932001@base", ADEPT).get("reason", "")), "lb_not_ready", "LB not ready rejected")
	_ok(str(manager.call("validate_action", MENDER, "ability:GL:931103@base", ADEPT).get("reason", "")).begins_with("wrong_side:"), "heal cannot target enemy")
	_ok(bool(manager.call("validate_action", MENDER, "ability:GL:931103@base", VANGUARD).get("ok", false)), "heal ally accepted")
	_ok(bool(manager.call("queue_guard", BULWARK).get("ok", false)), "guard accepted")
	_eq(int(manager.call("summary").get("queue_size", 0)), 1, "guard queued")
	manager.call("begin_execution")
	_eq(str(manager.call("validate_action", ARCANIST, "ability:GL:931002@base", ADEPT).get("reason", "")), "not_player_phase", "input locked during execution")


func test_target_resolution() -> void:
	var manager: RefCounted = _manager()
	manager.call("start_battle")
	var state: RefCounted = manager.get("state")
	var all_allies: RefCounted = action_script.new()
	all_allies.actor_id = WARDEN
	all_allies.targeting = "all_allies"
	var resolved: Dictionary = target_script.call("resolve", all_allies, state)
	_ok(bool(resolved.get("ok", false)), "all_allies resolves")
	_eq((resolved.get("targets", []) as Array).size(), 5, "all_allies expands to five")

	var all_enemies: RefCounted = action_script.new()
	all_enemies.actor_id = VANGUARD
	all_enemies.targeting = "all_enemies"
	var enemy_targets: Dictionary = target_script.call("resolve", all_enemies, state)
	_eq((enemy_targets.get("targets", []) as Array).size(), 2, "all_enemies expands to two")

	var self_action: RefCounted = action_script.new()
	self_action.actor_id = VANGUARD
	self_action.targeting = "self"
	_eq(str((target_script.call("resolve", self_action, state).get("targets", []) as Array)[0]), VANGUARD, "self resolves")

	var missing: RefCounted = action_script.new()
	missing.actor_id = VANGUARD
	missing.targeting = "enemy"
	_eq(str(target_script.call("resolve", missing, state).get("reason", "")), "target_missing", "empty target rejected")
	state.find_combatant(ADEPT).hp = 0
	var downed_target: Array[String] = []
	downed_target.append(ADEPT)
	missing.target_ids = downed_target
	_eq(str(target_script.call("resolve", missing, state).get("reason", "")), "target_missing_or_down:%s" % ADEPT, "downed target rejected")


func test_turn_transitions() -> void:
	var manager: RefCounted = _manager()
	manager.call("start_battle")
	_eq(str(manager.get("state").phase), "player", "phase starts player")
	_ok(bool(manager.call("queue_action", VANGUARD, "ability:GL:931001@base", ADEPT).get("ok", false)), "action queued for phase test")
	manager.call("begin_execution")
	_eq(str(manager.get("state").phase), "player_execution", "player execution phase")
	for frame_index: int in range(300):
		manager.call("advance_frames", 1)
		if str(manager.get("state").phase) == "player":
			break
	_eq(str(manager.get("state").phase), "player", "phase returns to player")
	_eq(int(manager.get("state").turn), 2, "turn increments")
	_ok(bool(manager.call("queue_action", VANGUARD, "ability:GL:931001@base", ADEPT).get("ok", false)), "second turn action queued")
	manager.call("begin_execution")
	_eq(str(manager.get("state").phase), "player_execution", "second execution phase")


# ---------------------------------------------------------------------------
# Damage, elements, healing and statuses
# ---------------------------------------------------------------------------

func _damage(kind: String, attacker: RefCounted, target: RefCounted, ability_id: String, hit: Dictionary, seed_value: int = 7) -> Dictionary:
	var calculator: RefCounted = damage_script.new()
	var ability: Dictionary = ContentRepository.call("get_ability_definition", ability_id)
	ability["kind"] = kind
	return calculator.call(
		"calculate", attacker, target, ability, hit,
		1.0, rng_script.new(seed_value)
	)


func test_physical_and_magical_damage() -> void:
	var attacker: RefCounted = _combatant(VANGUARD)
	var target: RefCounted = _combatant(BOSS_ID, "enemy")
	var physical: Dictionary = _damage("physical", attacker, target, "ability:GL:931001@base", {"element": "non_elemental", "weight": 1.0})
	_ok(bool(physical.get("ok", false)), "physical damage calculated")
	_ok(int(physical.get("amount", 0)) > 0, "physical damage positive")
	var breakdown: Dictionary = physical.get("breakdown", {})
	_eq(str(breakdown.get("offensive_stat", "")), "atk", "physical uses ATK")
	_eq(str(breakdown.get("defensive_stat", "")), "def", "physical uses DEF")
	_eq(float(breakdown.get("level_correction", 0.0)), 1.5, "level correction from level 50")
	_ok(float(breakdown.get("final_variance", 0.0)) >= 0.85 and float(breakdown.get("final_variance", 0.0)) <= 1.0, "final variance in documented range")

	var magic_attacker: RefCounted = _combatant(ARCANIST)
	var magical: Dictionary = _damage("magical", magic_attacker, target, "ability:GL:931002@base", {"element": "fire", "weight": 1.0})
	_ok(bool(magical.get("ok", false)), "magical damage calculated")
	var magic_breakdown: Dictionary = magical.get("breakdown", {})
	_eq(str(magic_breakdown.get("offensive_stat", "")), "mag", "magical uses MAG")
	_eq(str(magic_breakdown.get("defensive_stat", "")), "spr", "magical uses SPR")

	var unsupported: Dictionary = _damage("white", attacker, target, "ability:GL:931003@base", {"element": "non_elemental", "weight": 1.0})
	_eq(str(unsupported.get("reason", "")), "unsupported_damage_kind", "non-damaging kind rejected")


func test_guard_and_elements() -> void:
	var attacker: RefCounted = _combatant(VANGUARD)
	var target: RefCounted = _combatant(BOSS_ID, "enemy")
	var hit: Dictionary = {"element": "fire", "weight": 1.0}
	var normal: Dictionary = _damage("physical", attacker, target, "ability:GL:931001@base", hit, 99)
	target.guard = true
	var guarded: Dictionary = _damage("physical", attacker, target, "ability:GL:931001@base", hit, 99)
	target.guard = false
	_eq(float(guarded.get("breakdown", {}).get("guard_multiplier", 0.0)), 0.5, "guard multiplier is 50 percent")
	_ok(int(guarded.get("amount", 0)) < int(normal.get("amount", 0)), "guard reduces damage")

	var neutral_target: RefCounted = _combatant(BRUTE, "enemy")
	var neutral: Dictionary = _damage("magical", _combatant(ARCANIST), neutral_target, "ability:GL:931002@base", hit, 31)
	var resisted: Dictionary = _damage("magical", _combatant(ARCANIST), target, "ability:GL:931002@base", hit, 31)
	_ok(float(resisted.get("breakdown", {}).get("element_multiplier", 1.0)) < float(neutral.get("breakdown", {}).get("element_multiplier", 1.0)), "fire resistance reduces multiplier")
	_ok(int(resisted.get("amount", 0)) <= int(neutral.get("amount", 0)), "fire resistance reduces damage")

	var manager: RefCounted = _manager(BOSS)
	manager.call("start_battle")
	var boss: RefCounted = manager.get("state").find_combatant(BOSS_ID)
	var element_resolver: RefCounted = element_script.new()
	var before: float = element_resolver.call("multiplier", ["fire"], boss)
	manager.get("status_manager").call("apply", boss, {"type": "imperil", "element": "fire", "percent": 30, "turns": 3}, VANGUARD, manager.get("rng"))
	var after: float = element_resolver.call("multiplier", ["fire"], boss)
	_ok(after > before, "imperil increases elemental damage taken")
	_eq(str(manager.get("status_manager").call("apply", boss, {"type": "buff", "stat": "def", "percent": 20, "turns": 2}, VANGUARD, manager.get("rng")).get("type", "")), "buff", "buff applied")


func test_healing_and_mp() -> void:
	var manager: RefCounted = _manager()
	manager.call("start_battle")
	var mender: RefCounted = manager.get("state").find_combatant(MENDER)
	var vanguard: RefCounted = manager.get("state").find_combatant(VANGUARD)
	vanguard.hp = 1000
	var mp_before: int = mender.mp
	var result: Dictionary = manager.call("execute_turn")
	_ok(bool(result.get("ok", false)), "empty turn executes")
	_ok(bool(manager.call("queue_action", MENDER, "ability:GL:931103@base", VANGUARD).get("ok", false)), "greater mend queued")
	var second: Dictionary = manager.call("begin_execution")
	_ok(bool(second.get("ok", false)), "second execution begins")
	manager.call("advance_frames", 200)
	_ok(vanguard.hp > 1000, "healing increases HP")
	_ok(mender.mp < mp_before, "MP consumed by ability")
	_eq(int(manager.get("state").find_combatant(MENDER).mp), mp_before - 16, "MP cost matches ability definition")
	vanguard.hp = vanguard.max_hp
	var direct: RefCounted = manager.get("state").find_combatant(VANGUARD)
	direct.hp = direct.max_hp - 1
	var overheal: int = direct.restore_hp(9999)
	_eq(overheal, 1, "healing clamps to max HP")


func test_buffs_breaks_and_statuses() -> void:
	var manager: RefCounted = _manager()
	manager.call("start_battle")
	var vanguard: RefCounted = manager.get("state").find_combatant(VANGUARD)
	var base_atk: int = vanguard.effective_stat("atk")
	manager.get("status_manager").call("apply", vanguard, {"type": "buff", "stat": "atk", "percent": 35, "turns": 2}, WARDEN, manager.get("rng"))
	_ok(vanguard.effective_stat("atk") > base_atk, "buff raises effective ATK")
	manager.get("status_manager").call("apply", vanguard, {"type": "break", "stat": "atk", "percent": 25, "turns": 2}, BOSS_ID, manager.get("rng"))
	_ok(vanguard.effective_stat("atk") > base_atk, "buff and break coexist; strongest dominates")
	manager.get("status_manager").call("tick", vanguard)
	manager.get("status_manager").call("tick", vanguard)
	_eq(vanguard.effective_stat("atk"), base_atk, "buffs and breaks expire after declared turns")
	_ok(bool(vanguard.has_status("status:sleep") == false), "no accidental sleep")
	manager.get("status_manager").call("apply", vanguard, {"type": "status", "status": "sleep", "chance": 100, "turns": 2}, BOSS_ID, manager.get("rng"))
	_ok(vanguard.has_status("status:sleep"), "sleep applied at 100 percent chance")
	_eq(str(manager.get("status_manager").call("can_act", vanguard, "physical").get("reason", "")), "sleep", "sleep blocks actions")
	manager.get("status_manager").call("tick", vanguard)
	manager.get("status_manager").call("tick", vanguard)
	_ok(not vanguard.has_status("status:sleep"), "sleep expires")
	var poison_target: RefCounted = manager.get("state").find_combatant(BULWARK)
	manager.get("status_manager").call("apply", poison_target, {"type": "status", "status": "poison", "chance": 100, "turns": 1}, BOSS_ID, manager.get("rng"))
	var hp_before: int = poison_target.hp
	manager.get("status_manager").call("tick", poison_target)
	_ok(poison_target.hp < hp_before, "poison ticks damage")
	var silence_target: RefCounted = manager.get("state").find_combatant(ARCANIST)
	manager.get("status_manager").call("apply", silence_target, {"type": "status", "status": "silence", "chance": 100, "turns": 2}, BOSS_ID, manager.get("rng"))
	_eq(str(manager.get("status_manager").call("can_act", silence_target, "magical").get("reason", "")), "silence", "silence blocks magical actions")
	_ok(bool(manager.get("status_manager").call("can_act", silence_target, "physical").get("ok", false)), "silence allows physical actions")


# ---------------------------------------------------------------------------
# Multi-hit, chains and LB
# ---------------------------------------------------------------------------

func test_multi_hit_and_chains() -> void:
	var manager: RefCounted = _manager(BOSS, 77)
	manager.call("start_battle")
	_run_turn(manager, [
		{"actor": VANGUARD, "ability": "ability:GL:931101@base", "target": BOSS_ID},
		{"actor": ARCANIST, "ability": "ability:GL:931102@base", "target": BOSS_ID}
	])
	var all_damage_events: Array[Dictionary] = _events_of_type(manager, "damage")
	var damage_events: Array[Dictionary] = []
	for event: Dictionary in all_damage_events:
		var data: Dictionary = event.get("data", {})
		var actor_id: String = str(data.get("actor_id", ""))
		if actor_id == VANGUARD or actor_id == ARCANIST:
			damage_events.append(event)
	_eq(damage_events.size(), 7, "four-hit plus three-hit skills produce seven hits")
	var chain_events: Array[Dictionary] = _events_of_type(manager, "chain")
	_ok(chain_events.size() >= 2, "chain events emitted")
	var max_chain: int = 0
	for event: Dictionary in chain_events:
		var chain: Dictionary = (event.get("data", {}) as Dictionary).get("chain", {})
		max_chain = maxi(max_chain, int(chain.get("count", 0)))
	_ok(max_chain > 0, "chain counter advanced")

	var chains: RefCounted = chain_script.new()
	var first: Dictionary = chains.call("register_hit", VANGUARD, 10, ["fire"], "synthetic_divine")
	_eq(int(first.get("count", 0)), 0, "first hit starts chain")
	var second: Dictionary = chains.call("register_hit", ARCANIST, 20, ["fire"], "synthetic_divine")
	_eq(int(second.get("count", 0)), 1, "different actor within 20 frames links")
	_eq(int(second.get("modifier", 0)), 30, "normal link +10 percent plus shared element +20 percent")
	var spark: Dictionary = chains.call("register_hit", VANGUARD, 20, ["ice"], "synthetic_divine")
	_ok(bool(spark.get("spark", false)), "zero-frame gap is spark")
	_eq(int(spark.get("modifier", 0)), 70, "spark +40 percent accumulates")
	var same_actor: Dictionary = chains.call("register_hit", VANGUARD, 21, ["fire"], "synthetic_divine")
	_eq(str(same_actor.get("reset_reason", "")), "same_actor", "same actor ends chain")
	var timeout: Dictionary = chains.call("register_hit", ARCANIST, 100, ["fire"], "synthetic_divine")
	_eq(str(timeout.get("reset_reason", "")), "timeout", "gap over 20 frames ends chain")
	for index: int in range(40):
		chains.call("register_hit", VANGUARD if index % 2 == 0 else ARCANIST, 200 + index, ["fire"], "test")
	_ok(int(chains.chain_modifier) <= 300, "chain modifier capped at 300 percent")


func test_limit_burst() -> void:
	var manager: RefCounted = _manager()
	manager.call("start_battle")
	var mender: RefCounted = manager.get("state").find_combatant(MENDER)
	var lbs: RefCounted = lb_script.new()
	for index: int in range(20):
		lbs.call("on_action_start", mender)
	_eq(mender.lb_gauge, 12, "automatic LB fill capped at 12")
	_ok(not lbs.call("can_use", mender), "LB not ready at 12 of 14")
	lbs.call("fill", mender, 2)
	_ok(bool(lbs.call("can_use", mender)), "LB ready at full gauge")
	var consumed: Dictionary = lbs.call("consume", mender)
	_ok(bool(consumed.get("ok", false)), "LB consumed")
	_eq(mender.lb_gauge, 0, "LB gauge resets")
	lbs.call("reset_turn")
	for index: int in range(3):
		lbs.call("on_action_start", mender)
	lbs.call("reset_turn")
	lbs.call("on_action_start", mender)
	_ok(mender.lb_gauge <= 12, "LB cap resets each turn")

	var lb_manager: RefCounted = _manager(BOSS, 91)
	lb_manager.call("start_battle")
	lb_manager.get("state").find_combatant(VANGUARD).lb_gauge = 12
	_run_turn(lb_manager, [{"actor": VANGUARD, "ability": "ability:GL:932001@base", "target": BOSS_ID}])
	_ok(_events_of_type(lb_manager, "limit_burst").size() > 0, "LB activation event consumed")
	_ok(_events_of_type(lb_manager, "damage").size() > 0, "LB multi-hit damage applied")


# ---------------------------------------------------------------------------
# Enemy AI, outcome and rewards
# ---------------------------------------------------------------------------

func test_enemy_ai() -> void:
	var manager: RefCounted = _manager(BOSS, 5150)
	manager.call("start_battle")
	var boss: RefCounted = manager.get("state").find_combatant(BOSS_ID)
	var ai: RefCounted = ai_script.new()
	var actions: Array = ai.call("decide_actions", boss, manager.get("state"), manager.get("rng"), 0)
	_eq(actions.size(), 2, "boss schedules two actions")
	var ability_ids: Array[String] = []
	for action: RefCounted in actions:
		ability_ids.append(action.ability_id)
		_ok(action.start_frame >= 0, "AI action has logical frame")
	_ok(ability_ids[0] != ability_ids[1], "boss actions use distinct abilities")
	var cooldown_entries: int = 0
	for key: String in ai.cooldowns.keys():
		if key.begins_with(BOSS_ID + ":") and int(ai.cooldowns[key]) > 0:
			cooldown_entries += 1
	_ok(cooldown_entries > 0, "used boss ability enters cooldown")

	var replay_manager: RefCounted = _manager(BOSS, 5150)
	replay_manager.call("start_battle")
	var replay_boss: RefCounted = replay_manager.get("state").find_combatant(BOSS_ID)
	var replay_ai: RefCounted = ai_script.new()
	var replay_actions: Array = replay_ai.call("decide_actions", replay_boss, replay_manager.get("state"), replay_manager.get("rng"), 0)
	var replay_ids: Array[String] = []
	for action: RefCounted in replay_actions:
		replay_ids.append(action.ability_id)
	_eq(str(replay_ids), str(ability_ids), "AI decisions deterministic for same seed")


func test_victory_and_rewards() -> void:
	var manager: RefCounted = _manager(SKIRMISH, 808)
	manager.call("start_battle")
	for enemy in manager.get("state").enemies:
		enemy.hp = 1
	_run_turn(manager, [
		{"actor": VANGUARD, "ability": "ability:GL:931001@base", "target": ADEPT},
		{"actor": VANGUARD, "ability": "ability:GL:931001@base", "target": BRUTE}
	])
	var result: RefCounted = manager.get("state").result
	_ok(result != null, "victory result created")
	if result == null:
		return
	_ok(bool(result.victory), "victory flag set")
	_eq(str(result.outcome), "victory", "victory outcome")
	var rewards: Dictionary = result.rewards
	_eq(int(rewards.get("gil", 0)), 400, "synthetic gil reward")
	_eq(int((rewards.get("items", []) as Array).size()), 1, "synthetic item reward")

	var resolver: RefCounted = reward_script.new()
	var lost: Dictionary = resolver.call("resolve", ContentRepository.call("get_encounter", SKIRMISH), false)
	_eq(int(lost.get("gil", 0)), 0, "defeat grants no reward")

	var record: Dictionary = result.call("to_dict")
	SaveManager.call("record_battle_result", record)
	var progress: Dictionary = SaveManager.call("load_battle_progress")
	var progress_data: Dictionary = progress.get("progress", {})
	_eq(int((progress_data.get("clears", {}) as Dictionary).get(SKIRMISH, 0)), 1, "clear persisted")
	_eq(int(progress_data.get("total_gil", 0)), 400, "gil persisted")
	_eq(int((progress_data.get("item_counts", {}) as Dictionary).get("item:GL:940001@base", 0)), 1, "item persisted")

	var legacy: Dictionary = {"version": 1, "completed": [SKIRMISH]}
	var migrated: Dictionary = SaveManager.call("migrate_battle_progress", legacy)
	_eq(int((migrated.get("progress", {}) as Dictionary).get("clears", {})[SKIRMISH]), 1, "version 1 progress migration")


func test_defeat() -> void:
	var manager: RefCounted = _manager(SKIRMISH, 606)
	manager.call("start_battle")
	for combatant in manager.get("state").party:
		combatant.hp = 1
	var forced_ai: Dictionary = {
		"max_actions": 1,
		"action_start_frames": [4],
		"pattern": [{
			"ability": "ability:GL:933002@base",
			"weight": 1,
			"min_hp_percent": 0,
			"max_hp_percent": 100,
			"target_rule": "all_enemies",
			"cooldown": 0
		}]
	}
	for enemy in manager.get("state").enemies:
		enemy.definition_data["ai"] = forced_ai.duplicate(true)
	manager.call("begin_execution")
	manager.call("advance_frames", 300)
	var result: RefCounted = manager.get("state").result
	_ok(result != null, "defeat result created")
	if result == null:
		return
	_ok(not bool(result.victory), "defeat flag set")
	_eq(str(result.outcome), "defeat", "defeat outcome")
	_eq(int(result.rewards.get("gil", 0)), 0, "defeat has no gil")


func test_unsupported_effects() -> void:
	var manager: RefCounted = _manager()
	manager.call("start_battle")
	var hp_before: int = manager.get("state").find_combatant(ADEPT).hp
	var queued: Dictionary = manager.call("queue_action", VANGUARD, "ability:GL:939999@base", ADEPT)
	_ok(bool(queued.get("ok", false)), "unsupported effect ability queues as a valid command")
	manager.call("begin_execution")
	manager.call("advance_frames", 100)
	_eq(int(manager.get("state").find_combatant(ADEPT).hp), hp_before, "unsupported effect does not mutate target HP")
	_ok(_events_of_type(manager, "unsupported_effect").size() > 0, "unsupported effect reported explicitly")


func test_items() -> void:
	var manager: RefCounted = _manager()
	manager.call("start_battle")
	var vanguard: RefCounted = manager.get("state").find_combatant(VANGUARD)
	vanguard.hp = 1000
	_ok(bool(manager.call("use_item", VANGUARD, "item:GL:940001@base", VANGUARD).get("ok", false)), "potion queued")
	manager.call("begin_execution")
	manager.call("advance_frames", 100)
	_ok(vanguard.hp > 1000, "potion heals")
	_ok(bool(manager.call("use_item", VANGUARD, "item:GL:940001@base", VANGUARD).get("ok", false)) == false, "potion exhausted after one use")


func test_deterministic_replay() -> void:
	var actions: Array[Dictionary] = [
		{"actor": VANGUARD, "ability": "ability:GL:931001@base", "target": ADEPT},
		{"actor": ARCANIST, "ability": "ability:GL:931002@base", "target": BRUTE},
		{"actor": WARDEN, "ability": "ability:JP:931104@base", "target": ADEPT}
	]
	var first: RefCounted = _manager(BOSS, 123456)
	first.call("start_battle")
	_run_turn(first, actions)
	var second: RefCounted = _manager(BOSS, 123456)
	second.call("start_battle")
	_run_turn(second, actions)
	var first_events: Array[Dictionary] = []
	var second_events: Array[Dictionary] = []
	for event: Dictionary in first.get("state").events:
		first_events.append({"frame": event.get("frame", 0), "type": event.get("type", "")})
	for event: Dictionary in second.get("state").events:
		second_events.append({"frame": event.get("frame", 0), "type": event.get("type", "")})
	_eq(JSON.stringify(first_events), JSON.stringify(second_events), "same seed and commands replay identical event timeline")
	_eq(str(first.get("rng").call("snapshot")), str(second.get("rng").call("snapshot")), "RNG state identical after replay")
	# Run identity is intentionally unique per manager instance. Determinism is
	# evaluated on the simulation snapshot only, excluding presentation-scoped
	# run metadata; the seed itself remains part of the compared state.
	var first_snapshot: Dictionary = first.get("state").call("snapshot")
	var second_snapshot: Dictionary = second.get("state").call("snapshot")
	for snapshot: Dictionary in [first_snapshot, second_snapshot]:
		snapshot.erase("run_id")
		snapshot.erase("seed_source")
	_eq(JSON.stringify(first_snapshot), JSON.stringify(second_snapshot), "battle snapshot identical after replay")


func test_clock_and_events() -> void:
	var clock: RefCounted = clock_script.new()
	clock.call("reset")
	_eq(clock.frame, 0, "clock resets to frame zero")
	_eq(clock.call("advance_frames", 9), 9, "clock advances logical frames")
	clock.call("set_frame", -4)
	_eq(clock.frame, 0, "clock clamps negative frames")
	var manager: RefCounted = _manager()
	manager.call("start_battle")
	_ok(_events_of_type(manager, "battle_start").size() == 1, "battle_start emitted once")
	var emitted: Array[Dictionary] = manager.call("advance_frames", 3)
	_ok(emitted.is_empty(), "advancing without schedule emits no effect events")
	_ok(int(manager.call("summary").get("frame", 0)) >= 3, "summary exposes logical frame")
