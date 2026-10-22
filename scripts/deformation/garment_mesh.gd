class_name GarmentMesh
extends RefCounted
## Builds a subdivided triangle mesh for a garment template in its local frame.
## The mesh is triangulated once in rest pose, so later deformation can never
## break the triangulation (folds simply overlap instead of disappearing).

## Approximate pixels per local unit, used only to get even mesh density.
const UNIT_PX := {"bodice": Vector2(62, 120), "skirt": Vector2(64, 340), "sleeve": Vector2(12, 225)}
const EDGE_STEP_PX := 8.0
const GRID_STEP_PX := 15.0

static var _cache: Dictionary = {}

var outline: PackedVector2Array  # densified closed outline (local)
var vertices: PackedVector2Array  # outline vertices first, then interior points (local)
var indices: PackedInt32Array
var outline_count: int = 0


static func for_definition(def: GarmentDefinition) -> GarmentMesh:
	var key := "%s:%d" % [def.id, def.outline.size()]
	if _cache.has(key):
		return _cache[key]
	var mesh := GarmentMesh.new()
	mesh._build(def.outline, UNIT_PX.get(def.category, Vector2(60, 120)))
	_cache[key] = mesh
	return mesh


static func clear_cache() -> void:
	_cache.clear()


static func densify(points: PackedVector2Array, unit_px: Vector2, step_px: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := points.size()
	for i in range(n):
		var a := points[i]
		var b := points[(i + 1) % n]
		var len_px := ((b - a) * unit_px).length()
		var steps := maxi(1, ceili(len_px / step_px))
		for s in range(steps):
			out.append(a.lerp(b, float(s) / steps))
	return out


func _build(source: PackedVector2Array, unit_px: Vector2) -> void:
	outline = densify(source, unit_px, EDGE_STEP_PX)
	outline_count = outline.size()
	vertices = outline.duplicate()
	# Work in pixel-like space so triangles are well-shaped.
	var px_outline := PackedVector2Array()
	for p in outline:
		px_outline.append(p * unit_px)
	var bounds := Rect2(px_outline[0], Vector2.ZERO)
	for p in px_outline:
		bounds = bounds.expand(p)
	var px_points := px_outline.duplicate()
	var min_dist_sq := (GRID_STEP_PX * 0.45) * (GRID_STEP_PX * 0.45)
	var y := bounds.position.y + GRID_STEP_PX * 0.5
	var row := 0
	while y < bounds.end.y:
		var x := bounds.position.x + GRID_STEP_PX * (0.5 if row % 2 == 0 else 1.0)
		while x < bounds.end.x:
			var q := Vector2(x, y)
			if Geometry2D.is_point_in_polygon(q, px_outline) and _far_from(q, px_outline, min_dist_sq):
				px_points.append(q)
				vertices.append(q / unit_px)
			x += GRID_STEP_PX
		y += GRID_STEP_PX * 0.87
		row += 1
	var tris := Geometry2D.triangulate_delaunay(px_points)
	indices = PackedInt32Array()
	for t in range(0, tris.size(), 3):
		var a := px_points[tris[t]]
		var b := px_points[tris[t + 1]]
		var c := px_points[tris[t + 2]]
		var centroid := (a + b + c) / 3.0
		if not Geometry2D.is_point_in_polygon(centroid, px_outline):
			continue
		# Reject slivers spanning across concave notches.
		var mid_ab := (a + b) * 0.5
		var mid_bc := (b + c) * 0.5
		var mid_ca := (c + a) * 0.5
		if not (Geometry2D.is_point_in_polygon(mid_ab, px_outline) or _on_outline(tris[t], tris[t + 1])):
			continue
		if not (Geometry2D.is_point_in_polygon(mid_bc, px_outline) or _on_outline(tris[t + 1], tris[t + 2])):
			continue
		if not (Geometry2D.is_point_in_polygon(mid_ca, px_outline) or _on_outline(tris[t + 2], tris[t])):
			continue
		indices.append(tris[t])
		indices.append(tris[t + 1])
		indices.append(tris[t + 2])
	if indices.is_empty():
		# Fallback: plain ear-clipping of the outline.
		indices = Geometry2D.triangulate_polygon(px_outline)


func _on_outline(i: int, j: int) -> bool:
	if i >= outline_count or j >= outline_count:
		return false
	var d := absi(i - j)
	return d == 1 or d == outline_count - 1


static func _far_from(q: Vector2, pts: PackedVector2Array, min_dist_sq: float) -> bool:
	for p in pts:
		if q.distance_squared_to(p) < min_dist_sq:
			return false
	return true
