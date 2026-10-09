extends CanvasLayer
# Điều khiển cảm ứng cho điện thoại & tablet:
# - Góc trái dưới: Cần gạt joystick ảo hoặc cụm nút 4 hướng (D-pad) có thể chuyển đổi.
# - Góc phải dưới: Nút Thao Tác lớn (tương tác/dùng công cụ/nói chuyện) + các nút tiện ích (Túi, Hạt, Ăn, Tạm dừng).

const UIKit := preload("res://scripts/ui/ui_kit.gd")

const JOY_R := 70.0       # bán kính vùng joystick
const KNOB_R := 28.0      # bán kính núm
const JOY_AREA := 200.0   # kích thước khung joystick

var main: Node

var _root: Control
var _joy_panel: Control
var _dpad_panel: Control
var _mode_btn: Button

# Trạng thái di chuyển
var _is_dpad_mode := false
var _joy_touch := -1
var _joy_center := Vector2(JOY_AREA / 2.0, JOY_AREA / 2.0)
var _knob := Vector2(JOY_AREA / 2.0, JOY_AREA / 2.0)
var _time := 0.0

# Nút thao tác góc phải
var _btn_action: Button
var _btn_inv: Button
var _btn_seed: Button
var _btn_eat: Button
var _btn_pause: Button


func _ready() -> void:
	layer = 15

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.resized.connect(_place)
	add_child(_root)

	# --- CỤM DI CHUYỂN (GÓC TRÁI DƯỚI) ---
	# 1. Cần gạt Joystick ảo
	_joy_panel = Control.new()
	_joy_panel.custom_minimum_size = Vector2(JOY_AREA, JOY_AREA)
	_joy_panel.size = Vector2(JOY_AREA, JOY_AREA)
	_joy_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_joy_panel.gui_input.connect(_on_joy_input)
	_joy_panel.draw.connect(_draw_joy)
	_root.add_child(_joy_panel)

	# 2. Cụm nút 4 hướng D-Pad (Lên, Xuống, Trái, Phải)
	_dpad_panel = Control.new()
	_dpad_panel.custom_minimum_size = Vector2(JOY_AREA, JOY_AREA)
	_dpad_panel.size = Vector2(JOY_AREA, JOY_AREA)
	_dpad_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dpad_panel.visible = false
	_root.add_child(_dpad_panel)
	_build_dpad()

	# 3. Nút chuyển chế độ di chuyển (Joystick <-> Phím 4 hướng)
	_mode_btn = Button.new()
	_mode_btn.text = "🕹️ Cần gạt"
	_mode_btn.add_theme_font_size_override("font_size", 11)
	_mode_btn.focus_mode = Control.FOCUS_NONE
	_mode_btn.custom_minimum_size = Vector2(90, 28)
	var mode_sb := UIKit.btn_style(Color(0.20, 0.14, 0.09, 0.85), UIKit.COLOR_BORDER_WOOD, 6, 1)
	_mode_btn.add_theme_stylebox_override("normal", mode_sb)
	_mode_btn.add_theme_stylebox_override("hover", mode_sb)
	_mode_btn.add_theme_stylebox_override("pressed", mode_sb)
	_mode_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)
	_mode_btn.pressed.connect(_toggle_move_mode)
	_root.add_child(_mode_btn)

	# --- CỤM NÚT THAO TÁC (GÓC PHẢI DƯỚI) ---
	# Nút Thao Tác lớn (Interact - E)
	_btn_action = _make_action_button(_root, "THAO TÁC", 84, "primary", "interact")
	_btn_action.name = "BtnAction"

	# Các nút vệ tinh: Túi đồ (I), Đổi hạt (R), Ăn nhanh (F), Tạm dừng (Esc)
	_btn_inv = _make_action_button(_root, "TÚI", 56, "tab", "inventory")
	_btn_inv.name = "BtnInv"

	_btn_seed = _make_action_button(_root, "HẠT", 56, "tab", "cycle_seed")
	_btn_seed.name = "BtnSeed"

	_btn_eat = _make_action_button(_root, "ĂN", 56, "sell", "quick_eat")
	_btn_eat.name = "BtnEat"

	_btn_pause = _make_action_button(_root, "❚❚", 44, "close", "pause")
	_btn_pause.name = "BtnPause"

	_place()


