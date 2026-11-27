extends Node

## Narrow autoload service: the only runtime entry point for normalized content.
## Scenes never read raw source files or JSON paths directly.

signal content_loaded(summary: Dictionary)
signal load_failed(message: String)

const CATALOG_PATH := "res://data/content_catalog.json"

var loaded: bool = false
var _catalog: Dictionary = {}
var _units: Array[UnitRecord] = []
var _units_by_id: Dictionary = {}
var _animations: Dictionary = {}
var _atlas_info: Dictionary = {}
var _settings_defaults: Dictionary = {}
var _battles: Dictionary = {}
var _unit_definitions: Dictionary = {}
var _progression_rules: Dictionary = {}
var _equipment: Dictionary = {}
var _materia: Dictionary = {}
var _vision_cards: Dictionary = {}
var _ability_rewards: Dictionary = {}
var _advanced_abilities: Dictionary = {}
var _mechanic_labels: Dictionary = {}
var _imported_manifest: Dictionary = {}
var _espers: Dictionary = {}
var _summon_banners: Dictionary = {}
var _offline_economy_rules: Dictionary = {}
var _offline_default_rule_id: String = ""
var _shops: Dictionary = {}
var _crafting_recipes: Dictionary = {}
var _resource_definition_ids: Dictionary = {}
var _world_regions: Dictionary = {}
var _world_locations: Dictionary = {}
var _world_connections: Dictionary = {}
var _world_interactables: Dictionary = {}
var _world_dialogues: Dictionary = {}
var _world_quests: Dictionary = {}
var _events: Dictionary = {}
var _event_stages: Dictionary = {}

const FIXTURE_MARKER := "SYNTHETIC_FIXTURE"
const ALLOWED_EVIDENCE: Array[String] = ["SYNTHETIC_FIXTURE", "REMASTERED_DESIGN"]
const CURRENCY_KEYS: Array[String] = ["gil", "lapis", "trust_moogles"]
const EVENT_OBJECTIVE_TYPES: Array[String] = ["stage_clear", "boss_clear"]
const EVENT_UNLOCK_KINDS: Array[String] = ["none", "event", "stage", "quest"]


func _ready() -> void:
	var error: Error = load_content()
	if error != OK:
		var message: String = "ContentRepository failed to load with error %d" % error
		DebugLog.error(message)
		load_failed.emit(message)


