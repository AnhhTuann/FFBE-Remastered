extends Node

## Writable player state. Immutable definitions come from ContentRepository;
## this service owns owned units, inventory, resources, trust, parties and locale.
## It is a separate version-3 file so version-2 slot and battle-progress saves
## remain untouched and readable.

signal state_changed(section: String)
signal load_failed(message: String)

const PLAYER_STATE_PATH := "user://player_state_v3.json"
const PLAYER_STATE_VERSION := 3
const SUPPORTED_LOCALES: Array[String] = ["vi", "en", "ja"]

var data: Dictionary = {}
var progression: RefCounted = null
var inventory: RefCounted = null
var build_resolver: RefCounted = null
var last_error: String = ""
var _loading: bool = false


func _ready() -> void:
	data = load_state()
	rebuild_systems()
	DebugLog.info("PlayerState ready (format version %d, %d owned units)" % [
		PLAYER_STATE_VERSION, (data.get("owned_units", []) as Array).size()
	])


func rebuild_systems() -> void:
	var progression_script: Script = load("res://progression/progression_system.gd") as Script
	var inventory_script: Script = load("res://progression/inventory_system.gd") as Script
	var build_script: Script = load("res://progression/build_resolver.gd") as Script
	if progression_script != null:
		progression = progression_script.new(self)
	if inventory_script != null:
		inventory = inventory_script.new(self)
	if build_script != null:
		build_resolver = build_script.new(self)


func default_state() -> Dictionary:
	var resources: Dictionary = {
		"gil": 500000,
		"lapis": 0,
		"trust_moogles": 10,
		"item:GL:800001@base": 20,
		"material:GL:900101@base": 120,
		"material:GL:900102@base": 80,
		"material:GL:900103@base": 40,
		"fragment:GL:910101@base": 0,
		"fragment:GL:910102@base": 0,
		"fragment:GL:910103@base": 0,
		"fragment:JP:910104@base": 0,
		"fragment:GL:910105@base": 0
	}
	for stat: String in ["hp", "atk", "def", "mag", "spr"]:
		resources["item:GL:81%s@base" % _pot_code(stat)] = 40

	var units: Array[Dictionary] = []
	var serial: int = 1
	for definition_id: String in [
		"unit:GL:910101@base", "unit:GL:910102@base", "unit:GL:910103@base",
		"unit:JP:910104@base", "unit:GL:910105@base", "unit:GL:910101@base"
	]:
		units.append(_new_unit_dict(definition_id, serial, "starting_fixture"))
		serial += 1

	return {
		"version": PLAYER_STATE_VERSION,
		"profile": {"locale": "vi", "favorites": [], "last_unit_id": ""},
		"resources": resources,
		"owned_units": units,
		"inventory": _default_inventory(),
		"parties": {
			"default": {
				"name_key": "party.preset.default",
				"slots": [
					"unit:GL:910101:1@base", "unit:GL:910102:2@base", "unit:GL:910103:3@base",
					"unit:JP:910104:4@base", "unit:GL:910105:5@base"
				],
				"leader_slot": 0
			}
		},
		"active_party": "default",
		"next_unit_serial": serial,
		"next_equip_serial": 1,
		"claimed_rewards": {},
		"legacy": {}
	}


func _pot_code(stat: String) -> String:
	return {"hp": "0001", "atk": "0002", "def": "0003", "mag": "0004", "spr": "0005"}.get(stat, "0000")


func _new_unit_dict(definition_id: String, serial: int, source: String) -> Dictionary:
	var parsed: Variant = ContentRepository.call("parse_composite_id", definition_id)
	var region := "GL"
	var native_id := ""
	var form := "base"
	if parsed is ContentId:
		region = str(parsed.region)
		native_id = str(parsed.native_id)
		form = str(parsed.form)
	return {
		"instance_id": "unit:%s:%s:%04d@%s" % [region, native_id, serial, form],
		"definition_id": definition_id,
		"base_id": definition_id.substr(0, definition_id.find("@")),
		"region": region,
		"native_id": native_id,
		"form": form,
		"serial": serial,
		"level": 1,
		"exp": 0,
		"star": 5,
		"ex_level": 0,
		"nv_unlocked": false,
		"nv_plus": false,
		"trust": 0,
		"tmr_claimed": false,
		"stmr_claimed": false,
		"favorite": false,
		"locked": false,
		"equipped": {},
		"pot_allocations": {},
		"learned_abilities": [],
		"awakened_abilities": [],
		"source": source
	}


