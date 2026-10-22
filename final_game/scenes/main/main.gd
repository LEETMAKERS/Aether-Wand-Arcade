extends Node
## Coordinates the 60-second / 21-cue round (preset or random, Lite or Wild)
## on a single monotonic clock (Time.get_ticks_msec()), triggers line-centered
## attack effects, computes the 1.0-10.0 score, and logs results to project files.

enum CueState { IDLE, ACTIVE, RESOLVED }

@export var input_router: InputRouter # Emits target_activated.
@export var hud: Hud # Display only.
@export var cast_capture: CastCapture # Prefix, commit, 30 ms confirmation.
@export var troop_scene: PackedScene # troop.tscn, instanced per cue.

@export_group("Difficulty & Scoring Tuning")
## Overall game speed multiplier (0.5 = slower, 1.0 = normal, 1.5+ = faster).
@export_range(0.4, 2.5, 0.1) var game_speed: float = 1.0
## Half-width of the Perfect release window around contact T, in milliseconds.
@export_range(20, 200, 5) var perfect_window_ms: int = 50
## Half-width of the Good/Great release window around contact T, in milliseconds.
@export_range(60, 400, 10) var good_window_ms: int = 130
## How long (ms at 1.0x speed) a troop takes to walk from the gate to the line.
@export_range(800, 3500, 100) var cue_lead_ms: int = 2100
## Break points required to defeat the Summoner (Victory threshold).
@export_range(30, 180, 5) var break_target: int = 100
## Break points required to achieve a 10.0 score (lower = easier to get 10.0!).
@export_range(40, 210, 5) var break_for_max_score: int = 140

@export_group("Optional layout markers")
## Lane positions. If unassigned, viewport-relative defaults are used.
@export var lane_left: Marker2D
@export var lane_center: Marker2D
@export var lane_right: Marker2D
## Horizontal bar whose vertical centre is the contact line.
@export var contact_line: ColorRect
## Optional AnimatedSprite2D placed in Arena to show elemental attack bursts.
@export var attack_effect: AnimatedSprite2D

const START_CUE_ACTION: StringName = &"start_cue"
const RESET_ACTION: StringName = &"reset_cast"

## Baseline round duration in milliseconds (60 seconds at 1.0x speed).
const BASE_ROUND_DURATION_MS: int = 60000

## File paths saved directly in the project folder.
const HIGH_SCORE_FILE: String = "res://high_scores.txt"
const GAME_LOG_FILE: String = "res://game_log.csv"

## 21 contact times in milliseconds at 1.0x speed (from docs/game-design.md).
const PRESET_CONTACT_MS: Array[int] = [
	3200, 6400, 9600, 12800, 16000, 19200, 22400,
	25200, 28000, 30800, 33600, 36400, 39200, 42000,
	44400, 46800, 49200, 51600, 54000, 56400, 58800,
]

## 21 required counters for the preset schedule.
const PRESET_COUNTERS: Array[GameTypes.Element] = [
	GameTypes.Element.A, GameTypes.Element.B, GameTypes.Element.C,
	GameTypes.Element.A, GameTypes.Element.B, GameTypes.Element.C, GameTypes.Element.A,
	GameTypes.Element.B, GameTypes.Element.A, GameTypes.Element.A,
	GameTypes.Element.C, GameTypes.Element.B, GameTypes.Element.C, GameTypes.Element.B,
	GameTypes.Element.C, GameTypes.Element.B, GameTypes.Element.A,
	GameTypes.Element.C, GameTypes.Element.C, GameTypes.Element.A, GameTypes.Element.B,
]

