from __future__ import annotations

import hashlib
import io
import os
import shutil
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from lxml import etree
from PIL import Image, ImageDraw, ImageFont


REFERENCE = Path(r"C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-4179-architect-review.docx")
OUTPUT = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david\review\SALDEV-1413-architect-doc\SALDEV-1413-architect-review.docx")
EXPECTED_SHA256 = "6CD3A83323E24FCE40799F07B7E2A0D0E8960AC060138EF1B827A2DEE7B5E2A9"

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
DC_NS = "http://purl.org/dc/elements/1.1/"
CP_NS = "http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
DCTERMS_NS = "http://purl.org/dc/terms/"
XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"
NS = {"w": W_NS}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


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
    body = root.find("w:body", NS)
    return body.findall("w:p", NS)


def body_tables(root):
    body = root.find("w:body", NS)
    return body.findall("w:tbl", NS)


def cell_paragraphs(table, row: int, col: int):
    rows = table.findall("w:tr", NS)
    cells = rows[row].findall("w:tc", NS)
    return cells[col].findall("w:p", NS)


def set_cell(table, row: int, col: int, text: str) -> None:
    paragraphs = cell_paragraphs(table, row, col)
    set_paragraph_text(paragraphs[0], text)
    for paragraph in paragraphs[1:]:
        set_paragraph_text(paragraph, "")


def set_callout(table, label: str, body: str) -> None:
    paragraphs = cell_paragraphs(table, 0, 0)
    if len(paragraphs) < 2:
        raise RuntimeError("Expected two-paragraph callout cell")
    set_paragraph_text(paragraphs[0], label)
    set_paragraph_text(paragraphs[1], body)


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
    path = Path(r"C:\Windows\Fonts") / filename
    return ImageFont.truetype(str(path), size=size)


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


def draw_bullet_list(draw, x, y, items, fnt, text_color, dot_color, max_width):
    for item in items:
        draw.ellipse((x, y + 11, x + 12, y + 23), fill=dot_color)
        lines = wrapped_lines(draw, item, fnt, max_width - 30)
        line_height = draw.textbbox((0, 0), "Ag", font=fnt)[3] + 7
        for idx, line in enumerate(lines):
            draw.text((x + 28, y + idx * line_height), line, font=fnt, fill=text_color)
        y += max(58, len(lines) * line_height + 16)
    return y


def build_diagram() -> bytes:
    canvas = Image.new("RGB", (1600, 1000), "#F7F9FC")
    draw = ImageDraw.Draw(canvas)
    navy = "#0B2545"
    gray = "#5B6777"
    red = "#C53030"
    red_fill = "#FCEBEC"
    amber = "#B7791F"
    amber_fill = "#FFF5D9"
    green = "#16836B"
    green_fill = "#E7F5F0"
    blue = "#2E74B5"
    blue_fill = "#EAF2FB"

    draw.text((70, 50), "SALDEV-1413 | ARR correction and promotion path", font=font(40, True), fill=navy)
    draw.text((70, 105), "Targeted fixes are required before the active sandbox implementation is ready to promote.", font=font(22), fill=gray)

    boxes = [
        (55, "Grouping identity", red, red_fill, ["Quote + Product key", "20+ collision groups", "Distinct ramp lines merge"]),
        (430, "Requirement alignment", red, red_fill, ["Latest comment says retain fields", "7 flows use new averages", "Owner decision required"]),
        (805, "Rollup durability", amber, amber_fill, ["Partial DML ignored", "Null divisor is unguarded", "Atomic handling required"]),
        (1180, "Release proof", green, green_fill, ["Correct stable key", "Five-mapping test matrix", "UAT and read-back"]),
    ]
    box_y, box_w, box_h = 210, 320, 380
    for x, title, stroke, fill, bullets in boxes:
        draw.rounded_rectangle((x, box_y, x + box_w, box_y + box_h), radius=22, fill=fill, outline=stroke, width=5)
        draw.text((x + 24, box_y + 28), title, font=font(25, True), fill=navy)
        draw_bullet_list(draw, x + 28, box_y + 105, bullets, font(20), navy, stroke, box_w - 50)

    arrow_labels = [(375, 430, "FIX", red), (750, 805, "ALIGN", red), (1125, 1180, "GUARD", amber)]
    for x1, x2, label, color in arrow_labels:
        y = box_y + 205
        draw.line((x1, y, x2 - 15, y), fill=color, width=6)
        draw.polygon([(x2 - 15, y - 13), (x2, y), (x2 - 15, y + 13)], fill=color)
        label_box = draw.textbbox((0, 0), label, font=font(16, True))
        label_w = label_box[2] - label_box[0]
        draw.text(((x1 + x2 - label_w) / 2, y - 40), label, font=font(16, True), fill=color)

    draw.rounded_rectangle((70, 690, 1530, 910), radius=24, fill=blue_fill, outline=blue, width=4)
    draw.text((105, 730), "Architect reading", font=font(26, True), fill=navy)
    reading = (
        "Keep the metadata-driven engine, but change its identity key, resolve the ticket-field conflict, "
        "make rollup writes atomic, and prove all five mappings. The 12 business flows should receive "
        "surgical formula changes only - this review does not recommend a wholesale AI-style rewrite."
    )
    draw_wrapped(draw, (105, 785), reading, font(21), navy, 1370, line_gap=8)

    stream = io.BytesIO()
    canvas.save(stream, format="PNG", optimize=True)
    return stream.getvalue()


