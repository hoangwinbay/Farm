extends Node
# Trạng thái chung: tiền, ngày, giờ trong ngày, cây đã mở khóa.

signal money_changed(value: int)
signal crops_changed
signal stamina_changed(value: float, max_value: float)

const CropDB := preload("res://scripts/crop_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")

const MINUTES_PER_SEC := 1200.0 / 900.0  # 1 ngày = 20h trong game = 15 phút thật
const DAY_START := 420          # 7:00 sáng
const COLLAPSE_MIN := 120       # 2:00 sáng — chưa ngủ thì gục ngã
const MINUTES_PER_DAY := 1440
const MAX_STAMINA_DEFAULT: float = 100.0

var money := 100
var day := 1
var unlocked: Array = ["rice"]
var clock: float = DAY_START  # phải là float — kiểu int sẽ làm đồng hồ không chạy
var stamina: float = 100.0
var max_stamina: float = 100.0


func reset_new_game() -> void:
	money = 100
	day = 1
	clock = DAY_START
	unlocked = ["rice"]
	stamina = MAX_STAMINA_DEFAULT
	max_stamina = MAX_STAMINA_DEFAULT
	money_changed.emit(money)
	crops_changed.emit()
	stamina_changed.emit(stamina, max_stamina)


func add_stamina(v: float) -> void:
	stamina = clampf(stamina + v, 0.0, max_stamina)
	stamina_changed.emit(stamina, max_stamina)


func use_stamina(v: float) -> bool:
	stamina = clampf(stamina - v, 0.0, max_stamina)
	stamina_changed.emit(stamina, max_stamina)
	return stamina > 0.0


func is_exhausted() -> bool:
	return stamina <= 0.0


func get_food_stamina(category: String, id: String) -> int:
	match category:
		"crop", "produce":
			var c := CropDB.get_crop(id)
			if not c.is_empty():
				match id:
					"watermelon": return 40
					"coffee": return 35
					"sweet_potato", "sugarcane": return 25
					"corn": return 22
					"cassava", "potato", "cabbage", "peanut": return 20
					"carrot", "tomato", "soybean": return 18
					"rice", "wheat": return 15
					"pepper": return 10
					"rubber", "sau_bo": return 0
					_: return 15
			# Kiểm tra nếu là sản phẩm gia cầm trong túi produce
			match id:
				"thit_ngan": return 60
				"thit_bocau": return 55
				"thit_vit": return 50
				"thit_ga": return 45
				"trung_da_dieu": return 65
				"trung_vuon": return 25
				"trung_vit": return 22
				"trung_ga": return 20
				"trung_cut": return 15
				_: return 0
		"poultry", "meat":
			match id:
				"thit_ngan": return 60
				"thit_bocau": return 55
				"thit_vit": return 50
				"thit_ga": return 45
				"trung_da_dieu": return 65
				"trung_vuon": return 25
				"trung_vit": return 22
				"trung_ga": return 20
				"trung_cut": return 15
				_: return 0
		"fish":
			var f := FishDB.get_fish(id)
			if not f.is_empty():
				return 30
	return 0


func get_food_name(category: String, id: String) -> String:
	match category:
		"crop", "produce":
			var c := CropDB.get_crop(id)
			if not c.is_empty():
				return str(c.get("name", id))
			for a in PoultryDB.ANIMALS:
				if str(a.product) == id:
					return str(a.product_name)
		"poultry", "meat":
			for a in PoultryDB.ANIMALS:
				if str(a.product) == id:
					return str(a.product_name)
		"fish":
			var f := FishDB.get_fish(id)
			if not f.is_empty():
				return str(f.get("name", id))
	return id


func eat_food(category: String, id: String) -> Dictionary:
	var rec := get_food_stamina(category, id)
	if rec <= 0:
		return {"ok": false, "reason": "not_edible", "msg": "Món này không thể ăn được!"}
	if stamina >= max_stamina:
		return {"ok": false, "reason": "full", "msg": "Thể lực đã tràn đầy (%d/%d), không cần ăn thêm!" % [int(stamina), int(max_stamina)]}
	
	var count := 0
	var cat_key := category
	if category == "crop" or category == "produce" or category == "poultry" or category == "meat":
		count = Inventory.produce_count(id)
		cat_key = "produce"
	elif category == "fish":
		count = Inventory.fish_count(id)
		cat_key = "fish"
	
	if count < 1:
		return {"ok": false, "reason": "none", "msg": "Không có món này trong túi!"}
	
	if cat_key == "produce":
		Inventory.take_produce(id, 1)
	elif cat_key == "fish":
		Inventory.take_fish(id, 1)
	
	var old_stam := stamina
	add_stamina(rec)
	var recovered := int(stamina - old_stam)
	var fname := get_food_name(category, id)
	
	return {
		"ok": true,
		"recovered": recovered,
		"stamina": int(stamina),
		"max_stamina": int(max_stamina),
		"msg": "Đã ăn 1 %s, hồi +%d thể lực! ⚡ (%d/%d)" % [fname, recovered, int(stamina), int(max_stamina)]
	}


func add_money(v: int) -> void:
	money += v
	money_changed.emit(money)


func try_spend(v: int) -> bool:
	if money < v:
		return false
	money -= v
	money_changed.emit(money)
	return true


func has_crop(id: String) -> bool:
	return unlocked.has(id)


func next_locked() -> Dictionary:
	return CropDB.next_locked(unlocked)


func unlock_next() -> bool:
	var c := next_locked()
	if c.is_empty():
		return false
	if money < int(c.unlock_cost):
		return false
	money -= int(c.unlock_cost)
	unlocked.append(str(c.id))
	money_changed.emit(money)
	crops_changed.emit()
	return true


func tick(delta: float) -> void:
	clock += delta * MINUTES_PER_SEC
	if clock >= MINUTES_PER_DAY:
		# 0h đêm: sang ngày mới tự động
		clock -= MINUTES_PER_DAY
		day += 1


# Ngủ: nếu ngủ trước 6h sáng thì dậy ngay 6h cùng ngày, sau 6h thì dậy 6h hôm sau.
func sleep_to_morning(forced: bool = false) -> void:
	if clock >= DAY_START:
		day += 1
	clock = DAY_START
	if forced:
		stamina = max_stamina * 0.6  # gục ngã vì kiệt sức chỉ hồi 60% thể lực
	else:
		stamina = max_stamina        # ngủ đủ giấc hồi 100% thể lực
	stamina_changed.emit(stamina, max_stamina)


func clock_text() -> String:
	return "%02d:%02d" % [int(clock) / 60, int(clock) % 60]
