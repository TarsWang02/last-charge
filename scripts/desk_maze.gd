class_name DeskMaze
extends Node3D
## A random grid maze on the desk top (new layout every run; the same within a run so memorised routes
## stay valid after a respawn). Built at runtime: floor tiles, wall pieces (school things lying on the desk),
## holes in most dead ends (fall = back to the last checkpoint), the desk edge is open.
## Lights: the flashlight at the start shines on the END of the maze; the others light either their own
## surroundings or a spot further along the route. Powering one also makes it a checkpoint.
## One straight stretch of the route has a hole with the eraser in front of it: push it in to bridge it.
##   --maze-seed=N on the command line fixes the layout.

const K := 9.0

@export var x0 := -1.1     ## desk top bounds (metres)
@export var x1 := -0.4
@export var z0 := -0.55
@export var z1 := 0.85
@export var top := 0.75
@export var cols := 6
@export var rows := 12
@export var loop_chance := 0.06   ## extra openings that make loops (alternative routes)
@export var hole_chance := 0.85   ## dead ends that are holes
@export var branch_hole_chance := 0.4  ## other off-route cells that are holes
@export var seed := -1
@export var dressed := true
@export var seed_pool: PackedInt32Array = []

const WALL_T := 0.015            ## wall thickness (m)
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const WALL_COLORS := [Color(0.85, 0.7, 0.2), Color(0.2, 0.35, 0.7), Color(0.65, 0.2, 0.15), Color(0.8, 0.75, 0.6), Color(0.3, 0.55, 0.35)]

var rng := RandomNumberGenerator.new()
var used_seed := 0
var start := Vector2i(0, 0)
var goal := Vector2i.ZERO
var open := {}                    ## Vector2i cell -> Array of open directions (Vector2i)
var holes: Array[Vector2i] = []
var path: Array[Vector2i] = []    ## start -> goal
var eraser_index := -1            ## path[eraser_index] = the bridge hole, path[eraser_index - 1] = eraser
var eraser: CharacterBody3D
var hole_fill: Area3D
var note: Node3D
var lights: Array = []
var light_specs := []             ## [cell, target cell, cost, colour, kind]
var note_cell := Vector2i.ZERO
var _required := {}               ## cells that must stay reachable
var _tiles := {}
var walls: Array = []

func get_tiles() -> Dictionary:
	return _tiles
var _floor_mat: StandardMaterial3D

func _ready() -> void:
	used_seed = seed
	var explicit_seed := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--maze-seed="):
			used_seed = int(a.substr(12))
			explicit_seed = true
	if not explicit_seed and not seed_pool.is_empty():
		used_seed = seed_pool[randi() % seed_pool.size()]
	if used_seed < 0:
		used_seed = randi() % 100000
	rng.seed = used_seed
	goal = Vector2i(cols - 1, rows - 1)
	_carve()
	path = _solve()
	_place_eraser_hole()
	_choose_item_cells()
	_place_holes()
	_build_floor_and_walls()
	_place_items()
	if dressed and not "--whitebox" in OS.get_cmdline_user_args():
		DeskMazeDressing.new().dress(self)
	print("[maze] seed=%d path=%d holes=%d lights=%d" % [used_seed, path.size(), holes.size(), lights.size()])

# ------------------------------------------------------------------ layout
func cell_size() -> Vector2:
	return Vector2((x1 - x0) / cols, (z1 - z0) / rows)

## Centre of a cell on the desk top, in world units.
func cell_world(c: Vector2i) -> Vector3:
	var s := cell_size()
	return Vector3((x0 + (c.x + 0.5) * s.x) * K, top * K, (z0 + (c.y + 0.5) * s.y) * K)

func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows

func _carve() -> void:
	for x in cols:
		for y in rows:
			open[Vector2i(x, y)] = []
	var stack: Array[Vector2i] = [start]
	var seen := {start: true}
	while not stack.is_empty():
		var c: Vector2i = stack.back()
		var options := []
		for d in DIRS:
			var n: Vector2i = c + d
			if _inside(n) and not seen.has(n):
				options.append(d)
		if options.is_empty():
			stack.pop_back()
			continue
		var d: Vector2i = options[rng.randi() % options.size()]
		open[c].append(d)
		open[c + d].append(-d)
		seen[c + d] = true
		stack.append(c + d)
	for x in cols:  # a few loops
		for y in rows:
			var c := Vector2i(x, y)
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				if _inside(c + d) and not open[c].has(d) and rng.randf() < loop_chance:
					open[c].append(d)
					open[c + d].append(-d)

func _solve(blocked: Array = []) -> Array[Vector2i]:
	var prev := {start: start}
	var q: Array[Vector2i] = [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c == goal:
			break
		for d in open[c]:
			var n: Vector2i = c + d
			if not prev.has(n) and not blocked.has(n):
				prev[n] = c
				q.append(n)
	var out: Array[Vector2i] = []
	if not prev.has(goal):
		return out
	var c := goal
	while c != start:
		out.push_front(c)
		c = prev[c]
	out.push_front(start)
	return out

func _place_eraser_hole() -> void:
	# a straight stretch in the second half of the route: path[i-2] -> path[i-1] (eraser) -> path[i] (hole)
	var candidates := []
	for i in range(3, path.size() - 1):
		if path[i] - path[i - 1] == path[i - 1] - path[i - 2]:
			candidates.append(i)
	candidates = candidates.filter(func(i): return i >= path.size() / 2) if candidates.any(func(i): return i >= path.size() / 2) else candidates
	if candidates.is_empty():
		return
	eraser_index = candidates[rng.randi() % candidates.size()]
	holes.append(path[eraser_index])

func _choose_item_cells() -> void:
	var used := {}
	for c in path:
		_required[c] = true
	if eraser_index > 0:
		used[path[eraser_index - 1]] = true
		used[path[eraser_index]] = true
	light_specs = [[start, path.back(), 0.05, Color(1.0, 0.92, 0.75), "flashlight"]]
	used[start] = true
	for f in [0.3, 0.55, 0.8]:
		var i := int(path.size() * f)
		while i < path.size() - 1 and used.has(path[i]):
			i += 1
		var far := rng.randf() < 0.5
		var tgt: Vector2i = path[min(i + rng.randi_range(4, 6), path.size() - 1)] if far else path[i]
		light_specs.append([path[i], tgt, 0.05, Color(1.0, 0.75, 0.45), "far" if far else "local"])
		used[path[i]] = true
	var dead := open.keys().filter(func(c): return open[c].size() == 1 and not used.has(c) and c != goal)
	_shuffle(dead)
	if dead.size() > 0:
		light_specs.append([dead[0], dead[0], 0.08, Color(1.0, 0.72, 0.4), "lamp"])
		_required[dead[0]] = true
	note_cell = dead[1] if dead.size() > 1 else path[path.size() / 2]
	_required[note_cell] = true

## Is every required cell still reachable from the start if `extra` is also a hole?
func _all_reachable(extra: Vector2i) -> bool:
	var bridge: Vector2i = path[eraser_index] if eraser_index > 0 else Vector2i(-9, -9)
	var seen := {start: true}
	var q: Array[Vector2i] = [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		for d in open[c]:
			var n: Vector2i = c + d
			if seen.has(n) or n == extra or (holes.has(n) and n != bridge):
				continue
			seen[n] = true
			q.append(n)
	for c in _required:
		if not seen.has(c):
			return false
	return true

func _place_holes() -> void:
	var cells := open.keys()
	_shuffle(cells)
	for c in cells:
		if _required.has(c) or holes.has(c) or c == start or c == goal:
			continue
		var p := hole_chance if open[c].size() == 1 else branch_hole_chance
		if rng.randf() < p and _all_reachable(c):
			holes.append(c)

# ------------------------------------------------------------------ build
func _box(size: Vector3, pos: Vector3, color: Color, solid := true, mat: StandardMaterial3D = null) -> Node3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	if mat == null:
		mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.75
	mi.material_override = mat
	if not solid:
		mi.position = pos
		add_child(mi)
		return mi
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	body.add_child(mi)
	body.position = pos
	add_child(body)
	return body

func _build_floor_and_walls() -> void:
	var s := cell_size()
	_floor_mat = StandardMaterial3D.new()
	_floor_mat.albedo_color = Color(0.38, 0.24, 0.13)
	_floor_mat.roughness = 0.6
	for c in open:
		if holes.has(c):
			continue
		var p := cell_world(c)
		_tiles[c] = _box(Vector3(s.x * K, 0.03 * K, s.y * K), p - Vector3(0, 0.015 * K, 0), Color.WHITE, true, _floor_mat)
	# walls on closed inner edges, plus posts at every inner grid point so corners look solid
	for c in open:
		for d in [Vector2i(1, 0), Vector2i(0, 1)]:
			var n: Vector2i = c + d
			if not _inside(n) or open[c].has(d):
				continue
			var h := rng.randf_range(0.03, 0.06)
			var col: Color = WALL_COLORS[rng.randi() % WALL_COLORS.size()]
			var mid := (cell_world(c) + cell_world(n)) / 2.0
			var size := Vector3(WALL_T * K, h * K, (s.y + WALL_T) * K) if d.x != 0 else Vector3((s.x + WALL_T) * K, h * K, WALL_T * K)
			var wall := _box(size, mid + Vector3(0, h * K / 2.0, 0), col)
			walls.append([c, d, h, wall])

func _place_items() -> void:
	var used := {}
	for c in holes:
		used[c] = true
	# the eraser and the hole it fills
	if eraser_index > 0:
		var hole_c: Vector2i = path[eraser_index]
		var er_c: Vector2i = path[eraser_index - 1]
		used[er_c] = true
		eraser = load("res://scripts/components/pushable.gd").new()
		eraser.size = Vector3.ONE * 0.095 * K
		eraser.color = Color(0.85, 0.45, 0.5)
		add_child(eraser)
		eraser.global_position = cell_world(er_c) + Vector3(0, 0.001 * K, 0)
		hole_fill = load("res://scripts/components/hole_fill.gd").new()
		var s := cell_size()
		hole_fill.size = Vector3(s.x * K, 1, s.y * K)
		hole_fill.surface_y = top * K
		add_child(hole_fill)
		hole_fill.global_position = cell_world(hole_c)
	var reveal := load("res://scripts/components/reveal_light.gd")
	var cp := load("res://scripts/components/checkpoint.gd")
	var specs := light_specs
	for sp in specs:
		var c: Vector2i = sp[0]
		var l: Area3D = reveal.new()
		l.cost = sp[2]
		l.radius = 1.1
		l.prompt_offset = Vector3(0, 1.3, 0)
		l.light_color = sp[3]
		l.light_range = 5.8 if sp[4] == "lamp" else 4.6
		l.light_energy = 6.0
		l.target_offset = cell_world(sp[1]) - cell_world(c)
		add_child(l)
		l.global_position = cell_world(c)
		l.kind = sp[4]
		lights.append(l)
		var marker := _box(Vector3(0.25, 0.25, 0.25) * (1.6 if sp[4] == "lamp" else 1.0), Vector3.ZERO, sp[3], false)
		marker.reparent(l, false)
		marker.position = Vector3(0.35, 0.15, 0.35)
		var chk: Area3D = cp.new()
		chk.chapter_id = "teen"
		chk.recharge = 0.0
		chk.respawn_charge = 0.6
		chk.fail_below_y = (top - 0.006) * K
		chk.size = Vector3(0.8, 1.0, 0.8)
		chk.show_light = false
		add_child(chk)
		chk.global_position = cell_world(c)
	# mom's note in a dead end (worth the detour)
	note = _box(Vector3(0.07 * K, 0.004 * K, 0.05 * K), cell_world(note_cell) + Vector3(0, 0.002 * K, 0), Color(0.9, 0.85, 0.7), false)

func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t

## Route as world points (for the self-test).
func route_points() -> Array:
	return path.map(func(c): return cell_world(c))
