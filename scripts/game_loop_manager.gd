extends RefCounted
# Quản lý Vòng Lặp Khung Hình (Game Loop & Frame Processing)

var main: Node2D


func setup(p_main: Node2D) -> void:
	main = p_main


# Cập nhật khung hình mỗi tick
func process_frame(delta: float) -> void:
	if main._debug_mode != "":
		main.debug_runner.debug_step()
	if main._clicktest != "":
		main.clicktest_runner.clicktest_step()
	if main.minimap != null:
		main.minimap.visible = (main.mode == main.Mode.PLAY) and (not main.in_mine)
	if main.touch_ui != null:
		main.touch_ui.visible = main.mode == main.Mode.PLAY
	if main.mode != main.Mode.PLAY or main.get_tree().paused:
		return

	main.day_night_cycle.process_time(delta)
	main.stall_manager.process_stall_customers(delta)

	if is_instance_valid(main.player):
		var ppos: Vector2 = main.player.position
		if is_instance_valid(main._shed_decor):
			var behind_shed: bool = ppos.x >= 435.0 and ppos.x <= 565.0 and ppos.y < 230.0 and ppos.y > 60.0
			var target_shed_a: float = 0.6 if behind_shed else 1.0
			main._shed_decor.modulate.a = move_toward(main._shed_decor.modulate.a, target_shed_a, delta * 4.0)
		if is_instance_valid(main._house_decor):
			var behind_house: bool = ppos.x >= 565.0 and ppos.x <= 720.0 and ppos.y < 216.0 and ppos.y > 60.0
			var target_house_a: float = 0.6 if behind_house else 1.0
			main._house_decor.modulate.a = move_toward(main._house_decor.modulate.a, target_house_a, delta * 4.0)

	main.fishing_manager.process(delta)
	if not main.fishing:
		main.interaction_manager.update_hint_and_highlight()
