extends SceneTree
## Regenerates the content resources in res://resources/ from the authoring catalogs.
##   godot --headless --path . -s tools/build_content.gd
## The generated .tres files are the game's source of truth at runtime; they can also be
## edited or duplicated directly in the Godot editor.

const Garments = preload("res://tools/content/garment_catalog.gd")
const Bodies = preload("res://tools/content/body_catalog.gd")
const Shoes = preload("res://tools/content/shoe_catalog.gd")
const Hair = preload("res://tools/content/hair_catalog.gd")
const Jewelry = preload("res://tools/content/jewelry_catalog.gd")

const FABRICS := [
	["cotton", "Plain Cotton", 80.0, "c44d58", "f2e8d5"],
	["silk", "Smooth Silk", 260.0, "b5838d", "ffffff"],
	["velvet", "Crushed Velvet", 150.0, "7b2d3a", "000000"],
	["linen", "Linen", 90.0, "d8c8a8", "ffffff"],
	["satin", "Satin", 240.0, "355c7d", "ffffff"],
	["lace", "Lace", 70.0, "f6f1e9", "ffffff"],
	["floral", "Floral Print", 120.0, "f4ecdc", "c25b7a"],
	["stripes", "Regency Stripes", 110.0, "f2e8d5", "6a8caf"],
	["check", "Gingham Check", 90.0, "ffffff", "c44d58"],
	["brocade", "Brocade", 160.0, "2f5d50", "d8c27a"],
	["polka", "Polka Dots", 100.0, "1d3557", "f1faee"],
	["geometric", "Argyle Geometric", 120.0, "e9c46a", "264653"],
	["tartan", "Tartan", 140.0, "1f4e3d", "a4161a"],
	["houndstooth", "Houndstooth", 70.0, "f2efe6", "1a1a1a"],
]


const TRACKS := [
	["parlour_waltz", "Parlour Waltz in F", "A light-footed piano waltz for the afternoon."],
	["tea_at_half_past_four", "Tea at Half Past Four", "A gentle string quartet with a flute reprise."],
	["lace_and_lavender", "Lace & Lavender", "A music-box lullaby over harp arpeggios."],
	["promenade_on_regent_street", "Promenade on Regent Street", "A courtly minuet for piano and strings."],
	["gaslight_nocturne", "Gaslight Nocturne", "A slow, dreamy piano nocturne."],
]


func _init() -> void:
	var counts := {}
	counts["bodies"] = _save_all(Bodies.build(), "res://resources/bodies", "%02d_%s")
	counts["garments"] = _save_all(Garments.build(), "res://resources/garments", "%02d_%s")
	counts["shoes"] = _save_all(Shoes.build(), "res://resources/shoes", "%02d_%s")
	counts["hair"] = _save_all(Hair.build(), "res://resources/hairstyles", "%02d_%s")
	counts["jewelry"] = _save_all(Jewelry.build(), "res://resources/jewelry", "%02d_%s")
	counts["fabrics"] = _save_all(_fabrics(), "res://resources/fabrics", "%02d_%s")
	counts["tracks"] = _build_playlist()
	print("Content built: ", counts)
	quit()


func _fabrics() -> Array[FabricDefinition]:
	var out: Array[FabricDefinition] = []
	for f in FABRICS:
		var d := FabricDefinition.new()
		d.id = f[0]
		d.display_name = f[1]
		d.tile_size = f[2]
		d.default_color = Color.html(f[3])
		d.default_secondary = Color.html(f[4])
		d.texture = load("res://assets/fabrics/%s.png" % f[0])
		if d.texture == null:
			push_error("Missing fabric texture for " + f[0] + " (run the editor import first)")
		out.append(d)
	return out


func _save_all(items: Array, dir: String, pattern: String) -> int:
	DirAccess.make_dir_recursive_absolute(dir)
	# Remove stale files so deleted catalog entries disappear.
	var da := DirAccess.open(dir)
	for f in da.get_files():
		if f.ends_with(".tres"):
			da.remove(f)
	var i := 0
	for item in items:
		var file_name: String
		if pattern.begins_with("%02d"):
			file_name = pattern % [i, item.id]
		else:
			file_name = pattern % item.id
		var err := ResourceSaver.save(item, "%s/%s.tres" % [dir, file_name])
		if err != OK:
			push_error("Failed to save %s: %s" % [item.id, err])
		i += 1
	return i


func _build_playlist() -> int:
	var playlist := MusicPlaylist.new()
	var typed: Array[MusicTrack] = []
	for t in TRACKS:
		var path := "res://assets/audio/music/%s.ogg" % t[0]
		if not ResourceLoader.exists(path):
			push_warning("Missing music file " + path)
			continue
		var track := MusicTrack.new()
		track.title = t[1]
		track.description = t[2]
		track.stream = load(path)
		typed.append(track)
	playlist.tracks = typed
	DirAccess.make_dir_recursive_absolute("res://resources/music")
	ResourceSaver.save(playlist, "res://resources/music/playlist.tres")
	return typed.size()
