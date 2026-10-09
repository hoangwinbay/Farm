extends SceneTree

# Test kiem tra loi thoi gian cho cau ca:
# Khi tha cau va het 15s (ve 0s), dong thong bao "Đang thả câu... còn 0 giây" phai bien mat hoan toan.

var GameState: Node
var Inventory: Node

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	GameState = root.get_node("GameState")
	Inventory = root.get_node("Inventory")
	print("--- BAT DAU KIEM THU LOI THONG BAO THA CAU KHI VE 0 GIAY ---")
	var MainScript = load("res://scripts/main.gd")
	var main = MainScript.new()
	root.add_child(main)

	for i in 10:
		await physics_frame

	main.start_new_game()

	for i in 10:
		await physics_frame

	# 1. Trang bi can cau cho nguoi choi va di chuyen den bo ao
	Inventory.add_rod("basic", 5)
	Inventory.active_item = {"type": "rod", "id": "basic", "name": "Cần tre", "casts": 5}
	main.player.position = main.FISH_SPOT_POS + Vector2(-40, 0)

	for i in 5:
		await physics_frame

	print("1.1 Vi tri nguoi choi: ", main.player.position, " | So luot cau: ", Inventory.total_casts())
	assert(Inventory.total_casts() > 0, "Loi: Khong co luot cau!")

	# 2. Bat dau tha cau
	main._start_fishing()
	print("2.1 Trang thai fishing sau khi tha cau: ", main.fishing)
	assert(main.fishing == true, "Loi: fishing phai la true!")
	print("2.2 fishing_left khoi diem: ", main.fishing_left)
	assert(main.fishing_left > 0.0, "Loi: fishing_left phai > 0!")

	# Chay 1 frame process
	main._process(0.1)
	print("2.3 Hint text khi dang cau: '", main.hud.hint_label.text, "' | Hint visible: ", main.hud.hint_container.visible)
	assert(main.hud.hint_container.visible == true, "Loi: Hint container phai hien khi dang cau!")
	assert(main.hud.hint_label.text.contains("Đang thả câu"), "Loi: Hint text phai chua 'Đang thả câu'!")

	# 3. Simulate thoi gian troi qua con 0.5s
	main.fishing_left = 0.5
	main._process(0.1)
	print("3.1 Khi con 0.4s: '", main.hud.hint_label.text, "'")
	assert(main.hud.hint_label.text.contains("Đang thả câu"), "Loi: Khi con thoi gian van phai hien!")

	# 4. Simulate thoi gian ve 0s (het gio cau)
	main._process(0.5) # delta = 0.5s se lam fishing_left tu 0.4s ve <= 0.0s
	print("4.1 Sau khi het 15s ve 0s -> Trang thai fishing: ", main.fishing)
	assert(main.fishing == false, "Loi: Sau khi het gio fishing phai ve false!")
	print("4.2 Hint text ngay sau khi het gio: '", main.hud.hint_label.text, "' | Hint visible: ", main.hud.hint_container.visible)
	assert(not main.hud.hint_label.text.contains("Đang thả câu... còn 0 giây"), "Loi: Thong bao 'Đang thả câu... còn 0 giây' khong duoc ton tai!")

	# 5. Chay them nhieu frame sau khi cau xong de chac chan khong bi ket thong bao
	for i in 10:
		main._process(0.016)

	print("5.1 Cac frame tiep theo -> Hint text: '", main.hud.hint_label.text, "'")
	assert(not main.hud.hint_label.text.contains("Đang thả câu... còn 0 giây"), "Loi: Thong bao 'còn 0 giây' van con ton tai o cac frame sau!")

	# 6. Kiem tra nguoi choi di chuyen duoc sau khi cau
	assert(main.player.can_move == true, "Loi: Nguoi choi phai di chuyen duoc sau khi thu can!")

	print("=== KIEM THU LOI THONG BAO THA CAU THANH CONG 100% ===")
	quit(0)
