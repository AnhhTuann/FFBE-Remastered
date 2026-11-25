class_name CombatantState
extends RefCounted

## Mutable battle state for one combatant. The immutable content definition is copied,
## never modified, so fixtures can be reused across battles and tests.

var id: String = ""
var definition_id: String = ""
var definition_data: Dictionary = {}
var display_name: String = ""
var side: String = ""
var role: String = ""
var level: int = 1
var base_stats: Dictionary = {}
var resist: Dictionary = {}
var weapon_variance: Array = [1.0, 1.0]
var abilities: Array[String] = []
var basic_attack: String = ""
var limit_ability: String = ""
var animation_id: String = ""
var lb_cost: int = 12
var lb_gauge: int = 0
var hp: int = 1
var mp: int = 0
var max_hp: int = 1
var max_mp: int = 0
var guard: bool = false
var statuses: Dictionary = {}


static func from_definition(definition: Dictionary, p_side: String) -> CombatantState:
	var result := CombatantState.new()
	result.definition_id = str(definition.get("id", ""))
	result.definition_data = definition.duplicate(true)
	result.id = result.definition_id
	result.display_name = str(definition.get("display_name", result.id))
	result.side = p_side
	result.role = str(definition.get("role", "unknown"))
	result.level = int(definition.get("level", 1))

	var stats_variant: Variant = definition.get("stats", {})
	if stats_variant is Dictionary:
		result.base_stats = (stats_variant as Dictionary).duplicate(true)
	var resist_variant: Variant = definition.get("resist", {})
	if resist_variant is Dictionary:
		result.resist = (resist_variant as Dictionary).duplicate(true)
	var variance_variant: Variant = definition.get("weapon_variance", [1.0, 1.0])
	if variance_variant is Array and (variance_variant as Array).size() >= 2:
		result.weapon_variance = (variance_variant as Array).duplicate()

	var abilities_variant: Variant = definition.get("abilities", [])
	if abilities_variant is Array:
		for ability_id in abilities_variant:
			result.abilities.append(str(ability_id))
	result.basic_attack = str(definition.get("basic_attack", ""))
	result.limit_ability = str(definition.get("limit_burst", ""))
	result.animation_id = str(definition.get("animation_id", ""))
	result.lb_cost = maxi(int(definition.get("lb_cost", 12)), 1)

	result.max_hp = maxi(int(result.base_stats.get("hp", 1)), 1)
	result.max_mp = maxi(int(result.base_stats.get("mp", 0)), 0)
	result.hp = result.max_hp
	result.mp = result.max_mp
	return result


func is_alive() -> bool:
	return hp > 0


func hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp) * 100.0


func effective_stat(stat_name: String) -> int:
	var value: float = float(int(base_stats.get(stat_name, 0)))
	var buff_percent: int = 0
	var break_percent: int = 0
	for entry_variant: Variant in statuses.values():
		if not entry_variant is Dictionary:
			continue
		var entry: Dictionary = entry_variant
		var kind: String = str(entry.get("kind", ""))
		if kind == "buff" and str(entry.get("stat", "")) == stat_name:
			buff_percent = maxi(buff_percent, int(entry.get("potency", 0)))
		elif kind == "break" and str(entry.get("stat", "")) == stat_name:
			break_percent = maxi(break_percent, int(entry.get("potency", 0)))
	value *= 1.0 + float(buff_percent - break_percent) / 100.0
	if has_status("status:disease"):
		value *= 0.9
	return maxi(int(round(value)), 0)


func has_status(key: String) -> bool:
	return statuses.has(key)


func add_status(key: String, entry: Dictionary) -> bool:
	## Strongest active effect of the same kind replaces the old one; equal refreshes.
	if statuses.has(key):
		var existing: Dictionary = statuses[key]
		if int(entry.get("potency", 0)) < int(existing.get("potency", 0)):
			return false
		existing.merge(entry, true)
		statuses[key] = existing
		return true
	statuses[key] = entry.duplicate(true)
	return true


func remove_status(key: String) -> void:
	statuses.erase(key)


func take_damage(amount: int) -> int:
	var applied: int = mini(maxi(amount, 0), hp)
	hp -= applied
	return applied


func restore_hp(amount: int) -> int:
	if not is_alive():
		return 0
	var applied: int = mini(maxi(amount, 0), max_hp - hp)
	hp += applied
	return applied


func spend_mp(amount: int) -> bool:
	if mp < amount:
		return false
	mp -= amount
	return true


func restore_mp(amount: int) -> int:
	var applied: int = mini(maxi(amount, 0), max_mp - mp)
	mp += applied
	return applied


func add_lb(amount: int) -> int:
	var before: int = lb_gauge
	lb_gauge = mini(lb_gauge + maxi(amount, 0), lb_cost)
	return lb_gauge - before


func lb_ready() -> bool:
	return lb_gauge >= lb_cost and is_alive()


func reset_turn_flags() -> void:
	guard = false


func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"side": side,
		"role": role,
		"level": level,
		"hp": hp,
		"max_hp": max_hp,
		"mp": mp,
		"max_mp": max_mp,
		"lb_gauge": lb_gauge,
		"lb_cost": lb_cost,
		"guard": guard,
		"alive": is_alive(),
		"statuses": statuses.duplicate(true),
		"effective": {
			"atk": effective_stat("atk"),
			"def": effective_stat("def"),
			"mag": effective_stat("mag"),
			"spr": effective_stat("spr")
		}
	}
