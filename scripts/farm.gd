extends Node2D
# Quản lý lưới ô nông trại: cày / gieo / tưới / thu hoạch, và tăng trưởng qua ngày.

const FarmTileScript := preload("res://scripts/farm_tile.gd")
const CropDB := preload("res://scripts/crop_db.gd")

const TILE := 32

var origin := Vector2.ZERO
var size_tiles := Vector2i(14, 9)
var tiles: Dictionary = {}
var tile_centers: Dictionary = {}
var plots: Array = []


func setup_plots(plot_configs: Array) -> void:
	plots = plot_configs.duplicate(true)
	position = Vector2.ZERO
	tiles.clear()
	tile_centers.clear()
	for child in get_children():
		child.queue_free()

	for plot in plots:
		var o: Vector2 = plot.origin
		var s: Vector2i = plot.size
		var y_off: int = int(plot.get("y_offset", 0))
		for py in s.y:
			for px in s.x:
				var coord := Vector2i(px, py + y_off)
				var center_pos := o + Vector2(px * TILE + 16, py * TILE + 16)
				var t := FarmTileScript.new()
				t.farm = self
				t.setup(coord, center_pos)
				add_child(t)
				tiles[coord] = t
				tile_centers[coord] = center_pos


func setup(o: Vector2, s: Vector2i) -> void:
	origin = o
	size_tiles = s
	setup_plots([{
		"origin": o,
		"size": s,
		"rect": Rect2(o, Vector2(s.x * TILE, s.y * TILE)),
		"y_offset": 0
	}])


func has_soil(c: Vector2i) -> bool:
	var t = tiles.get(c)
	return t != null and t.tstate != FarmTileScript.TState.GRASS


func tile_at_world(p: Vector2) -> Node:
	var check_p := to_local(p)
	for plot in plots:
		var rect: Rect2 = plot.rect
		if rect.has_point(check_p):
			var local := check_p - rect.position
			var gx := int(floor(local.x / TILE))
			var gy := int(floor(local.y / TILE))
			var coord := Vector2i(gx, gy + int(plot.get("y_offset", 0)))
			return tiles.get(coord)
		elif rect.has_point(p):
			var local := p - rect.position
			var gx := int(floor(local.x / TILE))
			var gy := int(floor(local.y / TILE))
			var coord := Vector2i(gx, gy + int(plot.get("y_offset", 0)))
			return tiles.get(coord)
	return null


func tile_center(v: Vector2i) -> Vector2:
	if tile_centers.has(v):
		return to_global(tile_centers[v])
	return global_position + Vector2(v.x * TILE + 16, v.y * TILE + 16)


# Hành động có thể làm trên ô này -> hiển thị gợi ý phím E.
func action_at(tile) -> Dictionary:
	if tile == null:
		return {"act": "none", "label": "", "ok": false}
	if tile.tstate == FarmTileScript.TState.GRASS:
		return {"act": "till", "label": "Cày đất (cần cuốc — đang có ×%d)" % Inventory.hoes, "ok": Inventory.hoes > 0}
	if tile.tstate == FarmTileScript.TState.HARVESTED:
		return {"act": "till", "label": "Cuốc lại đất đen sau thu hoạch (cần cuốc — đang có ×%d)" % Inventory.hoes, "ok": Inventory.hoes > 0}
	if tile.tstate == FarmTileScript.TState.PLANTED and tile.has_pest:
		return {"act": "catch_pest", "label": "Bắt sâu bọ 🐛 (Đang cắn phá cây!)", "ok": true}
	if tile.tstate == FarmTileScript.TState.PLANTED and tile.is_ready():
		var c := CropDB.get_crop(tile.crop_id)
		return {"act": "harvest", "label": "Thu hoạch %s" % c.get("name", "?"), "ok": true}
	if tile.tstate == FarmTileScript.TState.PLANTED and not tile.watered:
		var has_w := Inventory.has_water()
		var label := "Tưới nước (%d/%d)" % [Inventory.water_level, Inventory.water_max] if has_w else "Bình hết nước (ra bờ ao múc!)"
		return {"act": "water", "label": label, "ok": has_w}
	if tile.tstate == FarmTileScript.TState.TILLED:
		var sid := Inventory.selected_seed
		if sid != "" and GameState.has_crop(sid) and Inventory.seed_count(sid) > 0:
			var cs := CropDB.get_crop(sid)
			return {"act": "plant", "label": "Gieo hạt %s (còn ×%d)" % [cs.get("name", "?"), Inventory.seed_count(sid)], "ok": true}
		return {"act": "none", "label": "Chưa gieo hạt (chọn hạt ở thanh công cụ hoặc bấm I)", "ok": false}
	if tile.tstate == FarmTileScript.TState.PLANTED:
		var c2 := CropDB.get_crop(tile.crop_id)
		var pct := int(clampf(tile.growth / float(c2.get("grow_sec", 1)) * 100.0, 0.0, 99.0))
		var extra := "" if tile.watered else " — đất khô, cần tưới!"
		return {"act": "none", "label": "%s đang lớn (%d%%)%s" % [c2.get("name", "?"), pct, extra], "ok": false}
	return {"act": "none", "label": "", "ok": false}


