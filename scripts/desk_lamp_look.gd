extends Node
const K:=9.0
var room: Node3D
var source: OmniLight3D
var beam: SpotLight3D
var bounce: OmniLight3D
var bulb_material: StandardMaterial3D
func _ready() -> void:
 room=get_parent();process_priority=10
 call_deferred("install")
func install() -> void:
 source=room.get_node("DeskLampGlow")
 # Retain the original energy property for the flicker/blackout/ending tweens.
 source.layers=0;source.light_volumetric_fog_energy=0
 beam=SpotLight3D.new();beam.name="DeskLampDownlight";add_child(beam)
 beam.global_position=source.global_position
 beam.look_at(Vector3(-.93,.751,.40)*K,Vector3.FORWARD)
 beam.light_color=Color(1,.79,.54);beam.spot_range=1.16*K
 beam.spot_angle=56;beam.spot_attenuation=.70
 beam.light_size=.025*K;beam.shadow_enabled=true
 beam.light_specular=.16;beam.light_volumetric_fog_energy=.75
 bounce=OmniLight3D.new();bounce.name="DeskPaperBounce";add_child(bounce)
 bounce.position=Vector3(-.94,.91,.47)*K;bounce.omni_range=.70*K
 bounce.light_color=Color(1,.83,.62);bounce.light_size=.09*K
 bounce.shadow_enabled=true;bounce.light_specular=0;bounce.light_volumetric_fog_energy=.08
 var bulb=room.get_node("Stop2/WallLampShade/Art_wall_lamp").find_child("LampBulb",true,false)
 if bulb and bulb.material_override is StandardMaterial3D:
  bulb_material=bulb.material_override.duplicate();bulb.material_override=bulb_material
func _process(_delta: float) -> void:
 if not is_instance_valid(beam):return
 beam.light_energy=source.light_energy*2.30
 bounce.light_energy=source.light_energy*.045
 beam.visible=source.visible;bounce.visible=source.visible
 # The lamp reappears naturally when the ending restores its source; the maze remains unobstructed.
 if source.visible and source.light_energy>.02 and is_instance_valid(room.player) and not room.player.top_down:
  room.get_node("Stop2/WallLampShade").visible=true
 if bulb_material:bulb_material.emission_energy_multiplier=1.5*clampf(source.light_energy/1.8,0,1)
 var dust=room.get_node_or_null("BedroomLook/LampDust")
 if dust and is_instance_valid(room.player):dust.visible=source.visible and source.light_energy>.02 and not room.player.top_down
