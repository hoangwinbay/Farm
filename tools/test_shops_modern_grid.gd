extends SceneTree

const CropDB := preload("res://scripts/crop_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const TextureGen := preload("res://scripts/texture_gen.gd")

var GameState: Node
var Inventory: Node

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	GameState = root.get_node("GameState")
	Inventory = root.get_node("Inventory")

	print("=== KIỂM THỬ TOÀN DIỆN 3 CỬA HÀNG: DOCK PHẢI, MODAL TRÁI & CLICK THẺ NHẠY 100% ===")

	var click_ev := InputEventMouseButton.new()
	click_ev.button_index = MOUSE_BUTTON_LEFT
	click_ev.pressed = true

	# 1. TIỆM BÁC TƯ (shop_panel.gd)
	print("\n--- 1. Kiểm tra Tiệm Bác Tư (shop_panel.gd) ---")
	var ShopPanelScript = load("res://scripts/ui/shop_panel.gd")
	var shop = ShopPanelScript.new()
	root.add_child(shop)
	shop.open()
	await process_frame

	# Kiểm tra dock nằm bên phải màn hình (x=790)
	var root_ctrl = shop.get_child(0) as Control
	var panel = root_ctrl.get_child(2) as PanelContainer
	var p_rect = panel.get_global_rect()
	print("  -> Vị trí panel Tiệm Bác Tư: ", p_rect)
	assert(p_rect.position.x == 790.0 and p_rect.size.x == 490.0, "Panel Bác Tư phải neo ở x=790, rộng 490px!")

	# Kiểm tra 3 tab
	assert(shop._cat_buttons.has("seeds"), "Bác Tư phải có tab 'seeds' (Mua hạt)!")
	assert(shop._cat_buttons.has("tools"), "Bác Tư phải có tab 'tools' (Mua cuốc)!")
	assert(shop._cat_buttons.has("produce"), "Bác Tư phải có tab 'produce' (Bán nông sản)!")

	# Test click thẻ hạt giống mở modal
	shop._set_category("seeds")
	var seed_grid: GridContainer = shop.rows.get_child(0) as GridContainer
	var first_seed_card: Control = seed_grid.get_child(0) as Control
	
	# Click trực tiếp lên thẻ PanelContainer
	shop._hide_info_modal()
	first_seed_card.gui_input.emit(click_ev)
	assert(shop._modal_root.visible == true, "Click vào thân thẻ hạt giống phải mở Modal!")
	print("  -> Đạt: Click vào thân thẻ hạt giống mở modal thành công.")

	# Click vào TextureRect icon của thẻ
	shop._hide_info_modal()
	var seed_ic: TextureRect = null
	var seed_name: Label = null
	for c in first_seed_card.get_children():
		for c2 in c.get_children():
			if c2 is TextureRect: seed_ic = c2
			elif c2 is Label and not (c2.get_parent() is PanelContainer): seed_name = c2
	assert(seed_ic != null and seed_name != null, "Phải tìm thấy icon và label trên thẻ!")
	seed_ic.gui_input.emit(click_ev)
	assert(shop._modal_root.visible == true, "Click vào icon hạt giống phải mở Modal!")
	print("  -> Đạt: Click vào icon hạt giống mở modal thành công.")

	# Click vào Label tên của thẻ
	shop._hide_info_modal()
	seed_name.gui_input.emit(click_ev)
	assert(shop._modal_root.visible == true, "Click vào tên hạt giống phải mở Modal!")
	print("  -> Đạt: Click vào tên hạt giống mở modal thành công.")

	# Kiểm tra vị trí của Modal chi tiết (nằm ở nửa trái x=0..790)
	var m_center: Control = shop._modal_root.get_child(1) as Control
	var m_card: Control = m_center.get_child(0) as Control
	var m_rect = m_card.get_global_rect()
	print("  -> Vị trí Modal chi tiết: ", m_rect)
	assert(m_rect.position.x < 790.0, "Modal chi tiết phải nằm ở vùng bên trái, không đè lên cửa hàng bên phải!")
	shop.close()

	# 2. TRẠI GIỐNG CÔ TƯ (poultry_shop.gd)
	print("\n--- 2. Kiểm tra Trại Giống Cô Tư (poultry_shop.gd) ---")
	var PoultryShopScript = load("res://scripts/ui/poultry_shop.gd")
	var poultry = PoultryShopScript.new()
	root.add_child(poultry)
	poultry.open()
	await process_frame

	var p_panel = poultry.get_child(0).get_child(2) as PanelContainer
	var poultry_p_rect = p_panel.get_global_rect()
	print("  -> Vị trí panel Trại Giống Cô Tư: ", poultry_p_rect)
	assert(poultry_p_rect.position.x == 790.0 and poultry_p_rect.size.x == 490.0, "Panel Cô Tư phải neo ở x=790!")

	# Kiểm tra 3 tab
	assert(poultry._cat_buttons.has("animals"), "Cô Tư phải có tab 'animals'!")
	assert(poultry._cat_buttons.has("coops"), "Cô Tư phải có tab 'coops'!")
	assert(poultry._cat_buttons.has("products"), "Cô Tư phải có tab 'products'!")

	# Test click thẻ con giống
	poultry._set_category("animals")
	var a_grid: GridContainer = poultry.rows.get_child(0) as GridContainer
	var first_a_card: Control = a_grid.get_child(0) as Control

	poultry._hide_info_modal()
	first_a_card.gui_input.emit(click_ev)
	assert(poultry._modal_root.visible == true, "Click vào thân thẻ con giống phải mở Modal!")
	print("  -> Đạt: Click thẻ con giống mở modal thành công.")

	# Click icon con giống
	poultry._hide_info_modal()
	var a_ic: TextureRect = null
	for c in first_a_card.get_children():
		for c2 in c.get_children():
			if c2 is TextureRect: a_ic = c2
	a_ic.gui_input.emit(click_ev)
	assert(poultry._modal_root.visible == true, "Click icon con giống phải mở Modal!")
	print("  -> Đạt: Click icon con giống mở modal thành công.")
	poultry.close()

	# 3. BẾN CÁ CHÚ HAI (fish_shop.gd)
	print("\n--- 3. Kiểm tra Bến Cá Chú Hai (fish_shop.gd) ---")
	var FishShopScript = load("res://scripts/ui/fish_shop.gd")
	var fish_shop = FishShopScript.new()
	root.add_child(fish_shop)
	fish_shop.open()
	await process_frame

	var f_panel = fish_shop.get_child(0).get_child(2) as PanelContainer
	var fish_p_rect = f_panel.get_global_rect()
	print("  -> Vị trí panel Bến Cá Chú Hai: ", fish_p_rect)
	assert(fish_p_rect.position.x == 790.0 and fish_p_rect.size.x == 490.0, "Panel Chú Hai phải neo ở x=790!")

	# Kiểm tra 3 tab
	assert(fish_shop._cat_buttons.has("rods"), "Chú Hai phải có tab 'rods'!")
	assert(fish_shop._cat_buttons.has("bait"), "Chú Hai phải có tab 'bait'!")
	assert(fish_shop._cat_buttons.has("fish"), "Chú Hai phải có tab 'fish'!")

	# Test click thẻ cần câu
	fish_shop._set_category("rods")
	var rod_grid: GridContainer = fish_shop.rows.get_child(0) as GridContainer
	var first_rod_card: Control = rod_grid.get_child(0) as Control

	fish_shop._hide_info_modal()
	first_rod_card.gui_input.emit(click_ev)
	assert(fish_shop._modal_root.visible == true, "Click vào thân thẻ cần câu phải mở Modal!")
	print("  -> Đạt: Click thẻ cần câu mở modal thành công.")

	# Click icon cần câu
	fish_shop._hide_info_modal()
	var rod_ic: TextureRect = null
	for c in first_rod_card.get_children():
		for c2 in c.get_children():
			if c2 is TextureRect: rod_ic = c2
	rod_ic.gui_input.emit(click_ev)
	assert(fish_shop._modal_root.visible == true, "Click icon cần câu phải mở Modal!")
	print("  -> Đạt: Click icon cần câu mở modal thành công.")
	fish_shop.close()

	print("\n=== TẤT CẢ KIỂM THỬ THÀNH CÔNG RỰC RỠ 100%! CỬA HÀNG NEO PHẢI, MODAL TRÁI, CLICK NHẠY MỌI ĐIỂM! ===")
	quit(0)
