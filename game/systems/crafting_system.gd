class_name CraftingSystem
extends RefCounted

## Prompt 05 synthetic crafting system. Jobs are local-only, use synthetic
## recipes and settle from an explicit timestamp; claims and refunds are
## idempotent through namespaced PlayerState claim keys.

const EVIDENCE_LABEL := "REMASTERED_DESIGN"

var state: Node = null


func _init(p_state: Node) -> void:
	state = p_state


func _repo() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("ContentRepository") if tree != null else null


func recipes() -> Dictionary:
	return _repo().call("get_crafting_recipes")


func recipe(recipe_id: String) -> Dictionary:
	return _repo().call("get_crafting_recipe", recipe_id)


func start(recipe_id: String, now_unix: int = -1) -> Dictionary:
	var def: Dictionary = recipe(recipe_id)
	if def.is_empty():
		return _fail("unknown_recipe", "craft.recipe.unknown", {"key": recipe_id})
	var requirements: Dictionary = def.get("requirements", {}) if def.get("requirements", {}) is Dictionary else {}
	var required_flags: Array = requirements.get("required_flags", []) if requirements.get("required_flags", []) is Array else []
	for flag_variant: Variant in required_flags:
		if not _has_flag(str(flag_variant)):
			return _fail("flag_required", "craft.flag", {"key": recipe_id, "flag": str(flag_variant)})
	var min_level: int = maxi(int(requirements.get("min_level", 1)), 1)
	if _player_level() < min_level:
		return _fail("level_required", "craft.level", {"key": recipe_id})
	var inputs: Dictionary = _clamped_cost(def.get("inputs", {}))
	if inputs.is_empty():
		return _fail("invalid_inputs", "craft.inputs", {"key": recipe_id})
	if not state.call("can_pay", inputs):
		return _fail("insufficient_resources", "craft.resources", {"key": recipe_id})

	var now: int = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	now = maxi(now, 0)
	var duration: int = maxi(int(def.get("duration_seconds", 0)), 1)
	var snapshot: String = _snapshot()
	if not bool(state.call("pay", inputs)):
		_restore(snapshot)
		return _fail("payment_failed", "craft.payment", {"key": recipe_id})
	var data: Dictionary = state.get("data")
	var section: Dictionary = _ensure_section(data, "crafting")
	var jobs: Dictionary = _ensure_section(section, "jobs")
	var sequence: int = maxi(int(section.get("next_job_seq", 1)), maxi(jobs.size() + 1, 1))
	while jobs.has("craft:%d" % sequence):
		sequence += 1
	var job_id: String = "craft:%d" % sequence
	var job: Dictionary = {
		"id": job_id,
		"recipe_id": recipe_id,
		"status": "in_progress",
		"created_at": now,
		"ready_at": now + duration,
		"duration_seconds": duration,
		"inputs": inputs.duplicate(true),
		"outputs": (def.get("outputs", {}) as Dictionary).duplicate(true),
		"receipt_prefix": str(def.get("receipt_prefix", "")),
		"evidence": EVIDENCE_LABEL
	}
	jobs[job_id] = job
	section["jobs"] = jobs
	section["next_job_seq"] = sequence + 1
	data["crafting"] = section
	return _commit("crafting", snapshot, "craft.start.ok", {"key": job_id, "job": job.duplicate(true)})


func status() -> Dictionary:
	var now: int = int(Time.get_unix_time_from_system())
	var section: Dictionary = _read_section(state.get("data"), "crafting")
	var jobs: Dictionary = _read_section(section, "jobs")
	var result: Dictionary = {}
	for job_id: Variant in jobs.keys():
		var job: Dictionary = jobs[job_id] if jobs[job_id] is Dictionary else {}
		var derived: String = str(job.get("status", "in_progress"))
		if derived == "in_progress" and now >= int(job.get("ready_at", 0)):
			derived = "claimable"
		var copy: Dictionary = job.duplicate(true)
		copy["derived_status"] = derived
		result[str(job_id)] = copy
	return _ok("craft.status.ready", {"jobs": result, "now_unix": now})


