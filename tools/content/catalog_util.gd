class_name CatalogUtil
extends RefCounted
## Geometry helpers for authoring content (used by tools/build_content.gd).


static func v(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in arr:
		out.append(Vector2(p[0], p[1]))
	return out


## Builds a symmetric outline from a right half that starts and ends on the center line
## (x = 0), listed from the top center clockwise to the bottom center.
static func sym(half: Array) -> PackedVector2Array:
	var right := v(half)
	var out := right.duplicate()
	for i in range(right.size() - 2, 0, -1):
		out.append(Vector2(-right[i].x, right[i].y))
	return out


static func mirror_x(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(Vector2(-p.x, p.y))
	return out


## Returns the given lines plus their mirror images.
static func mirrored_lines(lines: Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for l in lines:
		var pl: PackedVector2Array = l if l is PackedVector2Array else v(l)
		out.append(pl)
		out.append(mirror_x(pl))
	return out


static func lines(arr: Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for l in arr:
		out.append(l if l is PackedVector2Array else v(l))
	return out


static func mirrored_dots(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in arr:
		out.append(Vector2(p[0], p[1]))
		if absf(p[0]) > 0.0001:
			out.append(Vector2(-p[0], p[1]))
	return out


## A polyline with a sinusoidal perpendicular ripple (ruffles, scallops).
## `aspect` rescales x relative to y so the ripple is perpendicular in visual space.
static func wave(points: PackedVector2Array, waves_per_segment: int, amp: float, samples_per_wave: int = 6) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var d := b - a
		var n := Vector2(-d.y, d.x).normalized()
		var steps := waves_per_segment * samples_per_wave
		for s in range(steps):
			var t := float(s) / steps
			out.append(a + d * t + n * sin(t * waves_per_segment * TAU) * amp)
	out.append(points[points.size() - 1])
	return out


## Scallops: semicircular bumps (always to the same side) along a straight segment.
static func scallops(a: Vector2, b: Vector2, count: int, amp: float, samples: int = 6) -> PackedVector2Array:
	var out := PackedVector2Array()
	var d := b - a
	var n := Vector2(-d.y, d.x).normalized()
	for c in range(count):
		for s in range(samples):
			var t := (c + float(s) / samples) / count
			out.append(a + d * t + n * absf(sin((float(s) / samples) * PI)) * amp)
	out.append(b)
	return out


static func ellipse(center: Vector2, rx: float, ry: float, deg_from: float, deg_to: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(n + 1):
		var a := deg_to_rad(lerpf(deg_from, deg_to, float(i) / n))
		out.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return out


static func zigzag(x_amp: float, y_from: float, y_to: float, count: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(count + 1):
		out.append(Vector2(x_amp if i % 2 == 0 else -x_amp, lerpf(y_from, y_to, float(i) / count)))
	return out


static func concat(parts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for part in parts:
		var pv: PackedVector2Array = part if part is PackedVector2Array else v(part)
		out.append_array(pv)
	return out


static func translate(points: PackedVector2Array, off: Vector2, scale: Vector2 = Vector2.ONE) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p * scale + off)
	return out


## Generic shape dictionaries used by shoes, hair and jewelry.
static func poly(region: int, points: PackedVector2Array, shade: float = 1.0) -> Dictionary:
	return {"k": "poly", "r": region, "p": points, "shade": shade}


static func line(region: int, points: PackedVector2Array, width: float, shade: float = 1.0) -> Dictionary:
	return {"k": "line", "r": region, "p": points, "w": width, "shade": shade}


static func circle(region: int, center: Vector2, radius: float, shade: float = 1.0) -> Dictionary:
	return {"k": "circle", "r": region, "p": PackedVector2Array([center]), "rad": radius, "shade": shade}
