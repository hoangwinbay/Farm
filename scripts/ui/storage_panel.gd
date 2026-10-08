extends CanvasLayer
# Giao diện Nhà Kho (Shed Storage):
# Lưu trữ hạt giống, nông sản, cá và sâu bọ không giới hạn.
# Giúp giải phóng túi đồ có giới hạn (12 ô) của người chơi.

const CropDB := preload("res://scripts/crop_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const OreDB := preload("res://scripts/ore_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal feedback(text: String, color: Color)

var shed_rows: VBoxContainer
var shed_scroll: ScrollContainer
var bag_rows: VBoxContainer
var bag_scroll: ScrollContainer
var bag_capacity_label: Label
var feedback_label: Label
var shed_count_label: Label


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

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 3, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	panel.custom_minimum_size = Vector2(900, 600)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	# --- 1. TIÊU ĐỀ & THÔNG TIN ĐẦU TRANG ---
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	v.add_child(head)

	var title_v := VBoxContainer.new()
	title_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_v.add_theme_constant_override("separation", 2)
	head.add_child(title_v)

	UIKit.title_label(title_v, "🏚️ NHÀ KHO NÔNG TRẠI", 20, UIKit.COLOR_TEXT_TITLE)

	# Huy hiệu sức chứa túi đồ
	var cap_box := PanelContainer.new()
	cap_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	var hc := HBoxContainer.new()
	hc.add_theme_constant_override("separation", 6)
	cap_box.add_child(hc)
	var bic := TextureRect.new()
	bic.texture = TextureGen.backpack_icon()
	bic.custom_minimum_size = Vector2(18, 18)
	bic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hc.add_child(bic)
	bag_capacity_label = UIKit.label(hc, "Túi đồ: 0/12", 14, UIKit.COLOR_TEXT_GOLD)
	head.add_child(cap_box)

	var close_btn := UIKit.styled_button(head, "✕ Đóng (Esc/E)", 13, "danger")
	close_btn.pressed.connect(close)

	# Thanh thông báo nhanh feedback
	feedback_label = Label.new()
	feedback_label.add_theme_font_size_override("font_size", 13)
	feedback_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.text = "Nhấp các nút bên dưới để cất hoặc rút vật phẩm giữa Túi đồ và Nhà kho."
	v.add_child(feedback_label)

	# --- 2. HAI CỘT CHÍNH (TRÁI: NHÀ KHO, PHẢI: TÚI ĐỒ) ---
	var split_h := HBoxContainer.new()
	split_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_h.add_theme_constant_override("separation", 12)
	v.add_child(split_h)

	# == CỘT TRÁI: KHO LƯU TRỮ TRONG NHÀ KHO ==
	var left_v := VBoxContainer.new()
	left_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_v.add_theme_constant_override("separation", 6)
	split_h.add_child(left_v)

	var left_head := HBoxContainer.new()
	var l_title := _section_title("📦 KHO NHÀ KHO", Color(0.95, 0.85, 0.65))
	l_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_head.add_child(l_title)
	shed_count_label = UIKit.label(left_head, "0 món", 12, UIKit.COLOR_TEXT_MUTED)
	left_v.add_child(left_head)

	shed_scroll = ScrollContainer.new()
	shed_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shed_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(shed_scroll)
	left_v.add_child(shed_scroll)

	shed_rows = VBoxContainer.new()
	shed_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shed_rows.add_theme_constant_override("separation", 6)
	shed_scroll.add_child(shed_rows)

	# == CỘT PHẢI: TÚI ĐỒ CỦA BẠN ==
	var right_v := VBoxContainer.new()
	right_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_v.add_theme_constant_override("separation", 6)
	split_h.add_child(right_v)

	var r_title := _section_title("🎒 TÚI ĐỒ CỦA BẠN", Color(0.65, 0.90, 0.70))
	right_v.add_child(r_title)

	bag_scroll = ScrollContainer.new()
	bag_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(bag_scroll)
	right_v.add_child(bag_scroll)

	bag_rows = VBoxContainer.new()
	bag_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_rows.add_theme_constant_override("separation", 6)
	bag_scroll.add_child(bag_rows)

	# --- 3. THANH THAO TÁC NHANH (QUICK ACTIONS) ---
	var bot_h := HBoxContainer.new()
	bot_h.add_theme_constant_override("separation", 10)
	v.add_child(bot_h)

	var store_crops_btn := UIKit.styled_button(bot_h, "🧺 Cất hết Nông sản", 13, "primary")
	store_crops_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	store_crops_btn.pressed.connect(func():
		var n := Inventory.store_all_category("produce")
		_set_msg("Đã cất %d nông sản vào nhà kho! 🧺" % n if n > 0 else "Không có nông sản nào trong túi để cất.", Color(0.7, 0.95, 0.6))
		refresh()
	)

	var store_fish_btn := UIKit.styled_button(bot_h, "🐟 Cất hết Cá", 13, "primary")
	store_fish_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	store_fish_btn.pressed.connect(func():
		var n := Inventory.store_all_category("fish")
		_set_msg("Đã cất %d cá vào nhà kho! 🐟" % n if n > 0 else "Không có cá nào trong túi để cất.", Color(0.7, 0.95, 0.6))
		refresh()
	)

	var store_seeds_btn := UIKit.styled_button(bot_h, "🌱 Cất hết Hạt giống", 13, "primary")
	store_seeds_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	store_seeds_btn.pressed.connect(func():
		var n := Inventory.store_all_category("seeds")
		_set_msg("Đã cất %d hạt giống vào nhà kho! 🌱" % n if n > 0 else "Không có hạt giống nào trong túi để cất.", Color(0.7, 0.95, 0.6))
		refresh()
	)


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	_set_msg("Nhấp các nút để cất hoặc rút vật phẩm giữa Túi đồ và Nhà kho.", Color(0.9, 0.85, 0.7))
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func _set_msg(text: String, col: Color) -> void:
	if feedback_label != null:
		feedback_label.text = text
		feedback_label.add_theme_color_override("font_color", col)


func refresh() -> void:
	var used := Inventory.backpack_slots_used()
	var cap := Inventory.backpack_max
	if bag_capacity_label != null:
		bag_capacity_label.text = "Túi đồ: %d/%d ô" % [used, cap]
		var col := Color(1.0, 0.45, 0.4) if used >= cap else (Color(1.0, 0.8, 0.3) if used >= cap - 2 else UIKit.COLOR_TEXT_GOLD)
		bag_capacity_label.add_theme_color_override("font_color", col)

	_refresh_shed_list()
	_refresh_bag_list()


func _refresh_shed_list() -> void:
	for c in shed_rows.get_children():
		c.queue_free()

	var total_stored_types := 0
	# Nông sản trong kho
	var p_dict = Inventory.storage.get("produce", {})
	if typeof(p_dict) == TYPE_DICTIONARY:
		for id in p_dict:
			var count: int = int(p_dict[id])
			if count > 0:
				total_stored_types += 1
				shed_rows.add_child(_build_storage_row("produce", str(id), count))

	# Cá trong kho
	var f_dict = Inventory.storage.get("fish", {})
	if typeof(f_dict) == TYPE_DICTIONARY:
		for id in f_dict:
			var count: int = int(f_dict[id])
			if count > 0:
				total_stored_types += 1
				shed_rows.add_child(_build_storage_row("fish", str(id), count))

	# Khoáng sản trong kho
	var o_dict = Inventory.storage.get("ores", {})
	if typeof(o_dict) == TYPE_DICTIONARY:
		for id in o_dict:
			var count: int = int(o_dict[id])
			if count > 0:
				total_stored_types += 1
				shed_rows.add_child(_build_storage_row("ores", str(id), count))

	# Hạt giống trong kho
	var s_dict = Inventory.storage.get("seeds", {})
	if typeof(s_dict) == TYPE_DICTIONARY:
		for id in s_dict:
			var count: int = int(s_dict[id])
			if count > 0:
				total_stored_types += 1
				shed_rows.add_child(_build_storage_row("seeds", str(id), count))

	if shed_count_label != null:
		shed_count_label.text = "%d loại món" % total_stored_types

	if total_stored_types == 0:
		var empty_box := PanelContainer.new()
		empty_box.add_theme_stylebox_override("panel", UIKit.row_locked_box())
		var l := UIKit.label(empty_box, "(Nhà kho đang trống. Hãy cất đồ từ túi ở cột bên phải sang!)", 13, UIKit.COLOR_TEXT_MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shed_rows.add_child(empty_box)


func _refresh_bag_list() -> void:
	for c in bag_rows.get_children():
		c.queue_free()

	var any := false

	# Khoáng sản trong túi
	for id in Inventory.ores:
		var count: int = int(Inventory.ores[id])
		if count > 0:
			any = true
			bag_rows.add_child(_build_bag_row("ores", str(id), count))

	# Nông sản trong túi
	for id in Inventory.produce:
		var count: int = int(Inventory.produce[id])
		if count > 0:
			any = true
			bag_rows.add_child(_build_bag_row("produce", str(id), count))

	# Cá trong túi
	for id in Inventory.fish:
		var count: int = int(Inventory.fish[id])
		if count > 0:
			any = true
			bag_rows.add_child(_build_bag_row("fish", str(id), count))

	# Hạt giống trong túi
	for id in Inventory.seeds:
		var count: int = int(Inventory.seeds[id])
		if count > 0:
			any = true
			bag_rows.add_child(_build_bag_row("seeds", str(id), count))

	if not any:
		var empty_box := PanelContainer.new()
		empty_box.add_theme_stylebox_override("panel", UIKit.row_locked_box())
		var l := UIKit.label(empty_box, "(Túi đồ không có vật phẩm nào để cất vào kho)", 13, UIKit.COLOR_TEXT_MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bag_rows.add_child(empty_box)


func _build_storage_row(category: String, id: String, count: int) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)

	var icon_slot := PanelContainer.new()
	icon_slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = _get_item_icon(category, id)
	icon.custom_minimum_size = Vector2(26, 26)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon_slot.add_child(icon)
	h.add_child(icon_slot)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 1)
	h.add_child(info_v)

	var item_name := _get_item_name(category, id)
	UIKit.label(info_v, item_name, 14, UIKit.COLOR_TEXT_TITLE)

	var count_pill := PanelContainer.new()
	count_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.16, 0.12, 0.08), UIKit.COLOR_BORDER_WOOD, 4))
	UIKit.label(count_pill, "Trong kho: ×%d" % count, 11, UIKit.COLOR_TEXT_GOLD)
	info_v.add_child(count_pill)

	# Nút rút đồ
	var btn_h := HBoxContainer.new()
	btn_h.add_theme_constant_override("separation", 4)
	h.add_child(btn_h)

	var w1 := UIKit.styled_button(btn_h, "Rút 1", 12, "default")
	w1.custom_minimum_size = Vector2(46, 28)
	w1.pressed.connect(func():
		_withdraw(category, id, 1)
	)

	if count >= 10:
		var w10 := UIKit.styled_button(btn_h, "10", 12, "default")
		w10.custom_minimum_size = Vector2(36, 28)
		w10.pressed.connect(func():
			_withdraw(category, id, 10)
		)

	var wall := UIKit.styled_button(btn_h, "Hết", 12, "buy")
	wall.custom_minimum_size = Vector2(42, 28)
	wall.pressed.connect(func():
		_withdraw(category, id, count)
	)

	return p


