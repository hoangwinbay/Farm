extends Node
# Kho đồ: hạt giống + nông sản thu hoạch, hạt đang chọn để gieo.

signal changed
signal baby_born(species_id: String, species_name: String)

const CropDB := preload("res://scripts/crop_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const OreDB := preload("res://scripts/ore_db.gd")

var seeds: Dictionary = {}
var produce: Dictionary = {}
var selected_seed := ""
var hoes := 0
var hoe_tier: String = "basic"  # "basic", "copper", "iron", "gold"
var water_level := 20
var water_max := 20
var pickaxe := ""  # "basic", "copper", "iron", "gold", "" = chưa có
var ores: Dictionary = {}  # ore_id -> số lượng
var active_item: Dictionary = {"type": "hoe"}
var rods: Dictionary = {}  # tier -> số lượt câu còn lại
var fish: Dictionary = {}  # fish_id -> số lượng
var coops: Dictionary = {"small": 0, "large": 0}  # legacy
var coop_tiers: Dictionary = {"chicken": 0, "cow": 0, "pig": 0, "sheep": 0}  # Cấp chuồng: 0=chưa mua, 1=cấp 1 (chứa 2), 2=cấp 2 (chứa 4)
var animals: Array = []  # [{id, progress, ready, is_baby, grow_progress, is_sheared}]
var breed_timers: Dictionary = {}  # species_id -> thời gian ghép đôi sinh sản
var feed: int = 0  # Túi cám Stardew Valley cho gia súc, gia cầm
var backpack_max: int = 12
var storage: Dictionary = {"seeds": {}, "produce": {}, "fish": {}, "ores": {}}


func reset() -> void:
	seeds = {}
	produce = {}
	selected_seed = ""
	hoes = 0
	hoe_tier = "basic"
	water_level = 20
	water_max = 20
	pickaxe = ""
	ores = {}
	active_item = {"type": "hoe"}
	rods = {}
	fish = {}
	feed = 0
	coops = {"small": 0, "large": 0}
	coop_tiers = {"chicken": 0, "cow": 0, "pig": 0, "sheep": 0}
	animals = []
	breed_timers = {}
	backpack_max = 12
	storage = {"seeds": {}, "produce": {}, "fish": {}, "ores": {}}
	changed.emit()


func feed_count() -> int:
	return feed


func add_feed(n: int = 1) -> void:
	feed += n
	changed.emit()


func take_feed(n: int = 1) -> bool:
	if feed >= n:
		feed -= n
		changed.emit()
		return true
	return false


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
	var remaining := c - n
	if remaining <= 0:
		seeds.erase(id)
		if selected_seed == id:
			var pool := owned_seed_ids()
			if pool.is_empty():
				selected_seed = ""
				if active_item.get("type") == "seed":
					active_item = get_fallback_tool()
			else:
				selected_seed = str(pool[0])
				if active_item.get("type") == "seed":
					active_item = {"type": "seed", "id": selected_seed}
	else:
		seeds[id] = remaining
	changed.emit()
	return true


func get_fallback_tool() -> Dictionary:
	if hoes > 0:
		return {"type": "hoe"}
	if water_max > 0:
		return {"type": "watering_can"}
	if total_casts() > 0:
		return {"type": "rod"}
	if has_pickaxe():
		return {"type": "pickaxe"}
	if feed > 0:
		return {"type": "feed"}
	var s := owned_seed_ids()
	if not s.is_empty():
		return {"type": "seed", "id": str(s[0])}
	return {"type": "hand"}


func take_produce(id: String, n: int = 1) -> bool:
	var c := produce_count(id)
	if c < n:
		return false
	var remaining := c - n
	if remaining <= 0:
		produce.erase(id)
	else:
		produce[id] = remaining
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
	if hoes <= 0 and active_item.get("type", "") == "hoe":
		active_item = get_fallback_tool()
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


func get_hoe_tier() -> String:
	return hoe_tier if hoe_tier != "" else "basic"


func set_hoe_tier(tier: String) -> void:
	hoe_tier = tier
	changed.emit()


func get_pickaxe_tier() -> String:
	return pickaxe if pickaxe != "" else "basic"


func upgrade_hoe() -> Dictionary:
	var cur_idx := 0
	for i in OreDB.HOES.size():
		if OreDB.HOES[i].tier == get_hoe_tier():
			cur_idx = i
			break
	if cur_idx >= OreDB.HOES.size() - 1:
		return {"ok": false, "msg": "Cuốc đất đã đạt cấp tối đa!"}
	var next_h = OreDB.HOES[cur_idx + 1]
	var price: int = int(next_h.price)
	var ore_type: String = str(next_h.ore_type)
	var ore_count: int = int(next_h.ore_count)
	if GameState.money < price:
		return {"ok": false, "msg": "Không đủ tiền! Cần %d xu." % price}
	if ore_type != "" and ore_count(ore_type) < ore_count:
		var o_info := OreDB.get_ore(ore_type)
		return {"ok": false, "msg": "Thiếu nguyên liệu! Cần %d %s." % [ore_count, str(o_info.get("name", "quặng"))]}
	GameState.money -= price
	GameState.money_changed.emit(GameState.money)
	if ore_type != "":
		take_ore(ore_type, ore_count)
	set_hoe_tier(str(next_h.tier))
	return {"ok": true, "msg": "Đã nâng cấp lên %s (-%d xu, giảm tốn thể lực còn %.0f⚡)!" % [str(next_h.name), price, float(next_h.stamina)]}


func upgrade_pickaxe() -> Dictionary:
	if not has_pickaxe():
		add_pickaxe("basic")
	var cur_tier := get_pickaxe_tier()
	var cur_idx := 0
	for i in OreDB.PICKAXES.size():
		if OreDB.PICKAXES[i].tier == cur_tier:
			cur_idx = i
			break
	if cur_idx >= OreDB.PICKAXES.size() - 1:
		return {"ok": false, "msg": "Cúp khai mỏ đã đạt cấp tối đa!"}
	var next_p = OreDB.PICKAXES[cur_idx + 1]
	var price: int = int(next_p.price)
	var ore_type: String = str(next_p.ore_type)
	var ore_count: int = int(next_p.ore_count)
	if GameState.money < price:
		return {"ok": false, "msg": "Không đủ tiền! Cần %d xu." % price}
	if ore_type != "" and ore_count(ore_type) < ore_count:
		var o_info := OreDB.get_ore(ore_type)
		return {"ok": false, "msg": "Thiếu nguyên liệu! Cần %d %s." % [ore_count, str(o_info.get("name", "quặng"))]}
	GameState.money -= price
	GameState.money_changed.emit(GameState.money)
	if ore_type != "":
		take_ore(ore_type, ore_count)
	add_pickaxe(str(next_p.tier))
	return {"ok": true, "msg": "Đã nâng cấp lên %s (-%d xu, giảm tốn thể lực còn %.0f⚡)!" % [str(next_p.name), price, float(next_p.stamina)]}


# ---- khoáng sản & quặng (ores) ----

func add_ore(id: String, n: int = 1) -> void:
	ores[id] = int(ores.get(id, 0)) + n
	changed.emit()


func take_ore(id: String, n: int = 1) -> bool:
	var c := ore_count(id)
	if c < n:
		return false
	var remaining := c - n
	if remaining <= 0:
		ores.erase(id)
	else:
		ores[id] = remaining
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
	if feed > 0:
		slots += 1
	return slots


func can_hold(category: String, id: String) -> bool:
	match category:
		"feed", "cam":
			if feed > 0:
				return true
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
		"feed", "cam":
			return "feed"
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
	if tool_type == "hoe" and hoes <= 0:
		return
	if tool_type == "rod" and total_casts() <= 0:
		return
	active_item = {"type": tool_type}
	changed.emit()


func select_seed(id: String) -> void:
	if id != "" and seed_count(id) <= 0:
		return
	selected_seed = id
	active_item = {"type": "seed", "id": id} if id != "" else get_fallback_tool()
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
		var c := int(rods[k])
		if c > 0:
			n += c
	return n


# Dùng 1 lượt câu (ưu tiên cần cấp thấp trước). Trả về tier đã dùng, "" nếu hết.
func take_cast() -> String:
	for tier in ["basic", "mid", "high"]:
		if int(rods.get(tier, 0)) > 0:
			var rem := int(rods[tier]) - 1
			if rem <= 0:
				rods.erase(tier)
			else:
				rods[tier] = rem
			if total_casts() <= 0 and active_item.get("type", "") == "rod":
				active_item = get_fallback_tool()
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
	var remaining := c - n
	if remaining <= 0:
		fish.erase(id)
	else:
		fish[id] = remaining
	changed.emit()
	return true


# ---- chăn nuôi ----

func get_coop_tier(species_id: String) -> int:
	var sid := PoultryDB.get_canonical_id(species_id)
	return int(coop_tiers.get(sid, 0))


func coop_count(size: String) -> int:
	var canon := PoultryDB.get_canonical_id(size)
	if coop_tiers.has(canon):
		return 1 if get_coop_tier(canon) > 0 else 0
	if size == "small":
		return 1 if get_coop_tier("chicken") > 0 else 0
	if size == "large":
		var cnt := 0
		for s in ["cow", "pig", "sheep"]:
			if get_coop_tier(s) > 0:
				cnt += 1
		return cnt
	return int(coops.get(size, 0))


func coop_capacity(species_id: String) -> int:
	var canon := PoultryDB.get_canonical_id(species_id)
	if coop_tiers.has(canon):
		var tier := get_coop_tier(canon)
		if tier == 1:
			return 2
		elif tier >= 2:
			return 4
		return 0
	if species_id == "small":
		return coop_capacity("chicken")
	if species_id == "large":
		return coop_capacity("cow") + coop_capacity("pig") + coop_capacity("sheep")
	return 0


func add_coop(species_id: String) -> void:
	var canon := PoultryDB.get_canonical_id(species_id)
	if coop_tiers.has(canon):
		coop_tiers[canon] = mini(2, get_coop_tier(canon) + 1)
	elif species_id == "small":
		coop_tiers["chicken"] = mini(2, get_coop_tier("chicken") + 1)
	elif species_id == "large":
		for s in ["cow", "pig", "sheep"]:
			if get_coop_tier(s) == 0:
				coop_tiers[s] = 1
				break
	changed.emit()


func animals_of_species(species_id: String) -> int:
	var sid := PoultryDB.get_canonical_id(species_id)
	var n := 0
	for a in animals:
		if PoultryDB.get_canonical_id(str(a.id)) == sid:
			n += 1
	return n


func animals_of_size(size: String) -> int:
	var n := 0
	for a in animals:
		var d := PoultryDB.get_animal(str(a.id))
		if not d.is_empty() and str(d.size) == size:
			n += 1
	return n


func free_slots(species_id: String) -> int:
	var sid := PoultryDB.get_canonical_id(species_id)
	if coop_tiers.has(sid):
		return coop_capacity(sid) - animals_of_species(sid)
	if sid == "small":
		return free_slots("chicken")
	if sid == "large":
		return free_slots("cow") + free_slots("pig") + free_slots("sheep")
	return 0


func buy_coop(species_id: String) -> String:
	var sid := PoultryDB.get_canonical_id(species_id)
	var c := PoultryDB.get_coop_data(sid)
	if c.is_empty():
		return "Loại chuồng không tồn tại!"
	var cur_tier := get_coop_tier(sid)
	if cur_tier >= 1:
		return "Đã mua %s rồi!" % str(c.name)
	var price := int(c.tier1_price)
	if not GameState.try_spend(price):
		return "Không đủ xu mua %s (cần %d xu)!" % [str(c.name), price]
	coop_tiers[sid] = 1
	changed.emit()
	return ""


func upgrade_coop(species_id: String) -> String:
	var sid := PoultryDB.get_canonical_id(species_id)
	var c := PoultryDB.get_coop_data(sid)
	if c.is_empty():
		return "Loại chuồng không tồn tại!"
	var cur_tier := get_coop_tier(sid)
	if cur_tier < 1:
		return "Cần mua %s Cấp 1 trước!" % str(c.name)
	if cur_tier >= 2:
		return "%s đã đạt cấp tối đa (Cấp 2)!" % str(c.name)
	var price := int(c.tier2_price)
	if not GameState.try_spend(price):
		return "Không đủ xu nâng cấp (cần %d xu)!" % price
	coop_tiers[sid] = 2
	changed.emit()
	return ""


# Mua con giống: cần chuồng trống đúng loài. Trả về "" nếu thành công, ngược lại trả lời do.
func buy_animal(id: String) -> String:
	var canon_id := PoultryDB.get_canonical_id(id)
	var a := PoultryDB.get_animal(canon_id)
	if a.is_empty():
		return "Không có con này!"
	var c := PoultryDB.get_coop_data(canon_id)
	var cname := str(c.get("name", "Chuồng"))
	var tier := get_coop_tier(canon_id)
	if tier <= 0:
		return "Cần mua %s (Cấp 1) tại tiệm Cô Tư trước!" % cname
	if free_slots(canon_id) < 1:
		if tier < 2:
			return "%s đã kín chỗ (%d/%d con)! Hãy nâng cấp lên Cấp 2." % [cname, animals_of_species(canon_id), coop_capacity(canon_id)]
		else:
			return "%s đã đạt giới hạn tối đa (%d/4 con)!" % [cname, animals_of_species(canon_id)]
	if not GameState.try_spend(int(a.price)):
		return "Không đủ xu mua %s!" % a.name
	animals.append({
		"id": canon_id,
		"progress": 0.0,
		"ready": 0,
		"fed": false,
		"is_baby": false,
		"grow_progress": 0.0,
		"is_sheared": false,
	})
	changed.emit()
	return ""


# Đồng hồ chăn nuôi:
# - Con non: lớn dần theo thời gian (grow_progress >= GROW_TIME thì thành con lớn)
# - Con lớn: sau khi được cho ăn cám (fed == true), tiến hành tích lũy để ra sản phẩm
# - Ghép đôi: nuôi từ 2 con lớn cùng loài trở lên, đủ thời gian sẽ sinh ra con non baby!
func tick_animals(delta: float) -> void:
	var had_change := false

	# 1. Quản lý từng con vật
	for a in animals:
		var canon_id := PoultryDB.get_canonical_id(str(a.id))
		var d := PoultryDB.get_animal(canon_id)
		if d.is_empty():
			continue

		# Con non: lớn dần
		if bool(a.get("is_baby", false)):
			a.grow_progress = float(a.get("grow_progress", 0.0)) + delta
			if a.grow_progress >= PoultryDB.GROW_TIME:
				a.is_baby = false
				a.grow_progress = 0.0
				a.fed = false
				had_change = true
			continue

		# Con trưởng thành:
		# CHỈ sản xuất sản phẩm sau khi đã được cho ăn (fed == true) và chưa có sản phẩm sẵn sàng
		var is_fed: bool = bool(a.get("fed", false))
		var is_ready: bool = int(a.get("ready", 0)) > 0
		if is_fed and not is_ready:
			a.progress = float(a.get("progress", 0.0)) + delta
			var interval: float = float(d.get("interval", 25.0))
			if a.progress >= interval:
				a.progress = 0.0
				a.ready = 1
				# Cừu khi mọc lại bộ lông đầy đặn
				if canon_id == "sheep":
					a.is_sheared = false
				had_change = true

	# 2. Sinh sản: nuôi từ 2 con lớn cùng loài trở lên, có chuồng trống thì đẻ baby
	var adult_counts := {}
	for a in animals:
		if not bool(a.get("is_baby", false)):
			var sid := PoultryDB.get_canonical_id(str(a.id))
			adult_counts[sid] = int(adult_counts.get(sid, 0)) + 1

	for sid in adult_counts:
		if adult_counts[sid] >= 2:
			var d := PoultryDB.get_animal(sid)
			if free_slots(sid) > 0:
				breed_timers[sid] = float(breed_timers.get(sid, 0.0)) + delta
				if breed_timers[sid] >= PoultryDB.BREED_TIME:
					breed_timers[sid] = 0.0
					# Sinh 1 con baby mới!
					animals.append({
						"id": sid,
						"is_baby": true,
						"grow_progress": 0.0,
						"progress": 0.0,
						"ready": 0,
						"fed": false,
						"is_sheared": false,
					})
					baby_born.emit(sid, str(d.name))
					had_change = true

	if had_change:
		changed.emit()


func ready_products() -> int:
	var n := 0
	for a in animals:
		n += int(a.ready)
	return n


func ready_products_for_species(species_id: String) -> int:
	var sid := PoultryDB.get_canonical_id(species_id)
	var n := 0
	for a in animals:
		if PoultryDB.get_canonical_id(str(a.id)) == sid:
			n += int(a.ready)
	return n


func hungry_animals_for_species(species_id: String) -> int:
	var sid := PoultryDB.get_canonical_id(species_id)
	var n := 0
	for a in animals:
		if PoultryDB.get_canonical_id(str(a.id)) == sid:
			if not bool(a.get("fed", false)) and int(a.get("ready", 0)) == 0:
				n += 1
	return n


# Cho 1 con cụ thể ăn cám
func feed_animal_by_dict(a: Dictionary) -> bool:
	if bool(a.get("fed", false)) or int(a.get("ready", 0)) > 0:
		return false
	if not take_feed(1):
		return false
	a["fed"] = true
	a["progress"] = 0.0
	changed.emit()
	return true


# Cho tất cả các con đang đói trong chuồng ăn
func feed_all_hungry_for_species(species_id: String) -> int:
	var sid := PoultryDB.get_canonical_id(species_id)
	var fed_cnt := 0
	for a in animals:
		if PoultryDB.get_canonical_id(str(a.get("id", ""))) == sid:
			if not bool(a.get("fed", false)) and int(a.get("ready", 0)) == 0:
				if take_feed(1):
					a["fed"] = true
					a["progress"] = 0.0
					fed_cnt += 1
				else:
					break
	if fed_cnt > 0:
		changed.emit()
	return fed_cnt


# Thu hoạch 1 con cụ thể: ngay lập tức có thể cho ăn tiếp!
func collect_animal_by_dict(a: Dictionary) -> String:
	if int(a.get("ready", 0)) <= 0:
		return ""
	var canon_id := PoultryDB.get_canonical_id(str(a.get("id", "")))
	var d := PoultryDB.get_animal(canon_id)
	if d.is_empty():
		return ""
	var prod_id := str(d.product)
	if not can_hold("produce", prod_id):
		return ""
	a["ready"] = 0
	a["fed"] = false  # Thu hoạch xong ngay lập tức có thể cho ăn tiếp!
	a["progress"] = 0.0
	if canon_id == "sheep":
		a["is_sheared"] = true
	add_produce(prod_id, 1)
	changed.emit()
	return prod_id


# Thu hết sản phẩm chờ -> vào kho nông sản. Trả về số đã thu.
func collect_products() -> int:
	var n := 0
	for a in animals:
		var canon_id := PoultryDB.get_canonical_id(str(a.id))
		var d := PoultryDB.get_animal(canon_id)
		if d.is_empty():
			continue
		var prod_id := str(d.product)
		while int(a.ready) > 0:
			if not can_hold("produce", prod_id):
				break
			a.ready = int(a.ready) - 1
			a.fed = false  # Thu hoạch xong lập tức cho ăn tiếp!
			a.progress = 0.0
			add_produce(prod_id, 1)
			n += 1
			# Cừu sau khi xén lông chuyển sang trạng thái đã cạo lông
			if canon_id == "sheep":
				a.is_sheared = true
	if n > 0:
		changed.emit()
	return n


# Thu sản phẩm riêng của một loài chuồng. Trả về số đã thu.
func collect_products_for_species(species_id: String) -> int:
	var sid := PoultryDB.get_canonical_id(species_id)
	var d := PoultryDB.get_animal(sid)
	if d.is_empty():
		return 0
	var prod_id := str(d.product)
	var n := 0
	for a in animals:
		if PoultryDB.get_canonical_id(str(a.id)) != sid:
			continue
		while int(a.ready) > 0:
			if not can_hold("produce", prod_id):
				break
			a.ready = int(a.ready) - 1
			a.fed = false  # Thu hoạch xong lập tức cho ăn tiếp!
			a.progress = 0.0
			add_produce(prod_id, 1)
			n += 1
			if sid == "sheep":
				a.is_sheared = true
	if n > 0:
		changed.emit()
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
		"hoes": hoes, "hoe_tier": get_hoe_tier(), "water_level": water_level, "water_max": water_max,
		"pickaxe": pickaxe, "ores": ores.duplicate(),
		"active_item": active_item.duplicate(),
		"rods": rods.duplicate(), "fish": fish.duplicate(),
		"feed": feed,
		"coops": coops.duplicate(),
		"coop_tiers": coop_tiers.duplicate(),
		"animals": animals.duplicate(true),
		"breed_timers": breed_timers.duplicate(),
		"backpack_max": backpack_max,
		"storage": storage.duplicate(true)
	}


