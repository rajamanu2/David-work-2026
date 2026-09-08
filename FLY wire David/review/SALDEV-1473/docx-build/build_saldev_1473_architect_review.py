from __future__ import annotations

import hashlib
import io
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from lxml import etree
from PIL import Image, ImageDraw, ImageFont


REFERENCE = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david\output\documents\SALDEV-1475-architect-review.docx")
OUTPUT = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david\review\SALDEV-1473\SALDEV-1473_Architect_Review.docx")
EXPECTED_SHA256 = "B491A97DA9EC81D50922AE59C6796B3A7FE7CE7E5CDBE94E6402A4572F05141D"

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
WP_NS = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
DC_NS = "http://purl.org/dc/elements/1.1/"
CP_NS = "http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
DCTERMS_NS = "http://purl.org/dc/terms/"
XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"
NS = {"w": W_NS, "wp": WP_NS}

NAVY = "#0B2545"
BLUE = "#2E74B5"
GREEN = "#0F8F74"
GREEN_FILL = "#E7F5F0"
AMBER = "#B7791F"
AMBER_FILL = "#FFF4D6"
RED = "#C53030"
RED_FILL = "#FDEBEC"
GRAY = "#5B6777"
PALE_BLUE = "#EAF2FB"
CANVAS = "#F7F9FC"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def qn(local: str) -> str:
    return f"{{{W_NS}}}{local}"


def set_paragraph_text(paragraph, text: str) -> None:
    nodes = paragraph.xpath(".//w:t", namespaces=NS)
    if not nodes:
        run = etree.SubElement(paragraph, qn("r"))
        node = etree.SubElement(run, qn("t"))
        nodes = [node]
    target = next((node for node in nodes if (node.text or "").strip()), nodes[0])
    target.text = text
    if text.startswith(" ") or text.endswith(" "):
        target.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
    for node in nodes:
        if node is not target:
            node.text = ""


def body_paragraphs(root):
    return root.find("w:body", NS).findall("w:p", NS)


def body_tables(root):
    return root.find("w:body", NS).findall("w:tbl", NS)


def cell(table, row: int, col: int):
    rows = table.findall("w:tr", NS)
    return rows[row].findall("w:tc", NS)[col]


def cell_paragraphs(table, row: int, col: int):
    return cell(table, row, col).findall("w:p", NS)


def set_cell(table, row: int, col: int, text: str) -> None:
    paragraphs = cell_paragraphs(table, row, col)
    set_paragraph_text(paragraphs[0], text)
    for paragraph in paragraphs[1:]:
        set_paragraph_text(paragraph, "")


def set_cell_fill(table, row: int, col: int, fill: str) -> None:
    tc = cell(table, row, col)
    tc_pr = tc.find("w:tcPr", NS)
    if tc_pr is None:
        tc_pr = etree.Element(qn("tcPr"))
        tc.insert(0, tc_pr)
    shd = tc_pr.find("w:shd", NS)
    if shd is None:
        shd = etree.SubElement(tc_pr, qn("shd"))
    shd.set(qn("fill"), fill.replace("#", ""))
    shd.set(qn("val"), "clear")


def set_cell_text_style(table, row: int, col: int, color: str, bold: bool = True) -> None:
    for run in cell(table, row, col).xpath(".//w:r", namespaces=NS):
        rpr = run.find("w:rPr", NS)
        if rpr is None:
            rpr = etree.Element(qn("rPr"))
            run.insert(0, rpr)
        color_node = rpr.find("w:color", NS)
        if color_node is None:
            color_node = etree.SubElement(rpr, qn("color"))
        color_node.set(qn("val"), color.replace("#", ""))
        bold_node = rpr.find("w:b", NS)
        if bold and bold_node is None:
            etree.SubElement(rpr, qn("b"))


def set_status(table, row: int, text: str, kind: str) -> None:
    palette = {
        "pass": (GREEN_FILL, GREEN),
        "follow": (AMBER_FILL, AMBER),
        "fail": (RED_FILL, RED),
        "info": (PALE_BLUE, BLUE),
    }
    fill, color = palette[kind]
    set_cell(table, row, 2, text)
    set_cell_fill(table, row, 2, fill)
    set_cell_text_style(table, row, 2, color, True)


