class_name DesignFactory
extends RefCounted
## Creates starting designs and applies template defaults to garment slots.


static func default_design() -> DressDesign:
	var d := DressDesign.new()
	var body := Content.get_body("classic")
	d.body_id = body.id if body else "classic"
	if body:
		d.skin_color = body.skin_color
	set_template(d, "bodice", "bodice_victorian", true)
	set_template(d, "skirt", "skirt_full_victorian", true)
	set_template(d, "sleeve_right", "sleeve_long_fitted", true)
	d.sync_sleeves("sleeve_right")
	# Coordinate the starter outfit.
	for slot in DressDesign.GARMENT_SLOTS:
		var m := d.garment(slot).material
		m.primary = Color.html("7b2d3a")
		m.trim = Color.html("d9b25c")
	d.garment("skirt").material.fabric_id = "velvet"
	d.garment("sleeve_left").material.fabric_id = "velvet"
	d.garment("sleeve_right").material.fabric_id = "velvet"
	set_shoe(d, "shoe_button_boot")
	set_hair(d, "hair_victorian_updo")
	d.jewelry["earrings"]["id"] = "earring_drop_pearl"
	d.jewelry["necklace"]["id"] = "necklace_pearl_strand"
	_apply_jewelry_defaults(d, "earrings")
	_apply_jewelry_defaults(d, "necklace")
	return d


## Assigns a template to a slot. When `apply_defaults` is true (or the slot was empty)
## the template's default fabric and colors are used; otherwise the player's material is kept.
static func set_template(d: DressDesign, slot: String, template_id: String, apply_defaults: bool = false) -> void:
	var inst := d.garment(slot)
	var was_empty := inst.is_empty()
	inst.template_id = template_id
	inst.reset_lattice()
	var def := Content.get_garment(template_id)
	if def and (apply_defaults or was_empty):
		inst.material.fabric_id = def.default_fabric
		inst.material.primary = def.default_color
		inst.material.secondary = def.default_secondary
		inst.material.trim = def.default_trim
	inst.visible = true


static func set_shoe(d: DressDesign, shoe_id: String) -> void:
	d.shoe_id = shoe_id
	var s := Content.get_shoe(shoe_id)
	d.shoe_colors = s.region_defaults.duplicate() if s else PackedColorArray()


static func set_hair(d: DressDesign, hair_id: String, keep_colors: bool = false) -> void:
	d.hair_id = hair_id
	var h := Content.get_hair(hair_id)
	if h == null or keep_colors:
		return
	var cols := h.default_colors.duplicate()
	while cols.size() < 3:
		cols.append(cols[cols.size() - 1] if cols.size() > 0 else Color(0.35, 0.22, 0.13))
	d.hair_colors = cols


static func _apply_jewelry_defaults(d: DressDesign, cat: String) -> void:
	var j := Content.get_jewelry(d.jewelry[cat]["id"])
	if j:
		d.jewelry[cat]["metal"] = j.default_metal
		d.jewelry[cat]["gem"] = j.default_gem


static func set_jewelry(d: DressDesign, cat: String, jewelry_id: String) -> void:
	var was_empty: bool = d.jewelry[cat]["id"] == ""
	d.jewelry[cat]["id"] = jewelry_id
	d.jewelry[cat]["visible"] = true
	if was_empty:
		_apply_jewelry_defaults(d, cat)