func _build_bag_row(category: String, id: String, count: int) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)

	var icon_slot := PanelContainer.new()
	icon_slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = _get_item_icon(category, id)
	icon.custom_minimum_size = Vector2(26, 26)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon_slot.add_child(icon)
	h.add_child(icon_slot)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 1)
	h.add_child(info_v)

	var item_name := _get_item_name(category, id)
	UIKit.label(info_v, item_name, 14, UIKit.COLOR_TEXT_TITLE)

	var count_pill := PanelContainer.new()
	count_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.16, 0.10), Color(0.3, 0.6, 0.3), 4))
	UIKit.label(count_pill, "Trong túi: ×%d" % count, 11, Color(0.75, 0.95, 0.7))
	info_v.add_child(count_pill)

	# Nút cất đồ
	var btn_h := HBoxContainer.new()
	btn_h.add_theme_constant_override("separation", 4)
	h.add_child(btn_h)

	var s1 := UIKit.styled_button(btn_h, "Cất 1", 12, "default")
	s1.custom_minimum_size = Vector2(46, 28)
	s1.pressed.connect(func():
		_store(category, id, 1)
	)

	if count >= 10:
		var s10 := UIKit.styled_button(btn_h, "10", 12, "default")
		s10.custom_minimum_size = Vector2(36, 28)
		s10.pressed.connect(func():
			_store(category, id, 10)
		)

	var sall := UIKit.styled_button(btn_h, "Hết", 12, "primary")
	sall.custom_minimum_size = Vector2(42, 28)
	sall.pressed.connect(func():
		_store(category, id, count)
	)

	return p


