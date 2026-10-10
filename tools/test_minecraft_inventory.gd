extends SceneTree

var GameState: Node
var Inventory: Node

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	GameState = root.get_node("GameState")
	Inventory = root.get_node("Inventory")

	print("=== BẮT ĐẦU KIỂM TRA HỆ THỐNG TÚI ĐỒ VÀ THANH CÔNG CỤ MINECRAFT ===")

	# 1. Kiểm tra kích thước và hằng số
	print("1. Kiểm tra kích thước ô:")
	assert(Inventory.HOTBAR_SIZE == 9, "Hotbar phải có đúng 9 ô!")
	assert(Inventory.BACKPACK_SIZE == 20, "Balo phải có đúng 20 ô!")
	assert(Inventory.backpack_max == 20, "backpack_max phải là 20!")
	print("  -> Đạt: Hotbar 9 ô, Balo 20 ô, Sức chứa balo 20 ô.")

	# 2. Reset và kiểm tra trạng thái khởi tạo
	print("2. Kiểm tra khởi tạo sau khi reset:")
	Inventory.reset()
	assert(Inventory.hotbar_slots.size() == 9, "Hotbar slots array phải có size 9!")
	assert(Inventory.backpack_slots.size() == 20, "Backpack slots array phải có size 20!")
	var s1 = Inventory.get_hotbar_slot(1)
	assert(str(s1.get("type", "")) == "watering_can", "Ô 1 hotbar phải chứa bình nước!")
	assert(int(s1.get("qty", 0)) == 20, "Bình nước phải đầy 20 gáo!")
	print("  -> Đạt: Khởi tạo sạch sẽ, bình nước đặt vào ô hotbar 1.")

	# 3. Thêm cuốc và hạt giống
	print("3. Kiểm tra tự động fill vào thanh công cụ:")
	Inventory.add_hoes(1)
	var hoe_slot = Inventory.get_hotbar_slot(0)
	assert(str(hoe_slot.get("type", "")) == "hoe", "Cuốc phải tự động fill vào ô trống đầu tiên (ô 0)!")
	assert(int(hoe_slot.get("qty", 0)) == 1, "Số lượng cuốc là 1.")

	Inventory.add_seed("rice", 10)
	var rice_slot = Inventory.get_hotbar_slot(2)
	assert(str(rice_slot.get("type", "")) == "seed" and str(rice_slot.get("id", "")) == "rice", "Hạt lúa phải vào ô 2 hotbar!")
	assert(int(rice_slot.get("qty", 0)) == 10, "Số lượng hạt lúa là 10.")
	print("  -> Đạt: Cuốc vào ô 0, Hạt lúa vào ô 2.")

	# 4. Kiểm tra chọn ô hotbar và active_item
	print("4. Kiểm tra chọn phím tắt và đổi vật phẩm cầm trên tay:")
	Inventory.select_hotbar_slot(0)
	assert(str(Inventory.active_item.get("type", "")) == "hoe", "Cầm ô 0 phải là cuốc!")
	Inventory.select_hotbar_slot(1)
	assert(str(Inventory.active_item.get("type", "")) == "watering_can", "Cầm ô 1 phải là bình tưới!")
	Inventory.select_hotbar_slot(2)
	assert(str(Inventory.active_item.get("type", "")) == "seed" and Inventory.selected_seed == "rice", "Cầm ô 2 phải là hạt lúa!")
	Inventory.select_hotbar_slot(5)
	assert(str(Inventory.active_item.get("type", "")) == "hand", "Cầm ô trống phải là tay không!")
	print("  -> Đạt: Chọn ô 0..8 đồng bộ chuẩn xác với active_item.")

	# 5. Đổ đầy 9 ô hotbar để test cơ chế fill vào balo
	print("5. Đổ đầy 9 ô hotbar và kiểm tra tràn vào balo:")
	Inventory.add_seed("corn", 5)       # ô 3
	Inventory.add_seed("carrot", 5)     # ô 4
	Inventory.add_ore("copper_ore", 3)  # ô 5
	Inventory.add_ore("iron_ore", 2)    # ô 6
	Inventory.add_fish("carp", 1)       # ô 7
	Inventory.add_produce("thit_ga", 4) # ô 8
	for i in 9:
		assert(not Inventory.get_hotbar_slot(i).is_empty(), "Ô hotbar %d phải có đồ!" % i)

	# Thêm món mới: cá rô ("ro_phi") -> Phải tự tràn vào Balo ô 0!
	Inventory.add_fish("ro_phi", 2)
	var bp0 = Inventory.get_backpack_slot(0)
	assert(not bp0.is_empty(), "Balo ô 0 phải nhận món mới khi hotbar đã full!")
	assert(str(bp0.get("type", "")) == "fish" and str(bp0.get("id", "")) == "ro_phi", "Balo ô 0 phải là cá rô phi!")
	print("  -> Đạt: Khi hotbar đầy 9 ô, vật phẩm mới tự động tràn vào Balo.")

	# 6. Kiểm tra nút "Lấy ra" (move_backpack_to_hotbar) khi hotbar đang FULL
	print("6. Kiểm tra 'Lấy ra' khi hotbar full (cơ chế thay thế ô đang chọn):")
	Inventory.select_hotbar_slot(5)
	assert(str(Inventory.get_hotbar_slot(5).get("id", "")) == "copper_ore", "Ô 5 đang là copper_ore.")

	# Bấm "Lấy ra" cá rô phi từ Balo ô 0:
	var move_ok = Inventory.move_backpack_to_hotbar(0)
	assert(move_ok, "Phải thực hiện thay thế thành công!")
	assert(str(Inventory.get_hotbar_slot(5).get("id", "")) == "ro_phi", "Ô 5 hotbar phải được thay thế bằng ro_phi!")
	assert(str(Inventory.get_backpack_slot(0).get("id", "")) == "copper_ore", "Balo ô 0 phải nhận lại món bị thay thế (copper_ore)!")
	print("  -> Đạt: Thay thế hoàn hảo giữa ô hotbar đang chọn và Balo!")

	# 7. Kiểm tra nút "Lấy ra" khi hotbar CÒN TRỐNG
	print("7. Kiểm tra 'Lấy ra' khi hotbar còn ô trống:")
	Inventory.move_hotbar_to_backpack(8)
	assert(Inventory.get_hotbar_slot(8).is_empty(), "Ô 8 hotbar phải trống!")

	var move_to_empty = Inventory.move_backpack_to_hotbar(0)
	assert(move_to_empty, "Phải lấy ra thành công!")
	assert(Inventory.get_backpack_slot(0).is_empty(), "Balo ô 0 phải trở thành trống!")
	assert(str(Inventory.get_hotbar_slot(8).get("id", "")) == "copper_ore", "Ô 8 hotbar vừa trống phải được fill copper_ore!")
	print("  -> Đạt: Tự động điền vào ô trống đầu tiên của hotbar.")

	# 8. Kiểm tra Kéo thả / Hoán đổi (swap_slots):
	print("8. Kiểm tra kéo thả hoán đổi ô (Drag & Drop):")
	Inventory.swap_slots("backpack", 1, "backpack", 10)
	assert(str(Inventory.get_backpack_slot(10).get("id", "")) == "thit_ga", "Balo ô 10 phải nhận thit_ga!")
	assert(Inventory.get_backpack_slot(1).is_empty(), "Balo ô 1 phải trống!")

	Inventory.swap_slots("backpack", 10, "hotbar", 2)
	assert(str(Inventory.get_hotbar_slot(2).get("id", "")) == "thit_ga", "Hotbar ô 2 nhận thit_ga!")
	assert(str(Inventory.get_backpack_slot(10).get("id", "")) == "rice", "Balo ô 10 nhận lại rice!")
	print("  -> Đạt: Kéo thả hoán đổi vị trí mượt mà chuẩn Minecraft.")

	# 9. Kiểm tra Giao diện InventoryPanel & HUD Hotbar Kéo thả
	# 9. Kiểm tra Giao diện InventoryPanel (Popup gồm Balo 20 ô + Hotbar 9 ô)
	print("9. Kiểm tra UI InventoryPanel (Popup Balo 20 ô + Hotbar 9 ô):")
	var InvPanelScript = load("res://scripts/ui/inventory_panel.gd")
	var inv_panel = InvPanelScript.new()
	root.add_child(inv_panel)
	inv_panel.open()
	assert(inv_panel.visible, "InventoryPanel mở hiển thị bình thường!")
	assert(inv_panel.backpack_grid.get_child_count() == Inventory.backpack_max + 1, "Lưới Balo phải tạo 20 ô vật phẩm + 1 ô dấu cộng để mua thêm!")
	assert(inv_panel.hotbar_grid.get_child_count() == 9, "Lưới Hotbar trong popup phải tạo đúng 9 ô Button!")

	# Kiểm tra nút thao tác tối giản đúng chữ "Lấy ra" và "Ăn" khi chọn Balo
	inv_panel.select_slot("backpack", 10) # Ô 10 đang có rice
	assert(inv_panel.detail_title.text != "", "Tiêu đề chi tiết phải hiển thị tên vật phẩm!")
	var action_btn_texts: Array[String] = []
	for c in inv_panel.actions_container.get_children():
		if c is Button:
			action_btn_texts.append(c.text)
	assert("Lấy ra" in action_btn_texts, "Nút lấy ra phải tối giản đúng chữ 'Lấy ra'!")

	# Kiểm tra kéo thả từ Balo sang Hotbar ngay trong popup
	var bp_btn = inv_panel.backpack_grid.get_child(10)
	var drag_data = bp_btn._get_drag_data(Vector2.ZERO)
	assert(drag_data != null and drag_data.get("source_area") == "backpack", "Nút Balo tạo dữ liệu drag chuẩn!")

	var hb_btn = inv_panel.hotbar_grid.get_child(8) # Thả vào ô 8 của thanh hotbar trong popup
	assert(hb_btn._can_drop_data(Vector2.ZERO, drag_data), "Hotbar nhận dữ liệu drop từ Balo!")
	hb_btn._drop_data(Vector2.ZERO, drag_data)
	assert(not Inventory.get_hotbar_slot(8).is_empty(), "Hotbar ô 8 đã nhận vật phẩm kéo từ Balo!")

	# Kiểm tra nút "Cất" khi chọn ô trên Hotbar
	inv_panel.select_slot("hotbar", 8)
	var hb_btn_texts: Array[String] = []
	for c in inv_panel.actions_container.get_children():
		if c is Button:
			hb_btn_texts.append(c.text)
	assert("Cất" in hb_btn_texts, "Nút cất đồ từ hotbar vào balo phải tối giản đúng chữ 'Cất'!")

	print("  -> Đạt: Popup tích hợp Balo + Hotbar 9 ô, nền tối toàn bộ, nút tối giản 'Lấy ra' / 'Cất' / 'Ăn'.")

	# 10. Kiểm tra Mua slot túi đồ bằng vàng (Giới hạn tối đa 64 ô)
	print("10. Kiểm tra Mua slot túi đồ bằng vàng (Giới hạn 64):")
	assert(Inventory.BACKPACK_MAX_LIMIT == 64, "Giới hạn túi đồ phải là 64 ô!")
	assert(Inventory.backpack_max == 20, "Khởi điểm túi đồ có 20 ô!")

	var initial_cost = Inventory.get_backpack_upgrade_cost()
	assert(initial_cost == 50, "Chi phí mở ô 21 phải là 50 xu!")

	# Thử mua khi không đủ tiền
	GameState.money = 10
	var fail_res = Inventory.upgrade_backpack()
	assert(not fail_res.ok, "Không thể mua khi thiếu tiền!")
	assert(Inventory.backpack_max == 20, "Số ô không đổi khi thất bại!")

	# Mua 1 ô khi đủ tiền
	GameState.money = 200
	var succ_res = Inventory.upgrade_backpack()
	assert(succ_res.ok, "Mua ô thành công khi đủ tiền!")
	assert(Inventory.backpack_max == 21, "Số ô tăng lên 21!")
	assert(GameState.money == 150, "Đã trừ đúng 50 xu (còn 150)!")
	assert(Inventory.backpack_slots.size() == 21, "Mảng backpack_slots mở rộng lên 21 ô!")

	# Chi phí ô tiếp theo
	assert(Inventory.get_backpack_upgrade_cost() == 60, "Chi phí mở ô 22 tăng lên 60 xu!")

	# Nâng cấp thẳng lên 64 ô
	GameState.money = 100000
	while Inventory.backpack_max < 64:
		var r = Inventory.upgrade_backpack()
		assert(r.ok, "Nâng cấp từng ô liên tục thành công!")

	assert(Inventory.backpack_max == 64, "Túi đồ đạt đúng giới hạn tối đa 64 ô!")
	assert(Inventory.backpack_slots.size() == 64, "Mảng backpack_slots có đúng 64 ô!")
	assert(Inventory.get_backpack_upgrade_cost() == -1, "Khi đạt 64 ô, chi phí trả về -1!")
	assert(not Inventory.can_upgrade_backpack(), "Không thể nâng cấp vượt quá 64!")

	var max_res = Inventory.upgrade_backpack()
	assert(not max_res.ok, "Thử nâng cấp khi đã 64 ô phải bị chặn!")

	# Kiểm tra UI phân trang Android cập nhật đúng 64 ô
	inv_panel.refresh()
	assert(inv_panel._get_total_pages() == 4, "Túi đồ 64 ô phải chia thành 4 trang (20 ô/trang)!")
	assert(inv_panel.backpack_grid.get_child_count() == 20, "Trang 1 phải hiển thị đúng 20 ô!")
	assert(inv_panel.upgrade_btn.disabled, "Nút nâng cấp phải bị vô hiệu hóa khi đạt 64!")
	assert(inv_panel.upgrade_btn.text == "Tối đa (64 ô)", "Nút phải hiển thị 'Tối đa (64 ô)'!")

	# Kiểm tra chuyển sang trang cuối (Trang 4 - index 3):
	inv_panel._set_page(3)
	assert(inv_panel.backpack_grid.get_child_count() == 4, "Trang 4 (cuối) phải hiển thị 4 ô còn lại (60..63)!")
	assert(inv_panel.page_pills_container.get_child_count() == 4, "Phải có đúng 4 nút tab trang [1] [2] [3] [4]!")
	assert(inv_panel.next_page_btn.disabled, "Ở trang cuối nút mũi tên tới phải bị disabled!")

	# Chuyển lùi lại trang trước bằng _change_page(-1)
	inv_panel._change_page(-1)
	assert(inv_panel._current_page == 2, "Lùi trang thành công về trang 3 (index 2)!")
	assert(inv_panel.backpack_grid.get_child_count() == 20, "Trang 3 hiển thị đủ 20 ô!")

	print("  -> Đạt: Mua ô bằng vàng, chi phí tăng dần, chặn chặt chẽ tại 64 ô, phân trang 4 trang mượt mà.")

	print("\n=== TOÀN BỘ 10 BƯỚC KIỂM TRA ĐỀU THÀNH CÔNG VƯỢT TRỘI! ===")
	quit(0)
