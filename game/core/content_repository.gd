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

const FIXTURE_MARKER := "SYNTHETIC_FIXTURE"
const ALLOWED_EVIDENCE: Array[String] = ["SYNTHETIC_FIXTURE", "REMASTERED_DESIGN"]
const CURRENCY_KEYS: Array[String] = ["gil", "lapis", "trust_moogles"]


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
	for pack: Dictionary in [espers_data, summon_banners_data, offline_rules_data, shops_data, crafting_recipes_data]:
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


func get_crafting_recipes() -> Dictionary:
	return _crafting_recipes.duplicate(true)


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
		if parsed.kind != expected_kind or str(entry.get("kind", "")) != expected_kind:
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
		if int(guarantee.get("within", 0)) <= 0:
			return false
		if str(guarantee.get("type", "")) == "unit_id" and not seen.has(str(guarantee.get("unit_id", ""))):
			return false
		if int((entry.get("pity", {}) as Dictionary).get("threshold", 0)) <= 0:
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
		for item_variant: Variant in stock_variant as Array:
			if not item_variant is Dictionary:
				return false
			var item: Dictionary = item_variant
			var stock_id: String = str(item.get("stock_id", ""))
			if stock_id.is_empty() or seen.has(stock_id):
				return false
			if not _definition_exists(str(item.get("definition_id", ""))):
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
