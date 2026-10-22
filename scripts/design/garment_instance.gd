class_name GarmentInstance
extends RefCounted
## A garment slot in a design: the chosen template plus all player customization.

const LATTICE_SIZE := 4  # 4x4 cubic free-form-deformation cage

var template_id: String = ""
var material: FabricMaterial = FabricMaterial.new()
var visible: bool = true
## Skirt: pinned to the bodice waist seam. Sleeves: follow the bodice shoulders.
var attached: bool = true
## Draw-order option: bodice over/under skirt, sleeves over/under bodice.
var layer_front: bool = false

# Basic transform (applied around the garment's pivot / seam anchor).
var offset: Vector2 = Vector2.ZERO
var scale: Vector2 = Vector2.ONE
var rotation: float = 0.0  # radians
var skew: Vector2 = Vector2.ZERO  # radians (horizontal, vertical)
var bend: float = 0.0
var flare: float = 0.0

## Advanced mode: cage control point offsets in the garment's local frame, row-major (y, x).
var lattice: PackedVector2Array = PackedVector2Array()


func is_empty() -> bool:
	return template_id == ""


func reset_transform() -> void:
	offset = Vector2.ZERO
	scale = Vector2.ONE
	rotation = 0.0
	skew = Vector2.ZERO
	bend = 0.0
	flare = 0.0


func reset_lattice() -> void:
	lattice = PackedVector2Array()


func get_lattice() -> PackedVector2Array:
	if lattice.size() != LATTICE_SIZE * LATTICE_SIZE:
		var l := PackedVector2Array()
		l.resize(LATTICE_SIZE * LATTICE_SIZE)
		return l
	return lattice


func has_lattice_edits() -> bool:
	for p in lattice:
		if p.length_squared() > 1e-8:
			return true
	return false


func to_dict() -> Dictionary:
	var lat: Array = []
	for p in get_lattice():
		lat.append(DesignUtil.vec2_to_array(p))
	return {
		"template": template_id,
		"material": material.to_dict(),
		"visible": visible,
		"attached": attached,
		"layer_front": layer_front,
		"offset": DesignUtil.vec2_to_array(offset),
		"scale": DesignUtil.vec2_to_array(scale),
		"rotation": rotation,
		"skew": DesignUtil.vec2_to_array(skew),
		"bend": bend,
		"flare": flare,
		"lattice": lat,
	}


func from_dict(d: Dictionary) -> void:
	template_id = str(d.get("template", ""))
	material = FabricMaterial.new()
	material.from_dict(d.get("material", {}))
	visible = bool(d.get("visible", true))
	attached = bool(d.get("attached", true))
	layer_front = bool(d.get("layer_front", false))
	offset = DesignUtil.vec2(d.get("offset"), Vector2.ZERO)
	scale = DesignUtil.vec2(d.get("scale"), Vector2.ONE)
	rotation = float(d.get("rotation", 0.0))
	skew = DesignUtil.vec2(d.get("skew"), Vector2.ZERO)
	bend = float(d.get("bend", 0.0))
	flare = float(d.get("flare", 0.0))
	lattice = PackedVector2Array()
	var lat: Array = d.get("lattice", [])
	if lat.size() == LATTICE_SIZE * LATTICE_SIZE:
		for item in lat:
			lattice.append(DesignUtil.vec2(item, Vector2.ZERO))


## Copies this instance onto `target` mirrored across the body's center line
## (used for linked left/right sleeves).
func copy_mirrored_to(target: GarmentInstance) -> void:
	target.from_dict(to_dict())
	target.offset.x = -offset.x
	target.rotation = -rotation
	target.skew = -skew
