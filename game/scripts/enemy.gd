# enemy.gd
# Enemy state: health and stun flag.
# Pure logic — no rendering or AI (AI lives in CombatManager).
class_name Enemy
extends Node

signal died
signal health_changed(new_hp: int, max_hp: int)

var hp      : int  = CombatConfig.ENEMY_MAX_HP
var max_hp  : int  = CombatConfig.ENEMY_MAX_HP
var stunned : bool = false

func take_damage(amount: int) -> void:
    if hp <= 0:
        return  # guard: prevent double-death signals
    hp = maxi(0, hp - amount)
    health_changed.emit(hp, max_hp)
    if hp == 0:
        died.emit()

func set_stunned(value: bool) -> void:
    stunned = value
