extends Node2D
# Dân làng NPC đi bộ dọc đại lộ ghé vào sạp mua hàng.

const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal arrived_at_stall
signal purchase_completed(slot_idx: int, item_name: String, qty: int, coins: int)
signal departed

enum State { WALK_IN, SHOPPING, WALK_OUT }

var state: int = State.WALK_IN
var speed: float = 65.0
var target_stall_pos := Vector2(184, 468)
var spawn_side := "west"  # "west" hoặc "east"
var exit_x: float = -40.0

var _spr: Sprite2D
var _shadow: Sprite2D
var _bubble: PanelContainer
var _bubble_icon: TextureRect
var _anim_t: float = 0.0
var _shop_timer: float = 0.0
var _purchased: bool = false

# Thông tin giao dịch được gán trước khi xuất phát
var target_slot_idx: int = -1
var item_id: String = ""
var item_type: String = ""
var item_name: String = ""
var unit_price: int = 0
var buy_qty: int = 1


func _ready() -> void:
	z_as_relative = true

	# 1. Bóng đổ chân nhân vật
	_shadow = Sprite2D.new()
	_shadow.texture = TextureGen.get_tex("shadow")
	_shadow.scale = Vector2(0.85, 0.75)
	_shadow.position = Vector2(0, 0)
	add_child(_shadow)

	# 2. Thân nhân vật NPC
	_spr = Sprite2D.new()
	_spr.scale = Vector2(1.2, 1.2)
	_spr.offset = Vector2(0, -18)
	_spr.texture = TextureGen.char_tex("side", 0, true)
	add_child(_spr)

	# 3. Bong bóng suy nghĩ / mua sắm trên đầu
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.22, 0.16, 0.10, 0.95), UIKit.COLOR_BORDER_GOLD, 4))
	_bubble.position = Vector2(-12, -44)
	_bubble.visible = false

	var bh := HBoxContainer.new()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	_bubble.add_child(bh)

	_bubble_icon = TextureRect.new()
	_bubble_icon.custom_minimum_size = Vector2(16, 16)
	_bubble_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	bh.add_child(_bubble_icon)

	add_child(_bubble)

	# Cấu hình hướng đi ban đầu
	if spawn_side == "west":
		position = Vector2(-20, target_stall_pos.y)
		exit_x = -40.0
		_spr.flip_h = false
	else:
		position = Vector2(360, target_stall_pos.y)
		exit_x = 400.0
		_spr.flip_h = true


func _process(delta: float) -> void:
	match state:
		State.WALK_IN:
			var dx := target_stall_pos.x - position.x
			if absf(dx) > 2.5:
				position.x += signf(dx) * speed * delta
				_spr.flip_h = dx < 0
				_anim_t += delta
				_spr.texture = TextureGen.char_tex("side", int(_anim_t * 6.0) % 4, true)
			else:
				# Đã đến trước quầy sạp hàng!
				position = target_stall_pos
				state = State.SHOPPING
				_shop_timer = 0.0
				_spr.flip_h = false
				_spr.texture = TextureGen.char_tex("up", 0, true)
				arrived_at_stall.emit()
				_show_item_bubble()

		State.SHOPPING:
			_shop_timer += delta
			# Sau 0.7 giây dừng ngắm hàng -> chốt mua
			if _shop_timer >= 0.7 and not _purchased:
				_purchased = true
				var earned := unit_price * buy_qty
				purchase_completed.emit(target_slot_idx, item_name, buy_qty, earned)
				_show_coin_bubble()
				# Nhún người vui mừng khi mua được hàng
				var tw := create_tween()
				tw.tween_property(_spr, "position:y", -5.0, 0.12).set_trans(Tween.TRANS_SINE)
				tw.tween_property(_spr, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_SINE)

			# Sau 1.8 giây hoàn tất mua -> rời sạp hàng
			if _shop_timer >= 1.8:
				_bubble.visible = false
				state = State.WALK_OUT

		State.WALK_OUT:
			var dx := exit_x - position.x
			if absf(dx) > 3.0:
				position.x += signf(dx) * speed * delta
				_spr.flip_h = dx < 0
				_anim_t += delta
				_spr.texture = TextureGen.char_tex("side", int(_anim_t * 6.0) % 4, true)
			else:
				departed.emit()
				queue_free()


func _show_item_bubble() -> void:
	_bubble.visible = true
	_bubble_icon.texture = TextureGen.get_crate_fill_tex(item_id, item_type)
	var tw := _bubble.create_tween()
	_bubble.scale = Vector2(0.5, 0.5)
	tw.tween_property(_bubble, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_coin_bubble() -> void:
	_bubble.visible = true
	_bubble_icon.texture = TextureGen.coin_icon()
	var tw := _bubble.create_tween()
	_bubble.scale = Vector2(1.2, 1.2)
	tw.tween_property(_bubble, "scale", Vector2.ONE, 0.1)
