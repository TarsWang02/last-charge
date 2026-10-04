extends SceneTree
var room: Node3D
var results := {}
var out := "res://shots/bedroom_soft"
func _initialize() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--art-shots="): out=arg.trim_prefix("--art-shots=")
    call_deferred("_run")
func _fingerprint(node: Node, prefix: String) -> Dictionary:
    var rows := {}
    for child in node.get_children():
        if child is CSGShape3D:
            var row := {"transform":str(child.transform),"collision":child.use_collision,"operation":child.operation}
            for key in ["size","radius","height"]:
                if key in child: row[key]=str(child.get(key))
            rows[prefix+"/"+child.name]=row
        rows.merge(_fingerprint(child,prefix+"/"+child.name))
    return rows
func _bedroom_fingerprint() -> Dictionary:
    var result := {}
    for key in ["Shell","Bedroom","Stop0","Stop1","Stop2","People"]:
        result.merge(_fingerprint(room.get_node(key),key))
    return result
func _points(node: Node, points: Array[Vector3]) -> void:
    if node is MeshInstance3D:
        for surface in node.mesh.get_surface_count():
            var arrays: Array=node.mesh.surface_get_arrays(surface)
            for point in arrays[Mesh.ARRAY_VERTEX]: points.append(node.global_transform*point/9)
    for child in node.get_children(): _points(child,points)
func _bounds(node: Node) -> AABB:
    var points: Array[Vector3]=[];_points(node,points)
    var result:=AABB(points[0],Vector3.ZERO)
    for point in points: result=result.expand(point)
    return result
func _hidden_proxy(path: String) -> bool:
    var proxy: CSGShape3D=room.get_node(path)
    return proxy.material is StandardMaterial3D and proxy.material.albedo_color.a==0 and proxy.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func _shot(name: String,pos: Vector3,target: Vector3,fov:=45.0) -> void:
    if DisplayServer.get_name()=="headless": return
    var cam:=Camera3D.new();room.add_child(cam)
    cam.position=pos*9;cam.look_at(target*9);cam.fov=fov;cam.make_current()
    await create_timer(.25).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out.path_join(name+".png"))
    cam.queue_free()
func _run() -> void:
    DirAccess.make_dir_recursive_absolute(out)
    room=load("res://scenes/room.tscn").instantiate()
    var original:=_bedroom_fingerprint()
    root.add_child(room)
    await create_timer(.6).timeout
    results["all_bedroom_proxy_geometry_preserved"]=original==_bedroom_fingerprint()
    results["installed"]=room.has_meta("bedroom_soft_art_installed")
    for key in ["Bedroom/Pillow","Bedroom/Blanket","People/OldManInBed","People/OldManHead","People/BoyAtDesk","People/BoyHead","Stop1/DollHeadA","Stop1/DollHeadB"]:
        results[key+"_replaced"]=_hidden_proxy(key)
    results["no_visible_fallback_cushion"]=room.get_node_or_null("Stop1/ImportedArt/LandingCushion")==null
    var uncovered: Array[String]=[]
    for group in ["Bedroom","Stop0","Stop1","Stop2"]:
        for node in room.get_node(group).find_children("*","CSGShape3D",true,false):
            if node.name in ["DoorGapGlow", "StandHere"]: continue # engine glow / cyan gameplay marker
            if node.visible and node.material is StandardMaterial3D and node.material.albedo_color.a>.01:
                uncovered.append(str(node.get_path()))
    results["uncovered_whitebox_props"]=uncovered
    results["all_bedroom_prop_visuals_replaced"]=uncovered.is_empty()
    var pillow:=_bounds(room.get_node("Bedroom/Art_soft_pillow"))
    results["pillow_height_matches"]=absf(pillow.end.y-.67)<.001 and absf(pillow.size.y-.12)<.001
    var quilt:=_bounds(room.get_node("Bedroom/Art_soft_quilt"))
    results["quilt_footprint_matches"]=absf(quilt.size.x-1.26)<.01 and absf(quilt.size.z-1.40)<.01
    var elder:=room.get_node("People/Art_sleeping_grandfather")
    var head:=_bounds(elder.find_child("Elder_Head",true,false))
    results["elder_head_position_m"]=str(head.get_center())
    results["elder_head_aligned_to_pillow"]=absf(head.get_center().z+2.35)<.015 and absf(head.get_center().x+4.05)<.015
    for entry in [["DollHeadA",.08],["DollHeadB",.06]]:
        var head_bounds:=_bounds(room.get_node("Stop1/"+entry[0]+"/Art_porcelain_doll_head"))
        results[entry[0]+"_height_m"]=head_bounds.end.y
        results[entry[0]+"_matches"]=absf(head_bounds.size.y-entry[1])<.001 and absf(head_bounds.end.y-entry[1])<.001
    results["soft_cushion_removed"]=room.get_node_or_null("Stop1/ImportedArt/Art_soft_landing_cushion")==null
    var count:=room.find_children("Art_*","Node3D",true,false).size()
    load("res://scripts/bedroom_soft_art.gd").install(room)
    results["idempotent"]=room.find_children("Art_*","Node3D",true,false).size()==count
    var collisions:=0
    for node in room.find_children("*","CollisionShape3D",true,false):
        if "Art_" in str(node.get_path()): collisions+=1
    results["no_art_collisions"]=collisions==0
    var boy:=room.get_node("People/Art_seated_teen")
    room.player.set_top_down(true)
    await create_timer(.05).timeout
    results["boy_hides_for_readable_maze"]=not boy.visible
    room.player.set_top_down(false)
    await create_timer(.05).timeout
    results["boy_returns_after_maze"]=boy.visible
    var env: Environment=room.get_node("WorldEnvironment").environment
    env.fog_enabled=false;env.volumetric_fog_enabled=false;env.ambient_light_energy=1
    room.get_node("PostFX").enabled=false;room.get_node("MoonShaft").light_energy=4
    await _shot("bedroom_complete",Vector3(-2.35,2.2,-.15),Vector3(-3.67,.70,-1.70))
    await _shot("sleeping_grandfather",Vector3(-3.15,1.40,-1.90),Vector3(-4.05,.75,-2.23),40)
    await _shot("soft_bedding",Vector3(-3.0,1.9,-.5),Vector3(-4.05,.68,-1.7),42)
    await _shot("seated_teen",Vector3(-.75,1.75,1.20),Vector3(-1.35,.72,.5),52)
    await _shot("teen_face",Vector3(-.62,1.41,.85),Vector3(-1.28,1.08,.5),40)
    await _shot("doll_heads",Vector3(-2.61,.15,-1.80),Vector3(-2.73,.045,-1.875),50)
    await _shot("rounded_nightstand",Vector3(-2.65,1.10,-1.90),Vector3(-3.07,.70,-2.43),44)
    await _shot("rounded_truck",Vector3(-2.61,.31,-1.91),Vector3(-2.74,.09,-2.08),42)
    await _shot("soft_landing",Vector3(-2.54,.42,-2.31),Vector3(-2.70,.09,-2.5),40)
    var passed:=true
    for value in results.values():
        if value is bool and not value: passed=false
    FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
    print("SOFTTEST ",JSON.stringify(results))
    quit(0 if passed else 1)

