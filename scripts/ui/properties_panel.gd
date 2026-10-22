class_name PropertiesPanel
extends PanelContainer
## Right panel: properties of the current selection (colors, fabric, transform,
## layer and visibility options). Controls are rebuilt only when the selection's
## structure changes; otherwise their values are refreshed in place so that
## slider drags and color picking are never interrupted.

const PALETTES := {
	"Victorian Jewel": ["7b2d3a", "1f3a5f", "2f5d50", "5a2a6e", "d9b25c", "1a1a1a", "f2e8d5", "8b1e2b"],
	"Pastel Parlour": ["f4c2c2", "cdb4db", "bde0fe", "a2d2ff", "fff1c1", "c1e1c1", "ffd6a5", "fde2e4"],
	"Mourning & Lace": ["111111", "2b2b2b", "4a4a4a", "6d6875", "f6f1e9", "e0d4bd", "3b2a20", "b8a88c"],
	"Garden Party": ["6a994e", "a7c957", "f2e8cf", "bc4749", "e9c46a", "f4a261", "457b9d", "ffafcc"],
	"Bold Modern": ["e63946", "ffb703", "2a9d8f", "3a86ff", "ff006e", "8338ec", "06d6a0", "fb5607"],
}
const SKIN_TONES := ["fbe3d3", "f5d0b5", "e8b996", "d39b72", "b07850", "8d5a3b", "6b4128", "4a2c1c", "e9d8c4", "c9c2b8"]
const MAX_RECENT := 10

static var recent_colors: Array[Color] = []
static var palette_name: String = "Victorian Jewel"

var editor: FashionEditor
var _content: VBoxContainer
var _scroll: ScrollContainer
var _refreshers: Array[Callable] = []
var _pickers: Array[ColorPicker] = []
var _structure_key: String = ""
var _recent_row: HFlowContainer
var _primary_setter: Callable


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.panel_box())
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 6)
	_scroll.add_child(_content)
	editor.design_changed.connect(_on_design_changed)
	editor.selection_changed.connect(func(_s): _rebuild())
	editor.design_replaced.connect(_rebuild)
	_rebuild()


func _on_design_changed() -> void:
	if _compute_structure_key() != _structure_key:
		_rebuild()
	else:
		for r in _refreshers:
			r.call()


func _compute_structure_key() -> String:
	var d := editor.design
	var slot := editor.selected_slot
	var key := slot
	if DressDesign.is_garment_slot(slot):
		key += "|" + str(d.garment(slot).is_empty()) + str(d.sleeves_linked)
	elif slot == "shoes":
		key += "|" + d.shoe_id
	elif slot == "hair":
		key += "|" + d.hair_id
	elif slot == "jewelry":
		for c in DressDesign.JEWELRY_CATEGORIES:
			key += "|" + str(d.jewelry[c]["id"] == "")
	return key


func _rebuild() -> void:
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	_refreshers.clear()
	_pickers.clear()
	_primary_setter = Callable()
	_structure_key = _compute_structure_key()
	var slot := editor.selected_slot
	if DressDesign.is_garment_slot(slot):
		_build_garment(slot)
	elif slot == "body":
		_build_body()
	elif slot == "shoes":
		_build_shoes()
	elif slot == "hair":
		_build_hair()
	elif slot == "jewelry":
		_build_jewelry()
	_build_palette_section()
	for r in _refreshers:
		r.call()


