extends CanvasLayer
# Bảng Cài Đặt (Settings Panel): Phong cách Gỗ Mộc Stardew Valley.
# - Âm thanh: nhãn "Âm thanh", nút bật/tắt loa (🔊 / 🔇) và thanh kéo âm lượng (HSlider).
# - Tốc độ chơi: điều chỉnh tốc độ từ x1 đến x5 với nút chu kỳ và 5 chip chọn nhanh.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")

signal closed

var sound_toggle_btn: Button
var volume_slider: HSlider

var speed_label: Label
var speed_cycle_btn: Button
var speed_buttons: Array[Button] = []

var _panel: PanelContainer


func _ready() -> void:
	layer = 28
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Lớp nền tối mờ - bấm ra ngoài để đóng
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.68)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			close()
	)
	root.add_child(dim)

	# Hộp thoại trung tâm
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 3, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	_panel.custom_minimum_size = Vector2(430, 0)
	center.add_child(_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_panel.add_child(v)

	# --- TIÊU ĐỀ: CÀI ĐẶT & NÚT ĐÓNG "✕" ---
	var top_h := HBoxContainer.new()
	top_h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(top_h)

	var gear_ic := TextureRect.new()
	gear_ic.texture = TextureGen.gear_icon()
	gear_ic.custom_minimum_size = Vector2(24, 24)
	gear_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_h.add_child(gear_ic)

	var title := Label.new()
	title.text = " Cài đặt"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.8))
	close_btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_CLOSE_BG, Color(0.7, 0.3, 0.2)))
	close_btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_CLOSE_HOVER, Color(0.9, 0.4, 0.3)))
	close_btn.pressed.connect(close)
	top_h.add_child(close_btn)

	UIKit.divider(v)

	# --- MỤC 1: ÂM THANH (CHỈ CHỮ "Âm thanh", NÚT TẮT MỞ LOA & THANH KÉO ÂM LƯỢNG) ---
	var sound_card := PanelContainer.new()
	sound_card.add_theme_stylebox_override("panel", UIKit.row_box())
	v.add_child(sound_card)

	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 8)
	sound_card.add_child(sv)

	var s_top := HBoxContainer.new()
	sv.add_child(s_top)

	var sound_title := Label.new()
	sound_title.text = "Âm thanh"
	sound_title.add_theme_font_size_override("font_size", 15)
	sound_title.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
	sound_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s_top.add_child(sound_title)

	var sound_controls_h := HBoxContainer.new()
	sound_controls_h.add_theme_constant_override("separation", 12)
	sound_controls_h.alignment = BoxContainer.ALIGNMENT_CENTER
	sv.add_child(sound_controls_h)

	# Nút tắt mở loa: hiển thị biểu tượng 🔊 hoặc 🔇
	sound_toggle_btn = Button.new()
	sound_toggle_btn.focus_mode = Control.FOCUS_NONE
	sound_toggle_btn.custom_minimum_size = Vector2(44, 40)
	sound_toggle_btn.add_theme_font_size_override("font_size", 20)
	sound_toggle_btn.pressed.connect(_on_sound_toggle_pressed)
	sound_controls_h.add_child(sound_toggle_btn)

	# Thanh kéo âm lượng (HSlider)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.custom_minimum_size = Vector2(280, 32)
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_slider(volume_slider)
	volume_slider.value_changed.connect(_on_volume_changed)
	sound_controls_h.add_child(volume_slider)

	UIKit.divider(v)

	# --- MỤC 2: TỐC ĐỘ CHƠI (x1 đến x5) ---
	var speed_card := PanelContainer.new()
	speed_card.add_theme_stylebox_override("panel", UIKit.row_box())
	v.add_child(speed_card)

	var sp_v := VBoxContainer.new()
	sp_v.add_theme_constant_override("separation", 8)
	speed_card.add_child(sp_v)

	var sp_top := HBoxContainer.new()
	sp_v.add_child(sp_top)

	speed_label = UIKit.label(sp_top, "⚡ Tốc độ: x1 (Chuẩn)", 15, UIKit.COLOR_TEXT_TITLE)
	speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	speed_cycle_btn = Button.new()
	speed_cycle_btn.focus_mode = Control.FOCUS_NONE
	speed_cycle_btn.custom_minimum_size = Vector2(160, 32)
	speed_cycle_btn.add_theme_font_size_override("font_size", 13)
	speed_cycle_btn.pressed.connect(_on_speed_cycle_pressed)
	sp_top.add_child(speed_cycle_btn)

	var chip_h := HBoxContainer.new()
	chip_h.add_theme_constant_override("separation", 6)
	sp_v.add_child(chip_h)

	var speeds := [1, 2, 3, 4, 5]
	for spd in speeds:
		var chip := Button.new()
		chip.text = "x%d" % spd
		if spd == 1:
			chip.text = "x1 (Chuẩn)"
		elif spd == 5:
			chip.text = "x5 (Nhanh)"
		chip.focus_mode = Control.FOCUS_NONE
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.custom_minimum_size = Vector2(0, 32)
		chip.add_theme_font_size_override("font_size", 12)
		var target_speed: float = float(spd)
		chip.pressed.connect(func():
			var gs := _gs()
			if gs != null:
				gs.set_game_speed(target_speed)
			_update_ui()
		)
		chip_h.add_child(chip)
		speed_buttons.append(chip)

	UIKit.divider(v)

	# --- NÚT ĐÓNG / ÁP DỤNG ---
	var apply_btn := UIKit.styled_button(v, "✔ Đóng", 15, "buy")
	apply_btn.custom_minimum_size = Vector2(0, 36)
	apply_btn.pressed.connect(close)

	_update_ui()


