class_name UiKit
## The game's UI look in one place: quiet and warm, like the game itself - smoked dark glass with a thin
## warm rim, cream type, one amber accent (the colour of memory / the goal in the art brief). Menus are
## text items that light amber and slide right with a thin amber bar; prompts are small dark badges with a
## cream ring that fills amber while you hold.
## Game sets UiKit.theme() on the root window; CanvasLayer roots get it set explicitly (layers stop it).
## Fonts: Fredoka (display) and Nunito (body), SIL OFL - assets/fonts/OFL_*.txt.

const CREAM := Color(1.0, 0.95, 0.86)
const IVORY := Color(0.96, 0.9, 0.76)
const INK := Color(0.07, 0.065, 0.09)
const AMBER := Color(1.0, 0.74, 0.36)        ## warm = memory / the goal (matches the art brief)
const AMBER_DEEP := Color(0.93, 0.55, 0.18)
const MUSTARD := Color(0.88, 0.67, 0.22)     ## the robot's paint
const BRICK := Color(0.85, 0.36, 0.28)       ## low battery
const TEAL := Color(0.42, 0.95, 0.9)         ## the robot's eyes
const GLASS := Color(0.06, 0.055, 0.08)
const RIM := Color(1.0, 0.8, 0.55, 0.22)

const _FREDOKA := preload("res://assets/fonts/Fredoka.ttf")
const _NUNITO := preload("res://assets/fonts/Nunito.ttf")

static var _theme: Theme
static var _fonts := {}
static var _rings := {}


## Fredoka at a weight (300-700): titles, menu items, key caps.
static func display(weight := 500, spacing := 0) -> Font:
	return _font(_FREDOKA, weight, spacing)


## Nunito at a weight (200-1000): subtitles, labels, body text.
static func body(weight := 600, spacing := 0) -> Font:
	return _font(_NUNITO, weight, spacing)


static func _font(base: FontFile, weight: int, spacing: int) -> Font:
	var key := "%s:%d:%d" % [base.resource_path, weight, spacing]
	if not _fonts.has(key):
		var f := FontVariation.new()
		f.base_font = base
		f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		f.spacing_glyph = spacing
		_fonts[key] = f
	return _fonts[key]


static func rounded(bg: Color, radius := 12, border := 0, border_col := RIM) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 10
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_col
	sb.anti_aliasing = true
	return sb


## Smoked glass with a thin warm rim and a soft shadow (pause menu, settings, the subtitle plate).
static func card(alpha := 0.82, pad := 28) -> StyleBoxFlat:
	var sb := rounded(Color(GLASS, alpha), 16, 1, RIM)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 24
	sb.shadow_offset = Vector2(0, 8)
	sb.set_content_margin_all(pad)
	return sb


## Kept for callers of the earlier look: now the same glass card.
static func paper(pad := 28, alpha := 0.82) -> StyleBoxFlat:
	return card(alpha, pad)


static func paper_theme() -> Theme:
	return theme()


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = body(600)
	t.default_font_size = 22

	# menu items: plain cream text; hover / focus = amber text, a thin amber bar on the left, a faint
	# warm wash, and the text slides right (more left margin) - no boxes, no outlines
	var normal := _item(Color(0, 0, 0, 0), 0)
	var hover := _item(Color(AMBER, 0.08), 4)
	var pressed := _item(Color(AMBER, 0.16), 4)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", hover)
	t.set_stylebox("disabled", "Button", normal)
	t.set_font("font", "Button", display(500, 1))
	t.set_font_size("font_size", "Button", 28)
	t.set_color("font_color", "Button", Color(CREAM, 0.82))
	t.set_color("font_focus_color", "Button", AMBER)
	t.set_color("font_hover_color", "Button", AMBER)
	t.set_color("font_pressed_color", "Button", AMBER)
	t.set_color("font_hover_pressed_color", "Button", AMBER)

	# the shadows dropdown: a quiet glass pill
	var opt := rounded(Color(1, 1, 1, 0.06), 10, 1, RIM)
	opt.content_margin_left = 16
	opt.content_margin_right = 16
	opt.content_margin_top = 8
	opt.content_margin_bottom = 8
	var opt_h: StyleBoxFlat = opt.duplicate()
	opt_h.border_color = Color(AMBER, 0.7)
	t.set_stylebox("normal", "OptionButton", opt)
	t.set_stylebox("hover", "OptionButton", opt_h)
	t.set_stylebox("pressed", "OptionButton", opt_h)
	t.set_stylebox("hover_pressed", "OptionButton", opt_h)
	t.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())
	t.set_font("font", "OptionButton", body(600))
	t.set_font_size("font_size", "OptionButton", 20)
	t.set_color("font_color", "OptionButton", CREAM)
	t.set_color("font_hover_color", "OptionButton", AMBER)
	t.set_color("font_focus_color", "OptionButton", CREAM)
	t.set_color("font_pressed_color", "OptionButton", AMBER)

	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.75))
	t.set_constant("outline_size", "Label", 4)

	t.set_stylebox("panel", "PanelContainer", card())
	t.set_stylebox("panel", "PopupMenu", card(0.96, 8))
	t.set_font("font", "PopupMenu", body(600))
	t.set_font_size("font_size", "PopupMenu", 20)
	t.set_color("font_color", "PopupMenu", CREAM)
	t.set_color("font_hover_color", "PopupMenu", INK)
	t.set_stylebox("hover", "PopupMenu", rounded(AMBER, 8))

	# sliders: a hairline track, an amber fill, a small cream knob
	var track := rounded(Color(1, 1, 1, 0.14), 3)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var fill := rounded(AMBER, 3)
	fill.content_margin_top = 2
	fill.content_margin_bottom = 2
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", rounded(Color(1, 0.84, 0.55), 3))
	t.set_icon("grabber", "HSlider", _dot(18, CREAM, 0))
	t.set_icon("grabber_highlight", "HSlider", _dot(22, AMBER, 0))
	_theme = t
	return t


