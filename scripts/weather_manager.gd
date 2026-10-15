extends CanvasLayer
# Quản lý hệ thống Thời tiết: Trời nắng, Mưa nhỏ, Mưa rào, Mưa dông, Gió lộng.
# Điều phối hiệu ứng hạt (mưa rơi, sấm sét chớp giật, lá bay cuộn gió), tự động tưới đất và rơi vật phẩm hiếm.

const TextureGen := preload("res://scripts/texture_gen.gd")
const OreDB := preload("res://scripts/ore_db.gd")

const SUNNY := "sunny"       # Trời nắng ☀️
const DRIZZLE := "drizzle"   # Mưa nhỏ 🌦️
const RAIN := "rain"         # Mưa rào 🌧️
const STORM := "storm"       # Mưa dông ⛈️
const WINDY := "windy"       # Gió lộng 🍃

var current_weather: String = SUNNY
var main_node: Node2D = null
var player: CharacterBody2D = null
var farm_node: Node2D = null

# Lớp vẽ CanvasLayer toàn màn hình (layer 5: trên world, dưới HUD)
var _overlay: Control = null
var _lightning_flash: ColorRect = null
var _lightning_alpha: float = 0.0
var _lightning_timer: float = 0.0

# Hiệu ứng mưa (Rain simulation)
var _rain_drops: Array = []
var _splashes: Array = []

# Hiệu ứng gió & lá bay (Wind & Leaves simulation)
var _leaves: Array = []

# Danh sách node vật phẩm rơi trên mặt đất
var _drop_nodes: Array[Node2D] = []

class RainDrop:
	var pos: Vector2
	var speed: float
	var length: float
	var alpha: float
	var vx: float
	var vy: float

class LeafParticle:
	var pos: Vector2
	var speed: float
	var angle: float
	var rot_speed: float
	var size: float
	var color: Color
	var wave_offset: float

class SplashRipple:
	var pos: Vector2
	var radius: float
	var max_radius: float
	var alpha: float


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Lớp vẽ hạt toàn màn hình
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_on_overlay_draw)
	add_child(_overlay)

	# Lớp chớp sáng sấm sét
	_lightning_flash = ColorRect.new()
	_lightning_flash.color = Color.WHITE
	_lightning_flash.modulate.a = 0.0
	_lightning_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lightning_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lightning_flash)


func setup(main_ref: Node2D, player_ref: CharacterBody2D, farm_ref: Node2D) -> void:
	main_node = main_ref
	player = player_ref
	farm_node = farm_ref
	set_weather(GameState.weather)


static func get_weather_name(w: String) -> String:
	match w:
		DRIZZLE:
			return "Mưa nhỏ"
		RAIN:
			return "Mưa rào"
		STORM:
			return "Mưa dông"
		WINDY:
			return "Gió lộng"
		_:
			return "Nắng đẹp"


static func get_weather_icon(w: String) -> String:
	match w:
		DRIZZLE:
			return "🌦️"
		RAIN:
			return "🌧️"
		STORM:
			return "⛈️"
		WINDY:
			return "🍃"
		_:
			return "☀️"


static func get_weather_display(w: String) -> String:
	return "%s %s" % [get_weather_icon(w), get_weather_name(w)]


static func roll_weather(day: int) -> String:
	if day <= 1:
		return SUNNY
	var r := randf()
	if r < 0.38:
		return SUNNY
	elif r < 0.58:
		return DRIZZLE
	elif r < 0.74:
		return RAIN
	elif r < 0.88:
		return WINDY
	else:
		return STORM


func set_weather(w: String) -> void:
	current_weather = w
	GameState.weather = w
	_init_particles()
	if is_instance_valid(main_node):
		if current_weather == STORM:
			_lightning_timer = randf_range(4.0, 10.0)
		_announce_weather()


func _announce_weather() -> void:
	if not is_instance_valid(main_node) or main_node.hud == null:
		return
	match current_weather:
		SUNNY:
			main_node.hud.toast("Trời nắng đẹp rạng rỡ! Cây cối cần được tưới nước. ☀️", Color(1.0, 0.95, 0.5))
		DRIZZLE:
			main_node.hud.toast("Mưa nhỏ rả rích! Đất vườn luôn ẩm ướt mát mẻ. 🌦️", Color(0.7, 0.9, 1.0))
		RAIN:
			main_node.hud.toast("Mưa rào mát lành! Tự động tưới đẫm toàn bộ ruộng cả ngày 🌧️", Color(0.5, 0.85, 1.0))
		STORM:
			main_node.hud.toast("Mưa dông sấm chớp! Cẩn thận sấm sét rền vang ngoài trời ⛈️", Color(0.85, 0.75, 1.0))
		WINDY:
			main_node.hud.toast("Gió lộng mát rượi! Lá bay rào rạt và có vật phẩm rơi trên cỏ 🍃", Color(0.75, 1.0, 0.7))


