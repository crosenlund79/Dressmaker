class_name Boutique
extends Node2D
## The Victorian dressmaking shop. All artwork is drawn procedurally in layers:
##   street (behind, parallax) -> wall with window openings -> floor -> furniture,
## plus an interactive radio and a cheval mirror that reflects the outfit.
## Model space origin (0, 0) is where the model's feet stand on the fitting platform.

signal radio_clicked

const WALL_TOP := -820.0
const WALL_BOTTOM := -40.0
const WINDOWS := [Rect2(-700, -700, 320, 470), Rect2(380, -700, 320, 470)]

var camera: Camera2D
var street: StreetAmbience
var wall: Wall
var floor_layer: FloorLayer
var furniture: Furniture
var radio: Radio
var mirror: Mirror


func _ready() -> void:
	street = StreetAmbience.new()
	street.name = "Street"
	street.camera = camera
	add_child(street)
	wall = Wall.new()
	wall.name = "Wall"
	add_child(wall)
	floor_layer = FloorLayer.new()
	floor_layer.name = "Floor"
	add_child(floor_layer)
	furniture = Furniture.new()
	furniture.name = "Furniture"
	add_child(furniture)
	mirror = Mirror.new()
	mirror.name = "Mirror"
	mirror.position = Vector2(300, 0)
	add_child(mirror)
	radio = Radio.new()
	radio.name = "Radio"
	radio.position = Vector2(520, -212)
	radio.clicked.connect(func(): radio_clicked.emit())
	add_child(radio)