static func _item(bg: Color, bar: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = bar
	sb.border_color = AMBER
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 18 + (14 if bar > 0 else 0)   # the text slides right on hover
	sb.content_margin_right = 18
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	return sb


## A filled circle, optionally with a ring of `ring_col` (slider knob, key caps).
static func _dot(px: int, col: Color, ring_px := 3, ring_col := CREAM) -> ImageTexture:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := (px - 1) / 2.0
	for y in px:
		for x in px:
			var d := Vector2(x - c, y - c).length()
			var a := clampf(c - d + 0.5, 0.0, 1.0)
			var inner := clampf(c - ring_px - d + 0.5, 0.0, 1.0) if ring_px > 0 else 1.0
			var pc := ring_col.lerp(col, inner)
			img.set_pixel(x, y, Color(pc.r, pc.g, pc.b, a * pc.a))
	return ImageTexture.create_from_image(img)


## The hold ring around a key cap: an amber arc from 12 o'clock, `f` of the way round (cached in steps).
static func ring(f: float, px := 128) -> ImageTexture:
	var step := clampi(roundi(f * 32.0), 0, 32)
	if _rings.has(step):
		return _rings[step]
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := (px - 1) / 2.0
	var r_out := c
	var r_in := c - px * 0.07
	var end := TAU * step / 32.0
	for y in px:
		for x in px:
			var v := Vector2(x - c, y - c)
			var d := v.length()
			var a := clampf(r_out - d + 0.5, 0.0, 1.0) * clampf(d - r_in + 0.5, 0.0, 1.0)
			if a <= 0.0:
				continue
			var ang := fposmod(atan2(v.x, -v.y), TAU)
			img.set_pixel(x, y, Color(AMBER, a) if ang <= end else Color(0, 0, 0, a * 0.35))
	_rings[step] = ImageTexture.create_from_image(img)
	return _rings[step]


## Menu items need nothing extra (the theme does the hover); kept so callers stay the same.
static func juice(_b: Control, _i := 0) -> void:
	pass


static func juice_all(_root: Node) -> void:
	pass


## A display label (titles): cream, wide-spaced, a soft dark shadow.
static func title_label(text: String, size: int, col := CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", display(600, maxi(2, size / 14)))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("shadow_offset_y", 4)
	l.add_theme_constant_override("shadow_outline_size", 10)
	return l


## A 3D key-cap prompt (billboarded, screen-sized, drawn over everything): a small dark badge with a cream
## ring and the key, the action beside it, an amber hold ring. Drive it with set_prompt_progress.
static func make_prompt(key: String, action := "") -> Node3D:
	var root := Node3D.new()
	root.name = "KeyPrompt"
	var cap := Sprite3D.new()
	cap.name = "Cap"
	cap.texture = _dot(96, Color(GLASS, 0.88), 5, CREAM)
	_billboard(cap)
	root.add_child(cap)
	var hold := Sprite3D.new()
	hold.name = "Ring"
	hold.texture = ring(0.0)
	hold.visible = false
	hold.render_priority = 1
	_billboard(hold)
	root.add_child(hold)
	var k := Label3D.new()
	k.name = "Key"
	k.text = key
	k.font = display(600)
	k.font_size = 46 if key.length() == 1 else 30
	k.modulate = CREAM
	k.outline_size = 0
	k.render_priority = 2
	_billboard(k)
	root.add_child(k)
	var a := Label3D.new()
	a.name = "Action"
	a.text = action
	a.font = body(700)
	a.font_size = 36
	a.modulate = CREAM
	a.outline_modulate = Color(0, 0, 0, 0.8)
	a.outline_size = 12
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	a.render_priority = 2
	_billboard(a)
	a.offset = Vector2(56, 0) / 0.6   # right of the cap (offset is in pixels at pixel_size)
	root.add_child(a)
	return root


static func _billboard(n: Node) -> void:
	n.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	n.no_depth_test = true
	n.fixed_size = true
	n.pixel_size = 0.0012 * 0.6
	if n is Label3D:
		n.double_sided = true


## Hold progress (0..1) on a prompt made by make_prompt; <= 0 hides the ring.
static func set_prompt_progress(p: Node3D, f: float) -> void:
	var r: Sprite3D = p.get_node("Ring")
	r.visible = f > 0.0
	if f > 0.0:
		r.texture = ring(f)


static func set_prompt_text(p: Node3D, key: String, action: String) -> void:
	(p.get_node("Key") as Label3D).text = key
	(p.get_node("Action") as Label3D).text = action
