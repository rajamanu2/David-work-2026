from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt

from build_architect_review import (
    INK,
    LIGHT_BLUE,
    MUTED,
    NAVY,
    add_body,
    add_heading,
    add_page_field,
    add_table,
    rgb,
    set_cell_margins,
    set_cell_text,
    set_run_font,
    set_table_geometry,
    shade_cell,
)


ROOT = Path(__file__).resolve().parent
REFERENCE = ROOT / "SCC-3387-architect-review.docx"
OUTPUT = ROOT / "SCC-4273-Peer-Review.docx"


def clear_body(document: Document) -> None:
    body = document._element.body
    for child in list(body):
        if child.tag != qn("w:sectPr"):
            body.remove(child)


def set_light_borders(table) -> None:
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.find(qn("w:tblBorders"))
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = qn(f"w:{edge}")
        element = borders.find(tag)
        if element is None:
            element = OxmlElement(f"w:{edge}")
            borders.append(element)
        element.set(qn("w:val"), "single")
        element.set(qn("w:sz"), "6")
        element.set(qn("w:space"), "0")
        element.set(qn("w:color"), "D9D9D9")


def normalize_table(table) -> None:
    set_light_borders(table)
    for row in table.rows:
        for cell in row.cells:
            set_cell_margins(cell, top=80, start=115, bottom=80, end=115)


def review_table(document, headers, rows, widths, status_column=None):
    table = add_table(document, headers, rows, widths, status_column=status_column)
    normalize_table(table)
    return table


def configure_footer(section) -> None:
    for header in (section.header, section.even_page_header, section.first_page_header):
        paragraph = header.paragraphs[0]
        paragraph.text = ""
        paragraph.paragraph_format.space_after = Pt(0)
    for footer in (section.footer, section.even_page_footer, section.first_page_footer):
        paragraph = footer.paragraphs[0]
        paragraph.text = ""
        paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        paragraph.paragraph_format.space_before = Pt(0)
        run = paragraph.add_run("GreatPlainsMerge  |  Page ")
        set_run_font(run, size=9, color=MUTED)
        add_page_field(paragraph)


def configure_document(document: Document) -> None:
    document.settings.odd_and_even_pages_header_footer = False
    for section in document.sections:
        section.page_width = Inches(8.5)
        section.page_height = Inches(11)
        section.top_margin = Inches(0.85)
        section.right_margin = Inches(0.9)
        section.bottom_margin = Inches(0.85)
        section.left_margin = Inches(0.9)
        section.header_distance = Inches(0.42)
        section.footer_distance = Inches(0.42)
        section.different_first_page_header_footer = False
        configure_footer(section)

    normal = document.styles["Normal"]
    normal.font.name = "Arial"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
    normal.font.size = Pt(10.5)
    normal.font.color.rgb = rgb(INK)
    normal.paragraph_format.space_before = Pt(0)
    normal.paragraph_format.space_after = Pt(5)
    normal.paragraph_format.line_spacing = 1.05

    title = document.styles["Title"]
    title.font.name = "Arial"
    title._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
    title._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
    title.font.size = Pt(25)
    title.font.bold = True
    title.font.color.rgb = rgb("000000")
    title.paragraph_format.space_before = Pt(0)
    title.paragraph_format.space_after = Pt(4)
    title.paragraph_format.keep_with_next = True
    p_pr = title._element.get_or_add_pPr()
    border = p_pr.find(qn("w:pBdr"))
    if border is not None:
        p_pr.remove(border)

    for name, size, before, after in (
        ("Heading 1", 16, 10, 5),
        ("Heading 2", 13, 8, 4),
        ("Heading 3", 12, 7, 3),
    ):
        style = document.styles[name]
        style.font.name = "Arial"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = rgb("000000")
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True


def add_decision(document: Document, label: str, message: str) -> None:
    paragraph = document.add_paragraph()
    paragraph.paragraph_format.space_before = Pt(3)
    paragraph.paragraph_format.space_after = Pt(8)
    paragraph.paragraph_format.line_spacing = 1.05
    lead = paragraph.add_run(f"{label}  ")
    set_run_font(lead, size=10.5, color=NAVY, bold=True)
    body = paragraph.add_run(message)
    set_run_font(body, size=10.5, color=INK)


