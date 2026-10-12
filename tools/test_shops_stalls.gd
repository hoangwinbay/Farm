extends SceneTree

const TextureGen := preload("res://scripts/texture_gen.gd")
const NpcScript := preload("res://scripts/npc.gd")
const DialogueBoxScript := preload("res://scripts/ui/dialogue_box.gd")
const WorldBuilderScript := preload("res://scripts/world_builder.gd")

func _init() -> void:
	print("--- BAT DAU KIEM THU 3 CUA HANG CO TU, BAC TU, CHU HAI ---")

	# 1. Kiem tra texture 3 sap hang ti le chuan can doi voi Player (~60-70px width, ~70-80px height)
	var tex_tu: Texture2D = TextureGen.get_stand_tex("poultry")
	assert(tex_tu != null, "Texture stand_poultry khong duoc null!")
	print("1. Stand poultry texture: ", tex_tu.get_size())
	assert(tex_tu.get_width() >= 55 and tex_tu.get_width() <= 75 and tex_tu.get_height() >= 70 and tex_tu.get_height() <= 90, "Kich thuoc sap Co Tu phai can doi!")

	var tex_bac_tu: Texture2D = TextureGen.get_stand_tex("seed")
	assert(tex_bac_tu != null, "Texture stand_seed khong duoc null!")
	print("2. Stand seed texture: ", tex_bac_tu.get_size())
	assert(tex_bac_tu.get_width() >= 55 and tex_bac_tu.get_width() <= 75 and tex_bac_tu.get_height() >= 65 and tex_bac_tu.get_height() <= 80, "Kich thuoc sap Bac Tu phai can doi!")

	var tex_hai: Texture2D = TextureGen.get_stand_tex("fish")
	assert(tex_hai != null, "Texture stand_fish khong duoc null!")
	print("3. Stand fish texture: ", tex_hai.get_size())
	assert(tex_hai.get_width() >= 55 and tex_hai.get_width() <= 75 and tex_hai.get_height() >= 65 and tex_hai.get_height() <= 85, "Kich thuoc sap Chu Hai phai can doi!")

	# 2. Kiem tra avatar cua 3 thuong nhan
	var av_tu: Texture2D = TextureGen.co_tu_avatar()
	assert(av_tu != null, "Avatar Co Tu khong duoc null!")
	print("4. Co Tu avatar: ", av_tu.get_size())

	var av_bac_tu: Texture2D = TextureGen.bac_tu_avatar()
	assert(av_bac_tu != null, "Avatar Bac Tu khong duoc null!")
	print("5. Bac Tu avatar: ", av_bac_tu.get_size())

	var av_hai: Texture2D = TextureGen.chu_hai_avatar()
	assert(av_hai != null, "Avatar Chu Hai khong duoc null!")
	print("6. Chu Hai avatar: ", av_hai.get_size())

	# 3. Kiem tra hop thoai hien thi avatar tung nguoi
	var dlg = DialogueBoxScript.new()
	dlg._ready()

	dlg.start("Cô Tư", ["Gà vịt giống đây!"])
	assert(dlg.avatar_container.visible == true, "Avatar phai hien khi noi chuyen voi Co Tu!")
	assert(dlg.avatar_rect.texture == av_tu, "Texture avatar phai dung Co Tu!")
	assert(dlg.name_label.text == "🐔 Cô Tư", "Ten phai co icon 🐔!")
	print("7. Dialogue Co Tu avatar: PASS")

	dlg.start("Bác Tư", ["Hạt giống tốt day!"])
	assert(dlg.avatar_container.visible == true, "Avatar phai hien khi noi chuyen voi Bac Tu!")
	assert(dlg.avatar_rect.texture == av_bac_tu, "Texture avatar phai dung Bac Tu!")
	assert(dlg.name_label.text == "🌾 Bác Tư", "Ten phai co icon 🌾!")
	print("8. Dialogue Bac Tu avatar: PASS")

	dlg.start("Chú Hai", ["Cá tươi ngon day!"])
	assert(dlg.avatar_container.visible == true, "Avatar phai hien khi noi chuyen voi Chu Hai!")
	assert(dlg.avatar_rect.texture == av_hai, "Texture avatar phai dung Chu Hai!")
	assert(dlg.name_label.text == "🎣 Chú Hai", "Ten phai co icon 🎣!")
	print("9. Dialogue Chu Hai avatar: PASS")

	# 4. Kiem tra cac lop texture tach roi (bg, merchant, front) cho tung sap hang
	for s_id in ["poultry", "seed", "fish"]:
		var bg_l: Texture2D = TextureGen.get_stand_layer_tex(s_id, "bg")
		var mer_l: Texture2D = TextureGen.get_stand_layer_tex(s_id, "merchant")
		var fg_l: Texture2D = TextureGen.get_stand_layer_tex(s_id, "front")
		assert(bg_l != null, "Layer bg cua %s khong duoc null!" % s_id)
		assert(mer_l != null, "Layer merchant cua %s khong duoc null!" % s_id)
		assert(fg_l != null, "Layer front cua %s khong duoc null!" % s_id)
		assert(bg_l.get_size() == mer_l.get_size() and bg_l.get_size() == fg_l.get_size(), "Cac lop phai cung kich thuoc!")
		print("Layer check %s: PASS (size=%s)" % [s_id, bg_l.get_size()])

	# 5. Kiem tra tao sap hang qua WorldBuilder
	var wb = WorldBuilderScript.new()
	var test_world := Node2D.new()
	wb.world = test_world

	var npc_tu = NpcScript.new()
	npc_tu.npc_name = "Cô Tư"
	wb.add_shop_stall("poultry", WorldBuilderScript.STAND_TU_POS, npc_tu)

	var npc_bac_tu = NpcScript.new()
	npc_bac_tu.npc_name = "Bác Tư"
	wb.add_shop_stall("seed", WorldBuilderScript.STAND_POS, npc_bac_tu)

	var npc_hai = NpcScript.new()
	npc_hai.npc_name = "Chú Hai"
	wb.add_shop_stall("fish", WorldBuilderScript.STAND_HAI_POS, npc_hai)

	# Kiem tra so luong node duoc tao trong test_world
	print("10. So node con trong the gioi sau khi tao 3 sap hang: ", test_world.get_child_count())
	assert(test_world.get_child_count() == 9, "Phai tao du 9 node (3 shadow + 3 stall_body + 3 npc_obj)!")

	# Kiem tra cau truc cac lop ben trong stall_body (chi co MerchantSprite duoc chuyen dong)
	for i in [1, 4, 7]:
		var stall_body: StaticBody2D = test_world.get_child(i) as StaticBody2D
		assert(stall_body != null, "Node stall_body phai la StaticBody2D!")
		var spr_bg: Sprite2D = stall_body.get_node_or_null("StallBg") as Sprite2D
		var spr_mer: Sprite2D = stall_body.get_node_or_null("MerchantSprite") as Sprite2D
		var spr_fg: Sprite2D = stall_body.get_node_or_null("StallFg") as Sprite2D
		assert(spr_bg != null, "StallBg phai ton tai!")
		assert(spr_mer != null, "MerchantSprite phai ton tai!")
		assert(spr_fg != null, "StallFg phai ton tai!")
		assert(spr_bg.scale == Vector2.ONE and spr_bg.rotation == 0.0, "Khung sap phai dung yen!")
		assert(spr_fg.scale == Vector2.ONE and spr_fg.rotation == 0.0, "Quay hang phai dung yen!")
		print("Stall %d layer check: PASS (Bg, Mer, Fg verified)" % (i / 3 + 1))

	print("=== KIEM THU 3 CUA HANG CO TU, BAC TU, CHU HAI THANH CONG 100% ===")
	quit()
