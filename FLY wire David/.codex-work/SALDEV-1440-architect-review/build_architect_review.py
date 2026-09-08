from __future__ import annotations

from copy import deepcopy
from hashlib import sha256
from io import BytesIO
from pathlib import Path
import textwrap
import zipfile

from lxml import etree
from PIL import Image, ImageDraw, ImageFont


TASK_DIR = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david\.codex-work\SALDEV-1440-architect-review")
REFERENCE = TASK_DIR / "SCC-3385-architect-review.docx"
OUTPUT = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david\output\documents\SALDEV-1440-architect-review.docx")
EXPECTED_REFERENCE_HASH = "A63491D6161B45ACC1C082B240AD46B7900D0506EFDE5A311F1C0504DB60E88C"

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
NS = {"w": W_NS}
XML_SPACE = "{http://www.w3.org/XML/1998/namespace}space"

NAVY = "#0B2545"
BLUE = "#2E74B5"
TEXT = "#1F2937"
MUTED = "#5B6777"
GREEN = "#138A72"
GREEN_FILL = "#E4F3EE"
AMBER = "#B7791F"
AMBER_FILL = "#FFF4D6"
RED = "#C53030"
RED_FILL = "#FDE8E8"
PANEL = "#F5F7FA"
WHITE = "#FFFFFF"


def font(size: int, bold: bool = False, italic: bool = False) -> ImageFont.FreeTypeFont:
    if bold and italic:
        name = "arialbi.ttf"
    elif bold:
        name = "arialbd.ttf"
    elif italic:
        name = "ariali.ttf"
    else:
        name = "arial.ttf"
    return ImageFont.truetype(str(Path(r"C:\Windows\Fonts") / name), size)


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        trial = f"{current} {word}".strip()
        if draw.textbbox((0, 0), trial, font=fnt)[2] <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_lines(draw: ImageDraw.ImageDraw, xy: tuple[int, int], lines: list[str], fnt, fill, gap: int = 8) -> int:
    x, y = xy
    for line in lines:
        draw.text((x, y), line, font=fnt, fill=fill)
        y += fnt.size + gap
    return y


def rounded_box(draw, box, title, items, stroke, fill, title_fill=None, item_font_size=22):
    x1, y1, x2, y2 = box
    draw.rounded_rectangle(box, radius=20, fill=fill, outline=stroke, width=4)
    draw.rounded_rectangle((x1, y1, x2, y1 + 68), radius=20, fill=title_fill or fill, outline=stroke, width=4)
    draw.rectangle((x1 + 2, y1 + 48, x2 - 2, y1 + 70), fill=title_fill or fill)
    draw.text((x1 + 24, y1 + 20), title, font=font(27, bold=True), fill=NAVY)
    y = y1 + 92
    item_font = font(item_font_size)
    for item in items:
        draw.ellipse((x1 + 26, y + 7, x1 + 38, y + 19), fill=stroke)
        lines = wrap(draw, item, item_font, x2 - x1 - 82)
        y = draw_lines(draw, (x1 + 52, y), lines, item_font, TEXT, gap=6) + 14


def arrow(draw, start, end, color=BLUE, width=7):
    draw.line((start, end), fill=color, width=width)
    ex, ey = end
    sx, sy = start
    if abs(ex - sx) >= abs(ey - sy):
        points = [(ex, ey), (ex - 20, ey - 13), (ex - 20, ey + 13)] if ex >= sx else [(ex, ey), (ex + 20, ey - 13), (ex + 20, ey + 13)]
    else:
        points = [(ex, ey), (ex - 13, ey - 20), (ex + 13, ey - 20)] if ey >= sy else [(ex, ey), (ex - 13, ey + 20), (ex + 13, ey + 20)]
    draw.polygon(points, fill=color)


