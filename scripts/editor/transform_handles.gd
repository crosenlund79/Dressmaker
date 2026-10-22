class_name TransformHandles
extends Node2D
## On-model editing overlay. Lives inside the character rig, so local coordinates
## are model space. Basic mode: move / scale / rotate / skew / bend handles.
## Advanced mode: a 4x4 free-form-deformation cage whose points can be dragged.

const HANDLE_PX := 7.0
const TIPS := {
	"move": "Drag to move", "scale_xy": "Scale (Shift: uniform)", "scale_x": "Scale width", "scale_y": "Scale height",
	"rotate": "Rotate (Shift: 15° steps)", "skew_x": "Skew horizontally", "skew_y": "Skew vertically",
	"bend": "Bend / curve the fabric", "cage": "Drag to reshape (curve)",
}

var editor: FashionEditor
var presentation: CharacterPresentation
var enabled: bool = true

var _drag: Dictionary = {}
var _hover: Dictionary = {}


func _shape() -> GarmentShape:
	if presentation == null or editor == null:
		return null
	return presentation.shapes.get(editor.selected_slot)


func _px() -> float:
	var s := get_global_transform_with_canvas().get_scale().x
	return 1.0 / maxf(s, 0.01)


func _process(_delta: float) -> void:
	queue_redraw()


# ------------------------------------------------------------------ handle layout
func _handles() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var shape := _shape()
	if shape == null or not enabled or not shape.instance.visible:
		return out
	if editor.edit_mode == "advanced":
		for iy in range(GarmentDeformer.LATTICE_N):
			for ix in range(GarmentDeformer.LATTICE_N):
				out.append({"id": "cage", "ix": ix, "iy": iy, "pos": shape.cage_point(ix, iy)})
		return out
	var box := shape.pre_affine_box()
	var pv := shape.pivot
	var corners := [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
	for c in corners:
		out.append({"id": "scale_xy", "local": c, "pos": shape.box_point_to_model(c)})
	var mids := {
		"left": Vector2(box.position.x, box.get_center().y), "right": Vector2(box.end.x, box.get_center().y),
		"top": Vector2(box.get_center().x, box.position.y), "bottom": Vector2(box.get_center().x, box.end.y),
	}
	for k in ["left", "right"]:
		if absf(mids[k].x - pv.x) > 4.0:
			out.append({"id": "scale_x", "local": mids[k], "pos": shape.box_point_to_model(mids[k])})
	for k in ["top", "bottom"]:
		if absf(mids[k].y - pv.y) > 4.0:
			out.append({"id": "scale_y", "local": mids[k], "pos": shape.box_point_to_model(mids[k])})
	var far_y := box.position.y if absf(box.position.y - pv.y) >= absf(box.end.y - pv.y) else box.end.y
	var far_x := box.end.x if absf(box.end.x - pv.x) >= absf(box.position.x - pv.x) else box.position.x
	var px := _px()
	var far_mid := shape.box_point_to_model(Vector2(box.get_center().x, far_y))
	var outward := (far_mid - shape.box_point_to_model(box.get_center())).normalized()
	if outward == Vector2.ZERO:
		outward = Vector2.UP
	out.append({"id": "rotate", "pos": far_mid + outward * 36.0 * px})
	var fl := shape.box_point_to_model(Vector2(box.position.x, far_y))
	var fr := shape.box_point_to_model(Vector2(box.end.x, far_y))
	out.append({"id": "skew_x", "far": Vector2(box.get_center().x, far_y), "pos": fl.lerp(fr, 0.78) + outward * 16.0 * px})
	out.append({"id": "bend", "pos": fl.lerp(fr, 0.22) + outward * 16.0 * px})
	var side_mid := shape.box_point_to_model(Vector2(far_x, box.get_center().y))
	var side_out := (side_mid - shape.box_point_to_model(box.get_center())).normalized()
	out.append({"id": "skew_y", "far": Vector2(far_x, box.get_center().y), "pos": side_mid + side_out * 18.0 * px})
	return out


func _hit(m: Vector2) -> Dictionary:
	var r := HANDLE_PX * 1.6 * _px()
	var best := {}
	var best_d := INF
	for h in _handles():
		var d: float = (h["pos"] as Vector2).distance_to(m)
		if d < r and d < best_d:
			best = h
			best_d = d
	return best


# ------------------------------------------------------------------ input
func _unhandled_input(event: InputEvent) -> void:
	if not enabled or editor == null or not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_press()
		elif not _drag.is_empty():
			_drag = {}
			editor.end_interaction()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var m := get_local_mouse_position()
		if not _drag.is_empty():
			presentation.note_activity()
			_on_drag(m, event.shift_pressed)
			get_viewport().set_input_as_handled()
		else:
			_hover = _hit(m)
			if _hover.is_empty():
				var shape := _shape()
				if shape and shape.contains_point(m):
					_hover = {"id": "move", "pos": m}
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if not _hover.is_empty() else Input.CURSOR_ARROW)


