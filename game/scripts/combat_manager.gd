# combat_manager.gd
# Orchestrates all combat: enemy AI, attack spawning, collision detection,
# damage, and state transitions.
#
# State machine:
#   IDLE       — enemy is waiting; idle timer counts down to next pattern
#   ATTACKING  — enemy attacks are in flight; player can intercept
#   VULNERABLE — enemy stunned after a perfect intercept; player deals bonus damage
#   GAME_OVER  — match ended (player or enemy HP hit 0)
#
# Collision model:
#   Player attack travels UP, enemy attack travels DOWN, in the same lane.
#   Overlap detected by Y-distance < ATTACK_RADIUS * 2.5.
#   Collision in the perfect zone (near player) → perfect intercept.
#   Collision outside → regular block.
class_name CombatManager
extends Node

enum State { IDLE, ATTACKING, VULNERABLE, GAME_OVER }

# ── External references (set by main.gd before add_child) ─────────────────
var arena             : Arena
var attacks_container : Node2D
var player            : Player
var enemy             : Enemy
var hud               : HUD
var input_handler     : InputHandler

# ── Runtime ────────────────────────────────────────────────────────────────
var _state         : State = State.IDLE
var _idle_timer    : float = 0.0
var _vuln_timer    : float = 0.0
var _pattern_index : int   = 0

# Active attacks. Each entry: { "node": LaneAttack, "lane": int }
var _enemy_attacks  : Array = []
var _player_attacks : Array = []

# ── Lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
    input_handler.lane_pressed.connect(_on_lane_pressed)
    player.died.connect(_on_player_died)
    enemy.died.connect(_on_enemy_died)
    hud.update_health(player.hp, player.max_hp, enemy.hp, enemy.max_hp)
    _start_idle()

func _process(delta: float) -> void:
    if _state == State.GAME_OVER:
        return

    _prune_dead()
    _check_player_attacks_reached_enemy()

    if _state == State.GAME_OVER:
        return   # enemy might have died in the call above

    match _state:
        State.IDLE:
            _idle_timer -= delta
            if _idle_timer <= 0.0:
                _launch_next_pattern()

        State.ATTACKING:
            _check_collisions()
            if _state != State.ATTACKING:
                return   # perfect intercept may have changed state
            _check_enemy_attacks_landed()
            if _state != State.ATTACKING:
                return   # player may have died
            if _enemy_attacks.is_empty():
                _start_idle()  # all enemy attacks resolved without a perfect → next round

        State.VULNERABLE:
            _vuln_timer -= delta
            if _vuln_timer <= 0.0:
                _end_vulnerability()

# ── Input ──────────────────────────────────────────────────────────────────

func _on_lane_pressed(lane: int) -> void:
    if _state == State.GAME_OVER:
        return
    var is_vuln : bool = (_state == State.VULNERABLE)
    if not player.can_attack_lane(lane, is_vuln):
        return  # global or lane cooldown active — ignore

    player.start_lane_cooldown(lane, is_vuln)

    if is_vuln:
        # Enemy is stunned: direct damage, no projectile needed
        enemy.take_damage(CombatConfig.PLAYER_VULN_DAMAGE)
        arena.trigger_flash(lane, CombatConfig.COL_PERFECT, 0.22)
        hud.show_status("VULNERABLE! -%d" % CombatConfig.PLAYER_VULN_DAMAGE)
        hud.update_health(player.hp, player.max_hp, enemy.hp, enemy.max_hp)
        return

    # IDLE or ATTACKING: spawn a player attack projectile that travels up
    _spawn_player_attack(lane)

# ── Attack spawning ────────────────────────────────────────────────────────

