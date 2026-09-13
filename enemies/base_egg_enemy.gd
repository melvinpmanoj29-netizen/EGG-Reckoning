extends CharacterBody2D
class_name BaseEggEnemy

## Base Egg AI State Machine with Vision, Hearing, Patrol, Alert, Chase, and Search.
## Inherited by CrawlingEgg (Minion), PoisonEgg, and DemonEggMinion.

signal defeated(enemy: Node2D)
signal state_changed(old_state: int, new_state: int)

enum AIState {
	IDLE = 0,
	PATROL = 1,
	INVESTIGATE = 2,
	ALERT = 3,
	CHASE = 4,
	ATTACK = 5,
	SEARCH = 6,
	RETURN_TO_PATROL = 7
}

@export var max_health: float = 35.0
@export var move_speed: float = 70.0
@export var chase_speed: float = 115.0
@export var vision_range_dusk: float = 240.0
@export var vision_range_night: float = 340.0
@export var vision_fov_degrees: float = 110.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 45.0
@export var attack_cooldown: float = 1.0
@export var patrol_points: Array[Vector2] = []

var health: float = 35.0
var current_state: AIState = AIState.IDLE
var spawn_position: Vector2 = Vector2.ZERO

var _patrol_index: int = 0
var _idle_timer: float = 0.0
var _alert_timer: float = 0.0
var _search_timer: float = 0.0
var _attack_timer: float = 0.0
var _los_lost_timer: float = 0.0
var _wiggle_cycle: float = 0.0

var _target_player: Node2D = null
var _target_destination: Vector2 = Vector2.ZERO
var _last_known_player_pos: Vector2 = Vector2.ZERO
var _is_dying: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: Area2D = get_node_or_null("HitBox")
@onready var death_particles: CPUParticles2D = get_node_or_null("DeathParticles")

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	spawn_position = global_position

	if patrol_points.is_empty():
		# Default local guard patrol
		patrol_points.append(spawn_position + Vector2(-60, 0))
		patrol_points.append(spawn_position + Vector2(60, 0))

	_target_destination = patrol_points[0]
	current_state = AIState.PATROL if patrol_points.size() > 1 else AIState.IDLE
	_idle_timer = randf_range(1.0, 3.0)

