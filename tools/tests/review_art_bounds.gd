extends SceneTree
func _initialize():call_deferred("run")
func bounds(n: Node3D)->AABB:
 var result:=AABB();var first:=true
 for m in n.find_children("*","MeshInstance3D",true,false):
  if not m.is_visible_in_tree():continue
  for i in 8:
   var p: Vector3=m.global_transform*m.get_aabb().get_endpoint(i)/9.0
   if first:result=AABB(p,Vector3.ZERO);first=false
   else:result=result.expand(p)
 return result
func run():
 var room=load("res://scenes/room.tscn").instantiate();root.add_child(room);room._op_skip=true
 await create_timer(.6).timeout
 for row in [["People/Art_cook_middle_aged",AABB(Vector3(3.4,.04,-2.65),Vector3(.6,.82,.60))],["People/Art_old_man",AABB(Vector3(1.27,.25,1.43),Vector3(.66,.15,.58))],["People/Art_seated_young_man",AABB(Vector3(.75,.20,-1.25),Vector3(1.4,.20,.5))]]:
  var count:=0;var hit:=AABB();var first:=true
  for m in room.get_node(row[0]).find_children("*","MeshInstance3D",true,false):
   for surf in m.mesh.get_surface_count():
    var vs: PackedVector3Array=m.mesh.surface_get_arrays(surf)[Mesh.ARRAY_VERTEX]
    for v in vs:
     var p: Vector3=m.global_transform*v/9.0
     if row[1].has_point(p):
      count+=1
      if first:hit=AABB(p,Vector3.ZERO);first=false
      else:hit=hit.expand(p)
  print("PENETRATION ",row[0]," count=",count," bounds=",hit)
 quit()
