extends Control

## Data-driven World Map. All visible copy is localized and every marker is
## derived from the synthetic repository plus persisted PlayerState world state.

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"
const FIRST_REGION := "region:GL:1001@vale"

@onready var title_label: Label = $Layout/Header/TitleLabel
@onready var subtitle_label: Label = $Layout/Header/SubtitleLabel
@onready var map_area: WorldMapMarkerArea = $Layout/Main/MapFrame/MapArea
@onready var legend_label: Label = $Layout/Main/InfoPanel/LegendLabel
@onready var name_label: Label = $Layout/Main/InfoPanel/NameLabel
@onready var description_label: Label = $Layout/Main/InfoPanel/DescriptionLabel
@onready var state_label: Label = $Layout/Main/InfoPanel/StateLabel
@onready var requirements_label: Label = $Layout/Main/InfoPanel/RequirementsLabel
@onready var connections_label: Label = $Layout/Main/InfoPanel/ConnectionsLabel
@onready var reward_label: Label = $Layout/Main/InfoPanel/RewardLabel
@onready var enter_button: Button = $Layout/Main/InfoPanel/EnterButton
@onready var journal_button: Button = $Layout/Main/InfoPanel/JournalButton
@onready var zoom_in_button: Button = $Layout/Main/InfoPanel/ZoomRow/ZoomInButton
@onready var zoom_out_button: Button = $Layout/Main/InfoPanel/ZoomRow/ZoomOutButton
@onready var controls_label: Label = $Layout/ControlsLabel
@onready var status_label: Label = $Layout/StatusLabel
@onready var journal_panel: PanelContainer = $JournalPanel
@onready var journal_title: Label = $JournalPanel/JournalLayout/JournalTitle
@onready var journal_content: RichTextLabel = $JournalPanel/JournalLayout/JournalContent
@onready var journal_close_button: Button = $JournalPanel/JournalLayout/JournalCloseButton

var locations_repo: WorldLocationRepository
var world: WorldStateService
var quests: QuestManager
var location_ids: Array[String] = []
var selected_id: String = ""
var focus_index: int = 0
var zoom: float = 1.0
var _repository: Node


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_repository = _get_repository()
	locations_repo = WorldLocationRepository.new(_repository)
	world = WorldStateService.new()
	quests = QuestManager.new()
	add_child(quests)
	quests._ready()
	_apply_qa_scenario()
	map_area.marker_selected.connect(_on_marker_selected)
	map_area.marker_hovered.connect(_on_marker_hovered)
	enter_button.pressed.connect(_on_enter_pressed)
	journal_button.pressed.connect(toggle_journal)
	journal_close_button.pressed.connect(_close_journal)
	zoom_in_button.pressed.connect(func() -> void: _change_zoom(0.12))
	zoom_out_button.pressed.connect(func() -> void: _change_zoom(-0.12))
	LocaleManager.locale_changed.connect(_apply_locale)
	journal_panel.visible = false
	_rebuild()
	_apply_locale(LocaleManager.current_locale)
	enter_button.grab_focus()


func t(key: String, args: Dictionary = {}) -> String:
	return LocaleManager.t(key, args)


func _get_repository() -> Node:
	var loop: Variant = Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("ContentRepository")
	return null


func _apply_qa_scenario() -> void:
	var scenario: String = OS.get_environment("FFBE_QA_SCENARIO")
	if scenario == "quest_complete" or scenario == "quest_complete_journal":
		_seed_completed_quest()
	if scenario == "journal" or scenario == "quest_complete_journal":
		call_deferred("toggle_journal")
	if scenario == "locked":
		selected_id = "loc:GL:1103@spire"
	elif scenario == "selected":
		selected_id = "loc:GL:1102@meadow"


