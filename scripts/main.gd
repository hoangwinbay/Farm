extends Node2D
# Bộ điều phối chính (Game Coordinator): quản lý vòng chơi, UI, điều phối các hệ thống.
# Các chức năng nghiệp vụ được phân tách ra các module chuyên biệt:
# - FarmingController       (scripts/farming_controller.gd)       : Trồng cây, cuốc đất, tưới nước, thu hoạch, thể lực
# - PenManager              (scripts/pen_manager.gd)              : Chăn nuôi, chuồng trại 2x2, cho ăn, sản phẩm chăn nuôi
# - FishingManager          (scripts/fishing_manager.gd)          : Câu cá, phao câu, gợn sóng nước, múc nước hồ
# - StallManager            (scripts/stall_manager.gd)            : Sạp hàng nông sản, khách Stardew Valley, doanh thu
# - WorldBuilder            (scripts/world_builder.gd)            : Xây dựng bản đồ, công trình, hàng rào, cây cối ngẫu nhiên
# - InteractionManager      (scripts/interaction_manager.gd)      : Hệ thống tương tác, gợi ý [E], hội thoại NPC
# - DayNightCycle           (scripts/day_night_cycle.gd)          : Chu kỳ ngày/đêm, ánh sáng môi trường (_tint), ngủ nghỉ (_do_sleep)
# - SaveLoadManager         (scripts/save_load_manager.gd)        : Lưu/tải dữ liệu game, khởi tạo phiên chơi mới & tiếp tục
# - MineTransitionManager   (scripts/mine_transition_manager.gd)  : Hiệu ứng mờ dần và chuyển cảnh hầm mỏ
# - UICoordinator           (scripts/ui_coordinator.gd)           : Quản lý các tầng giao diện, mở/đóng các panel và menu
# - GameLoopManager         (scripts/game_loop_manager.gd)        : Quản lý vòng lặp khung hình, cập nhật logic thế giới
# - InputController         (scripts/input_controller.gd)         : Quản lý xử lý phím bấm & thao tác chuột đầu vào
# - ManagerRegistry         (scripts/manager_registry.gd)         : Đăng ký & khởi tạo tất cả các module quản lý
# - WorldAssembler          (scripts/world_assembler.gd)          : Lắp ráp thế giới, nông trại, nhân vật & thực thể
# - GameBootstrapper        (scripts/game_bootstrapper.gd)        : Khởi động vòng đời trò chơi & kết nối tín hiệu
# - DebugRunner             (scripts/debug_runner.gd)             : Chế độ debug chụp ảnh và kiểm thử tự động
# - ClicktestRunner         (scripts/clicktest_runner.gd)         : Kịch bản Clicktest tự động di chuyển & kiểm tra

const TextureGen := preload("res://scripts/texture_gen.gd")
const CropDB := preload("res://scripts/crop_db.gd")
const FarmScript := preload("res://scripts/farm.gd")
const PlayerScript := preload("res://scripts/player.gd")
const CatHelperScript := preload("res://scripts/cat_helper.gd")
const MineManagerScript := preload("res://scripts/mine_manager.gd")
const WeatherManagerScript := preload("res://scripts/weather_manager.gd")
const QuestManagerScript := preload("res://scripts/quest_manager.gd")
const PenAnimal := preload("res://scripts/pen_animal.gd")

# Các Module chức năng riêng
const FarmingControllerScript := preload("res://scripts/farming_controller.gd")
const PenManagerScript := preload("res://scripts/pen_manager.gd")
const FishingManagerScript := preload("res://scripts/fishing_manager.gd")
const StallManagerScript := preload("res://scripts/stall_manager.gd")
const WorldBuilderScript := preload("res://scripts/world_builder.gd")
const InteractionManagerScript := preload("res://scripts/interaction_manager.gd")
const DayNightCycleScript := preload("res://scripts/day_night_cycle.gd")
const SaveLoadManagerScript := preload("res://scripts/save_load_manager.gd")
const MineTransitionManagerScript := preload("res://scripts/mine_transition_manager.gd")
const UICoordinatorScript := preload("res://scripts/ui_coordinator.gd")
const GameLoopManagerScript := preload("res://scripts/game_loop_manager.gd")
const InputControllerScript := preload("res://scripts/input_controller.gd")
const ManagerRegistryScript := preload("res://scripts/manager_registry.gd")
const WorldAssemblerScript := preload("res://scripts/world_assembler.gd")
const GameBootstrapperScript := preload("res://scripts/game_bootstrapper.gd")
const DebugRunnerScript := preload("res://scripts/debug_runner.gd")
const ClicktestRunnerScript := preload("res://scripts/clicktest_runner.gd")

