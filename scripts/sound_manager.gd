extends Node

## SoundManager provides dual-stream procedural horror audio architecture:
## 1. Dedicated Continuous Background Music & Ambience channel (_bgm_player).
## 2. Dedicated Low-latency Foreground Sound Effects & Story Cues channel (_sfx_player).

var _bgm_player: AudioStreamPlayer
var _bgm_generator: AudioStreamGenerator
var _bgm_playback: AudioStreamGeneratorPlayback

var _sfx_player: AudioStreamPlayer
var _sfx_generator: AudioStreamGenerator
var _sfx_playback: AudioStreamGeneratorPlayback

var _sample_rate: float = 22050.0

# Boss Music synthesis state
var _boss_music_active: bool = false
var _boss_phase: int = 1
var _boss_music_time: float = 0.0

# Origin Story Background Music state
var _story_bgm_active: bool = false
var _story_panel_idx: int = 0
var _current_panel_blend: float = 0.0
var _story_bgm_time: float = 0.0
var _story_bgm_vol: float = 0.0
var _story_bgm_target_vol: float = 0.0

# Town Ambience state (Dusk -> Night)
var _town_ambience_active: bool = false
var _town_night_factor: float = 0.0
var _target_night_factor: float = 0.0
var _town_ambience_time: float = 0.0
var _town_ambience_vol: float = 0.0
var _town_ambience_target_vol: float = 0.0
var _distant_night_timer: float = 0.0

func _ready() -> void:
	# Initialize Dedicated BGM Channel
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = "Master"
	add_child(_bgm_player)
	_bgm_generator = AudioStreamGenerator.new()
	_bgm_generator.mix_rate = _sample_rate
	_bgm_generator.buffer_length = 0.5
	_bgm_player.stream = _bgm_generator
	_bgm_player.play()
	_bgm_playback = _bgm_player.get_stream_playback() as AudioStreamGeneratorPlayback

	# Initialize Dedicated SFX Channel
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFXPlayer"
	_sfx_player.bus = "Master"
	add_child(_sfx_player)
	_sfx_generator = AudioStreamGenerator.new()
	_sfx_generator.mix_rate = _sample_rate
	_sfx_generator.buffer_length = 0.5
	_sfx_player.stream = _sfx_generator
	_sfx_player.play()
	_sfx_playback = _sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(delta: float) -> void:
	if _story_bgm_active and _bgm_playback:
		_stream_story_bgm(delta)
	elif _boss_music_active and _bgm_playback:
		_stream_boss_music(delta)
	elif _town_ambience_active and _bgm_playback:
		_stream_town_ambience(delta)

# ---------------------------------------------------------
# TOWN DUSK & NIGHT HORROR AMBIENCE SYSTEM
# ---------------------------------------------------------

func start_town_ambience(is_night: bool = false) -> void:
	_story_bgm_active = false
	_boss_music_active = false
	_town_ambience_active = true
	_town_ambience_time = 0.0
	_town_night_factor = 1.0 if is_night else 0.0
	_target_night_factor = _town_night_factor
	_town_ambience_vol = 0.0
	_town_ambience_target_vol = 0.8
	_distant_night_timer = randf_range(12.0, 24.0)

func set_town_night_factor(factor: float) -> void:
	_target_night_factor = clampf(factor, 0.0, 1.0)

func stop_town_ambience() -> void:
	_town_ambience_target_vol = 0.0
	var tween := create_tween()
	tween.tween_property(self, "_town_ambience_vol", 0.0, 0.5)
	tween.tween_callback(func():
		_town_ambience_active = false
	)

