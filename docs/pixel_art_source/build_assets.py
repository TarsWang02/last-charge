from pathlib import Path
import json, math, random, re
from PIL import Image, ImageDraw
import numpy as np

ROOT = Path(__file__).parent
OUT = ROOT / 'pixel'
OUT.mkdir(parents=True, exist_ok=True)
PAL = {
    '.': (0,0,0,0), 'k': '#100810', 'T': '#252331', 'G': '#525366', 'A': '#9093A7',
    'W': '#E9DFC0', 'M': '#C6A34A', 'm': '#866035', 'Y': '#E3C379',
    'C': '#4DFFF2', 'c': '#278A94', 'R': '#AE3545', 'r': '#681B32', 'h': '#D85A55',
    'V': '#915399', 'v': '#512A68', 'L': '#C58AC0', 'O': '#E87935', 'E': '#FFD077',
    'H': '#E6BB59', 'S': '#E0B68A', 's': '#AB705E', 'P': '#D783A1', 'p': '#944B78',
    'B': '#44476C', 'b': '#282B4C', 'q': '#AC8050',
}
def rgba(c):
    if isinstance(c,tuple): return c
    c=c.lstrip('#');return tuple(int(c[i:i+2],16) for i in (0,2,4))+(255,)
PAL={k:rgba(v) for k,v in PAL.items()}
manifest={}
def canvas(w,h): return Image.new('RGBA',(w,h),(0,0,0,0))
def save(name,im,category='sprite'):
    assert im.mode=='RGBA'
    im.save(OUT/(name+'.png'))
    manifest[name]={'size':list(im.size),'category':category}
    return im
def art(name,w,h,rows):
    assert len(rows)==h,(name,len(rows),h)
    assert all(len(r)<=w for r in rows),(name,[len(r) for r in rows])
    im=canvas(w,h)
    for y,row in enumerate(rows):
        for x,ch in enumerate(row):
            if ch!='.': im.putpixel((x,y),PAL[ch])
    return save(name,im)
def rect(im,box,ch):ImageDraw.Draw(im).rectangle(box,fill=PAL[ch])
def pixel(im,x,y,ch):
    if 0<=x<im.width and 0<=y<im.height:im.putpixel((x,y),PAL[ch])
def line(im,pts,ch):ImageDraw.Draw(im).line(pts,fill=PAL[ch],width=1)
def shift(im,dx=0,dy=0):
    out=canvas(*im.size);out.paste(im,(dx,dy));return out
def recolor(im,old,new):
    out=im.copy();a=np.array(out);a[(a==PAL[old]).all(axis=2)]=PAL[new];return Image.fromarray(a)
def frames(name,action,images):
    for i,im in enumerate(images):save(f'{name}_{action}_{i}',im,'animation')

# Each cell is an actual output pixel. No resampling, AA or fractional alpha.
bot=art('bot',12,13,[
    '...kkkkkk...', '..kYMMMMMk..','..kmMMMkCkCk','..kMMMkCCkCk',
    '...kkkMMMkk.','..kkMMMMMkk.','.kGkCkCkCMGk','.kTkCkCkCMTk',
    '..kkmMMMkk..','..kMkmMkMk..','.kkTTkkTTkk.','kTGTGkkTGTGk','.kkkk..kkkk.'])
idle1=bot.copy();pixel(idle1,4,5,'Y');pixel(idle1,8,5,'m')
frames('bot','idle',[bot,idle1])
walk=[]
for i in range(4):
    im=bot.copy()
    for x in [2,3,8,9]:pixel(im,x,11,'G' if (x+i)%2==0 else 'T')
    pixel(im,1,7,'M' if i%2 else 'T');pixel(im,10,7,'T' if i%2 else 'M')
    walk.append(im)
