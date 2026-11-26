class_name BattleManager
extends RefCounted

## UI-independent battle orchestrator. Every stochastic rule uses BattleRNG and every
## timed hit uses BattleClock; presentation only consumes emitted events.

signal event_emitted(event: Dictionary)

var state: BattleState
var clock: BattleClock
var rng: BattleRNG
var queue: ActionQueue
var turn_manager: TurnManager
var chain_manager: ChainManager
var limit_manager: LimitBurstManager
var status_manager: StatusEffectManager
var damage_calculator: DamageCalculator
var effect_resolver: EffectResolver
var enemy_ai: EnemyAI
var reward_resolver: RewardResolver

var encounter_def: Dictionary = {}
var combatant_defs: Dictionary = {}
var ability_defs: Dictionary = {}
var item_defs: Dictionary = {}
var schedule: Array[ScheduledHit] = []
var schedule_index: int = 0
var item_uses: Dictionary = {}
var ability_uses: Dictionary = {}
var last_player_actions: Array[Dictionary] = []

static var _manager_counter: int = 0


func _init(
	p_encounter: Dictionary,
	p_combatants: Dictionary,
	p_abilities: Dictionary,
	p_items: Dictionary,
	seed_value: Variant = null,
	seed_source: String = "independent",
	run_id: String = ""
) -> void:
	encounter_def = p_encounter.duplicate(true)
	combatant_defs = p_combatants.duplicate(true)
	ability_defs = p_abilities.duplicate(true)
	item_defs = p_items.duplicate(true)

	state = BattleState.new()
	state.encounter_id = str(encounter_def.get("id", ""))
	state.encounter_name = str(encounter_def.get("name", ""))
	state.boss = bool(encounter_def.get("boss", false))
	state.seed = int(seed_value) if seed_value != null else _next_default_seed()
	state.seed_source = _normalize_seed_source(seed_source)
	state.run_id = run_id if not run_id.is_empty() else _new_run_id("manager")
	state.ability_defs = ability_defs.duplicate(true)

	for unit_id: String in encounter_def.get("party", []):
		if combatant_defs.has(unit_id):
			state.party.append(CombatantState.from_definition(combatant_defs[unit_id], "party"))
	for enemy_id: String in encounter_def.get("enemies", []):
		if combatant_defs.has(enemy_id):
			state.enemies.append(CombatantState.from_definition(combatant_defs[enemy_id], "enemy"))

	clock = BattleClock.new()
	rng = BattleRNG.new(seed_value)
	queue = ActionQueue.new()
	turn_manager = TurnManager.new()
	chain_manager = ChainManager.new()
	limit_manager = LimitBurstManager.new()
	status_manager = StatusEffectManager.new()
	damage_calculator = DamageCalculator.new()
	effect_resolver = EffectResolver.new(damage_calculator, status_manager, limit_manager, chain_manager)
	enemy_ai = EnemyAI.new()
	reward_resolver = RewardResolver.new()


## Godot 4.7 exposes a monotonic microsecond clock, not OS.get_unix_time_us().
## Combining it with a process counter keeps independent seeds and run ids
## unique across retries without relying on wall-clock precision.
static func _clock_usec() -> int:
	return Time.get_ticks_usec()


static func _next_default_seed() -> int:
	_manager_counter += 1
	return (_clock_usec() ^ (_manager_counter * 2654435761)) & 0x7FFFFFFFFFFFFFFF


static func _new_run_id(prefix: String) -> String:
	_manager_counter += 1
	return "run:%s:%d:%d" % [prefix, _clock_usec(), _manager_counter]


func _normalize_seed_source(source: String) -> String:
	return "qa_deterministic" if source == "qa_deterministic" else "independent"


func start_battle() -> Dictionary:
	clock.reset()
	rng.reset(state.seed)
	turn_manager.start_battle()
	state.turn = turn_manager.turn
	state.phase = turn_manager.phase
	chain_manager.reset()
	limit_manager.reset_turn()
	enemy_ai.reset()
	schedule.clear()
	schedule_index = 0
	item_uses.clear()
	ability_uses.clear()
	_emit("battle_start", {
		"message": "Battle started: %s" % state.encounter_name,
		"encounter_id": state.encounter_id,
		"seed": state.seed,
		"seed_source": state.seed_source,
		"run_id": state.run_id,
		"boss": state.boss
	})
	return state.snapshot()


