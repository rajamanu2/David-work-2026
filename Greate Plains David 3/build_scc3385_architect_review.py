from pathlib import Path

from PIL import Image, ImageDraw
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.shared import Inches, Pt

from build_architect_review import (
    AMBER,
    BLUE,
    INK,
    LIGHT_BLUE,
    LIGHT_RED,
    MUTED,
    NAVY,
    RED,
    add_body,
    add_callout,
    add_figure,
    add_heading,
    add_page_field,
    add_table,
    arrow,
    draw_wrapped,
    load_font,
    rgb,
    rounded,
    set_cell_text,
    set_run_font,
    set_table_geometry,
    shade_cell,
)


ROOT = Path(__file__).resolve().parent
REFERENCE = ROOT / "Great_Plains_Trouble_Ticket_Architect_Review.docx"
ASSET_DIR = ROOT / "doc-assets-scc3385"
OUTPUT = ROOT / "SCC-3385-architect-review.docx"
ASSET_DIR.mkdir(exist_ok=True)


def clear_body(document: Document) -> None:
    body = document._element.body
    section_properties = body.sectPr
    for child in list(body):
        if child is not section_properties:
            body.remove(child)


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
        run = paragraph.add_run("GreatPlainsMerge to UAT  |  Page ")
        set_run_font(run, size=9, color=MUTED)
        add_page_field(paragraph)


def configure_document(document: Document) -> None:
    for section in document.sections:
        section.page_width = Inches(8.5)
        section.page_height = Inches(11)
        section.top_margin = Inches(1)
        section.right_margin = Inches(1)
        section.bottom_margin = Inches(1)
        section.left_margin = Inches(1)
        section.header_distance = Inches(0.492)
        section.footer_distance = Inches(0.492)
        configure_footer(section)

    normal = document.styles["Normal"]
    normal.font.name = "Arial"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
    normal.font.size = Pt(11)
    normal.font.color.rgb = rgb(INK)
    normal.paragraph_format.space_before = Pt(0)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.10

    for name, size, color, before, after in (
        ("Heading 1", 16, BLUE, 12, 6),
        ("Heading 2", 13, BLUE, 10, 5),
        ("Heading 3", 12, NAVY, 8, 4),
    ):
        style = document.styles[name]
        style.font.name = "Arial"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = rgb(color)
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True


def draw_bullet_list(draw, box, lines, color, body_font, max_width, step=58) -> None:
    y = box[1]
    for line in lines:
        draw.ellipse((box[0], y + 7, box[0] + 12, y + 19), fill=color)
        draw_wrapped(draw, (box[0] + 28, y), line, body_font, "#1F2937", max_width, spacing=6)
        y += step