func _build_dpad() -> void:
	var btn_sz := 54.0
	var cx := (JOY_AREA - btn_sz) / 2.0
	var cy := (JOY_AREA - btn_sz) / 2.0
	var offset := 56.0

	_make_hold_button(_dpad_panel, "▲", Vector2(cx, cy - offset), btn_sz, "move_up")
	_make_hold_button(_dpad_panel, "▼", Vector2(cx, cy + offset), btn_sz, "move_down")
	_make_hold_button(_dpad_panel, "◀", Vector2(cx - offset, cy), btn_sz, "move_left")
	_make_hold_button(_dpad_panel, "▶", Vector2(cx + offset, cy), btn_sz, "move_right")

	# Nút tròn ở giữa làm mốc
	var center_mark := Control.new()
	center_mark.custom_minimum_size = Vector2(28, 28)
	center_mark.position = Vector2(cx + (btn_sz - 28) / 2.0, cy + (btn_sz - 28) / 2.0)
	center_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_mark.draw.connect(func() -> void:
		center_mark.draw_circle(Vector2(14, 14), 12, Color(0.18, 0.12, 0.08, 0.8))
		center_mark.draw_arc(Vector2(14, 14), 12, 0, TAU, 24, UIKit.COLOR_BORDER_GOLD, 1.5)
	)
	_dpad_panel.add_child(center_mark)


func _make_hold_button(parent: Control, text: String, pos: Vector2, size: float, action: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(size, size)
	b.size = Vector2(size, size)
	b.position = pos
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)

	var norm := UIKit.btn_style(Color(0.24, 0.16, 0.10, 0.85), UIKit.COLOR_BORDER_GOLD, int(size / 3.0), 2)
	var prs := UIKit.btn_style(Color(0.40, 0.25, 0.12, 0.95), UIKit.COLOR_BORDER_BRIGHT, int(size / 3.0), 0)
	b.add_theme_stylebox_override("normal", norm)
	b.add_theme_stylebox_override("hover", norm)
	b.add_theme_stylebox_override("pressed", prs)

	b.button_down.connect(func() -> void:
		Input.action_press(action, 1.0)
	)
	b.button_up.connect(func() -> void:
		Input.action_release(action)
	)
	parent.add_child(b)
	return b


