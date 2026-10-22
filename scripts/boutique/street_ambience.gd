class_name StreetAmbience
extends Node2D
## The street outside: painted backdrop plus randomly spawned pedestrians and
## the occasional carriage. It is drawn behind the shop wall, so it is only
## visible through the windows. Moves with a parallax factor for depth.

const SIDEWALK_Y := -248.0
const ROAD_Y := -282.0
const PARALLAX := 0.35
const SHOP_SIGNS := ["Milliner", "Tea Rooms", "Apothecary", "Books", "Hatter", "Confectioner", "Tailor", "Florist"]

var camera: Camera2D
var _rng := RandomNumberGenerator.new()
var _spawn_timer := 1.0
var _carriage_timer := 12.0
var _people: Node2D
var _road: Node2D
var _backdrop: Backdrop


func _ready() -> void:
	_rng.randomize()
	_backdrop = Backdrop.new()
	_backdrop.rng_seed = 1851
	add_child(_backdrop)
	_road = Node2D.new()
	_road.name = "Road"
	add_child(_road)
	_people = Node2D.new()
	_people.name = "People"
	add_child(_people)
	# A few passers-by already on the street at startup.
	for i in range(4):
		_spawn_pedestrian(_rng.randf_range(-1200.0, 1200.0))


func _process(delta: float) -> void:
	if camera:
		position.x = camera.position.x * PARALLAX
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _rng.randf_range(2.5, 7.0)
		if _people.get_child_count() < 9:
			_spawn_pedestrian(INF)
	_carriage_timer -= delta
	if _carriage_timer <= 0.0:
		_carriage_timer = _rng.randf_range(25.0, 50.0)
		var c := Carriage.new()
		c.dir = 1.0 if _rng.randf() < 0.5 else -1.0
		c.position = Vector2(-1900.0 * c.dir, ROAD_Y)
		c.body_color = Color.html(["1f1f2b", "3b2a20", "2e4a3b", "5a1f2a"][_rng.randi() % 4])
		c.horse_color = Color.html(["3b2416", "6b4226", "1a1410", "c8b8a0"][_rng.randi() % 4])
		_road.add_child(c)


func _spawn_pedestrian(x: float) -> void:
	var p := Pedestrian.new()
	p.randomize_look(_rng)
	p.limit_x = 1900.0
	var start_x := x if x != INF else -1850.0 * p.dir
	p.position = Vector2(start_x, SIDEWALK_Y + _rng.randf_range(-6.0, 6.0))
	_people.add_child(p)


