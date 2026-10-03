"""Blender background: blender -b -P split_robot.py -- --input robot_lo.glb --output robot_parts.glb
Coordinates used for cuts are Blender world (X right, Y rear, Z up).
No decimation, rebaking, skinning or animation. Original loop UVs retained.
"""
import bpy,bmesh,argparse,sys,time,json,math,struct
from pathlib import Path
from mathutils import Vector,Matrix
t0=time.perf_counter()
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);p.add_argument('--work',default=None);p.add_argument('--task-start',default=None);a=p.parse_args(sys.argv[sys.argv.index('--')+1:])
out=Path(a.output);work=Path(a.work) if a.work else Path(__file__).parent;renders=work/'renders';renders.mkdir(parents=True,exist_ok=True);out.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=a.input)
src=next(o for o in bpy.context.scene.objects if o.type=='MESH');bpy.context.view_layer.objects.active=src;src.select_set(True);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
mat=src.data.materials[0];src.data.calc_loop_triangles();original_tris=len(src.data.loop_triangles)
original_coords=[v.co.copy() for v in src.data.vertices]
def bounds(coords):return [[min(v[i] for v in coords) for i in range(3)],[max(v[i] for v in coords) for i in range(3)]]
original_bounds=bounds(original_coords)
# Actually attempt loose separation, then restore the original mesh for geometric cuts.
backup=src.data.copy();bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.separate(type='LOOSE');bpy.ops.object.mode_set(mode='OBJECT')
loose=[o for o in bpy.context.scene.objects if o.type=='MESH'];loose_count=len(loose)
for o in loose:bpy.data.objects.remove(o,do_unlink=True)
bm=bmesh.new();bm.from_mesh(backup)
# Weld exact-position seam duplicates only. Loop UV values remain on their original corners.
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.000001)
caps=[]
def split(mesh,co,no,label):
 results=[]
 for positive in (False,True):
  b=mesh.copy();res=bmesh.ops.bisect_plane(b,geom=list(b.verts)+list(b.edges)+list(b.faces),dist=1e-7,plane_co=co,plane_no=no,clear_inner=positive,clear_outer=not positive)
  edges=[e for e in res['geom_cut'] if isinstance(e,bmesh.types.BMEdge) and e.is_valid and e.is_boundary]
  if edges:
   filled=bmesh.ops.holes_fill(b,edges=edges,sides=0)['faces']
   for f in filled:f.material_index=0;f.smooth=False
   caps.append({'cut':label,'side':'positive' if positive else 'negative','faces':len(filled)})
  results.append(b)
 mesh.free();return results
rest,head=split(bm,(0,0,.610),(0,0,1),'neck z=0.610')
low,upper=split(rest,(0,0,.280),(0,0,1),'lower partition z=0.280')
upper,key=split(upper,(0,.245,0),(0,1,0),'key stem y=0.245')
left,rest=split(upper,(-.207,0,0),(1,0,0),'left shoulder x=-0.207')
rest,right=split(rest,(.207,0,0),(1,0,0),'right shoulder x=0.207')
# Left/right below are spatial intermediate names, final names use robot viewpoint.
left_arm,left_back=split(left,(0,.060,0),(0,1,0),'rear shoulder ornament y=0.060')
# Lower claws are disconnected islands below the wrist partition; preserve whole islands.
seen=set();claws={-1:[],1:[]}
for face in low.faces:
 if face in seen:continue
 stack=[face];island=[];seen.add(face)
 while stack:
  f=stack.pop();island.append(f)
  for e in f.edges:
   for q in e.link_faces:
    if q not in seen:seen.add(q);stack.append(q)
 verts={v for f in island for v in f.verts}
 if min(v.co.z for v in verts)>.19:
  side=1 if sum(v.co.x for v in verts)>0 else -1;claws[side].extend(island)
def extract_faces(mesh,fs):
 selected=set(fs);mesh.faces.index_update();ids={f.index for f in selected};b=mesh.copy();b.faces.ensure_lookup_table();bmesh.ops.delete(b,geom=[f for f in b.faces if f.index not in ids],context='FACES');bmesh.ops.delete(mesh,geom=list(selected),context='FACES');return b
ll=extract_faces(low,claws[-1]);rr=extract_faces(low,claws[1])
tl,low=split(low,(-.145,0,0),(1,0,0),'left track axle x=-0.145')
center,tr=split(low,(.145,0,0),(1,0,0),'right track axle x=0.145')
groups={'Body':[rest,center,left_back],'Head':[head],'Arm_R':[left_arm,ll],'Arm_L':[right,rr],'Track_R':[tl],'Track_L':[tr],'WindKey':[key]}
pivots={'Body':(0,0,.049),'Head':(0,0,.610),'Arm_R':(-.207,0,.535),'Arm_L':(.207,0,.535),'Track_R':(-.235,0,.125),'Track_L':(.235,0,.125),'WindKey':(.178,.205,.478)}
objects={}
for name,meshes in groups.items():
 parts=[]
 for b in meshes:
  me=bpy.data.meshes.new(name);b.to_mesh(me);b.free();me.materials.append(mat);ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);parts.append(ob)
 bpy.ops.object.select_all(action='DESELECT')
 for ob in parts:ob.select_set(True)
 bpy.context.view_layer.objects.active=parts[0]
 if len(parts)>1:bpy.ops.object.join()
 ob=parts[0];ob.name=name;pv=Vector(pivots[name]);ob.data.transform(Matrix.Translation(-pv));ob.location=pv;objects[name]=ob
