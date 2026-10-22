extends RefCounted
## Authoring source for the 30 hairstyles (20 single-color + 10 multicolor).
## Head-local units: origin at the head center, 1 = head radius, +y down.
## The face spans roughly x in [-1, 1], y in [-1.15, 1.15]; shoulders are near y = 1.9.

const U = preload("res://tools/content/catalog_util.gd")
const STRAND := 0.035


static func c(hex: String) -> Color:
	return Color.html(hex)


# ----------------------------------------------------------------- building blocks
static func hairline(kind: String) -> PackedVector2Array:
	match kind:
		"bangs":
			var pts := U.v([[1.0, 0.15], [0.96, -0.2]])
			pts.append_array(U.scallops(Vector2(0.9, -0.3), Vector2(-0.9, -0.3), 6, -0.06))
			pts.append_array(U.v([[-0.96, -0.2], [-1.0, 0.15]]))
			return pts
		"side":
			return U.v([[1.0, 0.15], [0.92, -0.35], [0.6, -0.62], [0.3, -0.58], [0.0, -0.42], [-0.4, -0.28], [-0.8, -0.12], [-1.02, 0.22]])
		"high":
			return U.v([[1.0, 0.0], [0.85, -0.45], [0.45, -0.7], [0.0, -0.76], [-0.45, -0.7], [-0.85, -0.45], [-1.0, 0.0]])
		"waves":
			var w := U.v([[1.0, 0.15], [0.95, -0.25], [0.7, -0.45], [0.4, -0.3], [0.1, -0.5], [-0.2, -0.32], [-0.5, -0.52], [-0.8, -0.35], [-0.97, -0.1], [-1.0, 0.15]])
			return w
		_:
			return U.v([[1.0, 0.15], [0.9, -0.3], [0.6, -0.6], [0.2, -0.62], [0.0, -0.55], [-0.2, -0.62], [-0.6, -0.6], [-0.9, -0.3], [-1.0, 0.15]])


## The hair covering the top of the head (front layer).
static func cap(kind: String, vol: float = 1.05, top_extra: float = 0.0) -> PackedVector2Array:
	var arc := U.ellipse(Vector2(0, -0.08), 1.1 * vol, 1.2 * vol + top_extra, 180, 360, 18)
	var pts := arc
	pts.append_array(hairline(kind))
	return pts


