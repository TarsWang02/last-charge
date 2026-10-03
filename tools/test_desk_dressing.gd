extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("_run")
func _snapshot(maze: DeskMaze) -> Dictionary:
 var collisions := []
 _collisions(maze, collisions)
 return {"path": str(maze.path), "holes": str(maze.holes), "open": str(maze.open), "rng": str(maze.rng.state), "collisions": collisions, "light_specs":str(maze.light_specs), "note": str(maze.note_cell)}
func _collisions(node: Node, out: Array) -> void:
 if node is CollisionShape3D:
  out.append([str(node.global_transform), str(node.shape.size) if node.shape is BoxShape3D else str([node.shape.get_class(), node.shape.get("radius"), node.shape.get("height")])])
 for child in node.get_children(): _collisions(child, out)
func _run() -> void:
 for seed in [7,123,4242,0,22,49]:
  var a := DeskMaze.new()
  a.seed = seed
  a.dressed = false
  root.add_child(a)
  var original := _snapshot(a)
  var before := a.rng.state
  DeskMazeDressing.new().dress(a)
  var decorated := _snapshot(a)
  var same := original == decorated
  var counts: Dictionary = a.get_node("DeskDressing").get_meta("counts")
  var glowing := StandardMaterial3D.new()
  glowing.emission_enabled = true
  glowing.emission_energy_multiplier = 2.5
  a.note.material_override = glowing
  var note_art: Node3D = a.note.get_children()[-1]
  note_art._process(0)
  var glow_ok: bool = not note_art.materials.is_empty() and note_art.materials.all(func(m): return m.emission_enabled and is_equal_approx(m.emission_energy_multiplier, 2.5))
  var budgets: bool = counts.walls + counts.pillars + counts.stacks <= 250 and counts.papers <= 60
  var envelopes := true
  for node in a.get_node("DeskDressing").get_children():
   if node.has_meta("wall_envelope_m") and node.get_meta("wall_envelope_m") > 0.03901: envelopes = false
  var b := DeskMaze.new()
  b.seed = seed
  b.dressed = true
  root.add_child(b)
  var regenerated := _snapshot(b) == original
  print("LAYOUTTEST ",JSON.stringify({"seed":seed,"equal":same,"regenerated_equal":regenerated,"rng_unchanged":before==a.rng.state,"note_emission":glow_ok,"budgets":budgets,"wall_envelopes":envelopes,"path":str(a.path),"holes":str(a.holes),"counts":counts}))
  failed = failed or not (same and regenerated and budgets and envelopes and glow_ok)
  a.free()
  b.free()
 quit(1 if failed else 0)