# Tái xuất hằng số để tương thích tuyệt đối với các script bên ngoài
const WORLD_SIZE := WorldBuilderScript.WORLD_SIZE
const PLOT_NORTH_ORIGIN := FarmingControllerScript.PLOT_NORTH_ORIGIN
const PLOT_SOUTH_ORIGIN := FarmingControllerScript.PLOT_SOUTH_ORIGIN
const PLOT_TILES := FarmingControllerScript.PLOT_TILES
const FARM_ORIGIN := FarmingControllerScript.FARM_ORIGIN
const FARM_TILES := FarmingControllerScript.FARM_TILES
const FARM_PLOTS := FarmingControllerScript.FARM_PLOTS
const HOUSE_POS := WorldBuilderScript.HOUSE_POS
const SHED_POS := WorldBuilderScript.SHED_POS
const TENT_POS := WorldBuilderScript.TENT_POS
const MAILBOX_POS := WorldBuilderScript.MAILBOX_POS
const MAYOR_POS := WorldBuilderScript.MAYOR_POS
const MARKET_STALL_POS := WorldBuilderScript.MARKET_STALL_POS
const MINE_ENTRANCE_POS := WorldBuilderScript.MINE_ENTRANCE_POS
const MINE_SIGN_POS := WorldBuilderScript.MINE_SIGN_POS
const LEAH_MINER_POS := WorldBuilderScript.LEAH_MINER_POS
const SDV_CUSTOMERS_DATA := StallManagerScript.SDV_CUSTOMERS_DATA
const SDV_CUSTOMERS := StallManagerScript.SDV_CUSTOMERS
const STALL_COUNTER_SPOTS := StallManagerScript.STALL_COUNTER_SPOTS
const STALL_WISHLIST_ITEMS := StallManagerScript.STALL_WISHLIST_ITEMS
const STAND_POS := WorldBuilderScript.STAND_POS
const STAND_HAI_POS := WorldBuilderScript.STAND_HAI_POS
const STAND_TU_POS := WorldBuilderScript.STAND_TU_POS
const NPC_POS := Vector2(1580, 430)
const CHU_HAI_POS := Vector2(1750, 430)
const COTU_POS := Vector2(1410, 430)
const SCARECROW_NORTH_POS := WorldBuilderScript.SCARECROW_NORTH_POS
const SCARECROW_SOUTH_POS := WorldBuilderScript.SCARECROW_SOUTH_POS
const SCARECROW_POS := WorldBuilderScript.SCARECROW_POS
const PLAYER_START := WorldBuilderScript.PLAYER_START
const POND_RECT := FishingManagerScript.POND_RECT
const FISH_SPOT_POS := FishingManagerScript.FISH_SPOT_POS

const PEN_COW := PenManagerScript.PEN_COW
const PEN_CHICKEN := PenManagerScript.PEN_CHICKEN
const PEN_SHEEP := PenManagerScript.PEN_SHEEP
const PEN_PIG := PenManagerScript.PEN_PIG
const PEN_RECT := PenManagerScript.PEN_RECT
const PATH_COBBLE_V := PenManagerScript.PATH_COBBLE_V
const PATH_COBBLE_H := PenManagerScript.PATH_COBBLE_H
const PENS_CONFIG := PenManagerScript.PENS_CONFIG
const PATHS := WorldBuilderScript.PATHS
const FOLIAGE_TYPES := WorldBuilderScript.FOLIAGE_TYPES

enum Mode { TITLE, PLAY, DIALOG, PANEL }

var mode: int = Mode.TITLE

# Đối tượng quản lý chức năng chuyên biệt
var farming_controller: RefCounted
var pen_manager: RefCounted
var fishing_manager: RefCounted
var stall_manager: RefCounted
var world_builder: RefCounted
var interaction_manager: RefCounted
var day_night_cycle: RefCounted
var save_load_manager: RefCounted
var mine_transition_manager: RefCounted
var ui_coordinator: RefCounted
var game_loop_manager: RefCounted
var input_controller: RefCounted
var manager_registry: RefCounted
var world_assembler: RefCounted
var game_bootstrapper: RefCounted
var debug_runner: RefCounted
var clicktest_runner: RefCounted

