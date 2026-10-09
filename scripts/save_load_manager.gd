extends RefCounted
# Quản lý Lưu / Tải Dữ Liệu Game & Phiên Chơi (Save & Load Manager)

const WeatherManagerScript := preload("res://scripts/weather_manager.gd")
const QuestManagerScript := preload("res://scripts/quest_manager.gd")
const CatHelperScript := preload("res://scripts/cat_helper.gd")
const QuestDB := preload("res://scripts/quest_db.gd")

var main: Node2D


func setup(p_main: Node2D) -> void:
	main = p_main


func cat_save_data() -> Dictionary:
	if is_instance_valid(main.cat_helper):
		return main.cat_helper.get_save_dict()
	return {}


func quest_save_data() -> Dictionary:
	if is_instance_valid(main.quest_mgr):
		return main.quest_mgr.get_save_data()
	return {}


# Lưu trạng thái game hiện tại vào file save
func save_now() -> void:
	SaveSystem.save_game(
		main.farm.get_state(),
		main.player.position,
		main._npc_met,
		main.mailbox_data,
		main.foliage_data,
		main.stall_slots,
		main.stall_revenue,
		cat_save_data(),
		quest_save_data()
	)
	if is_instance_valid(main.hud):
		main.hud.toast("Đã lưu game!", Color(0.6, 1.0, 0.6))


# Khởi tạo một phiên chơi mới hoàn toàn
func start_new_game() -> void:
	GameState.reset_new_game()
	if is_instance_valid(main.weather_mgr):
		main.weather_mgr.set_weather(WeatherManagerScript.SUNNY)
	if is_instance_valid(main.hud):
		main.hud.set_weather(WeatherManagerScript.SUNNY)

	Inventory.reset()
	Inventory.selected_seed = "rice"
	Inventory.add_hoes(2)
	Inventory.add_seed("rice", 2)
	Inventory.add_produce("sweet_potato", 2)
	Inventory.add_produce("thit_lon", 1)

	main.mailbox_data = main._default_mailbox_data()
	main._update_mailbox_badge()

	main.stall_slots = [{}, {}, {}, {}, {}, {}]
	main.stall_revenue = 0
	main._update_stall_crates_visual()
	main._update_stall_coin_badge()

	main.farm.reset_all()
	main.player.position = main.PLAYER_START
	main.player.facing = Vector2.DOWN
	main.cam.reset_smoothing()
	main._npc_met = false
	main._populate_random_foliage(75)

	if is_instance_valid(main.cat_helper):
		main.cat_helper.dismiss()
		main.cat_helper.position = CatHelperScript.SPAWN_POS
		main.cat_helper.state = CatHelperScript.State.ARRIVING
		main.cat_helper.waypoints = [
			CatHelperScript.ROAD_JUNCTION_POS,
			Vector2(CatHelperScript.ROAD_JUNCTION_POS.x, CatHelperScript.WAITING_POS.y),
			CatHelperScript.WAITING_POS
		]
		main.cat_helper._show_bubble_text("...")

	if is_instance_valid(main.quest_mgr):
		var cur_day: int = QuestManagerScript.get_real_day_id()
		var cur_week: int = QuestManagerScript.get_real_week_id()
		main.quest_mgr.refresh_daily_quests(cur_day)
		main.quest_mgr.refresh_weekly_quests(cur_week)
		main.quest_mgr.lifetime_quests = QuestDB.init_lifetime_quests()
		main.quest_mgr.quests_refreshed.emit()

	main._update_npc_mayor_indicator()
	main.dialog_box.force_close()
	main.title_screen.hide_me()
	main.get_tree().paused = false
	main.mode = main.Mode.PLAY
	if is_instance_valid(main.hud):
		main.hud.toast("WASD: di chuyển · E: tương tác · I: kho đồ · Q: nhiệm vụ · F: ăn nhanh hồi thể lực ⚡")


