class_name DesignPersistence
extends RefCounted
## Saves designs as versioned JSON (plus an optional PNG thumbnail) under user://designs/.
## Designs are reconstructed entirely from the JSON data.

const DESIGN_DIR := "user://designs"


static func _ensure_dir(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)


static func slugify(design_name: String) -> String:
	var s := design_name.strip_edges().to_lower()
	var out := ""
	for ch in s:
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			out += ch
		elif out.length() > 0 and not out.ends_with("_"):
			out += "_"
	out = out.trim_suffix("_")
	return out if out != "" else "design"


static func path_for(design_name: String, dir: String = DESIGN_DIR) -> String:
	return dir.path_join(slugify(design_name) + ".json")


static func exists(design_name: String, dir: String = DESIGN_DIR) -> bool:
	return FileAccess.file_exists(path_for(design_name, dir))


static func save_design(design: DressDesign, design_name: String, thumbnail: Image = null, dir: String = DESIGN_DIR) -> Error:
	_ensure_dir(dir)
	var path := path_for(design_name, dir)
	var data := design.to_save_data(design_name)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	var thumb_path := path.get_basename() + ".png"
	if thumbnail != null and not thumbnail.is_empty():
		thumbnail.save_png(thumb_path)
	return OK


static func load_data(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


static func load_design(path: String) -> DressDesign:
	return DressDesign.from_save_data(load_data(path))


## Lists saved designs, newest first: [{name, path, saved_at, thumbnail}]
static func list_designs(dir: String = DESIGN_DIR) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var da := DirAccess.open(dir)
	if da == null:
		return out
	for f in da.get_files():
		if not f.ends_with(".json"):
			continue
		var path := dir.path_join(f)
		var data := load_data(path)
		if data.get("format", "") != DressDesign.FORMAT_ID:
			continue
		var thumb := path.get_basename() + ".png"
		out.append({
			"name": str(data.get("name", f.get_basename())),
			"path": path,
			"saved_at": str(data.get("saved_at", "")),
			"thumbnail": thumb if FileAccess.file_exists(thumb) else "",
		})
	out.sort_custom(func(a, b): return a["saved_at"] > b["saved_at"])
	return out


static func delete_design(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var thumb := path.get_basename() + ".png"
	if FileAccess.file_exists(thumb):
		DirAccess.remove_absolute(thumb)