func play_distant_night_sound() -> void:
	if not _sfx_playback: return
	# Ominous distant metallic reverberation / unsettling groan
	var frames: int = int(_sample_rate * 1.5)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 1.5) * min(1.0, t * 8.0)
		var groan: float = sin(2.0 * PI * (90.0 - t * 25.0) * t) * 0.4
		var hiss: float = (randf() * 2.0 - 1.0) * sin(2.0 * PI * 240.0 * t) * 0.2
		var sample: float = (groan + hiss) * env * 0.55
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func _stream_town_ambience(delta: float) -> void:
	if not _bgm_playback or not _bgm_playback.can_push_buffer(64):
		return

	_town_ambience_vol = move_toward(_town_ambience_vol, _town_ambience_target_vol, delta * 0.6)
	_town_night_factor = move_toward(_town_night_factor, _target_night_factor, delta * 0.4)

	# Occasional random distant eerie sound at full night
	if _town_night_factor > 0.7:
		_distant_night_timer -= delta
		if _distant_night_timer <= 0.0:
			_distant_night_timer = randf_range(18.0, 35.0)
			play_distant_night_sound()

	var frames_to_push: int = min(256, _bgm_playback.get_frames_available())
	for i in range(frames_to_push):
		_town_ambience_time += 1.0 / _sample_rate
		var t := _town_ambience_time
		var nf := _town_night_factor

		# 1. Dusk base layer: Gentle atmospheric breeze and warm low pad
		var dusk_breeze := (randf() * 2.0 - 1.0) * sin(2.0 * PI * 95.0 * t) * (0.06 + sin(t * 0.3) * 0.03)
		var dusk_tone := sin(2.0 * PI * 110.0 * t) * 0.08 * (1.0 - nf * 0.8)

		# 2. Night layer: Whistling cold drafts & tension sub-bass (48 Hz / 72 Hz)
		var wind_gust := (sin(t * 0.4) * 0.5 + 0.5) * (randf() * 2.0 - 1.0) * 0.12 * nf
		var wind_whistle := sin(2.0 * PI * (320.0 + sin(t * 0.8) * 80.0) * t) * 0.05 * nf * (sin(t * 0.25) * 0.5 + 0.5)
		var sub_dread := (sin(2.0 * PI * 48.0 * t) * 0.25 + sin(2.0 * PI * 72.0 * t) * 0.15) * nf

		# Master Ambience sample
		var sample: float = (dusk_breeze * (1.0 - nf * 0.5) + dusk_tone + wind_gust + wind_whistle + sub_dread) * _town_ambience_vol * 0.38
		_bgm_playback.push_frame(Vector2(sample, sample))

# ---------------------------------------------------------
# ORIGIN STORY CONTINUOUS BACKGROUND MUSIC SYSTEM
# ---------------------------------------------------------

func start_story_music() -> void:
	_story_bgm_active = true
	_boss_music_active = false
	_story_bgm_time = 0.0
	_story_panel_idx = 0
	_current_panel_blend = 0.0
	_story_bgm_vol = 0.0
	_story_bgm_target_vol = 0.85

func set_story_scene(scene_index: int) -> void:
	_story_panel_idx = scene_index

func stop_story_music() -> void:
	_story_bgm_target_vol = 0.0
	var tween := create_tween()
	tween.tween_property(self, "_story_bgm_vol", 0.0, 0.6)
	tween.tween_callback(func():
		_story_bgm_active = false
	)

