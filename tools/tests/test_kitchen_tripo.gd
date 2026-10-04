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
 var room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
 await create_timer(.8).timeout
 room.kitchen_revealed=true;room.player.locked=true
 room.player.teleport(Vector3(2.28,.1,-1.8)*9)
 var stop=room.get_node("Stop4")
 var checks={}
 for row in [["RiceBag/Art_rice_bag",Vector3(.13,.22,.16),.22],["BreadBag/Art_bread_bag",Vector3(.15,.09,.16),.99]]:
  var box:=bounds(stop.get_node(row[0]))
  checks[row[0]+"_size"]=box.size.distance_to(row[1])<.01
  checks[row[0]+"_top"]=absf(box.end.y-row[2])<.01
 var cook=room.get_node("People/Art_cook_middle_aged")
 var cb:=bounds(cook)
 checks["cook_height"]=absf(cb.size.y-1.5)<.01
 checks["cook_on_floor"]=absf(cb.position.y)<.005
 checks["cook_faces_north"]=cook.basis.z.z<-.99
 checks["old_visuals_hidden"]=stop.get_node("RiceBag").has_meta("art_collision_proxy") and stop.get_node("BreadBag").has_meta("art_collision_proxy") and room.get_node("People/CookAtStove").has_meta("art_collision_proxy")
 checks["original_collisions"]=stop.get_node("RiceBag").use_collision and stop.get_node("BreadBag").use_collision
 print("KITCHENTRIPOCHECK ",JSON.stringify(checks))
 var camera:=Camera3D.new();room.add_child(camera);camera.make_current()
 for row in [["cook",Vector3(2.20,1.70,-1.35),Vector3(3.70,.85,-1.78),53.0],["climb",Vector3(1.58,.63,-1.88),Vector3(2.05,.32,-2.43),48.0],["bread",Vector3(3.02,1.26,-1.78),Vector3(3.32,1.0,-2.26),38.0]]:
  camera.position=row[1]*9;camera.look_at(row[2]*9);camera.fov=row[3]
  await create_timer(.3).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://shots/kitchen_art/tripo_"+row[0]+".png")
 var ok:=true
 for value in checks.values():if not value:ok=false
 quit(0 if ok else 1)