def patch_document(xml_bytes: bytes) -> bytes:
    root = etree.fromstring(xml_bytes)
    paragraphs = body_paragraphs(root)
    tables = body_tables(root)
    for table_index in (2, 4, 5, 7, 8, 10, 11):
        mark_header_row(tables[table_index])

    paragraph_text = {
        0: "ARCHITECT REVIEW",
        1: "SALDEV-1413 | Stepped-up Pricing ARR Flows",
        2: "Flywire Partial sandbox | Read-only implementation and promotion-readiness assessment",
        5: "Acceptance outcome",
        8: "Correction and control path",
        9: "Use a targeted correction: preserve the metadata-driven rollup engine, group by a stable ramp-line identity, align the seven affected flows with the final product-owner decision, make rollup writes atomic, and prove the result with focused Apex and business UAT.",
        11: "Figure 1. SALDEV-1413 ARR correction and promotion path",
        14: "Current SALDEV-1413 implementation evidence",
        15: "Apex and configuration evidence",
        17: "Flow and test evidence",
        21: "Implementation and release boundary",
        23: "Release sequence",
        27: "UAT and approval gates",
        29: "Required approval gates",
        31: "Ready-to-paste architect response",
    }
    for index, text in paragraph_text.items():
        set_paragraph_text(paragraphs[index], text)

    meta = [
        ("Environment", "FlywirePartial | Org 00DhG0000000jOX | Sandbox"),
        ("Review date", "26 August 2026"),
        ("Evidence", "Active-state read-back | retrieved metadata | Apex test | SOQL collision checks"),
        ("Decision", "Changes Requested - not ready for promotion"),
        ("Boundary", "No code edits, deployment, activation, data changes, or Production changes"),
    ]
    for row, values in enumerate(meta):
        set_cell(tables[0], row, 0, values[0])
        set_cell(tables[0], row, 1, values[1])

    set_callout(
        tables[1],
        "ARCHITECT DECISION",
        "Do not promote yet. The implementation is bulk-aware and metadata-driven, but its aggregation key merges distinct lines, seven active flows conflict with the latest story clarification, and rollup failures can leave unsafe prorate divisors.",
    )

    acceptance = [
        ("#", "Scope", "Result", "Evidence"),
        ("1", "Aggregation correctness", "Fail", "Apex groups only by Quote + Product; sandbox evidence found 20+ groups with multiple distinct line identities."),
        ("2", "Requirement alignment", "Fail", "The final story comment says retain Quoted Usage fields, but two mappings and seven active flows average them."),
        ("3", "Runtime durability", "Fail", "Partial SaveResults are ignored and three flows divide directly by Total_Prorate_Multiplier__c."),
        ("4", "Active component scope", "Pass", "All 12 named target flows are active/latest; the active B2B XB API name is the _1 definition."),
        ("5", "Automated proof", "Partial", "Focused Apex tests passed, but handler coverage is 72% and four mappings plus Flow behavior are untested."),
    ]
    for row, values in enumerate(acceptance):
        for col, text in enumerate(values):
            set_cell(tables[2], row, col, text)

    set_callout(
        tables[3],
        "DESIGN READING",
        "Red marks release blockers. Amber marks runtime risk. Green is the required promotion proof. Correct the shared engine and formulas surgically; do not rewrite all 12 flows.",
    )

    apex_evidence = [
        ("Evidence area", "Current implementation", "Acceptance", "Architect reading"),
        ("Group identity", "Quote + Product", "Fail", "Distinct ramp lines can merge."),
        ("Requirement mapping", "5 CMDT mappings", "Fail", "Two usage mappings contradict the final comment."),
        ("DML handling", "update(..., false)", "Fail", "Partial SaveResults are unchecked."),
        ("Prorate safety", "Direct division", "Fail", "Three flows lack divisor guards."),
        ("Audit narrative", "Healthcare text mismatch", "Fail", "Formula and audit text use different fields."),
        ("Bulk structure", "2 queries + 1 DML", "Pass", "The bulk execution pattern is sound."),
    ]
    for row, values in enumerate(apex_evidence):
        for col, text in enumerate(values):
            set_cell(tables[4], row, col, text)

    flow_evidence = [
        ("Evidence area", "Observed state", "Acceptance", "Architect reading"),
        ("Usage-field flows", "7 active flows", "Fail", "Seven flows change fields marked to retain."),
        ("Prorate flows", "3 active flows", "Fail", "Three flows divide without a guard."),
        ("Collision evidence", "20+ groups", "Fail", "395 lines / 394 identities in one group."),
        ("Test coverage", "5 methods; 72%", "Fail", "Only the rate mapping is asserted."),
        ("Definition state", "12/12 active/latest", "Pass", "All target definitions match."),
    ]
    for row, values in enumerate(flow_evidence):
        for col, text in enumerate(values):
            set_cell(tables[5], row, col, text)

    set_callout(
        tables[6],
        "PROMOTION BLOCKER",
        "Do not promote until duplicate-line grouping, usage-field alignment, divisor safety, and all five mappings are proven.",
    )

    components = [
        ("Component type", "Focused scope", "Required action"),
        ("Apex rollup service", "calculateAveragePrice (QuoteLineTriggerHandler)", "Group by Opportunity_Line_Id__c or an approved composite identity."),
        ("Quote Line trigger", "QuoteLineTrigger after-save path", "Preserve bulk execution; make recursion reset and error handling deterministic."),
        ("Custom metadata", "5 Quote Line rollup mappings", "Validate fields and operations; retain/remove usage mappings after owner decision."),
        ("Usage ARR flows", "7 active flows", "Apply only the approved usage-field formula decision; preserve unrelated logic."),
        ("Prorate ARR flows", "Edu Payables; Fixed Price; Travel Payables", "Guard null/zero totals and require atomic rollup completion."),
        ("Automated tests", "Apex plus targeted Flow/UAT scenarios", "Cover five mappings, duplicate identities, bulk quotes, delete/update, null/zero, and regression."),
    ]
    for row, values in enumerate(components):
        for col, text in enumerate(values):
            set_cell(tables[7], row, col, text)

    sequence = [
        ("Phase", "Required evidence"),
        ("Pre-deployment", "Obtain written owner confirmation on Quoted Usage fields; approve the stable line identity; retrieve the current target-org baseline."),
        ("Sandbox correction", "Make a focused Apex/mapping/formula change only; preserve unrelated Flow behavior and active-state boundaries."),
        ("Validation and UAT", "Run the expanded Apex matrix, focused Flow tests, check-only validation, stepped/non-stepped business scenarios, and capture job IDs and record-level expected ARR."),
        ("Promotion and read-back", "Promote only after approval; verify active versions, Apex coverage, rollup fields, ARR outputs, and logs. Roll back the approved package if a critical regression appears."),
    ]
    for row, values in enumerate(sequence):
        for col, text in enumerate(values):
            set_cell(tables[8], row, col, text)

    set_callout(
        tables[9],
        "PRODUCTION GATE",
        "This review covered FlywirePartial only. Production was not inventoried or changed. Re-retrieve current Production metadata and run focused check-only validation before any deployment decision.",
    )

    uat = [
        ("Test", "Pass evidence"),
        ("Stepped grouping", "Two occurrences of the same product retain separate identities while each ramp sequence receives its own average and total proration."),
        ("Non-stepped regression", "A non-stepped line produces the same ARR as the current approved baseline with no average-field side effect."),
        ("Usage-field decision", "Percent and amount scenarios match the written product-owner decision, including the existing divide-by-100 behavior."),
        ("Prorate products", "Edu Payables, Fixed Price, and Travel Payables handle populated, null, and zero total-prorate conditions without blank ARR or Flow faults."),
        ("Bulk and lifecycle", "Multi-quote insert, update, delete, start-date shift, and duplicate-product tests pass with expected rollup placement."),
    ]
    for row, values in enumerate(uat):
        for col, text in enumerate(values):
            set_cell(tables[10], row, col, text)

    approvals = [
        ("#", "Required action", "Owner", "Evidence needed"),
        ("1", "Confirm usage-field requirement", "Product Owner / Architect", "Written decision resolving the final comment versus earlier design text."),
        ("2", "Approve rollup identity", "CPQ Architect", "Named stable key and examples for repeated products, bundles, and ramp groups."),
        ("3", "Complete focused correction", "Development Lead", "Reviewed Apex, CMDT, and Flow diff with no unrelated rewrite."),
        ("4", "Validate sandbox package", "Release Manager / QA", "Expanded test results, coverage, check-only job ID, UAT records, and expected values."),
        ("5", "Promote and read back", "DevOps / Business Owner", "Deployment receipt, active-version checks, field-level read-back, ARR results, and sign-offs."),
    ]
    for row, values in enumerate(approvals):
        for col, text in enumerate(values):
            set_cell(tables[11], row, col, text)

    story = (
        "Architect review completed for SALDEV-1413 in FlywirePartial. Changes Requested. All 12 target flows are active/latest and focused Apex tests passed, but Quote + Product grouping can merge distinct line identities. The final story comment says retain Quoted Usage Percent and Amount; two mappings and seven active flows average them. Partial rollup failures are ignored, and three flows divide by Total_Prorate_Multiplier__c without a null/zero guard. Confirm the usage-field requirement, approve a stable line key, make writes atomic, protect the divisor, and run the five-mapping stepped/non-stepped matrix before promotion. Retrieval 09ShG000006FuUgUAK; Apex 707hG00000LJDjlQAH. No code, metadata, activation, deployment, data, or Production changes were made."
    )
    set_callout(tables[12], "STORY COMMENT", story)

    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)


