extends CanvasLayer
# Giao diện Thuê & Quản Lý Mèo Làm Nông (Phong cách Cửa Hàng Tối Giản & Thẻ Lưới Hiện Đại):
# - Thiết kế dạng Shop Dock Panel neo sát lề phải màn hình đồng bộ cùng Shop Bác Tư, Cô Tư, Chú Hai.
# - Thẻ dịch vụ tối giản, trực quan, hỗ trợ vuốt cuộn cảm ứng và modal xem chi tiết 1-chạm.

const TextureGen := preload("res://scripts/texture_gen.gd")
const CropDB := preload("res://scripts/crop_db.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const CatHelperScript := preload("res://scripts/cat_helper.gd")

signal closed
signal feedback(text: String, color: Color)

var cats: Array = []
var cat: Node2D = null

var back_btn: Button
var dock_panel: PanelContainer

var _container: VBoxContainer
var _cat_selector_bar: HBoxContainer
var _hire_view: VBoxContainer
var _manage_view: VBoxContainer

# Hire view dynamic fields
var _hire_cards_container: VBoxContainer
var _hire_title_lbl: Label
var _hire_portrait_rect: TextureRect
var _hire_name_badge: Label
var _hire_intro_lbl: Label
var _hire_wage_info: Label
var _hire_btn: Button

# Manage view dynamic fields
var _manage_title_lbl: Label
var _manage_avatar_rect: TextureRect

# Quản lý views
var _status_label: Label
var _water_label: Label
var _seeds_in_cat_box: VBoxContainer
var _seeds_in_bag_box: VBoxContainer

var _active_tab: int = 0
var _current_mode: String = "hire" # "hire" or "manage"
var _tab_hire_mode_btn: Button
var _tab_manage_mode_btn: Button

var _tab_seeds_btn: Button
var _tab_upgrades_btn: Button
var _tab_seeds_container: VBoxContainer
var _tab_upgrades_container: VBoxContainer
var _upgrade_cards_box: VBoxContainer
var _wallet_label: Label

var _hoe_card: PanelContainer
var _right_box: PanelContainer
var _left_box: PanelContainer

var _hoe_icon_rect: TextureRect
var _hoe_info_label: Label
var _give_hoe_1_btn: Button
var _give_hoe_all_btn: Button
var _take_hoe_btn: Button
var _take_hoe_all_btn: Button
var _bag_title_label: Label
var _cat_bag_title_label: Label

# Giao diện dành riêng cho Mèo Bán Hàng (Tuxedo Cat Seller)
var _seller_container: VBoxContainer
var _seller_stall_label: Label
var _seller_revenue_label: Label
var _seller_collect_btn: Button
var _seller_open_stall_btn: Button
var _seller_filter: String = "all"
var _seller_filter_buttons: Dictionary = {}
var _seller_items_box: VBoxContainer
var _seller_summary_label: Label

# Modal chi tiết mèo (Info Modal phong cách Cửa hàng)
var _modal_root: Control
var _modal_icon: TextureRect
var _modal_title: Label
var _modal_desc_label: Label
var _modal_lines_v: VBoxContainer
var _modal_action_h: HBoxContainer
var _current_modal_data: Dictionary = {}


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Nền làm mờ toàn màn hình
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.70)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	root.add_child(dim)

	# Nút quay lại "<<" ở góc trên bên trái màn hình
	back_btn = Button.new()
	back_btn.text = "<<"
	back_btn.position = Vector2(24, 20)
	back_btn.custom_minimum_size = Vector2(56, 44)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.COLOR_WOOD_BG, UIKit.COLOR_BORDER_GOLD, 10, 2))
	back_btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.COLOR_WOOD_LIGHT, UIKit.COLOR_BORDER_BRIGHT, 10, 2))
	back_btn.add_theme_stylebox_override("pressed", UIKit.btn_style(UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD, 10, 0))
	back_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
	back_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	back_btn.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	back_btn.add_theme_constant_override("outline_size", 3)
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.pressed.connect(close)
	root.add_child(back_btn)

	# Khung cửa hàng đặt ở GIỮA màn hình (CenterContainer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	dock_panel = PanelContainer.new()
	dock_panel.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 3, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	dock_panel.custom_minimum_size = Vector2(560, 620)
	dock_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(dock_panel)

	_container = VBoxContainer.new()
	_container.add_theme_constant_override("separation", 10)
	dock_panel.add_child(_container)

	# --- Header: Tiêu đề cửa hàng & Nút đóng ---
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_child(head)

	var title := UIKit.title_label(head, "DỊCH VỤ MÈO LÀM NÔNG", 20, UIKit.COLOR_TEXT_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var close_head_btn := UIKit.styled_button(head, "✕ Đóng (Esc)", 12, "danger")
	close_head_btn.pressed.connect(close)

	# --- Thanh ví tiền người chơi ---
	var wallet_bar := PanelContainer.new()
	wallet_bar.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.17, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	_container.add_child(wallet_bar)

	var wh := HBoxContainer.new()
	wh.add_theme_constant_override("separation", 6)
	wh.alignment = BoxContainer.ALIGNMENT_CENTER
	wallet_bar.add_child(wh)

	var wic := TextureRect.new()
	wic.texture = TextureGen.coin_icon()
	wic.custom_minimum_size = Vector2(16, 16)
	wic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	wh.add_child(wic)

	_wallet_label = UIKit.label(wh, "Tiền hiện có trong ví: 0 xu", 13, UIKit.COLOR_TEXT_GOLD)

	# Các nút điều khiển ẩn để tương thích code
	_tab_hire_mode_btn = Button.new()
	_tab_hire_mode_btn.visible = false
	_tab_hire_mode_btn.pressed.connect(_show_hire_mode)
	root.add_child(_tab_hire_mode_btn)

	_tab_manage_mode_btn = Button.new()
	_tab_manage_mode_btn.visible = false
	_tab_manage_mode_btn.pressed.connect(_show_manage_mode)
	root.add_child(_tab_manage_mode_btn)

	_cat_selector_bar = HBoxContainer.new()
	_cat_selector_bar.visible = false
	root.add_child(_cat_selector_bar)

	# --- 2 Khung hiển thị nội dung ---
	_build_hire_view()
	_build_manage_view()

	# --- Hộp thoại chi tiết Modal (phong cách Shop) ---
	_build_info_modal(root)


func _build_cat_selector_bar() -> void:
	pass


func _refresh_cat_selector() -> void:
	if _cat_selector_bar == null:
		return
	for c in _cat_selector_bar.get_children():
		c.queue_free()

	_cat_selector_bar.visible = false
	for c_node in cats:
		if c_node == null or not is_instance_valid(c_node):
			continue
		var is_sel: bool = (c_node == cat)
		var status_str := " (Đang làm)" if c_node.is_hired else " (Chưa thuê)"
		var cname: String = str(c_node.get("cat_name")) if "cat_name" in c_node else "Mèo"
		var btn_txt := "🐱 " + cname + status_str
		var btn_style := "gold" if is_sel else "neutral"
		var btn := UIKit.styled_button(_cat_selector_bar, btn_txt, 12, btn_style)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var target_c: Node2D = c_node
		btn.pressed.connect(func():
			cat = target_c
			_refresh_cat_selector()
			_refresh_view()
		)


func open(cat_node: Node2D = null, all_cats: Array = []) -> void:
	if not all_cats.is_empty():
		cats = all_cats
	elif cats.is_empty() and cat_node != null:
		cats = [cat_node]

	if cat_node != null:
		cat = cat_node
	elif not cats.is_empty() and (cat == null or not (cat in cats)):
		cat = cats[0]

	visible = true

	# Khi nhấn vào biểu tượng mèo trên HUD / phím M / Nhà Junimo (cat_node == null),
	# luôn luôn mở Danh Sách Mèo (cards) để xem & chọn tất cả các mèo!
	# Chỉ mở thẳng trang quản lý nếu người chơi tương tác trực tiếp với một chú mèo cụ thể đã thuê ngoài sân.
	if cat_node != null and cat_node.is_hired:
		_show_manage_mode()
	else:
		_show_hire_mode()

	_refresh_cat_selector()

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("meow")


func close() -> void:
	if _modal_root != null and _modal_root.visible:
		_hide_info_modal()
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		close()
		get_viewport().set_input_as_handled()


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		close()


func _update_wallet_label() -> void:
	if _wallet_label != null:
		var m: int = 0
		if has_node("/root/GameState"):
			m = int(get_node("/root/GameState").money)
		_wallet_label.text = "Tiền hiện có trong ví: %d xu" % m


func _update_mode_tabs() -> void:
	if _tab_hire_mode_btn != null and _tab_manage_mode_btn != null:
		if _current_mode == "hire":
			_tab_hire_mode_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.38, 0.26, 0.12), UIKit.COLOR_BORDER_GOLD, 6, 2))
			_tab_manage_mode_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.24, 0.18, 0.12), UIKit.COLOR_BORDER_WOOD, 6, 1))
		else:
			_tab_hire_mode_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.24, 0.18, 0.12), UIKit.COLOR_BORDER_WOOD, 6, 1))
			_tab_manage_mode_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.38, 0.26, 0.12), UIKit.COLOR_BORDER_GOLD, 6, 2))


func _show_hire_mode() -> void:
	_current_mode = "hire"
	_update_mode_tabs()
	if _hire_view != null: _hire_view.visible = true
	if _manage_view != null: _manage_view.visible = false
	_refresh_hire_data()


func _show_manage_mode() -> void:
	# Nếu chú mèo hiện tại chưa thuê, kiểm tra xem có chú mèo nào đã thuê không
	if cat != null and not cat.is_hired:
		var found_hired: Node2D = null
		for c in cats:
			if c != null and c.is_hired:
				found_hired = c
				break
		if found_hired != null:
			cat = found_hired
			_refresh_cat_selector()
		else:
			feedback.emit("Bạn chưa thuê chú mèo nào! Hãy thuê một chú mèo bên dưới.", Color(1.0, 0.85, 0.4))
			_show_hire_mode()
			return

	_current_mode = "manage"
	_update_mode_tabs()
	if _hire_view != null: _hire_view.visible = false
	if _manage_view != null: _manage_view.visible = true
	_refresh_manage_data()


func _refresh_view() -> void:
	if cat == null or not is_instance_valid(cat):
		close()
		return

	_refresh_cat_selector()
	_update_wallet_label()

	if not cat.is_hired:
		_show_hire_mode()
	else:
		if _current_mode == "hire":
			_show_hire_mode()
		else:
			_show_manage_mode()


