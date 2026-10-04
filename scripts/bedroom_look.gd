extends Node
## Bedroom-only art direction. Gameplay owns darkness, charge and collision geometry.
const K := 9.0
var room: Node3D
var env: Environment
var post: ShaderMaterial
var original_env := {}
var original_post := {}
var fills: Array[Light3D] = []
var dust: Array[GPUParticles3D] = []
var active := false
var opening_framed := false
var toon_materials := {}
var moon_color: Color
var previous_msaa: int
const ENV := {
    "ambient_light_color": Color(.17,.21,.34),
    "tonemap_mode": Environment.TONE_MAPPER_ACES,
    "ssao_enabled": true, "ssao_radius": 1.0, "ssao_intensity": .8,
    "ssao_light_affect": .12,
    "glow_enabled": true, "glow_intensity": .72, "glow_strength": 1.15,
    "glow_hdr_threshold": 1.05,
    "fog_density": .004, "fog_light_color": Color(.035,.045,.08),
    "volumetric_fog_density": .012,
}
const GRADE := {
    "exposure": .96, "contrast": 1.08, "saturation": 1.06,
    "shadow_tint": Vector3(.50,.62,.91), "highlight_tint": Vector3(1,.90,.76),
    "split_tone": .24, "chroma_offset": .00022,
    "grain_amount": .009, "vignette_strength": .31,
    "vignette_radius": 1.05, "vignette_softness": .6,
    "focus_width": .23, "focus_falloff": .40, "max_blur": 1.35,
}
func _ready() -> void:
    room=get_parent()
    var world=room.get_node("WorldEnvironment")
    world.environment=world.environment.duplicate()
    env=world.environment
    var screen=room.get_node("PostFX/Screen")
    screen.material=screen.material.duplicate()
    post=screen.material
    room.get_node("PostFX").mat=post
    for key in ENV:original_env[key]=env.get(key)
    for key in GRADE:original_post[key]=post.get_shader_parameter(key)
    original_post["tilt_shift_enabled"]=post.get_shader_parameter("tilt_shift_enabled")
    moon_color=room.get_node("Moonlight").light_color
    previous_msaa=get_viewport().msaa_3d
    var shaft: SpotLight3D=room.get_node("MoonShaft")
    shaft.light_energy=8.0;shaft.light_color=Color(.65,.76,1)
    shaft.spot_angle=20;shaft.spot_attenuation=.55
    shaft.light_specular=.15;shaft.light_size=.09*K;shaft.light_volumetric_fog_energy=5.0
    var fill: OmniLight3D=room.get_node("MoonFill")
    fill.light_color=Color(.76,.81,.91);fill.light_energy=.30
    fill.light_specular=0;fill.light_size=.025*K
    var desk: OmniLight3D=room.get_node("DeskLampGlow")
    desk.light_color=Color(1,.79,.54);desk.light_energy=1.8;desk.light_size=.05*K;desk.light_specular=.25;desk.light_volumetric_fog_energy=2.2
    var eye: SpotLight3D=room.get_node("Stop1/BigBotEyeLight")
    eye.light_energy=4.5;eye.light_size=.025*K
    _bounce("BedBounce",Vector3(-3.55,1.40,-1.8),Color(.60,.70,1),.13,1.65)
    _bounce("NightstandBounce",Vector3(-3.45,1.0,-1.95),Color(.87,.90,1),.08,1.1)
    _bounce("BoxRim",Vector3(-2.30,.78,-2.12),Color(.58,.70,1),.72,.95)
    _bounce("BoxCardboardBounce",Vector3(-2.65,.44,-2.25),Color(1,.80,.57),.07,.72)
    _bounce("DeskBounce",Vector3(-1.20,1.35,.25),Color(1,.86,.69),.07,.95)
    for mesh in room.get_node("Shell").find_children("*","MeshInstance3D",true,false):
        for surface in mesh.mesh.get_surface_count():
            var material=mesh.get_active_material(surface)
            if material is StandardMaterial3D and material.resource_name=="WindowGlass":
                var glass=material.duplicate()
                glass.roughness=.46;glass.metallic=0;glass.metallic_specular=.12
                mesh.set_surface_override_material(surface,glass)
    _dust("MoonDust",Vector3(-3.06,1.35,-2.38),Vector3(.24,.60,.22),Color(.68,.78,1,.42),110)
    _dust("LampDust",Vector3(-.82,1.0,.50),Vector3(.22,.30,.28),Color(1,.72,.39,.35),60)
    for source in room.find_children("*","Light3D",true,false):
        if source.has_meta("bedroom_logical_light"):fills.append(source)
    room.set_meta("bedroom_look_installed",true)
    for branch in ["Shell", "Bedroom", "Stop0", "Stop1", "Stop2"]:
        var node=room.get_node_or_null(branch)
        if node:_toon_tree(node)
    _set_active(true)
