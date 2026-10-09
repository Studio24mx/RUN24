extends Node

var streams := {}
var music_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	streams["shoot"] = _tone(780.0, 0.055, 0.28, 0.22)
	streams["hit"] = _tone(260.0, 0.050, 0.34, -0.35)
	streams["kill"] = _tone(180.0, 0.110, 0.38, -0.55)
	streams["hurt"] = _tone(125.0, 0.160, 0.44, -0.62)
	streams["jump"] = _tone(430.0, 0.075, 0.22, 0.45)
	streams["dash"] = _tone(205.0, 0.095, 0.30, 0.95)
	streams["pickup"] = _tone(620.0, 0.160, 0.30, 0.75)
	streams["special"] = _tone(330.0, 0.220, 0.42, 1.20)
	streams["gate"] = _tone(150.0, 0.260, 0.34, 0.55)
	streams["boss"] = _tone(82.0, 0.620, 0.42, -0.18)
	streams["victory"] = _tone(523.25, 0.520, 0.32, 0.72)
	streams["death"] = _tone(110.0, 0.520, 0.42, -0.78)
	streams["ambient_music"] = _music_loop(false)
	streams["boss_music"] = _music_loop(true)

	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -24.0
	add_child(music_player)
	start_ambient_music()

func play(name: String, volume_db: float = -7.0) -> void:
	if not streams.has(name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = streams[name]
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func start_ambient_music() -> void:
	if not is_instance_valid(music_player):
		return
	if music_player.stream == streams.get("ambient_music") and music_player.playing:
		return
	music_player.stream = streams.get("ambient_music")
	music_player.volume_db = -23.0
	music_player.play()

func start_boss_music() -> void:
	if not is_instance_valid(music_player):
		return
	music_player.stream = streams.get("boss_music")
	music_player.volume_db = -20.0
	music_player.play()

func stop_music() -> void:
	if is_instance_valid(music_player):
		music_player.stop()

func _tone(freq: float, duration: float, amp: float, glide: float = 0.0) -> AudioStreamWAV:
	var rate := 22050
	var count := maxi(int(duration * float(rate)), 1)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(maxi(count - 1, 1))
		var current_freq := freq * (1.0 + glide * (t - 0.5))
		phase += TAU * current_freq / float(rate)
		var envelope := sin(PI * t)
		var harmonic := sin(phase) * 0.78 + sin(phase * 2.01) * 0.16 + sin(phase * 0.51) * 0.06
		var sample := clampf(harmonic * amp * envelope, -1.0, 1.0)
		data.encode_s16(i * 2, int(sample * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func _music_loop(boss_mode: bool) -> AudioStreamWAV:
	var rate := 22050
	var seconds := 8.0
	var count := int(seconds * float(rate))
	var data := PackedByteArray()
	data.resize(count * 2)
	var roots := [55.0, 65.406, 73.416, 49.0] if not boss_mode else [55.0, 58.27, 49.0, 65.406]
	for i in range(count):
		var t := float(i) / float(rate)
		var bar := int(t / 2.0) % roots.size()
		var root: float = roots[bar]
		var local := fmod(t, 2.0)
		var slow_env := 0.55 + 0.45 * sin(PI * local / 2.0)
		var drone := sin(TAU * root * t) * 0.34
		drone += sin(TAU * root * 1.5 * t) * 0.15
		drone += sin(TAU * root * 2.0 * t) * 0.10
		var pulse_rate := 4.0 if boss_mode else 2.0
		var beat_phase := fmod(t * pulse_rate, 1.0)
		var beat_env := exp(-beat_phase * (12.0 if boss_mode else 9.0))
		var pulse := sin(TAU * (root * 4.0) * t) * beat_env * (0.20 if boss_mode else 0.10)
		var shimmer := sin(TAU * (root * 6.0) * t + sin(t * 0.7)) * 0.035
		var sample := (drone * slow_env + pulse + shimmer) * (0.42 if boss_mode else 0.32)
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = count
	wav.data = data
	return wav
