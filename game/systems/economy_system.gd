class_name EconomySystem
extends RefCounted

## Prompt 05 synthetic offline economy. All caps, rates and party modifiers
## come from SYNTHETIC_FIXTURE data. status() is read-only; settle() grants once
## per away period and commits exactly once. A capped period pays at most
## cap_seconds but consumes the full elapsed interval on success, so repeated
## settle() calls with the same now_unix cannot mint another capped claim.

const EVIDENCE_LABEL := "REMASTERED_DESIGN"
const CURRENCY_KEYS: Array[String] = ["gil", "lapis", "trust_moogles"]

var state: Node = null


func _init(p_state: Node) -> void:
	state = p_state


func _repo() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("ContentRepository") if tree != null else null


func rules() -> Dictionary:
	return _repo().call("get_offline_economy_rules")


func status(now_unix: int) -> Dictionary:
	var window: Dictionary = _window(now_unix)
	if not bool(window.get("ok", false)):
		return window
	return _ok("economy.status.ready", window)


func settle(now_unix: int) -> Dictionary:
	var window: Dictionary = _window(now_unix)
	if not bool(window.get("ok", false)):
		return window
	var claim_key: String = str(window.get("claim_key", ""))
	var data: Dictionary = state.get("data")
	var section: Dictionary = _read_section(data, "economy")
	var claims: Dictionary = _read_section(section, "claims")
	if claims.has(claim_key):
		return _fail("already_claimed", "economy.settle.claimed", window)
	if int(window.get("pending_seconds", 0)) <= 0:
		var last_settled: int = maxi(int(section.get("last_settled_unix", 0)), 0)
		if now_unix >= last_settled:
			for claim_variant: Variant in claims.values():
				if claim_variant is Dictionary and int((claim_variant as Dictionary).get("window_end", -1)) == last_settled:
					return _fail("already_claimed", "economy.settle.claimed", window)
		return _fail(str(window.get("reason", "no_pending_time")), "economy.settle.empty", window)

	var reward: Dictionary = window.get("resources", {}) if window.get("resources", {}) is Dictionary else {}
	var snapshot: String = _snapshot()
	state.call("grant", reward)
	data = state.get("data")
	section = _ensure_section(data, "economy")
	claims = _ensure_section(section, "claims")
	claims[claim_key] = {
		"window_start": int(window.get("window_start", 0)),
		"window_end": int(window.get("window_end", 0)),
		"consumed_until": int(window.get("consumed_until", window.get("window_end", 0))),
		"elapsed_seconds": int(window.get("elapsed_seconds", 0)),
		"reward_seconds": int(window.get("reward_seconds", 0)),
		"capped": bool(window.get("capped", false)),
		"resources": reward.duplicate(true),
		"evidence": EVIDENCE_LABEL
	}
	section["claims"] = claims
	section["last_settled_unix"] = int(window.get("consumed_until", window.get("window_end", 0)))
	data["economy"] = section
	return _commit("economy", snapshot, "economy.settle.ok", {
		"key": claim_key,
		"granted": reward,
		"window_start": int(window.get("window_start", 0)),
		"window_end": int(window.get("window_end", 0)),
		"consumed_until": int(window.get("consumed_until", window.get("window_end", 0))),
		"elapsed_seconds": int(window.get("elapsed_seconds", 0)),
		"reward_seconds": int(window.get("reward_seconds", 0)),
		"capped": bool(window.get("capped", false)),
		"modifier": str(window.get("modifier", ""))
	})


# --- window calculation --------------------------------------------------------

