from __future__ import annotations

import importlib.util
import io
from datetime import datetime, timezone
from pathlib import Path

from lxml import etree
from PIL import Image, ImageDraw


ROOT = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david")
BASE_PATH = ROOT / "review" / "SALDEV-1473" / "docx-build" / "build_saldev_1473_architect_review.py"
REFERENCE = ROOT / "output" / "documents" / "SALDEV-1475-architect-review.docx"
OUTPUT = ROOT / "review" / "SALDEV-1427-1371-architect-review" / "SALDEV-1427-1371_Architect_Review.docx"
EXPECTED_SHA256 = "B491A97DA9EC81D50922AE59C6796B3A7FE7CE7E5CDBE94E6402A4572F05141D"

spec = importlib.util.spec_from_file_location("flywire_review_base", BASE_PATH)
base = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(base)


def build_correction_diagram() -> bytes:
    canvas = Image.new("RGB", (1600, 1020), base.CANVAS)
    draw = ImageDraw.Draw(canvas)
    draw.text((65, 45), "SALDEV-1427 / 1371 | Current runtime path", font=base.font(38, True), fill=base.NAVY)
    draw.text((65, 95), "The implementation has useful structure, but release-critical contracts are incomplete.", font=base.font(21), fill=base.GRAY)

    top = 185
    width = 320
    gap = 55
    xs = [55, 55 + width + gap, 55 + 2 * (width + gap), 55 + 3 * (width + gap)]
    boxes = [
        ("Story intent", ["Clear ARR values", "Control QLE editability", "Keep lineage across groups", "Support stepped pricing"], base.BLUE, base.PALE_BLUE),
        ("QCP scripts", ["25-field ARR list", "Clone + calculate hooks", "Missing field dependencies", "Conflicting editability"], base.RED, base.RED_FILL),
        ("Apex mapping", ["Two bulk SOQL queries", "Before-save assignment", "Quote + Product key only", "Exceptions are swallowed"], base.AMBER, base.AMBER_FILL),
        ("Release proof", ["7 of 7 tests pass", "Handler coverage: 97%", "Trigger coverage: 43.59%", "Dry-run status: Failed"], base.RED, base.RED_FILL),
    ]
    for x, (title, items, stroke, fill) in zip(xs, boxes):
        base.draw_box(draw, (x, top, x + width, top + 430), title, items, stroke, fill)
    for i, label in enumerate(("configure", "invoke", "validate")):
        base.arrow(draw, xs[i] + width, top + 215, xs[i + 1], label)

    draw.rounded_rectangle((90, 725, 1510, 925), radius=24, fill=base.RED_FILL, outline=base.RED, width=4)
    draw.text((125, 758), "BLOCKER CONCENTRATION", font=base.font(25, True), fill=base.RED)
    message = (
        "The declared CPQ field dependencies do not match the JavaScript reads and writes; one referenced field does not exist; "
        "and the lineage key cannot distinguish duplicate products across group, bundle, or ship-to contexts."
    )
    base.draw_wrapped(draw, (125, 810), message, base.font(22, True), base.NAVY, 1340, 8)
    stream = io.BytesIO()
    canvas.save(stream, format="PNG", optimize=True)
    return stream.getvalue()


def build_architecture_diagram() -> bytes:
    canvas = Image.new("RGB", (1600, 1100), "#FFFFFF")
    draw = ImageDraw.Draw(canvas)
    draw.text((70, 45), "SALDEV-1427 / 1371 | Required release design", font=base.font(38, True), fill=base.NAVY)
    draw.text((70, 95), "One canonical data contract, deterministic lineage, visible failure, and layered tests", font=base.font(21), fill=base.GRAY)

    boxes = [
        (70, 210, 360, 575, "Canonical contract", ["One ARR field list", "Only real API names", "All QCP dependencies", "Explicit group fields"], base.BLUE, base.PALE_BLUE),
        (440, 210, 730, 575, "QLE policy", ["Ordered rule precedence", "First-group edit set", "Downstream lock set", "Ship-To decision signed"], base.GREEN, base.GREEN_FILL),
        (810, 210, 1100, 575, "Lineage key", ["Quote + source group", "Bundle/config context", "Ship-to context", "No silent fallback"], base.GREEN, base.GREEN_FILL),
        (1180, 210, 1530, 575, "Proof layers", ["JavaScript unit tests", "Exact Apex assertions", "75%+ trigger coverage", "Named QLE scenarios"], base.GREEN, base.GREEN_FILL),
    ]
    for x1, y1, x2, y2, title, items, stroke, fill in boxes:
        base.draw_box(draw, (x1, y1, x2, y2), title, items, stroke, fill)
    for i, label in enumerate(("govern", "correlate", "prove")):
        base.arrow(draw, boxes[i][2], 392, boxes[i + 1][0], label)

    draw.rounded_rectangle((100, 700, 760, 990), radius=22, fill=base.GREEN_FILL, outline=base.GREEN, width=4)
    draw.text((130, 735), "Retain", font=base.font(27, True), fill=base.NAVY)
    base.draw_bullets(draw, 135, 800, [
        "Bulk Set and Map processing",
        "Queries outside loops",
        "Before-save field assignment",
        "Trigger-to-handler delegation",
    ], base.font(20), base.NAVY, base.GREEN, 570, 54)

    draw.rounded_rectangle((840, 700, 1500, 990), radius=22, fill=base.RED_FILL, outline=base.RED, width=4)
    draw.text((870, 735), "Must close before promotion", font=base.font(27, True), fill=base.NAVY)
    base.draw_bullets(draw, 875, 800, [
        "Resolve NS ID and Ship-To rules",
        "Correct dependencies and field names",
        "Redesign deterministic mapping",
        "Pass check-only and QLE matrix",
    ], base.font(20), base.NAVY, base.RED, 570, 54)

    stream = io.BytesIO()
    canvas.save(stream, format="PNG", optimize=True)
    return stream.getvalue()