# ============================================================================ wall
class Wall extends Node2D:
	func _draw() -> void:
		var paper := Color("eadbc4")
		var stripe := Color("e2cfb2")
		var wood := Color("7a4e32")
		var wood_dark := Color("5a3a22")
		var left := -2000.0
		var right := 2000.0
		# Wallpaper as rectangles around the window openings.
		var regions: Array[Rect2] = []
		var xs := [left, Boutique.WINDOWS[0].position.x, Boutique.WINDOWS[0].end.x, Boutique.WINDOWS[1].position.x, Boutique.WINDOWS[1].end.x, right]
		for i in range(0, xs.size() - 1):
			if i % 2 == 0:
				regions.append(Rect2(xs[i], Boutique.WALL_TOP, xs[i + 1] - xs[i], -230 - Boutique.WALL_TOP))
			else:
				var w: Rect2 = Boutique.WINDOWS[(i - 1) / 2]
				regions.append(Rect2(xs[i], Boutique.WALL_TOP, xs[i + 1] - xs[i], w.position.y - Boutique.WALL_TOP))
		for r in regions:
			draw_rect(r, paper)
			var sx := floorf(r.position.x / 60.0) * 60.0
			while sx < r.end.x:
				var a := maxf(sx, r.position.x)
				var b := minf(sx + 26.0, r.end.x)
				if b > a:
					draw_rect(Rect2(a, r.position.y, b - a, r.size.y), stripe)
				sx += 60.0
			# Damask motifs.
			var my := r.position.y + 40.0
			var row := 0
			while my < r.end.y - 20.0:
				var mx := floorf(r.position.x / 60.0) * 60.0 + 43.0 + (30.0 if row % 2 else 0.0)
				while mx < r.end.x - 6.0:
					if mx > r.position.x + 6.0:
						_motif(Vector2(mx, my), Color("d6bf9c"))
					mx += 60.0
				my += 70.0
				row += 1
		# Wainscoting.
		draw_rect(Rect2(left, -230, right - left, 190), wood)
		draw_rect(Rect2(left, -236, right - left, 12), wood_dark)
		var px := left + 20.0
		while px < right:
			draw_rect(Rect2(px, -205, 110, 140), wood.lightened(0.06))
			draw_rect(Rect2(px, -205, 110, 140), wood_dark, false, 3.0)
			px += 135.0
		draw_rect(Rect2(left, -52, right - left, 14), wood_dark)
		# Crown molding.
		draw_rect(Rect2(left, Boutique.WALL_TOP, right - left, 26), Color("f3e9d6"))
		draw_rect(Rect2(left, Boutique.WALL_TOP + 26, right - left, 6), Color("c9a24a"))
		for w in Boutique.WINDOWS:
			_window(w)
		# Wall sconces with a warm glow.
		for x in [-250.0, 250.0, 1000.0, -1000.0]:
			var c := Vector2(x, -600)
			for i in range(6):
				draw_circle(c, 120.0 - i * 18.0, Color(1.0, 0.85, 0.55, 0.035))
			draw_rect(Rect2(c.x - 4, c.y, 8, 40), Color("b08d57"))
			ShapeDrawer.fill_polygon(self, PackedVector2Array([c + Vector2(-16, -10), c + Vector2(16, -10), c + Vector2(10, 18), c + Vector2(-10, 18)]), Color("fff3cc"))
			draw_circle(c + Vector2(0, -2), 6, Color("fffbe8"))
		# Framed fashion plates.
		_frame(Rect2(-330, -650, 90, 120), Color("7b2d3a"))
		_frame(Rect2(-220, -620, 70, 90), Color("2f5d50"))
		_frame(Rect2(160, -640, 80, 105), Color("5a2a6e"))
		# Wall clock.
		var cc := Vector2(780, -620)
		draw_circle(cc, 46, Color("5a3a22"))
		draw_circle(cc, 38, Color("f8f1e2"))
		for h in range(12):
			var a := TAU * h / 12.0
			draw_line(cc + Vector2(cos(a), sin(a)) * 30, cc + Vector2(cos(a), sin(a)) * 35, Color("3b2416"), 2.0)
		draw_line(cc, cc + Vector2(0, -24), Color("3b2416"), 3.0)
		draw_line(cc, cc + Vector2(16, 6), Color("3b2416"), 3.0)

	func _motif(c: Vector2, col: Color) -> void:
		ShapeDrawer.fill_polygon(self, PackedVector2Array([c + Vector2(0, -12), c + Vector2(6, -3), c + Vector2(0, 10), c + Vector2(-6, -3)]), col)
		draw_circle(c + Vector2(-8, 4), 3, col)
		draw_circle(c + Vector2(8, 4), 3, col)

	func _window(w: Rect2) -> void:
		var frame := Color("5a3a22")
		# Glass sheen.
		ShapeDrawer.fill_polygon(self, PackedVector2Array([w.position + Vector2(40, 0), w.position + Vector2(110, 0), w.position + Vector2(10, 200), w.position + Vector2(0, 140)]), Color(1, 1, 1, 0.12))
		ShapeDrawer.fill_polygon(self, PackedVector2Array([w.end - Vector2(130, 470), w.end - Vector2(100, 470), w.end - Vector2(220, 230), w.end - Vector2(240, 260)]), Color(1, 1, 1, 0.08))
		# Mullions.
		for i in range(1, 3):
			var x := w.position.x + w.size.x * i / 3.0
			draw_line(Vector2(x, w.position.y), Vector2(x, w.end.y), frame, 7.0)
		for j in range(1, 3):
			var y := w.position.y + w.size.y * j / 3.0
			draw_line(Vector2(w.position.x, y), Vector2(w.end.x, y), frame, 7.0)
		draw_rect(w.grow(6), frame, false, 14.0)
		draw_rect(Rect2(w.position.x - 26, w.end.y + 4, w.size.x + 52, 16), Color("6b4428"))
		# Curtains with tiebacks.
		var red := Color("7b2d3a")
		for side in [-1, 1]:
			var x0 := w.position.x - 30.0 if side < 0 else w.end.x + 30.0
			var x1 := w.position.x + 46.0 if side < 0 else w.end.x - 46.0
			var curtain := PackedVector2Array([Vector2(x0, w.position.y - 40), Vector2(x1, w.position.y - 40), Vector2(x1 - side * 8, w.position.y + 120), Vector2(x0 + side * 34, w.position.y + 230), Vector2(x0 + side * 10, w.end.y + 20), Vector2(x0, w.end.y + 30)])
			ShapeDrawer.fill_polygon(self, curtain, red)
			for k in range(3):
				var fx := lerpf(x0, x1, 0.25 + k * 0.25)
				draw_line(Vector2(fx, w.position.y - 30), Vector2(lerpf(fx, x0 + side * 24, 0.7), w.position.y + 220), red.darkened(0.25), 3.0, true)
			draw_line(Vector2(x0, w.position.y + 228), Vector2(x0 + side * 44, w.position.y + 222), Color("c9a24a"), 6.0, true)
		# Pelmet.
		var pel := Rect2(w.position.x - 44, w.position.y - 58, w.size.x + 88, 34)
		draw_rect(pel, Color("6a2531"))
		for k in range(8):
			var sx := pel.position.x + k * pel.size.x / 8.0
			draw_arc(Vector2(sx + pel.size.x / 16.0, pel.end.y), pel.size.x / 16.0, 0, PI, 8, Color("c9a24a"), 3.0)

	func _frame(r: Rect2, art: Color) -> void:
		draw_rect(r.grow(8), Color("b08d57"))
		draw_rect(r, Color("f4ead8"))
		var c := r.get_center()
		draw_circle(c + Vector2(0, -r.size.y * 0.28), r.size.x * 0.1, Color("e8c4a8"))
		ShapeDrawer.fill_polygon(self, PackedVector2Array([c + Vector2(-r.size.x * 0.12, -r.size.y * 0.18), c + Vector2(r.size.x * 0.12, -r.size.y * 0.18), c + Vector2(r.size.x * 0.3, r.size.y * 0.38), c + Vector2(-r.size.x * 0.3, r.size.y * 0.38)]), art)
		draw_rect(r.grow(8), Color("7a5a2a"), false, 2.0)


