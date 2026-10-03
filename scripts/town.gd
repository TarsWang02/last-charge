class_name Town
extends Node3D
## The little country town around the farmhouse, seen through the windows and in the ending's aerial
## shot. Low detail and cheap: everything is drawn by seven MultiMeshes, one per kind of mesh (boxes,
## roofs, cones, spheres, cylinders, the lights and the lamplight pools on the ground), each instance
## carrying its own colour - about seven draw calls for the whole town, no shadows. Each lit window /
## street lamp is an instance of the light MultiMesh whose colour fades between "on" and "off".
## The layout is drawn in "layout units" (1 = SPREAD metres); everything is scaled by K * SPREAD.
## The town has its own distance haze (shaders/town.gdshader); the sky is shaders/night_sky.gdshader.

const K := 9.0
const LIGHT_OFF := Color(0.004, 0.005, 0.009)
const KEEP_OUT := Rect2(-5.6, -3.4, 11.8, 7.2)   ## the farmhouse and its yard (x, z in layout units)
const SPREAD := 4.0   ## the layout below is drawn small; everything is scaled up by this to real-world size
                      ## (houses 3-6 m, lamps 5 m, the nearest neighbour ~16 m from the farmhouse)
const ROAD_Z := 7.5   ## the main road, east-west
const STREET_X := 7.0 ## the village street, running south from the main road
const GROUND_Y := -0.0175   ## the ground's top (layout units; -7 cm)
const WARM := [Color(1.0, 0.72, 0.38), Color(1.0, 0.8, 0.5), Color(1.0, 0.86, 0.64), Color(0.98, 0.62, 0.3)]
const TV := Color(0.5, 0.66, 1.0)
const WALLS := [Color(0.62, 0.6, 0.55), Color(0.6, 0.52, 0.38), Color(0.55, 0.42, 0.25), Color(0.46, 0.24, 0.17),
	Color(0.38, 0.44, 0.38), Color(0.4, 0.44, 0.52), Color(0.38, 0.28, 0.19), Color(0.66, 0.64, 0.6)]
const ROOFS := [Color(0.16, 0.17, 0.21), Color(0.4, 0.16, 0.12), Color(0.27, 0.18, 0.13), Color(0.19, 0.23, 0.17),
	Color(0.26, 0.26, 0.29), Color(0.34, 0.2, 0.15)]

var lights_x := PackedFloat32Array()      ## each light's x (layout units), for "lights go out as the robot passes"
var _on := PackedColorArray()             ## each light's colour when lit
var _cur := PackedFloat32Array()
var _target := PackedFloat32Array()
var _pool_of := {}                        ## light index -> lamplight pool index
var _lights: MultiMeshInstance3D
var _pools: MultiMeshInstance3D
var _sky: ShaderMaterial
var _glow_lit := Color(0.16, 0.14, 0.17)  ## the warm band of town light along the horizon, fading with the lights
var _animating := false
var _rng := RandomNumberGenerator.new()

# instances per mesh kind: [[Transform3D (layout units), Color], ...]
var _box := []
var _roof := []
var _cone := []
var _ball := []
var _cyl := []
var _light := []   # [Transform3D, Color, x]
var _pool := []    # [Transform3D, light index]
var _spots := []   # house footprints, Vector3(x, z, radius), so nothing overlaps

func build(seed_ := 1949) -> void:
	_rng.seed = seed_
	_ground()
	_church(Vector3(STREET_X + 2.2, 0, 16.5))
	_village()
	_lamps()
	_power_line()
	_farmyard()
	_trees()
	_hills()
	_emit()