func _physics_process(delta: float) -> void:
	if _is_dying:
		return

	if _target_player == null or not is_instance_valid(_target_player):
		_target_player = get_tree().get_first_node_in_group("player")

	if _attack_timer > 0.0:
		_attack_timer -= delta

	# Check Vision detection if player exists
	if _target_player != null and is_instance_valid(_target_player):
		var can_see := _can_see_player(_target_player)
		if can_see:
			_last_known_player_pos = _target_player.global_position
			_los_lost_timer = 0.0

			if current_state != AIState.CHASE and current_state != AIState.ATTACK and current_state != AIState.ALERT:
				_enter_alert_state()
		else:
			if current_state == AIState.CHASE:
				_los_lost_timer += delta
				if _los_lost_timer > 2.5:
					_enter_state(AIState.SEARCH)

	# Execute State Machine
	match current_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.PATROL:
			_process_patrol(delta)
		AIState.INVESTIGATE:
			_process_investigate(delta)
		AIState.ALERT:
			_process_alert(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.ATTACK:
			_process_attack(delta)
		AIState.SEARCH:
			_process_search(delta)
		AIState.RETURN_TO_PATROL:
			_process_return_to_patrol(delta)

	# Organic visual locomotion bobbing
	if velocity.length() > 5.0 and sprite:
		_wiggle_cycle += delta * 16.0
		sprite.scale = Vector2(0.24 + sin(_wiggle_cycle) * 0.02, 0.24 - sin(_wiggle_cycle) * 0.02)

func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		if patrol_points.size() > 1:
			_enter_state(AIState.PATROL)
		else:
			_idle_timer = randf_range(2.0, 5.0)
			rotation += randf_range(-1.2, 1.2)

func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		_enter_state(AIState.IDLE)
		return

	_target_destination = patrol_points[_patrol_index]
	var dist := global_position.distance_to(_target_destination)

	if dist < 16.0:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		_idle_timer = randf_range(1.5, 3.5)
		_enter_state(AIState.IDLE)
		return

	var dir := (_target_destination - global_position).normalized()
	velocity = dir * move_speed
	rotation = lerp_angle(rotation, dir.angle(), delta * 8.0)
	move_and_slide()

func _process_investigate(delta: float) -> void:
	var dist := global_position.distance_to(_target_destination)
	if dist < 24.0:
		_enter_state(AIState.SEARCH)
		return

	var dir := (_target_destination - global_position).normalized()
	velocity = dir * (move_speed * 1.1)
	rotation = lerp_angle(rotation, dir.angle(), delta * 10.0)
	move_and_slide()

func _process_alert(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if _target_player:
		var dir := (_target_player.global_position - global_position).normalized()
		rotation = lerp_angle(rotation, dir.angle(), delta * 12.0)

	_alert_timer -= delta
	if _alert_timer <= 0.0:
		_enter_state(AIState.CHASE)

func _process_chase(delta: float) -> void:
	if _target_player == null or not is_instance_valid(_target_player):
		_enter_state(AIState.SEARCH)
		return

	var to_player := _target_player.global_position - global_position
	var dist := to_player.length()

	# In attack range?
	if dist <= attack_range:
		_enter_state(AIState.ATTACK)
		return

	# Max chase dropoff distance
	if dist > 550.0:
		_enter_state(AIState.SEARCH)
		return

	var dir := to_player.normalized()
	velocity = dir * chase_speed
	rotation = lerp_angle(rotation, dir.angle(), delta * 12.0)
	move_and_slide()

func _process_attack(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if _attack_timer <= 0.0:
		_execute_attack()
		_attack_timer = attack_cooldown

	# Resume chase after attack
	_enter_state(AIState.CHASE)

func _process_search(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_search_timer -= delta
	# Look around in place
	rotation += sin(delta * 4.0) * 0.08
	if _search_timer <= 0.0:
		_enter_state(AIState.RETURN_TO_PATROL)

func _process_return_to_patrol(delta: float) -> void:
	var target_pt := patrol_points[0] if not patrol_points.is_empty() else spawn_position
	var dist := global_position.distance_to(target_pt)

	if dist < 24.0:
		_enter_state(AIState.PATROL if patrol_points.size() > 1 else AIState.IDLE)
		return

	var dir := (target_pt - global_position).normalized()
	velocity = dir * move_speed
	rotation = lerp_angle(rotation, dir.angle(), delta * 8.0)
	move_and_slide()

func _enter_state(new_state: AIState) -> void:
	var old := current_state
	current_state = new_state
	state_changed.emit(old, new_state)

	match new_state:
		AIState.SEARCH:
			_search_timer = randf_range(3.0, 4.5)
		AIState.ALERT:
			_alert_timer = 0.35

func _enter_alert_state() -> void:
	_enter_state(AIState.ALERT)
	# Red eye flash telegraph
	modulate = Color(1.5, 0.4, 0.4, 1.0)
	var t := create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.35)

func _can_see_player(player_node: Node2D) -> bool:
	if player_node == null:
		return false

	var to_player := player_node.global_position - global_position
	var dist := to_player.length()

	var max_vision := vision_range_dusk
	var gs := get_node_or_null("/root/GameState")
	if gs and "is_night" in gs and gs.is_night:
		max_vision = vision_range_night

	if dist > max_vision:
		return false

	# FOV check
	var forward := Vector2.RIGHT.rotated(rotation)
	var angle_to := forward.angle_to(to_player.normalized())
	if abs(angle_to) > deg_to_rad(vision_fov_degrees * 0.5):
		# Outside direct vision cone; if extremely close (stealth back-touch), still detect
		if dist > 40.0:
			return false

	# Raycast Wall Line-of-Sight Check
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, player_node.global_position, 1) # Layer 1 = World Walls
	var result := space_state.intersect_ray(query)

	if result.is_empty():
		return true # Unobstructed line of sight
	return false

func on_noise_heard(noise_origin: Vector2, radius: float) -> void:
	if _is_dying:
		return

	var dist := global_position.distance_to(noise_origin)
	if dist <= radius:
		if current_state == AIState.IDLE or current_state == AIState.PATROL or current_state == AIState.SEARCH or current_state == AIState.RETURN_TO_PATROL:
			_target_destination = noise_origin
			_enter_state(AIState.INVESTIGATE)
			# Small question visual shudder
			rotation = (noise_origin - global_position).angle()

func _execute_attack() -> void:
	# Default melee attack: deal damage to overlapping player bodies in HitBox
	if hit_box:
		for body in hit_box.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(attack_damage)
				break

func take_damage(amount: float) -> void:
	take_fire_damage(amount)

func take_burn_damage(amount: float) -> void:
	take_fire_damage(amount)

func take_fire_damage(amount: float) -> void:
	if _is_dying:
		return

	health -= amount
	# Immediately aggro on taking damage
	if current_state != AIState.CHASE and current_state != AIState.ATTACK:
		if _target_player:
			_last_known_player_pos = _target_player.global_position
			_enter_state(AIState.CHASE)

	# Burn effect
	modulate = Color(1.8, 0.4, 0.2, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

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
	if sprite:
		sprite.visible = false
	if hit_box:
		hit_box.set_deferred("monitoring", false)

	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(queue_free)
