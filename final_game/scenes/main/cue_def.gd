class_name CueDef
extends RefCounted
## One cue's read-only settings: what it demands and when it arrives.
##
## This is the "definition" half of the settings-versus-progress split. It is
## never mutated during play; live attempt state lives elsewhere. Contact time
## is a value on the shared monotonic clock (Time.get_ticks_msec()).

var required_counter: GameTypes.Element
var lane: GameTypes.Lane
var contact_ms: int


func _init(
	p_required_counter: GameTypes.Element,
	p_lane: GameTypes.Lane,
	p_contact_ms: int,
) -> void:
	required_counter = p_required_counter
	lane = p_lane
	contact_ms = p_contact_ms
