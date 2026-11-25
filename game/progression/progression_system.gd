class_name ProgressionSystem
extends RefCounted

## Mutable progression rules for owned unit instances. Every cost, cap and
## transition comes from the synthetic data files; no FFBE original value is
## reconstructed. Transactions roll back resources and unit state on failure.

const STATS: Array[String] = ["hp", "mp", "atk", "def", "mag", "spr"]

var state: Node = null


func _init(p_state: Node) -> void:
	state = p_state


func _rules() -> Dictionary:
	return ContentRepository.call("get_progression_rules")


func definition(instance_id: String) -> Dictionary:
	var instance: Dictionary = state.call("get_unit_instance", instance_id)
	if instance.is_empty():
		return {}
	return ContentRepository.call("get_unit_definition", str(instance.get("definition_id", "")))


func instance(instance_id: String) -> Dictionary:
	return state.call("get_unit_instance", instance_id)


func _snapshot() -> Dictionary:
	return {
		"resources": state.call("get_resources"),
		"owned_units": (state.get("data") as Dictionary).get("owned_units", []).duplicate(true)
	}


func _restore(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	var data: Dictionary = state.get("data")
	data["resources"] = snapshot.get("resources", {}).duplicate(true)
	data["owned_units"] = snapshot.get("owned_units", []).duplicate(true)
	state.set("data", data)


func _commit(section: String, snapshot: Dictionary, message: String, extras: Dictionary = {}) -> Dictionary:
	var error: Error = state.call("commit", section)
	if error != OK:
		_restore(snapshot)
		return _fail("save_failed", message)
	return _ok(message, extras)


func _ok(message: String, extras: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {"ok": true, "reason": "", "message": message}
	result.merge(extras, true)
	return result


func _fail(reason: String, message: String, extras: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {"ok": false, "reason": reason, "message": message}
	result.merge(extras, true)
	return result


func _exp_required(level: int) -> int:
	var rules: Dictionary = _rules()
	var curve: Dictionary = rules.get("exp_curve", {})
	var base: float = maxf(float(curve.get("base", 100)), 1.0)
	var multiplier: float = maxf(float(curve.get("multiplier", 1.1)), 1.0)
	var exponent: float = maxf(float(curve.get("exponent", 1.0)), 0.0)
	return maxi(int(round(base * pow(multiplier, maxf(float(level - 1), 0.0)) * pow(float(level), exponent))), 1)


func level_cap(def: Dictionary, unit: Dictionary) -> int:
	if bool(unit.get("nv_unlocked", false)):
		return maxi(int(def.get("level_caps", {}).get("nv", 120)), 1)
	var star: int = maxi(int(unit.get("star", 5)), 1)
	return maxi(int(def.get("level_caps", {}).get(str(star), 1)), 1)


func gain_exp(instance_id: String, amount: int) -> Dictionary:
	if amount <= 0:
		return _fail("invalid_amount", "gain_exp requires a positive fixture amount")
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found: %s" % instance_id)
	var def: Dictionary = ContentRepository.call("get_unit_definition", str(unit.get("definition_id", "")))
	if def.is_empty():
		return _fail("unknown_definition", "Unit definition not found")
	var snapshot: Dictionary = _snapshot()
	unit["exp"] = maxi(int(unit.get("exp", 0)) + amount, 0)
	var cap: int = level_cap(def, unit)
	var levels_gained: int = 0
	while int(unit["level"]) < cap and int(unit["exp"]) >= _exp_required(int(unit["level"])):
		unit["exp"] -= _exp_required(int(unit["level"]))
		unit["level"] = int(unit["level"]) + 1
		levels_gained += 1
	if int(unit["level"]) >= cap:
		unit["exp"] = mini(int(unit["exp"]), _exp_required(cap))
	unit["learned_abilities"] = _sync_learned(def, unit)
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not apply EXP to this unit")
	return _commit("progression", snapshot, "EXP applied", {
		"levels_gained": levels_gained,
		"level": int(unit["level"]),
		"cap_reached": int(unit["level"]) >= cap
	})


func _sync_learned(def: Dictionary, unit: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var level: int = int(unit.get("level", 1))
	var star: int = int(unit.get("star", 5))
	for ability_variant: Variant in def.get("abilities", []):
		if not ability_variant is Dictionary:
			continue
		var ability: Dictionary = ability_variant
		if level >= int(ability.get("unlock_level", 1)) and star >= int(ability.get("unlock_star", 1)):
			result.append(str(ability.get("id", "")))
	return result


func use_pot(instance_id: String, stat: String, count: int) -> Dictionary:
	if not STATS.has(stat) or count <= 0:
		return _fail("invalid_pot", "Invalid stat pot request")
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	var def: Dictionary = definition(instance_id)
	if def.is_empty():
		return _fail("unknown_definition", "Unit definition not found")
	var rules: Dictionary = _rules()
	var pot_rule_variant: Variant = rules.get("stat_pots", {}).get(stat, {})
	if not pot_rule_variant is Dictionary:
		return _fail("invalid_pot", "No pot rule for %s" % stat)
	var pot_rule: Dictionary = pot_rule_variant
	var item_id: String = str(pot_rule.get("id", ""))
	var amount_per: int = maxi(int(pot_rule.get("amount", 0)), 0)
	if item_id.is_empty() or amount_per <= 0:
		return _fail("invalid_pot", "Incomplete pot rule")
	var caps: Dictionary = def.get("pot_caps", {})
	var cap: int = maxi(int(caps.get(stat, 0)), 0)
	var allocations: Dictionary = (unit.get("pot_allocations", {}) as Dictionary).duplicate(true)
	var allocated: int = maxi(int(allocations.get(stat, 0)), 0)
	var available: int = maxi(cap - allocated, 0)
	if available <= 0:
		return _fail("pot_cap_reached", "%s pot cap reached" % stat)
	var applied: int = mini(available, amount_per * count)
	var required_items: int = ceili(float(applied) / float(amount_per))
	var cost: Dictionary = {item_id: required_items}
	if not state.call("can_pay", cost):
		return _fail("insufficient_items", "Not enough %s" % item_id)
	var snapshot: Dictionary = _snapshot()
	if not state.call("pay", cost):
		_restore(snapshot)
		return _fail("payment_failed", "Pot payment failed")
	allocations[stat] = allocated + applied
	unit["pot_allocations"] = allocations
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not apply pot")
	return _commit("progression", snapshot, "%s pot applied" % stat, {
		"stat": stat, "applied": applied, "total": allocated + applied, "cap": cap
	})


func convert_duplicate(instance_id: String) -> Dictionary:
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	if bool(unit.get("locked", false)):
		return _fail("locked", "Locked units cannot be converted")
	var equipped: Dictionary = unit.get("equipped", {})
	if not equipped.is_empty():
		return _fail("equipped", "Unequip this copy before conversion")
	var definition_id: String = str(unit.get("definition_id", ""))
	var copies: int = 0
	for entry_variant: Variant in state.call("owned_units"):
		if entry_variant is Dictionary and str((entry_variant as Dictionary).get("definition_id", "")) == definition_id:
			copies += 1
	if copies < 2:
		return _fail("not_duplicate", "Only one copy of this definition is owned")
	var def: Dictionary = ContentRepository.call("get_unit_definition", definition_id)
	var fragments: int = maxi(int(def.get("duplicate_fragments", 0)), 0)
	if fragments <= 0:
		return _fail("no_fragment_rule", "No duplicate conversion rule for this definition")
	var fragment_id: String = "fragment:%s:%s@base" % [str(unit.get("region", "GL")), str(unit.get("native_id", ""))]
	var snapshot: Dictionary = _snapshot()
	var units: Array = (state.get("data") as Dictionary).get("owned_units", []).duplicate(true)
	var kept: Array = []
	var removed: int = 0
	for entry_variant: Variant in units:
		if entry_variant is Dictionary and str((entry_variant as Dictionary).get("instance_id", "")) == instance_id and removed == 0:
			removed += 1
			continue
		kept.append(entry_variant)
	if removed == 0:
		_restore(snapshot)
		return _fail("unknown_instance", "Instance vanished during conversion")
	var data: Dictionary = state.get("data")
	data["owned_units"] = kept
	state.set("data", data)
	var resources: Dictionary = state.call("get_resources")
	resources[fragment_id] = maxi(int(resources.get(fragment_id, 0)), 0) + fragments
	data["resources"] = resources
	data["profile"]["favorites"] = _remove_from_array(data["profile"].get("favorites", []), instance_id)
	state.set("data", data)
	return _commit("progression", snapshot, "Duplicate converted to fragments", {
		"fragment_id": fragment_id, "fragments": fragments
	})


func _remove_from_array(value: Variant, removed: String) -> Array:
	var result: Array = []
	if value is Array:
		for entry: Variant in value:
			if str(entry) != removed:
				result.append(entry)
	return result


func give_trust(instance_id: String, amount: int) -> Dictionary:
	if amount <= 0:
		return _fail("invalid_amount", "Trust gain requires a positive amount")
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	var rules: Dictionary = _rules()
	var cap: int = maxi(int(rules.get("max_trust", 100)), 1)
	var snapshot: Dictionary = _snapshot()
	unit["trust"] = mini(maxi(int(unit.get("trust", 0)) + amount, 0), cap)
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not update trust")
	return _commit("progression", snapshot, "Trust increased", {
		"trust": int(unit["trust"]), "cap": cap
	})


func add_trust_from_battle(instance_ids: Array, amount: int) -> Dictionary:
	var results: Array[Dictionary] = []
	for id_variant: Variant in instance_ids:
		var result: Dictionary = give_trust(str(id_variant), amount)
		results.append(result)
	return _ok("Battle trust applied", {"results": results})


func claim_tmr(instance_id: String) -> Dictionary:
	return _claim_reward(instance_id, "tmr", "tmr_claimed")


func claim_stmr(instance_id: String) -> Dictionary:
	return _claim_reward(instance_id, "stmr", "stmr_claimed")


func _claim_reward(instance_id: String, tier: String, flag: String) -> Dictionary:
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	if bool(unit.get(flag, false)):
		return _fail("already_claimed", "%s already claimed" % tier.to_upper())
	var def: Dictionary = definition(instance_id)
	var trust: Dictionary = def.get("trust", {})
	var required: int = maxi(int(trust.get("stmr_at" if tier == "stmr" else "max", 100)), 1)
	if int(unit.get("trust", 0)) < required:
		return _fail("trust_required", "Trust %d/%d required" % [required, int(unit.get("trust", 0))])
	var reward_id: String = str(trust.get("stmr_reward" if tier == "stmr" else "tmr_reward", ""))
	if reward_id.is_empty():
		return _fail("no_reward", "No synthetic %s reward for this form" % tier.to_upper())
	if not _inventory_has_definition(reward_id):
		return _fail("missing_reward_definition", "Reward definition is not loaded: %s" % reward_id)
	var snapshot: Dictionary = _snapshot()
	unit[flag] = true
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not mark reward claimed")
	var inventory_script: Script = load("res://progression/inventory_system.gd") as Script
	var inventory: RefCounted = inventory_script.new(state) if inventory_script != null else state.get("inventory")
	var granted: Dictionary = inventory.call("grant_item", reward_id, "%s_claim" % tier)
	if not bool(granted.get("ok", false)):
		_restore(snapshot)
		return _fail("grant_failed", str(granted.get("message", "Reward grant failed")))
	return _commit("progression", snapshot, "%s claimed" % tier.to_upper(), {
		"reward_id": reward_id, "uid": str(granted.get("uid", ""))
	})


func _inventory_has_definition(reward_id: String) -> bool:
	if reward_id.begins_with("equip:"):
		return not ContentRepository.call("get_equipment_definition", reward_id).is_empty()
	if reward_id.begins_with("materia:"):
		return not ContentRepository.call("get_materia_definition", reward_id).is_empty()
	if reward_id.begins_with("vision_card:"):
		return not ContentRepository.call("get_vision_card_definition", reward_id).is_empty()
	if reward_id.begins_with("ability:"):
		return not ContentRepository.call("get_ability_reward_definition", reward_id).is_empty()
	return false


func awaken_star(instance_id: String, target_star: int) -> Dictionary:
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	var def: Dictionary = definition(instance_id)
	var awakening_variant: Variant = def.get("awakening", {})
	var awakening: Dictionary = awakening_variant if awakening_variant is Dictionary else {}
	var transition_key: String = str(target_star)
	if not awakening.has(transition_key) or not awakening.get(transition_key) is Dictionary:
		return _fail("no_transition", "No awakening transition to star %d for this form" % target_star)
	var transition: Dictionary = awakening[transition_key]
	var required_star: int = maxi(int(transition.get("requires_star", 0)), 1)
	if int(unit.get("star", 1)) != required_star:
		return _fail("requirement", "Star %d required" % required_star)
	var cost: Dictionary = _normalize_cost(transition.get("cost", {}))
	if not state.call("can_pay", cost):
		return _fail("insufficient_resources", "Awakening resources are insufficient")
	var snapshot: Dictionary = _snapshot()
	if not state.call("pay", cost):
		_restore(snapshot)
		return _fail("payment_failed", "Awakening payment failed")
	unit["star"] = target_star
	unit["learned_abilities"] = _sync_learned(def, unit)
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not apply awakening")
	return _commit("progression", snapshot, "Awakened to star %d" % target_star, {
		"star": target_star, "cost": cost
	})


func awaken_nv(instance_id: String) -> Dictionary:
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	if bool(unit.get("nv_unlocked", false)):
		return _fail("already_nv", "NV is already unlocked")
	var def: Dictionary = definition(instance_id)
	var transition: Dictionary = def.get("nv", {})
	if transition.is_empty():
		return _fail("no_transition", "This form has no NV transition")
	var required_star: int = maxi(int(transition.get("requires_star", 0)), 1)
	if int(unit.get("star", 1)) < required_star:
		return _fail("requirement", "Star %d required" % required_star)
	var cost: Dictionary = _normalize_cost(transition.get("cost", {}))
	if not state.call("can_pay", cost):
		return _fail("insufficient_resources", "NV resources are insufficient")
	var target_form: String = str(transition.get("form", ""))
	var target_def: Dictionary = ContentRepository.call("get_unit_definition", target_form)
	if target_form.is_empty() or target_def.is_empty():
		return _fail("missing_form", "NV form definition is unavailable")
	var snapshot: Dictionary = _snapshot()
	if not state.call("pay", cost):
		_restore(snapshot)
		return _fail("payment_failed", "NV payment failed")
	unit["nv_unlocked"] = true
	unit["star"] = maxi(int(unit.get("star", 1)), 7)
	unit["definition_id"] = target_form
	unit["form"] = str(target_def.get("form", "nv"))
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not apply NV awakening")
	return _commit("progression", snapshot, "NV awakening applied", {
		"form": unit["form"], "cost": cost, "label": "UNVERIFIED_RULE"
	})


func awaken_ex(instance_id: String, level: int) -> Dictionary:
	if level < 1 or level > 3:
		return _fail("invalid_ex", "EX level must be 1, 2 or 3")
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	if not bool(unit.get("nv_unlocked", false)):
		return _fail("nv_required", "NV awakening is required")
	if int(unit.get("ex_level", 0)) >= level:
		return _fail("already_unlocked", "EX +%d is already unlocked" % level)
	var def: Dictionary = definition(instance_id)
	var transition_variant: Variant = def.get("ex", {}).get(str(level), {})
	if not transition_variant is Dictionary or transition_variant.is_empty():
		return _fail("no_transition", "This form has no EX +%d transition" % level)
	var transition: Dictionary = transition_variant
	if level > 1 and int(unit.get("ex_level", 0)) != level - 1:
		return _fail("requirement", "EX +%d is required first" % (level - 1))
	var fragment_id: String = "fragment:%s:%s@base" % [str(unit.get("region", "GL")), str(unit.get("native_id", ""))]
	var cost: Dictionary = _normalize_cost(transition.get("cost", {}))
	if not cost.has(fragment_id) and int(transition.get("requires_nv", 0)) == 0:
		return _fail("invalid_cost", "EX transition has no matching fragment cost")
	if not state.call("can_pay", cost):
		return _fail("insufficient_resources", "EX resources are insufficient")
	var snapshot: Dictionary = _snapshot()
	if not state.call("pay", cost):
		_restore(snapshot)
		return _fail("payment_failed", "EX payment failed")
	unit["ex_level"] = level
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not apply EX awakening")
	return _commit("progression", snapshot, "EX +%d applied" % level, {
		"ex_level": level, "cost": cost, "label": "UNVERIFIED_RULE"
	})


func awaken_nv_plus(instance_id: String) -> Dictionary:
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	if bool(unit.get("nv_plus", false)):
		return _fail("already_nv_plus", "NV+ is already unlocked")
	if int(unit.get("ex_level", 0)) < 3:
		return _fail("requirement", "EX +3 is required")
	var def: Dictionary = definition(instance_id)
	var transition: Dictionary = def.get("nv_plus", {})
	if transition.is_empty():
		return _fail("no_transition", "This form has no NV+ transition")
	var cost: Dictionary = _normalize_cost(transition.get("cost", {}))
	if not state.call("can_pay", cost):
		return _fail("insufficient_resources", "NV+ resources are insufficient")
	var snapshot: Dictionary = _snapshot()
	if not state.call("pay", cost):
		_restore(snapshot)
		return _fail("payment_failed", "NV+ payment failed")
	unit["nv_plus"] = true
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not apply NV+")
	return _commit("progression", snapshot, "NV+ applied", {
		"cost": cost, "label": "UNVERIFIED_RULE"
	})


func shift_form(instance_id: String) -> Dictionary:
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	if not bool(unit.get("nv_unlocked", false)):
		return _fail("nv_required", "NV awakening is required")
	var def: Dictionary = definition(instance_id)
	var target: String = str(def.get("shift", {}).get("to", ""))
	var target_def: Dictionary = ContentRepository.call("get_unit_definition", target)
	if target.is_empty() or target_def.is_empty():
		return _fail("no_form", "No alternate synthetic form is available")
	var snapshot: Dictionary = _snapshot()
	unit["definition_id"] = target
	unit["form"] = str(target_def.get("form", "base"))
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not shift form")
	return _commit("progression", snapshot, "Form shifted to %s" % unit["form"], {
		"form": unit["form"], "label": str(def.get("mechanic_labels", {}).get("brave_shift", "REMASTERED_DESIGN"))
	})


func eligible_abilities(instance_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return result
	var def: Dictionary = definition(instance_id)
	var awakened: Array = unit.get("awakened_abilities", [])
	for ability_variant: Variant in def.get("abilities", []):
		if not ability_variant is Dictionary:
			continue
		var ability: Dictionary = ability_variant
		var id: String = str(ability.get("id", ""))
		if id.is_empty() or awakened.has(id):
			continue
		if int(unit.get("level", 1)) < int(ability.get("unlock_level", 1)):
			continue
		if int(unit.get("star", 1)) < int(ability.get("unlock_star", 1)):
			continue
		result.append(ability)
	return result


func awaken_ability(instance_id: String, ability_id: String) -> Dictionary:
	var matches: Array[Dictionary] = eligible_abilities(instance_id)
	var selected: Dictionary = {}
	for ability: Dictionary in matches:
		if str(ability.get("id", "")) == ability_id:
			selected = ability
			break
	if selected.is_empty():
		return _fail("ineligible", "Ability is not eligible for awakening")
	var cost: Dictionary = _normalize_cost(selected.get("cost", {}))
	if not state.call("can_pay", cost):
		return _fail("insufficient_resources", "Ability awakening resources are insufficient")
	var snapshot: Dictionary = _snapshot()
	if not cost.is_empty() and not state.call("pay", cost):
		_restore(snapshot)
		return _fail("payment_failed", "Ability awakening payment failed")
	var unit: Dictionary = instance(instance_id)
	var awakened: Array = unit.get("awakened_abilities", []).duplicate()
	awakened.append(ability_id)
	unit["awakened_abilities"] = awakened
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not awaken ability")
	return _commit("progression", snapshot, "Ability awakened", {"ability_id": ability_id, "cost": cost})


func cost_summary(instance_id: String) -> Dictionary:
	var unit: Dictionary = instance(instance_id)
	if unit.is_empty():
		return {}
	var def: Dictionary = definition(instance_id)
	var result: Dictionary = {
		"star": (def.get("awakening", {}) as Dictionary).get(str(int(unit.get("star", 5)) + 1), {}),
		"nv": def.get("nv", {}),
		"ex": (def.get("ex", {}) as Dictionary).get(str(maxi(int(unit.get("ex_level", 0)) + 1, 1)), {}),
		"nv_plus": def.get("nv_plus", {}),
		"exp_required": _exp_required(int(unit.get("level", 1))),
		"level_cap": level_cap(def, unit)
	}
	return result


func _normalize_cost(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not value is Dictionary:
		return result
	for key: String in (value as Dictionary).keys():
		var amount: int = maxi(int((value as Dictionary)[key]), 0)
		if amount > 0:
			result[key] = amount
	return result
