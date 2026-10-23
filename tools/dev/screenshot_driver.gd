extends Node
## Dev-only automation for visual checks. Activated by user args after "--":
##   godot --path . -- --shot=/path/out.png [--delay=2.0] [--select=skirt] [--mode=advanced]
##        [--zoom=1.5] [--preview] [--radio] [--gallery] [--category=Hair] [--script=demo]

var main: Node
var args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	await get_tree().create_timer(0.6).timeout
	var ui: EditorUI = main.ui
	var editor: FashionEditor = main.editor
	if args.has("script"):
		_run_script(args["script"], editor)
	if args.has("category"):
		ui.library.show_category(args["category"], true)
	if args.has("select"):
		editor.select(args["select"])
	if args.has("mode"):
		editor.set_mode(args["mode"])
	if args.has("zoom"):
		await get_tree().create_timer(0.5).timeout
		ui.focus_selection()
	if args.has("preview"):
		ui.set_preview(true)
	if args.has("radio"):
		ui.open_radio()
	if args.has("save"):
		await ui._do_save(args["save"])
	if args.has("gallery"):
		ui._on_gallery()
	await get_tree().create_timer(float(args.get("delay", "1.5"))).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(args.get("shot", "user://shot.png"))
	print("screenshot saved: ", args.get("shot"))
	get_tree().quit()


func _run_script(script_name: String, editor: FashionEditor) -> void:
	match script_name:
		"demo":
			editor.change("demo", func():
				var d := editor.design
				d.body_id = "hourglass"
				DesignFactory.set_template(d, "bodice", "bodice_military", true)
				DesignFactory.set_template(d, "skirt", "skirt_high_low", true)
				DesignFactory.set_template(d, "sleeve_right", "sleeve_gigot", true)
				d.sync_sleeves("sleeve_right")
				d.garment("skirt").flare = 0.6
				d.garment("skirt").bend = 0.4
				var lat := d.garment("skirt").get_lattice()
				lat[13] = Vector2(0.5, 0.15)
				lat[14] = Vector2(-0.5, 0.15)
				d.garment("skirt").lattice = lat
				d.garment("bodice").material.primary = Color("1f3a5f")
				DesignFactory.set_shoe(d, "shoe_stiletto")
				DesignFactory.set_hair(d, "hair_two_tone_split")
				d.jewelry["tiara"]["id"] = "tiara_crown"
				d.jewelry["bracelet"]["id"] = "bracelet_bangle")
		"wild":
			editor.change("wild", func():
				var d := editor.design
				d.body_id = "full_figure"
				DesignFactory.set_template(d, "bodice", "bodice_cubist", true)
				DesignFactory.set_template(d, "skirt", "skirt_crinoline", true)
				DesignFactory.set_template(d, "sleeve_right", "sleeve_butterfly", true)
				DesignFactory.set_template(d, "sleeve_left", "sleeve_bell", true)
				d.sleeves_linked = false
				d.garment("skirt").scale = Vector2(1.3, 0.9)
				d.garment("skirt").skew = Vector2(0.2, 0)
				d.garment("bodice").rotation = 0.08
				DesignFactory.set_shoe(d, "shoe_platform")
				DesignFactory.set_hair(d, "hair_rainbow_ringlets")
				d.jewelry["necklace"]["id"] = "necklace_gem_collar")
