extends CharacterBody3D
## Third-person robot controller: camera-relative movement, spring-arm camera,
## jump with coyote time / buffering / variable height, battery charge.
## Kitchen only (magnet_enabled): hold the magnet button (right mouse / Q / RB) under a steel surface
## (nodes in group "metal", axis-aligned CSGBox3D) -> the robot turns its claws into an electromagnet and
## hangs under it, moving along it; it can pass to a neighbouring steel piece at a similar height. Hanging
## drains charge fast; let go (or run flat) and it drops.
## Physics runs at the physics tick; everything visible (model, camera, animation) is updated
## every rendered frame from the interpolated body position, so it stays smooth at 144/165 Hz.

signal charge_changed(charge: float)
signal died

@export var model_path := "res://assets/models/robot_parts_polished.glb"
@export var robot_height := 0.9
@export_group("Move")
@export var speed := 2.8
@export var accel := 14.0
@export var air_accel := 5.0
@export var turn_speed := 12.0
@export_group("Jump")
@export var jump_velocity := 5.0
@export var fall_gravity_mult := 1.9
@export var coyote_time := 0.12
@export var jump_buffer := 0.12
@export_group("Camera")
@export var mouse_sens := 0.0028
@export var stick_sens := 2.6
@export var pitch_min := -55.0
@export var pitch_max := 10.0
@export var cam_height := 0.65
@export var cam_y_follow := 8.0 ## lower = camera lags more on jumps
@export var mantle_height := 0.7 ## airborne against a ledge whose top is this close: climb onto it
@export_group("Grab")
@export var grab_range := 0.45 ## gap between the robot and a block's side to grab it
@export var grab_speed_mult := 0.5
@export_group("Top-down")
@export var top_down_pitch := -80.0
@export var top_down_dist := 8.0
@export var glow_range := 2.4 ## the robot's own always-on light (units), used in dark top-down mazes
@export_group("Magnet")
@export var magnet_reach := 1.0      ## how far above the robot's head a steel underside can be grabbed (units)
@export var magnet_speed := 0.8      ## x move speed while hanging
@export var magnet_drain := 0.01     ## charge per second while hanging (instead of the normal drain)
@export_group("Battery")
@export var drain_per_sec := 0.006
@export var drain_per_jump := 0.006

@onready var visual: Node3D = $Visual
@onready var lean: Node3D = $Visual/Lean
@onready var cam_pivot: Node3D = $CamPivot
@onready var spring: SpringArm3D = $CamPivot/SpringArm3D

var rig: RobotRig
var charge := 1.0
var alive := true
var locked := false  ## cutscenes / scripted moves: no input, no physics, no drain
var grabbing: Pushable = null
var top_down := false  ## fixed overhead camera, no mouse look, no jumping (the desk maze)
var magnet_enabled := false  ## the kitchen switches this on
var updraft_top := -INF      ## set each physics frame by the level while the robot is in rising steam (units)
var hanging := false         ## scripted hanging (the clothesline): claws up, like the magnet
var head_look := NAN         ## scripted head turn (degrees, + = to the robot's left); NAN = normal
var pose_override := []      ## cutscenes: [yaw, tilt, nod, l_lift, r_lift, l_swing, r_swing] for the rig; [] = normal
var powered_down := false    ## the ending: it has given its last charge; eyes and cells go dark
var clinging: Node3D = null  ## the steel piece the robot hangs under
var magnet_seconds := 0.0    ## time spent hanging (for tuning / the self test)
var _cling_y := 0.0
var _magnet_hint: Node3D
var _td_yaw := 0.0
var _arm_len := 3.8
var _focus := Vector3.INF      ## top-down: a lit area the camera should also frame
var _focus_extra := 0.0
var _pivot_pos := Vector3.ZERO
var _glow: OmniLight3D
var _carry: OmniLight3D
var _grab_axis := Vector3.ZERO
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _coyote := 0.0
var _buffer := 0.0
var _was_floor := true
var _prev_vy := 0.0
var _t := 0.0
var _face_yaw := 0.0
var _prev_hv := Vector3.ZERO
var _acc_fwd := 0.0
var _cam_y := 0.0
var _phase := 0.0
var _key_deg := 0.0
# body springs (degrees / scale)
var _pitch := RobotRig.Spring.new(90.0, 0.5)
var _roll := RobotRig.Spring.new(90.0, 0.5)
var _squash := RobotRig.Spring.new(260.0, 0.28)

