extends Node2D

## FreshMart Grocery Store Interior.

const SCENE_TOWN: String = "res://scenes/world/town_map.tscn"

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var modal: CanvasLayer = $InvestigationModal
@onready var inventory_menu: CanvasLayer = $InventoryMenu
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

# Interactables
@onready var invoice_int: Area2D = $RegisterCounter/ShopInvoice/Interactable
@onready var egg_crates_int: Area2D = $AisleShelf1/Interactable
@onready var exit_door_int: Area2D = $ExitDoor/Interactable

const SHOP_INVOICE_TEXT: String = (
	"HARBORVALE GENERAL STORE — SUPPLY INVOICE\n\n" +
	"SUPPLIER: St. Anthony Sub-Level Agro-Research (Egg Society)\n" +
	"BATCH #804-E: 'Enriched Protein Specimen'\n\n" +
	"NOTE: All shipments marked with purple seal must be distributed immediately to residential grocery stores. " +
	"Under no circumstances should boxes be opened or candled under ultraviolet light."
)

const EGG_CRATES_TEXT: String = (
	"CONTAMINATED EGG CRATES (BATCH #804-E)\n\n" +
	"Hundreds of eggs stamped with deep purple cult sigils. " +
	"A sub-audible hum resonates from the shells. Several cartons have begun leaking a dark, gelatinous enzyme."
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

	invoice_int.interacted.connect(_on_invoice_interacted)
	egg_crates_int.interacted.connect(_on_egg_crates_interacted)
	exit_door_int.interacted.connect(_on_exit_door_interacted)

	canvas_modulate.color = Color(0.68, 0.62, 0.72, 1.0)
	hud.show_alert("HARBORVALE FRESHMART GROCERY")

func _on_invoice_interacted(_p: Node2D) -> void:
	modal.open_clue("COMMERCIAL LEDGER - GENERAL STORE", SHOP_INVOICE_TEXT, "shop_invoice")

func _on_egg_crates_interacted(_p: Node2D) -> void:
	modal.open_clue("CONTAMINATED BATCH #804-E", EGG_CRATES_TEXT, "grocery_eggs")

func _on_exit_door_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.town_player_pos = Vector2(-850, 380) # Outside Grocery Store
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", Color(0.0, 0.0, 0.0, 1.0), 0.4)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(SCENE_TOWN)
	)
