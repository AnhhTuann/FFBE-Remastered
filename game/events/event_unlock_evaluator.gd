class_name EventUnlockEvaluator
extends RefCounted

## Prompt 07.1 prerequisite evaluator. Availability stays in EventSchedule;
## this class only answers whether an event's authored unlock is satisfied.
## All branches fail closed on malformed or cross-region references.

var _state: Node = null
var _repository: EventRepository = null


func _init(state_node: Node, repository: EventRepository) -> void:
	_state = state_node
	_repository = repository


func is_event_unlocked(event_id: String, region: String) -> bool:
	return bool(status(event_id, region).get("ok", false))


func status(event_id: String, region: String) -> Dictionary:
	var event: Dictionary = _repository.get_event(event_id) if _repository != null else {}
	if event.is_empty():
		return _fail("invalid_event", "event.invalid_context")
	var regions_variant: Variant = event.get("regions", {})
	if not regions_variant is Dictionary or not (regions_variant as Dictionary).has(region):
		return _fail("region_mismatch", "event.invalid_context")
	var unlock: Dictionary = _repository.event_unlock(event_id)
	if unlock.is_empty():
		return _fail("unknown_unlock", "event.center.locked")
	var kind: String = str(unlock.get("kind", ""))
	var reference: String = str(unlock.get("id", ""))
	if kind == EventRepository.UNLOCK_NONE:
		if not reference.is_empty():
			return _fail("invalid_prerequisite", "event.center.locked")
		return _ok()
	if reference.is_empty():
		return _fail("invalid_prerequisite", "event.center.locked")
	if kind == EventRepository.UNLOCK_EVENT:
		return _verdict(_event_prerequisite(reference, region))
	if kind == EventRepository.UNLOCK_STAGE:
		return _verdict(_stage_prerequisite(reference, region))
	if kind == EventRepository.UNLOCK_QUEST:
		return _verdict(_quest_prerequisite(reference, region))
	return _fail("unknown_unlock", "event.center.locked")


func _verdict(satisfied: bool) -> Dictionary:
	return _ok() if satisfied else _fail("prerequisite_unmet", "event.center.locked")


func _event_prerequisite(event_id: String, region: String) -> bool:
	var prerequisite: Dictionary = _repository.get_event(event_id)
	if prerequisite.is_empty():
		return false
	var regions_variant: Variant = prerequisite.get("regions", {})
	if not regions_variant is Dictionary or not (regions_variant as Dictionary).has(region):
		return false
	var stage_ids_variant: Variant = prerequisite.get("stage_ids", [])
	if not stage_ids_variant is Array or (stage_ids_variant as Array).is_empty():
		return false
	var completions: Dictionary = _map("completions")
	for stage_id_variant: Variant in (stage_ids_variant as Array):
		var stage_id: String = str(stage_id_variant)
		var stage: Dictionary = _repository.get_event_stage(stage_id)
		if stage.is_empty() or str(stage.get("region", "")) != region:
			return false
		if not completions.has("%s|%s" % [event_id, stage_id]):
			return false
	return true


func _stage_prerequisite(stage_id: String, region: String) -> bool:
	var stage: Dictionary = _repository.get_event_stage(stage_id)
	if stage.is_empty() or str(stage.get("region", "")) != region:
		return false
	var owner_id: String = str(stage.get("event_id", ""))
	var owner: Dictionary = _repository.get_event(owner_id)
	if owner.is_empty():
		return false
	var regions_variant: Variant = owner.get("regions", {})
	if not regions_variant is Dictionary or not (regions_variant as Dictionary).has(region):
		return false
	var key: String = "%s|%s" % [owner_id, stage_id]
	return _map("completions").has(key) or _map("first_clears").has(key)


func _quest_prerequisite(quest_id: String, region: String) -> bool:
	if not quest_id.begins_with("quest:%s:" % region):
		return false
	if not _repository.has_world_quest(quest_id):
		return false
	if _state == null:
		return false
	var world_variant: Variant = _state.data.get("world", {})
	if not world_variant is Dictionary:
		return false
	var quests_variant: Variant = (world_variant as Dictionary).get("quests", {})
	if not quests_variant is Dictionary:
		return false
	var entry_variant: Variant = (quests_variant as Dictionary).get(quest_id, {})
	if not entry_variant is Dictionary:
		return false
	var entry: Dictionary = entry_variant
	return bool(entry.get("completed", false)) or str(entry.get("status", "")) == "completed"


func _map(key: String) -> Dictionary:
	if _state == null:
		return {}
	var events_variant: Variant = _state.data.get("events", {})
	if not events_variant is Dictionary:
		return {}
	var value: Variant = (events_variant as Dictionary).get(key, {})
	return value if value is Dictionary else {}


func _ok() -> Dictionary:
	return {"ok": true, "reason": "", "message": ""}


func _fail(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}
