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
const StallPanelScript := preload("res://scripts/ui/stall_panel.gd")
const StallCustomerScript := preload("res://scripts/stall_customer.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory_panel.gd")
const DialogueBoxScript := preload("res://scripts/ui/dialogue_box.gd")
const TitleScreenScript := preload("res://scripts/ui/title_screen.gd")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const MinimapScript := preload("res://scripts/ui/minimap.gd")
const TouchControlsScript := preload("res://scripts/ui/touch_controls.gd")
const MailboxPanelScript := preload("res://scripts/ui/mailbox_panel.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

const WORLD_SIZE := Vector2(1500, 1000)
const FARM_ORIGIN := Vector2(424, 384)
const FARM_TILES := Vector2i(14, 9)
const HOUSE_POS := Vector2(241, 248)
const MAILBOX_POS := Vector2(320, 246)
const MARKET_STALL_POS := Vector2(184, 440) # sạp hàng nông sản tại góc rẽ trái

# 10 nhân vật Stardew Valley với tên Việt Nam thân thiện
const SDV_CUSTOMERS_DATA := [
	{"name": "Bé Lan", "asset": "Abigail"},
	{"name": "Cô Mai", "asset": "Haley"},
	{"name": "Chị Thảo", "asset": "Leah"},
	{"name": "Em Cúc", "asset": "Penny"},
	{"name": "Anh Nam", "asset": "Sam"},
	{"name": "Anh Dũng", "asset": "Alex"},
	{"name": "Chị Hoa", "asset": "Emily"},
	{"name": "Bác Minh", "asset": "Harvey"},
	{"name": "Bé Linh", "asset": "Maru"},
	{"name": "Anh Phong", "asset": "Sebastian"},
]
const SDV_CUSTOMERS := ["Abigail", "Haley", "Leah", "Penny", "Sam", "Alex", "Emily", "Harvey", "Maru", "Sebastian"]

# Các vị trí đứng trước sạp hàng để tối đa 10 NPC ghé cùng lúc
const STALL_COUNTER_SPOTS := [
	Vector2(146, 468), Vector2(165, 468), Vector2(184, 468),
	Vector2(203, 468), Vector2(222, 468), Vector2(155, 482),
	Vector2(174, 482), Vector2(193, 482), Vector2(212, 482),
	Vector2(230, 482)
]

const STALL_WISHLIST_ITEMS := [
	{"id": "wheat", "type": "crop", "name": "Lúa mì", "base_price": 45},
	{"id": "rice", "type": "crop", "name": "Lúa nước", "base_price": 25},
	{"id": "tomato", "type": "crop", "name": "Cà chua", "base_price": 96},
	{"id": "carrot", "type": "crop", "name": "Cà rốt", "base_price": 66},
	{"id": "corn", "type": "crop", "name": "Bắp ngô", "base_price": 70},
	{"id": "potato", "type": "crop", "name": "Khoai tây", "base_price": 88},
	{"id": "cabbage", "type": "crop", "name": "Bắp cải", "base_price": 110},
	{"id": "watermelon", "type": "crop", "name": "Dưa hấu", "base_price": 155},
	{"id": "chep", "type": "fish", "name": "Cá chép", "base_price": 40},
	{"id": "trung_ga", "type": "poultry", "name": "Trứng gà", "base_price": 30},
	{"id": "trung_vit", "type": "poultry", "name": "Trứng vịt", "base_price": 45},
]
const STAND_POS := Vector2(1180, 416)       # quầy Bác Tư
const STAND_HAI_POS := Vector2(1350, 416)   # quầy Chú Hai
const STAND_TU_POS := Vector2(1010, 416)    # quầy Cô Tư
const NPC_POS := Vector2(1180, 430)         # điểm tương tác Bác Tư
const CHU_HAI_POS := Vector2(1350, 430)     # điểm tương tác Chú Hai
const COTU_POS := Vector2(1010, 430)        # điểm tương tác Cô Tư
const SCARECROW_POS := Vector2(648, 528)
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

# Mạng lối đi lát đất chuẩn Stardew Valley (lưới 16px).
# Đại lộ đông-tây (48px = 3 ô) + các nhánh lối đi (32px = 2 ô).
const PATHS := [
	Rect2(240, 240, 32, 224),    # từ cửa nhà xuống đại lộ (x: 240..272, y: 240..464)
	Rect2(0, 448, 1408, 48),     # đại lộ đông - tây qua 2 cổng ruộng, kéo dài hết map sang trái (x: 0..1408, y: 448..496)
	Rect2(944, 352, 464, 96),    # khuôn viên chợ quê 3 quầy hàng liền sát đại lộ (x: 944..1408, y: 352..448)
	Rect2(288, 480, 32, 96),     # nhánh tới cổng chuồng gia cầm (x: 288..320, y: 480..576)
	Rect2(1024, 480, 32, 272),   # nhánh xuống bờ ao câu cá (x: 1024..1056, y: 480..752)
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
var stall_panel: CanvasLayer
var stall_slots: Array = [{}, {}, {}, {}, {}, {}]
var stall_crate_sprites: Array[Sprite2D] = []
var stall_revenue: int = 0
var stall_coin_badge: PanelContainer
var stall_coin_label: Label
var _stall_customer_timer: float = 0.0
var _active_stall_customer: Node2D = null
var _stall_customers: Array[Node2D] = []
var inv_panel: CanvasLayer
var mailbox_panel: CanvasLayer
var mailbox_badge: PanelContainer
var mailbox_data: Dictionary = {"hoes": 999, "coins": 999}
var dialog_box: CanvasLayer
var title_screen: CanvasLayer
var pause_menu: CanvasLayer
var minimap: CanvasLayer
var touch_ui: CanvasLayer
var fade_rect: ColorRect

var interactables: Array = []
var _npc_met := false
var _npc_hai_met := false
var _npc_tu_met := false
var _dialog_next := "shop"

var foliage_nodes: Array = []
var foliage_data: Array = []

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
	mailbox_data = _default_mailbox_data()

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
	stall_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))
	stall_panel.closed.connect(_close_panels)
	stall_panel.stall_changed.connect(_on_stall_changed)
	stall_panel.revenue_collected.connect(_on_stall_revenue_collected)
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

	# nhà (chỗ ngủ) - Nhà gỗ Stardew Valley
	_add_decor(TextureGen.get_tex("house"), HOUSE_POS, 1.0, Rect2(-68, -140, 134, 104))
	# hòm thư Stardew Valley cạnh bậc thềm hiên nhà
	_build_mailbox()
	# bù nhìn Stardew Valley
	_add_decor(TextureGen.get_tex("scarecrow"), SCARECROW_POS, 1.5, Rect2(-6, -10, 12, 10))
	# sạp hàng nông sản Stardew Valley tại góc rẽ trái (kèm bóng đổ mềm mại trên nền cỏ)
	_build_market_stall()
	# Hệ thống thực vật & cây cối mọc ngẫu nhiên trên bề mặt cỏ tự nhiên (Stardew Valley)
	_populate_random_foliage(75)

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
		{"pos": HOUSE_POS + Vector2(15, -16), "r": 50.0, "label": "Ngủ", "cb": _ask_sleep},
		{"pos": MAILBOX_POS, "r": 50.0, "label": "Hòm thư 📬", "cb": _open_mailbox},
		{"pos": MARKET_STALL_POS + Vector2(0, 16), "r": 65.0, "label": "Sạp hàng 🏪", "cb": _open_market_stall},
		{"pos": NPC_POS, "r": 60.0, "label": "Bác Tư", "cb": _talk_npc},
		{"pos": CHU_HAI_POS, "r": 60.0, "label": "Chú Hai", "cb": _talk_hai},
		{"pos": COTU_POS, "r": 60.0, "label": "Cô Tư", "cb": _talk_tu},
		{"pos": PEN_RECT.get_center() + Vector2(0, 4), "r": 75.0, "label": "Thu hoạch chuồng", "cb": _collect_products},
		{"pos": FISH_SPOT_POS, "r": 152.0, "label": "Câu cá", "cb": _start_fishing},
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
	for x in [136, 168, 200, 232, 264, 296, 328, 360, 376]:
		_add_sprite(fh, Vector2(x, y_s + 8.0) - org, pen_node)
	_add_sprite(TextureGen.get_tex("fence_corner_tl"), Vector2(120, 560) - org, pen_node)
	_add_sprite(TextureGen.get_tex("fence_corner_tr"), Vector2(392, 560) - org, pen_node)
	_add_sprite(TextureGen.get_tex("fence_corner_bl"), Vector2(120, y_s + 8) - org, pen_node)
	_add_sprite(TextureGen.get_tex("fence_corner_br"), Vector2(392, y_s + 8) - org, pen_node)

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


