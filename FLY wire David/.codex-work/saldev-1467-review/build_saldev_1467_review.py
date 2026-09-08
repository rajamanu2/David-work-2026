from __future__ import annotations

from hashlib import sha256
from importlib.util import module_from_spec, spec_from_file_location
from io import BytesIO
from pathlib import Path
import zipfile

from lxml import etree
from PIL import Image, ImageDraw


ROOT = Path(r"C:\Users\LIKKI\Documents\ChatGPT\david")
BASE_SCRIPT = ROOT / ".codex-work" / "SALDEV-1440-architect-review" / "build_architect_review.py"
REFERENCE = ROOT / ".codex-work" / "SALDEV-1440-architect-review" / "SCC-3385-architect-review.docx"
OUTPUT = ROOT / "output" / "documents" / "SALDEV-1467-architect-review.docx"
EXPECTED_REFERENCE_HASH = "A63491D6161B45ACC1C082B240AD46B7900D0506EFDE5A311F1C0504DB60E88C"

spec = spec_from_file_location("architect_template", BASE_SCRIPT)
base = module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(base)

NS = base.NS
XML_SPACE = base.XML_SPACE


def execution_path_figure() -> bytes:
    img = Image.new("RGB", (1600, 1020), base.PANEL)
    d = ImageDraw.Draw(img)
    d.text((68, 50), "SALDEV-1467 | Current execution path", font=base.font(38, bold=True), fill=base.NAVY)
    d.text((68, 105), "The Flow is obsolete, but Apex still writes from OLI after-insert back to the CPQ Quote Line", font=base.font(21), fill=base.MUTED)

    base.rounded_box(d, (55, 195, 360, 610), "OpportunityLineItem", [
        "CPQ creates OLI",
        "after insert fires",
        "Quote Line link present",
    ], base.BLUE, "#F8FBFE", "#E5EFF9", 20)
    base.rounded_box(d, (430, 175, 790, 630), "FW OLI trigger", [
        "syncOpportunityLineId",
        "loads every OLI for quote",
        "maps group/product slots",
    ], base.BLUE, "#F8FBFE", "#E5EFF9", 20)
    base.rounded_box(d, (860, 155, 1215, 650), "Cross-object DML", [
        "updates Quote Line",
        "Database.update(..., false)",
        "SaveResults not checked",
        "guard reset not in finally",
    ], base.RED, "#FFF8F8", "#FDECEC", 20)
    base.rounded_box(d, (1285, 195, 1545, 610), "CPQ lifecycle", [
        "SBQQ after-update",
        "pricing / async work",
        "original collision risk",
    ], base.RED, "#FFF8F8", "#FDECEC", 19)
    base.arrow(d, (360, 400), (430, 400))
    base.arrow(d, (790, 400), (860, 400))
    base.arrow(d, (1215, 400), (1285, 400))

    base.rounded_box(d, (90, 705, 735, 980), "Verified", [
        "Flow status = Obsolete",
        "10/10 components compile",
        "16/16 specified test methods pass",
    ], base.GREEN, "#F8FCFA", "#E6F3EF", 18)
    base.rounded_box(d, (865, 705, 1510, 980), "Validation blockers", [
        "QuoteLineTrigger coverage = 69.70%",
        "Async helper coverage = 7.69%",
        "Check-only job 0AfhG000001ZTplSAG failed",
    ], base.RED, "#FFF8F8", "#FDECEC", 18)
    out = BytesIO()
    img.save(out, format="PNG", optimize=True)
    return out.getvalue()


def acceptance_figure() -> bytes:
    img = Image.new("RGB", (1600, 1100), "#FFFFFF")
    d = ImageDraw.Draw(img)
    d.text((70, 38), "SALDEV-1467 | Acceptance-evidence gap", font=base.font(38, bold=True), fill=base.NAVY)
    d.text((70, 92), "Coverage is high on some classes, but assertions do not prove the required business outcomes", font=base.font(22), fill=base.MUTED)

    base.rounded_box(d, (55, 185, 475, 605), "Stepped groups", [
        "Expected: same OLI ID",
        "Test checks only non-null",
        "One fallback value asserted",
        "Duplicate bundle slots unclear",
    ], base.AMBER, "#FFFBF2", "#FFF1CC", 20)
    base.rounded_box(d, (590, 185, 1010, 605), "Price-change clone", [
        "Expected: retain OLI ID",
        "Amendment method invoked",
        "No before/after ID assertion",
        "No Quote Line Type assertion",
    ], base.RED, "#FFF8F8", "#FDECEC", 20)
    base.rounded_box(d, (1125, 185, 1545, 605), "Other clone", [
        "Expected: new OLI ID",
        "No explicit test fixture",
        "No inequality assertion",
        "New/Renew paths unproven",
    ], base.RED, "#FFF8F8", "#FDECEC", 20)

    base.rounded_box(d, (90, 735, 735, 1010), "Required scenario matrix", [
        "New Business: stepped and ordinary clone",
        "Amendment: price change and other clone",
        "Renewal: preserve lineage and line type",
    ], base.BLUE, "#F8FBFE", "#E5EFF9", 20)
    base.rounded_box(d, (865, 735, 1510, 1010), "Required evidence", [
        "Exact ID equality / inequality assertions",
        "Bulk bundle test in CPQ lifecycle context",
        "No AsyncException and no silent DML failures",
    ], base.GREEN, "#F8FCFA", "#E6F3EF", 20)
    out = BytesIO()
    img.save(out, format="PNG", optimize=True)
    return out.getvalue()


