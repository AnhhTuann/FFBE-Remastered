class_name InteractionController
extends RefCounted

## Gameplay-only interaction resolution for exploration areas. Presentation is
## owned by ExplorationArea; this controller has no scene nodes and is directly
## testable headlessly.

signal interaction_resolved(result: Dictionary)

const INTERACTION_RANGE := 78.0

var locations: WorldLocationRepository
var world_state: WorldStateService
var quests: QuestManager
var _state_node: Node
var _area_id: String = ""
var _interactables: Array[Dictionary] = []


func _init(
	state_node: Node = null,
	location_repository: WorldLocationRepository = null,
	state_service: WorldStateService = null,
	quest_manager: QuestManager = null
) -> void:
	if state_node != null:
		_state_node = state_node
	var loop: Variant = Engine.get_main_loop()
	if loop is SceneTree:
		var tree: SceneTree = loop
		if _state_node == null:
			_state_node = tree.root.get_node_or_null("PlayerState")
		if location_repository == null:
			location_repository = WorldLocationRepository.new()
		if state_service == null:
			state_service = WorldStateService.new()
		if quest_manager == null:
			quest_manager = tree.root.get_node_or_null("QuestManager")
	locations = location_repository
	world_state = state_service
	quests = quest_manager


func configure_area(area_id: String) -> bool:
	if not locations.location_exists(area_id):
		_area_id = ""
		_interactables.clear()
		return false
	_area_id = area_id
	_interactables.clear()
	var all: Dictionary = locations.get_interactables()
	for id: String in all.keys():
		var entry: Dictionary = all[id]
		if str(entry.get("area_id", "")) == area_id:
			_interactables.append(entry)
	return true


func interactables() -> Array[Dictionary]:
	return _interactables.duplicate(true)


func nearest(player_position: Vector2, max_range: float = INTERACTION_RANGE) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = max_range + 1.0
	for entry: Dictionary in _interactables:
		if not can_interact(entry):
			continue
		var position_variant: Variant = entry.get("position", {})
		if not position_variant is Dictionary:
			continue
		var point: Dictionary = position_variant
		var target := Vector2(float(point.get("x", 0)), float(point.get("y", 0)))
		var distance: float = player_position.distance_to(target)
		if distance <= max_range and distance < best_distance:
			best_distance = distance
			best = {
				"id": str(entry.get("id", "")),
				"definition": entry.duplicate(true),
				"distance": distance
			}
	return best


func can_interact(entry: Dictionary) -> bool:
	var id: String = str(entry.get("id", ""))
	if id.is_empty():
		return false
	var requirement_variant: Variant = entry.get("requirement", null)
	if requirement_variant is Dictionary:
		var required_location: String = str((requirement_variant as Dictionary).get("location_id", ""))
		if not required_location.is_empty() and not world_state.is_unlocked(required_location):
			return false
	match str(entry.get("kind", "")):
		"treasure":
			return str(entry.get("interaction_policy", "")) != "one_time" or not world_state.was_treasure_opened(id)
		"encounter_trigger":
			if str(entry.get("interaction_policy", "")) == "one_time":
				var encounter_id: String = str(entry.get("encounter_id", ""))
				if world_state.was_one_time_encounter_defeated(encounter_id):
					return false
				var state_variant: Variant = _state_node.get("data")
				var claims: Dictionary = (state_variant as Dictionary).get("reward_claims", {}) if state_variant is Dictionary else {}
				return not claims.has("battle|once|%s" % encounter_id)
			return true
		"exit":
			var destination: String = str(entry.get("destination", ""))
			return destination == "world_map" or locations.location_exists(destination)
		"npc":
			return not str(entry.get("dialogue_id", "")).is_empty()
		_:
			return false


func interact(player_position: Vector2) -> Dictionary:
	var candidate: Dictionary = nearest(player_position)
	var blocked: Dictionary = {}
	if candidate.is_empty():
		for entry: Dictionary in _interactables:
			var position_variant: Variant = entry.get("position", {})
			if not position_variant is Dictionary:
				continue
			var point: Dictionary = position_variant
			var target := Vector2(float(point.get("x", 0)), float(point.get("y", 0)))
			if player_position.distance_to(target) <= INTERACTION_RANGE:
				blocked = entry
				break
	var result: Dictionary
	if not blocked.is_empty() and candidate.is_empty():
		result = {
			"ok": false, "reason": "interaction_unavailable",
			"id": str(blocked.get("id", "")),
			"prompt_key": str(blocked.get("prompt_key", ""))
		}
	elif candidate.is_empty():
		result = {"ok": false, "reason": "out_of_range"}
	else:
		result = _resolve(candidate["definition"] as Dictionary)
	interaction_resolved.emit(result)
	return result


func resolve_by_id(id: String) -> Dictionary:
	for entry: Dictionary in _interactables:
		if str(entry.get("id", "")) == id:
			var result: Dictionary = _resolve(entry)
			interaction_resolved.emit(result)
			return result
	return {"ok": false, "reason": "invalid_interactable"}


