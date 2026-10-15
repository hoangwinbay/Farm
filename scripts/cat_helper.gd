extends Node2D
# Chú Mèo Tam Thể làm nông (Calico Cat Helper):
# - Xuất phát từ đường bên trái đến trước cửa nhà người chơi và dừng lại với bong bóng 3 chấm (...).
# - Người chơi tương tác [E] để thuê (50 xu/ngày).
# - Nhiệm vụ:
#   1. Gieo hạt (từ số hạt người chơi giao).
#   2. Tưới nước cho cây (khi hết nước tự ra bờ ao múc).
#   3. Bắt sâu bọ cắn phá cây.
#   4. Thu hoạch nông sản khi chín.
#   5. Cất toàn bộ nông sản & sâu bọ vào Nhà Kho (Shed).
# - Cuối ngày (19:00 hoặc khi người chơi ngủ) nhận lương và vào lều Stardew Valley để ngủ.

const TextureGen := preload("res://scripts/texture_gen.gd")
const FarmTileScript := preload("res://scripts/farm_tile.gd")
const CropDB := preload("res://scripts/crop_db.gd")

signal toast_requested(text: String, color: Color)
signal hired
signal action_performed(act_type: String, target_id: String)

enum State {
	ARRIVING,
	WAITING_HIRE,
	IDLE,
	WALKING_TO_JOB,
	WORKING,
	WALKING_TO_POND,
	REFILLING,
	WALKING_TO_SHED,
	DEPOSITING,
	WALKING_TO_TENT,
	SLEEPING,
	WALKING_TO_MINE,
	MINING
}

const WAITING_POS := Vector2(618, 305)
const DOORSTEP_POS := Vector2(656, 260)
const ROAD_JUNCTION_POS := Vector2(656, 472)
const SPAWN_POS := Vector2(370, 472)
const JUNIMO_HUT_SLEEP_POS := Vector2(1365, 195)
const TENT_SLEEP_POS := JUNIMO_HUT_SLEEP_POS
const SHED_DOOR_POS := Vector2(505, 258)
const POND_REFILL_POS := Vector2(1440, 730)
const POND_FISHING_POS := Vector2(1245, 860)
const FARM_GATE_WEST := Vector2(824, 472)
const MID_ROAD_POS := Vector2(1048, 472)
const EAST_ROAD_POS := Vector2(1365, 472)
const NORTH_GATE_INNER := Vector2(1048, 420)
const NORTH_GATE_POS := Vector2(1048, 446)
const SOUTH_GATE_INNER := Vector2(1048, 524)
const SOUTH_GATE_POS := Vector2(1048, 498)
const MINE_ENTRANCE_DOOR := Vector2(96, 68)
const MINE_INSIDE_POS := Vector2(96, 56)
const MINE_PATH_APPROACH := Vector2(96, 110)
const MINE_WORKING_POS := MINE_ENTRANCE_DOOR
const MINE_ROAD_JUNCTION := Vector2(96, 472)
const STALL_SELLER_POS := Vector2(532, 444)

var state: int = State.ARRIVING
var is_hired: bool = false
var cat_breed: String = "calico":
	set(v):
		cat_breed = v
		if v == "orange":
			cat_name = "Mèo Mướp Vàng"
			cat_role = "gardener"
			daily_wage = 50
		elif v == "white":
			cat_name = "Mèo Trắng Tuyết"
			cat_role = "fisher"
			daily_wage = 75
		elif v == "tuxedo":
			cat_name = "Mèo Mun Tuxedo"
			cat_role = "seller"
			daily_wage = 80
		else:
			cat_name = "Mèo Tam Thể"
			cat_role = "miner"
			daily_wage = 100
var cat_name: String = "Mèo Tam Thể"
var cat_role: String = "miner" # "gardener", "miner", "fisher", hoặc "seller"
var other_cat: Node2D = null
var other_cats: Array = []
var speed: float = 42.0
var work_timer: float = 0.0
var anim_t: float = 0.0
var facing_dir: String = "down"
var _mining_hits: int = 0
var is_underground: bool = false

func get_sleep_pos() -> Vector2:
	if cat_breed == "orange":
		return Vector2(1385, 195)
	elif cat_breed == "white":
		return Vector2(1345, 195)
	elif cat_breed == "tuxedo":
		return Vector2(1365, 175)
	return JUNIMO_HUT_SLEEP_POS

func get_entrance_pos() -> Vector2:
	if cat_breed == "orange":
		return Vector2(1385, 235)
	elif cat_breed == "white":
		return Vector2(1345, 235)
	elif cat_breed == "tuxedo":
		return Vector2(1365, 235)
	return Vector2(1365, 235)

func _tex(anim: String, frame_idx: int = 0) -> Texture2D:
	return TextureGen.cat_char_tex(anim, frame_idx, cat_breed)

var speed_level: int = 1
var work_level: int = 1
var bag_level: int = 1
const MAX_UPGRADE_LEVEL := 5

var water_capacity: int = 15
var water_level: int = 15
var assigned_hoes: int = 0
var assigned_rods: int = 0
var assigned_seeds: Dictionary = {}  # seed_id -> count
var harvest_bag: Dictionary = {}     # item_id -> count
var sell_targets: Dictionary = {}    # item_id -> int
var total_sales_revenue: int = 0
var stall_manager = null
var _stall_timer: float = 0.0
var daily_wage: int = 50
var wage_paid_today: bool = false

var farm: Node2D = null
var mine_manager: Node2D = null
var current_job: Dictionary = {}
var waypoints: Array = []
var _target_tile: Node = null
var _target_rock: Dictionary = {}


func get_cat_mining_power() -> int:
	match work_level:
		1, 2: return 1
		3, 4: return 2
		5: return 3
		_: return 1


func _get_mine_manager() -> Node2D:
	if is_instance_valid(mine_manager):
		return mine_manager
	if get_parent() != null and get_parent().has_method("break_rock_for_cat"):
		return get_parent() as Node2D
	if has_node("/root/Main"):
		var m = get_node("/root/Main")
		if "mine_manager" in m and is_instance_valid(m.mine_manager):
			return m.mine_manager
	if get_tree() != null and get_tree().root != null:
		for c in get_tree().root.get_children():
			if "mine_manager" in c and is_instance_valid(c.mine_manager):
				return c.mine_manager
	return null


func _is_player_in_mine() -> bool:
	var mm := _get_mine_manager()
	if mm != null:
		if mm.has_method("is_player_in_mine"):
			return mm.is_player_in_mine()
		if mm.main_game != null and "in_mine" in mm.main_game:
			return bool(mm.main_game.in_mine)
		return mm.visible
	if has_node("/root/Main"):
		var m = get_node("/root/Main")
		if "in_mine" in m:
			return bool(m.in_mine)
	return false


func _get_stall_manager():
	if is_instance_valid(stall_manager):
		return stall_manager
	if has_node("/root/Main"):
		var m = get_node("/root/Main")
		if "stall_manager" in m and is_instance_valid(m.stall_manager):
			stall_manager = m.stall_manager
			return stall_manager
	if get_tree() != null and get_tree().root != null:
		for c in get_tree().root.get_children():
			if "stall_manager" in c and is_instance_valid(c.stall_manager):
				stall_manager = c.stall_manager
				return stall_manager
	return null


func _get_sellable_item_info(item_id: String) -> Dictionary:
	var CropDB = load("res://scripts/crop_db.gd")
	var FishDB = load("res://scripts/fish_db.gd")
	var PoultryDB = load("res://scripts/poultry_db.gd")
	var OreDB = load("res://scripts/ore_db.gd")

	var c: Dictionary = CropDB.get_crop(item_id)
	if not c.is_empty():
		return {"id": item_id, "type": "crop", "name": str(c.get("name", item_id)), "price": int(c.get("sell_price", 10))}

	var f: Dictionary = FishDB.get_fish(item_id)
	if not f.is_empty():
		return {"id": item_id, "type": "fish", "name": str(f.get("name", item_id)), "price": int(f.get("price", 10))}

	var p: Dictionary = PoultryDB.get_product(item_id)
	if not p.is_empty():
		return {"id": item_id, "type": "poultry", "name": str(p.get("name", item_id)), "price": int(p.get("price", 10))}

	var o: Dictionary = OreDB.get_ore(item_id)
	if not o.is_empty():
		return {"id": item_id, "type": "ore", "name": str(o.get("name", item_id)), "price": int(o.get("price", 10))}

	return {"id": item_id, "type": "crop", "name": item_id, "price": 10}


func set_sell_target(item_id: String, qty: int) -> void:
	if qty <= 0:
		sell_targets.erase(item_id)
	else:
		sell_targets[item_id] = qty
	if (cat_breed == "tuxedo" or cat_role == "seller") and is_hired:
		if state == State.IDLE or state == State.WALKING_TO_TENT:
			if GameState.clock < get_sleep_clock() and GameState.clock >= GameState.DAY_START:
				_find_next_seller_job()


func adjust_sell_target(item_id: String, delta: int) -> void:
	var cur: int = int(sell_targets.get(item_id, 0))
	var new_v: int = maxi(0, cur + delta)
	set_sell_target(item_id, new_v)


func get_sell_target(item_id: String) -> int:
	return int(sell_targets.get(item_id, 0))


func clear_all_sell_targets() -> void:
	sell_targets.clear()


func _find_restockable_item(sm = null) -> Dictionary:
	if sm == null:
		sm = _get_stall_manager()
	if sm == null or not ("stall_slots" in sm):
		return {}
	var slot_limit := get_stall_slot_limit()
	for item_id in sell_targets.keys():
		var target: int = int(sell_targets[item_id])
		if target <= 0:
			continue
		var cur_on_stall: int = 0
		var existing_slot_idx: int = -1
		var empty_slot_idx: int = -1
		for i in sm.stall_slots.size():
			var s = sm.stall_slots[i]
			if typeof(s) == TYPE_DICTIONARY and not s.is_empty():
				if str(s.get("id", "")) == str(item_id):
					cur_on_stall += int(s.get("count", 0))
					existing_slot_idx = i
			elif empty_slot_idx < 0:
				empty_slot_idx = i

		var max_allowed := mini(target, slot_limit)
		var cur_carrying := int(harvest_bag.get(item_id, 0))
		var total_present := cur_on_stall + cur_carrying
		if total_present < max_allowed and (existing_slot_idx >= 0 or empty_slot_idx >= 0):
			var info := _get_sellable_item_info(str(item_id))
			var cat_type: String = str(info.get("type", "crop"))
			var cat_key := Inventory._normalize_cat(cat_type)
			var in_storage := Inventory.storage_count(cat_key, str(item_id))
			if in_storage > 0:
				var need := max_allowed - total_present
				var to_take := mini(need, in_storage)
				return {
					"item_id": str(item_id),
					"cat_type": cat_type,
					"info": info,
					"need": need,
					"to_take": to_take,
					"existing_slot_idx": existing_slot_idx,
					"empty_slot_idx": empty_slot_idx
				}
	return {}


func has_seller_work() -> bool:
	if _total_bag_items() > 0:
		return true
	var sm = _get_stall_manager()
	if sm == null:
		return false
	if int(sm.stall_revenue) > 0:
		return true
	var restock := _find_restockable_item(sm)
	if not restock.is_empty():
		return true
	return false


