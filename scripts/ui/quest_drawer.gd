extends PanelContainer
# Bảng rút gọn nhiệm vụ trên HUD (nằm dưới bảng thông tin, cạnh nút Mèo & Nhà kho).
# Có thể trượt mở / đóng nhanh bằng phím Q hoặc click chuột.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")

signal open_full_quests_requested
signal reward_claimed(quest_dict: Dictionary)

var quest_manager: Node = null

var _items_vbox: VBoxContainer = null


func _ready() -> void:
	add_theme_stylebox_override("panel", UIKit.wood_frame(10, 2, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	custom_minimum_size = Vector2(300, 0)
	mouse_filter = Control.MOUSE_FILTER_PASS
	visible = false

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)

	# 1. Tiêu đề bảng & Nút Đóng
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	vb.add_child(head)

	var icon_star := TextureRect.new()
	icon_star.texture = TextureGen.star_icon()
	icon_star.custom_minimum_size = Vector2(16, 16)
	icon_star.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	head.add_child(icon_star)

	var title := UIKit.label(head, "NHIỆM VỤ [Q]", 13, UIKit.COLOR_TEXT_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var close_btn := Button.new()
	close_btn.text = "✖"
	close_btn.custom_minimum_size = Vector2(24, 24)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.add_theme_font_size_override("font_size", 10)
	close_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.35, 0.15, 0.15), Color(0.65, 0.25, 0.25), 4, 1))
	close_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.50, 0.20, 0.20), Color(0.85, 0.35, 0.35), 4, 1))
	close_btn.pressed.connect(func():
		visible = false
	)
	head.add_child(close_btn)

	# 2. Vùng cuộn danh sách các thẻ nhiệm vụ
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(280, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)

	_items_vbox = VBoxContainer.new()
	_items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(_items_vbox)

	# 3. Nút mở toàn bộ sổ nhật ký nhiệm vụ (3 Tab)
	var full_btn := Button.new()
	full_btn.text = "📜 Mở Nhật Ký Chi Tiết (3 Tab)"
	full_btn.custom_minimum_size = Vector2(0, 28)
	full_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	full_btn.add_theme_font_size_override("font_size", 11)
	full_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.24, 0.16, 0.10), UIKit.COLOR_BORDER_WOOD, 6, 1))
	full_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.38, 0.25, 0.16), UIKit.COLOR_BORDER_GOLD, 6, 1))
	full_btn.pressed.connect(func():
		visible = false
		open_full_quests_requested.emit()
	)
	vb.add_child(full_btn)


func setup(qm: Node) -> void:
	quest_manager = qm
	if quest_manager != null:
		quest_manager.quest_progressed.connect(func(_id, _cur, _tgt): _refresh_ui())
		quest_manager.quest_completed.connect(func(_q): _refresh_ui())
		quest_manager.quest_claimed.connect(func(_q): _refresh_ui())
		quest_manager.quests_refreshed.connect(_refresh_ui)
	_refresh_ui()


func toggle_drawer() -> void:
	visible = !visible
	if visible:
		_refresh_ui()


func _refresh_ui() -> void:
	if quest_manager == null or _items_vbox == null:
		return

	for c in _items_vbox.get_children():
		c.queue_free()

	var active_quests: Array[Dictionary] = quest_manager.get_summary_quests()
	if active_quests.is_empty():
		var empty_lbl := UIKit.label(_items_vbox, "Đã hoàn thành hết nhiệm vụ!", 11, UIKit.COLOR_TEXT_MUTED)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		for q in active_quests:
			var card := _build_quest_row(q)
			_items_vbox.add_child(card)


func _build_quest_row(q: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.16, 0.11, 0.07, 0.95), UIKit.COLOR_BORDER_WOOD, 6))
	row.custom_minimum_size = Vector2(260, 0)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	row.add_child(vb)

	# Hàng 1: Tiêu đề & Tiến độ số
	var hb_top := HBoxContainer.new()
	vb.add_child(hb_top)

	var title_lbl := UIKit.label(hb_top, str(q.get("title", "")), 11, UIKit.COLOR_TEXT_TITLE)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var cur: int = int(q.get("progress", 0))
	var target: int = int(q.get("target_count", 1))
	var is_done: bool = bool(q.get("completed", false))
	var is_claimed: bool = bool(q.get("claimed", false))

	var prog_text := "%d/%d" % [cur, target]
	var prog_lbl := UIKit.label(hb_top, prog_text, 11, UIKit.COLOR_TEXT_GOLD if is_done else UIKit.COLOR_TEXT_MUTED)

	# Hàng 2: Thanh tiến độ trực quan
	var prog_bar := ProgressBar.new()
	prog_bar.custom_minimum_size = Vector2(0, 8)
	prog_bar.max_value = target
	prog_bar.value = cur
	prog_bar.show_percentage = false
	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = Color(0.08, 0.06, 0.04)
	bg_box.set_corner_radius_all(3)
	prog_bar.add_theme_stylebox_override("background", bg_box)
	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = Color(0.35, 0.85, 0.35) if is_done else Color(0.85, 0.65, 0.25)
	fill_box.set_corner_radius_all(3)
	prog_bar.add_theme_stylebox_override("fill", fill_box)
	vb.add_child(prog_bar)

	# Hàng 3: Nút nhận thưởng hoặc thông tin phần thưởng
	if is_done and not is_claimed:
		var claim_btn := Button.new()
		var coin_rew: int = int(q.get("reward_coins", 0))
		var item_rew_count: int = int(q.get("reward_item_count", 0))
		var item_rew_name: String = str(q.get("reward_item_name", ""))
		var btn_txt := "✨ Nhận: %d xu" % coin_rew
		if item_rew_count > 0 and item_rew_name != "":
			btn_txt += " + %d %s" % [item_rew_count, item_rew_name]
		claim_btn.text = btn_txt
		claim_btn.custom_minimum_size = Vector2(0, 24)
		claim_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		claim_btn.add_theme_font_size_override("font_size", 10)
		claim_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.20, 0.45, 0.20), Color(0.4, 0.9, 0.4), 4, 1))
		claim_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.28, 0.60, 0.28), Color(0.6, 1.0, 0.6), 4, 1))
		var q_id: String = str(q.get("id", ""))
		claim_btn.pressed.connect(func():
			var claimed_data = quest_manager.claim_reward(q_id)
			if not claimed_data.is_empty():
				reward_claimed.emit(claimed_data)
				_refresh_ui()
		)
		vb.add_child(claim_btn)
	elif not is_done:
		var rew_lbl := Label.new()
		var coin_rew: int = int(q.get("reward_coins", 0))
		var item_rew_count: int = int(q.get("reward_item_count", 0))
		var item_rew_name: String = str(q.get("reward_item_name", ""))
		var info_txt := "Thưởng: %d xu" % coin_rew
		if item_rew_count > 0 and item_rew_name != "":
			info_txt += " + %d %s" % [item_rew_count, item_rew_name]
		rew_lbl.text = info_txt
		rew_lbl.add_theme_font_size_override("font_size", 9)
		rew_lbl.add_theme_color_override("font_color", UIKit.COLOR_TEXT_MUTED)
		vb.add_child(rew_lbl)

	return row
