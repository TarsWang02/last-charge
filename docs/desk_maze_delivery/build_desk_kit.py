import bpy, math, json, random
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).parent
OUT=ROOT/'delivery'; OUT.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(24)

def material(name,color,kind='paint'):
    m=bpy.data.materials.new(name); m.use_nodes=True
    n=m.node_tree.nodes; p=n.get('Principled BSDF')
    p.inputs['Roughness'].default_value=.78
    p.inputs['Metallic'].default_value=.18 if kind=='metal' else 0
    im=bpy.data.images.new(name+'_albedo',width=512,height=512)
    pix=[]
    for y in range(512):
        for x in range(512):
            # Solid-color wear only: no directional shading, AO or highlights.
            wave=math.sin(x*.13+math.sin(y*.04)*2)*.016 if kind=='wood' else math.sin(x*.08+y*.03)*.006
            noise=random.uniform(-.015,.015)+wave
            chip=((x*71+y*131)%3071<8)
            patch=((x//11*73+y//9*151)%251<5) and ((x%11-5)**2+(y%9-4)**2<22)
            c=tuple(max(0,min(1,v+noise)) for v in color)
            if chip: c=tuple(v*.65+.10 for v in c)
            if patch: c=tuple(v*.68+.035 for v in c)
            pix.extend((*c,1))
    im.pixels.foreach_set(pix); im.pack()
    t=n.new('ShaderNodeTexImage');t.image=im;m.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color'])
    return m

wood=material('worn_honey_wood',(.58,.39,.18),'wood')
red=material('faded_brick_red',(.46,.12,.08))
cream=material('aged_ivory',(.78,.72,.57))
steel=material('charcoal_steel',(.12,.14,.14),'metal')
brass=material('muted_brass',(.50,.36,.15),'metal')
ochre=material('mustard_paint',(.59,.41,.12))
rubber=material('old_rubber',(.075,.068,.057))

def finish(o,name,mat,bevel=0):
    o.name=name;o.data.materials.append(mat)
    if bevel:
        mod=o.modifiers.new('soft_worn_edges','BEVEL');mod.width=bevel;mod.segments=2
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bpy.context.view_layer.objects.active=o
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.025);bpy.ops.object.mode_set(mode='OBJECT')
    return o

def box(name,size,pos,mat,bevel=.001):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,mat,bevel)

def cyl(name,r,h,pos,mat,axis='Z',verts=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=h,location=pos)
    o=bpy.context.object
    if axis=='X':o.rotation_euler.y=math.pi/2
    return finish(o,name,mat,min(.0005,h*.15))

def root(name,parts,pivot):
    bpy.ops.object.empty_add(location=pivot);r=bpy.context.object;r.name=name
    for o in parts:
        world=o.matrix_world.copy();o.parent=r;o.matrix_world=world
    return r

def group_objects(r):return [r]+list(r.children_recursive)


assets=[]
blue=material('faded_navy',(.15,.22,.32));green=material('old_olive',(.27,.31,.16))
def B(n,s,p,m=wood,b=.0006):return box(n,s,p,m,b)
def add(id,group,parts,weight=1):
    r=root('prop_desk_'+id,parts,(0,0,0));assets.append((id,group,r,weight));return r

def top_material(id,title,kind='paper'):
    fp=ROOT/(id+'_colour.png')
    m=bpy.data.materials.new(id+'_printed');m.use_nodes=True;nt=m.node_tree;p=nt.nodes['Principled BSDF'];p.inputs['Roughness'].default_value=.9;tex=nt.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(fp));tex.image.pack();nt.links.new(tex.outputs['Color'],p.inputs['Base Color']);return m

def plane(id,w,d,z,mat):
    me=bpy.data.meshes.new(id);me.from_pydata([(-w/2,-d/2,z),(w/2,-d/2,z),(w/2,d/2,z),(-w/2,d/2,z)],[],[(0,1,2,3)]);me.update();o=bpy.data.objects.new(id,me);bpy.context.collection.objects.link(o);me.materials.append(mat);uv=me.uv_layers.new()
    for li,xy in zip(me.polygons[0].loop_indices,[(0,1),(1,1),(1,0),(0,0)]):uv.data[li].uv=xy
    return o

