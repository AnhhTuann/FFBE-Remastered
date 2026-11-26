class_name ActionQueue
extends RefCounted

## Validated action list expanded into deterministic, clock-scheduled effect entries.
## A queued action reserves the resources it will spend, so several commands from
## one actor cannot overdraw MP and several actors cannot exceed a shared item
## limit. Reservations are released when the queue is cleared at execution time.

var actions: Array[BattleAction] = []
var mp_reserved: Dictionary = {}
var item_reserved: Dictionary = {}
var ability_queued: Dictionary = {}
var lb_reserved: Dictionary = {}


## With no context the action is treated as already validated (used for the
## immutable execution-stage queue). With a context, legality is rechecked and
## the action's MP/item/LB cost is reserved immediately.
func add(action: BattleAction, context: Dictionary = {}) -> bool:
	if action == null:
		return false
	if not context.is_empty() and not _reserve(action, context):
		return false
	actions.append(action)
	return true


func clear() -> void:
	actions.clear()
	mp_reserved.clear()
	item_reserved.clear()
	ability_queued.clear()
	lb_reserved.clear()


func size() -> int:
	return actions.size()


func reserved_mp(actor_id: String) -> int:
	return maxi(int(mp_reserved.get(actor_id, 0)), 0)


func queued_item_uses(item_id: String) -> int:
	return maxi(int(item_reserved.get(item_id, 0)), 0)


func queued_ability_uses(ability_id: String) -> int:
	return maxi(int(ability_queued.get(ability_id, 0)), 0)


func has_lb_reservation(actor_id: String) -> bool:
	return lb_reserved.has(actor_id)


func _reserve(action: BattleAction, context: Dictionary) -> bool:
	var state: BattleState = context.get("state") as BattleState
	var ability_defs: Dictionary = context.get("ability_defs", {})
	var item_defs: Dictionary = context.get("item_defs", {})
	var status_manager: StatusEffectManager = context.get("status_manager") as StatusEffectManager
	var limit_manager: LimitBurstManager = context.get("limit_manager") as LimitBurstManager
	var item_uses: Dictionary = context.get("item_uses", {})
	var ability_uses: Dictionary = context.get("ability_uses", {})
	if state == null or status_manager == null:
		return false
	var actor: CombatantState = state.find_combatant(action.actor_id)
	if actor == null or not actor.is_alive():
		return false
	var definition: Dictionary = {}
	if action.source_type == "item":
		definition = item_defs.get(action.ability_id, {})
	elif action.source_type == "ability":
		definition = ability_defs.get(action.ability_id, {})
	if not definition.is_empty():
		var gate: Dictionary = status_manager.can_act(actor, str(definition.get("kind", "")))
		if not bool(gate.get("ok", false)):
			return false

	if action.source_type == "ability":
		var mp_cost: int = maxi(int(definition.get("mp_cost", 0)), 0)
		if reserved_mp(actor.id) + mp_cost > actor.mp:
			return false
		var uses_limit: int = maxi(int(definition.get("uses_per_battle", 0)), 0)
		if uses_limit > 0 and int(ability_uses.get(action.ability_id, 0)) + queued_ability_uses(action.ability_id) + 1 > uses_limit:
			return false
		if bool(definition.get("is_limit_burst", false)):
			if lb_reserved.has(actor.id) or limit_manager == null or not limit_manager.can_use(actor):
				return false
			lb_reserved[actor.id] = true
		if mp_cost > 0:
			mp_reserved[actor.id] = reserved_mp(actor.id) + mp_cost
		ability_queued[action.ability_id] = queued_ability_uses(action.ability_id) + 1
	elif action.source_type == "item":
		var item_limit: int = maxi(int(definition.get("uses_per_battle", 1)), 1)
		if int(item_uses.get(action.ability_id, 0)) + queued_item_uses(action.ability_id) + 1 > item_limit:
			return false
		item_reserved[action.ability_id] = queued_item_uses(action.ability_id) + 1
	return true


func to_array() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for action: BattleAction in actions:
		data.append(action.to_dict())
	return data


