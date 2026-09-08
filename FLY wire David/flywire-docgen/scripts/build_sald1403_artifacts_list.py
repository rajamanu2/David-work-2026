from pathlib import Path
from docx import Document
from docx.enum.section import WD_ORIENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.shared import Inches, Pt, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david\flywire-docgen")
OUT = ROOT / "deliverables" / "SALDEV-1403_Artifacts_Deployment_List.docx"

NAVY = "17365D"
BLUE = "2E74B5"
LIGHT_BLUE = "DCE6F1"
LIGHT_GRAY = "F2F4F7"
MID_GRAY = "6B7280"
WHITE = "FFFFFF"
BLACK = "111827"


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=100, start=110, bottom=100, end=110):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for tag, val in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{tag}"))
        if node is None:
            node = OxmlElement(f"w:{tag}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(val))
        node.set(qn("w:type"), "dxa")


def set_table_geometry(table, widths_dxa):
    table.autofit = False
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    tbl_pr = table._tbl.tblPr
    tbl_w = tbl_pr.first_child_found_in("w:tblW")
    tbl_w.set(qn("w:w"), str(sum(widths_dxa)))
    tbl_w.set(qn("w:type"), "dxa")
    tbl_ind = tbl_pr.first_child_found_in("w:tblInd")
    if tbl_ind is None:
        tbl_ind = OxmlElement("w:tblInd")
        tbl_pr.append(tbl_ind)
    tbl_ind.set(qn("w:w"), "110")
    tbl_ind.set(qn("w:type"), "dxa")
    grid = table._tbl.tblGrid
    for child in list(grid):
        grid.remove(child)
    for width in widths_dxa:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)
    for row in table.rows:
        for idx, cell in enumerate(row.cells):
            tc_pr = cell._tc.get_or_add_tcPr()
            tc_w = tc_pr.first_child_found_in("w:tcW")
            tc_w.set(qn("w:w"), str(widths_dxa[idx]))
            tc_w.set(qn("w:type"), "dxa")
            cell.width = Inches(widths_dxa[idx] / 1440)
            set_cell_margins(cell)


def set_run(run, size=9, bold=False, color=BLACK, italic=False):
    run.font.name = "Calibri"
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), "Calibri")
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), "Calibri")
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    run.font.color.rgb = RGBColor.from_string(color)


def style_paragraph(p, before=0, after=4, line=1.05):
    p.paragraph_format.space_before = Pt(before)
    p.paragraph_format.space_after = Pt(after)
    p.paragraph_format.line_spacing = line


def add_bullet(doc, text):
    p = doc.add_paragraph(style="List Bullet")
    style_paragraph(p, after=3, line=1.08)
    set_run(p.add_run(text), size=10)
    return p


def add_numbered(doc, text):
    p = doc.add_paragraph(style="List Number")
    style_paragraph(p, after=3, line=1.08)
    set_run(p.add_run(text), size=10)
    return p


doc = Document()
sec = doc.sections[0]
sec.orientation = WD_ORIENT.LANDSCAPE
sec.page_width = Inches(11)
sec.page_height = Inches(8.5)
sec.top_margin = Inches(0.62)
sec.bottom_margin = Inches(0.62)
sec.left_margin = Inches(0.5)
sec.right_margin = Inches(0.5)
sec.header_distance = Inches(0.3)
sec.footer_distance = Inches(0.3)

styles = doc.styles
normal = styles["Normal"]
normal.font.name = "Calibri"
normal._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
normal.font.size = Pt(10)
normal.paragraph_format.space_after = Pt(5)
normal.paragraph_format.line_spacing = 1.1

for name, size, color, before, after in (
    ("Title", 23, NAVY, 0, 4),
    ("Heading 1", 15, BLUE, 12, 6),
    ("Heading 2", 12, NAVY, 8, 4),
):
    st = styles[name]
    st.font.name = "Calibri"
    st._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
    st._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
    st.font.size = Pt(size)
    st.font.bold = True
    st.font.color.rgb = RGBColor.from_string(color)
    st.paragraph_format.space_before = Pt(before)
    st.paragraph_format.space_after = Pt(after)

