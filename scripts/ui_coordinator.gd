extends RefCounted
# Quản lý Hệ Thống Giao Diện, Mở/Đóng Bảng Điều Khiển & Menus (UI Coordinator)

const HudScript := preload("res://scripts/ui/hud.gd")
const ShopPanelScript := preload("res://scripts/ui/shop_panel.gd")
const FishShopScript := preload("res://scripts/ui/fish_shop.gd")
const PoultryShopScript := preload("res://scripts/ui/poultry_shop.gd")
const StallPanelScript := preload("res://scripts/ui/stall_panel.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory_panel.gd")
const DialogueBoxScript := preload("res://scripts/ui/dialogue_box.gd")
const TitleScreenScript := preload("res://scripts/ui/title_screen.gd")
const PauseMenuScript := preload("res://scripts/ui/pause_menu.gd")
const MinimapScript := preload("res://scripts/ui/minimap.gd")
const TouchControlsScript := preload("res://scripts/ui/touch_controls.gd")
const MailboxPanelScript := preload("res://scripts/ui/mailbox_panel.gd")
const StoragePanelScript := preload("res://scripts/ui/storage_panel.gd")
const CatPanelScript := preload("res://scripts/ui/cat_panel.gd")
const QuestPanelScript := preload("res://scripts/ui/quest_panel.gd")
const ToolUpgradePanelScript := preload("res://scripts/ui/tool_upgrade_panel.gd")

var main: Node2D

var hud: CanvasLayer
var shop_panel: CanvasLayer
var fish_shop: CanvasLayer
var poultry_shop: CanvasLayer
var stall_panel: CanvasLayer
var inv_panel: CanvasLayer
var storage_panel: CanvasLayer
var cat_panel: CanvasLayer
var mailbox_panel: CanvasLayer
var dialog_box: CanvasLayer
var title_screen: CanvasLayer
var pause_menu: CanvasLayer
var minimap: CanvasLayer
var touch_ui: CanvasLayer
var tool_upgrade_panel: CanvasLayer
var quest_panel: CanvasLayer
var fade_rect: ColorRect


func setup(p_main: Node2D) -> void:
	main = p_main


# Xây dựng toàn bộ các tầng giao diện (CanvasLayers)
func build_ui() -> void:
	hud = HudScript.new()
	main.add_child(hud)
	hud.open_inventory_requested.connect(open_inventory)
	hud.open_storage_requested.connect(open_storage)
	hud.open_cat_requested.connect(open_cat_panel)
	hud.open_stall_requested.connect(main._open_market_stall)

	shop_panel = ShopPanelScript.new()
	main.add_child(shop_panel)

	fish_shop = FishShopScript.new()
	main.add_child(fish_shop)

	poultry_shop = PoultryShopScript.new()
	main.add_child(poultry_shop)

	stall_panel = StallPanelScript.new()
	main.add_child(stall_panel)

	inv_panel = InventoryPanelScript.new()
	main.add_child(inv_panel)

	mailbox_panel = MailboxPanelScript.new()
	main.add_child(mailbox_panel)
	mailbox_panel.closed.connect(close_panels)
	mailbox_panel.changed.connect(on_mailbox_changed)

	storage_panel = StoragePanelScript.new()
	main.add_child(storage_panel)
	storage_panel.closed.connect(close_panels)
	storage_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))

	cat_panel = CatPanelScript.new()
	main.add_child(cat_panel)
	cat_panel.closed.connect(close_panels)
	cat_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))

	quest_panel = QuestPanelScript.new()
	main.add_child(quest_panel)
	quest_panel.setup(main.quest_mgr)
	quest_panel.closed.connect(close_panels)
	quest_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))

	tool_upgrade_panel = ToolUpgradePanelScript.new()
	main.add_child(tool_upgrade_panel)
	tool_upgrade_panel.closed.connect(close_panels)
	tool_upgrade_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))

	hud.setup_quests(main.quest_mgr)
	hud.open_quests_requested.connect(open_quest_panel)

	pause_menu = PauseMenuScript.new()
	main.add_child(pause_menu)

	dialog_box = DialogueBoxScript.new()
	main.add_child(dialog_box)

	title_screen = TitleScreenScript.new()
	main.add_child(title_screen)

	minimap = MinimapScript.new()
	main.add_child(minimap)
	minimap.setup(main.ground.texture, main.player, main.world, main)
	minimap.toast_cb = func(t: String, c: Color) -> void: hud.toast(t, c)

	if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("android") or OS.get_environment("FARM_TOUCH") != "":
		if not DisplayServer.is_touchscreen_available():
			Input.emulate_touch_from_mouse = true
		touch_ui = TouchControlsScript.new()
		main.add_child(touch_ui)
		touch_ui.main = main

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 60
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)


