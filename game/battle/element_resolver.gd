class_name ElementResolver
extends RefCounted

## Averages multi-element attacks against target resistance and clamps the result.
## Fixture resistances are stored as whole percentages (10 means 10%).
## Evidence: exvius.fandom.com/wiki/Mechanics#Elemental_Resistance.

static func effective_resist(element: String, target: CombatantState) -> float:
	if target == null:
		return 0.0
	var value: float = float(target.resist.get(element, 0.0)) / 100.0
	for entry_variant: Variant in target.statuses.values():
		if not entry_variant is Dictionary:
			continue
		var entry: Dictionary = entry_variant
		if str(entry.get("kind", "")) == "imperil" and str(entry.get("element", "")) == element:
			value -= float(entry.get("potency", 0)) / 100.0
	return clampf(value, -1.0, 1.0)


static func multiplier(elements: Array, target: CombatantState) -> float:
	if elements.is_empty():
		return 1.0
	var total: float = 0.0
	var counted: int = 0
	for element_variant: Variant in elements:
		var element: String = str(element_variant)
		if element.is_empty() or element == "non_elemental":
			continue
		total += 1.0 - effective_resist(element, target)
		counted += 1
	if counted == 0:
		return 1.0
	return maxf(total / float(counted), 0.0)