frames('bot','walk',walk)
jump=bot.copy();rect(jump,(1,6,1,8),'.');rect(jump,(10,6,10,8),'.');pixel(jump,1,5,'G');pixel(jump,10,5,'G');frames('bot','jump',[jump])
fall=bot.copy();pixel(fall,1,8,'M');pixel(fall,10,8,'M');frames('bot','fall',[fall])
hurt=recolor(bot,'M','W');frames('bot','hurt',[hurt])
claw=art('bot_claw',20,6,['............kkk.kk..','kkMMMMGGGGGkAAkGAAk.','kYMMMMGGGGGGkkGGGkkk','kkmmmmTTTTTGGGGGGkkk','...........kAAkGAAk.','............kkk.kk..'])
frames('bot_claw','attack',[shift(claw,-6),claw,shift(claw,-4)])
slime=art('slime',12,8,['....kkkk....','..kkLLVVkk..','.kLVVVVVVVk.','kVVWkVVWkVVk','kVVkkVVkkVVk','kvVVVVVVVVvk','.kvvvvvvvvk.','..kkkkkkkk..'])
sq=art('_slime_squash',12,8,['............','....kkkk....','..kkLLVVkk..','.kVVWkVWkVk.','kVVVkkVkkVVk','kvVVVVVVVVvk','kvvvvvvvvvvk','.kkkkkkkkkk.'])
frames('slime','crawl',[slime,sq]);(OUT/'_slime_squash.png').unlink();manifest.pop('_slime_squash')
bat=art('bat',12,6,['k..........k','krk..kk..krk','krhkkrrkkhrk','.krrOErrrk..','..krrrhrk...','...kk..kk...'])
batdown=art('_bat_down',12,6,['....kkkk....','...krOErk...','..krhrrhrk..','.krkrrrrkrk.','krk..kk..krk','k..........k'])
frames('bat','flap',[bat,batdown]);(OUT/'_bat_down.png').unlink();manifest.pop('_bat_down')
turret=art('turret',12,10,['....kkkkk...','...krhRRRk..','..kRROERRRk.','kkkkRRRrRRk.','kGAkRRRrRRk.','kkkkrrRrRRk.','...krrrrrrk.','..kkkkkkkkk.','.kAGGGGGGAAk','.kkkkkkkkkk.'])
charged=turret.copy();rect(charged,(5,2,7,3),'E');frames('turret','idle',[turret]);frames('turret','charge',[charged])
orb=art('orb',6,6,['..kk..','.kOEk.','kOEWWk','kOrOEk','.krrk.','..kk..'])
frames('orb','pulse',[orb,recolor(orb,'O','E')])
knight=art('knight',14,17,['.....kkkk.....','....kAAAGk....','...kWAAAAGk...','...kTkkAAAk...','....kkkkkk....','..kkAAAGGkk...','.krrkAAAGGAk..','kRHRkAAGGGAAk.','kRHrkAAGGGAGk.','kRHRkGGGGGAGk.','krrrkAGGGAkk..','.krkAAAAGAk...','..kkAGkAGAk...','...kGk.kAGk...','...kGk..kGk...','..kAAk..kAAk..','.kkkkk..kkkkk.'])
knwalk=knight.copy();rect(knwalk,(3,13,5,15),'.');rect(knwalk,(2,14,4,15),'G');frames('knight','walk',[knight,knwalk])
wind=knight.copy();pixel(wind,9,4,'W');pixel(wind,9,5,'A');frames('knight','windup',[wind])
thrust=knight.copy();rect(thrust,(11,14,12,15),'A');frames('knight','thrust',[thrust])
recover=knight.copy();rect(recover,(0,7,3,10),'.');rect(recover,(1,11,4,13),'r');pixel(recover,2,12,'H');frames('knight','recover',[recover])
art('knight_sword',16,3,['.kkkkkkkkkkkkk..','kWAAAAAAAAGGGMkk','.kkkkkkkkkkkkk..'])
princess=art('princess',13,19,['....kEkEk....','....kHHHk....','...kHHYHHk...','..kHSWSSHHk..','..kHSkkSHHk..','..kHSSsSHHk..','..kHHSSHHHk..','...kHPpPHHk..','..kSPPPPSHk..','..kkPWPpkk...','...kPPPpPk...','..kPPPpPPPk..','..kPPpPPPpk..','.kPPPpPPpPPk.','.kPPpPPPpPPk.','kPPPpPPpPPPPk','kPPpPPWpPPPPk','kPPppPPppPPPk','.kkkkkkkkkkk.'])
wait=princess.copy();pixel(wait,8,6,'Y');frames('princess','wait',[princess,wait])
wave=princess.copy();rect(wave,(1,6,2,7),'S');pixel(wave,1,5,'k');frames('princess','wave',[princess,wave])
rescued=princess.transpose(Image.Transpose.FLIP_LEFT_RIGHT);frames('princess','rescued',[rescued,recolor(rescued,'p','P')])
battery=art('battery',6,9,['..kk..','.kAAk.','kGCCGk','kCWCck','kCWCck','kCCCCk','kCccCk','kGCCGk','.kkkk.']);frames('battery','shine',[battery,recolor(battery,'c','C')])
art('heart',5,4,['kE.Ek','kEEEk','.kEk.','..k..'])