# ------------------------------------------------------------------ layout
func _ground() -> void:
	_add_box(Vector3(0, GROUND_Y - 0.005, 0), Vector3(150, 0.01, 150), Color(0.075, 0.09, 0.075))
	# a patchwork of fields with hedgerows, all around the outskirts
	var fields := [Color(0.11, 0.14, 0.08), Color(0.15, 0.12, 0.085), Color(0.19, 0.18, 0.12), Color(0.09, 0.12, 0.09),
		Color(0.13, 0.15, 0.1)]
	for i in 46:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(9.0, 34.0)
		var c := Vector3(cos(a) * r, 0, sin(a) * r)
		if c.z > 4.0 and c.z < 22.0 and c.x > -16.0 and c.x < 20.0:
			continue  # the village itself sits on plain ground
		var size := Vector3(_rng.randf_range(3.0, 7.0), 0.004, _rng.randf_range(2.0, 5.0))
		var yaw := _rng.randf_range(-0.25, 0.25)
		var y := GROUND_Y + 0.002 + (i % 4) * 0.003
		_add_box(c + Vector3(0, y, 0), size, fields[i % fields.size()], yaw)
		var b := Basis(Vector3.UP, yaw)
		_add_box(c + b * Vector3(0, 0.05, size.z / 2.0), Vector3(size.x, 0.14, 0.14), Color(0.05, 0.08, 0.06), yaw)
	# roads: the main road, the village street, the farm's own dirt lane down to the road
	var road := Color(0.17, 0.165, 0.15)
	_add_box(Vector3(2.0, GROUND_Y + 0.01, ROAD_Z), Vector3(80, 0.004, 0.9), road)
	_add_box(Vector3(STREET_X, GROUND_Y + 0.011, 18.0), Vector3(0.8, 0.004, 21.0), road)
	_add_box(Vector3(1.6, GROUND_Y + 0.009, 4.6), Vector3(0.5, 0.004, 5.8), Color(0.15, 0.13, 0.1))

## Houses lining the main road and the village street, and a few farms out in the fields.
func _village() -> void:
	var x := -16.0
	while x < 20.0:   # along the main road, both sides, facing it
		for side in [-1.0, 1.0]:
			if _rng.randf() < 0.8:
				_house(Vector3(x + _rng.randf_range(-0.3, 0.3), 0, ROAD_Z + side * _rng.randf_range(1.5, 2.1)), PI if side > 0.0 else 0.0)
		x += _rng.randf_range(1.9, 2.7)
	var z := ROAD_Z + 2.6
	while z < 27.0:   # the village street
		for side in [-1.0, 1.0]:
			if _rng.randf() < 0.85:
				_house(Vector3(STREET_X + side * _rng.randf_range(1.4, 2.0), 0, z + _rng.randf_range(-0.3, 0.3)), -PI / 2.0 * side)
		z += _rng.randf_range(1.9, 2.5)
	for i in 14:      # scattered farms
		var p := Vector3(_rng.randf_range(-16.0, 19.0), 0, _rng.randf_range(-14.0, 26.0))
		if p.z < 0.0 and p.z > -14.0 and absf(p.x) < 4.0:
			continue   # nothing right behind the farmhouse: it stands clear in the ending's last shot
		_house(p, _rng.randf() * TAU, true)

