extends CharacterBody2D

## Giant Egg Tank -- Heavy armored egg that spawns 2 crawling eggs upon death.

signal defeated(minion: Node2D)

const MINION_SCENE := preload("res://enemies/minion_egg.tscn")

@export var max_health: float = 120.0
@export var speed: float = 50.0
@export var attack_damage: float = 25.0
@export var detection_range: float = 400.0

var health: float = 120.0
var _attack_timer: float = 0.0
var _target_player: Node2D = null
var _is_dying: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: Area2D = $HitBox
@onready var death_particles: CPUParticles2D = $DeathParticles

func _ready() -> void:
	add_to_group("enemies")
	health = max_health

func _physics_process(delta: float) -> void:
	if _is_dying:
		return

	if _target_player == null or not is_instance_valid(_target_player):
		_target_player = get_tree().get_first_node_in_group("player")
		if _target_player == null:
			return

	var dist := global_position.distance_to(_target_player.global_position)
	var active_range := detection_range
	var gs := get_node_or_null("/root/GameState")
	if gs and "is_night" in gs and gs.is_night:
		active_range = 9999.0

	if dist <= active_range:
		var dir := (_target_player.global_position - global_position).normalized()
		velocity = dir * speed
		rotation = dir.angle()
		move_and_slide()

	if _attack_timer > 0.0:
		_attack_timer -= delta

	if _attack_timer <= 0.0:
		for body in hit_box.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(attack_damage)
				_attack_timer = 1.0
				break

func take_fire_damage(amount: float) -> void:
	if _is_dying:
		return
	health -= amount
	modulate = Color(1.0, 0.4, 0.1, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)

	if health <= 0.0:
		_die()

func _die() -> void:
	if _is_dying:
		return
	_is_dying = true
	var gs := get_node_or_null("/root/GameState")
	if gs and "minions_defeated" in gs:
		gs.minions_defeated += 1
	defeated.emit(self)

	if death_particles:
		death_particles.emitting = true
	sprite.visible = false
	hit_box.set_deferred("monitoring", false)

	# Spawn 2 crawler minions from the shattered shell
	var parent := get_parent()
	if parent:
		for i in range(2):
			var minion := MINION_SCENE.instantiate() as Node2D
			var offset := Vector2(cos(i * PI), sin(i * PI)) * 30.0
			minion.global_position = global_position + offset
			parent.call_deferred("add_child", minion)

	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(queue_free)
