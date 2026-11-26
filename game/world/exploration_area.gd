extends Control

## Exploration presentation and input shell. Gameplay rules live in
## ExplorationController, InteractionController, QuestManager and
## DialogueManager; this script only maps state to nodes and handles input.

const HUB_LOCATION := "loc:GL:1101@haven"
const MEADOW_LOCATION := "loc:GL:1102@meadow"
const SPIRE_LOCATION := "loc:GL:1103@spire"
const WORLD_MAP_PATH := "res://scenes/world/world_map.tscn"
const BATTLE_PATH := "res://scenes/battle/battle_scene.tscn"
const DESIGN_WIDTH := 1280.0
const DESIGN_HEIGHT := 720.0

@onready var title_label: Label = $TitleLabel
@onready var controls_label: Label = $ControlsLabel
@onready var status_label: Label = $StatusLabel
@onready var prompt_label: Label = $PromptLabel
@onready var player_marker: ColorRect = $PlayerMarker
@onready var marker_layer: Control = $InteractableLayer
@onready var pause_panel: PanelContainer = $PausePanel
@onready var pause_title: Label = $PausePanel/PauseLayout/PauseTitle
@onready var resume_button: Button = $PausePanel/PauseLayout/ResumeButton
@onready var return_button: Button = $PausePanel/PauseLayout/ReturnButton
@onready var dialogue_panel: PanelContainer = $DialoguePanel

var movement: ExplorationController
var interaction: InteractionController
var world: WorldStateService
var quests: QuestManager
var dialogue: DialogueManager
var locations_repo: WorldLocationRepository
var area_id: String = HUB_LOCATION
var status_key: String = ""
var marker_buttons: Dictionary = {}
var _held_keys: Dictionary = {}
var _paused: bool = false
var _repository: Node
var _viewport_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(_on_resized)
	_update_viewport_scale()
	_repository = _get_node("ContentRepository")
	locations_repo = WorldLocationRepository.new(_repository)
	world = WorldStateService.new()
	quests = QuestManager.new()
	add_child(quests)
	quests._ready()
	dialogue = DialogueManager.new()
	add_child(dialogue)
	dialogue.configure(DialogueRepository.new(_repository), world, quests)
	interaction = InteractionController.new(_get_node("PlayerState"), locations_repo, world, quests)
	movement = ExplorationController.new()

	resume_button.pressed.connect(_toggle_pause)
	return_button.pressed.connect(_return_to_map)
	dialogue_panel.next_pressed.connect(_advance_dialogue)
	dialogue_panel.close_pressed.connect(_close_dialogue)
	dialogue_panel.choice_selected.connect(_choose_dialogue)
	LocaleManager.locale_changed.connect(_apply_locale)

	var context: Dictionary = WorldContext.consume()
	var scenario: String = OS.get_environment("FFBE_QA_SCENARIO")
	var requested: String = str(context.get("location_id", ""))
	if requested.is_empty():
		requested = _qa_location(scenario)
	if requested.is_empty() or not locations_repo.location_exists(requested):
		requested = HUB_LOCATION
	area_id = requested
	if scenario.begins_with("meadow") or scenario.begins_with("spire"):
		world.unlock_location(area_id)
	if not context.is_empty() and context.has("battle_result"):
		var result_variant: Variant = context.get("battle_result", {})
		if result_variant is Dictionary:
			var handled: Dictionary = interaction.on_battle_result(context, result_variant)
			status_key = "world.explore.battle_victory" if bool(handled.get("progressed", false)) else "world.explore.battle_defeat"

	var location: Dictionary = locations_repo.get_location(area_id)
	var region_id: String = str(location.get("region_id", ""))
	world.set_current_location(region_id, area_id)
	interaction.configure_area(area_id)
	var start_position: Vector2 = _qa_start_position(scenario)
	var obstacles: Array[Rect2] = _obstacles()
	movement.configure(start_position, Rect2(44, 84, 1192, 596), obstacles)
	pause_panel.visible = false
	_rebuild_markers()
	_apply_locale(LocaleManager.current_locale)
	_refresh_presentation()

	if scenario == "haven_npc":
		_start_dialogue("dialogue:GL:2101@keeper")
	elif scenario == "haven_npc_choice":
		_start_dialogue("dialogue:GL:2101@keeper")
		dialogue.advance()
		dialogue.advance()
		dialogue_panel.show_page(dialogue.current())
		_clear_dialogue_labels()
	elif scenario == "meadow_chest":
		interact_at_player()
	elif scenario == "meadow_battle" or scenario == "spire_boss":
		# Scene changes cannot remove the current scene while its _ready() is
		# still running. QA scenarios therefore launch on the next idle frame.
		call_deferred("_launch_battle", {
			"action": "battle", "id": _trigger_id_for_area(), "encounter_id": ""
		})
	elif scenario == "pause":
		_toggle_pause()