func settle(now_unix: int) -> Dictionary:
	var now: int = maxi(now_unix, 0)
	var section: Dictionary = _read_section(state.get("data"), "crafting")
	var jobs: Dictionary = _read_section(section, "jobs")
	var changed: Array[String] = []
	for job_id: Variant in jobs.keys():
		var job: Dictionary = jobs[job_id] if jobs[job_id] is Dictionary else {}
		if str(job.get("status", "")) == "in_progress" and now >= maxi(int(job.get("ready_at", 0)), 0):
			changed.append(str(job_id))
	if changed.is_empty():
		return _ok("craft.settle.noop", {"changed": changed, "now_unix": now})

	var snapshot: String = _snapshot()
	var data: Dictionary = state.get("data")
	section = _ensure_section(data, "crafting")
	jobs = _ensure_section(section, "jobs")
	for job_id: String in changed:
		var job: Dictionary = jobs[job_id] if jobs[job_id] is Dictionary else {}
		job["status"] = "claimable"
		job["settled_at"] = now
		jobs[job_id] = job
	section["jobs"] = jobs
	data["crafting"] = section
	return _commit("crafting", snapshot, "craft.settle.ok", {"changed": changed, "now_unix": now})


func claim(job_id: String) -> Dictionary:
	var section: Dictionary = _read_section(state.get("data"), "crafting")
	var jobs: Dictionary = _read_section(section, "jobs")
	if not jobs.has(job_id):
		return _fail("unknown_job", "craft.job.unknown", {"key": job_id})
	var job_variant: Variant = jobs.get(job_id, {})
	if not job_variant is Dictionary:
		return _fail("unknown_job", "craft.job.unknown", {"key": job_id})
	var job: Dictionary = job_variant
	var claim_key: String = "craft|%s|claim" % job_id
	var claims: Dictionary = _read_section(section, "claims")
	if claims.has(claim_key):
		return _fail("already_claimed", "craft.claim.claimed", {"key": claim_key})
	if str(job.get("status", "")) != "claimable":
		return _fail("not_claimable", "craft.job.claimable", {"key": job_id})

	var outputs: Dictionary = _clamped_cost(job.get("outputs", {}))
	var snapshot: String = _snapshot()
	var granted: Dictionary = {}
	var uids: Array[String] = []
	for output_id: String in outputs.keys():
		var grant_result: Dictionary = _grant_output(output_id, outputs[output_id], "crafting_claim")
		if not bool(grant_result.get("ok", false)):
			_restore(snapshot)
			return _fail(str(grant_result.get("reason", "grant_failed")), "craft.grant", {"key": claim_key})
		uids.append_array(grant_result.get("uids", []) as Array[String])
		granted.merge(grant_result.get("granted", {}) as Dictionary, true)

	var data: Dictionary = state.get("data")
	section = _ensure_section(data, "crafting")
	jobs = _ensure_section(section, "jobs")
	claims = _ensure_section(section, "claims")
	job = jobs.get(job_id, {}) if jobs.get(job_id, {}) is Dictionary else {}
	job["status"] = "claimed"
	job["claimed_at"] = int(Time.get_unix_time_from_system())
	jobs[job_id] = job
	claims[claim_key] = {"job_id": job_id, "outputs": granted.duplicate(true), "evidence": EVIDENCE_LABEL}
	section["jobs"] = jobs
	section["claims"] = claims
	data["crafting"] = section
	return _commit("crafting", snapshot, "craft.claim.ok", {"key": claim_key, "granted": granted, "uids": uids})


