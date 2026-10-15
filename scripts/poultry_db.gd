extends RefCounted
# Dữ liệu chăn nuôi: chuồng, vật nuôi (gà, bò, lợn, cừu), sản phẩm & sinh sản.

const ANIMALS := [
	{
		"id": "chicken",
		"name": "Gà trắng",
		"size": "small",
		"price": 150,
		"color": "e8e6e0",
		"shape": "chicken",
		"product": "trung_ga",
		"product_name": "Trứng gà",
		"product_color": "f2e3b6",
		"interval": 90.0,
		"product_price": 35,
		"texture_adult": "res://picture/animals/White Chicken.png",
		"texture_baby": "res://picture/animals/BabyWhite Chicken.png",
		"frame_size": Vector2i(16, 16),
		"baby_frame_size": Vector2i(16, 16),
		"hframes": 4,
		"vframes": 7,
		"baby_vframes": 14,
	},
	{
		"id": "cow",
		"name": "Bò trắng",
		"size": "large",
		"price": 600,
		"color": "f4f4f4",
		"shape": "cow",
		"product": "sua_bo",
		"product_name": "Sữa bò",
		"product_color": "f5f5f5",
		"interval": 90.0,
		"product_price": 70,
		"texture_adult": "res://picture/animals/White Cow.png",
		"texture_baby": "res://picture/animals/BabyWhite Cow.png",
		"frame_size": Vector2i(32, 32),
		"baby_frame_size": Vector2i(32, 32),
		"hframes": 4,
		"vframes": 5,
		"baby_vframes": 5,
	},
	{
		"id": "pig",
		"name": "Lợn",
		"size": "large",
		"price": 450,
		"color": "f5a0a0",
		"shape": "pig",
		"product": "", # không có sản phẩm định kỳ khi ăn
		"product_name": "",
		"product_color": "e06d6d",
		"interval": 90.0,
		"product_price": 0,
		"texture_adult": "res://picture/animals/Pig.png",
		"texture_baby": "res://picture/animals/BabyPig.png",
		"frame_size": Vector2i(32, 32),
		"baby_frame_size": Vector2i(32, 32),
		"hframes": 4,
		"vframes": 5,
		"baby_vframes": 5,
	},
	{
		"id": "sheep",
		"name": "Cừu",
		"size": "large",
		"price": 500,
		"color": "f0f0ea",
		"shape": "sheep",
		"product": "long_cuu",
		"product_name": "Lông cừu",
		"product_color": "e8e8f0",
		"interval": 90.0,
		"product_price": 65,
		"texture_adult": "res://picture/animals/Sheep.png",
		"texture_sheared": "res://picture/animals/ShearedSheep.png",
		"texture_baby": "res://picture/animals/BabySheep.png",
		"frame_size": Vector2i(32, 32),
		"baby_frame_size": Vector2i(32, 32),
		"hframes": 4,
		"vframes": 5,
		"baby_vframes": 5,
	},
]

const FEED_PRICE := 15
const FEED_DATA := {
	"id": "feed",
	"name": "Túi Cám",
	"price": 15,
	"desc": "Cám dinh dưỡng cho vật nuôi chuồng. Cho ăn để vật nuôi no bụng và cho sản phẩm thu hoạch!",
}

