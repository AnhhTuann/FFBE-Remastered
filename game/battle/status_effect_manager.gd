class_name StatusEffectManager
extends RefCounted

## Ordered status application, duration tracking and turn ticks.
## Same-kind active effects replace by potency; no dormant-layer system is claimed.

func apply(target: CombatantState, effect: Dictionary, source_id: String, rng: BattleRNG) -> Dictionary:
	if target == null or not target.is_alive():
		return _event(false, "target_unavailable", "No living target for status")

	var effect_type: String = str(effect.get("type", ""))
	var turns: int = maxi(int(effect.get("turns", 1)), 1)
	var key: String = ""
	var entry: Dictionary = {}

	match effect_type:
		"buff", "break":
			var stat_name: String = str(effect.get("stat", ""))
			if stat_name.is_empty() or not ["hp", "mp", "atk", "def", "mag", "spr"].has(stat_name):
				return _event(false, "unsupported_effect", "Unsupported stat: %s" % stat_name)
			key = "%s:%s" % [effect_type, stat_name]
			entry = {
				"id": key,
				"kind": effect_type,
				"stat": stat_name,
				"potency": int(effect.get("percent", 0)),
				"turns": turns,
				"source": source_id
			}
		"imperil":
			var element: String = str(effect.get("element", ""))
			if element.is_empty():
				return _event(false, "unsupported_effect", "Imperil requires an element")
			key = "imperil:%s" % element
			entry = {
				"id": key,
				"kind": "imperil",
				"element": element,
				"potency": int(effect.get("percent", 0)),
				"turns": turns,
				"source": source_id
			}
		"status":
			var status_id: String = str(effect.get("status", ""))
			key = "status:%s" % status_id
			var chance: float = float(effect.get("chance", 1.0)) * 100.0
			if rng != null and not rng.chance(chance):
				return _event(false, "status_resisted", "%s resisted %s" % [target.display_name, status_id])
			entry = {
				"id": key,
				"kind": "status",
				"status": status_id,
				"potency": 1,
				"turns": turns,
				"source": source_id
			}
		_:
			return _event(false, "unsupported_effect", "Unsupported status effect: %s" % effect_type)

	var applied: bool = target.add_status(key, entry)
	return _event(applied, effect_type, "%s: %s (%d turns)" % [target.display_name, key, turns])


func tick(target: CombatantState) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if target == null or not target.is_alive():
		return events

	for key: String in target.statuses.keys():
		var entry_variant: Variant = target.statuses.get(key, {})
		if not entry_variant is Dictionary:
			continue
		var entry: Dictionary = entry_variant
		var status_id: String = str(entry.get("status", ""))
		if status_id == "poison":
			var damage: int = target.take_damage(maxi(int(target.max_hp * 0.1), 1))
			events.append(_event(true, "status_tick", "%s loses %d HP to poison" % [target.display_name, damage]))
			entry["applied_damage"] = damage
		elif status_id == "regen":
			var healed: int = target.restore_hp(maxi(int(entry.get("amount", 0)), 0))
			events.append(_event(true, "status_tick", "%s recovers %d HP" % [target.display_name, healed]))

		entry["turns"] = maxi(int(entry.get("turns", 1)) - 1, 0)
		if int(entry["turns"]) <= 0:
			target.remove_status(key)
			events.append(_event(true, "status_expired", "%s expired on %s" % [key, target.display_name]))
		else:
			target.statuses[key] = entry
	return events


func can_act(target: CombatantState, action_kind: String) -> Dictionary:
	if target == null or not target.is_alive():
		return {"ok": false, "reason": "actor_down"}
	for status_id: String in ["sleep", "paralyze", "petrify", "confuse"]:
		if target.has_status("status:%s" % status_id):
			return {"ok": false, "reason": status_id}
	if target.has_status("status:silence") and action_kind == "magical":
		return {"ok": false, "reason": "silence"}
	return {"ok": true, "reason": ""}


func _event(ok: bool, effect_type: String, message: String) -> Dictionary:
	return {"ok": ok, "type": effect_type, "message": message}
