extends Control

## Main Menu controller.
## Handles Start Game (→ backstory) and Exit buttons.

const SCENE_BACKSTORY: String = "res://scenes/story/backstory_sequence.tscn"

func _ready() -> void:
	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)

	# Connect buttons
	$Center/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Center/VBox/ExitButton.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	$Center/VBox/StartButton.disabled = true
	get_tree().change_scene_to_file(SCENE_BACKSTORY)

func _on_exit_pressed() -> void:
	get_tree().quit()
