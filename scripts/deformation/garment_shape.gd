class_name GarmentShape
extends RefCounted
## Evaluated geometry of one garment on one body: the full deformation pipeline
## plus the attachment (seam) system that keeps garment pieces connected.
##
## Attachment rules:
##  * Skirt: its waist edge (local v = 0) is pinned to the bodice's deformed waist
##    edge (bodice local v = 1). The correction fades out down the skirt, so the
##    connecting edge is deformed rather than the whole skirt being shifted.
##  * Sleeves: the shoulder end follows the bodice's deformed shoulder anchor; the
##    correction fades toward the wrist so the cuff stays at the hand.

const SKIRT_SEAM_FALLOFF := 0.35
const SEAM_SAMPLES := 33
const SEAM_RANGE := 1.25

var definition: GarmentDefinition
var instance: GarmentInstance
var body: BodyDefinition
var category: String = "bodice"
var side: int = 1
var bounds: Rect2
var cage: Rect2
var lattice: PackedVector2Array
var basis: Transform2D
var pivot: Vector2

var mesh: GarmentMesh
## Final model-space geometry (valid after rebuild()).
var points: PackedVector2Array
var outline_points: PackedVector2Array
var uvs: PackedVector2Array
var shades: PackedColorArray

var _parent: GarmentShape = null
var _seam_delta: PackedVector2Array = PackedVector2Array()  # skirt: sampled along u
var _shoulder_delta: Vector2 = Vector2.ZERO  # sleeve


func _init(def: GarmentDefinition, inst: GarmentInstance, body_def: BodyDefinition, garment_side: int = 1, parent: GarmentShape = null) -> void:
	definition = def
	instance = inst
	body = body_def
	category = def.category
	side = garment_side
	bounds = def.get_local_bounds()
	cage = GarmentDeformer.cage_rect(bounds)
	lattice = inst.get_lattice()
	basis = GarmentDeformer.affine_basis(inst.scale, inst.rotation, inst.skew)
	pivot = GarmentDeformer.body_map(GarmentDeformer.pivot_local(category), category, body, side)
	_parent = parent
	_prepare_attachment()


## Stages 2-4 (everything after the cage offset).
func map_after_ffd(q: Vector2) -> Vector2:
	var bf := GarmentDeformer.bend_flare(q, category, bounds, instance.bend, instance.flare)
	var m := GarmentDeformer.body_map(bf, category, body, side)
	return GarmentDeformer.apply_affine(m, pivot, instance.offset, basis)


## Pipeline without the attachment correction.
func map_unattached(p: Vector2) -> Vector2:
	return map_after_ffd(p + GarmentDeformer.ffd_offset(p, lattice, cage))


## Full pipeline for a local rest-pose point.
func map_point(p: Vector2) -> Vector2:
	return map_unattached(p) + attachment_offset(p)


## Pre-affine model-space mapping (for the Basic-mode handle box).
func map_pre_affine(p: Vector2) -> Vector2:
	var q := p + GarmentDeformer.ffd_offset(p, lattice, cage)
	var bf := GarmentDeformer.bend_flare(q, category, bounds, instance.bend, instance.flare)
	return GarmentDeformer.body_map(bf, category, body, side)


func attachment_offset(p: Vector2) -> Vector2:
	if not instance.attached:
		return Vector2.ZERO
	match category:
		"skirt":
			if _seam_delta.is_empty():
				return Vector2.ZERO
			var w := 1.0 - smoothstep(0.0, SKIRT_SEAM_FALLOFF, p.y)
			if w <= 0.0:
				return Vector2.ZERO
			return _sample_seam_delta(p.x) * w
		"sleeve":
			var t := clampf(p.y, 0.0, 1.0)
			return _shoulder_delta * (1.0 - 0.85 * smoothstep(0.0, 1.0, t))
	return Vector2.ZERO


## The bodice's deformed waist seam at local u (model space).
func waist_seam_point(u: float) -> Vector2:
	return map_point(Vector2(u, 1.0))


