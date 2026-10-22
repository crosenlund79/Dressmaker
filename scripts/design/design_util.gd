class_name DesignUtil
extends RefCounted
## Small helpers for (de)serializing design data.


static func color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String and Color.html_is_valid(value):
		return Color.html(value)
	return fallback


static func vec2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


static func vec2_to_array(v: Vector2) -> Array:
	return [snappedf(v.x, 0.0001), snappedf(v.y, 0.0001)]
