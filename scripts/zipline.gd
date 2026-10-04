class_name Zipline
extends Node3D
## The clothesline (stop 5, old age). Strung between hooks across the living room - from the kitchen window
## over the room to a hook behind the sofa, back to the window, then along it to the breaker box - and the
## robot rides it hanging from a wire coat hanger whose hook runs on the line. Slow -> fast -> slow, easing
## off at each corner hook. All in world units (the node sits at the origin).
##   A / D  swing left / right under the line (a pendulum) - hanging things (a dead lamp, plants, a chime,
##          a birdcage) hang on one side or the other: swing away from them or bump into them (slower).
##   jump   just before a clothes peg: the hook hops over it (otherwise it catches: slower for a moment).
## Washing hangs across the line, facing the robot: it crashes through it (no penalty, just spectacle).

signal reached(u: float)   ## once at each of `marks` (the two slow looks)
signal finished
signal clacked              ## caught on a peg or bumped into something

@export var points := PackedVector3Array()     ## the line's hooks, start -> end
@export var sags := PackedFloat32Array()       ## how far each span hangs down in the middle
@export var hanger_drop := 1.8                 ## line -> the hanger's bar
@export var pegs := PackedFloat32Array([0.12, 0.31, 0.59, 0.76])
@export var garments := PackedFloat32Array([0.07, 0.17, 0.27, 0.38, 0.55, 0.64, 0.71, 0.8])
@export var hanging := [[0.14, -1, "lamp"], [0.22, 1, "plant"], [0.35, -1, "chime"], [0.52, 1, "cage"],
	[0.62, -1, "lamp"], [0.68, 1, "plant"], [0.78, -1, "chime"]]   ## [u, side (+1 = right), kind]
@export var marks := PackedFloat32Array([0.43, 0.87])  ## slow looks: into the room (crossing it), out of the window
@export var mark_u := 0.87                            ## the last one: the battery is down to its last cell here
@export var v_min := 0.9
@export var v_max := 4.2
@export var ceiling := 24.3                     ## ceiling height (units), where hanging things hang from

const ROBOT_HANG := 0.92                       ## bar -> the robot's feet
var u := 0.0
var riding := false
var rider: CharacterBody3D
var hops := 0
var clacks := 0
var bumps := 0
var ride_seconds := 0.0
var swing := 0.0                                ## pendulum angle (rad, + = to the right)
var hanger: Node3D
var wires: Array[Node3D] = []                  ## the hanger's slanted wires + hook (hidden in first person)
var bar: Node3D                                 ## the bar the robot holds
var corners := PackedFloat32Array()             ## u of each corner hook
var hang_nodes: Array[Node3D] = []
var _cum := PackedFloat32Array()                ## cumulative length at each point
var _len := 1.0
var _mult := 1.0
var _swing_v := 0.0
var _jump_buf := 0.0
var _next_peg := 0
var _next_hang := 0
var _hop := 0.0
var _next_mark := 0
var _garments: Array[Node3D] = []

# ------------------------------------------------------------------ the line
func point(t: float) -> Vector3:
	var d := clampf(t, -0.2, 1.2) * _len
	var i := 0
	while i < points.size() - 2 and d > _cum[i + 1]:
		i += 1
	var k := (d - _cum[i]) / (_cum[i + 1] - _cum[i])
	var p := points[i].lerp(points[i + 1], k)
	var kk := clampf(k, 0.0, 1.0)
	p.y -= (sags[i] if i < sags.size() else 0.0) * 4.0 * kk * (1.0 - kk)
	return p

func direction(t: float) -> Vector3:
	var d := point(t + 0.004) - point(t - 0.004)
	d.y = 0.0
	return d.normalized()

func right_axis(t: float) -> Vector3:
	return direction(t).cross(Vector3.UP).normalized()

## Speed along the line: picks up, fastest around the middle, eases off at each corner, crawls at the end.
func profile(t: float) -> float:
	var v := v_min + (v_max - v_min) * pow(maxf(sin(clampf(t / 0.93, 0.0, 1.0) * PI), 0.0), 0.6)
	for c in corners:
		var dc := absf(t - c)
		if dc < 0.05:
			v *= lerpf(0.45, 1.0, dc / 0.05)
	return v