func load_content() -> Error:
	_catalog = _read_json(CATALOG_PATH)
	if _catalog.is_empty():
		return ERR_FILE_NOT_FOUND

	var files_variant: Variant = _catalog.get("files", {})
	if not files_variant is Dictionary:
		DebugLog.error("content_catalog.json has no files dictionary")
		return ERR_INVALID_DATA
	var files: Dictionary = files_variant

	var units_data: Dictionary = _read_json(str(files.get("units", "")))
	var animations_data: Dictionary = _read_json(str(files.get("animations", "")))
	var settings_data: Dictionary = _read_json(str(files.get("settings_defaults", "")))
	var battles_data: Dictionary = _read_json(str(files.get("battles", "")))
	var unit_definitions_data: Dictionary = _read_json(str(files.get("unit_definitions", "")))
	var progression_rules_data: Dictionary = _read_json(str(files.get("progression_rules", "")))
	var equipment_data: Dictionary = _read_json(str(files.get("equipment", "")))
	var advanced_abilities_data: Dictionary = _read_json(str(files.get("advanced_abilities", "")))
	var mechanic_labels_data: Dictionary = _read_json(str(files.get("mechanic_labels", "")))
	var imported_manifest_data: Dictionary = _read_json(str(files.get("imported_manifest", "")))
	var espers_data: Dictionary = _read_json(str(files.get("espers", "")))
	var summon_banners_data: Dictionary = _read_json(str(files.get("summon_banners", "")))
	var offline_rules_data: Dictionary = _read_json(str(files.get("offline_economy_rules", "")))
	var shops_data: Dictionary = _read_json(str(files.get("shops", "")))
	var crafting_recipes_data: Dictionary = _read_json(str(files.get("crafting_recipes", "")))
	var world_regions_data: Dictionary = _read_json(str(files.get("world_regions", "")))
	var world_locations_data: Dictionary = _read_json(str(files.get("world_locations", "")))
	var world_connections_data: Dictionary = _read_json(str(files.get("world_connections", "")))
	var world_interactables_data: Dictionary = _read_json(str(files.get("world_interactables", "")))
	var world_dialogues_data: Dictionary = _read_json(str(files.get("world_dialogues", "")))
	var world_quests_data: Dictionary = _read_json(str(files.get("world_quests", "")))
	var events_data: Dictionary = _read_json(str(files.get("events", "")))
	if units_data.is_empty() or animations_data.is_empty() or settings_data.is_empty() or battles_data.is_empty():
		return ERR_FILE_NOT_FOUND
	if unit_definitions_data.is_empty() or progression_rules_data.is_empty() or equipment_data.is_empty():
		return ERR_FILE_NOT_FOUND
	if advanced_abilities_data.is_empty() or mechanic_labels_data.is_empty() or imported_manifest_data.is_empty():
		return ERR_FILE_NOT_FOUND
	if espers_data.is_empty() or summon_banners_data.is_empty() or offline_rules_data.is_empty():
		return ERR_FILE_NOT_FOUND
	if shops_data.is_empty() or crafting_recipes_data.is_empty():
		return ERR_FILE_NOT_FOUND
	if world_regions_data.is_empty() or world_locations_data.is_empty() or world_connections_data.is_empty():
		return ERR_FILE_NOT_FOUND
	if world_interactables_data.is_empty() or world_dialogues_data.is_empty() or world_quests_data.is_empty():
		return ERR_FILE_NOT_FOUND
	if events_data.is_empty():
		return ERR_FILE_NOT_FOUND
	for pack: Dictionary in [
		espers_data, summon_banners_data, offline_rules_data, shops_data,
		crafting_recipes_data, world_regions_data, world_locations_data,
		world_connections_data, world_interactables_data, world_dialogues_data,
		world_quests_data, events_data
	]:
		if not _fixture_gate(pack):
			return ERR_INVALID_DATA
	if str(unit_definitions_data.get("fixture_marker", "")) != "SYNTHETIC_FIXTURE":
		DebugLog.error("Unit definition package is not marked SYNTHETIC_FIXTURE")
		return ERR_INVALID_DATA
	if str(progression_rules_data.get("fixture_marker", "")) != "SYNTHETIC_FIXTURE":
		DebugLog.error("Progression package is not marked SYNTHETIC_FIXTURE")
		return ERR_INVALID_DATA
	if str(equipment_data.get("fixture_marker", "")) != "SYNTHETIC_FIXTURE":
		DebugLog.error("Equipment package is not marked SYNTHETIC_FIXTURE")
		return ERR_INVALID_DATA
	if str(advanced_abilities_data.get("fixture_marker", "")) != "SYNTHETIC_FIXTURE":
		DebugLog.error("Advanced ability package is not marked SYNTHETIC_FIXTURE")
		return ERR_INVALID_DATA

	_units.clear()
	_units_by_id.clear()
	var units_variant: Variant = units_data.get("units", [])
	if units_variant is Array:
		for entry in units_variant:
			if not entry is Dictionary:
				continue
			var record: UnitRecord = UnitRecord.from_dict(entry)
			if not record.content_id.is_valid():
				DebugLog.warn("Skipping invalid content identity: %s" % record.id)
				continue
			if _units_by_id.has(record.id):
				DebugLog.warn("Duplicate composite identity skipped: %s" % record.id)
				continue
			_units.append(record)
			_units_by_id[record.id] = record

	var animations_variant: Variant = animations_data.get("clips", {})
	if animations_variant is Dictionary:
		_animations = animations_variant.duplicate(true)
	var atlas_variant: Variant = animations_data.get("atlas", {})
	if atlas_variant is Dictionary:
		_atlas_info = atlas_variant.duplicate(true)
	var defaults_variant: Variant = settings_data.get("settings", {})
	if defaults_variant is Dictionary:
		_settings_defaults = defaults_variant.duplicate(true)

	if str(battles_data.get("fixture_marker", "")) != "SYNTHETIC_FIXTURE":
		DebugLog.error("Battle package is not marked SYNTHETIC_FIXTURE")
		return ERR_INVALID_DATA
	_battles = battles_data.duplicate(true)

	_unit_definitions.clear()
	var unit_defs_variant: Variant = unit_definitions_data.get("units", [])
	if unit_defs_variant is Array:
		for entry_variant: Variant in unit_defs_variant:
			if not entry_variant is Dictionary:
				continue
			var entry: Dictionary = entry_variant
			var id: String = str(entry.get("id", ""))
			if id.is_empty() or _unit_definitions.has(id):
				DebugLog.warn("Skipping invalid or duplicate unit definition: %s" % id)
				continue
			var parsed: ContentId = ContentId.parse(id)
			if parsed == null or not parsed.is_valid() or parsed.as_text() != id:
				DebugLog.warn("Skipping malformed unit definition identity: %s" % id)
				continue
			_unit_definitions[id] = entry.duplicate(true)

	_progression_rules = progression_rules_data.duplicate(true)
	_equipment = _copy_section(equipment_data, "equipment")
	_materia = _copy_section(equipment_data, "materia")
	_vision_cards = _copy_section(equipment_data, "vision_cards")
	_ability_rewards = _copy_section(equipment_data, "abilities")
	_advanced_abilities = _copy_section(advanced_abilities_data, "abilities")
	var labels_variant: Variant = mechanic_labels_data.get("mechanics", {})
	_mechanic_labels = labels_variant.duplicate(true) if labels_variant is Dictionary else {}
	_imported_manifest = imported_manifest_data.duplicate(true)

	_resource_definition_ids.clear()
	_collect_resource_ids(_unit_definitions, _resource_definition_ids)
	_collect_resource_ids(_progression_rules, _resource_definition_ids)
	_collect_resource_ids(equipment_data, _resource_definition_ids)
	_collect_resource_ids(_battles, _resource_definition_ids)
	var trust_moogle_variant: Variant = _progression_rules.get("trust_moogle", {})
	if trust_moogle_variant is Dictionary:
		var trust_moogle_id: String = str((trust_moogle_variant as Dictionary).get("id", ""))
		if not trust_moogle_id.is_empty():
			_resource_definition_ids[trust_moogle_id] = true

	var parsed_espers: Dictionary = _validated_records(espers_data, "espers", "esper")
	var parsed_banners: Dictionary = _validated_records(summon_banners_data, "banners", "summon")
	var parsed_rules: Dictionary = _validated_records(offline_rules_data, "rules", "offline_rule")
	var parsed_shops: Dictionary = _validated_records(shops_data, "shops", "shop")
	var parsed_recipes: Dictionary = _validated_records(crafting_recipes_data, "recipes", "recipe")
	if parsed_espers.is_empty() or parsed_banners.is_empty() or parsed_rules.is_empty():
		return ERR_INVALID_DATA
	if parsed_shops.is_empty() or parsed_recipes.is_empty():
		return ERR_INVALID_DATA
	if not _validate_espers(parsed_espers) or not _validate_banners(parsed_banners):
		return ERR_INVALID_DATA
	if not _validate_offline_rules(parsed_rules, str(offline_rules_data.get("default_rule_id", ""))):
		return ERR_INVALID_DATA
	if not _validate_shops(parsed_shops) or not _validate_recipes(parsed_recipes):
		return ERR_INVALID_DATA

	_espers = parsed_espers
	_summon_banners = parsed_banners
	_offline_economy_rules = parsed_rules
	_offline_default_rule_id = str(offline_rules_data.get("default_rule_id", ""))
	_shops = parsed_shops
	_crafting_recipes = parsed_recipes
	_world_regions = _validated_records(world_regions_data, "regions", "region")
	_world_locations = _validated_records(world_locations_data, "locations", "location")
	_world_connections = _validated_records(world_connections_data, "connections", "connection")
	_world_interactables = _validated_world_records(
		world_interactables_data, "interactables",
		["npc", "treasure", "encounter_trigger", "exit"]
	)
	_world_dialogues = _validated_records(world_dialogues_data, "dialogues", "dialogue")
	_world_quests = _validated_records(world_quests_data, "quests", "quest")
	if _world_regions.is_empty() or _world_locations.is_empty() or _world_connections.is_empty():
		return ERR_INVALID_DATA
	if _world_interactables.is_empty() or _world_dialogues.is_empty() or _world_quests.is_empty():
		return ERR_INVALID_DATA
	if not _validate_world_data():
		return ERR_INVALID_DATA

	var parsed_events: Dictionary = _validated_records(events_data, "events", "event")
	var parsed_event_stages: Dictionary = _validated_records(events_data, "stages", "event_stage")
	if parsed_events.is_empty() or parsed_event_stages.is_empty():
		return ERR_INVALID_DATA
	if not _validate_event_data(parsed_events, parsed_event_stages):
		return ERR_INVALID_DATA
	_events = parsed_events
	_event_stages = parsed_event_stages

	loaded = true
	DebugLog.info("Loaded %d synthetic unit records" % _units.size())
	content_loaded.emit(summary())
	return OK


func get_units() -> Array[UnitRecord]:
	return _units.duplicate()


func get_units_for_region(region: String) -> Array[UnitRecord]:
	var result: Array[UnitRecord] = []
	for unit: UnitRecord in _units:
		if unit.region == region:
			result.append(unit)
	return result


