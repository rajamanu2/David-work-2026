from __future__ import annotations

import hashlib
import importlib.util
import io
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from lxml import etree
from PIL import Image, ImageDraw


ROOT = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david")
TASK = ROOT / "review" / "SALDEV-1427-1371-architect-review"
REFERENCE = ROOT / "output" / "documents" / "SALDEV-1475-architect-review.docx"
EXPECTED_SHA256 = "B491A97DA9EC81D50922AE59C6796B3A7FE7CE7E5CDBE94E6402A4572F05141D"
OUTPUT_1427 = TASK / "SALDEV-1427_Architect_Review.docx"
OUTPUT_1371 = TASK / "SALDEV-1371_Architect_Review.docx"

combined_path = TASK / "build_review.py"
spec = importlib.util.spec_from_file_location("combined_review", combined_path)
combined = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(combined)
base = combined.base


def flow_diagram(ticket: str, subtitle: str, boxes, banner_title: str, banner_text: str) -> bytes:
    canvas = Image.new("RGB", (1600, 1020), base.CANVAS)
    draw = ImageDraw.Draw(canvas)
    draw.text((65, 45), f"{ticket} | Current runtime path", font=base.font(38, True), fill=base.NAVY)
    draw.text((65, 95), subtitle, font=base.font(21), fill=base.GRAY)
    top, width, gap = 185, 320, 55
    xs = [55, 55 + width + gap, 55 + 2 * (width + gap), 55 + 3 * (width + gap)]
    for x, (title, items, stroke, fill) in zip(xs, boxes):
        base.draw_box(draw, (x, top, x + width, top + 430), title, items, stroke, fill)
    for index, label in enumerate(("configure", "execute", "prove")):
        base.arrow(draw, xs[index] + width, top + 215, xs[index + 1], label)
    draw.rounded_rectangle((90, 725, 1510, 925), radius=24, fill=base.RED_FILL, outline=base.RED, width=4)
    draw.text((125, 758), banner_title, font=base.font(25, True), fill=base.RED)
    base.draw_wrapped(draw, (125, 810), banner_text, base.font(22, True), base.NAVY, 1340, 8)
    stream = io.BytesIO()
    canvas.save(stream, format="PNG", optimize=True)
    return stream.getvalue()


def target_diagram(ticket: str, subtitle: str, boxes, retain_items, close_items) -> bytes:
    canvas = Image.new("RGB", (1600, 1100), "#FFFFFF")
    draw = ImageDraw.Draw(canvas)
    draw.text((70, 45), f"{ticket} | Required release design", font=base.font(38, True), fill=base.NAVY)
    draw.text((70, 95), subtitle, font=base.font(21), fill=base.GRAY)
    positions = [
        (70, 210, 360, 575),
        (440, 210, 730, 575),
        (810, 210, 1100, 575),
        (1180, 210, 1530, 575),
    ]
    for rect, (title, items, stroke, fill) in zip(positions, boxes):
        base.draw_box(draw, rect, title, items, stroke, fill)
    for index, label in enumerate(("govern", "execute", "prove")):
        base.arrow(draw, positions[index][2], 392, positions[index + 1][0], label)
    draw.rounded_rectangle((100, 700, 760, 990), radius=22, fill=base.GREEN_FILL, outline=base.GREEN, width=4)
    draw.text((130, 735), "Retain", font=base.font(27, True), fill=base.NAVY)
    base.draw_bullets(draw, 135, 800, retain_items, base.font(20), base.NAVY, base.GREEN, 570, 54)
    draw.rounded_rectangle((840, 700, 1500, 990), radius=22, fill=base.RED_FILL, outline=base.RED, width=4)
    draw.text((870, 735), "Must close before promotion", font=base.font(27, True), fill=base.NAVY)
    base.draw_bullets(draw, 875, 800, close_items, base.font(20), base.NAVY, base.RED, 570, 54)
    stream = io.BytesIO()
    canvas.save(stream, format="PNG", optimize=True)
    return stream.getvalue()