func _resolve(entry: Dictionary) -> Dictionary:
	var id: String = str(entry.get("id", ""))
	match str(entry.get("kind", "")):
		"npc":
			return {
				"ok": true, "action": "dialogue", "id": id,
				"dialogue_id": str(entry.get("dialogue_id", ""))
			}
		"treasure":
			return _open_treasure(id, entry)
		"encounter_trigger":
			world_state.record_interaction(id, "battle_launched")
			return {
				"ok": true, "action": "battle", "id": id,
				"encounter_id": str(entry.get("encounter_id", "")),
				"return_scene": WorldContext.EXPLORATION_PATH,
				"location_id": _area_id
			}
		"exit":
			var destination: String = str(entry.get("destination", ""))
			if destination == "world_map":
				return {
					"ok": true, "action": "world_map", "id": id,
					"return_scene": WorldContext.WORLD_MAP_PATH
				}
			return {
				"ok": true, "action": "travel", "id": id,
				"location_id": destination,
				"return_scene": WorldContext.EXPLORATION_PATH
			}
		_:
			return {"ok": false, "reason": "invalid_interactable"}


func _open_treasure(id: String, entry: Dictionary) -> Dictionary:
	var reward_variant: Variant = entry.get("reward", {})
	var reward: Dictionary = reward_variant if reward_variant is Dictionary else {}
	var event: Dictionary = {"type": "open_treasure", "target": id, "count": 1}
	# Treasure, reward claim and quest event share one staged mutation and one
	# commit; a failed write restores the whole action.
	var callback: Callable = func() -> Dictionary:
		var staged: Dictionary = _stage_treasure(id)
		if not bool(staged.get("ok", false)):
			return staged
		if quests != null:
			var state_variant: Variant = _state_node.get("data")
			var quest_stage: Dictionary = QuestSettlement.stage_event(
				state_variant, event, quests.repository
			)
			if not bool(quest_stage.get("ok", false)):
				return quest_stage
		return staged
	var claim: Variant = _state_node.call("claim_world_reward", "treasure", id, reward, callback)
	if not (claim is Dictionary and bool((claim as Dictionary).get("ok", false))):
		return {"ok": false, "reason": str((claim as Dictionary).get("reason", "reward_failed")), "id": id}
	if quests != null:
		for quest_id: String in quests.repository.get_quest_ids():
			quests.quest_changed.emit(quest_id)
	return {
		"ok": true, "action": "treasure", "id": id,
		"reward": (claim as Dictionary).get("rewards", {}),
		"claim_key": str((claim as Dictionary).get("key", ""))
	}


func _stage_treasure(id: String) -> Dictionary:
	var data_variant: Variant = _state_node.get("data")
	if not data_variant is Dictionary:
		return {"ok": false, "reason": "invalid_state"}
	var data: Dictionary = data_variant
	var world_variant: Variant = data.get("world", {})
	if not world_variant is Dictionary:
		return {"ok": false, "reason": "invalid_state"}
	var world: Dictionary = world_variant
	var opened_variant: Variant = world.get("opened_treasures", [])
	var opened: Array = opened_variant if opened_variant is Array else []
	if opened.has(id):
		return {"ok": false, "reason": "already_opened"}
	opened.append(id)
	opened.sort()
	world["opened_treasures"] = opened
	var interactions_variant: Variant = world.get("interactions", {})
	var interactions: Dictionary = interactions_variant if interactions_variant is Dictionary else {}
	interactions[id] = {
		"count": int((interactions.get(id, {}) as Dictionary).get("count", 0)) + 1,
		"last_outcome": "opened"
	}
	world["interactions"] = interactions
	data["world"] = world
	return {"ok": true, "reason": ""}


func on_battle_result(context: Dictionary, result: Dictionary) -> Dictionary:
	var victory: bool = bool(result.get("victory", false))
	if not victory:
		# Defeat settles nothing; Retry remains available.
		return {"ok": true, "progressed": false, "reason": "defeat"}
	var run_id: String = str(result.get("run_id", ""))
	var processed_variant: Variant = world_state.state().get("processed_battle_runs", {})
	var processed: Dictionary = processed_variant if processed_variant is Dictionary else {}
	if not run_id.is_empty() and processed.has(run_id):
		# Canonical settlement already committed during the battle. Return is a
		# presentation step only and cannot grant or count anything twice.
		return {"ok": true, "progressed": true, "reason": "victory", "settled": true}
	var settlement: Variant = _state_node.call("settle_world_battle", result, context)
	if not (settlement is Dictionary and bool((settlement as Dictionary).get("ok", false))):
		return {
			"ok": false, "progressed": false,
			"reason": str((settlement as Dictionary).get("reason", "save_failed"))
		}
	return {"ok": true, "progressed": true, "reason": "victory", "settled": true}
