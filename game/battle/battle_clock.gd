class_name BattleClock
extends RefCounted

## Logical 60 Hz battle clock. Presentation speed never changes simulation frames.

signal advanced(frame: int)

var frame: int = 0


func reset() -> void:
	frame = 0
	advanced.emit(frame)


func advance_frames(count: int) -> int:
	if count <= 0:
		return frame
	frame += count
	advanced.emit(frame)
	return frame


func set_frame(value: int) -> void:
	frame = maxi(value, 0)
	advanced.emit(frame)
