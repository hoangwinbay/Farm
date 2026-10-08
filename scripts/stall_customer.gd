extends Node2D
# Dân làng NPC từ Stardew Valley ghé sạp mua hàng:
# - Hiện bong bóng [x3] + [icon món đồ cần mua].
# - Nếu có hàng -> mua ngay.
# - Nếu chưa có hàng -> 20% từ chối ngay, 80% đứng chờ & đi lại xung quanh sạp đến hết ngày.
# - Người chơi có thể đến gần bấm [E] để báo hết hàng (từ chối).
# - Khi về -> quay trở về đoạn đường ban đầu ở rìa trái màn hình.

const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal arrived_at_stall
signal purchase_completed(slot_idx: int, item_name: String, qty: int, coins: int, buyer_name: String)
signal wait_timeout_expired(buyer_name: String, item_name: String)
signal departed

enum State { WALK_IN, SHOPPING, WAITING, WALK_OUT }

# Danh tính nhân vật Stardew Valley và tên Việt Nam thân thiện
var character_name: String = "Abigail"
var display_name: String = "Bé Lan"

var state: int = State.WALK_IN
var speed: float = 35.0         # Tốc độ đi bộ bình thường (35 px/s)
var wander_speed: float = 22.0  # Tốc độ đi dạo thư thả khi đứng chờ
var target_stall_pos := Vector2(584, 468)
var exit_pos := Vector2(-40.0, 468.0)   # Quay trở về con đường bên trái (Tây)
var stall_slots: Array = []     # Tham chiếu đến các ô sạp hàng của main

# Nhu cầu mua sắm của khách
var item_id: String = "wheat"
var item_type: String = "crop"
var item_name: String = "Lúa mì"
var buy_qty: int = 3
var unit_price: int = 0
var max_wait_time: float = 20.0 # Thời gian tối đa kiên nhẫn chờ món hàng (giây)

var _spr: Sprite2D
var _shadow: Sprite2D
var _bubble: PanelContainer
var _bubble_qty_label: Label
var _bubble_icon: TextureRect
var _anim_t: float = 0.0
var _shop_timer: float = 0.0
var _check_restock_timer: float = 0.0
var _wait_elapsed: float = 0.0
var _purchased: bool = false
var _disappointed: bool = false

# AI đi lại xung quanh khi đứng chờ
var _wander_target := Vector2.ZERO
var _wander_wait_timer: float = 0.0
var _is_wandering: bool = false


func _ready() -> void:
	z_as_relative = true

	# 1. Bóng đổ chân nhân vật (Stardew Valley ground shadow)
	_shadow = Sprite2D.new()
	_shadow.texture = TextureGen.get_tex("shadow")
	_shadow.scale = Vector2(0.9, 0.7)
	_shadow.position = Vector2(0, 0)
	add_child(_shadow)

	# 2. Thân nhân vật NPC Stardew Valley (16x32 sprite gốc)
	_spr = Sprite2D.new()
	_spr.scale = Vector2(1.25, 1.25)
	_spr.offset = Vector2(0, -16)
	_spr.texture = TextureGen.sdv_char_tex(character_name, "left", 0)
	add_child(_spr)

	# 3. Bong bóng nhỏ tròn, màu trắng lơ lửng phía trên đầu (không che mất đầu)
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override("panel", _make_white_bubble_style())
	_bubble.position = Vector2(-16, -66)
	_bubble.pivot_offset = Vector2(16, 10)
	_bubble.resized.connect(func():
		_bubble.position.x = -_bubble.size.x / 2.0
		_bubble.pivot_offset = _bubble.size / 2.0
	)
	_bubble.visible = true

	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 2)
	_bubble.add_child(bh)

	_bubble_qty_label = Label.new()
	_bubble_qty_label.text = "×%d" % buy_qty
	_bubble_qty_label.add_theme_font_size_override("font_size", 10)
	_bubble_qty_label.add_theme_color_override("font_color", Color(0.18, 0.12, 0.08))
	_bubble_qty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bh.add_child(_bubble_qty_label)

	_bubble_icon = TextureRect.new()
	_bubble_icon.custom_minimum_size = Vector2(14, 14)
	_bubble_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_bubble_icon.texture = TextureGen.get_crate_fill_tex(item_id, item_type)
	bh.add_child(_bubble_icon)

	add_child(_bubble)

	# Xuất phát từ đoạn đường phía bên trái (Tây)
	position = Vector2(-30.0 - randf_range(0, 30.0), target_stall_pos.y)
	_spr.flip_h = false
	max_wait_time = randf_range(16.0, 24.0)
	_wait_elapsed = 0.0


