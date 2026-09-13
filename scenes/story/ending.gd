extends Control

## Ending sequence after Demon Egg defeat.
## Town quiet → player leaves → "The nightmare was over." → small egg appears & cracks → "THE END"

@onready var panel_label: Label = $Center/VBox/PanelLabel
@onready var egg_graphic: Node2D = $Center/VBox/EggContainer/EggGraphic
@onready var crack_poly: Polygon2D = $Center/VBox/EggContainer/EggGraphic/CrackPoly
@onready var continue_btn: Button = $Center/VBox/ContinueBtn

var _panel_index: int = 0
var _animating: bool = false

const PANELS: Array[String] = [
	"The town of Harborvale fell into absolute silence.\n\nYou make your way out through the ruined gates,\nleaving the ash and sulfur behind.",
	"The nightmare was over.",
	"Far below in the darkness, something small shifted...",
	"...and a new, faint pulse began.",
	"THE END"
]

func _ready() -> void:
	egg_graphic.visible = false
	crack_poly.visible = false
	continue_btn.pressed.connect(_on_continue_pressed)
	_show_panel(0)

func _show_panel(idx: int) -> void:
	_panel_index = idx
	_animating = true
	continue_btn.disabled = true
	panel_label.text = PANELS[idx]
	panel_label.modulate.a = 0.0

	# Visual effects for egg
	if idx >= 2 and idx <= 3:
		egg_graphic.visible = true
	else:
		egg_graphic.visible = false

	if idx == 3:
		crack_poly.visible = true
	else:
		crack_poly.visible = false

	if idx >= PANELS.size() - 1:
		continue_btn.text = "Return to Main Menu"
	else:
		continue_btn.text = "Next →"

	var tween := create_tween()
	tween.tween_property(panel_label, "modulate:a", 1.0, 0.6)
	tween.tween_callback(func():
		_animating = false
		continue_btn.disabled = false
	)

func _on_continue_pressed() -> void:
	if _animating:
		return
	if _panel_index >= PANELS.size() - 1:
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	else:
		_show_panel(_panel_index + 1)

func _unhandled_input(event: InputEvent) -> void:
	if not _animating and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		_on_continue_pressed()
