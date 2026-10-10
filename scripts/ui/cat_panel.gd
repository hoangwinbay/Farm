extends CanvasLayer
# Giao diện Phỏng vấn & Quản lý Chú Mèo Tam Thể làm nông:
# - Trước khi thuê: xem thông tin dịch vụ, tiền công 50 xu/ngày, bấm thuê.
# - Sau khi thuê: xem trạng thái, bình nước, giao nhận hạt giống để mèo tự động gieo.

const TextureGen := preload("res://scripts/texture_gen.gd")
const CropDB := preload("res://scripts/crop_db.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const CatHelperScript := preload("res://scripts/cat_helper.gd")

signal closed
signal feedback(text: String, color: Color)

var cat: Node2D = null

var _container: VBoxContainer
var _hire_view: VBoxContainer
var _manage_view: VBoxContainer

# Quản lý views
var _status_label: Label
var _water_label: Label
var _seeds_in_cat_box: VBoxContainer
var _seeds_in_bag_box: VBoxContainer

var _active_tab: int = 0
var _tab_seeds_btn: Button
var _tab_upgrades_btn: Button
var _tab_seeds_container: VBoxContainer
var _tab_upgrades_container: VBoxContainer
var _upgrade_cards_box: VBoxContainer
var _wallet_label: Label

var _hoe_info_label: Label
var _give_hoe_1_btn: Button
var _give_hoe_all_btn: Button
var _take_hoe_btn: Button
var _take_hoe_all_btn: Button


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
	panel.custom_minimum_size = Vector2(760, 520)
	center.add_child(panel)

	_container = VBoxContainer.new()
	_container.add_theme_constant_override("separation", 10)
	panel.add_child(_container)

	_build_hire_view()
	_build_manage_view()


func open(cat_node: Node2D) -> void:
	cat = cat_node
	visible = true
	_refresh_view()


func close() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		close()
		get_viewport().set_input_as_handled()


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		close()


func _refresh_view() -> void:
	if cat == null or not is_instance_valid(cat):
		close()
		return

	if not cat.is_hired:
		_hire_view.visible = true
		_manage_view.visible = false
	else:
		_hire_view.visible = false
		_manage_view.visible = true
		_refresh_manage_data()


# ---------- GIAO DIỆN PHỎNG VẤN & THUÊ MÈO ----------

func _build_hire_view() -> void:
	_hire_view = VBoxContainer.new()
	_hire_view.add_theme_constant_override("separation", 14)
	_container.add_child(_hire_view)

	# Tiêu đề
	var head := HBoxContainer.new()
	_hire_view.add_child(head)
	var title_lbl := UIKit.title_label(head, "🐱 MÈO TAM THỂ LÀM NÔNG", 20, UIKit.COLOR_TEXT_TITLE)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_btn := UIKit.styled_button(head, "✕ Đóng (Esc)", 13, "danger")
	close_btn.pressed.connect(close)

	# Nội dung giới thiệu
	var body_h := HBoxContainer.new()
	body_h.add_theme_constant_override("separation", 20)
	_hire_view.add_child(body_h)

	# Khung hình chân dung chú mèo
	var portrait_box := PanelContainer.new()
	portrait_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.15, 0.10), UIKit.COLOR_BORDER_GOLD, 8))
	portrait_box.custom_minimum_size = Vector2(170, 240)
	body_h.add_child(portrait_box)

	var p_v := VBoxContainer.new()
	p_v.alignment = BoxContainer.ALIGNMENT_CENTER
	p_v.add_theme_constant_override("separation", 8)
	portrait_box.add_child(p_v)

	var cat_tex_rect := TextureRect.new()
	cat_tex_rect.texture = TextureGen.cat_char_tex("down", 0)
	cat_tex_rect.custom_minimum_size = Vector2(84, 96)
	cat_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	p_v.add_child(cat_tex_rect)

	var name_badge := UIKit.label(p_v, "Mèo Thợ Nông", 14, UIKit.COLOR_TEXT_GOLD)
	name_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Cột mô tả công việc
	var desc_v := VBoxContainer.new()
	desc_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_v.add_theme_constant_override("separation", 8)
	body_h.add_child(desc_v)

	var intro := UIKit.label(desc_v, "Meo meo! Tôi là Mèo Tam Thể làm nông chăm chỉ.\nBạn có muốn thuê tôi phụ giúp công việc đồng áng không?", 14, Color(0.95, 0.90, 0.80))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var task_box := PanelContainer.new()
	task_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.18, 0.13, 0.08, 0.8), UIKit.COLOR_BORDER_WOOD, 6))
	var task_v := VBoxContainer.new()
	task_v.add_theme_constant_override("separation", 4)
	task_box.add_child(task_v)

	UIKit.label(task_v, "Nhiệm vụ chú mèo sẽ đảm nhiệm:", 13, UIKit.COLOR_TEXT_GOLD)
	UIKit.label(task_v, "🌾 Thu hoạch hoa màu ngay khi chín", 12, Color(0.85, 0.85, 0.80))
	UIKit.label(task_v, "🐛 Bắt sạch sâu bọ cắn phá cây trồng", 12, Color(0.85, 0.85, 0.80))
	UIKit.label(task_v, "💧 Tưới nước cho cây (hết nước tự ra ao múc)", 12, Color(0.85, 0.85, 0.80))
	UIKit.label(task_v, "🌱 Gieo hạt giống (khi bạn giao hạt vào túi Mèo)", 12, Color(0.85, 0.85, 0.80))
	UIKit.label(task_v, "⛏️ Cuốc xới đất đen sau thu hoạch (khi bạn giao cuốc)", 12, Color(0.85, 0.85, 0.80))
	UIKit.label(task_v, "🏚️ Cất toàn bộ hoa màu và sâu bọ vào Nhà Kho", 12, Color(0.85, 0.85, 0.80))
	UIKit.label(task_v, "⛺ Đến tối Mèo sẽ vào lều riêng để ngủ", 12, Color(0.85, 0.85, 0.80))
	UIKit.label(task_v, "⭐ Dùng tiền nâng cấp Tốc độ, Năng suất & Túi đồ cho Mèo", 12, Color(1.0, 0.9, 0.5))
	desc_v.add_child(task_box)

	var wage_info := UIKit.label(desc_v, "💰 Tiền công: 50 xu / ngày (trả tự động vào cuối ngày lúc 19:00 hoặc khi bạn đi ngủ).", 13, Color(1.0, 0.85, 0.4))
	wage_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Nút hành động
	var btn_h := HBoxContainer.new()
	btn_h.alignment = BoxContainer.ALIGNMENT_END
	btn_h.add_theme_constant_override("separation", 12)
	_hire_view.add_child(btn_h)

	var hire_btn := UIKit.styled_button(btn_h, "🤝 Đồng ý thuê (50 xu/ngày)", 14, "gold")
	hire_btn.pressed.connect(_on_hire_pressed)

	var cancel_btn := UIKit.styled_button(btn_h, "Để sau", 14, "neutral")
	cancel_btn.pressed.connect(close)


