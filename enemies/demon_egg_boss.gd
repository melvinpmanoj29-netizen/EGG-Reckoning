extends CharacterBody2D

## Demon Egg Boss (Specimen Zero) — 3-Phase Final Boss.
## Features 3 distinct attacks with readable warning telegraphs:
## 1. Corrupted Egg Bomb with ground impact warning.
## 2. Demonic Projectile hellfire spread.
## 3. Altar Minion Summoning at room corners (never on player).
## Phase 3 exposes the vulnerable core for the Incendiary Burner.

signal defeated
signal phase_changed(new_phase: int)
signal health_changed(current: float, max_val: float)

const MINION_SCENE := preload("res://enemies/minion_egg.tscn")
const DEMON_MINION_SCENE := preload("res://enemies/demon_egg_minion.tscn")
const EGG_BOMB_SCENE := preload("res://enemies/boss_egg_bomb.tscn")
const PROJECTILE_SCENE := preload("res://enemies/poison_projectile.tscn")

const ALTAR_SPAWN_POINTS: Array[Vector2] = [
	Vector2(-450, -300),
	Vector2(450, -300),
	Vector2(-450, 300),
	Vector2(450, 300)
]

@export var max_health: float = 220.0
@export var contact_damage: float = 20.0

var health: float = 220.0
var current_phase: int = 1
var _phase_timer: float = 12.0
var _contact_timer: float = 0.0

var _bomb_timer: float = 3.5
var _projectile_timer: float = 2.0
var _summon_timer: float = 7.0
var _pulse_timer: float = 0.0

var _target_player: Node2D = null
var _is_dying: bool = false
var _is_telegraphing: bool = false

@onready var boss_sprite: Sprite2D = $BossSprite
@onready var aura_light: PointLight2D = $BossAuraLight
@onready var hit_box: Area2D = $HitBox
@onready var phase_particles: CPUParticles2D = $PhaseParticles
@onready var death_shards: CPUParticles2D = $DeathShards

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	current_phase = 1
	_phase_timer = 12.0
	_bomb_timer = 3.0
	_summon_timer = 6.0

	var hud := _get_hud()
	if hud and hud.has_method("show_boss_bar"):
		hud.show_boss_bar("DEMON EGG — SPECIMEN ZERO")
		hud.update_boss_bar(health, max_health)

func _physics_process(delta: float) -> void:
	if _is_dying:
		return

	if _target_player == null or not is_instance_valid(_target_player):
		_target_player = get_tree().get_first_node_in_group("player")
		if _target_player == null:
			return

	_pulse_timer += delta
	_update_pulse()

	match current_phase:
		1:
			_phase1_behavior(delta)
		2:
			_phase2_behavior(delta)
		3:
			_phase3_behavior(delta)

	# Contact damage with player
	if _contact_timer > 0.0:
		_contact_timer -= delta
	if _contact_timer <= 0.0:
		for body in hit_box.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(contact_damage)
				_contact_timer = 1.0
				break

func _phase1_behavior(delta: float) -> void:
	# Keep moderate distance
	var dist := global_position.distance_to(_target_player.global_position)
	if dist < 260.0:
		var away_dir := (global_position - _target_player.global_position).normalized()
		velocity = away_dir * 60.0
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	_bomb_timer -= delta
	if _bomb_timer <= 0.0:
		_bomb_timer = 4.2
		_telegraph_and_launch_egg_bomb()

	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = 8.5
		_summon_minions_at_altars(1, false)

	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_transition_to_phase(2)

func _phase2_behavior(delta: float) -> void:
	# Aggressive chase & dual projectile pressure
	var to_player := (_target_player.global_position - global_position).normalized()
	velocity = to_player * 100.0
	move_and_slide()

	_projectile_timer -= delta
	if _projectile_timer <= 0.0:
		_projectile_timer = 3.2
		_fire_demonic_projectiles()

	_bomb_timer -= delta
	if _bomb_timer <= 0.0:
		_bomb_timer = 3.5
		_telegraph_and_launch_egg_bomb()

	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = 7.5
		_summon_minions_at_altars(2, true)

	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_transition_to_phase(3)

func _phase3_behavior(delta: float) -> void:
	# Vulnerable frantic phase
	velocity = Vector2.ZERO

	_projectile_timer -= delta
	if _projectile_timer <= 0.0:
		_projectile_timer = 2.4
		_fire_demonic_projectiles()

	_bomb_timer -= delta
	if _bomb_timer <= 0.0:
		_bomb_timer = 2.8
		_telegraph_and_launch_egg_bomb()

func _transition_to_phase(new_phase: int) -> void:
	current_phase = new_phase
	phase_changed.emit(current_phase)

	if phase_particles:
		phase_particles.restart()
		phase_particles.emitting = true

	var hud := _get_hud()
	match current_phase:
		2:
			_phase_timer = 14.0
			_bomb_timer = 2.5
			_projectile_timer = 1.5
			if hud and hud.has_method("show_alert"):
				hud.show_alert("PHASE 2: SPECIMEN ZERO UNLEASHES DEMONIC FIRES!")
			_summon_minions_at_altars(2, true)
		3:
			if hud and hud.has_method("show_alert"):
				hud.show_alert("PHASE 3: SHELL SHATTERED! BURN THE VULNERABLE CORE!")
			_summon_minions_at_altars(1, false)

