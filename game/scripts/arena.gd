# arena.gd
# Draws all static visual elements: background, lanes, perfect zone,
# enemy and player body shapes, and transient flash effects.
# Purely presentational — no game logic.
class_name Arena
extends Node2D

# ── Flash state ─────────────────────────────────────────────────────────
# Each entry: { lane: int, color: Color, timer: float }
var _flashes    : Array = []
var _show_vuln  : bool  = false
var _vuln_timer : float = 0.0

# ── Public API ───────────────────────────────────────────────────────────

func trigger_flash(lane: int, col: Color, duration: float = 0.25) -> void:
    _flashes.append({ "lane": lane, "color": col, "timer": duration })
    queue_redraw()

func trigger_flash_all(col: Color, duration: float = 0.35) -> void:
    for i in CombatConfig.LANE_COUNT:
        trigger_flash(i, col, duration)

func show_vulnerability(duration: float) -> void:
    _show_vuln  = true
    _vuln_timer = duration
    queue_redraw()

func hide_vulnerability() -> void:
    _show_vuln = false
    queue_redraw()

# ── Godot callbacks ──────────────────────────────────────────────────────

func _ready() -> void:
    # Lane key labels (drawn as Node children so text is easy to handle)
    var keys := ["A", "S", "D"]
    for i in CombatConfig.LANE_COUNT:
        var lbl := Label.new()
        lbl.text     = keys[i]
        lbl.position = Vector2(CombatConfig.LANE_X[i] - 10.0,
                               CombatConfig.LANE_BOTTOM_Y + 6.0)
        lbl.add_theme_font_size_override("font_size", 20)
        lbl.modulate = Color(0.55, 0.55, 0.80)
        add_child(lbl)

func _process(delta: float) -> void:
    var dirty := false
    # Age flash effects
    for i in range(_flashes.size() - 1, -1, -1):
        _flashes[i].timer -= delta
        if _flashes[i].timer <= 0.0:
            _flashes.remove_at(i)
        dirty = true
    # Age vulnerability overlay
    if _show_vuln:
        _vuln_timer -= delta
        if _vuln_timer <= 0.0:
            _show_vuln = false
        dirty = true
    if dirty:
        queue_redraw()

func _draw() -> void:
    # ── Background ────────────────────────────────────────────────────
    draw_rect(Rect2(0.0, 0.0, CombatConfig.VIEWPORT_W, CombatConfig.VIEWPORT_H),
              CombatConfig.COL_BG)

    # ── Lanes ──────────────────────────────────────────────────────────
    var lw      : float = CombatConfig.LANE_WIDTH
    var hw      : float = lw * 0.5
    var top_y   : float = CombatConfig.LANE_TOP_Y
    var bot_y   : float = CombatConfig.LANE_BOTTOM_Y
    var lane_h  : float = bot_y - top_y
    var pz_top  : float = CombatConfig.PLAYER_Y - CombatConfig.PERFECT_ZONE_HEIGHT

    for i in CombatConfig.LANE_COUNT:
        var cx   : float = CombatConfig.LANE_X[i]
        var rect := Rect2(cx - hw, top_y, lw, lane_h)

        # Lane fill
        draw_rect(rect, CombatConfig.COL_LANE)

        # Perfect zone tint (faint yellow near player)
        draw_rect(Rect2(cx - hw, pz_top, lw, CombatConfig.PERFECT_ZONE_HEIGHT),
                  CombatConfig.COL_PERFECT_ZONE)

        # Vulnerability green overlay
        if _show_vuln:
            draw_rect(rect, CombatConfig.COL_VULN_TINT)

        # Flash effects (fade out by timer fraction)
        for f in _flashes:
            if f.lane == i:
                var t    : float = clampf(f.timer * 5.0, 0.0, 1.0)
                var fcol : Color = f.color
                fcol.a   = t * 0.45
                draw_rect(rect, fcol)

        # Lane border
        draw_rect(rect, CombatConfig.COL_LANE_BORDER, false, 1.5)

    # ── Perfect-zone dividing line (dashed yellow) ─────────────────────
    var left_x  : float = CombatConfig.LANE_X[0] - hw
    var right_x : float = CombatConfig.LANE_X[2] + hw
    draw_dashed_line(
        Vector2(left_x, pz_top), Vector2(right_x, pz_top),
        Color(1.0, 1.0, 0.3, 0.4), 1.0, 10.0
    )

    # ── Enemy shape (red diamond at top) ──────────────────────────────
    var ex : float = CombatConfig.LANE_X[1]
    var ey : float = CombatConfig.ENEMY_Y
    draw_colored_polygon(PackedVector2Array([
        Vector2(ex,       ey - 24.0),
        Vector2(ex + 30.0, ey),
        Vector2(ex,       ey + 20.0),
        Vector2(ex - 30.0, ey),
    ]), CombatConfig.COL_ENEMY)
    # Horizontal enemy line across all lanes
    draw_line(Vector2(left_x, ey), Vector2(right_x, ey), CombatConfig.COL_ENEMY, 2.0)

    # ── Player shape (green diamond at bottom) ─────────────────────────
    var px : float = CombatConfig.LANE_X[1]
    var py : float = CombatConfig.PLAYER_Y
    draw_colored_polygon(PackedVector2Array([
        Vector2(px,       py - 20.0),
        Vector2(px + 24.0, py),
        Vector2(px,       py + 14.0),
        Vector2(px - 24.0, py),
    ]), CombatConfig.COL_PLAYER)
    # Horizontal player line across all lanes
    draw_line(Vector2(left_x, py), Vector2(right_x, py), CombatConfig.COL_PLAYER, 2.0)
