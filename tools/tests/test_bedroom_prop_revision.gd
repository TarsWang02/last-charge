extends SceneTree
var room: Node3D
var results:={}
const OUT="res://shots/bedroom_prop_revision"
func _initialize():call_deferred("run")
func bounds(node: Node) -> AABB:
    var p: Array[Vector3]=[]
    points(node,p)
    if p.is_empty():return AABB()
    var b:=AABB(p[0],Vector3.ZERO)
    for v in p:b=b.expand(v)
    return b
func points(node: Node,p: Array[Vector3]):
    if node is MeshInstance3D:
        for s in node.mesh.get_surface_count():
            for v in node.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:p.append(node.global_transform*v/9)
    for c in node.get_children():points(c,p)
func shot(label: String,position_m: Vector3,target: Vector3,fov:=60.0):
    if DisplayServer.get_name()=="headless":return
    var cam:=Camera3D.new();room.add_child(cam);cam.position=position_m*9;cam.look_at(target*9);cam.fov=fov;cam.make_current()
    await create_timer(.25).timeout;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OUT.path_join(label+".png"));cam.queue_free()
func run():
    DirAccess.make_dir_recursive_absolute(OUT)
    room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    await create_timer(.8).timeout
    var stop=room.get_node("Stop1")
    var dx: float=room.get_meta("toybox_offset_m")
    var box=stop.get_node("Art_moving_box")
    var bot=stop.get_node("ImportedArt/Art_bigbot")
    var tracks=stop.get_node("Art_car_head_tracks")
    results["box_visual_matches_collision_center"]=absf(box.position.x/9-(-2.24+dx))<.001
    results["east_lid_removed"]=box.find_child("FlapE",true,false)==null and stop.get_node_or_null("FlapE")==null
    results["head_tracks_aligned"]=absf(tracks.position.x-stop.get_node("BigBotHead").position.x)<.001
    results["no_brown_cushion"]=stop.find_child("LandingCushion",true,false)==null and stop.find_child("Art_soft_landing_cushion",true,false)==null
    var bear=stop.get_node("ImportedArt/Art_bear")
    results["bear_width_m"]=bounds(bear).size.x
    var p: Vector3=room.get_node("FallLanding").position/9
    results["bear_covers_landing"]=bounds(bear).has_point(Vector3(p.x,.1,p.z))
    var train=stop.get_node("Train")
    var theta: float=train._a
    var tangent:=Vector3(-sin(theta),0,cos(theta))
    results["train_points_forward"]=train.global_basis.x.dot(tangent)>.999
    var car=stop.get_node("ElectricCar")
    var heading: Vector3=(room.get_node("CarWay1").position-car.position).normalized()
    results["car_points_to_first_waypoint"]=car.get_node("Art_car").global_basis.z.normalized().dot(heading)>.999
    await shot("inside_box",Vector3(-2.45,.30,-2.35),Vector3(-1.54,.34,-2.20),70)
    await shot("landing",Vector3(-2.21,.40,-2.08),p+Vector3(0,.01,0),49)
    await shot("overview",Vector3(-1.95,1.00,-1.28),Vector3(-1.94,.29,-2.22),60)
    train.set_physics_process(false)
    var tp: Vector3=train.global_position/9
    await shot("train",tp+train.global_basis*Vector3(.17,.10,.15),tp+Vector3(0,.025,0),42)
    train.set_physics_process(true)
    var monkey=stop.get_node("Drum/Art_monkey")
    var mb:=bounds(monkey)
    results["head_monkey_height_m"]=mb.size.y
    results["head_monkey_enlarged"]=absf(mb.size.y-.162)<.001
    results["monkey_feet_on_head"]=absf(mb.position.y-.58)<.001
    results["drum_in_corner"]=stop.get_node_or_null("WindUpMonkey/Art_drum")!=null
    await shot("head_mechanism",mb.get_center()+Vector3(-.26,.16,.24),mb.get_center()+Vector3(.035,-.025,0),58)
    room._stand_frame_up()
    await create_timer(.9).timeout
    var frame=room.get_node("Stop0/PhotoFrame")
    var top: Vector3=frame.to_global(Vector3(.065,0,.18)*9)
    results["frame_leans_backward"]=top.z<frame.global_position.z and top.y>frame.global_position.y
    await shot("frame_and_glasses",Vector3(-2.69,1.04,-1.89),Vector3(-2.88,.80,-2.30),54)
    var cp: Vector3=car.global_position/9
    await shot("car",cp+Vector3(-.15,.13,-.15),cp,44)
    var before_car: Vector3=car.global_position
    room._run_machine()
    await create_timer(.5).timeout
    var travelled: Vector3=car.global_position-before_car
    results["car_drives_forward"]=travelled.length()>.05 and car.get_node("Art_car").global_basis.z.normalized().dot(travelled.normalized())>.99
    await create_timer(3.6).timeout
    var landed:=bounds(monkey)
    results["monkey_fell_to_seesaw"]=absf(stop.get_node("Drum").position.y-room.get_node("DrumLanding").position.y)<.05
    await shot("monkey_landed",landed.get_center()+Vector3(-.26,.23,.24),landed.get_center(),55)
    print("PROPREVISION ",JSON.stringify(results))
    FileAccess.open(OUT.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
    var passed:=true
    for v in results.values():
        if v is bool and not v:passed=false
    quit(0 if passed else 1)