REPLACEMENTS = {
    1: "SALDEV-1467 | Resolve Apex Error on Opportunity Line ID Flow",
    2: "FlywirePartial | Read-only implementation review and check-only validation",
    4: "FlywirePartial | Sandbox org 00DhG0000000jOXUAY",
    5: "Scope",
    6: "1 obsolete Flow | 3 triggers | 6 Apex classes/tests",
    8: "28 August 2026",
    9: "Check-only",
    10: "Failed | Job 0AfhG000001ZTplSAG | 10/10 components, 16/16 tests",
    12: "NO-GO - Changes Requested before QA or promotion",
    14: "No records, deployment, activation, or org metadata were changed",
    17: "Do not approve SALDEV-1467. The scoped package compiles and all specified tests pass, but check-only validation fails coverage gates and the replacement retains the original cross-object Quote Line DML risk from an OLI after-insert context.",
    25: "Original Flow",
    26: "Verified",
    27: "copying_of_Opportunity_Line_Id_unique_identifier has status Obsolete in FlywirePartial.",
    29: "Stepped products",
    30: "Partial",
    31: "Mapping logic exists, but tests prove only non-null/fallback values rather than exact cross-group identity for all bundle slots.",
    33: "Price-change clone",
    34: "Not proven",
    35: "The amendment method is invoked, but no assertion confirms the cloned line retains the source Opportunity Line ID.",
    37: "Other clone",
    38: "Not proven",
    39: "No test proves an ordinary clone receives a new Opportunity Line ID or remains independent of the source line.",
    41: "New / Amend / Renew",
    42: "Gap",
    43: "Fixtures mention these contexts, but end-to-end cloning outcomes are not asserted for each lifecycle path.",
    45: "Error-free quoting",
    46: "Blocked",
    47: "Synthetic tests pass; no representative bundle test proves the CPQ async collision is eliminated.",
    50: "Runtime-risk path",
    51: "The obsolete Flow removes one writer, but the replacement OLI after-insert trigger still performs cross-object DML on SBQQ__QuoteLine__c and can re-enter CPQ after-update processing.",
    53: "Figure 1. SALDEV-1467 current OLI-to-Quote-Line execution path",
    55: "Green is verified. Amber needs stronger evidence. Red blocks approval or can recreate the original failure mode.",
    58: "Detailed review findings",
    59: "1. Check-only validation evidence",
    60: "Metric",
    61: "Result",
    62: "Evidence",
    63: "Validation job",
    64: "Failed",
    65: "0AfhG000001ZTplSAG; checkOnly=true; rollbackOnError=true; no component or test errors.",
    66: "Payload",
    67: "10 components",
    68: "1 Flow, 3 triggers, 6 Apex classes/tests; all 10 compiled successfully.",
    69: "Specified tests",
    70: "16 passed",
    71: "OpportunityLineItemTriggerHandlerTest (2), QuoteLineTriggerHandleTest (8), QuoteLineGroupTriggerTest (6).",
    72: "Coverage gates",
    73: "Failed",
    74: "QuoteLineTrigger 69.70%; QuoteLineGroupAsyncHelper 7.69%; each selected component requires at least 75%.",
    75: "Focused test run",
    76: "Passed",
    77: "Job 707hG00000LhjKT; 100% pass rate; org-wide coverage 30%.",
    79: "2. Exact approval blockers",
    80: "Blocker",
    81: "Impact",
    82: "Exact evidence",
    83: "Deployment coverage",
    84: "Hard fail",
    85: "QuoteLineTrigger has 33 executable locations with 10 uncovered; helper has 13 with 12 uncovered.",
    86: "Cross-object DML",
    87: "Runtime risk",
    88: "OLI after insert calls Database.update on Quote Lines, re-entering the managed SBQQ after-update lifecycle.",
    89: "Silent failure handling",
    90: "Data risk",
    91: "Database.update(..., false) SaveResults are ignored; guard reset is not protected by finally.",
    93: "3. Code and test-quality findings",
    94: "Area",
    95: "Status",
    96: "Evidence / required action",
    97: "Fallback overload",
    98: "Defect",
    99: "When relationship data is absent, processOliIdSync(List) adds Quote Line IDs to the quote-ID set; its test asserts only true.",
    100: "Ramp key design",
    101: "Risk",
    102: "Before-insert mapping keys only quote plus product and uses ordered slots; repeated products in multiple bundles can be ambiguous.",
    103: "Exception handling",
    104: "Risk",
    105: "copyOpportunityLineIdOnRamp catches all exceptions and only debugs, allowing quoting to continue with missing IDs.",
    106: "Acceptance assertions",
    107: "Missing",
    108: "No exact ID equality/inequality assertions for price-change clones, ordinary clones, and all New/Amend/Renew paths.",
    109: "SALDEV-1427 overlap",
    110: "Unscoped",
    111: "The ticket says part of SALDEV-1427 is covered, but the promoted component/test boundary and ownership are not defined.",
    114: "Safe replacement and proof model",
    115: "The fix should establish identifiers before CPQ-managed after-update work, make mapping deterministic for duplicate bundle structures, surface partial DML failures, and test every lifecycle outcome explicitly.",
    117: "Figure 2. SALDEV-1467 acceptance-evidence gap and required scenario matrix",
    120: "Required approval gates",
    126: "Remove re-entry risk",
    127: "Developer / CPQ architect",
    128: "Redesign the OLI-to-Quote-Line sync so the fix does not issue Quote Line DML from OLI after insert in the CPQ transaction.",
    130: "Clear coverage gates",
    131: "Developer",
    132: "Raise QuoteLineTrigger and QuoteLineGroupAsyncHelper to at least 75% in the exact deployment payload.",
    134: "Assert acceptance rules",
    135: "Developer / QA",
    136: "Add exact same-ID and new-ID assertions for stepped, price-change, and ordinary clones across New, Amend, and Renew.",
    138: "Exercise CPQ scale",
    139: "CPQ QA",
    140: "Run representative large bundles and confirm no AsyncException, recursion, SOQL 101, or silent SaveResult failures.",
    142: "Bound SALDEV-1427",
    143: "Product owner / Architect",
    144: "Document which ramp-ID behavior belongs to SALDEV-1467 versus SALDEV-1427 and deploy/test them as one controlled dependency set.",
    146: "Revalidate and QA",
    147: "Release manager / QA",
    148: "Require a clean 10/10 check-only result, then execute named New/Amend/Renew scenarios with field-level evidence.",
    152: "Architect review completed for SALDEV-1467 in FlywirePartial. Changes Requested / NO-GO. The original Flow is Obsolete and the scoped Apex compiles, but check-only job 0AfhG000001ZTplSAG failed: all 10 components compiled and all 16 specified test methods passed, yet QuoteLineTrigger is only 69.70% covered and QuoteLineGroupAsyncHelper is 7.69%, below the 75% requirement. More importantly, FWOpportunityLineItemTrigger still runs after insert and OpportunityLineItemTriggerHandler performs Database.update on SBQQ__QuoteLine__c, so the replacement retains the same CPQ after-update re-entry pattern implicated in the original AsyncException. SaveResults are not inspected, one fallback path treats a Quote Line ID as a Quote ID, and the tests do not assert the required same-ID/new-ID outcomes across New, Amendment, and Renewal cloning. Redesign the cross-object sync, fix coverage, add exact lifecycle assertions, clarify the SALDEV-1427 dependency, and repeat check-only plus representative CPQ bundle QA before approval.",
    155: "This assessment uses the SALDEV-1467 ticket text, read-only FlywirePartial identity verification, scoped metadata retrieval, focused Apex tests, source inspection, and a check-only validation. No records, deployment, activation, quick deploy, or org metadata changes were performed.",
}