# ---------- GIAO DIỆN THUÊ MÈO TỐI GIẢN NHƯ CỬA HÀNG ----------

func _build_hire_view() -> void:
	_hire_view = VBoxContainer.new()
	_hire_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hire_view.add_theme_constant_override("separation", 8)
	_container.add_child(_hire_view)

	var tip_lbl := UIKit.label(_hire_view, "Chọn chú mèo bạn muốn thuê để tự động phụ việc làm vườn:", 12, UIKit.COLOR_TEXT_MUTED)
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Danh sách thẻ mèo phong cách cửa hàng (Có gắn TouchScrollHelper)
	var hire_scroll := ScrollContainer.new()
	hire_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hire_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(hire_scroll)
	_hire_view.add_child(hire_scroll)

	_hire_cards_container = VBoxContainer.new()
	_hire_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hire_cards_container.add_theme_constant_override("separation", 10)
	hire_scroll.add_child(_hire_cards_container)

	# Khởi tạo các label ẩn / placeholder để tương thích với các script test
	_hire_title_lbl = Label.new()
	_hire_title_lbl.visible = false
	_hire_view.add_child(_hire_title_lbl)

	_hire_portrait_rect = TextureRect.new()
	_hire_portrait_rect.visible = false
	_hire_view.add_child(_hire_portrait_rect)

	_hire_name_badge = Label.new()
	_hire_name_badge.visible = false
	_hire_view.add_child(_hire_name_badge)

	_hire_intro_lbl = Label.new()
	_hire_intro_lbl.visible = false
	_hire_view.add_child(_hire_intro_lbl)

	_hire_wage_info = Label.new()
	_hire_wage_info.visible = false
	_hire_view.add_child(_hire_wage_info)

	_hire_btn = Button.new()
	_hire_btn.visible = false
	_hire_btn.pressed.connect(_on_hire_pressed)
	_hire_view.add_child(_hire_btn)


func _refresh_hire_data() -> void:
	if _hire_cards_container == null:
		return

	for c in _hire_cards_container.get_children():
		_hire_cards_container.remove_child(c)
		c.queue_free()

	_update_wallet_label()

	var target_list: Array = cats if not cats.is_empty() else ([cat] if cat != null else [])
	for c_node in target_list:
		if c_node == null or not is_instance_valid(c_node):
			continue
		var card := _build_cat_shop_card(c_node)
		_hire_cards_container.add_child(card)

	# Đồng bộ các biến tham chiếu cho chú mèo hiện tại để tương thích với kiểm thử
	if cat != null:
		var cname: String = str(cat.get("cat_name")) if "cat_name" in cat else "Mèo"
		if _hire_title_lbl != null:
			_hire_title_lbl.text = "🐱 %s LÀM NÔNG" % cname.to_upper()
		if _hire_portrait_rect != null:
			_hire_portrait_rect.texture = TextureGen.cat_char_tex("down", 0, cat.cat_breed)
		if _hire_name_badge != null:
			_hire_name_badge.text = "%s" % cname
		if _hire_intro_lbl != null:
			_hire_intro_lbl.text = "Thuê %s phụ giúp làm vườn" % cname
		if _hire_wage_info != null:
			_hire_wage_info.text = "💰 Tiền công: %d xu / ngày" % cat.daily_wage
		if _hire_btn != null:
			_hire_btn.text = "🤝 Đồng ý thuê %s (%d xu/ngày)" % [cname, cat.daily_wage]


func _build_cat_shop_card(c_node: Node2D) -> Control:
	var cname: String = str(c_node.get("cat_name")) if "cat_name" in c_node else "Mèo"
	var breed: String = str(c_node.get("cat_breed")) if "cat_breed" in c_node else "calico"
	var wage: int = int(c_node.get("daily_wage")) if "daily_wage" in c_node else 50
	var is_hired: bool = bool(c_node.get("is_hired"))
	var is_current: bool = (c_node == cat)

	var card := PanelContainer.new()
	var border_col := UIKit.COLOR_BORDER_GOLD if is_current else UIKit.COLOR_BORDER_WOOD
	card.add_theme_stylebox_override("panel", UIKit.wood_frame(10, 2 if is_current else 1, UIKit.COLOR_WOOD_INNER, border_col))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	card.add_child(cv)

	# --- Hàng 1: Trạng thái & Tiền công & Nút (i) xem chi tiết ---
	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 6)
	cv.add_child(top_h)

	var badge := PanelContainer.new()
	if is_hired:
		badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.24, 0.12), Color(0.35, 0.55, 0.30), 4))
		UIKit.label(badge, "✓ ĐANG LÀM VIỆC", 10, Color(0.70, 0.95, 0.65))
	else:
		badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.32, 0.22, 0.12), UIKit.COLOR_BORDER_GOLD, 4))
		UIKit.label(badge, "CHƯA THUÊ", 10, UIKit.COLOR_TEXT_GOLD)
	top_h.add_child(badge)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(sp)

	var wage_pill := PanelContainer.new()
	wage_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.17, 0.08), UIKit.COLOR_BORDER_GOLD, 4))
	UIKit.label(wage_pill, "💰 %d xu / ngày" % wage, 11, UIKit.COLOR_TEXT_GOLD)
	top_h.add_child(wage_pill)

	var info_btn := _create_info_circle_button(func():
		_show_cat_details_modal(c_node)
	)
	top_h.add_child(info_btn)

	# --- Hàng 2: Avatar & Thông tin tóm tắt tối giản ---
	var body_h := HBoxContainer.new()
	body_h.add_theme_constant_override("separation", 12)
	cv.add_child(body_h)

	var avatar_box := PanelContainer.new()
	avatar_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.08, 0.05), UIKit.COLOR_BORDER_WOOD, 6))
	avatar_box.custom_minimum_size = Vector2(58, 58)
	body_h.add_child(avatar_box)

	var cat_tex := TextureRect.new()
	cat_tex.texture = TextureGen.cat_char_tex("down", 0, breed)
	cat_tex.custom_minimum_size = Vector2(40, 48)
	cat_tex.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	avatar_box.add_child(cat_tex)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 3)
	body_h.add_child(info_v)

	var name_lbl := UIKit.title_label(info_v, "🐱 %s" % cname.to_upper(), 15, UIKit.COLOR_TEXT_TITLE)

	var role_str := ""
	var skills_str := ""
	if breed == "orange":
		role_str = "Nông dân tập sự · Làm vườn trọn gói"
		skills_str = "🌾 Thu hoạch · 💧 Tưới nước · 🐛 Bắt sâu · ⛏️ Cuốc xới · 🌱 Gieo hạt"
	elif breed == "calico":
		role_str = "Thợ Mỏ Chăm Chỉ · Tự động khai khoáng"
		skills_str = "⛏️ Đào đá & than · 💎 Khai thác quặng đồng, sắt, vàng & ngọc quý · 🏚️ Cất vào Nhà Kho"
	elif breed == "white":
		role_str = "Cần Thủ Chăm Chỉ · Tự động câu cá bên bờ ao"
		skills_str = "🎣 Thả câu & giật cá · 🐟 Câu các loại cá tươi bên bờ ao · 🏚️ Cất vào Nhà Kho"
	elif breed == "tuxedo":
		role_str = "Tiểu Thương Chuyên Nghiệp · Tự động bán hàng & gom tiền"
		skills_str = "🧺 Bày nông sản, cá & khoáng sản ra sạp · 💵 Bán đồ cho khách · 💰 Tự động thu tiền vào ví"
	UIKit.label(info_v, role_str, 11, UIKit.COLOR_TEXT_MUTED)

	var skills_lbl := UIKit.label(info_v, skills_str, 11, Color(0.85, 0.85, 0.80))
	skills_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# --- Hàng 3: Nút tương tác 1-chạm ---
	var action_h := HBoxContainer.new()
	action_h.add_theme_constant_override("separation", 8)
	cv.add_child(action_h)

	if not is_hired:
		var buy_btn := Button.new()
		buy_btn.text = "🤝 Thuê Ngay (%d xu/ngày)" % wage
		buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_btn.custom_minimum_size = Vector2(0, 34)
		buy_btn.add_theme_font_size_override("font_size", 13)
		buy_btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.55, 0.85, 0.45), 6, 2))
		buy_btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.65, 0.95, 0.55), 6, 2))
		buy_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
		buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		buy_btn.pressed.connect(func():
			cat = c_node
			_on_hire_pressed()
		)
		action_h.add_child(buy_btn)
	else:
		var manage_btn := UIKit.styled_button(action_h, "⚙️ Giao việc & Nâng cấp", 12, "gold")
		manage_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		manage_btn.pressed.connect(func():
			cat = c_node
			_show_manage_mode()
		)

		var dismiss_btn := UIKit.styled_button(action_h, "Cho nghỉ", 12, "danger")
		dismiss_btn.custom_minimum_size = Vector2(80, 0)
		dismiss_btn.pressed.connect(func():
			c_node.dismiss()
			_refresh_cat_selector()
			_refresh_view()
		)

	return card