## 21 lanes for the preset schedule.
const PRESET_LANES: Array[GameTypes.Lane] = [
	GameTypes.Lane.LEFT, GameTypes.Lane.CENTER, GameTypes.Lane.RIGHT,
	GameTypes.Lane.CENTER, GameTypes.Lane.LEFT, GameTypes.Lane.CENTER, GameTypes.Lane.RIGHT,
	GameTypes.Lane.RIGHT, GameTypes.Lane.LEFT, GameTypes.Lane.CENTER,
	GameTypes.Lane.RIGHT, GameTypes.Lane.CENTER, GameTypes.Lane.LEFT, GameTypes.Lane.RIGHT,
	GameTypes.Lane.CENTER, GameTypes.Lane.LEFT, GameTypes.Lane.RIGHT,
	GameTypes.Lane.RIGHT, GameTypes.Lane.LEFT, GameTypes.Lane.LEFT, GameTypes.Lane.CENTER,
]

const ATTACK_ANIM_BY_ELEMENT: Dictionary = {
	GameTypes.Element.A: &"element_a",
	GameTypes.Element.B: &"element_b",
	GameTypes.Element.C: &"element_c",
}

## Viewport-relative defaults when markers are not placed in the editor.
const DEFAULT_LANE_X: Dictionary = {
	GameTypes.Lane.LEFT: 0.25,
	GameTypes.Lane.CENTER: 0.5,
	GameTypes.Lane.RIGHT: 0.75,
}
const DEFAULT_SPAWN_Y: float = 0.1
const DEFAULT_CONTACT_Y: float = 0.6

var _round_active: bool = false
var _paused: bool = false
var _pause_start_ms: int = 0
var _round_start_ms: int = 0
var _active_speed: float = 1.0
var _active_lead_ms: int = 2100
var _active_round_duration_ms: int = BASE_ROUND_DURATION_MS
var _schedule: Array[CueDef] = []
var _next_cue_index: int = 0

var _player_login: String = "player"
var _use_random_cues: bool = false
var _wild_enabled: bool = false

var _state: CueState = CueState.IDLE
var _cue: CueDef
var _open_ms: int = 0
var _troop: Troop
var _pending_result: JudgeResult # Judged result waiting for max(T, confirm).
var _pending_element: GameTypes.Element = GameTypes.Element.A
var _pending_lane: GameTypes.Lane = GameTypes.Lane.CENTER
var _play_attack_on_apply: bool = false
var _break_total: int = 0

var _high_score: float = 1.0
var _high_score_holder: String = "-"


func _ready() -> void:
	randomize()
	_load_high_score()
	input_router.target_activated.connect(_on_target_activated)
	cast_capture.step_confirmed.connect(_on_step_confirmed)
	cast_capture.prefix_changed.connect(_on_prefix_changed)
	cast_capture.prepared.connect(_on_prepared)
	cast_capture.committed.connect(_on_committed)
	cast_capture.ambiguous.connect(_on_ambiguous)
	hud.start_round_requested.connect(_on_start_round_requested)
	hud.resume_requested.connect(_resume_round)
	hud.restart_requested.connect(_on_restart_requested)
	hud.tuning_changed.connect(_on_tuning_changed)
	hud.set_initial_tuning(
		game_speed,
		perfect_window_ms,
		good_window_ms,
		cue_lead_ms,
		break_target,
		break_for_max_score,
	)
	if attack_effect != null:
		attack_effect.visible = false
		attack_effect.animation_finished.connect(_on_attack_effect_finished)
	_abort_round()


func _unhandled_input(event: InputEvent) -> void:
	if hud.is_typing_login():
		return
	if event.is_action_pressed(&"ui_cancel"):
		if _round_active:
			if _paused:
				_resume_round()
			else:
				_pause_round()
		return
	if event.is_action_pressed(START_CUE_ACTION):
		if not _round_active:
			_start_round(
				hud.get_login_text(),
				hud.is_random_mode_selected(),
				hud.is_wild_mode_selected(),
				hud.get_selected_speed(game_speed),
			)
	elif event.is_action_pressed(RESET_ACTION):
		_abort_round()