func _make_action_button(parent: Control, text: String, side: float, style: String, action: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(side, side)
	b.size = Vector2(side, side)
	b.focus_mode = Control.FOCUS_NONE

	var font_sz: int
	var radius := int(side / 2.0)
	var bg_col: Color
	var border_col := UIKit.COLOR_BORDER_GOLD

	if style == "primary":
		font_sz = 14
		bg_col = Color(0.46, 0.30, 0.14, 0.95)
		border_col = UIKit.COLOR_BORDER_BRIGHT
	elif style == "sell":
		font_sz = 13
		bg_col = Color(0.40, 0.22, 0.10, 0.90)
		border_col = Color(0.95, 0.65, 0.30)
	elif style == "close":
		font_sz = 14
		bg_col = Color(0.36, 0.14, 0.12, 0.90)
		border_col = Color(0.85, 0.45, 0.40)
	else:
		font_sz = 13
		bg_col = Color(0.22, 0.15, 0.10, 0.90)
		border_col = UIKit.COLOR_BORDER_WOOD

	b.add_theme_font_size_override("font_size", font_sz)
	b.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	b.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	b.add_theme_constant_override("outline_size", 2)

	var sb_norm := UIKit.btn_style(bg_col, border_col, radius, 3)
	var sb_prs := UIKit.btn_style(bg_col.darkened(0.25), border_col.lightened(0.2), radius, 0)
	b.add_theme_stylebox_override("normal", sb_norm)
	b.add_theme_stylebox_override("hover", sb_norm)
	b.add_theme_stylebox_override("pressed", sb_prs)

	b.pressed.connect(func() -> void: _fire(action))
	parent.add_child(b)
	return b


func _fire(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _toggle_move_mode() -> void:
	_is_dpad_mode = not _is_dpad_mode
	_joy_panel.visible = not _is_dpad_mode
	_dpad_panel.visible = _is_dpad_mode
	if _is_dpad_mode:
		_release_joy()
		_mode_btn.text = "➕ 4 Phím"
	else:
		_release_all_dpad()
		_mode_btn.text = "🕹️ Cần gạt"


func _release_all_dpad() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)


func _place() -> void:
	if _joy_panel == null or not is_inside_tree():
		return
	var vs := _root.get_viewport_rect().size

	# Vị trí cụm di chuyển góc trái dưới
	var move_pos := Vector2(24, vs.y - JOY_AREA - 24)
	_joy_panel.position = move_pos
	_dpad_panel.position = move_pos
	_mode_btn.position = Vector2(move_pos.x + (JOY_AREA - 90) / 2.0, move_pos.y - 32)

	# Vị trí cụm thao tác góc phải dưới:
	# Nút THAO TÁC lớn đặt sát tay cầm ngón cái
	_btn_action.position = Vector2(vs.x - 108, vs.y - 180)

	# Nút TÚI ĐỒ (ở bên trái nút THAO TÁC)
	_btn_inv.position = Vector2(vs.x - 186, vs.y - 146)

	# Nút HẠT GIỐNG (ở phía trên nút THAO TÁC)
	_btn_seed.position = Vector2(vs.x - 96, vs.y - 264)

	# Nút ĂN NHANH (ở góc chéo trên-trái)
	_btn_eat.position = Vector2(vs.x - 186, vs.y - 230)

	# Nút TẠM DỪNG (ở giữa phía trên màn hình, không đè bản đồ)
	_btn_pause.position = Vector2((vs.x - 44) / 2.0, 16)


func set_action_label(hint: String) -> void:
	if _btn_action == null or not is_instance_valid(_btn_action):
		return
	var clean := hint.trim_prefix("E: ").strip_edges()
	if clean == "":
		_btn_action.text = "THAO TÁC"
		_btn_action.add_theme_font_size_override("font_size", 14)
		return

	var lower := clean.to_lower()
	var act_txt := "THAO TÁC"
	var font_sz := 13

	if "thu hoạch" in lower:
		act_txt = "🧺 THU"
	elif "cày" in lower or "cuốc" in lower:
		act_txt = "🌱 CUỐC"
	elif "tưới" in lower:
		act_txt = "💧 TƯỚI"
	elif "gieo" in lower:
		act_txt = "🌾 GIEO"
	elif "bắt sâu" in lower or "sâu bọ" in lower:
		act_txt = "🐛 BẮT"
	elif "cho" in lower and "ăn" in lower:
		act_txt = "🌾 CHO ĂN"
		font_sz = 12
	elif "nhặt" in lower:
		act_txt = "✨ NHẶT"
	elif "câu cá" in lower:
		act_txt = "🎣 CÂU"
	elif "múc nước" in lower:
		act_txt = "💧 MÚC"
	elif "hòm thư" in lower:
		act_txt = "📬 THƯ"
	elif "sạp hàng" in lower:
		act_txt = "🏪 SẠP"
	elif "đập" in lower or "đào" in lower or "khai thác" in lower:
		act_txt = "⛏️ ĐÀO"
	elif "xuống" in lower or "lên" in lower or "cầu thang" in lower:
		act_txt = "🪜 THANG"
	elif "nói" in lower or "bác tư" in lower or "chú hai" in lower or "cô tư" in lower or "trưởng thôn" in lower or "leah" in lower:
		act_txt = "💬 NÓI"
	elif "mèo" in lower:
		act_txt = "🐱 MÈO"
	else:
		if clean.length() > 8:
			act_txt = clean.substr(0, 7) + ".."
		else:
			act_txt = clean

	_btn_action.text = act_txt
	_btn_action.add_theme_font_size_override("font_size", font_sz)


func _process(delta: float) -> void:
	_time += delta
	if _joy_touch != -1 and main != null and main.mode != main.Mode.PLAY:
		_release_joy()
	_joy_panel.queue_redraw()


func _on_joy_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _joy_touch == -1:
			_joy_touch = t.index
			_knob = _joy_center + (t.position - _joy_center).limit_length(JOY_R)
			_apply_dir(_knob - _joy_center)
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
	_knob = _joy_center
	_release_all_dpad()


func _draw_joy() -> void:
	var alpha := 0.88 if _joy_touch != -1 else 0.58
	# Vành nền ngoài
	_joy_panel.draw_circle(_joy_center, JOY_R + 6.0, Color(0.08, 0.05, 0.03, 0.45 * alpha))
	_joy_panel.draw_circle(_joy_center, JOY_R, Color(0.18, 0.12, 0.08, 0.65 * alpha))
	_joy_panel.draw_arc(_joy_center, JOY_R, 0, TAU, 48, Color(0.86, 0.70, 0.32, 0.95 * alpha), 2.5)

	# 4 mũi tên hướng
	var font := ThemeDB.fallback_font
	for d: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var p := _joy_center + d * (JOY_R - 18.0)
		var sym := "▲" if d == Vector2.UP else ("▼" if d == Vector2.DOWN else ("◀" if d == Vector2.LEFT else "▶"))
		_joy_panel.draw_string(font, p + Vector2(-6, 5), sym,
				HORIZONTAL_ALIGNMENT_CENTER, -1, 15, Color(1.0, 0.92, 0.80, 0.85 * alpha))

	# Núm kéo joystick
	_joy_panel.draw_circle(_knob, KNOB_R + 3.0, Color(0.08, 0.05, 0.03, 0.75 * alpha))
	_joy_panel.draw_circle(_knob, KNOB_R, Color(0.92, 0.84, 0.65, 0.95 * alpha))
	_joy_panel.draw_arc(_knob, KNOB_R, 0, TAU, 32, UIKit.COLOR_BORDER_BRIGHT * alpha, 2.0)
	_joy_panel.draw_circle(_knob, 8.0, Color(0.48, 0.32, 0.15, 0.85 * alpha))
