class_name BattleState
extends RefCounted

## Complete mutable battle snapshot. No node, scene, animation or UI reference is stored here.

var encounter_id: String = ""
var encounter_name: String = ""
var ability_defs: Dictionary = {}
var boss: bool = false
var seed: int = 1
var turn: int = 0
var phase: String = "idle"
var party: Array[CombatantState] = []
var enemies: Array[CombatantState] = []
var events: Array[Dictionary] = []
var log: Array[String] = []
var chain_count: int = 0
var chain_modifier: int = 0
var result: BattleResult = null


func find_combatant(combatant_id: String) -> CombatantState:
	for combatant: CombatantState in party:
		if combatant.id == combatant_id:
			return combatant
	for combatant: CombatantState in enemies:
		if combatant.id == combatant_id:
			return combatant
	return null


func alive_party() -> Array[CombatantState]:
	var result_array: Array[CombatantState] = []
	for combatant: CombatantState in party:
		if combatant.is_alive():
			result_array.append(combatant)
	return result_array


func alive_enemies() -> Array[CombatantState]:
	var result_array: Array[CombatantState] = []
	for combatant: CombatantState in enemies:
		if combatant.is_alive():
			result_array.append(combatant)
	return result_array


func add_event(event: Dictionary) -> void:
	events.append(event.duplicate(true))
	var event_type: String = str(event.get("type", "event"))
	var data: Dictionary = event.get("data", {})
	var message: String = str(data.get("message", ""))
	if not message.is_empty():
		log.append("[%d] %s: %s" % [int(event.get("frame", 0)), event_type, message])


func snapshot() -> Dictionary:
	var party_data: Array[Dictionary] = []
	var enemy_data: Array[Dictionary] = []
	for combatant: CombatantState in party:
		party_data.append(combatant.to_dict())
	for combatant: CombatantState in enemies:
		enemy_data.append(combatant.to_dict())
	return {
		"encounter_id": encounter_id,
		"encounter_name": encounter_name,
		"boss": boss,
		"seed": seed,
		"turn": turn,
		"phase": phase,
		"chain_count": chain_count,
		"chain_modifier": chain_modifier,
		"party": party_data,
		"enemies": enemy_data,
		"result": result.to_dict() if result != null else {},
		"event_count": events.size()
	}
