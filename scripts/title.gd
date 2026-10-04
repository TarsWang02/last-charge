extends Control
## Title screen: Start / Settings / Quit. No in-game HUD per the design doc, so this is the main menu.
## Look (scripts/ui/ui_kit.gd): a night sky, the logo bobbing, five battery cells that keep draining and
## refilling, chunky pill buttons that bounce in; Settings opens as a card over the menu.

var _stars := []
var _t := 0.0
var _cells: Array[Panel] = []
var _settings_card: Control


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# night sky: a warm glow low on the horizon fading up into deep blue, a few twinkling stars
	var bg := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.2, 0.13, 0.17))
	grad.set_color(1, Color(0.015, 0.02, 0.045))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 1.15)
	gt.fill_to = Vector2(0.5, -0.2)
	bg.texture = gt
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 90:
		_stars.append([Vector2(rng.randf(), rng.randf() * 0.75), rng.randf_range(0.8, 2.2), rng.randf() * TAU])
	var sky := Control.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.draw.connect(func():
		for s in _stars:
			var a: float = 0.35 + 0.35 * sin(_t * 1.3 + s[2])
			sky.draw_circle(s[0] * sky.size, s[1], Color(1, 0.95, 0.85, a)))
	add_child(sky)
	set_meta("sky", sky)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	var logo := UiKit.block_letters("LAST CHARGE", 112)
	box.add_child(logo)
	box.add_child(_battery())
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 26)
	box.add_child(gap)

	# the menu is a paper card (the ink-outlined tags vanish against the night sky on their own)
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", UiKit.paper(30))
	sheet.theme = UiKit.paper_theme()
	sheet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(sheet)
	box.sort_children.connect(func():
		sheet.pivot_offset = sheet.size / 2.0
		sheet.rotation_degrees = 1.2)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	buttons.custom_minimum_size = Vector2(380, 0)
	sheet.add_child(buttons)
	var start := _button("Start", func(): Game.start_game())
	start.add_theme_font_size_override("font_size", 32)
	buttons.add_child(start)
	buttons.add_child(_button("Settings", func(): _show_settings(true)))
	buttons.add_child(_button("Quit", func(): get_tree().quit()))

	var hint := Label.new()
	hint.text = "Best with headphones, lights off."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.modulate = Color(1, 1, 1, 0.55)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.offset_top = -56
	add_child(hint)

	_settings_card = _build_settings()
	add_child(_settings_card)
	UiKit.juice_all(self)

	# entrance: the logo drops in with a bounce, the buttons pop up one after another
	logo.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(logo, "modulate:a", 1.0, 0.5)
	for i in buttons.get_child_count():
		var b: Control = buttons.get_child(i)
		b.modulate.a = 0.0
		tw.tween_property(b, "modulate:a", 1.0, 0.35).set_delay(0.35 + i * 0.1)
	set_meta("logo", logo)
	start.grab_focus()
	if "--autotest" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.8).timeout
		Game.start_game()


func _process(d: float) -> void:
	_t += d
	(get_meta("sky") as Control).queue_redraw()
	UiKit.bob_letters(get_meta("logo"), _t)   # each toy-block letter wobbles on its own
	# the battery: cells go out right to left, flicker on the last one, then all refill
	var cycle := fmod(_t, 7.0)
	var lit := 5 - int(clampf(cycle / 1.1, 0.0, 5.0))
	for i in _cells.size():
		var on := i < lit
		if i == lit - 1 and lit == 1:
			on = sin(_t * 22.0) > -0.2   # the last cell flickers
		var col := (UiKit.MUSTARD if lit > 1 else UiKit.BRICK) if on else Color(UiKit.INK, 0.5)
		(_cells[i].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = col


func _battery() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var shell := PanelContainer.new()   # the battery body with an ink outline and a nub on the right
	var sb := UiKit.paper(10)
	sb.border_width_left = 5
	sb.set_content_margin_all(10)
	shell.add_theme_stylebox_override("panel", sb)
	row.add_child(shell)
	var cells := HBoxContainer.new()
	cells.add_theme_constant_override("separation", 8)
	shell.add_child(cells)
	for i in 5:
		var c := Panel.new()
		c.custom_minimum_size = Vector2(46, 30)
		c.add_theme_stylebox_override("panel", UiKit.rounded(UiKit.MUSTARD, 6, 3, UiKit.INK))
		cells.add_child(c)
		_cells.append(c)
	var nub := Panel.new()
	nub.custom_minimum_size = Vector2(10, 22)
	nub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nub.add_theme_stylebox_override("panel", UiKit.rounded(UiKit.IVORY, 4, 3, UiKit.INK))
	row.add_child(nub)
	return row


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on_press)
	return b


func _build_settings() -> Control:
	var veil := ColorRect.new()   # dims the menu behind the card; click outside to close
	veil.color = Color(0, 0, 0, 0.55)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.visible = false
	veil.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _show_settings(false))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	veil.add_child(center)
	var cardp := PanelContainer.new()
	cardp.add_theme_stylebox_override("panel", UiKit.paper(40))
	cardp.theme = UiKit.paper_theme()
	cardp.rotation_degrees = -1.2
	cardp.resized.connect(func(): cardp.pivot_offset = cardp.size / 2.0)
	center.add_child(cardp)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	cardp.add_child(v)
	v.add_child(Game.make_settings_panel())
	var close := _button("Back", func(): _show_settings(false))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.custom_minimum_size = Vector2(220, 0)
	v.add_child(close)
	veil.set_meta("close", close)
	return veil


func _show_settings(on: bool) -> void:
	_settings_card.visible = on
	if on:
		_settings_card.modulate.a = 0.0
		create_tween().tween_property(_settings_card, "modulate:a", 1.0, 0.18)
		(_settings_card.get_meta("close") as Button).grab_focus()
