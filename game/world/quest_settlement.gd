class_name QuestSettlement
extends RefCounted

## Pure quest staging used by gameplay transactions. It mutates a caller-owned
## state dictionary without committing, so treasure, battle and quest actions
## can settle rewards, flags and objectives in one atomic write.

const EVENT_TYPES: Array[String] = [
	"talk_to", "visit_location", "defeat_encounter", "open_treasure", "collect", "complete_quest"
]


static func stage_event(state: Dictionary, event: Dictionary, repository: QuestRepository) -> Dictionary:
	var event_type: String = str(event.get("type", ""))
	var target: String = str(event.get("target", ""))
	var count: int = maxi(1, int(event.get("count", 1)))
	if not EVENT_TYPES.has(event_type) or target.is_empty():
		return {"ok": false, "reason": "invalid_event", "message": "quest.invalid_event"}
	var world_variant: Variant = state.get("world", null)
	if not world_variant is Dictionary:
		return {"ok": false, "reason": "invalid_state", "message": "quest.invalid_state"}
	var world: Dictionary = world_variant
	var quests_variant: Variant = world.get("quests", {})
	var quests: Dictionary = quests_variant if quests_variant is Dictionary else {}
	var touched: Array[String] = []
	var completed: Array[String] = []
	for quest_id: String in repository.get_quest_ids():
		var record_variant: Variant = quests.get(quest_id, {})
		var record: Dictionary = record_variant if record_variant is Dictionary else {}
		if str(record.get("status", "not_started")) != "active":
			continue
		var progress_variant: Variant = record.get("progress", {})
		var current_progress: Dictionary = progress_variant if progress_variant is Dictionary else {}
		var changed: bool = false
		for objective: Dictionary in repository.get_objectives(quest_id):
			if str(objective.get("type", "")) != event_type or str(objective.get("target", "")) != target:
				continue
			var objective_id: String = str(objective.get("id", ""))
			var required: int = maxi(1, int(objective.get("count", 1)))
			var next_value: int = mini(required, int(current_progress.get(objective_id, 0)) + count)
			if next_value == int(current_progress.get(objective_id, 0)):
				continue
			current_progress[objective_id] = next_value
			changed = true
		if not changed:
			continue
		touched.append(quest_id)
		if _all_objectives_met(quest_id, current_progress, repository):
			var completion: Dictionary = _stage_completion(
				state, world, quests, quest_id, current_progress, repository
			)
			if not bool(completion.get("ok", false)):
				return completion
			completed.append(quest_id)
		else:
			_stage_quest(quests, quest_id, "active", current_progress)
	world["quests"] = quests
	state["world"] = world
	return {
		"ok": true, "reason": "", "touched": touched,
		"completed": completed, "event": event.duplicate(true)
	}


static func _all_objectives_met(quest_id: String, progress_map: Dictionary, repository: QuestRepository) -> bool:
	for objective: Dictionary in repository.get_objectives(quest_id):
		var objective_id: String = str(objective.get("id", ""))
		if int(progress_map.get(objective_id, 0)) < maxi(1, int(objective.get("count", 1))):
			return false
	return true


static func _stage_quest(quests: Dictionary, quest_id: String, quest_status: String, progress_map: Dictionary) -> void:
	quests[quest_id] = {
		"status": quest_status,
		"progress": progress_map.duplicate(true),
		"completed": quest_status == "completed"
	}


static func _stage_completion(
	state: Dictionary,
	world: Dictionary,
	quests: Dictionary,
	quest_id: String,
	progress_map: Dictionary,
	repository: QuestRepository
) -> Dictionary:
	var quest: Dictionary = repository.get_quest(quest_id)
	var reward_variant: Variant = quest.get("rewards", {})
	var reward: Dictionary = reward_variant if reward_variant is Dictionary else {}
	var key: String = "world|quest|%s" % quest_id
	var claims_variant: Variant = state.get("reward_claims", {})
	var claims: Dictionary = claims_variant if claims_variant is Dictionary else {}
	if claims.has(key):
		_stage_quest(quests, quest_id, "completed", progress_map)
		return {"ok": true, "reason": "", "quest_id": quest_id, "claim": {"key": key, "already_claimed": true}}
	var grant: Dictionary = {}
	grant["gil"] = maxi(int(reward.get("gil", 0)), 0)
	var items_variant: Variant = reward.get("items", [])
	if items_variant is Array:
		for item_variant: Variant in items_variant:
			var item_id: String = str(item_variant)
			if not item_id.is_empty():
				grant[item_id] = int(grant.get(item_id, 0)) + 1
	var resources_variant: Variant = state.get("resources", {})
	var resources: Dictionary = resources_variant if resources_variant is Dictionary else {}
	for resource_key: String in grant.keys():
		var amount: int = maxi(int(grant[resource_key]), 0)
		if amount <= 0:
			continue
		resources[resource_key] = maxi(int(resources.get(resource_key, 0)), 0) + amount
	state["resources"] = resources
	claims[key] = {
		"key": key, "kind": "quest", "identity": quest_id,
		"rewards": grant.duplicate(true), "canonical": true
	}
	state["reward_claims"] = claims
	var legacy_variant: Variant = state.get("claimed_rewards", {})
	var legacy: Dictionary = legacy_variant if legacy_variant is Dictionary else {}
	legacy[key] = {"kind": "quest", "identity": quest_id, "rewards": grant.duplicate(true)}
	state["claimed_rewards"] = legacy
	_stage_quest(quests, quest_id, "completed", progress_map)
	var unlocks_variant: Variant = quest.get("unlocks", [])
	if unlocks_variant is Array:
		var unlocked_variant: Variant = world.get("unlocked_locations", [])
		var discovered_variant: Variant = world.get("discovered_locations", [])
		var unlocked: Array = unlocked_variant if unlocked_variant is Array else []
		var discovered: Array = discovered_variant if discovered_variant is Array else []
		for location_variant: Variant in unlocks_variant:
			var location_id: String = str(location_variant)
			if not unlocked.has(location_id):
				unlocked.append(location_id)
			if not discovered.has(location_id):
				discovered.append(location_id)
		unlocked.sort()
		discovered.sort()
		world["unlocked_locations"] = unlocked
		world["discovered_locations"] = discovered
	return {
		"ok": true, "reason": "", "quest_id": quest_id,
		"claim": {"key": key, "rewards": grant.duplicate(true)}
	}
