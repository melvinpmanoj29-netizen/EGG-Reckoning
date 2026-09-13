extends Node2D

## Abandoned Town & Hospital Map (Stage 2 Expanded Town)

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var modal: CanvasLayer = $InvestigationModal
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var encounter_warning: Node = $EncounterWarning
@onready var inventory_menu: CanvasLayer = $InventoryMenu
@onready var fog_rect: ColorRect = get_node_or_null("FogOverlay/FogRect")

const DUSK_MODULATE := Color(0.68, 0.62, 0.72, 1.0)
const TWILIGHT_MODULATE := Color(0.35, 0.30, 0.48, 1.0)
const MIDNIGHT_MODULATE := Color(0.05, 0.05, 0.10, 1.0)
const NIGHT_FOG_DENSITY: float = 0.22

# Town Building Door Interactables
@onready var player_house_door: Area2D = $Buildings/PlayerHouse/Door/Interactable
@onready var henderson_door: Area2D = $Buildings/HendersonHouse/Door/Interactable
@onready var miller_door: Area2D = $Buildings/MillerHouse/Door/Interactable
@onready var grocery_door: Area2D = $Buildings/GroceryStore/Door/Interactable
@onready var pharmacy_door: Area2D = $Buildings/PharmacyStore/Door/Interactable
@onready var hardware_door: Area2D = $Buildings/HardwareStore/Door/Interactable
@onready var gas_door: Area2D = $Buildings/GasStation/Door/Interactable

# Hospital & Town Interactables
@onready var med_records_int: Area2D = $Hospital/RecordsRoom/MedicalRecords/Interactable
@onready var cctv_int: Area2D = $Hospital/SecurityRoom/CCTVConsole/Interactable
@onready var demon_egg_int: Area2D = $Hospital/QuarantineVault/DemonEgg/Interactable
@onready var town_board_int: Area2D = $TownSquare/TownNoticeBoard/Interactable
@onready var lair_portal_int: Area2D = $Hospital/QuarantineVault/LairPortal/Interactable
@onready var patient1_chart_int: Area2D = $Hospital/PatientRoom1/Chart/Interactable
@onready var patient2_chart_int: Area2D = $Hospital/PatientRoom2/ToxicologyChart/Interactable
@onready var patient3_chart_int: Area2D = $Hospital/PatientRoom3/DischargeLog/Interactable

# Enemy spawner containers
@onready var enemy_container: Node2D = $Enemies

const MINION_SCENE := preload("res://enemies/minion_egg.tscn")
const DEMON_MINION_SCENE := preload("res://enemies/demon_egg_minion.tscn")
const POISON_EGG_SCENE := preload("res://enemies/poison_egg.tscn")

const INITIAL_HOSPITAL_WAVE_SIZE: int = 8

const MEDICAL_RECORDS_TEXT: String = (
	"INCIDENT REPORT #049 - ST. ANTHONY HOSPITAL (CONFIDENTIAL)\n\n" +
	"Patient Zero arrived displaying severe calcification of internal tissue. " +
	"Exploratory incisions revealed a smooth, calcified ovoid entity attached directly " +
	"to the abdominal aorta. The specimen produced an audible sub-bass vibration.\n\n" +
	"Upon extraction, the patient expired instantly. Biological samples began sprouting " +
	"locomotive appendages. The primary specimen was relocated to the Sub-level Quarantine Vault.\n\n" +
	"WARNING: Extreme thermal vulnerability noted. Standard incendiary gear recommended."
)

const PATIENT1_TEXT: String = (
	"ST. ANTHONY HOSPITAL - PATIENT 01 CHART (ARTHUR HENDERSON)\n\n" +
	"ADMITTED: Oct 15 - 08:30 AM\n" +
	"SYMPTOMS: Patient consumed standard store-bought eggs. Developed intense abdominal fever followed by rapid calcification of internal organs.\n\n" +
	"PHYSICIAN NOTE: Epidermal layer is hardening into an egg-like shell. Faint scratching heard from within patient's torso. Patient became unresponsive at 14:00."
)

const PATIENT2_TEXT: String = (
	"ST. ANTHONY HOSPITAL - PATIENT 02 TOXICOLOGY REPORT\n\n" +
	"SPECIMEN ID: Neurotoxin Batch #804-E\n" +
	"ORIGIN: Egg Society Sub-Level Agro-Cultivation\n\n" +
	"ANALYSIS: Bio-chemical compound accelerates cellular mutation and bonds with human gastrointestinal tissue. " +
	"Parasitic incubation begins within 4 hours. CRITICAL WEAKNESS: Extreme vulnerability to concentrated flame and incendiary heat."
)

const PATIENT3_TEXT: String = (
	"ST. ANTHONY HOSPITAL - PATIENT 03 QUARANTINE & DISCHARGE LOG\n\n" +
	"INCIDENT REPORT: Isolation Ward Containment Breach\n\n" +
	"LOG: Patient 03 ruptured during examination. Multiple parasitic egg entities emerged and attacked medical personnel. " +
	"Quarantine wing sealed permanently. The sub-level hatch in Vault Zero remains the only conduit to the Cult's underground breeding grounds."
)

