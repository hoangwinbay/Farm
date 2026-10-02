extends CanvasLayer
# Điều khiển cảm ứng cho điện thoại: joystick ảo góc trái + cụm nút hành động góc phải.
# Chỉ được thêm vào khi máy có màn hình cảm ứng — máy tính vẫn chơi bằng WASD như cũ.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

const JOY_R := 66.0    # bán kính vùng joystick
const KNOB_R := 26.0   # bán kính núm
const JOY_AREA := 190.0

var main: Node

var _joy: Control
var _joy_touch := -1        # index ngón tay đang điều khiển joystick (-1 = không)
var _joy_center := Vector2(JOY_AREA / 2.0, JOY_AREA / 2.0)
var _knob := Vector2(JOY_AREA / 2.0, JOY_AREA / 2.0)
var _time := 0.0


func _ready() -> void:
	layer = 15

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.resized.connect(_place)
	add_child(root)

	# --- joystick ảo góc trái dưới ---
	_joy = Control.new()
	_joy.custom_minimum_size = Vector2(JOY_AREA, JOY_AREA)
	_joy.size = Vector2(JOY_AREA, JOY_AREA)
	_joy.mouse_filter = Control.MOUSE_FILTER_STOP
	_joy.gui_input.connect(_on_joy_input)
	_joy.draw.connect(_draw_joy)
	root.add_child(_joy)

	# --- cụm nút hành động góc phải dưới ---
	var e_btn := _make_button(root, "E", 74, "primary", "interact")
	var i_btn := _make_button(root, "I", 58, "tab", "inventory")
	var r_btn := _make_button(root, "R", 58, "tab", "cycle_seed")
	var p_btn := _make_button(root, "❚❚", 44, "close", "pause")
	e_btn.name = "BtnE"
	i_btn.name = "BtnI"
	r_btn.name = "BtnR"
	p_btn.name = "BtnP"
	_place()


func _make_button(parent: Control, text: String, side: float, style: String, action: String) -> Button:
	var b := UIKit.styled_button(null, text, int(side * 0.4), style)
	b.custom_minimum_size = Vector2(side, side)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void: _fire(action))
	parent.add_child(b)
	return b


# Gửi sự kiện hành động giả lập phím (giống hệt bấm E/I/R/Esc trên máy tính).
func _fire(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _place() -> void:
	if _joy == null:
		return
	var vs := _joy.get_viewport_rect().size
	_joy.position = Vector2(18, vs.y - JOY_AREA - 18)
	# cụm nút nâng trên thanh hotbar (chiếm ~84px đáy màn hình)
	var e_btn := _joy.get_parent().get_node("BtnE") as Button
	var i_btn := _joy.get_parent().get_node("BtnI") as Button
	var r_btn := _joy.get_parent().get_node("BtnR") as Button
	var p_btn := _joy.get_parent().get_node("BtnP") as Button
	e_btn.position = Vector2(vs.x - 94, vs.y - 186)
	i_btn.position = Vector2(vs.x - 170, vs.y - 158)
	r_btn.position = Vector2(vs.x - 88, vs.y - 268)
	p_btn.position = Vector2(vs.x - 170, vs.y - 248)


func _process(delta: float) -> void:
	_time += delta
	# mất Focus / rời chế độ chơi thì nhả mọi hướng đi
	if _joy_touch != -1 and main != null and main.mode != main.Mode.PLAY:
		_release_joy()
	_joy.queue_redraw()


func _on_joy_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _joy_touch == -1:
			_joy_touch = t.index
			_joy_center = t.position
			_knob = _joy_center
			_apply_dir(Vector2.ZERO)
		elif not t.pressed and t.index == _joy_touch:
			_release_joy()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_touch:
			_knob = _joy_center + (d.position - _joy_center).limit_length(JOY_R)
			_apply_dir(_knob - _joy_center)


func _apply_dir(dir: Vector2) -> void:
	var v := dir.limit_length(JOY_R) / JOY_R
	Input.action_press("move_left", maxf(0.0, -v.x))
	Input.action_press("move_right", maxf(0.0, v.x))
	Input.action_press("move_up", maxf(0.0, -v.y))
	Input.action_press("move_down", maxf(0.0, v.y))


func _release_joy() -> void:
	_joy_touch = -1
	_joy_center = Vector2(JOY_AREA / 2.0, JOY_AREA / 2.0)
	_knob = _joy_center
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)


func _draw_joy() -> void:
	var alpha := 0.85 if _joy_touch != -1 else 0.55
	# vành đế joystick
	_joy.draw_circle(_joy_center, JOY_R + 4.0, Color(0.08, 0.05, 0.03, 0.5 * alpha))
	_joy.draw_circle(_joy_center, JOY_R, Color(0.18, 0.12, 0.08, 0.6 * alpha))
	_joy.draw_arc(_joy_center, JOY_R, 0, TAU, 40, Color(0.86, 0.70, 0.32, 0.9 * alpha), 2.5)
	# 4 mũi tên hướng
	var font := ThemeDB.fallback_font
	for d: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var p := _joy_center + d * (JOY_R - 16.0)
		_joy.draw_string(font, p + Vector2(-4, 4), "▲" if d == Vector2.UP
				else ("▼" if d == Vector2.DOWN else ("◀" if d == Vector2.LEFT else "▶")),
				HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.95, 0.9, 0.8, 0.8 * alpha))
	# núm joystick
	_joy.draw_circle(_knob, KNOB_R + 3.0, Color(0.08, 0.05, 0.03, 0.7 * alpha))
	_joy.draw_circle(_knob, KNOB_R, Color(0.9, 0.82, 0.6, 0.9 * alpha))