def diagrams_1427():
    first = flow_diagram(
        "SALDEV-1427",
        "Stepped-pricing controls span QCP configuration, QLE policy, Apex lineage, and the release gate.",
        [
            ("Story intent", ["Clear ARR on clones", "Control QLE editability", "Keep cross-group lineage", "Cover stepped pricing"], base.BLUE, base.PALE_BLUE),
            ("QCP scripts", ["Clone + calculate hooks", "25-field ARR list", "Missing dependencies", "Conflicting editability"], base.RED, base.RED_FILL),
            ("Apex lineage", ["Bulk Sets and Maps", "Two SOQL queries", "Quote + Product key", "Exceptions swallowed"], base.AMBER, base.AMBER_FILL),
            ("Release proof", ["7 of 7 tests pass", "Handler coverage 97%", "Trigger coverage 43.59%", "Dry run failed"], base.RED, base.RED_FILL),
        ],
        "BLOCKER CONCENTRATION",
        "The QCP dependency contract is incomplete, usage editability is contradictory, and the lineage key cannot distinguish duplicate products across group, bundle, or ship-to contexts.",
    )
    second = target_diagram(
        "SALDEV-1427",
        "A canonical field contract, ordered policy, deterministic lineage key, and layered tests",
        [
            ("Canonical contract", ["One ARR field list", "Only real API names", "All line dependencies", "All group dependencies"], base.BLUE, base.PALE_BLUE),
            ("QLE policy", ["Explicit rule order", "First-group edit set", "Downstream lock set", "Ship-To rule signed"], base.GREEN, base.GREEN_FILL),
            ("Lineage key", ["Quote + source group", "Bundle/config context", "Ship-to context", "No silent fallback"], base.GREEN, base.GREEN_FILL),
            ("Proof layers", ["JavaScript unit tests", "Exact Apex assertions", "75%+ trigger coverage", "Named QLE scenarios"], base.GREEN, base.GREEN_FILL),
        ],
        ["Bulk Set and Map processing", "Queries outside loops", "Before-save assignment", "Trigger-to-handler delegation"],
        ["Resolve NS ID and Ship-To", "Fix dependencies and APIs", "Redesign lineage mapping", "Pass dry run and QLE matrix"],
    )
    return first, second


def diagrams_1371():
    first = flow_diagram(
        "SALDEV-1371",
        "The acceptance criterion is database nulling after non-stepped clone actions, not QLE visibility alone.",
        [
            ("Story intent", ["Prevent ARR inflation", "Non-stepped quote", "Seven named fields", "Verify outside QLE"], base.BLUE, base.PALE_BLUE),
            ("Clone handler", ["58-line JavaScript", "Seven fields included", "Syntax check passes", "Dependencies incomplete"], base.RED, base.RED_FILL),
            ("Scope control", ["Broader 25-field list", "Duplicated in QCP", "Extra API mismatch", "Approval not evidenced"], base.AMBER, base.AMBER_FILL),
            ("Acceptance proof", ["Save direct line clone", "Assert seven nulls", "Check Add Products", "Re-run ARR Flow"], base.RED, base.RED_FILL),
        ],
        "ACCEPTANCE NOT PROVEN",
        "The seven required null assignments are present, but those fields are absent from the clone script dependencies and no saved quote-line read-back proves the values are null or the ARR regression is fixed.",
    )
    second = target_diagram(
        "SALDEV-1371",
        "The clone contract must be schema-valid and proven on saved quote-line records",
        [
            ("Seven-field contract", ["Verified API names", "Approved ticket scope", "Single shared definition", "Declared dependencies"], base.BLUE, base.PALE_BLUE),
            ("Clone-time clear", ["Direct line clone", "Null before save", "Source stays intact", "Visible error handling"], base.GREEN, base.GREEN_FILL),
            ("Record read-back", ["Open quote-line detail", "Assert seven fields null", "Check Add Products", "Capture evidence"], base.GREEN, base.GREEN_FILL),
            ("Regression proof", ["Non-SUP line matrix", "SALDEV-1351 scenario", "ARR Flow outcome", "JavaScript unit tests"], base.GREEN, base.GREEN_FILL),
        ],
        ["Dedicated clone handler", "Seven APIs exist", "Both scripts parse", "Add Products is distinct"],
        ["Declare seven dependencies", "Control the broader scope", "Add JavaScript tests", "Capture saved-record proof"],
    )
    return first, second


def set_alt_text(root, first_title: str, first_descr: str, second_title: str, second_descr: str) -> None:
    paragraphs = base.body_paragraphs(root)
    for index, title, description in (
        (10, first_title, first_descr),
        (24, second_title, second_descr),
    ):
        nodes = paragraphs[index].xpath(".//wp:docPr", namespaces=base.NS)
        if nodes:
            nodes[0].set("title", title)
            nodes[0].set("descr", description)


