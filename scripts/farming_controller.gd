extends RefCounted
# Quản lý Trồng Cây & Thao tác Ruộng Nông Trại (Farming & Crop Controller)

const OreDB := preload("res://scripts/ore_db.gd")
const CropDB := preload("res://scripts/crop_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")

const PLOT_NORTH_ORIGIN := Vector2(824, 304)
const PLOT_SOUTH_ORIGIN := Vector2(824, 512)
const PLOT_TILES := Vector2i(14, 4)
const FARM_ORIGIN := PLOT_NORTH_ORIGIN
const FARM_TILES := PLOT_TILES

const FARM_PLOTS := [
	{
		"id": "north",
		"name": "Thửa Bắc",
		"origin": PLOT_NORTH_ORIGIN,
		"size": PLOT_TILES,
		"rect": Rect2(824, 304, 448, 128),
		"y_offset": 0
	},
	{
		"id": "south",
		"name": "Thửa Nam",
		"origin": PLOT_SOUTH_ORIGIN,
		"size": PLOT_TILES,
		"rect": Rect2(824, 512, 448, 128),
		"y_offset": 4
	}
]

# Giới hạn hàng rào của từng thửa ruộng (vùng bên trong hàng rào bao gồm lối vào cổng)
const PLOT_NORTH_BOUNDS := Rect2(806, 288, 484, 160) # x: 806..1290, y: 288..448
const PLOT_SOUTH_BOUNDS := Rect2(806, 496, 484, 160) # x: 806..1290, y: 496..656

var main: Node2D
var farm: Node2D
var highlight: Sprite2D


func setup(p_main: Node2D, p_farm: Node2D, p_highlight: Sprite2D) -> void:
	main = p_main
	farm = p_farm
	highlight = p_highlight


# Kiểm tra vị trí (thường là người chơi) có đang đứng bên trong thửa ruộng của ô đất hay không
func is_player_in_tile_plot(player_pos: Vector2, tile: Node) -> bool:
	if tile == null:
		return false
	if tile.coord.y < 4:
		return PLOT_NORTH_BOUNDS.has_point(player_pos)
	else:
		return PLOT_SOUTH_BOUNDS.has_point(player_pos)


func get_action_stamina_cost(act: String) -> float:
	match act:
		"till": return OreDB.get_hoe_stamina(Inventory.get_hoe_tier())
		"water": return 5.0
		"plant": return 5.0
		"harvest": return 1.5
		"catch_pest": return 1.0
		"fish": return 15.0
		"mine": return OreDB.get_pickaxe_stamina(Inventory.get_pickaxe_tier())
	return 0.0


func quick_eat() -> void:
	if GameState.stamina >= GameState.max_stamina:
		if is_instance_valid(main.hud):
			main.hud.toast("Thể lực đã tràn đầy (%d/%d)!" % [int(GameState.stamina), int(GameState.max_stamina)], Color(1.0, 0.88, 0.4))
		return

	var best_cat := ""
	var best_id := ""
	var best_rec := 0

	# 1. Ưu tiên kiểm tra sản phẩm chăn nuôi (thịt gà, thịt vịt, thịt ngan, bồ câu thịt...)
	for a in PoultryDB.ANIMALS:
		var pid := str(a.product)
		if Inventory.produce_count(pid) > 0:
			var rec := GameState.get_food_stamina("poultry", pid)
			if rec > best_rec:
				best_rec = rec
				best_cat = "produce"
				best_id = pid

	# 2. Kiểm tra nông sản trồng trọt
	if best_rec == 0:
		for c in CropDB.CROPS:
			var cid := str(c.id)
			if Inventory.produce_count(cid) > 0:
				var rec := GameState.get_food_stamina("crop", cid)
				if rec > best_rec:
					best_rec = rec
					best_cat = "produce"
					best_id = cid

	# 3. Kiểm tra cá
	if best_rec == 0:
		for f in FishDB.FISH:
			var fid := str(f.id)
			if Inventory.fish_count(fid) > 0:
				var rec := GameState.get_food_stamina("fish", fid)
				if rec > best_rec:
					best_rec = rec
					best_cat = "fish"
					best_id = fid

	if best_id == "":
		if is_instance_valid(main.hud):
			main.hud.toast("Túi đồ không có nông sản hoặc thịt để ăn! (Bấm I xem túi)", Color(1.0, 0.65, 0.4))
		return

	var res := GameState.eat_food(best_cat, best_id)
	if res.get("ok", false):
		if is_instance_valid(main.hud):
			main.hud.toast(str(res.get("msg", "")), Color(0.4, 1.0, 0.5))
		spawn_effect("fx_harvest", main.player.position)
		if main.inv_panel != null and main.inv_panel.visible:
			main.inv_panel.refresh()
	else:
		if is_instance_valid(main.hud):
			main.hud.toast(str(res.get("msg", "")), Color(1.0, 0.65, 0.4))


