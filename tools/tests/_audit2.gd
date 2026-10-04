extends SceneTree
func _initialize():call_deferred("run")
func run():
	var room=load("res://scenes/room.tscn").instantiate()
	root.add_child(room)
	await create_timer(1.0).timeout
	for n in room.find_children("*","CSGShape3D",true,false):
		var s: CSGShape3D = n
		if not s.is_visible_in_tree():continue
		var m = s.material
		if m is StandardMaterial3D and m.transparency != 0 and m.albedo_color.a < 0.05:continue
		var art := false
		for c in s.get_children():
			if c.name.begins_with("Art_") or c is MeshInstance3D or c.get_child_count() > 0: art = true
		if art and s.use_collision:
			print("VISIBLE_PROXY ", room.get_path_to(s), " mat=", m)
	quit()
