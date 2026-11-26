class_name SummonSystem
extends RefCounted

## Prompt 05 synthetic summon system. RNG is locked to (seed, banner id,
## receipt); process-global RNG is never used. Costs, weights and guarantees
## come exclusively from SYNTHETIC_FIXTURE banner data. grant_unit() commits
## internally, so a successful summon performs no second commit.

const HISTORY_LIMIT := 200
const MAX_RECEIPT_LENGTH := 128
const EVIDENCE_LABEL := "REMASTERED_DESIGN"

var state: Node = null


func _init(p_state: Node) -> void:
	state = p_state


func _repo() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("ContentRepository") if tree != null else null


func banners() -> Dictionary:
	return _repo().call("get_summon_banners")


func banner(banner_id: String) -> Dictionary:
	return _repo().call("get_summon_banner", banner_id)


func cost(banner_id: String) -> Dictionary:
	var def: Dictionary = banner(banner_id)
	var value: Variant = def.get("cost", {})
	return _clamped_cost(value) if value is Dictionary else {}


## Receipts are idempotency identities, not free text. Surrounding whitespace is
## normalized away; empty and oversized receipts are rejected before any charge.
func normalize_receipt(receipt: String) -> String:
	var trimmed: String = receipt.strip_edges()
	if trimmed.is_empty() or trimmed.length() > MAX_RECEIPT_LENGTH:
		return ""
	return trimmed


func summon(banner_id: String, seed: int, receipt: String = "") -> Dictionary:
	var normalized: String = normalize_receipt(receipt)
	if normalized.is_empty():
		return _fail("invalid_receipt", "reason.invalid_receipt", {
			"key": "", "receipt_length": receipt.length(), "max_length": MAX_RECEIPT_LENGTH
		})
	var def: Dictionary = banner(banner_id)
	if def.is_empty():
		return _fail("unknown_banner", "summon.unknown", {"key": banner_id})
	var cost_map: Dictionary = cost(banner_id)
	if cost_map.is_empty():
		return _fail("invalid_cost", "summon.cost", {"key": banner_id})
	var claim_key: String = "summon|%s|%s" % [banner_id, normalized]
	var data: Dictionary = state.get("data")
	var section: Dictionary = _read_section(data, "summon")
	var claims: Dictionary = _read_section(section, "claims")
	if claims.has(claim_key):
		return _fail("already_claimed", "summon.claimed", {"key": claim_key})
	if not state.call("can_pay", cost_map):
		return _fail("insufficient_resources", "summon.resources", {"key": claim_key})

	var safe_seed: int = maxi(seed, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = safe_seed + banner_id.hash() + normalized.hash()
	var pity: Dictionary = _read_section(section, "pity")
	var previous_pity: int = clampi(int(pity.get(banner_id, 0)), 0, 1000000)
	var pity_after_draw: int = previous_pity + 1
	var guarantee: Dictionary = def.get("guarantee", {}) if def.get("guarantee", {}) is Dictionary else {}
	var pool: Array = def.get("pool", []) if def.get("pool", []) is Array else []
	if pool.is_empty():
		return _fail("invalid_pool", "summon.pool", {"key": claim_key})
	var guaranteed: bool = int(guarantee.get("within", 0)) > 0 and pity_after_draw >= maxi(int(guarantee.get("within", 0)), 1)
	var chosen: String = ""
	if guaranteed and str(guarantee.get("type", "")) == "unit_id":
		var forced: String = str(guarantee.get("unit_id", ""))
		if pool.has(forced):
			chosen = forced
	if chosen.is_empty():
		chosen = _weighted_pick(def, rng)
	if chosen.is_empty():
		return _fail("invalid_pool", "summon.pool", {"key": claim_key})

	var pity_rule: Dictionary = def.get("pity", {}) if def.get("pity", {}) is Dictionary else {}
	var resets: bool = guaranteed and bool(pity_rule.get("reset_after_guarantee", true))
	var new_pity: int = 0 if resets else pity_after_draw

	var snapshot: String = _snapshot()
	if not bool(state.call("pay", cost_map)):
		_restore(snapshot)
		return _fail("payment_failed", "summon.payment", {"key": claim_key})
	data = state.get("data")
	section = _ensure_section(data, "summon")
	pity = _ensure_section(section, "pity")
	claims = _ensure_section(section, "claims")
	pity[banner_id] = new_pity
	var claim_record: Dictionary = {
		"banner_id": banner_id,
		"seed": safe_seed,
		"receipt": normalized,
		"unit_id": chosen,
		"pity_before": previous_pity,
		"pity_after": new_pity,
		"guaranteed": guaranteed,
		"evidence": EVIDENCE_LABEL
	}
	claims[claim_key] = claim_record
	var history_variant: Variant = section.get("history", [])
	var history: Array = history_variant if history_variant is Array else []
	history.append({
		"banner_id": banner_id,
		"seed": safe_seed,
		"receipt": normalized,
		"unit_id": chosen,
		"guaranteed": guaranteed,
		"source": "synthetic_summon"
	})
	while history.size() > HISTORY_LIMIT:
		history.remove_at(0)
	section["history"] = history
	section["pity"] = pity
	section["claims"] = claims
	data["summon"] = section

	# grant_unit() appends the owned instance and commits the save. It returns an
	# empty ID when that commit fails, so the whole summon is restored below.
	# No further commit is issued on the success path; this claim/pity/history
	# snapshot is included in that same write.
	var instance_id: String = str(state.call("grant_unit", chosen, "summon"))
	if instance_id.is_empty():
		_restore(snapshot)
		state.call("commit", "summon")
		return _fail("grant_failed", "summon.grant", {"key": claim_key})
	return _ok("summon.ok", {
		"key": claim_key,
		"banner_id": banner_id,
		"unit_id": chosen,
		"instance_id": instance_id,
		"guaranteed": guaranteed,
		"pity": new_pity,
		"pity_rule": maxi(int(pity_rule.get("threshold", 0)), 0),
		"guarantee_within": maxi(int(guarantee.get("within", 0)), 0),
		"evidence": EVIDENCE_LABEL
	})


func history() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var section: Dictionary = _read_section(state.get("data"), "summon")
	var value: Variant = section.get("history", [])
	if value is Array:
		for entry: Variant in value as Array:
			if entry is Dictionary:
				result.append(entry)
	return result


# --- helpers -------------------------------------------------------------------

func _weighted_pick(def: Dictionary, rng: RandomNumberGenerator) -> String:
	var pool: Array = def.get("pool", []) if def.get("pool", []) is Array else []
	var weights: Dictionary = def.get("weights", {}) if def.get("weights", {}) is Dictionary else {}
	var total: int = 0
	for unit_variant: Variant in pool:
		total += maxi(int(weights.get(str(unit_variant), 0)), 0)
	if total <= 0:
		return ""
	var roll: int = rng.randi_range(0, total - 1)
	var cursor: int = 0
	for unit_variant: Variant in pool:
		cursor += maxi(int(weights.get(str(unit_variant), 0)), 0)
		if roll < cursor:
			return str(unit_variant)
	return str(pool[pool.size() - 1])


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