def add_metadata(document: Document) -> None:
    rows = [
        ("Environment", "GreatPlainsMerge sandbox | Great Plains Communications | Org 00DEa00000GkAsHMAV"),
        ("Review date", "5 September 2026"),
        ("Story / branch", "SCC-4273 | dev_SCC-4273__feat-Case_-_Trouble_Ticket_"),
        ("Focused retrieval", "Succeeded | Jobs 09SEa00000jCU0XMAW, 09SEa00000jCVxUMAW, 09SEa00000jCxjyMAC"),
        ("Decision", "Changes Requested - do not approve the PR yet"),
        ("Boundary", "Read-only review; no records, metadata, activation, deployment, or access assignments changed"),
    ]
    table = document.add_table(rows=len(rows) + 1, cols=2)
    table.style = "Table Grid"
    set_table_geometry(table, [1850, 7670])
    normalize_table(table)
    header_row = table.rows[0]
    header_properties = header_row._tr.get_or_add_trPr()
    header_properties.append(OxmlElement("w:tblHeader"))
    for cell, text in zip(header_row.cells, ("Review item", "Evidence")):
        shade_cell(cell, "EEF1F5")
        set_cell_text(cell, text, size=9.2, color=NAVY, bold=True)
    for row, (label, value) in zip(table.rows[1:], rows):
        shade_cell(row.cells[0], LIGHT_BLUE)
        set_cell_text(row.cells[0], label, size=9.2, color=NAVY, bold=True)
        set_cell_text(row.cells[1], value, size=9.1)
    document.add_paragraph().paragraph_format.space_after = Pt(0)


