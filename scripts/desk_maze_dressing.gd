class_name DeskMazeDressing
extends RefCounted
## Visual-only dressing. Deliberately never reads the solution path or maze RNG.
const K := 9.0
var rng := RandomNumberGenerator.new()
var kit := DeskMazeKit.new()
var maze: DeskMaze
var root: Node3D
var keys: Array[Vector3] = []
var counts := {"walls": 0, "pillars": 0, "stacks": 0, "papers": 0, "scatter": 0, "emotional": 0}

func dress(target: DeskMaze) -> void:
 maze = target
 rng.seed = maze.used_seed * 7919 + 1
 root = Node3D.new()
 root.name = "DeskDressing"
 maze.add_child(root)
 for light in maze.lights:
  keys.append(light.global_position / K)
 keys.append(maze.cell_world(maze.note_cell) / K)
 if is_instance_valid(maze.eraser):
  keys.append(maze.eraser.global_position / K)
 _floors()
 _walls()
 _pillars()
 _papers_and_scatter()
 _holes()
 _important()
 root.set_meta("counts", counts)
 root.set_meta("dressing_seed", maze.used_seed * 7919 + 1)
 print("DRESSING ", JSON.stringify(counts))

func _hide_meshes(body: Node3D) -> void:
 for child in body.get_children():
  if child is MeshInstance3D:
   child.visible = false

func _safe(point: Vector3, radius: float) -> bool:
 for key in keys:
  if Vector2(point.x - key.x, point.z - key.z).length() < radius:
   return false
 return true

func _put(entry: Dictionary, pos_m: Vector3, scale_m := Vector3.ONE, yaw := 0.0, shadow := true, parent: Node3D = null) -> Node3D:
 var node := kit.instance(entry)
 if parent == null:
  parent = root
 parent.add_child(node)
 node.position = pos_m * K
 node.scale = scale_m * K
 node.rotation.y = yaw
 _shadows(node, shadow)
 return node

func _shadows(node: Node, enabled: bool) -> void:
 if node is GeometryInstance3D:
  node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 for child in node.get_children():
  _shadows(child, enabled)

func _floors() -> void:
 var s := maze.cell_size()
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(0.62, 0.46, 0.30)
 mat.roughness = 0.85
 if ResourceLoader.exists("res://assets/textures/desk_wood.png"):
  mat.albedo_texture = load("res://assets/textures/desk_wood.png")
 for c in maze.get_tiles():
  _hide_meshes(maze.get_tiles()[c])
  var mi := MeshInstance3D.new()
  var mesh := BoxMesh.new()
  mesh.size = Vector3(s.x, 0.03, s.y) * K
  mi.mesh = mesh
  mi.material_override = mat
  mi.position = maze.cell_world(c) - Vector3(0, 0.015 * K, 0)
  root.add_child(mi)