func _ready() -> void:
	_setup_input()
	var model: Node3D = (load(model_path) as PackedScene).instantiate()
	lean.add_child(model)
	ModelUtil.fit(model, robot_height)
	rig = RobotRig.new(model)
	_squash.snap(1.0)
	# visible nodes follow the interpolated body in _process instead of inheriting the physics tick
	for n in [visual, cam_pivot]:
		n.top_level = true
		n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	spring.add_excluded_object(get_rid())
	spring.rotation.x = deg_to_rad(-18.0)
	_arm_len = spring.spring_length
	_cam_y = global_position.y
	_glow = OmniLight3D.new()  # the robot's own small light; only switched up in dark areas
	_glow.light_color = Color(0.4, 1.0, 0.95)
	_glow.light_energy = 0.0
	_glow.omni_range = glow_range
	_glow.position = Vector3(0, 0.8, 0)
	visual.add_child(_glow)
	_carry = OmniLight3D.new()  # the light it always carries: a soft pool round its feet, dimmer as it runs down
	_carry.light_color = Color(0.6, 0.95, 1.0)
	_carry.light_energy = 0.0
	_carry.omni_range = 3.4
	_carry.omni_attenuation = 1.3
	_carry.position = Vector3(0, 0.75, 0.25)
	_carry.light_specular = 0.1
	visual.add_child(_carry)
	_magnet_hint = UiKit.make_prompt("RMB", "Magnet")  # "you can grab the steel above you"
	_magnet_hint.position = Vector3(0, 1.35, 0)
	_magnet_hint.visible = false
	visual.add_child(_magnet_hint)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

static func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_fwd": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, JOY_BUTTON_A], "interact": [KEY_E, JOY_BUTTON_X],
		"attack": [KEY_J, JOY_BUTTON_B],  # the claw in the TV game (+ left mouse button, below)
		"magnet": [KEY_Q, JOY_BUTTON_RIGHT_SHOULDER],  # the kitchen electromagnet (+ right mouse button, below)
	}
	for action in map:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.2)
		for code in map[action]:
			var ev: InputEvent
			if code < 32:  # small codes are joypad buttons, not keys
				ev = InputEventJoypadButton.new()
				ev.button_index = code
			else:
				ev = InputEventKey.new()
				ev.physical_keycode = code
			InputMap.action_add_event(action, ev)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", click)
	var rclick := InputEventMouseButton.new()
	rclick.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("magnet", rclick)
	for pair in [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0],
			["move_fwd", JOY_AXIS_LEFT_Y, -1.0], ["move_back", JOY_AXIS_LEFT_Y, 1.0]]:
		var m := InputEventJoypadMotion.new()
		m.axis = pair[1]
		m.axis_value = pair[2]
		InputMap.action_add_event(pair[0], m)

## Top-down only: frame the robot AND a lit area (camera moves to the midpoint and backs off to fit both).
func set_view_focus(point: Vector3, radius: float) -> void:
	_focus = point
	var d := Vector2(point.x - global_position.x, point.z - global_position.z).length()
	_focus_extra = maxf(0.0, (d + radius) * 0.9 - top_down_dist * 0.5)

func clear_view_focus() -> void:
	_focus = Vector3.INF
	_focus_extra = 0.0

## Overhead maze camera on/off. yaw = which way is "up" on screen (0 = north).
func set_top_down(on: bool, yaw := 0.0) -> void:
	top_down = on
	_td_yaw = yaw
	var tw := create_tween()
	tw.tween_property(_glow, "light_energy", 1.4 if on else 0.0, 0.8)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not top_down and clinging == null:
		_rotate_cam(-event.relative.x * mouse_sens, -event.relative.y * mouse_sens)

func _rotate_cam(yaw: float, pitch: float) -> void:
	cam_pivot.rotation.y += yaw
	spring.rotation.x = clampf(spring.rotation.x + pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))

func add_charge(v: float) -> void:
	charge = clampf(charge + v, 0.0, 1.0)
	charge_changed.emit(charge)

