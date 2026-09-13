extends "res://enemies/base_egg_enemy.gd"

## Crawling Egg Minion — Basic Melee Stalker.
## Skitters in dark alleys, investigates noises, and performs close-range lunge attacks.

func _ready() -> void:
	max_health = 30.0
	move_speed = 70.0
	chase_speed = 110.0
	vision_range_dusk = 240.0
	vision_range_night = 320.0
	attack_damage = 15.0
	attack_range = 42.0
	attack_cooldown = 0.9
	super._ready()

func _execute_attack() -> void:
	# Quick forward lunge visual
	if _target_player:
		var dir := (_target_player.global_position - global_position).normalized()
		velocity = dir * 220.0
		move_and_slide()

	super._execute_attack()