func _show_cat_details_modal(c_node: Node2D) -> void:
	var cname: String = str(c_node.get("cat_name")) if "cat_name" in c_node else "Mèo"
	var breed: String = str(c_node.get("cat_breed")) if "cat_breed" in c_node else "calico"
	var wage: int = int(c_node.get("daily_wage")) if "daily_wage" in c_node else (100 if breed == "calico" else (80 if breed == "tuxedo" else (75 if breed == "white" else 50)))
	var desc_str := ""
	var loc_str := ""
	var work_str := ""
	var shed_str := ""
	var upgrade_str := ""

	if breed == "calico":
		desc_str = "Mèo Tam Thể thợ mỏ chăm chỉ, tự động khai thác khoáng sản quý giá từ Hầm Mỏ"
		loc_str = "Hầm Mỏ (xuất hiện sau khi thuê, nghỉ ngơi ở Nhà Junimo)"
		work_str = "⛏️ Công việc: Khai thác đá, than đá, quặng đồng, sắt, vàng và ngọc quý"
		shed_str = "🏚️ Cất kho: Tự động gom toàn bộ khoáng sản đào được về Nhà Kho"
		upgrade_str = "⭐ Nâng cấp: Nâng Tốc độ di chuyển, Năng suất khai thác & Sức chứa túi quặng"
	elif breed == "orange":
		desc_str = "Mèo Mướp Vàng làm nông chăm chỉ, tháo vát"
		loc_str = "Ruộng nương (xuất hiện ngay sau khi thuê, nghỉ ngơi ở Nhà Junimo)"
		work_str = "🌾 Công việc: Thu hoạch hoa màu, bắt sâu, tưới nước bằng bình, xới đất, gieo hạt"
		shed_str = "🏚️ Cất kho: Tự động gom toàn bộ nông sản & sâu bọ vào Nhà Kho"
		upgrade_str = "⭐ Nâng cấp: Nâng Tốc độ, Năng suất làm việc & Sức chứa túi / Bình nước"
	elif breed == "white":
		desc_str = "Mèo Trắng Tuyết yêu thích sông nước, chuyên cần câu các loại cá tươi bên hông ao"
		loc_str = "Nhà Junimo (xuất hiện ngay sau khi thuê)"
		work_str = "🎣 Công việc: Đứng ngang bờ hồ câu cá (hụt cá nếu cần đểu), đầy giỏ tự cất kho rồi câu tiếp"
		shed_str = "🏚️ Cất kho: Tự động đem cá về cất vào Nhà Kho rồi lập tức ra ao câu tiếp"
		upgrade_str = "⭐ Nâng cấp: Nâng Cần câu (giảm tỉ lệ hụt cá & mở cá hiếm), Tốc độ & Giỏ cá"
	elif breed == "tuxedo":
		desc_str = "Mèo Mun Tuxedo lanh lợi hoạt bát, chuyên quản lý Sạp Bán Hàng và tự động thu tiền về ví"
		loc_str = "Sạp Bán Hàng (nghỉ ngơi trong Nhà Junimo)"
		work_str = "🧺 Công việc: Tự bày hàng từ kho/balo ra sạp theo yêu cầu, tiếp khách & bán đồ"
		shed_str = "💰 Thu tiền: Tự động gom toàn bộ tiền bán hàng gửi thẳng vào ví của bạn"
		upgrade_str = "⭐ Nâng cấp: Nâng Tốc độ di chuyển, Tốc độ bán hàng & Sức chứa mang vác"
	else:
		desc_str = "Mèo Tam Thể thợ mỏ chăm chỉ"
		loc_str = "Hầm Mỏ (sau đó nghỉ ở Nhà Junimo)"
		work_str = "⛏️ Công việc: Khai thác khoáng sản"
		shed_str = "🏚️ Cất kho: Tự động gom khoáng sản vào Nhà Kho"
		upgrade_str = "⭐ Nâng cấp: Nâng Tốc độ & Sức chứa"

	_show_info_modal({
		"title": "🐱 %s" % cname,
		"desc": desc_str,
		"icon": TextureGen.cat_char_tex("down", 0, breed),
		"cat_node": c_node,
		"lines": [
			"💰 Tiền công: %d xu / ngày (trả tự động lúc 19:00 hoặc khi ngủ)" % wage,
			"🛖 Nơi ở & Xuất hiện: %s" % loc_str,
			work_str,
			shed_str,
			upgrade_str
		]
	})


func _on_hire_pressed() -> void:
	if cat == null:
		return
	cat.hire()
	var extra := ""
	var job_title := "làm nông"
	if cat.cat_role == "miner":
		extra = " Mèo đã bắt đầu công việc thợ mỏ tại Hầm Mỏ! ⛏️🛖"
		job_title = "đào mỏ"
	elif cat.cat_role == "fisher":
		extra = " Mèo đã bắt đầu công việc câu cá tại bờ ao! 🎣🐟🛖"
		job_title = "câu cá"
	elif cat.cat_role == "seller":
		extra = " Mèo đã bắt đầu trực sạp tại Sạp Bán Hàng! 🧺🏪💰"
		job_title = "bán hàng"
	feedback.emit("Đã thuê %s %s thành công! 🐱%s" % [cat.cat_name, job_title, extra], Color(0.65, 1.0, 0.6))
	_refresh_cat_selector()
	_show_manage_mode()


# ---------- GIAO DIỆN QUẢN LÝ MÈO ĐANG LÀM VIỆC ----------

func _build_manage_view() -> void:
	_manage_view = VBoxContainer.new()
	_manage_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_manage_view.add_theme_constant_override("separation", 10)
	_container.add_child(_manage_view)

	# Tiêu đề quản lý & nút cho mèo nghỉ việc
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	_manage_view.add_child(head)

	var back_list_btn := UIKit.styled_button(head, "« Danh sách mèo", 12, "neutral")
	back_list_btn.pressed.connect(_show_hire_mode)

	_manage_title_lbl = UIKit.title_label(head, "🐱 QUẢN LÝ MÈO LÀM NÔNG", 17, UIKit.COLOR_TEXT_TITLE)
	_manage_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var dismiss_btn := UIKit.styled_button(head, "Cho nghỉ việc", 12, "danger")
	dismiss_btn.pressed.connect(func():
		if cat != null:
			cat.dismiss()
			_show_hire_mode()
	)

	# Bảng trạng thái hoạt động của mèo
	var status_card := PanelContainer.new()
	status_card.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.15, 0.10), UIKit.COLOR_BORDER_GOLD, 6))
	var st_h := HBoxContainer.new()
	st_h.add_theme_constant_override("separation", 14)
	status_card.add_child(st_h)

	_manage_avatar_rect = TextureRect.new()
	_manage_avatar_rect.texture = TextureGen.cat_char_tex("down", 0)
	_manage_avatar_rect.custom_minimum_size = Vector2(32, 32)
	_manage_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	st_h.add_child(_manage_avatar_rect)

	var st_v := VBoxContainer.new()
	st_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label = UIKit.label(st_v, "Trạng thái: Đang nghỉ ngơi", 13, Color(0.9, 0.9, 0.8))
	_water_label = UIKit.label(st_v, "Bình nước: 15/15 💧 | Tiền công: 50 xu/ngày", 12, UIKit.COLOR_TEXT_GOLD)
	st_h.add_child(st_v)

	_manage_view.add_child(status_card)

	# Thanh chuyển Tab: [🌾 Hạt giống & Cuốc đất] [⭐ Nâng cấp Mèo]
	var tab_bar := HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 8)
	_manage_view.add_child(tab_bar)

	_tab_seeds_btn = UIKit.styled_button(tab_bar, "🌾 Hạt giống & Cuốc đất", 13, "gold")
	_tab_seeds_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_seeds_btn.pressed.connect(func(): _switch_tab(0))

	_tab_upgrades_btn = UIKit.styled_button(tab_bar, "⭐ Nâng cấp Mèo", 13, "neutral")
	_tab_upgrades_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_upgrades_btn.pressed.connect(func(): _switch_tab(1))

	# TAB 1: Giao nhận hạt giống & cuốc đất
	_tab_seeds_container = VBoxContainer.new()
	_tab_seeds_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_seeds_container.add_theme_constant_override("separation", 8)
	_manage_view.add_child(_tab_seeds_container)

	# Khung giao nhận Cuốc cày đất cho Mèo
	var hoe_card := PanelContainer.new()
	_hoe_card = hoe_card
	hoe_card.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.15, 0.10), UIKit.COLOR_BORDER_GOLD, 6))
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 6)
	hoe_card.add_child(hv)

	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 8)
	hv.add_child(hh)

	_hoe_icon_rect = TextureRect.new()
	_hoe_icon_rect.texture = TextureGen.hoe_icon()
	_hoe_icon_rect.custom_minimum_size = Vector2(24, 24)
	_hoe_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hh.add_child(_hoe_icon_rect)

	_hoe_info_label = UIKit.label(hh, "⛏️ Cuốc: Mèo giữ ×0 · Balo: ×0", 12, UIKit.COLOR_TEXT_GOLD)
	_hoe_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var h_btns := HBoxContainer.new()
	h_btns.add_theme_constant_override("separation", 6)
	hv.add_child(h_btns)

	_give_hoe_1_btn = UIKit.styled_button(h_btns, "Giao 1", 11, "gold")
	_give_hoe_1_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_give_hoe_1_btn.pressed.connect(func():
		if cat != null:
			if cat.cat_breed == "white" or str(cat.get("cat_role")) == "fisher":
				if cat.has_method("give_rods") and cat.give_rods(10):
					_refresh_manage_data()
			else:
				if cat.give_hoes(1):
					_refresh_manage_data()
	)

	_give_hoe_all_btn = UIKit.styled_button(h_btns, "Giao hết", 11, "green")
	_give_hoe_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_give_hoe_all_btn.pressed.connect(func():
		if cat != null:
			if cat.cat_breed == "white" or str(cat.get("cat_role")) == "fisher":
				if cat.has_method("give_rods") and cat.give_rods(Inventory.total_casts()):
					_refresh_manage_data()
			else:
				if cat.give_hoes(Inventory.hoes):
					_refresh_manage_data()
	)

	_take_hoe_btn = UIKit.styled_button(h_btns, "Lấy 1", 11, "neutral")
	_take_hoe_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_take_hoe_btn.pressed.connect(func():
		if cat != null:
			if cat.cat_breed == "white" or str(cat.get("cat_role")) == "fisher":
				if cat.has_method("take_back_rods") and cat.take_back_rods(10):
					_refresh_manage_data()
			else:
				if cat.take_back_hoes(1):
					_refresh_manage_data()
	)

	_take_hoe_all_btn = UIKit.styled_button(h_btns, "Lấy hết", 11, "neutral")
	_take_hoe_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_take_hoe_all_btn.pressed.connect(func():
		if cat != null:
			if cat.cat_breed == "white" or str(cat.get("cat_role")) == "fisher":
				if cat.has_method("take_back_rods") and cat.take_back_rods(-1):
					_refresh_manage_data()
			else:
				if cat.take_back_hoes(-1):
					_refresh_manage_data()
	)

	_tab_seeds_container.add_child(hoe_card)

	# Bảng giao nhận hạt giống: Balo bạn & Túi Mèo
	var right_box := PanelContainer.new()
	_right_box = right_box
	right_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.16, 0.11, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	var right_v := VBoxContainer.new()
	right_box.add_child(right_v)
	_bag_title_label = UIKit.title_label(right_v, "🎒 Giao hạt giống từ balo của bạn:", 13, Color(0.65, 0.95, 0.65))

	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.custom_minimum_size = Vector2(0, 115)
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(right_scroll)
	_seeds_in_bag_box = VBoxContainer.new()
	_seeds_in_bag_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(_seeds_in_bag_box)
	right_v.add_child(right_scroll)
	_tab_seeds_container.add_child(right_box)

	var left_box := PanelContainer.new()
	_left_box = left_box
	left_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.16, 0.11, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	var left_v := VBoxContainer.new()
	left_box.add_child(left_v)
	_cat_bag_title_label = UIKit.title_label(left_v, "🌱 Túi hạt giống Mèo đang giữ (để gieo):", 13, UIKit.COLOR_TEXT_GOLD)

	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_scroll.custom_minimum_size = Vector2(0, 95)
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(left_scroll)
	_seeds_in_cat_box = VBoxContainer.new()
	_seeds_in_cat_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(_seeds_in_cat_box)
	left_v.add_child(left_scroll)
	_tab_seeds_container.add_child(left_box)

	# Giao diện chọn hàng bán (+/-) cho Mèo Bán Hàng (Tuxedo)
	_build_seller_view(_tab_seeds_container)

	# TAB 2: Nâng cấp Mèo
	_tab_upgrades_container = VBoxContainer.new()
	_tab_upgrades_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_upgrades_container.add_theme_constant_override("separation", 8)
	_tab_upgrades_container.visible = false
	_manage_view.add_child(_tab_upgrades_container)

	_upgrade_cards_box = VBoxContainer.new()
	_upgrade_cards_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_upgrade_cards_box.add_theme_constant_override("separation", 8)
	_tab_upgrades_container.add_child(_upgrade_cards_box)