func validate_action(
	actor_id: String,
	ability_id: String,
	target_id: String = "",
	source_type: String = "ability"
) -> Dictionary:
	if not turn_manager.is_player_input_allowed():
		return _invalid("not_player_phase")
	var actor: CombatantState = state.find_combatant(actor_id)
	if actor == null or actor.side != "party" or not actor.is_alive():
		return _invalid("actor_unavailable")

	var action := BattleAction.new()
	action.actor_id = actor_id
	action.ability_id = ability_id
	action.source_type = source_type
	if source_type == "guard":
		action.ability_id = "guard"
		action.targeting = "self"
		action.target_ids = [actor_id]
	else:
		var definition: Dictionary = _source_definition(source_type, ability_id)
		if definition.is_empty():
			return _invalid("unknown_action")
		action.targeting = str(definition.get("targeting", "enemy"))
		var requested_targets: Array[String] = []
		if not target_id.is_empty():
			requested_targets.append(target_id)
		action.target_ids = requested_targets

	var targets: Dictionary = TargetResolver.resolve(action, state)
	if not bool(targets.get("ok", false)):
		return _invalid(str(targets.get("reason", "invalid_target")))

	if source_type == "ability":
		var ability: Dictionary = ability_defs.get(ability_id, {})
		var mp_cost: int = int(ability.get("mp_cost", 0))
		if actor.mp - queue.reserved_mp(actor.id) < mp_cost:
			return _invalid("insufficient_mp")
		var uses_limit: int = maxi(int(ability.get("uses_per_battle", 0)), 0)
		if uses_limit > 0:
			var used: int = int(ability_uses.get(ability_id, 0)) + queue.queued_ability_uses(ability_id)
			if used >= uses_limit:
				return _invalid("ability_exhausted")
		var gate: Dictionary = status_manager.can_act(actor, str(ability.get("kind", "")))
		if not bool(gate.get("ok", false)):
			return _invalid(str(gate.get("reason", "action_blocked")))
		if bool(ability.get("is_limit_burst", false)):
			if str(ability_id) != actor.limit_ability:
				return _invalid("wrong_limit_burst")
			if queue.has_lb_reservation(actor.id) or not limit_manager.can_use(actor):
				return _invalid("lb_not_ready")
	elif source_type == "item":
		var used: int = int(item_uses.get(ability_id, 0)) + queue.queued_item_uses(ability_id)
		if used >= maxi(int(item_defs[ability_id].get("uses_per_battle", 1)), 1):
			return _invalid("item_exhausted")

	var resolved_targets: Array[String] = []
	for target_id_variant: Variant in targets.get("targets", []):
		resolved_targets.append(str(target_id_variant))
	action.target_ids = resolved_targets
	return {"ok": true, "action": action, "reason": ""}


func queue_action(
	actor_id: String,
	ability_id: String,
	target_id: String = "",
	source_type: String = "ability"
) -> Dictionary:
	var validation: Dictionary = validate_action(actor_id, ability_id, target_id, source_type)
	if not bool(validation.get("ok", false)):
		_emit("action_rejected", {
			"message": "Action rejected: %s" % str(validation.get("reason", "")),
			"actor_id": actor_id,
			"ability_id": ability_id,
			"reason": str(validation.get("reason", ""))
		})
		return validation
	var action: BattleAction = validation["action"]
	action.label = _action_label(action)
	var reserved: bool = queue.add(action, {
		"state": state,
		"ability_defs": ability_defs,
		"item_defs": item_defs,
		"status_manager": status_manager,
		"limit_manager": limit_manager,
		"item_uses": item_uses,
		"ability_uses": ability_uses
	})
	if not reserved:
		var reason := "queue_reservation_failed"
		_emit("action_rejected", {
			"message": "Action rejected: %s" % reason,
			"actor_id": actor_id,
			"ability_id": ability_id,
			"reason": reason
		})
		return {"ok": false, "reason": reason}
	_emit("action_queued", {
		"message": "%s queued %s" % [state.find_combatant(actor_id).display_name, action.label],
		"action": action.to_dict(),
		"queue_size": queue.size()
	})
	return {"ok": true, "action": action.to_dict(), "reason": ""}


