extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("=== TESTING CAT VISIBILITY AND JUNIMO HUT BEHAVIOR ===")

	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var cat = main_scene.cat_helper
	assert(cat != null, "Cat helper must exist")
	var CatHelperScript = load("res://scripts/cat_helper.gd")

	# 1. Hire the cat
	cat.hire()
	assert(cat.is_hired == true, "Cat should be hired")
	print("✓ Cat hired successfully")

	# 2. When cat is at TENT_SLEEP_POS and has no jobs:
	cat.position = CatHelperScript.TENT_SLEEP_POS
	cat.state = CatHelperScript.State.IDLE
	cat._scan_timer = 0.5 # Force scan
	cat._process(0.01)

	assert(cat.visible == false, "Cat must be invisible (hidden inside hut) when idle with no jobs!")
	assert(cat._bubble.visible == false, "Bubble must be hidden when cat is inside hut!")
	print("✓ Cat correctly disappears (visible = false) inside Junimo Hut when idle without jobs")

	# 3. Simulate a job appearing (plant a tile that needs water)
	var farm = main_scene.farm
	assert(farm != null, "Farm must exist")
	var tile = farm.tiles.values()[0]
	tile.tstate = 2 # PLANTED
	tile.watered = false
	tile.growth = 0.5
	tile.has_pest = false

	# Trigger job search
	cat._scan_timer = 0.5
	cat._find_next_job()

	assert(cat.visible == true, "Cat must become visible when a job appears!")
	assert(cat.state == CatHelperScript.State.WALKING_TO_JOB, "Cat should be walking to the job!")
	print("✓ Cat steps out of hut (visible = true) when work appears")

	# 4. Simulate completing the job
	tile.watered = true
	cat._target_tile = tile
	cat._complete_job()
	cat.state = CatHelperScript.State.IDLE
	cat.position = farm.tile_center(tile.coord)

	# Cat is now far from hut and has no more jobs -> should walk to hut
	cat._scan_timer = 0.5
	cat._find_next_job()
	assert(cat.state == CatHelperScript.State.WALKING_TO_TENT, "Cat should walk back to hut when no more jobs")
	print("✓ Cat walks back to Junimo Hut when finished working")

	# Move cat to hut and process arrival
	cat.position = CatHelperScript.TENT_SLEEP_POS
	cat.waypoints.clear()
	cat._process(0.01)
	assert(cat.visible == false, "Cat disappears inside hut upon arrival!")
	print("✓ Cat disappears completely inside hut upon reaching doorstep")

	# 5. Nighttime check
	var GameState = root.get_node("GameState")
	GameState.clock = 1200 # 20:00 (bedtime)
	cat._process(0.01)
	assert(cat.state == CatHelperScript.State.SLEEPING, "Cat state should be SLEEPING")
	assert(cat.visible == false, "Cat must remain hidden inside hut during sleep!")
	print("✓ Cat sleeps inside hut without showing outside")

	print("=== ALL CAT HUT BEHAVIOR CHECKS PASSED 100%! ===")
	quit(0)
