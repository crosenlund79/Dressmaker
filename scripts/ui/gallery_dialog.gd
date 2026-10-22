class_name GalleryDialog
extends PopupPanel
## Saved designs: thumbnail, name, date, and load / delete actions.

signal load_requested(path: String)

var _grid: GridContainer
var _confirm: ConfirmationDialog
var _pending_delete: String = ""
var _empty: Label


func _ready() -> void:
	min_size = Vector2i(1040, 700)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var h := UiTheme.header("Design Gallery")
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(h)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(hide)
	top.add_child(close)
	_empty = UiTheme.note("No saved designs yet. Use \"Save\" to keep your creations here.")
	_empty.custom_minimum_size.x = 900
	v.add_child(_empty)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(1000, 600)
	v.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_grid)
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Delete design"
	_confirm.ok_button_text = "Delete"
	_confirm.confirmed.connect(func():
		DesignPersistence.delete_design(_pending_delete)
		refresh())
	add_child(_confirm)


func refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var designs := DesignPersistence.list_designs()
	_empty.visible = designs.is_empty()
	for entry in designs:
		_grid.add_child(_card(entry))


func _card(entry: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.CREAM, UiTheme.GOLD, 1, 8, 8))
	var v := VBoxContainer.new()
	panel.add_child(v)
	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(170, 230)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if entry["thumbnail"] != "":
		var img := Image.load_from_file(ProjectSettings.globalize_path(entry["thumbnail"]))
		if img:
			tex.texture = ImageTexture.create_from_image(img)
	v.add_child(tex)
	var name_l := Label.new()
	name_l.text = entry["name"]
	name_l.add_theme_font_override("font", UiTheme.font("bold"))
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.custom_minimum_size.x = 170
	v.add_child(name_l)
	var date := UiTheme.note(str(entry["saved_at"]).replace("T", " "))
	date.custom_minimum_size.x = 170
	v.add_child(date)
	var row := HBoxContainer.new()
	v.add_child(row)
	var load_b := Button.new()
	load_b.text = "Load"
	load_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_b.pressed.connect(func():
		load_requested.emit(entry["path"])
		hide())
	row.add_child(load_b)
	var del := Button.new()
	del.text = "Delete"
	del.pressed.connect(func():
		_pending_delete = entry["path"]
		_confirm.dialog_text = "Delete \"%s\"? This cannot be undone." % entry["name"]
		_confirm.popup_centered())
	row.add_child(del)
	return panel
