class_name RobotRig
extends RefCounted
## Drives the rigid parts of robot_parts_v2.glb and adds the procedural glowing eyes + battery cells.
## Every joint follows its target through a damped spring, so poses blend, overshoot slightly and
## settle (follow-through) instead of snapping. kick_*() adds an impulse for secondary motion.
## Tracks: wheels spin and the belt crawls round its loop (shaders/track_belt.gdshader).

const CELL_COUNT := 5
const CYAN := Color(0.25, 1.0, 0.95)
const AMBER := Color(1.0, 0.6, 0.12)
const RED := Color(1.0, 0.12, 0.08)
const BELT_SHADER := preload("res://shaders/track_belt.gdshader")
const WHEEL_RADIUS := [0.07, 0.08, 0.07]

class Spring:
	var x := 0.0
	var v := 0.0
	var target := 0.0
	var k := 0.0
	var d := 0.0
	func _init(stiffness: float, damping_ratio: float) -> void:
		k = stiffness
		d = 2.0 * damping_ratio * sqrt(stiffness)
	func step(dt: float) -> float:
		var h := dt
		while h > 0.0:  # sub-step for stability at low frame rates
			var s := minf(h, 1.0 / 120.0)
			v += (k * (target - x) - d * v) * s
			x += v * s
			h -= s
		return x
	func snap(val: float) -> void:
		x = val
		target = val
		v = 0.0

var body: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var key: Node3D
var belts := {}   # "L"/"R" -> ShaderMaterial
var wheels := {"L": [], "R": []}
var eyes: Array[MeshInstance3D] = []
var eye_light: OmniLight3D
var cells: Array[MeshInstance3D] = []
var ok := false

# springs (degrees): head is quick and bouncy, arms are looser and lag more
var head_yaw := Spring.new(160.0, 0.45)
var head_tilt := Spring.new(140.0, 0.4)
var head_nod := Spring.new(180.0, 0.35)
var lift_l := Spring.new(90.0, 0.4)
var lift_r := Spring.new(90.0, 0.4)
var swing_l := Spring.new(110.0, 0.35)
var swing_r := Spring.new(110.0, 0.35)

var eye_offset := Vector3(0.105, 0.155, 0.236)
## Battery cells, Body-local: (x, y, surface z) of each modelled cell's back-most point, measured
## from the teal texture faces with tools/blender/measure_cells.py. The pack is slightly slanted.
var cell_surfaces: Array[Vector3] = [Vector3(-0.1355, 0.4229, -0.1316), Vector3(-0.068, 0.4249, -0.1423),
	Vector3(0.0006, 0.4266, -0.1572), Vector3(0.0757, 0.4233, -0.1778), Vector3(0.1492, 0.4229, -0.191)]
var cell_radius := 0.022
var cell_height := 0.09
var _belt_dist := {"L": 0.0, "R": 0.0}

func _init(model: Node) -> void:
	body = model.find_child("Body", true, false)
	head = model.find_child("Head", true, false)
	arm_l = model.find_child("Arm_L", true, false)
	arm_r = model.find_child("Arm_R", true, false)
	key = model.find_child("WindKey", true, false)
	ok = body != null and head != null and arm_l != null and arm_r != null
	if not ok:
		push_warning("[rig] model has no separate parts; only whole-body motion available")
		return
	for side in ["L", "R"]:
		for i in 3:
			var w: Node3D = model.find_child("Wheel_%s%d" % [side, i + 1], true, false)
			if w:
				wheels[side].append(w)
		var belt := model.find_child("Belt_" + side, true, false) as MeshInstance3D
		if belt:
			belts[side] = _belt_material(belt)
	_paint(model)
	_make_eyes()
	_make_cells()

## Smooth tin-toy enamel over every painted part (not the belts, which have their own scrolling shader).
func _paint(model: Node) -> void:
	var shader := preload("res://shaders/tin_paint.gdshader")
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		if mi.name.begins_with("Belt_") or mi.material_override != null:
			continue
		var src := (mi as MeshInstance3D).get_active_material(0) as BaseMaterial3D
		if src == null or src.albedo_texture == null:
			continue
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("albedo_tex", src.albedo_texture)
		var rubber: bool = mi.name.begins_with("Wheel") or mi.name.begins_with("Track")
		m.set_shader_parameter("roughness", 0.7 if rubber else 0.52)
		m.set_shader_parameter("metallic", 0.0 if rubber else 0.05)
		mi.material_override = m

func _belt_material(mi: MeshInstance3D) -> ShaderMaterial:
	var src := mi.get_active_material(0) as BaseMaterial3D
	var m := ShaderMaterial.new()
	m.shader = BELT_SHADER
	if src:
		m.set_shader_parameter("albedo_tex", src.albedo_texture)
		m.set_shader_parameter("normal_tex", src.normal_texture)
		m.set_shader_parameter("rm_tex", src.roughness_texture)
	mi.material_override = m
	mi.extra_cull_margin = 0.1  # vertices move in the shader
	return m

func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m

