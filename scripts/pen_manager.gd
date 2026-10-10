extends RefCounted
# Quản lý Chăn Nuôi & Khu Chuồng Trại (Livestock & Pen Manager)

const TextureGen := preload("res://scripts/texture_gen.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const PenAnimal := preload("res://scripts/pen_animal.gd")

const PEN_COW := Rect2(144, 528, 288, 160)      # Chuồng Bò (Tây Bắc)
const PEN_CHICKEN := Rect2(480, 528, 288, 160)  # Chuồng Gà (Đông Bắc)
const PEN_SHEEP := Rect2(144, 736, 288, 160)    # Chuồng Cừu (Tây Nam)
const PEN_PIG := Rect2(480, 736, 288, 160)      # Chuồng Lợn (Đông Nam)
const PEN_RECT := PEN_CHICKEN                    # fallback tham chiếu cũ

const PATH_COBBLE_V := Rect2(432, 480, 48, 440)  # đường dọc nối từ đại lộ xuống đáy 4 chuồng
const PATH_COBBLE_H := Rect2(144, 688, 624, 48)  # đường ngang phân cách tầng chuồng trên và dưới

const PENS_CONFIG := [
	{
		"id": "cow",
		"name": "Chuồng Bò",
		"rect": PEN_COW,
		"gate_axis": "south",
		"bldg_pos": Vector2(208, 584),
		"bldg_type": "barn",
	},
	{
		"id": "chicken",
		"name": "Chuồng Gà",
		"rect": PEN_CHICKEN,
		"gate_axis": "south",
		"bldg_pos": Vector2(544, 584),
		"bldg_type": "coop",
	},
	{
		"id": "sheep",
		"name": "Chuồng Cừu",
		"rect": PEN_SHEEP,
		"gate_axis": "north",
		"bldg_pos": Vector2(208, 840),
		"bldg_type": "barn",
	},
	{
		"id": "pig",
		"name": "Chuồng Lợn",
		"rect": PEN_PIG,
		"gate_axis": "north",
		"bldg_pos": Vector2(544, 840),
		"bldg_type": "barn",
	},
]

var main: Node2D
var pen_node: Node2D
var active_pen_animals: Array = []
var pen_bubbles: Dictionary = {}


func setup(p_main: Node2D) -> void:
	main = p_main


func build_pen(parent: Node2D) -> Node2D:
	pen_node = Node2D.new()
	pen_node.name = "Pen"
	pen_node.position = Vector2.ZERO
	parent.add_child(pen_node)
	rebuild_pen()
	return pen_node


func rebuild_pen() -> void:
	if pen_node == null:
		return
	active_pen_animals.clear()
	pen_bubbles.clear()
	for c in pen_node.get_children():
		c.queue_free()

	var fh := TextureGen.get_tex("fence_h")
	var fv := TextureGen.get_tex("fence_v")
	var f_tl := TextureGen.get_tex("fence_corner_tl")
	var f_tr := TextureGen.get_tex("fence_corner_tr")
	var f_bl := TextureGen.get_tex("fence_corner_bl")
	var f_br := TextureGen.get_tex("fence_corner_br")
	var f_gate := TextureGen.get_tex("gate_coop")

	var rng := RandomNumberGenerator.new()
	rng.seed = 2026

	for pcfg in PENS_CONFIG:
		var sid: String = str(pcfg.id)
		var r: Rect2 = pcfg.rect
		var rx: float = r.position.x
		var ry: float = r.position.y
		var rw: float = r.size.x
		var rh: float = r.size.y
		var tier: int = Inventory.get_coop_tier(sid)
		var gate_axis: String = str(pcfg.gate_axis)

		# 1. Mặt sàn chuồng
		var bedding := Sprite2D.new()
		bedding.texture = TextureGen.get_tex("pen_dirt_bedding" if tier == 0 else "pen_bedding")
		bedding.position = Vector2(rx + rw / 2.0, ry + rh / 2.0)
		bedding.z_index = -1
		pen_node.add_child(bedding)

		# 2. Hàng rào gỗ ngoại vi bao quanh chuồng & Cổng chuồng
		_add_sprite(f_tl, Vector2(rx, ry), pen_node)
		_add_sprite(f_tr, Vector2(rx + rw, ry), pen_node)
		_add_sprite(f_bl, Vector2(rx, ry + rh), pen_node)
		_add_sprite(f_br, Vector2(rx + rw, ry + rh), pen_node)

		for y in range(int(ry) + 16, int(ry + rh), 32):
			_add_sprite(fv, Vector2(rx, y), pen_node)
			_add_sprite(fv, Vector2(rx + rw, y), pen_node)
		_wall(Vector2(rx + 4, ry + rh / 2.0), Vector2(8, rh), pen_node)
		_wall(Vector2(rx + rw - 4, ry + rh / 2.0), Vector2(8, rh), pen_node)

		var mid_x := rx + rw / 2.0
		if gate_axis == "south":
			for x in range(int(rx) + 16, int(rx + rw), 32):
				_add_sprite(fh, Vector2(x, ry), pen_node)
			_wall(Vector2(mid_x, ry + 4), Vector2(rw, 8), pen_node)

			# Hàng rào dưới có cổng ở giữa
			for x in range(int(rx) + 16, int(mid_x - 16), 32):
				_add_sprite(fh, Vector2(x, ry + rh), pen_node)
			_add_sprite(f_gate, Vector2(mid_x, ry + rh), pen_node)
			for x in range(int(mid_x + 32), int(rx + rw), 32):
				_add_sprite(fh, Vector2(x, ry + rh), pen_node)
			var wing_w: float = (rw - 32.0) / 2.0
			_wall(Vector2(rx + wing_w / 2.0, ry + rh + 4), Vector2(wing_w, 8), pen_node)
			_wall(Vector2(rx + rw - wing_w / 2.0, ry + rh + 4), Vector2(wing_w, 8), pen_node)
		else:
			for x in range(int(rx) + 16, int(rx + rw), 32):
				_add_sprite(fh, Vector2(x, ry + rh), pen_node)
			_wall(Vector2(mid_x, ry + rh + 4), Vector2(rw, 8), pen_node)

			# Hàng rào trên có cổng ở giữa
			for x in range(int(rx) + 16, int(mid_x - 16), 32):
				_add_sprite(fh, Vector2(x, ry), pen_node)
			_add_sprite(f_gate, Vector2(mid_x, ry), pen_node)
			for x in range(int(mid_x + 32), int(rx + rw), 32):
				_add_sprite(fh, Vector2(x, ry), pen_node)
			var wing_w: float = (rw - 32.0) / 2.0
			_wall(Vector2(rx + wing_w / 2.0, ry + 4), Vector2(wing_w, 8), pen_node)
			_wall(Vector2(rx + rw - wing_w / 2.0, ry + 4), Vector2(wing_w, 8), pen_node)

		# 3. Công trình chuồng trại và cơ sở vật chất
		var trough_pos := Vector2(rx + 150, ry + 40)
		if tier >= 1:
			var bldg_body := StaticBody2D.new()
			var bpos: Vector2 = pcfg.bldg_pos
			bldg_body.position = bpos
			var bldg_spr := Sprite2D.new()
			var is_coop := (str(pcfg.bldg_type) == "coop")
			var btex_key := ""
			if is_coop:
				btex_key = "coop_tier2" if tier >= 2 else "coop_tier1"
			else:
				btex_key = "barn_tier2" if tier >= 2 else "barn_tier1"
			bldg_spr.texture = TextureGen.get_tex(btex_key)
			var b_scale := Vector2(0.65, 0.65)
			if tier == 2:
				b_scale = Vector2(0.70, 0.70)
			elif tier == 3:
				b_scale = Vector2(0.74, 0.74)
			elif tier >= 4:
				b_scale = Vector2(0.78, 0.78)
			bldg_spr.scale = b_scale
			bldg_body.add_child(bldg_spr)

			var bcol := CollisionShape2D.new()
			var bshape := RectangleShape2D.new()
			bshape.size = Vector2(56 * b_scale.x / 0.65, 30 * b_scale.y / 0.65)
			bcol.shape = bshape
			bcol.position = Vector2(0, 10)
			bldg_body.add_child(bcol)
			pen_node.add_child(bldg_body)

			var trough_y: float = ry + 36.0 if gate_axis == "south" else ry + 95.0
			trough_pos = Vector2(rx + 150, trough_y)
			_add_sprite(TextureGen.get_tex("trough"), Vector2(rx + 150, trough_y), pen_node, Vector2(1.65, 1.65))
			_add_sprite(TextureGen.get_tex("water_trough"), Vector2(rx + 150, trough_y + 26), pen_node, Vector2(1.65, 1.65))
			_add_sprite(TextureGen.get_tex("hay_bale"), Vector2(rx + 224, trough_y), pen_node)

			if is_coop:
				_add_sprite(TextureGen.get_tex("nest_box"), Vector2(rx + 224, trough_y + 24), pen_node)

			if tier >= 2:
				_add_sprite(TextureGen.get_tex("hay_bale"), Vector2(rx + 252, trough_y), pen_node)
			if tier >= 3:
				_add_sprite(TextureGen.get_tex("hay_bale"), Vector2(rx + 224, trough_y - 20 if gate_axis == "south" else trough_y + 20), pen_node)
			if tier >= 4:
				_add_sprite(TextureGen.get_tex("hay_bale"), Vector2(rx + 252, trough_y - 20 if gate_axis == "south" else trough_y + 20), pen_node)

		# 4. Các con vật thuộc loài này di chuyển và ăn trong chuồng
		var species_animals: Array = []
		for a in Inventory.animals:
			if PoultryDB.get_canonical_id(str(a.id)) == sid:
				species_animals.append(a)

		var anim_spots: Array = []
		if gate_axis == "south":
			anim_spots = [
				Vector2(rx + 50, ry + 95),
				Vector2(rx + 90, ry + 95),
				Vector2(rx + 130, ry + 95),
				Vector2(rx + 170, ry + 95),
				Vector2(rx + 210, ry + 95),
				Vector2(rx + 250, ry + 95),
				Vector2(rx + 60, ry + 125),
				Vector2(rx + 100, ry + 125),
				Vector2(rx + 140, ry + 125),
				Vector2(rx + 180, ry + 125),
				Vector2(rx + 220, ry + 125),
				Vector2(rx + 250, ry + 125),
				Vector2(rx + 50, ry + 65),
				Vector2(rx + 90, ry + 65),
				Vector2(rx + 210, ry + 65),
				Vector2(rx + 250, ry + 65),
			]
		else:
			anim_spots = [
				Vector2(rx + 50, ry + 45),
				Vector2(rx + 90, ry + 45),
				Vector2(rx + 130, ry + 45),
				Vector2(rx + 170, ry + 45),
				Vector2(rx + 210, ry + 45),
				Vector2(rx + 250, ry + 45),
				Vector2(rx + 60, ry + 75),
				Vector2(rx + 100, ry + 75),
				Vector2(rx + 140, ry + 75),
				Vector2(rx + 180, ry + 75),
				Vector2(rx + 220, ry + 75),
				Vector2(rx + 250, ry + 75),
				Vector2(rx + 50, ry + 105),
				Vector2(rx + 90, ry + 105),
				Vector2(rx + 210, ry + 105),
				Vector2(rx + 250, ry + 105),
			]

		var d := PoultryDB.get_animal(sid)
		for idx in species_animals.size():
			var a: Dictionary = species_animals[idx]
			var spot: Vector2 = anim_spots[idx % anim_spots.size()] + Vector2(rng.randf_range(-5, 5), rng.randf_range(-3, 3))
			var animal_node := PenAnimal.new()
			animal_node.position = spot
			animal_node.setup(sid, a, idx, r, trough_pos)
			pen_node.add_child(animal_node)
			active_pen_animals.append(animal_node)

		# 5. Biểu tượng thu hoạch nổi
		var pprod := str(d.get("product", ""))
		if pprod != "":
			var pen_bubble := Sprite2D.new()
			pen_bubble.texture = TextureGen.get_harvest_bubble(pprod)
			pen_bubble.scale = Vector2(1.35, 1.35)
			var base_by: float = ry + 22.0
			pen_bubble.position = Vector2(mid_x, base_by)
			pen_bubble.visible = (Inventory.ready_products_for_species(sid) > 0)
			pen_node.add_child(pen_bubble)
			pen_bubbles[sid] = pen_bubble

			var ptw := pen_bubble.create_tween().set_loops()
			ptw.tween_property(pen_bubble, "position:y", base_by - 4.0, 0.6).set_trans(Tween.TRANS_SINE)
			ptw.tween_property(pen_bubble, "position:y", base_by, 0.6).set_trans(Tween.TRANS_SINE)


func update_pen_bubbles() -> void:
	for sid in pen_bubbles:
		var pb: Sprite2D = pen_bubbles[sid]
		if is_instance_valid(pb):
			pb.visible = (Inventory.ready_products_for_species(sid) > 0)


func collect_pen_products(species_id: String) -> void:
	var n: int = Inventory.collect_products_for_species(species_id)
	if n > 0:
		var d := PoultryDB.get_animal(species_id)
		var pname := str(d.get("product_name", "sản phẩm"))
		if is_instance_valid(main.hud):
			main.hud.toast("Đã thu hoạch %d %s! 🧺" % [n, pname], Color(1.0, 0.88, 0.55))
		if main.quest_mgr != null:
			main.quest_mgr.advance_progress("poultry", "any", n)
			main.quest_mgr.advance_progress("poultry", str(d.get("product", "")), n)
		return
	var all_n: int = Inventory.collect_products()
	if all_n > 0:
		if is_instance_valid(main.hud):
			main.hud.toast("Đã thu %d sản phẩm chăn nuôi! 🧺" % all_n, Color(1.0, 0.75, 0.5))
		if main.quest_mgr != null:
			main.quest_mgr.advance_progress("poultry", "any", all_n)
		return
	if Inventory.ready_products() > 0:
		if is_instance_valid(main.hud):
			main.hud.toast("Túi đồ đã đầy (%d/%d)! Vui lòng cất bớt đồ vào nhà kho 🏚️ để thu hoạch." % [Inventory.backpack_slots_used(), Inventory.backpack_max], Color(1.0, 0.65, 0.4))
		return
	var c := PoultryDB.get_coop_data(species_id)
	var cname := str(c.get("name", "Chuồng"))
	var tier := Inventory.get_coop_tier(species_id)
	if tier == 0:
		if is_instance_valid(main.hud):
			main.hud.toast("%s chưa được xây! Hãy ghé tiệm Cô Tư để mua." % cname, Color(0.9, 0.75, 0.6))
	elif Inventory.animals_of_species(species_id) == 0:
		if is_instance_valid(main.hud):
			main.hud.toast("%s đang trống! Hãy mua con giống tại tiệm Cô Tư." % cname, Color(0.9, 0.8, 0.6))
	else:
		if is_instance_valid(main.hud):
			main.hud.toast("%s chưa có sản phẩm nào để thu hoạch!" % cname, Color(0.9, 0.7, 0.6))


func collect_products() -> void:
	var n: int = Inventory.collect_products()
	if n > 0:
		if is_instance_valid(main.hud):
			main.hud.toast("Đã thu %d sản phẩm chăn nuôi! Bán cho Cô Tư." % n, Color(1.0, 0.75, 0.5))
		if main.quest_mgr != null:
			main.quest_mgr.advance_progress("poultry", "any", n)
			main.quest_mgr.advance_progress("poultry", "trung_ga", n)
	elif Inventory.ready_products() > 0:
		if is_instance_valid(main.hud):
			main.hud.toast("Túi đồ đã đầy (%d/%d)! Vui lòng cất bớt đồ vào nhà kho 🏚️ để thu hoạch." % [Inventory.backpack_slots_used(), Inventory.backpack_max], Color(1.0, 0.65, 0.4))
	else:
		if is_instance_valid(main.hud):
			main.hud.toast("Chưa có sản phẩm nào chờ thu...", Color(0.8, 0.8, 0.8))


func interact_pen(species_id: String) -> void:
	var r_count := Inventory.ready_products_for_species(species_id)
	if r_count > 0:
		collect_pen_products(species_id)
		return
	var hungry_count := Inventory.hungry_animals_for_species(species_id)
	if hungry_count > 0:
		if Inventory.feed_count() > 0:
			var fed := Inventory.feed_all_hungry_for_species(species_id)
			if fed > 0:
				var c := PoultryDB.get_coop_data(species_id)
				if is_instance_valid(main.hud):
					main.hud.toast("Đã cho %d con ở %s ăn 🌾! Chúng đang tiến tới máng ăn." % [fed, c.get("name", "Chuồng")], Color(1.0, 0.9, 0.4))
				for anim in active_pen_animals:
					if is_instance_valid(anim) and anim.species_id == species_id and anim.is_fed() and anim.state != PenAnimal.State.EATING:
						anim.target_pos = anim.get_trough_eating_spot()
						anim.state = PenAnimal.State.WALK_TO_TROUGH
						anim._play_heart_effect()
		else:
			if is_instance_valid(main.hud):
				main.hud.toast("Bạn cần mua Túi Cám ở Cửa Hàng Cô Tư để cho ăn!", Color(1.0, 0.65, 0.4))
		return
	collect_pen_products(species_id)


func harvest_single_animal(anim: PenAnimal) -> void:
	if not is_instance_valid(anim):
		return
	var was_ready: bool = anim.is_ready()
	var prod_id := anim.harvest()
	if prod_id != "":
		var d := PoultryDB.get_animal(anim.species_id)
		var pname := str(d.get("product_name", "sản phẩm"))
		if is_instance_valid(main.hud):
			main.hud.toast("Đã thu hoạch 1 %s từ %s! 🧺 (Có thể cho ăn tiếp ngay)" % [pname, anim.get_animal_name()], Color(1.0, 0.92, 0.55))
		if main.quest_mgr != null:
			main.quest_mgr.advance_progress("poultry", "any", 1)
			main.quest_mgr.advance_progress("poultry", prod_id, 1)
	elif was_ready:
		if is_instance_valid(main.hud):
			main.hud.toast("Túi đồ đã đầy (%d/%d)! Vui lòng cất bớt đồ vào nhà kho 🏚️ để thu hoạch." % [Inventory.backpack_slots_used(), Inventory.backpack_max], Color(1.0, 0.65, 0.4))


func feed_single_animal(anim: PenAnimal) -> void:
	if not is_instance_valid(anim):
		return
	if Inventory.feed_count() <= 0:
		if is_instance_valid(main.hud):
			main.hud.toast("Bạn cần mua Túi Cám ở Cửa Hàng để cho ăn!", Color(1.0, 0.65, 0.4))
		return
	if anim.feed():
		if is_instance_valid(main.hud):
			main.hud.toast("Đã cho %s ăn 1 Túi Cám! Đang đi tới máng ăn 🌾 (Cám còn: ×%d · Lần %d/5)" % [anim.get_animal_name(), Inventory.feed_count(), anim.get_times_fed()], Color(1.0, 0.92, 0.45))


func slaughter_single_animal(anim: PenAnimal) -> void:
	if not is_instance_valid(anim):
		return
	var res := Inventory.slaughter_animal(anim.animal_data)
	if not bool(res.get("ok", false)):
		if is_instance_valid(main.hud):
			main.hud.toast(str(res.get("msg", "Không thể lấy thịt!")), Color(1.0, 0.65, 0.4))
		return

	var meat_id: String = str(res.meat_id)
	var meat_qty: int = int(res.qty)
	var pinfo := PoultryDB.get_product_info(meat_id)
	var mname: String = str(pinfo.get("name", "Thịt"))

	# Động tác chém của người chơi
	if is_instance_valid(main.player):
		if main.farming_controller != null:
			main.farming_controller.face_towards(anim.position)
		main.player.play_action_anim("till")

	# Hiệu ứng chém / slash effect tại vị trí con vật
	_play_slash_effect(anim.position)

	# Hiệu ứng tung các icon thịt ra mặt đất
	_spawn_meat_burst_drops(anim.position, meat_id, meat_qty)

	if is_instance_valid(main.hud):
		main.hud.toast("Đã chém lấy %d %s! 🥩" % [meat_qty, mname], Color(1.0, 0.9, 0.45))

	if main.quest_mgr != null:
		main.quest_mgr.advance_progress("meat", "any", meat_qty)
		main.quest_mgr.advance_progress("meat", meat_id, meat_qty)
		main.quest_mgr.advance_progress("poultry", meat_id, meat_qty)

	active_pen_animals.erase(anim)
	anim.queue_free()
	update_pen_bubbles()


func _spawn_meat_burst_drops(pos: Vector2, meat_id: String, qty: int) -> void:
	if main == null or main.world == null:
		return
	var tex: Texture2D = TextureGen.get_product_icon(meat_id)
	if tex == null:
		return

	for i in range(qty):
		var drop := Node2D.new()
		drop.position = pos
		drop.z_index = 6
		main.world.add_child(drop)

		# Bóng đổ nhỏ dưới mặt đất
		var shadow := Sprite2D.new()
		shadow.texture = TextureGen.shadow_tex()
		shadow.scale = Vector2(0.55, 0.38)
		shadow.modulate = Color(0, 0, 0, 0.45)
		drop.add_child(shadow)

		# Sprite miếng thịt Stardew Valley
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.scale = Vector2(1.2, 1.2)
		drop.add_child(spr)

		# Văng ra các góc ngẫu nhiên xung quanh con vật
		var angle: float = randf() * TAU
		var dist: float = randf_range(22.0, 68.0)
		var target_pos: Vector2 = pos + Vector2(cos(angle), sin(angle)) * dist
		var arc_h: float = randf_range(26.0, 48.0)
		var burst_dur: float = randf_range(0.38, 0.52)

		# Hiệu ứng bay bổng theo quỹ đạo cầu vồng (parabolic arc)
		var tw_pos := drop.create_tween()
		tw_pos.tween_property(drop, "position:x", target_pos.x, burst_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_pos.parallel().tween_property(drop, "position:y", target_pos.y, burst_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Độ cao nảy lên rồi rơi xuống đất
		var tw_h := spr.create_tween()
		tw_h.tween_property(spr, "position:y", -arc_h, burst_dur * 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_h.tween_property(spr, "position:y", 0.0, burst_dur * 0.58).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

		# Xoay nhẹ tự nhiên
		var tw_rot := spr.create_tween()
		tw_rot.tween_property(spr, "rotation", randf_range(-0.6, 0.6), burst_dur)

		# Nằm yên trên mặt đất để người chơi nhìn thấy thịt vương vãi
		var stay_time: float = randf_range(0.45, 0.75)
		var tw_collect := drop.create_tween()
		tw_collect.tween_interval(burst_dur + stay_time)

		# Sau đó bay hút vào người chơi
		tw_collect.tween_callback(func():
			if not is_instance_valid(drop):
				return
			if not is_instance_valid(main.player):
				drop.queue_free()
				return
			var fly_tw := drop.create_tween()
			fly_tw.tween_property(drop, "global_position", main.player.global_position, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			fly_tw.parallel().tween_property(drop, "scale", Vector2(0.4, 0.4), 0.26)
			fly_tw.tween_callback(func():
				if is_instance_valid(drop):
					drop.queue_free()
			)
		)


func _play_slash_effect(pos: Vector2) -> void:
	if main == null or main.world == null:
		return
	# 1. Vệt chém sắc bén
	var slash := Sprite2D.new()
	slash.texture = TextureGen.slash_effect_tex()
	slash.position = pos + Vector2(0, -6)
	slash.scale = Vector2(0.6, 0.6)
	slash.rotation = -0.4
	slash.z_index = 10
	main.world.add_child(slash)

	var tw := slash.create_tween()
	tw.tween_property(slash, "scale", Vector2(1.5, 1.5), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(slash, "rotation", 0.4, 0.16)
	tw.parallel().tween_property(slash, "modulate:a", 0.0, 0.22).set_delay(0.08)
	tw.tween_callback(slash.queue_free)

	# 2. Tia hạt bay ra xung quanh
	for i in range(5):
		var p := Sprite2D.new()
		p.texture = TextureGen.star_icon()
		p.position = pos + Vector2(0, -4)
		p.scale = Vector2(0.4, 0.4)
		p.modulate = Color(1.0, 0.35, 0.35, 0.95)
		p.z_index = 11
		main.world.add_child(p)
		var angle := randf() * TAU
		var spd := randf_range(20.0, 40.0)
		var target_offset := Vector2(cos(angle), sin(angle)) * spd
		var ptw := p.create_tween()
		ptw.tween_property(p, "position", p.position + target_offset, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ptw.parallel().tween_property(p, "modulate:a", 0.0, 0.22)
		ptw.tween_callback(p.queue_free)


func _add_sprite(tex: Texture2D, pos: Vector2, parent: Node = null, spr_scale: Vector2 = Vector2.ONE) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.scale = spr_scale
	(parent if parent != null else pen_node).add_child(s)
	return s


func _wall(center: Vector2, size: Vector2, parent: Node = null) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	(parent if parent != null else pen_node).add_child(body)
