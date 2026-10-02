extends CanvasLayer
# HUD Nông Trại: Bảng trạng thái gỗ mộc, thanh hotbar hạt giống, gợi ý thao tác & thông báo cuộn giấy.

const CropDB := preload("res://scripts/crop_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

var clock_label: Label
var day_label: Label
var money_label: Label
var hoe_label: Label
var hint_container: PanelContainer
var hint_label: Label
var seed_label: Label
var toast_row: VBoxContainer
var hotbar_row: HBoxContainer
var _group: ButtonGroup


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- 1. KHỐI TRẠNG THÁI GỖ TRÊN TRÁI (Bảng nông dân) ---
	var tl := PanelContainer.new()
	tl.add_theme_stylebox_override("panel", UIKit.wood_frame(10, 2, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	tl.position = Vector2(16, 16)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tl)

	var v_status := VBoxContainer.new()
	v_status.add_theme_constant_override("separation", 6)
	v_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(v_status)

	# Hàng 1: Ngày & Giờ với icon
	var h_time := HBoxContainer.new()
	h_time.add_theme_constant_override("separation", 10)
	h_time.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_status.add_child(h_time)

	# Huy hiệu Ngày
	var day_pill := PanelContainer.new()
	day_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.22, 0.15, 0.10), UIKit.COLOR_BORDER_WOOD, 6))
	day_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h_time.add_child(day_pill)
	var h_day := HBoxContainer.new()
	h_day.add_theme_constant_override("separation", 5)
	day_pill.add_child(h_day)
	var day_ic := TextureRect.new()
	day_ic.texture = TextureGen.calendar_icon()
	day_ic.custom_minimum_size = Vector2(16, 16)
	day_ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	h_day.add_child(day_ic)
	day_label = UIKit.label(h_day, "Ngày 1", 14, UIKit.COLOR_TEXT_TITLE)

	# Huy hiệu Đồng hồ
	var clock_pill := PanelContainer.new()
	clock_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.22, 0.15, 0.10), UIKit.COLOR_BORDER_WOOD, 6))
	clock_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h_time.add_child(clock_pill)
	var h_clk := HBoxContainer.new()
	h_clk.add_theme_constant_override("separation", 5)
	clock_pill.add_child(h_clk)
	var clk_ic := TextureRect.new()
	clk_ic.texture = TextureGen.clock_icon()
	clk_ic.custom_minimum_size = Vector2(16, 16)
	clk_ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	h_clk.add_child(clk_ic)
	clock_label = UIKit.label(h_clk, "07:00", 15, Color(0.90, 0.95, 1.0))

	# Hàng 2: Tiền vàng & Cuốc xới đất
	var h_assets := HBoxContainer.new()
	h_assets.add_theme_constant_override("separation", 10)
	h_assets.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_status.add_child(h_assets)

	# Túi tiền
	var money_pill := PanelContainer.new()
	money_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.25, 0.18, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	money_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h_assets.add_child(money_pill)
	var h_m := HBoxContainer.new()
	h_m.add_theme_constant_override("separation", 5)
	money_pill.add_child(h_m)
	var m_ic := TextureRect.new()
	m_ic.texture = TextureGen.coin_icon()
	m_ic.custom_minimum_size = Vector2(16, 16)
	m_ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	h_m.add_child(m_ic)
	money_label = UIKit.label(h_m, "100 xu", 15, UIKit.COLOR_TEXT_GOLD)

	# Túi cuốc
	var hoe_pill := PanelContainer.new()
	hoe_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.16, 0.12), UIKit.COLOR_BORDER_WOOD, 6))
	hoe_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h_assets.add_child(hoe_pill)
	var h_h := HBoxContainer.new()
	h_h.add_theme_constant_override("separation", 5)
	hoe_pill.add_child(h_h)
	var h_ic := TextureRect.new()
	h_ic.texture = TextureGen.hoe_icon()
	h_ic.custom_minimum_size = Vector2(16, 16)
	h_ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	h_h.add_child(h_ic)
	hoe_label = UIKit.label(h_h, "Cuốc ×0", 14, Color(0.90, 0.82, 0.70))

	# --- 2. THÔNG BÁO CUỘN GIẤY PHẢI PHÍA DƯỚI BẢN ĐỒ NHỎ ---
	var tr := MarginContainer.new()
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.offset_left = -340
	tr.offset_right = -16
	tr.offset_top = 344
	tr.offset_bottom = 648
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tr)
	toast_row = VBoxContainer.new()
	toast_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	toast_row.add_theme_constant_override("separation", 6)
	toast_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.add_child(toast_row)

	# --- 3. GỢI Ý HÀNH ĐỘNG (Floating Wood Pill) ---
	var hint_center := CenterContainer.new()
	hint_center.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_center.offset_top = -140
	hint_center.offset_bottom = -96
	hint_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hint_center)

	hint_container = PanelContainer.new()
	hint_container.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.08, 0.05, 0.92), UIKit.COLOR_BORDER_GOLD, 8))
	hint_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_center.add_child(hint_container)

	var hint_h := HBoxContainer.new()
	hint_h.add_theme_constant_override("separation", 8)
	hint_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_container.add_child(hint_h)

	var key_ic := UIKit.key_badge(hint_h, "E")
	key_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE

	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
	hint_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.98))
	hint_label.add_theme_constant_override("outline_size", 4)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_h.add_child(hint_label)
	hint_container.visible = false

	# --- 4. THANH CÔNG CỤ & HẠT GIỐNG DƯỚI CÙNG (Hotbar Tray) ---
	var strip := CenterContainer.new()
	strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_top = -84
	strip.offset_bottom = -14
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(strip)

	var tray := PanelContainer.new()
	tray.add_theme_stylebox_override("panel", UIKit.wood_frame(12, 2, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	strip.add_child(tray)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	tray.add_child(hb)

	# Huy hiệu loại hạt đang cầm
	var seed_pill := PanelContainer.new()
	seed_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.09), UIKit.COLOR_BORDER_WOOD, 6))
	hb.add_child(seed_pill)
	seed_label = UIKit.label(seed_pill, "Hạt: ...", 14, UIKit.COLOR_TEXT_GREEN)

	# Danh sách các ô chọn hạt giống
	hotbar_row = HBoxContainer.new()
	hotbar_row.add_theme_constant_override("separation", 6)
	hb.add_child(hotbar_row)

	# Phím tắt phụ bên phải
	var tips_box := HBoxContainer.new()
	tips_box.add_theme_constant_override("separation", 6)
	hb.add_child(tips_box)
	UIKit.key_badge(tips_box, "I")
	UIKit.label(tips_box, "Kho đồ", 13, UIKit.COLOR_TEXT_MUTED)
	UIKit.label(tips_box, "·", 13, UIKit.COLOR_BORDER_WOOD)
	UIKit.key_badge(tips_box, "R")
	UIKit.label(tips_box, "Đổi nhanh", 13, UIKit.COLOR_TEXT_MUTED)

	_group = ButtonGroup.new()
	rebuild_hotbar()


