extends RefCounted
## Authoring source for jewelry. Region 0 = metal, 1 = gem/pearl.
## Units are pixels for the reference ("Classic") body; anchors:
##   earrings -> ear lobe (screen-right, mirrored), necklace -> neck base (centered),
##   bracelet -> wrist (screen-right, mirrored, aligned with the forearm),
##   anklet -> ankle (screen-right, mirrored), tiara -> top of the hair (centered).

const U = preload("res://tools/content/catalog_util.gd")


static func c(hex: String) -> Color:
	return Color.html(hex)


static func j(id: String, name: String, cat: String, shapes: Array, metal: Color, gem: Color) -> JewelryDefinition:
	var d := JewelryDefinition.new()
	d.id = id
	d.display_name = name
	d.category = cat
	var typed: Array[Dictionary] = []
	for s in shapes:
		if s is Array:
			for x in s:
				typed.append(x)
		else:
			typed.append(s)
	d.shapes = typed
	d.default_metal = metal
	d.default_gem = gem
	return d


static func beads_on(path: PackedVector2Array, spacing: float, r: float, region: int = 1) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var carry := 0.0
	for i in range(path.size() - 1):
		var a := path[i]
		var b := path[i + 1]
		var seg := a.distance_to(b)
		var t := carry
		while t <= seg:
			out.append(U.circle(region, a.lerp(b, t / maxf(seg, 0.001)), r))
			t += spacing
		carry = t - seg
	return out


static func ring(center: Vector2, rx: float, ry: float, front_only: bool = true) -> PackedVector2Array:
	return U.ellipse(center, rx, ry, 0 if front_only else 0, 180 if front_only else 360, 14)


