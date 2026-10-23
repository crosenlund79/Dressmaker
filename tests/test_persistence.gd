extends TestCase
## Save / load serialization.

const DIR := "user://test_designs"


func _custom_design() -> DressDesign:
	var d := DesignFactory.default_design()
	d.body_id = "pear"
	d.skin_color = Color("8d5a3b")
	DesignFactory.set_template(d, "skirt", "skirt_bustle", true)
	var s := d.garment("skirt")
	s.material.fabric_id = "tartan"
	s.material.primary = Color("123456")
	s.material.pattern_scale = 2.5
	s.material.pattern_rotation = 30.0
	s.offset = Vector2(12, -7)
	s.scale = Vector2(1.4, 0.9)
	s.rotation = 0.25
	s.skew = Vector2(0.1, -0.2)
	s.bend = 0.7
	s.flare = 0.4
	var lat := s.get_lattice()
	lat[5] = Vector2(0.3, -0.2)
	s.lattice = lat
	d.sleeves_linked = false
	DesignFactory.set_template(d, "sleeve_left", "sleeve_butterfly", true)
	DesignFactory.set_shoe(d, "shoe_wedge")
	d.shoe_colors[0] = Color("ff00aa")
	DesignFactory.set_hair(d, "hair_ombre_long")
	d.hair_colors[2] = Color("00ffcc")
	DesignFactory.set_jewelry(d, "tiara", "tiara_floral")
	d.jewelry["tiara"]["gem"] = Color("abcdef")
	d.jewelry["earrings"]["visible"] = false
	return d


func test_dict_round_trip() -> void:
	var d := _custom_design()
	var copy := DressDesign.new()
	copy.from_dict(d.to_dict())
	check_eq(JSON.stringify(copy.to_dict()), JSON.stringify(d.to_dict()), "to_dict/from_dict round trip is lossless")
	done()


func test_save_load_list_delete() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	var d := _custom_design()
	check_eq(DesignPersistence.save_design(d, "Tartan Bustle!", null, DIR), OK, "save succeeds")
	check(DesignPersistence.exists("Tartan Bustle!", DIR), "saved file exists")
	var listed := DesignPersistence.list_designs(DIR)
	check_eq(listed.size(), 1, "one design listed")
	check_eq(listed[0]["name"], "Tartan Bustle!", "listed name")
	var loaded := DesignPersistence.load_design(listed[0]["path"])
	check(loaded != null, "design loads")
	check_eq(JSON.stringify(loaded.to_dict()), JSON.stringify(d.to_dict()), "loaded design matches saved design")
	check_eq(loaded.garment("skirt").lattice[5], Vector2(0.3, -0.2), "deformation control points restored")
	# Overwrite with a change.
	d.garment("skirt").material.primary = Color("654321")
	DesignPersistence.save_design(d, "Tartan Bustle!", null, DIR)
	check_eq(DesignPersistence.list_designs(DIR).size(), 1, "overwrite keeps a single file")
	check_eq(DesignPersistence.load_design(listed[0]["path"]).garment("skirt").material.primary.to_html(false), "654321", "overwrite stored the new color")
	DesignPersistence.delete_design(listed[0]["path"])
	check_eq(DesignPersistence.list_designs(DIR).size(), 0, "design deleted")
	done()


func test_versioned_format() -> void:
	var data := _custom_design().to_save_data("x")
	check_eq(data["format"], DressDesign.FORMAT_ID, "format id written")
	check_eq(data["version"], DressDesign.FORMAT_VERSION, "version written")
	var bad := data.duplicate(true)
	bad["format"] = "something_else"
	check(DressDesign.from_save_data(bad) == null, "foreign files are rejected")
	var future := data.duplicate(true)
	future["version"] = DressDesign.FORMAT_VERSION + 1
	check(DressDesign.from_save_data(future) == null, "newer versions are rejected")
	# JSON numbers come back as floats; loading must still work.
	var reparsed: Dictionary = JSON.parse_string(JSON.stringify(data))
	check(DressDesign.from_save_data(reparsed) != null, "JSON round trip loads")
	done()


func test_slugify() -> void:
	check_eq(DesignPersistence.slugify("  My Lovely Dress!! "), "my_lovely_dress", "slug")
	check_eq(DesignPersistence.slugify("???"), "design", "fallback slug")
	done()