def patch_footer(xml_bytes: bytes) -> bytes:
    root = etree.fromstring(xml_bytes)
    for node in root.xpath(".//w:t", namespaces=NS):
        if node.text and "GreatPlainsMerge" in node.text:
            node.text = node.text.replace("GreatPlainsMerge", "FlywirePartial")
    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)


def patch_core(xml_bytes: bytes) -> bytes:
    ns = {"dc": DC_NS, "cp": CP_NS, "dcterms": DCTERMS_NS}
    root = etree.fromstring(xml_bytes)
    values = {
        ("dc", "title"): "SALDEV-1413 Stepped-up Pricing ARR Flows Architect Review",
        ("dc", "subject"): "Read-only implementation and promotion-readiness assessment",
        ("cp", "keywords"): "Salesforce, Flywire, SALDEV-1413, ARR, stepped-up pricing, Apex, Flow, architect review",
        ("dc", "description"): "Architect review packet derived from the SCC-4179 reference design.",
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
    actual = sha256(REFERENCE)
    if actual != EXPECTED_SHA256:
        raise RuntimeError(f"Reference SHA mismatch: {actual}")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    diagram = build_diagram()
    editable = {
        "word/document.xml",
        "word/footer1.xml",
        "word/footer2.xml",
        "word/footer3.xml",
        "word/media/image2.png",
        "docProps/core.xml",
    }

    fd, temp_name = tempfile.mkstemp(prefix="saldev_1413_", suffix=".docx", dir=str(OUTPUT.parent))
    os.close(fd)
    temp_path = Path(temp_name)
    try:
        with ZipFile(REFERENCE, "r") as source, ZipFile(temp_path, "w", compression=ZIP_DEFLATED) as target:
            for item in source.infolist():
                data = source.read(item.filename)
                if item.filename == "word/document.xml":
                    data = patch_document(data)
                elif item.filename in {"word/footer1.xml", "word/footer2.xml", "word/footer3.xml"}:
                    data = patch_footer(data)
                elif item.filename == "word/media/image2.png":
                    data = diagram
                elif item.filename == "docProps/core.xml":
                    data = patch_core(data)
                target.writestr(item, data)

        with ZipFile(REFERENCE, "r") as source, ZipFile(temp_path, "r") as final:
            if source.namelist() != final.namelist():
                raise RuntimeError("Package part inventory changed")
            for name in source.namelist():
                if name not in editable and hashlib.sha256(source.read(name)).digest() != hashlib.sha256(final.read(name)).digest():
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