static func star(center: Vector2, r_out: float, r_in: float, points: int = 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(points * 2):
		var a := -PI / 2 + PI * i / points
		var r := r_out if i % 2 == 0 else r_in
		out.append(center + Vector2(cos(a), sin(a)) * r)
	return out


static func build() -> Array[JewelryDefinition]:
	var list: Array[JewelryDefinition] = []
	var gold := c("d4af37")
	var silver := c("cfd3d6")
	var pearl := c("f4efe6")

	# --- earrings (anchor: ear lobe)
	list.append(j("earring_pearl_stud", "Pearl Studs", "earrings", [U.circle(1, Vector2(0, 2), 3.2)], gold, pearl))
	list.append(j("earring_drop_pearl", "Drop Pearls", "earrings", [U.line(0, U.v([[0, 0], [0, 9]]), 1.4), U.circle(0, Vector2(0, 1), 1.8), U.circle(1, Vector2(0, 12), 3.6)], gold, pearl))
	list.append(j("earring_chandelier", "Chandelier Earrings", "earrings", [
		U.circle(0, Vector2(0, 1), 1.8), U.line(0, U.v([[0, 1], [0, 6]]), 1.2),
		U.line(0, U.v([[-5, 10], [0, 6], [5, 10]]), 1.2), U.line(0, U.v([[-5, 10], [-6, 16], [0, 19], [6, 16], [5, 10]]), 1.2),
		U.circle(1, Vector2(-6, 17), 1.8), U.circle(1, Vector2(0, 20), 2.4), U.circle(1, Vector2(6, 17), 1.8)], gold, c("c1121f")))
	list.append(j("earring_hoop", "Gold Hoops", "earrings", [U.line(0, U.ellipse(Vector2(0, 8), 6.5, 7.5, -90, 270, 20), 1.8)], gold, pearl))
	list.append(j("earring_teardrop", "Teardrop Gems", "earrings", [U.circle(0, Vector2(0, 1), 2.0), U.line(0, U.v([[0, 1], [0, 5]]), 1.2),
		U.poly(1, U.v([[0, 5], [3.5, 11], [3, 14], [0, 16], [-3, 14], [-3.5, 11]])), U.line(0, U.v([[0, 5], [3.5, 11], [3, 14], [0, 16], [-3, 14], [-3.5, 11], [0, 5]]), 0.8)], silver, c("3a86ff")))

	# --- necklaces (anchor: neck base, x across, +y down the chest)
	var curve := U.ellipse(Vector2(0, -4), 26, 24, 180, 0, 18)
	list.append(j("necklace_pearl_strand", "Pearl Strand", "necklace", [beads_on(_reverse(curve), 4.6, 2.4)], gold, pearl))
	list.append(j("necklace_cameo_choker", "Cameo Choker", "necklace", [
		U.line(1, U.v([[-15, -9], [0, -6], [15, -9]]), 5.0, 0.8),
		U.poly(0, U.ellipse(Vector2(0, -2), 6.5, 8, 0, 360, 16)), U.poly(1, U.ellipse(Vector2(0, -2), 4.5, 6, 0, 360, 16), 1.15)], gold, c("2b2d42")))
	var chain := U.ellipse(Vector2(0, 2), 22, 30, 180, 0, 18)
	list.append(j("necklace_locket", "Heart Locket", "necklace", [U.line(0, chain, 1.1),
		U.poly(0, U.v([[0, 30], [-6, 25], [-7, 21], [-4, 18], [0, 21], [4, 18], [7, 21], [6, 25]])), U.circle(1, Vector2(0, 23), 2.0)], gold, c("e63946")))
	var collar_outer := U.ellipse(Vector2(0, -6), 24, 20, 180, 0, 16)
	var collar_inner := U.ellipse(Vector2(0, -6), 20, 12, 0, 180, 16)
	var collar := _reverse(collar_outer)
	collar.append_array(collar_inner)
	var collar_gems: Array = []
	for k in range(7):
		var a := deg_to_rad(30 + k * 20.0)
		collar_gems.append(U.circle(1, Vector2(0, -6) + Vector2(cos(a) * 22, sin(a) * 16), 2.2))
	list.append(j("necklace_gem_collar", "Jeweled Collar", "necklace", [U.poly(0, collar), collar_gems], gold, c("2a9d8f")))
	list.append(j("necklace_velvet_ribbon", "Velvet Ribbon Choker", "necklace", [U.line(1, U.v([[-15, -10], [0, -7], [15, -10]]), 4.5, 0.9),
		U.line(0, U.v([[0, -6], [0, 0]]), 1.0), U.poly(0, star(Vector2(0, 3), 4.5, 2.0))], silver, c("1b1b3a")))
	var c2 := U.ellipse(Vector2(0, -2), 30, 34, 180, 0, 20)
	list.append(j("necklace_double_strand", "Double Pearl Strand", "necklace", [beads_on(_reverse(curve), 4.6, 2.2), beads_on(_reverse(c2), 4.8, 2.2)], gold, pearl))

	# --- bracelets (anchor: wrist; local x across the forearm)
	list.append(j("bracelet_bangle", "Gold Bangle", "bracelet", [U.line(0, U.ellipse(Vector2(0, -2), 9.5, 3.2, 0, 180, 12), 2.6), U.line(0, U.ellipse(Vector2(0, 1), 9.5, 3.2, 0, 180, 12), 2.0)], gold, pearl))
	list.append(j("bracelet_pearl_cuff", "Pearl Cuff", "bracelet", [beads_on(U.ellipse(Vector2(0, -3), 9, 3, 0, 180, 12), 3.6, 1.8), beads_on(U.ellipse(Vector2(0, 1), 9, 3, 0, 180, 12), 3.6, 1.8)], gold, pearl))
	list.append(j("bracelet_tennis", "Gem Tennis Bracelet", "bracelet", [U.line(0, U.ellipse(Vector2(0, 0), 9.5, 3, 0, 180, 12), 1.6), beads_on(U.ellipse(Vector2(0, 0), 9.5, 3, 0, 180, 12), 3.4, 1.6)], silver, c("8ecae6")))
	var coil: Array = []
	for k in range(3):
		coil.append(U.line(0, U.ellipse(Vector2(0, -5 + k * 4), 9.5, 2.6, 0, 180, 12), 1.8))
	coil.append(U.circle(1, Vector2(9, -5), 1.6))
	list.append(j("bracelet_snake", "Snake Coil", "bracelet", coil, gold, c("06d6a0")))

	# --- anklets (anchor: ankle)
	list.append(j("anklet_chain", "Delicate Chain", "anklet", [U.line(0, U.ellipse(Vector2(0, -2), 11, 3.5, 0, 180, 14), 1.1), U.circle(1, Vector2(0, 3.5), 1.8)], gold, pearl))
	list.append(j("anklet_bells", "Bell Anklet", "anklet", [U.line(0, U.ellipse(Vector2(0, -2), 11, 3.5, 0, 180, 14), 1.4),
		U.circle(1, Vector2(-7, 4), 2.2), U.circle(1, Vector2(0, 5.5), 2.2), U.circle(1, Vector2(7, 4), 2.2)], silver, c("e9c46a")))
	list.append(j("anklet_beads", "Bead String", "anklet", [beads_on(U.ellipse(Vector2(0, -2), 11, 3.5, 0, 180, 14), 3.4, 1.7)], gold, c("e76f51")))
	list.append(j("anklet_gems", "Gem Anklet", "anklet", [U.line(0, U.ellipse(Vector2(0, -2), 11, 3.5, 0, 180, 14), 1.4),
		U.poly(1, U.v([[0, 0], [3, 3.5], [0, 7], [-3, 3.5]])), U.circle(1, Vector2(-6, 2.6), 1.5), U.circle(1, Vector2(6, 2.6), 1.5)], gold, c("9b5de5")))

	# --- tiaras (anchor: crown, the top of the hair; band follows the head curve)
	var band := U.ellipse(Vector2(0, 12), 28, 12, 200, 340, 12)
	list.append(j("tiara_pearl_diadem", "Pearl Diadem", "tiara", [U.line(0, band, 2.4), beads_on(U.ellipse(Vector2(0, 8), 24, 12, 210, 330, 10), 5.5, 2.2),
		U.poly(0, U.v([[-4, 0], [0, -9], [4, 0]])), U.circle(1, Vector2(0, -6), 2.4)], gold, pearl))
	var flowers: Array = [U.line(0, band, 2.0)]
	for k in range(5):
		var a := deg_to_rad(215 + k * 27.5)
		var fc := Vector2(0, 12) + Vector2(cos(a) * 28, sin(a) * 12) + Vector2(0, -2)
		for petal in range(5):
			var pa := TAU * petal / 5.0
			flowers.append(U.circle(1, fc + Vector2(cos(pa), sin(pa)) * 2.6, 2.1))
		flowers.append(U.circle(0, fc, 1.6))
	list.append(j("tiara_floral", "Floral Tiara", "tiara", flowers, gold, c("ffafcc")))
	var spikes := PackedVector2Array()
	for k in range(9):
		var x := lerpf(-24, 24, k / 8.0)
		var base_y := 12.0 - sqrt(maxf(0.0, 1.0 - pow(x / 28.0, 2.0))) * 12.0 + 12.0
		spikes.append(Vector2(x, base_y - (10.0 if k % 2 == 0 else 3.0) - (6.0 if k == 4 else 0.0)))
	var crown := spikes.duplicate()
	crown.append_array(_reverse(U.ellipse(Vector2(0, 14), 24, 10, 205, 335, 10)))
	list.append(j("tiara_crown", "Spiked Crown", "tiara", [U.poly(0, crown), U.circle(1, Vector2(0, -2), 2.8), U.circle(1, Vector2(-12, 3), 2.0), U.circle(1, Vector2(12, 3), 2.0)], gold, c("d00000")))
	list.append(j("tiara_star_circlet", "Star Circlet", "tiara", [U.line(0, band, 1.8), U.poly(1, star(Vector2(0, -1), 8, 3.5)), U.line(0, star(Vector2(0, -1), 8, 3.5) + PackedVector2Array([star(Vector2(0, -1), 8, 3.5)[0]]), 0.8)], silver, c("ffd60a")))
	list.append(j("tiara_feather", "Feather Fascinator", "tiara", [
		U.poly(1, U.v([[14, 6], [20, -18], [26, -30], [24, -14], [20, 4]])), U.poly(1, U.v([[16, 6], [30, -10], [38, -14], [30, 0], [20, 8]]), 0.85),
		U.line(0, U.v([[18, 5], [24, -24]]), 0.8), U.circle(0, Vector2(17, 6), 4.0), U.circle(1, Vector2(17, 6), 2.0, 1.2)], gold, c("264653")))

	return list


static func _reverse(p: PackedVector2Array) -> PackedVector2Array:
	var out := p.duplicate()
	out.reverse()
	return out