def book(id,w,d,h,m=red,z=0):
    return [B(id+'_pages',(w-.004,d-.002,h-.004),(0,0,z+h/2),cream),B(id+'_cover',(w,d,.002),(0,0,z+.001),m),B(id+'_cover',(w,d,.002),(0,0,z+h-.001),m),B(id+'_spine',(w,.003,h),(0,d/2-.0015,z+h/2),m)]
def device(id,w,d,h,label,m=steel):
    p=[B(id+'_body',(w,d,h),(0,0,h/2),m,.0015),B(id+'_screen',(w*.65,d*.28,.0008),(0,d*.23,h+.0004),cream,.0002)]
    for i in range(3):
        for j in range(4):p.append(B(id+'_button',(w*.16,d*.08,.001),(w*(i-1)*.23,d*(-.32+j*.10),h+.0005),rubber,.0002))
    return p
# A wall pieces: long axis X, depth <=3.5cm.
p=[B('TextbookPages',(.112,.017,.075),(0,0,.04),cream)]
for y in [-.0105,.0105]:p.append(B('TextbookCover',(.116667,.002,.08),(0,y,.04),blue))
p.append(B('TextbookSpine',(.004,.023,.08),(-.056333,0,.04),blue));add('textbook','A1',p,2)
add('calculator','A1',device('Calculator',.116667,.026,.038,'MATH',steel))
p=[B('TapeFoot',(.116667,.026,.018),(0,0,.009),red),B('TapeTower',(.039,.020,.037),(-.025,0,.033),red)]
bpy.ops.mesh.primitive_torus_add(major_segments=24,minor_segments=8,major_radius=.013,minor_radius=.006,location=(-.025,0,.052));o=bpy.context.object;o.rotation_euler.x=math.pi/2;p.append(finish(o,'TapeRoll',cream));p.append(B('CuttingBlade',(.016,.024,.004),(.044,0,.025),steel));add('tape_dispenser','A1',p)
for id,L,num in [('book_stack',.233333,3),('fallen_books',.350,4)]:
    p=[]
    for i in range(num):p+=book('Stack%d'%i,L,.026,.013,[red,blue,green,ochre][i],z=.013*i)
    add(id,'A2' if num==3 else 'A3',p,2)
p=[B('PencilPouch',(.233333,.030,.045),(0,0,.0225),green,.003),B('PouchZipper',(.210,.001,.001),(0,0,.045),brass,.0001)];p.append(B('ZipPull',(.008,.005,.001),(.080,0,.045),steel));add('pencil_pouch','A2',p)
p=[B('UprightRuler',(.233333,.014,.040),(0,0,.020),wood)]
for i in range(23):p.append(B('RulerTick',(.0006,.0001,.008 if i%5 else .016),(-.11+i*.01,-.00705,.027),steel,0))
add('upright_ruler','A2',p)
p=[B('LongRuler',(.350,.025,.008),(0,0,.004),wood)]
for i in range(35):p.append(B('LongTick',(.0005,.007,.0001),(-.17+i*.01,.007,.0081),steel,0))
p+=book('ExerciseOnRuler',.13,.024,.03,blue,z=.008);add('ruler_exercise','A3',p)
# Stack assets scaled on placement to fit wall envelope.
add('open_book','A_stack',[B('OpenPageLeft',(.034,.060,.004),(-.017,0,.003),cream),B('OpenPageRight',(.034,.060,.004),(.017,0,.003),cream),B('BookFold',(.002,.060,.007),(0,0,.0035),red)])
p=[B('Cartridge',(.032,.024,.009),(0,0,.0045),steel,.001),B('CartridgeSticker',(.025,.016,.0002),(0,0,.0091),cream)];add('cartridge','A_stack',p)
# Tall corner clutter: compact footprints, open rims.
def vessel(id,h,mat,handles=False,pens=False):
    p=[cyl(id+'_base',.013,.003,(0,0,.0015),mat,verts=16)]
    for i in range(16):
        a=i*math.tau/16;p.append(B(id+'_wall',(.004,.002,h-.003),(.012*math.cos(a),.012*math.sin(a),(h+.003)/2),mat,.0002));p[-1].rotation_euler.z=a+math.pi/2
    bpy.ops.mesh.primitive_torus_add(major_segments=24,minor_segments=6,major_radius=.012,minor_radius=.001,location=(0,0,h));p.append(finish(bpy.context.object,id+'_rim',mat))
    if handles:
        bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=5,major_radius=.004,minor_radius=.001,location=(.010,0,h*.55));o=bpy.context.object;o.rotation_euler.x=math.pi/2;p.append(finish(o,'CupHandle',mat))
    if pens:
        for i in range(4):
            a=i*math.tau/4;p.append(cyl('Pencil',.0017,h*.8,(.006*math.cos(a),.006*math.sin(a),h*.85),[red,ochre,blue,wood][i],verts=6))
    return p
