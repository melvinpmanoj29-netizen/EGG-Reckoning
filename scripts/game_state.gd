extends Node

## Global game state singleton.
## Persists between scene transitions via autoload.

var selected_character: String = "boy"  ## "boy" or "girl"

## Opening & Tutorial state
var has_burner: bool = false
var has_torch: bool = false
var torch_enabled: bool = true
var friends_letter_read: bool = false
var storage_room_unlocked: bool = false
var front_door_unlocked: bool = false
var house_investigated_count: int = 0

## Inventory items
var medkits: int = 1
var fuel_canisters: int = 0
var key_items: Array[String] = []
var town_player_pos: Vector2 = Vector2.ZERO

## Day 2 story & world state
var is_night: bool = false
var medical_records_read: bool = false
var cctv_inspected: bool = false
var demon_egg_discovered: bool = false
var minions_defeated: int = 0
var initial_hospital_wave_started: bool = false
var initial_hospital_wave_defeated: int = 0
var initial_hospital_wave_completed: bool = false

## Day 3 state
var entered_lair: bool = false
var boss_defeated: bool = false
var boss_retry_available: bool = false

## Player runtime stats (retained across sub-areas if needed)
var player_health: float = 100.0
var player_max_health: float = 100.0
var player_fuel: float = 100.0
var player_max_fuel: float = 100.0

func reset_game() -> void:
	has_burner = false
	has_torch = false
	torch_enabled = true
	friends_letter_read = false
	storage_room_unlocked = false
	front_door_unlocked = false
	house_investigated_count = 0
	medkits = 1
	fuel_canisters = 0
	key_items.clear()
	is_night = false
	medical_records_read = false
	cctv_inspected = false
	demon_egg_discovered = false
	minions_defeated = 0
	initial_hospital_wave_started = false
	initial_hospital_wave_defeated = 0
	initial_hospital_wave_completed = false
	entered_lair = false
	boss_defeated = false
	boss_retry_available = false
	player_health = 100.0
	player_fuel = 100.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()

func toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