## One house: walls, a pitched roof, maybe a chimney, a door, and windows - some lit, some dark.
## yaw turns the front (+z local) to face the road.
func _house(p: Vector3, yaw: float, farm := false) -> void:
	var w := _rng.randf_range(1.0, 1.7)
	var d := _rng.randf_range(0.8, 1.15)
	var h := _rng.randf_range(0.7, 1.05)
	if KEEP_OUT.grow(0.4).has_point(Vector2(p.x, p.z)) or absf(p.z - ROAD_Z) < 1.1 or absf(p.x - STREET_X) < 1.0 and p.z > ROAD_Z \
			or absf(p.x - 1.6) < 1.3 and p.z < ROAD_Z + 3.0:   # (the farm lane, and a gap opposite it)
		return
	for s in _spots:
		if Vector2(s.x - p.x, s.y - p.z).length() < s.z + w * 0.62:
			return
	_spots.append(Vector3(p.x, p.z, w * 0.62))
	yaw += _rng.randf_range(-0.08, 0.08)
	var b := Basis(Vector3.UP, yaw)
	var wall: Color = WALLS[_rng.randi() % WALLS.size()]
	_add_box(p + Vector3(0, h / 2.0 - 0.06, 0), Vector3(w, h, d), wall.darkened(0.2 + _rng.randf() * 0.15), yaw)
	var rh := _rng.randf_range(0.38, 0.6)
	var rc: Color = ROOFS[_rng.randi() % ROOFS.size()]
	_roof.append([Transform3D(Basis(Vector3.UP, yaw + PI / 2.0).scaled_local(Vector3(d * 1.18, rh, w * 1.08)),
		p + Vector3(0, h - 0.06 + rh / 2.0, 0)), rc])
	_add_box(p + Vector3(0, GROUND_Y + 0.004, 0) + b * Vector3(0, 0, -d * 0.55), Vector3(w * 1.5, 0.004, d * 1.9),
		Color(0.085, 0.115, 0.075).lightened(_rng.randf() * 0.05), yaw)   # its garden, out the back
	if _rng.randf() < 0.65:
		_add_box(p + b * Vector3(_rng.randf_range(-0.3, 0.3) * w, h + rh * 0.55, _rng.randf_range(-0.1, 0.1) * d),
			Vector3(0.11, 0.42, 0.11), wall.darkened(0.35), yaw)
	_add_box(p + b * Vector3(_rng.randf_range(-0.25, 0.25) * w, 0.11, d / 2.0 + 0.008), Vector3(0.16, 0.34, 0.02),
		Color(0.12, 0.08, 0.06), yaw)
	var lit_chance := 0.45 if farm else 0.6
	for face in [1.0, -1.0]:   # windows front and back, ground floor (and an upper one under the roof when tall)
		var n := 3 if w > 1.35 else 2
		for j in n:
			var u := (j - (n - 1) / 2.0) * w / n
			if face > 0.0 and absf(u) < 0.14:
				continue   # the door is here
			_window(p, b, Vector3(u, 0.24, face * (d / 2.0 + 0.012)), yaw, lit_chance)
		if h > 0.9:
			_window(p, b, Vector3(0, h - 0.26, face * (d / 2.0 + 0.012)), yaw, lit_chance * 0.6)

func _window(p: Vector3, b: Basis, local: Vector3, yaw: float, lit_chance: float) -> void:
	var at := p + b * local
	if _rng.randf() < lit_chance:
		var c: Color = TV if _rng.randf() < 0.07 else WARM[_rng.randi() % WARM.size()]
		_light.append([Transform3D(b.scaled_local(Vector3(0.17, 0.2, 0.02)), at), c, p.x])
	else:
		_add_box(at, Vector3(0.17, 0.2, 0.02), Color(0.03, 0.04, 0.06), yaw)

## The church at the end of the village street: a nave and a tower with a steeple (the skyline's landmark).
func _church(c: Vector3) -> void:
	var white := Color(0.64, 0.63, 0.6)
	_add_box(c + Vector3(0, 0.74, 0), Vector3(1.3, 1.6, 2.6), white)
	_roof.append([Transform3D(Basis().scaled_local(Vector3(1.45, 0.8, 2.75)), c + Vector3(0, 1.94, 0)), Color(0.17, 0.18, 0.22)])
	var tower := c + Vector3(0, 0, -1.6)
	_add_box(tower + Vector3(0, 1.54, 0), Vector3(0.7, 3.2, 0.7), white)
	_cone.append([Transform3D(Basis(Vector3.UP, PI / 4.0).scaled_local(Vector3(0.95, 1.9, 0.95)), tower + Vector3(0, 4.05, 0)),
		Color(0.17, 0.18, 0.22)])
	for i in 3:   # tall lit windows down the nave's west side (facing the street), the clock face on the tower
		_light.append([Transform3D(Basis().scaled_local(Vector3(0.02, 0.5, 0.2)), c + Vector3(-0.66, 0.85, -0.7 + i * 0.7)),
			Color(1.0, 0.62, 0.32), c.x])
	_light.append([Transform3D(Basis().scaled_local(Vector3(0.3, 0.3, 0.02)), tower + Vector3(0, 2.7, -0.36)),
		Color(1.0, 0.92, 0.75), c.x])
	_spots.append(Vector3(c.x, c.z - 0.6, 2.0))

