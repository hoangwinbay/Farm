extends StaticBody2D
# NPC đứng tại các địa điểm trong làng (Bác Tư, Cô Tư, Chú Hai, Bác Trưởng Thôn).

const TextureGen := preload("res://scripts/texture_gen.gd")

var npc_name := "Bác Tư"
var spr: Sprite2D
var _quest_indicator: Sprite2D


func _ready() -> void:
	var ntype := "bac_tu"
	if npc_name.contains("Cô Tư"):
		ntype = "co_tu"
	elif npc_name.contains("Chú Hai"):
		ntype = "chu_hai"
	elif npc_name.contains("Trưởng Thôn") or npc_name.contains("Trưởng Làng"):
		ntype = "truong_thon"

	spr = Sprite2D.new()
	spr.texture = TextureGen.npc_tex(ntype)
	spr.scale = Vector2(1.8, 1.8)
	spr.offset = Vector2(0, -10)
	add_child(spr)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	col.position = Vector2(0, -5)
	add_child(col)

	# Hiệu ứng thở nhẹ nhàng, nhấp nháy tự nhiên
	var tw := spr.create_tween().set_loops()
	tw.tween_property(spr, "scale:y", 1.84, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(spr, "scale:y", 1.8, 1.2).set_trans(Tween.TRANS_SINE)

	# Biểu tượng thông báo nhiệm vụ lơ lửng trên đầu (! hoặc ?)
	_quest_indicator = Sprite2D.new()
	_quest_indicator.visible = false
	_quest_indicator.position = Vector2(0, -32)
	add_child(_quest_indicator)

	var qtw := _quest_indicator.create_tween().set_loops()
	qtw.tween_property(_quest_indicator, "position:y", -35.0, 0.6).set_trans(Tween.TRANS_SINE)
	qtw.tween_property(_quest_indicator, "position:y", -30.0, 0.6).set_trans(Tween.TRANS_SINE)


func set_quest_indicator(type: String) -> void:
	if _quest_indicator == null:
		return
	if type == "":
		_quest_indicator.visible = false
	else:
		_quest_indicator.texture = TextureGen.quest_mark_tex(type)
		_quest_indicator.visible = true