func _window(now_unix: int) -> Dictionary:
	if now_unix < 0:
		return _fail("invalid_time", "economy.time.invalid", {"pending_seconds": 0, "resources": {}})
	var rules_map: Dictionary = rules()
	if rules_map.is_empty():
		return _fail("no_rules", "economy.rules.missing", {"pending_seconds": 0, "resources": {}})
	var rule_keys: Array[String] = []
	for key: Variant in rules_map.keys():
		rule_keys.append(str(key))
	rule_keys.sort()
	var rule_id: String = str(_repo().call("get_offline_economy_default_rule_id"))
	if rule_id.is_empty() or not rules_map.has(rule_id):
		rule_id = rule_keys[0]
	var rule: Dictionary = rules_map.get(rule_id, {})
	var cap_seconds: int = maxi(int(rule.get("cap_seconds", 0)), 0)
	var minimum_interval: int = maxi(int(rule.get("minimum_interval_seconds", 0)), 0)
	var data: Dictionary = state.get("data")
	var section: Dictionary = _read_section(data, "economy")
	var last_settled: int = maxi(int(section.get("last_settled_unix", 0)), 0)
	if now_unix <= last_settled:
		return _ok("economy.status.ready", {
			"rule_id": rule_id,
			"pending_seconds": 0,
			"reward_seconds": 0,
			"elapsed_seconds": 0,
			"capped": false,
			"window_start": last_settled,
			"window_end": last_settled,
			"consumed_until": last_settled,
			"resources": {},
			"modifier": "",
			"claim_key": "offline|%d|%d" % [last_settled, last_settled],
			"reason": "no_pending_time"
		})
	var elapsed: int = now_unix - last_settled
	var pending: int = mini(elapsed, cap_seconds)
	if pending < minimum_interval:
		return _ok("economy.status.ready", {
			"rule_id": rule_id,
			"pending_seconds": 0,
			"reward_seconds": 0,
			"elapsed_seconds": elapsed,
			"capped": elapsed > cap_seconds,
			"window_start": last_settled,
			"window_end": last_settled,
			"consumed_until": last_settled,
			"resources": {},
			"modifier": "",
			"claim_key": "offline|%d|%d" % [last_settled, last_settled],
			"reason": "minimum_interval"
		})
	# The reward window is capped, but the whole away period is consumed on a
	# successful settle. window_end therefore equals the elapsed-period end and
	# becomes the next last_settled_unix; reward_seconds records the paid cap.
	var window_end: int = now_unix
	var modifier_id: String = ""
	var multiplier: int = 100
	var modifiers: Array = rule.get("party_modifiers", []) if rule.get("party_modifiers", []) is Array else []
	var members: int = _active_party_size(data)
	for modifier_variant: Variant in modifiers:
		if not modifier_variant is Dictionary:
			continue
		var modifier: Dictionary = modifier_variant
		var min_members: int = maxi(int(modifier.get("min_members", 0)), 0)
		var max_members: int = maxi(int(modifier.get("max_members", 999)), 0)
		if members >= min_members and members <= max_members:
			multiplier = maxi(int(modifier.get("multiplier_percent", 100)), 1)
			modifier_id = str(modifier.get("id", ""))
			break
	var rates: Dictionary = rule.get("rates_per_hour", {}) if rule.get("rates_per_hour", {}) is Dictionary else {}
	var caps: Dictionary = rule.get("cap_per_resource", {}) if rule.get("cap_per_resource", {}) is Dictionary else {}
	var reward: Dictionary = {}
	for key: Variant in rates.keys():
		var resource_id: String = str(key)
		if resource_id.is_empty():
			continue
		var per_hour: int = maxi(int(rates[key]), 0)
		var cap: int = maxi(int(caps.get(resource_id, 0)), 0)
		var amount: int = int(float(per_hour) * float(pending) / 3600.0)
		amount = int(float(amount) * float(multiplier) / 100.0)
		if cap > 0:
			amount = mini(amount, cap)
		reward[resource_id] = maxi(amount, 0)
	return {
		"ok": true,
		"reason": "",
		"rule_id": rule_id,
		"pending_seconds": pending,
		"reward_seconds": pending,
		"elapsed_seconds": elapsed,
		"capped": elapsed > cap_seconds,
		"window_start": last_settled,
		"window_end": window_end,
		"consumed_until": window_end,
		"resources": reward,
		"modifier": modifier_id,
		"multiplier_percent": multiplier,
		"claim_key": "offline|%d|%d" % [last_settled, window_end],
		"evidence": EVIDENCE_LABEL
	}


func _active_party_size(data: Dictionary) -> int:
	var parties_variant: Variant = data.get("parties", {})
	if not parties_variant is Dictionary:
		return 0
	var parties: Dictionary = parties_variant
	var active_id: String = str(data.get("active_party", "default"))
	var party_variant: Variant = parties.get(active_id, {})
	if not party_variant is Dictionary:
		return 0
	var slots_variant: Variant = (party_variant as Dictionary).get("slots", [])
	return (slots_variant as Array).size() if slots_variant is Array else 0


# --- transaction helpers -------------------------------------------------------

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
