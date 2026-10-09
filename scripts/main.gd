extends Node2D
# Bộ điều phối chính: xây thế giới, điều khiển vòng chơi, ngày/đêm, UI, lưu game.

const TextureGen := preload("res://scripts/texture_gen.gd")
const CropDB := preload("res://scripts/crop_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const FarmScript := preload("res://scripts/farm.gd")
const FarmTileScript := preload("res://scripts/farm_tile.gd")
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
const StoragePanelScript := preload("res://scripts/ui/storage_panel.gd")
const CatHelperScript := preload("res://scripts/cat_helper.gd")
const CatPanelScript := preload("res://scripts/ui/cat_panel.gd")
const MineManagerScript := preload("res://scripts/mine_manager.gd")
const WeatherManagerScript := preload("res://scripts/weather_manager.gd")
const QuestManagerScript := preload("res://scripts/quest_manager.gd")
const QuestPanelScript := preload("res://scripts/ui/quest_panel.gd")
const QuestDB := preload("res://scripts/quest_db.gd")
const OreDB := preload("res://scripts/ore_db.gd")
const ToolUpgradePanelScript := preload("res://scripts/ui/tool_upgrade_panel.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const PenAnimal := preload("res://scripts/pen_animal.gd")

const WORLD_SIZE := Vector2(1900, 1000)
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
const HOUSE_POS := Vector2(641, 248)
const SHED_POS := Vector2(505, 248)
const TENT_POS := Vector2(766, 248)
const MAILBOX_POS := Vector2(720, 246)
const MAYOR_POS := Vector2(705, 270)
const MARKET_STALL_POS := Vector2(584, 440) # sạp hàng nông sản tại ngã rẽ đại lộ
const MINE_ENTRANCE_POS := Vector2(96, 64)   # cửa hầm mỏ đá khoét sâu vào vách núi biên Bắc
const MINE_SIGN_POS := Vector2(56, 96)       # biển báo hầm mỏ bên trái lối vào ở chân vách núi
const LEAH_MINER_POS := Vector2(136, 96)     # Leah đứng bên phải lối vào mỏ hướng dẫn người chơi

# Các nhân vật Stardew Valley ghé sạp mua hàng (Leah là NPC quản lý mỏ riêng)
const SDV_CUSTOMERS_DATA := [
	{"name": "Bé Lan", "asset": "Abigail"},
	{"name": "Cô Mai", "asset": "Haley"},
	{"name": "Em Cúc", "asset": "Penny"},
	{"name": "Anh Nam", "asset": "Sam"},
	{"name": "Anh Dũng", "asset": "Alex"},
	{"name": "Chị Hoa", "asset": "Emily"},
	{"name": "Bác Minh", "asset": "Harvey"},
	{"name": "Bé Linh", "asset": "Maru"},
	{"name": "Anh Phong", "asset": "Sebastian"},
]
const SDV_CUSTOMERS := ["Abigail", "Haley", "Penny", "Sam", "Alex", "Emily", "Harvey", "Maru", "Sebastian"]

# Các vị trí đứng trước sạp hàng để tối đa 10 NPC ghé cùng lúc
const STALL_COUNTER_SPOTS := [
	Vector2(546, 468), Vector2(565, 468), Vector2(584, 468),
	Vector2(603, 468), Vector2(622, 468), Vector2(555, 482),
	Vector2(574, 482), Vector2(593, 482), Vector2(612, 482),
	Vector2(630, 482)
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
	{"id": "trung_ga", "type": "poultry", "name": "Trứng gà", "base_price": 35},
	{"id": "sua_bo", "type": "poultry", "name": "Sữa bò", "base_price": 70},
	{"id": "thit_lon", "type": "poultry", "name": "Thịt lợn", "base_price": 55},
	{"id": "long_cuu", "type": "poultry", "name": "Lông cừu", "base_price": 65},
]
const STAND_POS := Vector2(1580, 416)       # quầy Bác Tư
const STAND_HAI_POS := Vector2(1750, 416)   # quầy Chú Hai
const STAND_TU_POS := Vector2(1410, 416)    # quầy Cô Tư
const NPC_POS := Vector2(1580, 430)         # điểm tương tác Bác Tư
const CHU_HAI_POS := Vector2(1750, 430)     # điểm tương tác Chú Hai
const COTU_POS := Vector2(1410, 430)        # điểm tương tác Cô Tư
const SCARECROW_NORTH_POS := Vector2(1048, 368) # bù nhìn rơm ở giữa Thửa Bắc
const SCARECROW_SOUTH_POS := Vector2(1048, 576) # bù nhìn rơm ở giữa Thửa Nam
const SCARECROW_POS := SCARECROW_NORTH_POS      # bù nhìn rơm (tương thích)
const PLAYER_START := Vector2(650, 470)
const POND_RECT := Rect2(1232, 720, 416, 368)
const FISH_SPOT_POS := Vector2(1440, 880)   # tâm hồ Stardew Valley hình tròn tràn biên Nam

# 4 Chuồng riêng biệt theo bố trí 2x2 chuẩn theo sơ đồ:
# Top-Left: BÒ    | Top-Right: GÀ
# Bottom-Left: CỪU | Bottom-Right: LỢN
const PEN_COW := Rect2(256, 544, 224, 128)      # Chuồng Bò (Tây Bắc)
const PEN_CHICKEN := Rect2(528, 544, 224, 128)  # Chuồng Gà (Đông Bắc)
const PEN_SHEEP := Rect2(256, 720, 224, 128)    # Chuồng Cừu (Tây Nam)
const PEN_PIG := Rect2(528, 720, 224, 128)      # Chuồng Lợn (Đông Nam)
const PEN_RECT := PEN_CHICKEN                    # fallback tham chiếu cũ

# Lối đi lát đá (Cobblestone) chữ thập giữa 4 chuồng
const PATH_COBBLE_V := Rect2(480, 480, 48, 384)  # đường dọc nối từ đại lộ xuống đáy 4 chuồng
const PATH_COBBLE_H := Rect2(240, 672, 528, 48)  # đường ngang phân cách tầng chuồng trên và dưới

const PENS_CONFIG := [
	{
		"id": "cow",
		"name": "Chuồng Bò",
		"rect": PEN_COW,
		"gate_axis": "south",
		"bldg_pos": Vector2(310, 584),
		"bldg_type": "barn",
	},
	{
		"id": "chicken",
		"name": "Chuồng Gà",
		"rect": PEN_CHICKEN,
		"gate_axis": "south",
		"bldg_pos": Vector2(582, 584),
		"bldg_type": "coop",
	},
	{
		"id": "sheep",
		"name": "Chuồng Cừu",
		"rect": PEN_SHEEP,
		"gate_axis": "north",
		"bldg_pos": Vector2(310, 760),
		"bldg_type": "barn",
	},
	{
		"id": "pig",
		"name": "Chuồng Lợn",
		"rect": PEN_PIG,
		"gate_axis": "north",
		"bldg_pos": Vector2(582, 760),
		"bldg_type": "barn",
	},
]

# Mạng lối đi lát đất chuẩn Stardew Valley (lưới 16px).
const PATHS := [
	Rect2(640, 240, 32, 224),    # từ cửa nhà xuống đại lộ (x: 640..672, y: 240..464)
	Rect2(80, 80, 32, 370),      # đường mòn từ đại lộ lên thẳng cửa hầm mỏ vách núi biên Bắc (x: 80..112, y: 80..450)
	Rect2(0, 448, 1850, 48),     # đại lộ đông - tây xuyên suốt qua sạp hàng và 2 cổng ruộng (x: 0..1850, y: 448..496)
	Rect2(1344, 352, 464, 96),   # khuôn viên chợ quê 3 quầy hàng liền sát đại lộ (x: 1344..1808, y: 352..448)
	Rect2(1424, 480, 32, 252),   # nhánh xuống bờ ao câu cá (x: 1424..1456, y: 480..732)
]

enum Mode { TITLE, PLAY, DIALOG, PANEL }

var mode: int = Mode.TITLE

var world: Node2D
var player: CharacterBody2D
var farm: Node2D
var npc: StaticBody2D
var npc_hai: StaticBody2D
var npc_tu: StaticBody2D
var npc_leah: StaticBody2D
var npc_mayor: StaticBody2D
var quest_mgr: Node
var mine_manager: Node2D
var in_mine: bool = false
var pen_node: Node2D
var active_pen_animals: Array = []
var cam: Camera2D
var ground: Sprite2D
var canvas_mod: CanvasModulate
var highlight: Sprite2D
var weather_mgr: CanvasLayer

var hud: CanvasLayer
var shop_panel: CanvasLayer
var fish_shop: CanvasLayer
var poultry_shop: CanvasLayer
var quest_panel: CanvasLayer
var tool_upgrade_panel: CanvasLayer
var stall_panel: CanvasLayer
var stall_slots: Array = [{}, {}, {}, {}, {}, {}]
var stall_crate_sprites: Array[Sprite2D] = []
var stall_revenue: int = 0
var stall_coin_badge: PanelContainer
var stall_coin_label: Label
var _stall_customer_timer: float = 0.0
var _next_stall_customer_delay: float = 16.0
var _active_stall_customer: Node2D = null
var _stall_customers: Array[Node2D] = []
var inv_panel: CanvasLayer
var storage_panel: CanvasLayer
var cat_helper: Node2D
var cat_panel: CanvasLayer
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
var _leah_met := false
var _mayor_met := false
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
var _fishing_line: Line2D
var _lake_ripple_timer: float = 0.5
var _bobber_ripple_timer: float = 0.0

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

	GameState.money_changed.connect(func(v: int) -> void:
		hud.set_money(v)
		if quest_mgr != null:
			quest_mgr.update_money_milestones(v)
	)
	GameState.crops_changed.connect(func() -> void: hud.rebuild_hotbar())
	GameState.stamina_changed.connect(func(cur: float, max_v: float) -> void: hud.set_stamina(cur, max_v))
	GameState.weather_changed.connect(func(w: String) -> void:
		if is_instance_valid(hud):
			hud.set_weather(w)
	)
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
	Inventory.baby_born.connect(func(_sid: String, sname: String) -> void:
		hud.toast("🐣 Tin vui: Đàn %s vừa sinh một chú con non (baby)!" % sname, Color(1.0, 0.85, 0.3))
	)
	inv_panel.closed.connect(_close_panels)
	inv_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))
	dialog_box.finished.connect(_on_dialog_finished)
	dialog_box.answered.connect(_on_sleep_answer)
	title_screen.start_requested.connect(start_new_game)
	title_screen.continue_requested.connect(continue_game)
	pause_menu.resumed.connect(_resume_from_pause)
	pause_menu.saved.connect(_save_now)
	pause_menu.menu_requested.connect(_back_to_title)

	hud.set_money(GameState.money)
	hud.set_stamina(GameState.stamina, GameState.max_stamina)
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
	var farm_px := Rect2(824, 288, 448, 368)
	ground.texture = TextureGen.make_ground(int(WORLD_SIZE.x), int(WORLD_SIZE.y), farm_px, PATHS, POND_RECT, [PATH_COBBLE_V, PATH_COBBLE_H])
	world.add_child(ground)

	# Vách núi đá mở rộng lên phía trên biên Bắc (chống lộ khoảng trống khi màn hình kéo dãn)
	var cliff_top_ext := Sprite2D.new()
	cliff_top_ext.texture = TextureGen.get_tex("sdv_north_cliff_top")
	cliff_top_ext.position = Vector2(0, -160)
	cliff_top_ext.centered = false
	world.add_child(cliff_top_ext)

	# nông trại 2 thửa riêng biệt + ô vuông chỉ điểm
	farm = FarmScript.new()
	farm.setup_plots(FARM_PLOTS)
	world.add_child(farm)
	highlight = Sprite2D.new()
	highlight.texture = TextureGen.get_tex("highlight")
	highlight.visible = false
	farm.add_child(highlight)

	# nhà (chỗ ngủ) - Nhà gỗ Stardew Valley
	_add_decor(TextureGen.get_tex("house"), HOUSE_POS, 1.0, Rect2(-68, -140, 134, 104))
	# nhà kho Stardew Valley cạnh nhà chính
	_add_decor(TextureGen.get_tex("shed"), SHED_POS, 1.0, Rect2(-48, -100, 96, 75))
	# lều của Mèo Stardew Valley cạnh nhà chính
	_add_decor(TextureGen.get_tex("tent"), TENT_POS, 1.0, Rect2(-20, -56, 40, 42))
	# hòm thư Stardew Valley cạnh bậc thềm hiên nhà
	_build_mailbox()
	# bù nhìn Stardew Valley ở giữa mỗi thửa ruộng
	_add_decor(TextureGen.get_tex("scarecrow"), SCARECROW_NORTH_POS, 1.2, Rect2(-4, -6, 8, 6))
	_add_decor(TextureGen.get_tex("scarecrow"), SCARECROW_SOUTH_POS, 1.2, Rect2(-4, -6, 8, 6))
	# sạp hàng nông sản Stardew Valley tại góc rẽ trái (kèm bóng đổ mềm mại trên nền cỏ)
	_build_market_stall()
	# Khu vực cửa hầm mỏ đá & Leah phía Tây Bắc
	_build_mine_entrance()
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

	# Quản lý hầm mỏ khai thác quặng
	mine_manager = MineManagerScript.new()
	mine_manager.visible = false
	mine_manager.setup(self, player)
	mine_manager.exit_requested.connect(_on_exit_mine)
	add_child(mine_manager)

	# Quản lý Hệ Thống Nhiệm Vụ (Ngày, Tuần, Thành Tựu)
	quest_mgr = QuestManagerScript.new()
	quest_mgr.setup(self)
	quest_mgr.quest_completed.connect(func(q: Dictionary):
		hud.toast("🎉 Xong nhiệm vụ: %s! Nhận thưởng [Q] hoặc gặp Trưởng Thôn" % str(q.get("title", "")), Color(1.0, 0.85, 0.35))
		_update_npc_mayor_indicator()
	)
	quest_mgr.quests_refreshed.connect(_update_npc_mayor_indicator)
	quest_mgr.quest_claimed.connect(func(_q: Dictionary):
		_update_npc_mayor_indicator()
		_save_now()
	)
	add_child(quest_mgr)

	# Chú mèo tam thể làm nông
	cat_helper = CatHelperScript.new()
	cat_helper.farm = farm
	cat_helper.toast_requested.connect(func(txt: String, col: Color): hud.toast(txt, col))
	cat_helper.action_performed.connect(func(act_type: String, target_id: String):
		if quest_mgr != null:
			quest_mgr.advance_progress(act_type, target_id)
	)
	world.add_child(cat_helper)

	# Bác Trưởng Thôn đứng trước sân nhà chính
	npc_mayor = NpcScript.new()
	npc_mayor.npc_name = "Trưởng Thôn"
	npc_mayor.position = MAYOR_POS
	world.add_child(npc_mayor)
	_update_npc_mayor_indicator()

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

	# Quản lý thời tiết & hiệu ứng hạt
	weather_mgr = WeatherManagerScript.new()
	add_child(weather_mgr)
	weather_mgr.setup(self, player, farm)

	# ao cá tròn Stardew Valley: bờ đá phía bắc và mặt nước sâu
	var cliff_body := StaticBody2D.new()
	cliff_body.position = Vector2(1440, 765)
	var cliff_col := CollisionShape2D.new()
	var cliff_shape := RectangleShape2D.new()
	cliff_shape.size = Vector2(200, 20)
	cliff_col.shape = cliff_shape
	cliff_body.add_child(cliff_col)
	world.add_child(cliff_body)

	_add_ellipse_wall(Vector2(1440, 900), 160.0, 140.0)

	# khu chuồng nuôi: hàng rào + nhà chuồng + nơi con vật đứng
	_build_pen()

	interactables = [
		{"pos": HOUSE_POS + Vector2(15, -16), "r": 50.0, "label": "Ngủ 🛏️ (Lưu game)", "cb": _ask_sleep},
		{"pos": SHED_POS + Vector2(0, -6), "r": 50.0, "label": "Nhà kho 🏚️", "cb": _open_storage},
		{"pos": MAILBOX_POS, "r": 50.0, "label": "Hòm thư 📬", "cb": _open_mailbox},
		{"pos": MAYOR_POS, "r": 50.0, "label": "Trưởng Thôn 📜", "cb": _talk_mayor},
		{"pos": MARKET_STALL_POS + Vector2(0, 16), "r": 65.0, "label": "Sạp hàng 🏪", "cb": _open_market_stall},
		{"pos": MINE_ENTRANCE_POS + Vector2(0, 24), "r": 50.0, "label": "Vào Hầm Mỏ ⛏️", "cb": _enter_mine},
		{"pos": MINE_SIGN_POS, "r": 40.0, "label": "Biển báo Hầm Mỏ 📜", "cb": _read_mine_sign},
		{"pos": LEAH_MINER_POS, "r": 45.0, "label": "Leah ⛏️ (Nâng cấp Nông Cụ)", "cb": _talk_leah},
		{"pos": NPC_POS, "r": 60.0, "label": "Bác Tư", "cb": _talk_npc},
		{"pos": CHU_HAI_POS, "r": 60.0, "label": "Chú Hai", "cb": _talk_hai},
		{"pos": COTU_POS, "r": 60.0, "label": "Cô Tư", "cb": _talk_tu},
		{"pos": PEN_COW.get_center(), "r": 85.0, "label": "Chuồng Bò", "cb": func(): _interact_pen("cow")},
		{"pos": PEN_CHICKEN.get_center(), "r": 85.0, "label": "Chuồng Gà", "cb": func(): _interact_pen("chicken")},
		{"pos": PEN_SHEEP.get_center(), "r": 85.0, "label": "Chuồng Cừu", "cb": func(): _interact_pen("sheep")},
		{"pos": PEN_PIG.get_center(), "r": 85.0, "label": "Chuồng Lợn", "cb": func(): _interact_pen("pig")},
		{"pos": FISH_SPOT_POS, "r": 180.0, "label": "Câu cá", "cb": _start_fishing},
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
	pen_node.position = Vector2.ZERO
	world.add_child(pen_node)
	_rebuild_pen()


# Dựng lại 4 khu chuồng riêng biệt (Bò, Gà, Cừu, Lợn) theo bố trí 2x2:
# Ban đầu là hàng rào gỗ với nền đất trống (Cấp 0).
# Khi mua Cấp 1: xuất hiện nhà chuồng, máng ăn/nước, nền rơm.
# Khi nâng cấp Cấp 2: nhà chuồng lớn hơn (Big Coop / Big Barn), thêm máng ăn & trang trí.
# Khi có sản phẩm: bong bóng hình icon sản phẩm nổi bồng bềnh, KHÔNG CÓ CHỮ NÀO THÊM.
func _rebuild_pen() -> void:
	if pen_node == null:
		return
	active_pen_animals.clear()
	for c in pen_node.get_children():
		c.queue_free()

	var fh := TextureGen.get_tex("fence_h")
	var fv := TextureGen.get_tex("fence_v")
	var f_tl := TextureGen.get_tex("fence_corner_tl")
	var f_tr := TextureGen.get_tex("fence_corner_tr")
	var f_bl := TextureGen.get_tex("fence_corner_bl")
	var f_br := TextureGen.get_tex("fence_corner_br")
	var f_gate := TextureGen.get_tex("gate_coop")

	var rng := RandomNumberGenerator.new()
	rng.seed = 2026

	for pcfg in PENS_CONFIG:
		var sid: String = str(pcfg.id)
		var r: Rect2 = pcfg.rect
		var rx: float = r.position.x
		var ry: float = r.position.y
		var rw: float = r.size.x
		var rh: float = r.size.y
		var tier: int = Inventory.get_coop_tier(sid)
		var gate_axis: String = str(pcfg.gate_axis)

		# 1. Mặt sàn chuồng: Cấp 0 là nền đất trống; Cấp 1 & 2 là nền rơm vàng
		var bedding := Sprite2D.new()
		bedding.texture = TextureGen.get_tex("pen_dirt_bedding" if tier == 0 else "pen_bedding")
		bedding.position = Vector2(rx + rw / 2.0, ry + rh / 2.0)
		bedding.z_index = -1
		pen_node.add_child(bedding)

		# 2. Hàng rào gỗ ngoại vi bao quanh chuồng & Cổng chuồng
		# Bốn góc rào
		_add_sprite(f_tl, Vector2(rx, ry), pen_node)
		_add_sprite(f_tr, Vector2(rx + rw, ry), pen_node)
		_add_sprite(f_bl, Vector2(rx, ry + rh), pen_node)
		_add_sprite(f_br, Vector2(rx + rw, ry + rh), pen_node)

		# Hai vách tường dọc (Tây và Đông)
		for y in range(int(ry) + 16, int(ry + rh), 32):
			_add_sprite(fv, Vector2(rx, y), pen_node)
			_add_sprite(fv, Vector2(rx + rw, y), pen_node)
		_wall(Vector2(rx + 4, ry + rh / 2.0), Vector2(8, rh), pen_node)
		_wall(Vector2(rx + rw - 4, ry + rh / 2.0), Vector2(8, rh), pen_node)

		if gate_axis == "south":
			# Tường Bắc liền kín (không có cổng)
			for x in range(int(rx) + 16, int(rx + rw), 32):
				_add_sprite(fh, Vector2(x, ry), pen_node)
			_wall(Vector2(rx + rw / 2.0, ry + 4), Vector2(rw, 8), pen_node)

			# Tường Nam hướng ra đường đá giữa: chừa cổng ở giữa
			for x in [rx + 16, rx + 48, rx + 80]:
				_add_sprite(fh, Vector2(x, ry + rh), pen_node)
			_add_sprite(f_gate, Vector2(rx + 112, ry + rh), pen_node)
			for x in [rx + 144, rx + 176, rx + 208]:
				_add_sprite(fh, Vector2(x, ry + rh), pen_node)
			_wall(Vector2(rx + 48, ry + rh + 4), Vector2(96, 8), pen_node)
			_wall(Vector2(rx + 176, ry + rh + 4), Vector2(96, 8), pen_node)
		else:
			# Tường Nam liền kín
			for x in range(int(rx) + 16, int(rx + rw), 32):
				_add_sprite(fh, Vector2(x, ry + rh), pen_node)
			_wall(Vector2(rx + rw / 2.0, ry + rh + 4), Vector2(rw, 8), pen_node)

			# Tường Bắc hướng ra đường đá giữa: chừa cổng ở giữa
			for x in [rx + 16, rx + 48, rx + 80]:
				_add_sprite(fh, Vector2(x, ry), pen_node)
			_add_sprite(f_gate, Vector2(rx + 112, ry), pen_node)
			for x in [rx + 144, rx + 176, rx + 208]:
				_add_sprite(fh, Vector2(x, ry), pen_node)
			_wall(Vector2(rx + 48, ry + 4), Vector2(96, 8), pen_node)
			_wall(Vector2(rx + 176, ry + 4), Vector2(96, 8), pen_node)

		# 3. Công trình chuồng trại và cơ sở vật chất (Chỉ xuất hiện khi đã mua Cấp 1 hoặc Cấp 2)
		if tier >= 1:
			var bldg_body := StaticBody2D.new()
			var bpos: Vector2 = pcfg.bldg_pos
			bldg_body.position = bpos
			var bldg_spr := Sprite2D.new()
			var is_coop := (str(pcfg.bldg_type) == "coop")
			var btex_key := ""
			if is_coop:
				btex_key = "coop_tier2" if tier >= 2 else "coop_tier1"
			else:
				btex_key = "barn_tier2" if tier >= 2 else "barn_tier1"
			bldg_spr.texture = TextureGen.get_tex(btex_key)
			var b_scale := Vector2(0.70, 0.70) if tier >= 2 else Vector2(0.65, 0.65)
			bldg_spr.scale = b_scale
			bldg_body.add_child(bldg_spr)

			# Va chạm thân nhà chuồng
			var bcol := CollisionShape2D.new()
			var bshape := RectangleShape2D.new()
			bshape.size = Vector2(56 * b_scale.x / 0.65, 30 * b_scale.y / 0.65)
			bcol.shape = bshape
			bcol.position = Vector2(0, 10)
			bldg_body.add_child(bcol)
			pen_node.add_child(bldg_body)

			# Máng ăn & máng nước
			_add_sprite(TextureGen.get_tex("trough"), Vector2(rx + 126, ry + 40), pen_node)
			_add_sprite(TextureGen.get_tex("water_trough"), Vector2(rx + 126, ry + 58), pen_node)
			_add_sprite(TextureGen.get_tex("hay_bale"), Vector2(rx + 190, ry + 40), pen_node)

			if is_coop:
				_add_sprite(TextureGen.get_tex("nest_box"), Vector2(rx + 190, ry + 60), pen_node)

			# Cấp 2 có thêm đống rơm thứ hai và chi tiết nâng cấp
			if tier >= 2:
				_add_sprite(TextureGen.get_tex("hay_bale"), Vector2(rx + 168, ry + 40), pen_node)

		# 4. Các con vật thuộc loài này di chuyển và ăn trong chuồng
		var species_animals: Array = []
		for a in Inventory.animals:
			if PoultryDB.get_canonical_id(str(a.id)) == sid:
				species_animals.append(a)

		var anim_spots := [
			Vector2(rx + 56, ry + 88),
			Vector2(rx + 112, ry + 88),
			Vector2(rx + 168, ry + 88),
			Vector2(rx + 84, ry + 104),
			Vector2(rx + 140, ry + 104),
			Vector2(rx + 60, ry + 68),
		]

		var d := PoultryDB.get_animal(sid)
		for idx in species_animals.size():
			var a: Dictionary = species_animals[idx]
			var spot: Vector2 = anim_spots[idx % anim_spots.size()] + Vector2(rng.randf_range(-5, 5), rng.randf_range(-3, 3))
			var animal_node := PenAnimal.new()
			animal_node.position = spot
			animal_node.setup(sid, a, idx, r, Vector2(rx + 126, ry + 40))
			pen_node.add_child(animal_node)
			active_pen_animals.append(animal_node)

		# 5. Biểu tượng thu hoạch chung nổi trên chuồng khi có sản phẩm (KHÔNG ĐƯỢC CÓ CHỮ GÌ THÊM)
		var ready_count := Inventory.ready_products_for_species(sid)
		if ready_count > 0:
			var pen_bubble := Sprite2D.new()
			pen_bubble.texture = TextureGen.get_harvest_bubble(str(d.product))
			pen_bubble.scale = Vector2(1.35, 1.35)
			pen_bubble.position = Vector2(rx + 112, ry + 22)
			pen_node.add_child(pen_bubble)

			var ptw := pen_bubble.create_tween().set_loops()
			ptw.tween_property(pen_bubble, "position:y", pen_bubble.position.y - 4.0, 0.6).set_trans(Tween.TRANS_SINE)
			ptw.tween_property(pen_bubble, "position:y", pen_bubble.position.y, 0.6).set_trans(Tween.TRANS_SINE)


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
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue, _cat_save_data(), _quest_save_data())


