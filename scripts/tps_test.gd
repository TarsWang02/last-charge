extends Node3D
## Playable test level for the third-person robot: a giant desk with book stacks to climb,
## a desk lamp to power with E, and batteries to collect. Built in code to stay easy to tweak.
##   godot --path . res://scenes/tps_test.tscn [-- --autotest --shots=DIR]

const PLAYER := preload("res://scenes/tps_player.tscn")
const POST_FX := preload("res://scenes/post_fx.tscn")
const SPAWN := Vector3(0, 0.05, 4)

var player: CharacterBody3D
var lamp_light: SpotLight3D
var lamp_bulb: MeshInstance3D
var lamp_area: Area3D
var lamp_on := false
var prompt: Label3D
var hint: Label
var debug: Label
var pause_label: Label
var _hint_t := 10.0
var post_fx: CanvasLayer

func _ready() -> void:
	_build_env()
	_build_level()
	player = PLAYER.instantiate()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.teleport(SPAWN)
	player.died.connect(func(): pause_label.text = "OUT OF POWER\npress R to restart"; pause_label.visible = true)
	post_fx = POST_FX.instantiate()
	post_fx.player_path = player.get_path()
	add_child(post_fx)
	_build_ui()
	if "--nointerp" in OS.get_cmdline_user_args():
		get_tree().physics_interpolation = false
	if "--autotest" in OS.get_cmdline_user_args():
		_autotest()

# ------------------------------------------------------------------ world
func _mat(c: Color, rough := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _box(size: Vector3, pos: Vector3, c: Color, rot_y := 0.0) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.rotation.y = rot_y
	b.use_collision = true
	b.material = _mat(c)
	add_child(b)
	return b

func _build_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.025)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.42, 0.65)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.9
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.03, 0.04, 0.07)
	env.fog_density = 0.02
	var we := WorldEnvironment.new()
	we.environment = env
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = false  # tilt-shift in post_fx does the miniature blur
	attrs.dof_blur_far_distance = 9.0
	attrs.dof_blur_far_transition = 6.0
	attrs.dof_blur_amount = 0.1
	we.camera_attributes = attrs
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 1.0)
	moon.light_energy = 1.1
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-40, 150, 0)
	add_child(moon)

func _build_level() -> void:
	var wood := Color(0.36, 0.22, 0.12)
	_box(Vector3(16, 0.4, 12), Vector3(0, -0.2, 0), wood)                       # desk top
	# book stacks as a staircase (step heights 0.45 / 0.9 / 1.35 / 1.8)
	var cols := [Color(0.5, 0.12, 0.1), Color(0.12, 0.25, 0.4), Color(0.55, 0.45, 0.2), Color(0.18, 0.35, 0.2)]
	for i in 4:
		_box(Vector3(1.6, 0.45 * (i + 1), 1.2), Vector3(-3.0 + i * 1.7, 0.225 * (i + 1), -1.0), cols[i], 0.05 * (i % 2))
	_box(Vector3(3.0, 0.3, 2.0), Vector3(4.6, 2.0, -1.0), Color(0.25, 0.2, 0.15))  # shelf ledge (a gap jump from the last stack)
	_box(Vector3(1.0, 0.3, 1.0), Vector3(6.5, 2.4, -2.6), Color(0.6, 0.55, 0.45))  # small step up to the lamp
	_build_lamp(Vector3(6.3, 2.55, -4.3))
	for p in [Vector3(-3.0, 0.75, -1.0), Vector3(2.1, 2.1, -1.0), Vector3(-5, 0.35, 3), Vector3(5.6, 2.45, -0.4)]:
		_add_battery(p)