func _store(category: String, id: String, amount: int) -> void:
	var item_name := _get_item_name(category, id)
	if Inventory.store_item(category, id, amount):
		_set_msg("Đã cất %d %s vào nhà kho!" % [amount, item_name], Color(0.7, 0.95, 0.6))
		refresh()
	else:
		_set_msg("Không thể cất %s!" % item_name, Color(1.0, 0.5, 0.4))


func _withdraw(category: String, id: String, amount: int) -> void:
	var item_name := _get_item_name(category, id)
	var cat_key := "produce"
	if category == "seeds": cat_key = "seed"
	elif category == "fish": cat_key = "fish"
	elif category == "ores": cat_key = "ore"

	if not Inventory.can_hold(cat_key, id):
		_set_msg("Túi đồ đã đầy (%d/%d ô)! Hãy cất bớt món khác vào kho trước." % [Inventory.backpack_slots_used(), Inventory.backpack_max], Color(1.0, 0.45, 0.4))
		return

	if Inventory.withdraw_item(category, id, amount):
		_set_msg("Đã rút %d %s về túi đồ!" % [amount, item_name], Color(0.7, 0.95, 0.6))
		refresh()
	else:
		_set_msg("Túi đồ không đủ chỗ để nhận %s!" % item_name, Color(1.0, 0.45, 0.4))


