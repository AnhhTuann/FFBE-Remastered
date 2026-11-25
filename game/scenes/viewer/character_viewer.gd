extends Control

## Character and asset viewer. Uses the repository abstraction only; all content
## is SYNTHETIC_FIXTURE data, and invalid metadata is shown instead of substituted.

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"

var _units: Array[UnitRecord] = []
var _current_unit: UnitRecord = null
var _current_clip_name: String = "idle"
var _favorites: Array = []
var _frame_data: Array = []

@onready var region_option: OptionButton = $Layout/Content/LeftPanel/RegionOption
@onready var unit_option: OptionButton = $Layout/Content/LeftPanel/UnitOption
@onready var clip_option: OptionButton = $Layout/Content/LeftPanel/ClipOption
@onready var stats_label: Label = $Layout/Content/LeftPanel/StatsLabel
@onready var abilities_label: Label = $Layout/Content/LeftPanel/AbilitiesLabel
@onready var provenance_label: Label = $Layout/Content/LeftPanel/ProvenanceLabel
@onready var play_button: Button = $Layout/Content/LeftPanel/Controls/PlayButton
@onready var restart_button: Button = $Layout/Content/LeftPanel/Controls/RestartButton
@onready var speed_label: Label = $Layout/Content/LeftPanel/Controls/SpeedLabel
@onready var speed_slider: HSlider = $Layout/Content/LeftPanel/Controls/SpeedSlider
@onready var sprite_area: Control = $Layout/Content/SpriteArea
@onready var sprite: AnimatedSprite2D = $Layout/Content/SpriteArea/Sprite
@onready var diagnostics_label: Label = $Layout/DiagnosticsLabel
@onready var back_button: Button = $Layout/Header/BackButton
@onready var title_label: Label = $Layout/Header/TitleLabel


func _ready() -> void:
	region_option.add_item("All regions")
	region_option.set_item_metadata(0, "ALL")
	region_option.add_item("GL only")
	region_option.set_item_metadata(1, "GL")
	region_option.add_item("JP only")
	region_option.set_item_metadata(2, "JP")

	region_option.item_selected.connect(_on_region_selected)
	unit_option.item_selected.connect(_on_unit_selected)
	clip_option.item_selected.connect(_on_clip_selected)
	play_button.pressed.connect(_toggle_playback)
	restart_button.pressed.connect(_restart_animation)
	speed_slider.value_changed.connect(_on_speed_changed)
	back_button.pressed.connect(_on_back_pressed)
	sprite_area.resized.connect(_layout_sprite)
	sprite.frame_changed.connect(_apply_frame_offset)

	_populate_units("ALL")
	if unit_option.get_item_count() > 0:
		_on_unit_selected(0)
	call_deferred("_layout_sprite")


func _process(_delta: float) -> void:
	play_button.text = "Pause" if sprite.is_playing() else "Play"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("viewer_toggle_playback"):
		_toggle_playback()
	elif event.is_action_pressed("viewer_restart_animation"):
		_restart_animation()


func _populate_units(region_filter: String) -> void:
	unit_option.clear()
	_units = ContentRepository.get_units()
	for unit: UnitRecord in _units:
		if region_filter != "ALL" and unit.region != region_filter:
			continue
		var index: int = unit_option.get_item_count()
		unit_option.add_item("%s · %s" % [unit.display_id(), unit.display_name])
		unit_option.set_item_metadata(index, unit.id)

	if unit_option.get_item_count() > 0:
		unit_option.select(0)
		_on_unit_selected(0)
	else:
		_current_unit = null
		_update_info()
		_show_diagnostics(["No units found for the selected region"])


func _on_region_selected(index: int) -> void:
	_populate_units(str(region_option.get_item_metadata(index)))


func _on_unit_selected(index: int) -> void:
	var unit_id: String = str(unit_option.get_item_metadata(index))
	_current_unit = ContentRepository.get_unit(unit_id)
	if _current_unit == null:
		_show_diagnostics(["Unknown unit identity: %s" % unit_id])
		return

	title_label.text = "Character Viewer — %s (%s)" % [_current_unit.display_name, _current_unit.region]
	SaveManager.update_settings({
		"last_region": _current_unit.region,
		"last_unit_id": _current_unit.id
	})
	_populate_clips()
	_update_info()
	if clip_option.get_item_count() > 0:
		_on_clip_selected(0)


func _populate_clips() -> void:
	clip_option.clear()
	if _current_unit == null:
		return

	var names: Array[String] = ContentRepository.get_clip_names(_current_unit.animation_id)
	if names.is_empty():
		var index: int = clip_option.get_item_count()
		clip_option.add_item("no clips")
		clip_option.set_item_metadata(index, "")
		return

	for clip_name: String in names:
		var index: int = clip_option.get_item_count()
		clip_option.add_item(clip_name.capitalize())
		clip_option.set_item_metadata(index, clip_name)
	clip_option.select(0)


func _on_clip_selected(index: int) -> void:
	_current_clip_name = str(clip_option.get_item_metadata(index))
	_apply_clip()


