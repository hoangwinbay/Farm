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
	SLEEPING
}

const WAITING_POS := Vector2(618, 305)
const DOORSTEP_POS := Vector2(656, 260)
const ROAD_JUNCTION_POS := Vector2(656, 472)
const SPAWN_POS := Vector2(370, 472)
const TENT_SLEEP_POS := Vector2(766, 246)
const SHED_DOOR_POS := Vector2(505, 258)
const POND_REFILL_POS := Vector2(1410, 750)
const FARM_GATE_WEST := Vector2(824, 472)

var state: int = State.ARRIVING
var is_hired: bool = false
var speed: float = 42.0
var work_timer: float = 0.0
var anim_t: float = 0.0
var facing_dir: String = "down"

var speed_level: int = 1
var work_level: int = 1
var bag_level: int = 1
const MAX_UPGRADE_LEVEL := 5

var water_capacity: int = 15
var water_level: int = 15
var assigned_hoes: int = 0
var assigned_seeds: Dictionary = {}  # seed_id -> count
var harvest_bag: Dictionary = {}     # item_id -> count
var daily_wage: int = 50
var wage_paid_today: bool = false

var farm: Node2D = null
var current_job: Dictionary = {}
var waypoints: Array = []
var _target_tile: Node = null


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


func get_max_bag_for_level(lvl: int) -> int:
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
			toast_requested.emit("Nâng cấp Năng suất Mèo lên Cấp %d! ⏱️ (Làm việc đến %02d:00)" % [work_level, sleep_hr], Color(0.65, 1.0, 0.65))
		"bag":
			bag_level += 1
			water_capacity = get_water_capacity_for_level(bag_level)
			water_level = water_capacity
			toast_requested.emit("Nâng cấp Túi đồ Mèo lên Cấp %d! 🎒 (Túi %d món, Bình %d giọt)" % [bag_level, get_max_bag(), water_capacity], Color(0.4, 0.85, 1.0))
	return true

var _spr: Sprite2D
var _shadow: Sprite2D
var _bubble: PanelContainer
var _bubble_label: Label
var _bubble_icon: TextureRect
var _bubble_tween: Tween
var _scan_timer: float = 0.0


func _ready() -> void:
	z_as_relative = true

	# 1. Bóng đổ chân nhân vật
	_shadow = Sprite2D.new()
	_shadow.texture = TextureGen.get_tex("shadow")
	_shadow.scale = Vector2(0.9, 0.7)
	_shadow.position = Vector2(0, 0)
	add_child(_shadow)

	# 2. Sprite chú mèo tam thể
	_spr = Sprite2D.new()
	_spr.scale = Vector2(1.25, 1.25)
	_spr.offset = Vector2(0, -16)
	_spr.texture = TextureGen.cat_char_tex("down", 0)
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
		position = SPAWN_POS
		state = State.ARRIVING
		waypoints = [ROAD_JUNCTION_POS, Vector2(ROAD_JUNCTION_POS.x, WAITING_POS.y), WAITING_POS]
		_show_bubble_text("...")
	else:
		position = WAITING_POS
		state = State.IDLE
		_hide_bubble()