func queue_guard(actor_id: String) -> Dictionary:
	return queue_action(actor_id, "guard", actor_id, "guard")


func use_item(actor_id: String, item_id: String, target_id: String) -> Dictionary:
	return queue_action(actor_id, item_id, target_id, "item")


func clear_queue() -> void:
	queue.clear()
	_emit("queue_cleared", {"message": "Action queue cleared"})


func begin_execution() -> Dictionary:
	if not turn_manager.is_player_input_allowed():
		return {"ok": false, "reason": "not_player_phase"}
	if state.result != null:
		return {"ok": false, "reason": "battle_finished"}
	if queue.size() == 0:
		_emit("execution_started", {"message": "No player actions queued", "scheduled": 0})
		turn_manager.begin_enemy_phase()
		state.phase = turn_manager.phase
		_begin_enemy_phase()
		return {"ok": true, "scheduled": schedule.size(), "skipped_player": true}

	last_player_actions = []
	var valid_actions: Array[BattleAction] = []
	for action: BattleAction in queue.actions:
		var definition: Dictionary = _source_definition(action.source_type, action.ability_id)
		var actor: CombatantState = state.find_combatant(action.actor_id)
		if actor == null or not actor.is_alive():
			_cancel_action(action, "actor_down")
			continue
		var gate: Dictionary = status_manager.can_act(actor, str(definition.get("kind", "")))
		if not bool(gate.get("ok", false)):
			_cancel_action(action, str(gate.get("reason", "action_blocked")))
			continue
		if action.source_type == "ability":
			var mp_cost: int = int(definition.get("mp_cost", 0))
			var uses_limit: int = maxi(int(definition.get("uses_per_battle", 0)), 0)
			var reserved_uses: int = 0
			if uses_limit > 0:
				reserved_uses = int(ability_uses.get(action.ability_id, 0)) + 1
				if reserved_uses > uses_limit:
					_cancel_action(action, "ability_exhausted")
					continue
				ability_uses[action.ability_id] = reserved_uses
			if actor.mp < mp_cost:
				if uses_limit > 0:
					ability_uses[action.ability_id] = reserved_uses - 1
				_cancel_action(action, "insufficient_mp")
				continue
			if bool(definition.get("is_limit_burst", false)):
				var lb: Dictionary = limit_manager.consume(actor)
				if not bool(lb.get("ok", false)):
					if uses_limit > 0:
						ability_uses[action.ability_id] = reserved_uses - 1
					_cancel_action(action, str(lb.get("reason", "lb_not_ready")))
					continue
				_emit("limit_burst", lb)
			if mp_cost > 0 and not actor.spend_mp(mp_cost):
				if uses_limit > 0:
					ability_uses[action.ability_id] = reserved_uses - 1
				_cancel_action(action, "insufficient_mp")
				continue
			_emit_animation(actor.id, "skill" if mp_cost > 0 or bool(definition.get("is_limit_burst", false)) else "attack")
		elif action.source_type == "item":
			var used_item: int = int(item_uses.get(action.ability_id, 0)) + 1
			var item_limit: int = maxi(int(definition.get("uses_per_battle", 1)), 1)
			if used_item > item_limit:
				_cancel_action(action, "item_exhausted")
				continue
			item_uses[action.ability_id] = used_item
		_emit("action_started", {
			"message": "%s uses %s" % [actor.display_name, action.label],
			"action": action.to_dict()
		})
		valid_actions.append(action)
		last_player_actions.append(action.to_dict())

	queue.clear()
	var staged := ActionQueue.new()
	for action: BattleAction in valid_actions:
		staged.add(action)
	schedule = staged.build_schedule(state, ability_defs, item_defs, clock.frame, status_manager)
	schedule.sort_custom(_sort_schedule)
	schedule_index = 0
	state.phase = "player_execution"
	turn_manager.phase = "player_execution"
	_emit("execution_started", {"message": "Executing %d timed effects" % schedule.size(), "scheduled": schedule.size()})
	return {"ok": true, "scheduled": schedule.size()}


