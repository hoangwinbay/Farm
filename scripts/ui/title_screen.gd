extends CanvasLayer
# Màn hình khởi đầu Fluffy Farm: Phong cách Nông trại ấm cúng & Mộc mạc Stardew Valley.
# Tái hiện chuẩn xác thiết kế đồ họa pixel art: Logo Fluffy Farm, phong cảnh hoàng hôn ấm áp,
# nhãn "ẤN BẮT ĐẦU" nhấp nháy, các nút gỗ "BẮT ĐẦU MỚI", "TIẾP TỤC", "HƯỚNG DẪN" (kèm cà rốt).

const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal start_requested
signal continue_requested

var start_btn: Button
var _continue_btn: Button
var _guide: PanelContainer
var _guide_overlay: Control


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# 1. Hình nền Full cảnh Fluffy Farm (chứa logo Fluffy Farm trên nền trời hoàng hôn làng quê)
	var bg := TextureRect.new()
	bg.texture = load("res://picture/title_screen/title_bg.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	# 2. Khối trung tâm chứa các nút bấm gỗ & nhãn "ẤN BẮT ĐẦU"
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	v.set_anchors_preset(Control.PRESET_CENTER_TOP)
	v.offset_top = 335
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(v)

	# Dòng chữ "ẤN BẮT ĐẦU" với hiệu ứng nhấp nháy êm dịu (pulsing breathing)
	var prompt_lbl := Label.new()
	prompt_lbl.text = "ẤN BẮT ĐẦU"
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_lbl.add_theme_font_size_override("font_size", 21)
	prompt_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	prompt_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 0.98))
	prompt_lbl.add_theme_constant_override("outline_size", 6)
	v.add_child(prompt_lbl)

	var p_tween := create_tween().set_loops()
	p_tween.tween_property(prompt_lbl, "modulate:a", 0.55, 0.75).set_trans(Tween.TRANS_SINE)
	p_tween.tween_property(prompt_lbl, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_SINE)

	# Khối 3 nút gỗ chạm khắc - kích thước đồng bộ tuyệt đối với ô trên cùng
	var btn_box := VBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 8)
	v.add_child(btn_box)

	var base_btn_size := Vector2(292, 78)

	# Nút 1: BẮT ĐẦU MỚI (ô trên cùng làm chuẩn kích thước)
	start_btn = _create_wood_button("res://picture/title_screen/btn_new_game.png", base_btn_size)
	start_btn.pressed.connect(func(): start_requested.emit())
	btn_box.add_child(start_btn)

	# Nút 2: TIẾP TỤC (bằng chính xác kích thước ô trên cùng)
	_continue_btn = _create_wood_button("res://picture/title_screen/btn_continue.png", base_btn_size)
	_continue_btn.pressed.connect(func(): continue_requested.emit())
	btn_box.add_child(_continue_btn)

	# Nút 3: HƯỚNG DẪN (thanh gỗ bằng chính xác ô trên cùng, kèm củ cà rốt xinh xắn ở góc)
	var guide_tex_size := Vector2(base_btn_size.x * 481.0 / 442.0, base_btn_size.y * 134.0 / 118.0)
	var guide_btn := _create_wood_button("res://picture/title_screen/btn_guide.png", base_btn_size, guide_tex_size)
	guide_btn.pressed.connect(func():
		_guide_overlay.visible = not _guide_overlay.visible
	)
	btn_box.add_child(guide_btn)

	# 3. Dòng bản quyền dưới cùng: "© 2026 FLUFFY GAME STUDIO"
	var footer := Label.new()
	footer.text = "© 2026 FLUFFY GAME STUDIO"
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_bottom = -16
	footer.offset_top = -42
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	footer.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	footer.add_theme_constant_override("outline_size", 4)
	root.add_child(footer)

	# 4. Lớp phủ cửa sổ Cẩm Nang / Hướng Dẫn Nông Dân
	_guide_overlay = Control.new()
	_guide_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_guide_overlay.visible = false
	root.add_child(_guide_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.70)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_guide_overlay.visible = false
	)
	_guide_overlay.add_child(dim)

	var g_center := CenterContainer.new()
	g_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_guide_overlay.add_child(g_center)

	_guide = _build_guide()
	g_center.add_child(_guide)