def create_deployment_diagram(path: Path) -> None:
    image = Image.new("RGB", (1600, 1020), "#F7F9FC")
    draw = ImageDraw.Draw(image)
    title = load_font(42, bold=True)
    subtitle = load_font(22)
    heading = load_font(26, bold=True)
    body = load_font(19)
    small = load_font(17)

    draw.text((65, 50), "SCC-3385 | Merge-to-UAT validation path", font=title, fill="#0B2545")
    draw.text(
        (67, 110),
        "Source metadata was retrieved successfully; the corrected check-only package exposed target prerequisites and source defects.",
        font=subtitle,
        fill="#5B6777",
    )

    columns = [
        ((55, 220, 420, 610), "GreatPlainsMerge", [
            "Active Flow v1",
            "5 new WorkOrder fields",
            "Quick action + 3 layouts",
            "3 profile payloads",
            "Validation rule absent",
        ], "#E7F5F1", "#16836B"),
        ((620, 220, 985, 610), "Corrected package", [
            "14 metadata members",
            "15 files",
            "Check-only = true",
            "NoTestRun",
            "Rollback on error = true",
        ], "#EAF2FA", "#2E74B5"),
        ((1180, 220, 1545, 610), "GreatPlainsUAT", [
            "6 components validated",
            "8 component failures",
            "SCC-3384 prerequisites missing",
            "Profile drift detected",
            "No metadata changed",
        ], "#FDECEC", "#C53030"),
    ]
    for box, box_title, lines, fill, outline in columns:
        rounded(draw, box, fill, outline=outline, radius=24, width=4)
        draw.text((box[0] + 28, box[1] + 26), box_title, font=heading, fill="#0B2545")
        draw_bullet_list(draw, (box[0] + 30, box[1] + 98), lines, outline, body, box[2] - box[0] - 88)

    arrow(draw, (420, 415), (620, 415), color="#2E74B5", width=7)
    draw.text((454, 368), "retrieve", font=small, fill="#5B6777")
    arrow(draw, (985, 415), (1180, 415), color="#C53030", width=7)
    draw.text((1016, 358), "check-only job", font=small, fill="#5B6777")
    draw.text((1018, 390), "0AfEa00000bbQXhKAM", font=small, fill="#C53030")

    rounded(draw, (55, 690, 760, 965), "#FDECEC", outline="#C53030", radius=22, width=4)
    draw.text((85, 720), "Hard deployment blockers", font=heading, fill="#0B2545")
    blockers = [
        "No Trouble Ticket record type in UAT.",
        "Priority, service, address, and Case-to-WorkOrder prerequisites are absent.",
        "Profiles contain unrelated permission and record-type drift.",
    ]
    draw_bullet_list(draw, (85, 785), blockers, "#C53030", body, 610, step=56)

    rounded(draw, (840, 690, 1545, 965), "#FFF6DE", outline="#B7791F", radius=22, width=4)
    draw.text((870, 720), "Architect decision", font=heading, fill="#0B2545")
    decision = (
        "NO-GO. Repair source design and deploy SCC-3384 prerequisites first, then require a clean 15-of-15 check-only result before promotion."
    )
    draw_wrapped(draw, (870, 795), decision, body, "#1F2937", 610, spacing=8)

    image.save(path)


def class_box(draw, box, title, rows, header_fill="#EAF2FA", outline="#8FB7DC") -> None:
    x1, y1, x2, _ = box
    rounded(draw, box, "#FFFFFF", outline=outline, radius=18, width=3)
    draw.rounded_rectangle((x1, y1, x2, y1 + 62), radius=18, fill=header_fill, outline=outline, width=3)
    draw.rectangle((x1, y1 + 40, x2, y1 + 62), fill=header_fill)
    draw.text((x1 + 22, y1 + 18), title, font=load_font(23, True), fill="#0B2545")
    y = y1 + 80
    for row in rows:
        draw.text((x1 + 22, y), row, font=load_font(17), fill="#3D4A5A")
        y += 29


