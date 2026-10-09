extends RefCounted
# Quản lý Chăn Nuôi & Khu Chuồng Trại (Livestock & Pen Manager)

const TextureGen := preload("res://scripts/texture_gen.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const PenAnimal := preload("res://scripts/pen_animal.gd")

const PEN_COW := Rect2(256, 544, 224, 128)      # Chuồng Bò (Tây Bắc)
const PEN_CHICKEN := Rect2(528, 544, 224, 128)  # Chuồng Gà (Đông Bắc)
const PEN_SHEEP := Rect2(256, 720, 224, 128)    # Chuồng Cừu (Tây Nam)
const PEN_PIG := Rect2(528, 720, 224, 128)      # Chuồng Lợn (Đông Nam)
const PEN_RECT := PEN_CHICKEN                    # fallback tham chiếu cũ

const PATH_COBBLE_V := Rect2(480, 480, 48, 384)  # đường dọc nối từ đại lộ xuống đáy 4 chuồng
const PATH_COBBLE_H := Rect2(240, 672, 528, 48)  # đường ngang phân cách tầng chuồng trên và dưới

const PENS_CONFIG := [
	{
		"id": "cow",
		"name": "Chuồng Bò",
		"rect": PEN_COW,
		"gate_axis": "south",
		"bldg_pos": Vector2(310, 584),
		"bldg_type": "barn",
	},
	{
		"id": "chicken",
		"name": "Chuồng Gà",
		"rect": PEN_CHICKEN,
		"gate_axis": "south",
		"bldg_pos": Vector2(582, 584),
		"bldg_type": "coop",
	},
	{
		"id": "sheep",
		"name": "Chuồng Cừu",
		"rect": PEN_SHEEP,
		"gate_axis": "north",
		"bldg_pos": Vector2(310, 760),
		"bldg_type": "barn",
	},
	{
		"id": "pig",
		"name": "Chuồng Lợn",
		"rect": PEN_PIG,
		"gate_axis": "north",
		"bldg_pos": Vector2(582, 760),
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

		if gate_axis == "south":
			for x in range(int(rx) + 16, int(rx + rw), 32):
				_add_sprite(fh, Vector2(x, ry), pen_node)
			_wall(Vector2(rx + rw / 2.0, ry + 4), Vector2(rw, 8), pen_node)

			for x in [rx + 16, rx + 48, rx + 80]:
				_add_sprite(fh, Vector2(x, ry + rh), pen_node)
			_add_sprite(f_gate, Vector2(rx + 112, ry + rh), pen_node)
			for x in [rx + 144, rx + 176, rx + 208]:
				_add_sprite(fh, Vector2(x, ry + rh), pen_node)
			_wall(Vector2(rx + 48, ry + rh + 4), Vector2(96, 8), pen_node)
			_wall(Vector2(rx + 176, ry + rh + 4), Vector2(96, 8), pen_node)
		else:
			for x in range(int(rx) + 16, int(rx + rw), 32):
				_add_sprite(fh, Vector2(x, ry + rh), pen_node)
			_wall(Vector2(rx + rw / 2.0, ry + rh + 4), Vector2(rw, 8), pen_node)

			for x in [rx + 16, rx + 48, rx + 80]:
				_add_sprite(fh, Vector2(x, ry), pen_node)
			_add_sprite(f_gate, Vector2(rx + 112, ry), pen_node)
			for x in [rx + 144, rx + 176, rx + 208]:
				_add_sprite(fh, Vector2(x, ry), pen_node)
			_wall(Vector2(rx + 48, ry + 4), Vector2(96, 8), pen_node)
			_wall(Vector2(rx + 176, ry + 4), Vector2(96, 8), pen_node)

		# 3. Công trình chuồng trại và cơ sở vật chất
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
			var b_scale := Vector2(0.70, 0.70) if tier >= 2 else Vector2(0.65, 0.65)
			bldg_spr.scale = b_scale
			bldg_body.add_child(bldg_spr)

			var bcol := CollisionShape2D.new()
			var bshape := RectangleShape2D.new()
			bshape.size = Vector2(56 * b_scale.x / 0.65, 30 * b_scale.y / 0.65)
			bcol.shape = bshape
			bcol.position = Vector2(0, 10)
			bldg_body.add_child(bcol)
			pen_node.add_child(bldg_body)

			_add_sprite(TextureGen.get_tex("trough"), Vector2(rx + 126, ry + 38), pen_node, Vector2(1.65, 1.65))
			_add_sprite(TextureGen.get_tex("water_trough"), Vector2(rx + 126, ry + 62), pen_node, Vector2(1.65, 1.65))
			_add_sprite(TextureGen.get_tex("hay_bale"), Vector2(rx + 190, ry + 40), pen_node)

			if is_coop:
				_add_sprite(TextureGen.get_tex("nest_box"), Vector2(rx + 190, ry + 60), pen_node)

			if tier >= 2:
				_add_sprite(TextureGen.get_tex("hay_bale"), Vector2(rx + 168, ry + 40), pen_node)

		# 4. Các con vật thuộc loài này di chuyển và ăn trong chuồng
		var species_animals: Array = []
		for a in Inventory.animals:
			if PoultryDB.get_canonical_id(str(a.id)) == sid:
				species_animals.append(a)

		var anim_spots := [
			Vector2(rx + 56, ry + 88),
			Vector2(rx + 112, ry + 88),
			Vector2(rx + 168, ry + 88),
			Vector2(rx + 84, ry + 104),
			Vector2(rx + 140, ry + 104),
			Vector2(rx + 60, ry + 68),
		]

		var d := PoultryDB.get_animal(sid)
		for idx in species_animals.size():
			var a: Dictionary = species_animals[idx]
			var spot: Vector2 = anim_spots[idx % anim_spots.size()] + Vector2(rng.randf_range(-5, 5), rng.randf_range(-3, 3))
			var animal_node := PenAnimal.new()
			animal_node.position = spot
			animal_node.setup(sid, a, idx, r, Vector2(rx + 126, ry + 38))
			pen_node.add_child(animal_node)
			active_pen_animals.append(animal_node)

		# 5. Biểu tượng thu hoạch nổi
		var pen_bubble := Sprite2D.new()
		pen_bubble.texture = TextureGen.get_harvest_bubble(str(d.product))
		pen_bubble.scale = Vector2(1.35, 1.35)
		var base_by: float = ry + 22.0
		pen_bubble.position = Vector2(rx + 112, base_by)
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
			main.hud.toast("Đã cho %s ăn 1 Túi Cám! Đang đi tới máng ăn 🌾 (Cám còn: ×%d)" % [anim.get_animal_name(), Inventory.feed_count()], Color(1.0, 0.92, 0.45))


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
