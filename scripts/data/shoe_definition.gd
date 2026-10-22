class_name ShoeDefinition
extends Resource
## A shoe drawn in profile for the screen-right foot (toe pointing +x) and mirrored for the left.
## Coordinates are pixels relative to the floor point below the ankle; -y is up.
## Each shape belongs to an independently colorable region.

@export var id: String = ""
@export var display_name: String = ""
@export var region_names: PackedStringArray = PackedStringArray()
@export var region_defaults: PackedColorArray = PackedColorArray()
## Shape dictionaries: {k: "poly"|"line"|"circle", r: region, p: PackedVector2Array, w: width, rad: radius, shade: float}
@export var shapes: Array[Dictionary] = []
## How far the heel lifts the body (pixels).
@export var heel_lift: float = 0.0
