extends RefCounted
# Dữ liệu Khoáng sản, Quặng và Cúp khai mỏ.

const ORES := [
	{
		"id": "stone",
		"name": "Đá cuội",
		"price": 2,
		"color": "9e9e9e",
		"desc": "Đá thường vỡ vụn khi đào mỏ, dùng xây dựng.",
		"min_floor": 1,
		"hits": 2
	},
	{
		"id": "coal",
		"name": "Than đá",
		"price": 15,
		"color": "37474f",
		"desc": "Khoáng sản màu đen, chất đốt quý giá.",
		"min_floor": 1,
		"hits": 2
	},
	{
		"id": "copper_ore",
		"name": "Quặng Đồng",
		"price": 30,
		"color": "d87d38",
		"desc": "Quặng kim loại màu cam đỏ, dễ tìm thấy ở các tầng đầu.",
		"min_floor": 1,
		"hits": 3
	},
	{
		"id": "iron_ore",
		"name": "Quặng Sắt",
		"price": 75,
		"color": "b0bec5",
		"desc": "Quặng kim loại chắc chắn màu xám bạc, xuất hiện từ tầng 3.",
		"min_floor": 3,
		"hits": 4
	},
	{
		"id": "gold_ore",
		"name": "Quặng Vàng",
		"price": 180,
		"color": "ffd54f",
		"desc": "Quặng kim loại quý màu vàng óng, xuất hiện từ tầng 6.",
		"min_floor": 6,
		"hits": 5
	},
	{
		"id": "ruby",
		"name": "Hồng Ngọc (Ruby)",
		"price": 350,
		"color": "e53935",
		"desc": "Đá quý màu đỏ rực rỡ, lấp lánh và rất hiếm gặp.",
		"min_floor": 4,
		"hits": 5
	},
	{
		"id": "diamond",
		"name": "Kim Cương",
		"price": 800,
		"color": "80deea",
		"desc": "Báu vật trong lòng đất, độ cứng tuyệt đối và giá trị cực cao.",
		"min_floor": 8,
		"hits": 6
	}
]

const PICKAXES := [
	{"tier": "basic", "name": "Cúp sơ cấp", "power": 1, "price": 0, "color": "9e9e9e", "desc": "Cúp bằng đá và gỗ do Leah tặng, đủ đào các tầng đầu."},
	{"tier": "copper", "name": "Cúp đồng", "power": 2, "price": 500, "color": "d87d38", "desc": "Cúp đúc bằng đồng, đào đá nhanh gấp đôi."},
	{"tier": "iron", "name": "Cúp sắt", "power": 3, "price": 1500, "color": "cfd8dc", "desc": "Cúp rèn từ sắt già, phá vỡ quặng cứng dễ dàng."},
	{"tier": "gold", "name": "Cúp vàng", "power": 4, "price": 4000, "color": "ffe082", "desc": "Cúp mạ vàng tinh xảo, sức đào thần tốc."}
]

static func get_ore(id: String) -> Dictionary:
	for o in ORES:
		if o.id == id:
			return o
	return {}

static func get_pickaxe(tier: String) -> Dictionary:
	for p in PICKAXES:
		if p.tier == tier:
			return p
	return {}

static func pickaxe_power(tier: String) -> int:
	var p := get_pickaxe(tier)
	return int(p.get("power", 1))