func _switch_tab(idx: int) -> void:
	_active_tab = idx
	if _tab_seeds_container != null and _tab_upgrades_container != null:
		_tab_seeds_container.visible = (_active_tab == 0)
		_tab_upgrades_container.visible = (_active_tab == 1)
	if _tab_seeds_btn != null and _tab_upgrades_btn != null:
		if _active_tab == 0:
			_tab_seeds_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.38, 0.26, 0.12), UIKit.COLOR_BORDER_GOLD, 6, 2))
			_tab_upgrades_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.24, 0.18, 0.12), UIKit.COLOR_BORDER_WOOD, 6, 1))
		else:
			_tab_seeds_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.24, 0.18, 0.12), UIKit.COLOR_BORDER_WOOD, 6, 1))
			_tab_upgrades_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.38, 0.26, 0.12), UIKit.COLOR_BORDER_GOLD, 6, 2))
	_refresh_manage_data()


func _refresh_manage_data() -> void:
	if cat == null:
		return

	if _manage_title_lbl != null:
		var cname: String = str(cat.get("cat_name")) if "cat_name" in cat else "Mèo"
		_manage_title_lbl.text = "🐱 QUẢN LÝ %s" % cname.to_upper()
	if _manage_avatar_rect != null:
		_manage_avatar_rect.texture = TextureGen.cat_char_tex("down", 0, cat.cat_breed)

	var is_miner: bool = (str(cat.get("cat_role")) == "miner")
	var is_fisher: bool = (str(cat.get("cat_role")) == "fisher")
	var is_seller: bool = (str(cat.get("cat_role")) == "seller")

	if _tab_seeds_btn != null:
		if is_seller:
			_tab_seeds_btn.text = "🏪 Chọn Hàng Bán Ra Sạp"
		elif is_fisher:
			_tab_seeds_btn.text = "🐟 Giỏ Cá Đã Câu"
		elif is_miner:
			_tab_seeds_btn.text = "💎 Túi Khoáng Sản"
		else:
			_tab_seeds_btn.text = "🌾 Hạt giống & Cuốc đất"

	if _hoe_card != null: _hoe_card.visible = not is_seller
	if _right_box != null: _right_box.visible = not is_seller
	if _left_box != null: _left_box.visible = not is_seller
	if _seller_container != null: _seller_container.visible = is_seller

	if _bag_title_label != null:
		if is_fisher:
			_bag_title_label.text = "🎒 Cần câu & Cá trong balo của bạn:"
		elif is_miner:
			_bag_title_label.text = "🎒 Khoáng sản trong balo của bạn:"
		else:
			_bag_title_label.text = "🎒 Giao hạt giống từ balo của bạn:"

	if _cat_bag_title_label != null:
		if is_fisher:
			_cat_bag_title_label.text = "🐟 Giỏ cá Mèo đang giữ:"
		elif is_miner:
			_cat_bag_title_label.text = "⛏️ Khoáng sản Mèo đang giữ:"
		else:
			_cat_bag_title_label.text = "🌱 Túi hạt giống Mèo đang giữ (để gieo):"

	# Cập nhật trạng thái chữ
	var state_str := "Đang nghỉ ngơi"
	match cat.state:
		CatHelperScript.State.ARRIVING, CatHelperScript.State.WAITING_HIRE:
			state_str = "Đang đứng chờ ở sân"
		CatHelperScript.State.WALKING_TO_MINE:
			state_str = "Đang đi lên Hầm Mỏ ⛏️"
		CatHelperScript.State.MINING:
			state_str = "Đang khai thác khoáng sản tại Hầm Mỏ ⛏️💎"
		CatHelperScript.State.WALKING_TO_JOB, CatHelperScript.State.WORKING:
			var jtype: String = str(cat.current_job.get("type", ""))
			match jtype:
				"sell": state_str = "Đang đứng bán hàng tại Sạp Chợ 🏪🧺"
				"fish": state_str = "Đang câu cá bên bờ ao 🎣🐟"
				"pest": state_str = "Đang đi bắt sâu bọ 🐛"
				"harvest": state_str = "Đang đi thu hoạch hoa màu 🌾"
				"water": state_str = "Đang tưới nước cho luống cây 💧"
				"till": state_str = "Đang đi cuốc xới đất ⛏️"
				"plant": state_str = "Đang gieo hạt giống vào đất 🌱"
				"mine": state_str = "Đang khai thác mỏ ⛏️"
				_: state_str = "Đang làm việc"
		CatHelperScript.State.WALKING_TO_POND, CatHelperScript.State.REFILLING:
			state_str = "Đang ra bờ ao múc đầy bình nước 💧"
		CatHelperScript.State.WALKING_TO_SHED, CatHelperScript.State.DEPOSITING:
			if is_fisher:
				state_str = "Đang đem cá câu được cất vào Nhà Kho 🏚️🐟"
			elif is_miner:
				state_str = "Đang đem khoáng sản cất vào Nhà Kho 🏚️⛏️"
			elif is_seller:
				state_str = "Đang vào Nhà Kho lấy hàng mang ra sạp 🏚️📦"
			else:
				state_str = "Đang đem nông sản cất vào Nhà Kho 🏚️"
		CatHelperScript.State.WALKING_TO_TENT:
			if is_fisher and int(cat.get("assigned_rods")) <= 0:
				state_str = "Chưa có cần câu! Đang đi về Nhà Junimo 🎣"
			else:
				state_str = "Đang đi về Nhà Junimo 🛖"
		CatHelperScript.State.SLEEPING:
			state_str = "Đang ngủ trong Nhà Junimo 🛖"
		CatHelperScript.State.IDLE:
			if not cat.visible:
				if is_seller:
					state_str = "Đang nghỉ trong Nhà Junimo 🛖 (Chờ có tiền thu hoặc hàng cần lấy ra sạp)"
				elif is_fisher and int(cat.get("assigned_rods")) <= 0:
					state_str = "Chờ được giao cần câu trong Nhà Junimo 🎣"
				else:
					state_str = "Đang nghỉ ngơi trong Nhà Junimo 🛖"
			else:
				if is_seller:
					state_str = "Đang chuẩn bị ra Sạp Bán Hàng 🏪"
				elif is_fisher:
					if int(cat.get("assigned_rods")) <= 0:
						state_str = "Chưa có cần câu! Hãy giao cần câu cho mèo 🎣"
					else:
						state_str = "Đang chuẩn bị ra bờ ao câu cá 🎣"
				elif is_miner:
					state_str = "Đang chuẩn bị lên mỏ ⛏️"
				else:
					state_str = "Đang rảnh rỗi chờ việc"

	_status_label.text = "Trạng thái: %s" % state_str
	if is_seller:
		_water_label.text = "🏪 Trực Sạp Chợ | Doanh số đã bán: %d xu 💰 | Lương: %d xu/ngày | Hôm nay: %s" % [
			int(cat.get("total_sales_revenue")), cat.daily_wage, "Đã trả 💰" if cat.wage_paid_today else "Chờ lúc 19:00"
		]
	elif is_fisher:
		var fish_count: int = cat._total_bag_items() if cat.has_method("_total_bag_items") else 0
		var r_count: int = int(cat.get("assigned_rods"))
		var r_str: String = "Cần câu: %d lượt 🎣" % r_count if r_count > 0 else "Cần câu: Chưa có ❌"
		_water_label.text = "%s | Giỏ cá: %d/%d 🎒 | Lương: %d xu/ngày | Hôm nay: %s" % [
			r_str, fish_count, cat.get_max_bag(), cat.daily_wage, "Đã trả 💰" if cat.wage_paid_today else "Chờ lúc 19:00"
		]
	elif is_miner:
		var ore_count: int = cat._total_bag_items() if cat.has_method("_total_bag_items") else 0
		_water_label.text = "Túi khoáng sản: %d/%d 🎒 | Lương: %d xu/ngày | Hôm nay: %s" % [
			ore_count, cat.get_max_bag(), cat.daily_wage, "Đã trả 💰" if cat.wage_paid_today else "Chờ lúc 19:00"
		]
	else:
		_water_label.text = "Bình nước: %d/%d 💧 | Lương: %d xu/ngày | Hôm nay: %s" % [
			cat.water_level, cat.water_capacity, cat.daily_wage, "Đã trả 💰" if cat.wage_paid_today else "Chờ lúc 19:00"
		]

	if is_seller:
		_refresh_seller_items()

	# Cập nhật thông tin Cuốc cày / Cần câu
	if _hoe_info_label != null:
		if is_fisher:
			var cat_r: int = int(cat.get("assigned_rods"))
			var bag_r: int = Inventory.total_casts()
			if _hoe_icon_rect != null:
				_hoe_icon_rect.texture = TextureGen.get_tex("sdv_rod")
			_hoe_info_label.text = "🎣 Cần câu: Mèo giữ ×%d lượt · Balo: ×%d lượt" % [cat_r, bag_r]
			if _give_hoe_1_btn != null:
				_give_hoe_1_btn.text = "Giao 1 cần"
				_give_hoe_1_btn.disabled = (bag_r <= 0)
			if _give_hoe_all_btn != null:
				_give_hoe_all_btn.text = "Giao hết"
				_give_hoe_all_btn.disabled = (bag_r <= 0)
			if _take_hoe_btn != null:
				_take_hoe_btn.text = "Lấy 1 cần"
				_take_hoe_btn.disabled = (cat_r <= 0)
			if _take_hoe_all_btn != null:
				_take_hoe_all_btn.text = "Lấy hết"
				_take_hoe_all_btn.disabled = (cat_r <= 0)
		elif is_miner:
			if _hoe_icon_rect != null:
				_hoe_icon_rect.texture = TextureGen.hoe_icon()
			_hoe_info_label.text = "⛏️ Nghề Thợ Mỏ: Tự động khai thác đá, than & quặng quý mang về Nhà Kho"
			if _give_hoe_1_btn != null:
				_give_hoe_1_btn.text = "Giao 1"
				_give_hoe_1_btn.disabled = true
			if _give_hoe_all_btn != null:
				_give_hoe_all_btn.text = "Giao hết"
				_give_hoe_all_btn.disabled = true
			if _take_hoe_btn != null:
				_take_hoe_btn.text = "Lấy 1"
				_take_hoe_btn.disabled = true
			if _take_hoe_all_btn != null:
				_take_hoe_all_btn.text = "Lấy hết"
				_take_hoe_all_btn.disabled = true
		else:
			var cat_h: int = int(cat.assigned_hoes)
			var bag_h: int = int(Inventory.hoes)
			if _hoe_icon_rect != null:
				_hoe_icon_rect.texture = TextureGen.hoe_icon()
			_hoe_info_label.text = "⛏️ Cuốc: Mèo giữ ×%d cuốc · Balo: ×%d cuốc" % [cat_h, bag_h]
			if _give_hoe_1_btn != null:
				_give_hoe_1_btn.text = "Giao 1"
				_give_hoe_1_btn.disabled = (bag_h <= 0)
			if _give_hoe_all_btn != null:
				_give_hoe_all_btn.text = "Giao hết"
				_give_hoe_all_btn.disabled = (bag_h <= 0)
			if _take_hoe_btn != null:
				_take_hoe_btn.text = "Lấy 1"
				_take_hoe_btn.disabled = (cat_h <= 0)
			if _take_hoe_all_btn != null:
				_take_hoe_all_btn.text = "Lấy hết"
				_take_hoe_all_btn.disabled = (cat_h <= 0)

	# Cập nhật danh sách vật phẩm Mèo đang giữ
	for child in _seeds_in_cat_box.get_children():
		_seeds_in_cat_box.remove_child(child)
		child.queue_free()

	if is_fisher:
		if cat.harvest_bag.is_empty():
			var empty_txt := "(Mèo chưa có cần câu. Hãy giao cần câu bên trên để mèo đi câu)" if int(cat.get("assigned_rods")) <= 0 else "(Giỏ cá trống. Mèo đang câu cá bên bờ ao — còn %d lượt)" % int(cat.get("assigned_rods"))
			var empty_lbl := UIKit.label(_seeds_in_cat_box, empty_txt, 11, Color(0.6, 0.55, 0.5))
			empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			var FishDB = load("res://scripts/fish_db.gd")
			for fid in cat.harvest_bag:
				var count: int = int(cat.harvest_bag[fid])
				if count <= 0:
					continue
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 6)
				var ic := TextureRect.new()
				var fdata: Dictionary = FishDB.get_fish(fid)
				var color_hex: String = str(fdata.get("color", "8d9b6a"))
				ic.texture = TextureGen.fish_icon(color_hex)
				ic.custom_minimum_size = Vector2(20, 20)
				ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
				row.add_child(ic)

				var fname: String = str(fdata.get("name", fid))
				var lbl := UIKit.label(row, "%s: ×%d" % [fname, count], 12, Color(0.9, 0.9, 0.8))
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

				var send_shed_btn := UIKit.styled_button(row, "Cất kho", 11, "neutral")
				send_shed_btn.pressed.connect(func():
					Inventory.direct_store("fish", str(fid), count)
					cat.harvest_bag.erase(fid)
					_refresh_manage_data()
				)
				_seeds_in_cat_box.add_child(row)
	elif is_miner:
		if cat.harvest_bag.is_empty():
			var empty_lbl := UIKit.label(_seeds_in_cat_box, "(Túi khoáng sản trống. Mèo đang chăm chỉ đào mỏ)", 11, Color(0.6, 0.55, 0.5))
			empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			for oid in cat.harvest_bag:
				var count: int = int(cat.harvest_bag[oid])
				if count <= 0:
					continue
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 6)
				var ic := TextureRect.new()
				ic.texture = TextureGen.ore_item_icon(oid)
				ic.custom_minimum_size = Vector2(20, 20)
				ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
				row.add_child(ic)

				var oname: String = cat._get_ore_display_name(oid) if cat.has_method("_get_ore_display_name") else oid
				var lbl := UIKit.label(row, "%s: ×%d" % [oname, count], 12, Color(0.9, 0.9, 0.8))
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

				var send_shed_btn := UIKit.styled_button(row, "Cất kho", 11, "neutral")
				send_shed_btn.pressed.connect(func():
					Inventory.direct_store("ores", str(oid), count)
					cat.harvest_bag.erase(oid)
					_refresh_manage_data()
				)
				_seeds_in_cat_box.add_child(row)
	else:
		if cat.assigned_seeds.is_empty():
			var empty_lbl := UIKit.label(_seeds_in_cat_box, "(Chưa có hạt giống nào. Hãy giao hạt bên trên để Mèo tự gieo)", 11, Color(0.6, 0.55, 0.5))
			empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			for sid in cat.assigned_seeds:
				var count: int = int(cat.assigned_seeds[sid])
				if count <= 0:
					continue
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 6)
				var ic := TextureRect.new()
				ic.texture = TextureGen.seed_bag_tex(sid)
				ic.custom_minimum_size = Vector2(20, 20)
				ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
				row.add_child(ic)

				var cdata := CropDB.get_crop(sid)
				var cname := str(cdata.get("name", sid))
				var lbl := UIKit.label(row, "%s: ×%d" % [cname, count], 12, Color(0.9, 0.9, 0.8))
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

				var take_btn := UIKit.styled_button(row, "Lấy lại", 11, "neutral")
				take_btn.pressed.connect(func():
					cat.take_back_seeds(sid, 5)
					_refresh_manage_data()
				)
				_seeds_in_cat_box.add_child(row)

	# Cập nhật danh sách trong balo người chơi
	for child in _seeds_in_bag_box.get_children():
		_seeds_in_bag_box.remove_child(child)
		child.queue_free()

	if is_fisher:
		var FishDB = load("res://scripts/fish_db.gd")
		var has_any := false

		# 1. Liệt kê các loại cần câu trong balo để người chơi tiện giao cho mèo
		for tier in ["basic", "mid", "high"]:
			var casts: int = int(Inventory.rods.get(tier, 0))
			if casts <= 0:
				continue
			has_any = true
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var ic := TextureRect.new()
			ic.texture = TextureGen.get_tex("sdv_rod")
			ic.custom_minimum_size = Vector2(20, 20)
			ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			row.add_child(ic)

			var tier_name := "Cần Tre" if tier == "basic" else ("Cần Sợi Thủy Tinh" if tier == "mid" else "Cần Iridium")
			var lbl := UIKit.label(row, "%s: %d lượt câu" % [tier_name, casts], 12, Color(0.4, 0.85, 1.0))
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var give_btn := UIKit.styled_button(row, "Giao cần", 11, "gold")
			give_btn.pressed.connect(func():
				cat.give_rods(casts)
				_refresh_manage_data()
			)
			_seeds_in_bag_box.add_child(row)

		# 2. Liệt kê cá đang có trong balo
		var owned_fish := Inventory.fish
		for fid in owned_fish:
			var count: int = int(owned_fish[fid])
			if count <= 0:
				continue
			has_any = true
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var ic := TextureRect.new()
			var fdata: Dictionary = FishDB.get_fish(fid)
			var color_hex: String = str(fdata.get("color", "8d9b6a"))
			ic.texture = TextureGen.fish_icon(color_hex)
			ic.custom_minimum_size = Vector2(20, 20)
			ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			row.add_child(ic)

			var fname: String = str(fdata.get("name", fid))
			var lbl := UIKit.label(row, "%s trong balo: ×%d" % [fname, count], 12, Color(0.9, 0.9, 0.8))
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_seeds_in_bag_box.add_child(row)

		if not has_any:
			var empty_lbl := UIKit.label(_seeds_in_bag_box, "(Balo không có cần câu hay cá. Hãy mua cần ở Bến Cá Chú Hai)", 11, Color(0.6, 0.55, 0.5))
			empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	elif is_miner:
		var owned_ores := Inventory.ores
		var has_any_ore := false
		for oid in owned_ores:
			var count: int = int(owned_ores[oid])
			if count <= 0:
				continue
			has_any_ore = true
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var ic := TextureRect.new()
			ic.texture = TextureGen.ore_item_icon(oid)
			ic.custom_minimum_size = Vector2(20, 20)
			ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			row.add_child(ic)

			var oname: String = cat._get_ore_display_name(oid) if cat.has_method("_get_ore_display_name") else oid
			var lbl := UIKit.label(row, "%s trong balo: ×%d" % [oname, count], 12, Color(0.9, 0.9, 0.8))
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_seeds_in_bag_box.add_child(row)

		if not has_any_ore:
			var empty_lbl := UIKit.label(_seeds_in_bag_box, "(Balo của bạn chưa có khoáng sản nào)", 11, Color(0.6, 0.55, 0.5))
			empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		var owned_seeds := Inventory.seeds
		var has_any := false
		for sid in owned_seeds:
			var count: int = int(owned_seeds[sid])
			if count <= 0:
				continue
			has_any = true
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var ic := TextureRect.new()
			ic.texture = TextureGen.seed_bag_tex(sid)
			ic.custom_minimum_size = Vector2(20, 20)
			ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			row.add_child(ic)

			var cdata := CropDB.get_crop(sid)
			var cname := str(cdata.get("name", sid))
			var lbl := UIKit.label(row, "%s: ×%d" % [cname, count], 12, Color(0.9, 0.9, 0.8))
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var give5_btn := UIKit.styled_button(row, "Giao 5", 11, "gold")
			give5_btn.pressed.connect(func():
				cat.give_seeds(sid, mini(5, count))
				_refresh_manage_data()
			)

			var give_all_btn := UIKit.styled_button(row, "Giao hết", 11, "green")
			give_all_btn.pressed.connect(func():
				cat.give_seeds(sid, count)
				_refresh_manage_data()
			)

			_seeds_in_bag_box.add_child(row)

		if not has_any:
			var empty_lbl := UIKit.label(_seeds_in_bag_box, "(Balo của bạn không có hạt giống nào để giao)", 11, Color(0.6, 0.55, 0.5))
			empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Cập nhật giao diện Nâng cấp
	_update_wallet_label()

	if _upgrade_cards_box != null:
		for c in _upgrade_cards_box.get_children():
			_upgrade_cards_box.remove_child(c)
			c.queue_free()

		# 1. Thẻ Tốc độ di chuyển
		var next_spd_str: String = "%.0f px/s" % float(cat.get_speed_for_level(cat.speed_level + 1))
		var spd_desc := "Vận tốc mèo đi lại giữa Sạp Hàng, Nhà Kho và Nhà Junimo" if is_seller else ("Vận tốc mèo đi lại giữa Bờ ao, Nhà Kho và Nhà Junimo" if is_fisher else ("Vận tốc mèo đi lại giữa Hầm Mỏ, Nhà Kho và Lều" if is_miner else "Vận tốc mèo đi lại trên ruộng"))
		_build_upgrade_card(_upgrade_cards_box, "speed", "⚡ Tốc độ di chuyển",
			spd_desc,
			cat.speed_level, "%.0f px/s" % float(cat.speed),
			next_spd_str
		)

		# 2. Thẻ Năng suất & Giờ làm việc
		var sleep_hr: int = int(float(cat.get_sleep_clock()) / 60.0)
		var next_sleep_hr: int = int(float(cat.get_sleep_clock_for_level(cat.work_level + 1)) / 60.0)
		if is_seller:
			_build_upgrade_card(_upgrade_cards_box, "work", "⏱️ Năng suất Bán hàng & Giờ làm",
				"Bán hàng nhanh nhẹn, tiếp khách chu đáo · Tan ca %02d:00 tối" % sleep_hr,
				cat.work_level, "Bán hàng nhanh · Đến %02d:00" % sleep_hr,
				"Bán nhanh hơn, phục vụ nhiều khách hơn, làm việc đến %02d:00 đêm" % next_sleep_hr
			)
		elif is_fisher:
			var cur_rod: String = cat.get_rod_name(cat.work_level) if cat.has_method("get_rod_name") else "Cần sơ cấp"
			var cur_fail: int = int((cat.get_rod_fail_rate(cat.work_level) if cat.has_method("get_rod_fail_rate") else 0.35) * 100)
			var cur_dur: float = cat.get_fishing_cycle_duration() if cat.has_method("get_fishing_cycle_duration") else 3.2
			var next_rod: String = cat.get_rod_name(cat.work_level + 1) if cat.has_method("get_rod_name") else "Cần tốt hơn"
			var next_fail: int = int((cat.get_rod_fail_rate(cat.work_level + 1) if cat.has_method("get_rod_fail_rate") else 0.0) * 100)
			_build_upgrade_card(_upgrade_cards_box, "work", "🎣 Nâng cấp Cần câu & Giờ làm",
				"%s (Hụt cá: %d%% · %.1fs/lần) · Tan ca %02d:00" % [cur_rod, cur_fail, cur_dur, sleep_hr],
				cat.work_level, "%s (Hụt: %d%%)" % [cur_rod, cur_fail],
				"Lên %s (Hụt còn %d%%), câu cá quý hơn, làm việc đến %02d:00" % [next_rod, next_fail, next_sleep_hr]
			)
		elif is_miner:
			var mine_speed: float = float(cat.get_mining_cycle_duration()) if cat.has_method("get_mining_cycle_duration") else 1.0
			_build_upgrade_card(_upgrade_cards_box, "work", "⏱️ Năng suất Khai mỏ & Giờ làm",
				"Đào mỏ %.2fs/lần · Mở khóa quặng quý hơn · Tan ca %02d:00 tối" % [mine_speed, sleep_hr],
				cat.work_level, "Đào %.2fs · Đến %02d:00" % [mine_speed, sleep_hr],
				"Đào nhanh hơn, mở quặng hiếm, làm việc đến %02d:00 đêm" % next_sleep_hr
			)
		else:
			_build_upgrade_card(_upgrade_cards_box, "work", "⏱️ Năng suất & Giờ làm việc",
				"Thao tác %.2fs/việc · Tan ca %02d:00 tối" % [float(cat.get_work_duration()), sleep_hr],
				cat.work_level, "Thao tác %.2fs · Đến %02d:00" % [float(cat.get_work_duration()), sleep_hr],
				"Làm việc chăm chỉ đến %02d:00 đêm" % next_sleep_hr
			)

		# 3. Thẻ Sức chứa Túi đồ
		var next_bag: int = int(cat.get_max_bag_for_level(cat.bag_level + 1))
		if is_seller:
			var cur_limit: int = int(cat.get_stall_slot_limit())
			var next_limit: int = int(cat.get_stall_slot_limit_for_level(cat.bag_level + 1))
			_build_upgrade_card(_upgrade_cards_box, "bag", "🎒 Giới Hạn Ô Kệ Sạp & Vận Chuyển",
				"Xếp tối đa %d món/ô sạp hàng (Lấy từ kho ra)" % cur_limit,
				cat.bag_level, "%d món/ô sạp" % cur_limit,
				"Tăng lên tối đa %d món/ô sạp hàng" % next_limit
			)
		elif is_fisher:
			_build_upgrade_card(_upgrade_cards_box, "bag", "🎒 Sức chứa Giỏ cá",
				"Giỏ gom: %d con cá mỗi chuyến cất vào Nhà Kho" % int(cat.get_max_bag()),
				cat.bag_level, "Giỏ %d con cá" % int(cat.get_max_bag()),
				"Giỏ chứa tối đa %d con cá" % next_bag
			)
		elif is_miner:
			_build_upgrade_card(_upgrade_cards_box, "bag", "🎒 Sức chứa Túi khoáng sản",
				"Túi gom: %d khoáng sản mỗi chuyến chở về Nhà Kho" % int(cat.get_max_bag()),
				cat.bag_level, "Túi %d khoáng sản" % int(cat.get_max_bag()),
				"Túi chứa tối đa %d khoáng sản" % next_bag
			)
		else:
			var next_water: int = int(cat.get_water_capacity_for_level(cat.bag_level + 1))
			_build_upgrade_card(_upgrade_cards_box, "bag", "🎒 Sức chứa Túi đồ & Bình nước",
				"Túi gom: %d món · Bình nước: %d giọt" % [int(cat.get_max_bag()), int(cat.water_capacity)],
				cat.bag_level, "Túi %d món · Bình %d giọt" % [int(cat.get_max_bag()), int(cat.water_capacity)],
				"Túi %d món · Bình nước %d giọt" % [next_bag, next_water]
			)