func _build_mailbox() -> void:
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

	# Biển báo thư mới lơ lửng trên hòm thư
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

	var tw := create_tween().set_loops()
	tw.tween_property(mailbox_badge, "position:y", -49.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(mailbox_badge, "position:y", -43.0, 0.7).set_trans(Tween.TRANS_SINE)

	world.add_child(body)
	_update_mailbox_badge()


func _default_mailbox_data() -> Dictionary:
	return {
		"hoes": 999,
		"coins": 9999,
		"produce": {
			"tomato": 50,
			"corn": 50,
			"watermelon": 50,
			"strawberry": 50,
			"carrot": 50,
			"potato": 50,
			"rice": 50,
			"trung_ga": 50,
			"trung_vit": 50,
			"thit_ga": 30,
			"long_ngong": 20,
			"trung_da_dieu": 10,
		},
		"fish": {
			"chep": 30,
			"hoi": 30,
			"tram": 30,
			"tre_vang": 20,
			"chien": 10,
		}
	}


func _has_mailbox_items() -> bool:
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


func _update_mailbox_badge() -> void:
	if mailbox_badge == null:
		return
	mailbox_badge.visible = _has_mailbox_items()


func _build_market_stall() -> void:
	var body := StaticBody2D.new()
	body.position = MARKET_STALL_POS

	# 1. Hiệu ứng bóng đổ mềm mại trên nền cỏ (Stardew Valley ground shadow)
	var shadow := Sprite2D.new()
	shadow.texture = TextureGen.get_tex("stall_shadow")
	shadow.position = Vector2(2, -4)
	body.add_child(shadow)

	# 2. Thân sạp hàng gỗ
	var spr := Sprite2D.new()
	var tex: Texture2D = TextureGen.get_tex("market_stall")
	spr.texture = tex
	spr.offset = Vector2(0, -tex.get_height() / 2.0)
	body.add_child(spr)

	# 3. 6 ô chứa nông sản / cá / gia cầm trên mặt quầy gỗ (2 hàng x 3 cột)
	stall_crate_sprites.clear()
	var crate_offsets: Array[Vector2] = [
		Vector2(-20.5, -36.0), Vector2(-6.5, -36.0), Vector2(7.5, -36.0),
		Vector2(-20.5, -27.0), Vector2(-6.5, -27.0), Vector2(7.5, -27.0),
	]
	for i in 6:
		var cs := Sprite2D.new()
		cs.name = "CrateFill_%d" % i
		cs.position = crate_offsets[i]
		cs.visible = false
		body.add_child(cs)
		stall_crate_sprites.append(cs)

	# 4. Huy hiệu tiền bán hàng nổi phía trên sạp (khi có tiền chưa thu)
	stall_coin_badge = PanelContainer.new()
	stall_coin_badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.16, 0.08, 0.95), UIKit.COLOR_BORDER_GOLD, 6))
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 4)
	stall_coin_badge.add_child(ch)
	var mic := TextureRect.new()
	mic.texture = TextureGen.coin_icon()
	mic.custom_minimum_size = Vector2(14, 14)
	mic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ch.add_child(mic)
	stall_coin_label = UIKit.label(ch, "0 xu", 11, UIKit.COLOR_TEXT_GOLD)
	stall_coin_badge.position = Vector2(8, -52)
	stall_coin_badge.visible = false
	body.add_child(stall_coin_badge)

	var ctw := create_tween().set_loops()
	ctw.tween_property(stall_coin_badge, "position:y", -55.0, 0.7).set_trans(Tween.TRANS_SINE)
	ctw.tween_property(stall_coin_badge, "position:y", -49.0, 0.7).set_trans(Tween.TRANS_SINE)

	# 5. Va chạm (chân cột và quầy hàng)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(104, 24)
	col.shape = shape
	col.position = Vector2(0, -14)
	body.add_child(col)

	world.add_child(body)
	_update_stall_crates_visual()
	_update_stall_coin_badge()


func _update_stall_coin_badge() -> void:
	if stall_coin_badge == null:
		return
	stall_coin_badge.visible = stall_revenue > 0
	if stall_coin_label != null:
		stall_coin_label.text = "%d xu" % stall_revenue


func _update_stall_crates_visual() -> void:
	for i in 6:
		if i >= stall_crate_sprites.size():
			continue
		var cs: Sprite2D = stall_crate_sprites[i]
		if i < stall_slots.size() and stall_slots[i] != null and not stall_slots[i].is_empty():
			var slot: Dictionary = stall_slots[i]
			var sid: String = str(slot.get("id", ""))
			var stype: String = str(slot.get("type", "crop"))
			var count: int = int(slot.get("count", 0))
			if sid != "" and count > 0:
				cs.texture = TextureGen.get_crate_fill_tex(sid, stype)
				cs.visible = true
			else:
				cs.visible = false
		else:
			cs.visible = false


