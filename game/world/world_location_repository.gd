class_name WorldLocationRepository
extends RefCounted

## Read-only view over synthetic world definitions. All mutable discovery and
## unlock state belongs to PlayerState; this class only answers gate questions.

var _repository: Node


func _init(repository: Node = null) -> void:
	if repository != null:
		_repository = repository
		return
	var loop: Variant = Engine.get_main_loop()
	if loop is SceneTree:
		_repository = (loop as SceneTree).root.get_node_or_null("ContentRepository")


func get_region(id: String) -> Dictionary:
	return _repository.call("get_world_region", id) as Dictionary


func get_location(id: String) -> Dictionary:
	return _repository.call("get_world_location", id) as Dictionary


func get_locations() -> Dictionary:
	return _repository.call("get_world_locations") as Dictionary


func get_connections() -> Dictionary:
	return _repository.call("get_world_connections") as Dictionary


func get_interactables() -> Dictionary:
	var value: Variant = _repository.call("get_world_interactables")
	return value if value is Dictionary else {}


func get_interactable(id: String) -> Dictionary:
	var value: Variant = _repository.call("get_world_interactable", id)
	return value if value is Dictionary else {}


func get_start_location(region_id: String) -> String:
	var region: Dictionary = get_region(region_id)
	return str(region.get("start_location", ""))


func location_exists(id: String) -> bool:
	return not get_location(id).is_empty()


## Unknown, malformed or cross-region IDs are rejected before any scene load.
func validate_reference(id: String, expected_kind: String = "location") -> bool:
	if id.is_empty():
		return false
	var entry: Dictionary = {}
	match expected_kind:
		"location":
			entry = get_location(id)
		"region":
			entry = get_region(id)
		"quest":
			entry = _repository.call("get_world_quest", id) as Dictionary
		"npc":
			entry = _repository.call("get_world_interactable", id) as Dictionary
		"treasure":
			entry = _repository.call("get_world_interactable", id) as Dictionary
		"encounter":
			return (str(id).begins_with("encounter:GL:") or str(id).begins_with("encounter:JP:")) and not (
				_repository.call("get_encounter", id) as Dictionary
			).is_empty()
		_:
			return false
	return not entry.is_empty() and str(entry.get("kind", "")) == expected_kind


func get_locations_for_region(region_id: String) -> Array[String]:
	var result: Array[String] = []
	for id: String in get_locations().keys():
		var location: Dictionary = get_location(id)
		if str(location.get("region_id", "")) == region_id:
			result.append(id)
	result.sort()
	return result


func connections_for(id: String) -> Array[String]:
	var result: Array[String] = []
	for connection_id: String in get_connections().keys():
		var connection: Dictionary = _repository.call("get_world_connection", connection_id) as Dictionary
		var from_id: String = str(connection.get("from", ""))
		var to_id: String = str(connection.get("to", ""))
		if from_id == id:
			result.append(to_id)
		elif to_id == id:
			result.append(from_id)
	result.sort()
	return result


## `is_connected` is a built-in Object method, so graph lookup uses this name.
func has_connection(from_id: String, to_id: String) -> bool:
	return connections_for(from_id).has(to_id)


func connection_requirement(from_id: String, to_id: String) -> Dictionary:
	for connection_id: String in get_connections().keys():
		var connection: Dictionary = _repository.call("get_world_connection", connection_id) as Dictionary
		var from_id_value: String = str(connection.get("from", ""))
		var to_id_value: String = str(connection.get("to", ""))
		if (from_id_value == from_id and to_id_value == to_id) or (
			to_id_value == from_id and from_id_value == to_id
		):
			var requirement: Variant = connection.get("requirement", {})
			return requirement if requirement is Dictionary else {}
	return {}


func meets_requirements(id: String, world_state: Dictionary, quest_states: Dictionary = {}) -> bool:
	var location: Dictionary = get_location(id)
	if location.is_empty():
		return false
	if bool(location.get("initial_unlocked", false)):
		return true
	var unlocked_variant: Variant = world_state.get("unlocked_locations", [])
	if unlocked_variant is Array and (unlocked_variant as Array).has(id):
		return true
	var requirements_variant: Variant = location.get("unlock_requirements", {})
	if not requirements_variant is Dictionary:
		return false
	var requirements: Dictionary = requirements_variant
	var flags_variant: Variant = requirements.get("flags", [])
	if flags_variant is Array:
		var flags: Dictionary = world_state.get("flags", {})
		for flag: Variant in flags_variant:
			if not bool(flags.get(str(flag), false)):
				return false
	var quests_variant: Variant = requirements.get("quests", [])
	if quests_variant is Array:
		for quest_id: Variant in quests_variant:
			var quest: Dictionary = quest_states.get(str(quest_id), {})
			if str(quest.get("status", "")) != "completed":
				return false
	return true


func can_travel(from_id: String, to_id: String, world_state: Dictionary, quest_states: Dictionary = {}) -> bool:
	if not location_exists(from_id) or not location_exists(to_id):
		return false
	if not meets_requirements(to_id, world_state, quest_states):
		return false
	var requirement: Dictionary = connection_requirement(from_id, to_id)
	var required_location: String = str(requirement.get("location_id", ""))
	if required_location.is_empty():
		return true
	var unlocked_variant: Variant = world_state.get("unlocked_locations", [])
	return unlocked_variant is Array and (unlocked_variant as Array).has(required_location)
