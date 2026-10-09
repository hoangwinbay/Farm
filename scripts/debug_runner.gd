extends RefCounted
# Chế Độ Debug Chụp Ảnh và Kiểm Thử Tự Động (Debug Test Runner)

const CropDB := preload("res://scripts/crop_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")

var main: Node2D
var debug_frame: int = 0


func setup(p_main: Node2D) -> void:
	main = p_main


func debug_step() -> void:
	debug_frame += 1
	match debug_frame:
		30:
			shot("1_title")
		31:
			debug_click_move()
		32:
			debug_click_press()
		34:
			print("DEBUG click result: mode=", main.mode, " (kỳ vọng 1=PLAY)")
		35:
			debug_start()
		70:
			shot("2_spawn")
		75:
			debug_field()
		100:
			shot("3_field")
		105:
			debug_grow()
		125:
			shot("4_grown")
		130:
			debug_shop_open()
		150:
			shot("5_shop")
		155:
			main.shop_panel.close()
		160:
			debug_inventory()
		180:
			shot("6_inventory")
		185:
			main.inv_panel.close()
		190:
			debug_dialog()
		210:
			shot("7_dialog")
		215:
			main.dialog_box.force_close()
			main.get_tree().paused = false
			main.mode = main.Mode.PLAY
			GameState.clock = 1320
		240:
			shot("8_dusk")
		245:
			GameState.clock = 700
			main.player.position = Vector2(430, 270)
		285:
			shot("9_house")
		290:
			main.player.position = Vector2(1030, 460)
		330:
			shot("10_stand")
		335:
			Inventory.rods = {"basic": 3}
			Inventory.add_fish("chep", 2)
			Inventory.add_fish("tre_vang", 1)
			Inventory.add_fish("chien", 1)
			Inventory.add_hoes(3)
			GameState.clock = 800
			main.player.position = Vector2(1030, 690)
		375:
			shot("11_pond")
		380:
			main.mode = main.Mode.PANEL
			main.fish_shop.open()
		400:
			shot("12_fishshop")
		405:
			main.fish_shop.close()
			main.mode = main.Mode.PLAY
			Inventory.coops = {"small": 4, "large": 2}
			for aid in ["ga_de", "ga_thit", "ga_vuon", "vit_thit", "cut", "bocau", "ngong", "da_dieu"]:
				Inventory.buy_animal(str(aid))
			main.player.position = Vector2(310, 610)
			GameState.clock = 800
		440:
			shot("13_pen")
		445:
			main.mode = main.Mode.PANEL
			main.poultry_shop.open()
		465:
			shot("14_poultry")
		470:
			main.poultry_shop.close()
			main.mode = main.Mode.PLAY
			GameState.clock = 800
			main.player.position = Vector2(310, 610)
			main.cam.reset_smoothing()
		480:
			main.minimap.set_big(true)
		490:
			shot("15_minimap_big")
		495:
			main.minimap.set_big(false)
			main.minimap._on_poi_clicked("pond")
			print("MINIMAP guide_on=", main.minimap.guide_dest == "pond",
					" cancel=", main.minimap.cancel_btn.visible,
					" route_pts=", main.minimap.guide.route.size())
		530:
			shot("16_minimap_guide")
		535:
			main.minimap._on_cancel_pressed()
			print("MINIMAP after_cancel=", main.minimap.guide_dest == "")
		540:
			main.minimap._on_poi_clicked("batu")
			main.player.position = Vector2(1180, 430)
		580:
			print("MINIMAP arrival_cleared=", main.minimap.guide_dest == "")
			debug_done()


func debug_click_move() -> void:
	var btn: Button = main.title_screen.start_btn
	var vpos: Vector2 = btn.get_global_rect().get_center()
	var wpos: Vector2 = main.get_viewport().get_final_transform() * vpos
	var mm := InputEventMouseMotion.new()
	mm.position = wpos
	mm.global_position = wpos
	main.get_viewport().push_input(mm)
	print("DEBUG btn rect=", btn.get_global_rect(), " viewport_pos=", vpos, " window_pos=", wpos)
	print("DEBUG hovered=", main.get_viewport().gui_get_hovered_control())


func debug_click_press() -> void:
	var vpos: Vector2 = main.title_screen.start_btn.get_global_rect().get_center()
	var wpos: Vector2 = main.get_viewport().get_final_transform() * vpos
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = wpos
	ev.global_position = wpos
	main.get_viewport().push_input(ev)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = wpos
	up.global_position = wpos
	main.get_viewport().push_input(up)


func debug_start() -> void:
	main.start_new_game()
	GameState.money = 999999
	while GameState.unlock_next():
		pass
	GameState.money = 12345
	GameState.money_changed.emit(GameState.money)
	for c in CropDB.CROPS:
		Inventory.add_seed(str(c.id), 3)
	print("DEBUG unlocked=", GameState.unlocked.size(), " (cần 16)")


func debug_field() -> void:
	Inventory.selected_seed = "rice"
	var coords := [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3)]
	for i in coords.size():
		var t = main.farm.tiles[coords[i]]
		t.till()
		t.plant("rice")
		if i < 5:
			t.water()
	print("DEBUG planted=", coords.size(), " (1 ô cố tình không tưới)")


