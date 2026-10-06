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
		"interval": 60.0,
		"product_price": 35,
		"texture_adult": "res://Content (unpacked)/Animals/White Chicken.png",
		"texture_baby": "res://Content (unpacked)/Animals/BabyWhite Chicken.png",
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
		"texture_adult": "res://Content (unpacked)/Animals/White Cow.png",
		"texture_baby": "res://Content (unpacked)/Animals/BabyWhite Cow.png",
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
		"product": "thit_lon",
		"product_name": "Thịt lợn",
		"product_color": "e06d6d",
		"interval": 80.0,
		"product_price": 55,
		"texture_adult": "res://Content (unpacked)/Animals/Pig.png",
		"texture_baby": "res://Content (unpacked)/Animals/BabyPig.png",
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
		"interval": 100.0,
		"product_price": 65,
		"texture_adult": "res://Content (unpacked)/Animals/Sheep.png",
		"texture_sheared": "res://Content (unpacked)/Animals/ShearedSheep.png",
		"texture_baby": "res://Content (unpacked)/Animals/BabySheep.png",
		"frame_size": Vector2i(32, 32),
		"baby_frame_size": Vector2i(32, 32),
		"hframes": 4,
		"vframes": 5,
		"baby_vframes": 5,
	},
]

const COOP_DATA := {
	"chicken": {
		"id": "chicken",
		"name": "Chuồng Gà",
		"animal_id": "chicken",
		"animal_name": "Gà trắng",
		"tier1_price": 200,
		"tier2_price": 350,
		"tier1_cap": 2,
		"tier2_cap": 4,
		"desc_t0": "Khu đất rào gỗ với nền đất. Mua chuồng Cấp 1 để nuôi được 2 con gà!",
		"desc_t1": "Chuồng Cấp 1 (sức chứa 2 con). Nâng cấp Cấp 2 để mở rộng 4 con và đủ chỗ cho gà con sinh sản!",
		"desc_t2": "Chuồng Cấp 2 (Tối đa, sức chứa 4 con). Đủ chỗ cho cặp gà lớn và đàn gà con!",
	},
	"cow": {
		"id": "cow",
		"name": "Chuồng Bò",
		"animal_id": "cow",
		"animal_name": "Bò trắng",
		"tier1_price": 500,
		"tier2_price": 700,
		"tier1_cap": 2,
		"tier2_cap": 4,
		"desc_t0": "Khu đất rào gỗ với nền đất. Mua chuồng Cấp 1 để nuôi được 2 con bò sữa!",
		"desc_t1": "Chuồng Cấp 1 (sức chứa 2 con). Nâng cấp Cấp 2 để mở rộng 4 con và đủ chỗ cho bê con sinh sản!",
		"desc_t2": "Chuồng Cấp 2 (Tối đa, sức chứa 4 con). Đủ chỗ cho cặp bò sữa và đàn bê con!",
	},
	"pig": {
		"id": "pig",
		"name": "Chuồng Lợn",
		"animal_id": "pig",
		"animal_name": "Lợn",
		"tier1_price": 400,
		"tier2_price": 600,
		"tier1_cap": 2,
		"tier2_cap": 4,
		"desc_t0": "Khu đất rào gỗ với nền đất. Mua chuồng Cấp 1 để nuôi được 2 con lợn!",
		"desc_t1": "Chuồng Cấp 1 (sức chứa 2 con). Nâng cấp Cấp 2 để mở rộng 4 con và đủ chỗ cho lợn con sinh sản!",
		"desc_t2": "Chuồng Cấp 2 (Tối đa, sức chứa 4 con). Đủ chỗ cho cặp lợn và đàn lợn con!",
	},
	"sheep": {
		"id": "sheep",
		"name": "Chuồng Cừu",
		"animal_id": "sheep",
		"animal_name": "Cừu",
		"tier1_price": 450,
		"tier2_price": 650,
		"tier1_cap": 2,
		"tier2_cap": 4,
		"desc_t0": "Khu đất rào gỗ với nền đất. Mua chuồng Cấp 1 để nuôi được 2 con cừu lấy lông!",
		"desc_t1": "Chuồng Cấp 1 (sức chứa 2 con). Nâng cấp Cấp 2 để mở rộng 4 con và đủ chỗ cho cừu con sinh sản!",
		"desc_t2": "Chuồng Cấp 2 (Tối đa, sức chứa 4 con). Đủ chỗ cho cặp cừu và đàn cừu non!",
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


static func get_product_info(prod_id: String) -> Dictionary:
	for a in ANIMALS:
		if str(a.product) == prod_id:
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
	if prod_id == "thit_ga":
		return {
			"id": "thit_ga",
			"name": "Thịt gà",
			"color": "d98a4a",
			"price": 45,
			"animal_id": "chicken",
			"animal_name": "Gà trắng",
			"is_meat": true,
			"is_edible": true,
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