def set_table(table, rows) -> None:
    for row_index, row in enumerate(rows):
        for column_index, value in enumerate(row):
            base.set_cell(table, row_index, column_index, value)


def patch_1427(xml_bytes: bytes) -> bytes:
    root = etree.fromstring(combined.patch_document(xml_bytes))
    paragraphs, tables = base.body_paragraphs(root), base.body_tables(root)
    replacements = {
        1: "SALDEV 1427 QCP Cloning Logic Architect Review",
        2: "FlywirePartial | Read-only stepped-pricing JavaScript and Apex best-practice review",
        5: "Acceptance and quality outcome",
        8: "Runtime path and defect concentration",
        9: "SALDEV-1427 spans QCP configuration, QLE editability, and Apex Opportunity Line ID lineage. The code has a useful bulk-processing base, but several runtime contracts and the release gate remain incomplete.",
        11: "Figure 1. SALDEV-1427 implementation path and release blockers",
        22: "Required target architecture and proof model",
        23: "The release-ready design should centralize the ARR field contract, declare every QCP dependency, make editability precedence explicit, correlate lineage deterministically, and prove JavaScript and Apex behavior independently.",
        25: "Figure 2. SALDEV-1427 required data contract, lineage design, and proof layers",
        26: "Architect interpretation: the Apex handler is bulk-structured, but QCP configuration and identity semantics are executable parts of the solution. Passing handler tests cannot compensate for missing dependencies, contradictory rules, ambiguous lineage, or insufficient trigger coverage.",
        33: "Evidence: the SALDEV-1427 source document, verified FlywirePartial sandbox and scripts, retrieved Apex and field metadata, syntax checks, focused tests, and check-only validation. No Salesforce record or metadata changes, deployment, activation, promotion, or Production action occurred.",
    }
    for index, value in replacements.items():
        base.set_paragraph_text(paragraphs[index], value)

    set_table(tables[0], [
        ("Source", "SALDEV-1427 | FlywirePartial Enterprise sandbox 00DhG0000000jOXUAY"),
        ("Scope", "2 QCP scripts | 1 trigger | 1 handler | 1 test class"),
        ("Review date", "4 September 2026"),
        ("Validation mode", "Live read-back | JS syntax | focused Apex tests | check-only"),
        ("Decision", "NO-GO - Changes Requested before QA or promotion"),
        ("Boundary", "Read-only review; no record, metadata, activation, or deployment changes"),
    ])
    base.set_callout(
        tables[1], "ARCHITECT DECISION",
        "Changes Requested. SALDEV-1427 is not release-ready: QCP dependencies are incomplete, Domestic_Sponsor__c is not a real quote-line field, usage fields are simultaneously read-only and editable, lineage matching is ambiguous, and check-only failed at 43.59% trigger coverage.",
        base.RED_FILL, base.RED,
    )
    set_table(tables[2], [
        ("#", "Scope", "Result", "Evidence"),
        ("1", "ARR values cleared on SUP clones", "NOT PROVEN", "Nulling lists exist, but dependencies omit the fields and one API name is invalid."),
        ("2", "First group remains editable", "PARTIAL", "An editable allowlist exists; no live QLE functional run was performed."),
        ("3", "Later groups are restricted", "DEFECT", "The script reads group Source and Number, but they are not declared dependencies."),
        ("4", "Usage price fields editable", "FAIL", "Usage_Rate__c and Usage_Rate_Amt__c are also globally read-only; that rule wins."),
        ("5", "Opportunity Line ID lineage", "HIGH RISK", "Quote + Product cannot distinguish group, bundle, configuration, or ship-to context."),
        ("6", "Required scenario matrix", "FAIL", "No JavaScript unit evidence; Apex assertions miss Group 2; check-only failed coverage."),
    ])
    base.set_status(tables[2], 1, "NOT PROVEN", "follow")
    base.set_status(tables[2], 2, "PARTIAL", "follow")
    for row, status in ((3, "DEFECT"), (4, "FAIL"), (5, "HIGH RISK"), (6, "FAIL")):
        base.set_status(tables[2], row, status, "fail")

    set_table(tables[4], [
        ("Evidence area", "Observed result", "Evidence"),
        ("Target org", "Verified sandbox", "FlywirePartial is org 00DhG0000000jOXUAY; Enterprise Edition; IsSandbox=true."),
        ("QCP_HideFieldInQLE", "Runtime present", "1,999 JavaScript lines; transpiled runtime exists; syntax check passed."),
        ("QLE_CloneLineHandler", "Runtime present", "58 JavaScript lines; clone hook and runtime exist; syntax check passed."),
        ("Apex runtime", "Bulk-structured", "Trigger delegates to a with-sharing handler using Sets, Maps, and two SOQL queries outside loops."),
        ("Field read-back", "24 of 25 found", "Domestic_Sponsor__c does not exist; Processed_Volume_Amount__c is correctly excluded."),
    ])
    set_table(tables[5], [
        ("Finding", "Severity", "Evidence"),
        ("Dependency contract", "BLOCKER", "Clone script omits all ARR dependencies; QCP omits required line and group dependencies."),
        ("Rule precedence", "BLOCKER", "Two usage fields are both globally read-only and ramp-editable; read-only executes first."),
        ("Lineage determinism", "HIGH", "Occurrence order can cross bundles or ship-to groups; fallback reuses the first master ID."),
    ])
    for row in (1, 2, 3):
        base.set_cell_fill(tables[5], row, 1, base.RED_FILL)
        base.set_cell_text_style(tables[5], row, 1, base.RED, True)
    set_table(tables[6], [
        ("Test / boundary", "Status", "Evidence"),
        ("Focused Apex suite", "PASS", "7 of 7 QuoteLineTriggerHandlerTest methods passed; zero failures."),
        ("Handler coverage", "PASS", "QuoteLineTriggerHandler measured 97%."),
        ("Trigger coverage", "FAIL", "QuoteLineTrigger measured 43.59%; Salesforce requires at least 75%."),
        ("Check-only package", "FAILED", "0AfhG000001da33SAA: 3/3 components and 7/7 tests, but coverage failed; nothing deployed."),
        ("Behavior proof", "MISSING", "No JavaScript suite or live QLE matrix; the second-group Apex outcome is not asserted."),
    ])
    for row in (1, 2):
        base.set_cell_fill(tables[6], row, 1, base.GREEN_FILL)
        base.set_cell_text_style(tables[6], row, 1, base.GREEN, True)
    for row in (3, 4, 5):
        base.set_cell_fill(tables[6], row, 1, base.RED_FILL)
        base.set_cell_text_style(tables[6], row, 1, base.RED, True)
    set_table(tables[7], [
        ("Gate", "Required action", "Owner", "Evidence needed"),
        ("1", "Correct APIs and QCP dependencies", "CPQ Developer", "All line/group APIs exist and are declared; remove or correctly map Domestic_Sponsor__c."),
        ("2", "Make editability precedence explicit", "CPQ Developer", "Usage fields work as intended in first and downstream groups."),
        ("3", "Redesign lineage correlation", "Apex Developer", "Deterministic source/group/bundle/ship-to key; no silent fallback."),
        ("4", "Resolve story semantics", "Product Owner", "Signed NS ID, Ship-To, amendment, and SALDEV-1404 dependency decisions."),
        ("5", "Add exact automated tests", "Developer / QA", "JavaScript tests plus Apex assertions for every group, duplicate product, bundle, and ship-to case."),
        ("6", "Re-run release and QLE proof", "Dev Lead / QA", "75%+ trigger coverage, successful check-only, and named SUP functional read-back."),
    ])
    base.set_callout(
        tables[8], "STORY COMMENT",
        "Architect review completed for SALDEV-1427 in FlywirePartial. Decision: Changes Requested / NO-GO before QA or promotion. Both QCP scripts pass syntax checks; the with-sharing Apex handler is bulk-structured; 7 of 7 focused tests passed; and handler coverage is 97%. Blockers remain: incomplete QCP dependencies, nonexistent Domestic_Sponsor__c, conflicting usage-field editability, ambiguous Quote + Product lineage, swallowed exceptions, and missing JavaScript and exact Group 2 assertions. Check-only 0AfhG000001da33SAA validated 3 of 3 components and ran 7 passing tests, but failed because QuoteLineTrigger coverage is 43.59%, below 75%. Nothing deployed. Resolve requirements, correct the field contract, redesign deterministic mapping, add the missing tests, pass check-only, and complete the named stepped-pricing QLE matrix before resubmission.",
        base.PALE_BLUE, base.BLUE,
    )
    set_alt_text(
        root,
        "SALDEV-1427 current runtime path",
        "Diagram showing story intent, QCP scripts, Apex lineage, and release proof with dependency, editability, mapping, and coverage blockers.",
        "SALDEV-1427 required release design",
        "Diagram showing a canonical field contract, ordered QLE policy, deterministic lineage key, layered tests, retained strengths, and completion gates.",
    )
    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)