func _process(_delta: float) -> void:
	if not _round_active or _paused:
		return

	var now_ms: int = Time.get_ticks_msec()
	var elapsed_ms: int = now_ms - _round_start_ms
	var remaining_sec: float = float(_active_round_duration_ms - elapsed_ms) / 1000.0
	hud.show_timer(remaining_sec)

	# Open the next scheduled cue when its lead window arrives.
	if _state != CueState.ACTIVE and _next_cue_index < _schedule.size():
		var candidate: CueDef = _schedule[_next_cue_index]
		if now_ms >= candidate.contact_ms - _active_lead_ms:
			_next_cue_index += 1
			_open_scheduled_cue(candidate)

	if _state != CueState.IDLE:
		cast_capture.update(now_ms)
		_update_troop(now_ms)

	if _state == CueState.ACTIVE:
		# A judged release is applied at the later of T and its confirmation.
		if _pending_result != null:
			if now_ms >= _cue.contact_ms:
				_apply(_pending_result)
			return

		# Unfinished: wait out any eligible pending input before declaring a miss.
		var miss_deadline_ms: int = _live_good_ms() + CastCapture.CONFIRM_INTERVAL_MS
		if now_ms >= _cue.contact_ms + miss_deadline_ms \
				and not cast_capture.has_pending():
			_apply(CueJudge.make_miss())
			return

	# Finish the round once all 21 cues have resolved and round duration elapsed.
	if _next_cue_index >= _schedule.size() and _state != CueState.ACTIVE \
			and elapsed_ms >= _active_round_duration_ms:
		_finish_round()


func _on_tuning_changed() -> void:
	var base_lead: int = hud.get_selected_approach_ms(cue_lead_ms)
	_active_lead_ms = int(roundf(float(base_lead) / maxi_float(_active_speed, 0.4)))
	hud.show_round_progress(_break_total, _live_break_target())
	hud.show_score(_compute_score(_break_total))


func _on_start_round_requested(
	login: String,
	random_cues: bool,
	wild_enabled: bool,
	speed_scale: float,
) -> void:
	_start_round(login, random_cues, wild_enabled, speed_scale)


func _on_restart_requested() -> void:
	_start_round(
		hud.get_login_text(),
		hud.is_random_mode_selected(),
		hud.is_wild_mode_selected(),
		hud.get_selected_speed(game_speed),
	)


func _pause_round() -> void:
	if not _round_active or _paused:
		return
	_paused = true
	_pause_start_ms = Time.get_ticks_msec()
	if _troop != null and is_instance_valid(_troop) and _troop.animated_sprite != null:
		_troop.animated_sprite.pause()
	if attack_effect != null and attack_effect.is_playing():
		attack_effect.pause()
	hud.show_pause_settings(true)


func _resume_round() -> void:
	if not _round_active or not _paused:
		return
	var paused_ms: int = Time.get_ticks_msec() - _pause_start_ms
	_round_start_ms += paused_ms
	_open_ms += paused_ms
	if _cue != null:
		_cue.contact_ms += paused_ms
	for i: int in range(_next_cue_index, _schedule.size()):
		_schedule[i].contact_ms += paused_ms
	cast_capture.shift_timestamps(paused_ms)
	_wild_enabled = hud.is_wild_mode_selected()
	_on_tuning_changed()
	_paused = false
	if _troop != null and is_instance_valid(_troop) and _troop.animated_sprite != null:
		_troop.animated_sprite.play()
	if attack_effect != null and attack_effect.visible:
		attack_effect.play()
	hud.show_pause_settings(false)


## Start a fresh 21-cue round scaled by speed_scale.
func _start_round(
	login: String,
	random_cues: bool,
	wild_enabled: bool,
	speed_scale: float,
) -> void:
	_abort_round()
	_paused = false
	_player_login = login
	_use_random_cues = random_cues
	_wild_enabled = wild_enabled
	_active_speed = clampf(speed_scale, 0.4, 2.5)
	var base_lead: int = hud.get_selected_approach_ms(cue_lead_ms)
	_active_lead_ms = int(roundf(float(base_lead) / _active_speed))
	_active_round_duration_ms = int(roundf(float(BASE_ROUND_DURATION_MS) / _active_speed))
	_break_total = 0
	_round_start_ms = Time.get_ticks_msec()
	_schedule = _build_schedule(_round_start_ms, _use_random_cues, _active_speed)
	_next_cue_index = 0
	_round_active = true
	hud.show_menu(false)
	hud.reset_display()
	hud.show_round_progress(_break_total, _live_break_target())
	hud.show_score(1.0)
	hud.show_timer(float(_active_round_duration_ms) / 1000.0)


