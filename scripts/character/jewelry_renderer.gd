class_name JewelryRenderer
extends Node2D
## Draws one jewelry category at its body anchors.

var body: BodyDefinition
var category: String = "earrings"
var definition: JewelryDefinition
var metal: Color = Color(0.85, 0.7, 0.35)
var gem: Color = Color.WHITE
var crown_height: float = 0.1  # from the current hairstyle (tiara seating)


func _draw() -> void:
	if body == null or definition == null:
		return
	var cols := PackedColorArray([metal, gem])
	for xf in anchor_transforms():
		ShapeDrawer.draw_shapes(self, definition.shapes, cols, xf, xf.get_scale().y, 0.9)


func anchor_transforms() -> Array[Transform2D]:
	var out: Array[Transform2D] = []
	var head_scale := body.head_radius / 36.0
	match category:
		"earrings":
			for side in [-1, 1]:
				var p := body.ear_point(side) + Vector2(0, body.head_radius * 0.06)
				out.append(Transform2D(Vector2(side * head_scale, 0), Vector2(0, head_scale), p))
		"necklace":
			var s := (body.neck_hw / 15.0 + body.shoulder_hw / 70.0) * 0.5
			out.append(Transform2D(Vector2(s, 0), Vector2(0, s), body.neck_base() + Vector2(0, 2)))
		"bracelet":
			var s2 := body.arm_hw_wrist / 7.5
			for side in [-1, 1]:
				var dir := body.arm_direction(side)
				var across: Vector2 = Vector2(dir.y, -dir.x) * side  # +x points away from the body on both sides
				var p2 := body.arm_to_model(Vector2(0, 0.93), side)
				out.append(Transform2D(across * s2, dir * s2, p2))
		"anklet":
			var s3 := body.leg_hw_ankle / 9.0
			for side in [-1, 1]:
				out.append(Transform2D(Vector2(side * s3, 0), Vector2(0, s3), body.ankle_point(side) + Vector2(0, -6)))
		"tiara":
			var p4 := body.head_center() + Vector2(0, -body.head_radius * (1.15 + crown_height) + body.head_radius * 0.12)
			out.append(Transform2D(Vector2(head_scale, 0), Vector2(0, head_scale), p4))
	return out
