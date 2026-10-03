extends Node3D
## Mirror the original note's proximity emission onto its printed replacement.
var materials: Array[StandardMaterial3D] = []
func _ready() -> void:
 _collect(self)
func _collect(node: Node) -> void:
 if node is MeshInstance3D:
  for surface in node.mesh.get_surface_count():
   var original = node.get_active_material(surface)
   if original is StandardMaterial3D:
    var mat: StandardMaterial3D = original.duplicate()
    node.set_surface_override_material(surface, mat)
    materials.append(mat)
 for child in node.get_children(): _collect(child)
func _process(_delta: float) -> void:
 var source = get_parent().material_override
 if source is StandardMaterial3D and source.emission_enabled:
  for material in materials:
   material.emission_enabled = true
   material.emission = source.emission
   material.emission_energy_multiplier = source.emission_energy_multiplier
