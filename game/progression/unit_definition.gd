class_name UnitDefinition
extends RefCounted

## Immutable, region-aware unit/form definition. Player-owned mutable state lives
## in UnitInstance and is never stored on this object.

var id: String = ""
var base_id: String = ""
var region: String = ""
var native_id: String = ""
var form: String = "base"
var name_key: String = ""
var role: String = ""
var roles: Array[String] = []
var categories: Array[String] = []
var element: String = ""
var limited: bool = false
var verification_status: String = "UNVERIFIED"
var provenance: Dictionary = {}
var rarity: int = 0
var level_caps: Dictionary = {}
var base_stats: Dictionary = {}
var growth_per_level: Dictionary = {}
var pot_caps: Dictionary = {}
var awakening: Dictionary = {}
var nv: Dictionary = {}
var ex: Dictionary = {}
var nv_plus: Dictionary = {}
var trust: Dictionary = {}
var duplicate_fragments: int = 0
var abilities: Array = []
var passive_abilities: Array = []
var leader_skill: Dictionary = {}
var super_lb: Dictionary = {}
var overdrive: Dictionary = {}
var shift: Dictionary = {}
var mechanic_labels: Dictionary = {}


static func from_dict(data: Dictionary) -> UnitDefinition:
	var result := UnitDefinition.new()
	result.id = str(data.get("id", ""))
	result.base_id = str(data.get("base_id", result.id))
	result.region = str(data.get("region", "")).to_upper()
	result.native_id = str(data.get("native_id", ""))
	result.form = str(data.get("form", "base")).to_lower()
	result.name_key = str(data.get("name_key", ""))
	result.role = str(data.get("role", ""))
	for value: Variant in data.get("roles", []):
		result.roles.append(str(value))
	for value: Variant in data.get("categories", []):
		result.categories.append(str(value))
	result.element = str(data.get("element", ""))
	result.limited = bool(data.get("limited", false))
	result.verification_status = str(data.get("verification_status", "UNVERIFIED"))
	var provenance_variant: Variant = data.get("provenance", {})
	result.provenance = provenance_variant.duplicate(true) if provenance_variant is Dictionary else {}
	result.rarity = int(data.get("rarity", 0))
	result.level_caps = _copy_dict(data.get("level_caps", {}))
	result.base_stats = _copy_dict(data.get("base_stats", {}))
	result.growth_per_level = _copy_dict(data.get("growth_per_level", {}))
	result.pot_caps = _copy_dict(data.get("pot_caps", {}))
	result.awakening = _copy_dict(data.get("awakening", {}))
	result.nv = _copy_dict(data.get("nv", {}))
	result.ex = _copy_dict(data.get("ex", {}))
	result.nv_plus = _copy_dict(data.get("nv_plus", {}))
	result.trust = _copy_dict(data.get("trust", {}))
	result.duplicate_fragments = maxi(int(data.get("duplicate_fragments", 0)), 0)
	var abilities_variant: Variant = data.get("abilities", [])
	if abilities_variant is Array:
		result.abilities = (abilities_variant as Array).duplicate(true)
	var passives_variant: Variant = data.get("passive_abilities", [])
	if passives_variant is Array:
		result.passive_abilities = (passives_variant as Array).duplicate(true)
	result.leader_skill = _copy_dict(data.get("leader_skill", {}))
	result.super_lb = _copy_dict(data.get("super_lb", {}))
	result.overdrive = _copy_dict(data.get("overdrive", {}))
	result.shift = _copy_dict(data.get("shift", {}))
	result.mechanic_labels = _copy_dict(data.get("mechanic_labels", {}))
	return result


func is_valid() -> bool:
	return not id.is_empty() and (region == "GL" or region == "JP") and not native_id.is_empty() and not base_stats.is_empty()


func level_cap(star: int, ex_level: int = 0) -> int:
	if ex_level > 0 and level_caps.has("nv"):
		return int(level_caps["nv"])
	var keys: Array[String] = [str(star), "nv"]
	for key: String in keys:
		if level_caps.has(key):
			return int(level_caps[key])
	return 1


func stats_at_level(level: int) -> Dictionary:
	var result: Dictionary = {}
	for stat: String in base_stats.keys():
		var growth: int = int(growth_per_level.get(stat, 0))
		result[stat] = maxi(int(base_stats[stat]) + growth * maxi(level - 1, 0), 0)
	return result


func pot_cap(stat: String) -> int:
	return maxi(int(pot_caps.get(stat, 0)), 0)


static func _copy_dict(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}
