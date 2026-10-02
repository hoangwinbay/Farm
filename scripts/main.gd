extends Node2D
# Bộ điều phối chính: xây thế giới, điều khiển vòng chơi, ngày/đêm, UI, lưu game.

const TextureGen := preload("res://scripts/texture_gen.gd")
const CropDB := preload("res://scripts/crop_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const FarmScript := preload("res://scripts/farm.gd")
const PlayerScript := preload("res://scripts/player.gd")
const NpcScript := preload("res://scripts/npc.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const ShopPanelScript := preload("res://scripts/ui/shop_panel.gd")
const FishShopScript := preload("res://scripts/ui/fish_shop.gd")
const PoultryShopScript := preload("res://scripts/ui/poultry_shop.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory_panel.gd")
const DialogueBoxScript := preload("res://scripts/ui/dialogue_box.gd")
const TitleScreenScript := preload("res://scripts/ui/title_screen.gd")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const MinimapScript := preload("res://scripts/ui/minimap.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

const WORLD_SIZE := Vector2(1500, 1000)
const FARM_ORIGIN := Vector2(420, 380)
const FARM_TILES := Vector2i(14, 9)
const HOUSE_POS := Vector2(250, 230)
const STAND_POS := Vector2(1180, 348)       # quầy Bác Tư
const STAND_HAI_POS := Vector2(1350, 348)   # quầy Chú Hai
const STAND_TU_POS := Vector2(1010, 348)    # quầy Cô Tư
const NPC_POS := Vector2(1180, 362)         # điểm tương tác Bác Tư
const CHU_HAI_POS := Vector2(1350, 362)     # điểm tương tác Chú Hai
const COTU_POS := Vector2(1010, 362)        # điểm tương tác Cô Tư
const SCARECROW_POS := Vector2(392, 356)
const PLAYER_START := Vector2(250, 470)
const POND_RECT := Rect2(940, 760, 180, 100)
const FISH_SPOT_POS := Vector2(1030, 810)   # tâm hồ — câu được ở MỌI bờ
# Khu chuồng: sân trong (y 560..660) + lưới ô chuồng 3 cột bên dưới.
# Mỗi LOẠI gia cầm một ô riêng; chuồng co/giãn theo số loại đang nuôi.
const PEN_RECT := Rect2(120, 560, 272, 108)
const PEN_COL_X := [128.0, 216.0, 304.0]  # mép trái 3 cột ô
const PEN_CELL := Vector2(80, 64)         # cỡ 1 ô chuồng
const PEN_GRID_TOP := 668.0               # mép trên hàng ô đầu tiên
const PEN_ROW_STEP := 72.0                # 64 ô + 8 divider
const PEN_SPOTS := [                      # chỗ đứng con vật trong ô (so tâm ô)
	Vector2(0, -8), Vector2(-18, 8), Vector2(18, 10),
	Vector2(-8, 18), Vector2(22, -6), Vector2(-24, -4),
]

# Mạng lối đi hình chữ nhật (24px) — trùng với đồ thị chỉ đường trong minimap.
# Đại lộ đông-tây + nhánh nhà, 3 nhánh quầy hàng, nhánh cổng chuồng, nhánh bờ ao.
const PATHS := [
	Rect2(238, 236, 24, 246),    # từ cửa nhà xuống đại lộ
	Rect2(238, 458, 1162, 24),   # đại lộ đông - tây (qua 2 cổng ruộng)
	Rect2(970, 370, 430, 24),    # lối chợ chạy trước 3 quầy
	Rect2(998, 394, 24, 64),     # nhánh lên quầy Cô Tư
	Rect2(1168, 394, 24, 64),    # nhánh lên quầy Bác Tư
	Rect2(1338, 394, 24, 64),    # nhánh lên quầy Chú Hai
	Rect2(292, 482, 24, 84),     # nhánh tới cổng chuồng gia cầm
	Rect2(1018, 482, 24, 266),   # nhánh xuống bờ ao câu cá
]

enum Mode { TITLE, PLAY, DIALOG, PANEL }

var mode: int = Mode.TITLE

var world: Node2D
var player: CharacterBody2D
var farm: Node2D
var npc: StaticBody2D
var npc_hai: StaticBody2D
var npc_tu: StaticBody2D
var pen_node: Node2D
var cam: Camera2D
var ground: Sprite2D
var canvas_mod: CanvasModulate
var highlight: Sprite2D

var hud: CanvasLayer
var shop_panel: CanvasLayer
var fish_shop: CanvasLayer
var poultry_shop: CanvasLayer
var inv_panel: CanvasLayer
var dialog_box: CanvasLayer
var title_screen: CanvasLayer
var pause_menu: CanvasLayer
var minimap: CanvasLayer
var fade_rect: ColorRect

var interactables: Array = []
var _npc_met := false
var _npc_hai_met := false
var _npc_tu_met := false
var _dialog_next := "shop"

var fishing := false
var fishing_left := 0.0
var _rod_spr: Sprite2D
var _bobber_spr: Sprite2D

var _debug_mode := ""
var _debug_frame := 0
var _clicktest := ""
var _clicktest_frame := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true  # chống trường hợp node Main bị ẩn vô tình trong editor
	_debug_mode = OS.get_environment("FARM_SHOT")
	_clicktest = OS.get_environment("FARM_CLICKTEST")

	_build_world()
	_build_ui()

	GameState.money_changed.connect(func(v: int) -> void: hud.set_money(v))
	GameState.crops_changed.connect(func() -> void: hud.rebuild_hotbar())
	Inventory.changed.connect(hud.rebuild_hotbar)
	shop_panel.feedback.connect(func(t: String) -> void: hud.toast(t, Color(1.0, 0.9, 0.5)))
	shop_panel.closed.connect(_close_panels)
	fish_shop.feedback.connect(func(t: String) -> void: hud.toast(t, Color(0.6, 0.9, 1.0)))
	fish_shop.closed.connect(_close_panels)
	poultry_shop.feedback.connect(func(t: String) -> void: hud.toast(t, Color(1.0, 0.7, 0.6)))
	poultry_shop.closed.connect(_close_panels)
	Inventory.changed.connect(_rebuild_pen)
	inv_panel.closed.connect(_close_panels)
	dialog_box.finished.connect(_on_dialog_finished)
	dialog_box.answered.connect(_on_sleep_answer)
	title_screen.start_requested.connect(start_new_game)
	title_screen.continue_requested.connect(continue_game)
	pause_menu.resumed.connect(_resume_from_pause)
	pause_menu.saved.connect(_save_now)
	pause_menu.menu_requested.connect(_back_to_title)

	hud.set_money(GameState.money)
	title_screen.open(SaveSystem.has_save())


# ---------------- xây thế giới ----------------

func _build_world() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

	canvas_mod = CanvasModulate.new()
	canvas_mod.color = Color.WHITE
	world.add_child(canvas_mod)

	# nền cỏ + đường + ao (bake 1 ảnh)
	ground = Sprite2D.new()
	ground.centered = false
	var farm_px := Rect2(FARM_ORIGIN, Vector2(FARM_TILES.x * 32, FARM_TILES.y * 32))
	ground.texture = TextureGen.make_ground(int(WORLD_SIZE.x), int(WORLD_SIZE.y), farm_px, PATHS, POND_RECT)
	world.add_child(ground)

	# nông trại + ô vuông chỉ điểm
	farm = FarmScript.new()
	farm.setup(FARM_ORIGIN, FARM_TILES)
	world.add_child(farm)
	highlight = Sprite2D.new()
	highlight.texture = TextureGen.get_tex("highlight")
	highlight.visible = false
	farm.add_child(highlight)

	# nhà (chỗ ngủ)
	_add_decor(TextureGen.get_tex("house"), HOUSE_POS, 1.5, Rect2(-66, -34, 132, 36))
	# bù nhìn
	_add_decor(TextureGen.get_tex("scarecrow"), SCARECROW_POS, 1.5, Rect2(0, 0, 0, 0))
	# cây
	for tpos in [
		Vector2(90, 130), Vector2(300, 90), Vector2(420, 110), Vector2(720, 90),
		Vector2(1010, 120), Vector2(1350, 110), Vector2(1150, 60), Vector2(1450, 300),
		Vector2(60, 360), Vector2(1450, 540), Vector2(80, 700), Vector2(700, 760),
		Vector2(740, 780), Vector2(500, 930), Vector2(820, 940), Vector2(1210, 900),
		Vector2(1430, 780), Vector2(960, 640),
	]:
		_add_decor(TextureGen.get_tex("tree"), tpos, 1.5, Rect2(-7, -8, 14, 10))

	_build_fences()
	_build_walls()

	# Khởi tạo 3 NPC
	npc = NpcScript.new()
	npc.npc_name = "Bác Tư"

	npc_hai = NpcScript.new()
	npc_hai.npc_name = "Chú Hai"

	npc_tu = NpcScript.new()
	npc_tu.npc_name = "Cô Tư"

	# Dựng 3 quầy hàng độc nhất với NPC đứng bên trong: Cô Tư, Bác Tư, Chú Hai
	_add_shop_stall("poultry", STAND_TU_POS, npc_tu)
	_add_shop_stall("seed", STAND_POS, npc)
	_add_shop_stall("fish", STAND_HAI_POS, npc_hai)

	# người chơi + camera
	player = PlayerScript.new()
	player.position = PLAYER_START
	world.add_child(player)
	cam = Camera2D.new()
	cam.zoom = Vector2(2, 2)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(WORLD_SIZE.x)
	cam.limit_bottom = int(WORLD_SIZE.y)
	player.add_child(cam)
	cam.make_current()
	cam.reset_smoothing()

	# ao: hồ là ellipse — chặn đi xuống nước bằng tường ellipse, nhưng câu được ở mọi bờ
	_add_ellipse_wall(POND_RECT.get_center(), 88, 48)

	# khu chuồng nuôi: hàng rào + nhà chuồng + nơi con vật đứng
	_build_pen()

	interactables = [
		{"pos": HOUSE_POS + Vector2(0, 16), "r": 54.0, "label": "Ngủ (sang ngày mới + lưu game)", "cb": _ask_sleep},
		{"pos": NPC_POS, "r": 60.0, "label": "Bác Tư — hạt giống & nông sản", "cb": _talk_npc},
		{"pos": CHU_HAI_POS, "r": 60.0, "label": "Chú Hai — cần câu & thu mua cá", "cb": _talk_hai},
		{"pos": COTU_POS, "r": 60.0, "label": "Cô Tư — mua gia cầm & chuồng", "cb": _talk_tu},
		{"pos": PEN_RECT.get_center() + Vector2(0, 4), "r": 75.0, "label": "Thu sản phẩm chăn nuôi", "cb": _collect_products},
		{"pos": FISH_SPOT_POS, "r": 152.0, "label": "Thả câu cá (15 giây)", "cb": _start_fishing},
	]


func _add_shop_stall(shop_id: String, pos: Vector2, npc_obj: StaticBody2D) -> void:
	# 1. Phần mái & giá kệ phía sau (y nhỏ hơn -> vẽ phía sau NPC)
	var back := Sprite2D.new()
	back.texture = TextureGen.get_tex("stand_%s_back" % shop_id)
	back.position = pos + Vector2(0, -18)
	world.add_child(back)

	# 2. NPC đứng tại quầy (đầu và mặt nằm trọn vẹn dưới mái che)
	npc_obj.position = pos + Vector2(0, 2)
	world.add_child(npc_obj)

	# 3. Quầy bán hàng & nông sản phía trước (y lớn hơn -> chỉ che chân và thắt lưng của NPC)
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


func _add_ellipse_wall(center: Vector2, rx: float, ry: float) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var col := CollisionShape2D.new()
	var shape := ConvexPolygonShape2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	shape.points = pts
	col.shape = shape
	body.add_child(col)
	world.add_child(body)


func _build_pen() -> void:
	pen_node = Node2D.new()
	pen_node.name = "Pen"
	pen_node.position = Vector2(120, 560)
	world.add_child(pen_node)
	_rebuild_pen()


# Dựng lại toàn khu chuồng: rào ngoại vi, sân trong, lưới ô chuồng
# (mỗi LOẠI gia cầm một ô riêng) và các con vật trong ô của chúng.
func _rebuild_pen() -> void:
	if pen_node == null:
		return
	for c in pen_node.get_children():
		c.queue_free()

	var fh := TextureGen.get_tex("fence_h")
	var fv := TextureGen.get_tex("fence_v")
	var fc := TextureGen.get_tex("fence_corner")
	var org := Vector2(120, 560)  # mọi toạ độ con là toạ độ thế giới trừ org

	# Các loại đang nuôi, xếp theo thứ tự DB để ô không đổi chỗ khi mua/bán
	var species: Array = []
	for d in PoultryDB.ANIMALS:
		for a in Inventory.animals:
			if str(a.id) == str(d.id):
				species.append(str(d.id))
				break
	var rows: int = int(ceil(species.size() / float(PEN_COL_X.size())))
	var y_s := 660.0 + PEN_ROW_STEP * rows  # mép trên dải rào đóng đáy chuồng

	# 1. Nền rơm phủ toàn khu chuồng
	var bedding := Sprite2D.new()
	bedding.texture = TextureGen.get_tex("pen_bedding")
	bedding.position = Vector2(136.0, (y_s - 552.0) / 2.0)
	bedding.scale = Vector2(272.0 / 224.0, (y_s - 552.0) / 128.0)
	bedding.z_index = -1
	pen_node.add_child(bedding)

	# 2. Hàng rào ngoại vi — cổng giữ nguyên ở x 280..328
	for x in [136, 168, 200, 232, 264, 344, 376]:
		_add_sprite(fh, Vector2(x, 560.0) - org, pen_node)
	_add_sprite(TextureGen.get_tex("gate_coop"), Vector2(304, 560.0) - org, pen_node)
	for y in range(576, int(y_s) + 8, 32):
		_add_sprite(fv, Vector2(120.0, y) - org, pen_node)
		_add_sprite(fv, Vector2(392.0, y) - org, pen_node)
	for x in range(136, 392, 32):
		_add_sprite(fh, Vector2(x, y_s + 8.0) - org, pen_node)
	for cpos in [Vector2(120, 560), Vector2(392, 560), Vector2(120, y_s + 8), Vector2(392, y_s + 8)]:
		_add_sprite(fc, cpos - org, pen_node)

	# 3. Sân trong: nhà chuồng, máng ăn/nước, ổ đẻ, đống rơm
	var coop := StaticBody2D.new()
	coop.position = Vector2(56, 54)
	var coop_spr := Sprite2D.new()
	coop_spr.texture = TextureGen.get_tex("coop")
	coop.add_child(coop_spr)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(50, 28)
	col.shape = shape
	col.position = Vector2(0, 4)
	coop.add_child(col)
	pen_node.add_child(coop)
	_add_sprite(TextureGen.get_tex("hay_bale"), Vector2(234, 82), pen_node)
	_add_sprite(TextureGen.get_tex("trough"), Vector2(130, 52), pen_node)
	_add_sprite(TextureGen.get_tex("water_trough"), Vector2(130, 70), pen_node)
	_add_sprite(TextureGen.get_tex("nest_box"), Vector2(212, 52), pen_node)

	# 4. Va chạm: ngoại vi + dải ngang trước từng hàng ô (chừa lỗ 32px giữa mỗi cột)
	var pwall := func(center: Vector2, size: Vector2) -> void:
		_wall(center - org, size, pen_node)
	pwall.call(Vector2(200, 564), Vector2(160, 8))
	pwall.call(Vector2(360, 564), Vector2(64, 8))
	pwall.call(Vector2(120, (568.0 + y_s) / 2.0), Vector2(8, y_s - 552.0))
	pwall.call(Vector2(392, (568.0 + y_s) / 2.0), Vector2(8, y_s - 552.0))
	pwall.call(Vector2(256, y_s + 4.0), Vector2(272, 8))
	for r in rows:
		var yb := 660.0 + PEN_ROW_STEP * r + 4.0
		pwall.call(Vector2(136, yb), Vector2(32, 8))
		pwall.call(Vector2(212, yb), Vector2(56, 8))
		pwall.call(Vector2(300, yb), Vector2(56, 8))
		pwall.call(Vector2(376, yb), Vector2(32, 8))
		for x in [136, 212, 300, 376]:
			_add_sprite(fh, Vector2(x, 664.0 + PEN_ROW_STEP * r) - org, pen_node)
	if rows > 0:
		var colh := y_s - 668.0
		pwall.call(Vector2(212, 668.0 + colh / 2.0), Vector2(8, colh))
		pwall.call(Vector2(300, 668.0 + colh / 2.0), Vector2(8, colh))
		for cx in [212.0, 300.0]:
			for y in range(676, int(y_s), 32):
				_add_sprite(fv, Vector2(cx, y) - org, pen_node)

	# 5. Ô chuồng: biển tên từng loại, ô chưa dùng hiện "Trống"
	var total_slots: int = rows * PEN_COL_X.size()
	for i in total_slots:
		var cx: float = PEN_COL_X[i % PEN_COL_X.size()]
		var cy := PEN_GRID_TOP + PEN_ROW_STEP * floori(i / float(PEN_COL_X.size()))
		var badge := PanelContainer.new()
		if i < species.size():
			badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.18, 0.12, 0.06, 0.92), UIKit.COLOR_BORDER_GOLD, 4))
			UIKit.label(badge, str(PoultryDB.get_animal(species[i]).name), 10, UIKit.COLOR_TEXT_TITLE)
		else:
			badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07, 0.8), Color(0.32, 0.26, 0.2), 4))
			UIKit.label(badge, "Ô trống", 10, UIKit.COLOR_TEXT_MUTED)
		badge.position = Vector2(cx - 120.0, cy - 560.0) + Vector2(2, 1)
		pen_node.add_child(badge)

	# 6. Con vật: mỗi loại đứng trong ô của nó
	if species.size() > 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = 777
		var used := {}
		for a in Inventory.animals:
			var sid := str(a.id)
			var ci: int = species.find(sid)
			var cx: float = PEN_COL_X[ci % PEN_COL_X.size()]
			var cy := PEN_GRID_TOP + PEN_ROW_STEP * floori(ci / float(PEN_COL_X.size()))
			var k: int = int(used.get(sid, 0))
			used[sid] = k + 1
			var animal_node := Node2D.new()
			animal_node.position = Vector2(cx + PEN_CELL.x / 2.0, cy + PEN_CELL.y / 2.0) \
					+ PEN_SPOTS[k % PEN_SPOTS.size()] \
					+ Vector2(rng.randf_range(-4, 4), rng.randf_range(-3, 3)) - org
			pen_node.add_child(animal_node)

			var d := PoultryDB.get_animal(sid)
			if d.is_empty():
				continue
			var spr := Sprite2D.new()
			spr.texture = TextureGen.animal_sprite(str(d.shape), str(d.color))
			spr.scale = Vector2(1.5, 1.5)
			animal_node.add_child(spr)

			# Hiệu ứng mổ thóc / cử động sống động
			var tw := animal_node.create_tween().set_loops()
			var delay := rng.randf_range(0.2, 1.8)
			tw.tween_interval(delay)
			tw.tween_property(spr, "position:y", 2.0, 0.15)
			tw.tween_interval(0.1)
			tw.tween_property(spr, "position:y", 0.0, 0.15)
			tw.tween_interval(rng.randf_range(1.5, 3.0))

			# Bong bóng trứng nổi trên đầu nếu con này có sản phẩm chờ thu
			if int(a.get("ready", 0)) > 0:
				var egg_bubble := Sprite2D.new()
				egg_bubble.texture = TextureGen.orb_icon(str(d.product_color))
				egg_bubble.scale = Vector2(0.85, 0.85)
				egg_bubble.position = Vector2(0, -18)
				animal_node.add_child(egg_bubble)

				var btw := egg_bubble.create_tween().set_loops()
				btw.tween_property(egg_bubble, "position:y", -21.0, 0.5).set_trans(Tween.TRANS_SINE)
				btw.tween_property(egg_bubble, "position:y", -17.0, 0.5).set_trans(Tween.TRANS_SINE)

	# 7. Biển báo thu hoạch nổi trên sân nếu có sản phẩm
	var total_ready: int = Inventory.ready_products()
	if total_ready > 0:
		var harvest_sign := Node2D.new()
		harvest_sign.position = Vector2(48, 30)
		pen_node.add_child(harvest_sign)

		var sign_bubble := PanelContainer.new()
		sign_bubble.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.16, 0.08, 0.95), UIKit.COLOR_BORDER_GOLD, 6))
		var sh := HBoxContainer.new()
		sh.add_theme_constant_override("separation", 4)
		sign_bubble.add_child(sh)

		var e_ic := TextureRect.new()
		e_ic.texture = TextureGen.star_icon()
		e_ic.custom_minimum_size = Vector2(14, 14)
		e_ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		sh.add_child(e_ic)

		UIKit.label(sh, "Thu hoạch (%d) [E]" % total_ready, 12, UIKit.COLOR_TEXT_TITLE)
		harvest_sign.add_child(sign_bubble)
		sign_bubble.position = Vector2(-sign_bubble.get_combined_minimum_size().x / 2.0, -10)

		var stw := harvest_sign.create_tween().set_loops()
		stw.tween_property(harvest_sign, "position:y", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		stw.tween_property(harvest_sign, "position:y", 6.0, 0.6).set_trans(Tween.TRANS_SINE)




func _add_decor(tex: Texture2D, pos: Vector2, scl: float, collide: Rect2) -> void:
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


func _build_fences() -> void:
	var fh: Texture2D = TextureGen.get_tex("fence_h")
	var fv: Texture2D = TextureGen.get_tex("fence_v")
	var fc: Texture2D = TextureGen.get_tex("fence_corner")
	var y_top := int(FARM_ORIGIN.y - 8)
	var y_bot := int(FARM_ORIGIN.y + FARM_TILES.y * 32 + 4)
	var x_left := int(FARM_ORIGIN.x - 12)
	var x_right := int(FARM_ORIGIN.x + FARM_TILES.x * 32 + 12)

	# 1. Hàng ngang trên + dưới liền kín
	for x in range(int(FARM_ORIGIN.x) + 16, int(FARM_ORIGIN.x + FARM_TILES.x * 32) - 15, 32):
		_add_sprite(fh, Vector2(x, y_top))
		_add_sprite(fh, Vector2(x, y_bot))

	# 2. Hai cột dọc — Tây và Đông chừa cửa đi qua
	var door_w1 := FARM_ORIGIN.y + 2 * 32
	var door_w2 := FARM_ORIGIN.y + 4 * 32
	for y in range(y_top + 16, y_bot, 32):
		if y > door_w1 and y < door_w2:
			continue
		_add_sprite(fv, Vector2(x_left, y))
		_add_sprite(fv, Vector2(x_right, y))

	# 3. Bốn cọc góc vững chãi cho hàng rào ruộng
	_add_sprite(fc, Vector2(x_left, y_top))
	_add_sprite(fc, Vector2(x_right, y_top))
	_add_sprite(fc, Vector2(x_left, y_bot))
	_add_sprite(fc, Vector2(x_right, y_bot))

	# Va chạm: tây/đông mở cửa giữa, nam/bắc liền kín
	_wall(Vector2(FARM_ORIGIN.x + FARM_TILES.x * 16, y_top), Vector2(FARM_TILES.x * 32, 10))
	_wall(Vector2(FARM_ORIGIN.x + FARM_TILES.x * 16, y_bot), Vector2(FARM_TILES.x * 32, 10))
	_wall(Vector2(x_left, (y_top - 6 + door_w1) / 2.0), Vector2(10, door_w1 - y_top + 6))
	_wall(Vector2(x_left, (door_w2 + y_bot + 8) / 2.0), Vector2(10, y_bot + 8 - door_w2))
	_wall(Vector2(x_right, (y_top - 6 + door_w1) / 2.0), Vector2(10, door_w1 - y_top + 6))
	_wall(Vector2(x_right, (door_w2 + y_bot + 8) / 2.0), Vector2(10, y_bot + 8 - door_w2))

	# 4. Hai khung cổng DỌC nghệ thuật tại cửa Tây & Đông
	for door_x in [x_left, x_right]:
		_add_sprite(TextureGen.get_tex("gate_v"), Vector2(door_x, (door_w1 + door_w2) / 2.0))


func _add_sprite(tex: Texture2D, pos: Vector2, parent: Node = null) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	(parent if parent != null else world).add_child(s)


func _build_walls() -> void:
	var t := 40.0
	_wall(Vector2(WORLD_SIZE.x / 2, -t / 2), Vector2(WORLD_SIZE.x + t * 2, t))
	_wall(Vector2(WORLD_SIZE.x / 2, WORLD_SIZE.y + t / 2), Vector2(WORLD_SIZE.x + t * 2, t))
	_wall(Vector2(-t / 2, WORLD_SIZE.y / 2), Vector2(t, WORLD_SIZE.y + t * 2))
	_wall(Vector2(WORLD_SIZE.x + t / 2, WORLD_SIZE.y / 2), Vector2(t, WORLD_SIZE.y + t * 2))


func _wall(center: Vector2, size: Vector2, parent: Node = null) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	(parent if parent != null else world).add_child(body)


# ---------------- xây UI ----------------

func _build_ui() -> void:
	hud = HudScript.new()
	add_child(hud)
	shop_panel = ShopPanelScript.new()
	add_child(shop_panel)
	fish_shop = FishShopScript.new()
	add_child(fish_shop)
	poultry_shop = PoultryShopScript.new()
	add_child(poultry_shop)
	inv_panel = InventoryPanelScript.new()
	add_child(inv_panel)
	pause_menu = PauseMenuScript.new()
	add_child(pause_menu)
	dialog_box = DialogueBoxScript.new()
	add_child(dialog_box)
	title_screen = TitleScreenScript.new()
	add_child(title_screen)
	minimap = MinimapScript.new()
	add_child(minimap)
	minimap.setup(ground.texture, player, world, self)
	minimap.toast_cb = func(t: String, c: Color) -> void: hud.toast(t, c)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 60
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)


