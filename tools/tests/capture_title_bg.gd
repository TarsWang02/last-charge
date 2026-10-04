extends SceneTree
## Renders the title screen's backdrop from the game itself: the moonlit bedroom, the old man asleep, the
## robot on the nightstand. Saves a few candidates; the chosen one is copied to assets/ui/title_bg.png.
##   godot --path . --resolution 1920x1080 -s res://tools/tests/capture_title_bg.gd -- --shots=shots/bg
var out := "user://title_bg"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			out = arg.trim_prefix("--shots=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	call_deferred("_run")

func _wait(t: float) -> void:
	await create_timer(t, true).timeout

func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out.path_join(n))
	print("shot ", n)

func _hide_ui() -> void:
	var game := root.get_node("Game")
	for c in game.captions.get_children():
		if c is CanvasItem:
			c.visible = false
	for p in current_scene.find_children("KeyPrompt", "Node3D", true, false):
		p.visible = false
		p.process_mode = Node.PROCESS_MODE_DISABLED

func _run() -> void:
	var game := root.get_node("Game")
	game.start_game()
	await _wait(9.0)   # past the opening blackout
	_hide_ui()
	await _shot("bg_start.png")
	var fi: Node3D = current_scene.get_node("Stop0/FrameInteract")
	game.player.teleport(fi.global_position + Vector3(0, .04, .45))
	await _wait(1.0)
	_hide_ui()
	await _shot("bg_frame.png")
	quit()