func _process(delta: float) -> void:
	# Kiểm tra giờ đi ngủ vào buổi tối (dựa trên cấp độ thời gian làm việc)
	if is_hired and GameState.clock >= get_sleep_clock():
		if state != State.WALKING_TO_TENT and state != State.SLEEPING:
			_pay_daily_wage()
			state = State.WALKING_TO_TENT
			_set_destination(TENT_SLEEP_POS)
			_show_bubble_text("😴")

	# Kiểm tra trời sáng (từ 7:00 sáng)
	if state == State.SLEEPING and GameState.clock < get_sleep_clock() and GameState.clock >= GameState.DAY_START:
		wage_paid_today = false
		state = State.IDLE
		_hide_bubble()

	match state:
		State.ARRIVING:
			_process_walk(delta, func():
				# Đến trước cửa nhà người chơi
				state = State.WAITING_HIRE
				facing_dir = "down"
				_spr.texture = TextureGen.cat_char_tex("down", 0)
				_spr.flip_h = false
				_show_bubble_text("...")
			)

		State.WAITING_HIRE:
			_spr.texture = TextureGen.cat_char_tex("down", 0)
			# Đứng chờ người chơi đến phỏng vấn / thuê

		State.IDLE:
			_scan_timer += delta
			if _scan_timer >= 0.5:
				_scan_timer = 0.0
				_find_next_job()

		State.WALKING_TO_JOB:
			_process_walk(delta, func():
				state = State.WORKING
				work_timer = 0.0
				_spr.texture = TextureGen.cat_char_tex("act", 0)
			)

		State.WORKING:
			work_timer += delta
			_spr.texture = TextureGen.cat_char_tex("act", 0)
			if work_timer >= get_work_duration():
				_complete_job()
				state = State.IDLE
				_hide_bubble()

		State.WALKING_TO_POND:
			_process_walk(delta, func():
				state = State.REFILLING
				work_timer = 0.0
				_spr.texture = TextureGen.cat_char_tex("act", 0)
				_show_bubble_text("💧+")
			)

		State.REFILLING:
			work_timer += delta
			_spr.texture = TextureGen.cat_char_tex("act", 0)
			if work_timer >= get_refill_duration():
				water_level = water_capacity
				state = State.IDLE
				_hide_bubble()
				toast_requested.emit("Mèo đã múc đầy bình nước từ ao! 💧 (%d/%d)" % [water_level, water_capacity], Color(0.4, 0.85, 1.0))

		State.WALKING_TO_SHED:
			_process_walk(delta, func():
				state = State.DEPOSITING
				work_timer = 0.0
				_spr.texture = TextureGen.cat_char_tex("up", 0)
				_show_bubble_text("📦")
			)

		State.DEPOSITING:
			work_timer += delta
			if work_timer >= get_deposit_duration():
				_deposit_items_to_shed()
				state = State.IDLE
				_hide_bubble()

		State.WALKING_TO_TENT:
			_process_walk(delta, func():
				state = State.SLEEPING
				_spr.texture = TextureGen.cat_char_tex("down", 0)
				_show_bubble_text("Zzz...")
			)

		State.SLEEPING:
			_spr.texture = TextureGen.cat_char_tex("down", 0)


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

	if absf(dir.y) > absf(dir.x) * 1.2:
		if dir.y > 0:
			facing_dir = "down"
			_spr.texture = TextureGen.cat_char_tex("down", frame_idx % 3)
			_spr.flip_h = false
		else:
			facing_dir = "up"
			_spr.texture = TextureGen.cat_char_tex("up", frame_idx % 3)
			_spr.flip_h = false
	else:
		facing_dir = "side"
		_spr.texture = TextureGen.cat_char_tex("side", frame_idx % 2)
		_spr.flip_h = (dir.x < 0)


func _set_destination(dest: Vector2) -> void:
	waypoints.clear()

	# Hệ thống định tuyến thông minh tránh va chạm nhà, chuồng và sạp hàng
	var from_p := position

	# Di chuyển giữa khu nhà phía Bắc (y < 350) và ruộng/ao phía Nam (y >= 350)
	if from_p.y < 350.0 and dest.y >= 350.0:
		if from_p.x < 240.0:
			waypoints.append(Vector2(ROAD_JUNCTION_POS.x, from_p.y))
		waypoints.append(Vector2(ROAD_JUNCTION_POS.x, 472.0))
		if dest.x >= 424.0:
			waypoints.append(FARM_GATE_WEST)
		waypoints.append(dest)
	elif from_p.y >= 350.0 and dest.y < 350.0:
		if from_p.x >= 424.0:
			waypoints.append(FARM_GATE_WEST)
		waypoints.append(Vector2(ROAD_JUNCTION_POS.x, 472.0))
		if dest.x < 240.0:
			waypoints.append(Vector2(ROAD_JUNCTION_POS.x, dest.y))
		waypoints.append(dest)
	elif from_p.y < 350.0 and dest.y < 350.0:
		# Giữa các công trình cạnh nhau (Nhà kho <-> Nhà <-> Lều)
		waypoints.append(Vector2(from_p.x, 280.0))
		waypoints.append(Vector2(dest.x, 280.0))
		waypoints.append(dest)
	else:
		waypoints.append(dest)


# ---------- Quản lý công việc nông trại ----------

func _find_next_job() -> void:
	if farm == null or not ("tiles" in farm):
		return

	# Nếu đã gom được kha khá nông sản hoặc không còn việc gấp, đem cất vào Nhà Kho
	var bag_count := _total_bag_items()
	if bag_count >= get_max_bag():
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
		state = State.WALKING_TO_SHED
		_set_destination(SHED_DOOR_POS)
		_show_bubble_text("📦")
		return


func _start_tile_job(type: String, tile: Node, bubble_icon_text: String) -> void:
	current_job = {"type": type, "tile": tile}
	_target_tile = tile
	state = State.WALKING_TO_JOB
	var center_p: Vector2 = farm.tile_center(tile.coord)
	_set_destination(center_p)
	_show_bubble_text(bubble_icon_text)


