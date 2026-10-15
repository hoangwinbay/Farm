extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("==================================================")
	print("   TESTING MINIMALIST SHOP-STYLE CAT PANEL UI     ")
	print("==================================================")

	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var GameState = root.get_node("GameState")
	var Inventory = root.get_node("Inventory")
	GameState.money = 200

	var ui_coord = main_scene.ui_coordinator
	assert(ui_coord != null, "UI Coordinator must exist")

	# 1. Open Cat Panel
	print("\n--- 1. Testing Open & Right-Dock Layout ---")
	ui_coord.open_cat_panel()
	var panel = ui_coord.cat_panel
	assert(panel.visible == true, "Panel must be visible")

	# Check panel docking & back button
	var back_btn = panel.back_btn
	assert(back_btn != null, "Back button '<<' must exist")
	assert(back_btn.text == "<<", "Back button text must be '<<'")
	assert(back_btn.position == Vector2(24, 20), "Back button must be at Vector2(24, 20)")
	print("✓ Back button '<<' verified at (24, 20)")

	var dock_panel = panel.dock_panel
	assert(dock_panel != null, "Cat panel must exist")
	assert(dock_panel.get_parent() is CenterContainer, "Panel must be placed inside CenterContainer")
	assert(dock_panel.custom_minimum_size == Vector2(560, 620), "Panel minimum size must be 560x620")
	print("✓ Cat panel centered on screen (560x620) matching user request")

	# 2. Check Wallet and Mode Tabs
	print("\n--- 2. Testing Wallet Bar & Mode Tabs ---")
	assert(panel._wallet_label != null, "Wallet label must exist")
	assert(panel._wallet_label.text.contains("200 xu"), "Wallet label must display current money (200 xu)")
	assert(panel._tab_hire_mode_btn != null, "Hire mode tab button must exist")
	assert(panel._tab_manage_mode_btn != null, "Manage mode tab button must exist")
	assert(panel._tab_hire_mode_btn.visible == false, "Top mode buttons are hidden per user request")
	assert(panel._tab_manage_mode_btn.visible == false, "Top mode buttons are hidden per user request")
	assert(panel._cat_selector_bar.visible == false, "Top cat selector buttons are hidden per user request")
	print("✓ Redundant top 4 buttons verified removed from display")

	# 3. Check Minimalist Shop Cards in Hire View
	print("\n--- 3. Testing Minimalist Cat Shop Cards ---")
	assert(panel._hire_view.visible == true, "Hire view must be visible when opening unhired cat")
	assert(panel._hire_cards_container != null, "Cards container must exist")
	var cards = panel._hire_cards_container.get_children()
	assert(cards.size() >= 2, "There must be cards for both Calico and Orange cat (got %d)" % cards.size())
	print("✓ Cards container has %d minimalist shop cards" % cards.size())

	# 4. Check Info Modal
	print("\n--- 4. Testing Info Modal (Popup [i]) ---")
	assert(panel._modal_root != null, "Info modal root must exist")
	assert(panel._modal_root.visible == false, "Modal must be hidden initially")

	# Trigger info modal for Orange cat
	panel._show_cat_details_modal(main_scene.cat_helper_orange)
	assert(panel._modal_root.visible == true, "Info modal must open")
	assert(panel._modal_title.text.contains("Mèo Mướp Vàng"), "Modal title must display Orange cat name")
	assert(panel._modal_lines_v.get_child_count() >= 4, "Modal must have detail bullet lines")
	print("✓ Info modal opened with full details and hiring action")

	panel._hide_info_modal()
	assert(panel._modal_root.visible == false, "Modal must close upon _hide_info_modal()")
	print("✓ Info modal closed successfully")

	# 5. Test 1-Click Hiring from Card
	print("\n--- 5. Testing 1-Click Hiring ---")
	var orange = main_scene.cat_helper_orange
	assert(orange.is_hired == false, "Orange cat initially not hired")

	panel.cat = orange
	panel._on_hire_pressed()

	assert(orange.is_hired == true, "Orange cat must be hired")
	assert(orange.visible == true, "Orange cat must be visible outside")
	assert(orange.position == orange.get_entrance_pos(), "Orange cat must appear at Junimo hut entrance")
	assert(panel._manage_view.visible == true, "Panel should switch to manage view after hire")
	assert(panel._manage_title_lbl.text.contains("MÈO MƯỚP VÀNG"), "Manage title must show Orange cat name")
	print("✓ 1-Click hire succeeded: Orange cat appeared at Junimo hut door (%s)" % str(orange.position))

	# 6. Test Management View in Shop Dock
	print("\n--- 6. Testing Management View (Seeds & Upgrades) ---")
	assert(panel._status_label != null, "Status label must exist")
	assert(panel._water_label != null, "Water label must exist")
	assert(panel._hoe_info_label != null, "Hoe info label must exist")
	assert(panel._seeds_in_bag_box != null, "Seeds in bag box must exist")
	assert(panel._seeds_in_cat_box != null, "Seeds in cat box must exist")

	# Test switching to Upgrades sub-tab
	panel._switch_tab(1)
	assert(panel._tab_upgrades_container.visible == true, "Upgrades container must be visible in tab 1")
	assert(panel._upgrade_cards_box.get_child_count() == 3, "Must display 3 upgrade cards (Speed, Work, Bag)")
	print("✓ Management view sub-tabs (Seeds & Upgrades) verified")

	# 7. Test Close with '<<' Button
	print("\n--- 7. Testing Close ---")
	back_btn.pressed.emit()
	assert(panel.visible == false, "Panel must close when back button '<<' is pressed")
	print("✓ Panel successfully closed via '<<' back button")

	print("\n==================================================")
	print("   ALL MINIMALIST SHOP CAT PANEL TESTS PASSED! 🎉 ")
	print("==================================================")
	quit(0)