func _withdraw_items_from_shed() -> void:
	var sm = _get_stall_manager()
	if sm == null or not ("stall_slots" in sm):
		return
	var slot_limit := get_stall_slot_limit()
	var max_carry := get_max_bag()
	var any_taken := false

	for item_id in sell_targets.keys():
		if _total_bag_items() >= max_carry:
			break
		var target: int = int(sell_targets[item_id])
		if target <= 0:
			continue
		var cur_on_stall: int = 0
		var existing_slot_idx: int = -1
		var empty_slot_idx: int = -1
		for i in sm.stall_slots.size():
			var s = sm.stall_slots[i]
			if typeof(s) == TYPE_DICTIONARY and not s.is_empty():
				if str(s.get("id", "")) == str(item_id):
					cur_on_stall += int(s.get("count", 0))
					existing_slot_idx = i
			elif empty_slot_idx < 0:
				empty_slot_idx = i

		var max_allowed := mini(target, slot_limit)
		var cur_carrying := int(harvest_bag.get(item_id, 0))
		var total_present := cur_on_stall + cur_carrying
		if total_present < max_allowed and (existing_slot_idx >= 0 or empty_slot_idx >= 0):
			var space_in_slot := max_allowed - total_present
			var space_in_bag := max_carry - _total_bag_items()
			var need := mini(space_in_slot, space_in_bag)
			if need <= 0:
				continue
			var info := _get_sellable_item_info(str(item_id))
			var cat_type: String = str(info.get("type", "crop"))
			var cat_key := Inventory._normalize_cat(cat_type)
			var in_storage := Inventory.storage_count(cat_key, str(item_id))
			if in_storage > 0:
				var take_n := mini(need, in_storage)
				# Lấy strictly từ Kho lưu trữ (warehouse storage)!
				var taken := Inventory.take_from_storage(cat_type, str(item_id), take_n)
				if taken > 0:
					harvest_bag[item_id] = cur_carrying + taken
					any_taken = true
					toast_requested.emit("%s đã lấy ×%d %s từ Nhà Kho để mang ra sạp! 📦🧺" % [cat_name, taken, str(info.get("name", item_id))], Color(0.65, 0.95, 0.65))

	if any_taken:
		_show_bubble_text("🧺")


func _is_rock_valid(rock_data: Dictionary) -> bool:
	if rock_data.is_empty():
		return false
	var mm := _get_mine_manager()
	if mm == null or not (rock_data in mm._rocks_data):
		return false
	var body = rock_data.get("body")
	return is_instance_valid(body) and int(rock_data.get("hits_left", 0)) > 0


func _find_nearest_mine_rock() -> Dictionary:
	var mm := _get_mine_manager()
	if mm == null:
		return {}
	mm.ensure_floor_ready(mm.current_floor)
	var best_rock := {}
	var min_dist := INF
	for r in mm._rocks_data:
		if not _is_rock_valid(r):
			continue
		var pt: Vector2i = r.get("pos_tile", Vector2i.ZERO)
		var r_pos := Vector2(pt.x * 32 + 16, pt.y * 32 + 16)
		var d := position.distance_to(r_pos)
		if d < min_dist:
			min_dist = d
			best_rock = r
	return best_rock


func _get_rock_stand_pos(rock_pos: Vector2) -> Vector2:
	var stand := rock_pos + Vector2(0, 18)
	if rock_pos.y >= 13 * 32:
		stand = rock_pos + Vector2(0, -18)
	return stand


func get_speed_for_level(lvl: int) -> float:
	match lvl:
		1: return 42.0
		2: return 65.0
		3: return 92.0
		4: return 120.0
		5: return 155.0
		_: return 155.0


func get_work_duration() -> float:
	match work_level:
		1: return 0.70
		2: return 0.50
		3: return 0.38
		4: return 0.28
		5: return 0.20
		_: return 0.20


func get_mining_cycle_duration() -> float:
	match work_level:
		1: return 1.10
		2: return 0.85
		3: return 0.65
		4: return 0.48
		5: return 0.35
		_: return 0.35


func _pick_mined_ore() -> String:
	var r := randf() * 100.0
	match work_level:
		1:
			if r < 50.0: return "stone"
			elif r < 80.0: return "coal"
			else: return "copper_ore"
		2:
			if r < 38.0: return "stone"
			elif r < 68.0: return "coal"
			elif r < 88.0: return "copper_ore"
			else: return "iron_ore"
		3:
			if r < 30.0: return "stone"
			elif r < 55.0: return "coal"
			elif r < 75.0: return "copper_ore"
			elif r < 92.0: return "iron_ore"
			else: return "gold_ore"
		4:
			if r < 24.0: return "stone"
			elif r < 46.0: return "coal"
			elif r < 66.0: return "copper_ore"
			elif r < 84.0: return "iron_ore"
			elif r < 95.0: return "gold_ore"
			else: return "ruby"
		5:
			if r < 18.0: return "stone"
			elif r < 38.0: return "coal"
			elif r < 58.0: return "copper_ore"
			elif r < 76.0: return "iron_ore"
			elif r < 90.0: return "gold_ore"
			elif r < 97.0: return "ruby"
			else: return "diamond"
		_:
			return "stone"


func _get_ore_display_name(ore_id: String) -> String:
	match ore_id:
		"stone": return "Đá cuội"
		"coal": return "Than đá"
		"copper_ore": return "Quặng Đồng"
		"iron_ore": return "Quặng Sắt"
		"gold_ore": return "Quặng Vàng"
		"ruby": return "Hồng Ngọc (Ruby)"
		"diamond": return "Kim Cương"
		_: return "Khoáng sản"


func get_rod_name(lvl: int = -1) -> String:
	if lvl < 1:
		lvl = work_level
	match lvl:
		1: return "Cần Tre Sơ Cấp"
		2: return "Cần Gỗ Trung Cấp"
		3: return "Cần Sợi Thủy Tinh"
		4: return "Cần Carbon Bậc Thầy"
		5: return "Cần Câu Thần Thoại"
		_: return "Cần Câu Thần Thoại"


func get_rod_fail_rate(lvl: int = -1) -> float:
	if lvl < 1:
		lvl = work_level
	match lvl:
		1: return 0.35
		2: return 0.20
		3: return 0.10
		4: return 0.03
		5: return 0.0
		_: return 0.0


func get_fishing_cycle_duration() -> float:
	match work_level:
		1: return 3.2
		2: return 2.4
		3: return 1.8
		4: return 1.3
		5: return 0.9
		_: return 0.9


func _pick_fished_item() -> String:
	var FishDB = load("res://scripts/fish_db.gd")
	var night: bool = GameState.clock < GameState.DAY_START or GameState.clock >= 1140.0
	var r := randf()
	var tier := "common"
	match work_level:
		1:
			if r < 0.85: tier = "common"
			else: tier = "mid"
		2:
			if r < 0.55: tier = "common"
			elif r < 0.95: tier = "mid"
			else: tier = "rare"
		3:
			if r < 0.35: tier = "common"
			elif r < 0.75: tier = "mid"
			elif r < 0.97: tier = "rare"
			else: tier = "legend"
		4:
			if r < 0.20: tier = "common"
			elif r < 0.55: tier = "mid"
			elif r < 0.92: tier = "rare"
			else: tier = "legend"
		5:
			if r < 0.10: tier = "common"
			elif r < 0.40: tier = "mid"
			elif r < 0.80: tier = "rare"
			else: tier = "legend"
		_:
			tier = "common"
	var fish_dict: Dictionary = FishDB.pick_fish(tier, night)
	return str(fish_dict.get("id", "ro_dong"))


func get_refill_duration() -> float:
	match work_level:
		1: return 1.00
		2: return 0.75
		3: return 0.55
		4: return 0.40
		5: return 0.25
		_: return 0.25


func get_deposit_duration() -> float:
	match work_level:
		1: return 0.80
		2: return 0.60
		3: return 0.45
		4: return 0.35
		5: return 0.25
		_: return 0.25


func get_sleep_clock() -> float:
	return get_sleep_clock_for_level(work_level)


func get_sleep_clock_for_level(lvl: int) -> float:
	match lvl:
		1: return 1140.0 # 19:00
		2: return 1200.0 # 20:00
		3: return 1260.0 # 21:00
		4: return 1320.0 # 22:00
		5: return 1380.0 # 23:00
		_: return 1380.0


func get_max_bag() -> int:
	return get_max_bag_for_level(bag_level)


func get_stall_slot_limit() -> int:
	return get_stall_slot_limit_for_level(bag_level)


static func get_stall_slot_limit_for_level(lvl: int) -> int:
	match lvl:
		1: return 10
		2: return 15
		3: return 20
		4: return 30
		5: return 50
		_: return 50


func get_max_bag_for_level(lvl: int) -> int:
	if cat_breed == "tuxedo" or cat_role == "seller":
		return get_stall_slot_limit_for_level(lvl)
	match lvl:
		1: return 5
		2: return 10
		3: return 18
		4: return 28
		5: return 45
		_: return 45


func get_water_capacity_for_level(lvl: int) -> int:
	match lvl:
		1: return 15
		2: return 25
		3: return 40
		4: return 60
		5: return 90
		_: return 90


func get_upgrade_cost(type: String, cur_lvl: int) -> int:
	if cur_lvl >= MAX_UPGRADE_LEVEL:
		return -1
	match type:
		"speed":
			var costs := [80, 180, 320, 500]
			return costs[cur_lvl - 1]
		"work":
			var costs := [100, 220, 380, 550]
			return costs[cur_lvl - 1]
		"bag":
			var costs := [90, 200, 350, 500]
			return costs[cur_lvl - 1]
		_:
			return 100


func upgrade(type: String) -> bool:
	var cur_lvl := 1
	match type:
		"speed": cur_lvl = speed_level
		"work": cur_lvl = work_level
		"bag": cur_lvl = bag_level
	if cur_lvl >= MAX_UPGRADE_LEVEL:
		return false
	var cost := get_upgrade_cost(type, cur_lvl)
	if cost <= 0 or not GameState.try_spend(cost):
		return false
	match type:
		"speed":
			speed_level += 1
			speed = get_speed_for_level(speed_level)
			toast_requested.emit("Nâng cấp Tốc độ Mèo lên Cấp %d! ⚡ (%.0f px/s)" % [speed_level, speed], Color(1.0, 0.85, 0.35))
		"work":
			work_level += 1
			var sleep_hr := int(get_sleep_clock() / 60.0)
			if cat_role == "fisher":
				var rname := get_rod_name(work_level)
				var rfail := int(get_rod_fail_rate(work_level) * 100)
				toast_requested.emit("Nâng cấp Cần câu lên %s! 🎣 (Hụt còn %d%%, câu đến %02d:00)" % [rname, rfail, sleep_hr], Color(0.4, 0.85, 1.0))
			elif cat_role == "miner":
				toast_requested.emit("Nâng cấp Năng suất Mỏ lên Cấp %d! ⏱️ (Làm việc đến %02d:00)" % [work_level, sleep_hr], Color(0.95, 0.85, 0.4))
			else:
				toast_requested.emit("Nâng cấp Năng suất Mèo lên Cấp %d! ⏱️ (Làm việc đến %02d:00)" % [work_level, sleep_hr], Color(0.65, 1.0, 0.65))
		"bag":
			bag_level += 1
			water_capacity = get_water_capacity_for_level(bag_level)
			water_level = water_capacity
			if cat_role == "seller":
				toast_requested.emit("Nâng cấp Sức chứa Ô Sạp & Vận Chuyển lên Cấp %d! 🎒 (Tối đa %d món/ô sạp)" % [bag_level, get_stall_slot_limit()], Color(1.0, 0.88, 0.4))
			elif cat_role == "fisher":
				toast_requested.emit("Nâng cấp Giỏ cá của Mèo lên Cấp %d! 🎒 (Chứa tối đa %d con cá)" % [bag_level, get_max_bag()], Color(0.4, 0.85, 1.0))
			elif cat_role == "miner":
				toast_requested.emit("Nâng cấp Túi khoáng sản lên Cấp %d! 🎒 (Chứa tối đa %d quặng)" % [bag_level, get_max_bag()], Color(0.95, 0.85, 0.4))
			else:
				toast_requested.emit("Nâng cấp Túi đồ Mèo lên Cấp %d! 🎒 (Túi %d món, Bình %d giọt)" % [bag_level, get_max_bag(), water_capacity], Color(0.4, 0.85, 1.0))
	return true

