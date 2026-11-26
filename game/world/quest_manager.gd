class_name QuestManager
extends Node

## Data-driven quest lifecycle. Progress and completion live in PlayerState's
## additive world section; rewards are settled once through PlayerState's
## claim-keyed transactional API.

signal quest_changed(quest_id: String)

const EVENT_TYPES: Array[String] = [
	"talk_to", "visit_location", "defeat_encounter", "open_treasure", "collect", "complete_quest"
]

var repository: QuestRepository
var world_state: WorldStateService
var _state_node: Node


func _ready() -> void:
	if repository == null:
		repository = QuestRepository.new()
	if world_state == null:
		world_state = WorldStateService.new()
	var loop: Variant = Engine.get_main_loop()
	if loop is SceneTree:
		_state_node = (loop as SceneTree).root.get_node_or_null("PlayerState")


func configure(state_node: Node, quest_repository: QuestRepository, state_service: WorldStateService) -> void:
	_state_node = state_node
	repository = quest_repository
	world_state = state_service


func status(quest_id: String) -> String:
	return str(world_state.get_quest_state(quest_id).get("status", "not_started"))


func is_completed(quest_id: String) -> bool:
	return status(quest_id) == "completed"


func progress(quest_id: String) -> Dictionary:
	var entry: Dictionary = world_state.get_quest_state(quest_id)
	var progress_variant: Variant = entry.get("progress", {})
	return progress_variant if progress_variant is Dictionary else {}


func meets_prerequisites(quest_id: String) -> bool:
	var prerequisites: Dictionary = repository.get_prerequisites(quest_id)
	var flags_variant: Variant = prerequisites.get("flags", [])
	if flags_variant is Array:
		for flag: Variant in flags_variant:
			if not world_state.get_flag(str(flag)):
				return false
	var quests_variant: Variant = prerequisites.get("quests", [])
	if quests_variant is Array:
		for prerequisite: Variant in quests_variant:
			if not is_completed(str(prerequisite)):
				return false
	return true


func accept(quest_id: String) -> Dictionary:
	if repository.get_quest(quest_id).is_empty():
		return _fail("invalid_quest")
	if status(quest_id) != "not_started":
		return _fail("already_started")
	if not meets_prerequisites(quest_id):
		return _fail("prerequisites_unmet")
	var initial: Dictionary = {}
	for objective: Dictionary in repository.get_objectives(quest_id):
		initial[str(objective.get("id", ""))] = _initial_progress(objective)
	var accepted: Dictionary = {
		"ok": true, "reason": "", "quest_id": quest_id,
		"status": "active", "progress": initial
	}
	var result: Variant = _state_node.call("transact_world", "quests", func() -> Dictionary:
		return _stage_quest(quest_id, "active", initial)
	)
	if not (result is Dictionary and bool((result as Dictionary).get("ok", false))):
		return _fail("save_failed")
	quest_changed.emit(quest_id)
	return accepted


func record_event(event: Dictionary) -> Dictionary:
	var event_type: String = str(event.get("type", ""))
	var target: String = str(event.get("target", ""))
	if not EVENT_TYPES.has(event_type) or target.is_empty():
		return _fail("invalid_event")
	# Every objective touched by this event is staged together and committed
	# once. A failed write rolls back all quest progress, rewards and unlocks.
	var result: Variant = _state_node.call("transact_world", "quests", func() -> Dictionary:
		var state_variant: Variant = _state_node.get("data")
		if not state_variant is Dictionary:
			return {"ok": false, "reason": "invalid_state"}
		return QuestSettlement.stage_event(state_variant, event, repository)
	)
	if not (result is Dictionary and bool((result as Dictionary).get("ok", false))):
		return _fail(str((result as Dictionary).get("reason", "save_failed")))
	for quest_id: String in (result as Dictionary).get("touched", []):
		quest_changed.emit(quest_id)
	return result


func journal() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest_id: String in repository.get_quest_ids():
		var quest: Dictionary = repository.get_quest(quest_id)
		result.append({
			"id": quest_id,
			"name_key": str(quest.get("name_key", "")),
			"description_key": str(quest.get("description_key", "")),
			"status": status(quest_id),
			"progress": progress(quest_id),
			"objectives": repository.get_objectives(quest_id)
		})
	return result


