from pathlib import Path

from docx import Document
from docx.enum.table import WD_ALIGN_VERTICAL
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.opc.constants import RELATIONSHIP_TYPE as RT
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[2]
OUT_PATH = (
    ROOT
    / "outputs"
    / "ge_cpc_parts_shipped_prod_handoff"
    / "GE_CPC_Parts_Shipped_Production_AutoFast_Handoff.docx"
)

BLUE = RGBColor(46, 116, 181)
DARK_BLUE = RGBColor(31, 77, 120)
NAVY = RGBColor(11, 37, 69)
GRAY = RGBColor(85, 85, 85)
MUTED = RGBColor(100, 111, 124)
BLACK = RGBColor(0, 0, 0)
GREEN = RGBColor(35, 100, 55)
RED = RGBColor(155, 28, 28)
GOLD = RGBColor(122, 90, 0)

TABLE_WIDTH = 9360
TABLE_INDENT = 120


def set_run_font(run, name="Calibri", size=None, color=None, bold=None, italic=None):
    run.font.name = name
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.rFonts
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    rfonts.set(qn("w:ascii"), name)
    rfonts.set(qn("w:hAnsi"), name)
    if size is not None:
        run.font.size = Pt(size)
    if color is not None:
        run.font.color.rgb = color
    if bold is not None:
        run.bold = bold
    if italic is not None:
        run.italic = italic


def set_paragraph_spacing(paragraph, before=0, after=6, line=1.25):
    paragraph.paragraph_format.space_before = Pt(before)
    paragraph.paragraph_format.space_after = Pt(after)
    paragraph.paragraph_format.line_spacing = line


def set_style_font(style, size, color=BLACK, bold=False, before=0, after=6, line=1.25):
    style.font.name = "Calibri"
    style.font.size = Pt(size)
    style.font.color.rgb = color
    style.font.bold = bold
    style.paragraph_format.space_before = Pt(before)
    style.paragraph_format.space_after = Pt(after)
    style.paragraph_format.line_spacing = line
    rpr = style.element.get_or_add_rPr()
    rfonts = rpr.rFonts
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    rfonts.set(qn("w:ascii"), "Calibri")
    rfonts.set(qn("w:hAnsi"), "Calibri")


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=80, bottom=80, start=120, end=120):
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_mar = tc_pr.find(qn("w:tcMar"))
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for margin_name, value in (("top", top), ("bottom", bottom), ("start", start), ("end", end)):
        node = tc_mar.find(qn(f"w:{margin_name}"))
        if node is None:
            node = OxmlElement(f"w:{margin_name}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_table_borders(table, color="D7DBE2", size="6"):
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.find(qn("w:tblBorders"))
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        node = borders.find(qn(f"w:{edge}"))
        if node is None:
            node = OxmlElement(f"w:{edge}")
            borders.append(node)
        node.set(qn("w:val"), "single")
        node.set(qn("w:sz"), size)
        node.set(qn("w:space"), "0")
        node.set(qn("w:color"), color)


def set_table_widths(table, widths_dxa, indent_dxa=TABLE_INDENT):
    table.autofit = False
    tbl = table._tbl
    tbl_pr = tbl.tblPr

    tbl_w = tbl_pr.find(qn("w:tblW"))
    if tbl_w is None:
        tbl_w = OxmlElement("w:tblW")
        tbl_pr.append(tbl_w)
    tbl_w.set(qn("w:w"), str(sum(widths_dxa)))
    tbl_w.set(qn("w:type"), "dxa")

    tbl_ind = tbl_pr.find(qn("w:tblInd"))
    if tbl_ind is None:
        tbl_ind = OxmlElement("w:tblInd")
        tbl_pr.append(tbl_ind)
    tbl_ind.set(qn("w:w"), str(indent_dxa))
    tbl_ind.set(qn("w:type"), "dxa")

    grid = tbl.tblGrid
    if grid is None:
        grid = OxmlElement("w:tblGrid")
        tbl.insert(0, grid)
    for child in list(grid):
        grid.remove(child)
    for width in widths_dxa:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)

    for row in table.rows:
        for idx, cell in enumerate(row.cells):
            width = widths_dxa[idx]
            cell.width = Inches(width / 1440)
            tc_pr = cell._tc.get_or_add_tcPr()
            tc_w = tc_pr.find(qn("w:tcW"))
            if tc_w is None:
                tc_w = OxmlElement("w:tcW")
                tc_pr.append(tc_w)
            tc_w.set(qn("w:w"), str(width))
            tc_w.set(qn("w:type"), "dxa")
            set_cell_margins(cell)


def repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    existing = tr_pr.find(qn("w:tblHeader"))
    if existing is None:
        tbl_header = OxmlElement("w:tblHeader")
        tbl_header.set(qn("w:val"), "true")
        tr_pr.append(tbl_header)


def shade_paragraph(paragraph, fill="F4F6F9", border_color="D7DBE2"):
    p_pr = paragraph._p.get_or_add_pPr()
    shd = p_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        p_pr.append(shd)
    shd.set(qn("w:fill"), fill)
    borders = p_pr.find(qn("w:pBdr"))
    if borders is None:
        borders = OxmlElement("w:pBdr")
        p_pr.append(borders)
    for edge in ("top", "left", "bottom", "right"):
        node = borders.find(qn(f"w:{edge}"))
        if node is None:
            node = OxmlElement(f"w:{edge}")
            borders.append(node)
        node.set(qn("w:val"), "single")
        node.set(qn("w:sz"), "4")
        node.set(qn("w:space"), "3")
        node.set(qn("w:color"), border_color)


def add_hyperlink(paragraph, text, url):
    part = paragraph.part
    r_id = part.relate_to(url, RT.HYPERLINK, is_external=True)
    hyperlink = OxmlElement("w:hyperlink")
    hyperlink.set(qn("r:id"), r_id)

    new_run = OxmlElement("w:r")
    r_pr = OxmlElement("w:rPr")
    r_fonts = OxmlElement("w:rFonts")
    r_fonts.set(qn("w:ascii"), "Calibri")
    r_fonts.set(qn("w:hAnsi"), "Calibri")
    r_pr.append(r_fonts)
    color = OxmlElement("w:color")
    color.set(qn("w:val"), "0563C1")
    r_pr.append(color)
    underline = OxmlElement("w:u")
    underline.set(qn("w:val"), "single")
    r_pr.append(underline)
    new_run.append(r_pr)

    text_node = OxmlElement("w:t")
    text_node.text = text
    new_run.append(text_node)
    hyperlink.append(new_run)
    paragraph._p.append(hyperlink)


def add_page_number(paragraph):
    run = paragraph.add_run()
    fld_begin = OxmlElement("w:fldChar")
    fld_begin.set(qn("w:fldCharType"), "begin")
    run._r.append(fld_begin)
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = " PAGE "
    run._r.append(instr)
    fld_sep = OxmlElement("w:fldChar")
    fld_sep.set(qn("w:fldCharType"), "separate")
    run._r.append(fld_sep)
    text = OxmlElement("w:t")
    text.text = "1"
    run._r.append(text)
    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    run._r.append(fld_end)


def clear_paragraph(paragraph):
    for run in list(paragraph.runs):
        paragraph._p.remove(run._r)


def configure_document(doc):
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(1)
    section.right_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)

    styles = doc.styles
    set_style_font(styles["Normal"], 11, BLACK, before=0, after=6, line=1.25)
    set_style_font(styles["Title"], 24, NAVY, bold=True, before=0, after=4, line=1.10)
    set_style_font(styles["Subtitle"], 12.5, GRAY, before=0, after=14, line=1.15)
    set_style_font(styles["Heading 1"], 16, BLUE, bold=True, before=18, after=10, line=1.25)
    set_style_font(styles["Heading 2"], 13, BLUE, bold=True, before=14, after=7, line=1.25)
    set_style_font(styles["Heading 3"], 12, DARK_BLUE, bold=True, before=10, after=5, line=1.25)

    header = section.header
    header.is_linked_to_previous = False
    header_p = header.paragraphs[0]
    clear_paragraph(header_p)
    header_p.paragraph_format.space_after = Pt(0)
    header_p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    header_p.paragraph_format.tab_stops.add_tab_stop(Inches(6.5))
    left = header_p.add_run("PROBO MEDICAL | SALESFORCE")
    set_run_font(left, size=8.5, color=MUTED, bold=True)
    right = header_p.add_run("\tGE CPC REPORT | PRODUCTION HANDOFF")
    set_run_font(right, size=8.5, color=MUTED, bold=True)

    footer = section.footer
    footer.is_linked_to_previous = False
    footer_p = footer.paragraphs[0]
    clear_paragraph(footer_p)
    footer_p.paragraph_format.space_before = Pt(0)
    footer_p.paragraph_format.space_after = Pt(0)
    footer_p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    footer_p.paragraph_format.tab_stops.add_tab_stop(Inches(6.5))
    run = footer_p.add_run("Prepared for David | GE CPC Parts Shipped")
    set_run_font(run, size=8.5, color=MUTED)
    run = footer_p.add_run("\tPage ")
    set_run_font(run, size=8.5, color=MUTED)
    add_page_number(footer_p)


