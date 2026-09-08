from pathlib import Path
from textwrap import wrap

from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parent
ASSET_DIR = ROOT / "doc-assets"
OUTPUT = ROOT / "Great_Plains_Trouble_Ticket_Architect_Review.docx"
ASSET_DIR.mkdir(exist_ok=True)

# decision_memo preset: Arial, US Letter, 1-inch margins, 6.5-inch content width.
NAVY = "0B2545"
BLUE = "2E74B5"
TEAL = "16836B"
AMBER = "B7791F"
RED = "C53030"
INK = "1F2937"
MUTED = "5B6777"
LIGHT_BLUE = "EAF2FA"
LIGHT_TEAL = "E7F5F1"
LIGHT_AMBER = "FFF6DE"
LIGHT_RED = "FDECEC"
LIGHT_GRAY = "F2F4F7"
WHITE = "FFFFFF"
GRID = "D8DEE8"


def rgb(hex_color):
    return RGBColor.from_string(hex_color)


def set_run_font(run, size=11, color=INK, bold=False, italic=False, name="Arial"):
    run.font.name = name
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), name)
    run.font.size = Pt(size)
    run.font.color.rgb = rgb(color)
    run.bold = bold
    run.italic = italic


def shade_cell(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=100, start=140, bottom=100, end=140):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for m, v in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{m}"))
        if node is None:
            node = OxmlElement(f"w:{m}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(v))
        node.set(qn("w:type"), "dxa")


def set_table_geometry(table, widths_dxa, indent_dxa=120):
    total = sum(widths_dxa)
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    table.autofit = False
    tbl_pr = table._tbl.tblPr

    tbl_w = tbl_pr.find(qn("w:tblW"))
    if tbl_w is None:
        tbl_w = OxmlElement("w:tblW")
        tbl_pr.append(tbl_w)
    tbl_w.set(qn("w:w"), str(total))
    tbl_w.set(qn("w:type"), "dxa")

    tbl_ind = tbl_pr.find(qn("w:tblInd"))
    if tbl_ind is None:
        tbl_ind = OxmlElement("w:tblInd")
        tbl_pr.append(tbl_ind)
    tbl_ind.set(qn("w:w"), str(indent_dxa))
    tbl_ind.set(qn("w:type"), "dxa")

    layout = tbl_pr.find(qn("w:tblLayout"))
    if layout is None:
        layout = OxmlElement("w:tblLayout")
        tbl_pr.append(layout)
    layout.set(qn("w:type"), "fixed")

    grid = table._tbl.tblGrid
    for child in list(grid):
        grid.remove(child)
    for width in widths_dxa:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)

    for row in table.rows:
        for idx, cell in enumerate(row.cells):
            width = widths_dxa[min(idx, len(widths_dxa) - 1)]
            tc_pr = cell._tc.get_or_add_tcPr()
            tc_w = tc_pr.find(qn("w:tcW"))
            if tc_w is None:
                tc_w = OxmlElement("w:tcW")
                tc_pr.append(tc_w)
            tc_w.set(qn("w:w"), str(width))
            tc_w.set(qn("w:type"), "dxa")
            set_cell_margins(cell)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER


def set_repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def set_cell_text(cell, text, *, size=10, color=INK, bold=False, align=WD_ALIGN_PARAGRAPH.LEFT):
    cell.text = ""
    p = cell.paragraphs[0]
    p.alignment = align
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(0)
    p.paragraph_format.line_spacing = 1.05
    run = p.add_run(text)
    set_run_font(run, size=size, color=color, bold=bold)


def add_table(doc, headers, rows, widths_dxa, status_column=None):
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    set_table_geometry(table, widths_dxa)
    for i, header in enumerate(headers):
        shade_cell(table.rows[0].cells[i], LIGHT_GRAY)
        set_cell_text(table.rows[0].cells[i], header, size=9.5, color=NAVY, bold=True)
    set_repeat_table_header(table.rows[0])
    for row_data in rows:
        cells = table.add_row().cells
        for i, value in enumerate(row_data):
            if status_column is not None and i == status_column:
                val = str(value).lower()
                fill, color = (LIGHT_TEAL, TEAL) if "pass" in val and "partial" not in val else (LIGHT_AMBER, AMBER)
                if "fail" in val or "block" in val or "change" in val:
                    fill, color = LIGHT_RED, RED
                shade_cell(cells[i], fill)
                set_cell_text(cells[i], str(value), size=9.5, color=color, bold=True, align=WD_ALIGN_PARAGRAPH.CENTER)
            else:
                set_cell_text(cells[i], str(value), size=9.2)
    doc.add_paragraph().paragraph_format.space_after = Pt(1)
    return table