# Các node chính trong trò chơi
var world: Node2D
var player: CharacterBody2D
var farm: Node2D
var cam: Camera2D
var ground: Sprite2D
var canvas_mod: CanvasModulate
var highlight: Sprite2D
var weather_mgr: CanvasLayer
var quest_mgr: Node
var cat_helper: Node2D
var mine_manager: Node2D
var in_mine: bool = false

# Tham chiếu node & trạng thái từ các module
var pen_node: Node2D
var active_pen_animals: Array:
	get: return pen_manager.active_pen_animals if pen_manager != null else []
	set(v): if pen_manager != null: pen_manager.active_pen_animals = v

var _pen_bubbles: Dictionary:
	get: return pen_manager.pen_bubbles if pen_manager != null else {}
	set(v): if pen_manager != null: pen_manager.pen_bubbles = v

var stall_slots: Array:
	get: return stall_manager.stall_slots if stall_manager != null else []
	set(v): if stall_manager != null: stall_manager.stall_slots = v

var stall_crate_sprites: Array[Sprite2D]:
	get: return stall_manager.stall_crate_sprites if stall_manager != null else []
	set(v): if stall_manager != null: stall_manager.stall_crate_sprites = v

var stall_revenue: int:
	get: return stall_manager.stall_revenue if stall_manager != null else 0
	set(v): if stall_manager != null: stall_manager.stall_revenue = v

var stall_coin_badge: PanelContainer:
	get: return stall_manager.stall_coin_badge if stall_manager != null else null
	set(v): if stall_manager != null: stall_manager.stall_coin_badge = v

var stall_coin_label: Label:
	get: return stall_manager.stall_coin_label if stall_manager != null else null
	set(v): if stall_manager != null: stall_manager.stall_coin_label = v

var _stall_customers: Array[Node2D]:
	get: return stall_manager._stall_customers if stall_manager != null else []
	set(v): if stall_manager != null: stall_manager._stall_customers = v

var _active_stall_customer: Node2D:
	get: return stall_manager._active_stall_customer if stall_manager != null else null
	set(v): if stall_manager != null: stall_manager._active_stall_customer = v

var mailbox_badge: PanelContainer:
	get: return world_builder.mailbox_badge if world_builder != null else null
	set(v): if world_builder != null: world_builder.mailbox_badge = v

var mailbox_data: Dictionary:
	get: return world_builder.mailbox_data if world_builder != null else {}
	set(v): if world_builder != null: world_builder.mailbox_data = v

var foliage_nodes: Array:
	get: return world_builder.foliage_nodes if world_builder != null else []
	set(v): if world_builder != null: world_builder.foliage_nodes = v

var foliage_data: Array:
	get: return world_builder.foliage_data if world_builder != null else []
	set(v): if world_builder != null: world_builder.foliage_data = v

var interactables: Array:
	get: return interaction_manager.interactables if interaction_manager != null else []
	set(v): if interaction_manager != null: interaction_manager.interactables = v

var fishing: bool:
	get: return fishing_manager.fishing if fishing_manager != null else false
	set(v): if fishing_manager != null: fishing_manager.fishing = v

var fishing_left: float:
	get: return fishing_manager.fishing_left if fishing_manager != null else 0.0
	set(v): if fishing_manager != null: fishing_manager.fishing_left = v

var _rod_spr: Sprite2D:
	get: return fishing_manager._rod_spr if fishing_manager != null else null
	set(v): if fishing_manager != null: fishing_manager._rod_spr = v

var _bobber_spr: Sprite2D:
	get: return fishing_manager._bobber_spr if fishing_manager != null else null
	set(v): if fishing_manager != null: fishing_manager._bobber_spr = v

var _fishing_line: Line2D:
	get: return fishing_manager._fishing_line if fishing_manager != null else null
	set(v): if fishing_manager != null: fishing_manager._fishing_line = v

var npc: StaticBody2D:
	get: return interaction_manager.npc if interaction_manager != null else null
	set(v): if interaction_manager != null: interaction_manager.npc = v