const TOWN_BOARD_TEXT: String = (
	"EMERGENCY EVACUATION NOTICE - HARBORVALE\n\n" +
	"All residents must proceed to the East Highway immediately. " +
	"Do not approach unidentified biological clusters. Avoid darkened corridors. " +
	"If you hear rhythmic scratching inside the walls, seek shelter and maintain high illumination."
)

const DEMON_EGG_TEXT: String = (
	"THE DEMON EGG (SPECIMEN ZERO)\n\n" +
	"A monolithic, pulsating black-and-crimson egg dominates the quarantine chamber. " +
	"Its membrane swells and contracts with terrifying vitality. Inside, something ancient and " +
	"unfathomably evil writhes against the shell.\n\n" +
	"As you examine it, an ear-splitting psychic shriek reverberates through the facility! " +
	"Outside, dusk immediately dies into a suffocating, unnatural night!\n\n" +
	"A hatch opens behind the chamber, leading deeper into the underground..."
)

func _ready() -> void:
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		cam.zoom = Vector2(1.0, 1.0)
		cam.limit_left   = -1200
		cam.limit_top    = -800
		cam.limit_right  =  1200
		cam.limit_bottom =  800

	# Restore player position from building exit if set
	var gs := get_node_or_null("/root/GameState")
	if gs and "town_player_pos" in gs and gs.town_player_pos != Vector2.ZERO:
		player.global_position = gs.town_player_pos

	# Connect player signals to HUD
	player.health_changed.connect(hud.update_health)
	player.fuel_changed.connect(hud.update_fuel)
	player.died.connect(_on_player_died)

	# Initial HUD refresh
	hud.update_health(player.health, player.max_health)
	hud.update_fuel(player.fuel, player.max_fuel)

	# Building door interactables
	player_house_door.interacted.connect(func(_p): _change_interior("res://scenes/world/player_house.tscn", Vector2(-850, -350)))
	henderson_door.interacted.connect(func(_p): _change_interior("res://scenes/interiors/house_henderson.tscn", Vector2(-500, -350)))
	miller_door.interacted.connect(func(_p): _change_interior("res://scenes/interiors/house_miller.tscn", Vector2(-150, -350)))
	grocery_door.interacted.connect(func(_p): _change_interior("res://scenes/interiors/store_grocery.tscn", Vector2(-850, 380)))
	pharmacy_door.interacted.connect(func(_p): _change_interior("res://scenes/interiors/store_pharmacy.tscn", Vector2(-550, 380)))
	hardware_door.interacted.connect(func(_p): _change_interior("res://scenes/interiors/store_hardware.tscn", Vector2(-250, 380)))
	gas_door.interacted.connect(func(_p): _change_interior("res://scenes/interiors/station_gas.tscn", Vector2(900, 380)))

	# Hospital & World interactables
	med_records_int.interacted.connect(_on_medical_records_interacted)
	cctv_int.interacted.connect(_on_cctv_interacted)
	demon_egg_int.interacted.connect(_on_demon_egg_interacted)
	town_board_int.interacted.connect(_on_town_board_interacted)
	lair_portal_int.interacted.connect(_on_lair_portal_interacted)
	patient1_chart_int.interacted.connect(_on_patient1_chart_interacted)
	patient2_chart_int.interacted.connect(_on_patient2_chart_interacted)
	patient3_chart_int.interacted.connect(_on_patient3_chart_interacted)

	# Connect investigation modal closed signal
	modal.modal_closed.connect(_on_modal_closed)

	# Connect pre-placed world enemies
	for enemy in enemy_container.get_children():
		if enemy.has_signal("defeated") and not enemy.defeated.is_connected(_on_initial_hospital_minion_defeated):
			enemy.defeated.connect(_on_initial_hospital_minion_defeated)

	# Night state check & ambience setup
	var sm := get_node_or_null("/root/SoundManager")
	if gs and "is_night" in gs and gs.is_night:
		canvas_modulate.color = MIDNIGHT_MODULATE
		_set_fog_density(NIGHT_FOG_DENSITY)
		_activate_all_street_lights()
		lair_portal_int.is_active = gs.initial_hospital_wave_completed
		if sm and sm.has_method("start_town_ambience"):
			sm.start_town_ambience(true)
	else:
		canvas_modulate.color = DUSK_MODULATE
		_set_fog_density(0.0)
		lair_portal_int.is_active = false
		if sm and sm.has_method("start_town_ambience"):
			sm.start_town_ambience(false)

func _set_fog_density(density: float) -> void:
	if fog_rect and fog_rect.material is ShaderMaterial:
		(fog_rect.material as ShaderMaterial).set_shader_parameter("fog_density", density)

func _activate_all_street_lights() -> void:
	var lights := get_tree().get_nodes_in_group("lights")
	for light in lights:
		if light.has_method("turn_on_street_light"):
			light.turn_on_street_light(0.0)

