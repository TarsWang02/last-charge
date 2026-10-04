extends SceneTree
var room: Node3D
var result: Dictionary={}
var output:="res://shots/bedroom_relayout"
func _initialize() -> void:call_deferred("run")
func points(node: Node, output_points: Array[Vector3]) -> void:
    if node is MeshInstance3D:
        for surface in node.mesh.get_surface_count():
            var arrays: Array=node.mesh.surface_get_arrays(surface)
            for point in arrays[Mesh.ARRAY_VERTEX]:output_points.append(node.global_transform*point/9)
    for child in node.get_children():points(child,output_points)
func bounds(node: Node) -> AABB:
    var vertices: Array[Vector3]=[];points(node,vertices)
    if vertices.is_empty():return AABB()
    var box:=AABB(vertices[0],Vector3.ZERO)
    for vertex in vertices:box=box.expand(vertex)
    return box
func shot(name: String,position_m: Vector3,target: Vector3,fov:=48.0) -> void:
    if DisplayServer.get_name()=="headless":return
    var cam:=Camera3D.new();room.add_child(cam);cam.position=position_m*9;cam.look_at(target*9);cam.fov=fov;cam.make_current()
    await create_timer(.3).timeout;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output.path_join(name+".png"));cam.queue_free()
func overlaps() -> Array[String]:
    var found: Array[String]=[]
    var names: Array[String]=["OldBooks","PillBottleA","PillBottleB","WaterGlass","ReadingGlasses","CoinA","CoinB","PhotoFrame","LooseBook"]
    for i in names.size():
        for j in range(i+1,names.size()):
            var a:=bounds(room.get_node("Stop0/"+names[i]));var b:=bounds(room.get_node("Stop0/"+names[j]))
            if a.has_volume() and b.has_volume() and a.intersects(b):found.append(names[i]+" / "+names[j])
    return found
func run() -> void:
    DirAccess.make_dir_recursive_absolute(output)
    room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    room.player.set_process_unhandled_input(false)
    await create_timer(.7).timeout
    var stand=room.get_node("Stop0/Nightstand")
    var stand_visual:=bounds(stand.find_child("Nightstand_Top",true,false))
    result["nightstand_visual_bounds"]=str(stand_visual)
    result["nightstand_size_m"]=str(stand.size/9)
    result["nightstand_73cm"]=absf(stand.size.x/9-.7333333)<.001 and absf(stand.size.z/9-.7333333)<.001
    result["nightstand_visual_matches"]=absf(stand_visual.size.x-.7333333)<.001 and absf(stand_visual.size.z-.7333333)<.001 and absf(stand_visual.end.y-.72)<.001
    var photo=room.get_node("Stop0/PhotoFrame").find_child("FamilyPhoto",true,false)
    result["photo_uv_present"]=photo.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV].size()==4
    result["photo_texture_present"]=photo.material_override.albedo_texture!=null
    result["toon_materials_active"]=stand.find_child("Nightstand_Top",true,false).get_active_material(0).diffuse_mode==BaseMaterial3D.DIFFUSE_TOON
    result["flat_frame_overlaps"]=overlaps()
    result["flat_layout_clear"]=overlaps().is_empty()
    result["rig_parts_present"]=room.player.rig.ok
    result["wheel_count_six"]=room.player.rig.wheels["L"].size()+room.player.rig.wheels["R"].size()==6
    result["belt_count_two"]=room.player.rig.belts.size()==2
    var player_model=room.player.lean.get_child(0)
    result["player_height_matches"]=absf(bounds(player_model).size.y-.1)<.005
    await shot("room",Vector3(-2.25,1.85,-.15),Vector3(-3.75,.70,-1.65),53)
    await shot("nightstand_flat",Vector3(-2.92,1.38,-1.42),Vector3(-2.91,.76,-2.30),49)
    room._stand_frame_up();await create_timer(.85).timeout
    result["upright_frame_overlaps"]=overlaps();result["upright_layout_clear"]=overlaps().is_empty()
    result["frame_rotates"]=absf(room.get_node("Stop0/PhotoFrame").rotation_degrees.x+102)<.05
    await shot("nightstand_upright",Vector3(-2.91,1.02,-1.50),Vector3(-2.91,.82,-2.30),47)
    await shot("box_sources",Vector3(-1.85,1.10,-1.25),Vector3(-1.98,.30,-2.22),60)
    var player: Node3D=room.player
    player.teleport(Vector3(-3.03,.721,-2.14)*9)
    player._face_yaw=PI
    player.visual.rotation.y=PI
    await create_timer(1.0).timeout
    var center: Vector3=player.global_position/9+Vector3(0,.05,0)
    await shot("player_front",center+Vector3(.16,.085,-.21),center,38)
    await shot("player_back",center+Vector3(-.14,.075,.21),center,38)
    room.player.set_top_down(true);await create_timer(.1).timeout
    result["logical_lights_off_in_maze"]=not room.get_node("Stop1/BoxBatteryTorch/BatteryTorchBeam").visible and not room.get_node("Stop1/Train/TrainLampGlow").visible
    print("RELAYOUTTEST ",JSON.stringify(result))
    FileAccess.open(output.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
    var passed:=true
    for value in result.values():
        if value is bool and not value:passed=false
    quit(0 if passed else 1)
