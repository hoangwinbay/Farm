extends CanvasLayer
# Cửa Hàng Bác Tư: Giao diện thẻ lưới 3 cột hiện đại & Hộp thoại chi tiết (Phong cách Mobile Grid Card).

const CropDB := preload("res://scripts/crop_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal feedback(text: String)

const HOE_PRICE := 20
const FEED_PRICE := 15

var money_label: Label
var rows: VBoxContainer
var scroll: ScrollContainer
var _buy_mode := "x1" # "x1", "x5", "x10", "x100", "max"
var _qty_buttons: Dictionary = {}
var _current_cat := "seeds" # "seeds", "tools", "produce", "all", "unlocks"
var _cat_buttons: Dictionary = {}

# Modal chi tiết vật phẩm
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

	# Nền làm mờ farm đằng sau
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.70)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
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

	# Khung cửa hàng neo sát lề phải màn hình (chống click lọt xuống dim)
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
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(v)

	# --- Tiêu đề Cửa Hàng ---
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(head)

	var title := UIKit.title_label(head, "CỬA HÀNG BÁC TƯ", 22, UIKit.COLOR_TEXT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# --- 3 Tab chính: Mua hạt, Mua cuốc, Bán nông sản ---
	var tabs_box := PanelContainer.new()
	tabs_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.08, 0.05, 0.85), UIKit.COLOR_BORDER_WOOD, 8))
	v.add_child(tabs_box)

	var cat_h := HBoxContainer.new()
	cat_h.add_theme_constant_override("separation", 6)
	tabs_box.add_child(cat_h)

	var cats := [
		{"key": "seeds", "label": "🌱 Mua hạt"},
		{"key": "tools", "label": "🛠️ Mua cuốc"},
		{"key": "produce", "label": "🌾 Bán nông sản"},
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

	# Các nút ảo để tương thích kiểm thử cũ
	var dummy_all := Button.new()
	dummy_all.visible = false
	root.add_child(dummy_all)
	_cat_buttons["all"] = dummy_all

	var dummy_unlocks := Button.new()
	dummy_unlocks.visible = false
	root.add_child(dummy_unlocks)
	_cat_buttons["unlocks"] = dummy_unlocks

	_update_cat_buttons_style()

	# --- Thanh chọn số lượng mua (x1, x5, x10, x100, Max) ---
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
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	UIKit.style_scroll_container(scroll)
	v.add_child(scroll)

	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	rows.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(rows)

	# --- Thanh đáy hiển thị tiền xu & đóng ---
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

	# Tạo Modal chi tiết (nằm bên trái cửa hàng, như ảnh tham khảo)
	_setup_info_modal(root)


func _setup_info_modal(parent: Node) -> void:
	_modal_root = Control.new()
	_modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_root.visible = false
	_modal_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_root.z_index = 10
	parent.add_child(_modal_root)

	# Nền mờ chỉ phủ vùng bên trái (không che khung cửa hàng bên phải)
	var m_dim := ColorRect.new()
	m_dim.color = Color(0.08, 0.05, 0.03, 0.55)
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

	# Vùng đặt modal ở nửa trái màn hình (như ảnh tham khảo)
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

	# Nửa trên: Nền gỗ ấm với icon lớn và tên vật phẩm
	var top_box := PanelContainer.new()
	top_box.add_theme_stylebox_override("panel", UIKit.modal_top_box())
	top_box.mouse_filter = Control.MOUSE_FILTER_STOP
	card_v.add_child(top_box)

	var top_v := VBoxContainer.new()
	top_v.alignment = BoxContainer.ALIGNMENT_CENTER
	top_v.add_theme_constant_override("separation", 8)
	top_v.mouse_filter = Control.MOUSE_FILTER_PASS
	top_box.add_child(top_v)

	_modal_icon = TextureRect.new()
	_modal_icon.custom_minimum_size = Vector2(64, 64)
	_modal_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_modal_icon.mouse_filter = Control.MOUSE_FILTER_PASS
	top_v.add_child(_modal_icon)

	_modal_title = Label.new()
	_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_title.add_theme_font_size_override("font_size", 20)
	_modal_title.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
	_modal_title.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.03, 0.98))
	_modal_title.add_theme_constant_override("outline_size", 4)
	_modal_title.mouse_filter = Control.MOUSE_FILTER_PASS
	top_v.add_child(_modal_title)

	_modal_desc_label = Label.new()
	_modal_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_desc_label.add_theme_font_size_override("font_size", 12)
	_modal_desc_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)
	_modal_desc_label.mouse_filter = Control.MOUSE_FILTER_PASS
	top_v.add_child(_modal_desc_label)

	# Nửa dưới: Banner gỗ sẫm chứa thông số chi tiết và nút thao tác
	var banner_box := PanelContainer.new()
	banner_box.add_theme_stylebox_override("panel", UIKit.modal_banner_box())
	banner_box.mouse_filter = Control.MOUSE_FILTER_STOP
	card_v.add_child(banner_box)

	var banner_v := VBoxContainer.new()
	banner_v.add_theme_constant_override("separation", 10)
	banner_v.mouse_filter = Control.MOUSE_FILTER_PASS
	banner_box.add_child(banner_v)

	_modal_lines_v = VBoxContainer.new()
	_modal_lines_v.add_theme_constant_override("separation", 4)
	_modal_lines_v.mouse_filter = Control.MOUSE_FILTER_PASS
	banner_v.add_child(_modal_lines_v)

	var sep := ColorRect.new()
	sep.color = Color(0.86, 0.70, 0.32, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_v.add_child(sep)

	_modal_action_h = HBoxContainer.new()
	_modal_action_h.add_theme_constant_override("separation", 8)
	_modal_action_h.mouse_filter = Control.MOUSE_FILTER_PASS
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
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_modal_lines_v.add_child(lbl)

	for c in _modal_action_h.get_children():
		c.queue_free()

	var type: String = str(data.get("type", ""))
	var cid: String = str(data.get("id", ""))
	var price: int = int(data.get("price", 0))

	match type:
		"buy_seed":
			var act_v := VBoxContainer.new()
			act_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			act_v.add_theme_constant_override("separation", 8)
			_modal_action_h.add_child(act_v)

			# Thanh chọn số lượng mua trực tiếp trong hộp thoại
			var m_qh := HBoxContainer.new()
			m_qh.alignment = BoxContainer.ALIGNMENT_CENTER
			m_qh.add_theme_constant_override("separation", 4)
			act_v.add_child(m_qh)

			var m_lbl := UIKit.label(m_qh, "Số lượng:", 11, UIKit.COLOR_TEXT_GOLD)
			m_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

			var m_modes := [
				{"key": "x1", "label": "x1"},
				{"key": "x2", "label": "x2"},
				{"key": "x5", "label": "x5"},
				{"key": "x10", "label": "x10"},
				{"key": "x100", "label": "x100"},
				{"key": "max", "label": "Tối đa"},
			]
			for mm in m_modes:
				var mk: String = str(mm.key)
				var m_btn := Button.new()
				m_btn.text = str(mm.label)
				m_btn.add_theme_font_size_override("font_size", 11)
				m_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				m_btn.custom_minimum_size = Vector2(34 if mk != "max" else 52, 24)
				var is_active := (mk == _buy_mode)
				if is_active:
					m_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.42, 0.28, 0.16), UIKit.COLOR_BORDER_BRIGHT, 5, 2))
					m_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.50, 0.34, 0.20), UIKit.COLOR_BORDER_BRIGHT, 5, 2))
					m_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
				else:
					m_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.20, 0.13, 0.08, 0.6), UIKit.COLOR_BORDER_WOOD, 5, 1))
					m_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.28, 0.18, 0.12, 0.8), UIKit.COLOR_BORDER_WOOD, 5, 1))
					m_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)
				m_btn.pressed.connect(func():
					_set_buy_mode(mk)
				)
				m_qh.add_child(m_btn)

			var qty := _get_buy_qty(price)
			var total := qty * price
			var buy_btn := Button.new()
			if _buy_mode == "max" and qty <= 0:
				buy_btn.text = "❌ Không đủ xu"
			elif qty > 1:
				buy_btn.text = "+ Mua x%d (%d xu)" % [qty, total]
			else:
				buy_btn.text = "+ Mua (%d xu)" % price
			buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			buy_btn.custom_minimum_size = Vector2(0, 36)
			buy_btn.add_theme_font_size_override("font_size", 14)
			buy_btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.55, 0.85, 0.45), 8, 2))
			buy_btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.65, 0.95, 0.55), 8, 2))
			buy_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			buy_btn.disabled = (qty <= 0) or (GameState.money < total)
			buy_btn.pressed.connect(func():
				_buy(cid)
				_update_modal_content()
			)
			act_v.add_child(buy_btn)

		"buy_hoe":
			var qty := _get_buy_qty(HOE_PRICE)
			var total := qty * HOE_PRICE
			var buy_btn := Button.new()
			buy_btn.text = "+ Mua x%d Cuốc (%d xu)" % [qty, total] if qty > 1 else "+ Mua Cuốc (%d xu)" % HOE_PRICE
			buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			buy_btn.custom_minimum_size = Vector2(0, 36)
			buy_btn.add_theme_font_size_override("font_size", 14)
			buy_btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.55, 0.85, 0.45), 8, 2))
			buy_btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.65, 0.95, 0.55), 8, 2))
			buy_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			buy_btn.disabled = (qty <= 0) or (GameState.money < total)
			buy_btn.pressed.connect(func():
				_buy_hoe()
				_update_modal_content()
			)
			_modal_action_h.add_child(buy_btn)

		"buy_feed":
			var qty := _get_buy_qty(FEED_PRICE)
			var total := qty * FEED_PRICE
			var buy_btn := Button.new()
			buy_btn.text = "+ Mua x%d Cám (%d xu)" % [qty, total] if qty > 1 else "+ Mua Cám (%d xu)" % FEED_PRICE
			buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			buy_btn.custom_minimum_size = Vector2(0, 36)
			buy_btn.add_theme_font_size_override("font_size", 14)
			buy_btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.55, 0.85, 0.45), 8, 2))
			buy_btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.65, 0.95, 0.55), 8, 2))
			buy_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			buy_btn.disabled = (qty <= 0) or (GameState.money < total)
			buy_btn.pressed.connect(func():
				_buy_feed()
				_update_modal_content()
			)
			_modal_action_h.add_child(buy_btn)

		"buy_backpack":
			var cost := Inventory.get_backpack_upgrade_cost()
			var btn := Button.new()
			btn.text = "+ Nâng Cấp Balo (%d xu)" % cost
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 36)
			btn.add_theme_font_size_override("font_size", 14)
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.55, 0.85, 0.45), 8, 2))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.65, 0.95, 0.55), 8, 2))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.disabled = (GameState.money < cost) or (Inventory.backpack_max >= Inventory.BACKPACK_MAX_LIMIT)
			btn.pressed.connect(func():
				var res := Inventory.upgrade_backpack()
				if res.get("ok", false):
					feedback.emit(str(res.get("msg", "")))
					refresh()
					_update_modal_content()
				else:
					feedback.emit(str(res.get("msg", "")))
			)
			_modal_action_h.add_child(btn)

		"sell_produce":
			var have := Inventory.produce_count(cid)
			var sell1 := Button.new()
			sell1.text = "Bán 1 (+%d xu)" % price
			sell1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sell1.custom_minimum_size = Vector2(0, 36)
			sell1.add_theme_font_size_override("font_size", 13)
			sell1.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_SELL_BG, Color(0.95, 0.65, 0.30), 8, 2))
			sell1.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_SELL_HOVER, Color(1.0, 0.75, 0.40), 8, 2))
			sell1.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			sell1.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			sell1.disabled = have < 1
			sell1.pressed.connect(func():
				_sell(cid, false)
				_update_modal_content()
			)
			_modal_action_h.add_child(sell1)

			var sell_all := Button.new()
			sell_all.text = "Bán Hết (%d cái)" % have
			sell_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sell_all.custom_minimum_size = Vector2(0, 36)
			sell_all.add_theme_font_size_override("font_size", 13)
			sell_all.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.32, 0.18, 0.08), Color(0.90, 0.55, 0.25), 8, 2))
			sell_all.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.42, 0.24, 0.12), Color(1.0, 0.65, 0.35), 8, 2))
			sell_all.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			sell_all.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			sell_all.disabled = have < 1
			sell_all.pressed.connect(func():
				_sell(cid, true)
				_update_modal_content()
			)
			_modal_action_h.add_child(sell_all)

		"unlock_crop":
			var btn := Button.new()
			btn.text = "🔓 Mở Khóa Cây Này (%d xu)" % price
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 36)
			btn.add_theme_font_size_override("font_size", 14)
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.48, 0.32, 0.15), UIKit.COLOR_BORDER_BRIGHT, 8, 2))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.60, 0.42, 0.20), UIKit.COLOR_BORDER_BRIGHT, 8, 2))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.disabled = GameState.money < price
			btn.pressed.connect(func():
				_unlock()
				_hide_info_modal()
			)
			_modal_action_h.add_child(btn)

	_modal_root.visible = true


