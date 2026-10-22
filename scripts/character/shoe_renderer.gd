class_name ShoeRenderer
extends Node2D
## Draws the selected shoe pair. Each shoe region has its own color.
## This node sits on the floor (the body above it is lifted by the heel height).

var body: BodyDefinition
var definition: ShoeDefinition
var colors: PackedColorArray = PackedColorArray()


func _draw() -> void:
	if body == null or definition == null:
		return
	var cols := colors
	if cols.size() < definition.region_names.size():
		cols = definition.region_defaults
	var f := body.foot_scale
	for side in [-1, 1]:
		var xf := Transform2D(Vector2(side * f, 0), Vector2(0, f), Vector2(side * body.ankle_x, 0))
		ShapeDrawer.draw_shapes(self, definition.shapes, cols, xf, f)


## Rough bounds for picking (model space, relative to this node).
func get_bounds() -> Rect2:
	if body == null or definition == null:
		return Rect2()
	var r := Rect2(Vector2(-body.ankle_x - 45, -60 - definition.heel_lift), Vector2(body.ankle_x * 2 + 90, 62 + definition.heel_lift))
	return r