def add_para(doc, text="", size=11, color=BLACK, bold=False, italic=False, after=6, before=0):
    p = doc.add_paragraph()
    set_paragraph_spacing(p, before=before, after=after, line=1.25)
    if text:
        run = p.add_run(text)
        set_run_font(run, size=size, color=color, bold=bold, italic=italic)
    return p


def add_labeled_para(doc, label, value):
    p = doc.add_paragraph()
    set_paragraph_spacing(p, after=6, line=1.25)
    label_run = p.add_run(f"{label}: ")
    set_run_font(label_run, size=11, color=DARK_BLUE, bold=True)
    value_run = p.add_run(value)
    set_run_font(value_run, size=11, color=BLACK)
    return p


def add_callout(doc, title, body, fill="F4F6F9", title_color=NAVY):
    p = doc.add_paragraph()
    set_paragraph_spacing(p, before=2, after=8, line=1.25)
    shade_paragraph(p, fill=fill)
    run = p.add_run(f"{title}: ")
    set_run_font(run, size=11, color=title_color, bold=True)
    body_run = p.add_run(body)
    set_run_font(body_run, size=11, color=BLACK)
    return p


def set_cell_text(cell, text, bold=False, color=BLACK, size=10.2, align=None):
    cell.text = ""
    p = cell.paragraphs[0]
    set_paragraph_spacing(p, before=0, after=0, line=1.15)
    if align is not None:
        p.alignment = align
    run = p.add_run(str(text))
    set_run_font(run, size=size, color=color, bold=bold)
    cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER


def add_table(doc, headers, rows, widths, status_col=None):
    table = doc.add_table(rows=1, cols=len(headers))
    set_table_widths(table, widths)
    set_table_borders(table)
    repeat_table_header(table.rows[0])
    for idx, header in enumerate(headers):
        cell = table.rows[0].cells[idx]
        set_cell_shading(cell, "E8EEF5")
        set_cell_text(cell, header, bold=True, color=DARK_BLUE, size=9.8)
    for row_data in rows:
        row = table.add_row()
        for idx, value in enumerate(row_data):
            cell = row.cells[idx]
            value_color = BLACK
            if status_col is not None and idx == status_col:
                upper = str(value).upper()
                if "SUCCEEDED" in upper or "PASSED" in upper or "COMPLETE" in upper:
                    value_color = GREEN
                elif "NOT FOUND" in upper or "PENDING" in upper:
                    value_color = GOLD
                elif "FAILED" in upper or "ERROR" in upper:
                    value_color = RED
            set_cell_text(cell, value, color=value_color, size=9.8)
    add_para(doc, "", after=4)
    return table


def add_metadata_table(doc, rows):
    return add_table(doc, ["Field", "Value"], rows, [2400, 6960])