## Build the 21-cue schedule on the shared clock (preset or random, scaled by speed).
func _build_schedule(
	start_ms: int,
	use_random: bool,
	speed_scale: float,
) -> Array[CueDef]:
	var list: Array[CueDef] = []
	var elements: Array[GameTypes.Element] = [
		GameTypes.Element.A,
		GameTypes.Element.B,
		GameTypes.Element.C,
	]
	var lanes: Array[GameTypes.Lane] = [
		GameTypes.Lane.LEFT,
		GameTypes.Lane.CENTER,
		GameTypes.Lane.RIGHT,
	]
	for i: int in range(PRESET_CONTACT_MS.size()):
		var scaled_offset_ms: int = int(roundf(float(PRESET_CONTACT_MS[i]) / speed_scale))
		var contact_ms: int = start_ms + scaled_offset_ms
		var counter: GameTypes.Element = PRESET_COUNTERS[i]
		var lane: GameTypes.Lane = PRESET_LANES[i]
		if use_random:
			counter = elements[randi() % elements.size()]
			lane = lanes[randi() % lanes.size()]
		list.append(CueDef.new(counter, lane, contact_ms))
	return list


## Open one scheduled cue. Does not touch InputRouter rearm state.
func _open_scheduled_cue(cue_def: CueDef) -> void:
	if _troop != null and is_instance_valid(_troop):
		_troop.queue_free()
	_troop = null
	if troop_scene == null:
		push_error("Main: troop_scene is not assigned in the Inspector.")
		return
	var instance: Troop = troop_scene.instantiate() as Troop
	if instance == null:
		push_error("Main: troop_scene root does not have the Troop script.")
		return

	_cue = cue_def
	_open_ms = _cue.contact_ms - _active_lead_ms
	_pending_result = null
	_play_attack_on_apply = false

	_troop = instance
	if contact_line != null and contact_line.get_parent() != null:
		contact_line.get_parent().add_child(_troop)
	else:
		add_child(_troop)
	_troop.configure(_spawn_point(_cue.lane), _contact_point(_cue.lane))
	_troop.setup_visuals(_cue.required_counter)

	_state = CueState.ACTIVE
	cast_capture.open(_wild_enabled)
	hud.show_cue(_cue.required_counter, _cue.lane)


## Abort the active round or cue and return to the menu cleanly.
func _abort_round() -> void:
	_round_active = false
	_paused = false
	_state = CueState.IDLE
	_pending_result = null
	_play_attack_on_apply = false
	_cue = null
	_schedule.clear()
	_next_cue_index = 0
	cast_capture.close()
	if _troop != null and is_instance_valid(_troop):
		_troop.queue_free()
	_troop = null
	if attack_effect != null:
		attack_effect.stop()
		attack_effect.visible = false
	hud.reset_display()
	hud.show_round_progress(_break_total, _live_break_target())
	hud.show_timer(float(BASE_ROUND_DURATION_MS) / 1000.0)
	hud.show_menu(true, "RUNEWEAVE", _format_high_score_text())


## Complete the round, compute final score, log to disk, and show menu.
func _finish_round() -> void:
	_round_active = false
	_state = CueState.IDLE
	cast_capture.close()
	var final_score: float = _compute_score(_break_total)
	var victory: bool = _break_total >= _live_break_target()
	hud.show_score(final_score)
	_record_completed_game(_player_login, final_score, _break_total)
	var banner: String = "%s! SCORE %.1f" % [
		"VICTORY" if victory else "DEFEAT",
		final_score,
	]
	hud.show_menu(true, banner, _format_high_score_text())


