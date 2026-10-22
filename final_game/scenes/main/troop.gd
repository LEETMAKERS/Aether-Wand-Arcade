class_name Troop
extends Node2D
## Presentation seam for one troop. Visuals only; no judging, no clock.
##
## Main tells it where its journey starts and ends, which counter it requires,
## and how far along it is (0.0 at the gate, 1.0 at the contact line).

@export var body: ColorRect
@export var animated_sprite: AnimatedSprite2D
@export var counter_icon: Sprite2D

@export_group("Counter Element Icons")
@export var icon_element_a: Texture2D
@export var icon_element_b: Texture2D
@export var icon_element_c: Texture2D

const ANIM_BY_COUNTER: Dictionary = {
	GameTypes.Element.A: &"element_a",
	GameTypes.Element.B: &"element_b",
	GameTypes.Element.C: &"element_c",
}

const COLOR_IDLE: Color = Color(0.7, 0.7, 0.7)
const COLOR_CLEAN: Color = Color(0.3, 0.9, 0.4)
const COLOR_PARTIAL: Color = Color(0.9, 0.8, 0.3)
const COLOR_FAIL: Color = Color(0.9, 0.3, 0.3)

const DEATH_DURATION_SEC: float = 0.28
const BREACH_DURATION_SEC: float = 0.65
const BREACH_DISTANCE_PX: float = 200.0

var _start_pos: Vector2
var _contact_pos: Vector2
var _resolving: bool = false


func _ready() -> void:
	clear()


## Set the endpoints of this troop's path, in world coordinates.
func configure(start_pos: Vector2, contact_pos: Vector2) -> void:
	_start_pos = start_pos
	_contact_pos = contact_pos
	global_position = start_pos
	scale = Vector2(0.7, 0.7)
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Select the troop animation and overhead counter badge for this cue.
func setup_visuals(required_counter: GameTypes.Element) -> void:
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		var anim_name: StringName = ANIM_BY_COUNTER.get(required_counter, &"default")
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)
		elif animated_sprite.sprite_frames.has_animation(&"default"):
			animated_sprite.play(&"default")
	if counter_icon != null:
		counter_icon.texture = _texture_for_element(required_counter)


## Place the troop along its path. 0.0 is the gate, 1.0 is the contact line.
func set_progress(t: float) -> void:
	if _resolving:
		return
	global_position = _start_pos.lerp(_contact_pos, clampf(t, 0.0, 1.0))


## Apply the single visual reaction to the committed outcome and free when done.
func show_outcome(result: JudgeResult) -> void:
	_resolving = true
	if body != null:
		match result.outcome:
			JudgeResult.Outcome.CLEAN_KILL:
				body.color = COLOR_CLEAN
			JudgeResult.Outcome.WRONG_ELEMENT_KILL:
				body.color = COLOR_PARTIAL
			_:
				body.color = COLOR_FAIL

	var tween: Tween = create_tween().set_parallel(true)
	match result.outcome:
		JudgeResult.Outcome.CLEAN_KILL:
			modulate = Color(2.4, 2.4, 2.4, 1.0)
			scale = Vector2(1.28, 1.28)
			tween.tween_property(self, ^"scale", Vector2(0.15, 0.15), DEATH_DURATION_SEC) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(self, ^"rotation", 0.35, DEATH_DURATION_SEC)
			tween.tween_property(self, ^"modulate:a", 0.0, DEATH_DURATION_SEC)
		JudgeResult.Outcome.WRONG_ELEMENT_KILL:
			modulate = Color(1.8, 0.85, 0.35, 1.0)
			scale = Vector2(1.15, 1.15)
			tween.tween_property(self, ^"scale", Vector2(0.25, 0.25), DEATH_DURATION_SEC)
			tween.tween_property(self, ^"modulate:a", 0.0, DEATH_DURATION_SEC)
		_:
			# Survivor keeps marching past the contact line toward the base and fades out.
			if result.outcome == JudgeResult.Outcome.WRONG_ELEMENT_SURVIVE:
				modulate = Color(1.5, 0.65, 0.45, 1.0)
			tween.tween_property(
				self,
				^"global_position:y",
				global_position.y + BREACH_DISTANCE_PX,
				BREACH_DURATION_SEC,
			).set_trans(Tween.TRANS_LINEAR)
			tween.tween_property(self, ^"modulate:a", 0.0, BREACH_DURATION_SEC) \
				.set_delay(0.15)

	tween.chain().tween_callback(queue_free)


## Reset to the idle look at the start of an attempt.
func clear() -> void:
	_resolving = false
	modulate = Color.WHITE
	rotation = 0.0
	if body != null:
		body.color = COLOR_IDLE


func _texture_for_element(element: GameTypes.Element) -> Texture2D:
	match element:
		GameTypes.Element.A:
			return icon_element_a
		GameTypes.Element.B:
			return icon_element_b
		_:
			return icon_element_c