func _get_node(name: String) -> Node:
	var loop: Variant = Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null(NodePath(name))
	return null


## Interaction data is authored in a 1280x720 design space. Presentation is
## mapped onto the actual window so 1024x640 and 1920x1080 keep the same
## reachable area and marker layout without changing gameplay coordinates.
func _update_viewport_scale() -> void:
	var viewport_size := size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = Vector2(DESIGN_WIDTH, DESIGN_HEIGHT)
	_viewport_scale = Vector2(
		maxf(0.1, viewport_size.x / DESIGN_WIDTH),
		maxf(0.1, viewport_size.y / DESIGN_HEIGHT)
	)


func _design_to_screen(point: Vector2) -> Vector2:
	return Vector2(point.x * _viewport_scale.x, point.y * _viewport_scale.y)


func _screen_to_design(point: Vector2) -> Vector2:
	return Vector2(point.x / _viewport_scale.x, point.y / _viewport_scale.y)


func _screen_rect(rect: Rect2) -> Rect2:
	return Rect2(_design_to_screen(rect.position), rect.size * _viewport_scale)


func _on_resized() -> void:
	_update_viewport_scale()
	if movement == null or interaction == null:
		return
	if not marker_buttons.is_empty():
		_rebuild_markers()
	_refresh_presentation()
	queue_redraw()


func t(key: String, args: Dictionary = {}) -> String:
	return LocaleManager.t(key, args)


func _qa_location(scenario: String) -> String:
	if scenario.begins_with("meadow"):
		return MEADOW_LOCATION
	if scenario.begins_with("spire"):
		return SPIRE_LOCATION
	return HUB_LOCATION


func _qa_start_position(scenario: String) -> Vector2:
	if scenario == "haven_npc" or scenario == "haven_npc_choice":
		return Vector2(300, 490)
	if scenario == "meadow_chest":
		return Vector2(530, 490)
	if scenario == "meadow_battle":
		return Vector2(930, 360)
	if scenario == "spire_boss":
		return Vector2(640, 360)
	return Vector2(570, 560)


func _trigger_id_for_area() -> String:
	return "encounter_trigger:GL:5101@meadow" if area_id == MEADOW_LOCATION else "encounter_trigger:GL:5102@spire"


func _obstacles() -> Array[Rect2]:
	match area_id:
		MEADOW_LOCATION:
			return [Rect2(220, 180, 180, 90), Rect2(700, 440, 170, 80)]
		SPIRE_LOCATION:
			return [Rect2(300, 200, 220, 110), Rect2(820, 420, 170, 90)]
		_:
			return [Rect2(180, 180, 220, 100), Rect2(820, 180, 200, 110)]


func _rebuild_markers() -> void:
	for child: Node in marker_layer.get_children():
		child.queue_free()
	marker_buttons.clear()
	for entry: Dictionary in interaction.interactables():
		var id: String = str(entry.get("id", ""))
		var point_variant: Variant = entry.get("position", {})
		if not point_variant is Dictionary:
			continue
		var point: Dictionary = point_variant
		var button := Button.new()
		button.name = "Marker_" + id.replace(":", "_").replace("@", "_")
		button.custom_minimum_size = Vector2(136, 34)
		button.position = _design_to_screen(Vector2(
			float(point.get("x", 0)), float(point.get("y", 0))
		)) - Vector2(68, 17)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(func() -> void: _on_marker_pressed(id))
		marker_layer.add_child(button)
		marker_buttons[id] = button
	_refresh_markers()


func _refresh_markers() -> void:
	for id: String in marker_buttons.keys():
		var button: Button = marker_buttons[id]
		var entry_variant: Variant = _repository.call("get_world_interactable", id)
		if not entry_variant is Dictionary:
			continue
		var entry: Dictionary = entry_variant
		button.disabled = not interaction.can_interact(entry)
		button.text = LocaleManager.t(str(entry.get("name_key", "")))
		button.modulate = Color(0.65, 0.85, 1.0) if not button.disabled else Color(0.45, 0.48, 0.55)


func _on_marker_pressed(id: String) -> void:
	var entry: Dictionary = _repository.call("get_world_interactable", id)
	var point: Dictionary = entry.get("position", {})
	var target := Vector2(float(point.get("x", 570)), float(point.get("y", 500)) - 56)
	movement.set_move_target(target)


func interact_at_player() -> Dictionary:
	var result: Dictionary = interaction.interact(movement.position)
	_handle_interaction(result)
	return result


