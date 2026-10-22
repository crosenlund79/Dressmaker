class_name ThumbnailRenderer
extends SubViewport
## Off-screen renderer for gallery thumbnails: draws only the model (no UI, no shop).

var _character: CharacterPresentation
var _camera: Camera2D


func _init() -> void:
	size = Vector2i(240, 330)
	transparent_bg = true
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	_character = CharacterPresentation.new()
	_character.interactive = false
	_character.idle_enabled = false
	add_child(_character)
	_camera = Camera2D.new()
	add_child(_camera)


func capture(design: DressDesign) -> Image:
	_character.set_design(design.duplicate_design())
	var b := _character.body
	var top := (b.head_center_y - b.head_radius * 2.2) if b else -680.0
	var height := -top + 30.0
	var z := minf(size.y / height, size.x / 520.0)
	_camera.zoom = Vector2(z, z)
	_camera.position = Vector2(0, top * 0.5 + 10.0)
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var tex := get_texture()
	if tex == null:
		return null
	var img := tex.get_image()
	return img
