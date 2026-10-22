extends Node2D
## Dev scene: renders the default design for visual checks (used with xvfb screenshots).

var characters: Array = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.93, 0.88, 0.8))
	var bodies := ["classic", "petite", "full_figure", "tall_slender", "pear"]
	for i in range(bodies.size()):
		var d := DesignFactory.default_design()
		d.body_id = bodies[i]
		var c := CharacterPresentation.new()
		c.position = Vector2(200 + i * 380, 960)
		c.idle_enabled = false
		add_child(c)
		c.set_design(d)
		characters.append(c)
	await get_tree().create_timer(0.5).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("SHOT") if OS.get_environment("SHOT") != "" else "/tmp/preview.png")
	get_tree().quit()