# ---------------- vòng chơi ----------------

func _process(delta: float) -> void:
	if _debug_mode != "":
		_debug_step()
	if _clicktest != "":
		_clicktest_step()
	minimap.visible = mode == Mode.PLAY
	if mode != Mode.PLAY or get_tree().paused:
		return
	GameState.tick(delta)
	Inventory.tick_animals(delta)
	hud.set_clock(GameState.clock_text())
	canvas_mod.color = _tint()
	_update_hint_and_highlight()
	if fishing:
		fishing_left -= delta
		hud.set_hint("Đang thả câu... còn %d giây" % int(ceil(maxf(fishing_left, 0.0))))
		highlight.visible = false
		if fishing_left <= 0.0:
			_finish_fishing()
	if GameState.clock >= GameState.COLLAPSE_MIN and GameState.clock < GameState.DAY_START:
		_do_sleep(true)  # 2h sáng chưa ngủ -> gục ngã


func _tint() -> Color:
	# 7:00 - 19:00 trời sáng; 19:00 - 7:00 đêm dịu (ruộng vẫn nhìn rõ màu nâu)
	var t := GameState.clock
	var night := Color(0.68, 0.72, 0.92)
	var day := Color.WHITE
	if t < 420:
		# 0:00-6:00 đêm; 6:00-7:00 chuyển sáng
		return night.lerp(day, clampf((t - 360) / 60.0, 0, 1))
	if t < 1140:
		return day
	if t < 1200:
		# 19:00-20:00 chuyển tối
		return day.lerp(night, clampf((t - 1140) / 60.0, 0, 1))
	return night


