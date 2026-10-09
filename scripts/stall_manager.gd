extends RefCounted
# Quản lý Sạp Hàng Nông Sản & Khách Mua Hàng (Market Stall & Customers Manager)

const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const StallCustomerScript := preload("res://scripts/stall_customer.gd")

const MARKET_STALL_POS := Vector2(584, 440) # sạp hàng nông sản tại ngã rẽ đại lộ

const SDV_CUSTOMERS_DATA := [
	{"name": "Bé Lan", "asset": "Abigail"},
	{"name": "Cô Mai", "asset": "Haley"},
	{"name": "Em Cúc", "asset": "Penny"},
	{"name": "Anh Nam", "asset": "Sam"},
	{"name": "Anh Dũng", "asset": "Alex"},
	{"name": "Chị Hoa", "asset": "Emily"},
	{"name": "Bác Minh", "asset": "Harvey"},
	{"name": "Bé Linh", "asset": "Maru"},
	{"name": "Anh Phong", "asset": "Sebastian"},
]
const SDV_CUSTOMERS := ["Abigail", "Haley", "Penny", "Sam", "Alex", "Emily", "Harvey", "Maru", "Sebastian"]

const STALL_COUNTER_SPOTS := [
	Vector2(546, 468), Vector2(565, 468), Vector2(584, 468),
	Vector2(603, 468), Vector2(622, 468), Vector2(555, 482),
	Vector2(574, 482), Vector2(593, 482), Vector2(612, 482),
	Vector2(630, 482)
]

const STALL_WISHLIST_ITEMS := [
	{"id": "wheat", "type": "crop", "name": "Lúa mì", "base_price": 45},
	{"id": "rice", "type": "crop", "name": "Lúa nước", "base_price": 25},
	{"id": "tomato", "type": "crop", "name": "Cà chua", "base_price": 96},
	{"id": "carrot", "type": "crop", "name": "Cà rốt", "base_price": 66},
	{"id": "corn", "type": "crop", "name": "Bắp ngô", "base_price": 70},
	{"id": "potato", "type": "crop", "name": "Khoai tây", "base_price": 88},
	{"id": "cabbage", "type": "crop", "name": "Bắp cải", "base_price": 110},
	{"id": "watermelon", "type": "crop", "name": "Dưa hấu", "base_price": 155},
	{"id": "chep", "type": "fish", "name": "Cá chép", "base_price": 40},
	{"id": "trung_ga", "type": "poultry", "name": "Trứng gà", "base_price": 35},
	{"id": "sua_bo", "type": "poultry", "name": "Sữa bò", "base_price": 70},
	{"id": "thit_lon", "type": "poultry", "name": "Thịt lợn", "base_price": 55},
	{"id": "long_cuu", "type": "poultry", "name": "Lông cừu", "base_price": 65},
]

var main: Node2D
var world: Node2D

var stall_slots: Array = [{}, {}, {}, {}, {}, {}]
var stall_crate_sprites: Array[Sprite2D] = []
var stall_revenue: int = 0
var stall_coin_badge: PanelContainer
var stall_coin_label: Label
var _stall_customer_timer: float = 0.0
var _next_stall_customer_delay: float = 16.0
var _active_stall_customer: Node2D = null
var _stall_customers: Array[Node2D] = []


func setup(p_main: Node2D, p_world: Node2D) -> void:
	main = p_main
	world = p_world


func build_market_stall() -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = MARKET_STALL_POS

	var shadow := Sprite2D.new()
	shadow.texture = TextureGen.get_tex("stall_shadow")
	shadow.position = Vector2(2, -4)
	body.add_child(shadow)

	var spr := Sprite2D.new()
	var tex: Texture2D = TextureGen.get_tex("market_stall")
	spr.texture = tex
	spr.offset = Vector2(0, -tex.get_height() / 2.0)
	body.add_child(spr)

	stall_crate_sprites.clear()
	var crate_offsets: Array[Vector2] = [
		Vector2(-20.5, -36.0), Vector2(-6.5, -36.0), Vector2(7.5, -36.0),
		Vector2(-20.5, -27.0), Vector2(-6.5, -27.0), Vector2(7.5, -27.0),
	]
	for i in 6:
		var cs := Sprite2D.new()
		cs.name = "CrateFill_%d" % i
		cs.position = crate_offsets[i]
		cs.visible = false
		body.add_child(cs)
		stall_crate_sprites.append(cs)

	stall_coin_badge = PanelContainer.new()
	stall_coin_badge.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.16, 0.08, 0.95), UIKit.COLOR_BORDER_GOLD, 6))
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 4)
	stall_coin_badge.add_child(ch)
	var mic := TextureRect.new()
	mic.texture = TextureGen.coin_icon()
	mic.custom_minimum_size = Vector2(14, 14)
	mic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ch.add_child(mic)
	stall_coin_label = UIKit.label(ch, "0 xu", 11, UIKit.COLOR_TEXT_GOLD)
	stall_coin_badge.position = Vector2(8, -52)
	stall_coin_badge.visible = false
	body.add_child(stall_coin_badge)

	var ctw := main.create_tween().set_loops()
	ctw.tween_property(stall_coin_badge, "position:y", -55.0, 0.7).set_trans(Tween.TRANS_SINE)
	ctw.tween_property(stall_coin_badge, "position:y", -49.0, 0.7).set_trans(Tween.TRANS_SINE)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(104, 24)
	col.shape = shape
	col.position = Vector2(0, -14)
	body.add_child(col)

	world.add_child(body)
	update_stall_crates_visual()
	update_stall_coin_badge()
	return body