def set_callout(table, label: str, body: str, fill: str | None = None, label_color: str | None = None) -> None:
    paragraphs = cell_paragraphs(table, 0, 0)
    if len(paragraphs) < 2:
        raise RuntimeError("Expected two-paragraph callout cell")
    set_paragraph_text(paragraphs[0], label)
    set_paragraph_text(paragraphs[1], body)
    if fill:
        set_cell_fill(table, 0, 0, fill)
    if label_color:
        for run in paragraphs[0].xpath(".//w:r", namespaces=NS):
            rpr = run.find("w:rPr", NS)
            if rpr is None:
                rpr = etree.Element(qn("rPr"))
                run.insert(0, rpr)
            color = rpr.find("w:color", NS)
            if color is None:
                color = etree.SubElement(rpr, qn("color"))
            color.set(qn("val"), label_color.replace("#", ""))


def mark_header_row(table) -> None:
    row = table.find("w:tr", NS)
    if row is None:
        return
    properties = row.find("w:trPr", NS)
    if properties is None:
        properties = etree.Element(qn("trPr"))
        row.insert(0, properties)
    marker = properties.find("w:tblHeader", NS)
    if marker is None:
        marker = etree.SubElement(properties, qn("tblHeader"))
    marker.set(qn("val"), "1")


def font(size: int, bold: bool = False):
    filename = "arialbd.ttf" if bold else "arial.ttf"
    return ImageFont.truetype(str(Path(r"C:\Windows\Fonts") / filename), size=size)


def wrapped_lines(draw: ImageDraw.ImageDraw, text: str, fnt, max_width: int):
    words = text.split()
    lines = []
    current = ""
    for word in words:
        trial = word if not current else current + " " + word
        if draw.textbbox((0, 0), trial, font=fnt)[2] <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_wrapped(draw, xy, text, fnt, fill, max_width, line_gap=6):
    x, y = xy
    line_height = draw.textbbox((0, 0), "Ag", font=fnt)[3] + line_gap
    for line in wrapped_lines(draw, text, fnt, max_width):
        draw.text((x, y), line, font=fnt, fill=fill)
        y += line_height
    return y


def draw_bullets(draw, x, y, items, fnt, text_color, dot_color, max_width, spacing=48):
    for item in items:
        draw.ellipse((x, y + 9, x + 11, y + 20), fill=dot_color)
        lines = wrapped_lines(draw, item, fnt, max_width - 28)
        line_height = draw.textbbox((0, 0), "Ag", font=fnt)[3] + 6
        for idx, line in enumerate(lines):
            draw.text((x + 26, y + idx * line_height), line, font=fnt, fill=text_color)
        y += max(spacing, len(lines) * line_height + 13)
    return y


def draw_box(draw, rect, title, items, stroke, fill):
    x1, y1, x2, y2 = rect
    draw.rounded_rectangle(rect, radius=20, fill=fill, outline=stroke, width=4)
    draw.rectangle((x1 + 2, y1 + 2, x2 - 2, y1 + 70), fill=fill)
    draw.line((x1, y1 + 70, x2, y1 + 70), fill=stroke, width=2)
    draw.text((x1 + 20, y1 + 20), title, font=font(25, True), fill=NAVY)
    draw_bullets(draw, x1 + 22, y1 + 98, items, font(18), NAVY, stroke, x2 - x1 - 42)


def arrow(draw, x1, y, x2, label):
    draw.line((x1, y, x2 - 18, y), fill=BLUE, width=6)
    draw.polygon([(x2 - 18, y - 12), (x2, y), (x2 - 18, y + 12)], fill=BLUE)
    bbox = draw.textbbox((0, 0), label, font=font(14, True))
    width = bbox[2] - bbox[0]
    draw.text(((x1 + x2 - width) / 2, y - 32), label, font=font(14, True), fill=GRAY)


