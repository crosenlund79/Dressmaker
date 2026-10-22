class_name LibraryPanel
extends PanelContainer
## Left panel: category tabs and the content library grid for the active category.

signal category_changed(category: String)

const CATEGORIES := ["Body", "Bodice", "Skirt", "Sleeves", "Fabric", "Shoes", "Jewelry", "Hair"]
const JEWELRY_TABS := {"earrings": "Earrings", "necklace": "Necklaces", "bracelet": "Bracelets", "anklet": "Anklets", "tiara": "Tiaras"}
const ICON_SIZE := Vector2(104, 104)

var editor: FashionEditor
var category: String = "Bodice"
var jewelry_category: String = "earrings"

var _cat_buttons: Dictionary = {}
var _grid: GridContainer
var _title: Label
var _subtabs: HFlowContainer
var _scroll: ScrollContainer
var _item_buttons: Array = []  # [{button, is_selected: Callable}]


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.panel_box())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	var cats := VBoxContainer.new()
	cats.custom_minimum_size.x = 112
	cats.add_theme_constant_override("separation", 6)
	row.add_child(cats)
	var group := ButtonGroup.new()
	for c in CATEGORIES:
		var b := Button.new()
		b.text = c
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(108, 44)
		b.add_theme_font_override("font", UiTheme.font("bold"))
		b.pressed.connect(_on_category_pressed.bind(c))
		cats.add_child(b)
		_cat_buttons[c] = b
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	_title = UiTheme.header("")
	right.add_child(_title)
	_subtabs = HFlowContainer.new()
	right.add_child(_subtabs)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_scroll.add_child(_grid)
	editor.design_changed.connect(_refresh_selection)
	editor.design_replaced.connect(_rebuild)
	editor.selection_changed.connect(_on_selection_changed)
	show_category(category, false)


func _on_category_pressed(c: String) -> void:
	show_category(c, true)


func show_category(c: String, select_slot: bool) -> void:
	category = c
	for key in _cat_buttons:
		(_cat_buttons[key] as Button).set_pressed_no_signal(key == c)
	if select_slot:
		match c:
			"Body":
				editor.select("body")
			"Bodice":
				editor.select("bodice")
			"Skirt":
				editor.select("skirt")
			"Sleeves":
				editor.select(editor.selected_slot if DressDesign.is_sleeve_slot(editor.selected_slot) else "sleeve_right")
			"Fabric":
				editor.select(editor.garment_slot_or_default())
			"Shoes":
				editor.select("shoes")
			"Jewelry":
				editor.select("jewelry")
			"Hair":
				editor.select("hair")
	_rebuild()
	category_changed.emit(c)


func _on_selection_changed(slot: String) -> void:
	var c := category
	match slot:
		"body":
			c = "Body"
		"bodice":
			c = "Bodice" if category != "Fabric" else "Fabric"
		"skirt":
			c = "Skirt" if category != "Fabric" else "Fabric"
		"sleeve_left", "sleeve_right":
			c = "Sleeves" if category != "Fabric" else "Fabric"
		"shoes":
			c = "Shoes"
		"jewelry":
			c = "Jewelry"
		"hair":
			c = "Hair"
	if c != category:
		show_category(c, false)
	else:
		_rebuild()


