extends RefCounted
# Quản lý Xây Dựng Bản Đồ, Công Trình & Hệ Thống Thực Vật (World Builder & Foliage)

const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const CatHelperScript := preload("res://scripts/cat_helper.gd")

const WORLD_SIZE := Vector2(1900, 1000)
const HOUSE_POS := Vector2(641, 248)
const SHED_POS := Vector2(505, 248)
const TENT_POS := Vector2(766, 248)
const MAILBOX_POS := Vector2(720, 246)
const MAYOR_POS := Vector2(705, 270)
const MARKET_STALL_POS := Vector2(584, 440)
const MINE_ENTRANCE_POS := Vector2(96, 64)
const MINE_SIGN_POS := Vector2(56, 96)
const LEAH_MINER_POS := Vector2(136, 96)

const STAND_POS := Vector2(1580, 416)       # quầy Bác Tư
const STAND_HAI_POS := Vector2(1750, 416)   # quầy Chú Hai
const STAND_TU_POS := Vector2(1410, 416)    # quầy Cô Tư
const SCARECROW_NORTH_POS := Vector2(1048, 368) # bù nhìn rơm ở giữa Thửa Bắc
const SCARECROW_SOUTH_POS := Vector2(1048, 576) # bù nhìn rơm ở giữa Thửa Nam
const SCARECROW_POS := SCARECROW_NORTH_POS
const PLAYER_START := Vector2(650, 470)
const POND_RECT := Rect2(1232, 720, 416, 368)
const FISH_SPOT_POS := Vector2(1440, 880)

const PATH_COBBLE_V := Rect2(480, 480, 48, 384)
const PATH_COBBLE_H := Rect2(240, 672, 528, 48)

const PATHS := [
	Rect2(640, 240, 32, 224),    # từ cửa nhà xuống đại lộ (x: 640..672, y: 240..464)
	Rect2(80, 80, 32, 370),      # đường mòn từ đại lộ lên thẳng cửa hầm mỏ vách núi biên Bắc (x: 80..112, y: 80..450)
	Rect2(0, 448, 1850, 48),     # đại lộ đông - tây xuyên suốt qua sạp hàng và 2 cổng ruộng (x: 0..1850, y: 448..496)
	Rect2(1344, 352, 464, 96),   # khuôn viên chợ quê 3 quầy hàng liền sát đại lộ (x: 1344..1808, y: 352..448)
	Rect2(1424, 480, 32, 252),   # nhánh xuống bờ ao câu cá (x: 1424..1456, y: 480..732)
]

const FOLIAGE_TYPES := [
	{"name": "tree_oak", "weight": 20},
	{"name": "tree_maple", "weight": 20},
	{"name": "tree_pine", "weight": 18},
	{"name": "tree_broadleaf", "weight": 12},
	{"name": "bush_large", "weight": 8},
	{"name": "bush_med", "weight": 8},
	{"name": "bush_berry", "weight": 6},
	{"name": "bush_small", "weight": 5},
	{"name": "tree_stump", "weight": 3},
]

var main: Node2D
var world: Node2D
var ground: Sprite2D
var canvas_mod: CanvasModulate
var mailbox_badge: PanelContainer
var mailbox_data: Dictionary = {"hoes": 999, "coins": 999}
var foliage_nodes: Array = []
var foliage_data: Array = []

var shed_decor: StaticBody2D
var house_decor: StaticBody2D
var npc_leah: StaticBody2D


func setup(p_main: Node2D) -> void:
	main = p_main
	mailbox_data = default_mailbox_data()


