extends Node3D
## Robot model test bench: lighting from the design doc (cold moon + warm lamp + cyan eyes),
## procedural whole-body motion (drive / lean / squash-stretch jump), two post looks.
##   godot --path . res://scenes/robot_test.tscn -- --autotest --shots=DIR --look=diorama|ps1

@export var model_path := "res://assets/models/robot_parts.glb"
@export var robot_height := 1.0

const POST := preload("res://shaders/ps1_post.gdshader")

var robot: Node3D        # moves / squashes
var model: Node3D        # the imported glb
var cam: Camera3D
var post: ShaderMaterial
var t := 0.0
var mode := "drive"      # drive | jump | idle
var _jump_t := 0.0
var load_ms := 0
var rig: RobotRig
var charge := 1.0
var pose_override := false

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--model="):
			model_path = a.substr(8)
	_build_world()
	robot = Node3D.new()
	add_child(robot)
	var t0 := Time.get_ticks_msec()
	model = (load(model_path) as PackedScene).instantiate()
	load_ms = Time.get_ticks_msec() - t0
	robot.add_child(model)
	ModelUtil.fit(model, robot_height)
	rig = RobotRig.new(model)
	if not rig.ok:
		_add_eye_lights()
	print("[robot] load %d ms, meshes=%d" % [load_ms, model.find_children("*", "MeshInstance3D", true, false).size()])
	var look := "diorama"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--look="):
			look = a.substr(7)
	set_look(look)
	if "--autotest" in OS.get_cmdline_user_args():
		_autotest(look)

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.38, 0.6)
	env.ambient_light_energy = 0.15
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.9
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# giant wooden desk top
	var floor := CSGBox3D.new()
	floor.size = Vector3(12, 0.2, 12)
	floor.position.y = -0.1
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.35, 0.22, 0.12)
	fm.roughness = 0.6
	floor.material = fm
	add_child(floor)
	# cold blue moonlight through a window
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 1.0)
	moon.light_energy = 0.6
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-35, 140, 0)
	add_child(moon)
	# warm amber desk lamp
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.62, 0.3)
	lamp.light_energy = 3.0
	lamp.omni_range = 6.0
	lamp.shadow_enabled = true
	lamp.position = Vector3(-1.6, 2.2, 1.0)
	add_child(lamp)
	cam = Camera3D.new()
	cam.fov = 45
	add_child(cam)
	var attrs := CameraAttributesPractical.new()  # tilt-shift-ish miniature DOF
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 4.5
	attrs.dof_blur_far_transition = 3.0
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = 1.2
	attrs.dof_blur_near_transition = 0.8
	attrs.dof_blur_amount = 0.12
	cam.attributes = attrs
	var layer := CanvasLayer.new()
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post = ShaderMaterial.new()
	post.shader = POST
	rect.material = post
	layer.add_child(rect)
	add_child(layer)

## The model is one mesh, so "eyes" are just two cyan lights placed at the face.
func _add_eye_lights() -> void:
	var box := ModelUtil.combined_aabb(robot)
	var eye := OmniLight3D.new()
	eye.light_color = Color(0.3, 1.0, 0.95)
	eye.light_energy = 1.2
	eye.omni_range = 1.2
	eye.position = Vector3(0, box.position.y + box.size.y * 0.75, box.position.z + box.size.z + 0.15)
	robot.add_child(eye)

func set_look(look: String) -> void:
	var diorama := look == "diorama"
	post.set_shader_parameter("pixel_size", 1.0 if diorama else 3.0)
	post.set_shader_parameter("color_levels", 256.0 if diorama else 24.0)
	post.set_shader_parameter("dither", not diorama)
	post.set_shader_parameter("grain_amount", 0.035 if diorama else 0.07)
	post.set_shader_parameter("chroma_offset", 0.002 if diorama else 0.006)
	post.set_shader_parameter("vignette_strength", 0.6 if diorama else 0.85)
	(cam.attributes as CameraAttributesPractical).dof_blur_far_enabled = diorama
	(cam.attributes as CameraAttributesPractical).dof_blur_near_enabled = diorama

func jump() -> void:
	mode = "jump"
	_jump_t = 0.0

