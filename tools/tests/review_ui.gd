extends SceneTree
## Screenshots of every UI surface (title, settings card, subtitle plate, controls card, key-cap prompt
## with its hold ring, pause menu):
##   godot --path . --resolution 1600x900 -s res://tools/tests/review_ui.gd -- --shots=shots/ui
var out := "user://ui_review"

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

func _run() -> void:
	var game := root.get_node("Game")
	change_scene_to_file("res://scenes/title.tscn")
	await _wait(1.6)
	await _shot("ui_title.png")
	current_scene._show_settings(true)
	await _wait(0.5)
	await _shot("ui_title_settings.png")
	current_scene._show_settings(false)
	game.start_game()
	await _wait(2.5)
	game.captions.say("Who's that at my desk? ...At this hour?", 4.0)
	game.captions.show_controls()
	await _wait(1.2)
	await _shot("ui_subtitle_controls.png")
	var room: Node = current_scene
	var fi: Node = room.get_node("Stop0/FrameInteract")
	game.player.teleport(fi.global_position + Vector3(0, .04, .45))
	await _wait(0.6)
	await _shot("ui_prompt.png")
	UiKit.set_prompt_progress(fi._prompt, 0.65)
	await _wait(0.1)
	await _shot("ui_prompt_hold.png")
	game.set_paused(true)
	await _wait(0.4)
	await _shot("ui_pause.png")
	quit()
