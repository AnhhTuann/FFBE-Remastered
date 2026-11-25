class_name ScheduledHit
extends RefCounted

## One effect or hit placed on the controllable battle clock.

var action: BattleAction = null
var effect_index: int = 0
var hit_index: int = -1
var frame: int = 0
var effect: Dictionary = {}
var hit: Dictionary = {}
var actor_order: int = 0


func is_damage_hit() -> bool:
	return hit_index >= 0


func to_dict() -> Dictionary:
	return {
		"actor_id": action.actor_id if action != null else "",
		"ability_id": action.ability_id if action != null else "",
		"effect_index": effect_index,
		"hit_index": hit_index,
		"frame": frame,
		"actor_order": actor_order,
		"effect": effect.duplicate(true),
		"hit": hit.duplicate(true)
	}
