extends RefCounted
# Hệ thống giao diện Phong cách Nông trại ấm cúng & Mộc mạc (Rustic Wood & Cozy Farm).

const TextureGen := preload("res://scripts/texture_gen.gd")
const TouchScrollHelperClass := preload("res://scripts/ui/touch_scroll_helper.gd")

# Bảng màu chủ đạo - Gỗ ấm, vàng lúa chín, giấy da cổ
const COLOR_WOOD_DARK := Color(0.12, 0.08, 0.05, 0.98)       # Khung gỗ sẫm / viền dày
const COLOR_WOOD_BG := Color(0.18, 0.12, 0.08, 0.96)         # Nền panel gỗ tếch ấm
const COLOR_WOOD_INNER := Color(0.24, 0.16, 0.10, 0.92)      # Nền thẻ / khay bên trong
const COLOR_WOOD_LIGHT := Color(0.32, 0.22, 0.14, 0.95)      # Gỗ sáng / hover thẻ
const COLOR_WOOD_LOCKED := Color(0.15, 0.11, 0.09, 0.88)     # Thẻ bị khóa

const COLOR_BORDER_GOLD := Color(0.86, 0.70, 0.32)           # Vàng rơm / đồng cổ
const COLOR_BORDER_BRIGHT := Color(1.0, 0.88, 0.45)          # Vàng sáng nổi bật
const COLOR_BORDER_WOOD := Color(0.45, 0.30, 0.18)           # Viền gỗ tự nhiên
const COLOR_BORDER_DARK := Color(0.08, 0.05, 0.03)           # Rãnh chạm khắc sẫm

const COLOR_TEXT_TITLE := Color(1.0, 0.90, 0.50)            # Tiêu đề vàng lúa
const COLOR_TEXT_BODY := Color(0.96, 0.92, 0.85)             # Chữ trắng ngà vỏ trấu
const COLOR_TEXT_MUTED := Color(0.78, 0.72, 0.62)            # Chữ phụ màu be
const COLOR_TEXT_GOLD := Color(1.0, 0.84, 0.28)              # Tiền vàng
const COLOR_TEXT_GREEN := Color(0.55, 0.92, 0.48)            # Xanh lá mua giống
const COLOR_TEXT_BLUE := Color(0.52, 0.85, 1.0)              # Xanh sông nước câu cá
const COLOR_TEXT_ORANGE := Color(1.0, 0.72, 0.40)            # Cam thu hoạch / bán

# Nút bấm chuyên dụng
const BTN_NORMAL_BG := Color(0.34, 0.22, 0.13)
const BTN_HOVER_BG := Color(0.46, 0.31, 0.18)
const BTN_PRESSED_BG := Color(0.24, 0.15, 0.08)
const BTN_DISABLED_BG := Color(0.20, 0.16, 0.13)

const BTN_BUY_BG := Color(0.18, 0.34, 0.16)
const BTN_BUY_HOVER := Color(0.26, 0.46, 0.22)
const BTN_SELL_BG := Color(0.42, 0.24, 0.12)
const BTN_SELL_HOVER := Color(0.56, 0.33, 0.16)
const BTN_CLOSE_BG := Color(0.36, 0.14, 0.12)
const BTN_CLOSE_HOVER := Color(0.48, 0.18, 0.16)


# ---------------- StyleBoxes Căn Bản (Tương thích ngược) ----------------

static func panel_box(bg := COLOR_WOOD_BG, border := COLOR_BORDER_GOLD) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	sb.set_content_margin_all(14)
	return sb


static func row_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_WOOD_INNER
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.border_color = COLOR_BORDER_WOOD
	sb.set_content_margin_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	return sb


static func row_locked_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_WOOD_LOCKED
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.28, 0.22, 0.18, 0.7)
	sb.set_content_margin_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	return sb


static func toast_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.09, 0.05, 0.94)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = COLOR_BORDER_GOLD
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	sb.set_content_margin_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	return sb


# ---------------- StyleBoxes Nâng Cao Cho Phong Cách Gỗ Mộc ----------------

static func wood_frame(radius: int = 12, border_w: int = 3, bg := COLOR_WOOD_BG, border := COLOR_BORDER_GOLD) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_w)
	sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 5)
	sb.set_content_margin_all(16)
	return sb


