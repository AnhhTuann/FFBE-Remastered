class_name EventSchedule
extends RefCounted

## Prompt 07 availability states. The clock is injectable so schedule boundary
## tests never read the OS clock; production constructs it with the default.

const STATE_UPCOMING := "upcoming"
const STATE_ACTIVE := "active"
const STATE_ENDED := "ended"
const STATE_ARCHIVED := "archived"
const STATE_PERMANENT := "permanent"
const STATE_REPLAYABLE := "replayable"

var _clock: Callable = Callable()


func _init(clock: Callable = Callable()) -> void:
	_clock = clock


func now() -> int:
	if _clock.is_valid():
		return maxi(0, int(_clock.call()))
	return maxi(0, int(Time.get_unix_time_from_system()))


func state(event: Dictionary, region: String, unlock_met: bool = true, now_unix: int = -1) -> String:
	if event.is_empty():
		return STATE_ENDED
	var availability: Dictionary = event.get("availability", {})
	if str(availability.get("mode", "")) == "permanent":
		return STATE_PERMANENT
	var regions_variant: Variant = event.get("regions", {})
	if not regions_variant is Dictionary:
		return STATE_ENDED
	var config_variant: Variant = (regions_variant as Dictionary).get(region, null)
	if not config_variant is Dictionary:
		return STATE_ENDED
	var config: Dictionary = config_variant
	var current: int = now() if now_unix < 0 else maxi(0, now_unix)
	var start_unix: int = int(config.get("start_unix", 0))
	var end_unix: int = int(config.get("end_unix", 0))
	if end_unix <= start_unix:
		return STATE_ENDED
	if current < start_unix:
		return STATE_UPCOMING
	if current < end_unix:
		return STATE_ACTIVE
	var replay: Dictionary = event.get("replay_policy", {})
	if bool(replay.get("replay_enabled", false)) and unlock_met:
		return STATE_REPLAYABLE
	if bool(replay.get("archive_after_end", false)):
		return STATE_ARCHIVED
	return STATE_ENDED


func can_enter(event: Dictionary, region: String, unlock_met: bool = true, now_unix: int = -1) -> bool:
	var current_state: String = state(event, region, unlock_met, now_unix)
	return current_state == STATE_ACTIVE or current_state == STATE_PERMANENT or current_state == STATE_REPLAYABLE


func is_past(event: Dictionary, region: String, unlock_met: bool = true, now_unix: int = -1) -> bool:
	var current_state: String = state(event, region, unlock_met, now_unix)
	return current_state == STATE_ENDED or current_state == STATE_ARCHIVED or current_state == STATE_REPLAYABLE


func state_key(current_state: String) -> String:
	return "event.state.%s" % current_state
