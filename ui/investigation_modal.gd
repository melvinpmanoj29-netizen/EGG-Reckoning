extends CanvasLayer

## Investigation Modal Controller.
## Handles rich evidence dossier display, handwritten letter notes, and visual 3-channel CCTV surveillance terminal.

signal modal_closed(topic: String)

@onready var title_label: Label = $Center/Panel/Margin/VBox/HeaderHBox/TitleLabel
@onready var stamp_label: Label = $Center/Panel/Margin/VBox/HeaderHBox/StampLabel
@onready var clue_container: VBoxContainer = $Center/Panel/Margin/VBox/ClueContainer
@onready var text_label: RichTextLabel = $Center/Panel/Margin/VBox/ClueContainer/TextLabel
@onready var cctv_container: VBoxContainer = $Center/Panel/Margin/VBox/CCTVContainer
@onready var footage_texture: TextureRect = $Center/Panel/Margin/VBox/CCTVContainer/ScreenFrame/FootageTexture
@onready var timestamp_label: Label = $Center/Panel/Margin/VBox/CCTVContainer/ScreenFrame/OverlayMargin/VBox/TopInfo/TimestampLabel
@onready var rec_label: Label = $Center/Panel/Margin/VBox/CCTVContainer/ScreenFrame/OverlayMargin/VBox/TopInfo/RecLabel
@onready var feed_desc_label: Label = $Center/Panel/Margin/VBox/CCTVContainer/ScreenFrame/OverlayMargin/VBox/FeedDescription

@onready var cam1_btn: Button = $Center/Panel/Margin/VBox/CCTVContainer/BtnHBox/Cam1Btn
@onready var cam2_btn: Button = $Center/Panel/Margin/VBox/CCTVContainer/BtnHBox/Cam2Btn
@onready var cam3_btn: Button = $Center/Panel/Margin/VBox/CCTVContainer/BtnHBox/Cam3Btn
@onready var close_btn: Button = $Center/Panel/Margin/VBox/BottomBar/CloseBtn

var current_topic: String = ""
var _cam_index: int = 1
var _timer: float = 0.0

const CCTV_DATA: Dictionary = {
	1: {
		"name": "CAM 01 // TOWN PERIMETER [LIVE]",
		"image": "res://assets/ui/cctv_cam1.png",
		"desc": "[ANALYSIS]: Streets completely deserted. Overturned vehicles barricade the main avenue. Low-frequency silhouettes are skittering near the alleyway shadows."
	},
	2: {
		"name": "CAM 02 // HOSPITAL WARD B [INTERFERENCE]",
		"image": "res://assets/ui/cctv_cam2.png",
		"desc": "[ANALYSIS]: Ward B quarantine breached. Heavy sulfur staining on floor tiles. Biological clusters detected near patient quarantine rooms."
	},
	3: {
		"name": "CAM 03 // VAULT SPECIMEN ZERO [CRITICAL]",
		"image": "res://assets/ui/cctv_cam3.png",
		"desc": "[ANALYSIS]: Monolithic Demon Egg actively pulsating in sub-level containment. Warning beacon flashing. Egg Society lair portal detected directly behind chamber."
	}
}

# Saved documents lookup for inventory inspection
var _saved_documents: Dictionary = {}

func _ready() -> void:
	add_to_group("investigation_modal")
	visible = false
	close_btn.pressed.connect(close)
	cam1_btn.pressed.connect(_switch_cam.bind(1))
	cam2_btn.pressed.connect(_switch_cam.bind(2))
	cam3_btn.pressed.connect(_switch_cam.bind(3))

func _process(delta: float) -> void:
	if visible and cctv_container.visible:
		_timer += delta
		# Blinking REC dot
		rec_label.visible = fmod(_timer, 1.0) < 0.65
		# Dynamic seconds counter
		var sec := int(_timer * 2.0) % 60
		timestamp_label.text = "2026-09-13 02:41:%02d AM" % sec
		# Subtle footage jitter
		if footage_texture:
			footage_texture.position.x = sin(_timer * 25.0) * 1.5

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_TAB)):
		get_viewport().set_input_as_handled()
		close()

func open_clue(title: String, body_text: String, topic_id: String = "") -> void:
	current_topic = topic_id
	title_label.text = title.to_upper()
	stamp_label.text = "[ CONFIDENTIAL EVIDENCE ]"
	stamp_label.modulate = Color(1.0, 0.35, 0.35, 1.0)
	
	_saved_documents[title] = {"text": body_text, "topic": topic_id, "is_letter": false}
	_log_to_game_state(title)
	
	# Format with rich BBCode highlighting
	var formatted_text := _apply_evidence_formatting(body_text)
	text_label.text = formatted_text
	
	clue_container.visible = true
	cctv_container.visible = false
	visible = true

	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_clue_open"):
		sm.play_clue_open()

