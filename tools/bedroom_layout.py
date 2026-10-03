"""Idempotent bedroom layout migration, used by the generator and existing scene."""
import re
K=9.0
BOX_DX=.44*2/3
POSITIONS={
 'Stop0/Nightstand':(-2.933333333,.36,-2.283333333),
 'Stop0/NightstandDrawer':(-2.933333333,.57,-1.916666667),
 'Stop0/WaterGlass':(-2.67,.775,-2.55),
 'Stop0/PillBottleB':(-2.83,.7525,-2.56),
 'Stop0/ReadingGlasses':(-2.85,.729,-2.03),
 'Stop0/CoinA':(-3.10,.7215,-2.08),
 'Stop0/CoinB':(-3.02,.7215,-2.06),
 'Stop0/PhotoFrame':(-2.96,.72,-2.43),
 'Stop0/FrameInteract':(-2.895,.74,-2.34),
 'Stop0/LooseBook':(-2.566666667,.72,-2.33),
 'Areas/BookTip':(-2.521666667,.785,-2.33),
}
MARKERS={'FallLanding','MachineLook','BookLanding','ShelfTarget','DrumLanding','CarWay1','CarWay2','CarWay3','CarWay4'}
def vector(text):return [float(x) for x in text.split(',')]
def fmt(values):return ', '.join(f'{x:.9g}' for x in values)
def _apply_layout_v2(text):
    if 'metadata/bedroom_layout_version = 2' in text:return text
    blocks=re.split(r'(?=\[node )',text)
    for i,block in enumerate(blocks):
        if not block.startswith('[node '):continue
        header=block.split('\n',1)[0]
        name=re.search(r'name="([^"]+)"',header).group(1)
        pm=re.search(r'parent="([^"]+)"',header);parent=pm.group(1) if pm else None
        path=name if parent in [None,'.'] else parent+'/'+name
        if parent is None:
            block=block.replace(header,header+'\nmetadata/bedroom_layout_version = 2\nmetadata/toybox_offset_m = 0.293333333')
        target=POSITIONS.get(path)
        shifted=parent=='Stop1' or (parent=='.' and name in MARKERS) or (parent=='Checkpoints' and name in ['ToyBox','BoxShelf']) or (parent=='Areas' and name in ['JackTop','SeesawEnd'])
        if target or shifted:
            def transform(m):
                data=vector(m.group(1))
                if target:data[-3:]=[x*K for x in target]
                else:data[-3]+=BOX_DX*K
                return 'transform = Transform3D('+fmt(data)+')'
            # Train has no transform: its center drives its motion from _ready onward.
            block=re.sub(r'transform = Transform3D\(([^)]+)\)',transform,block,count=1)
        if path=='Stop1/Train':
            def center(m):
                xyz=vector(m.group(1));xyz[0]+=BOX_DX*K
                return 'center = Vector3('+fmt(xyz)+')'
            block=re.sub(r'center = Vector3\(([^)]+)\)',center,block,count=1)
        if path=='Stop0/Nightstand':block=re.sub(r'size = Vector3\([^)]+\)','size = Vector3(6.6, 6.48, 6.6)',block,count=1)
        if path=='Stop0/NightstandDrawer':block=re.sub(r'size = Vector3\([^)]+\)','size = Vector3(6.24, 1.26, 0.09)',block,count=1)
        blocks[i]=block
    return ''.join(blocks)


def apply_layout(text):
    text=_apply_layout_v2(text)
    if 'metadata/bedroom_prop_revision = 1' in text:return text
    blocks=re.split(r'(?=\[node )',text)
    output=[]
    for block in blocks:
        if not block.startswith('[node '):
            output.append(block);continue
        header=block.split('\n',1)[0]
        name=re.search(r'name="([^"]+)"',header).group(1)
        pm=re.search(r'parent="([^"]+)"',header);parent=pm.group(1) if pm else None
        path=name if parent in [None,'.'] else parent+'/'+name
        if parent is None:block=block.replace(header,header+'\nmetadata/bedroom_prop_revision = 1')
        if path=='Stop1/FlapE':continue
        def move(m):
            values=vector(m.group(1))
            if path=='Stop0/ReadingGlasses':
                import math
                a=math.radians(-23);c=math.cos(a);t=math.sin(a)
                values[:9]=[c,0,-t,0,1,0,t,0,c]
                values[-3:]=[-2.795*K,.729*K,-2.052*K]
            elif path=='Stop1/Drum':values[-2]=.661*K
            return 'transform = Transform3D('+fmt(values)+')'
        if path in ['Stop0/ReadingGlasses','Stop1/Drum']:
            block=re.sub(r'transform = Transform3D\(([^)]+)\)',move,block,count=1)
        if path=='Stop1/Drum':block=block.replace('height = 0.81','height = 1.458')
        if path=='Stop1/WindUpMonkey':block=block.replace('radius = 0.27','radius = 0.54')
        output.append(block)
    return ''.join(output)
