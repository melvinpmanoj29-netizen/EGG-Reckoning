extends CharacterBody2D

## Player Controller for EGG: RECKONING.
## Features WASD movement, mouse aiming, incendiary burner with particle effects,
## tactical flashlight, sprint, health & fuel management, and Stage 3C equipment progression.

signal health_changed(current: float, max_val: float)
signal fuel_changed(current: float, max_val: float)
signal died

const BASE_SPEED: float = 140.0
const SPRINT_SPEED: float = 210.0
const FUEL_CONSUMPTION_RATE: float = 16.0 # fuel per second while firing
const BURN_DAMAGE_PER_SEC: float = 45.0

@export var max_health: float = 100.0
@export var max_fuel: float = 100.0

var health: float = 100.0
var fuel: float = 100.0
var _invuln_timer: float = 0.0
var _is_attacking: bool = false
var _sound_timer: float = 0.0
var _walk_cycle: float = 0.0

var _nearby_interactables: Array[Area2D] = []
var _noise_timer: float = 0.0

@onready var character_sprite: Sprite2D = $CharacterSprite
@onready var nozzle: Node2D = $Nozzle
@onready var flame_cone: Area2D = $Nozzle/FlameCone
@onready var fire_particles: CPUParticles2D = $Nozzle/FlameCone/FireParticles
@onready var spark_particles: CPUParticles2D = $Nozzle/FlameCone/Sparks
@onready var smoke_particles: CPUParticles2D = $Nozzle/FlameCone/Smoke
@onready var fire_light: PointLight2D = $Nozzle/FlameCone/FireLight
@onready var flashlight: PointLight2D = $Nozzle/Flashlight
@onready var ambient_light: PointLight2D = $AmbientLight

func _ready() -> void:
	add_to_group("player")
	flame_cone.monitoring = false
	flame_cone.visible = false
	_set_particles_emitting(false)

	# Ensure 100% solid opacity
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	if character_sprite:
		character_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		character_sprite.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

	# Sync character customization
	var selected_char := "boy"
	var gs := get_node_or_null("/root/GameState")
	if gs and "selected_character" in gs:
		selected_char = gs.selected_character

	match selected_char:
		"girl":
			if ResourceLoader.exists("res://assets/characters/girl/sprite.png"):
				character_sprite.texture = load("res://assets/characters/girl/sprite.png")
		_:
			if ResourceLoader.exists("res://assets/characters/boy/sprite.png"):
				character_sprite.texture = load("res://assets/characters/boy/sprite.png")

	# Sync equipment & visuals (empty hands by default)
	update_equipment_visuals()

	health_changed.emit(health, max_health)
	fuel_changed.emit(fuel, max_fuel)

func update_equipment_visuals() -> void:
	if nozzle == null:
		nozzle = get_node_or_null("FlameCone/Nozzle")
	if flashlight == null:
		flashlight = get_node_or_null("TorchLight")

	var gs := get_node_or_null("/root/GameState")
	var has_burner: bool = _check_has_burner()
	var has_torch: bool = false
	var torch_active: bool = true

	if gs:
		if "has_torch" in gs:
			has_torch = gs.has_torch
		if "torch_enabled" in gs:
			torch_active = gs.torch_enabled

	if nozzle:
		nozzle.visible = has_burner

	if flashlight:
		flashlight.enabled = (has_torch and torch_active)

func _physics_process(delta: float) -> void:
	if _is_modal_active():
		velocity = Vector2.ZERO
		move_and_slide()
		_stop_attack()
		return

	# WASD Movement & Sprint
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_sprint: bool = Input.is_key_pressed(KEY_SHIFT) or (InputMap.has_action("sprint") and Input.is_action_pressed("sprint"))
	var current_speed: float = SPRINT_SPEED if (is_sprint and direction.length_squared() > 0.0) else BASE_SPEED
	velocity = direction * current_speed
	move_and_slide()

	# Aim character, burner and flashlight towards mouse
	var mouse_pos := get_global_mouse_position()
	var aim_angle := (mouse_pos - global_position).angle()
	character_sprite.rotation = aim_angle
	if nozzle: nozzle.look_at(mouse_pos)
	if flashlight: flashlight.look_at(mouse_pos)

	# Subtle walk bobbing animation & movement noise emission
	if velocity.length() > 5.0:
		var bob_rate: float = 18.0 if is_sprint else 14.0
		_walk_cycle += delta * bob_rate
		character_sprite.scale = Vector2(0.35 + sin(_walk_cycle) * 0.02, 0.35 - sin(_walk_cycle) * 0.02)

		_noise_timer -= delta
		if _noise_timer <= 0.0:
			_noise_timer = 0.22 if is_sprint else 0.45
			var noise_rad: float = 220.0 if is_sprint else 70.0
			broadcast_noise(global_position, noise_rad)
	else:
		character_sprite.scale = Vector2(0.35, 0.35)

	# Handle attack (Left Click or "attack" action)
	var wants_attack: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or (InputMap.has_action("attack") and Input.is_action_pressed("attack"))
	var has_burner_unlocked: bool = _check_has_burner()
	
	if wants_attack and has_burner_unlocked and fuel > 0.0:
		_start_attack(delta)
	else:
		_stop_attack()

	# Handle Invulnerability Flash
	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		character_sprite.modulate.a = 0.5 + 0.5 * sin(_invuln_timer * 30.0)
	else:
		character_sprite.modulate.a = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F or event.physical_keycode == KEY_F:
			_toggle_flashlight()
		elif event.keycode == KEY_E or event.physical_keycode == KEY_E:
			_interact_with_nearest()
	elif InputMap.has_action("toggle_torch") and event.is_action_pressed("toggle_torch"):
		_toggle_flashlight()
	elif InputMap.has_action("interact") and event.is_action_pressed("interact"):
		_interact_with_nearest()

