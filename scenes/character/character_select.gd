extends Control

## Character selection screen.
## Player chooses Male or Female operative -- both have identical gameplay abilities.
## Selected character is stored in GameState.selected_character.

const SCENE_MAIN_GAME: String = "res://scenes/world/player_house.tscn"

@onready var boy_btn: Button = $Center/CenterVBox/HBox/BoyCard/BoyButton
@onready var girl_btn: Button = $Center/CenterVBox/HBox/GirlCard/GirlButton
@onready var boy_card: VBoxContainer = $Center/CenterVBox/HBox/BoyCard
@onready var girl_card: VBoxContainer = $Center/CenterVBox/HBox/GirlCard

func _get_game_state() -> Node:
	return get_node_or_null("/root/GameState")

func _ready() -> void:
	modulate.a = 0.0
	boy_btn.pressed.connect(_on_boy_selected)
	girl_btn.pressed.connect(_on_girl_selected)
	
	boy_btn.mouse_entered.connect(_on_card_hover.bind(boy_card, true))
	boy_btn.mouse_exited.connect(_on_card_hover.bind(boy_card, false))
	girl_btn.mouse_entered.connect(_on_card_hover.bind(girl_card, true))
	girl_btn.mouse_exited.connect(_on_card_hover.bind(girl_card, false))
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)

func _on_card_hover(card: Control, is_hover: bool) -> void:
	var target_scale := Vector2(1.03, 1.03) if is_hover else Vector2(1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(card, "scale", target_scale, 0.15).set_trans(Tween.TRANS_SINE)

func _on_boy_selected() -> void:
	var gs := _get_game_state()
	if gs:
		gs.selected_character = "boy"
	_play_select_feedback()
	_disable_buttons()
	_transition_to_game()

func _on_girl_selected() -> void:
	var gs := _get_game_state()
	if gs:
		gs.selected_character = "girl"
	_play_select_feedback()
	_disable_buttons()
	_transition_to_game()

func _play_select_feedback() -> void:
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_pickup"):
		sm.play_pickup()

func _disable_buttons() -> void:
	boy_btn.disabled = true
	girl_btn.disabled = true

func _transition_to_game() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(SCENE_MAIN_GAME))
