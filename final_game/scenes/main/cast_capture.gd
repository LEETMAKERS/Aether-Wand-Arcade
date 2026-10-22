class_name CastCapture
extends Node
## Owns the cast buffer: prefix, prepared element/style, release, and commitment.
##
## Separated from coordination so the 30 ms confirmation lives in one place.
## It records inputs and reports a committed cast or an ambiguity; it does not
## judge timing or score. Timestamps come from the shared clock passed by Main.

## Emitted when any activation (steps 0..2 prepare, step 3 release) confirms.
signal step_confirmed(step_index: int, target: GameTypes.Target)
## Emitted when the first three activations resolve into a previewable spell.
signal prepared(element: GameTypes.Element, style: GameTypes.CastStyle)
## Emitted after each confirmed preparation input before the third (count 1..2).
signal prefix_changed(count: int)
## Emitted when the fourth activation confirms. release_ms is its timestamp.
signal committed(
	element: GameTypes.Element,
	style: GameTypes.CastStyle,
	lane: GameTypes.Lane,
	release_ms: int,
)
## Emitted when conflicting near-simultaneous activations are detected.
signal ambiguous()

## Reject a different-target activation arriving within this window of another.
const CONFIRM_INTERVAL_MS: int = 30

const PREFIX_LENGTH: int = 3

var _active: bool = false
var _wild_enabled: bool = false
var _prefix: Array[GameTypes.Target] = []
var _prepared_element: GameTypes.Element
var _prepared_style: GameTypes.CastStyle = GameTypes.CastStyle.STABLE
var _committed: bool = false

# Pending confirmation of the most recent activation.
var _pending_target: GameTypes.Target
var _pending_ms: int = -1
var _has_pending: bool = false


## Begin accepting inputs for a fresh attempt. Clears all buffered state.
func open(wild_enabled: bool = false) -> void:
	_active = true
	_wild_enabled = wild_enabled
	_committed = false
	_prefix.clear()
	_prepared_style = GameTypes.CastStyle.STABLE
	_has_pending = false
	_pending_ms = -1


## Stop accepting inputs. Used at cue close.
func close() -> void:
	_active = false
	_has_pending = false


## Feed one normalized activation with its timestamp on the shared clock.
func accept(target: GameTypes.Target, now_ms: int) -> void:
	if not _active or _committed:
		return

	# If the previous activation has outlived its interval, it is final now.
	if _has_pending and now_ms - _pending_ms >= CONFIRM_INTERVAL_MS:
		_confirm_pending()
		if _committed:
			return

	# A different target inside the confirmation interval is ambiguous.
	if _has_pending and target != _pending_target \
			and now_ms - _pending_ms < CONFIRM_INTERVAL_MS:
		_has_pending = false
		_active = false
		ambiguous.emit()
		return

	_has_pending = true
	_pending_target = target
	_pending_ms = now_ms


## Confirm a pending activation once its interval passes without a conflict.
## Main calls this each frame with the shared clock.
func update(now_ms: int) -> void:
	if _active and _has_pending and now_ms - _pending_ms >= CONFIRM_INTERVAL_MS:
		_confirm_pending()


## True while an activation is waiting out its confirmation interval.
func has_pending() -> bool:
	return _has_pending


## Shift pending timestamp forward after an unpaused interval so pause time
## never counts against the 30 ms disambiguation window.
func shift_timestamps(delta_ms: int) -> void:
	if _has_pending and _pending_ms >= 0:
		_pending_ms += delta_ms


func _confirm_pending() -> void:
	if not _has_pending:
		return
	var target: GameTypes.Target = _pending_target
	var release_ms: int = _pending_ms
	_has_pending = false

	if _prefix.size() < PREFIX_LENGTH:
		var step_index: int = _prefix.size()
		_prefix.append(target)
		step_confirmed.emit(step_index, target)
		if _prefix.size() == PREFIX_LENGTH:
			_prepared_element = RecipeRules.interpret_prefix(_prefix)
			_prepared_style = RecipeRules.interpret_style(_prefix, _wild_enabled)
			prepared.emit(_prepared_element, _prepared_style)
		else:
			prefix_changed.emit(_prefix.size())
		return

	# Fourth activation: select lane and commit.
	var lane: GameTypes.Lane = RecipeRules.target_to_lane(target)
	_committed = true
	step_confirmed.emit(PREFIX_LENGTH, target)
	committed.emit(_prepared_element, _prepared_style, lane, release_ms)


func get_prepared_count() -> int:
	return _prefix.size()


func is_prepared() -> bool:
	return _prefix.size() >= PREFIX_LENGTH


func is_committed() -> bool:
	return _committed
