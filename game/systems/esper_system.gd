class_name EsperSystem
extends RefCounted

## Prompt 05 synthetic esper collection system. All definitions come from
## SYNTHETIC_FIXTURE content; synthesized stats are project-authored design and
## make no claim about original FFBE esper values. Every mutation is snapshotted
## and committed once through PlayerState.

const EVIDENCE_LABEL := "REMASTERED_DESIGN"
const STAT_KEYS: Array[String] = ["hp", "mp", "atk", "def", "mag", "spr"]

var state: Node = null


func _init(p_state: Node) -> void:
	state = p_state


func _repo() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("ContentRepository") if tree != null else null


func definition(esper_id: String) -> Dictionary:
	return _repo().call("get_esper_definition", esper_id)


func definitions() -> Dictionary:
	return _repo().call("get_esper_definitions")


func owned() -> Dictionary:
	var data: Dictionary = state.get("data")
	var section: Dictionary = _read_section(data, "espers")
	var owned_variant: Variant = section.get("owned", {})
	return (owned_variant as Dictionary).duplicate(true) if owned_variant is Dictionary else {}


func status_for(party_id: String) -> Dictionary:
	var data: Dictionary = state.get("data")
	var section: Dictionary = _read_section(data, "espers")
	var active_variant: Variant = (section.get("active_by_party", {}) as Dictionary).get(party_id, "")
	var esper_id: String = str(active_variant)
	if esper_id.is_empty():
		return _fail("no_active_esper", "esper.status.no_active", {"party_id": party_id, "stats": {}})
	var entry: Dictionary = _owned_entry(esper_id)
	if entry.is_empty():
		return _fail("not_owned", "esper.status.not_owned", {"party_id": party_id, "esper_id": esper_id})
	var def: Dictionary = definition(esper_id)
	if def.is_empty():
		return _fail("unknown_esper", "esper.status.unknown", {"party_id": party_id, "esper_id": esper_id})
	var level: int = clampi(int(entry.get("level", 1)), 1, maxi(int(def.get("max_level", 1)), 1))
	var stats: Dictionary = _synthesized_stats(def, level)
	return _ok("esper.status.ready", {
		"party_id": party_id,
		"esper_id": esper_id,
		"level": level,
		"sp": clampi(int(entry.get("sp", 0)), 0, maxi(int(def.get("sp_cap", 0)), 0)),
		"max_level": maxi(int(def.get("max_level", 1)), 1),
		"stats": stats,
		"passive_effects": (def.get("passive_effects", []) as Array).duplicate(true),
		"evidence": EVIDENCE_LABEL
	})


func unlock(esper_id: String) -> Dictionary:
	var def: Dictionary = definition(esper_id)
	if def.is_empty():
		return _fail("unknown_esper", "esper.unlock.unknown", {"key": esper_id})
	var data: Dictionary = state.get("data")
	var section: Dictionary = _read_section(data, "espers")
	var claims: Dictionary = _read_section(section, "claims")
	var claim_key: String = "esper|%s|unlock" % esper_id
	if claims.has(claim_key):
		return _fail("already_claimed", "esper.unlock.claimed", {"key": claim_key})
	var owned: Dictionary = _read_section(section, "owned")
	if owned.has(esper_id):
		return _fail("already_owned", "esper.unlock.owned", {"key": claim_key})
	var unlock_rule: Dictionary = def.get("unlock", {}) if def.get("unlock", {}) is Dictionary else {}
	var required_flags: Array = unlock_rule.get("required_flags", []) if unlock_rule.get("required_flags", []) is Array else []
	for flag: Variant in required_flags:
		if not _has_flag(str(flag)):
			return _fail("flag_required", "esper.unlock.flag", {"key": claim_key, "flag": str(flag)})
	var min_level: int = maxi(int(unlock_rule.get("min_level", 1)), 1)
	if _player_level() < min_level:
		return _fail("level_required", "esper.unlock.level", {"key": claim_key})
	var cost: Dictionary = _clamped_cost(def.get("cost", {}))
	if not state.call("can_pay", cost):
		return _fail("insufficient_resources", "esper.unlock.resources", {"key": claim_key})

	var snapshot: String = _snapshot()
	if not bool(state.call("pay", cost)):
		_restore(snapshot)
		return _fail("payment_failed", "esper.unlock.payment", {"key": claim_key})
	data = state.get("data")
	section = _ensure_section(data, "espers")
	owned = _ensure_section(section, "owned")
	claims = _ensure_section(section, "claims")
	owned[esper_id] = {"level": 1, "sp": 0, "source": "synthetic_unlock"}
	claims[claim_key] = {"esper_id": esper_id, "level": 1, "evidence": EVIDENCE_LABEL}
	section["owned"] = owned
	section["claims"] = claims
	data["espers"] = section
	return _commit("espers", snapshot, "esper.unlock.ok", {"key": claim_key, "esper_id": esper_id, "level": 1})