func _build_mine_entrance() -> void:
	# 1. Cửa hang đá khoét trực tiếp vào vách núi biên Bắc
	var cave_spr := Sprite2D.new()
	cave_spr.texture = TextureGen.get_tex("cave_entrance")
	cave_spr.position = MINE_ENTRANCE_POS
	world.add_child(cave_spr)

	# Chân vách đá 2 bên cửa mỏ ngăn người chơi đi xuyên núi
	_wall(Vector2(56, 76), Vector2(48, 24))
	_wall(Vector2(136, 76), Vector2(48, 24))

	# 2. Biển báo gỗ cạnh hang ở chân vách núi
	var sign_spr := Sprite2D.new()
	sign_spr.texture = TextureGen.get_tex("mine_sign")
	sign_spr.position = MINE_SIGN_POS
	world.add_child(sign_spr)

	# 3. NPC Leah đứng trước cửa mỏ hướng dẫn người chơi
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

	# Nhịp thở tự nhiên cho Leah
	var tw := l_spr.create_tween().set_loops()
	tw.tween_property(l_spr, "scale:y", 1.23, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(l_spr, "scale:y", 1.2, 1.2).set_trans(Tween.TRANS_SINE)

	world.add_child(npc_leah)


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
	# 1. Giới hạn biên bản đồ (phía Bắc chừa khoảng cho vách núi nhô lên cao 96px)
	if pos.x < 45.0 or pos.x > WORLD_SIZE.x - 45.0 or pos.y < 105.0 or pos.y > WORLD_SIZE.y - 50.0:
		return false

	# 2. Toàn bộ mạng lưới đường đi (PATHS) + hành lang an toàn 28px
	for p in PATHS:
		if p.grow(28.0).has_point(pos):
			return false

	# 3. Ruộng nông trại & hàng rào 2 thửa (Thửa Bắc & Thửa Nam)
	var farm_box_n := Rect2(824 - 40.0, 304 - 40.0, 448 + 80.0, 128 + 60.0)
	var farm_box_s := Rect2(824 - 40.0, 512 - 20.0, 448 + 80.0, 128 + 60.0)
	if farm_box_n.has_point(pos) or farm_box_s.has_point(pos):
		return false

	# 4. Nhà gỗ & hiên nhà
	var house_box := Rect2(HOUSE_POS.x - 90.0, HOUSE_POS.y - 155.0, 185.0, 180.0)
	if house_box.has_point(pos):
		return false

	# 4b. Nhà kho Stardew Valley cạnh nhà chính
	var shed_box := Rect2(SHED_POS.x - 65.0, SHED_POS.y - 140.0, 130.0, 160.0)
	if shed_box.has_point(pos):
		return false

	# 4c. Lều của Mèo Stardew Valley
	var tent_box := Rect2(TENT_POS.x - 30.0, TENT_POS.y - 70.0, 60.0, 80.0)
	if tent_box.has_point(pos):
		return false

	# 4d. Vị trí mèo đứng đợi nhận việc trong sân
	if pos.distance_to(CatHelperScript.WAITING_POS) < 32.0:
		return false

	# 5. Hòm thư cạnh nhà
	if pos.distance_to(MAILBOX_POS) < 36.0:
		return false

	# 5b. Vị trí Bác Trưởng Thôn đứng trước nhà
	if pos.distance_to(MAYOR_POS) < 32.0:
		return false

	# 6. Bù nhìn rơm ở giữa 2 thửa ruộng
	if pos.distance_to(SCARECROW_NORTH_POS) < 32.0 or pos.distance_to(SCARECROW_SOUTH_POS) < 32.0:
		return false

	# 7. Vị trí xuất phát của người chơi
	if pos.distance_to(PLAYER_START) < 40.0:
		return false

	# 8. 4 Khu chuồng nuôi & lối đi lát đá xung quanh
	var pen_box := Rect2(230.0, 520.0, 550.0, 360.0)
	if pen_box.has_point(pos):
		return false

	# 9. Ao nước tròn lớn & toàn bộ bờ ao câu cá
	if POND_RECT.grow(20.0).has_point(pos):
		return false

	# 10. Ba quầy hàng chợ quê & khoảng đất mua bán
	var market_box := Rect2(STAND_TU_POS.x - 90.0, 330.0, 500.0, 130.0)
	if market_box.has_point(pos):
		return false

	# 10b. Sạp hàng nông sản ở góc rẽ trái
	var stall_box := Rect2(MARKET_STALL_POS.x - 65.0, MARKET_STALL_POS.y - 75.0, 130.0, 95.0)
	if stall_box.has_point(pos):
		return false

	# 10c. Khu vực cửa hầm mỏ đá, biển báo và NPC Leah (trống hoàn toàn không bị cây che)
	var mine_box := Rect2(0.0, 140.0, 220.0, 160.0)
	if mine_box.has_point(pos):
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
	var f_gate: Texture2D = TextureGen.get_tex("gate_farm")
	var f_tl: Texture2D = TextureGen.get_tex("fence_corner_tl")
	var f_tr: Texture2D = TextureGen.get_tex("fence_corner_tr")
	var f_bl: Texture2D = TextureGen.get_tex("fence_corner_bl")
	var f_br: Texture2D = TextureGen.get_tex("fence_corner_br")

	var x_left := 808
	var x_right := 1288
	var farm_mid_x := (x_left + x_right) / 2.0  # 1048.0
	var farm_width := float(x_right - x_left)   # 480.0

	# ---------------- THỬA BẮC (NORTH PLOT: y: 304..432) ----------------
	var n_ytop := 290
	var n_ybot := 446

	# 1. Hàng ngang Bắc (liền kín)
	for x in range(x_left + 32, x_right, 32):
		_add_sprite(fh, Vector2(x, n_ytop))
	_add_sprite(f_tl, Vector2(x_left, n_ytop))
	_add_sprite(f_tr, Vector2(x_right, n_ytop))
	_add_sprite(f_bl, Vector2(x_left, n_ybot))
	_add_sprite(f_br, Vector2(x_right, n_ybot))

	# 2. Hai cột dọc Tây và Đông (liền kín)
	for y in [322, 354, 386, 418]:
		_add_sprite(fv, Vector2(x_left, y))
		_add_sprite(fv, Vector2(x_right, y))

	# 3. Hàng ngang Nam: mở cổng ở giữa hướng ra đại lộ (x: 1016..1080)
	for x in [840, 872, 904, 936, 968, 1000, 1096, 1128, 1160, 1192, 1224, 1256]:
		_add_sprite(fh, Vector2(x, n_ybot))
	_add_sprite(f_gate, Vector2(farm_mid_x, n_ybot))

	# Va chạm Thửa Bắc
	_wall(Vector2(farm_mid_x, n_ytop), Vector2(farm_width, 10))
	_wall(Vector2(x_left, (n_ytop + n_ybot) / 2.0), Vector2(10, n_ybot - n_ytop))
	_wall(Vector2(x_right, (n_ytop + n_ybot) / 2.0), Vector2(10, n_ybot - n_ytop))
	_wall(Vector2((x_left + 1016) / 2.0, n_ybot), Vector2(1016 - x_left, 10))
	_wall(Vector2((1080 + x_right) / 2.0, n_ybot), Vector2(x_right - 1080, 10))

	# ---------------- THỬA NAM (SOUTH PLOT: y: 512..640) ----------------
	var s_ytop := 498
	var s_ybot := 654

	# 1. Hàng ngang Bắc: mở cổng ở giữa hướng ra đại lộ (x: 1016..1080)
	for x in [840, 872, 904, 936, 968, 1000, 1096, 1128, 1160, 1192, 1224, 1256]:
		_add_sprite(fh, Vector2(x, s_ytop))
	_add_sprite(f_gate, Vector2(farm_mid_x, s_ytop))

	_add_sprite(f_tl, Vector2(x_left, s_ytop))
	_add_sprite(f_tr, Vector2(x_right, s_ytop))
	_add_sprite(f_bl, Vector2(x_left, s_ybot))
	_add_sprite(f_br, Vector2(x_right, s_ybot))

	# 2. Hai cột dọc Tây và Đông (liền kín)
	for y in [530, 562, 594, 626]:
		_add_sprite(fv, Vector2(x_left, y))
		_add_sprite(fv, Vector2(x_right, y))

	# 3. Hàng ngang Nam (liền kín)
	for x in range(x_left + 32, x_right, 32):
		_add_sprite(fh, Vector2(x, s_ybot))

	# Va chạm Thửa Nam
	_wall(Vector2(farm_mid_x, s_ybot), Vector2(farm_width, 10))
	_wall(Vector2(x_left, (s_ytop + s_ybot) / 2.0), Vector2(10, s_ybot - s_ytop))
	_wall(Vector2(x_right, (s_ytop + s_ybot) / 2.0), Vector2(10, s_ybot - s_ytop))
	_wall(Vector2((x_left + 1016) / 2.0, s_ytop), Vector2(1016 - x_left, 10))
	_wall(Vector2((1080 + x_right) / 2.0, s_ytop), Vector2(x_right - 1080, 10))


func _add_sprite(tex: Texture2D, pos: Vector2, parent: Node = null) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	(parent if parent != null else world).add_child(s)


func _build_walls() -> void:
	var t := 40.0
	# Chặn biên Bắc tại chân vách núi Stardew Valley (y = 80px)
	_wall(Vector2(WORLD_SIZE.x / 2, 20.0), Vector2(WORLD_SIZE.x + t * 2, 120.0))
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
	hud.open_inventory_requested.connect(_open_inventory)
	hud.open_storage_requested.connect(_open_storage)
	hud.open_cat_requested.connect(_open_cat_panel)
	hud.open_stall_requested.connect(_open_market_stall)
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
	storage_panel = StoragePanelScript.new()
	add_child(storage_panel)
	storage_panel.closed.connect(_close_panels)
	storage_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))
	cat_panel = CatPanelScript.new()
	add_child(cat_panel)
	cat_panel.closed.connect(_close_panels)
	cat_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))
	quest_panel = QuestPanelScript.new()
	add_child(quest_panel)
	quest_panel.setup(quest_mgr)
	quest_panel.closed.connect(_close_panels)
	quest_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))
	tool_upgrade_panel = ToolUpgradePanelScript.new()
	add_child(tool_upgrade_panel)
	tool_upgrade_panel.closed.connect(_close_panels)
	tool_upgrade_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))
	hud.setup_quests(quest_mgr)
	hud.open_quests_requested.connect(_open_quest_panel)
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
	if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("android") or OS.get_environment("FARM_TOUCH") != "":
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
	if minimap != null:
		minimap.visible = (mode == Mode.PLAY) and (not in_mine)
	if touch_ui != null:
		touch_ui.visible = mode == Mode.PLAY
	if mode != Mode.PLAY or get_tree().paused:
		return
	GameState.tick(delta)
	Inventory.tick_animals(delta)
	_process_stall_customers(delta)
	hud.set_clock(GameState.clock_text())
	canvas_mod.color = _tint()
	# Gợn sóng nước hồ tự nhiên phong cách Stardew Valley
	if not in_mine:
		_lake_ripple_timer -= delta
		if _lake_ripple_timer <= 0.0:
			_lake_ripple_timer = randf_range(1.5, 2.5)
			var r_angle := randf() * TAU
			var r_dist := sqrt(randf())
			var rx := 1440.0 + cos(r_angle) * (r_dist * 115.0)
			var ry := 900.0 + sin(r_angle) * (r_dist * 75.0)
			if ry >= 820.0 and ry <= 990.0:
				_spawn_water_ripple(Vector2(rx, ry), randf_range(0.85, 1.15), randf_range(0.7, 0.9))

	if fishing:
		fishing_left -= delta
		hud.set_hint("Đang thả câu... còn %d giây" % int(ceil(maxf(fishing_left, 0.0))))
		highlight.visible = false
		# Dây câu mảnh kết nối đầu cần tới phao
		if is_instance_valid(_fishing_line) and is_instance_valid(_bobber_spr):
			var tip: Vector2 = player.get_rod_tip_position()
			var bpos: Vector2 = _bobber_spr.position
			var mid: Vector2 = (tip + bpos) * 0.5 + Vector2(0, 4.0)
			_fishing_line.points = PackedVector2Array([tip, mid, bpos])
		# Gợn sóng nước lan tỏa từ phao câu
		_bobber_ripple_timer -= delta
		if _bobber_ripple_timer <= 0.0:
			_bobber_ripple_timer = 0.85
			if is_instance_valid(_bobber_spr):
				_spawn_water_ripple(_bobber_spr.position, 0.75, 0.7)
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

	# Giới hạn số lượng khách ghé sạp cùng lúc (tối đa 3 khách để sạp thoáng đãng)
	if _stall_customers.size() >= 3:
		return

	_stall_customer_timer += delta
	# Giảm tần suất: khoảng 16 - 26 giây mới có một khách mới ghé sạp
	if _stall_customer_timer < _next_stall_customer_delay:
		return
	_stall_customer_timer = 0.0
	_next_stall_customer_delay = randf_range(16.0, 26.0)

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
	cust.wait_timeout_expired.connect(func(who: String, what: String):
		hud.toast("%s: Đợi một lúc không thấy có %s nên đành về vậy... 💨" % [who, what], Color(0.95, 0.75, 0.55))
	)
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
	if quest_mgr != null:
		quest_mgr.advance_progress("stall_sell", "any", qty)
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue, _cat_save_data(), _quest_save_data())