func _update_hint_and_highlight() -> void:
	var near := _nearest_interactable()
	if not near.is_empty():
		highlight.visible = false
		var lbl: String = str(near.label)
		if near.pos == PEN_RECT.get_center() + Vector2(0, 4):
			var r_count := Inventory.ready_products()
			if r_count > 0:
				lbl = "Thu hoạch %d sản phẩm chăn nuôi 🥚" % r_count
			elif Inventory.animals.size() > 0:
				lbl = "Chuồng gia cầm (%d con đang lớn) 🌾" % Inventory.animals.size()
			else:
				lbl = "Chuồng gia cầm (Gặp Cô Tư mua giống)"
		hud.set_hint("E: " + lbl)
		return
	var tile = farm.tile_at_world(player.get_facing_point())
	if tile == null:
		highlight.visible = false
		hud.set_hint("")
		return
	var info: Dictionary = farm.action_at(tile)
	highlight.visible = true
	highlight.global_position = farm.tile_center(tile.coord)
	highlight.modulate = Color(0.5, 1.0, 0.5, 0.95) if bool(info.ok) else Color(1, 1, 1, 0.35)
	hud.set_hint(("E: " + str(info.label)) if str(info.label) != "" else "")


func _nearest_interactable() -> Dictionary:
	var best := {}
	var best_d := INF
	for it in interactables:
		var d: float = player.position.distance_to(it.pos)
		if d <= float(it.r) and d < best_d:
			best_d = d
			best = it
	return best


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if mode == Mode.PLAY and not get_tree().paused:
			pause_menu.open()
			get_tree().paused = true
		elif pause_menu.visible:
			_resume_from_pause()
		elif shop_panel.visible or inv_panel.visible:
			_close_panels()
	elif event.is_action_pressed("interact"):
		if mode == Mode.PLAY and not get_tree().paused:
			_do_interact()
		elif mode == Mode.DIALOG:
			dialog_box.advance()
	elif event.is_action_pressed("inventory"):
		if mode == Mode.PLAY and not get_tree().paused:
			_open_inventory()
		elif inv_panel.visible:
			_close_panels()
	elif event.is_action_pressed("cycle_seed") and mode == Mode.PLAY and not get_tree().paused:
		var id := Inventory.cycle_seed()
		var c := CropDB.get_crop(id)
		if not c.is_empty():
			hud.toast("Đổi hạt: %s" % c.name)


