extends "res://enemies/base_egg_enemy.gd"

## Poison Egg — Ranged Corrupted Support Enemy.
## Keeps safe distance, repositions away from burner rush, and spits toxic acid projectiles.

const POISON_PROJECTILE_SCENE := preload("res://enemies/poison_projectile.tscn")

func _ready() -> void:
	max_health = 35.0
	move_speed = 65.0
	chase_speed = 95.0
	vision_range_dusk = 280.0
	vision_range_night = 380.0
	attack_damage = 16.0
	attack_range = 240.0
	attack_cooldown = 1.8
	super._ready()

func _process_chase(delta: float) -> void:
	if _target_player == null or not is_instance_valid(_target_player):
		_enter_state(AIState.SEARCH)
		return

	var to_player := _target_player.global_position - global_position
	var dist := to_player.length()

	# Keep ranged distance (160 - 240 px)
	if dist <= attack_range and dist >= 160.0:
		velocity = Vector2.ZERO
		move_and_slide()
		rotation = lerp_angle(rotation, to_player.angle(), delta * 10.0)
		if _attack_timer <= 0.0:
			_enter_state(AIState.ATTACK)
		return

	if dist < 140.0:
		# Reposition / back away from player
		var away_dir := -to_player.normalized()
		velocity = away_dir * move_speed
		rotation = lerp_angle(rotation, to_player.angle(), delta * 8.0)
		move_and_slide()
		return

	# Otherwise advance toward attack range
	var dir := to_player.normalized()
	velocity = dir * chase_speed
	rotation = lerp_angle(rotation, dir.angle(), delta * 10.0)
	move_and_slide()

func _execute_attack() -> void:
	if _target_player == null or not is_instance_valid(_target_player):
		return

	var proj := POISON_PROJECTILE_SCENE.instantiate() as Area2D
	proj.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 20.0
	var dir := (_target_player.global_position - global_position).normalized()
	if "direction" in proj:
		proj.direction = dir
	proj.rotation = dir.angle()

	var parent := get_parent()
	if parent:
		parent.add_child(proj)

	# Recoil visual
	if sprite:
		var t := create_tween()
		t.tween_property(sprite, "scale", Vector2(0.28, 0.20), 0.08)
		t.tween_property(sprite, "scale", Vector2(0.24, 0.24), 0.15)