func get_unit(id: String) -> UnitRecord:
	return _units_by_id.get(id, null) as UnitRecord


func get_animation_id_for_unit(unit: UnitRecord) -> String:
	return unit.animation_id if unit != null else ""


func get_clip_names(animation_id: String) -> Array[String]:
	var result: Array[String] = []
	if not _animations.has(animation_id):
		return result
	var clips_variant: Variant = _animations.get(animation_id, {})
	if not clips_variant is Dictionary:
		return result
	var clips: Dictionary = clips_variant
	for key in clips.keys():
		result.append(str(key))
	return result


func get_animation_clip(animation_id: String, clip_name: String) -> Dictionary:
	if not _animations.has(animation_id):
		return {}
	var clips_variant: Variant = _animations.get(animation_id, {})
	if not clips_variant is Dictionary:
		return {}
	var clips: Dictionary = clips_variant
	var clip_variant: Variant = clips.get(clip_name, {})
	if not clip_variant is Dictionary:
		return {}
	return clip_variant.duplicate(true)


func get_atlas_info() -> Dictionary:
	return _atlas_info.duplicate(true)


func get_settings_defaults() -> Dictionary:
	return _settings_defaults.duplicate(true)


func get_battle_package() -> Dictionary:
	var result: Dictionary = _battles.duplicate(true)
	var abilities_variant: Variant = result.get("abilities", {})
	var abilities: Dictionary = abilities_variant if abilities_variant is Dictionary else {}
	for id: String in _advanced_abilities.keys():
		if not abilities.has(id):
			abilities[id] = (_advanced_abilities[id] as Dictionary).duplicate(true)
	result["abilities"] = abilities
	return result


func get_battle_combatant(id: String) -> Dictionary:
	var section_variant: Variant = _battles.get("combatants", {})
	if not section_variant is Dictionary:
		return {}
	var value: Variant = (section_variant as Dictionary).get(id, {})
	return value.duplicate(true) if value is Dictionary else {}


func get_ability_definition(id: String) -> Dictionary:
	var section_variant: Variant = _battles.get("abilities", {})
	if section_variant is Dictionary:
		var value: Variant = (section_variant as Dictionary).get(id, {})
		if value is Dictionary:
			return (value as Dictionary).duplicate(true)
	return _lookup_definition(_advanced_abilities, id)


func get_item_definition(id: String) -> Dictionary:
	var section_variant: Variant = _battles.get("items", {})
	if not section_variant is Dictionary:
		return {}
	var value: Variant = (section_variant as Dictionary).get(id, {})
	return value.duplicate(true) if value is Dictionary else {}


func get_encounter(id: String) -> Dictionary:
	var section_variant: Variant = _battles.get("encounters", {})
	if not section_variant is Dictionary:
		return {}
	var value: Variant = (section_variant as Dictionary).get(id, {})
	return value.duplicate(true) if value is Dictionary else {}


func get_encounter_ids() -> Array[String]:
	var result: Array[String] = []
	var encounters_variant: Variant = _battles.get("encounters", {})
	if encounters_variant is Dictionary:
		for key in (encounters_variant as Dictionary).keys():
			result.append(str(key))
	result.sort()
	return result


func parse_composite_id(id: String) -> ContentId:
	return ContentId.parse(id)


func get_unit_definition(id: String) -> Dictionary:
	var value: Variant = _unit_definitions.get(id, {})
	return value.duplicate(true) if value is Dictionary else {}


func get_unit_definitions() -> Dictionary:
	return _unit_definitions.duplicate(true)


func get_progression_rules() -> Dictionary:
	return _progression_rules.duplicate(true)


func get_equipment_definition(id: String) -> Dictionary:
	return _lookup_definition(_equipment, id)


func get_materia_definition(id: String) -> Dictionary:
	return _lookup_definition(_materia, id)


func get_vision_card_definition(id: String) -> Dictionary:
	return _lookup_definition(_vision_cards, id)


func get_ability_reward_definition(id: String) -> Dictionary:
	return _lookup_definition(_ability_rewards, id)


func get_advanced_ability(id: String) -> Dictionary:
	return _lookup_definition(_advanced_abilities, id)


func get_mechanic_labels() -> Dictionary:
	return _mechanic_labels.duplicate(true)


func get_imported_manifest() -> Dictionary:
	return _imported_manifest.duplicate(true)


func get_esper_definition(id: String) -> Dictionary:
	return _lookup_definition(_espers, id)


func get_esper_definitions() -> Dictionary:
	return _espers.duplicate(true)


func get_summon_banner(id: String) -> Dictionary:
	return _lookup_definition(_summon_banners, id)


func get_summon_banners() -> Dictionary:
	return _summon_banners.duplicate(true)


func get_offline_economy_rules() -> Dictionary:
	return _offline_economy_rules.duplicate(true)


func get_offline_economy_default_rule_id() -> String:
	return _offline_default_rule_id


func get_shop(id: String) -> Dictionary:
	return _lookup_definition(_shops, id)


func get_shops() -> Dictionary:
	return _shops.duplicate(true)


func get_crafting_recipe(id: String) -> Dictionary:
	return _lookup_definition(_crafting_recipes, id)


## Public, read-only definition gate used by economy systems before charging or
## granting. Currencies and all composite synthetic resource/item definitions
## resolve through the same validator used when the packs were loaded.
func definition_exists(id: String) -> bool:
	return _definition_exists(id)


func get_crafting_recipes() -> Dictionary:
	return _crafting_recipes.duplicate(true)


## Prompt 06 world data is read-only to callers; repositories own all mutable
## discovery and progression state.
func get_world_region(id: String) -> Dictionary:
	return _lookup_definition(_world_regions, id)


func get_world_regions() -> Dictionary:
	return _world_regions.duplicate(true)


func get_world_location(id: String) -> Dictionary:
	return _lookup_definition(_world_locations, id)


func get_world_locations() -> Dictionary:
	return _world_locations.duplicate(true)


func get_world_connection(id: String) -> Dictionary:
	return _lookup_definition(_world_connections, id)


func get_world_connections() -> Dictionary:
	return _world_connections.duplicate(true)


func get_world_interactable(id: String) -> Dictionary:
	return _lookup_definition(_world_interactables, id)


func get_world_interactables() -> Dictionary:
	return _world_interactables.duplicate(true)


func get_world_dialogue(id: String) -> Dictionary:
	return _lookup_definition(_world_dialogues, id)


func get_world_dialogues() -> Dictionary:
	return _world_dialogues.duplicate(true)


func get_world_quest(id: String) -> Dictionary:
	return _lookup_definition(_world_quests, id)


func get_world_quests() -> Dictionary:
	return _world_quests.duplicate(true)


