extends CanvasLayer
# Màn hình chính Nông Trại Việt: Phong cách Nông trại ấm cúng & Mộc mạc.

const CropDB := preload("res://scripts/crop_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal start_requested
signal continue_requested

var start_btn: Button
var _continue_btn: Button
var _guide: PanelContainer


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS

	# --- Nền phong cảnh làng quê vẽ bằng code ---
	var bg := _build_landscape_background()
	add_child(bg)

	# --- Bố cục trung tâm ---
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)

	# --- Biển hiệu gỗ treo (Title Plaque) ---
	var plaque := PanelContainer.new()
	plaque.add_theme_stylebox_override("panel", UIKit.wood_frame(16, 3, UIKit.COLOR_WOOD_BG, UIKit.COLOR_BORDER_BRIGHT))
	plaque.custom_minimum_size = Vector2(620, 0)
	v.add_child(plaque)

	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	plaque.add_child(pv)

	# Dải khay gỗ trưng bày nông sản
	var shelf := PanelContainer.new()
	shelf.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.10, 0.06, 0.04, 0.8), UIKit.COLOR_BORDER_WOOD, 8))
	pv.add_child(shelf)
	var icons := HBoxContainer.new()
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	icons.add_theme_constant_override("separation", 5)
	shelf.add_child(icons)
	for crop in CropDB.CROPS:
		var slot := PanelContainer.new()
		slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
		var tr := TextureRect.new()
		tr.texture = TextureGen.prod_icon(crop)
		tr.custom_minimum_size = Vector2(26, 26)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		slot.add_child(tr)
		icons.add_child(slot)

	# Tên game chạm khắc vàng lúa
	var title := UIKit.title_label(pv, "🌾 NÔNG TRẠI VIỆT 🌾", 52, UIKit.COLOR_TEXT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 10)

	var sub := UIKit.label(pv, "Hành Trình Lập Nghiệp Làng Quê Yên Bình", 17, UIKit.COLOR_TEXT_BODY)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	UIKit.divider(pv)

	# Khẩu hiệu quy trình mùa màng
	var flow := UIKit.label(pv, "🌱 Cày đất  •  Gieo hạt  •  Tưới nước  •  Thu hoạch  •  Mở khóa 16 loại cây 🌾", 14, UIKit.COLOR_BORDER_GOLD)
	flow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# --- Cột nút bấm gỗ ---
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 10)
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(btn_box)

	start_btn = UIKit.styled_button(btn_box, "▶ BẮT ĐẦU MỚI", 20, "buy")
	start_btn.custom_minimum_size = Vector2(300, 48)
	start_btn.pressed.connect(func(): start_requested.emit())

	_continue_btn = UIKit.styled_button(btn_box, "TIẾP TỤC CUỘC CHƠI", 18, "primary")
	_continue_btn.custom_minimum_size = Vector2(300, 44)
	_continue_btn.pressed.connect(func(): continue_requested.emit())

	var guide_btn := UIKit.styled_button(btn_box, "📖 CẨM NANG NÔNG DÂN", 16, "default")
	guide_btn.custom_minimum_size = Vector2(300, 40)
	guide_btn.pressed.connect(func(): _guide.visible = not _guide.visible)

	# Dòng chữ chân trang ấm cúng
	var footer := UIKit.label(v, "Bấm Enter hoặc C để bắt đầu ngay · Godot 4.7", 13, UIKit.COLOR_TEXT_MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# --- Bảng cẩm nang mở rộng ---
	_guide = _build_guide()
	v.add_child(_guide)
	_guide.visible = false


func _build_landscape_background() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 1. Bầu trời bình minh ấm áp
	var sky := ColorRect.new()
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.color = Color(0.18, 0.28, 0.32) # Xanh sớm mai
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sky)

	# Gradient vầng đông vàng cam
	var dawn := ColorRect.new()
	dawn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dawn.offset_top = -420
	dawn.color = Color(0.85, 0.58, 0.28, 0.45) # Ánh nắng vàng ấm
	dawn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dawn)

	# 2. Mặt trời mọc ở đường chân trời
	var sun_center := Panel.new()
	var sun_sb := StyleBoxFlat.new()
	sun_sb.bg_color = Color(1.0, 0.92, 0.55, 0.85)
	sun_sb.set_corner_radius_all(90)
	sun_sb.shadow_color = Color(1.0, 0.85, 0.40, 0.4)
	sun_sb.shadow_size = 30
	sun_center.add_theme_stylebox_override("panel", sun_sb)
	sun_center.custom_minimum_size = Vector2(180, 180)
	sun_center.set_anchors_preset(Control.PRESET_CENTER)
	sun_center.offset_left = -90
	sun_center.offset_right = 90
	sun_center.offset_top = -140
	sun_center.offset_bottom = 40
	sun_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sun_center)

	# 3. Dãy đồi xanh xa xa
	var hills_far := ColorRect.new()
	hills_far.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hills_far.offset_top = -260
	hills_far.color = Color(0.24, 0.38, 0.22, 0.75)
	hills_far.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hills_far)

	# 4. Đồi xanh gần
	var hills_near := ColorRect.new()
	hills_near.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hills_near.offset_top = -170
	hills_near.color = Color(0.18, 0.32, 0.16, 0.85)
	hills_near.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hills_near)

	# 5. Cánh đồng lúa vàng màu mỡ cận cảnh
	var field := ColorRect.new()
	field.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	field.offset_top = -80
	field.color = Color(0.42, 0.32, 0.14, 0.95)
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(field)

	# Lớp phủ ấm cúng làm dịu toàn bộ phong cảnh
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.12, 0.08, 0.04, 0.35)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)

	return root


func _build_guide() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 2, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	p.custom_minimum_size = Vector2(740, 0)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var t := UIKit.title_label(head, "📜 CẨM NANG NHÀ NÔNG VIỆT NAM", 19, UIKit.COLOR_TEXT_TITLE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_btn := UIKit.styled_button(head, "✕ Đóng", 13, "danger")
	close_btn.pressed.connect(func(): _guide.visible = false)

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
		"• Chăn nuôi: Gặp Cô Tư mua chuồng & con giống (Gà, Bò, Lợn, Cừu). Nuôi 2 con cùng loài có thể sinh ra con non baby! Gà cho trứng, bò cho sữa, lợn cho thịt, cừu cho lông. Ra chuồng bấm [E] thu gom bán lại cho cô.")
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
	_guide.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_C:
			start_requested.emit()


func hide_me() -> void:
	visible = false
