extends CanvasLayer
# HUD Nông Trại: Bảng trạng thái gỗ mộc, thanh hotbar hạt giống, gợi ý thao tác & thông báo cuộn giấy.

const CropDB := preload("res://scripts/crop_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal open_inventory_requested
signal open_storage_requested
signal open_cat_requested
signal open_stall_requested

var clock_label: Label
var day_label: Label
var money_label: Label
var hoe_label: Label
var water_label: Label
var hint_container: PanelContainer
var hint_label: Label
var active_label: Label
var seed_label: Label
var toast_row: VBoxContainer
var hotbar_row: HBoxContainer
var _group: ButtonGroup
var _slots_cache: Array[Dictionary] = []


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

	# Bình nước
	var water_pill := PanelContainer.new()
	water_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.18, 0.24), Color(0.3, 0.6, 0.8), 6))
	water_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h_assets.add_child(water_pill)
	var h_w := HBoxContainer.new()
	h_w.add_theme_constant_override("separation", 5)
	water_pill.add_child(h_w)
	var w_ic := TextureRect.new()
	w_ic.texture = TextureGen.watering_can_icon()
	w_ic.custom_minimum_size = Vector2(16, 16)
	w_ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	h_w.add_child(w_ic)
	water_label = UIKit.label(h_w, "Nước 20/20", 14, Color(0.70, 0.90, 1.0))

	# --- 1b. NÚT NHANH CẠNH MÀN HÌNH: Quản lý Mèo [M], Nhà kho [K] ---
	var quick_dock := PanelContainer.new()
	quick_dock.add_theme_stylebox_override("panel", UIKit.wood_frame(6, 2, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	quick_dock.position = Vector2(16, 120)
	root.add_child(quick_dock)

	var qv := VBoxContainer.new()
	qv.add_theme_constant_override("separation", 6)
	quick_dock.add_child(qv)

	_make_quick_btn(qv, "M", TextureGen.cat_char_tex("down", 0), "Quản lý Mèo [M]", func():
		open_cat_requested.emit()
	)
	_make_quick_btn(qv, "K", TextureGen.get_tex("shed"), "Nhà kho [K]", func():
		open_storage_requested.emit()
	)

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

	# --- 4. THANH CÔNG CỤ DƯỚI CÙNG (Hotbar Tray - Gọn gàng, chỉ icon và số) ---
	var strip := CenterContainer.new()
	strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_top = -68
	strip.offset_bottom = -12
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(strip)

	var tray := PanelContainer.new()
	tray.add_theme_stylebox_override("panel", UIKit.wood_frame(8, 2, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	strip.add_child(tray)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	tray.add_child(hb)

	active_label = Label.new()
	seed_label = active_label

	# Danh sách các ô chọn công cụ & hạt giống
	hotbar_row = HBoxContainer.new()
	hotbar_row.add_theme_constant_override("separation", 5)
	hb.add_child(hotbar_row)

	# Nút mở kho đồ dạng ô vuông Stardew Valley [I]
	var inv_btn := Button.new()
	inv_btn.custom_minimum_size = Vector2(46, 46)
	inv_btn.tooltip_text = "Kho đồ [I]"
	inv_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	inv_btn.add_theme_stylebox_override("normal", UIKit.slot_box(false))
	inv_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.32, 0.22, 0.14), UIKit.COLOR_BORDER_BRIGHT, 6, 1))
	inv_btn.add_theme_stylebox_override("pressed", UIKit.slot_box(true))

	var inv_k := Label.new()
	inv_k.text = "I"
	inv_k.position = Vector2(4, 2)
	inv_k.add_theme_font_size_override("font_size", 10)
	inv_k.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78, 0.9))
	inv_k.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	inv_k.add_theme_constant_override("outline_size", 2)
	inv_k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inv_btn.add_child(inv_k)

	var inv_ic := TextureRect.new()
	inv_ic.texture = TextureGen.backpack_icon()
	inv_ic.position = Vector2(9, 9)
	inv_ic.size = Vector2(28, 28)
	inv_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inv_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inv_btn.add_child(inv_ic)

	inv_btn.pressed.connect(func():
		open_inventory_requested.emit()
	)
	hb.add_child(inv_btn)

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
	if hoe_label != null:
		hoe_label.text = "Cuốc ×%d" % Inventory.hoes
	if water_label != null:
		water_label.text = "Nước %d/%d" % [Inventory.water_level, Inventory.water_max]
	if day_label != null:
		day_label.text = "Ngày %d" % GameState.day

	if hotbar_row == null:
		return

	for c in hotbar_row.get_children():
		c.queue_free()

	_slots_cache.clear()

	var act_t: String = str(Inventory.active_item.get("type", "hoe"))

	# Ô 1: Cuốc
	var hoe_active: bool = (act_t == "hoe")
	_slots_cache.append({
		"key": "1",
		"type": "hoe",
		"name": "Cuốc",
		"qty": Inventory.hoes,
		"tooltip": "Cuốc (×%d)" % Inventory.hoes,
		"icon": TextureGen.hoe_icon(),
		"active": hoe_active,
		"action": func():
			Inventory.select_tool("hoe")
	})

	# Ô 2: Bình tưới (hiện rõ số nước X/20)
	var water_active: bool = (act_t == "watering_can")
	_slots_cache.append({
		"key": "2",
		"type": "watering_can",
		"name": "Bình tưới",
		"qty": Inventory.water_level,
		"tooltip": "Bình tưới (%d/%d)" % [Inventory.water_level, Inventory.water_max],
		"icon": TextureGen.watering_can_icon(),
		"active": water_active,
		"action": func():
			Inventory.select_tool("watering_can")
	})

	# Ô 3: Cần câu
	var rod_active: bool = (act_t == "rod")
	_slots_cache.append({
		"key": "3",
		"type": "rod",
		"name": "Cần câu",
		"qty": Inventory.total_casts(),
		"tooltip": "Cần câu (%d lượt)" % Inventory.total_casts(),
		"icon": TextureGen.get_tex("fx_rod"),
		"active": rod_active,
		"action": func():
			Inventory.select_tool("rod")
	})

	# Các ô tiếp theo: Hạt giống (hotkey 4..9)
	var ids: Array = Inventory.owned_seed_ids()
	if ids.is_empty():
		ids = GameState.unlocked.duplicate()

	var max_seed_slots: int = 6
	var shown: int = mini(ids.size(), max_seed_slots)
	for i in shown:
		var sid := str(ids[i])
		var crop := CropDB.get_crop(sid)
		if crop.is_empty():
			continue
		var is_seed_active: bool = (act_t == "seed" and Inventory.selected_seed == sid)
		_slots_cache.append({
			"key": str(4 + i),
			"type": "seed",
			"id": sid,
			"name": str(crop.name),
			"qty": Inventory.seed_count(sid),
			"tooltip": "%s (×%d)" % [crop.name, Inventory.seed_count(sid)],
			"icon": TextureGen.seed_icon(crop),
			"active": is_seed_active,
			"action": func():
				Inventory.select_seed(sid)
		})

	for slot in _slots_cache:
		var b := Button.new()
		b.custom_minimum_size = Vector2(46, 46)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = str(slot.get("tooltip", ""))

		var is_act: bool = bool(slot.get("active", false))
		if is_act:
			b.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.42, 0.28, 0.15), UIKit.COLOR_BORDER_GOLD, 6, 2))
			b.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.50, 0.34, 0.18), UIKit.COLOR_BORDER_GOLD, 6, 2))
			b.add_theme_stylebox_override("pressed", UIKit.btn_style(Color(0.32, 0.20, 0.10), UIKit.COLOR_BORDER_GOLD, 6, 2))
		else:
			b.add_theme_stylebox_override("normal", UIKit.slot_box(false))
			b.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.30, 0.20, 0.12), UIKit.COLOR_BORDER_BRIGHT, 6, 1))
			b.add_theme_stylebox_override("pressed", UIKit.slot_box(true))

		# 1. Hình ảnh trung tâm duy nhất (không có chữ thừa)
		var ic := TextureRect.new()
		ic.texture = slot.icon
		ic.position = Vector2(9, 9)
		ic.size = Vector2(28, 28)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ic)

		# 2. Số thứ tự phím tắt ở góc trên-trái (1, 2, 3...)
		var key_lbl := Label.new()
		key_lbl.text = str(slot.get("key", ""))
		key_lbl.position = Vector2(4, 2)
		key_lbl.add_theme_font_size_override("font_size", 10)
		key_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78, 0.9))
		key_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
		key_lbl.add_theme_constant_override("outline_size", 2)
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(key_lbl)

		# 3. Ký hiệu số lượng ở góc dưới-phải (ví dụ 998, 20, 0...)
		var qty_val: int = int(slot.get("qty", 0))
		var qty_lbl := Label.new()
		qty_lbl.text = str(qty_val)
		qty_lbl.position = Vector2(2, 28)
		qty_lbl.size = Vector2(41, 16)
		qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		qty_lbl.add_theme_font_size_override("font_size", 11)
		if str(slot.get("type", "")) == "watering_can":
			qty_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0) if qty_val > 0 else Color(1.0, 0.45, 0.45))
		else:
			qty_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8) if qty_val > 0 else Color(0.65, 0.60, 0.55, 0.8))
		qty_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.98))
		qty_lbl.add_theme_constant_override("outline_size", 3)
		qty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(qty_lbl)

		var fn: Callable = slot.action
		b.pressed.connect(func():
			fn.call()
			rebuild_hotbar()
		)
		hotbar_row.add_child(b)

	if ids.size() > shown:
		var more_b := Button.new()
		more_b.custom_minimum_size = Vector2(46, 46)
		more_b.tooltip_text = "+%d loại hạt khác (I)" % (ids.size() - shown)
		more_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		more_b.add_theme_stylebox_override("normal", UIKit.slot_box(false))
		more_b.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.30, 0.20, 0.12), UIKit.COLOR_BORDER_BRIGHT, 6, 1))
		more_b.add_theme_stylebox_override("pressed", UIKit.slot_box(true))
		var more_lbl := Label.new()
		more_lbl.text = "+%d" % (ids.size() - shown)
		more_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		more_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		more_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		more_lbl.add_theme_font_size_override("font_size", 12)
		more_lbl.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GOLD)
		more_lbl.add_theme_constant_override("outline_size", 2)
		more_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		more_b.add_child(more_lbl)
		more_b.pressed.connect(func():
			open_inventory_requested.emit()
		)
		hotbar_row.add_child(more_b)

	_update_active_label()