func _tint() -> Color:
	# 7:00 - 19:00 trời sáng; 19:00 - 7:00 đêm dịu
	var t := GameState.clock
	var night := Color(0.68, 0.72, 0.92)
	var day := Color.WHITE

	# Điều chỉnh tông màu môi trường theo thời tiết
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
		# 0:00-6:00 đêm; 6:00-7:00 chuyển sáng
		return night.lerp(day, clampf((t - 360) / 60.0, 0, 1))
	if t < 1140:
		return day
	if t < 1200:
		# 19:00-20:00 chuyển tối
		return day.lerp(night, clampf((t - 1140) / 60.0, 0, 1))
	return night


func _update_hint_and_highlight() -> void:
	if in_mine:
		highlight.visible = false
		var near_m: Dictionary = mine_manager.get_interactable_near(player.position) if mine_manager else {}
		if not near_m.is_empty():
			hud.set_hint("E: " + str(near_m.get("label", "")))
		else:
			hud.set_hint("")
		return

	var near := _nearest_interactable()
	if not near.is_empty():
		highlight.visible = false
		var lbl: String = str(near.label)
		var pen_matched := false
		for pcfg in PENS_CONFIG:
			if near.pos == pcfg.rect.get_center():
				pen_matched = true
				var sid: String = str(pcfg.id)
				var r_count := Inventory.ready_products_for_species(sid)
				var cname: String = str(pcfg.name)
				var hungry_count := Inventory.hungry_animals_for_species(sid)
				if r_count > 0:
					lbl = "Thu hoạch %s (%d) ⭐" % [cname, r_count]
				elif hungry_count > 0:
					if Inventory.feed_count() > 0:
						lbl = "Cho %s ăn 🌾 (%d con đói · Cám x%d)" % [cname, hungry_count, Inventory.feed_count()]
					else:
						lbl = "%s (Đói · Cần mua Túi Cám ở Cửa Hàng)" % cname
				else:
					var tier := Inventory.get_coop_tier(sid)
					if tier == 0:
						lbl = "%s (Chưa mua)" % cname
					else:
						lbl = "%s (%d con)" % [cname, Inventory.animals_of_species(sid)]
				break
		if not pen_matched and near.pos == MAILBOX_POS:
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
	if in_mine and mine_manager != null:
		return mine_manager.get_interactable_near(player.position)

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
	# Kiểm tra từng con vật trong chuồng (cho ăn / thu hoạch trực tiếp)
	for anim in active_pen_animals:
		if is_instance_valid(anim):
			var d_anim: float = player.position.distance_to(anim.position)
			if d_anim <= 42.0 and d_anim < best_d:
				best_d = d_anim
				var aname: String = anim.get_animal_name()
				if anim.is_ready():
					best = {
						"pos": anim.position,
						"r": 42.0,
						"label": "Thu hoạch %s (%s) ⭐" % [aname, anim.get_product_name()],
						"cb": func(): _harvest_single_animal(anim)
					}
				elif not anim.is_fed():
					if Inventory.feed_count() > 0:
						best = {
							"pos": anim.position,
							"r": 42.0,
							"label": "Cho %s ăn 🌾 (Cám x%d)" % [aname, Inventory.feed_count()],
							"cb": func(): _feed_single_animal(anim)
						}
					else:
						best = {
							"pos": anim.position,
							"r": 42.0,
							"label": "Cho %s ăn 🌾 (Cần mua Túi Cám ở Cửa Hàng)" % aname,
							"cb": func(): hud.toast("Bạn cần mua Túi Cám ở tiệm Cô Tư để cho ăn!", Color(1.0, 0.65, 0.4))
						}
				elif anim.state == PenAnimal.State.EATING or anim.state == PenAnimal.State.WALK_TO_TROUGH:
					best = {
						"pos": anim.position,
						"r": 42.0,
						"label": "%s (Đang ăn trong máng 🌾)" % aname,
						"cb": func(): pass
					}
				else:
					var rem: int = int(ceil(anim.get_remaining_wait_time()))
					best = {
						"pos": anim.position,
						"r": 42.0,
						"label": "%s (Đang lớn... còn %ds) ⏳" % [aname, rem],
						"cb": func(): pass
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
		elif shop_panel.visible or inv_panel.visible or fish_shop.visible or poultry_shop.visible or (stall_panel != null and stall_panel.visible) or (mailbox_panel != null and mailbox_panel.visible) or (storage_panel != null and storage_panel.visible) or (cat_panel != null and cat_panel.visible) or (quest_panel != null and quest_panel.visible) or (tool_upgrade_panel != null and tool_upgrade_panel.visible):
			_close_panels()
	elif event.is_action_pressed("interact"):
		if mode == Mode.PLAY and not get_tree().paused:
			_do_interact()
		elif mode == Mode.DIALOG:
			dialog_box.advance()
		elif (mailbox_panel != null and mailbox_panel.visible) or (stall_panel != null and stall_panel.visible) or (storage_panel != null and storage_panel.visible) or (cat_panel != null and cat_panel.visible) or (quest_panel != null and quest_panel.visible) or (tool_upgrade_panel != null and tool_upgrade_panel.visible):
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
	elif event.is_action_pressed("quick_eat") and mode == Mode.PLAY and not get_tree().paused:
		_quick_eat()
	elif event is InputEventKey and event.pressed and not event.echo:
		if mode == Mode.PLAY and not get_tree().paused:
			if event.keycode == KEY_K:
				_open_storage()
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_M:
				_open_cat_panel()
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_F:
				_quick_eat()
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_Q:
				if hud != null and hud.quest_drawer != null:
					hud.quest_drawer.toggle_drawer()
				else:
					_open_quest_panel()
				get_viewport().set_input_as_handled()
				return
			elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
				hud.select_slot_by_index(event.keycode - KEY_1)
		elif (storage_panel != null and storage_panel.visible and event.keycode == KEY_K) \
			or (cat_panel != null and cat_panel.visible and event.keycode == KEY_M) \
			or (quest_panel != null and quest_panel.visible and event.keycode == KEY_Q):
			_close_panels()
			get_viewport().set_input_as_handled()
			return
	elif event is InputEventMouseButton and event.pressed and mode == Mode.PLAY and not get_tree().paused:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			hud.cycle_slot(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			hud.cycle_slot(1)


# ---------------- hành động ----------------

func _get_action_stamina_cost(act: String) -> float:
	match act:
		"till": return OreDB.get_hoe_stamina(Inventory.get_hoe_tier())
		"water": return 5.0
		"plant": return 5.0
		"harvest": return 1.5
		"catch_pest": return 1.0
		"fish": return 15.0
		"mine": return OreDB.get_pickaxe_stamina(Inventory.get_pickaxe_tier())
	return 0.0


func _quick_eat() -> void:
	if GameState.stamina >= GameState.max_stamina:
		hud.toast("Thể lực đã tràn đầy (%d/%d)!" % [int(GameState.stamina), int(GameState.max_stamina)], Color(1.0, 0.88, 0.4))
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
		hud.toast("Túi đồ không có nông sản hoặc thịt để ăn! (Bấm I xem túi)", Color(1.0, 0.65, 0.4))
		return

	var res := GameState.eat_food(best_cat, best_id)
	if res.get("ok", false):
		hud.toast(str(res.get("msg", "")), Color(0.4, 1.0, 0.5))
		_spawn_effect("fx_harvest", player.position)
		if inv_panel != null and inv_panel.visible:
			inv_panel.refresh()
	else:
		hud.toast(str(res.get("msg", "")), Color(1.0, 0.65, 0.4))


func _do_interact() -> void:
	if fishing:
		return
	if in_mine and mine_manager != null:
		var near_m: Dictionary = mine_manager.get_interactable_near(player.position)
		if not near_m.is_empty() and near_m.has("cb") and near_m.cb is Callable:
			near_m.cb.call()
		return
	var near := _nearest_interactable()
	if not near.is_empty():
		near.cb.call()
		return
	var tile = farm.tile_at_world(player.get_facing_point())
	if tile == null:
		return
	var info: Dictionary = farm.action_at(tile)
	var act := str(info.act)
	if act == "none":
		return

	var cost := _get_action_stamina_cost(act)
	if cost > 0.0 and GameState.stamina < cost:
		hud.toast("Bạn đã kiệt sức! Hãy ăn nông sản hoặc thịt (phím F hoặc I) để hồi thể lực ⚡", Color(1.0, 0.45, 0.35))
		return

	var crop_id_before: String = tile.crop_id if tile != null else ""
	var selected_seed_before := Inventory.selected_seed
	var msg: String = farm.perform_at(tile)
	if msg == "":
		return

	if cost > 0.0:
		GameState.use_stamina(cost)

	hud.toast(msg)
	if act != "none":
		_spawn_effect("fx_" + act, farm.tile_center(tile.coord))

	if quest_mgr != null:
		match act:
			"harvest":
				quest_mgr.advance_progress("harvest", crop_id_before)
			"plant":
				quest_mgr.advance_progress("plant", selected_seed_before)
			"water":
				quest_mgr.advance_progress("water", "any")
			"till":
				quest_mgr.advance_progress("till", "any")
			"catch_pest":
				quest_mgr.advance_progress("catch_pest", "sau_bo")

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


func _talk_mayor() -> void:
	mode = Mode.DIALOG
	get_tree().paused = true
	_dialog_next = "quests"
	if _mayor_met:
		dialog_box.start("Trưởng Thôn", ["Chào cháu! Hãy xem bảng nhiệm vụ hôm nay có việc gì giúp làng nhé!"])
	else:
		dialog_box.start("Trưởng Thôn", [
			"Chào mừng cháu đến với làng! Bác là Trưởng Thôn nơi đây.",
			"Mỗi ngày và mỗi tuần bác đều có các nhiệm vụ giúp làng phát triển nông nghiệp và khai khoáng.",
			"Nhiệm vụ Ngày thưởng 100 vàng + 10 nguyên liệu cùng loại!",
			"Nhiệm vụ Tuần thưởng 500 vàng + 50 nguyên liệu cùng loại, còn Nhiệm vụ Tổng thưởng 50 vàng mỗi mốc thành tựu!",
			"Cháu có thể mở Bảng Nhiệm Vụ bằng phím [Q] hoặc bấm biểu tượng nhiệm vụ góc trên bất cứ lúc nào."
		])
		_mayor_met = true


func _on_dialog_finished() -> void:
	if _dialog_next == "none":
		mode = Mode.PLAY
		get_tree().paused = false
		return
	elif _dialog_next == "leah_gift":
		mode = Mode.PLAY
		get_tree().paused = false
		Inventory.add_pickaxe("basic")
		hud.toast("Nhận được Cúp khai mỏ sơ cấp từ Leah! ⛏️", Color(0.7, 1.0, 0.7))
		return
	elif _dialog_next == "tool_upgrade":
		_open_tool_upgrade_panel()
	elif _dialog_next == "fish":
		_open_fish_shop()
	elif _dialog_next == "poultry":
		_open_poultry_shop()
	elif _dialog_next == "quests":
		_open_quest_panel()
	else:
		_open_shop()


func _talk_leah() -> void:
	mode = Mode.DIALOG
	get_tree().paused = true
	if not Inventory.has_pickaxe():
		_dialog_next = "leah_gift"
		dialog_box.start("Leah", [
			"Chào bạn! Mình là Leah.",
			"Đây là hầm mỏ bỏ hoang của làng, dưới lòng đất ẩn chứa rất nhiều khoáng sản quý giá như Đồng, Sắt, Vàng và Đá quý hiếm.",
			"Mình tặng bạn chiếc Cúp sơ cấp này nhé! Hãy cầm Cúp và xuống mỏ thử vận may nào!"
		])
		_leah_met = true
	else:
		_dialog_next = "tool_upgrade"
		dialog_box.start("Leah", [
			"Chào bạn! Càng xuống sâu hầm mỏ sẽ càng có nhiều quặng quý hiếm.",
			"Nếu có đủ Quặng và Vàng, mình sẽ rèn nâng cấp Cuốc đất và Cúp mỏ cho bạn để làm việc đỡ tốn thể lực hơn nhé!"
		])


func _read_mine_sign() -> void:
	mode = Mode.DIALOG
	get_tree().paused = true
	_dialog_next = "none"
	dialog_box.start("📜 Biển Báo Hầm Mỏ", [
		"• Tầng 1 - 2: Nhiều Đá cuội, Than đá & Quặng Đồng.",
		"• Tầng 3 - 5: Xuất hiện Quặng Sắt & Hồng Ngọc (Ruby).",
		"• Tầng 6+: Quặng Vàng & Kim Cương quý hiếm.",
		"⚠️ Hướng dẫn: Đứng gần khối quặng và bấm E để đập bằng Cúp. Bấm E tại cầu thang để chuyển tầng!"
	])


func _fade_transition(on_mid: Callable) -> void:
	if fade_rect == null:
		if on_mid.is_valid():
			on_mid.call()
		return
	player.can_move = false
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.35)
	tw.tween_callback(func():
		if on_mid.is_valid():
			on_mid.call()
	)
	tw.tween_interval(0.1)
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		player.can_move = true
	)


