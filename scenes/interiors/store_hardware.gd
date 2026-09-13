extends Node2D

## Harborvale Hardware & Tool Supply Interior.

const SCENE_TOWN: String = "res://scenes/world/town_map.tscn"

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var modal: CanvasLayer = $InvestigationModal
@onready var inventory_menu: CanvasLayer = $InventoryMenu
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

# Interactables
@onready var manifest_int: Area2D = $RegisterCounter/HardwareManifest/Interactable
@onready var tool_notes_int: Area2D = $ToolRack/Interactable
@onready var fuel_tank_int: Area2D = $FuelStation/Interactable
@onready var exit_door_int: Area2D = $ExitDoor/Interactable

const HARDWARE_MANIFEST_TEXT: String = (
	"HARBORVALE HARDWARE & SUPPLY — EXPEDITE LOG\n\n" +
	"CLIENT: St. Anthony Quarantine Wing / Sub-Level B\n" +
	"ORDERS: 40x Heavy Industrial Gas Cylinders, 6x High-Pressure Torch Nozzles, 12x Steel Containment Cages.\n\n" +
	"MEMO: 'Delivery driver noted chemical smell and rhythmic thumping from the quarantine basement. Advised not to return without full respiratory gear.'"
)

const TOOL_NOTES_TEXT: String = (
	"MAINTENANCE LOG: BURNER MODIFICATION\n\n" +
	"Thermal ignition at 1200°C is the only verified method to rupture the outer chitin of mutated egg specimens. " +
	"Standard kinetic weapons merely aggravate the embryos."
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

	manifest_int.interacted.connect(_on_manifest_interacted)
	tool_notes_int.interacted.connect(_on_tool_notes_interacted)
	fuel_tank_int.interacted.connect(_on_fuel_tank_interacted)
	exit_door_int.interacted.connect(_on_exit_door_interacted)

	canvas_modulate.color = Color(0.70, 0.65, 0.58, 1.0)
	hud.show_alert("HARBORVALE HARDWARE & TOOL SUPPLY")

func _on_manifest_interacted(_p: Node2D) -> void:
	modal.open_clue("HARDWARE WORK ORDER - SUB-LEVEL B", HARDWARE_MANIFEST_TEXT, "hardware_manifest")

func _on_tool_notes_interacted(_p: Node2D) -> void:
	modal.open_clue("BURNER MAINTENANCE LOG", TOOL_NOTES_TEXT, "burner_notes")

func _on_fuel_tank_interacted(_p: Node2D) -> void:
	if not fuel_collected:
		fuel_collected = true
		player.fuel = minf(player.max_fuel, player.fuel + 60.0)
		hud.update_fuel(player.fuel, player.max_fuel)
		hud.show_alert("+60 BURNER FUEL COLLECTED")
		$FuelStation.visible = false

func _on_exit_door_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.town_player_pos = Vector2(-250, 380) # Outside Hardware Store
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", Color(0.0, 0.0, 0.0, 1.0), 0.4)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(SCENE_TOWN)
	)