func select_slot_by_index(idx: int) -> void:
	if idx >= 0 and idx < _slots_cache.size():
		var slot: Dictionary = _slots_cache[idx]
		var act: Callable = slot.get("action", Callable())
		if act.is_valid():
			act.call()
			rebuild_hotbar()
			toast("Đã chọn: %s" % slot.get("name", ""), Color(1.0, 0.9, 0.5))


func cycle_slot(delta: int) -> void:
	if _slots_cache.is_empty():
		return
	var cur_idx := 0
	for i in _slots_cache.size():
		if bool(_slots_cache[i].get("active", false)):
			cur_idx = i
			break
	var next_idx: int = (cur_idx + delta) % _slots_cache.size()
	if next_idx < 0:
		next_idx += _slots_cache.size()
	select_slot_by_index(next_idx)


func _select_seed(id: String) -> void:
	Inventory.select_seed(id)
	rebuild_hotbar()


func _update_active_label() -> void:
	if active_label == null:
		return
	var act_type: String = str(Inventory.active_item.get("type", "hoe"))
	match act_type:
		"hoe":
			active_label.text = "⛏ Cuốc (×%d)" % Inventory.hoes
			active_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
		"watering_can":
			active_label.text = "💧 Bình tưới (%d/%d)" % [Inventory.water_level, Inventory.water_max]
			active_label.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
		"rod":
			active_label.text = "🎣 Cần câu (%d lượt)" % Inventory.total_casts()
			active_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
		"seed":
			var sid := Inventory.selected_seed
			var c := CropDB.get_crop(sid)
			if c.is_empty():
				active_label.text = "🌱 Hạt: Chưa chọn"
				active_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)
			else:
				active_label.text = "🌱 Hạt: %s (×%d)" % [c.name, Inventory.seed_count(sid)]
				active_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_GREEN)
		_:
			active_label.text = "Đang cầm: Trống"
			active_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)
	_update_seed_label()


func _update_seed_label() -> void:
	if seed_label == null or seed_label == active_label:
		return
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


func _make_quick_btn(parent: Control, shortcut_text: String, icon_tex: Texture2D, tooltip: String, on_click: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(44, 44)
	btn.tooltip_text = tooltip
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", UIKit.slot_box(false))
	btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.32, 0.22, 0.14), UIKit.COLOR_BORDER_BRIGHT, 6, 1))
	btn.add_theme_stylebox_override("pressed", UIKit.slot_box(true))

	if icon_tex != null:
		var ic := TextureRect.new()
		ic.texture = icon_tex
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.position = Vector2(6, 6)
		ic.size = Vector2(32, 32)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(ic)

	var k := Label.new()
	k.text = shortcut_text
	k.position = Vector2(3, 1)
	k.add_theme_font_size_override("font_size", 10)
	k.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 0.95))
	k.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	k.add_theme_constant_override("outline_size", 2)
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(k)

	btn.pressed.connect(on_click)
	parent.add_child(btn)
	return btn