# ============================================================================ floor
class FloorLayer extends Node2D:
	func _draw() -> void:
		var top := Boutique.WALL_BOTTOM
		var bottom := 420.0
		draw_rect(Rect2(-2000, top, 4000, bottom - top), Color("8a5a3a"))
		var vp := Vector2(0, -700)
		var x := -4000.0
		while x <= 4000.0:
			var t := (top - vp.y) / (bottom - vp.y)
			var a := vp.lerp(Vector2(x, bottom), t)
			draw_line(a, Vector2(x, bottom), Color("74482c"), 2.0)
			x += 110.0
		var y := top + 18.0
		var step := 18.0
		while y < bottom:
			draw_line(Vector2(-2000, y), Vector2(2000, y), Color(0.35, 0.2, 0.12, 0.25), 1.0)
			step *= 1.18
			y += step
		# Rug.
		_ellipse(Vector2(0, 26), 360, 74, Color("6a2531"))
		_ellipse(Vector2(0, 26), 330, 64, Color("c9a24a"))
		_ellipse(Vector2(0, 26), 318, 60, Color("2f4d45"))
		for i in range(24):
			var a := TAU * i / 24.0
			draw_circle(Vector2(cos(a) * 280, 26 + sin(a) * 50), 6, Color("c9a24a"))
		# Fitting platform.
		_ellipse(Vector2(0, 14), 205, 34, Color("4a2c1a"))
		draw_rect(Rect2(-205, 0, 410, 14), Color("4a2c1a"))
		_ellipse(Vector2(0, 0), 205, 34, Color("8a5a3a"))
		_ellipse(Vector2(0, 0), 190, 29, Color("9b6a46"))
		var ring := ShapeDrawer.ellipse_points(Vector2.ZERO, 197, 31, 48)
		ring.append(ring[0])
		draw_polyline(ring, Color("c9a24a"), 2.0, true)

	func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
		ShapeDrawer.fill_polygon(self, ShapeDrawer.ellipse_points(c, rx, ry, 40), col)


