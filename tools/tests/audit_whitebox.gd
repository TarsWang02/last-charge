extends SceneTree
## Lists every white-box CSG shape still visible after the art scripts have run, by group, with its size in metres.
func _initialize():call_deferred("run")
func run():
	var room=load("res://scenes/room.tscn").instantiate()
	root.add_child(room)
	await create_timer(1.0).timeout
	var out := {}
	for n in room.find_children("*","CSGShape3D",true,false):
		var s: CSGShape3D = n
		if not s.is_visible_in_tree():continue
		var m = s.material
		if m is StandardMaterial3D and (m.albedo_color.a < 0.05 and m.transparency != 0):continue
		var has_art := false
		for c in s.get_children():
			if c.name.begins_with("Art_"):has_art=true
		if has_art:continue
		var size := ""
		if s is CSGBox3D:size=str((s as CSGBox3D).size/9.0)
		var grp:String=str(room.get_path_to(s)).get_slice("/",0)
		if not out.has(grp):out[grp]=[]
		out[grp].append(s.name+" "+size+(" mat="+str(m.resource_name) if m else ""))
	for g in out:
		print("== ",g," (",out[g].size(),")")
		for l in out[g]:print("   ",l)
	quit()
