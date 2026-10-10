extends RefCounted
# Lắp Ráp Thế Giới, Nông Trại, Nhân Vật & Các Thực Thể (World Assembler)

const TextureGen := preload("res://scripts/texture_gen.gd")
const FarmScript := preload("res://scripts/farm.gd")
const PlayerScript := preload("res://scripts/player.gd")
const CatHelperScript := preload("res://scripts/cat_helper.gd")
const MineManagerScript := preload("res://scripts/mine_manager.gd")
const WeatherManagerScript := preload("res://scripts/weather_manager.gd")
const QuestManagerScript := preload("res://scripts/quest_manager.gd")
const FarmingControllerScript := preload("res://scripts/farming_controller.gd")
const WorldBuilderScript := preload("res://scripts/world_builder.gd")


func build_world(main: Node2D) -> void:
	main.world = main.world_builder.build_world()
	main.ground = main.world_builder.ground
	main.canvas_mod = main.world_builder.canvas_mod

	main.farm = FarmScript.new()
	main.farm.setup_plots(FarmingControllerScript.FARM_PLOTS)
	main.world.add_child(main.farm)

	main.highlight = Sprite2D.new()
	main.highlight.texture = TextureGen.get_tex("highlight")
	main.highlight.visible = false
	main.farm.add_child(main.highlight)

	main.farming_controller.setup(main, main.farm, main.highlight)

	main.world_builder.build_residence_complex()
	main.world_builder.build_mailbox()
	main.world_builder.add_decor(TextureGen.get_tex("scarecrow"), WorldBuilderScript.SCARECROW_NORTH_POS, 1.2, Rect2(-4, -6, 8, 6))
	main.world_builder.add_decor(TextureGen.get_tex("scarecrow"), WorldBuilderScript.SCARECROW_SOUTH_POS, 1.2, Rect2(-4, -6, 8, 6))

	main.stall_manager.setup(main, main.world)
	main.stall_manager.build_market_stall()

	main.world_builder.build_mine_entrance()
	main.world_builder.build_fixed_foliage()
	main.world_builder.build_fences()
	main.world_builder.build_walls()

	main.interaction_manager.build_npcs(main.world)

	main.player = PlayerScript.new()
	main.player.position = WorldBuilderScript.PLAYER_START
	main.world.add_child(main.player)

	main.fishing_manager.setup(main, main.world, main.player)

	main.mine_manager = MineManagerScript.new()
	main.mine_manager.visible = false
	main.mine_manager.setup(main, main.player)
	main.mine_manager.exit_requested.connect(main._on_exit_mine)
	main.add_child(main.mine_manager)

	main.quest_mgr = QuestManagerScript.new()
	main.quest_mgr.setup(main)
	main.quest_mgr.quest_completed.connect(func(q: Dictionary):
		main.hud.toast("🎉 Xong nhiệm vụ: %s! Nhận thưởng [Q] hoặc gặp Trưởng Thôn" % str(q.get("title", "")), Color(1.0, 0.85, 0.35))
		main._update_npc_mayor_indicator()
	)
	main.quest_mgr.quests_refreshed.connect(main._update_npc_mayor_indicator)
	main.quest_mgr.quest_claimed.connect(func(_q: Dictionary):
		main._update_npc_mayor_indicator()
		main._save_now()
	)
	main.add_child(main.quest_mgr)

	main.cat_helper = CatHelperScript.new()
	main.cat_helper.farm = main.farm
	main.cat_helper.toast_requested.connect(func(txt: String, col: Color): main.hud.toast(txt, col))
	main.cat_helper.action_performed.connect(func(act_type: String, target_id: String):
		if main.quest_mgr != null:
			main.quest_mgr.advance_progress(act_type, target_id)
	)
	main.world.add_child(main.cat_helper)

	main.cam = Camera2D.new()
	main.cam.zoom = Vector2(2, 2)
	main.cam.position_smoothing_enabled = true
	main.cam.position_smoothing_speed = 8.0
	main.cam.limit_left = 0
	main.cam.limit_top = 0
	main.cam.limit_right = int(WorldBuilderScript.WORLD_SIZE.x)
	main.cam.limit_bottom = int(WorldBuilderScript.WORLD_SIZE.y)
	main.player.add_child(main.cam)
	main.cam.make_current()
	main.cam.reset_smoothing()

	main.weather_mgr = WeatherManagerScript.new()
	main.add_child(main.weather_mgr)
	main.weather_mgr.setup(main, main.player, main.farm)

	main.fishing_manager.build_pond_collision()
	main.pen_node = main.pen_manager.build_pen(main.world)

	main.interaction_manager.build_interactables()
