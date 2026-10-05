extends RefCounted
# Dữ liệu chăn nuôi: chuồng, gia cầm, sản phẩm.

const ANIMALS := [
	# ---- Gà ----
	{"id": "ga_thit", "name": "Gà thịt", "size": "small", "price": 80, "color": "b5651d", "shape": "chicken",
		"product": "thit_ga", "product_name": "Thịt gà", "product_color": "d98a4a",
		"interval": 150, "product_price": 45},
	{"id": "ga_de", "name": "Gà đẻ trứng", "size": "small", "price": 120, "color": "e8e6e0", "shape": "chicken",
		"product": "trung_ga", "product_name": "Trứng gà", "product_color": "f2e3b6",
		"interval": 90, "product_price": 25},
	{"id": "ga_vuon", "name": "Gà thả vườn", "size": "small", "price": 200, "color": "c9a227", "shape": "chicken",
		"product": "trung_vuon", "product_name": "Trứng gà vườn", "product_color": "eecf8a",
		"interval": 120, "product_price": 45},
	# ---- Vịt / Ngan ----
	{"id": "vit_thit", "name": "Vịt thịt", "size": "small", "price": 150, "color": "d8d8d0", "shape": "duck",
		"product": "thit_vit", "product_name": "Thịt vịt", "product_color": "d8b06a",
		"interval": 240, "product_price": 80},
	{"id": "vit_de", "name": "Vịt đẻ trứng", "size": "small", "price": 200, "color": "e6d690", "shape": "duck",
		"product": "trung_vit", "product_name": "Trứng vịt", "product_color": "f0e2a0",
		"interval": 150, "product_price": 45},
	{"id": "ngan", "name": "Ngan (Vịt xiêm)", "size": "small", "price": 300, "color": "4a4a48", "shape": "duck",
		"product": "thit_ngan", "product_name": "Thịt ngan", "product_color": "c96f4a",
		"interval": 300, "product_price": 130},
	# ---- Ngỗng ----
	{"id": "ngong", "name": "Ngỗng", "size": "large", "price": 400, "color": "f0f0ea", "shape": "duck",
		"product": "long_ngong", "product_name": "Lông ngỗng", "product_color": "e8e8f0",
		"interval": 300, "product_price": 150},
	# ---- Cút / Bồ câu ----
	{"id": "cut", "name": "Chim cút", "size": "small", "price": 250, "color": "8d7b64", "shape": "chicken",
		"product": "trung_cut", "product_name": "Trứng cút", "product_color": "d9c49a",
		"interval": 120, "product_price": 30},
	{"id": "bocau", "name": "Bồ câu", "size": "small", "price": 350, "color": "9aa7b0", "shape": "chicken",
		"product": "thit_bocau", "product_name": "Bồ câu thịt", "product_color": "b0a0b8",
		"interval": 300, "product_price": 110},
	# ---- Trĩ / Đà điểu ----
	{"id": "tri", "name": "Chim trĩ", "size": "large", "price": 600, "color": "8b6f47", "shape": "big",
		"product": "long_tri", "product_name": "Lông trĩ", "product_color": "c98f4e",
		"interval": 480, "product_price": 220},
	{"id": "da_dieu", "name": "Đà điểu", "size": "large", "price": 1500, "color": "5a5a5a", "shape": "big",
		"product": "trung_da_dieu", "product_name": "Trứng đà điểu", "product_color": "f2ead0",
		"interval": 600, "product_price": 450},
]

const COOPS := [
	{"id": "small", "name": "Chuồng nhỏ", "price": 400,
		"desc": "Nuôi Gà / Vịt / Ngan / Cút / Bồ câu — 1 chuồng nuôi 1 con"},
	{"id": "large", "name": "Chuồng lớn", "price": 1200,
		"desc": "Nuôi Ngỗng / Trĩ / Đà điểu — 1 chuồng nuôi 1 con"},
]

const READY_CAP := 3  # mỗi con tích tối đa 3 sản phẩm chờ thu


static func get_animal(id: String) -> Dictionary:
	for a in ANIMALS:
		if a.id == id:
			return a
	return {}


static func get_coop(id: String) -> Dictionary:
	for c in COOPS:
		if c.id == id:
			return c
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
	return {}


static func is_meat(prod_id: String) -> bool:
	return prod_id.begins_with("thit_") or prod_id == "thit_bocau"


static func is_edible(prod_id: String) -> bool:
	return is_meat(prod_id) or prod_id.begins_with("trung_")