## Prompt 07 event data is read-only. Repositories and services own mutable
## participation state; callers never edit these definitions in place.
func get_event(id: String) -> Dictionary:
	return _lookup_definition(_events, id)


func get_events() -> Dictionary:
	return _events.duplicate(true)


func get_event_stage(id: String) -> Dictionary:
	return _lookup_definition(_event_stages, id)


func get_event_stages() -> Dictionary:
	return _event_stages.duplicate(true)


func get_event_pack() -> Dictionary:
	return {
		"events": _events.duplicate(true),
		"stages": _event_stages.duplicate(true)
	}


func summary() -> Dictionary:
	var policy_variant: Variant = _catalog.get("policy", {})
	var policy: Dictionary = policy_variant if policy_variant is Dictionary else {}
	return {
		"content_version": str(_catalog.get("content_version", "")),
		"fixture_marker": str(_catalog.get("fixture_marker", "")),
		"unit_count": _units.size(),
		"animation_group_count": _animations.size(),
		"encounter_count": (_battles.get("encounters", {}) as Dictionary).size(),
		"unit_definition_count": _unit_definitions.size(),
		"equipment_definition_count": _equipment.size(),
		"materia_definition_count": _materia.size(),
		"vision_card_definition_count": _vision_cards.size(),
		"ability_reward_definition_count": _ability_rewards.size(),
		"advanced_ability_count": _advanced_abilities.size(),
		"esper_definition_count": _espers.size(),
		"summon_banner_count": _summon_banners.size(),
		"offline_economy_rule_count": _offline_economy_rules.size(),
		"shop_definition_count": _shops.size(),
		"crafting_recipe_count": _crafting_recipes.size(),
		"world_region_count": _world_regions.size(),
		"world_location_count": _world_locations.size(),
		"world_connection_count": _world_connections.size(),
		"world_interactable_count": _world_interactables.size(),
		"world_dialogue_count": _world_dialogues.size(),
		"world_quest_count": _world_quests.size(),
		"event_count": _events.size(),
		"event_stage_count": _event_stages.size(),
		"rights_gate": str(policy.get("rights_gate", "not_passed")),
		"regions": ["GL", "JP"]
	}


func _lookup_definition(section: Dictionary, id: String) -> Dictionary:
	var value: Variant = section.get(id, {})
	return value.duplicate(true) if value is Dictionary else {}


func _copy_section(source: Dictionary, key: String) -> Dictionary:
	var value: Variant = source.get(key, {})
	return value.duplicate(true) if value is Dictionary else {}