func _rebuild() -> void:
	for ch in _grid.get_children():
		ch.queue_free()
	for ch in _subtabs.get_children():
		ch.queue_free()
	_item_buttons.clear()
	_subtabs.visible = category == "Jewelry"
	var d := editor.design
	match category:
		"Body":
			_title.text = "Body Types"
			for b in Content.bodies:
				var body_def: BodyDefinition = b
				_add_item(b.display_name, func(ci, r): PreviewArt.body(ci, r, body_def, d.skin_color),
					func(): return editor.design.body_id == body_def.id,
					func(): editor.change("Body type", func(): editor.design.body_id = body_def.id), b.description)
		"Bodice", "Skirt", "Sleeves":
			var slot := _garment_slot()
			var cat: String = {"Bodice": "bodice", "Skirt": "skirt", "Sleeves": "sleeve"}[category]
			_title.text = {"Bodice": "Bodices", "Skirt": "Skirts", "Sleeves": "Sleeves"}[category]
			_add_item("None", func(ci, r): _draw_none(ci, r),
				func(): return editor.design.garment(slot).is_empty(),
				func(): editor.change("Remove " + category.to_lower(), func(): _set_garment(slot, "")))
			for g in Content.garments_in(cat):
				var gd: GarmentDefinition = g
				_add_item(g.display_name, func(ci, r): PreviewArt.garment(ci, r, gd, gd.default_color, gd.default_trim),
					func(): return editor.design.garment(_garment_slot()).template_id == gd.id,
					func(): editor.change("Choose " + gd.display_name, func(): _set_garment(_garment_slot(), gd.id)))
		"Fabric":
			var gslot := editor.garment_slot_or_default()
			_title.text = "Fabrics"
			for f in Content.fabrics:
				var fd: FabricDefinition = f
				var btn := _add_item(f.display_name, func(ci, r): PreviewArt.fabric_swatch(ci, r),
					func(): return editor.design.garment(editor.garment_slot_or_default()).material.fabric_id == fd.id,
					func(): editor.change("Fabric " + fd.display_name, func(): editor.design.garment(editor.garment_slot_or_default()).material.fabric_id = fd.id))
				var icon: PreviewIcon = btn.get_meta("icon")
				var m := d.garment(gslot).material
				icon.material = PreviewArt.fabric_material(fd, m.primary if not d.garment(gslot).is_empty() else fd.default_color, m.secondary if not d.garment(gslot).is_empty() else fd.default_secondary)
		"Shoes":
			_title.text = "Shoes"
			_add_item("Barefoot", func(ci, r): _draw_none(ci, r), func(): return editor.design.shoe_id == "",
				func(): editor.change("Remove shoes", func(): editor.design.shoe_id = ""))
			for s in Content.shoes:
				var sd: ShoeDefinition = s
				_add_item(s.display_name, func(ci, r): PreviewArt.shoe(ci, r, sd), func(): return editor.design.shoe_id == sd.id,
					func(): editor.change("Choose " + sd.display_name, func(): DesignFactory.set_shoe(editor.design, sd.id)))
		"Jewelry":
			_title.text = "Jewelry"
			var group := ButtonGroup.new()
			for key in JEWELRY_TABS:
				var tb := Button.new()
				tb.text = JEWELRY_TABS[key]
				tb.toggle_mode = true
				tb.button_group = group
				tb.button_pressed = key == jewelry_category
				tb.add_theme_font_size_override("font_size", 14)
				tb.pressed.connect(func():
					jewelry_category = key
					_rebuild())
				_subtabs.add_child(tb)
			var jc := jewelry_category
			_add_item("None", func(ci, r): _draw_none(ci, r), func(): return editor.design.jewelry[jc]["id"] == "",
				func(): editor.change("Remove " + JEWELRY_TABS[jc].to_lower(), func(): editor.design.jewelry[jc]["id"] = ""))
			for j in Content.jewelry_in(jc):
				var jd: JewelryDefinition = j
				_add_item(j.display_name, func(ci, r): PreviewArt.jewelry(ci, r, jd), func(): return editor.design.jewelry[jc]["id"] == jd.id,
					func(): editor.change("Choose " + jd.display_name, func(): DesignFactory.set_jewelry(editor.design, jc, jd.id)))
		"Hair":
			_title.text = "Hairstyles"
			_add_item("None", func(ci, r): _draw_none(ci, r), func(): return editor.design.hair_id == "",
				func(): editor.change("Remove hair", func(): editor.design.hair_id = ""))
			for h in Content.hairstyles:
				var hd: HairDefinition = h
				var label := h.display_name + ("  ✦" if h.color_count > 1 else "")
				_add_item(label, func(ci, r): PreviewArt.hair(ci, r, hd, d.skin_color), func(): return editor.design.hair_id == hd.id,
					func(): editor.change("Choose " + hd.display_name, func(): DesignFactory.set_hair(editor.design, hd.id)),
					"%s (%d color%s)" % [hd.display_name, hd.color_count, "s" if hd.color_count > 1 else ""])
	_refresh_selection()


func _garment_slot() -> String:
	match category:
		"Bodice":
			return "bodice"
		"Skirt":
			return "skirt"
	return editor.selected_slot if DressDesign.is_sleeve_slot(editor.selected_slot) else "sleeve_right"


func _set_garment(slot: String, template_id: String) -> void:
	var d := editor.design
	if template_id == "":
		d.garment(slot).template_id = ""
		if DressDesign.is_sleeve_slot(slot) and d.sleeves_linked:
			d.garment(DressDesign.other_sleeve(slot)).template_id = ""
		return
	DesignFactory.set_template(d, slot, template_id)
	# Picking a sleeve for an empty pair fills both sides when linked.
	if DressDesign.is_sleeve_slot(slot) and d.sleeves_linked:
		d.sync_sleeves(slot)


func _add_item(label: String, draw_fn: Callable, is_selected: Callable, on_pick: Callable, tooltip: String = "") -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(ICON_SIZE.x + 12, ICON_SIZE.y + 34)
	b.tooltip_text = tooltip if tooltip != "" else label
	b.clip_contents = true
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 4
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	var icon := PreviewIcon.new(draw_fn, ICON_SIZE)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)
	var l := Label.new()
	l.text = label
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 13)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = ICON_SIZE.x + 6
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	b.set_meta("icon", icon)
	b.set_meta("label", l)
	b.pressed.connect(func():
		on_pick.call()
		_refresh_selection())
	_grid.add_child(b)
	_item_buttons.append({"button": b, "selected": is_selected})
	return b


func _refresh_selection() -> void:
	for item in _item_buttons:
		var b: Button = item["button"]
		var sel: bool = item["selected"].call()
		b.set_pressed_no_signal(sel)
		(b.get_meta("label") as Label).add_theme_color_override("font_color", UiTheme.CREAM if sel else UiTheme.INK)


func _draw_none(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	var rad := minf(r.size.x, r.size.y) * 0.28
	ci.draw_arc(c, rad, 0, TAU, 32, Color(0.55, 0.42, 0.3), 3.0, true)
	ci.draw_line(c + Vector2(-rad, rad) * 0.7, c + Vector2(rad, -rad) * 0.7, Color(0.55, 0.42, 0.3), 3.0, true)