var npc_hai: StaticBody2D:
	get: return interaction_manager.npc_hai if interaction_manager != null else null
	set(v): if interaction_manager != null: interaction_manager.npc_hai = v

var npc_tu: StaticBody2D:
	get: return interaction_manager.npc_tu if interaction_manager != null else null
	set(v): if interaction_manager != null: interaction_manager.npc_tu = v

var npc_leah: StaticBody2D:
	get: return interaction_manager.npc_leah if interaction_manager != null else null
	set(v): if interaction_manager != null: interaction_manager.npc_leah = v

var npc_mayor: StaticBody2D:
	get: return interaction_manager.npc_mayor if interaction_manager != null else null
	set(v): if interaction_manager != null: interaction_manager.npc_mayor = v

var _npc_met: bool:
	get: return interaction_manager._npc_met if interaction_manager != null else false
	set(v): if interaction_manager != null: interaction_manager._npc_met = v

var _npc_hai_met: bool:
	get: return interaction_manager._npc_hai_met if interaction_manager != null else false
	set(v): if interaction_manager != null: interaction_manager._npc_hai_met = v

var _npc_tu_met: bool:
	get: return interaction_manager._npc_tu_met if interaction_manager != null else false
	set(v): if interaction_manager != null: interaction_manager._npc_tu_met = v

var _leah_met: bool:
	get: return interaction_manager._leah_met if interaction_manager != null else false
	set(v): if interaction_manager != null: interaction_manager._leah_met = v

var _mayor_met: bool:
	get: return interaction_manager._mayor_met if interaction_manager != null else false
	set(v): if interaction_manager != null: interaction_manager._mayor_met = v

var _dialog_next: String:
	get: return interaction_manager._dialog_next if interaction_manager != null else "shop"
	set(v): if interaction_manager != null: interaction_manager._dialog_next = v

var _shed_decor: StaticBody2D:
	get: return world_builder.shed_decor if world_builder != null else null
var _house_decor: StaticBody2D:
	get: return world_builder.house_decor if world_builder != null else null

# Tham chiếu giao diện từ UICoordinator
var hud: CanvasLayer:
	get: return ui_coordinator.hud if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.hud = v

var shop_panel: CanvasLayer:
	get: return ui_coordinator.shop_panel if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.shop_panel = v

var fish_shop: CanvasLayer:
	get: return ui_coordinator.fish_shop if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.fish_shop = v

var poultry_shop: CanvasLayer:
	get: return ui_coordinator.poultry_shop if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.poultry_shop = v

var quest_panel: CanvasLayer:
	get: return ui_coordinator.quest_panel if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.quest_panel = v

var tool_upgrade_panel: CanvasLayer:
	get: return ui_coordinator.tool_upgrade_panel if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.tool_upgrade_panel = v

var stall_panel: CanvasLayer:
	get: return ui_coordinator.stall_panel if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.stall_panel = v

var inv_panel: CanvasLayer:
	get: return ui_coordinator.inv_panel if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.inv_panel = v

var storage_panel: CanvasLayer:
	get: return ui_coordinator.storage_panel if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.storage_panel = v

var cat_panel: CanvasLayer:
	get: return ui_coordinator.cat_panel if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.cat_panel = v

var mailbox_panel: CanvasLayer:
	get: return ui_coordinator.mailbox_panel if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.mailbox_panel = v

var dialog_box: CanvasLayer:
	get: return ui_coordinator.dialog_box if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.dialog_box = v

var title_screen: CanvasLayer:
	get: return ui_coordinator.title_screen if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.title_screen = v

var pause_menu: CanvasLayer:
	get: return ui_coordinator.pause_menu if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.pause_menu = v

var minimap: CanvasLayer:
	get: return ui_coordinator.minimap if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.minimap = v

var touch_ui: CanvasLayer:
	get: return ui_coordinator.touch_ui if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.touch_ui = v

var fade_rect: ColorRect:
	get: return ui_coordinator.fade_rect if ui_coordinator != null else null
	set(v): if ui_coordinator != null: ui_coordinator.fade_rect = v

var _debug_mode := ""
var _debug_frame: int:
	get: return debug_runner.debug_frame if debug_runner != null else 0
	set(v): if debug_runner != null: debug_runner.debug_frame = v

