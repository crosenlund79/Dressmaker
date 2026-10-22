class_name GarmentRenderer
extends Node2D
## Renders one garment slot: the deformed fabric mesh (tinted pattern shader)
## plus outline, trims and the selection highlight.

const FABRIC_SHADER := preload("res://shaders/fabric.gdshader")

var shape: GarmentShape
var selected: bool = false
var slot: String = ""

var _fabric: FabricLayer
var _trim: TrimLayer
var _material: ShaderMaterial


func _init(slot_name: String = "") -> void:
	slot = slot_name
	name = "Garment_" + slot_name
	_material = ShaderMaterial.new()
	_material.shader = FABRIC_SHADER
	_fabric = FabricLayer.new()
	_fabric.name = "Fabric"
	_fabric.material = _material
	_fabric.owner_renderer = self
	add_child(_fabric)
	_trim = TrimLayer.new()
	_trim.name = "Trim"
	_trim.owner_renderer = self
	add_child(_trim)


func set_shape(new_shape: GarmentShape, fabric: FabricDefinition) -> void:
	shape = new_shape
	visible = shape != null and shape.instance.visible
	if shape:
		var m := shape.instance.material
		_material.set_shader_parameter("pattern", fabric.texture if fabric else null)
		_material.set_shader_parameter("primary", m.primary)
		_material.set_shader_parameter("secondary", m.secondary)
		_material.set_shader_parameter("pattern_scale", m.pattern_scale)
		_material.set_shader_parameter("pattern_rotation", deg_to_rad(m.pattern_rotation))
		_material.set_shader_parameter("opacity", m.opacity)
	_fabric.queue_redraw()
	_trim.queue_redraw()


func set_selected(value: bool) -> void:
	selected = value
	_material.set_shader_parameter("highlight", 1.0 if value else 0.0)
	_trim.queue_redraw()


class FabricLayer extends Node2D:
	var owner_renderer: GarmentRenderer

	func _draw() -> void:
		var s := owner_renderer.shape
		if s == null or s.mesh == null or s.mesh.indices.is_empty():
			return
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), s.mesh.indices, s.points, s.shades, s.uvs)


class TrimLayer extends Node2D:
	var owner_renderer: GarmentRenderer

	func _draw() -> void:
		var s := owner_renderer.shape
		if s == null or s.outline_points.size() < 3:
			return
		var m := s.instance.material
		var closed := s.outline_points.duplicate()
		closed.append(closed[0])
		if owner_renderer.selected:
			draw_polyline(closed, Color(1.0, 0.85, 0.35, 0.35), 7.0, true)
			draw_polyline(closed, Color(1.0, 0.92, 0.6, 0.9), 2.5, true)
		var edge := m.primary.darkened(0.55)
		edge.a = maxf(m.opacity, 0.5)
		draw_polyline(closed, edge, 1.6, true)
		var trim := m.trim
		trim.a = maxf(m.opacity, 0.6)
		for line in s.definition.detail_lines:
			if line.size() >= 2:
				draw_polyline(s.map_polyline(line), trim, 1.8, true)
		for dot in s.definition.detail_dots:
			var p := s.map_point(dot)
			draw_circle(p, 3.0, trim)
			draw_arc(p, 3.0, 0.0, TAU, 12, trim.darkened(0.4), 1.0, true)
