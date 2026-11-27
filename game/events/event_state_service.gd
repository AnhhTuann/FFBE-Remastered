class_name EventStateService
extends RefCounted

## Prompt 07 progression and settlement. Every mutation is staged into one
## PlayerState.transaction("events", ...), reuses the canonical reward ledger,
## and commits through the existing atomic save path. Definitions are read-only.

var _state: Node = null
var _repository: EventRepository = null


func _init(state_node: Node, repository: Variant = null) -> void:
	_state = state_node
	if repository is EventRepository:
		_repository = repository
	elif repository is Node and (repository as Node).has_method("get_event_pack"):
		_repository = EventRepository.new(repository as Node)
	else:
		_repository = EventRepository.new()


func repository() -> EventRepository:
	return _repository


func section() -> Dictionary:
	if _state == null:
		return {}
	var value: Variant = _state.data.get("events", {})
	if not value is Dictionary:
		return _state.call("default_event_state")
	return (value as Dictionary).duplicate(true)


func get_stage_progress(event_id: String, stage_id: String) -> Dictionary:
	var key: String = "%s|%s" % [event_id, stage_id]
	var progress_variant: Variant = section().get("progress", {})
	if not progress_variant is Dictionary:
		return {"runs": 0, "cleared": false, "completed": false}
	var progress: Dictionary = progress_variant
	var entry_variant: Variant = progress.get(key, {})
	var entry: Dictionary = entry_variant if entry_variant is Dictionary else {}
	return {
		"runs": int(entry.get("runs", 0)),
		"cleared": bool((section().get("first_clears", {}) as Dictionary).has(key)),
		"completed": bool((section().get("completions", {}) as Dictionary).has(key))
	}


func is_stage_unlocked(event_id: String, stage_id: String) -> bool:
	var stage: Dictionary = _repository.get_event_stage(stage_id)
	if stage.is_empty() or str(stage.get("event_id", "")) != event_id:
		return false
	var first_clears_variant: Variant = section().get("first_clears", {})
	var first_clears: Dictionary = first_clears_variant if first_clears_variant is Dictionary else {}
	for prereq_variant: Variant in (stage.get("unlock_after", []) as Array):
		var prereq_id: String = str(prereq_variant)
		if not first_clears.has("%s|%s" % [event_id, prereq_id]):
			return false
	return true


func mission_status(event_id: String, mission_id: String) -> Dictionary:
	var mission: Dictionary = _repository.event_mission(event_id, mission_id)
	if mission.is_empty():
		return {"ok": false, "reason": "invalid_mission"}
	var key: String = "%s|%s" % [event_id, mission_id]
	var progress_variant: Variant = section().get("mission_progress", {})
	var progress: Dictionary = progress_variant if progress_variant is Dictionary else {}
	var count: int = int(progress.get(key, 0))
	var target: int = int(mission.get("target", 1))
	var claim_key: String = "world|event|mission|%s" % key
	var claims_variant: Variant = _state.data.get("reward_claims", {})
	var claims: Dictionary = claims_variant if claims_variant is Dictionary else {}
	return {
		"ok": true, "reason": "", "count": mini(count, target), "target": target,
		"complete": count >= target, "claimed": claims.has(claim_key)
	}


func currency_amount(currency_id: String) -> int:
	var currency_variant: Variant = section().get("currency", {})
	if not currency_variant is Dictionary:
		return 0
	return int((currency_variant as Dictionary).get(currency_id, 0))


