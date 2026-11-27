class_name EventCard
extends Button

## Reusable designed card for Event Center lists and detail sections.
## Presentation only: it emits activated(payload); the coordinator calls services.

signal activated(payload: Dictionary)

var card_kind: String = "event"
var payload: Dictionary = {}
var _selected: bool = false
var _body: VBoxContainer = null
var _badge_row: HBoxContainer = null
var _badge: Label = null
var _state: Label = null
var _art: EventArtwork = null
var _title: Label = null
var _subtitle: Label = null
var _meta: Label = null
var _reward: Label = null
var _progress: EventProgress = null


func _ready() -> void:
	flat = true
	# The Button.text mirror exists for accessibility and existing scene tests;
	# visible copy is drawn by child Labels so the card can use a custom layout.
	# Do not clear it here: configure() may run before the node enters the tree.
	add_theme_font_size_override("font_size", 1)
	add_theme_color_override("font_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_color_hover", Color(0, 0, 0, 0))
	add_theme_color_override("font_color_pressed", Color(0, 0, 0, 0))
	add_theme_color_override("font_color_disabled", Color(0, 0, 0, 0))
	add_theme_color_override("font_color_focus", Color(0, 0, 0, 0))
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	_build()
	_apply_style()
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _build() -> void:
	if _body != null:
		return
	_body = VBoxContainer.new()
	_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.offset_left = 11.0
	_body.offset_right = -11.0
	_body.offset_top = 9.0
	_body.offset_bottom = -9.0
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_theme_constant_override("separation", 4)
	add_child(_body)

	_badge_row = HBoxContainer.new()
	_badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_badge_row)
	_badge = EventTheme.make_label("", EventTheme.FONT_TINY, EventTheme.GOLD)
	_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_badge_row.add_child(_badge)
	_state = EventTheme.make_label("", EventTheme.FONT_TINY, EventTheme.CYAN)
	_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_state.size_flags_horizontal = Control.SIZE_SHRINK_END
	_badge_row.add_child(_state)

	_art = EventArtwork.new()
	_art.visible = false
	_body.add_child(_art)

	_title = EventTheme.make_label("", EventTheme.FONT_TITLE, EventTheme.TEXT)
	_body.add_child(_title)
	_subtitle = EventTheme.make_label("", EventTheme.FONT_SMALL, EventTheme.TEXT_MUTED)
	_body.add_child(_subtitle)
	_meta = EventTheme.make_label("", EventTheme.FONT_TINY, EventTheme.TEXT_MUTED)
	_body.add_child(_meta)
	_reward = EventTheme.make_label("", EventTheme.FONT_TINY, EventTheme.GOLD)
	_body.add_child(_reward)

	_progress = EventProgress.new()
	_progress.visible = false
	_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_progress)


func configure(data: Dictionary) -> void:
	if _body == null:
		_build()
	card_kind = str(data.get("kind", "event"))
	payload = data.get("payload", {}) if data.get("payload", {}) is Dictionary else {}
	_title.text = str(data.get("title", ""))
	_subtitle.text = str(data.get("subtitle", ""))
	_meta.text = str(data.get("meta", ""))
	_reward.text = str(data.get("reward", ""))
	_badge.text = str(data.get("badge", ""))
	_state.text = str(data.get("state", ""))
	_state.add_theme_color_override("font_color", _state_color(str(data.get("state_key", ""))))
	text = _accessible_summary(data)

	var show_art: bool = bool(data.get("show_art", false))
	_art.visible = show_art
	if show_art:
		var art_size: Vector2 = Vector2(280, 132)
		var requested_art_size: Variant = data.get("art_minimum_size", null)
		if requested_art_size is Vector2:
			art_size = requested_art_size
		_art.configure(
			str(data.get("art_event_id", "")),
			str(data.get("art_category", "story")),
			EventTheme.accent_for_category(str(data.get("art_category", "story"))),
			str(data.get("art_caption", "")),
			art_size
		)

	var has_progress: bool = data.has("progress_current") and data.has("progress_target")
	_progress.visible = has_progress
	if has_progress:
		_progress.set_progress(
			int(data.get("progress_current", 0)),
			int(data.get("progress_target", 1)),
			str(data.get("progress_text", ""))
		)

	disabled = bool(data.get("disabled", false))
	set_selected(bool(data.get("selected", false)))
	var requested_size: Variant = data.get("minimum_size", null)
	custom_minimum_size = requested_size if requested_size is Vector2 else _minimum_size()
	size_flags_vertical = Control.SIZE_EXPAND_FILL if card_kind in ["event", "stage", "mission"] else Control.SIZE_SHRINK_BEGIN
	_apply_style()
	queue_redraw()


func set_selected(value: bool) -> void:
	if _selected == value:
		return
	_selected = value
	_apply_style()


func is_selected() -> bool:
	return _selected


func _accessible_summary(data: Dictionary) -> String:
	var parts: Array[String] = []
	for field: String in ["badge", "title", "state", "subtitle", "meta", "reward", "progress_text"]:
		var value: String = str(data.get(field, ""))
		if not value.is_empty():
			parts.append(value)
	return " · ".join(parts)


func _minimum_size() -> Vector2:
	match card_kind:
		"event":
			return Vector2(318, 214)
		"stage":
			return Vector2(318, 132)
		"mission":
			return Vector2(318, 126)
		"shop":
			return Vector2(282, 118)
		"summon":
			return Vector2(318, 148)
		_:
			return Vector2(318, 112)


func _state_color(state_key: String) -> Color:
	match state_key:
		"locked", "insufficient", "out_of_stock":
			return EventTheme.DANGER
		"complete", "claimed", "purchased":
			return EventTheme.SUCCESS
		"selected", "active", "claimable", "available":
			return EventTheme.CYAN
		_:
			return EventTheme.TEXT_MUTED


func _apply_style() -> void:
	var bg: Color = EventTheme.PANEL_ELEVATED.lightened(0.05) if _selected else EventTheme.PANEL_ELEVATED
	var border: Color = EventTheme.GOLD if _selected else EventTheme.GOLD_DIM
	var border_width: int = 2 if _selected else 1
	add_theme_stylebox_override("normal", EventTheme.make_style(bg, border, EventTheme.RADIUS, border_width, 10))
	add_theme_stylebox_override("hover", EventTheme.make_style(bg.lightened(0.05), EventTheme.CYAN, EventTheme.RADIUS, 2, 10))
	add_theme_stylebox_override("pressed", EventTheme.make_style(EventTheme.PANEL, EventTheme.GOLD, EventTheme.RADIUS, 2, 10))
	add_theme_stylebox_override("disabled", EventTheme.make_style(EventTheme.PANEL, Color(EventTheme.GOLD_DIM.r, EventTheme.GOLD_DIM.g, EventTheme.GOLD_DIM.b, 0.38), EventTheme.RADIUS, 1, 10))


func _on_pressed() -> void:
	if not disabled:
		activated.emit(payload.duplicate(true))


func _on_mouse_entered() -> void:
	if not disabled:
		EventTheme.tween_property(self, "modulate", Color(1.04, 1.04, 1.04, 1.0), 0.12)


func _on_mouse_exited() -> void:
	EventTheme.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.16)