func _build_lamp(base: Vector3) -> void:
	var metal := _mat(Color(0.7, 0.55, 0.25), 0.35)
	metal.metallic = 0.8
	var foot := CSGCylinder3D.new()
	foot.radius = 0.5
	foot.height = 0.1
	foot.position = base
	foot.material = metal
	foot.use_collision = true
	add_child(foot)
	var pole := CSGCylinder3D.new()
	pole.radius = 0.06
	pole.height = 2.0
	pole.position = base + Vector3(0, 1.0, 0)
	pole.material = metal
	add_child(pole)
	var shade := CSGCylinder3D.new()
	shade.radius = 0.45
	shade.height = 0.5
	shade.cone = true
	shade.position = base + Vector3(0, 2.1, 0.35)
	shade.rotation_degrees.x = 200
	shade.material = metal
	add_child(shade)
	lamp_bulb = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.12
	s.height = 0.24
	lamp_bulb.mesh = s
	lamp_bulb.position = base + Vector3(0, 1.9, 0.4)
	lamp_bulb.material_override = _mat(Color(0.3, 0.28, 0.25))
	add_child(lamp_bulb)
	lamp_light = SpotLight3D.new()
	lamp_light.light_color = Color(1.0, 0.65, 0.3)
	lamp_light.light_energy = 0.0
	lamp_light.spot_range = 9.0
	lamp_light.spot_angle = 50.0
	lamp_light.shadow_enabled = true
	lamp_light.position = base + Vector3(0, 1.85, 0.4)
	lamp_light.rotation_degrees.x = -70
	lamp_light.rotation_degrees.y = 160
	add_child(lamp_light)
	lamp_area = Area3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.4
	cs.shape = sph
	lamp_area.add_child(cs)
	lamp_area.position = base + Vector3(0, 0.3, 0)
	add_child(lamp_area)
	prompt = Label3D.new()
	prompt.text = "[E]"
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.no_depth_test = true
	prompt.modulate = Color(1, 0.85, 0.5)
	prompt.font_size = 48
	prompt.position = base + Vector3(0, 1.0, 0.6)
	prompt.visible = false
	add_child(prompt)

func _add_battery(pos: Vector3) -> void:
	var a := Area3D.new()
	a.position = pos
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.4
	cs.shape = sh
	a.add_child(cs)
	var m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.08
	cyl.height = 0.28
	m.mesh = cyl
	var mat := _mat(Color(0.2, 1.0, 0.9))
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.9)
	mat.emission_energy_multiplier = 2.5
	m.material_override = mat
	m.rotation_degrees.z = 20
	a.add_child(m)
	var l := OmniLight3D.new()
	l.light_color = Color(0.2, 1.0, 0.9)
	l.light_energy = 0.4
	l.omni_range = 1.2
	a.add_child(l)
	a.body_entered.connect(func(b):
		if b == player:
			player.add_charge(0.2)
			a.queue_free())
	add_child(a)

# ------------------------------------------------------------------ ui
func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 2
	add_child(ui)
	hint = Label.new()
	hint.text = "WASD move   ·   mouse look   ·   Space jump (hold = higher)   ·   E power the lamp\nEsc pause   ·   R restart   ·   F1 debug   ·   F2 post effect on/off"
	hint.position = Vector2(24, 24)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	ui.add_child(hint)
	debug = Label.new()
	debug.position = Vector2(24, 80)
	debug.visible = false
	ui.add_child(debug)
	pause_label = Label.new()
	pause_label.set_anchors_preset(Control.PRESET_CENTER)
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.add_theme_font_size_override("font_size", 32)
	pause_label.visible = false
	ui.add_child(pause_label)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and player.alive:
			_resume()
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				get_tree().paused = true
				pause_label.text = "PAUSED\nEsc / click to resume   ·   Q to quit"
				pause_label.visible = true
			else:
				_resume()
		KEY_Q:
			if get_tree().paused:
				get_tree().quit()
		KEY_R:
			_restart()
		KEY_F1:
			debug.visible = not debug.visible
		KEY_F2:
			post_fx.enabled = not post_fx.enabled

func _resume() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pause_label.visible = not player.alive