func _build_upgrade_card(parent: Control, type: String, title: String, desc: String, cur_lvl: int, cur_stat: String, next_stat: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.18, 0.13, 0.08), UIKit.COLOR_BORDER_WOOD, 6))
	parent.add_child(card)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	card.add_child(h)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)

	var title_txt := "%s  (Cấp %d/%d)" % [title, cur_lvl, CatHelperScript.MAX_UPGRADE_LEVEL]
	UIKit.label(v, title_txt, 13, UIKit.COLOR_TEXT_GOLD)
	UIKit.label(v, "%s  [Hiện tại: %s]" % [desc, cur_stat], 11, Color(0.85, 0.85, 0.80))
	if cur_lvl < CatHelperScript.MAX_UPGRADE_LEVEL:
		UIKit.label(v, "➜ Cấp kế tiếp: %s" % next_stat, 11, Color(0.55, 0.95, 0.55))
	else:
		UIKit.label(v, "⭐ Đã đạt mức tối đa! Mèo đã thuần thục kỹ năng này.", 11, Color(1.0, 0.85, 0.35))

	var is_max: bool = (cur_lvl >= CatHelperScript.MAX_UPGRADE_LEVEL)
	var cost: int = cat.get_upgrade_cost(type, cur_lvl)

	if is_max:
		var max_btn := UIKit.styled_button(h, "⭐ Tối đa", 12, "neutral")
		max_btn.disabled = true
	else:
		var can_afford: bool = (GameState.money >= cost) if has_node("/root/GameState") else true
		var btn_style_type := "gold" if can_afford else "neutral"
		var up_btn := UIKit.styled_button(h, "Nâng cấp (%d xu)" % cost, 12, btn_style_type)
		up_btn.pressed.connect(func():
			if has_node("/root/GameState") and GameState.money < cost:
				feedback.emit("Không đủ tiền! Bạn cần %d xu để nâng cấp kỹ năng này." % cost, Color(1.0, 0.5, 0.4))
				return
			if cat.upgrade(type):
				_refresh_manage_data()
		)


