# SALDEV-1413 architect review template contract

## Reference

- Retained DOCX: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-4179-architect-review.docx`
- SHA-256: `6CD3A83323E24FCE40799F07B7E2A0D0E8960AC060138EF1B827A2DEE7B5E2A9`
- Rendered page count: 5
- Section count: 1
- Reference render: `C:\Users\LIKKI\Documents\ChatGPT\david\review\SALDEV-1413-architect-doc\template-reference-render`
- Style evidence: `C:\Users\LIKKI\Documents\ChatGPT\david\review\SALDEV-1413-architect-doc\template-style-evidence.json`

## Page system

- US Letter portrait, 8.5 x 11 inches.
- Margins: 1 inch on all sides; header/footer distance 0.4917 inch.
- One section; no page-orientation changes.
- Default/even/first headers and footers exist as separate package parts. They are visually identical and must remain relationship-compatible.
- Page transitions are controlled by retained body paragraphs/page-break properties. Do not add sections or change pagination controls.

## Typography and colors

- Arial throughout.
- Eyebrow: 10 pt bold, blue `2E74B5`, 12 pt before and 2 pt after.
- Title: 25 pt bold, navy `0B2545`, 4 pt after.
- Subtitle: 13 pt regular, gray `5B6777`, 16 pt after.
- Heading 1/2: retain the source Heading styles; both render blue `2E74B5` with the source spacing and keep behavior.
- Body: 11 pt Arial, dark gray `1F2937`.
- Table body/header text: 9.5 pt Arial. Headers and left metadata labels are bold navy `0B2545`.
- Status colors: fail red `C53030`, pass green `16836B`, partial/gate amber `B7791F`.
- Caption: 9 pt italic Arial, centered, gray `5B6777`, 2 pt before and 8 pt after.

## Tables and components

- Retain all 13 source tables, row counts, column counts, widths, borders, cell margins, fills, and vertical alignment.
- Table grids in EMU: T0 `[1206500,4737100]`; T1 `[5943600]`; T2 `[317500,1365250,920750,3340100]`; T3 `[5943600]`; T4/T5 `[2286000,1143000,1143000,1371600]`; T6 `[5943600]`; T7 `[1333500,2476500,2133600]`; T8 `[1206500,4737100]`; T9 `[5943600]`; T10 `[1333500,4610100]`; T11 `[317500,1524000,1397000,2705100]`; T12 `[5943600]`.
- T1, T3, T6, T9, and T12 are single-cell callouts with a colored label paragraph followed by a bold navy decision paragraph.
- T2, T4, T5, T7, T8, T10, and T11 are evidence/control tables with existing header fills and repeating visual rules.
- The source inline diagram slot is `word/media/image2.png`, 1600 x 1000 pixels, rendered at 6.45 x 4.03 inches. Replace only this media part and retain its relationship and drawing geometry.
- Footer text is right aligned, 9 pt Arial gray, with a live PAGE field. Replace only the environment label; preserve field XML.

## Content flow and slot map

1. Page 1: eyebrow, title, subtitle, five-row review metadata, architect decision callout, Acceptance outcome heading, five-row result table.
2. Page 2: correction/control-path heading, one lead paragraph, retained diagram slot, caption, design-reading callout.
3. Page 3: current evidence heading, two Heading 2 evidence groups, two four-column evidence tables, red promotion-blocker callout.
4. Page 4: implementation/release-boundary heading, six-row component/action table, Release sequence heading, four-row evidence table, amber Production gate callout.
5. Page 5: UAT heading, five-row test table, approval-gates heading, five-row owner/evidence table, ready-to-paste response heading and blue story-comment callout.

Stable editable locators are direct body paragraph indexes 0, 1, 2, 5, 8, 9, 11, 14, 15, 17, 21, 23, 27, 29, and 31; direct body table indexes 0 through 12; footer text nodes containing `GreatPlainsMerge`; `word/media/image2.png`; and selected Dublin Core properties in `docProps/core.xml`.

## Package preservation

- Editable parts: `word/document.xml`, `word/footer1.xml`, `word/footer2.xml`, `word/footer3.xml`, `word/media/image2.png`, and `docProps/core.xml`.
- Preserve byte-for-byte: `[Content_Types].xml`, package relationships, `word/_rels/document.xml.rels`, styles, stylesWithEffects, settings, webSettings, fontTable, theme, numbering, all headers, `word/media/image1.png`, all customXml parts and relationships, app properties, and thumbnail.
- No comments, footnotes, endnotes, or content-control parts are present. Three PAGE fields exist in the footer parts and must remain.

## Fidelity gates

- Reference SHA-256 must still match before and after authoring.
- Final document must remain five pages, one portrait section, with unchanged margins, diagram geometry, table topology, page-break pattern, and footer PAGE fields.
- Every final page must be rendered through Word/PDF and inspected at 100 percent zoom.
- All preserve-only package parts must retain identical SHA-256 values.
- Fail delivery for clipping, overlap, broken tables, unexpected page movement, altered recurring chrome, missing fields, or an unexplained package-part change.