func _bounce(label: String,position_m: Vector3,color: Color,energy: float,range_m: float) -> void:
    var light:=OmniLight3D.new();light.name=label;add_child(light)
    if label.begins_with("Box"):position_m.x+=float(room.get_meta("toybox_offset_m",0.0))
    light.position=position_m*K;light.light_color=color;light.light_energy=energy
    light.omni_range=range_m*K;light.omni_attenuation=1.25
    light.shadow_enabled=true;light.light_size=.08*K
    light.light_specular=0.0;light.light_volumetric_fog_energy=.15
    fills.append(light)
func _dust(label: String,center: Vector3,extent: Vector3,color: Color,count: int) -> void:
    var particles:=GPUParticles3D.new();particles.name=label;add_child(particles)
    particles.position=center*K;particles.amount=count;particles.lifetime=18.0
    particles.preprocess=8.0;particles.visibility_aabb=AABB(-extent*K*2,extent*K*4)
    var motion:=ParticleProcessMaterial.new()
    motion.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
    motion.emission_box_extents=extent*K;motion.gravity=Vector3(0,-.002,0)*K
    motion.direction=Vector3(.5,.1,.2);motion.spread=160
    motion.initial_velocity_min=.004*K;motion.initial_velocity_max=.012*K
    motion.scale_min=.35;motion.scale_max=1.0;particles.process_material=motion
    var gradient:=Gradient.new()
    gradient.set_color(0,Color(1,1,1,1));gradient.set_color(1,Color(1,1,1,0))
    var texture:=GradientTexture2D.new();texture.gradient=gradient
    texture.width=32;texture.height=32;texture.fill=GradientTexture2D.FILL_RADIAL
    texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
    var material:=StandardMaterial3D.new()
    material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    material.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES
    material.albedo_texture=texture;material.albedo_color=color
    var quad:=QuadMesh.new();quad.size=Vector2.ONE*.0025*K;quad.material=material
    particles.draw_pass_1=quad;particles.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    dust.append(particles)
func _set_active(value: bool) -> void:
    active=value
    # One coherent grade across the house; the room still owns power and ending light levels.
    if not room.has_meta("shared_miniature_grade"):
        for key in ENV:env.set(key,ENV[key])
        for key in GRADE:post.set_shader_parameter(key,GRADE[key])
        room.get_node("Moonlight").light_color=Color(.16,.20,.34)
        get_viewport().msaa_3d=Viewport.MSAA_4X
        room.set_meta("shared_miniature_grade",true)
    if not active:post.set_shader_parameter("tilt_shift_enabled",original_post["tilt_shift_enabled"])
func _process(_delta: float) -> void:
    if not is_instance_valid(room.player):return
    if not opening_framed:
        room.player.spring.rotation.x=deg_to_rad(-19)
        _toon_tree(room.player)
        opening_framed=true
    var inside: bool=room.player.global_position.x<-.35*K
    if inside!=active:_set_active(inside)
    var maze: bool=room.player.top_down
    for light in fills:light.visible=active and not maze
    for particles in dust:particles.visible=active and not maze
    if active:post.set_shader_parameter("tilt_shift_enabled",not maze)






# Retain painted albedo, with broad diffuse bands and restrained highlights.
# Transparent glass, invisible collision proxies and luminous parts keep their own shading.
func _toon_material(source: Material) -> Material:
    if not source is StandardMaterial3D:return source
    if source.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or source.emission_enabled:return source
    if source.shading_mode!=BaseMaterial3D.SHADING_MODE_PER_PIXEL:return source
    var id=source.get_instance_id()
    if toon_materials.has(id):return toon_materials[id]
    var material=source.duplicate()
    material.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
    material.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
    material.roughness=maxf(source.roughness,.78)
    material.metallic=minf(source.metallic,.12)
    material.normal_scale=minf(source.normal_scale,.22)
    toon_materials[id]=material
    return material

func _toon_tree(node: Node) -> void:
    # Ceramic keepsakes retain their glaze highlights.
    if node.has_meta("preserve_material_finish"):return
    if node is MeshInstance3D and node.mesh:
        if node.material_override:
            node.material_override=_toon_material(node.material_override)
        else:
            for surface in node.mesh.get_surface_count():
                var source=node.get_active_material(surface)
                if source:node.set_surface_override_material(surface,_toon_material(source))
    elif node is CSGShape3D and "material" in node and node.material:
        node.material=_toon_material(node.material)
    for child in node.get_children():_toon_tree(child)