def add_heading(doc, text, level=1):
    p = doc.add_paragraph(style=f"Heading {level}")
    p.paragraph_format.keep_with_next = True
    p.add_run(text)
    return p


def add_body(doc, text, *, bold_lead=None, color=INK, after=6, italic=False):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(after)
    p.paragraph_format.line_spacing = 1.10
    if bold_lead and text.startswith(bold_lead):
        r1 = p.add_run(bold_lead)
        set_run_font(r1, bold=True, color=color)
        r2 = p.add_run(text[len(bold_lead):])
        set_run_font(r2, color=color, italic=italic)
    else:
        r = p.add_run(text)
        set_run_font(r, color=color, italic=italic)
    return p


def add_callout(doc, label, message, *, fill=LIGHT_AMBER, accent=AMBER):
    table = doc.add_table(rows=1, cols=1)
    table.style = "Table Grid"
    set_table_geometry(table, [9360])
    cell = table.cell(0, 0)
    shade_cell(cell, fill)
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(2)
    r = p.add_run(label.upper())
    set_run_font(r, size=9, color=accent, bold=True)
    p2 = cell.add_paragraph()
    p2.paragraph_format.space_after = Pt(0)
    p2.paragraph_format.line_spacing = 1.08
    r2 = p2.add_run(message)
    set_run_font(r2, size=11, color=NAVY, bold=True)
    doc.add_paragraph().paragraph_format.space_after = Pt(1)


def add_page_field(paragraph):
    run = paragraph.add_run()
    fld_char = OxmlElement("w:fldChar")
    fld_char.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = " PAGE "
    fld_sep = OxmlElement("w:fldChar")
    fld_sep.set(qn("w:fldCharType"), "separate")
    fld_text = OxmlElement("w:t")
    fld_text.text = "1"
    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    run._r.extend([fld_char, instr, fld_sep, fld_text, fld_end])
    set_run_font(run, size=9, color=MUTED)


def configure_header_footer(section):
    for header in (section.header, section.even_page_header, section.first_page_header):
        p = header.paragraphs[0]
        p.text = ""
        p.paragraph_format.space_after = Pt(0)

    for footer in (section.footer, section.even_page_footer, section.first_page_footer):
        p = footer.paragraphs[0]
        p.text = ""
        p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        p.paragraph_format.space_before = Pt(0)
        r = p.add_run("GreatPlainsMerge  |  Page ")
        set_run_font(r, size=9, color=MUTED)
        add_page_field(p)


def set_image_alt(inline_shape, title, description):
    doc_pr = inline_shape._inline.docPr
    doc_pr.set("title", title)
    doc_pr.set("descr", description)


def add_figure(doc, image_path, caption, alt_text, width=6.45):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.keep_with_next = True
    shape = p.add_run().add_picture(str(image_path), width=Inches(width))
    set_image_alt(shape, caption, alt_text)
    cap = doc.add_paragraph()
    cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cap.paragraph_format.space_before = Pt(2)
    cap.paragraph_format.space_after = Pt(8)
    cap.paragraph_format.keep_with_next = True
    r = cap.add_run(caption)
    set_run_font(r, size=9, color=MUTED, italic=True)


def load_font(size, bold=False):
    filename = "arialbd.ttf" if bold else "arial.ttf"
    return ImageFont.truetype(str(Path("C:/Windows/Fonts") / filename), size)


