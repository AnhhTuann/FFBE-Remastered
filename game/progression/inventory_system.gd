class_name InventorySystem
extends RefCounted

## Owned-item uniqueness, equipment restrictions, materia stacking and vision
## cards. Every item definition comes from the synthetic content repository.

const SECTIONS: Array[String] = ["equipment", "materia", "vision_cards", "abilities"]
const MATERIA_SLOT_COUNT := 4

var state: Node = null


func _init(p_state: Node) -> void:
	state = p_state


func _fail(reason: String, message: String, extras: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {"ok": false, "reason": reason, "message": message}
	result.merge(extras, true)
	return result


func _ok(message: String, extras: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {"ok": true, "reason": "", "message": message}
	result.merge(extras, true)
	return result


func _snapshot() -> Dictionary:
	var data: Dictionary = state.get("data")
	return {
		"resources": state.call("get_resources"),
		"owned_units": data.get("owned_units", []).duplicate(true),
		"inventory": data.get("inventory", {}).duplicate(true),
		"parties": data.get("parties", {}).duplicate(true)
	}


func _restore(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	var data: Dictionary = state.get("data")
	data["resources"] = snapshot.get("resources", {}).duplicate(true)
	data["owned_units"] = snapshot.get("owned_units", []).duplicate(true)
	data["inventory"] = snapshot.get("inventory", {}).duplicate(true)
	data["parties"] = snapshot.get("parties", {}).duplicate(true)
	state.set("data", data)


func _commit(section: String, snapshot: Dictionary, message: String, extras: Dictionary = {}) -> Dictionary:
	var error: Error = state.call("commit", section)
	if error != OK:
		_restore(snapshot)
		return _fail("save_failed", message)
	return _ok(message, extras)


func _data() -> Dictionary:
	return state.get("data")


func definition_for(uid: String) -> Dictionary:
	var entry: Dictionary = state.call("find_inventory_entry", uid)
	if entry.is_empty():
		return {}
	var definition_id: String = str(entry.get("definition_id", ""))
	if definition_id.begins_with("equip:"):
		return ContentRepository.call("get_equipment_definition", definition_id)
	if definition_id.begins_with("materia:"):
		return ContentRepository.call("get_materia_definition", definition_id)
	if definition_id.begins_with("vision_card:"):
		return ContentRepository.call("get_vision_card_definition", definition_id)
	if definition_id.begins_with("ability:"):
		return ContentRepository.call("get_ability_reward_definition", definition_id)
	return {}


func grant_item(definition_id: String, source: String = "granted") -> Dictionary:
	var def: Dictionary = _definition_by_id(definition_id)
	if def.is_empty():
		return _fail("unknown_definition", "Item definition not found: %s" % definition_id)
	var section: String = _section_for(definition_id)
	var serial: int = state.call("next_equip_serial")
	var region: String = str(def.get("region", "GL"))
	var native_id: String = str(def.get("native_id", ""))
	var form: String = str(def.get("form", "base"))
	var uid: String = "owned:%s:%s:%04d@%s" % [region, native_id, serial, form]
	var entry: Dictionary = {
		"uid": uid,
		"definition_id": definition_id,
		"level": 1,
		"locked": false,
		"source": source
	}
	var snapshot: Dictionary = _snapshot()
	var data: Dictionary = _data()
	var inventory: Dictionary = data.get("inventory", {}).duplicate(true)
	var section_items: Array = inventory.get(section, []).duplicate()
	section_items.append(entry)
	inventory[section] = section_items
	data["inventory"] = inventory
	state.set("data", data)
	if not _can_persist(snapshot):
		return _fail("save_failed", "Item grant could not be saved")
	return _ok("Item granted", {"uid": uid, "section": section, "definition_id": definition_id})


func _can_persist(snapshot: Dictionary) -> bool:
	var error: Error = state.call("commit", "inventory")
	if error != OK:
		_restore(snapshot)
		return false
	return true


func _definition_by_id(definition_id: String) -> Dictionary:
	if definition_id.begins_with("equip:"):
		return ContentRepository.call("get_equipment_definition", definition_id)
	if definition_id.begins_with("materia:"):
		return ContentRepository.call("get_materia_definition", definition_id)
	if definition_id.begins_with("vision_card:"):
		return ContentRepository.call("get_vision_card_definition", definition_id)
	if definition_id.begins_with("ability:"):
		return ContentRepository.call("get_ability_reward_definition", definition_id)
	return {}


func _section_for(definition_id: String) -> String:
	if definition_id.begins_with("equip:"):
		return "equipment"
	if definition_id.begins_with("materia:"):
		return "materia"
	if definition_id.begins_with("vision_card:"):
		return "vision_cards"
	if definition_id.begins_with("ability:"):
		return "abilities"
	return ""


func inventory_for_slot(slot: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if slot.begins_with("materia"):
		for entry: Dictionary in state.call("inventory_section", "materia"):
			result.append(entry)
		return result
	for entry: Dictionary in state.call("inventory_section", "equipment"):
		var def: Dictionary = ContentRepository.call("get_equipment_definition", str(entry.get("definition_id", "")))
		var slots: Array = def.get("slots", [])
		if slots.has(slot):
			result.append(entry)
	return result


func _entry(uid: String) -> Dictionary:
	return state.call("find_inventory_entry", uid)


func _uid_equipped_elsewhere(uid: String, except_instance_id: String = "") -> bool:
	for unit: Dictionary in state.call("owned_units"):
		var instance_id: String = str(unit.get("instance_id", ""))
		if instance_id == except_instance_id:
			continue
		var equipped: Dictionary = unit.get("equipped", {})
		for slot: String in equipped.keys():
			if str(equipped[slot]) == uid:
				return true
	for party_id: String in state.call("parties").keys():
		var party: Dictionary = state.call("get_party", party_id)
		if _party_vc_in_use(party, uid, except_instance_id):
			return true
	return false


func _party_vc_in_use(party: Dictionary, uid: String, except_instance_id: String = "") -> bool:
	if uid.is_empty():
		return false
	if str(party.get("vision_card", "")) == uid:
		return true
	var assignments_variant: Variant = party.get("vision_card_assignments", {})
	if assignments_variant is Dictionary:
		for instance_id: Variant in (assignments_variant as Dictionary).keys():
			if str(instance_id) == except_instance_id:
				continue
			if str((assignments_variant as Dictionary)[instance_id]) == uid:
				return true
	return false


func _vision_card_entry(uid: String) -> Dictionary:
	var entry: Dictionary = _entry(uid)
	if entry.is_empty() or bool(entry.get("locked", false)):
		return {}
	if not str(entry.get("definition_id", "")).begins_with("vision_card:"):
		return {}
	if definition_for(uid).is_empty():
		return {}
	return entry


func _passes_restrictions(def: Dictionary, instance_id: String, slot: String) -> bool:
	var unit: Dictionary = state.call("get_unit_instance", instance_id)
	if unit.is_empty():
		return false
	var def_unit: Dictionary = state.call("definition_for", unit)
	var restrictions: Dictionary = def.get("restrictions", {})
	if restrictions.has("forms") and not (restrictions["forms"] as Array).has(str(unit.get("form", "base"))):
		return false
	if restrictions.has("roles") and not (restrictions["roles"] as Array).has(str(def_unit.get("role", ""))):
		return false
	if restrictions.has("categories"):
		var categories: Array = def_unit.get("categories", [])
		var allowed: Array = restrictions["categories"]
		var matched: bool = false
		for category: Variant in categories:
			if allowed.has(str(category)):
				matched = true
				break
		if not matched:
			return false
	if slot.begins_with("materia"):
		return true
	return (def.get("slots", []) as Array).has(slot)


func equip(instance_id: String, slot: String, uid: String) -> Dictionary:
	if slot.begins_with("materia"):
		var index_text: String = slot.substr(slot.find("_") + 1)
		if not index_text.is_valid_int():
			return _fail("invalid_slot", "Invalid materia slot")
		return equip_materia(instance_id, index_text.to_int(), uid)
	var unit: Dictionary = state.call("get_unit_instance", instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	var entry: Dictionary = _entry(uid)
	if entry.is_empty():
		return _fail("unknown_item", "Owned item not found")
	if bool(entry.get("locked", false)):
		return _fail("locked", "Locked items cannot be equipped")
	if _uid_equipped_elsewhere(uid, instance_id):
		return _fail("already_equipped", "This item is already equipped")
	var def: Dictionary = definition_for(uid)
	if def.is_empty() or not _passes_restrictions(def, instance_id, slot):
		return _fail("restriction", "Item cannot be equipped in this slot by this form")
	var snapshot: Dictionary = _snapshot()
	var equipped: Dictionary = (unit.get("equipped", {}) as Dictionary).duplicate(true)
	equipped[slot] = uid
	unit["equipped"] = equipped
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not equip item")
	return _commit("equipment", snapshot, "Item equipped", {"slot": slot, "uid": uid})


func unequip(instance_id: String, slot: String) -> Dictionary:
	var unit: Dictionary = state.call("get_unit_instance", instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	var equipped: Dictionary = (unit.get("equipped", {}) as Dictionary).duplicate(true)
	if not equipped.has(slot):
		return _fail("empty_slot", "Slot is already empty")
	var uid: String = str(equipped.get(slot, ""))
	equipped.erase(slot)
	unit["equipped"] = equipped
	var snapshot: Dictionary = _snapshot()
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not unequip item")
	return _commit("equipment", snapshot, "Item unequipped", {"slot": slot, "uid": uid})


func equip_materia(instance_id: String, index: int, uid: String) -> Dictionary:
	if index < 0 or index >= MATERIA_SLOT_COUNT:
		return _fail("invalid_slot", "Materia slot must be 0-3")
	var slot: String = "materia_%d" % index
	var unit: Dictionary = state.call("get_unit_instance", instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	var entry: Dictionary = _entry(uid)
	if entry.is_empty():
		return _fail("unknown_item", "Owned materia not found")
	if bool(entry.get("locked", false)):
		return _fail("locked", "Locked materia cannot be equipped")
	if _uid_equipped_elsewhere(uid, instance_id):
		return _fail("already_equipped", "This materia is already equipped")
	var def: Dictionary = definition_for(uid)
	if def.is_empty() or not _passes_restrictions(def, instance_id, slot):
		return _fail("restriction", "Materia cannot be equipped by this form")
	var stack_group: String = str(def.get("stacking_group", uid))
	var stack_limit: int = maxi(int(def.get("stack_limit", 1)), 1)
	var equipped: Dictionary = (unit.get("equipped", {}) as Dictionary).duplicate(true)
	var used: int = 0
	for equipped_slot: String in equipped.keys():
		if not equipped_slot.begins_with("materia_"):
			continue
		var other: Dictionary = _entry(str(equipped[equipped_slot]))
		if not other.is_empty() and str(_definition_by_id(str(other.get("definition_id", ""))).get("stacking_group", "")) == stack_group:
			used += 1
	if used >= stack_limit and str(equipped.get(slot, "")) != uid:
		return _fail("stack_limit", "Materia stacking limit reached")
	var snapshot: Dictionary = _snapshot()
	equipped[slot] = uid
	unit["equipped"] = equipped
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not equip materia")
	return _commit("equipment", snapshot, "Materia equipped", {"slot": slot, "uid": uid})


func unequip_materia(instance_id: String, index: int) -> Dictionary:
	return unequip(instance_id, "materia_%d" % index)


func assign_vision_card(party_id: String, uid: String) -> Dictionary:
	var party: Dictionary = state.call("get_party", party_id)
	if party.is_empty():
		return _fail("unknown_party", "Party not found")
	var entry: Dictionary = _entry(uid)
	if entry.is_empty():
		return _fail("unknown_item", "Vision card not found")
	if bool(entry.get("locked", false)):
		return _fail("locked", "Locked cards cannot be assigned")
	var def: Dictionary = definition_for(uid)
	if def.is_empty() or not str(entry.get("definition_id", "")).begins_with("vision_card:"):
		return _fail("wrong_type", "Item is not a vision card")
	if _uid_equipped_elsewhere(uid):
		return _fail("already_assigned", "Vision card is already assigned")
	var snapshot: Dictionary = _snapshot()
	party["vision_card"] = uid
	state.call("set_party", party_id, party)
	return _commit("party", snapshot, "Vision card assigned", {"uid": uid, "party_id": party_id})


func unassign_vision_card(party_id: String) -> Dictionary:
	var party: Dictionary = state.call("get_party", party_id)
	if party.is_empty():
		return _fail("unknown_party", "Party not found")
	var uid: String = str(party.get("vision_card", ""))
	if uid.is_empty():
		return _fail("empty_slot", "No vision card is assigned")
	var snapshot: Dictionary = _snapshot()
	party.erase("vision_card")
	state.call("set_party", party_id, party)
	return _commit("party", snapshot, "Vision card unassigned", {"uid": uid, "party_id": party_id})


## Per-unit assignment has the highest BuildResolver precedence. The same card
## can never be assigned to two units or reused as a party card at once.
func assign_vision_card_to_unit(instance_id: String, uid: String) -> Dictionary:
	var unit: Dictionary = state.call("get_unit_instance", instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	var entry: Dictionary = _vision_card_entry(uid)
	if entry.is_empty():
		return _fail("wrong_type", "Vision card is unavailable or locked")
	if _uid_equipped_elsewhere(uid, instance_id):
		return _fail("already_assigned", "Vision card is already assigned")
	var snapshot: Dictionary = _snapshot()
	var equipped: Dictionary = (unit.get("equipped", {}) as Dictionary).duplicate(true)
	equipped["vision_card"] = uid
	unit["equipped"] = equipped
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not assign vision card")
	return _commit("equipment", snapshot, "Vision card assigned to unit", {
		"uid": uid, "instance_id": instance_id
	})


func unassign_vision_card_from_unit(instance_id: String) -> Dictionary:
	var unit: Dictionary = state.call("get_unit_instance", instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	var equipped: Dictionary = (unit.get("equipped", {}) as Dictionary).duplicate(true)
	if not equipped.has("vision_card"):
		return _fail("empty_slot", "Unit has no vision card")
	var uid: String = str(equipped["vision_card"])
	equipped.erase("vision_card")
	unit["equipped"] = equipped
	var snapshot: Dictionary = _snapshot()
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not unassign vision card")
	return _commit("equipment", snapshot, "Vision card unassigned from unit", {
		"uid": uid, "instance_id": instance_id
	})


func assign_vision_card_to_party_unit(party_id: String, instance_id: String, uid: String) -> Dictionary:
	var party: Dictionary = state.call("get_party", party_id)
	if party.is_empty():
		return _fail("unknown_party", "Party not found")
	var slots_variant: Variant = party.get("slots", [])
	if not (slots_variant is Array) or not (slots_variant as Array).has(instance_id):
		return _fail("not_in_party", "Unit is not in this party")
	var unit: Dictionary = state.call("get_unit_instance", instance_id)
	if unit.is_empty():
		return _fail("unknown_instance", "Owned unit not found")
	var entry: Dictionary = _vision_card_entry(uid)
	if entry.is_empty():
		return _fail("wrong_type", "Vision card is unavailable or locked")
	if _uid_equipped_elsewhere(uid, instance_id):
		return _fail("already_assigned", "Vision card is already assigned")
	var snapshot: Dictionary = _snapshot()
	var equipped: Dictionary = (unit.get("equipped", {}) as Dictionary).duplicate(true)
	equipped["vision_card"] = uid
	unit["equipped"] = equipped
	if not state.call("mutate_unit_instance", instance_id, unit):
		_restore(snapshot)
		return _fail("mutation_failed", "Could not assign vision card")
	var assignments_variant: Variant = party.get("vision_card_assignments", {})
	var assignments: Dictionary = assignments_variant if assignments_variant is Dictionary else {}
	assignments[instance_id] = uid
	party["vision_card_assignments"] = assignments
	state.call("set_party", party_id, party)
	return _commit("party", snapshot, "Vision card assigned to party unit", {
		"uid": uid, "party_id": party_id, "instance_id": instance_id
	})


func toggle_lock(uid: String) -> Dictionary:
	var entry: Dictionary = _entry(uid)
	if entry.is_empty():
		return _fail("unknown_item", "Owned item not found")
	var snapshot: Dictionary = _snapshot()
	entry["locked"] = not bool(entry.get("locked", false))
	var data: Dictionary = _data()
	var inventory: Dictionary = data.get("inventory", {}).duplicate(true)
	var section: String = str(entry.get("_section", ""))
	if section.is_empty():
		section = _section_for(str(entry.get("definition_id", "")))
	var items: Array = inventory.get(section, []).duplicate()
	for index: int in range(items.size()):
		if str((items[index] as Dictionary).get("uid", "")) == uid:
			items[index] = entry
			break
	inventory[section] = items
	data["inventory"] = inventory
	state.set("data", data)
	return _commit("inventory", snapshot, "Lock toggled", {"uid": uid, "locked": bool(entry["locked"])})


func sell(uid: String) -> Dictionary:
	var entry: Dictionary = _entry(uid)
	if entry.is_empty():
		return _fail("unknown_item", "Owned item not found")
	if bool(entry.get("locked", false)):
		return _fail("locked", "Unlock the item before selling")
	if _uid_equipped_elsewhere(uid):
		return _fail("equipped", "Unequip this item before selling")
	var def: Dictionary = definition_for(uid)
	var value: int = maxi(int(def.get("sell_value", 0)), 0)
	if value <= 0:
		return _fail("no_sell_value", "This item has no synthetic sell value")
	var snapshot: Dictionary = _snapshot()
	var data: Dictionary = _data()
	var inventory: Dictionary = data.get("inventory", {}).duplicate(true)
	var section: String = _section_for(str(entry.get("definition_id", "")))
	var items: Array = []
	for item_variant: Variant in inventory.get(section, []):
		if item_variant is Dictionary and str((item_variant as Dictionary).get("uid", "")) == uid:
			continue
		items.append(item_variant)
	inventory[section] = items
	data["inventory"] = inventory
	state.set("data", data)
	var resources: Dictionary = state.call("get_resources")
	resources["gil"] = maxi(int(resources.get("gil", 0)), 0) + value
	data["resources"] = resources
	state.set("data", data)
	return _commit("inventory", snapshot, "Item sold", {"uid": uid, "gil": value})


func upgrade_vision_card(uid: String) -> Dictionary:
	var entry: Dictionary = _entry(uid)
	if entry.is_empty():
		return _fail("unknown_item", "Vision card not found")
	if bool(entry.get("locked", false)):
		return _fail("locked", "Unlock the card before upgrading")
	var def: Dictionary = definition_for(uid)
	var level: int = maxi(int(entry.get("level", 1)), 1)
	var max_level: int = maxi(int(def.get("max_level", 1)), 1)
	if level >= max_level:
		return _fail("max_level", "Vision card is already at max level")
	var cost_variant: Variant = (def.get("upgrade_costs", {}) as Dictionary).get(str(level + 1), {})
	if not cost_variant is Dictionary:
		return _fail("no_cost", "No synthetic upgrade cost for the next level")
	var cost: Dictionary = {}
	for key: String in (cost_variant as Dictionary).keys():
		cost[key] = maxi(int((cost_variant as Dictionary)[key]), 0)
	if not state.call("can_pay", cost):
		return _fail("insufficient_resources", "Upgrade resources are insufficient")
	var snapshot: Dictionary = _snapshot()
	if not state.call("pay", cost):
		_restore(snapshot)
		return _fail("payment_failed", "Upgrade payment failed")
	entry["level"] = level + 1
	var data: Dictionary = _data()
	var inventory: Dictionary = data.get("inventory", {}).duplicate(true)
	var items: Array = inventory.get("vision_cards", []).duplicate()
	for index: int in range(items.size()):
		if str((items[index] as Dictionary).get("uid", "")) == uid:
			items[index] = entry
			break
	inventory["vision_cards"] = items
	data["inventory"] = inventory
	state.set("data", data)
	return _commit("inventory", snapshot, "Vision card upgraded", {"uid": uid, "level": level + 1, "cost": cost})
