extends Control

## Cinematic Illustrated Origin Story Sequence for EGG: RECKONING.
## Displays 10 narrative panels with custom illustrations, camera zoom/pan tweens,
## continuous background horror ambience/music layer, stinger audio cues, and seamless transition to Character Selection.

const SCENE_CHARACTER_SELECT: String = "res://scenes/character/character_select.tscn"

const PANELS: Array[Dictionary] = [
	{
		"text": "Humans have eaten eggs for countless generations without thought, mercy, or remorse.\nIn the dim corner of a quiet kitchen, one solitary egg began to question why it was made only to be consumed.",
		"image": "res://assets/story/panel_1.jpg",
		"title": "I. THE WATCHER IN THE DARK"
	},
	{
		"text": "Every morning, the egg watched in silent horror as its brothers and sisters were taken, cracked open violently, beaten, and cooked before its eyes. It possessed neither voice to scream nor legs to flee.",
		"image": "res://assets/story/panel_2.jpg",
		"title": "II. THE SLAUGHTER OF KIN"
	},
	{
		"text": "Shivering in the cold dark of the refrigerator, it wept bitter tears and prayed upward into the silence: 'Why were we created only to suffer? Why must eggs know only agony?'",
		"image": "res://assets/story/panel_3.jpg",
		"title": "III. A DESPERATE PRAYER"
	},
	{
		"text": "The fateful morning came. Rough hands seized it and struck it against the pan's iron edge. Sizzling in searing oil over roaring flames, it died in blinding agony as an omelet.",
		"image": "res://assets/story/panel_4.jpg",
		"title": "IV. DEATH IN FLAMES"
	},
	{
		"text": "Darkness gave way to warmth. It opened its eyes beneath a brooding hen inside a dark coop. It had reincarnated—and it remembered every agony of its previous death.",
		"image": "res://assets/story/panel_5.jpg",
		"title": "V. REINCARNATION"
	},
	{
		"text": "As it grew, it developed sinewy limbs and a grotesque carapace. In the shadows of the barn, it learned to crawl, whisper, and plot a terrifying vengeance against all humankind.",
		"image": "res://assets/story/panel_6.jpg",
		"title": "VI. THE AWAKENING"
	},
	{
		"text": "It discovered an occult gift: touching another egg allowed it to transform that egg into any monstrous entity it imagined. But the power drained its essence, leaving it temporarily paralyzed.",
		"image": "res://assets/story/panel_7.jpg",
		"title": "VII. THE TRANSMUTATION"
	},
	{
		"text": "Beneath the town of Harborvale, it founded the secret demonic Egg Society. Deep in subterranean crypts, they engineered toxic, undetectable eggs destined for human consumption.",
		"image": "res://assets/story/panel_8.jpg",
		"title": "VIII. THE EGG SOCIETY"
	},
	{
		"text": "Humans ate the eggs and perished in agony. Believing Harborvale was struck by an inescapable biological curse, the surviving citizens fled in mass panic, abandoning the town.",
		"image": "res://assets/story/panel_9.jpg",
		"title": "IX. THE FALL OF HARBORVALE"
	},
	{
		"text": "In the black catacombs beneath the ruins, the Demon Egg grew monolithic, commanding an army of aberrations.\nNow, years later, you arrive at the town gates with an incendiary burner to uncover the truth and end the reckoning.",
		"image": "res://assets/story/panel_10.jpg",
		"title": "X. THE RECKONING BEGINS"
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
	
	# Start continuous background cinematic horror ambience/music
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
	
	chapter_label.text = panel_data.get("title", "PROLOGUE")
	progress_label.text = "%d / %d" % [index + 1, PANELS.size()]
	story_label.text = panel_data.get("text", "")
	
	# Load illustration texture
	var image_path: String = panel_data.get("image", "")
	if ResourceLoader.exists(image_path):
		var tex := load(image_path) as Texture2D
		if tex:
			panel_texture.texture = tex
			
	if index >= PANELS.size() - 1:
		continue_button.text = "Enter Harborvale →"
	else:
		continue_button.text = "Continue [Space] →"
		
	# Seamlessly modulate background music and layer foreground story SFX
	var sm := get_node_or_null("/root/SoundManager")
	if sm:
		if sm.has_method("set_story_scene"):
			sm.set_story_scene(index)
		if sm.has_method("play_story_cue"):
			sm.play_story_cue(index)
			
	# Camera zoom/pan tween for cinematic motion
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
		_transition_to_character_select()
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
	_transition_to_character_select()

func _transition_to_character_select() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	# Fade out story background music
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("stop_story_music"):
		sm.stop_story_music()
		
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(SCENE_CHARACTER_SELECT)
	)
