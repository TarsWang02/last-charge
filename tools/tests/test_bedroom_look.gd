extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var room=load("res://scenes/room.tscn").instantiate()
    var original: Dictionary={}
    var source: Environment=room.get_node("WorldEnvironment").environment
    var original_msaa:=root.msaa_3d
    for key in load("res://scripts/bedroom_look.gd").ENV:original[key]=source.get(key)
    root.add_child(room);await create_timer(.5).timeout
    var look=room.get_node("BedroomLook")
    var result: Dictionary={"installed":room.has_meta("bedroom_look_installed"),"bedroom_profile_active":look.active,"opening_highlight_reduced":room.get_node("MoonShaft").light_energy<12,"no_added_colliders":look.find_children("*","CollisionShape3D",true,false).is_empty()}
    room.player.locked=true
    result["battery_postprocess_bound"]=room.get_node("PostFX").mat==look.post
    room.player.charge=.1
    await create_timer(.35).timeout
    result["low_battery_effect_preserved"]=float(look.post.get_shader_parameter("power_loss"))>.1
    room.player.charge=1.0
    var env: Environment=room.get_node("WorldEnvironment").environment
    env.ambient_light_energy=.07
    room.player.set_top_down(true)
    await create_timer(.1).timeout
    result["maze_fill_lights_off"]=look.fills.all(func(light):return not light.visible)
    result["maze_darkness_preserved"]=is_equal_approx(env.ambient_light_energy,.07)
    result["maze_dust_hidden"]=look.dust.all(func(particles):return not particles.visible)
    result["maze_stays_sharp"]=look.post.get_shader_parameter("tilt_shift_enabled")==false
    room.player.set_top_down(false);await create_timer(.1).timeout
    result["third_person_lights_return"]=look.fills.all(func(light):return light.visible)
    room.player.global_position=Vector3(0,1,1)*9
    await create_timer(.1).timeout
    result["outside_profile_off"]=not look.active
    result["outside_fill_lights_off"]=look.fills.all(func(light):return not light.visible)
    result["outside_environment_restored"]=original.keys().all(func(key):return env.get(key)==original[key])
    result["outside_antialiasing_restored"]=root.msaa_3d==original_msaa
    print("LOOKTEST ",JSON.stringify(result))
    quit(0 if result.values().all(func(value):return value) else 1)