## Visual kick for scripted launches (toaster etc.).
func launch_squash() -> void:
	_squash.v += 9.0
	rig.kick_arms(-200.0, 450.0)
	rig.kick_head(-200.0)

## Back to life after running flat (respawn at a checkpoint).
func revive(c: float) -> void:
	charge = c
	alive = true
	charge_changed.emit(charge)

## Teleport (restart / respawn) without the camera and model sliding across the level.
func teleport(pos: Vector3) -> void:
	_stop_cling()
	global_position = pos
	velocity = Vector3.ZERO
	reset_physics_interpolation()
	_cam_y = pos.y

# ------------------------------------------------------------------ physics
func _physics_process(delta: float) -> void:
	if locked:
		velocity = Vector3.ZERO
		_was_floor = false  # land squash when control returns
		return
	if _magnet_physics(delta):
		return
	var on_floor := is_on_floor()
	var g := _gravity * (fall_gravity_mult if velocity.y < 0.0 else 1.0)
	if updraft_top > -INF:  # carried up by steam: float towards its top, gently
		velocity.y = lerpf(velocity.y, clampf((updraft_top - global_position.y) * 2.5, -1.2, 2.2), 1.0 - exp(-5.0 * delta))
	elif not on_floor:
		velocity.y -= g * delta
	_coyote = coyote_time if on_floor else _coyote - delta
	_buffer = jump_buffer if Input.is_action_just_pressed("jump") else _buffer - delta

	var input := Vector2.ZERO
	if alive and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input = Input.get_vector("move_left", "move_right", "move_fwd", "move_back")
	var dir := Basis(Vector3.UP, cam_pivot.rotation.y) * Vector3(input.x, 0, input.y)
	var spd := speed * lerpf(0.55, 1.0, clampf(charge * 2.0, 0.0, 1.0))  # slower when low
	var a := accel if on_floor else air_accel
	var target := dir * spd
	velocity.x = move_toward(velocity.x, target.x, a * spd * delta)
	velocity.z = move_toward(velocity.z, target.z, a * spd * delta)
	if dir.length() > 0.05:
		_face_yaw = atan2(dir.x, dir.z)

	# grab (hold E next to a block): push / pull along one axis, slower, no jumping
	var near := _nearest_pushable() if on_floor and alive else null
	for p in get_tree().get_nodes_in_group("pushable"):
		p.show_prompt(p == near and grabbing == null)
	if grabbing == null and near != null and Input.is_action_pressed("interact"):
		grabbing = near
		grabbing.grabbed = true
		var to := grabbing.global_position - global_position
		_grab_axis = Vector3(signf(to.x), 0, 0) if absf(to.x) > absf(to.z) else Vector3(0, 0, signf(to.z))
	elif grabbing != null and (not Input.is_action_pressed("interact") or not on_floor or _gap_to(grabbing) > grab_range + 0.3):
		_release_grab()
	var pull_v := Vector3.ZERO
	if grabbing != null:
		var v := Vector3(velocity.x, 0, velocity.z).project(_grab_axis) * grab_speed_mult
		_face_yaw = atan2(_grab_axis.x, _grab_axis.z)
		_buffer = 0.0
		if v.dot(_grab_axis) >= 0.0:  # pushing: the block goes first
			var got := grabbing.push(v, delta)
			velocity.x = got.x
			velocity.z = got.z
		else:                         # pulling: the robot goes first, the block follows below
			velocity.x = v.x
			velocity.z = v.z
			pull_v = v

	if top_down:
		_buffer = 0.0  # no jumping in the maze

	if alive and _buffer > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity
		_buffer = 0.0
		_coyote = 0.0
		_squash.v += 7.0                  # stretch up
		rig.kick_arms(-150.0, 380.0)      # arms fling up and back
		rig.kick_head(-160.0)             # look up as it leaves the ground
		add_charge(-drain_per_jump)
	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= 0.5  # short hop

	move_and_slide()
	_try_mantle(dir)
	if grabbing != null and pull_v != Vector3.ZERO:
		grabbing.push(pull_v, delta)

	if is_on_floor() and not _was_floor:
		var impact := clampf(-_prev_vy / 7.0, 0.15, 1.0)
		_squash.v -= 8.0 * impact         # squash down, wobble back
		rig.kick_head(320.0 * impact)     # head nods with the landing
		rig.kick_arms(120.0 * impact, -350.0 * impact)
	_was_floor = is_on_floor()
	_prev_vy = velocity.y

	var hv := Vector3(velocity.x, 0, velocity.z)
	var fwd := Vector3(sin(_face_yaw), 0, cos(_face_yaw))
	_acc_fwd = lerpf(_acc_fwd, (hv - _prev_hv).dot(fwd) / delta, 0.25)
	_prev_hv = hv

	if alive and not in_cutscene():   # cutscenes are free: the battery only runs down while you play
		add_charge(-drain_per_sec * delta)
		if charge <= 0.0:
			alive = false
			died.emit()