func _on_stall_changed() -> void:
	_update_stall_crates_visual()
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue)


func _add_decor(tex: Texture2D, pos: Vector2, scl: float, collide: Rect2) -> StaticBody2D:
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


func _get_foliage_col_rect(f_name: String) -> Rect2:
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


func _random_foliage_type(rng: RandomNumberGenerator) -> String:
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


func _is_grass_surface(pos: Vector2) -> bool:
	# 1. Giới hạn biên bản đồ
	if pos.x < 45.0 or pos.x > WORLD_SIZE.x - 45.0 or pos.y < 50.0 or pos.y > WORLD_SIZE.y - 50.0:
		return false

	# 2. Toàn bộ mạng lưới đường đi (PATHS) + hành lang an toàn 28px
	for p in PATHS:
		if p.grow(28.0).has_point(pos):
			return false

	# 3. Ruộng nông trại & hàng rào + cổng vào (Tây, Đông, rào Bắc, Nam)
	var farm_box := Rect2(FARM_ORIGIN.x - 40.0, FARM_ORIGIN.y - 60.0, FARM_TILES.x * 32.0 + 80.0, FARM_TILES.y * 32.0 + 120.0)
	if farm_box.has_point(pos):
		return false

	# 4. Nhà gỗ & hiên nhà
	var house_box := Rect2(HOUSE_POS.x - 90.0, HOUSE_POS.y - 155.0, 185.0, 180.0)
	if house_box.has_point(pos):
		return false

	# 5. Hòm thư cạnh nhà
	if pos.distance_to(MAILBOX_POS) < 36.0:
		return false

	# 6. Bù nhìn rơm
	if pos.distance_to(SCARECROW_POS) < 32.0:
		return false

	# 7. Vị trí xuất phát của người chơi
	if pos.distance_to(PLAYER_START) < 40.0:
		return false

	# 8. Khu chuồng nuôi gia cầm & lối đi xung quanh
	var pen_box := Rect2(90.0, 530.0, 320.0, 230.0)
	if pen_box.has_point(pos):
		return false

	# 9. Ao nước & toàn bộ bờ ao câu cá
	if POND_RECT.grow(30.0).has_point(pos):
		return false

	# 10. Ba quầy hàng chợ quê & khoảng đất mua bán
	var market_box := Rect2(920.0, 330.0, 500.0, 130.0)
	if market_box.has_point(pos):
		return false

	# 10b. Sạp hàng nông sản ở góc rẽ trái
	var stall_box := Rect2(MARKET_STALL_POS.x - 65.0, MARKET_STALL_POS.y - 75.0, 130.0, 95.0)
	if stall_box.has_point(pos):
		return false

	# 11. Các vạt đất trống (dirt patches) tự nhiên trên mặt đất
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


func _clear_foliage() -> void:
	for node in foliage_nodes:
		if is_instance_valid(node):
			node.queue_free()
	foliage_nodes.clear()
	foliage_data.clear()


func _spawn_foliage_item(f_name: String, pos: Vector2) -> StaticBody2D:
	var tex := TextureGen.get_tex(f_name)
	if tex == null:
		return null
	var col_rect := _get_foliage_col_rect(f_name)
	var body: StaticBody2D = _add_decor(tex, pos, 1.0, col_rect)
	foliage_nodes.append(body)
	foliage_data.append({"type": f_name, "x": pos.x, "y": pos.y})
	return body


func _populate_random_foliage(target_count: int = 75, seed_val: int = 0) -> void:
	_clear_foliage()
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

		if not _is_grass_surface(pt):
			continue

		var too_close := false
		for d in foliage_data:
			var ex_pt := Vector2(float(d.x), float(d.y))
			if pt.distance_to(ex_pt) < min_dist:
				too_close = true
				break
		if too_close:
			continue

		var f_type := _random_foliage_type(rng)
		_spawn_foliage_item(f_type, pt)


func _load_foliage(saved_items: Array) -> void:
	_clear_foliage()
	for item in saved_items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var px: float = float(item.get("x", 0.0))
		var py: float = float(item.get("y", 0.0))
		var pt := Vector2(px, py)
		if not _is_grass_surface(pt):
			continue
		var f_type: String = str(item.get("type", "tree_oak"))
		_spawn_foliage_item(f_type, pt)


func _sprout_random_plant() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i in 100:
		var x := rng.randf_range(50.0, WORLD_SIZE.x - 50.0)
		var y := rng.randf_range(55.0, WORLD_SIZE.y - 55.0)
		var pt := Vector2(x, y)
		if not _is_grass_surface(pt):
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
		_spawn_foliage_item(plant_type, pt)
		hud.toast("Một cây xanh vừa mọc tự nhiên trên bãi cỏ qua đêm! 🌱", Color(0.65, 0.95, 0.6))
		break


func _build_fences() -> void:
	var fh: Texture2D = TextureGen.get_tex("fence_h")
	var fv: Texture2D = TextureGen.get_tex("fence_v")
	var y_top := 370
	var y_bot := 672
	var x_left := 408
	var x_right := 888

	# 1. Hàng ngang trên + dưới liền kín (14 sprite 32px nối liền kín khít từ cọc góc này sang cọc góc kia)
	for x in range(440, 857, 32):
		_add_sprite(fh, Vector2(x, y_top))
		_add_sprite(fh, Vector2(x, y_bot))

	# 2. Hai cột dọc — Tây và Đông chừa cửa đi qua ở đại lộ (tâm 472), rào nối khít vào cổng không khe hở
	for y in [398, 430, 514, 546, 578, 610, 642]:
		_add_sprite(fv, Vector2(x_left, y))
		_add_sprite(fv, Vector2(x_right, y))

	# 3. Bốn cọc góc vững chãi cho hàng rào ruộng ngay rìa ngoài đất trồng
	_add_sprite(TextureGen.get_tex("fence_corner_tl"), Vector2(x_left, y_top))
	_add_sprite(TextureGen.get_tex("fence_corner_tr"), Vector2(x_right, y_top))
	_add_sprite(TextureGen.get_tex("fence_corner_bl"), Vector2(x_left, y_bot))
	_add_sprite(TextureGen.get_tex("fence_corner_br"), Vector2(x_right, y_bot))

	# Va chạm: tây/đông mở cửa giữa (y: 440..504), nam/bắc liền kín
	var door_y1 := 440
	var door_y2 := 504
	var farm_mid_x := (x_left + x_right) / 2.0  # 648.0
	var farm_width := float(x_right - x_left)   # 480.0
	_wall(Vector2(farm_mid_x, y_top), Vector2(farm_width, 10))
	_wall(Vector2(farm_mid_x, y_bot), Vector2(farm_width, 10))
	_wall(Vector2(x_left, (y_top - 6 + door_y1) / 2.0), Vector2(10, door_y1 - y_top + 6))
	_wall(Vector2(x_left, (door_y2 + y_bot + 8) / 2.0), Vector2(10, y_bot + 8 - door_y2))
	_wall(Vector2(x_right, (y_top - 6 + door_y1) / 2.0), Vector2(10, door_y1 - y_top + 6))
	_wall(Vector2(x_right, (door_y2 + y_bot + 8) / 2.0), Vector2(10, y_bot + 8 - door_y2))

	# 4. Hai khung cổng DỌC nghệ thuật tại cửa Tây & Đông
	var door_mid := 472.0
	_add_sprite(TextureGen.get_tex("gate_v"), Vector2(x_left, door_mid))
	var s_right := Sprite2D.new()
	s_right.texture = TextureGen.get_tex("gate_v")
	s_right.position = Vector2(x_right, door_mid)
	s_right.flip_h = true
	world.add_child(s_right)


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
	stall_panel = StallPanelScript.new()
	add_child(stall_panel)
	inv_panel = InventoryPanelScript.new()
	add_child(inv_panel)
	mailbox_panel = MailboxPanelScript.new()
	add_child(mailbox_panel)
	mailbox_panel.closed.connect(_close_panels)
	mailbox_panel.changed.connect(_on_mailbox_changed)
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
	# Điện thoại/tablet: thêm joystick ảo + nút cảm ứng (máy tính giữ bàn phím)
	if DisplayServer.is_touchscreen_available() or OS.get_environment("FARM_TOUCH") != "":
		if not DisplayServer.is_touchscreen_available():
			Input.emulate_touch_from_mouse = true  # chạy thử joystick bằng chuột trên PC
		touch_ui = TouchControlsScript.new()
		add_child(touch_ui)
		touch_ui.main = self

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
	if touch_ui != null:
		touch_ui.visible = mode == Mode.PLAY
	if mode != Mode.PLAY or get_tree().paused:
		return
	GameState.tick(delta)
	Inventory.tick_animals(delta)
	_process_stall_customers(delta)
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


