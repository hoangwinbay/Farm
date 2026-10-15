extends CanvasLayer
# Bảng Nhật Ký Nhiệm Vụ 3 Tab (Nhiệm vụ Ngày, Nhiệm vụ Tuần, Nhiệm vụ Tổng).
# Hiển thị toàn bộ mục tiêu, mô tả, thanh tiến độ và nút nhận thưởng phong cách gỗ mộc.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")

signal closed
signal feedback(text: String, color: Color)
signal reward_claimed(quest_dict: Dictionary)

var quest_manager: Node = null

var _panel: PanelContainer
var _tabs_row: HBoxContainer
var _tab_daily_btn: Button
var _tab_weekly_btn: Button
var _tab_lifetime_btn: Button
var _active_tab: String = "daily" # "daily", "weekly", "lifetime"
var _cards_container: VBoxContainer
var _sub_header_lbl: Label


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	# Khung bao phủ toàn màn hình
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Nền mờ phía sau
	var bg_overlay := ColorRect.new()
	bg_overlay.color = Color(0.08, 0.05, 0.03, 0.65)
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			close()
	)
	root.add_child(bg_overlay)

	# Căn giữa hoàn hảo
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	# Khung gỗ chính
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 3, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	_panel.custom_minimum_size = Vector2(800, 520)
	center.add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_panel.add_child(vb)

	# 1. Tiêu đề bảng & Nút Đóng
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	vb.add_child(head)

	var icon_star := TextureRect.new()
	icon_star.texture = TextureGen.star_icon()
	icon_star.custom_minimum_size = Vector2(20, 20)
	icon_star.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	head.add_child(icon_star)

	var title := UIKit.label(head, "BẢNG NHIỆM VỤ LÀNG QUÊ", 18, UIKit.COLOR_TEXT_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var close_btn := Button.new()
	close_btn.text = "✖"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.35, 0.15, 0.15), Color(0.65, 0.25, 0.25), 6, 1))
	close_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.50, 0.20, 0.20), Color(0.85, 0.35, 0.35), 6, 1))
	close_btn.pressed.connect(close)
	head.add_child(close_btn)

	# 2. Hàng 3 Tab chọn nhóm nhiệm vụ
	_tabs_row = HBoxContainer.new()
	_tabs_row.add_theme_constant_override("separation", 8)
	vb.add_child(_tabs_row)

	_tab_daily_btn = _create_tab_btn("☀️ Nhiệm Vụ Ngày", "daily")
	_tab_weekly_btn = _create_tab_btn("📅 Nhiệm Vụ Tuần", "weekly")
	_tab_lifetime_btn = _create_tab_btn("🏆 Nhiệm Vụ Tổng (Thành Tựu)", "lifetime")

	_tabs_row.add_child(_tab_daily_btn)
	_tabs_row.add_child(_tab_weekly_btn)
	_tabs_row.add_child(_tab_lifetime_btn)

	# 3. Phụ đề tóm tắt thời gian / trạng thái tab
	_sub_header_lbl = UIKit.label(vb, "", 12, UIKit.COLOR_TEXT_MUTED)

	# 4. Vùng cuộn danh sách các thẻ nhiệm vụ
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 310)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIKit.style_scroll_container(scroll)
	vb.add_child(scroll)

	_cards_container = VBoxContainer.new()
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_cards_container)


func setup(qm: Node) -> void:
	quest_manager = qm
	if quest_manager != null:
		quest_manager.quest_progressed.connect(func(_id, _cur, _tgt): if visible: _refresh_tab_content())
		quest_manager.quest_completed.connect(func(_q): if visible: _refresh_tab_content())
		quest_manager.quest_claimed.connect(func(_q): if visible: _refresh_tab_content())
		quest_manager.quests_refreshed.connect(func(): if visible: _refresh_tab_content())


func _create_tab_btn(label_text: String, tab_id: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(175, 34)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func():
		_active_tab = tab_id
		_update_tab_buttons_style()
		_refresh_tab_content()
	)
	return btn


func _update_tab_buttons_style() -> void:
	var style_active := UIKit.btn_style(Color(0.40, 0.28, 0.16), UIKit.COLOR_BORDER_GOLD, 6, 2)
	var style_inactive := UIKit.btn_style(Color(0.20, 0.14, 0.08), UIKit.COLOR_BORDER_WOOD, 6, 1)

	_tab_daily_btn.add_theme_stylebox_override("normal", style_active if _active_tab == "daily" else style_inactive)
	_tab_weekly_btn.add_theme_stylebox_override("normal", style_active if _active_tab == "weekly" else style_inactive)
	_tab_lifetime_btn.add_theme_stylebox_override("normal", style_active if _active_tab == "lifetime" else style_inactive)


func open(default_tab: String = "daily") -> void:
	_active_tab = default_tab
	_update_tab_buttons_style()
	_refresh_tab_content()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


var _timer_tick: float = 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	_timer_tick += delta
	if _timer_tick >= 1.0:
		_timer_tick = 0.0
		_update_sub_header()


func _update_sub_header() -> void:
	if quest_manager == null or _sub_header_lbl == null:
		return
	match _active_tab:
		"daily":
			var cd: String = quest_manager.format_countdown_daily()
			_sub_header_lbl.text = "⏱️ Làm mới sau: %s (Đúng 00:00 hàng ngày) • Thưởng: 100 vàng + 10 nguyên liệu cùng loại" % cd
		"weekly":
			var cd: String = quest_manager.format_countdown_weekly()
			_sub_header_lbl.text = "⏱️ Làm mới sau: %s (Đúng 00:00 thứ Hai) • Thưởng: 500 vàng + 50 nguyên liệu cùng loại" % cd
		"lifetime":
			var quest_list: Array[Dictionary] = quest_manager.lifetime_quests
			var completed_cnt := 0
			for q in quest_list:
				if bool(q.get("completed", false)):
					completed_cnt += 1
			_sub_header_lbl.text = "🏆 Mốc thành tựu nông trại trọn đời (%d/%d đã hoàn thành) • Thưởng: 50 vàng mỗi mốc" % [completed_cnt, quest_list.size()]