var _clicktest := ""
var _clicktest_frame: int:
	get: return clicktest_runner.clicktest_frame if clicktest_runner != null else 0
	set(v): if clicktest_runner != null: clicktest_runner.clicktest_frame = v


func _ready() -> void:
	if game_bootstrapper == null:
		game_bootstrapper = GameBootstrapperScript.new()
		game_bootstrapper.setup(self)
	game_bootstrapper.bootstrap()


func _init_managers() -> void:
	if manager_registry == null:
		manager_registry = ManagerRegistryScript.new()
	manager_registry.init_managers(self)


func _build_world() -> void:
	if world_assembler == null:
		world_assembler = WorldAssemblerScript.new()
	world_assembler.build_world(self)


func _build_ui() -> void:
	ui_coordinator.build_ui()
	ui_coordinator.connect_ui_signals()


func _process(delta: float) -> void:
	game_loop_manager.process_frame(delta)


func _tint() -> Color:
	return day_night_cycle.get_ambient_tint()


func _set_current_hint(t: String) -> void:
	ui_coordinator.set_current_hint(t)


func _unhandled_input(event: InputEvent) -> void:
	input_controller.handle_unhandled_input(event)


# Forwarding calls to managers
func _do_farm_action(tile: Node) -> bool:
	return farming_controller.do_farm_action(tile)

func _get_action_stamina_cost(act: String) -> float:
	return farming_controller.get_action_stamina_cost(act)

func _quick_eat() -> void:
	farming_controller.quick_eat()

func _spawn_effect(kind: String, pos: Vector2) -> void:
	farming_controller.spawn_effect(kind, pos)

func _face_towards(target_pos: Vector2) -> void:
	farming_controller.face_towards(target_pos)

func _rebuild_pen() -> void:
	pen_manager.rebuild_pen()

func _update_pen_bubbles() -> void:
	pen_manager.update_pen_bubbles()

func _collect_pen_products(species_id: String) -> void:
	pen_manager.collect_pen_products(species_id)

func _collect_products() -> void:
	pen_manager.collect_products()

func _interact_pen(species_id: String) -> void:
	pen_manager.interact_pen(species_id)

func _harvest_single_animal(anim: PenAnimal) -> void:
	pen_manager.harvest_single_animal(anim)

func _feed_single_animal(anim: PenAnimal) -> void:
	pen_manager.feed_single_animal(anim)

func _start_fishing() -> void:
	fishing_manager.start_fishing()

func _finish_fishing() -> void:
	fishing_manager.finish_fishing()

func _refill_water_can() -> void:
	fishing_manager.refill_water_can()

func _spawn_water_ripple(pos: Vector2, r_scale: float = 1.0, r_dur: float = 0.7) -> Sprite2D:
	return fishing_manager.spawn_water_ripple(pos, r_scale, r_dur)

func _open_market_stall() -> void:
	stall_manager.open_market_stall()

func _on_stall_changed() -> void:
	stall_manager.on_stall_changed()

func _on_stall_revenue_collected(amt: int) -> void:
	stall_manager.on_stall_revenue_collected(amt)

func _update_stall_coin_badge() -> void:
	stall_manager.update_stall_coin_badge()

func _update_stall_crates_visual() -> void:
	stall_manager.update_stall_crates_visual()

func _decline_stall_customer(cust: Node2D) -> void:
	stall_manager.decline_stall_customer(cust)

func _process_stall_customers(delta: float) -> void:
	stall_manager.process_stall_customers(delta)

func _spawn_stall_customer(forced_slot_idx: int = -1) -> Node2D:
	return stall_manager.spawn_stall_customer(forced_slot_idx)

func _on_stall_customer_purchased(slot_idx: int, item_name: String, qty: int, coins: int, buyer_name: String = "") -> void:
	stall_manager.on_stall_customer_purchased(slot_idx, item_name, qty, coins, buyer_name)

func _nearest_interactable() -> Dictionary:
	return interaction_manager.nearest_interactable()

func _update_hint_and_highlight() -> void:
	interaction_manager.update_hint_and_highlight()

func _do_interact() -> void:
	interaction_manager.do_interact()

func _handle_world_tap(world_tap_pos: Vector2) -> void:
	interaction_manager.handle_world_tap(world_tap_pos)

func _talk_npc() -> void:
	interaction_manager.talk_npc()