def set_image_alt_text(root) -> None:
    paragraphs = base.body_paragraphs(root)
    descriptions = {
        10: (
            "SALDEV-1427 and SALDEV-1371 current runtime path",
            "Diagram showing story intent flowing through two QCP scripts and Apex mapping into a failed check-only release gate, with dependency, editability, lineage, and coverage blockers.",
        ),
        24: (
            "SALDEV-1427 and SALDEV-1371 required release design",
            "Diagram showing a canonical field contract, ordered QLE policy, deterministic lineage key, layered tests, retained strengths, and mandatory completion gates.",
        ),
    }
    for index, (title, description) in descriptions.items():
        nodes = paragraphs[index].xpath(".//wp:docPr", namespaces=base.NS)
        if nodes:
            nodes[0].set("title", title)
            nodes[0].set("descr", description)


def patch_document(xml_bytes: bytes) -> bytes:
    root = etree.fromstring(xml_bytes)
    paragraphs = base.body_paragraphs(root)
    tables = base.body_tables(root)
    for index in (0, 2, 4, 5, 6, 7):
        base.mark_header_row(tables[index])

    replacements = {
        0: "ARCHITECT REVIEW",
        1: "SALDEV-1427 / SALDEV-1371 | QCP Clone Integrity",
        2: "FlywirePartial | Read-only CPQ JavaScript and Apex best-practice review",
        5: "Acceptance and quality outcome",
        8: "Runtime path and defect concentration",
        9: "The design correctly separates QLE JavaScript concerns from Apex lineage assignment, but the configuration contract, rule precedence, mapping identity, and release proof are not yet strong enough for promotion.",
        11: "Figure 1. Current implementation path and release-blocker concentration",
        14: "Detailed code and validation evidence",
        15: "1. Live component and runtime evidence",
        17: "2. Best-practice findings",
        19: "3. Test and validation evidence",
        22: "Required target architecture and proof model",
        23: "The release-ready design should centralize the ARR field contract, declare every QCP dependency, make editability precedence explicit, correlate lineage deterministically, and prove JavaScript plus Apex behavior independently.",
        25: "Figure 2. Required data contract, lineage design, and proof layers",
        26: "Architect interpretation: the code has a sound bulk-processing foundation, but configuration and identity semantics are part of the implementation. Passing handler tests cannot compensate for an invalid field, missing QCP dependencies, ambiguous lineage, or insufficient trigger coverage.",
        28: "Required completion gates",
        30: "Ready-to-paste architect response",
        32: "Evidence boundary",
        33: "Evidence: supplied story documents, verified FlywirePartial sandbox and custom scripts, retrieved Apex and field metadata, JavaScript syntax checks, focused tests, and check-only validation. No Salesforce record or metadata changes, deployment, activation, promotion, or Production action occurred.",
    }
    for index, text in replacements.items():
        base.set_paragraph_text(paragraphs[index], text)

    metadata = [
        ("Source", "FlywirePartial | Enterprise sandbox 00DhG0000000jOXUAY"),
        ("Scope", "2 QCP scripts | 1 trigger | 1 handler | 1 test class"),
        ("Review date", "4 September 2026"),
        ("Validation mode", "Live read-back | JS syntax | focused Apex tests | check-only"),
        ("Decision", "NO-GO — Changes Requested before QA or promotion"),
        ("Boundary", "Read-only review; no record, metadata, activation, or deployment changes"),
    ]
    for row, values in enumerate(metadata):
        base.set_cell(tables[0], row, 0, values[0])
        base.set_cell(tables[0], row, 1, values[1])

    base.set_callout(
        tables[1],
        "ARCHITECT DECISION",
        "Changes Requested. The implementation contains several good Apex practices, but it is not release-ready: QCP dependencies are incomplete, Domestic_Sponsor__c is not a real quote-line field, usage fields are simultaneously read-only and editable, lineage matching is ambiguous, and the check-only gate failed at 43.59% trigger coverage.",
        base.RED_FILL,
        base.RED,
    )

    acceptance = [
        ("#", "Scope", "Result", "Evidence"),
        ("1", "ARR fields cleared on clones", "NOT PROVEN", "Both scripts carry the nulling list, but clone dependencies omit all 25 fields and one API name is invalid."),
        ("2", "First ramp group editable", "PARTIAL", "An editable allowlist exists; no live QLE functional run was performed in this read-only review."),
        ("3", "Later groups restricted", "DEFECT", "The script reads group Source and Number, but only Allow Product Ramping is declared as a group dependency."),
        ("4", "Usage price remains editable", "FAIL", "Usage_Rate__c and Usage_Rate_Amt__c are also in the global read-only list, which executes first."),
        ("5", "Opportunity Line ID lineage", "HIGH RISK", "The map key is Quote + Product only and does not distinguish group, bundle, configuration, or ship-to context."),
        ("6", "Release test matrix", "FAIL", "No JavaScript unit evidence; Apex assertions miss the second-group result; check-only failed coverage."),
    ]
    for row, values in enumerate(acceptance):
        for col, text in enumerate(values):
            base.set_cell(tables[2], row, col, text)
    base.set_status(tables[2], 1, acceptance[1][2], "follow")
    base.set_status(tables[2], 2, acceptance[2][2], "follow")
    for row in (3, 4, 5, 6):
        base.set_status(tables[2], row, acceptance[row][2], "fail")

    base.set_callout(
        tables[3],
        "DESIGN READING",
        "Blue shows the intended contract. Green shows practices worth retaining. Amber marks incomplete proof. Red identifies issues that can create incorrect quote-line behavior or block release.",
    )

    live = [
        ("Evidence area", "Observed result", "Evidence"),
        ("Target org", "Verified sandbox", "FlywirePartial is org 00DhG0000000jOXUAY; Enterprise Edition; IsSandbox=true."),
        ("QCP_HideFieldInQLE", "Live runtime present", "1,999 JavaScript lines; transpiled runtime exists; syntax check passed."),
        ("QLE_CloneLineHandler", "Live runtime present", "58 JavaScript lines; clone hook and runtime exist; syntax check passed."),
        ("Apex runtime", "Bulk-structured", "Trigger delegates to a with-sharing handler using Sets, Maps, and two SOQL queries outside loops."),
        ("Field read-back", "24 of 25 found", "Domestic_Sponsor__c does not exist; Processed_Volume_Amount__c is correctly excluded."),
    ]
    for row, values in enumerate(live):
        for col, text in enumerate(values):
            base.set_cell(tables[4], row, col, text)

    practices = [
        ("Finding", "Severity", "Evidence"),
        ("Dependency contract", "BLOCKER", "Clone script declares only NS ID and Opportunity Line ID; QCP omits required line and group fields."),
        ("Rule precedence", "BLOCKER", "Two usage-rate fields appear in both global read-only and editable-ramping sets; read-only wins."),
        ("Lineage determinism", "HIGH", "Quote + Product occurrence order can cross bundles or ship-to groups; fallback reuses the first master ID."),
    ]
    for row, values in enumerate(practices):
        for col, text in enumerate(values):
            base.set_cell(tables[5], row, col, text)
    for row in (1, 2, 3):
        base.set_cell_fill(tables[5], row, 1, base.RED_FILL)
        base.set_cell_text_style(tables[5], row, 1, base.RED, True)

    validation = [
        ("Test / boundary", "Status", "Evidence"),
        ("Focused Apex suite", "PASS", "7 of 7 QuoteLineTriggerHandlerTest methods passed; zero test failures."),
        ("Handler coverage", "PASS", "QuoteLineTriggerHandler measured 97%; this supports the bulk-structured handler implementation."),
        ("Trigger coverage", "FAIL", "QuoteLineTrigger measured 43.59%; Salesforce requires at least 75% for the selected trigger."),
        ("Check-only package", "FAILED", "0AfhG000001da33SAA: 3/3 components, 7/7 tests, but coverage gate failed; nothing deployed."),
        ("Behavior proof", "MISSING", "No JavaScript unit suite or live QLE scenario matrix; the second-group Apex outcome is not asserted."),
    ]
    for row, values in enumerate(validation):
        for col, text in enumerate(values):
            base.set_cell(tables[6], row, col, text)
    for row in (1, 2):
        base.set_cell_fill(tables[6], row, 1, base.GREEN_FILL)
        base.set_cell_text_style(tables[6], row, 1, base.GREEN, True)
    for row in (3, 4, 5):
        base.set_cell_fill(tables[6], row, 1, base.RED_FILL)
        base.set_cell_text_style(tables[6], row, 1, base.RED, True)

    gates = [
        ("Gate", "Required action", "Owner", "Evidence needed"),
        ("1", "Correct field names and QCP dependencies", "CPQ Developer", "All referenced line/group APIs exist and are declared; remove Domestic_Sponsor__c or map it correctly."),
        ("2", "Make editability precedence explicit", "CPQ Developer", "Usage price fields are editable only where intended; tests cover first and downstream groups."),
        ("3", "Redesign lineage correlation", "Apex Developer", "A deterministic source/group/bundle/ship-to key; no first-ID fallback; visible failure behavior."),
        ("4", "Resolve story semantics", "Product Owner", "Signed decision for NS ID, Ship-To locking, amendment scope, and the SALDEV-1404 dependency."),
        ("5", "Add exact automated tests", "Developer / QA", "JavaScript hook tests plus Apex assertions for every group, duplicate product, bundle, ship-to, and 200-line case."),
        ("6", "Re-run release and QLE proof", "Dev Lead / QA", "75%+ trigger coverage, successful check-only, and named SUP/non-SUP multi-group functional read-back."),
    ]
    for row, values in enumerate(gates):
        for col, text in enumerate(values):
            base.set_cell(tables[7], row, col, text)

    story = (
        "Architect review completed for SALDEV-1427 and duplicate SALDEV-1371 in FlywirePartial. Decision: Changes Requested / NO-GO before QA or promotion. Strengths: both QCP scripts pass syntax checks; the with-sharing handler uses bulk Sets and Maps with queries outside loops; 7 of 7 focused tests passed; and handler coverage is 97%. Blockers: QLE_CloneLineHandler declares only NS ID and Opportunity Line ID although it writes the ARR set; QCP_HideFieldInQLE omits required line and group dependencies; Domestic_Sponsor__c is not a quote-line field; usage-rate fields are both globally read-only and ramp-editable; and lineage uses only Quote + Product, allowing cross-group, bundle, or ship-to mismatches. Exceptions are swallowed. Check-only 0AfhG000001da33SAA validated 3 of 3 components and ran 7 passing tests, but failed because trigger coverage is 43.59%, below 75%. Nothing deployed. Resolve the NS ID, Ship-To, and amendment requirements; correct dependencies and API names; redesign deterministic mapping; add JavaScript and exact Apex assertions; reach 75%+ trigger coverage; and complete the named QLE matrix before resubmission."
    )
    base.set_callout(tables[8], "STORY COMMENT", story, base.PALE_BLUE, base.BLUE)

    set_image_alt_text(root)
    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)


