extends CharacterBody2D
class_name PenAnimal

# Quản lý hành vi của một con vật trong chuồng:
# - Di chuyển qua lại (wander) trong chuồng.
# - Đi tới máng ăn và ăn thức ăn khi được cho ăn.
# - Hiện bong bóng túi cám khi đói.
# - Sau khi ăn, chờ một lúc để sinh sản phẩm tùy loài.
# - Khi có thể thu hoạch: ĐỨNG YÊN và hiện bong bóng sản phẩm.
# - Thu hoạch xong có thể ngay lập tức cho ăn tiếp!

const PoultryDB := preload("res://scripts/poultry_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")

signal feed_requested(animal)
signal harvest_requested(animal)

enum State {
	IDLE,
	WANDER,
	WALK_TO_TROUGH,
	EATING,
	READY # Có sản phẩm để thu hoạch -> ĐỨNG YÊN!
}

var species_id: String = "chicken"
var animal_data: Dictionary = {}
var animal_index: int = 0
var pen_rect: Rect2 = Rect2()
var trough_pos: Vector2 = Vector2.ZERO

var state: int = State.IDLE

var spr: Sprite2D
var shadow_spr: Sprite2D
var bubble_spr: Sprite2D
var heart_spr: Sprite2D

var idle_timer: float = 1.0
var eating_timer: float = 0.0
var target_pos: Vector2 = Vector2.ZERO
var move_speed: float = 22.0

var h_frames: int = 4
var v_frames: int = 7
var frame_timer: float = 0.0
var walk_frame_index: int = 0
var current_facing: Vector2 = Vector2.DOWN

var is_baby: bool = false
var is_sheared: bool = false
var _bubble_base_y: float = -20.0
var _bubble_time: float = 0.0
var _eating_bob_time: float = 0.0


func setup(sid: String, data: Dictionary, idx: int, p_rect: Rect2, t_pos: Vector2) -> void:
	species_id = PoultryDB.get_canonical_id(sid)
	animal_data = data
	animal_index = idx
	pen_rect = p_rect
	trough_pos = t_pos

	var d := PoultryDB.get_animal(species_id)
	is_baby = bool(animal_data.get("is_baby", false))
	is_sheared = bool(animal_data.get("is_sheared", false))

	# Tốc độ di chuyển tùy loài
	match species_id:
		"chicken":
			move_speed = 26.0 if is_baby else 22.0
		"pig":
			move_speed = 22.0 if is_baby else 18.0
		"cow":
			move_speed = 18.0 if is_baby else 15.0
		"sheep":
			move_speed = 20.0 if is_baby else 16.0
		_:
			move_speed = 20.0

	_build_visuals(d)
	_sync_state()


func _build_visuals(d: Dictionary) -> void:
	# 1. Bóng đổ dưới chân
	shadow_spr = Sprite2D.new()
	shadow_spr.texture = TextureGen.shadow_tex()
	if species_id == "chicken":
		shadow_spr.scale = Vector2(0.7, 0.5) if is_baby else Vector2(0.9, 0.6)
		shadow_spr.position = Vector2(0, 4)
	else:
		shadow_spr.scale = Vector2(1.1, 0.7) if is_baby else Vector2(1.5, 0.9)
		shadow_spr.position = Vector2(0, 8)
	shadow_spr.modulate = Color(0, 0, 0, 0.45)
	add_child(shadow_spr)

	# 2. Sprite chính của con vật
	spr = Sprite2D.new()
	var tex: Texture2D = TextureGen.get_animal_tex(species_id, is_baby, is_sheared)
	if tex == null:
		tex = TextureGen.get_animal_icon(species_id, is_baby, is_sheared)
	spr.texture = tex

	h_frames = int(d.get("hframes", 4))
	v_frames = int(d.get("baby_vframes", 5) if is_baby else d.get("vframes", 5))
	spr.hframes = h_frames
	spr.vframes = v_frames

	if species_id == "chicken":
		spr.scale = Vector2(1.2, 1.2) if is_baby else Vector2(1.6, 1.6)
		_bubble_base_y = -22.0
	else:
		spr.scale = Vector2(1.0, 1.0) if is_baby else Vector2(1.4, 1.4)
		_bubble_base_y = -26.0

	spr.frame = 0
	add_child(spr)

	# 3. Bong bóng suy nghĩ (túi cám hoặc sản phẩm thu hoạch)
	bubble_spr = Sprite2D.new()
	bubble_spr.z_index = 8
	bubble_spr.position = Vector2(0, _bubble_base_y)
	bubble_spr.visible = false
	add_child(bubble_spr)

	# 4. Icon trái tim nhỏ khi được cho ăn
	heart_spr = Sprite2D.new()
	heart_spr.texture = TextureGen.star_icon() # fallback lấp lánh/trái tim
	heart_spr.z_index = 9
	heart_spr.position = Vector2(0, _bubble_base_y)
	heart_spr.visible = false
	add_child(heart_spr)

	# Đặt vị trí ban đầu ngẫu nhiên trong chuồng
	if position == Vector2.ZERO:
		position = _get_random_yard_point()


