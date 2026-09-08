# SALDEV-1440 architect-review template contract

## Reference

- Retained reference: `C:\Users\LIKKI\Documents\ChatGPT\david\.codex-work\SALDEV-1440-architect-review\SCC-3385-architect-review.docx`
- Original source: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-3385-architect-review.docx`
- SHA-256: `A63491D6161B45ACC1C082B240AD46B7900D0506EFDE5A311F1C0504DB60E88C`
- Pages: 5. Sections: 1.
- Reference render: `template-reference-render\page-1.png` through `page-5.png`.
- Evidence: `template-style-evidence.json`, section/style/heading/image/field/content-control audits.

## Page system

- US Letter portrait, 8.5 x 11 inches; one section; new-page section start.
- Margins: 1.0 inch on all sides. Different-first-page enabled.
- Header linked off; footer linked off. Footer is right-aligned and reads `<review context> | Page <PAGE field>`.
- Five page patterns: title/decision/acceptance table; readiness diagram; detailed evidence tables; architecture diagram; approval gates/comment/evidence boundary.

## Typography and palette

- Family: Arial throughout.
- Eyebrow: 10 pt bold, `#2E74B5`, 12 pt before, 2 pt after.
- Title: 25 pt bold, `#0B2545`, 4 pt after.
- Subtitle: 13 pt regular, `#5B6777`, 14 pt after.
- Heading 1: source `Heading 1` style, blue, bold, approximately 15 pt with source spacing/keep behavior.
- Heading 2: source `Heading 2` style, blue, bold, approximately 12 pt.
- Body: 11 pt regular, `#1F2937`, 1.1 line spacing, 6 pt after.
- Figure captions: 9 pt italic, centered, `#5B6777`, 2 pt before, 8 pt after.
- Table body: 9-9.5 pt; header text bold navy; status colors use green `#138A72`, amber `#B7791F`, red `#C53030` with pale matching fills.

## Tables and components

- All tables use the retained exact 6.5-inch geometry, borders, fills, cell margins, row behavior, and column grids.
- Metadata table: 6 x 2, widths 1.3194 / 5.1806 inches.
- Decision callout: 1 x 1, 6.5 inches, pale-red fill.
- Acceptance table: 7 x 4, widths 0.3333 / 1.4236 / 1.0069 / 3.7361 inches.
- Design-reading callout: 1 x 1, pale-blue fill.
- Evidence table: 6 x 3, widths 1.2153 / 1.6319 / 3.6528 inches.
- Configuration/failure table: 4 x 3, widths 1.7014 / 1.1111 / 3.6875 inches.
- Scope/follow-up table: 6 x 3, widths 1.5278 / 1.3194 / 3.6528 inches.
- Approval-gate table: 7 x 4, widths 0.5903 / 1.7361 / 1.3889 / 2.7847 inches.
- Story-comment callout: 1 x 1, pale-blue fill.
- Two inline diagrams occupy the retained drawing slots: 6.45 x 4.11 inches and 6.45 x 4.43 inches. Replace only `word/media/image3.png` and `word/media/image4.png` at 1600 x 1020 and 1600 x 1100 pixels.

## Content flow and slot map

1. Title block: SALDEV ticket, review context.
2. Metadata table: source/review target/date/check-only/decision/boundary.
3. Architect decision callout.
4. Acceptance outcome table with six story checks.
5. Readiness-path narrative, diagram, caption, design reading.
6. Detailed dry-run findings: check-only evidence, exact configuration evidence, scope boundaries/follow-ups.
7. Quote-group classification architecture narrative, diagram, caption, interpretation.
8. Required handoff gates table.
9. Ready-to-paste architect response callout.
10. Evidence boundary.

All body, table-cell, caption, and footer text is editable for this derivative. Styles, table geometry, numbering fields, section properties, drawing anchors/sizes, relationships, and unrelated package parts are preserve-only.

## Package preservation

- Editable parts: `word/document.xml`, `word/footer1.xml`, `word/footer2.xml`, `word/footer3.xml`, `word/media/image3.png`, `word/media/image4.png`.
- Preserve byte-for-byte: `[Content_Types].xml`, root relationships, `docProps`, styles, numbering, settings, theme, font table, web settings, document relationships, custom XML, all other footers/headers, and media images 1/2.
- The build must patch the retained package rather than rebuild it with `python-docx`.

## Fidelity gates

- Reference hash must still equal the recorded SHA-256 before and after authoring.
- Final must retain one section, Letter portrait geometry, five-page structure where practical, table grids/fills, two diagram slots, three PAGE fields, and the source footer pattern.
- Only the six listed editable parts may differ at the package-content level.
- Render all final pages through Microsoft Word, inspect at 100%, and reject clipping, overlap, broken tables, unexpected pagination, or missing footer/page fields.
