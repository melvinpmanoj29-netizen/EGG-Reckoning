extends Node2D

## Valley Gas & Fuel Service Interior.

const SCENE_TOWN: String = "res://scenes/world/town_map.tscn"

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var modal: CanvasLayer = $InvestigationModal
@onready var inventory_menu: CanvasLayer = $InventoryMenu
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

# Interactables
@onready var dispatch_log_int: Area2D = $RegisterCounter/DispatchLog/Interactable
@onready var emergency_radio_int: Area2D = $RadioDesk/Interactable
@onready var fuel_tank_int: Area2D = $FuelStation/Interactable
@onready var exit_door_int: Area2D = $ExitDoor/Interactable

const DISPATCH_LOG_TEXT: String = (
	"VALLEY GAS STATION — NIGHT DISPATCH LOG\n\n" +
	"02:15 AM: Emergency convoys requisitioned entire underground diesel reservoir.\n" +
	"03:40 AM: Sheriff department blocked main highway bridge. Directed all heavy transport toward St. Anthony Hospital underground vault.\n" +
	"04:10 AM: Power grid failed. Strange sulfurous fog creeping in from the north."
)

const EMERGENCY_RADIO_TEXT: String = (
	"EMERGENCY FREQUENCY RADIO BROADCAST\n\n" +
	"...[Static]... 'Harborvale Sector 4 quarantine compromised. " +
	"The biological mass in the hospital sub-level has breached containment. " +
	"All remaining civilian survivors must stay indoors. Do not approach the medical facility.' ...[Static]..."
)

var fuel_collected: bool = false

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

	dispatch_log_int.interacted.connect(_on_dispatch_log_interacted)
	emergency_radio_int.interacted.connect(_on_emergency_radio_interacted)
	fuel_tank_int.interacted.connect(_on_fuel_tank_interacted)
	exit_door_int.interacted.connect(_on_exit_door_interacted)

	canvas_modulate.color = Color(0.60, 0.64, 0.70, 1.0)
	hud.show_alert("VALLEY GAS & FUEL SERVICE")

func _on_dispatch_log_interacted(_p: Node2D) -> void:
	modal.open_clue("VALLEY GAS DISPATCH LOG", DISPATCH_LOG_TEXT, "gas_dispatch_log")

func _on_emergency_radio_interacted(_p: Node2D) -> void:
	modal.open_clue("EMERGENCY RADIO TRANSCRIPT", EMERGENCY_RADIO_TEXT, "emergency_radio")

func _on_fuel_tank_interacted(_p: Node2D) -> void:
	if not fuel_collected:
		fuel_collected = true
		player.fuel = minf(player.max_fuel, player.fuel + 50.0)
		hud.update_fuel(player.fuel, player.max_fuel)
		hud.show_alert("+50 BURNER FUEL COLLECTED")
		$FuelStation.visible = false

func _on_exit_door_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.town_player_pos = Vector2(900, 380) # Outside Gas Station
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", Color(0.0, 0.0, 0.0, 1.0), 0.4)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(SCENE_TOWN)
	)
