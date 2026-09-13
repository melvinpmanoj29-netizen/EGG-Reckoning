extends Node2D

## Henderson Residence Interior.

const SCENE_TOWN: String = "res://scenes/world/town_map.tscn"

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var modal: CanvasLayer = $InvestigationModal
@onready var inventory_menu: CanvasLayer = $InventoryMenu
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

# Interactables
@onready var diary_int: Area2D = $Desk/HendersonDiary/Interactable
@onready var bed_int: Area2D = $BedArea/Interactable
@onready var fridge_int: Area2D = $Refrigerator/Interactable
@onready var exit_door_int: Area2D = $ExitDoor/Interactable

const HENDERSON_DIARY_TEXT: String = (
	"HENDERSON FAMILY DIARY (FINAL ENTRY)\n\n" +
	"'October 14th — It started with the eggs we bought from the valley farm. " +
	"Arthur felt a sharp burning in his chest after breakfast. By nightfall, his skin was pale, cold, and hard as porcelain.\n\n" +
	"The noises inside the pantry won't stop. It sounds like something skittering against the wood. " +
	"We are barricading the bedroom. If anyone finds this... do not consume any poultry or eggs. They are not food anymore.'"
)

const BED_CALCIFIED_TEXT: String = (
	"HENDERSON BEDROOM OBSERVATION\n\n" +
	"The bed sheets are torn and encrusted with calcified porcelain-like biological fragments. " +
	"Arthur Henderson was clearly quarantined here before the infection completely overtook his physiology."
)

const FRIDGE_TEXT: String = (
	"HENDERSON PANTRY\n\n" +
	"A carton of purple-sealed valley eggs sits inside. Several shells have cracked open from the inside out."
)

func _ready() -> void:
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		cam.zoom = Vector2(1.5, 1.5)
		cam.limit_left   = -370
		cam.limit_top    = -240
		cam.limit_right  =  370
		cam.limit_bottom =  240

	player.health_changed.connect(hud.update_health)
	player.fuel_changed.connect(hud.update_fuel)
	hud.update_health(player.health, player.max_health)
	hud.update_fuel(player.fuel, player.max_fuel)

	diary_int.interacted.connect(_on_diary_interacted)
	bed_int.interacted.connect(_on_bed_interacted)
	fridge_int.interacted.connect(_on_fridge_interacted)
	exit_door_int.interacted.connect(_on_exit_door_interacted)

	canvas_modulate.color = Color(0.65, 0.6, 0.72, 1.0)
	hud.show_alert("HENDERSON RESIDENCE — 14 Elm Street")

func _on_diary_interacted(_p: Node2D) -> void:
	modal.open_clue("RESIDENTIAL ARCHIVE - HENDERSON RESIDENCE", HENDERSON_DIARY_TEXT, "henderson_diary")

func _on_bed_interacted(_p: Node2D) -> void:
	modal.open_clue("CALCIFIED BEDROOM", BED_CALCIFIED_TEXT, "henderson_bed")

func _on_fridge_interacted(_p: Node2D) -> void:
	modal.open_clue("PANTRY STORAGE", FRIDGE_TEXT, "henderson_pantry")

func _on_exit_door_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.town_player_pos = Vector2(-850, -380) # Outside Henderson House
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", Color(0.0, 0.0, 0.0, 1.0), 0.4)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(SCENE_TOWN)
	)
