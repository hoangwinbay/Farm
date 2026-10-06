extends CanvasLayer
# Trại Giống Cô Tư: Phong cách Nhà vườn nông thôn ấm áp, thẻ chuồng trại & gia cầm mộc mạc.

const PoultryDB := preload("res://scripts/poultry_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal feedback(text: String)

var money_label: Label
var rows: VBoxContainer


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
	panel.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 3, Color(0.18, 0.12, 0.08, 0.98), Color(1.0, 0.72, 0.45)))
	panel.custom_minimum_size = Vector2(880, 600)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	# --- Tiêu đề trang trại ---
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	v.add_child(head)

	var title := UIKit.title_label(head, "🐔 TRẠI GIỐNG CÔ TƯ — CHĂN NUÔI", 22, Color(1.0, 0.82, 0.60))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Tiền vàng
	var money_box := PanelContainer.new()
	money_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.22, 0.14, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
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

	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.16, 0.10, 0.8), Color(0.65, 0.45, 0.30), 6))
	v.add_child(banner)
	var sub := UIKit.label(banner, "🌾 \"Cô Tư chuyên cung cấp 4 giống vật nuôi tốt nhất làng: Gà trắng, Bò trắng, Lợn và Cừu. Mua chuồng trước rồi thả giống nghen (Cấp 1 nuôi 2 con, Cấp 2 nuôi 4 con)! Nuôi đủ đôi (2 con cùng loài) là chúng có thể sinh ra con non baby!\"", 13, UIKit.COLOR_TEXT_BODY)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	UIKit.divider(v)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(sc)
	v.add_child(sc)

	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	sc.add_child(rows)


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

	# 1. Chuồng nuôi
	rows.add_child(_section_title("🏡 CHUỒNG TRẠI (MUA & NÂNG CẤP)", Color(1.0, 0.85, 0.65)))
	for cid in ["cow", "chicken", "sheep", "pig"]:
		var cdata := PoultryDB.get_coop_data(cid)
		if not cdata.is_empty():
			rows.add_child(_build_coop_row(cdata))

	# 2. Con giống
	rows.add_child(_section_title("🐣 CON GIỐNG (GÀ, BÒ, LỢN, CỪU)", UIKit.COLOR_TEXT_GREEN))
	for a in PoultryDB.ANIMALS:
		rows.add_child(_build_animal_row(a))

	# 3. Sản phẩm chăn nuôi
	var prod_head := HBoxContainer.new()
	var prod_title := _section_title("🧺 THU MUA SẢN PHẨM CHĂN NUÔI", UIKit.COLOR_TEXT_TITLE)
	prod_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prod_head.add_child(prod_title)

	var total_prod_val := _total_product_value()
	if total_prod_val > 0:
		var sell_all_btn := UIKit.styled_button(prod_head, "⭐ BÁN HẾT SẢN PHẨM (+%d xu)" % total_prod_val, 13, "sell")
		sell_all_btn.pressed.connect(_sell_all_products)
	rows.add_child(prod_head)

	var any := false
	for a in PoultryDB.ANIMALS:
		var pid := str(a.product)
		var n := Inventory.produce_count(pid)
		if n < 1:
			continue
		any = true
		rows.add_child(_build_product_row(a, n))

	if not any:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UIKit.row_locked_box())
		var l := UIKit.label(p, "(Chưa có sản phẩm nào — hãy nuôi gia cầm rồi ra chuồng bấm [E] để thu hoạch)", 13, UIKit.COLOR_TEXT_MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rows.add_child(p)


func _section_title(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.18, 0.12, 0.08), UIKit.COLOR_BORDER_WOOD, 6))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	UIKit.label(h, text, 14, color)
	return p


func _total_product_value() -> int:
	var total := 0
	for a in PoultryDB.ANIMALS:
		var pid := str(a.product)
		var n := Inventory.produce_count(pid)
		total += n * int(a.product_price)
	return total


func _sell_all_products() -> void:
	var total := 0
	var count := 0
	for a in PoultryDB.ANIMALS:
		var pid := str(a.product)
		var n := Inventory.produce_count(pid)
		if n > 0 and Inventory.take_produce(pid, n):
			total += n * int(a.product_price)
			count += n
	if total > 0:
		GameState.add_money(total)
		feedback.emit("Đã bán %d sản phẩm chăn nuôi (+%d xu)!" % [count, total])
		refresh()


