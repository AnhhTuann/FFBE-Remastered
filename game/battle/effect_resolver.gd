class_name EffectResolver
extends RefCounted

## Applies one scheduled effect in explicit order. Unknown effects produce an
## explicit unsupported event and never mutate state silently.

var damage_calculator: DamageCalculator
var status_manager: StatusEffectManager
var limit_manager: LimitBurstManager
var chain_manager: ChainManager


func _init(
	p_damage_calculator: DamageCalculator,
	p_status_manager: StatusEffectManager,
	p_limit_manager: LimitBurstManager,
	p_chain_manager: ChainManager
) -> void:
	damage_calculator = p_damage_calculator
	status_manager = p_status_manager
	limit_manager = p_limit_manager
	chain_manager = p_chain_manager


func apply(
	state: BattleState,
	action: BattleAction,
	scheduled: ScheduledHit,
	rng: BattleRNG
) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var effect: Dictionary = scheduled.effect
	var effect_type: String = str(effect.get("type", ""))
	var actor: CombatantState = state.find_combatant(action.actor_id)
	var legality: Dictionary = _actor_legality(actor, scheduled)
	if not bool(legality.get("ok", false)):
		return [_cancelled(str(legality.get("reason", "actor_unavailable")), actor)]

	match effect_type:
		"damage":
			events.append_array(_apply_damage(state, actor, action, scheduled, rng))
		"heal":
			events.append_array(_apply_heal(state, actor, action, effect, rng))
		"buff", "break", "imperil", "status":
			for target: CombatantState in _effect_targets(state, action, effect):
				var result: Dictionary = status_manager.apply(target, effect, actor.id, rng)
				events.append(_as_event(result.get("type", effect_type), result))
		"lb_fill":
			for target: CombatantState in _effect_targets(state, action, effect):
				var result: Dictionary = limit_manager.fill(target, int(effect.get("amount", 0)), "ability")
				events.append(_as_event("lb_fill", result))
		"mp_restore":
			for target: CombatantState in _effect_targets(state, action, effect):
				var restored: int = target.restore_mp(int(effect.get("amount", 0)))
				events.append(_event("mp_restore", "%s restores %d MP" % [target.display_name, restored]))
		"guard":
			actor.guard = true
			events.append(_event("guard", "%s guards" % actor.display_name))
		_:
			events.append(_unsupported(
				"unsupported_effect",
				"Effect '%s' is not implemented; no state was changed" % effect_type
			))
	return events


func _apply_damage(
	state: BattleState,
	actor: CombatantState,
	action: BattleAction,
	scheduled: ScheduledHit,
	rng: BattleRNG
) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var effect: Dictionary = scheduled.effect
	var ability: Dictionary = {
		"kind": str(effect.get("kind", "")),
		"modifier": float(effect.get("modifier", 1.0)),
		"ignore_def": float(effect.get("ignore_def", 0))
	}
	var elements: Array[String] = []
	var hit_element: String = str(scheduled.hit.get("element", ""))
	if not hit_element.is_empty():
		elements.append(hit_element)

	var chain: Dictionary = chain_manager.register_hit(
		actor.id, scheduled.frame, elements, str(effect.get("chain_family", ""))
	)
	state.chain_count = int(chain.get("count", 0))
	state.chain_modifier = int(chain.get("modifier", 0))
	var chain_message: String = "%s chain x%d (%d%%)" % [
		str(chain.get("kind", "none")), state.chain_count, state.chain_modifier
	]
	events.append(_event("chain", chain_message, {
		"chain": chain.duplicate(true),
		"actor_id": actor.id,
		"frame": scheduled.frame
	}))

	for target: CombatantState in _effect_targets(state, action, effect):
		var result: Dictionary = damage_calculator.calculate(
			actor, target, ability, scheduled.hit, float(chain.get("bonus", 1.0)), rng
		)
		if not bool(result.get("ok", false)):
			events.append(_as_event("unsupported_effect", result))
			continue
		var amount: int = int(result.get("amount", 0))
		var applied: int = target.take_damage(amount)
		var lb_result: Dictionary = limit_manager.on_damage_taken(target)
		events.append(_event("damage", "%s hits %s for %d" % [actor.display_name, target.display_name, applied], {
			"actor_id": actor.id,
			"target_id": target.id,
			"amount": applied,
			"breakdown": result.get("breakdown", {}),
			"chain": chain.duplicate(true),
			"hit_index": scheduled.hit_index,
			"lb": lb_result
		}))
		if not target.is_alive():
			events.append(_event("defeat_combatant", "%s is defeated" % target.display_name, {
				"target_id": target.id
			}))
	return events


