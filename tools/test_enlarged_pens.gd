extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("=== KIỂM THỬ KHU CHUỒNG TRẠI MỞ RỘNG (4 CHUỒNG BẰNG NHAU + ĐƯỜNG ĐÁ Ở GIỮA) ===")

	var PenManagerScript = load("res://scripts/pen_manager.gd")
	var WorldBuilderScript = load("res://scripts/world_builder.gd")
	var TextureGen = load("res://scripts/texture_gen.gd")

	# 1. Kiểm tra kích thước 4 chuồng bằng nhau chuẩn xác
	var cow_r: Rect2 = PenManagerScript.PEN_COW
	var chk_r: Rect2 = PenManagerScript.PEN_CHICKEN
	var shp_r: Rect2 = PenManagerScript.PEN_SHEEP
	var pig_r: Rect2 = PenManagerScript.PEN_PIG

	var expected_size := Vector2(288, 160)
	assert(cow_r.size == expected_size, "Chuồng Bò phải có kích thước 288x160! Hiện tại: %s" % str(cow_r.size))
	assert(chk_r.size == expected_size, "Chuồng Gà phải có kích thước 288x160! Hiện tại: %s" % str(chk_r.size))
	assert(shp_r.size == expected_size, "Chuồng Cừu phải có kích thước 288x160! Hiện tại: %s" % str(shp_r.size))
	assert(pig_r.size == expected_size, "Chuồng Lợn phải có kích thước 288x160! Hiện tại: %s" % str(pig_r.size))
	print("1. Cả 4 chuồng đều có diện tích bằng nhau hoàn hảo (288x160 = 46,080 px²): PASSED")

	# 2. Kiểm tra đường đá ở giữa (dọc và ngang tạo ngã tư chữ thập)
	var path_v: Rect2 = PenManagerScript.PATH_COBBLE_V
	var path_h: Rect2 = PenManagerScript.PATH_COBBLE_H

	# Kiểm tra khớp nối trục X:
	# Chuồng trái (x=144..432) -> Đường đá dọc (x=432..480, w=48) -> Chuồng phải (x=480..768)
	assert(cow_r.end.x == path_v.position.x, "Mép phải chuồng trái (%d) phải chạm mép trái đường đá dọc (%d)!" % [cow_r.end.x, path_v.position.x])
	assert(path_v.end.x == chk_r.position.x, "Mép phải đường đá dọc (%d) phải chạm mép trái chuồng phải (%d)!" % [path_v.end.x, chk_r.position.x])
	assert(path_v.size.x == 48, "Bề rộng đường đá dọc phải là 48px!")

	# Kiểm tra khớp nối trục Y:
	# Chuồng trên (y=528..688) -> Đường đá ngang (y=688..736, h=48) -> Chuồng dưới (y=736..896)
	assert(cow_r.end.y == path_h.position.y, "Mép dưới chuồng trên (%d) phải chạm mép trên đường đá ngang (%d)!" % [cow_r.end.y, path_h.position.y])
	assert(path_h.end.y == shp_r.position.y, "Mép dưới đường đá ngang (%d) phải chạm mép trên chuồng dưới (%d)!" % [path_h.end.y, shp_r.position.y])
	assert(path_h.size.y == 48, "Bề rộng đường đá ngang phải là 48px!")
	print("2. Hệ thống đường đá ở giữa kết nối hoàn hảo với 4 chuồng: PASSED")

	# 3. Kiểm tra khởi tạo và dựng Node PenManager
	var dummy_main := Node2D.new()
	root.add_child(dummy_main)

	var pm = PenManagerScript.new()
	pm.setup(dummy_main)
	var world := Node2D.new()
	dummy_main.add_child(world)
	var pnode = pm.build_pen(world)

	assert(pnode != null, "Pen node phải được tạo thành công!")
	assert(pnode.get_child_count() > 0, "Pen node phải có các đối tượng rào, sàn, cổng!")
	print("3. Khởi tạo và dựng hàng rào, cổng chuồng, sàn lót rơm thành công: PASSED (Nodes: %d)" % pnode.get_child_count())

	# 4. Kiểm tra sinh texture mặt đất không bị lỗi
	var ground_tex = TextureGen.make_ground(
		int(WorldBuilderScript.WORLD_SIZE.x),
		int(WorldBuilderScript.WORLD_SIZE.y),
		Rect2(808, 304, 480, 360),
		WorldBuilderScript.PATHS,
		WorldBuilderScript.POND_RECT,
		[path_v, path_h]
	)
	assert(ground_tex != null, "make_ground phải sinh Texture2D thành công!")
	print("4. make_ground với autotile đất chuồng trại và đường đá mới: PASSED")

	# 5. Kiểm tra chiều cao thế giới chuẩn (WORLD_SIZE.y = 1000) giấu mép đáy ao cá và đệm cỏ thoáng cho camera
	assert(WorldBuilderScript.WORLD_SIZE.y == 1000, "WORLD_SIZE.y phải là 1000 để mép đáy ao cá ăn khớp với ranh giới bản đồ!")
	var margin_bottom: float = WorldBuilderScript.WORLD_SIZE.y - shp_r.end.y
	assert(margin_bottom >= 100.0, "Phần đệm cỏ dưới đáy chuồng phải rộng rãi (>= 100px)! Hiện tại: %.1f px" % margin_bottom)
	print("5. Chiều cao bản đồ WORLD_SIZE.y = 1000 giữ ao cá ăn khớp biên nam, đệm cỏ dưới đáy chuồng rộng %.1f px giúp camera bao quát hoàn hảo: PASSED" % margin_bottom)

	print("\n=== TOÀN BỘ KIỂM THỬ KHU CHUỒNG TRẠI MỞ RỘNG THÀNH CÔNG 100%! ===")
	quit(0)
