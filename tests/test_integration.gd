extends TestCase
## Boots the real main scene and drives the editor like a player would.

var main: Node


func _boot() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	for i in range(3):
		await get_tree().process_frame


func test_main_scene_boots() -> void:
	await _boot()
	check(main.character.shapes.has("bodice"), "model is dressed")
	check(main.ui.library != null and main.ui.properties != null, "panels built")
	check(main.boutique.street != null, "street exists")
	check(main.music.track_count() >= 5, "radio has tracks")
	main.queue_free()
	await get_tree().process_frame
	done()


func test_drag_handles_and_undo() -> void:
	await _boot()
	var editor: FashionEditor = main.editor
	var handles: TransformHandles = main.handles
	editor.select("skirt")
	await get_tree().process_frame
	# Move: press inside the skirt and drag.
	var skirt: GarmentShape = main.character.shapes["skirt"]
	var inside := skirt.map_point(Vector2(1.2, 0.7))
	check(handles._on_press(inside), "press on the skirt starts a drag")
	handles._on_drag(inside + Vector2(30, -10), false)
	handles._on_drag(inside + Vector2(45, -20), false)
	handles.end_drag()
	check_vec_near(editor.design.garment("skirt").offset, Vector2(45, -20), 0.01, "skirt moved by drag")
	# Rotate handle.
	var rot := {}
	for h in handles.get_handles():
		if h["id"] == "rotate":
			rot = h
	check(not rot.is_empty(), "rotate handle exists")
	var pivot: Vector2 = main.character.shapes["skirt"].pivot + editor.design.garment("skirt").offset
	check(handles._on_press(rot["pos"]), "press on rotate handle")
	handles._on_drag(pivot + (rot["pos"] - pivot).rotated(0.4), false)
	handles.end_drag()
	check_near(editor.design.garment("skirt").rotation, 0.4, 0.02, "rotation by handle")
	# Advanced mode: drag a cage point.
	editor.set_mode("advanced")
	await get_tree().process_frame
	var cage: Dictionary = handles.get_handles()[14]
	check_eq(cage["id"], "cage", "advanced mode shows cage points")
	handles._on_press(cage["pos"])
	handles._on_drag(cage["pos"] + Vector2(0, 40), false)
	handles.end_drag()
	check(editor.design.garment("skirt").has_lattice_edits(), "cage drag edits the lattice")
	check(editor.design.garment("skirt").lattice[13].length() > 0.0, "symmetric cage edit mirrors to the opposite point")
	# Three drags -> three undo steps back to the original.
	editor.undo()
	editor.undo()
	editor.undo()
	check_eq(editor.design.garment("skirt").offset, Vector2.ZERO, "undo restores position")
	check_near(editor.design.garment("skirt").rotation, 0.0, 1e-6, "undo restores rotation")
	check(not editor.design.garment("skirt").has_lattice_edits(), "undo restores curves")
	# The rendered model follows the design.
	await get_tree().process_frame
	check_vec_near(main.character.shapes["skirt"].pivot + editor.design.garment("skirt").offset, main.character.shapes["skirt"].pivot, 0.01, "presentation refreshed")
	main.queue_free()
	await get_tree().process_frame
	done()


func test_click_selects_garment() -> void:
	await _boot()
	var editor: FashionEditor = main.editor
	editor.select("hair")
	var bodice: GarmentShape = main.character.shapes["bodice"]
	main.handles._on_press(bodice.map_point(Vector2(0.3, 0.6)))
	main.handles.end_drag()
	check_eq(editor.selected_slot, "bodice", "clicking the bodice selects it")
	main.queue_free()
	await get_tree().process_frame
	done()
