class_name BattleSprite
extends AnimatedSprite2D

## Battle presentation adapter over the validated synthetic animation pipeline.
## Frame offsets, origins, loop flags and clip speed come from ContentRepository data.

var animation_id: String = ""
var frame_data: Array = []
var alias_map: Dictionary = {}


func setup(p_animation_id: String, modulation: Color) -> bool:
	animation_id = p_animation_id
	var package: Dictionary = ContentRepository.get_battle_package()
	var policy: Dictionary = package.get("animation_policy", {})
	var aliases_variant: Variant = policy.get("aliases", {})
	if aliases_variant is Dictionary:
		alias_map = (aliases_variant as Dictionary).duplicate()

	var clip_names: Array[String] = ContentRepository.get_clip_names(animation_id)
	if clip_names.is_empty():
		return false
	var atlas_info: Dictionary = ContentRepository.get_atlas_info()
	var texture: Texture2D = load(str(atlas_info.get("path", ""))) as Texture2D
	if texture == null:
		return false

	var frames := SpriteFrames.new()
	frames.clear_all()
	for clip_name: String in clip_names:
		var clip: Dictionary = ContentRepository.get_animation_clip(animation_id, clip_name)
		var diagnostics: Array = AnimationValidator.validate_clip(
			clip, int(atlas_info.get("width", 0)), int(atlas_info.get("height", 0))
		)
		if not diagnostics.is_empty():
			continue
		frames.add_animation(clip_name)
		frames.set_animation_loop(clip_name, bool(clip.get("loop", false)))
		frames.set_animation_speed(clip_name, float(clip.get("speed", 1.0)))
		for frame_variant: Variant in clip.get("frames", []):
			if not frame_variant is Dictionary:
				continue
			var frame: Dictionary = frame_variant
			var rect: Array = frame.get("rect", [0, 0, 32, 32])
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = texture
			atlas_texture.region = Rect2(
				float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3])
			)
			frames.add_frame(clip_name, atlas_texture, float(frame.get("duration", 0.1)))

	if frames.get_animation_names().is_empty():
		return false
	sprite_frames = frames
	animation = "idle" if frames.has_animation("idle") else frames.get_animation_names()[0]
	var initial_clip: Dictionary = ContentRepository.get_animation_clip(animation_id, animation)
	var frames_variant: Variant = initial_clip.get("frames", [])
	if frames_variant is Array:
		for frame_variant: Variant in frames_variant:
			if frame_variant is Dictionary:
				frame_data.append((frame_variant as Dictionary).duplicate(true))
	modulate = modulation
	centered = true
	scale = Vector2(2.0, 2.0)
	texture_filter = TEXTURE_FILTER_NEAREST
	if not frame_changed.is_connected(_apply_frame_offset):
		frame_changed.connect(_apply_frame_offset)
	_apply_frame_offset()
	play()
	return true


func play_clip(clip_name: String) -> void:
	if sprite_frames == null:
		return
	var resolved: String = clip_name
	if not sprite_frames.has_animation(resolved) and alias_map.has(resolved):
		resolved = str(alias_map[resolved])
	if not sprite_frames.has_animation(resolved):
		resolved = "idle" if sprite_frames.has_animation("idle") else str(sprite_frames.get_animation_names()[0])
	frame_data = []
	var clip: Dictionary = ContentRepository.get_animation_clip(animation_id, resolved)
	var frames_variant: Variant = clip.get("frames", [])
	if frames_variant is Array:
		for frame_variant: Variant in frames_variant:
			if frame_variant is Dictionary:
				frame_data.append((frame_variant as Dictionary).duplicate(true))
	animation = resolved
	play()
	_apply_frame_offset()


func _apply_frame_offset() -> void:
	if sprite_frames == null or frame < 0 or frame >= frame_data.size():
		return
	var frame_variant: Variant = frame_data[frame]
	if not frame_variant is Dictionary:
		return
	var frame_info: Dictionary = frame_variant
	var rect: Array = frame_info.get("rect", [0, 0, 32, 32])
	var offset_data: Array = frame_info.get("offset", [0, 0])
	var origin: Array = frame_info.get("origin", [0.5, 0.5])
	offset = Vector2(
		-float(rect[2]) * float(origin[0]) + float(offset_data[0]),
		-float(rect[3]) * float(origin[1]) + float(offset_data[1])
	)