func _talk_hai() -> void:
	interaction_manager.talk_hai()

func _talk_mayor() -> void:
	interaction_manager.talk_mayor()

func _talk_tu() -> void:
	interaction_manager.talk_tu()

func _talk_leah() -> void:
	interaction_manager.talk_leah()

func _read_mine_sign() -> void:
	interaction_manager.read_mine_sign()

func _on_dialog_finished() -> void:
	interaction_manager.on_dialog_finished()

func _update_npc_mayor_indicator() -> void:
	interaction_manager.update_npc_mayor_indicator()

func _populate_random_foliage(target_count: int = 75, seed_val: int = 0) -> void:
	world_builder.populate_random_foliage(target_count, seed_val)

func _load_foliage(saved_items: Array) -> void:
	world_builder.load_foliage(saved_items)

func _clear_foliage() -> void:
	world_builder.clear_foliage()

func _sprout_random_plant() -> void:
	world_builder.sprout_random_plant()

func _is_grass_surface(pos: Vector2) -> bool:
	return world_builder.is_grass_surface(pos)

func _update_mailbox_badge() -> void:
	world_builder.update_mailbox_badge()

func _has_mailbox_items() -> bool:
	return world_builder.has_mailbox_items()

func _default_mailbox_data() -> Dictionary:
	return world_builder.default_mailbox_data()

# Quản lý Ngủ Nghỉ & Ngày Đêm (Ủy quyền cho DayNightCycle)
func _ask_sleep() -> void:
	day_night_cycle.ask_sleep()

func _on_sleep_answer(yes: bool) -> void:
	day_night_cycle.on_sleep_answer(yes)

func _do_sleep(forced: bool) -> void:
	day_night_cycle.do_sleep(forced)

# Quản lý Lưu / Tải Game (Ủy quyền cho SaveLoadManager)
func _cat_save_data() -> Dictionary:
	return save_load_manager.cat_save_data()

func _quest_save_data() -> Dictionary:
	return save_load_manager.quest_save_data()

func _save_now() -> void:
	save_load_manager.save_now()

func start_new_game() -> void:
	save_load_manager.start_new_game()

func continue_game() -> void:
	save_load_manager.continue_game()

func _back_to_title() -> void:
	save_load_manager.back_to_title()

# Quản lý Debug & Clicktest (Ủy quyền cho DebugRunner & ClicktestRunner)
func _debug_step() -> void:
	debug_runner.debug_step()

func _clicktest_step() -> void:
	clicktest_runner.clicktest_step()

func _debug_click_move() -> void:
	debug_runner.debug_click_move()

func _debug_click_press() -> void:
	debug_runner.debug_click_press()

func _shot(shot_name: String) -> void:
	debug_runner.shot(shot_name)

func _press_interact() -> void:
	clicktest_runner.press_interact()

# Quản lý Chuyển Cảnh Hầm Mỏ (Ủy quyền cho MineTransitionManager)
func _fade_transition(on_mid: Callable) -> void:
	mine_transition_manager.fade_transition(on_mid)

func _enter_mine() -> void:
	mine_transition_manager.enter_mine()

func _on_exit_mine() -> void:
	mine_transition_manager.exit_mine()

# Quản lý Mở / Đóng Giao Diện (Ủy quyền cho UICoordinator)
func _open_shop() -> void:
	ui_coordinator.open_shop()

func _open_fish_shop() -> void:
	ui_coordinator.open_fish_shop()

func _open_poultry_shop() -> void:
	ui_coordinator.open_poultry_shop()

func _open_tool_upgrade_panel() -> void:
	ui_coordinator.open_tool_upgrade_panel()

func _open_inventory() -> void:
	ui_coordinator.open_inventory()

func _open_mailbox() -> void:
	ui_coordinator.open_mailbox()

func _open_storage() -> void:
	ui_coordinator.open_storage()

func _open_cat_panel() -> void:
	ui_coordinator.open_cat_panel()

func _open_quest_panel() -> void:
	ui_coordinator.open_quest_panel()

func _on_mailbox_changed() -> void:
	ui_coordinator.on_mailbox_changed()

func _close_panels() -> void:
	ui_coordinator.close_panels()

func _resume_from_pause() -> void:
	ui_coordinator.resume_from_pause()
