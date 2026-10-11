# input_handler.gd
# Translates raw key presses into lane signals.
# To integrate Hall-effect hardware: replace _unhandled_key_input
# with hardware polling (e.g. serial/USB read) — nothing else changes.
class_name InputHandler
extends Node

# Emitted each time a lane sensor / key fires.
# lane_index: 0 = left, 1 = centre, 2 = right
signal lane_pressed(lane_index: int)

# Key → lane-index mapping. Edit here to remap controls.
const BINDINGS : Dictionary = {
    KEY_A:     0,   # left lane
    KEY_S:     1,   # centre lane
    KEY_D:     2,   # right lane
    KEY_LEFT:  0,   # arrow-key alternates
    KEY_DOWN:  1,
    KEY_RIGHT: 2,
}

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if BINDINGS.has(event.keycode):
            lane_pressed.emit(BINDINGS[event.keycode])
