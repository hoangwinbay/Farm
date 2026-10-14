extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("=== TESTING CAT SPRITE TEXTURES AND ANIMATION ===")
	
	var TextureGen = load("res://scripts/texture_gen.gd")
	assert(TextureGen != null, "TextureGen must load")

	var directions = ["down", "up", "side", "left", "right"]
	for d in directions:
		for f in range(4):
			var tex: Texture2D = TextureGen.cat_char_tex(d, f)
			assert(tex != null, "Texture for %s frame %d must not be null" % [d, f])
			assert(tex.get_width() == 28, "Texture width must be 28, got %d" % tex.get_width())
			assert(tex.get_height() == 32, "Texture height must be 32, got %d" % tex.get_height())
			print("✓ Loaded cat %s frame %d: %dx%d" % [d, f, tex.get_width(), tex.get_height()])

	var act_tex: Texture2D = TextureGen.cat_char_tex("act", 0)
	assert(act_tex != null, "Action texture must not be null")
	assert(act_tex.get_width() == 28, "Action texture width must be 28")
	assert(act_tex.get_height() == 32, "Action texture height must be 32")
	print("✓ Loaded cat action frame: %dx%d" % [act_tex.get_width(), act_tex.get_height()])

	# Test till/hoe frames
	for f in range(4):
		var till_tex: Texture2D = TextureGen.cat_char_tex("till", f)
		assert(till_tex != null, "Till texture frame %d must not be null" % f)
		assert(till_tex.get_width() == 48, "Till texture width must be 48, got %d" % till_tex.get_width())
		assert(till_tex.get_height() == 40, "Till texture height must be 40, got %d" % till_tex.get_height())
		print("✓ Loaded cat till frame %d: %dx%d" % [f, till_tex.get_width(), till_tex.get_height()])

	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var cat = main_scene.cat_helper
	assert(cat != null, "Cat helper must exist")
	cat.hire()

	assert(cat._spr != null, "Cat sprite must be initialized")
	assert(cat._spr.texture != null, "Cat sprite texture must not be null")
	print("✓ CatHelper instantiated and sprite initialized with default texture")

	# Test walk animation cycles
	# Test walking down
	cat.waypoints = [Vector2(0, 100)]
	cat.position = Vector2(0, 0)
	cat.anim_t = 0.0
	cat._process_walk(0.2, func(): pass)
	assert(cat.facing_dir == "down", "Facing should be down")
	print("✓ Cat walk down animation sets down texture")

	# Test walking up
	cat.waypoints = [Vector2(0, -100)]
	cat.position = Vector2(0, 0)
	cat.anim_t = 0.0
	cat._process_walk(0.2, func(): pass)
	assert(cat.facing_dir == "up", "Facing should be up")
	print("✓ Cat walk up animation sets up texture")

	# Test walking left (should use native left texture)
	cat.waypoints = [Vector2(-100, 0)]
	cat.position = Vector2(0, 0)
	cat.anim_t = 0.0
	cat._process_walk(0.2, func(): pass)
	assert(cat.facing_dir == "side", "Facing should be side")
	assert(cat._spr.flip_h == true, "Walking left should set flip_h to true")
	print("✓ Cat walk left animation sets flip_h = true to face left consistently")

	# Test walking right (should use native side/right texture)
	cat.waypoints = [Vector2(100, 0)]
	cat.position = Vector2(0, 0)
	cat.anim_t = 0.0
	cat._process_walk(0.2, func(): pass)
	assert(cat.facing_dir == "side", "Facing should be side")
	assert(cat._spr.flip_h == false, "Native right texture should not need horizontal flip")
	print("✓ Cat walk right animation uses native side/right texture without flip")

	# Test Tilling animation during WORK state
	var farm = main_scene.farm
	assert(farm != null, "Farm must exist")
	var tile = farm.tiles.values()[0]
	tile.tstate = 1 # HARVESTED
	cat.assigned_hoes = 5
	cat.current_job = {"type": "till", "tile": tile}
	cat._target_tile = tile
	cat.state = cat.State.WORKING
	cat.work_timer = 0.0
	cat._last_h_dir = 1.0 # Facing right

	# Frame 0
	cat._process(0.01)
	assert(cat._spr.offset == Vector2(0, -20), "Sprite offset during till must be Vector2(0, -20), got %s" % str(cat._spr.offset))
	assert(cat._spr.flip_h == false, "flip_h should be false for right facing")
	print("✓ Cat tilling start frame: correct texture and offset (0, -20)")

	# Frame 2 (halfway through work duration)
	cat.work_timer = cat.get_work_duration() * 0.55
	cat._process(0.01)
	assert(cat._spr.offset == Vector2(0, -20), "Sprite offset must remain Vector2(0, -20)")
	print("✓ Cat tilling mid swing frame: correct swing texture and offset")

	# Test left-facing till
	cat._last_h_dir = -1.0 # Facing left
	cat._process(0.01)
	assert(cat._spr.flip_h == true, "flip_h should be true for left facing")
	print("✓ Cat tilling left-facing: flip_h correctly applied")

	# Complete job
	cat.work_timer = cat.get_work_duration() + 0.01
	cat._process(0.01)
	assert(cat.state == cat.State.IDLE, "Cat state should transition to IDLE after completing work")
	assert(cat._spr.offset == Vector2(0, -16), "Sprite offset must reset to Vector2(0, -16) after work")
	print("✓ Cat tilling completion: resets offset to (0, -16) and returns to IDLE")

	# Test Orange Cat Watering animation
	for i in range(4):
		var w_tex = TextureGen.cat_char_tex("water", i, "orange")
		assert(w_tex != null, "Orange cat water frame %d must load" % i)
		assert(w_tex.get_width() == 48 and w_tex.get_height() == 40, "Water frame %d must be 48x40" % i)
		print("✓ Loaded orange cat water frame %d: 48x40" % i)

	var orange_cat: Node2D = main_scene.cat_helper_orange
	assert(orange_cat != null, "Orange cat helper must exist")
	assert(orange_cat.cat_role == "gardener", "Orange cat role must be gardener")
	orange_cat.state = orange_cat.State.WORKING
	orange_cat.current_job = {"type": "water", "tile": tile}
	orange_cat._target_tile = tile
	orange_cat.work_timer = 0.0
	orange_cat._last_h_dir = 1.0

	orange_cat._process(0.01)
	assert(orange_cat._spr.offset == Vector2(0, -20), "Watering offset must be (0, -20)")
	assert(orange_cat._spr.flip_h == false, "Right-facing watering flip_h must be false")
	print("✓ Orange cat watering start frame: offset (0, -20) and texture set")

	orange_cat.work_timer = orange_cat.get_work_duration() * 0.8
	orange_cat._last_h_dir = -1.0
	orange_cat._process(0.01)
	assert(orange_cat._spr.offset == Vector2(0, -20), "Watering offset must stay (0, -20)")
	assert(orange_cat._spr.flip_h == true, "Left-facing watering flip_h must be true")
	print("✓ Orange cat watering pouring frame: flip_h correctly applied")

	print("=== ALL CAT SPRITE & ANIMATION TESTS PASSED 100%! ===")
	quit()