func _update_modal_content() -> void:
	if not _modal_root.visible or _current_modal_data.is_empty():
		return
	var type: String = str(_current_modal_data.get("type", ""))
	var cid: String = str(_current_modal_data.get("id", ""))
	var crop: Dictionary = _current_modal_data.get("crop", {})

	match type:
		"buy_seed":
			var seed_count := Inventory.seed_count(cid)
			var grow_min := int(ceil(float(crop.grow_sec) / 60.0))
			_current_modal_data["lines"] = [
				"⏱ Thời gian lớn: ~%d phút" % grow_min,
				"🌱 Phân nhóm: %s" % str(crop.group),
				"💰 Đơn giá hạt: %d xu" % int(crop.seed_price),
				"🌾 Giá bán thu hoạch: %d xu/cái" % int(crop.sell_price),
				"🎒 Đang có trong túi: %d hạt" % seed_count
			]
		"sell_produce":
			var prod_count := Inventory.produce_count(cid)
			_current_modal_data["lines"] = [
				"🌾 Giá thu mua: %d xu/cái" % int(crop.sell_price),
				"🌱 Phân nhóm: %s" % str(crop.group),
				"🎒 Đang có trong túi: %d cái" % prod_count,
				"💰 Tổng giá trị: %d xu" % (prod_count * int(crop.sell_price))
			]
		"buy_hoe":
			_current_modal_data["lines"] = [
				"🛠️ Công dụng: Xới đất cỏ thành đất trồng",
				"💰 Đơn giá: %d xu/cái" % HOE_PRICE,
				"🎒 Đang có: %d cái" % Inventory.hoes
			]
		"buy_feed":
			_current_modal_data["lines"] = [
				"🌾 Thức ăn cho: Gà, Bò, Lợn, Cừu",
				"💰 Đơn giá: %d xu/túi" % FEED_PRICE,
				"🎒 Đang có: %d túi" % Inventory.feed_count()
			]
		"buy_backpack":
			_current_modal_data["lines"] = [
				"🎒 Sức chứa hiện tại: %d ô" % Inventory.backpack_max,
				"📦 Giới hạn tối đa: %d ô" % Inventory.BACKPACK_MAX_LIMIT,
				"💰 Chi phí nâng cấp: %d xu" % Inventory.get_backpack_upgrade_cost()
			]

	_show_info_modal(_current_modal_data)


