from pathlib import Path
from docx import Document
from PIL import Image,ImageOps,ImageDraw
import json,io
src=Path(r'C:\Users\LIKKI\Downloads\ref do not used SALDEV-1420-20260907T161927Z-1-001\ref do not used SALDEV-1420\Story Test Execution Document for SALDEV-1420.docx')
out=Path(__file__).parent/'SALDEV-1420-test-document-review';out.mkdir(exist_ok=True)
d=Document(src); entries=[]; context=[]
for p in d.paragraphs:
    if p.text.strip(): context.append(p.text)
    for node in p._p.xpath('.//a:blip'):
        rid=node.get('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}embed')
        blob=d.part.related_parts[rid].blob
        n=len(entries)+1; im=Image.open(io.BytesIO(blob)).convert('RGB'); name=f'image-{n:02}.png'; im.save(out/name)
        entries.append({'image':name,'context':context[-3:],'size':im.size})
(out/'image-index.json').write_text(json.dumps(entries,indent=2))
for start in range(0,len(entries),12):
    sheet=Image.new('RGB',(1600,1800),'#ddd');draw=ImageDraw.Draw(sheet)
    for j,e in enumerate(entries[start:start+12]):
        x=(j%3)*533;y=(j//3)*450
        im=Image.open(out/e['image']);im.thumbnail((515,390));sheet.paste(im,(x,y+40));draw.text((x+5,y+5),e['image']+' '+e['context'][-1][:65],fill='black')
    sheet.save(out/f'contact-{start//12+1}.jpg')
print(json.dumps(entries,indent=2))