func update_stall_coin_badge() -> void:
	if stall_coin_badge == null:
		return
	stall_coin_badge.visible = stall_revenue > 0
	if stall_coin_label != null:
		stall_coin_label.text = "%d xu" % stall_revenue


func update_stall_crates_visual() -> void:
	for i in 6:
		if i >= stall_crate_sprites.size():
			continue
		var cs: Sprite2D = stall_crate_sprites[i]
		if i < stall_slots.size() and stall_slots[i] != null and not stall_slots[i].is_empty():
			var slot: Dictionary = stall_slots[i]
			var sid: String = str(slot.get("id", ""))
			var stype: String = str(slot.get("type", "crop"))
			var count: int = int(slot.get("count", 0))
			if sid != "" and count > 0:
				cs.texture = TextureGen.get_crate_fill_tex(sid, stype)
				cs.visible = true
			else:
				cs.visible = false
		else:
			cs.visible = false


func on_stall_changed() -> void:
	update_stall_crates_visual()
	main._save_now()


func process_stall_customers(delta: float) -> void:
	var t := GameState.clock

	var alive: Array[Node2D] = []
	for c in _stall_customers:
		if is_instance_valid(c):
			alive.append(c)
	_stall_customers = alive
	_active_stall_customer = _stall_customers[0] if not _stall_customers.is_empty() else null

	if t >= 1260.0 or t < 420.0:
		for c in _stall_customers:
			if is_instance_valid(c) and c.state == StallCustomerScript.State.WAITING:
				c.dismiss_for_night()
		return

	if _stall_customers.size() >= 3:
		return

	_stall_customer_timer += delta
	if _stall_customer_timer < _next_stall_customer_delay:
		return
	_stall_customer_timer = 0.0
	_next_stall_customer_delay = randf_range(16.0, 26.0)

	spawn_stall_customer()