class Backdrop extends Node2D:
	## Opposite side of the street: sky, terraced shopfronts, lamp posts, road.
	var rng_seed := 1
	var _font: Font

	func _ready() -> void:
		_font = load("res://assets/fonts/LiberationSerif-Bold.ttf")

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = rng_seed
		# Sky.
		for i in range(12):
			var t := i / 12.0
			draw_rect(Rect2(-2200, -820 + t * 520, 4400, 44), Color("d7dfe3").lerp(Color("f1ece0"), t))
		# Distant rooftops.
		var roof := PackedVector2Array([Vector2(-2200, -560)])
		var x := -2200.0
		while x < 2200.0:
			var w := rng.randf_range(80, 200)
			var top := rng.randf_range(-690, -600)
			roof.append(Vector2(x, top))
			roof.append(Vector2(x + w * 0.15, top))
			roof.append(Vector2(x + w * 0.2, top - 30))
			roof.append(Vector2(x + w * 0.3, top - 30))
			roof.append(Vector2(x + w * 0.35, top))
			roof.append(Vector2(x + w, top))
			x += w
		roof.append(Vector2(2200, -560))
		ShapeDrawer.fill_polygon(self, roof, Color("b9bfc4"))
		# Shopfronts.
		var sx := -2200.0
		var palette := ["9c5b46", "e2d4b7", "a8b59a", "8b8f99", "c9a27e", "7d6a8a", "d8c3a5"]
		var sign_i := 0
		while sx < 2200.0:
			var w2 := rng.randf_range(240, 340)
			var top2 := rng.randf_range(-660, -590)
			var col := Color.html(palette[rng.randi() % palette.size()])
			draw_rect(Rect2(sx, top2, w2 - 4, -300 - top2), col)
			draw_rect(Rect2(sx - 4, top2 - 12, w2 + 4, 14), col.darkened(0.25))
			# Upper windows.
			for wx in range(3):
				var r := Rect2(sx + 24 + wx * (w2 - 48) / 3.0, top2 + 30, (w2 - 48) / 3.0 - 24, 60)
				draw_rect(r, Color("f3d9a0") if rng.randf() < 0.3 else Color("5d6c78"))
				draw_rect(r, col.darkened(0.45), false, 3.0)
			# Shop window, door, awning and sign.
			var shop_top := -420.0
			draw_rect(Rect2(sx + 16, shop_top, w2 - 110, 110), Color("6f7d86"))
			draw_rect(Rect2(sx + 16, shop_top, w2 - 110, 110), Color("3b2416"), false, 4.0)
			draw_rect(Rect2(sx + w2 - 80, shop_top - 10, 50, 120), Color("3b2a20"))
			var awning := Color.html(palette[(rng.randi() + 2) % palette.size()]).darkened(0.1)
			for k in range(8):
				var aw := (w2 - 20) / 8.0
				ShapeDrawer.fill_polygon(self, PackedVector2Array([Vector2(sx + 10 + k * aw, shop_top - 40), Vector2(sx + 10 + (k + 1) * aw, shop_top - 40), Vector2(sx + 12 + (k + 1) * aw, shop_top - 10), Vector2(sx + 8 + k * aw, shop_top - 10)]), awning if k % 2 == 0 else Color("f2ead8"))
			draw_rect(Rect2(sx + 20, shop_top - 78, w2 - 48, 32), Color("2e3b33"))
			draw_string(_font, Vector2(sx + 20, shop_top - 54), SHOP_SIGNS[sign_i % SHOP_SIGNS.size()], HORIZONTAL_ALIGNMENT_CENTER, w2 - 48, 20, Color("e8cf8a"))
			sign_i += 1
			sx += w2
		# Far pavement, road and near pavement.
		draw_rect(Rect2(-2200, -300, 4400, 14), Color("a69c8c"))
		draw_rect(Rect2(-2200, -286, 4400, 30), Color("7d7468"))
		for i in range(90):
			draw_line(Vector2(-2200 + i * 50, -284), Vector2(-2200 + i * 50 + 18, -258), Color("6c6458"), 1.0)
		draw_rect(Rect2(-2200, -258, 4400, 40), Color("b8ad9c"))
		# Gas lamps.
		var lx := -2100.0
		while lx < 2200.0:
			draw_line(Vector2(lx, -262), Vector2(lx, -470), Color("2a2a2a"), 5.0)
			draw_rect(Rect2(lx - 12, -505, 24, 34), Color("2a2a2a"))
			draw_rect(Rect2(lx - 8, -500, 16, 24), Color("ffe6a3"))
			draw_circle(Vector2(lx, -488), 30, Color(1, 0.9, 0.6, 0.12))
			lx += 520.0


class Carriage extends Node2D:
	var dir := 1.0
	var speed := 120.0
	var phase := 0.0
	var body_color := Color("1f1f2b")
	var horse_color := Color("3b2416")

	func _process(delta: float) -> void:
		position.x += dir * speed * delta
		phase += delta * 8.0
		scale = Vector2(dir * 0.8, 0.8)
		queue_redraw()
		if absf(position.x) > 2000.0:
			queue_free()

	func _draw() -> void:
		var o := Color(0.1, 0.08, 0.06)
		# Horse (in front, +x).
		var hx := 150.0
		var bob := sin(phase) * 2.0
		for k in range(4):
			var leg_x := hx - 30 + k * 20
			var swing := sin(phase + k * 1.6) * 8.0
			draw_line(Vector2(leg_x, -60 + bob), Vector2(leg_x + swing, 0), horse_color.darkened(0.2), 6.0, true)
		ShapeDrawer.fill_polygon(self, PackedVector2Array([Vector2(hx - 45, -95 + bob), Vector2(hx + 35, -95 + bob), Vector2(hx + 45, -60 + bob), Vector2(hx - 45, -55 + bob)]), horse_color)
		ShapeDrawer.fill_polygon(self, PackedVector2Array([Vector2(hx + 30, -95 + bob), Vector2(hx + 55, -140 + bob), Vector2(hx + 75, -135 + bob), Vector2(hx + 60, -110 + bob), Vector2(hx + 45, -80 + bob)]), horse_color)
		draw_line(Vector2(hx - 45, -90 + bob), Vector2(hx - 60, -60 + bob), horse_color.darkened(0.3), 5.0, true)
		draw_line(Vector2(hx - 45, -75), Vector2(40, -70), Color("2a1a10"), 3.0)
		# Cab.
		draw_rect(Rect2(-60, -150, 110, 110), body_color)
		draw_rect(Rect2(-45, -135, 40, 45), Color("c9d3d8"))
		draw_rect(Rect2(-60, -150, 110, 110), o, false, 2.0)
		draw_rect(Rect2(-70, -160, 130, 12), body_color.darkened(0.3))
		for wx in [-30.0, 40.0]:
			var c := Vector2(wx, -28)
			draw_arc(c, 28, 0, TAU, 20, Color("3b2416"), 5.0, true)
			for s in range(6):
				var a := phase * 0.6 + s * PI / 3.0
				draw_line(c, c + Vector2(cos(a), sin(a)) * 26, Color("5a3a22"), 2.0)
