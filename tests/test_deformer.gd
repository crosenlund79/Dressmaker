extends TestCase
## Pure deformation math.


func test_bernstein_partition_of_unity() -> void:
	for t in [0.0, 0.13, 0.5, 0.77, 1.0]:
		var s := 0.0
		for i in range(4):
			s += GarmentDeformer.bernstein3(i, t)
		check_near(s, 1.0, 1e-6, "Bernstein weights sum to 1 at t=%f" % t)
	done()


func test_ffd_zero_lattice_is_identity() -> void:
	var cage := Rect2(-2, -0.5, 4, 2)
	var lat := PackedVector2Array()
	lat.resize(16)
	check_eq(GarmentDeformer.ffd_offset(Vector2(0.3, 0.2), lat, cage), Vector2.ZERO, "zero lattice gives zero offset")
	check_eq(GarmentDeformer.ffd_offset(Vector2(0.3, 0.2), PackedVector2Array(), cage), Vector2.ZERO, "empty lattice gives zero offset")
	done()


func test_ffd_uniform_translation() -> void:
	var cage := Rect2(-1, 0, 2, 1)
	var lat := PackedVector2Array()
	for i in range(16):
		lat.append(Vector2(0.25, -0.1))
	for p in [Vector2(-1, 0), Vector2(0.2, 0.7), Vector2(1, 1)]:
		check_vec_near(GarmentDeformer.ffd_offset(p, lat, cage), Vector2(0.25, -0.1), 1e-5, "uniform lattice translates %s" % str(p))
	done()


func test_ffd_corner_interpolates() -> void:
	var cage := Rect2(0, 0, 1, 1)
	var lat := PackedVector2Array()
	lat.resize(16)
	lat[15] = Vector2(0.5, 0.5)  # bottom-right control point
	check_vec_near(GarmentDeformer.ffd_offset(Vector2(1, 1), lat, cage), Vector2(0.5, 0.5), 1e-6, "corner control point is interpolated at the corner")
	check_vec_near(GarmentDeformer.ffd_offset(Vector2(0, 0), lat, cage), Vector2.ZERO, 1e-6, "opposite corner unaffected")
	var mid := GarmentDeformer.ffd_offset(Vector2(0.5, 0.5), lat, cage)
	check(mid.length() > 0.0 and mid.length() < 0.5, "interior is smoothly blended")
	done()


func test_bend_and_flare_preserve_seam() -> void:
	var bounds := Rect2(-2, 0, 4, 1)
	for cat in ["skirt", "sleeve"]:
		var seam_pt := Vector2(0.8, 0.0)
		check_vec_near(GarmentDeformer.bend_flare(seam_pt, cat, bounds, 1.5, 0.8), seam_pt, 1e-6, "%s seam unaffected by bend/flare" % cat)
	var bodice_bounds := Rect2(-1, -0.3, 2, 1.4)
	check_vec_near(GarmentDeformer.bend_flare(Vector2(0.5, 1.0), "bodice", bodice_bounds, 1.0, 1.0), Vector2(0.5, 1.0), 1e-6, "bodice waist seam unaffected")
	done()


func test_bend_is_a_curve_not_a_rotation() -> void:
	var bounds := Rect2(-2, 0, 4, 1)
	var a := GarmentDeformer.bend_flare(Vector2(0, 0.25), "skirt", bounds, 1.0, 0.0).x
	var b := GarmentDeformer.bend_flare(Vector2(0, 0.5), "skirt", bounds, 1.0, 0.0).x
	var c := GarmentDeformer.bend_flare(Vector2(0, 1.0), "skirt", bounds, 1.0, 0.0).x
	# Quadratic: displacement grows faster than linearly along the garment.
	check(b > a * 2.0 and c > b * 2.0, "bend displacement is non-linear (curved)")
	done()


func test_affine_identity_and_pivot() -> void:
	var basis := GarmentDeformer.affine_basis(Vector2.ONE, 0.0, Vector2.ZERO)
	var pivot := Vector2(10, 20)
	check_vec_near(GarmentDeformer.apply_affine(Vector2(3, 4), pivot, Vector2.ZERO, basis), Vector2(3, 4), 1e-5, "identity affine")
	var scaled := GarmentDeformer.affine_basis(Vector2(2, 3), 0.0, Vector2.ZERO)
	check_vec_near(GarmentDeformer.apply_affine(pivot, pivot, Vector2.ZERO, scaled), pivot, 1e-5, "pivot is a fixed point of scaling")
	var rot := GarmentDeformer.affine_basis(Vector2.ONE, PI / 2, Vector2.ZERO)
	check_vec_near(GarmentDeformer.apply_affine(pivot + Vector2(1, 0), pivot, Vector2.ZERO, rot), pivot + Vector2(0, 1), 1e-5, "rotation by 90 degrees")
	var skew := GarmentDeformer.affine_basis(Vector2.ONE, 0.0, Vector2(atan(0.5), 0.0))
	check_vec_near(GarmentDeformer.apply_affine(pivot + Vector2(0, 2), pivot, Vector2.ZERO, skew), pivot + Vector2(1, 2), 1e-5, "horizontal skew shifts x by y*tan")
	done()


func test_solve2_and_inverse() -> void:
	check_vec_near(GarmentDeformer.solve2(Vector2(2, 0), Vector2(0, 4), Vector2(2, 8)), Vector2(1, 2), 1e-6, "2x2 solve")
	check_eq(GarmentDeformer.solve2(Vector2(1, 1), Vector2(2, 2), Vector2(1, 1)), Vector2.ZERO, "singular system returns zero")
	var f := func(p: Vector2) -> Vector2: return Vector2(p.x * p.x * 3.0 + p.y, p.y * 2.0 - p.x)
	var target := Vector2(13.0, 3.0)
	var sol := GarmentDeformer.solve_inverse(f, Vector2(1, 1), target, 12)
	check_vec_near(f.call(sol), target, 0.06, "Newton inverse reaches target")
	done()

