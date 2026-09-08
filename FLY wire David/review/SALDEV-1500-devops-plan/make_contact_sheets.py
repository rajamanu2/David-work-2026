from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
PAGES = sorted((ROOT / "render-word-v4").glob("page-*.png"), key=lambda p: int(p.stem.split("-")[-1]))
OUT = ROOT / "contact-sheets-v4"
OUT.mkdir(parents=True, exist_ok=True)

font_path = Path("C:/Windows/Fonts/arialbd.ttf")
font = ImageFont.truetype(str(font_path), 30) if font_path.exists() else ImageFont.load_default()

for start in range(0, len(PAGES), 3):
    group = PAGES[start:start + 3]
    opened = [Image.open(p).convert("RGB") for p in group]
    width = max(im.width for im in opened)
    label_h = 54
    gap = 24
    height = sum(im.height + label_h for im in opened) + gap * (len(opened) - 1)
    sheet = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(sheet)
    y = 0
    for path, im in zip(group, opened):
        page_no = int(path.stem.split("-")[-1])
        draw.rectangle((0, y, width, y + label_h), fill="#0B2545")
        draw.text((20, y + 9), f"PAGE {page_no}", font=font, fill="white")
        y += label_h
        sheet.paste(im, (0, y))
        y += im.height + gap
    end = start + len(group)
    sheet.save(OUT / f"pages-{start + 1:02d}-{end:02d}.png", optimize=True)
print(f"created {((len(PAGES) + 2) // 3)} contact sheets for {len(PAGES)} pages")
