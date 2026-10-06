extends CanvasLayer
# Kho đồ Nông Dân: Phong cách Gỗ mộc & Ấm cúng với thẻ phân loại mượt mà.

const CropDB := preload("res://scripts/crop_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal feedback(text: String, color: Color)

var rows: VBoxContainer
var scroll: ScrollContainer
var capacity_label: Label
var stamina_label: Label
var _active_filter := "all" # "all", "seed", "crop", "fish"
var _tab_all: Button
var _tab_seed: Button
var _tab_crop: Button
var _tab_fish: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 3, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	panel.custom_minimum_size = Vector2(760, 580)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	# --- Tiêu đề & Thông tin đầu trang ---
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	v.add_child(head)

	var title := UIKit.title_label(head, "🎒 Túi đồ", 20, UIKit.COLOR_TEXT_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Thể lực hiện tại
	var sta_box := PanelContainer.new()
	sta_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.06), UIKit.COLOR_BORDER_WOOD, 6))
	var hs := HBoxContainer.new()
	hs.add_theme_constant_override("separation", 6)
	sta_box.add_child(hs)
	var sic := TextureRect.new()
	sic.texture = TextureGen.stamina_icon()
	sic.custom_minimum_size = Vector2(16, 16)
	sic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hs.add_child(sic)
	stamina_label = UIKit.label(hs, "Thể lực: %d/%d ⚡" % [int(GameState.stamina), int(GameState.max_stamina)], 14, Color(0.35, 0.95, 0.55))
	head.add_child(sta_box)

	# Sức chứa túi đồ
	var cap_box := PanelContainer.new()
	cap_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	var hc := HBoxContainer.new()
	hc.add_theme_constant_override("separation", 6)
	cap_box.add_child(hc)
	var bic := TextureRect.new()
	bic.texture = TextureGen.backpack_icon()
	bic.custom_minimum_size = Vector2(16, 16)
	bic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hc.add_child(bic)
	capacity_label = UIKit.label(hc, "%d/%d ô" % [Inventory.backpack_slots_used(), Inventory.backpack_max], 14, UIKit.COLOR_TEXT_GOLD)
	head.add_child(cap_box)

	# Tiền hiện có
	var money_box := PanelContainer.new()
	money_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	var hm := HBoxContainer.new()
	hm.add_theme_constant_override("separation", 6)
	money_box.add_child(hm)
	var mic := TextureRect.new()
	mic.texture = TextureGen.coin_icon()
	mic.custom_minimum_size = Vector2(16, 16)
	mic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hm.add_child(mic)
	UIKit.label(hm, "%d xu" % GameState.money, 15, UIKit.COLOR_TEXT_GOLD)
	head.add_child(money_box)

	var close_btn := UIKit.styled_button(head, "✕ Đóng", 13, "danger")
	close_btn.pressed.connect(close)

	# Hàng Tabs phân loại
	var tab_bar := HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 6)
	v.add_child(tab_bar)

	_tab_all = _create_tab(tab_bar, "🌾 Tất cả", "all")
	_tab_seed = _create_tab(tab_bar, "🌱 Hạt", "seed")
	_tab_crop = _create_tab(tab_bar, "🧺 Nông sản & Thịt", "crop")
	_tab_fish = _create_tab(tab_bar, "🐟 Cá", "fish")

	# Danh sách thẻ cuộn
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(scroll)
	v.add_child(scroll)

	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 6)
	scroll.add_child(rows)


func _create_tab(parent: Node, label_text: String, filter_key: String) -> Button:
	var btn := UIKit.styled_button(parent, label_text, 13, "tab")
	btn.custom_minimum_size = Vector2(110, 32)
	btn.pressed.connect(func():
		_active_filter = filter_key
		_update_tab_styles()
		refresh()
	)
	return btn


func _update_tab_styles() -> void:
	var tabs: Array[Button] = [_tab_all, _tab_seed, _tab_crop, _tab_fish]
	var keys: Array[String] = ["all", "seed", "crop", "fish"]
	for i in tabs.size():
		var is_active: bool = (keys[i] == _active_filter)
		var bg_color := Color(0.42, 0.28, 0.16) if is_active else Color(0.20, 0.14, 0.09)
		var border := UIKit.COLOR_BORDER_BRIGHT if is_active else UIKit.COLOR_BORDER_WOOD
		tabs[i].add_theme_stylebox_override("normal", UIKit.btn_style(bg_color, border, 6, 1))
		tabs[i].add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE if is_active else UIKit.COLOR_TEXT_MUTED)


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		close()


