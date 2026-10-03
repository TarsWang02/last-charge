extends SceneTree
## Story captions smoke test (opening lines + a memory card), with screenshots when windowed:
##   godot --path . -s res://tools/tests/test_captions.gd -- --shots=shots/captions
var out := "user://captions_test"
var results := {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			out = arg.trim_prefix("--shots=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	call_deferred("_run")

func _wait(t: float) -> void:
	await create_timer(t).timeout

func _shot(n: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out.path_join(n))

func _run() -> void:
	var game := root.get_node("Game")
	var cap: Node = game.captions
	game.start_game()
	await _wait(3.0)
	results["opening_line_1"] = cap._center.text == StoryText.OPENING[0][0] and cap._center.modulate.a > 0.9
	await _shot("opening.png")
	await _wait(7.0)
	game.restore_memory("family_photo")
	game.restore_memory("mom_note")   # queued behind the first
	await _wait(2.0)
	results["memory_card"] = cap._memory_body.text == StoryText.MEMORIES.family_photo.body and cap._memory_box.modulate.a > 0.9
	await _shot("memory_photo.png")
	await _wait(8.0)
	results["memory_queue"] = cap._memory_body.text == StoryText.MEMORIES.mom_note.body
	await _shot("memory_note.png")
	results["controls_card"] = cap._controls.text == StoryText.CONTROLS
	print("CAPTIONTEST ", JSON.stringify(results))
	quit()