## QA-only deterministic state seeding in an isolated profile. This never runs
## in the normal game path and never touches the owner's real save.
func _seed_completed_quest() -> void:
	if quests.status("quest:GL:3100@oath") == "not_started":
		quests.accept("quest:GL:3100@oath")
		quests.record_event({"type": "talk_to", "target": "npc:GL:2101@keeper", "count": 1})
	if quests.status("quest:GL:3101@lantern") == "not_started":
		quests.accept("quest:GL:3101@lantern")
		for event: Dictionary in [
			{"type": "talk_to", "target": "npc:GL:2102@scout", "count": 1},
			{"type": "visit_location", "target": "loc:GL:1102@meadow", "count": 1},
			{"type": "open_treasure", "target": "treasure:GL:4101@meadow", "count": 1},
			{"type": "defeat_encounter", "target": "encounter:GL:950001@skirmish", "count": 1},
			{"type": "collect", "target": "fragment:GL:910101@base", "count": 1},
			{"type": "complete_quest", "target": "quest:GL:3100@oath", "count": 1}
		]:
			quests.record_event(event)


func _rebuild() -> void:
	location_ids = locations_repo.get_locations_for_region(FIRST_REGION)
	if location_ids.is_empty():
		status_label.text = t("world.map.no_selection")
		return
	if selected_id.is_empty() or not location_ids.has(selected_id):
		selected_id = location_ids[0]
	focus_index = maxi(0, location_ids.find(selected_id))
	var records: Dictionary = {}
	var states: Dictionary = {}
	var quest_states: Dictionary = {}
	for quest_id: String in quests.repository.get_quest_ids():
		quest_states[quest_id] = world.get_quest_state(quest_id)
	for id: String in location_ids:
		records[id] = locations_repo.get_location(id)
		var unlocked: bool = locations_repo.meets_requirements(id, world.state(), quest_states)
		states[id] = {
			"unlocked": unlocked,
			"discovered": world.is_discovered(id),
			"completed": world.is_completed(id),
			"current": str(world.state().get("current_location", "")) == id
		}
	var edges: Array = []
	for connection_id: String in locations_repo.get_connections().keys():
		var edge: Variant = _repository.call("get_world_connection", connection_id)
		if edge is Dictionary:
			edges.append(edge)
	map_area.set_data(records, states, edges)
	map_area.set_selection(selected_id)
	map_area.scale = Vector2.ONE * zoom
	_update_info()


func _update_info() -> void:
	var location: Dictionary = locations_repo.get_location(selected_id)
	if location.is_empty():
		name_label.text = t("world.map.no_selection")
		return
	var quest_states: Dictionary = {}
	for quest_id: String in quests.repository.get_quest_ids():
		quest_states[quest_id] = world.get_quest_state(quest_id)
	var unlocked: bool = locations_repo.meets_requirements(selected_id, world.state(), quest_states)
	var state_parts: Array[String] = []
	if unlocked:
		state_parts.append(t("world.map.discovered"))
	else:
		state_parts.append(t("world.map.locked"))
	if world.is_completed(selected_id):
		state_parts.append(t("world.map.completed"))
	if str(world.state().get("current_location", "")) == selected_id:
		state_parts.append(t("world.map.current"))
	name_label.text = LocaleManager.t(str(location.get("name_key", "")))
	description_label.text = LocaleManager.t(str(location.get("description_key", "")))
	state_label.text = t("world.map.location_state") + ": " + ", ".join(state_parts)
	var requirement_parts: Array[String] = []
	var requirements: Dictionary = location.get("unlock_requirements", {})
	for quest_id: Variant in requirements.get("quests", []):
		requirement_parts.append(LocaleManager.t(quests.repository.get_quest(str(quest_id)).get("name_key", "")))
	for flag: Variant in requirements.get("flags", []):
		requirement_parts.append(str(flag))
	requirements_label.text = t("world.map.requirements") + ": " + (
		", ".join(requirement_parts) if not requirement_parts.is_empty() else "-"
	)
	var connections: Array[String] = locations_repo.connections_for(selected_id)
	var connection_names: Array[String] = []
	for connected_id: String in connections:
		var connected: Dictionary = locations_repo.get_location(connected_id)
		connection_names.append(LocaleManager.t(str(connected.get("name_key", ""))))
	connections_label.text = t("world.map.connections") + ": " + (
		", ".join(connection_names) if not connection_names.is_empty() else "-"
	)
	var encounter_id: String = str(location.get("encounter_id", ""))
	reward_label.text = t("world.map.reward_summary") + ": " + (
		encounter_id if not encounter_id.is_empty() else "-"
	)
	enter_button.disabled = not unlocked
	enter_button.text = t("world.map.enter") if unlocked else t("world.map.locked")


