class_name EditorUI
extends CanvasLayer
## Screen layout: top bar (file + history), left library, right properties,
## bottom context tools. Also hosts the save / gallery / radio windows.

const TOP_H := 60.0
const BOTTOM_H := 96.0
const LEFT_W := 392.0
const RIGHT_W := 372.0

var editor: FashionEditor
var camera: CameraController
var presentation: CharacterPresentation
var handles: TransformHandles
var music: MusicPlayer
var thumbnailer: ThumbnailRenderer

var root: Control
var library: LibraryPanel
var properties: PropertiesPanel
var top_bar: PanelContainer
var bottom_bar: PanelContainer
var radio_panel: RadioPanel
var gallery: GalleryDialog
var preview_mode := false

var _undo_btn: Button
var _redo_btn: Button
var _name_label: Label
var _mode_basic: Button
var _mode_adv: Button
var _sym_check: CheckBox
var _hint: Label
var _zoom_label: Label
var _tool_box: HBoxContainer
var _exit_preview: Button
var _toast: Label
var _toast_tween: Tween
var _save_dialog: ConfirmationDialog
var _save_name: LineEdit
var _overwrite: ConfirmationDialog
var _new_confirm: ConfirmationDialog


## Builds the interface. Called by Main once all references are assigned.
func setup() -> void:
	layer = 10
	root = Control.new()
	root.name = "Root"
	root.theme = UiTheme.build()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top_bar()
	_build_side_panels()
	_build_bottom_bar()
	_build_dialogs()
	_toast = Label.new()
	_toast.add_theme_font_override("font", UiTheme.font("italic"))
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.add_theme_color_override("font_color", UiTheme.CREAM)
	_toast.add_theme_stylebox_override("normal", UiTheme.box(Color(0.23, 0.14, 0.09, 0.9), UiTheme.GOLD, 1, 8, 14))
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position = Vector2(-150, TOP_H + 14)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast)
	_exit_preview = Button.new()
	_exit_preview.text = "✎ Back to editing"
	_exit_preview.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_exit_preview.position = Vector2(-240, 16)
	_exit_preview.visible = false
	_exit_preview.pressed.connect(func(): set_preview(false))
	root.add_child(_exit_preview)
	editor.history_changed.connect(_refresh_history)
	editor.design_changed.connect(_refresh_title)
	editor.design_replaced.connect(_refresh_title)
	editor.selection_changed.connect(_on_selection_changed)
	editor.mode_changed.connect(func(_m): _refresh_tools())
	camera.zoom_changed.connect(func(z): _zoom_label.text = "%d%%" % roundi(z * 100.0))
	camera.ui_insets = Vector4(LEFT_W + 12, TOP_H + 8, RIGHT_W + 12, BOTTOM_H + 8)
	_refresh_history()
	_refresh_title()
	_refresh_tools()


# ------------------------------------------------------------------ layout
func _build_top_bar() -> void:
	top_bar = PanelContainer.new()
	top_bar.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.WALNUT, UiTheme.GOLD, 0, 0, 10))
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size.y = TOP_H
	root.add_child(top_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	top_bar.add_child(row)
	var title := Label.new()
	title.text = "❦ Sandrines Dresses"
	title.add_theme_font_override("font", UiTheme.font("bold"))
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("f3dca0"))
	row.add_child(title)
	_name_label = Label.new()
	_name_label.add_theme_font_override("font", UiTheme.font("italic"))
	_name_label.add_theme_color_override("font_color", Color("e8d8bc"))
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_name_label)
	_top_button(row, "New", "Start a new design (Ctrl+N)", _on_new)
	_top_button(row, "Save", "Save this design (Ctrl+S)", _on_save)
	_top_button(row, "Gallery", "Open saved designs", _on_gallery)
	row.add_child(VSeparator.new())
	_undo_btn = _top_button(row, "↶ Undo", "Undo (Ctrl+Z)", func(): editor.undo())
	_redo_btn = _top_button(row, "↷ Redo", "Redo (Ctrl+Y)", func(): editor.redo())
	row.add_child(VSeparator.new())
	_top_button(row, "♫ Radio", "Open the radio (or click the radio in the shop)", open_radio)
	_top_button(row, "Preview", "Admire the outfit without the editing tools (H)", func(): set_preview(true))


