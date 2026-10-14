extends CanvasLayer
# Trại Giống Cô Tư: Giao diện thẻ lưới 3 cột hiện đại & Hộp thoại chi tiết (Phong cách Mobile Grid Card).

const PoultryDB := preload("res://scripts/poultry_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal feedback(text: String)

var money_label: Label
var rows: VBoxContainer
var scroll: ScrollContainer
var _current_cat := "animals" # "animals", "coops", "products"
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

	# Khung cửa hàng neo sát lề phải màn hình (chống trôi ra ngoài màn hình)
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

	# --- Tiêu đề Cửa Hàng ---
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(head)

	var title := UIKit.title_label(head, "TRẠI GIỐNG CÔ TƯ", 22, UIKit.COLOR_TEXT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# --- 3 Tab: Mua giống, Chuồng & Cám, Bán sản phẩm ---
	var tabs_box := PanelContainer.new()
	tabs_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.08, 0.05, 0.85), UIKit.COLOR_BORDER_WOOD, 8))
	v.add_child(tabs_box)

	var cat_h := HBoxContainer.new()
	cat_h.add_theme_constant_override("separation", 6)
	tabs_box.add_child(cat_h)

	var cats := [
		{"key": "animals", "label": "🐣 Mua giống"},
		{"key": "coops", "label": "🏡 Chuồng & Cám"},
		{"key": "products", "label": "🧺 Bán sản phẩm"},
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
	var aid: String = str(data.get("id", ""))
	var price: int = int(data.get("price", 0))

	match type:
		"buy_animal":
			var tier := Inventory.get_coop_tier(aid)
			var slots := Inventory.free_slots(aid)
			var can_buy := (tier > 0) and (slots > 0) and (GameState.money >= price)
			var btn := Button.new()
			btn.text = "+ Mua Con Giống (%d xu)" % price
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 36)
			btn.add_theme_font_size_override("font_size", 14)
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.55, 0.85, 0.45), 8, 2))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.65, 0.95, 0.55), 8, 2))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.disabled = not can_buy
			btn.pressed.connect(func():
				_buy_animal(aid)
				_hide_info_modal()
			)
			_modal_action_h.add_child(btn)

		"coop_tier":
			var coop_data: Dictionary = data.get("coop_data", {})
			var tier := Inventory.get_coop_tier(aid)
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 36)
			btn.add_theme_font_size_override("font_size", 14)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

			if tier == 0:
				var t1_cost := int(coop_data.get("tier1_price", 200))
				btn.text = "+ Mua Chuồng Cấp 1 (%d xu)" % t1_cost
				btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.55, 0.85, 0.45), 8, 2))
				btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.65, 0.95, 0.55), 8, 2))
				btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
				btn.disabled = GameState.money < t1_cost
				btn.pressed.connect(func():
					_buy_coop(aid)
					_hide_info_modal()
				)
			elif tier < 4:
				var next_tier := tier + 1
				var up_cost := PoultryDB.get_coop_upgrade_price(aid, next_tier)
				btn.text = "▲ Nâng Cấp Cấp %d (%d xu)" % [next_tier, up_cost]
				btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.48, 0.32, 0.15), UIKit.COLOR_BORDER_BRIGHT, 8, 2))
				btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.60, 0.42, 0.20), UIKit.COLOR_BORDER_BRIGHT, 8, 2))
				btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
				btn.disabled = GameState.money < up_cost
				btn.pressed.connect(func():
					_upgrade_coop(aid)
					_hide_info_modal()
				)
			else:
				btn.text = "✔ Đã Đạt Tối Đa (Cấp 4)"
				btn.disabled = true

			_modal_action_h.add_child(btn)

		"buy_feed":
			var btn := Button.new()
			btn.text = "+ Mua 5 Túi Cám (75 xu)"
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 36)
			btn.add_theme_font_size_override("font_size", 14)
			btn.add_theme_stylebox_override("normal", UIKit.btn_style(UIKit.BTN_BUY_BG, Color(0.55, 0.85, 0.45), 8, 2))
			btn.add_theme_stylebox_override("hover", UIKit.btn_style(UIKit.BTN_BUY_HOVER, Color(0.65, 0.95, 0.55), 8, 2))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.disabled = GameState.money < 75
			btn.pressed.connect(func():
				if GameState.try_spend(75):
					if has_node("/root/AudioManager"):
						get_node("/root/AudioManager").play_sfx("coin")
					Inventory.add_feed(5)
					feedback.emit("Đã mua 5 Túi Cám (-75 xu)! 🌾")
					refresh()
					_hide_info_modal()
			)
			_modal_action_h.add_child(btn)

		"sell_product":
			var count := Inventory.produce_count(aid)
			var pname: String = str(data.get("pname", ""))
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
				_sell_product(aid, price, pname, false)
				_hide_info_modal()
			)
			_modal_action_h.add_child(sell1)

			var sell_all := Button.new()
			sell_all.text = "Bán Hết (%d cái)" % count
			sell_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sell_all.custom_minimum_size = Vector2(0, 36)
			sell_all.add_theme_font_size_override("font_size", 13)
			sell_all.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.32, 0.18, 0.08), Color(0.90, 0.55, 0.25), 8, 2))
			sell_all.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.42, 0.24, 0.12), Color(1.0, 0.65, 0.35), 8, 2))
			sell_all.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
			sell_all.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			sell_all.disabled = count < 1
			sell_all.pressed.connect(func():
				_sell_product(aid, price, pname, true)
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
	for k in ["animals", "coops", "products"]:
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


func refresh() -> void:
	money_label.text = "%d xu" % GameState.money
	for c in rows.get_children():
		rows.remove_child(c)
		c.queue_free()

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 1. TAB CON GIỐNG (animals)
	if _current_cat == "animals":
		for a in PoultryDB.ANIMALS:
			grid.add_child(_build_animal_card(a))

	# 2. TAB CHUỒNG TRẠI & CÁM (coops)
	elif _current_cat == "coops":
		for cid in ["cow", "chicken", "sheep", "pig"]:
			var cdata := PoultryDB.get_coop_data(cid)
			if not cdata.is_empty():
				grid.add_child(_build_coop_card(cdata))
		grid.add_child(_build_feed_card())

	# 3. TAB BÁN SẢN PHẨM CHĂN NUÔI (products)
	elif _current_cat == "products":
		var total_val := _total_product_value()
		if total_val > 0:
			var sell_all_btn := UIKit.styled_button(rows, "⭐ BÁN HẾT SẢN PHẨM (+%d xu)" % total_val, 13, "sell")
			sell_all_btn.custom_minimum_size = Vector2(0, 36)
			sell_all_btn.pressed.connect(_sell_all_products)

		for pinfo in PoultryDB.PRODUCTS:
			grid.add_child(_build_product_card(pinfo))

	rows.add_child(grid)


# ---------------- Thẻ Lưới Cho Trại Giống (Grid Cards) ----------------

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


func _build_animal_card(a: Dictionary) -> Control:
	var aid := str(a.id)
	var price := int(a.price)
	var tier := Inventory.get_coop_tier(aid)
	var slots := Inventory.free_slots(aid)
	var count := Inventory.animals_of_species(aid)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var show_animal := func():
		var coop_data := PoultryDB.get_coop_data(aid)
		var cname := str(coop_data.get("name", "Chuồng"))
		_show_info_modal({
			"title": str(a.name),
			"desc": "Vật nuôi thuần chủng khỏe mạnh",
			"icon": TextureGen.get_animal_icon(aid),
			"type": "buy_animal",
			"id": aid,
			"price": price,
			"lines": [
				"🏡 Chuồng yêu cầu: %s (Cấp %d)" % [cname, tier],
				"📦 Sức chứa trống: %d chỗ" % slots if tier > 0 else "❌ Cần mua %s trước" % cname,
				"🥛 Sản phẩm tạo ra: %s" % (str(a.product_name) if str(a.product_name) != "" else "Thịt khi trưởng thành"),
				"💰 Giá con giống: %d xu" % price
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
	if tier == 0:
		badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.36, 0.24, 0.10), UIKit.COLOR_BORDER_GOLD, 4))
		var bl := UIKit.label(badge, "Chưa chuồng", 9, UIKit.COLOR_TEXT_GOLD)
		bl.mouse_filter = Control.MOUSE_FILTER_PASS
	elif slots <= 0:
		badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.36, 0.14, 0.12), Color(0.85, 0.45, 0.40), 4))
		var bl := UIKit.label(badge, "Đầy: %d" % count, 10, Color(1.0, 0.8, 0.8))
		bl.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.06, 0.90), UIKit.COLOR_BORDER_GOLD, 4))
		var bl := UIKit.label(badge, "Nuôi: %d" % count, 10, UIKit.COLOR_TEXT_GOLD)
		bl.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(badge)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(sp)

	var info_btn := _create_info_circle_button(show_animal)
	top_h.add_child(info_btn)

	var ic := TextureRect.new()
	ic.texture = TextureGen.get_animal_icon(aid)
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = str(a.name)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	_make_card_clickable(card, ic, name_l, show_animal)

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
	buy_btn.disabled = (tier == 0 or slots < 1 or GameState.money < price)
	buy_btn.pressed.connect(_buy_animal.bind(aid))
	v.add_child(buy_btn)

	return card