func do_farm_action(tile: Node) -> bool:
	if tile == null or main.fishing:
		return false
	if is_instance_valid(main.player) and not is_player_in_tile_plot(main.player.position, tile):
		if is_instance_valid(main.hud):
			main.hud.toast("Hãy vào trong ruộng qua cổng rào để chăm sóc cây trồng! 🌾", Color(1.0, 0.85, 0.5))
		return false
	var info: Dictionary = farm.action_at(tile)
	var act := str(info.act)
	if act == "none":
		if str(info.label) != "" and is_instance_valid(main.hud):
			main.hud.toast(str(info.label))
		return false

	var cost := get_action_stamina_cost(act)
	if cost > 0.0 and GameState.stamina < cost:
		if is_instance_valid(main.hud):
			main.hud.toast("Bạn đã kiệt sức! Hãy ăn nông sản hoặc thịt (phím F hoặc I) để hồi thể lực ⚡", Color(1.0, 0.45, 0.35))
		return false

	var crop_id_before: String = tile.crop_id if tile != null else ""
	var selected_seed_before := Inventory.selected_seed
	var msg: String = farm.perform_at(tile)
	if msg == "":
		return false

	if cost > 0.0:
		GameState.use_stamina(cost)

	if is_instance_valid(main.hud):
		main.hud.toast(msg)
	if act != "none":
		spawn_effect("fx_" + act, farm.tile_center(tile.coord))

	if main.quest_mgr != null:
		match act:
			"harvest":
				main.quest_mgr.advance_progress("harvest", crop_id_before)
			"plant":
				main.quest_mgr.advance_progress("plant", selected_seed_before)
			"water":
				main.quest_mgr.advance_progress("water", "any")
			"till":
				main.quest_mgr.advance_progress("till", "any")
			"catch_pest":
				main.quest_mgr.advance_progress("catch_pest", "sau_bo")

	main.player.play_action_anim(act)
	main.player.can_move = false
	var act_time: float = main.player.get_action_duration(act)
	await main.get_tree().create_timer(act_time).timeout
	if not main.fishing and is_instance_valid(main.player):
		main.player.can_move = true
	return true


func spawn_effect(kind: String, pos: Vector2) -> void:
	if not is_instance_valid(main.world):
		return
	var spr := Sprite2D.new()
	spr.texture = TextureGen.get_tex(kind)
	spr.z_index = 50
	spr.position = pos
	main.world.add_child(spr)
	var tw := spr.create_tween()
	tw.tween_property(spr, "position:y", pos.y - 13.0, 0.45).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.45).set_delay(0.12)
	tw.tween_callback(spr.queue_free)


func face_towards(target_pos: Vector2) -> void:
	if not is_instance_valid(main.player):
		return
	var diff: Vector2 = target_pos - main.player.position
	if diff.length_squared() > 1.0:
		if absf(diff.x) >= absf(diff.y):
			main.player.facing = Vector2(signf(diff.x), 0)
		else:
			main.player.facing = Vector2(0, signf(diff.y))
