extends SceneTree
var room
var camera: Camera3D
const OUT="res://shots/tv_art_review"
func _initialize():call_deferred("run")
func shot(name: String,eye: Vector3,target: Vector3):
 camera.global_position=eye*9
 camera.look_at(target*9)
 await create_timer(.25).timeout
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT.path_join(name+".png"))
func run():
 DirAccess.make_dir_recursive_absolute(OUT)
 room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
 await create_timer(.5).timeout
 room.process_mode=Node.PROCESS_MODE_DISABLED
 camera=Camera3D.new();root.add_child(camera);camera.fov=45;camera.make_current()
 await shot("television_front",Vector3(1.04,.86,-1.08),Vector3(1,.62,-2.36))
 await shot("climbing_steps",Vector3(-.05,.70,-1.43),Vector3(.40,.25,-2.24))
 await shot("sofa_and_young_man",Vector3(.53,1.03,-1.95),Vector3(1.30,.68,-.94))
 await shot("young_man_hands",Vector3(1.30,.79,-1.63),Vector3(1.30,.64,-1.26))
 room.get_node("Stop3/TimeBoxLid").rotation_degrees.x=-105
 room.get_node("Stop3/TimeBoxGlow").light_energy=2
 await shot("time_box_open",Vector3(1.74,.27,-1.91),Vector3(1.6,.04,-2.15))
 print("TV_ART_REVIEW_COMPLETE")
 quit()