func cancel(job_id: String, now_unix: int = -1) -> Dictionary:
	var section: Dictionary = _read_section(state.get("data"), "crafting")
	var jobs: Dictionary = _read_section(section, "jobs")
	if not jobs.has(job_id):
		return _fail("unknown_job", "craft.job.unknown", {"key": job_id})
	var job_variant: Variant = jobs.get(job_id, {})
	if not job_variant is Dictionary:
		return _fail("unknown_job", "craft.job.unknown", {"key": job_id})
	var job: Dictionary = job_variant
	if str(job.get("status", "")) != "in_progress":
		return _fail("job_ready", "craft.cancel.ready", {"key": job_id})
	var now: int = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	if now >= maxi(int(job.get("ready_at", 0)), 0):
		return _fail("job_ready", "craft.cancel.ready", {"key": job_id})
	var claim_key: String = "craft|%s|refund" % job_id
	var claims: Dictionary = _read_section(section, "claims")
	if claims.has(claim_key):
		return _fail("already_claimed", "craft.refund.claimed", {"key": claim_key})

	var refund: Dictionary = _clamped_cost(job.get("inputs", {}))
	var snapshot: String = _snapshot()
	state.call("grant", refund)
	var data: Dictionary = state.get("data")
	section = _ensure_section(data, "crafting")
	jobs = _ensure_section(section, "jobs")
	claims = _ensure_section(section, "claims")
	job = jobs.get(job_id, {}) if jobs.get(job_id, {}) is Dictionary else {}
	job["status"] = "cancelled"
	job["cancelled_at"] = now
	jobs[job_id] = job
	claims[claim_key] = {"job_id": job_id, "refund": refund.duplicate(true), "evidence": EVIDENCE_LABEL}
	section["jobs"] = jobs
	section["claims"] = claims
	data["crafting"] = section
	return _commit("crafting", snapshot, "craft.cancel.ok", {"key": claim_key, "refund": refund})


# --- item/resource grant -------------------------------------------------------

func _grant_output(definition_id: String, quantity: int, source: String) -> Dictionary:
	var section_name: String = ""
	if not _repo().call("get_equipment_definition", definition_id).is_empty():
		section_name = "equipment"
	elif not _repo().call("get_materia_definition", definition_id).is_empty():
		section_name = "materia"
	elif not _repo().call("get_vision_card_definition", definition_id).is_empty():
		section_name = "vision_cards"
	else:
		state.call("grant", {definition_id: maxi(quantity, 0)})
		return _ok("craft.resource_grant", {"granted": {definition_id: maxi(quantity, 0)}, "uids": [] as Array[String]})
	var parsed: ContentId = ContentId.parse(definition_id)
	if parsed == null or not parsed.is_valid():
		return _fail("invalid_definition", "craft.definition", {})
	var data: Dictionary = state.get("data")
	var inventory: Dictionary = _read_section(data, "inventory")
	var entries: Array = inventory.get(section_name, []) if inventory.get(section_name, []) is Array else []
	var uids: Array[String] = []
	for index: int in range(maxi(quantity, 0)):
		var uid: String = _unique_equip_uid(parsed, entries)
		entries.append({
			"uid": uid,
			"definition_id": definition_id,
			"level": 1,
			"locked": false,
			"source": source
		})
		uids.append(uid)
	inventory[section_name] = entries
	data = state.get("data")
	data["inventory"] = inventory
	return _ok("craft.item_grant", {"granted": {definition_id: maxi(quantity, 0)}, "uids": uids})


# --- helpers -------------------------------------------------------------------

func _unique_equip_uid(parsed: ContentId, entries: Array) -> String:
	var taken: Dictionary = {}
	for entry_variant: Variant in entries:
		if entry_variant is Dictionary:
			taken[str((entry_variant as Dictionary).get("uid", ""))] = true
	var serial: int = maxi(int(state.call("next_equip_serial")), 1)
	var uid: String = ""
	while true:
		uid = "owned:%s:%s:%04d@%s" % [parsed.region, parsed.native_id, serial, parsed.form]
		if not taken.has(uid):
			break
		serial += 1
	var data: Dictionary = state.get("data")
	data["next_equip_serial"] = serial + 1
	return uid


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


func _player_level() -> int:
	var data: Dictionary = state.get("data")
	var profile_variant: Variant = data.get("profile", {})
	if profile_variant is Dictionary:
		return maxi(int((profile_variant as Dictionary).get("level", 1)), 1)
	return 1


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