const COOP_DATA := {
	"chicken": {
		"id": "chicken",
		"name": "Chuồng Gà",
		"animal_id": "chicken",
		"animal_name": "Gà trắng",
		"tier1_price": 200,
		"tier2_price": 350,
		"tier3_price": 600,
		"tier4_price": 1000,
		"tier1_cap": 2,
		"tier2_cap": 4,
		"tier3_cap": 8,
		"tier4_cap": 16,
		"desc_t0": "Khu đất rào gỗ với nền đất. Mua chuồng Cấp 1 để nuôi được 2 con gà!",
		"desc_t1": "Chuồng Cấp 1 (sức chứa 2 con). Nâng cấp Cấp 2 để mở rộng 4 con và đủ chỗ cho gà con sinh sản!",
		"desc_t2": "Chuồng Cấp 2 (sức chứa 4 con). Nâng cấp Cấp 3 để mở rộng 8 con!",
		"desc_t3": "Chuồng Cấp 3 (sức chứa 8 con). Nâng cấp Cấp 4 (Max) để mở rộng 16 con!",
		"desc_t4": "Chuồng Cấp 4 (Tối đa, sức chứa 16 con). Trang trại nuôi gà quy mô lớn nhất!",
	},
	"cow": {
		"id": "cow",
		"name": "Chuồng Bò",
		"animal_id": "cow",
		"animal_name": "Bò trắng",
		"tier1_price": 500,
		"tier2_price": 750,
		"tier3_price": 1200,
		"tier4_price": 2000,
		"tier1_cap": 2,
		"tier2_cap": 4,
		"tier3_cap": 8,
		"tier4_cap": 16,
		"desc_t0": "Khu đất rào gỗ với nền đất. Mua chuồng Cấp 1 để nuôi được 2 con bò sữa!",
		"desc_t1": "Chuồng Cấp 1 (sức chứa 2 con). Nâng cấp Cấp 2 để mở rộng 4 con và đủ chỗ cho bê con sinh sản!",
		"desc_t2": "Chuồng Cấp 2 (sức chứa 4 con). Nâng cấp Cấp 3 để mở rộng 8 con!",
		"desc_t3": "Chuồng Cấp 3 (sức chứa 8 con). Nâng cấp Cấp 4 (Max) để mở rộng 16 con!",
		"desc_t4": "Chuồng Cấp 4 (Tối đa, sức chứa 16 con). Trang trại nuôi bò quy mô lớn nhất!",
	},
	"pig": {
		"id": "pig",
		"name": "Chuồng Lợn",
		"animal_id": "pig",
		"animal_name": "Lợn",
		"tier1_price": 400,
		"tier2_price": 650,
		"tier3_price": 1000,
		"tier4_price": 1600,
		"tier1_cap": 2,
		"tier2_cap": 4,
		"tier3_cap": 8,
		"tier4_cap": 16,
		"desc_t0": "Khu đất rào gỗ với nền đất. Mua chuồng Cấp 1 để nuôi được 2 con lợn!",
		"desc_t1": "Chuồng Cấp 1 (sức chứa 2 con). Nâng cấp Cấp 2 để mở rộng 4 con và đủ chỗ cho lợn con sinh sản!",
		"desc_t2": "Chuồng Cấp 2 (sức chứa 4 con). Nâng cấp Cấp 3 để mở rộng 8 con!",
		"desc_t3": "Chuồng Cấp 3 (sức chứa 8 con). Nâng cấp Cấp 4 (Max) để mở rộng 16 con!",
		"desc_t4": "Chuồng Cấp 4 (Tối đa, sức chứa 16 con). Trang trại nuôi lợn quy mô lớn nhất!",
	},
	"sheep": {
		"id": "sheep",
		"name": "Chuồng Cừu",
		"animal_id": "sheep",
		"animal_name": "Cừu",
		"tier1_price": 450,
		"tier2_price": 700,
		"tier3_price": 1100,
		"tier4_price": 1800,
		"tier1_cap": 2,
		"tier2_cap": 4,
		"tier3_cap": 8,
		"tier4_cap": 16,
		"desc_t0": "Khu đất rào gỗ với nền đất. Mua chuồng Cấp 1 để nuôi được 2 con cừu lấy lông!",
		"desc_t1": "Chuồng Cấp 1 (sức chứa 2 con). Nâng cấp Cấp 2 để mở rộng 4 con và đủ chỗ cho cừu con sinh sản!",
		"desc_t2": "Chuồng Cấp 2 (sức chứa 4 con). Nâng cấp Cấp 3 để mở rộng 8 con!",
		"desc_t3": "Chuồng Cấp 3 (sức chứa 8 con). Nâng cấp Cấp 4 (Max) để mở rộng 16 con!",
		"desc_t4": "Chuồng Cấp 4 (Tối đa, sức chứa 16 con). Trang trại nuôi cừu quy mô lớn nhất!",
	},
}

