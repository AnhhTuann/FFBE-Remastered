class_name ChainManager
extends RefCounted

## Evidence-led chain registration with a deterministic, frame-based desktop equivalent.
## A link requires a different actor within 20 logical frames; gap 0 is a spark chain.
## Matching elements add 20% each. Normal links add 10%, spark links add 40%.

const LINK_WINDOW_FRAMES := 20
const NORMAL_INCREMENT := 10
const SPARK_INCREMENT := 40
const ELEMENT_INCREMENT := 20
const MODIFIER_CAP := 300

var chain_count: int = 0
var chain_modifier: int = 0
var last_frame: int = -9999
var last_actor_id: String = ""
var last_elements: Array[String] = []
var last_family: String = ""
var sparks: int = 0
var resets: int = 0


func register_hit(actor_id: String, frame: int, elements: Array, family: String) -> Dictionary:
	var result: Dictionary = {
		"bonus": 1.0,
		"count": 0,
		"modifier": 0,
		"kind": "initiation",
		"spark": false,
		"reset_reason": ""
	}

	if last_actor_id.is_empty():
		_remember(actor_id, frame, elements, family)
		return result

	if actor_id == last_actor_id:
		_reset_with_reason("same_actor")
		_remember(actor_id, frame, elements, family)
		result["kind"] = "reset"
		result["reset_reason"] = "same_actor"
		return result

	var gap: int = frame - last_frame
	if gap < 0 or gap > LINK_WINDOW_FRAMES:
		_reset_with_reason("timeout")
		_remember(actor_id, frame, elements, family)
		result["kind"] = "reset"
		result["reset_reason"] = "timeout"
		return result

	var increment: int = SPARK_INCREMENT if gap == 0 else NORMAL_INCREMENT
	var matched_elements: int = 0
	for element_variant: Variant in elements:
		var element: String = str(element_variant)
		if element == "non_elemental" or element.is_empty():
			continue
		if last_elements.has(element):
			matched_elements += 1
	increment += matched_elements * ELEMENT_INCREMENT

	chain_modifier = mini(chain_modifier + increment, MODIFIER_CAP)
	chain_count += 1
	result["bonus"] = 1.0 + float(chain_modifier) / 100.0
	result["count"] = chain_count
	result["modifier"] = chain_modifier
	result["kind"] = "spark" if gap == 0 else "normal"
	result["spark"] = gap == 0
	if gap == 0:
		sparks += 1
	_remember(actor_id, frame, elements, family)
	return result


func reset() -> void:
	chain_count = 0
	chain_modifier = 0
	last_frame = -9999
	last_actor_id = ""
	last_elements = []
	last_family = ""
	sparks = 0
	resets = 0


func snapshot() -> Dictionary:
	return {
		"chain_count": chain_count,
		"chain_modifier": chain_modifier,
		"last_actor_id": last_actor_id,
		"last_frame": last_frame,
		"last_elements": last_elements.duplicate(),
		"last_family": last_family,
		"sparks": sparks,
		"resets": resets
	}


func _remember(actor_id: String, frame: int, elements: Array, family: String) -> void:
	last_actor_id = actor_id
	last_frame = frame
	last_elements.clear()
	for element_variant: Variant in elements:
		last_elements.append(str(element_variant))
	last_family = family


func _reset_with_reason(_reason: String) -> void:
	chain_count = 0
	chain_modifier = 0
	resets += 1
	last_actor_id = ""
	last_elements = []
	last_family = ""
