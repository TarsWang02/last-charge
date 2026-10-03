extends SceneTree
var out := "res://shots/maze_seeds"
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--seed-output="): out=arg.trim_prefix("--seed-output=")
    var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("candidates.json")))
    var world := Node3D.new()
    root.add_child(world)
    var environment := WorldEnvironment.new()
    environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color(0.13,0.12,0.11)
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color=Color.WHITE
    environment.environment.ambient_light_energy=1.0
    world.add_child(environment)
    var lamp:=DirectionalLight3D.new()
    lamp.rotation_degrees=Vector3(-70,20,0)
    lamp.light_energy=0.8
    world.add_child(lamp)
    var cam:=Camera3D.new()
    world.add_child(cam)
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=1.02*9
    cam.position=Vector3(-0.75,2.4,0.15)*9
    cam.look_at(Vector3(-0.75,0.75,0.15)*9,Vector3.RIGHT)
    cam.make_current()
    for row in rows:
        var maze: DeskMaze=load("res://scripts/desk_maze.gd").new()
        maze.seed=int(row.seed)
        world.add_child(maze)
        await create_timer(0.15).timeout
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(out.path_join("seed_%d.png"%row.seed))
        maze.queue_free()
        await process_frame
    quit()
