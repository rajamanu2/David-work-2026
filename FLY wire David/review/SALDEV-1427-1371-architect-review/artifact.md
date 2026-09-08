# Artifact design authority — SALDEV-1427 / SALDEV-1371

## Intent

Create two separate, editable five-page architect-review DOCX files that evaluate the live FlywirePartial implementation against each attached story independently. Each document is a read-only evidence report, not an implementation or deployment artifact.

## Output split

- `SALDEV-1427_Architect_Review.docx`: stepped-pricing clone behavior, QLE editability, Opportunity Line ID lineage, requirements, test matrix, and bundled release gate.
- `SALDEV-1371_Architect_Review.docx`: non-stepped quote-line or group cloning, ARR field nulling, record-detail verification, and SALDEV-1351 regression evidence.
- SALDEV-1371 may identify SALDEV-1427 as the delivery vehicle, but it must not inherit stepped-pricing editability or Opportunity Line ID acceptance as its own acceptance scope.
- Apex trigger coverage is a direct release blocker in SALDEV-1427. In SALDEV-1371 it is contextual only: the Apex dry run does not validate the JavaScript acceptance criterion.

## Retained reference

- Reference: `output/documents/SALDEV-1475-architect-review.docx`
- SHA-256: `B491A97DA9EC81D50922AE59C6796B3A7FE7CE7E5CDBE94E6402A4572F05141D`
- Preserve all package parts except `word/document.xml`, `word/media/image3.png`, `word/media/image4.png`, and `docProps/core.xml`.

## Page system

- Five US-Letter portrait pages, one section, 1-inch margins.
- Arial throughout; navy and blue for hierarchy, green for verified strengths, amber for follow-up, red for blockers.
- Existing Flywire review header/footer, page numbering, paragraph styles, table geometry, spacing, and editable OOXML structure are authoritative.
- Page 1: title, metadata, decision callout, acceptance matrix.
- Page 2: defect concentration and runtime-path diagram.
- Page 3: live component, best-practice, and validation evidence tables.
- Page 4: required target architecture and proof-model diagram.
- Page 5: completion gates, ready-to-paste story response, evidence boundary.

## Visual slots

- Replace image 3 with a 1600×1020 PNG showing the current ticket-to-runtime path and concentrated blockers.
- Replace image 4 with a 1600×1100 PNG showing the required dependency contract, deterministic lineage key, failure handling, and test proof.
- Preserve the existing image dimensions and anchoring in the DOCX; provide meaningful title and description alt text.

## Content rules

- Decision: `NO-GO — Changes Requested before QA or promotion`.
- Distinguish story statements from live-org observations.
- State that all 7 focused tests passed, while the check-only validation failed solely because `QuoteLineTrigger` coverage is 43.59%, below Salesforce's 75% deployment requirement.
- Treat handler coverage (97%) as a strength, not as proof of trigger or JavaScript behavior.
- Name the highest-risk defects: CPQ dependency declarations, nonexistent `Domestic_Sponsor__c`, contradictory usage-field editability, ambiguous quote-plus-product mapping, swallowed exceptions, and missing deterministic tests.
- State the evidence boundary: no records changed, no scripts edited, no metadata deployed, no activation, and no Production action.

## Verification contract

- Reference package inventory and preserve-only hashes must remain unchanged.
- Final file must pass structural, accessibility, heading, image, field, and table checks in proportion to the retained reference.
- Render every final page with Word-to-PDF plus Poppler if the packaged LibreOffice renderer is unavailable, then visually inspect every page for clipping, overflow, and legibility.