def patch_1371(xml_bytes: bytes) -> bytes:
    root = etree.fromstring(combined.patch_document(xml_bytes))
    paragraphs, tables = base.body_paragraphs(root), base.body_tables(root)
    replacements = {
        1: "SALDEV 1371 ARR Clone Data Integrity Architect Review",
        2: "FlywirePartial | Read-only non-stepped quote-line cloning best-practice review",
        5: "Acceptance and quality outcome",
        8: "Clone path and missing acceptance proof",
        9: "SALDEV-1371 requires ARR values to be null on saved cloned quote-line records for non-stepped quoting. Hiding fields in QLE is not acceptance evidence; database read-back and the SALDEV-1351 regression outcome are required.",
        11: "Figure 1. SALDEV-1371 clone path and evidence gap",
        14: "Detailed code and validation evidence",
        15: "1. Story and live runtime evidence",
        17: "2. Best-practice findings",
        19: "3. Acceptance evidence and boundaries",
        22: "Required clone-data architecture and proof model",
        23: "A release-ready solution should use the seven verified ticket fields, clear them once during direct quote-line cloning, preserve the source and Add Products behavior, and prove saved values outside QLE.",
        25: "Figure 2. SALDEV-1371 required clone contract and record-level proof",
        26: "Architect interpretation: the seven required API names exist and the nulling intent is visible, but a complete runtime dependency contract and saved-record proof are mandatory. SALDEV-1427 is the linked delivery vehicle; its Apex evidence does not validate this JavaScript criterion.",
        28: "Completion gates",
        30: "Ready-to-paste architect response",
        32: "Evidence boundary",
        33: "Evidence: the SALDEV-1371 source document, verified FlywirePartial sandbox and scripts, seven-field schema read-back, and syntax checks. No cloned records were created or saved, and no Salesforce record or metadata changes, deployment, activation, promotion, or Production action occurred.",
    }
    for index, value in replacements.items():
        base.set_paragraph_text(paragraphs[index], value)

    set_table(tables[0], [
        ("Source", "SALDEV-1371 | FlywirePartial Enterprise sandbox 00DhG0000000jOXUAY"),
        ("Scope", "2 QCP scripts | 7 required ARR fields | non-stepped direct line cloning"),
        ("Review date", "4 September 2026"),
        ("Validation mode", "Live script read-back | seven-field schema | JavaScript syntax"),
        ("Decision", "NO-GO - Changes Requested before story closure"),
        ("Boundary", "Read-only review; no clone execution, record save, metadata edit, or deployment"),
    ])
    base.set_callout(
        tables[1], "ARCHITECT DECISION",
        "Changes Requested. SALDEV-1371 cannot be closed from code presence alone. Although all seven ticket field APIs exist and the null assignments are present, the clone script omits those fields from its dependency declaration and no saved quote-line read-back or SALDEV-1351 regression proves the ARR values are null outside QLE.",
        base.RED_FILL, base.RED,
    )
    set_table(tables[2], [
        ("#", "Scope", "Result", "Evidence"),
        ("1", "Seven-field nulling logic exists", "IMPLEMENTED", "The clone handler includes all seven ticket fields; JavaScript syntax passes."),
        ("2", "Seven ticket APIs are valid", "PASS", "All seven required API names exist on SBQQ__QuoteLine__c."),
        ("3", "Runtime dependencies are complete", "FAIL", "The clone script declares only NS ID and Opportunity Line ID, not the seven fields it writes."),
        ("4", "Saved clone values are null", "NOT PROVEN", "No record-detail or SOQL read-back was performed for a cloned non-SUP line."),
        ("5", "Direct line clone is covered", "MISSING", "No functional test proves the explicit non-stepped quote-line clone path."),
        ("6", "SALDEV-1351 regression passes", "MISSING", "The APAC ARR Flow outcome was not re-tested after a clone save."),
    ])
    base.set_status(tables[2], 1, "IMPLEMENTED", "pass")
    base.set_status(tables[2], 2, "PASS", "pass")
    base.set_status(tables[2], 3, "FAIL", "fail")
    base.set_status(tables[2], 4, "NOT PROVEN", "follow")
    base.set_status(tables[2], 5, "MISSING", "fail")
    base.set_status(tables[2], 6, "MISSING", "fail")

    base.set_callout(
        tables[3], "DESIGN READING",
        "Blue shows the non-stepped clone acceptance path. Green shows code characteristics worth retaining. Amber marks incomplete evidence. Red identifies schema or proof defects that block story closure.",
    )
    set_table(tables[4], [
        ("Evidence area", "Observed result", "Evidence"),
        ("Story status", "Duplicate", "SALDEV-1371 states the requirement is handled with SALDEV-1427."),
        ("Target org", "Verified sandbox", "FlywirePartial is org 00DhG0000000jOXUAY; Enterprise Edition; IsSandbox=true."),
        ("QLE_CloneLineHandler", "Runtime present", "58 JavaScript lines; all seven ticket fields appear; syntax check passed."),
        ("QCP_HideFieldInQLE", "Related runtime", "The before-calculate path repeats a broader ARR list; syntax check passed."),
        ("Field read-back", "7 of 7 found", "Est_Annual_MM__c; Estimated_Volume__c; Annual_Number_of_Domestic_Transactions__c; Annual_Total_CC_Volume__c; Annual_No_Surcharge_Transactions__c; Annual_Total_Surcharge_Volume__c; Utilization__c."),
    ])
    set_table(tables[5], [
        ("Finding", "Severity", "Evidence"),
        ("Dependency contract", "BLOCKER", "The seven fields written by the clone handler are absent from SBQQ__QuoteLineFields__c."),
        ("Scope control", "HIGH", "The implementation clears a broader 25-field set; approval for that expansion is not evidenced by SALDEV-1371."),
        ("Maintainability", "HIGH", "The broader ARR list is duplicated across scripts, creating drift and execution-order risk."),
    ])
    for row in (1, 2, 3):
        base.set_cell_fill(tables[5], row, 1, base.RED_FILL)
        base.set_cell_text_style(tables[5], row, 1, base.RED, True)
    set_table(tables[6], [
        ("Test / boundary", "Status", "Evidence"),
        ("JavaScript syntax", "PASS", "Both live scripts parse successfully with Node syntax checks."),
        ("Seven-field schema", "PASS", "All seven API names in SALDEV-1371 were found in the live quote-line schema."),
        ("Delivery evidence boundary", "CONTEXT", "SALDEV-1427 Apex tests do not execute or prove the JavaScript clone hook."),
        ("JavaScript unit proof", "MISSING", "No automated test demonstrates each ARR field changes from populated to null."),
        ("Record-level acceptance", "MISSING", "No saved non-SUP clone was checked outside QLE or against the ARR Flow outcome."),
    ])
    for row in (1, 2):
        base.set_cell_fill(tables[6], row, 1, base.GREEN_FILL)
        base.set_cell_text_style(tables[6], row, 1, base.GREEN, True)
    base.set_cell_fill(tables[6], 3, 1, base.AMBER_FILL)
    base.set_cell_text_style(tables[6], 3, 1, base.AMBER, True)
    for row in (4, 5):
        base.set_cell_fill(tables[6], row, 1, base.RED_FILL)
        base.set_cell_text_style(tables[6], row, 1, base.RED, True)
    set_table(tables[7], [
        ("Gate", "Required action", "Owner", "Evidence needed"),
        ("1", "Confirm seven-field story scope", "Product Owner", "Approve the seven fields and separately govern any broader nulling behavior."),
        ("2", "Declare all seven dependencies", "CPQ Developer", "The clone script exposes every SALDEV-1371 field it writes."),
        ("3", "Centralize nulling logic", "CPQ Developer", "One canonical field definition and one clear mutation path with visible errors."),
        ("4", "Add JavaScript unit tests", "Developer", "Populated-to-null assertions for all seven fields; source values remain intact."),
        ("5", "Run non-SUP line-clone test", "CPQ QA", "Saved clone shows seven nulls outside QLE; Add Products remains unchanged."),
        ("6", "Re-test SALDEV-1351 outcome", "CPQ QA / RevOps", "The clone no longer inflates ARR and the background Flow result is correct."),
    ])
    base.set_callout(
        tables[8], "STORY COMMENT",
        "Architect review completed for SALDEV-1371 in FlywirePartial. Decision: Changes Requested / NO-GO for story closure. All seven ticket field APIs exist, the live QLE_CloneLineHandler includes null assignments for them, and both related scripts pass JavaScript syntax checks. However, the clone script declares only NS ID and Opportunity Line ID rather than the seven fields it writes; the implementation expands to a broader 25-field list without approval evidenced in this story; the list is duplicated across scripts; and no JavaScript unit or saved-record evidence proves a non-stepped quote-line clone has null values outside QLE. SALDEV-1427 is the linked delivery vehicle, but its Apex evidence does not execute this JavaScript path. Confirm scope, declare all seven dependencies, centralize the field contract, add exact tests, verify the saved clone and Add Products control, and re-run the SALDEV-1351 ARR regression before closing the duplicate. No deployment or Salesforce change occurred.",
        base.PALE_BLUE, base.BLUE,
    )
    set_alt_text(
        root,
        "SALDEV-1371 clone path and evidence gap",
        "Diagram showing the seven-field story intent, clone handler, broader scope-control concern, and missing saved-record acceptance proof.",
        "SALDEV-1371 required clone-data design",
        "Diagram showing the seven-field contract, direct clone-time clearing, record read-back, regression proof, retained strengths, and closure gates.",
    )
    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)