func _style_slider(slider: HSlider) -> void:
	var track_sb := StyleBoxFlat.new()
	track_sb.bg_color = Color(0.12, 0.08, 0.05, 0.95)
	track_sb.border_color = Color(0.45, 0.30, 0.18)
	track_sb.set_border_width_all(1)
	track_sb.set_corner_radius_all(4)
	track_sb.expand_margin_top = 4
	track_sb.expand_margin_bottom = 4

	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = Color(0.86, 0.70, 0.32)
	fill_sb.set_corner_radius_all(4)
	fill_sb.expand_margin_top = 4
	fill_sb.expand_margin_bottom = 4

	slider.add_theme_stylebox_override("slider", track_sb)
	slider.add_theme_stylebox_override("grabber_area", fill_sb)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_sb)

	var grabber_img := Image.create_empty(16, 20, false, Image.FORMAT_RGBA8)
	for y in range(20):
		for x in range(16):
			if x == 0 or x == 15 or y == 0 or y == 19:
				grabber_img.set_pixel(x, y, Color(0.12, 0.08, 0.05))
			elif x == 1 or y == 1:
				grabber_img.set_pixel(x, y, Color(1.0, 0.88, 0.45))
			else:
				grabber_img.set_pixel(x, y, Color(0.86, 0.70, 0.32))
	var grabber_tex := ImageTexture.create_from_image(grabber_img)
	slider.add_theme_icon_override("grabber", grabber_tex)
	slider.add_theme_icon_override("grabber_highlight", grabber_tex)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_update_ui()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _gs() -> Node:
	if has_node("/root/GameState"):
		return get_node("/root/GameState")
	return null


func _am() -> Node:
	if has_node("/root/AudioManager"):
		return get_node("/root/AudioManager")
	return null


func _on_sound_toggle_pressed() -> void:
	var am := _am()
	if am != null:
		am.toggle_sound()
	else:
		var gs := _gs()
		if gs != null:
			gs.set_sound_enabled(not bool(gs.sound_enabled))
	_update_ui()


func _on_volume_changed(val: float) -> void:
	var am := _am()
	if am != null:
		am.set_volume(val)
	_update_ui()


func _on_speed_cycle_pressed() -> void:
	var gs := _gs()
	if gs != null:
		gs.cycle_game_speed()
	_update_ui()


func _update_ui() -> void:
	var am := _am()
	var gs := _gs()

	# 1. Cập nhật Âm thanh
	var is_enabled: bool = true
	var cur_vol: float = 0.8

	if am != null:
		is_enabled = am.sound_enabled
		cur_vol = am.sound_volume
	elif gs != null:
		is_enabled = bool(gs.sound_enabled)

	if sound_toggle_btn != null:
		if is_enabled and cur_vol > 0.001:
			sound_toggle_btn.text = "🔊"
			sound_toggle_btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.45))
			sound_toggle_btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.4, 0.85, 0.35)))
			sound_toggle_btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.5, 0.95, 0.45)))
		else:
			sound_toggle_btn.text = "🔇"
			sound_toggle_btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
			sound_toggle_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.25, 0.18, 0.14), Color(0.5, 0.4, 0.3)))
			sound_toggle_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.35, 0.25, 0.20), Color(0.6, 0.5, 0.4)))

	if volume_slider != null:
		var target_val: float = cur_vol if is_enabled else 0.0
		if not is_equal_approx(volume_slider.value, target_val):
			volume_slider.set_value_no_signal(target_val)

	# 2. Cập nhật Tốc độ chơi
	var cur_spd: float = float(gs.game_speed) if gs != null else 1.0
	var cur_int: int = int(round(cur_spd))
	if speed_label != null:
		var desc := "Chuẩn"
		if cur_int == 2: desc = "Nhanh x2"
		elif cur_int == 3: desc = "Nhanh x3"
		elif cur_int == 4: desc = "Nhanh x4"
		elif cur_int == 5: desc = "Cực nhanh x5"
		speed_label.text = "⚡ Tốc độ: x%d (%s)" % [cur_int, desc]

	if speed_cycle_btn != null:
		var next_int: int = cur_int + 1 if cur_int < 5 else 1
		speed_cycle_btn.text = "⏩ Đổi: x%d ➔ x%d" % [cur_int, next_int]
		speed_cycle_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.38, 0.26, 0.14), UIKit.COLOR_BORDER_GOLD))
		speed_cycle_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.50, 0.34, 0.18), UIKit.COLOR_BORDER_BRIGHT))

	# 3. Cập nhật 5 chip chọn nhanh
	for i in range(speed_buttons.size()):
		var btn: Button = speed_buttons[i]
		var spd_val: int = i + 1
		var is_selected := (spd_val == cur_int)
		if is_selected:
			btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.42, 0.30, 0.12), UIKit.COLOR_BORDER_BRIGHT, 5, 2))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.52, 0.38, 0.16), UIKit.COLOR_BORDER_BRIGHT, 5, 2))
		else:
			btn.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70))
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.24, 0.16, 0.10), UIKit.COLOR_BORDER_WOOD, 5, 1))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.32, 0.22, 0.14), UIKit.COLOR_BORDER_GOLD, 5, 1))
