extends TestCase
## Garment geometry, attachment (seams) and deformation on real content.


func _shape(id: String, inst: GarmentInstance, body: BodyDefinition, side: int = 1, parent: GarmentShape = null) -> GarmentShape:
	inst.template_id = id
	var s := GarmentShape.new(Content.get_garment(id), inst, body, side, parent)
	s.rebuild()
	return s


func test_every_template_builds_a_mesh() -> void:
	var body := Content.get_body("classic")
	for g in Content.garments:
		var s := _shape(g.id, GarmentInstance.new(), body, 1)
		check(s.mesh.indices.size() >= 3 and s.mesh.indices.size() % 3 == 0, "%s has triangles" % g.id)
		check(s.points.size() == s.mesh.vertices.size(), "%s geometry evaluated" % g.id)
		# Triangulated area should match the outline area (mesh covers the silhouette).
		var unit: Vector2 = GarmentMesh.UNIT_PX[g.category]
		var tri_area := 0.0
		for t in range(0, s.mesh.indices.size(), 3):
			var a := s.mesh.vertices[s.mesh.indices[t]] * unit
			var b := s.mesh.vertices[s.mesh.indices[t + 1]] * unit
			var c := s.mesh.vertices[s.mesh.indices[t + 2]] * unit
			tri_area += absf((b - a).cross(c - a)) * 0.5
		var poly := PackedVector2Array()
		for p in g.outline:
			poly.append(p * unit)
		var outline_area := 0.0
		for i in range(poly.size()):
			outline_area += poly[i].cross(poly[(i + 1) % poly.size()])
		outline_area = absf(outline_area) * 0.5
		check(absf(tri_area - outline_area) / outline_area < 0.08, "%s mesh covers outline (%.0f vs %.0f)" % [g.id, tri_area, outline_area])
	done()


func test_skirt_seam_follows_deformed_bodice() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for body_id in ["classic", "full_figure", "tall_slender"]:
		var body := Content.get_body(body_id)
		for i in range(6):
			var b_inst := GarmentInstance.new()
			b_inst.scale = Vector2(rng.randf_range(0.7, 1.6), rng.randf_range(0.8, 1.3))
			b_inst.rotation = rng.randf_range(-0.3, 0.3)
			b_inst.skew = Vector2(rng.randf_range(-0.4, 0.4), 0.0)
			b_inst.offset = Vector2(rng.randf_range(-30, 30), rng.randf_range(-20, 20))
			var lat := b_inst.get_lattice()
			lat[13] = Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.1, 0.1))
			b_inst.lattice = lat
			var bodice := _shape(Content.garments_in("bodice")[i * 3].id, b_inst, body)
			var s_inst := GarmentInstance.new()
			s_inst.scale = Vector2(rng.randf_range(0.6, 2.0), rng.randf_range(0.7, 1.4))
			s_inst.flare = rng.randf_range(0.0, 1.5)
			s_inst.bend = rng.randf_range(-1.0, 1.0)
			var skirt := _shape(Content.garments_in("skirt")[i * 3].id, s_inst, body, 1, bodice)
			for u in [-1.0, -0.5, 0.0, 0.5, 1.0]:
				check_vec_near(skirt.map_point(Vector2(u, 0.0)), bodice.waist_seam_point(u), 0.75, "%s case %d: skirt top meets bodice at u=%f" % [body_id, i, u])
	done()


func test_detached_skirt_is_free() -> void:
	var body := Content.get_body("classic")
	var b_inst := GarmentInstance.new()
	b_inst.offset = Vector2(0, -60)
	var bodice := _shape("bodice_victorian", b_inst, body)
	var s_inst := GarmentInstance.new()
	s_inst.attached = false
	var skirt := _shape("skirt_bell", s_inst, body, 1, bodice)
	check_vec_near(skirt.map_point(Vector2(0, 0)), body.skirt_to_model(Vector2.ZERO), 1e-3, "detached skirt keeps its own position")
	done()


func test_sleeves_follow_bodice_shoulders() -> void:
	var body := Content.get_body("athletic")
	var b_inst := GarmentInstance.new()
	b_inst.scale = Vector2(1.4, 1.0)
	b_inst.offset = Vector2(0, -15)
	var bodice := _shape("bodice_military", b_inst, body)
	for side in [-1, 1]:
		var sleeve := _shape("sleeve_long_fitted", GarmentInstance.new(), body, side, bodice)
		var anchor := Vector2(BodyDefinition.SHOULDER_ANCHOR.x * side, BodyDefinition.SHOULDER_ANCHOR.y)
		check_vec_near(sleeve.map_point(Vector2.ZERO), bodice.map_point(anchor), 0.5, "sleeve %d shoulder attaches to the deformed bodice" % side)
		check_vec_near(sleeve.map_point(Vector2(0, 1)), body.wrist_point(side) + (bodice.map_point(anchor) - body.bodice_to_model(anchor)) * 0.15, 0.5, "sleeve %d cuff stays near the wrist" % side)
	done()


func test_sleeves_mirror() -> void:
	var body := Content.get_body("classic")
	var l := _shape("sleeve_bell", GarmentInstance.new(), body, -1)
	var r := _shape("sleeve_bell", GarmentInstance.new(), body, 1)
	for p in [Vector2(1, 0.5), Vector2(-1, 1.0), Vector2(2.0, 0.9)]:
		var a := l.map_point(p)
		var b := r.map_point(p)
		check_vec_near(a, Vector2(-b.x, b.y), 1e-3, "left sleeve mirrors right at %s" % str(p))
	done()


func test_cage_drag_solves_to_target() -> void:
	var body := Content.get_body("classic")
	var inst := GarmentInstance.new()
	inst.scale = Vector2(1.3, 0.9)
	inst.rotation = 0.2
	var skirt := _shape("skirt_full_victorian", inst, body)
	var before := skirt.cage_point(2, 3)
	var target := before + Vector2(40, 25)
	var off := skirt.solve_cage_offset(2, 3, target)
	var lat := inst.get_lattice()
	lat[3 * 4 + 2] = off
	inst.lattice = lat
	var after := _shape("skirt_full_victorian", inst, body)
	check_vec_near(after.cage_point(2, 3), target, 0.5, "dragged control point lands under the cursor")
	check(after.map_point(Vector2(2.5, 0.95)).distance_to(skirt.map_point(Vector2(2.5, 0.95))) > 1.0, "cage edit deforms the fabric")
	done()


func test_body_switch_keeps_dress_connected() -> void:
	var d := DesignFactory.default_design()
	d.garment("skirt").scale = Vector2(1.5, 1.0)
	d.garment("bodice").rotation = 0.1
	for b in Content.bodies:
		d.body_id = b.id
		var c := CharacterPresentation.new()
		add_child(c)
		c.set_design(d)
		var bodice: GarmentShape = c.shapes["bodice"]
		var skirt: GarmentShape = c.shapes["skirt"]
		check_vec_near(skirt.map_point(Vector2(0.6, 0.0)), bodice.waist_seam_point(0.6), 0.75, "%s: seam intact after body switch" % b.id)
		check(c.shapes.has("sleeve_left") and c.shapes.has("sleeve_right"), "%s: sleeves rebuilt" % b.id)
		c.queue_free()
	done()
