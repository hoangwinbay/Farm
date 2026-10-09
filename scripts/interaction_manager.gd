extends RefCounted
# Quản lý Hệ Thống Tương Tác, Gợi Ý & Hội Thoại NPC (Interaction & NPC Manager)

const NpcScript := preload("res://scripts/npc.gd")
const PenAnimal := preload("res://scripts/pen_animal.gd")
const StallCustomerScript := preload("res://scripts/stall_customer.gd")
const CatHelperScript := preload("res://scripts/cat_helper.gd")
const WorldBuilderScript := preload("res://scripts/world_builder.gd")
const PenManagerScript := preload("res://scripts/pen_manager.gd")
const FishingManagerScript := preload("res://scripts/fishing_manager.gd")

var main: Node2D
var interactables: Array = []

var npc: StaticBody2D
var npc_hai: StaticBody2D
var npc_tu: StaticBody2D
var npc_leah: StaticBody2D
var npc_mayor: StaticBody2D

var _npc_met := false
var _npc_hai_met := false
var _npc_tu_met := false
var _leah_met := false
var _mayor_met := false
var _dialog_next := "shop"


func setup(p_main: Node2D) -> void:
	main = p_main


func build_npcs(world: Node2D) -> void:
	npc = NpcScript.new()
	npc.npc_name = "Bác Tư"

	npc_hai = NpcScript.new()
	npc_hai.npc_name = "Chú Hai"

	npc_tu = NpcScript.new()
	npc_tu.npc_name = "Cô Tư"

	main.world_builder.add_shop_stall("poultry", WorldBuilderScript.STAND_TU_POS, npc_tu)
	main.world_builder.add_shop_stall("seed", WorldBuilderScript.STAND_POS, npc)
	main.world_builder.add_shop_stall("fish", WorldBuilderScript.STAND_HAI_POS, npc_hai)

	npc_mayor = NpcScript.new()
	npc_mayor.npc_name = "Trưởng Thôn"
	npc_mayor.position = WorldBuilderScript.MAYOR_POS
	world.add_child(npc_mayor)
	update_npc_mayor_indicator()

	npc_leah = main.world_builder.npc_leah


func build_interactables() -> void:
	interactables = [
		{"pos": WorldBuilderScript.HOUSE_POS + Vector2(15, -16), "r": 50.0, "label": "Ngủ 🛏️ (Lưu game)", "cb": main._ask_sleep},
		{"pos": WorldBuilderScript.SHED_POS + Vector2(0, -6), "r": 50.0, "label": "Nhà kho 🏚️", "cb": main._open_storage},
		{"pos": WorldBuilderScript.TENT_POS, "r": 50.0, "label": "Lều Mèo ⛺ (Quản lý Mèo)", "cb": main._open_cat_panel},
		{"pos": WorldBuilderScript.MAILBOX_POS, "r": 50.0, "label": "Hòm thư 📬", "cb": main._open_mailbox},
		{"pos": WorldBuilderScript.MAYOR_POS, "r": 50.0, "label": "Trưởng Thôn 📜", "cb": talk_mayor},
		{"pos": WorldBuilderScript.MARKET_STALL_POS + Vector2(0, 16), "r": 65.0, "label": "Sạp hàng 🏪", "cb": main._open_market_stall},
		{"pos": WorldBuilderScript.MINE_ENTRANCE_POS + Vector2(0, 24), "r": 50.0, "label": "Vào Hầm Mỏ ⛏️", "cb": main._enter_mine},
		{"pos": WorldBuilderScript.MINE_SIGN_POS, "r": 40.0, "label": "Biển báo Hầm Mỏ 📜", "cb": read_mine_sign},
		{"pos": WorldBuilderScript.LEAH_MINER_POS, "r": 45.0, "label": "Leah ⛏️ (Nâng cấp Nông Cụ)", "cb": talk_leah},
		{"pos": WorldBuilderScript.STAND_POS, "r": 60.0, "label": "Bác Tư", "cb": talk_npc},
		{"pos": WorldBuilderScript.STAND_HAI_POS, "r": 60.0, "label": "Chú Hai", "cb": talk_hai},
		{"pos": WorldBuilderScript.STAND_TU_POS, "r": 60.0, "label": "Cô Tư", "cb": talk_tu},
		{"pos": PenManagerScript.PEN_COW.get_center(), "r": 85.0, "label": "Chuồng Bò", "cb": func(): main.pen_manager.interact_pen("cow")},
		{"pos": PenManagerScript.PEN_CHICKEN.get_center(), "r": 85.0, "label": "Chuồng Gà", "cb": func(): main.pen_manager.interact_pen("chicken")},
		{"pos": PenManagerScript.PEN_SHEEP.get_center(), "r": 85.0, "label": "Chuồng Cừu", "cb": func(): main.pen_manager.interact_pen("sheep")},
		{"pos": PenManagerScript.PEN_PIG.get_center(), "r": 85.0, "label": "Chuồng Lợn", "cb": func(): main.pen_manager.interact_pen("pig")},
		{"pos": FishingManagerScript.FISH_SPOT_POS, "r": 210.0, "label": "Câu cá", "cb": main.fishing_manager.start_fishing},
	]