# ============================================================================ furniture
class Furniture extends Node2D:
	func _draw() -> void:
		_shelves(Rect2(-1320, -760, 560, 720))
		_sewing_table(Vector2(-540, 0))
		_dress_form(Vector2(-290, 0))
		_counter(Rect2(420, -210, 520, 210))
		_hat_boxes(Vector2(1020, 0))

	func _shelves(r: Rect2) -> void:
		var wood := Color("6b4428")
		draw_rect(r, wood.darkened(0.25))
		var rows := 5
		var colors := ["7b2d3a", "2f5d50", "d8c8a8", "1f3a5f", "c08497", "e9c46a", "5a2a6e", "f2e8d5", "8a3b1e", "6a994e", "b5838d", "264653"]
		var ci := 0
		for i in range(rows):
			var y := r.position.y + 20 + i * (r.size.y - 40) / rows
			var h := (r.size.y - 40) / rows - 16
			var x := r.position.x + 20
			while x < r.end.x - 60:
				var col := Color.html(colors[ci % colors.size()])
				ci += 1
				var bw := 44.0
				draw_rect(Rect2(x, y + h - 40, bw, 40), col)
				draw_circle(Vector2(x + bw * 0.5, y + h - 20), 18, col.lightened(0.15))
				draw_circle(Vector2(x + bw * 0.5, y + h - 20), 5, col.darkened(0.4))
				x += bw + 6
			draw_rect(Rect2(r.position.x, y + h, r.size.x, 14), wood)
		draw_rect(r, wood, false, 14.0)
		# Ladder.
		draw_line(Vector2(r.end.x - 120, r.position.y + 40), Vector2(r.end.x - 60, r.end.y + 40), Color("8a5a3a"), 8.0)
		draw_line(Vector2(r.end.x - 60, r.position.y + 40), Vector2(r.end.x, r.end.y + 40), Color("8a5a3a"), 8.0)
		for k in range(9):
			var t := (k + 1) / 10.0
			draw_line(Vector2(r.end.x - 120, r.position.y + 40).lerp(Vector2(r.end.x - 60, r.end.y + 40), t), Vector2(r.end.x - 60, r.position.y + 40).lerp(Vector2(r.end.x, r.end.y + 40), t), Color("8a5a3a"), 5.0)

	func _sewing_table(base: Vector2) -> void:
		var wood := Color("5a3a22")
		var top_y := base.y - 190.0
		draw_rect(Rect2(base.x - 150, top_y, 300, 18), Color("7a4e32"))
		for lx in [-130.0, 130.0]:
			draw_rect(Rect2(base.x + lx - 6, top_y + 18, 12, 172), wood)
		# Cast-iron treadle.
		draw_arc(Vector2(base.x, base.y - 60), 50, 0, TAU, 24, Color("1f1f1f"), 5.0)
		draw_line(Vector2(base.x - 130, base.y - 20), Vector2(base.x + 130, base.y - 20), Color("1f1f1f"), 6.0)
		# Sewing machine.
		var m := Vector2(base.x - 20, top_y)
		var body := PackedVector2Array([m + Vector2(-80, 0), m + Vector2(60, 0), m + Vector2(60, -20), m + Vector2(30, -26), m + Vector2(30, -80), m + Vector2(-70, -80), m + Vector2(-80, -60), m + Vector2(-60, -60), m + Vector2(-60, -26), m + Vector2(-80, -20)])
		ShapeDrawer.fill_polygon(self, body, Color("15151a"))
		draw_line(m + Vector2(-60, -70), m + Vector2(20, -70), Color("c9a24a"), 2.0)
		draw_circle(m + Vector2(40, -55), 16, Color("2a2a30"))
		draw_arc(m + Vector2(40, -55), 16, 0, TAU, 16, Color("c9a24a"), 2.0)
		# Spools, pin cushion, scissors.
		for i in range(3):
			var sp := Vector2(base.x + 70 + i * 22, top_y - 18)
			draw_rect(Rect2(sp.x - 7, sp.y, 14, 18), [Color("c44d58"), Color("2f5d50"), Color("e9c46a")][i])
			draw_rect(Rect2(sp.x - 9, sp.y - 3, 18, 4), Color("b08d57"))
			draw_rect(Rect2(sp.x - 9, sp.y + 17, 18, 4), Color("b08d57"))
		draw_circle(Vector2(base.x + 120, top_y - 12), 12, Color("c44d58"))
		draw_line(Vector2(base.x - 140, top_y + 2), Vector2(base.x - 60, top_y + 60), Color("f2e3a0"), 4.0)

	func _dress_form(base: Vector2) -> void:
		var linen := Color("e6d8bd")
		draw_line(base + Vector2(0, -10), base + Vector2(0, -230), Color("3b2416"), 6.0)
		for s in [-1, 1]:
			draw_line(base + Vector2(0, -12), base + Vector2(s * 50, 0), Color("3b2416"), 5.0)
		var torso := PackedVector2Array([base + Vector2(-46, -440), base + Vector2(46, -440), base + Vector2(40, -380), base + Vector2(28, -330), base + Vector2(44, -260), base + Vector2(-44, -260), base + Vector2(-28, -330), base + Vector2(-40, -380)])
		ShapeDrawer.fill_polygon(self, torso, linen)
		torso.append(torso[0])
		draw_polyline(torso, Color("8a7a5a"), 2.0, true)
		draw_rect(Rect2(base.x - 8, base.y - 470, 16, 30), Color("3b2416"))
		draw_circle(base + Vector2(0, -470), 9, Color("c9a24a"))
		# A draped length of fabric with pins.
		var drape := PackedVector2Array([base + Vector2(-46, -436), base + Vector2(10, -440), base + Vector2(-10, -300), base + Vector2(-60, -210), base + Vector2(-70, -230)])
		ShapeDrawer.fill_polygon(self, drape, Color("2f5d50"))
		for k in range(3):
			draw_circle(base + Vector2(-30 + k * 12, -420 + k * 40), 2.5, Color("d9b25c"))
		# Tape measure.
		draw_polyline(PackedVector2Array([base + Vector2(-46, -440), base + Vector2(-20, -400), base + Vector2(0, -360), base + Vector2(30, -400), base + Vector2(46, -440)]), Color("f2e3a0"), 3.0, true)

	func _counter(r: Rect2) -> void:
		var wood := Color("6b4428")
		draw_rect(r, wood)
		draw_rect(Rect2(r.position.x - 14, r.position.y - 14, r.size.x + 28, 18), Color("8a5a3a"))
		var x := r.position.x + 20
		while x < r.end.x - 60:
			draw_rect(Rect2(x, r.position.y + 30, 100, r.size.y - 60), wood.lightened(0.07))
			draw_rect(Rect2(x, r.position.y + 30, 100, r.size.y - 60), wood.darkened(0.3), false, 3.0)
			x += 125
		# Cash register.
		var c := Vector2(r.end.x - 110, r.position.y - 14)
		draw_rect(Rect2(c.x - 50, c.y - 70, 100, 70), Color("b08d57"))
		draw_rect(Rect2(c.x - 40, c.y - 100, 80, 32), Color("c9a24a"))
		for i in range(4):
			for j in range(2):
				draw_circle(Vector2(c.x - 30 + i * 20, c.y - 50 + j * 20), 5, Color("f2ead8"))
		# Ribbons and a vase of flowers.
		var v := Vector2(r.position.x + 260, r.position.y - 14)
		ShapeDrawer.fill_polygon(self, PackedVector2Array([v + Vector2(-16, 0), v + Vector2(16, 0), v + Vector2(20, -40), v + Vector2(-20, -40)]), Color("2f5d50"))
		for k in range(5):
			var f := v + Vector2(-24 + k * 12, -60 - (k % 2) * 14)
			draw_line(v + Vector2(0, -40), f, Color("4b5d3a"), 2.0)
			draw_circle(f, 8, [Color("e07a8f"), Color("f6e7cb"), Color("c25b7a")][k % 3])

	func _hat_boxes(base: Vector2) -> void:
		var cols := [Color("c08497"), Color("a8b59a"), Color("e9c46a")]
		var y := base.y
		for i in range(3):
			var w := 150.0 - i * 26
			var h := 70.0
			draw_rect(Rect2(base.x - w / 2, y - h, w, h), cols[i])
			draw_rect(Rect2(base.x - w / 2 - 6, y - h - 10, w + 12, 14), cols[i].darkened(0.2))
			draw_line(Vector2(base.x, y - h - 10), Vector2(base.x, y), Color("f6f1e9"), 4.0)
			y -= h + 10


