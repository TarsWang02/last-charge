extends SceneTree
func _initialize():call_deferred("run")
func _blocked(node: Node3D,a: Vector3,b: Vector3) -> bool:
 for m in node.find_children("*","MeshInstance3D",true,false):
  var inverse=m.global_transform.affine_inverse()
  var faces: PackedVector3Array=m.mesh.get_faces()
  for i in range(0,faces.size(),3):
   if Geometry3D.segment_intersects_triangle(inverse*a,inverse*b,faces[i],faces[i+1],faces[i+2])!=null:return true
 return false
func run():
 var room=load("res://scenes/room.tscn").instantiate();root.add_child(room);room._op_skip=true
 await create_timer(.8).timeout
 room.player.locked=true;room.player.set_physics_process(false);room.player.charge=1
 room.player.teleport(Vector3(-1.10,.752,-.49)*9);room.player.velocity=Vector3.ZERO
 var normal=room.get_node("Stop2/DeskNormal")
 var eye:=Vector3(-1.10,.84,-.49)*9
 var checks={"face_clear":not _blocked(normal,eye,Vector3(-1.36,1.16,.50)*9),"door_clear":not _blocked(normal,eye,Vector3(-.45,.85,.95)*9),"no_collision":normal.find_children("*","CollisionShape3D",true,false).is_empty() and normal.find_children("*","CSGShape3D",true,false).is_empty()}
 var shots:="res://shots/desk_normal";DirAccess.make_dir_recursive_absolute(shots)
 if "--desk-still" in OS.get_cmdline_user_args():root.get_node("Game").captions.visible=false
 var cam:=Camera3D.new();room.add_child(cam);cam.position=Vector3(-1.78,1.26,-.01)*9;cam.look_at(Vector3(-.92,.77,.35)*9);cam.fov=57;cam.make_current()
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(shots+"/normal_overview.png")
 if "--desk-still" in OS.get_cmdline_user_args():
  var lamp=room.get_node("DeskLampLook")
  checks["downlight_on"]=lamp.beam.light_energy>0
  room.get_node("DeskLampGlow").light_energy=0
  await create_timer(.1).timeout
  checks["downlight_off"]=lamp.beam.light_energy==0 and lamp.bounce.light_energy==0
  checks["bulb_off"]=lamp.bulb_material.emission_energy_multiplier==0
  print("DESKNORMAL_STILL ",JSON.stringify(checks));quit();return
 room._enter_desk()
 await create_timer(2.0).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(shots+"/normal_pov_boy.png")
 checks["first_person"]=room._fp_desk!=null and room._fp_desk.current
 var start:=Time.get_ticks_msec()
 while normal.visible and Time.get_ticks_msec()-start<35000:await process_frame
 checks["normal_hidden_after_blackout"]=not normal.visible
 checks["maze_visible_after_blackout"]=room.maze.visible
 await create_timer(1.6).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(shots+"/normal_hidden_dark.png")
 print("DESKNORMAL_REVIEW ",JSON.stringify(checks))
 quit()
