class_name ShapeDrawer
extends RefCounted
## Draws the generic shape dictionaries used by shoes, hair and jewelry:
##   {k: "poly"|"line"|"circle", r: color region, p: points, w: line width, rad: radius, shade: brightness}

const OUTLINE_DARKEN := 0.45

static var _tri_cache: Dictionary = {}


static func draw_shapes(ci: CanvasItem, shapes: Array, colors: PackedColorArray, xf: Transform2D, unit: float, outline_width: float = 1.1) -> void:
	for s in shapes:
		var region: int = s.get("r", 0)
		var base: Color = colors[clampi(region, 0, colors.size() - 1)] if colors.size() > 0 else Color.WHITE
		var col := _shade(base, float(s.get("shade", 1.0)))
		var pts: PackedVector2Array = s.get("p", PackedVector2Array())
		match s.get("k", "poly"):
			"poly":
				if pts.size() < 3:
					continue
				var world := xf * pts
				var tris := _triangulate(pts)
				if not tris.is_empty():
					RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), tris, world, PackedColorArray([col]))
				var closed := world.duplicate()
				closed.append(world[0])
				ci.draw_polyline(closed, col.darkened(OUTLINE_DARKEN), outline_width, true)
			"line":
				if pts.size() < 2:
					continue
				ci.draw_polyline(xf * pts, col, maxf(float(s.get("w", 0.05)) * unit, 0.8), true)
			"circle":
				if pts.is_empty():
					continue
				var center: Vector2 = xf * pts[0]
				var radius: float = float(s.get("rad", 0.1)) * unit
				ci.draw_circle(center, radius, col)
				ci.draw_arc(center, radius, 0.0, TAU, maxi(10, int(radius * 1.5)), col.darkened(OUTLINE_DARKEN), outline_width, true)


static func _shade(c: Color, shade: float) -> Color:
	if shade == 1.0:
		return c
	if shade < 1.0:
		return c.darkened(1.0 - shade)
	return c.lightened(shade - 1.0)


static func _triangulate(pts: PackedVector2Array) -> PackedInt32Array:
	var key := hash(pts)
	if _tri_cache.has(key):
		return _tri_cache[key]
	var tris := Geometry2D.triangulate_polygon(pts)
	_tri_cache[key] = tris
	return tris


## Filled polygon that tolerates self-intersection (draws nothing for the fill if it can't triangulate).
static func fill_polygon(ci: CanvasItem, pts: PackedVector2Array, col: Color, outline: Color = Color.TRANSPARENT, width: float = 1.2) -> void:
	if pts.size() < 3:
		return
	var tris := Geometry2D.triangulate_polygon(pts)
	if not tris.is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), tris, pts, PackedColorArray([col]))
	if outline.a > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, outline, width, true)


static func ellipse_points(center: Vector2, rx: float, ry: float, n: int = 24) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(n):
		var a := TAU * i / n
		out.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return out