func spawn_stall_customer(forced_slot_idx: int = -1) -> Node2D:
	var occupied_spots: Array[Vector2] = []
	for c in _stall_customers:
		if is_instance_valid(c):
			occupied_spots.append(c.target_stall_pos)

	var free_spots: Array[Vector2] = []
	for spot in STALL_COUNTER_SPOTS:
		if not spot in occupied_spots:
			free_spots.append(spot)

	if free_spots.is_empty():
		return null

	var chosen_spot: Vector2 = free_spots[randi() % free_spots.size()]

	var available_chars := []
	for d in SDV_CUSTOMERS_DATA:
		var in_use := false
		for c in _stall_customers:
			if is_instance_valid(c) and c.display_name == str(d.name):
				in_use = true
				break
		if not in_use:
			available_chars.append(d)

	var cdata: Dictionary = available_chars[randi() % available_chars.size()] if not available_chars.is_empty() else SDV_CUSTOMERS_DATA[randi() % SDV_CUSTOMERS_DATA.size()]

	var target_item: Dictionary = {}
	var stocked_indices: Array[int] = []
	for i in stall_slots.size():
		var slot = stall_slots[i]
		if typeof(slot) == TYPE_DICTIONARY and not slot.is_empty() and int(slot.get("count", 0)) > 0:
			stocked_indices.append(i)

	if forced_slot_idx >= 0 and forced_slot_idx < stall_slots.size() and not stall_slots[forced_slot_idx].is_empty():
		var slot: Dictionary = stall_slots[forced_slot_idx]
		target_item = {
			"id": str(slot.get("id", "")),
			"type": str(slot.get("type", "crop")),
			"name": str(slot.get("name", "Nông sản")),
			"price": int(slot.get("price", 10)),
			"qty": mini(int(slot.get("count", 1)), randi_range(1, 3))
		}
	elif not stocked_indices.is_empty() and randf() < 0.65:
		var idx: int = stocked_indices[randi() % stocked_indices.size()]
		var slot: Dictionary = stall_slots[idx]
		target_item = {
			"id": str(slot.get("id", "")),
			"type": str(slot.get("type", "crop")),
			"name": str(slot.get("name", "Nông sản")),
			"price": int(slot.get("price", 10)),
			"qty": mini(int(slot.get("count", 1)), randi_range(1, 3))
		}
	else:
		var w_item: Dictionary = STALL_WISHLIST_ITEMS[randi() % STALL_WISHLIST_ITEMS.size()]
		var bp: int = int(w_item.get("base_price", 20))
		target_item = {
			"id": str(w_item.get("id", "wheat")),
			"type": str(w_item.get("type", "crop")),
			"name": str(w_item.get("name", "Lúa mì")),
			"price": maxi(1, int(round(float(bp) * 1.2))),
			"qty": randi_range(1, 3)
		}

	var cust: Node2D = StallCustomerScript.new()
	cust.character_name = str(cdata.asset)
	cust.display_name = str(cdata.name)
	cust.target_stall_pos = chosen_spot
	cust.stall_slots = stall_slots

	cust.item_id = str(target_item.get("id", "wheat"))
	cust.item_type = str(target_item.get("type", "crop"))
	cust.item_name = str(target_item.get("name", "Lúa mì"))
	cust.unit_price = int(target_item.get("price", 10))
	cust.buy_qty = int(target_item.get("qty", 1))

	cust.purchase_completed.connect(on_stall_customer_purchased)
	cust.wait_timeout_expired.connect(func(who: String, what: String):
		if is_instance_valid(main.hud):
			main.hud.toast("%s: Đợi một lúc không thấy có %s nên đành về vậy... 💨" % [who, what], Color(0.95, 0.75, 0.55))
	)
	cust.departed.connect(func():
		_stall_customers.erase(cust)
		if _active_stall_customer == cust:
			_active_stall_customer = _stall_customers[0] if not _stall_customers.is_empty() else null
	)

	_stall_customers.append(cust)
	_active_stall_customer = cust
	world.add_child(cust)
	return cust


func on_stall_customer_purchased(slot_idx: int, item_name: String, qty: int, coins: int, buyer_name: String = "") -> void:
	if slot_idx >= 0 and slot_idx < stall_slots.size():
		var slot: Dictionary = stall_slots[slot_idx]
		if not slot.is_empty():
			var cur: int = int(slot.get("count", 0))
			var actual_qty: int = mini(cur, qty)
			slot["count"] = cur - actual_qty
			if int(slot["count"]) <= 0:
				stall_slots[slot_idx] = {}
			update_stall_crates_visual()
			if main.stall_panel != null and main.stall_panel.visible:
				main.stall_panel.stall_slots = stall_slots
				main.stall_panel.stall_revenue = stall_revenue + coins
				main.stall_panel._refresh_ui()

	stall_revenue += coins
	update_stall_coin_badge()
	var who := buyer_name if buyer_name != "" else "Khách"
	if is_instance_valid(main.hud):
		main.hud.toast("%s ghé mua %d %s! Có %d xu chờ thu tại sạp 🏪" % [who, qty, item_name, stall_revenue], Color(1.0, 0.88, 0.4))
	if main.quest_mgr != null:
		main.quest_mgr.advance_progress("stall_sell", "any", qty)
	main._save_now()


func decline_stall_customer(cust: Node2D) -> void:
	if not is_instance_valid(cust) or cust.state != StallCustomerScript.State.WAITING:
		return
	cust.decline()
	if is_instance_valid(main.hud):
		main.hud.toast("%s: Tiếc quá, hẹn hôm khác nhé! 👋" % cust.display_name, Color(1.0, 0.85, 0.5))


func open_market_stall() -> void:
	main.mode = main.Mode.PANEL
	main.get_tree().paused = true
	main.stall_panel.open(stall_slots, stall_revenue)


func on_stall_revenue_collected(_amt: int) -> void:
	stall_revenue = 0
	update_stall_coin_badge()
	main._save_now()


func clear_night_customers() -> void:
	for c in _stall_customers:
		if is_instance_valid(c):
			c.queue_free()
	_stall_customers.clear()
	_active_stall_customer = null
