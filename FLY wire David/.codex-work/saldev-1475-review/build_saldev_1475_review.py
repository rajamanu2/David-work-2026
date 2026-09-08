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
OUTPUT = ROOT / "output" / "documents" / "SALDEV-1475-architect-review.docx"
EXPECTED_REFERENCE_HASH = "A63491D6161B45ACC1C082B240AD46B7900D0506EFDE5A311F1C0504DB60E88C"

spec = spec_from_file_location("architect_template", BASE_SCRIPT)
base = module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(base)

W_NS = base.W_NS
NS = base.NS
XML_SPACE = base.XML_SPACE


def lifecycle_figure() -> bytes:
    img = Image.new("RGB", (1600, 1020), base.PANEL)
    d = ImageDraw.Draw(img)
    d.text((68, 50), "SALDEV-1475 | Observed CPQ lifecycle", font=base.font(38, bold=True), fill=base.NAVY)
    d.text((68, 105), "Live FlywirePartial trace for Q-37942, Contract 00021743, Q-37946, and Q-37950", font=base.font(21), fill=base.MUTED)

    base.rounded_box(d, (55, 185, 420, 650), "Original quote", [
        "Q-37942: 3 ramped groups",
        "Five quote lines",
        "Year 1 / Year 2 / Year 3",
        "Group Line Items = true",
    ], base.BLUE, "#F8FBFE", "#E5EFF9", 20)
    base.rounded_box(d, (505, 185, 900, 650), "Contract subscriptions", [
        "Five subscription records",
        "No direct Quote Line Group field",
        "Source Quote Line retains lineage",
        "One-time fee does not renew",
    ], base.GREEN, "#F8FCFA", "#E6F3EF", 20)
    base.rounded_box(d, (985, 155, 1545, 455), "Amendment Q-37946", [
        "Five lines are ungrouped",
        "Group Line Items = false",
        "Zero Quote Line Groups",
    ], base.GREEN, "#F8FCFA", "#E6F3EF", 20)
    base.rounded_box(d, (985, 535, 1545, 835), "Renewal Q-37950", [
        "Four renewable lines are ungrouped",
        "Each line points to a subscription",
        "Three Domestic lines remain separate",
    ], base.GREEN, "#F8FCFA", "#E6F3EF", 20)

    base.arrow(d, (420, 405), (505, 405))
    base.arrow(d, (900, 360), (985, 300))
    base.arrow(d, (900, 475), (985, 660))
    d.text((433, 370), "contract", font=base.font(18), fill=base.MUTED)
    d.text((905, 312), "amend", font=base.font(18), fill=base.MUTED)
    d.text((905, 590), "renew", font=base.font(18), fill=base.MUTED)

    d.rounded_rectangle((85, 885, 1515, 970), radius=18, fill="#FFF4D6", outline=base.AMBER, width=4)
    d.text((120, 910), "Coverage gap: no non-ramped lifecycle case and no populated NS Line Item ID were tested.", font=base.font(24, bold=True), fill=base.NAVY)
    out = BytesIO()
    img.save(out, format="PNG", optimize=True)
    return out.getvalue()


def lineage_figure() -> bytes:
    img = Image.new("RGB", (1600, 1100), "#FFFFFF")
    d = ImageDraw.Draw(img)
    d.text((70, 38), "SALDEV-1475 | Identity and renewal lineage", font=base.font(38, bold=True), fill=base.NAVY)
    d.text((70, 92), "Quote group identity ends at the quote; subscription identity drives downstream lines", font=base.font(22), fill=base.MUTED)

    base.rounded_box(d, (55, 190, 360, 570), "Quote Line Group", [
        "Group record and name",
        "Allow Product Ramping",
        "Start and end dates",
        "Not copied to Subscription",
    ], base.BLUE, "#F8FBFE", "#E5EFF9", 19)
    base.rounded_box(d, (430, 170, 790, 590), "Original Quote Line", [
        "SBQQ__Group__c",
        "Product, dates, and prices",
        "Source for contracted Subscription",
    ], base.BLUE, "#F8FBFE", "#E5EFF9", 19)
    base.rounded_box(d, (865, 155, 1235, 605), "Subscription", [
        "SBQQ__QuoteLine__c",
        "Product and segment dates",
        "Renewal Price / NS fields",
        "No group reference",
    ], base.GREEN, "#F8FCFA", "#E6F3EF", 19)
    base.rounded_box(d, (1300, 205, 1545, 555), "Lifecycle line", [
        "Amendment: copied line",
        "Renewal: Renewed Subscription",
        "Group remains null",
    ], base.GREEN, "#F8FCFA", "#E6F3EF", 18)
    base.arrow(d, (360, 380), (430, 380))
    base.arrow(d, (790, 380), (865, 380))
    base.arrow(d, (1235, 380), (1300, 380))

    base.rounded_box(d, (80, 710, 720, 995), "Verified source behavior", [
        "Renewal header starts 24-Sep-2029 despite early generation",
        "Three Domestic subscriptions create three renewal lines",
        "Platform line uses its own Year 1 subscription",
    ], base.GREEN, "#F8FCFA", "#E6F3EF", 19)
    base.rounded_box(d, (880, 710, 1520, 995), "Required business design", [
        "Persistent custom group key if identity must survive",
        "Reconstruction automation for amendment and renewal",
        "Explicit consolidation and NS-ID rules plus tests",
    ], base.AMBER, "#FFFBF2", "#FFF1CC", 19)
    out = BytesIO()
    img.save(out, format="PNG", optimize=True)
    return out.getvalue()