def figure_one() -> bytes:
    img = Image.new("RGB", (1600, 1020), PANEL)
    d = ImageDraw.Draw(img)
    d.text((68, 54), "SALDEV-1440 | Partial verification path", font=font(38, bold=True), fill=NAVY)
    d.text((68, 108), "Live configuration, source synchronization, and check-only evidence", font=font(22), fill=MUTED)

    rounded_box(d, (60, 195, 480, 655), "FlywirePartial", [
        "Allow Product Ramping checkbox exists",
        "Line Editor displays the indicator",
        "CPQ Sales Permissions grants edit access",
        "Business validation recorded in Partial",
    ], GREEN, "#F8FCFA", "#E6F3EF", 21)
    rounded_box(d, (590, 195, 1010, 655), "Scoped source + dry run", [
        "Three story components retrieved",
        "Missing local field set synchronized",
        "Field set exactly matches live metadata",
        "Check-only job validated 1 of 1",
    ], BLUE, "#F8FBFE", "#E5EFF9", 21)
    rounded_box(d, (1120, 195, 1540, 655), "Architect outcome", [
        "GO for story closure in Partial",
        "No deployment or activation performed",
        "Promotion target not assessed",
        "Linked observations remain separate scope",
    ], GREEN, "#F8FCFA", "#E6F3EF", 21)
    arrow(d, (480, 420), (590, 420))
    arrow(d, (1010, 420), (1120, 420))
    d.text((500, 382), "retrieve", font=font(18), fill=MUTED)
    d.text((1030, 382), "verify", font=font(18), fill=MUTED)

    rounded_box(d, (60, 725, 760, 950), "Verified story scope", [
        "Backend indicator, QLE visibility, permissions, ramped cloning, and standard grouping are evidenced.",
    ], GREEN, "#F8FCFA", "#E6F3EF", 20)
    rounded_box(d, (840, 725, 1540, 950), "Linked follow-up", [
        "SALDEV-1404 owns the deeper duplicate matrix; cloning observations should be tracked separately.",
    ], AMBER, "#FFFBF2", "#FFF1CC", 20)
    out = BytesIO()
    img.save(out, format="PNG", optimize=True)
    return out.getvalue()


def figure_two() -> bytes:
    img = Image.new("RGB", (1600, 1100), WHITE)
    d = ImageDraw.Draw(img)
    d.text((70, 40), "SALDEV-1440 | Quote group classification model", font=font(38, bold=True), fill=NAVY)
    d.text((70, 95), "One visible indicator selects ramped or standard group behavior", font=font(22), fill=MUTED)

    rounded_box(d, (60, 205, 360, 560), "Sales user", [
        "Creates or clones Quote Line Groups",
        "Chooses the intended grouping use case",
    ], BLUE, "#F8FBFE", "#E5EFF9", 20)
    rounded_box(d, (440, 170, 830, 595), "Allow Product Ramping", [
        "Checkbox on Quote Line Group",
        "Visible in SBQQ__LineEditor",
        "Editable through CPQ Sales Permissions",
        "Default value is false",
    ], BLUE, "#F8FBFE", "#E5EFF9", 20)
    rounded_box(d, (930, 160, 1535, 480), "Checked: ramped group", [
        "Clone the same product across groups",
        "Use effective dates and subscription term",
        "Cover the full contract timeframe",
        "Duplicate guardrails continue under SALDEV-1404",
    ], GREEN, "#F8FCFA", "#E6F3EF", 20)
    rounded_box(d, (930, 565, 1535, 885), "Unchecked: standard group", [
        "Separate by Ship To, Payments, or other use",
        "Different products may appear by group",
        "Same product is allowed for different Ship To",
        "Stepped-pricing guardrails do not apply",
    ], AMBER, "#FFFBF2", "#FFF1CC", 20)

    arrow(d, (360, 382), (440, 382))
    arrow(d, (830, 315), (930, 315), GREEN)
    arrow(d, (830, 455), (930, 700), AMBER)
    d.text((850, 278), "true", font=font(18, bold=True), fill=GREEN)
    d.text((850, 520), "false", font=font(18, bold=True), fill=AMBER)

    d.rounded_rectangle((160, 945, 1440, 1035), radius=18, fill="#E7F0F9", outline=BLUE, width=4)
    d.text((195, 970), "Shared control plane: QLE field set + CPQ Sales Permissions + linked duplicate validation", font=font(24, bold=True), fill=NAVY)
    out = BytesIO()
    img.save(out, format="PNG", optimize=True)
    return out.getvalue()


