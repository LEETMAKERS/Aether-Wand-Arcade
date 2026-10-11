# lane_attack.gd
# A moving attack projectile that travels along one lane.
# Spawned dynamically by CombatManager for both enemy and player attacks.
# Handles its own movement and drawing; CombatManager handles collision logic.
class_name LaneAttack
extends Node2D

enum Source { ENEMY, PLAYER }

var lane_index : int    = 0
var source     : Source = Source.ENEMY
var speed      : float  = 0.0

var _alive     : bool   = true
var _direction : float  = 1.0  # +1 = downward (enemy), -1 = upward (player)

# ── Setup ────────────────────────────────────────────────────────────────

func setup(p_lane: int, p_source: Source, p_speed: float) -> void:
    lane_index = p_lane
    source     = p_source
    speed      = p_speed
    _direction = 1.0 if p_source == Source.ENEMY else -1.0
    position.x = CombatConfig.LANE_X[p_lane]
    position.y = CombatConfig.ENEMY_Y if p_source == Source.ENEMY else CombatConfig.PLAYER_Y
    queue_redraw()

# ── Public API ───────────────────────────────────────────────────────────

func is_alive() -> bool:
    return _alive

func kill() -> void:
    if not _alive:
        return
    _alive = false
    hide()        # immediately invisible — don't wait for queue_free
    queue_free()

# ── Godot callbacks ──────────────────────────────────────────────────────

func _process(delta: float) -> void:
    if not _alive:
        return
    position.y += speed * _direction * delta
    queue_redraw()

func _draw() -> void:
    var r   : float = CombatConfig.ATTACK_RADIUS
    var col : Color = CombatConfig.COL_ENEMY_ATTACK \
        if source == Source.ENEMY else CombatConfig.COL_PLAYER_ATTACK
    # Outer body
    draw_circle(Vector2.ZERO, r, col)
    # Bright core for legibility against dark lanes
    draw_circle(Vector2.ZERO, r * 0.42, col.lightened(0.55))