# ---------------- hành động ----------------

func _do_interact() -> void:
	if fishing:
		return
	var near := _nearest_interactable()
	if not near.is_empty():
		near.cb.call()
		return
	var tile = farm.tile_at_world(player.get_facing_point())
	if tile == null:
		return
	var info: Dictionary = farm.action_at(tile)
	var msg: String = farm.perform_at(tile)
	if msg == "":
		return
	hud.toast(msg)
	var act := str(info.act)
	if act != "none":
		_spawn_effect("fx_" + act, farm.tile_center(tile.coord))
	player.play_action_anim()
	player.can_move = false
	await get_tree().create_timer(0.25).timeout
	if not fishing:
		player.can_move = true


# Hiệu ứng nhỏ bốc lên rồi tan (đất bay / hạt giống / giọt nước / sao vàng).
func _spawn_effect(kind: String, pos: Vector2) -> void:
	var spr := Sprite2D.new()
	spr.texture = TextureGen.get_tex(kind)
	spr.z_index = 50
	spr.position = pos
	world.add_child(spr)
	var tw := spr.create_tween()
	tw.tween_property(spr, "position:y", pos.y - 13.0, 0.45).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.45).set_delay(0.12)
	tw.tween_callback(spr.queue_free)


func _talk_npc() -> void:
	mode = Mode.DIALOG
	get_tree().paused = true
	_dialog_next = "shop"
	if _npc_met:
		dialog_box.start("Bác Tư", ["Cần gì nữa con? Mua hạt giống hay bán nông sản nào?"])
	else:
		dialog_box.start("Bác Tư", [
			"Chào con! Chào mừng đến với nông trại nhỏ của bác.",
			"Làm ruộng thế này: MUA CUỐC -> CÀY đất -> GIEO hạt -> TƯỚI nước cho đủ ẩm -> THU HOẠCH khi cây chín.",
			"Cây lớn dần theo thời gian khi đất ẩm — đất khô sau chừng 4 phút thì tưới lại đó con!",
			"Rồi mang nông sản ra quầy bán. ĐỦ TIỀN thì mở khóa được cây mới, càng về sau càng giá trị!",
			"Muốn câu cá thì ra AO gặp Chú Hai mua cần câu đó con!",
		])
		_npc_met = true


