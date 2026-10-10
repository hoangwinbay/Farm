extends CanvasLayer
# Túi đồ: Popup chứa Balo (tối đa 64 ô - Phân trang chạm cực mượt cho Android) & 9 ô Thanh công cụ

const CropDB := preload("res://scripts/crop_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const OreDB := preload("res://scripts/ore_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal feedback(text: String, color: Color)

const SLOTS_PER_PAGE: int = 20

# Nút chuyển trang hỗ trợ kéo thả rê qua tự lật trang
class PageNavButton extends Button:
	var target_page: int = 0
	var panel_owner: CanvasLayer

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		if data is Dictionary and data.has("source_area"):
			if panel_owner != null:
				panel_owner._set_page(target_page)
		return false


# Inner class hỗ trợ kéo thả (Drag and Drop) như Minecraft giữa Balo và Hotbar
class SlotButton extends Button:
	var area: String = "backpack" # "backpack" hoặc "hotbar"
	var slot_index: int = 0
	var panel_owner: CanvasLayer

	func _get_drag_data(_at_position: Vector2) -> Variant:
		var slot: Dictionary = Inventory.get_hotbar_slot(slot_index) if area == "hotbar" else Inventory.get_backpack_slot(slot_index)
		if slot.is_empty() or int(slot.get("qty", 1)) <= 0:
			return null

		var preview := Control.new()
		var p_icon := TextureRect.new()
		p_icon.texture = Inventory.get_slot_icon(slot)
		p_icon.custom_minimum_size = Vector2(36, 36)
		p_icon.size = Vector2(36, 36)
		p_icon.position = Vector2(-18, -18)
		p_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.add_child(p_icon)
		if get_viewport() and get_viewport().gui_is_dragging():
			set_drag_preview(preview)

		return {
			"source_area": area,
			"source_index": slot_index
		}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("source_area") and data.has("source_index")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		var src_area: String = str(data.get("source_area", ""))
		var src_idx: int = int(data.get("source_index", -1))
		if Inventory.swap_slots(src_area, src_idx, area, slot_index):
			if panel_owner != null:
				panel_owner.select_slot(area, slot_index)
				panel_owner.refresh()
			Inventory.changed.emit()


var capacity_label: Label
var stamina_label: Label
var money_label: Label

var bp_title_lbl: Label
var page_nav_h: HBoxContainer
var prev_page_btn: PageNavButton
var next_page_btn: PageNavButton
var page_pills_container: HBoxContainer
var upgrade_btn: Button

var backpack_grid: GridContainer
var hotbar_grid: HBoxContainer
var rows: Control # Tương thích ngược

# Bảng chi tiết bên phải (Inspection Panel - Tối giản)
var detail_panel: PanelContainer
var detail_icon: TextureRect
var detail_title: Label
var detail_qty_label: Label
var detail_desc_label: Label
var actions_container: VBoxContainer

var _selected_area: String = "backpack"
var _selected_index: int = -1
var _current_page: int = 0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Lớp mờ nền dim phủ toàn bộ màn hình (Vùng tối hoàn toàn)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.wood_frame(12, 3, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	panel.custom_minimum_size = Vector2(800, 320)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	# --- 1. Tiêu đề & Thông tin đầu trang tối giản ---
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	v.add_child(head)

	var title := UIKit.title_label(head, "🎒 Túi đồ", 18, UIKit.COLOR_TEXT_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Thể lực
	var sta_box := PanelContainer.new()
	sta_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.06), UIKit.COLOR_BORDER_WOOD, 6))
	var hs := HBoxContainer.new()
	hs.add_theme_constant_override("separation", 5)
	sta_box.add_child(hs)
	var sic := TextureRect.new()
	sic.texture = TextureGen.stamina_icon()
	sic.custom_minimum_size = Vector2(16, 16)
	sic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hs.add_child(sic)
	stamina_label = UIKit.label(hs, "%d/%d ⚡" % [int(GameState.stamina), int(GameState.max_stamina)], 13, Color(0.35, 0.95, 0.55))
	head.add_child(sta_box)

	# Sức chứa balo
	var cap_box := PanelContainer.new()
	cap_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	var hc := HBoxContainer.new()
	hc.add_theme_constant_override("separation", 5)
	cap_box.add_child(hc)
	var bic := TextureRect.new()
	bic.texture = TextureGen.backpack_icon()
	bic.custom_minimum_size = Vector2(16, 16)
	bic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hc.add_child(bic)
	capacity_label = UIKit.label(hc, "%d/%d" % [Inventory.backpack_slots_used(), Inventory.backpack_max], 13, UIKit.COLOR_TEXT_GOLD)
	head.add_child(cap_box)

	# Tiền hiện có
	var money_box := PanelContainer.new()
	money_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	var hm := HBoxContainer.new()
	hm.add_theme_constant_override("separation", 5)
	money_box.add_child(hm)
	var mic := TextureRect.new()
	mic.texture = TextureGen.coin_icon()
	mic.custom_minimum_size = Vector2(16, 16)
	mic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hm.add_child(mic)
	money_label = UIKit.label(hm, "%d xu" % GameState.money, 14, UIKit.COLOR_TEXT_GOLD)
	head.add_child(money_box)

	GameState.money_changed.connect(func(val: int) -> void:
		if money_label != null:
			money_label.text = "%d xu" % val
		_update_upgrade_btn()
	)

	var close_btn := UIKit.styled_button(head, "✕ Đóng", 13, "danger")
	close_btn.pressed.connect(close)

	# --- 2. Thân chính: Bên trái là Balo + Thanh công cụ, Bên phải là Bảng chi tiết tối giản ---
	var body_h := HBoxContainer.new()
	body_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_h.add_theme_constant_override("separation", 14)
	v.add_child(body_h)

	# Cột trái: Balo (tối đa 64 ô) + Thanh công cụ (9 ô)
	var left_v := VBoxContainer.new()
	left_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_v.add_theme_constant_override("separation", 10)
	body_h.add_child(left_v)

	# 2a. Phần Balo (Phân trang chạm 1-chạm không cần vuốt cuộn)
	var bp_box := PanelContainer.new()
	bp_box.add_theme_stylebox_override("panel", UIKit.wood_frame(8, 2, Color(0.14, 0.10, 0.06, 0.9), UIKit.COLOR_BORDER_WOOD))
	bp_box.gui_input.connect(_on_bp_gui_input)
	left_v.add_child(bp_box)

	var bp_v := VBoxContainer.new()
	bp_v.add_theme_constant_override("separation", 6)
	bp_box.add_child(bp_v)

	var bp_title_h := HBoxContainer.new()
	bp_title_h.add_theme_constant_override("separation", 8)
	bp_v.add_child(bp_title_h)

	bp_title_lbl = UIKit.label(bp_title_h, "Balo (%d/64 ô)" % Inventory.backpack_max, 14, UIKit.COLOR_TEXT_TITLE)

	# Thanh chuyển trang: ◀ [1] [2] ... ▶
	page_nav_h = HBoxContainer.new()
	page_nav_h.add_theme_constant_override("separation", 5)
	page_nav_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_nav_h.alignment = BoxContainer.ALIGNMENT_CENTER
	bp_title_h.add_child(page_nav_h)

	prev_page_btn = PageNavButton.new()
	prev_page_btn.text = "◀"
	prev_page_btn.panel_owner = self
	prev_page_btn.custom_minimum_size = Vector2(32, 26)
	prev_page_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	prev_page_btn.pressed.connect(func(): _change_page(-1))
	page_nav_h.add_child(prev_page_btn)

	page_pills_container = HBoxContainer.new()
	page_pills_container.add_theme_constant_override("separation", 4)
	page_nav_h.add_child(page_pills_container)

	next_page_btn = PageNavButton.new()
	next_page_btn.text = "▶"
	next_page_btn.panel_owner = self
	next_page_btn.custom_minimum_size = Vector2(32, 26)
	next_page_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_page_btn.pressed.connect(func(): _change_page(1))
	page_nav_h.add_child(next_page_btn)

	# Nút mua mở thêm ô
	upgrade_btn = Button.new()
	upgrade_btn.custom_minimum_size = Vector2(110, 26)
	upgrade_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	upgrade_btn.pressed.connect(_on_upgrade_backpack_pressed)
	bp_title_h.add_child(upgrade_btn)

	# Lưới Balo (Cố định 2 hàng 10 ô = 20 ô/trang, không cần cuộn, thao tác ngón tay chạm cực chuẩn)
	backpack_grid = GridContainer.new()
	backpack_grid.columns = 10
	backpack_grid.add_theme_constant_override("h_separation", 6)
	backpack_grid.add_theme_constant_override("v_separation", 6)
	bp_v.add_child(backpack_grid)
	rows = backpack_grid

	# 2b. Phần Thanh công cụ nhanh (9 ô)
	var hb_box := PanelContainer.new()
	hb_box.add_theme_stylebox_override("panel", UIKit.wood_frame(8, 2, Color(0.14, 0.10, 0.06, 0.9), UIKit.COLOR_BORDER_GOLD))
	left_v.add_child(hb_box)

	var hb_v := VBoxContainer.new()
	hb_v.add_theme_constant_override("separation", 6)
	hb_box.add_child(hb_v)

	var hb_title_h := HBoxContainer.new()
	hb_v.add_child(hb_title_h)
	UIKit.label(hb_title_h, "Thanh công cụ (9 ô)", 14, Color(1.0, 0.88, 0.45))

	hotbar_grid = HBoxContainer.new()
	hotbar_grid.add_theme_constant_override("separation", 6)
	hb_v.add_child(hotbar_grid)

	# Cột phải: Bảng chi tiết vật phẩm đã chọn tối giản
	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(170, 0)
	detail_panel.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.13, 0.09, 0.06, 0.95), UIKit.COLOR_BORDER_GOLD, 8))
	body_h.add_child(detail_panel)

	var d_v := VBoxContainer.new()
	d_v.add_theme_constant_override("separation", 6)
	detail_panel.add_child(d_v)

	# Khung hình ảnh vật phẩm to ở giữa
	var icon_slot := PanelContainer.new()
	icon_slot.custom_minimum_size = Vector2(52, 52)
	icon_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_slot.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.18, 0.12, 0.08), UIKit.COLOR_BORDER_WOOD, 6))
	d_v.add_child(icon_slot)

	detail_icon = TextureRect.new()
	detail_icon.custom_minimum_size = Vector2(38, 38)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_slot.add_child(detail_icon)

	detail_title = UIKit.title_label(d_v, "", 14, UIKit.COLOR_TEXT_TITLE)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	detail_qty_label = UIKit.label(d_v, "", 13, UIKit.COLOR_TEXT_GOLD)
	detail_qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	detail_desc_label = Label.new()
	detail_desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc_label.add_theme_font_size_override("font_size", 12)
	detail_desc_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6))
	d_v.add_child(detail_desc_label)

	# Vùng nút thao tác tối giản: "Lấy ra", "Cất", "Ăn"
	actions_container = VBoxContainer.new()
	actions_container.add_theme_constant_override("separation", 5)
	d_v.add_child(actions_container)

	Inventory.changed.connect(func():
		if visible:
			refresh()
	)


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		close()