# Tải lại trạng thái game từ file save đã lưu
func continue_game() -> void:
	var d := SaveSystem.load_data()
	if d.is_empty():
		start_new_game()
		return

	GameState.money = int(d.get("money", 100))
	GameState.day = int(d.get("day", 1))
	GameState.clock = float(d.get("clock", GameState.DAY_START))
	GameState.stamina = float(d.get("stamina", 100.0))
	GameState.max_stamina = float(d.get("max_stamina", 100.0))
	GameState.weather = str(d.get("weather", "sunny"))
	if is_instance_valid(main.weather_mgr):
		main.weather_mgr.set_weather(GameState.weather)
	if is_instance_valid(main.hud):
		main.hud.set_weather(GameState.weather)

	var unl: Array = []
	for id in d.get("unlocked", ["rice"]):
		unl.append(str(id))
	GameState.unlocked = unl
	GameState.money_changed.emit(GameState.money)
	GameState.crops_changed.emit()
	GameState.stamina_changed.emit(GameState.stamina, GameState.max_stamina)
	GameState.weather_changed.emit(GameState.weather)

	Inventory.set_state({
		"seeds": d.get("seeds", {}),
		"produce": d.get("produce", {}),
		"sel": d.get("sel", ""),
		"hoes": d.get("hoes", 0),
		"water_level": d.get("water_level", 20),
		"water_max": d.get("water_max", 20),
		"active_item": d.get("active_item", {"type": "hoe"}),
		"rods": d.get("rods", {}),
		"fish": d.get("fish", {}),
		"coops": d.get("coops", {}),
		"animals": d.get("animals", []),
	})

	var mb_dict = d.get("mailbox", null)
	if typeof(mb_dict) == TYPE_DICTIONARY and not mb_dict.is_empty() and (mb_dict.has("produce") or mb_dict.has("fish")):
		main.mailbox_data = mb_dict.duplicate(true)
	else:
		main.mailbox_data = main._default_mailbox_data()
	main._update_mailbox_badge()

	var st_arr = d.get("stall", [])
	if typeof(st_arr) == TYPE_ARRAY and st_arr.size() == 6:
		main.stall_slots = st_arr.duplicate(true)
	else:
		main.stall_slots = [{}, {}, {}, {}, {}, {}]
	main.stall_revenue = int(d.get("stall_revenue", 0))
	main._update_stall_crates_visual()
	main._update_stall_coin_badge()

	var farm_arr = d.get("farm", [])
	if typeof(farm_arr) == TYPE_ARRAY:
		main.farm.apply_state(farm_arr)

	var pp: Array = d.get("player", [main.PLAYER_START.x, main.PLAYER_START.y])
	main.player.position = Vector2(float(pp[0]), float(pp[1]))
	main.cam.reset_smoothing()
	main._npc_met = bool(d.get("npc_met", true))

	var f_arr = d.get("foliage", [])
	if typeof(f_arr) == TYPE_ARRAY and f_arr.size() > 0:
		main._load_foliage(f_arr)
	elif main.foliage_data.is_empty():
		main._populate_random_foliage(75)

	if d.has("cat") and is_instance_valid(main.cat_helper):
		main.cat_helper.load_save_dict(d["cat"])

	if d.has("quests") and is_instance_valid(main.quest_mgr):
		main.quest_mgr.load_save_data(d["quests"])

	main._update_npc_mayor_indicator()
	main.title_screen.hide_me()
	main.get_tree().paused = false
	main.mode = main.Mode.PLAY
	if is_instance_valid(main.hud):
		main.hud.toast("Đã tiếp tục — chào mừng trở lại!", Color(0.65, 1.0, 0.6))


# Lưu game và quay về màn hình chính
func back_to_title() -> void:
	save_now()
	main._close_panels()
	main.mode = main.Mode.TITLE
	main.dialog_box.force_close()
	main.title_screen.open(SaveSystem.has_save())