func debug_grow() -> void:
	var wcoords := [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(2, 3), Vector2i(3, 3)]
	for i in 70:
		for v in wcoords:
			main.farm.tiles[v].tick_growth(1.0)
	var ready := 0
	for t in main.farm.tiles.values():
		if t.is_ready():
			ready += 1
	print("DEBUG ready sau 70 giây = ", ready, " (kỳ vọng 5)")
	var t0 = main.farm.tiles[Vector2i(2, 2)]
	t0.water()
	for i in 250:
		t0.tick_growth(1.0)
	print("DEBUG dry test: watered=", t0.watered, " (kỳ vọng false)")
	var first_ready = null
	for t in main.farm.tiles.values():
		if t.is_ready():
			first_ready = t
			break
	print("DEBUG harvest msg: ", main.farm.perform_at(first_ready))
	print("DEBUG produce rice = ", Inventory.produce_count("rice"), " (kỳ vọng 1)")
	Inventory.hoes = 2
	var tb = main.farm.tiles[Vector2i(6, 5)]
	tb.reset_tile()
	print("HOETEST lần1: ", main.farm.perform_at(tb), " | cuốc còn=", Inventory.hoes)
	tb.reset_tile()
	print("HOETEST lần2: ", main.farm.perform_at(tb), " | cuốc còn=", Inventory.hoes)
	tb.reset_tile()
	print("HOETEST lần3 (hết cuốc): ", main.farm.perform_at(tb), " | cuốc còn=", Inventory.hoes)
	Inventory.water_level = 1
	var twater = main.farm.tiles[Vector2i(6, 5)]
	twater.reset_tile()
	twater.till()
	twater.plant("rice")
	print("WATERTEST tưới lần1: ", main.farm.perform_at(twater), " | nước còn=", Inventory.water_level)
	twater.watered = false
	print("WATERTEST tưới lần2 (hết nước): ", main.farm.perform_at(twater), " | nước còn=", Inventory.water_level)
	var added_w: int = Inventory.refill_water()
	print("WATERTEST múc đầy ao: +%d | nước đầy=%d/%d" % [added_w, Inventory.water_level, Inventory.water_max])
	twater.reset_tile()
	Inventory.rods = {"basic": 2}
	print("FISHTEST cast1=", Inventory.take_cast(), " cast2=", Inventory.take_cast(),
			" cast3='", Inventory.take_cast(), "' (kỳ vọng basic, basic, trống)")
	var counts := {}
	for i in 2000:
		var r := FishDB.roll_cast(false)
		var k := "none" if r.is_empty() else str(r.tier)
		counts[k] = int(counts.get(k, 0)) + 1
	print("FISHTEST 2000 lượt (kỳ vọng ~none 600 / common 800 / mid 400 / rare 200 / legend ~0): ", counts)
	Inventory.coops = {"small": 1, "large": 0}
	print("POULTRY mua gà 1: '", Inventory.buy_animal("chicken"), "' (kỳ vọng trống)")
	print("POULTRY mua gà 2: '", Inventory.buy_animal("chicken"), "' (trống)")
	print("POULTRY mua bò (không có chuồng lớn): '", Inventory.buy_animal("cow"), "'")
	Inventory.add_feed(10)
	Inventory.feed_all_hungry_for_species("chicken")
	Inventory.tick_animals(95)
	var got: int = Inventory.collect_products()
	print("POULTRY thu sau 95s = ", got, " trứng gà (kỳ vọng 2)")
	print("POULTRY baby gà sinh ra: ", Inventory.animals.any(func(a): return bool(a.get("is_baby", false))))
	print("POULTRY produce trung_ga=", Inventory.produce_count("trung_ga"))
	SaveSystem.save_game(main.farm.get_state(), main.player.position, true, main.mailbox_data, main.foliage_data, main.stall_slots, main.stall_revenue)
	var d := SaveSystem.load_data()
	print("DEBUG save/load farm tiles = ", (d.get("farm", []) as Array).size(),
			" hoes=", int(d.get("hoes", -1)), " rods=", d.get("rods", {}),
			" coops=", d.get("coops", {}), " animals=", (d.get("animals", []) as Array).size())


func debug_shop_open() -> void:
	main.mode = main.Mode.PANEL
	main.shop_panel.open()


func debug_inventory() -> void:
	main.mode = main.Mode.PANEL
	main.inv_panel.open()


func debug_dialog() -> void:
	main.mode = main.Mode.DIALOG
	main.get_tree().paused = true
	main.dialog_box.start("Bác Tư", ["Chào con! Cửa hàng bên này bán đủ 16 loại hạt giống đó."])


func shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var img := main.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("user://shot_%s.png" % shot_name)
	img.save_png(path)
	print("SHOT ", path)


func debug_done() -> void:
	GameState.reset_new_game()
	Inventory.reset()
	main.continue_game()
	print("DEBUG continue: money=", GameState.money, " day=", GameState.day,
			" unlocked=", GameState.unlocked.size(),
			" seed_rice=", Inventory.seed_count("rice"))
	print("DEBUG_DONE")
	main.get_tree().quit()