var _spr: Sprite2D
var _shadow: Sprite2D
var _bubble: PanelContainer
var _bubble_label: Label
var bubble_text: String:
	get: return _bubble_label.text if _bubble_label != null else ""
var _bubble_icon: TextureRect
var _bubble_tween: Tween
var _scan_timer: float = 0.0
var _last_h_dir: float = 1.0


func _ready() -> void:
	z_as_relative = true

	# 1. Bóng đổ chân nhân vật
	_shadow = Sprite2D.new()
	_shadow.texture = TextureGen.get_tex("shadow")
	_shadow.scale = Vector2(0.9, 0.7)
	_shadow.position = Vector2(0, 0)
	add_child(_shadow)

	# 2. Sprite chú mèo
	if cat_breed == "orange":
		cat_name = "Mèo Mướp Vàng"
		cat_role = "gardener"
		daily_wage = 50
	elif cat_breed == "white":
		cat_name = "Mèo Trắng Tuyết"
		cat_role = "fisher"
		daily_wage = 75
	elif cat_breed == "tuxedo":
		cat_name = "Mèo Mun Tuxedo"
		cat_role = "seller"
		daily_wage = 80
	else:
		cat_name = "Mèo Tam Thể"
		cat_role = "miner"
		daily_wage = 100

	_spr = Sprite2D.new()
	_spr.scale = Vector2(1.25, 1.25)
	_spr.offset = Vector2(0, -16)
	_spr.texture = _tex("down", 0)
	add_child(_spr)

	# 3. Bong bóng suy nghĩ / thông báo trên đầu
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override("panel", _make_bubble_style())
	_bubble.position = Vector2(-14, -58)
	_bubble.pivot_offset = Vector2(14, 10)
	_bubble.resized.connect(func():
		_bubble.position.x = -_bubble.size.x / 2.0
		_bubble.pivot_offset = _bubble.size / 2.0
	)
	add_child(_bubble)

	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 2)
	_bubble.add_child(bh)

	_bubble_label = Label.new()
	_bubble_label.text = "..."
	_bubble_label.add_theme_font_size_override("font_size", 10)
	_bubble_label.add_theme_color_override("font_color", Color(0.18, 0.12, 0.08))
	_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bh.add_child(_bubble_label)

	_bubble_icon = TextureRect.new()
	_bubble_icon.custom_minimum_size = Vector2(12, 12)
	_bubble_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_bubble_icon.visible = false
	bh.add_child(_bubble_icon)

	_start_bubble_bob()

	# Khởi động lộ trình vào nông trại
	if not is_hired:
		if cat_breed == "calico":
			position = SPAWN_POS
			state = State.ARRIVING
			waypoints = [ROAD_JUNCTION_POS, Vector2(ROAD_JUNCTION_POS.x, WAITING_POS.y), WAITING_POS]
			_show_bubble_text("...")
			visible = true
		else:
			position = get_sleep_pos()
			state = State.WAITING_HIRE
			visible = false
			_hide_bubble()
	else:
		position = get_sleep_pos()
		state = State.IDLE
		visible = false
		_hide_bubble()


func _process(delta: float) -> void:
	# Kiểm tra giờ đi ngủ vào buổi tối (dựa trên cấp độ thời gian làm việc)
	if is_hired and GameState.clock >= get_sleep_clock():
		if state != State.WALKING_TO_TENT and state != State.SLEEPING:
			_pay_daily_wage()
			if position.distance_to(get_sleep_pos()) <= 15.0:
				state = State.SLEEPING
				visible = false
				_hide_bubble()
			else:
				state = State.WALKING_TO_TENT
				_set_destination(get_sleep_pos())
				_show_bubble_text("😴")

	# Kiểm tra trời sáng (từ 7:00 sáng)
	if state == State.SLEEPING and GameState.clock < get_sleep_clock() and GameState.clock >= GameState.DAY_START:
		wage_paid_today = false
		state = State.IDLE
		visible = false
		_hide_bubble()

	match state:
		State.ARRIVING:
			_process_walk(delta, func():
				# Đến trước cửa nhà người chơi
				state = State.WAITING_HIRE
				facing_dir = "down"
				_spr.texture = _tex("down", 0)
				_spr.flip_h = false
				_show_bubble_text("...")
			)

		State.WAITING_HIRE:
			_spr.texture = _tex("down", 0)
			# Đứng chờ người chơi đến phỏng vấn / thuê

		State.IDLE:
			_scan_timer += delta
			if _scan_timer >= 0.5:
				_scan_timer = 0.0
				_find_next_job()

		State.WALKING_TO_JOB:
			_process_walk(delta, func():
				if cat_role == "miner":
					if _is_rock_valid(_target_rock):
						state = State.MINING
						work_timer = 0.0
						_mining_hits = 0
						var pt: Vector2i = _target_rock.get("pos_tile", Vector2i.ZERO)
						var r_pos := Vector2(pt.x * 32 + 16, pt.y * 32 + 16)
						if r_pos.y < position.y:
							facing_dir = "up"
							_spr.texture = _tex("up", 0)
						elif r_pos.y > position.y:
							facing_dir = "down"
							_spr.texture = _tex("down", 0)
						elif r_pos.x < position.x:
							facing_dir = "side"
							_spr.texture = _tex("side", 0)
							_spr.flip_h = true
						else:
							facing_dir = "side"
							_spr.texture = _tex("side", 0)
							_spr.flip_h = false
						_spr.offset = Vector2(0, -20)
						_show_bubble_text("⛏️")
					else:
						_target_rock = {}
						state = State.IDLE
						_find_next_mining_job()
					return

				state = State.WORKING
				work_timer = 0.0
				var jtype: String = str(current_job.get("type", ""))
				if jtype == "till":
					_spr.texture = _tex("till", 0)
					_spr.offset = Vector2(0, -20)
					_spr.flip_h = (_last_h_dir < 0)
				elif jtype == "water":
					_spr.texture = _tex("water", 0)
					_spr.offset = Vector2(0, -20)
					_spr.flip_h = (_last_h_dir < 0)
				elif jtype == "fish":
					_spr.texture = _tex("fish", 0)
					_spr.offset = Vector2(0, -20)
					_spr.flip_h = false
					_last_h_dir = 1.0
					facing_dir = "right"
					_show_bubble_text("🎣")
					if has_node("/root/AudioManager"):
						get_node("/root/AudioManager").play_sfx("fish_cast")
				elif jtype == "sell":
					_spr.texture = _tex("right", 0)
					_spr.offset = Vector2(0, -16)
					_spr.flip_h = false
					_last_h_dir = 1.0
					facing_dir = "right"
					_show_bubble_text("🏪")
				else:
					_spr.texture = _tex("act", 0)
					_spr.offset = Vector2(0, -16)
			)

		State.WORKING:
			work_timer += delta
			var jtype: String = str(current_job.get("type", ""))
			if jtype == "till":
				var progress: float = clampf(work_timer / get_work_duration(), 0.0, 0.999)
				var till_frame: int = int(progress * 4.0)
				_spr.texture = _tex("till", till_frame)
				_spr.offset = Vector2(0, -20)
				_spr.flip_h = (_last_h_dir < 0)
			elif jtype == "water":
				var progress: float = clampf(work_timer / get_work_duration(), 0.0, 0.999)
				var water_frame: int = int(progress * 4.0)
				_spr.texture = _tex("water", water_frame)
				_spr.offset = Vector2(0, -20)
				_spr.flip_h = (_last_h_dir < 0)
			elif jtype == "fish":
				var fish_dur: float = get_fishing_cycle_duration()
				var progress: float = clampf(work_timer / fish_dur, 0.0, 0.999)
				var f_idx: int = 0
				if progress < 0.20:
					f_idx = 0
				elif progress < 0.45:
					f_idx = 1
				elif progress < 0.80:
					f_idx = 2
				else:
					f_idx = 3
					if fmod(work_timer, 0.5) < delta:
						_show_bubble_text("❗")
				_spr.texture = _tex("fish", f_idx)
				_spr.offset = Vector2(0, -20)
				_spr.flip_h = false
				if f_idx >= 2 and fmod(work_timer, 0.8) < delta:
					_spawn_water_ripple_near_pond()
			elif jtype == "sell":
				_spr.offset = Vector2(0, -16)
				_spr.flip_h = false
				_spr.texture = _tex("right", 0)
				_stall_timer += delta
				if _stall_timer >= 1.5:
					_stall_timer = 0.0
					_process_stall_work()
				if GameState.clock >= get_sleep_clock():
					state = State.WALKING_TO_TENT
					_set_destination(get_sleep_pos())
					_show_bubble_text("😴")
					return
			else:
				_spr.texture = _tex("act", 0)
				_spr.offset = Vector2(0, -16)

			if jtype != "sell":
				var cur_dur: float = get_fishing_cycle_duration() if jtype == "fish" else get_work_duration()
				if work_timer >= cur_dur:
					_complete_job()
					if state != State.WALKING_TO_SHED and state != State.WALKING_TO_TENT:
						state = State.IDLE
						_spr.offset = Vector2(0, -16)
						_spr.flip_h = false
						_hide_bubble()

		State.WALKING_TO_POND:
			_process_walk(delta, func():
				state = State.REFILLING
				work_timer = 0.0
				_spr.texture = _tex("act", 0)
				_show_bubble_text("💧+")
			)

		State.REFILLING:
			work_timer += delta
			_spr.texture = _tex("act", 0)
			if work_timer >= get_refill_duration():
				water_level = water_capacity
				state = State.IDLE
				_hide_bubble()
				toast_requested.emit("%s đã múc đầy bình nước từ ao! 💧 (%d/%d)" % [cat_name, water_level, water_capacity], Color(0.4, 0.85, 1.0))

		State.WALKING_TO_SHED:
			_process_walk(delta, func():
				if is_underground:
					var mm := _get_mine_manager()
					var main_node = mm.main_game if mm != null else null
					if main_node != null and "world" in main_node and get_parent() != main_node.world:
						reparent(main_node.world)
					is_underground = false
					position = MINE_ENTRANCE_DOOR
					visible = (main_node == null or not main_node.in_mine)
					facing_dir = "down"
					_spr.offset = Vector2(0, -16)
					_spr.texture = _tex("down", 0)
					_set_destination(SHED_DOOR_POS)
					_show_bubble_text("📦")
					toast_requested.emit("%s đã từ Hầm Mỏ ra ngoài, gánh khoáng sản về Nhà Kho! 📦" % cat_name, Color(1.0, 0.85, 0.4))
				elif cat_breed == "tuxedo" or cat_role == "seller":
					_withdraw_items_from_shed()
					state = State.WALKING_TO_JOB
					current_job = {"type": "sell", "pos": STALL_SELLER_POS}
					_target_tile = null
					_set_destination(STALL_SELLER_POS)
					_show_bubble_text("🧺")
				else:
					state = State.DEPOSITING
					work_timer = 0.0
					_spr.texture = _tex("up", 0)
					_show_bubble_text("📦")
			)

		State.DEPOSITING:
			work_timer += delta
			if work_timer >= get_deposit_duration():
				_deposit_items_to_shed()
				state = State.IDLE
				_hide_bubble()
				if cat_role == "miner":
					state = State.WALKING_TO_MINE
					_set_destination(MINE_ENTRANCE_DOOR)
					_show_bubble_text("⛏️")
				elif cat_role == "fisher":
					if GameState.clock < get_sleep_clock():
						if assigned_rods > 0:
							state = State.WALKING_TO_JOB
							current_job = {"type": "fish", "pos": POND_FISHING_POS}
							_target_tile = null
							_set_destination(POND_FISHING_POS)
							_show_bubble_text("🎣")
							toast_requested.emit("%s cất cá vào kho xong, lập tức quay lại bờ ao câu tiếp! 🎣🐟 (Còn %d lượt)" % [cat_name, assigned_rods], Color(0.4, 0.85, 1.0))
						else:
							state = State.WALKING_TO_TENT
							_set_destination(get_sleep_pos())
							_show_bubble_text("🎣?")
							toast_requested.emit("%s đã cất cá và hết cần câu! Hãy giao thêm cần câu để mèo câu tiếp. 🎣" % cat_name, Color(1.0, 0.75, 0.4))
				else:
					_find_next_job()

		State.WALKING_TO_TENT:
			# Nếu là ban ngày và có việc mới phát sinh thì quay lại làm việc
			if GameState.clock < get_sleep_clock():
				_scan_timer += delta
				if _scan_timer >= 1.0:
					_scan_timer = 0.0
					_find_next_job()
					if state != State.WALKING_TO_TENT:
						return
			_process_walk(delta, func():
				if is_underground:
					var mm := _get_mine_manager()
					var main_node = mm.main_game if mm != null else null
					if main_node != null and "world" in main_node and get_parent() != main_node.world:
						reparent(main_node.world)
					is_underground = false
					position = MINE_ENTRANCE_DOOR
					visible = (main_node == null or not main_node.in_mine)
					_set_destination(get_sleep_pos())
					_show_bubble_text("😴")
				else:
					visible = false
					_hide_bubble()
					if GameState.clock >= get_sleep_clock():
						state = State.SLEEPING
					else:
						state = State.IDLE
			)

		State.SLEEPING:
			visible = false
			_hide_bubble()

		State.WALKING_TO_MINE:
			_process_walk(delta, func():
				var mm := _get_mine_manager()
				if mm != null:
					enter_underground_mine(mm)
				else:
					position = MINE_INSIDE_POS
					visible = false
					state = State.MINING
					work_timer = 0.0
					_hide_bubble()
					toast_requested.emit("%s đã đi vào trong Hầm Mỏ để khai thác khoáng sản! ⛏️💎" % cat_name, Color(0.85, 0.95, 1.0))
			)

		State.MINING:
			if cat_role == "miner":
				if not _is_rock_valid(_target_rock):
					var mm := _get_mine_manager()
					if mm != null and not mm._rocks_data.is_empty():
						_target_rock = {}
						state = State.IDLE
						_find_next_mining_job()
						return

			work_timer += delta
			var mine_dur := get_mining_cycle_duration()
			if is_underground:
				visible = true
				var progress: float = clampf(work_timer / mine_dur, 0.0, 0.999)
				var till_frame: int = int(progress * 4.0)
				_spr.texture = _tex("till", till_frame)
				_spr.offset = Vector2(0, -20)
				_spr.flip_h = false
			else:
				visible = false

			if work_timer >= mine_dur:
				work_timer = 0.0
				if not _target_rock.is_empty():
					_perform_cat_rock_hit()
				else:
					_complete_mining_step()


