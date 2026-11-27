class_name EventBackdrop
extends Control

## Low-cost atmospheric backdrop drawn with Godot primitives only.
## It never receives input and carries no content meaning.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var size_vector: Vector2 = size
	if size_vector.x <= 0.0 or size_vector.y <= 0.0:
		return
	var bands: int = 16
	var band_height: float = size_vector.y / float(bands)
	for index: int in range(bands):
		var blend: float = float(index) / float(maxi(1, bands - 1))
		var color: Color = EventTheme.BG.lerp(EventTheme.BG_SECONDARY, blend)
		draw_rect(Rect2(0.0, float(index) * band_height, size_vector.x, band_height + 1.0), color)
	var glow_center: Vector2 = Vector2(size_vector.x * 0.52, size_vector.y * 0.08)
	draw_circle(glow_center, maxf(size_vector.x, size_vector.y) * 0.34, Color(EventTheme.CYAN.r, EventTheme.CYAN.g, EventTheme.CYAN.b, 0.055))
	draw_circle(Vector2(size_vector.x * 0.06, size_vector.y * 0.92), maxf(size_vector.x, size_vector.y) * 0.28, Color(EventTheme.GOLD.r, EventTheme.GOLD.g, EventTheme.GOLD.b, 0.035))
	var step: float = maxf(64.0, size_vector.x / 14.0)
	var line_color := Color(EventTheme.GOLD.r, EventTheme.GOLD.g, EventTheme.GOLD.b, 0.055)
	var cursor: float = 0.0
	while cursor < size_vector.x + size_vector.y:
		draw_line(Vector2(cursor, 0.0), Vector2(cursor - size_vector.y, size_vector.y), line_color, 1.0, true)
		cursor += step
	draw_rect(Rect2(4.0, 4.0, size_vector.x - 8.0, size_vector.y - 8.0), Color(EventTheme.GOLD.r, EventTheme.GOLD.g, EventTheme.GOLD.b, 0.25), false, 1.0, true)
