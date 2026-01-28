extends Node

## Audio Manager - Handles all game audio
## Uses procedural audio generation for simple SFX (no external files needed)

# Audio buses
var master_volume := 0.8
var sfx_volume := 0.7
var bgm_volume := 0.7  # Increased for better audibility

# Audio players
var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8

# BGM state
var bgm_playing := false

var _bgm_stream: AudioStreamWAV

func _ready() -> void:
	_setup_audio_players()
	_setup_audio_bus()
	# Pre-generate BGM to avoid delay when first playing
	_bgm_stream = _generate_bgm()

func _setup_audio_bus() -> void:
	# Set initial volumes
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

func _setup_audio_players() -> void:
	# BGM Player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	bgm_player.volume_db = linear_to_db(bgm_volume)
	add_child(bgm_player)
	
	# SFX Players pool
	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = linear_to_db(sfx_volume)
		add_child(player)
		sfx_players.append(player)

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# If all are busy, use the first one
	return sfx_players[0]

# ============ SOUND EFFECTS ============

func play_mask_switch() -> void:
	var player := _get_available_sfx_player()
	player.stream = _generate_mask_switch_sound()
	player.pitch_scale = randf_range(0.95, 1.05)
	player.play()

func play_death() -> void:
	var player := _get_available_sfx_player()
	player.stream = _generate_death_sound()
	player.pitch_scale = 1.0
	player.play()

func play_level_complete() -> void:
	var player := _get_available_sfx_player()
	player.stream = _generate_victory_sound()
	player.pitch_scale = 1.0
	player.play()

func play_enemy_alert() -> void:
	var player := _get_available_sfx_player()
	player.stream = _generate_alert_sound()
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()

func play_enemy_flee() -> void:
	var player := _get_available_sfx_player()
	player.stream = _generate_flee_sound()
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()

func play_laser_deactivate() -> void:
	var player := _get_available_sfx_player()
	player.stream = _generate_laser_sound(false)
	player.pitch_scale = 1.0
	player.play()

func play_laser_activate() -> void:
	var player := _get_available_sfx_player()
	player.stream = _generate_laser_sound(true)
	player.pitch_scale = 1.0
	player.play()

func play_cooldown_ready() -> void:
	var player := _get_available_sfx_player()
	player.stream = _generate_ready_sound()
	player.pitch_scale = 1.0
	player.play()

func play_sword_swing() -> void:
	var player := _get_available_sfx_player()
	player.stream = _generate_sword_sound()
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()

func play_player_hurt() -> void:
	var player := _get_available_sfx_player()
	player.stream = _generate_hurt_sound()
	player.pitch_scale = randf_range(0.95, 1.05)
	player.play()

func play_enemy_shoot() -> void:
	var player := _get_available_sfx_player()
	player.stream = _generate_shoot_sound()
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()

# ============ BACKGROUND MUSIC ============

func play_bgm() -> void:
	# If already playing, don't restart
	if bgm_player.playing:
		return
	
	# Use pre-generated BGM stream
	if bgm_player.stream == null:
		bgm_player.stream = _bgm_stream
	
	# Connect finished signal for looping (only once)
	if not bgm_player.finished.is_connected(_on_bgm_finished):
		bgm_player.finished.connect(_on_bgm_finished)
	
	bgm_player.play()
	bgm_playing = true

func stop_bgm() -> void:
	bgm_player.stop()
	bgm_playing = false

func _on_bgm_finished() -> void:
	if bgm_playing:
		# Restart from beginning for seamless loop
		bgm_player.play()

# ============ PROCEDURAL AUDIO GENERATION ============