func advance_frames(count: int) -> Array[Dictionary]:
	var emitted: Array[Dictionary] = []
	if clock.frame >= 999999:
		return emitted
	clock.advance_frames(maxi(count, 0))
	while schedule_index < schedule.size() and schedule[schedule_index].frame <= clock.frame:
		var entry: ScheduledHit = schedule[schedule_index]
		schedule_index += 1
		if state.result != null:
			continue
		var results: Array[Dictionary] = effect_resolver.apply(state, entry.action, entry, rng)
		for result: Dictionary in results:
			var event := BattleEvent.new(entry.frame, str(result.get("type", "event")), result.get("data", {}))
			_emit_event(event)
			emitted.append(event.to_dict())
			if str(result.get("type", "")) == "damage":
				var data: Dictionary = result.get("data", {})
				_emit_animation(str(data.get("target_id", "")), "damage")
			if state.result == null:
				_check_outcome()
			if state.result != null:
				break
		if state.result != null:
			schedule_index = schedule.size()
			break
	if schedule_index >= schedule.size() and state.result == null:
		_after_execution()
	return emitted


func execute_turn(max_frames: int = 600) -> Dictionary:
	var started: Dictionary = begin_execution()
	if not bool(started.get("ok", false)):
		return started
	var iterations: int = 0
	while state.result == null and iterations < max_frames:
		advance_frames(1)
		iterations += 1
		if state.phase == "player" and schedule_index >= schedule.size():
			break
	return {
		"ok": true,
		"frames": iterations,
		"phase": state.phase,
		"chain": chain_manager.snapshot(),
		"state": state.snapshot()
	}


func get_ability_def(ability_id: String) -> Dictionary:
	var value: Variant = ability_defs.get(ability_id, {})
	return value.duplicate(true) if value is Dictionary else {}


func get_item_def(item_id: String) -> Dictionary:
	var value: Variant = item_defs.get(item_id, {})
	return value.duplicate(true) if value is Dictionary else {}


func summary() -> Dictionary:
	return {
		"queue_size": queue.size(),
		"schedule_size": schedule.size(),
		"schedule_index": schedule_index,
		"frame": clock.frame,
		"rng_state": rng.snapshot(),
		"phase": state.phase,
		"turn": state.turn,
		"run_id": state.run_id,
		"seed_source": state.seed_source,
		"chain": chain_manager.snapshot(),
		"event_count": state.events.size()
	}


func _after_execution() -> void:
	if state.phase == "player_execution":
		chain_manager.reset()
		state.chain_count = 0
		state.chain_modifier = 0
		_begin_enemy_phase()
		return

	if state.phase == "enemy_execution":
		for combatant: CombatantState in _all_combatants():
			for event: Dictionary in status_manager.tick(combatant):
				_emit(str(event.get("type", "status_tick")), event)
			if not combatant.is_alive():
				_emit("defeat_combatant", {"message": "%s is defeated" % combatant.display_name, "target_id": combatant.id})
		_check_outcome()
		if state.result != null:
			return
		for combatant: CombatantState in _all_combatants():
			combatant.reset_turn_flags()
		limit_manager.reset_turn()
		chain_manager.reset()
		state.chain_count = 0
		state.chain_modifier = 0
		turn_manager.end_turn()
		state.turn = turn_manager.turn
		state.phase = turn_manager.phase
		_emit("turn_started", {"message": "Turn %d — player phase" % state.turn, "turn": state.turn})