func _walls() -> void:
 var lines := {}
 var s := maze.cell_size()
 for wall in maze.walls:
  _hide_meshes(wall[3])
  var c: Vector2i = wall[0]
  var d: Vector2i = wall[1]
  var key := Vector2i(0, c.x + 1) if d.x != 0 else Vector2i(1, c.y + 1)
  if not lines.has(key):
   lines[key] = {}
  lines[key][c.y if d.x != 0 else c.x] = float(wall[2])
 for line in lines:
  var indices: Array = lines[line].keys()
  indices.sort()
  var i := 0
  while i < indices.size():
   var end := i + 1
   while end < indices.size() and indices[end] == indices[end - 1] + 1:
    end += 1
   while i < end:
    var length := mini(end - i, rng.randi_range(2, 3))
    var entry := kit.pick("A%d" % length, rng)
    var run_start: int = indices[i]
    var max_h := 0.0
    for j in length:
     max_h = maxf(max_h, float(lines[line][run_start + j]))
    var span := (s.y if line.x == 0 else s.x) * length
    var pos := Vector3(maze.x0 + line.y * s.x, maze.top, maze.z0 + (run_start + length * 0.5) * s.y) if line.x == 0 else Vector3(maze.x0 + (run_start + length * 0.5) * s.x, maze.top, maze.z0 + line.y * s.y)
    var width := 0.020
    var rotation_limit := minf(deg_to_rad(6), asin(clampf((0.036 - width) / span, 0, 1)))
    var yaw := (PI / 2 if line.x == 0 else 0.0) + rng.randf_range(-rotation_limit, rotation_limit)
    var dims: Vector3 = entry.size_m
    var height := clampf(maxf(max_h + 0.002, dims.y), 0.032, 0.11)
    # Shrink 1mm at each end so run ends stay within their closed edges.
    var scale_m := Vector3((span - 0.002) / dims.x, height / dims.y, width / dims.z)
    var jitter := rng.randf_range(-0.001, 0.001)
    pos += Vector3(0, 0, jitter) if line.x == 0 else Vector3(jitter, 0, 0)
    var node := _put(entry, pos, scale_m, yaw)
    node.set_meta("wall_envelope_m", width * absf(cos(yaw)) + span * absf(sin(yaw)) if line.x == 1 else width * absf(sin(yaw)) + span * absf(cos(yaw)))
    counts.walls += 1
    if rng.randf() < 0.3 and _safe(pos, 0.065):
     var stack := kit.pick("A_stack", rng)
     var angle := rng.randf_range(0, TAU)
     var sd: Vector3 = stack.size_m
     var projected := absf(sd.x * sin(angle)) + absf(sd.z * cos(angle))
     var shrink := minf(1, 0.027 / projected)
     _put(stack, pos + Vector3(0, height, 0), Vector3(shrink, shrink, shrink), yaw + angle)
     counts.stacks += 1
    i += length

func _pillars() -> void:
 var junctions := {}
 for wall in maze.walls:
  var c: Vector2i = wall[0]
  var d: Vector2i = wall[1]
  var ends := [Vector2i(c.x + 1, c.y), Vector2i(c.x + 1, c.y + 1)] if d.x != 0 else [Vector2i(c.x, c.y + 1), Vector2i(c.x + 1, c.y + 1)]
  for end in ends:
   junctions[end] = int(junctions.get(end, 0)) + 1
 var s := maze.cell_size()
 for c in junctions:
  if junctions[c] < 2 or c.x <= 0 or c.x >= maze.cols or c.y <= 0 or c.y >= maze.rows:
   continue
  var pos := Vector3(maze.x0 + c.x * s.x, maze.top, maze.z0 + c.y * s.y)
  if not _safe(pos, 0.06):
   continue
  var entry := kit.pick("B_tall" if rng.randf() < 0.2 else "B", rng)
  var dims: Vector3 = entry.size_m
  var shrink := minf(1, 0.029 / Vector2(dims.x, dims.z).length())
  _put(entry, pos, Vector3(shrink, 1, shrink), rng.randf_range(0, TAU))
  counts.pillars += 1