func _enter_mine() -> void:
	if not Inventory.has_pickaxe():
		hud.toast("Hãy nói chuyện với Leah để nhận Cúp trước khi vào mỏ! ⛏️", Color(1.0, 0.85, 0.5))
		return
	_fade_transition(func():
		in_mine = true
		player.reparent(mine_manager)
		world.process_mode = Node.PROCESS_MODE_DISABLED
		world.visible = false
		if is_instance_valid(weather_mgr):
			weather_mgr.visible = false
		if is_instance_valid(hud):
			hud.set_underground(true)
		mine_manager.process_mode = Node.PROCESS_MODE_PAUSABLE
		mine_manager.enter_mine(1)
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = mine_manager.MINE_TILES.x * mine_manager.TILE
		cam.limit_bottom = mine_manager.MINE_TILES.y * mine_manager.TILE
		hud.toast("Đã tiến vào Hầm Mỏ — Tầng 1! ⛏️", Color(0.8, 0.9, 1.0))
	)


func _on_exit_mine() -> void:
	if not in_mine:
		return
	_fade_transition(func():
		in_mine = false
		player.reparent(world)
		mine_manager.process_mode = Node.PROCESS_MODE_DISABLED
		mine_manager.visible = false
		world.process_mode = Node.PROCESS_MODE_PAUSABLE
		world.visible = true
		if is_instance_valid(weather_mgr):
			weather_mgr.visible = true
		if is_instance_valid(hud):
			hud.set_underground(false)
		player.position = MINE_ENTRANCE_POS + Vector2(0, 32)
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = int(WORLD_SIZE.x)
		cam.limit_bottom = int(WORLD_SIZE.y)
		hud.toast("Đã trở lại mặt đất! 🌄")
	)


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
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue, _cat_save_data(), _quest_save_data())


