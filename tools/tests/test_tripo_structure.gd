extends SceneTree
var room: Node3D
var results := {}
var out := "res://shots/tripo_batch_03"
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--art-shots="): out=arg.trim_prefix("--art-shots=")
 call_deferred("_run")
func _fingerprint(node: Node, prefix := "Room") -> Dictionary:
 var rows := {}
 for child in node.get_children():
  if child is CSGShape3D:
   var row := {"transform":str(child.transform),"collision":child.use_collision,"operation":child.operation}
   for key in ["size","radius","height"]:
    if key in child:row[key]=str(child.get(key))
   rows[prefix+"/"+child.name]=row
  rows.merge(_fingerprint(child,prefix+"/"+child.name))
 return rows
func _points(node: Node, points: Array[Vector3]) -> void:
 if node is MeshInstance3D:
  for surface in node.mesh.get_surface_count():
   var arrays: Array=node.mesh.surface_get_arrays(surface)
   for point in arrays[Mesh.ARRAY_VERTEX]:points.append(node.global_transform*point/9)
 for child in node.get_children(): _points(child,points)
func _bounds(node: Node) -> AABB:
 var points: Array[Vector3]=[]
 _points(node,points)
 var result:=AABB(points[0],Vector3.ZERO)
 for point in points:result=result.expand(point)
 return result
func _shot(name: String, pos: Vector3, target: Vector3) -> void:
 if DisplayServer.get_name()=="headless":return
 var cam:=Camera3D.new()
 room.add_child(cam)
 cam.position=pos*9
 cam.look_at(target*9)
 cam.fov=45
 cam.make_current()
 await create_timer(.2).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
 cam.queue_free()
func _run() -> void:
 DirAccess.make_dir_recursive_absolute(out)
 room=load("res://scenes/room.tscn").instantiate()
 var original:=_fingerprint(room)
 root.add_child(room)
 await create_timer(.5).timeout
 results["collision_unchanged"]=original==_fingerprint(room)
 results["installed"]=room.has_meta("tripo_structure_art_installed")
 for entry in [["Stop0/PillBottleA/Art_pill_bottle_a",Vector3(.04,.08,.04),.8],["Stop0/PillBottleB/Art_pill_bottle_b",Vector3(.036,.065,.036),.785],["Stop0/ReadingGlasses/Art_reading_glasses",Vector3(.12,.018,.03),.738],["Stop1/Shoebox/Art_shoebox",Vector3(.56,.30,.22),.30]]:
  var bounds:=_bounds(room.get_node(entry[0]))
  results[entry[0]+"_size"]=str(bounds.size)
  results[entry[0]+"_top"]=bounds.end.y
  results[entry[0]+"_matches"]=bounds.size.distance_to(entry[1])<.002 and absf(bounds.end.y-entry[2])<.002
 var box:=room.get_node("Stop1/Art_moving_box")
 var specs:={"BoxFloor":Vector3(1.2,.008,.9),"BoxWallW":Vector3(.012,.60,.9),"BoxWallE":Vector3(.012,.60,.9),"BoxWallN":Vector3(1.2,.60,.012),"BoxWallS":Vector3(1.2,.55,.012),"FlapN":Vector3(1.2,.28,.012),"FlapE":Vector3(.012,.4,.9),"FlapWTorn":Vector3(.22,.01,.62)}
 for key in specs:
  var bounds:=_bounds(box.find_child(key,true,false))
  results[key+"_matches"]=bounds.size.distance_to(specs[key])<.002
 var glass:=room.get_node("Stop0/WaterGlass/Art_water_glass")
 var gb:=_bounds(glass)
 results["glass_dimensions"]=gb.size.distance_to(Vector3(.07,.11,.07))<.002
 var water: MeshInstance3D=glass.get_node("HalfGlassWater")
 results["water_surface_m"]=water.global_position.y/9+.052/2
 results["half_filled"]=absf(results.water_surface_m-(.72+.055))<.0001
 var gm:=glass.find_child("WaterGlassSkin",true,false) as MeshInstance3D
 results["glass_transparent"]=gm.get_active_material(0).transparency==BaseMaterial3D.TRANSPARENCY_ALPHA
 var chair:=_bounds(room.get_node("Stop2/DeskChair/Art_chair"))
 results["chair_height_matches"]=absf(chair.end.y-.95)<.002 and absf(chair.position.y)<.002
 var before:=_fingerprint(room)
 load("res://scripts/tripo_structure_art.gd").install(room)
 results["idempotent"]=before==_fingerprint(room) and room.get_node("Stop1").find_children("Art_moving_box","Node3D",false,false).size()==1
 var collisions:=0
 for node in room.find_children("*","CollisionShape3D",true,false):
  if "Art_" in str(node.get_path()):collisions+=1
 results["no_art_collisions"]=collisions==0
 var env: Environment=room.get_node("WorldEnvironment").environment
 env.fog_enabled=false
 env.volumetric_fog_enabled=false
 env.ambient_light_energy=1
 room.get_node("PostFX").enabled=false
 room.get_node("MoonShaft").light_energy=4
 await _shot("nightstand",Vector3(-2.65,1.12,-1.98),Vector3(-3.02,.77,-2.41))
 await _shot("glass_and_glasses",Vector3(-2.70,.94,-2.18),Vector3(-2.98,.765,-2.38))
 await _shot("moving_box",Vector3(-3.2,1.65,-1.15),Vector3(-2.24,.42,-2.20))
 await _shot("shoebox",Vector3(-2.65,.78,-2.0),Vector3(-2.20,.30,-2.52))
 await _shot("chair",Vector3(-2.1,1.5,1.25),Vector3(-1.32,.47,.5))
 var passed:=true
 for value in results.values():
  if value is bool and not value:passed=false
 FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
 print("TRIPOTEST ",JSON.stringify(results))
 quit(0 if passed else 1)
