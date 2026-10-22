class_name FashionEditor
extends Node
## Coordinates editing: owns the current design, the selection, the edit mode and
## the undo/redo history. Every change goes through change(), which records a
## before/after snapshot in Godot's UndoRedo. Continuous edits (handle drags,
## slider drags, color picking) are merged into a single undo step.

signal design_changed
signal selection_changed(slot: String)
signal mode_changed(mode: String)
signal history_changed
signal design_replaced  # new / loaded design (UI should fully rebuild)

const MERGE_WINDOW_MS := 700

var design: DressDesign
var design_name: String = ""
var selected_slot: String = "bodice"
var edit_mode: String = "basic"  # "basic" | "advanced"
var symmetric_cage: bool = true
var undo_redo := UndoRedo.new()
var dirty: bool = false

var _interaction_label: String = ""
var _interaction_serial: int = 0
var _last_label: String = ""
var _last_time: int = -100000
var _merge_serial: int = 0


func _init() -> void:
	undo_redo.max_steps = 200


func _ready() -> void:
	if design == null:
		design = DesignFactory.default_design()


func _exit_tree() -> void:
	undo_redo.free()


# ------------------------------------------------------------------ changes / history
## Applies `fn` to the design and records it as an undoable step.
func change(label: String, fn: Callable) -> void:
	var before := design.to_dict()
	fn.call()
	_after_edit()
	var after := design.to_dict()
	if before.hash() == after.hash() and str(before) == str(after):
		return
	var action_name := _action_name(label)
	undo_redo.create_action(action_name, UndoRedo.MERGE_ENDS)
	undo_redo.add_do_method(_apply_snapshot.bind(after))
	undo_redo.add_undo_method(_apply_snapshot.bind(before))
	undo_redo.commit_action(false)
	dirty = true
	design_changed.emit()
	history_changed.emit()


## Groups all changes until end_interaction() into one undo step (e.g. a mouse drag).
func begin_interaction(label: String) -> void:
	_interaction_serial += 1
	_interaction_label = "%s~%d" % [label, _interaction_serial]


func end_interaction() -> void:
	_interaction_label = ""
	_last_label = ""


func _action_name(label: String) -> String:
	if _interaction_label != "":
		return _interaction_label
	var now := Time.get_ticks_msec()
	if label != _last_label or now - _last_time > MERGE_WINDOW_MS:
		_merge_serial += 1
	_last_label = label
	_last_time = now
	return "%s#%d" % [label, _merge_serial]


func _after_edit() -> void:
	if DressDesign.is_sleeve_slot(selected_slot):
		design.sync_sleeves(selected_slot)


func _apply_snapshot(snapshot: Dictionary) -> void:
	design.from_dict(snapshot)
	dirty = true
	design_changed.emit()


func undo() -> void:
	end_interaction()
	_last_label = ""
	if undo_redo.undo():
		history_changed.emit()


func redo() -> void:
	end_interaction()
	_last_label = ""
	if undo_redo.redo():
		history_changed.emit()


func can_undo() -> bool:
	return undo_redo.has_undo()


func can_redo() -> bool:
	return undo_redo.has_redo()


# ------------------------------------------------------------------ selection / mode
func select(slot: String) -> void:
	if slot == selected_slot:
		return
	selected_slot = slot
	end_interaction()
	selection_changed.emit(slot)


func set_mode(mode: String) -> void:
	if mode == edit_mode:
		return
	edit_mode = mode
	mode_changed.emit(mode)


func selected_garment() -> GarmentInstance:
	if DressDesign.is_garment_slot(selected_slot):
		return design.garment(selected_slot)
	return null


## The garment slot that fabric/color edits apply to (last selected garment).
func garment_slot_or_default() -> String:
	return selected_slot if DressDesign.is_garment_slot(selected_slot) else "bodice"


# ------------------------------------------------------------------ whole designs
func new_design() -> void:
	change("New design", func():
		design.from_dict(DesignFactory.default_design().to_dict()))
	design_name = ""
	dirty = false
	design_replaced.emit()


func load_design(loaded: DressDesign, loaded_name: String) -> void:
	change("Load design", func(): design.from_dict(loaded.to_dict()))
	design_name = loaded_name
	dirty = false
	design_replaced.emit()


func clear_history() -> void:
	undo_redo.clear_history()
	history_changed.emit()
