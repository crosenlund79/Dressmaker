extends TestCase
## Editor controller: undo/redo, merging and garment replacement.

var editor: FashionEditor


func _fresh() -> FashionEditor:
	if editor:
		editor.queue_free()
	editor = FashionEditor.new()
	add_child(editor)
	return editor


func test_color_change_undo_redo() -> void:
	var e := _fresh()
	var before := e.design.garment("bodice").material.primary
	e.change("Color", func(): e.design.garment("bodice").material.primary = Color.RED)
	check_eq(e.design.garment("bodice").material.primary, Color.RED, "color applied")
	e.undo()
	check_eq(e.design.garment("bodice").material.primary, before, "undo restores color")
	e.redo()
	check_eq(e.design.garment("bodice").material.primary, Color.RED, "redo reapplies color")
	done()


func test_texture_template_transform_and_curve_undo() -> void:
	var e := _fresh()
	var snapshot := JSON.stringify(e.design.to_dict())
	e.change("Fabric", func(): e.design.garment("skirt").material.fabric_id = "polka")
	e.change("Choose", func(): DesignFactory.set_template(e.design, "skirt", "skirt_mermaid"))
	e.change("Rotate", func(): e.design.garment("skirt").rotation = 0.5)
	e.change("Curve edit", func():
		var lat := e.design.garment("skirt").get_lattice()
		lat[0] = Vector2(0.2, 0.1)
		e.design.garment("skirt").lattice = lat)
	check_eq(e.design.garment("skirt").template_id, "skirt_mermaid", "template replaced")
	for i in range(4):
		e.undo()
	check_eq(JSON.stringify(e.design.to_dict()), snapshot, "four undos restore the original design")
	for i in range(4):
		e.redo()
	check_eq(e.design.garment("skirt").template_id, "skirt_mermaid", "redo restores template")
	check_eq(e.design.garment("skirt").lattice[0], Vector2(0.2, 0.1), "redo restores curve edit")
	check_near(e.design.garment("skirt").rotation, 0.5, 1e-6, "redo restores rotation")
	done()


func test_interaction_merges_into_one_step() -> void:
	var e := _fresh()
	e.begin_interaction("drag")
	for i in range(10):
		e.change("Move", func(): e.design.garment("bodice").offset = Vector2(i, 0))
	e.end_interaction()
	check_eq(e.design.garment("bodice").offset, Vector2(9, 0), "drag applied")
	e.undo()
	check_eq(e.design.garment("bodice").offset, Vector2.ZERO, "a whole drag undoes in one step")
	check(not e.can_undo(), "nothing else to undo")
	done()


func test_linked_sleeves_mirror_edits() -> void:
	var e := _fresh()
	e.select("sleeve_right")
	e.change("Rotate", func(): e.design.garment("sleeve_right").rotation = 0.3)
	e.change("Move", func(): e.design.garment("sleeve_right").offset = Vector2(10, 5))
	check_near(e.design.garment("sleeve_left").rotation, -0.3, 1e-6, "left sleeve rotation mirrored")
	check_eq(e.design.garment("sleeve_left").offset, Vector2(-10, 5), "left sleeve offset mirrored")
	e.change("Unlink", func(): e.design.sleeves_linked = false)
	e.change("Rotate", func(): e.design.garment("sleeve_right").rotation = 0.6)
	check_near(e.design.garment("sleeve_left").rotation, -0.3, 1e-6, "unlinked sleeves are independent")
	done()


func test_garment_replacement_keeps_player_colors() -> void:
	var e := _fresh()
	e.change("Color", func(): e.design.garment("skirt").material.primary = Color("abcdef"))
	e.change("Choose", func(): DesignFactory.set_template(e.design, "skirt", "skirt_tulip"))
	check_eq(e.design.garment("skirt").material.primary.to_html(false), "abcdef", "changing template keeps the chosen color")
	e.change("Remove", func(): e.design.garment("skirt").template_id = "")
	check(e.design.garment("skirt").is_empty(), "skirt removed")
	e.change("Choose", func(): DesignFactory.set_template(e.design, "skirt", "skirt_bell"))
	check_eq(e.design.garment("skirt").material.fabric_id, Content.get_garment("skirt_bell").default_fabric, "an empty slot gets template defaults")
	done()


func test_new_design_is_undoable() -> void:
	var e := _fresh()
	e.change("Body", func(): e.design.body_id = "petite")
	e.new_design()
	check_eq(e.design.body_id, "classic", "new design resets")
	e.undo()
	check_eq(e.design.body_id, "petite", "new design can be undone")
	done()
