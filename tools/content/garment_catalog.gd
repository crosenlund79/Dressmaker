extends RefCounted
## Authoring source for the 60 garment templates (20 bodices, 20 skirts, 20 sleeves).
## See GarmentDefinition for the local frame conventions.

const U = preload("res://tools/content/catalog_util.gd")


static func g(id: String, name: String, cat: String, outline: PackedVector2Array, detail_lines: Array[PackedVector2Array], dots: PackedVector2Array, fabric: String, color: Color, secondary: Color, trim: Color, tags: Array = []) -> GarmentDefinition:
	var d := GarmentDefinition.new()
	d.id = id
	d.display_name = name
	d.category = cat
	d.outline = outline
	d.detail_lines = detail_lines
	d.detail_dots = dots
	d.default_fabric = fabric
	d.default_color = color
	d.default_secondary = secondary
	d.default_trim = trim
	d.tags = PackedStringArray(tags)
	return d


static func c(hex: String) -> Color:
	return Color.html(hex)


static func build() -> Array[GarmentDefinition]:
	var out: Array[GarmentDefinition] = []
	out.append_array(bodices())
	out.append_array(skirts())
	out.append_array(sleeves())
	return out


static func _join(a: Array[PackedVector2Array], b: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = a.duplicate()
	out.append_array(b)
	return out


static func _dots_line(x: float, y0: float, y1: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(n):
		out.append(Vector2(x, lerpf(y0, y1, float(i) / maxf(n - 1, 1))))
	return out


# --------------------------------------------------------------------------- bodices
static func bodices() -> Array[GarmentDefinition]:
	var B := "bodice"
	var list: Array[GarmentDefinition] = []

	list.append(g("bodice_victorian", "Fitted Victorian Bodice", B,
		U.sym([[0, 0.07], [0.12, 0.05], [0.24, -0.06], [0.6, -0.04], [1.03, 0.0], [1.04, 0.1], [0.99, 0.24], [1.02, 0.45], [1.03, 0.75], [1.04, 1.0], [0.7, 1.03], [0.3, 1.1], [0, 1.16]]),
		_join(U.mirrored_lines([[[0.55, -0.03], [0.45, 0.4], [0.4, 0.8], [0.42, 1.06]]]),
			U.lines([[[-0.24, -0.06], [-0.12, 0.05], [0, 0.07], [0.12, 0.05], [0.24, -0.06]]])),
		_dots_line(0, 0.16, 1.04, 8), "velvet", c("7b2d3a"), c("e8d9c0"), c("d9b25c"), ["victorian"]))

	list.append(g("bodice_high_neck", "High-Neck Bodice", B,
		U.sym([[0, -0.3], [0.16, -0.33], [0.27, -0.32], [0.28, -0.1], [0.6, -0.05], [1.03, 0.0], [1.04, 0.1], [0.99, 0.24], [1.03, 0.6], [1.05, 1.0], [0, 1.03]]),
		_join(U.mirrored_lines([[[0.12, 0.0], [0.12, 0.55]], [[0.22, -0.04], [0.22, 0.5]]]),
			U.lines([[[-0.28, -0.1], [0, -0.07], [0.28, -0.1]]])),
		_dots_line(0, -0.26, 0.9, 9), "linen", c("f1e6d2"), c("c9b79a"), c("8a6d4b"), ["victorian"]))

	list.append(g("bodice_corset", "Corset Bodice", B,
		U.sym([[0, 0.3], [0.2, 0.22], [0.42, 0.2], [0.7, 0.22], [0.97, 0.28], [0.97, 0.45], [1.0, 0.75], [1.04, 1.0], [0.75, 1.05], [0.35, 1.05], [0, 1.13]]),
		_join(U.mirrored_lines([[[0.35, 0.22], [0.3, 0.6], [0.34, 1.05]], [[0.7, 0.23], [0.62, 0.6], [0.72, 1.04]]]),
			U.lines([U.zigzag(0.07, 0.33, 1.06, 12)])),
		U.mirrored_dots([[0.09, 0.36], [0.09, 0.5], [0.09, 0.64], [0.09, 0.78], [0.09, 0.92]]), "satin", c("1f2a44"), c("9aa7c7"), c("e6d7b3"), ["victorian", "strapless"]))

	list.append(g("bodice_off_shoulder", "Off-Shoulder Bodice", B,
		U.sym([[0, 0.18], [0.4, 0.15], [0.8, 0.1], [1.22, 0.08], [1.25, 0.2], [1.0, 0.27], [0.99, 0.4], [1.03, 0.7], [1.04, 1.0], [0, 1.02]]),
		U.lines([U.wave(U.v([[-1.2, 0.16], [-0.6, 0.22], [0, 0.25], [0.6, 0.22], [1.2, 0.16]]), 3, 0.02)]),
		PackedVector2Array(), "silk", c("e7b7c4"), c("fff4f0"), c("ffffff"), ["romantic"]))

	list.append(g("bodice_square_neck", "Square-Neck Bodice", B,
		U.sym([[0, 0.24], [0.4, 0.24], [0.4, -0.07], [0.6, -0.05], [1.03, 0.0], [1.04, 0.1], [0.99, 0.24], [1.02, 0.6], [1.04, 1.0], [0, 1.0]]),
		U.lines([[[-0.36, -0.06], [-0.36, 0.2], [0.36, 0.2], [0.36, -0.06]]]),
		U.v([[0, 0.3], [0, 0.42]]), "brocade", c("2f5d50"), c("d8c27a"), c("d9b25c"), ["renaissance"]))

	list.append(g("bodice_sweetheart", "Sweetheart Bodice", B,
		U.sym([[0, 0.3], [0.08, 0.24], [0.2, 0.16], [0.33, 0.14], [0.48, 0.18], [0.62, 0.23], [0.98, 0.28], [0.98, 0.45], [1.02, 0.75], [1.04, 1.0], [0, 1.02]]),
		_join(U.lines([[[0, 0.3], [0, 1.02]]]), U.mirrored_lines([[[0.45, 0.2], [0.3, 0.7], [0.15, 1.0]]])),
		PackedVector2Array(), "satin", c("b83b5e"), c("f6c1d0"), c("f2e3c6"), ["strapless"]))

	list.append(g("bodice_one_shoulder", "One-Shoulder Asymmetric", B,
		U.v([[0.3, -0.09], [0.62, -0.05], [1.03, 0.0], [1.04, 0.1], [0.99, 0.24], [1.02, 0.6], [1.04, 1.0], [0, 1.04], [-1.04, 1.0], [-1.02, 0.6], [-0.98, 0.3], [-0.6, 0.27], [-0.2, 0.18], [0.12, 0.05]]),
		U.lines([[[-0.8, 0.45], [0.3, 0.1]], [[-0.9, 0.72], [0.62, 0.2]], [[-0.6, 0.96], [0.9, 0.36]]]),
		PackedVector2Array(), "silk", c("3c6e91"), c("cfe3ef"), c("e6e6e6"), ["asymmetric", "modern"]))

	list.append(g("bodice_peasant", "Flowing Peasant Blouse", B,
		U.sym([[0, 0.1], [0.22, -0.02], [0.5, -0.04], [1.15, 0.02], [1.22, 0.25], [1.24, 0.6], [1.3, 0.95], [1.25, 1.08], [0.6, 1.12], [0, 1.1]]),
		_join(U.lines([[[-0.48, 0.0], [-0.22, 0.08], [0, 0.12], [0.22, 0.08], [0.48, 0.0]]]),
			U.mirrored_lines([[[0.1, 0.13], [0.14, 0.32]], [[0.25, 0.08], [0.33, 0.27]], [[0.4, 0.04], [0.52, 0.21]], [[0.4, 1.08], [0.45, 0.85]], [[0.85, 1.06], [0.9, 0.84]]])),
		PackedVector2Array(), "cotton", c("f4ecdc"), c("d9c8a8"), c("a0522d"), ["loose"]))

	list.append(g("bodice_military", "Hussar Military Jacket", B,
		U.sym([[0, -0.18], [0.2, -0.21], [0.28, -0.2], [0.3, -0.08], [0.7, -0.04], [1.16, -0.03], [1.2, 0.08], [1.03, 0.12], [0.99, 0.24], [1.0, 0.6], [1.06, 1.0], [1.1, 1.12], [0.4, 1.12], [0, 1.16]]),
		_join(U.mirrored_lines([[[0.08, 0.14], [0.45, 0.12]], [[0.08, 0.32], [0.5, 0.3]], [[0.08, 0.5], [0.52, 0.48]], [[0.08, 0.68], [0.5, 0.66]], [[0.08, 0.86], [0.46, 0.84]],
				[[0.92, 0.07], [0.92, 0.2]], [[0.99, 0.07], [0.99, 0.2]], [[1.06, 0.06], [1.06, 0.19]], [[1.13, 0.05], [1.13, 0.18]], [[0.86, -0.02], [1.18, -0.02]]]),
			U.lines([[[-0.29, -0.08], [0, -0.05], [0.29, -0.08]]])),
		U.mirrored_dots([[0.1, 0.14], [0.1, 0.32], [0.1, 0.5], [0.1, 0.68], [0.1, 0.86]]), "velvet", c("8b1e2b"), c("2b2b2b"), c("e2c16b"), ["military", "structured"]))

	var tier_half: Array = [[0, 0.06], [0.24, -0.07], [0.6, -0.04], [1.03, 0.0], [1.04, 0.1], [0.99, 0.24], [1.12, 0.34], [1.0, 0.38], [1.14, 0.6], [1.02, 0.64], [1.16, 0.88], [1.05, 1.0]]
	var tier_pts := U.v(tier_half)
	tier_pts.append_array(U.scallops(Vector2(1.05, 1.0), Vector2(0, 1.0), 3, 0.06).slice(1))
	list.append(g("bodice_tiered_ruffle", "Tiered Ruffle Bodice", B,
		U.sym(_to_array(tier_pts)),
		U.lines([U.wave(U.v([[-1.08, 0.36], [1.08, 0.36]]), 7, 0.02), U.wave(U.v([[-1.1, 0.62], [1.1, 0.62]]), 7, 0.02), U.wave(U.v([[-1.12, 0.86], [1.12, 0.86]]), 7, 0.02)]),
		PackedVector2Array(), "lace", c("f3e9f1"), c("c7a2b8"), c("b07a9a"), ["romantic", "layered"]))

	list.append(g("bodice_deep_v", "Deep V Wrap Bodice", B,
		U.sym([[0, 0.55], [0.26, -0.08], [0.6, -0.05], [1.03, 0.0], [1.04, 0.1], [0.99, 0.24], [1.02, 0.6], [1.04, 1.0], [0, 1.0]]),
		U.lines([[[0.26, -0.08], [-0.15, 0.55], [-0.7, 0.98]], [[-0.26, -0.08], [0, 0.55]]]),
		PackedVector2Array(), "silk", c("5a2a6e"), c("d2b4de"), c("e3c58a"), ["modern"]))

	list.append(g("bodice_halter", "Halter Neck Bodice", B,
		U.sym([[0, 0.26], [0.08, 0.0], [0.16, -0.14], [0.3, -0.14], [0.33, 0.0], [0.62, 0.22], [0.98, 0.29], [0.98, 0.45], [1.02, 0.75], [1.04, 1.0], [0, 1.02]]),
		U.lines([[[-0.3, -0.11], [0, -0.1], [0.3, -0.11]]]),
		U.v([[0, -0.1]]), "polka", c("1d3557"), c("f1faee"), c("f1faee"), ["modern"]))

	list.append(g("bodice_bolero", "Cropped Bolero Jacket", B,
		U.sym([[0, -0.1], [0.28, -0.12], [0.62, -0.05], [1.04, 0.0], [1.05, 0.1], [1.0, 0.24], [1.02, 0.5], [0.9, 0.62], [0.55, 0.6], [0.3, 0.42], [0.16, 0.12], [0.08, 0.0], [0, -0.04]]),
		U.mirrored_lines([[[0.08, 0.0], [0.16, 0.12], [0.3, 0.42], [0.55, 0.6], [0.9, 0.62]]]),
		U.mirrored_dots([[0.2, 0.2], [0.27, 0.35], [0.4, 0.5], [0.6, 0.58], [0.8, 0.6]]), "brocade", c("1a1a1a"), c("b08d57"), c("d9b25c"), ["jacket", "open"]))

	list.append(g("bodice_empire", "Empire Waist Bodice", B,
		U.sym([[0, 0.18], [0.25, 0.08], [0.4, -0.04], [0.62, -0.05], [1.03, 0.0], [1.04, 0.1], [0.99, 0.24], [1.0, 0.42], [1.06, 0.7], [1.1, 1.0], [0, 1.0]]),
		_join(U.lines([[[-1.0, 0.43], [0, 0.45], [1.0, 0.43]], [[-1.01, 0.52], [0, 0.54], [1.01, 0.52]]]),
			U.mirrored_lines([[[0.2, 0.56], [0.25, 0.95]], [[0.55, 0.56], [0.65, 0.95]]])),
		U.v([[0, 0.48], [-0.05, 0.47], [0.05, 0.47]]), "cotton", c("cfe0f2"), c("ffffff"), c("6a8caf"), ["regency"]))

	list.append(g("bodice_peplum", "Peplum Jacket", B,
		U.sym([[0, 0.05], [0.24, -0.08], [0.6, -0.05], [1.03, 0.0], [1.04, 0.1], [0.99, 0.24], [1.02, 0.6], [1.0, 0.95], [1.35, 1.2], [1.28, 1.3], [0.8, 1.32], [0.3, 1.3], [0, 1.33]]),
		_join(U.mirrored_lines([[[0.24, -0.08], [0.32, 0.2], [0.12, 0.35], [0.0, 0.5]]]),
			U.lines([[[-1.0, 0.97], [0, 0.99], [1.0, 0.97]]])),
		U.v([[0, 0.58], [0, 0.72], [0, 0.86]]), "check", c("4b5d3a"), c("c9b98f"), c("3a2a1a"), ["jacket", "structured"]))

	list.append(g("bodice_sailor", "Sailor Collar Blouse", B,
		U.sym([[0, 0.04], [0.24, -0.08], [0.6, -0.05], [1.06, 0.0], [1.07, 0.12], [1.02, 0.24], [1.07, 0.6], [1.1, 1.0], [0, 1.0]]),
		U.mirrored_lines([[[0.24, -0.08], [0.0, 0.42]], [[0.24, -0.08], [0.7, -0.03], [0.62, 0.22], [0.1, 0.36]], [[0.6, 0.17], [0.13, 0.3]]]),
		U.v([[0, 0.44], [-0.04, 0.48], [0.04, 0.48]]), "stripes", c("f7f7f2"), c("1f3a68"), c("1f3a68"), ["casual"]))

	var ruff := U.wave(U.ellipse(Vector2(0, -0.15), 0.85, 0.3, -90, 25, 12), 1, 0.025)
	var ruff_half: Array = _to_array(ruff)
	ruff_half[0] = [0.0, ruff_half[0][1]]
	ruff_half.append_array([[1.03, 0.02], [1.04, 0.12], [0.99, 0.24], [1.02, 0.6], [1.04, 1.0], [0.5, 1.04], [0, 1.14]])
	var ruff_lines: Array = []
	for k in range(0, 7):
		var a := deg_to_rad(-90.0 + k * 18.0)
		ruff_lines.append([[cos(a) * 0.35, -0.15 + sin(a) * 0.12], [cos(a) * 0.8, -0.15 + sin(a) * 0.28]])
	list.append(g("bodice_ruff", "Elizabethan Ruff Collar", B,
		U.sym(ruff_half), U.mirrored_lines(ruff_lines),
		_dots_line(0, 0.2, 1.0, 6), "velvet", c("2d2440"), c("f2efe6"), c("f2efe6"), ["historical", "dramatic"]))

	list.append(g("bodice_cubist", "Cubist Angular Top", B,
		U.sym([[0, -0.06], [0.3, -0.16], [0.75, -0.12], [1.35, 0.04], [1.05, 0.28], [1.28, 0.52], [1.0, 0.72], [1.15, 1.0], [0.45, 0.94], [0, 1.06]]),
		U.mirrored_lines([[[0.3, -0.16], [0.4, 0.4]], [[0.4, 0.4], [1.05, 0.28]], [[0.4, 0.4], [0, 0.6]], [[0.4, 0.4], [1.0, 0.72]], [[1.0, 0.72], [0.45, 0.94]]]),
		PackedVector2Array(), "geometric", c("e9c46a"), c("264653"), c("264653"), ["experimental", "geometric"]))

	list.append(g("bodice_dirndl", "Lace-Up Strap Bodice", B,
		U.sym([[0, 0.34], [0.36, 0.32], [0.42, 0.12], [0.46, -0.05], [0.62, -0.05], [0.64, 0.12], [0.98, 0.28], [0.98, 0.45], [1.02, 0.75], [1.04, 1.0], [0.25, 1.06], [0, 1.12]]),
		_join(U.lines([U.zigzag(0.12, 0.38, 1.04, 8)]), U.mirrored_lines([[[0.36, 0.32], [0.42, 0.12], [0.46, -0.05]]])),
		U.mirrored_dots([[0.14, 0.38], [0.14, 0.54], [0.14, 0.71], [0.14, 0.87], [0.14, 1.04]]), "floral", c("2e4a3b"), c("e07a8f"), c("f0e1c0"), ["folk"]))

	list.append(g("bodice_capelet", "Shoulder Capelet Bodice", B,
		U.sym([[0, -0.14], [0.28, -0.13], [0.7, -0.03], [1.32, 0.2], [1.45, 0.48], [1.15, 0.5], [1.02, 0.56], [1.04, 1.0], [0, 1.0]]),
		U.mirrored_lines([[[1.45, 0.48], [0.8, 0.53], [0.2, 0.5], [0, 0.5]], [[1.4, 0.5], [1.42, 0.6]], [[1.25, 0.51], [1.26, 0.61]], [[1.1, 0.52], [1.1, 0.62]]]),
		U.mirrored_dots([[0.12, -0.08]]), "velvet", c("5b3a29"), c("caa472"), c("e3c58a"), ["outerwear", "dramatic"]))

	return list


# --------------------------------------------------------------------------- skirts
static func skirts() -> Array[GarmentDefinition]:
	var S := "skirt"
	var list: Array[GarmentDefinition] = []

	list.append(g("skirt_full_victorian", "Full Victorian Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.1, 0.12], [1.35, 0.3], [1.8, 0.55], [2.35, 0.8], [2.7, 0.95], [2.2, 0.98], [1.2, 1.0], [0, 1.0]]),
		U.mirrored_lines([[[2.45, 0.85], [1.3, 0.89], [0, 0.9]], [[0.4, 0.02], [0.8, 0.95]], [[0.9, 0.05], [1.7, 0.92]]]),
		PackedVector2Array(), "velvet", c("7b2d3a"), c("e8d9c0"), c("d9b25c"), ["victorian", "full"]))

	list.append(g("skirt_bustle", "Bustle Skirt", S,
		U.v([[0, -0.03], [1.0, -0.03], [1.5, 0.12], [1.75, 0.25], [1.45, 0.35], [1.5, 0.6], [1.7, 0.9], [1.6, 0.98], [0, 0.99], [-1.6, 0.98], [-2.2, 1.04], [-3.0, 1.07], [-2.4, 0.8], [-1.6, 0.55], [-1.5, 0.35], [-1.8, 0.22], [-1.5, 0.1], [-1.0, -0.03]]),
		U.lines([[[-1.45, 0.12], [-0.6, 0.38], [0.4, 0.42], [1.5, 0.15]], [[-1.5, 0.32], [0, 0.56], [1.45, 0.36]], [[-1.55, 0.6], [-2.3, 0.95]]]),
		U.v([[1.55, 0.2], [1.62, 0.17], [1.62, 0.24]]), "stripes", c("3b4f6b"), c("c7d0db"), c("e3c58a"), ["victorian", "asymmetric"]))

	list.append(g("skirt_bell", "Bell Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.06, 0.18], [1.12, 0.45], [1.35, 0.7], [1.9, 0.88], [2.1, 0.97], [1.2, 0.99], [0, 0.99]]),
		U.lines([[[-2.0, 0.92], [0, 0.94], [2.0, 0.92]]]),
		PackedVector2Array(), "satin", c("355c7d"), c("b8d0e6"), c("f0e6d2"), ["victorian"]))

	list.append(g("skirt_column", "Narrow Column Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.04, 0.19], [0.98, 0.5], [0.86, 0.8], [0.8, 0.97], [0, 0.98]]),
		U.lines([[[0.0, 0.0], [0.0, 0.98]]]),
		_dots_line(-0.45, 0.1, 0.8, 8), "linen", c("6d6875"), c("b5838d"), c("2b2b2b"), ["narrow", "edwardian"]))

	list.append(g("skirt_tiered", "Layered Tiered Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.08, 0.19], [1.25, 0.36], [1.18, 0.38], [1.45, 0.64], [1.38, 0.66], [1.8, 0.96], [0, 0.98]]),
		U.lines([U.wave(U.v([[-1.22, 0.37], [1.22, 0.37]]), 8, 0.012), U.wave(U.v([[-1.42, 0.65], [1.42, 0.65]]), 9, 0.012), U.wave(U.v([[-1.78, 0.94], [1.78, 0.94]]), 11, 0.012)]),
		PackedVector2Array(), "floral", c("f2d0a4"), c("b5523b"), c("8c3b2b"), ["layered", "folk"]))

	list.append(g("skirt_high_low", "Asymmetric High-Low Skirt", S,
		U.v([[0, -0.03], [1.0, -0.03], [1.15, 0.18], [1.6, 0.4], [1.9, 0.52], [1.2, 0.56], [0.3, 0.68], [-0.6, 0.85], [-1.4, 0.98], [-2.0, 0.96], [-1.7, 0.6], [-1.2, 0.25], [-1.0, -0.03]]),
		U.lines([[[-0.2, 0.05], [-1.2, 0.85]], [[0.4, 0.06], [-0.2, 0.7]]]),
		PackedVector2Array(), "silk", c("2a9d8f"), c("e9f5f2"), c("e9c46a"), ["asymmetric", "modern"]))

	list.append(g("skirt_high_slit", "High-Slit Skirt", S,
		U.v([[0, -0.03], [1.0, -0.03], [1.1, 0.19], [1.25, 0.5], [1.45, 0.96], [0.55, 0.98], [0.42, 0.42], [0.3, 0.98], [-1.45, 0.96], [-1.25, 0.5], [-1.1, 0.19], [-1.0, -0.03]]),
		U.lines([[[0.42, 0.42], [0.42, 0.36]]]),
		PackedVector2Array(), "satin", c("9d0208"), c("f48c06"), c("faa307"), ["modern", "daring"]))

	list.append(g("skirt_short_flared", "Short Flared Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.25, 0.15], [1.65, 0.3], [1.85, 0.38], [1.0, 0.4], [0, 0.4]]),
		U.mirrored_lines([[[0.3, 0.02], [0.45, 0.39]], [[0.75, 0.0], [1.1, 0.39]], [[1.0, 0.05], [1.6, 0.36]]]),
		PackedVector2Array(), "check", c("e63946"), c("f1faee"), c("1d3557"), ["short", "playful"]))

	list.append(g("skirt_train", "Dramatic Train Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.15, 0.2], [1.5, 0.5], [2.0, 0.78], [3.2, 0.98], [4.3, 1.06], [2.5, 1.08], [0, 1.06]]),
		U.mirrored_lines([[[0.6, 0.1], [1.6, 1.0]], [[1.2, 0.35], [3.0, 1.03]], [[0.2, 0.2], [0.6, 1.04]]]),
		PackedVector2Array(), "silk", c("f5f0e6"), c("e0d4bd"), c("cbb37f"), ["formal", "dramatic"]))

	list.append(g("skirt_origami", "Origami Geometric Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.7, 0.25], [1.25, 0.33], [2.1, 0.6], [1.5, 0.66], [2.5, 0.92], [1.2, 0.82], [0.5, 0.96], [0, 0.86]]),
		U.mirrored_lines([[[1.0, -0.03], [1.25, 0.33]], [[1.25, 0.33], [1.5, 0.66]], [[1.5, 0.66], [1.2, 0.82]], [[0.4, 0.0], [0.5, 0.96]], [[0.5, 0.45], [1.25, 0.33]]]),
		PackedVector2Array(), "geometric", c("ffb703"), c("023047"), c("023047"), ["experimental", "geometric"]))

	var hoops: Array = []
	for hv in [0.35, 0.55, 0.75, 0.9]:
		var w: float = lerpf(1.6, 3.3, (hv - 0.35) / 0.6)
		hoops.append(U.ellipse(Vector2(0, hv - 0.02), w, 0.03, 180, 0, 10))
	list.append(g("skirt_crinoline", "Grand Crinoline", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.25, 0.1], [1.9, 0.3], [2.6, 0.55], [3.2, 0.8], [3.4, 0.93], [3.0, 0.98], [1.5, 1.0], [0, 1.0]]),
		U.lines(hoops), PackedVector2Array(), "brocade", c("c08497"), c("f7e1d7"), c("f7e1d7"), ["victorian", "wide"]))

	list.append(g("skirt_mermaid", "Mermaid Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.06, 0.19], [0.96, 0.45], [0.84, 0.66], [1.1, 0.8], [1.7, 0.95], [2.0, 1.04], [0, 1.0]]),
		U.mirrored_lines([[[0.84, 0.66], [1.1, 1.0]], [[0.4, 0.68], [0.6, 1.0]]]),
		PackedVector2Array(), "satin", c("0b6e4f"), c("a7c957"), c("f2e8cf"), ["formal", "fitted"]))

	var pleat_half: Array = [[0, -0.03], [1.0, -0.03], [1.15, 0.19], [1.5, 0.74]]
	var zig := PackedVector2Array()
	for k in range(11):
		var x := lerpf(1.5, 0.0, k / 10.0)
		zig.append(Vector2(x, 0.78 if k % 2 == 0 else 0.74))
	pleat_half.append_array(_to_array(zig))
	var pleats: Array = []
	for k in range(1, 6):
		pleats.append([[k * 0.19, 0.0], [k * 0.29, 0.75]])
	list.append(g("skirt_knife_pleat", "Knife-Pleated Skirt", S,
		U.sym(pleat_half), U.mirrored_lines(pleats), PackedVector2Array(), "linen", c("264653"), c("8ab17d"), c("e9c46a"), ["pleated"]))

	list.append(g("skirt_bubble", "Bubble Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.3, 0.1], [1.75, 0.25], [1.85, 0.38], [1.55, 0.5], [1.1, 0.55], [0, 0.56]]),
		U.lines([U.wave(U.v([[-1.2, 0.52], [1.2, 0.52]]), 9, 0.01)]),
		PackedVector2Array(), "polka", c("ff8fab"), c("ffffff"), c("fb6f92"), ["playful", "short"]))

	list.append(g("skirt_handkerchief", "Handkerchief Hem Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.15, 0.2], [1.5, 0.45], [2.1, 0.85], [1.3, 0.62], [0.75, 0.92], [0.3, 0.66], [0, 0.85]]),
		U.mirrored_lines([[[0.5, 0.02], [0.75, 0.9]], [[1.05, 0.05], [2.0, 0.83]]]),
		PackedVector2Array(), "lace", c("cdb4db"), c("ffc8dd"), c("a2d2ff"), ["boho"]))

	list.append(g("skirt_tulip", "Tulip Wrap Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.25, 0.2], [1.35, 0.4], [1.2, 0.58], [0.8, 0.66], [0.3, 0.6], [0, 0.52]]),
		U.lines([[[-0.2, 0.0], [0.3, 0.3], [0.35, 0.6]], [[0.2, 0.0], [-0.25, 0.32], [-0.3, 0.6]]]),
		PackedVector2Array(), "silk", c("d62828"), c("fcbf49"), c("f77f00"), ["modern", "short"]))

	list.append(g("skirt_walking", "Edwardian Walking Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.12, 0.19], [1.45, 0.6], [1.7, 0.93], [0, 0.95]]),
		_join(U.lines([[[-1.65, 0.86], [0, 0.88], [1.65, 0.86]]]), U.mirrored_lines([[[0.55, 0.25], [0.85, 0.25], [0.85, 0.35]]])),
		_dots_line(-0.25, 0.05, 0.85, 7), "check", c("5e503f"), c("a9927d"), c("22333b"), ["edwardian"]))

	var cancan := U.v([[0, -0.03], [1.0, -0.03], [1.3, 0.2], [1.25, 0.24], [1.55, 0.38], [1.48, 0.42], [1.85, 0.56]])
	cancan.append_array(U.scallops(Vector2(1.85, 0.56), Vector2(0, 0.6), 5, 0.03).slice(1))
	list.append(g("skirt_cancan", "Can-Can Ruffle Skirt", S,
		U.sym(_to_array(cancan)),
		U.lines([U.wave(U.v([[-1.28, 0.22], [1.28, 0.22]]), 7, 0.012), U.wave(U.v([[-1.52, 0.4], [1.52, 0.4]]), 9, 0.012)]),
		PackedVector2Array(), "stripes", c("000000"), c("e5383b"), c("e5383b"), ["playful", "layered"]))

	list.append(g("skirt_polonaise", "Polonaise Draped Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.3, 0.2], [1.75, 0.45], [1.55, 0.55], [1.65, 0.75], [1.9, 0.96], [0, 0.98]]),
		U.lines([[[-1.75, 0.45], [-1.0, 0.62], [0, 0.55], [1.0, 0.62], [1.75, 0.45]], [[-1.0, 0.62], [-0.9, 0.2]], [[1.0, 0.62], [0.9, 0.2]]]),
		U.mirrored_dots([[1.0, 0.62]]), "floral", c("f6e7cb"), c("6a994e"), c("bc4749"), ["rococo", "draped"]))

	list.append(g("skirt_lampshade", "Lampshade Tunic Skirt", S,
		U.sym([[0, -0.03], [1.0, -0.03], [1.15, 0.18], [2.0, 0.38], [2.0, 0.43], [0.9, 0.45], [0.82, 0.97], [0, 0.98]]),
		U.lines([[[-2.0, 0.4], [0, 0.42], [2.0, 0.4]], [[0, 0.45], [0, 0.97]]]),
		PackedVector2Array(), "brocade", c("3d405b"), c("f2cc8f"), c("f2cc8f"), ["experimental", "1910s"]))

	return list


