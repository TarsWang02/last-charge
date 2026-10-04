extends SceneTree
func _initialize():call_deferred("run")
func bounds(node: Node3D) -> AABB:
 var box:=AABB();var first:=true
 for mesh in node.find_children("*","MeshInstance3D",true,false):
  for i in 8:
   var p: Vector3=mesh.global_transform*mesh.get_aabb().get_endpoint(i)/9
   if first:box=AABB(p,Vector3.ZERO);first=false
   else:box=box.expand(p)
 return box
func run():
 var room=load("res://scenes/room.tscn").instantiate()
 var snapshots={}
 for node in room.get_node("Stop4").find_children("*","CSGShape3D",true,false):
  if node.use_collision:
   snapshots[str(room.get_path_to(node))]=[node.transform,node.use_collision]
 root.add_child(room)
 await create_timer(.8).timeout
 room.player.locked=true
 var checks={}
 checks["collision_proxies_retained"]=true
 for path in snapshots:
  var node=room.get_node(path)
  if node.transform!=snapshots[path][0] or node.use_collision!=snapshots[path][1]:checks["collision_proxies_retained"]=false
 var stop=room.get_node("Stop4")
 for entry in [["CounterA/Art_counter_a",.90],["CounterB/Art_counter_b",.90],["CannedGoods/Art_canned_goods",.11],["StepStool/Art_step_stool",.33],["Art_chair",.80],["Lunchbox/Art_lunchbox",.55],["CerealBox/Art_cereal_box",.67],["CuttingBoard/Art_cutting_board",.91],["Toaster/Art_toaster",1.08],["DishRack/Art_dish_rack",1.15],["DishLid/Art_dish_lid",.99]]:
  checks[entry[0]+"_height"]=absf(bounds(stop.get_node(entry[0])).end.y-entry[1])<=.01
 checks["hood_underside"]=absf(bounds(stop.get_node("RangeHood/Art_range_hood")).position.y-1.46)<.01
 checks["door_east_hinge"]=stop.get_node("MicrowaveDoor").position.is_equal_approx(Vector3(2.72,.90,-2.30)*9)
 checks["utensil_hook_pivots"]=true
 for i in range(1,5):
  if absf(stop.get_node("HangingUtensil"+str(i)).global_position.y/9-1.30)>.001:checks["utensil_hook_pivots"]=false
 checks["no_art_collision"]=stop.find_children("Art_*","CollisionObject3D",true,false).is_empty()
 var heat:=StandardMaterial3D.new();heat.emission_enabled=true;heat.emission=Color(1,.35,.1);heat.emission_energy_multiplier=4
 stop.get_node("ToasterCoils").material=heat
 await process_frame
 await process_frame
 checks["coils_follow_live_heat"]=room.get_node("KitchenLook").coil_material.emission_enabled and room.get_node("KitchenLook").coil_material.emission_energy_multiplier==4
 print("KITCHENARTCHECK ",JSON.stringify(checks))
 var ok:=true
 for value in checks.values():if not value:ok=false
 quit(0 if ok else 1)