func build_world() -> Node2D:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	main.add_child(world)

	canvas_mod = CanvasModulate.new()
	canvas_mod.color = Color.WHITE
	world.add_child(canvas_mod)

	ground = Sprite2D.new()
	ground.centered = false
	var farm_px := Rect2(824, 288, 448, 368)
	ground.texture = TextureGen.make_ground(int(WORLD_SIZE.x), int(WORLD_SIZE.y), farm_px, PATHS, POND_RECT, [PATH_COBBLE_V, PATH_COBBLE_H])
	world.add_child(ground)

	var cliff_top_ext := Sprite2D.new()
	cliff_top_ext.texture = TextureGen.get_tex("sdv_north_cliff_top")
	cliff_top_ext.position = Vector2(0, -160)
	cliff_top_ext.centered = false
	world.add_child(cliff_top_ext)

	return world


func build_residence_complex() -> void:
	shed_decor = add_decor(TextureGen.get_tex("shed"), SHED_POS, 1.0, Rect2())
	house_decor = add_decor(TextureGen.get_tex("house"), HOUSE_POS, 1.0, Rect2())
	add_decor(TextureGen.get_tex("tent"), TENT_POS, 1.0, Rect2())

	var body := StaticBody2D.new()
	body.name = "ResidenceCollision"

	var back_wall := CollisionShape2D.new()
	var bw_shape := RectangleShape2D.new()
	bw_shape.size = Vector2(400, 40)
	back_wall.shape = bw_shape
	back_wall.position = Vector2(580, 45)
	body.add_child(back_wall)

	var shed_col := CollisionShape2D.new()
	var shed_shape := RectangleShape2D.new()
	shed_shape.size = Vector2(110, 70)
	shed_col.shape = shed_shape
	shed_col.position = Vector2(505, 209)
	body.add_child(shed_col)

	var house_col := CollisionShape2D.new()
	var hm_shape := RectangleShape2D.new()
	hm_shape.size = Vector2(144, 70)
	house_col.shape = hm_shape
	house_col.position = Vector2(641, 209)
	body.add_child(house_col)

	var tent_col := CollisionShape2D.new()
	var tent_shape := RectangleShape2D.new()
	tent_shape.size = Vector2(40, 48)
	tent_col.shape = tent_shape
	tent_col.position = Vector2(766, 220)
	body.add_child(tent_col)

	world.add_child(body)


