class_name GarmentDeformer
extends RefCounted
## Pure deformation math for garments. No scene dependencies, so it is unit-testable.
##
## Pipeline for a local garment point p (see GarmentShape):
##   1. free-form deformation:  q = p + FFD(p)            (Advanced mode cage, local units)
##   2. bend / flare:           q' = bend_flare(q)        (seam-preserving: zero effect at the seam)
##   3. body mapping:           m = body frame(q')        (adapts the garment to the body type)
##   4. affine:                 a = pivot + offset + B * (m - pivot)   B = rotation * skew * scale
##   5. attachment:             final = a + w(p) * seam_delta(p)       (see GarmentShape)

const LATTICE_N := 4
const CAGE_PADDING := 0.06
const BEND_STRENGTH := {"bodice": 1.0, "skirt": 1.6, "sleeve": 3.0}


static func bernstein3(i: int, t: float) -> float:
	var mt := 1.0 - t
	match i:
		0:
			return mt * mt * mt
		1:
			return 3.0 * t * mt * mt
		2:
			return 3.0 * t * t * mt
		_:
			return t * t * t


## Cage rectangle (local units) for a template's bounds.
static func cage_rect(bounds: Rect2) -> Rect2:
	var pad := bounds.size * CAGE_PADDING + Vector2(0.02, 0.02)
	return Rect2(bounds.position - pad, bounds.size + pad * 2.0)


static func cage_rest_point(ix: int, iy: int, cage: Rect2) -> Vector2:
	return cage.position + Vector2(cage.size.x * ix / float(LATTICE_N - 1), cage.size.y * iy / float(LATTICE_N - 1))


## Cubic Bernstein free-form deformation. `lattice` holds 16 offsets, row-major (iy * 4 + ix).
static func ffd_offset(p: Vector2, lattice: PackedVector2Array, cage: Rect2) -> Vector2:
	if lattice.size() != LATTICE_N * LATTICE_N:
		return Vector2.ZERO
	var s := clampf((p.x - cage.position.x) / maxf(cage.size.x, 1e-5), 0.0, 1.0)
	var t := clampf((p.y - cage.position.y) / maxf(cage.size.y, 1e-5), 0.0, 1.0)
	var bs := [bernstein3(0, s), bernstein3(1, s), bernstein3(2, s), bernstein3(3, s)]
	var bt := [bernstein3(0, t), bernstein3(1, t), bernstein3(2, t), bernstein3(3, t)]
	var out := Vector2.ZERO
	for iy in range(LATTICE_N):
		var wy: float = bt[iy]
		if wy == 0.0:
			continue
		for ix in range(LATTICE_N):
			out += lattice[iy * LATTICE_N + ix] * (wy * bs[ix])
	return out


## Normalized distance from the garment's seam (0 at the seam, 1 at the far end).
static func seam_distance(p: Vector2, category: String, bounds: Rect2) -> float:
	if category == "bodice":
		var top := bounds.position.y
		return maxf((1.0 - p.y) / maxf(1.0 - top, 0.1), 0.0)
	var bottom := bounds.end.y
	return maxf(p.y / maxf(bottom, 0.1), 0.0)


## Bend curves the garment sideways with a quadratic profile (a true curve, not a rotation);
## flare widens it progressively away from the seam. Both leave the seam untouched.
static func bend_flare(p: Vector2, category: String, bounds: Rect2, bend: float, flare: float) -> Vector2:
	if bend == 0.0 and flare == 0.0:
		return p
	var d := seam_distance(p, category, bounds)
	var x := p.x * (1.0 + flare * d)
	x += bend * d * d * float(BEND_STRENGTH.get(category, 1.0))
	return Vector2(x, p.y)


static func body_map(p: Vector2, category: String, body: BodyDefinition, side: int) -> Vector2:
	match category:
		"bodice":
			return body.bodice_to_model(p)
		"skirt":
			return body.skirt_to_model(p)
		_:
			return body.arm_to_model(p, side)


## Local point that acts as the garment's pivot / seam anchor.
static func pivot_local(category: String) -> Vector2:
	if category == "bodice":
		return Vector2(0.0, 1.0)  # waist center
	return Vector2.ZERO  # skirt: waist center, sleeve: shoulder


## B = rotation * skew * scale
static func affine_basis(scale: Vector2, rotation: float, skew: Vector2) -> Transform2D:
	var s := Transform2D(Vector2(scale.x, 0.0), Vector2(0.0, scale.y), Vector2.ZERO)
	var k := Transform2D(Vector2(1.0, tan(skew.y)), Vector2(tan(skew.x), 1.0), Vector2.ZERO)
	var r := Transform2D(rotation, Vector2.ZERO)
	return r * k * s


static func apply_affine(m: Vector2, pivot: Vector2, offset: Vector2, basis: Transform2D) -> Vector2:
	return pivot + offset + basis.basis_xform(m - pivot)


## Solves the 2x2 system J * x = rhs. Returns Vector2.ZERO if J is singular.
static func solve2(jx: Vector2, jy: Vector2, rhs: Vector2) -> Vector2:
	var det := jx.x * jy.y - jy.x * jx.y
	if absf(det) < 1e-9:
		return Vector2.ZERO
	return Vector2((rhs.x * jy.y - jy.x * rhs.y) / det, (jx.x * rhs.y - rhs.x * jx.y) / det)


## Finds a local-space input for `f` that maps to `target`, starting at `guess`
## (Newton iterations with a numerical Jacobian). Used to drag cage points with the mouse.
static func solve_inverse(f: Callable, guess: Vector2, target: Vector2, iterations: int = 6) -> Vector2:
	var x := guess
	var h := 1e-3
	for _i in range(iterations):
		var fx: Vector2 = f.call(x)
		var err := target - fx
		if err.length() < 0.05:
			break
		var jx: Vector2 = (f.call(x + Vector2(h, 0.0)) - fx) / h
		var jy: Vector2 = (f.call(x + Vector2(0.0, h)) - fx) / h
		var step := solve2(jx, jy, err)
		if step == Vector2.ZERO:
			break
		x += step
	return x
