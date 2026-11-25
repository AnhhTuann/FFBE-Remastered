class_name BattleRNG
extends RefCounted

## Deterministic linear congruential generator used by every stochastic battle rule.
## Replaying the same seed and action sequence yields identical variance and AI choices.

var state: int = 1


func _init(seed_value: int = 1) -> void:
	reset(seed_value)


func reset(seed_value: int) -> void:
	state = seed_value if seed_value != 0 else 1
	state = state & 0x7fffffff


func next_int() -> int:
	state = (state * 1103515245 + 12345) & 0x7fffffff
	return state


func next_float() -> float:
	return float(next_int()) / 2147483647.0


func range_int(minimum: int, maximum: int) -> int:
	if maximum <= minimum:
		return minimum
	return minimum + (next_int() % (maximum - minimum + 1))


func range_float(minimum: float, maximum: float) -> float:
	if maximum <= minimum:
		return minimum
	return minimum + next_float() * (maximum - minimum)


func chance(percent: float) -> bool:
	return next_float() * 100.0 < percent


func snapshot() -> int:
	return state
