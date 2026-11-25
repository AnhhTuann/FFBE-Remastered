class_name DamageCalculator
extends RefCounted

## Traceable physical and magical damage. The structure follows the documented FFBE
## factors; equipment systems, killers, critical hits and hybrid damage are absent and
## therefore never claimed. All synthetic fixtures use authored weapon variance.

var element_resolver: ElementResolver = ElementResolver.new()


func calculate(
	attacker: CombatantState,
	target: CombatantState,
	ability: Dictionary,
	hit: Dictionary,
	chain_bonus: float,
	rng: BattleRNG
) -> Dictionary:
	if attacker == null or target == null or not target.is_alive():
		return _unsupported("target_unavailable", "No living target")

	var kind: String = str(ability.get("kind", ""))
	if kind != "physical" and kind != "magical":
		return _unsupported("unsupported_damage_kind", "Unsupported damage kind: %s" % kind)

	var offensive_stat: int = 0
	var defensive_stat: int = 0
	var offensive_name: String = ""
	var defensive_name: String = ""
	if kind == "physical":
		offensive_name = "atk"
		defensive_name = "def"
	else:
		offensive_name = "mag"
		defensive_name = "spr"
	offensive_stat = attacker.effective_stat(offensive_name)
	var ignore_percent: float = float(ability.get("ignore_def", 0))
	defensive_stat = int(round(float(target.effective_stat(defensive_name)) * (1.0 - ignore_percent / 100.0)))

	var modifier: float = float(ability.get("modifier", 1.0)) * float(hit.get("weight", 1.0))
	var level_correction: float = 1.0 + float(attacker.level) / 100.0
	var variance_low: float = float(attacker.weapon_variance[0])
	var variance_high: float = float(attacker.weapon_variance[1])
	var weapon_variance: float = rng.range_float(variance_low, variance_high)
	var final_variance: float = float(rng.range_int(85, 100)) / 100.0
	var guard_multiplier: float = 0.5 if target.guard else 1.0

	var elements: Array[String] = []
	var hit_element: String = str(hit.get("element", ""))
	if not hit_element.is_empty():
		elements.append(hit_element)
	var ability_elements_variant: Variant = ability.get("elements", [])
	if ability_elements_variant is Array:
		for element_variant: Variant in ability_elements_variant:
			var element: String = str(element_variant)
			if not elements.has(element):
				elements.append(element)
	var resistance: float = ElementResolver.multiplier(elements, target)

	var base: float = float(offensive_stat * offensive_stat) / float(maxi(defensive_stat, 1))
	var amount: int = maxi(int(floor(
		base * modifier * level_correction * weapon_variance * final_variance
		* maxf(chain_bonus, 1.0) * resistance * guard_multiplier
	)), 1)

	return {
		"ok": true,
		"kind": kind,
		"amount": amount,
		"breakdown": {
			"offensive_stat": offensive_name,
			"offensive_value": offensive_stat,
			"defensive_stat": defensive_name,
			"defensive_value": defensive_stat,
			"modifier": modifier,
			"level_correction": level_correction,
			"weapon_variance": weapon_variance,
			"final_variance": final_variance,
			"chain_bonus": chain_bonus,
			"element_multiplier": resistance,
			"guard_multiplier": guard_multiplier,
			"elements": elements
		}
	}


func _unsupported(reason: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"reason": reason,
		"message": message,
		"amount": 0,
		"breakdown": {}
	}
