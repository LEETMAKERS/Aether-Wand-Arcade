class_name RecipeRules
## Pure recipe interpretation. No node access and no side effects.
##
## The same functions serve both the live preview and the final judgment, so
## this stays free of presentation and state. Every prefix of three produces
## an element; there are no invalid recipes.

## Interpret the first three accepted activations into a prepared element.
##
## Rule (from the design brief):
##   - If one target appears at least twice, its element wins.
##   - If all three differ, the third activation decides.
## Mapping: LEFT -> A, CENTER -> B, RIGHT -> C.
static func interpret_prefix(prefix: Array[GameTypes.Target]) -> GameTypes.Element:
	assert(prefix.size() == 3, "interpret_prefix expects exactly three activations")

	var counts: Dictionary = {
		GameTypes.Target.LEFT: 0,
		GameTypes.Target.CENTER: 0,
		GameTypes.Target.RIGHT: 0,
	}
	for target: GameTypes.Target in prefix:
		counts[target] += 1

	for target: GameTypes.Target in counts:
		if counts[target] >= 2:
			return target_to_element(target)

	# All three differ: the third activation determines the element.
	return target_to_element(prefix[2])


## Determine whether the three-input prefix is STABLE or WILD.
## In Lite (wild_enabled == false), all prefixes are STABLE.
## When wild_enabled is true, all-different prefixes are WILD.
static func interpret_style(
	prefix: Array[GameTypes.Target],
	wild_enabled: bool,
) -> GameTypes.CastStyle:
	assert(prefix.size() == 3, "interpret_style expects exactly three activations")
	if not wild_enabled:
		return GameTypes.CastStyle.STABLE
	if prefix[0] != prefix[1] and prefix[1] != prefix[2] and prefix[0] != prefix[2]:
		return GameTypes.CastStyle.WILD
	return GameTypes.CastStyle.STABLE


## Map the fourth (release) activation to the destination lane.
static func target_to_lane(target: GameTypes.Target) -> GameTypes.Lane:
	match target:
		GameTypes.Target.LEFT:
			return GameTypes.Lane.LEFT
		GameTypes.Target.CENTER:
			return GameTypes.Lane.CENTER
		_:
			return GameTypes.Lane.RIGHT


## Map a single preparation activation to its corresponding element.
static func target_to_element(target: GameTypes.Target) -> GameTypes.Element:
	match target:
		GameTypes.Target.LEFT:
			return GameTypes.Element.A
		GameTypes.Target.CENTER:
			return GameTypes.Element.B
		_:
			return GameTypes.Element.C
