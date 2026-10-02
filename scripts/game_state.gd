extends Node
# Trạng thái chung: tiền, ngày, giờ trong ngày, cây đã mở khóa.

signal money_changed(value: int)
signal crops_changed

const CropDB := preload("res://scripts/crop_db.gd")

const MINUTES_PER_SEC := 1200.0 / 900.0  # 1 ngày = 20h trong game = 15 phút thật
const DAY_START := 420          # 7:00 sáng
const COLLAPSE_MIN := 120       # 2:00 sáng — chưa ngủ thì gục ngã
const MINUTES_PER_DAY := 1440

var money := 100
var day := 1
var unlocked: Array = ["rice"]
var clock: float = DAY_START  # phải là float — kiểu int sẽ làm đồng hồ không chạy


func reset_new_game() -> void:
	money = 100
	day = 1
	clock = DAY_START
	unlocked = ["rice"]
	money_changed.emit(money)
	crops_changed.emit()


func add_money(v: int) -> void:
	money += v
	money_changed.emit(money)


func try_spend(v: int) -> bool:
	if money < v:
		return false
	money -= v
	money_changed.emit(money)
	return true


func has_crop(id: String) -> bool:
	return unlocked.has(id)


func next_locked() -> Dictionary:
	return CropDB.next_locked(unlocked)


func unlock_next() -> bool:
	var c := next_locked()
	if c.is_empty():
		return false
	if money < int(c.unlock_cost):
		return false
	money -= int(c.unlock_cost)
	unlocked.append(str(c.id))
	money_changed.emit(money)
	crops_changed.emit()
	return true


func tick(delta: float) -> void:
	clock += delta * MINUTES_PER_SEC
	if clock >= MINUTES_PER_DAY:
		# 0h đêm: sang ngày mới tự động
		clock -= MINUTES_PER_DAY
		day += 1


# Ngủ: nếu ngủ trước 6h sáng thì dậy ngay 6h cùng ngày, sau 6h thì dậy 6h hôm sau.
func sleep_to_morning() -> void:
	if clock >= DAY_START:
		day += 1
	clock = DAY_START


func clock_text() -> String:
	return "%02d:%02d" % [int(clock) / 60, int(clock) % 60]