func _stream_story_bgm(delta: float) -> void:
	if not _bgm_playback or not _bgm_playback.can_push_buffer(64):
		return
	
	_story_bgm_vol = move_toward(_story_bgm_vol, _story_bgm_target_vol, delta * 0.8)
	_current_panel_blend = lerp(_current_panel_blend, float(_story_panel_idx), delta * 1.5)
	
	var frames_to_push: int = min(256, _bgm_playback.get_frames_available())
	for i in range(frames_to_push):
		_story_bgm_time += 1.0 / _sample_rate
		var t := _story_bgm_time
		var p := _current_panel_blend
		
		# 1. Base dark horror drone chord: C2 (65.41 Hz) + G2 (98.0 Hz) + Eb2 (77.78 Hz)
		var lfo := sin(t * 0.25) * 0.8
		var f1: float = 65.41 + lfo
		var f2: float = 98.00 + sin(t * 0.17) * 0.5
		
		# Minor second dissonance creeps in as tragedy develops
		var f3: float = 77.78 + sin(t * 0.31) * 0.6
		if p > 1.5:
			f3 = lerp(77.78, 69.30, clampf((p - 1.5) / 2.5, 0.0, 1.0))
		
		var drone := (sin(2.0 * PI * f1 * t) * 0.35 + sin(2.0 * PI * f2 * t) * 0.25 + sin(2.0 * PI * f3 * t) * 0.25)
		
		# 2. Rhythmic heartbeat / sub-pulse modulated per story chapter
		var bpm: float = 44.0 + clampf(p * 2.2, 0.0, 22.0)
		if p >= 4.0 and p < 5.0:
			# Scene 5 (Rebirth): deep stillness
			bpm = 32.0
		var beat_len: float = 60.0 / bpm
		var beat_t: float = fmod(t, beat_len)
		var heartbeat_env: float = exp(-beat_t * 10.0)
		var heartbeat: float = sin(2.0 * PI * 46.0 * beat_t) * heartbeat_env * 0.35
		var hb_weight: float = 0.25 + clampf(p * 0.08, 0.0, 0.6)
		if p >= 3.0 and p <= 4.2:
			hb_weight = 0.7 # Intense pulse during death and reincarnation
			
		# 3. Eerie atmospheric pad / weeping harmonic
		var pad_freq: float = 261.63 + sin(t * 0.35) * 2.0
		if p > 5.0:
			pad_freq = 277.18 # C# occult harmonic shift in Egg Society scenes
		var pad_env: float = (sin(t * 0.5) * 0.5 + 0.5) * (0.15 + clampf(p * 0.04, 0.0, 0.3))
		var pad: float = sin(2.0 * PI * pad_freq * t) * pad_env * 0.22
		
		# 4. Low atmospheric air movement
		var wind_mod: float = (sin(t * 0.7) * 0.5 + 0.5) * 0.12
		var noise: float = (randf() * 2.0 - 1.0) * sin(2.0 * PI * (110.0 + p * 12.0) * t) * wind_mod
		
		# Master background mix
		var sample: float = (drone * 0.42 + heartbeat * hb_weight + pad + noise) * _story_bgm_vol * 0.32
		_bgm_playback.push_frame(Vector2(sample, sample))

# ---------------------------------------------------------
# BOSS AUDIO SYSTEM
# ---------------------------------------------------------

func start_boss_music() -> void:
	_story_bgm_active = false
	_boss_music_active = true
	_boss_phase = 1
	_boss_music_time = 0.0

func set_boss_phase(phase: int) -> void:
	_boss_phase = phase
	play_stinger()

func stop_boss_music() -> void:
	_boss_music_active = false

func play_boss_attack() -> void:
	if not _sfx_playback: return
	# Heavy rushing flame whoosh
	var frames: int = int(_sample_rate * 0.3)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = sin(PI * (t / 0.3))
		var noise: float = (randf() * 2.0 - 1.0) * 0.4
		var low_thud: float = sin(2.0 * PI * (80.0 - t * 100.0) * t) * 0.5
		var sample: float = (noise + low_thud) * env * 0.7
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func play_boss_death() -> void:
	stop_boss_music()
	if not _sfx_playback: return
	# Colossal resonant shattering explosion
	var frames: int = int(_sample_rate * 2.0)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 1.8)
		var noise: float = (randf() * 2.0 - 1.0) * 0.5
		var sub: float = sin(2.0 * PI * max(20.0, 120.0 - t * 50.0) * t) * 0.6
		var crackle: float = sin(2.0 * PI * 340.0 * t) * exp(-t * 8.0) * 0.4
		var sample: float = (noise * 0.5 + sub * 0.4 + crackle * 0.3) * env * 0.8
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func _stream_boss_music(_delta: float) -> void:
	if not _bgm_playback or not _bgm_playback.can_push_buffer(64):
		return
	var bpm: float = 80.0 if _boss_phase == 1 else (115.0 if _boss_phase == 2 else 140.0)
	var beat_len: float = 60.0 / bpm
	var frames_to_push: int = min(256, _bgm_playback.get_frames_available())
	
	for i in range(frames_to_push):
		_boss_music_time += 1.0 / _sample_rate
		var t: float = _boss_music_time
		var beat_t: float = fmod(t, beat_len)
		var beat_env: float = exp(-beat_t * (10.0 if _boss_phase == 1 else 14.0))
		
		# Low heavy heartbeat pulse
		var bass_pitch: float = 48.0 if _boss_phase == 1 else (55.0 if _boss_phase == 2 else 65.0)
		var drum: float = sin(2.0 * PI * bass_pitch * beat_t) * beat_env * 0.45
		
		# Dissonant occult synthesizer drone
		var drone_pitch: float = 82.0 + sin(t * 0.5) * 4.0
		var drone: float = (sin(2.0 * PI * drone_pitch * t) * 0.15 + sin(2.0 * PI * (drone_pitch * 1.414) * t) * 0.12)
		
		# Frenzy lead for phase 2 and 3
		var frenzy: float = 0.0
		if _boss_phase >= 2:
			var arp_pitch: float = 180.0 + fmod(floor(t * 6.0), 4.0) * 35.0
			frenzy = sin(2.0 * PI * arp_pitch * t) * 0.1
			if _boss_phase == 3:
				frenzy += (randf() * 2.0 - 1.0) * 0.08
				
		var sample: float = (drum + drone + frenzy) * 0.5
		_bgm_playback.push_frame(Vector2(sample, sample))

