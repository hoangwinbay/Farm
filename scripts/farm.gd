extends Node2D
# Quản lý lưới ô nông trại: cày / gieo / tưới / thu hoạch, và tăng trưởng qua ngày.

const FarmTileScript := preload("res://scripts/farm_tile.gd")
const CropDB := preload("res://scripts/crop_db.gd")

const TILE := 32

var origin := Vector2.ZERO
var size_tiles := Vector2i(14, 9)
var tiles: Dictionary = {}


func setup(o: Vector2, s: Vector2i) -> void:
	origin = o
	position = o
	size_tiles = s
	for y in s.y:
		for x in s.x:
			var t := FarmTileScript.new()
			t.farm = self
			t.setup(Vector2i(x, y))
			add_child(t)
			tiles[Vector2i(x, y)] = t


func has_soil(c: Vector2i) -> bool:
	var t = tiles.get(c)
	return t != null and t.tstate != FarmTileScript.TState.GRASS


func tile_at_world(p: Vector2) -> Node:
	var local := p - global_position
	var v := Vector2i(int(floor(local.x / TILE)), int(floor(local.y / TILE)))
	return tiles.get(v)


func tile_center(v: Vector2i) -> Vector2:
	return global_position + Vector2(v.x * TILE + 16, v.y * TILE + 16)


# Hành động có thể làm trên ô này -> hiển thị gợi ý phím E.
func action_at(tile) -> Dictionary:
	if tile == null:
		return {"act": "none", "label": "", "ok": false}
	if tile.tstate == FarmTileScript.TState.GRASS:
		return {"act": "till", "label": "Cày đất (cần cuốc — đang có ×%d)" % Inventory.hoes, "ok": Inventory.hoes > 0}
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
			tile.till()
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
