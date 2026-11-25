class_name BuildResolver
extends RefCounted

## Resolves immutable definitions + owned state into battle-ready stats.
## System labels are preserved from data; no unverified FFBE original claim is
## implied by a displayed value.

const STATS: Array[String] = ["hp", "mp", "atk", "def", "mag", "spr"]

var state: Node = null


func _init(p_state: Node) -> void:
	state = p_state


func _fail(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message, "diagnostics": [message]}


func _ok(message: String, extras: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {"ok": true, "reason": "", "message": message, "diagnostics": []}
	result.merge(extras, true)
	return result


func resolve_unit(instance_id: String, party_id: String = "", include_vision_card: bool = true) -> Dictionary:
	var unit: Dictionary = state.call("get_unit_instance", instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found: %s" % instance_id)
	var def: Dictionary = state.call("definition_for", unit)
	if def.is_empty():
		return _fail("unknown_definition", "Unit definition not found for %s" % instance_id)

	var stats: Dictionary = {}
	for stat: String in STATS:
		var base_value: int = maxi(int(def.get("base_stats", {}).get(stat, 0)), 0)
		var growth: int = maxi(int(def.get("growth_per_level", {}).get(stat, 0)), 0)
		stats[stat] = base_value + growth * maxi(int(unit.get("level", 1)) - 1, 0)
	var pots: Dictionary = unit.get("pot_allocations", {})
	for stat: String in STATS:
		stats[stat] += maxi(int(pots.get(stat, 0)), 0)

	var percent: Dictionary = {}
	var passives: Array[Dictionary] = []
	var diagnostics: Array[String] = []
	var labels: Dictionary = {}

	for passive_variant: Variant in def.get("passive_abilities", []):
		if passive_variant is Dictionary:
			_add_passive(passive_variant, passives, percent, labels, diagnostics)

	var equipped: Dictionary = unit.get("equipped", {})
	var mech_labels: Dictionary = ContentRepository.call("get_mechanic_labels")
	for slot: String in equipped.keys():
		var uid: String = str(equipped[slot])
		var entry: Dictionary = state.call("find_inventory_entry", uid)
		if entry.is_empty():
			diagnostics.append("Equipped item is missing from inventory: %s" % uid)
			continue
		var item_def: Dictionary = _definition_for_entry(entry)
		if item_def.is_empty():
			diagnostics.append("Equipped item definition is unavailable: %s" % uid)
			continue
		for stat: String in STATS:
			stats[stat] += maxi(int(item_def.get("stats", {}).get(stat, 0)), 0)
		for passive_variant: Variant in item_def.get("passives", []):
			if passive_variant is Dictionary:
				_add_passive(passive_variant, passives, percent, labels, diagnostics)
		var restrictions: Dictionary = item_def.get("restrictions", {})
		if not _restrictions_ok(restrictions, unit, def):
			diagnostics.append("Equipped item restriction is not satisfied: %s" % uid)

	if include_vision_card and not party_id.is_empty():
		var party: Dictionary = state.call("get_party", party_id)
		var vc_uid: String = str(party.get("vision_card", ""))
		if not vc_uid.is_empty():
			var vc_entry: Dictionary = state.call("find_inventory_entry", vc_uid)
			if vc_entry.is_empty():
				diagnostics.append("Assigned vision card is missing: %s" % vc_uid)
			else:
				var vc_def: Dictionary = _definition_for_entry(vc_entry)
				var vc_level: int = maxi(int(vc_entry.get("level", 1)), 1)
				for stat: String in STATS:
					stats[stat] += maxi(int(vc_def.get("stats_per_level", {}).get(stat, 0)), 0) * vc_level
				for passive_variant: Variant in vc_def.get("passives", []):
					if not passive_variant is Dictionary:
						continue
					var passive: Dictionary = passive_variant
					var categories: Array = passive.get("categories", [])
					var categories_ok: bool = categories.is_empty()
					for category: Variant in categories:
						if def.get("categories", []).has(str(category)):
							categories_ok = true
							break
					if categories_ok:
						_add_passive(passive, passives, percent, labels, diagnostics, vc_level)
					else:
						diagnostics.append("Vision card category does not match this unit: %s" % vc_uid)

	if not party_id.is_empty():
		var party_data: Dictionary = state.call("get_party", party_id)
		var slots: Array = party_data.get("slots", [])
		var leader_slot: int = maxi(int(party_data.get("leader_slot", 0)), 0)
		if leader_slot < slots.size() and str(slots[leader_slot]) == instance_id:
			var leader: Dictionary = def.get("leader_skill", {})
			if not leader.is_empty():
				var effect: Dictionary = leader.get("effect", {})
				var categories: Array = effect.get("categories", [])
				var applies: bool = categories.is_empty()
				for category: Variant in categories:
					if def.get("categories", []).has(str(category)):
						applies = true
						break
				if applies:
					var stat_name: String = str(effect.get("stat", ""))
					if STATS.has(stat_name):
						_add_percent(percent, stat_name, int(effect.get("percent", 0)))
						labels[str(leader.get("id", "leader_skill"))] = str(leader.get("label", "REMASTERED_DESIGN"))
					else:
						diagnostics.append("Leader skill has an unknown stat: %s" % stat_name)

	var cap_percent: int = maxi(int(ContentRepository.call("get_progression_rules").get("passive_stat_cap_percent", 400)), 0)
	var final_stats: Dictionary = {}
	for stat: String in STATS:
		var bonus_percent: int = clampi(int(percent.get(stat, 0)), 0, cap_percent)
		final_stats[stat] = maxi(int(round(float(stats[stat]) * (1.0 + float(bonus_percent) / 100.0))), 0)

	var ability_ids: Array[String] = []
	for ability_variant: Variant in def.get("abilities", []):
		var ability_id: String = _ability_id(ability_variant)
		if ability_id.is_empty() or ability_ids.has(ability_id):
			continue
		ability_ids.append(ability_id)
	for ability_id_variant: Variant in unit.get("awakened_abilities", []):
		var ability_id: String = _ability_id(ability_id_variant)
		if ability_id.is_empty() or ability_ids.has(ability_id):
			continue
		ability_ids.append(ability_id)
	var ex_level: int = maxi(int(unit.get("ex_level", 0)), 0)
	if ex_level >= 1:
		var slb: Dictionary = def.get("super_lb", {})
		if not str(slb.get("id", "")).is_empty() and not ability_ids.has(str(slb["id"])):
			ability_ids.append(str(slb["id"]))
			labels[str(slb["id"])] = str(slb.get("label", "UNVERIFIED_RULE"))
	if ex_level >= 2:
		var od: Dictionary = def.get("overdrive", {})
		if not str(od.get("id", "")).is_empty() and not ability_ids.has(str(od["id"])):
			ability_ids.append(str(od["id"]))
			labels[str(od["id"])] = str(od.get("label", "UNVERIFIED_RULE"))

	return _ok("Build resolved", {
		"instance_id": instance_id,
		"definition_id": str(unit.get("definition_id", "")),
		"form": str(unit.get("form", "base")),
		"level": int(unit.get("level", 1)),
		"star": int(unit.get("star", 5)),
		"ex_level": ex_level,
		"stats": final_stats,
		"base_stats": stats,
		"percent": percent,
		"passives": passives,
		"abilities": ability_ids,
		"restrictions": equipped,
		"labels": labels,
		"diagnostics": diagnostics
	})


func _add_passive(
	passive: Dictionary,
	passives: Array[Dictionary],
	percent: Dictionary,
	labels: Dictionary,
	diagnostics: Array[String],
	level_scale: int = 1
) -> void:
	var passive_id: String = str(passive.get("id", ""))
	var label: String = str(passive.get("label", ""))
	if not label.is_empty() and not passive_id.is_empty():
		labels[passive_id] = label
	var kind: String = str(passive.get("type", ""))
	if kind == "stat":
		var stat_name: String = str(passive.get("stat", ""))
		if not STATS.has(stat_name):
			diagnostics.append("Passive has an unknown stat: %s" % stat_name)
			return
		var amount: int = maxi(int(passive.get("percent", 0)), 0)
		if bool(passive.get("per_level", false)):
			amount *= maxi(level_scale, 1)
		_add_percent(percent, stat_name, amount)
	var copy: Dictionary = passive.duplicate(true)
	passives.append(copy)


func _add_percent(percent: Dictionary, stat: String, amount: int) -> void:
	percent[stat] = maxi(int(percent.get(stat, 0)), 0) + maxi(amount, 0)


func _definition_for_entry(entry: Dictionary) -> Dictionary:
	var definition_id: String = str(entry.get("definition_id", ""))
	if definition_id.begins_with("equip:"):
		return ContentRepository.call("get_equipment_definition", definition_id)
	if definition_id.begins_with("materia:"):
		return ContentRepository.call("get_materia_definition", definition_id)
	if definition_id.begins_with("vision_card:"):
		return ContentRepository.call("get_vision_card_definition", definition_id)
	return {}


func _restrictions_ok(restrictions: Dictionary, unit: Dictionary, def: Dictionary) -> bool:
	if restrictions.has("forms") and not (restrictions["forms"] as Array).has(str(unit.get("form", "base"))):
		return false
	if restrictions.has("roles") and not (restrictions["roles"] as Array).has(str(def.get("role", ""))):
		return false
	if restrictions.has("categories"):
		var categories: Array = def.get("categories", [])
		var allowed: Array = restrictions["categories"]
		for category: Variant in categories:
			if allowed.has(str(category)):
				return true
		return false
	return true


func resolve_party(party_id: String) -> Dictionary:
	var party: Dictionary = state.call("get_party", party_id)
	if party.is_empty():
		return _fail("unknown_party", "Party not found: %s" % party_id)
	var slots: Array = party.get("slots", [])
	if slots.size() != 5:
		return _fail("invalid_party", "A party must contain exactly five slots")
	var seen: Dictionary = {}
	var units: Array[Dictionary] = []
	var diagnostics: Array[String] = []
	for slot_index: int in range(slots.size()):
		var instance_id: String = str(slots[slot_index])
		if instance_id.is_empty():
			diagnostics.append("Slot %d is empty" % (slot_index + 1))
			continue
		if seen.has(instance_id):
			diagnostics.append("Slot %d repeats instance %s" % [slot_index + 1, instance_id])
			continue
		seen[instance_id] = true
		var resolved: Dictionary = resolve_unit(instance_id, party_id, true)
		if not bool(resolved.get("ok", false)):
			diagnostics.append("Slot %d: %s" % [slot_index + 1, str(resolved.get("message", "invalid unit"))])
			continue
		units.append(resolved)
		for item: String in resolved.get("diagnostics", []):
			diagnostics.append("Slot %d: %s" % [slot_index + 1, item])
	var valid: bool = units.size() == 5 and diagnostics.is_empty()
	var totals: Dictionary = {}
	for stat: String in STATS:
		totals[stat] = 0
	for resolved: Dictionary in units:
		for stat: String in STATS:
			totals[stat] += int(resolved.get("stats", {}).get(stat, 0))
	return _ok("Party resolved", {
		"party_id": party_id,
		"valid": valid,
		"diagnostics": diagnostics,
		"slots": slots.duplicate(),
		"leader_slot": int(party.get("leader_slot", 0)),
		"units": units,
		"totals": totals,
		"vision_card": str(party.get("vision_card", ""))
	})


func build_combatant_def(instance_id: String, party_id: String = "") -> Dictionary:
	var unit: Dictionary = state.call("get_unit_instance", instance_id)
	if unit.is_empty():
		return {}
	var def: Dictionary = state.call("definition_for", unit)
	if def.is_empty():
		return {}
	var resolved: Dictionary = resolve_unit(instance_id, party_id, true)
	if not bool(resolved.get("ok", false)):
		return {}
	var base_id: String = str(unit.get("base_id", str(def.get("base_id", ""))))
	var source_def: Dictionary = ContentRepository.call("get_battle_combatant", str(unit.get("definition_id", "")))
	if source_def.is_empty():
		source_def = ContentRepository.call("get_battle_combatant", base_id)
	if source_def.is_empty():
		return {}
	var result: Dictionary = source_def.duplicate(true)
	result["id"] = instance_id
	result["definition_id"] = str(unit.get("definition_id", ""))
	result["display_name"] = LocaleManager.call("label_for", def)
	result["role"] = str(def.get("role", source_def.get("role", "unknown")))
	result["level"] = int(unit.get("level", source_def.get("level", 1)))
	result["stats"] = resolved.get("stats", source_def.get("stats", {}))
	result["resist"] = source_def.get("resist", {})
	result["weapon_variance"] = source_def.get("weapon_variance", [1.0, 1.0])
	result["lb_cost"] = int(source_def.get("lb_cost", 12))
	result["basic_attack"] = str(source_def.get("basic_attack", ""))
	result["limit_ability"] = str(source_def.get("limit_burst", ""))
	result["limit_burst"] = str(source_def.get("limit_burst", ""))
	var abilities: Array[String] = []
	for ability_id: Variant in result.get("abilities", []):
		var id: String = str(ability_id)
		if not abilities.has(id):
			abilities.append(id)
	for ability_id: String in resolved.get("abilities", []):
		if not abilities.has(ability_id):
			abilities.append(ability_id)
	result["abilities"] = abilities
	result["mechanic_labels"] = resolved.get("labels", {})
	result["verification_status"] = "SYNTHETIC_FIXTURE"
	return result


## Definition ability entries are dictionaries with an `id`; resolved and
## awakened ability collections use bare ID strings. Accept both shapes so
## form-specific abilities keep their composite identity end to end.
func _ability_id(value: Variant) -> String:
	if value is Dictionary:
		return str((value as Dictionary).get("id", ""))
	return str(value)
