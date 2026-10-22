class_name InputRouter
extends Node
## Normalizes keyboard actions into one fresh activation per tap.
##
## This is the only layer that knows about the input source. It emits exactly
## one signal per fresh activation and enforces rearming: a held key does not
## repeat, and a target can fire again only after it is released. It makes no
## element, recipe, or combat decisions. A future ESP32 transport replaces
## this node without touching the rest of the game.

signal target_activated(target: GameTypes.Target)

## Maps each gameplay target to its development keyboard action.
const ACTIONS: Dictionary = {
	GameTypes.Target.LEFT: &"cast_left",
	GameTypes.Target.CENTER: &"cast_center",
	GameTypes.Target.RIGHT: &"cast_right",
}


func _unhandled_input(event: InputEvent) -> void:
	for target: GameTypes.Target in ACTIONS:
		var action: StringName = ACTIONS[target]
		# is_action_pressed() is false for echo events, so a held key fires
		# once; the next activation requires a release (just_released) first.
		if event.is_action_pressed(action):
			target_activated.emit(target)
			return