def patch_core(xml_bytes: bytes, ticket: str, title: str, subject: str) -> bytes:
    ns = {"dc": base.DC_NS, "cp": base.CP_NS, "dcterms": base.DCTERMS_NS}
    root = etree.fromstring(xml_bytes)
    values = {
        ("dc", "title"): title,
        ("dc", "subject"): subject,
        ("cp", "keywords"): f"Salesforce, Flywire, {ticket}, CPQ, QCP, architect review",
        ("dc", "description"): "Standalone best-practice review derived from the established Flywire architect-review format.",
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


def write_doc(output: Path, patch_fn, diagrams, ticket: str, title: str, subject: str) -> None:
    if base.sha256(REFERENCE) != EXPECTED_SHA256:
        raise RuntimeError("Reference SHA-256 mismatch")
    editable = {"word/document.xml", "word/media/image3.png", "word/media/image4.png", "docProps/core.xml"}
    fd, temp_name = tempfile.mkstemp(prefix=ticket.lower().replace("-", "_"), suffix=".docx", dir=str(output.parent))
    os.close(fd)
    temp_path = Path(temp_name)
    try:
        with ZipFile(REFERENCE, "r") as source, ZipFile(temp_path, "w", compression=ZIP_DEFLATED) as target:
            for item in source.infolist():
                data = source.read(item.filename)
                if item.filename == "word/document.xml":
                    data = patch_fn(data)
                elif item.filename == "word/media/image3.png":
                    data = diagrams[0]
                elif item.filename == "word/media/image4.png":
                    data = diagrams[1]
                elif item.filename == "docProps/core.xml":
                    data = patch_core(data, ticket, title, subject)
                target.writestr(item, data)
        with ZipFile(REFERENCE, "r") as source, ZipFile(temp_path, "r") as final:
            if source.namelist() != final.namelist():
                raise RuntimeError(f"{ticket}: package part inventory changed")
            for name in source.namelist():
                if name not in editable:
                    if hashlib.sha256(source.read(name)).digest() != hashlib.sha256(final.read(name)).digest():
                        raise RuntimeError(f"{ticket}: preserve-only part changed: {name}")
        os.replace(temp_path, output)
    finally:
        if temp_path.exists():
            temp_path.unlink()
    print(output)


def main() -> None:
    TASK.mkdir(parents=True, exist_ok=True)
    write_doc(
        OUTPUT_1427, patch_1427, diagrams_1427(), "SALDEV-1427",
        "SALDEV 1427 QCP Cloning Logic Architect Review",
        "Read-only stepped-pricing JavaScript and Apex best-practice assessment",
    )
    write_doc(
        OUTPUT_1371, patch_1371, diagrams_1371(), "SALDEV-1371",
        "SALDEV 1371 ARR Clone Data Integrity Architect Review",
        "Read-only non-stepped quote-line cloning best-practice assessment",
    )


if __name__ == "__main__":
    main()
