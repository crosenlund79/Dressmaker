extends TestCase
## Content library completeness and integrity.


func test_garment_counts() -> void:
	check_eq(Content.garments_in("bodice").size(), 20, "20 bodices")
	check_eq(Content.garments_in("skirt").size(), 20, "20 skirts")
	check_eq(Content.garments_in("sleeve").size(), 20, "20 sleeves")
	done()


func test_garment_silhouettes_are_distinct() -> void:
	for cat in ["bodice", "skirt", "sleeve"]:
		var seen := {}
		for g in Content.garments_in(cat):
			check(g.outline.size() >= 4, "%s has a real outline" % g.id)
			var key := str(g.outline)
			check(not seen.has(key), "%s has a unique silhouette" % g.id)
			seen[key] = true
			var area := absf(_area(g.outline))
			check(area > 0.05, "%s outline has area" % g.id)
	done()


func test_unique_ids() -> void:
	var ids := {}
	for list in [Content.bodies, Content.garments, Content.fabrics, Content.shoes, Content.hairstyles, Content.jewelry]:
		for item in list:
			check(not ids.has(item.id), "unique id %s" % item.id)
			ids[item.id] = true
	done()


func test_fabrics() -> void:
	check(Content.fabrics.size() >= 12, "at least 12 fabrics")
	for f in Content.fabrics:
		check(f.texture != null, "%s has a texture" % f.id)
	for g in Content.garments:
		check(Content.get_fabric(g.default_fabric).id == g.default_fabric, "%s default fabric exists" % g.id)
	done()


func test_shoes_have_colorable_regions() -> void:
	check_eq(Content.shoes.size(), 20, "20 shoes")
	var silhouettes := {}
	for s in Content.shoes:
		check(s.region_names.size() >= 3, "%s has at least 3 colorable regions" % s.id)
		check_eq(s.region_names.size(), s.region_defaults.size(), "%s region defaults" % s.id)
		var used := {}
		for sh in s.shapes:
			used[sh["r"]] = true
			check(sh["r"] < s.region_names.size(), "%s shape region in range" % s.id)
		check_eq(used.size(), s.region_names.size(), "%s every region is used" % s.id)
		var key := str(s.shapes[0]["p"])
		check(not silhouettes.has(key) or s.shapes.size() != silhouettes[key], "%s distinct design" % s.id)
		silhouettes[key] = s.shapes.size()
	done()


func test_hairstyles() -> void:
	check_eq(Content.hairstyles.size(), 30, "30 hairstyles")
	var single := 0
	var multi := 0
	for h in Content.hairstyles:
		if h.color_count == 1:
			single += 1
		else:
			multi += 1
			check(h.color_count >= 2 and h.color_count <= 3, "%s has 2-3 colors" % h.id)
		var regions := {}
		for sh in h.back_shapes + h.front_shapes:
			regions[sh["r"]] = true
		check_eq(regions.size(), h.color_count, "%s uses exactly its color slots" % h.id)
		check(not (h.back_shapes + h.front_shapes).is_empty(), "%s has shapes" % h.id)
	check_eq(single, 20, "20 single-color hairstyles")
	check_eq(multi, 10, "10 multicolor hairstyles")
	done()


func test_jewelry_categories() -> void:
	for cat in DressDesign.JEWELRY_CATEGORIES:
		check(Content.jewelry_in(cat).size() >= 4, "at least 4 %s designs" % cat)
	done()


func test_playlist() -> void:
	check(Content.playlist != null and Content.playlist.tracks.size() >= 5, "radio has at least 5 tracks")
	for t in Content.playlist.tracks:
		check(t.stream != null, "%s has audio" % t.title)
	done()


static func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in range(p.size()):
		var q := p[(i + 1) % p.size()]
		a += p[i].x * q.y - q.x * p[i].y
	return a * 0.5