## Canonical event battle settlement. A duplicate run is a hard no-op before
## the write guard, pending capture and transaction. Reward, first clear,
## currency, missions, progress and receipt commit together or not at all.
func settle_battle(result: Dictionary, context: Dictionary = {}) -> Dictionary:
	var run_id: String = str(result.get("run_id", ""))
	var event_id: String = str(context.get("event_id", result.get("event_id", "")))
	var stage_id: String = str(context.get("stage_id", result.get("stage_id", "")))
	if run_id.is_empty() or event_id.is_empty() or stage_id.is_empty():
		return {"ok": false, "reason": "invalid_result", "message": "event.invalid_result"}
	var event: Dictionary = _repository.get_event(event_id)
	var stage: Dictionary = _repository.get_event_stage(stage_id)
	if event.is_empty() or stage.is_empty():
		return {"ok": false, "reason": "invalid_context", "message": "event.invalid_context"}
	if str(stage.get("event_id", "")) != event_id:
		return {"ok": false, "reason": "invalid_context", "message": "event.invalid_context"}
	var encounter_id: String = str(stage.get("encounter_id", ""))
	var result_encounter: String = str(result.get("encounter_id", ""))
	var context_encounter: String = str(context.get("encounter_id", ""))
	if result_encounter != encounter_id or (not context_encounter.is_empty() and context_encounter != encounter_id):
		return {"ok": false, "reason": "invalid_context", "message": "event.invalid_context"}
	var region: String = str(context.get("region", stage.get("region", "")))
	if region.is_empty() or not (event.get("regions", {}) as Dictionary).has(region):
		return {"ok": false, "reason": "invalid_context", "message": "event.invalid_context"}

	var current: Dictionary = section()
	var processed_variant: Variant = current.get("processed_runs", {})
	var processed: Dictionary = processed_variant if processed_variant is Dictionary else {}
	if processed.has(run_id):
		var prior_variant: Variant = processed[run_id]
		var prior: Dictionary = prior_variant if prior_variant is Dictionary else {}
		if str(prior.get("event_id", "")) != event_id or str(prior.get("stage_id", "")) != stage_id:
			return {"ok": false, "reason": "invalid_context", "message": "event.invalid_context"}
		return {
			"ok": true, "reason": "", "duplicate": true,
			"reward": {"ok": false, "reason": "already_claimed", "message": "reward.already_claimed"},
			"event": {"ok": true, "reason": "", "duplicate": true}
		}

	if not bool(_state.call("is_write_allowed")):
		return {"ok": false, "reason": "read_only", "message": "save.error.read_only"}

	_state.set("_pending_battle_result", result.duplicate(true))
	_state.set("_pending_battle_context", context.duplicate(true))
	_state.set("_pending_battle_kind", "event")

	var victory: bool = bool(result.get("victory", false))
	var staged_result: Dictionary = result.duplicate(true)
	var staged_context: Dictionary = context.duplicate(true)
	var outcome: Dictionary = _state.call("transaction", "event_settlement", func() -> Dictionary:
		var working: Dictionary = _mutable_section()
		var receipts: Dictionary = working["processed_runs"]
		var receipt: Dictionary = {
			"run_id": run_id, "event_id": event_id, "stage_id": stage_id,
			"region": region, "encounter_id": encounter_id,
			"outcome": "victory" if victory else "defeat"
		}
		receipts[run_id] = receipt
		working["processed_runs"] = receipts
		working["last_result"] = staged_result.duplicate(true)
		if not victory:
			_state.data["events"] = working
			return {
				"ok": true, "reason": "not_victory", "duplicate": false,
				"reward": {"ok": false, "reason": "not_victory", "message": "battle.not_victory"},
				"event": {"ok": true, "reason": "not_victory", "duplicate": false}
			}

		var reward_outcomes: Array[Dictionary] = []
		var first_key: String = "%s|%s" % [event_id, stage_id]
		var first_clears: Dictionary = working["first_clears"]
		if not first_clears.has(first_key):
			var first_reward: Variant = stage.get("first_clear_reward", {})
			var first_result: Dictionary = _claim_event(
				"first", "%s|%s" % [event_id, stage_id],
				first_reward.duplicate(true) if first_reward is Dictionary else {}
			)
			reward_outcomes.append(first_result)
			if bool(first_result.get("ok", false)):
				first_clears[first_key] = true
		working["first_clears"] = first_clears

		var repeat_reward: Variant = stage.get("repeat_reward", {})
		var repeat_result: Dictionary = _claim_event(
			"run", run_id,
			repeat_reward.duplicate(true) if repeat_reward is Dictionary else {}
		)
		reward_outcomes.append(repeat_result)

		var currency_variant: Variant = stage.get("currency", {})
		if currency_variant is Dictionary:
			var currency: Dictionary = currency_variant
			var currency_id: String = str(currency.get("id", ""))
			var amount: int = maxi(0, int(currency.get("amount", 0)))
			if not currency_id.is_empty() and amount > 0:
				var currency_state: Dictionary = working["currency"]
				currency_state[currency_id] = int(currency_state.get(currency_id, 0)) + amount
				working["currency"] = currency_state

		var progress: Dictionary = working["progress"]
		var progress_entry_variant: Variant = progress.get(first_key, {})
		var progress_entry: Dictionary = progress_entry_variant if progress_entry_variant is Dictionary else {}
		progress_entry["runs"] = int(progress_entry.get("runs", 0)) + 1
		progress_entry["cleared"] = true
		progress[first_key] = progress_entry
		var completed: Dictionary = working["completions"]
		if int(progress_entry["runs"]) >= maxi(1, int(stage.get("completion_target", 1))):
			completed[first_key] = true
		working["progress"] = progress
		working["completions"] = completed

		var mission_progress: Dictionary = working["mission_progress"]
		for mission_variant: Variant in (event.get("missions", []) as Array):
			if not mission_variant is Dictionary:
				continue
			var mission: Dictionary = mission_variant
			var mission_key: String = "%s|%s" % [event_id, str(mission.get("id", ""))]
			mission_progress[mission_key] = int(mission_progress.get(mission_key, 0)) + 1
		working["mission_progress"] = mission_progress
		_state.data["events"] = working

		var claim_error: Dictionary = {}
		for claim_result: Dictionary in reward_outcomes:
			var reason: String = str(claim_result.get("reason", ""))
			if not bool(claim_result.get("ok", false)) and reason != "already_claimed":
				claim_error = claim_result
				break
		if not claim_error.is_empty():
			return claim_error
		return {
			"ok": true, "reason": "", "duplicate": false,
			"reward": {
				"ok": true, "reason": "",
				"key": str(reward_outcomes[0].get("key", "")),
				"rewards": _merged_rewards(reward_outcomes)
			},
			"event": {
				"ok": true, "reason": "", "duplicate": false,
				"event_id": event_id, "stage_id": stage_id, "region": region,
				"first_clear": bool(first_clears.has(first_key)),
				"completion": bool(completed.has(first_key)),
				"context": staged_context.duplicate(true)
			}
		}
	)
	if str(outcome.get("reason", "")) != "save_failed":
		_state.call("clear_pending_battle_result")
	return outcome


