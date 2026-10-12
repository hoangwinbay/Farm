extends SceneTree

const TextureGen := preload("res://scripts/texture_gen.gd")
const NpcScript := preload("res://scripts/npc.gd")
const DialogueBoxScript := preload("res://scripts/ui/dialogue_box.gd")

func _init() -> void:
	print("--- BAT DAU KIEM THU ASSET TRUONG THON ---")
	
	# 1. TextureGen.npc_tex("truong_thon")
	var tex := TextureGen.npc_tex("truong_thon")
	assert(tex != null, "TextureGen.npc_tex('truong_thon') khong duoc null!")
	print("1. npc_tex('truong_thon') thanh cong: size = ", tex.get_size())
	assert(tex.get_width() > 0 and tex.get_height() > 0, "Kich thuoc texture phai hop le!")
	
	# 2. TextureGen.truong_thon_avatar()
	var av := TextureGen.truong_thon_avatar()
	assert(av != null, "TextureGen.truong_thon_avatar() khong duoc null!")
	print("2. truong_thon_avatar() thanh cong: size = ", av.get_size())
	assert(av.get_width() > 0 and av.get_height() > 0, "Kich thuoc avatar phai hop le!")
	
	# 3. NpcScript instance
	var npc = NpcScript.new()
	npc.npc_name = "Trưởng Thôn"
	npc._ready()
	print("3. NpcScript Trưởng Thôn da khoi tao.")
	assert(npc.spr != null, "Sprite khong duoc null!")
	assert(npc.spr.texture == tex, "Sprite phai dung texture truong_thon!")
	print("   - spr.scale: ", npc.spr.scale)
	print("   - spr.offset: ", npc.spr.offset)
	var visual_h: float = float(tex.get_height()) * float(npc.spr.scale.y)
	print("   - Chieu cao tren man hinh: ", visual_h, " px")
	assert(visual_h >= 38.0 and visual_h <= 45.0, "Chieu cao phai can doi voi cac nhan vat khac!")
	
	# 4. DialogueBoxScript test
	var dlg = DialogueBoxScript.new()
	dlg._ready()
	
	# Test Truong Thon dialogue
	dlg.start("Trưởng Thôn", ["Chào mừng cháu đến với làng!"])
	assert(dlg.avatar_container.visible == true, "Avatar container phai visible voi Truong Thon!")
	assert(dlg.avatar_rect.texture != null, "Avatar texture phai hop le!")
	assert(dlg.name_label.text == "📜 Trưởng Thôn", "Name label phai co icon 📜 Truong Thon!")
	print("4. Hop thoai Trưởng Thôn hien thi avatar & the ten: PASS")
	
	# Test Bac Tu dialogue (has avatar)
	dlg.start("Bác Tư", ["Chào con!"])
	assert(dlg.avatar_container.visible == true, "Avatar container phai hien voi Bac Tu!")
	assert(dlg.name_label.text == "🌾 Bác Tư", "Name label phai la 🌾 Bac Tu!")
	print("5. Hop thoai Bác Tư co avatar: PASS")

	# Test object dialogue (no avatar)
	dlg.start("Biển Báo", ["Chu y nguy hiem"])
	assert(dlg.avatar_container.visible == false, "Avatar container phai an voi Bien Bao!")
	print("5.1 Hop thoai Bien Bao an avatar: PASS")
	
	# Test Ask dialogue
	dlg.ask("Di ngu?")
	assert(dlg.avatar_container.visible == false, "Avatar container phai an khi hoi ask mode!")
	print("6. Hop thoai ask mode: PASS")
	
	print("=== KIEM THU ASSET TRUONG THON HOAN TAT 100% THANH CONG ===")
	quit()
