class_name EventArtwork
extends Control

## Original, deterministic vector artwork for synthetic event fixtures.
## No external image, FFBE art or unverified asset is loaded.

var _seed_value: int = 0
var _category: String = "story"
var _accent: Color = EventTheme.CYAN
var _caption_text: String = ""
var _caption: Label = null


func configure(
	event_id: String,
	category: String,
	accent: Color,
	caption: String,
	minimum_size: Vector2 = Vector2(280, 132)
) -> void:
	_seed_value = absi(event_id.hash())
	_category = category
	_accent = accent
	_caption_text = caption
	custom_minimum_size = minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _caption != null:
		_caption.text = caption
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption = EventTheme.make_label(_caption_text, EventTheme.FONT_TINY, Color(EventTheme.TEXT.r, EventTheme.TEXT.g, EventTheme.TEXT.b, 0.82))
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_top = -24
	_caption.offset_bottom = -3
	add_child(_caption)


func _draw() -> void:
	var size_vector: Vector2 = size
	if size_vector.x <= 0.0 or size_vector.y <= 0.0:
		return
	_draw_layered_background(size_vector)
	_draw_motif(size_vector)
	_draw_ornament(size_vector)


func _draw_layered_background(size_vector: Vector2) -> void:
	var bands: int = 10
	var band_height: float = size_vector.y / float(bands)
	for index: int in range(bands):
		var blend: float = float(index) / float(maxi(1, bands - 1))
		var color: Color = EventTheme.BG_SECONDARY.lerp(EventTheme.PANEL_ELEVATED, blend)
		color.a = 0.96
		draw_rect(Rect2(0.0, float(index) * band_height, size_vector.x, band_height + 1.0), color)
	var glow: Color = Color(_accent.r, _accent.g, _accent.b, 0.12)
	draw_circle(Vector2(size_vector.x * 0.72, size_vector.y * 0.38), min(size_vector.x, size_vector.y) * 0.52, glow)