func _init_particles() -> void:
	_rain_drops.clear()
	_splashes.clear()
	_leaves.clear()

	var view_size := _overlay.get_rect().size if _overlay != null else Vector2.ZERO
	if view_size.x <= 0:
		view_size = Vector2(1280, 720)

	var count_drops := 0
	if current_weather == DRIZZLE:
		count_drops = 75
	elif current_weather == RAIN:
		count_drops = 190
	elif current_weather == STORM:
		count_drops = 340

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Khởi tạo hạt mưa
	for i in count_drops:
		var d := RainDrop.new()
		d.pos = Vector2(rng.randf_range(-100, view_size.x + 200), rng.randf_range(-100, view_size.y + 100))
		if current_weather == DRIZZLE:
			d.speed = rng.randf_range(320, 480)
			d.length = rng.randf_range(8, 14)
			d.alpha = rng.randf_range(0.35, 0.65)
			d.vx = rng.randf_range(-30, -10)
			d.vy = d.speed
		elif current_weather == RAIN:
			d.speed = rng.randf_range(580, 780)
			d.length = rng.randf_range(16, 26)
			d.alpha = rng.randf_range(0.5, 0.8)
			d.vx = rng.randf_range(-90, -45)
			d.vy = d.speed
		elif current_weather == STORM:
			d.speed = rng.randf_range(780, 1050)
			d.length = rng.randf_range(24, 40)
			d.alpha = rng.randf_range(0.65, 0.95)
			d.vx = rng.randf_range(-180, -110)
			d.vy = d.speed
		_rain_drops.append(d)

	# Khởi tạo lá bay theo gió (Windy)
	if current_weather == WINDY:
		for i in 50:
			var lf := LeafParticle.new()
			lf.pos = Vector2(rng.randf_range(-200, view_size.x + 200), rng.randf_range(-50, view_size.y + 50))
			lf.speed = rng.randf_range(200, 340)
			lf.angle = rng.randf_range(0, TAU)
			lf.rot_speed = rng.randf_range(-3.0, 3.0)
			lf.size = rng.randf_range(4.5, 8.0)
			lf.wave_offset = rng.randf_range(0, TAU)
			var color_pool := [
				Color(0.42, 0.72, 0.25, 0.85),
				Color(0.85, 0.68, 0.20, 0.9),
				Color(0.92, 0.48, 0.18, 0.85),
				Color(0.95, 0.65, 0.75, 0.85)
			]
			lf.color = color_pool[rng.randi_range(0, color_pool.size() - 1)]
			_leaves.append(lf)


func _process(delta: float) -> void:
	if not is_instance_valid(main_node) or main_node.mode != main_node.Mode.PLAY:
		if _overlay != null:
			_overlay.queue_redraw()
		return

	# Tự động làm ẩm và tưới toàn bộ ruộng ngoài trời khi mưa (vẫn tiếp tục tưới ruộng trên mặt đất)
	if current_weather in [DRIZZLE, RAIN, STORM]:
		_auto_water_farm_crops()

	# Khi người chơi đang ở dưới hầm mỏ, tắt toàn bộ hiệu ứng hình ảnh (mưa, sét, lá bay) trên màn hình
	if main_node.in_mine:
		if _lightning_flash != null:
			_lightning_flash.modulate.a = 0.0
		if _overlay != null:
			_overlay.queue_redraw()
		return

	# Cập nhật hạt mưa
	if current_weather in [DRIZZLE, RAIN, STORM]:
		_update_rain(delta)

	# Cập nhật sấm sét trong bão
	if current_weather == STORM:
		_update_storm_lightning(delta)

	# Cập nhật lá bay khi gió lộng
	if current_weather == WINDY:
		_update_windy_leaves(delta)

	# Cập nhật chớp sáng sấm sét
	if _lightning_alpha > 0.0:
		_lightning_alpha = maxf(0.0, _lightning_alpha - delta * 4.5)
		if _lightning_flash != null:
			_lightning_flash.modulate.a = _lightning_alpha

	if _overlay != null:
		_overlay.queue_redraw()