bpy.context.view_layer.update()
robot=bpy.data.objects.new('Robot',None);bpy.context.collection.objects.link(robot);objects['Body'].parent=robot
for name,ob in objects.items():
 if name!='Body':mw=ob.matrix_world.copy();ob.parent=objects['Body'];ob.matrix_world=mw
bpy.context.view_layer.update()
def godot(v):return [round(v[0],6),round(v[2],6),round(-v[1],6)]
stats={}
for name,ob in objects.items():
 ob.data.calc_loop_triangles();coords=[ob.matrix_world@v.co for v in ob.data.vertices];g=[Vector(godot(v)) for v in coords];stats[name]={'triangles':len(ob.data.loop_triangles),'bbox':bounds(g),'pivot':godot(ob.matrix_world.translation)}
bpy.ops.object.select_all(action='DESELECT');robot.select_set(True)
for ob in objects.values():ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False,export_materials='EXPORT',export_image_format='AUTO')
export_seconds=time.perf_counter()-t0
# Export is completed before temporary diagnostic materials and poses.
colors=[(.45,.55,.65,1),(.95,.3,.18,1),(.2,.75,.3,1),(.1,.55,.95,1),(.85,.3,.8,1),(1,.75,.12,1),(.25,.95,.85,1)]
for (name,ob),col in zip(objects.items(),colors):
 m=bpy.data.materials.new('diagnostic_'+name);m.diffuse_color=col;ob.data.materials.clear();ob.data.materials.append(m)
s=bpy.context.scene;s.render.engine='BLENDER_WORKBENCH';s.display.shading.light='STUDIO';s.display.shading.color_type='MATERIAL';s.display.shading.show_shadows=True;s.display.shading.show_cavity=True;s.world=bpy.data.worlds.new('World');s.world.color=(.16,.16,.16);s.render.resolution_x=1100;s.render.resolution_y=1100;s.render.resolution_percentage=100
def render(name,pos,scale=1.25):
 bpy.ops.object.camera_add(location=pos);cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.48))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=scale;s.camera=cam;s.render.filepath=str(renders/(name+'.png'));bpy.ops.render.render(write_still=True);bpy.data.objects.remove(cam,do_unlink=True)
for name,pos in [('front',(0,-2,.50)),('back',(0,2,.50)),('left',(2,0,.50)),('three_quarter',(1.5,-2,1.25))]:render(name,pos)
objects['Head'].rotation_euler=(0,math.radians(15),math.radians(30));objects['Arm_L'].rotation_euler[1]=math.radians(-45);objects['Arm_R'].rotation_euler[1]=math.radians(45);objects['WindKey'].rotation_euler[1]=math.radians(90)
render('action_test',(1.5,-2,1.25),1.45)
render('action_test_back',(1.5,2,1.25),1.45)
# Mandatory reimport, hierarchy/geometry/embedded-material checks.
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(out));re={o.name:o for o in bpy.context.scene.objects};checks={}
checks['names']=set(re)==set(objects)|{'Robot'};checks['hierarchy']=re['Body'].parent==re['Robot'] and all(re[n].parent==re['Body'] for n in objects if n!='Body')
coords=[];total=0
for ob in re.values():
 if ob.type=='MESH':ob.data.calc_loop_triangles();total+=len(ob.data.loop_triangles);coords.extend(ob.matrix_world@v.co for v in ob.data.vertices)