func _prepare_attachment() -> void:
	if category == "skirt":
		_seam_delta = PackedVector2Array()
		for i in range(SEAM_SAMPLES):
			var u := lerpf(-SEAM_RANGE, SEAM_RANGE, float(i) / (SEAM_SAMPLES - 1))
			var target: Vector2
			if _parent != null:
				target = _parent.waist_seam_point(u)
			else:
				target = body.bodice_to_model(Vector2(u, 1.0))
			_seam_delta.append(target - map_unattached(Vector2(u, 0.0)))
	elif category == "sleeve" and _parent != null:
		var anchor := Vector2(BodyDefinition.SHOULDER_ANCHOR.x * side, BodyDefinition.SHOULDER_ANCHOR.y)
		_shoulder_delta = _parent.map_point(anchor) - body.bodice_to_model(anchor)


func _sample_seam_delta(u: float) -> Vector2:
	var f := (clampf(u, -SEAM_RANGE, SEAM_RANGE) + SEAM_RANGE) / (2.0 * SEAM_RANGE) * (SEAM_SAMPLES - 1)
	var i := mini(int(f), SEAM_SAMPLES - 2)
	return _seam_delta[i].lerp(_seam_delta[i + 1], f - i)


## Evaluates the mesh. Call after construction; cheap enough to run on every edit.
func rebuild(tile_size: float = 96.0) -> void:
	mesh = GarmentMesh.for_definition(definition)
	var n := mesh.vertices.size()
	points.resize(n)
	uvs.resize(n)
	shades.resize(n)
	var tile := maxf(tile_size, 1.0)
	var half_w := maxf(bounds.size.x * 0.5, 0.01)
	var cx := bounds.get_center().x
	for i in range(n):
		var p := mesh.vertices[i]
		points[i] = map_point(p)
		# UVs follow the rest pose so the pattern stretches with the fabric.
		var rest := GarmentDeformer.body_map(p, category, body, side)
		uvs[i] = rest / tile
		var xn := (p.x - cx) / half_w
		var g := 1.0 - 0.2 * xn * xn
		shades[i] = Color(g, g, g, 1.0)
	outline_points = points.slice(0, mesh.outline_count)


## Model-space position of a detail polyline / dot defined in local space.
func map_polyline(local_points: PackedVector2Array) -> PackedVector2Array:
	var dense := PackedVector2Array()
	var unit: Vector2 = GarmentMesh.UNIT_PX.get(category, Vector2(60, 120))
	for i in range(local_points.size() - 1):
		var a := local_points[i]
		var b := local_points[i + 1]
		var steps := maxi(1, ceili(((b - a) * unit).length() / 10.0))
		for s in range(steps):
			dense.append(map_point(a.lerp(b, float(s) / steps)))
	if local_points.size() > 0:
		dense.append(map_point(local_points[local_points.size() - 1]))
	return dense


func contains_point(model_point: Vector2) -> bool:
	return outline_points.size() >= 3 and Geometry2D.is_point_in_polygon(model_point, outline_points)


## Basic-mode handle box: the pre-affine model-space bounding box.
func pre_affine_box() -> Rect2:
	var outline := mesh.outline if mesh else definition.outline
	var r := Rect2(map_pre_affine(outline[0]), Vector2.ZERO)
	for i in range(0, outline.size(), 2):
		r = r.expand(map_pre_affine(outline[i]))
	return r


func box_point_to_model(p: Vector2) -> Vector2:
	return GarmentDeformer.apply_affine(p, pivot, instance.offset, basis)


## Displayed position of a cage control point.
func cage_point(ix: int, iy: int) -> Vector2:
	var rest := GarmentDeformer.cage_rest_point(ix, iy, cage)
	return map_after_ffd(rest + lattice[iy * GarmentDeformer.LATTICE_N + ix]) + attachment_offset(rest)


## Local cage offset that places control point (ix, iy) at `model_target`.
func solve_cage_offset(ix: int, iy: int, model_target: Vector2) -> Vector2:
	var rest := GarmentDeformer.cage_rest_point(ix, iy, cage)
	var att := attachment_offset(rest)
	var f := func(off: Vector2) -> Vector2: return map_after_ffd(rest + off) + att
	return GarmentDeformer.solve_inverse(f, lattice[iy * GarmentDeformer.LATTICE_N + ix], model_target)
