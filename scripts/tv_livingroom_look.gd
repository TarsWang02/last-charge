extends Node
## Local TV spill only; fades with the existing screen light when the television turns off.
var source: OmniLight3D
var bounces: Array[OmniLight3D]=[]
func _ready():
 var room=get_parent()
 source=room.get_node("TVGlow")
 for entry in [["TVWallBounce",Vector3(.24,.55,-2.00),.75,.95],["TVSofaBounce",Vector3(.86,.60,-1.58),.07,.65]]:
  var light:=OmniLight3D.new()
  light.name=entry[0]
  light.position=entry[1]*9
  light.light_color=Color(.25,.36,.78)
  light.light_energy=entry[2]
  light.omni_range=entry[3]*9
  light.light_specular=.05
  light.shadow_enabled=true
  light.set_meta("base_energy",entry[2])
  add_child(light)
  bounces.append(light)
func _process(_delta):
 for light in bounces:light.light_energy=light.get_meta("base_energy")*clampf(source.light_energy/2.0,0,1)