# ------------------------------------------------------------------ magnet (kitchen)
static func metal_box(n: Node3D) -> AABB:
	var sz: Vector3 = n.size
	return AABB(n.global_position - sz / 2.0, sz)

## A steel piece whose underside is between dy_min and dy_max above the robot's head (at p), with p inside
## its footprint grown by `grow`.
func _find_metal(p: Vector3, dy_min: float, dy_max: float, exclude: Node3D = null, grow := 0.4) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("metal"):
		if n == exclude:
			continue
		var b := metal_box(n)
		if p.x < b.position.x - grow or p.x > b.end.x + grow or p.z < b.position.z - grow or p.z > b.end.z + grow:
			continue
		var dy := b.position.y - (p.y + robot_height)
		if dy < dy_min or dy > dy_max:
			continue
		if absf(dy) < best_d:
			best = n
			best_d = absf(dy)
	return best

func _start_cling(m: Node3D) -> void:
	clinging = m
	_cling_y = metal_box(m).position.y - robot_height - 0.01
	velocity = Vector3.ZERO
	_release_grab()
	_squash.v += 5.0
	rig.kick_arms(300.0, 0.0)
	create_tween().tween_property(_glow, "light_energy", 1.6, 0.2)

func _stop_cling() -> void:
	if clinging == null:
		return
	clinging = null
	if _glow and not top_down:
		create_tween().tween_property(_glow, "light_energy", 0.0, 0.4)

## Returns true while hanging (the normal walk/jump physics is skipped).
## A scripted camera (a cutscene, a reveal, a close-up) has the view, not the robot's own camera.
func in_cutscene() -> bool:
	var cam := get_viewport().get_camera_3d()
	return cam != null and cam != $CamPivot/SpringArm3D/Camera3D and not top_down

func _magnet_physics(delta: float) -> bool:
	if not magnet_enabled:
		_magnet_hint.visible = false
		return false
	var held := Input.is_action_pressed("magnet") and alive
	if clinging == null:
		var near := _find_metal(global_position, -0.3, magnet_reach)
		_magnet_hint.visible = near != null
		if held and near != null:
			_start_cling(near)
		else:
			return false
	_magnet_hint.visible = false
	if not held or charge <= 0.0:
		_stop_cling()
		return false
	# move along the underside; at its edge, pass on to a neighbouring steel piece at a similar height
	var input := Input.get_vector("move_left", "move_right", "move_fwd", "move_back")
	var dir := Basis(Vector3.UP, cam_pivot.rotation.y) * Vector3(input.x, 0, input.y)
	var want := global_position + dir * speed * magnet_speed * delta
	want.y = lerpf(global_position.y, _cling_y, 1.0 - exp(-14.0 * delta))
	var b := metal_box(clinging)
	var g := 0.5
	if want.x < b.position.x - g or want.x > b.end.x + g or want.z < b.position.z - g or want.z > b.end.z + g:
		var next := _find_metal(Vector3(want.x, _cling_y, want.z), -2.2, 2.2, clinging, 0.6)   # forgiving hand-over at corners
		if next != null:
			clinging = next
			_cling_y = metal_box(next).position.y - robot_height - 0.01
		else:
			want.x = clampf(want.x, b.position.x - g, b.end.x + g)
			want.z = clampf(want.z, b.position.z - g, b.end.z + g)
	velocity = (want - global_position) / delta
	move_and_slide()
	velocity = Vector3.ZERO
	if dir.length() > 0.05:
		_face_yaw = atan2(dir.x, dir.z)
	magnet_seconds += delta
	add_charge(-magnet_drain * delta)
	if charge <= 0.0:
		_stop_cling()
		alive = false
		died.emit()
	return true