func _talk_hai() -> void:
	mode = Mode.DIALOG
	get_tree().paused = true
	_dialog_next = "fish"
	if _npc_hai_met:
		dialog_box.start("Chú Hai", ["Cá gì nữa con? Mua cần câu hay bán cá nào?"])
	else:
		dialog_box.start("Chú Hai", [
			"Chào con! Chú Hai đây — buôn cá tôm bốn phương!",
			"Mua cần câu của chú rồi ra AO phía sau thả câu. Mỗi lần thả phải chờ 15 giây mới kéo được!",
			"Nghe đồn: đêm đêm cá Trê Vàng mới chịu lên, và dưới dòng sông còn có Cá Chiên huyền thoại...",
			"Cá câu được bán lại cho chú giá tốt lắm con!",
		])
		_npc_hai_met = true


func _on_dialog_finished() -> void:
	if _dialog_next == "fish":
		_open_fish_shop()
	elif _dialog_next == "poultry":
		_open_poultry_shop()
	else:
		_open_shop()


func _open_shop() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	shop_panel.open()


func _open_fish_shop() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	fish_shop.open()


func _open_poultry_shop() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	poultry_shop.open()


func _talk_tu() -> void:
	mode = Mode.DIALOG
	get_tree().paused = true
	_dialog_next = "poultry"
	if _npc_hai_met:
		dialog_box.start("Cô Tư", ["Gia cầm khỏe mạnh hết nấy con! Mua chuồng, mua giống hay bán sản phẩm?"])
	else:
		dialog_box.start("Cô Tư", [
			"Chào con! Cô Tư đây — giống gia cầm chuẩn nhất vùng!",
			"Muốn nuôi thì phải MUA CHUỒNG trước: chuồng nhỏ nuôi Gà/Vịt/Ngan/Cút/Bồ câu, chuồng lớn nuôi Ngỗng/Trĩ/Đà điểu.",
			"Mua giống về thả vào chuồng, chúng tự cho sản phẩm — nhớ quay lại thu hoạch nhé!",
			"Thịt, trứng, lông cô thu mua giá ngon lắm đó con!",
		])
	_npc_tu_met = true