func _default_inventory() -> Dictionary:
	return {
		"equipment": [
			{"uid": "owned:GL:500001:0001@blade", "definition_id": "equip:GL:500001@blade", "level": 1, "locked": false},
			{"uid": "owned:GL:500002:0002@staff", "definition_id": "equip:GL:500002@staff", "level": 1, "locked": false},
			{"uid": "owned:GL:500003:0003@shield", "definition_id": "equip:GL:500003@shield", "level": 1, "locked": false},
			{"uid": "owned:GL:510001:0004@armor", "definition_id": "equip:GL:510001@armor", "level": 1, "locked": false},
			{"uid": "owned:GL:510001:0005@armor", "definition_id": "equip:GL:510001@armor", "level": 1, "locked": false},
			{"uid": "owned:GL:520001:0006@accessory", "definition_id": "equip:GL:520001@accessory", "level": 1, "locked": false},
			{"uid": "owned:JP:520002:0007@accessory", "definition_id": "equip:JP:520002@accessory", "level": 1, "locked": false}
		],
		"materia": [
			{"uid": "owned:GL:600001:0008@base", "definition_id": "materia:GL:600001@base", "locked": false},
			{"uid": "owned:GL:600001:0009@base", "definition_id": "materia:GL:600001@base", "locked": false},
			{"uid": "owned:GL:600002:0010@base", "definition_id": "materia:GL:600002@base", "locked": false},
			{"uid": "owned:GL:600003:0011@base", "definition_id": "materia:GL:600003@base", "locked": false},
			{"uid": "owned:JP:600004:0012@base", "definition_id": "materia:JP:600004@base", "locked": false},
			{"uid": "owned:GL:600005:0013@base", "definition_id": "materia:GL:600005@base", "locked": false},
			{"uid": "owned:GL:600006:0014@base", "definition_id": "materia:GL:600006@base", "locked": false}
		],
		"vision_cards": [
			{"uid": "owned:GL:700001:0015@base", "definition_id": "vision_card:GL:700001@base", "level": 1, "locked": false},
			{"uid": "owned:JP:700002:0016@base", "definition_id": "vision_card:JP:700002@base", "level": 1, "locked": false},
			{"uid": "owned:GL:700003:0017@base", "definition_id": "vision_card:GL:700003@base", "level": 1, "locked": false}
		],
		"abilities": []
	}


func load_state() -> Dictionary:
	_loading = true
	var result: Variant = SaveManager.call("_read_json_with_fallback", PLAYER_STATE_PATH)
	_loading = false
	if result is Dictionary and bool((result as Dictionary).get("ok", false)):
		var raw: Variant = (result as Dictionary).get("data", {})
		if raw is Dictionary:
			var migrated := migrate_state(raw as Dictionary)
			if validate_state(migrated):
				last_error = ""
				return migrated
			last_error = "save.error.invalid"
			load_failed.emit(last_error)
			return default_state()
	last_error = "save.error.corrupt"
	load_failed.emit(last_error)
	return default_state()


func migrate_state(raw: Dictionary) -> Dictionary:
	if raw.is_empty():
		return default_state()
	var version: int = int(raw.get("version", 1))
	if version > PLAYER_STATE_VERSION:
		last_error = "save.error.newer"
		return {}
	var working: Dictionary = raw.duplicate(true)
	while version < PLAYER_STATE_VERSION:
		match version:
			1:
				working = _migrate_1_to_2(working)
			2:
				working = _migrate_2_to_3(working)
			_:
				return {}
		version += 1
		working["version"] = version
	if not working.has("claimed_rewards"):
		working["claimed_rewards"] = {}
	return working