func _build_coop_card(coop: Dictionary) -> Control:
	var cid := str(coop.id)
	var tier := Inventory.get_coop_tier(cid)
	var count := Inventory.animals_of_species(cid)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var show_coop := func():
		var desc_lines := [
			"🏡 Hiện tại: %s" % ("Chưa mua" if tier == 0 else "Cấp %d (Sức chứa %d con)" % [tier, Inventory.coop_capacity(cid)]),
			"🐾 Số vật nuôi đang ở: %d con" % count
		]
		if tier < 4:
			var next_t := tier + 1
			var up_cost: int = int(coop.tier1_price) if tier == 0 else PoultryDB.get_coop_upgrade_price(cid, next_t)
			desc_lines.append("▲ Lên Cấp %d: %d xu (Chứa %d con)" % [next_t, up_cost, PoultryDB.get_coop_capacity(cid, next_t)])
		else:
			desc_lines.append("✔ Đã đạt cấp tối đa (16 con)")

		_show_info_modal({
			"title": str(coop.name),
			"desc": "Khu chuồng trại chăn nuôi gia súc, gia cầm",
			"icon": TextureGen.get_tex("coop_tier2" if tier >= 2 else "coop_tier1") if cid == "chicken" else TextureGen.get_tex("barn_tier2" if tier >= 2 else "barn_tier1"),
			"type": "coop_tier",
			"id": cid,
			"coop_data": coop,
			"lines": desc_lines
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
	if tier == 0:
		badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.10), UIKit.COLOR_BORDER_WOOD, 4))
		var bl := UIKit.label(badge, "Chưa mua", 10, UIKit.COLOR_TEXT_MUTED)
		bl.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.24, 0.12), Color(0.35, 0.55, 0.30), 4))
		var bl := UIKit.label(badge, "Cấp %d (%d/%d)" % [tier, count, Inventory.coop_capacity(cid)], 10, Color(0.75, 0.95, 0.70))
		bl.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(badge)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_PASS
	top_h.add_child(sp)

	var info_btn := _create_info_circle_button(show_coop)
	top_h.add_child(info_btn)

	var ic := TextureRect.new()
	if cid == "chicken":
		ic.texture = TextureGen.get_tex("coop_tier2" if tier >= 2 else "coop_tier1")
	else:
		ic.texture = TextureGen.get_tex("barn_tier2" if tier >= 2 else "barn_tier1")
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = str(coop.name)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	_make_card_clickable(card, ic, name_l, show_coop)

	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(0, 26)
	action_btn.add_theme_font_size_override("font_size", 11)
	action_btn.add_theme_stylebox_override("normal", UIKit.shop_price_pill(Color(0.28, 0.18, 0.08), UIKit.COLOR_BORDER_GOLD))
	action_btn.add_theme_stylebox_override("hover", UIKit.shop_price_pill(Color(0.38, 0.26, 0.12), UIKit.COLOR_BORDER_BRIGHT))
	action_btn.add_theme_stylebox_override("disabled", UIKit.shop_price_pill(Color(0.14, 0.11, 0.09), Color(0.28, 0.22, 0.18)))
	action_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GOLD)
	action_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.45))
	action_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if tier == 0:
		var price := int(coop.tier1_price)
		action_btn.text = "+ %d 🪙" % price
		action_btn.disabled = GameState.money < price
		action_btn.pressed.connect(_buy_coop.bind(cid))
	elif tier < 4:
		var next_t := tier + 1
		var price := PoultryDB.get_coop_upgrade_price(cid, next_t)
		action_btn.text = "▲ %d 🪙" % price
		action_btn.disabled = GameState.money < price
		action_btn.pressed.connect(_upgrade_coop.bind(cid))
	else:
		action_btn.text = "Tối đa"
		action_btn.disabled = true
	v.add_child(action_btn)

	return card