def add_links_table(doc):
    table = doc.add_table(rows=1, cols=4)
    widths = [1300, 3000, 1600, 3460]
    set_table_widths(table, widths)
    set_table_borders(table)
    repeat_table_header(table.rows[0])
    headers = ["Environment", "Clickable link", "Report ID", "Notes"]
    for idx, header in enumerate(headers):
        cell = table.rows[0].cells[idx]
        set_cell_shading(cell, "E8EEF5")
        set_cell_text(cell, header, bold=True, color=DARK_BLUE, size=9.8)

    rows = [
        (
            "Production",
            "Open Production report",
            "00OjR0000002cHJUAY",
            "Final deployed report in Probo Medical Production.",
            "https://probomedical.my.salesforce.com/lightning/r/Report/00OjR0000002cHJUAY/view",
        ),
        (
            "UAT",
            "Open UAT report",
            "00OjH0000000ZXFUA2",
            "UAT deployment and business test target.",
            "https://probomedical--uat.sandbox.my.salesforce.com/lightning/r/Report/00OjH0000000ZXFUA2/view",
        ),
        (
            "DevDO",
            "Open DevDO report",
            "00OiK0000000k9JUAQ",
            "Original build sandbox; expected low/no data.",
            "https://probomedical--devdo.sandbox.my.salesforce.com/lightning/r/Report/00OiK0000000k9JUAQ/view",
        ),
    ]
    for env, text, rid, notes, url in rows:
        row = table.add_row()
        set_cell_text(row.cells[0], env, bold=env == "Production", size=9.8)
        row.cells[1].text = ""
        p = row.cells[1].paragraphs[0]
        set_paragraph_spacing(p, before=0, after=0, line=1.15)
        add_hyperlink(p, text, url)
        row.cells[1].vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        set_cell_text(row.cells[2], rid, size=9.8)
        set_cell_text(row.cells[3], notes, size=9.8)
    add_para(doc, "", after=4)
    return table


def add_ready_message(doc):
    doc.add_paragraph("8. Ready-to-send note for David", style="Heading 1")
    p = doc.add_paragraph()
    set_paragraph_spacing(p, before=2, after=4, line=1.25)
    shade_paragraph(p, fill="F4F6F9")
    r = p.add_run("David, the GE CPC Parts Shipped report has been built in DevDO, validated/deployed to UAT, and then validated and deployed to Production after approval. ")
    set_run_font(r, size=10.8, color=BLACK)
    r = p.add_run("Production report: ")
    set_run_font(r, size=10.8, color=BLACK, bold=True)
    add_hyperlink(p, "Open GE CPC Parts Shipped in Production", "https://probomedical.my.salesforce.com/lightning/r/Report/00OjR0000002cHJUAY/view")
    r = p.add_run(". The Production deployment created one Report metadata component only: Service_Operations_Reports/GE_CPC_Parts_Shipped. No data, Apex, Flow, objects, fields, permissions, or other setup were changed. I did not find an official user-story number in the supplied GE CPC files or local artifacts, so I used 'GE CPC Parts Shipped Report' as the working story reference. The six 302808xxx values are GE PO/opportunity references, not a story number. Remaining business checks are to confirm the report rows/totals and decide whether any data cleanup is needed for missing cost or serial values.")
    set_run_font(r, size=10.8, color=BLACK)