func build_mailbox() -> void:
	var tex := TextureGen.get_tex("mailbox")
	if tex == null:
		return
	var body := StaticBody2D.new()
	body.position = MAILBOX_POS
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.scale = Vector2(1.0, 1.0)
	spr.offset = Vector2(0, -tex.get_height() / 2.0)
	body.add_child(spr)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 10)
	col.shape = shape
	col.position = Vector2(0, -5)
	body.add_child(col)

	mailbox_badge = PanelContainer.new()
	mailbox_badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.16, 0.08, 0.95), UIKit.COLOR_BORDER_GOLD, 6))
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 4)
	mailbox_badge.add_child(bh)

	var star_ic := TextureRect.new()
	star_ic.texture = TextureGen.star_icon()
	star_ic.custom_minimum_size = Vector2(12, 12)
	star_ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	bh.add_child(star_ic)

	UIKit.label(bh, "Thư mới [E]", 11, UIKit.COLOR_TEXT_TITLE)
	mailbox_badge.position = Vector2(-36, -46)
	body.add_child(mailbox_badge)

	var tw := main.create_tween().set_loops()
	tw.tween_property(mailbox_badge, "position:y", -49.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(mailbox_badge, "position:y", -43.0, 0.7).set_trans(Tween.TRANS_SINE)

	world.add_child(body)
	update_mailbox_badge()


func default_mailbox_data() -> Dictionary:
	return {
		"hoes": 999,
		"coins": 9999,
		"feed": 30,
		"produce": {
			"tomato": 50,
			"corn": 50,
			"watermelon": 50,
			"strawberry": 50,
			"carrot": 50,
			"potato": 50,
			"rice": 50,
			"trung_ga": 50,
			"sua_bo": 30,
			"thit_lon": 30,
			"long_cuu": 20,
		},
		"fish": {
			"chep": 30,
			"hoi": 30,
			"tram": 30,
			"tre_vang": 20,
			"chien": 10,
		}
	}


func has_mailbox_items() -> bool:
	if int(mailbox_data.get("hoes", 0)) > 0 or int(mailbox_data.get("coins", 0)) > 0:
		return true
	var prod = mailbox_data.get("produce", {})
	if typeof(prod) == TYPE_DICTIONARY:
		for k in prod:
			if int(prod[k]) > 0:
				return true
	var fish = mailbox_data.get("fish", {})
	if typeof(fish) == TYPE_DICTIONARY:
		for k in fish:
			if int(fish[k]) > 0:
				return true
	return false


func update_mailbox_badge() -> void:
	if mailbox_badge == null:
		return
	mailbox_badge.visible = has_mailbox_items()


func build_mine_entrance() -> void:
	var cave_spr := Sprite2D.new()
	cave_spr.texture = TextureGen.get_tex("cave_entrance")
	cave_spr.position = MINE_ENTRANCE_POS
	world.add_child(cave_spr)

	wall(Vector2(56, 76), Vector2(48, 24))
	wall(Vector2(136, 76), Vector2(48, 24))

	var sign_spr := Sprite2D.new()
	sign_spr.texture = TextureGen.get_tex("mine_sign")
	sign_spr.position = MINE_SIGN_POS
	world.add_child(sign_spr)

	npc_leah = StaticBody2D.new()
	npc_leah.position = LEAH_MINER_POS
	var l_spr := Sprite2D.new()
	l_spr.texture = TextureGen.sdv_char_tex("Leah", "down", 0)
	l_spr.scale = Vector2(1.2, 1.2)
	l_spr.offset = Vector2(0, -14)
	npc_leah.add_child(l_spr)

	var l_col := CollisionShape2D.new()
	var l_shape := CircleShape2D.new()
	l_shape.radius = 6.0
	l_col.shape = l_shape
	npc_leah.add_child(l_col)

	var tw := l_spr.create_tween().set_loops()
	tw.tween_property(l_spr, "scale:y", 1.23, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(l_spr, "scale:y", 1.2, 1.2).set_trans(Tween.TRANS_SINE)

	world.add_child(npc_leah)


func add_shop_stall(shop_id: String, pos: Vector2, npc_obj: StaticBody2D) -> void:
	var back := Sprite2D.new()
	back.texture = TextureGen.get_tex("stand_%s_back" % shop_id)
	back.position = pos + Vector2(0, -18)
	world.add_child(back)

	npc_obj.position = pos + Vector2(0, 2)
	world.add_child(npc_obj)

	var front := StaticBody2D.new()
	front.position = pos + Vector2(0, 10)
	var spr := Sprite2D.new()
	spr.texture = TextureGen.get_tex("stand_%s_front" % shop_id)
	spr.offset = Vector2(0, -spr.texture.get_height() / 2.0)
	front.add_child(spr)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(76, 16)
	col.shape = shape
	col.position = Vector2(0, -6)
	front.add_child(col)
	world.add_child(front)


func build_fences() -> void:
	var fh: Texture2D = TextureGen.get_tex("fence_h")
	var fv: Texture2D = TextureGen.get_tex("fence_v")
	var f_gate: Texture2D = TextureGen.get_tex("gate_farm")
	var f_tl: Texture2D = TextureGen.get_tex("fence_corner_tl")
	var f_tr: Texture2D = TextureGen.get_tex("fence_corner_tr")
	var f_bl: Texture2D = TextureGen.get_tex("fence_corner_bl")
	var f_br: Texture2D = TextureGen.get_tex("fence_corner_br")

	var x_left := 808
	var x_right := 1288
	var farm_mid_x := (x_left + x_right) / 2.0
	var farm_width := float(x_right - x_left)

	# THỬA BẮC
	var n_ytop := 290
	var n_ybot := 446

	for x in range(x_left + 32, x_right, 32):
		add_sprite(fh, Vector2(x, n_ytop))
	add_sprite(f_tl, Vector2(x_left, n_ytop))
	add_sprite(f_tr, Vector2(x_right, n_ytop))
	add_sprite(f_bl, Vector2(x_left, n_ybot))
	add_sprite(f_br, Vector2(x_right, n_ybot))

	for y in [322, 354, 386, 418]:
		add_sprite(fv, Vector2(x_left, y))
		add_sprite(fv, Vector2(x_right, y))

	for x in [840, 872, 904, 936, 968, 1000, 1096, 1128, 1160, 1192, 1224, 1256]:
		add_sprite(fh, Vector2(x, n_ybot))
	add_sprite(f_gate, Vector2(farm_mid_x, n_ybot))

	wall(Vector2(farm_mid_x, n_ytop), Vector2(farm_width, 10))
	wall(Vector2(x_left, (n_ytop + n_ybot) / 2.0), Vector2(10, n_ybot - n_ytop))
	wall(Vector2(x_right, (n_ytop + n_ybot) / 2.0), Vector2(10, n_ybot - n_ytop))
	wall(Vector2((x_left + 1016) / 2.0, n_ybot), Vector2(1016 - x_left, 10))
	wall(Vector2((1080 + x_right) / 2.0, n_ybot), Vector2(x_right - 1080, 10))

	# THỬA NAM
	var s_ytop := 498
	var s_ybot := 654

	for x in [840, 872, 904, 936, 968, 1000, 1096, 1128, 1160, 1192, 1224, 1256]:
		add_sprite(fh, Vector2(x, s_ytop))
	add_sprite(f_gate, Vector2(farm_mid_x, s_ytop))

	add_sprite(f_tl, Vector2(x_left, s_ytop))
	add_sprite(f_tr, Vector2(x_right, s_ytop))
	add_sprite(f_bl, Vector2(x_left, s_ybot))
	add_sprite(f_br, Vector2(x_right, s_ybot))

	for y in [530, 562, 594, 626]:
		add_sprite(fv, Vector2(x_left, y))
		add_sprite(fv, Vector2(x_right, y))

	for x in range(x_left + 32, x_right, 32):
		add_sprite(fh, Vector2(x, s_ybot))

	wall(Vector2(farm_mid_x, s_ybot), Vector2(farm_width, 10))
	wall(Vector2(x_left, (s_ytop + s_ybot) / 2.0), Vector2(10, s_ybot - s_ytop))
	wall(Vector2(x_right, (s_ytop + s_ybot) / 2.0), Vector2(10, s_ybot - s_ytop))
	wall(Vector2((x_left + 1016) / 2.0, s_ytop), Vector2(1016 - x_left, 10))
	wall(Vector2((1080 + x_right) / 2.0, s_ytop), Vector2(x_right - 1080, 10))


func build_walls() -> void:
	var t := 40.0
	wall(Vector2(WORLD_SIZE.x / 2, 20.0), Vector2(WORLD_SIZE.x + t * 2, 120.0))
	wall(Vector2(WORLD_SIZE.x / 2, WORLD_SIZE.y + t / 2), Vector2(WORLD_SIZE.x + t * 2, t))
	wall(Vector2(-t / 2, WORLD_SIZE.y / 2), Vector2(t, WORLD_SIZE.y + t * 2))
	wall(Vector2(WORLD_SIZE.x + t / 2, WORLD_SIZE.y / 2), Vector2(t, WORLD_SIZE.y + t * 2))


func add_decor(tex: Texture2D, pos: Vector2, scl: float, collide: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.scale = Vector2(scl, scl)
	spr.offset = Vector2(0, -tex.get_height() / 2.0)
	body.add_child(spr)
	if collide.size != Vector2.ZERO:
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = collide.size
		col.shape = shape
		col.position = collide.position + collide.size / 2.0
		body.add_child(col)
	world.add_child(body)
	return body


func add_sprite(tex: Texture2D, pos: Vector2, parent: Node = null, spr_scale: Vector2 = Vector2.ONE) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.scale = spr_scale
	(parent if parent != null else world).add_child(s)
	return s


func wall(center: Vector2, size: Vector2, parent: Node = null) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	(parent if parent != null else world).add_child(body)


# --- Foliage System ---

func get_foliage_col_rect(f_name: String) -> Rect2:
	match f_name:
		"bush_large":
			return Rect2(-18, -14, 36, 14)
		"bush_med", "bush_berry":
			return Rect2(-12, -12, 24, 12)
		"bush_small":
			return Rect2(-10, -10, 20, 10)
		"tree_stump":
			return Rect2(-7, -14, 14, 14)
		"tree_broadleaf":
			return Rect2(-10, -16, 20, 16)
		_:
			return Rect2(-8, -14, 16, 14)


func random_foliage_type(rng: RandomNumberGenerator) -> String:
	var total_w := 0
	for item in FOLIAGE_TYPES:
		total_w += int(item.weight)
	var r := rng.randi_range(0, total_w - 1)
	var cur := 0
	for item in FOLIAGE_TYPES:
		cur += int(item.weight)
		if r < cur:
			return str(item.name)
	return "tree_oak"


func is_grass_surface(pos: Vector2) -> bool:
	if pos.x < 45.0 or pos.x > WORLD_SIZE.x - 45.0 or pos.y < 105.0 or pos.y > WORLD_SIZE.y - 50.0:
		return false

	for p in PATHS:
		if p.grow(28.0).has_point(pos):
			return false

	var farm_box_n := Rect2(824 - 40.0, 304 - 40.0, 448 + 80.0, 128 + 60.0)
	var farm_box_s := Rect2(824 - 40.0, 512 - 20.0, 448 + 80.0, 128 + 60.0)
	if farm_box_n.has_point(pos) or farm_box_s.has_point(pos):
		return false

	var house_box := Rect2(HOUSE_POS.x - 90.0, HOUSE_POS.y - 155.0, 185.0, 180.0)
	if house_box.has_point(pos):
		return false

	var shed_box := Rect2(SHED_POS.x - 65.0, SHED_POS.y - 140.0, 130.0, 160.0)
	if shed_box.has_point(pos):
		return false

	var tent_box := Rect2(TENT_POS.x - 30.0, TENT_POS.y - 70.0, 60.0, 80.0)
	if tent_box.has_point(pos):
		return false

	if pos.distance_to(CatHelperScript.WAITING_POS) < 32.0:
		return false

	if pos.distance_to(MAILBOX_POS) < 36.0:
		return false

	if pos.distance_to(MAYOR_POS) < 32.0:
		return false

	if pos.distance_to(SCARECROW_NORTH_POS) < 32.0 or pos.distance_to(SCARECROW_SOUTH_POS) < 32.0:
		return false

	if pos.distance_to(PLAYER_START) < 40.0:
		return false

	var pen_box := Rect2(230.0, 520.0, 550.0, 360.0)
	if pen_box.has_point(pos):
		return false

	if POND_RECT.grow(20.0).has_point(pos):
		return false

	var market_box := Rect2(STAND_TU_POS.x - 90.0, 330.0, 500.0, 130.0)
	if market_box.has_point(pos):
		return false

	var stall_box := Rect2(MARKET_STALL_POS.x - 65.0, MARKET_STALL_POS.y - 75.0, 130.0, 95.0)
	if stall_box.has_point(pos):
		return false

	var mine_box := Rect2(0.0, 140.0, 220.0, 160.0)
	if mine_box.has_point(pos):
		return false

	var dirt_patches: Array[Vector4i] = [
		Vector4i(6, 14, 4, 3), Vector4i(30, 8, 5, 3), Vector4i(46, 10, 4, 3), Vector4i(70, 7, 5, 3),
		Vector4i(88, 19, 4, 3), Vector4i(82, 36, 5, 4), Vector4i(86, 46, 4, 3), Vector4i(72, 48, 4, 3),
		Vector4i(34, 55, 5, 3), Vector4i(48, 52, 4, 3), Vector4i(78, 56, 5, 3), Vector4i(6, 42, 4, 3), Vector4i(8, 58, 4, 3),
	]
	for dp in dirt_patches:
		var cx := dp.x * 16.0
		var cy := dp.y * 16.0
		var rx := dp.z * 16.0
		var ry := dp.w * 16.0
		var dx := (pos.x - cx) / rx
		var dy := (pos.y - cy) / ry
		if dx * dx + dy * dy <= 1.0:
			return false

	return true


func clear_foliage() -> void:
	for node in foliage_nodes:
		if is_instance_valid(node):
			node.queue_free()
	foliage_nodes.clear()
	foliage_data.clear()


func spawn_foliage_item(f_name: String, pos: Vector2) -> StaticBody2D:
	var tex := TextureGen.get_tex(f_name)
	if tex == null:
		return null
	var col_rect := get_foliage_col_rect(f_name)
	var body: StaticBody2D = add_decor(tex, pos, 1.0, col_rect)
	foliage_nodes.append(body)
	foliage_data.append({"type": f_name, "x": pos.x, "y": pos.y})
	return body


func populate_random_foliage(target_count: int = 75, seed_val: int = 0) -> void:
	clear_foliage()
	var rng := RandomNumberGenerator.new()
	if seed_val != 0:
		rng.seed = seed_val
	else:
		rng.randomize()

	var attempts := 0
	var max_attempts := 3500
	var min_dist := 48.0

	while foliage_data.size() < target_count and attempts < max_attempts:
		attempts += 1
		var x := rng.randf_range(50.0, WORLD_SIZE.x - 50.0)
		var y := rng.randf_range(55.0, WORLD_SIZE.y - 55.0)
		var pt := Vector2(x, y)

		if not is_grass_surface(pt):
			continue

		var too_close := false
		for d in foliage_data:
			var ex_pt := Vector2(float(d.x), float(d.y))
			if pt.distance_to(ex_pt) < min_dist:
				too_close = true
				break
		if too_close:
			continue

		var f_type := random_foliage_type(rng)
		spawn_foliage_item(f_type, pt)


func load_foliage(saved_items: Array) -> void:
	clear_foliage()
	for item in saved_items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var px: float = float(item.get("x", 0.0))
		var py: float = float(item.get("y", 0.0))
		var pt := Vector2(px, py)
		if not is_grass_surface(pt):
			continue
		var f_type: String = str(item.get("type", "tree_oak"))
		spawn_foliage_item(f_type, pt)


func sprout_random_plant() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i in 100:
		var x := rng.randf_range(50.0, WORLD_SIZE.x - 50.0)
		var y := rng.randf_range(55.0, WORLD_SIZE.y - 55.0)
		var pt := Vector2(x, y)
		if not is_grass_surface(pt):
			continue
		var too_close := false
		for d in foliage_data:
			var ex_pt := Vector2(float(d.x), float(d.y))
			if pt.distance_to(ex_pt) < 48.0:
				too_close = true
				break
		if too_close:
			continue
		var plant_pool := ["bush_small", "bush_berry", "bush_med", "tree_oak", "tree_maple", "tree_pine"]
		var plant_type: String = plant_pool[rng.randi_range(0, plant_pool.size() - 1)]
		spawn_foliage_item(plant_type, pt)
		if is_instance_valid(main.hud):
			main.hud.toast("Một cây xanh vừa mọc tự nhiên trên bãi cỏ qua đêm! 🌱", Color(0.65, 0.95, 0.6))
		break
