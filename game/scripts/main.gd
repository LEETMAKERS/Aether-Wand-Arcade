# main.gd
# Root scene script.
# Builds the entire scene tree programmatically in _ready(), then wires
# all cross-node references before adding CombatManager (which starts combat).
# Handles restart: R key reloads the scene, which re-runs _ready() cleanly.
extends Node2D

# Explicit preloads make the dependency graph visible and allow the
# headless script checker to resolve class names without a running project.
const ArenaScript         := preload("res://scripts/arena.gd")
const PlayerScript        := preload("res://scripts/player.gd")
const EnemyScript         := preload("res://scripts/enemy.gd")
const HUDScript           := preload("res://scripts/hud.gd")
const InputHandlerScript  := preload("res://scripts/input_handler.gd")
const CombatManagerScript := preload("res://scripts/combat_manager.gd")

func _ready() -> void:
    _setup()

func _setup() -> void:
    # ── Arena (draws all static visuals) ───────────────────────────────
    var arena_node := ArenaScript.new()
    arena_node.name = "Arena"
    add_child(arena_node)

    # ── Container for moving attack nodes ──────────────────────────────
    var attacks := Node2D.new()
    attacks.name = "AttacksContainer"
    add_child(attacks)

    # ── Logic nodes (no rendering) ─────────────────────────────────────
    var player_node := PlayerScript.new()
    player_node.name = "Player"
    add_child(player_node)

    var enemy_node := EnemyScript.new()
    enemy_node.name = "Enemy"
    add_child(enemy_node)

    # ── HUD (needs player ref for cooldown polling) ────────────────────
    var hud_node    := HUDScript.new()
    hud_node.name   = "HUD"
    hud_node.player = player_node   # set before add_child so _process works immediately
    add_child(hud_node)

    # ── Input handler ─────────────────────────────────────────────────
    var input_node := InputHandlerScript.new()
    input_node.name = "InputHandler"
    add_child(input_node)

    # ── Combat manager — wire references, then add (triggers _ready) ───
    var cm := CombatManagerScript.new()
    cm.name              = "CombatManager"
    cm.arena             = arena_node
    cm.attacks_container = attacks
    cm.player            = player_node
    cm.enemy             = enemy_node
    cm.hud               = hud_node
    cm.input_handler     = input_node
    add_child(cm)   # cm._ready() fires here; combat begins

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R:
            get_tree().reload_current_scene()
