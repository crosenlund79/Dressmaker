class_name Pedestrian
extends Node2D
## An ambient Victorian passer-by seen through the shop windows (side view).
## Appearance, colors, direction and speed are randomized.

const KINDS := ["lady", "lady", "gentleman", "gentleman", "maid", "worker", "lady_parasol"]
const DRESS_COLORS := ["7b2d3a", "2f5d50", "1f3a5f", "5a2a6e", "8a6d4b", "3b4f6b", "a35d6a", "4b5d3a", "c08497", "6d6875"]
const COAT_COLORS := ["2b2b2b", "3b2a20", "1f2a44", "4a3b2a", "5c4033", "2e4a3b", "6b6b6b"]
const SKIN := ["f5d0b5", "e8b996", "d39b72", "b07850", "8d5a3b", "6b4128"]
const HAIR := ["2b1b17", "5a3825", "8a3b1e", "d9b26f", "a89f91"]

var kind: String
var dir: float = 1.0
var speed: float = 60.0
var walk_phase: float = 0.0
var height: float = 160.0
var c_main: Color
var c_accent: Color
var c_skin: Color
var c_hair: Color
var c_hat: Color
var hat_style: int = 0
var limit_x: float = 2000.0


func randomize_look(rng: RandomNumberGenerator) -> void:
	kind = KINDS[rng.randi() % KINDS.size()]
	dir = 1.0 if rng.randf() < 0.5 else -1.0
	speed = rng.randf_range(42.0, 78.0)
	height = rng.randf_range(148.0, 172.0)
	walk_phase = rng.randf() * TAU
	var palette := DRESS_COLORS if kind.begins_with("lady") else COAT_COLORS
	c_main = Color.html(palette[rng.randi() % palette.size()])
	c_accent = Color.html(DRESS_COLORS[rng.randi() % DRESS_COLORS.size()]).lightened(0.25)
	c_skin = Color.html(SKIN[rng.randi() % SKIN.size()])
	c_hair = Color.html(HAIR[rng.randi() % HAIR.size()])
	c_hat = Color.html(COAT_COLORS[rng.randi() % COAT_COLORS.size()]) if rng.randf() < 0.6 else c_accent
	hat_style = rng.randi() % 3
	scale.x = dir


func _process(delta: float) -> void:
	position.x += dir * speed * delta
	walk_phase += delta * speed * 0.085
	queue_redraw()
	if absf(position.x) > limit_x:
		queue_free()


func _draw() -> void:
	var h := height
	var bob := absf(sin(walk_phase)) * 2.0
	var outline := Color(0.15, 0.1, 0.08, 0.9)
	var head_r := h * 0.075
	var head := Vector2(0, -h + head_r - bob)
	if kind.begins_with("lady") or kind == "maid":
		_draw_lady(h, bob, outline)
	else:
		_draw_gent(h, bob, outline)
	# Head, face profile and hair.
	draw_circle(head, head_r, c_skin)
	draw_arc(head, head_r, 0, TAU, 16, outline, 1.0, true)
	draw_circle(head + Vector2(head_r * 0.45, -head_r * 0.1), 1.2, outline)
	ShapeDrawer.fill_polygon(self, PackedVector2Array([head + Vector2(-head_r, -head_r * 0.2), head + Vector2(-head_r * 0.6, -head_r), head + Vector2(head_r * 0.5, -head_r * 0.95), head + Vector2(head_r * 0.2, -head_r * 0.4), head + Vector2(-head_r * 0.3, head_r * 0.6)]), c_hair)
	_draw_hat(head, head_r, outline)


func _draw_lady(h: float, bob: float, outline: Color) -> void:
	var waist := Vector2(0, -h * 0.58 - bob)
	var sway := sin(walk_phase) * 4.0
	var skirt_c := c_main if kind != "maid" else Color(0.15, 0.15, 0.18)
	var skirt := PackedVector2Array([waist + Vector2(-h * 0.07, 0), waist + Vector2(h * 0.07, 0), Vector2(h * 0.2 + sway, -2), Vector2(h * 0.16 + sway * 0.5, 0), Vector2(-h * 0.2 + sway, 0)])
	ShapeDrawer.fill_polygon(self, skirt, skirt_c)
	skirt.append(skirt[0])
	draw_polyline(skirt, outline, 1.0, true)
	if kind == "maid":
		ShapeDrawer.fill_polygon(self, PackedVector2Array([waist + Vector2(h * 0.02, 2), waist + Vector2(h * 0.075, 2), Vector2(h * 0.14 + sway * 0.5, -h * 0.12), Vector2(h * 0.04, -h * 0.1)]), Color(0.97, 0.96, 0.92))
	var torso := PackedVector2Array([waist + Vector2(-h * 0.065, 0), waist + Vector2(h * 0.07, 0), waist + Vector2(h * 0.085, -h * 0.2), waist + Vector2(-h * 0.07, -h * 0.22)])
	ShapeDrawer.fill_polygon(self, torso, skirt_c.darkened(0.08))
	var arm_swing := sin(walk_phase) * 0.35
	var shoulder := waist + Vector2(0, -h * 0.19)
	var hand := shoulder + Vector2(sin(arm_swing) * h * 0.2, cos(arm_swing) * h * 0.2)
	if kind == "lady_parasol":
		hand = shoulder + Vector2(h * 0.12, h * 0.02)
		var tip := hand + Vector2(-h * 0.05, -h * 0.42)
		draw_line(hand, tip, outline, 1.5)
		var canopy := PackedVector2Array()
		for i in range(9):
			var a := PI + PI * i / 8.0
			canopy.append(tip + Vector2(cos(a) * h * 0.2, sin(a) * h * 0.1 + h * 0.06))
		ShapeDrawer.fill_polygon(self, canopy, c_accent)
	draw_line(shoulder, hand, skirt_c.darkened(0.2), h * 0.035, true)
	draw_circle(hand, h * 0.02, c_skin)


