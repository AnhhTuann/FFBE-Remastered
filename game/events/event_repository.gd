class_name EventRepository
extends RefCounted

## Read-only projection of the validated Prompt 07 event pack. Definitions are
## immutable; all mutable participation state stays in PlayerState.events.

var _content: Node = null
var _events: Dictionary = {}
var _stages: Dictionary = {}


func _init(content: Node = null) -> void:
	if content == null:
		var loop: Variant = Engine.get_main_loop()
		if loop is SceneTree:
			content = (loop as SceneTree).root.get_node_or_null("ContentRepository")
	_content = content
	reload()


func reload() -> bool:
	if _content == null or not _content.has_method("get_event_pack"):
		return false
	var pack: Variant = _content.call("get_event_pack")
	if not pack is Dictionary:
		return false
	var source_events: Variant = (pack as Dictionary).get("events", {})
	var source_stages: Variant = (pack as Dictionary).get("stages", {})
	_events = source_events.duplicate(true) if source_events is Dictionary else {}
	_stages = source_stages.duplicate(true) if source_stages is Dictionary else {}
	return not _events.is_empty()


func is_loaded() -> bool:
	return not _events.is_empty()


func get_event(event_id: String) -> Dictionary:
	var value: Variant = _events.get(event_id, {})
	return value.duplicate(true) if value is Dictionary else {}


func get_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in _sorted_keys(_events):
		result.append(_events[id].duplicate(true))
	return result


func get_events_for_region(region: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event: Dictionary in get_events():
		var regions: Variant = event.get("regions", {})
		if regions is Dictionary and (regions as Dictionary).has(region):
			result.append(event)
	return result


func get_event_stage(stage_id: String) -> Dictionary:
	var value: Variant = _stages.get(stage_id, {})
	return value.duplicate(true) if value is Dictionary else {}


func get_event_stages() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in _sorted_keys(_stages):
		result.append(_stages[id].duplicate(true))
	return result


func stages_for_event(event_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event: Dictionary in get_events():
		if str(event.get("id", "")) != event_id:
			continue
		for stage_id_variant: Variant in (event.get("stage_ids", []) as Array):
			var stage: Dictionary = get_event_stage(str(stage_id_variant))
			if not stage.is_empty():
				result.append(stage)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 0)) < int(b.get("order", 0))
	)
	return result


func region_config(event_id: String, region: String) -> Dictionary:
	var event: Dictionary = get_event(event_id)
	var regions_variant: Variant = event.get("regions", {})
	if not regions_variant is Dictionary:
		return {}
	var value: Variant = (regions_variant as Dictionary).get(region, {})
	return value.duplicate(true) if value is Dictionary else {}


func banner_ref(event_id: String, region: String) -> String:
	var config: Dictionary = region_config(event_id, region)
	var override: String = str(config.get("banner_ref", ""))
	if not override.is_empty():
		return override
	return str(get_event(event_id).get("banner_ref", ""))


func event_mission(event_id: String, mission_id: String) -> Dictionary:
	for mission_variant: Variant in (get_event(event_id).get("missions", []) as Array):
		if mission_variant is Dictionary and str((mission_variant as Dictionary).get("id", "")) == mission_id:
			return (mission_variant as Dictionary).duplicate(true)
	return {}


func shop_item(event_id: String, item_id: String) -> Dictionary:
	var shop_variant: Variant = get_event(event_id).get("shop", {})
	if not shop_variant is Dictionary:
		return {}
	for item_variant: Variant in ((shop_variant as Dictionary).get("items", []) as Array):
		if item_variant is Dictionary and str((item_variant as Dictionary).get("id", "")) == item_id:
			return (item_variant as Dictionary).duplicate(true)
	return {}


func shop_items(event_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var shop_variant: Variant = get_event(event_id).get("shop", {})
	if not shop_variant is Dictionary:
		return result
	for item_variant: Variant in ((shop_variant as Dictionary).get("items", []) as Array):
		if item_variant is Dictionary:
			result.append((item_variant as Dictionary).duplicate(true))
	return result


func _sorted_keys(source: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key_variant: Variant in source.keys():
		keys.append(str(key_variant))
	keys.sort()
	return keys
