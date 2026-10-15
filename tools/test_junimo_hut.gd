extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	var f := FileAccess.open("d:/Farm/test_output.txt", FileAccess.WRITE)
	f.store_line("=== TESTING JUNIMO HUT IN REAL GAME SCENE ===")
	print("=== TESTING JUNIMO HUT IN REAL GAME SCENE ===")

	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var TextureGen = load("res://scripts/texture_gen.gd")
	var WorldBuilderScript = load("res://scripts/world_builder.gd")
	var CatHelperScript = load("res://scripts/cat_helper.gd")
	var MinimapScript = load("res://scripts/ui/minimap.gd")

	# 1. Texture check
	var hut_tex = TextureGen.get_tex("junimo_hut")
	assert(hut_tex != null, "Texture junimo_hut should not be null")
	assert(hut_tex.get_width() == 48 and hut_tex.get_height() == 64, "Hut size should be 48x64")
	print("✓ Texture junimo_hut verified (48x64)")
	f.store_line("✓ Texture junimo_hut verified (48x64)")

	# 2. Position constant check
	assert(WorldBuilderScript.JUNIMO_HUT_POS == Vector2(1365, 195), "JUNIMO_HUT_POS must be (1365, 195)")
	assert(WorldBuilderScript.TENT_POS == Vector2(1365, 195), "TENT_POS must alias JUNIMO_HUT_POS")
	assert(CatHelperScript.TENT_SLEEP_POS == Vector2(1365, 195), "CatHelper TENT_SLEEP_POS must be (1365, 195)")
	print("✓ All position constants verified at Vector2(1365, 195)")
	f.store_line("✓ All position constants verified at Vector2(1365, 195)")

	# 3. Junimo Hut node and collision in world
	var world = main_scene.world
	assert(world != null, "World should exist")

	var hut_node = world.get_node_or_null("JunimoHut")
	assert(hut_node != null, "JunimoHut node must exist in world")
	assert(hut_node.position == Vector2(1365, 195), "JunimoHut position must be (1365, 195)")

	var has_col := false
	for child in hut_node.get_children():
		if child is CollisionShape2D:
			has_col = true
			var shape = child.shape as RectangleShape2D
			assert(shape != null, "Shape must be RectangleShape2D")
			assert(shape.size == Vector2(48, 24), "Shape size should be (48, 24)")
	assert(has_col, "JunimoHut must have collision shape")
	print("✓ Junimo Hut StaticBody2D and collision verified in world")
	f.store_line("✓ Junimo Hut StaticBody2D and collision verified in world")

	# Check old tent is removed
	var residence_col = world.get_node_or_null("ResidenceCollision")
	assert(residence_col != null, "ResidenceCollision should exist")
	for child in residence_col.get_children():
		if child is CollisionShape2D:
			assert(child.position != Vector2(766, 220), "Old tent collision at (766, 220) must be removed!")
	print("✓ Old tent decor and collision verified removed from (766, 220)")
	f.store_line("✓ Old tent decor and collision verified removed from (766, 220)")

	# 4. Interaction check
	var im = main_scene.interaction_manager
	assert(im != null, "InteractionManager must exist")
	var found_hut_interact := false
	var found_old_tent_interact := false
	for inter in im.interactables:
		if inter.pos == Vector2(1365, 195):
			found_hut_interact = true
			assert("Junimo" in inter.label, "Interact label should mention Junimo")
		if inter.pos == Vector2(766, 248):
			found_old_tent_interact = true

	assert(found_hut_interact, "Must find Junimo Hut interactable at (1365, 195)")
	assert(not found_old_tent_interact, "Must NOT find old tent interactable at (766, 248)")
	print("✓ Interaction manager verified: prompt at (1365, 195) is active")
	f.store_line("✓ Interaction manager verified: prompt at (1365, 195) is active")

	# 5. Minimap check
	assert(MinimapScript.NODES["tent"] == Vector2(1365, 195), "Minimap NODES['tent'] must be (1365, 195)")
	assert(MinimapScript.NODES["j_tent"] == Vector2(1365, 470), "Minimap NODES['j_tent'] must be (1365, 470)")

	var found_poi := false
	for poi in MinimapScript.POIS:
		if poi.id == "tent":
			found_poi = true
			assert(poi.pos == Vector2(1365, 195), "Minimap POI tent pos must be (1365, 195)")
			assert("Junimo" in poi.name, "POI name should mention Junimo")
	assert(found_poi, "Minimap POI tent must exist")
	print("✓ Minimap POIs and route nodes verified at (1365, 195)")
	f.store_line("✓ Minimap POIs and route nodes verified at (1365, 195)")

	f.store_line("=== ALL JUNIMO HUT CHECKS PASSED 100%! ===")
	f.close()
	print("=== ALL JUNIMO HUT CHECKS PASSED 100%! ===")
	quit(0)
