extends CanvasLayer
# Bến Cá Chú Hai: Giao diện thẻ lưới 3 cột hiện đại & Hộp thoại chi tiết (Phong cách Mobile Grid Card).

const FishDB := preload("res://scripts/fish_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal feedback(text: String)

var money_label: Label
var rows: VBoxContainer
var scroll: ScrollContainer
var _buy_mode := "x1" # "x1", "x5", "x10", "x100", "max"
var _qty_buttons: Dictionary = {}
var _current_cat := "rods" # "rods", "bait", "fish"
var _cat_buttons: Dictionary = {}

# Modal chi tiết
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
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.70)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	root.add_child(dim)

	# Nút quay lại "<<" ở góc trên bên trái
	var back_btn := Button.new()
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

	# Khung bến cá neo sát lề phải màn hình (chống trôi ra ngoài màn hình)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.shop_dock_panel())
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -490.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.custom_minimum_size = Vector2(490, 720)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	# --- Tiêu đề Bến Cá ---
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(head)

	var title := UIKit.title_label(head, "BẾN CÁ CHÚ HAI", 22, UIKit.COLOR_TEXT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# --- 3 Tab: Cần câu, Mồi câu, Bán cá ---
	var tabs_box := PanelContainer.new()
	tabs_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.08, 0.05, 0.85), UIKit.COLOR_BORDER_WOOD, 8))
	v.add_child(tabs_box)

	var cat_h := HBoxContainer.new()
	cat_h.add_theme_constant_override("separation", 6)
	tabs_box.add_child(cat_h)

	var cats := [
		{"key": "rods", "label": "🎣 Mua cần"},
		{"key": "bait", "label": "🪱 Mua mồi"},
		{"key": "fish", "label": "🐟 Bán cá"},
	]

	for c_info in cats:
		var ck: String = str(c_info.key)
		var cbtn := Button.new()
		cbtn.text = str(c_info.label)
		cbtn.add_theme_font_size_override("font_size", 13)
		cbtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cbtn.custom_minimum_size = Vector2(0, 34)
		cbtn.pressed.connect(_set_category.bind(ck))
		cat_h.add_child(cbtn)
		_cat_buttons[ck] = cbtn

	_update_cat_buttons_style()

	# --- Thanh chọn số lượng mua ---
	var qty_pill := PanelContainer.new()
	qty_pill.name = "QtyPill"
	qty_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.08, 0.05, 0.85), UIKit.COLOR_BORDER_WOOD, 8))
	v.add_child(qty_pill)

	var qh := HBoxContainer.new()
	qh.add_theme_constant_override("separation", 6)
	qty_pill.add_child(qh)

	var qlbl := UIKit.label(qh, "🛒 Số lượng:", 12, UIKit.COLOR_TEXT_GOLD)
	qlbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var modes := [
		{"key": "x1", "label": "x1"},
		{"key": "x2", "label": "x2"},
		{"key": "x5", "label": "x5"},
		{"key": "x10", "label": "x10"},
		{"key": "x100", "label": "x100"},
		{"key": "max", "label": "⚡ Tối đa"},
	]

	for m in modes:
		var k: String = str(m.key)
		var btn := Button.new()
		btn.text = str(m.label)
		btn.add_theme_font_size_override("font_size", 11)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.custom_minimum_size = Vector2(34 if k != "max" else 68, 24)
		btn.pressed.connect(_set_buy_mode.bind(k))
		qh.add_child(btn)
		_qty_buttons[k] = btn

	_update_qty_buttons_style()

	# --- Danh sách lưới cuộn sản phẩm ---
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(scroll)
	v.add_child(scroll)

	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	scroll.add_child(rows)

	# --- Thanh đáy hiển thị tiền xu ---
	var bottom_bar := HBoxContainer.new()
	bottom_bar.add_theme_constant_override("separation", 10)
	v.add_child(bottom_bar)

	var money_box := PanelContainer.new()
	money_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.09, 0.05, 0.90), UIKit.COLOR_BORDER_GOLD, 8))
	bottom_bar.add_child(money_box)

	var hm := HBoxContainer.new()
	hm.alignment = BoxContainer.ALIGNMENT_CENTER
	hm.add_theme_constant_override("separation", 8)
	money_box.add_child(hm)

	var mic := TextureRect.new()
	mic.texture = TextureGen.coin_icon()
	mic.custom_minimum_size = Vector2(20, 20)
	mic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hm.add_child(mic)

	money_label = UIKit.label(hm, "", 16, UIKit.COLOR_TEXT_GOLD)

	_setup_info_modal(root)