def build_document() -> None:
    document = Document(REFERENCE)
    clear_body(document)
    configure_document(document)

    eyebrow = document.add_paragraph()
    eyebrow.paragraph_format.space_before = Pt(6)
    eyebrow.paragraph_format.space_after = Pt(2)
    set_run_font(eyebrow.add_run("PEER REVIEW"), size=10, color="000000", bold=True)

    title = document.add_paragraph(style="Title")
    title.add_run("SCC 4273 Case Trouble Ticket Peer Review")

    subtitle = document.add_paragraph()
    subtitle.paragraph_format.space_after = Pt(12)
    set_run_font(
        subtitle.add_run("Great Plains Merge Sandbox Read only implementation assessment"),
        size=13,
        color="000000",
    )

    add_metadata(document)
    add_decision(
        document,
        "Decision",
        "Changes Requested. The Trouble Ticket record type, dedicated layout, source-listed fields, and reviewed profile access are present. Approval is blocked because the record type exposes only one Primary Resolution at runtime and the submitted PR URL, base, head, commit, and file diff were not supplied for code-parity review.",
    )

    add_heading(document, "Acceptance outcome", 1)
    acceptance_rows = [
        (
            "1",
            "Record type and layout",
            "Pass",
            "Trouble_Ticket is active. Case-Trouble Ticket contains the source-listed Case Information, Critical Dates, and Resolution Details fields.",
        ),
        (
            "2",
            "Profile field access",
            "Pass",
            "Admin, Standard, and System Administrator - API Only have readable/editable access to all nine reviewed custom Case fields.",
        ),
        (
            "3",
            "Subscriber Report values",
            "Partial pass",
            "All 64 unique supplied labels are enabled for Trouble Ticket. Eight additional enabled values require business confirmation.",
        ),
        (
            "4",
            "Primary Resolution runtime",
            "Fail",
            "Only Cleared Without Repair is enabled for the Trouble Ticket record type, although 61 unique resolution labels were supplied.",
        ),
        (
            "5",
            "Dependency design",
            "Fail",
            "Primary Resolution depends on Subscriber Report, but Subscriber Report has no Service Type controller. The intended matrix is not documented in acceptance criteria.",
        ),
        (
            "6",
            "PR parity and API proof",
            "Not proven",
            "The document provides a branch name but no PR diff. The separate API org shown in screenshots was not connected for independent verification.",
        ),
    ]
    review_table(document, ["#", "Scope", "Result", "Evidence"], acceptance_rows, [500, 2050, 1450, 5520], status_column=2)

    document.add_page_break()
    add_heading(document, "Layout and access evidence", 1)
    layout_rows = [
        ("Case Information", "Pass", "Parent Case, Service Type, Service Address, standard Priority, Subscriber Report, and other routing/contact fields are present."),
        ("Critical Dates", "Pass", "Problem Occurred, Problem Reported, Repair, Created, and Closed dates are present."),
        ("Resolution Details", "Pass", "Primary Resolution, Secondary Resolution, and Resolution Detail are present."),
        ("Record type", "Pass", "Trouble_Ticket is active with ID 012Ea000007eNrVIAU."),
        ("Dedicated layout", "Pass", "Case-Trouble Ticket is assigned to the reviewed profiles for this record type."),
    ]
    review_table(document, ["Area", "Result", "Current Merge evidence"], layout_rows, [2350, 1400, 5770], status_column=1)

    add_heading(document, "Reviewed custom-field permissions", 2)
    access_rows = [
        ("Admin", "9 of 9 readable", "9 of 9 editable", "Pass"),
        ("Standard", "9 of 9 readable", "9 of 9 editable", "Pass"),
        ("System Administrator - API Only", "9 of 9 readable", "9 of 9 editable", "Pass"),
    ]
    review_table(document, ["Profile metadata name", "Read access", "Edit access", "Result"], access_rows, [3250, 2050, 2050, 2170], status_column=3)
    add_body(
        document,
        "Problem Occurred Date, Problem Reported Date, Repair Date, Resolution Detail, Service Type, Service Address, Subscriber Report, Primary Resolution, and Secondary Resolution were reviewed. Standard Parent Case, Priority, Created Date, and Closed Date are governed through their standard-field and layout behavior rather than custom fieldPermissions entries.",
        bold_lead="Scope",
        after=4,
    )

    add_heading(document, "Access traceability note", 2)
    trace_rows = [
        ("Ticket comment", "The branch was updated to include the fields in a permission set."),
        ("Observed Merge configuration", "The verified access is in profile metadata. No SCC-4273- or Trouble Ticket-named permission set was identified in the current permission-set inventory."),
        ("Peer review requirement", "Name the actual access component in the ticket and PR inventory so deployment and later audit evidence match the implementation."),
    ]
    review_table(document, ["Evidence source", "Peer review reading"], trace_rows, [2600, 6920])

    document.add_page_break()
    add_heading(document, "Picklist and dependency evidence", 1)
    picklist_rows = [
        ("Service Type", "7 enabled", "Circuit, Internet, Voice, Video, Wireless, Other, and Locate", "Pass for current Merge; no supplied acceptance matrix"),
        ("Subscriber Report", "72 enabled", "64 unique supplied labels plus 8 additional values", "Partial pass - confirm the eight extras"),
        ("Subscriber Report controller", "None", "Not dependent on Service Type", "Fail if Service Type control is required"),
        ("Primary Resolution global values", "61 unique", "All 61 supplied labels exist globally", "Pass at global-value-set level"),
        ("Primary Resolution dependency", "60 mappings", "Controlled by Subscriber Report", "Partial pass - one meaningful value is unmapped"),
        ("Trouble Ticket runtime values", "1 enabled", "Cleared Without Repair only", "Fail - record type blocks the supplied list"),
    ]
    review_table(
        document,
        ["Control", "Observed", "Current Merge evidence", "Peer review reading"],
        picklist_rows,
        [2250, 1450, 3350, 2470],
        status_column=3,
    )

    add_heading(document, "Value reconciliation", 2)
    reconciliation_rows = [
        ("Supplied Subscriber Report list", "70 entries; 64 unique", "All 64 unique labels are present and enabled for Trouble Ticket."),
        ("Duplicate supplied reports", "6 repeated labels", "CUT CABLE OR DROP, CAN'T CONNECT, OUTAGE, ALL SERVICES OUT, and DAMAGE CLAIM repeat; ALL SERVICES OUT appears three times."),
        ("Additional enabled reports", "8 values", "All Plume Related Sub Reports; Analog Channels Out of Service; Channel Buffering; Channels Out; Fixed Wireless Trbl; GPC Declared Outage; Hosted-Features; Referred to NOC/UC."),
        ("Unmapped meaningful resolution", "Fiber Splicing Completed", "Present globally but absent from the 60 Primary Resolution dependency mappings."),
        ("Duplicate-format global values", "3 semantic duplicates", "Clear - Trip / CLEAR- TRIP; Cust Caused - No Chg / CUST CAUSED- NO CHG; Cust Caused - Trip Chg / CUST CAUSED- TRIP CHG."),
    ]
    review_table(document, ["Check", "Observed", "Required reading"], reconciliation_rows, [2600, 2450, 4470])
    add_decision(
        document,
        "Root cause",
        "The principal runtime defect is record-type value enablement: UI API evidence for Trouble Ticket returns one Primary Resolution, regardless of the broader global value set and dependency metadata.",
    )

    document.add_page_break()
    add_heading(document, "PR and evidence boundary", 1)
    boundary_rows = [
        ("Attached source", "Reviewed", "The supplied SCC-4273 export and its screenshots were treated as ticket evidence, not as authorization to change Salesforce."),
        ("Merge sandbox", "Verified", "Organization identity, Case schema, record type, layout, three profiles, global value set, and record-type UI picklists were checked read-only."),
        ("Git pull request", "Not supplied", "No PR URL, base branch, head commit, changed-file list, or diff was available. Branch-to-org and branch-to-target parity cannot be approved."),
        ("Separate API org", "Not connected", "The screenshot comparison was not independently reproduced, so the API-side missing-field claim remains unverified in this review."),
        ("Acceptance criteria", "Missing", "The ticket export says None. The intended controller matrix, approved extra values, and exact deployment inventory are therefore not authoritative."),
        ("Testing and release", "Not performed", "No record creation, persona UI test, deployment validation, deployment, activation, access assignment, or UAT execution was performed."),
    ]
    review_table(document, ["Boundary", "Status", "Evidence and limitation"], boundary_rows, [2250, 1650, 5620], status_column=1)

    add_heading(document, "Required approval gates", 1)
    gate_rows = [
        ("1", "Attach exact PR evidence", "PR URL, base/head, commit SHA, changed-file list, and diff match the intended release."),
        ("2", "Correct Primary Resolution enablement", "All approved values are enabled for Trouble Ticket and verified through UI API plus a named-persona UI test."),
        ("3", "Confirm dependency design", "Product Owner states whether Subscriber Report must depend on Service Type and supplies the approved service-to-report matrix."),
        ("4", "Reconcile values", "Map Fiber Splicing Completed, resolve duplicate-format resolutions, and approve or remove the eight additional Subscriber Report values."),
        ("5", "Correct component inventory", "Ticket and PR name the record type, layout, fields, value set, dependencies, and actual profile or permission-set access components."),
        ("6", "Run promotion-path validation", "Re-review the PR diff, test as named personas in Merge, and independently verify the target API/UAT org after promotion."),
    ]
    review_table(document, ["#", "Required action", "Approval evidence"], gate_rows, [550, 3100, 5870])

    document.add_page_break()
    add_heading(document, "Ready to paste peer review response", 1)
    response = (
        "Peer review completed in GreatPlainsMerge. Changes Requested - do not approve the PR yet. The Trouble Ticket record type is active; the dedicated layout includes the source-listed Case Information, Critical Dates, and Resolution Details fields; and Admin, Standard, and System Administrator - API Only have read/edit access to all nine reviewed custom fields. All 64 unique Subscriber Report labels supplied in the ticket are enabled, with eight additional values requiring business confirmation. The blocking defect is Primary Resolution: the Trouble Ticket record type currently exposes only Cleared Without Repair even though the supplied list contains 61 unique values. Subscriber Report also has no Service Type controller, Fiber Splicing Completed is not mapped in the Primary Resolution dependency, and duplicate-format resolution values need reconciliation. The ticket has no acceptance criteria, and no PR URL, base/head, commit, file list, or diff was supplied, so branch parity and merge readiness cannot be approved. Attach the exact PR evidence, correct and retest the runtime picklists, document the intended dependency matrix and component inventory, then resubmit for peer review. No Salesforce records, metadata, activation, deployment, or access assignments were changed."
    )
    add_body(document, response, after=8)

    add_heading(document, "Reviewer sign-off summary", 1)
    signoff_rows = [
        ("Current recommendation", "Changes Requested"),
        ("Verified pass areas", "Active record type; dedicated layout; source-listed fields; three reviewed profile access paths; supplied Subscriber Report labels."),
        ("Blocking areas", "Primary Resolution record-type enablement; missing PR diff; undocumented dependency and value decisions."),
        ("Re-review trigger", "Updated PR evidence plus successful named-persona runtime verification in Merge and the promoted target org."),
    ]
    review_table(document, ["Review item", "Outcome"], signoff_rows, [2650, 6870])
    add_body(
        document,
        "This document assesses the evidence available on 5 September 2026. It does not certify deployment, target-org parity, business acceptance, or production readiness.",
        italic=True,
        color=MUTED,
        after=2,
    )

    document.core_properties.title = "SCC 4273 Case Trouble Ticket Peer Review"
    document.core_properties.subject = "Read only implementation assessment in GreatPlainsMerge"
    document.core_properties.author = "Peer Review"
    document.core_properties.keywords = "Salesforce, Great Plains, SCC-4273, Case, Trouble Ticket, peer review"
    document.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build_document()