func _initial_progress(objective: Dictionary) -> int:
	var objective_type: String = str(objective.get("type", ""))
	var target: String = str(objective.get("target", ""))
	var required: int = maxi(1, int(objective.get("count", 1)))
	match objective_type:
		"collect":
			return mini(required, int(_state_node.call("get_resource", target)))
		"complete_quest":
			return required if is_completed(target) else 0
		"visit_location":
			return required if world_state.is_discovered(target) else 0
		"open_treasure":
			return required if world_state.was_treasure_opened(target) else 0
		"defeat_encounter":
			return required if world_state.was_one_time_encounter_defeated(target) else 0
		"talk_to":
			var interactions_variant: Variant = world_state.state().get("interactions", {})
			var interactions: Dictionary = interactions_variant if interactions_variant is Dictionary else {}
			var record: Dictionary = interactions.get(target, {})
			return required if int(record.get("count", 0)) > 0 else 0
		_:
			return 0


func _all_objectives_met(quest_id: String, progress_map: Dictionary) -> bool:
	for objective: Dictionary in repository.get_objectives(quest_id):
		var objective_id: String = str(objective.get("id", ""))
		if int(progress_map.get(objective_id, 0)) < maxi(1, int(objective.get("count", 1))):
			return false
	return true


func _complete(quest_id: String, progress_map: Dictionary) -> Dictionary:
	var quest: Dictionary = repository.get_quest(quest_id)
	var rewards: Dictionary = {}
	var rewards_variant: Variant = quest.get("rewards", {})
	if rewards_variant is Dictionary:
		rewards = rewards_variant
	var unlocks: Array[String] = []
	var unlocks_variant: Variant = quest.get("unlocks", [])
	if unlocks_variant is Array:
		for location_id: Variant in unlocks_variant:
			unlocks.append(str(location_id))
	var callback: Callable = func() -> Dictionary:
		var staged: Dictionary = _stage_quest(quest_id, "completed", progress_map)
		if not bool(staged.get("ok", false)):
			return staged
		return _stage_unlocks(unlocks)
	var result: Variant = _state_node.call(
		"claim_world_reward", "quest", quest_id, rewards, callback
	)
	if not (result is Dictionary and bool((result as Dictionary).get("ok", false))):
		return _fail(str((result as Dictionary).get("reason", "reward_failed")))
	return {
		"ok": true, "reason": "", "quest_id": quest_id,
		"status": "completed", "claim": (result as Dictionary).duplicate(true)
	}


func _stage_unlocks(unlocks: Array[String]) -> Dictionary:
	var data_variant: Variant = _state_node.get("data")
	if not data_variant is Dictionary:
		return {"ok": false, "reason": "invalid_state"}
	var data: Dictionary = data_variant
	var world_variant: Variant = data.get("world", {})
	if not world_variant is Dictionary:
		return {"ok": false, "reason": "invalid_state"}
	var world: Dictionary = world_variant
	var unlocked_variant: Variant = world.get("unlocked_locations", [])
	var unlocked: Array = unlocked_variant if unlocked_variant is Array else []
	var discovered_variant: Variant = world.get("discovered_locations", [])
	var discovered: Array = discovered_variant if discovered_variant is Array else []
	for location_id: String in unlocks:
		if not unlocked.has(location_id):
			unlocked.append(location_id)
		if not discovered.has(location_id):
			discovered.append(location_id)
	unlocked.sort()
	discovered.sort()
	world["unlocked_locations"] = unlocked
	world["discovered_locations"] = discovered
	data["world"] = world
	return {"ok": true, "reason": ""}


func _stage_quest(quest_id: String, quest_status: String, progress_map: Dictionary) -> Dictionary:
	var data_variant: Variant = _state_node.get("data")
	if not data_variant is Dictionary:
		return {"ok": false, "reason": "invalid_state"}
	var data: Dictionary = data_variant
	var world_variant: Variant = data.get("world", {})
	if not world_variant is Dictionary:
		return {"ok": false, "reason": "invalid_state"}
	var world: Dictionary = world_variant
	var quests_variant: Variant = world.get("quests", {})
	var quests: Dictionary = quests_variant if quests_variant is Dictionary else {}
	quests[quest_id] = {
		"status": quest_status,
		"progress": progress_map.duplicate(true),
		"completed": quest_status == "completed"
	}
	world["quests"] = quests
	data["world"] = world
	return {"ok": true, "reason": ""}


func _fail(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": "quest.%s" % reason}