def build_doc():
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    doc = Document()
    configure_document(doc)

    doc.core_properties.title = "GE CPC Parts Shipped Production AutoFast Handoff"
    doc.core_properties.subject = "Salesforce report deployment summary for GE CPC Parts Shipped"
    doc.core_properties.author = "Probo Medical Salesforce Team"
    doc.core_properties.keywords = "Salesforce, Probo Medical, GE CPC, report, DevDO, UAT, Production"

    kicker = doc.add_paragraph()
    set_paragraph_spacing(kicker, before=0, after=2, line=1.10)
    run = kicker.add_run("AUTOFAST HANDOFF RECORD")
    set_run_font(run, size=10, color=BLUE, bold=True)

    title = doc.add_paragraph("GE CPC Parts Shipped Report - Production Deployment", style="Title")
    title.alignment = WD_ALIGN_PARAGRAPH.LEFT
    subtitle = doc.add_paragraph("DevDO, UAT, and Production implementation summary with no images", style="Subtitle")
    subtitle.alignment = WD_ALIGN_PARAGRAPH.LEFT

    add_metadata_table(
        doc,
        [
            ("Prepared for", "David"),
            ("Prepared on", "September 4, 2026"),
            ("Final status", "COMPLETE - Production deployment succeeded"),
            ("Production report", "GE CPC Parts Shipped | Report ID 00OjR0000002cHJUAY"),
            ("Working story reference", "GE CPC Parts Shipped Report"),
            ("Official user story number", "Not found/provided in supplied files or local GE CPC artifacts"),
            ("Document format", "AutoFast-style Word handoff; text only; no screenshots or images"),
        ],
    )

    add_callout(
        doc,
        "Outcome",
        "The requested Salesforce report now exists in Production. The deployment added one Report metadata component only and did not alter production data, Apex, Flow, objects, fields, permissions, profiles, automation, or integrations.",
        fill="EEF6EE",
        title_color=GREEN,
    )

    doc.add_paragraph("1. What the story means", style="Heading 1")
    add_labeled_para(
        doc,
        "Business request",
        "Create a report that tracks parts shipped against the six GE CPC / Philips EPIQ opportunity references, including system serial, asset, part, quantity, and cost details.",
    )
    add_labeled_para(
        doc,
        "Functional scope",
        "Report metadata only. The work was not an Apex change, Flow change, object/field change, data load, user access change, or integration change.",
    )
    add_labeled_para(
        doc,
        "Where the work belonged",
        "Build and first verification were done in DevDO. UAT was used for dry-run validation and deployment. Production was used only after approval, with a check-only validation before the real deployment.",
    )
    add_labeled_para(
        doc,
        "Important story-number note",
        "No official Jira or user-story number was found in the GE CPC contract, system list, or local GE CPC artifacts. The six 302808xxx values are GE PO/opportunity references, not story numbers.",
    )

    doc.add_paragraph("2. Deployment path and evidence", style="Heading 1")
    add_table(
        doc,
        ["Environment / gate", "Evidence", "Result"],
        [
            ("DevDO build", "Report ID 00OiK0000000k9JUAQ in Service Operations Reports", "CREATED - report opened successfully; zero rows expected because CPC production data was not present in DevDO"),
            ("UAT dry run", "Validation job 0AfjH0000000RUrSAM", "PASSED - 1/1 component, 0 errors; dry run did not create the report"),
            ("UAT deployment", "Deployment job 0AfjH0000000RWTSA2; Report ID 00OjH0000000ZXFUA2", "SUCCEEDED - 1/1 Report component deployed; read-back found 13 columns, 3 filters, Current Fiscal Year date filter"),
            ("UAT data check", "Count-only filter check after UAT deployment", "90 matching Work Order Line Items at the time checked"),
            ("Production check-only", "Validation job 0AfjR0000000vzBSAQ", "PASSED - checkOnly=true; 1/1 component, 0 errors"),
            ("Production deployment", "Deployment job 0AfjR0000000w0nSAA; Report ID 00OjR0000002cHJUAY", "SUCCEEDED - checkOnly=false; one Report metadata component created"),
            ("Production read-back", "Report last modified 2026-09-03T17:51:50.000+0000", "CONFIRMED - 13 columns, 3 filters, Current Fiscal Year date filter, and 143 matching Work Order Line Items at deployment check"),
        ],
        [2200, 3600, 3560],
        status_col=2,
    )

    doc.add_paragraph("3. Production work completed", style="Heading 1")
    add_table(
        doc,
        ["Item", "Production result"],
        [
            ("Created component", "Report: Service_Operations_Reports/GE_CPC_Parts_Shipped"),
            ("Report label", "GE CPC Parts Shipped"),
            ("Report ID", "00OjR0000002cHJUAY"),
            ("Folder", "Service Operations Reports"),
            ("Report type", "Work Orders with Work Order Line items2 / Work_Orders_with_Work_Order_Line_items2__c"),
            ("Report format", "Tabular"),
            ("Deployment job", "0AfjR0000000w0nSAA"),
            ("Pre-deploy validation job", "0AfjR0000000vzBSAQ"),
        ],
        [2600, 6760],
    )

    add_callout(
        doc,
        "Production non-impact statement",
        "No production records were inserted, updated, or deleted. No code, tests, flows, field definitions, objects, permission sets, profiles, dashboards, subscriptions, sharing rules, or integrations were changed.",
        fill="FFF8E8",
        title_color=GOLD,
    )

    doc.add_paragraph("4. Report configuration", style="Heading 1")
    add_table(
        doc,
        ["Configuration", "Value"],
        [
            ("Description", "Tracks parts shipped against the six GE CPC opportunities by system serial, asset, part, quantity, and cost."),
            ("Currency", "USD"),
            ("Scope", "Organization"),
            ("Sort", "Work Order Opportunity ascending"),
            ("Date filter", "Work Order Ship Date = Current Fiscal Year"),
            ("Filter logic", "1 AND (2 OR 3)"),
            ("Filter 1", "Work Order Account contains GE PRECISION HEALTHCARE LLC"),
            ("Filter 2", "Work Order Opportunity contains CPC - PHILIPS EPIQ"),
            ("Filter 3", "Work Order Customer PO Number equals 302808083, 302808091, 302808107, 302808142, 302808182, 302808186"),
        ],
        [2300, 7060],
    )

    doc.add_paragraph("5. Report columns deployed", style="Heading 1")
    add_table(
        doc,
        ["Column", "Metadata field"],
        [
            ("Work Order", "WorkOrder$Name"),
            ("Opportunity", "WorkOrder$Opportunity__c"),
            ("Service Contract", "WorkOrder$ServiceContract"),
            ("Customer PO Number", "WorkOrder$Customer_PO_Number__c"),
            ("Ship Date", "WorkOrder$Ship_Date__c"),
            ("Asset Serial Number", "WorkOrder$Asset_Serial_Number__c"),
            ("Asset Number", "WorkOrder.WorkOrderLineItems$Asset_Number__c"),
            ("Part Number", "WorkOrder.WorkOrderLineItems$Part_Number__c"),
            ("Part Used Product Name", "WorkOrder.WorkOrderLineItems$Part_Used__c.Product_Name__c"),
            ("Description", "WorkOrder.WorkOrderLineItems$Description"),
            ("Quantity", "WorkOrder.WorkOrderLineItems$Quantity"),
            ("Part Used Cost", "WorkOrder.WorkOrderLineItems$Part_Used__c.Cost__c, summed"),
            ("Total Cost of Assets Used in Repair", "WorkOrder.WorkOrderLineItems$Part_Used__c.Total_Cost_of_Assets_Used_in_Repair__c, summed"),
        ],
        [3100, 6260],
    )

    doc.add_paragraph("6. Direct report links", style="Heading 1")
    add_links_table(doc)

    doc.add_paragraph("7. How to check in Production", style="Heading 1")
    add_table(
        doc,
        ["Step", "What to check", "Expected result"],
        [
            ("1", "Open the Production report link.", "Browser should show probomedical.my.salesforce.com, not a sandbox domain."),
            ("2", "Confirm the report title.", "Header should show GE CPC Parts Shipped."),
            ("3", "Open or review Filters.", "Filters should match GE PRECISION HEALTHCARE LLC, CPC - PHILIPS EPIQ, and the six 302808xxx PO values; date range should be Current Fiscal Year."),
            ("4", "Run/refresh the report.", "Rows should return for the GE CPC / Philips EPIQ shipped-parts population. Deployment-time count-only check found 143 matching Work Order Line Items; live counts can change."),
            ("5", "Review totals.", "Part Used Cost and Total Cost of Assets Used in Repair should summarize at the report level."),
            ("6", "Business review any blanks.", "Earlier read-only checks showed some missing cost and serial values. Revalidate current missing-count details before treating those as final cleanup numbers."),
        ],
        [800, 3600, 4960],
    )

    doc.add_paragraph("9. Remaining items", style="Heading 1")
    add_table(
        doc,
        ["Remaining item", "Owner / note"],
        [
            ("Official story number", "Ask David or Jira owner for the official user-story/ticket number; none was found in the provided GE CPC files."),
            ("Business sign-off", "David/business owner should open the Production report and confirm the rows, totals, and filter scope meet the requested CPC tracking need."),
            ("Data cleanup decision", "If serial- or cost-completeness is important, run a fresh data-quality pass and decide whether missing cost/serial values need cleanup."),
            ("Optional report access/subscription", "No subscription or additional folder-access change was made. Add only if David requests it."),
            ("Change-set note", "The deployed scope is one Report metadata component and can be represented in a UI Change Set, but the recorded deployment evidence is Salesforce metadata validation/deployment job evidence."),
        ],
        [2700, 6660],
    )

    add_ready_message(doc)

    OUT_PATH.unlink(missing_ok=True)
    doc.save(OUT_PATH)
    return OUT_PATH


if __name__ == "__main__":
    path = build_doc()
    print(path)