func _on_bp_gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_page(1)
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_change_page(-1)


func open() -> void:
	visible = true
	if _selected_area == "" or _selected_index < 0:
		_auto_select_first_slot()
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func _auto_select_first_slot() -> void:
	if not Inventory.get_hotbar_slot(Inventory.active_hotbar_index).is_empty():
		_selected_area = "hotbar"
		_selected_index = Inventory.active_hotbar_index
		return
	for i in Inventory.backpack_slots.size():
		if not Inventory.backpack_slots[i].is_empty():
			_selected_area = "backpack"
			_selected_index = i
			_current_page = int(i / SLOTS_PER_PAGE)
			return
	_selected_area = "hotbar"
	_selected_index = 0


func select_slot(area: String, idx: int) -> void:
	_selected_area = area
	_selected_index = idx
	refresh()


func _get_total_pages() -> int:
	return maxi(1, int(ceil(float(Inventory.backpack_max) / float(SLOTS_PER_PAGE))))


func _change_page(delta: int) -> void:
	var total := _get_total_pages()
	var new_p := clampi(_current_page + delta, 0, total - 1)
	if new_p != _current_page:
		_current_page = new_p
		refresh()


func _set_page(page_idx: int) -> void:
	var total := _get_total_pages()
	var new_p := clampi(page_idx, 0, total - 1)
	if new_p != _current_page:
		_current_page = new_p
		refresh()


