from pathlib import Path
from zipfile import ZipFile

from docx import Document
from docx.oxml.ns import qn


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "outputs" / "next_four_architect_reviews_2026-09-01"
CASES = ["00009998", "00010158", "00009589", "00010514"]


def dxa(value):
    return round(value.inches * 1440)


failures = []
for case_id in CASES:
    path = BASE / f"Case_{case_id}_Architect_Review.docx"
    with ZipFile(path) as archive:
        bad_member = archive.testzip()
        if bad_member:
            failures.append(f"{case_id}: corrupt ZIP member {bad_member}")

    doc = Document(path)
    full_text = "\n".join(p.text for p in doc.paragraphs)
    for required in (
        f"Case {case_id}",
        "Hard-coded value assessment",
        "Steps to reproduce",
        "Expected result",
        "Pre-fix actual result",
        "Outbound change-set status",
        "UAT acceptance checklist",
        "0AfiK0000000X8rSAE",
        "13/13",
        "Production",
    ):
        if required not in full_text and not any(required in c.text for t in doc.tables for r in t.rows for c in r.cells):
            failures.append(f"{case_id}: missing required text {required}")

    section = doc.sections[0]
    geometry = {
        "page_width": dxa(section.page_width),
        "page_height": dxa(section.page_height),
        "top": dxa(section.top_margin),
        "right": dxa(section.right_margin),
        "bottom": dxa(section.bottom_margin),
        "left": dxa(section.left_margin),
    }
    expected = {
        "page_width": 12240,
        "page_height": 15840,
        "top": 1440,
        "right": 1440,
        "bottom": 1440,
        "left": 1440,
    }
    if geometry != expected:
        failures.append(f"{case_id}: page geometry {geometry}")

    for table_no, table in enumerate(doc.tables, start=1):
        tbl_pr = table._tbl.tblPr
        tbl_w = tbl_pr.find(qn("w:tblW"))
        tbl_ind = tbl_pr.find(qn("w:tblInd"))
        if tbl_w is None or tbl_w.get(qn("w:w")) != "9360":
            failures.append(f"{case_id}: table {table_no} width is not 9360 DXA")
        if tbl_ind is None or tbl_ind.get(qn("w:w")) != "120":
            failures.append(f"{case_id}: table {table_no} indent is not 120 DXA")
        grid_widths = [int(n.get(qn("w:w"))) for n in table._tbl.tblGrid.findall(qn("w:gridCol"))]
        if sum(grid_widths) != 9360:
            failures.append(f"{case_id}: table {table_no} grid sum is {sum(grid_widths)}")
        for row_no, row in enumerate(table.rows, start=1):
            cell_widths = []
            for cell in row.cells:
                tc_w = cell._tc.get_or_add_tcPr().find(qn("w:tcW"))
                cell_widths.append(int(tc_w.get(qn("w:w"))))
            if cell_widths != grid_widths:
                failures.append(f"{case_id}: table {table_no} row {row_no} widths {cell_widths} != {grid_widths}")

    numbering = doc.part.numbering_part.element
    num_ids = {n.get(qn("w:numId")) for n in numbering.findall(qn("w:num"))}
    if not {"42", "43", "44"}.issubset(num_ids):
        failures.append(f"{case_id}: real list numbering definitions missing")

    print(f"PASS {case_id}: {len(doc.paragraphs)} paragraphs, {len(doc.tables)} tables, valid package")

if failures:
    print("FAILURES")
    for failure in failures:
        print(failure)
    raise SystemExit(1)

print("ALL STRUCTURAL CHECKS PASSED")