def patch_core(xml_bytes: bytes) -> bytes:
    ns = {"dc": base.DC_NS, "cp": base.CP_NS, "dcterms": base.DCTERMS_NS}
    root = etree.fromstring(xml_bytes)
    values = {
        ("dc", "title"): "SALDEV-1427 and SALDEV-1371 QCP Clone Integrity Architect Review",
        ("dc", "subject"): "Read-only Salesforce CPQ JavaScript and Apex best-practice assessment",
        ("cp", "keywords"): "Salesforce, Flywire, SALDEV-1427, SALDEV-1371, CPQ, QCP, Apex, architect review",
        ("dc", "description"): "Combined best-practice review derived from the established Flywire architect-review format.",
    }
    for (prefix, local), value in values.items():
        node = root.find(f"{prefix}:{local}", ns)
        if node is not None:
            node.text = value
    modified = root.find("dcterms:modified", ns)
    if modified is not None:
        modified.text = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        modified.set(f"{{{base.XSI_NS}}}type", "dcterms:W3CDTF")
    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)


if __name__ == "__main__":
    base.REFERENCE = REFERENCE
    base.OUTPUT = OUTPUT
    base.EXPECTED_SHA256 = EXPECTED_SHA256
    base.build_correction_diagram = build_correction_diagram
    base.build_architecture_diagram = build_architecture_diagram
    base.patch_document = patch_document
    base.patch_core = patch_core
    base.main()
