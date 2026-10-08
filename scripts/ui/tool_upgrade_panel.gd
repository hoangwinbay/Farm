extends CanvasLayer
# Bàn Rèn Nâng Cấp Dụng Cụ (Leah) - Giảm tiêu hao thể lực và tăng hiệu suất.

const OreDB := preload("res://scripts/ore_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal feedback(text: String, color: Color)

var money_label: Label
var copper_label: Label
var iron_label: Label
var gold_label: Label

# Thẻ Cuốc Đất (Hoe)
var hoe_icon_rect: TextureRect
var hoe_tier_label: Label
var hoe_stamina_label: Label
var hoe_desc_label: Label
var hoe_next_container: VBoxContainer
var hoe_next_title: Label
var hoe_next_stamina: Label
var hoe_cost_label: Label
var hoe_upgrade_btn: Button

# Thẻ Cúp Khai Mỏ (Pickaxe)
var pickaxe_icon_rect: TextureRect
var pickaxe_tier_label: Label
var pickaxe_power_label: Label
var pickaxe_stamina_label: Label
var pickaxe_desc_label: Label
var pickaxe_next_container: VBoxContainer
var pickaxe_next_title: Label
var pickaxe_next_stats: Label
var pickaxe_cost_label: Label
var pickaxe_upgrade_btn: Button


func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.02, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 3, Color(0.14, 0.10, 0.08, 0.98), Color(0.85, 0.62, 0.28)))
	panel.custom_minimum_size = Vector2(860, 560)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	# --- Header: Tiêu đề + Nút Đóng ---
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	v.add_child(head)

	var title := UIKit.title_label(head, "⚒️ LÒ RÈN DỤNG CỤ - LEAH", 22, Color(1.0, 0.88, 0.45))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var btn_close := UIKit.styled_button(head, "✕ Đóng", 14, "close")
	btn_close.custom_minimum_size = Vector2(80, 32)
	btn_close.pressed.connect(close)

	# --- Thanh tài nguyên (Tiền + Quặng khoáng sản) ---
	var res_box := PanelContainer.new()
	res_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.10, 0.95), UIKit.COLOR_BORDER_WOOD, 8))
	v.add_child(res_box)

	var res_hb := HBoxContainer.new()
	res_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	res_hb.add_theme_constant_override("separation", 24)
	res_box.add_child(res_hb)

	# Tiền xu
	var coin_box := HBoxContainer.new()
	coin_box.add_theme_constant_override("separation", 6)
	res_hb.add_child(coin_box)
	var coin_ic := TextureRect.new()
	coin_ic.texture = TextureGen.coin_icon()
	coin_ic.custom_minimum_size = Vector2(20, 20)
	coin_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_box.add_child(coin_ic)
	money_label = UIKit.label(coin_box, "0 xu", 15, UIKit.COLOR_TEXT_GOLD)

	# Quặng Đồng
	var cop_box := HBoxContainer.new()
	cop_box.add_theme_constant_override("separation", 6)
	res_hb.add_child(cop_box)
	var cop_ic := TextureRect.new()
	cop_ic.texture = TextureGen.ore_item_icon("copper_ore")
	cop_ic.custom_minimum_size = Vector2(20, 20)
	cop_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cop_box.add_child(cop_ic)
	copper_label = UIKit.label(cop_box, "Đồng: 0", 15, Color(0.95, 0.65, 0.45))

	# Quặng Sắt
	var iron_box := HBoxContainer.new()
	iron_box.add_theme_constant_override("separation", 6)
	res_hb.add_child(iron_box)
	var iron_ic := TextureRect.new()
	iron_ic.texture = TextureGen.ore_item_icon("iron_ore")
	iron_ic.custom_minimum_size = Vector2(20, 20)
	iron_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	iron_box.add_child(iron_ic)
	iron_label = UIKit.label(iron_box, "Sắt: 0", 15, Color(0.85, 0.90, 0.95))

	# Quặng Vàng
	var gold_box := HBoxContainer.new()
	gold_box.add_theme_constant_override("separation", 6)
	res_hb.add_child(gold_box)
	var gold_ic := TextureRect.new()
	gold_ic.texture = TextureGen.ore_item_icon("gold_ore")
	gold_ic.custom_minimum_size = Vector2(20, 20)
	gold_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gold_box.add_child(gold_ic)
	gold_label = UIKit.label(gold_box, "Vàng: 0", 15, Color(1.0, 0.88, 0.35))

	# --- Thân panel: 2 Cột thẻ Nâng cấp Cuốc đất & Cúp khai mỏ ---
	var cards_hb := HBoxContainer.new()
	cards_hb.add_theme_constant_override("separation", 16)
	cards_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cards_hb)

	_build_hoe_card(cards_hb)
	_build_pickaxe_card(cards_hb)

	# --- Footer: Lời khuyên của Leah ---
	var tip_box := PanelContainer.new()
	tip_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.09, 0.07, 0.8), Color(0.4, 0.3, 0.2), 6))
	v.add_child(tip_box)

	var tip_lbl := UIKit.label(tip_box, "💡 Mẹo: Khai thác khoáng sản dưới Hầm Mỏ Tây Bắc để tìm quặng rèn nông cụ. Nâng cấp giúp tiết kiệm rất nhiều thể lực!", 13, UIKit.COLOR_TEXT_MUTED)
	tip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_hoe_card(parent: Control) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.wood_frame(10, 2, Color(0.20, 0.15, 0.11, 0.95), Color(0.65, 0.45, 0.25)))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)

	# Header thẻ
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	vb.add_child(top)

	hoe_icon_rect = TextureRect.new()
	hoe_icon_rect.custom_minimum_size = Vector2(44, 44)
	hoe_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hoe_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(hoe_icon_rect)

	var title_vb := VBoxContainer.new()
	title_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_vb)

	UIKit.label(title_vb, "🌱 CUỐC ĐẤT", 18, Color(1.0, 0.92, 0.65))
	hoe_tier_label = UIKit.label(title_vb, "Cuốc thường", 14, Color(0.85, 0.85, 0.85))

	var sep1 := HSeparator.new()
	sep1.add_theme_constant_override("separation", 4)
	vb.add_child(sep1)

	# Thông số hiện tại
	hoe_stamina_label = UIKit.label(vb, "⚡ Thể lực tiêu hao: 7⚡ / lần cuốc", 14, Color(1.0, 0.75, 0.45))
	hoe_desc_label = UIKit.label(vb, "Cuốc nông nghiệp cơ bản.", 13, UIKit.COLOR_TEXT_MUTED)
	hoe_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var sep2 := HSeparator.new()
	sep2.add_theme_constant_override("separation", 8)
	vb.add_child(sep2)

	# Thông tin nâng cấp tiếp theo
	hoe_next_container = VBoxContainer.new()
	hoe_next_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hoe_next_container.add_theme_constant_override("separation", 6)
	vb.add_child(hoe_next_container)

	hoe_next_title = UIKit.label(hoe_next_container, "Cấp kế tiếp: Cuốc đồng", 15, Color(0.95, 0.85, 0.4))
	hoe_next_stamina = UIKit.label(hoe_next_container, "⚡ Giảm thể lực: còn 5⚡ (Tiết kiệm -2⚡)", 14, Color(0.55, 0.95, 0.55))
	hoe_cost_label = UIKit.label(hoe_next_container, "Chi phí: 300 xu + 5 Quặng Đồng", 13, Color(1.0, 0.85, 0.5))

	# Nút bấm nâng cấp
	hoe_upgrade_btn = UIKit.styled_button(vb, "NÂNG CẤP CUỐC", 15, "gold")
	hoe_upgrade_btn.custom_minimum_size = Vector2(0, 38)
	hoe_upgrade_btn.pressed.connect(_on_upgrade_hoe_pressed)


