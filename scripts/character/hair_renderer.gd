class_name HairRenderer
extends Node2D
## Draws either the back or the front layer of a hairstyle, in head-local units.

var body: BodyDefinition
var definition: HairDefinition
var colors: PackedColorArray = PackedColorArray()
var front: bool = true


func _xf() -> Transform2D:
	var r := body.head_radius
	return Transform2D(Vector2(r, 0), Vector2(0, r), body.head_center())


func _draw() -> void:
	if body == null or definition == null:
		return
	var shapes := definition.front_shapes if front else definition.back_shapes
	ShapeDrawer.draw_shapes(self, shapes, colors, _xf(), body.head_radius)


func contains_point(p: Vector2) -> bool:
	if body == null or definition == null:
		return false
	var local := _xf().affine_inverse() * p
	for s in definition.front_shapes + definition.back_shapes:
		if s.get("k") == "poly" and Geometry2D.is_point_in_polygon(local, s["p"]):
			return true
		if s.get("k") == "circle" and local.distance_to(s["p"][0]) <= float(s.get("rad", 0.1)):
			return true
	return false