func _generate_tone(frequency: float, duration: float, volume: float = 0.5, 
					wave_type: int = 0, attack: float = 0.01, release: float = 0.05) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit audio = 2 bytes per sample
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var envelope := 1.0
		
		# Attack
		if t < attack:
			envelope = t / attack
		# Release
		elif t > duration - release:
			envelope = (duration - t) / release
		
		var sample: float
		match wave_type:
			0:  # Sine wave
				sample = sin(t * frequency * TAU)
			1:  # Square wave
				sample = 1.0 if fmod(t * frequency, 1.0) < 0.5 else -1.0
			2:  # Triangle wave
				sample = abs(fmod(t * frequency * 4.0, 4.0) - 2.0) - 1.0
			3:  # Sawtooth
				sample = fmod(t * frequency * 2.0, 2.0) - 1.0
			_:
				sample = sin(t * frequency * TAU)
		
		sample *= envelope * volume
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_mask_switch_sound() -> AudioStreamWAV:
	# Rising "whoosh" effect
	var sample_rate := 22050
	var duration := 0.15
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var progress := t / duration
		var freq: float = lerp(200.0, 800.0, progress)
		var envelope := sin(progress * PI)
		var sample := sin(t * freq * TAU) * envelope * 0.4
		# Add some harmonics
		sample += sin(t * freq * 2.0 * TAU) * envelope * 0.15
		sample += randf_range(-0.1, 0.1) * envelope * 0.3  # Noise
		
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_death_sound() -> AudioStreamWAV:
	# Descending "wah wah" effect
	var sample_rate := 22050
	var duration := 0.4
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var progress := t / duration
		var freq: float = lerp(400.0, 100.0, progress * progress)
		var envelope := 1.0 - progress
		var sample := sin(t * freq * TAU) * envelope * 0.5
		sample += sin(t * freq * 0.5 * TAU) * envelope * 0.3
		
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_victory_sound() -> AudioStreamWAV:
	# Ascending arpeggio
	var sample_rate := 22050
	var duration := 0.6
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	var notes := [262.0, 330.0, 392.0, 523.0]  # C, E, G, C (octave up)
	var note_duration := duration / notes.size()
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var note_index := mini(int(t / note_duration), notes.size() - 1)
		var freq: float = notes[note_index]
		var note_t := fmod(t, note_duration)
		var envelope := 1.0 - (note_t / note_duration) * 0.5
		
		var sample := sin(t * freq * TAU) * envelope * 0.4
		sample += sin(t * freq * 2.0 * TAU) * envelope * 0.15
		
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_alert_sound() -> AudioStreamWAV:
	# Sharp "ping" alert
	var sample_rate := 22050
	var duration := 0.12
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var progress := t / duration
		var envelope := (1.0 - progress) * (1.0 - progress)
		var freq := 880.0
		var sample := sin(t * freq * TAU) * envelope * 0.5
		sample += sin(t * freq * 1.5 * TAU) * envelope * 0.2
		
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_flee_sound() -> AudioStreamWAV:
	# Quick descending "scared" sound
	var sample_rate := 22050
	var duration := 0.2
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var progress := t / duration
		var freq: float = lerp(600.0, 300.0, progress)
		var envelope := 1.0 - progress * 0.7
		var sample := sin(t * freq * TAU) * envelope * 0.4
		# Vibrato
		sample *= 1.0 + sin(t * 30.0 * TAU) * 0.2
		
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_laser_sound(activating: bool) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.15
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var progress := t / duration
		var freq: float
		if activating:
			freq = lerp(200.0, 500.0, progress)
		else:
			freq = lerp(500.0, 200.0, progress)
		var envelope := sin(progress * PI)
		var sample := sin(t * freq * TAU) * envelope * 0.3
		sample += randf_range(-0.1, 0.1) * envelope * 0.2
		
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_ready_sound() -> AudioStreamWAV:
	# Quick "ding" when cooldown is ready
	var sample_rate := 22050
	var duration := 0.1
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var progress := t / duration
		var envelope := (1.0 - progress)
		var freq := 1200.0
		var sample := sin(t * freq * TAU) * envelope * 0.3
		
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_bgm() -> AudioStreamWAV:
	# Simple ambient loop - low drone with subtle melody
	var sample_rate := 22050
	var duration := 8.0  # 8 second loop
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	# Simple chord progression: Am - F - C - G (in low register)
	var chord_notes := [
		[110.0, 130.81, 164.81],  # Am
		[87.31, 110.0, 130.81],   # F
		[130.81, 164.81, 196.0],  # C
		[98.0, 123.47, 146.83],   # G
	]
	var chord_duration := duration / chord_notes.size()
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var chord_index := int(t / chord_duration) % chord_notes.size()
		var chord: Array = chord_notes[chord_index]
		
		var sample := 0.0
		for note: float in chord:
			sample += sin(t * note * TAU) * 0.15
		
		# Add subtle high melody
		var melody_notes := [440.0, 392.0, 349.23, 329.63]
		var melody_index := int(t / (duration / 8)) % melody_notes.size()
		var melody_note: float = melody_notes[melody_index]
		var melody_envelope := sin(fmod(t, duration / 8) / (duration / 8) * PI) * 0.3
		sample += sin(t * melody_note * TAU) * 0.08 * melody_envelope
		
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	# Enable seamless looping
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

func _generate_sword_sound() -> AudioStreamWAV:
	# Sharp "whoosh" sound for sword swing
	var sample_rate := 22050
	var duration := 0.25
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var progress := t / duration
		var envelope := (1.0 - progress * progress)  # Quick fade
		
		# Sweeping frequency (whoosh effect)
		var freq: float = lerp(200.0, 50.0, progress)
		var sample := sin(t * freq * TAU) * envelope * 0.4
		
		# Add high frequency component
		sample += sin(t * freq * 3.0 * TAU) * envelope * 0.2
		
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_hurt_sound() -> AudioStreamWAV:
	# Quick "ouch" sound
	var sample_rate := 22050
	var duration := 0.15
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var progress := t / duration
		var envelope := (1.0 - progress) * (1.0 - progress)
		
		# Descending tone
		var freq: float = lerp(400.0, 200.0, progress)
		var sample := sin(t * freq * TAU) * envelope * 0.3
		
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_shoot_sound() -> AudioStreamWAV:
	# Sharp "pew" sound for enemy bullets
	var sample_rate := 22050
	var duration := 0.1
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var progress := t / duration
		var envelope := (1.0 - progress) * (1.0 - progress)
		
		# Quick high frequency burst
		var freq: float = lerp(800.0, 400.0, progress)
		var sample := sin(t * freq * TAU) * envelope * 0.25
		
		# Add noise component
		sample += (randf() * 2.0 - 1.0) * envelope * 0.1
		
		var sample_int := int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