func build_schedule(
	state: BattleState,
	ability_defs: Dictionary,
	item_defs: Dictionary,
	start_frame: int,
	status_manager: StatusEffectManager = null
) -> Array[ScheduledHit]:
	var schedule: Array[ScheduledHit] = []
	for action: BattleAction in actions:
		var actor: CombatantState = state.find_combatant(action.actor_id)
		if actor == null or not actor.is_alive():
			continue
		if status_manager != null:
			var queued_definition: Dictionary = _definition_for(action, ability_defs, item_defs)
			var gate: Dictionary = status_manager.can_act(actor, str(queued_definition.get("kind", "")))
			if not bool(gate.get("ok", false)):
				continue
		var validation: Dictionary = TargetResolver.resolve(action, state)
		if not bool(validation.get("ok", false)):
			continue
		var resolved_targets: Array[String] = []
		for target_id_variant: Variant in validation.get("targets", []):
			resolved_targets.append(str(target_id_variant))
		action.target_ids = resolved_targets

		var definition: Dictionary = _definition_for(action, ability_defs, item_defs)
		var actor_order: int = _actor_order(state, action.actor_id)
		var hits_variant: Variant = definition.get("hits", [])
		if hits_variant is Array:
			for hit_index: int in range((hits_variant as Array).size()):
				var hit_variant: Variant = hits_variant[hit_index]
				if not hit_variant is Dictionary:
					continue
				var hit: Dictionary = hit_variant
				var effect: Dictionary = {
					"type": "damage",
					"kind": str(definition.get("kind", "")),
					"targeting": str(definition.get("targeting", action.targeting)),
					"modifier": float(definition.get("modifier", 1.0)),
					"chain_family": str(definition.get("chain_family", ""))
				}
				var entry := ScheduledHit.new()
				entry.action = action
				entry.effect_index = -1
				entry.hit_index = hit_index
				entry.frame = start_frame + int(hit.get("frame", 0))
				entry.effect = effect
				entry.hit = hit.duplicate(true)
				entry.actor_order = actor_order
				schedule.append(entry)

		var effects_variant: Variant = definition.get("effects", [])
		if effects_variant is Array:
			for effect_index: int in range((effects_variant as Array).size()):
				var effect_variant: Variant = effects_variant[effect_index]
				if not effect_variant is Dictionary:
					continue
				var entry := ScheduledHit.new()
				entry.action = action
				entry.effect_index = effect_index
				entry.hit_index = -1
				entry.frame = start_frame + int((effect_variant as Dictionary).get("frame", 0))
				entry.effect = (effect_variant as Dictionary).duplicate(true)
				entry.hit = {}
				entry.actor_order = actor_order
				schedule.append(entry)

		if action.source_type == "guard":
			var guard_entry := ScheduledHit.new()
			guard_entry.action = action
			guard_entry.effect_index = 0
			guard_entry.frame = start_frame
			guard_entry.effect = {"type": "guard", "targeting": "self", "frame": 0}
			guard_entry.actor_order = actor_order
			schedule.append(guard_entry)

	schedule.sort_custom(_sort_entries)
	return schedule


func _definition_for(action: BattleAction, ability_defs: Dictionary, item_defs: Dictionary) -> Dictionary:
	if action.source_type == "item":
		var item_variant: Variant = item_defs.get(action.ability_id, {})
		return item_variant if item_variant is Dictionary else {}
	var ability_variant: Variant = ability_defs.get(action.ability_id, {})
	return ability_variant if ability_variant is Dictionary else {}


func _actor_order(state: BattleState, actor_id: String) -> int:
	for index: int in range(state.party.size()):
		if state.party[index].id == actor_id:
			return index + 1
	for index: int in range(state.enemies.size()):
		if state.enemies[index].id == actor_id:
			return index + 101
	return 999


func _sort_entries(left: ScheduledHit, right: ScheduledHit) -> bool:
	if left.frame != right.frame:
		return left.frame < right.frame
	if left.actor_order != right.actor_order:
		return left.actor_order < right.actor_order
	if left.hit_index != right.hit_index:
		return left.hit_index < right.hit_index
	return left.effect_index < right.effect_index
