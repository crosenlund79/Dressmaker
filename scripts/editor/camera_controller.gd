class_name CameraController
extends Camera2D
## Zoom (mouse wheel, toward the cursor) and pan (right/middle drag) for the fitting area.
## `ui_insets` (left, top, right, bottom in screen pixels) keeps framing centered in the
## part of the screen not covered by panels.

signal zoom_changed(zoom_level: float)

const MIN_ZOOM := 0.45
const MAX_ZOOM := 3.5

var world_bounds := Rect2(-1500, -900, 3000, 1150)
var ui_insets := Vector4(0, 0, 0, 0)
var _panning := false
var _tween: Tween


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_at(zoom.x * 1.12, event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_at(zoom.x / 1.12, event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_panning = event.pressed
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _panning:
		position -= event.relative / zoom.x
		_clamp()
		get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		zoom_at(zoom.x * event.factor, event.position)
	elif event is InputEventPanGesture:
		position += event.delta * 8.0 / zoom.x
		_clamp()


func zoom_at(new_zoom: float, screen_point: Vector2) -> void:
	_kill_tween()
	new_zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	var before := _screen_to_world(screen_point)
	zoom = Vector2(new_zoom, new_zoom)
	var after := _screen_to_world(screen_point)
	position += before - after
	_clamp()
	zoom_changed.emit(new_zoom)


func set_zoom_level(new_zoom: float) -> void:
	zoom_at(new_zoom, _free_center())


func _screen_to_world(p: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * p


func _free_center() -> Vector2:
	var vp := get_viewport_rect().size
	return Vector2((ui_insets.x + vp.x - ui_insets.z) * 0.5, (ui_insets.y + vp.y - ui_insets.w) * 0.5)


## Frames a world-space rectangle inside the free (non-panel) area.
func focus_rect(rect: Rect2, animate: bool = true, padding: float = 1.25) -> void:
	var vp := get_viewport_rect().size
	var free := Vector2(vp.x - ui_insets.x - ui_insets.z, vp.y - ui_insets.y - ui_insets.w)
	var z := clampf(minf(free.x / (rect.size.x * padding), free.y / (rect.size.y * padding)), MIN_ZOOM, MAX_ZOOM)
	var shift := _free_center() - vp * 0.5
	var target_pos := rect.get_center() - shift / z
	_kill_tween()
	if animate:
		_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(self, "zoom", Vector2(z, z), 0.35)
		_tween.parallel().tween_property(self, "position", target_pos, 0.35)
		_tween.finished.connect(func(): zoom_changed.emit(zoom.x))
	else:
		zoom = Vector2(z, z)
		position = target_pos
		zoom_changed.emit(z)


## Pans just enough to bring a world rect into the free area (keeps the selection visible).
func ensure_visible(rect: Rect2) -> void:
	var inv := get_canvas_transform().affine_inverse()
	var vp := get_viewport_rect().size
	var tl: Vector2 = inv * Vector2(ui_insets.x, ui_insets.y)
	var br: Vector2 = inv * Vector2(vp.x - ui_insets.z, vp.y - ui_insets.w)
	var view := Rect2(tl, br - tl)
	if view.encloses(rect):
		return
	if rect.size.x > view.size.x or rect.size.y > view.size.y:
		focus_rect(rect)
		return
	var delta := Vector2.ZERO
	if rect.position.x < view.position.x:
		delta.x = rect.position.x - view.position.x
	elif rect.end.x > view.end.x:
		delta.x = rect.end.x - view.end.x
	if rect.position.y < view.position.y:
		delta.y = rect.position.y - view.position.y
	elif rect.end.y > view.end.y:
		delta.y = rect.end.y - view.end.y
	_kill_tween()
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position", position + delta, 0.3)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _clamp() -> void:
	position = position.clamp(world_bounds.position, world_bounds.end)
