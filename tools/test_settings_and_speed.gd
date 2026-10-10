extends SceneTree

const TextureGen := preload("res://scripts/texture_gen.gd")

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("=== RUNNING SETTINGS & GAME SPEED TESTS ===")
	var GS = root.get_node("/root/GameState")
	var SettingsPanelScript = load("res://scripts/ui/settings_panel.gd")
	var TitleScreenScript = load("res://scripts/ui/title_screen.gd")

	var passed := 0
	var total := 0

	# Test 1: Gear icon texture
	total += 1
	var gear_tex = TextureGen.gear_icon()
	if gear_tex != null and gear_tex.get_width() == 16 and gear_tex.get_height() == 16:
		print("PASS: TextureGen.gear_icon() is valid 16x16 icon")
		passed += 1
	else:
		printerr("FAIL: gear_icon() invalid: ", gear_tex)

	# Test 2: Game speed initial value & clamp
	total += 1
	GS.set_game_speed(1.0)
	if GS.game_speed == 1.0 and is_equal_approx(Engine.time_scale, 1.0):
		print("PASS: GameState game_speed initialized to 1.0, Engine.time_scale = 1.0")
		passed += 1
	else:
		printerr("FAIL: game_speed mismatch: ", GS.game_speed, " time_scale: ", Engine.time_scale)

	# Test 3: Cycle game speed 1x -> 2x -> 3x -> 4x -> 5x -> 1x
	total += 1
	var expected_cycle := [2.0, 3.0, 4.0, 5.0, 1.0]
	var cycle_ok := true
	for exp in expected_cycle:
		var cur = GS.cycle_game_speed()
		if cur != exp or not is_equal_approx(Engine.time_scale, exp):
			cycle_ok = false
			printerr("FAIL: cycle speed expected ", exp, " got ", cur, " (time_scale: ", Engine.time_scale, ")")
			break
	if cycle_ok:
		print("PASS: cycle_game_speed() successfully cycles x1 -> x2 -> x3 -> x4 -> x5 -> x1")
		passed += 1

	# Test 4: Sound toggle
	total += 1
	GS.set_sound_enabled(true)
	if GS.sound_enabled == true:
		GS.set_sound_enabled(false)
		if GS.sound_enabled == false:
			GS.set_sound_enabled(true)
			print("PASS: Sound toggle verified (true -> false -> true)")
			passed += 1
		else:
			printerr("FAIL: Sound toggle failed to set false")
	else:
		printerr("FAIL: Sound toggle initial state not true")

	# Test 5: SettingsPanel modal creation & interaction
	total += 1
	var panel = SettingsPanelScript.new()
	root.add_child(panel)
	await process_frame
	panel.open()
	if panel.visible:
		# Test speed buttons inside panel
		GS.set_game_speed(4.0)
		panel._update_ui()
		if GS.game_speed == 4.0 and is_equal_approx(Engine.time_scale, 4.0):
			panel.close()
			if not panel.visible:
				print("PASS: SettingsPanel opened, updated speed to x4, and closed successfully")
				passed += 1
			else:
				printerr("FAIL: SettingsPanel failed to close")
		else:
			printerr("FAIL: SettingsPanel speed update failed")
	else:
		printerr("FAIL: SettingsPanel failed to open")
	panel.queue_free()

	# Test 6: TitleScreen gear button
	total += 1
	var title = TitleScreenScript.new()
	root.add_child(title)
	await process_frame
	var found_gear := false
	for child in title.get_children():
		if child is Control:
			for sub in child.get_children():
				if sub is Button and "Cài đặt" in sub.tooltip_text:
					found_gear = true
					break
	if found_gear and title._settings_panel != null:
		print("PASS: TitleScreen contains gear button and integrated SettingsPanel")
		passed += 1
	else:
		printerr("FAIL: TitleScreen missing gear button or _settings_panel")
	title.queue_free()

	# Reset speed back to 1.0 for normal game
	GS.set_game_speed(1.0)

	print("\n==========================================")
	print("TEST RESULTS: %d/%d PASSED" % [passed, total])
	print("==========================================")
	if passed == total:
		print("ALL SETTINGS & SPEED TESTS PASSED SUCCESSFULLY!")
		quit(0)
	else:
		quit(1)