func _on_hire_pressed() -> void:
	if cat == null:
		return
	cat.hire()
	feedback.emit("Đã thuê Mèo Tam Thể làm nông thành công! 🐱🌾", Color(0.65, 1.0, 0.6))
	_refresh_view()


# ---------- GIAO DIỆN QUẢN LÝ MÈO ĐANG LÀM VIỆC ----------

func _build_manage_view() -> void:
	_manage_view = VBoxContainer.new()
	_manage_view.add_theme_constant_override("separation", 10)
	_container.add_child(_manage_view)

	# Tiêu đề & thanh trạng thái
	var head := HBoxContainer.new()
	_manage_view.add_child(head)
	var title_lbl := UIKit.title_label(head, "🐱 QUẢN LÝ MÈO LÀM NÔNG", 20, UIKit.COLOR_TEXT_TITLE)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var dismiss_btn := UIKit.styled_button(head, "Cho mèo nghỉ việc", 12, "danger")
	dismiss_btn.pressed.connect(func():
		if cat != null:
			cat.dismiss()
			_refresh_view()
	)

	var close_btn := UIKit.styled_button(head, "✕ Đóng (Esc/E)", 13, "gold")
	close_btn.pressed.connect(close)

	# Bảng trạng thái hoạt động của mèo
	var status_card := PanelContainer.new()
	status_card.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.15, 0.10), UIKit.COLOR_BORDER_GOLD, 6))
	var st_h := HBoxContainer.new()
	st_h.add_theme_constant_override("separation", 16)
	status_card.add_child(st_h)

	var avatar := TextureRect.new()
	avatar.texture = TextureGen.cat_char_tex("down", 0)
	avatar.custom_minimum_size = Vector2(32, 32)
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	st_h.add_child(avatar)

	var st_v := VBoxContainer.new()
	st_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label = UIKit.label(st_v, "Trạng thái: Đang nghỉ ngơi", 13, Color(0.9, 0.9, 0.8))
	_water_label = UIKit.label(st_v, "Bình nước: 15/15 💧 | Tiền công: 50 xu/ngày", 12, UIKit.COLOR_TEXT_GOLD)
	st_h.add_child(st_v)

	_manage_view.add_child(status_card)

	# Thanh chuyển Tab: [🌾 Hạt giống & Cuốc đất] [⭐ Nâng cấp Mèo]
	var tab_bar := HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 8)
	_manage_view.add_child(tab_bar)

	_tab_seeds_btn = UIKit.styled_button(tab_bar, "🌾 Hạt giống & Cuốc đất", 13, "gold")
	_tab_seeds_btn.pressed.connect(func(): _switch_tab(0))

	_tab_upgrades_btn = UIKit.styled_button(tab_bar, "⭐ Nâng cấp Mèo (Tốc độ / Giờ làm / Túi)", 13, "neutral")
	_tab_upgrades_btn.pressed.connect(func(): _switch_tab(1))

	# TAB 1: Giao nhận hạt giống & cuốc đất
	_tab_seeds_container = VBoxContainer.new()
	_tab_seeds_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_seeds_container.add_theme_constant_override("separation", 8)
	_manage_view.add_child(_tab_seeds_container)

	# Khung giao nhận Cuốc cày đất cho Mèo
	var hoe_card := PanelContainer.new()
	hoe_card.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.15, 0.10), UIKit.COLOR_BORDER_GOLD, 6))
	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 8)
	hoe_card.add_child(hh)

	var hic := TextureRect.new()
	hic.texture = TextureGen.hoe_icon()
	hic.custom_minimum_size = Vector2(24, 24)
	hic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	hh.add_child(hic)

	_hoe_info_label = UIKit.label(hh, "⛏️ Cuốc làm đất: Mèo đang giữ ×0 · Balo của bạn: ×0", 12, UIKit.COLOR_TEXT_GOLD)
	_hoe_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_give_hoe_1_btn = UIKit.styled_button(hh, "Giao 1", 11, "gold")
	_give_hoe_1_btn.pressed.connect(func():
		if cat != null and cat.give_hoes(1):
			_refresh_manage_data()
	)

	_give_hoe_all_btn = UIKit.styled_button(hh, "Giao hết", 11, "green")
	_give_hoe_all_btn.pressed.connect(func():
		if cat != null and cat.give_hoes(Inventory.hoes):
			_refresh_manage_data()
	)

	_take_hoe_btn = UIKit.styled_button(hh, "Lấy lại 1", 11, "neutral")
	_take_hoe_btn.pressed.connect(func():
		if cat != null and cat.take_back_hoes(1):
			_refresh_manage_data()
	)

	_take_hoe_all_btn = UIKit.styled_button(hh, "Lấy hết", 11, "neutral")
	_take_hoe_all_btn.pressed.connect(func():
		if cat != null and cat.take_back_hoes(-1):
			_refresh_manage_data()
	)

	_tab_seeds_container.add_child(hoe_card)

	var seeds_hbox := HBoxContainer.new()
	seeds_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	seeds_hbox.add_theme_constant_override("separation", 12)
	_tab_seeds_container.add_child(seeds_hbox)

	# Cột trái: Hạt giống Mèo đang giữ
	var left_box := PanelContainer.new()
	left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.16, 0.11, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	var left_v := VBoxContainer.new()
	left_box.add_child(left_v)
	UIKit.title_label(left_v, "🌱 Túi hạt giống Mèo đang giữ (để gieo):", 13, UIKit.COLOR_TEXT_GOLD)
	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_scroll.custom_minimum_size = Vector2(0, 180)
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(left_scroll)
	_seeds_in_cat_box = VBoxContainer.new()
	_seeds_in_cat_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(_seeds_in_cat_box)
	left_v.add_child(left_scroll)
	seeds_hbox.add_child(left_box)

	# Cột phải: Hạt giống trong balo người chơi để giao
	var right_box := PanelContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.16, 0.11, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	var right_v := VBoxContainer.new()
	right_box.add_child(right_v)
	UIKit.title_label(right_v, "🎒 Giao hạt giống từ balo của bạn:", 13, Color(0.65, 0.95, 0.65))
	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.custom_minimum_size = Vector2(0, 180)
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(right_scroll)
	_seeds_in_bag_box = VBoxContainer.new()
	_seeds_in_bag_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(_seeds_in_bag_box)
	right_v.add_child(right_scroll)
	seeds_hbox.add_child(right_box)

	# TAB 2: Nâng cấp Mèo
	_tab_upgrades_container = VBoxContainer.new()
	_tab_upgrades_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_upgrades_container.add_theme_constant_override("separation", 8)
	_tab_upgrades_container.visible = false
	_manage_view.add_child(_tab_upgrades_container)

	var wallet_bar := PanelContainer.new()
	wallet_bar.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.17, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	_tab_upgrades_container.add_child(wallet_bar)
	var wh := HBoxContainer.new()
	wh.add_theme_constant_override("separation", 6)
	wallet_bar.add_child(wh)
	var wic := TextureRect.new()
	wic.texture = TextureGen.coin_icon()
	wic.custom_minimum_size = Vector2(16, 16)
	wic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	wh.add_child(wic)
	_wallet_label = UIKit.label(wh, "Tiền hiện có trong túi của bạn: 0 xu", 13, UIKit.COLOR_TEXT_GOLD)

	_upgrade_cards_box = VBoxContainer.new()
	_upgrade_cards_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_upgrade_cards_box.add_theme_constant_override("separation", 8)
	_tab_upgrades_container.add_child(_upgrade_cards_box)


