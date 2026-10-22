class_name Hud
extends CanvasLayer
## Display only. Renders capture state, round progress, menu, and settings.
##
## This node makes no gameplay decisions and never recounts inputs. It updates
## labels, swaps card/slot icons, colors text by phase/element/outcome, and
## emits signals when the player starts, pauses/resumes, or tunes settings.

signal start_round_requested(
	login: String,
	random_cues: bool,
	wild_enabled: bool,
	speed_scale: float,
)
signal resume_requested()
signal restart_requested()
signal tuning_changed()

@export_group("Text Labels")
@export var status_label: Label
@export var result_label: Label
@export var style_label: Label
@export var cue_label: Label
@export var left_prompt: Label
@export var center_prompt: Label
@export var right_prompt: Label

@export_group("Control Cards")
@export var left_card: Control
@export var center_card: Control
@export var right_card: Control
@export var left_card_icon: TextureRect
@export var center_card_icon: TextureRect
@export var right_card_icon: TextureRect

@export_group("Recipe & Prepared Slots")
@export var recipe_slot_1: Control
@export var recipe_slot_2: Control
@export var recipe_slot_3: Control
@export var recipe_icon_1: TextureRect
@export var recipe_icon_2: TextureRect
@export var recipe_icon_3: TextureRect
@export var prepared_slot: Control
@export var prepared_icon: TextureRect
@export var phase_plate: TextureRect

@export_group("Element & Arrow Textures")
@export var icon_element_a: Texture2D
@export var icon_element_b: Texture2D
@export var icon_element_c: Texture2D
@export var icon_arrow_left: Texture2D
@export var icon_arrow_center: Texture2D
@export var icon_arrow_right: Texture2D
@export var plate_normal: Texture2D
@export var plate_ready: Texture2D

@export_group("Top Bar & Summoner")
@export var timer_label: Label
@export var break_label: Label
@export var score_label: Label
@export var break_bar: Range
@export var summoner_icon: TextureRect
@export var summoner_stage_1: Texture2D
@export var summoner_stage_2: Texture2D
@export var summoner_stage_3: Texture2D

@export_group("Menu & Settings Overlay")
@export var menu_panel: Control
@export var menu_title_label: Label
@export var high_score_label: Label
@export var login_input: LineEdit
@export var start_button: BaseButton
@export var open_settings_button: BaseButton
@export var settings_panel: Control
@export var settings_title_label: Label
@export var random_toggle: BaseButton
@export var wild_toggle: BaseButton
@export var speed_slider: Range
@export var speed_value_label: Label
@export var perfect_window_slider: Range
@export var perfect_window_label: Label
@export var good_window_slider: Range
@export var good_window_label: Label
@export var approach_time_slider: Range
@export var approach_time_label: Label
@export var break_target_slider: Range
@export var break_target_label: Label
@export var max_score_break_slider: Range
@export var max_score_break_label: Label
@export var restart_button: BaseButton
@export var close_settings_button: BaseButton

const ELEMENT_NAMES: Dictionary = {
	GameTypes.Element.A: "FIRE",
	GameTypes.Element.B: "FROST",
	GameTypes.Element.C: "LIGHTNING",
}

const LANE_NAMES: Dictionary = {
	GameTypes.Lane.LEFT: "LEFT",
	GameTypes.Lane.CENTER: "CENTER",
	GameTypes.Lane.RIGHT: "RIGHT",
}

const PREPARE_PROMPTS: Dictionary = {
	GameTypes.Target.LEFT: "FIRE",
	GameTypes.Target.CENTER: "FROST",
	GameTypes.Target.RIGHT: "LIGHTNING",
}

const RELEASE_PROMPTS: Dictionary = {
	GameTypes.Target.LEFT: "LEFT",
	GameTypes.Target.CENTER: "CENTER",
	GameTypes.Target.RIGHT: "RIGHT",
}

const OUTCOME_TEXT: Dictionary = {
	JudgeResult.Outcome.CLEAN_KILL: "CLEAN KILL!",
	JudgeResult.Outcome.WRONG_ELEMENT_KILL: "WRONG ELEMENT — RAGGED KILL",
	JudgeResult.Outcome.WRONG_ELEMENT_SURVIVE: "WRONG ELEMENT — SURVIVED",
	JudgeResult.Outcome.WRONG_LANE: "WRONG LANE!",
	JudgeResult.Outcome.EARLY: "TOO EARLY — FIZZLED!",
	JudgeResult.Outcome.MISS: "UNFINISHED — MISSED!",
	JudgeResult.Outcome.AMBIGUOUS: "AMBIGUOUS INPUT!",
}

