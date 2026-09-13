extends Area2D

signal interacted(player: Node2D)

@export var prompt_text: String = "Investigate"
@export var interactable_id: String = ""
@export var one_shot: bool = false
@export var is_active: bool = true:
	set(val):
		is_active = val
		_update_active_state()

var _player_in_range: Node2D = null

func _ready() -> void:
	collision_layer = 4 # Layer 3 for interactables
	collision_mask = 2  # Player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_active_state()

func _update_active_state() -> void:
	var indicator := get_node_or_null("PromptIndicator")
	if indicator:
		indicator.visible = is_active
	if not is_inside_tree():
		return
	if is_active:
		for body in get_overlapping_bodies():
			_check_register_body(body)
	else:
		if _player_in_range and is_instance_valid(_player_in_range):
			if _player_in_range.has_method("unregister_interactable"):
				_player_in_range.unregister_interactable(self)
		_player_in_range = null

func _on_body_entered(body: Node2D) -> void:
	_check_register_body(body)

func _check_register_body(body: Node2D) -> void:
	if not is_active:
		return
	if body.is_in_group("player") or body.name == "Player":
		_player_in_range = body
		if body.has_method("register_interactable"):
			body.register_interactable(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
		if body == _player_in_range:
			_player_in_range = null

func interact(player: Node2D) -> void:
	if not is_active:
		return
	interacted.emit(player)
	if one_shot:
		is_active = false
		if player.has_method("unregister_interactable"):
			player.unregister_interactable(self)