header = sec.header.paragraphs[0]
header.text = "FLYWIRE | SALESFORCE CPQ / OMNISTUDIO"
header.alignment = WD_ALIGN_PARAGRAPH.RIGHT
style_paragraph(header, after=0)
for run in header.runs:
    set_run(run, size=8, bold=True, color=MID_GRAY)

footer = sec.footer.paragraphs[0]
footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
set_run(footer.add_run("SALDEV-1403 | Partial sandbox artifact inventory"), size=8, color=MID_GRAY)

p = doc.add_paragraph(style="Title")
p.alignment = WD_ALIGN_PARAGRAPH.LEFT
set_run(p.add_run("Artifacts List / Deployment List"), size=23, bold=True, color=NAVY)

p = doc.add_paragraph()
style_paragraph(p, after=10)
set_run(p.add_run("Story: "), size=10, bold=True, color=BLUE)
set_run(p.add_run("SALDEV-1403 - Update output documents for stepped-up pricing (OmniStudio)"), size=10)
set_run(p.add_run("   |   Target: FlywirePartial sandbox"), size=10, color=MID_GRAY)

headers = ["Name", "Component Name", "Component API Name / Record ID", "Dependency", "Comments"]
rows = [
    (
        "OmniScript",
        "Generate Quote Document - SteppedUpPricing\nVersion 2",
        "Type: CPQ\nSubType: QuoteDocument\nLanguage: English\nID: 0jNhG0000000umzUAA",
        "GetQuoteProposalDataSteppedUpPricing\nGetDocumentTemplate action\nCPQQuoteProposalDocumentSteppedUpPricing\nCPQ Quote Proposal template",
        "Active user entry point used to generate/preview the stepped-up pricing proposal. Passes the Quote record ID as ContextId and orchestrates extract, template selection, transform, and document generation.",
    ),
    (
        "Data Mapper Extract",
        "GetQuoteProposalDataSteppedUpPricing",
        "ID: 0jIhG0000000GsnUAE\nType: Extract\nVersion: 1",
        "SBQQ__Quote__c\nSBQQ__QuoteLineGroup__c\nSBQQ__QuoteLine__c\nAccount / Product data",
        "Retrieves quote header, line groups, service start/end dates, group ordering fields, products, quantities, billing frequency, price, description, Rate Details, and Ship-To data. Supports grouped and ungrouped quotes and the final amendment-line exclusion requirement.",
    ),
    (
        "Data Mapper Transform",
        "CPQQuoteProposalDocumentSteppedUpPricing",
        "ID: 0jIhG0000000HX7UAM\nType: Transform\nVersion: 1",
        "Output from GetQuoteProposalDataSteppedUpPricing\nWord document token model",
        "Builds the document JSON structure for Group and QuoteLine/Line nodes. Produces conditional flags for grouped versus ungrouped output and Multiple Ship-To behavior, while preventing duplicate lines and keeping products under the correct group.",
    ),
    (
        "Document Template",
        "CPQ Quote Proposal",
        "ID: 2dtPb0000000BwLIAU\nType: MicrosoftWord\nMechanism: ClientSide",
        "Transform token model\nDocumentTemplateContentDoc link\nOmniScript template-selection action",
        "Active template record. Contains the grouped pricing section, group name/term header, service period, correct product placement, and conditional Ship-To Account column. Preserves the existing layout for ordinary ungrouped quotes.",
    ),
    (
        "Template Content",
        "CPQ Quote Proposal - SteppedUpPricing-v5.docx",
        "ContentVersion: 068hG0000033ObzQAE\nContentDocument: 069hG000003DZfnQAG\nTemplate link: 2ddhG0000001bwnQAA",
        "DocumentTemplate: CPQ Quote Proposal\nData Mapper output tokens",
        "Final Word content linked to the active template. Displays each group separately, appends Rate Details to Description, shows service periods and term headers, conditionally shows Ship-To, and avoids an empty 'Group 1' section for ungrouped Legal quotes.",
    ),
]