func _open_fish_shop() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	fish_shop.open()


func _open_poultry_shop() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	poultry_shop.open()


func _open_tool_upgrade_panel() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	tool_upgrade_panel.open()


func _talk_tu() -> void:
	mode = Mode.DIALOG
	get_tree().paused = true
	_dialog_next = "poultry"
	if _npc_tu_met:
		dialog_box.start("Cô Tư", [
			"Vật nuôi khỏe mạnh hết nấy con! Mua chuồng, mua giống hay bán sản phẩm?",
			"Nhớ nghen: Cứ nuôi đủ 2 con lớn cùng loài là chúng có thể sinh ra con non baby đó!"
		])
	else:
		dialog_box.start("Cô Tư", [
			"Chào con! Cô Tư đây — trại giống gia cầm gia súc uy tín nhất vùng!",
			"Cô chuyên bán 4 loại con giống tốt: Gà trắng, Bò trắng, Lợn và Cừu.",
			"Muốn nuôi thì nhớ MUA CHUỒNG trước: Chuồng gia cầm nuôi Gà, Chuồng gia súc nuôi Bò, Lợn, Cừu.",
			"Gà cho trứng, Bò cho sữa, Lợn cho thịt, Cừu cho lông xén.",
			"Đặc biệt: Nuôi đủ đôi (từ 2 con cùng loài trở lên) là chúng có thể đẻ ra con baby!",
			"Nhớ ghé chuồng bấm [E] thu hoạch rồi mang qua cô thu mua giá ngon nghen con!"
		])
	_npc_tu_met = true


func _collect_pen_products(species_id: String) -> void:
	var n: int = Inventory.collect_products_for_species(species_id)
	if n > 0:
		var d := PoultryDB.get_animal(species_id)
		var pname := str(d.get("product_name", "sản phẩm"))
		hud.toast("Đã thu hoạch %d %s! 🧺" % [n, pname], Color(1.0, 0.88, 0.55))
		if quest_mgr != null:
			quest_mgr.advance_progress("poultry", "any", n)
			quest_mgr.advance_progress("poultry", str(d.get("product", "")), n)
	else:
		var all_n: int = Inventory.collect_products()
		if all_n > 0:
			hud.toast("Đã thu %d sản phẩm chăn nuôi! 🧺" % all_n, Color(1.0, 0.75, 0.5))
			if quest_mgr != null:
				quest_mgr.advance_progress("poultry", "any", all_n)
		else:
			var c := PoultryDB.get_coop_data(species_id)
			var cname := str(c.get("name", "Chuồng"))
			var tier := Inventory.get_coop_tier(species_id)
			if tier == 0:
				hud.toast("%s chưa được xây! Hãy ghé tiệm Cô Tư để mua." % cname, Color(0.9, 0.75, 0.6))
			elif Inventory.animals_of_species(species_id) == 0:
				hud.toast("%s đang trống! Hãy mua con giống tại tiệm Cô Tư." % cname, Color(0.9, 0.8, 0.6))
			else:
				hud.toast("%s chưa có sản phẩm nào để thu hoạch!" % cname, Color(0.9, 0.7, 0.6))


func _collect_products() -> void:
	var n: int = Inventory.collect_products()
	if n > 0:
		hud.toast("Đã thu %d sản phẩm chăn nuôi! Bán cho Cô Tư." % n, Color(1.0, 0.75, 0.5))
		if quest_mgr != null:
			quest_mgr.advance_progress("poultry", "any", n)
			quest_mgr.advance_progress("poultry", "trung_ga", n)
	else:
		hud.toast("Chưa có sản phẩm nào chờ thu...", Color(0.8, 0.8, 0.8))


func _interact_pen(species_id: String) -> void:
	var r_count := Inventory.ready_products_for_species(species_id)
	if r_count > 0:
		_collect_pen_products(species_id)
		return
	var hungry_count := Inventory.hungry_animals_for_species(species_id)
	if hungry_count > 0:
		if Inventory.feed_count() > 0:
			var fed := Inventory.feed_all_hungry_for_species(species_id)
			if fed > 0:
				var c := PoultryDB.get_coop_data(species_id)
				hud.toast("Đã cho %d con ở %s ăn 🌾! Chúng đang tiến tới máng ăn." % [fed, c.get("name", "Chuồng")], Color(1.0, 0.9, 0.4))
				for anim in active_pen_animals:
					if is_instance_valid(anim) and anim.species_id == species_id and anim.is_fed() and anim.state != PenAnimal.State.EATING:
						anim.target_pos = anim.get_trough_eating_spot()
						anim.state = PenAnimal.State.WALK_TO_TROUGH
						anim._play_heart_effect()
		else:
			hud.toast("Bạn cần mua Túi Cám ở Cửa Hàng Cô Tư để cho ăn!", Color(1.0, 0.65, 0.4))
		return
	_collect_pen_products(species_id)


func _harvest_single_animal(anim: PenAnimal) -> void:
	if not is_instance_valid(anim):
		return
	var prod_id := anim.harvest()
	if prod_id != "":
		var d := PoultryDB.get_animal(anim.species_id)
		var pname := str(d.get("product_name", "sản phẩm"))
		hud.toast("Đã thu hoạch 1 %s từ %s! 🧺 (Có thể cho ăn tiếp ngay)" % [pname, anim.get_animal_name()], Color(1.0, 0.92, 0.55))
		if quest_mgr != null:
			quest_mgr.advance_progress("poultry", "any", 1)
			quest_mgr.advance_progress("poultry", prod_id, 1)


func _feed_single_animal(anim: PenAnimal) -> void:
	if not is_instance_valid(anim):
		return
	if Inventory.feed_count() <= 0:
		hud.toast("Bạn cần mua Túi Cám ở Cửa Hàng để cho ăn!", Color(1.0, 0.65, 0.4))
		return
	if anim.feed():
		hud.toast("Đã cho %s ăn 1 Túi Cám! Đang đi tới máng ăn 🌾 (Cám còn: ×%d)" % [anim.get_animal_name(), Inventory.feed_count()], Color(1.0, 0.92, 0.45))


func _open_inventory() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	inv_panel.open()


func _open_mailbox() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	mailbox_panel.open(mailbox_data)


func _open_storage() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	storage_panel.open()


func _open_cat_panel() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	cat_panel.open(cat_helper)


func _open_quest_panel() -> void:
	mode = Mode.PANEL
	get_tree().paused = true
	quest_panel.open("daily")


func _update_npc_mayor_indicator() -> void:
	if npc_mayor == null or quest_mgr == null:
		return
	if quest_mgr.has_unclaimed_rewards():
		npc_mayor.set_quest_indicator("question")
	elif quest_mgr.has_active_quests():
		npc_mayor.set_quest_indicator("exclamation")
	else:
		npc_mayor.set_quest_indicator("")


func _on_mailbox_changed() -> void:
	_update_mailbox_badge()
	hud.rebuild_hotbar()
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue, _cat_save_data(), _quest_save_data())


func _close_panels() -> void:
	shop_panel.visible = false
	fish_shop.visible = false
	poultry_shop.visible = false
	inv_panel.visible = false
	if storage_panel != null:
		storage_panel.visible = false
	if cat_panel != null:
		cat_panel.visible = false
	if mailbox_panel != null:
		mailbox_panel.visible = false
	if stall_panel != null:
		stall_panel.visible = false
	if quest_panel != null:
		quest_panel.visible = false
	if tool_upgrade_panel != null:
		tool_upgrade_panel.visible = false
	pause_menu.visible = false
	get_tree().paused = false
	if mode != Mode.TITLE:
		mode = Mode.PLAY


func _resume_from_pause() -> void:
	pause_menu.close()
	get_tree().paused = false
	if mode != Mode.TITLE:
		mode = Mode.PLAY


func _cat_save_data() -> Dictionary:
	if is_instance_valid(cat_helper):
		return cat_helper.get_save_dict()
	return {}


func _quest_save_data() -> Dictionary:
	if is_instance_valid(quest_mgr):
		return quest_mgr.get_save_data()
	return {}


func _save_now() -> void:
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue, _cat_save_data(), _quest_save_data())
	hud.toast("Đã lưu game!", Color(0.6, 1.0, 0.6))


func _back_to_title() -> void:
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue, _cat_save_data(), _quest_save_data())
	_close_panels()
	mode = Mode.TITLE
	dialog_box.force_close()
	title_screen.open(SaveSystem.has_save())


# ---------------- ngủ qua đêm ----------------

func _ask_sleep() -> void:
	mode = Mode.DIALOG
	get_tree().paused = true
	dialog_box.ask("Đi ngủ và lưu game? (Lưu ý: Ngủ không hồi thể lực, hãy ăn nông sản hoặc thịt ⚡)")


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
	if in_mine:
		in_mine = false
		player.reparent(world)
		if mine_manager != null:
			mine_manager.process_mode = Node.PROCESS_MODE_DISABLED
			mine_manager.visible = false
		world.process_mode = Node.PROCESS_MODE_PAUSABLE
		world.visible = true
		if is_instance_valid(weather_mgr):
			weather_mgr.visible = true
		if is_instance_valid(hud):
			hud.set_underground(false)
		player.position = HOUSE_POS + Vector2(15, 10)
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = int(WORLD_SIZE.x)
		cam.limit_bottom = int(WORLD_SIZE.y)
	GameState.sleep_to_morning(forced)
	var next_w: String = WeatherManagerScript.roll_weather(GameState.day)
	GameState.weather = next_w
	if is_instance_valid(weather_mgr):
		weather_mgr.set_weather(next_w)
	if is_instance_valid(hud):
		hud.set_weather(next_w)
	var ready_n: int = farm.ready_count()
	# Dọn các khách NPC ngày hôm trước để ngày mới đón khách mới
	for c in _stall_customers:
		if is_instance_valid(c):
			c.queue_free()
	_stall_customers.clear()
	_active_stall_customer = null
	# Chú mèo tam thể làm nông: trả lương và sẵn sàng cho ngày mới
	if is_instance_valid(cat_helper) and cat_helper.is_hired:
		cat_helper._pay_daily_wage()
		cat_helper.wage_paid_today = false
		cat_helper.position = CatHelperScript.TENT_SLEEP_POS
		cat_helper.state = CatHelperScript.State.IDLE
		cat_helper._hide_bubble()
	# Cập nhật nhiệm vụ theo thời gian thực
	if is_instance_valid(quest_mgr):
		quest_mgr.check_real_time_refresh()
		_update_npc_mayor_indicator()
	# Cây cối tự nhiên có tỉ lệ mọc thêm trên bề mặt cỏ qua đêm
	if foliage_nodes.size() < 95 and randf() < 0.60:
		_sprout_random_plant()
	# Sâu bọ có thể xuất hiện trên các luống cây đang lớn qua đêm (trời mưa dông không sinh sâu)
	var new_pests := 0
	if not (next_w in [WeatherManagerScript.RAIN, WeatherManagerScript.STORM]):
		for t in farm.tiles.values():
			if t.tstate == FarmTileScript.TState.PLANTED and not t.is_ready() and not t.has_pest and t.growth > 3.0:
				if randf() < 0.15:
					t.spawn_pest()
					new_pests += 1
	# Hàng hoá trên sạp được giữ nguyên qua đêm (không bán qua đêm)
	SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue, _cat_save_data(), _quest_save_data())
	hud.set_clock(GameState.clock_text())
	canvas_mod.color = _tint()
	if forced:
		hud.toast("Bạn gục ngã vì quá khuya... Đã lưu game 💾 (Ăn thức ăn để hồi thể lực)", Color(1.0, 0.55, 0.45))
	else:
		hud.toast("Ngày mới! Đã lưu game thành công 💾 (Ăn thức ăn để hồi thể lực)", Color(0.65, 1.0, 0.6))
	if new_pests > 0:
		hud.toast("⚠️ Có %d cây bị sâu cắn phá! Hãy bắt sâu bọ để cây lớn tiếp 🐛" % new_pests, Color(1.0, 0.65, 0.4))
	if ready_n > 0:
		hud.toast("%d cây đã chín chờ thu hoạch!" % ready_n, Color(0.75, 1.0, 0.7))
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
	if GameState.stamina < 2.0:
		hud.toast("Bạn đã kiệt sức! Không đủ sức múc nước (cần 2⚡). Hãy ăn nông sản hoặc thịt!", Color(1.0, 0.45, 0.35))
		return
	GameState.use_stamina(2.0)
	var _added: int = Inventory.refill_water()
	player.facing = (POND_RECT.get_center() - player.position).normalized()
	_spawn_effect("fx_water", player.position + player.facing * 18.0)
	player.play_action_anim("water")
	player.can_move = false
	var act_time: float = player.get_action_duration("water")
	await get_tree().create_timer(act_time).timeout
	player.can_move = true
	hud.rebuild_hotbar()
	hud.toast("Đã múc nước từ ao (-2⚡)! Bình tưới: %d/%d 💧" % [Inventory.water_level, Inventory.water_max], Color(0.4, 0.85, 1.0))


