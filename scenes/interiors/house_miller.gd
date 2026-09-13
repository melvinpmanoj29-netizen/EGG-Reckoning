extends Node2D

## Miller Residence (Victim House #2).

const SCENE_TOWN: String = "res://scenes/world/town_map.tscn"

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var modal: CanvasLayer = $InvestigationModal
@onready var inventory_menu: CanvasLayer = $InventoryMenu
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

# Interactables
@onready var newspaper_int: Area2D = $Table/Newspaper/Interactable
@onready var radio_int: Area2D = $Radio/Interactable
@onready var exit_door_int: Area2D = $ExitDoor/Interactable

const MILLER_NEWSPAPER_TEXT: String = (
	"HARBORVALE HERALD — SPECIAL EMERGENCY EDITION\n\n" +
	"'UNEXPLAINED CALCIFICATION OUTBREAK SPREADS THROUGH DISTRICT 4'\n\n" +
	"City officials urge all citizens to surrender commercial poultry products to St. Anthony Hospital for biohazard disposal. " +
	"Survivors report scratching inside walls and violent internal symptoms. Evacuation convoy departs via East Highway."
)

const RADIO_TEXT: String = (
	"BATTERY-POWERED SHORTWAVE RADIO\n\n" +
	"A repeating emergency broadcast loops through bursts of static: '...Do not eat the marked eggs... quarantine breached at St. Anthony... seek shelter...'"
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

	newspaper_int.interacted.connect(_on_newspaper_interacted)
	radio_int.interacted.connect(_on_radio_interacted)
	exit_door_int.interacted.connect(_on_exit_door_interacted)

	canvas_modulate.color = Color(0.62, 0.58, 0.7, 1.0)
	hud.show_alert("MILLER RESIDENCE — 22 Elm Street")

func _on_newspaper_interacted(_p: Node2D) -> void:
	modal.open_clue("NEWSPAPER - HARBORVALE HERALD", MILLER_NEWSPAPER_TEXT, "miller_newspaper")

func _on_radio_interacted(_p: Node2D) -> void:
	modal.open_clue("SHORTWAVE EMERGENCY RADIO", RADIO_TEXT, "miller_radio")

func _on_exit_door_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.town_player_pos = Vector2(-550, -380) # Outside Miller House
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", Color(0.0, 0.0, 0.0, 1.0), 0.4)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(SCENE_TOWN)
	)
