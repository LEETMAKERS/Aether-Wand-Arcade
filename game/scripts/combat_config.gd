# combat_config.gd
# Central tuning file — change values here for balance adjustments.
# Access as CombatConfig.CONSTANT_NAME from any script (globally registered via class_name).
class_name CombatConfig
extends RefCounted

# ── Viewport ───────────────────────────────────────────────────────────────
const VIEWPORT_W : float = 1280.0
const VIEWPORT_H : float = 720.0

# ── Lane geometry ──────────────────────────────────────────────────────────
const LANE_COUNT : int   = 3
# X centre of each lane: left / centre / right
const LANE_X     : Array = [380.0, 640.0, 900.0]
const LANE_WIDTH : float = 150.0

# Vertical extent of the drawn lanes
const LANE_TOP_Y    : float = 60.0
const LANE_BOTTOM_Y : float = 640.0

# Where enemy attacks originate and where the player stands
const ENEMY_Y  : float = 95.0
const PLAYER_Y : float = 608.0

# Height of the "perfect intercept" zone above the player.
# An enemy attack whose Y >= (PLAYER_Y - PERFECT_ZONE_HEIGHT) is in the zone.
const PERFECT_ZONE_HEIGHT : float = 100.0

# ── Attack physics ─────────────────────────────────────────────────────────
const ENEMY_ATTACK_SPEED            : float = 210.0  # px / s, downward
const PLAYER_ATTACK_SPEED           : float = 480.0  # px / s, upward (fast = snappy feel)
const ATTACK_RADIUS                 : float = 16.0   # visual + collision half-size
# Multi-lane enemy patterns move slower so the player has a fair chance
const ENEMY_MULTIPATTERN_SPEED_MULT : float = 0.72

# ── Player cooldown ────────────────────────────────────────────────────────
# Global cooldown (GCD): lockout across ALL lanes after any attack.
# Prevents rolling fingers across A-S-D simultaneously.
const PLAYER_GLOBAL_COOLDOWN      : float = 0.32  # seconds lockout on all lanes
# Individual lane cooldown: prevents mashing the same lane.
const PLAYER_LANE_COOLDOWN        : float = 0.48  # seconds lockout on the used lane
# Rapid burst GCD during the enemy vulnerability window (allows rapid punishing combo).
const PLAYER_VULN_GLOBAL_COOLDOWN : float = 0.14  # seconds

# ── Health ─────────────────────────────────────────────────────────────────
const PLAYER_MAX_HP : int = 100
const ENEMY_MAX_HP  : int = 200

# ── Damage ─────────────────────────────────────────────────────────────────
const ENEMY_LANE_DAMAGE        : int = 18  # player takes this per unblocked enemy attack
const PLAYER_INTERCEPT_DAMAGE  : int = 12  # regular collision outside perfect zone
const PLAYER_PERFECT_DAMAGE    : int = 20  # bonus for the perfect intercept itself
const PLAYER_VULN_DAMAGE       : int = 35  # each lane press during vulnerability window
# Free swings (reaching enemy without intercepting) deal 0 damage outside vulnerability.
# Enemy armor deflects random projectiles — forces player to parry and earn openings!
const PLAYER_FREESWING_DAMAGE  : int =  0

# ── Stun / Vulnerability ───────────────────────────────────────────────────
const VULNERABILITY_DURATION : float = 1.5  # seconds of bonus-damage window

# ── Enemy AI ───────────────────────────────────────────────────────────────
# Delay between the last attack resolving and the next pattern launching.
# Alternates min / max for deterministic but varied pacing.
const ENEMY_IDLE_DELAY_MIN : float = 1.4
const ENEMY_IDLE_DELAY_MAX : float = 2.1

# Attack patterns — each element is an Array of lane indices.
# 0 = left, 1 = centre, 2 = right.
# The AI cycles through this list deterministically (no RNG yet).
const ENEMY_PATTERNS : Array = [
    [1],        # centre
    [0],        # left
    [2],        # right
    [0, 2],     # spread
    [1],        # centre
    [0, 1],     # left + centre
    [2],        # right
    [1, 2],     # centre + right
    [0, 1, 2],  # full sweep (slower due to speed mult)
    [0],        # left
    [1],        # centre
    [0, 2],     # spread
]

# ── Colors ─────────────────────────────────────────────────────────────────
const COL_BG            : Color = Color(0.07, 0.07, 0.12)
const COL_LANE          : Color = Color(0.14, 0.14, 0.20)
const COL_LANE_BORDER   : Color = Color(0.28, 0.28, 0.45)
const COL_PERFECT_ZONE  : Color = Color(1.00, 1.00, 0.30, 0.09)
const COL_ENEMY_ATTACK  : Color = Color(1.00, 0.22, 0.18)
const COL_PLAYER_ATTACK : Color = Color(0.22, 0.85, 1.00)
const COL_INTERCEPT     : Color = Color(1.00, 0.90, 0.20)
const COL_PERFECT       : Color = Color(1.00, 0.50, 1.00)
const COL_VULN_TINT     : Color = Color(0.30, 1.00, 0.50, 0.15)
const COL_PLAYER        : Color = Color(0.25, 0.90, 0.40)
const COL_ENEMY         : Color = Color(0.95, 0.25, 0.20)
