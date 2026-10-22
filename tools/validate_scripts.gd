extends Node
## Loads every script and scene in the project to surface parse/compile errors.
##   godot --headless --path . tools/validate_scripts.tscn

var failures := 0


func _ready() -> void:
	_scan("res://")
	print("Validation finished, failures: ", failures)
	get_tree().quit(1 if failures > 0 else 0)


func _scan(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for d in dir.get_directories():
		if d.begins_with("."):
			continue
		_scan(path.path_join(d))
	for f in dir.get_files():
		var full := path.path_join(f)
		if f.ends_with(".gd") or f.ends_with(".tscn") or f.ends_with(".tres"):
			var res = ResourceLoader.load(full)
			if res == null:
				printerr("FAILED: ", full)
				failures += 1
			elif res is GDScript and not res.can_instantiate():
				printerr("FAILED (compile): ", full)
				failures += 1