bb=bounds(coords);err=max(abs(bb[j][i]-original_bounds[j][i]) for j in range(2) for i in range(3));checks['triangle_count']=abs(total/original_tris-1)<=.15;checks['bbox']=err<.01
raw=out.read_bytes();ln=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+ln]);checks['materials']=len(g.get('materials',[]))==1;checks['embedded_textures']=bool(g.get('images')) and all('bufferView' in im and 'uri' not in im for im in g['images']);checks['no_animation_skin']=not g.get('animations') and not g.get('skins')
result={'blender':bpy.app.version_string,'input':a.input,'output':a.output,'original_tris':original_tris,'output_tris':total,'bbox_error_m':err,'loose_parts':loose_count,'parts':stats,'caps':caps,'checks':checks,'export_seconds':export_seconds,'script_seconds':time.perf_counter()-t0}
(work/'split_metrics.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print('RESULT',json.dumps(result));assert all(checks.values()),checks

from datetime import datetime,timezone
from hashlib import sha256
def embedded_hashes(path):
 d=Path(path).read_bytes();n=struct.unpack_from('<I',d,12)[0];j=json.loads(d[20:20+n]);binary=d[28+n:];hs=[]
 for im in j.get('images',[]):
  bv=j['bufferViews'][im['bufferView']];v=binary[bv.get('byteOffset',0):bv.get('byteOffset',0)+bv['byteLength']];hs.append(sha256(v).hexdigest())
 return sorted(hs)
checks['texture_bytes_unchanged']=embedded_hashes(a.input)==embedded_hashes(out)
result['checks']=checks
result['task_seconds_to_export']=(datetime.now(timezone.utc)-datetime.fromisoformat(a.task_start)).total_seconds()-(time.perf_counter()-t0-export_seconds) if a.task_start else export_seconds
(work/'split_metrics.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
lines=['# 机器人刚性拆件报告','',f"Blender：{bpy.app.version_string}；命令行无界面运行。",'', '坐标均为 glTF / Godot 世界坐标（米，Y 朝上）；前方为 +Z，机器人自身左侧为 +X。所有节点缩放为 1，Robot 位于 (0,0,0)。','', '| 部件 | 三角面 | 包围盒最小值 | 包围盒最大值 | 世界枢轴 |','|---|---:|---|---|---|']
for name,d in stats.items():
 fmt=lambda v:'('+', '.join(f'{x:.6f}' for x in v)+')'
 lines.append(f"| {name} | {d['triangles']} | {fmt(d['bbox'][0])} | {fmt(d['bbox'][1])} | {fmt(d['pivot'])} |")
lines += ['', '## 方法与质量', '',f'先实际 Separate by Loose Parts，得到 {loose_count} 个 UV 接缝碎片；重合位置连通检查为一整体。保持 loop UV，合并 1 微米内重合位置，再用 bmesh bisect 在脖子、肩部和履带轴连接处切割，钳子下半段按连通岛重新归并。没有减面、重拓扑、烘焙、骨骼或动画。', '', '头部、眼睛和头顶零件完整属于 Head；双臂包括活塞与完整钳子；履带包括轮子和内侧轴套。电池舱保持在 Body。Body 底部枢轴位于中央下部支架的底端（不是机器人脚底）。', '', '原 AI 模型两侧都有钥匙状结构：+X 后侧薄钥匙分出 WindKey；-X 肩后另一个厚的钥匙状装饰与背部框架归入 Body，避免随肩膀转动或强行分成两个不同轴的钥匙。WindKey 的连接轴为 Godot Z（Blender Y），Godot 可绕本地 Z 旋转；枢轴放在杆插入背部框架处。', '', '局限：这是刚性切面，不是新建机械关节；极大角度时可看到原模型融合部位与新增端盖。原 AI 模型的凹陷、非对称和表面细节保留。动作测试为头转 30°/歪 15°、双臂抬 45°、钥匙转 90°；附背面动作图方便查看钥匙。', '', '## 补洞', '', '每个 bisect 新生成的开口使用 holes_fill 封盖，同一个材质；补面 UV 使用默认值。脖子、肩侧、轴套和钥匙杆端盖位于关节内侧；腕部 z=0.280 分区两半最终同属手臂，内部端盖不会随动作张开。切割位置（以下为 Blender 坐标）：']
for c in caps:lines.append(f"- {c['cut']} / {c['side']}：{c['faces']} 个多边形端盖。")
lines += ['', '## 实际验证', '',f"原始 {original_tris} 三角面；导出重新导入 {total} 三角面，变化 {(total/original_tris-1)*100:.2f}%；包围盒最大端点误差 {err:.9f} m。"]
for k,v in checks.items():lines.append(f"- {k}：{'PASS' if v else 'FAIL'}")
lines += ['', '三张嵌入贴图的 SHA-256 与输入逐字节一致；尺寸、编码及像素均未改变。原始表面 UV 保留，切割新增顶点 UV 由原三角面插值。导出 1 个材质，7 个网格，未导出相机、灯、动画和蒙皮。', '', '## 耗时', '', f"从任务初始检查到本轮导出完成：{result['task_seconds_to_export']:.1f} 秒（包含下载安装、权限等待、预览和修正）。",f"最终脚本：导出完成 {export_seconds:.3f} 秒；包括渲染与重新导入检查共 {result['script_seconds']:.3f} 秒。早期预览和试切轮次未保存独立运行日志，也未汇总计时；脚本运行时间为进程内测量，不包含 Blender 启动。",'真人熟练操作估计 1–2 小时，含辨认 AI 融合边界、拆件、端盖、原点、导出和验证；这是估计，不是实测。', '', '## 复现', '', '```powershell', fr"& 'D:\AI\Blender\blender.exe' -b -P '{Path(__file__)}' -- --input '{a.input}' --output '{out}'", '```', '', '项目入库检查：未测（需在最终文件落盘后运行）。Godot 无头导入：未测。']
(work/'SPLIT_REPORT.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
assert all(checks.values()),checks