func _activate_street_lights_sequential() -> void:
	var lights := get_tree().get_nodes_in_group("lights")
	for light in lights:
		if light.has_method("turn_on_street_light") and "is_night_only" in light and light.is_night_only:
			light.turn_on_street_light(randf_range(0.0, 1.6))

func _change_interior(scene_path: String, return_pos: Vector2) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.town_player_pos = return_pos
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", Color(0.0, 0.0, 0.0, 1.0), 0.35)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(scene_path)
	)

func _on_medical_records_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.medical_records_read = true
	modal.open_clue("ST. ANTHONY HOSPITAL - MEDICAL ARCHIVE", MEDICAL_RECORDS_TEXT, "med_records")

func _on_patient1_chart_interacted(_p: Node2D) -> void:
	modal.open_clue("PATIENT ROOM 01 - MEDICAL RECORD", PATIENT1_TEXT, "patient1_chart")

func _on_patient2_chart_interacted(_p: Node2D) -> void:
	modal.open_clue("PATIENT ROOM 02 - TOXICOLOGY RECORD", PATIENT2_TEXT, "patient2_chart")

func _on_patient3_chart_interacted(_p: Node2D) -> void:
	modal.open_clue("PATIENT ROOM 03 - ISOLATION WARD LOG", PATIENT3_TEXT, "patient3_chart")

func _on_cctv_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.cctv_inspected = true
	modal.open_cctv()

func _on_demon_egg_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.demon_egg_discovered = true
	modal.open_clue("BIO-HAZARD CONTAINMENT - SPECIMEN ZERO", DEMON_EGG_TEXT, "demon_egg")

func _on_town_board_interacted(_p: Node2D) -> void:
	modal.open_clue("TOWN NOTICE BOARD", TOWN_BOARD_TEXT, "town_board")

func _on_lair_portal_interacted(_p: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.entered_lair = true
	get_tree().change_scene_to_file("res://scenes/world/boss_room.tscn")

func _on_modal_closed(topic: String) -> void:
	if topic == "demon_egg" or topic == "cctv":
		trigger_night()

func trigger_night() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs and "is_night" in gs:
		if gs.is_night:
			return
		gs.is_night = true

	var sm := get_node_or_null("/root/SoundManager")

	# Smooth gradual dusk -> twilight -> midnight environmental transition
	var tween := create_tween()

	# 0.0s -> 3.0s: Dusk to Twilight & Audio shift begins
	if sm and sm.has_method("set_town_night_factor"):
		sm.set_town_night_factor(0.5)

	tween.tween_property(canvas_modulate, "color", TWILIGHT_MODULATE, 3.0)
	tween.parallel().tween_method(_set_fog_density, 0.0, NIGHT_FOG_DENSITY * 0.5, 3.0)

	# At 2.5s: Street lights begin activating with subtle staggered delays; distant night audio cue
	tween.tween_callback(func():
		_activate_street_lights_sequential()
		if sm and sm.has_method("play_distant_night_sound"):
			sm.play_distant_night_sound()
	)

	# 3.0s -> 6.0s: Twilight to Midnight & full wind tension
	tween.tween_callback(func():
		if sm and sm.has_method("set_town_night_factor"):
			sm.set_town_night_factor(1.0)
	)
	tween.tween_property(canvas_modulate, "color", MIDNIGHT_MODULATE, 3.0)
	tween.parallel().tween_method(_set_fog_density, NIGHT_FOG_DENSITY * 0.5, NIGHT_FOG_DENSITY, 3.0)

	# At 3.8s: Subtle non-blocking "NIGHT HAS FALLEN" alert
	tween.tween_callback(func():
		hud.show_alert("NIGHT HAS FALLEN")
	)

	# At 6.0s: Transition completes, start hospital & town wave
	tween.tween_callback(func():
		_start_initial_hospital_wave()
	)

func _start_initial_hospital_wave() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null or gs.initial_hospital_wave_started:
		return
	gs.initial_hospital_wave_started = true

	# Alert any existing enemies into search/investigate mode
	for enemy in enemy_container.get_children():
		if enemy.has_method("investigate_position"):
			enemy.investigate_position(player.global_position)

func _spawn_enemy(scene_res: PackedScene, pos: Vector2, counts_toward_initial_wave: bool = false) -> void:
	var enemy := scene_res.instantiate() as Node2D
	enemy.global_position = pos
	if counts_toward_initial_wave:
		enemy.defeated.connect(_on_initial_hospital_minion_defeated)
	enemy_container.add_child(enemy)

func _on_initial_hospital_minion_defeated(_minion: Node2D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null or gs.initial_hospital_wave_completed:
		return
	gs.initial_hospital_wave_defeated += 1
	var required_kills: int = 5
	if gs.initial_hospital_wave_defeated < required_kills:
		return

	gs.initial_hospital_wave_completed = true
	lair_portal_int.is_active = true
	hud.show_alert("HOSPITAL CLEARED - EGG SOCIETY LAIR HATCH UNLOCKED!")
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_stinger"):
		sm.play_stinger()

func _on_player_died() -> void:
	hud.show_alert("CRITICAL VITALS - YOU HAVE PERISHED")
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/menus/game_over.tscn")
	)
