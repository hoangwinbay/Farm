extends Node2D
# Dân làng NPC từ Stardew Valley ghé sạp mua hàng:
# Hiện bong bóng x[số lượng] + hình ảnh món đồ cần mua.
# Nếu sạp có hàng -> mua ngay. Nếu chưa có -> đứng chờ một lúc lâu. Nếu hết giờ chờ -> thất vọng rời đi.

const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal arrived_at_stall
signal purchase_completed(slot_idx: int, item_name: String, qty: int, coins: int, buyer_name: String)
signal departed

enum State { WALK_IN, SHOPPING, WAITING, WALK_OUT }

# Danh tính nhân vật Stardew Valley và tên Việt Nam thân thiện
var character_name: String = "Abigail"
var display_name: String = "Bé Lan"

var state: int = State.WALK_IN
var speed: float = 35.0  # Bước đi chậm rãi, thư thái (35 px/s)
var target_stall_pos := Vector2(184, 468)
var exit_x: float = 430.0  # Đi tiếp dọc đại lộ về phía đông sau khi ghé sạp
var stall_slots: Array = []  # Tham chiếu đến các ô sạp hàng của main

# Nhu cầu mua sắm của khách
var item_id: String = "wheat"
var item_type: String = "crop"
var item_name: String = "Lúa mì"
var buy_qty: int = 3
var unit_price: int = 0

var _spr: Sprite2D
var _shadow: Sprite2D
var _bubble: PanelContainer
var _bubble_qty_label: Label
var _bubble_icon: TextureRect
var _anim_t: float = 0.0
var _shop_timer: float = 0.0
var _wait_timer: float = 0.0
var _max_wait_time: float = 12.0  # Đứng chờ 12 giây nếu chưa có hàng
var _purchased: bool = false
var _disappointed: bool = false


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
	_spr.texture = TextureGen.sdv_char_tex(character_name, "right", 0)
	add_child(_spr)

	# 3. Bong bóng suy nghĩ: [ ×3 ] [ 🌾 Icon ]
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.08, 0.95), UIKit.COLOR_BORDER_GOLD, 4))
	_bubble.position = Vector2(-22, -48)
	_bubble.visible = true

	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 3)
	_bubble.add_child(bh)

	_bubble_qty_label = Label.new()
	_bubble_qty_label.text = "×%d" % buy_qty
	_bubble_qty_label.add_theme_font_size_override("font_size", 10)
	_bubble_qty_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GOLD)
	_bubble_qty_label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.04, 0.95))
	_bubble_qty_label.add_theme_constant_override("outline_size", 2)
	bh.add_child(_bubble_qty_label)

	_bubble_icon = TextureRect.new()
	_bubble_icon.custom_minimum_size = Vector2(16, 16)
	_bubble_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_bubble_icon.texture = TextureGen.get_crate_fill_tex(item_id, item_type)
	bh.add_child(_bubble_icon)

	add_child(_bubble)

	# Xuất phát từ đoạn đường bên trái màn hình
	position = Vector2(-25 - randf_range(0, 20), target_stall_pos.y)
	_spr.flip_h = false


func _process(delta: float) -> void:
	match state:
		State.WALK_IN:
			var dx := target_stall_pos.x - position.x
			if absf(dx) > 2.0:
				position.x += signf(dx) * speed * delta
				_anim_t += delta
				_spr.flip_h = false
				_spr.texture = TextureGen.sdv_char_tex(character_name, "right", int(_anim_t * 5.0) % 4)
			else:
				# Đã đến vị trí trước quầy sạp hàng
				position = target_stall_pos
				_anim_t = 0.0
				_spr.flip_h = false
				# Hướng mặt lên phía trên nhìn vào sạp gỗ
				_spr.texture = TextureGen.sdv_char_tex(character_name, "up", 0)
				arrived_at_stall.emit()

				# Kiểm tra xem sạp hàng có món đồ khách cần không
				var match_slot := _find_matching_slot()
				if match_slot >= 0:
					state = State.SHOPPING
					_shop_timer = 0.0
				else:
					# Không có -> đứng chờ một lúc lâu
					state = State.WAITING
					_wait_timer = 0.0

		State.WAITING:
			_wait_timer += delta

			# Trong lúc đứng chờ, kiểm tra xem người chơi có vừa bày hàng lên sạp không
			var match_slot := _find_matching_slot()
			if match_slot >= 0:
				state = State.SHOPPING
				_shop_timer = 0.0
				return

			# Hiệu ứng bong bóng nhấp nháy nhẹ khi đang đứng đợi
			var pulse := 1.0 + 0.08 * sin(_wait_timer * 4.0)
			_bubble.scale = Vector2(pulse, pulse)

			# Nếu đã đứng chờ quá lâu (12s) mà sạp vẫn không có đồ -> thất vọng rời đi
			if _wait_timer >= _max_wait_time:
				_bubble.scale = Vector2.ONE
				_show_disappointed_bubble()
				state = State.WALK_OUT

		State.SHOPPING:
			_bubble.scale = Vector2.ONE
			_shop_timer += delta

			# Sau 0.8s đứng chọn hàng -> tiến hành mua
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

			# Sau 2.2s mua xong -> cất bong bóng và đi tiếp
			if _shop_timer >= 2.2:
				_bubble.visible = false
				state = State.WALK_OUT

		State.WALK_OUT:
			var dx := exit_x - position.x
			if absf(dx) > 3.0:
				position.x += signf(dx) * speed * delta
				_anim_t += delta
				var dir := "right" if dx > 0 else "left"
				_spr.flip_h = false
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
