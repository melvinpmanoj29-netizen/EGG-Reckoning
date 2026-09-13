extends Node2D

## CarePlus Pharmacy Interior.

const SCENE_TOWN: String = "res://scenes/world/town_map.tscn"

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var modal: CanvasLayer = $InvestigationModal
@onready var inventory_menu: CanvasLayer = $InventoryMenu
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

# Interactables
@onready var tox_record_int: Area2D = $Counter/ToxicologyRecord/Interactable
@onready var med_shelf_int: Area2D = $MedicineCabinet/Interactable
@onready var exit_door_int: Area2D = $ExitDoor/Interactable

const PHARMACY_RECORD_TEXT: String = (
	"CAREPLUS PHARMACY — TOXICOLOGY & PRESCRIPTION LEDGER\n\n" +
	"PATIENT SYMPTOM LOG:\n" +
	"- Severe gastrointestinal pain, rapid epidermal ossification, pulse rhythm anomalies.\n" +
	"- Standard antitoxins and antibiotics completely ineffective against parasitic egg tissue.\n\n" +
	"NOTE: Hospital quarantine teams confiscated all industrial flame equipment. Patients relocated to St. Anthony Sub-Level Quarantine Vault."
)

const MED_SHELF_TEXT: String = (
	"PHARMACY DISPENSARY\n\n" +
	"Most sedative and painkiller bottles are empty. Medical supplies were looted during the initial evacuation."
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

	tox_record_int.interacted.connect(_on_tox_record_interacted)
	med_shelf_int.interacted.connect(_on_med_shelf_interacted)
	exit_door_int.interacted.connect(_on_exit_door_interacted)

	canvas_modulate.color = Color(0.65, 0.65, 0.75, 1.0)
	hud.show_alert("CAREPLUS PHARMACY & CLINIC")

func _on_tox_record_interacted(_p: Node2D) -> void:
	modal.open_clue("PHARMACY CLINICAL LEDGER", PHARMACY_RECORD_TEXT, "pharmacy_ledger")

func _on_med_shelf_interacted(_p: Node2D) -> void:
	modal.open_clue("MEDICINE CABINET", MED_SHELF_TEXT, "pharmacy_shelf")

func _on_exit_door_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.town_player_pos = Vector2(-480, 380) # Outside Pharmacy
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", Color(0.0, 0.0, 0.0, 1.0), 0.4)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(SCENE_TOWN)
	)
