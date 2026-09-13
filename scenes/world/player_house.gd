extends Node2D

## Player House & Opening Tutorial Scene for EGG: RECKONING.
## Player wakes up in their detective apartment, follows the tutorial, reads the Friend's Letter,
## collects the Tactical Torch & Incendiary Burner, and departs into Harborvale.

const SCENE_TOWN: String = "res://scenes/world/town_map.tscn"

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var modal: CanvasLayer = $InvestigationModal
@onready var inventory_menu: CanvasLayer = $InventoryMenu
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

# House Interactables
@onready var letter_int: Area2D = $Desk/FriendsLetter/Interactable
@onready var bookshelf_int: Area2D = $Bookshelf/Interactable
@onready var wardrobe_int: Area2D = $Wardrobe/Interactable
@onready var tv_int: Area2D = $TV/Interactable
@onready var fridge_int: Area2D = $Refrigerator/Interactable
@onready var window_int: Area2D = $Window/Interactable
@onready var storage_int: Area2D = $StorageCloset/Interactable
@onready var front_door_int: Area2D = $FrontDoor/Interactable

const FRIENDS_LETTER_TEXT: String = (
	"To whoever finds this...\n\n" +
	"I don't know how much time I have left.\n" +
	"Something is terribly wrong with the eggs distributed across Harborvale.\n\n" +
	"People are getting sick. The hospitals are overflowing with calcified patients. " +
	"Everyone thinks it's some kind of airborne plague or curse.\n\n" +
	"But I found the truth: The eggs are alive, parasitic, and hatching from the inside.\n\n" +
	"THEY CAN BE DESTROYED BY FIRE.\n\n" +
	"I locked an Incendiary Burner and extra fuel canisters inside your storage closet. " +
	"Take them and protect yourself.\n\n" +
	"If you're reading this, don't trust the eggs.\n" +
	"And whatever you do...\n\n" +
	"DO NOT GO NEAR THE HOSPITAL ALONE.\n\n" +
	"— Detective Vance"
)

const BOOKSHELF_TEXT: String = (
	"DETECTIVE TEXTBOOKS & TOXICOLOGY NOTES\n\n" +
	"A collection of forensic volumes. Several marked bookmarks point to chapters on " +
	"rapid biological calcification, parasitic incubation vectors, and extreme vulnerability to thermal heat."
)

const TV_TEXT: String = (
	"EMERGENCY BROADCAST RECEIVER\n\n" +
	"White static hisses through the speaker. The Harborvale municipal emergency channel has been silent since midnight."
)

const FRIDGE_TEXT: String = (
	"REFRIGERATOR\n\n" +
	"Completely emptied. Canned rations are gone, and a carton of valley eggs sits crushed in the trash bin below."
)

const WINDOW_TEXT: String = (
	"WINDOW TO HARBORVALE\n\n" +
	"You look outside into the cold dusk mist. The streets are completely abandoned and choked with unnatural silence. " +
	"Distant flickering streetlights illuminate scattered debris."
)

var _tutorial_step: int = 0
var _moved_distance: float = 0.0
var _initial_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Camera setup
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		cam.zoom = Vector2(1.5, 1.5)
		cam.limit_left   = -370
		cam.limit_top    = -240
		cam.limit_right  =  370
		cam.limit_bottom =  240

	# Connect player signals to HUD
	player.health_changed.connect(hud.update_health)
	player.fuel_changed.connect(hud.update_fuel)
	hud.update_health(player.health, player.max_health)
	hud.update_fuel(player.fuel, player.max_fuel)

	# Connect house interactables
	letter_int.interacted.connect(_on_letter_interacted)
	bookshelf_int.interacted.connect(_on_bookshelf_interacted)
	wardrobe_int.interacted.connect(_on_wardrobe_interacted)
	tv_int.interacted.connect(_on_tv_interacted)
	fridge_int.interacted.connect(_on_fridge_interacted)
	window_int.interacted.connect(_on_window_interacted)
	storage_int.interacted.connect(_on_storage_interacted)
	front_door_int.interacted.connect(_on_front_door_interacted)

	# Connect modal closed
	modal.modal_closed.connect(_on_modal_closed)

	# Wake-up fade in & tutorial sequence
	canvas_modulate.color = Color(0.0, 0.0, 0.0, 1.0)
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", Color(0.7, 0.65, 0.75, 1.0), 1.6)
	
	_initial_pos = player.global_position
	
	# Initial tutorial prompt
	hud.show_alert("W A S D — Move  |  Hold SHIFT — Sprint")

