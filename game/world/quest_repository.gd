class_name QuestRepository
extends RefCounted

## Read-only access to the synthetic quest graph in game/data/world/quests.json.

var _repository: Node


func _init(repository: Node = null) -> void:
	if repository != null:
		_repository = repository
		return
	var loop: Variant = Engine.get_main_loop()
	if loop is SceneTree:
		_repository = (loop as SceneTree).root.get_node_or_null("ContentRepository")


func get_quest(id: String) -> Dictionary:
	var value: Variant = _repository.call("get_world_quest", id)
	return value if value is Dictionary else {}


func get_quests() -> Dictionary:
	var value: Variant = _repository.call("get_world_quests")
	return value if value is Dictionary else {}


func get_objectives(quest_id: String) -> Array[Dictionary]:
	var quest: Dictionary = get_quest(quest_id)
	var result: Array[Dictionary] = []
	for objective_variant: Variant in quest.get("objectives", []):
		if objective_variant is Dictionary:
			result.append(objective_variant)
	return result


func get_prerequisites(quest_id: String) -> Dictionary:
	var quest: Dictionary = get_quest(quest_id)
	var prerequisites: Variant = quest.get("prerequisites", {})
	return prerequisites if prerequisites is Dictionary else {}


func get_quest_ids() -> Array[String]:
	var result: Array[String] = []
	for id: String in get_quests().keys():
		result.append(id)
	result.sort()
	return result
