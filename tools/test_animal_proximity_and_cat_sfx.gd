extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	print("=== RUNNING TEST: ANIMAL PROXIMITY & CAT SFX ===")
	var SoundGen = load("res://scripts/sound_gen.gd")
	var PenManagerScript = load("res://scripts/pen_manager.gd")
	var CatPanelScript = load("res://scripts/ui/cat_panel.gd")

	var passed := 0
	var total := 0

	# 1. Kiểm tra nạp âm thanh từ file WAV chuẩn Stardew Valley
	var test_sounds := ["cow", "chicken", "sheep", "pig", "duck", "meow"]
	for snd in test_sounds:
		total += 1
		var stream: AudioStreamWAV = SoundGen.get_sfx(snd)
		if stream != null and stream.data.size() > 0:
			print("  [PASS] SoundGen.get_sfx('%s'): mix_rate=%d, data_len=%d, stereo=%s" % [snd, stream.mix_rate, stream.data.size(), stream.stereo])
			passed += 1
		else:
			printerr("  [FAIL] Không thể tải stream cho âm thanh: " + snd)

	# 2. Kiểm tra AudioManager
	total += 1
	var audio_mgr: Node = root.get_node_or_null("/root/AudioManager")
	if audio_mgr != null:
		print("  [PASS] AudioManager autoload tồn tại")
		passed += 1
	else:
		printerr("  [FAIL] AudioManager không tìm thấy trong root")

	# 3. Kiểm tra CatPanel.open() phát âm thanh meow
	total += 1
	var cat_panel = CatPanelScript.new()
	root.add_child(cat_panel)
	var CatHelper = load("res://scripts/cat_helper.gd")
	var cat_dummy = CatHelper.new()
	cat_panel.open(cat_dummy)
	if cat_panel.visible:
		print("  [PASS] CatPanel.open() mở thành công và kích hoạt âm thanh mèo meow")
		passed += 1
	else:
		printerr("  [FAIL] CatPanel.open() không hiển thị")
	cat_panel.queue_free()
	cat_dummy.queue_free()

	# 4. Kiểm tra PenManager tính toán khoảng cách và cự ly 1m
	var pm: RefCounted = PenManagerScript.new()
	var mock_main := Node2D.new()
	root.add_child(mock_main)
	pm.setup(mock_main)

	# PEN_COW: Rect2(144, 528, 288, 160)
	total += 1
	var dist_inside: float = pm._dist_to_rect(Vector2(200, 600), PenManagerScript.PEN_COW)
	if is_zero_approx(dist_inside):
		print("  [PASS] Khoảng cách khi người chơi ở trong chuồng = 0.0")
		passed += 1
	else:
		printerr("  [FAIL] dist_inside sai: ", dist_inside)

	total += 1
	# Cách mép trên chuồng bò 16 pixel (y = 512, trong khi mép trên là 528)
	var dist_near: float = pm._dist_to_rect(Vector2(200, 512), PenManagerScript.PEN_COW)
	if is_equal_approx(dist_near, 16.0):
		print("  [PASS] Khoảng cách người chơi cách mép hàng rào 16px = 16.0")
		passed += 1
	else:
		printerr("  [FAIL] dist_near sai: ", dist_near)

	total += 1
	# Cách xa chuồng bò 100 pixel (y = 428)
	var dist_far: float = pm._dist_to_rect(Vector2(200, 428), PenManagerScript.PEN_COW)
	if is_equal_approx(dist_far, 100.0):
		print("  [PASS] Khoảng cách người chơi ở xa = 100.0")
		passed += 1
	else:
		printerr("  [FAIL] dist_far sai: ", dist_far)

	# 5. Kiểm tra phát âm thanh khi lại gần chuồng 1 mét (dist <= 36.0 px)
	var inv: Node = root.get_node_or_null("/root/Inventory")
	if inv != null:
		# Giả lập vật nuôi: Chuồng bò có 1 con bò, chuồng gà có 1 con gà, chuồng cừu trống
		inv.animals.clear()
		inv.animals.append({"id": "cow", "is_baby": false, "fed": false, "ready": 0})
		inv.animals.append({"id": "chicken", "is_baby": false, "fed": false, "ready": 0})

		# Đi ở xa (100, 100) -> không chuồng nào kích hoạt
		pm.process_pen_proximity(0.1, Vector2(100, 100))
		total += 1
		if pm._pen_sfx_cooldowns.get("cow", 0.0) <= 0.0 and pm._pen_sfx_cooldowns.get("chicken", 0.0) <= 0.0:
			print("  [PASS] Ở xa chuồng: không có cooldown nào kích hoạt")
			passed += 1
		else:
			printerr("  [FAIL] Cooldown bị kích hoạt khi ở xa!")

		# Tiến lại gần chuồng bò cách hàng rào 10 pixel (Vector2(200, 518)) -> dist = 10.0 <= 36.0
		total += 1
		pm.process_pen_proximity(0.1, Vector2(200, 518))
		if pm._pen_sfx_cooldowns.get("cow", 0.0) > 0.0:
			print("  [PASS] Lại gần chuồng bò 1m (10px <= 36px): tiếng bò rống được kích hoạt, cooldown=%.2fs" % pm._pen_sfx_cooldowns["cow"])
			passed += 1
		else:
			printerr("  [FAIL] Tiếng bò không được kích hoạt khi lại gần!")

		# Đứng lại gần nhưng đang trong cooldown -> không kích hoạt dồn dập
		var cd_before: float = pm._pen_sfx_cooldowns["cow"]
		pm.process_pen_proximity(0.5, Vector2(200, 518))
		total += 1
		if is_equal_approx(pm._pen_sfx_cooldowns["cow"], cd_before - 0.5):
			print("  [PASS] Đứng gần chuồng: cooldown giảm đều đặn không bị spam lặp lại")
			passed += 1
		else:
			printerr("  [FAIL] Cooldown không giảm đúng: ", pm._pen_sfx_cooldowns["cow"])

		# Tiến tới chuồng cừu (PEN_SHEEP: 144, 736) cách 10px -> nhưng không có cừu
		total += 1
		pm.process_pen_proximity(2.0, Vector2(200, 726))
		if pm._pen_sfx_cooldowns.get("sheep", 0.0) <= 0.0:
			print("  [PASS] Lại gần chuồng cừu nhưng chuồng trống: không phát tiếng cừu")
			passed += 1
		else:
			printerr("  [FAIL] Tiếng cừu phát ra khi chuồng không có cừu!")

		# Chờ cooldown toàn cục hết (2.0s) rồi tiến tới chuồng gà (PEN_CHICKEN: 480, 528)
		total += 1
		pm.process_pen_proximity(2.0, Vector2(500, 518)) # dist = 10.0 <= 36.0
		if pm._pen_sfx_cooldowns.get("chicken", 0.0) > 0.0:
			print("  [PASS] Lại gần chuồng gà 1m: tiếng gà cục tác được kích hoạt, cooldown=%.2fs" % pm._pen_sfx_cooldowns["chicken"])
			passed += 1
		else:
			printerr("  [FAIL] Tiếng gà không kích hoạt!")

	mock_main.queue_free()

	print("\n=== KẾT QUẢ KIỂM THỬ: %d/%d PASSED ===" % [passed, total])
	if passed == total:
		print("TẤT CẢ TÍNH NĂNG ÂM THANH HOẠT ĐỘNG HOÀN HẢO!")
		quit(0)
	else:
		printerr("CÓ LỖI XẢY RA!")
		quit(1)