func _apply_clip() -> void:
	_show_diagnostics([])
	if _current_unit == null:
		return

	var animation_id: String = _current_unit.animation_id
	if _current_clip_name.is_empty() or not ContentRepository.get_clip_names(animation_id).has(_current_clip_name):
		sprite.stop()
		_show_diagnostics([
			"Missing animation metadata: %s / %s" % [animation_id, _current_clip_name]
		])
		return

	var clip: Dictionary = ContentRepository.get_animation_clip(animation_id, _current_clip_name)
	var atlas_info: Dictionary = ContentRepository.get_atlas_info()
	var atlas_width: int = int(atlas_info.get("width", 0))
	var atlas_height: int = int(atlas_info.get("height", 0))
	var diagnostics: Array[String] = AnimationValidator.validate_clip(clip, atlas_width, atlas_height)

	if not FileAccess.file_exists(_current_unit.atlas_path):
		diagnostics.append("Missing atlas texture: %s" % _current_unit.atlas_path)
	if not diagnostics.is_empty():
		sprite.stop()
		_show_diagnostics(diagnostics)
		return

	var texture: Texture2D = load(_current_unit.atlas_path) as Texture2D
	if texture == null:
		sprite.stop()
		_show_diagnostics(["Atlas texture could not be loaded: %s" % _current_unit.atlas_path])
		return

	var frames := SpriteFrames.new()
	frames.clear_all()
	frames.add_animation(_current_clip_name)
	frames.set_animation_loop(_current_clip_name, bool(clip.get("loop", false)))
	frames.set_animation_speed(_current_clip_name, float(clip.get("speed", 1.0)))

	var frame_data: Array = clip.get("frames", [])
	for frame_variant in frame_data:
		if not frame_variant is Dictionary:
			continue
		var frame: Dictionary = frame_variant
		var rect: Array = frame.get("rect", [])
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
		frames.add_frame(_current_clip_name, atlas_texture, float(frame.get("duration", 0.1)))

	sprite.sprite_frames = frames
	sprite.animation = _current_clip_name
	sprite.speed_scale = float(speed_slider.value)

	_frame_data = frame_data.duplicate(true)
	_apply_frame_offset()
	sprite.play()


func _update_info() -> void:
	if _current_unit == null:
		stats_label.text = "Stats\n- none"
		abilities_label.text = "Abilities\n- none"
		provenance_label.text = "Provenance\n- none"
		return

	var keys: Array = _current_unit.stats.keys()
	keys.sort()
	var stat_lines: Array[String] = []
	for key in keys:
		stat_lines.append("- %s: %s" % [str(key), str(_current_unit.stats[key])])
	stats_label.text = "Stats (%s)\n%s" % [_current_unit.display_id(), _join_lines(stat_lines)]

	var ability_lines: Array[String] = []
	for ability in _current_unit.abilities:
		if ability is Dictionary:
			ability_lines.append("- %s" % str(ability.get("name", "unknown")))
	abilities_label.text = "Abilities\n%s" % _join_lines(ability_lines)

	provenance_label.text = "Provenance\n- status: %s\n- source: %s\n- license: %s" % [
		_current_unit.verification_status,
		str(_current_unit.provenance.get("source", "unknown")),
		str(_current_unit.provenance.get("license", "unknown"))
	]


func _toggle_playback() -> void:
	if sprite.is_playing():
		sprite.stop()
	else:
		sprite.play()


func _restart_animation() -> void:
	sprite.stop()
	sprite.play()


func _on_speed_changed(value: float) -> void:
	sprite.speed_scale = value
	speed_label.text = "Speed: %.2fx" % value


func _layout_sprite() -> void:
	sprite.position = sprite_area.size * 0.5


## Applies origin centering and the frame's declared pixel offset together.
## AnimatedSprite2D has one offset property, so this runs on every frame change.
func _apply_frame_offset() -> void:
	var frame_index: int = sprite.frame
	if frame_index < 0 or frame_index >= _frame_data.size():
		return
	var frame_variant: Variant = _frame_data[frame_index]
	if not frame_variant is Dictionary:
		return
	var frame: Dictionary = frame_variant
	var rect: Array = frame.get("rect", [0, 0, 32, 32])
	var offset: Array = frame.get("offset", [0, 0])
	var origin: Array = frame.get("origin", [0.5, 0.5])
	sprite.offset = Vector2(
		-float(rect[2]) * float(origin[0]) + float(offset[0]),
		-float(rect[3]) * float(origin[1]) + float(offset[1])
	)


func _show_diagnostics(messages: Array[String]) -> void:
	if messages.is_empty():
		diagnostics_label.text = "Diagnostics: none"
		return
	var text: String = "Diagnostics:\n"
	for message: String in messages:
		text += "- " + message + "\n"
	diagnostics_label.text = text


func _join_lines(lines: Array[String]) -> String:
	if lines.is_empty():
		return "- none"
	var text: String = ""
	for line: String in lines:
		text += line + "\n"
	return text.substr(0, maxi(text.length() - 1, 0))


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
