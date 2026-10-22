class_name PreviewArt
extends RefCounted
## Draws small library thumbnails directly from content data (no image files needed),
## so new templates get icons automatically.

const FABRIC_SHADER := preload("res://shaders/fabric.gdshader")


static func fit(bounds: Rect2, rect: Rect2, pad: float = 0.12, flip_y: bool = false) -> Transform2D:
	var inner := rect.grow(-minf(rect.size.x, rect.size.y) * pad)
	var s := minf(inner.size.x / maxf(bounds.size.x, 0.001), inner.size.y / maxf(bounds.size.y, 0.001))
	var origin := inner.get_center() - bounds.get_center() * s
	return Transform2D(Vector2(s, 0), Vector2(0, -s if flip_y else s), origin)


static func garment(ci: CanvasItem, rect: Rect2, def: GarmentDefinition, primary: Color, trim: Color) -> void:
	var unit: Vector2 = GarmentMesh.UNIT_PX.get(def.category, Vector2(60, 120))
	var pts := PackedVector2Array()
	for p in def.outline:
		pts.append(p * unit)
	var b := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		b = b.expand(p)
	var xf := fit(b, rect, 0.1)
	var world := xf * pts
	ShapeDrawer.fill_polygon(ci, world, primary, primary.darkened(0.55), 1.4)
	for line in def.detail_lines:
		var l := PackedVector2Array()
		for p in line:
			l.append(xf * (p * unit))
		if l.size() >= 2:
			ci.draw_polyline(l, trim, 1.2, true)
	for d in def.detail_dots:
		ci.draw_circle(xf * (d * unit), 1.6, trim)


static func body(ci: CanvasItem, rect: Rect2, b: BodyDefinition, skin: Color) -> void:
	var common := Rect2(-110, -700, 220, 704)  # shared scale so heights are comparable
	var xf := fit(common, rect, 0.06)
	var outline := skin.darkened(0.4)
	for side in [-1, 1]:
		var arm := PackedVector2Array()
		for t in [0.0, 1.1]:
			arm.append(b.arm_to_model(Vector2(1.0, t), side))
		for t in [1.1, 0.0]:
			arm.append(b.arm_to_model(Vector2(-1.0, t), side))
		ShapeDrawer.fill_polygon(ci, xf * arm, skin, outline, 1.0)
		var leg := PackedVector2Array([Vector2(side * b.hip_hw * 0.42 - b.leg_hw_top, b.hip_y), Vector2(side * b.hip_hw * 0.42 + b.leg_hw_top, b.hip_y),
			Vector2(side * b.ankle_x + b.leg_hw_ankle, 0), Vector2(side * b.ankle_x - b.leg_hw_ankle, 0)])
		ShapeDrawer.fill_polygon(ci, xf * leg, skin, outline, 1.0)
	var torso := PackedVector2Array()
	for i in range(11):
		torso.append(b.bodice_to_model(Vector2(1.0, i / 10.0)))
	torso.append(b.skirt_to_model(Vector2(1.0, 0.2)))
	torso.append(b.skirt_to_model(Vector2(-1.0, 0.2)))
	for i in range(10, -1, -1):
		torso.append(b.bodice_to_model(Vector2(-1.0, i / 10.0)))
	ShapeDrawer.fill_polygon(ci, xf * torso, skin, outline, 1.0)
	var hc: Vector2 = xf * b.head_center()
	var hr: float = b.head_radius * xf.get_scale().x
	ci.draw_circle(hc, hr, skin)
	ci.draw_arc(hc, hr, 0, TAU, 20, outline, 1.0, true)


static func shoe(ci: CanvasItem, rect: Rect2, def: ShoeDefinition) -> void:
	var b := Rect2(-14, -40, 56, 42)
	for sh in def.shapes:
		for p in sh["p"]:
			b = b.expand(p)
	var xf := fit(b, rect, 0.06)
	ShapeDrawer.draw_shapes(ci, def.shapes, def.region_defaults, xf, xf.get_scale().x, 1.0)


static func hair(ci: CanvasItem, rect: Rect2, def: HairDefinition, skin: Color = Color(0.95, 0.82, 0.72)) -> void:
	var b := Rect2(-2.3, -2.6, 4.6, 6.4)
	var xf := fit(b, rect, 0.04)
	var s := xf.get_scale().x
	ShapeDrawer.draw_shapes(ci, def.back_shapes, def.default_colors, xf, s, 1.0)
	var neck := PackedVector2Array([Vector2(-0.4, 0.8), Vector2(0.4, 0.8), Vector2(0.45, 1.9), Vector2(-0.45, 1.9)])
	ShapeDrawer.fill_polygon(ci, xf * neck, skin)
	var shoulders := PackedVector2Array([Vector2(-2.0, 2.4), Vector2(-0.5, 1.7), Vector2(0.5, 1.7), Vector2(2.0, 2.4), Vector2(2.1, 3.8), Vector2(-2.1, 3.8)])
	ShapeDrawer.fill_polygon(ci, xf * shoulders, Color(0.9, 0.86, 0.8), Color(0.6, 0.55, 0.5))
	ci.draw_set_transform_matrix(xf)
	ci.draw_circle(Vector2.ZERO, 1.0, skin)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	ShapeDrawer.draw_shapes(ci, def.front_shapes, def.default_colors, xf, s, 1.0)


static func jewelry(ci: CanvasItem, rect: Rect2, def: JewelryDefinition) -> void:
	var b := Rect2()
	var first := true
	for sh in def.shapes:
		for p in sh["p"]:
			var rr: float = sh.get("rad", 1.0)
			var pr := Rect2(p - Vector2(rr, rr), Vector2(rr, rr) * 2.0)
			b = pr if first else b.merge(pr)
			first = false
	var xf := fit(b.grow(2.0), rect, 0.12)
	ShapeDrawer.draw_shapes(ci, def.shapes, PackedColorArray([def.default_metal, def.default_gem]), xf, xf.get_scale().x, 1.0)


static func fabric_material(def: FabricDefinition, primary: Color, secondary: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FABRIC_SHADER
	m.set_shader_parameter("pattern", def.texture)
	m.set_shader_parameter("primary", primary)
	m.set_shader_parameter("secondary", secondary)
	m.set_shader_parameter("pattern_scale", 1.0)
	m.set_shader_parameter("opacity", 1.0)
	return m


## Draws a fabric swatch; `ci` must use fabric_material().
static func fabric_swatch(ci: CanvasItem, rect: Rect2) -> void:
	var r := rect.grow(-6)
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var uv_scale := 1.6
	var uvs := PackedVector2Array([Vector2.ZERO, Vector2(uv_scale, 0), Vector2(uv_scale, uv_scale), Vector2(0, uv_scale)])
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), PackedInt32Array([0, 1, 2, 0, 2, 3]), pts, PackedColorArray([Color.WHITE]), uvs)