def create_architecture_diagram(path: Path) -> None:
    image = Image.new("RGB", (1600, 1100), "#FFFFFF")
    draw = ImageDraw.Draw(image)
    draw.text((60, 42), "SCC-3385 | Work Order creation model", font=load_font(40, True), fill="#0B2545")
    draw.text((62, 100), "Case prerequisites, screen Flow controls, Work Order output, and release blockers", font=load_font(22), fill="#5B6777")

    boxes = {
        "case": (55, 220, 405, 505),
        "flow": (470, 220, 850, 535),
        "work": (915, 220, 1265, 535),
        "activity": (1315, 220, 1550, 455),
        "duplicate": (240, 690, 600, 925),
        "layout": (650, 690, 1025, 955),
        "booking": (1080, 690, 1460, 925),
    }

    arrow(draw, (405, 365), (470, 365), color="#2E74B5", width=6)
    arrow(draw, (850, 365), (915, 365), color="#2E74B5", width=6)
    arrow(draw, (1265, 340), (1315, 340), color="#16836B", width=6)
    arrow(draw, (660, 535), (470, 690), color="#2E74B5", width=6)
    arrow(draw, (1085, 535), (845, 690), color="#C53030", width=6)
    arrow(draw, (1130, 535), (1260, 690), color="#16836B", width=6)

    class_box(draw, boxes["case"], "TroubleTicket Case", [
        "RecordType = Trouble_Ticket",
        "Priority__c",
        "Service_Address__c",
        "Service_Type__c",
        "Subscriber_Report__c",
        "Order__c",
    ], header_fill="#FDECEC", outline="#C53030")
    class_box(draw, boxes["flow"], "Create Work Order Flow", [
        "active/latest v1",
        "record-type guard",
        "Work Type required",
        "Work Instructions required",
        "CaseId duplicate lookup",
        "maps notes and address",
        "creates WorkOrder + Task",
    ], header_fill="#EAF2FA", outline="#2E74B5")
    class_box(draw, boxes["work"], "WorkOrder", [
        "Account + Case link",
        "Priority + service address",
        "5 new SCC-3385 fields",
        "Source_Case_Id__c unique",
        "Order__c remains required",
        "exception rule absent",
    ], header_fill="#FFF6DE", outline="#B7791F")
    class_box(draw, boxes["activity"], "Case Activity", [
        "completed Task",
        "Work Order number",
        "Work Type in detail",
        "runtime not executed",
    ], header_fill="#E7F5F1", outline="#16836B")
    class_box(draw, boxes["duplicate"], "Duplicate guard", [
        "lookup by standard CaseId",
        "existing Work Order link",
        "unique Source Case ID",
        "runtime test still required",
    ], header_fill="#EAF2FA", outline="#2E74B5")
    class_box(draw, boxes["layout"], "WorkOrder layouts", [
        "2 layouts retrieved",
        "5 new fields not placed",
        "values cannot be verified",
        "Case relationship missing in UAT",
        "changes requested",
    ], header_fill="#FDECEC", outline="#C53030")
    class_box(draw, boxes["booking"], "Book Appointment", [
        "FSL action remains present",
        "Service Appointments retained",
        "runtime regression not executed",
        "no source regression observed",
    ], header_fill="#E7F5F1", outline="#16836B")

    rounded(draw, (55, 1010, 1550, 1070), "#FDECEC", outline="#C53030", radius=15, width=3)
    draw.text(
        (82, 1027),
        "Release blocker: prerequisites, Order exception, WorkOrder layout placement, profiles, and named UAT Cases must be repaired before retest.",
        font=load_font(19, True),
        fill="#A12626",
    )
    image.save(path)