func _migrate_1_to_2(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	if not result.has("profile"):
		result["profile"] = {"locale": "vi", "favorites": [], "last_unit_id": ""}
	return result


func _migrate_2_to_3(data: Dictionary) -> Dictionary:
	var fresh: Dictionary = default_state()
	var profile_variant: Variant = data.get("profile", {})
	if profile_variant is Dictionary:
		var profile: Dictionary = profile_variant
		var locale := normalize_locale(str(profile.get("locale", "vi")))
		fresh["profile"]["locale"] = locale
		var favorites_variant: Variant = profile.get("favorites", [])
		if favorites_variant is Array:
			fresh["profile"]["favorites"] = (favorites_variant as Array).duplicate()
		fresh["profile"]["last_unit_id"] = str(profile.get("last_unit_id", ""))
	var legacy: Dictionary = {}
	for key: String in ["battle_progress", "settings_summary", "version"]:
		if data.has(key):
			legacy[key] = (data[key] if not data[key] is Dictionary else (data[key] as Dictionary).duplicate(true))
	fresh["legacy"] = legacy
	return fresh


func normalize_locale(locale: String) -> String:
	var tag := locale.strip_edges().replace("-", "_").to_lower()
	for supported: String in SUPPORTED_LOCALES:
		if tag.begins_with(supported):
			return supported
	return "vi"


func validate_state(state: Dictionary) -> bool:
	if int(state.get("version", 0)) != PLAYER_STATE_VERSION:
		return false
	if not (state.get("owned_units", []) is Array) or not (state.get("inventory", {}) is Dictionary):
		return false
	if not (state.get("parties", {}) is Dictionary) or not (state.get("resources", {}) is Dictionary):
		return false
	if not (state.get("claimed_rewards", {}) is Dictionary):
		return false
	var seen: Dictionary = {}
	for entry: Variant in state.get("owned_units", []):
		if not entry is Dictionary:
			return false
		var uid := str((entry as Dictionary).get("instance_id", ""))
		if uid.is_empty() or seen.has(uid):
			return false
		seen[uid] = true
	var locale := normalize_locale(str((state.get("profile", {}) as Dictionary).get("locale", "vi")))
	if not SUPPORTED_LOCALES.has(locale):
		return false
	return true


func save() -> Error:
	if _loading:
		return OK
	if not validate_state(data):
		return ERR_INVALID_DATA
	var error: Error = SaveManager.call("atomic_write", PLAYER_STATE_PATH, data)
	if error != OK:
		last_error = "save.error.invalid"
		return error
	last_error = ""
	return OK


func commit(section: String) -> Error:
	var error: Error = save()
	if error == OK:
		state_changed.emit(section)
	return error


func reset_to_defaults() -> Error:
	data = default_state()
	rebuild_systems()
	return commit("reset")


func get_resources() -> Dictionary:
	return (data.get("resources", {}) as Dictionary).duplicate(true)


func get_resource(key: String) -> int:
	var resources: Dictionary = data.get("resources", {})
	return maxi(int(resources.get(key, 0)), 0)


func can_pay(cost: Dictionary) -> bool:
	for key: String in cost.keys():
		if get_resource(key) < maxi(int(cost[key]), 0):
			return false
	return true


func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	var resources: Dictionary = data.get("resources", {})
	for key: String in cost.keys():
		resources[key] = get_resource(key) - maxi(int(cost[key]), 0)
	data["resources"] = resources
	return true


func grant(reward: Dictionary) -> void:
	var resources: Dictionary = data.get("resources", {})
	for key: String in reward.keys():
		resources[key] = get_resource(key) + maxi(int(reward[key]), 0)
	data["resources"] = resources


func owned_units() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Variant in data.get("owned_units", []):
		if entry is Dictionary:
			result.append(entry as Dictionary)
	return result


func get_unit_instance(instance_id: String) -> Dictionary:
	for entry: Dictionary in owned_units():
		if str(entry.get("instance_id", "")) == instance_id:
			return entry.duplicate(true)
	return {}


func mutate_unit_instance(instance_id: String, patch: Dictionary) -> bool:
	var units_variant: Variant = data.get("owned_units", [])
	if not units_variant is Array:
		return false
	var units: Array = units_variant as Array
	for index: int in range(units.size()):
		if not units[index] is Dictionary:
			continue
		var entry: Dictionary = units[index]
		if str(entry.get("instance_id", "")) == instance_id:
			entry.merge(patch, true)
			units[index] = entry
			data["owned_units"] = units
			return true
	return false


func grant_unit(definition_id: String, source: String = "granted") -> String:
	var serial: int = maxi(int(data.get("next_unit_serial", 1)), 1)
	var entry: Dictionary = _new_unit_dict(definition_id, serial, source)
	var units_variant: Variant = data.get("owned_units", [])
	var units: Array = units_variant if units_variant is Array else []
	(units as Array).append(entry)
	data["owned_units"] = units
	data["next_unit_serial"] = serial + 1
	commit("units")
	return str(entry["instance_id"])


func inventory_section(section: String) -> Array[Dictionary]:
	var inventory: Dictionary = data.get("inventory", {})
	var result: Array[Dictionary] = []
	for entry: Variant in inventory.get(section, []):
		if entry is Dictionary:
			result.append(entry as Dictionary)
	return result


func find_inventory_entry(uid: String) -> Dictionary:
	for section: String in ["equipment", "materia", "vision_cards", "abilities"]:
		for entry: Dictionary in inventory_section(section):
			if str(entry.get("uid", "")) == uid:
				var copy: Dictionary = entry.duplicate(true)
				copy["_section"] = section
				return copy
	return {}


func next_equip_serial() -> int:
	var serial: int = maxi(int(data.get("next_equip_serial", 1)), 1)
	data["next_equip_serial"] = serial + 1
	return serial


func parties() -> Dictionary:
	var result: Variant = data.get("parties", {})
	return result.duplicate(true) if result is Dictionary else {}


func get_party(party_id: String) -> Dictionary:
	var all_parties: Dictionary = parties()
	var result: Variant = all_parties.get(party_id, {})
	return result.duplicate(true) if result is Dictionary else {}


func set_party(party_id: String, party: Dictionary) -> void:
	var all_parties: Dictionary = parties()
	all_parties[party_id] = party.duplicate(true)
	data["parties"] = all_parties


func definition_for(instance: Dictionary) -> Dictionary:
	return ContentRepository.call("get_unit_definition", str(instance.get("definition_id", "")))


func locale() -> String:
	return normalize_locale(str((data.get("profile", {}) as Dictionary).get("locale", "vi")))


func set_locale(locale: String) -> void:
	var normalized := normalize_locale(locale)
	var profile_variant: Variant = data.get("profile", {})
	var profile: Dictionary = profile_variant if profile_variant is Dictionary else {}
	profile["locale"] = normalized
	data["profile"] = profile
	commit("profile")


## Deterministic idempotency key for a battle result. The same encounter, seed,
## turn count and reward snapshot can only be claimed once, even after a reload.
func battle_reward_key(result: Dictionary) -> String:
	var rewards_variant: Variant = result.get("rewards", {})
	var rewards: Dictionary = rewards_variant if rewards_variant is Dictionary else {}
	var items_variant: Variant = rewards.get("items", [])
	var items: Array = items_variant if items_variant is Array else []
	var parts: Array[String] = [
		"battle",
		str(result.get("encounter_id", "")),
		str(result.get("seed", 0)),
		str(result.get("turns", 0)),
		str(bool(result.get("victory", false))),
		str(rewards.get("gil", 0))
	]
	for item: Variant in items:
		parts.append(str(item))
	return "|".join(parts)


func claim_battle_reward(result: Dictionary) -> Dictionary:
	if not bool(result.get("victory", false)):
		return {"ok": false, "reason": "not_victory", "key": ""}
	var key := battle_reward_key(result)
	var claimed_variant: Variant = data.get("claimed_rewards", {})
	var claimed: Dictionary = claimed_variant if claimed_variant is Dictionary else {}
	if claimed.has(key):
		return {"ok": false, "reason": "already_claimed", "key": key, "message": "save.error.invalid"}
	claimed[key] = {
		"encounter_id": str(result.get("encounter_id", "")),
		"seed": int(result.get("seed", 0)),
		"turns": int(result.get("turns", 0))
	}
	data["claimed_rewards"] = claimed
	var rewards_variant: Variant = result.get("rewards", {})
	var rewards: Dictionary = rewards_variant if rewards_variant is Dictionary else {}
	var grant: Dictionary = {"gil": maxi(int(rewards.get("gil", 0)), 0)}
	var items_variant: Variant = rewards.get("items", [])
	if items_variant is Array:
		for item: Variant in items_variant:
			var item_id := str(item)
			if not item_id.is_empty():
				grant[item_id] = int(grant.get(item_id, 0)) + 1
	grant(grant)
	var error: Error = commit("rewards")
	if error != OK:
		return {"ok": false, "reason": "save_failed", "key": key, "message": "save.error.invalid"}
	return {"ok": true, "reason": "", "key": key, "message": "save.saved", "rewards": grant}