func _restart() -> void:
	player.teleport(SPAWN)
	player.velocity = Vector3.ZERO
	player.charge = 1.0
	player.alive = true
	pause_label.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	_hint_t -= delta
	hint.modulate.a = clampf(_hint_t / 2.0, 0.0, 1.0)
	if player.global_position.y < -6.0:
		player.teleport(SPAWN)
		player.velocity = Vector3.ZERO
	var near := lamp_area.overlaps_body(player)
	prompt.visible = near and not lamp_on
	if near and not lamp_on and player.alive and Input.is_action_just_pressed("interact"):
		power_lamp()
	debug.text = "%d fps   charge %.2f   pos %s   floor %s" % [Engine.get_frames_per_second(), player.charge,
		str(player.global_position.snapped(Vector3.ONE * 0.01)), player.is_on_floor()]

func power_lamp() -> void:
	lamp_on = true
	player.add_charge(-0.1)
	var tw := create_tween()
	tw.tween_property(lamp_light, "light_energy", 6.0, 0.6).set_trans(Tween.TRANS_EXPO)
	var m := _mat(Color(1, 0.8, 0.5))
	m.emission_enabled = true
	m.emission = Color(1, 0.7, 0.35)
	m.emission_energy_multiplier = 6.0
	lamp_bulb.material_override = m

# ------------------------------------------------------------------ self test
func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _shot(dir: String, n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(n))

func _act(action: String, down: bool) -> void:  # real input event, like a key press
	var e := InputEventAction.new()
	e.action = action
	e.pressed = down
	Input.parse_input_event(e)

func _hold(action: String, s: float) -> void:
	_act(action, true)
	await _wait(s)
	_act(action, false)