func _process(delta: float) -> void:
	t += delta
	var s := Vector3.ONE
	match mode:
		"drive":  # drive in a circle, lean into the turn, track rumble
			var a := t * 0.6
			robot.position = Vector3(cos(a) * 1.2, absf(sin(t * 18.0)) * 0.006, sin(a) * 1.2)
			robot.rotation = Vector3(0, -a, deg_to_rad(-6))
		"idle":   # breathing bob, slight sway
			robot.position.y = 0.0
			s = Vector3(1, 1.0 + sin(t * 2.2) * 0.015, 1)
			robot.rotation.z = sin(t * 0.9) * 0.03
		"jump":   # wind-up squash -> stretch in air -> landing squash
			_jump_t += delta
			var j := _jump_t
			if j < 0.25:
				s = Vector3(1.12, 0.8, 1.12)
			elif j < 0.85:
				var u := (j - 0.25) / 0.6
				robot.position.y = sin(u * PI) * 0.7
				s = Vector3(0.92, 1.15, 0.92).lerp(Vector3.ONE, u)
			elif j < 1.05:
				robot.position.y = 0.0
				s = Vector3(1.15, 0.82, 1.15)
			else:
				mode = "idle"
	robot.scale = s
	rig.set_charge(charge, t)
	if not pose_override:
		var droop := (1.0 - charge) * 25.0
		match mode:
			"drive":
				rig.pose(sin(t * 0.8) * 25.0, 0.0, 8.0 - droop, 8.0 - droop, sin(t * 6.0) * 15.0, -sin(t * 6.0) * 15.0)
				rig.track_rumble(t, 1.0)
			"idle":
				rig.pose(sin(t * 0.5) * 10.0, sin(t * 0.7) * 6.0 - droop * 0.3, 4.0 - droop, 4.0 - droop, 0.0, 0.0)
			"jump":
				var up := 55.0 if _jump_t > 0.25 and _jump_t < 0.85 else -5.0
				rig.pose(0.0, 0.0, up, up, -20.0, -20.0)
		rig.spin_key(t * 90.0)
	if not "--autotest" in OS.get_cmdline_user_args():
		_orbit(t * 0.3, 0.35)

func _orbit(angle: float, pitch: float, dist := 3.0) -> void:
	var target := robot.global_position + Vector3(0, robot_height * 0.5, 0)
	cam.global_position = target + Vector3(sin(angle) * cos(pitch), sin(pitch), cos(angle) * cos(pitch)) * dist
	cam.look_at(target)

# ---------------------------------------------------------------- self test
func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _shot(dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(name))

func _fps(sec: float) -> float:
	var f0 := Engine.get_process_frames()
	var t0 := Time.get_ticks_usec()
	await _wait(sec)
	return snappedf((Engine.get_process_frames() - f0) / ((Time.get_ticks_usec() - t0) / 1e6), 0.1)

func _autotest(look: String) -> void:
	var dir := OS.get_user_data_dir()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			dir = a.substr(8)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var tag := look + ("_lo" if model_path.ends_with("_lo.glb") else ("_parts" if rig.ok else ""))
	look = tag
	var r := {"model": model_path, "look": look, "load_ms": load_ms, "renderer": RenderingServer.get_current_rendering_method()}
	mode = "idle"
	robot.position = Vector3.ZERO
	robot.rotation = Vector3.ZERO
	await _wait(1.0)
	for v in [["front34", 0.6, 0.25], ["back", PI + 0.3, 0.3], ["side_low", PI / 2, 0.05]]:
		_orbit(v[1], v[2])
		await _wait(0.4)
		await _shot(dir, "robot_%s_%s.png" % [look, v[0]])
	if rig.ok:
		pose_override = true
		_orbit(0.35, 0.15, 2.0)
		rig.pose(30.0, 15.0, 45.0, 45.0, 0.0, 0.0)
		rig.spin_key(90.0)
		await _wait(0.3)
		await _shot(dir, "robot_%s_pose_test.png" % look)
		rig.pose(0, 0, 0, 0, 0, 0)
		for c in [[1.0, "full"], [0.5, "half"], [0.15, "low"]]:
			charge = c[0]
			_orbit(PI + 0.25, 0.25, 1.9)
			await _wait(0.35)
			await _shot(dir, "robot_%s_charge_%s.png" % [look, c[1]])
		_orbit(0.3, 0.1, 1.8)
		await _wait(0.2)
		await _shot(dir, "robot_%s_eyes_low.png" % look)
		charge = 1.0
		pose_override = false
		r["parts"] = [rig.head.name, rig.arm_l.name, rig.arm_r.name, rig.wheels["L"].size(), rig.belts.size(), rig.key.name if rig.key else "none"]
	_orbit(0.9, 0.2, 3.6)
	r["fps_idle"] = await _fps(3.0)
	r["vram_mb"] = snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1)
	r["draw_prims"] = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	jump()
	await _wait(0.12)
	await _shot(dir, "robot_%s_jump_squash.png" % look)
	await _wait(0.33)
	await _shot(dir, "robot_%s_jump_air.png" % look)
	await _wait(1.0)
	mode = "drive"
	for i in 3:
		await _wait(0.5)
		_orbit(0.9, 0.3, 4.5)
	await _shot(dir, "robot_%s_drive.png" % look)
	r["fps_drive"] = await _fps(3.0)
	print("ROBOTTEST ", JSON.stringify(r))
	get_tree().quit()
