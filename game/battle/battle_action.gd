class_name BattleAction
extends RefCounted

## A validated player or enemy command before it is expanded into timed hits.

var actor_id: String = ""
var ability_id: String = ""
var source_type: String = "ability"  # ability, item, guard
var targeting: String = ""
var target_ids: Array[String] = []
var start_frame: int = 0
var label: String = ""


func to_dict() -> Dictionary:
	return {
		"actor_id": actor_id,
		"ability_id": ability_id,
		"source_type": source_type,
		"targeting": targeting,
		"target_ids": target_ids.duplicate(),
		"start_frame": start_frame,
		"label": label
	}