static func cap_strands(kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var part := Vector2(0.0, -1.2) if kind != "side" else Vector2(0.35, -1.18)
	for x in [-0.7, -0.35, 0.35, 0.7]:
		var end := Vector2(x * 1.15, -0.45 + absf(x) * 0.25)
		var mid := part.lerp(end, 0.5) + Vector2(x * 0.15, -0.05)
		out.append(U.line(0, U.v([[part.x, part.y + 0.05], [mid.x, mid.y], [end.x, end.y]]), STRAND, 0.78))
	return out


static func long_back(length: float, width: float, wave_amp: float = 0.0, bottom: String = "round") -> PackedVector2Array:
	var top := U.ellipse(Vector2(0, -0.1), 1.15, 1.28, 180, 360, 14)
	var right := U.v([[1.18, 0.2], [width * 0.92, 1.3], [width, length * 0.65], [width * 0.95, length]])
	if wave_amp > 0.0:
		right = U.wave(right, 2, wave_amp)
	var pts := top
	pts.append_array(right)
	match bottom:
		"straight":
			pts.append(Vector2(0, length + 0.02))
		"points":
			pts.append_array(U.v([[width * 0.6, length - 0.25], [width * 0.3, length + 0.05], [0, length - 0.2], [-width * 0.3, length + 0.05], [-width * 0.6, length - 0.25]]))
		_:
			pts.append_array(U.scallops(Vector2(width * 0.95, length), Vector2(-width * 0.95, length), 4, -0.12).slice(1, -1))
	var left := U.mirror_x(right)
	left.reverse()
	pts.append_array(left)
	return pts


static func side_lock(length: float, side: int, wave_amp: float = 0.0, width: float = 0.32) -> PackedVector2Array:
	var outer := U.v([[1.08, -0.15], [1.2, 0.5], [1.3, length * 0.6], [1.28 + width * 0.3, length]])
	var inner := U.v([[1.28 - width, length - 0.2], [1.25 - width * 1.4, length * 0.55], [0.95, 0.6], [0.88, 0.1]])
	if wave_amp > 0.0:
		outer = U.wave(outer, 2, wave_amp)
		inner = U.wave(inner, 2, wave_amp)
	var pts := outer
	pts.append_array(inner)
	return pts if side > 0 else U.mirror_x(pts)


static func lock_strands(length: float, side: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in range(2):
		var x := (1.08 + k * 0.1) * side
		out.append(U.line(0, U.v([[x, 0.2], [x + 0.05 * side, length * 0.5], [x + 0.08 * side, length - 0.3]]), STRAND, 0.78))
	return out


static func bun(center: Vector2, r: float, region: int = 0) -> Array[Dictionary]:
	return [
		U.circle(region, center, r),
		U.line(region, U.ellipse(center, r * 0.6, r * 0.55, 200, 520, 14), STRAND, 0.75),
	]


static func curl_column(from: Vector2, to: Vector2, count: int, r: float, regions: Array = [0]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(count):
		var p := from.lerp(to, float(i) / maxf(count - 1, 1))
		var reg: int = regions[i % regions.size()]
		out.append(U.circle(reg, p, r * (1.0 - 0.15 * float(i) / count)))
		out.append(U.line(reg, U.ellipse(p, r * 0.5, r * 0.5, 0, 300, 8), STRAND * 0.8, 0.75))
	return out


static func braid(path: PackedVector2Array, count: int, w: float, regions: Array = [0]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var total := 0.0
	for i in range(path.size() - 1):
		total += path[i].distance_to(path[i + 1])
	for i in range(count):
		var t := (i + 0.5) / count * total
		var acc := 0.0
		var pos := path[0]
		var dir := Vector2.DOWN
		for j in range(path.size() - 1):
			var seg := path[j].distance_to(path[j + 1])
			if acc + seg >= t:
				dir = (path[j + 1] - path[j]).normalized()
				pos = path[j].lerp(path[j + 1], (t - acc) / seg)
				break
			acc += seg
		var nrm := Vector2(-dir.y, dir.x)
		var off := nrm * w * 0.28 * (1 if i % 2 == 0 else -1)
		var seg_len := total / count
		var e := PackedVector2Array()
		for k in range(12):
			var a := TAU * k / 12.0
			e.append(pos + off + dir * cos(a) * seg_len * 0.75 + nrm * sin(a) * w * 0.55)
		out.append(U.poly(regions[i % regions.size()], e))
		out.append(U.line(regions[i % regions.size()], U.v([[(pos + off - nrm * w * 0.3).x, (pos + off - nrm * w * 0.3).y], [(pos + off + nrm * w * 0.3 + dir * seg_len * 0.3).x, (pos + off + nrm * w * 0.3 + dir * seg_len * 0.3).y]]), STRAND, 0.75))
	return out


static func bumpy_circle(center: Vector2, r: float, bumps: int, amp: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := bumps * 6
	for i in range(n):
		var a := TAU * i / n
		var rr := r + absf(sin(a * bumps * 0.5)) * amp
		pts.append(center + Vector2(cos(a), sin(a)) * rr)
	return pts


static func with_region(shapes: Array[Dictionary], region: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in shapes:
		var d: Dictionary = s.duplicate(true)
		d["r"] = region
		out.append(d)
	return out


## Recolors shapes by clipping them against region polygons: [[polygon, color_index], ...].
static func split(shapes: Array[Dictionary], regions: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in shapes:
		if s["k"] == "poly":
			for reg in regions:
				for piece in Geometry2D.intersect_polygons(s["p"], reg[0]):
					var d: Dictionary = s.duplicate(true)
					d["p"] = piece
					d["r"] = reg[1]
					out.append(d)
		else:
			var pts: PackedVector2Array = s["p"]
			var probe: Vector2 = pts[pts.size() / 2]
			var d2: Dictionary = s.duplicate(true)
			for reg in regions:
				if Geometry2D.is_point_in_polygon(probe, reg[0]):
					d2["r"] = reg[1]
					break
			out.append(d2)
	return out


static func half_plane(left: bool) -> PackedVector2Array:
	return U.v([[-10, -10], [0, -10], [0, 10], [-10, 10]]) if left else U.v([[0, -10], [10, -10], [10, 10], [0, 10]])


static func band(y0: float, y1: float) -> PackedVector2Array:
	return U.v([[-10, y0], [10, y0], [10, y1], [-10, y1]])


static func hair(id: String, name: String, back: Array[Dictionary], front: Array[Dictionary], crown: float, colors: Array, color_names: Array = ["Hair"]) -> HairDefinition:
	var h := HairDefinition.new()
	h.id = id
	h.display_name = name
	h.back_shapes = back
	h.front_shapes = front
	h.crown_height = crown
	h.color_count = colors.size()
	h.default_colors = PackedColorArray(colors)
	h.color_names = PackedStringArray(color_names)
	return h


static func arr(items: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for it in items:
		if it is Array:
			for x in it:
				out.append(x)
		else:
			out.append(it)
	return out


# ----------------------------------------------------------------- catalog
static func build() -> Array[HairDefinition]:
	var list: Array[HairDefinition] = []
	var brown := c("5a3825")
	var auburn := c("8a3b1e")
	var blonde := c("d9b26f")
	var black := c("1f1712")
	var chestnut := c("6e4123")
	var copper := c("b5562b")
	var ash := c("a89f91")
	var red := c("a32b1a")

	# --- single-color hairstyles
	var updo_back := arr([bun(Vector2(0, -1.3), 0.5)])
	var updo_front := arr([U.poly(0, cap("high", 1.06)), cap_strands("high"),
		curl_column(Vector2(1.0, -0.05), Vector2(1.06, 0.35), 3, 0.13), curl_column(Vector2(-1.0, -0.05), Vector2(-1.06, 0.35), 3, 0.13)])
	list.append(hair("hair_victorian_updo", "Victorian Updo", updo_back, updo_front, 0.55, [chestnut]))

	list.append(hair("hair_low_chignon", "Low Chignon", arr([U.circle(0, Vector2(0.92, 0.72), 0.34), U.circle(0, Vector2(-0.92, 0.72), 0.34)]),
		arr([U.poly(0, cap("center", 1.03)), cap_strands("center")]), 0.1, [brown]))

	list.append(hair("hair_long_straight", "Long Straight", arr([U.poly(0, long_back(4.2, 1.45, 0.0, "straight"))]),
		arr([U.poly(0, cap("center")), cap_strands("center"), U.poly(0, side_lock(3.0, 1)), U.poly(0, side_lock(3.0, -1)), lock_strands(3.0, 1), lock_strands(3.0, -1)]), 0.12, [black]))

	var curly_back := arr([U.poly(0, long_back(3.6, 1.65, 0.12)),
		curl_column(Vector2(1.45, 0.6), Vector2(1.7, 3.3), 6, 0.3), curl_column(Vector2(-1.45, 0.6), Vector2(-1.7, 3.3), 6, 0.3)])
	list.append(hair("hair_long_curly", "Long Curly", curly_back,
		arr([U.poly(0, cap("side", 1.12)), curl_column(Vector2(1.08, -0.3), Vector2(1.2, 0.5), 3, 0.22), curl_column(Vector2(-1.08, -0.3), Vector2(-1.2, 0.5), 3, 0.22)]), 0.18, [auburn]))

	list.append(hair("hair_side_braid", "Side Braid", arr([U.poly(0, long_back(1.3, 1.3, 0.0, "round"))]),
		arr([U.poly(0, cap("side")), cap_strands("side"), braid(U.v([[0.95, 0.3], [1.3, 1.5], [1.4, 3.4]]), 8, 0.42), U.circle(0, Vector2(1.42, 3.6), 0.12, 0.8)]), 0.1, [blonde]))

	list.append(hair("hair_bob", "Short Bob", arr([U.poly(0, long_back(1.25, 1.35, 0.0, "straight"))]),
		arr([U.poly(0, cap("bangs")), U.poly(0, side_lock(1.25, 1, 0.0, 0.25)), U.poly(0, side_lock(1.25, -1, 0.0, 0.25))]), 0.15, [black]))

	list.append(hair("hair_loose_waves", "Loose Waves", arr([U.poly(0, long_back(2.5, 1.55, 0.09))]),
		arr([U.poly(0, cap("waves")), cap_strands("center"), U.poly(0, side_lock(2.3, 1, 0.06)), U.poly(0, side_lock(2.3, -1, 0.06))]), 0.15, [copper]))

	list.append(hair("hair_gibson", "Gibson Girl Pompadour", arr([bun(Vector2(0, -1.62), 0.32), U.circle(0, Vector2(0.85, -0.6), 0.45), U.circle(0, Vector2(-0.85, -0.6), 0.45)]),
		arr([U.poly(0, cap("high", 1.18, 0.35)), cap_strands("high")]), 0.65, [chestnut]))

	var pony := U.v([[-0.2, -1.3], [0.3, -1.48], [1.1, -1.25], [1.6, -0.3], [1.75, 1.0], [1.45, 2.3], [1.25, 1.1], [1.05, -0.35], [0.4, -1.08]])
	list.append(hair("hair_high_ponytail", "High Ponytail", arr([U.poly(0, pony), U.line(0, U.v([[1.1, -0.9], [1.45, 0.6], [1.45, 2.0]]), STRAND, 0.75)]),
		arr([U.poly(0, cap("high", 1.04)), cap_strands("high"), U.circle(0, Vector2(0.15, -1.38), 0.13, 0.7)]), 0.35, [blonde]))

	var asym_back := U.v([[-1.15, -0.1], [-0.9, -0.85], [0.0, -1.38], [0.9, -0.85], [1.18, 0.1], [1.45, 1.4], [1.55, 3.0], [1.1, 3.1], [0.9, 1.5], [-0.9, 0.6], [-1.25, 0.75]])
	list.append(hair("hair_asymmetric", "Asymmetric Side-Swept", arr([U.poly(0, asym_back)]),
		arr([U.poly(0, cap("side", 1.08)), cap_strands("side"), U.poly(0, side_lock(2.8, 1, 0.04, 0.4))]), 0.12, [red]))

	var pixie := cap("side", 1.02)
	list.append(hair("hair_pixie", "Pixie Crop", [] as Array[Dictionary],
		arr([U.poly(0, pixie), U.poly(0, U.v([[-1.02, 0.0], [-0.92, 0.0], [-0.94, 0.45], [-1.04, 0.4]])), U.poly(0, U.v([[1.02, 0.0], [0.92, 0.0], [0.94, 0.45], [1.04, 0.4]])),
			U.line(0, U.v([[0.3, -1.1], [-0.2, -0.6], [-0.7, -0.4]]), STRAND, 0.75), U.line(0, U.v([[0.6, -1.0], [0.4, -0.6]]), STRAND, 0.75)]), 0.12, [ash]))

	list.append(hair("hair_ringlets", "Victorian Ringlets", arr([curl_column(Vector2(1.25, 0.2), Vector2(1.45, 2.2), 6, 0.2), curl_column(Vector2(-1.25, 0.2), Vector2(-1.45, 2.2), 6, 0.2)]),
		arr([U.poly(0, cap("center", 1.06)), cap_strands("center"), curl_column(Vector2(1.05, 0.1), Vector2(1.12, 1.6), 5, 0.17), curl_column(Vector2(-1.05, 0.1), Vector2(-1.12, 1.6), 5, 0.17)]), 0.25, [brown]))

	list.append(hair("hair_double_buns", "Double Buns", arr([bun(Vector2(0.75, -1.05), 0.42), bun(Vector2(-0.75, -1.05), 0.42)]),
		arr([U.poly(0, cap("center")), cap_strands("center")]), 0.3, [c("2b1b17")]))

	list.append(hair("hair_crown_braid", "Crown Braid", [] as Array[Dictionary],
		arr([U.poly(0, cap("high", 1.04)), braid(U.ellipse(Vector2(0, -0.2), 1.08, 1.1, 185, 355, 10), 11, 0.36)]), 0.28, [blonde]))

	var tail_r := U.v([[0.85, -0.75], [1.3, -0.55], [1.9, 0.6], [2.15, 2.0], [1.95, 2.9], [1.7, 2.0], [1.35, 0.8], [0.95, -0.2]])
	list.append(hair("hair_twin_tails", "Twin Tails", arr([U.poly(0, tail_r), U.poly(0, U.mirror_x(tail_r))]),
		arr([U.poly(0, cap("bangs")), U.circle(0, Vector2(1.05, -0.6), 0.14, 0.7), U.circle(0, Vector2(-1.05, -0.6), 0.14, 0.7)]), 0.15, [c("3e2a20")]))

	list.append(hair("hair_voluminous_curls", "Voluminous Curls", arr([U.poly(0, bumpy_circle(Vector2(0, -0.35), 1.65, 14, 0.18))]),
		arr([U.poly(0, cap("high", 1.08)), curl_column(Vector2(-0.7, -0.8), Vector2(0.7, -0.8), 5, 0.17)]), 0.75, [c("1b1210")]))

	var fw_cap := cap("waves", 1.02)
	list.append(hair("hair_finger_waves", "Finger Waves", arr([U.poly(0, long_back(1.0, 1.25, 0.05, "round"))]),
		arr([U.poly(0, fw_cap), U.line(0, U.wave(U.v([[-0.9, -0.75], [0.9, -0.75]]), 3, 0.08), STRAND * 1.3, 0.7), U.line(0, U.wave(U.v([[-1.0, -0.35], [1.0, -0.35]]), 3, 0.08), STRAND * 1.3, 0.7)]), 0.08, [c("2a1d18")]))

	var hive := U.v([[-1.12, 0.0], [-1.15, -0.9], [-0.9, -1.8], [-0.4, -2.35], [0.0, -2.45], [0.4, -2.35], [0.9, -1.8], [1.15, -0.9], [1.12, 0.0]])
	list.append(hair("hair_beehive", "Beehive", arr([U.poly(0, hive), U.line(0, U.ellipse(Vector2(0, -1.3), 0.7, 0.8, 200, 340, 8), STRAND, 0.75)]),
		arr([U.poly(0, cap("high", 1.05)), cap_strands("high")]), 1.25, [c("c78f4a")]))

	list.append(hair("hair_cascade", "Waist-Length Cascade", arr([U.poly(0, long_back(6.0, 1.75, 0.1, "points"))]),
		arr([U.poly(0, cap("center", 1.07)), cap_strands("center"), U.poly(0, side_lock(5.0, 1, 0.08)), U.poly(0, side_lock(5.0, -1, 0.08)), lock_strands(5.0, 1), lock_strands(5.0, -1)]), 0.12, [c("c9a26b")]))

	var crest := U.v([[-0.2, -0.6], [-0.35, -1.0], [-0.15, -1.15], [-0.3, -1.55], [0.0, -1.45], [0.05, -1.95], [0.25, -1.4], [0.55, -1.7], [0.45, -1.15], [0.8, -1.25], [0.45, -0.85], [0.25, -0.6]])
	list.append(hair("hair_punk_crest", "Punk Crest", [] as Array[Dictionary],
		arr([U.poly(0, cap("high", 1.0), 0.55), U.poly(0, crest)]), 0.9, [c("7b2cbf")]))

	# --- multicolor hairstyles
	var hl_front := arr([U.poly(0, cap("waves")), U.poly(0, side_lock(2.3, 1, 0.06)), U.poly(0, side_lock(2.3, -1, 0.06)),
		U.poly(1, U.v([[0.3, -1.15], [0.55, -1.05], [0.75, -0.5], [0.6, -0.48]])), U.poly(1, U.v([[-0.2, -1.2], [-0.45, -1.1], [-0.6, -0.5], [-0.45, -0.48]])),
		U.line(1, U.wave(U.v([[1.2, 0.2], [1.3, 2.0]]), 2, 0.05), 0.08), U.line(1, U.wave(U.v([[-1.2, 0.2], [-1.3, 2.0]]), 2, 0.05), 0.08)])
	list.append(hair("hair_highlighted_waves", "Highlighted Waves", arr([U.poly(0, long_back(2.5, 1.55, 0.09)), U.line(1, U.wave(U.v([[1.4, 0.5], [1.5, 2.3]]), 2, 0.06), 0.1)]),
		hl_front, 0.15, [brown, c("e0b46c")], ["Base", "Highlights"]))

	var split_back := split(arr([U.poly(0, long_back(4.0, 1.45, 0.0, "straight"))]), [[half_plane(true), 0], [half_plane(false), 1]])
	var split_front := split(arr([U.poly(0, cap("center")), U.poly(0, side_lock(3.0, 1)), U.poly(0, side_lock(3.0, -1)), cap_strands("center")]), [[half_plane(true), 0], [half_plane(false), 1]])
	list.append(hair("hair_two_tone_split", "Two-Tone Split", split_back, split_front, 0.12, [c("111111"), c("f2f2f2")], ["Left", "Right"]))

	var bands := [[band(-10, 1.3), 0], [band(1.3, 3.1), 1], [band(3.1, 10), 2]]
	list.append(hair("hair_ombre_long", "Ombré Cascade", split(arr([U.poly(0, long_back(5.0, 1.7, 0.08, "points"))]), bands),
		split(arr([U.poly(0, cap("center", 1.06)), U.poly(0, side_lock(4.2, 1, 0.06)), U.poly(0, side_lock(4.2, -1, 0.06))]), bands), 0.12,
		[c("3b2416"), c("b0643a"), c("f2c38b")], ["Roots", "Middle", "Tips"]))

	list.append(hair("hair_streaked_bob", "Streaked Bob", arr([U.poly(0, long_back(1.25, 1.35, 0.0, "straight")), U.poly(1, U.v([[1.0, 0.1], [1.25, 0.2], [1.3, 1.25], [1.05, 1.25]]))]),
		arr([U.poly(0, cap("bangs")), U.poly(0, side_lock(1.25, 1, 0.0, 0.25)), U.poly(0, side_lock(1.25, -1, 0.0, 0.25)),
			U.poly(1, U.v([[0.35, -1.15], [0.6, -1.0], [0.5, -0.3], [0.32, -0.3]])), U.poly(2, U.v([[-0.4, -1.12], [-0.62, -0.98], [-0.6, -0.3], [-0.42, -0.3]]))]), 0.15,
		[c("1a1a1a"), c("ff006e"), c("3a86ff")], ["Base", "Streak 1", "Streak 2"]))

	list.append(hair("hair_tricolor_braid", "Three-Color Braid", arr([U.poly(0, long_back(1.3, 1.3))]),
		arr([U.poly(0, cap("side")), braid(U.v([[0.95, 0.3], [1.3, 1.5], [1.4, 3.6]]), 10, 0.42, [0, 1, 2]), U.circle(2, Vector2(1.42, 3.8), 0.12, 0.8)]), 0.1,
		[c("d9b26f"), c("e07a5f"), c("3d405b")], ["Strand 1", "Strand 2", "Strand 3"]))

	list.append(hair("hair_peekaboo", "Peekaboo Underlayer", arr([U.poly(1, long_back(3.6, 1.55, 0.0, "straight"))]),
		arr([U.poly(0, cap("side", 1.06)), cap_strands("side"), U.poly(0, side_lock(2.4, 1)), U.poly(0, side_lock(2.4, -1))]), 0.12,
		[c("2d1e17"), c("06d6a0")], ["Top", "Underlayer"]))

	var pony2 := arr([U.poly(0, pony)])
	list.append(hair("hair_dip_dyed_pony", "Dip-Dyed Ponytail", split(pony2, [[band(-10, 0.9), 0], [band(0.9, 10), 1]]),
		arr([U.poly(0, cap("high", 1.04)), cap_strands("high"), U.circle(0, Vector2(0.15, -1.38), 0.13, 0.7)]), 0.35,
		[c("e8d3a9"), c("ef476f")], ["Hair", "Dyed Tips"]))

	list.append(hair("hair_rainbow_ringlets", "Rainbow Ringlets", arr([curl_column(Vector2(1.25, 0.2), Vector2(1.45, 2.2), 6, 0.2, [0, 1, 2]), curl_column(Vector2(-1.25, 0.2), Vector2(-1.45, 2.2), 6, 0.2, [2, 1, 0])]),
		arr([U.poly(0, cap("center", 1.06)), curl_column(Vector2(1.05, 0.1), Vector2(1.12, 1.6), 5, 0.17, [1, 2, 0]), curl_column(Vector2(-1.05, 0.1), Vector2(-1.12, 1.6), 5, 0.17, [1, 0, 2])]), 0.25,
		[c("ff99c8"), c("a9def9"), c("fcf6bd")], ["Color 1", "Color 2", "Color 3"]))

	list.append(hair("hair_tipped_updo", "Tipped Updo", with_region(arr([bun(Vector2(0, -1.3), 0.5)]), 1),
		arr([U.poly(0, cap("high", 1.06)), cap_strands("high"), curl_column(Vector2(1.0, -0.05), Vector2(1.06, 0.35), 3, 0.13, [2]), curl_column(Vector2(-1.0, -0.05), Vector2(-1.06, 0.35), 3, 0.13, [2])]), 0.55,
		[c("4a2f23"), c("c1666b"), c("f4e285")], ["Base", "Bun", "Curls"]))

	list.append(hair("hair_halo_braid", "Halo Ribbon Braid", [] as Array[Dictionary],
		arr([U.poly(0, cap("high", 1.04)), braid(U.ellipse(Vector2(0, -0.2), 1.08, 1.1, 185, 355, 10), 11, 0.36, [1]),
			U.line(2, U.wave(U.ellipse(Vector2(0, -0.2), 1.08, 1.1, 185, 355, 16), 6, 0.05), 0.07)]), 0.28,
		[c("6f4e37"), c("e6c79c"), c("9d4edd")], ["Hair", "Braid", "Ribbon"]))

	return list