func set_active(party_id: String, esper_id: String) -> Dictionary:
	if party_id.is_empty() or state.call("get_party", party_id).is_empty():
		return _fail("unknown_party", "esper.active.party", {"key": esper_id})
	var def: Dictionary = definition(esper_id)
	if def.is_empty():
		return _fail("unknown_esper", "esper.active.unknown", {"key": esper_id})
	if _owned_entry(esper_id).is_empty():
		return _fail("not_owned", "esper.active.not_owned", {"key": esper_id})
	var link_rules: Dictionary = def.get("party_link_rules", {}) if def.get("party_link_rules", {}) is Dictionary else {}
	var party: Dictionary = state.call("get_party", party_id)
	var party_region: String = str(party.get("region", ""))
	if str(link_rules.get("region_lock", "")) == "same_region" and not party_region.is_empty() and party_region != str(def.get("region", "")):
		return _fail("region_mismatch", "esper.active.region", {"key": esper_id})
	var max_parties: int = maxi(int(link_rules.get("max_active_parties", 1)), 1)
	var data: Dictionary = state.get("data")
	var section: Dictionary = _read_section(data, "espers")
	var active: Dictionary = _read_section(section, "active_by_party")
	var linked: int = 0
	for key: Variant in active.keys():
		if str(active[key]) == esper_id and str(key) != party_id:
			linked += 1
	if linked >= max_parties:
		return _fail("link_limit", "esper.active.limit", {"key": esper_id})
	var status_key: String = "esper|%s|active:%s" % [esper_id, party_id]
	if str(active.get(party_id, "")) == esper_id:
		return _ok("esper.active.ok", {"key": status_key, "esper_id": esper_id, "party_id": party_id, "unchanged": true})

	var snapshot: String = _snapshot()
	data = state.get("data")
	section = _ensure_section(data, "espers")
	active = _ensure_section(section, "active_by_party")
	active[party_id] = esper_id
	section["active_by_party"] = active
	data["espers"] = section
	return _commit("espers", snapshot, "esper.active.ok", {"key": status_key, "esper_id": esper_id, "party_id": party_id})


func clear_active(party_id: String) -> Dictionary:
	if party_id.is_empty() or state.call("get_party", party_id).is_empty():
		return _fail("unknown_party", "esper.clear.party", {"key": party_id})
	var data: Dictionary = state.get("data")
	var section: Dictionary = _read_section(data, "espers")
	var active: Dictionary = _read_section(section, "active_by_party")
	if not active.has(party_id):
		return _ok("esper.clear.ok", {"key": party_id, "unchanged": true})
	var snapshot: String = _snapshot()
	data = state.get("data")
	section = _ensure_section(data, "espers")
	active = _ensure_section(section, "active_by_party")
	active.erase(party_id)
	section["active_by_party"] = active
	data["espers"] = section
	return _commit("espers", snapshot, "esper.clear.ok", {"key": party_id})