func nearest_interactable() -> Dictionary:
	if main.in_mine and main.mine_manager != null:
		return main.mine_manager.get_interactable_near(main.player.position)

	var best := {}
	var best_d := INF
	for it in interactables:
		var it_pos: Vector2 = it.pos
		var d: float = main.player.position.distance_to(it_pos)
		if d <= float(it.r) and d < best_d:
			best_d = d
			best = it.duplicate()
			if it_pos == FishingManagerScript.FISH_SPOT_POS:
				var active_t: String = str(Inventory.active_item.get("type", ""))
				if active_t == "rod" and Inventory.total_casts() > 0:
					best.label = "Câu cá (%d lượt)" % Inventory.total_casts()
					best.cb = main.fishing_manager.start_fishing
				elif Inventory.water_level < Inventory.water_max:
					best.label = "Múc nước vào bình (%d/%d) 💧" % [Inventory.water_level, Inventory.water_max]
					best.cb = main.fishing_manager.refill_water_can
				elif Inventory.total_casts() > 0:
					best.label = "Câu cá (%d lượt)" % Inventory.total_casts()
					best.cb = main.fishing_manager.start_fishing
				else:
					best.label = "Bình nước đã đầy (20/20) 💧"
					best.cb = func(): if is_instance_valid(main.hud): main.hud.toast("Bình nước đã đầy rồi (20/20)!")

	# Kiểm tra chú mèo tam thể
	if is_instance_valid(main.cat_helper):
		var d_cat: float = main.player.position.distance_to(main.cat_helper.position)
		if d_cat <= 50.0 and d_cat < best_d:
			best_d = d_cat
			var cat_lbl: String = "Mèo Tam Thể 🐱"
			if not main.cat_helper.is_hired:
				cat_lbl = "Mèo Tam Thể 🐱 (Phỏng vấn / Thuê)"
			elif main.cat_helper.state == CatHelperScript.State.SLEEPING:
				cat_lbl = "Mèo Tam Thể 🐱 (Đang ngủ Zzz...)"
			else:
				cat_lbl = "Mèo Tam Thể 🐱 (Quản lý / Giao việc)"
			best = {
				"pos": main.cat_helper.position,
				"r": 50.0,
				"label": cat_lbl,
				"cb": func(): main._open_cat_panel()
			}

	# Kiểm tra khách NPC đang đứng chờ quanh sạp
	for c in main.stall_manager._stall_customers:
		if is_instance_valid(c) and c.state == StallCustomerScript.State.WAITING:
			var d: float = main.player.position.distance_to(c.position)
			if d <= 32.0 and d < best_d:
				best_d = d
				best = {
					"pos": c.position,
					"r": 32.0,
					"label": "%s · [E] Báo hết hàng" % c.display_name,
					"cb": func(): main.stall_manager.decline_stall_customer(c)
				}

	# Kiểm tra từng con vật trong chuồng
	for anim in main.pen_manager.active_pen_animals:
		if is_instance_valid(anim):
			var d_anim: float = main.player.position.distance_to(anim.position)
			if d_anim <= 42.0 and d_anim < best_d:
				best_d = d_anim
				var aname: String = anim.get_animal_name()
				if anim.is_ready():
					best = {
						"pos": anim.position,
						"r": 42.0,
						"label": "Thu hoạch %s (%s) ⭐" % [aname, anim.get_product_name()],
						"cb": func(): main.pen_manager.harvest_single_animal(anim)
					}
				elif not anim.is_fed():
					if Inventory.feed_count() > 0:
						best = {
							"pos": anim.position,
							"r": 42.0,
							"label": "Cho %s ăn 🌾 (Cám x%d)" % [aname, Inventory.feed_count()],
							"cb": func(): main.pen_manager.feed_single_animal(anim)
						}
					else:
						best = {
							"pos": anim.position,
							"r": 42.0,
							"label": "Cho %s ăn 🌾 (Cần mua Túi Cám ở Cửa Hàng)" % aname,
							"cb": func(): if is_instance_valid(main.hud): main.hud.toast("Bạn cần mua Túi Cám ở tiệm Cô Tư để cho ăn!", Color(1.0, 0.65, 0.4))
						}
				elif anim.state == PenAnimal.State.EATING or anim.state == PenAnimal.State.WALK_TO_TROUGH:
					best = {
						"pos": anim.position,
						"r": 42.0,
						"label": "%s (Đang ăn trong máng 🌾)" % aname,
						"cb": func(): pass
					}
				else:
					var rem: int = int(ceil(anim.get_remaining_wait_time()))
					best = {
						"pos": anim.position,
						"r": 42.0,
						"label": "%s (Đang lớn... còn %ds) ⏳" % [aname, rem],
						"cb": func(): pass
					}
	return best