const COOPS := [
	{
		"id": "chicken",
		"name": "Chuồng Gà",
		"price": 200,
		"capacity": 2,
		"desc": "Khu đất rào gỗ. Mua chuồng để bắt đầu nuôi gà!",
	},
	{
		"id": "cow",
		"name": "Chuồng Bò",
		"price": 500,
		"capacity": 2,
		"desc": "Khu đất rào gỗ. Mua chuồng để bắt đầu nuôi bò!",
	},
	{
		"id": "pig",
		"name": "Chuồng Lợn",
		"price": 400,
		"capacity": 2,
		"desc": "Khu đất rào gỗ. Mua chuồng để bắt đầu nuôi lợn!",
	},
	{
		"id": "sheep",
		"name": "Chuồng Cừu",
		"price": 450,
		"capacity": 2,
		"desc": "Khu đất rào gỗ. Mua chuồng để bắt đầu nuôi cừu!",
	},
]

const READY_CAP := 3
const BREED_TIME := 60.0
const GROW_TIME := 60.0

const ALIASES := {
	"ga": "chicken",
	"ga_de": "chicken",
	"ga_thit": "chicken",
	"ga_vuon": "chicken",
	"chicken": "chicken",
	"bo": "cow",
	"bo_trang": "cow",
	"cow": "cow",
	"lon": "pig",
	"heo": "pig",
	"pig": "pig",
	"cuu": "sheep",
	"sheep": "sheep",
	"vit_thit": "chicken",
	"vit_de": "chicken",
	"ngan": "chicken",
	"ngong": "sheep",
	"cut": "chicken",
	"bocau": "chicken",
	"tri": "chicken",
	"da_dieu": "cow",
}


static func get_canonical_id(id: String) -> String:
	var low := id.to_lower().strip_edges()
	if ALIASES.has(low):
		return ALIASES[low]
	for a in ANIMALS:
		if a.id == low:
			return a.id
	return low


static func get_animal(id: String) -> Dictionary:
	var canon := get_canonical_id(id)
	for a in ANIMALS:
		if a.id == canon:
			return a
	return {}


static func get_coop_data(species_id: String) -> Dictionary:
	var sid := get_canonical_id(species_id)
	if COOP_DATA.has(sid):
		return COOP_DATA[sid]
	return {}


static func get_coop_capacity(species_id: String, tier: int) -> int:
	match tier:
		1: return 2
		2: return 4
		3: return 8
		4: return 16
		_: return 16 if tier > 4 else 0


static func get_coop_upgrade_price(species_id: String, target_tier: int) -> int:
	var c := get_coop_data(species_id)
	if c.is_empty():
		return 0
	match target_tier:
		1: return int(c.get("tier1_price", 200))
		2: return int(c.get("tier2_price", 350))
		3: return int(c.get("tier3_price", 600))
		4: return int(c.get("tier4_price", 1000))
		_: return 0


static func get_coop(id: String) -> Dictionary:
	var canon := get_canonical_id(id)
	for c in COOPS:
		if c.id == canon or c.id == id:
			return c
	if COOP_DATA.has(canon):
		var cd: Dictionary = COOP_DATA[canon]
		return {
			"id": canon,
			"name": str(cd.name),
			"price": int(cd.tier1_price),
			"capacity": int(cd.tier1_cap),
			"desc": str(cd.desc_t1),
		}
	return {}