func _draw_motif(size_vector: Vector2) -> void:
	var center: Vector2 = Vector2(size_vector.x * 0.52, size_vector.y * 0.45)
	var unit: float = mini(size_vector.x, size_vector.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_value
	for index: int in range(7):
		var radius: float = unit * (0.10 + float(index) * 0.055)
		var alpha: float = 0.18 - float(index) * 0.017
		draw_arc(center, radius, 0.0, TAU, 72, Color(_accent.r, _accent.g, _accent.b, maxf(0.03, alpha)), 1.4, true)
	for index: int in range(18):
		var point := Vector2(
			rng.randf_range(size_vector.x * 0.08, size_vector.x * 0.92),
			rng.randf_range(size_vector.y * 0.10, size_vector.y * 0.72)
		)
		var star_size: float = rng.randf_range(1.0, 2.8)
		var star_color := Color(EventTheme.TEXT.r, EventTheme.TEXT.g, EventTheme.TEXT.b, rng.randf_range(0.18, 0.55))
		draw_line(point + Vector2(-star_size, 0.0), point + Vector2(star_size, 0.0), star_color, 1.0, true)
		draw_line(point + Vector2(0.0, -star_size), point + Vector2(0.0, star_size), star_color, 1.0, true)

	match _category:
		"collaboration":
			_draw_interlocking_rings(center, unit)
		"limited":
			_draw_crescent(center, unit)
		"permanent":
			_draw_pillars(center, unit)
		"seasonal":
			_draw_radial(center, unit, 8)
		"challenge":
			_draw_chevrons(center, unit)
		_:
			_draw_radial(center, unit, 6)


func _draw_interlocking_rings(center: Vector2, unit: float) -> void:
	var left: Vector2 = center + Vector2(-unit * 0.12, 0.0)
	var right: Vector2 = center + Vector2(unit * 0.12, 0.0)
	var radius: float = unit * 0.24
	var gold: Color = Color(EventTheme.GOLD.r, EventTheme.GOLD.g, EventTheme.GOLD.b, 0.82)
	draw_arc(left, radius, 0.0, TAU, 64, gold, 2.0, true)
	draw_arc(right, radius, 0.0, TAU, 64, Color(_accent.r, _accent.g, _accent.b, 0.86), 2.0, true)
	draw_line(center + Vector2(-unit * 0.32, unit * 0.22), center + Vector2(unit * 0.32, unit * 0.22), gold, 1.2, true)


func _draw_crescent(center: Vector2, unit: float) -> void:
	var gold: Color = Color(EventTheme.GOLD.r, EventTheme.GOLD.g, EventTheme.GOLD.b, 0.86)
	draw_arc(center, unit * 0.26, deg_to_rad(35.0), deg_to_rad(325.0), 64, gold, 2.4, true)
	draw_arc(center + Vector2(unit * 0.06, 0.0), unit * 0.20, deg_to_rad(45.0), deg_to_rad(315.0), 64, Color(_accent.r, _accent.g, _accent.b, 0.7), 1.2, true)


func _draw_pillars(center: Vector2, unit: float) -> void:
	var color: Color = Color(EventTheme.GOLD.r, EventTheme.GOLD.g, EventTheme.GOLD.b, 0.72)
	for offset: float in [-0.24, -0.08, 0.08, 0.24]:
		var x: float = center.x + unit * offset
		draw_line(Vector2(x, center.y - unit * 0.26), Vector2(x, center.y + unit * 0.26), color, 2.0, true)
	draw_line(center + Vector2(-unit * 0.30, -unit * 0.26), center + Vector2(unit * 0.30, -unit * 0.26), color, 2.0, true)
	draw_line(center + Vector2(-unit * 0.30, unit * 0.26), center + Vector2(unit * 0.30, unit * 0.26), color, 2.0, true)


func _draw_radial(center: Vector2, unit: float, spokes: int) -> void:
	var color: Color = Color(EventTheme.GOLD.r, EventTheme.GOLD.g, EventTheme.GOLD.b, 0.78)
	for index: int in range(spokes):
		var angle: float = TAU * float(index) / float(spokes)
		var inner: Vector2 = center + Vector2(cos(angle), sin(angle)) * unit * 0.08
		var outer: Vector2 = center + Vector2(cos(angle), sin(angle)) * unit * 0.30
		draw_line(inner, outer, color, 1.8, true)
	draw_circle(center, unit * 0.045, Color(_accent.r, _accent.g, _accent.b, 0.95))


func _draw_chevrons(center: Vector2, unit: float) -> void:
	var color: Color = Color(EventTheme.GOLD.r, EventTheme.GOLD.g, EventTheme.GOLD.b, 0.82)
	for index: int in range(3):
		var y: float = center.y - unit * 0.16 + float(index) * unit * 0.16
		var half_width: float = unit * (0.30 - float(index) * 0.05)
		var points := PackedVector2Array([
			center + Vector2(-half_width, y + unit * 0.10),
			center + Vector2(0.0, y - unit * 0.06),
			center + Vector2(half_width, y + unit * 0.10)
		])
		draw_polyline(points, color, 2.0, true)


func _draw_ornament(size_vector: Vector2) -> void:
	var gold: Color = Color(EventTheme.GOLD.r, EventTheme.GOLD.g, EventTheme.GOLD.b, 0.72)
	draw_rect(Rect2(1.0, 1.0, size_vector.x - 2.0, size_vector.y - 2.0), gold, false, 1.5, true)
	var corner: float = minf(18.0, min(size_vector.x, size_vector.y) * 0.12)
	draw_line(Vector2(1.0, corner), Vector2(1.0, 1.0), gold, 2.0, true)
	draw_line(Vector2(1.0, 1.0), Vector2(corner, 1.0), gold, 2.0, true)
	draw_line(Vector2(size_vector.x - corner, size_vector.y - 1.0), Vector2(size_vector.x - 1.0, size_vector.y - 1.0), gold, 2.0, true)
	draw_line(Vector2(size_vector.x - 1.0, size_vector.y - 1.0), Vector2(size_vector.x - 1.0, size_vector.y - corner), gold, 2.0, true)
