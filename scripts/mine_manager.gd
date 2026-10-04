extends Node2D
# Quản lý Hầm Mỏ & Đào Quặng (Mining System)

signal exit_requested
signal floor_changed(new_floor: int)

const TextureGen := preload("res://scripts/texture_gen.gd")
const OreDB := preload("res://scripts/ore_db.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

const TILE := 32
const MINE_TILES := Vector2i(24, 15)  # 768 x 480 px

var current_floor: int = 1
var max_floor_reached: int = 1
var main_game = null
var player: CharacterBody2D = null

var _floor_node: Node2D
var _wall_node: Node2D
var _rocks_node: Node2D
var _ladder_up: Sprite2D
var _ladder_down: Sprite2D
var _mine_hud: CanvasLayer
var _floor_label: Label
var _rocks_data: Array = []  # [{node, type, hits_left, pos_tile}]

const LADDER_UP_TILE := Vector2i(3, 3)
const LADDER_DOWN_TILE := Vector2i(20, 11)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	y_sort_enabled = true
	visible = false
	_build_mine_environment()
	_build_mine_hud()


func setup(main_ref, player_ref: CharacterBody2D) -> void:
	main_game = main_ref
	player = player_ref


func enter_mine(floor_num: int = 1) -> void:
	current_floor = floor_num
	if current_floor > max_floor_reached:
		max_floor_reached = current_floor
	process_mode = Node.PROCESS_MODE_PAUSABLE
	visible = true
	_update_hud()
	_generate_floor(current_floor)
	if player != null:
		player.position = Vector2(LADDER_UP_TILE.x * TILE + 16, LADDER_UP_TILE.y * TILE + 28)
	if _mine_hud != null:
		_mine_hud.visible = true


func leave_mine() -> void:
	if _mine_hud != null:
		_mine_hud.visible = false
	exit_requested.emit()


func _build_mine_environment() -> void:
	# Nền tối vô tận bao quanh hầm mỏ chống lộ màu cỏ xanh
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.05)
	bg.position = Vector2(-2000, -2000)
	bg.size = Vector2(5000, 5000)
	bg.z_index = -10
	add_child(bg)

	_floor_node = Node2D.new()
	_floor_node.name = "MineFloor"
	_floor_node.z_index = -1
	add_child(_floor_node)

	_wall_node = Node2D.new()
	_wall_node.name = "MineWalls"
	add_child(_wall_node)

	_rocks_node = Node2D.new()
	_rocks_node.name = "MineRocks"
	_rocks_node.y_sort_enabled = true
	add_child(_rocks_node)

	# 1. Gạch nền hầm mỏ
	var f_tex := TextureGen.get_tex("mine_floor")
	for y in MINE_TILES.y:
		for x in MINE_TILES.x:
			var s := Sprite2D.new()
			s.texture = f_tex
			s.position = Vector2(x * TILE + 16, y * TILE + 16)
			_floor_node.add_child(s)

	# 2. Vách đá bao quanh
	var w_tex := TextureGen.get_tex("mine_wall")
	for x in MINE_TILES.x:
		_add_wall_tile(w_tex, Vector2(x * TILE + 16, 16))
		_add_wall_tile(w_tex, Vector2(x * TILE + 16, (MINE_TILES.y - 1) * TILE + 16))
	for y in range(1, MINE_TILES.y - 1):
		_add_wall_tile(w_tex, Vector2(16, y * TILE + 16))
		_add_wall_tile(w_tex, Vector2((MINE_TILES.x - 1) * TILE + 16, y * TILE + 16))

	# 3. Thang lên mặt đất
	_ladder_up = Sprite2D.new()
	_ladder_up.texture = TextureGen.get_tex("mine_ladder_up")
	_ladder_up.position = Vector2(LADDER_UP_TILE.x * TILE + 16, LADDER_UP_TILE.y * TILE + 16)
	add_child(_ladder_up)

	# 4. Thang xuống tầng sâu
	_ladder_down = Sprite2D.new()
	_ladder_down.texture = TextureGen.get_tex("mine_ladder_down")
	_ladder_down.position = Vector2(LADDER_DOWN_TILE.x * TILE + 16, LADDER_DOWN_TILE.y * TILE + 16)
	add_child(_ladder_down)