table = doc.add_table(rows=1, cols=5)
table.style = "Table Grid"
widths = [1050, 2200, 2300, 2250, 6600 - 0]  # replaced below with exact landscape total
widths = [1050, 2100, 2350, 2250, 6650]
# Named layout override: landscape deployment matrix, 14,400 DXA total content width.
set_table_geometry(table, widths)
for i, text in enumerate(headers):
    cell = table.rows[0].cells[i]
    set_cell_shading(cell, NAVY)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    p = cell.paragraphs[0]
    style_paragraph(p, after=0, line=1.0)
    set_run(p.add_run(text), size=9.5, bold=True, color=WHITE)

for ridx, data in enumerate(rows):
    cells = table.add_row().cells
    for cidx, value in enumerate(data):
        if ridx % 2 == 1:
            set_cell_shading(cells[cidx], LIGHT_GRAY)
        cells[cidx].vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.TOP
        p = cells[cidx].paragraphs[0]
        style_paragraph(p, after=0, line=1.02)
        for line_idx, line in enumerate(value.split("\n")):
            if line_idx:
                p.add_run().add_break()
            set_run(p.add_run(line), size=8.2, bold=(cidx == 0 or (cidx == 1 and line_idx == 0)), color=(NAVY if cidx == 0 else BLACK))

set_table_geometry(table, widths)

p = doc.add_paragraph()
style_paragraph(p, before=5, after=2)
set_run(p.add_run("Deployment order: "), size=9, bold=True, color=BLUE)
set_run(p.add_run("1) Extract Data Mapper  2) Transform Data Mapper  3) Document Template and DOCX content  4) OmniScript version/activation  5) Run the three business test scenarios."), size=9)

doc.add_page_break()
doc.add_paragraph("Scope, Validation, and Exclusions", style="Heading 1")

doc.add_paragraph("What the story required", style="Heading 2")
for text in (
    "Render quote-line groups dynamically and in the intended order; keep bundle options under the correct parent product.",
    "Show group name/term header and service-period start/end dates for stepped-up pricing quotes.",
    "Append Rate Details to the product Description and exclude amendment lines from the generated output.",
    "Show the Ship-To Account column only when Multiple Ship-To Accounts is Yes.",
    "Keep the original ungrouped quote layout and do not display an empty Group 1 section.",
):
    add_bullet(doc, text)

doc.add_paragraph("Business validation completed in Partial", style="Heading 2")
validation = doc.add_table(rows=1, cols=3)
validation.style = "Table Grid"
validation_widths = [1900, 3900, 8600]
set_table_geometry(validation, validation_widths)
for i, text in enumerate(("Quote", "Scenario", "Expected / validated result")):
    set_cell_shading(validation.rows[0].cells[i], LIGHT_BLUE)
    p = validation.rows[0].cells[i].paragraphs[0]
    style_paragraph(p, after=0)
    set_run(p.add_run(text), size=9.5, bold=True, color=NAVY)
for data in (
    ("Q-37723", "Five groups; Multiple Ship-To = Yes", "Separate groups, service dates, correct products, no duplicates, and Ship-To Account column visible."),
    ("Q-37780", "Five groups; Multiple Ship-To = No", "Same grouped output with the Ship-To Account column hidden."),
    ("Q-37640", "Ordinary ungrouped quote", "Original product table retained; no group headers, no service-period group section, and no empty Group 1."),
):
    cells = validation.add_row().cells
    for i, value in enumerate(data):
        p = cells[i].paragraphs[0]
        style_paragraph(p, after=0, line=1.05)
        set_run(p.add_run(value), size=9)
set_table_geometry(validation, validation_widths)

doc.add_paragraph("Not deployment artifacts for SALDEV-1403", style="Heading 2")
for text in (
    "No new LWC, Flow, Custom Field, Permission Set, or Visualforce component was created for this story.",
    "CPQQuoteProposalOutputSerializer and its Apex test were experimental validation utilities; the serializer is not attached to the final OmniStudio flow and should not be included in the SALDEV-1403 deployment package.",
    "SALDEV-1420 email/approval-document OmniStudio assets are a separate story and are excluded from this artifact list.",
    "Local scripts, JSON patch files, render folders, and handoff reports are engineering evidence only; they are not Salesforce deployable metadata.",
):
    add_bullet(doc, text)

