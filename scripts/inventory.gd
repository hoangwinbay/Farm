extends Node
# Kho đồ: hạt giống + nông sản thu hoạch, hạt đang chọn để gieo.

signal changed
signal baby_born(species_id: String, species_name: String)
signal pens_structure_changed

const CropDB := preload("res://scripts/crop_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const OreDB := preload("res://scripts/ore_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")

const HOTBAR_SIZE: int = 9
const BACKPACK_DEFAULT_SIZE: int = 20
const BACKPACK_SIZE: int = 20 # Alias tương thích ngược
const BACKPACK_MAX_LIMIT: int = 64

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
var coop_tiers: Dictionary = {"chicken": 0, "cow": 0, "pig": 0, "sheep": 0}  # Cấp chuồng: 0=chưa mua, 1=cấp 1 (chứa 2), 2=cấp 2 (chứa 4), 3=cấp 3 (chứa 8), 4=cấp 4 (chứa 16)
var animals: Array = []  # [{id, progress, ready, is_baby, grow_progress, is_sheared}]
var breed_timers: Dictionary = {}  # species_id -> thời gian ghép đôi sinh sản
var feed: int = 0  # Túi cám Stardew Valley cho gia súc, gia cầm
var backpack_max: int = 20
var storage: Dictionary = {"seeds": {}, "produce": {}, "fish": {}, "ores": {}}

var hotbar_slots: Array = []
var backpack_slots: Array = []
var active_hotbar_index: int = 0


func _init() -> void:
	_init_slots()


func _init_slots() -> void:
	hotbar_slots = []
	for i in HOTBAR_SIZE:
		hotbar_slots.append({})
	backpack_slots = []
	for i in backpack_max:
		backpack_slots.append({})
	active_hotbar_index = 0


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
	backpack_max = 20
	storage = {"seeds": {}, "produce": {}, "fish": {}, "ores": {}}
	_init_slots()
	if water_max > 0:
		hotbar_slots[1] = {"type": "watering_can", "qty": water_level, "max": water_max}
	changed.emit()



func _ensure_slots_valid() -> void:
	if hotbar_slots.size() != HOTBAR_SIZE:
		hotbar_slots.resize(HOTBAR_SIZE)
		for i in HOTBAR_SIZE:
			if hotbar_slots[i] == null or not (hotbar_slots[i] is Dictionary):
				hotbar_slots[i] = {}
	if backpack_slots.size() != backpack_max:
		backpack_slots.resize(backpack_max)
		for i in backpack_max:
			if backpack_slots[i] == null or not (backpack_slots[i] is Dictionary):
				backpack_slots[i] = {}


func get_backpack_upgrade_cost() -> int:
	if backpack_max >= BACKPACK_MAX_LIMIT:
		return -1
	return 50 + (backpack_max - BACKPACK_DEFAULT_SIZE) * 10


func can_upgrade_backpack() -> bool:
	if backpack_max >= BACKPACK_MAX_LIMIT:
		return false
	var cost := get_backpack_upgrade_cost()
	return GameState.money >= cost


func upgrade_backpack() -> Dictionary:
	if backpack_max >= BACKPACK_MAX_LIMIT:
		return {"ok": false, "msg": "Túi đồ đã đạt tối đa %d ô!" % BACKPACK_MAX_LIMIT}
	var cost := get_backpack_upgrade_cost()
	if GameState.money < cost:
		return {"ok": false, "msg": "Không đủ vàng! Cần %d xu." % cost}
	GameState.add_money(-cost)
	backpack_max += 1
	_ensure_slots_valid()
	changed.emit()
	return {"ok": true, "msg": "Đã mở thêm 1 ô túi đồ! (%d/64 ô)" % backpack_max, "new_max": backpack_max}


func _add_item_to_slots(type: String, id: String, qty: int, extra: Dictionary = {}) -> void:
	_ensure_slots_valid()
	# 1. Thử cộng dồn vào ô đã có sẵn
	for s in hotbar_slots:
		if not s.is_empty() and str(s.get("type", "")) == type and str(s.get("id", "")) == id:
			s["qty"] = int(s.get("qty", 0)) + qty
			return
	for s in backpack_slots:
		if not s.is_empty() and str(s.get("type", "")) == type and str(s.get("id", "")) == id:
			s["qty"] = int(s.get("qty", 0)) + qty
			return

	# 2. Đặt vào ô trống đầu tiên (ưu tiên hotbar trước, rồi tới balo)
	var new_item: Dictionary = {"type": type, "id": id, "qty": qty}
	for k in extra:
		new_item[k] = extra[k]

	for i in hotbar_slots.size():
		if hotbar_slots[i].is_empty():
			hotbar_slots[i] = new_item
			return
	for i in backpack_slots.size():
		if backpack_slots[i].is_empty():
			backpack_slots[i] = new_item
			return


func _take_item_from_slots(type: String, id: String, qty: int) -> int:
	_ensure_slots_valid()
	var needed := qty
	# Ưu tiên trừ từ ô đang cầm trên hotbar nếu khớp
	if active_hotbar_index >= 0 and active_hotbar_index < hotbar_slots.size():
		var act_s: Dictionary = hotbar_slots[active_hotbar_index]
		if not act_s.is_empty() and str(act_s.get("type", "")) == type and (id == "" or str(act_s.get("id", "")) == id):
			var have: int = int(act_s.get("qty", 0))
			if have <= needed:
				needed -= have
				hotbar_slots[active_hotbar_index] = {}
			else:
				act_s["qty"] = have - needed
				needed = 0

	if needed > 0:
		for i in hotbar_slots.size():
			var s: Dictionary = hotbar_slots[i]
			if not s.is_empty() and str(s.get("type", "")) == type and (id == "" or str(s.get("id", "")) == id):
				var have: int = int(s.get("qty", 0))
				if have <= needed:
					needed -= have
					hotbar_slots[i] = {}
				else:
					s["qty"] = have - needed
					needed = 0
			if needed <= 0:
				break

	if needed > 0:
		for i in backpack_slots.size():
			var s: Dictionary = backpack_slots[i]
			if not s.is_empty() and str(s.get("type", "")) == type and (id == "" or str(s.get("id", "")) == id):
				var have: int = int(s.get("qty", 0))
				if have <= needed:
					needed -= have
					backpack_slots[i] = {}
				else:
					s["qty"] = have - needed
					needed = 0
			if needed <= 0:
				break

	return qty - needed


func _update_tool_slot_qty(type: String, qty: int) -> void:
	_ensure_slots_valid()
	for s in hotbar_slots:
		if not s.is_empty() and str(s.get("type", "")) == type:
			s["qty"] = qty
			return
	for s in backpack_slots:
		if not s.is_empty() and str(s.get("type", "")) == type:
			s["qty"] = qty
			return


func _has_item_in_slots(type: String, id: String) -> bool:
	for s in hotbar_slots:
		if not s.is_empty() and str(s.get("type", "")) == type:
			if id == "" or str(s.get("id", "")) == id:
				return true
	for s in backpack_slots:
		if not s.is_empty() and str(s.get("type", "")) == type:
			if id == "" or str(s.get("id", "")) == id:
				return true
	return false


func _sync_single_slot(slots_list: Array, idx: int) -> void:
	var s: Dictionary = slots_list[idx]
	if s.is_empty():
		return
	var t: String = str(s.get("type", ""))
	var id: String = str(s.get("id", ""))
	match t:
		"hoe":
			if hoes <= 0:
				slots_list[idx] = {}
			else:
				s["qty"] = hoes
				s["tier"] = get_hoe_tier()
		"watering_can":
			s["qty"] = water_level
			s["max"] = water_max
		"pickaxe":
			if not has_pickaxe():
				slots_list[idx] = {}
			else:
				s["qty"] = get_pickaxe_power()
				s["tier"] = get_pickaxe_tier()
		"rod":
			var c: int = rod_casts(str(s.get("tier", "basic")))
			if c <= 0 and total_casts() <= 0:
				slots_list[idx] = {}
			else:
				s["qty"] = c if c > 0 else total_casts()
		"feed":
			if feed <= 0:
				slots_list[idx] = {}
			else:
				s["qty"] = feed
		"seed":
			var c := seed_count(id)
			if c <= 0:
				slots_list[idx] = {}
			else:
				s["qty"] = c
		"produce":
			var c := produce_count(id)
			if c <= 0:
				slots_list[idx] = {}
			else:
				s["qty"] = c
		"fish":
			var c := fish_count(id)
			if c <= 0:
				slots_list[idx] = {}
			else:
				s["qty"] = c
		"ore":
			var c := ore_count(id)
			if c <= 0:
				slots_list[idx] = {}
			else:
				s["qty"] = c


func sync_slots_from_pools() -> void:
	_ensure_slots_valid()

	for i in hotbar_slots.size():
		_sync_single_slot(hotbar_slots, i)
	for i in backpack_slots.size():
		_sync_single_slot(backpack_slots, i)

	if hoes > 0 and not _has_item_in_slots("hoe", ""):
		if hotbar_slots[0].is_empty():
			hotbar_slots[0] = {"type": "hoe", "id": "", "qty": hoes, "tier": get_hoe_tier()}
		else:
			_add_item_to_slots("hoe", "", hoes, {"tier": get_hoe_tier()})

	if water_max > 0 and not _has_item_in_slots("watering_can", ""):
		if hotbar_slots[1].is_empty():
			hotbar_slots[1] = {"type": "watering_can", "id": "", "qty": water_level, "max": water_max}
		elif hotbar_slots[0].is_empty():
			hotbar_slots[0] = {"type": "watering_can", "id": "", "qty": water_level, "max": water_max}
		else:
			_add_item_to_slots("watering_can", "", water_level, {"max": water_max})

	if hoes > 0 and str(hotbar_slots[0].get("type", "")) == "watering_can" and (hotbar_slots[1].is_empty() or str(hotbar_slots[1].get("type", "")) == "hoe"):
		var tmp_can: Dictionary = hotbar_slots[0]
		hotbar_slots[0] = hotbar_slots[1]
		hotbar_slots[1] = tmp_can
		if hotbar_slots[0].is_empty() and hoes > 0:
			hotbar_slots[0] = {"type": "hoe", "id": "", "qty": hoes, "tier": get_hoe_tier()}

	if has_pickaxe() and not _has_item_in_slots("pickaxe", ""):
		_add_item_to_slots("pickaxe", "", get_pickaxe_power(), {"tier": get_pickaxe_tier()})
	for r in rods:
		if int(rods[r]) > 0 and not _has_item_in_slots("rod", str(r)):
			_add_item_to_slots("rod", str(r), int(rods[r]), {"tier": str(r)})
	if feed > 0 and not _has_item_in_slots("feed", ""):
		_add_item_to_slots("feed", "", feed)
	for sid in seeds:
		if int(seeds[sid]) > 0 and not _has_item_in_slots("seed", str(sid)):
			_add_item_to_slots("seed", str(sid), int(seeds[sid]))
	for pid in produce:
		if int(produce[pid]) > 0 and not _has_item_in_slots("produce", str(pid)):
			_add_item_to_slots("produce", str(pid), int(produce[pid]))
	for fid in fish:
		if int(fish[fid]) > 0 and not _has_item_in_slots("fish", str(fid)):
			_add_item_to_slots("fish", str(fid), int(fish[fid]))
	for oid in ores:
		if int(ores[oid]) > 0 and not _has_item_in_slots("ore", str(oid)):
			_add_item_to_slots("ore", str(oid), int(ores[oid]))

	sync_active_item_from_hotbar()


func sync_active_item_from_hotbar() -> void:
	_ensure_slots_valid()
	if active_hotbar_index < 0 or active_hotbar_index >= hotbar_slots.size():
		active_hotbar_index = 0
	var slot: Dictionary = hotbar_slots[active_hotbar_index] if not hotbar_slots.is_empty() else {}
	if slot.is_empty() or int(slot.get("qty", 1)) <= 0:
		active_item = {"type": "hand"}
		return

	var t: String = str(slot.get("type", ""))
	match t:
		"hoe":
			active_item = {"type": "hoe", "tier": get_hoe_tier()}
		"watering_can":
			active_item = {"type": "watering_can"}
		"pickaxe":
			active_item = {"type": "pickaxe", "tier": get_pickaxe_tier()}
		"rod":
			active_item = {"type": "rod", "tier": str(slot.get("tier", "basic"))}
		"feed":
			active_item = {"type": "feed"}
		"seed":
			var sid := str(slot.get("id", ""))
			selected_seed = sid
			active_item = {"type": "seed", "id": sid}
		"produce":
			active_item = {"type": "produce", "id": str(slot.get("id", ""))}
		"fish":
			active_item = {"type": "fish", "id": str(slot.get("id", ""))}
		"ore":
			active_item = {"type": "ore", "id": str(slot.get("id", ""))}
		_:
			active_item = {"type": "hand"}


func get_hotbar_slot(idx: int) -> Dictionary:
	_ensure_slots_valid()
	if idx >= 0 and idx < hotbar_slots.size():
		return hotbar_slots[idx]
	return {}


func get_backpack_slot(idx: int) -> Dictionary:
	_ensure_slots_valid()
	if idx >= 0 and idx < backpack_slots.size():
		return backpack_slots[idx]
	return {}


func set_hotbar_slot(idx: int, item: Dictionary) -> void:
	_ensure_slots_valid()
	if idx >= 0 and idx < hotbar_slots.size():
		hotbar_slots[idx] = item.duplicate(true)
		sync_active_item_from_hotbar()
		changed.emit()


func set_backpack_slot(idx: int, item: Dictionary) -> void:
	_ensure_slots_valid()
	if idx >= 0 and idx < backpack_slots.size():
		backpack_slots[idx] = item.duplicate(true)
		changed.emit()


func select_hotbar_slot(idx: int) -> void:
	_ensure_slots_valid()
	active_hotbar_index = clampi(idx, 0, HOTBAR_SIZE - 1)
	sync_active_item_from_hotbar()
	changed.emit()


func cycle_hotbar(delta: int) -> void:
	var next_idx := (active_hotbar_index + delta) % HOTBAR_SIZE
	if next_idx < 0:
		next_idx += HOTBAR_SIZE
	select_hotbar_slot(next_idx)


func move_backpack_to_hotbar(backpack_idx: int) -> bool:
	_ensure_slots_valid()
	if backpack_idx < 0 or backpack_idx >= backpack_slots.size():
		return false
	var item: Dictionary = backpack_slots[backpack_idx]
	if item.is_empty():
		return false

	# 1. Tìm ô trống đầu tiên trong thanh công cụ nhanh (0..8)
	var empty_idx := -1
	for i in hotbar_slots.size():
		if hotbar_slots[i].is_empty():
			empty_idx = i
			break

	if empty_idx != -1:
		hotbar_slots[empty_idx] = item.duplicate(true)
		backpack_slots[backpack_idx] = {}
		select_hotbar_slot(empty_idx)
	else:
		# 2. Thanh công cụ đã đầy -> Thay thế ô đang chọn (active_hotbar_index)
		var cur: Dictionary = hotbar_slots[active_hotbar_index].duplicate(true)
		hotbar_slots[active_hotbar_index] = item.duplicate(true)
		backpack_slots[backpack_idx] = cur
		select_hotbar_slot(active_hotbar_index)

	changed.emit()
	return true


func move_hotbar_to_backpack(hotbar_idx: int) -> bool:
	_ensure_slots_valid()
	if hotbar_idx < 0 or hotbar_idx >= hotbar_slots.size():
		return false
	var item: Dictionary = hotbar_slots[hotbar_idx]
	if item.is_empty():
		return false

	var empty_idx := -1
	for i in backpack_slots.size():
		if backpack_slots[i].is_empty():
			empty_idx = i
			break

	if empty_idx == -1:
		return false

	backpack_slots[empty_idx] = item.duplicate(true)
	hotbar_slots[hotbar_idx] = {}
	sync_active_item_from_hotbar()
	changed.emit()
	return true


func swap_slots(source_area: String, source_idx: int, target_area: String, target_idx: int) -> bool:
	_ensure_slots_valid()
	var src_list := hotbar_slots if source_area == "hotbar" else backpack_slots
	var tgt_list := hotbar_slots if target_area == "hotbar" else backpack_slots

	if source_idx < 0 or source_idx >= src_list.size():
		return false
	if target_idx < 0 or target_idx >= tgt_list.size():
		return false
	if source_area == target_area and source_idx == target_idx:
		return false

	var src_item: Dictionary = src_list[source_idx]
	var tgt_item: Dictionary = tgt_list[target_idx]

	if not src_item.is_empty() and not tgt_item.is_empty() \
		and str(src_item.get("type", "")) == str(tgt_item.get("type", "")) \
		and str(src_item.get("id", "")) == str(tgt_item.get("id", "")) \
		and str(src_item.get("type", "")) in ["seed", "produce", "fish", "ore", "feed", "hoe"]:
		tgt_item["qty"] = int(tgt_item.get("qty", 0)) + int(src_item.get("qty", 0))
		src_list[source_idx] = {}
	else:
		var temp: Dictionary = src_list[source_idx]
		src_list[source_idx] = tgt_list[target_idx]
		tgt_list[target_idx] = temp

	sync_active_item_from_hotbar()
	changed.emit()
	return true


func get_slot_icon(item: Dictionary) -> Texture2D:
	if item.is_empty():
		return null
	var t: String = str(item.get("type", ""))
	match t:
		"hoe":
			return TextureGen.hoe_icon(str(item.get("tier", get_hoe_tier())))
		"watering_can":
			return TextureGen.watering_can_icon()
		"pickaxe":
			return TextureGen.pickaxe_icon(str(item.get("tier", get_pickaxe_tier())))
		"rod":
			return TextureGen.get_tex("fx_rod")
		"feed":
			return TextureGen.get_feed_icon()
		"seed":
			var crop := CropDB.get_crop(str(item.get("id", "")))
			return TextureGen.seed_icon(crop) if not crop.is_empty() else null
		"produce":
			var pid := str(item.get("id", ""))
			if pid == "sau_bo":
				return TextureGen.get_tex("caterpillar")
			var crop := CropDB.get_crop(pid)
			if not crop.is_empty():
				return TextureGen.prod_icon(crop)
			return TextureGen.get_product_icon(pid)
		"fish":
			var f := FishDB.get_fish(str(item.get("id", "")))
			return TextureGen.fish_icon(f.get("color", "#4a90e2")) if not f.is_empty() else null
		"ore":
			return TextureGen.ore_item_icon(str(item.get("id", "")))
	return null


func get_slot_name(item: Dictionary) -> String:
	if item.is_empty():
		return "Ô trống"
	var t: String = str(item.get("type", ""))
	match t:
		"hoe":
			var h := OreDB.get_hoe(str(item.get("tier", get_hoe_tier())))
			return str(h.get("name", "Cuốc đất"))
		"watering_can":
			return "Bình tưới nước"
		"pickaxe":
			var p := OreDB.get_pickaxe(str(item.get("tier", get_pickaxe_tier())))
			return str(p.get("name", "Cúp khai mỏ"))
		"rod":
			return "Cần câu cá"
		"feed":
			return "Túi Cám"
		"seed":
			var crop := CropDB.get_crop(str(item.get("id", "")))
			return "Hạt giống %s" % str(crop.get("name", item.get("id", "")))
		"produce":
			var pid := str(item.get("id", ""))
			if pid == "sau_bo":
				return "Sâu bọ 🐛"
			var crop := CropDB.get_crop(pid)
			if not crop.is_empty():
				return str(crop.get("name", pid))
			var anim := PoultryDB.get_animal(pid)
			if not anim.is_empty():
				return str(anim.get("name", pid))
			return pid.capitalize()
		"fish":
			var f := FishDB.get_fish(str(item.get("id", "")))
			return str(f.get("name", item.get("id", "")))
		"ore":
			var o := OreDB.get_ore(str(item.get("id", "")))
			return str(o.get("name", item.get("id", "")))
	return "Vật phẩm"


func get_slot_desc(item: Dictionary) -> String:
	if item.is_empty():
		return "Ô này hiện chưa chứa vật phẩm nào."
	var t: String = str(item.get("type", ""))
	match t:
		"hoe":
			var h := OreDB.get_hoe(str(item.get("tier", get_hoe_tier())))
			return "Công cụ cày xới đất để gieo hạt.\nTiêu tốn: %.0f⚡ thể lực." % float(h.get("stamina", 8.0))
		"watering_can":
			return "Dùng để tưới nước cho cây trồng.\nTiêu tốn: 5⚡ thể lực mỗi lần tưới.\nLượng nước: %d/%d gáo (ra bờ ao để múc)." % [water_level, water_max]
		"pickaxe":
			var p := OreDB.get_pickaxe(str(item.get("tier", get_pickaxe_tier())))
			return "Dùng khai thác quặng và đập đá trong hầm mỏ.\nSức đập: Cấp %d · Tiêu tốn: %.0f⚡ thể lực." % [get_pickaxe_power(), float(p.get("stamina", 7.0))]
		"rod":
			return "Cần câu dùng để câu cá ở bờ ao.\nTiêu tốn: 15⚡ thể lực mỗi lần quăng cần.\nSố lượt câu còn lại: %d lượt." % total_casts()
		"feed":
			return "Cám cho gia súc, gia cầm Stardew Valley.\nĐến gần chuồng bấm E để cho ăn."
		"seed":
			var crop := CropDB.get_crop(str(item.get("id", "")))
			return "Thời gian lớn: %d giây.\nGiá bán khi thu hoạch: %d xu." % [int(crop.get("grow_sec", 15)), int(crop.get("sell_price", 10))]
		"produce":
			var pid := str(item.get("id", ""))
			if pid == "sau_bo":
				return "Sâu bắt được từ ruộng rau. Dùng làm mồi câu hoặc bán (5 xu)."
			var crop := CropDB.get_crop(pid)
			if not crop.is_empty():
				var food := GameState.get_food_stamina("crop", pid)
				var food_str := "\nĂn hồi phục: +%d⚡ thể lực." % food if food > 0 else ""
				return "Nông sản tươi ngon.\nGiá bán: %d xu.%s" % [int(crop.get("sell_price", 10)), food_str]
			var food := GameState.get_food_stamina("poultry", pid)
			var food_str := "\nĂn hồi phục: +%d⚡ thể lực." % food if food > 0 else ""
			return "Sản phẩm chăn nuôi tươi sống.%s" % food_str
		"fish":
			var f := FishDB.get_fish(str(item.get("id", "")))
			var food := GameState.get_food_stamina("fish", str(item.get("id", "")))
			var food_str := "\nĂn hồi phục: +%d⚡ thể lực." % food if food > 0 else ""
			return "Cá tươi câu từ ao làng.\nGiá bán: %d xu.%s" % [int(f.get("price", 10)), food_str]
		"ore":
			var o := OreDB.get_ore(str(item.get("id", "")))
			return "%s\nGiá bán: %d xu." % [str(o.get("desc", "")), int(o.get("price", 5))]
	return ""


func get_slot_category(item: Dictionary) -> String:
	if item.is_empty():
		return ""
	var t: String = str(item.get("type", ""))
	match t:
		"hoe", "watering_can", "pickaxe", "rod":
			return "Công cụ"
		"feed":
			return "Thức ăn gia súc"
		"seed":
			return "Hạt giống"
		"produce":
			var pid := str(item.get("id", ""))
			if pid == "sau_bo":
				return "Mồi câu / Côn trùng"
			var anim := PoultryDB.get_animal(pid)
			if not anim.is_empty():
				return "Thịt & Sản phẩm"
			return "Nông sản"
		"fish":
			return "Cá tươi"
		"ore":
			return "Khoáng sản & Quặng"
	return "Vật phẩm"


func get_slot_qty(item: Dictionary) -> int:
	if item.is_empty():
		return 0
	var t: String = str(item.get("type", ""))
	match t:
		"watering_can":
			return water_level
		"hoe":
			return hoes
		"rod":
			return total_casts()
		"pickaxe":
			return get_pickaxe_power()
		_:
			return int(item.get("qty", 1))


func feed_count() -> int:
	return feed


func add_feed(n: int = 1) -> void:
	feed += n
	_add_item_to_slots("feed", "", n)
	sync_active_item_from_hotbar()
	changed.emit()


func take_feed(n: int = 1) -> bool:
	if feed >= n:
		feed -= n
		_take_item_from_slots("feed", "", n)
		sync_active_item_from_hotbar()
		changed.emit()
		return true
	return false


func add_seed(id: String, n: int = 1) -> void:
	seeds[id] = int(seeds.get(id, 0)) + n
	_add_item_to_slots("seed", id, n)
	if selected_seed == "":
		selected_seed = id
	sync_active_item_from_hotbar()
	changed.emit()


func add_produce(id: String, n: int = 1) -> void:
	produce[id] = int(produce.get(id, 0)) + n
	_add_item_to_slots("produce", id, n)
	sync_active_item_from_hotbar()
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
			else:
				selected_seed = str(pool[0])
	else:
		seeds[id] = remaining
	_take_item_from_slots("seed", id, n)
	sync_active_item_from_hotbar()
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
	_take_item_from_slots("produce", id, n)
	sync_active_item_from_hotbar()
	changed.emit()
	return true


func seed_count(id: String) -> int:
	return int(seeds.get(id, 0))


func produce_count(id: String) -> int:
	return int(produce.get(id, 0))


# ---- cuốc ----

func add_hoes(n: int = 1) -> void:
	hoes += n
	_add_item_to_slots("hoe", "", n, {"tier": get_hoe_tier()})
	sync_active_item_from_hotbar()
	changed.emit()


func take_hoe() -> bool:
	if hoes < 1:
		return false
	hoes -= 1
	_take_item_from_slots("hoe", "", 1)
	if hoes <= 0 and active_item.get("type", "") == "hoe":
		active_item = get_fallback_tool()
	sync_active_item_from_hotbar()
	changed.emit()
	return true


# ---- bình tưới nước ----

func has_water() -> bool:
	return water_level > 0


func take_water(n: int = 1) -> bool:
	if water_level < n:
		return false
	water_level -= n
	_update_tool_slot_qty("watering_can", water_level)
	changed.emit()
	return true


func refill_water() -> int:
	var added: int = water_max - water_level
	water_level = water_max
	_update_tool_slot_qty("watering_can", water_level)
	changed.emit()
	return added


# ---- cúp đào mỏ (pickaxe) ----

func add_pickaxe(tier: String = "basic") -> void:
	pickaxe = tier
	_add_item_to_slots("pickaxe", "", get_pickaxe_power(), {"tier": tier})
	sync_active_item_from_hotbar()
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
	_add_item_to_slots("ore", id, n)
	sync_active_item_from_hotbar()
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
	_take_item_from_slots("ore", id, n)
	sync_active_item_from_hotbar()
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
	_ensure_slots_valid()
	var count := 0
	for s in backpack_slots:
		if not s.is_empty() and int(s.get("qty", 1)) > 0:
			count += 1
	return count


func can_hold(category: String, id: String) -> bool:
	_ensure_slots_valid()
	var cat_norm := _normalize_cat(category)
	for s in hotbar_slots:
		if not s.is_empty() and _slot_matches_item(s, cat_norm, id):
			return true
	for s in backpack_slots:
		if not s.is_empty() and _slot_matches_item(s, cat_norm, id):
			return true

	for s in hotbar_slots:
		if s.is_empty():
			return true
	for s in backpack_slots:
		if s.is_empty():
			return true
	return false


func _slot_matches_item(slot: Dictionary, category: String, id: String) -> bool:
	var t: String = str(slot.get("type", ""))
	match category:
		"seeds", "seed":
			return t == "seed" and str(slot.get("id", "")) == id
		"produce", "crop", "poultry":
			return t == "produce" and str(slot.get("id", "")) == id
		"fish":
			return t == "fish" and str(slot.get("id", "")) == id
		"ores", "ore":
			return t == "ore" and str(slot.get("id", "")) == id
		"feed", "cam":
			return t == "feed"
		"hoe":
			return t == "hoe"
		"rod":
			return t == "rod"
		"pickaxe":
			return t == "pickaxe"
	return false



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
	for i in hotbar_slots.size():
		var s: Dictionary = hotbar_slots[i]
		if not s.is_empty() and str(s.get("type", "")) == tool_type:
			select_hotbar_slot(i)
			return
	active_item = {"type": tool_type}
	changed.emit()


func select_seed(id: String) -> void:
	if id != "" and seed_count(id) <= 0:
		return
	selected_seed = id
	for i in hotbar_slots.size():
		var s: Dictionary = hotbar_slots[i]
		if not s.is_empty() and str(s.get("type", "")) == "seed" and str(s.get("id", "")) == id:
			select_hotbar_slot(i)
			return
	active_item = {"type": "seed", "id": id} if id != "" else get_fallback_tool()
	changed.emit()


# ---- cần câu ----

func add_rod(tier: String, casts: int) -> void:
	rods[tier] = int(rods.get(tier, 0)) + casts
	_add_item_to_slots("rod", tier, casts, {"tier": tier})
	sync_active_item_from_hotbar()
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
			_take_item_from_slots("rod", tier, 1)
			if total_casts() <= 0 and active_item.get("type", "") == "rod":
				active_item = get_fallback_tool()
			sync_active_item_from_hotbar()
			changed.emit()
			return tier
	return ""


# ---- cá ----

func add_fish(id: String, n: int = 1) -> void:
	fish[id] = int(fish.get(id, 0)) + n
	_add_item_to_slots("fish", id, n)
	sync_active_item_from_hotbar()
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
	_take_item_from_slots("fish", id, n)
	sync_active_item_from_hotbar()
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
		match tier:
			1: return 2
			2: return 4
			3: return 8
			4: return 16
			_: return 16 if tier > 4 else 0
	if species_id == "small":
		return coop_capacity("chicken")
	if species_id == "large":
		return coop_capacity("cow") + coop_capacity("pig") + coop_capacity("sheep")
	return 0


func add_coop(species_id: String) -> void:
	var canon := PoultryDB.get_canonical_id(species_id)
	if coop_tiers.has(canon):
		coop_tiers[canon] = mini(4, get_coop_tier(canon) + 1)
	elif species_id == "small":
		coop_tiers["chicken"] = mini(4, get_coop_tier("chicken") + 1)
	elif species_id == "large":
		for s in ["cow", "pig", "sheep"]:
			if get_coop_tier(s) < 4:
				coop_tiers[s] = mini(4, get_coop_tier(s) + 1)
				break
	changed.emit()
	pens_structure_changed.emit()


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
	pens_structure_changed.emit()
	return ""


func upgrade_coop(species_id: String) -> String:
	var sid := PoultryDB.get_canonical_id(species_id)
	var c := PoultryDB.get_coop_data(sid)
	if c.is_empty():
		return "Loại chuồng không tồn tại!"
	var cur_tier := get_coop_tier(sid)
	if cur_tier < 1:
		return "Cần mua %s Cấp 1 trước!" % str(c.name)
	if cur_tier >= 4:
		return "%s đã đạt cấp tối đa (Cấp 4)!" % str(c.name)
	var next_tier := cur_tier + 1
	var price := PoultryDB.get_coop_upgrade_price(sid, next_tier)
	if not GameState.try_spend(price):
		return "Không đủ xu nâng cấp lên Cấp %d (cần %d xu)!" % [next_tier, price]
	coop_tiers[sid] = next_tier
	changed.emit()
	pens_structure_changed.emit()
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
		if tier < 4:
			return "%s đã kín chỗ (%d/%d con)! Hãy nâng cấp lên Cấp %d." % [cname, animals_of_species(canon_id), coop_capacity(canon_id), tier + 1]
		else:
			return "%s đã đạt giới hạn tối đa (%d/16 con)!" % [cname, animals_of_species(canon_id)]
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
		"times_fed": 0,
	})
	changed.emit()
	pens_structure_changed.emit()
	return ""