# ------------------------------------------------------------------ build
func _ready() -> void:
	_cum.append(0.0)
	for i in range(1, points.size()):
		_cum.append(_cum[i - 1] + points[i - 1].distance_to(points[i]))
	_len = _cum[_cum.size() - 1]
	for i in range(1, points.size() - 1):
		corners.append(_cum[i] / _len)
	var cord := _mat(Color(0.78, 0.75, 0.68))
	var a := point(-0.03)
	for i in 80:
		var b := point(-0.03 + (i + 1) * 1.06 / 80.0)
		_seg(self, a, b, 0.035, cord)
		a = b
	for i in range(1, points.size() - 1):  # corner hooks: a little pulley hanging from the ceiling
		_seg(self, points[i], Vector3(points[i].x, ceiling, points[i].z), 0.03, cord)
		var wheel := _box(Vector3(0.08, 0.3, 0.3), points[i] + Vector3(0, 0.1, 0), Color(0.5, 0.5, 0.52))
		wheel.look_at(wheel.global_position + direction(_cum[i] / _len), Vector3.UP)
	for t in pegs:
		_box(Vector3(0.12, 0.35, 0.1), point(t) + Vector3(0, -0.05, 0), Color(0.75, 0.55, 0.3))
	_build_garments()
	_build_hanging()
	# the hanger: hook on the line, two slanted wires, the bar the robot holds (built across local X)
	hanger = Node3D.new()
	add_child(hanger)
	var wire := _mat(Color(0.6, 0.62, 0.66))
	for s in [-1.0, 1.0]:
		wires.append(_seg(hanger, Vector3(0, -0.25, 0), Vector3(s * 1.0, -hanger_drop, 0), 0.04, wire))
	bar = _seg(hanger, Vector3(-1.0, -hanger_drop, 0), Vector3(1.0, -hanger_drop, 0), 0.05, wire)
	wires.append(_seg(hanger, Vector3(0, 0.05, 0), Vector3(0, -0.25, 0), 0.04, wire))
	_place_hanger()

## Washing hung ACROSS the line, facing the robot: it crashes straight through each piece.
func _build_garments() -> void:
	var cols := [[Color(0.85, 0.82, 0.72), Color(0.6, 0.65, 0.78)], [Color(0.55, 0.62, 0.78), Color(0.9, 0.9, 0.88)],
		[Color(0.72, 0.38, 0.33), Color(0.85, 0.75, 0.6)], [Color(0.6, 0.66, 0.5), Color(0.4, 0.45, 0.35)],
		[Color(0.78, 0.7, 0.55), Color(0.62, 0.45, 0.35)]]
	for i in garments.size():
		var g := Node3D.new()  # pivot on the line; the cloth hangs below it, its face towards the robot
		add_child(g)
		g.global_position = point(garments[i])
		g.look_at(g.global_position + direction(garments[i]), Vector3.UP)
		var c: Array = cols[i % cols.size()]
		var w := 2.2 + (i % 3) * 0.4
		var cloth := _box(Vector3(w, 2.6, 0.06), Vector3.ZERO, c[0], g)
		cloth.position = Vector3(0, -1.3, 0)
		var stripe := _box(Vector3(w, 0.4, 0.07), Vector3.ZERO, c[1], g)  # a band of colour, so it reads as cloth
		stripe.position = Vector3(0, -0.7 - (i % 2) * 1.0, 0)
		_garments.append(g)