func _process(delta: float) -> void:
	match state:
		State.WALK_IN:
			var dx := target_stall_pos.x - position.x
			var dy := target_stall_pos.y - position.y
			if absf(dx) > 2.0 or absf(dy) > 2.0:
				var move_dir := Vector2(dx, dy).normalized()
				position += move_dir * speed * delta
				_anim_t += delta
				var dir := "right" if move_dir.x >= 0 else "left"
				if absf(move_dir.y) > absf(move_dir.x):
					dir = "down" if move_dir.y > 0 else "up"
				_spr.texture = TextureGen.sdv_char_tex(character_name, dir, int(_anim_t * 5.0) % 4)
			else:
				# Đã đến vị trí trước quầy sạp hàng
				position = target_stall_pos
				_anim_t = 0.0
				_spr.texture = TextureGen.sdv_char_tex(character_name, "up", 0)
				arrived_at_stall.emit()

				# Kiểm tra xem sạp hàng có món đồ khách cần không
				var match_slot := _find_matching_slot()
				if match_slot >= 0:
					state = State.SHOPPING
					_shop_timer = 0.0
				else:
					# Chưa có món đồ mong muốn: đứng chờ một lúc xem người chơi có bày hàng lên không
					state = State.WAITING
					_wait_elapsed = 0.0
					_is_wandering = false
					_wander_wait_timer = randf_range(2.0, 4.0)

		State.WAITING:
			# Trong lúc chờ, kiểm tra xem người chơi có vừa bày món hàng lên sạp không
			_check_restock_timer += delta
			if _check_restock_timer >= 0.3:
				_check_restock_timer = 0.0
				var match_slot := _find_matching_slot()
				if match_slot >= 0:
					# Phát hiện có hàng trên sạp! Lập tức chuyển sang mua sắm
					state = State.SHOPPING
					_shop_timer = 0.0
					_is_wandering = false
					return

			# Đếm thời gian chờ đợi: nếu quá thời gian kiên nhẫn mà vẫn chưa có đồ -> rời đi
			_wait_elapsed += delta
			if _wait_elapsed >= max_wait_time:
				wait_timeout_expired.emit(display_name, item_name)
				decline()
				return

			# Đi lại xung quanh khu vực trước sạp hàng
			if _is_wandering:
				var d_vec := _wander_target - position
				if d_vec.length() > 2.5:
					var m_dir := d_vec.normalized()
					position += m_dir * wander_speed * delta
					_anim_t += delta
					var dir := "right" if m_dir.x >= 0 else "left"
					if absf(m_dir.y) > absf(m_dir.x):
						dir = "down" if m_dir.y > 0 else "up"
					_spr.texture = TextureGen.sdv_char_tex(character_name, dir, int(_anim_t * 4.0) % 4)
				else:
					_is_wandering = false
					_wander_wait_timer = randf_range(2.5, 5.0)
					_anim_t = 0.0
					_spr.texture = TextureGen.sdv_char_tex(character_name, "up" if randf() < 0.6 else "down", 0)
			else:
				_wander_wait_timer -= delta
				if _wander_wait_timer <= 0.0:
					_wander_target = _pick_wander_spot()
					_is_wandering = true

		State.SHOPPING:
			# Nếu đang đứng cách quầy hàng do đi dạo, tiến nhanh về lại trước quầy
			var dx := target_stall_pos.x - position.x
			var dy := target_stall_pos.y - position.y
			if absf(dx) > 4.0 or absf(dy) > 4.0:
				var m_dir := Vector2(dx, dy).normalized()
				position += m_dir * speed * 1.5 * delta
				_anim_t += delta
				_spr.texture = TextureGen.sdv_char_tex(character_name, "up", int(_anim_t * 5.0) % 4)
				return
			else:
				position = target_stall_pos
				_spr.texture = TextureGen.sdv_char_tex(character_name, "up", 0)

			_shop_timer += delta
			# Sau 0.8s ngắm nghía -> tiến hành mua hàng
			if _shop_timer >= 0.8 and not _purchased:
				_purchased = true
				var match_slot := _find_matching_slot()
				if match_slot >= 0:
					var slot: Dictionary = stall_slots[match_slot]
					var stock: int = int(slot.get("count", 0))
					var actual_qty: int = mini(stock, buy_qty)
					var price: int = int(slot.get("price", unit_price))
					var earned: int = price * actual_qty
					purchase_completed.emit(match_slot, item_name, actual_qty, earned, display_name)
					_show_coin_bubble()
					# Nhún người vui sướng vì mua được đồ ngon
					var tw := create_tween()
					tw.tween_property(_spr, "position:y", -4.0, 0.12).set_trans(Tween.TRANS_SINE)
					tw.tween_property(_spr, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_SINE)
				else:
					_show_disappointed_bubble()
					state = State.WALK_OUT
					return

			# Sau 2.2s mua xong -> cất bong bóng và quay trở về đoạn đường ban đầu
			if _shop_timer >= 2.2:
				_bubble.visible = false
				state = State.WALK_OUT

		State.WALK_OUT:
			# Khi về thì quay trở về đoạn đường ban đầu ở rìa trái màn hình (x <= -35, y = 468)
			var target_x: float = exit_pos.x
			var dx := target_x - position.x
			var dy := exit_pos.y - position.y

			# Đưa vị trí y về trục đường chính 468
			if absf(dy) > 2.5:
				position.y += signf(dy) * speed * delta

			if absf(dx) > 3.0:
				position.x += signf(dx) * speed * delta
				_anim_t += delta
				var dir := "right" if dx > 0 else "left"
				_spr.texture = TextureGen.sdv_char_tex(character_name, dir, int(_anim_t * 5.0) % 4)
			else:
				departed.emit()
				queue_free()


