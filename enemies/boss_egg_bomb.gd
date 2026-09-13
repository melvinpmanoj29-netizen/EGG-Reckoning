extends Node2D

## Corrupted Egg Bomb launched by Demon Egg Boss.
## Displays ground warning telegraph and detonates on arrival with AOE blast.

@export var damage: float = 24.0
@export var blast_radius: float = 75.0
@export var travel_time: float = 0.9

var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var _time_elapsed: float = 0.0
var _detonated: bool = false

@onready var bomb_sprite: Sprite2D = $BombSprite
@onready var warning_circle: Polygon2D = $WarningCircle
@onready var explosion_particles: CPUParticles2D = $ExplosionParticles

func launch(p_start_pos: Vector2, p_target_pos: Vector2, p_travel_time: float = -1.0, p_damage: float = -1.0, p_radius: float = -1.0) -> void:
	start_pos = p_start_pos
	target_pos = p_target_pos
	global_position = p_start_pos
	if p_travel_time > 0.0:
		travel_time = p_travel_time
	if p_damage > 0.0:
		damage = p_damage
	if p_radius > 0.0:
		blast_radius = p_radius
	_time_elapsed = 0.0
	_detonated = false
	if warning_circle:
		warning_circle.global_position = target_pos
		warning_circle.visible = true

func _ready() -> void:
	if start_pos == Vector2.ZERO:
		start_pos = global_position
	if target_pos == Vector2.ZERO:
		target_pos = global_position

	if warning_circle:
		warning_circle.global_position = target_pos
		warning_circle.visible = true

func _physics_process(delta: float) -> void:
	if _detonated:
		return

	_time_elapsed += delta
	var progress := clampf(_time_elapsed / travel_time, 0.0, 1.0)

	# Parabolic arc height
	var arc_height := sin(progress * PI) * 55.0
	var linear_pos := start_pos.lerp(target_pos, progress)
	bomb_sprite.global_position = linear_pos + Vector2(0, -arc_height)
	bomb_sprite.rotation += delta * 14.0

	# Warning circle pulse
	warning_circle.scale = Vector2.ONE * (0.6 + progress * 0.4)

	if progress >= 1.0:
		_explode()

func _explode() -> void:
	if _detonated:
		return
	_detonated = true

	bomb_sprite.visible = false
	warning_circle.visible = false

	# Play explosion particles
	if explosion_particles:
		explosion_particles.global_position = target_pos
		explosion_particles.restart()
		explosion_particles.emitting = true

	# Play boss attack whoosh / explosion sound if SoundManager exists
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_boss_attack"):
		sm.play_boss_attack()

	# Deal damage to player if inside blast radius
	var player := get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist := target_pos.distance_to(player.global_position)
		if dist <= blast_radius and player.has_method("take_damage"):
			player.take_damage(damage)

	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_callback(queue_free)
