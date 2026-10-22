class_name FabricDefinition
extends Resource
## A fabric pattern. The texture channels are interpreted by shaders/fabric.gdshader:
##   R = shading / weave detail (0.8 is neutral)
##   G = secondary-color mask (0 = primary color, 1 = secondary color)
##   B = additive sheen highlight
##   A = coverage (lace holes are transparent)

@export var id: String = ""
@export var display_name: String = ""
@export var texture: Texture2D
## Pixels of model space covered by one texture repeat at pattern scale 1.
@export var tile_size: float = 96.0
@export var default_color: Color = Color(0.8, 0.3, 0.35)
@export var default_secondary: Color = Color(0.95, 0.9, 0.8)
