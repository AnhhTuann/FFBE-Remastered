class_name BattleResult
extends RefCounted

## Outcome and reward snapshot. Contains plain data only, saveable by SaveManager.

var encounter_id: String = ""
var encounter_name: String = ""
var victory: bool = false
var outcome: String = "pending"
var turns: int = 0
var seed: int = 0
var boss: bool = false
var rewards: Dictionary = {}
var defeated_enemies: Array[String] = []


func to_dict() -> Dictionary:
	return {
		"encounter_id": encounter_id,
		"encounter_name": encounter_name,
		"victory": victory,
		"outcome": outcome,
		"turns": turns,
		"seed": seed,
		"boss": boss,
		"rewards": rewards.duplicate(true),
		"defeated_enemies": defeated_enemies.duplicate()
	}