func _find_matching_slot() -> int:
	for i in stall_slots.size():
		var slot = stall_slots[i]
		if typeof(slot) == TYPE_DICTIONARY and not slot.is_empty():
			if str(slot.get("id", "")) == item_id and int(slot.get("count", 0)) > 0:
				return i
	return -1


func _pick_wander_spot() -> Vector2:
	# Khu vực quảng trường / đường cỏ mở rộng quanh sạp hàng
	var rx := randf_range(target_stall_pos.x - 55.0, target_stall_pos.x + 55.0)
	var ry := randf_range(462.0, 498.0)
	return Vector2(rx, ry)


func decline() -> void:
	if state == State.WALK_OUT:
		return
	_is_wandering = false
	_show_disappointed_bubble()
	state = State.WALK_OUT


func dismiss_for_night() -> void:
	if state == State.WALK_OUT:
		return
	_is_wandering = false
	_bubble.visible = false
	state = State.WALK_OUT


func _show_coin_bubble() -> void:
	_bubble.visible = true
	_bubble_qty_label.visible = false
	_bubble_icon.texture = TextureGen.coin_icon()
	var tw := _bubble.create_tween()
	_bubble.scale = Vector2(1.2, 1.2)
	tw.tween_property(_bubble, "scale", Vector2.ONE, 0.1)


func _show_disappointed_bubble() -> void:
	if _disappointed:
		return
	_disappointed = true
	_bubble.visible = true
	_bubble_qty_label.visible = false
	_bubble_icon.texture = TextureGen.sweat_drop_icon()

	# Lắc đầu nhẹ thất vọng
	var tw := create_tween()
	tw.tween_property(_spr, "position:x", -2.0, 0.08)
	tw.tween_property(_spr, "position:x", 2.0, 0.08)
	tw.tween_property(_spr, "position:x", 0.0, 0.08)
	tw.tween_interval(0.8)
	tw.tween_property(_bubble, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): _bubble.visible = false; _bubble.modulate.a = 1.0)


func _make_white_bubble_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.96)
	sb.border_color = Color(0.25, 0.20, 0.16, 0.75)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 1)
	return sb