func _begin_enemy_phase() -> void:
	turn_manager.begin_enemy_phase()
	state.phase = turn_manager.phase
	_emit("phase_changed", {"message": "Enemy phase", "phase": state.phase})
	var staged := ActionQueue.new()
	var enemy_actions: Array[BattleAction] = []
	for enemy: CombatantState in state.enemies:
		if not enemy.is_alive():
			continue
		var actions: Array[BattleAction] = enemy_ai.decide_actions(enemy, state, rng, clock.frame)
		for action: BattleAction in actions:
			var definition: Dictionary = ability_defs.get(action.ability_id, {})
			var mp_cost: int = int(definition.get("mp_cost", 0))
			if enemy.mp < mp_cost:
				continue
			if mp_cost > 0 and not enemy.spend_mp(mp_cost):
				continue
			action.label = str(definition.get("name", action.ability_id))
			enemy_actions.append(action)
			staged.add(action)
			_emit_animation(enemy.id, "skill" if int(definition.get("mp_cost", 0)) > 0 else "attack")

	for action: BattleAction in enemy_actions:
		var target_names: Array[String] = []
		for target_id: String in action.target_ids:
			var target: CombatantState = state.find_combatant(target_id)
			if target != null:
				target_names.append(target.display_name)
		_emit("action_started", {
			"message": "%s uses %s" % [state.find_combatant(action.actor_id).display_name, action.label],
			"action": action.to_dict(),
			"targets": target_names
		})

	schedule = staged.build_schedule(state, ability_defs, item_defs, clock.frame, status_manager)
	schedule.sort_custom(_sort_schedule)
	schedule_index = 0
	_emit("execution_started", {"message": "Enemy actions scheduled", "scheduled": schedule.size()})


func _check_outcome() -> void:
	if state.result != null:
		return
	if state.alive_enemies().is_empty():
		finish(true)
	elif state.alive_party().is_empty():
		finish(false)


func finish(victory: bool) -> void:
	if state.result != null:
		return
	var defeated: Array[String] = []
	for enemy: CombatantState in state.enemies:
		if not enemy.is_alive():
			defeated.append(enemy.id)
	var result := BattleResult.new()
	result.encounter_id = state.encounter_id
	result.encounter_name = state.encounter_name
	result.victory = victory
	result.outcome = "victory" if victory else "defeat"
	result.turns = state.turn
	result.seed = state.seed
	result.seed_source = state.seed_source
	result.run_id = state.run_id
	result.boss = state.boss
	var policy_variant: Variant = encounter_def.get("reward_policy", {})
	result.reward_policy = policy_variant.duplicate(true) if policy_variant is Dictionary else {}
	result.rewards = reward_resolver.resolve(encounter_def, victory, state.turn, state.run_id)
	result.defeated_enemies = defeated
	state.result = result
	turn_manager.finish(result.outcome)
	state.phase = result.outcome
	_emit("battle_end", {
		"message": "Battle %s" % result.outcome,
		"outcome": result.outcome,
		"result": result.to_dict()
	})
	_emit_animation("", "victory" if victory else "defeat")


func _source_definition(source_type: String, action_id: String) -> Dictionary:
	if source_type == "item":
		return get_item_def(action_id)
	if source_type == "guard":
		return {}
	return get_ability_def(action_id)


func _action_label(action: BattleAction) -> String:
	if not action.label.is_empty():
		return action.label
	if action.source_type == "guard":
		return "Guard"
	if action.source_type == "item":
		return str(get_item_def(action.ability_id).get("name", action.ability_id))
	return str(get_ability_def(action.ability_id).get("name", action.ability_id))


func _all_combatants() -> Array[CombatantState]:
	var result: Array[CombatantState] = []
	result.append_array(state.party)
	result.append_array(state.enemies)
	return result


func _sort_schedule(left: ScheduledHit, right: ScheduledHit) -> bool:
	if left.frame != right.frame:
		return left.frame < right.frame
	if left.actor_order != right.actor_order:
		return left.actor_order < right.actor_order
	if left.hit_index != right.hit_index:
		return left.hit_index < right.hit_index
	return left.effect_index < right.effect_index


func _cancel_action(action: BattleAction, reason: String) -> void:
	_emit("action_cancelled", {
		"message": "%s cancelled: %s" % [action.label if not action.label.is_empty() else action.ability_id, reason],
		"actor_id": action.actor_id,
		"ability_id": action.ability_id,
		"reason": reason,
		"action": action.to_dict()
	})


func _invalid(reason: String) -> Dictionary:
	return {"ok": false, "action": null, "reason": reason}


func _emit(event_type: String, data: Dictionary) -> void:
	_emit_event(BattleEvent.new(clock.frame, event_type, data))


func _emit_event(event: BattleEvent) -> void:
	state.add_event(event.to_dict())
	event_emitted.emit(event.to_dict())


func _emit_animation(actor_id: String, clip: String) -> void:
	_emit("animation", {"actor_id": actor_id, "clip": clip, "message": "Animation: %s" % clip})