func _hide_info_modal() -> void:
	if _modal_root != null:
		_modal_root.visible = false


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
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
	for k in ["seeds", "tools", "produce"]:
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
	if _modal_root != null and _modal_root.visible and not _current_modal_data.is_empty():
		_update_modal_content()


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

	# Quản lý hiển thị thanh chọn số lượng mua (chỉ hiện ở tab mua hạt hoặc mua cuốc)
	var q_node = find_child("QtyPill", true, false)
	if q_node != null:
		q_node.visible = (_current_cat == "seeds" or _current_cat == "tools" or _current_cat == "all")

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_PASS

	# 1. TAB MUA HẠT GIỐNG (seeds)
	if _current_cat == "seeds" or _current_cat == "all":
		for crop in CropDB.CROPS:
			if GameState.has_crop(str(crop.id)):
				grid.add_child(_build_seed_card(crop))

		# Cây kế tiếp cần mở khóa
		var next_crop := GameState.next_locked()
		if not next_crop.is_empty():
			for crop in CropDB.CROPS:
				if str(crop.id) == str(next_crop.get("id", "")):
					grid.add_child(_build_next_unlock_card(crop))
				elif not GameState.has_crop(str(crop.id)):
					grid.add_child(_build_mystery_card())

	# 2. TAB MUA CUỐC & VẬT TƯ (tools)
	if _current_cat == "tools":
		grid.add_child(_build_hoe_card())
		grid.add_child(_build_feed_card())
		grid.add_child(_build_backpack_card())

	# 3. TAB BÁN NÔNG SẢN (produce)
	if _current_cat == "produce":
		var total_val := _total_produce_value()
		if total_val > 0:
			var sell_all_btn := UIKit.styled_button(rows, "⭐ BÁN HẾT TẤT CẢ NÔNG SẢN (+%d xu)" % total_val, 13, "sell")
			sell_all_btn.custom_minimum_size = Vector2(0, 36)
			sell_all_btn.pressed.connect(_sell_all_produce)

		for crop in CropDB.CROPS:
			var cid := str(crop.id)
			if GameState.has_crop(cid) or Inventory.produce_count(cid) > 0:
				grid.add_child(_build_produce_card(crop))

	rows.add_child(grid)


