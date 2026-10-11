# hud.gd
# HUD: health bars, status text, and per-lane cooldown indicators.
# All nodes created programmatically — no external scene required.
# Polls player.lane_cooldowns each frame for smooth cooldown display.
class_name HUD
extends CanvasLayer

# Set by main.gd before add_child so _process can poll cooldowns.
var player : Player = null

# ── UI node references ───────────────────────────────────────────────────
var _enemy_bar  : ProgressBar
var _player_bar : ProgressBar
var _enemy_lbl  : Label
var _player_lbl : Label
var _status_lbl : Label
var _cd_panels  : Array[Panel] = []

# One colour per lane (left=blue, centre=green, right=orange)
const LANE_COLORS : Array = [
    Color(0.35, 0.65, 1.00),
    Color(0.30, 1.00, 0.50),
    Color(1.00, 0.60, 0.25),
]

# ── Lifecycle ────────────────────────────────────────────────────────────

func _ready() -> void:
    _build()

func _process(_delta: float) -> void:
    if player == null:
        return
    for i in CombatConfig.LANE_COUNT:
        var frac  : float = player.get_cooldown_fraction(i)
        # Dim the panel when on cooldown; full brightness when ready
        _cd_panels[i].modulate.a = lerp(1.0, 0.22, frac)

# ── Public API ───────────────────────────────────────────────────────────

func update_health(p_hp: int, p_max: int, e_hp: int, e_max: int) -> void:
    _player_bar.max_value = p_max
    _player_bar.value     = p_hp
    _player_lbl.text      = "PLAYER  %d / %d" % [p_hp, p_max]
    _enemy_bar.max_value  = e_max
    _enemy_bar.value      = e_hp
    _enemy_lbl.text       = "ENEMY  %d / %d" % [e_hp, e_max]

func show_status(text: String) -> void:
    _status_lbl.text = text

# ── Scene construction ───────────────────────────────────────────────────

func _build() -> void:
    # Enemy health (top centre)
    _enemy_lbl = _lbl("ENEMY  200 / 200", Vector2(480.0, 8.0), 15)
    _enemy_bar = _bar(Vector2(480.0, 28.0), Vector2(320.0, 16.0),
                      CombatConfig.COL_ENEMY_ATTACK.darkened(0.15), CombatConfig.ENEMY_MAX_HP)

    # Player health (bottom-left)
    _player_lbl = _lbl("PLAYER  100 / 100", Vector2(20.0, 652.0), 15)
    _player_bar = _bar(Vector2(20.0, 672.0), Vector2(320.0, 16.0),
                       CombatConfig.COL_PLAYER, CombatConfig.PLAYER_MAX_HP)

    # Status label (wide, centred in the play area)
    _status_lbl         = Label.new()
    _status_lbl.text    = ""
    _status_lbl.position = Vector2(240.0, 330.0)
    _status_lbl.size    = Vector2(800.0, 52.0)
    _status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status_lbl.add_theme_font_size_override("font_size", 23)
    add_child(_status_lbl)

    # Per-lane cooldown indicator bars (small rounded rectangles below lanes)
    var keys := ["A", "S", "D"]
    for i in CombatConfig.LANE_COUNT:
        var cx : float = CombatConfig.LANE_X[i]
        var panel := Panel.new()
        panel.position = Vector2(cx - 54.0, 653.0)
        panel.size     = Vector2(108.0, 14.0)
        var sf := StyleBoxFlat.new()
        sf.bg_color                  = LANE_COLORS[i]
        sf.corner_radius_top_left    = 3
        sf.corner_radius_top_right   = 3
        sf.corner_radius_bottom_left = 3
        sf.corner_radius_bottom_right = 3
        panel.add_theme_stylebox_override("panel", sf)
        add_child(panel)
        _cd_panels.append(panel)
        # Key hint below the bar
        var klbl := _lbl("[%s]" % keys[i], Vector2(cx - 54.0, 668.0), 13)
        klbl.size                 = Vector2(108.0, 18.0)
        klbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        klbl.modulate             = LANE_COLORS[i].lightened(0.15)

    # Controls hint (bottom centre)
    var hint := _lbl("A / ◀   S / ▼   D / ▶      R = Restart",
                     Vector2(640.0, 700.0), 14, true)
    hint.modulate = Color(0.45, 0.45, 0.55)

    # Perfect-zone annotation (right of the yellow dashed line)
    var pz_y   : float = CombatConfig.PLAYER_Y - CombatConfig.PERFECT_ZONE_HEIGHT
    var pz_lbl := _lbl("▲ PERFECT ZONE", Vector2(CombatConfig.LANE_X[2] + 82.0, pz_y - 2.0), 12)
    pz_lbl.modulate = Color(1.0, 1.0, 0.35, 0.75)

# ── Helpers ──────────────────────────────────────────────────────────────

func _lbl(text: String, pos: Vector2, font_size: int, centered: bool = false) -> Label:
    var l := Label.new()
    l.text     = text
    l.position = pos
    l.add_theme_font_size_override("font_size", font_size)
    if centered:
        l.size                  = Vector2(500.0, 36.0)
        l.position.x           -= 250.0
        l.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
    add_child(l)
    return l

func _bar(pos: Vector2, sz: Vector2, col: Color, max_val: int) -> ProgressBar:
    var b := ProgressBar.new()
    b.position        = pos
    b.size            = sz
    b.max_value       = max_val
    b.value           = max_val
    b.show_percentage = false
    var fill := StyleBoxFlat.new()
    fill.bg_color = col
    var bg := StyleBoxFlat.new()
    bg.bg_color   = Color(0.08, 0.08, 0.12)
    b.add_theme_stylebox_override("fill",       fill)
    b.add_theme_stylebox_override("background", bg)
    add_child(b)
    return b