func _build_feed_card() -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var show_feed := func():
		_show_info_modal({
			"title": "Túi Cám Nuôi",
			"desc": "Thức ăn dinh dưỡng Stardew Valley",
			"icon": TextureGen.get_feed_icon(),
			"type": "buy_feed",
			"lines": [
				"🌾 Cho ăn để vật nuôi no bụng và cho sản phẩm",
				"🐔 Thích hợp cho Gà, Bò, Lợn, Cừu",
				"💰 Giá: %d xu/túi" % PoultryDB.FEED_PRICE,
				"🎒 Đang có: %d túi" % Inventory.feed_count()
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
	name_l.text = "Túi Cám"
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	_make_card_clickable(card, ic, name_l, show_feed)

	var buy_btn := Button.new()
	buy_btn.text = "%d 🪙" % PoultryDB.FEED_PRICE
	buy_btn.custom_minimum_size = Vector2(0, 26)
	buy_btn.add_theme_font_size_override("font_size", 12)
	buy_btn.add_theme_stylebox_override("normal", UIKit.shop_price_pill(Color(0.14, 0.24, 0.12), Color(0.35, 0.55, 0.30)))
	buy_btn.add_theme_stylebox_override("hover", UIKit.shop_price_pill(Color(0.20, 0.34, 0.18), Color(0.50, 0.75, 0.40)))
	buy_btn.add_theme_stylebox_override("disabled", UIKit.shop_price_pill(Color(0.14, 0.11, 0.09), Color(0.28, 0.22, 0.18)))
	buy_btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GOLD)
	buy_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.45))
	buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	buy_btn.disabled = GameState.money < PoultryDB.FEED_PRICE
	buy_btn.pressed.connect(func():
		if GameState.try_spend(PoultryDB.FEED_PRICE):
			if has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_sfx("coin")
			Inventory.add_feed(1)
			feedback.emit("Đã mua 1 Túi Cám (-%d xu) 🌾" % PoultryDB.FEED_PRICE)
			refresh()
	)
	v.add_child(buy_btn)

	return card


