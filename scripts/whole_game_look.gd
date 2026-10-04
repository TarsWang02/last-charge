extends Node
## Shared miniature art direction. Light state and gameplay remain owned by the room.
const K:=9.0
var room: Node3D
var materials:={}
var dust_sources: Array=[]
func _ready() -> void:
 room=get_parent()
 call_deferred("_install")
func _install() -> void:
 for key in ["Stop3","Stop4","Stop5","Stop6","People"]:
  _soften(room.get_node(key),"")
 # Clear body/cabinet intersections; only the decorative figures move.
 room.get_node("People/Art_cook_middle_aged").position.z+=.12*K
 room.get_node("People/Art_seated_young_man").position.z-=.18*K
 room.get_node("People/Art_old_man").position.z-=.18*K
 # The screen and fire are broad, soft local sources; no ceiling lamps during the blackout.
 var tv: Light3D=room.get_node("TVGlow")
 tv.light_color=Color(.48,.60,.90);tv.light_size=.065*K
 tv.light_specular=.16;tv.light_volumetric_fog_energy=.85
 var sofa_bounce=room.get_node_or_null("TVLivingroomLook/TVSofaBounce")
 if sofa_bounce:
  sofa_bounce.set_meta("base_energy",.16)
  sofa_bounce.light_color=Color(.46,.58,.85)
 var stove: Light3D=room.get_node("StoveGlow")
 stove.light_color=Color(1,.64,.34);stove.light_size=.055*K
 stove.light_specular=.22;stove.light_volumetric_fog_energy=1.15
 var flood: OmniLight3D=room.get_node("FloodSheen")
 flood.light_color=Color(.52,.63,.84);flood.light_energy=.58
 flood.light_size=.12*K;flood.light_specular=.18;flood.light_volumetric_fog_energy=.22
 var fault: OmniLight3D=room.get_node("BreakerFaultLight")
 fault.light_color=Color(1,.20,.09);fault.light_energy=.58
 fault.omni_range=.52*K;fault.light_size=.012*K;fault.light_specular=.1
 fault.light_volumetric_fog_energy=.45
 # Diffuse sky through the long window, restricted to the sill and seat.
 _bounce("WindowSkyBounce",Vector3(1.55,1.48,2.49),Color(.61,.70,.91),.34,1.45)
 _bounce("SinkSkyBounce",Vector3(4.20,1.50,2.38),Color(.59,.70,.87),.19,1.60)
 _bounce("BreakerSkyBounce",Vector3(.04,1.62,2.46),Color(.58,.66,.84),.16,.82)
 _dust("TVFloatingDust",Vector3(.90,1.00,-1.65),Vector3(.42,.29,.36),Color(.55,.65,.91,.20),32,tv)
 _dust("KitchenFloatingDust",Vector3(3.76,1.32,-2.0),Vector3(.45,.32,.27),Color(.98,.73,.45,.20),34,stove)
 _dust("WindowFloatingDust",Vector3(1.65,1.39,2.24),Vector3(1.4,.42,.19),Color(.64,.75,.92,.17),42,null)
 room.set_meta("whole_game_art_installed",true)
 print("WHOLE_GAME_ART materials=",materials.size())
func _soften(node: Node,context: String) -> void:
 if node.has_meta("preserve_material_finish"):return
 context+="/"+str(node.name).to_lower()
 if node is MeshInstance3D and node.mesh:
  if node.material_override:node.material_override=_material(node.material_override,context)
  else:
   for index in node.mesh.get_surface_count():
    var source=node.get_active_material(index)
    if source:node.set_surface_override_material(index,_material(source,context))
 elif node is CSGShape3D and "material" in node and node.material:
  node.material=_material(node.material,context)
 for child in node.get_children():_soften(child,context)
func _material(source: Material,context: String) -> Material:
 if not source is StandardMaterial3D:return source
 if source.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or source.emission_enabled or source.shading_mode!=BaseMaterial3D.SHADING_MODE_PER_PIXEL:return source
 var metal:=false
 for token in ["kettle","stock_pot","dish_pot","dish_lid","ladle","utensil","rail_","range_hood","faucet","sink","breaker","speaker","crt_tv"]:
  if token in context:metal=true
 var ceramic: bool="mug" in context or "bowl" in context or "plates" in context
 var key:=str(source.get_instance_id())+str(metal)+str(ceramic)
 if materials.has(key):return materials[key]
 var material: StandardMaterial3D=source.duplicate()
 material.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
 material.normal_scale=minf(material.normal_scale,.22)
 material.roughness=maxf(material.roughness,.56 if metal or ceramic else .78)
 material.metallic=minf(material.metallic,.20 if metal else .06)
 material.specular_mode=BaseMaterial3D.SPECULAR_SCHLICK_GGX if metal or ceramic else BaseMaterial3D.SPECULAR_DISABLED
 material.metallic_specular=.22 if metal else .18
 material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
 materials[key]=material
 return material
func _bounce(label: String,p: Vector3,color: Color,energy: float,radius: float) -> void:
 var light:=OmniLight3D.new();light.name=label;add_child(light)
 light.position=p*K;light.light_color=color;light.light_energy=energy
 light.omni_range=radius*K;light.omni_attenuation=1.6;light.light_size=.10*K
 light.shadow_enabled=true;light.light_specular=.05;light.light_volumetric_fog_energy=.18
func _dust(label: String,p: Vector3,extent: Vector3,color: Color,count: int,source: Light3D) -> void:
 var particles:=GPUParticles3D.new();particles.name=label;add_child(particles)
 particles.position=p*K;particles.amount=count;particles.lifetime=20.0;particles.preprocess=7.0
 particles.visibility_aabb=AABB(-extent*K*2,extent*K*4)
 var motion:=ParticleProcessMaterial.new()
 motion.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;motion.emission_box_extents=extent*K
 motion.gravity=Vector3(0,-.002,0)*K;motion.direction=Vector3(.5,.1,.2);motion.spread=160
 motion.initial_velocity_min=.004*K;motion.initial_velocity_max=.010*K
 motion.scale_min=.35;motion.scale_max=1.0;particles.process_material=motion
 var gradient:=Gradient.new();gradient.set_color(0,Color.WHITE);gradient.set_color(1,Color(1,1,1,0))
 var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.width=32;texture.height=32
 texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
 var material:=StandardMaterial3D.new();material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES
 material.albedo_texture=texture;material.albedo_color=color
 var quad:=QuadMesh.new();quad.size=Vector2.ONE*.0022*K;quad.material=material
 particles.draw_pass_1=quad;particles.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 if source:dust_sources.append([particles,source])
func _process(delta: float) -> void:
 if is_instance_valid(room.player):
  # Ease across the doorway: the open room receives more unobstructed sky than the bedroom.
  var sky:=smoothstep(-.70,-.35,room.player.global_position.x/K)
  var tint:=Color(.16,.20,.34).lerp(Color(.42,.49,.67),sky)
  var moon: Light3D=room.get_node("Moonlight")
  moon.light_color=moon.light_color.lerp(tint,1.0-exp(-3.0*delta))
 for pair in dust_sources:pair[0].visible=pair[1].visible and pair[1].light_energy>.04
