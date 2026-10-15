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
	{
		"tier": "basic",
		"name": "Cúp sơ cấp",
		"power": 1,
		"stamina": 5.0,
		"price": 0,
		"ore_type": "",
		"ore_count": 0,
		"color": "9e9e9e",
		"desc": "Cúp bằng đá và gỗ do Leah tặng. Tiêu hao 5⚡ mỗi lần đập."
	},
	{
		"tier": "copper",
		"name": "Cúp đồng",
		"power": 2,
		"stamina": 4.0,
		"price": 350,
		"ore_type": "copper_ore",
		"ore_count": 5,
		"color": "d87d38",
		"desc": "Cúp đúc bằng đồng, sức đào x2. Tiêu hao giảm còn 4⚡ mỗi lần đập."
	},
	{
		"tier": "iron",
		"name": "Cúp sắt",
		"power": 3,
		"stamina": 3.0,
		"price": 1000,
		"ore_type": "iron_ore",
		"ore_count": 5,
		"color": "b0bec5",
		"desc": "Cúp rèn từ sắt già, phá quặng cứng dễ dàng. Tiêu hao giảm còn 3⚡ mỗi lần đập."
	},
	{
		"tier": "gold",
		"name": "Cúp vàng",
		"power": 4,
		"stamina": 2.0,
		"price": 2500,
		"ore_type": "gold_ore",
		"ore_count": 5,
		"color": "ffd54f",
		"desc": "Cúp mạ vàng tinh xảo, đào thần tốc. Tiêu hao chỉ còn 2⚡ mỗi lần đập."
	}
]

const HOES := [
	{
		"tier": "basic",
		"name": "Cuốc thường",
		"stamina": 7.0,
		"price": 0,
		"ore_type": "",
		"ore_count": 0,
		"color": "9e9e9e",
		"desc": "Cuốc nông nghiệp cơ bản. Tiêu hao 7⚡ thể lực mỗi lần cuốc."
	},
	{
		"tier": "copper",
		"name": "Cuốc đồng",
		"stamina": 5.0,
		"price": 300,
		"ore_type": "copper_ore",
		"ore_count": 5,
		"color": "d87d38",
		"desc": "Lưỡi cuốc đúc bằng đồng. Giảm tiêu hao xuống còn 5⚡ thể lực."
	},
	{
		"tier": "iron",
		"name": "Cuốc sắt",
		"stamina": 4.0,
		"price": 800,
		"ore_type": "iron_ore",
		"ore_count": 5,
		"color": "b0bec5",
		"desc": "Lưỡi cuốc rèn sắt già bền bỉ. Giảm tiêu hao xuống còn 4⚡ thể lực."
	},
	{
		"tier": "gold",
		"name": "Cuốc vàng",
		"stamina": 3.0,
		"price": 2000,
		"ore_type": "gold_ore",
		"ore_count": 5,
		"color": "ffd54f",
		"desc": "Cuốc mạ vàng tinh xảo, nhẹ tựa lông hồng. Giảm tiêu hao xuống còn 3⚡ thể lực."
	}
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
	return PICKAXES[0]

static func pickaxe_power(tier: String) -> int:
	var p := get_pickaxe(tier)
	return int(p.get("power", 1))

static func get_pickaxe_stamina(tier: String) -> float:
	var p := get_pickaxe(tier)
	return float(p.get("stamina", 5.0))

static func get_hoe(tier: String) -> Dictionary:
	for h in HOES:
		if h.tier == tier:
			return h
	return HOES[0]

static func get_hoe_stamina(tier: String) -> float:
	var h := get_hoe(tier)
	return float(h.get("stamina", 7.0))
