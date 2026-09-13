extends Node2D

## Underground Lair / Egg Society Boss Arena
## Contains the 3-phase Demon Egg Boss, investigation clues, resources, and arena bounds.

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var modal: CanvasLayer = $InvestigationModal
@onready var boss: CharacterBody2D = $DemonEggBoss
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var permanent_retry_button: Button = $BossRetryLayer/Margin/RetryBossButton

@onready var clue_altar_int: Area2D = $Clues/AltarClue/Interactable
@onready var clue_research_int: Area2D = $Clues/ResearchClue/Interactable

const CLUE_ALTAR_TEXT: String = (
	"EGG SOCIETY CULT CODEX\n\n" +
	"'We gave our bodies to nourish Specimen Zero. " +
	"In its initial waking cycle, the shell repels all heat. " +
	"Do not despair when fire does not bite! " +
	"Survive its frenzy. When its dark power peaks in Phase 3, its carapace will shatter... " +
	"and only then can it be cleansed with fire!'"
)

const CLUE_RESEARCH_TEXT: String = (
	"DR. VANE'S FINAL NOTE\n\n" +
	"'The egg minions are mere drones spawned to distract. " +
	"Conserve your fuel for the moment the boss core exposes itself! " +
	"Burn it relentlessly when the shield breaks!'"
)

func _ready() -> void:
	# Camera bounds for the boss arena
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		cam.limit_left = -700
		cam.limit_top = -500
		cam.limit_right = 700
		cam.limit_bottom = 500

	# Connect player signals
	player.health_changed.connect(hud.update_health)
	player.fuel_changed.connect(hud.update_fuel)
	player.died.connect(_on_player_died)
	permanent_retry_button.pressed.connect(_on_retry_boss_pressed)

	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.boss_retry_available = false

	# Initial HUD state
	hud.update_health(player.health, player.max_health)
	hud.update_fuel(player.fuel, player.max_fuel)

	# Connect clues
	if clue_altar_int:
		clue_altar_int.interacted.connect(_on_altar_clue_interacted)
	if clue_research_int:
		clue_research_int.interacted.connect(_on_research_clue_interacted)

	# Connect boss signals
	if boss:
		boss.phase_changed.connect(_on_boss_phase_changed)
		boss.defeated.connect(_on_boss_defeated)
		boss.health_changed.connect(hud.update_boss_bar)
		hud.show_boss_bar("DEMON EGG — SPECIMEN ZERO")
		hud.update_boss_bar(boss.health, boss.max_health)

	# Atmospheric intro & Boss Music
	canvas_modulate.color = Color(0.12, 0.08, 0.16, 1.0)
	hud.show_alert("EGG SOCIETY LAIR — SPECIMEN ZERO")

	var sm := get_node_or_null("/root/SoundManager")
	if sm:
		if sm.has_method("start_boss_music"):
			sm.start_boss_music()
		elif sm.has_method("play_stinger"):
			sm.play_stinger()

func _on_altar_clue_interacted(_p: Node2D) -> void:
	modal.open_clue("THE INNER SANCTUM — CULT CODEX", CLUE_ALTAR_TEXT, "altar")

func _on_research_clue_interacted(_p: Node2D) -> void:
	modal.open_clue("RESEARCH DESK — BURNER PROTOCOL", CLUE_RESEARCH_TEXT, "research")

func _on_boss_phase_changed(new_phase: int) -> void:
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("set_boss_phase"):
		sm.set_boss_phase(new_phase)
	elif sm and sm.has_method("play_stinger"):
		sm.play_stinger()

	match new_phase:
		2:
			# Atmosphere darkens, fog thickens
			var tween := create_tween()
			tween.tween_property(canvas_modulate, "color", Color(0.06, 0.03, 0.08, 1.0), 1.5)
			hud.show_alert("THE DEMON EGG ENRAGES — SURVIVE THE ONSLAUGHT!")
		3:
			# Shell breaks — vulnerable
			var tween := create_tween()
			tween.tween_property(canvas_modulate, "color", Color(0.18, 0.08, 0.08, 1.0), 0.8)
			hud.show_alert("THE SHELL CRACKED! BURN THE EGG NOW!")

func _on_boss_defeated() -> void:
	permanent_retry_button.disabled = true
	permanent_retry_button.hide()
	hud.show_alert("THE DEMON EGG SHATTERS!")
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_boss_death"):
		sm.play_boss_death()
	elif sm and sm.has_method("play_stinger"):
		sm.play_stinger()

	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/story/ending.tscn")
	)

func _on_retry_boss_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/boss_room.tscn")

func _on_player_died() -> void:
	hud.show_alert("CRITICAL VITALS — YOU HAVE PERISHED")
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.boss_retry_available = true
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/menus/game_over.tscn")
	)