func _perform_cat_rock_hit() -> void:
	if not _is_rock_valid(_target_rock):
		_target_rock = {}
		state = State.IDLE
		_find_next_mining_job()
		return

	var mm := _get_mine_manager()
	if mm == null:
		return

	if _is_player_in_mine() and has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("pickaxe")

	var spr: Sprite2D = _target_rock.get("spr")
	if is_instance_valid(spr):
		var tw := spr.create_tween()
		tw.tween_property(spr, "scale", Vector2(1.25, 0.85), 0.05)
		tw.tween_property(spr, "scale", Vector2(0.95, 1.15), 0.06)
		tw.tween_property(spr, "scale", Vector2(1.0, 1.0), 0.05)

	var pwr := get_cat_mining_power()
	_target_rock.hits_left = int(_target_rock.hits_left) - pwr
	_show_bubble_text("⛏️")

	if int(_target_rock.hits_left) <= 0:
		var _drops = mm.break_rock_for_cat(_target_rock, self)
		_show_bubble_text("💎")
		_target_rock = {}

		if _total_bag_items() >= get_max_bag():
			state = State.WALKING_TO_SHED
			_set_destination(Vector2(3 * 32 + 16, 3 * 32 + 28))
			_show_bubble_text("📦")
			if _is_player_in_mine():
				toast_requested.emit("%s đã đầy túi khoáng sản, đang rời hầm mỏ đem về Nhà Kho cất! 📦⛏️" % cat_name, Color(1.0, 0.85, 0.4))
		else:
			state = State.IDLE
			_find_next_mining_job()


func _complete_mining_step() -> void:
	_mining_hits += 1
	if _mining_hits < 2:
		if _is_player_in_mine() and has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("pickaxe")
		if is_underground:
			_show_bubble_text("⛏️")
		return

	_mining_hits = 0
	if _is_player_in_mine() and has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("rock_break")

	var ore_id := _pick_mined_ore()
	harvest_bag[ore_id] = int(harvest_bag.get(ore_id, 0)) + 1
	action_performed.emit("mine", ore_id)
	var ore_name := _get_ore_display_name(ore_id)
	if is_underground:
		_show_bubble_text("💎")
	if _is_player_in_mine():
		toast_requested.emit("%s ở trong Hầm Mỏ đã đào được 1 %s! ⛏️💎" % [cat_name, ore_name], Color(0.85, 0.92, 1.0))

	# Kiểm tra đầy túi sau khi nhặt quặng
	if _total_bag_items() >= get_max_bag():
		state = State.WALKING_TO_SHED
		if is_underground:
			_set_destination(Vector2(3 * 32 + 16, 3 * 32 + 28))
			_show_bubble_text("📦")
			if _is_player_in_mine():
				toast_requested.emit("%s đã đầy túi khoáng sản, leo lên gửi về Nhà Kho! 📦⛏️" % cat_name, Color(1.0, 0.85, 0.4))
		else:
			position = MINE_ENTRANCE_DOOR
			visible = true
			facing_dir = "down"
			_spr.offset = Vector2(0, -16)
			_spr.texture = _tex("down", 0)
			_set_destination(SHED_DOOR_POS)
			_show_bubble_text("📦")
			toast_requested.emit("%s đã đầy túi khoáng sản, từ Hầm Mỏ đem về Nhà Kho! 📦" % cat_name, Color(1.0, 0.85, 0.4))
	elif GameState.clock >= get_sleep_clock():
		state = State.WALKING_TO_TENT
		if not is_underground:
			position = MINE_ENTRANCE_DOOR
			visible = true
			facing_dir = "down"
			_spr.offset = Vector2(0, -16)
			_set_destination(get_sleep_pos())
			_show_bubble_text("😴")


func is_mining_shift() -> bool:
	if not is_hired or cat_role != "miner":
		return false
	if GameState.clock >= get_sleep_clock() or GameState.clock < GameState.DAY_START:
		return false
	return true


func enter_underground_mine(p_mine_mgr: Node2D = null) -> void:
	var mm: Node2D = p_mine_mgr if p_mine_mgr != null else _get_mine_manager()
	if mm != null:
		mine_manager = mm
		if get_parent() != mm:
			reparent(mm)
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_underground = true
	position = Vector2(3 * 32 + 16, 3 * 32 + 28)
	var in_m := false
	if mm != null:
		if mm.visible:
			in_m = true
		elif mm.main_game != null and mm.main_game.in_mine:
			in_m = true
	visible = in_m
	state = State.IDLE
	work_timer = 0.0
	_mining_hits = 0
	_target_rock = {}
	if mm != null:
		mm.ensure_floor_ready(mm.current_floor)
	toast_requested.emit("%s đã tiến vào lòng Hầm Mỏ để khai thác đá & quặng! ⛏️💎" % cat_name, Color(0.85, 0.95, 1.0))
	_find_next_mining_job()


func exit_underground_mine() -> void:
	is_underground = false
	var mm := _get_mine_manager()
	var main_node = mm.main_game if mm != null else null
	if main_node != null and "world" in main_node and get_parent() != main_node.world:
		reparent(main_node.world)
	position = MINE_ENTRANCE_DOOR
	visible = true
	facing_dir = "down"
	_spr.offset = Vector2(0, -16)
	_spr.texture = _tex("down", 0)
	_target_rock = {}
	if _total_bag_items() >= get_max_bag():
		state = State.WALKING_TO_SHED
		_set_destination(SHED_DOOR_POS)
		_show_bubble_text("📦")
	elif GameState.clock >= get_sleep_clock():
		state = State.WALKING_TO_TENT
		_set_destination(get_sleep_pos())
		_show_bubble_text("😴")
	else:
		state = State.IDLE
		_find_next_mining_job()


# ---------- Di chuyển theo chuỗi Waypoints ----------

func _process_walk(delta: float, on_reached: Callable) -> void:
	if waypoints.is_empty():
		on_reached.call()
		return

	var target: Vector2 = waypoints[0]
	var diff := target - position
	var dist := diff.length()

	if dist <= 3.0:
		position = target
		waypoints.remove_at(0)
		if waypoints.is_empty():
			on_reached.call()
		return

	var dir := diff.normalized()
	position += dir * speed * delta

	anim_t += delta
	var frame_idx := int(anim_t * 6.0)

	_spr.offset = Vector2(0, -16)
	if absf(dir.x) > 0.05:
		_last_h_dir = signf(dir.x)

	if absf(dir.y) > absf(dir.x) * 1.2:
		if dir.y > 0:
			facing_dir = "down"
			_spr.texture = _tex("down", frame_idx % 4)
			_spr.flip_h = false
		else:
			facing_dir = "up"
			_spr.texture = _tex("up", frame_idx % 4)
			_spr.flip_h = false
	else:
		facing_dir = "side"
		_spr.texture = _tex("side", frame_idx % 4)
		_spr.flip_h = (dir.x < 0)


func _is_in_north_field(p: Vector2) -> bool:
	return p.x >= 810.0 and p.x <= 1286.0 and p.y >= 292.0 and p.y <= 444.0


func _is_in_south_field(p: Vector2) -> bool:
	return p.x >= 810.0 and p.x <= 1286.0 and p.y >= 500.0 and p.y <= 652.0


func _is_pond_west_bank(p: Vector2) -> bool:
	return p.x >= 1200.0 and p.x <= 1300.0 and p.y >= 700.0


func _add_waypoint(pt: Vector2) -> void:
	if waypoints.is_empty():
		if position.distance_to(pt) > 5.0:
			waypoints.append(pt)
	elif waypoints.back().distance_to(pt) > 5.0:
		waypoints.append(pt)