# ============================================================================ radio
class Radio extends Node2D:
	## A cathedral-style wooden wireless set on the counter. Click to choose music.
	signal clicked
	var hovered := false
	var playing := false
	var _t := 0.0
	const RECT := Rect2(-62, -150, 124, 150)

	func _process(delta: float) -> void:
		_t += delta
		var m := get_local_mouse_position()
		var h := RECT.has_point(m)
		if h != hovered:
			hovered = h
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if h else Input.CURSOR_ARROW)
		queue_redraw()

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if RECT.has_point(get_local_mouse_position()):
				clicked.emit()
				get_viewport().set_input_as_handled()

	func _draw() -> void:
		if hovered:
			for i in range(4):
				draw_circle(Vector2(0, -75), 110.0 - i * 15.0, Color(1, 0.9, 0.5, 0.06))
		var wood := Color("7a4e32")
		var outline := Color("3b2416")
		var arch := PackedVector2Array([Vector2(-60, 0), Vector2(60, 0), Vector2(60, -90)])
		for i in range(11):
			var a := lerpf(0.0, PI, i / 10.0)
			arch.append(Vector2(cos(a) * 60, -90 - sin(a) * 58))
		arch.append(Vector2(-60, -90))
		ShapeDrawer.fill_polygon(self, arch, wood)
		arch.append(arch[0])
		draw_polyline(arch, outline, 3.0, true)
		# Speaker cloth with fretwork.
		var cloth := PackedVector2Array([Vector2(-38, -60), Vector2(38, -60), Vector2(38, -100)])
		for i in range(9):
			var a := lerpf(0.0, PI, i / 8.0)
			cloth.append(Vector2(cos(a) * 38, -100 - sin(a) * 36))
		cloth.append(Vector2(-38, -100))
		ShapeDrawer.fill_polygon(self, cloth, Color("c9a982"))
		for k in range(5):
			var x := -28 + k * 14
			draw_line(Vector2(x, -64), Vector2(x, -118 + absf(x) * 0.6), wood.darkened(0.2), 4.0)
		# Dial and knobs.
		draw_rect(Rect2(-30, -48, 60, 18), Color("f3e3b0"))
		draw_rect(Rect2(-30, -48, 60, 18), outline, false, 2.0)
		var needle := -24.0 + fmod(_t * 3.0, 48.0) if playing else 0.0
		draw_line(Vector2(needle, -47), Vector2(needle, -31), Color("8b1e2b"), 2.0)
		for kx in [-38.0, 38.0]:
			draw_circle(Vector2(kx, -18), 9, Color("3b2416"))
			draw_circle(Vector2(kx, -18), 5, Color("c9a24a"))
		# Floating notes while music plays.
		if playing:
			var font := ThemeDB.fallback_font
			for i in range(3):
				var ph := fmod(_t * 0.5 + i / 3.0, 1.0)
				var p := Vector2(30 + sin((ph + i) * 6.0) * 14, -150 - ph * 90)
				draw_string(font, p, "♪" if i % 2 == 0 else "♫", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.48, 0.18, 0.23, 1.0 - ph))
		if hovered:
			var font2 := ThemeDB.fallback_font
			draw_string(font2, Vector2(-70, 26), "Click to choose music", HORIZONTAL_ALIGNMENT_CENTER, 140, 15, Color("fff3d6"))


