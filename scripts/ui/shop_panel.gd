extends CanvasLayer
# Cửa Hàng Bác Tư: Phong cách Quầy gỗ Chợ quê mộc mạc & ấm áp.

const CropDB := preload("res://scripts/crop_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal feedback(text: String)

const HOE_PRICE := 20

var money_label: Label
var rows: VBoxContainer
var scroll: ScrollContainer


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
	panel.custom_minimum_size = Vector2(900, 600)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	# --- Tiêu đề quầy hàng ---
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	v.add_child(head)

	var title := UIKit.title_label(head, "🏪 CỬA HÀNG NÔNG SẢN BÁC TƯ", 22, UIKit.COLOR_TEXT_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Huy hiệu tiền vàng
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
	money_label = UIKit.label(hm, "", 16, UIKit.COLOR_TEXT_GOLD)
	head.add_child(money_box)

	var close_btn := UIKit.styled_button(head, "✕ Đóng (Esc)", 14, "danger")
	close_btn.pressed.connect(close)

	# Dòng chào hỏi của Bác Tư
	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.22, 0.15, 0.10, 0.8), UIKit.COLOR_BORDER_WOOD, 6))
	v.add_child(banner)
	var sub := UIKit.label(banner, "🌾 \"Chào con! Mua hạt giống tốt về gieo, có nông sản chín cứ mang qua đây bác thu mua giá tốt.\"", 13, UIKit.COLOR_TEXT_BODY)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	UIKit.divider(v)

	# Danh sách thẻ hàng hóa
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(scroll)
	v.add_child(scroll)

	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	scroll.add_child(rows)


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		close()


func open() -> void:
	visible = true
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func refresh() -> void:
	money_label.text = "%d xu" % GameState.money
	for c in rows.get_children():
		c.queue_free()

	# 1. Nông cụ cuốc đất
	rows.add_child(_section_title("🛠️ NÔNG CỤ THIẾT YẾU", Color(0.9, 0.8, 0.6)))
	rows.add_child(_build_hoe_row())

	# 2. Hạt giống & nông sản đã mở khóa
	rows.add_child(_section_title("🌱 HẠT GIỐNG & NÔNG SẢN ĐANG CÓ", UIKit.COLOR_TEXT_GREEN))
	var unlocked_next := GameState.next_locked()
	for crop in CropDB.CROPS:
		if GameState.has_crop(str(crop.id)):
			rows.add_child(_build_owned_row(crop))

	# 3. Cây kế tiếp & bí ẩn
	if not unlocked_next.is_empty():
		rows.add_child(_section_title("🔒 GIỐNG CÂY KẾ TIẾP CẦN MỞ KHÓA", UIKit.COLOR_TEXT_TITLE))
		for crop in CropDB.CROPS:
			if str(crop.id) == str(unlocked_next.get("id", "")):
				rows.add_child(_build_unlock_row(crop))
			elif not GameState.has_crop(str(crop.id)):
				rows.add_child(_build_mystery_row())


func _section_title(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.16, 0.11, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	UIKit.label(h, text, 14, color)
	return p


func _build_hoe_row() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = TextureGen.hoe_icon()
	icon.custom_minimum_size = Vector2(30, 30)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot.add_child(icon)
	h.add_child(slot)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 2)
	h.add_child(info_v)

	var title_h := HBoxContainer.new()
	title_h.add_theme_constant_override("separation", 8)
	info_v.add_child(title_h)
	UIKit.label(title_h, "Cuốc Cày Đất", 16, UIKit.COLOR_TEXT_BODY)

	var owned_pill := PanelContainer.new()
	owned_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.18, 0.14, 0.10), UIKit.COLOR_BORDER_WOOD, 4))
	UIKit.label(owned_pill, "Đang có: ×%d cuốc" % Inventory.hoes, 12, Color(0.9, 0.85, 0.75))
	title_h.add_child(owned_pill)

	UIKit.label(info_v, "Dùng để xới đất cỏ thành đất trồng (mỗi cuốc cày được 1 ô đất)", 12, UIKit.COLOR_TEXT_MUTED)

	var buy := UIKit.styled_button(h, "+ Mua cuốc (%d xu)" % HOE_PRICE, 13, "buy")
	buy.custom_minimum_size = Vector2(160, 34)
	buy.disabled = GameState.money < HOE_PRICE
	buy.pressed.connect(_buy_hoe)
	return p


func _buy_hoe() -> void:
	if not Inventory.can_hold("hoe", "hoe"):
		feedback.emit("Túi đồ đã đầy (%d/%d)! Hãy cất bớt đồ vào nhà kho 🏚️" % [Inventory.backpack_slots_used(), Inventory.backpack_max])
		return
	if GameState.try_spend(HOE_PRICE):
		Inventory.add_hoes(1)
		refresh()
	else:
		feedback.emit("Không đủ xu mua cuốc!")