func _setup_info_modal(parent: Node) -> void:
	_modal_root = Control.new()
	_modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_root.visible = false
	_modal_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_root.z_index = 10
	parent.add_child(_modal_root)

	var m_dim := ColorRect.new()
	m_dim.color = Color(0.02, 0.04, 0.06, 0.40)
	m_dim.anchor_left = 0.0
	m_dim.anchor_top = 0.0
	m_dim.anchor_right = 1.0
	m_dim.anchor_bottom = 1.0
	m_dim.offset_left = 0.0
	m_dim.offset_top = 0.0
	m_dim.offset_right = -490.0
	m_dim.offset_bottom = 0.0
	m_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	m_dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_hide_info_modal()
	)
	_modal_root.add_child(m_dim)

	var left_center := CenterContainer.new()
	left_center.anchor_left = 0.0
	left_center.anchor_top = 0.0
	left_center.anchor_right = 1.0
	left_center.anchor_bottom = 1.0
	left_center.offset_left = 0.0
	left_center.offset_top = 0.0
	left_center.offset_right = -490.0
	left_center.offset_bottom = 0.0
	left_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_root.add_child(left_center)

	var card_v := VBoxContainer.new()
	card_v.custom_minimum_size = Vector2(360, 0)
	card_v.add_theme_constant_override("separation", 0)
	card_v.mouse_filter = Control.MOUSE_FILTER_STOP
	left_center.add_child(card_v)

	var top_box := PanelContainer.new()
	top_box.add_theme_stylebox_override("panel", UIKit.modal_top_box())
	card_v.add_child(top_box)

	var top_v := VBoxContainer.new()
	top_v.alignment = BoxContainer.ALIGNMENT_CENTER
	top_v.add_theme_constant_override("separation", 8)
	top_box.add_child(top_v)

	_modal_icon = TextureRect.new()
	_modal_icon.custom_minimum_size = Vector2(64, 64)
	_modal_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	top_v.add_child(_modal_icon)

	_modal_title = Label.new()
	_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_title.add_theme_font_size_override("font_size", 20)
	_modal_title.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
	_modal_title.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.03, 0.98))
	_modal_title.add_theme_constant_override("outline_size", 4)
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
	banner_v.add_theme_constant_override("separation", 10)
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

	var close_btn := Button.new()
	close_btn.text = "✕ Đóng"
	close_btn.custom_minimum_size = Vector2(0, 34)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_CLOSE_BG, UIKit.COLOR_BORDER_GOLD, 8, 1))
	close_btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_CLOSE_HOVER, UIKit.COLOR_BORDER_BRIGHT, 8, 1))
	close_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(_hide_info_modal)
	banner_v.add_child(close_btn)