func _process(delta: float) -> void:
	_bubble_time += delta * 3.5

	# Đồng bộ trạng thái từ dữ liệu
	_sync_state()

	# Xử lý theo từng trạng thái
	match state:
		State.READY:
			# Có sản phẩm thu hoạch: ĐỨNG YÊN hoàn toàn!
			velocity = Vector2.ZERO
			spr.frame = _get_idle_frame()
			_update_bubble(true, false)

		State.EATING:
			# Đang ăn thức ăn trong máng
			velocity = Vector2.ZERO
			_eating_bob_time += delta * 8.0
			_update_eating_frame(delta)
			eating_timer -= delta
			if eating_timer <= 0.0:
				# Ăn xong! Tiếp tục di chuyển và tiêu hóa
				state = State.IDLE
				idle_timer = randf_range(1.5, 3.5)
			_update_bubble(false, false)

		State.WALK_TO_TROUGH:
			# Đang đi tới máng ăn
			_move_towards(target_pos, delta)
			if position.distance_to(target_pos) < 3.0:
				position = target_pos
				state = State.EATING
				eating_timer = randf_range(3.5, 5.0)
				_eating_bob_time = 0.0
			_update_bubble(false, false)

		State.WANDER:
			# Đi dạo qua lại trong chuồng
			_move_towards(target_pos, delta)
			if position.distance_to(target_pos) < 3.0:
				position = target_pos
				state = State.IDLE
				idle_timer = randf_range(2.0, 4.5)
			var is_hungry: bool = not bool(animal_data.get("fed", false))
			_update_bubble(false, is_hungry)

		State.IDLE:
			# Đứng nghỉ / mổ nhẹ tại chỗ
			velocity = Vector2.ZERO
			spr.frame = _get_idle_frame()
			idle_timer -= delta
			if idle_timer <= 0.0:
				target_pos = _get_random_yard_point()
				state = State.WANDER
			var is_hungry_idle: bool = not bool(animal_data.get("fed", false))
			_update_bubble(false, is_hungry_idle)


func _sync_state() -> void:
	var ready_count: int = int(animal_data.get("ready", 0))
	if ready_count > 0:
		if state != State.READY:
			state = State.READY
			velocity = Vector2.ZERO
		return

	# Nếu đã thu hoạch xong và trước đó đang ở READY -> trở về IDLE
	if state == State.READY and ready_count == 0:
		state = State.IDLE
		idle_timer = randf_range(0.5, 1.5)


func _update_bubble(ready_now: bool, hungry_now: bool) -> void:
	if ready_now:
		bubble_spr.visible = true
		var d := PoultryDB.get_animal(species_id)
		var prod_id := str(d.get("product", ""))
		bubble_spr.texture = TextureGen.get_harvest_bubble(prod_id)
		bubble_spr.position.y = _bubble_base_y + sin(_bubble_time) * 2.5
	elif can_slaughter():
		# Đã ăn đủ 5 lần: hiện bong bóng thịt Stardew Valley sẵn sàng chém lấy thịt!
		bubble_spr.visible = true
		var meat_id: String = PoultryDB.get_animal_meat_id(species_id)
		bubble_spr.texture = TextureGen.get_harvest_bubble(meat_id)
		bubble_spr.position.y = _bubble_base_y + sin(_bubble_time) * 2.5
	elif hungry_now:
		# Hiện bong bóng túi cám Stardew Valley!
		bubble_spr.visible = true
		bubble_spr.texture = TextureGen.get_feed_bubble()
		bubble_spr.position.y = _bubble_base_y + sin(_bubble_time) * 2.5
	else:
		bubble_spr.visible = false


func _move_towards(destination: Vector2, delta: float) -> void:
	var diff := destination - position
	var dist := diff.length()
	if dist <= move_speed * delta or dist < 1.0:
		position = destination
		return
	var dir := diff.normalized()
	current_facing = dir
	position += dir * move_speed * delta

	# Lật mặt theo hướng ngang
	if dir.x < -0.15:
		spr.flip_h = true
	elif dir.x > 0.15:
		spr.flip_h = false

	# Cập nhật khung hình bước đi
	frame_timer += delta * 6.0
	walk_frame_index = int(frame_timer) % 4
	var base_row := 1 # Hướng ngang
	if abs(dir.y) > abs(dir.x) * 1.5:
		if dir.y < 0:
			base_row = 2 # Hướng lên Bắc
		else:
			base_row = 0 # Hướng xuống Nam
	spr.frame = base_row * h_frames + walk_frame_index