func update_hint_and_highlight() -> void:
	if main.in_mine:
		if is_instance_valid(main.highlight):
			main.highlight.visible = false
		var near_m: Dictionary = main.mine_manager.get_interactable_near(main.player.position) if main.mine_manager else {}
		if not near_m.is_empty():
			main._set_current_hint("E: " + str(near_m.get("label", "")))
		else:
			main._set_current_hint("")
		return

	var near := nearest_interactable()
	if not near.is_empty():
		if is_instance_valid(main.highlight):
			main.highlight.visible = false
		var lbl: String = str(near.label)
		var pen_matched := false
		for pcfg in PenManagerScript.PENS_CONFIG:
			if near.pos == pcfg.rect.get_center():
				pen_matched = true
				var sid: String = str(pcfg.id)
				var r_count := Inventory.ready_products_for_species(sid)
				var cname: String = str(pcfg.name)
				var hungry_count := Inventory.hungry_animals_for_species(sid)
				if r_count > 0:
					lbl = "Thu hoạch %s (%d) ⭐" % [cname, r_count]
				elif hungry_count > 0:
					if Inventory.feed_count() > 0:
						lbl = "Cho %s ăn 🌾 (%d con đói · Cám x%d)" % [cname, hungry_count, Inventory.feed_count()]
					else:
						lbl = "%s (Đói · Cần mua Túi Cám ở Cửa Hàng)" % cname
				else:
					var tier := Inventory.get_coop_tier(sid)
					if tier == 0:
						lbl = "%s (Chưa mua)" % cname
					else:
						lbl = "%s (%d con)" % [cname, Inventory.animals_of_species(sid)]
				break
		if not pen_matched and near.pos == WorldBuilderScript.MAILBOX_POS:
			if main.world_builder.has_mailbox_items():
				lbl = "Hòm thư 📬 (Có quà)"
			else:
				lbl = "Hòm thư 📬 (Trống)"
		elif near.pos == WorldBuilderScript.MARKET_STALL_POS + Vector2(0, 16):
			var count_items := 0
			var occupied_crates := 0
			for sl in main.stall_manager.stall_slots:
				if typeof(sl) == TYPE_DICTIONARY and not sl.is_empty() and int(sl.get("count", 0)) > 0:
					count_items += int(sl.get("count", 0))
					occupied_crates += 1
			if occupied_crates > 0:
				lbl = "Sạp hàng 🏪 (%d/6 ô · %d món)" % [occupied_crates, count_items]
			else:
				lbl = "Sạp hàng 🏪"
		main._set_current_hint("E: " + lbl)
		return

	var tile = main.farm.tile_at_world(main.player.get_facing_point())
	if tile == null or not main.farming_controller.is_player_in_tile_plot(main.player.position, tile):
		if is_instance_valid(main.highlight):
			main.highlight.visible = false
		main._set_current_hint("")
		return
	var info: Dictionary = main.farm.action_at(tile)
	if is_instance_valid(main.highlight):
		main.highlight.visible = true
		main.highlight.global_position = main.farm.tile_center(tile.coord)
		main.highlight.modulate = Color(0.5, 1.0, 0.5, 0.95) if bool(info.ok) else Color(1, 1, 1, 0.35)
	main._set_current_hint(("E: " + str(info.label)) if str(info.label) != "" else "")


