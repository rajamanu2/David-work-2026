from pathlib import Path
import sys
from xml.etree import ElementTree as ET

content_path = Path(r"C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical\tmp_contract_review\odt_extracted\content.xml")
root = ET.parse(content_path).getroot()

NS = {
    "office": "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
    "text": "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
    "table": "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
    "draw": "urn:oasis:names:tc:opendocument:xmlns:drawing:1.0",
    "xlink": "http://www.w3.org/1999/xlink",
}


def text_content(node):
    parts = []
    for item in node.iter():
        if item.text:
            parts.append(item.text)
        if item.tail:
            parts.append(item.tail)
    return "".join(parts).replace("\u00a0", " ").strip()


body = root.find("office:body/office:text", NS)
output = []
if body is not None:
    for child in body:
        tag = child.tag.rsplit("}", 1)[-1]
        if tag in {"p", "h"}:
            value = text_content(child)
            if value:
                output.append(value)
        elif tag == "table":
            table_name = child.attrib.get(f"{{{NS['table']}}}name", "")
            output.append(f"[TABLE {table_name}]")
            for row in child.findall("table:table-row", NS):
                cells = []
                for cell in row.findall("table:table-cell", NS):
                    repeat = int(cell.attrib.get(f"{{{NS['table']}}}number-columns-repeated", "1"))
                    value = text_content(cell)
                    cells.extend([value] * min(repeat, 20))
                if any(cells):
                    output.append(" | ".join(cells))

for img in root.findall(".//draw:image", NS):
    href = img.attrib.get(f"{{{NS['xlink']}}}href")
    if href:
        output.append(f"[IMAGE {href}]")

sys.stdout.reconfigure(encoding="utf-8")
print("\n".join(output))
