class_name HairDefinition
extends Resource
## A hairstyle in head-local units: origin at the head center, 1 unit = head radius, +y down.
## Back shapes are drawn behind the body; front shapes over the face.
## Shape "r" indexes the hair color slot (0..color_count-1).

@export var id: String = ""
@export var display_name: String = ""
@export_range(1, 3) var color_count: int = 1
@export var color_names: PackedStringArray = PackedStringArray(["Hair"])
@export var default_colors: PackedColorArray = PackedColorArray([Color(0.35, 0.22, 0.13)])
@export var back_shapes: Array[Dictionary] = []
@export var front_shapes: Array[Dictionary] = []
## Height of the hair above the top of the head (head units), used to seat tiaras.
@export var crown_height: float = 0.1
