extends SceneTree
func _initialize():call_deferred("run")
func bounds(node: Node3D) -> AABB:
 var box:=AABB();var first:=true
 for mesh in node.find_children("*","MeshInstance3D",true,false):
  for i in 8:
   var p: Vector3=mesh.global_transform*mesh.get_aabb().get_endpoint(i)/9
   if first:box=AABB(p,Vector3.ZERO);first=false
   else:box=box.expand(p)
 return box
func run():
 var room=load("res://scenes/room.tscn").instantiate()
 var originals={}
 for stop in ["Stop5","Stop6"]:
  for proxy in room.get_node(stop).find_children("*","CSGShape3D",true,false):
   if proxy.use_collision:originals[str(room.get_path_to(proxy))]=proxy.transform
 root.add_child(room);await create_timer(.8).timeout
 room.kitchen_revealed=true;room.player.locked=true
 var checks={"collision_retained":true,"zip_all_auto_loaded":true,"south_window_clear":true}
 for path in originals:
  var proxy=room.get_node(path)
  if not proxy.use_collision or proxy.transform!=originals[path]:checks["collision_retained"]=false
 checks["sill_top"]=absf(bounds(room.get_node("Stop5/Windowsill/Art_windowsill")).end.y-.90)<.01
 checks["sill_size"]=bounds(room.get_node("Stop5/Windowsill/Art_windowsill")).size.distance_to(Vector3(5.6,.03,.25))<.01
 checks["breaker_shelf_top"]=absf(bounds(room.get_node("Stop6/BreakerShelf/Art_breaker_shelf")).end.y-1.06)<.01
 var zip=room.get_node("Stop5/Zipline")
 for key in ["peg","pulley","rose","lamp","plant","chime","cage","garment_a","garment_b","garment_c","garment_d","garment_e"]:
  if zip.find_children("Art_zip_"+key,"Node3D",true,false).is_empty():checks["zip_all_auto_loaded"]=false
 var core:=AABB(Vector3(-3.60,1.20,2.61),Vector3(.8,.6,.20))
 for name in ["Art_bedroom_south_frame","Art_window_leaf_left","Art_window_leaf_right"]:
  for mesh in room.get_node("Shell/"+name).find_children("*","MeshInstance3D",true,false):
   var faces: PackedVector3Array=mesh.mesh.get_faces()
   for i in range(0,faces.size(),3):
    var a: Vector3=mesh.global_transform*faces[i]/9
    var triangle_box:=AABB(a,Vector3.ZERO)
    triangle_box=triangle_box.expand(mesh.global_transform*faces[i+1]/9).expand(mesh.global_transform*faces[i+2]/9)
    if triangle_box.intersects(core):checks["south_window_clear"]=false
 checks["old_south_window_hidden"]=not room.get_node("Shell/WindowBedroomS/Art_window_south").visible
 checks["ceiling_single_sided"]=room.get_node("Shell/BedroomCeiling") is MeshInstance3D and room.get_node("Shell/BedroomCeiling").material_override.cull_mode==BaseMaterial3D.CULL_BACK
 checks["long_frame_depth"]=bounds(room.get_node("Shell/Art_long_window")).position.z>=2.62
 checks["lever_original_pivot"]=room.get_node("Stop6/BreakerLever").position.is_equal_approx(Vector3(-.315,1.30,2.24)*9)
 # Ray tests the model meshes, with each indicator square centre as the target.
 checks["indicators_unobstructed"]=true
 var box_art=room.get_node("Stop6/BreakerBox/Art_breaker_box")
 for target in [Vector3(-.315,1.485,2.135),Vector3(-.315,1.435,2.135)]:
  var from:=Vector3(.22,1.32,2.62)*9
  for mesh in box_art.find_children("*","MeshInstance3D",true,false):
   var inverse=mesh.global_transform.affine_inverse()
   var faces: PackedVector3Array=mesh.mesh.get_faces()
   for i in range(0,faces.size(),3):
    if Geometry3D.segment_intersects_triangle(inverse*from,inverse*(target*9),faces[i],faces[i+1],faces[i+2])!=null:checks["indicators_unobstructed"]=false
 print("FINALEARTCHECK ",JSON.stringify(checks))
 var camera:=Camera3D.new();room.add_child(camera);camera.make_current()
 for row in [["breaker",Vector3(.22,1.32,2.62),Vector3(-.32,1.30,2.18),47.0],["south_window",Vector3(-3.20,1.55,1.95),Vector3(-3.20,1.55,3.30),60.0]]:
  camera.position=row[1]*9;camera.look_at(row[2]*9);camera.fov=row[3]
  await create_timer(.3).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://shots/finale_art/review_"+row[0]+".png")
 var ok:=true
 for value in checks.values():if not value:ok=false
 quit(0 if ok else 1)