## Ledge assist: in the air, pushing into a wall whose top is just above the feet -> pop up onto it.
func _try_mantle(dir: Vector3) -> void:
	if top_down or is_on_floor() or not is_on_wall() or dir.length() < 0.3 or velocity.y < -6.0 or grabbing != null:
		return
	var n := get_wall_normal()
	if Vector3(dir.x, 0, dir.z).normalized().dot(-n) < 0.5:
		return
	for i in get_slide_collision_count():   # some ledges have to be reached the proper way
		var c := get_slide_collision(i).get_collider()
		if c is Node and c.has_meta("no_mantle"):
			return
	for h in [0.25, 0.45, mantle_height]:
		var up := global_transform.translated(Vector3.UP * h)
		if not test_move(global_transform, Vector3.UP * h) and not test_move(up, -n * 0.35):
			global_position += Vector3.UP * h - n * 0.35
			velocity.y = 0.0
			_squash.v -= 3.0
			return

func _gap_to(p: Pushable) -> float:
	var half := p.size * 0.5
	var c := p.global_position
	var dx := maxf(absf(global_position.x - c.x) - half.x, 0.0)
	var dz := maxf(absf(global_position.z - c.z) - half.z, 0.0)
	return Vector2(dx, dz).length() - 0.32

func _nearest_pushable() -> Pushable:
	var best: Pushable = null
	var bd := grab_range
	for p in get_tree().get_nodes_in_group("pushable"):
		var d := _gap_to(p)
		if d < bd and absf(p.global_position.y - global_position.y) < 0.4:
			best = p
			bd = d
	return best

func _release_grab() -> void:
	if grabbing:
		grabbing.grabbed = false
	grabbing = null

# ------------------------------------------------------------------ visuals (every frame)
func _process(delta: float) -> void:
	_t += delta
	var rs := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	var k := 1.0 - exp(-3.0 * delta)
	if clinging != null:  # hanging: a fixed side view from the open room, slightly from below
		var cy: float = clinging.get_meta("cam_yaw", cam_pivot.rotation.y)
		cam_pivot.rotation.y = lerp_angle(cam_pivot.rotation.y, cy, k * 1.5)
		spring.rotation.x = lerp_angle(spring.rotation.x, deg_to_rad(4.0), k * 1.5)
		spring.spring_length = lerpf(spring.spring_length, _arm_len * 1.15, k)
	elif top_down:  # glide to the overhead view
		cam_pivot.rotation.y = lerp_angle(cam_pivot.rotation.y, _td_yaw, k)
		spring.rotation.x = lerp_angle(spring.rotation.x, deg_to_rad(top_down_pitch), k)
		spring.spring_length = lerpf(spring.spring_length, top_down_dist + _focus_extra, k)
	else:
		spring.spring_length = lerpf(spring.spring_length, _arm_len, k)
	if rs.length() > 0.2 and not top_down and clinging == null:
		_rotate_cam(-rs.x * stick_sens * delta, -rs.y * stick_sens * delta)

	var pos := get_global_transform_interpolated().origin
	visual.global_position = pos
	_cam_y = lerpf(_cam_y, pos.y, 1.0 - exp(-cam_y_follow * delta)) if absf(_cam_y - pos.y) < 3.0 else pos.y
	var want := Vector3(pos.x, _cam_y + cam_height, pos.z)
	if top_down and _focus != Vector3.INF:
		want = Vector3((pos.x + _focus.x) / 2.0, want.y, (pos.z + _focus.z) / 2.0)
		_pivot_pos = _pivot_pos.lerp(want, 1.0 - exp(-4.0 * delta))
	elif top_down:
		_pivot_pos = _pivot_pos.lerp(want, 1.0 - exp(-8.0 * delta))
	else:
		_pivot_pos = want
	cam_pivot.global_position = _pivot_pos

	var prev_yaw := visual.rotation.y
	visual.rotation.y = lerp_angle(prev_yaw, _face_yaw, 1.0 - exp(-turn_speed * delta))
	var yaw_rate := wrapf(visual.rotation.y - prev_yaw, -PI, PI) / maxf(delta, 1e-4)
	_animate(delta, yaw_rate)