func _set_destination(dest: Vector2) -> void:
	waypoints.clear()
	if is_underground:
		_add_waypoint(dest)
		return
	var from_p := position

	var in_n_from := _is_in_north_field(from_p)
	var in_s_from := _is_in_south_field(from_p)
	var in_n_dest := _is_in_north_field(dest)
	var in_s_dest := _is_in_south_field(dest)
	var in_pond_west_from := _is_pond_west_bank(from_p)
	var in_pond_west_dest := _is_pond_west_bank(dest)

	# 1. Nếu cả điểm xuất phát và đích đến đều ở cùng trong 1 khu vực -> đi thẳng
	if in_n_from and in_n_dest:
		_add_waypoint(dest)
		return
	if in_s_from and in_s_dest:
		_add_waypoint(dest)
		return
	if in_pond_west_from and in_pond_west_dest:
		_add_waypoint(dest)
		return

	# 2. Nếu đang ở trong thửa ruộng hoặc bờ ao -> dẫn ra đường giao thông chính
	var curr := from_p
	if in_pond_west_from:
		_add_waypoint(Vector2(from_p.x, 680.0))
		_add_waypoint(Vector2(EAST_ROAD_POS.x, 680.0))
		_add_waypoint(EAST_ROAD_POS)
		curr = EAST_ROAD_POS
	elif in_n_from:
		_add_waypoint(NORTH_GATE_INNER)
		_add_waypoint(NORTH_GATE_POS)
		_add_waypoint(MID_ROAD_POS)
		curr = MID_ROAD_POS
	elif in_s_from:
		_add_waypoint(SOUTH_GATE_INNER)
		_add_waypoint(SOUTH_GATE_POS)
		_add_waypoint(MID_ROAD_POS)
		curr = MID_ROAD_POS

	# Mine area detection:
	var in_mine_from := (curr.x < 220.0 and curr.y < 440.0)
	var in_mine_dest := (dest.x < 220.0 and dest.y < 440.0)

	if in_mine_from and in_mine_dest:
		_add_waypoint(dest)
		return

	if in_mine_from:
		_add_waypoint(MINE_PATH_APPROACH)
		_add_waypoint(MINE_ROAD_JUNCTION)
		curr = MINE_ROAD_JUNCTION

	# Nếu đích đến là Bờ Tây Ao Nước (khu vực câu cá ngang hồ)
	if in_pond_west_dest:
		if curr.distance_to(EAST_ROAD_POS) > 10.0:
			if curr.x > 1300.0:
				_add_waypoint(EAST_ROAD_POS)
			elif curr.x < 800.0:
				_add_waypoint(ROAD_JUNCTION_POS)
				_add_waypoint(MID_ROAD_POS)
				_add_waypoint(EAST_ROAD_POS)
			else:
				_add_waypoint(MID_ROAD_POS)
				_add_waypoint(EAST_ROAD_POS)
		_add_waypoint(Vector2(EAST_ROAD_POS.x, 680.0))
		_add_waypoint(Vector2(dest.x, 680.0))
		_add_waypoint(dest)
		return

	# 3. Nếu đích đến nằm trong Thửa Bắc -> từ đường giữa qua cổng Bắc vào trong
	if in_n_dest:
		if curr.distance_to(MID_ROAD_POS) > 10.0:
			if curr.x > 1300.0:
				_add_waypoint(EAST_ROAD_POS)
			elif curr.x < 800.0:
				_add_waypoint(ROAD_JUNCTION_POS)
			_add_waypoint(MID_ROAD_POS)
		_add_waypoint(NORTH_GATE_POS)
		_add_waypoint(NORTH_GATE_INNER)
		_add_waypoint(dest)
		return

	# 4. Nếu đích đến nằm trong Thửa Nam -> từ đường giữa qua cổng Nam vào trong
	if in_s_dest:
		if curr.distance_to(MID_ROAD_POS) > 10.0:
			if curr.x > 1300.0:
				_add_waypoint(EAST_ROAD_POS)
			elif curr.x < 800.0:
				_add_waypoint(ROAD_JUNCTION_POS)
			_add_waypoint(MID_ROAD_POS)
		_add_waypoint(SOUTH_GATE_POS)
		_add_waypoint(SOUTH_GATE_INNER)
		_add_waypoint(dest)
		return

	# Nếu đích đến nằm ở khu Hầm Mỏ
	if in_mine_dest:
		if curr.distance_to(MINE_ROAD_JUNCTION) > 10.0:
			if curr.x > 1300.0:
				_add_waypoint(EAST_ROAD_POS)
				_add_waypoint(MID_ROAD_POS)
				_add_waypoint(ROAD_JUNCTION_POS)
			elif curr.x >= 800.0:
				_add_waypoint(MID_ROAD_POS)
				_add_waypoint(ROAD_JUNCTION_POS)
			elif curr.x > 220.0:
				if curr.y < 350.0:
					_add_waypoint(Vector2(curr.x, 300.0))
				_add_waypoint(ROAD_JUNCTION_POS)
			_add_waypoint(MINE_ROAD_JUNCTION)
		_add_waypoint(MINE_PATH_APPROACH)
		_add_waypoint(dest)
		return

	# 5. Cả hai điểm đều ở bên ngoài các thửa ruộng (Nhà Junimo, Nhà kho, Ao nước, Cửa nhà, v.v.)
	if curr.x < 220.0:
		_add_waypoint(ROAD_JUNCTION_POS)
		curr = ROAD_JUNCTION_POS

	if curr.x < 800.0 and dest.x > 1300.0:
		_add_waypoint(ROAD_JUNCTION_POS)
		_add_waypoint(MID_ROAD_POS)
		_add_waypoint(EAST_ROAD_POS)
		if dest.y > 600.0:
			_add_waypoint(Vector2(EAST_ROAD_POS.x, 730.0))
	elif curr.x > 1300.0 and dest.x < 800.0:
		if curr.y > 600.0:
			_add_waypoint(Vector2(EAST_ROAD_POS.x, 730.0))
		_add_waypoint(EAST_ROAD_POS)
		_add_waypoint(MID_ROAD_POS)
		_add_waypoint(ROAD_JUNCTION_POS)
		if dest.y < 350.0:
			_add_waypoint(Vector2(dest.x, 300.0))
	elif curr.distance_to(MID_ROAD_POS) < 10.0:
		if dest.x < 800.0:
			_add_waypoint(ROAD_JUNCTION_POS)
			if dest.y < 350.0:
				_add_waypoint(Vector2(dest.x, 300.0))
		elif dest.x > 1300.0:
			_add_waypoint(EAST_ROAD_POS)
			if dest.y > 600.0:
				_add_waypoint(Vector2(EAST_ROAD_POS.x, 730.0))
	elif curr.x > 1300.0 and dest.x > 1300.0:
		_add_waypoint(EAST_ROAD_POS)
		if dest.y > 600.0:
			_add_waypoint(Vector2(EAST_ROAD_POS.x, 730.0))
	elif curr.x < 800.0 and dest.x < 800.0:
		_add_waypoint(Vector2(curr.x, 300.0))
		_add_waypoint(Vector2(dest.x, 300.0))

	_add_waypoint(dest)


# ---------- Quản lý công việc nông trại & mỏ ----------

func _find_next_mining_job() -> void:
	if is_underground:
		if _total_bag_items() >= get_max_bag():
			state = State.WALKING_TO_SHED
			_set_destination(Vector2(3 * 32 + 16, 3 * 32 + 28))
			_show_bubble_text("📦")
			toast_requested.emit("%s đã đầy túi khoáng sản, đang rời hầm mỏ đem về Nhà Kho cất! 📦⛏️" % cat_name, Color(1.0, 0.85, 0.4))
			return

		if GameState.clock >= get_sleep_clock():
			state = State.WALKING_TO_TENT
			_set_destination(Vector2(3 * 32 + 16, 3 * 32 + 28))
			_show_bubble_text("😴")
			return

		var rock := _find_nearest_mine_rock()
		if not rock.is_empty():
			_target_rock = rock
			var pt: Vector2i = rock.get("pos_tile", Vector2i.ZERO)
			var rock_pos := Vector2(pt.x * 32 + 16, pt.y * 32 + 16)
			var stand_pos := _get_rock_stand_pos(rock_pos)
			state = State.WALKING_TO_JOB
			_set_destination(stand_pos)
			_show_bubble_text("⛏️")
			return
		else:
			# Không còn tảng đá nào trên tầng hiện tại
			if _total_bag_items() > 0:
				state = State.WALKING_TO_SHED
				_set_destination(Vector2(3 * 32 + 16, 3 * 32 + 28))
				_show_bubble_text("📦")
				return
			else:
				var mm := _get_mine_manager()
				if mm != null:
					mm.advance_floor_for_cat()
					var next_rock := _find_nearest_mine_rock()
					if not next_rock.is_empty():
						_target_rock = next_rock
						var pt: Vector2i = next_rock.get("pos_tile", Vector2i.ZERO)
						var rock_pos := Vector2(pt.x * 32 + 16, pt.y * 32 + 16)
						var stand_pos := _get_rock_stand_pos(rock_pos)
						state = State.WALKING_TO_JOB
						_set_destination(stand_pos)
						_show_bubble_text("⛏️")
						return
		return

	var bag_count := _total_bag_items()
	if bag_count >= get_max_bag():
		facing_dir = "down"
		_spr.texture = _tex("down", 0)
		_spr.offset = Vector2(0, -16)
		state = State.WALKING_TO_SHED
		_set_destination(SHED_DOOR_POS)
		_show_bubble_text("📦")
		return

	if GameState.clock >= get_sleep_clock():
		if position.distance_to(get_sleep_pos()) > 15.0:
			if state != State.WALKING_TO_TENT:
				state = State.WALKING_TO_TENT
				_set_destination(get_sleep_pos())
				_show_bubble_text("😴")
		else:
			visible = false
			_hide_bubble()
		return

	if position.distance_to(MINE_ENTRANCE_DOOR) <= 10.0 or position.distance_to(MINE_INSIDE_POS) <= 10.0:
		var mm := _get_mine_manager()
		if mm != null:
			enter_underground_mine(mm)
		else:
			position = MINE_INSIDE_POS
			visible = false
			state = State.MINING
			work_timer = 0.0
			_hide_bubble()
	else:
		visible = true
		state = State.WALKING_TO_MINE
		_set_destination(MINE_ENTRANCE_DOOR)
		_show_bubble_text("⛏️")


func _find_next_fishing_job() -> void:
	var bag_count := _total_bag_items()
	if bag_count >= get_max_bag():
		visible = true
		facing_dir = "down"
		_spr.texture = _tex("down", 0)
		_spr.offset = Vector2(0, -16)
		state = State.WALKING_TO_SHED
		_set_destination(SHED_DOOR_POS)
		_show_bubble_text("📦")
		return

	if GameState.clock >= get_sleep_clock():
		if position.distance_to(get_sleep_pos()) > 15.0:
			if state != State.WALKING_TO_TENT:
				state = State.WALKING_TO_TENT
				_set_destination(get_sleep_pos())
				_show_bubble_text("😴")
		else:
			visible = false
			_hide_bubble()
		return

	# Mèo Trắng phải được giao cần mới câu được!
	if assigned_rods <= 0:
		if bag_count > 0:
			visible = true
			facing_dir = "down"
			_spr.texture = _tex("down", 0)
			_spr.offset = Vector2(0, -16)
			state = State.WALKING_TO_SHED
			_set_destination(SHED_DOOR_POS)
			_show_bubble_text("📦")
			return
		if position.distance_to(get_sleep_pos()) > 15.0:
			if state != State.WALKING_TO_TENT:
				state = State.WALKING_TO_TENT
				_set_destination(get_sleep_pos())
				_show_bubble_text("🎣?")
		else:
			visible = false
			_hide_bubble()
		return

	visible = true
	state = State.WALKING_TO_JOB
	current_job = {"type": "fish", "pos": POND_FISHING_POS}
	_target_tile = null
	_set_destination(POND_FISHING_POS)
	_show_bubble_text("🎣")