static func slot_box(active: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.05, 0.95) if not active else Color(0.24, 0.17, 0.09, 0.98)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(2 if active else 1)
	sb.border_color = COLOR_BORDER_BRIGHT if active else COLOR_BORDER_WOOD
	if active:
		sb.shadow_color = Color(1.0, 0.85, 0.35, 0.35)
		sb.shadow_size = 4
	sb.set_content_margin_all(4)
	return sb


static func badge_box(bg := Color(0.12, 0.08, 0.05, 0.85), border := COLOR_BORDER_WOOD, radius: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(1)
	sb.border_color = border
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb


static func keycap_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.28, 0.20, 0.13)
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(1)
	sb.border_color = COLOR_BORDER_GOLD
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 1)
	return sb


# ---------------- Style Nút Bấm Gỗ Tự Nhiên & Chuyên Dụng ----------------

static func btn_style(bg: Color, border: Color, radius: int = 6, shadow_y: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(1)
	sb.border_color = border
	if shadow_y > 0:
		sb.shadow_color = Color(0, 0, 0, 0.4)
		sb.shadow_size = 3
		sb.shadow_offset = Vector2(0, shadow_y)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	return sb


# Tạo nút bấm chuẩn với hiệu ứng đầy đủ (normal, hover, pressed, disabled, focus)
static func styled_button(parent: Node, text: String, size: int = 14, type: String = "default") -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var norm_bg: Color
	var hov_bg: Color
	var prs_bg: Color
	var dis_bg := BTN_DISABLED_BG
	var border := COLOR_BORDER_GOLD

	match type:
		"buy", "green":
			norm_bg = BTN_BUY_BG
			hov_bg = BTN_BUY_HOVER
			prs_bg = Color(0.12, 0.24, 0.10)
			border = Color(0.55, 0.85, 0.45)
		"sell", "orange":
			norm_bg = BTN_SELL_BG
			hov_bg = BTN_SELL_HOVER
			prs_bg = Color(0.28, 0.15, 0.08)
			border = Color(0.95, 0.65, 0.30)
		"danger", "close":
			norm_bg = BTN_CLOSE_BG
			hov_bg = BTN_CLOSE_HOVER
			prs_bg = Color(0.24, 0.08, 0.07)
			border = Color(0.85, 0.45, 0.40)
		"primary", "gold":
			norm_bg = Color(0.48, 0.32, 0.15)
			hov_bg = Color(0.60, 0.42, 0.20)
			prs_bg = Color(0.32, 0.20, 0.08)
			border = COLOR_BORDER_BRIGHT
		"tab":
			norm_bg = Color(0.22, 0.15, 0.10)
			hov_bg = Color(0.34, 0.23, 0.15)
			prs_bg = Color(0.16, 0.10, 0.06)
			border = COLOR_BORDER_WOOD
		_:
			norm_bg = BTN_NORMAL_BG
			hov_bg = BTN_HOVER_BG
			prs_bg = BTN_PRESSED_BG
			border = COLOR_BORDER_GOLD

	b.add_theme_stylebox_override("normal", btn_style(norm_bg, border, 6, 2))
	b.add_theme_stylebox_override("hover", btn_style(hov_bg, border.lightened(0.2), 6, 2))
	b.add_theme_stylebox_override("pressed", btn_style(prs_bg, border.darkened(0.2), 6, 0))
	b.add_theme_stylebox_override("disabled", btn_style(dis_bg, Color(0.32, 0.26, 0.22), 6, 0))

	# Focus không dùng viền xanh mặc định mà dùng viền vàng thanh thoát
	var focus_box := btn_style(Color(0, 0, 0, 0), COLOR_BORDER_BRIGHT, 6, 0)
	focus_box.set_border_width_all(1)
	b.add_theme_stylebox_override("focus", focus_box)

	b.add_theme_color_override("font_color", COLOR_TEXT_BODY)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", COLOR_TEXT_TITLE)
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.45))
	b.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	b.add_theme_constant_override("outline_size", 3)

	b.custom_minimum_size = Vector2(0, 32)
	if parent != null:
		parent.add_child(b)
	return b