func set_money(v: int) -> void:
	money_label.text = "%d xu" % v


func set_clock(txt: String) -> void:
	clock_label.text = txt
	day_label.text = "Ngày %d" % GameState.day


func set_hint(t: String) -> void:
	hint_label.text = t.trim_prefix("E: ")
	hint_container.visible = (t != "")


func rebuild_hotbar() -> void:
	hoe_label.text = "Cuốc ×%d" % Inventory.hoes
	day_label.text = "Ngày %d" % GameState.day

	for c in hotbar_row.get_children():
		c.queue_free()

	var ids: Array = Inventory.owned_seed_ids()
	if ids.is_empty():
		ids = GameState.unlocked.duplicate()

	var shown: int = mini(ids.size(), 7)
	for i in shown:
		var id := str(ids[i])
		var c := CropDB.get_crop(id)
		if c.is_empty():
			continue

		var is_selected := (Inventory.selected_seed == id)
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = _group
		b.icon = TextureGen.seed_icon(c)
		b.text = " %s ×%d" % [c.name, Inventory.seed_count(id)]
		b.add_theme_font_size_override("font_size", 13)
		b.custom_minimum_size = Vector2(0, 32)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		# Áp style slot mộc mạc
		b.add_theme_stylebox_override("normal", UIKit.slot_box(false))
		b.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.32, 0.22, 0.14), UIKit.COLOR_BORDER_BRIGHT, 6, 1))
		b.add_theme_stylebox_override("pressed", UIKit.slot_box(true))

		b.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
		b.add_theme_color_override("font_pressed_color", UIKit.COLOR_TEXT_TITLE)
		b.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
		b.add_theme_constant_override("outline_size", 2)

		b.button_pressed = is_selected
		b.pressed.connect(_select_seed.bind(id))
		hotbar_row.add_child(b)

	if ids.size() > shown:
		var more_pill := PanelContainer.new()
		more_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.09), UIKit.COLOR_BORDER_WOOD, 6))
		var more_l := UIKit.label(more_pill, "+%d loại (I)" % (ids.size() - shown), 12, UIKit.COLOR_TEXT_MUTED)
		hotbar_row.add_child(more_pill)

	_update_seed_label()


func _select_seed(id: String) -> void:
	Inventory.selected_seed = id
	_update_seed_label()


func _update_seed_label() -> void:
	var sid := Inventory.selected_seed
	if sid == "":
		seed_label.text = "Chưa chọn hạt"
		seed_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)
		return
	var c := CropDB.get_crop(sid)
	if c.is_empty():
		seed_label.text = "Hạt: ?"
		return
	seed_label.text = "%s ×%d" % [c.name, Inventory.seed_count(sid)]
	seed_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GREEN)


func toast(text: String, color := Color.WHITE) -> void:
	if toast_row.get_child_count() > 4:
		toast_row.get_child(0).queue_free()

	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.toast_box())
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)

	var bullet := TextureRect.new()
	bullet.texture = TextureGen.star_icon()
	bullet.custom_minimum_size = Vector2(14, 14)
	bullet.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	bullet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(bullet)

	var l := UIKit.label(h, text, 14, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE

	toast_row.add_child(p)

	# Hiệu ứng mượt mà xuất hiện và mờ dần
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.8)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)