# ---------------- Hộp Thoại Chi Tiết Modal (Phong Cách Cửa Hàng) ----------------

func _create_info_circle_button(callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = "i"
	btn.custom_minimum_size = Vector2(22, 22)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.32, 0.22, 0.14), UIKit.COLOR_BORDER_GOLD, 11, 1))
	btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.44, 0.30, 0.18), UIKit.COLOR_BORDER_BRIGHT, 11, 1))
	btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(callback)
	return btn


func _build_info_modal(root: Control) -> void:
	_modal_root = Control.new()
	_modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_root.visible = false
	root.add_child(_modal_root)

	var modal_dim := ColorRect.new()
	modal_dim.color = Color(0, 0, 0, 0.60)
	modal_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_hide_info_modal()
	)
	_modal_root.add_child(modal_dim)

	var modal_center := CenterContainer.new()
	modal_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_root.add_child(modal_center)

	var modal_card := PanelContainer.new()
	modal_card.custom_minimum_size = Vector2(360, 0)
	modal_card.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 2, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	modal_center.add_child(modal_card)

	var card_v := VBoxContainer.new()
	card_v.add_theme_constant_override("separation", 10)
	modal_card.add_child(card_v)

	var top_box := PanelContainer.new()
	top_box.add_theme_stylebox_override("panel", UIKit.modal_top_box())
	card_v.add_child(top_box)

	var top_v := VBoxContainer.new()
	top_v.alignment = BoxContainer.ALIGNMENT_CENTER
	top_v.add_theme_constant_override("separation", 6)
	top_box.add_child(top_v)

	_modal_icon = TextureRect.new()
	_modal_icon.custom_minimum_size = Vector2(56, 56)
	_modal_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	top_v.add_child(_modal_icon)

	_modal_title = Label.new()
	_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_title.add_theme_font_size_override("font_size", 18)
	_modal_title.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
	_modal_title.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.03, 0.98))
	_modal_title.add_theme_constant_override("outline_size", 3)
	top_v.add_child(_modal_title)

	_modal_desc_label = Label.new()
	_modal_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_desc_label.add_theme_font_size_override("font_size", 12)
	_modal_desc_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)
	top_v.add_child(_modal_desc_label)

	var banner_box := PanelContainer.new()
	banner_box.add_theme_stylebox_override("panel", UIKit.modal_banner_box())
	card_v.add_child(banner_box)

	var banner_v := VBoxContainer.new()
	banner_v.add_theme_constant_override("separation", 8)
	banner_box.add_child(banner_v)

	_modal_lines_v = VBoxContainer.new()
	_modal_lines_v.add_theme_constant_override("separation", 4)
	banner_v.add_child(_modal_lines_v)

	var sep := ColorRect.new()
	sep.color = Color(0.86, 0.70, 0.32, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	banner_v.add_child(sep)

	_modal_action_h = HBoxContainer.new()
	_modal_action_h.add_theme_constant_override("separation", 8)
	banner_v.add_child(_modal_action_h)


func _show_info_modal(data: Dictionary) -> void:
	_current_modal_data = data
	_modal_icon.texture = data.get("icon", null)
	_modal_title.text = str(data.get("title", ""))
	_modal_desc_label.text = str(data.get("desc", ""))

	for c in _modal_lines_v.get_children():
		c.queue_free()

	for line in data.get("lines", []):
		var lbl := Label.new()
		lbl.text = str(line)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
		lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
		lbl.add_theme_constant_override("outline_size", 2)
		_modal_lines_v.add_child(lbl)

	for c in _modal_action_h.get_children():
		c.queue_free()

	var target_c: Node2D = data.get("cat_node", null)
	if target_c != null and not target_c.is_hired:
		var hire_btn := Button.new()
		hire_btn.text = "🤝 Thuê (%d xu/ngày)" % target_c.daily_wage
		hire_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hire_btn.custom_minimum_size = Vector2(0, 36)
		hire_btn.add_theme_font_size_override("font_size", 13)
		hire_btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.55, 0.85, 0.45), 8, 2))
		hire_btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.65, 0.95, 0.55), 8, 2))
		hire_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
		hire_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		hire_btn.pressed.connect(func():
			_hide_info_modal()
			cat = target_c
			_on_hire_pressed()
		)
		_modal_action_h.add_child(hire_btn)
	elif target_c != null and target_c.is_hired:
		var manage_btn := Button.new()
		manage_btn.text = "⚙️ Quản Lý Việc"
		manage_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		manage_btn.custom_minimum_size = Vector2(0, 36)
		manage_btn.add_theme_font_size_override("font_size", 13)
		manage_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.38, 0.26, 0.12), UIKit.COLOR_BORDER_GOLD, 8, 2))
		manage_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GOLD)
		manage_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		manage_btn.pressed.connect(func():
			_hide_info_modal()
			cat = target_c
			_show_manage_mode()
		)
		_modal_action_h.add_child(manage_btn)

	var close_btn := Button.new()
	close_btn.text = "✕ Đóng"
	close_btn.custom_minimum_size = Vector2(80, 36)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_CLOSE_BG, UIKit.COLOR_BORDER_GOLD, 8, 1))
	close_btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_CLOSE_HOVER, UIKit.COLOR_BORDER_BRIGHT, 8, 1))
	close_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(_hide_info_modal)
	_modal_action_h.add_child(close_btn)

	_modal_root.visible = true


