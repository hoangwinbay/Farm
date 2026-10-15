extends SceneTree
# Test chuyên sâu giao diện khởi đầu mới: Fluffy Farm Title Screen

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	print("--- BAT DAU KIEM THU GIAO DIEN FLUFFY FARM TITLE SCREEN ---")
	var TitleScreenScript = load("res://scripts/ui/title_screen.gd")
	assert(TitleScreenScript != null, "Loi: Khong load duoc title_screen.gd")

	var ts = TitleScreenScript.new()
	root.add_child(ts)

	for i in 5:
		await physics_frame

	# 1. Kiem tra khoi tao & cac thanh phan UI
	print("1. Kiem tra start_btn hop le: ", is_instance_valid(ts.start_btn), " (is Button: ", ts.start_btn is Button, ")")
	assert(is_instance_valid(ts.start_btn) and ts.start_btn is Button, "Loi: start_btn khong phai Button!")
	assert(is_instance_valid(ts._continue_btn) and ts._continue_btn is Button, "Loi: _continue_btn khong phai Button!")
	assert(is_instance_valid(ts._guide), "Loi: _guide khong hop le!")
	assert(is_instance_valid(ts._guide_overlay), "Loi: _guide_overlay khong hop le!")

	# 2. Kiem tra texture cua cac nut go va hinh nen
	var bg_tr = ts.get_node_or_null("Control/TextureRect")
	if bg_tr == null:
		# Find TextureRect in children
		for c in ts.get_children():
			if c is Control:
				for cc in c.get_children():
					if cc is TextureRect:
						bg_tr = cc
						break
	print("2.1 TextureRect hinh nen Fluffy Farm: ", bg_tr != null and bg_tr.texture != null)
	assert(bg_tr != null and bg_tr.texture != null, "Loi: Khong load duoc title_bg.png!")

	var btn_start_tr = ts.start_btn.get_node_or_null("Texture")
	print("2.2 Texture nut Bat dau moi: ", btn_start_tr != null and btn_start_tr.texture != null)
	assert(btn_start_tr != null and btn_start_tr.texture != null, "Loi: Khong load duoc btn_new_game.png!")

	var btn_cont_tr = ts._continue_btn.get_node_or_null("Texture")
	print("2.3 Texture nut Tiep tuc: ", btn_cont_tr != null and btn_cont_tr.texture != null)
	assert(btn_cont_tr != null and btn_cont_tr.texture != null, "Loi: Khong load duoc btn_continue.png!")

	# 3. Kiem tra trang thai has_save = false
	ts.open(false)
	print("3.1 Khi has_save = false -> _continue_btn.disabled: ", ts._continue_btn.disabled)
	assert(ts._continue_btn.disabled == true, "Loi: Khi khong co file save nut Tiep tuc phai bi disable!")

	# 4. Kiem tra trang thai has_save = true
	ts.open(true)
	print("3.2 Khi has_save = true -> _continue_btn.disabled: ", ts._continue_btn.disabled)
	assert(ts._continue_btn.disabled == false, "Loi: Khi co file save nut Tiep tuc phai duoc enable!")

	# 5. Kiem tra tin hieu bat dau & tiep tuc
	var start_res := [false]
	ts.start_requested.connect(func(): start_res[0] = true)
	ts.start_btn.pressed.emit()
	print("4.1 Nhan tin hieu start_requested khi bam nut: ", start_res[0])
	assert(start_res[0], "Loi: start_requested khong phat khi bam start_btn!")

	var cont_res := [false]
	ts.continue_requested.connect(func(): cont_res[0] = true)
	ts._continue_btn.pressed.emit()
	print("4.2 Nhan tin hieu continue_requested khi bam nut: ", cont_res[0])
	assert(cont_res[0], "Loi: continue_requested khong phat khi bam _continue_btn!")

	# 6. Kiem tra mo/dong huong dan
	assert(not ts._guide_overlay.visible, "Ban dau guide phai an!")
	ts.open(false)
	# Tim nut guide trong tree
	var guide_btn: Button
	for c in ts.start_btn.get_parent().get_children():
		if c is Button and c != ts.start_btn and c != ts._continue_btn:
			guide_btn = c
			break
	assert(guide_btn != null, "Loi: Khong tim thay guide_btn!")
	guide_btn.pressed.emit()
	print("5.1 Mo huong dan -> _guide_overlay.visible: ", ts._guide_overlay.visible)
	assert(ts._guide_overlay.visible, "Loi: Bang huong dan phai hien khi bam nut!")

	# Dong huong dan
	var close_btn: Button
	for c in ts._guide.get_children():
		if c is VBoxContainer:
			for cc in c.get_children():
				if cc is HBoxContainer:
					for ccc in cc.get_children():
						if ccc is Button:
							close_btn = ccc
							break
	if close_btn != null:
		close_btn.pressed.emit()
	print("5.2 Dong huong dan -> _guide_overlay.visible: ", ts._guide_overlay.visible)
	assert(not ts._guide_overlay.visible, "Loi: Bang huong dan phai dong khi bam dong!")

	# 7. Kiem tra hide_me
	ts.hide_me()
	print("6. Kiem tra hide_me() -> visible: ", ts.visible)
	assert(not ts.visible, "Loi: hide_me() phai an title screen!")

	# 8. Kiem tra kich thuoc 2 o duoi bang o tren cung
	print("7. Kiem tra dong bo kich thuoc 3 nut:")
	print("   - Start btn size: ", ts.start_btn.size, " min_size: ", ts.start_btn.custom_minimum_size)
	print("   - Continue btn size: ", ts._continue_btn.size, " min_size: ", ts._continue_btn.custom_minimum_size)
	print("   - Guide btn size: ", guide_btn.size, " min_size: ", guide_btn.custom_minimum_size)
	assert(ts.start_btn.custom_minimum_size == ts._continue_btn.custom_minimum_size, "Loi: Tiep tuc phai bang Bat dau moi!")
	assert(ts.start_btn.custom_minimum_size == guide_btn.custom_minimum_size, "Loi: Huong dan phai bang Bat dau moi!")
	assert(ts.start_btn.size == ts._continue_btn.size, "Loi: Size thuc te Tiep tuc phai bang Bat dau moi!")
	assert(ts.start_btn.size == guide_btn.size, "Loi: Size thuc te Huong dan phai bang Bat dau moi!")
	assert(abs(ts.start_btn.global_position.x - ts._continue_btn.global_position.x) < 0.1, "Loi: 2 nut tren phai thang hang!")
	assert(abs(ts.start_btn.global_position.x - guide_btn.global_position.x) < 0.1, "Loi: Nut duoi cung phai thang hang!")
	print("   -> Ca 3 o nut go deu hoan toan bang nhau va thang hang tuyet doi!")

	print("=== KIEM THU FLUFFY FARM TITLE SCREEN THANH CONG 100% ===")
	quit(0)
