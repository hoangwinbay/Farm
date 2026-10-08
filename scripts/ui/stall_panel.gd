extends CanvasLayer
# Giao diện Quản lý Sạp Hàng Nông Sản Của Tôi:
# Người chơi bày nông sản lên 6 ô sạp gỗ để bán cho dân làng NPC ghé mua.

const CropDB := preload("res://scripts/crop_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const OreDB := preload("res://scripts/ore_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal feedback(text: String, color: Color)
signal stall_changed
signal revenue_collected(amount: int)

var stall_slots: Array = []  # 6 phần tử Dictionary hoặc null
var stall_revenue: int = 0
var money_label: Label
var collect_btn: Button
var crates_grid: GridContainer
var inventory_rows: VBoxContainer
var scroll: ScrollContainer
var _active_filter := "all"  # "all", "crop", "fish", "poultry"

var _tab_all: Button
var _tab_crop: Button
var _tab_fish: Button
var _tab_poultry: Button
var _tab_ore: Button


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
	panel.custom_minimum_size = Vector2(920, 620)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	# --- Tiêu đề & Thông tin đầu trang ---
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	v.add_child(head)

	var title_v := VBoxContainer.new()
	title_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_v.add_theme_constant_override("separation", 2)
	head.add_child(title_v)

	UIKit.title_label(title_v, "🏪 SẠP HÀNG", 20, UIKit.COLOR_TEXT_TITLE)

	# Tiền hiện có
	var money_box := PanelContainer.new()
	money_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	var hm := HBoxContainer.new()
	hm.add_theme_constant_override("separation", 6)
	money_box.add_child(hm)
	var mic := TextureRect.new()
	mic.texture = TextureGen.coin_icon()
	mic.custom_minimum_size = Vector2(18, 18)
	mic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hm.add_child(mic)
	money_label = UIKit.label(hm, "%d xu" % GameState.money, 15, UIKit.COLOR_TEXT_GOLD)
	head.add_child(money_box)

	collect_btn = UIKit.styled_button(head, "🪙 Thu tiền: 0 xu", 13, "buy")
	collect_btn.custom_minimum_size = Vector2(130, 36)
	collect_btn.pressed.connect(_on_collect_pressed)
	collect_btn.visible = false

	var close_btn := UIKit.styled_button(head, "✕", 14, "danger")
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(close)

	v.add_child(HSeparator.new())

	# --- KHU VỰC 1: 6 Ô BÀY HÀNG TRÊN SẠP GỖ (2 hàng x 3 cột) ---
	var crates_header := HBoxContainer.new()
	crates_header.add_theme_constant_override("separation", 10)
	v.add_child(crates_header)
	UIKit.label(crates_header, "🧺 Ô TRƯNG BÀY (6 Ô)", 13, UIKit.COLOR_BORDER_BRIGHT)

	crates_grid = GridContainer.new()
	crates_grid.columns = 3
	crates_grid.add_theme_constant_override("h_separation", 10)
	crates_grid.add_theme_constant_override("v_separation", 8)
	v.add_child(crates_grid)

	v.add_child(HSeparator.new())

	# --- KHU VỰC 2: TÚI ĐỒ ĐỂ BÀY HÀNG LÊN SẠP ---
	var inv_header := HBoxContainer.new()
	inv_header.add_theme_constant_override("separation", 10)
	v.add_child(inv_header)
	UIKit.label(inv_header, "🎒 TÚI ĐỒ", 13, UIKit.COLOR_BORDER_BRIGHT)

	var tabs_h := HBoxContainer.new()
	tabs_h.add_theme_constant_override("separation", 6)
	tabs_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs_h.alignment = BoxContainer.ALIGNMENT_END
	inv_header.add_child(tabs_h)

	_tab_all = _make_tab(tabs_h, "Tất cả", "all")
	_tab_crop = _make_tab(tabs_h, "Nông sản", "crop")
	_tab_fish = _make_tab(tabs_h, "Cá tươi", "fish")
	_tab_poultry = _make_tab(tabs_h, "Gia cầm", "poultry")
	_tab_ore = _make_tab(tabs_h, "Quặng mỏ", "ore")

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)

	inventory_rows = VBoxContainer.new()
	inventory_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(inventory_rows)