def rounded(draw, box, fill, outline=GRID, radius=22, width=3):
    if isinstance(fill, str) and not fill.startswith("#"):
        fill = f"#{fill}"
    if isinstance(outline, str) and not outline.startswith("#"):
        outline = f"#{outline}"
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_wrapped(draw, xy, text, font, fill, max_width, spacing=8, anchor=None):
    words = text.split()
    lines, line = [], ""
    for word in words:
        trial = word if not line else f"{line} {word}"
        if draw.textbbox((0, 0), trial, font=font)[2] <= max_width:
            line = trial
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    draw.multiline_text(xy, "\n".join(lines), font=font, fill=fill, spacing=spacing, anchor=anchor)
    return lines


def arrow(draw, start, end, color="#8A97A8", width=5):
    draw.line([start, end], fill=color, width=width)
    x2, y2 = end
    x1, y1 = start
    if abs(x2 - x1) >= abs(y2 - y1):
        direction = 1 if x2 > x1 else -1
        pts = [(x2, y2), (x2 - 16 * direction, y2 - 10), (x2 - 16 * direction, y2 + 10)]
    else:
        direction = 1 if y2 > y1 else -1
        pts = [(x2, y2), (x2 - 10, y2 - 16 * direction), (x2 + 10, y2 - 16 * direction)]
    draw.polygon(pts, fill=color)


def create_figma_board(path):
    width, height = 1800, 1120
    img = Image.new("RGB", (width, height), "#F7F9FC")
    d = ImageDraw.Draw(img)
    title = load_font(46, True)
    subtitle = load_font(25)
    h = load_font(27, True)
    body = load_font(22)
    small = load_font(18)
    chip = load_font(17, True)

    d.text((70, 55), "Trouble Ticket Story | Architect Review Board", font=title, fill="#0B2545")
    d.text((72, 118), "GreatPlainsMerge - read-only dry-run evidence", font=subtitle, fill="#5B6777")
    d.rounded_rectangle((1440, 58, 1718, 112), radius=24, fill="#FFF1D6")
    d.text((1579, 85), "CONDITIONAL", font=chip, fill="#9A6500", anchor="mm")

    # Main columns
    rounded(d, (70, 195, 520, 785), "#FFFFFF")
    rounded(d, (675, 195, 1125, 785), "#FFFFFF")
    rounded(d, (1280, 195, 1730, 785), "#FFFFFF")
    d.text((100, 225), "1  Actor & access", font=h, fill="#2E74B5")
    d.text((705, 225), "2  Case configuration", font=h, fill="#2E74B5")
    d.text((1310, 225), "3  Dependency chain", font=h, fill="#2E74B5")

    # Left column nodes
    rounded(d, (105, 305, 485, 420), "#EAF2FA", outline="#A6C7E8", radius=18)
    d.text((135, 330), "NOC user", font=h, fill="#0B2545")
    d.text((135, 375), "Business acceptance persona", font=small, fill="#5B6777")
    rounded(d, (105, 475, 485, 610), "#FFFFFF", outline="#A6C7E8", radius=18)
    d.text((135, 500), "Profile + permissions", font=h, fill="#0B2545")
    draw_wrapped(d, (135, 548), "Dedicated layout assigned to only 3 of 32 profiles", body, "#5B6777", 320)
    rounded(d, (105, 660, 485, 744), "#FDECEC", outline="#E5A6A6", radius=18)
    d.text((135, 684), "Review: Priority FLS", font=h, fill="#C53030")

    # Center nodes
    rounded(d, (710, 305, 1090, 405), "#E7F5F1", outline="#85C8B5", radius=18)
    d.text((740, 330), "Record type", font=h, fill="#0B2545")
    d.text((740, 370), "Trouble Ticket - active/default", font=small, fill="#16836B")
    rounded(d, (710, 455, 1090, 595), "#EAF2FA", outline="#A6C7E8", radius=18)
    d.text((740, 480), "Trouble Ticket layout", font=h, fill="#0B2545")
    draw_wrapped(d, (740, 526), "Critical Dates + Resolution Details + Field Technician Context", body, "#5B6777", 320)
    rounded(d, (710, 645, 1090, 744), "#FFF6DE", outline="#E6C979", radius=18)
    d.text((740, 670), "Extra fields/sections", font=h, fill="#9A6500")
    d.text((740, 712), "Confirm design intent", font=small, fill="#7A5A00")

    # Right chain nodes
    chain_nodes = [
        (305, "Service Type", "7 values"),
        (475, "Subscriber Report", "63 record-type values"),
        (645, "Primary Resolution", "58 record-type values"),
    ]
    for y, label, detail in chain_nodes:
        rounded(d, (1315, y, 1695, y + 105), "#FFFFFF", outline="#A6C7E8", radius=18)
        d.text((1345, y + 22), label, font=h, fill="#0B2545")
        d.text((1345, y + 66), detail, font=small, fill="#5B6777")
    arrow(d, (1505, 410), (1505, 470), color="#2E74B5")
    arrow(d, (1505, 580), (1505, 640), color="#2E74B5")
    d.rounded_rectangle((1574, 431, 1710, 469), radius=18, fill="#FDECEC")
    d.text((1642, 450), "0 for Fixed Wireless", font=chip, fill="#C53030", anchor="mm")

    arrow(d, (520, 490), (675, 490), color="#8A97A8")
    arrow(d, (1125, 490), (1280, 490), color="#8A97A8")

    # Approval gate lane
    rounded(d, (70, 850, 1730, 1045), "#0B2545", outline="#0B2545", radius=24)
    d.text((105, 880), "Approval gates", font=h, fill="#FFFFFF")
    gates = [
        (105, "1", "Identify NOC profile", "Verify access/layout"),
        (505, "2", "Fix Priority FLS", "Low / Med / High"),
        (905, "3", "Map Fixed Wireless", "Subscriber Report"),
        (1305, "4", "Compare workbook", "Exact matrix evidence"),
    ]
    for x, n, label, detail in gates:
        d.ellipse((x, 940, x + 46, 986), fill="#2E74B5")
        d.text((x + 23, 963), n, font=chip, fill="#FFFFFF", anchor="mm")
        d.text((x + 62, 936), label, font=body, fill="#FFFFFF")
        d.text((x + 62, 974), detail, font=small, fill="#B9C9DA")

    img.save(path, dpi=(220, 220))


