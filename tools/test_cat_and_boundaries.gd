extends SceneTree
# Test toàn diện:
# 1. Bấm E tương tác với Mèo tam thể khi đứng gần (mở giao diện phỏng vấn / quản lý)
# 2. Giới hạn va chạm nhà chính & nhà kho (không đi xuyên qua nhà, mái, sau lưng)
# 3. Giới hạn va chạm hồ cá (không đi xuyên vào lòng hồ nước từ bất kỳ hướng nào)

var GameState: Node
var Inventory: Node

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	GameState = root.get_node("GameState")
	Inventory = root.get_node("Inventory")
	print("--- BAT DAU KIEM THU MEO & GIOI HAN NHA, HO ---")
	
	# Load Main scene
	var main_res: PackedScene = load("res://scenes/main.tscn")
	var main_node = main_res.instantiate()
	root.add_child(main_node)
	
	# Cho 5 frames để mọi node trong world và physics server sẵn sàng
	for i in 5:
		await physics_frame
	
	var player = main_node.player
	var cat = main_node.cat_helper
	var cat_panel = main_node.cat_panel
	
	# ========================================================
	# PHAN 1: KIEM THU TUONG TAC MEO TAM THE [E]
	# ========================================================
	print("--- PHAN 1: TƯƠNG TÁC MÈO TAM THỂ ---")
	# Đặt người chơi đứng gần mèo (mèo đang ở WAITING_POS hoặc SPAWN_POS)
	player.position = cat.position + Vector2(0, 16)
	var near_cat: Dictionary = main_node._nearest_interactable()
	var cat_label: String = str(near_cat.get("label", ""))
	print("1.1 Player dung canh meo -> Label: '", cat_label, "' (co chu 'Mèo': ", "Mèo" in cat_label, ")")
	assert("Mèo" in cat_label, "Loi: Khong tim thay tuong tac voi Meo khi dung gan!")

	# Thu mo giao dien meo bang cach kich hoat callback tuong tac [E]
	assert(near_cat.has("cb") and near_cat.cb is Callable, "Loi: Callback tuong tac meo khong hop le!")
	near_cat.cb.call()
	print("1.2 Kich hoat [E] -> cat_panel.visible: ", cat_panel.visible)
	assert(cat_panel.visible, "Loi: Bang quan ly meo khong mo khi bam E!")

	# Dong bang cat_panel
	main_node._close_panels()
	print("1.3 Dong bang meo -> cat_panel.visible: ", cat_panel.visible)
	assert(not cat_panel.visible, "Loi: Bang meo khong dong khi dong panel!")

	# ========================================================
	# ========================================================
	# PHAN 2: KIEM THU GIOI HAN NHA, NUI & LOI DI NGANG
	# ========================================================
	print("--- PHAN 2: GIỚI HẠN VA CHẠM NHÀ & LỐI ĐI NGANG ---")
	# 2.1 Di tu truoc cua nha kho (505, 270) di thang len tren
	player.position = Vector2(505, 270)
	for s in 50:
		player.velocity = Vector2(0, -100)
		player.move_and_slide()
		await physics_frame
	print("2.1 Di len nha kho -> Dung lai tai: ", player.position, " (chan ngoai nha? y >= 244: ", player.position.y >= 244, ")")
	assert(player.position.y >= 244, "Loi: Nhan vat da di xuyen qua nha kho!")

	# 2.2 Di ngang tu vi tri nhan vat ben trai nha kho (425, 165) xuyen suot sang phai ra bai co sau leu
	player.position = Vector2(425, 165)
	for s in 250:
		player.velocity = Vector2(100, 0)
		player.move_and_slide()
		await physics_frame
	print("2.2 Di ngang o y=165 sang phai -> Dat x: ", player.position.x, " (qua khoi nha? x > 720: ", player.position.x > 720, ")")
	assert(player.position.x > 720, "Loi: Khong di ngang qua duoc tu vi tri nhan vat o y=165!")

	# 2.3 Di ngang o do cao sat vach nui (425, 100) xuyen suot sang phai
	player.position = Vector2(425, 100)
	for s in 250:
		player.velocity = Vector2(100, 0)
		player.move_and_slide()
		await physics_frame
	print("2.3 Di ngang o y=100 (sat nui) sang phai -> Dat x: ", player.position.x, " (qua khoi nha? x > 720: ", player.position.x > 720, ")")
	assert(player.position.x > 720, "Loi: Khong di ngang qua duoc o y=100 sat nui!")

	# 2.4 Di len vach nui bien Bac
	player.position = Vector2(580, 80)
	for s in 50:
		player.velocity = Vector2(0, -100)
		player.move_and_slide()
		await physics_frame
	print("2.4 Di len vach nui -> Dung lai tai: ", player.position, " (chan boi nui? y in [88..94]: ", player.position.y >= 88 and player.position.y <= 94, ")")
	assert(player.position.y >= 88 and player.position.y <= 94, "Loi: Nhan vat da di xuyen qua vach nui bien Bac!")

	# 2.5 Di vao lan can / cua truoc nha chinh (656, 260) di thang len
	# Phai dung lai ben ngoai cua nha (y >= 250), khong the di xuyen qua cua vao trong nha!
	player.position = Vector2(656, 260)
	for s in 50:
		player.velocity = Vector2(0, -100)
		player.move_and_slide()
		await physics_frame
	print("2.5 Di thang vao cua nha chinh -> Dung lai tai: ", player.position, " (chan ngoai cua? y >= 250: ", player.position.y >= 250, ")")
	assert(player.position.y >= 250, "Loi: Nhan vat da di xuyen qua cua nha chinh!")

	# 2.6 Dung truoc cua nha van tuong tac ngu / luu game duoc
	var near_sleep: Dictionary = main_node._nearest_interactable()
	var sleep_lbl: String = str(near_sleep.get("label", ""))
	print("2.6 Dung truoc cua nha -> Label: '", sleep_lbl, "' (co chu 'Ngủ': ", "Ngủ" in sleep_lbl, ")")
	assert("Ngủ" in sleep_lbl, "Loi: Khong the tuong tac ngu khi dung truoc cua nha!")

	# 2.7 Di thang vao leu meo (766, 260)
	player.position = Vector2(766, 260)
	for s in 50:
		player.velocity = Vector2(0, -100)
		player.move_and_slide()
		await physics_frame
	print("2.7 Di vao leu meo -> Dung lai tai: ", player.position, " (chan ngoai leu? y >= 240: ", player.position.y >= 240, ")")
	assert(player.position.y >= 240, "Loi: Nhan vat da di xuyen qua leu meo!")

	# ========================================================
	# PHAN 3: KIEM THU GIOI HAN HO NUOC (DUNG TREN BO HO)
	# ========================================================
	print("--- PHAN 3: GIỚI HẠN VA CHẠM HỒ NƯỚC (ĐỨNG TRÊN BỜ) ---")
	# 3.1 Di tu duong phia Bac (1440, 700) xuong mep ho ca
	# Nguoi choi dung tren bo ho (y in [750..756]), khong bi chim xuong day ho nuoc (y=780)
	player.position = Vector2(1440, 700)
	for s in 80:
		player.velocity = Vector2(0, 100)
		player.move_and_slide()
		await physics_frame
	print("3.1 Di tu duong phia Bac xuong bo ho -> Dung lai tai: ", player.position, " (dung tren bo ho? y in [750..756]: ", player.position.y >= 750 and player.position.y <= 756, ")")
	assert(player.position.y >= 750 and player.position.y <= 756, "Loi: Khong dung tren bo ho ma bi chim xuong day ho! (y = %f)" % player.position.y)

	# 3.2 Di tu phia Tay (1200, 880) sang phai vao long ho
	player.position = Vector2(1200, 880)
	for s in 60:
		player.velocity = Vector2(100, 0)
		player.move_and_slide()
		await physics_frame
	print("3.2 Di tu phia Tay vao ho -> Dung lai tai: ", player.position, " (ngoai bo ho? x in [1255..1268]: ", player.position.x >= 1255 and player.position.x <= 1268, ")")
	assert(player.position.x >= 1255 and player.position.x <= 1268, "Loi: Nhan vat da di xuyen vao nuoc tu bo Tay!")

	# 3.3 Di tu phia Dong (1660, 880) sang trai vao long ho
	player.position = Vector2(1660, 880)
	for s in 60:
		player.velocity = Vector2(-100, 0)
		player.move_and_slide()
		await physics_frame
	print("3.3 Di tu phia Dong vao ho -> Dung lai tai: ", player.position, " (ngoai bo ho? x in [1605..1625]: ", player.position.x >= 1605 and player.position.x <= 1625, ")")
	assert(player.position.x >= 1605 and player.position.x <= 1625, "Loi: Nhan vat da di xuyen vao nuoc tu bo Dong!")

	# 3.4 Dung tren bo Bac ho co the tuong tac cau ca & muc nuoc
	player.position = Vector2(1440, 754)
	var near_pond_north: Dictionary = main_node._nearest_interactable()
	var pond_lbl_north: String = str(near_pond_north.get("label", ""))
	print("3.4 Dung tren bo Bac tai ", player.position, " -> Label: '", pond_lbl_north, "'")
	assert("Câu cá" in pond_lbl_north or "nước" in pond_lbl_north, "Loi: Khong the tuong tac cau ca tren bo Bac ho!")

	# 3.5 Dung tren bo Tay ho co the tuong tac cau ca & muc nuoc
	player.position = Vector2(1255, 880)
	var near_pond_west: Dictionary = main_node._nearest_interactable()
	var pond_lbl_west: String = str(near_pond_west.get("label", ""))
	print("3.5 Dung tren bo Tay tai ", player.position, " -> Label: '", pond_lbl_west, "'")
	assert("Câu cá" in pond_lbl_west or "nước" in pond_lbl_west, "Loi: Khong the tuong tac cau ca / muc nuoc tren bo Tay ho!")

	# ========================================================
	# PHAN 4: KIEM THU TUI DO (INVENTORY UI, TIEN & HAT X0)
	# ========================================================
	print("--- PHAN 4: KIỂM THỬ TÚI ĐỒ (TIỀN & ẨN VẬT PHẨM SỐ LƯỢNG 0) ---")
	var inv = main_node.inv_panel
	inv.open()

	# 4.1 Kiem tra tien hien thi trong tui do
	print("4.1 Tien trong GameState: ", GameState.money, " | Label tui do: '", inv.money_label.text, "'")
	assert(inv.money_label.text == "%d xu" % GameState.money, "Loi: Tien trong tui do khong khop voi GameState.money!")

	GameState.money = 350
	GameState.money_changed.emit(350)
	print("4.2 Sau khi doi tien -> Label tui do: '", inv.money_label.text, "'")
	assert(inv.money_label.text == "350 xu", "Loi: Tien trong tui do khong cap nhat theo money_changed!")

	# 4.3 Kiem tra cac hat giong so luong 0 khong con hien thi
	# Xoa toan bo hat trong Inventory
	Inventory.seeds.clear()
	Inventory.selected_seed = ""
	inv.refresh()
	# Dem so card hat giong trong rows
	var seed_cards_count := 0
	for child in inv.rows.get_children():
		# Neu la PanelContainer chua seed_card thi dem
		if child is PanelContainer and child.has_meta("is_seed_card"):
			seed_cards_count += 1
	# Hoac kiem tra placeholder
	print("4.3 Khi khong co hat giong (so luong = 0) -> Co card hat nao hien thi khong?")
	# Thu them 3 hat lua gao
	Inventory.add_seed("rice", 3)
	inv.refresh()
	assert(Inventory.seed_count("rice") == 3, "Loi add seed")
	Inventory.select_seed("rice")
	assert(Inventory.selected_seed == "rice", "Loi select seed")

	# Dung het hat lua gao ve 0
	Inventory.take_seed("rice", 3)
	assert(Inventory.seed_count("rice") == 0, "Loi: Seed phai ve 0")
	assert(Inventory.selected_seed == "", "Loi: Hat ve 0 phai tu dong bo chon / khong con cam!")
	inv.refresh()
	print("4.4 Khi hat ve 0 -> Inventory.selected_seed: '", Inventory.selected_seed, "' (da go bo chon)")

	inv.close()

	# ========================================================
	# PHAN 5: KIEM THU CAN CAU VE 0 KHONG CON HIEN THI TREN HOTBAR
	# ========================================================
	print("--- PHAN 5: CẦN CÂU VỀ 0 KHÔNG HIỂN THỊ TRÊN HOTBAR ---")
	Inventory.rods.clear()
	Inventory.active_item = {"type": "hoe"}
	var hud = main_node.hud
	hud.rebuild_hotbar()

	var has_rod_slot := false
	for slot in hud._slots_cache:
		if str(slot.get("type", "")) == "rod":
			has_rod_slot = true
			break
	print("5.1 Khi rods trong (0 luot cau) -> Hotbar co can cau khong? ", has_rod_slot)
	assert(not has_rod_slot, "Loi: Can cau ve 0 nhung van hien thi tren hotbar!")

	# Mua / Them 3 luot cau
	Inventory.add_rod("basic", 3)
	hud.rebuild_hotbar()
	has_rod_slot = false
	var rod_slot_qty := 0
	for slot in hud._slots_cache:
		if str(slot.get("type", "")) == "rod":
			has_rod_slot = true
			rod_slot_qty = int(slot.get("qty", 0))
			break
	print("5.2 Khi co 3 luot cau -> Hotbar co can cau khong? ", has_rod_slot, " (qty=", rod_slot_qty, ")")
	assert(has_rod_slot and rod_slot_qty == 3, "Loi: Can cau co luot cau nhung khong hien tren hotbar!")

	# Chon can cau lam active_item
	Inventory.select_tool("rod")
	assert(str(Inventory.active_item.get("type", "")) == "rod", "Loi: Khong the chon can cau khi con luot cau!")

	# Dung het 3 luot cau ve 0
	for c in 3:
		var used_tier = Inventory.take_cast()
		assert(used_tier != "", "Loi take_cast")
	assert(Inventory.total_casts() == 0, "Loi: total_casts phai ve 0")
	assert(str(Inventory.active_item.get("type", "")) != "rod", "Loi: Khi het luot cau active_item phai doi ve cong cu khac (hoe)!")

	hud.rebuild_hotbar()
	has_rod_slot = false
	for slot in hud._slots_cache:
		if str(slot.get("type", "")) == "rod":
			has_rod_slot = true
			break
	print("5.3 Sau khi dung het luot cau ve 0 -> Hotbar con can cau khong? ", has_rod_slot)
	assert(not has_rod_slot, "Loi: Can cau het luot (ve 0) van con hien thi tren hotbar!")

	# ========================================================
	# PHAN 6: KIEM THU CAT HET KHOANG SAN VAO NHA KHO
	# ========================================================
	print("--- PHAN 6: CẤT HẾT KHOÁNG SẢN VÀO NHÀ KHO ---")
	var storage_p = main_node.storage_panel
	Inventory.ores.clear()
	Inventory.add_ore("coal", 13)
	Inventory.add_ore("stone", 32)
	Inventory.add_ore("copper_ore", 11)
	assert(Inventory.ore_count("coal") == 13, "Loi add coal")
	assert(Inventory.ore_count("stone") == 32, "Loi add stone")
	assert(Inventory.ore_count("copper_ore") == 11, "Loi add copper_ore")

	# Cat het khoang san
	var moved_ores: int = int(Inventory.store_all_category("ores"))
	print("6.1 So khoang san da cat vao kho: ", moved_ores, " (ky vong 56)")
	assert(moved_ores == 56, "Loi: Phai cat tong cong 56 khoang san vao kho!")
	assert(Inventory.ore_count("coal") == 0, "Loi: Than da trong tui phai ve 0")
	assert(Inventory.ore_count("stone") == 0, "Loi: Da cuoi trong tui phai ve 0")
	assert(Inventory.ore_count("copper_ore") == 0, "Loi: Quang dong trong tui phai ve 0")

	# Kiem tra trong kho nha kho da nhan dung
	var stored_ores = Inventory.storage.get("ores", {})
	assert(int(stored_ores.get("coal", 0)) >= 13, "Loi: Kho khong nhan du than da!")
	assert(int(stored_ores.get("stone", 0)) >= 32, "Loi: Kho khong nhan du da cuoi!")
	assert(int(stored_ores.get("copper_ore", 0)) >= 11, "Loi: Kho khong nhan du quang dong!")

	storage_p.open()
	storage_p.refresh()
	storage_p.close()
	print("6.2 Giao dien nha kho mo/refresh voi khoang san thanh cong!")

	# ========================================================
	# PHAN 7: KIEM THU CUOC VE 0 KHÔNG CÒN HIỂN THỊ TRÊN HOTBAR
	# ========================================================
	print("--- PHAN 7: CUỐC VỀ 0 KHÔNG HIỂN THỊ TRÊN HOTBAR ---")
	Inventory.hoes = 2
	hud.rebuild_hotbar()
	var has_hoe_slot := false
	var hoe_qty := 0
	for slot in hud._slots_cache:
		if str(slot.get("type", "")) == "hoe":
			has_hoe_slot = true
			hoe_qty = int(slot.get("qty", 0))
			break
	print("7.1 Khi co 2 cuoc -> Hotbar co cuoc khong? ", has_hoe_slot, " (qty=", hoe_qty, ")")
	assert(has_hoe_slot and hoe_qty == 2, "Loi: Co cuoc nhung khong hien tren hotbar!")

	# Cuoc lan 1
	var t1: bool = Inventory.take_hoe()
	assert(t1 and Inventory.hoes == 1, "Loi take_hoe lan 1")
	hud.rebuild_hotbar()
	assert(hud._slots_cache.size() > 0 and str(hud._slots_cache[0].get("type")) == "hoe", "Loi: O 1 van phai la cuoc khi hoes=1")

	# Cuoc lan 2 ve 0
	var t2: bool = Inventory.take_hoe()
	assert(t2 and Inventory.hoes == 0, "Loi take_hoe lan 2")
	assert(str(Inventory.active_item.get("type", "")) != "hoe", "Loi: Khi hoes ve 0 active_item phai tu dong chuyen sang cong cu khac!")

	hud.rebuild_hotbar()
	has_hoe_slot = false
	for slot in hud._slots_cache:
		if str(slot.get("type", "")) == "hoe":
			has_hoe_slot = true
			break
	print("7.2 Sau khi cuoc het 2 cuoc ve 0 -> Hotbar con cuoc khong? ", has_hoe_slot)
	assert(not has_hoe_slot, "Loi: Cuoc ve 0 nhung van con hien thi tren hotbar!")

	# Thu chon cuoc khi hoes=0
	Inventory.select_tool("hoe")
	assert(str(Inventory.active_item.get("type", "")) != "hoe", "Loi: Khong the chon cuoc khi hoes == 0!")

	# Khi mua / nhan lai cuoc
	Inventory.add_hoes(5)
	hud.rebuild_hotbar()
	has_hoe_slot = false
	for slot in hud._slots_cache:
		if str(slot.get("type", "")) == "hoe":
			has_hoe_slot = true
			break
	print("7.3 Sau khi nhan them cuoc (5 cuoc) -> Hotbar co lai cuoc khong? ", has_hoe_slot)
	assert(has_hoe_slot, "Loi: Nhan them cuoc nhung hotbar khong hien lai!")

	print("=== TAT CA KIEM THU THANH CONG 100% ===")
	quit(0)