func do_interact() -> void:
	if main.fishing:
		return
	if main.in_mine and main.mine_manager != null:
		var near_m: Dictionary = main.mine_manager.get_interactable_near(main.player.position)
		if not near_m.is_empty() and near_m.has("cb") and near_m.cb is Callable:
			near_m.cb.call()
		return
	var near := nearest_interactable()
	if not near.is_empty():
		near.cb.call()
		return
	var tile = main.farm.tile_at_world(main.player.get_facing_point())
	if tile != null:
		if not main.farming_controller.is_player_in_tile_plot(main.player.position, tile):
			if is_instance_valid(main.hud):
				main.hud.toast("Hãy vào trong ruộng qua cổng rào để chăm sóc cây trồng! 🌾", Color(1.0, 0.85, 0.5))
			return
		main.farming_controller.do_farm_action(tile)


func handle_world_tap(world_tap_pos: Vector2) -> void:
	if main.mode != main.Mode.PLAY or main.get_tree().paused or main.fishing:
		return
	if not is_instance_valid(main.player):
		return

	if main.in_mine and main.mine_manager != null:
		if main.mine_manager.has_method("handle_tap"):
			main.mine_manager.handle_tap(world_tap_pos)
		return

	# 1. Chạm vào ô đất nông trại
	var tile = main.farm.tile_at_world(world_tap_pos)
	if tile != null:
		if not main.farming_controller.is_player_in_tile_plot(main.player.position, tile):
			if is_instance_valid(main.hud):
				main.hud.toast("Hãy vào trong ruộng qua cổng rào để thao tác ô đất này! 🌾", Color(1.0, 0.85, 0.5))
			return
		var t_center: Vector2 = main.farm.tile_center(tile.coord)
		var dist: float = main.player.position.distance_to(t_center)
		if dist <= 80.0:
			main.farming_controller.face_towards(t_center)
			main.farming_controller.do_farm_action(tile)
		else:
			if is_instance_valid(main.hud):
				main.hud.toast("Hãy lại gần hơn để thao tác ô đất này! 🌱", Color(1.0, 0.85, 0.5))
		return

	# 2. Chạm vào vật thể tương tác
	var best_it: Dictionary = {}
	var best_dist := INF
	for it in interactables:
		var it_pos: Vector2 = it.pos
		var it_r: float = maxf(float(it.get("r", 32.0)), 28.0)
		if world_tap_pos.distance_to(it_pos) <= it_r + 14.0:
			var d_p: float = main.player.position.distance_to(it_pos)
			if d_p < best_dist:
				best_dist = d_p
				best_it = it

	if best_it.is_empty():
		for pcfg in PenManagerScript.PENS_CONFIG:
			var r: Rect2 = pcfg.rect
			if r.has_point(world_tap_pos):
				for it in interactables:
					if it.pos == r.get_center():
						best_it = it
						best_dist = main.player.position.distance_to(it.pos)
						break
				break

	if best_it.is_empty() and is_instance_valid(main.cat_helper):
		if world_tap_pos.distance_to(main.cat_helper.position) <= 36.0:
			var d_p: float = main.player.position.distance_to(main.cat_helper.position)
			if d_p <= 65.0:
				main.farming_controller.face_towards(main.cat_helper.position)
				main._open_cat_panel()
			else:
				if is_instance_valid(main.hud):
					main.hud.toast("Hãy lại gần Mèo Tam Thể hơn để tương tác! 🐱", Color(1.0, 0.85, 0.5))
			return

	if not best_it.is_empty():
		var it_pos: Vector2 = best_it.pos
		var max_interact_dist: float = maxf(float(best_it.get("r", 32.0)) + 36.0, 68.0)
		if main.player.position.distance_to(it_pos) <= max_interact_dist:
			main.farming_controller.face_towards(it_pos)
			if best_it.has("cb") and best_it.cb is Callable:
				best_it.cb.call()
		else:
			if is_instance_valid(main.hud):
				main.hud.toast("Hãy lại gần hơn để tương tác!", Color(1.0, 0.85, 0.5))
		return


