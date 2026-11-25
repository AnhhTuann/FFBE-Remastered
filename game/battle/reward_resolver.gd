class_name RewardResolver
extends RefCounted

## Victory-only, deterministic reward snapshot. Rewards are synthetic IDs and gil values.

func resolve(encounter_definition: Dictionary, victory: bool) -> Dictionary:
	if not victory:
		return {"gil": 0, "items": [], "victory": false}
	var reward_variant: Variant = encounter_definition.get("reward", {})
	if not reward_variant is Dictionary:
		return {"gil": 0, "items": [], "victory": true}
	var reward: Dictionary = reward_variant
	var items: Array[String] = []
	var items_variant: Variant = reward.get("items", [])
	if items_variant is Array:
		for item_variant: Variant in items_variant:
			items.append(str(item_variant))
	return {
		"gil": maxi(int(reward.get("gil", 0)), 0),
		"items": items,
		"victory": true
	}