func _hide_info_modal() -> void:
	if _modal_root != null:
		_modal_root.visible = false


# ==============================================================================
# GIAO DIỆN QUẢN LÝ BÁN HÀNG TỰ ĐỘNG CHO MÈO MUN TUXEDO (STALL SELLER UI)
# ==============================================================================

var _seller_show_all_catalog: bool = false

func _build_seller_view(parent: Control) -> void:
	_seller_container = VBoxContainer.new()
	_seller_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_seller_container.add_theme_constant_override("separation", 8)
	_seller_container.visible = false
	parent.add_child(_seller_container)

	# 1. Thẻ tổng quan Sạp Hàng & Doanh Thu Chờ Thu
	var stall_card := PanelContainer.new()
	stall_card.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.15, 0.10), UIKit.COLOR_BORDER_GOLD, 6))
	var sc_h := HBoxContainer.new()
	sc_h.add_theme_constant_override("separation", 10)
	stall_card.add_child(sc_h)

	var s_icon := TextureRect.new()
	s_icon.texture = TextureGen.coin_icon()
	s_icon.custom_minimum_size = Vector2(28, 28)
	s_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	sc_h.add_child(s_icon)

	var sc_v := VBoxContainer.new()
	sc_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc_v.add_theme_constant_override("separation", 2)
	sc_h.add_child(sc_v)

	_seller_stall_label = UIKit.label(sc_v, "🏪 Sạp hàng: 0/6 ô đang bày bán", 12, UIKit.COLOR_TEXT_GOLD)
	_seller_revenue_label = UIKit.label(sc_v, "💰 Tiền chờ thu: 0 xu (Mèo tự thu vào ví)", 11, Color(0.70, 0.95, 0.65))

	var btn_v := HBoxContainer.new()
	btn_v.add_theme_constant_override("separation", 6)
	sc_h.add_child(btn_v)

	_seller_collect_btn = UIKit.styled_button(btn_v, "Thu tiền", 11, "buy")
	_seller_collect_btn.custom_minimum_size = Vector2(75, 30)
	_seller_collect_btn.pressed.connect(func():
		if cat != null and cat.has_method("_process_stall_work"):
			cat._process_stall_work()
			_refresh_manage_data()
	)

	_seller_open_stall_btn = UIKit.styled_button(btn_v, "Mở sạp", 11, "gold")
	_seller_open_stall_btn.custom_minimum_size = Vector2(65, 30)
	_seller_open_stall_btn.pressed.connect(func():
		var sm = cat._get_stall_manager() if cat != null and cat.has_method("_get_stall_manager") else null
		if sm != null and sm.has_method("open_market_stall"):
			close()
			sm.open_market_stall()
	)
	_seller_container.add_child(stall_card)

	# 2. Thanh lọc danh mục: [Tất cả] [🌾 Nông sản] [🐟 Cá tươi] [🥩 Gia súc] [⛏️ Quặng]
	var filter_bar := HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 6)
	_seller_container.add_child(filter_bar)

	_seller_filter_buttons = {}
	var filters := [
		{"key": "all", "label": "Tất cả"},
		{"key": "crop", "label": "🌾 Nông sản"},
		{"key": "fish", "label": "🐟 Cá tươi"},
		{"key": "poultry", "label": "🥩 Gia súc"},
		{"key": "ore", "label": "⛏️ Quặng"}
	]
	for f in filters:
		var f_key: String = str(f.key)
		var f_btn := UIKit.styled_button(filter_bar, str(f.label), 11, "gold" if _seller_filter == f_key else "neutral")
		f_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f_btn.pressed.connect(func():
			_seller_filter = f_key
			_update_seller_filter_styles()
			_refresh_seller_items()
		)
		_seller_filter_buttons[f_key] = f_btn

	# 3. Khung danh sách các mặt hàng hỗ trợ thiết lập số lượng +/-
	var items_panel := PanelContainer.new()
	items_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_panel.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.16, 0.11, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	_seller_container.add_child(items_panel)

	var ipv := VBoxContainer.new()
	ipv.add_theme_constant_override("separation", 6)
	items_panel.add_child(ipv)

	var sub_head := HBoxContainer.new()
	ipv.add_child(sub_head)
	UIKit.title_label(sub_head, "📦 Thiết lập số lượng mang ra sạp (+/-):", 12, Color(0.65, 0.95, 0.65)).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var cat_toggle_btn := UIKit.styled_button(sub_head, "Hiện tất cả mặt hàng", 10, "neutral")
	cat_toggle_btn.pressed.connect(func():
		_seller_show_all_catalog = not _seller_show_all_catalog
		cat_toggle_btn.text = "Chỉ hiện hàng có sẵn" if _seller_show_all_catalog else "Hiện tất cả mặt hàng"
		_refresh_seller_items()
	)

	var items_scroll := ScrollContainer.new()
	items_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_scroll.custom_minimum_size = Vector2(0, 180)
	items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(items_scroll)
	ipv.add_child(items_scroll)

	_seller_items_box = VBoxContainer.new()
	_seller_items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seller_items_box.add_theme_constant_override("separation", 4)
	items_scroll.add_child(_seller_items_box)

	# 4. Thanh tóm tắt & thao tác nhanh
	var bottom_h := HBoxContainer.new()
	bottom_h.add_theme_constant_override("separation", 8)
	_seller_container.add_child(bottom_h)

	_seller_summary_label = UIKit.label(bottom_h, "Đã chọn bán: 0 món", 11, UIKit.COLOR_TEXT_GOLD)
	_seller_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var restock_now_btn := UIKit.styled_button(bottom_h, "Bày ra sạp ngay 🧺", 11, "green")
	restock_now_btn.pressed.connect(func():
		if cat != null and cat.has_method("_process_stall_work"):
			cat._process_stall_work()
			_refresh_manage_data()
			feedback.emit("Mèo Mun đã kiểm tra và bày hàng lên sạp! 🧺🏪", Color(0.6, 1.0, 0.6))
	)

	var clear_btn := UIKit.styled_button(bottom_h, "Bỏ chọn tất cả ✕", 11, "danger")
	clear_btn.pressed.connect(func():
		if cat != null and cat.has_method("clear_all_sell_targets"):
			cat.clear_all_sell_targets()
			_refresh_manage_data()
	)


func _update_seller_filter_styles() -> void:
	for f_key in _seller_filter_buttons:
		var btn: Button = _seller_filter_buttons[f_key]
		if is_instance_valid(btn):
			if f_key == _seller_filter:
				btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.38, 0.26, 0.12), UIKit.COLOR_BORDER_GOLD, 6, 2))
			else:
				btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.24, 0.18, 0.12), UIKit.COLOR_BORDER_WOOD, 6, 1))