# The dragon's vulnerable face gets independent, legible mouth/dazed poses.
source=Path(r'C:\Users\Thunder\jam-test\scripts\tv_game.gd').read_text(encoding='utf8')
def source_rows(const):
    block=re.search(r'const '+const+r' := \[.*?\n\]',source,re.S).group(0)
    return re.findall(r'"([.A-Za-z]+)"',block)
def paint_rows(name,w,h,rows):
    im=canvas(w,h)
    for y,row in enumerate(rows[:h]):
        for x,ch in enumerate(row[:w]):
            if ch in PAL:pixel(im,x,y,ch)
    return save(name,im)
head=paint_rows('dragon_head',24,14,source_rows('DRAGON_HEAD'))
opened=paint_rows('dragon_head_open',24,15,source_rows('DRAGON_HEAD_OPEN'))
for im in [head,opened]:
    rect(im,(1,8,2,8),'r');pixel(im,8,4,'h');pixel(im,9,4,'h');pixel(im,13,5,'k');pixel(im,14,5,'E');pixel(im,14,6,'k');pixel(im,18,8,'h');pixel(im,19,8,'h')
save('dragon_head',head);save('dragon_head_open',opened)
dazed=head.copy();rect(dazed,(12,5,15,7),'R');line(dazed,[(12,5),(15,7)],'k');line(dazed,[(12,7),(15,5)],'k');rect(dazed,(4,11,7,12),'h');save('dragon_head_dazed',dazed)
wing=paint_rows('dragon_wing',30,13,source_rows('DRAGON_WING'));save('dragon_wing_down',wing.transpose(Image.Transpose.FLIP_TOP_BOTTOM))
neck=art('dragon_neck',10,10,['..kkkkkk..','.khRRRrrk.','kRRRRRrrrk','kRRRhhRrrk','kRRhhRRrrk','kWWWRRRrrk','kWWqRRRrrk','kWqqRRrrrk','.kqqRRrrk.','..kkkkkk..'])
tail=art('dragon_tail',12,12,['....kkkk....','..kkhRRRkk..','.khhRRRRrrk.','kRRRRRRRrrrk','kRRhhRRRrrrk','kRhhRRRRrrrk','kRRRRRRRrrrk','kRRRRRRrrrrk','kWqRRRrrrrrk','.kqqrrrrrrk.','..kkrrrrkk..','....kkkk....'])
art('dragon_tail_tip',10,8,['k.........','kYkk......','.kYYkk....','..kYYYkk..','..kYYYYYkk','.kYYqqkk..','kYqqkk....','kkkk......'])
fire=art('fireball',8,8,['....k...','...kOk..','..kEEOk.','.kOEWWOk','kOEWWEEk','kOrEEEOk','.krOOOk.','..kkkk..']);frames('fireball','roll',[fire,recolor(fire,'r','O')])