func _make_tab(parent: Control, text: String, f_id: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(80, 28)
	b.add_theme_font_size_override("font_size", 12)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void:
		_active_filter = f_id
		_update_tab_styles()
		_build_inventory_list()
	)
	parent.add_child(b)
	return b


func _update_tab_styles() -> void:
	var tabs := [_tab_all, _tab_crop, _tab_fish, _tab_poultry, _tab_ore]
	var ids := ["all", "crop", "fish", "poultry", "ore"]
	for i in tabs.size():
		var btn: Button = tabs[i]
		if btn == null:
			continue
		if ids[i] == _active_filter:
			btn.add_theme_stylebox_override("normal", UIKit.badge_box(Color(0.36, 0.24, 0.12), UIKit.COLOR_BORDER_GOLD, 6))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
		else:
			btn.add_theme_stylebox_override("normal", UIKit.badge_box(Color(0.18, 0.12, 0.08), UIKit.COLOR_BORDER_WOOD, 6))
			btn.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)


func open(slots: Array, revenue: int = 0) -> void:
	stall_slots = slots
	stall_revenue = revenue
	visible = true
	_update_tab_styles()
	_refresh_ui()


func close() -> void:
	visible = false
	closed.emit()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()


func _on_collect_pressed() -> void:
	if stall_revenue <= 0:
		return
	var amt := stall_revenue
	GameState.add_money(amt)
	stall_revenue = 0
	revenue_collected.emit(amt)
	feedback.emit("Đã thu %d xu tiền bán hàng! 🪙" % amt, Color(1.0, 0.9, 0.4))
	_refresh_ui()


func _refresh_ui() -> void:
	if money_label != null:
		money_label.text = "%d xu" % GameState.money
	if collect_btn != null:
		collect_btn.visible = stall_revenue > 0
		collect_btn.text = "🪙 Thu tiền: %d xu" % stall_revenue
	_build_crates_display()
	_build_inventory_list()


# --- VẼ 6 Ô TRÊN SẠP HÀNG ---
func _build_crates_display() -> void:
	for c in crates_grid.get_children():
		c.queue_free()

	for i in 6:
		var slot: Dictionary = stall_slots[i] if i < stall_slots.size() and stall_slots[i] != null else {}
		var card := _build_crate_slot_card(i, slot)
		crates_grid.add_child(card)


func _build_crate_slot_card(idx: int, slot: Dictionary) -> Control:
	var is_empty: bool = slot.is_empty() or int(slot.get("count", 0)) <= 0

	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(288, 72)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if is_empty:
		p.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07, 0.9), UIKit.COLOR_BORDER_WOOD, 8))
	else:
		p.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.22, 0.15, 0.10, 0.95), UIKit.COLOR_BORDER_GOLD, 8))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)

	# Khung hình ô đựng
	var slot_box := PanelContainer.new()
	slot_box.custom_minimum_size = Vector2(52, 52)
	slot_box.add_theme_stylebox_override("panel", UIKit.slot_box(not is_empty))
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED

	if not is_empty:
		var s_id: String = str(slot.get("id", ""))
		var s_type: String = str(slot.get("type", "crop"))
		icon.texture = _get_item_icon(s_id, s_type)
	else:
		icon.texture = null

	slot_box.add_child(icon)
	h.add_child(slot_box)

	# Thông tin ô
	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 2)
	h.add_child(info_v)

	var title_lbl: String = "Ô %d: %s" % [idx + 1, slot.get("name", "Trống") if not is_empty else "Trống"]
	UIKit.label(info_v, title_lbl, 13, UIKit.COLOR_TEXT_TITLE if not is_empty else UIKit.COLOR_TEXT_MUTED)

	if not is_empty:
		var count: int = int(slot.get("count", 0))
		var price: int = int(slot.get("price", 0))
		UIKit.label(info_v, "×%d · %d xu/món" % [count, price], 11, UIKit.COLOR_TEXT_GOLD)

		var retrieve_btn := UIKit.styled_button(h, "Thu hồi", 11, "ghost")
		retrieve_btn.custom_minimum_size = Vector2(62, 28)
		retrieve_btn.pressed.connect(func() -> void:
			_retrieve_from_stall(idx)
		)
	else:
		UIKit.label(info_v, "(Trống)", 11, UIKit.COLOR_TEXT_MUTED)

	return p


