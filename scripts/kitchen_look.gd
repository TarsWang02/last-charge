extends Node
var room: Node3D
var coil_material: StandardMaterial3D
func _ready() -> void:
 room=get_parent()
 toon(room.get_node("Stop4"))
 toon(room.get_node("People/Art_cook_middle_aged"))
 coil_material=StandardMaterial3D.new()
 coil_material.albedo_color=Color(.08,.07,.065)
 coil_material.roughness=.65
 for mesh in room.get_node("Stop4/ToasterCoils/Art_toaster_coils").find_children("*","MeshInstance3D",true,false):mesh.material_override=coil_material
 # A restrained cool fill reflects the flooded floor, contrasted with live stove fire.
 var fill:=OmniLight3D.new()
 fill.name="KitchenWaterBounce"
 fill.position=Vector3(4.04,.22,.15)*9
 fill.light_color=Color(.16,.24,.43)
 fill.light_energy=.30
 fill.omni_range=2.1*9
 fill.omni_attenuation=1.5
 fill.shadow_enabled=true
 room.add_child(fill)
 var mug_light:=OmniLight3D.new()
 mug_light.name="DaughterMemoryBounce"
 mug_light.position=Vector3(4.24,1.10,2.45)*9
 mug_light.light_color=Color(1,.62,.30)
 mug_light.light_energy=.40
 mug_light.omni_range=.42*9
 mug_light.shadow_enabled=true
 room.add_child(mug_light)
func _process(_delta: float) -> void:
 var source=room.get_node("Stop4/ToasterCoils").material
 if source is StandardMaterial3D:
  coil_material.emission_enabled=source.emission_enabled
  coil_material.emission=source.emission
  coil_material.emission_energy_multiplier=source.emission_energy_multiplier
func toon(node: Node) -> void:
 if node is MeshInstance3D and node.mesh:
  for i in node.mesh.get_surface_count():
   var source=node.get_active_material(i)
   if source is StandardMaterial3D:
    var mat: StandardMaterial3D=source.duplicate()
    mat.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
    mat.roughness=maxf(mat.roughness,.65)
    mat.metallic=minf(mat.metallic,.22)
    mat.specular_mode=BaseMaterial3D.SPECULAR_SCHLICK_GGX
    node.set_surface_override_material(i,mat)
 for child in node.get_children():toon(child)