# Giữ nguyên hàm button gốc để tương thích code cũ
static func button(parent: Node, text: String, size: int = 14) -> Button:
	return styled_button(parent, text, size, "default")


# ---------------- Label & Tiện Ích Văn Bản ----------------

static func label(parent: Control, text: String, size: int = 15, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	l.add_theme_constant_override("outline_size", 2)
	if parent != null:
		parent.add_child(l)
	return l


static func title_label(parent: Control, text: String, size: int = 24, color := COLOR_TEXT_TITLE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.03, 0.98))
	l.add_theme_constant_override("outline_size", 6)
	if parent != null:
		parent.add_child(l)
	return l


# ---------------- Thanh Cuộn Gỗ Đẹp Mắt ----------------

static func style_scroll_container(sc: ScrollContainer) -> void:
	if sc == null:
		return

	var vsb := sc.get_v_scroll_bar()
	if vsb:
		var grabber := StyleBoxFlat.new()
		grabber.bg_color = Color(0.58, 0.40, 0.24)
		grabber.set_corner_radius_all(6)
		grabber.set_border_width_all(2)
		grabber.border_color = COLOR_BORDER_GOLD
		grabber.content_margin_left = 3
		grabber.content_margin_right = 3

		var grabber_h := StyleBoxFlat.new()
		grabber_h.bg_color = Color(0.75, 0.54, 0.32)
		grabber_h.set_corner_radius_all(6)
		grabber_h.set_border_width_all(2)
		grabber_h.border_color = COLOR_BORDER_BRIGHT
		grabber_h.content_margin_left = 3
		grabber_h.content_margin_right = 3

		var track := StyleBoxFlat.new()
		track.bg_color = Color(0.12, 0.08, 0.05, 0.85)
		track.set_corner_radius_all(6)
		track.content_margin_left = 3
		track.content_margin_right = 3

		vsb.add_theme_stylebox_override("grabber", grabber)
		vsb.add_theme_stylebox_override("grabber_highlight", grabber_h)
		vsb.add_theme_stylebox_override("grabber_pressed", grabber_h)
		vsb.add_theme_stylebox_override("scroll", track)
		vsb.custom_minimum_size = Vector2(18, 0)

	var hsb := sc.get_h_scroll_bar()
	if hsb and sc.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		var h_grabber := StyleBoxFlat.new()
		h_grabber.bg_color = Color(0.58, 0.40, 0.24)
		h_grabber.set_corner_radius_all(6)
		h_grabber.set_border_width_all(2)
		h_grabber.border_color = COLOR_BORDER_GOLD

		var h_track := StyleBoxFlat.new()
		h_track.bg_color = Color(0.12, 0.08, 0.05, 0.85)
		h_track.set_corner_radius_all(6)

		hsb.add_theme_stylebox_override("grabber", h_grabber)
		hsb.add_theme_stylebox_override("scroll", h_track)
		hsb.custom_minimum_size = Vector2(0, 18)

	attach_touch_scroll(sc)


static func attach_touch_scroll(sc: ScrollContainer) -> void:
	if sc == null:
		return
	for c in sc.get_children():
		if c is TouchScrollHelperClass:
			return
	var helper := TouchScrollHelperClass.new(sc)
	sc.add_child(helper)


# ---------------- Huy Hiệu & Phím Tắt Trực Quan ----------------

static func key_badge(parent: Node, key_text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", keycap_box())
	var l := label(p, key_text, 12, COLOR_TEXT_TITLE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if parent != null:
		parent.add_child(p)
	return p


static func gold_badge(parent: Node, amount: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", badge_box(Color(0.18, 0.12, 0.06), COLOR_BORDER_GOLD, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)

	var icon := TextureRect.new()
	icon.texture = TextureGen.coin_icon()
	icon.custom_minimum_size = Vector2(18, 18)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	h.add_child(icon)

	label(h, "%d xu" % amount, 15, COLOR_TEXT_GOLD)
	if parent != null:
		parent.add_child(p)
	return p


static func divider(parent: Node) -> ColorRect:
	var cr := ColorRect.new()
	cr.color = Color(0.86, 0.70, 0.32, 0.35)
	cr.custom_minimum_size = Vector2(0, 1)
	if parent != null:
		parent.add_child(cr)
	return cr
