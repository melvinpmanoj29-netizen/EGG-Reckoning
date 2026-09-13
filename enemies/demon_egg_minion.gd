extends "res://enemies/base_egg_enemy.gd"

## Demon Egg Minion — Fast Demonic Hunter.
## Aggressive hunter with wider vision cone, fast pursuit, and lethal leap attacks.

func _ready() -> void:
	max_health = 45.0
	move_speed = 85.0
	chase_speed = 140.0
	vision_range_dusk = 300.0
	vision_range_night = 420.0
	vision_fov_degrees = 130.0
	attack_damage = 25.0
	attack_range = 55.0
	attack_cooldown = 1.2
	super._ready()

func _execute_attack() -> void:
	if _target_player:
		var dir := (_target_player.global_position - global_position).normalized()
		velocity = dir * 280.0
		move_and_slide()

	super._execute_attack()
