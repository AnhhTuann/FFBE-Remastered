class_name WorldMapMarkerArea
extends Control

## Presentation-only world map surface. It draws project-authored shapes; no
## protected map art, tileset or texture is used.

signal marker_selected(location_id: String)
signal marker_hovered(location_id: String)

const MARKER_RADIUS := 16.0

var location_records: Dictionary = {}
var location_states: Dictionary = {}
var connection_edges: Array = []
var selected_id: String = ""
var hovered_id: String = ""


func set_data(records: Dictionary, states: Dictionary, edges: Array) -> void:
	location_records = records.duplicate(true)
	location_states = states.duplicate(true)
	connection_edges = edges.duplicate(true)
	queue_redraw()


func set_selection(id: String) -> void:
	selected_id = id
	queue_redraw()


func set_hover(id: String) -> void:
	if hovered_id == id:
		return
	hovered_id = id
	marker_hovered.emit(id)
	queue_redraw()


func marker_centers() -> Dictionary:
	var result: Dictionary = {}
	for id: String in location_records.keys():
		var record: Dictionary = location_records[id]
		var point: Dictionary = record.get("map_position", {})
		result[id] = Vector2(size.x * float(point.get("x", 0.5)), size.y * float(point.get("y", 0.5)))
	return result


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.11, 0.18), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.31, 0.44, 0.58), false, 2.0)
	for edge_variant: Variant in connection_edges:
		var edge: Dictionary = edge_variant
		var centers: Dictionary = marker_centers()
		if not centers.has(str(edge.get("from", ""))) or not centers.has(str(edge.get("to", ""))):
			continue
		draw_line(
			centers[str(edge.get("from", ""))], centers[str(edge.get("to", ""))],
			Color(0.42, 0.60, 0.70), 3.0
		)
	var centers: Dictionary = marker_centers()
	for id: String in centers.keys():
		var center: Vector2 = centers[id]
		var state: Dictionary = location_states.get(id, {})
		var color: Color = Color(0.55, 0.58, 0.64)
		if bool(state.get("unlocked", false)):
			color = Color(0.30, 0.78, 0.88)
		if bool(state.get("completed", false)):
			color = Color(0.94, 0.76, 0.28)
		if id == hovered_id:
			color = color.lightened(0.25)
		draw_circle(center, MARKER_RADIUS + 6.0, Color(0.03, 0.05, 0.09))
		draw_circle(center, MARKER_RADIUS, color)
		draw_circle(center, MARKER_RADIUS, Color(0.95, 0.97, 1.0), false, 2.0)
		if id == selected_id:
			draw_arc(center, MARKER_RADIUS + 10.0, 0.0, TAU, 32, Color(1.0, 0.92, 0.45), 2.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var nearest_id: String = _nearest_marker((event as InputEventMouseMotion).position, 28.0)
		set_hover(nearest_id)
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			var id: String = _nearest_marker(mouse.position, 30.0)
			if not id.is_empty():
				set_selection(id)
				marker_selected.emit(id)


func _nearest_marker(point: Vector2, max_distance: float) -> String:
	var centers: Dictionary = marker_centers()
	var best_id: String = ""
	var best_distance: float = max_distance
	for id: String in centers.keys():
		var distance: float = point.distance_to(centers[id])
		if distance < best_distance:
			best_distance = distance
			best_id = id
	return best_id
