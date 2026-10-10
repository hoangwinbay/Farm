extends SceneTree

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	print("=== KIỂM THỬ DI CHUYỂN HÒM THƯ LÊN BÃI CỎ VÀ BỎ THÔNG BÁO ===")

	var WorldBuilderScript = load("res://scripts/world_builder.gd")
	assert(WorldBuilderScript.MAILBOX_POS == Vector2(704, 440), "MAILBOX_POS phải được chuyển lên bãi cỏ tại vị trí (704, 440)!")
	print("1. MAILBOX_POS = Vector2(704, 440) (nằm trọn trên bãi cỏ, không đè lên đường đất) chính xác!")

	# Kiểm tra cấu trúc Node
	var dummy_main := Node2D.new()
	root.add_child(dummy_main)

	var wb = WorldBuilderScript.new()
	wb.setup(dummy_main)
	var world := Node2D.new()
	wb.world = world
	dummy_main.add_child(world)

	wb.build_mailbox()

	# Kiểm tra mailbox body trong world
	var mb_body: StaticBody2D = null
	for c in world.get_children():
		if c is StaticBody2D and c.position == WorldBuilderScript.MAILBOX_POS:
			mb_body = c
			break

	assert(mb_body != null, "Phải tìm thấy mailbox StaticBody2D tại tọa độ (704, 440)!")
	print("2. Mailbox StaticBody2D được đặt đúng tọa độ (704, 440) trong World!")

	# Kiểm tra loại bỏ hoàn toàn thông báo
	assert(wb.mailbox_badge == null, "Thông báo hòm thư phải được loại bỏ hoàn toàn (mailbox_badge == null)!")
	wb.update_mailbox_badge() # Đảm bảo hàm gọi an toàn không crash
	print("3. Đã loại bỏ hoàn toàn thông báo trên hòm thư, giao diện sạch đẹp tự nhiên!")

	print("\n=== TOÀN BỘ KIỂM THỬ HÒM THƯ THÀNH CÔNG 100%! ===")
	quit(0)