func _on_press() -> void:
	var m := get_local_mouse_position()
	presentation.note_activity()
	var h := _hit(m)
	if h.is_empty():
		var picked := presentation.pick(m)
		if picked == "":
			return
		if picked != editor.selected_slot:
			editor.select(picked)
		if not DressDesign.is_garment_slot(picked):
			get_viewport().set_input_as_handled()
			return
		h = {"id": "move", "pos": m}
	var shape := _shape()
	if shape == null:
		return
	var inst := shape.instance
	_drag = h.duplicate()
	_drag["m0"] = m
	_drag["start"] = inst.to_dict()
	_drag["offset0"] = inst.offset
	_drag["scale0"] = inst.scale
	_drag["rot0"] = inst.rotation
	_drag["skew0"] = inst.skew
	_drag["bend0"] = inst.bend
	_drag["pivot"] = shape.pivot + inst.offset
	_drag["pivot_local"] = shape.pivot
	_drag["box"] = shape.pre_affine_box()
	_drag["bounds"] = shape.bounds
	_drag["category"] = shape.category
	_drag["side"] = shape.side
	if h["id"] == "cage":
		_drag["cage0"] = h["pos"]
	editor.begin_interaction("Transform" if h["id"] != "cage" else "Curve edit")
	get_viewport().set_input_as_handled()


