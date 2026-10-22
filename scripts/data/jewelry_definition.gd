class_name JewelryDefinition
extends Resource
## A jewelry design. Shapes use region 0 = metal, 1 = gem.
## Paired items (earrings, bracelets, anklets) are authored for the screen-right side and mirrored.
## Units: pixels for a reference body; scaled by the anchor's natural size at runtime.

@export var id: String = ""
@export var display_name: String = ""
@export_enum("earrings", "necklace", "bracelet", "anklet", "tiara") var category: String = "earrings"
@export var shapes: Array[Dictionary] = []
@export var default_metal: Color = Color(0.85, 0.7, 0.35)
@export var default_gem: Color = Color(0.95, 0.95, 0.92)