# ---------------------------------------------------------
# ENEMY APPROACH WARNING STAGES
# ---------------------------------------------------------

func play_warning_stage(stage: int) -> void:
	if not _sfx_playback: return
	match stage:
		1:
			# Stage 1: Distant skittering / scratching
			var frames: int = int(_sample_rate * 0.4)
			for i in range(frames):
				var t: float = float(i) / _sample_rate
				var env: float = exp(-t * 6.0)
				var scratch: float = (randf() * 2.0 - 1.0) * sin(2.0 * PI * 800.0 * t) * 0.2
				var sample: float = scratch * env * 0.4
				if _sfx_playback.can_push_buffer(1):
					_sfx_playback.push_frame(Vector2(sample, sample))
		2:
			# Stage 2: Erratic electrical buzzing & transformer hum
			var frames: int = int(_sample_rate * 0.6)
			for i in range(frames):
				var t: float = float(i) / _sample_rate
				var hum: float = sin(2.0 * PI * 60.0 * t) * 0.3 + (randf() * 2.0 - 1.0) * 0.15
				var sample: float = hum * 0.45
				if _sfx_playback.can_push_buffer(1):
					_sfx_playback.push_frame(Vector2(sample, sample))
		3:
			# Stage 3: Low rising dissonant dread drone
			var frames: int = int(_sample_rate * 0.8)
			for i in range(frames):
				var t: float = float(i) / _sample_rate
				var freq: float = 65.0 + t * 40.0
				var env: float = min(1.0, t * 2.0)
				var drone: float = (sin(2.0 * PI * freq * t) * 0.4 + sin(2.0 * PI * (freq * 1.414) * t) * 0.3) * env * 0.6
				if _sfx_playback.can_push_buffer(1):
					_sfx_playback.push_frame(Vector2(drone, drone))
		4:
			# Stage 4: Violent screeching horror stinger
			play_stinger()

# ---------------------------------------------------------
# ORIGIN STORY FOREGROUND SOUND DESIGN
# ---------------------------------------------------------

func play_story_cue(panel_index: int) -> void:
	if not _sfx_playback: return
	match panel_index:
		0: # Kitchen observation: Quiet hum & cutlery clank
			_play_soft_tone(220.0, 0.4)
		1: # Slaughter: Brutal shell crack
			_play_shell_crack()
		2: # Prayer: Ethereal chime
			_play_sad_chime()
		3: # Frying pan: Sizzling hot oil hiss
			_play_sizzle()
		4: # Reincarnation: Heavy heartbeat into rebirth surge
			_play_rebirth_surge()
		5: # Awakening: Skittering insectoid scratch
			_play_skitter()
		6: # Transmutation: Occult zap & dark pulse
			_play_occult_zap()
		7: # Egg Society: Deep chant rumble
			_play_cult_chant()
		8: # Town fall: Distant mournful wind
			_play_mournful_wind()
		9: # Climax reckoning stinger
			play_stinger()