func _update_upgrade_btn() -> void:
	if upgrade_btn == null:
		return
	if Inventory.backpack_max >= Inventory.BACKPACK_MAX_LIMIT:
		upgrade_btn.text = "Tối đa (64 ô)"
		upgrade_btn.disabled = true
		upgrade_btn.add_theme_stylebox_override("normal", UIKit.slot_box(false))
	else:
		var cost := Inventory.get_backpack_upgrade_cost()
		upgrade_btn.text = "+ Mở ô (%d xu)" % cost
		upgrade_btn.disabled = false
		var can_afford := (GameState.money >= cost)
		if can_afford:
			upgrade_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.20, 0.38, 0.18), Color(0.6, 0.95, 0.5), 4, 1))
			upgrade_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.26, 0.46, 0.22), Color(0.8, 1.0, 0.7), 4, 1))
		else:
			upgrade_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.24, 0.20, 0.16), Color(0.5, 0.42, 0.35), 4, 1))
			upgrade_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.28, 0.24, 0.18), Color(0.6, 0.5, 0.4), 4, 1))


func _update_page_nav() -> void:
	if page_nav_h == null:
		return
	var total := _get_total_pages()
	if _current_page >= total:
		_current_page = total - 1

	prev_page_btn.disabled = (_current_page <= 0)
	prev_page_btn.target_page = maxi(0, _current_page - 1)
	next_page_btn.disabled = (_current_page >= total - 1)
	next_page_btn.target_page = mini(total - 1, _current_page + 1)

	# Ẩn nút mũi tên nếu chỉ có đúng 1 trang
	prev_page_btn.visible = (total > 1)
	next_page_btn.visible = (total > 1)

	for c in page_pills_container.get_children():
		page_pills_container.remove_child(c)
		c.queue_free()

	if total > 1:
		for p in total:
			var p_btn := PageNavButton.new()
			p_btn.text = str(p + 1)
			p_btn.target_page = p
			p_btn.panel_owner = self
			p_btn.custom_minimum_size = Vector2(28, 26)
			p_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var is_act := (p == _current_page)
			if is_act:
				p_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.42, 0.30, 0.16), Color(1.0, 0.88, 0.45), 4, 2))
				p_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
			else:
				p_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.20, 0.15, 0.10), Color(0.45, 0.35, 0.25), 4, 1))
				p_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.30, 0.22, 0.14), Color(0.7, 0.6, 0.4), 4, 1))
				p_btn.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))

			var tp := p
			p_btn.pressed.connect(func():
				_set_page(tp)
			)
			page_pills_container.add_child(p_btn)


