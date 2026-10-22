class_name JudgeResult
extends RefCounted
## The single outcome of one committed attempt.
##
## Exactly one of these is produced per cue, including a miss. It carries the
## outcome category, the Break awarded to the summoner, and the troop damage
## dealt. Presentation reads it; it never recounts inputs or re-judges.

enum Outcome {
	CLEAN_KILL, # Correct element + lane: full Break.
	WRONG_ELEMENT_KILL, # Correct lane, wrong element, Perfect: ragged kill.
	WRONG_ELEMENT_SURVIVE, # Correct lane, wrong element, Good: troop breaches.
	WRONG_LANE, # Right spell, wrong destination.
	EARLY, # Released before the Good window.
	MISS, # No eligible fourth input in time.
	AMBIGUOUS, # Near-simultaneous conflicting activations.
}

var outcome: Outcome
var break_value: int
var troop_damage: int


func _init(p_outcome: Outcome, p_break_value: int, p_troop_damage: int) -> void:
	outcome = p_outcome
	break_value = p_break_value
	troop_damage = p_troop_damage
