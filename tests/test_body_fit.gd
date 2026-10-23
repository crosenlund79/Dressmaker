extends TestCase
## The mannequin conforms to its clothes: covered body never shows outside the fabric.


func _narrow_design() -> DressDesign:
	var d := DesignFactory.default_design()
	d.body_id = "full_figure"
	DesignFactory.set_template(d, "bodice", "bodice_corset", true)
	DesignFactory.set_template(d, "skirt", "skirt_column", true)
	d.garment("bodice").scale = Vector2(0.75, 1.0)
	d.garment("bodice").rotation = 0.15
	d.garment("skirt").scale = Vector2(0.65, 1.0)
	d.garment("skirt").bend = 0.8
	var lat := d.garment("skirt").get_lattice()
	lat[7] = Vector2(-0.4, 0.0)
	d.garment("skirt").lattice = lat
	d.garment("sleeve_right").scale = Vector2(0.55, 1.0)
	d.garment("sleeve_right").rotation = -0.2
	d.sync_sleeves("sleeve_right")
	return d


func _distance_outside(p: Vector2, outline: PackedVector2Array) -> float:
	if Geometry2D.is_point_in_polygon(p, outline):
		return 0.0
	var best := INF
	for i in range(outline.size()):
		var q := Geometry2D.get_closest_point_to_segment(p, outline[i], outline[(i + 1) % outline.size()])
		best = minf(best, p.distance_to(q))
	return best


func _check_part(c: CharacterPresentation, part: String, kind: String, rest: PackedVector2Array, slot_of: Callable) -> int:
	var deformed := c.fitter.deform(part, kind, rest)
	var bound := 0
	for i in range(rest.size()):
		var slot: String = slot_of.call(rest[i])
		var local := c.fitter._covered_local(slot, rest[i])
		if local.x == INF:
			check_vec_near(deformed[i], rest[i], 1e-4, "%s vertex %d is exposed and stays put" % [part, i])
			continue
		bound += 1
		var shape: GarmentShape = c.shapes[slot]
		var outside := _distance_outside(deformed[i], shape.outline_points)
		check(outside < 2.0, "%s vertex %d stays inside the %s (%.1f px outside)" % [part, i, slot, outside])
	return bound


func test_covered_body_stays_inside_fabric() -> void:
	var c := CharacterPresentation.new()
	add_child(c)
	c.set_design(_narrow_design())
	var body := c.body
	var torso := BodyRenderer._densify(BodyRenderer.new()._torso_outline_for(body), 7.0)
	var bound := _check_part(c, "t_torso", "torso", torso, func(q): return "bodice" if q.y <= body.waist_y + 0.5 else "skirt")
	check(bound > 20, "most of the torso is bound to the garments (%d)" % bound)
	for side in [-1, 1]:
		var arm := PackedVector2Array()
		for i in range(21):
			arm.append(body.arm_to_model(Vector2(1.0, -0.04 + i * 0.052), side))
		for i in range(20, -1, -1):
			arm.append(body.arm_to_model(Vector2(-1.0, -0.04 + i * 0.052), side))
		var slot := "sleeve_left" if side < 0 else "sleeve_right"
		var n := _check_part(c, "t_arm%d" % side, "arm_left" if side < 0 else "arm_right", BodyRenderer._densify(arm, 7.0), func(_q): return slot)
		check(n > 20, "arm %d bound to its sleeve" % side)
		check(c.fitter.wrist_offset(side).length() > 1.0, "hand %d follows the moved cuff" % side)
	c.queue_free()
	done()


func test_bare_shoulders_and_legs_remain() -> void:
	var c := CharacterPresentation.new()
	add_child(c)
	c.set_design(_narrow_design())
	var body := c.body
	# Above a strapless corset the shoulder is bare skin, not fabric.
	var shoulder := body.bodice_to_model(Vector2(0.8, -0.03))
	check(c.fitter._covered_local("bodice", shoulder).x == INF, "shoulder above the corset is exposed")
	# Without a skirt the legs are untouched.
	var d := _narrow_design()
	d.garment("skirt").template_id = ""
	c.set_design(d)
	var knee := Vector2(body.ankle_x, body.knee_y)
	var pts := PackedVector2Array([knee])
	check_vec_near(c.fitter.deform("t_knee", "lower", pts)[0], knee, 1e-4, "legs are unchanged without a skirt")
	c.queue_free()
	done()