func _make_eyes() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = 0.032
	disc.bottom_radius = 0.032
	disc.height = 0.004
	for sx in [-1, 1]:
		var e := MeshInstance3D.new()
		e.mesh = disc
		e.material_override = _emissive(CYAN, 2.2)
		e.position = Vector3(eye_offset.x * sx, eye_offset.y, eye_offset.z)
		e.rotation_degrees.x = 90
		head.add_child(e)
		eyes.append(e)
	eye_light = OmniLight3D.new()
	eye_light.light_color = CYAN
	eye_light.light_energy = 0.25
	eye_light.omni_range = 1.0
	eye_light.position = Vector3(0, eye_offset.y, eye_offset.z + 0.12)
	head.add_child(eye_light)

func _make_cells() -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = cell_radius
	cyl.bottom_radius = cell_radius
	cyl.height = cell_height
	for i in CELL_COUNT:
		var c := MeshInstance3D.new()
		c.mesh = cyl
		c.material_override = _emissive(CYAN, 1.15)
		# axis sits one radius inside the measured surface, so the cylinder wraps the modelled cell
		var p := cell_surfaces[i]
		c.position = Vector3(p.x, p.y, p.z + cell_radius - 0.003)
		body.add_child(c)
		cells.append(c)

## charge 0..1 -> lit cells, colour cyan > amber > red, last cell blinks, eyes squint.
func set_charge(charge: float, time: float) -> void:
	if not ok:
		return
	var lit := ceili(charge * CELL_COUNT)
	var col := CYAN if charge > 0.6 else (AMBER if charge > 0.2 else RED)
	for i in CELL_COUNT:
		var on := i < lit
		if on and lit == 1 and fmod(time, 0.8) < 0.3:
			on = false
		var m: StandardMaterial3D = cells[i].material_override
		m.albedo_color = col if on else Color(0.05, 0.06, 0.07)
		m.emission_enabled = on
		m.emission = col
	var open := lerpf(0.35, 1.0, clampf(charge * 1.4, 0.0, 1.0))
	for e in eyes:
		e.scale = Vector3(1.0, 1.0, open)
		(e.material_override as StandardMaterial3D).emission_energy_multiplier = 2.2 * open
	eye_light.light_energy = 0.25 * open

## Out of charge for good (the ending): every cell dark, eyes shut and unlit.
func power_off() -> void:
	if not ok:
		return
	for c in cells:
		var m: StandardMaterial3D = c.material_override
		m.albedo_color = Color(0.05, 0.06, 0.07)
		m.emission_enabled = false
	for e in eyes:
		e.scale = Vector3(1.0, 1.0, 0.3)
		(e.material_override as StandardMaterial3D).emission_energy_multiplier = 0.0
	eye_light.light_energy = 0.0

## Set spring targets (degrees). Arms: lift = sideways, swing = forward(+)/back(-).
func set_targets(yaw: float, tilt: float, nod: float, l_lift: float, r_lift: float, l_swing: float, r_swing: float) -> void:
	head_yaw.target = yaw
	head_tilt.target = tilt
	head_nod.target = nod
	lift_l.target = l_lift
	lift_r.target = r_lift
	swing_l.target = l_swing
	swing_r.target = r_swing

## Snap straight to a pose (used by the static test bench).
func pose(yaw: float, tilt: float, l_lift: float, r_lift: float, l_swing: float, r_swing: float) -> void:
	set_targets(yaw, tilt, 0.0, l_lift, r_lift, l_swing, r_swing)
	for s in [head_yaw, head_tilt, head_nod, lift_l, lift_r, swing_l, swing_r]:
		s.snap(s.target)
	_apply()

## Impulses (degrees per second) for secondary motion.
func kick_head(nod_v: float, yaw_v := 0.0) -> void:
	head_nod.v += nod_v
	head_yaw.v += yaw_v

func kick_arms(swing_v: float, lift_v := 0.0) -> void:
	swing_l.v += swing_v
	swing_r.v += swing_v
	lift_l.v += lift_v
	lift_r.v += lift_v

func update(dt: float) -> void:
	if not ok:
		return
	for s in [head_yaw, head_tilt, head_nod, lift_l, lift_r, swing_l, swing_r]:
		s.step(dt)
	_apply()

func _apply() -> void:
	head.rotation_degrees = Vector3(head_nod.x, head_yaw.x, head_tilt.x)
	arm_l.rotation_degrees = Vector3(-swing_l.x, 0, lift_l.x)
	arm_r.rotation_degrees = Vector3(-swing_r.x, 0, -lift_r.x)

func spin_key(deg: float) -> void:
	if key:
		key.rotation_degrees.z = deg

## Advance the tracks by the distance each side travelled this frame (metres, + = forward).
func drive_tracks(dist_l: float, dist_r: float) -> void:
	for side in ["L", "R"]:
		var d: float = dist_l if side == "L" else dist_r
		_belt_dist[side] += d
		if belts.has(side):
			(belts[side] as ShaderMaterial).set_shader_parameter("offset", _belt_dist[side])
		var ws: Array = wheels[side]
		for i in ws.size():
			(ws[i] as Node3D).rotation.x += d / WHEEL_RADIUS[i]

## Kept for the static test bench: drive both tracks forward at `speed` m/s.
func track_rumble(_time: float, speed: float, dt := 1.0 / 60.0) -> void:
	drive_tracks(speed * dt, speed * dt)
