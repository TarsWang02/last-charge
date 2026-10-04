extends RefCounted
const K:=9.0
static func _material(color: Color,glow:=false) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.78
    if glow:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=1.8
    return m
static func _part(parent: Node3D,label: String,mesh: Mesh,position_m: Vector3,material: Material) -> MeshInstance3D:
    var part:=MeshInstance3D.new();part.name=label;part.mesh=mesh;part.material_override=material
    parent.add_child(part);part.position=position_m*K;return part
static func install(room: Node3D) -> void:
    if not room.has_meta("bedroom_layout_version") or room.has_meta("bedroom_layout_art_installed"):return
    var dx: float=room.get_meta("toybox_offset_m")
    var art: Node3D=room.get_node("Stop0/Nightstand/Art_nightstand")
    art.scale.x*=5.0/3.0;art.scale.z*=5.0/3.0
    # Runtime art roots are not serialized; translate every directly authored art root too.
    for child in room.get_node("Stop1").get_children():
        if child is Node3D and (child.name=="ImportedArt" or child.has_meta("art_asset")):
            child.position.x+=dx*K
    var stop:=room.get_node("Stop1")
    var torch:=Node3D.new();torch.name="BoxBatteryTorch";stop.add_child(torch)
    torch.position=Vector3(-2.812+dx,.49,-2.48)*K
    torch.look_at(Vector3(-2.42+dx,.13,-2.22)*K)
    var shell:=CylinderMesh.new();shell.top_radius=.018*K;shell.bottom_radius=.018*K;shell.height=.052*K
    var casing:=_part(torch,"OxideRedCasing",shell,Vector3.ZERO,_material(Color(.30,.075,.04)))
    casing.rotation.x=PI/2
    var ring:=CylinderMesh.new();ring.top_radius=.019*K;ring.bottom_radius=.019*K;ring.height=.005*K
    _part(torch,"DarkLensRim",ring,Vector3(0,0,-.028),_material(Color(.085,.075,.06))).rotation.x=PI/2
    var lens:=CylinderMesh.new();lens.top_radius=.013*K;lens.bottom_radius=.013*K;lens.height=.002*K
    _part(torch,"WarmLens",lens,Vector3(0,0,-.032),_material(Color(1,.68,.30),true)).rotation.x=PI/2
    var clip:=BoxMesh.new();clip.size=Vector3(.009,.024,.021)*K
    _part(torch,"Clip",clip,Vector3(0,-.024,.010),_material(Color(.13,.12,.10)))
    var beam:=SpotLight3D.new();beam.name="BatteryTorchBeam";torch.add_child(beam)
    beam.position.z=-.035*K;beam.light_color=Color(1,.76,.43);beam.light_energy=6.5
    beam.spot_range=1.12*K;beam.spot_angle=53;beam.spot_attenuation=.70
    beam.light_size=.008*K;beam.shadow_enabled=true;beam.light_specular=.2
    beam.light_volumetric_fog_energy=1.0;beam.set_meta("bedroom_logical_light",true)
    var train: Node3D=stop.get_node("Train")
    var bulb:=SphereMesh.new();bulb.radius=.005*K;bulb.height=.010*K
    _part(train,"TrainHeadlamp",bulb,Vector3(.053,.039,0),_material(Color(1,.78,.45),true))
    var headlamp:=OmniLight3D.new();headlamp.name="TrainLampGlow";train.add_child(headlamp)
    headlamp.position=Vector3(.057,.039,0)*K;headlamp.light_color=Color(1,.80,.48)
    headlamp.light_energy=1.15;headlamp.omni_range=.33*K;headlamp.shadow_enabled=true
    headlamp.light_size=.004*K;headlamp.light_specular=.15;headlamp.set_meta("bedroom_logical_light",true)
    var eyes: SpotLight3D=stop.get_node("BigBotEyeLight")
    eyes.light_energy=4.5;eyes.spot_angle=44;eyes.spot_range=1.05*K
    eyes.look_at(Vector3(-2.13+dx,.20,-2.40)*K)
    room.get_node("Stop0/PhotoFrame/Frame").layers=0
    var photo: MeshInstance3D=room.get_node("Stop0/PhotoFrame").find_child("FamilyPhoto",true,false)
    var arrays: Array=photo.mesh.surface_get_arrays(0)
    var uv:=PackedVector2Array()
    for vertex in arrays[Mesh.ARRAY_VERTEX]:
        uv.append(Vector2((vertex.x-.010)/.110,1.0-(vertex.z-.010)/.160))
    arrays[Mesh.ARRAY_TEX_UV]=uv
    var print_mesh:=ArrayMesh.new()
    print_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    photo.mesh=print_mesh
    var print_material:=StandardMaterial3D.new()
    print_material.albedo_texture=load("res://assets/models/props/prop_photo_frame_family_photo.png")
    print_material.roughness=.92
    print_material.cull_mode=BaseMaterial3D.CULL_DISABLED
    photo.material_override=print_material
    # Personal keepsake beside the family photograph. Decoration only, no collision.
    var dog: Node3D=load("res://assets/models/props/prop_porcelain_dog.glb").instantiate()
    dog.name="Art_porcelain_dog"
    room.get_node("Stop0").add_child(dog)
    dog.position=Vector3(-3.06,.72,-2.40)*K
    dog.rotation.y=deg_to_rad(-25)
    dog.scale=Vector3.ONE*K
    dog.set_meta("art_asset","porcelain_dog")
    dog.set_meta("preserve_material_finish",true)
    room.set_meta("bedroom_layout_art_installed",true)