func _build_coop_row(coop: Dictionary) -> Control:
	var cid := str(coop.id)
	var tier := Inventory.get_coop_tier(cid)
	var count := Inventory.animals_of_species(cid)

	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	if cid == "chicken":
		icon.texture = TextureGen.get_tex("coop_tier2" if tier >= 2 else "coop_tier1")
	else:
		icon.texture = TextureGen.get_tex("barn_tier2" if tier >= 2 else "barn_tier1")
	icon.custom_minimum_size = Vector2(36, 28)
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
	UIKit.label(name_h, str(coop.name), 16, Color(1.0, 0.92, 0.75))

	var count_pill := PanelContainer.new()
	count_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.22, 0.16, 0.11), UIKit.COLOR_BORDER_WOOD, 4))
	var tag_text := ""
	var tag_col := Color(0.9, 0.8, 0.5)
	if tier == 0:
		tag_text = "Chưa mua (Khu đất rào gỗ)"
		tag_col = Color(0.8, 0.7, 0.5)
	elif tier == 1:
		tag_text = "Cấp 1 — Sức chứa: 2 con (Đang nuôi: %d)" % count
		tag_col = Color(0.6, 0.9, 0.6)
	else:
		tag_text = "Cấp 2 (Tối đa) — Sức chứa: 4 con (Đang nuôi: %d)" % count
		tag_col = Color(1.0, 0.85, 0.3)
	UIKit.label(count_pill, tag_text, 12, tag_col)
	name_h.add_child(count_pill)

	var desc_text := str(coop.desc_t0)
	if tier == 1:
		desc_text = str(coop.desc_t1)
	elif tier >= 2:
		desc_text = str(coop.desc_t2)
	UIKit.label(info_v, desc_text, 12, UIKit.COLOR_TEXT_MUTED)

	if tier == 0:
		var price := int(coop.tier1_price)
		var buy := UIKit.styled_button(h, "+ Mua Cấp 1 (%d xu)" % price, 13, "buy")
		buy.custom_minimum_size = Vector2(175, 34)
		buy.disabled = GameState.money < price
		buy.pressed.connect(_buy_coop.bind(cid))
	elif tier == 1:
		var price := int(coop.tier2_price)
		var up := UIKit.styled_button(h, "▲ Nâng cấp Cấp 2 (%d xu)" % price, 13, "upgrade")
		up.custom_minimum_size = Vector2(175, 34)
		up.disabled = GameState.money < price
		up.pressed.connect(_upgrade_coop.bind(cid))
	else:
		var max_btn := UIKit.styled_button(h, "✔ Đã đạt tối đa", 13, "secondary")
		max_btn.custom_minimum_size = Vector2(175, 34)
		max_btn.disabled = true
	return p