func _build_pickaxe_card(parent: Control) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.wood_frame(10, 2, Color(0.20, 0.15, 0.11, 0.95), Color(0.65, 0.45, 0.25)))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)

	# Header thẻ
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	vb.add_child(top)

	pickaxe_icon_rect = TextureRect.new()
	pickaxe_icon_rect.custom_minimum_size = Vector2(44, 44)
	pickaxe_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pickaxe_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(pickaxe_icon_rect)

	var title_vb := VBoxContainer.new()
	title_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_vb)

	UIKit.label(title_vb, "⛏️ CÚP KHAI MỎ", 18, Color(1.0, 0.92, 0.65))
	pickaxe_tier_label = UIKit.label(title_vb, "Cúp sơ cấp", 14, Color(0.85, 0.85, 0.85))

	var sep1 := HSeparator.new()
	sep1.add_theme_constant_override("separation", 4)
	vb.add_child(sep1)

	# Thông số hiện tại
	pickaxe_power_label = UIKit.label(vb, "🔨 Sức đập quặng: Cấp 1", 14, Color(0.7, 0.85, 1.0))
	pickaxe_stamina_label = UIKit.label(vb, "⚡ Thể lực tiêu hao: 5⚡ / lần đập", 14, Color(1.0, 0.75, 0.45))
	pickaxe_desc_label = UIKit.label(vb, "Cúp đập đá do Leah tặng.", 13, UIKit.COLOR_TEXT_MUTED)
	pickaxe_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var sep2 := HSeparator.new()
	sep2.add_theme_constant_override("separation", 8)
	vb.add_child(sep2)

	# Thông tin nâng cấp tiếp theo
	pickaxe_next_container = VBoxContainer.new()
	pickaxe_next_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pickaxe_next_container.add_theme_constant_override("separation", 6)
	vb.add_child(pickaxe_next_container)

	pickaxe_next_title = UIKit.label(pickaxe_next_container, "Cấp kế tiếp: Cúp đồng", 15, Color(0.95, 0.85, 0.4))
	pickaxe_next_stats = UIKit.label(pickaxe_next_container, "🔨 Sức đập x2 | ⚡ Giảm thể lực: còn 4⚡ (-1⚡)", 14, Color(0.55, 0.95, 0.55))
	pickaxe_cost_label = UIKit.label(pickaxe_next_container, "Chi phí: 350 xu + 5 Quặng Đồng", 13, Color(1.0, 0.85, 0.5))

	# Nút bấm nâng cấp
	pickaxe_upgrade_btn = UIKit.styled_button(vb, "NÂNG CẤP CÚP", 15, "gold")
	pickaxe_upgrade_btn.custom_minimum_size = Vector2(0, 38)
	pickaxe_upgrade_btn.pressed.connect(_on_upgrade_pickaxe_pressed)