func _handle_interaction(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		status_key = str(result.get("reason", "world.explore.out_of_range"))
		return
	status_key = ""
	match str(result.get("action", "")):
		"dialogue":
			_start_dialogue(str(result.get("dialogue_id", "")))
		"treasure":
			status_key = "world.explore.chest_opened"
			_refresh_markers()
		"battle":
			_launch_battle(result)
		"world_map":
			_return_to_map()
		"travel":
			_travel_to(str(result.get("location_id", "")))
		_:
			status_key = "world.error.invalid_exit"
	_refresh_presentation()


func _start_dialogue(dialogue_id: String) -> void:
	var page: Dictionary = dialogue.start(dialogue_id)
	if not bool(page.get("ok", false)):
		status_key = "world.error.invalid_exit"
		return
	dialogue_panel.show_page(page)
	_clear_dialogue_labels()


func _clear_dialogue_labels() -> void:
	# The interaction prompt sits underneath the panel; leaving it visible
	# bleeds stale text through the translucent background.
	prompt_label.text = ""
	status_label.text = ""


func _advance_dialogue() -> void:
	var page: Dictionary = dialogue.advance()
	if not bool(page.get("ok", false)) or bool(page.get("closed", false)):
		dialogue_panel.hide()
		return
	dialogue_panel.show_page(page)
	_clear_dialogue_labels()
	_refresh_markers()


func _choose_dialogue(choice_id: String) -> void:
	var page: Dictionary = dialogue.choose(choice_id)
	if not bool(page.get("ok", false)):
		status_key = str(page.get("reason", ""))
		return
	if bool(page.get("closed", false)):
		dialogue_panel.hide()
	else:
		dialogue_panel.show_page(page)
		_clear_dialogue_labels()
	_refresh_markers()
	_refresh_presentation()


func _close_dialogue() -> void:
	dialogue.close()
	dialogue_panel.hide()
	for button_variant: Variant in marker_buttons.values():
		if button_variant is Button:
			(button_variant as Button).grab_focus()
			break


func _launch_battle(result: Dictionary) -> void:
	var encounter_id: String = str(result.get("encounter_id", ""))
	if encounter_id.is_empty():
		var trigger: Dictionary = _repository.call("get_world_interactable", str(result.get("id", "")))
		encounter_id = str(trigger.get("encounter_id", ""))
	if encounter_id.is_empty():
		status_key = "world.error.invalid_exit"
		return
	WorldContext.write({
		"encounter_id": encounter_id,
		"return_scene": WorldContext.EXPLORATION_PATH,
		"location_id": area_id,
		"trigger_id": str(result.get("id", ""))
	})
	var error: Error = get_tree().change_scene_to_file(BATTLE_PATH)
	if error != OK:
		status_key = "common.note"


func _travel_to(destination: String) -> void:
	if destination.is_empty() or not locations_repo.location_exists(destination):
		status_key = "world.error.invalid_exit"
		return
	WorldContext.write({"location_id": destination, "return_scene": WORLD_MAP_PATH})
	var error: Error = get_tree().change_scene_to_file(WorldContext.EXPLORATION_PATH)
	if error != OK:
		status_key = "common.note"


func _return_to_map() -> void:
	WorldContext.clear()
	var error: Error = get_tree().change_scene_to_file(WORLD_MAP_PATH)
	if error != OK:
		status_key = "common.note"


func _toggle_pause() -> void:
	_paused = not _paused
	pause_panel.visible = _paused
	if _paused:
		resume_button.grab_focus()
	else:
		movement.clear_move_target()


func _refresh_presentation() -> void:
	player_marker.position = _design_to_screen(movement.position) - Vector2(14, 14)
	var nearest: Dictionary = interaction.nearest(movement.position)
	if dialogue.is_active():
		prompt_label.text = ""
	elif not nearest.is_empty():
		var entry: Dictionary = nearest.get("definition", {})
		prompt_label.text = LocaleManager.t(str(entry.get("prompt_key", ""))) + " · " + LocaleManager.t(
			str(entry.get("name_key", ""))
		)
	elif status_key.is_empty():
		prompt_label.text = ""
	else:
		prompt_label.text = t(_status_message_key(status_key))
	status_label.text = "" if status_key.is_empty() else t(_status_message_key(status_key))
	queue_redraw()


func _status_message_key(key: String) -> String:
	var known: Array[String] = [
		"world.explore.out_of_range", "world.explore.locked", "world.explore.chest_opened",
		"world.explore.battle_victory", "world.explore.battle_defeat",
		"world.travel.denied", "world.error.invalid_exit", "common.note"
	]
	return key if known.has(key) else "world.explore.out_of_range"


func _process(delta: float) -> void:
	if _paused or dialogue.is_active():
		return
	var direction := Vector2.ZERO
	if bool(_held_keys.get("left", false)):
		direction.x -= 1
	if bool(_held_keys.get("right", false)):
		direction.x += 1
	if bool(_held_keys.get("up", false)):
		direction.y -= 1
	if bool(_held_keys.get("down", false)):
		direction.y += 1
	if direction.length_squared() > 0:
		movement.clear_move_target()
		movement.move(delta, direction)
	else:
		movement.move_to_target(delta)
	_refresh_presentation()


func _draw() -> void:
	var playfield := _screen_rect(Rect2(44, 84, 1192, 596))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.09, 0.12), true)
	draw_rect(playfield, Color(0.10, 0.15, 0.19), true)
	draw_rect(playfield, Color(0.40, 0.56, 0.62), false, 3.0)
	for obstacle: Rect2 in _obstacles():
		var shape := _screen_rect(obstacle)
		draw_rect(shape, Color(0.18, 0.25, 0.31), true)
		draw_rect(shape, Color(0.52, 0.63, 0.69), false, 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: InputEventKey = event
		if not key.pressed:
			return
		# Dialogue owns keyboard input before movement keys are latched.
		if dialogue.is_active():
			var focus_owner: Control = get_viewport().gui_get_focus_owner()
			match key.keycode:
				KEY_UP:
					if focus_owner != null:
						var previous: Control = focus_owner.get_node_or_null(
							focus_owner.get_focus_neighbor(SIDE_TOP)
						) as Control
						if previous != null:
							previous.grab_focus()
					get_viewport().set_input_as_handled()
				KEY_DOWN:
					if focus_owner != null:
						var next_focus: Control = focus_owner.get_node_or_null(
							focus_owner.get_focus_neighbor(SIDE_BOTTOM)
						) as Control
						if next_focus != null:
							next_focus.grab_focus()
					get_viewport().set_input_as_handled()
				KEY_E, KEY_SPACE, KEY_ENTER:
					# A focused choice button handles ui_accept itself; do not
					# silently select choice 0 behind the user's selection.
					if focus_owner is Button and bool(dialogue.current().get("awaiting_choice", false)):
						return
					var page: Dictionary = dialogue.current()
					if bool(page.get("awaiting_choice", false)):
						var choices: Array = page.get("choices", [])
						if not choices.is_empty():
							_choose_dialogue(str((choices[0] as Dictionary).get("id", "")))
					else:
						_advance_dialogue()
					get_viewport().set_input_as_handled()
				KEY_ESCAPE:
					_close_dialogue()
					get_viewport().set_input_as_handled()
			return
		if _held_key_change(key):
			get_viewport().set_input_as_handled()
			return
		if _paused:
			if key.keycode == KEY_ESCAPE:
				_toggle_pause()
				get_viewport().set_input_as_handled()
			return
		match key.keycode:
			KEY_W, KEY_UP:
				_held_keys["up"] = true
				get_viewport().set_input_as_handled()
			KEY_S, KEY_DOWN:
				_held_keys["down"] = true
				get_viewport().set_input_as_handled()
			KEY_A, KEY_LEFT:
				_held_keys["left"] = true
				get_viewport().set_input_as_handled()
			KEY_D, KEY_RIGHT:
				_held_keys["right"] = true
				get_viewport().set_input_as_handled()
			KEY_E, KEY_SPACE:
				interact_at_player()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_toggle_pause()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if _paused or dialogue.is_active() or mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed:
			return
		var design_point := _screen_to_design(mouse.position)
		if design_point.y < 84 or design_point.y > 680:
			return
		movement.set_move_target(design_point)
		get_viewport().set_input_as_handled()


func _held_key_change(key: InputEventKey) -> bool:
	var key_name: String = ""
	match key.keycode:
		KEY_W, KEY_UP: key_name = "up"
		KEY_S, KEY_DOWN: key_name = "down"
		KEY_A, KEY_LEFT: key_name = "left"
		KEY_D, KEY_RIGHT: key_name = "right"
		_: return false
	_held_keys[key_name] = key.pressed
	return true


func _apply_locale(_locale: String = "") -> void:
	var location: Dictionary = locations_repo.get_location(area_id)
	title_label.text = t("world.explore.title") + " · " + LocaleManager.t(str(location.get("name_key", "")))
	controls_label.text = t("world.explore.controls")
	pause_title.text = t("world.explore.pause")
	resume_button.text = t("world.explore.resume")
	return_button.text = t("world.explore.return_map")
	_refresh_markers()
	_refresh_presentation()
