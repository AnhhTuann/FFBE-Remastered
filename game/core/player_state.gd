extends Node

## Writable player state. Immutable definitions come from ContentRepository;
## this service owns owned units, inventory, resources, trust, parties and locale.
## It remains in the version-3 filename so version-2 slot and battle-progress
## saves stay untouched; the in-file format is version 4 with additive v4 sections.
## Prompt 06 adds an additive `world` section without bumping the format version:
## v1-v4 saves are normalized through `_ensure_world_state()` and a migration
## backup is made before any on-disk state is rewritten.
## Fresh and migrated profiles anchor economy.last_settled_unix at creation time
## so an epoch-zero save cannot claim historical offline rewards.

signal state_changed(section: String)
signal load_failed(message: String)

const PLAYER_STATE_PATH := "user://player_state_v3.json"
const PLAYER_STATE_VERSION := 4
const SUPPORTED_LOCALES: Array[String] = ["vi", "en", "ja"]
const WORLD_REGION_ID := "region:GL:1001@vale"
const WORLD_START_LOCATION := "loc:GL:1101@haven"

## Sticky load states. Once a future/invalid save is detected the profile is
## locked: no commit, reward claim, quest/inventory mutation, migration, reset
## or backup may overwrite the on-disk bytes while the owner can still recover.
const SAVE_STATUS_NORMAL := "NORMAL"
const SAVE_STATUS_MIGRATING := "MIGRATING"
const SAVE_STATUS_READ_ONLY_FUTURE_VERSION := "READ_ONLY_FUTURE_VERSION"
const SAVE_STATUS_LOAD_FAILED := "LOAD_FAILED"

var data: Dictionary = {}
var progression: RefCounted = null
var inventory: RefCounted = null
var build_resolver: RefCounted = null
var last_error: String = ""
var save_status: String = SAVE_STATUS_NORMAL
var read_only_reason: String = ""
var _loading: bool = false
var _transaction_depth: int = 0
var _pending_battle_result: Dictionary = {}
var _pending_battle_context: Dictionary = {}
var _pending_battle_kind: String = ""


func _ready() -> void:
	data = load_state()
	rebuild_systems()
	DebugLog.info("PlayerState ready (format version %d, %d owned units)" % [
		PLAYER_STATE_VERSION, (data.get("owned_units", []) as Array).size()
	])


func get_save_status() -> String:
	return save_status


func set_save_status(status: String, reason: String = "") -> void:
	save_status = status
	read_only_reason = reason
	# MIGRATING is an in-memory phase: it may still write the one-generation
	# .mig.bak copy. Only terminal failure states lock the target bytes.
	var locked: bool = status == SAVE_STATUS_READ_ONLY_FUTURE_VERSION or status == SAVE_STATUS_LOAD_FAILED
	SaveManager.call("set_path_read_only", PLAYER_STATE_PATH, locked)


func _write_guard_error() -> Error:
	if save_status == SAVE_STATUS_NORMAL:
		return OK
	last_error = read_only_reason if not read_only_reason.is_empty() else "save.error.read_only"
	return ERR_FILE_NO_PERMISSION


func is_write_allowed() -> bool:
	return _write_guard_error() == OK


func get_pending_battle_result() -> Dictionary:
	return _pending_battle_result.duplicate(true)


func get_pending_battle_context() -> Dictionary:
	return _pending_battle_context.duplicate(true)


func get_pending_battle_kind() -> String:
	return _pending_battle_kind


func has_pending_battle_settlement() -> bool:
	return not _pending_battle_result.is_empty()


## Replays the failed settlement with its preserved result and context. No new
## battle is started and no reward is granted twice: the normal claim/receipt
## identity checks still apply. A world settlement keeps its trigger/location
## context; an ordinary battle reward has none and replays the claim directly.
func retry_pending_battle_settlement() -> Dictionary:
	if _pending_battle_result.is_empty():
		return {"ok": false, "reason": "no_pending_settlement", "message": "battle.reward_unavailable"}
	var outcome: Dictionary
	if _pending_battle_kind == "world":
		outcome = settle_world_battle(_pending_battle_result, _pending_battle_context)
	else:
		outcome = claim_battle_reward(_pending_battle_result)
	# A duplicate receipt means the preserved settlement is already committed.
	# Clear it here too because the early no-op returns before the normal clear.
	if bool(outcome.get("ok", false)):
		clear_pending_battle_result()
	return outcome


func clear_pending_battle_result() -> void:
	_pending_battle_result = {}
	_pending_battle_context = {}
	_pending_battle_kind = ""


## Explicit recovery is only possible when the on-disk save is no longer a
## future version. It never resets a future save by overwriting it.
func recover_from_load_failure() -> Error:
	var result: Dictionary = SaveManager.call("_read_json_with_fallback", PLAYER_STATE_PATH)
	if bool(result.get("ok", false)) and result.get("data") is Dictionary:
		var stored: Dictionary = result["data"]
		if int(stored.get("version", 1)) > PLAYER_STATE_VERSION:
			last_error = "save.error.newer"
			return ERR_FILE_NO_PERMISSION
	set_save_status(SAVE_STATUS_NORMAL, "")
	last_error = ""
	return OK


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


