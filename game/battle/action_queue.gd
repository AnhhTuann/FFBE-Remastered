class_name ActionQueue
extends RefCounted

## Validated action list expanded into deterministic, clock-scheduled effect entries.

var actions: Array[BattleAction] = []


func add(action: BattleAction) -> bool:
	if action == null:
		return false
	actions.append(action)
	return true


func clear() -> void:
	actions.clear()


func size() -> int:
	return actions.size()


func to_array() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for action: BattleAction in actions:
		data.append(action.to_dict())
	return data


func build_schedule(
	state: BattleState,
	ability_defs: Dictionary,
	item_defs: Dictionary,
	start_frame: int
) -> Array[ScheduledHit]:
	var schedule: Array[ScheduledHit] = []
	for action: BattleAction in actions:
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
