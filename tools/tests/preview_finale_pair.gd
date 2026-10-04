extends SceneTree
func _initialize():call_deferred("run")
func run():
 var room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
 await create_timer(.5).timeout
 room.player.locked=true
 var camera:=Camera3D.new();room.add_child(camera);camera.make_current()
 camera.position=Vector3(.60,1.20,.50)*9;camera.look_at(Vector3(1.60,.60,1.90)*9);camera.fov=48
 await create_timer(.4).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://shots/finale_art/chair_elder.png")
 print("TRIPO_PAIR_LOADED ",room.get_node("Stop5/Art_armchair")!=null and room.get_node("People/Art_old_man")!=null)
 quit()
