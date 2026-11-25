class_name TurnManager
extends RefCounted

## Explicit phase state machine. UI and animation never decide whose turn it is.

var turn: int = 0
var phase: String = "idle"


func start_battle() -> void:
	turn = 1
	phase = "player"


func begin_enemy_phase() -> void:
	phase = "enemy_execution"


func end_turn() -> void:
	turn += 1
	phase = "player"


func finish(outcome: String) -> void:
	phase = outcome


func is_player_input_allowed() -> bool:
	return phase == "player"


func to_dict() -> Dictionary:
	return {"turn": turn, "phase": phase}
