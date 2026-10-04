extends RefCounted
const K:=9.0
static func hide_proxy(shape: CSGShape3D) -> void:
 var mat:=StandardMaterial3D.new()
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.albedo_color=Color(0,0,0,0)
 shape.material=mat
 shape.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 shape.set_meta("art_collision_proxy",true)
static func attach(parent: Node3D,key: String,p:=Vector3.ZERO,yaw:=0.0) -> Node3D:
 var model: Node3D=load("res://assets/models/props/prop_finale_"+key+".glb").instantiate()
 model.name="Art_"+key
 parent.add_child(model);model.position=p*K;model.rotation.y=yaw;model.scale=Vector3.ONE*K
 model.set_meta("art_asset",key)
 return model
static func install(room: Node3D) -> void:
 if room.has_meta("livingroom_finale_art_installed"):return
 var stop5: Node3D=room.get_node("Stop5")
 for row in [["Windowsill","windowsill",-.015],["RadioTable","radio_table",-.275],["Radio","radio",-.085]]:
  var proxy: CSGShape3D=stop5.get_node(row[0]);hide_proxy(proxy)
  attach(proxy,row[1],Vector3(0,row[2],0),-PI/2 if row[0]=="Radio" else 0.0)
 for name in ["Armchair","ArmchairBack"]:hide_proxy(stop5.get_node(name))
 # Tripo chair and elder face north, preserving the original gameplay proxies.
 attach(stop5,"armchair",Vector3(1.60,0,1.85),PI)
 hide_proxy(room.get_node("People/OldManInArmchair"))
 var elder=attach(room.get_node("People"),"old_man",Vector3(1.60,0,1.30),PI)
 toon(elder)
 var stop6: Node3D=room.get_node("Stop6")
 for row in [["BreakerBox","breaker_box",-.225],["BreakerShelf","breaker_shelf",-.015],["WireDrop","wire_drop",-.1775],["WireAlongWall","wall_wire",0.0]]:
  var proxy: CSGShape3D=stop6.get_node(row[0]);hide_proxy(proxy);attach(proxy,row[1],Vector3(0,row[2],0))
 for name in ["ShelfBracket1","ShelfBracket2"]:hide_proxy(stop6.get_node(name))
 hide_proxy(stop6.get_node("BreakerLever/Handle"))
 attach(stop6.get_node("BreakerLever"),"breaker_lever")
 # Keep the two engine-controlled lamps in front of their sockets, unobstructed.
 var shell: Node3D=room.get_node("Shell")
 for i in range(1,7):hide_proxy(shell.get_node("WindowMullion"+str(i)))
 hide_proxy(shell.get_node("WindowTransom"))
 attach(shell,"long_window",Vector3(1.40,1.00,2.68))
 var south: CSGShape3D=shell.get_node("WindowBedroomS")
 hide_proxy(south)
 var old=south.get_node_or_null("Art_window_south")
 if old:old.visible=false
 attach(shell,"bedroom_south_frame",Vector3(-3.20,1.10,2.68))
 attach(shell,"window_leaf_left",Vector3(-3.80,1.10,2.68),deg_to_rad(-80))
 attach(shell,"window_leaf_right",Vector3(-2.60,1.10,2.68),deg_to_rad(80))
 toon(stop5);toon(stop6)
 # The zip art auto-loader uses its original pivots, dimensions, sway and knock-off animations.
 room.set_meta("livingroom_finale_art_installed",true)
static func toon(node: Node) -> void:
 if node is MeshInstance3D and node.mesh:
  for i in node.mesh.get_surface_count():
   var source=node.get_active_material(i)
   if source is StandardMaterial3D:
    var mat: StandardMaterial3D=source.duplicate()
    mat.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
    mat.roughness=maxf(mat.roughness,.74)
    mat.metallic=minf(mat.metallic,.22)
    node.set_surface_override_material(i,mat)
 for child in node.get_children():toon(child)

