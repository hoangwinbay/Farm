extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	print("=== RUNNING BGM & AUDIO SETTINGS VERIFICATION ===")
	var passed := 0
	var total := 0

	# Test 1: AudioManager autoload exists
	total += 1
	var am = root.get_node_or_null("/root/AudioManager")
	if am != null:
		print("PASS: AudioManager autoload exists at /root/AudioManager")
		passed += 1
	else:
		printerr("FAIL: AudioManager autoload not found!")
		quit(1)
		return

	# Test 2: BGM Player stream and playback
	total += 1
	if am.bgm_player != null and am.bgm_player.stream != null:
		var stream = am.bgm_player.stream
		var len_sec = stream.get_length()
		print("BGM Stream Length: ", len_sec, "s, Loop: ", stream.loop, " Playing: ", am.bgm_player.playing)
		if len_sec > 90.0 and stream.loop and am.bgm_player.playing:
			print("PASS: BGM Player is initialized with loaded looping stream and playing")
			passed += 1
		else:
			printerr("FAIL: BGM Player stream not valid or not playing")
	else:
		printerr("FAIL: bgm_player or stream is null")

	# Test 3: Volume and mute control
	total += 1
	am.set_volume(0.5)
	var expected_db: float = linear_to_db(0.5)
	if is_equal_approx(am.get_volume(), 0.5) and is_equal_approx(am.bgm_player.volume_db, expected_db):
		print("PASS: set_volume(0.5) sets volume and volume_db correctly")
		passed += 1
	else:
		printerr("FAIL: set_volume mismatch: ", am.get_volume(), " db: ", am.bgm_player.volume_db)

	# Test 4: Mute speaker toggle
	total += 1
	am.set_sound_enabled(false)
	if not am.is_sound_enabled() and am.bgm_player.volume_db <= -79.0:
		am.set_sound_enabled(true)
		if am.is_sound_enabled() and is_equal_approx(am.bgm_player.volume_db, expected_db):
			print("PASS: Mute speaker toggle verified (off -> on restores volume)")
			passed += 1
		else:
			printerr("FAIL: Unmuting failed")
	else:
		printerr("FAIL: Muting failed: enabled=", am.is_sound_enabled(), " db=", am.bgm_player.volume_db)

	# Test 5: SettingsPanel strict text verification ("Âm thanh" only)
	total += 1
	var SettingsPanelScript = load("res://scripts/ui/settings_panel.gd")
	var panel = SettingsPanelScript.new()
	root.add_child(panel)
	await process_frame
	panel.open()

	var labels_found: Array[String] = []
	var buttons_found: Array[String] = []
	_gather_ui_text(panel, labels_found, buttons_found)

	print("Labels found in SettingsPanel: ", labels_found)
	print("Buttons found in SettingsPanel: ", buttons_found)

	var has_sound_label := false
	for lbl in labels_found:
		if lbl.strip_edges() == "Âm thanh":
			has_sound_label = true

	var has_speed: bool = (panel.get("speed_label") != null) and (panel.get("speed_cycle_btn") != null) and (panel.get("speed_buttons") != null)
	if has_sound_label and has_speed:
		print("PASS: SettingsPanel contains both 'Âm thanh' audio controls and 5-speed adjustment controls!")
		passed += 1
	else:
		printerr("FAIL: SettingsPanel missing required audio or speed controls!")

	# Test 6: SettingsPanel speaker toggle and slider interactive sync
	total += 1
	var toggle_btn: Button = panel.sound_toggle_btn
	var slider: HSlider = panel.volume_slider
	if toggle_btn != null and slider != null:
		# Test clicking toggle button
		am.set_sound_enabled(true)
		am.set_volume(0.8)
		panel._update_ui()
		if toggle_btn.text == "🔊" and is_equal_approx(slider.value, 0.8):
			toggle_btn.pressed.emit()
			if not am.is_sound_enabled() and toggle_btn.text == "🔇":
				toggle_btn.pressed.emit()
				if am.is_sound_enabled() and toggle_btn.text == "🔊":
					# Test slider change
					slider.value = 0.4
					if is_equal_approx(am.get_volume(), 0.4):
						print("PASS: SettingsPanel toggle button & slider fully control audio and stay in sync")
						passed += 1
					else:
						printerr("FAIL: Slider value change did not update AudioManager: ", am.get_volume())
				else:
					printerr("FAIL: Toggle button unmute failed")
			else:
				printerr("FAIL: Toggle button mute failed")
		else:
			printerr("FAIL: Initial panel state mismatch: toggle=", toggle_btn.text, " slider=", slider.value)
	else:
		printerr("FAIL: sound_toggle_btn or volume_slider is null")

	panel.close()
	panel.queue_free()

	# Test 7: Persistence in user://audio_settings.json
	total += 1
	am.set_volume(0.75)
	am.set_sound_enabled(true)
	am.save_settings()
	var test_am_file = FileAccess.open("user://audio_settings.json", FileAccess.READ)
	if test_am_file != null:
		var content = test_am_file.get_as_text()
		test_am_file.close()
		var d = JSON.parse_string(content)
		if typeof(d) == TYPE_DICTIONARY and d.get("sound_enabled") == true and is_equal_approx(float(d.get("sound_volume")), 0.75):
			print("PASS: Audio settings correctly persisted to user://audio_settings.json")
			passed += 1
		else:
			printerr("FAIL: Parsed json mismatch: ", d)
	else:
		printerr("FAIL: audio_settings.json could not be opened")

	print("\n==========================================")
	print("AUDIO VERIFICATION: %d/%d PASSED" % [passed, total])
	print("==========================================")
	if passed == total:
		print("ALL BGM & AUDIO SETTINGS TESTS PASSED SUCCESSFULLY!")
		quit(0)
	else:
		quit(1)


func _gather_ui_text(node: Node, labels: Array[String], buttons: Array[String]) -> void:
	if node is Label:
		labels.append(node.text)
	elif node is Button:
		buttons.append(node.text)
	for child in node.get_children():
		_gather_ui_text(child, labels, buttons)
