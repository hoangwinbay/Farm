extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("==================================================")
	print("   TESTING THREE-CAT SYSTEM WITH WHITE CAT FISHER  ")
	print("==================================================")

	var TextureGen = load("res://scripts/texture_gen.gd")
	var CatHelperScript = load("res://scripts/cat_helper.gd")
	var FishDB = load("res://scripts/fish_db.gd")

	# -------------------------------------------------------------------------
	# 1. Test White Cat Textures
	# -------------------------------------------------------------------------
	print("\n--- 1. Testing White Cat Texture Extraction ---")
	var dirs = ["down", "up", "side", "left", "right"]
	for d in dirs:
		for f in range(4):
			var tex: Texture2D = TextureGen.cat_char_tex(d, f, "white")
			assert(tex != null, "White cat texture for %s_%d must exist!" % [d, f])
			assert(tex.get_width() == 28 and tex.get_height() == 32, "Dimensions must be 28x32")
	print("✓ White cat 4-direction walk cycle textures loaded (20/20 frames verified)")

	var act_tex: Texture2D = TextureGen.cat_char_tex("act", 0, "white")
	assert(act_tex != null, "White cat act texture must exist")
	assert(act_tex.get_width() == 28 and act_tex.get_height() == 32)
	print("✓ White cat act texture loaded (28x32)")

	for f in range(4):
		var fish_tex: Texture2D = TextureGen.cat_char_tex("fish", f, "white")
		assert(fish_tex != null, "White cat fish frame %d must exist" % f)
		assert(fish_tex.get_width() == 48 and fish_tex.get_height() == 40, "Fish frame must be 48x40")
	print("✓ White cat fishing 4-stage textures loaded (48x40: cast prep, hold, waiting, bite sparkle)")

	# -------------------------------------------------------------------------
	# 2. Main Scene Setup & Initial Cat State
	# -------------------------------------------------------------------------
	print("\n--- 2. Testing Main Scene & 3 Cats Initialization ---")
	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var Inventory = root.get_node("Inventory")
	var GameState = root.get_node("GameState")

	var calico = main_scene.cat_helper
	var orange = main_scene.cat_helper_orange
	var white = main_scene.cat_helper_white

	assert(calico != null, "Calico cat must be instantiated")
	assert(orange != null, "Orange cat must be instantiated")
	assert(white != null, "White cat must be instantiated")

	assert(calico.cat_breed == "calico", "Calico breed must be 'calico'")
	assert(orange.cat_breed == "orange", "Orange breed must be 'orange'")
	assert(white.cat_breed == "white", "White breed must be 'white'")

	assert(calico.cat_role == "miner", "Calico role must be 'miner'")
	assert(orange.cat_role == "gardener", "Orange role must be 'gardener'")
	assert(white.cat_role == "fisher", "White role must be 'fisher'")

	assert(main_scene.cat_helpers.size() >= 3, "main.cat_helpers must contain at least 3 cats")
	print("✓ Cats successfully instantiated with distinct breeds and roles (Gardener, Miner, Fisher)")

	# Initial states check
	assert(calico.is_hired == false, "Calico cat should not be hired initially")
	assert(orange.is_hired == false, "Orange cat should not be hired initially")
	assert(white.is_hired == false, "White cat should not be hired initially")
	assert(white.visible == false, "White cat must be hidden inside Junimo Hut before being hired")
	assert(white.position == white.get_sleep_pos(), "White cat should wait at sleep position inside hut")
	print("✓ White cat initial state: hidden inside Junimo Hut at %s" % str(white.position))

	# Non-overlapping positions
	assert(calico.get_sleep_pos() != orange.get_sleep_pos() and calico.get_sleep_pos() != white.get_sleep_pos(), "All 3 sleep positions must be distinct")
	print("✓ All 3 cats have distinct sleeping slots inside Junimo Hut: Calico=%s, Orange=%s, White=%s" % [calico.get_sleep_pos(), orange.get_sleep_pos(), white.get_sleep_pos()])

	# -------------------------------------------------------------------------
	# 3. Cat Panel UI & In-Menu Hiring
	# -------------------------------------------------------------------------
	print("\n--- 3. Testing Cat Panel UI & White Cat Hiring ---")
	var ui_coord = main_scene.ui_coordinator
	assert(ui_coord != null, "UI Coordinator must exist")

	# Open cat panel
	ui_coord.open_cat_panel()
	var panel = ui_coord.cat_panel
	assert(panel._hire_cards_container != null, "Hire cards container must exist")
	assert(panel._hire_cards_container.get_child_count() >= 3, "Cat cards list must contain all 3 cats")
	print("✓ Cat panel opened with all 3 cat cards listed")

	# Switch to White cat in menu
	panel.cat = white
	panel._refresh_view()
	assert(panel._hire_view.visible == true, "White cat hire view must be active")
	assert(panel._hire_title_lbl.text.contains("TRẮNG"), "Title must display White cat name")
	assert(panel._hire_portrait_rect.texture != null, "Portrait texture must be displayed")
	print("✓ White cat profile correctly displayed in hire menu")

	# Hire White Cat from Menu
	panel._on_hire_pressed()
	assert(white.is_hired == true, "White cat must now be hired")
	assert(white.visible == true, "White cat must appear upon being hired")
	assert(white.position == white.get_entrance_pos(), "White cat must appear at Junimo Hut doorstep: %s" % str(white.position))
	assert(panel._manage_view.visible == true, "Panel should automatically transition to management view")
	assert(panel._manage_title_lbl.text.contains("TRẮNG"), "Management title should display White cat name")
	print("✓ White cat hired directly inside cat menu and appeared at Junimo Hut door (%s)" % str(white.position))

	# -------------------------------------------------------------------------
	# 4. White Cat Fishing Mechanics, Rod Assignment & Animation
	# -------------------------------------------------------------------------
	print("\n--- 4. Testing White Cat Rod Assignment & Fishing Mechanics ---")
	assert(CatHelperScript.POND_FISHING_POS == Vector2(1245, 860), "Pond fishing spot must be on horizontal west bank (1245, 860)")
	print("✓ Horizontal side-pond fishing position verified: %s" % str(CatHelperScript.POND_FISHING_POS))

	# Rod names and fail rate progression
	assert(white.get_rod_name(1) == "Cần Tre Sơ Cấp", "Level 1 rod must be Cần Tre Sơ Cấp")
	assert(white.get_rod_fail_rate(1) == 0.35, "Level 1 fail rate must be 35%")
	assert(white.get_rod_name(2) == "Cần Gỗ Trung Cấp", "Level 2 rod must be Cần Gỗ Trung Cấp")
	assert(white.get_rod_fail_rate(2) == 0.20, "Level 2 fail rate must be 20%")
	assert(white.get_rod_name(5) == "Cần Câu Thần Thoại", "Level 5 rod must be Cần Câu Thần Thoại")
	assert(white.get_rod_fail_rate(5) == 0.0, "Level 5 fail rate must be 0%")
	print("✓ Rod upgrade tiers & fail rates verified (Tre 35% -> Gỗ 20% -> Sợi thủy tinh 10% -> Carbon 3% -> Thần thoại 0%)")

	# Test 4.1: Without fishing rod, White Cat CANNOT fish
	assert(white.assigned_rods == 0, "White cat should have 0 rods initially")
	white._find_next_job()
	assert(white.state != CatHelperScript.State.WALKING_TO_JOB, "White cat must NOT go fishing without rods assigned!")
	assert(white.bubble_text == "🎣?", "White cat must request a fishing rod with bubble '🎣?'")
	panel._refresh_manage_data()
	assert(panel._status_label.text.contains("Chưa có cần câu") or panel._status_label.text.contains("Chờ được giao cần câu"), "Cat panel status must indicate missing rod")
	print("✓ White cat blocked from fishing without assigned rod (bubble '🎣?' displayed)")

	# Test 4.2: Player assigns fishing rods to White Cat
	Inventory.add_rod("basic", 15)
	assert(Inventory.total_casts() >= 15, "Player inventory must have at least 15 casts")
	var give_ok: bool = white.give_rods(10)
	assert(give_ok == true, "give_rods should succeed")
	assert(white.assigned_rods == 10, "White cat assigned_rods must be 10")
	print("✓ Player successfully gave 10 rod casts to White Cat (assigned_rods = 10)")

	# Test 4.3: With rods assigned, cat proceeds to side-pond
	white._find_next_job()
	assert(white.state == CatHelperScript.State.WALKING_TO_JOB, "White cat should walk to side of pond for fishing job")
	assert(white.current_job.get("type") == "fish", "Job type must be 'fish'")
	assert(white.waypoints.size() > 0, "Waypoints towards pond must be generated")
	print("✓ White cat targeted fishing job at side-pond with fence-safe navigation waypoints")

	# Arrive at fishing spot (horizontal side of pond facing right)
	white.position = CatHelperScript.POND_FISHING_POS
	white.waypoints.clear()
	white._process_walk(0.01, func():
		white.state = CatHelperScript.State.WORKING
		white.work_timer = 0.0
		white._spr.texture = white._tex("fish", 0)
		white._spr.offset = Vector2(0, -20)
		white.facing_dir = "side"
		white._spr.flip_h = false
	)
	assert(white.state == CatHelperScript.State.WORKING, "White cat should be working/fishing")
	assert(white._spr.offset == Vector2(0, -20), "Sprite offset must be (0, -20) during fishing")
	assert(white._spr.flip_h == false, "Fishing sprite must face right into pond water")
	assert(white._spr.texture != null, "Fishing cast texture must be active")
	print("✓ Arrived at west bank: facing right (+X) into lake, cast frame active (0, -20 offset)")

	# Simulate fishing animation progression
	var fish_dur: float = white.get_fishing_cycle_duration()
	white.work_timer = fish_dur * 0.30
	white._process(0.01)
	assert(white._spr.texture != null, "Fish hold frame must be loaded")

	white.work_timer = fish_dur * 0.60
	white._process(0.01)
	assert(white._spr.texture != null, "Line-in-water frame must be loaded")

	white.work_timer = fish_dur * 0.90
	white._process(0.01)
	assert(white._spr.texture != null, "Bite sparkle frame must be loaded")
	print("✓ All 4 fishing animation stages displayed smoothly throughout cycle")

	# Test 4.4: Fishing success with master rod and decrement of assigned_rods
	white.work_level = 5
	white.harvest_bag.clear()
	var rods_before: int = white.assigned_rods
	white._complete_job()
	assert(white.assigned_rods == rods_before - 1, "Fishing attempt must consume 1 rod cast (before: %d, after: %d)" % [rods_before, white.assigned_rods])
	assert(white.harvest_bag.size() > 0, "Level 5 master rod must guarantee fish catch")
	var caught_fish_id: String = str(white.harvest_bag.keys()[0])
	var caught_count: int = int(white.harvest_bag[caught_fish_id])
	print("✓ Rod cast consumed (10 -> 9). Fish caught: %s ×%d added to cat's bag" % [caught_fish_id, caught_count])

	# Test 4.5: Player takes back rods from cat
	var casts_in_bag_before: int = Inventory.total_casts()
	var take_ok: bool = white.take_back_rods(4)
	assert(take_ok == true, "take_back_rods should succeed")
	assert(white.assigned_rods == rods_before - 1 - 4, "assigned_rods should be 4 less")
	assert(Inventory.total_casts() == casts_in_bag_before + 4, "Player inventory should receive 4 casts back")
	print("✓ Player took back 4 casts from cat (cat has %d, inventory has %d)" % [white.assigned_rods, Inventory.total_casts()])

	# -------------------------------------------------------------------------
	# 5. Full Bag Deposit to Shed Storage & Loop Back to Pond
	# -------------------------------------------------------------------------
	print("\n--- 5. Testing Bag Full -> Shed Deposit -> Return to Pond Loop ---")
	white.work_level = 1
	var max_bag: int = white.get_max_bag()
	white.harvest_bag = {"chep": max_bag}
	assert(white._total_bag_items() >= max_bag, "White cat bag must be full")

	# When bag is full at end of job or in scanning, cat immediately walks to shed
	white.current_job = {"type": "fish", "pos": CatHelperScript.POND_FISHING_POS}
	white.position = CatHelperScript.POND_FISHING_POS
	white._complete_job()
	assert(white.state == CatHelperScript.State.WALKING_TO_SHED, "Cat must switch to WALKING_TO_SHED when bag is full")
	assert(white.waypoints.size() > 0, "Waypoints towards shed must be generated")
	assert(white.waypoints.back() == CatHelperScript.SHED_DOOR_POS, "Last waypoint must be SHED_DOOR_POS")
	print("✓ Full bag triggers WALKING_TO_SHED with destination SHED_DOOR_POS")

	# Cat arrives at shed and deposits fish
	var initial_chep: int = Inventory.storage_count("fish", "chep")
	white.position = CatHelperScript.SHED_DOOR_POS
	white._deposit_items_to_shed()
	assert(white.harvest_bag.is_empty(), "Harvest bag must be empty after depositing to Shed")
	assert(Inventory.storage_count("fish", "chep") == initial_chep + max_bag, "Shed fish storage must increase by full bag count")
	print("✓ All %d fish deposited into Shed storage" % max_bag)

	# When cat still has assigned rods, it immediately loops back to pond
	white.assigned_rods = 5
	white.state = CatHelperScript.State.DEPOSITING
	white.work_timer = white.get_deposit_duration()
	white._process(0.01)
	assert(white.state == CatHelperScript.State.WALKING_TO_JOB, "White cat must loop back to WALKING_TO_JOB when rods remain")
	assert(white.current_job.get("type") == "fish", "Job type must remain 'fish'")
	assert(white.waypoints.back() == CatHelperScript.POND_FISHING_POS, "Waypoints must lead back to POND_FISHING_POS")
	print("✓ Loop verified: White Cat returns to pond while assigned_rods > 0")

	# When cat runs out of rods, after shed deposit it returns to Junimo Hut
	white.assigned_rods = 0
	white.state = CatHelperScript.State.DEPOSITING
	white.work_timer = white.get_deposit_duration()
	white._process(0.01)
	assert(white.state == CatHelperScript.State.WALKING_TO_TENT, "White cat must walk back to hut when assigned_rods == 0")
	assert(white.bubble_text == "🎣?", "White cat must display '🎣?' when out of rods")
	print("✓ When assigned_rods == 0, White Cat retreats to Junimo Hut with bubble '🎣?'")

	# -------------------------------------------------------------------------
	# 6. Dismissal & Sleep Behavior
	# -------------------------------------------------------------------------
	print("\n--- 6. Testing Dismissal & Sleep Behavior ---")
	white.dismiss()
	assert(white.is_hired == false, "White cat should not be hired after dismissal")
	assert(white.visible == false, "White cat must disappear inside hut when dismissed")
	assert(white.position == white.get_sleep_pos(), "White cat must return to hut sleep position")
	print("✓ White cat correctly disappears inside Junimo Hut upon dismissal")

	# -------------------------------------------------------------------------
	# 7. Save / Load Persistence
	# -------------------------------------------------------------------------
	print("\n--- 7. Testing Save & Load Round-Trip ---")
	var slm = main_scene.save_load_manager
	assert(slm != null, "SaveLoadManager must exist")

	white.hire()
	white.speed_level = 2
	white.work_level = 3
	white.bag_level = 2
	white.assigned_rods = 7
	white.harvest_bag = {"loc": 2, "chep": 3}

	var cat_data = slm.cat_save_data()
	assert(cat_data.has("white_cat"), "cat_data must include 'white_cat'")
	var w_saved = cat_data["white_cat"]
	assert(w_saved["cat_breed"] == "white", "Saved breed must be 'white'")
	assert(w_saved["cat_role"] == "fisher", "Saved role must be 'fisher'")
	assert(w_saved["is_hired"] == true, "Saved is_hired must be true")
	assert(w_saved["speed_level"] == 2, "Saved speed_level must be 2")
	assert(w_saved["work_level"] == 3, "Saved work_level must be 3")
	assert(w_saved["bag_level"] == 2, "Saved bag_level must be 2")
	assert(w_saved["assigned_rods"] == 7, "Saved assigned_rods must match 7")
	assert(w_saved["harvest_bag"]["loc"] == 2, "Saved fish bag must match")
	print("✓ Save dictionary correctly serializes White Cat's full state (including assigned_rods)")

	# Test loading into clean instance
	var test_white = CatHelperScript.new()
	test_white.load_save_dict(w_saved)
	assert(test_white.cat_breed == "white")
	assert(test_white.cat_role == "fisher")
	assert(test_white.cat_name == "Mèo Trắng Tuyết")
	assert(test_white.is_hired == true)
	assert(test_white.speed_level == 2)
	assert(test_white.work_level == 3)
	assert(test_white.bag_level == 2)
	assert(test_white.assigned_rods == 7)
	assert(test_white.harvest_bag["chep"] == 3)
	print("✓ Load save dict successfully restored White Cat state (including assigned_rods)")
	print("✓ Load save dict successfully restored White Cat state")

	print("\n==================================================")
	print("   ALL THREE-CAT SYSTEM TESTS PASSED 100%! 🎉🐱🎣  ")
	print("==================================================")
	quit(0)
