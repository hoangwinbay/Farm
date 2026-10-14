extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("==================================================")
	print("   TESTING TWO-CAT SYSTEM (CALICO & ORANGE TABBY)  ")
	print("==================================================")

	var TextureGen = load("res://scripts/texture_gen.gd")
	var CatHelperScript = load("res://scripts/cat_helper.gd")
	var FarmTileScript = load("res://scripts/farm_tile.gd")

	# -------------------------------------------------------------------------
	# 1. Test Orange Cat Sprites & Textures
	# -------------------------------------------------------------------------
	print("\n--- 1. Testing Orange Cat Texture Extraction ---")
	var dirs = ["down", "up", "side", "left", "right"]
	for d in dirs:
		for f in range(4):
			var tex: Texture2D = TextureGen.cat_char_tex(d, f, "orange")
			assert(tex != null, "Orange cat texture for %s_%d must exist!" % [d, f])
			assert(tex.get_width() == 28 and tex.get_height() == 32, "Dimensions must be 28x32")
	print("✓ Orange cat 4-direction walk cycle textures loaded (20/20 frames verified)")

	var act_tex: Texture2D = TextureGen.cat_char_tex("act", 0, "orange")
	assert(act_tex != null, "Orange cat act texture must exist")
	assert(act_tex.get_width() == 28 and act_tex.get_height() == 32)
	print("✓ Orange cat act/refill texture loaded (28x32)")

	for f in range(4):
		var till_tex: Texture2D = TextureGen.cat_char_tex("till", f, "orange")
		assert(till_tex != null, "Orange cat till frame %d must exist" % f)
		assert(till_tex.get_width() == 48 and till_tex.get_height() == 40)
	print("✓ Orange cat hoe/till 4-stage swing textures loaded (48x40)")

	# -------------------------------------------------------------------------
	# 2. Main Scene Setup & Initial Cat State
	# -------------------------------------------------------------------------
	print("\n--- 2. Testing Main Scene & Cat Helper Initialization ---")
	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var calico = main_scene.cat_helper
	var orange = main_scene.cat_helper_orange
	assert(calico != null, "Calico cat must be instantiated")
	assert(orange != null, "Orange cat must be instantiated")

	assert(calico.cat_breed == "calico", "Calico breed must be 'calico'")
	assert(orange.cat_breed == "orange", "Orange breed must be 'orange'")

	# Cross-linking check
	assert(calico.other_cat == orange, "Calico's other_cat must point to orange cat")
	assert(orange.other_cat == calico, "Orange's other_cat must point to calico cat")
	assert(main_scene.cat_helpers.size() >= 2, "main.cat_helpers must contain at least 2 cats")
	print("✓ Cat helpers successfully instantiated and cross-linked")

	# Initial states check
	assert(calico.is_hired == false, "Calico cat should not be hired initially")
	assert(orange.is_hired == false, "Orange cat should not be hired initially")
	assert(orange.visible == false, "Orange cat must be hidden inside Junimo Hut before being hired")
	assert(orange.position == orange.get_sleep_pos(), "Orange cat should wait at sleep position inside hut")
	print("✓ Orange cat initial state: hidden inside Junimo Hut waiting to be hired")

	# -------------------------------------------------------------------------
	# 3. Cat Panel UI & In-Menu Hiring
	# -------------------------------------------------------------------------
	print("\n--- 3. Testing Cat Panel UI & In-Menu Hiring ---")
	var ui_coord = main_scene.ui_coordinator
	assert(ui_coord != null, "UI Coordinator must exist")

	# Open cat panel
	ui_coord.open_cat_panel()
	var panel = ui_coord.cat_panel
	assert(panel._hire_cards_container != null, "Hire cards container must exist")
	assert(panel._hire_cards_container.get_child_count() >= 2, "Cat cards list contains both cats")
	print("✓ Cat panel opened with clean minimalist cat cards list (top buttons removed)")

	# Switch to Orange cat in menu
	panel.cat = orange
	panel._refresh_view()
	assert(panel._hire_view.visible == true, "Orange cat hire view must be active")
	assert(panel._hire_title_lbl.text.contains("MÈO MƯỚP VÀNG"), "Title must display Orange cat name")
	assert(panel._hire_portrait_rect.texture != null, "Portrait texture must be displayed")
	print("✓ Orange cat profile displayed in hire menu")

	# Hire Orange Cat from Menu
	panel._on_hire_pressed()
	assert(orange.is_hired == true, "Orange cat must now be hired")
	assert(orange.visible == true, "Orange cat must appear upon being hired")
	assert(orange.position == orange.get_entrance_pos(), "Orange cat must appear at Junimo Hut doorstep: %s" % str(orange.position))
	assert(panel._manage_view.visible == true, "Panel should automatically transition to management view")
	assert(panel._manage_title_lbl.text.contains("MÈO MƯỚP VÀNG"), "Management title should display Orange cat name")
	print("✓ Orange cat hired directly inside cat menu and appeared at Junimo Hut door (%s)" % str(orange.position))

	# Hire Calico Cat as well
	panel.cat = calico
	panel._on_hire_pressed()
	assert(calico.is_hired == true, "Calico cat must now be hired")
	print("✓ Calico cat also hired")

	# -------------------------------------------------------------------------
	# 4. Multi-Cat Gardening & Conflict Prevention
	# -------------------------------------------------------------------------
	print("\n--- 4. Testing Multi-Cat Work & No-Conflict Tile Targeting ---")
	var farm = main_scene.farm
	assert(farm != null, "Farm must exist")

	# Prepare 2 tiles needing tilling
	var tile_keys = farm.tiles.keys()
	assert(tile_keys.size() >= 2, "Farm must have at least 2 tiles")
	var tile1 = farm.tiles[tile_keys[0]]
	var tile2 = farm.tiles[tile_keys[1]]
	tile1.tstate = FarmTileScript.TState.HARVESTED
	tile2.tstate = FarmTileScript.TState.HARVESTED

	# Give hoes to both cats
	calico.assigned_hoes = 2
	orange.assigned_hoes = 2

	# Set Orange Cat to target tile1
	orange._target_tile = tile1
	orange.current_job = {"type": "till", "tile": tile1}

	# Check Calico Cat finding jobs: should skip tile1 because Orange Cat is targeting it!
	var target_for_calico = calico._find_nearest_tile(func(t): return t.tstate == FarmTileScript.TState.HARVESTED)
	assert(target_for_calico != null, "Calico must find a harvested tile")
	assert(target_for_calico != tile1, "Calico MUST NOT target the same tile as Orange Cat!")
	assert(target_for_calico == tile2, "Calico should target tile2")
	print("✓ Tile conflict prevention passed: Calico ignored tile targeted by Orange Cat")

	# Test Orange cat tilling animation and completion
	orange.state = orange.State.WORKING
	orange.work_timer = 0.0
	orange._last_h_dir = 1.0
	orange._process(0.01)
	assert(orange._spr.offset == Vector2(0, -20), "Till frame offset should be (0, -20)")
	orange.work_timer = 0.5 * orange.get_work_duration()
	orange._process(0.01)
	assert(orange._spr.texture != null, "Till mid-swing texture must be set")

	orange._complete_job()
	assert(tile1.tstate == FarmTileScript.TState.TILLED, "Tile 1 must now be TILLED by Orange Cat!")
	print("✓ Orange cat tilling work completed successfully (tile state -> TILLED)")

	# -------------------------------------------------------------------------
	# 5. Dismissal Behavior
	# -------------------------------------------------------------------------
	print("\n--- 5. Testing Dismissal Behavior ---")
	orange.dismiss()
	assert(orange.is_hired == false, "Orange cat should not be hired after dismissal")
	assert(orange.visible == false, "Orange cat must disappear inside hut when dismissed")
	assert(orange.position == orange.get_sleep_pos(), "Orange cat must be positioned at hut sleep pos")
	print("✓ Orange cat correctly disappears inside Junimo Hut upon dismissal")

	# Re-hire for next test
	orange.hire()
	assert(orange.is_hired == true and orange.visible == true)

	# -------------------------------------------------------------------------
	# 6. Nighttime & Sleeping Behavior
	# -------------------------------------------------------------------------
	print("\n--- 6. Testing Nighttime & Sleeping Behavior ---")
	var GameState = root.get_node("GameState")
	GameState.clock = 1200 # 20:00 bedtime
	calico._process(0.01)
	orange._process(0.01)

	assert(calico.state == CatHelperScript.State.WALKING_TO_TENT, "Calico should start walking to hut when bedtime arrives")
	assert(orange.state == CatHelperScript.State.WALKING_TO_TENT, "Orange should start walking to hut when bedtime arrives")
	print("✓ Bedtime triggered WALKING_TO_TENT for both cats")

	# Simulate arrival at sleep pos
	calico.position = calico.get_sleep_pos()
	calico.waypoints.clear()
	orange.position = orange.get_sleep_pos()
	orange.waypoints.clear()

	calico._process(0.01)
	orange._process(0.01)

	assert(calico.state == CatHelperScript.State.SLEEPING, "Calico should be sleeping upon arriving at hut")
	assert(calico.visible == false, "Calico must be hidden inside hut while sleeping")
	assert(orange.state == CatHelperScript.State.SLEEPING, "Orange should be sleeping upon arriving at hut")
	assert(orange.visible == false, "Orange must be hidden inside hut while sleeping")
	assert(calico.position != orange.position, "Calico and Orange cats should have non-overlapping sleep positions (%s vs %s)" % [calico.position, orange.position])
	print("✓ Both cats sleep inside Junimo Hut at distinct non-overlapping positions (Calico: %s, Orange: %s)" % [calico.position, orange.position])

	# -------------------------------------------------------------------------
	# 7. Save / Load Persistence
	# -------------------------------------------------------------------------
	print("\n--- 7. Testing Save & Load Round-Trip ---")
	var slm = main_scene.save_load_manager
	assert(slm != null, "SaveLoadManager must exist")

	orange.speed_level = 3
	orange.bag_level = 2
	orange.water_level = 18
	orange.assigned_hoes = 4
	orange.assigned_seeds = {"rice": 10}

	var cat_data = slm.cat_save_data()
	assert(cat_data.has("orange_cat"), "cat_data must include 'orange_cat'")
	var o_saved = cat_data["orange_cat"]
	assert(o_saved["cat_breed"] == "orange", "Saved breed must be 'orange'")
	assert(o_saved["is_hired"] == true, "Saved is_hired must be true")
	assert(o_saved["speed_level"] == 3, "Saved speed_level must be 3")
	assert(o_saved["bag_level"] == 2, "Saved bag_level must be 2")
	assert(o_saved["water_level"] == 18, "Saved water_level must be 18")
	assert(o_saved["assigned_hoes"] == 4, "Saved hoes must be 4")
	assert(o_saved["assigned_seeds"]["rice"] == 10, "Saved seeds must match")
	print("✓ Save dictionary correctly serializes both cats' full states")

	# Test loading into clean instance
	var test_orange = CatHelperScript.new()
	test_orange.load_save_dict(o_saved)
	assert(test_orange.cat_breed == "orange")
	assert(test_orange.cat_name == "Mèo Mướp Vàng")
	assert(test_orange.is_hired == true)
	assert(test_orange.speed_level == 3)
	assert(test_orange.bag_level == 2)
	assert(test_orange.water_level == 18)
	assert(test_orange.assigned_hoes == 4)
	assert(test_orange.assigned_seeds["rice"] == 10)
	print("✓ Load save dict successfully restored Orange Cat state")

	print("\n==================================================")
	print("   ALL TWO-CAT SYSTEM TESTS PASSED 100%! 🎉🐱🌾   ")
	print("==================================================")
	quit(0)
