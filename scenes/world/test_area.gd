extends Node2D

## Temporary test area -- verifies movement, collision, and camera.
## Replace with actual game levels once core systems are stable.
##
## Play area: 1920 x 1080 centred at origin (-960,-540) to (960,540).

@onready var player: CharacterBody2D = $Player
@onready var info_label: Label = $UI/InfoLabel

func _ready() -> void:
	# Set camera limits to match this level's play area bounds.
	# Player scene stays reusable; level owns the limits.
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left   = -960
	cam.limit_top    = -540
	cam.limit_right  =  960
	cam.limit_bottom =  540

	var selected_char := "boy"
	var gs := get_node_or_null("/root/GameState")
	if gs and "selected_character" in gs:
		selected_char = gs.selected_character

	info_label.text = "Playing as: %s  |  WASD / Arrow keys to move" \
		% selected_char.capitalize()
