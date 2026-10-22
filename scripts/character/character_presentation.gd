class_name CharacterPresentation
extends Node2D
## Assembles the model: body, garments, shoes, hair and jewelry in a fixed,
## consistent drawing order, and rebuilds garment geometry when the design changes.
##
## Drawing order (back to front):
##   hair back, legs, shoes, anklets, torso/arms, skirt, sleeves, bodice, waistband,
##   hands, necklace, bracelets, head, earrings, hair front, tiara
## Layer options: a bodice can be tucked under the skirt; sleeves can go over the bodice.

signal geometry_rebuilt

var design: DressDesign
var body: BodyDefinition
var selected_slot: String = ""
var idle_enabled: bool = true
var interactive: bool = true

var shapes: Dictionary = {}  # slot -> GarmentShape (or absent)
var heel_lift: float = 0.0

var rig: Node2D
var hair_back: HairRenderer
var legs: BodyRenderer
var shoes: ShoeRenderer
var anklets: JewelryRenderer
var torso: BodyRenderer
var garment_nodes: Dictionary = {}  # slot -> GarmentRenderer
var waistband: WaistbandRenderer
var hands: BodyRenderer
var necklace: JewelryRenderer
var bracelets: JewelryRenderer
var head: BodyRenderer
var earrings: JewelryRenderer
var hair_front: HairRenderer
var tiara: JewelryRenderer

var _shape_keys: Dictionary = {}
var _time := 0.0
var _blink_timer := 3.0
var _idle_weight := 0.0
var _last_activity := -100.0


func _init() -> void:
	rig = Node2D.new()
	rig.name = "Rig"
	add_child(rig)
	hair_back = _add(HairRenderer.new(), "HairBack")
	hair_back.front = false
	legs = _add(BodyRenderer.new().setup(BodyRenderer.Part.LEGS), "Legs")
	shoes = _add(ShoeRenderer.new(), "Shoes")
	anklets = _jewel("anklet")
	torso = _add(BodyRenderer.new().setup(BodyRenderer.Part.TORSO), "Torso")
	for slot in ["skirt", "sleeve_left", "sleeve_right", "bodice"]:
		garment_nodes[slot] = _add(GarmentRenderer.new(slot), "Garment_" + slot)
	waistband = _add(WaistbandRenderer.new(), "Waistband")
	hands = _add(BodyRenderer.new().setup(BodyRenderer.Part.HANDS), "Hands")
	necklace = _jewel("necklace")
	bracelets = _jewel("bracelet")
	head = _add(BodyRenderer.new().setup(BodyRenderer.Part.HEAD), "Head")
	earrings = _jewel("earrings")
	hair_front = _add(HairRenderer.new(), "HairFront")
	tiara = _jewel("tiara")


func _add(node: Node2D, node_name: String) -> Variant:
	node.name = node_name
	rig.add_child(node)
	return node


func _jewel(cat: String) -> JewelryRenderer:
	var j := JewelryRenderer.new()
	j.category = cat
	return _add(j, "Jewelry_" + cat)


func _process(delta: float) -> void:
	_time += delta
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		head.blink = not head.blink
		_blink_timer = 0.13 if head.blink else randf_range(2.5, 5.5)
		head.queue_redraw()
	# Gentle breathing, only while the player is not actively editing.
	var want_idle := idle_enabled and (_time - _last_activity) > 2.5
	_idle_weight = move_toward(_idle_weight, 1.0 if want_idle else 0.0, delta * (0.8 if want_idle else 8.0))
	var breath := sin(_time * 1.7) * 0.004 * _idle_weight
	rig.scale = Vector2(1.0 - breath * 0.3, 1.0 + breath)
	rig.position.y = -heel_lift


## Freezes the idle animation immediately (called on any editing input).
func note_activity() -> void:
	_last_activity = _time
	_idle_weight = 0.0
	rig.scale = Vector2.ONE


func set_design(d: DressDesign) -> void:
	design = d
	refresh()


func refresh() -> void:
	if design == null:
		return
	body = Content.get_body(design.body_id)
	if body == null:
		return
	var shoe_def := Content.get_shoe(design.shoe_id)
	heel_lift = (shoe_def.heel_lift * body.foot_scale) if shoe_def else 0.0
	rig.position.y = -heel_lift
	_rebuild_shapes()
	for node in [legs, torso, hands, head]:
		node.body = body
		node.skin = design.skin_color
		node.show_feet = shoe_def == null
		node.queue_redraw()
	shoes.body = body
	shoes.definition = shoe_def
	shoes.colors = design.shoe_colors
	shoes.position.y = heel_lift
	shoes.queue_redraw()
	var hair_def := Content.get_hair(design.hair_id)
	for hr in [hair_back, hair_front]:
		hr.body = body
		hr.definition = hair_def
		hr.colors = design.hair_colors
		hr.queue_redraw()
	for jr in [anklets, necklace, bracelets, earrings, tiara]:
		var e := design.get_jewelry(jr.category)
		jr.body = body
		jr.definition = Content.get_jewelry(e.get("id", "")) if e.get("visible", true) else null
		jr.metal = e.get("metal", Color.GOLD)
		jr.gem = e.get("gem", Color.WHITE)
		jr.crown_height = hair_def.crown_height if hair_def else 0.0
		jr.queue_redraw()
	_apply_layer_order()
	geometry_rebuilt.emit()


