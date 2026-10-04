extends RefCounted
## Art only: original collision proxies, live TV viewport and lid tween stay intact.
const K := 9.0
const MODELS := {
 "crt_tv": preload("res://assets/models/props/prop_crt_tv.glb"),
 "tv_cabinet": preload("res://assets/models/props/prop_tv_cabinet.glb"),
 "game_console": preload("res://assets/models/props/prop_game_console.glb"),
 "game_controller": preload("res://assets/models/props/prop_game_controller.glb"),
 "power_strip": preload("res://assets/models/props/prop_power_strip.glb"),
 "console_cable": preload("res://assets/models/props/prop_console_cable.glb"),
 "game_boxes": preload("res://assets/models/props/prop_game_boxes.glb"),
 "magazine_stack": preload("res://assets/models/props/prop_magazine_stack.glb"),
 "subwoofer": preload("res://assets/models/props/prop_subwoofer.glb"),
 "speaker_tall": preload("res://assets/models/props/prop_speaker_tall.glb"),
 "time_box": preload("res://assets/models/props/prop_time_box.glb"),
 "time_box_lid": preload("res://assets/models/props/prop_time_box_lid.glb"),
 "time_box_contents": preload("res://assets/models/props/prop_time_box_contents.glb"),
 "sofa": preload("res://assets/models/props/prop_sofa.glb"),
 "seated_young_man": preload("res://assets/models/props/prop_seated_young_man.glb"),
}
static func hide_proxy(proxy: CSGShape3D) -> void:
 var mat := StandardMaterial3D.new()
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.albedo_color=Color(0,0,0,0)
 proxy.material=mat
 proxy.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 proxy.set_meta("art_collision_proxy",true)
static func attach(parent: Node3D,key: String,p: Vector3,yaw:=0.0) -> Node3D:
 var model: Node3D=MODELS[key].instantiate()
 model.name="Art_"+key
 parent.add_child(model)
 model.position=p*K
 model.rotation.y=yaw
 model.scale=Vector3.ONE*K
 model.set_meta("art_asset",key)
 return model
static func install(room: Node3D) -> void:
 if room.has_meta("tv_livingroom_art_installed"):return
 var stop: Node3D=room.get_node("Stop3")
 for entry in [["CRT","crt_tv"],["TVCabinet","tv_cabinet"],["GameConsole","game_console"],["GameBoxes","game_boxes"],["MagStack","magazine_stack"],["Subwoofer","subwoofer"],["SpeakerTall","speaker_tall"],["PowerStrip","power_strip"],["TimeBoxBody","time_box"]]:
  var proxy: CSGBox3D=stop.get_node(entry[0])
  hide_proxy(proxy)
  attach(proxy,entry[1],Vector3(0,-proxy.size.y/(2*K),0))
 # The viewport renders on z=-2.177; leave its 48x38cm region completely open.
 hide_proxy(stop.get_node("CRTScreen"))
 for index in range(1,6):hide_proxy(stop.get_node("ConsoleCable"+str(index)))
 var cable:=attach(stop,"console_cable",Vector3.ZERO)
 var cable_material:=StandardMaterial3D.new()
 cable_material.albedo_color=Color(.045,.044,.048)
 cable_material.roughness=.45
 cable_material.emission_enabled=true
 cable_material.emission=Color(.025,.075,.28)
 cable_material.emission_energy_multiplier=.45
 for node in cable.find_children("*","MeshInstance3D",true,false):node.material_override=cable_material
 hide_proxy(stop.get_node("SofaSeat"))
 hide_proxy(stop.get_node("SofaBack"))
 attach(stop,"sofa",Vector3(1.45,0,-.875),PI)
 hide_proxy(room.get_node("People/YoungManOnSofa"))
 var youth:=attach(room.get_node("People"),"seated_young_man",Vector3(1.30,0,-1.09),PI)
 # The imported figure already holds one controller. Connect it to the console without duplicates.
 var lead:=MeshInstance3D.new()
 lead.name="Art_ControllerCable"
 var lead_mesh:=ImmediateMesh.new()
 lead_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
 var path: Array[Vector3]=[Vector3(1.30,.64,-1.46),Vector3(1.30,.47,-1.48),Vector3(1.33,.08,-1.52),Vector3(1.40,.004,-1.64),Vector3(1.48,.004,-1.91),Vector3(1.49,.12,-1.98),Vector3(1.48,.44,-2.01),Vector3(1.428,.525,-2.049)]
 for index in range(path.size()-1):
  var a:=path[index]*K
  var b:=path[index+1]*K
  var tangent: Vector3=(b-a).normalized()
  var side: Vector3=tangent.cross(Vector3.UP).normalized()
  if side.length_squared()<.01:side=Vector3.RIGHT
  var up: Vector3=tangent.cross(side).normalized()
  for j in 8:
   var angle:=float(j)*TAU/8
   var next:=float(j+1)*TAU/8
   var r0:Vector3=(cos(angle)*side+sin(angle)*up)*.0018*K
   var r1:Vector3=(cos(next)*side+sin(next)*up)*.0018*K
   for vertex in [a+r0,b+r0,b+r1,a+r0,b+r1,a+r1]:lead_mesh.surface_add_vertex(vertex)
 lead_mesh.surface_end()
 lead.mesh=lead_mesh
 var rubber:=StandardMaterial3D.new()
 rubber.albedo_color=Color(.055,.05,.047)
 rubber.roughness=.80
 lead.material_override=rubber
 stop.add_child(lead)
 var lid: Node3D=stop.get_node("TimeBoxLid")
 hide_proxy(lid.get_node("Lid"))
 attach(lid,"time_box_lid",Vector3.ZERO)
 var drawing: CSGBox3D=stop.get_node("Drawing")
 hide_proxy(drawing)
 attach(drawing,"time_box_contents",Vector3.ZERO)
 # Optional art: a flat rug, kept east of the route and away from the TV exit landing.
 var rug:=MeshInstance3D.new()
 rug.name="Art_LivingroomRug"
 var plane:=PlaneMesh.new()
 plane.size=Vector2(1.10,.90)*K
 rug.mesh=plane
 rug.position=Vector3(1.55,.002,-.04)*K
 var fabric:=StandardMaterial3D.new()
 fabric.albedo_color=Color(.22,.18,.20)
 fabric.roughness=1.0
 rug.material_override=fabric
 stop.add_child(rug)
 var look:=Node.new()
 look.name="TVLivingroomLook"
 look.set_script(load("res://scripts/tv_livingroom_look.gd"))
 room.add_child(look)
 room.set_meta("tv_livingroom_art_installed",true)