# ---------------- Thẻ Vật Phẩm Lưới 3 Cột (Grid Cards) ----------------

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


func _open_crop_modal(crop: Dictionary) -> void:
	var cid := str(crop.id)
	var seed_count := Inventory.seed_count(cid)
	var price := int(crop.seed_price)
	var grow_min := int(ceil(float(crop.grow_sec) / 60.0))
	_show_info_modal({
		"title": crop.name,
		"desc": crop.desc,
		"icon": TextureGen.seed_icon(crop),
		"type": "buy_seed",
		"id": cid,
		"price": price,
		"crop": crop,
		"lines": [
			"⏱ Thời gian lớn: ~%d phút" % grow_min,
			"🌱 Phân nhóm: %s" % str(crop.group),
			"💰 Đơn giá hạt: %d xu" % price,
			"🌾 Giá bán thu hoạch: %d xu/cái" % int(crop.sell_price),
			"🎒 Đang có trong túi: %d hạt" % seed_count
		]
	})


func _build_seed_card(crop: Dictionary) -> Control:
	var cid := str(crop.id)
	var seed_count := Inventory.seed_count(cid)
	var price := int(crop.seed_price)
	var qty := _get_buy_qty(price)
	var total := qty * price

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(v)

	# Hàng trên: Huy hiệu số lượng + Nút (i)
	var top_h := HBoxContainer.new()
	top_h.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(top_h)

	if seed_count > 0:
		var badge := PanelContainer.new()
		badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.06, 0.90), UIKit.COLOR_BORDER_GOLD, 4))
		badge.mouse_filter = Control.MOUSE_FILTER_PASS
		var bl := UIKit.label(badge, "x%d" % seed_count, 11, UIKit.COLOR_TEXT_GOLD)
		bl.mouse_filter = Control.MOUSE_FILTER_PASS
		top_h.add_child(badge)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(sp)

	var info_btn := _create_info_circle_button(func():
		_open_crop_modal(crop)
	)
	top_h.add_child(info_btn)

	# Icon hạt giống
	var ic := TextureRect.new()
	ic.texture = TextureGen.seed_icon(crop)
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	# Tên cây
	var name_l := Label.new()
	name_l.text = crop.name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	# Nhấn vào thẻ, icon, tên hoặc nút (i) đều mở modal chi tiết
	_make_card_clickable(card, ic, name_l, func(): _open_crop_modal(crop))

	# Nút bấm mua (Thanh giá xu ở đáy thẻ)
	var buy_btn := Button.new()
	if _buy_mode == "max":
		if qty > 0:
			buy_btn.text = "x%d · %d 🪙" % [qty, total]
		else:
			buy_btn.text = "Hết xu 🪙"
	elif qty > 1:
		buy_btn.text = "x%d · %d 🪙" % [qty, total]
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
	buy_btn.disabled = (qty <= 0) or (GameState.money < total)
	buy_btn.pressed.connect(func():
		_buy(cid)
	)
	v.add_child(buy_btn)

	return card


