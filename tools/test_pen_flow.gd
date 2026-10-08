extends SceneTree
# Test mô phỏng đúng luồng chơi thật: mua chuồng -> mua con -> cho ăn -> tick -> thu hoạch

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var Inv = root.get_node("/root/Inventory")
	var GS = root.get_node("/root/GameState")

	Inv.reset()
	GS.money = 99999

	# 1. Mua chuồng gà cấp 1
	var r1: String = Inv.buy_coop("chicken")
	print("1. buy_coop(chicken) err='", r1, "' tier=", Inv.get_coop_tier("chicken"), " (kỳ vọng '' / 1)")

	# 2. Mua 1 con gà
	var r2: String = Inv.buy_animal("chicken")
	print("2. buy_animal(chicken) err='", r2, "' animals=", Inv.animals.size(), " (kỳ vọng '' / 1)")

	# 3. Mua cám + cho ăn
	Inv.add_feed(5)
	print("3. feed_count=", Inv.feed_count())
	var fed: int = Inv.feed_all_hungry_for_species("chicken")
	print("4. feed_all -> fed=", fed, " (kỳ vọng 1), cám còn=", Inv.feed_count())

	# 5. Tick từng giây như game thật (25s interval)
	var ready_at: float = -1.0
	for i in 60:
		Inv.tick_animals(1.0)
		if Inv.ready_products_for_species("chicken") > 0 and ready_at < 0.0:
			ready_at = float(i + 1)
	print("5. ready sau ", ready_at, "s (kỳ vọng ~25), ready_products=", Inv.ready_products_for_species("chicken"))

	# 6. Thu hoạch
	var n: int = Inv.collect_products_for_species("chicken")
	print("6. collect -> n=", n, " trung_ga=", Inv.produce_count("trung_ga"), " (kỳ vọng 1 / 1)")

	# 7. Cho ăn lại ngay sau thu hoạch
	var fed2: int = Inv.feed_all_hungry_for_species("chicken")
	print("7. cho ăn lại -> fed=", fed2, " (kỳ vọng 1)")

	# 8. Trường hợp túi đồ đầy: nhồi đầy backpack rồi thu
	Inv.tick_animals(30.0)
	var used_before: int = Inv.backpack_slots_used()
	for i in range(0, Inv.backpack_max + 5):
		Inv.add_produce("rice", 1)
	var n_full: int = Inv.collect_products_for_species("chicken")
	print("8. túi đầy -> slots=", Inv.backpack_slots_used(), "/", Inv.backpack_max,
			" collect=", n_full, " (kỳ vọng 0 nếu đầy, sản phẩm vẫn ready=", Inv.ready_products_for_species("chicken"), ")")

	# 9. Test con non không sinh sản phẩm
	Inv.animals.append({"id": "chicken", "is_baby": true, "fed": true, "progress": 0.0, "ready": 0, "grow_progress": 0.0, "is_sheared": false})
	Inv.tick_animals(30.0)
	var adult_ready: int = 0
	var baby_ready: int = 0
	for a in Inv.animals:
		if bool(a.get("is_baby", false)):
			baby_ready += int(a.get("ready", 0))
		else:
			adult_ready += int(a.get("ready", 0))
	print("9. baby_ready=", baby_ready, " (kỳ vọng 0), adult_ready=", adult_ready)

	# 10. Bò/sợi interval dài hơn
	Inv.buy_coop("cow")
	Inv.buy_animal("cow")
	Inv.add_feed(5)
	Inv.feed_all_hungry_for_species("cow")
	Inv.tick_animals(44.0)
	var cow_ready_44: int = Inv.ready_products_for_species("cow")
	Inv.tick_animals(2.0)
	var cow_ready_46: int = Inv.ready_products_for_species("cow")
	print("10. bò ready@44s=", cow_ready_44, " (kỳ vọng 0), ready@46s=", cow_ready_46, " (kỳ vọng 1)")

	print("PEN_FLOW_TEST_DONE")
	quit()