func _refresh_seller_items() -> void:
	if cat == null or _seller_items_box == null:
		return
	for c in _seller_items_box.get_children():
		_seller_items_box.remove_child(c)
		c.queue_free()

	var sm = cat._get_stall_manager() if cat.has_method("_get_stall_manager") else null
	var rev: int = int(sm.stall_revenue) if sm != null else 0
	var occupied_slots: int = 0
	if sm != null and "stall_slots" in sm:
		for s in sm.stall_slots:
			if typeof(s) == TYPE_DICTIONARY and not s.is_empty() and int(s.get("count", 0)) > 0:
				occupied_slots += 1

	if _seller_stall_label != null:
		_seller_stall_label.text = "🏪 Sạp hàng: %d/6 ô đang bày bán" % occupied_slots
	if _seller_revenue_label != null:
		_seller_revenue_label.text = "💰 Tiền chờ thu: %d xu (Mèo tự thu vào ví)" % rev
	if _seller_collect_btn != null:
		_seller_collect_btn.disabled = (rev <= 0)
		_seller_collect_btn.text = "Thu %d xu 💰" % rev if rev > 0 else "Chưa có tiền"

	var FishDB = load("res://scripts/fish_db.gd")
	var PoultryDB = load("res://scripts/poultry_db.gd")
	var OreDB = load("res://scripts/ore_db.gd")

	var items_to_show: Array[Dictionary] = []

	# 1. Nông sản (crops)
	if _seller_filter == "all" or _seller_filter == "crop":
		for c in CropDB.CROPS:
			var cid: String = str(c.id)
			var avail: int = Inventory.total_item_available("produce", cid)
			var target: int = cat.get_sell_target(cid)
			if _seller_show_all_catalog or avail > 0 or target > 0:
				var in_storage := Inventory.storage_count("produce", cid)
				var in_bag := Inventory.produce_count(cid)
				var bp: int = int(c.get("sell_price", 10))
				var stall_price := maxi(1, int(round(float(bp) * 1.2)))
				items_to_show.append({
					"id": cid,
					"type": "crop",
					"name": str(c.name),
					"price": stall_price,
					"avail": avail,
					"in_storage": in_storage,
					"in_bag": in_bag,
					"target": target
				})

	# 2. Cá tươi (fish)
	if _seller_filter == "all" or _seller_filter == "fish":
		for f in FishDB.FISH:
			var fid: String = str(f.id)
			var avail: int = Inventory.total_item_available("fish", fid)
			var target: int = cat.get_sell_target(fid)
			if _seller_show_all_catalog or avail > 0 or target > 0:
				var in_storage := Inventory.storage_count("fish", fid)
				var in_bag := Inventory.fish_count(fid)
				var bp: int = int(f.get("price", 10))
				var stall_price := maxi(1, int(round(float(bp) * 1.2)))
				items_to_show.append({
					"id": fid,
					"type": "fish",
					"name": str(f.name),
					"price": stall_price,
					"avail": avail,
					"in_storage": in_storage,
					"in_bag": in_bag,
					"target": target
				})

	# 3. Sản phẩm chăn nuôi (poultry)
	if _seller_filter == "all" or _seller_filter == "poultry":
		for p in PoultryDB.PRODUCTS:
			var pid: String = str(p.id)
			var avail: int = Inventory.total_item_available("poultry", pid)
			var target: int = cat.get_sell_target(pid)
			if _seller_show_all_catalog or avail > 0 or target > 0:
				var in_storage := Inventory.storage_count("produce", pid)
				var in_bag := Inventory.produce_count(pid)
				var bp: int = int(p.get("price", 10))
				var stall_price := maxi(1, int(round(float(bp) * 1.2)))
				items_to_show.append({
					"id": pid,
					"type": "poultry",
					"name": str(p.name),
					"price": stall_price,
					"avail": avail,
					"in_storage": in_storage,
					"in_bag": in_bag,
					"target": target
				})

	# 4. Khoáng sản (ores)
	if _seller_filter == "all" or _seller_filter == "ore":
		for o in OreDB.ORES:
			var oid: String = str(o.id)
			var avail: int = Inventory.total_item_available("ores", oid)
			var target: int = cat.get_sell_target(oid)
			if _seller_show_all_catalog or avail > 0 or target > 0:
				var in_storage := Inventory.storage_count("ores", oid)
				var in_bag := Inventory.ore_count(oid)
				var bp: int = int(o.get("price", 10))
				var stall_price := maxi(1, int(round(float(bp) * 1.2)))
				items_to_show.append({
					"id": oid,
					"type": "ore",
					"name": str(o.name),
					"price": stall_price,
					"avail": avail,
					"in_storage": in_storage,
					"in_bag": in_bag,
					"target": target
				})

	if items_to_show.is_empty():
		var empty_box := PanelContainer.new()
		empty_box.add_theme_stylebox_override("panel", UIKit.row_locked_box())
		var l := UIKit.label(empty_box, "(Hiện chưa có mặt hàng nào sẵn trong kho hoặc balo để bán. Hãy nhấn nút 'Hiện tất cả mặt hàng' ở trên để lên lịch trước, hoặc thu hoạch thêm!)", 11, UIKit.COLOR_TEXT_MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_seller_items_box.add_child(empty_box)
	else:
		for item in items_to_show:
			var row := _build_seller_item_row(item)
			_seller_items_box.add_child(row)

	if _seller_summary_label != null:
		var total_target_types := 0
		var total_target_units := 0
		for tid in cat.sell_targets:
			var q := int(cat.sell_targets[tid])
			if q > 0:
				total_target_types += 1
				total_target_units += q
		_seller_summary_label.text = "Đã chọn bán: %d mặt hàng (%d món) · Đã bán tích lũy: %d xu" % [
			total_target_types, total_target_units, int(cat.get("total_sales_revenue"))
		]


func _build_seller_item_row(item: Dictionary) -> Control:
	var item_id: String = str(item.id)
	var item_type: String = str(item.type)
	var item_name: String = str(item.name)
	var price: int = int(item.price)
	var avail: int = int(item.avail)
	var in_storage: int = int(item.in_storage)
	var in_bag: int = int(item.in_bag)
	var target: int = int(item.target)

	var row := PanelContainer.new()
	var row_bg := Color(0.22, 0.17, 0.11) if target > 0 else Color(0.18, 0.13, 0.08)
	var row_border := UIKit.COLOR_BORDER_GOLD if target > 0 else UIKit.COLOR_BORDER_WOOD
	row.add_theme_stylebox_override("panel", UIKit.badge_box(row_bg, row_border, 6))

	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 8)
	row.add_child(rh)

	# Icon
	var ic := TextureRect.new()
	ic.texture = _get_seller_item_icon(item_id, item_type)
	ic.custom_minimum_size = Vector2(24, 24)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	rh.add_child(ic)

	# Thông tin: Tên + Giá sạp + Tồn kho
	var iv := VBoxContainer.new()
	iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	iv.add_theme_constant_override("separation", 1)
	rh.add_child(iv)

	var title_col := UIKit.COLOR_TEXT_TITLE if target > 0 else Color(0.9, 0.9, 0.8)
	var _top_l := UIKit.label(iv, "%s · %d xu/sp" % [item_name, price], 12, title_col)
	var _sub_l := UIKit.label(iv, "Kho: %d · Balo: %d (Tổng có: %d)" % [in_storage, in_bag, avail], 10, UIKit.COLOR_TEXT_MUTED)

	# Các nút điều chỉnh: [-] [ Bán: X ] [+] [+5] [Hết] [✕]
	var btns_h := HBoxContainer.new()
	btns_h.add_theme_constant_override("separation", 3)
	rh.add_child(btns_h)

	var minus_btn := UIKit.styled_button(btns_h, "-", 12, "neutral")
	minus_btn.custom_minimum_size = Vector2(24, 24)
	minus_btn.disabled = (target <= 0)
	minus_btn.pressed.connect(func():
		if cat != null:
			cat.adjust_sell_target(item_id, -1)
			_refresh_seller_items()
	)

	var qty_badge := PanelContainer.new()
	qty_badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.08, 0.05), UIKit.COLOR_BORDER_GOLD if target > 0 else UIKit.COLOR_BORDER_WOOD, 4))
	qty_badge.custom_minimum_size = Vector2(56, 24)
	var q_lbl := UIKit.label(qty_badge, "%d" % target, 11, UIKit.COLOR_TEXT_GOLD if target > 0 else UIKit.COLOR_TEXT_MUTED)
	q_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btns_h.add_child(qty_badge)

	var plus_btn := UIKit.styled_button(btns_h, "+", 12, "gold")
	plus_btn.custom_minimum_size = Vector2(24, 24)
	plus_btn.pressed.connect(func():
		if cat != null:
			cat.adjust_sell_target(item_id, 1)
			_refresh_seller_items()
	)

	var plus5_btn := UIKit.styled_button(btns_h, "+5", 10, "gold")
	plus5_btn.custom_minimum_size = Vector2(30, 24)
	plus5_btn.pressed.connect(func():
		if cat != null:
			cat.adjust_sell_target(item_id, 5)
			_refresh_seller_items()
	)

	var all_btn := UIKit.styled_button(btns_h, "Tất cả", 10, "green")
	all_btn.custom_minimum_size = Vector2(40, 24)
	all_btn.pressed.connect(func():
		if cat != null:
			cat.set_sell_target(item_id, avail)
			_refresh_seller_items()
	)

	if target > 0:
		var del_btn := UIKit.styled_button(btns_h, "✕", 10, "danger")
		del_btn.custom_minimum_size = Vector2(22, 24)
		del_btn.pressed.connect(func():
			if cat != null:
				cat.set_sell_target(item_id, 0)
				_refresh_seller_items()
		)

	return row


func _get_seller_item_icon(id: String, type: String) -> Texture2D:
	match type:
		"fish":
			var FishDB = load("res://scripts/fish_db.gd")
			var f: Dictionary = FishDB.get_fish(id)
			return TextureGen.fish_icon(str(f.get("color", "8d9b6a"))) if not f.is_empty() else null
		"crop":
			var c: Dictionary = CropDB.get_crop(id)
			return TextureGen.prod_icon(c) if not c.is_empty() else null
		"ore":
			return TextureGen.ore_item_icon(id)
		_:
			return TextureGen.get_product_icon(id)

