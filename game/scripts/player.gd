# player.gd
# Player state: health and per-lane attack cooldowns.
# Pure logic — receives method calls from CombatManager, emits signals upward.
class_name Player
extends Node

signal died
signal health_changed(new_hp: int, max_hp: int)

var hp             : int          = CombatConfig.PLAYER_MAX_HP
var max_hp         : int          = CombatConfig.PLAYER_MAX_HP
# Seconds remaining before each lane can be used again
var lane_cooldowns : Array[float] = [0.0, 0.0, 0.0]

func _process(delta: float) -> void:
    for i in CombatConfig.LANE_COUNT:
        if lane_cooldowns[i] > 0.0:
            lane_cooldowns[i] = maxf(0.0, lane_cooldowns[i] - delta)

# ── Cooldown API ─────────────────────────────────────────────────────────

func can_attack_lane(lane: int) -> bool:
    return lane_cooldowns[lane] <= 0.0

func start_lane_cooldown(lane: int) -> void:
    lane_cooldowns[lane] = CombatConfig.PLAYER_LANE_COOLDOWN

# Returns 0.0 = ready, 1.0 = just pressed (used by HUD for visual feedback)
func get_cooldown_fraction(lane: int) -> float:
    if CombatConfig.PLAYER_LANE_COOLDOWN <= 0.0:
        return 0.0
    return lane_cooldowns[lane] / CombatConfig.PLAYER_LANE_COOLDOWN

# ── Health API ────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
    if hp <= 0:
        return  # guard: prevent double-death signals
    hp = maxi(0, hp - amount)
    health_changed.emit(hp, max_hp)
    if hp == 0:
        died.emit()
