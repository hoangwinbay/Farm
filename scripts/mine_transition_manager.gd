extends RefCounted
# Quản lý Chuyển Cảnh Hầm Mỏ & Màn Hình Mờ Dần (Mine & Scene Transitions)

var main: Node2D


func setup(p_main: Node2D) -> void:
	main = p_main


# Hiệu ứng làm đen màn hình chuyển cảnh (Fade In / Fade Out)
func fade_transition(on_mid: Callable) -> void:
	if main.fade_rect == null:
		if on_mid.is_valid():
			on_mid.call()
		return
	if is_instance_valid(main.player):
		main.player.can_move = false
	var tw := main.create_tween()
	tw.tween_property(main.fade_rect, "modulate:a", 1.0, 0.35)
	tw.tween_callback(func():
		if on_mid.is_valid():
			on_mid.call()
	)
	tw.tween_interval(0.1)
	tw.tween_property(main.fade_rect, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		if is_instance_valid(main.player):
			main.player.can_move = true
	)


# Tiến vào Hầm Mỏ từ mặt đất
func enter_mine() -> void:
	if not Inventory.has_pickaxe():
		if is_instance_valid(main.hud):
			main.hud.toast("Hãy nói chuyện với Leah để nhận Cúp trước khi vào mỏ! ⛏️", Color(1.0, 0.85, 0.5))
		return

	fade_transition(func():
		main.in_mine = true
		main.player.reparent(main.mine_manager)
		main.world.process_mode = Node.PROCESS_MODE_DISABLED
		main.world.visible = false
		if is_instance_valid(main.weather_mgr):
			main.weather_mgr.visible = false
		if is_instance_valid(main.hud):
			main.hud.set_underground(true)
		main.mine_manager.process_mode = Node.PROCESS_MODE_PAUSABLE
		main.mine_manager.enter_mine(1)
		main.cam.limit_left = 0
		main.cam.limit_top = 0
		main.cam.limit_right = main.mine_manager.MINE_TILES.x * main.mine_manager.TILE
		main.cam.limit_bottom = main.mine_manager.MINE_TILES.y * main.mine_manager.TILE
		if is_instance_valid(main.hud):
			main.hud.toast("Đã tiến vào Hầm Mỏ — Tầng 1! ⛏️", Color(0.8, 0.9, 1.0))
	)


# Rời khỏi Hầm Mỏ trở lại mặt đất
func exit_mine() -> void:
	if not main.in_mine:
		return

	fade_transition(func():
		main.in_mine = false
		main.player.reparent(main.world)
		main.mine_manager.process_mode = Node.PROCESS_MODE_DISABLED
		main.mine_manager.visible = false
		main.world.process_mode = Node.PROCESS_MODE_PAUSABLE
		main.world.visible = true
		if is_instance_valid(main.weather_mgr):
			main.weather_mgr.visible = true
		if is_instance_valid(main.hud):
			main.hud.set_underground(false)
		main.player.position = main.world_builder.MINE_ENTRANCE_POS + Vector2(0, 32)
		main.cam.limit_left = 0
		main.cam.limit_top = 0
		main.cam.limit_right = int(main.WORLD_SIZE.x)
		main.cam.limit_bottom = int(main.WORLD_SIZE.y)
		if is_instance_valid(main.hud):
			main.hud.toast("Đã trở lại mặt đất! 🌄")
	)
