extends RefCounted
## Authoring source for the 20 shoe designs, built from a parametric profile.
## Coordinates: pixels, origin on the floor below the ankle, toe toward +x, -y up.

const U = preload("res://tools/content/catalog_util.gd")
const ST := 3.0  # sole thickness


static func c(hex: String) -> Color:
	return Color.html(hex)


static func build() -> Array[ShoeDefinition]:
	var list: Array[ShoeDefinition] = []
	list.append(shoe("shoe_button_boot", "Victorian Button Boot", {"h": 10, "heel": "louis", "shaft": 46, "toe": "round", "buttons": true, "toe_cap": true},
		{"upper": c("3b2a20"), "sole": c("1a1410"), "heel": c("2a1e16"), "accent": c("6b4a33"), "detail": c("d9c9a3")}, {"accent": "Toe Cap", "detail": "Buttons"}))
	list.append(shoe("shoe_lace_boot", "Lace-Up Granny Boot", {"h": 12, "heel": "block", "shaft": 52, "toe": "point", "laces": true},
		{"upper": c("5a1f2a"), "sole": c("1a1410"), "heel": c("1a1410"), "detail": c("f2e6cf")}, {"detail": "Laces"}))
	list.append(shoe("shoe_court", "Low Court Heel", {"h": 12, "heel": "louis", "toe": "point", "collar": 11},
		{"upper": c("1f3a5f"), "sole": c("141414"), "heel": c("1f3a5f")}, {}))
	list.append(shoe("shoe_stiletto", "High Stiletto Pump", {"h": 34, "heel": "stiletto", "toe": "point", "collar": 10},
		{"upper": c("b0002a"), "sole": c("111111"), "heel": c("b0002a")}, {}))
	list.append(shoe("shoe_slipper", "Embroidered Slipper", {"h": 2, "heel": "flat", "toe": "round", "open": true, "bow": true, "gems": 3},
		{"upper": c("7a9e7e"), "sole": c("e8dcc4"), "heel": c("e8dcc4"), "detail": c("f5d38a")}, {"detail": "Embroidery"}))
	list.append(shoe("shoe_ankle_boot", "Ankle Boot", {"h": 14, "heel": "block", "shaft": 22, "toe": "round", "pull_tab": true},
		{"upper": c("6b4226"), "sole": c("2a1a10"), "heel": c("2a1a10"), "accent": c("c9a46a")}, {"accent": "Pull Tab"}))
	list.append(shoe("shoe_buckled", "Buckled Shoe", {"h": 8, "heel": "block", "toe": "square", "buckle": true, "collar": 14},
		{"upper": c("1c1c1c"), "sole": c("3a2a1e"), "heel": c("3a2a1e"), "detail": c("d8d8d8")}, {"detail": "Buckle"}))
	list.append(shoe("shoe_mary_jane", "Mary Jane", {"h": 6, "heel": "block", "toe": "round", "strap": true, "collar": 10},
		{"upper": c("8c1c13"), "sole": c("1a1a1a"), "heel": c("1a1a1a"), "accent": c("8c1c13"), "detail": c("f2e6cf")}, {"accent": "Strap", "detail": "Button"}))
	list.append(shoe("shoe_evening", "Formal Evening Shoe", {"h": 22, "heel": "louis", "toe": "point", "bow": true, "gems": 1, "collar": 10},
		{"upper": c("f0e4d0"), "sole": c("8a7a60"), "heel": c("f0e4d0"), "detail": c("d4af37")}, {"detail": "Bow & Gem"}))
	list.append(shoe("shoe_platform", "Unconventional Platform", {"h": 36, "p": 18, "heel": "block", "toe": "round", "collar": 13},
		{"upper": c("ff70a6"), "sole": c("ffd670"), "heel": c("70d6ff")}, {}))
	list.append(shoe("shoe_curl_toe", "Fairy Curl-Toe Slipper", {"h": 2, "heel": "flat", "toe": "curl", "open": true, "pompom": true},
		{"upper": c("6a4c93"), "sole": c("1982c4"), "heel": c("1982c4"), "detail": c("ffca3a")}, {"detail": "Pompom"}))
	list.append(shoe("shoe_riding", "Tall Riding Boot", {"h": 8, "heel": "block", "shaft": 82, "toe": "round", "cuff": 10},
		{"upper": c("2b1d14"), "sole": c("120c08"), "heel": c("120c08"), "accent": c("8b5a2b")}, {"accent": "Cuff"}))
	list.append(shoe("shoe_spats", "Spat Shoes", {"h": 6, "heel": "block", "toe": "round", "spats": true, "collar": 14},
		{"upper": c("141414"), "sole": c("3b3b3b"), "heel": c("3b3b3b"), "accent": c("e8e1d0"), "detail": c("6b6b6b")}, {"accent": "Spats", "detail": "Buttons"}))
	list.append(shoe("shoe_ballet_flat", "Ballet Flat", {"h": 1, "heel": "flat", "toe": "round", "open": true, "bow": true},
		{"upper": c("f4c2c2"), "sole": c("c79a9a"), "heel": c("c79a9a"), "detail": c("e07a8f")}, {"detail": "Bow"}))
	list.append(shoe("shoe_pointe", "Ribbon Pointe Slipper", {"h": 1, "heel": "flat", "toe": "square", "open": true, "ribbons": true},
		{"upper": c("f7d6d0"), "sole": c("b88b84"), "heel": c("b88b84"), "detail": c("f7d6d0")}, {"detail": "Ribbons"}))
	list.append(shoe("shoe_wedge", "Rope Wedge", {"h": 22, "heel": "wedge", "toe": "round", "ankle_ties": true, "collar": 10},
		{"upper": c("e9d8a6"), "sole": c("6b4f2a"), "heel": c("c8a165"), "detail": c("1d3557")}, {"detail": "Ankle Ties"}))
	list.append(shoe("shoe_winged", "Winged Fantasy Boot", {"h": 16, "heel": "block", "shaft": 40, "toe": "point", "wings": true},
		{"upper": c("e5e5e5"), "sole": c("8d99ae"), "heel": c("8d99ae"), "detail": c("ffd166")}, {"detail": "Wings"}))
	list.append(shoe("shoe_clog", "Painted Clog", {"h": 8, "p": 6, "heel": "block", "toe": "round", "collar": 18, "toe_cap": true},
		{"upper": c("d9a441"), "sole": c("7a4b23"), "heel": c("7a4b23"), "accent": c("c44536")}, {"accent": "Painted Toe"}))
	list.append(shoe("shoe_cavalier", "Cavalier Cuff Boot", {"h": 10, "heel": "louis", "shaft": 70, "toe": "square", "cuff": 20, "buckle": true},
		{"upper": c("3d2b1f"), "sole": c("1a120c"), "heel": c("1a120c"), "accent": c("5c4033"), "detail": c("d4af37")}, {"accent": "Cuff", "detail": "Buckle"}))
	list.append(shoe("shoe_crystal", "Crystal Heel", {"h": 28, "heel": "stiletto", "toe": "point", "gems": 7, "collar": 9},
		{"upper": c("bde0fe"), "sole": c("a2d2ff"), "heel": c("cdb4db"), "detail": c("ffffff")}, {"detail": "Crystals"}))
	return list


