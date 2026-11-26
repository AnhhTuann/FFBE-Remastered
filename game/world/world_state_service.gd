class_name WorldStateService
extends RefCounted

## Mutable Prompt 06 world state. Every write is staged through PlayerState and
## committed in one atomic write; a failed commit restores the whole snapshot.

var _state_node: Node


func _init(state_node: Node = null) -> void:
	if state_node != null:
		_state_node = state_node
		return
	var loop: Variant = Engine.get_main_loop()
	if loop is SceneTree:
		_state_node = (loop as SceneTree).root.get_node_or_null("PlayerState")


func state() -> Dictionary:
	var state_variant: Variant = _state_node.call("get_world_state")
	return state_variant if state_variant is Dictionary else {}


func get_string_array(key: String) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in state().get(key, []):
		result.append(str(value))
	return result


func is_discovered(id: String) -> bool:
	return get_string_array("discovered_locations").has(id)


func is_unlocked(id: String) -> bool:
	return get_string_array("unlocked_locations").has(id)


func is_completed(id: String) -> bool:
	return get_string_array("completed_locations").has(id)


func was_one_time_encounter_defeated(id: String) -> bool:
	return get_string_array("defeated_one_time_encounters").has(id)


func was_treasure_opened(id: String) -> bool:
	return get_string_array("opened_treasures").has(id)


func get_flag(key: String) -> bool:
	var flags_variant: Variant = state().get("flags", {})
	return bool((flags_variant as Dictionary).get(key, false)) if flags_variant is Dictionary else false


func get_quest_state(id: String) -> Dictionary:
	var quests_variant: Variant = state().get("quests", {})
	if not quests_variant is Dictionary:
		return {}
	var entry: Variant = (quests_variant as Dictionary).get(id, {})
	return entry.duplicate(true) if entry is Dictionary else {}


func _append_unique(section: Dictionary, key: String, value: String) -> void:
	var values_variant: Variant = section.get(key, [])
	var values: Array = values_variant if values_variant is Array else []
	if not values.has(value):
		values.append(value)
		values.sort()
	section[key] = values


func discover_location(id: String) -> bool:
	return _write(func() -> Dictionary:
		var section_variant: Variant = _state_node.get("data").get("world", {})
		if not section_variant is Dictionary:
			return {"ok": false, "reason": "invalid_state"}
		_append_unique(section_variant as Dictionary, "discovered_locations", id)
		return {"ok": true, "reason": ""}
	)


func unlock_location(id: String) -> bool:
	return _write(func() -> Dictionary:
		var section_variant: Variant = _state_node.get("data").get("world", {})
		if not section_variant is Dictionary:
			return {"ok": false, "reason": "invalid_state"}
		_append_unique(section_variant as Dictionary, "unlocked_locations", id)
		_append_unique(section_variant as Dictionary, "discovered_locations", id)
		return {"ok": true, "reason": ""}
	)


func complete_location(id: String) -> bool:
	return _write(func() -> Dictionary:
		var section_variant: Variant = _state_node.get("data").get("world", {})
		if not section_variant is Dictionary:
			return {"ok": false, "reason": "invalid_state"}
		_append_unique(section_variant as Dictionary, "completed_locations", id)
		return {"ok": true, "reason": ""}
	)


func set_current_location(region_id: String, location_id: String) -> bool:
	return _write(func() -> Dictionary:
		var section_variant: Variant = _state_node.get("data").get("world", {})
		if not section_variant is Dictionary:
			return {"ok": false, "reason": "invalid_state"}
		var section: Dictionary = section_variant
		section["current_region"] = region_id
		section["current_location"] = location_id
		_append_unique(section, "discovered_locations", location_id)
		return {"ok": true, "reason": ""}
	)


func set_flag(key: String, value: bool) -> bool:
	return _write(func() -> Dictionary:
		var section_variant: Variant = _state_node.get("data").get("world", {})
		if not section_variant is Dictionary:
			return {"ok": false, "reason": "invalid_state"}
		var flags_variant: Variant = (section_variant as Dictionary).get("flags", {})
		var flags: Dictionary = flags_variant if flags_variant is Dictionary else {}
		flags[key] = value
		(section_variant as Dictionary)["flags"] = flags
		return {"ok": true, "reason": ""}
	)


func record_dialogue_choice(dialogue_id: String, choice_id: String) -> bool:
	return _write(func() -> Dictionary:
		var section_variant: Variant = _state_node.get("data").get("world", {})
		if not section_variant is Dictionary:
			return {"ok": false, "reason": "invalid_state"}
		var choices_variant: Variant = (section_variant as Dictionary).get("dialogue_choices", {})
		var choices: Dictionary = choices_variant if choices_variant is Dictionary else {}
		choices[dialogue_id] = {"choice_id": choice_id, "count": int((choices.get(dialogue_id, {}) as Dictionary).get("count", 0)) + 1}
		(section_variant as Dictionary)["dialogue_choices"] = choices
		return {"ok": true, "reason": ""}
	)


func record_interaction(id: String, outcome: String) -> bool:
	return _write(func() -> Dictionary:
		var section_variant: Variant = _state_node.get("data").get("world", {})
		if not section_variant is Dictionary:
			return {"ok": false, "reason": "invalid_state"}
		var interactions_variant: Variant = (section_variant as Dictionary).get("interactions", {})
		var interactions: Dictionary = interactions_variant if interactions_variant is Dictionary else {}
		var previous: Dictionary = interactions.get(id, {})
		interactions[id] = {
			"count": int(previous.get("count", 0)) + 1,
			"last_outcome": outcome
		}
		(section_variant as Dictionary)["interactions"] = interactions
		return {"ok": true, "reason": ""}
	)


func mark_one_time_encounter_defeated(encounter_id: String) -> bool:
	return _write(func() -> Dictionary:
		var section_variant: Variant = _state_node.get("data").get("world", {})
		if not section_variant is Dictionary:
			return {"ok": false, "reason": "invalid_state"}
		_append_unique(section_variant as Dictionary, "defeated_one_time_encounters", encounter_id)
		return {"ok": true, "reason": ""}
	)


func remember_battle_result(result: Dictionary) -> bool:
	return _write(func() -> Dictionary:
		var section_variant: Variant = _state_node.get("data").get("world", {})
		if not section_variant is Dictionary:
			return {"ok": false, "reason": "invalid_state"}
		(section_variant as Dictionary)["last_battle_result"] = result.duplicate(true)
		return {"ok": true, "reason": ""}
	)


func _write(mutation: Callable) -> bool:
	var result: Variant = _state_node.call("transact_world", "world", mutation)
	return result is Dictionary and bool((result as Dictionary).get("ok", false))
