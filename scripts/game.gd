extends Node
## Global game state (autoload "Game"): scene flow with fades, checkpoints & respawn,
## pause menu, settings (saved to user://settings.cfg), collected memories.

signal checkpoint_changed(cp: Node)
signal memory_restored(id: String)

const TITLE_SCENE := "res://scenes/title.tscn"
const GAME_SCENE := "res://scenes/room.tscn"
const SETTINGS_PATH := "user://settings.cfg"

var player: Node = null
var checkpoint: Node = null
var memories: Array[String] = []
var settings := {"master": 0.8, "music": 0.8, "sfx": 0.8, "shadows": 1, "render_scale": 1.0, "mouse_sens": 1.0}

var captions: Node  ## story captions (scripts/captions.gd); text in scripts/story_text.gd
var _fade: ColorRect
var _pause_root: Control
var _respawning := false

# ------------------------------------------------------------------ setup
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_pause_root = _build_pause_menu()
	_pause_root.visible = false
	layer.add_child(_pause_root)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	layer.add_child(_fade)
	captions = preload("res://scripts/captions.gd").new()
	add_child(captions)
	load_settings()

# ------------------------------------------------------------------ flow
func fade_out(t := 0.5) -> void:
	await create_tween().tween_property(_fade, "modulate:a", 1.0, t).finished

func fade_in(t := 0.6) -> void:
	await create_tween().tween_property(_fade, "modulate:a", 0.0, t).finished

func change_scene(path: String) -> void:
	await fade_out()
	get_tree().paused = false
	_pause_root.visible = false
	player = null
	checkpoint = null
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await fade_in()

func start_game() -> void:
	memories.clear()
	await change_scene(GAME_SCENE)   # (the opening cutscene and its lines are played by room.gd)

func to_title() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await change_scene(TITLE_SCENE)

func register_player(p: Node) -> void:
	player = p
	p.died.connect(_on_player_died)
	apply_settings()

func set_checkpoint(cp: Node) -> void:
	if checkpoint == cp:
		return
	checkpoint = cp
	checkpoint_changed.emit(cp)

func restore_memory(id: String) -> void:
	if id in memories:
		return
	memories.append(id)
	memory_restored.emit(id)

func is_respawning() -> bool:
	return _respawning

## Back to the last checkpoint. died=true -> refill to the checkpoint's respawn charge.
func respawn(died := false) -> void:
	if _respawning or player == null or checkpoint == null:
		return
	_respawning = true
	await fade_out(0.35)
	player.teleport(checkpoint.spawn_position())
	if died:
		player.revive(checkpoint.respawn_charge)
	await get_tree().create_timer(0.15).timeout
	await fade_in(0.45)
	_respawning = false

func _on_player_died() -> void:
	await get_tree().create_timer(2.0).timeout  # let the shut-down pose play
	respawn(true)

func _physics_process(_d: float) -> void:
	# falling off a chapter's route = back to its start
	if player and checkpoint and not _respawning and player.is_on_floor() \
			and player.global_position.y < checkpoint.fail_below_y:
		respawn(false)

# ------------------------------------------------------------------ pause
func _unhandled_input(event: InputEvent) -> void:
	if player == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and not get_tree().paused \
			and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_paused(p: bool) -> void:
	get_tree().paused = p
	_pause_root.visible = p
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if p else Input.MOUSE_MODE_CAPTURED

func _build_pause_menu() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(320, 0)
	box.position = Vector2(-160, -180)
	box.add_theme_constant_override("separation", 10)
	root.add_child(box)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	for b in [["Resume", func(): set_paused(false)], ["Restart checkpoint", func(): set_paused(false); respawn(false)],
			["Quit to title", func(): to_title()]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.pressed.connect(b[1])
		box.add_child(btn)
	box.add_child(make_settings_panel())
	return root

# ------------------------------------------------------------------ settings
func make_settings_panel() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	for s in [["Master volume", "master", 0.0, 1.0, 0.05], ["Music", "music", 0.0, 1.0, 0.05],
			["Sound effects", "sfx", 0.0, 1.0, 0.05], ["Render scale", "render_scale", 0.5, 1.0, 0.05],
			["Mouse sensitivity", "mouse_sens", 0.3, 2.0, 0.05]]:
		var l := Label.new()
		l.text = s[0]
		v.add_child(l)
		var sl := HSlider.new()
		sl.min_value = s[2]
		sl.max_value = s[3]
		sl.step = s[4]
		sl.value = settings[s[1]]
		var key: String = s[1]
		sl.value_changed.connect(func(val): settings[key] = val; apply_settings(); save_settings())
		v.add_child(sl)
	var opt := OptionButton.new()
	for n in ["Shadows: Low", "Shadows: Medium", "Shadows: High"]:
		opt.add_item(n)
	opt.select(settings.shadows)
	opt.item_selected.connect(func(i): settings.shadows = i; apply_settings(); save_settings())
	v.add_child(opt)
	return v

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(settings.master))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(settings.music))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(settings.sfx))
	var q: int = settings.shadows
	get_tree().root.positional_shadow_atlas_size = [1024, 2048, 4096][q]
	var f: int = [RenderingServer.SHADOW_QUALITY_HARD, RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_HIGH][q]
	RenderingServer.positional_soft_shadow_filter_set_quality(f)
	RenderingServer.directional_soft_shadow_filter_set_quality(f)
	RenderingServer.directional_shadow_atlas_set_size([2048, 4096, 8192][q], true)
	get_tree().root.scaling_3d_scale = settings.render_scale
	if player:
		player.mouse_sens = 0.0028 * settings.mouse_sens

func save_settings() -> void:
	var c := ConfigFile.new()
	for k in settings:
		c.set_value("settings", k, settings[k])
	c.save(SETTINGS_PATH)

func load_settings() -> void:
	var c := ConfigFile.new()
	if c.load(SETTINGS_PATH) == OK:
		for k in settings:
			settings[k] = c.get_value("settings", k, settings[k])
	apply_settings()
