extends Node
# Kho đồ: hạt giống + nông sản thu hoạch, hạt đang chọn để gieo.

signal changed

const CropDB := preload("res://scripts/crop_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const OreDB := preload("res://scripts/ore_db.gd")

var seeds: Dictionary = {}
var produce: Dictionary = {}
var selected_seed := ""
var hoes := 0
var water_level := 20
var water_max := 20
var pickaxe := ""  # "basic", "copper", "iron", "gold", "" = chưa có
var ores: Dictionary = {}  # ore_id -> số lượng
var active_item: Dictionary = {"type": "hoe"}
var rods: Dictionary = {}  # tier -> số lượt câu còn lại
var fish: Dictionary = {}  # fish_id -> số lượng
var coops: Dictionary = {"small": 0, "large": 0}  # số chuồng đã mua theo loại
var animals: Array = []  # [{id, progress, ready}]
var backpack_max: int = 12
var storage: Dictionary = {"seeds": {}, "produce": {}, "fish": {}, "ores": {}}


func reset() -> void:
	seeds = {}
	produce = {}
	selected_seed = ""
	hoes = 0
	water_level = 20
	water_max = 20
	pickaxe = ""
	ores = {}
	active_item = {"type": "hoe"}
	rods = {}
	fish = {}
	coops = {"small": 0, "large": 0}
	animals = []
	backpack_max = 12
	storage = {"seeds": {}, "produce": {}, "fish": {}, "ores": {}}
	changed.emit()


func add_seed(id: String, n: int = 1) -> void:
	seeds[id] = int(seeds.get(id, 0)) + n
	changed.emit()


func add_produce(id: String, n: int = 1) -> void:
	produce[id] = int(produce.get(id, 0)) + n
	changed.emit()


func take_seed(id: String, n: int = 1) -> bool:
	var c := seed_count(id)
	if c < n:
		return false
	seeds[id] = c - n
	changed.emit()
	return true


func take_produce(id: String, n: int = 1) -> bool:
	var c := produce_count(id)
	if c < n:
		return false
	produce[id] = c - n
	changed.emit()
	return true


func seed_count(id: String) -> int:
	return int(seeds.get(id, 0))


func produce_count(id: String) -> int:
	return int(produce.get(id, 0))


# ---- cuốc ----

func add_hoes(n: int = 1) -> void:
	hoes += n
	changed.emit()


func take_hoe() -> bool:
	if hoes < 1:
		return false
	hoes -= 1
	changed.emit()
	return true


# ---- bình tưới nước ----

func has_water() -> bool:
	return water_level > 0


func take_water(n: int = 1) -> bool:
	if water_level < n:
		return false
	water_level -= n
	changed.emit()
	return true


func refill_water() -> int:
	var added: int = water_max - water_level
	water_level = water_max
	changed.emit()
	return added


# ---- cúp đào mỏ (pickaxe) ----

func add_pickaxe(tier: String = "basic") -> void:
	pickaxe = tier
	changed.emit()


func has_pickaxe() -> bool:
	return pickaxe != ""


func get_pickaxe_power() -> int:
	if not has_pickaxe():
		return 0
	return OreDB.pickaxe_power(pickaxe)


# ---- khoáng sản & quặng (ores) ----

func add_ore(id: String, n: int = 1) -> void:
	ores[id] = int(ores.get(id, 0)) + n
	changed.emit()


func take_ore(id: String, n: int = 1) -> bool:
	var c := ore_count(id)
	if c < n:
		return false
	ores[id] = c - n
	changed.emit()
	return true


func ore_count(id: String) -> int:
	return int(ores.get(id, 0))


func total_ores() -> int:
	var n := 0
	for k in ores:
		n += int(ores[k])
	return n


# ---- giới hạn túi đồ (backpack slots) ----

func backpack_slots_used() -> int:
	var slots := 0
	if hoes > 0:
		slots += 1
	if water_max > 0:
		slots += 1
	if has_pickaxe():
		slots += 1
	if total_casts() > 0:
		slots += 1
	for k in seeds:
		if int(seeds[k]) > 0:
			slots += 1
	for k in produce:
		if int(produce[k]) > 0:
			slots += 1
	for k in fish:
		if int(fish[k]) > 0:
			slots += 1
	for k in ores:
		if int(ores[k]) > 0:
			slots += 1
	return slots


func can_hold(category: String, id: String) -> bool:
	match category:
		"seed", "seeds":
			if seed_count(id) > 0:
				return true
		"produce", "crop", "poultry":
			if produce_count(id) > 0:
				return true
		"fish":
			if fish_count(id) > 0:
				return true
		"ore", "ores":
			if ore_count(id) > 0:
				return true
		"hoe":
			if hoes > 0:
				return true
		"rod":
			if rod_casts(id) > 0:
				return true
		"pickaxe":
			if has_pickaxe():
				return true
	return backpack_slots_used() < backpack_max


# ---- nhà kho lưu trữ (shed storage) ----

func _normalize_cat(category: String) -> String:
	match category:
		"seed", "seeds":
			return "seeds"
		"produce", "crop", "poultry":
			return "produce"
		"fish":
			return "fish"
		"ore", "ores":
			return "ores"
	return category


func storage_count(category: String, id: String) -> int:
	var cat_key := _normalize_cat(category)
	return int(storage.get(cat_key, {}).get(id, 0))


func store_item(category: String, id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var cat_key := _normalize_cat(category)
	var have := 0
	match cat_key:
		"seeds":
			have = seed_count(id)
			if have < amount:
				amount = have
			if amount <= 0:
				return false
			take_seed(id, amount)
		"produce":
			have = produce_count(id)
			if have < amount:
				amount = have
			if amount <= 0:
				return false
			take_produce(id, amount)
		"fish":
			have = fish_count(id)
			if have < amount:
				amount = have
			if amount <= 0:
				return false
			take_fish(id, amount)
		"ores":
			have = ore_count(id)
			if have < amount:
				amount = have
			if amount <= 0:
				return false
			take_ore(id, amount)
		_:
			return false

	if not storage.has(cat_key):
		storage[cat_key] = {}
	storage[cat_key][id] = int(storage[cat_key].get(id, 0)) + amount
	changed.emit()
	return true


func direct_store(category: String, id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var cat_key := _normalize_cat(category)
	if not storage.has(cat_key):
		storage[cat_key] = {}
	storage[cat_key][id] = int(storage[cat_key].get(id, 0)) + amount
	changed.emit()


func withdraw_item(category: String, id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var cat_key := _normalize_cat(category)
	var stored := storage_count(cat_key, id)
	if stored <= 0:
		return false
	if amount > stored:
		amount = stored

	var item_cat := "produce"
	if cat_key == "seeds":
		item_cat = "seed"
	elif cat_key == "fish":
		item_cat = "fish"
	elif cat_key == "ores":
		item_cat = "ore"
	if not can_hold(item_cat, id):
		return false

	storage[cat_key][id] = stored - amount
	if int(storage[cat_key][id]) <= 0:
		storage[cat_key].erase(id)

	match cat_key:
		"seeds":
			add_seed(id, amount)
		"produce":
			add_produce(id, amount)
		"fish":
			add_fish(id, amount)
		"ores":
			add_ore(id, amount)

	changed.emit()
	return true


func store_all_category(category: String) -> int:
	var cat_key := _normalize_cat(category)
	var total_moved := 0
	match cat_key:
		"seeds":
			for k in seeds.keys():
				var c := int(seeds.get(k, 0))
				if c > 0:
					store_item("seeds", str(k), c)
					total_moved += c
		"produce":
			for k in produce.keys():
				var c := int(produce.get(k, 0))
				if c > 0:
					store_item("produce", str(k), c)
					total_moved += c
		"fish":
			for k in fish.keys():
				var c := int(fish.get(k, 0))
				if c > 0:
					store_item("fish", str(k), c)
					total_moved += c
		"ores":
			for k in ores.keys():
				var c := int(ores.get(k, 0))
				if c > 0:
					store_item("ores", str(k), c)
					total_moved += c
	return total_moved


# ---- chọn đồ thanh công cụ ----

func select_tool(tool_type: String) -> void:
	active_item = {"type": tool_type}
	changed.emit()


func select_seed(id: String) -> void:
	selected_seed = id
	active_item = {"type": "seed", "id": id}
	changed.emit()


# ---- cần câu ----

func add_rod(tier: String, casts: int) -> void:
	rods[tier] = int(rods.get(tier, 0)) + casts
	changed.emit()


func rod_casts(tier: String) -> int:
	return int(rods.get(tier, 0))


func total_casts() -> int:
	var n := 0
	for k in rods:
		n += int(rods[k])
	return n


# Dùng 1 lượt câu (ưu tiên cần cấp thấp trước). Trả về tier đã dùng, "" nếu hết.
func take_cast() -> String:
	for tier in ["basic", "mid", "high"]:
		if int(rods.get(tier, 0)) > 0:
			rods[tier] = int(rods[tier]) - 1
			changed.emit()
			return tier
	return ""


# ---- cá ----

func add_fish(id: String, n: int = 1) -> void:
	fish[id] = int(fish.get(id, 0)) + n
	changed.emit()


func fish_count(id: String) -> int:
	return int(fish.get(id, 0))


func take_fish(id: String, n: int = 1) -> bool:
	var c := fish_count(id)
	if c < n:
		return false
	fish[id] = c - n
	changed.emit()
	return true


# ---- chăn nuôi ----

func coop_count(size: String) -> int:
	return int(coops.get(size, 0))


func add_coop(size: String) -> void:
	coops[size] = coop_count(size) + 1
	changed.emit()


func animals_of_size(size: String) -> int:
	var n := 0
	for a in animals:
		var d := PoultryDB.get_animal(str(a.id))
		if not d.is_empty() and str(d.size) == size:
			n += 1
	return n


func free_slots(size: String) -> int:
	return coop_count(size) - animals_of_size(size)


# Mua con giống: cần chuồng trống đúng cỡ. Trả về "" nếu thành công, ngược lại trả lời do.
func buy_animal(id: String) -> String:
	var a := PoultryDB.get_animal(id)
	if a.is_empty():
		return "Không có con này!"
	var size := str(a.size)
	if free_slots(size) < 1:
		return "Cần mua thêm CHUỒNG %s để nuôi!" % ("LỚN" if size == "large" else "NHỎ")
	if not GameState.try_spend(int(a.price)):
		return "Không đủ xu mua %s!" % a.name
	animals.append({"id": id, "progress": 0.0, "ready": 0})
	changed.emit()
	return ""


# Đồng hồ chăn nuôi: con nào đủ thời gian thì sinh sản phẩm (tối đa 3 chờ thu).
func tick_animals(delta: float) -> void:
	for a in animals:
		var d := PoultryDB.get_animal(str(a.id))
		if d.is_empty():
			continue
		if int(a.ready) >= PoultryDB.READY_CAP:
			continue
		a.progress = float(a.progress) + delta
		if a.progress >= float(d.interval):
			a.progress = 0.0
			a.ready = int(a.ready) + 1
			changed.emit()


func ready_products() -> int:
	var n := 0
	for a in animals:
		n += int(a.ready)
	return n


# Thu hết sản phẩm chờ -> vào kho nông sản. Trả về số đã thu.
func collect_products() -> int:
	var n := 0
	for a in animals:
		var prod_id := str(PoultryDB.get_animal(str(a.id)).product)
		while int(a.ready) > 0:
			if not can_hold("produce", prod_id):
				break
			a.ready = int(a.ready) - 1
			add_produce(prod_id, 1)
			n += 1
	return n


func owned_seed_ids() -> Array:
	var pool: Array = []
	for id in GameState.unlocked:
		if seed_count(str(id)) > 0:
			pool.append(str(id))
	return pool


func cycle_seed() -> String:
	var pool := owned_seed_ids()
	if pool.is_empty():
		pool = GameState.unlocked.duplicate()
	if pool.is_empty():
		return selected_seed
	var idx := pool.find(selected_seed)
	selected_seed = str(pool[(idx + 1) % pool.size()])
	active_item = {"type": "seed", "id": selected_seed}
	changed.emit()
	return selected_seed


func get_state() -> Dictionary:
	return {
		"seeds": seeds.duplicate(), "produce": produce.duplicate(), "sel": selected_seed,
		"hoes": hoes, "water_level": water_level, "water_max": water_max,
		"pickaxe": pickaxe, "ores": ores.duplicate(),
		"active_item": active_item.duplicate(),
		"rods": rods.duplicate(), "fish": fish.duplicate(),
		"coops": coops.duplicate(), "animals": animals.duplicate(true),
		"backpack_max": backpack_max,
		"storage": storage.duplicate(true)
	}


func set_state(d: Dictionary) -> void:
	seeds = {}
	produce = {}
	rods = {}
	fish = {}
	ores = {}
	animals = []
	coops = {"small": 0, "large": 0}
	storage = {"seeds": {}, "produce": {}, "fish": {}, "ores": {}}
	backpack_max = int(d.get("backpack_max", 12))
	pickaxe = str(d.get("pickaxe", ""))
	if d.has("seeds"):
		for k in d["seeds"]:
			seeds[str(k)] = int(d["seeds"][k])
	if d.has("produce"):
		for k in d["produce"]:
			produce[str(k)] = int(d["produce"][k])
	if d.has("ores"):
		for k in d["ores"]:
			ores[str(k)] = int(d["ores"][k])
	if d.has("rods"):
		for k in d["rods"]:
			rods[str(k)] = int(d["rods"][k])
	if d.has("fish"):
		for k in d["fish"]:
			fish[str(k)] = int(d["fish"][k])
	if d.has("coops"):
		for k in d["coops"]:
			coops[str(k)] = int(d["coops"][k])
	if d.has("animals") and typeof(d["animals"]) == TYPE_ARRAY:
		for a in d["animals"]:
			animals.append({"id": str(a.get("id", "")), "progress": float(a.get("progress", 0)),
					"ready": int(a.get("ready", 0))})
	if d.has("storage") and d["storage"] is Dictionary:
		var st: Dictionary = d["storage"]
		for cat in ["seeds", "produce", "fish", "ores"]:
			if st.has(cat) and st[cat] is Dictionary:
				for k in st[cat]:
					storage[cat][str(k)] = int(st[cat][k])
	selected_seed = str(d.get("sel", ""))
	hoes = int(d.get("hoes", 0))
	water_level = int(d.get("water_level", 20))
	water_max = int(d.get("water_max", 20))
	if d.has("active_item") and d["active_item"] is Dictionary:
		active_item = (d["active_item"] as Dictionary).duplicate()
	else:
		active_item = {"type": "hoe"}
	changed.emit()