func _animate(delta: float, yaw_rate: float) -> void:
	var on_floor := is_on_floor()
	var fwd := Vector3(sin(visual.rotation.y), 0, cos(visual.rotation.y))
	var v_fwd := Vector3(velocity.x, 0, velocity.z).dot(fwd)
	var move := clampf(absf(v_fwd) / speed, 0.0, 1.0)
	var droop := (1.0 - charge) * 25.0

	# body: lean into speed, lag back on acceleration, bank outwards in turns, squash/stretch
	_pitch.target = clampf(v_fwd / speed * 7.0 - _acc_fwd * 0.7, -14.0, 14.0)
	_roll.target = clampf(yaw_rate * v_fwd * 5.0, -12.0, 12.0)
	if not alive:
		_pitch.target = 16.0
		_roll.target = 0.0
	_pitch.step(delta)
	_roll.step(delta)
	var sq := clampf(_squash.step(delta), 0.6, 1.5)
	lean.rotation_degrees = Vector3(_pitch.x, 0, _roll.x)
	lean.scale = Vector3(1.0 / sqrt(sq), sq, 1.0 / sqrt(sq))
	lean.position.y = sin(_t * 40.0) * 0.0025 * move if on_floor else 0.0  # motor vibration

	_carry.light_energy = 0.0 if powered_down else lerpf(0.35, 0.9, clampf(charge * 1.5, 0.0, 1.0))
	if powered_down:
		rig.power_off()
		_glow.light_energy = 0.0
	else:
		rig.set_charge(charge, _t)
	if not rig.ok:
		return
	var turn := clampf(rad_to_deg(yaw_rate) * 0.25, -35.0, 35.0)  # head leads into turns
	if not pose_override.is_empty():
		var o := pose_override
		rig.set_targets(o[0], o[1], o[2], o[3], o[4], o[5], o[6])
	elif not alive:
		rig.set_targets(0.0, 8.0, 32.0, -18.0, -18.0, 8.0, 8.0)
	elif clinging != null or hanging:  # hanging by both claws, body swinging a little as it moves
		var sway := sin(_t * 6.0) * 6.0 * move
		rig.set_targets(turn if is_nan(head_look) else head_look, 0.0, -18.0 if is_nan(head_look) else -4.0, 8.0, 8.0, 160.0 + sway, 160.0 - sway)
	elif grabbing != null:  # both claws forward on the block, head down with effort
		var strain := sin(_t * 9.0) * 3.0 * move
		rig.set_targets(0.0, strain, 14.0, 12.0, 12.0, 75.0, 75.0)
	elif not on_floor:
		var rising := velocity.y > 0.0
		rig.set_targets(turn, 0.0, -10.0 if rising else 8.0, 55.0 if rising else 75.0, 55.0 if rising else 75.0,
			-15.0 if rising else 10.0, -15.0 if rising else 10.0)
	elif move > 0.08:
		_phase += v_fwd * delta * 5.0
		var sw := sin(_phase) * 16.0 * move - _acc_fwd * 2.5
		rig.set_targets(turn, -turn * 0.25, 5.0 * move + droop * 0.6, 7.0 - droop, 7.0 - droop, sw, -sin(_phase) * 16.0 * move - _acc_fwd * 2.5)
	else:
		var look := sin(_t * 0.37) * 14.0 + sin(_t * 0.91) * 5.0  # idle look-around
		rig.set_targets(look, sin(_t * 0.6) * 5.0, droop * 0.8 + sin(_t * 1.7) * 1.5, 3.0 - droop, 3.0 - droop,
			sin(_t * 1.7) * 2.0, sin(_t * 1.7 + 0.5) * 2.0)
	rig.update(delta)

	# tracks: each side travels forward speed +- turning (skid steer), wheels spin with them
	var d := v_fwd * delta
	var diff := yaw_rate * 0.24 * delta
	rig.drive_tracks(d - diff, d + diff)
	_key_deg += delta * (40.0 + 260.0 * move)
	rig.spin_key(_key_deg)