func _collect_products() -> void:
	var n: int = Inventory.collect_products()
	if n > 0:
		hud.toast("Đã thu %d sản phẩm chăn nuôi! Bán cho Cô Tư." % n, Color(1.0, 0.75, 0.5))
	else:
		hud.toast("Chưa có sản phẩm nào chờ thu...", Color(0.8, 0.8, 0.8))


func _open_inventory() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	inv_panel.open()


func _close_panels() -> void:
	shop_panel.visible = false
	fish_shop.visible = false
	poultry_shop.visible = false
	inv_panel.visible = false
	pause_menu.visible = false
	get_tree().paused = false
	if mode != Mode.TITLE:
		mode = Mode.PLAY


func _resume_from_pause() -> void:
	pause_menu.close()
	get_tree().paused = false
	if mode != Mode.TITLE:
		mode = Mode.PLAY


func _save_now() -> void:
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met)
	hud.toast("Đã lưu game!", Color(0.6, 1.0, 0.6))


func _back_to_title() -> void:
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met)
	_close_panels()
	mode = Mode.TITLE
	dialog_box.force_close()
	title_screen.open(SaveSystem.has_save())


# ---------------- ngủ qua đêm ----------------

func _ask_sleep() -> void:
	mode = Mode.DIALOG
	get_tree().paused = true
	dialog_box.ask("Ngủ đến ngày mai? (Game sẽ tự lưu — cây vẫn lớn khi đất còn ẩm)")


func _on_sleep_answer(yes: bool) -> void:
	if yes:
		_do_sleep(false)
	else:
		mode = Mode.PLAY
		get_tree().paused = false


func _do_sleep(forced: bool) -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	dialog_box.force_close()
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.45)
	await tw.finished
	GameState.sleep_to_morning()
	var ready_n: int = farm.ready_count()
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met)
	hud.set_clock(GameState.clock_text())
	canvas_mod.color = _tint()
	if forced:
		hud.toast("Bạn gục ngã vì kiệt sức...", Color(1.0, 0.55, 0.45))
	hud.toast("Ngày mới! %d cây đã chín chờ thu hoạch." % ready_n, Color(0.65, 1.0, 0.6))
	var tw2 := create_tween()
	tw2.tween_property(fade_rect, "modulate:a", 0.0, 0.6)
	await tw2.finished
	if mode == Mode.PANEL:
		mode = Mode.PLAY
	get_tree().paused = false


# ---------------- câu cá ----------------

func _start_fishing() -> void:
	if fishing:
		return
	var tier := str(Inventory.take_cast())
	if tier == "":
		hud.toast("Hết lượt câu! Mua cần câu ở Chú Hai (bờ ao).", Color(1.0, 0.6, 0.5))
		return
	var rod := FishDB.get_rod(tier)
	fishing = true
	fishing_left = FishDB.FISH_TIME
	player.can_move = false
	hud.toast("Đã thả câu (%s — còn %d lượt)" % [rod.name, Inventory.total_casts()], Color(0.6, 0.9, 1.0))
	# animation: cần câu trên tay + phao nhấp nhô trên mặt nước
	var dir := (POND_RECT.get_center() - player.position).normalized()
	_rod_spr = Sprite2D.new()
	_rod_spr.texture = TextureGen.get_tex("fx_rod")
	_rod_spr.z_index = 50
	_rod_spr.position = player.position + Vector2(dir.x * 12.0, dir.y * 12.0 - 10.0)
	world.add_child(_rod_spr)
	_bobber_spr = Sprite2D.new()
	_bobber_spr.texture = TextureGen.get_tex("fx_bobber")
	_bobber_spr.z_index = 50
	_bobber_spr.position = player.position + dir * 46.0
	world.add_child(_bobber_spr)
	var bob := _bobber_spr.create_tween().set_loops()
	bob.tween_property(_bobber_spr, "position:y", _bobber_spr.position.y - 2.0, 0.5).set_ease(Tween.EASE_OUT)
	bob.tween_property(_bobber_spr, "position:y", _bobber_spr.position.y, 0.5).set_ease(Tween.EASE_IN)


func _finish_fishing() -> void:
	fishing = false
	player.can_move = true
	var bobber_pos := _bobber_spr.position if _bobber_spr != null else POND_RECT.get_center()
	if _rod_spr != null:
		_rod_spr.queue_free()
		_rod_spr = null
	if _bobber_spr != null:
		_bobber_spr.queue_free()
		_bobber_spr = null
	_spawn_effect("fx_water", bobber_pos)
	var night := GameState.clock < GameState.DAY_START or GameState.clock >= 1140
	var f := FishDB.roll_cast(night)
	if f.is_empty():
		hud.toast("Kéo cần lên... không con cá nào cắn!", Color(0.8, 0.8, 0.8))
		return
	Inventory.add_fish(str(f.id), 1)
	if str(f.tier) == "legend":
		hud.toast("HUYỀN THOẠI! Bắt được %s!!!" % f.name, Color(1.0, 0.85, 0.3))
	elif str(f.tier) == "rare":
		hud.toast("Bắt được cá hiếm: %s!" % f.name, Color(0.6, 1.0, 0.9))
	else:
		hud.toast("Bắt được %s! Bán cho Chú Hai." % f.name)


# ---------------- bắt đầu / tiếp tục ----------------

func start_new_game() -> void:
	GameState.reset_new_game()
	Inventory.reset()
	Inventory.selected_seed = "rice"
	Inventory.add_hoes(2)
	Inventory.add_seed("rice", 2)
	farm.reset_all()
	player.position = PLAYER_START
	player.facing = Vector2.DOWN
	cam.reset_smoothing()
	_npc_met = false
	dialog_box.force_close()
	title_screen.hide_me()
	get_tree().paused = false
	mode = Mode.PLAY
	hud.toast("Chào mừng đến Nông Trại Việt!", Color(1.0, 0.87, 0.35))
	hud.toast("WASD: di chuyển · E: tương tác · I: kho đồ")


