extends CanvasLayer
# Menu Tạm Dừng: Biển gỗ mộc mạc treo giữa màn hình với thông tin tóm tắt nông trại.

const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal resumed
signal saved
signal menu_requested
signal settings_requested

var summary_label: Label


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.wood_frame(16, 3, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	panel.custom_minimum_size = Vector2(380, 0)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)

	var title := UIKit.title_label(v, "⏸️ TẠM DỪNG", 26, UIKit.COLOR_TEXT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Thẻ tóm tắt thông tin ngày & tiền
	var sum_box := PanelContainer.new()
	sum_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.09), UIKit.COLOR_BORDER_WOOD, 6))
	v.add_child(sum_box)
	summary_label = UIKit.label(sum_box, "Ngày 1 · 07:00 · 100 xu", 13, UIKit.COLOR_TEXT_GOLD)
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	UIKit.divider(v)

	var resume := UIKit.styled_button(v, "▶ Tiếp tục chơi", 16, "buy")
	resume.custom_minimum_size = Vector2(280, 42)
	resume.pressed.connect(func(): resumed.emit())

	var save := UIKit.styled_button(v, "💾 Lưu trò chơi", 16, "primary")
	save.custom_minimum_size = Vector2(280, 42)
	save.pressed.connect(func(): saved.emit())

	var settings_btn := UIKit.styled_button(v, "⚙️ Cài đặt (Âm thanh & Tốc độ)", 15, "default")
	settings_btn.custom_minimum_size = Vector2(280, 40)
	settings_btn.pressed.connect(func(): settings_requested.emit())

	var menu := UIKit.styled_button(v, "🏠 Lưu & về màn hình chính", 15, "default")
	menu.custom_minimum_size = Vector2(280, 40)
	menu.pressed.connect(func(): menu_requested.emit())

	var note := UIKit.label(v, "Bấm Esc để tiếp tục chơi ngay", 12, UIKit.COLOR_TEXT_MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func open() -> void:
	if summary_label != null:
		summary_label.text = "Ngày %d  •  %s  •  %d xu" % [GameState.day, GameState.clock_text(), GameState.money]
	visible = true


func close() -> void:
	visible = false