func _add_wall_tile(tex: Texture2D, pos: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var spr := Sprite2D.new()
	spr.texture = tex
	body.add_child(spr)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE, TILE)
	col.shape = shape
	body.add_child(col)
	_wall_node.add_child(body)


func _build_mine_hud() -> void:
	_mine_hud = CanvasLayer.new()
	_mine_hud.layer = 15
	_mine_hud.visible = false
	add_child(_mine_hud)

	var top_box := CenterContainer.new()
	top_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_box.custom_minimum_size = Vector2(0, 48)
	_mine_hud.add_child(top_box)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.12, 0.10, 0.08, 0.92), UIKit.COLOR_BORDER_GOLD, 8))
	top_box.add_child(panel)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 6)
	m.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(m)

	_floor_label = UIKit.label(m, "⛏️ HẦM MỎ — TẦNG 1", 16, UIKit.COLOR_TEXT_GOLD)


func _update_hud() -> void:
	if _floor_label != null:
		_floor_label.text = "⛏️ HẦM MỎ — TẦNG %d" % current_floor


# Sinh ngẫu nhiên các tảng đá & quặng theo độ sâu tầng mỏ
func _generate_floor(floor_num: int) -> void:
	for child in _rocks_node.get_children():
		child.queue_free()
	_rocks_data.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = floor_num * 997 + (GameState.day if GameState else 1) * 31

	var rock_count := rng.randi_range(16, 24)
	var occupied: Array[Vector2i] = [LADDER_UP_TILE, LADDER_DOWN_TILE]
	occupied.append(LADDER_UP_TILE + Vector2i(0, 1))
	occupied.append(LADDER_DOWN_TILE + Vector2i(0, -1))

	for _i in rock_count:
		var rx := rng.randi_range(2, MINE_TILES.x - 3)
		var ry := rng.randi_range(2, MINE_TILES.y - 3)
		var pt := Vector2i(rx, ry)
		if occupied.has(pt):
			continue
		occupied.append(pt)

		var ore_type := "stone"
		var roll := rng.randf()
		if floor_num >= 8 and roll < 0.08:
			ore_type = "diamond"
		elif floor_num >= 6 and roll < 0.22:
			ore_type = "gold_ore"
		elif floor_num >= 4 and roll < 0.12:
			ore_type = "ruby"
		elif floor_num >= 3 and roll < 0.35:
			ore_type = "iron_ore"
		elif roll < 0.40:
			ore_type = "copper_ore"
		elif roll < 0.60:
			ore_type = "coal"
		else:
			ore_type = "stone"

		var ore_info := OreDB.get_ore(ore_type)
		var hits: int = int(ore_info.get("hits", 2))

		var rock_body := StaticBody2D.new()
		rock_body.position = Vector2(pt.x * TILE + 16, pt.y * TILE + 16)

		var spr := Sprite2D.new()
		spr.texture = TextureGen.mine_rock_tex(ore_type)
		spr.offset = Vector2(0, -4)
		rock_body.add_child(spr)

		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 8.0
		col.shape = shape
		rock_body.add_child(col)

		_rocks_node.add_child(rock_body)
		_rocks_data.append({
			"body": rock_body,
			"spr": spr,
			"type": ore_type,
			"hits_left": hits,
			"pos_tile": pt
		})


# Tìm tương tác khi người chơi đang trong hầm mỏ
func get_interactable_near(p_pos: Vector2) -> Dictionary:
	# 1. Thang lên
	var up_pos := _ladder_up.position
	if p_pos.distance_to(up_pos) < 36.0:
		return {
			"pos": up_pos,
			"r": 36.0,
			"label": "Lên mặt đất 🌄",
			"cb": leave_mine
		}

	# 2. Thang xuống
	var down_pos := _ladder_down.position
	if p_pos.distance_to(down_pos) < 36.0:
		return {
			"pos": down_pos,
			"r": 36.0,
			"label": "Xuống Tầng %d ⬇️" % (current_floor + 1),
			"cb": func():
				if main_game != null:
					main_game._fade_transition(func():
						enter_mine(current_floor + 1)
					)
				else:
					enter_mine(current_floor + 1)
		}

	# 3. Các khối đá quặng gần nhất
	for r in _rocks_data:
		var b: StaticBody2D = r.get("body")
		if is_instance_valid(b) and p_pos.distance_to(b.position) < 36.0:
			var ore_id: String = str(r.get("type", "stone"))
			var ore_info := OreDB.get_ore(ore_id)
			var ore_name: String = str(ore_info.get("name", "Đá"))
			return {
				"pos": b.position,
				"r": 36.0,
				"label": "Đập %s ⛏️ (%d lần)" % [ore_name, int(r.get("hits_left", 1))],
				"cb": func(): _hit_rock(r)
			}

	return {}