func _find_next_seller_job() -> void:
	if GameState.clock >= get_sleep_clock() or GameState.clock < GameState.DAY_START:
		if position.distance_to(get_sleep_pos()) > 15.0:
			if state != State.WALKING_TO_TENT:
				state = State.WALKING_TO_TENT
				_set_destination(get_sleep_pos())
				_show_bubble_text("😴")
		else:
			visible = false
			_hide_bubble()
		return

	var sm = _get_stall_manager()
	var has_rev: bool = (sm != null and int(sm.stall_revenue) > 0)
	var has_carried_items: bool = (_total_bag_items() > 0)
	var restock_item: Dictionary = _find_restockable_item(sm)
	var needs_restock: bool = (not restock_item.is_empty())

	# Nếu KHÔNG CÓ VIỆC GÌ LÀM:
	# Không có tiền để thu, không có hàng trong túi, không có hàng trong kho cần mang ra sạp
	if not has_rev and not has_carried_items and not needs_restock:
		if position.distance_to(get_sleep_pos()) > 15.0:
			if state != State.WALKING_TO_TENT:
				state = State.WALKING_TO_TENT
				_set_destination(get_sleep_pos())
				_hide_bubble()
		else:
			visible = false
			_hide_bubble()
			state = State.IDLE
		return

	# CÓ VIỆC: Mèo xuất hiện ra ngoài
	visible = true

	# 1. Đã có hàng trong túi (lấy từ kho xong) -> Mang ra sạp
	if has_carried_items:
		if position.distance_to(STALL_SELLER_POS) > 15.0:
			state = State.WALKING_TO_JOB
			current_job = {"type": "sell", "pos": STALL_SELLER_POS}
			_target_tile = null
			_set_destination(STALL_SELLER_POS)
			_show_bubble_text("🧺")
		else:
			state = State.WORKING
			current_job = {"type": "sell", "pos": STALL_SELLER_POS}
			facing_dir = "right"
			_spr.texture = _tex("right", 0)
			_spr.offset = Vector2(0, -16)
			_spr.flip_h = false
			_show_bubble_text("🧺")
			_process_stall_work()
		return

	# 2. Cần lấy hàng từ kho ra sạp ("lấy đồ từ kho")
	if needs_restock:
		if position.distance_to(SHED_DOOR_POS) > 15.0:
			state = State.WALKING_TO_SHED
			_target_tile = null
			_set_destination(SHED_DOOR_POS)
			_show_bubble_text("📦")
		else:
			_withdraw_items_from_shed()
			state = State.WALKING_TO_JOB
			current_job = {"type": "sell", "pos": STALL_SELLER_POS}
			_target_tile = null
			_set_destination(STALL_SELLER_POS)
			_show_bubble_text("🧺")
		return

	# 3. Có tiền thu tại sạp (stall_revenue > 0)
	if has_rev:
		if position.distance_to(STALL_SELLER_POS) > 15.0:
			state = State.WALKING_TO_JOB
			current_job = {"type": "sell", "pos": STALL_SELLER_POS}
			_target_tile = null
			_set_destination(STALL_SELLER_POS)
			_show_bubble_text("🪙")
		else:
			state = State.WORKING
			current_job = {"type": "sell", "pos": STALL_SELLER_POS}
			facing_dir = "right"
			_spr.texture = _tex("right", 0)
			_spr.offset = Vector2(0, -16)
			_spr.flip_h = false
			_show_bubble_text("🪙")
			_process_stall_work()
		return


func _process_stall_work() -> void:
	var sm = _get_stall_manager()
	if sm == null or not ("stall_slots" in sm):
		return

	var slot_limit := get_stall_slot_limit()

	# 1. BÀY HÀNG TỪ TÚI ĐANG MANG LÊN KỆ SẠP (Giới hạn tối đa slot_limit item 1 ô)
	var any_restocked := false
	for item_id in harvest_bag.keys():
		var count_to_put: int = int(harvest_bag[item_id])
		if count_to_put <= 0:
			continue
		var existing_slot_idx: int = -1
		var empty_slot_idx: int = -1
		for i in sm.stall_slots.size():
			var s = sm.stall_slots[i]
			if typeof(s) == TYPE_DICTIONARY and not s.is_empty():
				if str(s.get("id", "")) == str(item_id):
					existing_slot_idx = i
					break
			elif empty_slot_idx < 0:
				empty_slot_idx = i

		var info := _get_sellable_item_info(str(item_id))
		var cat_type: String = str(info.get("type", "crop"))
		if existing_slot_idx >= 0:
			var slot: Dictionary = sm.stall_slots[existing_slot_idx]
			var cur: int = int(slot.get("count", 0))
			var space: int = maxi(0, slot_limit - cur)
			var put: int = mini(count_to_put, space)
			if put > 0:
				slot["count"] = cur + put
				harvest_bag[item_id] = count_to_put - put
				any_restocked = true
				toast_requested.emit("%s đã xếp thêm ×%d %s lên kệ sạp! 🧺 (Hiện có %d/%d)" % [cat_name, put, str(info.get("name", item_id)), slot["count"], slot_limit], Color(0.65, 0.95, 0.65))
		elif empty_slot_idx >= 0:
			var put: int = mini(count_to_put, slot_limit)
			if put > 0:
				sm.stall_slots[empty_slot_idx] = {
					"id": str(item_id),
					"type": cat_type,
					"name": str(info.get("name", item_id)),
					"price": int(info.get("price", 10)),
					"count": put
				}
				harvest_bag[item_id] = count_to_put - put
				any_restocked = true
				toast_requested.emit("%s đã xếp ×%d %s lên kệ sạp! 🧺 (%d/%d)" % [cat_name, put, str(info.get("name", item_id)), put, slot_limit], Color(0.65, 0.95, 0.65))

		if int(harvest_bag.get(item_id, 0)) <= 0:
			harvest_bag.erase(item_id)

	# Nếu mèo đang ở sạp nhưng túi trống và có đồ cần lấy ngay từ kho (ví dụ khi gọi trực tiếp _process_stall_work trong test hoặc nút 'Bày ra sạp ngay')
	if _total_bag_items() <= 0:
		for item_id in sell_targets.keys():
			var target: int = int(sell_targets[item_id])
			if target <= 0:
				continue
			var cur_on_stall: int = 0
			var existing_slot_idx: int = -1
			var empty_slot_idx: int = -1
			for i in sm.stall_slots.size():
				var s = sm.stall_slots[i]
				if typeof(s) == TYPE_DICTIONARY and not s.is_empty():
					if str(s.get("id", "")) == str(item_id):
						cur_on_stall += int(s.get("count", 0))
						existing_slot_idx = i
				elif empty_slot_idx < 0:
					empty_slot_idx = i

			var max_allowed := mini(target, slot_limit)
			if cur_on_stall < max_allowed and (existing_slot_idx >= 0 or empty_slot_idx >= 0):
				var need := max_allowed - cur_on_stall
				var info := _get_sellable_item_info(str(item_id))
				var cat_type: String = str(info.get("type", "crop"))
				var cat_key := Inventory._normalize_cat(cat_type)
				var in_storage := Inventory.storage_count(cat_key, str(item_id))
				if in_storage > 0:
					var to_move := mini(need, in_storage)
					# Lấy strictly từ kho storage!
					var taken := Inventory.take_from_storage(cat_type, str(item_id), to_move)
					if taken > 0:
						if existing_slot_idx >= 0:
							var slot: Dictionary = sm.stall_slots[existing_slot_idx]
							slot["count"] = int(slot.get("count", 0)) + taken
						elif empty_slot_idx >= 0:
							sm.stall_slots[empty_slot_idx] = {
								"id": str(item_id),
								"type": cat_type,
								"name": str(info.get("name", item_id)),
								"price": int(info.get("price", 10)),
								"count": taken
							}
						any_restocked = true
						toast_requested.emit("%s tự động lấy từ kho và bày ×%d %s lên sạp hàng! 🧺" % [cat_name, taken, str(info.get("name", item_id))], Color(0.65, 0.95, 0.65))
						break

	if any_restocked:
		sm.on_stall_changed()
		if sm.main != null and sm.main.stall_panel != null and sm.main.stall_panel.visible:
			sm.main.stall_panel.stall_slots = sm.stall_slots
			sm.main.stall_panel._refresh_ui()
		_show_bubble_text("🧺")

	# 2. TỰ ĐỘNG THU TIỀN TẠI SẠP (Auto Revenue Collection)
	if int(sm.stall_revenue) > 0:
		var rev: int = int(sm.stall_revenue)
		sm.stall_revenue = 0
		sm.update_stall_coin_badge()
		GameState.add_money(rev)
		total_sales_revenue += rev
		_show_bubble_text("🪙+")
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		toast_requested.emit("%s đã tự động thu %d xu tiền bán hàng vào ví! 🪙🏪" % [cat_name, rev], Color(1.0, 0.9, 0.4))
		action_performed.emit("stall_sell", "")
		if sm.main != null and sm.main.stall_panel != null and sm.main.stall_panel.visible:
			sm.main.stall_panel.stall_revenue = 0
			sm.main.stall_panel._refresh_ui()

	# 3. TỰ ĐỘNG PHỤC VỤ KHÁCH ĐANG CHỜ TỪ KHO
	if sm._active_stall_customer != null and is_instance_valid(sm._active_stall_customer):
		var cust = sm._active_stall_customer
		if int(cust.state) == 2: # WAITING
			var cid: String = str(cust.item_id)
			var c_qty: int = int(cust.buy_qty)
			if int(sell_targets.get(cid, 0)) > 0:
				var info := _get_sellable_item_info(cid)
				var cat_type: String = str(info.get("type", "crop"))
				var cat_key := Inventory._normalize_cat(cat_type)
				var in_storage := Inventory.storage_count(cat_key, cid)
				if in_storage >= c_qty:
					var taken: int = Inventory.take_item_for_sale(cat_type, cid, c_qty, true)
					if taken > 0:
						var revenue: int = taken * int(cust.unit_price)
						GameState.add_money(revenue)
						total_sales_revenue += revenue
						cust._purchased = true
						if "bubble_qty_label" in cust and cust.bubble_qty_label != null:
							cust.bubble_qty_label.text = "✓"
						_show_bubble_text("✨")
						if has_node("/root/AudioManager"):
							get_node("/root/AudioManager").play_sfx("coin")
						toast_requested.emit("%s đã bán trực tiếp ×%d %s cho %s (+%d xu)! 🐱🪙" % [cat_name, taken, cust.item_name, cust.display_name, revenue], Color(1.0, 0.88, 0.4))
						action_performed.emit("stall_sell", "")
						cust.state = 3 # WALK_OUT
						cust.exit_pos = Vector2(-40, cust.position.y)
						if cust._spr != null:
							cust._spr.texture = TextureGen.sdv_char_tex(cust.character_name, "left", 0)

	# 4. KIỂM TRA CÒN VIỆC HAY KHÔNG
	# Nếu không còn việc: lập tức đi về Nhà Junimo (lều) và ẩn đi!
	if not has_seller_work():
		if position.distance_to(get_sleep_pos()) > 15.0:
			state = State.WALKING_TO_TENT
			_set_destination(get_sleep_pos())
			_hide_bubble()
		else:
			visible = false
			_hide_bubble()
			state = State.IDLE
	else:
		# Nếu còn hàng trong kho cần lấy:
		var restock := _find_restockable_item(sm)
		if not restock.is_empty() and _total_bag_items() <= 0:
			state = State.WALKING_TO_SHED
			_set_destination(SHED_DOOR_POS)
			_show_bubble_text("📦")


