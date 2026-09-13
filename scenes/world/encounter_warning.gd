extends Node

## Reusable 4-Stage Horror Encounter Warning System.
## Escalates tension before major enemy encounters with progressive audio, light flickering,
## and atmospheric darkening.

signal warning_started
signal warning_stage_reached(stage: int)
signal warning_completed

@export var canvas_modulate_path: NodePath
@export var stage_duration: float = 0.9

var _is_running: bool = false
var _modulate_node: CanvasModulate = null
var _original_modulate: Color = Color.WHITE

func _ready() -> void:
	if canvas_modulate_path:
		_modulate_node = get_node_or_null(canvas_modulate_path) as CanvasModulate
		if _modulate_node:
			_original_modulate = _modulate_node.color

func trigger_encounter_warning(custom_alert: String = "") -> void:
	if _is_running:
		return
	_is_running = true
	warning_started.emit()

	var sm := get_node_or_null("/root/SoundManager")
	var hud := get_tree().get_first_node_in_group("hud")

	# STAGE 1 (0.0s): Distant monster scratching & environmental hush
	if sm and sm.has_method("play_warning_stage"):
		sm.play_warning_stage(1)
	warning_stage_reached.emit(1)

	var tween := create_tween()
	
	# STAGE 2 (0.9s): Electrical hum, lights erratic flicker
	tween.tween_interval(stage_duration)
	tween.tween_callback(func():
		if sm and sm.has_method("play_warning_stage"):
			sm.play_warning_stage(2)
		warning_stage_reached.emit(2)
		_trigger_lights_flicker()
	)

	# STAGE 3 (1.8s): Rising dread drone & atmospheric distortion
	tween.tween_interval(stage_duration)
	tween.tween_callback(func():
		if sm and sm.has_method("play_warning_stage"):
			sm.play_warning_stage(3)
		warning_stage_reached.emit(3)
		if _modulate_node:
			var dark_color := _modulate_node.color * 0.5
			var t_mod := create_tween()
			t_mod.tween_property(_modulate_node, "color", dark_color, stage_duration * 0.8)
	)

	# STAGE 4 (2.7s): Piercing stinger & attack surge
	tween.tween_interval(stage_duration)
	tween.tween_callback(func():
		if sm and sm.has_method("play_warning_stage"):
			sm.play_warning_stage(4)
		warning_stage_reached.emit(4)
		if hud and custom_alert != "":
			if hud.has_method("show_alert"):
				hud.show_alert(custom_alert)
		_is_running = false
		warning_completed.emit()
	)

func _trigger_lights_flicker() -> void:
	# Randomly black out / flicker point lights in the scene
	var lights := get_tree().get_nodes_in_group("lights")
	for light in lights:
		if light is PointLight2D:
			var t := create_tween()
			t.tween_property(light, "energy", 0.0, 0.05)
			t.tween_interval(0.1)
			t.tween_property(light, "energy", 1.5, 0.05)