REPLACEMENTS = {
    1: "SALDEV-1440 | Distinguish Stepped-Up and Standard Quote Groups",
    2: "Flywire Partial | Architect verification and check-only readiness assessment",
    4: "FlywirePartial | Org 00DhG0000000jOXUAY",
    5: "Local source",
    6: "DX source synchronized from FlywirePartial",
    10: "Succeeded | Job 0AfhG000001XgKrSAK | 1/1 validated",
    12: "GO - Close in Partial; validate separately before promotion",
    14: "Read-only retrieval and check-only validation; no deployment or activation",
    17: "Approve SALDEV-1440 for closure in Partial. The checkbox, Line Editor visibility, and sales permissions are present, and the scoped field-set dry run passed unchanged. Keep SALDEV-1404 testing and cloning observations as linked follow-up scope.",
    25: "Backend indicator",
    26: "Pass",
    27: "Allow Product Ramping exists on SBQQ__QuoteLineGroup__c as a checkbox with default false.",
    29: "QLE visibility",
    30: "Pass",
    31: "SBQQ__LineEditor displays the checkbox with effective start, subscription term, and effective end.",
    33: "Sales access",
    34: "Pass",
    35: "CPQ Sales Permissions grants readable=true and editable=true for the indicator.",
    37: "Ramped cloning",
    38: "Pass",
    39: "Partial review confirmed cloning saves once the groups cover the full contract timeframe.",
    41: "Standard grouping",
    42: "Pass",
    43: "Different products and the same product with different Ship To locations were confirmed.",
    45: "Scope separation",
    46: "Scoped pass",
    47: "SALDEV-1404 owns deeper duplicate testing; fee carry-over and later-group roll-down are separate observations.",
    51: "The live Partial configuration and local story source now align. The scoped dry run passed unchanged; promotion to another org still requires its own package and validation.",
    53: "Figure 1. SALDEV-1440 Partial verification path",
    55: "Green is verified in Partial. Blue is synchronized source. Amber remains linked follow-up scope.",
    64: "0AfhG000001XgKrSAK",
    65: "checkOnly=true; rollbackOnError=true; NoTestRun",
    67: "1 component / 3 files",
    68: "FieldSet: SBQQ__QuoteLineGroup__c.SBQQ__LineEditor",
    70: "1",
    71: "The field set validated successfully and was reported unchanged against FlywirePartial.",
    73: "0",
    74: "No component failures or warnings were returned.",
    77: "Metadata-only dry run; no Apex or record writes were in scope.",
    79: "2. Exact configuration evidence",
    80: "Configuration",
    81: "Result",
    82: "Live evidence",
    83: "Backend indicator",
    84: "Verified",
    85: "Allow Product Ramping is a checkbox, defaults false, and identifies stepped-up groups.",
    86: "Line Editor field set",
    87: "Verified",
    88: "Displayed fields include the indicator, effective dates, and subscription term.",
    89: "Sales permission",
    90: "Verified",
    91: "CPQ Sales Permissions grants both read and edit access to the indicator.",
    93: "3. Scope boundaries and follow-ups",
    94: "Area",
    95: "Status",
    96: "Evidence / action",
    97: "Current Partial org",
    98: "Ready",
    99: "Field, field-set placement, and permission access are present in the live sandbox.",
    100: "Local source sync",
    101: "Completed",
    102: "The missing SBQQ__LineEditor metadata was added locally and exactly matches the live retrieval.",
    103: "Duplicate matrix",
    104: "Linked",
    105: "SALDEV-1404 owns detailed New Business, Amendment, and Renewal duplicate validation.",
    106: "Clone observations",
    107: "Separate",
    108: "One-time fee carry-over and no automatic later-group product roll-down should be tracked separately.",
    109: "Promotion target",
    110: "Not assessed",
    111: "No destination org was supplied; repeat the scoped retrieve and check-only validation before promotion.",
    114: "Quote group classification architecture",
    115: "The user-visible checkbox selects the group use case while the shared field set and permission set expose the control consistently in the Quote Line Editor.",
    117: "Figure 2. SALDEV-1440 quote group classification and control model",
    120: "Required handoff gates",
    126: "Close SALDEV-1440 in Partial",
    127: "Product owner",
    128: "Attach the architect response and move the story from Unresolved after approval.",
    130: "Maintain SALDEV-1404 linkage",
    131: "QA / Developer",
    132: "Complete the duplicate matrix for New Business, Amendment, and Renewal.",
    134: "Log cloning observations",
    135: "Product owner",
    136: "Track one-time fee carry-over and later-group product roll-down outside this story.",
    138: "Promote scoped metadata",
    139: "Release manager",
    140: "Include the checkbox field, Line Editor field set, and CPQ Sales Permissions only.",
    142: "Validate destination org",
    143: "Release manager",
    144: "Require a clean three-component check-only result before deployment approval.",
    146: "Execute business smoke test",
    147: "Sales Ops / QA",
    148: "Test ramped cloning, standard groups, and same-product groups with different Ship To values.",
    152: "Architect review completed for SALDEV-1440 in FlywirePartial. GO for closure in Partial: Allow Product Ramping exists, is visible in the Quote Line Editor, and is editable through CPQ Sales Permissions. The scoped field-set dry run succeeded unchanged (job 0AfhG000001XgKrSAK, 1 of 1 component, no deployment). Partial review evidence covers ramped cloning, standard groups, and same products with different Ship To locations. SALDEV-1404 remains responsible for the deeper duplicate matrix; one-time fee carry-over and later-group product roll-down should be tracked separately. Before promotion, deploy only the three story components, validate the destination org, and execute the business smoke tests.",
    155: "This assessment combines the SALDEV-1440 ticket export, scoped live metadata retrieval, local source comparison, and a FlywirePartial check-only validation. No records, deployment, activation, quick deploy, or org metadata changes were performed.",
}


