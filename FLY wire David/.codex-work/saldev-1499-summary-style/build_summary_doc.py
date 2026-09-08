from pathlib import Path

from docx import Document
from docx.enum.section import WD_ORIENT
from docx.enum.table import WD_ALIGN_VERTICAL, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david")
OUTPUT = ROOT / "flywire-docgen" / "deliverables" / "SALDEV-1499_Architect_Review_Summary.docx"


def set_font(run, size=11, bold=False, italic=False, color="262626"):
    run.font.name = "Arial"
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    for key in ("ascii", "hAnsi", "eastAsia"):
        rfonts.set(qn(f"w:{key}"), "Arial")
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    run.font.color.rgb = RGBColor.from_string(color)


def remove_border(paragraph):
    ppr = paragraph._p.get_or_add_pPr()
    pbdr = ppr.find(qn("w:pBdr"))
    if pbdr is not None:
        ppr.remove(pbdr)


def remove_style_border(style):
    ppr = style.element.get_or_add_pPr()
    pbdr = ppr.find(qn("w:pBdr"))
    if pbdr is not None:
        ppr.remove(pbdr)


def title(doc, text):
    p = doc.add_paragraph(style="Title")
    remove_border(p)
    p.paragraph_format.space_after = Pt(22)
    r = p.add_run(text)
    set_font(r, size=22, bold=False, color="202124")


def heading(doc, text, level=1):
    p = doc.add_paragraph(style=f"Heading {level}")
    p.paragraph_format.space_before = Pt(14 if level == 1 else 10)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    set_font(r, size=16 if level == 1 else 12.5, bold=True, color="202124")
    return p


def paragraph(doc, text, *, bold=False, italic=False, after=7):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(after)
    p.paragraph_format.line_spacing = 1.25
    r = p.add_run(text)
    set_font(r, size=11.5, bold=bold, italic=italic)
    return p


def bullet(doc, text):
    p = doc.add_paragraph(style="List Bullet")
    p.paragraph_format.left_indent = Inches(0.24)
    p.paragraph_format.first_line_indent = Inches(-0.15)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.line_spacing = 1.10
    r = p.add_run(text)
    set_font(r, size=10.8)
    return p


def set_cell_fill(cell, fill):
    tcpr = cell._tc.get_or_add_tcPr()
    shd = tcpr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tcpr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=90, start=115, bottom=90, end=115):
    tcpr = cell._tc.get_or_add_tcPr()
    tcmar = tcpr.first_child_found_in("w:tcMar")
    if tcmar is None:
        tcmar = OxmlElement("w:tcMar")
        tcpr.append(tcmar)
    for tag, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tcmar.find(qn(f"w:{tag}"))
        if node is None:
            node = OxmlElement(f"w:{tag}")
            tcmar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_table_borders(table):
    tblpr = table._tbl.tblPr
    borders = tblpr.first_child_found_in("w:tblBorders")
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tblpr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        node = borders.find(qn(f"w:{edge}"))
        if node is None:
            node = OxmlElement(f"w:{edge}")
            borders.append(node)
        node.set(qn("w:val"), "single")
        node.set(qn("w:sz"), "4")
        node.set(qn("w:color"), "D9D9D9")


def repeat_header(row):
    trpr = row._tr.get_or_add_trPr()
    hdr = OxmlElement("w:tblHeader")
    hdr.set(qn("w:val"), "true")
    trpr.append(hdr)


def table(doc, headers, rows, widths, status_col=None):
    t = doc.add_table(rows=1, cols=len(headers))
    t.alignment = WD_TABLE_ALIGNMENT.LEFT
    t.autofit = False
    repeat_header(t.rows[0])
    for i, h in enumerate(headers):
        cell = t.rows[0].cells[i]
        cell.width = Inches(widths[i])
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        set_cell_fill(cell, "FFFFFF")
        set_cell_margins(cell)
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        r = p.add_run(h)
        set_font(r, size=10.8, bold=True)
    for row_index, values in enumerate(rows):
        cells = t.add_row().cells
        for i, value in enumerate(values):
            cell = cells[i]
            cell.width = Inches(widths[i])
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            set_cell_margins(cell)
            if row_index % 2 == 1:
                set_cell_fill(cell, "FAFAFA")
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.08
            if status_col == i:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r = p.add_run(value)
            color = "262626"
            bold = False
            if status_col == i:
                bold = True
                color = {"Pass": "168A73", "Fail": "D13232", "Partial": "B97816"}.get(value, "262626")
            set_font(r, size=10.2, bold=bold, color=color)
    set_table_borders(t)
    spacer = doc.add_paragraph()
    spacer.paragraph_format.space_after = Pt(2)
    return t