func _rebuild_shapes() -> void:
	var bodice_shape := _build_shape("bodice", null, "")
	var parent_key: String = _shape_keys.get("bodice", "")
	_build_shape("skirt", bodice_shape, parent_key)
	_build_shape("sleeve_left", bodice_shape, parent_key)
	_build_shape("sleeve_right", bodice_shape, parent_key)
	for slot in garment_nodes:
		var gr: GarmentRenderer = garment_nodes[slot]
		var shape: GarmentShape = shapes.get(slot)
		var fabric: FabricDefinition = Content.get_fabric(shape.instance.material.fabric_id) if shape else null
		gr.set_shape(shape, fabric)
		gr.set_selected(interactive and slot == selected_slot)
	var bodice_inst := design.garment("bodice")
	var skirt_inst := design.garment("skirt")
	waistband.shape = bodice_shape
	waistband.body = body
	waistband.color = design.waistband_color
	waistband.visible = design.waistband and shapes.has("skirt") and skirt_inst.visible and skirt_inst.attached \
		and bodice_inst.visible and bodice_shape != null
	waistband.queue_redraw()


## Builds (or reuses) the shape for a slot. Shapes are only recomputed when their
## inputs change, so editing one garment does not re-evaluate the others.
func _build_shape(slot: String, parent: GarmentShape, parent_key: String) -> GarmentShape:
	var inst := design.garment(slot)
	var def: GarmentDefinition = Content.get_garment(inst.template_id) if not inst.is_empty() else null
	if def == null:
		shapes.erase(slot)
		_shape_keys.erase(slot)
		return null
	var key := "%s|%s|%s" % [body.id, str(inst.to_dict()), parent_key]
	if _shape_keys.get(slot, "") == key and shapes.has(slot):
		return shapes[slot]
	var side := DressDesign.sleeve_side(slot) if DressDesign.is_sleeve_slot(slot) else 1
	var shape := GarmentShape.new(def, inst, body, side, parent)
	var fabric := Content.get_fabric(inst.material.fabric_id)
	shape.rebuild(fabric.tile_size if fabric else 96.0)
	shapes[slot] = shape
	_shape_keys[slot] = key
	return shape


func _apply_layer_order() -> void:
	var order: Array = [hair_back, legs, shoes, anklets, torso]
	var bodice_under := design.garment("bodice").layer_front  # "tuck under skirt"
	var sleeves_over := design.garment("sleeve_left").layer_front or design.garment("sleeve_right").layer_front
	var sk: Node = garment_nodes["skirt"]
	var bo: Node = garment_nodes["bodice"]
	var sl: Node = garment_nodes["sleeve_left"]
	var sr: Node = garment_nodes["sleeve_right"]
	if bodice_under:
		order.append_array([sl, sr, bo, sk, waistband] if not sleeves_over else [bo, sk, waistband, sl, sr])
	else:
		order.append_array([sk, sl, sr, bo, waistband] if not sleeves_over else [sk, bo, waistband, sl, sr])
	order.append_array([hands, necklace, bracelets, head, earrings, hair_front, tiara])
	for i in range(order.size()):
		rig.move_child(order[i], i)


func set_selected_slot(slot: String) -> void:
	selected_slot = slot
	for s in garment_nodes:
		(garment_nodes[s] as GarmentRenderer).set_selected(interactive and s == slot)


## Converts a point in this node's parent space to rig (model) space.
func to_model(local_point: Vector2) -> Vector2:
	return rig.transform.affine_inverse() * local_point


func model_to_global(model_point: Vector2) -> Vector2:
	return rig.get_global_transform() * model_point


## Returns the slot / item under a model-space point, front-most first.
func pick(model_point: Vector2) -> String:
	var order: Array = []
	for i in range(rig.get_child_count() - 1, -1, -1):
		order.append(rig.get_child(i))
	for node in order:
		if node is GarmentRenderer:
			var gr: GarmentRenderer = node
			if gr.visible and gr.shape and gr.shape.contains_point(model_point):
				return gr.slot
		elif node == hair_front and hair_front.contains_point(model_point):
			return "hair"
		elif node == shoes and shoes.definition and shoes.get_bounds().has_point(model_point - shoes.position):
			return "shoes"
	return ""


## Model-space bounds of a slot (for camera framing).
func slot_bounds(slot: String) -> Rect2:
	var shape: GarmentShape = shapes.get(slot)
	if shape and shape.outline_points.size() > 0:
		var r := Rect2(shape.outline_points[0], Vector2.ZERO)
		for p in shape.outline_points:
			r = r.expand(p)
		return r
	if body == null:
		return Rect2(-100, -600, 200, 600)
	match slot:
		"hair", "jewelry":
			return Rect2(-body.head_radius * 2, body.head_center_y - body.head_radius * 2, body.head_radius * 4, body.head_radius * 4)
		"shoes":
			return Rect2(-body.ankle_x - 50, body.ankle_y - 60, body.ankle_x * 2 + 100, 90)
	return Rect2(-body.hip_hw * 2.2, body.head_center_y - body.head_radius * 1.6, body.hip_hw * 4.4, -body.head_center_y + body.head_radius * 1.6 + 10)


class WaistbandRenderer extends Node2D:
	## Optional seam-covering trim drawn along the bodice/skirt waist seam.
	var shape: GarmentShape
	var body: BodyDefinition
	var color: Color = Color(0.85, 0.72, 0.4)

	func _draw() -> void:
		if shape == null:
			return
		var pts := PackedVector2Array()
		for i in range(25):
			pts.append(shape.waist_seam_point(lerpf(-1.04, 1.04, i / 24.0)))
		draw_polyline(pts, color.darkened(0.4), 8.5, true)
		draw_polyline(pts, color, 6.0, true)
		draw_polyline(pts, color.lightened(0.3), 1.2, true)