func _toggle_flashlight() -> void:
	var gs := get_node_or_null("/root/GameState")
	var has_torch := false
	if gs and "has_torch" in gs:
		has_torch = gs.has_torch

	if not has_torch:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_alert"):
			hud.show_alert("NO FLASHLIGHT IN INVENTORY")
		return

	if gs:
		gs.torch_enabled = not gs.torch_enabled
		flashlight.enabled = gs.torch_enabled
	else:
		flashlight.enabled = not flashlight.enabled

	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_click"):
		sm.play_click()

func _interact_with_nearest() -> void:
	# Filter invalid instances
	_nearby_interactables = _nearby_interactables.filter(func(a): return is_instance_valid(a))
	if _nearby_interactables.is_empty():
		return

	# Sort by proximity
	_nearby_interactables.sort_custom(func(a, b):
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)

	var target: Area2D = _nearby_interactables[0]
	if target.has_method("interact"):
		target.interact(self)

func register_interactable(area: Area2D) -> void:
	if not _nearby_interactables.has(area):
		_nearby_interactables.append(area)

func unregister_interactable(area: Area2D) -> void:
	_nearby_interactables.erase(area)

func broadcast_noise(noise_pos: Vector2, radius: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.has_method("on_noise_heard"):
			enemy.on_noise_heard(noise_pos, radius)

func take_damage(amount: float) -> void:
	if _invuln_timer > 0.0:
		return

	health = max(0.0, health - amount)
	_invuln_timer = 0.8
	health_changed.emit(health, max_health)

	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_hurt"):
		sm.play_hurt()

	if health <= 0.0:
		died.emit()

func add_health(amount: float) -> bool:
	if health >= max_health:
		return false
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_pickup"):
		sm.play_pickup()
	return true

func heal(amount: float) -> bool:
	return add_health(amount)

func add_fuel(amount: float) -> bool:
	if fuel >= max_fuel:
		return false
	fuel = min(max_fuel, fuel + amount)
	fuel_changed.emit(fuel, max_fuel)
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_pickup"):
		sm.play_pickup()
	return true

func _check_has_burner() -> bool:
	var gs := get_node_or_null("/root/GameState")
	if gs and "has_burner" in gs:
		return gs.has_burner
	return false

func _set_particles_emitting(emitting: bool) -> void:
	if fire_particles: fire_particles.emitting = emitting
	if spark_particles: spark_particles.emitting = emitting
	if smoke_particles: smoke_particles.emitting = emitting
	if fire_light: fire_light.enabled = emitting

func _start_attack(delta: float) -> void:
	_is_attacking = true
	flame_cone.monitoring = true
	flame_cone.visible = true
	_set_particles_emitting(true)

	fuel = max(0.0, fuel - FUEL_CONSUMPTION_RATE * delta)
	fuel_changed.emit(fuel, max_fuel)

	# Firing burner emits a loud noise event (radius 550px)
	broadcast_noise(global_position, 550.0)

	# Sound loop trigger
	_sound_timer -= delta
	if _sound_timer <= 0.0:
		_sound_timer = 0.25
		var sm := get_node_or_null("/root/SoundManager")
		if sm and sm.has_method("play_flamethrower"):
			sm.play_flamethrower()

	# Deal damage to enemies in flame cone
	var damage_to_deal: float = BURN_DAMAGE_PER_SEC * delta
	for body in flame_cone.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			if body.has_method("take_fire_damage"):
				body.take_fire_damage(damage_to_deal)
			elif body.has_method("take_burn_damage"):
				body.take_burn_damage(damage_to_deal)
			elif body.has_method("take_damage"):
				body.take_damage(damage_to_deal)

	for area in flame_cone.get_overlapping_areas():
		var parent := area.get_parent()
		if parent and parent.is_in_group("enemies"):
			if parent.has_method("take_fire_damage"):
				parent.take_fire_damage(damage_to_deal)
			elif parent.has_method("take_burn_damage"):
				parent.take_burn_damage(damage_to_deal)
			elif parent.has_method("take_damage"):
				parent.take_damage(damage_to_deal)

func _stop_attack() -> void:
	if not _is_attacking:
		return
	_is_attacking = false
	flame_cone.monitoring = false
	flame_cone.visible = false
	_set_particles_emitting(false)

func _is_modal_active() -> bool:
	var modal := get_tree().get_first_node_in_group("investigation_modal")
	if modal and modal.has_method("is_investigation_active"):
		return modal.is_investigation_active()
	return false