func _complete_job() -> void:
	if _target_tile == null or not is_instance_valid(_target_tile):
		current_job.clear()
		return

	var job_type: String = str(current_job.get("type", ""))
	match job_type:
		"pest":
			if _target_tile.has_pest:
				_target_tile.clear_pest()
				harvest_bag["sau_bo"] = int(harvest_bag.get("sau_bo", 0)) + 1
				toast_requested.emit("Mèo đã bắt được 1 con sâu bọ! 🐛", Color(0.6, 0.9, 0.4))

		"harvest":
			if _target_tile.is_ready():
				var cid: String = _target_tile.harvest()
				if cid != "":
					harvest_bag[cid] = int(harvest_bag.get(cid, 0)) + 1
					var cdata := CropDB.get_crop(cid)
					var cname := str(cdata.get("name", "nông sản"))
					toast_requested.emit("Mèo đã thu hoạch %s! 🌾" % cname, Color(0.65, 1.0, 0.6))

		"till":
			if assigned_hoes > 0 and (_target_tile.tstate == FarmTileScript.TState.HARVESTED or _target_tile.tstate == FarmTileScript.TState.GRASS):
				_target_tile.till()
				assigned_hoes -= 1
				toast_requested.emit("Mèo đã cuốc xới đất xong! ⛏️ (Còn %d cuốc)" % assigned_hoes, Color(0.9, 0.8, 0.5))

		"water":
			if not _target_tile.watered:
				_target_tile.water()
				water_level = maxi(0, water_level - 1)

		"plant":
			var sid: String = str(current_job.get("seed_id", ""))
			if sid != "" and int(assigned_seeds.get(sid, 0)) > 0:
				if _target_tile.tstate == FarmTileScript.TState.TILLED:
					_target_tile.plant(sid)
					assigned_seeds[sid] = int(assigned_seeds.get(sid, 0)) - 1
					if assigned_seeds[sid] <= 0:
						assigned_seeds.erase(sid)

	current_job.clear()
	_target_tile = null


func _find_nearest_tile(condition: Callable) -> Node:
	if farm == null or not ("tiles" in farm):
		return null
	var best_tile: Node = null
	var min_d := 999999.0
	for t in farm.tiles.values():
		if condition.call(t):
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
	for k in harvest_bag:
		var count: int = int(harvest_bag[k])
		if count > 0:
			Inventory.direct_store("produce", str(k), count)
			items_stored += count
	harvest_bag.clear()
	toast_requested.emit("Mèo đã cất %d món thu hoạch vào Nhà Kho! 🏚️✨" % items_stored, Color(0.9, 0.8, 0.4))


# ---------- Thuê & Trả lương ----------

func hire() -> void:
	is_hired = true
	state = State.IDLE
	_show_bubble_text("Meo! 🐱❤️")
	hired.emit()
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(func():
		if state == State.IDLE:
			_hide_bubble()
	)


func dismiss() -> void:
	is_hired = false
	state = State.WAITING_HIRE
	position = WAITING_POS
	_show_bubble_text("...")


func _pay_daily_wage() -> void:
	if wage_paid_today or not is_hired:
		return
	if GameState.try_spend(daily_wage):
		wage_paid_today = true
		toast_requested.emit("Đã trả lương %d xu cho Chú Mèo chăm chỉ! 🐱💰" % daily_wage, Color(1.0, 0.9, 0.4))
	else:
		toast_requested.emit("Hôm nay không đủ tiền trả lương cho Chú Mèo! 😿", Color(1.0, 0.5, 0.4))


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
		"is_hired": is_hired,
		"water_level": water_level,
		"assigned_hoes": assigned_hoes,
		"assigned_seeds": assigned_seeds.duplicate(),
		"harvest_bag": harvest_bag.duplicate(),
		"wage_paid_today": wage_paid_today,
		"x": position.x,
		"y": position.y,
		"state": state,
		"speed_level": speed_level,
		"work_level": work_level,
		"bag_level": bag_level
	}


func load_save_dict(d: Dictionary) -> void:
	is_hired = bool(d.get("is_hired", false))
	speed_level = int(d.get("speed_level", 1))
	work_level = int(d.get("work_level", 1))
	bag_level = int(d.get("bag_level", 1))
	speed = get_speed_for_level(speed_level)
	water_capacity = get_water_capacity_for_level(bag_level)
	water_level = int(d.get("water_level", water_capacity))
	assigned_hoes = int(d.get("assigned_hoes", 0))
	assigned_seeds = d.get("assigned_seeds", {}).duplicate()
	harvest_bag = d.get("harvest_bag", {}).duplicate()
	wage_paid_today = bool(d.get("wage_paid_today", false))
	if d.has("x") and d.has("y"):
		position = Vector2(float(d["x"]), float(d["y"]))
	if is_hired:
		state = int(d.get("state", State.IDLE))
		_hide_bubble()
	else:
		state = State.WAITING_HIRE
		if not (d.has("x") and d.has("y")):
			position = WAITING_POS
		_show_bubble_text("...")