const COLOR_PHASE_IDLE: Color = Color(0.82, 0.84, 0.92, 1.0)
const COLOR_PHASE_PREPARE: Color = Color(0.96, 0.90, 0.78, 1.0)
const COLOR_PHASE_READY: Color = Color(0.36, 1.0, 0.49, 1.0)
const COLOR_STYLE_STABLE: Color = Color(0.95, 0.82, 0.42, 1.0)
const COLOR_STYLE_WILD: Color = Color(1.0, 0.38, 0.92, 1.0)

const ELEMENT_COLORS: Dictionary = {
	GameTypes.Element.A: Color(1.0, 0.42, 0.29, 1.0),
	GameTypes.Element.B: Color(0.36, 0.88, 1.0, 1.0),
	GameTypes.Element.C: Color(1.0, 0.89, 0.30, 1.0),
}

const OUTCOME_COLORS: Dictionary = {
	JudgeResult.Outcome.CLEAN_KILL: Color(1.0, 0.85, 0.30, 1.0),
	JudgeResult.Outcome.WRONG_ELEMENT_KILL: Color(1.0, 0.62, 0.27, 1.0),
	JudgeResult.Outcome.WRONG_ELEMENT_SURVIVE: Color(1.0, 0.62, 0.27, 1.0),
	JudgeResult.Outcome.WRONG_LANE: Color(1.0, 0.30, 0.37, 1.0),
	JudgeResult.Outcome.EARLY: Color(1.0, 0.30, 0.37, 1.0),
	JudgeResult.Outcome.MISS: Color(1.0, 0.30, 0.37, 1.0),
	JudgeResult.Outcome.AMBIGUOUS: Color(1.0, 0.30, 0.37, 1.0),
}

const CARD_LIFT_PX: float = 16.0
const CARD_TWEEN_SEC: float = 0.12
const POP_TWEEN_SEC: float = 0.14

var _card_base_y: Dictionary = {}
var _in_pause_menu: bool = false


func _ready() -> void:
	_record_card_base_positions()
	if start_button != null:
		start_button.pressed.connect(_on_start_button_pressed)
	if login_input != null:
		login_input.text_submitted.connect(_on_login_submitted)
	if open_settings_button != null:
		open_settings_button.pressed.connect(_on_open_settings_pressed)
	if close_settings_button != null:
		close_settings_button.pressed.connect(_on_close_settings_pressed)
	if restart_button != null:
		restart_button.pressed.connect(_on_restart_pressed)
	if speed_slider != null:
		speed_slider.value_changed.connect(_on_speed_slider_changed)
		_on_speed_slider_changed(speed_slider.value)
	if perfect_window_slider != null:
		perfect_window_slider.value_changed.connect(_on_perfect_window_changed)
		_on_perfect_window_changed(perfect_window_slider.value)
	if good_window_slider != null:
		good_window_slider.value_changed.connect(_on_good_window_changed)
		_on_good_window_changed(good_window_slider.value)
	if approach_time_slider != null:
		approach_time_slider.value_changed.connect(_on_approach_time_changed)
		_on_approach_time_changed(approach_time_slider.value)
	if break_target_slider != null:
		break_target_slider.value_changed.connect(_on_break_target_changed)
		_on_break_target_changed(break_target_slider.value)
	if max_score_break_slider != null:
		max_score_break_slider.value_changed.connect(_on_max_score_break_changed)
		_on_max_score_break_changed(max_score_break_slider.value)
	if settings_panel != null:
		settings_panel.visible = false
	reset_display()