func _launch_next_pattern() -> void:
    var pattern  : Array = CombatConfig.ENEMY_PATTERNS[
                           _pattern_index % CombatConfig.ENEMY_PATTERNS.size()]
    var is_multi : bool  = pattern.size() > 1
    var spd_mult : float = CombatConfig.ENEMY_MULTIPATTERN_SPEED_MULT if is_multi else 1.0

    _pattern_index += 1
    _state = State.ATTACKING

    for lane in pattern:
        var spd  : float    = CombatConfig.ENEMY_ATTACK_SPEED * spd_mult
        var atk  : LaneAttack = _create_attack(lane, LaneAttack.Source.ENEMY, spd)
        _enemy_attacks.append({ "node": atk, "lane": lane })
        arena.trigger_flash(lane, CombatConfig.COL_ENEMY_ATTACK, 0.10)

    hud.show_status("INCOMING!" if not is_multi else "MULTI-LANE!")

func _spawn_player_attack(lane: int) -> void:
    var atk := _create_attack(lane, LaneAttack.Source.PLAYER, CombatConfig.PLAYER_ATTACK_SPEED)
    _player_attacks.append({ "node": atk, "lane": lane })

func _create_attack(lane: int, src: LaneAttack.Source, spd: float) -> LaneAttack:
    var atk := LaneAttack.new()
    attacks_container.add_child(atk)
    atk.setup(lane, src, spd)
    return atk

# ── Collision detection ────────────────────────────────────────────────────

func _check_collisions() -> void:
    # Pair each live player attack with a live enemy attack in the same lane.
    # Resolve all found pairs (avoid mutating arrays during iteration).
    var resolved_pa : Array = []
    var resolved_ea : Array = []

    for pa in _player_attacks:
        if not pa.node.is_alive() or pa in resolved_pa:
            continue
        for ea in _enemy_attacks:
            if not ea.node.is_alive() or ea in resolved_ea:
                continue
            if pa.lane != ea.lane:
                continue

            var dist : float = absf(pa.node.position.y - ea.node.position.y)
            if dist > CombatConfig.ATTACK_RADIUS * 2.5:
                continue

            # Attacks collide — determine quality
            var in_perfect_zone : bool = \
                ea.node.position.y >= (CombatConfig.PLAYER_Y - CombatConfig.PERFECT_ZONE_HEIGHT)

            resolved_pa.append(pa)
            resolved_ea.append(ea)
            pa.node.kill()
            ea.node.kill()

            if in_perfect_zone:
                # Perfect: kill everything and open the vulnerability window.
                # Return immediately — _trigger_perfect clears the attack arrays.
                _trigger_perfect(pa.lane)
                return
            else:
                _apply_regular_intercept(pa.lane)
            break   # each player attack resolves against at most one enemy attack

    # Clean up resolved entries
    for pa in resolved_pa:
        _player_attacks.erase(pa)
    for ea in resolved_ea:
        _enemy_attacks.erase(ea)

func _apply_regular_intercept(lane: int) -> void:
    enemy.take_damage(CombatConfig.PLAYER_INTERCEPT_DAMAGE)
    arena.trigger_flash(lane, CombatConfig.COL_INTERCEPT, 0.28)
    hud.show_status("BLOCKED! -%d" % CombatConfig.PLAYER_INTERCEPT_DAMAGE)
    hud.update_health(player.hp, player.max_hp, enemy.hp, enemy.max_hp)

func _trigger_perfect(lane: int) -> void:
    # Kill every remaining attack on the field
    for ea in _enemy_attacks:
        if ea.node.is_alive(): ea.node.kill()
    _enemy_attacks.clear()
    for pa in _player_attacks:
        if pa.node.is_alive(): pa.node.kill()
    _player_attacks.clear()

    enemy.take_damage(CombatConfig.PLAYER_PERFECT_DAMAGE)
    arena.trigger_flash_all(CombatConfig.COL_PERFECT, 0.45)
    hud.update_health(player.hp, player.max_hp, enemy.hp, enemy.max_hp)

    if _state != State.GAME_OVER:
        _start_vulnerability()

# ── Hit detection ──────────────────────────────────────────────────────────

