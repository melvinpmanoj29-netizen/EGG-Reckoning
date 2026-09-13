extends Area2D

@export var fuel_amount: float = 45.0

var _bob_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 8 # Pickups layer
	collision_mask = 2  # Player layer
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_bob_timer += delta * 3.5
	if sprite:
		sprite.position.y = sin(_bob_timer) * 3.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("add_fuel"):
			var res = body.add_fuel(fuel_amount)
			if res == null or res == true:
				var sm := get_node_or_null("/root/SoundManager")
				if sm and sm.has_method("play_pickup"):
					sm.play_pickup()
				queue_free()