func _build_next_unlock_card(crop: Dictionary) -> Control:
	var price := int(crop.unlock_cost)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var grow_min := int(ceil(float(crop.grow_sec) / 60.0))
	var show_unlock := func():
		_show_info_modal({
			"title": "MỞ KHÓA: " + crop.name,
			"desc": crop.desc,
			"icon": TextureGen.lock_icon(),
			"type": "unlock_crop",
			"id": str(crop.id),
			"price": price,
			"crop": crop,
			"lines": [
				"🔓 Chi phí mở khóa: %d xu" % price,
				"⏱ Thời gian lớn: ~%d phút" % grow_min,
				"🌾 Giá bán thu hoạch: %d xu/cái" % int(crop.sell_price),
				"🌱 Phân nhóm: %s" % str(crop.group)
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
	badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.36, 0.24, 0.10), UIKit.COLOR_BORDER_GOLD, 4))
	badge.mouse_filter = Control.MOUSE_FILTER_PASS
	var bl := UIKit.label(badge, "🔒 Khóa", 10, UIKit.COLOR_TEXT_GOLD)
	bl.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(badge)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(sp)

	var info_btn := _create_info_circle_button(show_unlock)
	top_h.add_child(info_btn)

	var ic := TextureRect.new()
	ic.texture = TextureGen.lock_icon()
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = crop.name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)
	v.add_child(name_l)

	# Nhấn vào thẻ, icon, tên hoặc nút (i) đều mở modal chi tiết mở khóa
	_make_card_clickable(card, ic, name_l, show_unlock)

	var unlock_btn := Button.new()
	unlock_btn.text = "🔓 %d 🪙" % price
	unlock_btn.custom_minimum_size = Vector2(0, 26)
	unlock_btn.add_theme_font_size_override("font_size", 11)
	unlock_btn.add_theme_stylebox_override("normal", UIKit.shop_price_pill(Color(0.28, 0.18, 0.08), UIKit.COLOR_BORDER_GOLD))
	unlock_btn.add_theme_stylebox_override("hover", UIKit.shop_price_pill(Color(0.38, 0.26, 0.12), UIKit.COLOR_BORDER_BRIGHT))
	unlock_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GOLD)
	unlock_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	unlock_btn.disabled = GameState.money < price
	unlock_btn.pressed.connect(_unlock)
	v.add_child(unlock_btn)

	return card