func _read_json(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		DebugLog.error("Missing content file: %s" % path)
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		DebugLog.error("Cannot open content file: %s (error %d)" % [path, FileAccess.get_open_error()])
		return {}
	var text: String = file.get_as_text()
	file.close()

	var parser := JSON.new()
	var error: Error = parser.parse(text)
	if error != OK:
		DebugLog.error(
			"JSON parse failed for %s at line %d: %s"
			% [path, parser.get_error_line(), parser.get_error_message()]
		)
		return {}
	if not parser.data is Dictionary:
		DebugLog.error("Expected a JSON object in %s" % path)
		return {}
	return parser.data


## Prompt 05 economy packs fail closed: a missing pack, wrong marker, duplicate
## identity or malformed composite ID makes the whole repository load fail.
func _fixture_gate(pack: Dictionary) -> bool:
	if str(pack.get("fixture_marker", "")) != FIXTURE_MARKER:
		DebugLog.error("Economy pack is not marked SYNTHETIC_FIXTURE")
		return false
	var policy_variant: Variant = pack.get("policy", null)
	if not policy_variant is Dictionary:
		DebugLog.error("Economy pack has no policy dictionary")
		return false
	var policy: Dictionary = policy_variant
	if str(policy.get("rights_gate", "")) != "not_passed":
		DebugLog.error("Economy pack has no not_passed rights gate")
		return false
	if bool(policy.get("source_data_imported", false)):
		DebugLog.error("Economy pack claims imported source data")
		return false
	return true


## The synthetic world IDs keep the compact `loc:` prefix while their record
## `kind` stays readable as `location`. Normalize only this documented alias;
## every other record must match its ID prefix exactly.
func _canonical_kind(parsed_kind: String) -> String:
	# World locations keep the compact `loc:` prefix while Prompt 07 stages
	# keep the compact `stage:` prefix; their record kinds stay readable.
	if parsed_kind == "loc":
		return "location"
	if parsed_kind == "stage":
		return "event_stage"
	return parsed_kind


func _validated_records(pack: Dictionary, section_key: String, expected_kind: String) -> Dictionary:
	var entries_variant: Variant = pack.get(section_key, [])
	if not entries_variant is Array or (entries_variant as Array).is_empty():
		DebugLog.error("Economy pack has no %s records" % section_key)
		return {}
	var result: Dictionary = {}
	for entry_variant: Variant in entries_variant:
		if not entry_variant is Dictionary:
			DebugLog.error("Non-object record in %s" % section_key)
			return {}
		var entry: Dictionary = entry_variant
		var id: String = str(entry.get("id", ""))
		var parsed: ContentId = ContentId.parse(id)
		if parsed == null or not parsed.is_valid() or parsed.as_text() != id:
			DebugLog.error("Malformed %s identity: %s" % [section_key, id])
			return {}
		if _canonical_kind(parsed.kind) != expected_kind or str(entry.get("kind", "")) != expected_kind:
			DebugLog.error("Wrong kind for %s identity: %s" % [section_key, id])
			return {}
		if str(entry.get("region", "")) != parsed.region:
			DebugLog.error("Region mismatch for %s" % id)
			return {}
		if str(entry.get("native_id", "")) != parsed.native_id or str(entry.get("form", "")) != parsed.form:
			DebugLog.error("Native ID/form mismatch for %s" % id)
			return {}
		if not ALLOWED_EVIDENCE.has(str(entry.get("verification_status", ""))):
			DebugLog.error("Missing evidence label for %s" % id)
			return {}
		var provenance_variant: Variant = entry.get("provenance", {})
		if not provenance_variant is Dictionary:
			DebugLog.error("Missing provenance for %s" % id)
			return {}
		var provenance: Dictionary = provenance_variant
		if str(provenance.get("rights_gate", "")) != "not_passed":
			DebugLog.error("Missing not_passed rights gate for %s" % id)
			return {}
		if result.has(id):
			DebugLog.error("Duplicate %s identity: %s" % [section_key, id])
			return {}
		result[id] = entry.duplicate(true)
	return result


func _validated_world_records(pack: Dictionary, section_key: String, expected_kinds: Array) -> Dictionary:
	var entries_variant: Variant = pack.get(section_key, [])
	if not entries_variant is Array or (entries_variant as Array).is_empty():
		DebugLog.error("World pack has no %s records" % section_key)
		return {}
	var result: Dictionary = {}
	for entry_variant: Variant in entries_variant:
		if not entry_variant is Dictionary:
			DebugLog.error("Non-object record in world %s" % section_key)
			return {}
		var entry: Dictionary = entry_variant
		var id: String = str(entry.get("id", ""))
		var parsed: ContentId = ContentId.parse(id)
		if parsed == null or not parsed.is_valid() or parsed.as_text() != id:
			DebugLog.error("Malformed world identity: %s" % id)
			return {}
		var kind: String = str(entry.get("kind", ""))
		if not expected_kinds.has(kind) or _canonical_kind(parsed.kind) != kind:
			DebugLog.error("Wrong kind for world identity: %s" % [id])
			return {}
		if str(entry.get("region", "")) != parsed.region:
			DebugLog.error("Region mismatch for world identity: %s" % id)
			return {}
		if str(entry.get("native_id", "")) != parsed.native_id or str(entry.get("form", "")) != parsed.form:
			DebugLog.error("Native ID/form mismatch for world identity: %s" % id)
			return {}
		if not ALLOWED_EVIDENCE.has(str(entry.get("verification_status", ""))):
			DebugLog.error("Missing evidence label for world identity: %s" % id)
			return {}
		var provenance_variant: Variant = entry.get("provenance", {})
		if not provenance_variant is Dictionary:
			DebugLog.error("Missing provenance for world identity: %s" % id)
			return {}
		if str((provenance_variant as Dictionary).get("rights_gate", "")) != "not_passed":
			DebugLog.error("Missing not_passed rights gate for world identity: %s" % id)
			return {}
		if result.has(id):
			DebugLog.error("Duplicate world identity: %s" % id)
			return {}
		result[id] = entry.duplicate(true)
	return result


func _validate_world_data() -> bool:
	for id: String in _world_regions.keys():
		var entry: Dictionary = _world_regions[id]
		if str(entry.get("name_key", "")).is_empty() or str(entry.get("description_key", "")).is_empty():
			return false
		if str(entry.get("background_ref", "")).is_empty():
			return false
		if not _world_locations.has(str(entry.get("start_location", ""))):
			return false
	for id: String in _world_locations.keys():
		var entry: Dictionary = _world_locations[id]
		if not _world_regions.has(str(entry.get("region_id", ""))):
			return false
		if not ["town", "field", "dungeon", "boss"].has(str(entry.get("location_kind", ""))):
			return false
		if str(entry.get("name_key", "")).is_empty() or str(entry.get("description_key", "")).is_empty():
			return false
		if str(entry.get("background_ref", "")).is_empty():
			return false
		if not _is_world_point(entry.get("map_position", null)):
			return false
		if not _is_world_requirements(entry.get("unlock_requirements", null)):
			return false
		var encounter_id: String = str(entry.get("encounter_id", ""))
		if not encounter_id.is_empty():
			var encounters: Dictionary = _battles.get("encounters", {})
			if not encounters.has(encounter_id):
				return false
	for id: String in _world_connections.keys():
		var entry: Dictionary = _world_connections[id]
		var from_id: String = str(entry.get("from", ""))
		var to_id: String = str(entry.get("to", ""))
		if from_id == to_id or not _world_locations.has(from_id) or not _world_locations.has(to_id):
			return false
		if not _validate_location_requirement(entry.get("requirement", null)):
			return false
	for id: String in _world_interactables.keys():
		var entry: Dictionary = _world_interactables[id]
		if not _world_locations.has(str(entry.get("area_id", ""))):
			return false
		if not _is_world_point(entry.get("position", null)) or float(entry["position"]["x"]) < 0 or float(entry["position"]["x"]) > 1280:
			return false
		if float((entry["position"] as Dictionary).get("y", -1)) < 0 or float((entry["position"] as Dictionary).get("y", -1)) > 720:
			return false
		if int(entry.get("radius", 0)) <= 0:
			return false
		if str(entry.get("name_key", "")).is_empty() or str(entry.get("prompt_key", "")).is_empty():
			return false
		if not ["one_time", "repeatable"].has(str(entry.get("interaction_policy", ""))):
			return false
		if not _validate_location_requirement(entry.get("requirement", null)):
			return false
		var kind: String = str(entry.get("kind", ""))
		if kind == "npc" and not _world_dialogues.has(str(entry.get("dialogue_id", ""))):
			return false
		if kind == "treasure" and not _is_world_reward(entry.get("reward", null)):
			return false
		if kind == "encounter_trigger":
			var encounters: Dictionary = _battles.get("encounters", {})
			if not encounters.has(str(entry.get("encounter_id", ""))):
				return false
		if kind == "exit":
			var destination: String = str(entry.get("destination", ""))
			if destination != "world_map" and not _world_locations.has(destination):
				return false
	for id: String in _world_dialogues.keys():
		var entry: Dictionary = _world_dialogues[id]
		if str(entry.get("speaker_key", "")).is_empty():
			return false
		var nodes_variant: Variant = entry.get("nodes", [])
		if not nodes_variant is Array or (nodes_variant as Array).is_empty():
			return false
		var nodes: Dictionary = {}
		for node_variant: Variant in nodes_variant:
			if not node_variant is Dictionary:
				return false
			var node: Dictionary = node_variant
			var node_id: String = str(node.get("id", ""))
			if node_id.is_empty() or nodes.has(node_id):
				return false
			nodes[node_id] = node
		if not nodes.has(str(entry.get("start_node", ""))):
			return false
		for node_id: String in nodes.keys():
			var node: Dictionary = nodes[node_id]
			for line_variant: Variant in (node.get("lines", []) as Array):
				if not _validate_dialogue_line(line_variant):
					return false
			for choice_variant: Variant in (node.get("choices", []) as Array):
				if not choice_variant is Dictionary:
					return false
				var choice: Dictionary = choice_variant
				if str(choice.get("label_key", "")).is_empty() or not nodes.has(str(choice.get("next", ""))):
					return false
				if choice.has("when") and not _validate_dialogue_condition(choice.get("when")):
					return false
				for effect_variant: Variant in (choice.get("effects", []) as Array):
					if not _validate_dialogue_effect(effect_variant):
						return false
			var next_id: String = str(node.get("next", ""))
			if not next_id.is_empty() and not nodes.has(next_id):
				return false
	for id: String in _world_quests.keys():
		var entry: Dictionary = _world_quests[id]
		if str(entry.get("name_key", "")).is_empty() or str(entry.get("description_key", "")).is_empty():
			return false
		if not _is_world_requirements(entry.get("prerequisites", null)):
			return false
		for prereq: Variant in (entry.get("prerequisites", {}) as Dictionary).get("quests", []):
			if not _world_quests.has(str(prereq)):
				return false
		var objectives_variant: Variant = entry.get("objectives", [])
		if not objectives_variant is Array or (objectives_variant as Array).is_empty():
			return false
		var objective_ids: Dictionary = {}
		for objective_variant: Variant in objectives_variant:
			if not objective_variant is Dictionary:
				return false
			var objective: Dictionary = objective_variant
			var objective_id: String = str(objective.get("id", ""))
			if objective_id.is_empty() or objective_ids.has(objective_id):
				return false
			objective_ids[objective_id] = true
			if not _validate_quest_objective(objective):
				return false
		if not _is_world_reward(entry.get("rewards", null)):
			return false
		for unlock_variant: Variant in (entry.get("unlocks", []) as Array):
			if not _world_locations.has(str(unlock_variant)):
				return false
	return true


## Prompt 07 events fail closed on broken stage, schedule, reward or reference
## data. All event content remains synthetic and region-aware.
func _validate_event_data(events: Dictionary, stages: Dictionary) -> bool:
	var encounters_variant: Variant = _battles.get("encounters", {})
	var encounters: Dictionary = encounters_variant if encounters_variant is Dictionary else {}
	for id: String in events.keys():
		var event: Dictionary = events[id]
		if not ["story", "limited", "permanent", "collaboration", "seasonal", "challenge"].has(
			str(event.get("category", ""))
		):
			return false
		if str(event.get("name_key", "")).is_empty() or str(event.get("description_key", "")).is_empty():
			return false
		if not ["scheduled", "permanent"].has(str((event.get("availability", {}) as Dictionary).get("mode", ""))):
			return false
		var unlock_variant: Variant = event.get("unlock", null)
		if not unlock_variant is Dictionary:
			return false
		var unlock: Dictionary = unlock_variant
		var unlock_kind: String = str(unlock.get("kind", ""))
		if not EVENT_UNLOCK_KINDS.has(unlock_kind):
			return false
		var unlock_id: String = str(unlock.get("id", ""))
		if unlock_kind == "none":
			if not unlock_id.is_empty():
				return false
		elif unlock_id.is_empty() or not _event_unlock_reference_valid(event, unlock_kind, unlock_id, events, stages):
			return false
		var regions_variant: Variant = event.get("regions", {})
		if not regions_variant is Dictionary or (regions_variant as Dictionary).is_empty():
			return false
		for region_variant: Variant in (regions_variant as Dictionary).keys():
			var region: String = str(region_variant)
			if region != "GL" and region != "JP":
				return false
			var config_variant: Variant = (regions_variant as Dictionary)[region_variant]
			if not config_variant is Dictionary:
				return false
			var config: Dictionary = config_variant
			var start_unix: int = int(config.get("start_unix", -1))
			var end_unix: int = int(config.get("end_unix", -1))
			if str((event.get("availability", {}) as Dictionary).get("mode", "")) == "permanent":
				if start_unix != 0 or end_unix != 0:
					return false
			elif start_unix < 0 or end_unix <= start_unix:
				return false
			var banner_ref: String = str(config.get("banner_ref", ""))
			if not banner_ref.is_empty() and not _summon_banners.has(banner_ref):
				return false
		var banner_ref: String = str(event.get("banner_ref", ""))
		if not banner_ref.is_empty() and not _summon_banners.has(banner_ref):
			return false
		var shop_ref: String = str(event.get("shop_ref", ""))
		if not shop_ref.is_empty() and not _shops.has(shop_ref):
			return false
		var boss_encounter: String = str(event.get("boss_encounter", ""))
		if not boss_encounter.is_empty() and not encounters.has(boss_encounter):
			return false
		if str(event.get("event_currency", "")).is_empty():
			return false
		var stage_ids_variant: Variant = event.get("stage_ids", [])
		if not stage_ids_variant is Array or (stage_ids_variant as Array).is_empty():
			return false
		for stage_id_variant: Variant in stage_ids_variant:
			var stage_id: String = str(stage_id_variant)
			if not stages.has(stage_id):
				return false
			var stage: Dictionary = stages[stage_id]
			if str(stage.get("event_id", "")) != id or str(stage.get("region", "")) != str(event.get("region", "")):
				return false
			var config_variant: Variant = (event.get("regions", {}) as Dictionary).get(str(stage.get("region", "")), null)
			if config_variant is Dictionary:
				var override_ids: Variant = (config_variant as Dictionary).get("stage_ids", [])
				if override_ids is Array and not (override_ids as Array).is_empty() and not (override_ids as Array).has(stage_id):
					return false
		var missions_variant: Variant = event.get("missions", [])
		if not missions_variant is Array:
			return false
		var mission_ids: Dictionary = {}
		for mission_variant: Variant in missions_variant:
			if not mission_variant is Dictionary:
				return false
			var mission: Dictionary = mission_variant
			var mission_id: String = str(mission.get("id", ""))
			if mission_id.is_empty() or mission_ids.has(mission_id):
				return false
			mission_ids[mission_id] = true
			if str(mission.get("key", "")).is_empty() or int(mission.get("target", 0)) <= 0:
				return false
			if not _is_world_reward(mission.get("reward", null)):
				return false
			var objective_variant: Variant = mission.get("objective", null)
			if not objective_variant is Dictionary:
				return false
			var objective: Dictionary = objective_variant
			var objective_type: String = str(objective.get("type", ""))
			if not EVENT_OBJECTIVE_TYPES.has(objective_type):
				return false
			var objective_ref: String = str(objective.get("ref", ""))
			if not stages.has(objective_ref):
				return false
			var objective_stage: Dictionary = stages[objective_ref]
			if str(objective_stage.get("event_id", "")) != id:
				return false
			if objective_type == "boss_clear" and str(objective_stage.get("encounter_id", "")) != boss_encounter:
				return false
		var shop_variant: Variant = event.get("shop", {})
		if not shop_variant is Dictionary:
			return false
		var shop_items_variant: Variant = (shop_variant as Dictionary).get("items", [])
		if not shop_items_variant is Array:
			return false
		var shop_item_ids: Dictionary = {}
		for item_variant: Variant in shop_items_variant:
			if not item_variant is Dictionary:
				return false
			var item: Dictionary = item_variant
			var item_id: String = str(item.get("id", ""))
			if item_id.is_empty() or shop_item_ids.has(item_id):
				return false
			shop_item_ids[item_id] = true
			if str(item.get("currency", "")) != str(event.get("event_currency", "")):
				return false
			if int(item.get("cost", 0)) <= 0 or not _is_world_reward(item.get("reward", null)):
				return false
	for id: String in stages.keys():
		var stage: Dictionary = stages[id]
		if not events.has(str(stage.get("event_id", ""))):
			return false
		if not encounters.has(str(stage.get("encounter_id", ""))):
			return false
		if str(stage.get("name_key", "")).is_empty():
			return false
		if int(stage.get("order", -1)) < 0 or int(stage.get("completion_target", 0)) <= 0:
			return false
		if not _is_world_reward(stage.get("first_clear_reward", null)) or not _is_world_reward(stage.get("repeat_reward", null)):
			return false
		var currency_variant: Variant = stage.get("currency", null)
		if not currency_variant is Dictionary or int((currency_variant as Dictionary).get("amount", 0)) <= 0:
			return false
		for prereq_variant: Variant in (stage.get("unlock_after", []) as Array):
			if not stages.has(str(prereq_variant)):
				return false
	return true


## Event unlock references are validated against already-loaded definitions.
## A prerequisite from another region, an unknown quest or a missing stage is
## rejected at load time so runtime evaluation never has to guess.
func _event_unlock_reference_valid(
	event: Dictionary, kind: String, reference: String,
	events: Dictionary, stages: Dictionary
) -> bool:
	var regions_variant: Variant = event.get("regions", {})
	if not regions_variant is Dictionary:
		return false
	var regions: Dictionary = regions_variant
	match kind:
		"event":
			if not events.has(reference) or reference == str(event.get("id", "")):
				return false
			var prerequisite: Dictionary = events[reference]
			var prerequisite_regions_variant: Variant = prerequisite.get("regions", {})
			if not prerequisite_regions_variant is Dictionary:
				return false
			for region_variant: Variant in regions.keys():
				if not (prerequisite_regions_variant as Dictionary).has(str(region_variant)):
					return false
			return true
		"stage":
			if not stages.has(reference):
				return false
			var prerequisite_stage: Dictionary = stages[reference]
			var stage_region: String = str(prerequisite_stage.get("region", ""))
			if not regions.has(stage_region):
				return false
			return events.has(str(prerequisite_stage.get("event_id", "")))
		"quest":
			if not _world_quests.has(reference):
				return false
			for region_variant: Variant in regions.keys():
				if reference.begins_with("quest:%s:" % str(region_variant)):
					return true
			return false
		_:
			return false


func _is_world_point(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var point: Dictionary = value
	for axis: String in ["x", "y"]:
		var axis_value: Variant = point.get(axis, null)
		if typeof(axis_value) != TYPE_INT and typeof(axis_value) != TYPE_FLOAT:
			return false
	return true


func _is_world_requirements(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var requirements: Dictionary = value
	return _is_string_array(requirements.get("quests", [])) and _is_string_array(requirements.get("flags", []))


func _validate_location_requirement(value: Variant) -> bool:
	if value == null:
		return true
	if not value is Dictionary:
		return false
	var location_id: String = str((value as Dictionary).get("location_id", ""))
	return location_id.is_empty() or _world_locations.has(location_id)


func _validate_dialogue_line(value: Variant) -> bool:
	if value is String:
		return not str(value).is_empty()
	if not value is Dictionary:
		return false
	var line: Dictionary = value
	if str(line.get("key", "")).is_empty():
		return false
	if line.has("when") and not _validate_dialogue_condition(line.get("when")):
		return false
	return true


func _validate_dialogue_condition(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var condition: Dictionary = value
	match str(condition.get("type", "quest_status")):
		"quest_status":
			var quest_id: String = str(condition.get("quest_id", ""))
			var status: String = str(condition.get("status", condition.get("quest_status", "")))
			return _world_quests.has(quest_id) and ["not_started", "active", "completed"].has(status)
		"flag":
			return not str(condition.get("key", "")).is_empty()
		_:
			return false


func _validate_dialogue_effect(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var effect: Dictionary = value
	match str(effect.get("type", "")):
		"flag":
			return not str(effect.get("key", "")).is_empty()
		"quest_accept":
			return _world_quests.has(str(effect.get("quest_id", "")))
		"unlock_location":
			return _world_locations.has(str(effect.get("location_id", "")))
		"quest_event":
			var event_variant: Variant = effect.get("event", null)
			if not event_variant is Dictionary:
				return false
			var event: Dictionary = event_variant
			return ["talk_to", "visit_location", "defeat_encounter", "open_treasure", "collect", "complete_quest"].has(
				str(event.get("type", ""))
			) and not str(event.get("target", "")).is_empty()
		_:
			return false


func _validate_quest_objective(objective: Dictionary) -> bool:
	if str(objective.get("description_key", "")).is_empty() or int(objective.get("count", 0)) <= 0:
		return false
	var target: String = str(objective.get("target", ""))
	match str(objective.get("type", "")):
		"talk_to":
			var interactable: Dictionary = _world_interactables.get(target, {})
			return interactable.get("kind", "") == "npc"
		"visit_location":
			return _world_locations.has(target)
		"defeat_encounter":
			var encounters: Dictionary = _battles.get("encounters", {})
			return encounters.has(target)
		"open_treasure":
			var interactable: Dictionary = _world_interactables.get(target, {})
			return interactable.get("kind", "") == "treasure"
		"collect":
			return _definition_exists(target)
		"complete_quest":
			return _world_quests.has(target)
		_:
			return false


func _is_world_reward(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var reward: Dictionary = value
	if int(reward.get("gil", 0)) < 0:
		return false
	var items_variant: Variant = reward.get("items", [])
	if not items_variant is Array:
		return false
	for item_variant: Variant in items_variant:
		if not _definition_exists(str(item_variant)):
			return false
	return true


func _validate_espers(espers: Dictionary) -> bool:
	for id: String in espers.keys():
		var entry: Dictionary = espers[id]
		if str(entry.get("name_key", "")).is_empty() or int(entry.get("max_level", 0)) <= 0:
			return false
		if not _is_non_negative_int_map(entry.get("stats", null)):
			return false
		if not (entry.get("passive_effects", null) is Array) or not (entry.get("unlock", null) is Dictionary):
			return false
		if not (entry.get("party_link_rules", null) is Dictionary) or not _is_valid_cost(entry.get("cost", null)):
			return false
		if not _is_valid_cost(entry.get("sp_cost", null)) or int(entry.get("sp_cap", 0)) <= 0:
			return false
	return true


func _validate_banners(banners: Dictionary) -> bool:
	for id: String in banners.keys():
		var entry: Dictionary = banners[id]
		if str(entry.get("display_name_key", "")).is_empty() or not _is_valid_cost(entry.get("cost", null)):
			return false
		if not (entry.get("seed_policy", null) is Dictionary) or not (entry.get("pity", null) is Dictionary):
			return false
		var pool_variant: Variant = entry.get("pool", null)
		if not pool_variant is Array or (pool_variant as Array).is_empty():
			return false
		var weights_variant: Variant = entry.get("weights", null)
		if not weights_variant is Dictionary:
			return false
		var weights: Dictionary = weights_variant
		if str(weights.get("mode", "")) != "per_unit":
			return false
		var seen: Dictionary = {}
		for unit_variant: Variant in pool_variant as Array:
			var unit_id: String = str(unit_variant)
			var parsed: ContentId = ContentId.parse(unit_id)
			if parsed == null or not parsed.is_valid() or parsed.as_text() != unit_id:
				return false
			if not _unit_definitions.has(unit_id) or seen.has(unit_id):
				return false
			if int(weights.get(unit_id, 0)) <= 0:
				return false
			seen[unit_id] = true
		for key: Variant in weights.keys():
			if str(key) != "mode" and not seen.has(str(key)):
				return false
		var guarantee_variant: Variant = entry.get("guarantee", null)
		if not guarantee_variant is Dictionary:
			return false
		var guarantee: Dictionary = guarantee_variant
		var within: int = int(guarantee.get("within", 0))
		if within <= 0:
			return false
		if str(guarantee.get("type", "")) == "unit_id" and not seen.has(str(guarantee.get("unit_id", ""))):
			return false
		var pity: Dictionary = entry.get("pity", {})
		var threshold: int = int(pity.get("threshold", 0))
		# The engine grants from guarantee.within. A mismatched display threshold
		# would promise a different draw count, so fail closed instead of choosing.
		if threshold <= 0 or threshold != within:
			return false
	return true


func _validate_offline_rules(rules: Dictionary, default_id: String) -> bool:
	if not rules.has(default_id):
		return false
	for id: String in rules.keys():
		var entry: Dictionary = rules[id]
		if int(entry.get("cap_seconds", 0)) <= 0 or int(entry.get("minimum_interval_seconds", -1)) < 0:
			return false
		if not _is_valid_cost(entry.get("rates_per_hour", null), true):
			return false
		if not _is_valid_cost(entry.get("cap_per_resource", null), true):
			return false
		var rates: Dictionary = entry.get("rates_per_hour", {})
		var caps: Dictionary = entry.get("cap_per_resource", {})
		for key: Variant in caps.keys():
			if not rates.has(key) or int(caps[key]) <= 0:
				return false
		var modifiers_variant: Variant = entry.get("party_modifiers", null)
		if not modifiers_variant is Array:
			return false
		for modifier_variant: Variant in modifiers_variant as Array:
			if not modifier_variant is Dictionary:
				return false
			if int((modifier_variant as Dictionary).get("multiplier_percent", 0)) <= 0:
				return false
	return true


func _validate_shops(shops: Dictionary) -> bool:
	for id: String in shops.keys():
		var stock_variant: Variant = shops[id].get("stock", null)
		if not stock_variant is Array or (stock_variant as Array).is_empty():
			return false
		var seen: Dictionary = {}
		var shop_region: String = str(shops[id].get("region", ""))
		for item_variant: Variant in stock_variant as Array:
			if not item_variant is Dictionary:
				return false
			var item: Dictionary = item_variant
			var stock_id: String = str(item.get("stock_id", ""))
			if stock_id.is_empty() or seen.has(stock_id):
				return false
			var definition_id: String = str(item.get("definition_id", ""))
			if not _definition_exists(definition_id):
				return false
			var parsed_definition: ContentId = ContentId.parse(definition_id)
			if parsed_definition != null and parsed_definition.is_valid() and \
					str(parsed_definition.region) != shop_region:
				return false
			if not _is_valid_cost(item.get("cost", null)):
				return false
			var limit: int = int(item.get("limit", 0))
			if limit <= 0 or limit > 99 or str(item.get("refresh", "")).is_empty():
				return false
			if not _is_string_array(item.get("required_flags", null)):
				return false
			seen[stock_id] = true
	return true


func _validate_recipes(recipes: Dictionary) -> bool:
	for id: String in recipes.keys():
		var entry: Dictionary = recipes[id]
		if not _is_valid_cost(entry.get("inputs", null)) or not _is_valid_cost(entry.get("outputs", null)):
			return false
		if int(entry.get("duration_seconds", 0)) <= 0 or str(entry.get("receipt_prefix", "")).is_empty():
			return false
		if not (entry.get("requirements", null) is Dictionary):
			return false
		var requirements: Dictionary = entry.get("requirements", {})
		if not _is_string_array(requirements.get("required_flags", [])):
			return false
		for output_key: Variant in (entry.get("outputs", {}) as Dictionary).keys():
			var output_id: String = str(output_key)
			if not _definition_exists(output_id):
				return false
	return true


func _is_string_array(value: Variant) -> bool:
	if not value is Array:
		return false
	for entry: Variant in value as Array:
		if not entry is String:
			return false
	return true


func _is_non_negative_int_map(value: Variant) -> bool:
	if not value is Dictionary or (value as Dictionary).is_empty():
		return false
	for key: Variant in (value as Dictionary).keys():
		if not str(key).is_empty() and int((value as Dictionary)[key]) < 0:
			return false
	return true


func _is_valid_cost(value: Variant, allow_empty: bool = false) -> bool:
	if not value is Dictionary:
		return false
	var cost: Dictionary = value
	if cost.is_empty():
		return allow_empty
	for key: Variant in cost.keys():
		var resource_id: String = str(key)
		if not _definition_exists(resource_id):
			return false
		if typeof(cost[key]) != TYPE_INT and typeof(cost[key]) != TYPE_FLOAT:
			return false
		if typeof(cost[key]) == TYPE_FLOAT and float(cost[key]) != float(int(cost[key])):
			return false
		if int(cost[key]) < 0:
			return false
	return true


func _is_resource_like_id(id: String) -> bool:
	var parsed: ContentId = ContentId.parse(id)
	if parsed == null or not parsed.is_valid():
		return false
	return parsed.kind == "material" or parsed.kind == "item" or parsed.kind == "fragment"


func _definition_exists(id: String) -> bool:
	if CURRENCY_KEYS.has(id) or _resource_definition_ids.has(id):
		return true
	var parsed: ContentId = ContentId.parse(id)
	if parsed == null or not parsed.is_valid() or parsed.as_text() != id:
		return false
	match parsed.kind:
		"equip":
			return _equipment.has(id)
		"materia":
			return _materia.has(id)
		"vision_card":
			return _vision_cards.has(id)
		"material", "item", "fragment":
			return _resource_definition_ids.has(id)
		_:
			return false


func _collect_resource_ids(value: Variant, result: Dictionary) -> void:
	if value is Dictionary:
		for key: Variant in (value as Dictionary).keys():
			var id: String = str(key)
			if _is_resource_like_id(id):
				result[id] = true
			_collect_resource_ids((value as Dictionary)[key], result)
	elif value is Array:
		for entry: Variant in value as Array:
			_collect_resource_ids(entry, result)