func continue_game() -> void:
	var d := SaveSystem.load_data()
	if d.is_empty():
		start_new_game()
		return
	GameState.money = int(d.get("money", 100))
	GameState.day = int(d.get("day", 1))
	GameState.clock = float(d.get("clock", GameState.DAY_START))
	var unl: Array = []
	for id in d.get("unlocked", ["rice"]):
		unl.append(str(id))
	GameState.unlocked = unl
	GameState.money_changed.emit(GameState.money)
	GameState.crops_changed.emit()
	Inventory.set_state({
		"seeds": d.get("seeds", {}),
		"produce": d.get("produce", {}),
		"sel": d.get("sel", ""),
		"hoes": d.get("hoes", 0),
		"rods": d.get("rods", {}),
		"fish": d.get("fish", {}),
		"coops": d.get("coops", {}),
		"animals": d.get("animals", []),
	})
	var farm_arr = d.get("farm", [])
	if typeof(farm_arr) == TYPE_ARRAY:
		farm.apply_state(farm_arr)
	var pp: Array = d.get("player", [PLAYER_START.x, PLAYER_START.y])
	player.position = Vector2(float(pp[0]), float(pp[1]))
	cam.reset_smoothing()
	_npc_met = bool(d.get("npc_met", true))
	title_screen.hide_me()
	get_tree().paused = false
	mode = Mode.PLAY
	hud.toast("Đã tiếp tục — chào mừng trở lại!", Color(0.65, 1.0, 0.6))


# ---------------- chế độ debug chụp ảnh / kiểm thử ----------------

func _debug_step() -> void:
	_debug_frame += 1
	match _debug_frame:
		30:
			_shot("1_title")
		31:
			_debug_click_move()
		32:
			_debug_click_press()
		34:
			print("DEBUG click result: mode=", mode, " (kỳ vọng 1=PLAY)")
		35:
			_debug_start()
		70:
			_shot("2_spawn")
		75:
			_debug_field()
		100:
			_shot("3_field")
		105:
			_debug_grow()
		125:
			_shot("4_grown")
		130:
			_debug_shop_open()
		150:
			_shot("5_shop")
		155:
			shop_panel.close()
		160:
			_debug_inventory()
		180:
			_shot("6_inventory")
		185:
			inv_panel.close()
		190:
			_debug_dialog()
		210:
			_shot("7_dialog")
		215:
			dialog_box.force_close()
			get_tree().paused = false
			mode = Mode.PLAY
			GameState.clock = 1320  # 22:00 — đêm khuya
		240:
			_shot("8_dusk")
		245:
			GameState.clock = 700
			player.position = Vector2(430, 270)
		285:
			_shot("9_house")
		290:
			player.position = Vector2(1030, 400)
		330:
			_shot("10_stand")
		335:
			Inventory.rods = {"basic": 3}
			Inventory.add_fish("chep", 2)
			Inventory.add_fish("tre_vang", 1)
			Inventory.add_fish("chien", 1)
			Inventory.add_hoes(3)
			GameState.clock = 800
			player.position = Vector2(1030, 690)
		375:
			_shot("11_pond")
		380:
			mode = Mode.PANEL
			fish_shop.open()
		400:
			_shot("12_fishshop")
		405:
			fish_shop.close()
			mode = Mode.PLAY
			Inventory.coops = {"small": 4, "large": 2}
			for aid in ["ga_de", "ga_thit", "ga_vuon", "vit_thit", "cut", "bocau", "ngong", "da_dieu"]:
				Inventory.buy_animal(str(aid))
			player.position = Vector2(310, 610)
			GameState.clock = 800
		440:
			_shot("13_pen")
		445:
			mode = Mode.PANEL
			poultry_shop.open()
		465:
			_shot("14_poultry")
		470:
			poultry_shop.close()
			mode = Mode.PLAY
			GameState.clock = 800
			player.position = Vector2(310, 610)
			cam.reset_smoothing()
		480:
			minimap.set_big(true)
		490:
			_shot("15_minimap_big")
		495:
			minimap.set_big(false)
			minimap._on_poi_clicked("pond")
			print("MINIMAP guide_on=", minimap.guide_dest == "pond",
					" cancel=", minimap.cancel_btn.visible,
					" route_pts=", minimap.guide.route.size())
		530:
			_shot("16_minimap_guide")
		535:
			minimap._on_cancel_pressed()
			print("MINIMAP after_cancel=", minimap.guide_dest == "")
		540:
			minimap._on_poi_clicked("batu")
			player.position = Vector2(1180, 415)
		580:
			print("MINIMAP arrival_cleared=", minimap.guide_dest == "")
			_debug_done()


func _debug_click_move() -> void:
	var btn: Button = title_screen.start_btn
	var vpos: Vector2 = btn.get_global_rect().get_center()
	var wpos: Vector2 = get_viewport().get_final_transform() * vpos
	var mm := InputEventMouseMotion.new()
	mm.position = wpos
	mm.global_position = wpos
	get_viewport().push_input(mm)
	print("DEBUG btn rect=", btn.get_global_rect(), " viewport_pos=", vpos, " window_pos=", wpos)
	print("DEBUG hovered=", get_viewport().gui_get_hovered_control())


func _debug_click_press() -> void:
	var vpos: Vector2 = title_screen.start_btn.get_global_rect().get_center()
	var wpos: Vector2 = get_viewport().get_final_transform() * vpos
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = wpos
	ev.global_position = wpos
	get_viewport().push_input(ev)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = wpos
	up.global_position = wpos
	get_viewport().push_input(up)


func _debug_start() -> void:
	start_new_game()
	GameState.money = 999999
	while GameState.unlock_next():
		pass
	GameState.money = 12345
	GameState.money_changed.emit(GameState.money)
	for c in CropDB.CROPS:
		Inventory.add_seed(str(c.id), 3)
	print("DEBUG unlocked=", GameState.unlocked.size(), " (cần 16)")


func _debug_field() -> void:
	Inventory.selected_seed = "rice"
	var coords := [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3)]
	for i in coords.size():
		var t = farm.tiles[coords[i]]
		t.till()
		t.plant("rice")
		if i < 5:
			t.water()
	print("DEBUG planted=", coords.size(), " (1 ô cố tình không tưới)")