func _update_eating_frame(_delta: float) -> void:
	# Mặt hướng lên máng ăn (Bắc) hoặc cúi đầu ăn
	spr.flip_h = false
	if species_id == "chicken":
		# Khung mổ thóc (hàng 4 hoặc nhấp nhô đầu)
		var bob: int = int(_eating_bob_time) % 2
		spr.frame = 4 * h_frames + bob if (4 * h_frames + bob) < (h_frames * v_frames) else 1
		spr.position.y = 1.5 if bob == 1 else 0.0
	else:
		# Khung gặm cỏ/ăn máng (hàng 3)
		var chew: int = int(_eating_bob_time) % 3
		spr.frame = 3 * h_frames + chew if (3 * h_frames + chew) < (h_frames * v_frames) else 4
		spr.position.y = 1.0 if chew > 0 else 0.0


func _get_idle_frame() -> int:
	spr.position.y = 0.0
	if abs(current_facing.x) > abs(current_facing.y):
		return h_frames * 1 # Khung idle ngang
	elif current_facing.y < 0:
		return h_frames * 2 # Khung idle nhìn lên
	return 0 # Khung idle nhìn xuống


func _get_random_yard_point() -> Vector2:
	var rx := pen_rect.position.x
	var ry := pen_rect.position.y
	var rw := pen_rect.size.x
	var rh := pen_rect.size.y

	var min_x := rx + 36.0
	var max_x := rx + rw - 36.0
	var min_y := ry + 64.0
	var max_y := ry + rh - 22.0

	return Vector2(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y)
	)


func get_trough_eating_spot() -> Vector2:
	# Vị trí đứng trước máng ăn (máng tại trough_pos)
	var offset_x: float = -20.0 + (animal_index % 3) * 20.0
	return Vector2(trough_pos.x + offset_x, trough_pos.y + 15.0)


# Cho con vật ăn cám:
# - Tiêu hao 1 túi cám.
# - Đi tới máng ăn và ăn thức ăn trong máng.
# - Sau khi ăn sẽ chờ một khoảng thời gian để sinh sản phẩm!
func feed() -> bool:
	if is_fed() or is_ready():
		return false
	if not Inventory.take_feed(1):
		return false

	animal_data["fed"] = true
	animal_data["progress"] = 0.0
	animal_data["times_fed"] = int(animal_data.get("times_fed", 0)) + 1

	# Bắt đầu đi tới máng ăn
	target_pos = get_trough_eating_spot()
	state = State.WALK_TO_TROUGH

	# Hiệu ứng trái tim / niềm vui
	_play_heart_effect()

	emit_signal("feed_requested", self)
	return true


# Thu hoạch sản phẩm của con vật này:
# - Ngay lập tức có thể cho ăn tiếp!
func harvest() -> String:
	if not is_ready():
		return ""

	var prod_id: String = Inventory.collect_animal_by_dict(animal_data)
	if prod_id != "":
		# Thu hoạch xong -> lập tức trở về trạng thái có thể cho ăn tiếp
		state = State.IDLE
		idle_timer = randf_range(0.5, 1.5)
		_sync_state()
		emit_signal("harvest_requested", self)
	return prod_id


func _play_heart_effect() -> void:
	if heart_spr == null:
		return
	heart_spr.visible = true
	heart_spr.modulate = Color(1.0, 0.4, 0.6, 1.0)
	heart_spr.scale = Vector2(0.5, 0.5)
	heart_spr.position = Vector2(0, _bubble_base_y)

	var tw := create_tween()
	tw.tween_property(heart_spr, "position:y", _bubble_base_y - 12.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(heart_spr, "scale", Vector2(1.2, 1.2), 0.6)
	tw.parallel().tween_property(heart_spr, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func():
		if is_instance_valid(heart_spr):
			heart_spr.visible = false
	)


func is_ready() -> bool:
	return int(animal_data.get("ready", 0)) > 0


func is_fed() -> bool:
	return bool(animal_data.get("fed", false))


func can_slaughter() -> bool:
	return not is_baby and int(animal_data.get("times_fed", 0)) >= 5


func get_times_fed() -> int:
	return int(animal_data.get("times_fed", 0))


func get_animal_name() -> String:
	var d := PoultryDB.get_animal(species_id)
	return str(d.get("name", "Vật nuôi"))


func get_product_name() -> String:
	var d := PoultryDB.get_animal(species_id)
	return str(d.get("product_name", "Sản phẩm"))


func get_remaining_wait_time() -> float:
	var d := PoultryDB.get_animal(species_id)
	var interval: float = float(d.get("interval", 90.0))
	var prog: float = float(animal_data.get("progress", 0.0))
	return maxf(0.0, interval - prog)