func _get_item_name(category: String, id: String) -> String:
	match category:
		"seeds":
			var c := CropDB.get_crop(id)
			return "Hạt %s" % c.get("name", id) if not c.is_empty() else id
		"fish":
			var f := FishDB.get_fish(id)
			return str(f.get("name", id)) if not f.is_empty() else id
		"ores":
			var o := OreDB.get_ore(id)
			return str(o.get("name", id)) if not o.is_empty() else id
		"produce":
			var c := CropDB.get_crop(id)
			if not c.is_empty():
				return str(c.get("name", id))
			for a in PoultryDB.ANIMALS:
				if str(a.product) == id:
					return str(a.product_name)
	return id


func _get_item_icon(category: String, id: String) -> Texture2D:
	match category:
		"seeds":
			var c := CropDB.get_crop(id)
			return TextureGen.seed_icon(c) if not c.is_empty() else null
		"fish":
			var f := FishDB.get_fish(id)
			return TextureGen.fish_icon(str(f.color)) if not f.is_empty() else null
		"ores":
			return TextureGen.ore_item_icon(id)
		"produce":
			var c := CropDB.get_crop(id)
			if not c.is_empty():
				return TextureGen.prod_icon(c)
			for a in PoultryDB.ANIMALS:
				if str(a.product) == id:
					return TextureGen.get_product_icon(id)
	return null


func _section_title(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.16, 0.11, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	UIKit.label(h, text, 14, color)
	return p
