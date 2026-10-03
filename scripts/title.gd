extends Control
## Title screen: Start / Settings / Quit. No in-game HUD per the design doc, so this is the main menu.

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.025, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(360, 0)
	box.position = Vector2(-180, -200)
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var title := Label.new()
	title.text = "LAST CHARGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.55, 1.0, 0.95))
	box.add_child(title)
	var cells := Label.new()  # five battery cells as the logo
	cells.text = "▮ ▮ ▮ ▮ ▮"
	cells.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cells.add_theme_color_override("font_color", Color(0.3, 1.0, 0.95))
	box.add_child(cells)
	var start := Button.new()
	start.text = "Start"
	start.pressed.connect(func(): Game.start_game())
	box.add_child(start)
	var settings := Game.make_settings_panel()
	settings.visible = false
	var sbtn := Button.new()
	sbtn.text = "Settings"
	sbtn.pressed.connect(func(): settings.visible = not settings.visible)
	box.add_child(sbtn)
	box.add_child(settings)
	var quit := Button.new()
	quit.text = "Quit"
	quit.pressed.connect(func(): get_tree().quit())
	box.add_child(quit)
	var hint := Label.new()
	hint.text = "Best with headphones, lights off."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.5)
	box.add_child(hint)
	start.grab_focus()
	if "--autotest" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.8).timeout
		Game.start_game()
