extends CharacterBody2D
# Nhân vật nông dân: đi 4 hướng, đổi hướng tạo ô tương tác.

const TextureGen := preload("res://scripts/texture_gen.gd")

const SPEED := 150.0

var facing := Vector2.DOWN
var can_move := true

var _sprite: Sprite2D
var _dir := "down"
var _anim_t := 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_sprite = Sprite2D.new()
	_sprite.scale = Vector2(2, 2)
	_sprite.offset = Vector2(0, -8)
	add_child(_sprite)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	col.position = Vector2(0, -5)
	add_child(col)
	_update_tex(0)


func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		_anim_t = 0.0
		_update_tex(0)
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = v * SPEED
	move_and_slide()
	if v.length() > 0.01:
		if absf(v.x) >= absf(v.y):
			facing = Vector2(signf(v.x), 0)
			_dir = "side"
			_sprite.flip_h = v.x < 0
		else:
			facing = Vector2(0, signf(v.y))
			_dir = "up" if v.y < 0 else "down"
			_sprite.flip_h = false
		_anim_t += delta
		_update_tex(int(_anim_t * 6.0) % 2)
	else:
		_anim_t = 0.0
		_update_tex(0)


func get_facing_point() -> Vector2:
	return global_position + facing * 26.0


# Nhún người ngắn khi làm hành động (cày / gieo / tưới / thu hoạch).
func play_action_anim() -> void:
	var tw := create_tween()
	tw.tween_property(_sprite, "scale", Vector2(2.35, 1.7), 0.1)
	tw.tween_property(_sprite, "scale", Vector2(1.75, 2.3), 0.12)
	tw.tween_property(_sprite, "scale", Vector2(2, 2), 0.1)


func _update_tex(frame: int) -> void:
	_sprite.texture = TextureGen.char_tex(_dir, frame, false)