func _build_animal_row(a: Dictionary) -> Control:
	var aid := str(a.id)
	var price := int(a.price)
	var tier := Inventory.get_coop_tier(aid)
	var slots := Inventory.free_slots(aid)
	var coop_data := PoultryDB.get_coop_data(aid)
	var cname := str(coop_data.get("name", "Chuồng"))

	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = TextureGen.get_animal_icon(aid)
	icon.custom_minimum_size = Vector2(32, 32)
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
	UIKit.label(name_h, a.name, 15, UIKit.COLOR_TEXT_BODY)

	var req_pill := PanelContainer.new()
	req_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.15, 0.10), UIKit.COLOR_BORDER_WOOD, 4))
	UIKit.label(req_pill, cname, 11, UIKit.COLOR_TEXT_MUTED)
	name_h.add_child(req_pill)

	var owned_adult := 0
	var owned_baby := 0
	for an in Inventory.animals:
		if PoultryDB.get_canonical_id(str(an.id)) == aid:
			if bool(an.get("is_baby", false)):
				owned_baby += 1
			else:
				owned_adult += 1
	if owned_adult > 0 or owned_baby > 0:
		var owned_pill := PanelContainer.new()
		owned_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.18, 0.24, 0.14), Color(0.4, 0.8, 0.3), 4))
		var otxt := "Đang nuôi: %d lớn" % owned_adult
		if owned_baby > 0:
			otxt += ", %d baby" % owned_baby
		UIKit.label(owned_pill, otxt, 11, Color(0.6, 1.0, 0.5))
		name_h.add_child(owned_pill)

	UIKit.label(info_v, "Cho %s (%d xu) mỗi %ds · Nuôi 2 con sẽ đẻ ra baby" % [a.product_name, int(a.product_price), int(a.interval)], 12, UIKit.COLOR_TEXT_GOLD)

	var slot_color := Color(0.6, 0.95, 0.6) if (tier > 0 and slots > 0) else Color(0.9, 0.45, 0.4)
	var slot_txt := ""
	if tier == 0:
		slot_txt = "Chưa có %s!" % cname
	elif slots <= 0:
		slot_txt = "%s kín chỗ!" % cname
	else:
		slot_txt = "Trống: %d chỗ" % slots

	var slot_badge := PanelContainer.new()
	slot_badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07), UIKit.COLOR_BORDER_WOOD, 4))
	UIKit.label(slot_badge, slot_txt, 12, slot_color)
	h.add_child(slot_badge)

	var buy := UIKit.styled_button(h, "+ Mua (%d xu)" % price, 13, "buy")
	buy.custom_minimum_size = Vector2(130, 32)
	buy.disabled = (tier == 0 or slots < 1 or GameState.money < price)
	buy.pressed.connect(_buy_animal.bind(aid))
	if tier == 0:
		buy.tooltip_text = "Cần mua %s Cấp 1 trước!" % cname
	elif slots < 1:
		buy.tooltip_text = "%s đã kín chỗ! Hãy nâng cấp lên Cấp 2." % cname
	return p


func _build_product_row(a: Dictionary, n: int) -> Control:
	var pid := str(a.product)
	var price := int(a.product_price)

	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = TextureGen.get_product_icon(pid)
	icon.custom_minimum_size = Vector2(30, 30)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot.add_child(icon)
	h.add_child(slot)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 2)
	h.add_child(info_v)

	UIKit.label(info_v, a.product_name, 15, Color(1.0, 0.95, 0.85))
	UIKit.label(info_v, "Thu hoạch từ %s · Giá bán: %d xu/cái" % [a.name, price], 12, UIKit.COLOR_TEXT_MUTED)

	var count_pill := PanelContainer.new()
	count_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	UIKit.label(count_pill, "×%d cái" % n, 14, UIKit.COLOR_TEXT_TITLE)
	h.add_child(count_pill)

	var sell1 := UIKit.styled_button(h, "Bán 1", 13, "sell")
	sell1.custom_minimum_size = Vector2(65, 32)
	sell1.pressed.connect(_sell_product.bind(pid, price, a.product_name, false))

	var sellall := UIKit.styled_button(h, "Bán hết", 13, "sell")
	sellall.custom_minimum_size = Vector2(75, 32)
	sellall.pressed.connect(_sell_product.bind(pid, price, a.product_name, true))
	return p


func _buy_coop(id: String) -> void:
	var err := Inventory.buy_coop(id)
	if err == "":
		var c := PoultryDB.get_coop_data(id)
		feedback.emit("Đã mua %s Cấp 1! Bắt đầu thả con giống." % str(c.name))
		refresh()
	else:
		feedback.emit(err)


func _upgrade_coop(id: String) -> void:
	var err := Inventory.upgrade_coop(id)
	if err == "":
		var c := PoultryDB.get_coop_data(id)
		feedback.emit("Đã nâng cấp %s lên Cấp 2! Sức chứa 4 con & đủ chỗ cho baby." % str(c.name))
		refresh()
	else:
		feedback.emit(err)


func _buy_animal(id: String) -> void:
	var err := Inventory.buy_animal(id)
	if err == "":
		var a := PoultryDB.get_animal(id)
		feedback.emit("Đã mua giống %s! Thả vào chuồng rồi chờ thu sản phẩm." % a.name)
		refresh()
	else:
		feedback.emit(err)


func _sell_product(pid: String, price: int, pname: String, all: bool) -> void:
	var have := Inventory.produce_count(pid)
	if have < 1:
		return
	var n := have if all else 1
	if Inventory.take_produce(pid, n):
		GameState.add_money(price * n)
		refresh()
		if all:
			feedback.emit("Đã bán %d %s (+%d xu)" % [n, pname, price * n])