func _build_mystery_card() -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.row_locked_box())
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(v)

	var ic := TextureRect.new()
	ic.texture = TextureGen.lock_icon()
	ic.custom_minimum_size = Vector2(40, 40)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ic.modulate = Color(1, 1, 1, 0.4)
	ic.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = "???"
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 13)
	name_l.add_theme_color_override("font_color", Color(0.60, 0.55, 0.50))
	name_l.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(name_l)

	var sub := Label.new()
	sub.text = "Bí ẩn"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color(0.50, 0.45, 0.40))
	sub.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(sub)

	return card


func _build_hoe_card() -> Control:
	var qty := _get_buy_qty(HOE_PRICE)
	var total := qty * HOE_PRICE

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var show_hoe := func():
		_show_info_modal({
			"title": "Cuốc Cày Đất",
			"desc": "Nông cụ thiết yếu của nhà nông",
			"icon": TextureGen.hoe_icon(),
			"type": "buy_hoe",
			"id": "hoe",
			"price": HOE_PRICE,
			"lines": [
				"🛠️ Dùng xới đất cỏ thành đất trồng rau màu",
				"🌱 Mỗi cuốc cày được 1 ô đất canh tác",
				"💰 Giá mua: %d xu/cái" % HOE_PRICE,
				"🎒 Số lượng đang có: %d cái" % Inventory.hoes
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
	badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.06, 0.90), UIKit.COLOR_BORDER_GOLD, 4))
	badge.mouse_filter = Control.MOUSE_FILTER_PASS
	var bl := UIKit.label(badge, "x%d" % Inventory.hoes, 11, UIKit.COLOR_TEXT_GOLD)
	bl.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(badge)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(sp)

	var info_btn := _create_info_circle_button(show_hoe)
	top_h.add_child(info_btn)

	var ic := TextureRect.new()
	ic.texture = TextureGen.hoe_icon()
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = "Cuốc Cày Đất"
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	_make_card_clickable(card, ic, name_l, show_hoe)

	var buy_btn := Button.new()
	buy_btn.text = "%d 🪙" % total if qty > 1 else "%d 🪙" % HOE_PRICE
	buy_btn.custom_minimum_size = Vector2(0, 26)
	buy_btn.add_theme_font_size_override("font_size", 12)
	buy_btn.add_theme_stylebox_override("normal", UIKit.shop_price_pill(Color(0.14, 0.24, 0.12), Color(0.35, 0.55, 0.30)))
	buy_btn.add_theme_stylebox_override("hover", UIKit.shop_price_pill(Color(0.20, 0.34, 0.18), Color(0.50, 0.75, 0.40)))
	buy_btn.add_theme_stylebox_override("disabled", UIKit.shop_price_pill(Color(0.14, 0.11, 0.09), Color(0.28, 0.22, 0.18)))
	buy_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GOLD)
	buy_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.45))
	buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	buy_btn.disabled = (qty <= 0) or (GameState.money < total)
	buy_btn.pressed.connect(_buy_hoe)
	v.add_child(buy_btn)

	return card


func _build_feed_card() -> Control:
	var qty := _get_buy_qty(FEED_PRICE)
	var total := qty * FEED_PRICE

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var show_feed := func():
		_show_info_modal({
			"title": "Túi Cám Chăn Nuôi",
			"desc": "Thức ăn dinh dưỡng cho gia súc, gia cầm",
			"icon": TextureGen.get_feed_icon(),
			"type": "buy_feed",
			"id": "feed",
			"price": FEED_PRICE,
			"lines": [
				"🌾 Cho vật nuôi ăn để chúng mau lớn & sản sinh vật phẩm",
				"🐔 Dùng được cho Gà, Bò, Lợn, Cừu",
				"💰 Giá mua: %d xu/túi" % FEED_PRICE,
				"🎒 Số lượng đang có: %d túi" % Inventory.feed_count()
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
	badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.06, 0.90), UIKit.COLOR_BORDER_GOLD, 4))
	badge.mouse_filter = Control.MOUSE_FILTER_PASS
	var bl := UIKit.label(badge, "x%d" % Inventory.feed_count(), 11, UIKit.COLOR_TEXT_GOLD)
	bl.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(badge)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(sp)

	var info_btn := _create_info_circle_button(show_feed)
	top_h.add_child(info_btn)

	var ic := TextureRect.new()
	ic.texture = TextureGen.get_feed_icon()
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = "Túi Cám Nuôi"
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	_make_card_clickable(card, ic, name_l, show_feed)

	var buy_btn := Button.new()
	buy_btn.text = "%d 🪙" % total if qty > 1 else "%d 🪙" % FEED_PRICE
	buy_btn.custom_minimum_size = Vector2(0, 26)
	buy_btn.add_theme_font_size_override("font_size", 12)
	buy_btn.add_theme_stylebox_override("normal", UIKit.shop_price_pill(Color(0.14, 0.24, 0.12), Color(0.35, 0.55, 0.30)))
	buy_btn.add_theme_stylebox_override("hover", UIKit.shop_price_pill(Color(0.20, 0.34, 0.18), Color(0.50, 0.75, 0.40)))
	buy_btn.add_theme_stylebox_override("disabled", UIKit.shop_price_pill(Color(0.14, 0.11, 0.09), Color(0.28, 0.22, 0.18)))
	buy_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GOLD)
	buy_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.45))
	buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	buy_btn.disabled = (qty <= 0) or (GameState.money < total)
	buy_btn.pressed.connect(_buy_feed)
	v.add_child(buy_btn)

	return card


