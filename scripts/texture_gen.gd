extends RefCounted
# Vẽ toàn bộ pixel-art của game bằng code (không cần file ảnh ngoài).
# Mọi nơi dùng: const TextureGen := preload("res://scripts/texture_gen.gd")

const CropDB := preload("res://scripts/crop_db.gd")
const FishDB := preload("res://scripts/fish_db.gd")
const PoultryDB := preload("res://scripts/poultry_db.gd")

static var _cache: Dictionary = {}


# ---------- tiện ích vẽ ----------

static func _img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


static func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


static func px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


# Giá trị mặt nạ 1 kênh (dùng khi vẽ viền lối đi); ngoài biên coi như tắt.
static func _mask_on(img: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return false
	return img.get_pixel(x, y).r > 0.5


static func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			px(img, xx, yy, c)


static func circle(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			var dx := x + 0.5 - cx
			var dy := y + 0.5 - cy
			if dx * dx + dy * dy <= r * r + 0.4:
				px(img, x, y, c)


static func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(img, x, y, c)


# ---------- cache ----------

static func get_tex(key: String) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var tex: ImageTexture = null
	match key:
		"field":
			tex = _field()
		"tilled":
			tex = _tilled_variant("isolated", false)
		"tilled_wet":
			tex = _tilled_variant("isolated", true)
		"tilled_dark":
			tex = _tilled_variant("isolated", false, true)
		"tilled_isolated":
			tex = _tilled_variant("isolated", false)
		"tilled_left":
			tex = _tilled_variant("left", false)
		"tilled_mid":
			tex = _tilled_variant("mid", false)
		"tilled_right":
			tex = _tilled_variant("right", false)
		"tilled_wet_isolated":
			tex = _tilled_variant("isolated", true)
		"tilled_wet_left":
			tex = _tilled_variant("left", true)
		"tilled_wet_mid":
			tex = _tilled_variant("mid", true)
		"tilled_wet_right":
			tex = _tilled_variant("right", true)
		"tilled_dark_isolated":
			tex = _tilled_variant("isolated", false, true)
		"tilled_dark_left":
			tex = _tilled_variant("left", false, true)
		"tilled_dark_mid":
			tex = _tilled_variant("mid", false, true)
		"tilled_dark_right":
			tex = _tilled_variant("right", false, true)
		"highlight":
			tex = _highlight()
		"tree":
			tex = _tree()
		"tree_oak":
			tex = _tree_variant("tree_oak")
		"tree_maple":
			tex = _tree_variant("tree_maple")
		"tree_pine":
			tex = _tree_variant("tree_pine")
		"tree_broadleaf":
			tex = _tree_variant("tree_broadleaf")
		"bush_large":
			tex = _tree_variant("bush_large")
		"bush_med":
			tex = _tree_variant("bush_med")
		"bush_small":
			tex = _tree_variant("bush_small")
		"bush_berry":
			tex = _tree_variant("bush_berry")
		"tree_stump":
			tex = _tree_variant("tree_stump")
		"house":
			tex = _house()
		"cave_entrance":
			tex = cave_entrance_tex()
		"mine_sign":
			tex = mine_sign_tex()
		"mine_floor":
			tex = mine_floor_tex()
		"mine_wall":
			tex = mine_wall_tex()
		"mine_ladder_down":
			tex = mine_ladder_tex(true)
		"mine_ladder_up":
			tex = mine_ladder_tex(false)
		"rock_stone":
			tex = mine_rock_tex("stone")
		"rock_copper":
			tex = mine_rock_tex("copper_ore")
		"rock_iron":
			tex = mine_rock_tex("iron_ore")
		"rock_gold":
			tex = mine_rock_tex("gold_ore")
		"rock_ruby":
			tex = mine_rock_tex("ruby")
		"rock_diamond":
			tex = mine_rock_tex("diamond")
		"pickaxe_icon":
			tex = pickaxe_icon("basic")
		"shed":
			tex = _shed()
		"tent":
			tex = _tent()
		"caterpillar":
			tex = _caterpillar()
		"fx_pest":
			tex = _fx_pest()
		"mailbox":
			tex = _mailbox()
		"stand":
			tex = _stand()
		"market_stall":
			tex = _market_stall()
		"stall_shadow":
			tex = _stall_shadow()
		"shadow":
			tex = shadow_tex()
		"scarecrow":
			tex = _scarecrow()
		"coop":
			tex = _coop()
		"coop_tier1":
			tex = _coop_tier1()
		"coop_tier2":
			tex = _coop_tier2()
		"barn_tier1":
			tex = _barn_tier1()
		"barn_tier2":
			tex = _barn_tier2()
		"pen_bedding":
			tex = _pen_bedding()
		"pen_dirt_bedding":
			tex = _pen_dirt_bedding()
		"trough":
			tex = _trough()
		"water_trough":
			tex = _water_trough()
		"feed", "feed_bag":
			tex = get_feed_icon()
		"hay_bale":
			tex = _hay_bale()
		"nest_box":
			tex = _nest_box()
		"fence_h":
			tex = _fence_h()
		"fence_v":
			tex = _fence_v()
		"fence_corner":
			tex = _fence_corner()
		"fence_corner_tl":
			tex = _fence_corner_dir("tl")
		"fence_corner_tr":
			tex = _fence_corner_dir("tr")
		"fence_corner_bl":
			tex = _fence_corner_dir("bl")
		"fence_corner_br":
			tex = _fence_corner_dir("br")
		"gate":
			tex = _gate()
		"gate_v":
			tex = _gate_v()
		"gate_coop":
			tex = _coop_gate()
		"stand_seed_roof":
			tex = _stand_seed_roof()
		"stand_seed_back":
			tex = _stand_seed_back()
		"stand_seed_front":
			tex = _stand_seed_front()
		"stand_poultry_roof":
			tex = _stand_poultry_roof()
		"stand_poultry_back":
			tex = _stand_poultry_back()
		"stand_poultry_front":
			tex = _stand_poultry_front()
		"stand_fish_roof":
			tex = _stand_fish_roof()
		"stand_fish_back":
			tex = _stand_fish_back()
		"stand_fish_front":
			tex = _stand_fish_front()
		"fx_till":
			tex = _fx_till()
		"fx_plant":
			tex = _fx_plant()
		"fx_water":
			tex = _fx_water()
		"fx_harvest":
			tex = _fx_harvest()
		"fx_rod":
			tex = _fx_rod()
		"fx_bobber":
			tex = _fx_bobber()
	if tex != null:
		_cache[key] = tex
	return tex


# ---------- nền đất (bake 1 ảnh lớn) ----------

static func _autotile_terrain(img: Image, atlas: Image, grid: Array, gw: int, gh: int, is_dirt: bool, rng: RandomNumberGenerator, fgx0: int = 50, fgx1: int = 81) -> void:

	for gy in range(gh):
		for gx in range(gw):
			if not grid[gy][gx]:
				continue
			var n: bool = grid[gy - 1][gx] if gy > 0 else false
			var s: bool = grid[gy + 1][gx] if gy < gh - 1 else false
			var w_val: bool = grid[gy][gx - 1] if gx > 0 else false
			var e: bool = grid[gy][gx + 1] if gx < gw - 1 else false

			# Mở thông tại các vị trí cổng kết nối với đường đi (không bị chặn cỏ)
			if is_dirt:
				if gx == fgx0 and (gy >= 28 and gy <= 31):
					w_val = true # Cổng Tây ruộng nối đại lộ
				elif gx == (fgx1 - 1) and (gy >= 28 and gy <= 31):
					e = true # Cổng Đông ruộng nối đại lộ
				elif gy == 41 and (gx in [22, 23, 39, 40]):
					s = true # Cổng chuồng Bò và Gà mở về phía nam ra đường đá
				elif gy == 45 and (gx in [22, 23, 39, 40]):
					n = true # Cổng chuồng Cừu và Lợn mở về phía bắc ra đường đá

			var nw: bool = grid[gy - 1][gx - 1] if gy > 0 and gx > 0 else false
			var ne: bool = grid[gy - 1][gx + 1] if gy > 0 and gx < gw - 1 else false
			var sw: bool = grid[gy + 1][gx - 1] if gy < gh - 1 and gx > 0 else false
			var se: bool = grid[gy + 1][gx + 1] if gy < gh - 1 and gx < gw - 1 else false

			var tile_idx: int = 4
			# Góc lồi bo tròn ngoài (Outer convex corners)
			if not n and not w_val and s and e:
				tile_idx = 0
			elif not n and not e and s and w_val:
				tile_idx = 2
			elif not s and not w_val and n and e:
				tile_idx = 6
			elif not s and not e and n and w_val:
				tile_idx = 8
			# Mép thẳng (Straight edges)
			elif not n and s:
				tile_idx = 1
			elif not s and n:
				tile_idx = 7
			elif not w_val and e:
				tile_idx = 3
			elif not e and w_val:
				tile_idx = 5
			# Lòng trong & góc lõm nối ngã ba / ngã tư (Inner Concave Corners)
			else:
				if not nw and ne and sw and se:
					tile_idx = 9
				elif not ne and nw and sw and se:
					tile_idx = 10
				elif not sw and nw and ne and se:
					tile_idx = 11
				elif not se and nw and ne and sw:
					tile_idx = 12
				else:
					if is_dirt:
						var r := rng.randf()
						if r < 0.08:
							tile_idx = 13 # viên sỏi (pebbles)
						elif r < 0.15:
							tile_idx = 14 # vết lõm (crater)
						elif r < 0.20:
							tile_idx = 15 # bụi cỏ nhỏ trên đất (weed tuft)
						else:
							tile_idx = 4
					else:
						var r := rng.randf()
						if r < 0.12:
							tile_idx = 15 # cỏ 4 lá (clover)
						else:
							tile_idx = 4

			var col: int = tile_idx % 8
			var row: int = tile_idx / 8
			img.blit_rect(atlas, Rect2i(col * 16, row * 16, 16, 16), Vector2i(gx * 16, gy * 16))


static func make_ground(w: int, h: int, farm_rect: Rect2, paths: Array, pond: Rect2, cobble_paths: Array = []) -> ImageTexture:
	var key := "ground"
	if _cache.has(key):
		return _cache[key]
	var img := _img(w, h)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260101
	var grass_tiles := _load_picture("res://picture/sdv_grass.png")
	if grass_tiles != null:
		# Lát mặt cỏ Stardew Valley chuẩn tỉ lệ và phân bổ tự nhiên
		for ty in range(0, h, 16):
			for tx in range(0, w, 16):
				var r := rng.randf()
				var tile_idx: int = rng.randi_range(0, 1) if r < 0.85 else rng.randi_range(2, 8)
				img.blit_rect(grass_tiles, Rect2i(tile_idx * 16, 0, 16, 16), Vector2i(tx, ty))
	else:
		img.fill(Color(0.294, 0.647, 0.114))
		for by in range(0, h, 64):
			for bx in range(0, w, 64):
				var r := rng.randf()
				if r < 0.35:
					img.fill_rect(Rect2i(bx, by, 64, 64), Color(0.27, 0.60, 0.10))
				elif r < 0.6:
					img.fill_rect(Rect2i(bx, by, 64, 64), Color(0.32, 0.68, 0.13))
		for i in 26000:
			var x := rng.randi_range(0, w - 1)
			var y := rng.randi_range(0, h - 1)
			if rng.randf() < 0.5:
				px(img, x, y, Color(0.25, 0.55, 0.09))
			else:
				px(img, x, y, Color(0.35, 0.72, 0.15))

	var gw: int = int(ceil(float(w) / 16.0))
	var gh: int = int(ceil(float(h) / 16.0))

	# 1. Mặt nạ khu vực được bảo vệ (không đặt mảng cỏ đậm hay vạt đất trống)
	var protected: Array = []
	for y in gh:
		var row: Array = []
		row.resize(gw)
		row.fill(false)
		protected.append(row)

	var protect_rect = func(rx: float, ry: float, rw: float, rh: float, pad: int = 1) -> void:
		var tx0: int = maxi(0, int(floor(rx / 16.0)) - pad)
		var tx1: int = mini(gw, int(ceil((rx + rw) / 16.0)) + pad)
		var ty0: int = maxi(0, int(floor(ry / 16.0)) - pad)
		var ty1: int = mini(gh, int(ceil((ry + rh) / 16.0)) + pad)
		for py in range(ty0, ty1):
			for px in range(tx0, tx1):
				protected[py][px] = true

	# Bảo vệ các công trình, ruộng đồng, 4 khu chuồng trại & đường đá, khu chợ, ao hồ, hầm mỏ và đường đi
	protect_rect.call(farm_rect.position.x, farm_rect.position.y, farm_rect.size.x, farm_rect.size.y, 2)
	protect_rect.call(641.0 - 72.0, 248.0 - 144.0, 160.0, 160.0, 2) # Nhà gỗ & hiên
	protect_rect.call(240.0, 520.0, 540.0, 360.0, 2) # 4 khu chuồng gia cầm, gia súc & lối đi lát đá
	protect_rect.call(1344.0, 352.0, 464.0, 96.0, 2) # Khu chợ quê
	protect_rect.call(584.0 - 56.0, 440.0 - 66.0, 112.0, 66.0, 1) # Sạp hàng nông sản (nền cỏ xanh thanh sạch)
	protect_rect.call(32.0, 140.0, 128.0, 60.0, 1) # Khu vách núi cửa hầm mỏ đá Tây Bắc
	protect_rect.call(pond.position.x, pond.position.y, pond.size.x, pond.size.y, 3) # Hồ nước
	for p in paths:
		protect_rect.call(p.position.x, p.position.y, p.size.x, p.size.y, 2)

	# 2. Vùng cỏ xanh đậm tự nhiên (Dark green grass clusters)
	var dark_atlas := _load_picture("res://picture/sdv_dark_grass_tiles.png")
	var dark_grid: Array = []
	for y in gh:
		var row: Array = []
		row.resize(gw)
		row.fill(false)
		dark_grid.append(row)

	var dark_clusters: Array[Vector4i] = [
		Vector4i(8, 8, 7, 5), Vector4i(22, 6, 8, 5), Vector4i(40, 8, 9, 6), Vector4i(52, 7, 8, 5),
		Vector4i(75, 8, 10, 6), Vector4i(88, 12, 6, 6), Vector4i(80, 40, 8, 6), Vector4i(88, 52, 6, 6),
		Vector4i(70, 55, 9, 6), Vector4i(38, 52, 10, 6), Vector4i(50, 54, 9, 5), Vector4i(8, 48, 7, 6),
	]
	for cl in dark_clusters:
		var cx: int = cl.x
		var cy: int = cl.y
		var rx: int = cl.z
		var ry: int = cl.w
		for gy in range(maxi(0, cy - ry), mini(gh, cy + ry + 1)):
			for gx in range(maxi(0, cx - rx), mini(gw, cx + rx + 1)):
				if protected[gy][gx]:
					continue
				var dx := float(gx - cx) / float(rx)
				var dy := float(gy - cy) / float(ry)
				var noise := (sin(gx * 1.7 + gy * 2.3) + cos(gx * 0.9 - gy * 1.5)) * 0.15
				if dx * dx + dy * dy + noise <= 1.0:
					dark_grid[gy][gx] = true

	# 3. Các khoảng đất trống ngẫu nhiên (Bare ground clearings / dirt patches)
	var dirt_atlas := _load_picture("res://picture/sdv_dirt_patch_tiles.png")
	var dirt_grid: Array = []
	for y in gh:
		var row: Array = []
		row.resize(gw)
		row.fill(false)
		dirt_grid.append(row)

	var dirt_patches: Array[Vector4i] = [
		Vector4i(6, 14, 4, 3), Vector4i(30, 8, 5, 3), Vector4i(46, 10, 4, 3), Vector4i(70, 7, 5, 3),
		Vector4i(88, 19, 4, 3), Vector4i(82, 36, 5, 4), Vector4i(86, 46, 4, 3), Vector4i(72, 48, 4, 3),
		Vector4i(34, 55, 5, 3), Vector4i(48, 52, 4, 3), Vector4i(78, 56, 5, 3), Vector4i(6, 42, 4, 3), Vector4i(8, 58, 4, 3),
	]
	for dp in dirt_patches:
		var cx: int = dp.x
		var cy: int = dp.y
		var rx: int = dp.z
		var ry: int = dp.w
		for gy in range(maxi(0, cy - ry), mini(gh, cy + ry + 1)):
			for gx in range(maxi(0, cx - rx), mini(gw, cx + rx + 1)):
				if protected[gy][gx]:
					continue
				var dx := float(gx - cx) / float(rx)
				var dy := float(gy - cy) / float(ry)
				var noise := (sin(gx * 2.1 - gy * 1.8) + cos(gx * 1.3 + gy * 2.5)) * 0.18
				if dx * dx + dy * dy + noise <= 0.85:
					dirt_grid[gy][gx] = true
					dark_grid[gy][gx] = false

	# Làm mịn các vạt đất (smoothing pass: loại bỏ ô đơn độc)
	for gy in range(1, gh - 1):
		for gx in range(1, gw - 1):
			if dirt_grid[gy][gx]:
				var cnt: int = 0
				if dirt_grid[gy - 1][gx]: cnt += 1
				if dirt_grid[gy + 1][gx]: cnt += 1
				if dirt_grid[gy][gx - 1]: cnt += 1
				if dirt_grid[gy][gx + 1]: cnt += 1
				if cnt < 2:
					dirt_grid[gy][gx] = false

	# 4. Đất nông trại (Farm field) - phủ trọn vẹn toàn bộ khu đất trong hàng rào (x: 800..1296, y: 368..688)
	var fgx0: int = 50
	var fgx1: int = 81
	var fgy0: int = 23
	var fgy1: int = 43

	var farm_grid: Array = []
	for y in gh:
		var row: Array = []
		row.resize(gw)
		row.fill(false)
		farm_grid.append(row)

	for gy in range(fgy0, fgy1):
		for gx in range(fgx0, fgx1):
			if gy < gh and gx < gw:
				farm_grid[gy][gx] = true
				dark_grid[gy][gx] = false

	# 4 Khu chuồng nuôi riêng biệt (Bò, Gà, Cừu, Lợn) - toàn bộ dùng đất không cỏ chuẩn Stardew Valley
	# Không bị tràn ra ngoài hàng rào (mỗi chuồng 14x8 ô = 224x128px)
	var pen_grid: Array = []
	for y in gh:
		var row: Array = []
		row.resize(gw)
		row.fill(false)
		pen_grid.append(row)

	var pens_bounds := [
		Rect2i(16, 34, 14, 8), # Chuồng Bò (Tây Bắc: x=256..480, y=544..672)
		Rect2i(33, 34, 14, 8), # Chuồng Gà (Đông Bắc: x=528..752, y=544..672)
		Rect2i(16, 45, 14, 8), # Chuồng Cừu (Tây Nam: x=256..480, y=720..848)
		Rect2i(33, 45, 14, 8), # Chuồng Lợn (Đông Nam: x=528..752, y=720..848)
	]

	for pb in pens_bounds:
		for gy in range(pb.position.y, pb.end.y):
			for gx in range(pb.position.x, pb.end.x):
				if gy < gh and gx < gw:
					pen_grid[gy][gx] = true
					dark_grid[gy][gx] = false

	# 5. Lát autotile cho cỏ đậm, các vạt đất trống, đất nông trại và 4 khu chuồng nuôi
	if dark_atlas != null:
		_autotile_terrain(img, dark_atlas, dark_grid, gw, gh, false, rng, fgx0, fgx1)
	if dirt_atlas != null:
		_autotile_terrain(img, dirt_atlas, dirt_grid, gw, gh, true, rng, fgx0, fgx1)
		_autotile_terrain(img, dirt_atlas, farm_grid, gw, gh, true, rng, fgx0, fgx1)
		_autotile_terrain(img, dirt_atlas, pen_grid, gw, gh, true, rng, fgx0, fgx1)

	# 6. Rải hoa dại tự nhiên (wildflowers) trên thảm cỏ
	if dark_atlas != null:
		var fl_p_rect := Rect2i(5 * 16, 1 * 16, 16, 16)
		var fl_b_rect := Rect2i(6 * 16, 1 * 16, 16, 16)
		for gy in range(gh):
			for gx in range(gw):
				if not protected[gy][gx] and not dirt_grid[gy][gx] and not farm_grid[gy][gx] and not pen_grid[gy][gx]:
					var r := rng.randf()
					if r < 0.035:
						var src_rect := fl_p_rect if rng.randf() < 0.5 else fl_b_rect
						img.blend_rect(dark_atlas, src_rect, Vector2i(gx * 16, gy * 16))

	# ---------------- Hệ thống đường đi đất Stardew Valley chuẩn autotile ----------------
	var sdv_roads := _load_picture("res://picture/sdv_road_tiles.png")
	if sdv_roads != null:
		var road_grid: Array = []
		for y in gh:
			var row: Array = []
			row.resize(gw)
			row.fill(false)
			road_grid.append(row)

		for p in paths:
			var tx0: int = maxi(0, int(floor(p.position.x / 16.0)))
			var tx1: int = mini(gw, int(ceil(p.end.x / 16.0)))
			var ty0: int = maxi(0, int(floor(p.position.y / 16.0)))
			var ty1: int = mini(gh, int(ceil(p.end.y / 16.0)))
			for ty in range(ty0, ty1):
				for tx in range(tx0, tx1):
					# Không đặt đường đất đè lên lòng ruộng đất trồng
					if tx >= (fgx0 + 1) and tx < (fgx1 - 1) and ty >= (fgy0 + 1) and ty < (fgy1 - 1):
						continue
					road_grid[ty][tx] = true

		var top_edges: Array[Vector2i] = [
			Vector2i(16, 0), Vector2i(16, 0), Vector2i(32, 0),
			Vector2i(16, 0), Vector2i(48, 0), Vector2i(32, 0)
		]
		var dirt_details: Array[Vector2i] = [
			Vector2i(0, 48), Vector2i(16, 48), Vector2i(16, 48), Vector2i(0, 48),
			Vector2i(32, 48), Vector2i(48, 48), Vector2i(64, 48), Vector2i(80, 48),
			Vector2i(0, 48), Vector2i(16, 48)
		]

		for gy in range(gh):
			for gx in range(gw):
				if not road_grid[gy][gx]:
					continue
				var n: bool = road_grid[gy - 1][gx] if gy > 0 else false
				var s: bool = road_grid[gy + 1][gx] if gy < gh - 1 else false
				var w_val: bool = road_grid[gy][gx - 1] if gx > 0 else false
				var e: bool = road_grid[gy][gx + 1] if gx < gw - 1 else false

				# Nối thông ra mép trái bản đồ, cổng ruộng và cổng chuồng không bị cỏ chắn
				if gx == 0 and (gy >= 28 and gy <= 30):
					w_val = true
				elif gx == (fgx0 - 1) and (gy >= 28 and gy <= 31):
					e = true
				elif gx == fgx1 and (gy >= 28 and gy <= 31):
					w_val = true
				elif (gx in [30, 31, 32]) and gy == 30:
					s = true # Nối thông đại lộ với đường đá dọc dẫn xuống 4 chuồng

				var nw: bool = road_grid[gy - 1][gx - 1] if gy > 0 and gx > 0 else false
				var ne: bool = road_grid[gy - 1][gx + 1] if gy > 0 and gx < gw - 1 else false
				var sw: bool = road_grid[gy + 1][gx - 1] if gy < gh - 1 and gx > 0 else false
				var se: bool = road_grid[gy + 1][gx + 1] if gy < gh - 1 and gx < gw - 1 else false

				var src_pos := Vector2i(0, 48)

				# Góc lồi bo tròn ngoài (Outer convex corners)
				if not n and not w_val and s and e:
					src_pos = Vector2i(0, 0)    # CONVEX_TL (201)
				elif not n and not e and s and w_val:
					src_pos = Vector2i(64, 0)   # CONVEX_TR (204)
				elif not s and not w_val and n and e:
					src_pos = Vector2i(0, 32)   # CONVEX_BL (251)
				elif not s and not e and n and w_val:
					src_pos = Vector2i(64, 32)  # CONVEX_BR (254)
				# Mép thẳng (Straight edges)
				elif not n and s:
					src_pos = top_edges[rng.randi_range(0, top_edges.size() - 1)]
				elif not s and n:
					src_pos = Vector2i(16, 32)  # BOT_EDGE (252)
				elif not w_val and e:
					src_pos = Vector2i(0, 16)   # LEFT_EDGE (226)
				elif not e and w_val:
					src_pos = Vector2i(16, 16)  # RIGHT_EDGE (229)
				# Lòng đường & góc lõm nối ngã ba / ngã tư (Inner Concave Corners)
				else:
					if not nw and ne and sw and se:
						src_pos = Vector2i(32, 16) # CONCAVE_TL (203)
					elif not ne and nw and sw and se:
						src_pos = Vector2i(80, 0)  # CONCAVE_TR (178)
					elif not sw and nw and ne and se:
						src_pos = Vector2i(48, 16) # CONCAVE_BL (253)
					elif not se and nw and ne and sw:
						src_pos = Vector2i(64, 16) # CONCAVE_BR (179)
					else:
						src_pos = dirt_details[rng.randi_range(0, dirt_details.size() - 1)]

				img.blit_rect(sdv_roads, Rect2i(src_pos, Vector2i(16, 16)), Vector2i(gx * 16, gy * 16))

	# ---------------- Lối đi lát đá (Cobblestone paths) giữa các chuồng ----------------
	var cobble_tex := _load_picture("res://picture/sdv_cobblestone_path.png")
	var active_cobble_paths := cobble_paths
	if active_cobble_paths.is_empty():
		active_cobble_paths = [
			Rect2(480, 480, 48, 384), # đường dọc giữa các chuồng nối từ đại lộ xuống
			Rect2(240, 672, 528, 48), # đường ngang giữa hàng chuồng trên và dưới
		]

	for cp in active_cobble_paths:
		var cx0: int = maxi(0, int(floor(cp.position.x / 16.0)))
		var cx1: int = mini(gw, int(ceil(cp.end.x / 16.0)))
		var cy0: int = maxi(0, int(floor(cp.position.y / 16.0)))
		var cy1: int = mini(gh, int(ceil(cp.end.y / 16.0)))
		for ty in range(cy0, cy1):
			for tx in range(cx0, cx1):
				if cobble_tex != null:
					var tile_x := (rng.randi() % 4) * 16
					var tile_y := (rng.randi() % 4) * 16
					img.blend_rect(cobble_tex, Rect2i(tile_x, tile_y, 16, 16), Vector2i(tx * 16, ty * 16))

	# Ao cá tròn Stardew Valley chuẩn asset nguyên bản
	var pond_img := _load_picture("res://picture/sdv_pond_stardew.png")
	if pond_img != null:
		var px_pos := Vector2i(int(pond.position.x), int(pond.position.y))
		img.blend_rect(pond_img, Rect2i(Vector2i.ZERO, pond_img.get_size()), px_pos)

	var tex := _tex(img)
	_cache[key] = tex
	return tex


# ---------- đất canh tác ----------

# Nền ruộng đất không cỏ (chuẩn đất nông trại Stardew Valley)
static func _field() -> ImageTexture:
	var sdv_dirt := _load_picture("res://picture/sdv_dirt.png")
	if sdv_dirt != null:
		var img := _img(32, 32)
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		for ty in range(0, 32, 16):
			for tx in range(0, 32, 16):
				var r := rng.randf()
				var d_idx: int = 0
				if r < 0.55:
					d_idx = 0
				elif r < 0.78:
					d_idx = 1
				elif r < 0.9:
					d_idx = 2
				else:
					d_idx = 3
				img.blit_rect(sdv_dirt, Rect2i(d_idx * 16, 0, 16, 16), Vector2i(tx, ty))
		return _tex(img)
	var img := _img(32, 32)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var base := Color(0.85, 0.60, 0.22)
	img.fill(base)
	for i in 60:
		var x := rng.randi_range(0, 31)
		var y := rng.randi_range(0, 31)
		if rng.randf() < 0.5:
			px(img, x, y, base.darkened(0.12))
		else:
			px(img, x, y, base.lightened(0.09))
	return _tex(img)


static func _tilled_variant(type: String, wet: bool, dark: bool = false) -> ImageTexture:
	var prefix := "hoe_dirt_dark" if dark else ("hoe_dirt_wet" if wet else "hoe_dirt")
	var loaded := _load_picture("res://picture/%s_%s.png" % [prefix, type])
	if loaded != null:
		return _tex(loaded)
	return _tilled(wet, dark)


static func _tilled(wet: bool, dark: bool = false) -> ImageTexture:
	var img := _img(32, 32)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 if (wet or dark) else 13
	var base := Color(0.24, 0.16, 0.08) if dark else (Color(0.40, 0.26, 0.15) if wet else Color(0.55, 0.36, 0.20))
	var furrow := Color(0.18, 0.11, 0.05) if dark else (Color(0.31, 0.20, 0.11) if wet else Color(0.44, 0.28, 0.15))
	var ridge := Color(0.30, 0.20, 0.10) if dark else (Color(0.47, 0.31, 0.18) if wet else Color(0.63, 0.43, 0.26))
	img.fill(base)
	for y in range(2, 32, 5):
		for x in 32:
			px(img, x, y, furrow)
			px(img, x, y + 1, ridge)
	for i in 26:
		px(img, rng.randi_range(1, 30), rng.randi_range(1, 30), furrow)
	# viền ô cho dễ nhìn
	var edge := Color(0.20, 0.13, 0.06) if dark else (Color(0.35, 0.23, 0.12) if wet else Color(0.48, 0.31, 0.17))
	for x in 32:
		px(img, x, 0, edge)
		px(img, x, 31, edge)
	for y in 32:
		px(img, 0, y, edge)
		px(img, 31, y, edge)
	return _tex(img)


# ---------- hiệu ứng hành động ----------

# Khung cổng gỗ 64px: Cổng ngõ làng quê với 2 cột trụ vững chãi, đòn dông gỗ và mái che rơm/gỗ
static func _gate() -> ImageTexture:
	var loaded := _load_picture("res://picture/gate_coop.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(64, 30)
	var wood := Color(0.58, 0.40, 0.22)
	var dark := Color(0.38, 0.24, 0.12)
	var light := Color(0.74, 0.54, 0.32)
	var straw := Color(0.86, 0.70, 0.34)
	var straw_d := Color(0.66, 0.50, 0.22)

	# Bóng chân trụ
	ellipse(img, 6, 28, 6, 2, Color(0.12, 0.18, 0.10, 0.4))
	ellipse(img, 57, 28, 6, 2, Color(0.12, 0.18, 0.10, 0.4))

	# Hai cột trụ cổng gỗ to hai bên
	rect(img, 2, 4, 9, 25, wood)
	rect(img, 2, 4, 2, 25, light)
	rect(img, 9, 4, 2, 25, dark)
	rect(img, 53, 4, 9, 25, wood)
	rect(img, 53, 4, 2, 25, light)
	rect(img, 60, 4, 2, 25, dark)

	# Chân đế trụ đá
	rect(img, 1, 26, 11, 4, Color(0.55, 0.55, 0.58))
	rect(img, 52, 26, 11, 4, Color(0.55, 0.55, 0.58))

	# Đòn ngang vòm cổng
	rect(img, 0, 4, 64, 6, wood)
	rect(img, 0, 4, 64, 1, light)
	rect(img, 0, 9, 64, 1, dark)

	# Mái tranh nhỏ che cổng
	for r in 4:
		var w := 64 - r * 4
		var left := r * 2
		rect(img, left, 3 - r, w, 1, straw if r < 2 else straw_d)

	# Chốt giằng góc xéo
	px(img, 11, 10, dark)
	px(img, 12, 11, dark)
	px(img, 52, 10, dark)
	px(img, 51, 11, dark)

	# Biển cổng chào đón màu đỏ vàng
	rect(img, 26, 6, 12, 3, Color(0.85, 0.25, 0.20))
	px(img, 28, 7, Color(1, 0.9, 0.4))
	px(img, 35, 7, Color(1, 0.9, 0.4))

	return _tex(img)


# Khung cổng DỌC 32x64: Cổng rào đồng quê vào ruộng, hai trụ gỗ đá lim, cánh cửa chữ X mở rộng
static func _gate_v() -> ImageTexture:
	var loaded := _load_picture("res://picture/gate_v.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(32, 64)
	var wood_d := Color(0.38, 0.24, 0.12)
	var wood_m := Color(0.56, 0.38, 0.22)
	var wood_l := Color(0.74, 0.54, 0.32)
	var tile_red := Color(0.75, 0.30, 0.20)
	var tile_d := Color(0.55, 0.20, 0.12)
	var stone_m := Color(0.52, 0.54, 0.56)
	var stone_l := Color(0.70, 0.72, 0.75)
	var stone_d := Color(0.35, 0.36, 0.38)
	var iron := Color(0.24, 0.22, 0.22)
	var gold := Color(1.0, 0.88, 0.45)
	var leaf := Color(0.32, 0.62, 0.25)
	var leaf_d := Color(0.20, 0.44, 0.18)

	# 1. Chân đế trụ đá (đá xanh vững chãi)
	# Đế trên: y=13..16
	rect(img, 4, 13, 14, 4, stone_m)
	rect(img, 4, 13, 14, 1, stone_l)
	rect(img, 4, 16, 14, 1, stone_d)
	# Đế dưới: y=48..51
	rect(img, 4, 48, 14, 4, stone_m)
	rect(img, 4, 48, 14, 1, stone_l)
	rect(img, 4, 51, 14, 1, stone_d)

	# 2. Trụ gỗ lim chính (trên: y=0..13, dưới: y=51..64)
	# Trụ trên
	rect(img, 6, 2, 10, 11, wood_m)
	rect(img, 6, 2, 2, 11, wood_l)
	rect(img, 14, 2, 2, 11, wood_d)
	# Mái ngói nhỏ che mưa trên đỉnh trụ
	rect(img, 4, 0, 14, 3, tile_red)
	rect(img, 5, 0, 12, 1, Color(0.9, 0.45, 0.35))
	rect(img, 4, 2, 14, 1, tile_d)
	# Bản lề sắt đúc
	rect(img, 5, 6, 12, 2, iron)
	px(img, 8, 7, Color(0.8, 0.8, 0.85))

	# Trụ dưới
	rect(img, 6, 51, 10, 11, wood_m)
	rect(img, 6, 51, 2, 11, wood_l)
	rect(img, 14, 51, 2, 11, wood_d)
	# Chóp gỗ trụ dưới
	rect(img, 5, 61, 12, 3, stone_d)
	# Bản lề sắt đúc
	rect(img, 5, 56, 12, 2, iron)
	px(img, 8, 57, Color(0.8, 0.8, 0.85))

	# 3. Cánh cửa rào gỗ mở nép vào hai bên thành cổng (Upper wing: y=6..20, Lower wing: y=44..58)
	# Cánh cổng trên mở áp dọc
	rect(img, 16, 6, 12, 14, wood_m)
	rect(img, 16, 6, 12, 1, wood_l)
	rect(img, 16, 19, 12, 1, wood_d)
	rect(img, 16, 6, 1, 14, wood_l)
	rect(img, 27, 6, 1, 14, wood_d)
	# Nan giằng chéo chữ X cánh trên
	for i in 10:
		px(img, 17 + i, 8 + i, wood_d)
		px(img, 26 - i, 8 + i, wood_d)
	# Then cài cổng trên
	rect(img, 24, 12, 3, 2, iron)

	# Cánh cổng dưới mở áp dọc
	rect(img, 16, 44, 12, 14, wood_m)
	rect(img, 16, 44, 12, 1, wood_l)
	rect(img, 16, 57, 12, 1, wood_d)
	rect(img, 16, 44, 1, 14, wood_l)
	rect(img, 27, 44, 1, 14, wood_d)
	# Nan giằng chéo chữ X cánh dưới
	for i in 10:
		px(img, 17 + i, 46 + i, wood_d)
		px(img, 26 - i, 46 + i, wood_d)
	# Then cài cổng dưới
	rect(img, 24, 50, 3, 2, iron)

	# 4. Đèn lồng nông trại ấm áp treo trên cột trụ trên
	rect(img, 18, 5, 6, 1, iron) # cần treo
	rect(img, 20, 6, 2, 2, iron) # móc xích
	rect(img, 19, 8, 4, 5, iron) # khung đèn
	rect(img, 20, 9, 2, 3, gold) # ánh sáng đèn vàng
	px(img, 20, 10, Color(1, 1, 0.8)) # lõi sáng trắng

	# 5. Dây leo hoa lá mọc quấn quanh cột cổng
	px(img, 5, 8, leaf)
	px(img, 4, 9, leaf)
	px(img, 6, 10, leaf_d)
	px(img, 5, 11, leaf)
	px(img, 15, 7, leaf)
	px(img, 16, 8, leaf_d)
	px(img, 4, 53, leaf)
	px(img, 5, 54, leaf_d)
	px(img, 6, 55, leaf)

	return _tex(img)


# Cổng chuồng gia cầm 48x28: Cổng gỗ mộc mạc hai cánh mở vào trong sân, có chốt cài, xà ngang biểu tượng gà
static func _coop_gate() -> ImageTexture:
	var loaded := _load_picture("res://picture/gate_coop.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(48, 28)
	var wood_d := Color(0.38, 0.24, 0.12)
	var wood_m := Color(0.56, 0.38, 0.22)
	var wood_l := Color(0.74, 0.54, 0.32)
	var iron := Color(0.24, 0.22, 0.22)
	var gold := Color(0.96, 0.82, 0.28)
	var red := Color(0.85, 0.25, 0.20)
	var stone := Color(0.56, 0.54, 0.50)
	var shadow := Color(0.12, 0.18, 0.10, 0.4)

	# Bóng chân cổng
	ellipse(img, 6, 26, 6, 2, shadow)
	ellipse(img, 41, 26, 6, 2, shadow)

	# 1. Hai cột trụ gỗ vững chãi (trái x=3..8, phải x=39..44, y=2..27)
	# Cột trái
	rect(img, 3, 3, 6, 24, wood_m)
	rect(img, 3, 3, 1, 24, wood_l)
	rect(img, 8, 3, 1, 24, wood_d)
	# Cọc nhọn chóp nón
	px(img, 5, 1, wood_l)
	px(img, 6, 1, wood_l)
	px(img, 4, 2, wood_l)
	px(img, 7, 2, wood_d)
	# Đai sắt gia cố cọc
	rect(img, 2, 7, 8, 2, iron)
	rect(img, 2, 18, 8, 2, iron)
	px(img, 4, 8, Color(0.8, 0.8, 0.85))
	px(img, 4, 19, Color(0.8, 0.8, 0.85))

	# Cột phải
	rect(img, 39, 3, 6, 24, wood_m)
	rect(img, 39, 3, 1, 24, wood_l)
	rect(img, 44, 3, 1, 24, wood_d)
	# Cọc nhọn chóp nón
	px(img, 41, 1, wood_l)
	px(img, 42, 1, wood_l)
	px(img, 40, 2, wood_l)
	px(img, 43, 2, wood_d)
	# Đai sắt gia cố cọc
	rect(img, 38, 7, 8, 2, iron)
	rect(img, 38, 18, 8, 2, iron)
	px(img, 42, 8, Color(0.8, 0.8, 0.85))
	px(img, 42, 19, Color(0.8, 0.8, 0.85))

	# 2. Xà ngang cổng vòm gỗ bên trên (y=3..7)
	rect(img, 2, 3, 44, 4, wood_m)
	rect(img, 2, 3, 44, 1, wood_l)
	rect(img, 2, 6, 44, 1, wood_d)

	# Biển hiệu / Phù điêu gà trống chạm khắc trên xà cổng
	rect(img, 18, 1, 12, 6, wood_d)
	rect(img, 19, 2, 10, 4, wood_l)
	# Hình chú gà vàng mini trên biển
	px(img, 23, 2, red)   # mào đỏ
	px(img, 23, 3, gold)  # đầu
	px(img, 24, 3, red)   # mỏ
	rect(img, 22, 4, 3, 2, gold) # mình gà
	px(img, 21, 3, Color(0.3, 0.5, 0.3)) # đuôi xanh

	# Chuông đồng / chuông gió nhỏ treo dưới xà
	px(img, 24, 7, iron)
	px(img, 24, 8, gold)
	rect(img, 23, 9, 3, 2, gold)

	# 3. Hai cánh cửa rào gỗ hé mở sang hai bên vào trong sân chuồng
	# Cánh trái mở hé (x=9..18, y=9..25)
	rect(img, 9, 9, 9, 2, wood_m)
	rect(img, 9, 22, 9, 2, wood_m)
	# Các nan dọc
	for nx in [9, 12, 15, 17]:
		rect(img, nx, 8, 2, 17, wood_m)
		px(img, nx, 8, wood_l)
		px(img, nx + 1, 8, wood_d)
	# Thanh chéo chữ X gia cố cánh cửa trái
	for i in 8:
		px(img, 9 + i, 11 + i, wood_d)
		px(img, 17 - i, 11 + i, wood_d)
	# Bản lề sắt
	rect(img, 7, 10, 3, 2, iron)
	rect(img, 7, 21, 3, 2, iron)

	# Cánh phải mở hé (x=30..39, y=9..25)
	rect(img, 30, 9, 9, 2, wood_m)
	rect(img, 30, 22, 9, 2, wood_m)
	# Các nan dọc
	for nx in [30, 33, 36, 38]:
		rect(img, nx, 8, 2, 17, wood_m)
		px(img, nx, 8, wood_l)
		px(img, nx + 1, 8, wood_d)
	# Thanh chéo chữ X gia cố cánh cửa phải
	for i in 8:
		px(img, 30 + i, 11 + i, wood_d)
		px(img, 38 - i, 11 + i, wood_d)
	# Bản lề sắt
	rect(img, 38, 10, 3, 2, iron)
	rect(img, 38, 21, 3, 2, iron)

	# 4. Bậc ngưỡng cửa đá sỏi tự nhiên dưới lối đi (x=18..30, y=25..27)
	for sx in range(18, 30, 3):
		rect(img, sx, 25, 2, 2, stone)
		px(img, sx, 25, Color(0.7, 0.68, 0.65))

	return _tex(img)


static func _fx_till() -> ImageTexture:
	var img := _img(16, 16)
	var dirt := Color(0.5, 0.34, 0.19)
	rect(img, 3, 8, 4, 3, dirt)
	rect(img, 9, 11, 4, 3, dirt)
	rect(img, 6, 4, 3, 3, dirt.darkened(0.15))
	px(img, 12, 6, dirt)
	px(img, 2, 13, dirt)
	return _tex(img)


static func _fx_plant() -> ImageTexture:
	var img := _img(16, 16)
	var green := Color(0.35, 0.7, 0.3)
	rect(img, 7, 6, 2, 6, Color(0.3, 0.55, 0.25))
	px(img, 5, 5, green)
	px(img, 4, 6, green)
	px(img, 10, 5, green)
	px(img, 11, 6, green)
	px(img, 8, 4, green.lightened(0.2))
	px(img, 3, 12, Color(0.8, 0.66, 0.4))
	px(img, 12, 13, Color(0.8, 0.66, 0.4))
	return _tex(img)


static func _fx_water() -> ImageTexture:
	var img := _img(16, 16)
	var drop := Color(0.45, 0.72, 0.95)
	circle(img, 4, 5, 1.6, drop)
	circle(img, 10, 8, 1.8, drop)
	circle(img, 7, 12, 1.5, drop)
	px(img, 4, 3, Color(0.8, 0.92, 1))
	px(img, 10, 6, Color(0.8, 0.92, 1))
	return _tex(img)


static func _fx_harvest() -> ImageTexture:
	var img := _img(16, 16)
	var gold := Color(1.0, 0.85, 0.3)
	rect(img, 7, 2, 2, 12, gold)
	rect(img, 2, 7, 12, 2, gold)
	px(img, 4, 4, gold)
	px(img, 11, 4, gold)
	px(img, 4, 11, gold)
	px(img, 11, 11, gold)
	circle(img, 8, 8, 1.8, Color(1, 1, 1))
	return _tex(img)


static func _fx_rod() -> ImageTexture:
	var img := _img(16, 16)
	var wood := Color(0.5, 0.35, 0.2)
	for i in 9:
		px(img, 3 + i, 14 - i, wood)
		px(img, 4 + i, 14 - i, wood.darkened(0.2))
	px(img, 12, 5, Color(0.85, 0.85, 0.85))
	px(img, 12, 6, Color(0.85, 0.85, 0.85))
	px(img, 12, 7, Color(0.85, 0.85, 0.85))
	px(img, 12, 8, Color(0.85, 0.85, 0.85))
	px(img, 11, 9, Color(0.9, 0.9, 0.9))
	return _tex(img)


static func _fx_bobber() -> ImageTexture:
	var img := _img(16, 16)
	circle(img, 8, 6, 2.5, Color(0.85, 0.25, 0.2))
	circle(img, 8, 9, 2.5, Color(0.95, 0.95, 0.95))
	px(img, 8, 3, Color(0.6, 0.6, 0.6))
	return _tex(img)


static func _highlight() -> ImageTexture:
	var img := _img(34, 34)
	var white := Color(1, 1, 1, 0.92)
	var fillc := Color(1, 1, 1, 0.10)
	rect(img, 0, 0, 34, 34, fillc)
	for x in 34:
		px(img, x, 0, white)
		px(img, x, 1, white)
		px(img, x, 32, white)
		px(img, x, 33, white)
	for y in 34:
		px(img, 0, y, white)
		px(img, 1, y, white)
		px(img, 32, y, white)
		px(img, 33, y, white)
	return _tex(img)


# ---------- cảnh vật ----------

static func _tree_variant(var_name: String) -> ImageTexture:
	var loaded := _load_picture("res://picture/%s.png" % var_name)
	if loaded != null:
		return _tex(loaded)
	return _tree()


static func _tree() -> ImageTexture:
	var loaded := _load_picture("res://picture/tree_oak.png")
	if loaded == null:
		loaded = _load_picture("res://picture/tree.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(32, 48)
	rect(img, 14, 32, 5, 14, Color(0.45, 0.30, 0.18))
	px(img, 15, 34, Color(0.55, 0.38, 0.23))
	circle(img, 16, 20, 11, Color(0.20, 0.48, 0.23))
	circle(img, 11, 16, 7, Color(0.26, 0.56, 0.27))
	circle(img, 22, 16, 7, Color(0.26, 0.56, 0.27))
	circle(img, 16, 13, 6, Color(0.32, 0.62, 0.30))
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 26:
		px(img, rng.randi_range(5, 26), rng.randi_range(6, 26), Color(0.18, 0.42, 0.20))
	return _tex(img)


static func _house() -> ImageTexture:
	var loaded := _load_picture("res://picture/house.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(96, 80)
	# mái ngói
	for row in 28:
		var t := float(row) / 27.0
		var half := int(lerpf(10.0, 46.0, t))
		rect(img, 48 - half, row, half * 2, 1, Color(0.70, 0.30, 0.22))
		if row % 5 == 0:
			rect(img, 48 - half, row, half * 2, 1, Color(0.60, 0.24, 0.18))
	rect(img, 36, 0, 24, 3, Color(0.55, 0.22, 0.16))
	# tường
	rect(img, 8, 28, 80, 48, Color(0.93, 0.87, 0.71))
	rect(img, 8, 28, 80, 3, Color(0.80, 0.72, 0.55))
	rect(img, 8, 73, 80, 3, Color(0.70, 0.63, 0.48))
	# cửa
	rect(img, 40, 50, 16, 26, Color(0.46, 0.31, 0.18))
	rect(img, 42, 52, 12, 24, Color(0.55, 0.38, 0.22))
	px(img, 52, 63, Color(0.95, 0.85, 0.4))
	# cửa sổ
	for wx in [16, 66]:
		rect(img, wx, 38, 14, 13, Color(0.50, 0.68, 0.80))
		rect(img, wx + 6, 38, 2, 13, Color(0.93, 0.87, 0.71))
		rect(img, wx, 44, 14, 2, Color(0.93, 0.87, 0.71))
		rect(img, wx - 1, 37, 16, 1, Color(0.55, 0.42, 0.28))
		rect(img, wx - 1, 51, 16, 1, Color(0.55, 0.42, 0.28))
	return _tex(img)


static func _shed() -> ImageTexture:
	var loaded := _load_picture("res://picture/shed.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(112, 128)
	var wood_d := Color(0.35, 0.22, 0.12)
	var wood_m := Color(0.55, 0.38, 0.22)
	var roof := Color(0.65, 0.25, 0.18)
	rect(img, 10, 10, 92, 40, roof)
	rect(img, 16, 50, 80, 78, wood_m)
	rect(img, 46, 80, 20, 48, wood_d)
	return _tex(img)


static func _tent() -> ImageTexture:
	var loaded := _load_picture("res://picture/tent.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(48, 64)
	rect(img, 8, 16, 32, 44, Color(0.82, 0.72, 0.52))
	return _tex(img)


static func cat_char_tex(anim: String, frame_idx: int = 0) -> Texture2D:
	var path := ""
	match anim:
		"down":
			var idx := absi(frame_idx) % 3
			path = "res://picture/cat/cat_down_%d.png" % idx
		"up":
			var idx := absi(frame_idx) % 3
			path = "res://picture/cat/cat_up_%d.png" % idx
		"side":
			var idx := absi(frame_idx) % 2
			path = "res://picture/cat/cat_side_%d.png" % idx
		"act", "action", "side_act":
			path = "res://picture/cat/cat_side_act.png"
		_:
			path = "res://picture/cat/cat_down_0.png"

	var key := "cat_%s_%d" % [anim, frame_idx]
	if _cache.has(key):
		return _cache[key]
	var img := _load_picture(path)
	if img != null:
		var tex := _tex(img)
		_cache[key] = tex
		return tex
	return null


static func _caterpillar() -> ImageTexture:
	var img := _img(16, 16)
	var green_body := Color(0.48, 0.78, 0.22)
	var green_light := Color(0.70, 0.90, 0.35)
	var green_dark := Color(0.24, 0.48, 0.12)
	var eye_black := Color(0.1, 0.1, 0.1)
	var eye_white := Color(1.0, 1.0, 1.0)
	var ant_color := Color(0.35, 0.60, 0.15)

	# Đốt đuôi (Segment 1)
	circle(img, 3.5, 9.5, 2.4, green_dark)
	circle(img, 3.5, 9.5, 1.7, green_body)
	px(img, 3, 9, green_light)
	# Đốt thân 2
	circle(img, 6.5, 9.0, 2.5, green_dark)
	circle(img, 6.5, 9.0, 1.8, green_body)
	px(img, 6, 8, green_light)
	# Đốt thân 3
	circle(img, 9.5, 8.5, 2.5, green_dark)
	circle(img, 9.5, 8.5, 1.8, green_body)
	px(img, 9, 8, green_light)
	# Đốt đầu
	circle(img, 12.5, 8.0, 2.7, green_dark)
	circle(img, 12.5, 8.0, 2.0, green_body)
	px(img, 12, 7, green_light)
	# Mắt
	px(img, 13, 7, eye_black)
	px(img, 13, 6, eye_white)
	# Râu
	px(img, 13, 5, ant_color)
	px(img, 14, 4, ant_color)
	px(img, 12, 5, ant_color)
	px(img, 11, 4, ant_color)
	# Chân
	px(img, 4, 12, green_dark)
	px(img, 7, 12, green_dark)
	px(img, 10, 12, green_dark)
	return _tex(img)


static func _fx_pest() -> ImageTexture:
	return _caterpillar()


static func _mailbox() -> ImageTexture:
	var loaded := _load_picture("res://picture/mailbox.png")
	if loaded != null:
		return _tex(loaded)
	return null


static func _stand() -> ImageTexture:
	var img := _img(64, 56)
	# mái sọc đỏ trắng
	for x in 64:
		var c := Color(0.82, 0.32, 0.26) if (x / 8) % 2 == 0 else Color(0.95, 0.92, 0.85)
		rect(img, x, 0, 1, 14, c)
	rect(img, 0, 13, 64, 2, Color(0.45, 0.28, 0.16))
	# cột
	rect(img, 3, 14, 4, 38, Color(0.52, 0.36, 0.20))
	rect(img, 57, 14, 4, 38, Color(0.52, 0.36, 0.20))
	# quầy
	rect(img, 6, 36, 52, 16, Color(0.60, 0.42, 0.25))
	rect(img, 6, 36, 52, 3, Color(0.72, 0.52, 0.32))
	rect(img, 6, 50, 52, 2, Color(0.45, 0.30, 0.16))
	# thùng hàng trên quầy
	rect(img, 10, 24, 14, 12, Color(0.75, 0.56, 0.33))
	rect(img, 10, 24, 14, 2, Color(0.62, 0.44, 0.24))
	px(img, 12, 27, Color(0.85, 0.65, 0.4))
	rect(img, 30, 26, 12, 10, Color(0.70, 0.50, 0.28))
	rect(img, 30, 26, 12, 2, Color(0.58, 0.40, 0.20))
	px(img, 33, 29, Color(0.82, 0.62, 0.36))
	return _tex(img)


static func _market_stall() -> ImageTexture:
	var loaded := _load_picture("res://picture/market_stall.png")
	if loaded != null:
		return _tex(loaded)
	return _stand()


static func _stall_shadow() -> ImageTexture:
	var loaded := _load_picture("res://picture/stall_shadow.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(124, 32)
	var shadow := Color(0.05, 0.10, 0.04, 0.42)
	ellipse(img, 60, 16, 44, 9, shadow)
	ellipse(img, 18, 18, 13, 7, shadow)
	ellipse(img, 102, 18, 17, 8, shadow)
	return _tex(img)


static func shadow_tex() -> ImageTexture:
	var img := _img(20, 10)
	var shadow := Color(0.0, 0.0, 0.0, 0.45)
	ellipse(img, 10, 5, 8, 4, shadow)
	return _tex(img)


# Mái ngói cổ truyền che phía trên quầy Bác Tư (80x18)
static func _stand_seed_roof() -> ImageTexture:
	var img := _img(80, 18)
	var tile_r := Color(0.78, 0.32, 0.22)
	var tile_l := Color(0.90, 0.44, 0.32)
	var tile_d := Color(0.56, 0.20, 0.12)

	for row in 11:
		var w := 80 - (10 - row) * 2
		var left := (10 - row)
		rect(img, left, 2 + row, w, 1, tile_r if row % 2 == 0 else tile_d)
		px(img, left, 2 + row, tile_l)
		px(img, left + w - 1, 2 + row, tile_d)
	for x in range(0, 80, 4):
		rect(img, x, 13, 3, 2, tile_r)
		px(img, x + 1, 15, tile_d)
	rect(img, 12, 1, 56, 3, tile_d)
	rect(img, 14, 0, 52, 2, tile_l)
	px(img, 10, 1, tile_l)
	px(img, 9, 0, tile_l)
	px(img, 69, 1, tile_l)
	px(img, 70, 0, tile_l)
	return _tex(img)


# Mái tranh rơm vàng che phía trên quầy Cô Tư (80x18)
static func _stand_poultry_roof() -> ImageTexture:
	var img := _img(80, 18)
	var straw_top := Color(0.94, 0.82, 0.45)
	var straw_mid := Color(0.82, 0.68, 0.34)
	var straw_dark := Color(0.60, 0.44, 0.20)
	var gold := Color(0.98, 0.84, 0.28)
	var red := Color(0.88, 0.25, 0.20)

	for row in 12:
		var w := 80 - (11 - row) * 2
		var left := (11 - row)
		var sc := straw_top if row < 4 else (straw_mid if row < 9 else straw_dark)
		rect(img, left, 2 + row, w, 1, sc)
		px(img, left, 2 + row, straw_top)
		px(img, left + w - 1, 2 + row, straw_dark)
	for x in range(0, 80, 3):
		px(img, x, 14, straw_mid)
		px(img, x + 1, 15, straw_top)
		if x % 2 == 0:
			px(img, x, 16, straw_dark)
	rect(img, 38, 0, 4, 2, straw_dark)
	px(img, 40, 0, red)
	rect(img, 39, 1, 3, 2, gold)
	px(img, 42, 1, red)
	px(img, 38, 1, Color(0.3, 0.6, 0.3))
	return _tex(img)


# Mái bạt xanh chàm che phía trên quầy Chú Hai (80x18)
static func _stand_fish_roof() -> ImageTexture:
	var img := _img(80, 18)
	var blue_top := Color(0.32, 0.55, 0.78)
	var blue_mid := Color(0.20, 0.40, 0.62)
	var blue_dark := Color(0.12, 0.26, 0.44)

	for row in 12:
		var w := 80 - (11 - row) * 2
		var left := (11 - row)
		var bc := blue_top if row < 4 else (blue_mid if row < 9 else blue_dark)
		rect(img, left, 2 + row, w, 1, bc)
	for x in range(0, 80, 8):
		rect(img, x, 14, 7, 2, blue_mid)
		rect(img, x + 1, 16, 5, 1, blue_dark)
	for x in 80:
		if x % 2 == 0:
			px(img, x, 13, Color(0.9, 0.92, 0.95))
	return _tex(img)


# Quầy Bác Tư - Phần mái ngói cổ truyền & giá kệ phía sau (80x42)
static func _stand_seed_back() -> ImageTexture:
	var img := _img(80, 42)
	var wood_d := Color(0.36, 0.22, 0.12)
	var wood_m := Color(0.54, 0.36, 0.20)
	var wood_l := Color(0.72, 0.52, 0.30)
	var tile_r := Color(0.78, 0.32, 0.22)
	var tile_l := Color(0.90, 0.44, 0.32)
	var tile_d := Color(0.56, 0.20, 0.12)
	var board_bg := Color(0.90, 0.82, 0.65)
	var board_tx := Color(0.38, 0.20, 0.10)
	var gold := Color(0.96, 0.84, 0.28)
	var red := Color(0.85, 0.22, 0.18)

	# 1. Cột gỗ chịu lực hai bên và đòn ngang
	rect(img, 4, 12, 6, 30, wood_m)
	rect(img, 4, 12, 1, 30, wood_l)
	rect(img, 9, 12, 1, 30, wood_d)
	rect(img, 70, 12, 6, 30, wood_m)
	rect(img, 70, 12, 1, 30, wood_l)
	rect(img, 75, 12, 1, 30, wood_d)
	rect(img, 4, 12, 72, 4, wood_m)

	# 2. Mái ngói đất nung cổ truyền Việt Nam (y=0..15)
	for row in 10:
		var w := 80 - (9 - row) * 2
		var left := (9 - row)
		rect(img, left, 3 + row, w, 1, tile_r if row % 2 == 0 else tile_d)
		px(img, left, 3 + row, tile_l)
		px(img, left + w - 1, 3 + row, tile_d)
	# Mép ngói mũi hài lượn sóng
	for x in range(0, 80, 4):
		rect(img, x, 13, 3, 2, tile_r)
		px(img, x + 1, 15, tile_d)
	# Đòn dông nóc ngói cong nhẹ hai đầu
	rect(img, 12, 1, 56, 3, tile_d)
	rect(img, 14, 0, 52, 2, tile_l)
	# Đầu đao mái cong nhẹ
	px(img, 10, 1, tile_l)
	px(img, 9, 0, tile_l)
	px(img, 69, 1, tile_l)
	px(img, 70, 0, tile_l)

	# 3. Biển hiệu gỗ: "HẠT GIỐNG - NÔNG SẢN" (x=14..66, y=17..25)
	rect(img, 13, 16, 54, 10, wood_d)
	rect(img, 14, 17, 52, 8, board_bg)
	# Viền vàng thanh lịch
	rect(img, 15, 18, 50, 1, Color(0.80, 0.65, 0.35))
	rect(img, 15, 23, 50, 1, Color(0.80, 0.65, 0.35))
	# Biểu tượng bông lúa vàng 🌾
	rect(img, 18, 19, 2, 4, gold)
	px(img, 17, 19, gold)
	px(img, 20, 20, gold)
	px(img, 18, 23, Color(0.4, 0.6, 0.2))
	# Dòng chữ mô phỏng "HẠT GIỐNG & NÔNG SẢN"
	for bx in [23, 27, 31, 35, 39, 43, 47, 51, 55, 59]:
		rect(img, bx, 20, 3, 3, board_tx)
		px(img, bx + 1, 19, board_tx)

	# 4. Kệ gỗ đựng hũ hạt giống và chùm ớt tỏi phơi khô phía sau
	rect(img, 12, 27, 56, 2, wood_d)
	# Hũ hạt giống nhiều màu trên kệ
	rect(img, 18, 29, 6, 7, Color(0.42, 0.58, 0.35))
	rect(img, 19, 28, 4, 1, Color(0.8, 0.65, 0.4))
	rect(img, 28, 30, 7, 6, Color(0.72, 0.48, 0.28))
	rect(img, 30, 29, 3, 1, Color(0.5, 0.3, 0.15))
	rect(img, 46, 29, 6, 7, Color(0.68, 0.72, 0.75))
	rect(img, 56, 30, 7, 6, Color(0.55, 0.38, 0.24))

	# Chùm tỏi ớt phơi khô treo cột trái & phải
	for i in 4:
		px(img, 11, 28 + i * 2, red)
		px(img, 11, 29 + i * 2, red)
		px(img, 69, 28 + i * 2, Color(0.95, 0.95, 0.9))

	return _tex(img)


# Quầy Bác Tư - Phần quầy gỗ & nông sản bày bán phía trước (80x28)
static func _stand_seed_front() -> ImageTexture:
	var img := _img(80, 28)
	var wood_d := Color(0.36, 0.22, 0.12)
	var wood_m := Color(0.55, 0.36, 0.20)
	var wood_l := Color(0.72, 0.52, 0.30)
	var wood_light := Color(0.85, 0.64, 0.40)
	var sack := Color(0.76, 0.65, 0.44)
	var sack_d := Color(0.60, 0.50, 0.32)
	var rice := Color(0.96, 0.86, 0.32)
	var carrot := Color(0.95, 0.45, 0.12)
	var leaf := Color(0.30, 0.68, 0.25)
	var tomato := Color(0.88, 0.22, 0.16)
	var cabbage := Color(0.42, 0.74, 0.32)
	var brass := Color(0.92, 0.78, 0.25)
	var shadow := Color(0.12, 0.18, 0.10, 0.45)

	ellipse(img, 40, 26, 38, 3, shadow)

	# 1. Thân quầy gỗ vững chãi (y=7..25, x=4..76)
	rect(img, 4, 7, 72, 18, wood_m)
	rect(img, 4, 7, 72, 2, wood_light)
	rect(img, 4, 23, 72, 2, wood_d)
	for x in range(8, 76, 8):
		rect(img, x, 9, 1, 15, wood_d)
		rect(img, x + 1, 9, 1, 15, wood_l)

	# 2. Mặt bàn gỗ dày sáng bóng (y=3..7)
	rect(img, 2, 3, 76, 5, wood_m)
	rect(img, 2, 3, 76, 2, wood_light)
	rect(img, 2, 7, 76, 1, wood_d)

	# 3. Nông sản & vật phẩm trên bàn quầy:
	# Bao thóc vàng đầy ắp bên trái (x=6..18, y=2..22)
	rect(img, 6, 6, 12, 16, sack)
	rect(img, 6, 6, 12, 2, sack_d)
	rect(img, 7, 5, 10, 3, rice)
	px(img, 9, 4, Color(1, 0.95, 0.6))
	px(img, 13, 4, Color(1, 0.95, 0.6))

	# Chiếc cân đĩa đồng cổ kính ở giữa (x=24..36, y=0..10)
	rect(img, 29, 0, 2, 8, brass)
	rect(img, 24, 2, 12, 1, brass)
	rect(img, 28, 7, 4, 2, brass)
	rect(img, 23, 5, 4, 1, brass)
	rect(img, 33, 5, 4, 1, brass)
	px(img, 24, 3, Color(0.4, 0.3, 0.1))
	px(img, 34, 3, Color(0.4, 0.3, 0.1))
	px(img, 25, 4, Color(0.6, 0.5, 0.4))

	# Sọt nan tre đựng cà rốt tươi (x=40..52, y=3..20)
	rect(img, 41, 7, 12, 13, Color(0.72, 0.55, 0.32))
	for sy in range(9, 19, 3):
		rect(img, 41, sy, 12, 1, Color(0.55, 0.40, 0.22))
	rect(img, 43, 4, 2, 4, carrot)
	px(img, 43, 3, leaf)
	rect(img, 47, 3, 2, 5, carrot)
	px(img, 47, 2, leaf)
	rect(img, 50, 5, 2, 4, carrot)
	px(img, 50, 4, leaf)

	# Mẹt rau quả tươi: bắp cải xanh và cà chua chín đỏ (x=56..74, y=4..20)
	ellipse(img, 65, 12, 9, 6, Color(0.68, 0.52, 0.30))
	circle(img, 61, 10, 3.5, cabbage)
	px(img, 60, 9, Color(0.6, 0.9, 0.5))
	circle(img, 68, 9, 2.5, tomato)
	px(img, 68, 7, leaf)
	circle(img, 66, 13, 2.2, tomato)
	px(img, 66, 11, leaf)

	return _tex(img)


# Quầy Cô Tư - Mái rơm tranh & vách liếp tre phía sau (80x42)
static func _stand_poultry_back() -> ImageTexture:
	var img := _img(80, 42)
	var bamboo_m := Color(0.65, 0.58, 0.32)
	var bamboo_l := Color(0.80, 0.72, 0.44)
	var bamboo_d := Color(0.48, 0.40, 0.20)
	var straw_top := Color(0.94, 0.82, 0.45)
	var straw_mid := Color(0.82, 0.68, 0.34)
	var straw_dark := Color(0.60, 0.44, 0.20)
	var gold := Color(0.98, 0.84, 0.28)
	var red := Color(0.88, 0.25, 0.20)

	# 1. Cột tre to hai bên và đòn ngang tre
	for px_col in [4, 70]:
		rect(img, px_col, 12, 6, 30, bamboo_m)
		rect(img, px_col, 12, 1, 30, bamboo_l)
		rect(img, px_col + 5, 12, 1, 30, bamboo_d)
		for gy in [18, 28, 38]:
			rect(img, px_col, gy, 6, 1, bamboo_d)
			rect(img, px_col, gy + 1, 6, 1, bamboo_l)

	# 2. Vách liếp đan tre phía sau (y=16..42, x=10..70)
	for y in range(16, 42, 3):
		for x in range(10, 70, 4):
			var c := bamboo_m if (x / 4 + y / 3) % 2 == 0 else bamboo_d
			rect(img, x, y, 4, 3, c)

	# 3. Mái tranh rơm vàng nhiều tầng (y=0..16)
	for row in 12:
		var w := 80 - (11 - row) * 2
		var left := (11 - row)
		var sc := straw_top if row < 4 else (straw_mid if row < 9 else straw_dark)
		rect(img, left, 2 + row, w, 1, sc)
		px(img, left, 2 + row, straw_top)
		px(img, left + w - 1, 2 + row, straw_dark)
	for x in range(0, 80, 3):
		px(img, x, 14, straw_mid)
		px(img, x + 1, 15, straw_top)
		if x % 2 == 0:
			px(img, x, 16, straw_dark)

	# Chú gà trống gỗ chạm khắc trên đỉnh nóc chuồng
	rect(img, 38, 0, 4, 2, straw_dark)
	px(img, 40, 0, red)
	rect(img, 39, 1, 3, 2, gold)
	px(img, 42, 1, red)
	px(img, 38, 1, Color(0.3, 0.6, 0.3))

	# 4. Biển hiệu mộc: "TRẠI GIỐNG CÔ TƯ" (x=14..66, y=18..26)
	rect(img, 13, 17, 54, 10, bamboo_d)
	rect(img, 14, 18, 52, 8, Color(0.92, 0.84, 0.60))
	rect(img, 15, 19, 50, 1, bamboo_m)
	circle(img, 19, 22, 2.5, gold)
	px(img, 22, 22, Color(0.95, 0.5, 0.1))
	px(img, 19, 21, Color(0.1, 0.1, 0.1))
	for bx in [24, 28, 32, 36, 40, 44, 48, 52, 56, 60]:
		rect(img, bx, 21, 3, 3, Color(0.40, 0.24, 0.10))
		px(img, bx + 1, 20, Color(0.40, 0.24, 0.10))

	return _tex(img)


# Quầy Cô Tư - Bội úp gà, ổ trứng tươi & thức ăn gia cầm phía trước (80x28)
static func _stand_poultry_front() -> ImageTexture:
	var img := _img(80, 28)
	var bamboo_m := Color(0.65, 0.58, 0.32)
	var bamboo_l := Color(0.80, 0.72, 0.44)
	var bamboo_d := Color(0.48, 0.40, 0.20)
	var egg_white := Color(0.98, 0.96, 0.92)
	var egg_tan := Color(0.92, 0.82, 0.70)
	var straw := Color(0.88, 0.74, 0.38)
	var gold := Color(0.98, 0.84, 0.28)
	var shadow := Color(0.12, 0.18, 0.10, 0.45)

	ellipse(img, 40, 26, 38, 3, shadow)

	# 1. Quầy thanh tre ghép (y=7..25, x=4..76)
	rect(img, 4, 7, 72, 18, bamboo_m)
	rect(img, 4, 7, 72, 2, bamboo_l)
	rect(img, 4, 23, 72, 2, bamboo_d)
	for x in range(8, 76, 5):
		rect(img, x, 9, 2, 15, bamboo_l)
		px(img, x + 1, 10, bamboo_d)

	# Mặt bàn tre
	rect(img, 2, 3, 76, 5, bamboo_m)
	rect(img, 2, 3, 76, 2, bamboo_l)
	rect(img, 2, 7, 76, 1, bamboo_d)

	# 2. Bội úp gà tre tròn truyền thống bên trái (x=6..22, y=2..22)
	ellipse(img, 14, 13, 8, 9, bamboo_d)
	ellipse(img, 14, 13, 7, 8, Color(0.25, 0.18, 0.10))
	for i in range(7, 21, 3):
		rect(img, i, 4, 1, 17, bamboo_l)
	rect(img, 7, 10, 14, 1, bamboo_m)
	rect(img, 6, 16, 16, 1, bamboo_m)
	circle(img, 14, 13, 2.5, gold)
	px(img, 13, 12, Color(0.1, 0.1, 0.1))
	px(img, 16, 13, Color(0.95, 0.5, 0.1))

	# 3. Rổ rơm đựng đầy ắp trứng tươi ở giữa (x=28..44, y=4..20)
	ellipse(img, 36, 12, 8, 6, Color(0.55, 0.40, 0.20))
	ellipse(img, 36, 11, 7, 5, straw)
	ellipse(img, 33, 9, 2.5, 3.2, egg_white)
	px(img, 32, 8, Color(1, 1, 1))
	ellipse(img, 38, 9, 2.5, 3.2, egg_tan)
	ellipse(img, 35, 12, 2.5, 3.2, egg_white)
	ellipse(img, 39, 13, 2.2, 3.0, egg_tan)

	# 4. Máng thóc ngô vàng và gáo dừa múc nước (x=48..72, y=5..21)
	rect(img, 50, 7, 14, 10, Color(0.48, 0.32, 0.16))
	rect(img, 51, 8, 12, 8, gold)
	px(img, 53, 9, Color(1, 0.95, 0.5))
	px(img, 58, 9, Color(1, 0.95, 0.5))
	circle(img, 68, 11, 3.5, Color(0.35, 0.22, 0.12))
	px(img, 68, 11, Color(0.5, 0.75, 0.95))
	rect(img, 70, 7, 1, 6, Color(0.5, 0.35, 0.2))

	return _tex(img)


# Quầy Chú Hai - Mái bạt xanh biển & cần câu tre phía sau (80x42)
static func _stand_fish_back() -> ImageTexture:
	var img := _img(80, 42)
	var wood_d := Color(0.32, 0.24, 0.16)
	var wood_m := Color(0.48, 0.38, 0.26)
	var wood_l := Color(0.66, 0.54, 0.38)
	var blue_top := Color(0.32, 0.55, 0.78)
	var blue_mid := Color(0.20, 0.40, 0.62)
	var blue_dark := Color(0.12, 0.26, 0.44)
	var net := Color(0.70, 0.62, 0.46)
	var silver := Color(0.85, 0.90, 0.96)

	# 1. Cột gỗ bờ sông dạn dày sóng gió (x=4, x=70)
	for px_col in [4, 70]:
		rect(img, px_col, 12, 6, 30, wood_m)
		rect(img, px_col, 12, 1, 30, wood_l)
		rect(img, px_col + 5, 12, 1, 30, wood_d)

	for ry in [16, 26]:
		rect(img, 3, ry, 8, 2, Color(0.75, 0.65, 0.45))
		rect(img, 69, ry, 8, 2, Color(0.75, 0.65, 0.45))

	# 2. Mái bạt vải xanh chàm kiểu ngư dân (y=0..16)
	for row in 12:
		var w := 80 - (11 - row) * 2
		var left := (11 - row)
		var bc := blue_top if row < 4 else (blue_mid if row < 9 else blue_dark)
		rect(img, left, 2 + row, w, 1, bc)
	for x in range(0, 80, 8):
		rect(img, x, 14, 7, 2, blue_mid)
		rect(img, x + 1, 16, 5, 1, blue_dark)
	for x in 80:
		if x % 2 == 0:
			px(img, x, 13, Color(0.9, 0.92, 0.95))

	# 3. Biển hiệu gỗ mộc: "NGƯ CỤ CHÚ HAI" (x=14..66, y=18..26)
	rect(img, 13, 17, 54, 10, wood_d)
	rect(img, 14, 18, 52, 8, Color(0.85, 0.80, 0.70))
	rect(img, 15, 19, 50, 1, wood_l)
	ellipse(img, 20, 22, 4, 2, silver)
	px(img, 16, 21, silver)
	px(img, 16, 23, silver)
	px(img, 23, 22, Color(0.2, 0.4, 0.6))
	for bx in [26, 30, 34, 38, 42, 46, 50, 54, 58]:
		rect(img, bx, 21, 3, 3, Color(0.18, 0.28, 0.38))
		px(img, bx + 1, 20, Color(0.18, 0.28, 0.38))

	# 4. Giá treo 3 cần câu tre và lưới chài phao gỗ phía sau
	rect(img, 26, 30, 36, 1, wood_d)
	rect(img, 26, 38, 36, 1, wood_d)
	for ci in 3:
		var start_x := 30 + ci * 8
		for step in 14:
			px(img, start_x + step, 41 - step, Color(0.78, 0.65, 0.32))
		rect(img, start_x, 40, 3, 2, Color(0.55, 0.38, 0.20))
	for ny in range(20, 36, 2):
		for nx in range(65, 72, 2):
			px(img, nx, ny, net)
	circle(img, 68, 24, 1.8, Color(0.85, 0.45, 0.25))
	circle(img, 66, 30, 1.8, Color(0.85, 0.45, 0.25))

	return _tex(img)


# Quầy Chú Hai - Thùng cá bơi lội, hộp mồi câu & cá sông tươi phía trước (80x28)
static func _stand_fish_front() -> ImageTexture:
	var img := _img(80, 28)
	var wood_d := Color(0.32, 0.24, 0.16)
	var wood_m := Color(0.48, 0.38, 0.26)
	var wood_l := Color(0.66, 0.54, 0.38)
	var water := Color(0.28, 0.60, 0.85)
	var water_l := Color(0.55, 0.82, 0.98)
	var silver := Color(0.85, 0.90, 0.96)
	var orange := Color(0.96, 0.55, 0.20)
	var shadow := Color(0.12, 0.18, 0.10, 0.45)

	ellipse(img, 40, 26, 38, 3, shadow)

	# 1. Thân quầy gỗ mộc ven sông (y=7..25, x=4..76)
	rect(img, 4, 7, 72, 18, wood_m)
	rect(img, 4, 7, 72, 2, wood_l)
	rect(img, 4, 23, 72, 2, wood_d)
	for y in range(11, 23, 4):
		rect(img, 4, y, 72, 1, wood_d)
		rect(img, 4, y + 1, 72, 1, wood_l)

	# Mặt bàn gỗ dày
	rect(img, 2, 3, 76, 5, wood_m)
	rect(img, 2, 3, 76, 2, wood_l)
	rect(img, 2, 7, 76, 1, wood_d)

	# 2. Thùng gỗ tròn chứa nước và cá bơi tung tăng bên trái (x=6..24, y=2..22)
	ellipse(img, 15, 12, 9, 8, wood_d)
	ellipse(img, 15, 11, 8, 7, water)
	ellipse(img, 15, 10, 7, 5, water_l)
	ellipse(img, 14, 10, 3.5, 1.8, silver)
	px(img, 11, 9, silver)
	ellipse(img, 16, 13, 3.0, 1.6, orange)
	px(img, 19, 14, orange)
	px(img, 12, 6, Color(1, 1, 1))
	px(img, 18, 5, Color(1, 1, 1, 0.8))

	# 3. Hộp đựng mồi & phao câu cá ở giữa (x=28..44, y=4..19)
	rect(img, 29, 6, 15, 10, Color(0.25, 0.45, 0.35))
	rect(img, 30, 7, 13, 8, Color(0.35, 0.58, 0.45))
	rect(img, 32, 9, 3, 2, Color(0.9, 0.2, 0.2))
	rect(img, 32, 11, 3, 2, Color(0.95, 0.95, 0.95))
	rect(img, 38, 9, 3, 2, Color(0.95, 0.5, 0.1))
	rect(img, 38, 11, 3, 2, Color(0.95, 0.95, 0.95))

	# 4. Khay gỗ ướp đá cá sông tươi rói (x=48..72, y=4..21)
	rect(img, 50, 7, 22, 11, wood_d)
	rect(img, 51, 8, 20, 9, Color(0.85, 0.92, 0.98))
	ellipse(img, 57, 10, 5, 2, silver)
	px(img, 52, 9, silver)
	px(img, 60, 10, Color(0.2, 0.2, 0.2))
	ellipse(img, 63, 14, 5, 2, silver)
	px(img, 58, 15, silver)
	px(img, 66, 14, Color(0.2, 0.2, 0.2))

	return _tex(img)


static func _scarecrow() -> ImageTexture:
	var loaded := _load_picture("res://picture/scarecrow.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(16, 28)
	rect(img, 7, 8, 2, 19, Color(0.50, 0.35, 0.20))
	rect(img, 3, 11, 10, 2, Color(0.50, 0.35, 0.20))
	rect(img, 4, 13, 8, 8, Color(0.76, 0.30, 0.24))
	px(img, 5, 15, Color(0.62, 0.22, 0.18))
	px(img, 9, 18, Color(0.62, 0.22, 0.18))
	circle(img, 8, 8, 3, Color(0.91, 0.81, 0.62))
	px(img, 6, 8, Color(0.2, 0.2, 0.2))
	px(img, 10, 8, Color(0.2, 0.2, 0.2))
	rect(img, 3, 4, 10, 2, Color(0.85, 0.72, 0.35))
	rect(img, 6, 2, 4, 2, Color(0.85, 0.72, 0.35))
	return _tex(img)


static func _coop() -> ImageTexture:
	var loaded := _load_picture("res://picture/coop.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(64, 52)
	# Bóng đổ chân chuồng
	ellipse(img, 32, 48, 28, 4, Color(0.12, 0.18, 0.10, 0.45))

	# 1. Thân nhà chuồng gỗ chính (x=12..52, y=20..46)
	var wood_base := Color(0.58, 0.38, 0.22)
	var wood_dark := Color(0.40, 0.25, 0.14)
	var wood_light := Color(0.70, 0.48, 0.28)
	var wood_beam := Color(0.32, 0.20, 0.10)

	rect(img, 12, 20, 40, 26, wood_base)

	# Ván gỗ ghép dọc & các rãnh gỗ
	for x in range(16, 52, 6):
		for y in range(21, 46):
			px(img, x, y, wood_dark)
			px(img, x + 1, y, wood_light)

	# Cột góc chịu lực bằng gỗ dày
	rect(img, 11, 20, 4, 26, wood_beam)
	rect(img, 49, 20, 4, 26, wood_beam)
	rect(img, 12, 44, 40, 2, wood_beam)

	# 2. Hộc ổ rơm bên hông (Nesting box extension bên trái x=3..12, y=28..45)
	rect(img, 4, 29, 8, 16, wood_base)
	rect(img, 3, 27, 10, 3, wood_beam) # nắp hộc nghiêng
	# Sợi rơm vàng thò ra mép nắp
	px(img, 5, 30, Color(0.95, 0.82, 0.35))
	px(img, 7, 30, Color(0.95, 0.82, 0.35))
	px(img, 9, 31, Color(0.90, 0.75, 0.30))

	# 3. Cửa chính cho gia cầm ra vào (x=24..36, y=28..46)
	rect(img, 24, 28, 14, 18, wood_beam)
	rect(img, 25, 30, 12, 16, Color(0.12, 0.08, 0.05)) # cửa tối bên trong

	# Cầu thang gỗ / ván dốc cho gà vịt leo xuống (Ramp with rungs x=24..37, y=42..51)
	var ramp := Color(0.68, 0.48, 0.28)
	for i in 8:
		rect(img, 26, 43 + i, 10, 1, ramp)
		if i % 3 == 0:
			rect(img, 25, 43 + i, 12, 1, wood_beam)

	# 4. Cửa sổ thông gió có chấn song nan tre (x=40..47, y=24..32)
	rect(img, 40, 24, 8, 8, wood_beam)
	rect(img, 41, 25, 6, 6, Color(0.18, 0.12, 0.08))
	for y in range(25, 31, 2):
		rect(img, 41, y, 6, 1, Color(0.78, 0.65, 0.38))

	# 5. Mái rơm vàng dày nhiều lớp (Thatch roof y=4..22)
	var straw_top := Color(0.92, 0.78, 0.42)
	var straw_mid := Color(0.82, 0.66, 0.32)
	var straw_dark := Color(0.60, 0.44, 0.20)
	var ridge := Color(0.48, 0.32, 0.15)

	for row in 15:
		var w := 10 + row * 4
		var cx := 32
		var left := cx - int(w / 2.0)
		var c := straw_top if row < 5 else (straw_mid if row < 12 else straw_dark)
		rect(img, left, 6 + row, w, 1, c)
		if row >= 6:
			px(img, left - 1, 6 + row, straw_mid)
			px(img, left + w, 6 + row, straw_dark)

	# Mép mái rơm rủ xuống tự nhiên
	for x in range(2, 62, 3):
		px(img, x, 21, straw_top)
		px(img, x + 1, 22, straw_mid)
		if x % 2 == 0:
			px(img, x, 23, straw_dark)

	# Đòn dông nóc nhà
	rect(img, 25, 4, 14, 3, ridge)
	rect(img, 26, 3, 12, 2, straw_top)

	# Biểu tượng chú gà trống vàng trên nóc chuồng
	var gold := Color(1.0, 0.85, 0.25)
	px(img, 32, 1, gold)
	px(img, 32, 2, gold)
	rect(img, 31, 1, 3, 1, gold)

	# Bắp ngô vàng phơi khô treo bên vách
	rect(img, 18, 24, 2, 4, Color(0.96, 0.82, 0.22))
	px(img, 18, 23, Color(0.45, 0.65, 0.25))

	return _tex(img)


# Mặt sàn lót rơm và rải hạt ngô cho khu chuồng nuôi (224x128, nền trong suốt hòa vào đất autotile)
static func _pen_bedding() -> ImageTexture:
	var img := _img(224, 128)
	var straw_base := Color(0.85, 0.72, 0.36)
	var straw_light := Color(0.95, 0.84, 0.48)
	var straw_dark := Color(0.68, 0.52, 0.24)
	var corn_seed := Color(0.98, 0.86, 0.28)

	# Nền trong suốt để hiển thị trọn vẹn nền đất autotile Stardew Valley với viền cỏ bo tròn bên dưới
	var rng := RandomNumberGenerator.new()
	rng.seed = 999

	# Lớp rơm rạ rải rác tự nhiên trong sân chuồng
	for i in 650:
		var rx := rng.randi_range(6, 217)
		var ry := rng.randi_range(6, 121)
		var len := rng.randi_range(3, 6)
		var c := straw_base if rng.randf() > 0.4 else straw_light
		for l in len:
			px(img, rx + l, ry, c)
		if rng.randf() < 0.35:
			px(img, rx + 1, ry + 1, straw_dark)

	# Các hạt thóc / ngô vàng vương vãi quanh khu ăn uống
	for i in 150:
		var cx := rng.randi_range(30, 190)
		var cy := rng.randi_range(20, 105)
		px(img, cx, cy, corn_seed)
		if rng.randf() < 0.25:
			px(img, cx + 1, cy, Color(0.92, 0.76, 0.20))

	return _tex(img)


# Nền đất trống cho chuồng Cấp 0 (224x128, rào gỗ trên nền đất trống, chưa xây chuồng)
static func _pen_dirt_bedding() -> ImageTexture:
	var img := _img(224, 128)
	var rng := RandomNumberGenerator.new()
	rng.seed = 555
	for y in range(4, 124):
		for x in range(4, 220):
			var n := rng.randf()
			if n < 0.08:
				px(img, x, y, Color(0.55, 0.40, 0.24, 0.45))
			elif n < 0.12:
				px(img, x, y, Color(0.45, 0.32, 0.18, 0.40))
			elif n < 0.14:
				px(img, x, y, Color(0.68, 0.52, 0.34, 0.35))
	for i in 40:
		var sx := rng.randi_range(10, 210)
		var sy := rng.randi_range(10, 115)
		px(img, sx, sy, Color(0.48, 0.42, 0.35, 0.7))
		px(img, sx + 1, sy, Color(0.38, 0.32, 0.25, 0.7))
	return _tex(img)


static func _coop_tier1() -> ImageTexture:
	var loaded := _load_picture("res://picture/coop_tier1.png")
	if loaded != null:
		return _tex(loaded)
	return _coop()


static func _coop_tier2() -> ImageTexture:
	var loaded := _load_picture("res://picture/coop_tier2.png")
	if loaded != null:
		return _tex(loaded)
	return _coop()


static func _barn_tier1() -> ImageTexture:
	var loaded := _load_picture("res://picture/barn_tier1.png")
	if loaded != null:
		return _tex(loaded)
	return _coop()


static func _barn_tier2() -> ImageTexture:
	var loaded := _load_picture("res://picture/barn_tier2.png")
	if loaded != null:
		return _tex(loaded)
	return _coop()


# Máng ăn gỗ đựng thức ăn (22x8)
static func _trough() -> ImageTexture:
	var loaded := _load_picture("res://picture/trough.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(32, 14)
	var wood_d := Color(0.38, 0.24, 0.12)
	var wood_m := Color(0.55, 0.36, 0.20)
	var wood_l := Color(0.70, 0.48, 0.28)
	var corn := Color(0.98, 0.84, 0.22)
	var corn_d := Color(0.85, 0.68, 0.16)

	ellipse(img, 16, 12, 14, 2, Color(0.15, 0.10, 0.05, 0.4))
	rect(img, 2, 3, 28, 8, wood_d)
	rect(img, 3, 4, 26, 6, wood_m)
	rect(img, 4, 4, 24, 4, corn_d)
	rect(img, 5, 5, 22, 3, corn)
	# Hạt nổi
	px(img, 8, 4, Color(1, 0.95, 0.5))
	px(img, 15, 4, Color(1, 0.95, 0.5))
	px(img, 22, 4, Color(1, 0.95, 0.5))
	# Chân máng
	rect(img, 3, 10, 3, 3, wood_d)
	rect(img, 26, 10, 3, 3, wood_d)
	rect(img, 1, 3, 2, 8, wood_l)
	rect(img, 29, 3, 2, 8, wood_l)
	return _tex(img)


# Máng nước trong xanh (18x8)
static func _water_trough() -> ImageTexture:
	var loaded := _load_picture("res://picture/water_trough.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(28, 14)
	var wood_d := Color(0.36, 0.22, 0.12)
	var wood_m := Color(0.50, 0.32, 0.18)
	var water_d := Color(0.30, 0.55, 0.75)
	var water_l := Color(0.50, 0.78, 0.95)

	ellipse(img, 14, 12, 12, 2, Color(0.15, 0.10, 0.05, 0.4))
	rect(img, 2, 3, 24, 8, wood_d)
	rect(img, 3, 4, 22, 6, wood_m)
	rect(img, 4, 4, 20, 5, water_d)
	rect(img, 6, 5, 16, 3, water_l)
	px(img, 8, 5, Color(0.9, 0.95, 1.0)) # ánh phản chiếu nước
	px(img, 18, 5, Color(0.9, 0.95, 1.0))
	# Chân máng
	rect(img, 3, 10, 3, 3, wood_d)
	rect(img, 22, 10, 3, 3, wood_d)
	return _tex(img)


# Đống rơm vàng truyền thống / Cuộn rơm (30x26)
static func _hay_bale() -> ImageTexture:
	var img := _img(30, 26)
	var s_top := Color(0.92, 0.80, 0.45)
	var s_mid := Color(0.80, 0.65, 0.32)
	var s_dark := Color(0.60, 0.45, 0.20)
	var rope := Color(0.40, 0.28, 0.15)

	ellipse(img, 15, 23, 13, 3, Color(0.15, 0.10, 0.05, 0.4))

	# Khối đống rơm hình chóp vòm
	for row in 18:
		var half := int(4 + row * 0.6)
		rect(img, 15 - half, 4 + row, half * 2, 1, s_mid)
		px(img, 15 - half, 4 + row, s_dark)
		px(img, 15 + half - 1, 4 + row, s_top)

	# Đỉnh rơm tua tủa
	rect(img, 13, 1, 4, 3, s_top)
	px(img, 14, 0, s_top)
	px(img, 16, 2, s_mid)

	# Dây thừng thắt đống rơm
	rect(img, 6, 12, 18, 1, rope)
	rect(img, 4, 18, 22, 1, rope)

	return _tex(img)


# Ổ rơm đẻ trứng đặt ở sân chuồng (22x16)
static func _nest_box() -> ImageTexture:
	var img := _img(22, 16)
	var s_dark := Color(0.55, 0.40, 0.18)
	var s_mid := Color(0.78, 0.62, 0.30)
	var s_light := Color(0.92, 0.80, 0.45)
	var egg_white := Color(0.96, 0.94, 0.90)
	var egg_tan := Color(0.90, 0.80, 0.68)

	ellipse(img, 11, 13, 10, 3, Color(0.12, 0.08, 0.04, 0.35))
	ellipse(img, 11, 8, 9, 6, s_dark)
	ellipse(img, 11, 8, 7, 4, s_mid)

	# 2 quả trứng tươi nằm trong ổ rơm
	ellipse(img, 9, 8, 2.5, 3.5, egg_white)
	px(img, 8, 7, Color(1, 1, 1))
	ellipse(img, 13, 8, 2.5, 3.5, egg_tan)
	px(img, 12, 7, Color(1, 1, 1, 0.8))

	# Sợi rơm xòe xung quanh mép ổ
	for a in range(0, 20, 3):
		px(img, 2 + a, 4 + (a % 3), s_light)
		px(img, 1 + a, 12 - (a % 3), s_mid)

	return _tex(img)



# Lấy Texture gốc (spritesheet) của con vật (gà, bò, lợn, cừu)
static func get_animal_tex(species_id: String, is_baby: bool = false, is_sheared: bool = false) -> Texture2D:
	var sid := PoultryDB.get_canonical_id(species_id)
	var key := "anim_tex_%s_%s_%s" % [sid, str(is_baby), str(is_sheared)]
	if _cache.has(key):
		return _cache[key]

	var path := PoultryDB.get_texture_path(sid, is_baby, is_sheared)
	if path != "" and ResourceLoader.exists(path):
		var res: Resource = ResourceLoader.load(path)
		if res is Texture2D:
			_cache[key] = res
			return res as Texture2D

	var loaded := _load_picture(path)
	if loaded != null:
		var tex := _tex(loaded)
		_cache[key] = tex
		return tex

	return null


# Lấy icon tĩnh cắt từ spritesheet cho giao diện quầy & túi đồ
static func get_animal_icon(species_id: String, is_baby: bool = false, is_sheared: bool = false) -> ImageTexture:
	var sid := PoultryDB.get_canonical_id(species_id)
	var key := "anim_ic_%s_%s_%s" % [sid, str(is_baby), str(is_sheared)]
	if _cache.has(key):
		return _cache[key]

	var path := PoultryDB.get_texture_path(sid, is_baby, is_sheared)
	var loaded := _load_picture(path)
	if loaded != null:
		var fw: int = 16 if sid == "chicken" else 32
		var fh: int = 16 if sid == "chicken" else 32
		# Cắt frame nhìn nghiêng (hàng 1) để thấy rõ thân & đầu con vật
		var sub := Image.create(fw, fh, false, Image.FORMAT_RGBA8)
		sub.blit_rect(loaded, Rect2i(0, fh, fw, fh), Vector2i.ZERO)
		var tex := _tex(sub)
		_cache[key] = tex
		return tex

	# Fallback vẽ thủ công nếu không nạp được
	var d := PoultryDB.get_animal(sid)
	var shape := str(d.get("shape", sid))
	var col := str(d.get("color", "ffffff"))
	return _procedural_animal_sprite(shape, col)


static func animal_sprite(shape: String, color_hex: String) -> ImageTexture:
	var canon := PoultryDB.get_canonical_id(shape)
	if canon in ["chicken", "cow", "pig", "sheep"]:
		return get_animal_icon(canon)
	return _procedural_animal_sprite(shape, color_hex)


static func _procedural_animal_sprite(shape: String, color_hex: String) -> ImageTexture:
	var key := "animal_%s_%s" % [shape, color_hex]
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var c := Color(color_hex)
	var dark := c.darkened(0.35)
	var beak := Color(0.9, 0.6, 0.2)
	var leg := Color(0.85, 0.6, 0.3)
	if shape == "chicken":
		ellipse(img, 7, 10, 4, 3, c)
		circle(img, 10.5, 6, 2, c)
		px(img, 10, 3, Color(0.85, 0.25, 0.2))
		px(img, 11, 3, Color(0.85, 0.25, 0.2))
		px(img, 13, 6, beak)
		px(img, 10, 6, Color(0.1, 0.1, 0.1))
		px(img, 4, 8, c.lightened(0.25))
		px(img, 3, 9, c.lightened(0.25))
		px(img, 6, 14, leg)
		px(img, 8, 14, leg)
	elif shape == "duck":
		ellipse(img, 7, 10, 4.5, 2.8, c)
		circle(img, 11, 6, 2.2, c)
		rect(img, 13, 6, 2, 1, beak)
		px(img, 10, 6, Color(0.1, 0.1, 0.1))
		px(img, 3, 8, c.lightened(0.2))
		px(img, 6, 14, leg)
		px(img, 8, 14, leg)
	else:
		ellipse(img, 7, 9, 4, 3, c)
		rect(img, 11, 4, 1, 4, c)
		circle(img, 11.5, 3.5, 1.4, c)
		px(img, 12, 3, Color(0.1, 0.1, 0.1))
		px(img, 4, 6, c.lightened(0.25))
		px(img, 6, 13, dark)
		px(img, 6, 15, dark)
		px(img, 9, 13, dark)
		px(img, 9, 15, dark)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func _fence_h() -> ImageTexture:
	var loaded := _load_picture("res://picture/fence_h.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(32, 18)
	var wood := Color(0.60, 0.42, 0.24)
	var light := Color(0.76, 0.56, 0.34)
	var dark := Color(0.40, 0.26, 0.14)
	var nail := Color(0.25, 0.16, 0.08)

	# Bóng đổ chân hàng rào
	rect(img, 0, 16, 32, 2, Color(0.12, 0.18, 0.10, 0.35))

	# Thanh ngang trên (y=4..7)
	rect(img, 0, 4, 32, 3, wood)
	rect(img, 0, 4, 32, 1, light)
	rect(img, 0, 6, 32, 1, dark)

	# Thanh ngang dưới (y=10..13)
	rect(img, 0, 10, 32, 3, wood)
	rect(img, 0, 10, 32, 1, light)
	rect(img, 0, 12, 32, 1, dark)

	# Cột gỗ đứng chính giữa (x=13..18, y=1..16)
	rect(img, 13, 1, 6, 16, wood)
	rect(img, 13, 1, 1, 16, light)
	rect(img, 18, 1, 1, 16, dark)

	# Đầu cọc vát nhọn hình nón
	px(img, 15, 0, light)
	px(img, 16, 0, light)
	px(img, 14, 1, light)
	px(img, 17, 1, dark)

	# Đinh tán cố định ở các điểm giao
	px(img, 15, 5, nail)
	px(img, 16, 5, nail)
	px(img, 15, 11, nail)
	px(img, 16, 11, nail)

	# Nhánh cỏ xanh mọc nhẹ ở chân cọc
	px(img, 12, 15, Color(0.40, 0.62, 0.25))
	px(img, 19, 15, Color(0.45, 0.68, 0.28))

	return _tex(img)


static func _fence_v() -> ImageTexture:
	var loaded := _load_picture("res://picture/fence_v.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(18, 32)
	var wood := Color(0.60, 0.42, 0.24)
	var light := Color(0.76, 0.56, 0.34)
	var dark := Color(0.40, 0.26, 0.14)
	var nail := Color(0.25, 0.16, 0.08)

	# Bóng dọc
	rect(img, 15, 0, 3, 32, Color(0.12, 0.18, 0.10, 0.3))

	# Thanh dọc trái & phải
	rect(img, 4, 0, 3, 32, wood)
	rect(img, 4, 0, 1, 32, light)
	rect(img, 6, 0, 1, 32, dark)

	rect(img, 10, 0, 3, 32, wood)
	rect(img, 10, 0, 1, 32, light)
	rect(img, 12, 0, 1, 32, dark)

	# Cột ngang nối ở giữa (y=13..18)
	rect(img, 1, 13, 16, 6, wood)
	rect(img, 1, 13, 16, 1, light)
	rect(img, 1, 18, 16, 1, dark)

	# Đinh tán
	px(img, 5, 15, nail)
	px(img, 11, 15, nail)

	return _tex(img)


static func _fence_corner() -> ImageTexture:
	var loaded := _load_picture("res://picture/fence_corner.png")
	if loaded != null:
		return _tex(loaded)
	var img := _img(22, 22)
	var wood := Color(0.60, 0.42, 0.24)
	var light := Color(0.76, 0.56, 0.34)
	var dark := Color(0.40, 0.26, 0.14)
	var nail := Color(0.25, 0.16, 0.08)

	# Bóng chân cọc góc
	ellipse(img, 11, 19, 9, 3, Color(0.12, 0.18, 0.10, 0.4))

	# Cột góc to vững chãi (x=6..15, y=1..19)
	rect(img, 6, 2, 10, 18, wood)
	rect(img, 6, 2, 2, 18, light)
	rect(img, 14, 2, 2, 18, dark)


	# Chóp cọc vát hình kim tự tháp
	rect(img, 8, 1, 6, 1, light)
	px(img, 10, 0, light)
	px(img, 11, 0, light)

	# Nẹp đai sắt gia cố cọc góc
	rect(img, 5, 6, 12, 2, Color(0.35, 0.30, 0.25))
	rect(img, 5, 14, 12, 2, Color(0.35, 0.30, 0.25))
	px(img, 7, 7, nail)
	px(img, 13, 7, nail)

	# Cỏ mọc chân cọc
	px(img, 5, 19, Color(0.42, 0.65, 0.26))
	px(img, 16, 18, Color(0.45, 0.68, 0.28))

	return _tex(img)


static func _fence_corner_dir(dir: String) -> ImageTexture:
	var loaded := _load_picture("res://picture/fence_corner_" + dir + ".png")
	if loaded != null:
		return _tex(loaded)
	return _fence_corner()


# ---------- NHÂN VẬT DÂN LÀNG STARDEW VALLEY (NPC) ----------
const SDV_CHARACTERS := [
	"Abigail", "Haley", "Leah", "Penny", "Sam",
	"Alex", "Emily", "Harvey", "Maru", "Sebastian"
]

static func sdv_char_tex(char_name: String, dir: String, frame_idx: int) -> Texture2D:
	var cname := char_name if char_name != "" else "Abigail"
	var row := 0
	match dir:
		"down":
			row = 0
		"right", "side":
			row = 1
		"up":
			row = 2
		"left":
			row = 3
		_:
			row = 0

	var col := absi(frame_idx) % 4
	var key := "sdv_char_%s_%d_%d" % [cname, row, col]
	if _cache.has(key):
		return _cache[key]

	var sheet_key := "sdv_sheet_" + cname
	var sheet: Texture2D = null
	if _cache.has(sheet_key):
		sheet = _cache[sheet_key]
	else:
		var pic_path := "res://picture/characters/%s.png" % cname
		if ResourceLoader.exists(pic_path):
			sheet = ResourceLoader.load(pic_path) as Texture2D
		if sheet == null:
			var img := _load_picture(pic_path)
			if img != null:
				sheet = _tex(img)
		if sheet == null:
			var fallback_path := "res://Content (unpacked)/Characters/%s.png" % cname
			if ResourceLoader.exists(fallback_path):
				sheet = ResourceLoader.load(fallback_path) as Texture2D
			if sheet == null:
				var img_fb := _load_picture(fallback_path)
				if img_fb != null:
					sheet = _tex(img_fb)
		if sheet != null:
			_cache[sheet_key] = sheet

	if sheet != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(col * 16, row * 32, 16, 32)
		_cache[key] = atlas
		return atlas

	return char_tex(dir, frame_idx, true)


static func sweat_drop_icon() -> ImageTexture:
	if _cache.has("sweat_drop"):
		return _cache["sweat_drop"]
	var img := _img(12, 12)
	var blue := Color(0.35, 0.65, 0.95)
	var light_blue := Color(0.70, 0.88, 1.0)
	px(img, 5, 2, blue)
	px(img, 6, 2, blue)
	rect(img, 4, 3, 4, 2, blue)
	rect(img, 3, 5, 6, 4, blue)
	rect(img, 4, 9, 4, 2, blue)
	px(img, 4, 5, light_blue)
	px(img, 4, 6, light_blue)
	var t := _tex(img)
	_cache["sweat_drop"] = t
	return t


# ---------- nhân vật (nón lá!) ----------

static func char_action_tex(dir: String, act: String, step: int) -> ImageTexture:
	var d := dir
	if d != "up" and d != "down":
		d = "side"
	var key := "char_act_%s_%s_%d" % [d, act, step]
	if _cache.has(key):
		return _cache[key]
	var path := "res://picture/farmer_%s_%s_%d.png" % [d, act, step]
	var loaded := _load_picture(path)
	if loaded != null:
		var t := _tex(loaded)
		_cache[key] = t
		return t
	return char_tex(dir, 99)


static func char_tex(dir: String, frame: int, npc: bool = false) -> ImageTexture:
	var key := "char_%s_%d_%d" % [dir, frame, 1 if npc else 0]
	if _cache.has(key):
		return _cache[key]

	if not npc:
		var pic_name := ""
		if frame == 99:
			pic_name = "farmer_%s_action" % dir
		else:
			var sub_frame := 0
			match frame:
				0, 2:
					sub_frame = 0
				1:
					sub_frame = 1
				3:
					sub_frame = 2
				_:
					sub_frame = frame % 3
			pic_name = "farmer_%s_%d" % [dir, sub_frame]
		var loaded := _load_picture("res://picture/%s.png" % pic_name)
		if loaded != null:
			var t := _tex(loaded)
			_cache[key] = t
			return t

	var img := _img(16, 16)
	var skin := Color(0.95, 0.79, 0.60)
	var hair := Color(0.28, 0.20, 0.13)
	var boot := Color(0.36, 0.25, 0.16)
	var shirt := Color(0.62, 0.38, 0.20) if npc else Color(0.23, 0.50, 0.28)
	var pants := Color(0.42, 0.36, 0.28) if npc else Color(0.35, 0.40, 0.55)
	var hatc := Color(0.91, 0.80, 0.38)
	var hatd := Color(0.78, 0.66, 0.27)
	var eye := Color(0.15, 0.13, 0.11)

	if npc:
		# tóc + mặt
		rect(img, 4, 3, 8, 3, hair)
		rect(img, 5, 5, 6, 3, skin)
		px(img, 6, 6, eye)
		px(img, 9, 6, eye)
	else:
		# nón lá
		rect(img, 6, 1, 4, 1, hatc)
		rect(img, 5, 2, 6, 1, hatc)
		rect(img, 4, 3, 8, 1, hatd)
		rect(img, 3, 4, 10, 1, hatd)
		if dir == "up":
			rect(img, 5, 5, 6, 3, hair)
		else:
			rect(img, 5, 5, 6, 3, skin)
			if dir == "down":
				px(img, 6, 6, eye)
				px(img, 9, 6, eye)
			else:
				px(img, 10, 6, eye)
	# thân
	if dir == "side":
		rect(img, 5, 8, 6, 4, shirt)
		rect(img, 10, 9, 2, 3, shirt)
		px(img, 11, 11, skin)
	else:
		rect(img, 4, 8, 8, 4, shirt)
		rect(img, 3, 9, 1, 3, shirt)
		rect(img, 12, 9, 1, 3, shirt)
		px(img, 3, 11, skin)
		px(img, 12, 11, skin)
	# chân
	if dir == "side":
		if frame == 1:
			rect(img, 5, 12, 2, 4, pants)
			px(img, 5, 15, boot)
			rect(img, 9, 12, 2, 2, pants)
		else:
			rect(img, 6, 12, 2, 3, pants)
			rect(img, 9, 12, 2, 3, pants)
			px(img, 6, 15, boot)
			px(img, 9, 15, boot)
	else:
		if frame == 1:
			rect(img, 5, 12, 2, 4, pants)
			px(img, 5, 15, boot)
			rect(img, 9, 12, 2, 2, pants)
			px(img, 9, 13, boot)
		else:
			rect(img, 5, 12, 2, 3, pants)
			rect(img, 9, 12, 2, 3, pants)
			rect(img, 5, 15, 2, 1, boot)
			rect(img, 9, 15, 2, 1, boot)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


# Tạo sprite nhân vật NPC độc nhất cho từng người: Bác Tư, Cô Tư, Chú Hai (18x22)
static func npc_tex(npc_type: String) -> ImageTexture:
	var key := "npc_%s" % npc_type
	if _cache.has(key):
		return _cache[key]
	var img := _img(18, 22)

	match npc_type:
		"bac_tu":
			# Bác Tư: Lão nông Việt Nam râu tóc bạc phơ hiền từ, áo bà ba nâu, quàng khăn rằn Nam Bộ
			var skin := Color(0.90, 0.74, 0.56)
			var skin_d := Color(0.80, 0.64, 0.46)
			var hair := Color(0.86, 0.86, 0.90)
			var hair_d := Color(0.70, 0.70, 0.74)
			var brown_cloth := Color(0.46, 0.30, 0.16)
			var brown_l := Color(0.58, 0.40, 0.24)
			var eye := Color(0.18, 0.14, 0.10)
			var k_black := Color(0.18, 0.18, 0.18)
			var k_white := Color(0.94, 0.94, 0.94)

			# Tóc bạc hai bên và gáy (đỉnh đầu thưa)
			rect(img, 4, 3, 10, 4, hair)
			rect(img, 3, 4, 12, 4, hair_d)
			rect(img, 6, 2, 6, 2, skin) # đỉnh trán hói nhẹ

			# Khuôn mặt hiền từ (x=5..12, y=4..11)
			rect(img, 5, 4, 8, 7, skin)
			px(img, 6, 6, eye) # mắt cười hiền
			px(img, 11, 6, eye)
			px(img, 6, 5, hair) # lông mày bạc
			px(img, 11, 5, hair)
			# Nụ cười & ria mép bạc
			rect(img, 6, 8, 6, 2, hair)
			px(img, 8, 9, Color(0.7, 0.35, 0.3)) # môi cười
			px(img, 9, 9, Color(0.7, 0.35, 0.3))
			# Chòm râu bạc dài
			rect(img, 7, 10, 4, 2, hair)
			px(img, 8, 12, hair)
			px(img, 9, 12, hair)

			# Thân áo bà ba nâu
			rect(img, 3, 12, 12, 9, brown_cloth)
			rect(img, 3, 12, 1, 9, brown_l)
			rect(img, 14, 12, 1, 9, brown_cloth.darkened(0.2))
			# Cúc áo ngực
			for cy in [13, 15, 17, 19]:
				px(img, 9, cy, brown_l)

			# Khăn rằn Nam Bộ quàng chéo vai trái
			for i in 8:
				var kx := 4 + int(i * 0.7)
				var ky := 12 + i
				var c := k_white if (kx + ky) % 2 == 0 else k_black
				rect(img, kx, ky, 3, 1, c)
			# Tua rua khăn rằn dưới vạt áo
			px(img, 9, 20, k_white)
			px(img, 10, 20, k_black)
			px(img, 9, 21, k_white)

			# Cổ tay & bàn tay đặt trên quầy
			px(img, 3, 20, skin)
			px(img, 4, 20, skin)
			px(img, 13, 20, skin)
			px(img, 14, 20, skin)

		"co_tu":
			# Cô Tư: Phụ nữ nông thôn duyên dáng, tóc búi cài trâm hoa sen, áo bà ba hồng sen thanh lịch
			var skin := Color(0.96, 0.82, 0.68)
			var skin_r := Color(0.94, 0.64, 0.64)
			var hair := Color(0.14, 0.12, 0.14)
			var hair_h := Color(0.28, 0.24, 0.28)
			var pink_cloth := Color(0.86, 0.44, 0.60)
			var pink_l := Color(0.94, 0.58, 0.72)
			var pink_d := Color(0.70, 0.32, 0.48)
			var white := Color(0.98, 0.96, 0.94)
			var eye := Color(0.12, 0.10, 0.12)
			var lotus := Color(0.98, 0.40, 0.65)

			# Tóc đen mượt búi gọn gàng
			circle(img, 9, 4, 4.5, hair)
			rect(img, 7, 1, 4, 3, hair) # búi tóc trên
			px(img, 8, 2, hair_h)
			# Trâm cài hoa sen hồng trên búi tóc
			px(img, 12, 2, lotus)
			px(img, 13, 1, lotus)
			px(img, 13, 2, Color(1, 0.85, 0.4)) # nhụy vàng

			# Khuôn mặt rạng rỡ, má lúm đồng tiền
			rect(img, 5, 5, 8, 6, skin)
			rect(img, 6, 10, 6, 2, skin)
			# Mắt to tròn với mi cong
			px(img, 6, 7, eye)
			px(img, 11, 7, eye)
			px(img, 6, 6, hair) # mi
			px(img, 11, 6, hair)
			# Má hồng đào
			px(img, 5, 8, skin_r)
			px(img, 12, 8, skin_r)
			# Nụ cười tươi tắn
			px(img, 8, 10, Color(0.85, 0.35, 0.4))
			px(img, 9, 10, Color(0.85, 0.35, 0.4))

			# Áo bà ba hồng hoa sen với nẹp cổ trắng tinh khôi
			rect(img, 4, 12, 10, 9, pink_cloth)
			rect(img, 4, 12, 1, 9, pink_l)
			rect(img, 13, 12, 1, 9, pink_d)
			# Nẹp viền cổ áo bà ba màu trắng ngà
			rect(img, 8, 12, 2, 4, white)
			rect(img, 7, 12, 1, 2, white)
			rect(img, 10, 12, 1, 2, white)
			# Tạp dề / thắt lưng vải trắng gọn gàng
			rect(img, 5, 17, 8, 4, white)
			px(img, 9, 18, pink_d)

			# Bàn tay chào đón
			px(img, 3, 17, skin)
			px(img, 3, 18, skin)
			px(img, 14, 17, skin)
			px(img, 14, 18, skin)

		"chu_hai":
			# Chú Hai: Ngư dân dạn dày sông nước, da bánh mật, khăn đỏ buộc trán, áo chàm khỏe khoắn
			var skin := Color(0.82, 0.60, 0.42)
			var skin_d := Color(0.70, 0.50, 0.32)
			var hair := Color(0.18, 0.15, 0.12)
			var red_band := Color(0.88, 0.22, 0.18)
			var red_knot := Color(0.70, 0.16, 0.12)
			var indigo := Color(0.20, 0.40, 0.58)
			var indigo_l := Color(0.32, 0.54, 0.72)
			var indigo_d := Color(0.12, 0.28, 0.42)
			var eye := Color(0.12, 0.10, 0.10)

			# Tóc đen hơi rối theo gió sông
			rect(img, 4, 2, 10, 4, hair)
			px(img, 3, 4, hair)
			px(img, 14, 4, hair)
			# Khăn đỏ quấn trán đặc trưng ngư dân
			rect(img, 4, 4, 10, 2, red_band)
			rect(img, 4, 4, 10, 1, Color(0.98, 0.4, 0.3))
			# Mối thắt khăn bên thái dương rủ xuống
			px(img, 14, 5, red_knot)
			rect(img, 15, 6, 2, 3, red_band)

			# Khuôn mặt phong trần rám nắng
			rect(img, 5, 6, 8, 6, skin)
			rect(img, 6, 6, 2, 1, hair)
			rect(img, 10, 6, 2, 1, hair)
			px(img, 6, 7, eye)
			px(img, 11, 7, eye)
			for bx in [5, 6, 11, 12]:
				px(img, bx, 10, skin_d)
			rect(img, 7, 9, 4, 2, skin_d)
			rect(img, 8, 9, 2, 1, Color(0.98, 0.98, 0.98))

			# Áo bà ba xanh chàm khoét nách / xắn tay áo lộ bắp tay rắn rỏi
			rect(img, 4, 12, 10, 9, indigo)
			rect(img, 4, 12, 1, 9, indigo_l)
			rect(img, 13, 12, 1, 9, indigo_d)
			px(img, 8, 12, skin)
			px(img, 9, 12, skin)
			px(img, 8, 13, skin)
			px(img, 9, 13, skin)
			px(img, 8, 14, Color(0.85, 0.7, 0.4))

			# Cánh tay lực lưỡng rám nắng đặt lên bàn
			rect(img, 2, 14, 2, 7, skin)
			rect(img, 14, 14, 2, 7, skin)
			rect(img, 2, 19, 3, 2, skin_d)
			rect(img, 13, 19, 3, 2, skin_d)

		"truong_thon":
			# Bác Trưởng Thôn: Phong thái phúc hậu, mũ nan thanh lịch, râu ria mép hiền từ, áo ký giả vàng nâu sang trọng
			var skin := Color(0.86, 0.68, 0.50)
			var skin_d := Color(0.74, 0.56, 0.38)
			var hair_grey := Color(0.55, 0.55, 0.58)
			var hat_brim := Color(0.45, 0.32, 0.18)
			var hat_top := Color(0.60, 0.45, 0.28)
			var hat_band := Color(0.85, 0.25, 0.20)
			var coat := Color(0.58, 0.42, 0.22)
			var coat_l := Color(0.72, 0.54, 0.32)
			var coat_d := Color(0.40, 0.28, 0.14)
			var shirt_in := Color(0.92, 0.90, 0.85)
			var eye := Color(0.15, 0.12, 0.10)

			# Mũ nan rộng vành phong cách trưởng làng
			rect(img, 2, 3, 14, 2, hat_brim)
			rect(img, 5, 0, 8, 3, hat_top)
			rect(img, 5, 2, 8, 1, hat_band)
			px(img, 5, 1, Color(0.75, 0.60, 0.40))

			# Tóc mai hoa râm hai bên
			px(img, 4, 4, hair_grey)
			px(img, 4, 5, hair_grey)
			px(img, 13, 4, hair_grey)
			px(img, 13, 5, hair_grey)

			# Gương mặt phúc hậu
			rect(img, 5, 4, 8, 7, skin)
			px(img, 6, 6, eye)
			px(img, 11, 6, eye)
			px(img, 6, 5, hair_grey) # lông mày rậm
			px(img, 11, 5, hair_grey)

			# Bộ ria mép xồm xoàm đáng kính
			rect(img, 6, 8, 6, 2, hair_grey)
			px(img, 5, 9, hair_grey)
			px(img, 12, 9, hair_grey)
			px(img, 8, 10, Color(0.8, 0.4, 0.4)) # miệng cười mỉm

			# Áo ký giả vàng nâu đĩnh đạc
			rect(img, 4, 11, 10, 10, coat)
			rect(img, 4, 11, 1, 10, coat_l)
			rect(img, 13, 11, 1, 10, coat_d)
			# Cổ áo sơ mi trắng bên trong & cravat / khăn quàng nhỏ
			rect(img, 8, 11, 2, 3, shirt_in)
			px(img, 8, 12, Color(0.85, 0.2, 0.2)) # caravat đỏ
			px(img, 8, 13, Color(0.85, 0.2, 0.2))

			# Cúc áo mạ đồng & túi áo trước ngực
			px(img, 8, 15, Color(0.95, 0.85, 0.3))
			px(img, 8, 18, Color(0.95, 0.85, 0.3))
			rect(img, 10, 13, 3, 2, coat_d)

			# Tay áo
			rect(img, 2, 12, 2, 7, coat)
			rect(img, 14, 12, 2, 7, coat)
			rect(img, 2, 19, 2, 2, skin)
			rect(img, 14, 19, 2, 2, skin)

	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func quest_mark_tex(type: String) -> ImageTexture:
	var key := "quest_mark_%s" % type
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var bg_circle := Color(0.12, 0.08, 0.04, 0.85)
	circle(img, 8, 8, 7, bg_circle)

	if type == "exclamation": # Dấu ! vàng rực rỡ khi có nhiệm vụ mới
		var gold := Color(1.0, 0.85, 0.15)
		var bright := Color(1.0, 1.0, 0.70)
		var border := Color(0.65, 0.45, 0.05)
		circle(img, 8, 8, 6, border)
		rect(img, 7, 3, 2, 6, gold)
		rect(img, 7, 3, 1, 6, bright)
		rect(img, 7, 10, 2, 2, gold)
		px(img, 7, 10, bright)
	else: # Dấu ? vàng xanh lấp lánh khi có thưởng chờ nhận
		var green := Color(0.35, 0.95, 0.45)
		var bright := Color(0.85, 1.0, 0.85)
		var border := Color(0.10, 0.55, 0.20)
		circle(img, 8, 8, 6, border)
		rect(img, 6, 3, 4, 2, green)
		rect(img, 9, 4, 2, 3, green)
		rect(img, 7, 6, 3, 2, green)
		rect(img, 7, 7, 2, 2, green)
		rect(img, 7, 10, 2, 2, green)
		px(img, 7, 3, bright)
		px(img, 7, 10, bright)

	var tex := _tex(img)
	_cache[key] = tex
	return tex


# ---------- cây trồng ----------

# Nạp ảnh từ thư mục picture: đọc trực tiếp file trên đĩa vì game chạy không qua
# editor (ảnh chưa được import); nếu đã import thì fallback qua ResourceLoader.
static func _load_picture(path: String) -> Image:
	if path == "":
		return null
	var img := Image.new()
	var gp := ProjectSettings.globalize_path(path)
	if gp != "" and FileAccess.file_exists(gp):
		if img.load(gp) == OK:
			if img.get_format() != Image.FORMAT_RGBA8:
				img.convert(Image.FORMAT_RGBA8)
			return img
	if ResourceLoader.exists(path):
		var res: Resource = ResourceLoader.load(path)
		if res is Texture2D:
			var timg: Image = (res as Texture2D).get_image()
			if timg != null:
				if timg.get_format() != Image.FORMAT_RGBA8:
					timg.convert(Image.FORMAT_RGBA8)
				return timg
	return null


# Ảnh chính của cây đã chín: ảnh trong picture/ (nhìn từ trên xuống, nền đất)
# thu về và phủ kín ô 32x32. Thiếu ảnh thì trả null để vẽ pixel-art thay thế.
static func ripe_picture_img(id: String) -> Image:
	var key := "ripe_pic_%s" % id
	if _cache.has(key):
		return _cache[key]
	_cache[key] = null
	var img := _load_picture(CropDB.picture_path(id))
	if img != null:
		var w := img.get_width()
		var h := img.get_height()
		var s: float = maxf(32.0 / w, 32.0 / h)
		img.resize(maxi(1, int(round(w * s))), maxi(1, int(round(h * s))), Image.INTERPOLATE_LANCZOS)
		var tile := _img(32, 32)
		var cw := mini(img.get_width(), 32)
		var ch := mini(img.get_height(), 32)
		tile.blend_rect(img, Rect2i(0, 0, cw, ch), Vector2i((32 - cw) >> 1, (32 - ch) >> 1))
		img = tile
	_cache[key] = img
	return img


static func ripe_picture_tex(id: String) -> ImageTexture:
	var img := ripe_picture_img(id)
	return null if img == null else _tex(img)


static func crop_tex(crop: Dictionary, stage: int) -> ImageTexture:
	var key := "crop_%s_%d" % [crop.id, stage]
	if _cache.has(key):
		return _cache[key]
	var path := "res://picture/crops/crop_%s_stage_%d.png" % [crop.id, stage]
	var loaded := _load_picture(path)
	if loaded != null:
		var tex := _tex(loaded)
		_cache[key] = tex
		return tex
	# Nếu vượt quá stage, thử lấy stage chín cao nhất có sẵn
	for s in range(stage - 1, -1, -1):
		var fallback_path := "res://picture/crops/crop_%s_stage_%d.png" % [crop.id, s]
		var fallback_loaded := _load_picture(fallback_path)
		if fallback_loaded != null:
			var tex := _tex(fallback_loaded)
			_cache[key] = tex
			return tex
	var img := _img(16, 16)
	var accent := Color(str(crop.color))
	var leaf := Color(str(crop.leaf))
	var dark := leaf.darkened(0.3)
	var stem := Color(0.40, 0.55, 0.25)

	if stage <= 0:
		# hạt vừa gieo
		px(img, 7, 13, Color(0.72, 0.58, 0.38))
		px(img, 9, 14, Color(0.72, 0.58, 0.38))
		px(img, 8, 12, Color(0.80, 0.66, 0.44))
	elif stage == 1:
		# mầm non
		rect(img, 8, 11, 1, 4, stem)
		px(img, 6, 10, leaf)
		px(img, 7, 9, leaf)
		px(img, 10, 10, leaf)
		px(img, 9, 9, leaf)
		px(img, 8, 10, leaf)
	else:
		match str(crop.shape):
			"grain":
				_shape_grain(img, stage, accent, leaf, dark)
			"tall":
				_shape_tall(img, stage, accent, leaf, dark, str(crop.id))
			"bush":
				_shape_bush(img, stage, accent, leaf, dark, str(crop.id))
			"root":
				_shape_root(img, stage, accent, leaf, dark)
			"vine":
				_shape_vine(img, stage, accent, leaf, dark)
			"head":
				_shape_head(img, stage, accent, leaf, dark)
			"tree":
				_shape_tree(img, stage, accent, leaf, dark)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func _shape_grain(img: Image, stage: int, accent: Color, leaf: Color, dark: Color) -> void:
	for i in 4:
		var x := 3 + i * 3
		var top := 15 - (7 if stage == 2 else 10)
		for y in range(top, 16):
			px(img, x, y, Color(0.45, 0.60, 0.28))
		px(img, x - 1, top + 3, leaf)
		px(img, x + 1, top + 5, leaf)
		if stage == 2:
			px(img, x, top, leaf)
			px(img, x, top - 1, dark)
		else:
			# bông lúa / lúa mì chín vàng
			rect(img, x - 1, top - 2, 3, 3, accent)
			px(img, x, top - 3, accent)
			px(img, x - 1, top - 3, dark)


static func _shape_tall(img: Image, stage: int, accent: Color, leaf: Color, dark: Color, id: String) -> void:
	var top := 6 if stage == 2 else 4
	for y in range(top, 16):
		px(img, 8, y, Color(0.42, 0.58, 0.26))
	# lá hai bên
	for y in range(top + 1, 14, 2):
		px(img, 6, y, leaf)
		px(img, 5, y + 1, dark)
		px(img, 10, y + 1, leaf)
		px(img, 11, y + 2, dark)
	px(img, 8, top, leaf)
	px(img, 7, top - 1, leaf)
	px(img, 9, top - 1, leaf)
	if stage == 3:
		match id:
			"corn":
				rect(img, 6, 7, 3, 5, accent)
				px(img, 6, 7, dark)
				px(img, 8, 11, dark)
				px(img, 7, 8, Color(1.0, 0.95, 0.75))
			"sugarcane":
				for y in range(5, 15, 2):
					px(img, 8, y, accent)
				px(img, 8, 4, accent)
			"pepper":
				px(img, 6, 7, accent)
				px(img, 10, 9, accent)
				px(img, 8, 6, accent)
				px(img, 6, 8, Color(0.35, 0.5, 0.2))
			"cassava":
				px(img, 7, 14, accent)
				px(img, 9, 15, accent)
				circle(img, 8, 4, 2, leaf)


static func _shape_bush(img: Image, stage: int, accent: Color, leaf: Color, dark: Color, id: String) -> void:
	var cy := 10 if id != "peanut" else 12
	var r := 4 if stage == 2 else 5
	circle(img, 8, cy, r, leaf)
	circle(img, 6, cy - 1, r - 2, dark)
	if stage == 3:
		if id == "coffee":
			px(img, 6, cy, accent)
			px(img, 10, cy - 2, accent)
			px(img, 8, cy + 2, accent)
			px(img, 11, cy + 1, accent)
		elif id == "soybean":
			px(img, 6, cy + 1, accent)
			px(img, 10, cy - 1, accent)
			px(img, 8, cy + 2, accent)
		elif id == "peanut":
			px(img, 5, 14, accent)
			px(img, 8, 15, accent)
			px(img, 11, 14, accent)
		else:
			# cà chua
			px(img, 5, cy - 1, accent)
			px(img, 10, cy, accent)
			px(img, 8, cy + 3, accent)
			px(img, 12, cy - 3, accent)
			px(img, 5, cy - 2, accent.lightened(0.25))


static func _shape_root(img: Image, stage: int, accent: Color, leaf: Color, dark: Color) -> void:
	# chùm lá trên mặt đất
	px(img, 8, 9, leaf)
	px(img, 7, 10, leaf)
	px(img, 9, 10, leaf)
	px(img, 6, 11, dark)
	px(img, 10, 11, dark)
	px(img, 8, 11, dark)
	px(img, 5, 12, leaf)
	px(img, 11, 12, leaf)
	px(img, 8, 13, dark)
	if stage == 3:
		# đầu củ nhô lên khỏi đất
		rect(img, 7, 13, 3, 2, accent)
		px(img, 8, 12, accent)
		px(img, 7, 15, accent.darkened(0.2))
		px(img, 9, 15, accent.darkened(0.2))


static func _shape_vine(img: Image, stage: int, accent: Color, leaf: Color, dark: Color) -> void:
	for x in range(3, 13):
		px(img, x, 12, dark)
	px(img, 4, 10, leaf)
	px(img, 3, 11, leaf)
	px(img, 8, 10, leaf)
	px(img, 12, 10, leaf)
	px(img, 13, 11, leaf)
	px(img, 6, 13, leaf)
	px(img, 10, 13, leaf)
	if stage == 3:
		circle(img, 9, 9, 3, accent)
		px(img, 8, 7, Color(0.45, 0.68, 0.38))
		px(img, 10, 10, Color(0.45, 0.68, 0.38))
		px(img, 7, 10, Color(0.45, 0.68, 0.38))
		px(img, 9, 5, dark)


static func _shape_head(img: Image, stage: int, accent: Color, leaf: Color, dark: Color) -> void:
	if stage == 2:
		circle(img, 8, 11, 3, leaf)
		circle(img, 8, 11, 1, accent)
	else:
		circle(img, 8, 10, 5, dark)
		circle(img, 8, 10, 4, accent)
		circle(img, 8, 10, 2, accent.lightened(0.25))
		px(img, 5, 8, dark)
		px(img, 11, 12, dark)


static func _shape_tree(img: Image, stage: int, accent: Color, leaf: Color, dark: Color) -> void:
	rect(img, 7, 8, 2, 8, Color(0.45, 0.30, 0.18))
	circle(img, 8, 6, 4, leaf)
	circle(img, 6, 5, 2, dark)
	if stage == 3:
		# vắt mủ cao su
		rect(img, 6, 13, 4, 2, Color(0.75, 0.78, 0.78))
		px(img, 7, 12, accent)
		px(img, 8, 12, accent)
		px(img, 7, 9, Color(0.85, 0.55, 0.3))


# ---------- icon ----------

static func hoe_icon() -> ImageTexture:
	var key := "hoe_icon"
	if _cache.has(key):
		return _cache[key]
	var loaded := _load_picture("res://picture/hoe_icon.png")
	if loaded != null:
		var t := _tex(loaded)
		_cache[key] = t
		return t
	var img := _img(16, 16)
	var wood := Color(0.55, 0.38, 0.22)
	var metal := Color(0.72, 0.75, 0.78)
	# cán chéo
	for i in 8:
		px(img, 3 + i, 13 - i, wood)
		px(img, 4 + i, 13 - i, wood.darkened(0.15))
	# lưỡi cuốc
	rect(img, 9, 2, 5, 3, metal)
	px(img, 9, 5, metal.darkened(0.2))
	px(img, 13, 5, metal.darkened(0.2))
	px(img, 10, 3, Color(1, 1, 1, 0.5))
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func watering_can_icon() -> ImageTexture:
	var key := "watering_can_icon"
	if _cache.has(key):
		return _cache[key]
	var loaded := _load_picture("res://picture/watering_can_icon.png")
	if loaded != null:
		var t := _tex(loaded)
		_cache[key] = t
		return t
	var img := _img(16, 16)
	var metal := Color(0.70, 0.75, 0.80)
	var water := Color(0.35, 0.65, 0.95)
	rect(img, 3, 5, 10, 7, metal)
	rect(img, 9, 3, 4, 3, water)
	var tex := _tex(img)
	_cache[key] = tex
	return tex



static func rod_icon(color_hex: String) -> ImageTexture:
	var key := "rod_icon_%s" % color_hex
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var c := Color(color_hex)
	var dark := c.darkened(0.3)
	for i in 9:
		px(img, 3 + i, 13 - i, c)
		px(img, 4 + i, 13 - i, dark)
	# dây + lưỡi câu
	px(img, 12, 5, Color(0.85, 0.85, 0.85))
	px(img, 12, 6, Color(0.85, 0.85, 0.85))
	px(img, 12, 7, Color(0.85, 0.85, 0.85))
	px(img, 11, 8, Color(0.85, 0.85, 0.85))
	px(img, 11, 9, Color(0.9, 0.9, 0.9))
	# cuộn dây
	rect(img, 5, 10, 3, 2, dark)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func fish_icon(color_hex: String) -> ImageTexture:
	var key := "fish_icon_%s" % color_hex
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var c := Color(color_hex)
	var dark := c.darkened(0.3)
	# thân
	ellipse(img, 6.5, 8, 4.5, 2.6, c)
	# đuôi xòe ra sau
	rect(img, 11, 7, 2, 3, dark)
	px(img, 12, 6, dark)
	px(img, 12, 10, dark)
	px(img, 13, 5, dark)
	px(img, 13, 11, dark)
	# vây lưng + bụng
	px(img, 5, 5, dark)
	px(img, 6, 5, dark)
	px(img, 6, 11, c.lightened(0.3))
	px(img, 7, 11, c.lightened(0.3))
	# mắt + mang
	px(img, 3, 7, Color(0.1, 0.1, 0.1))
	px(img, 9, 7, dark)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func seed_icon(crop: Dictionary) -> ImageTexture:
	var key := "seed_icon_%s" % crop.id
	if _cache.has(key):
		return _cache[key]
	var path := "res://picture/crops/seed_%s.png" % crop.id
	var loaded := _load_picture(path)
	if loaded != null:
		var tex := _tex(loaded)
		_cache[key] = tex
		return tex
	var img := _img(16, 16)
	var bag := Color(0.84, 0.72, 0.50)
	var bagd := Color(0.66, 0.54, 0.34)
	var accent := Color(str(crop.color))
	rect(img, 5, 6, 7, 8, bag)
	rect(img, 5, 6, 7, 2, bagd)
	rect(img, 6, 4, 4, 2, bagd)
	px(img, 5, 5, bagd)
	px(img, 10, 5, bagd)
	circle(img, 8, 11, 2, accent)
	px(img, 7, 10, accent.lightened(0.3))
	px(img, 12, 13, bagd)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func seed_bag_tex(seed_id: String) -> ImageTexture:
	var c := CropDB.get_crop(seed_id)
	return seed_icon(c)


# Icon tròn generic dùng cho sản phẩm chăn nuôi (trứng/thịt/lông).
static func orb_icon(color_hex: String) -> ImageTexture:
	var key := "orb_icon_%s" % color_hex
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var c := Color(color_hex)
	circle(img, 8, 9, 4, c.darkened(0.15))
	circle(img, 8, 9, 3, c)
	px(img, 6, 8, Color(1, 1, 1, 0.55))
	px(img, 6, 9, Color(1, 1, 1, 0.35))
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func egg_icon(color_hex: String) -> ImageTexture:
	var key := "egg_icon_%s" % color_hex
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var c := Color(color_hex)
	var light := c.lightened(0.2)
	ellipse(img, 8, 8, 4.5, 6, c.darkened(0.15))
	ellipse(img, 7.5, 7.5, 3.5, 5, light)
	px(img, 6, 6, Color.WHITE)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func springobject_icon(idx: int) -> ImageTexture:
	var key := "sprobj_%d" % idx
	if _cache.has(key):
		return _cache[key]
	var loaded := _load_picture("res://Content (unpacked)/Maps/springobjects.png")
	if loaded != null:
		var cols: int = loaded.get_width() / 16
		var r: int = idx / cols
		var c: int = idx % cols
		var sub := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		sub.blit_rect(loaded, Rect2i(c * 16, r * 16, 16, 16), Vector2i.ZERO)
		var tex := _tex(sub)
		_cache[key] = tex
		return tex
	return null


static func milk_icon() -> ImageTexture:
	var sp := springobject_icon(184)
	if sp != null:
		return sp
	var key := "milk_icon"
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var milk := Color(0.96, 0.96, 0.98)
	var cap := Color(0.2, 0.5, 0.85)
	var glass := Color(0.75, 0.82, 0.9, 0.7)
	rect(img, 7, 2, 2, 2, cap)
	rect(img, 6, 4, 4, 2, glass)
	rect(img, 5, 6, 6, 8, milk)
	rect(img, 4, 8, 8, 5, milk)
	rect(img, 4, 6, 1, 7, glass)
	rect(img, 11, 6, 1, 7, glass)
	rect(img, 5, 13, 6, 1, glass)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func wool_icon() -> ImageTexture:
	var sp := springobject_icon(440)
	if sp != null:
		return sp
	var key := "wool_icon"
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var w := Color(0.95, 0.95, 0.92)
	var shadow := Color(0.78, 0.78, 0.75)
	circle(img, 8, 8, 5.5, shadow)
	circle(img, 6, 7, 3.5, w)
	circle(img, 10, 7, 3.5, w)
	circle(img, 8, 10, 3.5, w)
	circle(img, 8, 7, 2.5, Color.WHITE)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func get_product_icon(prod_id: String) -> Texture2D:
	var key := "prod_ic_%s" % prod_id
	if _cache.has(key):
		return _cache[key]
	var path := "res://picture/crops/prod_%s.png" % prod_id
	var loaded := _load_picture(path)
	if loaded != null:
		var tex := _tex(loaded)
		_cache[key] = tex
		return tex
	match prod_id:
		"trung_ga":
			var sp := springobject_icon(176)
			return sp if sp != null else egg_icon("f2e3b6")
		"sua_bo":
			return milk_icon()
		"long_cuu":
			return wool_icon()
		"thit_lon":
			var sp := springobject_icon(640)
			return sp if sp != null else meat_icon("e06d6d")
		"thit_ga":
			return meat_icon("d98a4a")
		_:
			for a in PoultryDB.ANIMALS:
				if str(a.product) == prod_id:
					if PoultryDB.is_meat(prod_id):
						return meat_icon(str(a.product_color))
					return egg_icon(str(a.product_color))
			return egg_icon("f2e3b6")


# Bong bóng sản phẩm thu hoạch (không chữ, chỉ có icon sản phẩm nổi bật bên trong)
static func get_harvest_bubble(prod_id: String) -> Texture2D:
	var key := "harvest_bubble_%s" % prod_id
	if _cache.has(key):
		return _cache[key]
	var img := _img(26, 26)
	# Bóng đổ mờ phía dưới
	circle(img, 13.0, 13.0, 11.5, Color(0.10, 0.08, 0.05, 0.45))
	# Viền ngoài nâu ấm sắc nét
	circle(img, 13.0, 11.0, 11.0, Color(0.24, 0.16, 0.08, 0.95))
	# Nền bong bóng trắng sáng
	circle(img, 13.0, 11.0, 9.5, Color(1.0, 1.0, 1.0, 0.95))
	# Điểm sáng bóng viền trên trái
	circle(img, 9.5, 7.5, 3.0, Color(1.0, 1.0, 1.0, 1.0))
	# Đuôi bong bóng chỉ xuống con vật / chuồng
	px(img, 11, 21, Color(0.24, 0.16, 0.08, 0.95))
	px(img, 12, 21, Color(1.0, 1.0, 1.0, 0.95))
	px(img, 13, 21, Color(1.0, 1.0, 1.0, 0.95))
	px(img, 14, 21, Color(0.24, 0.16, 0.08, 0.95))
	px(img, 12, 22, Color(0.24, 0.16, 0.08, 0.95))
	px(img, 13, 22, Color(1.0, 1.0, 1.0, 0.95))
	px(img, 13, 23, Color(0.24, 0.16, 0.08, 0.95))

	# Ghép icon sản phẩm 16x16 vào chính giữa bong bóng (tâm tại 13, 11)
	var prod_tex := get_product_icon(prod_id)
	if prod_tex != null:
		var prod_img: Image = prod_tex.get_image()
		if prod_img != null:
			var pw := mini(16, prod_img.get_width())
			var ph := mini(16, prod_img.get_height())
			var off_x := int(13 - pw / 2.0)
			var off_y := int(11 - ph / 2.0)
			img.blend_rect(prod_img, Rect2i(0, 0, pw, ph), Vector2i(off_x, off_y))

	var tex := _tex(img)
	_cache[key] = tex
	return tex


# Icon túi cám Stardew Valley (lấy từ springobjects sprite index 246 hoặc res://picture/feed_bag.png)
static func get_feed_icon() -> ImageTexture:
	var key := "feed_icon"
	if _cache.has(key):
		return _cache[key]
	var loaded := _load_picture("res://picture/feed_bag.png")
	if loaded != null:
		var tex := _tex(loaded)
		_cache[key] = tex
		return tex
	var sp := springobject_icon(246)
	if sp != null:
		_cache[key] = sp
		return sp
	var img := _img(16, 16)
	var bag_c := Color(0.76, 0.58, 0.38)
	var tie_c := Color(0.85, 0.25, 0.25)
	rect(img, 4, 5, 8, 9, bag_c)
	rect(img, 5, 3, 6, 2, tie_c)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


# Bong bóng suy nghĩ túi cám khi vật nuôi đói (chuẩn Stardew Valley)
static func get_feed_bubble() -> Texture2D:
	var key := "feed_bubble"
	if _cache.has(key):
		return _cache[key]
	var img := _img(26, 26)
	# Bóng đổ mờ phía dưới
	circle(img, 13.0, 13.0, 11.5, Color(0.10, 0.08, 0.05, 0.45))
	# Viền ngoài nâu ấm sắc nét
	circle(img, 13.0, 11.0, 11.0, Color(0.24, 0.16, 0.08, 0.95))
	# Nền bong bóng trắng sáng
	circle(img, 13.0, 11.0, 9.5, Color(1.0, 1.0, 1.0, 0.95))
	# Điểm sáng bóng viền trên trái
	circle(img, 9.5, 7.5, 3.0, Color(1.0, 1.0, 1.0, 1.0))
	# Đuôi bong bóng chỉ xuống con vật
	px(img, 11, 21, Color(0.24, 0.16, 0.08, 0.95))
	px(img, 12, 21, Color(1.0, 1.0, 1.0, 0.95))
	px(img, 13, 21, Color(1.0, 1.0, 1.0, 0.95))
	px(img, 14, 21, Color(0.24, 0.16, 0.08, 0.95))
	px(img, 12, 22, Color(0.24, 0.16, 0.08, 0.95))
	px(img, 13, 22, Color(1.0, 1.0, 1.0, 0.95))
	px(img, 13, 23, Color(0.24, 0.16, 0.08, 0.95))

	# Ghép icon túi cám 16x16 vào chính giữa bong bóng (tâm tại 13, 11)
	var feed_tex := get_feed_icon()
	if feed_tex != null:
		var feed_img: Image = feed_tex.get_image()
		if feed_img != null:
			var pw := mini(16, feed_img.get_width())
			var ph := mini(16, feed_img.get_height())
			var off_x := int(13 - pw / 2.0)
			var off_y := int(11 - ph / 2.0)
			img.blend_rect(feed_img, Rect2i(0, 0, pw, ph), Vector2i(off_x, off_y))

	var tex := _tex(img)
	_cache[key] = tex
	return tex



static func get_crate_fill_tex(id: String, type: String) -> ImageTexture:
	var key := "crate_fill_%s_%s" % [id, type]
	if _cache.has(key):
		return _cache[key]

	var canvas := _img(13, 8)

	if type == "crop" or type == "poultry":
		var path := "res://picture/crops/prod_%s.png" % id
		var loaded := _load_picture(path)
		if loaded != null:
			var min_x := loaded.get_width()
			var max_x := 0
			var min_y := loaded.get_height()
			var max_y := 0
			for y in loaded.get_height():
				for x in loaded.get_width():
					if loaded.get_pixel(x, y).a > 0.1:
						if x < min_x: min_x = x
						if x > max_x: max_x = x
						if y < min_y: min_y = y
						if y > max_y: max_y = y
			if min_x <= max_x and min_y <= max_y:
				var bw := max_x - min_x + 1
				var bh := max_y - min_y + 1
				var crop_img := Image.create(bw, bh, false, Image.FORMAT_RGBA8)
				crop_img.blit_rect(loaded, Rect2i(min_x, min_y, bw, bh), Vector2i.ZERO)
				var scale_f := minf(11.0 / float(bw), 7.5 / float(bh))
				var nw: int = maxi(2, int(round(float(bw) * scale_f)))
				var nh: int = maxi(2, int(round(float(bh) * scale_f)))
				crop_img.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
				var dx: int = (13 - nw) / 2
				var dy: int = (8 - nh) / 2
				canvas.blend_rect(crop_img, Rect2i(0, 0, nw, nh), Vector2i(dx, dy))
		else:
			var col := Color(0.88, 0.45, 0.15)
			for c in CropDB.CROPS:
				if str(c.id) == id:
					col = Color(str(c.color))
					break
			circle(canvas, 4, 4, 3, col)
			circle(canvas, 9, 4, 3, col.darkened(0.1))
			circle(canvas, 6.5, 3, 2.5, col.lightened(0.2))
			px(canvas, 6, 1, Color(0.3, 0.65, 0.25))
	elif type == "fish":
		var f_col := Color(0.4, 0.7, 0.9)
		for f in FishDB.FISH:
			if str(f.id) == id:
				f_col = Color(str(f.color))
				break
		ellipse(canvas, 6, 4, 4.5, 2.5, f_col)
		rect(canvas, 10, 3, 2, 3, f_col.darkened(0.3))
		px(canvas, 3, 3.5, Color(0.1, 0.1, 0.1))
	else:
		var p_col := Color(0.95, 0.88, 0.7)
		for a in PoultryDB.ANIMALS:
			if str(a.product) == id:
				p_col = Color(str(a.product_color))
				break
		ellipse(canvas, 4, 4.5, 2.2, 3.0, p_col.darkened(0.1))
		ellipse(canvas, 9, 4.5, 2.2, 3.0, p_col.darkened(0.15))
		ellipse(canvas, 6.5, 3.5, 2.2, 2.8, p_col.lightened(0.15))

	var tex := _tex(canvas)
	_cache[key] = tex
	return tex


static func prod_icon(crop: Dictionary) -> ImageTexture:
	if str(crop.get("id", "")) == "sau_bo":
		return get_tex("caterpillar")
	var key := "prod_icon_%s" % crop.id
	if _cache.has(key):
		return _cache[key]
	var path := "res://picture/crops/prod_%s.png" % crop.id
	var loaded := _load_picture(path)
	if loaded != null:
		var tex := _tex(loaded)
		_cache[key] = tex
		return tex
	var img := _img(16, 16)
	var accent := Color(str(crop.color))
	var leaf := Color(str(crop.leaf))
	circle(img, 8, 9, 4, accent)
	circle(img, 8, 9, 3, accent.lightened(0.1))
	px(img, 6, 8, Color(1, 1, 1, 0.55))
	px(img, 6, 9, Color(1, 1, 1, 0.35))
	px(img, 9, 4, leaf)
	px(img, 10, 3, leaf)
	px(img, 8, 5, leaf.darkened(0.2))
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func coin_icon() -> ImageTexture:
	var key := "coin_icon"
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var gold := Color(1.0, 0.82, 0.20)
	var gold_d := Color(0.72, 0.52, 0.10)
	var gold_l := Color(1.0, 0.94, 0.60)
	circle(img, 7.5, 7.5, 6.0, gold_d)
	circle(img, 7.5, 7.5, 5.0, gold)
	circle(img, 7.5, 7.5, 3.8, gold_d)
	circle(img, 7.5, 7.5, 2.8, gold)
	px(img, 5, 4, gold_l)
	px(img, 6, 4, gold_l)
	px(img, 4, 5, gold_l)
	px(img, 4, 6, gold_l)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func clock_icon() -> ImageTexture:
	var key := "clock_icon"
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var gold := Color(0.88, 0.72, 0.32)
	var face := Color(0.96, 0.95, 0.88)
	var hand := Color(0.20, 0.14, 0.08)
	rect(img, 7, 1, 2, 2, gold)
	circle(img, 7.5, 8.5, 5.8, gold)
	circle(img, 7.5, 8.5, 4.2, face)
	px(img, 7, 8, hand)
	px(img, 7, 6, hand)
	px(img, 7, 7, hand)
	px(img, 9, 8, hand)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func calendar_icon() -> ImageTexture:
	var key := "calendar_icon"
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var red := Color(0.82, 0.24, 0.20)
	var paper := Color(0.95, 0.94, 0.90)
	var paper_d := Color(0.75, 0.72, 0.65)
	var ink := Color(0.25, 0.20, 0.18)
	rect(img, 2, 3, 12, 11, paper_d)
	rect(img, 3, 4, 10, 9, paper)
	rect(img, 2, 3, 12, 3, red)
	px(img, 4, 1, Color(0.8, 0.8, 0.8))
	px(img, 4, 2, Color(0.8, 0.8, 0.8))
	px(img, 11, 1, Color(0.8, 0.8, 0.8))
	px(img, 11, 2, Color(0.8, 0.8, 0.8))
	# small calendar grid dots
	px(img, 5, 8, ink)
	px(img, 8, 8, ink)
	px(img, 10, 8, ink)
	px(img, 5, 11, ink)
	px(img, 8, 11, ink)
	px(img, 10, 11, ink)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func lock_icon() -> ImageTexture:
	var key := "lock_icon"
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var gold := Color(0.88, 0.72, 0.30)
	var gold_d := Color(0.55, 0.40, 0.15)
	for y in range(3, 8):
		px(img, 5, y, gold)
		px(img, 10, y, gold)
	rect(img, 6, 2, 4, 2, gold)
	rect(img, 3, 7, 10, 8, gold)
	rect(img, 4, 8, 8, 6, gold_d)
	px(img, 7, 10, Color(0.15, 0.10, 0.05))
	px(img, 8, 10, Color(0.15, 0.10, 0.05))
	px(img, 7, 11, Color(0.15, 0.10, 0.05))
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func star_icon() -> ImageTexture:
	var key := "star_icon"
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var star := Color(1.0, 0.82, 0.20)
	var glow := Color(1.0, 0.95, 0.55)
	circle(img, 7.5, 7.5, 4.0, star)
	rect(img, 7, 2, 2, 12, star)
	rect(img, 2, 7, 12, 2, star)
	px(img, 7, 7, glow)
	px(img, 8, 7, glow)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func backpack_icon() -> ImageTexture:
	var key := "backpack_icon"
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var leather := Color(0.72, 0.44, 0.22)
	var leather_d := Color(0.48, 0.26, 0.12)
	var metal := Color(0.95, 0.85, 0.40)
	# Thân ba lô da mộc
	rect(img, 3, 4, 10, 11, leather)
	rect(img, 4, 5, 8, 9, leather.lightened(0.12))
	# Nắp túi trên
	rect(img, 4, 2, 8, 4, leather_d)
	# Dây đai & khóa đồng
	rect(img, 5, 4, 2, 9, leather_d)
	rect(img, 9, 4, 2, 9, leather_d)
	px(img, 5, 7, metal)
	px(img, 10, 7, metal)
	# Túi con phía trước
	rect(img, 5, 9, 6, 4, leather_d)
	px(img, 7, 10, metal)
	px(img, 8, 10, metal)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func stamina_icon() -> ImageTexture:
	var key := "stamina_icon"
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var glow := Color(1.0, 0.88, 0.25)
	var edge := Color(0.75, 0.50, 0.08)
	var white := Color(1.0, 1.0, 0.85)
	# Tia sét vàng pixel 16x16
	rect(img, 8, 2, 3, 2, edge)
	rect(img, 7, 3, 3, 2, glow)
	rect(img, 6, 5, 4, 2, glow)
	rect(img, 4, 7, 9, 2, edge)
	rect(img, 5, 7, 7, 2, glow)
	rect(img, 7, 9, 4, 2, glow)
	rect(img, 6, 11, 3, 2, glow)
	rect(img, 5, 13, 2, 2, edge)
	px(img, 5, 14, glow)
	px(img, 8, 3, white)
	px(img, 7, 5, white)
	px(img, 7, 8, white)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func meat_icon(color_hex: String = "d98a4a") -> ImageTexture:
	var key := "meat_icon_%s" % color_hex
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var c := Color(color_hex)
	var bone := Color(0.95, 0.92, 0.85)
	var bone_d := Color(0.75, 0.70, 0.60)
	# Khúc xương nhô ra
	rect(img, 2, 11, 3, 3, bone_d)
	rect(img, 3, 10, 3, 3, bone)
	rect(img, 1, 12, 2, 2, bone)
	# Miếng thịt đùi gà tròn trịa
	circle(img, 9, 6, 5, c.darkened(0.25))
	circle(img, 9, 6, 4, c)
	circle(img, 8, 5, 2.5, c.lightened(0.2))
	px(img, 7, 4, Color(1, 1, 1, 0.6))
	var tex := _tex(img)
	_cache[key] = tex
	return tex


# ---------- HẦM MỎ & KHOÁNG SẢN (MINING SYSTEM) ----------

static func cave_entrance_tex() -> ImageTexture:
	var loaded := _load_picture("res://picture/cave_entrance.png")
	if loaded != null:
		return _tex(loaded)
	var key := "cave_entrance_tex"
	if _cache.has(key):
		return _cache[key]
	var img := _img(64, 56)
	var rock_dark := Color(0.18, 0.16, 0.15)
	var rock_mid := Color(0.35, 0.32, 0.28)
	var rock_light := Color(0.52, 0.48, 0.42)
	var rock_hl := Color(0.68, 0.64, 0.56)
	var wood_dark := Color(0.24, 0.15, 0.08)
	var wood_beam := Color(0.42, 0.28, 0.16)
	var wood_light := Color(0.58, 0.38, 0.22)
	var cave_void := Color(0.04, 0.03, 0.04)
	var lantern_glow := Color(1.0, 0.85, 0.35)

	# 1. Khối đá vách núi lớn bao quanh (x=4..60, y=0..55)
	circle(img, 32, 28, 30, rock_mid)
	circle(img, 20, 20, 18, rock_light)
	circle(img, 44, 20, 18, rock_mid)
	circle(img, 32, 10, 14, rock_light)
	rect(img, 6, 24, 52, 32, rock_mid)

	# Gờ đá nham nhở & đổ bóng vách núi
	for y in range(0, 56, 4):
		px(img, 6 + (y % 5), y, rock_dark)
		px(img, 57 - (y % 6), y, rock_dark)
		px(img, 15 + (y % 7), y, rock_hl)
		px(img, 48 - (y % 5), y, rock_dark)

	# 2. Vòm cửa hang tối sâu thẳm ở giữa (x=20..44, y=18..55)
	circle(img, 32, 28, 13, cave_void)
	rect(img, 19, 28, 26, 28, cave_void)
	rect(img, 22, 24, 20, 32, Color(0.02, 0.02, 0.02))

	# 3. Khung gỗ chống hầm mỏ (Timber support arch)
	# Cột trái
	rect(img, 16, 22, 4, 34, wood_beam)
	rect(img, 17, 22, 2, 34, wood_light)
	rect(img, 16, 22, 1, 34, wood_dark)
	# Cột phải
	rect(img, 44, 22, 4, 34, wood_beam)
	rect(img, 45, 22, 2, 34, wood_light)
	rect(img, 47, 22, 1, 34, wood_dark)
	# Xà ngang trên vòm
	rect(img, 14, 18, 36, 5, wood_beam)
	rect(img, 15, 19, 34, 3, wood_light)
	rect(img, 14, 18, 36, 1, wood_dark)
	rect(img, 14, 22, 36, 1, wood_dark)

	# 4. Đèn lồng treo giữa vòm phát sáng
	rect(img, 31, 23, 2, 3, wood_dark) # xích sắt
	rect(img, 30, 26, 4, 5, Color(0.2, 0.2, 0.2)) # khung đèn
	rect(img, 31, 27, 2, 3, lantern_glow) # ngọn lửa vàng
	px(img, 32, 28, Color(1.0, 1.0, 0.8))

	# 5. Rêu và bụi cỏ mọc trên gờ đá
	var moss := Color(0.35, 0.55, 0.25)
	rect(img, 12, 12, 8, 3, moss)
	rect(img, 44, 14, 9, 3, moss)
	rect(img, 26, 6, 12, 3, moss)

	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func mine_sign_tex() -> ImageTexture:
	var loaded := _load_picture("res://picture/mine_sign.png")
	if loaded != null:
		return _tex(loaded)
	var key := "mine_sign_tex"
	if _cache.has(key):
		return _cache[key]
	var img := _img(20, 24)
	var wood_d := Color(0.32, 0.18, 0.10)
	var wood_m := Color(0.55, 0.35, 0.18)
	var wood_l := Color(0.70, 0.48, 0.26)
	var gold := Color(0.95, 0.82, 0.30)
	# Cọc gỗ cắm đất
	rect(img, 9, 12, 3, 12, wood_d)
	rect(img, 10, 12, 1, 12, wood_m)
	# Bảng gỗ treo ngang
	rect(img, 2, 2, 16, 12, wood_d)
	rect(img, 3, 3, 14, 10, wood_m)
	rect(img, 4, 4, 12, 8, wood_l)
	# Biểu tượng Cúp đào mỏ khắc nổi trên bảng
	px(img, 7, 6, gold)
	px(img, 8, 7, gold)
	px(img, 9, 8, gold)
	px(img, 10, 9, wood_d)
	px(img, 11, 10, wood_d)
	# Đầu cúp
	rect(img, 6, 5, 3, 2, Color(0.85, 0.85, 0.90))
	px(img, 5, 6, Color(0.85, 0.85, 0.90))
	px(img, 9, 5, Color(0.85, 0.85, 0.90))
	var tex := _tex(img)
	_cache[key] = tex
	return tex

static func pickaxe_icon(tier: String = "basic") -> ImageTexture:
	var loaded := _load_picture("res://picture/pickaxe_%s.png" % tier)
	if loaded == null and tier == "basic":
		loaded = _load_picture("res://picture/pickaxe_icon.png")
	if loaded != null:
		return _tex(loaded)
	var key := "pickaxe_icon_%s" % tier
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	var head_col := Color(0.75, 0.75, 0.80)
	var head_hl := Color(0.92, 0.92, 0.96)
	var head_d := Color(0.45, 0.45, 0.50)
	match tier:
		"copper":
			head_col = Color(0.88, 0.50, 0.24)
			head_hl = Color(1.0, 0.70, 0.45)
			head_d = Color(0.58, 0.28, 0.10)
		"iron":
			head_col = Color(0.82, 0.86, 0.92)
			head_hl = Color(0.96, 0.98, 1.0)
			head_d = Color(0.50, 0.55, 0.62)
		"gold":
			head_col = Color(1.0, 0.84, 0.22)
			head_hl = Color(1.0, 0.96, 0.60)
			head_d = Color(0.70, 0.52, 0.08)

	var wood_d := Color(0.35, 0.20, 0.10)
	var wood_l := Color(0.65, 0.42, 0.22)

	# Cán gỗ chéo (x=2..12, y=3..13)
	for i in 9:
		px(img, 3 + i, 13 - i, wood_d)
		px(img, 4 + i, 13 - i, wood_l)

	# Đầu cúp cong sắc bén ở góc trên bên phải
	px(img, 13, 1, head_hl)
	px(img, 14, 2, head_col)
	px(img, 12, 2, head_hl)
	px(img, 13, 3, head_col)
	px(img, 11, 3, head_hl)
	px(img, 12, 4, head_col)
	px(img, 10, 4, head_col)
	px(img, 11, 5, head_d)
	px(img, 9, 5, head_col)
	px(img, 10, 6, head_d)
	px(img, 8, 6, head_col)
	px(img, 9, 7, head_d)
	px(img, 7, 7, head_d)
	px(img, 8, 8, head_d)
	px(img, 6, 8, head_d)

	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func mine_floor_tex() -> ImageTexture:
	var loaded := _load_picture("res://picture/mine/mine_floor.png")
	if loaded != null:
		return _tex(loaded)
	var key := "mine_floor_tex"
	if _cache.has(key):
		return _cache[key]
	var img := _img(32, 32)
	var base := Color(0.22, 0.20, 0.20)
	var dark := Color(0.16, 0.14, 0.14)
	var light := Color(0.28, 0.26, 0.25)
	rect(img, 0, 0, 32, 32, base)
	# Vân gạch đá tự nhiên & sỏi vụn
	for y in range(0, 32, 4):
		for x in range(0, 32, 4):
			if (x + y) % 6 == 0:
				px(img, x, y, light)
			elif (x * 3 + y) % 8 == 0:
				px(img, x, y, dark)
	rect(img, 0, 31, 32, 1, dark)
	rect(img, 31, 0, 1, 32, dark)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func mine_wall_tex() -> ImageTexture:
	var loaded := _load_picture("res://picture/mine/mine_wall.png")
	if loaded != null:
		return _tex(loaded)
	var key := "mine_wall_tex"
	if _cache.has(key):
		return _cache[key]
	var img := _img(32, 32)
	var w_dark := Color(0.10, 0.08, 0.08)
	var w_mid := Color(0.18, 0.15, 0.14)
	var w_light := Color(0.28, 0.24, 0.22)
	rect(img, 0, 0, 32, 32, w_mid)
	# Gờ đá tầng tầng lớp lớp
	for y in range(0, 32, 6):
		rect(img, 0, y, 32, 2, w_dark)
		rect(img, 0, y + 2, 32, 2, w_light)
	for x in range(0, 32, 8):
		rect(img, x, 0, 2, 32, w_dark)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func mine_ladder_tex(down: bool) -> ImageTexture:
	var key := "mine_ladder_%s" % ("down" if down else "up")
	if _cache.has(key):
		return _cache[key]
	var img := _img(24, 24)
	var wood_d := Color(0.28, 0.16, 0.08)
	var wood_m := Color(0.48, 0.30, 0.16)
	var wood_l := Color(0.68, 0.44, 0.24)
	if down:
		# Hố sâu xuống tầng dưới
		circle(img, 12, 12, 10, Color(0.04, 0.03, 0.04))
		# Thang gỗ đặt nghiêng vào hố
		rect(img, 7, 2, 2, 20, wood_m)
		rect(img, 15, 2, 2, 20, wood_m)
		for r in range(4, 21, 4):
			rect(img, 7, r, 10, 2, wood_l)
			rect(img, 7, r + 1, 10, 1, wood_d)
	else:
		# Thang leo ngược lên mặt đất
		rect(img, 6, 1, 3, 22, wood_d)
		rect(img, 15, 1, 3, 22, wood_d)
		rect(img, 7, 1, 1, 22, wood_l)
		rect(img, 16, 1, 1, 22, wood_l)
		for r in range(3, 22, 4):
			rect(img, 6, r, 12, 3, wood_m)
			rect(img, 7, r, 10, 1, wood_l)
			rect(img, 6, r + 2, 12, 1, wood_d)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func mine_rock_tex(rock_type: String) -> ImageTexture:
	var loaded := _load_picture("res://picture/mine/rock_%s.png" % rock_type)
	if loaded != null:
		return _tex(loaded)
	var key := "mine_rock_%s" % rock_type
	if _cache.has(key):
		return _cache[key]
	var img := _img(26, 24)
	var base_dark := Color(0.22, 0.20, 0.20)
	var base_mid := Color(0.42, 0.40, 0.38)
	var base_light := Color(0.60, 0.58, 0.54)
	var base_hl := Color(0.78, 0.76, 0.72)

	# 1. Bóng tròn dưới chân đá
	circle(img, 13, 20, 9, Color(0.08, 0.06, 0.06, 0.6))

	# 2. Khối đá 3D đa giác
	circle(img, 13, 12, 10, base_mid)
	rect(img, 6, 8, 14, 11, base_mid)
	rect(img, 5, 10, 16, 8, base_dark)
	rect(img, 7, 6, 11, 7, base_light)
	rect(img, 9, 5, 6, 4, base_hl)

	# Gờ đá góc cạnh
	px(img, 4, 12, base_dark)
	px(img, 21, 12, base_dark)
	px(img, 13, 3, base_hl)
	px(img, 14, 4, base_hl)

	# 3. Vết quặng / Tinh thể khoáng sản lấp lánh bên trong
	var ore_col := Color.TRANSPARENT
	var ore_hl := Color.TRANSPARENT
	match rock_type:
		"copper_ore":
			ore_col = Color(0.85, 0.45, 0.20)
			ore_hl = Color(1.0, 0.70, 0.40)
		"iron_ore":
			ore_col = Color(0.75, 0.82, 0.90)
			ore_hl = Color(0.95, 0.98, 1.0)
		"gold_ore":
			ore_col = Color(1.0, 0.80, 0.15)
			ore_hl = Color(1.0, 0.98, 0.60)
		"ruby":
			ore_col = Color(0.90, 0.15, 0.20)
			ore_hl = Color(1.0, 0.55, 0.60)
		"diamond":
			ore_col = Color(0.35, 0.85, 0.95)
			ore_hl = Color(0.80, 1.0, 1.0)
		"coal":
			ore_col = Color(0.12, 0.12, 0.14)
			ore_hl = Color(0.30, 0.30, 0.35)

	if ore_col != Color.TRANSPARENT:
		# Các cụm quặng sáng đính trên đá
		rect(img, 8, 9, 3, 3, ore_col)
		px(img, 9, 9, ore_hl)
		rect(img, 14, 7, 4, 3, ore_col)
		px(img, 15, 7, ore_hl)
		rect(img, 12, 13, 3, 3, ore_col)
		px(img, 13, 13, ore_hl)
		px(img, 17, 12, ore_col)
		px(img, 7, 14, ore_col)

	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func ore_item_icon(id: String) -> ImageTexture:
	var loaded := _load_picture("res://picture/item_%s.png" % id)
	if loaded != null:
		return _tex(loaded)
	var key := "ore_item_icon_%s" % id
	if _cache.has(key):
		return _cache[key]
	var img := _img(16, 16)
	match id:
		"stone":
			var d := Color(0.38, 0.36, 0.34)
			var m := Color(0.58, 0.56, 0.52)
			var l := Color(0.78, 0.76, 0.72)
			circle(img, 8, 8, 5, m)
			rect(img, 5, 6, 6, 6, m)
			rect(img, 7, 5, 4, 4, l)
			rect(img, 5, 9, 6, 3, d)
		"coal":
			var cd := Color(0.08, 0.08, 0.10)
			var cm := Color(0.20, 0.20, 0.24)
			var cl := Color(0.38, 0.38, 0.44)
			circle(img, 8, 8, 5, cm)
			rect(img, 6, 6, 5, 5, cm)
			rect(img, 7, 5, 3, 3, cl)
			rect(img, 5, 9, 6, 3, cd)
		"copper_ore":
			var cod := Color(0.55, 0.26, 0.10)
			var com := Color(0.85, 0.48, 0.22)
			var col := Color(1.0, 0.72, 0.45)
			circle(img, 8, 8, 5, com)
			rect(img, 6, 6, 5, 5, com)
			rect(img, 7, 5, 3, 3, col)
			rect(img, 5, 9, 6, 3, cod)
		"iron_ore":
			var iod := Color(0.42, 0.46, 0.52)
			var iom := Color(0.72, 0.78, 0.86)
			var iol := Color(0.92, 0.95, 1.0)
			circle(img, 8, 8, 5, iom)
			rect(img, 6, 6, 5, 5, iom)
			rect(img, 7, 5, 3, 3, iol)
			rect(img, 5, 9, 6, 3, iod)
		"gold_ore":
			var god := Color(0.65, 0.48, 0.08)
			var gom := Color(0.98, 0.80, 0.18)
			var gol := Color(1.0, 0.96, 0.55)
			circle(img, 8, 8, 5, gom)
			rect(img, 6, 6, 5, 5, gom)
			rect(img, 7, 5, 3, 3, gol)
			rect(img, 5, 9, 6, 3, god)
		"ruby":
			var rd := Color(0.60, 0.08, 0.12)
			var rm := Color(0.92, 0.18, 0.24)
			var rl := Color(1.0, 0.60, 0.65)
			# Hình thoi viên hồng ngọc
			rect(img, 7, 3, 2, 10, rm)
			rect(img, 5, 5, 6, 6, rm)
			rect(img, 4, 7, 8, 2, rm)
			px(img, 7, 5, rl)
			px(img, 8, 5, rl)
			px(img, 7, 10, rd)
		"diamond":
			var dd := Color(0.18, 0.60, 0.75)
			var dm := Color(0.45, 0.85, 0.96)
			var dl := Color(0.90, 1.0, 1.0)
			# Viên kim cương giác cắt 8 cạnh
			rect(img, 5, 4, 6, 3, dl)
			rect(img, 4, 7, 8, 2, dm)
			rect(img, 5, 9, 6, 2, dm)
			rect(img, 6, 11, 4, 2, dd)
			px(img, 7, 13, dd)
			px(img, 8, 13, dd)
			px(img, 6, 5, Color.WHITE)
			px(img, 7, 5, Color.WHITE)
		_:
			circle(img, 8, 8, 5, Color(0.6, 0.6, 0.6))
	var tex := _tex(img)
	_cache[key] = tex
	return tex