func _refresh_tab_content() -> void:
	if quest_manager == null or _cards_container == null:
		return

	for c in _cards_container.get_children():
		c.queue_free()

	_update_sub_header()

	var quest_list: Array[Dictionary] = []
	match _active_tab:
		"daily":
			quest_list = quest_manager.daily_quests
		"weekly":
			quest_list = quest_manager.weekly_quests
		"lifetime":
			quest_list = quest_manager.lifetime_quests

	if quest_list.is_empty():
		var empty_card := PanelContainer.new()
		empty_card.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.16, 0.11, 0.07, 0.95), UIKit.COLOR_BORDER_WOOD, 6))
		UIKit.label(empty_card, "Không có nhiệm vụ nào trong mục này.", 13, UIKit.COLOR_TEXT_MUTED)
		_cards_container.add_child(empty_card)
		return

	for q in quest_list:
		var card := _build_quest_card(q)
		_cards_container.add_child(card)


func _build_quest_card(q: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.18, 0.12, 0.08, 0.95), UIKit.COLOR_BORDER_GOLD if bool(q.get("completed", false)) else UIKit.COLOR_BORDER_WOOD, 8))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	# Hàng 1: Tiêu đề + Trạng thái
	var hb_title := HBoxContainer.new()
	vb.add_child(hb_title)

	var title_lbl := UIKit.label(hb_title, str(q.get("title", "")), 14, UIKit.COLOR_TEXT_TITLE)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var cur: int = int(q.get("progress", 0))
	var target: int = int(q.get("target_count", 1))
	var is_done: bool = bool(q.get("completed", false))
	var is_claimed: bool = bool(q.get("claimed", false))

	var badge_text := "Đang làm: %d/%d" % [cur, target]
	var badge_col := UIKit.COLOR_TEXT_MUTED
	if is_claimed:
		badge_text = "Đã nhận thưởng ✅"
		badge_col = Color(0.6, 0.9, 0.6)
	elif is_done:
		badge_text = "Đã hoàn thành! ✨"
		badge_col = UIKit.COLOR_TEXT_GOLD

	UIKit.label(hb_title, badge_text, 12, badge_col)

	# Hàng 2: Mô tả nhiệm vụ
	var desc_lbl := UIKit.label(vb, str(q.get("desc", "")), 12, Color(0.85, 0.82, 0.78))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Hàng 3: Thanh tiến độ + Phần thưởng + Nút Nhận
	var hb_bottom := HBoxContainer.new()
	hb_bottom.add_theme_constant_override("separation", 10)
	vb.add_child(hb_bottom)

	# Thanh tiến độ
	var prog_v := VBoxContainer.new()
	prog_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb_bottom.add_child(prog_v)

	var prog_bar := ProgressBar.new()
	prog_bar.custom_minimum_size = Vector2(0, 12)
	prog_bar.max_value = target
	prog_bar.value = cur
	prog_bar.show_percentage = false
	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = Color(0.08, 0.06, 0.04)
	bg_box.set_corner_radius_all(4)
	prog_bar.add_theme_stylebox_override("background", bg_box)
	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = Color(0.35, 0.85, 0.35) if is_done else Color(0.85, 0.65, 0.25)
	fill_box.set_corner_radius_all(4)
	prog_bar.add_theme_stylebox_override("fill", fill_box)
	prog_v.add_child(prog_bar)

	# Thông tin phần thưởng
	var coin_rew: int = int(q.get("reward_coins", 0))
	var item_rew_count: int = int(q.get("reward_item_count", 0))
	var item_rew_name: String = str(q.get("reward_item_name", ""))

	var reward_text := "Thưởng: %d xu" % coin_rew
	if item_rew_count > 0 and item_rew_name != "":
		reward_text += " + %d %s" % [item_rew_count, item_rew_name]

	UIKit.label(prog_v, reward_text, 11, UIKit.COLOR_TEXT_GOLD)

	# Nút nhận thưởng
	if is_done and not is_claimed:
		var claim_btn := Button.new()
		claim_btn.text = "Nhận Thưởng ✨"
		claim_btn.custom_minimum_size = Vector2(120, 32)
		claim_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		claim_btn.add_theme_font_size_override("font_size", 12)
		claim_btn.add_theme_stylebox_override("normal", UIKit.btn_style(Color(0.22, 0.50, 0.22), Color(0.4, 0.9, 0.4), 6, 1))
		claim_btn.add_theme_stylebox_override("hover", UIKit.btn_style(Color(0.30, 0.65, 0.30), Color(0.6, 1.0, 0.6), 6, 1))
		var q_id: String = str(q.get("id", ""))
		claim_btn.pressed.connect(func():
			var claimed_data = quest_manager.claim_reward(q_id)
			if not claimed_data.is_empty():
				reward_claimed.emit(claimed_data)
				var c_coins: int = int(claimed_data.get("reward_coins", 0))
				var c_cnt: int = int(claimed_data.get("reward_item_count", 0))
				var c_item: String = str(claimed_data.get("reward_item_name", ""))
				var toast_msg := "Nhận thưởng thành công: +%d xu" % c_coins
				if c_cnt > 0 and c_item != "":
					toast_msg += ", +%d %s" % [c_cnt, c_item]
				feedback.emit(toast_msg, Color(1.0, 0.9, 0.4))
				_refresh_tab_content()
		)
		hb_bottom.add_child(claim_btn)

	return card
