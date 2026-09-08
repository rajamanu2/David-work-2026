from PIL import Image, ImageChops, ImageDraw
from pathlib import Path
root=Path('scratch/business_templates_qa')
sheet=Image.new('RGB',(1546,2200),'white');draw=ImageDraw.Draw(sheet)
diffs=[]
for i in range(1,20):
 old=Image.open(root/f'Combined_Workbook-{i:02d}.png').convert('RGB')
 new=Image.open(root/f'AutoFast_Workbook-{i:02d}.png').convert('RGB')
 if ImageChops.difference(old.crop((0,100,773,925)),new.crop((0,100,773,925))).getbbox():diffs.append(i)
 x=((i-1)%2)*773;y=((i-1)//2)*220
 sheet.paste(new.crop((0,0,773,100)),(x,y+18))
 sheet.paste(new.crop((0,925,773,1000)),(x,y+120))
 draw.text((x+5,y+3),f'PAGE {i}',fill='black')
sheet.save(root/'autofast_branding_check.png')
print('Body layout differences:',diffs)