func _top_button(parent: Control, text: String, tip: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(88, 40)
	b.pressed.connect(func():
		SoundEffects.play("click", -10.0)
		fn.call())
	parent.add_child(b)
	return b


func _build_side_panels() -> void:
	library = LibraryPanel.new()
	library.editor = editor
	library.anchor_top = 0.0
	library.anchor_bottom = 1.0
	library.offset_left = 8
	library.offset_top = TOP_H + 8
	library.offset_right = LEFT_W
	library.offset_bottom = -BOTTOM_H - 8
	root.add_child(library)
	library.category_changed.connect(func(_c): SoundEffects.play("click", -12.0))
	properties = PropertiesPanel.new()
	properties.editor = editor
	properties.anchor_left = 1.0
	properties.anchor_right = 1.0
	properties.anchor_bottom = 1.0
	properties.offset_left = -RIGHT_W
	properties.offset_top = TOP_H + 8
	properties.offset_right = -8
	properties.offset_bottom = -BOTTOM_H - 8
	root.add_child(properties)


func _build_bottom_bar() -> void:
	bottom_bar = PanelContainer.new()
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.offset_top = -BOTTOM_H
	bottom_bar.offset_left = 8
	bottom_bar.offset_right = -8
	bottom_bar.offset_bottom = -6
	root.add_child(bottom_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bottom_bar.add_child(row)
	_tool_box = HBoxContainer.new()
	_tool_box.add_theme_constant_override("separation", 8)
	row.add_child(_tool_box)
	var mode_label := Label.new()
	mode_label.text = "Editing:"
	mode_label.add_theme_font_override("font", UiTheme.font("bold"))
	_tool_box.add_child(mode_label)
	var group := ButtonGroup.new()
	_mode_basic = Button.new()
	_mode_basic.text = "Basic transform"
	_mode_basic.toggle_mode = true
	_mode_basic.button_group = group
	_mode_basic.tooltip_text = "Move, scale, rotate, skew and bend with handles (Tab)"
	_mode_basic.pressed.connect(func(): editor.set_mode("basic"))
	_tool_box.add_child(_mode_basic)
	_mode_adv = Button.new()
	_mode_adv.text = "Advanced curves"
	_mode_adv.toggle_mode = true
	_mode_adv.button_group = group
	_mode_adv.tooltip_text = "Drag curve control points to reshape the fabric (Tab)"
	_mode_adv.pressed.connect(func(): editor.set_mode("advanced"))
	_tool_box.add_child(_mode_adv)
	_sym_check = CheckBox.new()
	_sym_check.text = "Mirror curve edits"
	_sym_check.button_pressed = editor.symmetric_cage
	_sym_check.toggled.connect(func(v): editor.symmetric_cage = v)
	_tool_box.add_child(_sym_check)
	var rs := Button.new()
	rs.text = "Reset shape"
	rs.pressed.connect(func():
		if editor.selected_garment():
			editor.change("Reset shape", func(): editor.selected_garment().reset_transform()))
	_tool_box.add_child(rs)
	var rc := Button.new()
	rc.text = "Reset curves"
	rc.pressed.connect(func():
		if editor.selected_garment():
			editor.change("Reset curves", func(): editor.selected_garment().reset_lattice()))
	_tool_box.add_child(rc)
	_hint = UiTheme.note("")
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_hint)
	var zoom_box := HBoxContainer.new()
	row.add_child(zoom_box)
	var zout := Button.new()
	zout.text = "−"
	zout.custom_minimum_size.x = 40
	zout.tooltip_text = "Zoom out (mouse wheel)"
	zout.pressed.connect(func(): camera.set_zoom_level(camera.zoom.x / 1.25))
	zoom_box.add_child(zout)
	_zoom_label = Label.new()
	_zoom_label.text = "100%"
	_zoom_label.custom_minimum_size.x = 60
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zoom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	zoom_box.add_child(_zoom_label)
	var zin := Button.new()
	zin.text = "+"
	zin.custom_minimum_size.x = 40
	zin.tooltip_text = "Zoom in (mouse wheel)"
	zin.pressed.connect(func(): camera.set_zoom_level(camera.zoom.x * 1.25))
	zoom_box.add_child(zin)
	var fit := Button.new()
	fit.text = "Whole model"
	fit.tooltip_text = "Frame the whole model"
	fit.pressed.connect(frame_model)
	zoom_box.add_child(fit)
	var focus := Button.new()
	focus.text = "Focus piece"
	focus.tooltip_text = "Zoom to the selected piece (F)"
	focus.pressed.connect(focus_selection)
	zoom_box.add_child(focus)


func _build_dialogs() -> void:
	radio_panel = RadioPanel.new()
	radio_panel.music = music
	root.add_child(radio_panel)
	gallery = GalleryDialog.new()
	root.add_child(gallery)
	gallery.load_requested.connect(_load_from_path)

	_save_dialog = ConfirmationDialog.new()
	_save_dialog.title = "Save design"
	_save_dialog.ok_button_text = "Save"
	var v := VBoxContainer.new()
	var l := Label.new()
	l.text = "Name your design:"
	v.add_child(l)
	_save_name = LineEdit.new()
	_save_name.custom_minimum_size.x = 360
	_save_name.max_length = 60
	_save_name.text_submitted.connect(func(_t):
		_save_dialog.hide()
		_on_save_confirmed())
	v.add_child(_save_name)
	_save_dialog.add_child(v)
	_save_dialog.confirmed.connect(_on_save_confirmed)
	root.add_child(_save_dialog)

	_overwrite = ConfirmationDialog.new()
	_overwrite.title = "Overwrite design?"
	_overwrite.ok_button_text = "Overwrite"
	_overwrite.confirmed.connect(func(): _do_save(_save_name.text.strip_edges()))
	root.add_child(_overwrite)

	_new_confirm = ConfirmationDialog.new()
	_new_confirm.title = "New design"
	_new_confirm.dialog_text = "Start a new design? Unsaved changes can still be undone."
	_new_confirm.ok_button_text = "Start fresh"
	_new_confirm.confirmed.connect(_do_new)
	root.add_child(_new_confirm)


# ------------------------------------------------------------------ actions
func _on_new() -> void:
	if editor.dirty:
		_new_confirm.popup_centered()
	else:
		_do_new()


func _do_new() -> void:
	editor.new_design()
	toast("A fresh design on the mannequin")
	frame_model()


func _on_save() -> void:
	_save_name.text = editor.design_name if editor.design_name != "" else _suggest_name()
	_save_dialog.popup_centered()
	_save_name.grab_focus()
	_save_name.select_all()


func _suggest_name() -> String:
	var def := Content.get_garment(editor.design.garment("skirt").template_id)
	var base := def.display_name if def else "My Design"
	return "%s %s" % [base, Time.get_date_string_from_system().right(5)]


func _on_save_confirmed() -> void:
	var n := _save_name.text.strip_edges()
	if n == "":
		toast("Please give the design a name")
		return
	if DesignPersistence.exists(n) and n != editor.design_name:
		_overwrite.dialog_text = "A design called \"%s\" already exists. Replace it?" % n
		_overwrite.popup_centered()
		return
	_do_save(n)


func _do_save(design_name: String) -> void:
	var img: Image = null
	if thumbnailer and DisplayServer.get_name() != "headless":
		img = await thumbnailer.capture(editor.design)
	var err := DesignPersistence.save_design(editor.design, design_name, img)
	if err == OK:
		editor.design_name = design_name
		editor.dirty = false
		_refresh_title()
		toast("Saved \"%s\"" % design_name)
		SoundEffects.play("snip", -6.0)
	else:
		toast("Could not save (error %d)" % err)


func _on_gallery() -> void:
	gallery.refresh()
	gallery.popup_centered()


func _load_from_path(path: String) -> void:
	var data := DesignPersistence.load_data(path)
	var d := DressDesign.from_save_data(data)
	if d == null:
		toast("That design could not be read")
		return
	editor.load_design(d, str(data.get("name", "")))
	toast("Loaded \"%s\"" % editor.design_name)
	frame_model()


func open_radio() -> void:
	SoundEffects.play("radio", -8.0)
	radio_panel.popup_centered(Vector2i(480, 0))


func set_preview(on: bool) -> void:
	preview_mode = on
	top_bar.visible = not on
	library.visible = not on
	properties.visible = not on
	bottom_bar.visible = not on
	_exit_preview.visible = on
	handles.enabled = not on
	presentation.set_selected_slot("" if on else editor.selected_slot)
	camera.ui_insets = Vector4.ZERO if on else Vector4(LEFT_W + 12, TOP_H + 8, RIGHT_W + 12, BOTTOM_H + 8)
	frame_model(1.2 if on else 1.45)


func frame_model(padding: float = 1.08) -> void:
	var b := presentation.slot_bounds("model")
	for slot in DressDesign.GARMENT_SLOTS:
		if presentation.shapes.has(slot):
			b = b.merge(presentation.slot_bounds(slot))
	var xf := presentation.rig.get_global_transform()
	camera.focus_rect(Rect2(xf * b.position, b.size * xf.get_scale()), true, padding)


func focus_selection() -> void:
	var b := presentation.slot_bounds(editor.selected_slot)
	var xf := presentation.rig.get_global_transform()
	camera.focus_rect(Rect2(xf * b.position, b.size * xf.get_scale()), true, 1.5)


func toast(text: String) -> void:
	_toast.text = text
	_toast.reset_size()
	_toast.position.x = (root.size.x - _toast.size.x) * 0.5 - root.size.x * 0.5
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


# ------------------------------------------------------------------ state refresh
func _refresh_history() -> void:
	_undo_btn.disabled = not editor.can_undo()
	_redo_btn.disabled = not editor.can_redo()


func _refresh_title() -> void:
	var n := editor.design_name if editor.design_name != "" else "Untitled design"
	_name_label.text = n + (" •" if editor.dirty else "")


func _on_selection_changed(slot: String) -> void:
	presentation.set_selected_slot(slot)
	_refresh_tools()
	if DressDesign.is_garment_slot(slot) and presentation.shapes.has(slot):
		var b := presentation.slot_bounds(slot)
		var xf := presentation.rig.get_global_transform()
		camera.ensure_visible(Rect2(xf * b.position, b.size * xf.get_scale()))


func _refresh_tools() -> void:
	var garment_selected := DressDesign.is_garment_slot(editor.selected_slot)
	_tool_box.visible = garment_selected
	_mode_basic.set_pressed_no_signal(editor.edit_mode == "basic")
	_mode_adv.set_pressed_no_signal(editor.edit_mode == "advanced")
	if not garment_selected:
		_hint.text = "Click a bodice, skirt or sleeve on the model to edit its shape. Right-drag to pan, mouse wheel to zoom."
	elif editor.edit_mode == "basic":
		_hint.text = "Drag the fabric to move it. Squares scale, the green knob rotates, blue diamonds skew, the orange knob bends."
	else:
		_hint.text = "Drag the pink curve points to bend and reshape the fabric. Seams stay connected."


# ------------------------------------------------------------------ shortcuts
func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	var k := event as InputEventKey
	var ctrl := k.ctrl_pressed or k.meta_pressed
	if preview_mode and (k.keycode == KEY_ESCAPE or k.keycode == KEY_H):
		set_preview(false)
	elif ctrl and k.keycode == KEY_Z and k.shift_pressed:
		editor.redo()
	elif ctrl and k.keycode == KEY_Z:
		editor.undo()
	elif ctrl and k.keycode == KEY_Y:
		editor.redo()
	elif ctrl and k.keycode == KEY_S:
		_on_save()
	elif ctrl and k.keycode == KEY_N:
		_on_new()
	elif k.keycode == KEY_TAB:
		editor.set_mode("advanced" if editor.edit_mode == "basic" else "basic")
	elif k.keycode == KEY_F:
		focus_selection()
	elif k.keycode == KEY_H:
		set_preview(not preview_mode)
	else:
		return
	get_viewport().set_input_as_handled()
