extends SceneTree
func _initialize():call_deferred("run")
func run():
 var room=load("res://scenes/room.tscn").instantiate();root.add_child(room)
 await create_timer(5).timeout
 var result={}
 result["boxes"]=await room._hop(Vector3(.35,0,-1.70),.05,0)
 result["magazines"]=await room._hop(Vector3(.36,0,-1.86),.86,0)
 result["subwoofer"]=await room._hop(Vector3(.37,0,-2.02),1.76,0)
 result["speaker"]=await room._hop(Vector3(.38,0,-2.20),2.66,0)
 result["cabinet"]=await room._hop(Vector3(.40,0,-2.45),3.56,-PI/2)
 print("TVCLIMBTEST ",JSON.stringify(result))
 quit()
