class_name LimitBurstManager
extends RefCounted

## Deterministic LB gauge rules. Evidence: automatic fill is capped at 12 crysts per turn.
## Explicit ability/item gauge effects are authored fixture values, not reconstructed FFBE data.

const AUTO_FILL_CAP := 12

var auto_fill_used: Dictionary = {}


func reset_turn() -> void:
	auto_fill_used.clear()


func can_use(actor: CombatantState) -> bool:
	return actor != null and actor.lb_ready()


func consume(actor: CombatantState) -> Dictionary:
	if not can_use(actor):
		return {"ok": false, "reason": "lb_not_ready", "message": "%s LB gauge is not full" % (actor.display_name if actor != null else "unknown")}
	actor.lb_gauge = 0
	return {"ok": true, "reason": "", "message": "%s unleashes a Limit Burst" % actor.display_name}


func on_action_start(actor: CombatantState) -> Dictionary:
	return _auto_fill(actor, 1, "action")


func on_damage_taken(target: CombatantState) -> Dictionary:
	return _auto_fill(target, 1, "damage_taken")


func fill(target: CombatantState, amount: int, reason: String = "explicit") -> Dictionary:
	if target == null or not target.is_alive():
		return {"ok": false, "reason": "target_unavailable", "message": "No living LB target"}
	var gained: int = target.add_lb(amount)
	return {
		"ok": gained > 0,
		"reason": "" if gained > 0 else "lb_full",
		"message": "%s gains %d LB (%d/%d)" % [target.display_name, gained, target.lb_gauge, target.lb_cost],
		"gained": gained
	}


func _auto_fill(target: CombatantState, amount: int, reason: String) -> Dictionary:
	if target == null or not target.is_alive():
		return {"ok": false, "reason": "target_unavailable", "message": "No living LB target"}
	var used: int = int(auto_fill_used.get(target.id, 0))
	if used >= AUTO_FILL_CAP:
		return {"ok": false, "reason": "auto_fill_cap", "message": "%s reached the auto LB cap" % target.display_name, "gained": 0}
	var granted: int = mini(amount, AUTO_FILL_CAP - used)
	auto_fill_used[target.id] = used + granted
	return fill(target, granted, reason)
