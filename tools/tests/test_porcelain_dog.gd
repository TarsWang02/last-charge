extends SceneTree
func _initialize():call_deferred("run")
func run():
 var room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
 await create_timer(.8).timeout
 room.player.locked=true
 var frame=room.get_node("Stop0/PhotoFrame")
 frame.rotation_degrees.x=-102
 var camera:=Camera3D.new();room.add_child(camera)
 camera.position=Vector3(-3.36,.98,-2.04)*9
 camera.look_at(Vector3(-3.01,.80,-2.41)*9)
 camera.fov=40;camera.make_current()
 await create_timer(.5).timeout
 await RenderingServer.frame_post_draw
 var folder="res://shots/porcelain_dog"
 DirAccess.make_dir_recursive_absolute(folder)
 root.get_texture().get_image().save_png(folder.path_join("dog_and_family_photo.png"))
 var dog=room.get_node("Stop0/Art_porcelain_dog")
 var box:=AABB();var first:=true
 for mesh in dog.find_children("*","MeshInstance3D",true,false):
  for i in 8:
   var p:Vector3=mesh.global_transform*mesh.get_aabb().get_endpoint(i)/9
   if first:box=AABB(p,Vector3.ZERO);first=false
   else:box=box.expand(p)
 var checks={"on_table":absf(box.position.y-.72)<.001,"within_table":box.position.x>=-3.30 and box.end.x<=-2.566 and box.position.z>=-2.65 and box.end.z<=-1.917,"clear_of_frame":box.end.x<-2.96,"no_new_collision":dog.find_children("*","CollisionObject3D",true,false).is_empty(),"family_photo_still_present":frame.find_child("FamilyPhoto",true,false)!=null}
 print("DOGARTTEST ",JSON.stringify(checks))
 var ok:=true
 for value in checks.values():if not value:ok=false
 quit(0 if ok else 1)