func _hit_rock(rock_data: Dictionary) -> void:
	if not is_instance_valid(rock_data.get("body")):
		return

	if not Inventory.has_pickaxe():
		if main_game != null and main_game.hud != null:
			main_game.hud.toast("Cần có Cúp khai mỏ để đập đá! (Nói chuyện với Leah)", Color(1.0, 0.6, 0.5))
		return

	var power: int = Inventory.get_pickaxe_power()
	rock_data.hits_left = int(rock_data.hits_left) - power

	if player != null:
		player.play_action_anim("till")

	var spr: Sprite2D = rock_data.get("spr")
	if is_instance_valid(spr):
		var tw := spr.create_tween()
		tw.tween_property(spr, "scale", Vector2(1.25, 0.85), 0.05)
		tw.tween_property(spr, "scale", Vector2(0.95, 1.15), 0.06)
		tw.tween_property(spr, "scale", Vector2(1.0, 1.0), 0.05)

	if int(rock_data.hits_left) <= 0:
		_break_rock(rock_data)


func _break_rock(rock_data: Dictionary) -> void:
	var body: StaticBody2D = rock_data.get("body")
	var ore_type: String = str(rock_data.get("type", "stone"))
	var ore_info := OreDB.get_ore(ore_type)
	var ore_name: String = str(ore_info.get("name", "Đá"))

	_rocks_data.erase(rock_data)
	if is_instance_valid(body):
		var tw := body.create_tween()
		tw.tween_property(body, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(body.queue_free)

	# Thưởng quặng rơi
	var drops: Array = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	match ore_type:
		"stone":
			drops.append({"id": "stone", "name": "Đá cuội", "count": rng.randi_range(1, 3)})
			if rng.randf() < 0.25:
				drops.append({"id": "coal", "name": "Than đá", "count": 1})
		"coal":
			drops.append({"id": "coal", "name": "Than đá", "count": rng.randi_range(1, 2)})
			drops.append({"id": "stone", "name": "Đá cuội", "count": 1})
		"copper_ore":
			drops.append({"id": "copper_ore", "name": "Quặng Đồng", "count": rng.randi_range(1, 2)})
			drops.append({"id": "stone", "name": "Đá cuội", "count": 1})
			if rng.randf() < 0.30:
				drops.append({"id": "coal", "name": "Than đá", "count": 1})
		"iron_ore":
			drops.append({"id": "iron_ore", "name": "Quặng Sắt", "count": rng.randi_range(1, 2)})
			drops.append({"id": "stone", "name": "Đá cuội", "count": 1})
			if rng.randf() < 0.35:
				drops.append({"id": "coal", "name": "Than đá", "count": 1})
		"gold_ore":
			drops.append({"id": "gold_ore", "name": "Quặng Vàng", "count": rng.randi_range(1, 2)})
			drops.append({"id": "stone", "name": "Đá cuội", "count": 1})
		"ruby":
			drops.append({"id": "ruby", "name": "Hồng Ngọc (Ruby)", "count": 1})
			drops.append({"id": "stone", "name": "Đá cuội", "count": rng.randi_range(1, 2)})
		"diamond":
			drops.append({"id": "diamond", "name": "Kim Cương", "count": 1})
			drops.append({"id": "stone", "name": "Đá cuội", "count": rng.randi_range(1, 2)})

	var gained_text := ""
	for d in drops:
		var id: String = str(d.id)
		var cnt: int = int(d.count)
		if Inventory.can_hold("ore", id):
			Inventory.add_ore(id, cnt)
			gained_text += "+%d %s  " % [cnt, str(d.name)]
		else:
			if main_game != null and main_game.hud != null:
				main_game.hud.toast("Túi đồ đã đầy, không thể chứa thêm %s!" % str(d.name), Color(1.0, 0.4, 0.4))

	if gained_text != "" and main_game != null and main_game.hud != null:
		main_game.hud.toast(gained_text.strip_edges(), Color(0.75, 0.95, 1.0))