# --------------------------------------------------------------------------- sleeves
static func sleeves() -> Array[GarmentDefinition]:
	var L := "sleeve"
	var list: Array[GarmentDefinition] = []
	var cap: Array = [[-1.1, 0.02], [-0.4, -0.08], [0.5, -0.08], [1.15, 0.0]]

	list.append(g("sleeve_long_fitted", "Long Fitted Sleeve", L,
		U.v(cap + [[1.15, 0.5], [1.12, 1.0], [-1.12, 1.0], [-1.12, 0.5]]),
		U.lines([[[-1.12, 0.9], [1.12, 0.9]]]), U.v([[0.6, 0.95]]), "cotton", c("7b2d3a"), c("e8d9c0"), c("d9b25c"), ["victorian"]))

	list.append(g("sleeve_puff", "Short Puff Sleeve", L,
		U.v([[-1.2, 0.05], [-0.8, -0.15], [0.4, -0.2], [1.7, -0.04], [2.1, 0.15], [1.8, 0.3], [1.2, 0.38], [-1.15, 0.34]]),
		U.lines([[[-0.2, -0.12], [0.0, 0.33]], [[0.6, -0.15], [0.7, 0.34]], [[1.3, -0.08], [1.4, 0.3]], [[-1.15, 0.3], [1.3, 0.34]]]),
		PackedVector2Array(), "silk", c("e7b7c4"), c("fff4f0"), c("ffffff"), ["romantic"]))

	list.append(g("sleeve_bell", "Bell Sleeve", L,
		U.v(cap + [[1.25, 0.45], [2.4, 0.9], [3.4, 1.08], [1.0, 1.1], [-1.6, 1.02], [-1.2, 0.55]]),
		U.lines([[[-1.55, 0.98], [1.0, 1.05], [3.3, 1.04]]]), PackedVector2Array(), "satin", c("355c7d"), c("b8d0e6"), c("f0e6d2"), ["victorian", "flared"]))

	list.append(g("sleeve_cap", "Cap Sleeve", L,
		U.v([[-1.1, 0.04], [-0.4, -0.08], [0.6, -0.08], [1.3, 0.02], [1.4, 0.18], [0.4, 0.24], [-1.1, 0.2]]),
		U.lines([[[-1.1, 0.17], [0.4, 0.21], [1.36, 0.15]]]), PackedVector2Array(), "cotton", c("f4ecdc"), c("d9c8a8"), c("a0522d"), ["short"]))

	var lace_pts := U.v([[-1.1, 0.02], [-0.4, -0.08], [0.5, -0.08]])
	lace_pts.append_array(U.scallops(Vector2(1.15, 0.0), Vector2(1.1, 1.0), 8, 0.18))
	lace_pts.append_array(U.v([[0.9, 1.02], [0.0, 1.14], [-0.9, 1.02]]))
	lace_pts.append_array(U.scallops(Vector2(-1.1, 1.0), Vector2(-1.12, 0.05), 8, 0.18))
	list.append(g("sleeve_lace_gauntlet", "Lace Gauntlet Sleeve", L,
		lace_pts, U.lines([[[-0.6, 0.1], [0.6, 0.35], [-0.6, 0.6], [0.6, 0.85]], [[0.6, 0.1], [-0.6, 0.35], [0.6, 0.6], [-0.6, 0.85]]]),
		PackedVector2Array(), "lace", c("f6f1e9"), c("d8cbb5"), c("c9b28f"), ["lace"]))

	list.append(g("sleeve_gigot", "Leg-of-Mutton Sleeve", L,
		U.v([[-1.3, 0.05], [-0.9, -0.22], [0.5, -0.32], [2.4, -0.12], [3.4, 0.15], [3.2, 0.38], [2.0, 0.55], [1.2, 0.64], [1.12, 1.0], [-1.12, 1.0], [-1.2, 0.6], [-1.6, 0.35]]),
		U.lines([[[0.2, -0.25], [0.5, 0.55]], [[1.4, -0.2], [1.6, 0.5]], [[-1.12, 0.92], [1.12, 0.92]]]),
		PackedVector2Array(), "velvet", c("5a2a6e"), c("d2b4de"), c("e3c58a"), ["victorian", "oversized"]))

	list.append(g("sleeve_pagoda", "Tiered Pagoda Sleeve", L,
		U.v(cap + [[1.25, 0.3], [1.9, 0.42], [1.5, 0.44], [1.6, 0.62], [2.4, 0.74], [1.9, 0.76], [2.0, 0.9], [2.9, 1.04], [-1.6, 1.0], [-1.4, 0.75], [-1.2, 0.4]]),
		U.lines([[[-1.25, 0.42], [1.9, 0.42]], [[-1.4, 0.72], [2.4, 0.74]]]), PackedVector2Array(), "lace", c("f3e9f1"), c("c7a2b8"), c("b07a9a"), ["layered"]))

	list.append(g("sleeve_asym_drape", "Asymmetric Drape Sleeve", L,
		U.v([[-1.1, 0.02], [-0.4, -0.08], [0.5, -0.08], [1.2, 0.0], [1.8, 0.4], [2.8, 0.9], [2.6, 1.25], [1.6, 1.05], [1.1, 0.75], [-0.4, 0.62], [-1.15, 0.5]]),
		U.lines([[[0.4, 0.1], [2.2, 1.0]], [[1.0, 0.1], [2.6, 0.95]]]), PackedVector2Array(), "silk", c("3c6e91"), c("cfe3ef"), c("e6e6e6"), ["asymmetric"]))

	list.append(g("sleeve_detached", "Detached Opera Sleeve", L,
		U.v([[-1.05, 0.38], [0.0, 0.33], [1.12, 0.36], [1.1, 1.0], [0.0, 1.06], [-1.1, 1.0]]),
		U.lines([[[-1.05, 0.44], [0.0, 0.4], [1.12, 0.42]]]), _dots_line(0.75, 0.5, 0.95, 5), "satin", c("1a1a1a"), c("444444"), c("d9d9d9"), ["detached", "evening"]))

	var spikes := U.v([[-1.1, 0.02], [-0.4, -0.08], [0.5, -0.08], [1.15, 0.0], [2.4, 0.1], [1.15, 0.25], [2.2, 0.38], [1.12, 0.5], [2.0, 0.63], [1.1, 0.75], [1.8, 0.88], [1.1, 1.0], [-1.1, 1.0], [-1.12, 0.5]])
	list.append(g("sleeve_crystal", "Crystal Spike Sleeve", L,
		spikes, U.lines([[[1.15, 0.0], [1.15, 1.0]]]), PackedVector2Array(), "geometric", c("8ecae6"), c("219ebc"), c("ffffff"), ["experimental", "geometric"]))

	list.append(g("sleeve_bishop", "Bishop Sleeve", L,
		U.v(cap + [[1.4, 0.35], [2.0, 0.7], [2.0, 0.86], [1.3, 0.95], [1.15, 1.0], [-1.15, 1.0], [-1.3, 0.95], [-1.9, 0.85], [-1.6, 0.6], [-1.2, 0.3]]),
		U.lines([[[-1.3, 0.94], [1.3, 0.94]], [[0.0, 0.3], [0.0, 0.92]], [[1.0, 0.4], [1.2, 0.92]], [[-0.9, 0.4], [-1.1, 0.92]]]),
		U.v([[0.5, 0.97]]), "linen", c("f1e6d2"), c("c9b79a"), c("8a6d4b"), ["romantic"]))

	list.append(g("sleeve_juliet", "Juliet Sleeve", L,
		U.v([[-1.25, 0.05], [-0.8, -0.14], [0.4, -0.18], [1.6, -0.02], [1.9, 0.16], [1.4, 0.3], [1.1, 0.34], [1.12, 1.0], [-1.12, 1.0], [-1.1, 0.34], [-1.4, 0.24]]),
		U.lines([[[-1.1, 0.34], [1.1, 0.34]], [[-1.12, 0.92], [1.12, 0.92]]]), PackedVector2Array(), "velvet", c("2f5d50"), c("d8c27a"), c("d9b25c"), ["renaissance"]))

	var flutter := U.v([[-1.1, 0.04], [-0.4, -0.08], [0.6, -0.08], [1.3, 0.02], [1.8, 0.15]])
	flutter.append_array(U.scallops(Vector2(2.3, 0.32), Vector2(-1.2, 0.24), 5, -0.05))
	list.append(g("sleeve_flutter", "Flutter Sleeve", L,
		flutter, U.lines([[[0.0, -0.06], [0.2, 0.26]], [[1.0, 0.0], [1.4, 0.28]]]), PackedVector2Array(), "silk", c("f2d0a4"), c("b5523b"), c("8c3b2b"), ["romantic", "short"]))

	list.append(g("sleeve_cold_shoulder", "Cold-Shoulder Flare", L,
		U.v([[-1.1, 0.3], [-0.3, 0.24], [1.2, 0.26], [1.2, 0.6], [1.8, 0.95], [2.0, 1.04], [-0.6, 1.05], [-1.15, 0.7]]),
		U.lines([[[0.0, 0.25], [0.0, -0.06]], [[-1.0, 0.33], [1.2, 0.3]]]), PackedVector2Array(), "polka", c("1d3557"), c("f1faee"), c("f1faee"), ["modern"]))

	list.append(g("sleeve_angel", "Angel Kimono Sleeve", L,
		U.v([[-1.1, 0.02], [-0.4, -0.08], [0.6, -0.06], [1.4, 0.05], [3.2, 0.35], [3.3, 1.1], [1.2, 1.16], [-0.6, 0.95], [-1.1, 0.6]]),
		U.lines([[[1.4, 0.05], [1.2, 1.16]], [[2.3, 0.2], [2.2, 1.12]]]), PackedVector2Array(), "floral", c("1b263b"), c("e0a458"), c("e0a458"), ["flowing", "kimono"]))

	list.append(g("sleeve_lantern", "Lantern Sleeve", L,
		U.v(cap + [[1.15, 0.45], [1.9, 0.62], [2.1, 0.75], [1.7, 0.88], [1.12, 0.93], [1.1, 1.0], [-1.1, 1.0], [-1.12, 0.93], [-1.7, 0.86], [-1.9, 0.74], [-1.6, 0.6], [-1.12, 0.45]]),
		U.lines([[[-1.12, 0.45], [1.15, 0.45]], [[0.0, 0.47], [0.0, 0.92]], [[-1.12, 0.93], [1.12, 0.93]]]), PackedVector2Array(), "satin", c("9d0208"), c("f48c06"), c("faa307"), ["modern"]))

	list.append(g("sleeve_epaulette", "Military Epaulette Sleeve", L,
		U.v([[-1.2, 0.0], [-0.6, -0.14], [0.6, -0.16], [1.9, -0.1], [2.2, 0.04], [1.9, 0.14], [1.15, 0.16], [1.15, 0.5], [1.12, 1.0], [-1.12, 1.0], [-1.12, 0.5]]),
		U.lines([[[1.9, 0.14], [1.9, 0.24]], [[1.6, 0.15], [1.6, 0.25]], [[1.3, 0.16], [1.3, 0.26]], [[-0.6, 0.86], [0.6, 0.8]], [[-0.6, 0.92], [0.6, 0.86]], [[-1.2, 0.05], [2.1, 0.05]]]),
		PackedVector2Array(), "velvet", c("8b1e2b"), c("2b2b2b"), c("e2c16b"), ["military"]))

	var ruffle := U.v(cap + [[1.12, 0.48], [1.8, 0.62], [1.5, 0.66], [2.2, 0.82], [1.8, 0.86]])
	ruffle.append_array(U.scallops(Vector2(2.5, 1.02), Vector2(-1.6, 0.98), 7, -0.03))
	ruffle.append_array(U.v([[-1.3, 0.8], [-1.1, 0.5]]))
	list.append(g("sleeve_engageante", "Engageante Ruffle Sleeve", L,
		ruffle, U.lines([U.wave(U.v([[-1.15, 0.62], [1.8, 0.62]]), 4, 0.02), U.wave(U.v([[-1.25, 0.82], [2.2, 0.82]]), 5, 0.02)]),
		PackedVector2Array(), "lace", c("f6f1e9"), c("d8cbb5"), c("c9b28f"), ["victorian", "lace"]))

	list.append(g("sleeve_butterfly", "Butterfly Wing Sleeve", L,
		U.v([[-1.0, 0.02], [-0.2, -0.1], [1.0, -0.2], [3.0, -0.55], [5.0, -0.45], [5.8, -0.1], [5.2, 0.3], [3.5, 0.55], [2.0, 0.5], [1.1, 0.55], [-1.0, 0.42]]),
		U.lines([[[0.8, 0.0], [5.0, -0.42]], [[0.8, 0.05], [5.6, -0.1]], [[0.8, 0.1], [5.1, 0.28]], [[0.8, 0.15], [3.4, 0.52]]]),
		U.v([[3.8, -0.2], [4.4, 0.1]]), "silk", c("ffafcc"), c("cdb4db"), c("ffffff"), ["fantasy", "experimental"]))

	list.append(g("sleeve_slashed", "Renaissance Slashed Puff", L,
		U.v([[-1.25, 0.04], [-0.8, -0.14], [0.4, -0.18], [1.6, -0.04], [1.9, 0.14], [1.4, 0.3], [1.3, 0.38], [1.7, 0.5], [1.4, 0.6], [1.12, 0.66], [1.12, 1.0], [-1.12, 1.0], [-1.15, 0.66], [-1.5, 0.55], [-1.3, 0.38], [-1.4, 0.25]]),
		U.lines([[[-0.6, -0.08], [-0.6, 0.28]], [[0.3, -0.12], [0.3, 0.3]], [[1.1, -0.06], [1.1, 0.3]], [[-0.8, 0.42], [-0.8, 0.6]], [[0.2, 0.4], [0.2, 0.62]], [[1.0, 0.42], [1.0, 0.6]]]),
		PackedVector2Array(), "brocade", c("1a1a1a"), c("b08d57"), c("d9b25c"), ["renaissance"]))

	return list


static func _to_array(pts: PackedVector2Array) -> Array:
	var out: Array = []
	for p in pts:
		out.append([p.x, p.y])
	return out
