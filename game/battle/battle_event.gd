class_name BattleEvent
extends RefCounted

## Explicit, JSON-serializable record consumed by UI, tests and persistence.

var frame: int = 0
var type: String = ""
var payload: Dictionary = {}


func _init(p_frame: int = 0, p_type: String = "", p_payload: Dictionary = {}) -> void:
	frame = p_frame
	type = p_type
	payload = p_payload.duplicate(true)


func to_dict() -> Dictionary:
	return {
		"frame": frame,
		"type": type,
		"data": payload.duplicate(true)
	}