REPLACEMENTS = {
    1: "SALDEV-1475 | OOB Grouped Lines on Amend and Renew",
    2: "FlywirePartial | Read-only lifecycle investigation and architect assessment",
    4: "FlywirePartial | Sandbox org 00DhG0000000jOXUAY",
    5: "Test records",
    6: "Q-37942 | Contract 00021743 | Q-37946 | Q-37950",
    8: "28 August 2026",
    9: "Validation mode",
    10: "Read-only SOQL and source review; no deployment or record changes",
    12: "CHANGES REQUESTED - Ramped result confirmed; required cases remain untested",
    14: "No records, metadata, deployment, activation, or pricing recalculation were changed",
    17: "Do not close SALDEV-1475 as fully complete. The ramped-group lifecycle is confirmed and matches Salesforce CPQ expected behavior, but the required non-ramped lifecycle case and populated NetSuite-ID case were not executed.",
    25: "Subscription group identity",
    26: "Indirect only",
    27: "No group ID is stored on Subscription. Lineage is Subscription -> Source Quote Line -> original Quote Line Group.",
    29: "Groups on amendment",
    30: "No",
    31: "Q-37946 has five lines, Group Line Items=false, zero groups, and every SBQQ__Group__c is null.",
    33: "Groups on renewal",
    34: "No",
    35: "Q-37950 has four lines, Group Line Items=false, zero groups, and every SBQQ__Group__c is null.",
    37: "Final-group assumption",
    38: "Rejected",
    39: "Renewal has three Domestic Payments lines mapped to three distinct subscriptions, not one consolidated final-group line.",
    41: "Early renewal timing",
    42: "Header pass",
    43: "Although generated before Year 3 starts, Q-37950 correctly covers 24-Sep-2029 through 23-Sep-2030.",
    45: "Non-ramped / NS ID",
    46: "Not tested",
    47: "Original data contains only ramped groups; every NS_ID__c is null, so both required behaviors remain unverified.",
    50: "Observed amendment and renewal path",
    51: "Salesforce CPQ preserves subscription-level lineage but does not preserve original Quote Line Groups. Flywire custom group-date logic only runs when groups exist.",
    53: "Figure 1. SALDEV-1475 observed CPQ lifecycle in FlywirePartial",
    55: "Green is verified live. Blue is the original quote structure. Amber is required follow-up evidence.",
    58: "Detailed investigation findings",
    59: "1. Named-record evidence",
    60: "Record set",
    61: "Observed result",
    62: "Evidence",
    63: "Target org",
    64: "FlywirePartial",
    65: "Org 00DhG0000000jOXUAY; Enterprise Edition sandbox; API 67.0.",
    66: "Original quote",
    67: "Q-37942 | 5 lines",
    68: "Three ramped groups: SUP Year 1, Year 2, and Year 3; dates span 24-Sep-2026 to 23-Sep-2029.",
    69: "Contract",
    70: "00021743 | 5 subscriptions",
    71: "Latest End Date behavior; renewal term 12; subscriptions retain source Quote Line links, not group IDs.",
    72: "Amendment",
    73: "Q-37946 | 5 ungrouped lines",
    74: "All original subscription lines appear, including the one-time implementation fee; no groups were recreated.",
    75: "Renewal",
    76: "Q-37950 | 4 ungrouped lines",
    77: "Three Domestic Payments lines plus one Platform Fee; one-time Implementation Fee is absent.",
    79: "2. Exact lifecycle outcomes",
    80: "Lifecycle stage",
    81: "Result",
    82: "Live evidence",
    83: "Original grouped quote",
    84: "Verified",
    85: "Q-37942 has Group Line Items=true, three group records, and all five lines linked to a group.",
    86: "Amendment quote",
    87: "Expected OOB",
    88: "Q-37946 has Group Line Items=false and no Quote Line Group records. Salesforce Help KA 004518583 confirms this is expected CPQ behavior.",
    89: "Renewal quote",
    90: "Expected OOB",
    91: "Q-37950 has Group Line Items=false and no Quote Line Group records; each line links to a renewed Subscription.",
    93: "3. Price, NetSuite, and coverage findings",
    94: "Area",
    95: "Status",
    96: "Evidence / required action",
    97: "Renewal lineage",
    98: "Verified",
    99: "Each renewal line has SBQQ__RenewedSubscription__c; three Domestic lines map to SUB-0067610, SUB-0067613, and SUB-0067614.",
    100: "Platform price",
    101: "Observed",
    102: "SUB-0067611 has Renewal Price 10,000; its renewal line has NS Billing Price 10,000 and Net Price 360,000.",
    103: "Early generation",
    104: "Observed",
    105: "Renewal header starts one day after the latest subscription end date. Generation before Year 3 start did not shift the header period.",
    106: "NS Line Item ID",
    107: "Blocked",
    108: "NS_ID__c is null on all five Subscriptions and all renewal lines; populated-ID propagation cannot be concluded.",
    109: "Non-ramped group",
    110: "Missing",
    111: "No Allow Product Ramping=false group exists in the named original quote. Execute the second required contract lifecycle.",
    114: "Quote group and subscription lineage architecture",
    115: "Quote Line Group is a quote-only container. Contracting creates independent Subscriptions that retain source Quote Line lineage; amendments and renewals create ungrouped lifecycle lines.",
    117: "Figure 2. SALDEV-1475 identity boundary and renewal-line lineage",
    120: "Required completion gates",
    126: "Run non-ramped lifecycle",
    127: "QA / Developer",
    128: "Create Allow Product Ramping=false groups, contract, amend, and renew; capture group counts and line-level links.",
    130: "Test populated NS IDs",
    131: "Integration / QA",
    132: "Use subscriptions with populated NS Line Item ID and compare subscription, amendment, and renewal values field by field.",
    134: "Confirm renewal intent",
    135: "Product owner / Architect",
    136: "Choose whether three stepped subscriptions should remain separate or consolidate to the final commercial period.",
    138: "Define persistent group key",
    139: "Solution architect",
    140: "If lifecycle grouping is required, define a custom identifier on source lines/subscriptions and deterministic reconstruction rules.",
    142: "Test pricing variants",
    143: "CPQ QA",
    144: "Cover non-zero prices by ramp year, renewal pricing methods, uplift, and renewal before each segment start.",
    146: "Coordinate linked stories",
    147: "Product owner",
    148: "Align the chosen behavior with SALDEV-1439 and SALDEV-1493; do not treat this investigation as implementation approval.",
    152: "Architect review completed for SALDEV-1475 in FlywirePartial using Opportunity OOB-CPQ-Learning-Shrey-20260821, original Quote Q-37942, Contract 00021743, Amendment Quote Q-37946, and Renewal Quote Q-37950. Salesforce CPQ did not copy or recreate Quote Line Groups: five Subscriptions trace indirectly through their Source Quote Lines, while both lifecycle quotes have Group Line Items=false, zero groups, and null line Group IDs. The final-group assumption is rejected because Q-37950 contains three separate Domestic Payments lines, each linked to a different Subscription. The Platform Fee line links to SUB-0067611, whose Renewal Price is 10,000; the renewal line has NS Billing Price 10,000 and Net Price 360,000. The one-time Implementation Fee does not renew. The renewal header correctly spans 24-Sep-2029 through 23-Sep-2030 even though renewal was generated before the final segment started. Changes Requested: complete the required non-ramped lifecycle test and a populated NS_ID__c test before closing the investigation. If group identity must survive, use a persistent custom identifier and deterministic reconstruction automation coordinated with SALDEV-1439 and SALDEV-1493.",
    155: "This assessment combines the SALDEV-1475 ticket text, Salesforce Help KA 004518583, read-only FlywirePartial schema and record queries, and local source review. No records, deployments, activations, pricing calculations, quick deploys, or org metadata changes were performed.",
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
        " the live data and Salesforce guidance agree that groups do not survive amendment or renewal. Preserve identity only through an explicit custom data model and reconstruction design.",
    ])
    for index in (30, 34, 38, 42, 84, 87, 90, 98, 101, 104):
        base.style_status(paragraphs[index], base.GREEN, base.GREEN_FILL)
    for index in (26, 107):
        base.style_status(paragraphs[index], base.AMBER, base.AMBER_FILL)
    for index in (46, 110):
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
        "word/media/image3.png": lifecycle_figure(),
        "word/media/image4.png": lineage_figure(),
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