def build():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc = Document()
    section = doc.sections[0]
    section.orientation = WD_ORIENT.PORTRAIT
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.72)
    section.bottom_margin = Inches(0.72)
    section.left_margin = Inches(0.8)
    section.right_margin = Inches(0.8)

    title_style = doc.styles["Title"]
    remove_style_border(title_style)
    for style_name in ("Title", "Heading 1", "Heading 2", "Normal"):
        style = doc.styles[style_name]
        style.font.name = "Arial"
        style.font.color.rgb = RGBColor.from_string("202124")

    doc.core_properties.title = "SALDEV 1499 Architect Review 7 September 2026"
    doc.core_properties.author = ""
    doc.core_properties.last_modified_by = ""

    title(doc, "SALDEV 1499 Architect Review 7 September 2026")
    paragraph(doc, "Decision: focused Salesforce test execution passed. Retain Changes Requested because the current tests do not fully prove the business outcomes and governor-limit claim in the Jira comment. No metadata was deployed or activated, and no Jira comment or business record was changed.")

    heading(doc, "Verified environment and validation")
    bullet(doc, "Environment: Flywire Partial sandbox; organization ID 00DhG0000000jOXUAY.")
    bullet(doc, "Flow Quote Line Type background field update is inactive. Version 13 is deactivated.")
    bullet(doc, "Focused Apex run 707hG00000MwRH0 completed with 9 tests and 0 failures.")
    bullet(doc, "The first synchronous attempt met ORG_ADMIN_LOCKED. The same focused class completed asynchronously.")
    bullet(doc, "Coverage below is from this focused run, not the Developer Console overall coverage display.")

    table(doc, ["Component", "Covered total lines", "Coverage"], [
        ["QuoteLineTrigger", "31 / 39", "79 percent"],
        ["QuoteLineTriggerHandler", "280 / 289", "96 percent"],
    ], [3.0, 2.0, 1.7])

    heading(doc, "Verified implementation changes")
    bullet(doc, "Before insert and before update call handlePriceChangeOnAmendmentClones, processBackgroundFields, and copyQuoteLineTypeToBackground in that order.")
    bullet(doc, "After update guards OLI synchronization with needsIdSync and a non-empty quote ID set instead of returning from the trigger early.")
    bullet(doc, "The isFirstRun flag is restored in a finally block, and the normal first-run path can continue to calculateRollupField.")
    bullet(doc, "The handler uses Set and Map collections and keeps SOQL outside loops.")

    doc.add_page_break()
    heading(doc, "Review of the Jira comment")
    table(doc, ["Comment claim", "Result", "Finding"], [
        ["Before-save call order corrected", "Pass", "The active trigger source contains the required order."],
        ["After-update early return corrected", "Pass", "The synchronization block is guarded without skipping the normal rollup path."],
        ["Three output fields asserted", "Fail", "The named test checks only that Default_Rate_Details__c is non-null."],
        ["200-line governor proof", "Partial", "The method completes for 200 records but does not assert query usage below 100 or exercise representative mixed data end to end."],
        ["Trigger and handler coverage", "Pass", "The focused run reports 79 percent and 96 percent."],
        ["Flow version 13 deactivated", "Pass", "The Flow is inactive and version 13 is deactivated."],
    ], [2.25, 0.85, 3.6], status_col=1)

    heading(doc, "Architect findings")
    bullet(doc, "High: the tests do not assert exact values for Quote_Line_Type_background__c, Rate_Details_Changed__c, and Default_Rate_Details__c.")
    bullet(doc, "High: formula-copy correctness after an in-transaction Price_Change__c update is not proven.")
    bullet(doc, "Medium: the 200-line method uses one quote and one product, disables managed triggers for insert, calls calculateRollupField directly, and does not assert Limits.getQueries.")
    bullet(doc, "Medium: no behavioral test proves that OLI synchronization and rollup both complete in the same update.")
    bullet(doc, "Medium: copyQuoteLineTypeToBackground catches a generic exception and only logs a warning, which can hide a classification failure.")
    bullet(doc, "Low: the code uses testProcessBackgroundFieldsFallbackAndEstoreMismatch, while the Jira comment names RestoreMismatch.")

    heading(doc, "Required changes before approval")
    bullet(doc, "Re-query and assert the exact expected value of all three output fields after insert and update.")
    bullet(doc, "Strengthen the 200-line test with mixed source, subscription, amendment, product, and quote data through the complete supported path.")
    bullet(doc, "Record defensible governor headroom and assert final field and rollup outcomes.")
    bullet(doc, "Add one update test that proves OLI synchronization and rollup complete together.")
    bullet(doc, "Add a Price_Change__c scenario that proves the persisted background classification matches the final formula result.")
    bullet(doc, "Narrow exception handling or surface unexpected failures so that tests and support can detect them.")

    heading(doc, "Final decision")
    paragraph(doc, "Execution passed. The architect decision remains Changes Requested because exact field assertions and representative bulk evidence are missing. Approve only after both pass in a new focused run.", bold=True)

    doc.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build()