const PRODUCTS := [
	{
		"id": "trung_ga",
		"name": "Trứng gà",
		"color": "f2e3b6",
		"price": 35,
		"animal_id": "chicken",
		"animal_name": "Gà trắng",
		"is_meat": false,
		"is_edible": true,
		"desc": "Trứng gà tươi thu hoạch từ chuồng gà.",
	},
	{
		"id": "sua_bo",
		"name": "Sữa bò",
		"color": "f5f5f5",
		"price": 70,
		"animal_id": "cow",
		"animal_name": "Bò trắng",
		"is_meat": false,
		"is_edible": true,
		"desc": "Bình sữa tươi thơm ngon từ bò trắng.",
	},
	{
		"id": "long_cuu",
		"name": "Lông cừu",
		"color": "e8e8f0",
		"price": 65,
		"animal_id": "sheep",
		"animal_name": "Cừu",
		"is_meat": false,
		"is_edible": false,
		"desc": "Lông cừu mềm mại dùng làm len dệt vải.",
	},
	{
		"id": "thit_ga",
		"name": "Thịt gà",
		"color": "d98a4a",
		"price": 35,
		"animal_id": "chicken",
		"animal_name": "Gà trắng",
		"is_meat": true,
		"is_edible": true,
		"desc": "Thịt gà tươi ngon thu được khi chém gà đủ 5 lần ăn.",
	},
	{
		"id": "thit_bo",
		"name": "Thịt bò",
		"color": "b83a3a",
		"price": 65,
		"animal_id": "cow",
		"animal_name": "Bò trắng",
		"is_meat": true,
		"is_edible": true,
		"desc": "Thịt bò hảo hạng thu được khi chém bò đủ 5 lần ăn.",
	},
	{
		"id": "thit_lon",
		"name": "Thịt lợn",
		"color": "e06d6d",
		"price": 60,
		"animal_id": "pig",
		"animal_name": "Lợn",
		"is_meat": true,
		"is_edible": true,
		"desc": "Thịt lợn tươi ngon thu được khi chém lợn đủ 5 lần ăn.",
	},
	{
		"id": "thit_cuu",
		"name": "Thịt cừu",
		"color": "d46666",
		"price": 45,
		"animal_id": "sheep",
		"animal_name": "Cừu",
		"is_meat": true,
		"is_edible": true,
		"desc": "Thịt cừu mềm thơm thu được khi chém cừu đủ 5 lần ăn.",
	},
]


static func get_animal_meat_id(species_id: String) -> String:
	var sid := get_canonical_id(species_id)
	match sid:
		"chicken": return "thit_ga"
		"cow": return "thit_bo"
		"pig": return "thit_lon"
		"sheep": return "thit_cuu"
		_: return "thit_ga"


static func get_animal_meat_qty(species_id: String) -> int:
	var sid := get_canonical_id(species_id)
	match sid:
		"chicken": return 6
		"cow": return 12
		"pig": return 10
		"sheep": return 8
		_: return 6


static func get_product_info(prod_id: String) -> Dictionary:
	for p in PRODUCTS:
		if str(p.id) == prod_id:
			return p
	for a in ANIMALS:
		if str(a.product) == prod_id and prod_id != "":
			return {
				"id": prod_id,
				"name": str(a.product_name),
				"color": str(a.product_color),
				"price": int(a.product_price),
				"animal_id": str(a.id),
				"animal_name": str(a.name),
				"is_meat": is_meat(prod_id),
				"is_edible": is_edible(prod_id),
			}
	return {}


static func is_meat(prod_id: String) -> bool:
	return prod_id.begins_with("thit_")


static func is_edible(prod_id: String) -> bool:
	return is_meat(prod_id) or prod_id.begins_with("trung_") or prod_id == "sua_bo"


static func get_texture_path(species_id: String, is_baby: bool = false, is_sheared: bool = false) -> String:
	var a := get_animal(species_id)
	if a.is_empty():
		return ""
	if is_baby:
		return str(a.get("texture_baby", ""))
	if is_sheared and a.has("texture_sheared"):
		return str(a.get("texture_sheared", ""))
	return str(a.get("texture_adult", ""))
