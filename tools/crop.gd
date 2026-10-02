extends SceneTree
func _init() -> void:
	var img := Image.load_from_file("C:/Users/Admin/AppData/Roaming/Godot/app_userdata/Nong Trai Viet/shot_13_pen.png")
	var crop := img.get_region(Rect2i(680, 260, 240, 200))
	crop.resize(480, 400, Image.INTERPOLATE_NEAREST)
	crop.save_png("C:/Users/Admin/AppData/Roaming/Godot/app_userdata/Nong Trai Viet/crop.png")
	print("CROP OK")
	quit()
