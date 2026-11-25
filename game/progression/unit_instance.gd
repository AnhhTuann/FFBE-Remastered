class_name UnitInstance
extends RefCounted

## Mutable owned copy of a unit. Instance IDs are serial-based; display names are
## never keys. Multiple copies of the same definition remain distinct.

var instance_id: String = ""
var definition_id: String = ""
var base_id: String = ""
var region: String = ""
var native_id: String = ""
var form: String = "base"
var serial: int = 0
var level: int = 1
var exp: int = 0
var star: int = 5
var ex_level: int = 0
var nv_unlocked: bool = false
var nv_plus: bool = false
var trust: int = 0
var tmr_claimed: bool = false
var stmr_claimed: bool = false
var favorite: bool = false
var locked: bool = false
var equipped: Dictionary = {}
var pot_allocations: Dictionary = {}
var learned_abilities: Array[String] = []
var awakened_abilities: Array[String] = []
var source: String = ""


static func from_dict(data: Dictionary) -> UnitInstance:
	var result := UnitInstance.new()
	result.instance_id = str(data.get("instance_id", ""))
	result.definition_id = str(data.get("definition_id", ""))
	result.base_id = str(data.get("base_id", ""))
	result.region = str(data.get("region", "")).to_upper()
	result.native_id = str(data.get("native_id", ""))
	result.form = str(data.get("form", "base")).to_lower()
	result.serial = int(data.get("serial", 0))
	result.level = maxi(int(data.get("level", 1)), 1)
	result.exp = maxi(int(data.get("exp", 0)), 0)
	result.star = maxi(int(data.get("star", 5)), 1)
	result.ex_level = clampi(int(data.get("ex_level", 0)), 0, 3)
	result.nv_unlocked = bool(data.get("nv_unlocked", false))
	result.nv_plus = bool(data.get("nv_plus", false))
	result.trust = maxi(int(data.get("trust", 0)), 0)
	result.tmr_claimed = bool(data.get("tmr_claimed", false))
	result.stmr_claimed = bool(data.get("stmr_claimed", false))
	result.favorite = bool(data.get("favorite", false))
	result.locked = bool(data.get("locked", false))
	var equipped_variant: Variant = data.get("equipped", {})
	result.equipped = equipped_variant.duplicate(true) if equipped_variant is Dictionary else {}
	var pots_variant: Variant = data.get("pot_allocations", {})
	result.pot_allocations = pots_variant.duplicate(true) if pots_variant is Dictionary else {}
	for ability_id: Variant in data.get("learned_abilities", []):
		result.learned_abilities.append(str(ability_id))
	for ability_id: Variant in data.get("awakened_abilities", []):
		result.awakened_abilities.append(str(ability_id))
	result.source = str(data.get("source", ""))
	return result


func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"base_id": base_id,
		"region": region,
		"native_id": native_id,
		"form": form,
		"serial": serial,
		"level": level,
		"exp": exp,
		"star": star,
		"ex_level": ex_level,
		"nv_unlocked": nv_unlocked,
		"nv_plus": nv_plus,
		"trust": trust,
		"tmr_claimed": tmr_claimed,
		"stmr_claimed": stmr_claimed,
		"favorite": favorite,
		"locked": locked,
		"equipped": equipped.duplicate(true),
		"pot_allocations": pot_allocations.duplicate(true),
		"learned_abilities": learned_abilities.duplicate(),
		"awakened_abilities": awakened_abilities.duplicate(),
		"source": source
	}


func copies_equipment(uid: String) -> bool:
	for slot: String in equipped.keys():
		if str(equipped[slot]) == uid:
			return true
	return false


func is_equipped() -> bool:
	return not equipped.is_empty()
