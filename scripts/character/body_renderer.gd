class_name BodyRenderer
extends Node2D
## Draws one layer of the procedural model body. Several instances are stacked by
## CharacterPresentation so clothing can sit between body parts.

enum Part { LEGS, TORSO, HANDS, HEAD }

const UNDERWEAR := Color(0.97, 0.94, 0.88)

var part: Part = Part.TORSO
var body: BodyDefinition
var skin: Color = Color(0.96, 0.82, 0.72)
var show_feet: bool = true
var blink: bool = false
## Conforms covered body parts to the garments (set by CharacterPresentation).
var fitter: BodyFitter


func setup(p: Part) -> BodyRenderer:
	part = p
	name = "Body" + str(Part.keys()[p]).capitalize()
	return self


func _draw() -> void:
	if body == null:
		return
	match part:
		Part.LEGS:
			_draw_legs()
		Part.TORSO:
			_draw_torso()
		Part.HANDS:
			_draw_hands()
		Part.HEAD:
			_draw_head()


func _outline() -> Color:
	return skin.darkened(0.42)


## Draws a body polygon conformed to the clothes covering it. The polygon is
## triangulated in its rest pose, so conforming can never break the fill.
func _part(part_name: String, kind: String, rest: PackedVector2Array, fill: Color, edge: Color) -> void:
	var dense := _densify(rest, 7.0)
	var pts := fitter.deform(part_name, kind, dense) if fitter and kind != "" else dense
	var tris := ShapeDrawer._triangulate(dense)
	if not tris.is_empty():
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), tris, pts, PackedColorArray([fill]))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, edge, 1.2, true)


func _line(part_name: String, kind: String, rest: PackedVector2Array, col: Color, width: float) -> void:
	var pts := fitter.deform(part_name, kind, rest) if fitter else rest
	draw_polyline(pts, col, width, true)