func _build_owned_row(crop: Dictionary) -> Control:
	var cid := str(crop.id)
	var seed_count := Inventory.seed_count(cid)
	var prod_count := Inventory.produce_count(cid)
	var seed_price := int(crop.seed_price)
	var sell_price := int(crop.sell_price)

	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = TextureGen.prod_icon(crop)
	icon.custom_minimum_size = Vector2(30, 30)
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
	UIKit.label(name_h, crop.name, 16, UIKit.COLOR_TEXT_TITLE)

	var grp := PanelContainer.new()
	grp.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.25, 0.18, 0.12), UIKit.COLOR_BORDER_WOOD, 4))
	UIKit.label(grp, str(crop.group), 11, UIKit.COLOR_TEXT_MUTED)
	name_h.add_child(grp)

	var grow_min := int(ceil(float(crop.grow_sec) / 60.0))
	UIKit.label(info_v, "Lớn ~%d phút khi đất ẩm · Mua hạt %d xu · Bán thu hoạch %d xu" % [grow_min, seed_price, sell_price], 12, UIKit.COLOR_TEXT_MUTED)

	# Nhóm Mua Hạt
	var buy_v := HBoxContainer.new()
	buy_v.add_theme_constant_override("separation", 6)
	h.add_child(buy_v)

	var seed_badge := PanelContainer.new()
	seed_badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07), UIKit.COLOR_BORDER_WOOD, 4))
	UIKit.label(seed_badge, "Hạt: ×%d" % seed_count, 13, Color(0.85, 0.95, 1.0))
	buy_v.add_child(seed_badge)

	var buy := UIKit.styled_button(buy_v, "+ Mua (%d xu)" % seed_price, 13, "buy")
	buy.custom_minimum_size = Vector2(110, 32)
	buy.disabled = GameState.money < seed_price
	buy.pressed.connect(_buy.bind(cid))

	# Nhóm Bán Nông Sản
	var sell_v := HBoxContainer.new()
	sell_v.add_theme_constant_override("separation", 6)
	h.add_child(sell_v)

	var prod_badge := PanelContainer.new()
	prod_badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07), UIKit.COLOR_BORDER_WOOD, 4))
	UIKit.label(prod_badge, "Có: ×%d" % prod_count, 13, UIKit.COLOR_TEXT_GOLD)
	sell_v.add_child(prod_badge)

	var sell1 := UIKit.styled_button(sell_v, "Bán 1", 13, "sell")
	sell1.custom_minimum_size = Vector2(65, 32)
	sell1.disabled = prod_count < 1
	sell1.pressed.connect(_sell.bind(cid, false))

	var sellall := UIKit.styled_button(sell_v, "Bán hết", 13, "sell")
	sellall.custom_minimum_size = Vector2(75, 32)
	sellall.disabled = prod_count < 1
	sellall.pressed.connect(_sell.bind(cid, true))

	return p


func _build_unlock_row(crop: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.15, 0.10), UIKit.COLOR_BORDER_GOLD, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var lock_box := PanelContainer.new()
	lock_box.add_theme_stylebox_override("panel", UIKit.slot_box(true))
	var lic := TextureRect.new()
	lic.texture = TextureGen.lock_icon()
	lic.custom_minimum_size = Vector2(28, 28)
	lic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	lock_box.add_child(lic)
	h.add_child(lock_box)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 2)
	h.add_child(info_v)

	var name_h := HBoxContainer.new()
	name_h.add_theme_constant_override("separation", 8)
	info_v.add_child(name_h)
	UIKit.label(name_h, "CÂY KẾ TIẾP: %s" % crop.name, 16, UIKit.COLOR_TEXT_TITLE)

	var grp := PanelContainer.new()
	grp.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.25, 0.18, 0.12), UIKit.COLOR_BORDER_WOOD, 4))
	UIKit.label(grp, str(crop.group), 11, UIKit.COLOR_TEXT_MUTED)
	name_h.add_child(grp)

	var grow_min := int(ceil(float(crop.grow_sec) / 60.0))
	UIKit.label(info_v, "%s · Lớn ~%d phút · Bán được %d xu/cái" % [crop.desc, grow_min, int(crop.sell_price)], 12, UIKit.COLOR_TEXT_MUTED)

	var price := int(crop.unlock_cost)
	var can_afford := (GameState.money >= price)
	var unlock_btn := UIKit.styled_button(h, "🔓 Mở khóa (%d xu)" % price, 14, "primary" if can_afford else "default")
	unlock_btn.custom_minimum_size = Vector2(170, 36)
	unlock_btn.disabled = not can_afford
	unlock_btn.pressed.connect(_unlock)

	return p


func _build_mystery_row() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_locked_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)

	var lic := TextureRect.new()
	lic.texture = TextureGen.lock_icon()
	lic.custom_minimum_size = Vector2(22, 22)
	lic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	lic.modulate = Color(1, 1, 1, 0.4)
	h.add_child(lic)

	var name_l := UIKit.label(h, "??? — Hạt giống bí ẩn", 15, Color(0.65, 0.60, 0.55))
	name_l.custom_minimum_size = Vector2(200, 0)

	UIKit.label(h, "Tích luỹ tiền mở khóa giống cây phía trên để khám phá giống này.", 13, Color(0.55, 0.50, 0.45))
	return p


func _buy(id: String) -> void:
	var c := CropDB.get_crop(id)
	if not Inventory.can_hold("seed", id):
		feedback.emit("Túi đồ đã đầy (%d/%d)! Hãy cất bớt đồ vào nhà kho 🏚️" % [Inventory.backpack_slots_used(), Inventory.backpack_max])
		return
	if GameState.try_spend(int(c.seed_price)):
		Inventory.add_seed(id, 1)
		refresh()
	else:
		feedback.emit("Không đủ xu để mua hạt %s!" % c.name)


func _sell(id: String, all: bool) -> void:
	var c := CropDB.get_crop(id)
	var have := Inventory.produce_count(id)
	if have < 1:
		return
	var n := have if all else 1
	if Inventory.take_produce(id, n):
		GameState.add_money(int(c.sell_price) * n)
		refresh()
		if all:
			feedback.emit("Đã bán %d %s (+%d xu)" % [n, c.name, int(c.sell_price) * n])


func _unlock() -> void:
	var c := GameState.next_locked()
	if GameState.unlock_next():
		feedback.emit("ĐÃ MỞ KHÓA: %s!" % c.get("name", "?"))
		refresh()
		scroll.scroll_vertical = 0