func _debug_grow() -> void:
	var wcoords := [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(2, 3), Vector2i(3, 3)]
	for i in 70:
		for v in wcoords:
			farm.tiles[v].tick_growth(1.0)
	var ready := 0
	for t in farm.tiles.values():
		if t.is_ready():
			ready += 1
	print("DEBUG ready sau 70 giây = ", ready, " (kỳ vọng 5)")
	# đất khô sau 240 giây
	var t0 = farm.tiles[Vector2i(2, 2)]
	t0.water()
	for i in 250:
		t0.tick_growth(1.0)
	print("DEBUG dry test: watered=", t0.watered, " (kỳ vọng false)")
	var first_ready = null
	for t in farm.tiles.values():
		if t.is_ready():
			first_ready = t
			break
	print("DEBUG harvest msg: ", farm.perform_at(first_ready))
	print("DEBUG produce rice = ", Inventory.produce_count("rice"), " (kỳ vọng 1)")
	# ---- test cuốc tiêu hao ----
	Inventory.hoes = 2
	var tb = farm.tiles[Vector2i(6, 5)]
	tb.reset_tile()
	print("HOETEST lần1: ", farm.perform_at(tb), " | cuốc còn=", Inventory.hoes)
	tb.reset_tile()
	print("HOETEST lần2: ", farm.perform_at(tb), " | cuốc còn=", Inventory.hoes)
	tb.reset_tile()
	print("HOETEST lần3 (hết cuốc): ", farm.perform_at(tb), " | cuốc còn=", Inventory.hoes)
	# ---- test lượt câu ----
	Inventory.rods = {"basic": 2}
	print("FISHTEST cast1=", Inventory.take_cast(), " cast2=", Inventory.take_cast(),
			" cast3='", Inventory.take_cast(), "' (kỳ vọng basic, basic, trống)")
	# ---- kiểm tra tỷ lệ câu 2000 lượt ----
	var counts := {}
	for i in 2000:
		var r := FishDB.roll_cast(false)
		var k := "none" if r.is_empty() else str(r.tier)
		counts[k] = int(counts.get(k, 0)) + 1
	print("FISHTEST 2000 lượt (kỳ vọng ~none 600 / common 800 / mid 400 / rare 200 / legend ~0): ", counts)
	# ---- test chăn nuôi ----
	Inventory.coops = {"small": 2, "large": 0}
	print("POULTRY mua gà đẻ: '", Inventory.buy_animal("ga_de"), "' (kỳ vọng trống)")
	print("POULTRY mua gà đẻ 2: '", Inventory.buy_animal("ga_de"), "' (trống)")
	print("POULTRY mua gà đẻ 3 (hết chỗ): '", Inventory.buy_animal("ga_de"), "'")
	print("POULTRY mua đà điểu (không có chuồng lớn): '", Inventory.buy_animal("da_dieu"), "'")
	Inventory.tick_animals(95)
	var got: int = Inventory.collect_products()
	print("POULTRY thu sau 95s = ", got, " trứng gà (kỳ vọng 2)")
	print("POULTRY ready_left=", Inventory.ready_products())
	print("POULTRY produce trung_ga=", Inventory.produce_count("trung_ga"))
	SaveSystem.save_game(farm.get_state(), player.position, true)
	var d := SaveSystem.load_data()
	print("DEBUG save/load farm tiles = ", (d.get("farm", []) as Array).size(),
			" hoes=", int(d.get("hoes", -1)), " rods=", d.get("rods", {}),
			" coops=", d.get("coops", {}), " animals=", (d.get("animals", []) as Array).size())


func _debug_shop_open() -> void:
	mode = Mode.PANEL
	shop_panel.open()


func _debug_inventory() -> void:
	mode = Mode.PANEL
	inv_panel.open()


func _debug_dialog() -> void:
	mode = Mode.DIALOG
	get_tree().paused = true
	dialog_box.start("Bác Tư", ["Chào con! Cửa hàng bên này bán đủ 16 loại hạt giống đó."])


func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("user://shot_%s.png" % shot_name)
	img.save_png(path)
	print("SHOT ", path)


func _debug_done() -> void:
	GameState.reset_new_game()
	Inventory.reset()
	continue_game()
	print("DEBUG continue: money=", GameState.money, " day=", GameState.day,
			" unlocked=", GameState.unlocked.size(),
			" seed_rice=", Inventory.seed_count("rice"))
	print("DEBUG_DONE")
	get_tree().quit()


# --- kịch bản: tự bấm "Bắt đầu mới" rồi chụp lại màn hình để xác nhận map hiển thị ---

func _clicktest_step() -> void:
	_clicktest_frame += 1
	match _clicktest_frame:
		40:
			_debug_click_move()
			_debug_click_press()
		130:
			print("CLICKTEST mode=", mode, " (kỳ vọng 1=PLAY) paused=", get_tree().paused)
			print("CLICKTEST world_children=", world.get_child_count(),
					" player=", player.position,
					" cam_center=", cam.get_screen_center_position(),
					" cam_active=", cam.is_current())
			print("CLICKTEST ground_tex=", ground.texture, " canvas_mod=", canvas_mod.color)
			print("CLICKTEST world_visible=", world.visible, " main_visible=", visible)
			_shot("auto_clicktest")
		140:
			# cửa NAM đã bị xoá: đi lên phải bị chặn
			player.position = Vector2(644, 725)
			player.facing = Vector2.UP
			cam.reset_smoothing()
			Input.action_press("move_up")
		240:
			Input.action_release("move_up")
			print("FARMSOUTH player=", player.position,
					" (kỳ vọng y > 685: cửa nam đã xoá, bị chặn)")
		245:
			# cửa TÂY: đi phải xuyên qua cửa vào ruộng
			player.position = Vector2(350, 470)
			player.facing = Vector2.RIGHT
			cam.reset_smoothing()
			Input.action_press("move_right")
		395:
			Input.action_release("move_right")
			print("WESTDOOR player=", player.position,
					" (kỳ vọng x > 450: qua cửa tây vào ruộng)")
		400:
			# test phím E: cày ô đất ngay phía trước
			_press_interact()
		440:
			var t = farm.tile_at_world(player.get_facing_point())
			print("ETEST tile_tstate=", (t.tstate if t != null else -1), " (kỳ vọng 1=TILLED)")
		445:
			# cửa ĐÔNG: đi trái xuyên qua cửa vào ruộng
			player.position = Vector2(960, 470)
			player.facing = Vector2.LEFT
			cam.reset_smoothing()
			Input.action_press("move_left")
		595:
			Input.action_release("move_left")
			print("EASTDOOR player=", player.position,
					" (kỳ vọng x < 850: qua cửa đông vào ruộng)")
		600:
			# cửa chuồng phía BẮC: đi xuống qua cửa vào trong
			player.position = Vector2(304, 505)
			player.facing = Vector2.DOWN
			cam.reset_smoothing()
			Input.action_press("move_down")
		750:
			Input.action_release("move_down")
			print("GATETEST player=", player.position,
					" (kỳ vọng 570 < y <= 665: vào chuồng qua cổng)")
		755:
			# rào nam chuồng chỗ KHÔNG có cửa: đi lên phải bị chặn
			player.position = Vector2(300, 700)
			Input.action_press("move_up")
		830:
			Input.action_release("move_up")
			print("FENCETEST player=", player.position,
					" (kỳ vọng y > 640: bị rào nam chuồng chặn)")
		835:
			# rào tây chuồng: đi phải bị chặn
			player.position = Vector2(110, 626)
			Input.action_press("move_right")
		905:
			Input.action_release("move_right")
			print("PENWEST player=", player.position,
					" (kỳ vọng x < 200: bị rào tây chặn)")
		910:
			# rào bắc ruộng: đi xuống bị chặn
			player.position = Vector2(644, 330)
			Input.action_press("move_down")
		985:
			Input.action_release("move_down")
			print("FARMTOP player=", player.position,
					" (kỳ vọng y < 400: bị rào bắc ruộng chặn)")
		990:
			print("CLICKTEST_DONE")
			get_tree().quit()
			get_tree().quit()


func _press_interact() -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = "interact"
	up.pressed = false
	Input.parse_input_event(up)