func _on_target_activated(target: GameTypes.Target) -> void:
	if _state != CueState.ACTIVE:
		return
	cast_capture.accept(target, Time.get_ticks_msec())


func _on_step_confirmed(step_index: int, target: GameTypes.Target) -> void:
	hud.show_step(step_index, target, RecipeRules.target_to_element(target))


func _on_prefix_changed(count: int) -> void:
	hud.show_phase(count, false)


func _on_prepared(
	element: GameTypes.Element,
	style: GameTypes.CastStyle,
) -> void:
	hud.show_prepared(element, style)


func _on_committed(
	element: GameTypes.Element,
	style: GameTypes.CastStyle,
	lane: GameTypes.Lane,
	release_ms: int,
) -> void:
	if _state != CueState.ACTIVE:
		return
	var p_ms: int = _live_perfect_ms()
	var g_ms: int = _live_good_ms()
	var timing: CueJudge.Timing = CueJudge.grade_timing(
		release_ms,
		_cue.contact_ms,
		p_ms,
		g_ms,
		g_ms,
	)
	_pending_element = element
	_pending_lane = lane
	_pending_result = CueJudge.judge(_cue, element, lane, timing, style)

	if timing == CueJudge.Timing.EARLY:
		_play_attack_on_apply = false
		_play_attack_effect(element, lane, true)
		hud.show_early_fizzle()
	else:
		_play_attack_on_apply = timing != CueJudge.Timing.MISS


func _on_ambiguous() -> void:
	_play_attack_on_apply = false
	_apply(CueJudge.make_ambiguous())


## Apply the cue's one result. The state guard makes a second call a no-op.
func _apply(result: JudgeResult) -> void:
	if _state != CueState.ACTIVE:
		return
	_state = CueState.RESOLVED
	if _play_attack_on_apply:
		_play_attack_effect(_pending_element, _pending_lane, false)
	_play_attack_on_apply = false
	_pending_result = null
	cast_capture.close()
	_break_total += result.break_value
	if _troop != null and is_instance_valid(_troop):
		_troop.show_outcome(result)
		_troop = null
	hud.show_judgment(result)
	hud.show_round_progress(_break_total, _live_break_target())
	hud.show_score(_compute_score(_break_total))


func _play_attack_effect(
	element: GameTypes.Element,
	lane: GameTypes.Lane,
	is_fizzle: bool,
) -> void:
	if attack_effect == null or attack_effect.sprite_frames == null:
		return
	var anim: StringName = ATTACK_ANIM_BY_ELEMENT.get(element, &"default")
	if not attack_effect.sprite_frames.has_animation(anim):
		if attack_effect.sprite_frames.has_animation(&"default"):
			anim = &"default"
		else:
			return
	attack_effect.global_position = _contact_point(lane)
	attack_effect.scale = Vector2(0.55, 0.55) if is_fizzle else Vector2(1.15, 1.15)
	attack_effect.modulate = Color(1.0, 1.0, 1.0, 0.55) if is_fizzle else Color.WHITE
	attack_effect.visible = true
	attack_effect.frame = 0
	attack_effect.play(anim)


func _on_attack_effect_finished() -> void:
	if attack_effect != null:
		attack_effect.visible = false


## Compute 1.0-10.0 score using the configurable Break ceiling for 10.0.
## Lowering `break_for_max_score` (or the slider in Settings) makes 10.0 easier!
func _compute_score(break_points: int) -> float:
	var ceiling: int = maxi(_live_max_score_break(), 1)
	var raw: float = clampf(1.0 + 9.0 * float(break_points) / float(ceiling), 1.0, 10.0)
	return floorf(raw * 10.0 + 0.5) / 10.0


func _live_perfect_ms() -> int:
	return hud.get_selected_perfect_ms(perfect_window_ms)


