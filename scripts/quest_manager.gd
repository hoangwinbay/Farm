extends Node
# Quản lý tiến trình nhiệm vụ của người chơi theo THỜI GIAN THỰC (Real-Time):
# - Nhiệm vụ Ngày: Tự động làm mới đúng 00:00 hàng ngày theo giờ hệ thống.
# - Nhiệm vụ Tuần: Tự động làm mới đúng 00:00 thứ Hai hàng tuần.
# - Nhiệm vụ Tổng (Thành Tựu): Mở trọn đời, theo dõi mọi hoạt động và mốc tiền tài sản.

const QuestDB := preload("res://scripts/quest_db.gd")

signal quest_progressed(quest_id: String, cur_progress: int, target_count: int)
signal quest_completed(quest_dict: Dictionary)
signal quest_claimed(quest_dict: Dictionary)
signal quests_refreshed

var daily_quests: Array[Dictionary] = []
var weekly_quests: Array[Dictionary] = []
var lifetime_quests: Array[Dictionary] = []

var last_assigned_real_day: int = -1
var last_assigned_real_week: int = -1

var main_node: Node2D = null
var _check_timer: float = 0.0


# ----------------- HÀM TIỆN ÍCH THỜI GIAN THỰC -----------------

# Mã định danh ngày thực (YYYYMMDD) làm seed ngẫu nhiên nhiệm vụ
static func get_real_day_id() -> int:
	var dt := Time.get_date_dict_from_system()
	return int(dt.year) * 10000 + int(dt.month) * 100 + int(dt.day)


# Mã định danh tuần thực tính từ Unix Epoch (bắt đầu từ Thứ Hai)
static func get_real_week_id() -> int:
	var unix_now := int(Time.get_unix_time_from_system())
	var tz_bias := int(Time.get_time_zone_from_system().bias) * 60
	var local_unix := unix_now + tz_bias
	# Offset 259200s (3 ngày) để khớp mốc Thứ Hai
	var week_index := int(floor(float(local_unix + 259200) / (7.0 * 86400.0)))
	return week_index


# Số giây còn lại cho đến 00:00 ngày tiếp theo
static func get_seconds_until_next_day() -> int:
	var dt := Time.get_time_dict_from_system()
	var sec_passed := int(dt.hour) * 3600 + int(dt.minute) * 60 + int(dt.second)
	return maxi(0, 86400 - sec_passed)


# Số giây còn lại cho đến 00:00 thứ Hai tuần sau
static func get_seconds_until_next_week() -> int:
	var dt := Time.get_datetime_dict_from_system()
	var w: int = int(dt.weekday) # 0=CN, 1=T2, 2=T3 ... 6=T7
	var days_left := 0
	if w == 0:
		days_left = 0
	elif w == 1:
		days_left = 6
	else:
		days_left = 7 - w + 1
	var sec_today_left := get_seconds_until_next_day()
	return days_left * 86400 + sec_today_left


# Chuỗi đếm ngược thời gian làm mới nhiệm vụ ngày
static func format_countdown_daily() -> String:
	var s := get_seconds_until_next_day()
	var h := s / 3600
	var m := (s % 3600) / 60
	var sec := s % 60
	return "%02d:%02d:%02d" % [h, m, sec]


# Chuỗi đếm ngược thời gian làm mới nhiệm vụ tuần
static func format_countdown_weekly() -> String:
	var s := get_seconds_until_next_week()
	var d := s / 86400
	var h := (s % 86400) / 3600
	var m := (s % 3600) / 60
	var sec := s % 60
	if d > 0:
		return "%d ngày %02d:%02d:%02d" % [d, h, m, sec]
	return "%02d:%02d:%02d" % [h, m, sec]


# ----------------- KHỞI TẠO & VÒNG LẶP -----------------

func setup(main_ref: Node2D) -> void:
	main_node = main_ref
	var cur_day := get_real_day_id()
	var cur_week := get_real_week_id()

	if daily_quests.is_empty():
		refresh_daily_quests(cur_day)
	if weekly_quests.is_empty():
		refresh_weekly_quests(cur_week)
	if lifetime_quests.is_empty():
		lifetime_quests = QuestDB.init_lifetime_quests()


func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer >= 1.0:
		_check_timer = 0.0
		check_real_time_refresh()