static func _densify(pts: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for i in range(n):
		var a := pts[i]
		var b := pts[(i + 1) % n]
		var steps := maxi(1, ceili(a.distance_to(b) / step))
		for k in range(steps):
			out.append(a.lerp(b, float(k) / steps))
	return out


func _draw_legs() -> void:
	for side in [-1, 1]:
		var left_edge := PackedVector2Array()
		var right_edge := PackedVector2Array()
		var top := body.hip_y - 6.0
		var hip_x: float = side * body.hip_hw * 0.42
		for i in range(25):
			var t := i / 24.0
			var y := lerpf(top, body.ankle_y + 2.0, t)
			var cx := lerpf(hip_x, side * body.ankle_x, smoothstep(0.0, 1.0, t))
			var hw := body.leg_hw(y)
			left_edge.append(Vector2(cx - hw, y))
			right_edge.append(Vector2(cx + hw, y))
		right_edge.reverse()
		var leg := left_edge
		leg.append_array(right_edge)
		_part("leg%d" % side, "lower", leg, skin, _outline())
		if show_feet:
			var a := body.ankle_point(side)
			var f := body.foot_scale
			var foot := PackedVector2Array()
			for p in [Vector2(-8, -4), Vector2(-9, 24), Vector2(8, 26), Vector2(30, 26), Vector2(31, 21), Vector2(12, 12), Vector2(8, -4)]:
				foot.append(a + Vector2(p.x * side * f, p.y * f))
			ShapeDrawer.fill_polygon(self, foot, skin, _outline())
	# Bloomers (modest underlayer over the upper thighs).
	var bl_bottom := body.waist_y + body.skirt_length() * 0.3
	var bloomers := PackedVector2Array()
	bloomers.append(Vector2(-body.waist_hw * 0.98, body.waist_y + 2))
	bloomers.append(Vector2(body.waist_hw * 0.98, body.waist_y + 2))
	bloomers.append(Vector2(body.hip_hw * 0.98, body.hip_y))
	for k in range(7):
		var x := lerpf(body.hip_hw * 0.92, body.hip_hw * 0.06, k / 6.0)
		bloomers.append(Vector2(x, bl_bottom + (4.0 if k % 2 == 0 else 0.0)))
	bloomers.append(Vector2(0, body.hip_y + 26))
	for k in range(7):
		var x2 := lerpf(-body.hip_hw * 0.06, -body.hip_hw * 0.92, k / 6.0)
		bloomers.append(Vector2(x2, bl_bottom + (4.0 if k % 2 == 0 else 0.0)))
	bloomers.append(Vector2(-body.hip_hw * 0.98, body.hip_y))
	_part("bloomers", "lower", bloomers, UNDERWEAR, UNDERWEAR.darkened(0.35))


func _torso_outline() -> PackedVector2Array:
	return _torso_outline_for(body)


func _torso_outline_for(b: BodyDefinition) -> PackedVector2Array:
	var right := PackedVector2Array()
	for p in [Vector2(0.24, -0.11), Vector2(0.6, -0.06), Vector2(0.93, -0.01)]:
		right.append(b.bodice_to_model(p))
	for i in range(1, 11):
		right.append(b.bodice_to_model(Vector2(1.0, i / 10.0)))
	for v in [0.06, 0.12, 0.19, 0.26]:
		right.append(b.skirt_to_model(Vector2(0.98, v)))
	right.append(b.skirt_to_model(Vector2(0.3, 0.3)))
	var out := right.duplicate()
	out.append(b.skirt_to_model(Vector2(0, 0.27)))
	for i in range(right.size() - 1, -1, -1):
		out.append(Vector2(-right[i].x, right[i].y))
	return out


func _draw_torso() -> void:
	var outline := _outline()
	# Arms (behind the torso edge), each conformed to its own sleeve.
	for side in [-1, 1]:
		var kind := "arm_left" if side < 0 else "arm_right"
		var arm := PackedVector2Array()
		for i in range(21):
			arm.append(body.arm_to_model(Vector2(1.0, -0.04 + i * 0.052), side))
		for i in range(20, -1, -1):
			arm.append(body.arm_to_model(Vector2(-1.0, -0.04 + i * 0.052), side))
		_part("arm%d" % side, kind, arm, skin, outline)
		var cap := ShapeDrawer.ellipse_points(body.shoulder_point(side), body.arm_hw_top * 1.05, body.arm_hw_top * 1.05, 16)
		var cap_pts := fitter.deform("cap%d" % side, kind, cap) if fitter else cap
		var cap_tris := ShapeDrawer._triangulate(cap)
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), cap_tris, cap_pts, PackedColorArray([skin]))
	# Neck.
	var nb := body.neck_base()
	var neck_top := body.head_center_y + body.head_radius * 0.7
	var neck := PackedVector2Array([Vector2(-body.neck_hw, neck_top), Vector2(body.neck_hw, neck_top),
		Vector2(body.neck_hw * 1.1, nb.y + 4), Vector2(-body.neck_hw * 1.1, nb.y + 4)])
	_part("neck", "neck", neck, skin, outline)
	# Torso.
	_part("torso", "torso", _torso_outline(), skin, outline)
	for side in [-1, 1]:
		_line("collar%d" % side, "torso", PackedVector2Array([body.bodice_to_model(Vector2(0.45 * side, 0.02)), body.bodice_to_model(Vector2(0.28 * side, 0.04)), body.bodice_to_model(Vector2(0.12 * side, 0.06))]), outline.lerp(skin, 0.6), 1.0)
	# Chemise underlayer.
	var chem := PackedVector2Array()
	chem.append(body.bodice_to_model(Vector2(0.95, 0.24)))
	for i in range(0, 9):
		chem.append(body.bodice_to_model(Vector2(0.99, 0.3 + i * 0.0875)))
	chem.append(body.skirt_to_model(Vector2(0.99, 0.04)))
	chem.append(body.skirt_to_model(Vector2(-0.99, 0.04)))
	for i in range(8, -1, -1):
		chem.append(body.bodice_to_model(Vector2(-0.99, 0.3 + i * 0.0875)))
	chem.append(body.bodice_to_model(Vector2(-0.95, 0.24)))
	for k in range(9):
		var u := lerpf(-0.9, 0.9, k / 8.0)
		chem.append(body.bodice_to_model(Vector2(u, 0.2 + (0.03 if k % 2 == 0 else 0.0))))
	_part("chemise", "torso", chem, UNDERWEAR, UNDERWEAR.darkened(0.35))
	for side in [-1, 1]:
		_line("strap%d" % side, "torso", PackedVector2Array([body.bodice_to_model(Vector2(0.55 * side, 0.21)), body.bodice_to_model(Vector2(0.575 * side, 0.08)), body.bodice_to_model(Vector2(0.6 * side, -0.05))]), UNDERWEAR.darkened(0.2), 2.0)


