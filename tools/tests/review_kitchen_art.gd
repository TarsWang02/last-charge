extends SceneTree
func _initialize():call_deferred("run")
func run():
 var room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
 await create_timer(.8).timeout
 room.player.locked=true
 room.kitchen_revealed=true
 room.player.teleport(Vector3(2.28,.1,-1.8)*9)
 var camera:=Camera3D.new();room.add_child(camera)
 camera.position=Vector3(1.6,2.2,.6)*9
 camera.look_at(Vector3(3.6,.8,-1.6)*9)
 camera.fov=58;camera.make_current()
 await create_timer(.5).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://shots/kitchen_art/review_overview.png")
 camera.position=Vector3(4.03,1.19,2.10)*9
 camera.look_at(Vector3(4.45,.95,2.45)*9)
 camera.fov=40
 await create_timer(.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://shots/kitchen_art/review_mug.png")
 quit()