func _build_backpack_card() -> Control:
	var cost := Inventory.get_backpack_upgrade_cost()
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var show_bp := func():
		_show_info_modal({
			"title": "Mở Rộng Túi Đồ (Balo)",
			"desc": "Gia tăng số lượng ngăn chứa mang theo",
			"icon": TextureGen.backpack_icon(),
			"type": "buy_backpack",
			"id": "backpack",
			"price": cost,
			"lines": [
				"🎒 Sức chứa hiện tại: %d/64 ô" % Inventory.backpack_max,
				"📦 Mỗi lần nâng mở thêm 8 ngăn chứa đồ",
				"💰 Chi phí nâng cấp: %d xu" % cost
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
	badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.06, 0.90), UIKit.COLOR_BORDER_GOLD, 4))
	badge.mouse_filter = Control.MOUSE_FILTER_PASS
	var bl := UIKit.label(badge, "%d ô" % Inventory.backpack_max, 11, UIKit.COLOR_TEXT_GOLD)
	bl.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(badge)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(sp)

	var info_btn := _create_info_circle_button(show_bp)
	top_h.add_child(info_btn)

	var ic := TextureRect.new()
	ic.texture = TextureGen.backpack_icon()
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = "Mở Rộng Balo"
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	_make_card_clickable(card, ic, name_l, show_bp)

	var up_btn := Button.new()
	if Inventory.backpack_max >= Inventory.BACKPACK_MAX_LIMIT:
		up_btn.text = "Tối đa"
		up_btn.disabled = true
	else:
		up_btn.text = "+ %d 🪙" % cost
		up_btn.disabled = GameState.money < cost

	up_btn.custom_minimum_size = Vector2(0, 26)
	up_btn.add_theme_font_size_override("font_size", 12)
	up_btn.add_theme_stylebox_override("normal", UIKit.shop_price_pill(Color(0.14, 0.24, 0.12), Color(0.35, 0.55, 0.30)))
	up_btn.add_theme_stylebox_override("hover", UIKit.shop_price_pill(Color(0.20, 0.34, 0.18), Color(0.50, 0.75, 0.40)))
	up_btn.add_theme_stylebox_override("disabled", UIKit.shop_price_pill(Color(0.14, 0.11, 0.09), Color(0.28, 0.22, 0.18)))
	up_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GOLD)
	up_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.45))
	up_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	up_btn.pressed.connect(func():
		var res := Inventory.upgrade_backpack()
		if res.get("ok", false):
			feedback.emit(str(res.get("msg", "")))
			refresh()
		else:
			feedback.emit(str(res.get("msg", "")))
	)
	v.add_child(up_btn)

	return card


