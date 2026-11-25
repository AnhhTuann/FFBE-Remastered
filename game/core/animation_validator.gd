class_name AnimationValidator
extends RefCounted

## Validates atlas frame metadata before it reaches AnimatedSprite2D.
## Repeated or non-monotonic frame IDs are allowed: source animations may hold
## or oscillate between frames. Rectangle, timing, origin and loop data are not.

static func validate_clip(clip: Dictionary, atlas_width: int, atlas_height: int) -> Array[String]:
	var diagnostics: Array[String] = []

	if clip.is_empty():
		diagnostics.append("clip is empty")
		return diagnostics

	if not clip.has("frames"):
		diagnostics.append("missing frames")
		return diagnostics

	var frames_variant: Variant = clip.get("frames")
	if not frames_variant is Array:
		diagnostics.append("frames is not an array")
		return diagnostics

	var frames: Array = frames_variant
	if frames.is_empty():
		diagnostics.append("frames array is empty")
		return diagnostics

	if not clip.has("loop") or not (clip.get("loop") is bool):
		diagnostics.append("missing or invalid loop flag")

	if clip.has("speed"):
		var speed_value: Variant = clip.get("speed")
		if not _is_number(speed_value) or not is_finite(float(speed_value)) or float(speed_value) <= 0.0:
			diagnostics.append("speed must be a positive finite number")

	for index in range(frames.size()):
		var frame_variant: Variant = frames[index]
		var prefix: String = "frame[%d]" % index
		if not frame_variant is Dictionary:
			diagnostics.append(prefix + " is not a dictionary")
			continue

		var frame: Dictionary = frame_variant
		var frame_id: Variant = frame.get("frame_id", null)
		if not _is_number(frame_id):
			diagnostics.append(prefix + " has invalid frame_id")

		var rect: Array[float] = _read_number_array(frame, "rect", 4, prefix, diagnostics)
		if rect.size() == 4:
			var x: int = int(rect[0])
			var y: int = int(rect[1])
			var width: int = int(rect[2])
			var height: int = int(rect[3])
			if width <= 0 or height <= 0:
				diagnostics.append(prefix + " rect dimensions must be positive")
			elif x < 0 or y < 0 or x + width > atlas_width or y + height > atlas_height:
				diagnostics.append(prefix + " rect is outside atlas bounds")

		_read_number_array(frame, "offset", 2, prefix, diagnostics)
		var origin: Array[float] = _read_number_array(frame, "origin", 2, prefix, diagnostics)
		if origin.size() == 2:
			if origin[0] < 0.0 or origin[0] > 1.0 or origin[1] < 0.0 or origin[1] > 1.0:
				diagnostics.append(prefix + " origin must be normalized to 0..1")

		var duration: Variant = frame.get("duration", null)
		if not _is_number(duration) or not is_finite(float(duration)) or float(duration) <= 0.0:
			diagnostics.append(prefix + " duration must be a positive finite number")

	return diagnostics


static func _read_number_array(
	frame: Dictionary,
	key: String,
	expected_size: int,
	prefix: String,
	diagnostics: Array[String]
) -> Array[float]:
	var result: Array[float] = []
	if not frame.has(key):
		diagnostics.append(prefix + " missing " + key)
		return result

	var value: Variant = frame.get(key)
	if not value is Array:
		diagnostics.append(prefix + " " + key + " is not an array")
		return result

	var values: Array = value
	if values.size() != expected_size:
		diagnostics.append(prefix + " " + key + " must contain %d values" % expected_size)
		return result

	for item in values:
		if not _is_number(item) or not is_finite(float(item)):
			diagnostics.append(prefix + " " + key + " contains a non-finite value")
			return result
		result.append(float(item))

	return result


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