def replace_paragraph(p, new_text: str) -> None:
    texts = p.xpath(".//w:t", namespaces=NS)
    if not texts:
        raise RuntimeError("Cannot replace a paragraph with no text nodes")
    texts[0].text = new_text
    texts[0].set(XML_SPACE, "preserve")
    for node in texts[1:]:
        node.text = ""


def patch_document(xml_bytes: bytes) -> bytes:
    parser = etree.XMLParser(remove_blank_text=False)
    root = etree.fromstring(xml_bytes, parser)
    paragraphs = root.xpath("//w:p", namespaces=NS)
    for index, new_text in REPLACEMENTS.items():
        replace_paragraph(paragraphs[index], new_text)
    base.set_segmented_paragraph(paragraphs[118], [
        "Architect interpretation:",
        " the implementation is not release-ready. Passing tests show executable code, but the failed coverage gate and unchanged cross-object DML pattern leave both deployment and runtime acceptance unresolved.",
    ])
    for index in (26, 64, 67, 70, 76):
        base.style_status(paragraphs[index], base.GREEN, base.GREEN_FILL)
    for index in (30, 42, 87, 90, 101, 104, 110):
        base.style_status(paragraphs[index], base.AMBER, base.AMBER_FILL)
    for index in (34, 38, 46, 73, 84, 98, 107):
        base.style_status(paragraphs[index], base.RED, base.RED_FILL)
    tables = root.xpath("//w:tbl", namespaces=NS)
    for table_index in (2, 4, 5, 6, 7):
        base.mark_header_row(tables[table_index])
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
        "word/media/image3.png": execution_path_figure(),
        "word/media/image4.png": acceptance_figure(),
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
    if sha256(REFERENCE.read_bytes()).hexdigest().upper() != EXPECTED_REFERENCE_HASH:
        raise SystemExit("Reference changed during authoring")
    print(OUTPUT)


if __name__ == "__main__":
    main()