func _switch_tab(idx: int) -> void:
	_active_tab = idx
	if _tab_seeds_container != null and _tab_upgrades_container != null:
		_tab_seeds_container.visible = (_active_tab == 0)
		_tab_upgrades_container.visible = (_active_tab == 1)
	if _tab_seeds_btn != null and _tab_upgrades_btn != null:
		if _active_tab == 0:
			_tab_seeds_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.38, 0.26, 0.12), UIKit.COLOR_BORDER_GOLD, 6, 2))
			_tab_upgrades_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.24, 0.18, 0.12), UIKit.COLOR_BORDER_WOOD, 6, 1))
		else:
			_tab_seeds_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.24, 0.18, 0.12), UIKit.COLOR_BORDER_WOOD, 6, 1))
			_tab_upgrades_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.38, 0.26, 0.12), UIKit.COLOR_BORDER_GOLD, 6, 2))
	_refresh_manage_data()


func _refresh_manage_data() -> void:
	if cat == null:
		return

	# Cập nhật trạng thái chữ
	var state_str := "Đang nghỉ ngơi"
	match cat.state:
		CatHelperScript.State.ARRIVING, CatHelperScript.State.WAITING_HIRE:
			state_str = "Đang đứng chờ ở sân"
		CatHelperScript.State.WALKING_TO_JOB, CatHelperScript.State.WORKING:
			var jtype: String = str(cat.current_job.get("type", ""))
			match jtype:
				"pest": state_str = "Đang đi bắt sâu bọ 🐛"
				"harvest": state_str = "Đang đi thu hoạch hoa màu 🌾"
				"water": state_str = "Đang tưới nước cho luống cây 💧"
				"till": state_str = "Đang đi cuốc xới đất ⛏️"
				"plant": state_str = "Đang gieo hạt giống vào đất 🌱"
				_: state_str = "Đang làm việc đồng áng"
		CatHelperScript.State.WALKING_TO_POND, CatHelperScript.State.REFILLING:
			state_str = "Đang ra bờ ao múc đầy bình nước 💧"
		CatHelperScript.State.WALKING_TO_SHED, CatHelperScript.State.DEPOSITING:
			state_str = "Đang đem nông sản cất vào Nhà Kho 🏚️"
		CatHelperScript.State.WALKING_TO_TENT, CatHelperScript.State.SLEEPING:
			state_str = "Đang ngủ trong lều Stardew Valley ⛺"

	_status_label.text = "Trạng thái: %s" % state_str
	_water_label.text = "Bình nước: %d/%d 💧 | Đã trả lương hôm nay: %s" % [
		cat.water_level, cat.water_capacity, "Đã trả 💰" if cat.wage_paid_today else "Chờ lúc 19:00"
	]

	# Cập nhật thông tin Cuốc cày
	if _hoe_info_label != null:
		var cat_h: int = int(cat.assigned_hoes)
		var bag_h: int = int(Inventory.hoes)
		_hoe_info_label.text = "⛏️ Cuốc làm đất: Mèo đang giữ ×%d cuốc · Balo của bạn: ×%d cuốc" % [cat_h, bag_h]
		if _give_hoe_1_btn != null:
			_give_hoe_1_btn.disabled = (bag_h <= 0)
		if _give_hoe_all_btn != null:
			_give_hoe_all_btn.disabled = (bag_h <= 0)
		if _take_hoe_btn != null:
			_take_hoe_btn.disabled = (cat_h <= 0)
		if _take_hoe_all_btn != null:
			_take_hoe_all_btn.disabled = (cat_h <= 0)

	# Cập nhật danh sách hạt giống Mèo đang giữ
	for child in _seeds_in_cat_box.get_children():
		child.queue_free()

	if cat.assigned_seeds.is_empty():
		var empty_lbl := UIKit.label(_seeds_in_cat_box, "(Chưa có hạt giống nào. Hãy giao hạt bên phải để Mèo tự gieo)", 12, Color(0.6, 0.55, 0.5))
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		for sid in cat.assigned_seeds:
			var count: int = int(cat.assigned_seeds[sid])
			if count <= 0:
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var ic := TextureRect.new()
			ic.texture = TextureGen.seed_bag_tex(sid)
			ic.custom_minimum_size = Vector2(20, 20)
			ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			row.add_child(ic)

			var cdata := CropDB.get_crop(sid)
			var cname := str(cdata.get("name", sid))
			var lbl := UIKit.label(row, "%s: ×%d" % [cname, count], 12, Color(0.9, 0.9, 0.8))
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var take_btn := UIKit.styled_button(row, "Lấy lại", 11, "neutral")
			take_btn.pressed.connect(func():
				cat.take_back_seeds(sid, 5)
				_refresh_manage_data()
			)
			_seeds_in_cat_box.add_child(row)

	# Cập nhật danh sách hạt giống trong balo người chơi
	for child in _seeds_in_bag_box.get_children():
		child.queue_free()

	var owned_seeds := Inventory.seeds
	var has_any := false
	for sid in owned_seeds:
		var count: int = int(owned_seeds[sid])
		if count <= 0:
			continue
		has_any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var ic := TextureRect.new()
		ic.texture = TextureGen.seed_bag_tex(sid)
		ic.custom_minimum_size = Vector2(20, 20)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(ic)

		var cdata := CropDB.get_crop(sid)
		var cname := str(cdata.get("name", sid))
		var lbl := UIKit.label(row, "%s: ×%d" % [cname, count], 12, Color(0.9, 0.9, 0.8))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var give5_btn := UIKit.styled_button(row, "Giao 5", 11, "gold")
		give5_btn.pressed.connect(func():
			cat.give_seeds(sid, mini(5, count))
			_refresh_manage_data()
		)

		var give_all_btn := UIKit.styled_button(row, "Giao hết", 11, "green")
		give_all_btn.pressed.connect(func():
			cat.give_seeds(sid, count)
			_refresh_manage_data()
		)

		_seeds_in_bag_box.add_child(row)

	if not has_any:
		var empty_lbl := UIKit.label(_seeds_in_bag_box, "(Balo của bạn không có hạt giống nào để giao)", 12, Color(0.6, 0.55, 0.5))
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Cập nhật giao diện Nâng cấp
	if _wallet_label != null:
		_wallet_label.text = "Tiền hiện có trong túi của bạn: %d xu" % GameState.money

	if _upgrade_cards_box != null:
		for c in _upgrade_cards_box.get_children():
			c.queue_free()

		# 1. Thẻ Tốc độ di chuyển
		var next_spd_str: String = "%.0f px/s" % float(cat.get_speed_for_level(cat.speed_level + 1))
		_build_upgrade_card(_upgrade_cards_box, "speed", "⚡ Tốc độ di chuyển",
			"Vận tốc mèo đi lại trên nông trại",
			cat.speed_level, "%.0f px/s" % float(cat.speed),
			next_spd_str
		)

		# 2. Thẻ Năng suất & Giờ làm việc
		var sleep_hr: int = int(float(cat.get_sleep_clock()) / 60.0)
		var next_sleep_hr: int = int(float(cat.get_sleep_clock_for_level(cat.work_level + 1)) / 60.0)
		_build_upgrade_card(_upgrade_cards_box, "work", "⏱️ Năng suất & Giờ làm việc",
			"Thao tác nhanh %.2fs/việc · Tan ca lúc %02d:00 tối" % [float(cat.get_work_duration()), sleep_hr],
			cat.work_level, "Thao tác %.2fs · Đến %02d:00" % [float(cat.get_work_duration()), sleep_hr],
			"Làm việc chăm chỉ đến %02d:00 đêm" % next_sleep_hr
		)

		# 3. Thẻ Sức chứa Túi đồ & Bình nước
		var next_bag: int = int(cat.get_max_bag_for_level(cat.bag_level + 1))
		var next_water: int = int(cat.get_water_capacity_for_level(cat.bag_level + 1))
		_build_upgrade_card(_upgrade_cards_box, "bag", "🎒 Sức chứa Túi đồ & Bình nước",
			"Túi gom nông sản: %d món · Bình nước: %d giọt" % [int(cat.get_max_bag()), int(cat.water_capacity)],
			cat.bag_level, "Túi %d món · Bình %d giọt" % [int(cat.get_max_bag()), int(cat.water_capacity)],
			"Túi %d món · Bình nước %d giọt" % [next_bag, next_water]
		)


