extends RefCounted
# Khởi Động Trò Chơi & Kết Nối Tín Hiệu Toàn Cục (Game Bootstrapper)

var main: Node2D


func setup(p_main: Node2D) -> void:
	main = p_main


func bootstrap() -> void:
	main.process_mode = Node.PROCESS_MODE_ALWAYS
	main.visible = true
	main._debug_mode = OS.get_environment("FARM_SHOT")
	main._clicktest = OS.get_environment("FARM_CLICKTEST")

	main._init_managers()
	main._build_world()
	main._build_ui()

	GameState.money_changed.connect(func(v: int) -> void:
		main.hud.set_money(v)
		if main.quest_mgr != null:
			main.quest_mgr.update_money_milestones(v)
	)
	GameState.crops_changed.connect(func() -> void: main.hud.rebuild_hotbar())
	GameState.stamina_changed.connect(func(cur: float, max_v: float) -> void: main.hud.set_stamina(cur, max_v))
	GameState.weather_changed.connect(func(w: String) -> void:
		if is_instance_valid(main.hud):
			main.hud.set_weather(w)
	)
	Inventory.changed.connect(main.hud.rebuild_hotbar)
	Inventory.pens_structure_changed.connect(main._rebuild_pen)
	Inventory.changed.connect(main._update_pen_bubbles)
	Inventory.baby_born.connect(func(_sid: String, sname: String) -> void:
		main.hud.toast("🐣 Tin vui: Đàn %s vừa sinh một chú con non (baby)!" % sname, Color(1.0, 0.85, 0.3))
	)

	main.hud.set_money(GameState.money)
	main.hud.set_stamina(GameState.stamina, GameState.max_stamina)
	main.title_screen.open(SaveSystem.has_save())
