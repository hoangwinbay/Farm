extends RefCounted
# Kịch Bản Clicktest Tự Động (Clicktest Automated Runner)

const CatHelperScript := preload("res://scripts/cat_helper.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")

var main: Node2D
var clicktest_frame: int = 0


func setup(p_main: Node2D) -> void:
	main = p_main


func press_interact() -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = "interact"
	up.pressed = false
	Input.parse_input_event(up)


func clicktest_step() -> void:
	clicktest_frame += 1
	match clicktest_frame:
		40:
			main._debug_click_move()
			main._debug_click_press()
		130:
			print("CLICKTEST mode=", main.mode, " (kỳ vọng 1=PLAY) paused=", main.get_tree().paused)
			print("CLICKTEST world_children=", main.world.get_child_count(),
					" player=", main.player.position,
					" cam_center=", main.cam.get_screen_center_position(),
					" cam_active=", main.cam.is_current())
			print("CLICKTEST ground_tex=", main.ground.texture, " canvas_mod=", main.canvas_mod.color)
			print("CLICKTEST world_visible=", main.world.visible, " main_visible=", main.visible)
			main._shot("auto_clicktest")
		140:
			main.player.position = Vector2(1048, 680)
			main.player.facing = Vector2.UP
			main.cam.reset_smoothing()
			Input.action_press("move_up")
		240:
			Input.action_release("move_up")
			print("FARMSOUTH player=", main.player.position,
					" (kỳ vọng y > 650: bị rào nam thửa Nam chặn)")
		245:
			main.player.position = Vector2(700, 472)
			main.player.facing = Vector2.RIGHT
			main.cam.reset_smoothing()
			Input.action_press("move_right")
		395:
			Input.action_release("move_right")
			print("WESTDOOR player=", main.player.position,
					" (kỳ vọng x > 850: đại lộ giữa 2 ruộng thông thoáng)")
		400:
			main.player.position = Vector2(505, 300)
			main.player.facing = Vector2.UP
			main.cam.reset_smoothing()
			Input.action_press("move_up")
		480:
			Input.action_release("move_up")
			print("SHEDCOL player=", main.player.position,
					" (kỳ vọng y in [244..255]: bị tường nhà kho chặn)")
		485:
			main.player.position = Vector2(641, 300)
			main.player.facing = Vector2.UP
			main.cam.reset_smoothing()
			Input.action_press("move_up")
		565:
			Input.action_release("move_up")
			print("HOUSECOL player=", main.player.position,
					" (kỳ vọng y in [244..255]: bị tường nhà chính chặn)")
		570:
			main.player.position = Vector2(505, 140)
			main.player.facing = Vector2.RIGHT
			main.cam.reset_smoothing()
			Input.action_press("move_right")
		700:
			Input.action_release("move_right")
			print("BACKLANE player=", main.player.position,
					" (kỳ vọng x > 720: đi ngang thông suốt qua lưng nhà kho & nhà chính)")
		705:
			main.player.position = Vector2(1440, 700)
			main.player.facing = Vector2.DOWN
			main.cam.reset_smoothing()
			Input.action_press("move_down")
		785:
			Input.action_release("move_down")
			print("PONDNORTH player=", main.player.position,
					" (kỳ vọng y in [750..756]: bờ đá bắc ao chặn đứng người chơi trên bờ)")
		790:
			main.player.position = Vector2(1700, 880)
			main.player.facing = Vector2.LEFT
			main.cam.reset_smoothing()
			Input.action_press("move_left")
		880:
			Input.action_release("move_left")
			print("PONDEAST player=", main.player.position,
					" (kỳ vọng x > 1610: bờ đông chặn, không đi vào lòng hồ)")
		885:
			main.player.position = Vector2(1170, 880)
			main.player.facing = Vector2.RIGHT
			main.cam.reset_smoothing()
			Input.action_press("move_right")
		975:
			Input.action_release("move_right")
			print("PONDWEST player=", main.player.position,
					" (kỳ vọng x < 1270: bờ tây chặn, không đi vào lòng hồ)")
		980:
			main.player.position = Vector2(641, 252)
			main.player.facing = Vector2.UP
			main.cam.reset_smoothing()
		990:
			press_interact()
		1020:
			print("HOUSE_SLEEP dialog_mode=", main.mode, " (kỳ vọng 2=DIALOG)")
			main.dialog_box.force_close()
			main.mode = main.Mode.PLAY
			main.get_tree().paused = false
		1025:
			main.player.position = main.world_builder.MAILBOX_POS + Vector2(0, 16)
			main.player.facing = Vector2.UP
			main.cam.reset_smoothing()
		1035:
			press_interact()
		1060:
			print("MAILBOX_OPEN panel_visible=", main.mailbox_panel.visible if main.mailbox_panel else false)
			main._close_panels()
		1065:
			main.player.position = main.world_builder.MARKET_STALL_POS + Vector2(0, 24)
			main.player.facing = Vector2.UP
			main.cam.reset_smoothing()
		1075:
			press_interact()
		1100:
			print("STALL_OPEN panel_visible=", main.stall_panel.visible if main.stall_panel else false)
			main._close_panels()
		1105:
			main.player.position = CatHelperScript.WAITING_POS + Vector2(0, 16)
			main.player.facing = Vector2.UP
			main.cam.reset_smoothing()
		1115:
			press_interact()
		1140:
			print("CAT_INTERACT panel_visible=", main.cat_panel.visible if main.cat_panel else false)
			main._close_panels()
		1145:
			main.player.position = main.world_builder.MINE_SIGN_POS + Vector2(0, 16)
			main.player.facing = Vector2.UP
			main.cam.reset_smoothing()
		1155:
			press_interact()
		1180:
			print("MINE_SIGN dialog_visible=", main.dialog_box.visible if main.dialog_box else false)
			main.dialog_box.force_close()
			main.mode = main.Mode.PLAY
			main.get_tree().paused = false
		1185:
			main.player.position = main.world_builder.LEAH_MINER_POS + Vector2(0, 16)
			main.player.facing = Vector2.UP
			main.cam.reset_smoothing()
		1195:
			press_interact()
		1220:
			print("LEAH_TALK dialog_visible=", main.dialog_box.visible if main.dialog_box else false)
			main.dialog_box.force_close()
			main.mode = main.Mode.PLAY
			main.get_tree().paused = false
		1225:
			main.player.position = main.world_builder.MINE_ENTRANCE_POS + Vector2(0, 32)
			main.player.facing = Vector2.UP
			main.cam.reset_smoothing()
		1235:
			press_interact()
		1310:
			print("MINE_ENTER in_mine=", main.in_mine,
					" floor=", main.mine_manager.current_floor if main.mine_manager else -1,
					" rocks=", main.mine_manager._rocks_data.size() if main.mine_manager else -1)
			main._on_exit_mine()
		1380:
			print("MINE_EXIT in_mine=", main.in_mine, " player_pos=", main.player.position)
		1385:
			var ripple_frames_ok := true
			for i in 8:
				if TextureGen.water_ripple_frame(i) == null:
					ripple_frames_ok = false
					break

			var rod_icons_ok: bool = (TextureGen.get_tex("fx_rod") != null
					and TextureGen.get_tex("fx_bobber") != null
					and TextureGen.rod_icon("9aa0a6") != null
					and TextureGen.rod_icon("66bb6a") != null
					and TextureGen.rod_icon("ffd54f") != null)

			var farmer_fish_anim_ok := true
			for d_name in ["down", "side", "up"]:
				for st in range(5):
					if TextureGen.char_action_tex(d_name, "fish", st) == null:
						farmer_fish_anim_ok = false
						break

			Inventory.add_rod("basic", 5)
			main.player.position = main.FISH_SPOT_POS + Vector2(-50, 0)
			main._start_fishing()
			var fishing_started_ok: bool = (main.fishing and main.player.is_fishing()
					and is_instance_valid(main._bobber_spr) and is_instance_valid(main._fishing_line))
			var ripple_spawn_ok: bool = is_instance_valid(main._spawn_water_ripple(Vector2(1440, 900), 1.0, 0.5))

			main._finish_fishing()
			var fishing_finished_ok: bool = (not main.fishing and main._bobber_spr == null and main._fishing_line == null)

			print("SDV_FISHING_RIPPLE_TEST ripples=", ripple_frames_ok, " rods=", rod_icons_ok,
					" farmer_anims=", farmer_fish_anim_ok, " start_cast=", fishing_started_ok,
					" ripple_spawn=", ripple_spawn_ok, " finish_cast=", fishing_finished_ok)

			print("CLICKTEST_DONE")
			main.get_tree().quit()