func _on_upgrade_backpack_pressed() -> void:
	var prev_total := _get_total_pages()
	var res := Inventory.upgrade_backpack()
	if res.get("ok", false):
		feedback.emit(str(res.get("msg", "")), Color(0.4, 1.0, 0.5))
		var new_total := _get_total_pages()
		if new_total > prev_total:
			_current_page = new_total - 1
		refresh()
	else:
		feedback.emit(str(res.get("msg", "")), Color(1.0, 0.45, 0.4))


func refresh() -> void:
	if not is_instance_valid(backpack_grid) or not is_instance_valid(hotbar_grid):
		return

	if stamina_label != null:
		var cur_s := int(ceil(GameState.stamina))
		var max_s := int(GameState.max_stamina)
		stamina_label.text = "%d/%d ⚡" % [cur_s, max_s]
		var s_col := Color(0.35, 0.95, 0.55) if cur_s >= 50 else (Color(1.0, 0.8, 0.3) if cur_s >= 20 else Color(1.0, 0.45, 0.4))
		stamina_label.add_theme_color_override("font_color", s_col)

	if capacity_label != null:
		var used := Inventory.backpack_slots_used()
		capacity_label.text = "%d/%d" % [used, Inventory.backpack_max]
		var col := Color(1.0, 0.45, 0.4) if used >= Inventory.backpack_max else (Color(1.0, 0.8, 0.3) if used >= Inventory.backpack_max - 2 else UIKit.COLOR_TEXT_GOLD)
		capacity_label.add_theme_color_override("font_color", col)

	if bp_title_lbl != null:
		bp_title_lbl.text = "Balo (%d/64 ô)" % Inventory.backpack_max

	_update_page_nav()
	_update_upgrade_btn()

	if money_label != null:
		money_label.text = "%d xu" % GameState.money

	# Tái tạo các ô Balo cho trang hiện tại (tối đa 20 ô mỗi trang)
	for c in backpack_grid.get_children():
		backpack_grid.remove_child(c)
		c.queue_free()

	var start_idx: int = _current_page * SLOTS_PER_PAGE
	var end_idx: int = mini(start_idx + SLOTS_PER_PAGE, Inventory.backpack_max)

	for i in range(start_idx, end_idx):
		var b := _create_slot_button("backpack", i)
		backpack_grid.add_child(b)

	# Ô dấu cộng để bấm mở thêm ô: hiện ở trang cuối nếu chưa max 64
	var is_last_page := (_current_page == _get_total_pages() - 1)
	if Inventory.backpack_max < Inventory.BACKPACK_MAX_LIMIT and is_last_page and (end_idx - start_idx < SLOTS_PER_PAGE or _get_total_pages() == 1):
		var add_b := Button.new()
		add_b.custom_minimum_size = Vector2(50, 50)
		add_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var next_cost := Inventory.get_backpack_upgrade_cost()
		add_b.tooltip_text = "Mở thêm 1 ô (%d xu)" % next_cost
		add_b.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.18, 0.14, 0.10, 0.7), Color(0.55, 0.45, 0.30), 6, 1))
		add_b.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.24, 0.35, 0.18), Color(0.6, 0.95, 0.5), 6, 2))
		add_b.add_theme_stylebox_override("pressed", UIKit.btn_style(Color(0.15, 0.12, 0.08), Color(0.6, 0.95, 0.5), 6, 1))

		var plus_lbl := Label.new()
		plus_lbl.text = "+"
		plus_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plus_lbl.add_theme_font_size_override("font_size", 22)
		plus_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
		plus_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_b.add_child(plus_lbl)

		add_b.pressed.connect(_on_upgrade_backpack_pressed)
		backpack_grid.add_child(add_b)

	# 9 ô Hotbar
	for c in hotbar_grid.get_children():
		hotbar_grid.remove_child(c)
		c.queue_free()
	for i in Inventory.HOTBAR_SIZE:
		var b := _create_slot_button("hotbar", i)
		hotbar_grid.add_child(b)

	_render_details()