func talk_npc() -> void:
	main.mode = main.Mode.DIALOG
	main.get_tree().paused = true
	_dialog_next = "shop"
	if _npc_met:
		main.dialog_box.start("Bác Tư", ["Cần gì nữa con? Mua hạt giống hay bán nông sản nào?"])
	else:
		main.dialog_box.start("Bác Tư", [
			"Chào con! Chào mừng đến với nông trại nhỏ của bác.",
			"Làm ruộng thế này: MUA CUỐC -> CÀY đất -> GIEO hạt -> TƯỚI nước cho đủ ẩm -> THU HOẠCH khi cây chín.",
			"Cây lớn dần theo thời gian khi đất ẩm — đất khô sau chừng 4 phút thì tưới lại đó con!",
			"Rồi mang nông sản ra quầy bán. ĐỦ TIỀN thì mở khóa được cây mới, càng về sau càng giá trị!",
			"Muốn câu cá thì ra AO gặp Chú Hai mua cần câu đó con!",
		])
		_npc_met = true


func talk_hai() -> void:
	main.mode = main.Mode.DIALOG
	main.get_tree().paused = true
	_dialog_next = "fish"
	if _npc_hai_met:
		main.dialog_box.start("Chú Hai", ["Cá gì nữa con? Mua cần câu hay bán cá nào?"])
	else:
		main.dialog_box.start("Chú Hai", [
			"Chào con! Chú Hai đây — buôn cá tôm bốn phương!",
			"Mua cần câu của chú rồi ra AO phía sau thả câu. Mỗi lần thả phải chờ 15 giây mới kéo được!",
			"Nghe đồn: đêm đêm cá Trê Vàng mới chịu lên, và dưới dòng sông còn có Cá Chiên huyền thoại...",
			"Cá câu được bán lại cho chú giá tốt lắm con!",
		])
		_npc_hai_met = true


func talk_mayor() -> void:
	main.mode = main.Mode.DIALOG
	main.get_tree().paused = true
	_dialog_next = "quests"
	if _mayor_met:
		main.dialog_box.start("Trưởng Thôn", ["Chào cháu! Hãy xem bảng nhiệm vụ hôm nay có việc gì giúp làng nhé!"])
	else:
		main.dialog_box.start("Trưởng Thôn", [
			"Chào mừng cháu đến với làng! Bác là Trưởng Thôn nơi đây.",
			"Mỗi ngày và mỗi tuần bác đều có các nhiệm vụ giúp làng phát triển nông nghiệp và khai khoáng.",
			"Nhiệm vụ Ngày thưởng 100 vàng + 10 nguyên liệu cùng loại!",
			"Nhiệm vụ Tuần thưởng 500 vàng + 50 nguyên liệu cùng loại, còn Nhiệm vụ Tổng thưởng 50 vàng mỗi mốc thành tựu!",
			"Cháu có thể mở Bảng Nhiệm Vụ bằng phím [Q] hoặc bấm biểu tượng nhiệm vụ góc trên bất cứ lúc nào."
		])
		_mayor_met = true


func on_dialog_finished() -> void:
	if _dialog_next == "none":
		main.mode = main.Mode.PLAY
		main.get_tree().paused = false
		return
	elif _dialog_next == "leah_gift":
		main.mode = main.Mode.PLAY
		main.get_tree().paused = false
		Inventory.add_pickaxe("basic")
		if is_instance_valid(main.hud):
			main.hud.toast("Nhận được Cúp khai mỏ sơ cấp từ Leah! ⛏️", Color(0.7, 1.0, 0.7))
		return
	elif _dialog_next == "tool_upgrade":
		main._open_tool_upgrade_panel()
	elif _dialog_next == "fish":
		main._open_fish_shop()
	elif _dialog_next == "poultry":
		main._open_poultry_shop()
	elif _dialog_next == "quests":
		main._open_quest_panel()
	else:
		main._open_shop()


