extends Control
## Title screen: Start / Settings / Quit. No in-game HUD per the design doc, so this is the main menu.
## Over a still of the game's first shot (the moonlit nightstand, the old man asleep - assets/ui/title_bg.jpg,
## rendered by tools/tests/capture_title_bg.gd) drifting slowly closer; the logo and a column of quiet text
## items on the left, where the room falls into shadow. Settings opens as a glass card. Look: ui_kit.gd.

const BG := preload("res://assets/ui/title_bg.jpg")

var _t := 0.0
var _bg: TextureRect
var _cells: Array[Panel] = []
var _settings_card: Control


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var base := ColorRect.new()
	base.color = Color.BLACK
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	_bg = TextureRect.new()
	_bg.texture = BG
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	# shade the left side for the menu, and a soft vignette all round
	add_child(_shade(Vector2(0, 0.5), Vector2(0.62, 0.5), Color(0, 0, 0, 0.82), Color(0, 0, 0, 0.0), false))
	add_child(_shade(Vector2(0.5, 0.5), Vector2(1.05, 0.5), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.6), true))

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	col.offset_left = 120
	col.offset_right = 760
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	var logo := UiKit.title_label("LAST CHARGE", 96)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(logo)
	col.add_child(_battery())
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 46)
	col.add_child(gap)

	var items := VBoxContainer.new()
	items.add_theme_constant_override("separation", 4)
	items.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	items.custom_minimum_size = Vector2(320, 0)
	col.add_child(items)
	var start := _button("Start", func(): Game.start_game())
	items.add_child(start)
	items.add_child(_button("Settings", func(): _show_settings(true)))
	items.add_child(_button("Quit", func(): get_tree().quit()))

	var hint := Label.new()
	hint.text = "Best with headphones, lights off."
	hint.add_theme_font_size_override("font_size", 17)
	hint.modulate = Color(1, 1, 1, 0.5)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 120
	hint.offset_top = -64
	add_child(hint)

	_settings_card = _build_settings()
	add_child(_settings_card)

	# entrance: the room fades up from black, then the logo and the items
	_bg.modulate.a = 0.0
	col.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_bg, "modulate:a", 1.0, 1.4)
	tw.tween_property(col, "modulate:a", 1.0, 0.8)
	start.grab_focus()
	if "--autotest" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.8).timeout
		Game.start_game()


func _process(d: float) -> void:
	_t += d
	# the room drifts slowly closer, like a held breath
	var z := 1.0 + 0.045 * (0.5 - 0.5 * cos(_t * TAU / 40.0))
	_bg.pivot_offset = _bg.size * Vector2(0.62, 0.55)
	_bg.scale = Vector2.ONE * z
	# the battery: cells go out one by one, the last one flickers red, then it all comes back
	var cycle := fmod(_t, 8.0)
	var lit := 5 - int(clampf(cycle / 1.3, 0.0, 5.0))
	for i in _cells.size():
		var on := i < lit
		if lit == 1 and i == 0:
			on = sin(_t * 20.0) > -0.3
		var c := (UiKit.CREAM if lit > 1 else UiKit.BRICK) if on else Color(1, 1, 1, 0.08)
		(_cells[i].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = c


func _shade(from: Vector2, to: Vector2, a: Color, b: Color, radial: bool) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL if radial else GradientTexture2D.FILL_LINEAR
	gt.fill_from = from
	gt.fill_to = to
	var r := TextureRect.new()
	r.texture = gt
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## A slim battery outline under the logo whose cells keep running down.
func _battery() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var shell := PanelContainer.new()
	var sb := UiKit.rounded(Color(0, 0, 0, 0), 6, 2, Color(UiKit.CREAM, 0.7))
	sb.set_content_margin_all(5)
	shell.add_theme_stylebox_override("panel", sb)
	row.add_child(shell)
	var cells := HBoxContainer.new()
	cells.add_theme_constant_override("separation", 4)
	shell.add_child(cells)
	for i in 5:
		var c := Panel.new()
		c.custom_minimum_size = Vector2(22, 12)
		c.add_theme_stylebox_override("panel", UiKit.rounded(UiKit.CREAM, 2))
		cells.add_child(c)
		_cells.append(c)
	var nub := Panel.new()
	nub.custom_minimum_size = Vector2(4, 10)
	nub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nub.add_theme_stylebox_override("panel", UiKit.rounded(Color(UiKit.CREAM, 0.7), 1))
	row.add_child(nub)
	return row


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(on_press)
	b.mouse_entered.connect(b.grab_focus)   # mouse and keyboard share one highlight
	return b


func _build_settings() -> Control:
	var veil := ColorRect.new()   # dims the menu behind the card; click outside to close
	veil.color = Color(0, 0, 0, 0.5)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.visible = false
	veil.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _show_settings(false))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	veil.add_child(center)
	var cardp := PanelContainer.new()
	cardp.add_theme_stylebox_override("panel", UiKit.card(0.9, 40))
	center.add_child(cardp)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	cardp.add_child(v)
	v.add_child(Game.make_settings_panel())
	var close := _button("Back", func(): _show_settings(false))
	close.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(close)
	veil.set_meta("close", close)
	return veil


func _show_settings(on: bool) -> void:
	_settings_card.visible = on
	if on:
		_settings_card.modulate.a = 0.0
		create_tween().tween_property(_settings_card, "modulate:a", 1.0, 0.2)
		(_settings_card.get_meta("close") as Button).grab_focus()
