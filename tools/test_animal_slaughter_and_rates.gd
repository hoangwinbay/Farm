extends SceneTree

const PoultryDB := preload("res://scripts/poultry_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("=== RUNNING ANIMAL SLAUGHTER & 90S RATE TESTS ===")
	var Inv = root.get_node("/root/Inventory")
	var GS = root.get_node("/root/GameState")

	var total_tests := 0
	var passed_tests := 0

	# Test 1: Check interval is 90.0s for all 4 animals
	total_tests += 1
	var all_90s := true
	for sid in ["chicken", "cow", "pig", "sheep"]:
		var a := PoultryDB.get_animal(sid)
		if float(a.get("interval", 0.0)) != 90.0:
			all_90s = false
			print("FAIL: %s interval is %s, expected 90.0" % [sid, str(a.get("interval"))])
	if all_90s:
		print("PASS: All animals have 90.0s interval")
		passed_tests += 1

	# Test 2: Check pig has no regular periodic product
	total_tests += 1
	var pig_data := PoultryDB.get_animal("pig")
	if str(pig_data.get("product", "")) == "":
		print("PASS: Pig has no periodic product (product is empty)")
		passed_tests += 1
	else:
		print("FAIL: Pig should have empty periodic product, found: ", pig_data.get("product"))

	# Test 3: Check meat IDs and yields
	total_tests += 1
	var meat_ok := true
	var expected_meats := {
		"chicken": "thit_ga",
		"cow": "thit_bo",
		"pig": "thit_lon",
		"sheep": "thit_cuu"
	}
	for sid in expected_meats:
		var mid := PoultryDB.get_animal_meat_id(sid)
		if mid != expected_meats[sid]:
			meat_ok = false
			print("FAIL: %s meat id is %s, expected %s" % [sid, mid, expected_meats[sid]])
		var mqty := PoultryDB.get_animal_meat_qty(sid)
		if mqty <= 0:
			meat_ok = false
			print("FAIL: %s meat qty is %d" % [sid, mqty])
	if meat_ok:
		print("PASS: Meat IDs and yields correctly configured for all 4 species")
		passed_tests += 1

	# Test 4: Check Stardew Valley meat assets load properly
	total_tests += 1
	var assets_ok := true
	for mid in ["thit_bo", "thit_lon", "thit_ga", "thit_cuu"]:
		var pinfo := PoultryDB.get_product_info(mid)
		if pinfo.is_empty():
			assets_ok = false
			print("FAIL: get_product_info empty for ", mid)
		var tex := TextureGen.get_product_icon(mid)
		if tex == null:
			assets_ok = false
			print("FAIL: TextureGen failed to load texture for ", mid)
	if assets_ok:
		print("PASS: All 4 Stardew Valley meat icons and product info loaded properly")
		passed_tests += 1

	# Test 5: Inventory ticking - Pig produces nothing and gets hungry immediately
	total_tests += 1
	Inv.animals.clear()
	Inv.feed = 100
	GS.money = 100000
	Inv.coop_tiers["pig"] = 1
	Inv.buy_animal("pig")
	var my_pig: Dictionary = Inv.animals[0]
	Inv.feed_animal_by_dict(my_pig)
	if not my_pig.fed or my_pig.times_fed != 1:
		print("FAIL: Pig failed to feed")
	else:
		# Tick 90.0s
		Inv.tick_animals(90.1)
		# Pig should have ready == 0, fed == false (hungry immediately)
		if int(my_pig.ready) == 0 and not my_pig.fed:
			print("PASS: Pig digested for 90s, produced nothing (ready=0) and became hungry immediately (fed=false)")
			passed_tests += 1
		else:
			print("FAIL: Pig state unexpected after 90s: ready=%s, fed=%s" % [str(my_pig.ready), str(my_pig.fed)])

	# Test 6: Statistical rate test for chicken/cow/sheep (50% product, 50% hungry)
	total_tests += 1
	var trials := 400
	var ready_count := 0
	var hungry_count := 0
	for i in range(trials):
		var test_anim := {
			"id": "chicken",
			"progress": 0.0,
			"ready": 0,
			"fed": true,
			"is_baby": false,
			"grow_progress": 0.0,
			"is_sheared": false,
			"times_fed": 1,
		}
		Inv.animals = [test_anim]
		Inv.tick_animals(90.1)
		if int(test_anim.ready) == 1:
			ready_count += 1
		elif not test_anim.fed:
			hungry_count += 1
	var rate := float(ready_count) / float(trials)
	print("Rate test: %d/%d (%.1f%%) produced product, %d/%d (%.1f%%) hungry immediately" % [ready_count, trials, rate * 100.0, hungry_count, trials, (float(hungry_count)/float(trials)) * 100.0])
	if ready_count + hungry_count == trials and rate >= 0.40 and rate <= 0.60:
		print("PASS: Chicken 50% rate test verified (~50% product, ~50% hungry immediately)")
		passed_tests += 1
	else:
		print("FAIL: 50% rate test out of range or unhandled state")

	# Test 7: Feed count tracking across 5 feeds
	total_tests += 1
	var tracking_ok := true
	var test_cow := {
		"id": "cow",
		"progress": 0.0,
		"ready": 0,
		"fed": false,
		"is_baby": false,
		"grow_progress": 0.0,
		"is_sheared": false,
		"times_fed": 0,
	}
	Inv.animals = [test_cow]
	for feed_step in range(1, 6):
		var fed_res = Inv.feed_animal_by_dict(test_cow)
		if not fed_res or int(test_cow.times_fed) != feed_step:
			tracking_ok = false
			print("FAIL: feed_step %d tracking failed: fed=%s, times_fed=%d" % [feed_step, str(fed_res), int(test_cow.times_fed)])
		# Reset fed for next test feed
		test_cow.fed = false
	if tracking_ok and int(test_cow.times_fed) == 5:
		print("PASS: times_fed accurately tracked to 5 feeds")
		passed_tests += 1

	# Test 8: Slaughtering requirements (< 5 feeds fails, >= 5 feeds succeeds)
	total_tests += 1
	var slaughter_ok := true
	var underage_pig := {
		"id": "pig",
		"progress": 0.0,
		"ready": 0,
		"fed": false,
		"is_baby": false,
		"grow_progress": 0.0,
		"is_sheared": false,
		"times_fed": 4, # only 4 feeds!
	}
	Inv.animals = [underage_pig]
	var res_underage = Inv.slaughter_animal(underage_pig)
	if bool(res_underage.get("ok", false)):
		slaughter_ok = false
		print("FAIL: Animal with times_fed=4 should NOT be allowed to slaughter!")

	# Now fatten to 5 feeds
	underage_pig.times_fed = 5
	var initial_meat = Inv.produce_count("thit_lon")
	var res_ready = Inv.slaughter_animal(underage_pig)
	if not bool(res_ready.get("ok", false)):
		slaughter_ok = false
		print("FAIL: Animal with times_fed=5 failed to slaughter: ", res_ready.get("msg"))
	elif Inv.produce_count("thit_lon") != initial_meat + 10:
		slaughter_ok = false
		print("FAIL: Meat quantity not credited correctly: ", Inv.produce_count("thit_lon"))
	elif Inv.animals.size() != 0:
		slaughter_ok = false
		print("FAIL: Animal was not removed from pen upon slaughter!")

	if slaughter_ok:
		print("PASS: Slaughter rules verified (blocks <5 feeds, permits >=5 feeds, removes animal, gives meat)")
		passed_tests += 1

	# Test 9: Save & load preserves times_fed
	total_tests += 1
	var cow_save := {
		"id": "cow",
		"progress": 42.0,
		"ready": 0,
		"fed": true,
		"is_baby": false,
		"grow_progress": 0.0,
		"is_sheared": false,
		"times_fed": 5,
	}
	Inv.animals = [cow_save]
	var saved_state = Inv.get_state()
	Inv.animals = []
	Inv.set_state(saved_state)
	if Inv.animals.size() == 1 and int(Inv.animals[0].get("times_fed", 0)) == 5:
		print("PASS: times_fed preserved across get_state and set_state")
		passed_tests += 1
	else:
		print("FAIL: times_fed lost on load: ", Inv.animals)

	print("\n==========================================")
	print("TEST RESULTS: %d/%d PASSED" % [passed_tests, total_tests])
	print("==========================================")

	if passed_tests == total_tests:
		print("ALL ANIMAL SLAUGHTER & RATES TESTS PASSED SUCCESSFULLY!")
	else:
		print("SOME TESTS FAILED!")
	quit(0 if passed_tests == total_tests else 1)