func set_state(d: Dictionary) -> void:
	seeds = {}
	produce = {}
	rods = {}
	fish = {}
	ores = {}
	feed = int(d.get("feed", 0))
	animals = []
	breed_timers = {}
	coops = {"small": 0, "large": 0}
	coop_tiers = {"chicken": 0, "cow": 0, "pig": 0, "sheep": 0}
	storage = {"seeds": {}, "produce": {}, "fish": {}, "ores": {}}
	backpack_max = int(d.get("backpack_max", 12))
	pickaxe = str(d.get("pickaxe", ""))
	if d.has("seeds"):
		for k in d["seeds"]:
			var c := int(d["seeds"][k])
			if c > 0:
				seeds[str(k)] = c
	if d.has("produce"):
		for k in d["produce"]:
			var c := int(d["produce"][k])
			if c > 0:
				produce[str(k)] = c
	if d.has("ores"):
		for k in d["ores"]:
			var c := int(d["ores"][k])
			if c > 0:
				ores[str(k)] = c
	if d.has("rods"):
		for k in d["rods"]:
			var c := int(d["rods"][k])
			if c > 0:
				rods[str(k)] = c
	if d.has("fish"):
		for k in d["fish"]:
			var c := int(d["fish"][k])
			if c > 0:
				fish[str(k)] = c
	if d.has("coops"):
		for k in d["coops"]:
			coops[str(k)] = int(d["coops"][k])
	if d.has("coop_tiers") and d["coop_tiers"] is Dictionary:
		for k in d["coop_tiers"]:
			var sid := PoultryDB.get_canonical_id(str(k))
			if coop_tiers.has(sid):
				coop_tiers[sid] = int(d["coop_tiers"][k])
	elif d.has("coops") and d["coops"] is Dictionary:
		var sc: int = int(d["coops"].get("small", 0))
		var lc: int = int(d["coops"].get("large", 0))
		if sc > 0:
			coop_tiers["chicken"] = 2 if sc > 1 else 1
		if lc > 0:
			var t := 2 if lc > 1 else 1
			coop_tiers["cow"] = t
			coop_tiers["pig"] = t
			coop_tiers["sheep"] = t
	if d.has("breed_timers") and d["breed_timers"] is Dictionary:
		for k in d["breed_timers"]:
			breed_timers[str(k)] = float(d["breed_timers"][k])
	if d.has("animals") and typeof(d["animals"]) == TYPE_ARRAY:
		for a in d["animals"]:
			animals.append({
				"id": str(a.get("id", "")),
				"progress": float(a.get("progress", 0)),
				"ready": int(a.get("ready", 0)),
				"fed": bool(a.get("fed", false)),
				"is_baby": bool(a.get("is_baby", false)),
				"grow_progress": float(a.get("grow_progress", 0.0)),
				"is_sheared": bool(a.get("is_sheared", false)),
			})
	if d.has("storage") and d["storage"] is Dictionary:
		var st: Dictionary = d["storage"]
		for cat in ["seeds", "produce", "fish", "ores"]:
			if st.has(cat) and st[cat] is Dictionary:
				for k in st[cat]:
					storage[cat][str(k)] = int(st[cat][k])
	selected_seed = str(d.get("sel", ""))
	hoes = int(d.get("hoes", 0))
	hoe_tier = str(d.get("hoe_tier", "basic"))
	water_level = int(d.get("water_level", 20))
	water_max = int(d.get("water_max", 20))
	if d.has("active_item") and d["active_item"] is Dictionary:
		active_item = (d["active_item"] as Dictionary).duplicate()
	else:
		active_item = {"type": "hoe"}
	changed.emit()