# --- VẼ DANH SÁCH NÔNG SẢN TRONG TÚI ĐỒ ---
func _build_inventory_list() -> void:
	for c in inventory_rows.get_children():
		c.queue_free()

	var has_items := false

	# 1. Nông sản (crops)
	if _active_filter == "all" or _active_filter == "crop":
		for crop in CropDB.CROPS:
			var cid: String = str(crop.id)
			var count := Inventory.produce_count(cid)
			if count > 0:
				has_items = true
				var card := _build_inventory_item_card(cid, "crop", crop.name, count, int(crop.sell_price))
				inventory_rows.add_child(card)

	# 2. Cá (fish)
	if _active_filter == "all" or _active_filter == "fish":
		for f in FishDB.FISH:
			var fid: String = str(f.id)
			var count: int = int(Inventory.fish.get(fid, 0))
			if count > 0:
				has_items = true
				var card := _build_inventory_item_card(fid, "fish", f.name, count, int(f.price))
				inventory_rows.add_child(card)

	# 3. Sản phẩm chăn nuôi (poultry products)
	if _active_filter == "all" or _active_filter == "poultry":
		for a in PoultryDB.ANIMALS:
			var pid: String = str(a.product)
			var count := Inventory.produce_count(pid)
			if count > 0:
				has_items = true
				var card := _build_inventory_item_card(pid, "poultry", a.product_name, count, int(a.product_price))
				inventory_rows.add_child(card)

	# 4. Khoáng sản & Quặng (ores)
	if _active_filter == "all" or _active_filter == "ore":
		for ore in OreDB.ORES:
			var oid: String = str(ore.id)
			var count := Inventory.ore_count(oid)
			if count > 0:
				has_items = true
				var card := _build_inventory_item_card(oid, "ore", ore.name, count, int(ore.price))
				inventory_rows.add_child(card)

	if not has_items:
		var empty_box := PanelContainer.new()
		empty_box.add_theme_stylebox_override("panel", UIKit.row_locked_box())
		var l := UIKit.label(empty_box, "(Túi đồ chưa có nông sản/cá/quặng để bày bán. Hãy thu hoạch hoặc đào mỏ thêm!)", 13, UIKit.COLOR_TEXT_MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inventory_rows.add_child(empty_box)


func _build_inventory_item_card(id: String, type: String, name: String, count: int, base_price: int) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	# Icon
	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = _get_item_icon(id, type)
	icon.custom_minimum_size = Vector2(28, 28)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot.add_child(icon)
	h.add_child(slot)

	# Tên & Thông tin giá bán sạp
	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 2)
	h.add_child(info_v)

	UIKit.label(info_v, name, 14, UIKit.COLOR_TEXT_BODY)
	var stall_price: int = maxi(1, int(round(float(base_price) * 1.2)))
	UIKit.label(info_v, "%d xu" % stall_price, 12, UIKit.COLOR_TEXT_GOLD)

	# Số lượng có trong túi
	var count_pill := PanelContainer.new()
	count_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	UIKit.label(count_pill, "×%d cái" % count, 13, UIKit.COLOR_TEXT_TITLE)
	h.add_child(count_pill)

	# Nút Bày lên sạp
	var btn_v := HBoxContainer.new()
	btn_v.add_theme_constant_override("separation", 6)
	h.add_child(btn_v)

	var b1 := UIKit.styled_button(btn_v, "Bày 1", 12, "buy")
	b1.custom_minimum_size = Vector2(65, 30)
	b1.pressed.connect(func() -> void:
		_add_item_to_stall(id, type, name, stall_price, 1)
	)

	if count >= 5:
		var b5 := UIKit.styled_button(btn_v, "Bày 5", 12, "buy")
		b5.custom_minimum_size = Vector2(65, 30)
		b5.pressed.connect(func() -> void:
			_add_item_to_stall(id, type, name, stall_price, 5)
		)

	var ball := UIKit.styled_button(btn_v, "Bày hết", 12, "primary")
	ball.custom_minimum_size = Vector2(75, 30)
	ball.pressed.connect(func() -> void:
		_add_item_to_stall(id, type, name, stall_price, count)
	)

	return p


# --- XỬ LÝ BÀY HÀNG VÀ THU HỒI ---

