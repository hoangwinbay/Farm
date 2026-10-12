extends Node
# Quản lý âm thanh toàn cục (BGM, hiệu ứng âm thanh SFX và cài đặt âm thanh).

const SoundGen := preload("res://scripts/sound_gen.gd")

const BGM_PATH := "res://game_assets/audio/bgm.mp3"
const SETTINGS_PATH := "user://audio_settings.json"
const MAX_SFX_CHANNELS := 12

signal sound_toggled(enabled: bool)
signal volume_changed(volume: float)

var bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

var sound_enabled: bool = true
var sound_volume: float = 0.8
var _last_active_volume: float = 0.8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	_setup_bgm_player()
	_setup_sfx_pool()


func _setup_bgm_player() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_player)

	var stream := _load_stream()
	if stream != null:
		bgm_player.stream = stream
		_apply_audio_state()
		bgm_player.play()
	else:
		push_warning("AudioManager: Không tải được stream nhạc nền từ " + BGM_PATH)


func _setup_sfx_pool() -> void:
	for i in range(MAX_SFX_CHANNELS):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "Master"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_players.append(p)


func play_sfx(kind: String, pitch_scale: float = 1.0, volume_offset_db: float = 0.0) -> void:
	if not sound_enabled or sound_volume <= 0.001:
		return
	var stream: AudioStream = SoundGen.get_sfx(kind)
	if stream == null:
		return
	if _sfx_players.is_empty():
		return

	var player: AudioStreamPlayer = _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()

	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = linear_to_db(sound_volume) + volume_offset_db
	player.play()


func _load_stream() -> AudioStream:
	if FileAccess.file_exists(BGM_PATH):
		var f := FileAccess.open(BGM_PATH, FileAccess.READ)
		if f != null:
			var bytes := f.get_buffer(f.get_length())
			f.close()
			var mp3 := AudioStreamMP3.new()
			mp3.data = bytes
			mp3.loop = true
			return mp3
	if ResourceLoader.exists(BGM_PATH):
		return load(BGM_PATH)
	return null


func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	if sound_enabled and sound_volume <= 0.01:
		sound_volume = _last_active_volume if _last_active_volume > 0.05 else 0.8
	_apply_audio_state()
	save_settings()
	sound_toggled.emit(sound_enabled)
	if has_node("/root/GameState"):
		var gs: Node = get_node("/root/GameState")
		if gs.get("sound_enabled") != null and gs.sound_enabled != sound_enabled:
			gs.sound_enabled = sound_enabled
			if gs.has_signal("sound_toggled"):
				gs.sound_toggled.emit(sound_enabled)


func toggle_sound() -> void:
	set_sound_enabled(not sound_enabled)


func set_volume(vol: float) -> void:
	sound_volume = clampf(vol, 0.0, 1.0)
	if sound_volume > 0.01:
		_last_active_volume = sound_volume
		if not sound_enabled:
			sound_enabled = true
			sound_toggled.emit(true)
			if has_node("/root/GameState"):
				var gs: Node = get_node("/root/GameState")
				if gs.get("sound_enabled") != null:
					gs.sound_enabled = true
					if gs.has_signal("sound_toggled"):
						gs.sound_toggled.emit(true)
	else:
		if sound_enabled:
			sound_enabled = false
			sound_toggled.emit(false)
			if has_node("/root/GameState"):
				var gs: Node = get_node("/root/GameState")
				if gs.get("sound_enabled") != null:
					gs.sound_enabled = false
					if gs.has_signal("sound_toggled"):
						gs.sound_toggled.emit(false)
	_apply_audio_state()
	save_settings()
	volume_changed.emit(sound_volume)


func get_volume() -> float:
	return sound_volume


func is_sound_enabled() -> bool:
	return sound_enabled


func _apply_audio_state() -> void:
	if bgm_player == null:
		return
	if not sound_enabled or sound_volume <= 0.001:
		bgm_player.volume_db = -80.0
	else:
		bgm_player.volume_db = linear_to_db(sound_volume)


func save_settings() -> void:
	var data := {
		"sound_enabled": sound_enabled,
		"sound_volume": sound_volume,
		"last_active_volume": _last_active_volume,
	}
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		if parsed.has("sound_enabled"):
			sound_enabled = bool(parsed["sound_enabled"])
		if parsed.has("sound_volume"):
			sound_volume = float(parsed["sound_volume"])
		if parsed.has("last_active_volume"):
			_last_active_volume = float(parsed["last_active_volume"])