## Builds a ShoeDefinition from profile parameters. Region keys: upper, sole, heel, accent, detail.
static func shoe(id: String, name: String, o: Dictionary, colors: Dictionary, names: Dictionary) -> ShoeDefinition:
	var h: float = float(o.get("h", 0))
	var p: float = float(o.get("p", 0))
	var shaft: float = float(o.get("shaft", 0))
	var toe: String = o.get("toe", "round")
	var heel_type: String = o.get("heel", "block")
	var lift := h + p
	var ankle_y := -26.0 - lift
	var toe_x := 40.0 if toe == "point" else 35.0
	var base := -(p + ST)  # top of the forefoot sole
	var heel_top := -(lift + ST)

	var shapes: Array[Dictionary] = []
	var used: Array[String] = []

	# --- upper
	var upper := PackedVector2Array()
	upper.append(Vector2(-12, heel_top))
	var instep_y := base - 13.0 - h * 0.45
	if shaft > 0.0:
		var top_y := ankle_y - shaft
		upper.append(Vector2(-12.5, top_y + 4))
		upper.append(Vector2(-11, top_y))
		upper.append(Vector2(10, top_y))
		upper.append(Vector2(10.5, top_y + 4))
		upper.append(Vector2(9.5, instep_y - 2))
	else:
		var collar: float = float(o.get("collar", 9 if o.get("open", false) else 12))
		var back_top := heel_top - collar
		upper.append(Vector2(-13, back_top))
		if o.get("open", false):
			upper.append(Vector2(-4, back_top + 2))
			upper.append(Vector2(8, base - 9.0 - h * 0.35))
			upper.append(Vector2(14, base - 9.0 - h * 0.2))
		else:
			upper.append(Vector2(-2, back_top + 1))
			upper.append(Vector2(7, instep_y))
	upper.append(Vector2(17, base - 10.0 - h * 0.15))
	upper.append(Vector2(27, base - 8.0))
	match toe:
		"point":
			upper.append(Vector2(toe_x - 7, base - 5))
			upper.append(Vector2(toe_x, base - 1))
		"square":
			upper.append(Vector2(toe_x - 1, base - 8))
			upper.append(Vector2(toe_x, base - 1))
		"curl":
			upper.append(Vector2(toe_x - 3, base - 6))
			upper.append(Vector2(toe_x + 4, base - 9))
			upper.append(Vector2(toe_x + 8, base - 16))
			upper.append(Vector2(toe_x + 4, base - 20))
			upper.append(Vector2(toe_x + 9, base - 21))
			upper.append(Vector2(toe_x + 12, base - 14))
			upper.append(Vector2(toe_x + 6, base - 2))
		_:
			upper.append(Vector2(toe_x - 4, base - 7))
			upper.append(Vector2(toe_x, base - 3))
			upper.append(Vector2(toe_x - 1, base))
	upper.append(Vector2(16, base))
	upper.append(Vector2(2, base - h * 0.62))
	shapes.append(U.poly(_r(used, "upper"), upper))

	# --- heel
	if h > 3.0:
		var hp := PackedVector2Array()
		match heel_type:
			"stiletto":
				hp = U.v([[-12, -lift], [-5, -lift], [-9.5, 0], [-11.5, 0]])
			"louis":
				hp = U.v([[-12.5, -lift], [-2, -lift], [-6, -lift * 0.45], [-5.5, 0], [-10, 0], [-11, -lift * 0.5]])
			"wedge":
				hp = U.v([[-12.5, -lift], [4, -(lift * 0.55)], [15, -(p + 0.5)], [15, 0], [-12, 0]])
			_:
				hp = U.v([[-12.5, -lift], [-2.5, -lift], [-3.5, 0], [-11.5, 0]])
		shapes.append(U.poly(_r(used, "heel"), hp))
		if heel_type == "wedge":
			for k in range(4):
				var yy := -lift * (0.2 + 0.2 * k)
				shapes.append(U.line(_r(used, "heel"), U.v([[-11.5, yy], [lerpf(-11, 12, 0.2 + 0.2 * k), yy * 0.8]]), 1.0, 0.75))

	# --- sole
	var sole := PackedVector2Array()
	if h <= 3.0:
		sole = U.v([[-12.5, -ST - p], [toe_x - 0.5, base], [toe_x - 1.5, 0], [-12, 0]])
	else:
		sole = U.v([[2, base - h * 0.62], [16, base], [toe_x - 0.5, base], [toe_x - 1.5, 0], [8, 0], [2, -ST - p - h * 0.5]])
	shapes.append(U.poly(_r(used, "sole"), sole))
	if toe == "curl":
		shapes.append(U.line(_r(used, "sole"), U.v([[toe_x - 1, base], [toe_x + 6, base - 2], [toe_x + 12, base - 14]]), 2.0))

	# --- accents
	if o.get("toe_cap", false):
		shapes.append(U.poly(_r(used, "accent"), U.v([[22, base - 9], [27, base - 8], [toe_x - 4, base - 7], [toe_x, base - 3], [toe_x - 1, base], [21, base]])))
	if o.get("pull_tab", false):
		var ty := ankle_y - shaft
		shapes.append(U.poly(_r(used, "accent"), U.v([[-12, ty - 7], [-7, ty - 7], [-7, ty + 3], [-12, ty + 3]])))
	if o.has("cuff"):
		var cy := ankle_y - shaft
		var cw: float = float(o["cuff"])
		var flare := 4.0 if cw > 12 else 1.0
		shapes.append(U.poly(_r(used, "accent"), U.v([[-12 - flare, cy - 2], [10 + flare, cy - 2], [11.5, cy + cw], [-13.5, cy + cw]])))
	if o.get("strap", false):
		shapes.append(U.line(_r(used, "accent"), U.v([[-6, heel_top - 9], [6, base - 13], [12, base - 1]]), 3.0))
		shapes.append(U.circle(_r(used, "detail"), Vector2(6, base - 13), 2.0))
	if o.get("spats", false):
		var sy := ankle_y - 22.0
		shapes.append(U.poly(_r(used, "accent"), U.v([[-12.5, sy], [9.5, sy], [9.5, instep_y], [20, base - 9], [12, base - 4], [-12.5, heel_top - 4]])))
		for k in range(3):
			shapes.append(U.circle(_r(used, "detail"), Vector2(-9, sy + 5 + k * 6), 1.4))

	# --- details
	if o.get("buttons", false):
		var by := ankle_y - shaft + 6
		var k := 0
		while by < instep_y:
			shapes.append(U.circle(_r(used, "detail"), Vector2(3.0 + k * 0.6, by), 1.6))
			by += 7.0
			k += 1
	if o.get("laces", false):
		var zz := PackedVector2Array()
		var ly := ankle_y - shaft + 4
		var left := true
		while ly < instep_y + 2:
			zz.append(Vector2(4 if left else 9.5, ly))
			ly += 4.5
			left = not left
		shapes.append(U.line(_r(used, "detail"), zz, 1.2))
		shapes.append(U.line(_r(used, "detail"), U.v([[8, ankle_y - shaft + 3], [14, ankle_y - shaft - 4], [16, ankle_y - shaft + 6]]), 1.2))
	if o.get("buckle", false):
		var bx := 9.0
		var byy := base - 12.0 - h * 0.15 if shaft == 0.0 else ankle_y - 6.0
		shapes.append(U.line(_r(used, "detail"), U.v([[bx - 4, byy - 4], [bx + 4, byy - 4], [bx + 4, byy + 4], [bx - 4, byy + 4], [bx - 4, byy - 4]]), 2.0))
		shapes.append(U.line(_r(used, "detail"), U.v([[bx, byy - 4], [bx, byy + 4]]), 1.2))
	if o.get("bow", false):
		var bw := Vector2(18, base - 10.0 - h * 0.15)
		shapes.append(U.poly(_r(used, "detail"), U.v([[bw.x, bw.y], [bw.x - 6, bw.y - 4], [bw.x - 6, bw.y + 3]])))
		shapes.append(U.poly(_r(used, "detail"), U.v([[bw.x, bw.y], [bw.x + 6, bw.y - 4], [bw.x + 6, bw.y + 3]])))
		shapes.append(U.circle(_r(used, "detail"), bw, 1.8, 0.85))
	if o.get("pompom", false):
		shapes.append(U.circle(_r(used, "detail"), Vector2(toe_x + 9, base - 22), 4.5))
	if o.get("ribbons", false):
		var rz := PackedVector2Array()
		for k in range(7):
			rz.append(Vector2(-8 if k % 2 == 0 else 8, ankle_y + 6 - k * 9))
		shapes.append(U.line(_r(used, "detail"), rz, 2.2))
	if o.get("ankle_ties", false):
		shapes.append(U.line(_r(used, "detail"), U.v([[-10, ankle_y + 4], [9, ankle_y + 2]]), 2.2))
		shapes.append(U.line(_r(used, "detail"), U.v([[9, ankle_y + 2], [15, ankle_y + 10], [12, ankle_y + 14]]), 1.6))
	if o.get("wings", false):
		var wy := ankle_y - shaft * 0.6
		shapes.append(U.poly(_r(used, "detail"), U.v([[-12, wy], [-26, wy - 14], [-34, wy - 10], [-24, wy - 6], [-32, wy - 2], [-22, wy + 1], [-28, wy + 6], [-12, wy + 6]])))
	var gems: int = int(o.get("gems", 0))
	for k in range(gems):
		var gx := 22.0 - k * 4.5 if gems > 1 else 20.0
		var gy := base - 7.0 - h * 0.1 - float(k % 2) * 3.0
		shapes.append(U.circle(_r(used, "detail"), Vector2(gx, gy), 1.8 if gems > 1 else 2.6))

	var s := ShoeDefinition.new()
	s.id = id
	s.display_name = name
	s.heel_lift = lift
	s.shapes = shapes
	var default_names := {"upper": "Upper", "sole": "Sole", "heel": "Heel", "accent": "Accent", "detail": "Details"}
	for key in used:
		s.region_names.append(names.get(key, default_names[key]))
		s.region_defaults.append(colors.get(key, Color(0.3, 0.2, 0.15)))
	return s


static func _r(used: Array[String], key: String) -> int:
	var i := used.find(key)
	if i < 0:
		used.append(key)
		i = used.size() - 1
	return i
