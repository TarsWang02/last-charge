extends SceneTree
var checks := {}
func _initialize():call_deferred("run")
func run():
 var room=load("res://scenes/room.tscn").instantiate()
 root.add_child(room)
 await create_timer(.4).timeout
 var stop=room.get_node("Stop3")
 for entry in [["GameBoxes","game_boxes",.09],["MagStack","magazine_stack",.19],["Subwoofer","subwoofer",.29],["SpeakerTall","speaker_tall",.39],["TVCabinet","tv_cabinet",.50]]:
  var proxy=stop.get_node(entry[0])
  var art=proxy.get_node("Art_"+entry[1])
  var top:float=-INF
  for mesh in art.find_children("*","MeshInstance3D",true,false):
   var bounds: AABB=mesh.get_aabb()
   for i in 8:top=maxf(top,(mesh.global_transform*bounds.get_endpoint(i)).y)
  checks[entry[0]+"_surface_height"]=absf(top-entry[2]*9)<.09
  checks[entry[0]+"_collision_preserved"]=proxy.use_collision
 var tv=stop.get_node("CRT/Art_crt_tv")
 var clear:=true
 var screen=Rect2(.76,.56,.48,.38).grow(-.003)
 for mesh in tv.find_children("*","MeshInstance3D",true,false):
  var lo:=Vector3(INF,INF,INF);var hi:=-lo
  for i in 8:
   var p:Vector3=mesh.global_transform*mesh.get_aabb().get_endpoint(i)/9
   lo=lo.min(p);hi=hi.max(p)
  if hi.z>=-2.178 and Rect2(Vector2(lo.x,lo.y),Vector2(hi.x-lo.x,hi.y-lo.y)).intersects(screen):clear=false
 checks["live_screen_opening_clear"]=clear
 var lid=stop.get_node("TimeBoxLid")
 var child=lid.get_node("Art_time_box_lid")
 checks["lid_origin_is_hinge"]=child.position.is_zero_approx()
 lid.rotation.x=deg_to_rad(-105)
 checks["lid_follows_original_pivot"]=child.global_transform.is_equal_approx(lid.global_transform.scaled_local(Vector3.ONE*9))
 checks["eight_tripo_views_ready"]=true
 for asset in ["01_seated_young_man","02_sofa"]:
  for view in ["front","back","left","right"]:
   if not FileAccess.file_exists("res://docs/art_production_20261004/tv_livingroom/tripo_references/"+asset+"/"+view+".png"):checks["eight_tripo_views_ready"]=false
 var passed:=true
 for value in checks.values():if not value:passed=false
 print("TVARTTEST ",JSON.stringify(checks))
 quit(0 if passed else 1)