func _build_upgrade_card(parent: Control, type: String, title: String, desc: String, cur_lvl: int, cur_stat: String, next_stat: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.18, 0.13, 0.08), UIKit.COLOR_BORDER_WOOD, 6))
	parent.add_child(card)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)

	var title_txt := "%s  (Cấp %d/%d)" % [title, cur_lvl, CatHelperScript.MAX_UPGRADE_LEVEL]
	UIKit.label(v, title_txt, 13, UIKit.COLOR_TEXT_GOLD)
	UIKit.label(v, "%s  [Hiện tại: %s]" % [desc, cur_stat], 11, Color(0.85, 0.85, 0.80))
	if cur_lvl < CatHelperScript.MAX_UPGRADE_LEVEL:
		UIKit.label(v, "➜ Cấp kế tiếp: %s" % next_stat, 11, Color(0.55, 0.95, 0.55))
	else:
		UIKit.label(v, "⭐ Đã đạt mức tối đa! Mèo đã thuần thục kỹ năng này.", 11, Color(1.0, 0.85, 0.35))

	var is_max: bool = (cur_lvl >= CatHelperScript.MAX_UPGRADE_LEVEL)
	var cost: int = cat.get_upgrade_cost(type, cur_lvl)

	if is_max:
		var max_btn := UIKit.styled_button(h, "⭐ Tối đa", 12, "neutral")
		max_btn.disabled = true
	else:
		var can_afford: bool = (GameState.money >= cost)
		var btn_style_type := "gold" if can_afford else "neutral"
		var up_btn := UIKit.styled_button(h, "Nâng cấp (%d xu)" % cost, 12, btn_style_type)
		up_btn.pressed.connect(func():
			if GameState.money < cost:
				feedback.emit("Không đủ tiền! Bạn cần %d xu để nâng cấp kỹ năng này." % cost, Color(1.0, 0.5, 0.4))
				return
			if cat.upgrade(type):
				_refresh_manage_data()
		)

