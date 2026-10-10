extends Node
class_name TouchScrollHelper

# Bộ hỗ trợ vuốt cuộn màn hình cảm ứng mượt mà (Kinetic Touch Scroll) cho Godot trên Android / Mobile.
# Tự động gắn vào ScrollContainer:
# 1. Hỗ trợ vuốt trượt bất kỳ đâu trong danh sách (kể cả vuốt đè lên các nút Button hoặc thẻ hàng).
# 2. Ngăn ngừa bấm nhầm nút khi đang vuốt kéo (tự động triệt tiêu click khi di chuyển > ngưỡng drag).
# 3. Quán tính trượt tự nhiên (Kinetic momentum scrolling) với lực ma sát êm ái như ứng dụng Android gốc.

var scroll_container: ScrollContainer
var drag_threshold: float = 10.0
var friction: float = 7.5
var max_velocity: float = 3000.0

var is_touching: bool = false
var is_dragging: bool = false
var touch_id: int = -1
var start_pos: Vector2 = Vector2.ZERO
var last_pos: Vector2 = Vector2.ZERO
var velocity_y: float = 0.0
var velocity_x: float = 0.0
var last_time: float = 0.0


func _init(sc: ScrollContainer = null) -> void:
	if sc != null:
		scroll_container = sc


func _ready() -> void:
	if scroll_container == null and get_parent() is ScrollContainer:
		scroll_container = get_parent() as ScrollContainer
	set_process(true)


func _process(delta: float) -> void:
	if not is_instance_valid(scroll_container) or not scroll_container.is_visible_in_tree():
		velocity_y = 0.0
		velocity_x = 0.0
		is_touching = false
		is_dragging = false
		return

	# Xử lý quán tính trượt (Kinetic inertia deceleration) khi đã nhấc tay
	if not is_touching:
		var has_motion := false

		# Trục dọc (Vertical)
		if absf(velocity_y) > 3.0:
			has_motion = true
			var vsb := scroll_container.get_v_scroll_bar()
			if vsb:
				var max_y: float = maxf(0.0, vsb.max_value - vsb.page)
				var new_y: float = scroll_container.scroll_vertical - (velocity_y * delta)
				if new_y <= 0.0 or new_y >= max_y:
					scroll_container.scroll_vertical = int(clampf(new_y, 0.0, max_y))
					velocity_y = 0.0
				else:
					scroll_container.scroll_vertical = int(new_y)
					velocity_y = lerpf(velocity_y, 0.0, friction * delta)
			else:
				velocity_y = 0.0

		# Trục ngang (Horizontal - nếu có bật)
		if absf(velocity_x) > 3.0 and scroll_container.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			has_motion = true
			var hsb := scroll_container.get_h_scroll_bar()
			if hsb:
				var max_x: float = maxf(0.0, hsb.max_value - hsb.page)
				var new_x: float = scroll_container.scroll_horizontal - (velocity_x * delta)
				if new_x <= 0.0 or new_x >= max_x:
					scroll_container.scroll_horizontal = int(clampf(new_x, 0.0, max_x))
					velocity_x = 0.0
				else:
					scroll_container.scroll_horizontal = int(new_x)
					velocity_x = lerpf(velocity_x, 0.0, friction * delta)
			else:
				velocity_x = 0.0

		if not has_motion:
			velocity_y = 0.0
			velocity_x = 0.0


func _input(event: InputEvent) -> void:
	if not is_instance_valid(scroll_container) or not scroll_container.is_visible_in_tree():
		return

	var rect: Rect2 = scroll_container.get_global_rect()

	# 1. Chạm xuống (ScreenTouch hoặc chuột trái)
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed:
			if rect.has_point(st.position):
				_on_touch_down(st.index, st.position)
		else:
			if is_touching and touch_id == st.index:
				_on_touch_up()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb: InputEventMouseButton = event
		if mb.pressed:
			if rect.has_point(mb.position):
				_on_touch_down(-1, mb.position)
		else:
			if is_touching and touch_id == -1:
				_on_touch_up()

	# 2. Vuốt kéo (ScreenDrag hoặc chuột di chuyển khi đang giữ chuột trái)
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		if is_touching and touch_id == sd.index:
			_on_drag_move(sd.position)

	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		var mm: InputEventMouseMotion = event
		if is_touching and touch_id == -1:
			_on_drag_move(mm.position)


func _on_touch_down(id: int, pos: Vector2) -> void:
	is_touching = true
	is_dragging = false
	touch_id = id
	start_pos = pos
	last_pos = pos
	velocity_y = 0.0
	velocity_x = 0.0
	last_time = Time.get_ticks_msec() / 1000.0


func _on_drag_move(pos: Vector2) -> void:
	var total_delta: Vector2 = pos - start_pos
	var dy: float = pos.y - last_pos.y
	var dx: float = pos.x - last_pos.x

	if not is_dragging:
		var allow_h := (scroll_container.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED)
		var check_dist: float = total_delta.length() if allow_h else absf(total_delta.y)
		if check_dist >= drag_threshold:
			is_dragging = true
			# Hủy focus của bất kỳ Button nào đang bị đè ngón tay
			var vp := scroll_container.get_viewport()
			if vp:
				var f := vp.gui_get_focus_owner()
				if f:
					f.release_focus()

	if is_dragging:
		# Cuộn trực tiếp
		if scroll_container.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			scroll_container.scroll_vertical -= int(dy)

		if scroll_container.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			scroll_container.scroll_horizontal -= int(dx)

		# Tính vận tốc lướt
		var now: float = Time.get_ticks_msec() / 1000.0
		var dt: float = now - last_time
		if dt > 0.001:
			var inst_vel_y := dy / dt
			var inst_vel_x := dx / dt
			velocity_y = clampf(lerpf(velocity_y, inst_vel_y, 0.45), -max_velocity, max_velocity)
			velocity_x = clampf(lerpf(velocity_x, inst_vel_x, 0.45), -max_velocity, max_velocity)

		last_time = now
		last_pos = pos

		# Tiêu thụ sự kiện kéo để các control bên dưới không bị kéo nhầm
		scroll_container.get_viewport().set_input_as_handled()


func _on_touch_up() -> void:
	if is_dragging:
		# Tiêu thụ sự kiện thả tay để không kích hoạt click vào các nút Button bên dưới!
		scroll_container.get_viewport().set_input_as_handled()

	is_touching = false
	is_dragging = false
	touch_id = -1