def build_correction_diagram() -> bytes:
    canvas = Image.new("RGB", (1600, 1020), CANVAS)
    draw = ImageDraw.Draw(canvas)
    draw.text((65, 45), "SALDEV-1473 | Quote-wide recalculation", font=font(38, True), fill=NAVY)
    draw.text((65, 95), "Every after-save interview now derives the header from the complete quote state.", font=font(21), fill=GRAY)

    top = 190
    width = 320
    gap = 55
    xs = [55, 55 + width + gap, 55 + 2 * (width + gap), 55 + 3 * (width + gap)]
    boxes = [
        ("QLE Save", ["Q-37873", "44 lines / 5 groups", "32 ramped lines", "Two ship-to accounts"], BLUE, PALE_BLUE),
        ("Quote Line Flow", ["After create or update", "Hierarchy validation retained", "Strategic exception retained"], BLUE, PALE_BLUE),
        ("Quote-wide lookup", ["Same Quote ID", "Direct Ship-To", "Inherited Parent Ship-To", "First different account"], GREEN, GREEN_FILL),
        ("Header outcome", ["Different found -> Yes", "None found -> No", "Q-37873 read-back: Yes"], GREEN, GREEN_FILL),
    ]
    for x, (title, items, stroke, fill) in zip(xs, boxes):
        draw_box(draw, (x, top, x + width, top + 420), title, items, stroke, fill)
    for i, label in enumerate(("after save", "query", "decide")):
        arrow(draw, xs[i] + width, top + 210, xs[i + 1], label)

    draw.rounded_rectangle((90, 720, 1510, 920), radius=24, fill=GREEN_FILL, outline=GREEN, width=4)
    draw.text((125, 755), "DEFECT REMOVED", font=font(25, True), fill=GREEN)
    message = (
        "The active version no longer lets the last processed line overwrite the quote header. "
        "All interviews use the same quote-wide evidence, so stepped and non-stepped groups converge on one deterministic result."
    )
    draw_wrapped(draw, (125, 805), message, font(22, True), NAVY, 1340, 8)
    stream = io.BytesIO()
    canvas.save(stream, format="PNG", optimize=True)
    return stream.getvalue()


def build_architecture_diagram() -> bytes:
    canvas = Image.new("RGB", (1600, 1100), "#FFFFFF")
    draw = ImageDraw.Draw(canvas)
    draw.text((70, 45), "SALDEV-1473 | Active Flow version 8", font=font(38, True), fill=NAVY)
    draw.text((70, 95), "Single-component correction with explicit preservation boundaries", font=font(21), fill=GRAY)

    boxes = [
        (70, 210, 360, 570, "Record trigger", ["SBQQ Quote Line", "After save", "Create and update"], BLUE, PALE_BLUE),
        (440, 210, 730, 570, "Validation path", ["Ultimate parent", "Strategic partner", "Invalid Ship-To error"], BLUE, PALE_BLUE),
        (810, 210, 1100, 570, "Full-quote query", ["Six filters", "Direct or inherited", "Different from quote account"], GREEN, GREEN_FILL),
        (1180, 210, 1530, 570, "Deterministic update", ["Found -> Yes", "Not found -> No", "Renewal logic continues"], GREEN, GREEN_FILL),
    ]
    for x1, y1, x2, y2, title, items, stroke, fill in boxes:
        draw_box(draw, (x1, y1, x2, y2), title, items, stroke, fill)
    for i, label in enumerate(("route", "recalculate", "update")):
        arrow(draw, boxes[i][2], 390, boxes[i + 1][0], label)

    draw.rounded_rectangle((100, 690, 760, 990), radius=22, fill=GREEN_FILL, outline=GREEN, width=4)
    draw.text((130, 725), "Verified live", font=font(27, True), fill=NAVY)
    draw_bullets(draw, 135, 790, [
        "Check-only: 1 component, 0 errors",
        "Deployment: 1 component, 0 errors",
        "Version 8 active read-back",
        "Q-37873 changed No -> Yes on Quick Save",
    ], font(20), NAVY, GREEN, 570, 54)

    draw.rounded_rectangle((840, 690, 1500, 990), radius=22, fill=AMBER_FILL, outline=AMBER, width=4)
    draw.text((870, 725), "Follow-up boundary", font=font(27, True), fill=NAVY)
    draw_bullets(draw, 875, 790, [
        "No bulk backfill was performed",
        "Pure non-stepped regression remains",
        "Yes-to-No reset remains",
        "Delete-only recalculation needs a separate decision",
    ], font(20), NAVY, AMBER, 570, 54)

    stream = io.BytesIO()
    canvas.save(stream, format="PNG", optimize=True)
    return stream.getvalue()


