extends SceneTree
var room: Node3D
var results := {}
var out := "res://shots/bedroom_finish"
func _initialize() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--art-shots="): out=arg.trim_prefix("--art-shots=")
    call_deferred("_run")
func _fingerprint(node: Node, prefix := "Room") -> Dictionary:
    var rows := {}
    for child in node.get_children():
        # Kitchen flame is a non-colliding visual with a runtime breathing animation.
        if child is CSGShape3D and child.name != "StoveFlame":
            var row := {"transform":str(child.transform),"collision":child.use_collision,"operation":child.operation}
            for key in ["size","radius","height"]:
                if key in child: row[key]=str(child.get(key))
            rows[prefix+"/"+child.name]=row
        rows.merge(_fingerprint(child,prefix+"/"+child.name))
    return rows
func _points(node: Node, points: Array[Vector3]) -> void:
    if node is MeshInstance3D:
        for surface in node.mesh.get_surface_count():
            var arrays: Array=node.mesh.surface_get_arrays(surface)
            for point in arrays[Mesh.ARRAY_VERTEX]: points.append(node.global_transform*point/9)
    for child in node.get_children(): _points(child,points)
func _bounds(node: Node) -> AABB:
    var points: Array[Vector3]=[]
    _points(node,points)
    var result:=AABB(points[0],Vector3.ZERO)
    for point in points: result=result.expand(point)
    return result
func _shot(name: String, pos: Vector3, target: Vector3, fov := 45.0) -> void:
    if DisplayServer.get_name()=="headless": return
    var cam:=Camera3D.new()
    room.add_child(cam);cam.position=pos*9;cam.look_at(target*9);cam.fov=fov;cam.make_current()
    await create_timer(.2).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out.path_join(name+".png"))
    cam.queue_free()
func _run() -> void:
    DirAccess.make_dir_recursive_absolute(out)
    room=load("res://scenes/room.tscn").instantiate()
    var original:=_fingerprint(room)
    root.add_child(room)
    await create_timer(.5).timeout
    results["collision_geometry_unchanged"]=original==_fingerprint(room)
    results["installed"]=room.has_meta("bedroom_finish_art_installed")
    var mattress:=room.get_node("Bedroom/Mattress/Art_mattress")
    var mb:=_bounds(mattress.find_child("MattressBody",true,false))
    results["mattress_size_m"]=str(mb.size)
    results["mattress_top_m"]=mb.end.y
    results["mattress_matches"]=mb.size.distance_to(Vector3(1.30,.20,1.90))<.001 and absf(mb.end.y-.55)<.001
    var truck:=room.get_node("Stop1/ToyTruck/Art_toy_truck")
    var tb:=_bounds(truck)
    results["truck_envelope_matches"]=tb.size.distance_to(Vector3(.12,.19,.12))<.001
    var bed:=_bounds(truck.find_child("TruckFlatBed",true,false))
    var cab:=_bounds(truck.find_child("TruckCab",true,false))
    results["truck_bed_top_m"]=bed.end.y
    results["truck_cab_top_m"]=cab.end.y
    results["truck_standing_surfaces_match"]=absf(bed.end.y-.14)<.001 and absf(cab.end.y-.19)<.001 and bed.size.x>=.118 and bed.size.z>=.118
    var tracks:=_bounds(room.get_node("Stop1/Art_car_head_tracks"))
    results["car_tracks_match"]=tracks.size.distance_to(Vector3(.10,.003,.23))<.001 and absf(tracks.end.y-.583)<.001
    var pivot:=room.get_node("Stop2/DoorPivot")
    var door:=pivot.get_node("Art_bedroom_door")
    var slab:=_bounds(door.find_child("DoorSlab",true,false))
    results["door_slab_matches"]=slab.size.distance_to(Vector3(.04,2.05,.85))<.001
    results["door_origin_is_original_hinge"]=door.position.is_zero_approx()
    var lever:=pivot.get_node("Handle/Art_door_lever")
    results["lever_surface_matches"]=absf(_bounds(lever).end.y-.81)<.001 and absf(_bounds(lever).size.z-.14)<.001
    var space:=room.get_world_3d().direct_space_state
    for spec in [["mattress",Vector3(-4.62,.56,-.80),.55],["truck_bed",Vector3(-2.70,.145,-2.05),.14],["truck_cab",Vector3(-2.77,.195,-2.11),.19]]:
        var start: Vector3=spec[1]*9
        var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(start,start-Vector3(0,.1,0)*9))
        results[spec[0]+"_collision_matches"]=not hit.is_empty() and absf(hit.position.y/9-spec[2])<.001
    var before_count:=room.find_children("Art_*","Node3D",true,false).size()
    load("res://scripts/bedroom_finish_art.gd").install(room)
    results["idempotent"]=room.find_children("Art_*","Node3D",true,false).size()==before_count and original==_fingerprint(room)
    var count:=0
    for node in room.find_children("*","CollisionShape3D",true,false):
        if "Art_" in str(node.get_path()): count+=1
    results["no_art_collision_shapes"]=count==0
    var env: Environment=room.get_node("WorldEnvironment").environment
    env.fog_enabled=false;env.volumetric_fog_enabled=false;env.ambient_light_energy=1
    room.get_node("PostFX").enabled=false;room.get_node("MoonShaft").light_energy=4
    await _shot("bed_and_mattress",Vector3(-2.6,1.65,-.35),Vector3(-4.05,.42,-1.6))
    await _shot("truck",Vector3(-2.61,.31,-1.91),Vector3(-2.74,.09,-2.08),42)
    await _shot("lamp",Vector3(-.92,1.36,.90),Vector3(-.53,1.11,.55),38)
    await _shot("south_window",Vector3(-2.0,1.8,1.5),Vector3(-3.2,1.55,2.60))
    await _shot("door_closed",Vector3(-1.90,1.25,1.00),Vector3(-.40,1.05,1.38))
    await _shot("head_tracks",Vector3(-2.10,.87,-1.87),Vector3(-1.77,.58,-2.20),40)
    var lamp:=room.get_node("Stop2/WallLampShade/Art_wall_lamp")
    room.get_node("Stop2/WallLampShade").visible=false
    results["lamp_inherits_desk_hide"]=not lamp.is_visible_in_tree()
    room.get_node("Stop2/WallLampShade").visible=true
    results["lamp_returns_after_desk"]=lamp.is_visible_in_tree()
    room._env_saved=[env.ambient_light_energy,room.get_node("Moonlight").light_energy]
    room.in_desk=true
    room._open_door()
    await create_timer(2.0).timeout
    results["door_art_follows_open_hinge"]=absf(pivot.rotation_degrees.y+75)<.1 and door.position.is_zero_approx()
    results["lever_art_follows_weight_press"]=absf(pivot.get_node("Handle").rotation_degrees.x+35)<.1 and lever.position.is_equal_approx(Vector3(0,0,-.07)*9)
    await _shot("door_open",Vector3(-1.9,1.4,1.0),Vector3(-.4,.9,1.45))
    var passed:=true
    for value in results.values():
        if value is bool and not value: passed=false
    FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
    print("BEDROOMTEST ",JSON.stringify(results))
    quit(0 if passed else 1)
