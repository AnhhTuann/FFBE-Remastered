class_name RewardResolver
extends RefCounted

## Victory-only, deterministic reward snapshot. All values are project-authored
## synthetic fixtures. Repeatable, first-clear and mission rewards are kept in
## separate buckets so settlement can apply independent idempotency keys.

func resolve(encounter_definition: Dictionary, victory: bool, turns: int = 0, run_id: String = "") -> Dictionary:
	if not victory:
		return {
			"gil": 0, "items": [], "victory": false, "repeatable": false,
			"repeat": {"gil": 0, "items": []}, "first_clear": {"gil": 0, "items": []},
			"missions": [], "claim_keys": {}, "policy": {}
		}

	# Current fixtures place every settlement rule under `reward_policy`. The
	# top-level fallback keeps older authored encounters readable.
	var policy_variant: Variant = encounter_definition.get("reward_policy", {})
	var policy: Dictionary = policy_variant if policy_variant is Dictionary else {}
	if policy.is_empty():
		policy = encounter_definition.duplicate(true)
	var repeatable: bool = bool(policy.get("repeatable", true))
	var repeat: Dictionary = _bundle(encounter_definition.get("reward", {}))
	if not repeatable:
		repeat = {"gil": 0, "items": []}

	var first_clear: Dictionary = {"gil": 0, "items": []}
	if bool(policy.get("first_clear", false)):
		var first_reward_variant: Variant = policy.get("first_clear_reward", encounter_definition.get("first_clear_reward", {}))
		first_clear = _bundle(first_reward_variant)

	var encounter_id: String = str(encounter_definition.get("id", ""))
	var mission_variants: Variant = policy.get("mission_rewards", encounter_definition.get("mission_rewards", []))
	var missions: Array[Dictionary] = []
	var claim_keys: Dictionary = {}
	if repeatable:
		claim_keys["repeat"] = "battle|run|%s" % (run_id if not run_id.is_empty() else "unknown")
	else:
		claim_keys["repeat"] = "battle|once|%s" % encounter_id
	if bool(policy.get("first_clear", false)):
		claim_keys["first_clear"] = "battle|first|%s" % encounter_id

	if mission_variants is Array:
		for mission_variant: Variant in mission_variants:
			if not mission_variant is Dictionary:
				continue
			var mission: Dictionary = mission_variant
			var mission_id: String = str(mission.get("id", ""))
			if mission_id.is_empty() or not _condition_met(mission.get("condition", {}), turns):
				continue
			var entry: Dictionary = {
				"id": mission_id,
				"condition": (mission.get("condition", {}) as Dictionary).duplicate(true),
				"reward": _bundle(mission.get("reward", {})),
				"repeatable": bool(mission.get("repeatable", false))
			}
			var key: String = "battle|mission|%s|%s" % [encounter_id, mission_id]
			if bool(entry["repeatable"]) and not run_id.is_empty():
				key = "%s|%s" % [key, run_id]
			entry["key"] = key
			claim_keys["mission:%s" % mission_id] = key
			missions.append(entry)

	return {
		"gil": maxi(int(repeat.get("gil", 0)), 0),
		"items": (repeat.get("items", []) as Array).duplicate(),
		"victory": true,
		"repeatable": repeatable,
		"repeat": repeat,
		"first_clear": first_clear,
		"missions": missions,
		"claim_keys": claim_keys,
		"policy": policy.duplicate(true)
	}


func _bundle(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {"gil": 0, "items": []}
	var reward: Dictionary = value
	var items: Array[String] = []
	for item_variant: Variant in reward.get("items", []):
		var item_id: String = str(item_variant)
		if not item_id.is_empty():
			items.append(item_id)
	return {"gil": maxi(int(reward.get("gil", 0)), 0), "items": items}


func _condition_met(value: Variant, turns: int) -> bool:
	if not value is Dictionary:
		return false
	var condition: Dictionary = value
	var kind: String = str(condition.get("type", ""))
	var threshold: int = int(condition.get("value", 0))
	match kind:
		"turns_lte":
			return turns > 0 and turns <= threshold
		"turns_gte":
			return turns >= threshold
		"no_condition":
			return true
		_:
			return false