func _process_stall_customers(delta: float) -> void:
	var t := GameState.clock

	# Lọc danh sách khách hàng đang hoạt động
	var alive: Array[Node2D] = []
	for c in _stall_customers:
		if is_instance_valid(c):
			alive.append(c)
	_stall_customers = alive
	_active_stall_customer = _stall_customers[0] if not _stall_customers.is_empty() else null

	# Khi trời tối (sau 21:00 / 1260.0 hoặc trước 7:00 sáng / 420.0), dân làng đứng chờ sẽ chào và ra về
	if t >= 1260.0 or t < 420.0:
		for c in _stall_customers:
			if is_instance_valid(c) and c.state == StallCustomerScript.State.WAITING:
				c.dismiss_for_night()
		return

	# Cho phép tối đa 10 NPC xuất hiện và chờ cùng lúc
	if _stall_customers.size() >= STALL_COUNTER_SPOTS.size():
		return

	_stall_customer_timer += delta
	# Cứ mỗi 3.5 - 5s có một khách mới ghé sạp nếu chưa đủ 10 người
	if _stall_customer_timer < 4.0:
		return
	_stall_customer_timer = 0.0

	_spawn_stall_customer()


func _spawn_stall_customer(forced_slot_idx: int = -1) -> Node2D:
	# Tìm vị trí đứng còn trống trước quầy sạp hàng
	var occupied_spots: Array[Vector2] = []
	for c in _stall_customers:
		if is_instance_valid(c):
			occupied_spots.append(c.target_stall_pos)

	var free_spots: Array[Vector2] = []
	for spot in STALL_COUNTER_SPOTS:
		if not spot in occupied_spots:
			free_spots.append(spot)

	if free_spots.is_empty():
		return null

	var chosen_spot: Vector2 = free_spots[randi() % free_spots.size()]

	# Chọn nhân vật Stardew Valley (1 trong 10 dân làng với tên tiếng Việt thân thuộc)
	var available_chars := []
	for d in SDV_CUSTOMERS_DATA:
		var in_use := false
		for c in _stall_customers:
			if is_instance_valid(c) and c.display_name == str(d.name):
				in_use = true
				break
		if not in_use:
			available_chars.append(d)

	var cdata: Dictionary = available_chars[randi() % available_chars.size()] if not available_chars.is_empty() else SDV_CUSTOMERS_DATA[randi() % SDV_CUSTOMERS_DATA.size()]

	# Lựa chọn món đồ khách muốn mua:
	# Ưu tiên chọn món đang có sẵn trên sạp (để mua được ngay), hoặc chọn từ wishlist (đứng chờ người chơi bày hàng)
	var target_item: Dictionary = {}
	var stocked_indices: Array[int] = []
	for i in stall_slots.size():
		var slot = stall_slots[i]
		if typeof(slot) == TYPE_DICTIONARY and not slot.is_empty() and int(slot.get("count", 0)) > 0:
			stocked_indices.append(i)

	if forced_slot_idx >= 0 and forced_slot_idx < stall_slots.size() and not stall_slots[forced_slot_idx].is_empty():
		var slot: Dictionary = stall_slots[forced_slot_idx]
		target_item = {
			"id": str(slot.get("id", "")),
			"type": str(slot.get("type", "crop")),
			"name": str(slot.get("name", "Nông sản")),
			"price": int(slot.get("price", 10)),
			"qty": mini(int(slot.get("count", 1)), randi_range(1, 3))
		}
	elif not stocked_indices.is_empty() and randf() < 0.65:
		var idx: int = stocked_indices[randi() % stocked_indices.size()]
		var slot: Dictionary = stall_slots[idx]
		target_item = {
			"id": str(slot.get("id", "")),
			"type": str(slot.get("type", "crop")),
			"name": str(slot.get("name", "Nông sản")),
			"price": int(slot.get("price", 10)),
			"qty": mini(int(slot.get("count", 1)), randi_range(1, 3))
		}
	else:
		var w_item: Dictionary = STALL_WISHLIST_ITEMS[randi() % STALL_WISHLIST_ITEMS.size()]
		var bp: int = int(w_item.get("base_price", 20))
		target_item = {
			"id": str(w_item.get("id", "wheat")),
			"type": str(w_item.get("type", "crop")),
			"name": str(w_item.get("name", "Lúa mì")),
			"price": maxi(1, int(round(float(bp) * 1.2))),
			"qty": randi_range(1, 3)
		}

	var cust: Node2D = StallCustomerScript.new()
	cust.character_name = str(cdata.asset)
	cust.display_name = str(cdata.name)
	cust.target_stall_pos = chosen_spot
	cust.stall_slots = stall_slots

	cust.item_id = str(target_item.get("id", "wheat"))
	cust.item_type = str(target_item.get("type", "crop"))
	cust.item_name = str(target_item.get("name", "Lúa mì"))
	cust.unit_price = int(target_item.get("price", 10))
	cust.buy_qty = int(target_item.get("qty", 1))

	cust.purchase_completed.connect(_on_stall_customer_purchased)
	cust.departed.connect(func():
		_stall_customers.erase(cust)
		if _active_stall_customer == cust:
			_active_stall_customer = _stall_customers[0] if not _stall_customers.is_empty() else null
	)

	_stall_customers.append(cust)
	_active_stall_customer = cust
	world.add_child(cust)
	return cust


