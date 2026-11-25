class_name EnemyAI
extends RefCounted

## Deterministic, data-driven enemy decisions. Patterns and cooldowns are fixture data;
## no reconstructed FFBE AI tables are claimed.

var cooldowns: Dictionary = {}


func decide_actions(enemy: CombatantState, state: BattleState, rng: BattleRNG, current_frame: int) -> Array[BattleAction]:
	var actions: Array[BattleAction] = []
	if enemy == null or not enemy.is_alive():
		return actions

	_tick_cooldowns(enemy.id)
	var ai: Dictionary = _ai_definition(enemy)
	var max_actions: int = maxi(int(ai.get("max_actions", 1)), 1)
	var start_frames: Array = ai.get("action_start_frames", [4])
	var pattern: Array = ai.get("pattern", [])
	var used_abilities: Array[String] = []

	for action_index: int in range(max_actions):
		var ability_id: String = _choose_ability(enemy, pattern, used_abilities, rng)
		if ability_id.is_empty():
			break
		used_abilities.append(ability_id)
		var ability: Dictionary = {}
		var candidate: Variant = state.ability_defs.get(ability_id, {})
		if candidate is Dictionary:
			ability = candidate
		var rule: String = _target_rule_for(pattern, ability_id)
		var action := BattleAction.new()
		action.actor_id = enemy.id
		action.ability_id = ability_id
		action.source_type = "ability"
		action.targeting = str(ability.get("targeting", "enemy"))
		action.target_ids = _choose_targets(rule, state, rng)
		action.start_frame = int(start_frames[mini(action_index, start_frames.size() - 1)]) if not start_frames.is_empty() else current_frame + 4 * (action_index + 1)
		action.label = str(ability.get("name", ability_id))
		actions.append(action)

		var cooldown: int = _cooldown_for(pattern, ability_id)
		if cooldown > 0:
			cooldowns["%s:%s" % [enemy.id, ability_id]] = cooldown
	return actions


func reset() -> void:
	cooldowns.clear()


func _ai_definition(enemy: CombatantState) -> Dictionary:
	var definition_variant: Variant = enemy.definition_data.get("ai", {})
	return definition_variant if definition_variant is Dictionary else {}


func _tick_cooldowns(enemy_id: String) -> void:
	for key: String in cooldowns.keys():
		if not key.begins_with(enemy_id + ":"):
			continue
		cooldowns[key] = maxi(int(cooldowns[key]) - 1, 0)


func _choose_ability(enemy: CombatantState, pattern: Array, used: Array[String], rng: BattleRNG) -> String:
	var hp_percent: float = enemy.hp_percent()
	var total_weight: int = 0
	var options: Array[Dictionary] = []
	for entry_variant: Variant in pattern:
		if not entry_variant is Dictionary:
			continue
		var entry: Dictionary = entry_variant
		var ability_id: String = str(entry.get("ability", ""))
		if ability_id.is_empty() or used.has(ability_id):
			continue
		if int(cooldowns.get("%s:%s" % [enemy.id, ability_id], 0)) > 0:
			continue
		if hp_percent < float(entry.get("min_hp_percent", 0)) or hp_percent > float(entry.get("max_hp_percent", 100)):
			continue
		var weight: int = maxi(int(entry.get("weight", 1)), 0)
		if weight <= 0:
			continue
		options.append(entry)
		total_weight += weight

	if options.is_empty():
		return enemy.basic_attack
	var roll: int = rng.range_int(1, total_weight)
	var cursor: int = 0
	for entry: Dictionary in options:
		cursor += maxi(int(entry.get("weight", 1)), 0)
		if roll <= cursor:
			return str(entry.get("ability", ""))
	return str(options[options.size() - 1].get("ability", ""))


func _target_rule_for(pattern: Array, ability_id: String) -> String:
	for entry_variant: Variant in pattern:
		if entry_variant is Dictionary and str((entry_variant as Dictionary).get("ability", "")) == ability_id:
			return str((entry_variant as Dictionary).get("target_rule", "random"))
	return "random"


func _choose_targets(rule: String, state: BattleState, rng: BattleRNG) -> Array[String]:
	var alive: Array[CombatantState] = state.alive_party()
	if alive.is_empty():
		return []
	if rule == "all_allies":
		return _ids(state.alive_enemies())
	if rule == "all_enemies":
		return _ids(alive)
	if rule == "lowest_hp":
		alive.sort_custom(func(left: CombatantState, right: CombatantState) -> bool: return left.hp < right.hp)
		return [alive[0].id]
	if rule == "highest_atk":
		alive.sort_custom(func(left: CombatantState, right: CombatantState) -> bool: return left.effective_stat("atk") > right.effective_stat("atk"))
		return [alive[0].id]
	return [alive[rng.range_int(0, alive.size() - 1)].id]


func _cooldown_for(pattern: Array, ability_id: String) -> int:
	for entry_variant: Variant in pattern:
		if entry_variant is Dictionary and str((entry_variant as Dictionary).get("ability", "")) == ability_id:
			return int((entry_variant as Dictionary).get("cooldown", 0))
	return 0


func _ids(combatants: Array[CombatantState]) -> Array[String]:
	var result: Array[String] = []
	for combatant: CombatantState in combatants:
		result.append(combatant.id)
	return result