## Things hanging from the ceiling on one side of the line, at the robot's height: swing away from them.
func _build_hanging() -> void:
	for h in hanging:
		var t: float = h[0]
		var side: float = h[1]
		var n := Node3D.new()  # pivot at the ceiling
		add_child(n)
		var base := point(t) + right_axis(t) * side * 0.85
		n.global_position = Vector3(base.x, ceiling, base.z)
		var bottom_y := point(t).y - hanger_drop - ROBOT_HANG + 0.1
		var cord_len := ceiling - bottom_y - 1.0
		_seg(n, Vector3.ZERO, Vector3(0, -cord_len, 0), 0.03, _mat(Color(0.25, 0.25, 0.28)))
		var rose := _box(Vector3(0.5, 0.12, 0.5), Vector3.ZERO, Color(0.7, 0.68, 0.62), n)  # where it hangs from the ceiling
		rose.position = Vector3(0, -0.06, 0)
		var top := Vector3(0, -cord_len, 0)
		match h[2]:
			"lamp":  # a dead pendant lamp: a shade and a bulb that doesn't light
				var bx1 := _box(Vector3(1.3, 0.5, 1.3), Vector3.ZERO, Color(0.55, 0.45, 0.32), n)
				bx1.position = top + Vector3(0, -0.35, 0)
				var bx2 := _box(Vector3(0.35, 0.4, 0.35), Vector3.ZERO, Color(0.75, 0.75, 0.7), n)
				bx2.position = top + Vector3(0, -0.75, 0)
			"plant":  # a hanging planter spilling leaves
				var bx3 := _box(Vector3(1.0, 0.6, 1.0), Vector3.ZERO, Color(0.6, 0.35, 0.25), n)
				bx3.position = top + Vector3(0, -0.4, 0)
				for k in 4:
					var leaf := _box(Vector3(0.25, 0.9, 0.12), Vector3.ZERO, Color(0.25, 0.45, 0.25), n)
					leaf.position = top + Vector3((k - 1.5) * 0.3, -0.9, 0.4 * (k % 2) - 0.2)
					leaf.rotation.z = (k - 1.5) * 0.4
			"chime":  # a wind chime: a ring and dangling tubes
				var bx4 := _box(Vector3(1.0, 0.08, 1.0), Vector3.ZERO, Color(0.6, 0.55, 0.45), n)
				bx4.position = top + Vector3(0, -0.1, 0)
				for k in 5:
					var tube := _box(Vector3(0.1, 0.7 + k * 0.08, 0.1), Vector3.ZERO, Color(0.72, 0.74, 0.78), n)
					tube.position = top + Vector3(cos(k * 1.26) * 0.4, -0.5 - k * 0.04, sin(k * 1.26) * 0.4)
			"cage":  # an empty birdcage
				var bx5 := _box(Vector3(1.2, 0.08, 1.2), Vector3.ZERO, Color(0.55, 0.5, 0.35), n)
				bx5.position = top + Vector3(0, -1.0, 0)
				for k in 6:
					var bar := _box(Vector3(0.05, 1.0, 0.05), Vector3.ZERO, Color(0.7, 0.62, 0.4), n)
					bar.position = top + Vector3(cos(k * 1.05) * 0.55, -0.5, sin(k * 1.05) * 0.55)
				var bx6 := _box(Vector3(0.9, 0.15, 0.9), Vector3.ZERO, Color(0.7, 0.62, 0.4), n)
				bx6.position = top + Vector3(0, -0.02, 0)
		n.set_meta("u", t)
		n.set_meta("side", side)
		hang_nodes.append(n)

# ------------------------------------------------------------------ ride
## Where the robot hangs (its feet): below the bar, swung sideways about the line.
func rider_pos() -> Vector3:
	var l := hanger_drop + ROBOT_HANG
	return hanger.global_position + (Vector3.DOWN * cos(swing) + right_axis(u) * sin(swing)) * l

## How far the robot hangs to the right of the line right now (units, - = left).
func lateral() -> float:
	return (rider_pos() - hanger.global_position).dot(right_axis(u))

func ride(r: CharacterBody3D) -> void:
	rider = r
	riding = true
	u = 0.0
	_mult = 1.0
	_next_peg = 0
	_next_hang = 0

func _place_hanger() -> void:
	var dir := direction(u)
	hanger.global_position = point(u) + Vector3(0, sin(_hop / 0.3 * PI) * 0.35 if _hop > 0.0 else 0.0, 0)
	var lean := clampf((profile(u) - v_min) * 0.025 - (1.0 - _mult) * 0.3, -0.3, 0.3)  # trails back with speed
	hanger.global_basis = Basis.looking_at(dir, Vector3.UP) * Basis(Vector3(0, 0, 1), -swing) * Basis(Vector3(1, 0, 0), lean)