func _add_item_to_stall(id: String, type: String, name: String, price: int, qty: int) -> void:
	# 1. Tìm ô đã có sẵn mặt hàng này để xếp chồng (stacking)
	var target_idx := -1
	for i in 6:
		if i < stall_slots.size() and stall_slots[i] != null and not stall_slots[i].is_empty():
			if str(stall_slots[i].get("id", "")) == id:
				target_idx = i
				break

	# 2. Nếu chưa có, tìm ô trống đầu tiên
	if target_idx < 0:
		for i in 6:
			if i >= stall_slots.size() or stall_slots[i] == null or stall_slots[i].is_empty():
				target_idx = i
				break

	if target_idx < 0:
		feedback.emit("Sạp hàng đã kín cả 6 ô! Hãy thu hồi bớt để bày món mới.", Color(1.0, 0.6, 0.4))
		return

	# Lấy hàng từ kho người chơi
	var taken := false
	if type == "fish":
		var cur_f := int(Inventory.fish.get(id, 0))
		var n: int = mini(qty, cur_f)
		if n > 0:
			Inventory.fish[id] = cur_f - n
			qty = n
			taken = true
			Inventory.changed.emit()
	elif type == "ore":
		var cur_o := Inventory.ore_count(id)
		var n: int = mini(qty, cur_o)
		if n > 0:
			taken = Inventory.take_ore(id, n)
			qty = n
	else:
		var cur_p := Inventory.produce_count(id)
		var n: int = mini(qty, cur_p)
		if n > 0:
			taken = Inventory.take_produce(id, n)
			qty = n

	if not taken or qty <= 0:
		return

	# Cập nhật ô sạp hàng
	while stall_slots.size() <= target_idx:
		stall_slots.append({})

	if stall_slots[target_idx] == null or stall_slots[target_idx].is_empty():
		stall_slots[target_idx] = {
			"id": id,
			"type": type,
			"name": name,
			"count": qty,
			"price": price,
		}
	else:
		stall_slots[target_idx]["count"] = int(stall_slots[target_idx].get("count", 0)) + qty

	stall_changed.emit()
	_refresh_ui()
	feedback.emit("Đã bày %d %s lên ô %d của sạp hàng! 🧺" % [qty, name, target_idx + 1], Color(0.65, 0.95, 0.6))


func _retrieve_from_stall(idx: int) -> void:
	if idx >= stall_slots.size() or stall_slots[idx] == null or stall_slots[idx].is_empty():
		return

	var slot: Dictionary = stall_slots[idx]
	var id: String = str(slot.get("id", ""))
	var type: String = str(slot.get("type", "crop"))
	var name: String = str(slot.get("name", ""))
	var count: int = int(slot.get("count", 0))
	var item_cat := "produce"
	if type == "fish":
		item_cat = "fish"
	elif type == "ore":
		item_cat = "ore"
	if not Inventory.can_hold(item_cat, id):
		feedback.emit("Túi đồ đã đầy (%d/%d)! Hãy cất bớt đồ vào nhà kho 🏚️ trước khi thu hồi." % [Inventory.backpack_slots_used(), Inventory.backpack_max], Color(1.0, 0.5, 0.4))
		return

	if count > 0:
		if type == "fish":
			Inventory.fish[id] = int(Inventory.fish.get(id, 0)) + count
			Inventory.changed.emit()
		elif type == "ore":
			Inventory.add_ore(id, count)
		else:
			Inventory.add_produce(id, count)

	stall_slots[idx] = {}
	stall_changed.emit()
	_refresh_ui()
	feedback.emit("Đã thu hồi %d %s về túi đồ! 🎒" % [count, name], Color(1.0, 0.9, 0.5))


func _get_item_icon(id: String, type: String) -> Texture2D:
	if type == "fish":
		var f := FishDB.get_fish(id)
		return TextureGen.fish_icon(str(f.color)) if not f.is_empty() else null
	elif type == "crop":
		var c := CropDB.get_crop(id)
		return TextureGen.prod_icon(c) if not c.is_empty() else null
	elif type == "ore":
		return TextureGen.ore_item_icon(id)
	else:
		# Sản phẩm chăn nuôi (trứng, sữa, thịt, lông)
		return TextureGen.get_product_icon(id)
	return null