func open() -> void:
	visible = true
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func refresh() -> void:
	# 1. Cập nhật tài nguyên người chơi
	money_label.text = "%d xu" % GameState.money
	copper_label.text = "Đồng: %d" % Inventory.ore_count("copper_ore")
	iron_label.text = "Sắt: %d" % Inventory.ore_count("iron_ore")
	gold_label.text = "Vàng: %d" % Inventory.ore_count("gold_ore")

	# 2. Cập nhật Thẻ Cuốc Đất
	var cur_hoe_tier := Inventory.get_hoe_tier()
	hoe_icon_rect.texture = TextureGen.hoe_icon(cur_hoe_tier)
	var hoe_info := OreDB.get_hoe(cur_hoe_tier)
	hoe_tier_label.text = "%s" % str(hoe_info.name)
	hoe_stamina_label.text = "⚡ Thể lực tiêu hao: %.0f⚡ / lần cuốc" % float(hoe_info.stamina)
	hoe_desc_label.text = str(hoe_info.desc)

	var cur_hoe_idx := 0
	for i in OreDB.HOES.size():
		if OreDB.HOES[i].tier == cur_hoe_tier:
			cur_hoe_idx = i
			break

	if cur_hoe_idx >= OreDB.HOES.size() - 1:
		# Đã đạt cấp tối đa
		hoe_next_title.text = "⭐ Đã đạt cấp tối đa (Cấp Vàng)!"
		hoe_next_stamina.text = "Tiết kiệm thể lực tối ưu nhất."
		hoe_cost_label.text = "Không thể nâng cấp thêm."
		hoe_upgrade_btn.text = "ĐÃ ĐẠT TỐI ĐA"
		hoe_upgrade_btn.disabled = true
	else:
		var next_h = OreDB.HOES[cur_hoe_idx + 1]
		var h_price: int = int(next_h.price)
		var h_ore_type: String = str(next_h.ore_type)
		var h_ore_cnt: int = int(next_h.ore_count)
		var o_info := OreDB.get_ore(h_ore_type)
		var o_name := str(o_info.get("name", h_ore_type))
		var o_have := Inventory.ore_count(h_ore_type)

		hoe_next_title.text = "Cấp kế tiếp: %s" % str(next_h.name)
		var save_stm := float(hoe_info.stamina) - float(next_h.stamina)
		hoe_next_stamina.text = "⚡ Tiêu hao mới: %.0f⚡ (Tiết kiệm -%.0f⚡)" % [float(next_h.stamina), save_stm]
		hoe_cost_label.text = "Chi phí: %d xu + %d %s (có %d)" % [h_price, h_ore_cnt, o_name, o_have]

		var can_afford_hoe := (GameState.money >= h_price and o_have >= h_ore_cnt)
		hoe_upgrade_btn.text = "NÂNG CẤP CUỐC (%d xu)" % h_price
		hoe_upgrade_btn.disabled = not can_afford_hoe

	# 3. Cập nhật Thẻ Cúp Khai Mỏ
	if not Inventory.has_pickaxe():
		pickaxe_icon_rect.texture = TextureGen.pickaxe_icon("basic")
		pickaxe_tier_label.text = "Chưa sở hữu Cúp"
		pickaxe_power_label.text = "🔨 Sức đập quặng: 0"
		pickaxe_stamina_label.text = "⚡ Thể lực tiêu hao: 5⚡"
		pickaxe_desc_label.text = "Hãy nói chuyện với Leah ở cửa mỏ để nhận Cúp sơ cấp miễn phí!"
		pickaxe_next_title.text = "Nhận Cúp sơ cấp trước"
		pickaxe_next_stats.text = "Gặp Leah tại cửa hầm mỏ Tây Bắc."
		pickaxe_cost_label.text = ""
		pickaxe_upgrade_btn.text = "CHƯA CÓ CÚP"
		pickaxe_upgrade_btn.disabled = true
	else:
		var cur_pick_tier := Inventory.get_pickaxe_tier()
		pickaxe_icon_rect.texture = TextureGen.pickaxe_icon(cur_pick_tier)
		var pick_info := OreDB.get_pickaxe(cur_pick_tier)
		pickaxe_tier_label.text = "%s" % str(pick_info.name)
		pickaxe_power_label.text = "🔨 Sức đập quặng: Cấp %d" % int(pick_info.power)
		pickaxe_stamina_label.text = "⚡ Thể lực tiêu hao: %.0f⚡ / lần đập" % float(pick_info.stamina)
		pickaxe_desc_label.text = str(pick_info.desc)

		var cur_pick_idx := 0
		for i in OreDB.PICKAXES.size():
			if OreDB.PICKAXES[i].tier == cur_pick_tier:
				cur_pick_idx = i
				break

		if cur_pick_idx >= OreDB.PICKAXES.size() - 1:
			# Đã đạt cấp tối đa
			pickaxe_next_title.text = "⭐ Đã đạt cấp tối đa (Cấp Vàng)!"
			pickaxe_next_stats.text = "Sức đập mạnh nhất và tiết kiệm thể lực tối ưu."
			pickaxe_cost_label.text = "Không thể nâng cấp thêm."
			pickaxe_upgrade_btn.text = "ĐÃ ĐẠT TỐI ĐA"
			pickaxe_upgrade_btn.disabled = true
		else:
			var next_p = OreDB.PICKAXES[cur_pick_idx + 1]
			var p_price: int = int(next_p.price)
			var p_ore_type: String = str(next_p.ore_type)
			var p_ore_cnt: int = int(next_p.ore_count)
			var po_info := OreDB.get_ore(p_ore_type)
			var po_name := str(po_info.get("name", p_ore_type))
			var po_have := Inventory.ore_count(p_ore_type)

			pickaxe_next_title.text = "Cấp kế tiếp: %s" % str(next_p.name)
			var save_p_stm := float(pick_info.stamina) - float(next_p.stamina)
			pickaxe_next_stats.text = "🔨 Sức đập: Cấp %d | ⚡ Tiêu hao mới: %.0f⚡ (-%.0f⚡)" % [int(next_p.power), float(next_p.stamina), save_p_stm]
			pickaxe_cost_label.text = "Chi phí: %d xu + %d %s (có %d)" % [p_price, p_ore_cnt, po_name, po_have]

			var can_afford_pick := (GameState.money >= p_price and po_have >= p_ore_cnt)
			pickaxe_upgrade_btn.text = "NÂNG CẤP CÚP (%d xu)" % p_price
			pickaxe_upgrade_btn.disabled = not can_afford_pick


func _on_upgrade_hoe_pressed() -> void:
	var res := Inventory.upgrade_hoe()
	if res.ok:
		feedback.emit(res.msg, Color(0.6, 1.0, 0.6))
		refresh()
	else:
		feedback.emit(res.msg, Color(1.0, 0.5, 0.4))


func _on_upgrade_pickaxe_pressed() -> void:
	var res := Inventory.upgrade_pickaxe()
	if res.ok:
		feedback.emit(res.msg, Color(0.6, 1.0, 0.6))
		refresh()
	else:
		feedback.emit(res.msg, Color(1.0, 0.5, 0.4))


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close()
		get_viewport().set_input_as_handled()
