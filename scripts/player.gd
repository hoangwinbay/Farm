extends CharacterBody2D
# Nhân vật nông dân: đi 4 hướng, đổi hướng tạo ô tương tác.

const TextureGen := preload("res://scripts/texture_gen.gd")

const SPEED := 150.0

var facing := Vector2.DOWN:
	set(val):
		facing = val
		if val != Vector2.ZERO:
			if absf(val.x) >= absf(val.y):
				_dir = "side"
				if _sprite:
					_sprite.flip_h = val.x < 0
			else:
				_dir = "up" if val.y < 0 else "down"
				if _sprite:
					_sprite.flip_h = false
			if _sprite:
				_update_tex(0)

var can_move := true
var _is_acting := false
var _action_tween: Tween

var _sprite: Sprite2D
var _sweat_spr: Sprite2D
var _sweat_timer: float = 0.0
var _dir := "down"
var _anim_t := 0.0
var _walk_stamina_timer: float = 0.0

const ACTION_STEPS := {
	"till": 5,
	"water": 3,
	"plant": 3,
	"harvest": 4,
}

const ACTION_DURATIONS := {
	"till": [0.07, 0.06, 0.06, 0.12, 0.07], # Total 0.38s
	"water": [0.08, 0.20, 0.08],            # Total 0.36s
	"plant": [0.08, 0.16, 0.08],            # Total 0.32s
	"harvest": [0.08, 0.08, 0.08, 0.16],    # Total 0.40s
}


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_sprite = Sprite2D.new()
	_sprite.scale = Vector2(1.2, 1.2)
	_sprite.offset = Vector2(0, -18)
	add_child(_sprite)
	_sweat_spr = Sprite2D.new()
	_sweat_spr.texture = TextureGen.sweat_drop_icon()
	_sweat_spr.position = Vector2(8, -32)
	_sweat_spr.visible = false
	_sweat_spr.z_index = 5
	add_child(_sweat_spr)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	col.position = Vector2(0, -5)
	add_child(col)
	_update_tex(0)


func _physics_process(delta: float) -> void:
	var exhausted: bool = GameState.is_exhausted()
	if exhausted:
		_sweat_timer += delta * 4.0
		_sweat_spr.visible = (int(_sweat_timer) % 2 == 0)
		_sweat_spr.position = Vector2(8 if not _sprite.flip_h else -8, -32 + sin(_sweat_timer) * 2.0)
	else:
		_sweat_spr.visible = false
		_sweat_timer = 0.0

	if not can_move or _is_acting:
		velocity = Vector2.ZERO
		_anim_t = 0.0
		if not _is_acting:
			_update_tex(0)
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var spd := SPEED * (0.6 if exhausted else 1.0)
	if GameState.weather == "windy" and v.x > 0:
		spd *= 1.18
	velocity = v * spd
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
		_anim_t += delta * (0.7 if exhausted else 1.0)
		_update_tex(int(_anim_t * 8.0) % 4)

		# Đi lại cũng tiêu hao năng lượng, nhưng rất ít (không đáng kể: 0.1 điểm mỗi giây di chuyển)
		if not exhausted and not is_on_wall():
			_walk_stamina_timer += delta
			if _walk_stamina_timer >= 1.0:
				_walk_stamina_timer -= 1.0
				GameState.use_stamina(0.1)
	else:
		_anim_t = 0.0
		_update_tex(0)
		_walk_stamina_timer = 0.0


func get_facing_point() -> Vector2:
	return global_position + facing * 26.0


func get_action_duration(act: String = "till") -> float:
	var durs: Variant = ACTION_DURATIONS.get(act, null)
	if durs == null or not (durs is Array):
		return 0.3
	var sum := 0.0
	for d in durs:
		sum += float(d)
	return sum


# Diễn hoạt hành động chuẩn Stardew Valley (cuốc đất / tưới cây / gieo hạt / gặt cây).
func play_action_anim(act: String = "till") -> void:
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_is_acting = true
	var num_steps: int = ACTION_STEPS.get(act, 0)
	var durs_var: Variant = ACTION_DURATIONS.get(act, [])
	var durs: Array = durs_var if durs_var is Array else []
	if num_steps <= 0 or durs.is_empty():
		_update_tex(99)
		var fallback_tw := create_tween()
		_action_tween = fallback_tw
		fallback_tw.tween_property(_sprite, "scale", Vector2(1.35, 1.05), 0.1)
		fallback_tw.tween_property(_sprite, "scale", Vector2(1.05, 1.35), 0.12)
		fallback_tw.tween_property(_sprite, "scale", Vector2(1.2, 1.2), 0.1)
		fallback_tw.tween_callback(func():
			_is_acting = false
			_update_tex(0)
		)
		return

	var tw := create_tween()
	_action_tween = tw
	for step in range(num_steps):
		var s := step
		var dur: float = float(durs[s]) if s < durs.size() else 0.08
		tw.tween_callback(func():
			_sprite.texture = TextureGen.char_action_tex(_dir, act, s)
		)
		if act == "till" and s == 3:
			tw.tween_property(_sprite, "scale", Vector2(1.28, 1.12), dur * 0.5)
			tw.tween_property(_sprite, "scale", Vector2(1.2, 1.2), dur * 0.5)
		elif act == "harvest" and s == 3:
			tw.tween_property(_sprite, "scale", Vector2(1.15, 1.25), dur * 0.5)
			tw.tween_property(_sprite, "scale", Vector2(1.2, 1.2), dur * 0.5)
		else:
			tw.tween_interval(dur)

	tw.tween_callback(func():
		_is_acting = false
		_sprite.scale = Vector2(1.2, 1.2)
		_update_tex(0)
	)


func _update_tex(frame: int) -> void:
	_sprite.texture = TextureGen.char_tex(_dir, frame, false)
