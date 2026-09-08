from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

render_dir = Path(r"C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical\outputs\ps_refactor_presentation\rendered")
output = Path(r"C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical\outputs\ps_refactor_presentation\contact_sheet.png")

pngs = sorted(render_dir.glob("slide-*.png"))
thumb_w = 426
thumb_h = 240
label_h = 30
cols = 3
rows = (len(pngs) + cols - 1) // cols
canvas = Image.new("RGB", (cols * thumb_w, rows * (thumb_h + label_h)), "white")
draw = ImageDraw.Draw(canvas)

for idx, path in enumerate(pngs):
    img = Image.open(path).convert("RGB").resize((thumb_w, thumb_h))
    x = (idx % cols) * thumb_w
    y = (idx // cols) * (thumb_h + label_h)
    canvas.paste(img, (x, y))
    draw.text((x + 12, y + thumb_h + 8), f"Slide {idx + 1}", fill=(30, 41, 59))

canvas.save(output)
print(output)