func _build_product_card(pinfo: Dictionary) -> Control:
	var pid := str(pinfo.id)
	var price := int(pinfo.price)
	var count := Inventory.produce_count(pid)
	var pname := str(pinfo.name)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 150)
	card.add_theme_stylebox_override("panel", UIKit.shop_card_box(false))

	var show_product := func():
		_show_info_modal({
			"title": pname,
			"desc": str(pinfo.get("desc", "Sản phẩm chăn nuôi")),
			"icon": TextureGen.get_product_icon(pid),
			"type": "sell_product",
			"id": pid,
			"price": price,
			"pname": pname,
			"lines": [
				"🧺 Giá Cô Tư thu mua: %d xu/cái" % price,
				"🎒 Đang có trong túi: %d cái" % count,
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

	var info_btn := _create_info_circle_button(show_product)
	top_h.add_child(info_btn)

	var ic := TextureRect.new()
	ic.texture = TextureGen.get_product_icon(pid)
	ic.custom_minimum_size = Vector2(44, 44)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	v.add_child(ic)

	var name_l := Label.new()
	name_l.text = pname
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 12)
	name_l.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	name_l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	name_l.add_theme_constant_override("outline_size", 2)
	v.add_child(name_l)

	_make_card_clickable(card, ic, name_l, show_product)

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
		_sell_product(pid, price, pname, false)
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


# ---------------- Logic Mua / Bán / Nâng Cấp ----------------

func _total_product_value() -> int:
	var total := 0
	for p in PoultryDB.PRODUCTS:
		var pid := str(p.id)
		var n := Inventory.produce_count(pid)
		total += n * int(p.price)
	return total


func _sell_all_products() -> void:
	var total := 0
	var count := 0
	for p in PoultryDB.PRODUCTS:
		var pid := str(p.id)
		var n := Inventory.produce_count(pid)
		if n > 0 and Inventory.take_produce(pid, n):
			total += n * int(p.price)
			count += n
	if total > 0:
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		GameState.add_money(total)
		feedback.emit("Đã bán %d sản phẩm chăn nuôi (+%d xu)! 🧺" % [count, total])
		refresh()


func _buy_animal(aid: String) -> void:
	var a := PoultryDB.get_animal(aid)
	if a.is_empty():
		return
	var price := int(a.price)
	var tier := Inventory.get_coop_tier(aid)
	var slots := Inventory.free_slots(aid)

	if tier == 0:
		feedback.emit("Chưa có chuồng cho %s! Hãy mua chuồng Cấp 1 trước." % a.name)
		return
	if slots < 1:
		feedback.emit("Chuồng %s đã kín chỗ! Hãy nâng cấp chuồng." % a.name)
		return
	if GameState.try_spend(price):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		Inventory.add_animal(aid)
		feedback.emit("Đã mua 1 %s (-%d xu)! Hãy ra chuồng chăm sóc." % [a.name, price])
		refresh()
	else:
		feedback.emit("Không đủ xu để mua %s (cần %d xu)!" % [a.name, price])


func _buy_coop(cid: String) -> void:
	var cdata := PoultryDB.get_coop_data(cid)
	var price := int(cdata.tier1_price)
	if GameState.try_spend(price):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		Inventory.set_coop_tier(cid, 1)
		feedback.emit("Đã dựng %s Cấp 1 (-%d xu) thành công! 🏡" % [cdata.name, price])
		refresh()
	else:
		feedback.emit("Không đủ xu để mua %s (cần %d xu)!" % [cdata.name, price])


func _upgrade_coop(cid: String) -> void:
	var tier := Inventory.get_coop_tier(cid)
	var next_tier := tier + 1
	var price := PoultryDB.get_coop_upgrade_price(cid, next_tier)
	if GameState.try_spend(price):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		Inventory.set_coop_tier(cid, next_tier)
		feedback.emit("Đã nâng cấp %s lên Cấp %d (-%d xu) (Sức chứa %d con)!" % [PoultryDB.get_coop_data(cid).name, next_tier, price, PoultryDB.get_coop_capacity(cid, next_tier)])
		refresh()
	else:
		feedback.emit("Không đủ xu để nâng cấp (cần %d xu)!" % price)


func _sell_product(pid: String, price: int, pname: String, all: bool) -> void:
	var have := Inventory.produce_count(pid)
	if have < 1:
		return
	var n := have if all else 1
	if Inventory.take_produce(pid, n):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("coin")
		var gain := price * n
		GameState.add_money(gain)
		feedback.emit("Đã bán %d %s (+%d xu)!" % [n, pname, gain])
		refresh()