func _create_slot_button(area: String, idx: int) -> SlotButton:
	var b := SlotButton.new()
	b.area = area
	b.slot_index = idx
	b.panel_owner = self
	b.custom_minimum_size = Vector2(50, 50)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var slot_data: Dictionary = Inventory.get_hotbar_slot(idx) if area == "hotbar" else Inventory.get_backpack_slot(idx)
	var is_selected: bool = (_selected_area == area and _selected_index == idx)
	var is_active_hotbar: bool = (area == "hotbar" and idx == Inventory.active_hotbar_index)

	if is_selected:
		b.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.45, 0.32, 0.18), Color(1.0, 0.90, 0.40), 6, 2))
		b.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.52, 0.38, 0.22), Color(1.0, 0.95, 0.50), 6, 2))
		b.add_theme_stylebox_override("pressed", UIKit.btn_style(Color(0.35, 0.24, 0.12), Color(1.0, 0.90, 0.40), 6, 2))
	elif is_active_hotbar:
		b.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.38, 0.25, 0.14), Color(0.95, 0.75, 0.20), 6, 2))
		b.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.46, 0.30, 0.16), Color(1.0, 0.85, 0.30), 6, 2))
		b.add_theme_stylebox_override("pressed", UIKit.btn_style(Color(0.28, 0.18, 0.10), Color(0.95, 0.75, 0.20), 6, 2))
	else:
		b.add_theme_stylebox_override("normal", UIKit.slot_box(false))
		b.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.30, 0.20, 0.12), UIKit.COLOR_BORDER_BRIGHT, 6, 1))
		b.add_theme_stylebox_override("pressed", UIKit.slot_box(true))

	# Phím tắt 1..9 ở góc trên-trái cho ô hotbar
	if area == "hotbar":
		var key_lbl := Label.new()
		key_lbl.text = str(idx + 1)
		key_lbl.position = Vector2(4, 2)
		key_lbl.add_theme_font_size_override("font_size", 10)
		key_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.60) if is_active_hotbar else Color(0.85, 0.82, 0.78, 0.85))
		key_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
		key_lbl.add_theme_constant_override("outline_size", 2)
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(key_lbl)

	if not slot_data.is_empty():
		var tex := Inventory.get_slot_icon(slot_data)
		if tex != null:
			var ic := TextureRect.new()
			ic.texture = tex
			ic.position = Vector2(10, 10)
			ic.size = Vector2(30, 30)
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(ic)

		var qty_val: int = Inventory.get_slot_qty(slot_data)
		var s_type: String = str(slot_data.get("type", ""))
		if s_type == "watering_can" or qty_val > 1:
			var qty_lbl := Label.new()
			qty_lbl.text = str(qty_val)
			qty_lbl.position = Vector2(2, 30)
			qty_lbl.size = Vector2(44, 16)
			qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			qty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			qty_lbl.add_theme_font_size_override("font_size", 11)
			if s_type == "watering_can":
				qty_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0) if qty_val > 0 else Color(1.0, 0.45, 0.45))
			else:
				qty_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
			qty_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.98))
			qty_lbl.add_theme_constant_override("outline_size", 3)
			qty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(qty_lbl)

	b.pressed.connect(func():
		select_slot(area, idx)
	)

	return b