# Small repeatable texture clusters, never dithered gradients.
random.seed(193)
def tile(name,base,edge,kind):
    im=canvas(16,16);rect(im,(0,0,15,15),base)
    if kind=='stone':
        rect(im,(0,0,15,0),'T');rect(im,(0,8,15,8),'T');rect(im,(7,0,7,7),'T');rect(im,(15,8,15,15),'T')
        line(im,[(1,1),(6,1)],'A');line(im,[(9,1),(14,1)],'A');line(im,[(1,9),(12,9)],'A')
        rect(im,(3,5,5,5),'G');rect(im,(10,12,13,12),'G')
    elif kind=='rock':
        line(im,[(0,4),(4,2),(9,3),(12,1),(15,2)],edge);line(im,[(1,13),(5,10),(10,11),(14,8)],edge)
        line(im,[(8,3),(7,7),(10,9)],'T');rect(im,(2,5,4,6),'G');rect(im,(11,12,13,13),'G')
    else:
        for x,y in [(2,4),(11,6),(5,11),(14,13)]:rect(im,(x,y,min(x+2,15),y),edge)
        if kind=='grass':
            rect(im,(0,0,15,0),'H')
            for x in [0,1,4,5,8,12,13]:pixel(im,x,0,'Y')
            rect(im,(0,1,15,2),'m')
    return save(name,im,'tile')
# Use grass-specific muted greens, entirely separate from cyan.
PAL.update({'g':rgba('#547C42'),'f':rgba('#8CA45B'),'d':rgba('#5B3B39'),'e':rgba('#855244')})
grass=tile('tile_grass','d','e','dirt');rect(grass,(0,0,15,0),'f');rect(grass,(0,1,15,2),'g')
for x in [1,4,9,12]:pixel(grass,x,3,'g')
save('tile_grass',grass,'tile');tile('tile_dirt','d','e','dirt');tile('tile_rock','b','B','rock');tile('tile_stone','G','A','stone')
art('tile_tower_top',8,8,['GGG..GGG','AAA..AAA','GGG..GGG','GGG..GGG','GGG..GGG','GGGGGGGG','AAAAAAAA','GGGGGGGG'])
gate=canvas(8,96)
for x in [1,5]:rect(gate,(x,0,x+1,95),'G');line(gate,[(x,0),(x,95)],'A')
for y in range(3,96,16):rect(gate,(0,y,7,y+1),'T');pixel(gate,1,y,'W');pixel(gate,5,y,'W')
save('tile_gate',gate,'tile')
plank=canvas(24,6);rect(plank,(0,0,23,5),'k');rect(plank,(1,1,22,4),'m');line(plank,[(1,1),(22,1)],'Y');line(plank,[(5,0),(7,2),(6,4),(9,5)],'k');line(plank,[(16,0),(14,2),(16,4)],'k');save('plank',plank);frames('plank','shake',[plank,recolor(plank,'Y','M')]);save('plank_shake',recolor(plank,'Y','M'))
platform=canvas(26,8);rect(platform,(0,0,25,7),'k');rect(platform,(1,1,24,6),'m');rect(platform,(1,1,24,1),'Y')
for x in [1,8,16,24]:rect(platform,(x,2,min(x+1,24),6),'G');pixel(platform,x,3,'W')
save('platform',platform)
art('spikes',6,6,['..kk..','..kWk.','.kWAk.','.kAAAk','kAAAGk','kkkkkk'])

sky=canvas(320,240);ds=ImageDraw.Draw(sky)
for y0,y1,c in [(0,54,'#15162C'),(55,103,'#1C1E3A'),(104,143,'#292943'),(144,187,'#35354C'),(188,239,'#444453')]:ds.rectangle((0,y0,319,y1),fill=rgba(c))
save('bg_sky',sky,'background')
stars=canvas(320,240)
for i in range(45):
    x=(i*73+29)%320;y=(i*41+11)%130;pixel(stars,x,y,'A')
    if i%11==0:
        pixel(stars,x-1,y,'G');pixel(stars,x+1,y,'G');pixel(stars,x,y-1,'G');pixel(stars,x,y+1,'G')