def class_box(d, box, title, rows, header_fill="#EAF2FA", outline="#8FB7DC"):
    x1, y1, x2, y2 = box
    rounded(d, box, "#FFFFFF", outline=outline, radius=18, width=3)
    d.rounded_rectangle((x1, y1, x2, y1 + 64), radius=18, fill=header_fill, outline=outline, width=3)
    d.rectangle((x1, y1 + 42, x2, y1 + 64), fill=header_fill)
    d.text((x1 + 24, y1 + 19), title, font=load_font(24, True), fill="#0B2545")
    y = y1 + 82
    for row in rows:
        d.text((x1 + 24, y), row, font=load_font(18), fill="#3D4A5A")
        y += 31


def create_class_diagram(path):
    width, height = 1800, 1280
    img = Image.new("RGB", (width, height), "#FFFFFF")
    d = ImageDraw.Draw(img)
    d.text((65, 45), "Trouble Ticket Configuration Model", font=load_font(42, True), fill="#0B2545")
    d.text((67, 105), "UML-style class diagram - configuration, access, and dependent values", font=load_font(23), fill="#5B6777")

    boxes = {
        "user": (70, 210, 410, 390),
        "profile": (520, 210, 900, 420),
        "record": (1010, 210, 1390, 420),
        "layout": (1420, 210, 1760, 450),
        "case": (710, 545, 1090, 820),
        "service": (80, 925, 430, 1115),
        "subscriber": (540, 925, 920, 1145),
        "primary": (1030, 925, 1410, 1145),
        "workbook": (1450, 925, 1760, 1145),
    }

    # connectors first
    arrow(d, (410, 300), (520, 300), color="#2E74B5")
    d.text((432, 270), "assigned", font=load_font(16), fill="#5B6777")
    arrow(d, (900, 315), (1010, 315), color="#2E74B5")
    d.text((920, 285), "can use", font=load_font(16), fill="#5B6777")
    arrow(d, (1390, 315), (1420, 315), color="#2E74B5")
    arrow(d, (1200, 420), (1060, 545), color="#2E74B5")
    arrow(d, (1590, 450), (1090, 655), color="#2E74B5")
    arrow(d, (905, 820), (255, 925), color="#2E74B5")
    arrow(d, (430, 1020), (540, 1020), color="#2E74B5")
    d.text((448, 990), "controls", font=load_font(16), fill="#5B6777")
    arrow(d, (920, 1020), (1030, 1020), color="#2E74B5")
    d.text((942, 990), "controls", font=load_font(16), fill="#5B6777")
    arrow(d, (1450, 1035), (1410, 1035), color="#B7791F")

    class_box(d, boxes["user"], "NOCUser", ["username", "businessPersona = NOC", "acceptanceTester"])
    class_box(d, boxes["profile"], "Profile", ["recordTypeVisibility", "layoutAssignment", "fieldPermissions", "current: admin / standard"])
    class_box(d, boxes["record"], "CaseRecordType", ["name = Trouble Ticket", "active = true", "defaultForCurrentUser = true"])
    class_box(d, boxes["layout"], "PageLayout", ["name = Trouble Ticket", "Critical Dates", "Resolution Details", "Field Technician Context"])
    class_box(d, boxes["case"], "Case", ["RecordTypeId", "Service_Type__c", "Subscriber_Report__c", "Primary_Resolution__c", "Priority__c", "critical date fields"], header_fill="#E7F5F1", outline="#72B9A4")
    class_box(d, boxes["service"], "ServiceType", ["7 values", "Fixed Wireless: mapped to 0"], header_fill="#FFF6DE", outline="#D9B95C")
    class_box(d, boxes["subscriber"], "SubscriberReport", ["controlled by Service Type", "64 active globally", "63 on Trouble Ticket", "LOCATE excluded"])
    class_box(d, boxes["primary"], "PrimaryResolution", ["controlled by Subscriber Report", "61 active globally", "58 on Trouble Ticket", "all available controllers mapped"])
    class_box(d, boxes["workbook"], "MappingWorkbook", ["source of truth", "not attached", "exact parity unverified"], header_fill="#FDECEC", outline="#E09A9A")

    # risk callout
    rounded(d, (70, 1190, 1760, 1250), "#FDECEC", outline="#E09A9A", radius=16)
    d.text((95, 1207), "Review required: Priority__c has no field permission; NOC profile is not identifiable; spreadsheet parity remains unproven.", font=load_font(21, True), fill="#A12626")
    img.save(path, dpi=(220, 220))


