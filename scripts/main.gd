extends Node3D
## Scene glue: audio, prop slot, and a command-line self test:
##   godot --path . -- --autotest --shots=C:/path/to/dir [--novsync]

@export var prop_path := "res://assets/models/prop.glb" ## Tripo model auto-loaded if present
@export var prop_target_height := 1.2
@export var wall_texture_path := "res://assets/textures/tex_wall_tile.png" ## applied to walls if present

@onready var player = $Player
@onready var stalker = $StalkerPath/Stalker
@onready var hud = $HUD
@onready var ambience: AudioStreamPlayer = $Ambience
@onready var hum: AudioStreamPlayer3D = $StalkerPath/Stalker/Hum
@onready var prop_slot: Node3D = $PropSlot

func _ready() -> void:
	_setup_audio(ambience, _first_audio("amb_", "res://assets/audio/ambience.ogg"))
	if ResourceLoader.exists(wall_texture_path):
		($Room/WallN.material as StandardMaterial3D).albedo_texture = load(wall_texture_path)
		print("[main] wall texture: ", wall_texture_path)
	_setup_audio(hum, "res://assets/audio/hum.ogg")
	if ResourceLoader.exists(prop_path):
		for c in prop_slot.get_children():
			c.free()
		var p: Node3D = load(prop_path).instantiate()
		prop_slot.add_child(p)
		ModelUtil.fit(p, prop_target_height)
		print("[main] prop loaded: ", prop_path)
	print("[main] renderer=%s adapter=%s" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name()])
	if "--autotest" in OS.get_cmdline_user_args():
		_autotest()

## First res://assets/audio/<prefix>*.ogg, else fallback (placeholder).
func _first_audio(prefix: String, fallback: String) -> String:
	for f in ResourceLoader.list_directory("res://assets/audio"):
		if f.begins_with(prefix) and f.ends_with(".ogg"):
			return "res://assets/audio/" + f
	return fallback

func _setup_audio(p: Node, path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[main] missing audio " + path)
		return
	var s: AudioStream = load(path)
	if s is AudioStreamOggVorbis:
		s.loop = true
	p.stream = s
	p.play()

# ---------------------------------------------------------------- self test
func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _key(k: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.keycode = k
	e.pressed = down
	Input.parse_input_event(e)

func _tap(k: Key) -> void:
	_key(k, true)
	await get_tree().process_frame
	_key(k, false)
	await get_tree().process_frame

func _shot(dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(name))

func _autotest() -> void:
	var dir := OS.get_user_data_dir()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--shots="):
			dir = a.substr(8)
	if "--novsync" in args:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var tag := RenderingServer.get_current_rendering_method()
	var r := {"renderer": tag, "adapter": RenderingServer.get_video_adapter_name(),
		"stalker_anims": stalker.anim_player.get_animation_list() if stalker.anim_player else []}
	await _wait(1.5)
	await _shot(dir, tag + "_light_on.png")

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	r["mouse_captured"] = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var start_xf: Transform3D = player.global_transform
	player.global_position = Vector3(-4.8, 0.9, 3.0)
	player.rotation.y = PI / 2  # face the west wall
	player.head.rotation.x = -0.1
	await _wait(0.5)
	await _shot(dir, tag + "_wall_closeup.png")
	player.global_transform = start_xf
	player.head.rotation.x = 0.0
	await _wait(0.3)
	var p0: Vector3 = player.global_position
	_key(KEY_W, true)
	await _wait(1.0)
	_key(KEY_W, false)
	r["walk_1s_m"] = snappedf(player.global_position.distance_to(p0), 0.01)
	var ry: float = player.rotation.y
	var mm := InputEventMouseMotion.new()
	mm.relative = Vector2(200, 0)
	Input.parse_input_event(mm)
	await _wait(0.1)
	r["mouse_look_rad"] = snappedf(absf(player.rotation.y - ry), 0.01)

	var b0: float = player.battery
	await _wait(2.0)
	r["battery_drain_2s"] = snappedf(b0 - player.battery, 0.01)
	await _tap(KEY_F)
	r["F_turns_off"] = not player.flashlight.visible
	await _shot(dir, tag + "_light_off.png")
	await _tap(KEY_F)
	r["F_turns_on"] = player.flashlight.visible
	await _tap(KEY_ESCAPE)
	r["esc_releases_mouse"] = Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
	r["settings_visible_after_esc"] = hud.settings.visible
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	stalker.set_moving(true)
	var pr: float = stalker.progress
	await _wait(1.0)
	r["stalker_moved_1s"] = snappedf(stalker.progress - pr, 0.01)
	r["anim_when_moving"] = stalker.current_anim()
	stalker.set_moving(false)
	await _wait(0.3)
	r["anim_when_idle"] = stalker.current_anim()
	stalker.set_moving(true)

	r["ambience_playing"] = ambience.playing
	r["hum3d_playing"] = hum.playing
	r["hum_stream"] = hum.stream.resource_path if hum.stream else ""
	r["ambience_stream"] = ambience.stream.resource_path if ambience.stream else ""

	hud.apply_render_scale(0.5)
	hud.apply_shadow_quality(0)
	await _wait(0.5)
	r["scale_0.5_applied"] = is_equal_approx(get_viewport().scaling_3d_scale, 0.5)
	r["shadow_low_atlas"] = get_viewport().positional_shadow_atlas_size
	await _shot(dir, tag + "_low_quality.png")
	var fps := {}
	for q in [[1.0, 1], [0.5, 0], [1.0, 2]]:
		hud.apply_render_scale(q[0])
		hud.apply_shadow_quality(q[1])
		await _wait(0.5)
		var f0 := Engine.get_process_frames()
		var t0 := Time.get_ticks_usec()
		await _wait(3.0)
		fps["scale%s_shadow%d" % [q[0], q[1]]] = snappedf((Engine.get_process_frames() - f0) / ((Time.get_ticks_usec() - t0) / 1e6), 0.1)
	r["avg_fps"] = fps
	r["vsync"] = DisplayServer.window_get_vsync_mode()
	print("AUTOTEST ", JSON.stringify(r))
	get_tree().quit()
