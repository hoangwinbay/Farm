extends SceneTree

var _log_file: FileAccess

func log_msg(msg: String) -> void:
	print(msg)
	if _log_file != null:
		_log_file.store_line(msg)
		_log_file.flush()

func _init() -> void:
	_log_file = FileAccess.open("res://test_result.log", FileAccess.WRITE)
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	log_msg("==================================================")
	log_msg("   TESTING FOUR CATS & TUXEDO SELLER SYSTEM       ")
	log_msg("==================================================")

	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var GameState = root.get_node("GameState")
	var Inventory = root.get_node("Inventory")
	GameState.money = 500

	# 1. Verify all 4 cats exist in main scene
	log_msg("\n--- 1. Testing Four Cats Instantiation ---")
	assert(main_scene.cat_helper_calico != null, "Calico cat must exist")
	assert(main_scene.cat_helper_orange != null, "Orange cat must exist")
	assert(main_scene.cat_helper_white != null, "White cat must exist")
	assert(main_scene.cat_helper_tuxedo != null, "Tuxedo cat must exist")
	assert(main_scene.cat_helpers.size() == 4, "Must have 4 cats registered in cat_helpers")
	log_msg("✓ All 4 cats instantiated successfully: Calico, Orange, White, Tuxedo")

	var calico = main_scene.cat_helper_calico
	var orange = main_scene.cat_helper_orange
	var white = main_scene.cat_helper_white
	var tuxedo = main_scene.cat_helper_tuxedo

	assert(calico.cat_role == "miner", "Calico role must be miner")
	assert(orange.cat_role == "gardener", "Orange role must be gardener")
	assert(white.cat_role == "fisher", "White role must be fisher")
	assert(tuxedo.cat_role == "seller", "Tuxedo role must be seller")
	assert(tuxedo.cat_name == "Mèo Mun Tuxedo", "Tuxedo name must be Mèo Mun Tuxedo")
	assert(tuxedo.daily_wage == 80, "Tuxedo daily wage must be 80")
	log_msg("✓ Cat roles verified: Calico(miner), Orange(gardener), White(fisher), Tuxedo(seller)")

	# 2. Test Tuxedo Cat Hiring & Idle Tent Retreat
	log_msg("\n--- 2. Testing Tuxedo Cat Hiring & Idle Tent Retreat ---")
	assert(tuxedo.is_hired == false, "Tuxedo cat initially not hired")
	tuxedo.hire()
	assert(tuxedo.is_hired == true, "Tuxedo cat must be hired")
	assert(tuxedo.visible == true, "Tuxedo cat initially spawns outside hut entrance")
	assert(tuxedo.position == tuxedo.get_entrance_pos(), "Tuxedo cat must spawn at Junimo hut entrance")

	# Tuxedo has no sell targets and no revenue yet -> must retreat into tent and disappear
	tuxedo._find_next_job()
	assert(tuxedo.state == tuxedo.State.WALKING_TO_TENT, "Tuxedo cat must walk to tent when no work")
	tuxedo.position = tuxedo.get_sleep_pos()
	tuxedo._find_next_job()
	assert(tuxedo.visible == false, "Tuxedo cat must disappear inside Junimo tent when idle")
	log_msg("✓ Tuxedo cat correctly retreats into Junimo hut and disappears when having no work")

	# 3. Test Auto Revenue Collection: Emerges from tent, collects, and returns to tent
	log_msg("\n--- 3. Testing Revenue Collection & Tent Return Cycle ---")
	var sm = main_scene.stall_manager
	assert(sm != null, "Stall manager must exist")
	var money_before: int = GameState.money
	sm.stall_revenue = 180
	sm.update_stall_coin_badge()
	assert(sm.stall_revenue == 180, "Stall revenue must be 180")

	# Cat should wake up and emerge from tent towards stall
	tuxedo._find_next_seller_job()
	assert(tuxedo.visible == true, "Tuxedo cat must emerge and become visible when money is available")
	assert(tuxedo.state == tuxedo.State.WALKING_TO_JOB, "Tuxedo cat must head to stall to collect revenue")
	assert(tuxedo.current_job.get("pos") == tuxedo.STALL_SELLER_POS, "Tuxedo destination must be STALL_SELLER_POS")

	# Arrives at stall and collects
	tuxedo.position = tuxedo.STALL_SELLER_POS
	var rev_before_tuxedo: int = tuxedo.total_sales_revenue
	tuxedo._process_stall_work()

	assert(sm.stall_revenue == 0, "Stall revenue must be 0 after auto-collection")
	assert(GameState.money == money_before + 180, "GameState.money must increase by 180")
	assert(tuxedo.total_sales_revenue == rev_before_tuxedo + 180, "Tuxedo total_sales_revenue must record 180")
	assert(tuxedo.state == tuxedo.State.WALKING_TO_TENT, "Tuxedo cat must immediately walk back to tent after collecting")

	# Arrives at tent
	tuxedo.position = tuxedo.get_sleep_pos()
	tuxedo._find_next_seller_job()
	assert(tuxedo.visible == false, "Tuxedo cat must disappear inside tent again")
	log_msg("✓ Tuxedo cat auto-collected 180 xu and retreated back into hut!")

	# 4. Test Warehouse-Only Restock, 10-Item Crate Limit & Upgrades
	log_msg("\n--- 4. Testing Warehouse Storage Restock & 10-Item Slot Limit ---")
	for i in 6:
		sm.stall_slots[i] = {}

	# Ensure player backpack has no wheat, but warehouse storage has 25 wheat
	Inventory.produce.erase("wheat")
	Inventory.direct_store("produce", "wheat", 25)
	assert(Inventory.storage_count("produce", "wheat") >= 25, "Wheat in warehouse storage must be >= 25")
	assert(Inventory.produce_count("wheat") == 0, "Player backpack has 0 wheat ('lấy đồ từ kho' only)")

	assert(tuxedo.bag_level == 1, "Initial bag level must be 1")
	assert(tuxedo.get_stall_slot_limit() == 10, "Initial slot limit must be 10 items per crate")

	# Set target wheat to 18 (higher than slot limit 10)
	tuxedo.set_sell_target("wheat", 18)
	assert(tuxedo.get_sell_target("wheat") == 18, "Target wheat is 18")

	# Cat should wake up and head to Shed first to withdraw goods from warehouse
	tuxedo._find_next_seller_job()
	assert(tuxedo.visible == true, "Tuxedo emerges to fetch restock goods from warehouse")
	assert(tuxedo.state == tuxedo.State.WALKING_TO_SHED, "Tuxedo must walk to SHED_DOOR_POS first")

	# Arrive at shed and withdraw
	tuxedo.position = tuxedo.SHED_DOOR_POS
	tuxedo._withdraw_items_from_shed()
	assert(int(tuxedo.harvest_bag.get("wheat", 0)) == 10, "Must withdraw exactly 10 wheat (capped at slot limit 10), got %d" % int(tuxedo.harvest_bag.get("wheat", 0)))
	assert(Inventory.storage_count("produce", "wheat") == 15, "Warehouse storage decreased from 25 to 15")
	assert(Inventory.produce_count("wheat") == 0, "Player backpack remains completely untouched (0 wheat)")

	# Tuxedo walks to stall with goods
	tuxedo.position = tuxedo.STALL_SELLER_POS
	tuxedo._process_stall_work()

	# Verify crate has exactly 10 wheat (max limit per slot)
	var slot_count := int(sm.stall_slots[0].get("count", 0))
	assert(slot_count == 10, "Stall crate slot must contain exactly 10 wheat (slot limit), got %d" % slot_count)
	assert(tuxedo.harvest_bag.is_empty(), "Harvest bag must be empty after placing on crate")
	assert(tuxedo.state == tuxedo.State.WALKING_TO_TENT, "Tuxedo cat walks back to tent after stocking")
	tuxedo.position = tuxedo.get_sleep_pos()
	tuxedo._find_next_seller_job()
	assert(tuxedo.visible == false, "Tuxedo cat disappears inside tent")
	log_msg("✓ Crate slot correctly capped at 10 items from warehouse; cat returned to tent")

	# Test Upgrading Bag to Level 2 (Limit expands from 10 to 15)
	log_msg("\n--- 5. Testing Bag Level Upgrade (Limit 10 -> 15 items) ---")
	GameState.money = 1000
	var up_ok: bool = tuxedo.upgrade("bag")
	assert(up_ok == true, "Upgrade bag must succeed")
	assert(tuxedo.bag_level == 2, "Bag level must now be 2")
	assert(tuxedo.get_stall_slot_limit() == 15, "Slot limit for Level 2 must be 15 items")

	# Target was 18, slot has 10, warehouse has 15. Tuxedo should fetch 5 more to reach 15!
	tuxedo._find_next_seller_job()
	assert(tuxedo.visible == true, "Tuxedo emerges to restock upgraded slot")
	assert(tuxedo.state == tuxedo.State.WALKING_TO_SHED, "Tuxedo walks to shed")
	tuxedo.position = tuxedo.SHED_DOOR_POS
	tuxedo._withdraw_items_from_shed()
	assert(int(tuxedo.harvest_bag.get("wheat", 0)) == 5, "Withdrew 5 wheat to reach new limit of 15")
	assert(Inventory.storage_count("produce", "wheat") == 10, "Warehouse storage decreased from 15 to 10")

	tuxedo.position = tuxedo.STALL_SELLER_POS
	tuxedo._process_stall_work()
	slot_count = int(sm.stall_slots[0].get("count", 0))
	assert(slot_count == 15, "Stall crate slot now holds 15 items after Level 2 upgrade, got %d" % slot_count)
	assert(tuxedo.state == tuxedo.State.WALKING_TO_TENT, "Tuxedo cat walks back to tent")
	tuxedo.position = tuxedo.get_sleep_pos()
	tuxedo._find_next_seller_job()
	assert(tuxedo.visible == false, "Tuxedo cat hides back in tent")
	log_msg("✓ Upgraded slot capacity to 15 items verified; cat fetched 5 more from warehouse and returned to tent")

	# 6. Test Cat Panel UI for Tuxedo Cat
	log_msg("\n--- 6. Testing Cat Panel UI with Tuxedo Cat ---")
	var ui_coord = main_scene.ui_coordinator
	ui_coord.open_cat_panel(tuxedo)
	var panel = ui_coord.cat_panel
	assert(panel.visible == true, "Panel must be visible")
	assert(panel._current_mode == "manage", "Panel must open in manage mode for hired cat")
	assert(panel._manage_title_lbl.text.contains("MÈO MUN TUXEDO"), "Panel title must display Tuxedo cat name")

	# Check seller-specific UI elements
	assert(panel._seller_container != null, "_seller_container must exist")
	assert(panel._seller_container.visible == true, "_seller_container must be visible for Tuxedo cat")
	assert(panel._hoe_card.visible == false, "_hoe_card must be hidden for Tuxedo cat")
	assert(panel._right_box.visible == false, "_right_box must be hidden for Tuxedo cat")
	assert(panel._left_box.visible == false, "_left_box must be hidden for Tuxedo cat")
	assert(panel._tab_seeds_btn.text.contains("Sạp"), "Tab button must reflect stall/seller: %s" % panel._tab_seeds_btn.text)
	assert(panel._water_label.text.contains("Trực Sạp Chợ"), "Water label must show stall role status")
	assert(panel._seller_filter_buttons.size() == 5, "Must have 5 category filter buttons")
	log_msg("✓ Tuxedo cat panel UI verified: seller container active, hoe/seeds containers hidden")

	# Test switching to upgrades tab
	panel._switch_tab(1)
	assert(panel._tab_upgrades_container.visible == true, "Upgrades tab must be visible")
	assert(panel._upgrade_cards_box.get_child_count() == 3, "Upgrades must display 3 cards")
	log_msg("✓ Tuxedo cat upgrades tab verified")

	panel.close()
	assert(panel.visible == false, "Panel closed successfully")

	# 7. Test Save & Load Persistence for Tuxedo Cat
	log_msg("\n--- 7. Testing Save & Load Persistence ---")
	tuxedo.set_sell_target("carrot", 15)
	tuxedo.total_sales_revenue = 450
	var save_dict: Dictionary = tuxedo.get_save_dict()

	assert(save_dict.get("cat_breed") == "tuxedo", "Save dict breed must be tuxedo")
	assert(save_dict.get("cat_role") == "seller", "Save dict role must be seller")
	assert(save_dict.get("is_hired") == true, "Save dict is_hired must be true")
	assert(int(save_dict.get("total_sales_revenue")) == 450, "Save dict revenue must be 450")
	var saved_targets: Dictionary = save_dict.get("sell_targets", {})
	assert(int(saved_targets.get("carrot", 0)) == 15, "Saved targets must contain carrot: 15")

	# Create a fresh cat node and load save data
	var fresh_cat = load("res://scripts/cat_helper.gd").new()
	fresh_cat.cat_breed = "tuxedo"
	fresh_cat.cat_role = "seller"
	fresh_cat.load_save_dict(save_dict)

	assert(fresh_cat.is_hired == true, "Loaded cat must be hired")
	assert(fresh_cat.total_sales_revenue == 450, "Loaded cat revenue must be 450")
	assert(fresh_cat.get_sell_target("carrot") == 15, "Loaded cat target for carrot must be 15")
	log_msg("✓ Save/Load serialization and restoration verified for Tuxedo cat")

	log_msg("\n==================================================")
	log_msg("   ALL FOUR CATS & TUXEDO SELLER TESTS PASSED! 🎉  ")
	log_msg("==================================================")
	quit(0)