def build_document():
    figma_path = ASSET_DIR / "figma-style-architect-board.png"
    class_path = ASSET_DIR / "trouble-ticket-class-diagram.png"
    create_figma_board(figma_path)
    create_class_diagram(class_path)

    doc = Document()
    doc.settings.odd_and_even_pages_header_footer = True
    section = doc.sections[0]
    section.top_margin = Inches(1.0)
    section.bottom_margin = Inches(1.0)
    section.left_margin = Inches(1.0)
    section.right_margin = Inches(1.0)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)
    section.different_first_page_header_footer = True
    configure_header_footer(section)

    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Arial"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
    normal.font.size = Pt(11)
    normal.font.color.rgb = rgb(INK)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.10

    for style_name, size, color, before, after in (
        ("Heading 1", 16, BLUE, 12, 6),
        ("Heading 2", 13, BLUE, 10, 5),
        ("Heading 3", 12, NAVY, 8, 4),
    ):
        st = styles[style_name]
        st.font.name = "Arial"
        st._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
        st._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
        st.font.size = Pt(size)
        st.font.bold = True
        st.font.color.rgb = rgb(color)
        st.paragraph_format.space_before = Pt(before)
        st.paragraph_format.space_after = Pt(after)
        st.paragraph_format.keep_with_next = True

    # Page 1 - decision memo masthead
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(2)
    r = p.add_run("ARCHITECT REVIEW")
    set_run_font(r, size=10, color=BLUE, bold=True)

    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(4)
    r = p.add_run("Trouble Ticket Story")
    set_run_font(r, size=26, color=NAVY, bold=True)

    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(16)
    r = p.add_run("Great Plains Merge Sandbox | Read-only dry-run and readiness assessment")
    set_run_font(r, size=13, color=MUTED)

    metadata = [
        ("Environment", "GreatPlainsMerge (Sandbox)"),
        ("Role", "Solution Architect review"),
        ("Assessment date", "26 August 2026"),
        ("Decision", "Conditional approval - changes requested"),
        ("Boundary", "No record creation, deployment, activation, or metadata changes"),
    ]
    meta = doc.add_table(rows=len(metadata), cols=2)
    meta.style = "Table Grid"
    set_table_geometry(meta, [1900, 7460])
    for row, (label, value) in zip(meta.rows, metadata):
        shade_cell(row.cells[0], LIGHT_BLUE)
        set_cell_text(row.cells[0], label, size=9.5, color=NAVY, bold=True)
        set_cell_text(row.cells[1], value, size=9.5)
    doc.add_paragraph().paragraph_format.space_after = Pt(2)

    add_callout(
        doc,
        "Architect decision",
        "Do not promote yet. The core configuration is present, but user-access, Priority field security, Fixed Wireless mapping, and spreadsheet parity require closure.",
    )

    add_heading(doc, "Acceptance test outcome", 1)
    test_rows = [
        ("1", "Trouble Ticket record type", "Pass - current admin", "Active, available, default, and mapped to the dedicated layout for the connected administrator."),
        ("2", "Layout and required fields", "Partial pass", "Requested fields exist, but Priority__c is hidden and the layout contains additional unrequested sections/fields."),
        ("3", "Dependent picklists", "Partial fail", "Both chains exist; Fixed Wireless has zero Subscriber Report choices and exact workbook parity is unverified."),
    ]
    add_table(doc, ["TC", "Scope", "Result", "Evidence"], test_rows, [650, 2400, 1750, 4560], status_column=2)

    add_heading(doc, "Approval position", 2)
    add_body(doc, "Recommended status: Changes Requested / Conditional Approval.", bold_lead="Recommended status:")
    add_body(doc, "The implementation is structurally close, but an architect sign-off should wait until the four approval gates on page 5 are completed and evidenced.")

    # Page 2 - Figma-style visual
    doc.add_page_break()
    add_heading(doc, "Solution overview", 1)
    add_body(doc, "This board shows how the intended NOC user reaches the Trouble Ticket experience and where the current review gates sit.")
    add_figure(
        doc,
        figma_path,
        "Figure 1. Figma-style architect review board",
        "Diagram showing NOC user access through profiles into the Trouble Ticket Case record type and layout, followed by Service Type, Subscriber Report, and Primary Resolution dependencies. Four approval gates are highlighted: NOC profile, Priority field security, Fixed Wireless mapping, and workbook comparison.",
    )
    add_callout(doc, "Design reading", "Green/blue items are configured. Amber and red items require confirmation or correction before promotion.", fill=LIGHT_BLUE, accent=BLUE)

    # Page 3 - detailed findings
    doc.add_page_break()
    add_heading(doc, "Detailed architect findings", 1)
    add_heading(doc, "1. Record type and access", 2)
    access_rows = [
        ("Record type", "Trouble Ticket", "Active; record type ID 012Ea000007eNrVIAU."),
        ("Connected user", "System Administrator", "Trouble Ticket is available and the default Case record type."),
        ("Dedicated layout", "3 profiles", "System Administrator, System Administrator - API Only, and Standard User."),
        ("Default Case layout", "29 profiles", "These profiles do not receive the dedicated Trouble Ticket layout assignment."),
        ("NOC persona", "Not identified", "No active profile/user was discoverable by NOC name, department, or title."),
    ]
    add_table(doc, ["Item", "Observed", "Architect interpretation"], access_rows, [2200, 1800, 5360])

    add_heading(doc, "2. Layout coverage", 2)
    layout_rows = [
        ("Critical Dates", "Pass with additions", "Problem Occurred, Problem Reported, Repair, Created, and Closed Date are present. Created By and MTTR are additional."),
        ("Resolution fields", "Pass", "Primary Resolution, Secondary Resolution, and Resolution Detail are grouped under Resolution Details."),
        ("Service context", "Pass", "Service Type, Service Address, Subscriber Report, Parent Case, and standard Priority are placed on the layout."),
        ("Extra section", "Review", "Field Technician Context was added although it is outside the stated test cases."),
        ("Priority ambiguity", "Changes requested", "Custom Priority__c has Low/Med/High but no field permission. Standard Priority remains visible with High/Medium/Low."),
    ]
    add_table(doc, ["Area", "Result", "Evidence"], layout_rows, [2200, 1900, 5260], status_column=1)

    add_heading(doc, "3. Dependency evidence", 2)
    dependency_rows = [
        ("Service Type -> Subscriber Report", "Configured", "7 Service Types; 63 Subscriber Reports on Trouble Ticket; Fixed Wireless maps to zero."),
        ("Subscriber Report -> Primary Resolution", "Configured", "All available Subscriber Report controllers have at least one Primary Resolution."),
        ("Record-type exclusions", "Review", "LOCATE is excluded from Subscriber Report. Three Primary Resolution values are excluded."),
        ("Excel parity", "Blocked", "The referenced Subscriber Reports NISC workbook was not attached or directly accessible."),
    ]
    add_table(doc, ["Relationship", "Status", "Evidence"], dependency_rows, [2850, 1600, 4910], status_column=1)

    # Page 4 - class/config diagram
    doc.add_page_break()
    add_heading(doc, "Configuration class diagram", 1)
    add_body(doc, "The diagram separates user access, Salesforce configuration, record data, and the external mapping source so ownership is clear.")
    add_figure(
        doc,
        class_path,
        "Figure 2. Trouble Ticket configuration and dependency class diagram",
        "UML-style diagram relating NOCUser, Profile, CaseRecordType, PageLayout, Case, ServiceType, SubscriberReport, PrimaryResolution, and MappingWorkbook. It highlights access assignments and dependent-picklist relationships.",
    )
    add_body(doc, "Architect interpretation: the Salesforce configuration objects are connected correctly for the current administrator, but the business-persona access model and workbook-driven value parity are not yet proven.", bold_lead="Architect interpretation:")

    # Page 5 - gates and ready-to-paste response
    doc.add_page_break()
    add_heading(doc, "Required approval gates", 1)
    gate_rows = [
        ("1", "Identify the NOC test user/profile", "Product owner / Salesforce admin", "Provide the username and prove record type, layout, and field visibility."),
        ("2", "Resolve Priority field design", "Salesforce admin / Architect", "Choose standard Priority or custom Priority__c; add field-level access if custom is retained."),
        ("3", "Resolve Fixed Wireless mapping", "Business analyst / Admin", "Add Subscriber Report values or document that an empty list is intentional."),
        ("4", "Validate Excel parity", "Business analyst / QA", "Attach the workbook and compare every Service Type, Subscriber Report, and Primary Resolution mapping."),
        ("5", "Confirm layout additions", "Product owner / Architect", "Approve or remove Created By, MTTR, Resolution Details, and Field Technician Context deviations."),
    ]
    add_table(doc, ["Gate", "Required action", "Owner", "Evidence needed"], gate_rows, [900, 2700, 2250, 3510])

    add_heading(doc, "Ready-to-paste architect response", 1)
    reply = (
        "Architect review completed in the GreatPlainsMerge sandbox. The core Trouble Ticket configuration is present, including the active record type, dedicated layout, Critical Dates fields, and both dependent-picklist relationships. Approval remains conditional. Please confirm the intended NOC user/profile assignment, resolve field-level access and usage for the Low/Med/High Priority field, resolve or confirm the empty Fixed Wireless Subscriber Report mapping, provide the Excel workbook for exact dependency validation, and confirm that the additional MTTR, Created By, Resolution Details, and Field Technician Context items are intentional. No records, metadata, activation, or deployment changes were made during this review."
    )
    add_callout(doc, "Story comment", reply, fill=LIGHT_BLUE, accent=BLUE)

    add_heading(doc, "Evidence boundary", 2)
    add_body(doc, "This report is a live, read-only configuration review of GreatPlainsMerge as observed on 26 August 2026. It is not a deployment validation, because no local change package or check-only deployment was supplied.")

    doc.core_properties.title = "Great Plains Trouble Ticket Architect Review"
    doc.core_properties.subject = "Read-only dry-run and readiness assessment"
    doc.core_properties.author = "Solution Architecture Review"
    doc.core_properties.keywords = "Salesforce, Great Plains, Trouble Ticket, architect review, dry run"

    doc.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build_document()