# ------------------------------------------------------------------ sections
func _build_garment(slot: String) -> void:
	var d := editor.design
	var titles := {"bodice": "Bodice", "skirt": "Skirt", "sleeve_left": "Sleeves", "sleeve_right": "Sleeves"}
	_content.add_child(UiTheme.header(titles[slot]))
	var name_label := Label.new()
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(name_label)
	_refreshers.append(func():
		var def := Content.get_garment(editor.design.garment(editor.selected_slot).template_id)
		name_label.text = def.display_name if def else "No piece chosen")
	if DressDesign.is_sleeve_slot(slot):
		var side_row := HBoxContainer.new()
		var group := ButtonGroup.new()
		for s in [["sleeve_left", "Left sleeve"], ["sleeve_right", "Right sleeve"]]:
			var b := Button.new()
			b.text = s[1]
			b.toggle_mode = true
			b.button_group = group
			b.button_pressed = slot == s[0]
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func(): editor.select(s[0]))
			side_row.add_child(b)
		_content.add_child(side_row)
		_check("Link left & right (mirror edits)", func(): return editor.design.sleeves_linked, func(v):
			editor.change("Link sleeves", func():
				editor.design.sleeves_linked = v
				if v:
					editor.design.sync_sleeves(editor.selected_slot)))
	var inst := d.garment(slot)
	if inst.is_empty():
		_content.add_child(UiTheme.note("Choose a piece from the library on the left. Selecting \"None\" removes a piece."))
		return
	var row := HBoxContainer.new()
	_content.add_child(row)
	var vis := CheckBox.new()
	vis.text = "Visible"
	vis.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vis.toggled.connect(func(v): editor.change("Visibility", func(): editor.design.garment(editor.selected_slot).visible = v))
	_refreshers.append(func(): vis.set_pressed_no_signal(editor.design.garment(editor.selected_slot).visible))
	row.add_child(vis)
	var remove := Button.new()
	remove.text = "Remove piece"
	remove.pressed.connect(func(): editor.change("Remove piece", func():
		editor.design.garment(editor.selected_slot).template_id = ""
		if DressDesign.is_sleeve_slot(editor.selected_slot) and editor.design.sleeves_linked:
			editor.design.garment(DressDesign.other_sleeve(editor.selected_slot)).template_id = ""))
	row.add_child(remove)
	match slot:
		"skirt":
			_check("Attach to bodice waist (seam lock)", func(): return _g().attached, func(v): editor.change("Attach", func(): _g().attached = v))
		"bodice":
			_check("Tuck bodice under skirt", func(): return _g().layer_front, func(v): editor.change("Layer", func(): _g().layer_front = v))
			var wb_row := HBoxContainer.new()
			_content.add_child(wb_row)
			var wb := CheckBox.new()
			wb.text = "Waistband trim"
			wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			wb.toggled.connect(func(v): editor.change("Waistband", func(): editor.design.waistband = v))
			_refreshers.append(func(): wb.set_pressed_no_signal(editor.design.waistband))
			wb_row.add_child(wb)
			wb_row.add_child(_color_button("Waistband color", func(): return editor.design.waistband_color, func(c): editor.design.waistband_color = c, Vector2(70, 32)))
		_:
			_check("Follow the bodice shoulders", func(): return _g().attached, func(v): editor.change("Attach", func(): _g().attached = v))
			_check("Draw sleeves over the bodice", func(): return _g().layer_front, func(v): editor.change("Layer", func(): _g().layer_front = v))

	_content.add_child(HSeparator.new())
	_content.add_child(UiTheme.header("Fabric"))
	var fabric_opt := OptionButton.new()
	for f in Content.fabrics:
		fabric_opt.add_item(f.display_name)
		fabric_opt.set_item_metadata(fabric_opt.item_count - 1, f.id)
	fabric_opt.item_selected.connect(func(i): editor.change("Fabric", func(): _g().material.fabric_id = fabric_opt.get_item_metadata(i)))
	_refreshers.append(func():
		for i in range(fabric_opt.item_count):
			if fabric_opt.get_item_metadata(i) == _g().material.fabric_id:
				fabric_opt.select(i))
	_content.add_child(fabric_opt)
	var colors := GridContainer.new()
	colors.columns = 2
	_content.add_child(colors)
	_primary_setter = func(c): _g().material.primary = c
	for spec in [["Main color", "primary"], ["Pattern color", "secondary"], ["Trim color", "trim"]]:
		var l := Label.new()
		l.text = spec[0]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		colors.add_child(l)
		var prop: String = spec[1]
		colors.add_child(_color_button(spec[0], func(): return _g().material.get(prop), func(c): _g().material.set(prop, c)))
	_slider("Pattern scale", 0.25, 4.0, 0.05, func(): return _g().material.pattern_scale, func(v): _g().material.pattern_scale = v, "%.2f×")
	_slider("Pattern angle", -180, 180, 1, func(): return _g().material.pattern_rotation, func(v): _g().material.pattern_rotation = v, "%d°")
	_slider("Opacity", 0.2, 1.0, 0.01, func(): return _g().material.opacity, func(v): _g().material.opacity = v, "%.2f")

	_content.add_child(HSeparator.new())
	_content.add_child(UiTheme.header("Shape"))
	_content.add_child(UiTheme.note("Drag the handles on the model, or fine-tune here. Advanced mode (bottom bar) edits curve points."))
	_slider("Move X", -250, 250, 1, func(): return _g().offset.x, func(v): _g().offset.x = v, "%d")
	_slider("Move Y", -250, 250, 1, func(): return _g().offset.y, func(v): _g().offset.y = v, "%d")
	_slider("Width", 0.2, 4.0, 0.01, func(): return _g().scale.x, func(v): _g().scale.x = v, "%.2f×")
	_slider("Height", 0.2, 4.0, 0.01, func(): return _g().scale.y, func(v): _g().scale.y = v, "%.2f×")
	_slider("Rotate", -180, 180, 1, func(): return rad_to_deg(_g().rotation), func(v): _g().rotation = deg_to_rad(v), "%d°")
	_slider("Skew H", -55, 55, 1, func(): return rad_to_deg(_g().skew.x), func(v): _g().skew.x = deg_to_rad(v), "%d°")
	_slider("Skew V", -55, 55, 1, func(): return rad_to_deg(_g().skew.y), func(v): _g().skew.y = deg_to_rad(v), "%d°")
	_slider("Bend", -3.0, 3.0, 0.01, func(): return _g().bend, func(v): _g().bend = v, "%.2f")
	_slider("Flare", -0.8, 3.0, 0.01, func(): return _g().flare, func(v): _g().flare = v, "%.2f")
	var resets := HBoxContainer.new()
	_content.add_child(resets)
	var rs := Button.new()
	rs.text = "Reset shape"
	rs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.pressed.connect(func(): editor.change("Reset shape", func(): _g().reset_transform()))
	resets.add_child(rs)
	var rc := Button.new()
	rc.text = "Reset curves"
	rc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rc.pressed.connect(func(): editor.change("Reset curves", func(): _g().reset_lattice()))
	resets.add_child(rc)