func _show_info_modal(data: Dictionary) -> void:
	_current_modal_data = data
	_modal_icon.texture = data.get("icon", null)
	_modal_title.text = str(data.get("title", ""))
	_modal_desc_label.text = str(data.get("desc", ""))
	_modal_desc_label.visible = not _modal_desc_label.text.is_empty()

	for c in _modal_lines_v.get_children():
		c.queue_free()

	var lines: Array = data.get("lines", [])
	for line in lines:
		var lbl := Label.new()
		lbl.text = str(line)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
		lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
		lbl.add_theme_constant_override("outline_size", 2)
		_modal_lines_v.add_child(lbl)

	for c in _modal_action_h.get_children():
		c.queue_free()

	var type: String = str(data.get("type", ""))
	var id: String = str(data.get("id", ""))
	var price: int = int(data.get("price", 0))

	match type:
		"buy_rod":
			var qty := _get_buy_qty(price)
			var total := qty * price
			var rod: Dictionary = data.get("rod", {})
			var total_casts: int = qty * int(rod.get("casts", 10))
			var btn := Button.new()
			btn.text = "+ Mua x%d Cần (+%d lượt · %d xu)" % [qty, total_casts, total] if qty > 1 else "+ Mua Cần (%d xu)" % price
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 36)
			btn.add_theme_font_size_override("font_size", 14)
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.55, 0.85, 0.45), 8, 2))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.65, 0.95, 0.55), 8, 2))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.disabled = (qty <= 0) or (GameState.money < total)
			btn.pressed.connect(func():
				_buy_rod(id)
				_hide_info_modal()
			)
			_modal_action_h.add_child(btn)

		"buy_bait":
			var btn := Button.new()
			btn.text = "+ Mua Mồi (%d xu)" % price
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 36)
			btn.add_theme_font_size_override("font_size", 14)
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.55, 0.85, 0.45), 8, 2))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.65, 0.95, 0.55), 8, 2))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.disabled = GameState.money < price
			btn.pressed.connect(func():
				if GameState.try_spend(price):
					if has_node("/root/AudioManager"):
						get_node("/root/AudioManager").play_sfx("coin")
					Inventory.add_bait(id, 5)
					feedback.emit("Đã mua 5 Mồi Câu (-%d xu)! 🪱" % price)
					refresh()
					_hide_info_modal()
			)
			_modal_action_h.add_child(btn)

		"sell_fish":
			var count := Inventory.fish_count(id)
			var sell1 := Button.new()
			sell1.text = "Bán 1 (+%d xu)" % price
			sell1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sell1.custom_minimum_size = Vector2(0, 36)
			sell1.add_theme_font_size_override("font_size", 13)
			sell1.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_SELL_BG, Color(0.95, 0.65, 0.30), 8, 2))
			sell1.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_SELL_HOVER, Color(1.0, 0.75, 0.40), 8, 2))
			sell1.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			sell1.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			sell1.disabled = count < 1
			sell1.pressed.connect(func():
				_sell_fish(id, false)
				_hide_info_modal()
			)
			_modal_action_h.add_child(sell1)

			var sell_all := Button.new()
			sell_all.text = "Bán Hết (%d con)" % count
			sell_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sell_all.custom_minimum_size = Vector2(0, 36)
			sell_all.add_theme_font_size_override("font_size", 13)
			sell_all.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.32, 0.18, 0.08), Color(0.90, 0.55, 0.25), 8, 2))
			sell_all.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.42, 0.24, 0.12), Color(1.0, 0.65, 0.35), 8, 2))
			sell_all.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			sell_all.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			sell_all.disabled = count < 1
			sell_all.pressed.connect(func():
				_sell_fish(id, true)
				_hide_info_modal()
			)
			_modal_action_h.add_child(sell_all)

	_modal_root.visible = true


func _hide_info_modal() -> void:
	if _modal_root != null:
		_modal_root.visible = false


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if _modal_root != null and _modal_root.visible:
			_hide_info_modal()
		else:
			close()


func open() -> void:
	visible = true
	_hide_info_modal()
	refresh()


func close() -> void:
	visible = false
	_hide_info_modal()
	closed.emit()


func _set_category(cat: String) -> void:
	_current_cat = cat
	_update_cat_buttons_style()
	if scroll != null:
		scroll.scroll_vertical = 0
	refresh()


func _update_cat_buttons_style() -> void:
	for k in ["rods", "bait", "fish"]:
		if not _cat_buttons.has(k):
			continue
		var btn: Button = _cat_buttons[k]
		var is_active: bool = (str(k) == _current_cat)
		if is_active:
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.42, 0.28, 0.16), UIKit.COLOR_BORDER_BRIGHT, 8, 2))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.50, 0.34, 0.20), UIKit.COLOR_BORDER_BRIGHT, 8, 2))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
		else:
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.20, 0.13, 0.08, 0.7), UIKit.COLOR_BORDER_WOOD, 8, 1))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.28, 0.18, 0.12, 0.9), UIKit.COLOR_BORDER_GOLD, 8, 1))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)


func _set_buy_mode(mode: String) -> void:
	_buy_mode = mode
	_update_qty_buttons_style()
	refresh()


func _update_qty_buttons_style() -> void:
	for k in _qty_buttons:
		var btn: Button = _qty_buttons[k]
		var is_active: bool = (str(k) == _buy_mode)
		if is_active:
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.42, 0.28, 0.16), UIKit.COLOR_BORDER_BRIGHT, 6, 2))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.50, 0.34, 0.20), UIKit.COLOR_BORDER_BRIGHT, 6, 2))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
		else:
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.20, 0.13, 0.08, 0.6), UIKit.COLOR_BORDER_WOOD, 6, 1))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.28, 0.18, 0.12, 0.8), UIKit.COLOR_BORDER_WOOD, 6, 1))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)


