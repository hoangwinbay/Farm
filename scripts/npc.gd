extends StaticBody2D
# NPC đứng tại quầy hàng (Bác Tư, Cô Tư, Chú Hai).

const TextureGen := preload("res://scripts/texture_gen.gd")

var npc_name := "Bác Tư"
var spr: Sprite2D


func _ready() -> void:
	var ntype := "bac_tu"
	if npc_name.contains("Cô Tư"):
		ntype = "co_tu"
	elif npc_name.contains("Chú Hai"):
		ntype = "chu_hai"

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

