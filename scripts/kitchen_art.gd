extends RefCounted
## Art-only replacements follow original collision and animation nodes.
const K := 9.0
static func hide_proxy(shape: CSGShape3D) -> void:
 var m:=StandardMaterial3D.new()
 m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 m.albedo_color=Color(0,0,0,0)
 shape.material=m
 shape.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 shape.set_meta("art_collision_proxy",true)
static func attach(parent: Node3D,key: String,p:=Vector3.ZERO) -> Node3D:
 var model: Node3D=load("res://assets/models/props/prop_kitchen_"+key+".glb").instantiate()
 model.name="Art_"+key
 parent.add_child(model)
 model.position=p*K
 model.scale=Vector3.ONE*K
 model.set_meta("art_asset",key)
 return model
static func install(room: Node3D) -> void:
 if room.has_meta("kitchen_art_installed"):return
 var stop: Node3D=room.get_node("Stop4")
 var entries=[
  ["CounterA","counter_a"],["CounterB","counter_b"],["CounterC","counter_c"],
  ["CounterE_N","counter_e_n"],["CounterE_S","counter_e_s"],
  ["SinkRimW","sink_rim_w"],["SinkRimE","sink_rim_e"],
  ["UpperCabW","upper_cab_w"],["UpperCabE","upper_cab_e"],["UpperCabEast","upper_cab_east"],
  ["StoveBody","stove"],["RangeHood","range_hood"],["HoodChimney","hood_chimney"],
  ["UtensilRailN","rail_n"],["UtensilRailE","rail_e"],
  ["CannedGoods","canned_goods"],["RiceBag","rice_bag"],["BreadBag","bread_bag"],["StepStool","step_stool"],["Lunchbox","lunchbox"],["CerealBox","cereal_box"],
  ["Microwave","microwave"],["CuttingBoard","cutting_board"],["Toaster","toaster"],
  ["SpiceShelf","spice_shelf"],["Kettle","kettle"],["DishRack","dish_rack"],
  ["DishPot","dish_pot"],["DishLid","dish_lid"],["DishBowlA","dish_bowl_a"],
  ["DishBowlB","dish_bowl_b"],["DishPlates","dish_plates"],["DishLadle","dish_ladle"],
 ]
 for entry in entries:
  var proxy: CSGBox3D=stop.get_node(entry[0])
  hide_proxy(proxy)
  attach(proxy,entry[1],Vector3(0,-proxy.size.y/(2*K),0))
 stop.get_node("Kettle/Art_kettle").rotation.y=-PI/2
 # The gameplay changes the original material; the art look mirrors its live heat.
 var coils: CSGShape3D=stop.get_node("ToasterCoils")
 coils.layers=0
 attach(coils,"toaster_coils",Vector3(0,-.006,0))
 for entry in [["StockPot","stock_pot"],["SinkPlug","sink_plug"],["Faucet","faucet"],["Mug","daughter_mug"]]:
  var proxy: CSGCylinder3D=stop.get_node(entry[0])
  hide_proxy(proxy)
  attach(proxy,entry[1],Vector3(0,-proxy.height/(2*K),0))
 stop.get_node("Mug/Art_daughter_mug").rotation.y=-PI/2
 for name in ["ChairSeat","ChairBack","ChairLeg1","ChairLeg2","ChairLeg3","ChairLeg4"]:hide_proxy(stop.get_node(name))
 attach(stop,"chair",Vector3(2.22,0,-2.33))
 # The cook is a static miniature, facing north toward the stove.
 hide_proxy(room.get_node("People/CookAtStove"))
 var cook:=attach(room.get_node("People"),"cook_middle_aged",Vector3(3.70,0,-1.78))
 cook.rotation.y=PI
 # Preserve the existing eastern hinge and every gameplay tween.
 hide_proxy(stop.get_node("MicrowaveDoor/Door"))
 attach(stop.get_node("MicrowaveDoor"),"microwave_door")
 for i in range(1,5):
  var proxy: CSGBox3D=stop.get_node("HangingUtensil"+str(i))
  hide_proxy(proxy)
  # Decoration has no collider: raise its swing pivot to the hook, retaining its pose.
  proxy.position.y+=.10*K
  attach(proxy,"utensil_"+str(i),Vector3(0,-.20,0))
 var table: CSGBox3D=stop.get_node("DiningTable")
 hide_proxy(table)
 attach(table,"dining_table",Vector3(0,-.735,0))
 # Basin floor proxy keeps its collision; visual walls extend to the counter opening.
 hide_proxy(stop.get_node("SinkBase"))
 attach(stop,"sink",Vector3(4.45,.72,.20))
 # Replace luminous blue whitebox water with a translucent, gently rippling surface.
 var shader:=Shader.new()
 shader.code="""shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float ripple=sin(world_pos.x*8.0+TIME*.55)*sin(world_pos.z*9.0-TIME*.4);
 ALBEDO=vec3(.07,.13,.20)+ripple*.006;
 ALPHA=.43;
 ROUGHNESS=.38;
 METALLIC=.04;
 SPECULAR=.22;
 NORMAL=normalize(NORMAL+vec3(cos(world_pos.x*8.0+TIME*.55)*.035,0.0,sin(world_pos.z*9.0-TIME*.4)*.035));
}"""
 var water:=ShaderMaterial.new();water.shader=shader
 for name in ["FloodFloor","FloodGap","SinkSpill","CounterWater","SinkWater","CornerWater"]:
  var surface: CSGShape3D=stop.get_node(name)
  surface.material=water
  surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var steam: CSGShape3D=stop.get_node("SteamColumn")
 hide_proxy(steam)
 var gradient:=Gradient.new()
 gradient.set_color(0,Color(1,1,1,.28));gradient.set_color(1,Color(1,1,1,0))
 var texture:=GradientTexture2D.new();texture.gradient=gradient
 texture.width=64;texture.height=64;texture.fill=GradientTexture2D.FILL_RADIAL
 texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
 var mist:=StandardMaterial3D.new()
 mist.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 mist.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
 mist.albedo_color=Color(.73,.78,.81,.65)
 mist.albedo_texture=texture
 mist.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 for i in range(7):
  var puff:=MeshInstance3D.new()
  puff.name="SteamPuff"+str(i)
  var quad:=QuadMesh.new();quad.size=Vector2(.17,.24)*K
  puff.mesh=quad;puff.material_override=mist
  puff.position=Vector3(sin(i*2.1)*.04,sin(i)*.055,-.34+i*.113)*K
  puff.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  steam.add_child(puff)
 for side in ["W","E"]:
  hide_proxy(stop.get_node("FlarePivot"+side+"/Flame"))
  var flame:=attach(stop.get_node("FlarePivot"+side),"flame")
  var fire:=StandardMaterial3D.new()
  fire.albedo_color=Color(1,.40,.08)
  fire.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  fire.emission_enabled=true
  fire.emission=Color(1,.30,.025)
  fire.emission_energy_multiplier=2.0
  for mesh in flame.find_children("*","MeshInstance3D",true,false):mesh.material_override=fire
 # Coils, switch, water, steam and fire remain the live engine-driven visuals.
 var look:=Node.new()
 look.name="KitchenLook"
 look.set_script(load("res://scripts/kitchen_look.gd"))
 room.add_child(look)
 room.set_meta("kitchen_art_installed",true)