## Initialize all tuning sliders from Main's default @export properties.
func set_initial_tuning(
	speed_value: float,
	perfect_ms: int,
	good_ms: int,
	approach_ms: int,
	break_target_val: int,
	max_score_break_val: int,
) -> void:
	if speed_slider != null:
		speed_slider.value = speed_value
	_on_speed_slider_changed(speed_value)

	if perfect_window_slider != null:
		perfect_window_slider.value = float(perfect_ms)
	_on_perfect_window_changed(float(perfect_ms))

	if good_window_slider != null:
		good_window_slider.value = float(good_ms)
	_on_good_window_changed(float(good_ms))

	if approach_time_slider != null:
		approach_time_slider.value = float(approach_ms)
	_on_approach_time_changed(float(approach_ms))

	if break_target_slider != null:
		break_target_slider.value = float(break_target_val)
	_on_break_target_changed(float(break_target_val))

	if max_score_break_slider != null:
		max_score_break_slider.value = float(max_score_break_val)
	_on_max_score_break_changed(float(max_score_break_val))


## Animate the confirmed card tap and fill the corresponding recipe slot (0..2).
func show_step(
	step_index: int,
	target: GameTypes.Target,
	element: GameTypes.Element,
) -> void:
	_animate_card_tap(_card_for_target(target))
	if step_index >= 0 and step_index < 3:
		var slot_icon: TextureRect = _recipe_icon_for_step(step_index)
		var slot_box: Control = _recipe_slot_for_step(step_index)
		if slot_icon != null:
			slot_icon.texture = _texture_for_element(element)
			slot_icon.visible = true
			_pop_control(slot_icon, 1.22)
		if slot_box != null:
			_pop_control(slot_box, 1.10)


## Update phase text and switch prompts between prepare and release modes.
func show_phase(prepared_count: int, awaiting_release: bool) -> void:
	if awaiting_release:
		_set_status("SPELL READY! CHOOSE LANE", COLOR_PHASE_READY)
		_set_plate(plate_ready)
		_show_lane_prompts()
	else:
		_set_status("PREPARE RUNE %d / 3" % (prepared_count + 1), COLOR_PHASE_PREPARE)
		_set_plate(plate_normal)
		_show_element_prompts()


## Show the locked-in element and style preview after three activations.
func show_prepared(
	element: GameTypes.Element,
	style: GameTypes.CastStyle = GameTypes.CastStyle.STABLE,
) -> void:
	var is_wild: bool = style == GameTypes.CastStyle.WILD
	var style_name: String = "WILD!" if is_wild else "STABLE"
	var style_color: Color = COLOR_STYLE_WILD if is_wild else ELEMENT_COLORS[element]
	_set_status("SPELL READY: %s!" % ELEMENT_NAMES[element], COLOR_PHASE_READY)
	_set_plate(plate_ready)
	if prepared_icon != null:
		prepared_icon.texture = _texture_for_element(element)
		prepared_icon.visible = true
		_pop_control(prepared_icon, 1.28)
	if prepared_slot != null:
		_pop_control(prepared_slot, 1.14)
	if style_label != null:
		style_label.text = "%s • %s" % [ELEMENT_NAMES[element], style_name]
		style_label.add_theme_color_override(&"font_color", style_color)
		_pop_control(style_label, 1.18)
	_show_lane_prompts()


## Show the single committed result for the attempt.
func show_result(element: GameTypes.Element, lane: GameTypes.Lane) -> void:
	if result_label == null:
		return
	result_label.text = "%s -> %s" % [
		ELEMENT_NAMES[element],
		LANE_NAMES[lane],
	]
	result_label.add_theme_color_override(&"font_color", ELEMENT_COLORS[element])
	_pop_control(result_label, 1.15)


## Clear all display back to the start of an attempt.
func reset_display() -> void:
	if cue_label != null:
		cue_label.text = ""
	_set_status("PRESS START OR ENTER", COLOR_PHASE_IDLE)
	_set_plate(plate_normal)
	if result_label != null:
		result_label.text = ""
	if style_label != null:
		style_label.text = "STABLE"
		style_label.add_theme_color_override(&"font_color", COLOR_STYLE_STABLE)
	_clear_icon(recipe_icon_1)
	_clear_icon(recipe_icon_2)
	_clear_icon(recipe_icon_3)
	_clear_icon(prepared_icon)
	_show_element_prompts()