func _on_marker_selected(id: String) -> void:
	selected_id = id
	focus_index = maxi(0, location_ids.find(id))
	_update_info()
	map_area.set_selection(id)


func _on_marker_hovered(_id: String) -> void:
	pass


func _on_enter_pressed() -> void:
	if selected_id.is_empty():
		status_label.text = t("world.map.no_selection")
		return
	var current: String = str(world.state().get("current_location", ""))
	if not selected_id == current and not locations_repo.has_connection(current, selected_id):
		status_label.text = t("world.map.no_route")
		return
	var quest_states: Dictionary = {}
	for quest_id: String in quests.repository.get_quest_ids():
		quest_states[quest_id] = world.get_quest_state(quest_id)
	if not locations_repo.meets_requirements(selected_id, world.state(), quest_states):
		status_label.text = t("world.travel.denied")
		return
	WorldContext.write({
		"location_id": selected_id,
		"return_scene": WorldContext.WORLD_MAP_PATH
	})
	var error: Error = get_tree().change_scene_to_file(WorldContext.EXPLORATION_PATH)
	if error == OK:
		status_label.text = ""
	else:
		status_label.text = t("common.note") + " " + str(error)


func toggle_journal() -> void:
	if journal_panel.visible:
		_close_journal()
		return
	journal_panel.visible = true
	_render_journal()
	journal_close_button.grab_focus()


func _close_journal() -> void:
	journal_panel.visible = false
	journal_button.grab_focus()


func _render_journal() -> void:
	var lines: Array[String] = []
	for entry: Dictionary in quests.journal():
		var status_key: String = "world.journal.%s" % str(entry.get("status", "not_started"))
		lines.append("%s [%s]" % [LocaleManager.t(str(entry.get("name_key", ""))), t(status_key)])
		lines.append("  " + LocaleManager.t(str(entry.get("description_key", ""))))
		var progress_map: Dictionary = entry.get("progress", {})
		for objective: Dictionary in (entry.get("objectives", []) as Array):
			var objective_id: String = str(objective.get("id", ""))
			var done: int = int(progress_map.get(objective_id, 0))
			var required: int = maxi(1, int(objective.get("count", 1)))
			lines.append("  - %s (%d/%d)" % [
				LocaleManager.t(str(objective.get("description_key", ""))), done, required
			])
	if lines.is_empty():
		lines.append(t("world.journal.empty"))
	journal_content.text = "\n".join(lines)


func _change_zoom(delta: float) -> void:
	zoom = clampf(zoom + delta, 0.8, 1.4)
	map_area.scale = Vector2.ONE * zoom
	queue_redraw()


func _apply_locale(_locale: String = "") -> void:
	title_label.text = t("world.map.title")
	subtitle_label.text = t("world.map.subtitle")
	legend_label.text = t("world.map.legend")
	controls_label.text = t("world.map.controls")
	journal_title.text = t("world.journal.title")
	journal_close_button.text = t("world.journal.close")
	_update_info()
	if journal_panel.visible:
		_render_journal()


func _unhandled_input(event: InputEvent) -> void:
	if journal_panel.visible:
		if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
			_close_journal()
			get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey:
		return
	var key: InputEventKey = event
	if not key.pressed:
		return
	match key.keycode:
		KEY_LEFT, KEY_A:
			_focus_shift(-1)
			get_viewport().set_input_as_handled()
		KEY_RIGHT, KEY_D:
			_focus_shift(1)
			get_viewport().set_input_as_handled()
		KEY_ENTER:
			_on_enter_pressed()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			var error: Error = get_tree().change_scene_to_file(MAIN_MENU_PATH)
			if error != OK:
				status_label.text = t("common.note") + " " + str(error)
			get_viewport().set_input_as_handled()


func _focus_shift(direction: int) -> void:
	if location_ids.is_empty():
		return
	focus_index = wrapi(focus_index + direction, 0, location_ids.size())
	_on_marker_selected(location_ids[focus_index])