func talk_leah() -> void:
	main.mode = main.Mode.DIALOG
	main.get_tree().paused = true
	if not Inventory.has_pickaxe():
		_dialog_next = "leah_gift"
		main.dialog_box.start("Leah", [
			"Chào bạn! Mình là Leah.",
			"Đây là hầm mỏ bỏ hoang của làng, dưới lòng đất ẩn chứa rất nhiều khoáng sản quý giá như Đồng, Sắt, Vàng và Đá quý hiếm.",
			"Mình tặng bạn chiếc Cúp sơ cấp này nhé! Hãy cầm Cúp và xuống mỏ thử vận may nào!"
		])
		_leah_met = true
	else:
		_dialog_next = "tool_upgrade"
		main.dialog_box.start("Leah", [
			"Chào bạn! Hầm mỏ gồm tất cả 20 tầng, càng xuống sâu sẽ càng có nhiều quặng quý hiếm.",
			"Nếu có đủ Quặng và Vàng, mình sẽ rèn nâng cấp Cuốc đất và Cúp mỏ cho bạn để làm việc đỡ tốn thể lực hơn nhé!"
		])


func read_mine_sign() -> void:
	main.mode = main.Mode.DIALOG
	main.get_tree().paused = true
	_dialog_next = "none"
	main.dialog_box.start("📜 Biển Báo Hầm Mỏ (20 Tầng)", [
		"⛏️ TẦNG 1 - 7 (Đất & Đá Thường): Nhiều Đá cuội, Than đá, Quặng Đồng. Quặng Sắt xuất hiện từ Tầng 4.",
		"❄️ TẦNG 8 - 14 (Hầm Mỏ Băng Giá): Quặng Sắt dồi dào, Than đá, Hồng Ngọc (Ruby). Quặng Vàng xuất hiện từ Tầng 11.",
		"🌋 TẦNG 15 - 19 (Nham Thạch): Nhiều Quặng Vàng, Hồng Ngọc, Quặng Sắt & Kim Cương quý hiếm.",
		"🏆 TẦNG 20 (ĐÁY HẦM MỎ): Kho tàng cực kỳ quý hiếm với Kim Cương (25%), Hồng Ngọc (25%), Quặng Vàng (35%)!",
		"⚠️ Hướng dẫn: Đứng gần khối quặng bấm [E] để đập bằng Cúp. Bấm [E] tại thang để xuống tầng tiếp theo hoặc trở lên mặt đất."
	])


func talk_tu() -> void:
	main.mode = main.Mode.DIALOG
	main.get_tree().paused = true
	_dialog_next = "poultry"
	if _npc_tu_met:
		main.dialog_box.start("Cô Tư", [
			"Vật nuôi khỏe mạnh hết nấy con! Mua chuồng, mua giống hay bán sản phẩm?",
			"Nhớ nghen: Cứ nuôi đủ 2 con lớn cùng loài là chúng có thể sinh ra con non baby đó!"
		])
	else:
		main.dialog_box.start("Cô Tư", [
			"Chào con! Cô Tư đây — trại giống gia cầm gia súc uy tín nhất vùng!",
			"Cô chuyên bán 4 loại con giống tốt: Gà trắng, Bò trắng, Lợn và Cừu.",
			"Muốn nuôi thì nhớ MUA CHUỒNG trước: Chuồng gia cầm nuôi Gà, Chuồng gia súc nuôi Bò, Lợn, Cừu.",
			"Gà cho trứng, Bò cho sữa, Lợn cho thịt, Cừu cho lông xén.",
			"Đặc biệt: Nuôi đủ đôi (từ 2 con cùng loài trở lên) là chúng có thể đẻ ra con baby!",
			"Nhớ ghé chuồng bấm [E] thu hoạch rồi mang qua cô thu mua giá ngon nghen con!"
		])
	_npc_tu_met = true


func update_npc_mayor_indicator() -> void:
	if npc_mayor == null or main.quest_mgr == null:
		return
	if main.quest_mgr.has_unclaimed_rewards():
		npc_mayor.set_quest_indicator("question")
	elif main.quest_mgr.has_active_quests():
		npc_mayor.set_quest_indicator("exclamation")
	else:
		npc_mayor.set_quest_indicator("")
