extends RefCounted
# Quản lý Chu Kỳ Ngày/Đêm, Ánh Sáng Môi Trường (_tint) & Ngủ Nghỉ Qua Đêm (_do_sleep)

const WeatherManagerScript := preload("res://scripts/weather_manager.gd")
const CatHelperScript := preload("res://scripts/cat_helper.gd")
const FarmTileScript := preload("res://scripts/farm_tile.gd")

var main: Node2D


func setup(p_main: Node2D) -> void:
	main = p_main


# Tính toán màu sắc ánh sáng môi trường theo giờ trong ngày và thời tiết
func get_ambient_tint() -> Color:
	var t := GameState.clock
	var night := Color(0.68, 0.72, 0.92)
	var day := Color.WHITE

	match GameState.weather:
		"drizzle":
			day = Color(0.88, 0.92, 0.96)
			night = Color(0.62, 0.66, 0.88)
		"rain":
			day = Color(0.74, 0.82, 0.94)
			night = Color(0.55, 0.60, 0.82)
		"storm":
			day = Color(0.55, 0.60, 0.76)
			night = Color(0.42, 0.46, 0.68)
		"windy":
			day = Color(0.96, 0.98, 0.94)
			night = Color(0.65, 0.70, 0.90)

	if t < 420:
		# 0:00 - 6:00 đêm; 6:00 - 7:00 chuyển sáng
		return night.lerp(day, clampf((t - 360) / 60.0, 0, 1))
	if t < 1140:
		return day
	if t < 1200:
		# 19:00 - 20:00 chuyển tối
		return day.lerp(night, clampf((t - 1140) / 60.0, 0, 1))
	return night


# Xử lý tiến trình thời gian và chu kỳ ngày/đêm mỗi frame
func process_time(delta: float) -> void:
	GameState.tick(delta)
	Inventory.tick_animals(delta)
	if is_instance_valid(main.hud):
		main.hud.set_clock(GameState.clock_text())
	if is_instance_valid(main.canvas_mod):
		main.canvas_mod.color = get_ambient_tint()

	# 2:00 sáng chưa ngủ -> người chơi ngất xỉu vì kiệt sức
	if GameState.clock >= GameState.COLLAPSE_MIN and GameState.clock < GameState.DAY_START:
		do_sleep(true)


# Mở hộp thoại hỏi đi ngủ
func ask_sleep() -> void:
	main.mode = main.Mode.DIALOG
	main.get_tree().paused = true
	main.dialog_box.ask("Đi ngủ và lưu game? (Lưu ý: Ngủ không hồi thể lực, hãy ăn nông sản hoặc thịt ⚡)")


func on_sleep_answer(yes: bool) -> void:
	if yes:
		do_sleep(false)
	else:
		main.mode = main.Mode.PLAY
		main.get_tree().paused = false


# Thực hiện tiến trình ngủ chuyển sang sáng hôm sau
func do_sleep(forced: bool) -> void:
	main.mode = main.Mode.PANEL
	main.get_tree().paused = true
	main.dialog_box.force_close()
	var tw := main.create_tween()
	tw.tween_property(main.fade_rect, "modulate:a", 1.0, 0.45)
	await tw.finished

	if main.in_mine:
		main.in_mine = false
		main.player.reparent(main.world)
		if main.mine_manager != null:
			main.mine_manager.process_mode = Node.PROCESS_MODE_DISABLED
			main.mine_manager.visible = false
		main.world.process_mode = Node.PROCESS_MODE_PAUSABLE
		main.world.visible = true
		if is_instance_valid(main.weather_mgr):
			main.weather_mgr.visible = true
		if is_instance_valid(main.hud):
			main.hud.set_underground(false)
		main.player.position = main.world_builder.HOUSE_POS + Vector2(15, 10)
		main.cam.limit_left = 0
		main.cam.limit_top = 0
		main.cam.limit_right = int(main.WORLD_SIZE.x)
		main.cam.limit_bottom = int(main.WORLD_SIZE.y)

	GameState.sleep_to_morning(forced)
	var next_w: String = WeatherManagerScript.roll_weather(GameState.day)
	GameState.weather = next_w
	if is_instance_valid(main.weather_mgr):
		main.weather_mgr.set_weather(next_w)
	if is_instance_valid(main.hud):
		main.hud.set_weather(next_w)
	var ready_n: int = main.farm.ready_count()

	main.stall_manager.clear_night_customers()

	if is_instance_valid(main.cat_helper) and main.cat_helper.is_hired:
		main.cat_helper._pay_daily_wage()
		main.cat_helper.wage_paid_today = false
		main.cat_helper.position = CatHelperScript.TENT_SLEEP_POS
		main.cat_helper.state = CatHelperScript.State.IDLE
		main.cat_helper._hide_bubble()

	if is_instance_valid(main.quest_mgr):
		main.quest_mgr.check_real_time_refresh()
		main._update_npc_mayor_indicator()

	if main.foliage_nodes.size() < 95 and randf() < 0.60:
		main._sprout_random_plant()

	var new_pests := 0
	if not (next_w in [WeatherManagerScript.RAIN, WeatherManagerScript.STORM]):
		for t in main.farm.tiles.values():
			if t.tstate == FarmTileScript.TState.PLANTED and not t.is_ready() and not t.has_pest and t.growth > 3.0:
				if randf() < 0.15:
					t.spawn_pest()
					new_pests += 1

	main._save_now()
	if is_instance_valid(main.hud):
		main.hud.set_clock(GameState.clock_text())
	if is_instance_valid(main.canvas_mod):
		main.canvas_mod.color = get_ambient_tint()

	if forced:
		if is_instance_valid(main.hud):
			main.hud.toast("Bạn gục ngã vì quá khuya... Đã lưu game 💾 (Ăn thức ăn để hồi thể lực)", Color(1.0, 0.55, 0.45))
	else:
		if is_instance_valid(main.hud):
			main.hud.toast("Ngày mới! Đã lưu game thành công 💾 (Ăn thức ăn để hồi thể lực)", Color(0.65, 1.0, 0.6))

	if new_pests > 0:
		if is_instance_valid(main.hud):
			main.hud.toast("⚠️ Có %d cây bị sâu cắn phá! Hãy bắt sâu bọ để cây lớn tiếp 🐛" % new_pests, Color(1.0, 0.65, 0.4))
	if ready_n > 0:
		if is_instance_valid(main.hud):
			main.hud.toast("%d cây đã chín chờ thu hoạch!" % ready_n, Color(0.75, 1.0, 0.7))

	var tw2 := main.create_tween()
	tw2.tween_property(main.fade_rect, "modulate:a", 0.0, 0.6)
	await tw2.finished
	if main.mode == main.Mode.PANEL:
		main.mode = main.Mode.PLAY
	main.get_tree().paused = false
