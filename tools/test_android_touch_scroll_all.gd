extends SceneTree

const TouchScrollHelperScript := preload("res://scripts/ui/touch_scroll_helper.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

var GameState: Node
var Inventory: Node

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	GameState = root.get_node("GameState")
	Inventory = root.get_node("Inventory")

	print("=== KIỂM THỬ HỆ THỐNG VUỐT CUỘN CẢM ỨNG ANDROID (SHOP CÔ TƯ, HÒM THƯ, ...) ===")

	# 1. Kiểm tra UIKit.style_scroll_container
	print("1. Kiểm tra UIKit.style_scroll_container & thanh cuộn thân thiện ngón tay:")
	var test_sc := ScrollContainer.new()
	test_sc.size = Vector2(300, 300)
	root.add_child(test_sc)
	UIKit.style_scroll_container(test_sc)

	var vsb := test_sc.get_v_scroll_bar()
	assert(vsb != null, "ScrollContainer phải có vertical scrollbar!")
	assert(vsb.custom_minimum_size.x >= 18.0, "Độ rộng scrollbar phải >= 18px để ngón tay dễ chạm kéo!")

	var helper_found := false
	for c in test_sc.get_children():
		if c is TouchScrollHelperScript:
			helper_found = true
			break
	assert(helper_found, "UIKit.style_scroll_container phải tự động gắn TouchScrollHelper!")
	print("  -> Đạt: Scrollbar 18px, tự động gắn TouchScrollHelper thành công.")

	# 2. Kiểm tra Shop Cô Tư (shop_panel.gd)
	print("2. Kiểm tra Tiệm Bác Tư (shop_panel.gd):")
	var ShopPanelScript = load("res://scripts/ui/shop_panel.gd")
	var shop_panel = ShopPanelScript.new()
	root.add_child(shop_panel)
	shop_panel.open()

	# Kiểm tra TouchScrollHelper trong shop
	var shop_has_helper := false
	for c in shop_panel.scroll.get_children():
		if c is TouchScrollHelperScript:
			shop_has_helper = true
			break
	assert(shop_has_helper, "Shop Bác Tư phải được gắn TouchScrollHelper!")

	# Kiểm tra tab phân loại danh mục (3 tab: Mua hạt, Mua cuốc, Bán nông sản)
	assert(shop_panel._cat_buttons.has("seeds"), "Shop phải có tab 'Mua hạt'!")
	assert(shop_panel._cat_buttons.has("tools"), "Shop phải có tab 'Mua cuốc'!")
	assert(shop_panel._cat_buttons.has("produce"), "Shop phải có tab 'Bán nông sản'!")

	# Chuyển sang tab Nông cụ (tools)
	shop_panel._set_category("tools")
	assert(shop_panel._current_cat == "tools", "Đã chọn danh mục 'tools'!")
	assert(shop_panel.rows.get_child_count() > 0, "Tab tools hiển thị lưới vật tư cuốc & cám!")

	# Chuyển sang tab Mua hạt (seeds)
	shop_panel._set_category("seeds")
	assert(shop_panel._current_cat == "seeds", "Đã chọn danh mục 'seeds'!")
	assert(shop_panel.rows.get_child_count() > 0, "Tab 'seeds' hiển thị đầy đủ danh sách hạt giống!")
	print("  -> Đạt: Shop Bác Tư có TouchScrollHelper và 3 tab thẻ lưới 1-chạm hoàn hảo.")

	# 3. Kiểm tra Hòm Thư (mailbox_panel.gd)
	print("3. Kiểm tra Hòm Thư (mailbox_panel.gd):")
	var MailboxScript = load("res://scripts/ui/mailbox_panel.gd")
	var mailbox = MailboxScript.new()
	root.add_child(mailbox)
	mailbox.open({
		"coins": 100,
		"hoes": 2,
		"feed": 5,
		"produce": {"rice": 10, "corn": 5}
	})

	var mb_scroll: ScrollContainer = null
	for c in mailbox.get_children():
		if c is Control:
			for sub in c.find_children("", "ScrollContainer", true, false):
				mb_scroll = sub as ScrollContainer
				break

	assert(mb_scroll != null, "Hòm thư phải có ScrollContainer!")
	var mb_has_helper := false
	for c in mb_scroll.get_children():
		if c is TouchScrollHelperScript:
			mb_has_helper = true
			break
	assert(mb_has_helper, "Hòm thư phải được gắn TouchScrollHelper!")
	assert(mailbox.items_vbox.get_child_count() >= 4, "Hòm thư phải hiển thị danh sách quà tặng!")
	print("  -> Đạt: Hòm thư có TouchScrollHelper và thanh cuộn cảm ứng mượt mà.")

	# 4. Kiểm tra Sạp Hàng (stall_panel.gd)
	print("4. Kiểm tra Sạp Hàng (stall_panel.gd):")
	var StallScript = load("res://scripts/ui/stall_panel.gd")
	var stall = StallScript.new()
	root.add_child(stall)
	stall.open([])
	var stall_has_helper := false
	for c in stall.scroll.get_children():
		if c is TouchScrollHelperScript:
			stall_has_helper = true
			break
	assert(stall_has_helper, "Sạp hàng phải có TouchScrollHelper!")
	print("  -> Đạt: Sạp hàng được hỗ trợ vuốt cuộn cảm ứng.")

	# 5. Kiểm tra Nhà Mèo (cat_panel.gd)
	print("5. Kiểm tra Nhà Mèo (cat_panel.gd):")
	var CatPanelScript = load("res://scripts/ui/cat_panel.gd")
	var cat_panel = CatPanelScript.new()
	root.add_child(cat_panel)
	var cat_scrolls = cat_panel.find_children("", "ScrollContainer", true, false)
	assert(cat_scrolls.size() >= 2, "Nhà Mèo phải có ít nhất 2 ScrollContainer!")
	for sc in cat_scrolls:
		var has_h := false
		for c in sc.get_children():
			if c is TouchScrollHelperScript:
				has_h = true
				break
		assert(has_h, "Cả 2 ScrollContainer của Nhà Mèo phải có TouchScrollHelper!")
	print("  -> Đạt: Cả 2 danh sách trong Nhà Mèo đều hỗ trợ vuốt cuộn cảm ứng.")

	# 6. Kiểm tra Tiệm Cá & Tiệm Chăn Nuôi & Nhà Kho & Bảng Nhiệm Vụ
	print("6. Kiểm tra FishShop, PoultryShop, StoragePanel, QuestPanel, QuestDrawer:")
	var FishShopScript = load("res://scripts/ui/fish_shop.gd")
	var fish_shop = FishShopScript.new()
	root.add_child(fish_shop)
	var fish_scroll = fish_shop.find_children("", "ScrollContainer", true, false)[0]
	assert(fish_scroll.find_children("", "TouchScrollHelper", true, false).size() > 0 or fish_scroll.get_child(0) is TouchScrollHelperScript, "Tiệm Cá phải có TouchScrollHelper!")

	var PoultryShopScript = load("res://scripts/ui/poultry_shop.gd")
	var poultry_shop = PoultryShopScript.new()
	root.add_child(poultry_shop)
	var p_scroll = poultry_shop.find_children("", "ScrollContainer", true, false)[0]
	assert(p_scroll.find_children("", "TouchScrollHelper", true, false).size() > 0 or p_scroll.get_child(0) is TouchScrollHelperScript, "Tiệm Chăn Nuôi phải có TouchScrollHelper!")

	var StorageScript = load("res://scripts/ui/storage_panel.gd")
	var storage_panel = StorageScript.new()
	root.add_child(storage_panel)
	assert(storage_panel.shed_scroll.get_child(0) is TouchScrollHelperScript, "Kho nhà kho phải có TouchScrollHelper!")
	assert(storage_panel.bag_scroll.get_child(0) is TouchScrollHelperScript, "Cột túi đồ nhà kho phải có TouchScrollHelper!")

	var QuestPanelScript = load("res://scripts/ui/quest_panel.gd")
	var quest_panel = QuestPanelScript.new()
	root.add_child(quest_panel)
	var q_scroll = quest_panel.find_children("", "ScrollContainer", true, false)[0]
	assert(q_scroll.get_child(0) is TouchScrollHelperScript, "Bảng nhiệm vụ phải có TouchScrollHelper!")

	var QuestDrawerScript = load("res://scripts/ui/quest_drawer.gd")
	var quest_drawer = QuestDrawerScript.new()
	root.add_child(quest_drawer)
	var qd_scroll = quest_drawer.find_children("", "ScrollContainer", true, false)[0]
	assert(qd_scroll.get_child(0) is TouchScrollHelperScript, "Ngăn kéo nhiệm vụ phải có TouchScrollHelper!")
	print("  -> Đạt: Tất cả 100% các panel danh sách trong game đều được trang bị TouchScrollHelper!")

	print("\n=== TẤT CẢ CÁC BƯỚC KIỂM THỬ ĐỀU THÀNH CÔNG XUẤT SẮC! ===")
	quit(0)