func _autotest() -> void:
	var dir := OS.get_user_data_dir()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			dir = a.substr(8)
	var r := {}
	await _wait(1.0)
	r["on_floor_at_start"] = player.is_on_floor()
	await _shot(dir, "tps_start.png")
	var p0 := player.global_position
	var belt0: float = player.rig._belt_dist["L"]
	var wheel0: float = player.rig.wheels["L"][0].rotation.x
	_act("move_fwd", true)
	await _wait(0.4)  # get up to speed, then measure how evenly the model moves each rendered frame
	var steps: Array[float] = []
	var last: Vector3 = player.visual.global_position
	for i in 60:
		await get_tree().process_frame
		var now: Vector3 = player.visual.global_position
		steps.append(now.distance_to(last) / get_process_delta_time())
		last = now
	await _wait(0.2)
	_act("move_fwd", false)
	var mean := 0.0
	for v in steps: mean += v
	mean /= steps.size()
	var var_ := 0.0
	for v in steps: var_ += (v - mean) * (v - mean)
	r["visual_speed_cv"] = snappedf(sqrt(var_ / steps.size()) / mean, 0.001)  # 0 = perfectly even
	r["walk_m"] = snappedf(player.global_position.distance_to(p0), 0.01)
	r["faces_move_dir"] = absf(wrapf(player.visual.rotation.y - PI, -PI, PI)) < 0.3  # moved towards -Z
	r["belt_moved_m"] = snappedf(player.rig._belt_dist["L"] - belt0, 0.01)
	r["wheel_spun_rad"] = snappedf(player.rig.wheels["L"][0].rotation.x - wheel0, 0.01)
	r["wheels_found"] = [player.rig.wheels["L"].size(), player.rig.wheels["R"].size(), player.rig.belts.size()]
	# side close-up of the tracks while driving
	player.cam_pivot.rotation.y = -PI / 2
	player.spring.spring_length = 1.3
	player.spring.rotation.x = deg_to_rad(-6)
	player.cam_pivot.rotation.y = 0.0
	_act("move_right", true)  # drives across the view -> side-on tracks
	await _wait(0.5)
	await _shot(dir, "tps_tracks_a.png")
	await _wait(0.06)
	await _shot(dir, "tps_tracks_b.png")
	_act("move_right", false)
	player.spring.spring_length = 2.8
	player.spring.rotation.x = deg_to_rad(-18)
	player.cam_pivot.rotation.y = 0.0
	await _wait(0.6)
	player.teleport(SPAWN)
	await _wait(0.5)
	await _shot(dir, "tps_walk.png")
	var y0 := player.global_position.y
	var peak := y0
	_act("jump", true)
	for i in 40:
		await get_tree().physics_frame
		peak = maxf(peak, player.global_position.y)
		if i == 12:
			await _shot(dir, "tps_jump.png")
	_act("jump", false)
	r["full_jump_height_m"] = snappedf(peak - y0, 0.01)
	await _wait(1.0)
	y0 = player.global_position.y
	peak = y0
	_act("jump", true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_act("jump", false)
	for i in 40:
		await get_tree().physics_frame
		peak = maxf(peak, player.global_position.y)
	r["short_hop_height_m"] = snappedf(peak - y0, 0.01)
	await _wait(0.8)
	var yaw0: float = player.cam_pivot.rotation.y
	var mm := InputEventMouseMotion.new()
	mm.relative = Vector2(300, 0)
	Input.parse_input_event(mm)
	await _wait(0.1)
	r["cam_orbit_rad"] = snappedf(absf(player.cam_pivot.rotation.y - yaw0), 0.01)
	# climb: put robot next to the first stack, jump forward onto it
	player.teleport(Vector3(-3.0, 0.05, 0.3))
	player.velocity = Vector3.ZERO
	player.cam_pivot.rotation.y = 0.0
	await _wait(0.5)
	var c_before: float = player.charge
	_act("move_fwd", true)
	await _wait(0.15)
	_act("jump", true)
	await _wait(0.3)
	_act("move_fwd", false)
	await _wait(0.2)
	_act("jump", false)
	await _wait(0.6)
	r["climbed_stack_y"] = snappedf(player.global_position.y, 0.01)
	r["battery_pickup_gain"] = snappedf(player.charge - c_before, 0.01)
	await _shot(dir, "tps_on_stack.png")
	# camera collision: back the camera into the stack behind
	player.teleport(Vector3(-1.3, 0.05, 0.2))
	player.cam_pivot.rotation.y = PI  # camera looks from -Z side, towards the books
	await _wait(0.4)
	r["spring_len_vs_max"] = [snappedf(player.spring.get_hit_length(), 0.01), player.spring.spring_length]
	player.cam_pivot.rotation.y = 0.0
	# lamp interaction
	player.teleport(Vector3(6.3, 2.6, -3.3))
	player.velocity = Vector3.ZERO
	await _wait(0.5)
	r["prompt_visible_near_lamp"] = prompt.visible
	var c0: float = player.charge
	await _hold("interact", 0.1)
	await _wait(0.8)
	r["lamp_on"] = lamp_on
	r["lamp_cost"] = snappedf(c0 - player.charge, 0.01)
	player.cam_pivot.rotation.y = -0.6
	player.spring.rotation.x = deg_to_rad(-25)
	await _wait(0.4)
	await _shot(dir, "tps_lamp_on.png")
	post_fx.enabled = false
	await _wait(0.1)
	await _shot(dir, "tps_lamp_on_nopost.png")
	post_fx.enabled = true
	player.charge = 0.08
	await _wait(1.5)
	await _shot(dir, "tps_low_power.png")
	r["power_loss_at_8pct"] = snappedf(post_fx.mat.get_shader_parameter("power_loss"), 0.01)
	# drain to death
	player.charge = 0.02
	await _wait(5.0)
	r["dies_at_zero"] = not player.alive
	await _shot(dir, "tps_dead.png")
	_restart()
	await _wait(0.3)
	r["restart_ok"] = player.alive and player.charge > 0.99
	var f0 := Engine.get_process_frames()
	var t0 := Time.get_ticks_usec()
	await _wait(2.0)
	r["fps"] = snappedf((Engine.get_process_frames() - f0) / ((Time.get_ticks_usec() - t0) / 1e6), 0.1)
	print("TPSTEST ", JSON.stringify(r))
	get_tree().quit()
