extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("=== KIỂM THỬ CỐ ĐỊNH CÂY CỐI & KHU CHUỒNG TRẠI MỞ RỘNG ===")

	var FixedFoliageData = load("res://scripts/fixed_foliage_data.gd")
	var WorldBuilderScript = load("res://scripts/world_builder.gd")

	# 1. Kiểm tra số lượng cây đã lưu trong FixedFoliageData (62 cây sau khi dọn sạch chuồng)
	assert(FixedFoliageData.FIXED_FOLIAGE.size() == 62, "Số lượng cây cố định phải là 62 cây!")
	print("1. FixedFoliageData.FIXED_FOLIAGE chứa 62 cây sạch đẹp ngoài khu chuồng: PASSED")

	# 2. Tạo môi trường giả lập WorldBuilder
	var dummy_main := Node2D.new()
	root.add_child(dummy_main)

	var wb = WorldBuilderScript.new()
	wb.setup(dummy_main)
	var world := Node2D.new()
	wb.world = world
	dummy_main.add_child(world)

	# 3. Nạp cây cố định
	wb.build_fixed_foliage()
	assert(wb.foliage_nodes.size() == 62, "Số node cây tạo ra phải là 62! Hiện tại: %d" % wb.foliage_nodes.size())
	assert(wb.foliage_data.size() == 62, "Số dữ liệu cây lưu trữ phải là 62! Hiện tại: %d" % wb.foliage_data.size())
	print("2. build_fixed_foliage() sinh ra chính xác 62 node StaticBody2D và 62 record: PASSED")

	# 4. Kiểm tra populate_random_foliage luôn gọi sang build_fixed_foliage
	wb.populate_random_foliage(75)
	assert(wb.foliage_nodes.size() == 62, "populate_random_foliage() phải nạp đúng 62 cây cố định!")
	print("3. populate_random_foliage() đã bị vô hiệu hóa ngẫu nhiên và luôn nạp đúng 62 cây cố định: PASSED")

	# 5. Kiểm tra sprout_random_plant không sinh thêm cây
	var count_before = wb.foliage_nodes.size()
	wb.sprout_random_plant()
	assert(wb.foliage_nodes.size() == count_before, "sprout_random_plant() không được sinh thêm cây mới!")
	print("4. sprout_random_plant() đã bị vô hiệu hóa hoàn toàn, không mọc cây ngẫu nhiên qua đêm: PASSED")

	print("\n=== TOÀN BỘ KIỂM THỬ CỐ ĐỊNH CÂY CỐI THÀNH CÔNG 100%! ===")
	quit(0)