save('bg_stars',stars,'background')
hills=canvas(320,40);dh=ImageDraw.Draw(hills)
for layer,c in [(0,'#2D374B'),(1,'#39443E')]:
    pts=[(x,round(13+layer*12+7*math.sin(x*math.tau/320*3+layer)+3*math.cos(x*math.tau/320*5))) for x in range(320)]
    dh.polygon(pts+[(319,39),(0,39)],fill=rgba(c))
save('bg_hills',hills,'background')
castle=canvas(320,240);dc=ImageDraw.Draw(castle)
c=rgba('#3B3655');shade=rgba('#2E2D48');light=rgba('#54475D')
dc.rectangle((209,141,290,207),fill=shade)
for x,y,w in [(208,112,17),(235,97,22),(274,119,17)]:
    dc.rectangle((x,y,x+w,207),fill=c);dc.rectangle((x+2,y+5,x+4,206),fill=light)
    dc.polygon([(x-2,y),(x+w//2,y-15),(x+w+2,y)],fill=shade)
    for a in range(x,x+w+1,6):dc.rectangle((a,y-3,a+3,y+2),fill=c)
dc.rectangle((213,127,218,135),fill=PAL['k']);dc.rectangle((214,128,217,134),fill=rgba('#FFC05A'))
dc.rectangle((248,140,255,207),fill=shade)
# ANU-inspired pixel plaque, referenced from the university's official shield.
# Muted warm gold belongs to the castle, rather than the interactive cyan palette.
gold=rgba('#B39973'); dark=rgba('#353047')
dc.rectangle((237,108,255,135),fill=dark)
dc.line([(237,135),(237,108),(255,108),(255,135)],fill=rgba('#78667A'),width=1)
crest=[
 'kkkkkkkkkkkkk',
 'k...........k',
 'k.......g...k',
 'k.....g...g.k',
 'k...........k',
 'k........g..k',
 'k.....g.....k',
 'k....ggg....k',
 'k..gg...gg..k',
 '.kg.......gk.',
 '.k.gg.g.gg.k.',
 '..k..g.g..k..',
 '...kgggggk...',
 '....kgggk....',
 '.....kkk.....']
for yy,row in enumerate(crest):
 for xx,ch in enumerate(row):
  if ch!='.':dc.point((240+xx,111+yy),fill=gold)
letters={'A':['.g.','g.g','ggg','g.g','g.g'], 'N':['g.g','ggg','ggg','ggg','g.g'], 'U':['g.g','g.g','g.g','g.g','.g.']}
for index,label in enumerate('ANU'):
 for yy,row in enumerate(letters[label]):
  for xx,ch in enumerate(row):
   if ch=='g':dc.point((241+index*4+xx,128+yy),fill=gold)
save('bg_castle_far',castle,'background')
tower=canvas(44,140);dt=ImageDraw.Draw(tower)
dt.rectangle((4,11,39,139),fill=rgba('#353347'));dt.rectangle((4,11,8,139),fill=rgba('#555064'));dt.rectangle((35,11,39,139),fill=rgba('#262636'))
for x in [0,16,32]:dt.rectangle((x,0,x+10,14),fill=rgba('#555064'));dt.rectangle((x+1,1,x+9,2),fill=rgba('#80747D'))
for y in range(20,140,12):
    dt.line((5,y,38,y),fill=rgba('#262636'))
    for x in range(10+(8 if y%24==8 else 0),38,16):dt.line((x,y,x,y+11),fill=rgba('#262636'))
dt.rectangle((15,50,27,67),fill=PAL['k']);dt.rectangle((16,52,26,65),fill=rgba('#FFC05A'));dt.rectangle((21,51,22,66),fill=PAL['m']);dt.rectangle((16,57,26,58),fill=PAL['m'])
save('bg_princess_tower',tower,'background')

hud=canvas(36,12);rect(hud,(0,1,33,10),'k');rect(hud,(1,2,32,9),'A');rect(hud,(2,3,31,8),'T');rect(hud,(33,4,35,7),'A');line(hud,[(2,2),(31,2)],'W');save('hud_battery',hud,'hud')
on=canvas(4,6);rect(on,(0,0,3,5),'c');rect(on,(0,0,2,4),'C');pixel(on,0,0,'W');save('hud_cell_on',on,'hud');off=canvas(4,6);rect(off,(0,0,3,5),'T');line(off,[(0,5),(3,5)],'G');save('hud_cell_off',off,'hud')
pip=art('hud_boss_pip_on',6,6,['..kk..','.khrk.','kRhRRk','kRrrRk','.krrk.','..kk..']);save('hud_boss_pip_off',recolor(recolor(recolor(pip,'R','T'),'r','k'),'h','G'),'hud')
glyph={'A':['.k.','k.k','kkk','k.k','k.k'],'D':['kk.','k.k','k.k','k.k','kk.'],'J':['..k','..k','..k','k.k','.k.']}
for label in ['A','D','J','SPACE']:
    w=25 if label=='SPACE' else 13;im=canvas(w,10);rect(im,(0,0,w-1,9),'k');rect(im,(1,1,w-2,7),'Y');rect(im,(1,8,w-2,8),'m');rect(im,(2,2,w-3,6),'T')
    if label=='SPACE':line(im,[(7,4),(7,5),(17,5),(17,4)],'W')
    else:
        for y,row in enumerate(glyph[label]):
            for x,ch in enumerate(row):
                if ch=='k':pixel(im,x+5,y+2,'W')
    save('key_'+label,im,'hud')
mouse=art('key_mouse',9,13,['..kkkkk..','.kAAAAAk.','kAEETGGGk','kAEETGGGk','kAEETGGGk','kAAATAAAk','kAGGGGGGk','kAGGGGGGk','kAGGGGGGk','kAGGGGGGk','.kGGGGGk.','.kAAAAAk.','..kkkkk..'])
cell=canvas(8,10);rect(cell,(1,0,6,9),'k');rect(cell,(2,1,5,8),'C');line(cell,[(2,2),(2,7)],'W');rect(cell,(3,0,4,0),'A');save('coin_cell',cell,'hud')
slot=canvas(40,30);rect(slot,(0,0,39,29),'k');rect(slot,(1,1,38,27),'G');rect(slot,(2,2,37,3),'A');rect(slot,(10,6,29,12),'k');rect(slot,(12,7,27,8),'T');rect(slot,(8,18,31,24),'T')
for x,y in [(3,5),(36,5),(3,25),(36,25)]:pixel(slot,x,y,'W')
line(slot,[(17,20),(17,22),(22,22),(22,20)],'M');save('coin_slot',slot,'hud')

def generated_body(path):
    im=Image.open(path).convert('RGBA');alpha=im.getchannel('A');im=im.crop(alpha.getbbox())
    # Production conversion: exact 48x31 pixel grid, six-color RGB and binary alpha.
    im=im.resize((48,31),Image.Resampling.NEAREST);a=np.array(im)
    cols=np.array([PAL[c][:3] for c in ['k','r','R','h','W','q']],dtype=np.int32)
    rgb=a[:,:,:3].astype(np.int32);dist=((rgb[:,:,None,:]-cols[None,None,:,:])**2).sum(axis=3);a[:,:,:3]=cols[dist.argmin(axis=2)];a[:,:,3]=np.where(a[:,:,3]>=128,255,0)
    return save('dragon_body',Image.fromarray(a))

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser();parser.add_argument('--dragon');args=parser.parse_args()
    if args.dragon:generated_body(args.dragon)
    (ROOT/'asset_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    print('PIXEL_ASSETS',len(manifest))