func _get_buy_qty(unit_price: int) -> int:
	match _buy_mode:
		"x1": return 1
		"x2": return 2
		"x5": return 5
		"x10": return 10
		"x100": return 100
		"max":
			if unit_price <= 0:
				return 1
			return int(GameState.money / unit_price)
	return 1


func refresh() -> void:
	money_label.text = "%d xu" % GameState.money
	for c in rows.get_children():
		rows.remove_child(c)
		c.queue_free()

	var q_node = find_child("QtyPill", true, false)
	if q_node != null:
		q_node.visible = (_current_cat == "rods" or _current_cat == "bait")

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 1. TAB CẦN CÂU (rods)
	if _current_cat == "rods":
		for rod in FishDB.RODS:
			grid.add_child(_build_rod_card(rod))

	# 2. TAB MỒI CÂU & VẬT TƯ (bait)
	elif _current_cat == "bait":
		grid.add_child(_build_bait_card("worm", "Mồi Trùn Quế", 10, "Mồi giun tự nhiên, thu hút cá phổ thông & trung cấp."))
		grid.add_child(_build_bait_card("caterpillar", "Mồi Sâu Bọ", 15, "Mồi tươi ngon bắt trên đồng ruộng, thu hút cá hiếm."))
		grid.add_child(_build_bait_card("paste", "Thính Cám Thơm", 25, "Hỗn hợp cám thơm ngào ngạt, tăng tốc độ cá cắn câu!"))

	# 3. TAB BÁN CÁ (fish)
	elif _current_cat == "fish":
		var total_fish_val := _total_fish_value()
		if total_fish_val > 0:
			var sell_all_btn := UIKit.styled_button(rows, "⭐ BÁN TẤT CẢ CÁ (+%d xu)" % total_fish_val, 13, "sell")
			sell_all_btn.custom_minimum_size = Vector2(0, 36)
			sell_all_btn.pressed.connect(_sell_all_fish)

		for f in FishDB.FISH:
			grid.add_child(_build_fish_card(f))

	rows.add_child(grid)


# ---------------- Thẻ Lưới Cho Bến Cá (Grid Cards) ----------------

func _make_card_clickable(card: Control, ic: Control, name_l: Control, callback: Callable) -> void:
	var on_click := func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			callback.call()

	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(on_click)

	if ic != null:
		ic.mouse_filter = Control.MOUSE_FILTER_STOP
		ic.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		ic.gui_input.connect(on_click)

	if name_l != null:
		name_l.mouse_filter = Control.MOUSE_FILTER_STOP
		name_l.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		name_l.gui_input.connect(on_click)


func _build_rod_card(rod: Dictionary) -> Control:
	var tier := str(rod.tier)
	var price := int(rod.price)
	var remaining := Inventory.rod_casts(tier)
	var qty := _get_buy_qty(price)
	var total_price := qty * price

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var show_rod := func():
		_show_info_modal({
			"title": str(rod.name),
			"desc": "Cần câu chuyên dụng cho hồ & sông nước",
			"icon": TextureGen.rod_icon(str(rod.color)),
			"type": "buy_rod",
			"id": tier,
			"price": price,
			"rod": rod,
			"lines": [
				"🎣 Độ bền: +%d lượt câu / lần mua" % int(rod.casts),
				"🎒 Hiện có: %d lượt câu trong túi" % remaining,
				"💰 Giá mua: %d xu" % price
			]
		})

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(v)

	var top_h := HBoxContainer.new()
	top_h.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(top_h)

	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_PASS
	badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.06, 0.90), UIKit.COLOR_BORDER_GOLD, 4))
	var bl := UIKit.label(badge, "%d lượt" % remaining if remaining > 0 else "0 lượt", 10, UIKit.COLOR_TEXT_GOLD)
	bl.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(badge)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(sp)

	var info_btn := _create_info_circle_button(show_rod)
	top_h.add_child(info_btn)

	var ic := TextureRect.new()
	ic.texture = TextureGen.rod_icon(str(rod.color))
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = str(rod.name)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 11)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	_make_card_clickable(card, ic, name_l, show_rod)

	var buy_btn := Button.new()
	if _buy_mode == "max":
		if qty > 0:
			buy_btn.text = "x%d · %d 🪙" % [qty, total_price]
		else:
			buy_btn.text = "Hết xu 🪙"
	elif qty > 1:
		buy_btn.text = "x%d · %d 🪙" % [qty, total_price]
	else:
		buy_btn.text = "%d 🪙" % price
	buy_btn.custom_minimum_size = Vector2(0, 26)
	buy_btn.add_theme_font_size_override("font_size", 11 if qty > 1 else 12)
	buy_btn.add_theme_stylebox_override("normal", UIKit.shop_price_pill(Color(0.14, 0.24, 0.12), Color(0.35, 0.55, 0.30)))
	buy_btn.add_theme_stylebox_override("hover", UIKit.shop_price_pill(Color(0.20, 0.34, 0.18), Color(0.50, 0.75, 0.40)))
	buy_btn.add_theme_stylebox_override("disabled", UIKit.shop_price_pill(Color(0.14, 0.11, 0.09), Color(0.28, 0.22, 0.18)))
	buy_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GOLD)
	buy_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.45))
	buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	buy_btn.disabled = (qty <= 0) or (GameState.money < total_price)
	buy_btn.pressed.connect(_buy_rod.bind(tier))
	v.add_child(buy_btn)

	return card


