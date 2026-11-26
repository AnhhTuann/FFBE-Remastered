class_name DialogueManager
extends Node

## Dialogue runtime: conditional pages, choices and persistent consequences.
## All speaker text is a localization key; this class never stores original FFBE
## story text.

signal dialogue_opened(dialogue_id: String)
signal dialogue_page_changed(page: Dictionary)
signal dialogue_closed(dialogue_id: String)

var repository: DialogueRepository
var world_state: WorldStateService
var quests: QuestManager
var active_id: String = ""
var active_node: String = ""
var active_lines: Array[Dictionary] = []
var page_index: int = 0
var active_choices: Array[Dictionary] = []


func _ready() -> void:
	if repository == null:
		repository = DialogueRepository.new()
	if world_state == null:
		world_state = WorldStateService.new()
	if quests == null:
		var loop: Variant = Engine.get_main_loop()
		if loop is SceneTree:
			quests = (loop as SceneTree).root.get_node_or_null("QuestManager")
		if quests == null:
			quests = QuestManager.new()
			add_child(quests)


func configure(
	dialogue_repository: DialogueRepository,
	state_service: WorldStateService,
	quest_manager: QuestManager
) -> void:
	repository = dialogue_repository
	world_state = state_service
	quests = quest_manager


func is_active() -> bool:
	return not active_id.is_empty()


func start(dialogue_id: String) -> Dictionary:
	var dialogue: Dictionary = repository.get_dialogue(dialogue_id)
	if dialogue.is_empty():
		return {"ok": false, "reason": "invalid_dialogue"}
	active_id = dialogue_id
	active_node = str(dialogue.get("start_node", ""))
	page_index = 0
	_enter_node(active_node)
	dialogue_opened.emit(dialogue_id)
	return current()


func current() -> Dictionary:
	if not is_active():
		return {"ok": false, "reason": "inactive"}
	var dialogue: Dictionary = repository.get_dialogue(active_id)
	var has_pages: bool = page_index < active_lines.size()
	var choices: Array[Dictionary] = []
	if not has_pages:
		for choice: Dictionary in active_choices:
			if _condition_met(choice.get("when", null)):
				choices.append(choice)
	return {
		"ok": true,
		"dialogue_id": active_id,
		"node_id": active_node,
		"speaker_key": str(dialogue.get("speaker_key", "")),
		"portrait_ref": str(dialogue.get("portrait_ref", "")),
		"line_key": str(active_lines[page_index].get("key", "")) if has_pages else "",
		"page": page_index + 1,
		"page_count": active_lines.size(),
		"awaiting_choice": not has_pages and not choices.is_empty(),
		"choices": choices.duplicate(true),
		"finished": not has_pages and choices.is_empty()
	}


func advance() -> Dictionary:
	var page: Dictionary = current()
	if not bool(page.get("ok", false)):
		return page
	if bool(page.get("awaiting_choice", false)):
		return {"ok": false, "reason": "choice_required"}
	if page_index + 1 < active_lines.size():
		page_index += 1
		dialogue_page_changed.emit(current())
		return current()
	# Exhausted pages expose their choices before following a linear `next`.
	# Move the cursor past the last line so current() stops reporting a page.
	page_index = active_lines.size()
	var choice_page: Dictionary = current()
	if not (choice_page.get("choices", []) as Array).is_empty():
		dialogue_page_changed.emit(choice_page)
		return choice_page
	var node: Dictionary = repository.get_node(active_id, active_node)
	var next_id: String = str(node.get("next", ""))
	if next_id.is_empty():
		return close()
	_enter_node(next_id)
	return current()


func choose(choice_id: String) -> Dictionary:
	var page: Dictionary = current()
	if not bool(page.get("ok", false)) or not bool(page.get("awaiting_choice", false)):
		return {"ok": false, "reason": "no_choice"}
	for choice: Dictionary in (page.get("choices", []) as Array):
		if str(choice.get("id", "")) != choice_id:
			continue
		if not _condition_met(choice.get("when", null)):
			return {"ok": false, "reason": "condition_unmet"}
		var applied: Dictionary = _apply_effects(choice.get("effects", []))
		if not bool(applied.get("ok", false)):
			return applied
		world_state.record_dialogue_choice(active_id, choice_id)
		var next_id: String = str(choice.get("next", ""))
		if next_id.is_empty():
			return close()
		_enter_node(next_id)
		return current()
	return {"ok": false, "reason": "invalid_choice"}


func close() -> Dictionary:
	var closed_id: String = active_id
	active_id = ""
	active_node = ""
	active_lines.clear()
	active_choices.clear()
	page_index = 0
	dialogue_closed.emit(closed_id)
	return {"ok": true, "reason": "", "closed": true}


func _enter_node(node_id: String) -> void:
	var node: Dictionary = repository.get_node(active_id, node_id)
	active_node = node_id
	active_lines.clear()
	active_choices.clear()
	for line_variant: Variant in node.get("lines", []):
		if not _condition_met(_line_condition(line_variant)):
			continue
		if line_variant is Dictionary:
			active_lines.append(line_variant)
		elif line_variant is String:
			active_lines.append({"key": str(line_variant)})
	for choice_variant: Variant in node.get("choices", []):
		if choice_variant is Dictionary:
			active_choices.append(choice_variant)
	page_index = 0
	if active_lines.is_empty():
		dialogue_page_changed.emit(current())


func _line_condition(line_variant: Variant) -> Variant:
	if line_variant is Dictionary:
		return (line_variant as Dictionary).get("when", null)
	return null


func _condition_met(value: Variant) -> bool:
	if value == null:
		return true
	if not value is Dictionary:
		return false
	var condition: Dictionary = value
	var condition_type: String = str(condition.get("type", "quest_status"))
	match condition_type:
		"flag":
			return world_state.get_flag(str(condition.get("key", ""))) == bool(condition.get("value", true))
		"quest_status":
			var quest_id: String = str(condition.get("quest_id", ""))
			var expected: String = str(condition.get("status", condition.get("quest_status", "")))
			return quests.status(quest_id) == expected
		_:
			return false


func _apply_effects(effects: Variant) -> Dictionary:
	if not effects is Array:
		return {"ok": true, "reason": ""}
	for effect_variant: Variant in effects:
		if not effect_variant is Dictionary:
			return {"ok": false, "reason": "invalid_effect"}
		var effect: Dictionary = effect_variant
		match str(effect.get("type", "")):
			"flag":
				if not world_state.set_flag(str(effect.get("key", "")), bool(effect.get("value", true))):
					return {"ok": false, "reason": "save_failed"}
			"quest_accept":
				var accepted: Dictionary = quests.accept(str(effect.get("quest_id", "")))
				if not bool(accepted.get("ok", false)) and str(accepted.get("reason", "")) != "already_started":
					return accepted
			"unlock_location":
				if not world_state.unlock_location(str(effect.get("location_id", ""))):
					return {"ok": false, "reason": "save_failed"}
			"quest_event":
				var event_variant: Variant = effect.get("event", {})
				if not event_variant is Dictionary:
					return {"ok": false, "reason": "invalid_event"}
				var recorded: Dictionary = quests.record_event(event_variant)
				if not bool(recorded.get("ok", false)):
					return recorded
			_:
				return {"ok": false, "reason": "invalid_effect"}
	return {"ok": true, "reason": ""}