## Street lamps along both roads, each with a pool of light on the ground.
func _lamps() -> void:
	var spots := []
	for i in 15:
		spots.append(Vector3(-14.5 + i * 2.4, 0, ROAD_Z + 0.65))
	for i in 7:
		spots.append(Vector3(STREET_X - 0.6, 0, ROAD_Z + 2.0 + i * 2.6))
	for p in spots:
		_add_box(p + Vector3(0, 0.6, 0), Vector3(0.045, 1.3, 0.045), Color(0.12, 0.12, 0.14))
		_pool.append([Transform3D(Basis().scaled_local(Vector3(2.4, 1.0, 2.4)), p + Vector3(0, 0.04, 0)), _light.size()])
		_light.append([Transform3D(Basis().scaled_local(Vector3(0.16, 0.1, 0.16)), p + Vector3(0, 1.28, 0)), Color(1.0, 0.82, 0.55), p.x])

## Telegraph poles carrying the farmhouse's line from the road up the lane to its south-east corner -
## in the ending, the one line that still leads to a lit house.
func _power_line() -> void:
	var poles := [Vector3(1.55, 0, 2.0), Vector3(1.55, 0, 4.3), Vector3(1.55, 0, 6.7)]
	for i in range(1, 8):
		poles.append(Vector3(1.55 + i * 2.5, 0, 6.7))
	for i in range(1, 8):
		poles.append(Vector3(1.55 - i * 2.5, 0, 6.7))
	var pole_h := 2.1
	var tops := []
	for i in poles.size():
		var p: Vector3 = poles[i]
		var along := Vector3(0, 0, 1) if i < 3 else Vector3(1, 0, 0)
		var yaw := atan2(along.x, along.z)
		_add_box(p + Vector3(0, pole_h / 2.0 - 0.05, 0), Vector3(0.05, pole_h, 0.05), Color(0.13, 0.1, 0.08))
		_add_box(p + Vector3(0, pole_h - 0.2, 0), Vector3(0.55, 0.035, 0.035), Color(0.13, 0.1, 0.08), yaw)
		tops.append([p + Vector3(0, pole_h - 0.18, 0), Basis(Vector3.UP, yaw) * Vector3(1, 0, 0)])
	var house := Vector3(1.19, 0.66, 0.66)   # the farmhouse's south-east eave (layout units)
	_wire(house, tops[0][0], 0.04)
	var spans := [[0, 1], [1, 2], [2, 3]]
	for i in range(3, 9):
		spans.append([i, i + 1])
	spans.append([2, 10])
	for i in range(10, 16):
		spans.append([i, i + 1])
	for s in spans:
		var a: Array = tops[s[0]]
		var c: Array = tops[s[1]]
		for k in [-0.22, 0.0, 0.22]:
			_wire(a[0] + a[1] * k, c[0] + c[1] * k, 0.09)

## A sagging wire from a to b, as two straight halves.
func _wire(a: Vector3, b: Vector3, sag: float) -> void:
	var mid := (a + b) / 2.0 - Vector3(0, sag, 0)
	for seg in [[a, mid], [mid, b]]:
		var p: Vector3 = seg[0]
		var q: Vector3 = seg[1]
		var dir := q - p
		var z := dir.normalized()
		var x := Vector3.UP.cross(z).normalized()
		var y := z.cross(x)
		_box.append([Transform3D(Basis(x * 0.012, y * 0.012, z * dir.length()), (p + q) / 2.0), Color(0.05, 0.05, 0.06)])

