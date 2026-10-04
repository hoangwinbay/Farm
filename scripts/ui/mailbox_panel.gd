extends CanvasLayer
# Hòm Thư Trước Nhà: Quà tặng tài nguyên kiểm thử và vật phẩm làng quê.

const CropDB := preload("res://scripts/crop_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal changed

var data: Dictionary = {}

var player_coins_label: Label
var player_hoes_label: Label
var items_vbox: VBoxContainer
var claim_all_btn: Button
var empty_label: Label


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
	panel.custom_minimum_size = Vector2(580, 500)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	# --- Tiêu đề & Thông tin đầu trang ---
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	v.add_child(head)

	var title := UIKit.title_label(head, "📬 HÒM THƯ", 20, UIKit.COLOR_TEXT_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Huy hiệu tiền & cuốc hiện có
	var player_box := PanelContainer.new()
	player_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.08), UIKit.COLOR_BORDER_WOOD, 6))
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 10)
	player_box.add_child(ph)

	var mic := TextureRect.new()
	mic.texture = TextureGen.coin_icon()
	mic.custom_minimum_size = Vector2(16, 16)
	mic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ph.add_child(mic)
	player_coins_label = UIKit.label(ph, "%d xu" % GameState.money, 12, UIKit.COLOR_TEXT_GOLD)

	var hic := TextureRect.new()
	hic.texture = TextureGen.hoe_icon()
	hic.custom_minimum_size = Vector2(16, 16)
	hic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ph.add_child(hic)
	player_hoes_label = UIKit.label(ph, "×%d cuốc" % Inventory.hoes, 12, UIKit.COLOR_TEXT_BODY)

	head.add_child(player_box)

	var close_btn := UIKit.styled_button(head, "✕", 13, "danger")
	close_btn.custom_minimum_size = Vector2(34, 34)
	close_btn.pressed.connect(close)

	v.add_child(HSeparator.new())

	# --- Danh sách vật phẩm trong hòm (ScrollContainer) ---
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)

	items_vbox = VBoxContainer.new()
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(items_vbox)

	empty_label = UIKit.label(v, "(Hòm thư trống)", 13, UIKit.COLOR_TEXT_MUTED)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	v.add_child(HSeparator.new())

	# --- Nút Nhận tất cả & Đóng ---
	var bottom_h := HBoxContainer.new()
	bottom_h.add_theme_constant_override("separation", 10)
	v.add_child(bottom_h)

	claim_all_btn = UIKit.styled_button(bottom_h, "🎁 NHẬN TẤT CẢ VÀO TÚI", 14, "buy")
	claim_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim_all_btn.custom_minimum_size = Vector2(0, 40)
	claim_all_btn.pressed.connect(_claim_all)

	var close_btn_bot := UIKit.styled_button(bottom_h, "✕ Đóng (Esc/E)", 13, "default")
	close_btn_bot.custom_minimum_size = Vector2(120, 40)
	close_btn_bot.pressed.connect(close)


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		close()


func open(mb_data: Dictionary) -> void:
	data = mb_data
	visible = true
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func refresh() -> void:
	if player_hoes_label != null:
		player_hoes_label.text = "×%d cuốc" % Inventory.hoes
	if player_coins_label != null:
		player_coins_label.text = "%d xu" % GameState.money

	if items_vbox == null:
		return

	for c in items_vbox.get_children():
		c.queue_free()

	var total_items := 0

	# 1. Tiền vàng
	var coins := int(data.get("coins", 0))
	if coins > 0:
		total_items += 1
		_add_row(TextureGen.coin_icon(), "Tiền vàng", "+%d xu" % coins, UIKit.COLOR_TEXT_GOLD, func() -> void:
			GameState.add_money(coins)
			data["coins"] = 0
			changed.emit()
			refresh()
		)

	# 2. Cuốc cày đất
	var hoes := int(data.get("hoes", 0))
	if hoes > 0:
		total_items += 1
		_add_row(TextureGen.hoe_icon(), "Cuốc cày", "×%d" % hoes, UIKit.COLOR_TEXT_BODY, func() -> void:
			Inventory.add_hoes(hoes)
			data["hoes"] = 0
			changed.emit()
			refresh()
		)

	# 3. Nông sản & Gia cầm
	var prod = data.get("produce", {})
	if typeof(prod) == TYPE_DICTIONARY:
		for k in prod.keys():
			var n: int = int(prod[k])
			if n <= 0:
				continue
			total_items += 1
			var item_info := _get_item_info(str(k), "crop")
			_add_row(item_info.icon, str(item_info.name), "×%d" % n, UIKit.COLOR_TEXT_TITLE, func() -> void:
				if not Inventory.can_hold("produce", str(k)):
					return
				Inventory.add_produce(str(k), n)
				prod[k] = 0
				changed.emit()
				refresh()
			)

	# 4. Cá tươi
	var fish = data.get("fish", {})
	if typeof(fish) == TYPE_DICTIONARY:
		for k in fish.keys():
			var n: int = int(fish[k])
			if n <= 0:
				continue
			total_items += 1
			var item_info := _get_item_info(str(k), "fish")
			_add_row(item_info.icon, str(item_info.name), "×%d" % n, Color(0.6, 0.9, 1.0), func() -> void:
				if not Inventory.can_hold("fish", str(k)):
					return
				Inventory.fish[str(k)] = int(Inventory.fish.get(str(k), 0)) + n
				Inventory.changed.emit()
				fish[k] = 0
				changed.emit()
				refresh()
			)

	var has_items := total_items > 0
	if claim_all_btn != null:
		claim_all_btn.disabled = not has_items
	if empty_label != null:
		empty_label.visible = not has_items