func add_sp(esper_id: String, amount: int) -> Dictionary:
	var def: Dictionary = definition(esper_id)
	if def.is_empty():
		return _fail("unknown_esper", "esper.sp.unknown", {"key": esper_id})
	var entry: Dictionary = _owned_entry(esper_id)
	if entry.is_empty():
		return _fail("not_owned", "esper.sp.not_owned", {"key": esper_id})
	if amount <= 0:
		return _fail("invalid_amount", "esper.sp.amount", {"key": esper_id})
	var cap: int = maxi(int(def.get("sp_cap", 0)), 0)
	var current: int = clampi(int(entry.get("sp", 0)), 0, cap)
	var applied: int = mini(amount, maxi(cap - current, 0))
	if applied <= 0:
		return _fail("sp_cap_reached", "esper.sp.cap", {"key": esper_id})
	var unit_cost: Dictionary = _clamped_cost(def.get("sp_cost", {}))
	var cost: Dictionary = {}
	for key: String in unit_cost.keys():
		cost[key] = unit_cost[key] * applied
	if not state.call("can_pay", cost):
		return _fail("insufficient_resources", "esper.sp.resources", {"key": esper_id})
	# SP is a repeatable paid progression sink, not a one-time reward. Diagnostics
	# use a stable key, but no claim entry may suppress a later purchase.
	var diagnostic_key: String = "esper|%s|sp" % esper_id
	var snapshot: String = _snapshot()
	if not bool(state.call("pay", cost)):
		_restore(snapshot)
		return _fail("payment_failed", "esper.sp.payment", {"key": diagnostic_key})
	var data: Dictionary = state.get("data")
	var section: Dictionary = _ensure_section(data, "espers")
	var owned: Dictionary = _ensure_section(section, "owned")
	entry = owned.get(esper_id, {}) if owned.get(esper_id, {}) is Dictionary else {}
	entry["sp"] = current + applied
	owned[esper_id] = entry
	var purchases_variant: Variant = section.get("sp_purchases", [])
	var purchases: Array = purchases_variant if purchases_variant is Array else []
	purchases.append({
		"esper_id": esper_id,
		"amount": amount,
		"applied": applied,
		"sp": current + applied,
		"cost": cost.duplicate(true),
		"evidence": EVIDENCE_LABEL
	})
	while purchases.size() > 50:
		purchases.remove_at(0)
	section["owned"] = owned
	section["sp_purchases"] = purchases
	data["espers"] = section
	return _commit("espers", snapshot, "esper.sp.ok", {"key": diagnostic_key, "sp": current + applied, "applied": applied})


# --- helpers -------------------------------------------------------------------

func _owned_entry(esper_id: String) -> Dictionary:
	var section: Dictionary = _read_section(state.get("data"), "espers")
	var owned: Dictionary = _read_section(section, "owned")
	var value: Variant = owned.get(esper_id, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _synthesized_stats(def: Dictionary, level: int) -> Dictionary:
	var base: Dictionary = def.get("stats", {}) if def.get("stats", {}) is Dictionary else {}
	var result: Dictionary = {}
	for stat: String in STAT_KEYS:
		var value: int = maxi(int(base.get(stat, 0)), 0)
		result[stat] = value + int(floor(float(value) * 0.05 * float(level - 1)))
	return result


func _player_level() -> int:
	var data: Dictionary = state.get("data")
	var profile_variant: Variant = data.get("profile", {})
	if profile_variant is Dictionary:
		return maxi(int((profile_variant as Dictionary).get("level", 1)), 1)
	return 1


func _has_flag(flag: String) -> bool:
	var data: Dictionary = state.get("data")
	var flags_variant: Variant = data.get("flags", {})
	if flags_variant is Dictionary:
		return bool((flags_variant as Dictionary).get(flag, false))
	var profile_variant: Variant = data.get("profile", {})
	if profile_variant is Dictionary:
		var profile_flags: Variant = (profile_variant as Dictionary).get("flags", {})
		return profile_flags is Dictionary and bool((profile_flags as Dictionary).get(flag, false))
	return false


func _clamped_cost(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not value is Dictionary:
		return result
	for key: Variant in (value as Dictionary).keys():
		result[str(key)] = maxi(int((value as Dictionary)[key]), 0)
	return result


func _read_section(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _ensure_section(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	if not value is Dictionary:
		value = {}
		data[key] = value
	return value


func _snapshot() -> String:
	return JSON.stringify(state.get("data"))


func _restore(snapshot: String) -> void:
	var parser := JSON.new()
	if parser.parse(snapshot) == OK and parser.data is Dictionary:
		state.set("data", parser.data)


func _commit(section: String, snapshot: String, message: String, extras: Dictionary) -> Dictionary:
	var error: Error = state.call("commit", section)
	if error != OK:
		_restore(snapshot)
		return _fail("save_failed", "save.error.invalid", extras)
	return _ok(message, extras)


func _ok(message: String, extras: Dictionary) -> Dictionary:
	var result: Dictionary = {"ok": true, "reason": "", "message": message, "data": {}}
	for key: Variant in extras.keys():
		var field: String = str(key)
		if field == "ok" or field == "data":
			continue
		result[field] = extras[key]
	return result


func _fail(reason: String, message: String, extras: Dictionary) -> Dictionary:
	var result: Dictionary = {"ok": false, "reason": reason, "message": message, "data": {}}
	for key: Variant in extras.keys():
		var field: String = str(key)
		if field == "ok" or field == "reason" or field == "message" or field == "data":
			continue
		result[field] = extras[key]
	return result