func open() -> void:
	visible = true
	_update_tab_styles()
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func refresh() -> void:
	if stamina_label != null:
		var cur_s := int(ceil(GameState.stamina))
		var max_s := int(GameState.max_stamina)
		stamina_label.text = "Thể lực: %d/%d ⚡" % [cur_s, max_s]
		var s_col := Color(0.35, 0.95, 0.55) if cur_s >= 50 else (Color(1.0, 0.8, 0.3) if cur_s >= 20 else Color(1.0, 0.45, 0.4))
		stamina_label.add_theme_color_override("font_color", s_col)

	if capacity_label != null:
		var used := Inventory.backpack_slots_used()
		var cap := Inventory.backpack_max
		capacity_label.text = "%d/%d ô" % [used, cap]
		var col := Color(1.0, 0.45, 0.4) if used >= cap else (Color(1.0, 0.8, 0.3) if used >= cap - 2 else UIKit.COLOR_TEXT_GOLD)
		capacity_label.add_theme_color_override("font_color", col)

	for c in rows.get_children():
		c.queue_free()

	# --- 1. HẠT GIỐNG ---
	if _active_filter == "all" or _active_filter == "seed":
		var head_p := _section_header("🌱 Hạt giống", UIKit.COLOR_TEXT_GREEN)
		rows.add_child(head_p)
		var any_seed := false
		for crop in CropDB.CROPS:
			var id := str(crop.id)
			if not GameState.has_crop(id):
				continue
			any_seed = true
			rows.add_child(_build_seed_card(crop))
		if not any_seed:
			_empty_placeholder("Chưa có hạt giống")

	# --- 2. NÔNG SẢN & THỊT ---
	if _active_filter == "all" or _active_filter == "crop":
		var head_p := _section_header("🧺 Nông sản & Thịt chăn nuôi", UIKit.COLOR_TEXT_TITLE)
		rows.add_child(head_p)
		var any_prod := false
		# Nông sản trồng trọt
		for crop in CropDB.CROPS:
			var id := str(crop.id)
			var n := Inventory.produce_count(id)
			if n < 1:
				continue
			any_prod = true
			rows.add_child(_build_crop_card(crop, n))
		# Sản phẩm chăn nuôi (thịt gà, vịt, ngan, bồ câu, trứng...)
		for a in PoultryDB.ANIMALS:
			var pid := str(a.product)
			var n := Inventory.produce_count(pid)
			if n < 1:
				continue
			any_prod = true
			rows.add_child(_build_poultry_card(pid, n))
		# Sâu bọ (nếu có trong kho nông sản)
		if Inventory.produce_count("sau_bo") > 0:
			any_prod = true
			var sb_crop := CropDB.get_crop("sau_bo")
			rows.add_child(_build_crop_card(sb_crop, Inventory.produce_count("sau_bo")))
		if not any_prod:
			_empty_placeholder("Chưa có nông sản hoặc thịt")

	# --- 3. CÁ TƯƠI ---
	if _active_filter == "all" or _active_filter == "fish":
		var head_p := _section_header("🐟 Cá", UIKit.COLOR_TEXT_BLUE)
		rows.add_child(head_p)
		var any_fish := false
		for f in FishDB.FISH:
			var fid := str(f.id)
			var n := Inventory.fish_count(fid)
			if n < 1:
				continue
			any_fish = true
			rows.add_child(_build_fish_card(f, n))
		if not any_fish:
			_empty_placeholder("Chưa có cá")


func _section_header(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.18, 0.12, 0.08), UIKit.COLOR_BORDER_WOOD, 6))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	UIKit.label(h, text, 14, color)
	return p


func _empty_placeholder(text: String) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_locked_box())
	var l := UIKit.label(p, "(%s)" % text, 13, UIKit.COLOR_TEXT_MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(p)


func _build_seed_card(crop: Dictionary) -> Control:
	var id := str(crop.id)
	var count := Inventory.seed_count(id)
	var is_held := (Inventory.selected_seed == id)

	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	# Ô slot icon
	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(is_held))
	var icon := TextureRect.new()
	icon.texture = TextureGen.seed_icon(crop)
	icon.custom_minimum_size = Vector2(28, 28)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot.add_child(icon)
	h.add_child(slot)

	# Thông tin tên và nhóm
	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 2)
	h.add_child(info_v)

	var name_h := HBoxContainer.new()
	name_h.add_theme_constant_override("separation", 8)
	info_v.add_child(name_h)
	UIKit.label(name_h, crop.name, 15, UIKit.COLOR_TEXT_TITLE)

	var group_pill := PanelContainer.new()
	group_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.25, 0.18, 0.12), UIKit.COLOR_BORDER_WOOD, 4))
	UIKit.label(group_pill, str(crop.group), 11, UIKit.COLOR_TEXT_MUTED)
	name_h.add_child(group_pill)

	# Số lượng đang có
	var count_pill := PanelContainer.new()
	count_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	UIKit.label(count_pill, "×%d" % count, 14, Color(0.85, 0.95, 1.0))
	h.add_child(count_pill)

	# Nút Chọn
	var btn_type := "primary" if is_held else "buy"
	var btn_text := "✓ Đang cầm" if is_held else "Cầm"
	var sel_btn := UIKit.styled_button(h, btn_text, 13, btn_type)
	sel_btn.custom_minimum_size = Vector2(90, 30)
	sel_btn.disabled = (count < 1 and not is_held)
	sel_btn.pressed.connect(_select.bind(id))

	return p


