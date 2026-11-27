class_name EventProgress
extends VBoxContainer

## Compact progress presentation with restrained fill animation.
## It reports values only; it never awards or mutates rewards.

var bar: ProgressBar = null
var value_label: Label = null

var _current: int = 0
var _target: int = 1
var _text: String = ""

var target_value: int = 1


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 3)
	_ensure_nodes()
	_apply_values()


func set_progress(current: int, target: int, text: String) -> void:
	_current = current
	_target = maxi(1, target)
	target_value = _target
	_text = text
	_ensure_nodes()
	_apply_values()


func _ensure_nodes() -> void:
	if bar == null:
		bar = ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = float(_target)
		bar.step = 1.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 10)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(bar)
	if value_label == null:
		value_label = EventTheme.make_label(_text, EventTheme.FONT_TINY, EventTheme.TEXT_MUTED)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_child(value_label)


func _apply_values() -> void:
	if bar == null or value_label == null:
		return
	bar.max_value = float(_target)
	EventTheme.tween_property(bar, "value", float(clampi(_current, 0, _target)), 0.20)
	value_label.text = _text