func _create_wood_button(tex_path: String, btn_size: Vector2, tex_size: Vector2 = Vector2.ZERO) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = btn_size
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.flat = true

	var empty_sb := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	btn.add_theme_stylebox_override("disabled", empty_sb)
	btn.add_theme_stylebox_override("focus", empty_sb)

	var tr := TextureRect.new()
	tr.name = "Texture"
	tr.texture = load(tex_path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	if tex_size == Vector2.ZERO:
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		tr.position = Vector2.ZERO
		tr.size = tex_size
	tr.pivot_offset = btn_size * 0.5
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tr)

	# Vi diễn hoạt tương tác khi rê chuột (Hover) & bấm (Pressed)
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			var tw := btn.create_tween()
			tw.tween_property(tr, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(tr, "modulate", Color(1.15, 1.15, 1.1), 0.12)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(tr, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(tr, "modulate", Color.WHITE if not btn.disabled else Color(0.55, 0.55, 0.55, 0.6), 0.12)
	)
	btn.button_down.connect(func():
		if not btn.disabled:
			var tw := btn.create_tween()
			tw.tween_property(tr, "scale", Vector2(0.96, 0.96), 0.08)
	)
	btn.button_up.connect(func():
		if not btn.disabled:
			var tw := btn.create_tween()
			tw.tween_property(tr, "scale", Vector2(1.04, 1.04) if btn.is_hovered() else Vector2.ONE, 0.08)
	)

	return btn


func _build_guide() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 3, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	p.custom_minimum_size = Vector2(740, 0)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var t := UIKit.title_label(head, "📜 CẨM NANG NHÀ NÔNG - FLUFFY FARM", 19, UIKit.COLOR_TEXT_TITLE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_btn := UIKit.styled_button(head, "✕ Đóng", 13, "danger")
	close_btn.pressed.connect(func(): _guide_overlay.visible = false)

	UIKit.divider(v)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)

	# Thẻ 1: Mùa màng
	var c1 := _guide_card("🌾 VỤ MÙA LÀNG QUÊ",
		"1. Cày đất: Đứng cạnh ô cỏ bấm [E] (tiêu hao 1 cuốc).\n" +
		"2. Gieo hạt: Mở kho đồ [I], chọn hạt rồi bấm [E].\n" +
		"3. Tưới nước: Bấm [E] để tưới ẩm (đất màu đậm hơn).\n" +
		"4. Thu hoạch: Cây lớn theo thời gian thật khi đất ẩm; khi chín bấm [E] thu hoạch và mang qua Bác Tư bán lấy tiền mở khóa cây mới.")
	grid.add_child(c1)

	# Thẻ 2: Câu cá & Chăn nuôi
	var c2 := _guide_card("🎣 CÂU CÁ & CHĂN NUÔI",
		"• Câu cá: Gặp Chú Hai ở bờ ao mua cần câu. Đứng bờ ao bấm [E] thả câu (15s tự giật cần). Ban đêm có cơ hội câu được Cá Trê Vàng và Cá Chiên huyền thoại!\n" +
		"• Chăn nuôi: Gặp Cô Tư mua chuồng & con giống (Gà, Bò, Lợn, Cừu). Nuôi 2 con cùng loài có thể sinh sản! Gà cho trứng, bò cho sữa, lợn cho thịt, cừu cho lông.")
	grid.add_child(c2)

	# Thẻ 3: Thời gian & Sinh hoạt
	var c3 := _guide_card("⏰ THỜI GIAN & LƯU GAME",
		"• 1 ngày trong game dài ~15 phút thật.\n" +
		"• 7:00 sáng đến 19:00 tối: trời sáng.\n" +
		"• 2:00 sáng chưa ngủ sẽ ngất xỉu vì mệt.\n" +
		"• Vào nhà bấm [E] ngủ để sang ngày mới và TỰ ĐỘNG LƯU GAME. Bạn cũng có thể bấm [Esc] để lưu bất kỳ lúc nào.")
	grid.add_child(c3)

	# Thẻ 4: Phím tắt điều khiển
	var c4 := _guide_card("⌨️ BẢNG PHÍM TẮT TIỆN LỢI",
		"• [W][A][S][D] hoặc Phím mũi tên: Di chuyển nông dân\n" +
		"• [E] hoặc [Space]: Tương tác chính (cày, gieo, tưới, gặt, nói chuyện)\n" +
		"• [I] hoặc [Tab]: Mở Kho đồ / chọn hạt giống\n" +
		"• [R]: Đổi nhanh hạt giống đang cầm\n" +
		"• [Esc]: Tạm dừng trò chơi / Lưu game / Thoát cửa sổ")
	grid.add_child(c4)

	return p


func _guide_card(heading: String, body: String) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIKit.row_box())
	pc.custom_minimum_size = Vector2(340, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	pc.add_child(v)

	UIKit.label(v, heading, 15, UIKit.COLOR_TEXT_TITLE)
	var content := UIKit.label(v, body, 13, UIKit.COLOR_TEXT_BODY)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return pc


func open(has_save: bool) -> void:
	visible = true
	_continue_btn.disabled = not has_save
	var tr := _continue_btn.get_node_or_null("Texture") as CanvasItem
	if tr != null:
		tr.modulate = Color.WHITE if has_save else Color(0.55, 0.55, 0.55, 0.6)
	if _guide_overlay != null:
		_guide_overlay.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _guide_overlay != null and _guide_overlay.visible:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			_guide_overlay.visible = false
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_C or event.keycode == KEY_SPACE:
			start_requested.emit()


func hide_me() -> void:
	visible = false