func _auto_water_farm_crops() -> void:
	if not is_instance_valid(farm_node) or farm_node.tiles == null:
		return
	for t in farm_node.tiles.values():
		if t != null and t.tstate == 2: # PLANTED
			if not t.watered or t._wet_time > 0.0:
				t.watered = true
				t._wet_time = 0.0
				t.refresh()
		elif t != null and t.tstate == 1: # TILLED
			pass


func _update_rain(delta: float) -> void:
	var view_size := _overlay.get_rect().size if _overlay != null else Vector2(1280, 720)
	var rng := RandomNumberGenerator.new()

	for item in _rain_drops:
		var d: RainDrop = item as RainDrop
		if d == null:
			continue
		d.pos.x += d.vx * delta
		d.pos.y += d.vy * delta

		# Khi rơi xuống đáy màn hình -> tạo giọt bắn nước (splash) và hồi sinh ở đỉnh
		if d.pos.y > view_size.y:
			if rng.randf() < 0.25 and _splashes.size() < 40:
				var sp := SplashRipple.new()
				sp.pos = Vector2(d.pos.x, minf(d.pos.y, view_size.y - rng.randf_range(0, 40)))
				sp.radius = 1.0
				sp.max_radius = rng.randf_range(3.0, 6.0)
				sp.alpha = 0.6
				_splashes.append(sp)

			d.pos.y = rng.randf_range(-60, -10)
			d.pos.x = rng.randf_range(-50, view_size.x + 150)

	# Cập nhật vòng sóng nước li ti (splashes)
	var alive_splashes: Array = []
	for sp_item in _splashes:
		var sp: SplashRipple = sp_item as SplashRipple
		if sp == null:
			continue
		sp.radius += delta * 14.0
		sp.alpha -= delta * 3.0
		if sp.alpha > 0.0 and sp.radius < sp.max_radius:
			alive_splashes.append(sp)
	_splashes = alive_splashes


func _update_windy_leaves(delta: float) -> void:
	var view_size := _overlay.get_rect().size if _overlay != null else Vector2(1280, 720)
	var time_now := Time.get_ticks_msec() / 1000.0

	for item in _leaves:
		var lf: LeafParticle = item as LeafParticle
		if lf == null:
			continue
		lf.pos.x += lf.speed * delta
		lf.pos.y += sin(time_now * 3.0 + lf.wave_offset) * 40.0 * delta + delta * 20.0
		lf.angle += lf.rot_speed * delta

		if lf.pos.x > view_size.x + 50:
			lf.pos.x = randf_range(-80, -10)
			lf.pos.y = randf_range(-30, view_size.y + 30)


func _update_storm_lightning(delta: float) -> void:
	_lightning_timer -= delta
	if _lightning_timer <= 0.0:
		_trigger_lightning_strike()
		_lightning_timer = randf_range(7.0, 16.0)


func _trigger_lightning_strike() -> void:
	if is_instance_valid(main_node) and main_node.in_mine:
		return

	# Chớp sáng màn hình cực đại
	_lightning_alpha = 0.88
	if _lightning_flash != null:
		_lightning_flash.modulate.a = _lightning_alpha

	# Rung lắc màn hình nhẹ tạo cảm giác sấm rền
	if is_instance_valid(main_node) and is_instance_valid(main_node.cam):
		var tw := create_tween()
		tw.tween_property(main_node.cam, "offset", Vector2(randf_range(-4, 4), randf_range(-4, 4)), 0.06)
		tw.tween_property(main_node.cam, "offset", Vector2.ZERO, 0.12)

	# Tỉ lệ 50% sấm sét đánh trúng đất trống rớt khoáng sản quý
	if randf() < 0.50 and is_instance_valid(main_node):
		_spawn_storm_ore_drop()


func _spawn_storm_ore_drop() -> void:
	if not is_instance_valid(main_node):
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _attempt in 20:
		var x := rng.randf_range(80.0, main_node.WORLD_SIZE.x - 80.0)
		var y := rng.randf_range(80.0, main_node.WORLD_SIZE.y - 80.0)
		var pos := Vector2(x, y)
		if main_node._is_grass_surface(pos):
			var ore_pool := ["coal", "copper_ore", "iron_ore", "gold_ore", "ruby"]
			var ore_id: String = ore_pool[rng.randi_range(0, ore_pool.size() - 1)]
			spawn_ground_item(ore_id, "ore", pos)
			break