func _build_bait_card(bait_id: String, bait_name: String, price: int, desc: String) -> Control:
	var count: int = 0
	if Inventory.has_method("bait_count"):
		count = int(Inventory.bait_count(bait_id))

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var show_bait := func():
		_show_info_modal({
			"title": bait_name,
			"desc": desc,
			"icon": TextureGen.get_tex("caterpillar") if bait_id == "caterpillar" else TextureGen.get_feed_icon(),
			"type": "buy_bait",
			"id": bait_id,
			"price": price,
			"lines": [
				"🪱 Số lượng: Gói 5 mồi câu",
				"🎯 Công dụng: %s" % desc,
				"💰 Giá mua: %d xu" % price
			]
		})

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(v)

	var top_h := HBoxContainer.new()
	top_h.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(top_h)

	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_PASS
	badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.06, 0.90), UIKit.COLOR_BORDER_GOLD, 4))
	var bl := UIKit.label(badge, "x%d" % count, 10, UIKit.COLOR_TEXT_GOLD)
	bl.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(badge)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(sp)

	var info_btn := _create_info_circle_button(show_bait)
	top_h.add_child(info_btn)

	var ic := TextureRect.new()
	ic.texture = TextureGen.get_tex("caterpillar") if bait_id == "caterpillar" else TextureGen.get_feed_icon()
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = bait_name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	_make_card_clickable(card, ic, name_l, show_bait)

	var buy_btn := Button.new()
	buy_btn.text = "%d 🪙" % price
	buy_btn.custom_minimum_size = Vector2(0, 26)
	buy_btn.add_theme_font_size_override("font_size", 12)
	buy_btn.add_theme_stylebox_override("normal", UIKit.shop_price_pill(Color(0.14, 0.24, 0.12), Color(0.35, 0.55, 0.30)))
	buy_btn.add_theme_stylebox_override("hover", UIKit.shop_price_pill(Color(0.20, 0.34, 0.18), Color(0.50, 0.75, 0.40)))
	buy_btn.add_theme_stylebox_override("disabled", UIKit.shop_price_pill(Color(0.14, 0.11, 0.09), Color(0.28, 0.22, 0.18)))
	buy_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GOLD)
	buy_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.45))
	buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	buy_btn.disabled = GameState.money < price
	buy_btn.pressed.connect(func():
		if GameState.try_spend(price):
			if has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_sfx("coin")
			if Inventory.has_method("add_bait"):
				Inventory.add_bait(bait_id, 5)
			feedback.emit("Đã mua 5 %s (-%d xu)! 🪱" % [bait_name, price])
			refresh()
	)
	v.add_child(buy_btn)

	return card