func _draw_gent(h: float, bob: float, outline: Color) -> void:
	var hip := Vector2(0, -h * 0.45 - bob)
	var swing := sin(walk_phase) * 0.45
	var trousers := c_main.darkened(0.25) if kind == "gentleman" else Color(0.35, 0.3, 0.25)
	for s in [1.0, -1.0]:
		var foot := hip + Vector2(sin(swing * s) * h * 0.45, cos(swing * s) * h * 0.45)
		draw_line(hip, foot, trousers, h * 0.055, true)
		draw_line(foot, foot + Vector2(h * 0.06, 0), Color(0.1, 0.08, 0.06), h * 0.03, true)
	var coat_len := h * 0.22 if kind == "gentleman" else h * 0.12
	var coat := PackedVector2Array([hip + Vector2(-h * 0.08, -h * 0.28), hip + Vector2(h * 0.08, -h * 0.28), hip + Vector2(h * 0.09, coat_len), hip + Vector2(-h * 0.1, coat_len)])
	ShapeDrawer.fill_polygon(self, coat, c_main)
	coat.append(coat[0])
	draw_polyline(coat, outline, 1.0, true)
	var shoulder := hip + Vector2(0, -h * 0.26)
	var arm := shoulder + Vector2(-sin(swing) * h * 0.22, cos(swing) * h * 0.22)
	draw_line(shoulder, arm, c_main.darkened(0.15), h * 0.04, true)
	draw_circle(arm, h * 0.02, c_skin)
	if kind == "gentleman":
		draw_line(arm, arm + Vector2(h * 0.05, h * 0.32), Color(0.2, 0.12, 0.06), 2.0, true)


func _draw_hat(head: Vector2, r: float, outline: Color) -> void:
	match kind:
		"maid":
			ShapeDrawer.fill_polygon(self, PackedVector2Array([head + Vector2(-r, -r * 0.5), head + Vector2(r * 0.6, -r * 0.9), head + Vector2(r * 0.4, -r * 1.3), head + Vector2(-r * 0.8, -r * 1.1)]), Color(0.97, 0.96, 0.92))
		"lady", "lady_parasol":
			if hat_style == 0:  # bonnet
				var b := PackedVector2Array([head + Vector2(r * 0.9, -r * 0.2), head + Vector2(r * 0.7, -r * 1.3), head + Vector2(-r * 0.6, -r * 1.25), head + Vector2(-r * 1.0, -r * 0.1)])
				ShapeDrawer.fill_polygon(self, b, c_hat)
				draw_line(head + Vector2(-r * 0.6, r * 0.2), head + Vector2(r * 0.3, r * 0.8), c_accent, 1.5)
			else:  # wide hat with feather
				draw_line(head + Vector2(-r * 1.8, -r * 0.7), head + Vector2(r * 1.8, -r * 0.7), c_hat, r * 0.35, true)
				draw_rect(Rect2(head + Vector2(-r * 0.8, -r * 1.4), Vector2(r * 1.6, r * 0.7)), c_hat)
				draw_line(head + Vector2(-r * 0.5, -r * 1.3), head + Vector2(-r * 1.6, -r * 2.2), c_accent, r * 0.25, true)
		"gentleman":
			if hat_style == 2:  # bowler
				draw_circle(head + Vector2(0, -r * 0.8), r * 0.75, c_hat.darkened(0.3))
				draw_line(head + Vector2(-r * 1.1, -r * 0.55), head + Vector2(r * 1.1, -r * 0.55), c_hat.darkened(0.3), r * 0.25, true)
			else:  # top hat
				draw_rect(Rect2(head + Vector2(-r * 0.75, -r * 2.4), Vector2(r * 1.5, r * 1.8)), Color(0.08, 0.07, 0.07))
				draw_line(head + Vector2(-r * 1.2, -r * 0.62), head + Vector2(r * 1.2, -r * 0.62), Color(0.08, 0.07, 0.07), r * 0.25, true)
				draw_line(head + Vector2(-r * 0.75, -r * 0.95), head + Vector2(r * 0.75, -r * 0.95), c_accent.darkened(0.3), r * 0.25)
		_:
			ShapeDrawer.fill_polygon(self, PackedVector2Array([head + Vector2(-r, -r * 0.5), head + Vector2(r * 1.5, -r * 0.6), head + Vector2(r * 0.7, -r * 1.2), head + Vector2(-r * 0.8, -r * 1.2)]), c_hat)
	var _unused := outline
