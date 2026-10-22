class_name UiTheme
extends RefCounted
## Victorian dressmaker's-workshop theme, built in code so it is easy to tweak.

const PARCHMENT := Color("f4ead8")
const PARCHMENT_DARK := Color("e6d6b8")
const WALNUT := Color("5a3a22")
const WALNUT_DARK := Color("3b2416")
const BURGUNDY := Color("7b2d3a")
const GOLD := Color("c9a24a")
const INK := Color("3b2618")
const CREAM := Color("fff8ea")

static var _font_regular: Font
static var _font_bold: Font
static var _font_italic: Font


static func font(kind: String = "regular") -> Font:
	if _font_regular == null:
		_font_regular = load("res://assets/fonts/LiberationSerif-Regular.ttf")
		_font_bold = load("res://assets/fonts/LiberationSerif-Bold.ttf")
		_font_italic = load("res://assets/fonts/LiberationSerif-Italic.ttf")
	match kind:
		"bold":
			return _font_bold
		"italic":
			return _font_italic
	return _font_regular


static func box(bg: Color, border: Color = Color.TRANSPARENT, width: int = 0, radius: int = 6, margin: float = 8.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	s.anti_aliasing = true
	return s


static func panel_box() -> StyleBoxFlat:
	var s := box(PARCHMENT, WALNUT, 3, 10, 12)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	return s


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 17
	t.set_color("font_color", "Label", INK)
	t.set_font("font", "Label", font())

	t.set_stylebox("panel", "PanelContainer", panel_box())
	t.set_stylebox("panel", "Panel", panel_box())
	t.set_stylebox("panel", "PopupPanel", panel_box())
	t.set_stylebox("panel", "PopupMenu", box(CREAM, WALNUT, 2, 6, 6))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", CREAM)
	t.set_stylebox("hover", "PopupMenu", box(BURGUNDY, Color.TRANSPARENT, 0, 4, 4))

	var normal := box(Color("efe2c8"), Color("8a6440"), 1, 6, 10)
	var hover := box(Color("f8efdd"), GOLD, 2, 6, 10)
	var pressed := box(BURGUNDY, Color("4a1820"), 1, 6, 10)
	var disabled := box(Color("e4dccb"), Color("b8a88c"), 1, 6, 10)
	var focus := box(Color.TRANSPARENT, GOLD, 2, 6, 10)
	for cls in ["Button", "OptionButton", "MenuButton", "CheckButton", "ColorPickerButton"]:
		t.set_stylebox("normal", cls, normal)
		t.set_stylebox("hover", cls, hover)
		t.set_stylebox("pressed", cls, pressed)
		t.set_stylebox("hover_pressed", cls, pressed)
		t.set_stylebox("disabled", cls, disabled)
		t.set_stylebox("focus", cls, focus)
		t.set_color("font_color", cls, INK)
		t.set_color("font_hover_color", cls, INK)
		t.set_color("font_pressed_color", cls, CREAM)
		t.set_color("font_hover_pressed_color", cls, CREAM)
		t.set_color("font_focus_color", cls, INK)
		t.set_color("font_disabled_color", cls, Color("9a8a70"))
	t.set_stylebox("normal", "CheckBox", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("hover", "CheckBox", box(Color(1, 1, 1, 0.3), Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("pressed", "CheckBox", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("hover_pressed", "CheckBox", box(Color(1, 1, 1, 0.3), Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(state, "CheckBox", INK)

	var field := box(CREAM, Color("8a6440"), 1, 5, 8)
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", box(CREAM, GOLD, 2, 5, 8))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("caret_color", "LineEdit", BURGUNDY)
	t.set_stylebox("panel", "ItemList", field)
	t.set_color("font_color", "ItemList", INK)
	t.set_color("font_selected_color", "ItemList", CREAM)
	t.set_stylebox("selected", "ItemList", box(BURGUNDY, Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("selected_focus", "ItemList", box(BURGUNDY, GOLD, 1, 4, 4))
	t.set_stylebox("hovered", "ItemList", box(Color(0.79, 0.64, 0.29, 0.25), Color.TRANSPARENT, 0, 4, 4))

	var slider_track := box(Color("c9b48f"), Color.TRANSPARENT, 0, 3, 0)
	slider_track.content_margin_top = 3
	slider_track.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", slider_track)
	var fill := box(BURGUNDY, Color.TRANSPARENT, 0, 3, 0)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _knob(GOLD, WALNUT, 9))
	t.set_icon("grabber_highlight", "HSlider", _knob(Color("e6c56b"), WALNUT, 10))

	t.set_stylebox("panel", "TooltipPanel", box(WALNUT_DARK, GOLD, 1, 4, 8))
	t.set_color("font_color", "TooltipLabel", CREAM)

	t.set_stylebox("separator", "HSeparator", box(GOLD, Color.TRANSPARENT, 0, 0, 0))
	t.set_constant("separation", "HSeparator", 10)
	t.set_stylebox("scroll", "VScrollBar", box(Color(0, 0, 0, 0.06), Color.TRANSPARENT, 0, 4, 2))
	t.set_stylebox("grabber", "VScrollBar", box(Color("b89b6c"), Color.TRANSPARENT, 0, 4, 2))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(GOLD, Color.TRANSPARENT, 0, 4, 2))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(BURGUNDY, Color.TRANSPARENT, 0, 4, 2))

	t.set_stylebox("panel", "Window", panel_box())
	t.set_stylebox("embedded_border", "Window", panel_box())
	t.set_stylebox("embedded_unfocused_border", "Window", panel_box())
	t.set_color("title_color", "Window", INK)
	t.set_font("title_font", "Window", font("bold"))
	t.set_stylebox("panel", "AcceptDialog", box(PARCHMENT, Color.TRANSPARENT, 0, 8, 12))
	return t


static func _knob(fill: Color, edge: Color, r: int) -> ImageTexture:
	var size := r * 2 + 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) * 0.5
	for y in range(size):
		for x in range(size):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= r:
				var col := fill if d < r - 1.5 else edge
				col.a = clampf(r - d + 0.5, 0.0, 1.0)
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func header(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("bold"))
	l.add_theme_font_size_override("font_size", 19)
	l.add_theme_color_override("font_color", BURGUNDY)
	return l


static func note(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font("italic"))
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color("6b5440"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