# ============================================================================ mirror
class Mirror extends Node2D:
	## A cheval mirror whose glass shows a reflection of the outfit.
	var reflection: CharacterPresentation
	var _glass: Polygon2D

	func _ready() -> void:
		_glass = Polygon2D.new()
		_glass.color = Color("b9c7cc")
		var pts := PackedVector2Array([Vector2(-62, -40), Vector2(62, -40), Vector2(62, -480)])
		for i in range(13):
			var a := lerpf(0.0, PI, i / 12.0)
			pts.append(Vector2(cos(a) * 62, -480 - sin(a) * 70))
		pts.append(Vector2(-62, -480))
		_glass.polygon = pts
		_glass.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		add_child(_glass)
		reflection = CharacterPresentation.new()
		reflection.interactive = false
		reflection.idle_enabled = false
		reflection.position = Vector2(-6, -40)
		reflection.scale = Vector2(-0.78, 0.78)
		reflection.modulate = Color(0.86, 0.9, 0.95)
		_glass.add_child(reflection)
		var sheen := Polygon2D.new()
		sheen.color = Color(1, 1, 1, 0.13)
		sheen.polygon = PackedVector2Array([Vector2(-40, -540), Vector2(-10, -540), Vector2(-60, -300), Vector2(-62, -360)])
		_glass.add_child(sheen)

	func _draw() -> void:
		var frame := Color("6b4428")
		# Stand.
		draw_line(Vector2(-78, -260), Vector2(-92, 10), frame, 10.0)
		draw_line(Vector2(78, -260), Vector2(92, 10), frame, 10.0)
		draw_line(Vector2(-110, 10), Vector2(-70, 10), frame, 10.0)
		draw_line(Vector2(70, 10), Vector2(110, 10), frame, 10.0)
		var pts := PackedVector2Array([Vector2(-74, -28), Vector2(74, -28), Vector2(74, -480)])
		for i in range(13):
			var a := lerpf(0.0, PI, i / 12.0)
			pts.append(Vector2(cos(a) * 74, -480 - sin(a) * 82))
		pts.append(Vector2(-74, -480))
		ShapeDrawer.fill_polygon(self, pts, frame)
		pts.append(pts[0])
		draw_polyline(pts, Color("c9a24a"), 3.0, true)
		draw_circle(Vector2(0, -566), 10, Color("c9a24a"))