# Tạo hiệu ứng gợn sóng nước lan tỏa chuẩn Stardew Valley (8 khung hình từ TileSheets/animations.png)
func _spawn_water_ripple(pos: Vector2, r_scale: float = 1.0, r_dur: float = 0.7) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = TextureGen.water_ripple_frame(0)
	spr.position = pos
	spr.scale = Vector2(r_scale, r_scale)
	spr.z_index = 2
	world.add_child(spr)
	var tw := spr.create_tween()
	var frame_dur: float = r_dur / 8.0
	for f in range(1, 8):
		var frame_idx := f
		tw.tween_interval(frame_dur)
		tw.tween_callback(func():
			if is_instance_valid(spr):
				spr.texture = TextureGen.water_ripple_frame(frame_idx)
		)
	tw.tween_property(spr, "modulate:a", 0.0, frame_dur)
	tw.tween_callback(func():
		if is_instance_valid(spr):
			spr.queue_free()
	)
	return spr


func _start_fishing() -> void:
	if fishing:
		return
	var fish_stamina := _get_action_stamina_cost("fish")
	if GameState.stamina < fish_stamina:
		hud.toast("Bạn đã kiệt sức! Không đủ sức câu cá (cần %d⚡). Hãy ăn nông sản hoặc thịt!" % int(fish_stamina), Color(1.0, 0.45, 0.35))
		return
	var tier := str(Inventory.take_cast())
	if tier == "":
		hud.toast("Hết lượt câu! Mua cần câu ở Chú Hai (bờ ao).", Color(1.0, 0.6, 0.5))
		return
	GameState.use_stamina(fish_stamina)
	var rod := FishDB.get_rod(tier)
	fishing = true
	var fish_time: float = FishDB.FISH_TIME
	if GameState.weather in [WeatherManagerScript.RAIN, WeatherManagerScript.STORM]:
		fish_time = 9.0
	elif GameState.weather == WeatherManagerScript.DRIZZLE:
		fish_time = 12.0
	fishing_left = fish_time
	player.can_move = false
	hud.toast("Đã thả câu (%s — còn %d lượt)" % [rod.name, Inventory.total_casts()], Color(0.6, 0.9, 1.0))

	# Hướng nhân vật về phía mặt hồ và bắt đầu diễn hoạt câu cá Stardew Valley
	var dir := (POND_RECT.get_center() - player.position).normalized()
	player.facing = dir
	player.start_fishing_anim()

	# Tính vị trí phao tiếp nước trong hồ
	var pond_center := POND_RECT.get_center()
	var dist_to_center := player.position.distance_to(pond_center)
	var cast_dist: float = clampf(dist_to_center * 0.65, 42.0, 85.0)
	var bobber_target := player.position + dir * cast_dist

	# Tạo phao câu Stardew Valley
	_bobber_spr = Sprite2D.new()
	_bobber_spr.texture = TextureGen.get_tex("fx_bobber")
	_bobber_spr.z_index = 50
	var tip_pos: Vector2 = player.get_rod_tip_position()
	_bobber_spr.position = tip_pos
	world.add_child(_bobber_spr)

	# Dây câu mảnh kết nối đầu cần tới phao
	if _fishing_line != null and is_instance_valid(_fishing_line):
		_fishing_line.queue_free()
	_fishing_line = Line2D.new()
	_fishing_line.width = 1.0
	_fishing_line.default_color = Color(0.92, 0.94, 0.98, 0.82)
	_fishing_line.z_index = 49
	_fishing_line.points = PackedVector2Array([tip_pos, (tip_pos + bobber_target) * 0.5, bobber_target])
	world.add_child(_fishing_line)

	# Hiệu ứng ném phao bay vào mặt nước
	var cast_tw := _bobber_spr.create_tween()
	cast_tw.tween_property(_bobber_spr, "position", bobber_target, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cast_tw.tween_callback(func():
		if is_instance_valid(_bobber_spr):
			# Phao chạm mặt nước: tạo sóng tròn Stardew Valley và bọt nước
			_spawn_water_ripple(bobber_target, 1.25, 0.8)
			_spawn_effect("fx_water", bobber_target)
			# Nhấp nhô bồng bềnh
			var bob := _bobber_spr.create_tween().set_loops()
			bob.tween_property(_bobber_spr, "position:y", bobber_target.y - 2.5, 0.55).set_ease(Tween.EASE_OUT)
			bob.tween_property(_bobber_spr, "position:y", bobber_target.y + 0.5, 0.55).set_ease(Tween.EASE_IN)
	)


func _finish_fishing() -> void:
	fishing = false
	player.can_move = true
	var bobber_pos := _bobber_spr.position if is_instance_valid(_bobber_spr) else POND_RECT.get_center()
	if _rod_spr != null and is_instance_valid(_rod_spr):
		_rod_spr.queue_free()
		_rod_spr = null
	if _fishing_line != null and is_instance_valid(_fishing_line):
		_fishing_line.queue_free()
		_fishing_line = null
	if _bobber_spr != null and is_instance_valid(_bobber_spr):
		_spawn_water_ripple(bobber_pos, 1.35, 0.65)
		_bobber_spr.queue_free()
		_bobber_spr = null
	_spawn_effect("fx_water", bobber_pos)
	player.stop_fishing_anim()
	var night := GameState.clock < GameState.DAY_START or GameState.clock >= 1140
	var f := FishDB.roll_cast(night)
	if f.is_empty():
		hud.toast("Kéo cần lên... không con cá nào cắn!", Color(0.8, 0.8, 0.8))
		return
	var fid := str(f.id)
	if not Inventory.can_hold("fish", fid):
		hud.toast("Túi đồ đã đầy! Không thể giữ %s... Hãy cất bớt đồ vào nhà kho 🏚️" % f.name, Color(1.0, 0.5, 0.4))
		return
	Inventory.add_fish(fid, 1)
	if quest_mgr != null:
		quest_mgr.advance_progress("fish", fid, 1)
	if str(f.tier) == "legend":
		hud.toast("HUYỀN THOẠI! Bắt được %s!!!" % f.name, Color(1.0, 0.85, 0.3))
	elif str(f.tier) == "rare":
		hud.toast("Bắt được cá hiếm: %s!" % f.name, Color(0.6, 1.0, 0.9))
	else:
		hud.toast("Bắt được %s! Bán cho Chú Hai." % f.name)


# ---------------- bắt đầu / tiếp tục ----------------

func start_new_game() -> void:
	GameState.reset_new_game()
	if is_instance_valid(weather_mgr):
		weather_mgr.set_weather(WeatherManagerScript.SUNNY)
	if is_instance_valid(hud):
		hud.set_weather(WeatherManagerScript.SUNNY)
	Inventory.reset()
	Inventory.selected_seed = "rice"
	Inventory.add_hoes(2)
	Inventory.add_seed("rice", 2)
	Inventory.add_produce("sweet_potato", 2) # Khoai lang để ăn hồi thể lực
	Inventory.add_produce("thit_lon", 1)      # Thịt lợn để ăn hồi thể lực
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
	if is_instance_valid(cat_helper):
		cat_helper.dismiss()
		cat_helper.position = CatHelperScript.SPAWN_POS
		cat_helper.state = CatHelperScript.State.ARRIVING
		cat_helper.waypoints = [CatHelperScript.ROAD_JUNCTION_POS, Vector2(CatHelperScript.ROAD_JUNCTION_POS.x, CatHelperScript.WAITING_POS.y), CatHelperScript.WAITING_POS]
		cat_helper._show_bubble_text("...")
	if is_instance_valid(quest_mgr):
		var cur_day: int = QuestManagerScript.get_real_day_id()
		var cur_week: int = QuestManagerScript.get_real_week_id()
		quest_mgr.refresh_daily_quests(cur_day)
		quest_mgr.refresh_weekly_quests(cur_week)
		quest_mgr.lifetime_quests = QuestDB.init_lifetime_quests()
		quest_mgr.quests_refreshed.emit()
	_update_npc_mayor_indicator()
	dialog_box.force_close()
	title_screen.hide_me()
	get_tree().paused = false
	mode = Mode.PLAY
	hud.toast("WASD: di chuyển · E: tương tác · I: kho đồ · Q: nhiệm vụ · F: ăn nhanh hồi thể lực ⚡")


func continue_game() -> void:
	var d := SaveSystem.load_data()
	if d.is_empty():
		start_new_game()
		return
	GameState.money = int(d.get("money", 100))
	GameState.day = int(d.get("day", 1))
	GameState.clock = float(d.get("clock", GameState.DAY_START))
	GameState.stamina = float(d.get("stamina", 100.0))
	GameState.max_stamina = float(d.get("max_stamina", 100.0))
	GameState.weather = str(d.get("weather", "sunny"))
	if is_instance_valid(weather_mgr):
		weather_mgr.set_weather(GameState.weather)
	if is_instance_valid(hud):
		hud.set_weather(GameState.weather)
	var unl: Array = []
	for id in d.get("unlocked", ["rice"]):
		unl.append(str(id))
	GameState.unlocked = unl
	GameState.money_changed.emit(GameState.money)
	GameState.crops_changed.emit()
	GameState.stamina_changed.emit(GameState.stamina, GameState.max_stamina)
	GameState.weather_changed.emit(GameState.weather)
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
	if d.has("cat") and is_instance_valid(cat_helper):
		cat_helper.load_save_dict(d["cat"])
	if d.has("quests") and is_instance_valid(quest_mgr):
		quest_mgr.load_save_data(d["quests"])
	_update_npc_mayor_indicator()
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
	# ---- test chăn nuôi & sinh sản ----
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
			player.position = Vector2(1048, 680)
			player.facing = Vector2.UP
			cam.reset_smoothing()
			Input.action_press("move_up")
		240:
			Input.action_release("move_up")
			print("FARMSOUTH player=", player.position,
					" (kỳ vọng y > 650: bị rào nam thửa Nam chặn)")
		245:
			# Đi trên đại lộ giữa 2 thửa ruộng
			player.position = Vector2(700, 472)
			player.facing = Vector2.RIGHT
			cam.reset_smoothing()
			Input.action_press("move_right")
		395:
			Input.action_release("move_right")
			print("WESTDOOR player=", player.position,
					" (kỳ vọng x > 850: đại lộ giữa 2 ruộng thông thoáng)")
		400:
			# Thửa Bắc: đi vào qua cổng Nam (x=1048, y=446)
			player.position = Vector2(1048, 465)
			player.facing = Vector2.UP
			cam.reset_smoothing()
			Input.action_press("move_up")
		435:
			Input.action_release("move_up")
		440:
			# test cày ô đất ngay phía trước trong Thửa Bắc
			Inventory.hoes = 5
			player.facing = Vector2.UP
			var fp: Vector2 = player.get_facing_point()
			var t = farm.tile_at_world(fp)
			if t != null:
				farm.perform_at(t)
			print("ETEST pos=", player.position, " fp=", fp, " tile_tstate=", (t.tstate if t != null else -1), " (kỳ vọng 1=TILLED)")
		445:
			# Thửa Nam: đi vào qua cổng Bắc (x=1048, y=498)
			player.position = Vector2(1048, 480)
			player.facing = Vector2.DOWN
			cam.reset_smoothing()
			Input.action_press("move_down")
		595:
			Input.action_release("move_down")
			print("EASTDOOR player=", player.position,
					" (kỳ vọng y > 505: vào thửa Nam qua cổng Bắc)")
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
			# rào bắc thửa Bắc: đi xuống bị chặn
			player.position = Vector2(1048, 250)
			Input.action_press("move_down")
		985:
			Input.action_release("move_down")
			print("FARMTOP player=", player.position,
					" (kỳ vọng y < 295: bị rào bắc thửa Bắc chặn)")
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

			var trail_to_mine_ok: bool = false
			for p in PATHS:
				if p.has_point(Vector2(96, 300)):
					trail_to_mine_ok = true
			var mine_in_nw: bool = (MINE_ENTRANCE_POS.y < 250.0 and MINE_ENTRANCE_POS.x <= 120.0)
			var poi_mine_nw: bool = false
			for p in MinimapScript.POIS:
				if str(p.get("id", "")) == "mine" and p.get("pos", Vector2.ZERO).y < 250.0:
					poi_mine_nw = true
			var cust_freq_reduced: bool = (_next_stall_customer_delay >= 15.0)

			print("MINE_RELOCATION_TEST trail=", trail_to_mine_ok, " pos_nw=", mine_in_nw,
					" poi_nw=", poi_mine_nw, " cust_from_left=", cust_from_left,
					" cust_exit_left=", decline_ok, " cust_freq_reduced=", cust_freq_reduced)
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

			# 4. Kiểm thử Giới hạn túi đồ (Backpack 12 ô) + Nhà kho (Shed) + Bắt sâu bọ (Pests)
			# A. Giới hạn túi đồ
			Inventory.reset()
			Inventory.backpack_max = 12
			var initial_slots := Inventory.backpack_slots_used()
			Inventory.add_seed("rice", 5)
			Inventory.add_seed("wheat", 5)
			Inventory.add_produce("tomato", 3)
			Inventory.add_produce("corn", 2)
			Inventory.add_fish("chep", 1)
			var slots_after := Inventory.backpack_slots_used()
			var can_add_existing := Inventory.can_hold("produce", "tomato") # đã có trong túi -> true
			# B. Nhà kho Stardew Valley & Storage Panel
			player.position = SHED_POS + Vector2(0, 15)
			var near_shed: Dictionary = _nearest_interactable()
			var shed_offers_storage: bool = ("Nhà kho" in str(near_shed.get("label", "")))
			if near_shed.has("cb") and near_shed.cb is Callable:
				near_shed.cb.call()
			var storage_panel_opened: bool = (storage_panel != null and storage_panel.visible)
			# Cất đồ vào nhà kho
			var store_ok: bool = Inventory.store_item("produce", "tomato", 2)
			var stored_tomato: int = Inventory.storage_count("produce", "tomato")
			var bag_tomato_after: int = Inventory.produce_count("tomato")
			# Rút đồ từ nhà kho
			var withdraw_ok: bool = Inventory.withdraw_item("produce", "tomato", 1)
			var stored_tomato_final: int = Inventory.storage_count("produce", "tomato")
			_close_panels()
			# C. Sâu bọ trên cây trồng (Pest mechanic)
			var test_t = farm.tiles[Vector2i(0, 0)]
			test_t.till()
			test_t.plant("wheat")
			test_t.growth = 10.0
			test_t.spawn_pest()
			var pest_spawned: bool = test_t.has_pest
			var pest_action: Dictionary = farm.action_at(test_t)
			var pest_action_is_catch: bool = (str(pest_action.get("act", "")) == "catch_pest")
			var catch_msg: String = farm.perform_at(test_t)
			var pest_cleared: bool = (not test_t.has_pest)
			var worm_count: int = Inventory.produce_count("sau_bo")
			var worm_crop_db: Dictionary = CropDB.get_crop("sau_bo")
			var shed_tex_ok: bool = (TextureGen.get_tex("shed") != null)
			var caterpillar_tex_ok: bool = (TextureGen.get_tex("caterpillar") != null)

			print("SHED_PEST_BACKPACK_TEST initial_slots=", initial_slots, " slots_after=", slots_after,
					" can_add_existing=", can_add_existing,
					" shed_interact=", shed_offers_storage, " storage_panel_opened=", storage_panel_opened,
					" store_ok=", store_ok, " stored_tomato=", stored_tomato, " bag_tomato=", bag_tomato_after,
					" withdraw_ok=", withdraw_ok, " stored_final=", stored_tomato_final,
					" pest_spawned=", pest_spawned, " pest_act_catch=", pest_action_is_catch,
					" pest_cleared=", pest_cleared, " worm_count=", worm_count,
					" worm_name=", worm_crop_db.get("name", ""),
					" shed_tex=", shed_tex_ok, " caterpillar_tex=", caterpillar_tex_ok)
			# 5. Kiểm thử Mèo Tam Thể làm nông (Cat Helper) + Lều Stardew Valley + Gieo hạt + Tưới + Bắt sâu + Thu hoạch + Cất kho + Ngủ lều
			# A. Asset lều Stardew Valley & Minimap POI
			var tent_tex_ok: bool = (TextureGen.get_tex("tent") != null)
			var poi_tent_exists: bool = false
			for p in MinimapScript.POIS:
				if str(p.get("id", "")) == "tent":
					poi_tent_exists = true
			# B. Chú mèo xuất phát & tương tác cửa nhà
			var cat_exists: bool = is_instance_valid(cat_helper)
			var cat_spr_ok: bool = (TextureGen.cat_char_tex("down", 0) != null and TextureGen.cat_char_tex("side", 0) != null and TextureGen.cat_char_tex("act", 0) != null)
			player.position = cat_helper.position + Vector2(0, 15)
			var near_cat: Dictionary = _nearest_interactable()
			var cat_offers_interact: bool = ("Mèo" in str(near_cat.get("label", "")))
			if near_cat.has("cb") and near_cat.cb is Callable:
				near_cat.cb.call()
			var cat_panel_opened: bool = (cat_panel != null and cat_panel.visible)
			_close_panels()
			# C. Thuê chú mèo
			cat_helper.hire()
			var cat_hired_ok: bool = cat_helper.is_hired
			# D. Giao hạt giống cho mèo
			Inventory.add_seed("wheat", 10)
			var give_seeds_ok: bool = cat_helper.give_seeds("wheat", 5)
			var cat_has_seeds: bool = (int(cat_helper.assigned_seeds.get("wheat", 0)) == 5)
			# E. Gieo hạt (Planting)
			farm.reset_all()
			var plant_tile = farm.tiles[Vector2i(1, 0)]
			plant_tile.till()
			cat_helper._find_next_job()
			var job_plant_ok: bool = (cat_helper.current_job.get("type") == "plant")
			cat_helper._complete_job()
			var tile_planted: bool = (plant_tile.tstate == FarmTileScript.TState.PLANTED and plant_tile.crop_id == "wheat")
			var cat_seeds_decreased: bool = (int(cat_helper.assigned_seeds.get("wheat", 0)) == 4)
			# F. Bắt sâu (Pest catching)
			plant_tile.spawn_pest()
			cat_helper._find_next_job()
			var job_pest_ok: bool = (cat_helper.current_job.get("type") == "pest")
			cat_helper._complete_job()
			var pest_caught: bool = (not plant_tile.has_pest and int(cat_helper.harvest_bag.get("sau_bo", 0)) == 1)
			# G. Tưới nước & Hết nước tự múc ao (Watering & Refill)
			plant_tile.watered = false
			cat_helper.water_level = 1
			cat_helper._find_next_job()
			var job_water_ok: bool = (cat_helper.current_job.get("type") == "water")
			cat_helper._complete_job()
			var tile_watered: bool = plant_tile.watered
			var cat_out_of_water: bool = (cat_helper.water_level == 0)
			# Khi hết nước và cần tưới tiếp
			plant_tile.watered = false
			cat_helper._find_next_job()
			var cat_goes_to_pond: bool = (cat_helper.state == CatHelperScript.State.WALKING_TO_POND)
			# Mô phỏng múc nước đầy
			cat_helper.water_level = cat_helper.water_capacity
			cat_helper.state = CatHelperScript.State.IDLE
			# H. Thu hoạch (Harvesting)
			plant_tile.growth = 100.0
			cat_helper._find_next_job()
			var job_harvest_ok: bool = (cat_helper.current_job.get("type") == "harvest")
			cat_helper._complete_job()
			var cat_bag_has_crop: bool = (int(cat_helper.harvest_bag.get("wheat", 0)) == 1)
			# I. Cất kho (Deposit to Shed)
			cat_helper._deposit_items_to_shed()
			var shed_has_wheat: bool = (Inventory.storage_count("produce", "wheat") >= 1)
			var shed_has_worm: bool = (Inventory.storage_count("produce", "sau_bo") >= 1)
			var cat_bag_empty: bool = cat_helper.harvest_bag.is_empty()
			# J. Trả lương & Đi ngủ trong lều Stardew Valley
			GameState.money = 200
			cat_helper.wage_paid_today = false
			cat_helper._pay_daily_wage()
			var wage_paid_ok: bool = (cat_helper.wage_paid_today and GameState.money == 150)
			# Di chuyển vào lều ngủ
			cat_helper.position = CatHelperScript.TENT_SLEEP_POS
			cat_helper.state = CatHelperScript.State.SLEEPING
			var cat_sleeping_ok: bool = (cat_helper.state == CatHelperScript.State.SLEEPING)

			print("CAT_HELPER_TEST tent_tex=", tent_tex_ok, " poi_tent=", poi_tent_exists,
					" cat_exists=", cat_exists, " cat_spr=", cat_spr_ok,
					" cat_interact=", cat_offers_interact, " panel_open=", cat_panel_opened,
					" cat_hired=", cat_hired_ok, " give_seeds=", give_seeds_ok, " has_seeds=", cat_has_seeds,
					" job_plant=", job_plant_ok, " tile_planted=", tile_planted, " seed_dec=", cat_seeds_decreased,
					" job_pest=", job_pest_ok, " pest_caught=", pest_caught,
					" job_water=", job_water_ok, " tile_watered=", tile_watered, " out_of_water=", cat_out_of_water,
					" goes_to_pond=", cat_goes_to_pond,
					" job_harvest=", job_harvest_ok, " bag_crop=", cat_bag_has_crop,
					" shed_stored=", (shed_has_wheat and shed_has_worm), " bag_cleared=", cat_bag_empty,
					" wage_paid=", wage_paid_ok, " cat_sleeping=", cat_sleeping_ok)

			# 6. Kiểm thử Máng ăn, Máng nước & Chuồng mới từ ảnh người dùng cung cấp
			var new_coop_ok: bool = (TextureGen.get_tex("coop") != null and TextureGen.get_tex("coop").get_width() == 48 and TextureGen.get_tex("coop").get_height() == 48)
			var new_trough_ok: bool = (TextureGen.get_tex("trough") != null and TextureGen.get_tex("trough").get_width() == 22 and TextureGen.get_tex("trough").get_height() == 8)
			var new_water_trough_ok: bool = (TextureGen.get_tex("water_trough") != null and TextureGen.get_tex("water_trough").get_width() == 18 and TextureGen.get_tex("water_trough").get_height() == 8)
			print("NEW_COOP_TROUGH_TEST coop=", new_coop_ok, " trough=", new_trough_ok, " water_trough=", new_water_trough_ok)

			# 7. Kiểm thử các nút tắt cạnh màn hình + Nâng cấp Mèo + Sạp không bán qua đêm
			# A. Thử mở các panel qua nút tắt cạnh màn hình (HUD signals)
			_close_panels()
			hud.open_cat_requested.emit()
			var quick_cat_open: bool = (cat_panel != null and cat_panel.visible)
			_close_panels()
			hud.open_storage_requested.emit()
			var quick_storage_open: bool = (storage_panel != null and storage_panel.visible)
			_close_panels()

			# B. Kiểm thử Nâng cấp chú mèo bằng tiền
			GameState.money = 1000
			var cat_up_spd: bool = cat_helper.upgrade("speed")
			var cat_spd_lvl2: bool = (cat_helper.speed_level == 2 and cat_helper.speed > 60.0)
			var cat_up_work: bool = cat_helper.upgrade("work")
			var cat_work_lvl2: bool = (cat_helper.work_level == 2)
			var cat_up_bag: bool = cat_helper.upgrade("bag")
			var cat_bag_lvl2: bool = (cat_helper.bag_level == 2 and cat_helper.water_capacity > 15)

			var save_dict: Dictionary = cat_helper.get_save_dict()
			var save_upgrades_ok: bool = (int(save_dict.get("speed_level", 0)) == 2 and int(save_dict.get("work_level", 0)) == 2 and int(save_dict.get("bag_level", 0)) == 2)

			# C. Kiểm thử hàng trên sạp không bị bán qua đêm
			stall_slots[0] = {"id": "tomato", "name": "Cà chua", "count": 10, "price": 25}
			_do_sleep(false)
			var overnight_unsold: bool = (int(stall_slots[0].get("count", 0)) == 10)

			print("QUICK_DOCK_CAT_UPGRADE_TEST quick_cat=", quick_cat_open, " quick_storage=", quick_storage_open,
					" up_spd=", (cat_up_spd and cat_spd_lvl2), " up_work=", (cat_up_work and cat_work_lvl2),
					" up_bag=", (cat_up_bag and cat_bag_lvl2), " save_upgrades=", save_upgrades_ok,
					" overnight_unsold=", overnight_unsold)

			# 8. Kiểm thử Đất đen sau thu hoạch + Giao cuốc cho Mèo + Mèo tự cày đất đen
			# A. Đất sau thu hoạch ở trạng thái HARVESTED và có texture đen SDV
			var harvested_state_ok: bool = (plant_tile.tstate == FarmTileScript.TState.HARVESTED)
			var dark_tex_ok: bool = (TextureGen.get_tex("tilled_dark_isolated") != null and TextureGen.get_tex("tilled_dark_mid") != null)
			# B. Người chơi có thể tự cuốc lại đất đen
			var dark_action: Dictionary = farm.action_at(plant_tile)
			var dark_action_ok: bool = (str(dark_action.get("act")) == "till")
			# C. Giao cuốc cho mèo
			Inventory.hoes = 5
			var give_hoe_ok: bool = cat_helper.give_hoes(3)
			var cat_has_hoes: bool = (cat_helper.assigned_hoes == 3 and Inventory.hoes == 2)
			# D. Mèo tự tìm việc cuốc đất đen sau thu hoạch
			cat_helper._find_next_job()
			var job_till_ok: bool = (str(cat_helper.current_job.get("type")) == "till")
			cat_helper._complete_job()
			var tile_tilled_by_cat: bool = (plant_tile.tstate == FarmTileScript.TState.TILLED)
			var cat_hoes_decremented: bool = (cat_helper.assigned_hoes == 2)
			# E. Lấy lại cuốc từ mèo
			var take_hoe_ok: bool = cat_helper.take_back_hoes(1)
			var hoes_retrieved: bool = (cat_helper.assigned_hoes == 1 and Inventory.hoes == 3)
			# F. Lưu/Tải số cuốc của mèo
			var cat_save: Dictionary = cat_helper.get_save_dict()
			var save_hoes_ok: bool = (int(cat_save.get("assigned_hoes", 0)) == 1)

			print("HARVEST_DARK_DIRT_AND_HOE_TEST dark_state=", harvested_state_ok, " dark_tex=", dark_tex_ok,
					" dark_act=", dark_action_ok, " give_hoe=", (give_hoe_ok and cat_has_hoes),
					" job_till=", job_till_ok, " tilled_by_cat=", tile_tilled_by_cat,
					" hoe_dec=", cat_hoes_decremented, " take_hoe=", (take_hoe_ok and hoes_retrieved),
					" save_hoes=", save_hoes_ok)

			# 9. Kiểm thử Hệ thống Thời tiết (Weather System)
			# A. Khởi tạo & hiển thị HUD
			weather_mgr.set_weather(WeatherManagerScript.SUNNY)
			var w_sunny_ok: bool = (GameState.weather == "sunny" and hud.weather_label.text.begins_with("☀️"))
			# B. Chuyển sang Mưa rào & Tự động tưới đất
			plant_tile.tstate = FarmTileScript.TState.PLANTED
			plant_tile.watered = false
			weather_mgr.set_weather(WeatherManagerScript.RAIN)
			weather_mgr._auto_water_farm_crops()
			var w_rain_watered: bool = (plant_tile.watered and hud.weather_label.text.begins_with("🌧️"))
			# C. Chuyển sang Mưa dông & Rơi quặng sấm sét
			weather_mgr.set_weather(WeatherManagerScript.STORM)
			weather_mgr._trigger_lightning_strike()
			var w_storm_ok: bool = (hud.weather_label.text.begins_with("⛈️") and weather_mgr._lightning_alpha > 0.0)
			# D. Chuyển sang Gió lộng & Mưa nhỏ
			weather_mgr.set_weather(WeatherManagerScript.WINDY)
			var w_windy_ok: bool = (hud.weather_label.text.begins_with("🍃") and weather_mgr._leaves.size() > 0)
			weather_mgr.set_weather(WeatherManagerScript.DRIZZLE)
			var w_drizzle_ok: bool = (hud.weather_label.text.begins_with("🌦️") and weather_mgr._rain_drops.size() > 0)

			# E. Lưu & tải thời tiết
			SaveSystem.save_game(farm.get_state(), player.position, _npc_met, mailbox_data, foliage_data, stall_slots, stall_revenue, _cat_save_data())
			var sd_weather: Dictionary = SaveSystem.load_data()
			var w_saved_ok: bool = (str(sd_weather.get("weather", "")) == "drizzle")

			print("WEATHER_SYSTEM_TEST sunny=", w_sunny_ok, " rain_water=", w_rain_watered,
					" storm=", w_storm_ok, " windy=", w_windy_ok, " drizzle=", w_drizzle_ok,
					" saved=", w_saved_ok)

			# 10. Kiểm thử Hệ thống Cho Động Vật Ăn Cám & Thu Hoạch
			var f_icon_ok: bool = (TextureGen.get_feed_icon() != null and TextureGen.get_feed_icon().get_width() > 0)
			var f_bubble_ok: bool = (TextureGen.get_feed_bubble() != null and TextureGen.get_feed_bubble().get_width() > 0)
			var prev_feed_count: int = Inventory.feed_count()
			Inventory.add_feed(5)
			var feed_added_ok: bool = (Inventory.feed_count() == prev_feed_count + 5)
			Inventory.coop_tiers["chicken"] = 1
			Inventory.buy_animal("chicken")
			_rebuild_pen()
			var test_anim: PenAnimal = null
			for pa in active_pen_animals:
				if pa.species_id == "chicken":
					test_anim = pa
					break
			var anim_found: bool = (test_anim != null)
			test_anim._process(0.016)
			var hungry_bubble_ok: bool = (test_anim.bubble_spr.visible and not test_anim.is_fed())
			var feed_before: int = Inventory.feed_count()
			var feed_act_ok: bool = test_anim.feed()
			var feed_decremented: bool = (Inventory.feed_count() == feed_before - 1)
			var walking_to_trough: bool = (test_anim.state == PenAnimal.State.WALK_TO_TROUGH)
			test_anim.position = test_anim.target_pos
			test_anim._process(0.016)
			var eating_at_trough: bool = (test_anim.state == PenAnimal.State.EATING)
			test_anim.eating_timer = 0.0
			test_anim._process(0.016)
			var idle_after_eating: bool = (test_anim.state == PenAnimal.State.IDLE)
			Inventory.tick_animals(25.0)
			test_anim._process(0.016)
			var ready_harvest: bool = (test_anim.state == PenAnimal.State.READY)
			var stands_still: bool = (test_anim.velocity == Vector2.ZERO)
			var harvest_bubble_visible: bool = test_anim.bubble_spr.visible
			var prod_harvested: String = test_anim.harvest()
			var prod_ok: bool = (prod_harvested == "trung_ga")
			test_anim._process(0.016)
			var can_feed_immediately: bool = (not test_anim.is_fed() and test_anim.bubble_spr.visible)
			var feed_again_ok: bool = test_anim.feed()

			print("ANIMAL_FEEDING_HARVEST_TEST icon=", f_icon_ok, " bubble=", f_bubble_ok,
					" feed_inv=", (feed_added_ok and feed_decremented), " anim_found=", anim_found,
					" hungry_bubble=", hungry_bubble_ok, " to_trough=", walking_to_trough,
					" eating=", eating_at_trough, " idle=", idle_after_eating,
					" ready=", ready_harvest, " stands_still=", stands_still,
					" harvest_bubble=", harvest_bubble_visible, " prod=", prod_ok,
					" feed_again=", (can_feed_immediately and feed_again_ok))

			# Test: Đi lại trừ thể lực rất ít & Đập đá trong mỏ trừ thể lực
			GameState.stamina = 100.0
			# 1. Đi lại
			player._is_acting = false
			player.can_move = true
			player._walk_stamina_timer = 0.0
			player.position = Vector2(600, 470)
			Input.action_press("move_right")
			player._physics_process(0.6)
			player._physics_process(0.5)
			Input.action_release("move_right")
			var walk_stamina_ok: bool = (GameState.stamina < 100.0 and GameState.stamina >= 99.8)

			# 2. Đập đá
			Inventory.add_pickaxe("basic")
			var mock_rock_body := StaticBody2D.new()
			var mock_rock_spr := Sprite2D.new()
			mock_rock_body.add_child(mock_rock_spr)
			world.add_child(mock_rock_body)
			var mock_rock: Dictionary = {
				"body": mock_rock_body,
				"spr": mock_rock_spr,
				"type": "stone",
				"hits_left": 2,
				"pos_tile": Vector2i(10, 10)
			}
			var stam_before_hit := GameState.stamina
			mine_manager._hit_rock(mock_rock)
			var hit_stamina_ok: bool = (is_equal_approx(GameState.stamina, stam_before_hit - 5.0))
			var rock_damaged: bool = (int(mock_rock.hits_left) == 1)

			# 3. Kiệt sức không đập được
			GameState.stamina = 1.0
			mine_manager._hit_rock(mock_rock)
			var exhausted_prevented: bool = (int(mock_rock.hits_left) == 1 and is_equal_approx(GameState.stamina, 1.0))
			mock_rock_body.queue_free()

			# 4. Kiểm tra các chi phí thể lực theo yêu cầu
			Inventory.set_hoe_tier("basic")
			Inventory.add_pickaxe("basic")
			var till_cost_ok: bool = is_equal_approx(_get_action_stamina_cost("till"), 7.0)
			var plant_cost_ok: bool = is_equal_approx(_get_action_stamina_cost("plant"), 5.0)
			var water_cost_ok: bool = is_equal_approx(_get_action_stamina_cost("water"), 5.0)
			var fish_cost_ok: bool = is_equal_approx(_get_action_stamina_cost("fish"), 15.0)
			var mine_cost_ok: bool = is_equal_approx(_get_action_stamina_cost("mine"), 5.0)

			# 5. Kiểm tra nâng cấp dụng cụ giảm thể lực
			GameState.money = 10000
			Inventory.add_ore("copper_ore", 10)
			Inventory.add_ore("iron_ore", 10)
			Inventory.add_ore("gold_ore", 10)

			var hoe_up_res := Inventory.upgrade_hoe()
			var hoe_reduced_ok: bool = (hoe_up_res.ok and is_equal_approx(_get_action_stamina_cost("till"), 5.0))

			var pick_up_res := Inventory.upgrade_pickaxe()
			var pick_reduced_ok: bool = (pick_up_res.ok and is_equal_approx(_get_action_stamina_cost("mine"), 4.0))

			# 6. Mở và đóng tool_upgrade_panel
			_open_tool_upgrade_panel()
			var panel_opened: bool = (tool_upgrade_panel != null and tool_upgrade_panel.visible)
			_close_panels()
			var panel_closed: bool = (tool_upgrade_panel != null and not tool_upgrade_panel.visible)

			# 7. Kiểm tra đi ngủ không hồi thể lực mà chỉ để lưu game
			GameState.stamina = 35.0
			GameState.sleep_to_morning(false)
			var sleep_no_heal_ok: bool = is_equal_approx(GameState.stamina, 35.0)
			GameState.sleep_to_morning(true)
			var forced_no_heal_ok: bool = is_equal_approx(GameState.stamina, 35.0)

			print("MINING_AND_WALKING_STAMINA_TEST walk_ok=", walk_stamina_ok,
					" hit_ok=", hit_stamina_ok, " rock_damaged=", rock_damaged,
					" exhausted_prevented=", exhausted_prevented)
			print("ACTION_STAMINA_TEST till_7=", till_cost_ok, " plant_5=", plant_cost_ok,
					" water_5=", water_cost_ok, " fish_15=", fish_cost_ok, " mine_5=", mine_cost_ok)
			print("TOOL_UPGRADE_TEST hoe_up=", hoe_reduced_ok, " pick_up=", pick_reduced_ok,
					" panel_open=", panel_opened, " panel_close=", panel_closed)
			# 8. Kiểm tra hoạt ảnh câu cá, cần câu và gợn sóng nước Stardew Valley
			var ripple_frames_ok := true
			for ri in range(8):
				if TextureGen.water_ripple_frame(ri) == null:
					ripple_frames_ok = false
					break

			var rod_icons_ok: bool = (TextureGen.get_tex("fx_rod") != null
					and TextureGen.get_tex("fx_bobber") != null
					and TextureGen.rod_icon("9aa0a6") != null
					and TextureGen.rod_icon("66bb6a") != null
					and TextureGen.rod_icon("ffd54f") != null)

			var farmer_fish_anim_ok := true
			for d_name in ["down", "side", "up"]:
				for st in range(5):
					if TextureGen.char_action_tex(d_name, "fish", st) == null:
						farmer_fish_anim_ok = false
						break

			# Kiểm tra quy trình thả câu và thu cần
			Inventory.add_rod("basic", 5)
			player.position = FISH_SPOT_POS + Vector2(-50, 0)
			_start_fishing()
			var fishing_started_ok: bool = (fishing and player.is_fishing()
					and is_instance_valid(_bobber_spr) and is_instance_valid(_fishing_line))
			var ripple_spawn_ok: bool = is_instance_valid(_spawn_water_ripple(Vector2(1440, 900), 1.0, 0.5))

			_finish_fishing()
			var fishing_finished_ok: bool = (not fishing and _bobber_spr == null and _fishing_line == null)

			print("SDV_FISHING_RIPPLE_TEST ripples=", ripple_frames_ok, " rods=", rod_icons_ok,
					" farmer_anims=", farmer_fish_anim_ok, " start_cast=", fishing_started_ok,
					" ripple_spawn=", ripple_spawn_ok, " finish_cast=", fishing_finished_ok)

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
