class_name UI
## Theme and small widget helpers. The look lives in res://assets/ui/*.png (painted 9-slice skins)
## and the two OFL fonts – swap those files to restyle the whole interface.

const INK := Color("3a2a1e")
const INK_SOFT := Color("6b5440")
const GOOD := Color("4f7a32")
const BAD := Color("a8382a")
const OCHRE_DARK := Color("8f5a24")
const CREAM := Color("f6e7c4")

static var theme: Theme
static var font_body: FontFile
static var font_bold: FontFile
static var font_display: FontFile


static func build_theme() -> Theme:
	if theme:
		return theme
	font_body = load("res://assets/fonts/Kalam-Regular.woff2")
	font_bold = load("res://assets/fonts/Kalam-Bold.woff2")
	font_display = load("res://assets/fonts/AmaticSC-Bold.woff2")
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = 16
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("panel", "PanelContainer", _tex_box("ui/panel", 30, 14))
	t.set_stylebox("panel", "Panel", _tex_box("ui/panel", 30, 14))
	t.set_type_variation("Leather", "PanelContainer")
	t.set_stylebox("panel", "Leather", _tex_box("ui/leather", 12, 8, 2))
	t.set_type_variation("Slot", "PanelContainer")
	t.set_stylebox("panel", "Slot", _tex_box("ui/slot", 14, 6))
	t.set_type_variation("Dark", "PanelContainer")
	t.set_stylebox("panel", "Dark", _tex_box("ui/panel_dark", 30, 10))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var file: String = {"normal": "ui/button", "hover": "ui/button_hover", "pressed": "ui/button_pressed", "disabled": "ui/button_disabled", "focus": "ui/button_hover"}[state]
		var sb: StyleBox = _tex_box(file, 14, 6)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		if state == "focus":
			sb = StyleBoxEmpty.new()
		t.set_stylebox(state, "Button", sb)
	t.set_font("font", "Button", font_display)
	t.set_font_size("font_size", "Button", 24)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(INK, 0.5))
	t.set_type_variation("Small", "Button")
	t.set_font_size("font_size", "Small", 19)
	t.set_type_variation("Active", "Button")
	t.set_stylebox("normal", "Active", _tex_box("ui/button_active", 14, 6))
	t.set_type_variation("Item", "Button")
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := _tex_box("ui/slot", 12, 3)
		if state == "hover" or state == "pressed":
			sb.modulate_color = Color(1.1, 1.0, 0.8)
		if state == "disabled":
			sb.modulate_color = Color(0.7, 0.7, 0.7, 0.6)
		if state == "focus":
			t.set_stylebox(state, "Item", StyleBoxEmpty.new())
			continue
		t.set_stylebox(state, "Item", sb)
	t.set_type_variation("Title", "Label")
	t.set_font("font", "Title", font_display)
	t.set_font_size("font_size", "Title", 40)
	t.set_type_variation("Heading", "Label")
	t.set_font("font", "Heading", font_display)
	t.set_font_size("font_size", "Heading", 27)
	t.set_type_variation("Muted", "Label")
	t.set_color("font_color", "Muted", INK_SOFT)
	t.set_font_size("font_size", "Muted", 14)
	t.set_type_variation("LeatherLabel", "Label")
	t.set_color("font_color", "LeatherLabel", CREAM)
	t.set_font_size("font_size", "LeatherLabel", 18)
	t.set_color("font_color", "CheckBox", INK)
	t.set_color("font_hover_color", "CheckBox", INK)
	t.set_color("font_pressed_color", "CheckBox", INK)
	t.set_color("font_color", "OptionButton", INK)
	t.set_font("font", "OptionButton", font_body)
	t.set_font_size("font_size", "OptionButton", 16)
	t.set_color("font_color", "LineEdit", INK)
	var le := StyleBoxFlat.new()
	le.bg_color = Color("f8efd8")
	le.border_color = INK
	le.set_border_width_all(2)
	le.set_corner_radius_all(8)
	le.content_margin_left = 8
	le.content_margin_right = 8
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("e6d5b0")
	bar_bg.border_color = INK
	bar_bg.set_border_width_all(2)
	bar_bg.set_corner_radius_all(6)
	var bar_fg := StyleBoxFlat.new()
	bar_fg.bg_color = Color("7f9a4a")
	bar_fg.set_corner_radius_all(5)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fg)
	t.set_type_variation("BadBar", "ProgressBar")
	var bad_fg := bar_fg.duplicate()
	bad_fg.bg_color = Color("c0603a")
	t.set_stylebox("fill", "BadBar", bad_fg)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color("8f5a24")
	grab.set_corner_radius_all(6)
	grab.content_margin_top = 4
	grab.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", bar_bg)
	t.set_stylebox("grabber_area", "HSlider", grab)
	t.set_stylebox("grabber_area_highlight", "HSlider", grab)
	var tip := _tex_box("ui/panel", 30, 12)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", INK)
	theme = t
	return t


static func _tex_box(id: String, margin: int, content: int, content_v := -1) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = Art.tex(id)
	sb.set_texture_margin_all(margin)
	sb.set_content_margin_all(content)
	if content_v >= 0:
		sb.content_margin_top = content_v
		sb.content_margin_bottom = content_v
	return sb


# ---------------------------------------------------------------- widgets

static func label(text: String, variation := "", wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, cb: Callable, variation := "") -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


static func icon(tex: Texture2D, px := 28) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	return r


static func good_icon(id: String, px := 28) -> TextureRect:
	var r := icon(Art.good_icon(id), px)
	r.tooltip_text = Content.tx(Content.GOOD[id].name) if Content.GOOD.has(id) else id
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


static func hbox(children: Array, sep := 6) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.alignment = BoxContainer.ALIGNMENT_BEGIN
	for c in children:
		if c != null:
			b.add_child(c)
	return b


static func vbox(children: Array, sep := 4) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	for c in children:
		if c != null:
			b.add_child(c)
	return b


static func bar(value: float, warn := false, width := 90) -> ProgressBar:
	var p := ProgressBar.new()
	p.min_value = 0
	p.max_value = 100
	p.value = value * 100.0
	p.show_percentage = false
	p.custom_minimum_size = Vector2(width, 12)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if warn:
		p.theme_type_variation = "BadBar"
	return p


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func row(left: Control, right: Control) -> HBoxContainer:
	return hbox([left, spacer(), right])


static func panel(children: Array, variation := "") -> PanelContainer:
	var p := PanelContainer.new()
	if variation != "":
		p.theme_type_variation = variation
	p.add_child(vbox(children))
	return p


static func clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()