func open_letter(title: String, body_text: String, topic_id: String = "friends_letter") -> void:
	current_topic = topic_id
	title_label.text = title.to_upper()
	stamp_label.text = "[ URGENT HANDWRITTEN NOTE ]"
	stamp_label.modulate = Color(1.0, 0.85, 0.3, 1.0)
	
	_saved_documents[title] = {"text": body_text, "topic": topic_id, "is_letter": true}
	_log_to_game_state(title)
	
	# Format letter with urgent personal styling
	var formatted_text := _apply_letter_formatting(body_text)
	text_label.text = formatted_text
	
	clue_container.visible = true
	cctv_container.visible = false
	visible = true

	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_clue_open"):
		sm.play_clue_open()

func open_key_document(doc_title: String) -> void:
	if _saved_documents.has(doc_title):
		var doc: Dictionary = _saved_documents[doc_title]
		if doc.get("is_letter", false):
			open_letter(doc_title, doc.get("text", ""), doc.get("topic", ""))
		else:
			open_clue(doc_title, doc.get("text", ""), doc.get("topic", ""))
	else:
		open_clue(doc_title, "Archived evidence record.", "")

func _log_to_game_state(title: String) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs and "key_items" in gs:
		if not gs.key_items.has(title):
			gs.key_items.append(title)

func open_cctv() -> void:
	current_topic = "cctv"
	title_label.text = "ST. ANTHONY HOSPITAL // CCTV TERMINAL"
	stamp_label.text = "[ SURVEILLANCE FEED ]"
	stamp_label.modulate = Color(0.4, 0.95, 0.6, 1.0)
	
	clue_container.visible = false
	cctv_container.visible = true
	_switch_cam(1)
	visible = true

	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_clue_open"):
		sm.play_clue_open()

func is_cctv_active() -> bool:
	return visible and current_topic == "cctv"

func is_investigation_active() -> bool:
	return visible

func _switch_cam(cam_id: int) -> void:
	_cam_index = cam_id
	var data: Dictionary = CCTV_DATA.get(cam_id, CCTV_DATA[1])
	
	var img_path: String = data.get("image", "")
	if ResourceLoader.exists(img_path):
		var tex := load(img_path) as Texture2D
		if tex:
			footage_texture.texture = tex
			
	feed_desc_label.text = data.get("desc", "")
	
	# Update active button tints
	cam1_btn.modulate = Color(1.2, 1.2, 1.2, 1.0) if cam_id == 1 else Color(0.7, 0.7, 0.7, 0.8)
	cam2_btn.modulate = Color(1.2, 1.2, 1.2, 1.0) if cam_id == 2 else Color(0.7, 0.7, 0.7, 0.8)
	cam3_btn.modulate = Color(1.2, 1.2, 1.2, 1.0) if cam_id == 3 else Color(0.7, 0.7, 0.7, 0.8)

	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_warning_stage"):
		sm.play_warning_stage(2) # camera switch buzz

func _apply_evidence_formatting(raw_text: String) -> String:
	var res := raw_text
	var keywords := [
		"Demon Egg", "Specimen Zero", "Egg Society", "Incendiary gear", "Incendiary Burner",
		"calcification", "thermal vulnerability", "poisonous", "sub-bass vibration",
		"Quarantine Vault", "Phase 3", "carapace", "Arthur", "evacuation", "fire",
		"storage room", "hospital", "danger"
	]
	for kw in keywords:
		res = res.replacen(kw, "[b][color=#ffcc44]" + kw + "[/color][/b]")
	return res

func _apply_letter_formatting(raw_text: String) -> String:
	var res := raw_text
	var key_warnings := [
		"DO NOT GO NEAR THE HOSPITAL ALONE",
		"destroyed by fire",
		"burner hidden in the storage room",
		"don't trust the eggs",
		"Incendiary Burner"
	]
	for kw in key_warnings:
		res = res.replacen(kw, "[b][color=#ff5544]" + kw + "[/color][/b]")
	return res

func close() -> void:
	if not visible:
		return
	visible = false
	var finished_topic := current_topic
	current_topic = ""
	modal_closed.emit(finished_topic)