def set_image_alt_text(root) -> None:
    paragraphs = body_paragraphs(root)
    descriptions = {
        10: ("SALDEV-1473 quote-wide correction path", "Diagram showing QLE Save, the Quote Line Flow, the quote-wide lookup, and the deterministic Yes or No header update."),
        24: ("SALDEV-1473 active Flow version 8 architecture", "Diagram showing trigger, preserved validation, six-filter quote-wide query, deterministic update, verified evidence, and follow-up boundary."),
    }
    for index, (title, description) in descriptions.items():
        nodes = paragraphs[index].xpath(".//wp:docPr", namespaces=NS)
        if nodes:
            nodes[0].set("title", title)
            nodes[0].set("descr", description)


def patch_document(xml_bytes: bytes) -> bytes:
    root = etree.fromstring(xml_bytes)
    paragraphs = body_paragraphs(root)
    tables = body_tables(root)
    for index in (0, 2, 4, 5, 6, 7):
        mark_header_row(tables[index])

    replacements = {
        0: "ARCHITECT REVIEW",
        1: "SALDEV-1473 | Multiple Ship-to Account Header Fix",
        2: "FlywirePartial | Deployed Flow correction and functional validation",
        5: "Acceptance outcome",
        8: "Root cause and correction path",
        9: "The defect was a record-by-record last-writer race. Flow version 8 now evaluates all quote lines after create or update and derives one deterministic header value from direct or inherited ship-to accounts.",
        11: "Figure 1. SALDEV-1473 quote-wide recalculation in FlywirePartial",
        14: "Detailed implementation and validation",
        15: "1. Live org and version evidence",
        17: "2. Deployment and metadata outcome",
        19: "3. Functional result and coverage boundary",
        22: "Quote-wide Flow architecture",
        23: "The correction adds one focused Get Records element and changes decision routing while preserving hierarchy validation, the Strategic Partner exception, and Renewal plus Upsell behavior.",
        25: "Figure 2. SALDEV-1473 active Flow version 8 and validation boundary",
        26: "Architect interpretation: the single-line calculation was the failure mode. The new full-quote query removes processing-order dependence and passed the named stepped/mixed QLE acceptance test.",
        28: "Recommended completion gates",
        30: "Ready-to-paste architect response",
        32: "Evidence boundary",
        33: "This assessment combines the SALDEV-1473 story, live FlywirePartial org identity and Flow metadata, focused check-only and deployment evidence, a 30-day quote-line mismatch sample, and the Q-37873 Quick Save test. The scope was one existing Flow. No Apex, fields, permission sets, Production changes, or bulk data backfill were included.",
    }
    for index, text in replacements.items():
        set_paragraph_text(paragraphs[index], text)

    metadata = [
        ("Source", "FlywirePartial | Enterprise sandbox 00DhG0000000jOXUAY | USA1148S"),
        ("Test record", "Q-37873 | Draft | 44 lines | 32 ramped | 2 ship-to accounts"),
        ("Review date", "1 September 2026"),
        ("Validation mode", "Live metadata read-back | check-only | deployment | QLE Quick Save | SOQL read-back"),
        ("Decision", "APPROVE / PASS - Primary acceptance criterion verified in FlywirePartial"),
        ("Boundary", "Version 8 active; no Production change and no bulk record backfill"),
    ]
    for row, values in enumerate(metadata):
        set_cell(tables[0], row, 0, values[0])
        set_cell(tables[0], row, 1, values[1])

    set_callout(
        tables[1],
        "ARCHITECT DECISION",
        "Approve SALDEV-1473 in FlywirePartial for the primary acceptance criterion. Flow version 8 is active, both validations succeeded, and Q-37873 changed from No to Yes on Quick Save with independent SOQL read-back. Complete the listed regression cases before promotion beyond the sandbox.",
        GREEN_FILL,
        GREEN,
    )

    acceptance = [
        ("#", "Scope", "Result", "Evidence"),
        ("1", "Story acceptance", "PASS", "Q-37873 changed Multiple Ship to Accounts from No to Yes after Quick Save."),
        ("2", "Quote-wide calculation", "PASS", "44 lines included two ship-to accounts; six lines used the alternate account."),
        ("3", "Stepped / mixed groups", "PASS", "The quote had five groups, 32 ramped lines, and 12 non-ramped lines."),
        ("4", "Create and update path", "IMPLEMENTED", "Active version 8 uses CreateAndUpdate with RecordAfterSave."),
        ("5", "Deployment integrity", "PASS", "Check-only and deployment each validated one Flow with zero component errors."),
        ("6", "Regression breadth", "FOLLOW-UP", "Pure non-stepped, alternate ramped-line, Yes-to-No, and delete-only cases remain."),
    ]
    for row, values in enumerate(acceptance):
        for col, text in enumerate(values):
            set_cell(tables[2], row, col, text)
    for row in (1, 2, 3, 4, 5):
        set_status(tables[2], row, acceptance[row][2], "pass")
    set_status(tables[2], 6, acceptance[6][2], "follow")

    set_callout(
        tables[3],
        "DESIGN READING",
        "Blue is preserved control logic. Green is the quote-wide correction and verified live evidence. Amber is recommended regression coverage before promotion beyond Partial.",
    )

    live = [
        ("Evidence area", "Observed result", "Evidence"),
        ("Target org", "FlywirePartial", "Flywire Enterprise sandbox 00DhG0000000jOXUAY; instance USA1148S."),
        ("Prior active Flow", "Version 6", "Update-only and line-by-line; became obsolete after version 8 activation."),
        ("Prior attempted Flow", "Version 7", "Obsolete; changed only the trigger to CreateAndUpdate."),
        ("Current Flow", "Version 8 Active", "301hG00000BfrsBQAR is both ActiveVersionId and LatestVersionId."),
        ("Mismatch sample", "24 of 155 quotes", "2,000 recent lines showed 24 incorrect No headers; 15 included ramped lines."),
    ]
    for row, values in enumerate(live):
        for col, text in enumerate(values):
            set_cell(tables[4], row, col, text)

    deployment = [
        ("Deployment gate", "Result", "Evidence"),
        ("Check-only", "PASS", "0AfhG000001bMygSAE | 1 Flow | 0 component errors | CheckOnly=true."),
        ("Deployment", "PASS", "0AfhG000001bPN5SAM | 1 Flow | 0 component errors | CheckOnly=false."),
        ("Metadata read-back", "PASS", "CreateAndUpdate, RecordAfterSave, six lookup filters, expected Yes/No routing."),
    ]
    for row, values in enumerate(deployment):
        for col, text in enumerate(values):
            set_cell(tables[5], row, col, text)
    for row in (1, 2, 3):
        set_cell_fill(tables[5], row, 1, GREEN_FILL)
        set_cell_text_style(tables[5], row, 1, GREEN, True)

    coverage = [
        ("Test / boundary", "Status", "Evidence"),
        ("Primary QLE test", "PASS", "Q-37873 Quick Save updated the header to Yes; independent SOQL confirmed Yes."),
        ("Record remained safe", "PASS", "Quote remained Draft and non-ordered; no line values were intentionally edited."),
        ("Mixed-group detection", "PASS", "Ramped and non-ramped groups coexisted; alternate ship-to lines were detected."),
        ("Yes-to-No reset", "PENDING", "Use a separate clone and return the final alternate ship-to line to the quote account."),
        ("Delete-only reset", "SEPARATE SCOPE", "The active Flow handles create/update; delete-only recalculation needs a decision."),
    ]
    for row, values in enumerate(coverage):
        for col, text in enumerate(values):
            set_cell(tables[6], row, col, text)
    for row in (1, 2, 3):
        set_cell_fill(tables[6], row, 1, GREEN_FILL)
        set_cell_text_style(tables[6], row, 1, GREEN, True)
    for row in (4, 5):
        set_cell_fill(tables[6], row, 1, AMBER_FILL)
        set_cell_text_style(tables[6], row, 1, AMBER, True)

    gates = [
        ("Gate", "Recommended action", "Owner", "Evidence needed"),
        ("1", "Run pure non-stepped regression", "CPQ QA", "Quote without ramped groups; verify No -> Yes and stable Quick Save."),
        ("2", "Use alternate account on ramped line", "CPQ QA", "A ramped segment directly using the alternate related account updates the header to Yes."),
        ("3", "Run Yes-to-No reset", "CPQ QA", "On a clone, remove the final alternate ship-to and verify the header returns to No."),
        ("4", "Run create-only scenario", "Developer / QA", "Create a new alternate-account line and verify Yes without a later line edit."),
        ("5", "Decide delete-only behavior", "Product Owner", "Confirm whether deletion must reset immediately; add a separate delete path if required."),
        ("6", "Capture source and release evidence", "Dev Lead / DevOps", "Commit the focused Flow diff and attach validation, deployment, and QLE evidence."),
    ]
    for row, values in enumerate(gates):
        for col, text in enumerate(values):
            set_cell(tables[7], row, col, text)

    story = (
        "Architect review completed for SALDEV-1473 in FlywirePartial. The defect was caused by record-by-record Flow logic: a later quote line matching the quote account could overwrite a prior Yes result back to No. The existing QuoteLine After Record Triggered Flow was updated as version 8 to run after create and update, query the full quote for a direct or inherited ship-to account that differs from the quote account, and route deterministically to Yes or No. Existing hierarchy validation, the Strategic Partner exception, and Renewal plus Upsell behavior were preserved. Check-only 0AfhG000001bMygSAE and deployment 0AfhG000001bPN5SAM each succeeded for one Flow with zero component errors. Version 8 is active. Q-37873 provided the named acceptance test: 44 lines, five groups, 32 ramped lines, two ship-to accounts, and six alternate-account lines. Quick Save changed the header from No to Yes, and independent SOQL read-back confirmed Yes. Primary acceptance criterion: PASS. No Production changes or bulk data backfill were performed. Complete the recommended pure non-stepped, alternate ramped-line, Yes-to-No, create-only, and delete-scope checks before broader promotion."
    )
    set_callout(tables[8], "STORY COMMENT", story, PALE_BLUE, BLUE)

    set_image_alt_text(root)
    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)