func _on_drag(m: Vector2, shift: bool) -> void:
	var slot := editor.selected_slot
	var d := _drag
	var m0: Vector2 = d["m0"]
	var pivot: Vector2 = d["pivot"]
	var rot0: float = d["rot0"]
	var skew0: Vector2 = d["skew0"]
	var scale0: Vector2 = d["scale0"]
	var rk := Transform2D(rot0, Vector2.ZERO) * Transform2D(Vector2(1.0, tan(skew0.y)), Vector2(tan(skew0.x), 1.0), Vector2.ZERO)
	var rk_inv := rk.affine_inverse()
	var r_inv := Transform2D(-rot0, Vector2.ZERO)
	match d["id"]:
		"move":
			var off: Vector2 = d["offset0"] + (m - m0)
			editor.change("Move", func(): editor.design.garment(slot).offset = off)
		"scale_xy", "scale_x", "scale_y":
			var q := rk_inv.basis_xform(m - pivot)
			var c: Vector2 = d["local"] - d["pivot_local"]
			var s := scale0
			if d["id"] != "scale_y" and absf(c.x) > 3.0:
				s.x = clampf(q.x / c.x, 0.15, 5.0)
			if d["id"] != "scale_x" and absf(c.y) > 3.0:
				s.y = clampf(q.y / c.y, 0.15, 5.0)
			if shift and d["id"] == "scale_xy":
				var k := (s.x / scale0.x + s.y / scale0.y) * 0.5
				s = scale0 * k
			editor.change("Scale", func(): editor.design.garment(slot).scale = s)
		"rotate":
			var a := rot0 + (m - pivot).angle() - (m0 - pivot).angle()
			if shift:
				a = snappedf(a, deg_to_rad(15.0))
			editor.change("Rotate", func(): editor.design.garment(slot).rotation = wrapf(a, -PI, PI))
		"skew_x", "skew_y":
			var dq := r_inv.basis_xform(m - pivot) - r_inv.basis_xform(m0 - pivot)
			var far: Vector2 = d["far"] - d["pivot_local"]
			var sk := skew0
			if d["id"] == "skew_x" and absf(far.y * scale0.y) > 3.0:
				sk.x = clampf(atan(tan(skew0.x) + dq.x / (far.y * scale0.y)), -1.2, 1.2)
			elif d["id"] == "skew_y" and absf(far.x * scale0.x) > 3.0:
				sk.y = clampf(atan(tan(skew0.y) + dq.y / (far.x * scale0.x)), -1.2, 1.2)
			editor.change("Skew", func(): editor.design.garment(slot).skew = sk)
		"bend":
			var dqb := r_inv.basis_xform(m - m0)
			var box: Rect2 = d["box"]
			var bounds: Rect2 = d["bounds"]
			var unit_px := box.size.x / maxf(bounds.size.x, 0.01)
			var strength: float = GarmentDeformer.BEND_STRENGTH.get(d["category"], 1.0)
			var bend_sign := float(d["side"]) if d["category"] == "sleeve" else 1.0
			var b := clampf(d["bend0"] + dqb.x / maxf(unit_px * strength * scale0.x, 0.01) * bend_sign, -3.0, 3.0)
			editor.change("Bend", func(): editor.design.garment(slot).bend = b)
		"cage":
			var shape := _shape()
			if shape == null:
				return
			var target: Vector2 = d["cage0"] + (m - m0)
			var ix: int = d["ix"]
			var iy: int = d["iy"]
			var off2 := shape.solve_cage_offset(ix, iy, target)
			var mirror := editor.symmetric_cage and shape.category != "sleeve" and ix != GarmentDeformer.LATTICE_N - 1 - ix
			editor.change("Curve edit", func():
				var inst := editor.design.garment(slot)
				var lat := inst.get_lattice()
				lat[iy * GarmentDeformer.LATTICE_N + ix] = off2
				if mirror:
					lat[iy * GarmentDeformer.LATTICE_N + (GarmentDeformer.LATTICE_N - 1 - ix)] = Vector2(-off2.x, off2.y)
				inst.lattice = lat)


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	var shape := _shape()
	if shape == null or not enabled or not shape.instance.visible:
		return
	var px := _px()
	var gold := Color(0.95, 0.78, 0.3)
	var dark := Color(0.25, 0.15, 0.1)
	if editor.edit_mode == "advanced":
		var n := GarmentDeformer.LATTICE_N
		for iy in range(n):
			var row := PackedVector2Array()
			for ix in range(n):
				row.append(shape.cage_point(ix, iy))
			draw_polyline(row, Color(0.85, 0.35, 0.55, 0.8), 1.5 * px, true)
		for ix in range(n):
			var col := PackedVector2Array()
			for iy in range(n):
				col.append(shape.cage_point(ix, iy))
			draw_polyline(col, Color(0.85, 0.35, 0.55, 0.8), 1.5 * px, true)
	else:
		var box := shape.pre_affine_box()
		var pts := PackedVector2Array()
		for c in [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y), box.position]:
			pts.append(shape.box_point_to_model(c))
		draw_dashed_line_poly(pts, gold, px)
		draw_circle(shape.pivot + shape.instance.offset, 3.5 * px, Color(0.3, 0.6, 0.9))
	for h in _handles():
		var p: Vector2 = h["pos"]
		var hovered: bool = not _hover.is_empty() and _hover.get("id") == h["id"] and (_hover.get("pos") as Vector2).distance_to(p) < 0.5
		var r := HANDLE_PX * px * (1.25 if hovered else 1.0)
		match h["id"]:
			"rotate":
				draw_line(p, p - (p - shape.box_point_to_model(shape.pre_affine_box().get_center())).normalized() * 30.0 * px, gold, 1.2 * px)
				draw_circle(p, r, Color(0.45, 0.75, 0.45))
				draw_arc(p, r * 0.55, 0.3, 4.6, 10, Color.WHITE, 1.4 * px)
			"skew_x", "skew_y":
				var dia := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)])
				draw_colored_polygon(dia, Color(0.4, 0.6, 0.95))
				dia.append(dia[0])
				draw_polyline(dia, dark, 1.2 * px)
			"bend":
				draw_circle(p, r, Color(0.95, 0.6, 0.25))
				draw_arc(p + Vector2(0, r * 0.9), r * 0.8, PI * 1.15, PI * 1.85, 8, Color.WHITE, 1.4 * px)
			"cage":
				draw_circle(p, r * 0.85, Color(0.95, 0.5, 0.7))
				draw_arc(p, r * 0.85, 0, TAU, 14, dark, 1.2 * px)
			_:
				draw_rect(Rect2(p - Vector2(r, r) * 0.8, Vector2(r, r) * 1.6), Color(1, 0.98, 0.92))
				draw_rect(Rect2(p - Vector2(r, r) * 0.8, Vector2(r, r) * 1.6), dark, false, 1.2 * px)
	var tip_id: String = _drag.get("id", _hover.get("id", ""))
	if tip_id != "" and TIPS.has(tip_id):
		var font := ThemeDB.fallback_font
		var at: Vector2 = get_local_mouse_position() + Vector2(14, -10) * px
		var fs := 15
		var text: String = TIPS[tip_id]
		var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs) * px
		draw_set_transform(at, 0.0, Vector2(px, px))
		draw_rect(Rect2(Vector2(-4, -fs), size / px + Vector2(8, 6)), Color(0.15, 0.1, 0.08, 0.85))
		draw_string(font, Vector2(0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.95, 0.85))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_dashed_line_poly(pts: PackedVector2Array, color: Color, px: float) -> void:
	for i in range(pts.size() - 1):
		draw_dashed_line(pts[i], pts[i + 1], color, 1.3 * px, 6.0 * px)
