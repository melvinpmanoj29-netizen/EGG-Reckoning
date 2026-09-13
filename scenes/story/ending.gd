extends Control

## Cinematic Illustrated Ending Sequence for EGG: RECKONING.
## Displays 5 narrative conclusion panels with custom illustrations,
## camera zoom/pan tweens, atmospheric sound cues, and return to Main Menu.

const SCENE_MAIN_MENU: String = "res://scenes/menus/main_menu.tscn"

const PANELS: Array[Dictionary] = [
	{
		"title": "EPILOGUE: I. THE MONOLITH SHATTERS",
		"text": "The cavern shook violently as Specimen Zero's calcified carapace ruptured under the relentless heat.\nIts monolithic demonic form collapsed inward, dissolving into a blinding cascade of embers, dark ash, and evaporating ichor.",
		"image": "res://assets/story/ending_1.jpg"
	},
	{
		"title": "EPILOGUE: II. ASHES OF THE EGG SOCIETY",
		"text": "Flames roared through the underground catacombs, consuming the occult altars and toxic incubation nests.\nThe horrific transmutations that had haunted Harborvale for years were finally cleansed by fire.",
		"image": "res://assets/story/ending_2.jpg"
	},
	{
		"title": "EPILOGUE: III. DAWN OVER HARBORVALE",
		"text": "As you emerge into the surface air, the oppressive black fog begins to dissolve.\nFor the first time in memory, the warm golden rays of morning sunlight break across the silent ruins of Harborvale.",
		"image": "res://assets/story/ending_3.jpg"
	},
	{
		"title": "EPILOGUE: IV. THE ROAD AHEAD",
		"text": "Incendiary burner slung across your shoulder, you walk through the rusted perimeter gates.\nThe nightmare of Harborvale is over, and your friend's investigation has reached its final truth.",
		"image": "res://assets/story/ending_4.jpg"
	},
	{
		"title": "EPILOGUE: V. A SINISTER PULSE",
		"text": "Deep in the forgotten darkness beneath the cooling rubble, undisturbed by human eyes...\na single golden egg begins to crack, its malevolent crimson eye opening to begin the cycle anew.\n\nTHE END",
		"image": "res://assets/story/ending_5.jpg"
	}
]

var current_panel: int = 0
var is_transitioning: bool = false

@onready var panel_texture: TextureRect = $IllustrationContainer/PanelTexture
@onready var story_label: Label = $BottomContent/VBox/StoryLabel
@onready var chapter_label: Label = $TopBar/HBox/ChapterLabel
@onready var progress_label: Label = $TopBar/HBox/ProgressLabel
@onready var continue_button: Button = $BottomContent/VBox/ButtonHBox/ContinueButton
@onready var skip_button: Button = $TopBar/HBox/SkipButton

func _ready() -> void:
	modulate.a = 0.0
	continue_button.pressed.connect(_on_continue_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("start_story_music"):
		sm.start_story_music()
		
	_show_panel(0, false)
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8)

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_E)):
		get_viewport().set_input_as_handled()
		_on_continue_pressed()

func _show_panel(index: int, animated: bool = true) -> void:
	current_panel = index
	var panel_data: Dictionary = PANELS[index]
	
	chapter_label.text = panel_data.get("title", "EPILOGUE")
	progress_label.text = "%d / %d" % [index + 1, PANELS.size()]
	story_label.text = panel_data.get("text", "")
	
	var image_path: String = panel_data.get("image", "")
	if ResourceLoader.exists(image_path):
		var tex := load(image_path) as Texture2D
		if tex:
			panel_texture.texture = tex
			
	if index >= PANELS.size() - 1:
		continue_button.text = "Return to Main Menu ⟲"
	else:
		continue_button.text = "Continue [Space] →"
		
	var sm := get_node_or_null("/root/SoundManager")
	if sm:
		if sm.has_method("play_stinger"):
			sm.play_stinger()
			
	if animated:
		panel_texture.scale = Vector2(1.05, 1.05)
		panel_texture.pivot_offset = panel_texture.size * 0.5
		var tween := create_tween().set_parallel(true)
		tween.tween_property(panel_texture, "scale", Vector2(1.0, 1.0), 6.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(story_label, "modulate:a", 1.0, 0.4).from(0.0)

func _on_continue_pressed() -> void:
	if is_transitioning:
		return
		
	if current_panel >= PANELS.size() - 1:
		_return_to_main_menu()
	else:
		is_transitioning = true
		continue_button.disabled = true
		var tween := create_tween()
		tween.tween_property(panel_texture, "modulate:a", 0.0, 0.25)
		tween.tween_property(story_label, "modulate:a", 0.0, 0.25)
		tween.tween_callback(func():
			_show_panel(current_panel + 1, true)
		)
		tween.tween_property(panel_texture, "modulate:a", 1.0, 0.35)
		tween.tween_callback(func():
			is_transitioning = false
			continue_button.disabled = false
		)

func _on_skip_pressed() -> void:
	_return_to_main_menu()

func _return_to_main_menu() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("stop_story_music"):
		sm.stop_story_music()
		
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(SCENE_MAIN_MENU)
	)