func spawn_ground_item(item_id: String, item_type: String, world_pos: Vector2) -> void:
	if not is_instance_valid(main_node) or not is_instance_valid(main_node.world):
		return

	var body := Area2D.new()
	body.position = world_pos
	body.z_index = 5

	var spr := Sprite2D.new()
	if item_type == "ore":
		spr.texture = TextureGen.ore_item_icon(item_id)
	elif item_type == "crop":
		spr.texture = TextureGen.get_crate_fill_tex(item_id, "crop")
	else:
		spr.texture = TextureGen.star_icon()

	spr.scale = Vector2(1.2, 1.2)
	body.add_child(spr)

	# Hiệu ứng lơ lửng nhấp nhô nhẹ
	var tw := body.create_tween().set_loops()
	tw.tween_property(spr, "position:y", -3.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(spr, "position:y", 2.0, 0.6).set_trans(Tween.TRANS_SINE)

	main_node.world.add_child(body)
	_drop_nodes.append(body)

	# Đăng ký điểm tương tác
	var d_name: String = item_id
	if item_type == "ore":
		var od := OreDB.get_ore(item_id)
		d_name = str(od.get("name", item_id))
	elif item_id == "sau_bo":
		d_name = "Sâu bọ"

	var interact_data := {
		"pos": world_pos,
		"r": 36.0,
		"label": "Nhặt %s" % d_name,
		"cb": func():
			if not is_instance_valid(body):
				return
			if item_type == "ore":
				Inventory.add_ore(item_id, 1)
			else:
				Inventory.add_produce(item_id, 1)
			main_node.hud.toast("Đã nhặt 1 %s! ✨" % d_name, Color(1.0, 0.9, 0.5))
			_remove_ground_item(body, world_pos)
	}
	main_node.interactables.append(interact_data)


func _remove_ground_item(body: Node2D, world_pos: Vector2) -> void:
	if is_instance_valid(body):
		body.queue_free()
	_drop_nodes.erase(body)
	if is_instance_valid(main_node):
		var remaining: Array = []
		for it in main_node.interactables:
			if it.get("pos") != world_pos:
				remaining.append(it)
		main_node.interactables = remaining


func _on_overlay_draw() -> void:
	if _overlay == null:
		return
	if is_instance_valid(main_node) and main_node.in_mine:
		return

	# 1. Vẽ các hạt mưa
	if current_weather in [DRIZZLE, RAIN, STORM]:
		var drop_col := Color(0.82, 0.92, 1.0, 0.65)
		if current_weather == STORM:
			drop_col = Color(0.72, 0.85, 1.0, 0.8)
		elif current_weather == DRIZZLE:
			drop_col = Color(0.88, 0.95, 1.0, 0.5)

		for d in _rain_drops:
			var drop: RainDrop = d as RainDrop
			if drop != null:
				var end_pt: Vector2 = drop.pos + Vector2(drop.vx * (drop.length / drop.speed), drop.vy * (drop.length / drop.speed))
				var c := drop_col
				c.a = drop.alpha
				_overlay.draw_line(drop.pos, end_pt, c, 1.2 if current_weather == STORM else 1.0)

		# Vẽ vòng sóng nước va chạm trên mặt đất
		for sp in _splashes:
			var ripple: SplashRipple = sp as SplashRipple
			if ripple != null:
				var sc := Color(0.85, 0.93, 1.0, ripple.alpha)
				_overlay.draw_arc(ripple.pos, ripple.radius, 0, TAU, 12, sc, 1.0)

	# 2. Vẽ lá bay theo gió (Windy)
	if current_weather == WINDY:
		for lf in _leaves:
			var leaf: LeafParticle = lf as LeafParticle
			if leaf != null:
				var pts := PackedVector2Array([
					Vector2(-leaf.size, 0).rotated(leaf.angle),
					Vector2(0, -leaf.size * 0.55).rotated(leaf.angle),
					Vector2(leaf.size, 0).rotated(leaf.angle),
					Vector2(0, leaf.size * 0.55).rotated(leaf.angle)
				])
				for i in pts.size():
					pts[i] += leaf.pos
				_overlay.draw_colored_polygon(pts, leaf.color)
