extends SceneTree

# Công cụ chạy sinh cây & thực vật ngẫu nhiên (Random Foliage Generator)
# Cách dùng:
# 1. Chạy xem thử và thống kê:
#    D:\Godot_v4.7.2-stable_win64.exe --headless -s tools/run_random_foliage.gd
# 2. Sinh ngẫu nhiên và lưu thẳng vào save game hiện tại:
#    D:\Godot_v4.7.2-stable_win64.exe --headless -s tools/run_random_foliage.gd -- --save

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	var WorldBuilderScript = load("res://scripts/world_builder.gd")
	print("==================================================")
	print("🌲 KHỞI ĐỘNG CÔNG CỤ SINH CÂY & THỰC VẬT NGẪU NHIÊN 🌲")
	print("==================================================")

	var dummy_main := Node2D.new()
	root.add_child(dummy_main)

	var wb = WorldBuilderScript.new()
	wb.setup(dummy_main)
	var world := Node2D.new()
	wb.world = world
	dummy_main.add_child(world)

	# Sinh 75 cây và bụi cây ngẫu nhiên trên khắp bản đồ cỏ
	var target_count := 75
	wb.populate_random_foliage(target_count)

	var data: Array = wb.foliage_data
	print("\n✅ Đã sinh thành công %d vật thể thực vật trên bản đồ!" % data.size())

	# Thống kê chủng loại
	var counts: Dictionary = {}
	var names_vi: Dictionary = {
		"tree_oak": "🌳 Cây Sồi (Oak)",
		"tree_maple": "🍁 Cây Phong (Maple)",
		"tree_pine": "🌲 Cây Thông (Pine)",
		"tree_broadleaf": "🌿 Cây Lá Rộng (Broadleaf)",
		"bush_large": "🌿 Bụi Rậm Lớn (Bush Large)",
		"bush_med": "🌱 Bụi Cây Vừa (Bush Med)",
		"bush_berry": "🫐 Bụi Quả Mọng (Berry Bush)",
		"bush_small": "🌱 Bụi Cỏ Nhỏ (Bush Small)",
		"tree_stump": "🪵 Gốc Cây Mục (Stump)"
	}

	for item in data:
		var t: String = str(item.get("type", "unknown"))
		counts[t] = int(counts.get(t, 0)) + 1

	print("\n--- BẢNG THỐNG KÊ SỐ LƯỢNG CHI TIẾT ---")
	for k in counts:
		var vi_name: String = str(names_vi.get(k, k))
		print(" • %-30s: %2d cây" % [vi_name, counts[k]])

	# In 5 mẫu vị trí đầu tiên
	print("\n--- MẪU 5 TỌA ĐỘ TIÊU BIỂU ---")
	for i in mini(5, data.size()):
		var it = data[i]
		print(" #%d: %-16s tại tọa độ (x: %6.1f, y: %6.1f)" % [i + 1, it.get("type"), float(it.get("x")), float(it.get("y"))])

	# Kiểm tra tham số dòng lệnh xem có lưu vào save.json hay không
	var cmd_args := OS.get_cmdline_user_args()
	var should_save := false
	for arg in cmd_args:
		if arg == "--save" or arg == "-s":
			should_save = true
			break

	# Nếu không có user args thì kiểm tra toàn bộ args
	if not should_save:
		for arg in OS.get_cmdline_args():
			if arg == "--save":
				should_save = true
				break

	var save_path := "user://save.json"
	if FileAccess.file_exists(save_path):
		if should_save:
			var f_read := FileAccess.open(save_path, FileAccess.READ)
			if f_read != null:
				var json_str := f_read.get_as_text()
				f_read.close()
				var save_dict = JSON.parse_string(json_str)
				if typeof(save_dict) == TYPE_DICTIONARY:
					save_dict["foliage"] = data.duplicate(true)
					var f_write := FileAccess.open(save_path, FileAccess.WRITE)
					if f_write != null:
						f_write.store_string(JSON.stringify(save_dict, "\t"))
						f_write.close()
						print("\n💾 [THÀNH CÔNG] Đã lưu dàn cây mới vào file save game (%s)!" % save_path)
						print("   👉 Bây giờ bạn chỉ cần mở game và bấm 'Tiếp tục' là thấy cây mới ngay!")
		else:
			print("\n💡 [MẸO]: Thêm cờ `--save` vào cuối lệnh để lưu thẳng dàn cây mới này vào file save game:")
			print("   cmd /c \"D:\\Godot_v4.7.2-stable_win64.exe --headless -s tools/run_random_foliage.gd -- --save\"")

	print("\n==================================================")
	quit(0)