def build_document() -> None:
    deployment_diagram = ASSET_DIR / "scc3385-deployment-validation-path.png"
    architecture_diagram = ASSET_DIR / "scc3385-work-order-model.png"
    create_deployment_diagram(deployment_diagram)
    create_architecture_diagram(architecture_diagram)

    document = Document(REFERENCE)
    clear_body(document)
    configure_document(document)

    paragraph = document.add_paragraph()
    paragraph.paragraph_format.space_before = Pt(12)
    paragraph.paragraph_format.space_after = Pt(2)
    set_run_font(paragraph.add_run("ARCHITECT REVIEW"), size=10, color=BLUE, bold=True)

    paragraph = document.add_paragraph()
    paragraph.paragraph_format.space_after = Pt(4)
    set_run_font(paragraph.add_run("SCC-3385 | Create Work Order for Tickets"), size=25, color=NAVY, bold=True)

    paragraph = document.add_paragraph()
    paragraph.paragraph_format.space_after = Pt(14)
    set_run_font(
        paragraph.add_run("Great Plains Merge to UAT | Source retrieval and check-only readiness assessment"),
        size=13,
        color=MUTED,
    )

    metadata = [
        ("Source", "GreatPlainsMerge | Org 00DEa00000GkAsHMAV"),
        ("Target", "GreatPlainsUAT | Org 00DEa00000FZlLBMA1"),
        ("Review date", "26 August 2026"),
        ("Check-only", "Failed | Job 0AfEa00000bbQXhKAM | 6/14 validated"),
        ("Decision", "NO-GO - Changes Requested before promotion"),
        ("Boundary", "No records, deployment, activation, or org metadata were changed"),
    ]
    table = document.add_table(rows=len(metadata), cols=2)
    table.style = "Table Grid"
    set_table_geometry(table, [1900, 7460])
    for row, (label, value) in zip(table.rows, metadata):
        shade_cell(row.cells[0], LIGHT_BLUE)
        set_cell_text(row.cells[0], label, size=9.3, color=NAVY, bold=True)
        set_cell_text(row.cells[1], value, size=9.3)
    document.add_paragraph().paragraph_format.space_after = Pt(1)

    add_callout(
        document,
        "Architect decision",
        "Do not promote SCC-3385. UAT lacks the Trouble Ticket foundation, the source Order exception is incomplete, WorkOrder layouts omit the new fields, and the check-only package failed 8 of 14 components.",
        fill=LIGHT_RED,
        accent=RED,
    )

    add_heading(document, "Acceptance outcome", 1)
    acceptance_rows = [
        ("1", "Action visibility", "Partial fail", "Source layout contains Create Work Order; UAT has no Trouble Ticket record type, so visibility cannot validate."),
        ("2", "Inherited details", "Partial fail", "Flow maps Account, address, service, report, notes, and priority; target dependencies and WorkOrder layout fields are missing."),
        ("3", "Required inputs", "Static pass", "Flow requires Work Type and Work Instructions. UAT has all four named trouble Work Types."),
        ("4", "Duplicate prevention", "Static pass", "Flow checks CaseId and links the existing Work Order; Source_Case_Id__c is unique. Runtime is untested."),
        ("5", "Case activity logging", "Static pass", "Flow creates a completed Task with Work Order number and Work Type. Runtime is untested."),
        ("6", "Book Appointment", "Static pass", "FSL__Book_Appointment remains on the FSL layout; no runtime regression was executed."),
    ]
    add_table(document, ["#", "Scope", "Result", "Evidence"], acceptance_rows, [480, 2050, 1450, 5380], status_column=2)

    document.add_page_break()
    add_heading(document, "Deployment readiness path", 1)
    add_body(document, "The source implementation is visible, but the promotion path breaks on prerequisite metadata, broad profile drift, and unresolved source design defects.")
    add_figure(
        document,
        deployment_diagram,
        "Figure 1. SCC-3385 Merge-to-UAT validation path",
        "Diagram showing GreatPlainsMerge metadata moving into a corrected fourteen-component check-only package and failing in GreatPlainsUAT. The lower lane lists missing prerequisites and the NO-GO architect decision.",
        width=6.45,
    )
    add_callout(document, "Design reading", "Green/blue is present in source. Amber requires repair. Red blocks promotion.", fill=LIGHT_BLUE, accent=BLUE)

    document.add_page_break()
    add_heading(document, "Detailed dry-run findings", 1)
    add_heading(document, "1. Check-only deployment evidence", 2)
    validation_rows = [
        ("Job", "0AfEa00000bbQXhKAM", "checkOnly=true; rollbackOnError=true; NoTestRun"),
        ("Payload", "14 components / 15 files", "1 Flow, 1 Quick Action, 6 fields, 3 layouts, 3 profiles"),
        ("Validated", "6", "All six WorkOrder field members validated; five are new and Order__c is changed."),
        ("Failed", "8", "Flow, Quick Action, three layouts, and three profiles failed."),
        ("Tests", "0", "No Apex in scope; functional story tests require controlled record writes."),
    ]
    add_table(document, ["Metric", "Result", "Evidence"], validation_rows, [1750, 2350, 5260])

    add_heading(document, "2. Exact failure groups", 2)
    failure_rows = [
        ("Missing Case prerequisites", "4 components", "Service Address, Priority__c, Case-to-WorkOrder relationship, and Trouble Ticket record type are absent in UAT."),
        ("Profile drift", "3 profiles", "Admin and API profile use unknown ArchiveArticles; Standard references the missing Trouble Ticket record type."),
        ("Quick Action cross-reference", "1 action", "Case.Create_Work_Order cannot resolve its Flow because the referenced Flow fails validation."),
    ]
    add_table(document, ["Failure group", "Affected", "Exact blocker"], failure_rows, [2450, 1600, 5310], status_column=1)

    add_heading(document, "3. Source and story defects", 2)
    defect_rows = [
        ("Order exception", "Blocker", "Order__c remains required=true; WorkOrder.Order_Required_Except_Trouble_Ticket does not exist."),
        ("WorkOrder layouts", "Changes requested", "Neither updated WorkOrder layout includes the five new SCC-3385 fields."),
        ("Component names", "Correct story", "Actual action is Case.Create_Work_Order; profile API names are Admin, Standard, and System Administrator - API Only."),
        ("Named Cases", "Blocked", "Cases 00001082 and 00001083 exist in neither authorized Great Plains sandbox."),
        ("Work Types", "Ready in UAT", "Comm Fiber, Resi Coax, Resi Copper, and Resi Fiber Trouble all exist in UAT."),
    ]
    add_table(document, ["Area", "Status", "Evidence"], defect_rows, [2200, 1900, 5260], status_column=1)

    document.add_page_break()
    add_heading(document, "Work Order creation architecture", 1)
    add_body(document, "The Flow contains most behavioral controls, but the target foundation and two source-side design elements prevent a complete end-to-end release.")
    add_figure(
        document,
        architecture_diagram,
        "Figure 2. SCC-3385 Work Order creation and dependency model",
        "Architecture diagram relating Trouble Ticket Case prerequisites, the Create Work Order Flow, WorkOrder fields, Case activity logging, duplicate prevention, WorkOrder layouts, and the preserved Book Appointment action. Blockers are shown in red or amber.",
        width=6.45,
    )
    add_body(
        document,
        "Architect interpretation: the Flow design covers gating, required inputs, duplicate detection, value mapping, and activity logging, but deployment and runtime acceptance remain blocked until the foundation and source defects are repaired.",
        bold_lead="Architect interpretation:",
    )

    document.add_page_break()
    add_heading(document, "Required approval gates", 1)
    gate_rows = [
        ("1", "Deploy SCC-3384 prerequisites", "Release manager", "Trouble Ticket record type plus Priority, Service Address, Service Type, Subscriber Report, and Work Order Case fields."),
        ("2", "Repair the Order exception", "Admin / Architect", "Make Order__c optional and add the active exception validation rule for non-Trouble Ticket Work Orders."),
        ("3", "Complete WorkOrder layouts", "Salesforce admin", "Place all five new fields on both WorkOrder layouts and retain Book Appointment."),
        ("4", "Narrow security payload", "Security owner", "Use a focused permission set or filtered profiles; remove ArchiveArticles and unrelated record-type drift."),
        ("5", "Prepare named UAT Cases", "QA / Business", "Create or identify Cases 00001082/00001083 equivalents with exact Account, address, service, report, priority, and notes."),
        ("6", "Revalidate and execute UAT", "QA / Release manager", "Require a clean 15/15 check-only result, then execute all six tests with IDs and screenshots."),
    ]
    add_table(document, ["Gate", "Required action", "Owner", "Evidence needed"], gate_rows, [850, 2500, 2000, 4010])

    add_heading(document, "Ready-to-paste architect response", 1)
    response = (
        "Architect dry run completed for SCC-3385 using GreatPlainsMerge as source and GreatPlainsUAT as the check-only target. Changes Requested / NO-GO: job 0AfEa00000bbQXhKAM was check-only and failed with 8 of 14 components; no metadata or records were changed. UAT is missing the Trouble Ticket record type and the SCC-3384 Case fields used by the Flow. In source, WorkOrder.Order__c remains required, the listed exception validation rule does not exist, and neither WorkOrder layout contains the five new fields. The Flow otherwise includes the record-type guard, required Work Type and Work Instructions, duplicate lookup/link, Case value mapping, completed Task logging, and the FSL Book Appointment action remains present. Complete the six approval gates above, prepare valid test Cases, and require a clean 15-of-15 validation plus all six UAT tests before promotion."
    )
    add_callout(document, "Story comment", response, fill=LIGHT_BLUE, accent=BLUE)

    add_heading(document, "Evidence boundary", 2)
    add_body(document, "This assessment combines source metadata retrieval, local structural review, read-only org queries, and a GreatPlainsUAT check-only deployment. No records, deployment, activation, quick deploy, or org metadata changes were performed.")

    document.core_properties.title = "SCC-3385 Create Work Order for Tickets Architect Review"
    document.core_properties.subject = "Source retrieval and check-only readiness assessment"
    document.core_properties.author = "Solution Architecture Review"
    document.core_properties.keywords = "Salesforce, Great Plains, SCC-3385, Work Order, architect review, dry run"
    document.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    build_document()
