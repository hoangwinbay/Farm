extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("==================================================")
	print("   TESTING CAT ICON OPENS CAT LIST (NOT CALICO)   ")
	print("==================================================")

	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var calico = main_scene.cat_helper
	var orange = main_scene.cat_helper_orange
	var panel = main_scene.cat_panel
	var hud = main_scene.hud

	# 1. Hire Calico Cat first
	calico.hire()
	assert(calico.is_hired == true, "Calico cat should be hired")
	print("✓ Calico cat is hired")

	# 2. Simulate clicking the cat icon on the HUD (open_cat_requested)
	print("\n--- Testing HUD Cat Icon Click ---")
	hud.open_cat_requested.emit()
	await process_frame

	assert(panel.visible == true, "Cat panel must be open")
	assert(panel._hire_view.visible == true, "Panel MUST show the Cat List (_hire_view) when clicking the cat icon!")
	assert(panel._manage_view.visible == false, "Panel MUST NOT show Calico management view (_manage_view) directly!")
	assert(panel._hire_cards_container.get_child_count() >= 2, "Cat list must display cards for all cats")
	print("✓ HUD Cat Icon correctly opened the full Cat List (not Calico management)!")

	# Close panel
	panel.close()
	assert(panel.visible == false)

	# 3. Test interacting directly with a specific cat in the field
	print("\n--- Testing Direct Interaction with Field Cat ---")
	main_scene._open_cat_panel(calico)
	await process_frame

	assert(panel.visible == true)
	assert(panel._manage_view.visible == true, "Directly clicking a hired cat in the field should open its management view")
	assert(panel._manage_title_lbl.text.contains("MÈO TAM THỂ"), "Management title must show Calico cat")
	print("✓ Direct interaction with hired field cat correctly opens its management view")

	# 4. Click '« Danh sách mèo' to return to list
	print("\n--- Testing '« Danh sách mèo' Return Button ---")
	panel._show_hire_mode()
	assert(panel._hire_view.visible == true, "Clicking back must return to the Cat List")
	assert(panel._manage_view.visible == false, "Management view must be hidden")
	print("✓ '« Danh sách mèo' button successfully returns to Cat List")

	print("\n==================================================")
	print("   ALL CAT ICON TESTS PASSED 100%! 🎉🐱           ")
	print("==================================================")
	quit(0)