func claim_mission(event_id: String, mission_id: String) -> Dictionary:
	var mission: Dictionary = _repository.event_mission(event_id, mission_id)
	if mission.is_empty():
		return {"ok": false, "reason": "invalid_mission", "message": "event.invalid_mission"}
	var status: Dictionary = mission_status(event_id, mission_id)
	if bool(status.get("claimed", false)):
		return {"ok": false, "reason": "already_claimed", "key": "world|event|mission|%s|%s" % [event_id, mission_id], "message": "reward.already_claimed"}
	if not bool(status.get("complete", false)):
		return {"ok": false, "reason": "mission_incomplete", "message": "event.mission_incomplete"}
	if not bool(_state.call("is_write_allowed")):
		return {"ok": false, "reason": "read_only", "message": "save.error.read_only"}
	return _state.call("transaction", "event_mission", func() -> Dictionary:
		return _claim_event(
			"mission", "%s|%s" % [event_id, mission_id],
			(mission.get("reward", {}) as Dictionary).duplicate(true)
		)
	)


func purchase_shop_item(event_id: String, item_id: String) -> Dictionary:
	var event: Dictionary = _repository.get_event(event_id)
	var item: Dictionary = _repository.shop_item(event_id, item_id)
	if event.is_empty() or item.is_empty():
		return {"ok": false, "reason": "invalid_item", "message": "event.invalid_item"}
	var currency_id: String = str(item.get("currency", ""))
	var cost: int = int(item.get("cost", 0))
	var claim_key: String = "world|event|shop|%s|%s" % [event_id, item_id]
	var claims_variant: Variant = _state.data.get("reward_claims", {})
	var claims: Dictionary = claims_variant if claims_variant is Dictionary else {}
	if claims.has(claim_key):
		return {"ok": false, "reason": "already_claimed", "key": claim_key, "message": "reward.already_claimed"}
	if currency_amount(currency_id) < cost:
		return {"ok": false, "reason": "insufficient_currency", "message": "event.insufficient_currency"}
	if not bool(_state.call("is_write_allowed")):
		return {"ok": false, "reason": "read_only", "message": "save.error.read_only"}
	return _state.call("transaction", "event_shop", func() -> Dictionary:
		var working: Dictionary = _mutable_section()
		var currency: Dictionary = working["currency"]
		var available: int = int(currency.get(currency_id, 0))
		if available < cost:
			return {"ok": false, "reason": "insufficient_currency", "message": "event.insufficient_currency"}
		currency[currency_id] = available - cost
		working["currency"] = currency
		_state.data["events"] = working
		var reward_variant: Variant = item.get("reward", {})
		return _claim_event(
			"shop", "%s|%s" % [event_id, item_id],
			reward_variant.duplicate(true) if reward_variant is Dictionary else {}
		)
	)


func _mutable_section() -> Dictionary:
	var value: Variant = _state.data.get("events", null)
	var section: Dictionary = value if value is Dictionary else _state.call("default_event_state")
	for key: String in ["progress", "first_clears", "completions", "currency", "mission_progress", "processed_runs", "claims", "last_result"]:
		if not section.has(key) or section[key] == null:
			section[key] = {} if key != "last_result" else {}
		elif not (section[key] is Dictionary):
			section[key] = {}
	return section


func _claim_event(kind: String, identity: String, reward: Dictionary) -> Dictionary:
	var key: String = "world|event|%s|%s" % [kind, identity]
	var claims_variant: Variant = _state.data.get("reward_claims", {})
	var claims: Dictionary = claims_variant if claims_variant is Dictionary else {}
	if claims.has(key):
		return {"ok": false, "reason": "already_claimed", "key": key, "message": "reward.already_claimed"}
	var result: Dictionary = _state.call("_stage_world_claim", "event", identity, reward, key)
	if not bool(result.get("ok", false)):
		return result
	var section: Dictionary = _mutable_section()
	var event_claims: Dictionary = section["claims"]
	event_claims[key] = {
		"key": key, "kind": kind, "identity": identity,
		"rewards": (result.get("rewards", {}) as Dictionary).duplicate(true)
	}
	section["claims"] = event_claims
	_state.data["events"] = section
	return result


func _merged_rewards(outcomes: Array[Dictionary]) -> Dictionary:
	var merged: Dictionary = {}
	for outcome: Dictionary in outcomes:
		var rewards_variant: Variant = outcome.get("rewards", {})
		if not rewards_variant is Dictionary:
			continue
		for key_variant: Variant in (rewards_variant as Dictionary).keys():
			var key: String = str(key_variant)
			merged[key] = int(merged.get(key, 0)) + int((rewards_variant as Dictionary)[key_variant])
	return merged