func _build_body() -> void:
	var d := editor.design
	_content.add_child(UiTheme.header("Model"))
	var body_label := Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(body_label)
	_refreshers.append(func():
		var b := Content.get_body(editor.design.body_id)
		body_label.text = "%s — %s" % [b.display_name, b.description] if b else "")
	_content.add_child(UiTheme.note("Pick a body type from the library. Your dress adapts automatically."))
	_content.add_child(HSeparator.new())
	_content.add_child(UiTheme.header("Skin tone"))
	var row := HBoxContainer.new()
	_content.add_child(row)
	var l := Label.new()
	l.text = "Custom"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	_primary_setter = func(c): editor.design.skin_color = c
	row.add_child(_color_button("Skin tone", func(): return editor.design.skin_color, func(c): editor.design.skin_color = c))
	var flow := HFlowContainer.new()
	_content.add_child(flow)
	for hex in SKIN_TONES:
		flow.add_child(_swatch(Color.html(hex), func(c): editor.change("Skin tone", func(): editor.design.skin_color = c)))
	var _unused := d


func _build_shoes() -> void:
	_content.add_child(UiTheme.header("Shoes"))
	var def := Content.get_shoe(editor.design.shoe_id)
	if def == null:
		_content.add_child(UiTheme.note("Barefoot. Choose a pair of shoes from the library."))
		return
	var name_l := Label.new()
	name_l.text = def.display_name
	_content.add_child(name_l)
	_content.add_child(UiTheme.note("Every part of the shoe can be colored separately."))
	var grid := GridContainer.new()
	grid.columns = 2
	_content.add_child(grid)
	for i in range(def.region_names.size()):
		var idx := i
		var l := Label.new()
		l.text = def.region_names[i]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(l)
		grid.add_child(_color_button(def.region_names[i], func(): return _shoe_color(idx), func(c): _set_shoe_color(idx, c)))
		if i == 0:
			_primary_setter = func(c): _set_shoe_color(0, c)
	var reset := Button.new()
	reset.text = "Restore original colors"
	reset.pressed.connect(func(): editor.change("Shoe colors", func(): editor.design.shoe_colors = def.region_defaults.duplicate()))
	_content.add_child(reset)


func _shoe_color(i: int) -> Color:
	var cols := editor.design.shoe_colors
	var def := Content.get_shoe(editor.design.shoe_id)
	if i < cols.size():
		return cols[i]
	return def.region_defaults[i] if def and i < def.region_defaults.size() else Color.WHITE


