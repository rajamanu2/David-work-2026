from pathlib import Path
import json
import pdfplumber

source = Path(r"C:\Users\LIKKI\Downloads\Flywire Future State Vision_20260814 (1).pdf")
output = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david\tmp\pdfs\flywire_future")
output.mkdir(parents=True, exist_ok=True)

pages = []
with pdfplumber.open(source) as pdf:
    for index, page in enumerate(pdf.pages, start=1):
        text = page.extract_text(x_tolerance=2, y_tolerance=3, layout=True) or ""
        pages.append({"page": index, "width": page.width, "height": page.height, "text": text})
        (output / f"page-{index:03d}.txt").write_text(text, encoding="utf-8")
        try:
            image = page.to_image(resolution=120, antialias=True)
            image.save(output / f"page-{index:03d}.png", format="PNG")
        except Exception as exc:
            print(f"render_error page={index}: {exc}")

(output / "pages.json").write_text(json.dumps(pages, indent=2), encoding="utf-8")
(output / "document.txt").write_text(
    "\n\n".join(f"===== PAGE {p['page']} =====\n{p['text']}" for p in pages),
    encoding="utf-8",
)
print(json.dumps({"pages": len(pages), "chars": sum(len(p["text"]) for p in pages)}))
