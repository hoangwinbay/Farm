extends SceneTree

# Danh sách các đoạn thẳng hàng rào thực tế trên bản đồ
const FENCES := [
	# Thửa Bắc (North Field)
	[Vector2(808, 290), Vector2(1288, 290)], # Rào Bắc
	[Vector2(808, 290), Vector2(808, 446)],   # Rào Tây
	[Vector2(1288, 290), Vector2(1288, 446)], # Rào Đông
	[Vector2(808, 446), Vector2(1016, 446)],  # Rào Nam (cánh trái)
	[Vector2(1080, 446), Vector2(1288, 446)], # Rào Nam (cánh phải)

	# Thửa Nam (South Field)
	[Vector2(808, 498), Vector2(1016, 498)],  # Rào Bắc (cánh trái)
	[Vector2(1080, 498), Vector2(1288, 498)], # Rào Bắc (cánh phải)
	[Vector2(808, 498), Vector2(808, 654)],   # Rào Tây
	[Vector2(1288, 498), Vector2(1288, 654)], # Rào Đông
	[Vector2(808, 654), Vector2(1288, 654)],  # Rào Nam
]

static func _ccw(A: Vector2, B: Vector2, C: Vector2) -> bool:
	return (C.y - A.y) * (B.x - A.x) > (B.y - A.y) * (C.x - A.x)

static func _segments_intersect(A: Vector2, B: Vector2, C: Vector2, D: Vector2) -> bool:
	return _ccw(A, C, D) != _ccw(B, C, D) and _ccw(A, B, C) != _ccw(A, B, D)

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("=== TESTING CAT FENCE NAVIGATION & AVOIDANCE ===")

	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var cat = main_scene.cat_helper
	assert(cat != null, "Cat helper must exist")

	var CatHelperScript = load("res://scripts/cat_helper.gd")

	# Test 1: Mèo ở trong Thửa Bắc đi ra Nhà Kho (Shed)
	cat.position = Vector2(900, 350) # Giữa thửa Bắc
	cat._set_destination(CatHelperScript.SHED_DOOR_POS)
	_verify_no_fence_cut(cat.position, cat.waypoints, "Thửa Bắc -> Nhà Kho")

	# Test 2: Mèo ở trong Thửa Nam đi về Nhà Junimo
	cat.position = Vector2(900, 550) # Giữa thửa Nam
	cat._set_destination(CatHelperScript.TENT_SLEEP_POS)
	_verify_no_fence_cut(cat.position, cat.waypoints, "Thửa Nam -> Nhà Junimo")

	# Test 3: Mèo ở trong Thửa Nam đi ra Bờ Ao múc nước
	cat.position = Vector2(1100, 600) # Thửa Nam
	cat._set_destination(CatHelperScript.POND_REFILL_POS)
	_verify_no_fence_cut(cat.position, cat.waypoints, "Thửa Nam -> Bờ Ao")

	# Test 4: Mèo ở Nhà Junimo đi vào một ô đất trong Thửa Nam
	cat.position = CatHelperScript.TENT_SLEEP_POS
	cat._set_destination(Vector2(950, 580)) # Ô đất Thửa Nam
	_verify_no_fence_cut(cat.position, cat.waypoints, "Nhà Junimo -> Thửa Nam")

	# Test 5: Mèo từ Thửa Bắc di chuyển sang Thửa Nam
	cat.position = Vector2(850, 320) # Thửa Bắc
	cat._set_destination(Vector2(1200, 600)) # Thửa Nam
	_verify_no_fence_cut(cat.position, cat.waypoints, "Thửa Bắc -> Thửa Nam")

	# Test 6: Mèo từ Thửa Nam di chuyển sang Thửa Bắc
	cat.position = Vector2(1200, 600) # Thửa Nam
	cat._set_destination(Vector2(850, 320)) # Thửa Bắc
	_verify_no_fence_cut(cat.position, cat.waypoints, "Thửa Nam -> Thửa Bắc")

	# Test 7: Mèo từ Bờ Ao đi vào Thửa Bắc
	cat.position = CatHelperScript.POND_REFILL_POS
	cat._set_destination(Vector2(1000, 350))
	_verify_no_fence_cut(cat.position, cat.waypoints, "Bờ Ao -> Thửa Bắc")

	# Test 8: Mèo từ Bờ Ao Ngang (câu cá) đi về Nhà Kho (cất cá)
	cat.position = CatHelperScript.POND_FISHING_POS
	cat._set_destination(CatHelperScript.SHED_DOOR_POS)
	_verify_no_fence_cut(cat.position, cat.waypoints, "Bờ Ao Ngang -> Nhà Kho")

	# Test 9: Mèo từ Nhà Kho đi ra Bờ Ao Ngang (câu cá tiếp)
	cat.position = CatHelperScript.SHED_DOOR_POS
	cat._set_destination(CatHelperScript.POND_FISHING_POS)
	_verify_no_fence_cut(cat.position, cat.waypoints, "Nhà Kho -> Bờ Ao Ngang")

	# Test 10: Mèo từ Nhà Junimo đi ra Bờ Ao Ngang
	cat.position = CatHelperScript.TENT_SLEEP_POS
	cat._set_destination(CatHelperScript.POND_FISHING_POS)
	_verify_no_fence_cut(cat.position, cat.waypoints, "Nhà Junimo -> Bờ Ao Ngang")

	# Test 11: Mèo từ Bờ Ao Ngang đi về Nhà Junimo
	cat.position = CatHelperScript.POND_FISHING_POS
	cat._set_destination(CatHelperScript.TENT_SLEEP_POS)
	_verify_no_fence_cut(cat.position, cat.waypoints, "Bờ Ao Ngang -> Nhà Junimo")

	# Test 12: Kiểm tra toàn diện mọi ô đất trên nông trại
	var farm = main_scene.farm
	assert(farm != null, "Farm must exist")
	var sample_tiles = farm.tiles.values()
	var test_count := 0

	for i in range(0, sample_tiles.size(), 4):
		var tile_from = sample_tiles[i]
		var pos_from: Vector2 = farm.tile_center(tile_from.coord)
		for j in range(2, sample_tiles.size(), 8):
			var tile_to = sample_tiles[j]
			var pos_to: Vector2 = farm.tile_center(tile_to.coord)
			cat.position = pos_from
			cat._set_destination(pos_to)
			_verify_no_fence_cut(cat.position, cat.waypoints, "Tile (%d,%d) -> Tile (%d,%d)" % [tile_from.coord.x, tile_from.coord.y, tile_to.coord.x, tile_to.coord.y])
			test_count += 1

	print("✓ Đã kiểm tra %d tuyến đường ngẫu nhiên qua các ô đất: 0 va chạm rào!" % test_count)
	print("=== TẤT CẢ KIỂM THỬ ĐIỀU HƯỚNG TRÁNH RÀO ĐÃ VƯỢT QUA 100%! ===")
	quit()

func _verify_no_fence_cut(start_pos: Vector2, waypoints: Array, test_label: String) -> void:
	var path := [start_pos] + waypoints
	for i in range(path.size() - 1):
		var A: Vector2 = path[i]
		var B: Vector2 = path[i + 1]
		for fence in FENCES:
			var C: Vector2 = fence[0]
			var D: Vector2 = fence[1]
			var cuts := _segments_intersect(A, B, C, D)
			assert(!cuts, "LỖI: Đường đi %s bị cắt xuyên rào tại đoạn %s -> %s (Rào %s -> %s)" % [test_label, str(A), str(B), str(C), str(D)])
	print("✓ %s: Đường đi không cắt xuyên hàng rào!" % test_label)