func _on_stall_customer_purchased(slot_idx: int, item_name: String, qty: int, coins: int, buyer_name: String = "") -> void:
	if slot_idx >= 0 and slot_idx < stall_slots.size():
		var slot: Dictionary = stall_slots[slot_idx]
		if not slot.is_empty():
			var cur: int = int(slot.get("count", 0))
			var actual_qty: int = mini(cur, qty)
			slot["count"] = cur - actual_qty
			if int(slot["count"]) <= 0:
				stall_slots[slot_idx] = {}
			_update_stall_crates_visual()
			if stall_panel != null and stall_panel.visible:
				stall_panel.stall_slots = stall_slots
				stall_panel.stall_revenue = stall_revenue + coins
				stall_panel._refresh_ui()

	# Tiền bán tích lũy tại sạp để người chơi tự đến nhận, không tự cộng vào ví
	stall_revenue += coins
	_update_stall_coin_badge()
	var who := buyer_name if buyer_name != "" else "Khách"
	hud.toast("%s ghé mua %d %s! Có %d xu chờ thu tại sạp 🏪" % [who, qty, item_name, stall_revenue], Color(1.0, 0.88, 0.4))
	_spawn_effect("fx_harvest", Vector2(184, 432))
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue)


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
				lbl = "Thu hoạch (%d) 🥚" % r_count
			elif Inventory.animals.size() > 0:
				lbl = "Chuồng gia cầm (%d con)" % Inventory.animals.size()
			else:
				lbl = "Chuồng gia cầm"
		elif near.pos == MAILBOX_POS:
			if _has_mailbox_items():
				lbl = "Hòm thư 📬 (Có quà)"
			else:
				lbl = "Hòm thư 📬 (Trống)"
		elif near.pos == MARKET_STALL_POS + Vector2(0, 16):
			var count_items := 0
			var occupied_crates := 0
			for sl in stall_slots:
				if typeof(sl) == TYPE_DICTIONARY and not sl.is_empty() and int(sl.get("count", 0)) > 0:
					count_items += int(sl.get("count", 0))
					occupied_crates += 1
			if occupied_crates > 0:
				lbl = "Sạp hàng 🏪 (%d/6 ô · %d món)" % [occupied_crates, count_items]
			else:
				lbl = "Sạp hàng 🏪"
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
		var it_pos: Vector2 = it.pos
		var d: float = player.position.distance_to(it_pos)
		if d <= float(it.r) and d < best_d:
			best_d = d
			best = it.duplicate()
			if it_pos == FISH_SPOT_POS:
				var active_t: String = str(Inventory.active_item.get("type", ""))
				if active_t == "rod" and Inventory.total_casts() > 0:
					best.label = "Câu cá (%d lượt)" % Inventory.total_casts()
					best.cb = _start_fishing
				elif Inventory.water_level < Inventory.water_max:
					best.label = "Múc nước vào bình (%d/%d) 💧" % [Inventory.water_level, Inventory.water_max]
					best.cb = _refill_water_can
				elif Inventory.total_casts() > 0:
					best.label = "Câu cá (%d lượt)" % Inventory.total_casts()
					best.cb = _start_fishing
				else:
					best.label = "Bình nước đã đầy (20/20) 💧"
					best.cb = func(): hud.toast("Bình nước đã đầy rồi (20/20)!")

	# Kiểm tra khách NPC đang đứng chờ quanh sạp để người chơi có thể từ chối / báo hết hàng
	for c in _stall_customers:
		if is_instance_valid(c) and c.state == StallCustomerScript.State.WAITING:
			var d: float = player.position.distance_to(c.position)
			if d <= 32.0 and d < best_d:
				best_d = d
				best = {
					"pos": c.position,
					"r": 32.0,
					"label": "%s · [E] Báo hết hàng" % c.display_name,
					"cb": func(): _decline_stall_customer(c)
				}
	return best


func _decline_stall_customer(cust: Node2D) -> void:
	if not is_instance_valid(cust) or cust.state != StallCustomerScript.State.WAITING:
		return
	cust.decline()
	hud.toast("%s: Tiếc quá, hẹn hôm khác nhé! 👋" % cust.display_name, Color(1.0, 0.85, 0.5))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if mode == Mode.PLAY and not get_tree().paused:
			pause_menu.open()
			get_tree().paused = true
		elif pause_menu.visible:
			_resume_from_pause()
		elif shop_panel.visible or inv_panel.visible or fish_shop.visible or poultry_shop.visible or (stall_panel != null and stall_panel.visible) or (mailbox_panel != null and mailbox_panel.visible):
			_close_panels()
	elif event.is_action_pressed("interact"):
		if mode == Mode.PLAY and not get_tree().paused:
			_do_interact()
		elif mode == Mode.DIALOG:
			dialog_box.advance()
		elif (mailbox_panel != null and mailbox_panel.visible) or (stall_panel != null and stall_panel.visible):
			_close_panels()
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
	elif event is InputEventKey and event.pressed and not event.echo and mode == Mode.PLAY and not get_tree().paused:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			hud.select_slot_by_index(event.keycode - KEY_1)
	elif event is InputEventMouseButton and event.pressed and mode == Mode.PLAY and not get_tree().paused:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			hud.cycle_slot(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			hud.cycle_slot(1)


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
	player.play_action_anim(act)
	player.can_move = false
	var act_time: float = player.get_action_duration(act)
	await get_tree().create_timer(act_time).timeout
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


func _open_market_stall() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	stall_panel.open(stall_slots, stall_revenue)


func _on_stall_revenue_collected(_amt: int) -> void:
	stall_revenue = 0
	_update_stall_coin_badge()
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue)


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


func _open_mailbox() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	mailbox_panel.open(mailbox_data)


func _on_mailbox_changed() -> void:
	_update_mailbox_badge()
	hud.rebuild_hotbar()
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue)


func _close_panels() -> void:
	shop_panel.visible = false
	fish_shop.visible = false
	poultry_shop.visible = false
	inv_panel.visible = false
	if mailbox_panel != null:
		mailbox_panel.visible = false
	if stall_panel != null:
		stall_panel.visible = false
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
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue)
	hud.toast("Đã lưu game!", Color(0.6, 1.0, 0.6))


