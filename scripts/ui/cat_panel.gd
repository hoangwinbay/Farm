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
	UIKit.label(task_v, "🏚️ Cất toàn bộ hoa màu và sâu bọ vào Nhà Kho", 12, Color(0.85, 0.85, 0.80))
	UIKit.label(task_v, "⛺ Đến tối (19:00) Mèo sẽ vào lều riêng để ngủ", 12, Color(0.85, 0.85, 0.80))
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

	# 2 Cột: Túi hạt của mèo (Trái) & Balo hạt giống của người chơi (Phải)
	var lists_h := HBoxContainer.new()
	lists_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lists_h.add_theme_constant_override("separation", 12)
	_manage_view.add_child(lists_h)

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
	_seeds_in_cat_box = VBoxContainer.new()
	_seeds_in_cat_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(_seeds_in_cat_box)
	left_v.add_child(left_scroll)
	lists_h.add_child(left_box)

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
	_seeds_in_bag_box = VBoxContainer.new()
	_seeds_in_bag_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(_seeds_in_bag_box)
	right_v.add_child(right_scroll)
	lists_h.add_child(right_box)


func _refresh_manage_data() -> void:
	if cat == null:
		return

	# Cập nhật trạng thái chữ
	var state_str := "Đang nghỉ ngơi"
	match cat.state:
		CatHelperScript.State.ARRIVING, CatHelperScript.State.WAITING_HIRE:
			state_str = "Đang đứng chờ cửa nhà"
		CatHelperScript.State.WALKING_TO_JOB, CatHelperScript.State.WORKING:
			var jtype: String = str(cat.current_job.get("type", ""))
			match jtype:
				"pest": state_str = "Đang đi bắt sâu bọ 🐛"
				"harvest": state_str = "Đang đi thu hoạch hoa màu 🌾"
				"water": state_str = "Đang tưới nước cho luống cây 💧"
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