func _draw_hands() -> void:
	var outline := _outline()
	for side in [-1, 1]:
		var off := fitter.wrist_offset(side) if fitter else Vector2.ZERO
		var hand := PackedVector2Array()
		for p in [Vector2(0.95, 0.99), Vector2(1.3, 1.04), Vector2(1.35, 1.09), Vector2(1.0, 1.135), Vector2(0.2, 1.15), Vector2(-0.7, 1.13), Vector2(-1.15, 1.07), Vector2(-0.95, 0.99)]:
			hand.append(body.arm_to_model(p, side) + off)
		ShapeDrawer.fill_polygon(self, hand, skin, outline)
		var thumb := PackedVector2Array()
		for p in [Vector2(-0.9, 1.02), Vector2(-1.6, 1.06), Vector2(-1.65, 1.09), Vector2(-1.05, 1.09)]:
			thumb.append(body.arm_to_model(p, side) + off)
		ShapeDrawer.fill_polygon(self, thumb, skin, outline)


func _draw_head() -> void:
	var r := body.head_radius
	var c := body.head_center()
	var outline := _outline()
	for side in [-1, 1]:
		var ear := ShapeDrawer.ellipse_points(c + Vector2(side * r * 0.97, r * 0.08), r * 0.16, r * 0.24, 14)
		ShapeDrawer.fill_polygon(self, ear, skin, outline)
	var head := PackedVector2Array()
	for i in range(32):
		var a := TAU * i / 32.0
		var ry := r * (1.15 if sin(a) < 0.0 else 1.12)
		var rx := r * (1.0 - 0.1 * maxf(sin(a), 0.0) * maxf(sin(a), 0.0))
		head.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ShapeDrawer.fill_polygon(self, head, skin, outline)
	# Face.
	var eye_col := Color(0.18, 0.12, 0.1)
	for side in [-1, 1]:
		var e := c + Vector2(side * r * 0.36, r * 0.12)
		if blink:
			draw_polyline(PackedVector2Array([e + Vector2(-r * 0.12, 0), e + Vector2(0, r * 0.04), e + Vector2(r * 0.12, 0)]), eye_col, 1.6, true)
		else:
			var eye := ShapeDrawer.ellipse_points(e, r * 0.09, r * 0.12, 14)
			ShapeDrawer.fill_polygon(self, eye, eye_col)
			draw_circle(e + Vector2(-r * 0.03, -r * 0.04), r * 0.03, Color(1, 1, 1, 0.9))
			draw_polyline(PackedVector2Array([e + Vector2(-side * r * 0.05, -r * 0.12), e + Vector2(side * r * 0.12, -r * 0.15), e + Vector2(side * r * 0.18, -r * 0.1)]), eye_col, 1.3, true)
		draw_polyline(PackedVector2Array([e + Vector2(-r * 0.14, -r * 0.27), e + Vector2(0, -r * 0.32), e + Vector2(r * 0.14, -r * 0.27)]), skin.darkened(0.55), 1.6, true)
		draw_circle(c + Vector2(side * r * 0.55, r * 0.42), r * 0.14, Color(0.95, 0.45, 0.45, 0.22))
	draw_polyline(PackedVector2Array([c + Vector2(0, r * 0.22), c + Vector2(-r * 0.05, r * 0.42), c + Vector2(r * 0.03, r * 0.45)]), skin.darkened(0.3), 1.2, true)
	var lip := Color(0.78, 0.33, 0.36)
	var mouth := PackedVector2Array([c + Vector2(-r * 0.17, r * 0.62), c + Vector2(0, r * 0.58), c + Vector2(r * 0.17, r * 0.62), c + Vector2(0, r * 0.72)])
	ShapeDrawer.fill_polygon(self, mouth, lip, lip.darkened(0.3), 1.0)