func _find_next_job() -> void:
	if cat_role == "miner":
		_find_next_mining_job()
		return
	if cat_role == "fisher":
		_find_next_fishing_job()
		return
	if cat_role == "seller":
		_find_next_seller_job()
		return

	if farm == null or not ("tiles" in farm):
		return

	# Nếu đã gom được kha khá nông sản hoặc không còn việc gấp, đem cất vào Nhà Kho
	var bag_count := _total_bag_items()
	if bag_count >= get_max_bag():
		visible = true
		facing_dir = "down"
		_spr.texture = _tex("down", 0)
		state = State.WALKING_TO_SHED
		_set_destination(SHED_DOOR_POS)
		_show_bubble_text("📦")
		return

	# ƯU TIÊN 1: Bắt sâu bọ (Pests) bảo vệ cây trồng
	var pest_tile: Node = _find_nearest_tile(func(t):
		return t.tstate == FarmTileScript.TState.PLANTED and t.has_pest
	)
	if pest_tile != null:
		_start_tile_job("pest", pest_tile, "🐛")
		return

	# ƯU TIÊN 2: Thu hoạch hoa màu đã chín
	var ready_tile: Node = _find_nearest_tile(func(t):
		return t.tstate == FarmTileScript.TState.PLANTED and t.is_ready()
	)
	if ready_tile != null:
		_start_tile_job("harvest", ready_tile, "🌾")
		return

	# ƯU TIÊN 3: Tưới nước cho cây đang khô
	var dry_tile: Node = _find_nearest_tile(func(t):
		return t.tstate == FarmTileScript.TState.PLANTED and not t.watered
	)
	if dry_tile != null:
		if water_level <= 0:
			# Hết nước -> tự động ra ao múc nước
			visible = true
			facing_dir = "down"
			_spr.texture = _tex("down", 0)
			state = State.WALKING_TO_POND
			_set_destination(POND_REFILL_POS)
			_show_bubble_text("💧...")
			return
		_start_tile_job("water", dry_tile, "💧")
		return

	# ƯU TIÊN 4: Cuốc đất đen sau thu hoạch (nếu được giao cuốc)
	if assigned_hoes > 0:
		var harvested_tile: Node = _find_nearest_tile(func(t):
			return t.tstate == FarmTileScript.TState.HARVESTED
		)
		if harvested_tile != null:
			_start_tile_job("till", harvested_tile, "⛏️")
			return

	# ƯU TIÊN 5: Gieo hạt giống người chơi giao vào đất đã cày
	var seed_id := _get_available_seed()
	if seed_id != "":
		var tilled_tile: Node = _find_nearest_tile(func(t):
			return t.tstate == FarmTileScript.TState.TILLED
		)
		if tilled_tile != null:
			visible = true
			facing_dir = "down"
			_spr.texture = _tex("down", 0)
			current_job = {"type": "plant", "seed_id": seed_id, "tile": tilled_tile}
			_target_tile = tilled_tile
			state = State.WALKING_TO_JOB
			var center_p: Vector2 = farm.tile_center(tilled_tile.coord)
			_set_destination(center_p)
			_show_bubble_text("🌱")
			return

	# ƯU TIÊN 6: Cày thêm đất cỏ nếu còn cuốc
	if assigned_hoes > 0:
		var grass_tile: Node = _find_nearest_tile(func(t):
			return t.tstate == FarmTileScript.TState.GRASS
		)
		if grass_tile != null:
			_start_tile_job("till", grass_tile, "⛏️")
			return

	# ƯU TIÊN 7: Nếu còn đồ trong túi thu hoạch thì đem cất kho
	if bag_count > 0:
		visible = true
		facing_dir = "down"
		_spr.texture = _tex("down", 0)
		state = State.WALKING_TO_SHED
		_set_destination(SHED_DOOR_POS)
		_show_bubble_text("📦")
		return

	# Không có công việc nào cần làm -> đi về Nhà Junimo và đi hẳn vào trong (ẩn đi)
	if position.distance_to(get_sleep_pos()) > 15.0:
		if state != State.WALKING_TO_TENT:
			state = State.WALKING_TO_TENT
			_set_destination(get_sleep_pos())
			_hide_bubble()
	else:
		visible = false
		_hide_bubble()


func _start_tile_job(type: String, tile: Node, bubble_icon_text: String) -> void:
	visible = true
	facing_dir = "down"
	_spr.texture = _tex("down", 0)
	current_job = {"type": type, "tile": tile}
	_target_tile = tile
	state = State.WALKING_TO_JOB
	var center_p: Vector2 = farm.tile_center(tile.coord)
	_set_destination(center_p)
	_show_bubble_text(bubble_icon_text)


func _spawn_water_ripple_near_pond() -> void:
	var w = get_parent()
	if w == null:
		return
	var main_node = w.get_parent()
	if main_node != null and "fishing_manager" in main_node and main_node.fishing_manager != null:
		main_node.fishing_manager.spawn_water_ripple(Vector2(position.x + 40, position.y + 6), 0.7, 0.6)


func _complete_fishing_job() -> void:
	assigned_rods = maxi(0, assigned_rods - 1)

	var fail_rate := get_rod_fail_rate(work_level)
	var rod_name := get_rod_name(work_level)

	if randf() < fail_rate:
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("splash")
		_show_bubble_text("💨")
		toast_requested.emit("%s dùng %s kéo cần lên... cá sổng mất rồi! 🎣💦" % [cat_name, rod_name], Color(0.85, 0.75, 0.65))
		action_performed.emit("fish_miss", "")
		return

	var FishDB = load("res://scripts/fish_db.gd")
	var fish_id := _pick_fished_item()
	harvest_bag[fish_id] = int(harvest_bag.get(fish_id, 0)) + 1
	var fdata: Dictionary = FishDB.get_fish(fish_id)
	var fname: String = str(fdata.get("name", "Cá tươi"))
	var ftier: String = str(fdata.get("tier", "common"))

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("fish_catch")

	_show_bubble_text("🐟")
	var color := Color(0.4, 0.85, 1.0)
	if ftier == "legend":
		color = Color(1.0, 0.85, 0.3)
		toast_requested.emit("HUYỀN THOẠI! %s dùng %s câu được %s! 🏆🐟" % [cat_name, rod_name, fname], color)
	elif ftier == "rare":
		color = Color(0.6, 1.0, 0.9)
		toast_requested.emit("%s dùng %s câu được cá hiếm: %s! ✨🐟" % [cat_name, rod_name, fname], color)
	else:
		toast_requested.emit("%s dùng %s đã câu được 1 con %s! 🐟🎣" % [cat_name, rod_name, fname], color)
	action_performed.emit("fish", fish_id)


func _complete_job() -> void:
	var job_type: String = str(current_job.get("type", ""))
	if job_type == "fish":
		_complete_fishing_job()
		current_job.clear()
		_target_tile = null
		if _total_bag_items() >= get_max_bag():
			state = State.WALKING_TO_SHED
			_set_destination(SHED_DOOR_POS)
			_show_bubble_text("📦")
			toast_requested.emit("%s đã đầy giỏ cá (%d/%d), đang đem về cất vào Nhà Kho! 📦🐟" % [cat_name, _total_bag_items(), get_max_bag()], Color(1.0, 0.85, 0.4))
		elif assigned_rods <= 0:
			if _total_bag_items() > 0:
				state = State.WALKING_TO_SHED
				_set_destination(SHED_DOOR_POS)
				_show_bubble_text("📦")
				toast_requested.emit("%s đã dùng hết lượt câu, đang về Nhà Kho cất cá! 📦🎣" % cat_name, Color(1.0, 0.85, 0.4))
			else:
				state = State.WALKING_TO_TENT
				_set_destination(get_sleep_pos())
				_show_bubble_text("🎣?")
				toast_requested.emit("%s đã dùng hết cần câu! Hãy giao thêm cần câu để mèo tiếp tục câu cá. 🎣" % cat_name, Color(1.0, 0.75, 0.4))
		return

	if _target_tile == null or not is_instance_valid(_target_tile):
		current_job.clear()
		return

	match job_type:
		"pest":
			if _target_tile.has_pest:
				_target_tile.clear_pest()
				harvest_bag["sau_bo"] = int(harvest_bag.get("sau_bo", 0)) + 1
				if has_node("/root/AudioManager"):
					get_node("/root/AudioManager").play_sfx("bush_rustle")
				toast_requested.emit("%s đã bắt được 1 con sâu bọ! 🐛" % cat_name, Color(0.6, 0.9, 0.4))
				action_performed.emit("catch_pest", "sau_bo")

		"harvest":
			if _target_tile.is_ready():
				var cid: String = _target_tile.harvest()
				if cid != "":
					harvest_bag[cid] = int(harvest_bag.get(cid, 0)) + 1
					var cdata := CropDB.get_crop(cid)
					var cname := str(cdata.get("name", "nông sản"))
					if has_node("/root/AudioManager"):
						get_node("/root/AudioManager").play_sfx("harvest")
					toast_requested.emit("%s đã thu hoạch %s! 🌾" % [cat_name, cname], Color(0.65, 1.0, 0.6))
					action_performed.emit("harvest", cid)

		"till":
			if assigned_hoes > 0 and (_target_tile.tstate == FarmTileScript.TState.HARVESTED or _target_tile.tstate == FarmTileScript.TState.GRASS):
				_target_tile.till()
				assigned_hoes -= 1
				if has_node("/root/AudioManager"):
					get_node("/root/AudioManager").play_sfx("till")
				toast_requested.emit("%s đã cuốc xới đất xong! ⛏️ (Còn %d cuốc)" % [cat_name, assigned_hoes], Color(0.9, 0.8, 0.5))

		"water":
			if not _target_tile.watered:
				_target_tile.water()
				water_level = maxi(0, water_level - 1)
				action_performed.emit("water", "")

		"plant":
			var sid: String = str(current_job.get("seed_id", ""))
			if sid != "" and int(assigned_seeds.get(sid, 0)) > 0:
				if _target_tile.tstate == FarmTileScript.TState.TILLED:
					_target_tile.plant(sid)
					assigned_seeds[sid] = int(assigned_seeds.get(sid, 0)) - 1
					if assigned_seeds[sid] <= 0:
						assigned_seeds.erase(sid)
					action_performed.emit("plant", sid)

	current_job.clear()
	_target_tile = null


func _is_tile_targeted_by_other_cat(tile: Node) -> bool:
	var list := other_cats if not other_cats.is_empty() else ([other_cat] if other_cat != null else [])
	for c in list:
		if is_instance_valid(c) and c.is_hired and c._target_tile == tile:
			return true
	return false


func _find_nearest_tile(condition: Callable) -> Node:
	if farm == null or not ("tiles" in farm):
		return null
	var best_tile: Node = null
	var min_d := 999999.0
	for t in farm.tiles.values():
		if condition.call(t):
			if _is_tile_targeted_by_other_cat(t):
				continue
			var d := position.distance_to(farm.tile_center(t.coord))
			if d < min_d:
				min_d = d
				best_tile = t
	return best_tile


