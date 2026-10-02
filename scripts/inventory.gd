extends Node
# Kho đồ: hạt giống + nông sản thu hoạch, hạt đang chọn để gieo.

signal changed

const CropDB := preload("res://scripts/crop_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")

var seeds: Dictionary = {}
var produce: Dictionary = {}
var selected_seed := ""
var hoes := 0
var rods: Dictionary = {}  # tier -> số lượt câu còn lại
var fish: Dictionary = {}  # fish_id -> số lượng
var coops: Dictionary = {"small": 0, "large": 0}  # số chuồng đã mua theo loại
var animals: Array = []  # [{id, progress, ready}]


func reset() -> void:
	seeds = {}
	produce = {}
	selected_seed = ""
	hoes = 0
	rods = {}
	fish = {}
	coops = {"small": 0, "large": 0}
	animals = []
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
		while int(a.ready) > 0:
			a.ready = int(a.ready) - 1
			add_produce(str(PoultryDB.get_animal(str(a.id)).product), 1)
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
	changed.emit()
	return selected_seed


func get_state() -> Dictionary:
	return {"seeds": seeds.duplicate(), "produce": produce.duplicate(), "sel": selected_seed,
			"hoes": hoes, "rods": rods.duplicate(), "fish": fish.duplicate(),
			"coops": coops.duplicate(), "animals": animals.duplicate(true)}


func set_state(d: Dictionary) -> void:
	seeds = {}
	produce = {}
	rods = {}
	fish = {}
	animals = []
	coops = {"small": 0, "large": 0}
	if d.has("seeds"):
		for k in d["seeds"]:
			seeds[str(k)] = int(d["seeds"][k])
	if d.has("produce"):
		for k in d["produce"]:
			produce[str(k)] = int(d["produce"][k])
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
	selected_seed = str(d.get("sel", ""))
	hoes = int(d.get("hoes", 0))
	changed.emit()