## Behind the farmhouse: a barn and a silo, a windpump, a row of poplars against the moon.
func _farmyard() -> void:
	var barn := Vector3(-9.0, 0, -7.0)
	_add_box(barn + Vector3(0, 0.55, 0), Vector3(2.2, 1.2, 1.4), Color(0.42, 0.15, 0.11))
	_roof.append([Transform3D(Basis(Vector3.UP, PI / 2.0).scaled_local(Vector3(1.6, 0.75, 2.35)), barn + Vector3(0, 1.52, 0)),
		Color(0.2, 0.2, 0.23)])
	_add_box(barn + Vector3(0.3, 0.36, 0.71), Vector3(0.7, 0.75, 0.02), Color(0.3, 0.1, 0.08))
	_light.append([Transform3D(Basis().scaled_local(Vector3(0.12, 0.08, 0.12)), barn + Vector3(0.3, 0.84, 0.75)), Color(1.0, 0.85, 0.6), barn.x])
	var silo := Vector3(-7.3, 0, -7.6)
	_cyl.append([Transform3D(Basis().scaled_local(Vector3(0.85, 2.3, 0.85)), silo + Vector3(0, 1.1, 0)), Color(0.5, 0.5, 0.52)])
	_ball.append([Transform3D(Basis().scaled_local(Vector3(0.85, 0.6, 0.85)), silo + Vector3(0, 2.25, 0)), Color(0.4, 0.42, 0.45)])
	# the windpump: four legs leaning in, a platform, the wheel and its tail vane
	var wp := Vector3(3.8, 0, -11.0)
	var dark := Color(0.16, 0.16, 0.18)
	for corner in [Vector3(1, 0, 1), Vector3(-1, 0, 1), Vector3(1, 0, -1), Vector3(-1, 0, -1)]:
		var foot: Vector3 = wp + corner * 0.32
		var top: Vector3 = wp + corner * 0.06 + Vector3(0, 2.6, 0)
		var up := (top - foot)
		var y := up.normalized()
		var x := y.cross(Vector3(0, 0, 1)).normalized()
		var z := x.cross(y)
		_box.append([Transform3D(Basis(x * 0.035, y * up.length(), z * 0.035), (foot + top) / 2.0), dark])
	_add_box(wp + Vector3(0, 2.6, 0), Vector3(0.22, 0.04, 0.22), dark)
	_cyl.append([Transform3D(Basis(Vector3.RIGHT, PI / 2.0).scaled_local(Vector3(1.0, 0.03, 1.0)), wp + Vector3(0, 2.85, 0.12)), dark])
	_add_box(wp + Vector3(0, 2.85, -0.45), Vector3(0.02, 0.22, 0.7), dark)
	# the poplars: a windbreak along the field north of the house
	var x0 := -9.0
	while x0 < 6.0:
		var s := _rng.randf_range(0.85, 1.15)
		_cone.append([Transform3D(Basis().scaled_local(Vector3(0.8 * s, 1.6 * s, 0.8 * s)), Vector3(x0, 0.2 + 0.8 * s, -12.0)),
			Color(0.05, 0.09, 0.07).lightened(_rng.randf() * 0.06)])
		x0 += _rng.randf_range(0.7, 1.0)

## Conifers and round trees: around the village gardens, along the edges, clumps in the fields.
func _trees() -> void:
	for i in 150:
		var t := Vector2(_rng.randf_range(-22.0, 26.0), _rng.randf_range(-22.0, 30.0))
		if t.y < -3.0 and t.y > -11.0 and absf(t.x + 0.8) < 6.0:
			continue   # keep the view from the bedroom's north window open
		if KEEP_OUT.grow(0.5).has_point(t) or absf(t.y - ROAD_Z) < 0.8 or absf(t.x - STREET_X) < 0.7 and t.y > ROAD_Z:
			continue
		var blocked := false
		for s in _spots:
			if Vector2(s.x - t.x, s.y - t.y).length() < s.z + 0.3:
				blocked = true
				break
		if blocked:
			continue
		var s := _rng.randf_range(0.5, 1.1)
		_add_box(Vector3(t.x, 0.14, t.y), Vector3(0.1, 0.4, 0.1), Color(0.14, 0.1, 0.07))
		if _rng.randf() < 0.55:
			_cone.append([Transform3D(Basis().scaled_local(Vector3(s, s * 1.9, s)), Vector3(t.x, 0.25 + s * 0.95, t.y)),
				Color(0.05, 0.1, 0.075).lightened(_rng.randf() * 0.07)])
		else:
			_ball.append([Transform3D(Basis().scaled_local(Vector3(s * 1.2, s * 1.0, s * 1.2)), Vector3(t.x, 0.35 + s * 0.45, t.y)),
				Color(0.09, 0.14, 0.07).lightened(_rng.randf() * 0.08)])

