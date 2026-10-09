extends RefCounted
# Quản lý Câu Cá & Hồ Nước (Fishing & Pond Manager)

const TextureGen := preload("res://scripts/texture_gen.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const WeatherManagerScript := preload("res://scripts/weather_manager.gd")

const POND_RECT := Rect2(1232, 720, 416, 368)
const FISH_SPOT_POS := Vector2(1440, 880)   # tâm hồ Stardew Valley hình tròn tràn biên Nam

var main: Node2D
var world: Node2D
var player: CharacterBody2D

var fishing := false
var fishing_left := 0.0
var _rod_spr: Sprite2D
var _bobber_spr: Sprite2D
var _fishing_line: Line2D
var _lake_ripple_timer: float = 0.5
var _bobber_ripple_timer: float = 0.0


func setup(p_main: Node2D, p_world: Node2D, p_player: CharacterBody2D) -> void:
	main = p_main
	world = p_world
	player = p_player


func build_pond_collision() -> StaticBody2D:
	var pond_body := StaticBody2D.new()
	pond_body.name = "PondBody"

	# Chu vi mép bờ ao hồ Stardew Valley
	var pond_poly := CollisionPolygon2D.new()
	var pond_pts := PackedVector2Array([
		Vector2(1296, 756),
		Vector2(1440, 756),
		Vector2(1568, 756),
		Vector2(1584, 768),
		Vector2(1600, 784),
		Vector2(1608, 840),
		Vector2(1610, 900),
		Vector2(1605, 930),
		Vector2(1592, 960),
		Vector2(1585, 1000),
		Vector2(1576, 1085),
		Vector2(1303, 1085),
		Vector2(1302, 1020),
		Vector2(1295, 990),
		Vector2(1287, 960),
		Vector2(1285, 930),
		Vector2(1269, 900),
		Vector2(1271, 840),
		Vector2(1280, 800),
		Vector2(1280, 768),
	])
	pond_poly.polygon = pond_pts
	pond_body.add_child(pond_poly)
	world.add_child(pond_body)
	return pond_body


func refill_water_can() -> void:
	if Inventory.water_level >= Inventory.water_max:
		if is_instance_valid(main.hud):
			main.hud.toast("Bình tưới đã đầy nước (%d/%d)!" % [Inventory.water_level, Inventory.water_max])
		return
	if GameState.stamina < 2.0:
		if is_instance_valid(main.hud):
			main.hud.toast("Bạn đã kiệt sức! Không đủ sức múc nước (cần 2⚡). Hãy ăn nông sản hoặc thịt!", Color(1.0, 0.45, 0.35))
		return
	GameState.use_stamina(2.0)
	var _added: int = Inventory.refill_water()
	player.facing = (POND_RECT.get_center() - player.position).normalized()
	if main.has_method("_spawn_effect"):
		main._spawn_effect("fx_water", player.position + player.facing * 18.0)
	player.play_action_anim("water")
	player.can_move = false
	var act_time: float = player.get_action_duration("water")
	await main.get_tree().create_timer(act_time).timeout
	if is_instance_valid(player):
		player.can_move = true
	if is_instance_valid(main.hud):
		main.hud.rebuild_hotbar()
		main.hud.toast("Đã múc nước từ ao (-2⚡)! Bình tưới: %d/%d 💧" % [Inventory.water_level, Inventory.water_max], Color(0.4, 0.85, 1.0))


func spawn_water_ripple(pos: Vector2, r_scale: float = 1.0, r_dur: float = 0.7) -> Sprite2D:
	if not is_instance_valid(world):
		return null
	var spr := Sprite2D.new()
	spr.texture = TextureGen.water_ripple_frame(0)
	spr.position = pos
	spr.scale = Vector2(r_scale, r_scale)
	spr.z_index = 2
	world.add_child(spr)
	var tw := spr.create_tween()
	var frame_dur: float = r_dur / 8.0
	for f in range(1, 8):
		var frame_idx := f
		tw.tween_interval(frame_dur)
		tw.tween_callback(func():
			if is_instance_valid(spr):
				spr.texture = TextureGen.water_ripple_frame(frame_idx)
		)
	tw.tween_property(spr, "modulate:a", 0.0, frame_dur)
	tw.tween_callback(func():
		if is_instance_valid(spr):
			spr.queue_free()
	)
	return spr


func start_fishing() -> void:
	if fishing:
		return
	var fish_stamina: float = 15.0
	if main.has_method("_get_action_stamina_cost"):
		fish_stamina = main._get_action_stamina_cost("fish")
	if GameState.stamina < fish_stamina:
		if is_instance_valid(main.hud):
			main.hud.toast("Bạn đã kiệt sức! Không đủ sức câu cá (cần %d⚡). Hãy ăn nông sản hoặc thịt!" % int(fish_stamina), Color(1.0, 0.45, 0.35))
		return
	var tier := str(Inventory.take_cast())
	if tier == "":
		if is_instance_valid(main.hud):
			main.hud.toast("Hết lượt câu! Mua cần câu ở Chú Hai (bờ ao).", Color(1.0, 0.6, 0.5))
		return
	GameState.use_stamina(fish_stamina)
	var rod := FishDB.get_rod(tier)
	fishing = true
	main.fishing = true
	var fish_time: float = FishDB.FISH_TIME
	if GameState.weather in [WeatherManagerScript.RAIN, WeatherManagerScript.STORM]:
		fish_time = 9.0
	elif GameState.weather == WeatherManagerScript.DRIZZLE:
		fish_time = 12.0
	fishing_left = fish_time
	main.fishing_left = fish_time
	player.can_move = false
	if is_instance_valid(main.hud):
		main.hud.toast("Đã thả câu (%s — còn %d lượt)" % [rod.name, Inventory.total_casts()], Color(0.6, 0.9, 1.0))

	var dir := (POND_RECT.get_center() - player.position).normalized()
	player.facing = dir
	player.start_fishing_anim()

	var pond_center := POND_RECT.get_center()
	var dist_to_center := player.position.distance_to(pond_center)
	var cast_dist: float = clampf(dist_to_center * 0.65, 42.0, 85.0)
	var bobber_target := player.position + dir * cast_dist

	_bobber_spr = Sprite2D.new()
	_bobber_spr.texture = TextureGen.get_tex("fx_bobber")
	_bobber_spr.z_index = 50
	var tip_pos: Vector2 = player.get_rod_tip_position()
	_bobber_spr.position = tip_pos
	world.add_child(_bobber_spr)
	main._bobber_spr = _bobber_spr

	if _fishing_line != null and is_instance_valid(_fishing_line):
		_fishing_line.queue_free()
	_fishing_line = Line2D.new()
	_fishing_line.width = 1.0
	_fishing_line.default_color = Color(0.92, 0.94, 0.98, 0.82)
	_fishing_line.z_index = 49
	_fishing_line.points = PackedVector2Array([tip_pos, (tip_pos + bobber_target) * 0.5, bobber_target])
	world.add_child(_fishing_line)
	main._fishing_line = _fishing_line

	var cast_tw := _bobber_spr.create_tween()
	cast_tw.tween_property(_bobber_spr, "position", bobber_target, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cast_tw.tween_callback(func():
		if is_instance_valid(_bobber_spr):
			spawn_water_ripple(bobber_target, 1.25, 0.8)
			if main.has_method("_spawn_effect"):
				main._spawn_effect("fx_water", bobber_target)
			var bob := _bobber_spr.create_tween().set_loops()
			bob.tween_property(_bobber_spr, "position:y", bobber_target.y - 2.5, 0.55).set_ease(Tween.EASE_OUT)
			bob.tween_property(_bobber_spr, "position:y", bobber_target.y + 0.5, 0.55).set_ease(Tween.EASE_IN)
	)


func finish_fishing() -> void:
	fishing = false
	main.fishing = false
	fishing_left = 0.0
	main.fishing_left = 0.0
	if is_instance_valid(player):
		player.can_move = true
	if main.has_method("_set_current_hint"):
		main._set_current_hint("")
	var bobber_pos := _bobber_spr.position if is_instance_valid(_bobber_spr) else POND_RECT.get_center()
	if _rod_spr != null and is_instance_valid(_rod_spr):
		_rod_spr.queue_free()
		_rod_spr = null
		main._rod_spr = null
	if _fishing_line != null and is_instance_valid(_fishing_line):
		_fishing_line.queue_free()
		_fishing_line = null
		main._fishing_line = null
	if _bobber_spr != null and is_instance_valid(_bobber_spr):
		spawn_water_ripple(bobber_pos, 1.35, 0.65)
		_bobber_spr.queue_free()
		_bobber_spr = null
		main._bobber_spr = null
	if main.has_method("_spawn_effect"):
		main._spawn_effect("fx_water", bobber_pos)
	if is_instance_valid(player):
		player.stop_fishing_anim()
	var night := GameState.clock < GameState.DAY_START or GameState.clock >= 1140
	var f := FishDB.roll_cast(night)
	if f.is_empty():
		if is_instance_valid(main.hud):
			main.hud.toast("Kéo cần lên... không con cá nào cắn!", Color(0.8, 0.8, 0.8))
		return
	var fid := str(f.id)
	if not Inventory.can_hold("fish", fid):
		if is_instance_valid(main.hud):
			main.hud.toast("Túi đồ đã đầy! Không thể giữ %s... Hãy cất bớt đồ vào nhà kho 🏚️" % f.name, Color(1.0, 0.5, 0.4))
		return
	Inventory.add_fish(fid, 1)
	if main.quest_mgr != null:
		main.quest_mgr.advance_progress("fish", fid, 1)
	if is_instance_valid(main.hud):
		if str(f.tier) == "legend":
			main.hud.toast("HUYỀN THOẠI! Bắt được %s!!!" % f.name, Color(1.0, 0.85, 0.3))
		elif str(f.tier) == "rare":
			main.hud.toast("Bắt được cá hiếm: %s!" % f.name, Color(0.6, 1.0, 0.9))
		else:
			main.hud.toast("Bắt được %s! Bán cho Chú Hai." % f.name)


func process(delta: float) -> void:
	# Gợn sóng nước hồ tự nhiên phong cách Stardew Valley
	if not main.in_mine:
		_lake_ripple_timer -= delta
		if _lake_ripple_timer <= 0.0:
			_lake_ripple_timer = randf_range(1.5, 2.5)
			var r_angle := randf() * TAU
			var r_dist := sqrt(randf())
			var rx := 1440.0 + cos(r_angle) * (r_dist * 115.0)
			var ry := 900.0 + sin(r_angle) * (r_dist * 75.0)
			if ry >= 820.0 and ry <= 990.0:
				spawn_water_ripple(Vector2(rx, ry), randf_range(0.85, 1.15), randf_range(0.7, 0.9))

	if fishing:
		fishing_left -= delta
		main.fishing_left = fishing_left
		if fishing_left <= 0.0:
			finish_fishing()
		else:
			if main.has_method("_set_current_hint"):
				main._set_current_hint("Đang thả câu... còn %d giây" % int(ceil(maxf(fishing_left, 0.0))))
		if is_instance_valid(main.highlight):
			main.highlight.visible = false
		if is_instance_valid(_fishing_line) and is_instance_valid(_bobber_spr) and is_instance_valid(player):
			var tip: Vector2 = player.get_rod_tip_position()
			var bpos: Vector2 = _bobber_spr.position
			var mid: Vector2 = (tip + bpos) * 0.5 + Vector2(0, 4.0)
			_fishing_line.points = PackedVector2Array([tip, mid, bpos])
		_bobber_ripple_timer -= delta
		if _bobber_ripple_timer <= 0.0:
			_bobber_ripple_timer = 0.85
			if is_instance_valid(_bobber_spr):
				spawn_water_ripple(_bobber_spr.position, 0.75, 0.7)