func _check_enemy_attacks_landed() -> void:
    for i in range(_enemy_attacks.size() - 1, -1, -1):
        var ea = _enemy_attacks[i]
        if not ea.node.is_alive():
            _enemy_attacks.remove_at(i)
            continue
        if ea.node.position.y >= CombatConfig.PLAYER_Y:
            player.take_damage(CombatConfig.ENEMY_LANE_DAMAGE)
            arena.trigger_flash(ea.lane, CombatConfig.COL_ENEMY_ATTACK, 0.40)
            hud.show_status("HIT! -%d HP" % CombatConfig.ENEMY_LANE_DAMAGE)
            hud.update_health(player.hp, player.max_hp, enemy.hp, enemy.max_hp)
            ea.node.kill()
            _enemy_attacks.remove_at(i)

func _check_player_attacks_reached_enemy() -> void:
    # Player attacks that reach the enemy without intercepting
    for i in range(_player_attacks.size() - 1, -1, -1):
        var pa = _player_attacks[i]
        if not pa.node.is_alive():
            _player_attacks.remove_at(i)
            continue
        if pa.node.position.y <= CombatConfig.ENEMY_Y:
            # Free swing: outside vulnerability
            if _state != State.VULNERABLE:
                if CombatConfig.PLAYER_FREESWING_DAMAGE > 0:
                    enemy.take_damage(CombatConfig.PLAYER_FREESWING_DAMAGE)
                    arena.trigger_flash(pa.lane, CombatConfig.COL_PLAYER_ATTACK, 0.15)
                    hud.show_status("POKE! -%d" % CombatConfig.PLAYER_FREESWING_DAMAGE)
                    hud.update_health(player.hp, player.max_hp, enemy.hp, enemy.max_hp)
                else:
                    arena.trigger_flash(pa.lane, Color(0.45, 0.45, 0.55), 0.12)
                    hud.show_status("DEFLECTED! (Enemy armored — parry to stun)")
            pa.node.kill()
            _player_attacks.remove_at(i)

# ── Utilities ──────────────────────────────────────────────────────────────

func _prune_dead() -> void:
    # Remove stale entries whose nodes were freed externally
    for i in range(_player_attacks.size() - 1, -1, -1):
        if not _player_attacks[i].node.is_alive():
            _player_attacks.remove_at(i)
    for i in range(_enemy_attacks.size() - 1, -1, -1):
        if not _enemy_attacks[i].node.is_alive():
            _enemy_attacks.remove_at(i)

func _kill_all_attacks() -> void:
    for ea in _enemy_attacks:
        if ea.node.is_alive(): ea.node.kill()
    _enemy_attacks.clear()
    for pa in _player_attacks:
        if pa.node.is_alive(): pa.node.kill()
    _player_attacks.clear()

# ── State transitions ──────────────────────────────────────────────────────

func _start_idle() -> void:
    _state = State.IDLE
    # Alternating delay for deterministic but varied pacing
    var even : bool = (_pattern_index % 2 == 0)
    _idle_timer = CombatConfig.ENEMY_IDLE_DELAY_MIN if even else CombatConfig.ENEMY_IDLE_DELAY_MAX
    hud.show_status("")

func _start_vulnerability() -> void:
    _state      = State.VULNERABLE
    _vuln_timer = CombatConfig.VULNERABILITY_DURATION
    enemy.set_stunned(true)
    arena.show_vulnerability(CombatConfig.VULNERABILITY_DURATION)
    hud.show_status("PERFECT! ENEMY STUNNED — press A / S / D to attack!")

func _end_vulnerability() -> void:
    enemy.set_stunned(false)
    arena.hide_vulnerability()
    hud.show_status("")
    _start_idle()

# ── Game-over handlers ─────────────────────────────────────────────────────

func _on_player_died() -> void:
    _state = State.GAME_OVER
    _kill_all_attacks()
    hud.show_status("YOU DIED    •    Press R to restart")

func _on_enemy_died() -> void:
    _state = State.GAME_OVER
    _kill_all_attacks()
    arena.trigger_flash_all(CombatConfig.COL_PERFECT, 1.0)
    hud.show_status("VICTORY!    •    Press R to restart")