# Kết nối các tín hiệu phản hồi từ panels
func connect_ui_signals() -> void:
	shop_panel.feedback.connect(func(t: String) -> void: hud.toast(t, Color(1.0, 0.9, 0.5)))
	shop_panel.closed.connect(close_panels)

	fish_shop.feedback.connect(func(t: String) -> void: hud.toast(t, Color(0.6, 0.9, 1.0)))
	fish_shop.closed.connect(close_panels)

	poultry_shop.feedback.connect(func(t: String) -> void: hud.toast(t, Color(1.0, 0.7, 0.6)))
	poultry_shop.closed.connect(close_panels)

	stall_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))
	stall_panel.closed.connect(close_panels)
	stall_panel.stall_changed.connect(main._on_stall_changed)
	stall_panel.revenue_collected.connect(main._on_stall_revenue_collected)

	inv_panel.closed.connect(close_panels)
	inv_panel.feedback.connect(func(t: String, c: Color) -> void: hud.toast(t, c))

	dialog_box.finished.connect(main._on_dialog_finished)
	dialog_box.answered.connect(main._on_sleep_answer)

	title_screen.start_requested.connect(main.start_new_game)
	title_screen.continue_requested.connect(main.continue_game)

	pause_menu.resumed.connect(resume_from_pause)
	pause_menu.saved.connect(main._save_now)
	pause_menu.menu_requested.connect(main._back_to_title)


# Mở các Panels
func open_shop() -> void:
	main.mode = main.Mode.PANEL
	main.get_tree().paused = true
	shop_panel.open()


func open_fish_shop() -> void:
	main.mode = main.Mode.PANEL
	main.get_tree().paused = true
	fish_shop.open()


func open_poultry_shop() -> void:
	main.mode = main.Mode.PANEL
	main.get_tree().paused = true
	poultry_shop.open()


func open_tool_upgrade_panel() -> void:
	main.mode = main.Mode.PANEL
	main.get_tree().paused = true
	tool_upgrade_panel.open()


func open_inventory() -> void:
	main.mode = main.Mode.PANEL
	main.get_tree().paused = true
	inv_panel.open()


func open_mailbox() -> void:
	main.mode = main.Mode.PANEL
	main.get_tree().paused = true
	mailbox_panel.open(main.mailbox_data)


func open_storage() -> void:
	main.mode = main.Mode.PANEL
	main.get_tree().paused = true
	storage_panel.open()


func open_cat_panel() -> void:
	main.mode = main.Mode.PANEL
	main.get_tree().paused = true
	cat_panel.open(main.cat_helper)


func open_quest_panel(tab: String = "daily") -> void:
	main.mode = main.Mode.PANEL
	main.get_tree().paused = true
	quest_panel.open(tab)


func on_mailbox_changed() -> void:
	main._update_mailbox_badge()
	hud.rebuild_hotbar()
	main._save_now()


# Đóng tất cả các Panels và đưa về trạng thái chơi PLAY
func close_panels() -> void:
	if shop_panel != null: shop_panel.visible = false
	if fish_shop != null: fish_shop.visible = false
	if poultry_shop != null: poultry_shop.visible = false
	if inv_panel != null: inv_panel.visible = false
	if storage_panel != null: storage_panel.visible = false
	if cat_panel != null: cat_panel.visible = false
	if mailbox_panel != null: mailbox_panel.visible = false
	if stall_panel != null: stall_panel.visible = false
	if quest_panel != null: quest_panel.visible = false
	if tool_upgrade_panel != null: tool_upgrade_panel.visible = false
	if pause_menu != null: pause_menu.visible = false
	main.get_tree().paused = false
	if main.mode != main.Mode.TITLE:
		main.mode = main.Mode.PLAY


func resume_from_pause() -> void:
	if pause_menu != null:
		pause_menu.close()
	main.get_tree().paused = false
	if main.mode != main.Mode.TITLE:
		main.mode = main.Mode.PLAY


func set_current_hint(t: String) -> void:
	if hud != null:
		hud.set_hint(t)
	if touch_ui != null and touch_ui.has_method("set_action_label"):
		touch_ui.set_action_label(t)


func is_any_panel_open() -> bool:
	return (shop_panel != null and shop_panel.visible) \
		or (inv_panel != null and inv_panel.visible) \
		or (fish_shop != null and fish_shop.visible) \
		or (poultry_shop != null and poultry_shop.visible) \
		or (stall_panel != null and stall_panel.visible) \
		or (mailbox_panel != null and mailbox_panel.visible) \
		or (storage_panel != null and storage_panel.visible) \
		or (cat_panel != null and cat_panel.visible) \
		or (quest_panel != null and quest_panel.visible) \
		or (tool_upgrade_panel != null and tool_upgrade_panel.visible) \
		or (pause_menu != null and pause_menu.visible)
