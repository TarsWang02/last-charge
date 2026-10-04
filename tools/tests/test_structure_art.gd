extends SceneTree
var room: Node3D
var results := {}
var out := OS.get_user_data_dir().path_join("art_review")

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--art-shots="):
			out = arg.trim_prefix("--art-shots=")
	call_deferred("_run")

func _fingerprint(node: Node, prefix := "Stop1") -> Dictionary:
	var rows := {}
	for child in node.get_children():
		if child is CSGShape3D and child.name != "StoveFlame":  # runtime animated, non-colliding kitchen visual
			var row := {"transform": str(child.transform), "collision": child.use_collision, "operation": child.operation}
			for p in ["size", "radius", "height", "inner_radius", "outer_radius"]:
				if p in child:
					row[p] = str(child.get(p))
			rows[prefix + "/" + str(child.name)] = row
		rows.merge(_fingerprint(child, prefix + "/" + str(child.name)))
	return rows

func _wait(t: float) -> void:
	await create_timer(t).timeout

func _snapshot(name: String, pos: Vector3, look: Vector3) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var cam := Camera3D.new()
	room.add_child(cam)
	cam.position = pos * 9
	cam.look_at(look * 9)
	cam.fov = 52
	cam.make_current()
	await _wait(0.2)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(out.path_join(name + ".png"))
	cam.queue_free()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	room = load("res://scenes/room.tscn").instantiate()
	var game := root.get_node("Game")
	var original := _fingerprint(room, "Room")
	root.add_child(room)
	await _wait(0.8)
	var before := _fingerprint(room, "Room")
	results["original_collision_geometry_preserved"] = original == before
	var art = load("res://scripts/room_art.gd")
	# Idempotence: reinstall must not create duplicate visuals or change collision proxies.
	art.install(room)
	results["collision_fingerprint_unchanged"] = before == _fingerprint(room, "Room")
	results["art_installed"] = room.has_meta("room_art_installed") and room.has_meta("structure_art_installed")
	var count := 0
	for n in room.find_children("Art_*", "Node3D", true, false):
		if n.has_meta("art_asset"):
			count += 1
	results["art_instances"] = count
	results["two_separate_eyes"] = room.get_node("Stop1/ImportedArt/Art_bigbot").find_child("Eye_L", true, false) != null and room.get_node("Stop1/ImportedArt/Art_bigbot").find_child("Eye_R", true, false) != null
	var bot := room.get_node("Stop1/ImportedArt/Art_bigbot")
	for label in ["HeadPlatform", "ShoulderPlatform_L", "ShoulderPlatform_R"]:
		var mesh := bot.find_child(label, true, false) as MeshInstance3D
		var bounds: AABB = mesh.global_transform * mesh.get_aabb()
		var top := bounds.end.y / 9.0
		var expected := 0.58 if label == "HeadPlatform" else 0.50
		results[label + "_visual_top_m"] = top
		results[label + "_visual_matches"] = absf(top - expected) < 0.001
		if label == "HeadPlatform":
			results["head_visual_footprint_matches"] = absf(bounds.size.x / 9.0 - 0.28) < 0.001 and absf(bounds.size.z / 9.0 - 0.28) < 0.001
	var box_dx: float = float(room.get_meta("toybox_offset_m", 0.0))
	var space := room.get_world_3d().direct_space_state
	var rays := {"head": [Vector3(-1.85, 0.59, -2.13), 0.58], "shoulder": [Vector3(-1.80, 0.51, -2.40), 0.50], "plush": [Vector3(-2.70, 0.14, -2.50), 0.12], "nightstand": [Vector3(-3.28, 0.74, -2.23), 0.72], "books": [Vector3(-3.18, 0.89, -2.54), 0.86], "loose_book": [Vector3(-2.88, 0.77, -2.33), 0.755], "block_stack": [Vector3(-2.72, 0.22, -2.28), 0.20], "jack_box": [Vector3(-2.29, 0.12, -1.96), 0.10]}
	for label in rays:
		var start: Vector3 = rays[label][0] * 9
		if label in ["head","shoulder","plush","loose_book","block_stack","jack_box"]:start.x+=box_dx*9
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(start, start - Vector3(0, 1, 0)))
		results[label + "_collision_y_m"] = hit.position.y / 9 if not hit.is_empty() else -1.0
		results[label + "_collision_matches"] = not hit.is_empty() and absf(hit.position.y / 9 - rays[label][1]) < 0.001
	var env: Environment = room.get_node("WorldEnvironment").environment
	room.get_node("PostFX").enabled = false
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	env.ambient_light_energy = 1.0
	room.get_node("MoonShaft").light_energy = 4.0
	await _snapshot("bedroom_structure", Vector3(-2.1, 2.9, -0.05), Vector3(-3.25, 0.55, -1.8))
	await _snapshot("nightstand", Vector3(-2.57, 1.08, -1.87), Vector3(-3.07, 0.76, -2.43))
	room._stand_frame_up()
	await _wait(0.85)
	results["frame_hinge_rotates"] = absf(room.get_node("Stop0/PhotoFrame").rotation_degrees.x + 102.0) < 0.05
	await _snapshot("family_frame", Vector3(-3.02, 0.96, -2.11), Vector3(-3.055, 0.80, -2.42))
	var train: Node3D = room.get_node("Stop1/Train")
	var train_cs := train.get_child(0) as CollisionShape3D
	results["train_collision_size_preserved"] = train_cs.shape.size.is_equal_approx(Vector3(0.9, 0.54, 0.45))
	var train_start := train.global_position
	await _wait(0.3)
	results["train_moves_with_art"] = train.global_position.distance_to(train_start) > 0.02 and train.get_node("Art_train_carriage").position.is_zero_approx()
	var block: CharacterBody3D = room.get_node("Stop1/PushBlockSmall")
	var block_start := block.global_position
	block.push(Vector3(0, 0, -0.8), 0.1)
	results["push_block_moves_with_art"] = block.global_position.distance_to(block_start) > 0.005 and block.get_node("Art_letter_block_b").position.is_zero_approx()
	await _snapshot("toybox_overview", Vector3(-2.30, 1.25, -1.90), Vector3(-2.24, 0.18, -2.20))
	await _snapshot("exit_machine", Vector3(-2.54, 0.91, -1.63), Vector3(-1.99, 0.31, -2.20))
	await _snapshot("plush_landing", Vector3(-2.64, 0.48, -2.36), Vector3(-2.73, 0.08, -2.52))
	# Book art inherits the original falling parent and lands at the existing checkpoint.
	room.player.teleport(Vector3(-2.88, 0.76, -2.33) * 9)
	if room.fall_armed:
		room._fall()
	await _wait(2.2)
	results["book_fall_reaches_toybox"] = room.fell and game.checkpoint.name == "ToyBox"
	# Short mechanics regression: clown and exit launch still run on their original nodes.
	room.player.teleport(Vector3(-2.28+box_dx, 0.105, -1.95) * 9)
	await _wait(0.42)
	results["jack_lid_opens"] = room.get_node("Stop1/JackBox/Art_jackbox_lid").rotation.x < -1.0
	await _snapshot("clown_and_monkey", Vector3(-2.42, 0.46, -2.07), Vector3(-2.24, 0.20, -1.92))
	await _wait(1.7)
	results["jack_checkpoint"] = str(game.checkpoint.name)
	results["jack_reaches_shelf"] = game.checkpoint.name == "BoxShelf"
	room.player.teleport(Vector3(-2.26+box_dx, 0.085, -2.20) * 9)
	room._run_machine()
	await _wait(7.0)
	results["exit_launch"] = room.launched
	results["exit_checkpoint"] = str(game.checkpoint.name)
	var cs_count := 0
	for n in room.find_children("*", "CollisionShape3D", true, false):
		if "Art_" in str(n.get_path()):
			cs_count += 1
	results["art_adds_no_collision_shapes"] = cs_count == 0
	var f := FileAccess.open(out.path_join("art_test.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(results, "\t"))
	print("ARTTEST ", JSON.stringify(results))
	quit(0 if results["art_installed"] and count == 51 and results["original_collision_geometry_preserved"] and results["collision_fingerprint_unchanged"] and results["head_collision_matches"] and results["shoulder_collision_matches"] and results["plush_collision_matches"] and results["jack_reaches_shelf"] and results["nightstand_collision_matches"] and results["books_collision_matches"] and results["loose_book_collision_matches"] and results["block_stack_collision_matches"] and results["jack_box_collision_matches"] and results["train_moves_with_art"] and results["push_block_moves_with_art"] and results["frame_hinge_rotates"] and results["book_fall_reaches_toybox"] and results["jack_lid_opens"] and results["art_adds_no_collision_shapes"] and results["exit_launch"] and results["head_visual_footprint_matches"] and results["HeadPlatform_visual_matches"] and results["ShoulderPlatform_L_visual_matches"] and results["ShoulderPlatform_R_visual_matches"] else 1)