def patch_core(xml_bytes: bytes) -> bytes:
    ns = {"dc": DC_NS, "cp": CP_NS, "dcterms": DCTERMS_NS}
    root = etree.fromstring(xml_bytes)
    values = {
        ("dc", "title"): "SALDEV-1473 Multiple Ship-to Account Header Fix Architect Review",
        ("dc", "subject"): "Deployed Salesforce Flow correction and functional validation",
        ("cp", "keywords"): "Salesforce, Flywire, SALDEV-1473, CPQ, Quote Line, Flow, architect review",
        ("dc", "description"): "Architect review derived from the established Flywire SALDEV review format.",
    }
    for (prefix, local), value in values.items():
        node = root.find(f"{prefix}:{local}", ns)
        if node is not None:
            node.text = value
    modified = root.find("dcterms:modified", ns)
    if modified is not None:
        modified.text = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        modified.set(f"{{{XSI_NS}}}type", "dcterms:W3CDTF")
    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)


def main() -> None:
    if not REFERENCE.exists():
        raise FileNotFoundError(REFERENCE)
    if sha256(REFERENCE) != EXPECTED_SHA256:
        raise RuntimeError("Reference SHA-256 mismatch")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    diagram_one = build_correction_diagram()
    diagram_two = build_architecture_diagram()
    editable = {
        "word/document.xml",
        "word/media/image3.png",
        "word/media/image4.png",
        "docProps/core.xml",
    }

    fd, temp_name = tempfile.mkstemp(prefix="saldev_1473_", suffix=".docx", dir=str(OUTPUT.parent))
    os.close(fd)
    temp_path = Path(temp_name)
    try:
        with ZipFile(REFERENCE, "r") as source, ZipFile(temp_path, "w", compression=ZIP_DEFLATED) as target:
            for item in source.infolist():
                data = source.read(item.filename)
                if item.filename == "word/document.xml":
                    data = patch_document(data)
                elif item.filename == "word/media/image3.png":
                    data = diagram_one
                elif item.filename == "word/media/image4.png":
                    data = diagram_two
                elif item.filename == "docProps/core.xml":
                    data = patch_core(data)
                target.writestr(item, data)

        with ZipFile(REFERENCE, "r") as source, ZipFile(temp_path, "r") as final:
            if source.namelist() != final.namelist():
                raise RuntimeError("Package part inventory changed")
            for name in source.namelist():
                if name not in editable:
                    before = hashlib.sha256(source.read(name)).digest()
                    after = hashlib.sha256(final.read(name)).digest()
                    if before != after:
                        raise RuntimeError(f"Preserve-only part changed: {name}")

        os.replace(temp_path, OUTPUT)
    finally:
        if temp_path.exists():
            temp_path.unlink()

    if sha256(REFERENCE) != EXPECTED_SHA256:
        raise RuntimeError("Reference changed during authoring")
    print(OUTPUT)


if __name__ == "__main__":
    main()
