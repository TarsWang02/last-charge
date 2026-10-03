extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
 var room = load("res://scenes/room.tscn").instantiate()
 if "--desk-undressed" in OS.get_cmdline_user_args():
  room.get_node("Stop2/DeskMaze").dressed = false
 root.add_child(room)
 current_scene = room
 await create_timer(0.5).timeout
 room.player.teleport(room.maze.cell_world(Vector2i(2,5)) + Vector3(0,0.05,0))
 room._enter_desk()
 await create_timer(2.0).timeout
 room.maze.lights[0]._on_activated()
 await create_timer(4.0).timeout
 var samples := []
 for i in 5:
  await create_timer(1.0).timeout
  samples.append(Performance.get_monitor(Performance.TIME_FPS))
 print("DESKPERF ",JSON.stringify({"dressed":room.maze.dressed,"fps":samples,"average_fps":samples.reduce(func(a,b):return a+b,0.0)/samples.size(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"seed":room.maze.used_seed,"frame_process_seconds":Performance.get_monitor(Performance.TIME_PROCESS)}))
 quit()

