extends Node

var streams := {}

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

func play(name: String, volume_db: float = -7.0) -> void:
	if not streams.has(name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = streams[name]
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

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