add('pencil_pot','B',vessel('PenPot',.038,wood,pens=True));add('mug','B',vessel('Mug',.032,cream,handles=True))
p=[cyl('SodaCan',.014,.055,(0,0,.0275),red,verts=20),cyl('CanLid',.014,.001,(0,0,.055),steel,verts=20),B('CanTab',(.005,.010,.001),(0,0,.056),brass)];add('soda_can','B',p)
add('alarm_clock','B_tall',device('AlarmClock',.027,.027,.088,'TIME',blue))
p=vessel('TallPenPot',.050,wood,pens=True);p.append(B('StuckRuler',(.009,.002,.080),(0,0,.10),wood));add('ruler_pot','B_tall',p)
# Printed top-facing papers and emotional sheets.
for id,title,kind in [('exam','MATHS','exam'),('homework','HOMEWORK','paper'),('birthday_card','HAPPY BIRTHDAY','card'),('certificate','WELL DONE','card')]:
    mat=top_material(id,title,kind);p=[B(id+'_sheet',(.068,.084,.001),(0,0,.0005),cream,.0002),plane(id+'_print',.067,.083,.00105,mat)]
    add(id,'C',p,2 if id in ['exam','homework'] else 1)
# D broken board fringe: thin edge strip / raised splinter.
p=[B('FrayedBoard',(.116667,.005,.006),(0,0,.003),wood,.0002)]
for i in range(7):p.append(B('WoodFibre',(.008,.008,.002),(-.049+i*.016,-.002,.005),wood,.0001))
add('broken_edge','D',p)
p=[B('SplinterBase',(.018,.009,.002),(0,0,.001),wood),B('RaisedSplinter',(.012,.003,.007),(0,0,.005),wood,.0002)];add('splinter_corner','D',p)
# E real low-poly scatter, all within1..3cm.
add('pencil_shaving','E',[B('PencilShaving',(.012,.006,.0008),(0,0,.0004),wood,.0001)])
curve=bpy.data.curves.new('PaperClip','CURVE');curve.dimensions='3D';curve.bevel_depth=.0004;curve.bevel_resolution=2;spl=curve.splines.new('POLY');coords=[(-.004,-.008),(.004,-.008),(.004,.007),(-.003,.007),(-.003,-.005),(.002,-.005),(.002,.004)];spl.points.add(len(coords)-1)
for pt,(x,y) in zip(spl.points,coords):pt.co=(x,y,.0004,1)
o=bpy.data.objects.new('PaperClip',curve);bpy.context.collection.objects.link(o);curve.materials.append(steel);bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH');add('paperclip','E',[bpy.context.object])
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3,radius=.0065,location=(0,0,.0065));o=bpy.context.object;o.scale=(1,.8,.9);finish(o,'PaperBall',cream);o.location.z-=min((o.matrix_world@v.co).z for v in o.data.vertices);add('paper_ball','E',[o])
p=[cyl('PencilStub',.0018,.020,(0,0,.0018),ochre,verts=6)];p[0].rotation_euler.y=math.pi/2;add('pencil_stub','E',p)
# F readable interactive props, foreground silhouette dominates.
p=[cyl('TorchBody',.008,.040,(0,0,.009),ochre,verts=16)];p[0].rotation_euler.x=math.pi/2
p+=[cyl('TorchHead',.012,.008,(0,-.023,.012),steel,verts=20),cyl('TorchLens',.010,.001,(0,-.0275,.012),cream,verts=20)];p[1].rotation_euler.x=math.pi/2;p[2].rotation_euler.x=math.pi/2
p.append(B('TorchSwitch',(.006,.012,.002),(0,.003,.017),red));add('flashlight','F_flashlight',p)
p=[B('LampClip',(.035,.028,.006),(0,0,.003),steel),B('LampStem',(.003,.003,.035),(0,0,.024),brass),B('LampHead',(.027,.018,.008),(0,-.010,.043),ochre,.002),B('LampLens',(.020,.013,.001),(0,-.010,.038),cream)];add('clip_lamp','F_far',p)
p=device('Handheld',.055,.040,.009,'PLAY',green);p.append(B('DPadX',(.012,.004,.001),(-.018,-.009,.010),steel));p.append(B('DPadY',(.004,.012,.001),(-.018,-.009,.010),steel));add('handheld','F_local',p)
add('electronic_clock','F_local',device('ElectronicClock',.048,.023,.022,'TIME',blue))
p=[cyl('LampBase',.017,.005,(0,0,.0025),brass,verts=24),cyl('LampPost',.002,.044,(0,0,.027),brass,verts=12)]
bpy.ops.mesh.primitive_cone_add(vertices=24,radius1=.024,radius2=.012,depth=.022,location=(0,0,.060));p.append(finish(bpy.context.object,'LampShade',red,.0005));p.append(cyl('LampBulb',.007,.005,(0,0,.048),cream,verts=16));add('mini_lamp','F_lamp',p)
base=B('UsedEraser',(.095,.095,.095),(0,0,.0475),cream,.002)
for i in range(9):
    x=(i%3-1)*.025;y=(i//3-1)*.025;bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.0023,depth=.010,location=(x,y,.095));cut=bpy.context.object;mod=base.modifiers.new('PencilPuncture','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cut;bpy.context.view_layer.objects.active=base;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
add('eraser','F_eraser',[base,B('EraserSleeve',(.095,.035,.0001),(0,0,.0949),red,0)])
mat=top_material('mom_note','BACK SOON','paper');p=[B('FoldedNote',(.070,.050,.002),(0,0,.001),cream),plane('NoteWriting',.069,.049,.0021,mat),B('FoldCrease',(.0006,.050,.0002),(0,0,.0022),wood,0)];add('folded_note','F_note',p)

manifest=[]
for id,group,r,weight in assets:
    bpy.ops.object.select_all(action='DESELECT');obs=group_objects(r)
    for o in obs:o.select_set(True)
    bpy.context.view_layer.objects.active=r
    bpy.ops.export_scene.gltf(filepath=str(OUT/('prop_desk_'+id+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_animations=False)
    points=[o.matrix_world@Vector(v) for o in obs if o.type=='MESH' for v in o.bound_box];lo=[min(v[i] for v in points) for i in range(3)];hi=[max(v[i] for v in points) for i in range(3)];dims=[hi[i]-lo[i] for i in range(3)];tris=sum(sum(len(f.vertices)-2 for f in o.data.polygons) for o in obs if o.type=='MESH')
    manifest.append(dict(id=id,group=group,glb_path='res://assets/models/props/prop_desk_'+id+'.glb',size_m=[dims[0],dims[2],dims[1]],weight=weight,triangles=tris))
(OUT/'desk_kit_manifest.json').write_text(json.dumps(manifest,indent=2));bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'desk_kit_source.blend'));print('KIT',len(manifest))
