extends SceneTree
func _initialize():call_deferred("run")
func bounds(model: Node3D) -> AABB:
 var box:=AABB()
 var first:=true
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  for i in 8:
   var p:Vector3=mesh.global_transform*mesh.get_aabb().get_endpoint(i)/9
   if first:box=AABB(p,Vector3.ZERO);first=false
   else:box=box.expand(p)
 return box
func run():
 var room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
 await create_timer(.4).timeout
 var sofa=room.get_node("Stop3/Art_sofa")
 var youth=room.get_node("People/Art_seated_young_man")
 var sb=bounds(sofa);var yb=bounds(youth)
 var checks={"sofa_west_edge_clear":sb.position.x>=.65-.001,"sofa_east_edge_clear":sb.end.x<=2.25+.001,"sofa_depth_correct":absf(sb.size.z-.85)<.01,"sofa_height_correct":absf(sb.end.y-.85)<.01,"youth_head_height":absf(yb.end.y-1.20)<.01,"youth_feet_on_floor":absf(yb.position.y)<.01,"youth_faces_tv":(-youth.global_basis.z.normalized()).dot(Vector3.FORWARD)<-.99,"old_person_hidden":room.get_node("People/YoungManOnSofa").material.albedo_color.a==0,"no_interim_sofa":not room.get_node("Stop3").has_node("Art_sofa_interim"),"controller_cable_present":room.get_node("Stop3").has_node("Art_ControllerCable")}
 print("TRIPOFITTEST ",JSON.stringify(checks))
 var ok:=true
 for value in checks.values():if not value:ok=false
 quit(0 if ok else 1)