func check_real_time_refresh() -> void:
	var cur_day := get_real_day_id()
	if cur_day != last_assigned_real_day:
		refresh_daily_quests(cur_day)

	var cur_week := get_real_week_id()
	if cur_week != last_assigned_real_week:
		refresh_weekly_quests(cur_week)


func refresh_daily_quests(day_seed: int) -> void:
	last_assigned_real_day = day_seed
	daily_quests = QuestDB.generate_daily_quests(day_seed)
	quests_refreshed.emit()


func refresh_weekly_quests(week_seed: int) -> void:
	last_assigned_real_week = week_seed
	weekly_quests = QuestDB.generate_weekly_quests(week_seed)
	quests_refreshed.emit()


# ----------------- TIẾN ĐỘ NHIỆM VỤ -----------------

func advance_progress(event_type: String, target_id: String, amount: int = 1) -> void:
	var any_completed := false

	# 1. Duyệt nhiệm vụ ngày
	for q in daily_quests:
		if bool(q.get("completed", false)):
			continue
		if _matches_quest(q, event_type, target_id):
			_add_progress(q, amount)
			if bool(q.get("completed", false)):
				any_completed = true
				quest_completed.emit(q)

	# 2. Duyệt nhiệm vụ tuần
	for q in weekly_quests:
		if bool(q.get("completed", false)):
			continue
		if _matches_quest(q, event_type, target_id):
			_add_progress(q, amount)
			if bool(q.get("completed", false)):
				any_completed = true
				quest_completed.emit(q)

	# 3. Duyệt nhiệm vụ tổng
	for q in lifetime_quests:
		if bool(q.get("completed", false)):
			continue
		if _matches_quest(q, event_type, target_id):
			_add_progress(q, amount)
			if bool(q.get("completed", false)):
				any_completed = true
				quest_completed.emit(q)


func update_money_milestones(current_money: int) -> void:
	for q in lifetime_quests:
		if str(q.get("type", "")) == "money_earn":
			var tgt: int = int(q.get("target_count", 1000))
			var cur_p: int = mini(current_money, tgt)
			if cur_p != int(q.get("progress", 0)):
				q["progress"] = cur_p
				if cur_p >= tgt and not bool(q.get("completed", false)):
					q["completed"] = true
					quest_completed.emit(q)
				quest_progressed.emit(str(q.get("id", "")), cur_p, tgt)


func _matches_quest(q: Dictionary, event_type: String, target_id: String) -> bool:
	if str(q.get("type", "")) != event_type:
		return false
	var q_target: String = str(q.get("target_id", "any"))
	if q_target == "any" or q_target == "":
		return true
	return q_target == target_id


func _add_progress(q: Dictionary, amount: int) -> void:
	var cur: int = int(q.get("progress", 0)) + amount
	var target: int = int(q.get("target_count", 1))
	q["progress"] = mini(cur, target)
	if int(q["progress"]) >= target:
		q["completed"] = true
	quest_progressed.emit(str(q.get("id", "")), int(q["progress"]), target)


# ----------------- NHẬN THƯỞNG -----------------

func claim_reward(quest_id: String) -> Dictionary:
	var quest: Dictionary = {}
	var category := ""

	# Tìm trong nhiệm vụ ngày
	for q in daily_quests:
		if str(q.get("id", "")) == quest_id:
			quest = q
			category = "daily"
			break

	# Tìm trong nhiệm vụ tuần
	if quest.is_empty():
		for q in weekly_quests:
			if str(q.get("id", "")) == quest_id:
				quest = q
				category = "weekly"
				break

	# Tìm trong nhiệm vụ tổng
	if quest.is_empty():
		for q in lifetime_quests:
			if str(q.get("id", "")) == quest_id:
				quest = q
				category = "lifetime"
				break

	if quest.is_empty() or not bool(quest.get("completed", false)) or bool(quest.get("claimed", false)):
		return {}

	quest["claimed"] = true

	# Trao thưởng vàng
	var coins: int = int(quest.get("reward_coins", 0))
	if coins > 0:
		GameState.add_money(coins)

	# Trao thưởng nguyên liệu (đối với nhiệm vụ ngày & tuần)
	var item_id: String = str(quest.get("reward_item_id", ""))
	var item_type: String = str(quest.get("reward_item_type", "crop"))
	var item_count: int = int(quest.get("reward_item_count", 0))

	if item_id != "" and item_count > 0:
		match item_type:
			"ore":
				Inventory.add_ore(item_id, item_count)
			"fish":
				Inventory.add_fish(item_id, item_count)
			"seed":
				Inventory.add_seed(item_id, item_count)
			_: # crop hoặc produce
				Inventory.add_produce(item_id, item_count)

	quest_claimed.emit(quest)
	return quest


