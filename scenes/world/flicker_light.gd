extends PointLight2D

## Intelligent Lighting & Flicker Component for Town & Interiors.
## Provides independent desynchronized behavior, street lamp dusk->night activation,
## and subtle atmospheric flickering without synchronized strobing.

enum FlickerMode {
	STABLE_STREET = 0,
	SUBTLE_FLICKER = 1,
	ERRATIC_FLUORESCENT = 2,
	PULSE_WARNING = 3
}

@export var base_energy: float = 1.0
@export var flicker_mode: FlickerMode = FlickerMode.SUBTLE_FLICKER
@export var is_night_only: bool = true
@export var active_at_dusk: bool = false
@export var min_interval: float = 2.5
@export var max_interval: float = 7.5

var _timer: float = 0.0
var _is_flickering: bool = false
var _flicker_duration: float = 0.0
var _pulse_time: float = 0.0
var _is_powered_on: bool = false

func _ready() -> void:
	add_to_group("lights")
	# Stagger initial timers so lights NEVER cycle or flicker together
	_timer = randf_range(0.5, max_interval)
	_pulse_time = randf_range(0.0, 10.0)

	var is_night: bool = false
	var gs := get_node_or_null("/root/GameState")
	if gs and "is_night" in gs:
		is_night = gs.is_night

	if is_night or active_at_dusk or not is_night_only:
		_is_powered_on = true
		energy = base_energy
	else:
		_is_powered_on = false
		energy = 0.0

func _process(delta: float) -> void:
	if not _is_powered_on:
		return

	match flicker_mode:
		FlickerMode.PULSE_WARNING:
			_pulse_time += delta * 2.2
			var pulse: float = (sin(_pulse_time) * 0.5 + 0.5)
			energy = base_energy * (0.6 + pulse * 0.5)

		FlickerMode.ERRATIC_FLUORESCENT:
			# Frequent erratic jumps (hospital emergency / broken tube)
			_timer -= delta
			if _timer <= 0.0:
				_timer = randf_range(0.06, 0.35)
				if randf() < 0.25:
					energy = randf_range(0.1, base_energy * 0.4)
				else:
					energy = randf_range(base_energy * 0.85, base_energy * 1.1)

		FlickerMode.STABLE_STREET:
			# Mostly solid with rare micro-dips
			_handle_subtle_flicker(delta, 0.06, 0.6)

		FlickerMode.SUBTLE_FLICKER:
			# Standard atmospheric lamp: solid 98% of the time, occasional single/double flicker
			_handle_subtle_flicker(delta, 0.12, 0.3)

func _handle_subtle_flicker(delta: float, dip_length: float, dip_floor_ratio: float) -> void:
	if _is_flickering:
		_flicker_duration -= delta
		if _flicker_duration <= 0.0:
			_is_flickering = false
			energy = base_energy
			_timer = randf_range(min_interval, max_interval)
	else:
		_timer -= delta
		# Very subtle micro-variation during stable periods
		energy = move_toward(energy, base_energy + (randf() * 0.04 - 0.02), delta * 2.0)
		if _timer <= 0.0:
			_is_flickering = true
			_flicker_duration = randf_range(0.04, dip_length)
			energy = base_energy * randf_range(dip_floor_ratio, 0.75)

func turn_on_street_light(delay: float = 0.0) -> void:
	if _is_powered_on:
		return

	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)

	# Quick startup flickers then stabilize to base_energy
	tween.tween_callback(func():
		_is_powered_on = true
		energy = base_energy * 0.3
	)
	tween.tween_interval(0.08)
	tween.tween_property(self, "energy", 0.05, 0.04)
	tween.tween_interval(0.06)
	tween.tween_property(self, "energy", base_energy * 1.15, 0.12)
	tween.tween_property(self, "energy", base_energy, 0.2)
