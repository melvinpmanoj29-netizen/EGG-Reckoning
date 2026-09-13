extends Area2D

## Toxic Acid Projectile launched by Poison Egg.

@export var speed: float = 240.0
@export var damage: float = 16.0
@export var lifetime: float = 2.5

var direction: Vector2 = Vector2.ZERO
var _timer: float = 0.0

@onready var particles: CPUParticles2D = $Particles
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_timer = lifetime

func fire(start_pos: Vector2, dir: Vector2, spd: float = -1.0, dmg: float = -1.0) -> void:
	launch(start_pos, dir, spd, dmg)

func launch(start_pos: Vector2, dir: Vector2, spd: float = -1.0, dmg: float = -1.0) -> void:
	global_position = start_pos
	direction = dir.normalized()
	rotation = dir.angle()
	if spd > 0.0:
		speed = spd
	if dmg > 0.0:
		damage = dmg

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_timer -= delta
	if _timer <= 0.0:
		_explode()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		_explode()
	elif body is StaticBody2D or body is TileMap:
		_explode()

func _explode() -> void:
	set_physics_process(false)
	set_deferred("monitoring", false)
	if sprite:
		sprite.visible = false
	if particles:
		particles.emitting = false
	queue_free()
