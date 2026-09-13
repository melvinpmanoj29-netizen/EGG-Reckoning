extends Control

## Game Over screen — shown when the player dies.
## Offers Restart (returns to town) and Main Menu options.

@onready var restart_button: Button = $Center/VBox/RestartButton
@onready var retry_boss_button: Button = $Center/VBox/RetryBossButton
@onready var main_menu_button: Button = $Center/VBox/MainMenuButton

func _ready() -> void:
	get_tree().paused = false
	var gs := get_node_or_null("/root/GameState")
	retry_boss_button.visible = gs != null and gs.boss_retry_available
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if retry_boss_button:
		retry_boss_button.pressed.connect(_on_retry_boss_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_restart_pressed() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.has_method("reset_game"):
		gs.reset_game()
	get_tree().change_scene_to_file("res://scenes/world/town_map.tscn")

func _on_retry_boss_pressed() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.boss_retry_available = false
	get_tree().change_scene_to_file("res://scenes/world/boss_room.tscn")

func _on_main_menu_pressed() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.has_method("reset_game"):
		gs.reset_game()
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
