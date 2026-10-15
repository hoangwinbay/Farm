extends RefCounted
# Hệ thống quản lý và sinh âm thanh hiệu ứng (Sound Effect Manager).
# Ưu tiên nạp trực tiếp âm thanh nguyên bản chính thống chuẩn Stardew Valley từ game_assets/audio/.
# Có cơ chế tổng hợp sóng âm dự phòng nếu file âm thanh chưa sẵn sàng.

static var _cache: Dictionary = {}
const AUDIO_DIR := "res://game_assets/audio/"
const MIX_RATE := 22050


static func get_sfx(kind: String) -> AudioStreamWAV:
	if _cache.has(kind):
		return _cache[kind]

	# 1. Thử tải file WAV gốc chuẩn Stardew Valley từ thư mục tài nguyên
	var wav_path := AUDIO_DIR + "sfx_" + kind + ".wav"
	if kind == "catch_pest":
		wav_path = AUDIO_DIR + "sfx_bush_rustle.wav"

	var loaded_wav := _load_wav_file(wav_path)
	if loaded_wav != null:
		_cache[kind] = loaded_wav
		return loaded_wav

	# 2. Dự phòng: tổng hợp âm thanh bằng thuật toán nếu không có file WAV
	var synth_wav := _synthesize(kind)
	if synth_wav != null:
		_cache[kind] = synth_wav
	return synth_wav


static func _load_wav_file(path: String) -> AudioStreamWAV:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var bytes := f.get_buffer(f.get_length())
	f.close()
	return _parse_riff_wav(bytes)


static func _parse_riff_wav(bytes: PackedByteArray) -> AudioStreamWAV:
	if bytes.size() < 44:
		return null
	var riff := bytes.slice(0, 4).get_string_from_ascii()
	var wave := bytes.slice(8, 12).get_string_from_ascii()
	if riff != "RIFF" or wave != "WAVE":
		return null

	var offset := 12
	var channels := 1
	var sample_rate := 44100
	var bits_per_sample := 16
	var audio_data := PackedByteArray()

	while offset + 8 <= bytes.size():
		var chunk_id := bytes.slice(offset, offset + 4).get_string_from_ascii()
		var chunk_size := bytes.decode_u32(offset + 4)
		offset += 8
		if chunk_id == "fmt ":
			channels = bytes.decode_u16(offset + 2)
			sample_rate = bytes.decode_u32(offset + 4)
			bits_per_sample = bytes.decode_u16(offset + 14)
		elif chunk_id == "data":
			audio_data = bytes.slice(offset, offset + chunk_size)
			break
		offset += chunk_size
		if chunk_size % 2 == 1:
			offset += 1

	if audio_data.is_empty():
		return null

	var stream := AudioStreamWAV.new()
	stream.data = audio_data
	stream.mix_rate = sample_rate
	stream.stereo = (channels == 2)
	stream.format = AudioStreamWAV.FORMAT_16_BITS if bits_per_sample == 16 else AudioStreamWAV.FORMAT_8_BITS
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream


static func _synthesize(kind: String) -> AudioStreamWAV:
	var samples: PackedFloat32Array = PackedFloat32Array()

	match kind:
		"hoe":
			var dur := 0.24
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			var rng := RandomNumberGenerator.new()
			rng.seed = 12345
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 20.0)
				var freq := 95.0 * (1.0 - t * 2.8)
				var thud := sin(t * maxf(freq, 35.0) * TAU) * 0.75
				var crunch := (rng.randf() * 2.0 - 1.0) * exp(-t * 32.0) * 0.45
				samples[i] = (thud + crunch) * env

		"bush_rustle", "catch_pest":
			var dur := 0.32
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			var rng := RandomNumberGenerator.new()
			rng.seed = 67890
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env1 := exp(-pow((t - 0.07) * 32.0, 2))
				var env2 := exp(-pow((t - 0.19) * 28.0, 2)) * 0.85
				var env := env1 + env2
				var noise := (rng.randf() * 2.0 - 1.0)
				samples[i] = noise * 0.55 * env

		"water":
			var dur := 0.36
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			var rng := RandomNumberGenerator.new()
			rng.seed = 98765
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := (1.0 - t / dur) * (1.0 - exp(-t * 45.0))
				var f := 340.0 + sin(t * 50.0 * TAU) * 110.0
				var trickle := sin(t * f * TAU) * 0.45
				var splash := (rng.randf() * 2.0 - 1.0) * 0.32
				samples[i] = (trickle + splash) * env * 0.65

		"step":
			var dur := 0.08
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			var rng := RandomNumberGenerator.new()
			rng.seed = 43210
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 65.0)
				var low := sin(t * 85.0 * TAU) * 0.5
				var tap := (rng.randf() * 2.0 - 1.0) * 0.35
				samples[i] = (low + tap) * env * 0.4

		"fish_cast":
			var dur := 0.22
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := sin((t / dur) * PI)
				var freq := 220.0 + sin((t / dur) * PI) * 520.0
				samples[i] = sin(t * freq * TAU) * env * 0.42

		"fish_plop":
			var dur := 0.18
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 26.0)
				var freq := 580.0 - t * 1800.0
				samples[i] = sin(t * maxf(freq, 110.0) * TAU) * env * 0.62

		"fish_bite":
			var dur := 0.24
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 18.0)
				var s1 := sin(t * 880.0 * TAU) * 0.45
				var s2 := sin(t * 1320.0 * TAU) * 0.35
				samples[i] = (s1 + s2) * env * 0.6

		"fish_catch":
			var dur := 0.45
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := (1.0 - t / dur)
				var freq := 440.0
				if t > 0.12: freq = 554.37
				if t > 0.24: freq = 659.25
				if t > 0.34: freq = 880.0
				samples[i] = sin(t * freq * TAU) * env * 0.55

		"harvest":
			var dur := 0.16
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 30.0)
				var freq := 260.0 + t * 2400.0
				samples[i] = sin(t * freq * TAU) * env * 0.65

		"plant":
			var dur := 0.14
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 36.0)
				var pat := sin(t * 220.0 * TAU) * 0.4
				var gravel := sin(t * 480.0 * TAU) * 0.25
				samples[i] = (pat + gravel) * env * 0.5

		"pickaxe":
			var dur := 0.20
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			var rng := RandomNumberGenerator.new()
			rng.seed = 24680
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 28.0)
				var ping := sin(t * 1280.0 * TAU) * 0.5 + sin(t * 2400.0 * TAU) * 0.25
				var stone := (rng.randf() * 2.0 - 1.0) * exp(-t * 45.0) * 0.35
				samples[i] = (ping + stone) * env * 0.62

		"rock_break":
			var dur := 0.30
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			var rng := RandomNumberGenerator.new()
			rng.seed = 13579
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 16.0)
				var crack := (rng.randf() * 2.0 - 1.0) * 0.5
				var rumble := sin(t * 65.0 * TAU) * 0.4
				samples[i] = (crack + rumble) * env * 0.6

		"eat":
			var dur := 0.24
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			var rng := RandomNumberGenerator.new()
			rng.seed = 86420
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env1 := exp(-pow((t - 0.05) * 36.0, 2))
				var env2 := exp(-pow((t - 0.15) * 36.0, 2)) * 0.85
				var env := env1 + env2
				var crunch := (rng.randf() * 2.0 - 1.0) * 0.52
				samples[i] = crunch * env * 0.55

		"coin":
			var dur := 0.28
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 15.0)
				var s1 := sin(t * 987.77 * TAU) * 0.42
				var s2 := sin(t * 1318.51 * TAU) * 0.42
				samples[i] = (s1 + s2) * env * 0.52

		"meow":
			var dur := 0.36
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := sin((t / dur) * PI)
				var freq := 430.0 + sin((t / dur) * PI * 0.8) * 220.0
				var v1 := sin(t * freq * TAU) * 0.55
				var v2 := sin(t * freq * 2.0 * TAU) * 0.22
				samples[i] = (v1 + v2) * env * 0.5

		"feed":
			var dur := 0.26
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			var rng := RandomNumberGenerator.new()
			rng.seed = 55555
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 18.0)
				var grain := (rng.randf() * 2.0 - 1.0) * 0.45
				var pat := sin(t * 260.0 * TAU) * 0.3
				samples[i] = (grain + pat) * env * 0.5

		"scoop_water":
			var dur := 0.32
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			var rng := RandomNumberGenerator.new()
			rng.seed = 77777
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := (1.0 - t / dur) * (1.0 - exp(-t * 30.0))
				var swirl := sin(t * (240.0 + sin(t * 30.0 * TAU) * 60.0) * TAU) * 0.5
				var splash := (rng.randf() * 2.0 - 1.0) * 0.25
				samples[i] = (swirl + splash) * env * 0.55

		"cow":
			var dur := 0.65
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := sin((t / dur) * PI) * (1.0 - t * 0.4)
				var freq := 115.0 - sin(t * 12.0) * 15.0
				samples[i] = (sin(t * freq * TAU) * 0.6 + sin(t * freq * 2.0 * TAU) * 0.25) * env * 0.55

		"chicken":
			var dur := 0.22
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 22.0)
				var freq := 480.0 + sin(t * 70.0 * TAU) * 120.0
				samples[i] = sin(t * freq * TAU) * env * 0.5

		"sheep":
			var dur := 0.48
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := sin((t / dur) * PI)
				var freq := 260.0 + sin(t * 28.0 * TAU) * 45.0
				samples[i] = sin(t * freq * TAU) * env * 0.5

		"pig":
			var dur := 0.32
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			var rng := RandomNumberGenerator.new()
			rng.seed = 33333
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 14.0)
				var snort := (rng.randf() * 2.0 - 1.0) * 0.35
				var low := sin(t * 135.0 * TAU) * 0.45
				samples[i] = (low + snort) * env * 0.52

		"duck":
			var dur := 0.28
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				var env := exp(-t * 16.0)
				var freq := 320.0 + sin(t * 40.0 * TAU) * 80.0
				samples[i] = (sin(t * freq * TAU) * 0.6 + sin(t * freq * 1.5 * TAU) * 0.3) * env * 0.5

		_:
			var dur := 0.1
			var n := int(MIX_RATE * dur)
			samples.resize(n)
			for i in range(n):
				var t := float(i) / MIX_RATE
				samples[i] = sin(t * 440.0 * TAU) * exp(-t * 40.0) * 0.5

	return _samples_to_wav(samples, MIX_RATE)


static func _samples_to_wav(samples: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var s := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, s)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = bytes
	return wav
