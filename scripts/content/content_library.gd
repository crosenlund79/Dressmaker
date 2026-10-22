class_name ContentLibrary
extends Node
## Read-only catalog of all game content, loaded from resource folders.
## Registered as the `Content` autoload. Drop a new .tres into one of the
## folders below and it appears in the game automatically.

const BODY_DIR := "res://resources/bodies"
const GARMENT_DIR := "res://resources/garments"
const FABRIC_DIR := "res://resources/fabrics"
const SHOE_DIR := "res://resources/shoes"
const HAIR_DIR := "res://resources/hairstyles"
const JEWELRY_DIR := "res://resources/jewelry"
const PLAYLIST_PATH := "res://resources/music/playlist.tres"

var bodies: Array[BodyDefinition] = []
var garments: Array[GarmentDefinition] = []
var fabrics: Array[FabricDefinition] = []
var shoes: Array[ShoeDefinition] = []
var hairstyles: Array[HairDefinition] = []
var jewelry: Array[JewelryDefinition] = []
var playlist: MusicPlaylist

var _by_id: Dictionary = {}
var _loaded := false


func _ready() -> void:
	load_all()


func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	for r in _load_dir(BODY_DIR):
		if r is BodyDefinition:
			bodies.append(r)
	for r in _load_dir(GARMENT_DIR):
		if r is GarmentDefinition:
			garments.append(r)
	for r in _load_dir(FABRIC_DIR):
		if r is FabricDefinition:
			fabrics.append(r)
	for r in _load_dir(SHOE_DIR):
		if r is ShoeDefinition:
			shoes.append(r)
	for r in _load_dir(HAIR_DIR):
		if r is HairDefinition:
			hairstyles.append(r)
	for r in _load_dir(JEWELRY_DIR):
		if r is JewelryDefinition:
			jewelry.append(r)
	_index("body", bodies)
	_index("garment", garments)
	_index("fabric", fabrics)
	_index("shoe", shoes)
	_index("hair", hairstyles)
	_index("jewelry", jewelry)
	if ResourceLoader.exists(PLAYLIST_PATH):
		playlist = load(PLAYLIST_PATH)
	if playlist == null:
		playlist = MusicPlaylist.new()


func garments_in(category: String) -> Array[GarmentDefinition]:
	var out: Array[GarmentDefinition] = []
	for g in garments:
		if g.category == category:
			out.append(g)
	return out


func jewelry_in(category: String) -> Array[JewelryDefinition]:
	var out: Array[JewelryDefinition] = []
	for j in jewelry:
		if j.category == category:
			out.append(j)
	return out


func get_body(id: String) -> BodyDefinition:
	var b: BodyDefinition = _by_id.get("body:" + id)
	if b == null and not bodies.is_empty():
		return bodies[0]
	return b


func get_garment(id: String) -> GarmentDefinition:
	return _by_id.get("garment:" + id)


func get_fabric(id: String) -> FabricDefinition:
	var f: FabricDefinition = _by_id.get("fabric:" + id)
	if f == null and not fabrics.is_empty():
		return fabrics[0]
	return f


func get_shoe(id: String) -> ShoeDefinition:
	return _by_id.get("shoe:" + id)


func get_hair(id: String) -> HairDefinition:
	return _by_id.get("hair:" + id)


func get_jewelry(id: String) -> JewelryDefinition:
	return _by_id.get("jewelry:" + id)


func _index(kind: String, items: Array) -> void:
	for item in items:
		_by_id[kind + ":" + item.id] = item


## Loads every resource in a folder, sorted by file name. Handles exported
## builds, where resources are listed with a ".remap" suffix.
static func _load_dir(dir_path: String) -> Array[Resource]:
	var out: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("Content folder missing: " + dir_path)
		return out
	var files: Array[String] = []
	for f in dir.get_files():
		var name := f.trim_suffix(".remap")
		if name.ends_with(".tres") or name.ends_with(".res"):
			if not files.has(name):
				files.append(name)
	files.sort()
	for f in files:
		var res := load(dir_path.path_join(f))
		if res:
			out.append(res)
		else:
			push_warning("Failed to load content: " + f)
	return out