func _render_details() -> void:
	for c in actions_container.get_children():
		actions_container.remove_child(c)
		c.queue_free()

	if _selected_area == "" or _selected_index < 0:
		detail_icon.texture = null
		detail_title.text = ""
		detail_qty_label.text = ""
		detail_desc_label.text = ""
		return

	var is_hb := (_selected_area == "hotbar")
	var slot: Dictionary = Inventory.get_hotbar_slot(_selected_index) if is_hb else Inventory.get_backpack_slot(_selected_index)
	if slot.is_empty():
		detail_icon.texture = null
		detail_title.text = ""
		detail_qty_label.text = ""
		detail_desc_label.text = ""
		return

	var s_name := Inventory.get_slot_name(slot)
	var s_icon := Inventory.get_slot_icon(slot)
	var s_qty := Inventory.get_slot_qty(slot)
	var s_type := str(slot.get("type", ""))
	var s_id := str(slot.get("id", ""))

	detail_icon.texture = s_icon
	detail_title.text = s_name
	if s_type == "watering_can":
		detail_qty_label.text = "%d/%d" % [s_qty, Inventory.water_max]
	elif s_qty > 1:
		detail_qty_label.text = "×%d" % s_qty
	else:
		detail_qty_label.text = ""

	# Dòng chỉ số tối giản: ví dụ "+55 ⚡"
	var stat_text := ""
	if s_type in ["produce", "fish"]:
		var food_cat := "fish" if s_type == "fish" else ("poultry" if not PoultryDB.get_animal(s_id).is_empty() else "crop")
		var food_val := GameState.get_food_stamina(food_cat, s_id)
		if food_val > 0:
			stat_text = "+%d ⚡" % food_val
	detail_desc_label.text = stat_text

	# Nút hành động tối giản đúng chữ: "Lấy ra", "Cất", "Ăn"
	if not is_hb:
		var take_btn := UIKit.styled_button(actions_container, "Lấy ra", 14, "buy")
		take_btn.custom_minimum_size = Vector2(0, 34)
		take_btn.pressed.connect(_on_action_take_out)
	else:
		var store_btn := UIKit.styled_button(actions_container, "Cất", 14, "default")
		store_btn.custom_minimum_size = Vector2(0, 34)
		store_btn.pressed.connect(_on_action_store_to_backpack)

	if s_type in ["produce", "fish"]:
		var food_cat := "fish" if s_type == "fish" else ("poultry" if not PoultryDB.get_animal(s_id).is_empty() else "crop")
		var food_val := GameState.get_food_stamina(food_cat, s_id)
		if food_val > 0:
			var eat_btn := UIKit.styled_button(actions_container, "Ăn", 14, "primary")
			eat_btn.custom_minimum_size = Vector2(0, 32)
			eat_btn.pressed.connect(_on_action_eat.bind(food_cat, s_id))