## Resolves an explicit test timestamp, then the QA away-period anchor, then
## the real clock. Explicit values always win so regression tests stay deterministic.
func _resolve_timestamp(now_unix: int) -> int:
	if now_unix >= 0:
		return now_unix
	var qa_now: String = OS.get_environment("FFBE_QA_NOW_UNIX")
	var qa_away: String = OS.get_environment("FFBE_QA_OFFLINE_SECONDS")
	if qa_now.is_valid_int() and qa_away.is_valid_int():
		return maxi(0, qa_now.to_int() - maxi(0, qa_away.to_int()))
	return maxi(0, int(Time.get_unix_time_from_system()))


func default_state(now_unix: int = -1) -> Dictionary:
	var anchor: int = _resolve_timestamp(now_unix)
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
		"reward_claims": {},
		"mission_progress": {},
		"battle_runs": {},
		"espers": {},
		"summon": {},
		"economy": {"last_settled_unix": anchor, "claims": {}},
		"shops": {},
		"crafting": {},
		"world": default_world_state(),
		"legacy": {}
	}


## Prompt 06 world state is additive. Every field has a conservative default so
## an old save can be backfilled without resetting progress from Prompts 01-05.1.
func default_world_state() -> Dictionary:
	return {
		"version": 1,
		"current_region": WORLD_REGION_ID,
		"current_location": WORLD_START_LOCATION,
		"discovered_locations": [WORLD_START_LOCATION],
		"unlocked_locations": [WORLD_START_LOCATION],
		"completed_locations": [],
		"quests": {},
		"flags": {},
		"dialogue_choices": {},
		"interactions": {},
		"opened_treasures": [],
		"defeated_one_time_encounters": [],
		"processed_battle_runs": {},
		"last_battle_result": {}
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


func load_state(now_unix: int = -1) -> Dictionary:
	var anchor: int = _resolve_timestamp(now_unix)
	set_save_status(SAVE_STATUS_MIGRATING, "")
	_loading = true
	var result: Variant = SaveManager.call("_read_json_with_fallback", PLAYER_STATE_PATH)
	_loading = false
	if result is Dictionary and bool((result as Dictionary).get("ok", false)):
		var raw: Variant = (result as Dictionary).get("data", {})
		if raw is Dictionary:
			var raw_state: Dictionary = raw as Dictionary
			# Check before any backup or normalization: a future save must stay
			# byte-identical, including its .mig.bak and .tmp companions.
			var raw_world_variant: Variant = raw_state.get("world", {})
			if int(raw_state.get("version", 1)) > PLAYER_STATE_VERSION \
					or (raw_world_variant is Dictionary and int((raw_world_variant as Dictionary).get("version", 1)) > 1):
				last_error = "save.error.newer"
				set_save_status(SAVE_STATUS_READ_ONLY_FUTURE_VERSION, last_error)
				load_failed.emit(last_error)
				return default_state(anchor)
			if _needs_migration_backup(raw_state):
				var backup_error: Error = SaveManager.call("backup_for_migration", PLAYER_STATE_PATH)
				if backup_error != OK:
					last_error = "save.error.migration_backup"
					set_save_status(SAVE_STATUS_LOAD_FAILED, last_error)
					load_failed.emit(last_error)
					return default_state(anchor)
			var migrated := migrate_state(raw_state, anchor)
			if save_status == SAVE_STATUS_READ_ONLY_FUTURE_VERSION:
				load_failed.emit(last_error)
				return default_state(anchor)
			if validate_state(migrated):
				set_save_status(SAVE_STATUS_NORMAL, "")
				last_error = ""
				return migrated
			last_error = "save.error.invalid"
			set_save_status(SAVE_STATUS_LOAD_FAILED, last_error)
			load_failed.emit(last_error)
			return default_state(anchor)
	# A fresh profile has nothing to recover and must remain writable. Only a
	# present but unreadable save is locked for owner recovery.
	if FileAccess.file_exists(PLAYER_STATE_PATH) or FileAccess.file_exists(PLAYER_STATE_PATH + ".bak"):
		last_error = "save.error.corrupt"
		set_save_status(SAVE_STATUS_LOAD_FAILED, last_error)
		load_failed.emit(last_error)
	else:
		last_error = ""
		set_save_status(SAVE_STATUS_NORMAL, "")
	return default_state(anchor)


func migrate_state(raw: Dictionary, now_unix: int = -1) -> Dictionary:
	if raw.is_empty():
		return default_state(now_unix)
	var anchor: int = _resolve_timestamp(now_unix)
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
				working = _migrate_2_to_3(working, anchor)
			3:
				working = _migrate_3_to_4(working)
			_:
				return {}
		version += 1
		working["version"] = version
	var future_world_variant: Variant = working.get("world", {})
	if future_world_variant is Dictionary and int((future_world_variant as Dictionary).get("version", 1)) > 1:
		last_error = "save.error.newer"
		return {}
	if not working.has("claimed_rewards"):
		working["claimed_rewards"] = {}
	return _ensure_economy_anchor(_ensure_world_state(working), anchor)


## Version 4 remains the file format. Older v1-v4 saves are normalized in memory
## and a `.mig.bak` copy is written before the first committed world mutation.
func _needs_migration_backup(raw: Dictionary) -> bool:
	var version: int = int(raw.get("version", 1))
	return version <= PLAYER_STATE_VERSION and (version < PLAYER_STATE_VERSION or not raw.has("world"))


func _ensure_world_state(target: Dictionary) -> Dictionary:
	var defaults: Dictionary = default_world_state()
	var section_variant: Variant = target.get("world", null)
	var section: Dictionary = section_variant if section_variant is Dictionary else {}
	for key: String in defaults.keys():
		if not section.has(key) or section[key] == null:
			section[key] = (defaults[key] as Array).duplicate(true) if defaults[key] is Array else (
				defaults[key].duplicate(true) if defaults[key] is Dictionary else defaults[key]
			)
	for id: String in [WORLD_START_LOCATION]:
		if not (section["discovered_locations"] as Array).has(id):
			(section["discovered_locations"] as Array).append(id)
		if not (section["unlocked_locations"] as Array).has(id):
			(section["unlocked_locations"] as Array).append(id)
	if str(section.get("current_location", "")).is_empty():
		section["current_location"] = WORLD_START_LOCATION
	if str(section.get("current_region", "")).is_empty():
		section["current_region"] = WORLD_REGION_ID
	for array_key: String in [
		"discovered_locations", "unlocked_locations", "completed_locations",
		"opened_treasures", "defeated_one_time_encounters"
	]:
		if not section[array_key] is Array:
			section[array_key] = []
	for dict_key: String in [
		"quests", "flags", "dialogue_choices", "interactions",
		"processed_battle_runs", "last_battle_result"
	]:
		if not section[dict_key] is Dictionary:
			section[dict_key] = {}
	target["world"] = section
	return target


## All world managers stage mutations on `data` and call this once. A failed
## atomic write restores the complete pre-transaction snapshot.
func commit_world(section: String, snapshot: Dictionary) -> Dictionary:
	var error: Error = commit(section)
	if error != OK:
		data = snapshot
		return {"ok": false, "reason": "save_failed", "message": "save.failed"}
	return {"ok": true, "reason": "", "message": "save.saved"}


func get_world_state() -> Dictionary:
	var state_variant: Variant = data.get("world", {})
	return state_variant.duplicate(true) if state_variant is Dictionary else default_world_state()


## Additive v4 economy anchor. It only fills a missing/zero unclaimed timestamp;
## any recorded claim window or positive timestamp is preserved byte-for-byte.
func _ensure_economy_anchor(target: Dictionary, anchor: int) -> Dictionary:
	var section_variant: Variant = target.get("economy", {})
	var section: Dictionary = section_variant if section_variant is Dictionary else {}
	var stored: int = int(section.get("last_settled_unix", -1))
	var claims_variant: Variant = section.get("claims", {})
	var claims: Dictionary = claims_variant if claims_variant is Dictionary else {}
	if stored < 0 or (stored == 0 and claims.is_empty()):
		section["last_settled_unix"] = maxi(anchor, 0)
		section["claims"] = claims
		target["economy"] = section
	elif not section.has("claims"):
		section["claims"] = claims
		target["economy"] = section
	return target


func _migrate_1_to_2(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	if not result.has("profile"):
		result["profile"] = {"locale": "vi", "favorites": [], "last_unit_id": ""}
	return result


func _migrate_2_to_3(data: Dictionary, now_unix: int = -1) -> Dictionary:
	var fresh: Dictionary = default_state(now_unix)
	var profile_variant: Variant = data.get("profile", {})
	if profile_variant is Dictionary:
		var profile: Dictionary = profile_variant
		var locale := normalize_locale(str(profile.get("locale", "vi")))
		fresh["profile"]["locale"] = locale
		var favorites_variant: Variant = profile.get("favorites", [])
		if favorites_variant is Array:
			fresh["profile"]["favorites"] = (favorites_variant as Array).duplicate()
		fresh["profile"]["last_unit_id"] = str(profile.get("last_unit_id", profile.get("selected_unit_id", "")))
	# Older saves may already carry v3-shaped fields. Keep those values and only
	# backfill keys that are absent instead of resetting the player's progress.
	var resources_variant: Variant = data.get("resources", {})
	if resources_variant is Dictionary:
		(fresh["resources"] as Dictionary).merge(resources_variant as Dictionary, true)
	for section: String in ["owned_units", "inventory", "parties", "claimed_rewards"]:
		var value: Variant = data.get(section, null)
		if value is Array or value is Dictionary:
			fresh[section] = (value as Array).duplicate(true) if value is Array else (value as Dictionary).duplicate(true)
	if data.has("active_party"):
		fresh["active_party"] = str(data.get("active_party", "default"))
	for key: String in ["next_unit_serial", "next_equip_serial"]:
		if int(data.get(key, 0)) > 0:
			fresh[key] = int(data[key])
	var legacy: Dictionary = {}
	for key: String in ["battle_progress", "settings_summary", "version"]:
		if data.has(key):
			legacy[key] = (data[key] if not data[key] is Dictionary else (data[key] as Dictionary).duplicate(true))
	fresh["legacy"] = legacy
	return fresh


func _migrate_3_to_4(data: Dictionary) -> Dictionary:
	## Additive migration: every v3 field is retained. Only missing v4 sections
	## are backfilled, and legacy claim keys are copied into the canonical store
	## so an older save cannot grant the same legacy reward twice.
	var result: Dictionary = data.duplicate(true)
	for section: String in [
		"reward_claims", "mission_progress", "battle_runs", "espers",
		"summon", "economy", "shops", "crafting"
	]:
		var value: Variant = result.get(section, null)
		if value == null or not (value is Dictionary):
			result[section] = {}

	var claimed_variant: Variant = result.get("claimed_rewards", {})
	if claimed_variant is Dictionary:
		var claims: Dictionary = result.get("reward_claims", {})
		for legacy_key: Variant in (claimed_variant as Dictionary).keys():
			var key: String = str(legacy_key)
			if claims.has(key):
				continue
			var entry_variant: Variant = (claimed_variant as Dictionary)[legacy_key]
			claims[key] = {
				"key": key,
				"legacy": true,
				"result": entry_variant.duplicate(true) if entry_variant is Dictionary else {}
			}
		result["reward_claims"] = claims

	var runs: Dictionary = result.get("battle_runs", {})
	var legacy_variant: Variant = result.get("legacy", {})
	if legacy_variant is Dictionary and runs.is_empty():
		var legacy_progress: Variant = (legacy_variant as Dictionary).get("battle_progress", {})
		if legacy_progress is Dictionary:
			runs["legacy"] = (legacy_progress as Dictionary).duplicate(true)
	result["battle_runs"] = runs
	return result


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
	for section: String in [
		"claimed_rewards", "reward_claims", "mission_progress", "battle_runs",
		"espers", "summon", "economy", "shops", "crafting", "world"
	]:
		if not (state.get(section, {}) is Dictionary):
			return false
	var world_variant: Variant = state.get("world", {})
	if not world_variant is Dictionary or int((world_variant as Dictionary).get("version", 0)) != 1:
		return false
	for world_key: String in [
		"discovered_locations", "unlocked_locations", "completed_locations",
		"opened_treasures", "defeated_one_time_encounters"
	]:
		if not (world_variant as Dictionary).get(world_key, []) is Array:
			return false
	for world_key: String in [
		"quests", "flags", "dialogue_choices", "interactions",
		"processed_battle_runs", "last_battle_result"
	]:
		if not (world_variant as Dictionary).get(world_key, {}) is Dictionary:
			return false
	var profile_variant_check: Variant = state.get("profile", {})
	if not profile_variant_check is Dictionary:
		return false
	var economy_variant: Variant = state.get("economy", {})
	if economy_variant is Dictionary and (economy_variant as Dictionary).has("last_settled_unix"):
		if int((economy_variant as Dictionary).get("last_settled_unix", -1)) < 0:
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
	var guard: Error = _write_guard_error()
	if guard != OK:
		return guard
	return _commit_internal()


func commit(section: String) -> Error:
	var error: Error = save()
	if error == OK:
		state_changed.emit(section)
	return error


func _commit_internal() -> Error:
	if not validate_state(data):
		last_error = "save.error.invalid"
		return ERR_INVALID_DATA
	var error: Error = SaveManager.call("atomic_write", PLAYER_STATE_PATH, data)
	if error != OK:
		last_error = "save.error.invalid"
		return error
	last_error = ""
	return OK


## One gameplay action = one staged mutation, validation and single commit.
## Public settlement helpers call this instead of nesting commits. A failed
## action restores the full snapshot; a nested transaction is rejected rather
## than silently creating a second on-disk write.
func transaction(section: String, mutation: Callable) -> Dictionary:
	if not mutation.is_valid():
		return {"ok": false, "reason": "invalid_mutation", "message": "save.failed"}
	var guard: Error = _write_guard_error()
	if guard != OK:
		return {"ok": false, "reason": "read_only", "message": "save.error.read_only"}
	if _transaction_depth > 0:
		return {"ok": false, "reason": "nested_transaction", "message": "save.failed"}
	var snapshot: Dictionary = data.duplicate(true)
	_transaction_depth = 1
	var staged: Variant
	staged = mutation.call()
	_transaction_depth = 0
	if staged is Dictionary and not bool((staged as Dictionary).get("ok", true)):
		data = snapshot
		return staged
	if not validate_state(data):
		data = snapshot
		return {"ok": false, "reason": "invalid_state", "message": "save.error.invalid"}
	var error: Error = _commit_internal()
	if error != OK:
		data = snapshot
		return {"ok": false, "reason": "save_failed", "message": "reward.save_failed"}
	state_changed.emit(section)
	return staged if staged is Dictionary else {"ok": true, "reason": ""}


func reset_to_defaults() -> Error:
	var guard: Error = _write_guard_error()
	if guard != OK:
		return guard
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
	if _write_guard_error() != OK:
		return false
	if not can_pay(cost):
		return false
	var resources: Dictionary = data.get("resources", {})
	for key: String in cost.keys():
		resources[key] = get_resource(key) - maxi(int(cost[key]), 0)
	data["resources"] = resources
	return true


func grant(reward: Dictionary) -> void:
	if _write_guard_error() != OK:
		return
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
	if _write_guard_error() != OK:
		return false
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
	if _write_guard_error() != OK or _transaction_depth > 0:
		return ""
	var serial: int = maxi(int(data.get("next_unit_serial", 1)), 1)
	var entry: Dictionary = _new_unit_dict(definition_id, serial, source)
	var units_variant: Variant = data.get("owned_units", [])
	var units: Array = units_variant if units_variant is Array else []
	(units as Array).append(entry)
	data["owned_units"] = units
	data["next_unit_serial"] = serial + 1
	if commit("units") != OK:
		return ""
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
	if _write_guard_error() != OK:
		return -1
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
	if _write_guard_error() != OK:
		return
	var all_parties: Dictionary = parties()
	all_parties[party_id] = party.duplicate(true)
	data["parties"] = all_parties


func definition_for(instance: Dictionary) -> Dictionary:
	return ContentRepository.call("get_unit_definition", str(instance.get("definition_id", "")))


func locale() -> String:
	return normalize_locale(str((data.get("profile", {}) as Dictionary).get("locale", "vi")))


func set_locale(locale: String) -> Error:
	var guard: Error = _write_guard_error()
	if guard != OK:
		return guard
	var normalized := normalize_locale(locale)
	var profile_variant: Variant = data.get("profile", {})
	var previous: Dictionary = (profile_variant as Dictionary).duplicate(true) if profile_variant is Dictionary else {}
	var profile: Dictionary = previous.duplicate(true)
	profile["locale"] = normalized
	data["profile"] = profile
	var error: Error = commit("profile")
	if error != OK:
		data["profile"] = previous
		return error
	return OK


## Legacy diagnostic fingerprint only. Canonical settlement uses the explicit
## claim keys supplied by RewardResolver; this helper is retained so older QA
## captures can still identify a result, but it never gates a reward grant.
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
	var guard: Error = _write_guard_error()
	if guard != OK:
		return {"ok": false, "reason": "read_only", "key": "", "message": "save.error.read_only"}
	_pending_battle_context = {}
	_pending_battle_kind = "reward"
	_pending_battle_result = result.duplicate(true)
	var outcome: Dictionary = transaction("rewards", func() -> Dictionary:
		return _stage_battle_reward(result)
	)
	if not outcome.has("key"):
		outcome["key"] = str(_canonical_claim_keys(
			result, str(result.get("encounter_id", "")), str(result.get("run_id", ""))
		).get("repeat", ""))
	if str(outcome.get("reason", "")) != "save_failed":
		clear_pending_battle_result()
	return outcome


## Pure staging half of battle reward settlement. It never commits, so a world
## settlement can include it in the same atomic transaction.
func _stage_battle_reward(result: Dictionary) -> Dictionary:
	if not bool(result.get("victory", false)):
		return {"ok": false, "reason": "not_victory", "key": "", "message": "reward.not_victory"}
	var encounter_id: String = str(result.get("encounter_id", ""))
	var run_id: String = str(result.get("run_id", ""))
	var claim_keys: Dictionary = _canonical_claim_keys(result, encounter_id, run_id)
	var repeat_key: String = str(claim_keys.get("repeat", ""))
	if repeat_key.is_empty():
		return {"ok": false, "reason": "invalid_result", "key": "", "message": "reward.invalid_result"}

	var claims_variant: Variant = data.get("reward_claims", {})
	var claims: Dictionary = claims_variant if claims_variant is Dictionary else {}
	var new_claim_keys: Array[String] = []
	for key_variant: Variant in claim_keys.values():
		var key: String = str(key_variant)
		if not claims.has(key):
			new_claim_keys.append(key)
	if new_claim_keys.is_empty():
		return {
			"ok": false, "reason": "already_claimed", "key": repeat_key,
			"message": "reward.already_claimed", "keys": claim_keys.duplicate(true)
		}

	var rewards_variant: Variant = result.get("rewards", {})
	var rewards: Dictionary = rewards_variant if rewards_variant is Dictionary else {}
	var grant: Dictionary = {}
	var legacy: Dictionary = _snapshot_section(data, "claimed_rewards")

	if not claims.has(repeat_key):
		var repeat_variant: Variant = rewards.get("repeat", {})
		if repeat_variant is Dictionary:
			_collect_reward(repeat_variant, grant)
		else:
			_collect_reward(rewards, grant)
		_remember_claim(claims, legacy, repeat_key, encounter_id, run_id, result)

	var first_key: String = str(claim_keys.get("first_clear", ""))
	if not first_key.is_empty() and not claims.has(first_key):
		var first_variant: Variant = rewards.get("first_clear", {})
		if first_variant is Dictionary:
			_collect_reward(first_variant, grant)
		_remember_claim(claims, legacy, first_key, encounter_id, run_id, result)

	var claimed_missions: Array[Dictionary] = []
	var missions_variant: Variant = rewards.get("missions", [])
	if missions_variant is Array:
		for mission_variant: Variant in missions_variant:
			if not mission_variant is Dictionary:
				continue
			var mission: Dictionary = mission_variant
			var mission_id: String = str(mission.get("id", ""))
			var key: String = str(claim_keys.get("mission:%s" % mission_id, mission.get("key", "")))
			if mission_id.is_empty() or key.is_empty() or claims.has(key):
				continue
			var mission_reward: Variant = mission.get("reward", {})
			if mission_reward is Dictionary:
				_collect_reward(mission_reward, grant)
			_remember_claim(claims, legacy, key, encounter_id, run_id, result)
			claimed_missions.append({
				"id": mission_id,
				"key": key,
				"repeatable": bool(mission.get("repeatable", false)),
				"reward": mission_reward.duplicate(true) if mission_reward is Dictionary else {}
			})

	for key_variant: Variant in claim_keys.values():
		var key: String = str(key_variant)
		if not new_claim_keys.has(key):
			continue
		legacy[key] = {
			"encounter_id": encounter_id,
			"run_id": run_id,
			"seed": int(result.get("seed", 0)),
			"turns": int(result.get("turns", 0))
		}

	var progress_variant: Variant = data.get("mission_progress", {})
	var mission_progress: Dictionary = progress_variant if progress_variant is Dictionary else {}
	for mission: Dictionary in claimed_missions:
		var key: String = str(mission["key"])
		var previous: Dictionary = mission_progress.get(key, {})
		mission_progress[key] = {
			"key": key,
			"encounter_id": encounter_id,
			"mission_id": str(mission["id"]),
			"run_id": run_id,
			"turns": int(result.get("turns", 0)),
			"repeatable": bool(mission["repeatable"]),
			"completions": int(previous.get("completions", 0)) + 1,
			"completed": true
		}

	var runs_variant: Variant = data.get("battle_runs", {})
	var runs: Dictionary = runs_variant if runs_variant is Dictionary else {}
	var run_key: String = run_id if not run_id.is_empty() else repeat_key
	runs[run_key] = {
		"run_id": run_key,
		"encounter_id": encounter_id,
		"seed": int(result.get("seed", 0)),
		"seed_source": str(result.get("seed_source", "independent")),
		"turns": int(result.get("turns", 0)),
		"victory": true,
		"claim_keys": claim_keys.duplicate(true),
		"rewards": grant.duplicate(true)
	}

	var resources: Dictionary = get_resources()
	for key: String in grant.keys():
		resources[key] = get_resource(key) + maxi(int(grant[key]), 0)
	data["resources"] = resources
	data["reward_claims"] = claims
	data["claimed_rewards"] = legacy
	data["mission_progress"] = mission_progress
	data["battle_runs"] = runs
	return {
		"ok": true,
		"reason": "",
		"key": repeat_key,
		"keys": claim_keys.duplicate(true),
		"new_keys": new_claim_keys.duplicate(true),
		"message": "reward.saved",
		"rewards": grant
	}


## Prompt 06 quest and treasure rewards reuse the same staged, claim-keyed and
## rollback-safe settlement path as combat rewards. `on_commit` lets the caller
## stage related world-state changes in the same single atomic write.
func claim_world_reward(
	kind: String,
	identity: String,
	reward: Dictionary,
	on_commit: Callable = Callable()
) -> Dictionary:
	if kind.is_empty() or identity.is_empty() or not (reward is Dictionary):
		return {"ok": false, "reason": "invalid_reward", "message": "reward.invalid"}
	var guard: Error = _write_guard_error()
	if guard != OK:
		return {"ok": false, "reason": "read_only", "message": "save.error.read_only"}
	var key: String = "world|%s|%s" % [kind, identity]
	var claims_variant: Variant = data.get("reward_claims", {})
	var claims: Dictionary = claims_variant if claims_variant is Dictionary else {}
	if claims.has(key):
		return {"ok": false, "reason": "already_claimed", "key": key, "message": "reward.already_claimed"}
	var staged_callback: Callable = on_commit
	var outcome: Dictionary = transaction("world_reward", func() -> Dictionary:
		if staged_callback.is_valid():
			var staged: Variant = staged_callback.call()
			if staged is Dictionary and not bool((staged as Dictionary).get("ok", true)):
				return staged
		return _stage_world_claim(kind, identity, reward, key)
	)
	if not outcome.has("key"):
		outcome["key"] = key
	return outcome


func _stage_world_claim(kind: String, identity: String, reward: Dictionary, key: String) -> Dictionary:
	var grant: Dictionary = {}
	_collect_reward(reward, grant)
	var resources: Dictionary = get_resources()
	for item_id: String in grant.keys():
		resources[item_id] = get_resource(item_id) + maxi(int(grant[item_id]), 0)
	data["resources"] = resources
	var legacy_variant: Variant = data.get("claimed_rewards", {})
	var legacy: Dictionary = legacy_variant if legacy_variant is Dictionary else {}
	legacy[key] = {"kind": kind, "identity": identity, "rewards": grant.duplicate(true)}
	var claims_variant: Variant = data.get("reward_claims", {})
	var claims: Dictionary = claims_variant if claims_variant is Dictionary else {}
	claims[key] = {
		"key": key,
		"kind": kind,
		"identity": identity,
		"rewards": grant.duplicate(true),
		"canonical": true
	}
	data["claimed_rewards"] = legacy
	data["reward_claims"] = claims
	return {
		"ok": true, "reason": "", "key": key,
		"message": "reward.saved", "rewards": grant.duplicate(true)
	}


func transact_world(section: String, mutation: Callable) -> Dictionary:
	return transaction(section, mutation)


## Canonical settlement for a world encounter. Reward, encounter flag, run
## receipt, world state and quest event are staged into one transaction and
## committed during the battle, before the player returns to the map. A run
## receipt is a hard idempotency boundary: no reward, world, interaction or quest
## mutation is even staged when the same run is settled again.
##
## `repository` is an optional test seam; normal callers leave it null.
func settle_world_battle(
	result: Dictionary, context: Dictionary = {}, repository: RefCounted = null
) -> Dictionary:
	var run_id: String = str(result.get("run_id", ""))
	var encounter_id: String = str(result.get("encounter_id", ""))
	if run_id.is_empty() or encounter_id.is_empty():
		return {"ok": false, "reason": "invalid_result", "message": "world.invalid_result"}

	var world_variant: Variant = data.get("world", null)
	var world: Dictionary = world_variant if world_variant is Dictionary else {}
	var processed_variant: Variant = world.get("processed_battle_runs", {})
	var processed: Dictionary = processed_variant if processed_variant is Dictionary else {}
	if processed.has(run_id):
		var prior_variant: Variant = processed[run_id]
		var prior: Dictionary = prior_variant if prior_variant is Dictionary else {}
		if not prior.is_empty() and str(prior.get("encounter_id", "")) != encounter_id:
			return {"ok": false, "reason": "invalid_context", "message": "world.invalid_context"}
		# Return before the write guard, pending-state capture and transaction.
		# This is a true no-op even for a quest whose objective needs multiple wins.
		return {
			"ok": true, "reason": "", "duplicate": true,
			"reward": {
				"ok": false, "reason": "already_claimed", "key": "",
				"message": "reward.already_claimed"
			},
			"world": {
				"ok": true, "reason": "", "duplicate": true,
				"one_time": bool(prior.get("one_time", false)),
				"trigger_id": str(prior.get("trigger_id", ""))
			},
			"quest": {"ok": true, "reason": "", "duplicate": true, "touched": [], "completed": []}
		}

	var guard: Error = _write_guard_error()
	if guard != OK:
		return {"ok": false, "reason": "read_only", "message": "save.error.read_only"}
	var settlement_context: Dictionary = context.duplicate(true)
	if settlement_context.is_empty() and result.has("trigger_id"):
		settlement_context["trigger_id"] = str(result.get("trigger_id", ""))
		settlement_context["location_id"] = str(result.get("location_id", ""))
	# Keep both halves until a write succeeds. A failed commit rolls data back but
	# must not discard the context needed for a no-refight retry.
	_pending_battle_context = settlement_context.duplicate(true)
	_pending_battle_kind = "world"
	_pending_battle_result = result.duplicate(true)
	var quest_repo: QuestRepository = QuestRepository.new()
	if repository != null and repository is QuestRepository:
		quest_repo = repository as QuestRepository
	var outcome: Dictionary = transaction("battle_settlement", func() -> Dictionary:
		var reward_stage: Dictionary = _stage_battle_reward(result)
		var reward_reason: String = str(reward_stage.get("reason", ""))
		if not bool(reward_stage.get("ok", false)) \
				and reward_reason != "not_victory" and reward_reason != "already_claimed":
			return reward_stage
		var world_stage: Dictionary = _stage_world_battle(result, settlement_context)
		if not bool(world_stage.get("ok", false)):
			return world_stage
		var quest_stage: Dictionary = {"ok": true, "reason": "", "touched": [], "completed": []}
		if bool(result.get("victory", false)) and not encounter_id.is_empty():
			quest_stage = QuestSettlement.stage_event(data, {
				"type": "defeat_encounter", "target": encounter_id, "count": 1
			}, quest_repo)
			if not bool(quest_stage.get("ok", false)):
				return quest_stage
		return {
			"ok": true, "reason": "", "reward": reward_stage,
			"world": world_stage, "quest": quest_stage
		}
	)
	if str(outcome.get("reason", "")) != "save_failed":
		clear_pending_battle_result()
	if not outcome.has("key"):
		outcome["key"] = str(((outcome.get("reward", {}) as Dictionary).get("key", "")))
	return outcome


func _stage_world_battle(result: Dictionary, context: Dictionary) -> Dictionary:
	var run_id: String = str(result.get("run_id", ""))
	var encounter_id: String = str(result.get("encounter_id", ""))
	var trigger_id: String = str(context.get("trigger_id", result.get("trigger_id", "")))
	var location_id: String = str(context.get("location_id", result.get("location_id", "")))
	if run_id.is_empty() or encounter_id.is_empty():
		return {"ok": false, "reason": "invalid_result", "message": "world.invalid_result"}
	var one_time: bool = bool(result.get("one_time", false))
	if not trigger_id.is_empty():
		var trigger: Dictionary = ContentRepository.call("get_world_interactable", trigger_id)
		if trigger.is_empty() or str(trigger.get("kind", "")) != "encounter_trigger":
			return {"ok": false, "reason": "invalid_context", "message": "world.invalid_context"}
		if str(trigger.get("encounter_id", "")) != encounter_id:
			return {"ok": false, "reason": "invalid_context", "message": "world.invalid_context"}
		var context_encounter: String = str(context.get("encounter_id", ""))
		if not context_encounter.is_empty() and context_encounter != encounter_id:
			return {"ok": false, "reason": "invalid_context", "message": "world.invalid_context"}
		var area_id: String = str(trigger.get("area_id", ""))
		if not location_id.is_empty() and not area_id.is_empty() and area_id != location_id:
			return {"ok": false, "reason": "invalid_context", "message": "world.invalid_context"}
		one_time = one_time or str(trigger.get("interaction_policy", "")) == "one_time"
	var world_variant: Variant = data.get("world", null)
	if not world_variant is Dictionary:
		return {"ok": false, "reason": "invalid_state", "message": "world.invalid_state"}
	var world: Dictionary = world_variant
	var processed_variant: Variant = world.get("processed_battle_runs", {})
	var processed: Dictionary = processed_variant if processed_variant is Dictionary else {}
	var duplicate: bool = processed.has(run_id)
	if not duplicate:
		processed[run_id] = {
			"run_id": run_id, "encounter_id": encounter_id,
			"outcome": "victory" if bool(result.get("victory", false)) else "defeat",
			"trigger_id": trigger_id, "one_time": one_time
		}
		var interactions_variant: Variant = world.get("interactions", {})
		var interactions: Dictionary = interactions_variant if interactions_variant is Dictionary else {}
		if not trigger_id.is_empty():
			var previous: Dictionary = interactions.get(trigger_id, {})
			interactions[trigger_id] = {
				"count": int(previous.get("count", 0)) + 1,
				"last_outcome": "victory" if bool(result.get("victory", false)) else "defeat"
			}
			world["interactions"] = interactions
	world["processed_battle_runs"] = processed
	world["last_battle_result"] = result.duplicate(true)
	if bool(result.get("victory", false)) and one_time:
		var defeated_variant: Variant = world.get("defeated_one_time_encounters", [])
		var defeated: Array = defeated_variant if defeated_variant is Array else []
		if not defeated.has(encounter_id):
			defeated.append(encounter_id)
			defeated.sort()
		world["defeated_one_time_encounters"] = defeated
	data["world"] = world
	return {
		"ok": true, "reason": "", "duplicate": duplicate,
		"one_time": one_time, "trigger_id": trigger_id
	}


func _snapshot_section(snapshot: Dictionary, section: String) -> Dictionary:
	var value: Variant = snapshot.get(section, {})
	return value if value is Dictionary else {}


func _remember_claim(
	claims: Dictionary,
	legacy: Dictionary,
	key: String,
	encounter_id: String,
	run_id: String,
	result: Dictionary
) -> void:
	var record: Dictionary = {
		"key": key,
		"encounter_id": encounter_id,
		"run_id": run_id,
		"turns": int(result.get("turns", 0)),
		"canonical": true
	}
	claims[key] = record
	legacy[key] = {
		"encounter_id": encounter_id,
		"run_id": run_id,
		"seed": int(result.get("seed", 0)),
		"turns": int(result.get("turns", 0))
	}


func _canonical_claim_keys(result: Dictionary, encounter_id: String, run_id: String) -> Dictionary:
	var policy_variant: Variant = result.get("reward_policy", {})
	var policy: Dictionary = policy_variant if policy_variant is Dictionary else {}
	var rewards_variant: Variant = result.get("rewards", {})
	var rewards: Dictionary = rewards_variant if rewards_variant is Dictionary else {}
	if policy.is_empty():
		var nested_policy: Variant = rewards.get("policy", {})
		if nested_policy is Dictionary:
			policy = nested_policy
	var provided_variant: Variant = rewards.get("claim_keys", result.get("claim_keys", {}))
	var provided: Dictionary = provided_variant if provided_variant is Dictionary else {}
	var keys: Dictionary = {}

	var repeat_key: String = str(provided.get("repeat", ""))
	if not repeat_key.is_empty() and not _is_canonical_claim_key(repeat_key):
		return {}
	if repeat_key.is_empty():
		# A world encounter marked one_time is keyed by the stable encounter id,
		# never by the attempt id: a retry or a fresh run cannot farm rewards.
		if bool(result.get("one_time", false)) and not encounter_id.is_empty():
			repeat_key = "battle|once|%s" % encounter_id
		elif not run_id.is_empty():
			repeat_key = "battle|run|%s" % run_id
		elif not bool(policy.get("repeatable", true)) and not encounter_id.is_empty():
			repeat_key = "battle|once|%s" % encounter_id
	if repeat_key.is_empty():
		return {}
	keys["repeat"] = repeat_key

	var first_key: String = str(provided.get("first_clear", ""))
	if not first_key.is_empty() and not _is_canonical_claim_key(first_key):
		return {}
	if first_key.is_empty() and bool(policy.get("first_clear", false)) and not encounter_id.is_empty():
		first_key = "battle|first|%s" % encounter_id
	if not first_key.is_empty():
		keys["first_clear"] = first_key

	for key_variant: Variant in provided.keys():
		var key: String = str(key_variant)
		if not key.begins_with("mission:"):
			continue
		var mission_key: String = str(provided[key_variant])
		if bool(result.get("one_time", false)) and not run_id.is_empty():
			var run_suffix: String = "|%s" % run_id
			if mission_key.ends_with(run_suffix):
				mission_key = mission_key.substr(0, mission_key.length() - run_suffix.length())
		if not _is_canonical_claim_key(mission_key):
			return {}
		keys[key] = mission_key
	return keys


func _is_canonical_claim_key(key: String) -> bool:
	for prefix: String in ["battle|run|", "battle|once|", "battle|first|", "battle|mission|"]:
		if key.begins_with(prefix) and key.length() > prefix.length():
			return true
	return false


func _collect_reward(bundle: Dictionary, grant: Dictionary) -> void:
	grant["gil"] = int(grant.get("gil", 0)) + maxi(int(bundle.get("gil", 0)), 0)
	var items_variant: Variant = bundle.get("items", [])
	if items_variant is Array:
		for item_variant: Variant in items_variant:
			var item_id: String = str(item_variant)
			if not item_id.is_empty():
				grant[item_id] = int(grant.get(item_id, 0)) + 1
