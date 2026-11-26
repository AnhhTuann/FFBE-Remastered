class_name DialogueRepository
extends RefCounted

## Read-only view over synthetic dialogue graphs.

var _repository: Node


func _init(repository: Node = null) -> void:
	if repository != null:
		_repository = repository
		return
	var loop: Variant = Engine.get_main_loop()
	if loop is SceneTree:
		_repository = (loop as SceneTree).root.get_node_or_null("ContentRepository")


func get_dialogue(id: String) -> Dictionary:
	var value: Variant = _repository.call("get_world_dialogue", id)
	return value if value is Dictionary else {}


func get_dialogues() -> Dictionary:
	var value: Variant = _repository.call("get_world_dialogues")
	return value if value is Dictionary else {}


func get_node(dialogue_id: String, node_id: String) -> Dictionary:
	var dialogue: Dictionary = get_dialogue(dialogue_id)
	for node_variant: Variant in dialogue.get("nodes", []):
		if node_variant is Dictionary and str((node_variant as Dictionary).get("id", "")) == node_id:
			return node_variant
	return {}


func start_node(dialogue_id: String) -> String:
	return str(get_dialogue(dialogue_id).get("start_node", ""))
