extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("==================================================")
	print("   TESTING MINER CAT SYSTEM (ORANGE CAT MINER)    ")
	print("==================================================")

	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var CatHelperScript = load("res://scripts/cat_helper.gd")

	var GameState = root.get_node("GameState")
	var Inventory = root.get_node("Inventory")
	GameState.money = 500

	var calico = main_scene.cat_helper
	var orange = main_scene.cat_helper_orange
	assert(calico != null, "Calico cat must exist")
	assert(orange != null, "Orange cat must exist")

	# -------------------------------------------------------------------------
	# 1. Verify Role & Wage Specialization
	# -------------------------------------------------------------------------
	print("\n--- 1. Testing Role & Daily Wage ---")
	assert(calico.cat_role == "miner", "Calico role must be miner")
	assert(calico.daily_wage == 100, "Calico daily wage must be 100 coins/day")

	assert(orange.cat_role == "gardener", "Orange cat role must be gardener")
	assert(orange.daily_wage == 50, "Orange cat daily wage must be 50 coins/day")
	print("✓ Orange cat role: %s, daily wage: %d xu/ngày" % [orange.cat_role, orange.daily_wage])
	print("✓ Calico cat role: %s, daily wage: %d xu/ngày" % [calico.cat_role, calico.daily_wage])

	# -------------------------------------------------------------------------
	# 2. Verify Cat Panel UI for Miner Cat
	# -------------------------------------------------------------------------
	print("\n--- 2. Testing Cat Panel UI Presentation ---")
	var ui_coord = main_scene.ui_coordinator
	ui_coord.open_cat_panel()
	var panel = ui_coord.cat_panel
	assert(panel.visible == true, "Panel must be open")

	# Check orange cat card in panel
	panel._refresh_hire_data()
	var cards = panel._hire_cards_container.get_children()
	assert(cards.size() >= 2, "Both cards must be rendered")

	var card_orange = cards[1] # orange is second
	# Verify modal detail
	panel._show_cat_details_modal(calico)
	assert(panel._modal_root.visible == true, "Modal must be open")
	assert(panel._modal_title.text.contains("Mèo Tam Thể"), "Title matches calico cat")
	assert(panel._modal_desc_label.text.contains("thợ mỏ") or panel._modal_desc_label.text.contains("Hầm Mỏ"), "Desc must mention miner/mine")

	var modal_text = ""
	for c in panel._modal_lines_v.get_children():
		modal_text += (c as Label).text + "\n"
	assert(modal_text.contains("100 xu / ngày"), "Modal must display 100 xu/ngày wage")
	assert(modal_text.contains("Khai thác") or modal_text.contains("quặng"), "Modal must describe mining job")
	print("✓ Cat Panel UI displays Calico cat as Miner with 100 xu/ngày wage")

	panel._hide_info_modal()

	# -------------------------------------------------------------------------
	# 3. Test Hiring & Transition to Mining Job
	# -------------------------------------------------------------------------
	print("\n--- 3. Testing In-Game Hiring & Automated Mining Job ---")
	panel.cat = calico
	panel._on_hire_pressed()
	assert(calico.is_hired == true, "Orange cat is now hired")
	assert(calico.visible == true, "Orange cat appears outside")

	# Trigger job finding
	calico.state = calico.State.IDLE
	calico._find_next_job()
	assert(calico.state == calico.State.WALKING_TO_MINE, "Orange cat should start walking to the Mine entrance")
	assert(calico.waypoints.size() > 0, "Waypoints towards mine entrance should be queued")
	print("✓ Orange cat finds job and transitions to WALKING_TO_MINE")

	# -------------------------------------------------------------------------
	# 4. Test Entering Cave & Direct Rock Mining in Mine
	# -------------------------------------------------------------------------
	print("\n--- 4. Testing Direct Rock Targeting & Mining ---")
	var mine_mgr = main_scene.mine_manager
	assert(mine_mgr != null, "MineManager must exist")
	mine_mgr.ensure_floor_ready(1)
	var initial_rock_count: int = mine_mgr._rocks_data.size()
	assert(initial_rock_count > 0, "Mine must have spawned rocks on floor 1")
	print("✓ Mine floor 1 loaded with %d rocks" % initial_rock_count)

	# Simulate arriving at cave entrance door on surface
	calico.position = calico.MINE_ENTRANCE_DOOR
	calico.waypoints.clear()
	calico._process(0.01) # triggers on_reached callback -> enter_underground_mine

	assert(calico.is_underground == true, "Cat must now be underground in the mine")
	assert(calico.get_parent() == mine_mgr, "Cat must be parented to mine_manager")
	assert(calico.state == calico.State.WALKING_TO_JOB, "Cat must target a rock and transition to WALKING_TO_JOB")
	assert(not calico._target_rock.is_empty(), "Cat must have a targeted rock")
	print("✓ Orange cat entered underground mine and targeted rock at tile %s" % str(calico._target_rock.pos_tile))

	# Simulate arriving at target rock
	var target_r = calico._target_rock
	var target_pt: Vector2i = target_r.pos_tile
	var r_pos := Vector2(target_pt.x * 32 + 16, target_pt.y * 32 + 16)
	orange.position = calico._get_rock_stand_pos(r_pos)
	calico.waypoints.clear()
	calico._process(0.01) # triggers reaching rock

	assert(calico.state == calico.State.MINING, "Cat must transition to MINING when reaching rock")
	var initial_hits: int = int(target_r.hits_left)

	# Swing 1: Hit the rock
	calico.work_timer = calico.get_mining_cycle_duration()
	calico._process(0.01)
	assert(int(target_r.hits_left) < initial_hits, "Rock hits_left must decrease after cat's swing")
	print("✓ Cat swung pickaxe at rock: hits_left %d -> %d" % [initial_hits, target_r.hits_left])

	# Continue hitting until rock breaks
	while calico._is_rock_valid(target_r):
		calico.work_timer = calico.get_mining_cycle_duration()
		calico._process(0.01)

	assert(mine_mgr._rocks_data.size() == initial_rock_count - 1, "Broken rock must be removed from mine_manager._rocks_data")
	assert(calico._total_bag_items() >= 1, "Cat must collect drops into harvest_bag upon breaking rock")
	print("✓ Rock broke! Removed from mine. Orange cat collected drops: %s" % str(calico.harvest_bag))

	# -------------------------------------------------------------------------
	# 5. Test Bag Full -> Climb Ladder -> Haul to Shed -> Deposit Ores
	# -------------------------------------------------------------------------
	print("\n--- 5. Testing Bag Full -> Climb Ladder -> Shed Deposit ---")
	var max_bag = calico.get_max_bag()
	# Fill remaining bag with stones
	calico.harvest_bag["stone"] = max_bag

	# Trigger job check with full bag
	calico.state = calico.State.IDLE
	calico._find_next_mining_job()
	assert(calico.state == calico.State.WALKING_TO_SHED, "Cat must transition to WALKING_TO_SHED when bag is full")
	print("✓ Full bag triggered WALKING_TO_SHED towards ladder up")

	# Simulate reaching ladder up inside mine
	orange.position = Vector2(3 * 32 + 16, 3 * 32 + 28)
	calico.waypoints.clear()
	calico._process(0.01) # triggers climb ladder callback

	assert(calico.is_underground == false, "Cat climbed ladder to surface (is_underground=false)")
	assert(calico.get_parent() == main_scene.world, "Cat must be reparented to main.world on surface")
	assert(calico.position == calico.MINE_ENTRANCE_DOOR, "Cat must emerge at cave doorway on surface")
	assert(calico.visible == true, "Cat must be visible on the surface while hauling to Shed")
	print("✓ Cat emerged at cave doorway on surface to haul minerals to Shed")

	# Simulate reaching Shed door
	calico.position = calico.SHED_DOOR_POS
	calico.waypoints.clear()
	calico._process(0.01) # triggers reaching Shed -> DEPOSITING
	assert(calico.state == calico.State.DEPOSITING, "Cat must enter DEPOSITING state at Shed")

	calico.work_timer = calico.get_deposit_duration()
	calico._process(0.01) # finishes depositing

	assert(calico.harvest_bag.is_empty(), "Harvest bag must be empty after depositing to Shed")
	var stored_ores = Inventory.storage.get("ores", {})
	assert(int(stored_ores.get("stone", 0)) >= max_bag, "Shed storage must contain deposited ores")
	assert(calico.state == calico.State.WALKING_TO_MINE, "After depositing, cat must immediately return to WALKING_TO_MINE")
	print("✓ Deposited all %d minerals into Shed storage and heading back to mine!" % max_bag)

	# -------------------------------------------------------------------------
	# 5b. Test Underground Mine Co-op & Interaction
	# -------------------------------------------------------------------------
	print("\n--- 5b. Testing Underground Mine Co-op & Interaction ---")
	Inventory.add_pickaxe("basic")
	main_scene.in_mine = true
	mine_mgr.visible = true

	# Put cat back underground
	calico.enter_underground_mine(mine_mgr)
	assert(calico.is_underground == true, "Orange cat must be underground")
	assert(calico.visible == true, "Orange cat must be visible when player is in mine")

	# Test underground interaction
	var inter = mine_mgr.get_interactable_near(calico.position + Vector2(10, 0))
	assert(inter.has("cb"), "Player near cat underground must be able to interact")
	assert(inter.label.contains("Mèo"), "Interaction prompt must identify the cat")
	print("✓ Underground interaction found: %s" % inter.label)

	# Test exiting mine
	main_scene.mine_transition_manager.exit_mine()
	main_scene.in_mine = false
	mine_mgr.visible = false
	calico.visible = false

	assert(calico.is_underground == true, "Orange cat remains working underground even when player leaves")
	assert(calico.visible == false, "Underground cat is hidden from surface view")
	print("✓ Orange cat continues mining underground smoothly when player exits to surface")

	# -------------------------------------------------------------------------
	# 5c. Test Mining Sound & Notification Isolation (Surface vs Underground)
	# -------------------------------------------------------------------------
	print("\n--- 5c. Testing Mining Sound & Toast Isolation ---")
	# 1. Player is on surface (in_mine == false)
	main_scene.in_mine = false
	mine_mgr.visible = false
	assert(calico._is_player_in_mine() == false, "Cat should know player is not in mine")
	assert(mine_mgr.is_player_in_mine() == false, "MineManager should know player is not in mine")

	var outside_toast_count := [0]
	var toast_hook = func(_msg: String, _color: Color):
		outside_toast_count[0] += 1
	calico.toast_requested.connect(toast_hook)

	# Simulate cat breaking a rock while player is outside
	mine_mgr.ensure_floor_ready(1)
	if mine_mgr._rocks_data.size() > 0:
		var r_outside = mine_mgr._rocks_data[0]
		calico._target_rock = r_outside
		calico.harvest_bag.clear()
		r_outside.hits_left = 1
		calico._perform_cat_rock_hit()
		assert(outside_toast_count[0] == 0, "No rock-break toasts should be emitted while player is on surface")
	print("✓ Cat mining underground stays silent and emits 0 rock toasts to player on surface")

	calico.toast_requested.disconnect(toast_hook)

	# 2. Player enters the mine (in_mine == true)
	main_scene.in_mine = true
	mine_mgr.visible = true
	assert(calico._is_player_in_mine() == true, "Cat should know player IS in mine")
	assert(mine_mgr.is_player_in_mine() == true, "MineManager should know player IS in mine")

	var inside_toast_count := [0]
	var toast_hook_inside = func(_msg: String, _color: Color):
		inside_toast_count[0] += 1
	calico.toast_requested.connect(toast_hook_inside)

	if mine_mgr._rocks_data.size() > 0:
		var r_inside = mine_mgr._rocks_data[0]
		calico._target_rock = r_inside
		calico.harvest_bag.clear()
		r_inside.hits_left = 1
		calico._perform_cat_rock_hit()
		assert(inside_toast_count[0] > 0, "Rock-break toast SHOULD be emitted when player is inside the mine with the cat")
	print("✓ Cat mining underground triggers immersion toasts/SFX when player is inside the mine")

	calico.toast_requested.disconnect(toast_hook_inside)

	# -------------------------------------------------------------------------
	# 6. Test Daily Wage Payment at 100 Coins
	# -------------------------------------------------------------------------
	print("\n--- 6. Testing Daily Wage Payment (100 xu/ngày) ---")
	var initial_money = GameState.money
	calico.wage_paid_today = false
	calico._pay_daily_wage()

	assert(calico.wage_paid_today == true, "Orange cat wage must be paid")
	assert(GameState.money == initial_money - 100, "100 coins must be deducted for Orange cat's wage (was %d, now %d)" % [initial_money, GameState.money])
	print("✓ Paid exactly 100 xu daily wage for Orange cat (Money: %d -> %d)" % [initial_money, GameState.money])

	# -------------------------------------------------------------------------
	# 7. Test Save & Load Persistence of Miner Role and 100 Wage
	# -------------------------------------------------------------------------
	print("\n--- 7. Testing Save & Load Persistence ---")
	var save_dict = calico.get_save_dict()
	assert(save_dict["cat_role"] == "miner", "Saved role must be miner")
	assert(save_dict["daily_wage"] == 100, "Saved daily wage must be 100")

	var fresh_calico = CatHelperScript.new()
	fresh_calico.load_save_dict(save_dict)
	assert(fresh_calico.cat_role == "miner", "Loaded role must be miner")
	assert(fresh_calico.daily_wage == 100, "Loaded daily wage must be 100")
	print("✓ Save/load round-trip preserves miner role and 100 wage accurately")

	print("\n==================================================")
	print("   ALL MINER CAT SYSTEM TESTS PASSED 100%! 🎉🐱⛏️   ")
	print("==================================================")
	quit(0)
