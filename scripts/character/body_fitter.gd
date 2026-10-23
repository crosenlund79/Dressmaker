class_name BodyFitter
extends RefCounted
## Makes the mannequin conform to the clothes it wears.
##
## Every body vertex that lies under a garment (judged in the garment's rest pose)
## is bound to that garment and pushed through the garment's own deformation
## pipeline (transform, bend, flare, curve cage and seam attachment). Wherever the
## fabric goes, the body underneath goes with it, so skin, chemise and bloomers
## never poke out beside a narrowed, rotated or reshaped piece. Where a template is
## slightly narrower than the body, covered vertices are first pulled just inside
## the silhouette. Exposed areas (bare shoulders, necklines, legs below a hem, bare
## arms) are left untouched.
##
## Bindings depend only on the body and the chosen templates, so they are computed
## once and reused while the player drags handles.

const MIN_ROW_EXTENT := 0.8  # a row must be covered at least this wide to trim the body to it
const MARGIN_PX := 3.0  # how far inside the fabric edge trimmed body vertices are placed
const ROWS := 64

static var _coverage: Dictionary = {}  # template id -> Coverage

var body: BodyDefinition
var shapes: Dictionary = {}
var _bindings: Dictionary = {}  # part name -> {key, inside: PackedByteArray, slots, locals}


func update(body_def: BodyDefinition, garment_shapes: Dictionary) -> void:
	body = body_def
	shapes = garment_shapes


## Returns `pts` (rest-pose model space) conformed to the garments covering them.
## `kind`: "torso" (bodice above the waist, skirt below), "neck" (bodice),
## "lower" (skirt), "arm_left" / "arm_right" (sleeves).
func deform(part: String, kind: String, pts: PackedVector2Array) -> PackedVector2Array:
	if body == null:
		return pts
	var b := _binding(part, kind, pts)
	var inside: PackedByteArray = b["inside"]
	var slots: PackedStringArray = b["slots"]
	var locals: PackedVector2Array = b["locals"]
	var out := pts.duplicate()
	for i in range(out.size()):
		if inside[i] == 1:
			var shape: GarmentShape = shapes[slots[i]]
			out[i] = shape.map_point(locals[i])
	return out


## How far the garment carried the wrist (hands and bracelets follow it).
func wrist_offset(side: int) -> Vector2:
	if body == null:
		return Vector2.ZERO
	var slot := "sleeve_left" if side < 0 else "sleeve_right"
	var rest := body.arm_to_model(Vector2(0, 0.97), side)
	var local := _covered_local(slot, rest)
	if local.x == INF:
		return Vector2.ZERO
	return (shapes[slot] as GarmentShape).map_point(local) - rest


func _slot_for(kind: String, q: Vector2) -> String:
	match kind:
		"torso":
			return "bodice" if q.y <= body.waist_y + 0.5 else "skirt"
		"neck":
			return "bodice"
		"lower":
			return "skirt"
		"arm_left":
			return "sleeve_left"
		"arm_right":
			return "sleeve_right"
	return ""


func _binding(part: String, kind: String, pts: PackedVector2Array) -> Dictionary:
	var key := "%s|%d|%d" % [body.id, pts.size(), hash(pts)]
	for slot in ["bodice", "skirt", "sleeve_left", "sleeve_right"]:
		var s: GarmentShape = shapes.get(slot)
		key += "|" + (s.definition.id + str(s.instance.visible) if s else "-")
	var cached: Dictionary = _bindings.get(part, {})
	if cached.get("key", "") == key:
		return cached
	var inside := PackedByteArray()
	var slots := PackedStringArray()
	var locals := PackedVector2Array()
	inside.resize(pts.size())
	slots.resize(pts.size())
	locals.resize(pts.size())
	for i in range(pts.size()):
		var slot := _slot_for(kind, pts[i])
		var local := _covered_local(slot, pts[i])
		if local.x != INF:
			inside[i] = 1
			slots[i] = slot
			locals[i] = local
	var b := {"key": key, "inside": inside, "slots": slots, "locals": locals}
	_bindings[part] = b
	return b


## The garment-local point a covered body vertex binds to, or (INF, INF) if the
## vertex is not under that garment.
func _covered_local(slot: String, q: Vector2) -> Vector2:
	var shape: GarmentShape = shapes.get(slot)
	if shape == null or not shape.instance.visible:
		return Vector2(INF, INF)
	var p := to_local(shape, q)
	var cov := coverage_for(shape.definition)
	p = cov.fit(p)
	if not cov.contains(p):
		return Vector2(INF, INF)
	return p


## Inverse of the body mapping for the garment's frame (rest pose).
func to_local(shape: GarmentShape, q: Vector2) -> Vector2:
	match shape.category:
		"bodice":
			return Vector2(q.x / body.silhouette_hw(q.y), (q.y - body.shoulder_y) / body.torso_length())
		"skirt":
			return Vector2(q.x / body.silhouette_hw(q.y), (q.y - body.waist_y) / body.skirt_length())
	var side := shape.side
	var d := q - body.shoulder_point(side)
	var t := d.dot(body.arm_direction(side)) / body.arm_length
	var s := d.dot(body.arm_outward_normal(side)) / body.arm_hw(t)
	return Vector2(s, t)


static func coverage_for(def: GarmentDefinition) -> Coverage:
	if not _coverage.has(def.id):
		_coverage[def.id] = Coverage.new(def)
	return _coverage[def.id]


## Per-template silhouette data in the garment's local frame.
class Coverage extends RefCounted:
	var unit: Vector2
	var outline_px: PackedVector2Array
	var y0: float
	var y1: float
	var ext_l := PackedFloat32Array()
	var ext_r := PackedFloat32Array()

	func _init(def: GarmentDefinition) -> void:
		unit = GarmentMesh.UNIT_PX.get(def.category, Vector2(60, 120))
		var outline := GarmentMesh.densify(def.outline, unit, 6.0)
		for p in outline:
			outline_px.append(p * unit)
		var bounds := def.get_local_bounds()
		y0 = bounds.position.y
		y1 = bounds.end.y
		ext_l.resize(ROWS)
		ext_r.resize(ROWS)
		for r in range(ROWS):
			var y := lerpf(y0, y1, (r + 0.5) / ROWS)
			var lo := INF
			var hi := -INF
			for i in range(outline.size()):
				var a := outline[i]
				var b := outline[(i + 1) % outline.size()]
				if (a.y - y) * (b.y - y) <= 0.0 and a.y != b.y:
					var x := lerpf(a.x, b.x, (y - a.y) / (b.y - a.y))
					lo = minf(lo, x)
					hi = maxf(hi, x)
			ext_l[r] = lo
			ext_r[r] = hi

	## Pulls a point that sticks out past a fully covered row back inside the fabric.
	func fit(p: Vector2) -> Vector2:
		if p.y < y0 or p.y > y1:
			return p
		var r := clampi(int((p.y - y0) / (y1 - y0) * ROWS), 0, ROWS - 1)
		var lo := ext_l[r]
		var hi := ext_r[r]
		if lo == INF:
			return p
		var margin := MARGIN_PX / unit.x
		var x := p.x
		if hi >= MIN_ROW_EXTENT and x > hi - margin:
			x = hi - margin
		if -lo >= MIN_ROW_EXTENT and x < lo + margin:
			x = lo + margin
		return Vector2(x, p.y)

	func contains(p: Vector2) -> bool:
		return Geometry2D.is_point_in_polygon(p * unit, outline_px)