# Đồng hồ chăn nuôi:
# - Con non: lớn dần theo thời gian (grow_progress >= GROW_TIME thì thành con lớn)
# - Con lớn: sau khi được cho ăn cám (fed == true), tiến hành tích lũy 90s
#   + Gà, bò, dê/cừu: 50% cho sản phẩm, 50% đói luôn
#   + Lợn: không cho sản phẩm mỗi lần ăn, lập tức đói lại cho lần ăn tiếp theo
#   + Khi cho ăn đủ 5 lần: có thể chém lấy thịt!
# - Ghép đôi: nuôi từ 2 con lớn cùng loài trở lên, đủ thời gian sẽ sinh ra con non baby!
func tick_animals(delta: float) -> void:
	var had_change := false
	var roster_changed := false

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
				roster_changed = true
			continue

		# Con trưởng thành:
		# CHỈ xử lý sau khi đã được cho ăn (fed == true) và chưa có sản phẩm sẵn sàng
		var is_fed: bool = bool(a.get("fed", false))
		var is_ready: bool = int(a.get("ready", 0)) > 0
		if is_fed and not is_ready:
			a.progress = float(a.get("progress", 0.0)) + delta
			var interval: float = float(d.get("interval", 90.0))
			if a.progress >= interval:
				a.progress = 0.0
				if canon_id == "pig":
					# Riêng lợn không cho gì mỗi lần ăn, lập tức đói lại cho lần ăn tiếp theo
					a.ready = 0
					a.fed = false
				else:
					# Gà, bò, dê/cừu: 50% cho sản phẩm, 50% đói luôn
					if randf() < 0.5:
						a.ready = 1
						if canon_id == "sheep":
							a.is_sheared = false
					else:
						a.ready = 0
						a.fed = false
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
						"times_fed": 0,
					})
					baby_born.emit(sid, str(d.name))
					had_change = true
					roster_changed = true

	if had_change:
		changed.emit()
	if roster_changed:
		pens_structure_changed.emit()


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
	a["times_fed"] = int(a.get("times_fed", 0)) + 1
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
					a["times_fed"] = int(a.get("times_fed", 0)) + 1
					fed_cnt += 1
				else:
					break
	if fed_cnt > 0:
		changed.emit()
	return fed_cnt