func _papers_and_scatter() -> void:
 var scatter := {}
 var emotional_left := rng.randi_range(1, 2)
 var cells: Array = maze.get_tiles().keys()
 # Fisher-Yates uses only the independent dressing RNG.
 for i in range(cells.size() - 1, 0, -1):
  var j := rng.randi_range(0, i)
  var temp = cells[i]
  cells[i] = cells[j]
  cells[j] = temp
 for c in cells:
  var center := maze.cell_world(c) / K
  if rng.randf() < 0.5 and counts.papers < 60:
   var id := "exam" if rng.randf() < 0.5 else "homework"
   if emotional_left > 0 and _safe(center, 0.05):
    id = "birthday_card" if rng.randf() < 0.5 else "certificate"
    emotional_left -= 1
    counts.emotional += 1
   # The rotated diagonal is smaller than a cell: never spans a hole.
   _put(kit.item(id), center + Vector3(0, 0.0004, 0), Vector3.ONE * 0.92, rng.randf_range(0, TAU), false)
   counts.papers += 1
  for j in rng.randi_range(0, 4):
   var pos := center + Vector3(rng.randf_range(-0.042, 0.042), 0.0015, rng.randf_range(-0.042, 0.042))
   if not _safe(pos, 0.045):
    continue
   var entry := kit.pick("E", rng)
   if not scatter.has(entry.id):
    scatter[entry.id] = []
   scatter[entry.id].append(Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * K), pos * K))
   counts.scatter += 1
 for id in scatter:
  var temporary := kit.instance(kit.item(id))
  var mesh := ArrayMesh.new()
  _merge_mesh(temporary, Transform3D.IDENTITY, mesh)
  temporary.free()
  var mm := MultiMesh.new()
  mm.transform_format = MultiMesh.TRANSFORM_3D
  mm.mesh = mesh
  mm.instance_count = scatter[id].size()
  for i in scatter[id].size():
   mm.set_instance_transform(i, scatter[id][i])
  var inst := MultiMeshInstance3D.new()
  inst.name = "Scatter_" + id
  inst.multimesh = mm
  inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  root.add_child(inst)

func _merge_mesh(node: Node3D, parent_transform: Transform3D, output: ArrayMesh) -> void:
 var transform := parent_transform * node.transform
 if node is MeshInstance3D:
  for surface in node.mesh.get_surface_count():
   var builder := SurfaceTool.new()
   builder.append_from(node.mesh, surface, transform)
   builder.set_material(node.get_active_material(surface))
   builder.commit(output)
 for child in node.get_children():
  if child is Node3D:
   _merge_mesh(child, transform, output)

func _holes() -> void:
 var s := maze.cell_size()
 var mat := StandardMaterial3D.new()
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.albedo_color = Color.BLACK
 for c in maze.holes:
  var center := maze.cell_world(c) / K
  var mi := MeshInstance3D.new()
  var plane := PlaneMesh.new()
  plane.size = s * K
  mi.mesh = plane
  mi.material_override = mat
  mi.position = (center - Vector3(0, 0.05, 0)) * K
  mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  root.add_child(mi)
  for direction in DeskMaze.DIRS:
   var adjacent: Vector2i = c + direction
   if maze.holes.has(adjacent) or not maze.open.has(adjacent):
    continue
   var pos := center + Vector3(direction.x * s.x / 2, 0, direction.y * s.y / 2)
   _put(kit.item("broken_edge"), pos, Vector3.ONE, PI / 2 if direction.x != 0 else 0, false)
  _put(kit.item("splinter_corner"), center + Vector3(s.x / 2 + 0.003, 0, s.y / 2 + 0.002), Vector3.ONE, 0, false)

func _important() -> void:
 for light in maze.lights:
  _hide_meshes(light)
  var entry := kit.pick("F_" + light.kind, rng)
  var yaw := atan2(light.target_offset.x, light.target_offset.z) if light.target_offset.length() > 0.01 else rng.randf_range(0, TAU)
  _put(entry, Vector3.ZERO, Vector3.ONE, yaw, true, light)
 if is_instance_valid(maze.eraser):
  _hide_meshes(maze.eraser)
  _put(kit.item("eraser"), Vector3.ZERO, Vector3.ONE, 0, true, maze.eraser)
 # Keep the original note node and material API for proximity emission.
 var note_art := _put(kit.item("folded_note"), Vector3(0, 0.0025, 0), Vector3.ONE, 0, false, maze.note)
 note_art.set_script(load("res://scripts/desk_note_art.gd"))
 note_art._ready()
 var pos := maze.cell_world(maze.note_cell) / K + Vector3(0.033, 0.007, 0)
 _put(kit.item("exam"), pos, Vector3.ONE * 0.65, 0.07, false)
 counts.papers += 1