## Show the cue's required counter and lane, kept optional in cue_label.
func show_cue(counter: GameTypes.Element, lane: GameTypes.Lane) -> void:
	if cue_label != null:
		cue_label.text = "COUNTER: %s (%s)" % [
			ELEMENT_NAMES[counter],
			LANE_NAMES[lane],
		]
		cue_label.add_theme_color_override(&"font_color", ELEMENT_COLORS[counter])
	_clear_icon(recipe_icon_1)
	_clear_icon(recipe_icon_2)
	_clear_icon(recipe_icon_3)
	_clear_icon(prepared_icon)
	if style_label != null:
		style_label.text = "STABLE"
		style_label.add_theme_color_override(&"font_color", COLOR_STYLE_STABLE)
	_set_status("PREPARE RUNE 1 / 3", COLOR_PHASE_PREPARE)
	_set_plate(plate_normal)
	if result_label != null:
		result_label.text = ""
	_show_element_prompts()


## Show feedback immediately when a release is too early and fizzles.
func show_early_fizzle() -> void:
	var fizzle_color: Color = OUTCOME_COLORS[JudgeResult.Outcome.EARLY]
	_set_status("TOO EARLY — FIZZLED!", fizzle_color)
	if result_label != null:
		result_label.text = "TOO EARLY — FIZZLED!"
		result_label.add_theme_color_override(&"font_color", fizzle_color)
		_pop_control(result_label, 1.20)


## Show the single judged outcome of the cue and why.
func show_judgment(result: JudgeResult) -> void:
	var outcome_color: Color = OUTCOME_COLORS[result.outcome]
	_set_status(OUTCOME_TEXT[result.outcome], outcome_color)
	if result_label != null:
		if result.break_value > 0:
			result_label.text = "%s\n+%d BREAK" % [
				OUTCOME_TEXT[result.outcome],
				result.break_value,
			]
		else:
			result_label.text = OUTCOME_TEXT[result.outcome]
		result_label.add_theme_color_override(&"font_color", outcome_color)
		_pop_control(result_label, 1.22)


## Update Break counter, Summoner health bar, and mask damage stage.
func show_round_progress(break_total: int, break_target: int) -> void:
	if break_label != null:
		break_label.text = "BREAK %03d / %d" % [break_total, break_target]
		_pop_control(break_label, 1.10)
	if break_bar != null:
		break_bar.max_value = float(break_target)
		break_bar.value = clampf(float(break_target - break_total), 0.0, float(break_target))
	if summoner_icon != null:
		var ratio: float = float(break_total) / float(maxi(break_target, 1))
		var target_tex: Texture2D = summoner_stage_1
		if ratio >= 1.0 and summoner_stage_3 != null:
			target_tex = summoner_stage_3
		elif ratio >= 0.5 and summoner_stage_2 != null:
			target_tex = summoner_stage_2
		if target_tex != null and summoner_icon.texture != target_tex:
			summoner_icon.texture = target_tex
			_pop_control(summoner_icon, 1.20)


## Update the top-left countdown timer display (M:SS).
func show_timer(remaining_sec: float) -> void:
	if timer_label == null:
		return
	var clamped: int = maxi(int(ceilf(remaining_sec)), 0)
	var mins: int = clamped / 60
	var secs: int = clamped % 60
	timer_label.text = "%d:%02d" % [mins, secs]


## Update the live or final score label (1.0 - 10.0).
func show_score(score_value: float) -> void:
	if score_label != null:
		score_label.text = "SCORE %.1f" % score_value


## Show or hide the menu overlay with optional round summary and high score text.
func show_menu(visible_flag: bool, title_text: String = "", best_text: String = "") -> void:
	_in_pause_menu = false
	if menu_panel != null:
		menu_panel.visible = visible_flag
	if settings_panel != null:
		settings_panel.visible = false
	if not title_text.is_empty() and menu_title_label != null:
		menu_title_label.text = title_text
	if not best_text.is_empty() and high_score_label != null:
		high_score_label.text = best_text
	if visible_flag and start_button != null:
		start_button.release_focus()


## Open or close the Settings panel as an in-game Pause overlay.
func show_pause_settings(paused: bool) -> void:
	_in_pause_menu = paused
	if menu_panel != null:
		menu_panel.visible = false
	if settings_panel != null:
		settings_panel.visible = paused
	if settings_title_label != null:
		settings_title_label.text = "PAUSED — SETTINGS" if paused else "SETTINGS"
	if restart_button != null:
		restart_button.visible = paused
	if close_settings_button is Button:
		(close_settings_button as Button).text = "RESUME (ESC)" if paused else "BACK TO MENU"


