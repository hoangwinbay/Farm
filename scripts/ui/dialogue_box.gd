extends CanvasLayer
# Hộp thoại NPC & Hỏi đáp: Phong cách RPG Làng quê mộc mạc với thẻ tên nổi bật.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal finished
signal answered(yes: bool)

var name_container: PanelContainer
var name_label: Label
var text_label: Label
var advance_btn: Button
var yes_btn: Button
var no_btn: Button

var _lines: Array = []
var _idx := 0
var _ask_mode := false


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var strip := CenterContainer.new()
	strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_top = -220
	strip.offset_bottom = -70
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(strip)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 3, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	panel.custom_minimum_size = Vector2(720, 130)
	strip.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	# Hàng Thẻ Tên Nhân Vật
	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 10)
	v.add_child(top_h)

	name_container = PanelContainer.new()
	name_container.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.16, 0.10), UIKit.COLOR_BORDER_BRIGHT, 6))
	top_h.add_child(name_container)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_TITLE)
	name_label.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.03, 0.95))
	name_label.add_theme_constant_override("outline_size", 3)
	name_container.add_child(name_label)

	# Nội dung lời thoại
	text_label = Label.new()
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.add_theme_color_override("font_color", UIKit.COLOR_TEXT_BODY)
	text_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	text_label.add_theme_constant_override("outline_size", 2)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(680, 52)
	v.add_child(text_label)

	# Các nút hành động
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_END
	btns.add_theme_constant_override("separation", 10)
	v.add_child(btns)

	yes_btn = UIKit.styled_button(btns, "🌙 Ngủ ngay", 14, "buy")
	yes_btn.custom_minimum_size = Vector2(130, 34)
	yes_btn.pressed.connect(_answer.bind(true))

	no_btn = UIKit.styled_button(btns, "⏳ Chưa, thức tiếp", 14, "default")
	no_btn.custom_minimum_size = Vector2(140, 34)
	no_btn.pressed.connect(_answer.bind(false))

	advance_btn = UIKit.styled_button(btns, "Tiếp tục (E) ▸", 14, "primary")
	advance_btn.custom_minimum_size = Vector2(140, 34)
	advance_btn.pressed.connect(advance)

	yes_btn.visible = false
	no_btn.visible = false


func start(who: String, lines: Array) -> void:
	_lines = lines
	_idx = 0
	_ask_mode = false

	var prefix := ""
	if who.contains("Bác Tư"):
		prefix = "🌾 "
	elif who.contains("Chú Hai"):
		prefix = "🎣 "
	elif who.contains("Cô Tư"):
		prefix = "🐔 "
	elif who != "":
		prefix = "💬 "

	name_label.text = "%s%s" % [prefix, who]
	name_container.visible = (who != "")
	yes_btn.visible = false
	no_btn.visible = false
	visible = true
	_show_line()


func _show_line() -> void:
	text_label.text = str(_lines[_idx])
	advance_btn.visible = true
	advance_btn.text = "Tiếp tục (E) ▸" if _idx < _lines.size() - 1 else "Xong (E) ✓"


func advance() -> void:
	if _ask_mode or not visible:
		return
	_idx += 1
	if _idx >= _lines.size():
		visible = false
		finished.emit()
	else:
		_show_line()


func ask(text: String, yes_text := "Ngủ", no_text := "Chưa") -> void:
	_ask_mode = true
	name_container.visible = false
	text_label.text = text
	advance_btn.visible = false
	yes_btn.text = "🌙 %s" % yes_text
	no_btn.text = "⏳ %s" % no_text
	yes_btn.visible = true
	no_btn.visible = true
	visible = true


func _answer(yes: bool) -> void:
	_ask_mode = false
	yes_btn.visible = false
	no_btn.visible = false
	visible = false
	answered.emit(yes)


func force_close() -> void:
	_ask_mode = false
	visible = false
