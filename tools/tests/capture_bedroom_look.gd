extends SceneTree
var room: Node3D
var output: String
func _initialize() -> void: call_deferred("run")
func shot(name: String, pos: Vector3, target: Vector3, fov:=48.0) -> void:
    var cam:=Camera3D.new();room.add_child(cam);cam.position=pos*9
    cam.look_at(target*9);cam.fov=fov;cam.make_current()
    await create_timer(.65).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output.path_join(name+".png"))
    cam.queue_free()
func run() -> void:
    output="res://shots/bedroom_look/"+("before" if "--before" in OS.get_cmdline_user_args() else "after")
    DirAccess.make_dir_recursive_absolute(output)
    room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
    await create_timer(1.0).timeout
    room.player.locked=true
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output.path_join("opening.png"))
    await shot("nightstand",Vector3(-3.67,1.08,-1.98),Vector3(-3.08,.79,-2.42),48)
    await shot("room",Vector3(-2.25,1.85,-.15),Vector3(-3.75,.70,-1.65),53)
    await shot("toys",Vector3(-2.38,.89,-1.56),Vector3(-2.25,.24,-2.22),64)
    await shot("desk",Vector3(-.75,1.65,1.2),Vector3(-1.10,.77,.5),57)
    print("LOOK_CAPTURE ",output)
    quit()
