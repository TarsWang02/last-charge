extends SceneTree
func _initialize():call_deferred("run")
func run():
 var room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
 room._op_skip=true
 await create_timer(1.0).timeout
 room.kitchen_revealed=true;room.player.locked=true;room.player.set_physics_process(false);room.player.charge=1.0
 room.get_node("PostFX").loss_cap=0.0
 var game=root.get_node("Game")
 if game.captions:game.captions.visible=false
 var camera:=Camera3D.new();room.add_child(camera);camera.make_current()
 var output:="res://shots/whole_game_art/before"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--review-output="):output=arg.substr(16)
 DirAccess.make_dir_recursive_absolute(output)
 var views=[
 ["01_bedroom",Vector3(-2.0,1.30,-.60),Vector3(-3.45,.64,-2.10),Vector3(-3,.78,-2),60],
 ["02_nightstand",Vector3(-2.70,1.12,-1.77),Vector3(-3.08,.77,-2.28),Vector3(-3,.78,-2),50],
 ["03_toybox",Vector3(-1.62,.89,-1.27),Vector3(-2.30,.22,-2.25),Vector3(-2.3,.2,-2.2),60],
 ["04_desk",Vector3(-2.2,1.5,1.28),Vector3(-.82,.79,.1),Vector3(-.8,.8,.15),55],
 ["05_tv",Vector3(.12,1.1,-.25),Vector3(1.2,.62,-1.7),Vector3(.3,.2,-1.0),62],
 ["06_kitchen",Vector3(2.2,1.40,-.65),Vector3(3.9,1.0,-2.10),Vector3(3,.95,-2.1),63],
 ["07_sink",Vector3(3.4,1.40,-.5),Vector3(4.45,.92,.50),Vector3(4.1,1,.2),58],
 ["08_chair",Vector3(.55,1.28,.55),Vector3(1.65,.58,1.8),Vector3(1,.9,2.4),54],
 ["09_zipline",Vector3(3.65,1.13,2.10),Vector3(.0,1.26,2.02),Vector3(3.7,1,2.4),73],
 ["10_breaker",Vector3(.26,1.35,2.59),Vector3(-.31,1.30,2.17),Vector3(-.25,1.07,2.3),48]]
 for row in views:
  room.player.global_position=row[3]*9
  camera.position=row[1]*9;camera.look_at(row[2]*9);camera.fov=row[4];camera.make_current()
  await create_timer(.45).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(output+"/"+row[0]+".png")
 # One actual dark maze view, then the powered ending state.
 room.player.global_position=Vector3(-.8,.78,.2)*9;room.player.top_down=true;room.maze.visible=true
 room.get_node("DeskLampGlow").light_energy=0
 room.get_node("WorldEnvironment").environment.ambient_light_energy=.07
 room.get_node("Moonlight").light_energy=.04
 for n in ["WallLampShade","WallLampArm"]:room.get_node("Stop2/"+n).visible=false
 camera.position=Vector3(-.78,2.10,.15)*9;camera.look_at(Vector3(-.78,.75,.15)*9,Vector3(0,0,-1));camera.fov=58
 await create_timer(.65).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output+"/11_maze.png")
 room.player.top_down=false;room.maze.visible=false
 room.player.global_position=Vector3(.3,.8,1.3)*9
 room.get_node("Moonlight").light_energy=.8
 room._lights_on()
 camera.position=Vector3(.45,1.60,.28)*9;camera.look_at(Vector3(2.25,.68,1.20)*9);camera.fov=72
 await create_timer(4.5).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output+"/12_power_restored.png")
 print("ART_REVIEW_FINISHED ",views.size()+2)
 quit()
