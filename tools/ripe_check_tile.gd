extends SceneTree
# Kiểm tra tích hợp: ô đất trồng lúa khi CHÍN phải hiện ảnh picture/ (32x32),
# khi đang lớn vẫn là pixel-art 16x16.

func _init() -> void:
	var FT := load("res://scripts/farm_tile.gd")
	var t = FT.new()
	t._ready()  # ngoài cây scene nên gọi tay để tạo sprite
	t.setup(Vector2i(0, 0))
	t.till()
	t.plant("rice")
	t.water()
	t.growth = 999.0
	t.refresh()
	print("ready=", t.is_ready(), " ripe_tex=", t._crop_spr.texture.get_size(), " visible=", t._crop_spr.visible)
	t.growth = 10.0
	t.refresh()
	print("growing_tex=", t._crop_spr.texture.get_size())
	quit()
