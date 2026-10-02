extends SceneTree
# Công cụ kiểm tra: gộp 16 ảnh cây CHÍN (nhánh picture/ trong texture_gen)
# thành 1 bảng PNG để xem nhanh. Chạy:
#   Godot --path D:\Farm --headless --script res://tools/ripe_preview.gd

func _init() -> void:
	var TG := preload("res://scripts/texture_gen.gd")
	var db := preload("res://scripts/crop_db.gd")
	var cols := 4
	var cell := 32
	var rows := int(ceil(db.CROPS.size() / float(cols)))
	var grid := Image.create_empty(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
	var missing: Array = []
	for i in db.CROPS.size():
		var c: Dictionary = db.CROPS[i]
		var img: Image = TG.ripe_picture_img(str(c.id))
		if img == null:
			missing.append("%s (%s)" % [c.id, db.picture_path(str(c.id))])
			continue
		var r := int(floor(i / float(cols)))
		grid.blend_rect(img, Rect2i(0, 0, 32, 32), Vector2i((i % cols) * cell, r * cell))
	grid.resize(cols * cell * 6, rows * cell * 6, Image.INTERPOLATE_NEAREST)
	var out := "C:/Users/Admin/AppData/Roaming/Godot/app_userdata/Nong Trai Viet/ripe_grid.png"
	grid.save_png(out)
	print("SAVED: ", out)
	print("MISSING: ", missing if not missing.is_empty() else "không có")
	# kiểm tra thêm đường texture trong game (stage 3)
	for i in db.CROPS.size():
		var t := TG.crop_tex(db.CROPS[i], 3)
		print(db.CROPS[i].id, " -> ", t.get_size())
	quit()