func _set_shoe_color(i: int, c: Color) -> void:
	var def := Content.get_shoe(editor.design.shoe_id)
	var cols := editor.design.shoe_colors
	if def:
		while cols.size() < def.region_names.size():
			cols.append(def.region_defaults[cols.size()])
	if i < cols.size():
		cols[i] = c
	editor.design.shoe_colors = cols


func _build_hair() -> void:
	_content.add_child(UiTheme.header("Hair"))
	var def := Content.get_hair(editor.design.hair_id)
	if def == null:
		_content.add_child(UiTheme.note("No hairstyle. Choose one from the library — styles marked ✦ have several colors."))
		return
	var name_l := Label.new()
	name_l.text = def.display_name
	_content.add_child(name_l)
	var grid := GridContainer.new()
	grid.columns = 2
	_content.add_child(grid)
	for i in range(def.color_count):
		var idx := i
		var l := Label.new()
		l.text = def.color_names[i] if i < def.color_names.size() else "Color %d" % (i + 1)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(l)
		grid.add_child(_color_button(l.text, func(): return editor.design.hair_colors[idx], func(c):
			var cols := editor.design.hair_colors
			cols[idx] = c
			editor.design.hair_colors = cols))
		if i == 0:
			_primary_setter = func(c):
				var cols2 := editor.design.hair_colors
				cols2[0] = c
				editor.design.hair_colors = cols2
	_content.add_child(UiTheme.note("Natural shades"))
	var flow := HFlowContainer.new()
	_content.add_child(flow)
	for hex in ["1f1712", "3b2416", "5a3825", "8a3b1e", "b5562b", "d9b26f", "efd9a7", "a89f91", "e8e4dc"]:
		flow.add_child(_swatch(Color.html(hex), func(c): editor.change("Hair color", func():
			var cols := editor.design.hair_colors
			cols[0] = c
			editor.design.hair_colors = cols)))


func _build_jewelry() -> void:
	_content.add_child(UiTheme.header("Jewelry"))
	_content.add_child(UiTheme.note("Choose designs in the library, or here. Each piece has its own metal and gem colors."))
	var names := {"earrings": "Earrings", "necklace": "Necklace", "bracelet": "Bracelets", "anklet": "Anklets", "tiara": "Tiara"}
	for cat in DressDesign.JEWELRY_CATEGORIES:
		var c: String = cat
		_content.add_child(HSeparator.new())
		var title_row := HBoxContainer.new()
		_content.add_child(title_row)
		var t := Label.new()
		t.text = names[c]
		t.add_theme_font_override("font", UiTheme.font("bold"))
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_row.add_child(t)
		var vis := CheckBox.new()
		vis.text = "Show"
		vis.toggled.connect(func(v): editor.change("Show " + c, func(): editor.design.jewelry[c]["visible"] = v))
		_refreshers.append(func(): vis.set_pressed_no_signal(editor.design.jewelry[c]["visible"]))
		title_row.add_child(vis)
		var opt := OptionButton.new()
		opt.add_item("None")
		opt.set_item_metadata(0, "")
		for j in Content.jewelry_in(c):
			opt.add_item(j.display_name)
			opt.set_item_metadata(opt.item_count - 1, j.id)
		opt.item_selected.connect(func(i): editor.change("Choose " + c, func():
			var id: String = opt.get_item_metadata(i)
			if id == "":
				editor.design.jewelry[c]["id"] = ""
			else:
				DesignFactory.set_jewelry(editor.design, c, id)))
		_refreshers.append(func():
			for i in range(opt.item_count):
				if opt.get_item_metadata(i) == editor.design.jewelry[c]["id"]:
					opt.select(i))
		_content.add_child(opt)
		if editor.design.jewelry[c]["id"] != "":
			var cr := HBoxContainer.new()
			_content.add_child(cr)
			for spec in [["Metal", "metal"], ["Gem", "gem"]]:
				var l := Label.new()
				l.text = spec[0]
				cr.add_child(l)
				var key: String = spec[1]
				var btn := _color_button(names[c] + " " + spec[0], func(): return editor.design.jewelry[c][key], func(col): editor.design.jewelry[c][key] = col, Vector2(64, 30))
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				cr.add_child(btn)


