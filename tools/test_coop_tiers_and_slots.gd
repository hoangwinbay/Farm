extends SceneTree
# Kiểm thử toàn diện hệ thống nâng cấp chuồng 4 cấp và sức chứa slot động vật:
# - Cấp 1 (mới mua): 2 slot
# - Cấp 2: 4 slot
# - Cấp 3: 8 slot
# - Cấp 4 (max): 16 slot

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("=== KIỂM THỬ HỆ THỐNG CHUỒNG 4 CẤP (2, 4, 8, 16 SLOTS) ===")

	var Inv = root.get_node("/root/Inventory")
	var GS = root.get_node("/root/GameState")
	var PoultryDB = load("res://scripts/poultry_db.gd")

	Inv.reset()
	GS.money = 1000000

	# 1. Kiểm tra hằng số sức chứa trong PoultryDB
	assert(PoultryDB.get_coop_capacity("chicken", 1) == 2, "Cấp 1 phải là 2 slots!")
	assert(PoultryDB.get_coop_capacity("chicken", 2) == 4, "Cấp 2 phải là 4 slots!")
	assert(PoultryDB.get_coop_capacity("chicken", 3) == 8, "Cấp 3 phải là 8 slots!")
	assert(PoultryDB.get_coop_capacity("chicken", 4) == 16, "Cấp 4 phải là 16 slots!")
	print("1. Kiểm tra cấu hình PoultryDB get_coop_capacity: PASSED")

	# 2. Kiểm tra chuồng ban đầu (chưa mua)
	for sid in ["chicken", "cow", "pig", "sheep"]:
		assert(Inv.get_coop_tier(sid) == 0, "Chuồng %s ban đầu phải là cấp 0!" % sid)
		assert(Inv.coop_capacity(sid) == 0, "Chuồng %s cấp 0 phải có sức chứa 0!" % sid)
		assert(Inv.free_slots(sid) == 0, "Chuồng %s cấp 0 không có free slots!" % sid)
		var buy_anim_err: String = Inv.buy_animal(sid)
		assert(buy_anim_err != "", "Không thể mua vật nuôi khi chưa có chuồng!")
	print("2. Trạng thái cấp 0 (chưa mua): PASSED")

	# 3. Mua mới chuồng (Cấp 1) -> 2 slot
	for sid in ["chicken", "cow", "pig", "sheep"]:
		var err = Inv.buy_coop(sid)
		assert(err == "", "Mua chuồng %s thất bại: %s" % [sid, err])
		assert(Inv.get_coop_tier(sid) == 1, "Chuồng %s mới mua phải là Cấp 1!" % sid)
		assert(Inv.coop_capacity(sid) == 2, "Chuồng %s Cấp 1 phải có sức chứa 2 slots! Hiện tại: %d" % [sid, Inv.coop_capacity(sid)])
		assert(Inv.free_slots(sid) == 2, "Chuồng %s Cấp 1 ban đầu phải có 2 free slots!" % sid)
	print("3. Mua mới chuồng (Cấp 1 -> 2 slots): PASSED")

	# 4. Kiểm tra giới hạn mua động vật ở Cấp 1 (tối đa 2 con)
	var err1 = Inv.buy_animal("chicken")
	assert(err1 == "", "Mua con gà 1 thất bại: %s" % err1)
	assert(Inv.free_slots("chicken") == 1, "Sau khi mua 1 con, còn 1 slot!")

	var err2 = Inv.buy_animal("chicken")
	assert(err2 == "", "Mua con gà 2 thất bại: %s" % err2)
	assert(Inv.free_slots("chicken") == 0, "Sau khi mua 2 con, còn 0 slot!")

	var err3 = Inv.buy_animal("chicken")
	assert(err3 != "", "Không được phép mua con gà thứ 3 ở Cấp 1!")
	assert("kín chỗ" in err3 or "Cấp 2" in err3, "Thông báo lỗi phải nhắc nâng cấp: %s" % err3)
	print("4. Giới hạn 2 slots ở Cấp 1: PASSED")

	# 5. Nâng cấp lên Cấp 2 -> 4 slots
	var up2 = Inv.upgrade_coop("chicken")
	assert(up2 == "", "Nâng cấp gà lên Cấp 2 thất bại: %s" % up2)
	assert(Inv.get_coop_tier("chicken") == 2, "Cấp chuồng phải là 2!")
	assert(Inv.coop_capacity("chicken") == 4, "Sức chứa Cấp 2 phải là 4 slots! Hiện tại: %d" % Inv.coop_capacity("chicken"))
	assert(Inv.free_slots("chicken") == 2, "Sau khi nâng cấp lên 4 slots và có 2 con, free_slots phải là 2!")

	# Mua thêm 2 con để đạt 4 con
	assert(Inv.buy_animal("chicken") == "", "Mua gà 3 thất bại!")
	assert(Inv.buy_animal("chicken") == "", "Mua gà 4 thất bại!")
	assert(Inv.free_slots("chicken") == 0, "Đã đủ 4 con!")
	var err5 = Inv.buy_animal("chicken")
	assert(err5 != "", "Không được phép mua con gà thứ 5 ở Cấp 2!")
	print("5. Nâng cấp Cấp 2 (4 slots): PASSED")

	# 6. Nâng cấp lên Cấp 3 -> 8 slots
	var up3 = Inv.upgrade_coop("chicken")
	assert(up3 == "", "Nâng cấp gà lên Cấp 3 thất bại: %s" % up3)
	assert(Inv.get_coop_tier("chicken") == 3, "Cấp chuồng phải là 3!")
	assert(Inv.coop_capacity("chicken") == 8, "Sức chứa Cấp 3 phải là 8 slots! Hiện tại: %d" % Inv.coop_capacity("chicken"))
	assert(Inv.free_slots("chicken") == 4, "Sau khi nâng cấp lên 8 slots và có 4 con, free_slots phải là 4!")

	# Mua thêm 4 con để đạt 8 con
	for i in 4:
		assert(Inv.buy_animal("chicken") == "", "Mua thêm gà ở Cấp 3 thất bại!")
	assert(Inv.animals_of_species("chicken") == 8, "Phải có đúng 8 con gà!")
	assert(Inv.free_slots("chicken") == 0, "Đã đủ 8 con!")
	var err9 = Inv.buy_animal("chicken")
	assert(err9 != "", "Không được phép mua con gà thứ 9 ở Cấp 3!")
	print("6. Nâng cấp Cấp 3 (8 slots): PASSED")

	# 7. Nâng cấp lên Cấp 4 (Max) -> 16 slots
	var up4 = Inv.upgrade_coop("chicken")
	assert(up4 == "", "Nâng cấp gà lên Cấp 4 thất bại: %s" % up4)
	assert(Inv.get_coop_tier("chicken") == 4, "Cấp chuồng phải là 4!")
	assert(Inv.coop_capacity("chicken") == 16, "Sức chứa Cấp 4 phải là 16 slots! Hiện tại: %d" % Inv.coop_capacity("chicken"))
	assert(Inv.free_slots("chicken") == 8, "Sau khi nâng cấp lên 16 slots và có 8 con, free_slots phải là 8!")

	# Mua thêm 8 con để đạt 16 con
	for i in 8:
		assert(Inv.buy_animal("chicken") == "", "Mua thêm gà ở Cấp 4 thất bại!")
	assert(Inv.animals_of_species("chicken") == 16, "Phải có đúng 16 con gà!")
	assert(Inv.free_slots("chicken") == 0, "Đã kín 16 con!")
	var err17 = Inv.buy_animal("chicken")
	assert(err17 != "", "Không được phép mua con gà thứ 17 ở Cấp 4!")
	assert("tối đa" in err17 or "16" in err17, "Lỗi khi đầy 16 con: %s" % err17)
	print("7. Nâng cấp Cấp 4 (Max, 16 slots): PASSED")

	# 8. Cố tình nâng cấp tiếp từ Cấp 4 -> Phải chặn lại vì đã max
	var up5 = Inv.upgrade_coop("chicken")
	assert(up5 != "", "Không được phép nâng cấp vượt quá Cấp 4!")
	assert("tối đa" in up5 or "Cấp 4" in up5, "Thông báo lỗi đã max cấp: %s" % up5)
	print("8. Chặn nâng cấp khi đã đạt Cấp 4 (Max): PASSED")

	# 9. Kiểm tra sinh sản (breeding) dừng khi kín chỗ
	# Hiện tại có 16 con gà (kín 16/16), tick_animals không được sinh thêm
	Inv.breed_timers["chicken"] = 59.9
	Inv.tick_animals(1.0)
	assert(Inv.animals_of_species("chicken") == 16, "Khi đầy 16 slot, sinh sản không được vượt quá 16 con!")
	print("9. Cơ chế sinh sản tuân thủ chặt chẽ sức chứa 16 slots: PASSED")

	print("\n=== TOÀN BỘ KIỂM THỬ HỆ THỐNG 4 CẤP CHUỒNG THÀNH CÔNG 100%! ===")
	quit(0)
