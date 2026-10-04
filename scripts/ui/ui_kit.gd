class_name UiKit
## The game's UI look in one place: old toys and cut paper, in the art brief's worn paint colours
## (mustard, brick red, faded navy, aged ivory) with a brown-black ink line. Buttons are slightly crooked
## paper tags with a hard sticker shadow that wobble on hover and take a different paint colour each;
## cards are tilted ivory paper; the logo is wobbly toy-block letters; prompts are tin badges.
## Game sets UiKit.theme() on the root window, so every Control (title, pause, settings, captions)
## picks it up; scripts only call the helpers below for the special bits.
## Fonts: Fredoka (display) and Nunito (body), SIL OFL - assets/fonts/OFL_*.txt.

const CREAM := Color(1.0, 0.96, 0.88)
const IVORY := Color(0.96, 0.9, 0.76)       ## aged paper
const INK := Color(0.17, 0.11, 0.09)        ## brown-black pencil / ink line
const MUSTARD := Color(0.88, 0.67, 0.22)    ## the robot's paint
const BRICK := Color(0.76, 0.35, 0.26)
const NAVY := Color(0.24, 0.32, 0.5)
const OLIVE := Color(0.52, 0.56, 0.32)
const AMBER := Color(1.0, 0.74, 0.32)       ## warm = memory / the goal (matches the art brief)
const AMBER_DEEP := Color(0.93, 0.55, 0.18)
const TEAL := Color(0.42, 0.95, 0.9)        ## the robot's eyes
const CARD := Color(0.08, 0.075, 0.11, 0.9)
const PAINTS := [MUSTARD, BRICK, NAVY, OLIVE]   ## hover colours, one per button in a menu

const _FREDOKA := preload("res://assets/fonts/Fredoka.ttf")
const _NUNITO := preload("res://assets/fonts/Nunito.ttf")

static var _theme: Theme
static var _fonts := {}
static var _rings := {}


## Fredoka at a weight (300-700): titles, buttons, key caps.
static func display(weight := 600) -> Font:
	return _font(_FREDOKA, weight)


## Nunito at a weight (200-1000): subtitles, labels, body text.
static func body(weight := 700) -> Font:
	return _font(_NUNITO, weight)


static func _font(base: FontFile, weight: int) -> Font:
	var key := "%s:%d" % [base.resource_path, weight]
	if not _fonts.has(key):
		var f := FontVariation.new()
		f.base_font = base
		f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		_fonts[key] = f
	return _fonts[key]


static func rounded(bg: Color, radius := 18, border := 0, border_col := INK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 10
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_col
	sb.anti_aliasing = true
	return sb


## A dark rounded card with a soft drop shadow (kept for anything that must stay dark).
static func card(alpha := 0.9, pad := 28) -> StyleBoxFlat:
	var sb := rounded(Color(CARD, alpha), 26)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 6)
	sb.set_content_margin_all(pad)
	return sb