# Chém 1 con vật lấy thịt khi đã cho ăn đủ ít nhất 5 lần:
# - Cần con trưởng thành và times_fed >= 5
# - Kiểm tra túi đồ có thể chứa thịt
# - Xóa con vật khỏi chuồng và cộng thịt vào kho/túi đồ
func slaughter_animal(a: Dictionary) -> Dictionary:
	var idx := animals.find(a)
	if idx < 0:
		return {"ok": false, "msg": "Không tìm thấy con vật trong chuồng!"}
	if bool(a.get("is_baby", false)):
		return {"ok": false, "msg": "Con non chưa thể lấy thịt!"}
	var fed_cnt: int = int(a.get("times_fed", 0))
	if fed_cnt < 5:
		return {"ok": false, "msg": "Cần cho ăn ít nhất 5 lần trước khi lấy thịt (hiện tại: %d/5 lần)!" % fed_cnt}

	var canon_id := PoultryDB.get_canonical_id(str(a.get("id", "")))
	var meat_id := PoultryDB.get_animal_meat_id(canon_id)
	var meat_qty := PoultryDB.get_animal_meat_qty(canon_id)
	if not can_hold("produce", meat_id):
		return {"ok": false, "msg": "Túi đồ đã đầy (%d/%d)! Vui lòng dọn bớt đồ trước khi lấy thịt." % [backpack_slots_used(), backpack_max]}

	animals.remove_at(idx)
	add_produce(meat_id, meat_qty)
	changed.emit()
	pens_structure_changed.emit()
	return {"ok": true, "meat_id": meat_id, "qty": meat_qty, "species_id": canon_id}


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
		"storage": storage.duplicate(true),
		"hotbar_slots": hotbar_slots.duplicate(true),
		"backpack_slots": backpack_slots.duplicate(true),
		"active_hotbar_index": active_hotbar_index
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
	backpack_max = clampi(int(d.get("backpack_max", BACKPACK_DEFAULT_SIZE)), BACKPACK_DEFAULT_SIZE, BACKPACK_MAX_LIMIT)
	if d.has("hotbar_slots") and d["hotbar_slots"] is Array:
		hotbar_slots = (d["hotbar_slots"] as Array).duplicate(true)
	else:
		hotbar_slots = []
		for i in HOTBAR_SIZE: hotbar_slots.append({})
	if d.has("backpack_slots") and d["backpack_slots"] is Array:
		backpack_slots = (d["backpack_slots"] as Array).duplicate(true)
	else:
		backpack_slots = []
		for i in backpack_max: backpack_slots.append({})
	_ensure_slots_valid()
	active_hotbar_index = int(d.get("active_hotbar_index", 0))
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
				"times_fed": int(a.get("times_fed", 0)),
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
	sync_slots_from_pools()
	if d.has("active_item") and d["active_item"] is Dictionary:
		active_item = (d["active_item"] as Dictionary).duplicate()
	else:
		sync_active_item_from_hotbar()
	changed.emit()
	pens_structure_changed.emit()