func _update_pulse() -> void:
	var pulse_speed := 2.0 + float(current_phase) * 2.0
	var pulse := (sin(_pulse_timer * pulse_speed) + 1.0) * 0.5
	var base_scale := 0.55 + pulse * 0.04
	boss_sprite.scale = Vector2(base_scale, base_scale)

	match current_phase:
		1:
			aura_light.energy = 1.2 + pulse * 0.4
			boss_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		2:
			aura_light.energy = 1.8 + pulse * 0.8
			boss_sprite.modulate = Color(1.2, 0.6 + pulse * 0.4, 0.6, 1.0)
		3:
			aura_light.energy = 2.5 + pulse * 1.2
			boss_sprite.modulate = Color(1.5, 0.3 + pulse * 0.7, 0.15, 1.0)

# ---------------------------------------------------------
# BOSS ATTACK 1: EGG BOMB (with warning telegraph)
# ---------------------------------------------------------
func _telegraph_and_launch_egg_bomb() -> void:
	if _target_player == null or not is_instance_valid(_target_player):
		return

	# Flash telegraph
	modulate = Color(2.0, 0.2, 0.2, 1.0)
	var t := create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.35)
	t.tween_callback(func():
		if _is_dying or _target_player == null: return
		var bomb := EGG_BOMB_SCENE.instantiate() as Node2D
		bomb.global_position = global_position
		bomb.start_pos = global_position
		bomb.target_pos = _target_player.global_position
		var parent := get_parent()
		if parent:
			parent.add_child(bomb)
	)

# ---------------------------------------------------------
# BOSS ATTACK 2: DEMONIC PROJECTILES (Hellfire Spread)
# ---------------------------------------------------------
func _fire_demonic_projectiles() -> void:
	if _target_player == null or not is_instance_valid(_target_player):
		return

	var parent := get_parent()
	if parent == null:
		return

	var base_dir := (_target_player.global_position - global_position).normalized()
	var angles: Array[float] = []
	if current_phase == 2:
		angles = [-0.35, 0.0, 0.35]
	else:
		angles = [-0.5, -0.25, 0.0, 0.25, 0.5]

	for offset_angle in angles:
		var proj := PROJECTILE_SCENE.instantiate() as Area2D
		proj.global_position = global_position + base_dir.rotated(offset_angle) * 35.0
		if "direction" in proj:
			proj.direction = base_dir.rotated(offset_angle)
		proj.rotation = base_dir.rotated(offset_angle).angle()
		proj.modulate = Color(1.8, 0.3, 0.2, 1.0) # Demonic red tint
		parent.add_child(proj)

# ---------------------------------------------------------
# BOSS ATTACK 3: ALTAR MINION SUMMONING
# ---------------------------------------------------------
func _summon_minions_at_altars(count: int, use_demon: bool = false) -> void:
	var parent := get_parent()
	if parent == null:
		return

	for i in range(count):
		var altar_pos := ALTAR_SPAWN_POINTS[randi() % ALTAR_SPAWN_POINTS.size()]
		var minion: Node2D
		if use_demon and DEMON_MINION_SCENE:
			minion = DEMON_MINION_SCENE.instantiate() as Node2D
		else:
			minion = MINION_SCENE.instantiate() as Node2D
		minion.global_position = altar_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		parent.add_child(minion)

func take_burn_damage(amount: float) -> void:
	take_fire_damage(amount)

func take_damage(amount: float) -> void:
	take_fire_damage(amount)

func take_fire_damage(amount: float) -> void:
	if _is_dying:
		return

	if current_phase < 3:
		# Immune during Phase 1 & 2
		var t := create_tween()
		t.tween_property(self, "modulate", Color(0.5, 0.5, 1.8, 1.0), 0.05)
		t.tween_property(self, "modulate", Color.WHITE, 0.1)
		return

	health -= amount
	health_changed.emit(max(0.0, health), max_health)
	modulate = Color(1.6, 0.3, 0.1, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

	var hud := _get_hud()
	if hud and hud.has_method("update_boss_bar"):
		hud.update_boss_bar(max(0.0, health), max_health)

	if health <= 0.0:
		_die()

func _die() -> void:
	if _is_dying:
		return
	_is_dying = true

	var hud := _get_hud()
	if hud and hud.has_method("hide_boss_bar"):
		hud.hide_boss_bar()
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.boss_defeated = true

	# Massive death explosion
	if death_shards:
		death_shards.emitting = true
	boss_sprite.visible = false
	aura_light.enabled = false
	hit_box.set_deferred("monitoring", false)

	defeated.emit()

	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(queue_free)

func _get_hud() -> Node:
	return get_tree().get_first_node_in_group("hud")