func _add_row(icon: Texture2D, item_name: String, count_text: String, count_color: Color, on_claim: Callable) -> void:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UIKit.row_box())

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	row.add_child(h)

	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	slot.custom_minimum_size = Vector2(36, 36)
	var ic := TextureRect.new()
	ic.texture = icon
	ic.custom_minimum_size = Vector2(24, 24)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot.add_child(ic)
	h.add_child(slot)

	var lbl := UIKit.label(h, item_name, 13, UIKit.COLOR_TEXT_BODY)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	UIKit.label(pill, count_text, 12, count_color)
	h.add_child(pill)

	var btn := UIKit.styled_button(h, "Lấy", 11, "buy")
	btn.custom_minimum_size = Vector2(55, 28)
	btn.pressed.connect(on_claim)

	items_vbox.add_child(row)


func _claim_all() -> void:
	var c := int(data.get("coins", 0))
	if c > 0:
		GameState.add_money(c)
		data["coins"] = 0

	var h := int(data.get("hoes", 0))
	if h > 0:
		Inventory.add_hoes(h)
		data["hoes"] = 0

	var prod = data.get("produce", {})
	if typeof(prod) == TYPE_DICTIONARY:
		for k in prod.keys():
			var n := int(prod[k])
			if n > 0 and Inventory.can_hold("produce", str(k)):
				Inventory.add_produce(str(k), n)
				prod[k] = 0

	var fish = data.get("fish", {})
	if typeof(fish) == TYPE_DICTIONARY:
		for k in fish.keys():
			var n := int(fish[k])
			if n > 0 and Inventory.can_hold("fish", str(k)):
				Inventory.fish[str(k)] = int(Inventory.fish.get(str(k), 0)) + n
				fish[k] = 0
		Inventory.changed.emit()

	changed.emit()
	refresh()


func _take_hoes() -> void:
	var h: int = int(data.get("hoes", 0))
	if h > 0:
		Inventory.add_hoes(h)
		data["hoes"] = 0
		changed.emit()
		refresh()


func _take_coins() -> void:
	var c: int = int(data.get("coins", 0))
	if c > 0:
		GameState.add_money(c)
		data["coins"] = 0
		changed.emit()
		refresh()


func _deposit_hoes() -> void:
	if Inventory.hoes >= 10:
		Inventory.hoes -= 10
		Inventory.changed.emit()
		data["hoes"] = int(data.get("hoes", 0)) + 10
		changed.emit()
		refresh()


func _deposit_coins() -> void:
	if GameState.try_spend(50):
		data["coins"] = int(data.get("coins", 0)) + 50
		changed.emit()
		refresh()


func _get_item_info(id: String, type: String) -> Dictionary:
	if type == "fish":
		var f := FishDB.get_fish(id)
		if not f.is_empty():
			return {"name": str(f.name), "icon": TextureGen.fish_icon(str(f.color))}
		return {"name": id, "icon": TextureGen.star_icon()}
	else:
		# Nông sản trồng trọt
		var c := CropDB.get_crop(id)
		if not c.is_empty():
			return {"name": str(c.name), "icon": TextureGen.prod_icon(c)}
		# Sản phẩm gia cầm
		for a in PoultryDB.ANIMALS:
			if str(a.product) == id:
				return {"name": str(a.product_name), "icon": TextureGen.egg_icon(str(a.product_color))}
		return {"name": id, "icon": TextureGen.star_icon()}