# Xử lý nút "Lấy ra": tự fill vào thanh công cụ khi còn trống, nếu full r thì thay thế
func _on_action_take_out() -> void:
	if _selected_area != "backpack" or _selected_index < 0:
		return
	var item: Dictionary = Inventory.get_backpack_slot(_selected_index)
	if item.is_empty():
		return
	var item_name := Inventory.get_slot_name(item)
	var prev_idx := _selected_index
	if Inventory.move_backpack_to_hotbar(prev_idx):
		_selected_area = "hotbar"
		_selected_index = Inventory.active_hotbar_index
		refresh()
		feedback.emit(item_name, Color(0.4, 1.0, 0.5))


# Xử lý nút "Cất"
func _on_action_store_to_backpack() -> void:
	if _selected_area != "hotbar" or _selected_index < 0:
		return
	var item: Dictionary = Inventory.get_hotbar_slot(_selected_index)
	if item.is_empty():
		return
	var item_name := Inventory.get_slot_name(item)
	if Inventory.move_hotbar_to_backpack(_selected_index):
		refresh()
		feedback.emit(item_name, Color(0.4, 1.0, 0.5))
	else:
		feedback.emit("Balo đã đầy %d ô!" % Inventory.backpack_max, Color(1.0, 0.45, 0.4))


# Xử lý nút "Ăn"
func _on_action_eat(cat: String, id: String) -> void:
	var res := GameState.eat_food(cat, id)
	if res.get("ok", false):
		feedback.emit(str(res.get("msg", "")), Color(0.4, 1.0, 0.5))
		refresh()
	else:
		feedback.emit(str(res.get("msg", "")), Color(1.0, 0.45, 0.4))