func _physics_process(delta: float) -> void:
	_hop = maxf(_hop - delta, 0.0)
	if not riding:
		return
	ride_seconds += delta
	_jump_buf = 0.35 if Input.is_action_just_pressed("jump") else maxf(_jump_buf - delta, 0.0)
	_mult = move_toward(_mult, 1.0, 0.6 * delta)
	# the swing: A / D push the pendulum, gravity brings it back, a little damping
	var push := Input.get_axis("move_left", "move_right")
	_swing_v += (push * 9.0 - sin(swing) * 7.0 - _swing_v * 1.6) * delta
	swing = clampf(swing + _swing_v * delta, -0.95, 0.95)
	var du := profile(u) * _mult * delta / _len
	if _next_peg < pegs.size() and u + du >= pegs[_next_peg]:
		if _jump_buf > 0.0:  # hop the hook over the peg
			hops += 1
			_hop = 0.3
			_jump_buf = 0.0
		else:  # caught on it: a jolt, slower for a while
			clacks += 1
			_mult = 0.3
			du = pegs[_next_peg] - u
			clacked.emit()
		_next_peg += 1
	if _next_hang < hang_nodes.size() and u + du >= float(hang_nodes[_next_hang].get_meta("u")):
		var n := hang_nodes[_next_hang]
		var side: float = n.get_meta("side")
		if lateral() * side > -0.42:  # not swung clearly away from it: bump
			bumps += 1
			_mult = minf(_mult, 0.45)
			_swing_v -= side * 2.5
			clacked.emit()
			_jolt(n, side, 0.6)
		else:  # just past it: it sways in the draught
			_jolt(n, side, 0.15)
		_next_hang += 1
	u = minf(u + du, 1.0)
	_place_hanger()
	if rider:
		rider.global_position = rider_pos()
	for g in _garments:  # crash straight through the washing: it flips up and over
		if not g.has_meta("hit") and g.global_position.distance_to(hanger.global_position) < 0.7:
			g.set_meta("hit", true)
			var rest := g.global_basis
			var axis := g.global_basis.x
			var tw := create_tween()
			tw.tween_method(func(a: float): g.global_basis = Basis(axis, a) * rest, 0.0, -1.9, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_method(func(a: float): g.global_basis = Basis(axis, a) * rest, -1.9, 0.0, 2.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if _next_mark < marks.size() and u >= marks[_next_mark]:
		reached.emit(marks[_next_mark])
		_next_mark += 1
	if u >= 1.0:
		riding = false
		finished.emit()

func _jolt(n: Node3D, side: float, amount: float) -> void:
	n.set_meta("kick", float(n.get_meta("kick", 0.0)) + side * amount)

## Everything hanging from the ceiling sways a little on its cord (so it reads as hanging from up there);
## a bump or a near miss kicks it into a bigger swing that dies down.
func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for n in hang_nodes:
		var kick: float = n.get_meta("kick", 0.0)
		var phase: float = float(n.get_meta("phase", 0.0)) + delta * 2.2
		n.set_meta("phase", phase)
		n.set_meta("kick", kick * exp(-1.2 * delta))
		var axis := direction(float(n.get_meta("u")))  # swings sideways, across the line
		var a := sin(t * 0.9 + float(n.get_meta("u")) * 20.0) * 0.04 + kick * sin(phase * 2.6)
		n.global_basis = Basis(axis, a)

# ------------------------------------------------------------------ helpers
func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m

## A box: in world space at `pos` (child of this node), or in `parent`'s local space (set .position).
func _box(size: Vector3, pos: Vector3, c: Color, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(c)
	if parent:
		parent.add_child(mi)
	else:
		add_child(mi)
		mi.global_position = pos
	return mi

## A thin bar between two points given in `parent`'s local space.
func _seg(parent: Node3D, a: Vector3, b: Vector3, w: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, w, maxf(a.distance_to(b), 0.001))
	mi.mesh = bm
	mi.material_override = m
	parent.add_child(mi)
	var wa := parent.global_transform * a
	var wb := parent.global_transform * b
	mi.global_position = (wa + wb) / 2.0
	if wa.distance_to(wb) > 0.001:
		mi.look_at(wb, Vector3.UP if absf((wb - wa).normalized().y) < 0.99 else Vector3.FORWARD)
	return mi
