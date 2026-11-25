class_name TargetResolver
extends RefCounted

## Validates actor/target legality and expands party-wide commands.

static func resolve(action: BattleAction, state: BattleState) -> Dictionary:
	var actor: CombatantState = state.find_combatant(action.actor_id)
	if actor == null or not actor.is_alive():
		return _failure("actor_missing_or_down")
	var targeting: String = action.targeting
	if targeting.is_empty():
		return _failure("targeting_missing")

	if targeting == "self":
		return _success([actor.id])
	if targeting == "all_allies":
		return _success(_ids(state.alive_party() if actor.side == "party" else state.alive_enemies()))
	if targeting == "all_enemies":
		return _success(_ids(state.alive_enemies() if actor.side == "party" else state.alive_party()))

	var candidates: Array[CombatantState] = state.alive_party() if actor.side == "party" else state.alive_enemies()
	if targeting == "ally":
		candidates = state.alive_party() if actor.side == "party" else state.alive_enemies()
	elif targeting == "enemy":
		candidates = state.alive_enemies() if actor.side == "party" else state.alive_party()
	else:
		return _failure("unsupported_targeting:%s" % targeting)

	if action.target_ids.is_empty():
		return _failure("target_missing")
	var resolved: Array[String] = []
	for target_id: String in action.target_ids:
		var target: CombatantState = state.find_combatant(target_id)
		if target == null or not target.is_alive():
			return _failure("target_missing_or_down:%s" % target_id)
		var legal: bool = false
		for candidate: CombatantState in candidates:
			if candidate.id == target_id:
				legal = true
				break
		if not legal:
			return _failure("wrong_side:%s" % target_id)
		if not resolved.has(target_id):
			resolved.append(target_id)
	return _success(resolved)


static func _ids(combatants: Array[CombatantState]) -> Array[String]:
	var result: Array[String] = []
	for combatant: CombatantState in combatants:
		result.append(combatant.id)
	return result


static func _success(targets: Array[String]) -> Dictionary:
	var result: Array[String] = []
	for target_id: String in targets:
		result.append(target_id)
	return {"ok": true, "targets": result, "reason": ""}


static func _failure(reason: String) -> Dictionary:
	return {"ok": false, "targets": [], "reason": reason}