func _build_palette_section() -> void:
	_content.add_child(HSeparator.new())
	_content.add_child(UiTheme.header("Colors"))
	var opt := OptionButton.new()
	var i := 0
	for p in PALETTES:
		opt.add_item(p)
		if p == palette_name:
			opt.select(i)
		i += 1
	opt.item_selected.connect(func(idx):
		palette_name = opt.get_item_text(idx)
		_apply_palette_to_pickers()
		_rebuild())
	_content.add_child(opt)
	var flow := HFlowContainer.new()
	_content.add_child(flow)
	for hex in PALETTES[palette_name]:
		flow.add_child(_swatch(Color.html(hex), _apply_quick_color))
	_content.add_child(UiTheme.note("Recent colors"))
	_recent_row = HFlowContainer.new()
	_content.add_child(_recent_row)
	_update_recent_row()
	if not _primary_setter.is_valid():
		for c in _recent_row.get_children():
			(c as Button).disabled = true
		for c in flow.get_children():
			(c as Button).disabled = true


func _apply_quick_color(c: Color) -> void:
	if _primary_setter.is_valid():
		editor.change("Color", func(): _primary_setter.call(c))
		_remember(c)


# ------------------------------------------------------------------ control helpers
func _g() -> GarmentInstance:
	return editor.design.garment(editor.selected_slot)


func _check(text: String, getter: Callable, on_toggle: Callable) -> CheckBox:
	var cb := CheckBox.new()
	cb.text = text
	cb.toggled.connect(on_toggle)
	_refreshers.append(func(): cb.set_pressed_no_signal(getter.call()))
	_content.add_child(cb)
	return cb


func _slider(label: String, min_v: float, max_v: float, step: float, getter: Callable, setter: Callable, fmt: String) -> HSlider:
	var row := HBoxContainer.new()
	_content.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 104
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(s)
	var val := Label.new()
	val.custom_minimum_size.x = 56
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val)
	s.drag_started.connect(func(): editor.begin_interaction(label))
	s.drag_ended.connect(func(_changed): editor.end_interaction())
	s.value_changed.connect(func(v):
		val.text = fmt % v
		editor.change(label, func(): setter.call(v)))
	_refreshers.append(func():
		var v: float = getter.call()
		s.set_value_no_signal(v)
		val.text = fmt % v)
	return s


func _color_button(label: String, getter: Callable, setter: Callable, min_size: Vector2 = Vector2(110, 32)) -> ColorPickerButton:
	var b := ColorPickerButton.new()
	b.custom_minimum_size = min_size
	b.tooltip_text = label
	b.edit_alpha = false
	var picker := b.get_picker()
	picker.presets_visible = true
	picker.can_add_swatches = true
	picker.sampler_visible = false
	_pickers.append(picker)
	_load_palette_into(picker)
	b.color_changed.connect(func(c): editor.change(label, func(): setter.call(c)))
	b.popup_closed.connect(func():
		_remember(b.color)
		editor.end_interaction())
	b.picker_created.connect(func(): pass)
	_refreshers.append(func(): b.color = getter.call())
	return b


func _swatch(c: Color, on_pick: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(28, 28)
	b.tooltip_text = "#" + c.to_html(false)
	var sb := UiTheme.box(c, UiTheme.WALNUT, 1, 4, 0)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := UiTheme.box(c.lightened(0.15), UiTheme.GOLD, 2, 4, 0)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.pressed.connect(func(): on_pick.call(c))
	return b


func _remember(c: Color) -> void:
	for existing in recent_colors:
		if existing.is_equal_approx(c):
			recent_colors.erase(existing)
			break
	recent_colors.push_front(c)
	while recent_colors.size() > MAX_RECENT:
		recent_colors.pop_back()
	_update_recent_row()


func _update_recent_row() -> void:
	if _recent_row == null or not is_instance_valid(_recent_row):
		return
	for ch in _recent_row.get_children():
		ch.queue_free()
	if recent_colors.is_empty():
		var l := Label.new()
		l.text = "—"
		_recent_row.add_child(l)
	for c in recent_colors:
		_recent_row.add_child(_swatch(c, _apply_quick_color))


func _load_palette_into(picker: ColorPicker) -> void:
	for p in picker.get_presets():
		picker.erase_preset(p)
	for hex in PALETTES[palette_name]:
		picker.add_preset(Color.html(hex))


func _apply_palette_to_pickers() -> void:
	for p in _pickers:
		if is_instance_valid(p):
			_load_palette_into(p)