def paragraph_text(p) -> str:
    return "".join(p.xpath(".//w:t/text()", namespaces=NS))


def replace_paragraph(p, new_text: str) -> None:
    texts = p.xpath(".//w:t", namespaces=NS)
    if not texts:
        raise RuntimeError("Cannot replace a paragraph with no text nodes")
    texts[0].text = new_text
    texts[0].set(XML_SPACE, "preserve")
    for node in texts[1:]:
        node.text = ""


def set_segmented_paragraph(p, segments: list[str]) -> None:
    texts = p.xpath(".//w:t", namespaces=NS)
    if len(texts) < len(segments):
        raise RuntimeError("Not enough source runs to preserve segmented formatting")
    for index, node in enumerate(texts):
        node.text = segments[index] if index < len(segments) else ""
        node.set(XML_SPACE, "preserve")


def ensure_child(parent, tag):
    node = parent.find(f"w:{tag}", NS)
    if node is None:
        node = etree.SubElement(parent, f"{{{W_NS}}}{tag}")
    return node


def style_status(p, color: str, fill: str) -> None:
    tc = p.getparent()
    while tc is not None and tc.tag != f"{{{W_NS}}}tc":
        tc = tc.getparent()
    if tc is None:
        raise RuntimeError("Status paragraph is not inside a table cell")
    tc_pr = ensure_child(tc, "tcPr")
    shd = ensure_child(tc_pr, "shd")
    shd.set(f"{{{W_NS}}}fill", fill.lstrip("#"))
    for run in p.xpath(".//w:r", namespaces=NS):
        rpr = run.find("w:rPr", NS)
        if rpr is None:
            rpr = etree.Element(f"{{{W_NS}}}rPr")
            run.insert(0, rpr)
        clr = ensure_child(rpr, "color")
        clr.set(f"{{{W_NS}}}val", color.lstrip("#"))
        ensure_child(rpr, "b")


def mark_header_row(table) -> None:
    first_row = table.find("w:tr", NS)
    if first_row is None:
        return
    tr_pr = ensure_child(first_row, "trPr")
    ensure_child(tr_pr, "tblHeader")


def patch_document(xml_bytes: bytes) -> bytes:
    parser = etree.XMLParser(remove_blank_text=False)
    root = etree.fromstring(xml_bytes, parser)
    paragraphs = root.xpath("//w:p", namespaces=NS)
    for index, new_text in REPLACEMENTS.items():
        replace_paragraph(paragraphs[index], new_text)
    set_segmented_paragraph(paragraphs[118], [
        "Architect interpretation:",
        " the classification control is fully exposed in Partial. Ramped and standard paths share the same QLE and permission foundation, while deeper duplicate behavior remains linked to SALDEV-1404.",
    ])
    for index in (26, 30, 34, 38, 42, 46, 84, 87, 90, 98, 101):
        style_status(paragraphs[index], GREEN, GREEN_FILL)
    for index in (104, 107, 110):
        style_status(paragraphs[index], AMBER, AMBER_FILL)
    tables = root.xpath("//w:tbl", namespaces=NS)
    for table_index in (2, 4, 5, 6, 7):
        mark_header_row(tables[table_index])
    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone="yes")


def patch_footer(xml_bytes: bytes) -> bytes:
    parser = etree.XMLParser(remove_blank_text=False)
    root = etree.fromstring(xml_bytes, parser)
    for node in root.xpath("//w:t", namespaces=NS):
        if node.text and "GreatPlainsMerge to UAT" in node.text:
            node.text = node.text.replace("GreatPlainsMerge to UAT", "FlywirePartial review")
    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone="yes")


def main() -> None:
    actual_hash = sha256(REFERENCE.read_bytes()).hexdigest().upper()
    if actual_hash != EXPECTED_REFERENCE_HASH:
        raise SystemExit(f"Reference hash mismatch: {actual_hash}")
    replacements = {
        "word/media/image3.png": figure_one(),
        "word/media/image4.png": figure_two(),
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(REFERENCE, "r") as source, zipfile.ZipFile(OUTPUT, "w", zipfile.ZIP_DEFLATED) as target:
        for item in source.infolist():
            data = source.read(item.filename)
            if item.filename == "word/document.xml":
                data = patch_document(data)
            elif item.filename in {"word/footer1.xml", "word/footer2.xml", "word/footer3.xml"}:
                data = patch_footer(data)
            elif item.filename in replacements:
                data = replacements[item.filename]
            target.writestr(item, data)
    print(OUTPUT)


if __name__ == "__main__":
    main()
