# player.gd
# Player state: health and per-lane attack cooldowns.
# Pure logic — receives method calls from CombatManager, emits signals upward.
class_name Player
extends Node

signal died
signal health_changed(new_hp: int, max_hp: int)

var hp              : int          = CombatConfig.PLAYER_MAX_HP
var max_hp          : int          = CombatConfig.PLAYER_MAX_HP
# Seconds remaining before each lane can be used again
var lane_cooldowns  : Array[float] = [0.0, 0.0, 0.0]
var global_cooldown : float        = 0.0

func _process(delta: float) -> void:
    if global_cooldown > 0.0:
        global_cooldown = maxf(0.0, global_cooldown - delta)
    for i in CombatConfig.LANE_COUNT:
        if lane_cooldowns[i] > 0.0:
            lane_cooldowns[i] = maxf(0.0, lane_cooldowns[i] - delta)

# ── Cooldown API ─────────────────────────────────────────────────────────

func can_attack_lane(lane: int, is_vulnerable: bool = false) -> bool:
    if is_vulnerable:
        return global_cooldown <= 0.0
    return global_cooldown <= 0.0 and lane_cooldowns[lane] <= 0.0

func start_lane_cooldown(lane: int, is_vulnerable: bool = false) -> void:
    if is_vulnerable:
        global_cooldown = CombatConfig.PLAYER_VULN_GLOBAL_COOLDOWN
    else:
        global_cooldown = CombatConfig.PLAYER_GLOBAL_COOLDOWN
        lane_cooldowns[lane] = CombatConfig.PLAYER_LANE_COOLDOWN

func get_lane_cooldown_fraction(lane: int) -> float:
    if CombatConfig.PLAYER_LANE_COOLDOWN <= 0.0:
        return 0.0
    return lane_cooldowns[lane] / CombatConfig.PLAYER_LANE_COOLDOWN

func get_global_cooldown_fraction(is_vulnerable: bool = false) -> float:
    var max_gcd : float = CombatConfig.PLAYER_VULN_GLOBAL_COOLDOWN if is_vulnerable else CombatConfig.PLAYER_GLOBAL_COOLDOWN
    if max_gcd <= 0.0:
        return 0.0
    return global_cooldown / max_gcd

# Combined fraction for HUD display: max of lane and global cooldown
func get_effective_cooldown_fraction(lane: int, is_vulnerable: bool = false) -> float:
    if is_vulnerable:
        return get_global_cooldown_fraction(true)
    return maxf(get_lane_cooldown_fraction(lane), get_global_cooldown_fraction(false))

# Returns 0.0 = ready, 1.0 = just pressed (used by HUD for visual feedback)
func get_cooldown_fraction(lane: int) -> float:
    return get_effective_cooldown_fraction(lane)

# ── Health API ────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
    if hp <= 0:
        return  # guard: prevent double-death signals
    hp = maxi(0, hp - amount)
    health_changed.emit(hp, max_hp)
    if hp == 0:
        died.emit()