## Two rings of hills on the horizon, the far one higher and bluer (the haze does the rest).
func _hills() -> void:
	for ring in [[14, 30.0, 37.0, 2.0, 5.0, Color(0.05, 0.07, 0.065)], [18, 48.0, 58.0, 5.0, 11.0, Color(0.05, 0.06, 0.09)]]:
		var n: int = ring[0]
		for i in n:
			var a := (i + _rng.randf() * 0.5) * TAU / n
			var r := _rng.randf_range(ring[1], ring[2])
			_ball.append([Transform3D(Basis(Vector3.UP, -a).scaled_local(Vector3(_rng.randf_range(16.0, 26.0), _rng.randf_range(ring[3], ring[4]), 7.0)),
				Vector3(cos(a) * r, 0.0, sin(a) * r)), ring[5]])

func _add_box(p: Vector3, size: Vector3, c: Color, yaw := 0.0) -> void:
	_box.append([Transform3D(Basis(Vector3.UP, yaw).scaled_local(size), p), c])

# ------------------------------------------------------------------ meshes
func _emit() -> void:
	var lit := ShaderMaterial.new()
	lit.shader = preload("res://shaders/town.gdshader")
	_multi(BoxMesh.new(), _box, lit)
	_multi(PrismMesh.new(), _roof, lit)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.radial_segments = 6
	cone.rings = 1
	cone.height = 1.0
	_multi(cone, _cone, lit)
	var ball := SphereMesh.new()
	ball.radius = 0.5
	ball.height = 1.0
	ball.radial_segments = 10
	ball.rings = 6
	_multi(ball, _ball, lit)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 12
	cyl.rings = 1
	_multi(cyl, _cyl, lit)
	# the lights, and the pools under the lamps
	var lm := ShaderMaterial.new()
	lm.shader = preload("res://shaders/town_light.gdshader")
	for l in _light:
		lights_x.append(l[2])
		_on.append(l[1])
		_cur.append(1.0)
		_target.append(1.0)
	_lights = _multi(BoxMesh.new(), _light, lm)
	var pm := ShaderMaterial.new()
	pm.shader = preload("res://shaders/town_pool.gdshader")
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE
	var pools := []
	for i in _pool.size():
		_pool_of[_pool[i][1]] = i
		pools.append([_pool[i][0], _on[_pool[i][1]]])
	_pools = _multi(quad, pools, pm)
	var env_node := get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment and env_node.environment.sky:
		_sky = env_node.environment.sky.sky_material as ShaderMaterial

func _multi(mesh: Mesh, items: Array, mat: Material) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = items.size()
	for i in items.size():
		var t: Transform3D = items[i][0]
		mm.set_instance_transform(i, Transform3D(t.basis * K * SPREAD, t.origin * K * SPREAD))
		mm.set_instance_color(i, items[i][1])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

# ------------------------------------------------------------------ lights
func light_count() -> int:
	return lights_x.size()

func lit_count() -> int:
	var n := 0
	for v in _target:
		if v > 0.5:
			n += 1
	return n

## Lights east of x (layout units) go out (each fades on its own).
func lights_off_east_of(x: float) -> void:
	for i in lights_x.size():
		if _target[i] > 0.5 and lights_x[i] > x:
			_target[i] = 0.0
			_animating = true

func set_all(on: bool) -> void:
	for i in _target.size():
		_target[i] = 1.0 if on else 0.0
	_animating = true

func _process(delta: float) -> void:
	if not _animating:
		return
	_animating = false
	var total := 0.0
	for i in _cur.size():
		if not is_equal_approx(_cur[i], _target[i]):
			_cur[i] = move_toward(_cur[i], _target[i], delta * 1.8)
			var c := LIGHT_OFF.lerp(_on[i], _cur[i])
			_lights.multimesh.set_instance_color(i, c)
			if _pool_of.has(i):
				_pools.multimesh.set_instance_color(_pool_of[i], _on[i] * _cur[i])
			_animating = true
		total += _cur[i]
	if _sky:   # the town's glow on the horizon fades with its lights
		_sky.set_shader_parameter("glow", Color(0.05, 0.06, 0.09).lerp(_glow_lit, total / maxf(1.0, _cur.size())))
