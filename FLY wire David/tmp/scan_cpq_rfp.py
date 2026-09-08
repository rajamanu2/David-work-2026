import json
import sys
import openpyxl

PATH = r"C:\Users\LIKKI\Downloads\CPQ RFP.xlsx"
wb = openpyxl.load_workbook(PATH, data_only=False)

groups = {
    "core": ["Introduction ", "Brief", "Flywire consolidated CPQ capabi", " CPQ Requirements"],
    "delivery": ["CPQ detailed Timeline", "CPQ SLA Framework", " CPQ Suppliers"],
    "questions": ["CPQ RFP Questions", "Research"],
}

def sparse_sheet(ws):
    rows = []
    for row in ws.iter_rows():
        cells = []
        for c in row:
            if c.value is not None:
                value = str(c.value).replace("\r\n", " | ").replace("\n", " | ")
                cells.append({"cell": c.coordinate, "value": value})
        if cells:
            rows.append(cells)
    return rows

selected = sys.argv[1] if len(sys.argv) > 1 else None
for group, names in groups.items():
    if selected and group != selected:
        continue
    payload = {name: sparse_sheet(wb[name]) for name in names}
    print(f"===GROUP:{group}===")
    print(json.dumps(payload, ensure_ascii=False, indent=2))