func _live_good_ms() -> int:
	return maxi(hud.get_selected_good_ms(good_window_ms), _live_perfect_ms())


func _live_break_target() -> int:
	return hud.get_selected_break_target(break_target)


func _live_max_score_break() -> int:
	return hud.get_selected_max_score_break(break_for_max_score)


func maxi_float(a: float, b: float) -> float:
	return a if a > b else b


func _load_high_score() -> void:
	var path: String = ProjectSettings.globalize_path(HIGH_SCORE_FILE)
	if not FileAccess.file_exists(path):
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var line: String = file.get_line().strip_edges()
	var parts: PackedStringArray = line.split(",")
	if parts.size() >= 2:
		_high_score_holder = parts[0]
		_high_score = float(parts[1])


func _record_completed_game(login: String, score: float, break_points: int) -> void:
	var safe_login: String = login.replace(",", "_").strip_edges()
	if safe_login.is_empty():
		safe_login = "player"
	var timestamp: String = Time.get_datetime_string_from_system(false, true)
	var mode_str: String = "%s_%s_%.1fx" % [
		"random" if _use_random_cues else "preset",
		"wild" if _wild_enabled else "lite",
		_active_speed,
	]

	# 1. Append to game_log.csv in project folder.
	var log_path: String = ProjectSettings.globalize_path(GAME_LOG_FILE)
	var write_header: bool = not FileAccess.file_exists(log_path)
	var log_file: FileAccess = FileAccess.open(
		log_path,
		FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE,
	)
	if log_file != null:
		if write_header:
			log_file.store_line("login,score,break_points,mode,played_at")
		else:
			log_file.seek_end()
		log_file.store_line("%s,%.1f,%d,%s,%s" % [
			safe_login,
			score,
			break_points,
			mode_str,
			timestamp,
		])

	# 2. Update high_scores.txt if this beats or ties the highest score.
	if score >= _high_score:
		_high_score = score
		_high_score_holder = safe_login
		var hs_path: String = ProjectSettings.globalize_path(HIGH_SCORE_FILE)
		var hs_file: FileAccess = FileAccess.open(hs_path, FileAccess.WRITE)
		if hs_file != null:
			hs_file.store_line("%s,%.1f,%d,%s,%s" % [
				_high_score_holder,
				_high_score,
				break_points,
				mode_str,
				timestamp,
			])


func _format_high_score_text() -> String:
	if _high_score_holder == "-":
		return "HIGH SCORE: NONE YET"
	return "HIGH SCORE: %.1f (%s)" % [_high_score, _high_score_holder]


## Drive the troop from the same clock that judges. Held at the line after T.
func _update_troop(now_ms: int) -> void:
	if _troop == null or not is_instance_valid(_troop):
		return
	var span_ms: int = _cue.contact_ms - _open_ms
	_troop.set_progress(float(now_ms - _open_ms) / float(span_ms))


func _lane_marker(lane: GameTypes.Lane) -> Marker2D:
	match lane:
		GameTypes.Lane.LEFT:
			return lane_left
		GameTypes.Lane.CENTER:
			return lane_center
		_:
			return lane_right


func _viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _lane_x(lane: GameTypes.Lane) -> float:
	var marker: Marker2D = _lane_marker(lane)
	if marker != null:
		return marker.global_position.x
	return _viewport_size().x * float(DEFAULT_LANE_X[lane])


func _spawn_point(lane: GameTypes.Lane) -> Vector2:
	var marker: Marker2D = _lane_marker(lane)
	if marker != null:
		return marker.global_position
	return Vector2(_lane_x(lane), _viewport_size().y * DEFAULT_SPAWN_Y)


func _contact_point(lane: GameTypes.Lane) -> Vector2:
	var y: float = _viewport_size().y * DEFAULT_CONTACT_Y
	if contact_line != null:
		y = contact_line.global_position.y + contact_line.size.y * 0.5
	return Vector2(_lane_x(lane), y)