## A sheet of aged paper: ivory, an ink outline, uneven corners, a hard offset shadow like a cut-out.
static func paper(pad := 28, alpha := 1.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(IVORY, alpha)
	sb.set_border_width_all(4)
	sb.border_color = INK
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 22
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 18
	sb.corner_detail = 6
	sb.shadow_color = Color(INK, 0.6)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(7, 8)
	sb.set_content_margin_all(pad)
	return sb


## Theme for things sitting ON paper: ink text, no outline.
static func paper_theme() -> Theme:
	var t: Theme = theme().duplicate()
	t.set_color("font_color", "Label", INK)
	t.set_constant("outline_size", "Label", 0)
	return t


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = body(700)
	t.default_font_size = 22

	# pill buttons: cream with a thick ink outline; amber on hover / focus; pressed sinks a little
	var normal := _pill(IVORY)
	var hover := _pill(MUSTARD)
	var pressed := _pill(MUSTARD.darkened(0.15))
	pressed.content_margin_top += 3
	pressed.content_margin_bottom -= 3
	var focus := rounded(Color(0, 0, 0, 0), 26, 4, MUSTARD)
	focus.expand_margin_left = 6
	focus.expand_margin_right = 6
	focus.expand_margin_top = 6
	focus.expand_margin_bottom = 6
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, normal)
		t.set_stylebox("hover", type, hover)
		t.set_stylebox("pressed", type, pressed)
		t.set_stylebox("hover_pressed", type, pressed)
		t.set_stylebox("focus", type, focus)
		t.set_stylebox("disabled", type, _pill(Color(CREAM, 0.4)))
		t.set_font("font", type, display(600))
		t.set_font_size("font_size", type, 26)
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			t.set_color(c, type, INK)
	t.set_constant("arrow_margin", "OptionButton", 18)

	# labels: cream with a soft ink outline so they read over the 3D scene
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_outline_color", "Label", Color(INK, 0.9))
	t.set_constant("outline_size", "Label", 6)

	t.set_stylebox("panel", "PanelContainer", paper())
	t.set_stylebox("panel", "PopupMenu", paper(10))
	t.set_font("font", "PopupMenu", display(500))
	t.set_font_size("font_size", "PopupMenu", 22)
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", INK)
	t.set_stylebox("hover", "PopupMenu", rounded(MUSTARD, 10))

	# sliders: a thick rounded track that fills amber, a round cream grabber with an ink ring
	var track := rounded(Color(INK, 0.18), 8, 3, INK)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	var fill := rounded(BRICK, 8, 3, INK)
	fill.content_margin_top = 6
	fill.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", rounded(BRICK.lightened(0.15), 8, 3, INK))
	t.set_icon("grabber", "HSlider", _dot(28, MUSTARD, 4))
	t.set_icon("grabber_highlight", "HSlider", _dot(32, MUSTARD, 4))
	_theme = t
	return t


