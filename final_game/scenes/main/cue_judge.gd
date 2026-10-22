class_name CueJudge
## Pure timing and outcome judgment. No node access, no side effects.
##
## Grades the fourth activation's timestamp against the cue's contact time and
## applies the Lite/Full reward table. All times are milliseconds on the shared
## monotonic clock.

enum Timing { PERFECT, GOOD, EARLY, MISS }

## Timing windows relative to contact time T, in milliseconds (from the brief).
const PERFECT_BEFORE_MS: int = 50 # T-50 .. T+50 inclusive.
const PERFECT_AFTER_MS: int = 50
const GOOD_BEFORE_MS: int = 140 # T-140 .. T+120, excluding Perfect.
const GOOD_AFTER_MS: int = 120

## Stable Break rewards (correct lane + correct element).
const BREAK_CLEAN_GOOD: int = 6
const BREAK_CLEAN_PERFECT: int = 8
## Wild Break rewards (correct lane + correct element, when Wild is enabled).
const BREAK_WILD_GOOD: int = 3
const BREAK_WILD_PERFECT: int = 10
## Correct lane, wrong element.
const BREAK_WRONG_ELEMENT_PERFECT: int = 1 # Ragged kill.

const TROOP_HP: int = 2


## Grade a release timestamp against contact time. A release with no eligible
## fourth input is reported as MISS by the caller; this grades an actual press.
static func grade_timing(
	release_ms: int,
	contact_ms: int,
	perfect_window_ms: int = PERFECT_BEFORE_MS,
	good_before_ms: int = GOOD_BEFORE_MS,
	good_after_ms: int = GOOD_AFTER_MS,
) -> Timing:
	var delta: int = release_ms - contact_ms # Negative is early, positive late.
	var eff_good_before: int = maxi(good_before_ms, perfect_window_ms)
	var eff_good_after: int = maxi(good_after_ms, perfect_window_ms)
	if delta >= -perfect_window_ms and delta <= perfect_window_ms:
		return Timing.PERFECT
	if delta >= -eff_good_before and delta <= eff_good_after:
		return Timing.GOOD
	if delta < -eff_good_before:
		return Timing.EARLY
	return Timing.MISS # Later than the Good window.


## Produce the single result for an attempt. `lane`, `element`, and `style` are
## the committed choices; pass Timing.MISS for an unfinished spell and let the
## ambiguous path be handled by the caller via make_ambiguous().
static func judge(
	cue: CueDef,
	element: GameTypes.Element,
	lane: GameTypes.Lane,
	timing: Timing,
	style: GameTypes.CastStyle = GameTypes.CastStyle.STABLE,
) -> JudgeResult:
	if timing == Timing.MISS:
		return JudgeResult.new(JudgeResult.Outcome.MISS, 0, 0)
	if timing == Timing.EARLY:
		return JudgeResult.new(JudgeResult.Outcome.EARLY, 0, 0)
	if lane != cue.lane:
		return JudgeResult.new(JudgeResult.Outcome.WRONG_LANE, 0, 0)

	var is_perfect: bool = timing == Timing.PERFECT

	if element == cue.required_counter:
		var break_value: int = 0
		if style == GameTypes.CastStyle.WILD:
			break_value = BREAK_WILD_PERFECT if is_perfect else BREAK_WILD_GOOD
		else:
			break_value = BREAK_CLEAN_PERFECT if is_perfect else BREAK_CLEAN_GOOD
		return JudgeResult.new(JudgeResult.Outcome.CLEAN_KILL, break_value, TROOP_HP)

	# Correct lane, wrong element.
	if is_perfect:
		return JudgeResult.new(
			JudgeResult.Outcome.WRONG_ELEMENT_KILL, BREAK_WRONG_ELEMENT_PERFECT, TROOP_HP
		)
	return JudgeResult.new(JudgeResult.Outcome.WRONG_ELEMENT_SURVIVE, 0, 1)


## Build the unfinished/miss result (no eligible fourth activation in time).
static func make_miss() -> JudgeResult:
	return JudgeResult.new(JudgeResult.Outcome.MISS, 0, 0)


## Build the ambiguous result (conflicting near-simultaneous activations).
static func make_ambiguous() -> JudgeResult:
	return JudgeResult.new(JudgeResult.Outcome.AMBIGUOUS, 0, 0)
