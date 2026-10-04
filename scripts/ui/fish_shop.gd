extends CanvasLayer
# Quầy Cá Chú Hai: Phong cách Bến sông quê mộc mạc với viền gỗ xanh mát.

const FishDB := preload("res://scripts/fish_db.gd")
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
	dim.color = Color(0.04, 0.07, 0.09, 0.68)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 3, Color(0.12, 0.16, 0.18, 0.98), Color(0.45, 0.75, 0.90)))
	panel.custom_minimum_size = Vector2(860, 580)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	# --- Tiêu đề bến cá ---
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	v.add_child(head)

	var title := UIKit.title_label(head, "🎣 BẾN CÁ CHÚ HAI", 22, Color(0.55, 0.88, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Tiền vàng
	var money_box := PanelContainer.new()
	money_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.10, 0.18, 0.22), UIKit.COLOR_BORDER_GOLD, 6))
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
	banner.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.10, 0.18, 0.22, 0.8), Color(0.35, 0.60, 0.75), 6))
	v.add_child(banner)
	var sub := UIKit.label(banner, "🌊 \"Cá ở ao này béo lắm con! Cần câu xịn sẽ tăng số lượt câu. Nhớ là Cá Trê Vàng chỉ cắn câu ban ĐÊM thôi nghe!\"", 13, Color(0.85, 0.95, 1.0))
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

	# 1. Cần câu
	rows.add_child(_section_title("🎣 CẦN CÂU CÁ CÁC CẤP", Color(0.55, 0.88, 1.0)))
	for rod in FishDB.RODS:
		rows.add_child(_build_rod_row(rod))

	# 2. Bán cá
	var head_fish := HBoxContainer.new()
	var fish_title := _section_title("🐟 GIỎ CÁ CỦA BẠN (BÁN CHO CHÚ)", UIKit.COLOR_TEXT_TITLE)
	fish_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_fish.add_child(fish_title)

	# Nút bán tất cả cá
	var total_fish_val := _total_fish_value()
	if total_fish_val > 0:
		var sell_all_btn := UIKit.styled_button(head_fish, "⭐ BÁN TẤT CẢ CÁ (+%d xu)" % total_fish_val, 13, "sell")
		sell_all_btn.pressed.connect(_sell_all_fish)
	rows.add_child(head_fish)

	var any := false
	for f in FishDB.FISH:
		var n := Inventory.fish_count(str(f.id))
		if n < 1:
			continue
		any = true
		rows.add_child(_build_fish_row(f))

	if not any:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UIKit.row_locked_box())
		var l := UIKit.label(p, "(Chưa có cá nào — hãy ra AO thả câu bấm [E] để câu cá)", 13, UIKit.COLOR_TEXT_MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rows.add_child(p)


func _section_title(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.10, 0.16, 0.20), Color(0.35, 0.60, 0.75), 6))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	UIKit.label(h, text, 14, color)
	return p


func _total_fish_value() -> int:
	var total := 0
	for f in FishDB.FISH:
		var n := Inventory.fish_count(str(f.id))
		total += n * int(f.price)
	return total


func _sell_all_fish() -> void:
	var total := 0
	var count := 0
	for f in FishDB.FISH:
		var fid := str(f.id)
		var n := Inventory.fish_count(fid)
		if n > 0 and Inventory.take_fish(fid, n):
			total += n * int(f.price)
			count += n
	if total > 0:
		GameState.add_money(total)
		feedback.emit("Đã bán toàn bộ %d con cá (+%d xu)!" % [count, total])
		refresh()


func _build_rod_row(rod: Dictionary) -> Control:
	var tier := str(rod.tier)
	var price := int(rod.price)
	var remaining := Inventory.rod_casts(tier)

	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = TextureGen.rod_icon(str(rod.color))
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
	UIKit.label(name_h, rod.name, 16, Color(0.95, 0.95, 1.0))

	var casts_pill := PanelContainer.new()
	casts_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.20, 0.26), Color(0.40, 0.65, 0.85), 4))
	UIKit.label(casts_pill, "%d lượt/cần" % int(rod.casts), 12, Color(0.75, 0.90, 1.0))
	name_h.add_child(casts_pill)

	var remain_color := Color(0.65, 0.95, 0.65) if remaining > 0 else UIKit.COLOR_TEXT_MUTED
	UIKit.label(info_v, "Hiện đang còn: %d lượt câu trong túi" % remaining, 13, remain_color)

	var buy := UIKit.styled_button(h, "+ Mua (%d xu)" % price, 14, "buy")
	buy.custom_minimum_size = Vector2(140, 34)
	buy.disabled = GameState.money < price
	buy.pressed.connect(_buy_rod.bind(tier))
	return p


func _build_fish_row(f: Dictionary) -> Control:
	var fid := str(f.id)
	var price := int(f.price)
	var count := Inventory.fish_count(fid)

	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.row_box())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var icon := TextureRect.new()
	icon.texture = TextureGen.fish_icon(str(f.color))
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
	UIKit.label(name_h, f.name, 15, Color(0.9, 0.95, 1.0))

	var tier_pill := PanelContainer.new()
	tier_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.18, 0.22), Color(0.40, 0.65, 0.85), 4))
	UIKit.label(tier_pill, str(f.tier).capitalize(), 11, Color(0.7, 0.85, 1.0))
	name_h.add_child(tier_pill)

	UIKit.label(info_v, "Giá bán cho Chú Hai: %d xu/con" % price, 12, UIKit.COLOR_TEXT_GOLD)

	# Số lượng đang có
	var count_pill := PanelContainer.new()
	count_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.10, 0.16, 0.22), UIKit.COLOR_BORDER_WOOD, 6))
	UIKit.label(count_pill, "×%d con" % count, 14, UIKit.COLOR_TEXT_TITLE)
	h.add_child(count_pill)

	var sell1 := UIKit.styled_button(h, "Bán 1", 13, "sell")
	sell1.custom_minimum_size = Vector2(65, 32)
	sell1.pressed.connect(_sell_fish.bind(fid, false))

	var sellall := UIKit.styled_button(h, "Bán hết", 13, "sell")
	sellall.custom_minimum_size = Vector2(75, 32)
	sellall.pressed.connect(_sell_fish.bind(fid, true))
	return p


func _buy_rod(tier: String) -> void:
	var rod := FishDB.get_rod(tier)
	if not Inventory.can_hold("rod", tier):
		feedback.emit("Túi đồ đã đầy (%d/%d)! Cất bớt đồ vào nhà kho 🏚️" % [Inventory.backpack_slots_used(), Inventory.backpack_max])
		return
	if GameState.try_spend(int(rod.price)):
		Inventory.add_rod(tier, int(rod.casts))
		feedback.emit("Đã mua %s (+%d lượt câu)!" % [rod.name, int(rod.casts)])
		refresh()
	else:
		feedback.emit("Không đủ xu mua %s!" % rod.name)


func _sell_fish(id: String, all: bool) -> void:
	var f := FishDB.get_fish(id)
	var have := Inventory.fish_count(id)
	if have < 1:
		return
	var n := have if all else 1
	if Inventory.take_fish(id, n):
		GameState.add_money(int(f.price) * n)
		refresh()
		if all:
			feedback.emit("Đã bán %d %s (+%d xu)" % [n, f.name, int(f.price) * n])