func _play_shell_crack() -> void:
	var frames: int = int(_sample_rate * 0.25)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 22.0)
		var crack: float = (randf() * 2.0 - 1.0) * 0.6 + sin(2.0 * PI * 420.0 * t) * 0.3
		var sample: float = crack * env * 0.7
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func _play_sizzle() -> void:
	var frames: int = int(_sample_rate * 0.8)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 2.5)
		var noise: float = (randf() * 2.0 - 1.0) * 0.35
		var sample: float = noise * env * 0.6
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func _play_sad_chime() -> void:
	var frames: int = int(_sample_rate * 0.7)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 3.5)
		var sample: float = (sin(2.0 * PI * 330.0 * t) * 0.35 + sin(2.0 * PI * 495.0 * t) * 0.25) * env * 0.5
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func _play_rebirth_surge() -> void:
	var frames: int = int(_sample_rate * 1.0)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 1.8)
		var thud: float = sin(2.0 * PI * 55.0 * t) * exp(-t * 8.0) * 0.6
		var surge: float = sin(2.0 * PI * (75.0 + t * 90.0) * t) * 0.3 * min(1.0, t * 3.0)
		var sample: float = (thud + surge) * env * 0.7
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func _play_skitter() -> void:
	var frames: int = int(_sample_rate * 0.5)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 5.0)
		var noise: float = (randf() * 2.0 - 1.0) * sin(2.0 * PI * 650.0 * t) * 0.35
		var sample: float = noise * env * 0.5
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func _play_occult_zap() -> void:
	var frames: int = int(_sample_rate * 0.6)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 4.0)
		var zap: float = sin(2.0 * PI * (400.0 - t * 300.0) * t) * 0.4 + (randf() * 2.0 - 1.0) * 0.2
		var sample: float = zap * env * 0.6
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func _play_cult_chant() -> void:
	var frames: int = int(_sample_rate * 0.9)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 2.0)
		var sub: float = sin(2.0 * PI * 70.0 * t) * 0.4 + sin(2.0 * PI * 105.0 * t) * 0.3
		var sample: float = sub * env * 0.6
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func _play_mournful_wind() -> void:
	var frames: int = int(_sample_rate * 1.0)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = sin(PI * (t / 1.0))
		var wind: float = (randf() * 2.0 - 1.0) * sin(2.0 * PI * 180.0 * t) * 0.3
		var sample: float = wind * env * 0.5
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func _play_soft_tone(freq: float, dur: float) -> void:
	var frames: int = int(_sample_rate * dur)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 3.0)
		var sample: float = sin(2.0 * PI * freq * t) * env * 0.3
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

# ---------------------------------------------------------
# INVESTIGATION & CLUES AUDIO
# ---------------------------------------------------------

func play_clue_found() -> void:
	if not _sfx_playback: return
	var frames: int = int(_sample_rate * 0.4)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var freq: float = 330.0 if t < 0.2 else 495.0
		var env: float = exp(-fmod(t, 0.2) * 10.0)
		var sample: float = sin(2.0 * PI * freq * t) * env * 0.45
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func play_clue_open() -> void:
	if not _sfx_playback: return
	var frames: int = int(_sample_rate * 0.25)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 14.0)
		var paper: float = (randf() * 2.0 - 1.0) * 0.3 + sin(2.0 * PI * 280.0 * t) * 0.2
		var sample: float = paper * env * 0.45
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

# ---------------------------------------------------------
# CORE GAMEPLAY SFX
# ---------------------------------------------------------

func play_stinger() -> void:
	if not _sfx_playback: return
	var frames: int = int(_sample_rate * 1.0)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 2.0)
		var s1: float = sin(2.0 * PI * 85.0 * t)
		var s2: float = sin(2.0 * PI * 122.0 * t)
		var s3: float = sin(2.0 * PI * 60.0 * t)
		var sample: float = (s1 * 0.4 + s2 * 0.3 + s3 * 0.3) * env * 0.7
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func play_burner() -> void:
	if not _sfx_playback: return
	var frames: int = int(_sample_rate * 0.15)
	for i in range(frames):
		var noise: float = (randf() * 2.0 - 1.0) * 0.25
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(noise, noise))

func play_hurt() -> void:
	if not _sfx_playback: return
	var frames: int = int(_sample_rate * 0.2)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var env: float = exp(-t * 15.0)
		var sample: float = sin(2.0 * PI * 110.0 * t) * env * 0.6
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))

func play_pickup() -> void:
	if not _sfx_playback: return
	var frames: int = int(_sample_rate * 0.25)
	for i in range(frames):
		var t: float = float(i) / _sample_rate
		var freq: float = 440.0 if t < 0.12 else 660.0
		var env: float = exp(-fmod(t, 0.12) * 12.0)
		var sample: float = sin(2.0 * PI * freq * t) * env * 0.4
		if _sfx_playback.can_push_buffer(1):
			_sfx_playback.push_frame(Vector2(sample, sample))
