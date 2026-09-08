import json
from pathlib import Path
import sys
import re
from zipfile import ZipFile
from docx import Document


def fail(message):
    raise SystemExit(f"FAIL: {message}")


template = Path(sys.argv[1])
patch_path = Path(sys.argv[2])
doc = Document(template)
text = "\n".join(p.text for p in doc.paragraphs)
table_text = "\n".join(cell.text for table in doc.tables for row in table.rows for cell in row.cells)

for token in (
    "{{#IF_QuoteLineGroupsPresentTrue}}",
    "{{#Group}}",
    "{{Name}}",
    "{{StartDate}}",
    "{{EndDate}}",
    "{{#Line}}",
    "{{ProductName}}",
    "{{Quantity}}",
    "{{BillingFrequency}}",
    "{{LineDescriptionWithType}}",
    "{{Price}}",
):
    if token not in text + "\n" + table_text:
        fail(f"missing template token {token}")

if text.count("{{#Group}}") != text.count("{{/Group}}"):
    fail("unbalanced Group blocks")

# Validate section ordering from the underlying Word XML, including tables.
xml = ZipFile(template).read("word/document.xml").decode("utf-8")
xml_text = "".join(re.findall(r"<w:t[^>]*>(.*?)</w:t>", xml))
stack = []
for token in re.findall(r"{{([#/])([^}]+)}}", xml_text):
    marker, name = token
    if marker == "#":
        stack.append(name)
    elif not stack or stack.pop() != name:
        fail(f"invalid section nesting at closing token {name}")
if stack:
    fail(f"unclosed template sections: {', '.join(stack)}")

patch = json.loads(patch_path.read_text(encoding="utf-8"))
if patch.get("deploy") is not False:
    fail("bundle is not explicitly marked deploy=false")

updates = [u for transform in patch["dataTransforms"] for u in transform["itemUpdates"]]
targets = {u["to"] for u in updates if u["field"] == "OutputFieldName"}
required_paths = {
    "Group:Line:ProductName",
    "Group:Line:ShipToAccountName",
    "Group:Line:Quantity",
    "Group:Line:BillingFrequency",
    "Group:Line:LineDescriptionWithType",
    "Group:Line:Price",
}
missing = required_paths - targets
if missing:
    fail(f"missing nested line mappings: {sorted(missing)}")

print(f"PASS: {template.name}")
print(f"PASS: {len(doc.tables)} tables; {text.count('{{#Group}}')} grouped rendering branches")
print(f"PASS: {len(updates)} isolated Data Mapper item updates")
print("PASS: bundle is local-only and deploy=false")