static func _pill(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()   # a cut paper tag: uneven corners, a little skew, a hard sticker shadow
	sb.bg_color = bg
	sb.set_border_width_all(4)
	sb.border_color = INK
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 26
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 24
	sb.corner_detail = 6
	sb.skew = Vector2(0.05, 0)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(INK, 0.7)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(5, 6)
	return sb


## A filled circle with an ink ring (slider grabber, key caps).
static func _dot(px: int, col: Color, ring := 3) -> ImageTexture:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := (px - 1) / 2.0
	for y in px:
		for x in px:
			var d := Vector2(x - c, y - c).length()
			var a := clampf(c - d + 0.5, 0.0, 1.0)
			var inner := clampf(c - ring - d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(INK.lerp(col, inner), a))
	return ImageTexture.create_from_image(img)


## The hold ring around a key cap: an amber arc from 12 o'clock, `f` of the way round (cached in steps).
static func ring(f: float, px := 128) -> ImageTexture:
	var step := clampi(roundi(f * 32.0), 0, 32)
	if _rings.has(step):
		return _rings[step]
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := (px - 1) / 2.0
	var r_out := c
	var r_in := c - px * 0.09
	var end := TAU * step / 32.0
	for y in px:
		for x in px:
			var v := Vector2(x - c, y - c)
			var d := v.length()
			var a := clampf(r_out - d + 0.5, 0.0, 1.0) * clampf(d - r_in + 0.5, 0.0, 1.0)
			if a <= 0.0:
				continue
			var ang := fposmod(atan2(v.x, -v.y), TAU)
			img.set_pixel(x, y, Color(AMBER, a) if ang <= end else Color(0, 0, 0, a * 0.45))
	_rings[step] = ImageTexture.create_from_image(img)
	return _rings[step]


## Hover / focus juice for a button: it rests a little crooked, and on hover grows, wobbles the other way
## and takes paint colour `i` (pivot = its centre).
static func juice(b: Control, i := 0) -> void:
	var centre := func(): b.pivot_offset = b.size / 2.0
	b.resized.connect(centre)
	centre.call()
	var rest: float = [-1.4, 1.1, -0.6, 1.6][i % 4]
	b.rotation_degrees = rest
	var paint: Color = PAINTS[i % PAINTS.size()]
	var hov := _pill(paint)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", _pill(paint.darkened(0.15)))
	var txt := INK if paint.get_luminance() > 0.45 else IVORY
	b.add_theme_color_override("font_hover_color", txt)
	b.add_theme_color_override("font_pressed_color", txt)
	var grow := func(on: bool):
		if on:
			b.add_theme_stylebox_override("normal", hov)
			b.add_theme_color_override("font_color", txt)
			b.add_theme_color_override("font_focus_color", txt)
		else:
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_color_override("font_color")
			b.remove_theme_color_override("font_focus_color")
		b.set_meta("rot", -rest * 1.6 if on else rest)
		b.set_meta("scl", Vector2.ONE * (1.08 if on else 1.0))
		var tw := b.create_tween().set_parallel().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", b.get_meta("scl"), 0.45)
		tw.tween_property(b, "rotation_degrees", b.get_meta("rot"), 0.45)
	# containers reset rotation and scale whenever they re-sort: put the tilt back afterwards
	b.set_meta("rot", rest)
	b.set_meta("scl", Vector2.ONE)
	var parent := b.get_parent()
	if parent is Container:
		parent.sort_children.connect(func():
			b.rotation_degrees = b.get_meta("rot")
			b.scale = b.get_meta("scl"))
	b.mouse_entered.connect(func(): grow.call(true))
	b.mouse_exited.connect(func(): if not b.has_focus(): grow.call(false))
	b.focus_entered.connect(func(): grow.call(true))
	b.focus_exited.connect(func(): grow.call(false))


## Juice every Button under a node (call after building a menu).
static func juice_all(root: Node) -> void:
	var i := 0
	for b in root.find_children("*", "BaseButton", true, false):
		if b is Button:
			juice(b, i)
			i += 1


## A big display label (titles).
static func title_label(text: String, size: int, col := CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", display(700))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", maxi(8, size / 6))
	l.add_theme_color_override("font_outline_color", INK)
	return l


## The logo as toy blocks: one label per letter, each its own paint colour and tilt; bob() them per frame.
static func block_letters(text: String, size: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", -2)
	var cols := [MUSTARD, BRICK, TEAL, NAVY.lightened(0.25), OLIVE.lightened(0.15)]
	var k := 0
	for ch in text:
		if ch == " ":
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(size * 0.35, 0)
			row.add_child(gap)
			continue
		var l := title_label(ch, size, cols[k % cols.size()])
		l.add_theme_constant_override("outline_size", maxi(10, size / 5))
		l.set_meta("phase", k * 0.7)
		l.set_meta("tilt", [-6.0, 4.0, -2.0, 5.0, -4.0, 3.0][k % 6])
		row.add_child(l)
		k += 1
	return row


static func bob_letters(row: Control, t: float) -> void:
	for l in row.get_children():
		if l is Label:
			l.pivot_offset = l.size / 2.0
			l.rotation_degrees = l.get_meta("tilt") + sin(t * 1.8 + l.get_meta("phase")) * 3.0
			l.scale = Vector2.ONE * (1.0 + 0.03 * sin(t * 2.3 + l.get_meta("phase")))


## A 3D key-cap prompt (billboarded, screen-sized, drawn over everything): a round cream cap with the
## key, the action beside it, and an amber hold ring. Returns the root; drive it with set_prompt_progress.
static func make_prompt(key: String, action := "") -> Node3D:
	var root := Node3D.new()
	root.name = "KeyPrompt"
	var cap := Sprite3D.new()
	cap.name = "Cap"
	cap.texture = _dot(96, MUSTARD, 8)
	_billboard(cap)
	root.add_child(cap)
	var hold := Sprite3D.new()
	hold.name = "Ring"
	hold.texture = ring(0.0)
	hold.visible = false
	hold.render_priority = 1
	_billboard(hold)
	hold.pixel_size = cap.pixel_size * 1.0
	root.add_child(hold)
	var k := Label3D.new()
	k.name = "Key"
	k.text = key
	k.font = display(700)
	k.font_size = 52 if key.length() == 1 else 34
	k.modulate = INK
	k.outline_size = 0
	k.render_priority = 2
	_billboard(k)
	root.add_child(k)
	var a := Label3D.new()
	a.name = "Action"
	a.text = action
	a.font = display(600)
	a.font_size = 40
	a.modulate = CREAM
	a.outline_modulate = INK
	a.outline_size = 14
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
