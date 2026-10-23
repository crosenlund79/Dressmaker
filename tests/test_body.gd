extends TestCase
## Body definitions and anchor calculations.


func test_ten_body_types_with_distinct_proportions() -> void:
	check_eq(Content.bodies.size(), 10, "10 body types")
	var signatures := {}
	for b in Content.bodies:
		var sig := "%d|%d|%d|%d|%d" % [b.shoulder_hw, b.waist_hw, b.hip_hw, b.head_center_y, b.waist_y]
		check(not signatures.has(sig), "body %s has unique proportions" % b.id)
		signatures[sig] = true
	done()


func test_anchor_order_and_symmetry() -> void:
	for b in Content.bodies:
		check(b.get_anchor("crown").y < b.get_anchor("head").y, "%s crown above head center" % b.id)
		check(b.get_anchor("head").y < b.get_anchor("neck").y, "%s head above neck" % b.id)
		check(b.get_anchor("neck").y < b.get_anchor("waist").y, "%s neck above waist" % b.id)
		check(b.get_anchor("waist").y < b.get_anchor("hip_left").y, "%s waist above hips" % b.id)
		check(b.get_anchor("hip_left").y < b.get_anchor("ankle_left").y, "%s hips above ankles" % b.id)
		check(b.get_anchor("ankle_left").y < 0.0, "%s ankles above the floor" % b.id)
		for pair in [["shoulder_left", "shoulder_right"], ["wrist_left", "wrist_right"], ["ankle_left", "ankle_right"], ["ear_left", "ear_right"], ["armpit_left", "armpit_right"]]:
			var l := b.get_anchor(pair[0])
			var r := b.get_anchor(pair[1])
			check_vec_near(l, Vector2(-r.x, r.y), 1e-4, "%s %s mirrors %s" % [b.id, pair[0], pair[1]])
			check(l.x < 0.0 and r.x > 0.0, "%s %s on the left" % [b.id, pair[0]])
	done()


func test_bodice_and_skirt_frames_agree_at_waist() -> void:
	for b in Content.bodies:
		for u in [-1.2, -1.0, -0.4, 0.0, 0.7, 1.0, 1.3]:
			check_vec_near(b.bodice_to_model(Vector2(u, 1.0)), b.skirt_to_model(Vector2(u, 0.0)), 1e-3, "%s waist seam continuity at u=%f" % [b.id, u])
	done()


func test_arm_length_and_widths() -> void:
	for b in Content.bodies:
		for side in [-1, 1]:
			var shoulder := b.arm_to_model(Vector2.ZERO, side)
			var wrist := b.wrist_point(side)
			check_near(shoulder.distance_to(wrist), b.arm_length, 0.01, "%s arm length" % b.id)
			var w := b.arm_to_model(Vector2(1, 0.5), side).distance_to(b.arm_to_model(Vector2(-1, 0.5), side))
			check_near(w, b.arm_hw(0.5) * 2.0, 0.01, "%s arm width at mid" % b.id)
	done()


func test_silhouette_is_smooth_and_positive() -> void:
	for b in Content.bodies:
		var prev := b.silhouette_hw(b.shoulder_y)
		var y := b.shoulder_y
		while y < b.hip_y + 40:
			var w := b.silhouette_hw(y)
			check(w > 10.0, "%s positive width at y=%f" % [b.id, y])
			check(absf(w - prev) < 4.0, "%s silhouette continuous at y=%f" % [b.id, y])
			prev = w
			y += 2.0
	done()
