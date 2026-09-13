extends Node

## Main scene entry point.
## Acts as the project launch pad; immediately loads the Main Menu.

const SCENE_MAIN_MENU: String = "res://scenes/menus/main_menu.tscn"

func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred(SCENE_MAIN_MENU)