func _get_available_seed() -> String:
	for sid in assigned_seeds:
		if int(assigned_seeds[sid]) > 0:
			return str(sid)
	return ""


func _total_bag_items() -> int:
	var total := 0
	for k in harvest_bag:
		total += int(harvest_bag[k])
	return total


func _deposit_items_to_shed() -> void:
	if harvest_bag.is_empty():
		return
	var items_stored := 0
	var is_miner := (cat_role == "miner")
	var is_fisher := (cat_role == "fisher")
	for k in harvest_bag:
		var count: int = int(harvest_bag[k])
		if count > 0:
			if is_fisher:
				Inventory.direct_store("fish", str(k), count)
			elif is_miner:
				Inventory.direct_store("ores", str(k), count)
			else:
				Inventory.direct_store("produce", str(k), count)
			items_stored += count
	harvest_bag.clear()
	if is_fisher:
		toast_requested.emit("%s đã cất %d con cá vào Nhà Kho! 🏚️🐟" % [cat_name, items_stored], Color(0.4, 0.85, 1.0))
	elif is_miner:
		toast_requested.emit("%s đã cất %d khoáng sản vào Nhà Kho! 🏚️⛏️" % [cat_name, items_stored], Color(0.95, 0.85, 0.4))
	else:
		toast_requested.emit("%s đã cất %d món thu hoạch vào Nhà Kho! 🏚️✨" % [cat_name, items_stored], Color(0.9, 0.8, 0.4))


# ---------- Thuê & Trả lương ----------

func hire() -> void:
	is_hired = true
	state = State.IDLE
	if cat_breed == "orange" or cat_breed == "white" or cat_breed == "tuxedo":
		position = get_entrance_pos()
		visible = true
		facing_dir = "down"
		_spr.texture = _tex("down", 0)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("meow")
	if cat_breed == "white" and assigned_rods <= 0:
		_show_bubble_text("🎣?")
		toast_requested.emit("%s đã sẵn sàng làm việc! Hãy mở thực đơn Mèo và giao cần câu để mèo bắt đầu câu cá nhé. 🎣" % cat_name, Color(0.4, 0.85, 1.0))
	elif cat_breed == "tuxedo":
		_show_bubble_text("🏪")
		toast_requested.emit("%s đã nhận việc! Mèo sẽ ra trực sạp hàng, tự động bán đồ và thu tiền vào ví cho bạn! 🏪🪙" % cat_name, Color(1.0, 0.88, 0.4))
	else:
		_show_bubble_text("Meo! 🐱❤️")
	hired.emit()
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(func():
		if state == State.IDLE and not (cat_breed == "white" and assigned_rods <= 0):
			_hide_bubble()
	)


func dismiss() -> void:
	is_hired = false
	state = State.WAITING_HIRE
	if cat_breed == "orange" or cat_breed == "white" or cat_breed == "tuxedo":
		visible = false
		position = get_sleep_pos()
		_hide_bubble()
	else:
		position = WAITING_POS
		visible = true
		_show_bubble_text("...")


func _pay_daily_wage() -> void:
	if wage_paid_today or not is_hired:
		return
	if GameState.try_spend(daily_wage):
		wage_paid_today = true
		toast_requested.emit("Đã trả lương %d xu cho %s chăm chỉ! 🐱💰" % [daily_wage, cat_name], Color(1.0, 0.9, 0.4))
	else:
		toast_requested.emit("Hôm nay không đủ tiền trả lương cho %s! 😿" % cat_name, Color(1.0, 0.5, 0.4))


# ---------- Giao nhận hạt giống & công cụ ----------

func give_hoes(amount: int) -> bool:
	if amount <= 0:
		return false
	if Inventory.hoes < amount:
		return false
	Inventory.hoes -= amount
	Inventory.changed.emit()
	assigned_hoes += amount
	return true


func take_back_hoes(amount: int = -1) -> bool:
	if assigned_hoes <= 0:
		return false
	var take_n := assigned_hoes if amount < 0 else mini(assigned_hoes, amount)
	assigned_hoes -= take_n
	Inventory.add_hoes(take_n)
	return true


func give_rods(amount: int = 10) -> bool:
	if amount <= 0:
		return false
	var available: int = Inventory.total_casts()
	if available <= 0:
		toast_requested.emit("Balo không có cần câu! Hãy mua cần ở Bến Cá Chú Hai.", Color(1.0, 0.6, 0.5))
		return false
	var to_give: int = mini(amount, available)
	var given: int = 0
	while given < to_give:
		var tier := Inventory.take_cast()
		if tier == "":
			break
		given += 1
	if given <= 0:
		return false
	assigned_rods += given
	toast_requested.emit("Đã giao %d lượt câu cho %s! 🎣 (Tổng giữ: %d lượt)" % [given, cat_name, assigned_rods], Color(0.4, 0.85, 1.0))
	if state == State.IDLE or state == State.SLEEPING or state == State.WALKING_TO_TENT:
		if GameState.clock < get_sleep_clock() and GameState.clock >= GameState.DAY_START:
			state = State.IDLE
			visible = true
			_find_next_fishing_job()
	return true


func take_back_rods(amount: int = -1) -> bool:
	if assigned_rods <= 0:
		return false
	var take_n: int = assigned_rods if amount < 0 else mini(assigned_rods, amount)
	assigned_rods -= take_n
	Inventory.add_rod("basic", take_n)
	toast_requested.emit("Đã lấy lại %d lượt câu từ %s! 🎣 (Còn %d lượt)" % [take_n, cat_name, assigned_rods], Color(0.85, 0.85, 0.85))
	if assigned_rods <= 0 and (state == State.WORKING or state == State.WALKING_TO_JOB):
		current_job.clear()
		if _total_bag_items() > 0:
			state = State.WALKING_TO_SHED
			_set_destination(SHED_DOOR_POS)
			_show_bubble_text("📦")
		else:
			state = State.WALKING_TO_TENT
			_set_destination(get_sleep_pos())
			_show_bubble_text("🎣?")
	return true


func give_seeds(seed_id: String, amount: int) -> bool:
	if amount <= 0:
		return false
	if not Inventory.take_seed(seed_id, amount):
		return false
	assigned_seeds[seed_id] = int(assigned_seeds.get(seed_id, 0)) + amount
	return true


func take_back_seeds(seed_id: String, amount: int = -1) -> bool:
	var cur: int = int(assigned_seeds.get(seed_id, 0))
	if cur <= 0:
		return false
	var take_n := cur if amount < 0 else mini(cur, amount)
	if not Inventory.can_hold("seeds", seed_id):
		toast_requested.emit("Túi đồ của bạn đã đầy!", Color(1.0, 0.5, 0.4))
		return false
	assigned_seeds[seed_id] = cur - take_n
	if assigned_seeds[seed_id] <= 0:
		assigned_seeds.erase(seed_id)
	Inventory.add_seed(seed_id, take_n)
	return true


# ---------- Hiệu ứng Bong bóng suy nghĩ ----------

func _show_bubble_text(txt: String) -> void:
	if _bubble == null or _bubble_label == null:
		return
	_bubble_label.text = txt
	_bubble.visible = true


func _hide_bubble() -> void:
	if _bubble != null:
		_bubble.visible = false


func _start_bubble_bob() -> void:
	if _bubble_tween != null and _bubble_tween.is_valid():
		_bubble_tween.kill()
	_bubble_tween = create_tween().set_loops()
	_bubble_tween.tween_property(_bubble, "position:y", -61.0, 0.7).set_trans(Tween.TRANS_SINE)
	_bubble_tween.tween_property(_bubble, "position:y", -57.0, 0.7).set_trans(Tween.TRANS_SINE)


func _make_bubble_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.96)
	sb.border_color = Color(0.25, 0.20, 0.16, 0.75)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 1)
	return sb


# ---------- Lưu & Tải trạng thái ----------

func get_save_dict() -> Dictionary:
	return {
		"cat_breed": cat_breed,
		"cat_role": cat_role,
		"daily_wage": daily_wage,
		"is_hired": is_hired,
		"water_level": water_level,
		"assigned_hoes": assigned_hoes,
		"assigned_rods": assigned_rods,
		"assigned_seeds": assigned_seeds.duplicate(),
		"harvest_bag": harvest_bag.duplicate(),
		"sell_targets": sell_targets.duplicate(),
		"total_sales_revenue": total_sales_revenue,
		"wage_paid_today": wage_paid_today,
		"x": position.x,
		"y": position.y,
		"state": state,
		"speed_level": speed_level,
		"work_level": work_level,
		"bag_level": bag_level
	}


func load_save_dict(d: Dictionary) -> void:
	cat_breed = str(d.get("cat_breed", cat_breed))
	if d.has("cat_role"):
		cat_role = str(d["cat_role"])
	elif cat_breed == "orange":
		cat_role = "gardener"
	elif cat_breed == "white":
		cat_role = "fisher"
	elif cat_breed == "tuxedo":
		cat_role = "seller"
	else:
		cat_role = "miner"

	# Migration: Calico swapped to miner, Orange swapped to gardener
	if cat_breed == "calico" and cat_role == "gardener":
		cat_role = "miner"
		daily_wage = 100
	elif cat_breed == "orange" and cat_role == "miner":
		cat_role = "gardener"
		daily_wage = 50

	if d.has("daily_wage"):
		daily_wage = int(d["daily_wage"])
	elif cat_breed == "orange":
		daily_wage = 50
	elif cat_breed == "white":
		daily_wage = 75
	elif cat_breed == "tuxedo":
		daily_wage = 80
	else:
		daily_wage = 100

	if cat_breed == "orange":
		cat_name = "Mèo Mướp Vàng"
	elif cat_breed == "white":
		cat_name = "Mèo Trắng Tuyết"
	elif cat_breed == "tuxedo":
		cat_name = "Mèo Mun Tuxedo"
	else:
		cat_name = "Mèo Tam Thể"
	if _spr != null:
		_spr.texture = _tex(facing_dir, 0)
	is_hired = bool(d.get("is_hired", false))
	speed_level = int(d.get("speed_level", 1))
	work_level = int(d.get("work_level", 1))
	bag_level = int(d.get("bag_level", 1))
	speed = get_speed_for_level(speed_level)
	water_capacity = get_water_capacity_for_level(bag_level)
	water_level = int(d.get("water_level", water_capacity))
	assigned_hoes = int(d.get("assigned_hoes", 0))
	assigned_rods = int(d.get("assigned_rods", 0))
	assigned_seeds = d.get("assigned_seeds", {}).duplicate()
	harvest_bag = d.get("harvest_bag", {}).duplicate()
	sell_targets = d.get("sell_targets", {}).duplicate()
	total_sales_revenue = int(d.get("total_sales_revenue", 0))
	wage_paid_today = bool(d.get("wage_paid_today", false))
	if d.has("x") and d.has("y"):
		position = Vector2(float(d["x"]), float(d["y"]))
	if is_hired:
		state = int(d.get("state", State.IDLE))
		_hide_bubble()
		if state == State.SLEEPING or (state == State.IDLE and position.distance_to(get_sleep_pos()) <= 25.0):
			visible = false
		else:
			visible = true
	else:
		state = State.WAITING_HIRE
		if cat_breed == "orange" or cat_breed == "white" or cat_breed == "tuxedo":
			visible = false
			position = get_sleep_pos()
			_hide_bubble()
		else:
			visible = true
			if not (d.has("x") and d.has("y")):
				position = WAITING_POS
			_show_bubble_text("...")