func _build_crop_card(crop: Dictionary, count: int) -> Control:
	var id := str(crop.id)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = TextureGen.prod_icon(crop)
	icon.custom_minimum_size = Vector2(28, 28)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot.add_child(icon)
	h.add_child(slot)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 2)
	h.add_child(info_v)

	UIKit.label(info_v, crop.name, 15, UIKit.COLOR_TEXT_BODY)

	var price_pill := PanelContainer.new()
	price_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.16, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	UIKit.label(price_pill, "%d xu" % int(crop.sell_price), 13, UIKit.COLOR_TEXT_GOLD)
	h.add_child(price_pill)

	var count_pill := PanelContainer.new()
	count_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	UIKit.label(count_pill, "×%d" % count, 14, UIKit.COLOR_TEXT_TITLE)
	h.add_child(count_pill)

	# Nút Ăn hồi thể lực
	var food_val := GameState.get_food_stamina("crop", id)
	if food_val > 0:
		var eat_btn := UIKit.styled_button(h, "🍴 Ăn (+%d⚡)" % food_val, 12, "buy")
		eat_btn.custom_minimum_size = Vector2(92, 28)
		eat_btn.pressed.connect(_eat.bind("crop", id))

	return p


func _build_poultry_card(prod_id: String, count: int) -> Control:
	var info := PoultryDB.get_product_info(prod_id)
	var p_name := str(info.get("name", prod_id))
	var p_color := str(info.get("color", "d98a4a"))
	var p_price := int(info.get("price", 30))
	var is_meat := bool(info.get("is_meat", false))
	var food_val := GameState.get_food_stamina("poultry", prod_id)

	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = TextureGen.get_product_icon(prod_id)
	icon.custom_minimum_size = Vector2(28, 28)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot.add_child(icon)
	h.add_child(slot)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 2)
	h.add_child(info_v)

	var name_h := HBoxContainer.new()
	name_h.add_theme_constant_override("separation", 8)
	info_v.add_child(name_h)
	UIKit.label(name_h, p_name, 15, Color(1.0, 0.88, 0.70) if is_meat else UIKit.COLOR_TEXT_BODY)

	var cat_pill := PanelContainer.new()
	cat_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.15, 0.10), UIKit.COLOR_BORDER_WOOD, 4))
	var cat_label := "Thịt" if is_meat else ("Sữa" if prod_id == "sua_bo" else ("Lông" if prod_id == "long_cuu" else "Trứng"))
	UIKit.label(cat_pill, cat_label, 11, UIKit.COLOR_TEXT_ORANGE if is_meat else UIKit.COLOR_TEXT_MUTED)
	name_h.add_child(cat_pill)

	var price_pill := PanelContainer.new()
	price_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.16, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	UIKit.label(price_pill, "%d xu" % p_price, 13, UIKit.COLOR_TEXT_GOLD)
	h.add_child(price_pill)

	var count_pill := PanelContainer.new()
	count_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	UIKit.label(count_pill, "×%d" % count, 14, UIKit.COLOR_TEXT_TITLE)
	h.add_child(count_pill)

	# Nút Ăn thịt / trứng hồi thể lực
	if food_val > 0:
		var eat_btn := UIKit.styled_button(h, "🍴 Ăn (+%d⚡)" % food_val, 12, "buy")
		eat_btn.custom_minimum_size = Vector2(92, 28)
		eat_btn.pressed.connect(_eat.bind("poultry", prod_id))

	return p


func _build_fish_card(f: Dictionary, count: int) -> Control:
	var fid := str(f.id)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = TextureGen.fish_icon(str(f.color))
	icon.custom_minimum_size = Vector2(28, 28)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot.add_child(icon)
	h.add_child(slot)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 2)
	h.add_child(info_v)

	UIKit.label(info_v, f.name, 15, UIKit.COLOR_TEXT_BLUE)

	var price_pill := PanelContainer.new()
	price_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.10, 0.18, 0.24), Color(0.40, 0.70, 0.90), 6))
	UIKit.label(price_pill, "%d xu" % int(f.price), 13, UIKit.COLOR_TEXT_BLUE)
	h.add_child(price_pill)

	var count_pill := PanelContainer.new()
	count_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	UIKit.label(count_pill, "×%d" % count, 14, UIKit.COLOR_TEXT_TITLE)
	h.add_child(count_pill)

	# Nút Ăn cá hồi thể lực
	var food_val := GameState.get_food_stamina("fish", fid)
	if food_val > 0:
		var eat_btn := UIKit.styled_button(h, "🍴 Ăn (+%d⚡)" % food_val, 12, "buy")
		eat_btn.custom_minimum_size = Vector2(92, 28)
		eat_btn.pressed.connect(_eat.bind("fish", fid))

	return p


func _eat(category: String, id: String) -> void:
	var res := GameState.eat_food(category, id)
	if res.get("ok", false):
		feedback.emit(str(res.get("msg", "")), Color(0.4, 1.0, 0.5))
	else:
		feedback.emit(str(res.get("msg", "")), Color(1.0, 0.65, 0.4))
	refresh()


func _select(id: String) -> void:
	Inventory.select_seed(id)
	refresh()