## Read current menu settings (used when starting via Enter key or Start button).
func get_login_text() -> String:
	if login_input == null:
		return "player"
	var cleaned: String = login_input.text.strip_edges()
	return "player" if cleaned.is_empty() else cleaned


func is_random_mode_selected() -> bool:
	return random_toggle != null and random_toggle.button_pressed


func is_wild_mode_selected() -> bool:
	return wild_toggle != null and wild_toggle.button_pressed


func get_selected_speed(default_speed: float = 1.0) -> float:
	if speed_slider != null and speed_slider.value > 0.0:
		return float(speed_slider.value)
	return default_speed


func get_selected_perfect_ms(default_ms: int = 50) -> int:
	if perfect_window_slider != null and perfect_window_slider.value > 0.0:
		return int(roundf(perfect_window_slider.value))
	return default_ms


func get_selected_good_ms(default_ms: int = 130) -> int:
	if good_window_slider != null and good_window_slider.value > 0.0:
		return int(roundf(good_window_slider.value))
	return default_ms


func get_selected_approach_ms(default_ms: int = 2100) -> int:
	if approach_time_slider != null and approach_time_slider.value > 0.0:
		return int(roundf(approach_time_slider.value))
	return default_ms


func get_selected_break_target(default_target: int = 100) -> int:
	if break_target_slider != null and break_target_slider.value > 0.0:
		return int(roundf(break_target_slider.value))
	return default_target


func get_selected_max_score_break(default_max: int = 140) -> int:
	if max_score_break_slider != null and max_score_break_slider.value > 0.0:
		return int(roundf(max_score_break_slider.value))
	return default_max


func is_typing_login() -> bool:
	return login_input != null and login_input.visible and login_input.has_focus()


func _on_open_settings_pressed() -> void:
	_in_pause_menu = false
	if menu_panel != null:
		menu_panel.visible = false
	if settings_title_label != null:
		settings_title_label.text = "SETTINGS"
	if restart_button != null:
		restart_button.visible = false
	if close_settings_button is Button:
		(close_settings_button as Button).text = "BACK TO MENU"
	if settings_panel != null:
		settings_panel.visible = true


func _on_close_settings_pressed() -> void:
	if _in_pause_menu:
		resume_requested.emit()
		return
	if settings_panel != null:
		settings_panel.visible = false
	if menu_panel != null:
		menu_panel.visible = true


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _on_speed_slider_changed(value: float) -> void:
	if speed_value_label != null:
		speed_value_label.text = "GAME SPEED: %.1fx" % value
	tuning_changed.emit()


func _on_perfect_window_changed(value: float) -> void:
	if perfect_window_label != null:
		perfect_window_label.text = "PERFECT WINDOW: ±%d ms" % int(roundf(value))
	tuning_changed.emit()


func _on_good_window_changed(value: float) -> void:
	if good_window_label != null:
		good_window_label.text = "GREAT WINDOW: ±%d ms" % int(roundf(value))
	tuning_changed.emit()


func _on_approach_time_changed(value: float) -> void:
	if approach_time_label != null:
		approach_time_label.text = "APPROACH TIME: %.2fs" % (value / 1000.0)
	tuning_changed.emit()


func _on_break_target_changed(value: float) -> void:
	if break_target_label != null:
		break_target_label.text = "VICTORY TARGET: %d BREAK" % int(roundf(value))
	tuning_changed.emit()


func _on_max_score_break_changed(value: float) -> void:
	if max_score_break_label != null:
		max_score_break_label.text = "BREAK FOR 10.0 SCORE: %d" % int(roundf(value))
	tuning_changed.emit()


func _on_start_button_pressed() -> void:
	if login_input != null:
		login_input.release_focus()
	start_round_requested.emit(
		get_login_text(),
		is_random_mode_selected(),
		is_wild_mode_selected(),
		get_selected_speed(1.0),
	)


func _on_login_submitted(_text: String) -> void:
	_on_start_button_pressed()


func _set_status(phase_text: String, color: Color) -> void:
	if status_label == null:
		return
	status_label.text = phase_text
	status_label.add_theme_color_override(&"font_color", color)
	_pop_control(status_label, 1.12)


func _set_plate(tex: Texture2D) -> void:
	if phase_plate != null and tex != null:
		phase_plate.texture = tex


