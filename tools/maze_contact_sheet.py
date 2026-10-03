from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json,sys
out=Path(sys.argv[1]);rows=json.loads((out/'candidates.json').read_text());sheet=Image.new('RGB',(1600,1680),(35,30,26));draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
for i,row in enumerate(rows):
    x=(i%4)*400;y=(i//4)*280;im=Image.open(out/('seed_%d.png'%row['seed']));im.thumbnail((394,245));sheet.paste(im,(x+(400-im.width)//2,y));draw.text((x+12,y+246),'Seed %d | path %d | holes %d | turns %d'%(row['seed'],row['path_len'],row['holes'],row['turns_on_path']),font=font,fill=(245,221,181))
sheet.save(out/'contact_sheet.png')
