from PIL import Image,ImageDraw
from pathlib import Path
ROOT=Path(__file__).parent
def generate(id,title,kind='paper'):
    im=Image.new('RGB',(512,512),(211,199,163));d=ImageDraw.Draw(im)
    if kind=='cover':
        d.rectangle((12,12,499,499),fill=(100,47,35),outline=(176,138,68),width=9);d.text((50,80),title,fill=(221,196,143),font_size=48);d.line((45,157,466,157),fill=(176,138,68),width=3)
    else:
        d.text((38,25),title,fill=(78,73,65),font_size=26)
        for j in range(7):
            y=85+j*49;d.line((38,y,470,y),fill=(155,151,134),width=1);d.text((42,y+9),str(j+1)+'.  x + '+str(j+2)+' = '+str(j+3),fill=(111,106,94),font_size=19)
        if kind=='exam':
            d.text((364,25),'62',fill=(145,33,26),font_size=44);d.ellipse((350,15,465,70),outline=(145,33,26),width=4)
            for x,y in [(350,104),(395,247),(320,349)]:d.line((x,y,x+16,y+16),fill=(145,33,26),width=3);d.line((x+16,y,x,y+16),fill=(145,33,26),width=3)
        if kind=='card':d.rectangle((20,20,492,492),outline=(129,81,69),width=5);d.text((68,215),'FOR YOU',fill=(129,81,69),font_size=42)
    fp=ROOT/(id+'_colour.png');im.save(fp)

for args in [('exam','MATHS','exam'),('homework','HOMEWORK','paper'),('birthday_card','HAPPY BIRTHDAY','card'),('certificate','WELL DONE','card'),('mom_note','BACK SOON','paper')]:generate(*args)