func _clear_icon(icon: TextureRect) -> void:
	if icon != null:
		icon.texture = null
		icon.visible = false


func _show_element_prompts() -> void:
	if left_prompt != null:
		left_prompt.text = PREPARE_PROMPTS[GameTypes.Target.LEFT]
		left_prompt.add_theme_color_override(&"font_color", ELEMENT_COLORS[GameTypes.Element.A])
	if center_prompt != null:
		center_prompt.text = PREPARE_PROMPTS[GameTypes.Target.CENTER]
		center_prompt.add_theme_color_override(&"font_color", ELEMENT_COLORS[GameTypes.Element.B])
	if right_prompt != null:
		right_prompt.text = PREPARE_PROMPTS[GameTypes.Target.RIGHT]
		right_prompt.add_theme_color_override(&"font_color", ELEMENT_COLORS[GameTypes.Element.C])
	_set_card_icons(icon_element_a, icon_element_b, icon_element_c, false)


func _show_lane_prompts() -> void:
	if left_prompt != null:
		left_prompt.text = RELEASE_PROMPTS[GameTypes.Target.LEFT]
		left_prompt.add_theme_color_override(&"font_color", COLOR_PHASE_READY)
	if center_prompt != null:
		center_prompt.text = RELEASE_PROMPTS[GameTypes.Target.CENTER]
		center_prompt.add_theme_color_override(&"font_color", COLOR_PHASE_READY)
	if right_prompt != null:
		right_prompt.text = RELEASE_PROMPTS[GameTypes.Target.RIGHT]
		right_prompt.add_theme_color_override(&"font_color", COLOR_PHASE_READY)
	_set_card_icons(icon_arrow_left, icon_arrow_center, icon_arrow_right, true)


func _set_card_icons(
	left_tex: Texture2D,
	center_tex: Texture2D,
	right_tex: Texture2D,
	animate: bool,
) -> void:
	if left_card_icon != null and left_tex != null:
		left_card_icon.texture = left_tex
		if animate:
			_pop_control(left_card_icon, 1.20)
	if center_card_icon != null and center_tex != null:
		center_card_icon.texture = center_tex
		if animate:
			_pop_control(center_card_icon, 1.20)
	if right_card_icon != null and right_tex != null:
		right_card_icon.texture = right_tex
		if animate:
			_pop_control(right_card_icon, 1.20)


func _texture_for_element(element: GameTypes.Element) -> Texture2D:
	match element:
		GameTypes.Element.A:
			return icon_element_a
		GameTypes.Element.B:
			return icon_element_b
		_:
			return icon_element_c


func _recipe_icon_for_step(step_index: int) -> TextureRect:
	match step_index:
		0:
			return recipe_icon_1
		1:
			return recipe_icon_2
		_:
			return recipe_icon_3


func _recipe_slot_for_step(step_index: int) -> Control:
	match step_index:
		0:
			return recipe_slot_1
		1:
			return recipe_slot_2
		_:
			return recipe_slot_3


func _card_for_target(target: GameTypes.Target) -> Control:
	match target:
		GameTypes.Target.LEFT:
			return left_card
		GameTypes.Target.CENTER:
			return center_card
		_:
			return right_card


func _record_card_base_positions() -> void:
	for card: Control in [left_card, center_card, right_card]:
		if card != null:
			_card_base_y[card] = card.position.y


func _animate_card_tap(card: Control) -> void:
	if card == null:
		return
	if not _card_base_y.has(card):
		_card_base_y[card] = card.position.y
	var base_y: float = float(_card_base_y[card])
	card.pivot_offset = card.size * 0.5
	var tween: Tween = create_tween().set_parallel(true)
	card.position.y = base_y - CARD_LIFT_PX
	card.scale = Vector2(1.10, 1.10)
	card.modulate = Color(1.3, 1.3, 1.3, 1.0)
	tween.tween_property(card, ^"position:y", base_y, CARD_TWEEN_SEC) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, ^"scale", Vector2.ONE, CARD_TWEEN_SEC) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, ^"modulate", Color.WHITE, CARD_TWEEN_SEC)


func _pop_control(control: Control, peak_scale: float) -> void:
	if control == null:
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(peak_scale, peak_scale)
	var tween: Tween = create_tween()
	tween.tween_property(control, ^"scale", Vector2.ONE, POP_TWEEN_SEC) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
