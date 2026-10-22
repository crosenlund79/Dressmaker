class_name GarmentDefinition
extends Resource
## A garment template: a silhouette authored in a normalized local frame.
##
## Local frames (x = across, y = along the garment):
##   bodice: x = u (+-1 at the body edge), y = v (0 shoulder line, 1 waist)
##   skirt:  x = u (+-1 at the body edge), y = v (0 waist, 1 ankle)
##   sleeve: x = s (+1 outer arm edge, -1 inner edge), y = t (0 shoulder, 1 wrist)
## Sleeves are authored for the screen-right arm and mirrored automatically.

@export var id: String = ""
@export var display_name: String = ""
@export_enum("bodice", "skirt", "sleeve") var category: String = "bodice"
## Closed outline polygon in the local frame.
@export var outline: PackedVector2Array = PackedVector2Array()
## Decorative trim lines (seams, lacing, ruffles), drawn in the trim color.
@export var detail_lines: Array[PackedVector2Array] = []
## Buttons / pearls, drawn in the trim color.
@export var detail_dots: PackedVector2Array = PackedVector2Array()
@export var default_fabric: String = "cotton"
@export var default_color: Color = Color(0.7, 0.2, 0.3)
@export var default_secondary: Color = Color(0.95, 0.9, 0.8)
@export var default_trim: Color = Color(0.85, 0.72, 0.4)
@export var tags: PackedStringArray = PackedStringArray()


func get_local_bounds() -> Rect2:
	if outline.is_empty():
		return Rect2(-1, 0, 2, 1)
	var r := Rect2(outline[0], Vector2.ZERO)
	for p in outline:
		r = r.expand(p)
	return r