func _apply_heal(
	state: BattleState,
	actor: CombatantState,
	action: BattleAction,
	effect: Dictionary,
	rng: BattleRNG
) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var variance: float = float(rng.range_int(85, 100)) / 100.0
	for target: CombatantState in _effect_targets(state, action, effect):
		var spr: int = target.effective_stat("spr")
		var mag: int = target.effective_stat("mag")
		var modifier: float = float(effect.get("modifier", 0.0))
		var amount: int = int(floor(
			(float(int(effect.get("base", 0))) + (float(spr) / 2.0 + float(mag) / 10.0) * modifier)
			* variance
		))
		var applied: int = target.restore_hp(amount)
		events.append(_event("heal", "%s heals %s for %d" % [actor.display_name, target.display_name, applied], {
			"actor_id": actor.id,
			"target_id": target.id,
			"amount": applied,
			"variance": variance
		}))
	return events


func _effect_targets(state: BattleState, action: BattleAction, effect: Dictionary) -> Array[CombatantState]:
	var actor: CombatantState = state.find_combatant(action.actor_id)
	var result: Array[CombatantState] = []
	if actor == null:
		return result
	var targeting: String = str(effect.get("targeting", action.targeting))
	match targeting:
		"self":
			result.append(actor)
		"all_allies":
			result = state.alive_party() if actor.side == "party" else state.alive_enemies()
		"all_enemies":
			result = state.alive_enemies() if actor.side == "party" else state.alive_party()
		"ally", "enemy":
			for target_id: String in action.target_ids:
				var target: CombatantState = state.find_combatant(target_id)
				if target == null or not target.is_alive():
					continue
				if targeting == "ally" and target.side != actor.side:
					continue
				if targeting == "enemy" and target.side == actor.side:
					continue
				result.append(target)
		_:
			return result
	return result


func _event(event_type: String, message: String, data: Dictionary = {}) -> Dictionary:
	var payload: Dictionary = data.duplicate(true)
	payload["message"] = message
	return {"type": event_type, "data": payload}


func _as_event(event_type: String, result: Dictionary) -> Dictionary:
	return _event(event_type, str(result.get("message", "")), result)


func _unsupported(reason: String, message: String) -> Dictionary:
	return _event("unsupported_effect", message, {"reason": reason})


## The schedule is built before hits resolve, but a faster earlier hit can down
## or disable a later actor. Re-check immediately before every effect so a
## cancelled command never changes state.
func _actor_legality(actor: CombatantState, scheduled: ScheduledHit) -> Dictionary:
	if actor == null:
		return {"ok": false, "reason": "actor_unavailable"}
	if not actor.is_alive():
		return {"ok": false, "reason": "actor_down"}
	if status_manager == null:
		return {"ok": true, "reason": ""}
	var kind: String = str(scheduled.effect.get("kind", ""))
	var gate: Dictionary = status_manager.can_act(actor, kind)
	if not bool(gate.get("ok", false)):
		return {"ok": false, "reason": str(gate.get("reason", "action_blocked"))}
	return {"ok": true, "reason": ""}


func _cancelled(reason: String, actor: CombatantState) -> Dictionary:
	var name: String = actor.display_name if actor != null else "unknown"
	return _event("action_cancelled", "%s cannot act: %s" % [name, reason], {
		"reason": reason,
		"actor_id": actor.id if actor != null else ""
	})
