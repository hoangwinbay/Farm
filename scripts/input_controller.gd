extends RefCounted
# Quản lý Xử Lý Phím & Chuột Đầu Vào (Input Controller & Event Handling)

const CropDB := preload("res://scripts/crop_db.gd")

var main: Node2D


func setup(p_main: Node2D) -> void:
	main = p_main


# Xử lý các sự kiện đầu vào chưa qua xử lý
func handle_unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if main.mode == main.Mode.PLAY and not main.get_tree().paused:
			main.pause_menu.open()
			main.get_tree().paused = true
		elif main.pause_menu.visible:
			main._resume_from_pause()
		elif main.ui_coordinator.is_any_panel_open():
			main._close_panels()
	elif event.is_action_pressed("interact"):
		if main.mode == main.Mode.PLAY and not main.get_tree().paused:
			main._do_interact()
		elif main.mode == main.Mode.DIALOG:
			main.dialog_box.advance()
		elif main.ui_coordinator.is_any_panel_open():
			main._close_panels()
	elif event.is_action_pressed("inventory"):
		if main.mode == main.Mode.PLAY and not main.get_tree().paused:
			main._open_inventory()
		elif main.inv_panel.visible:
			main._close_panels()
	elif event.is_action_pressed("cycle_seed") and main.mode == main.Mode.PLAY and not main.get_tree().paused:
		var id: String = Inventory.cycle_seed()
		var c: Dictionary = CropDB.get_crop(id)
		if not c.is_empty():
			main.hud.toast("Đổi hạt: %s" % c.name)
	elif event.is_action_pressed("quick_eat") and main.mode == main.Mode.PLAY and not main.get_tree().paused:
		main._quick_eat()
	elif event is InputEventKey and event.pressed and not event.echo:
		if main.mode == main.Mode.PLAY and not main.get_tree().paused:
			if event.keycode == KEY_K:
				main._open_storage()
				main.get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_M:
				main._open_cat_panel()
				main.get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_F:
				main._quick_eat()
				main.get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_Q:
				if main.hud != null and main.hud.quest_drawer != null:
					main.hud.quest_drawer.toggle_drawer()
				else:
					main._open_quest_panel()
				main.get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_F2:
				main.ui_coordinator.open_settings()
				main.get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_F3:
				var spd := GameState.cycle_game_speed()
				if main.hud != null:
					main.hud.toast("⚡ Tốc độ trò chơi: x%d" % int(spd), Color(1.0, 0.9, 0.4))
				main.get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_F5:
				main._save_now()
				if main.hud != null:
					main.hud.toast("💾 Đã lưu game thành công! (F5)", Color(0.4, 1.0, 0.5))
				main.get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_F7:
				main.world_builder.build_fixed_foliage()
				if main.hud != null:
					main.hud.toast("🌲 Đã nạp lại vị trí cây cố định! (F7)", Color(0.4, 1.0, 0.5))
				main.get_viewport().set_input_as_handled()
				return
			elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
				main.hud.select_slot_by_index(event.keycode - KEY_1)
		elif (main.storage_panel != null and main.storage_panel.visible and event.keycode == KEY_K) \
			or (main.cat_panel != null and main.cat_panel.visible and event.keycode == KEY_M) \
			or (main.quest_panel != null and main.quest_panel.visible and event.keycode == KEY_Q) \
			or (main.settings_panel != null and main.settings_panel.visible and event.keycode == KEY_F2):
			main._close_panels()
			main.get_viewport().set_input_as_handled()
			return
	elif (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed and main.mode == main.Mode.PLAY and not main.get_tree().paused:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				main.hud.cycle_slot(-1)
				return
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				main.hud.cycle_slot(1)
				return
			elif event.button_index != MOUSE_BUTTON_LEFT:
				return
		var tap_pos: Vector2 = main.player.get_global_mouse_position() if is_instance_valid(main.player) else main.get_global_mouse_position()
		main._handle_world_tap(tap_pos)
