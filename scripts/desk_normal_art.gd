extends RefCounted
const K:=9.0
static func put(parent: Node3D,label: String,path: String,p: Vector3,scale_m:=Vector3.ONE,yaw:=0.0) -> Node3D:
 var model: Node3D=load(path).instantiate();model.name=label
 parent.add_child(model);model.position=p*K;model.scale=scale_m*K;model.rotation.y=yaw
 model.set_meta("art_asset",label)
 return model
static func install(room: Node3D) -> void:
 var stop: Node3D=room.get_node("Stop2")
 if stop.has_node("DeskNormal"):return
 var normal:=Node3D.new();normal.name="DeskNormal";stop.add_child(normal)
 for row in [["tabletop",Vector3(-.81,.75,.15),0.0],["homework",Vector3(-1.015,.751,.50),-.04],["textbooks",Vector3(-.56,.751,-.12),0.0],["ruler_protractor",Vector3(-.78,.751,.18),-.18],["pencil",Vector3(-1.10,.757,.58),-.30],["spoon",Vector3(-.56,.751,.745),0.0],["clutter",Vector3(-.88,.751,-.14),.10],["mum_note",Vector3(-.81,.751,.73),-.07]]:
  put(normal,"desk_n_"+row[0],"res://assets/models/props/desk_n_"+row[0]+".glb",row[1],Vector3.ONE,row[2])
 # Same mesh and colour as the maze, at ordinary desk scale.
 put(normal,"desk_n_eraser","res://assets/models/props/desk_n_eraser.glb",Vector3(-.945,.756,.405),Vector3.ONE*.32,.12)
 put(normal,"desk_n_pencil_case","res://assets/models/props/desk_n_pencil_case.glb",Vector3(-.72,.751,.43),Vector3(.80,.55,1.8),-.10)
 put(normal,"desk_n_mug","res://assets/models/props/desk_n_mug.glb",Vector3(-.56,.751,.745),Vector3.ONE*2.08,PI/2)
 put(normal,"desk_n_alarm_clock","res://assets/models/props/desk_n_alarm_clock.glb",Vector3(-.54,.751,-.34),Vector3(2.0,.62,1.7),-PI/2)
 # Looser paper layers and reused maze stationery, all below the sight lines.
 for row in [["desk_n_clutter",Vector3(-.86,.752,-.31),Vector3.ONE*.70,.34],["desk_n_clutter",Vector3(-.66,.752,.035),Vector3.ONE*.72,-.19],["desk_n_pencil",Vector3(-.76,.753,-.115),Vector3.ONE*.68,.55],["desk_n_pencil",Vector3(-.92,.753,.24),Vector3.ONE*.57,1.0]]:
  put(normal,"Loose_"+row[0],"res://assets/models/props/"+row[0]+".glb",row[1],row[2],row[3])
 put(normal,"OpenSchoolbook","res://assets/models/props/prop_desk_open_book.glb",Vector3(-1.01,.751,.11),Vector3.ONE*2.10,.13)
 for row in [["paper_ball",Vector3(-.64,.752,.62),1.3,.0],["paper_ball",Vector3(-1.11,.752,.235),1.0,.5],["paper_ball",Vector3(-.57,.752,.15),.8,.2],["paperclip",Vector3(-.86,.756,-.15),1.7,.4],["paperclip",Vector3(-1.08,.757,.435),1.3,-.7],["paperclip",Vector3(-.77,.753,.66),1.4,1.0],["pencil_shaving",Vector3(-1.07,.757,.595),1.5,.4],["pencil_shaving",Vector3(-1.045,.757,.62),1.1,-.7],["pencil_shaving",Vector3(-1.03,.757,.635),1.0,1.0],["pencil_shaving",Vector3(-.965,.752,.295),1.3,.6]]:
  put(normal,"Scatter_"+row[0],"res://assets/models/props/prop_desk_"+row[0]+".glb",row[1],Vector3.ONE*row[2],row[3])
 var lamp_look:=Node.new();lamp_look.name="DeskLampLook"
 lamp_look.set_script(load("res://scripts/desk_lamp_look.gd"));room.add_child(lamp_look)
 # Tea sits below the rim; no glow, no extra light source.
 var tea:=MeshInstance3D.new();tea.name="ColdTea";normal.add_child(tea)
 var surface:=CylinderMesh.new();surface.top_radius=.022*K;surface.bottom_radius=.022*K;surface.height=.0005*K;surface.radial_segments=24
 tea.mesh=surface;tea.position=Vector3(-.56,.805,.745)*K
 var tea_mat:=StandardMaterial3D.new();tea_mat.albedo_color=Color(.19,.11,.055);tea_mat.roughness=.36;tea_mat.metallic_specular=.16;tea.material_override=tea_mat
 normal.set_meta("no_collision_decoration",true)
 room.set_meta("desk_normal_art_installed",true)