doc.add_page_break()
doc.add_paragraph("Business-User Test Steps", style="Heading 1")

doc.add_paragraph("Before testing", style="Heading 2")
for text in (
    "Log in to the Flywire Partial sandbox as a business user who can open Quotes and run the existing Generate Document action.",
    "Use the Sales Console, open the Quotes tab, and confirm that the active Generate Quote Document - SteppedUpPricing OmniScript is available from the quote action.",
    "For each scenario, close and reopen the document-generation screen before the next test if the browser retains a cached template or previous Context ID.",
):
    add_bullet(doc, text)

doc.add_paragraph("Test 1 - Grouped quote with Multiple Ship-To Accounts", style="Heading 2")
for text in (
    "Open quote Q-37723: https://flywire--partial.sandbox.my.salesforce.com/a2NhG000002ktrcUAA",
    "Confirm QuoteLineGroupsPresent__c is true, Multiple Ship-To Accounts is Yes, and five quote-line groups exist.",
    "Click Generate Document or Generate Quote Document. If the button is not visible, open the quote action drop-down at the upper-right of the record page.",
    "Complete the active OmniScript and select CPQ Quote Proposal when a template selection is displayed.",
    "Choose Preview or Generate and open the resulting proposal document/PDF.",
    "Verify that all five groups appear separately; each group has its name or Term header and service-period start/end dates; products appear beneath the correct group; and no lines are duplicated.",
    "Verify that Product, Quantity, Billing Frequency, Description including Rate Details, Price, and Ship-To Account are populated. The Ship-To Account column must be visible.",
):
    add_numbered(doc, text)

doc.add_paragraph("Test 2 - Grouped quote without Multiple Ship-To Accounts", style="Heading 2")
for text in (
    "Open quote Q-37780: https://flywire--partial.sandbox.my.salesforce.com/a2NhG000003EetVUAS",
    "Confirm that five quote-line groups exist and Multiple Ship-To Accounts is No.",
    "Run Generate Document / Generate Quote Document, complete the OmniScript, and preview or generate the proposal.",
    "Verify the same grouped output as Test 1: correct group order, group/Term header, service-period dates, correct product placement, populated product fields, appended Rate Details, and no duplicate lines.",
    "Verify that the Ship-To Account column is not displayed anywhere in the product table.",
):
    add_numbered(doc, text)

doc.add_paragraph("Test 3 - Ordinary ungrouped quote regression", style="Heading 2")
for text in (
    "Open quote Q-37640: https://flywire--partial.sandbox.my.salesforce.com/a2NhG000002YPkPUAW",
    "Confirm QuoteLineGroupsPresent__c is false.",
    "Run Generate Document / Generate Quote Document, complete the OmniScript, and preview or generate the proposal.",
    "Verify that the normal product table appears and matches the previous ungrouped layout.",
    "Verify that no group heading, Term header, grouped service-period section, or empty Group 1 appears.",
):
    add_numbered(doc, text)

doc.add_paragraph("Pass criteria", style="Heading 2")
for text in (
    "All three documents generate without an OmniScript Document Generation error.",
    "Grouped quotes render every line exactly once under the correct group and in the intended order.",
    "The Ship-To Account column follows the Multiple Ship-To Accounts setting.",
    "The ordinary quote retains its original ungrouped document layout.",
):
    add_bullet(doc, text)

p = doc.add_paragraph()
style_paragraph(p, before=8, after=0)
set_run(p.add_run("Prepared for handoff to David | Current implementation evidence from the FlywirePartial sandbox and the local flywire-docgen workspace."), size=8.5, italic=True, color=MID_GRAY)

OUT.parent.mkdir(parents=True, exist_ok=True)
doc.save(OUT)
print(OUT)
