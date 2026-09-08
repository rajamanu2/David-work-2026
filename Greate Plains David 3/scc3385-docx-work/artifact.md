# SCC-3385 document execution contract

## Reference

- Retained reference: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\Great_Plains_Trouble_Ticket_Architect_Review.docx`
- SHA-256: `D71F2A5223ADAA48483838ADA1E18348B237D28CFDFC03E275C6CB2778C06E03`
- Page count: 5
- Section count: 1
- Render evidence: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\doc-render\page-1.png` through `page-5.png`
- Section evidence: one portrait US Letter section, inspected with `section_audit.py`
- Style evidence: Arial throughout; inspected with `style_lint.py`

## Page system

- Page size: US Letter, 8.5 x 11 inches, portrait.
- Margins: 1 inch on all sides; usable width 6.5 inches / 9360 DXA.
- Header/footer distance: approximately 0.492 inch.
- One section; first-page and odd/even header/footer parts exist.
- Footer: right aligned, muted gray, environment label plus dynamic PAGE field.
- Page flow: explicit page break before each major page pattern; target is five pages.

## Typography and color

- Font: Arial for all roles.
- Eyebrow: 10 pt, bold, uppercase, blue `2E74B5`.
- Document title: 25-26 pt, bold, navy `0B2545`.
- Subtitle: 13 pt, muted gray `5B6777`.
- Heading 1: 16 pt, bold, blue `2E74B5`, 12 pt before / 6 pt after.
- Heading 2: 13 pt, bold, blue `2E74B5`, 10 pt before / 5 pt after.
- Heading 3: 12 pt, bold, navy `0B2545`.
- Body: 11 pt, ink `1F2937`, 1.10 line spacing, 6 pt after.
- Table body: 9.0-9.5 pt; table headers bold navy on light gray `F2F4F7`.
- Decision/risk: red `C53030` on light red `FDECEC`.
- Review/warning: amber `B7791F` on light amber `FFF6DE`.
- Positive/configured: teal `16836B` on light teal `E7F5F1`.

## Lists and tables

- Tables use fixed DXA geometry totaling 9360 DXA, 120 DXA indent, explicit grid and cell widths.
- Cell margins: approximately 100 DXA top/bottom and 140 DXA start/end.
- Header rows repeat and use light-gray fill.
- Status cells are centered, bold, and color-coded.
- No fixed row heights; text wraps naturally.
- Lists inside diagrams use drawn markers; body document relies on tables and prose rather than fake bullets.

## Components and content flow

1. Decision memo masthead, metadata table, red decision callout, acceptance outcome matrix.
2. Presentation-style solution/deployment map with caption, alt text, and design-reading callout.
3. Detailed evidence tables covering package validation, source defects, and UAT prerequisites.
4. Architecture/dependency diagram with caption, alt text, and interpretation paragraph.
5. Approval-gate matrix, ready-to-paste story comment, and evidence boundary.

## Slot map

- Masthead slots: story identifier/title, source-to-target subtitle, metadata values, decision language.
- Page 1 matrix: six acceptance criteria with status and concise evidence.
- Page 2 diagram: source org, corrected package, check-only job, target blockers, no-write boundary.
- Page 3 tables: exact check-only counts/errors; story/source discrepancies; UAT/test-data inventory.
- Page 4 diagram: Case prerequisites, Flow, WorkOrder output, activity logging, duplicate guard, Book Appointment regression boundary.
- Page 5 gates: owner/action/evidence rows; stakeholder-ready comment; no-deploy statement.
- Footer label changes from the reference environment to `GreatPlainsMerge to UAT`.

## Package preservation

- Preserve from reference: styles, theme, numbering, page geometry, style hierarchy, header/footer pattern, and table/figure conventions.
- Editable/rebuilt: `word/document.xml`, footer text, core properties, and document media/relationships required for the two SCC-3385 figures.
- Preserve-only package parts include `customXml`, theme, numbering, font table, styles, stylesWithEffects, settings, and web settings unless the document library necessarily reserializes them.
- Reference source remains unchanged and must retain the recorded SHA-256.

## Fidelity gates

- Five-page output with the same major page patterns as the reference.
- No clipping, overlap, broken tables, missing glyphs, or orphaned headings.
- Both figures must have descriptive alt text and centered captions.
- Footer page field must render on every page.
- Status colors and decision language must clearly communicate NO-GO.
- No Salesforce secrets, session values, internal citation tokens, or unsupported claims.
- Final document must state check-only job `0AfEa00000bbQXhKAM`, 14 components, 6 successes, 8 failures, and no org changes.