func _build_fish_card(f: Dictionary) -> Control:
	var fid := str(f.id)
	var price := int(f.price)
	var count := Inventory.fish_count(fid)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var show_fish := func():
		_show_info_modal({
			"title": str(f.name),
			"desc": str(f.get("desc", "Cá nước ngọt sông quê")),
			"icon": TextureGen.fish_icon(str(f.color)),
			"type": "sell_fish",
			"id": fid,
			"price": price,
			"lines": [
				"🐟 Phân hạng: %s" % str(f.tier).capitalize(),
				"🧺 Giá Chú Hai thu mua: %d xu/con" % price,
				"🎒 Đang có trong giỏ: %d con" % count,
				"💰 Tổng giá trị: %d xu" % (count * price)
			]
		})

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(v)

	var top_h := HBoxContainer.new()
	top_h.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(top_h)

	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_PASS
	if count > 0:
		badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.32, 0.18, 0.08), UIKit.COLOR_BORDER_GOLD, 4))
		var bl := UIKit.label(badge, "Có: %d" % count, 10, UIKit.COLOR_TEXT_GOLD)
		bl.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07, 0.6), UIKit.COLOR_BORDER_WOOD, 4))
		var bl := UIKit.label(badge, "Có: 0", 10, UIKit.COLOR_TEXT_MUTED)
		bl.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(badge)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(sp)

	var info_btn := _create_info_circle_button(show_fish)
	top_h.add_child(info_btn)

	var ic := TextureRect.new()
	ic.texture = TextureGen.fish_icon(str(f.color))
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = str(f.name)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	_make_card_clickable(card, ic, name_l, show_fish)

	var sell_btn := Button.new()
	sell_btn.text = "Bán (%d 🪙)" % price
	sell_btn.custom_minimum_size = Vector2(0, 26)
	sell_btn.add_theme_font_size_override("font_size", 11)
	sell_btn.add_theme_stylebox_override("normal", UIKit.shop_price_pill(Color(0.28, 0.16, 0.08), Color(0.60, 0.40, 0.20)))
	sell_btn.add_theme_stylebox_override("hover", UIKit.shop_price_pill(Color(0.38, 0.22, 0.12), Color(0.80, 0.55, 0.28)))
	sell_btn.add_theme_stylebox_override("disabled", UIKit.shop_price_pill(Color(0.14, 0.11, 0.09), Color(0.28, 0.22, 0.18)))
	sell_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_ORANGE)
	sell_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.45))
	sell_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	sell_btn.disabled = count < 1
	sell_btn.pressed.connect(func():
		_sell_fish(fid, false)
	)
	v.add_child(sell_btn)

	return card


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


# ---------------- Logic Mua / Bán ----------------

func _total_fish_value() -> int:
	var total := 0
	for f in FishDB.FISH:
		var n := Inventory.fish_count(str(f.id))
		total += n * int(f.price)
	return total


func _sell_all_fish() -> void:
	var total := 0
	var count := 0
	for f in FishDB.FISH:
		var fid := str(f.id)
		var n := Inventory.fish_count(fid)
		if n > 0 and Inventory.take_fish(fid, n):
			total += n * int(f.price)
			count += n
	if total > 0:
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		GameState.add_money(total)
		feedback.emit("Đã bán toàn bộ %d con cá (+%d xu)! 🐟" % [count, total])
		refresh()


func _buy_rod(tier: String) -> void:
	var rod := FishDB.get_rod(tier)
	var price := int(rod.price)
	var qty := _get_buy_qty(price)
	if qty <= 0:
		feedback.emit("Không đủ xu để mua %s!" % rod.name)
		return
	if not Inventory.can_hold("rod", tier):
		feedback.emit("Túi đồ đã đầy (%d/%d)! Cất bớt đồ vào nhà kho 🏚️" % [Inventory.backpack_slots_used(), Inventory.backpack_max])
		return
	var total_price := qty * price
	var total_casts := qty * int(rod.casts)
	if GameState.try_spend(total_price):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		Inventory.add_rod(tier, total_casts)
		feedback.emit("Đã mua %d %s (+%d lượt câu, -%d xu)! 🎣" % [qty, rod.name, total_casts, total_price])
		refresh()
	else:
		feedback.emit("Không đủ xu mua %d %s (cần %d xu)!" % [qty, rod.name, total_price])


func _sell_fish(id: String, all: bool) -> void:
	var f := FishDB.get_fish(id)
	var have := Inventory.fish_count(id)
	if have < 1:
		return
	var n := have if all else 1
	if Inventory.take_fish(id, n):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		GameState.add_money(int(f.price) * n)
		refresh()
		if all:
			feedback.emit("Đã bán %d %s (+%d xu) 🐟" % [n, f.name, int(f.price) * n])
		else:
			feedback.emit("Đã bán 1 %s (+%d xu) 🐟" % [f.name, int(f.price)])