# Thực hiện hành động, trả về dòng thông báo (rỗng = không làm gì).
func perform_at(tile) -> String:
	var info := action_at(tile)
	if tile == null:
		return ""
	match str(info.act):
		"catch_pest":
			if not Inventory.can_hold("produce", "sau_bo"):
				return "Túi đồ đã đầy (%d/%d)! Hãy cất đồ vào nhà kho 🏚️ trước khi bắt sâu." % [Inventory.backpack_slots_used(), Inventory.backpack_max]
			tile.clear_pest()
			Inventory.add_produce("sau_bo", 1)
			return "Đã bắt được 1 Sâu bọ 🐛! Có thể dùng làm mồi câu hoặc bán."
		"till":
			if not Inventory.take_hoe():
				return "Cần CUỐC để cày đất! Mua ở cửa hàng Bác Tư (20 xu)."
			var was_harvested: bool = (tile.tstate == FarmTileScript.TState.HARVESTED)
			tile.till()
			if was_harvested:
				return "Đã cuốc xới lại đất đen sau thu hoạch! (Còn %d cuốc)" % Inventory.hoes
			return "Đã cày đất! (Còn %d cuốc)" % Inventory.hoes
		"water":
			if tile.tstate != FarmTileScript.TState.PLANTED:
				return "Cần gieo hạt giống trước khi tưới nước!"
			if not Inventory.take_water(1):
				return "Bình tưới hết nước rồi! Hãy ra bờ ao để múc đầy bình."
			tile.water()
			return "Đã tưới nước! (Còn %d/%d gáo)" % [Inventory.water_level, Inventory.water_max]
		"plant":
			var sid := Inventory.selected_seed
			if sid == "" or not GameState.has_crop(sid):
				return "Chưa chọn hạt giống (bấm I)!"
			if not Inventory.take_seed(sid, 1):
				return "Hết hạt giống rồi — mua ở cửa hàng Bác Tư!"
			var c := CropDB.get_crop(sid)
			tile.plant(sid)
			return "Đã gieo hạt %s!" % c.get("name", "?")
		"harvest":
			if not Inventory.can_hold("produce", tile.crop_id):
				return "Túi đồ đã đầy (%d/%d)! Hãy cất bớt đồ vào nhà kho 🏚️ để thu hoạch." % [Inventory.backpack_slots_used(), Inventory.backpack_max]
			var id := str(tile.harvest())
			var c := CropDB.get_crop(id)
			Inventory.add_produce(id, 1)
			return "Thu hoạch +1 %s!" % c.get("name", "?")
	return ""


# Số cây đã chín chờ thu hoạch.
func ready_count() -> int:
	var n := 0
	for t in tiles.values():
		if t.is_ready():
			n += 1
	return n


func reset_all() -> void:
	for t in tiles.values():
		t.reset_tile()


func get_state() -> Array:
	var arr: Array = []
	for v in tiles:
		var d: Dictionary = tiles[v].get_state()
		if not d.is_empty():
			arr.append(d)
	return arr


func apply_state(arr: Array) -> void:
	reset_all()
	for d in arr:
		var key := Vector2i(int(d.get("x", -1)), int(d.get("y", -1)))
		if tiles.has(key):
			tiles[key].apply_state(d)