func _build_produce_card(crop: Dictionary) -> Control:
	var cid := str(crop.id)
	var prod_count := Inventory.produce_count(cid)
	var price := int(crop.sell_price)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var show_produce := func():
		_show_info_modal({
			"title": crop.name,
			"desc": "Nông sản tươi ngon từ đồng ruộng",
			"icon": TextureGen.prod_icon(crop),
			"type": "sell_produce",
			"id": cid,
			"price": price,
			"crop": crop,
			"lines": [
				"🌾 Giá Bác Tư thu mua: %d xu/cái" % price,
				"🌱 Phân nhóm: %s" % str(crop.group),
				"🎒 Đang có trong túi: %d cái" % prod_count,
				"💰 Tổng giá trị: %d xu" % (prod_count * price)
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
	if prod_count > 0:
		badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.32, 0.18, 0.08), UIKit.COLOR_BORDER_GOLD, 4))
		var bl := UIKit.label(badge, "Có: %d" % prod_count, 10, UIKit.COLOR_TEXT_GOLD)
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

	var info_btn := _create_info_circle_button(show_produce)
	top_h.add_child(info_btn)

	var ic := TextureRect.new()
	ic.texture = TextureGen.prod_icon(crop)
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = crop.name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	_make_card_clickable(card, ic, name_l, show_produce)

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
	sell_btn.disabled = prod_count < 1
	sell_btn.pressed.connect(func():
		_sell(cid, false)
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


# ---------------- Hàm Logic Mua / Bán ----------------

func _total_produce_value() -> int:
	var total := 0
	for crop in CropDB.CROPS:
		var n := Inventory.produce_count(str(crop.id))
		total += n * int(crop.sell_price)
	return total


func _sell_all_produce() -> void:
	var total := 0
	var count := 0
	for crop in CropDB.CROPS:
		var cid := str(crop.id)
		var n := Inventory.produce_count(cid)
		if n > 0 and Inventory.take_produce(cid, n):
			total += n * int(crop.sell_price)
			count += n
	if total > 0:
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		GameState.add_money(total)
		feedback.emit("Đã bán %d nông sản các loại (+%d xu)! 🌾" % [count, total])
		refresh()


func _buy(id: String) -> void:
	var c := CropDB.get_crop(id)
	var price := int(c.seed_price)
	var qty := _get_buy_qty(price)
	if qty <= 0:
		feedback.emit("Không đủ xu để mua hạt %s!" % c.name)
		return
	if not Inventory.can_hold("seed", id):
		feedback.emit("Túi đồ đã đầy (%d/%d)! Hãy cất bớt đồ vào nhà kho 🏚️" % [Inventory.backpack_slots_used(), Inventory.backpack_max])
		return
	var total_cost := qty * price
	if GameState.try_spend(total_cost):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		Inventory.add_seed(id, qty)
		feedback.emit("Đã mua %d hạt giống %s (-%d xu) 🌱" % [qty, c.name, total_cost])
		refresh()
	else:
		feedback.emit("Không đủ xu để mua %d hạt %s (cần %d xu)!" % [qty, c.name, total_cost])


func _sell(id: String, all: bool) -> void:
	var c := CropDB.get_crop(id)
	var have := Inventory.produce_count(id)
	if have < 1:
		return
	var n := have if all else 1
	if Inventory.take_produce(id, n):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		GameState.add_money(int(c.sell_price) * n)
		refresh()
		if all:
			feedback.emit("Đã bán %d %s (+%d xu)" % [n, c.name, int(c.sell_price) * n])
		else:
			feedback.emit("Đã bán 1 %s (+%d xu) 🌾" % [c.name, int(c.sell_price)])


func _buy_hoe() -> void:
	var qty := _get_buy_qty(HOE_PRICE)
	if qty <= 0:
		feedback.emit("Không đủ xu để mua cuốc!")
		return
	if not Inventory.can_hold("hoe", "hoe"):
		feedback.emit("Túi đồ đã đầy (%d/%d)! Hãy cất bớt đồ vào nhà kho 🏚️" % [Inventory.backpack_slots_used(), Inventory.backpack_max])
		return
	var total_cost := qty * HOE_PRICE
	if GameState.try_spend(total_cost):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		Inventory.add_hoes(qty)
		feedback.emit("Đã mua %d cuốc cày đất (-%d xu) 🛠️" % [qty, total_cost])
		refresh()
	else:
		feedback.emit("Không đủ xu mua %d cuốc (cần %d xu)!" % [qty, total_cost])


func _buy_feed() -> void:
	var qty := _get_buy_qty(FEED_PRICE)
	if qty <= 0:
		feedback.emit("Không đủ xu để mua túi cám!")
		return
	if not Inventory.can_hold("feed", "feed"):
		feedback.emit("Túi đồ đã đầy (%d/%d)! Hãy cất bớt đồ vào nhà kho 🏚️" % [Inventory.backpack_slots_used(), Inventory.backpack_max])
		return
	var total_cost := qty * FEED_PRICE
	if GameState.try_spend(total_cost):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		Inventory.add_feed(qty)
		feedback.emit("Đã mua %d túi cám chăn nuôi (-%d xu) 🌾" % [qty, total_cost])
		refresh()
	else:
		feedback.emit("Không đủ xu mua %d túi cám (cần %d xu)!" % [qty, total_cost])


func _unlock() -> void:
	var c := GameState.next_locked()
	if GameState.unlock_next():
		feedback.emit("ĐÃ MỞ KHÓA: %s!" % c.get("name", "?"))
		refresh()
		scroll.scroll_vertical = 0


# Giữ phương thức tương thích ngược cho test cũ
func _build_owned_row(crop: Dictionary) -> Control:
	return _build_seed_card(crop)
