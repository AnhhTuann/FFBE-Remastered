class_name BattleResult
extends RefCounted

## Outcome and reward snapshot. Contains plain data only, saveable by SaveManager.
## `run_id` is the unique identity of one battle attempt. It keeps repeatable
## rewards independent from encounter/seed/turn snapshots. `seed_source` records
## whether the RNG seed came from an independent attempt or a QA override.

var encounter_id: String = ""
var encounter_name: String = ""
var victory: bool = false
var outcome: String = "pending"
var turns: int = 0
var seed: int = 0
var seed_source: String = "independent"
var run_id: String = ""
var boss: bool = false
var one_time: bool = false
var rewards: Dictionary = {}
var reward_policy: Dictionary = {}
var defeated_enemies: Array[String] = []


func to_dict() -> Dictionary:
	return {
		"encounter_id": encounter_id,
		"encounter_name": encounter_name,
		"victory": victory,
		"outcome": outcome,
		"turns": turns,
		"seed": seed,
		"seed_source": seed_source,
		"run_id": run_id,
		"boss": boss,
		"one_time": one_time,
		"rewards": rewards.duplicate(true),
		"reward_policy": reward_policy.duplicate(true),
		"defeated_enemies": defeated_enemies.duplicate()
	}