func has_unclaimed_rewards() -> bool:
	for q in daily_quests:
		if bool(q.get("completed", false)) and not bool(q.get("claimed", false)):
			return true
	for q in weekly_quests:
		if bool(q.get("completed", false)) and not bool(q.get("claimed", false)):
			return true
	for q in lifetime_quests:
		if bool(q.get("completed", false)) and not bool(q.get("claimed", false)):
			return true
	return false


func has_active_quests() -> bool:
	for q in daily_quests:
		if not bool(q.get("completed", false)):
			return true
	for q in weekly_quests:
		if not bool(q.get("completed", false)):
			return true
	return false


func get_summary_quests() -> Array[Dictionary]:
	var list: Array[Dictionary] = []

	# 1. Các nhiệm vụ đã xong chưa nhận thưởng
	for q in daily_quests:
		if bool(q.get("completed", false)) and not bool(q.get("claimed", false)):
			list.append(q)
	for q in weekly_quests:
		if bool(q.get("completed", false)) and not bool(q.get("claimed", false)):
			list.append(q)
	for q in lifetime_quests:
		if bool(q.get("completed", false)) and not bool(q.get("claimed", false)):
			list.append(q)

	# 2. Các nhiệm vụ ngày đang làm
	for q in daily_quests:
		if not bool(q.get("completed", false)) and not list.has(q):
			list.append(q)

	# 3. Các nhiệm vụ tuần đang làm
	for q in weekly_quests:
		if not bool(q.get("completed", false)) and not list.has(q):
			list.append(q)

	# 4. Nhiệm vụ tổng đang làm
	for q in lifetime_quests:
		if not bool(q.get("completed", false)) and not list.has(q):
			list.append(q)
		if list.size() >= 4:
			break

	return list.slice(0, 4)


# ----------------- LƯU & TẢI TIẾN TRÌNH -----------------

func get_save_data() -> Dictionary:
	return {
		"last_real_day": last_assigned_real_day,
		"last_real_week": last_assigned_real_week,
		"daily": daily_quests.duplicate(true),
		"weekly": weekly_quests.duplicate(true),
		"lifetime": lifetime_quests.duplicate(true)
	}


func load_save_data(d: Dictionary) -> void:
	if d.is_empty():
		return

	var cur_day := get_real_day_id()
	var cur_week := get_real_week_id()

	last_assigned_real_day = int(d.get("last_real_day", cur_day))
	last_assigned_real_week = int(d.get("last_real_week", cur_week))

	# Kiểm tra ngày thực: nếu cùng ngày thì khôi phục tiến trình, nếu sang ngày mới thì làm mới
	if last_assigned_real_day == cur_day:
		var d_arr = d.get("daily", [])
		if typeof(d_arr) == TYPE_ARRAY and d_arr.size() > 0:
			daily_quests.clear()
			for item in d_arr:
				if typeof(item) == TYPE_DICTIONARY:
					daily_quests.append(item.duplicate(true))
		else:
			refresh_daily_quests(cur_day)
	else:
		refresh_daily_quests(cur_day)

	# Kiểm tra tuần thực
	if last_assigned_real_week == cur_week:
		var w_arr = d.get("weekly", [])
		if typeof(w_arr) == TYPE_ARRAY and w_arr.size() > 0:
			weekly_quests.clear()
			for item in w_arr:
				if typeof(item) == TYPE_DICTIONARY:
					weekly_quests.append(item.duplicate(true))
		else:
			refresh_weekly_quests(cur_week)
	else:
		refresh_weekly_quests(cur_week)

	# Khôi phục thành tựu trọn đời
	var lt_arr = d.get("lifetime", [])
	if typeof(lt_arr) == TYPE_ARRAY and lt_arr.size() > 0:
		lifetime_quests.clear()
		for item in lt_arr:
			if typeof(item) == TYPE_DICTIONARY:
				lifetime_quests.append(item.duplicate(true))
	else:
		lifetime_quests = QuestDB.init_lifetime_quests()

	quests_refreshed.emit()
