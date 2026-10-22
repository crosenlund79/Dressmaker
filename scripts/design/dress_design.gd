class_name DressDesign
extends RefCounted
## The complete, serializable state of an outfit.
## Everything needed to reconstruct a design lives here (no screenshots).

const FORMAT_ID := "sandrines_dresses_design"
const FORMAT_VERSION := 1
const GARMENT_SLOTS := ["bodice", "skirt", "sleeve_left", "sleeve_right"]
const JEWELRY_CATEGORIES := ["earrings", "necklace", "bracelet", "anklet", "tiara"]

var body_id: String = "classic"
var skin_color: Color = Color(0.96, 0.82, 0.72)
var garments: Dictionary = {}  # slot -> GarmentInstance
var sleeves_linked: bool = true
var waistband: bool = true
var waistband_color: Color = Color(0.85, 0.72, 0.4)

var shoe_id: String = ""
var shoe_colors: PackedColorArray = PackedColorArray()

var hair_id: String = ""
var hair_colors: PackedColorArray = PackedColorArray([Color(0.35, 0.22, 0.13), Color(0.8, 0.6, 0.3), Color(0.9, 0.85, 0.7)])

## category -> {"id": String, "visible": bool, "metal": Color, "gem": Color}
var jewelry: Dictionary = {}


func _init() -> void:
	for slot in GARMENT_SLOTS:
		garments[slot] = GarmentInstance.new()
	for cat in JEWELRY_CATEGORIES:
		jewelry[cat] = {"id": "", "visible": true, "metal": Color(0.85, 0.7, 0.35), "gem": Color(0.95, 0.95, 0.92)}


func garment(slot: String) -> GarmentInstance:
	return garments.get(slot)


static func sleeve_side(slot: String) -> int:
	return -1 if slot == "sleeve_left" else 1


static func is_garment_slot(slot: String) -> bool:
	return slot in GARMENT_SLOTS


static func is_sleeve_slot(slot: String) -> bool:
	return slot == "sleeve_left" or slot == "sleeve_right"


static func other_sleeve(slot: String) -> String:
	return "sleeve_right" if slot == "sleeve_left" else "sleeve_left"


## Mirrors one sleeve onto the other when the sleeves are linked.
func sync_sleeves(from_slot: String) -> void:
	if not sleeves_linked or not is_sleeve_slot(from_slot):
		return
	garment(from_slot).copy_mirrored_to(garment(other_sleeve(from_slot)))


func get_jewelry(cat: String) -> Dictionary:
	return jewelry.get(cat, {})


func to_dict() -> Dictionary:
	var g := {}
	for slot in GARMENT_SLOTS:
		g[slot] = garment(slot).to_dict()
	var j := {}
	for cat in JEWELRY_CATEGORIES:
		var e: Dictionary = jewelry[cat]
		j[cat] = {
			"id": e["id"],
			"visible": e["visible"],
			"metal": (e["metal"] as Color).to_html(true),
			"gem": (e["gem"] as Color).to_html(true),
		}
	return {
		"body": body_id,
		"skin": skin_color.to_html(true),
		"garments": g,
		"sleeves_linked": sleeves_linked,
		"waistband": waistband,
		"waistband_color": waistband_color.to_html(true),
		"shoes": {"id": shoe_id, "colors": _colors_to_array(shoe_colors)},
		"hair": {"id": hair_id, "colors": _colors_to_array(hair_colors)},
		"jewelry": j,
	}


func from_dict(d: Dictionary) -> void:
	body_id = str(d.get("body", "classic"))
	skin_color = DesignUtil.color(d.get("skin"), Color(0.96, 0.82, 0.72))
	var g: Dictionary = d.get("garments", {})
	for slot in GARMENT_SLOTS:
		var inst := GarmentInstance.new()
		inst.from_dict(g.get(slot, {}))
		garments[slot] = inst
	sleeves_linked = bool(d.get("sleeves_linked", true))
	waistband = bool(d.get("waistband", true))
	waistband_color = DesignUtil.color(d.get("waistband_color"), Color(0.85, 0.72, 0.4))
	var s: Dictionary = d.get("shoes", {})
	shoe_id = str(s.get("id", ""))
	shoe_colors = _array_to_colors(s.get("colors", []))
	var h: Dictionary = d.get("hair", {})
	hair_id = str(h.get("id", ""))
	hair_colors = _array_to_colors(h.get("colors", []))
	while hair_colors.size() < 3:
		hair_colors.append(Color(0.35, 0.22, 0.13))
	var j: Dictionary = d.get("jewelry", {})
	for cat in JEWELRY_CATEGORIES:
		var e: Dictionary = j.get(cat, {})
		jewelry[cat] = {
			"id": str(e.get("id", "")),
			"visible": bool(e.get("visible", true)),
			"metal": DesignUtil.color(e.get("metal"), Color(0.85, 0.7, 0.35)),
			"gem": DesignUtil.color(e.get("gem"), Color(0.95, 0.95, 0.92)),
		}


func duplicate_design() -> DressDesign:
	var d := DressDesign.new()
	d.from_dict(to_dict())
	return d


## Wraps the design in the versioned save envelope.
func to_save_data(design_name: String) -> Dictionary:
	return {
		"format": FORMAT_ID,
		"version": FORMAT_VERSION,
		"name": design_name,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"design": to_dict(),
	}


static func from_save_data(data: Dictionary) -> DressDesign:
	if str(data.get("format", "")) != FORMAT_ID:
		return null
	var version := int(data.get("version", 0))
	if version < 1 or version > FORMAT_VERSION:
		return null
	var d := DressDesign.new()
	d.from_dict(data.get("design", {}))
	return d


static func _colors_to_array(colors: PackedColorArray) -> Array:
	var out: Array = []
	for c in colors:
		out.append(c.to_html(true))
	return out


static func _array_to_colors(arr: Variant) -> PackedColorArray:
	var out := PackedColorArray()
	if arr is Array:
		for v in arr:
			out.append(DesignUtil.color(v, Color.WHITE))
	return out