func _process(_delta: float) -> void:
	if _tutorial_step == 0:
		if player.global_position.distance_to(_initial_pos) > 40.0:
			_tutorial_step = 1
			hud.show_alert("Press [E] to investigate objects in the room.")
	elif _tutorial_step == 1:
		if player.global_position.distance_to(letter_int.global_position) < 80.0:
			_tutorial_step = 2
			hud.show_alert("Something is wrong... Read the handwritten note on your desk.")

func _on_letter_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.friends_letter_read = true
		gs.storage_room_unlocked = true
	
	modal.open_letter("LETTER FROM DETECTIVE VANCE", FRIENDS_LETTER_TEXT, "friends_letter")
	
	if _tutorial_step < 3:
		_tutorial_step = 3

func _on_wardrobe_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs and not gs.has_torch:
		gs.has_torch = true
		gs.torch_enabled = true
		var player_node := get_tree().get_first_node_in_group("player")
		if player_node:
			if player_node.has_method("set_torch_enabled"):
				player_node.set_torch_enabled(true)
			elif player_node.has_node("Nozzle/Flashlight"):
				player_node.get_node("Nozzle/Flashlight").enabled = true
			elif player_node.has_node("Flashlight"):
				player_node.get_node("Flashlight").enabled = true
		hud.show_alert("TACTICAL FLASHLIGHT ACQUIRED — Press [F] to toggle light.")
		wardrobe_int.prompt_text = "Wardrobe (Flashlight Taken)"
		var sm := get_node_or_null("/root/SoundManager")
		if sm and sm.has_method("play_pickup"):
			sm.play_pickup()
	else:
		modal.open_clue("WARDROBE", "A heavy field coat and backup emergency gear.", "wardrobe")

func _on_bookshelf_interacted(_p: Node2D) -> void:
	modal.open_clue("BOOKSHELF", BOOKSHELF_TEXT, "bookshelf")

func _on_tv_interacted(_p: Node2D) -> void:
	modal.open_clue("STATIC TELEVISION", TV_TEXT, "tv")

func _on_fridge_interacted(_p: Node2D) -> void:
	modal.open_clue("REFRIGERATOR", FRIDGE_TEXT, "fridge")

func _on_window_interacted(_p: Node2D) -> void:
	modal.open_clue("BEDROOM WINDOW", WINDOW_TEXT, "window")

func _on_storage_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs and not gs.friends_letter_read:
		hud.show_alert("Locked. Read the letter on your desk first.")
		return
		
	if gs and not gs.has_burner:
		gs.has_burner = true
		gs.fuel_canisters += 2
		gs.front_door_unlocked = true
		front_door_int.prompt_text = "Leave House (Enter Harborvale)"
		storage_int.prompt_text = "Storage Closet (Emptied)"
		
		hud.show_alert("INCENDIARY BURNER & 2 FUEL CANISTERS ACQUIRED!\nLeft Click — Fire | Mouse — Aim | [Tab] — Inventory")
		
		var sm := get_node_or_null("/root/SoundManager")
		if sm and sm.has_method("play_pickup"):
			sm.play_pickup()
			
		_tutorial_step = 4
	else:
		modal.open_clue("STORAGE CLOSET", "Supply closet emptied. Incendiary weapon equipped.", "storage")

func _on_front_door_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs and not gs.has_burner:
		hud.show_alert("You must equip the burner from the storage closet before going outside!")
		return
		
	# Transition outside into Harborvale
	if gs:
		gs.town_player_pos = Vector2(-850, -350)
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", Color(0.0, 0.0, 0.0, 1.0), 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(SCENE_TOWN)
	)

func _on_modal_closed(topic: String) -> void:
	if topic == "friends_letter":
		storage_int.prompt_text = "Open Storage Closet (Retrieve Burner)"
		hud.show_alert("Search the storage closet on the right for the Incendiary Burner.")