func _back_to_title() -> void:
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue)
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
	# Dọn các khách NPC ngày hôm trước để ngày mới đón khách mới
	for c in _stall_customers:
		if is_instance_valid(c):
			c.queue_free()
	_stall_customers.clear()
	_active_stall_customer = null
	# Cây cối tự nhiên có tỉ lệ mọc thêm trên bề mặt cỏ qua đêm
	if foliage_nodes.size() < 95 and randf() < 0.60:
		_sprout_random_plant()
	# Dân làng mua hàng qua đêm tại sạp nông sản
	var total_overnight_coins := 0
	var total_overnight_items := 0
	for i in stall_slots.size():
		var slot = stall_slots[i]
		if typeof(slot) == TYPE_DICTIONARY and not slot.is_empty() and int(slot.get("count", 0)) > 0:
			var cur_count: int = int(slot.get("count", 0))
			var u_price: int = int(slot.get("price", 10))
			var sell_count: int = mini(cur_count, maxi(1, int(round(float(cur_count) * randf_range(0.5, 0.8)))))
			var earned: int = u_price * sell_count
			total_overnight_coins += earned
			total_overnight_items += sell_count
			slot["count"] = cur_count - sell_count
			if int(slot["count"]) <= 0:
				stall_slots[i] = {}
	if total_overnight_items > 0:
		stall_revenue += total_overnight_coins
		_update_stall_crates_visual()
		_update_stall_coin_badge()
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue)
	hud.set_clock(GameState.clock_text())
	canvas_mod.color = _tint()
	if forced:
		hud.toast("Bạn gục ngã vì kiệt sức...", Color(1.0, 0.55, 0.45))
	if total_overnight_items > 0:
		hud.toast("Sạp bán được %d món qua đêm! Có %d xu chờ thu tại sạp 🏪" % [total_overnight_items, stall_revenue], Color(1.0, 0.9, 0.45))
	hud.toast("Ngày mới! %d cây đã chín chờ thu hoạch." % ready_n, Color(0.65, 1.0, 0.6))
	var tw2 := create_tween()
	tw2.tween_property(fade_rect, "modulate:a", 0.0, 0.6)
	await tw2.finished
	if mode == Mode.PANEL:
		mode = Mode.PLAY
	get_tree().paused = false


# ---------------- múc nước từ ao & câu cá ----------------

