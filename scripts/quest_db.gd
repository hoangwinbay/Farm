extends Node
# Cơ sở dữ liệu nhiệm vụ: Nhiệm vụ Ngày, Nhiệm vụ Tuần và Nhiệm vụ Tổng (Thành tựu).
# Phần thưởng chuẩn theo yêu cầu:
# - Nhiệm vụ Ngày: 100 vàng + 10 nguyên liệu cùng loại
# - Nhiệm vụ Tuần: 500 vàng + 50 nguyên liệu cùng loại
# - Nhiệm vụ Tổng: 50 vàng mỗi nhiệm vụ

const CropDB := preload("res://scripts/crop_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const OreDB := preload("res://scripts/ore_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")

# ----------------- DANH SÁCH MẪU NHIỆM VỤ NGÀY -----------------
const DAILY_QUEST_TEMPLATES := [
	{
		"id_prefix": "d_harvest_rice",
		"title": "Thu hoạch Lúa Nước",
		"desc": "Bác Trưởng Thôn cần lúa tươi để nấu cơm trưa cho làng.",
		"type": "harvest",
		"target_id": "rice",
		"target_name": "Lúa nước",
		"target_count": 4,
		"reward_coins": 100,
		"reward_item_id": "rice",
		"reward_item_type": "crop",
		"reward_item_name": "Lúa nước",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_harvest_tomato",
		"title": "Thu hoạch Cà Chua",
		"desc": "Giao cà chua chín mọng cho bếp ăn tập thể của làng.",
		"type": "harvest",
		"target_id": "tomato",
		"target_name": "Cà chua",
		"target_count": 4,
		"reward_coins": 100,
		"reward_item_id": "tomato",
		"reward_item_type": "crop",
		"reward_item_name": "Cà chua",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_harvest_wheat",
		"title": "Thu hoạch Lúa Mì",
		"desc": "Lúa mì thơm ngon xay bột làm bánh mì cho dân làng.",
		"type": "harvest",
		"target_id": "wheat",
		"target_name": "Lúa mì",
		"target_count": 4,
		"reward_coins": 100,
		"reward_item_id": "wheat",
		"reward_item_type": "crop",
		"reward_item_name": "Lúa mì",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_harvest_carrot",
		"title": "Thu hoạch Cà Rốt",
		"desc": "Cà rốt tươi giòn ngọt bồi dưỡng sức khoẻ cho các bé.",
		"type": "harvest",
		"target_id": "carrot",
		"target_name": "Cà rốt",
		"target_count": 3,
		"reward_coins": 100,
		"reward_item_id": "carrot",
		"reward_item_type": "crop",
		"reward_item_name": "Cà rốt",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_water_crops",
		"title": "Tưới Nước Cho Cây",
		"desc": "Cây cối đang khát nước, hãy tưới đẫm các luống ruộng.",
		"type": "water",
		"target_id": "any",
		"target_name": "Luống cây",
		"target_count": 8,
		"reward_coins": 100,
		"reward_item_id": "rice",
		"reward_item_type": "crop",
		"reward_item_name": "Lúa nước",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_till_soil",
		"title": "Xới Đất Canh Tác",
		"desc": "Dùng cuốc cày xới các ô đất mới chuẩn bị cho vụ mùa.",
		"type": "till",
		"target_id": "any",
		"target_name": "Ô đất",
		"target_count": 6,
		"reward_coins": 100,
		"reward_item_id": "wheat",
		"reward_item_type": "crop",
		"reward_item_name": "Lúa mì",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_catch_fish_chep",
		"title": "Câu Cá Chép Dưới Ao",
		"desc": "Bác Trưởng Thôn thèm món cá chép om dưa trứ danh.",
		"type": "fish",
		"target_id": "chep",
		"target_name": "Cá chép",
		"target_count": 2,
		"reward_coins": 100,
		"reward_item_id": "chep",
		"reward_item_type": "fish",
		"reward_item_name": "Cá chép",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_catch_fish_any",
		"title": "Thả Câu Thư Giãn",
		"desc": "Ra bờ ao buông cần câu bất kỳ loài cá nào.",
		"type": "fish",
		"target_id": "any",
		"target_name": "Con cá",
		"target_count": 2,
		"reward_coins": 100,
		"reward_item_id": "chep",
		"reward_item_type": "fish",
		"reward_item_name": "Cá chép",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_mine_copper",
		"title": "Khai Thác Quặng Đồng",
		"desc": "Khai thác quặng đồng dưới mỏ để rèn đúc nông cụ mới.",
		"type": "mine",
		"target_id": "copper_ore",
		"target_name": "Quặng Đồng",
		"target_count": 3,
		"reward_coins": 100,
		"reward_item_id": "copper_ore",
		"reward_item_type": "ore",
		"reward_item_name": "Quặng Đồng",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_mine_coal",
		"title": "Khai Thác Than Đá",
		"desc": "Đập đá cuội tìm than đá làm nhiên liệu thắp sáng hầm mỏ.",
		"type": "mine",
		"target_id": "coal",
		"target_name": "Than đá",
		"target_count": 3,
		"reward_coins": 100,
		"reward_item_id": "coal",
		"reward_item_type": "ore",
		"reward_item_name": "Than đá",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_collect_eggs",
		"title": "Thu Hoạch Trứng Gà",
		"desc": "Ghé chuồng gia cầm thu hoạch những quả trứng tươi mới.",
		"type": "poultry",
		"target_id": "trung_ga",
		"target_name": "Trứng gà",
		"target_count": 3,
		"reward_coins": 100,
		"reward_item_id": "trung_ga",
		"reward_item_type": "produce",
		"reward_item_name": "Trứng gà",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_sell_stall",
		"title": "Bán Hàng Tại Sạp",
		"desc": "Bày nông sản lên quầy và bán cho các vị khách ghé thăm.",
		"type": "stall_sell",
		"target_id": "any",
		"target_name": "Món đồ",
		"target_count": 2,
		"reward_coins": 100,
		"reward_item_id": "tomato",
		"reward_item_type": "crop",
		"reward_item_name": "Cà chua",
		"reward_item_count": 10
	},
	{
		"id_prefix": "d_catch_pest",
		"title": "Bắt Sâu Bọ Phá Hoại",
		"desc": "Tìm và bắt những con sâu róm cắn phá hoa màu trên ruộng.",
		"type": "catch_pest",
		"target_id": "any",
		"target_name": "Sâu bọ",
		"target_count": 1,
		"reward_coins": 100,
		"reward_item_id": "sau_bo",
		"reward_item_type": "produce",
		"reward_item_name": "Sâu bọ",
		"reward_item_count": 10
	}
]

# ----------------- DANH SÁCH MẪU NHIỆM VỤ TUẦN -----------------
const WEEKLY_QUEST_TEMPLATES := [
	{
		"id_prefix": "w_harvest_bulk_crops",
		"title": "Vụ Mùa Bội Thu Tuần",
		"desc": "Thu hoạch số lượng lớn lúa nước phục vụ kho lương thực dự trữ của làng.",
		"type": "harvest",
		"target_id": "rice",
		"target_name": "Lúa nước",
		"target_count": 25,
		"reward_coins": 500,
		"reward_item_id": "rice",
		"reward_item_type": "crop",
		"reward_item_name": "Lúa nước",
		"reward_item_count": 50
	},
	{
		"id_prefix": "w_harvest_bulk_tomatoes",
		"title": "Nông Trại Cà Chua Trù Phú",
		"desc": "Cung cấp cà chua xuất khẩu sang thị trấn lân cận.",
		"type": "harvest",
		"target_id": "tomato",
		"target_name": "Cà chua",
		"target_count": 20,
		"reward_coins": 500,
		"reward_item_id": "tomato",
		"reward_item_type": "crop",
		"reward_item_name": "Cà chua",
		"reward_item_count": 50
	},
	{
		"id_prefix": "w_harvest_bulk_wheat",
		"title": "Đại Mùa Lúa Mì Vàng",
		"desc": "Cung cấp lúa mì cho xưởng bánh mì trung tâm thị trấn.",
		"type": "harvest",
		"target_id": "wheat",
		"target_name": "Lúa mì",
		"target_count": 20,
		"reward_coins": 500,
		"reward_item_id": "wheat",
		"reward_item_type": "crop",
		"reward_item_name": "Lúa mì",
		"reward_item_count": 50
	},
	{
		"id_prefix": "w_mine_deep_iron",
		"title": "Chiến Dịch Khai Mỏ Sắt",
		"desc": "Xuống các tầng sâu hầm mỏ khai thác quặng sắt kiên cố.",
		"type": "mine",
		"target_id": "iron_ore",
		"target_name": "Quặng Sắt",
		"target_count": 15,
		"reward_coins": 500,
		"reward_item_id": "iron_ore",
		"reward_item_type": "ore",
		"reward_item_name": "Quặng Sắt",
		"reward_item_count": 50
	},
	{
		"id_prefix": "w_mine_copper_bulk",
		"title": "Tổng Kho Đồng Làng",
		"desc": "Khai thác lượng lớn quặng đồng nâng cấp hạ tầng làng quê.",
		"type": "mine",
		"target_id": "copper_ore",
		"target_name": "Quặng Đồng",
		"target_count": 20,
		"reward_coins": 500,
		"reward_item_id": "copper_ore",
		"reward_item_type": "ore",
		"reward_item_name": "Quặng Đồng",
		"reward_item_count": 50
	},
	{
		"id_prefix": "w_poultry_eggs_bulk",
		"title": "Trang Trại Trứng Gia Cầm",
		"desc": "Thu hoạch lượng trứng gà dồi dào cung cấp cho chợ quê.",
		"type": "poultry",
		"target_id": "trung_ga",
		"target_name": "Trứng gà",
		"target_count": 18,
		"reward_coins": 500,
		"reward_item_id": "trung_ga",
		"reward_item_type": "produce",
		"reward_item_name": "Trứng gà",
		"reward_item_count": 50
	},
	{
		"id_prefix": "w_stall_sales_master",
		"title": "Đại Doanh Thương Sạp Hàng",
		"desc": "Phục vụ đông đảo các lượt khách ghé sạp nông sản trong tuần.",
		"type": "stall_sell",
		"target_id": "any",
		"target_name": "Lượt bán",
		"target_count": 15,
		"reward_coins": 500,
		"reward_item_id": "corn",
		"reward_item_type": "crop",
		"reward_item_name": "Bắp ngô",
		"reward_item_count": 50
	},
	{
		"id_prefix": "w_catch_fish_bulk",
		"title": "Tay Câu Thượng Hạng",
		"desc": "Thả câu và đánh bắt các mẻ cá tươi ngon dưới lòng ao làng.",
		"type": "fish",
		"target_id": "any",
		"target_name": "Con cá",
		"target_count": 10,
		"reward_coins": 500,
		"reward_item_id": "chep",
		"reward_item_type": "fish",
		"reward_item_name": "Cá chép",
		"reward_item_count": 50
	}
]

# ----------------- DANH SÁCH NHIỆM VỤ TỔNG (THÀNH TỰU TRỌN ĐỜI) -----------------
# Mỗi nhiệm vụ hoàn thành cho 50 vàng
const LIFETIME_QUESTS := [
	{
		"id": "lt_first_harvest",
		"title": "🌱 Bước Khởi Nghiệp",
		"desc": "Thu hoạch vụ mùa cây trồng đầu tiên trên nông trại của bạn.",
		"type": "harvest",
		"target_id": "any",
		"target_name": "Cây trồng",
		"target_count": 1,
		"reward_coins": 50
	},
	{
		"id": "lt_harvest_100",
		"title": "🌾 Nông Dân Chăm Chỉ",
		"desc": "Thu hoạch tổng cộng 100 cây trồng các loại.",
		"type": "harvest",
		"target_id": "any",
		"target_name": "Cây trồng",
		"target_count": 100,
		"reward_coins": 50
	},
	{
		"id": "lt_till_50",
		"title": "⛏️ Mở Rộng Ruộng Đồng",
		"desc": "Cày xới 50 ô đất canh tác trên cánh đồng.",
		"type": "till",
		"target_id": "any",
		"target_name": "Ô đất",
		"target_count": 50,
		"reward_coins": 50
	},
	{
		"id": "lt_water_100",
		"title": "💧 Thợ Tưới Nước Cần Mẫn",
		"desc": "Tưới nước 100 lần cho hoa màu.",
		"type": "water",
		"target_id": "any",
		"target_name": "Lần tưới",
		"target_count": 100,
		"reward_coins": 50
	},
	{
		"id": "lt_fish_first",
		"title": "🎣 Phát Súng Thả Câu",
		"desc": "Câu thành công con cá đầu tiên dưới ao làng.",
		"type": "fish",
		"target_id": "any",
		"target_name": "Con cá",
		"target_count": 1,
		"reward_coins": 50
	},
	{
		"id": "lt_fish_25",
		"title": "🐟 Ngư Phủ Lành Nghề",
		"desc": "Câu được tổng cộng 25 con cá dưới ao.",
		"type": "fish",
		"target_id": "any",
		"target_name": "Con cá",
		"target_count": 25,
		"reward_coins": 50
	},
	{
		"id": "lt_mine_first",
		"title": "⛏️ Thăm Dò Hầm Mỏ",
		"desc": "Đập khối quặng đầu tiên dưới hầm mỏ đá Tây Bắc.",
		"type": "mine",
		"target_id": "any",
		"target_name": "Khối quặng",
		"target_count": 1,
		"reward_coins": 50
	},
	{
		"id": "lt_mine_50",
		"title": "💎 Thợ Mỏ Cừ Khôi",
		"desc": "Khai thác 50 khối quặng và đá quý dưới mỏ.",
		"type": "mine",
		"target_id": "any",
		"target_name": "Khối quặng",
		"target_count": 50,
		"reward_coins": 50
	},
	{
		"id": "lt_mine_gold",
		"title": "✨ Cơn Sốt Quặng Vàng",
		"desc": "Tìm và khai thác thành công Quặng Vàng quý giá.",
		"type": "mine",
		"target_id": "gold_ore",
		"target_name": "Quặng Vàng",
		"target_count": 5,
		"reward_coins": 50
	},
	{
		"id": "lt_stall_sales_20",
		"title": "🏪 Thương Gia Thân Thiện",
		"desc": "Bán được 20 món nông sản tại sạp hàng cho dân làng.",
		"type": "stall_sell",
		"target_id": "any",
		"target_name": "Món đồ",
		"target_count": 20,
		"reward_coins": 50
	},
	{
		"id": "lt_poultry_collect_20",
		"title": "🥚 Chuồng Trại Ấm Êm",
		"desc": "Thu hoạch 20 sản phẩm trứng/thịt/lông từ gia cầm.",
		"type": "poultry",
		"target_id": "any",
		"target_name": "Sản phẩm",
		"target_count": 20,
		"reward_coins": 50
	},
	{
		"id": "lt_pests_caught_10",
		"title": "🐛 Dũng Sĩ Diệt Sâu",
		"desc": "Bắt thành công 10 con sâu bọ bảo vệ ruộng đồng.",
		"type": "catch_pest",
		"target_id": "any",
		"target_name": "Sâu bọ",
		"target_count": 10,
		"reward_coins": 50
	},
	{
		"id": "lt_wealth_1000",
		"title": "💰 Tích Tiểu Thành Đại",
		"desc": "Tích lũy được tổng cộng 1.000 xu trong tài khoản.",
		"type": "money_earn",
		"target_id": "any",
		"target_name": "Xu vàng",
		"target_count": 1000,
		"reward_coins": 50
	},
	{
		"id": "lt_wealth_5000",
		"title": "👑 Triệu Phú Làng Quê",
		"desc": "Đạt mốc 5.000 xu tài sản trong game.",
		"type": "money_earn",
		"target_id": "any",
		"target_name": "Xu vàng",
		"target_count": 5000,
		"reward_coins": 50
	}
]


# Tạo ngẫu nhiên 3 nhiệm vụ ngày cho ngày hiện tại
static func generate_daily_quests(day: int) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var pool := DAILY_QUEST_TEMPLATES.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260000 + day * 37

	# Xáo trộn ngẫu nhiên
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp

	for i in mini(3, pool.size()):
		var tmpl: Dictionary = pool[i].duplicate(true)
		tmpl["id"] = "%s_d%d" % [tmpl["id_prefix"], day]
		tmpl["progress"] = 0
		tmpl["completed"] = false
		tmpl["claimed"] = false
		list.append(tmpl)

	return list


# Tạo ngẫu nhiên 3 nhiệm vụ tuần cho tuần hiện tại
static func generate_weekly_quests(week_idx: int) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var pool := WEEKLY_QUEST_TEMPLATES.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = 99990000 + week_idx * 53

	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp

	for i in mini(3, pool.size()):
		var tmpl: Dictionary = pool[i].duplicate(true)
		tmpl["id"] = "%s_w%d" % [tmpl["id_prefix"], week_idx]
		tmpl["progress"] = 0
		tmpl["completed"] = false
		tmpl["claimed"] = false
		list.append(tmpl)

	return list


# Khởi tạo danh sách nhiệm vụ tổng
static func init_lifetime_quests() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for tmpl in LIFETIME_QUESTS:
		var q: Dictionary = tmpl.duplicate(true)
		q["progress"] = 0
		q["completed"] = false
		q["claimed"] = false
		list.append(q)
	return list
