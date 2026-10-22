class_name FabricMaterial
extends RefCounted
## Per-garment material settings: fabric pattern, colors and pattern placement.

var fabric_id: String = "cotton"
var primary: Color = Color(0.7, 0.2, 0.3)
var secondary: Color = Color(0.95, 0.9, 0.8)
var trim: Color = Color(0.85, 0.72, 0.4)
var pattern_scale: float = 1.0
var pattern_rotation: float = 0.0  # degrees
var opacity: float = 1.0


func to_dict() -> Dictionary:
	return {
		"fabric": fabric_id,
		"primary": primary.to_html(true),
		"secondary": secondary.to_html(true),
		"trim": trim.to_html(true),
		"pattern_scale": pattern_scale,
		"pattern_rotation": pattern_rotation,
		"opacity": opacity,
	}


func from_dict(d: Dictionary) -> void:
	fabric_id = str(d.get("fabric", fabric_id))
	primary = DesignUtil.color(d.get("primary"), primary)
	secondary = DesignUtil.color(d.get("secondary"), secondary)
	trim = DesignUtil.color(d.get("trim"), trim)
	pattern_scale = clampf(float(d.get("pattern_scale", pattern_scale)), 0.1, 8.0)
	pattern_rotation = float(d.get("pattern_rotation", pattern_rotation))
	opacity = clampf(float(d.get("opacity", opacity)), 0.05, 1.0)