func _refill_water_can() -> void:
	if Inventory.water_level >= Inventory.water_max:
		hud.toast("Bình tưới đã đầy nước (%d/%d)!" % [Inventory.water_level, Inventory.water_max])
		return
	var _added: int = Inventory.refill_water()
	player.facing = (POND_RECT.get_center() - player.position).normalized()
	_spawn_effect("fx_water", player.position + player.facing * 18.0)
	player.play_action_anim("water")
	player.can_move = false
	var act_time: float = player.get_action_duration("water")
	await get_tree().create_timer(act_time).timeout
	player.can_move = true
	hud.rebuild_hotbar()
	hud.toast("Đã múc nước từ ao! Bình tưới: %d/%d 💧" % [Inventory.water_level, Inventory.water_max], Color(0.4, 0.85, 1.0))


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
	mailbox_data = _default_mailbox_data()
	_update_mailbox_badge()
	stall_slots = [{}, {}, {}, {}, {}, {}]
	stall_revenue = 0
	_update_stall_crates_visual()
	_update_stall_coin_badge()
	farm.reset_all()
	player.position = PLAYER_START
	player.facing = Vector2.DOWN
	cam.reset_smoothing()
	_npc_met = false
	_populate_random_foliage(75)
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
		"water_level": d.get("water_level", 20),
		"water_max": d.get("water_max", 20),
		"active_item": d.get("active_item", {"type": "hoe"}),
		"rods": d.get("rods", {}),
		"fish": d.get("fish", {}),
		"coops": d.get("coops", {}),
		"animals": d.get("animals", []),
	})
	var mb_dict = d.get("mailbox", null)
	if typeof(mb_dict) == TYPE_DICTIONARY and not mb_dict.is_empty() and (mb_dict.has("produce") or mb_dict.has("fish")):
		mailbox_data = mb_dict.duplicate(true)
	else:
		mailbox_data = _default_mailbox_data()
	_update_mailbox_badge()
	var st_arr = d.get("stall", [])
	if typeof(st_arr) == TYPE_ARRAY and st_arr.size() == 6:
		stall_slots = st_arr.duplicate(true)
	else:
		stall_slots = [{}, {}, {}, {}, {}, {}]
	stall_revenue = int(d.get("stall_revenue", 0))
	_update_stall_crates_visual()
	_update_stall_coin_badge()
	var farm_arr = d.get("farm", [])
	if typeof(farm_arr) == TYPE_ARRAY:
		farm.apply_state(farm_arr)
	var pp: Array = d.get("player", [PLAYER_START.x, PLAYER_START.y])
	player.position = Vector2(float(pp[0]), float(pp[1]))
	cam.reset_smoothing()
	_npc_met = bool(d.get("npc_met", true))
	var f_arr = d.get("foliage", [])
	if typeof(f_arr) == TYPE_ARRAY and f_arr.size() > 0:
		_load_foliage(f_arr)
	elif foliage_data.is_empty():
		_populate_random_foliage(75)
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
			player.position = Vector2(1030, 460)
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
			player.position = Vector2(1180, 430)
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
	# ---- test nước & múc nước ao ----
	Inventory.water_level = 1
	var twater = farm.tiles[Vector2i(6, 5)]
	twater.reset_tile()
	twater.till()
	twater.plant("rice")
	print("WATERTEST tưới lần1: ", farm.perform_at(twater), " | nước còn=", Inventory.water_level)
	twater.watered = false
	print("WATERTEST tưới lần2 (hết nước): ", farm.perform_at(twater), " | nước còn=", Inventory.water_level)
	var added_w: int = Inventory.refill_water()
	print("WATERTEST múc đầy ao: +%d | nước đầy=%d/%d" % [added_w, Inventory.water_level, Inventory.water_max])
	twater.reset_tile()
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
	SaveSystem.save_game(farm.get_state(), player.position, true, mailbox_data, foliage_data, stall_slots, stall_revenue)
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
			player.position = Vector2(648, 725)
			player.facing = Vector2.UP
			cam.reset_smoothing()
			Input.action_press("move_up")
		240:
			Input.action_release("move_up")
			print("FARMSOUTH player=", player.position,
					" (kỳ vọng y > 685: cửa nam đã xoá, bị chặn)")
		245:
			# cửa TÂY: đi phải xuyên qua cửa vào ruộng
			player.position = Vector2(350, 472)
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
			player.position = Vector2(960, 472)
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
			player.position = Vector2(648, 330)
			Input.action_press("move_down")
		985:
			Input.action_release("move_down")
			print("FARMTOP player=", player.position,
					" (kỳ vọng y < 400: bị rào bắc ruộng chặn)")
		988:
			# test hòm thư bên cạnh nhà: kiểm tra sẵn 999 cuốc và 999 xu
			player.position = MAILBOX_POS + Vector2(0, 15)
			var near_mb: Dictionary = _nearest_interactable()
			var is_near_mb: bool = not near_mb.is_empty() and (Vector2(near_mb.get("pos", Vector2.ZERO)) == MAILBOX_POS)
			var mb_hoes_before: int = int(mailbox_data.get("hoes", 0))
			var mb_coins_before: int = int(mailbox_data.get("coins", 0))
			_open_mailbox()
			var opened_ok: bool = mailbox_panel.visible
			mailbox_panel._claim_all()
			var claimed_hoes: bool = Inventory.hoes >= 999
			var claimed_coins: bool = GameState.money >= 999
			var claimed_produce: bool = Inventory.produce_count("tomato") >= 50 and Inventory.produce_count("trung_ga") >= 50
			var claimed_fish: bool = int(Inventory.fish.get("chep", 0)) >= 30
			var mb_empty: bool = int(mailbox_data.get("hoes", -1)) == 0 and int(mailbox_data.get("coins", -1)) == 0
			_close_panels()
			var closed_ok: bool = not mailbox_panel.visible
			print("MAILBOXTEST near=", is_near_mb, " before=(", mb_hoes_before, ",", mb_coins_before,
					") opened=", opened_ok, " claimed=(", claimed_hoes, ",", claimed_coins,
					") resources=", (claimed_produce and claimed_fish),
					" empty=", mb_empty, " closed=", closed_ok)
		989:
			# test không tưới được khi chưa trồng hạt giống & kiểm tra texture cây trồng Stardew Valley
			var test_tile = farm.tiles[Vector2i(6, 6)]
			test_tile.reset_tile()
			test_tile.till()
			# Chưa trồng -> hành động tưới phải bị chặn
			var tilled_action: Dictionary = farm.action_at(test_tile)
			var can_water_unplanted: bool = str(tilled_action.get("act", "")) == "water"
			test_tile.water()
			var watered_unplanted: bool = test_tile.watered
			# Gieo hạt -> cho phép tưới
			Inventory.add_seed("rice", 1)
			Inventory.selected_seed = "rice"
			test_tile.plant("rice")
			var planted_action: Dictionary = farm.action_at(test_tile)
			var can_water_planted: bool = str(planted_action.get("act", "")) == "water"
			test_tile.water()
			var watered_planted: bool = test_tile.watered
			# Kiểm tra texture SDV mầm -> lớn
			var c_rice := CropDB.get_crop("rice")
			var tex_stage0 := TextureGen.crop_tex(c_rice, 0)
			var tex_stage4 := TextureGen.crop_tex(c_rice, 4)
			var tex_seed := TextureGen.seed_icon(c_rice)
			var tex_prod := TextureGen.prod_icon(c_rice)
			var assets_ok: bool = (tex_stage0 != null and tex_stage4 != null and tex_seed != null and tex_prod != null)
			print("CROGTEST water_unplanted=(action:", can_water_unplanted, ", wet:", watered_unplanted,
					") water_planted=(action:", can_water_planted, ", wet:", watered_planted,
					") sdv_assets=", assets_ok)
			test_tile.reset_tile()
		990:
			# test 3 quán bên cạnh đường mòn to và tương tác trực tiếp từ đại lộ
			player.position = Vector2(1010, 460)
			var near_tu: Dictionary = _nearest_interactable()
			player.position = Vector2(1180, 460)
			var near_batu: Dictionary = _nearest_interactable()
			player.position = Vector2(1350, 460)
			var near_hai: Dictionary = _nearest_interactable()
			var stands_on_road: bool = (near_tu.get("pos") == COTU_POS) and (near_batu.get("pos") == NPC_POS) and (near_hai.get("pos") == CHU_HAI_POS)
			print("STANDTEST roadside_accessible=", stands_on_road,
					" cotu_pos=", COTU_POS, " batu_pos=", NPC_POS, " hai_pos=", CHU_HAI_POS)
		992:
			# test cây cối mọc ngẫu nhiên trên bề mặt cỏ & mọc thêm qua đêm
			var f_count: int = foliage_data.size()
			var all_grass: bool = true
			for fd in foliage_data:
				if not _is_grass_surface(Vector2(float(fd.x), float(fd.y))):
					all_grass = false
					break
			_sprout_random_plant()
			var count_after_sprout: int = foliage_data.size()
			SaveSystem.save_game(farm.get_state(), player.position, true, mailbox_data, foliage_data, stall_slots, stall_revenue)
			var sd: Dictionary = SaveSystem.load_data()
			var saved_f_size: int = (sd.get("foliage", []) as Array).size()
			print("FOLIAGETEST initial=", f_count, " all_on_grass=", all_grass,
					" sprouted=", (count_after_sprout == f_count + 1),
					" saved_and_loaded=", (saved_f_size == count_after_sprout))
		994:
			# test sạp hàng nông sản tại góc rẽ trái và đường mòn sang bên trái
			player.position = Vector2(184, 460)
			var near_stall: Dictionary = _nearest_interactable()
			var stall_lbl: String = str(near_stall.get("label", ""))
			var stall_found: bool = "Sạp hàng" in stall_lbl
			_open_market_stall()
			var stall_opens_panel: bool = stall_panel.visible

			# Thử nghiệm bày 2 quả cà chua lên ô 0
			Inventory.add_produce("tomato", 5)
			stall_panel._add_item_to_stall("tomato", "crop", "Cà chua", 18, 2)
			var slot0_filled: bool = stall_slots[0].get("id") == "tomato" and stall_slots[0].get("count") == 2
			var crate0_visible: bool = stall_crate_sprites[0].visible and stall_crate_sprites[0].texture != null

			# Thử nghiệm bày 1 cá chép lên ô 1
			Inventory.fish["chep"] = int(Inventory.fish.get("chep", 0)) + 1
			stall_panel._add_item_to_stall("chep", "fish", "Cá chép", 48, 1)
			var slot1_filled: bool = stall_slots[1].get("id") == "chep"
			var crate1_visible: bool = stall_crate_sprites[1].visible

			# Thu hồi cá chép ở ô 1 -> ô 1 trống và sprite ẩn
			stall_panel._retrieve_from_stall(1)
			var crate1_cleared: bool = (not stall_crate_sprites[1].visible) and stall_slots[1].is_empty()

			# Test NPC khách hàng ghé mua và tích lũy tiền tại sạp (không tự cộng vào ví)
			var wallet_before: int = GameState.money
			var rev_before: int = stall_revenue
			var cust1: Node2D = _spawn_stall_customer(0)
			var cust_spawned: bool = (cust1 != null and cust1.character_name in SDV_CUSTOMERS and cust1.display_name != "")
			var cust_from_left: bool = (cust1.position.x < 0.0)
			var cust_slow: bool = (cust1.speed <= 40.0)
			var cust_bubble_has_qty: bool = (cust1._bubble_qty_label != null and cust1._bubble_qty_label.text.begins_with("×"))

			# Thử nghiệm spawn thêm NPC thứ 2 ghé sạp cùng lúc tại vị trí khác
			var cust2: Node2D = _spawn_stall_customer()
			var multi_cust_ok: bool = (_stall_customers.size() >= 2 and cust2.target_stall_pos != cust1.target_stall_pos)
			var diff_names_ok: bool = (cust2.display_name != cust1.display_name)
			var wander_spot: Vector2 = cust2._pick_wander_spot()
			var wander_ok: bool = (wander_spot.x >= 100.0 and wander_spot.x <= 270.0 and wander_spot.y >= 450.0 and wander_spot.y <= 515.0)

			# Thử nghiệm từ chối NPC 2 (báo hết hàng) -> NPC 2 quay về đoạn đường ban đầu ở rìa trái
			cust2.state = StallCustomerScript.State.WAITING
			_decline_stall_customer(cust2)
			var decline_ok: bool = (cust2.state == StallCustomerScript.State.WALK_OUT and cust2.exit_pos.x <= 0.0)

			# Giả lập hoàn thành mua hàng 1 quả cà chua giá 18 xu
			_on_stall_customer_purchased(0, "Cà chua", 1, 18, cust1.display_name)
			var wallet_unchanged: bool = (GameState.money == wallet_before)
			var stall_rev_accumulated: bool = (stall_revenue == rev_before + 18)
			var badge_active: bool = (stall_coin_badge.visible and stall_coin_label.text == "18 xu")
			var slot0_count_decreased: bool = (stall_slots[0].get("count") == 1)

			# Mở panel sạp hàng để thu tiền thủ công
			_open_market_stall()
			var collect_btn_shows_18: bool = stall_panel.collect_btn.visible and ("18 xu" in stall_panel.collect_btn.text)
			stall_panel._on_collect_pressed()
			var wallet_collected: bool = (GameState.money == wallet_before + 18)
			var rev_reset: bool = (stall_revenue == 0)
			var badge_hidden_after: bool = (not stall_coin_badge.visible)

			# Lưu và nạp game xem sạp hàng có giữ được cà chua còn lại ở ô 0
			SaveSystem.save_game(farm.get_state(), player.position, true, mailbox_data, foliage_data, stall_slots, stall_revenue)
			var sd_stall: Dictionary = SaveSystem.load_data()
			var st_saved: Array = sd_stall.get("stall", [])
			var save_has_stall: bool = st_saved.size() == 6 and st_saved[0].get("id") == "tomato" and st_saved[0].get("count") == 1
			var save_rev_correct: bool = (int(sd_stall.get("stall_revenue", -1)) == 0)

			# Thu hồi nốt cà chua ở ô 0 để sạch sạp
			stall_panel._retrieve_from_stall(0)
			stall_panel.close()

			# Dọn khách hàng NPC test
			for c in _stall_customers:
				if is_instance_valid(c):
					c.queue_free()
			_stall_customers.clear()
			_active_stall_customer = null

			# Kiểm tra đường mòn kéo dài hết map sang trái, nền cỏ dưới sạp và POI minimap
			var west_road_exists: bool = false
			var stall_ground_has_road: bool = false
			for p in PATHS:
				if p.position.x <= 0.0 and p.position.y <= 450.0 and p.end.y >= 490.0:
					west_road_exists = true
				if p.has_point(Vector2(184, 420)):
					stall_ground_has_road = true
			var poi_stall_exists: bool = false
			for p in MinimapScript.POIS:
				if str(p.get("id", "")) == "stall":
					poi_stall_exists = true
			print("MARKETSTALLTEST found=", stall_found, " opens_panel=", stall_opens_panel,
					" slot0_filled=", slot0_filled, " crate0_visual=", crate0_visible,
					" slot1_filled=", slot1_filled, " crate1_visual=", crate1_visible,
					" crate1_cleared=", crate1_cleared, " cust_spawned=", cust_spawned,
					" cust_from_left=", cust_from_left, " cust_slow=", cust_slow,
					" bubble_qty=", cust_bubble_has_qty, " multi_cust=", multi_cust_ok,
					" diff_names=", diff_names_ok, " wander=", wander_ok,
					" decline=", decline_ok,
					" wallet_unchanged=", wallet_unchanged, " stall_rev_accumulated=", stall_rev_accumulated,
					" badge_active=", badge_active, " slot0_dec=", slot0_count_decreased,
					" collect_btn=", collect_btn_shows_18, " wallet_collected=", wallet_collected,
					" rev_reset=", rev_reset, " badge_hidden=", badge_hidden_after,
					" save_has_stall=", save_has_stall, " save_rev=", save_rev_correct,
					" west_road_to_edge=", west_road_exists, " ground_is_grass=", (not stall_ground_has_road),
					" minimap_poi=", poi_stall_exists)
		995:
			# Test kiểm thử tính năng mới: Bình nước có hạn + múc nước bờ ao + thanh hotbar Stardew Valley + hoe sprites
			# 1. Hotbar slots
			hud.select_slot_by_index(0)
			var slot0_hoe: bool = (str(Inventory.active_item.get("type")) == "hoe")
			hud.select_slot_by_index(1)
			var slot1_water: bool = (str(Inventory.active_item.get("type")) == "watering_can")
			hud.select_slot_by_index(2)
			var slot2_rod: bool = (str(Inventory.active_item.get("type")) == "rod")
			# 2. Ao nước & giới hạn nước
			Inventory.water_level = 5
			player.position = FISH_SPOT_POS + Vector2(-60, 0)
			var near_pond: Dictionary = _nearest_interactable()
			var pond_offers_water: bool = ("Múc nước" in str(near_pond.get("label", "")))
			if near_pond.has("cb") and near_pond.cb is Callable:
				near_pond.cb.call()
			var water_refilled: bool = (Inventory.water_level == Inventory.water_max)
			# 3. Sprite cuốc đất & biểu tượng
			var hoe_tex_ok: bool = (TextureGen.hoe_icon() != null and TextureGen.watering_can_icon() != null)
			var till_tex_ok: bool = (TextureGen.char_action_tex("down", "till", 3) != null and TextureGen.char_action_tex("side", "till", 3) != null)
			print("WATER_HOTBAR_TEST slot_hoe=", slot0_hoe, " slot_water=", slot1_water, " slot_rod=", slot2_rod,
					" pond_offers_water=", pond_offers_water, " water_refilled=", water_refilled,
					" hoe_tex=", hoe_tex_ok, " till_tex=", till_tex_ok)
			print("CLICKTEST_DONE")
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
