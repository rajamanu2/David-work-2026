# SALDEV-1473 architect-review template contract

## Reference

- Absolute path: `C:\Users\LIKKI\Documents\ChatGPT\david\output\documents\SALDEV-1475-architect-review.docx`
- SHA-256: `B491A97DA9EC81D50922AE59C6796B3A7FE7CE7E5CDBE94E6402A4572F05141D`
- Size: 471,755 bytes
- Pages: 5
- Sections: 1
- Reference render: `C:\Users\LIKKI\Documents\ChatGPT\david\review\SALDEV-1473\docx-build\reference-render`
- Style evidence: `C:\Users\LIKKI\Documents\ChatGPT\david\review\SALDEV-1473\docx-build\evidence\reference-style.json`

## Page system

- US Letter portrait, 8.5 x 11 inches.
- One section, 1-inch margins on every side.
- Different-first-page header enabled; no visible body header.
- Footer uses right-aligned Arial gray text: `FlywirePartial review | Page N`.
- Content width is 6.5 inches. The document uses page breaks produced by content flow, not fixed row heights.

## Typography

- Base face: Arial.
- Eyebrow: 10 pt, bold, blue `#2E74B5`, 12 pt before and 2 pt after.
- Title: 25 pt, bold, navy `#0B2545`, 4 pt after.
- Subtitle: 13 pt, regular, gray `#5B6777`, 14 pt after.
- Body: 11 pt Arial, dark gray `#1F2937`, 6 pt after.
- Heading 1 and Heading 2 use the retained named styles, blue hierarchy, and keep-with-next behavior.
- Captions are centered/italic gray. Callout labels are uppercase blue or red, with bold navy body text.

## Tables and components

- Metadata table: 6 rows x 2 columns, widths 1.32 / 5.18 inches; pale-blue label cells.
- Decision callout: one cell, 6.5 inches, two paragraphs.
- Acceptance table: 7 x 4, widths 0.33 / 1.42 / 1.01 / 3.74 inches.
- Design-reading callout: one cell, 6.5 inches.
- Detailed tables: 6 x 3 at 1.22 / 1.63 / 3.65 inches; 4 x 3 at 1.70 / 1.11 / 3.69 inches; 6 x 3 at 1.53 / 1.32 / 3.65 inches.
- Completion-gates table: 7 x 4 at 0.59 / 1.74 / 1.39 / 2.78 inches.
- Story-comment callout: one cell, 6.5 inches.
- Header rows repeat. Rows grow naturally. Cell text is vertically centered with deliberate status-cell fills.
- Two diagram slots occur in body paragraph paths 10 and 24 and use `word/media/image3.png` and `word/media/image4.png`.

## Content flow and slot map

1. Title block: architect-review eyebrow, SALDEV-1473 title, deployment/validation subtitle.
2. Metadata table: source, test record, review date, validation mode, decision, boundary.
3. Architect decision callout.
4. Acceptance outcome table.
5. Root-cause and correction path: lead paragraph, diagram, caption, design-reading callout.
6. Detailed findings: org/version evidence, implementation/deployment evidence, functional/coverage evidence.
7. Architecture section: lead paragraph, diagram, caption, architect interpretation.
8. Required follow-up gates.
9. Ready-to-paste story response.
10. Evidence boundary.

All body paragraphs and tables are editable structural slots for the new story. Retained styles, numbering, theme, section properties, footer structure, and drawing placement are preserve-only. The two used diagram binaries may be replaced. Unused media parts remain preserve-only.

## Package preservation

- Package contains 27 parts.
- Editable parts: `word/document.xml`, `word/footer1.xml`, `word/footer2.xml`, `word/footer3.xml`, `word/media/image3.png`, `word/media/image4.png`, and `docProps/core.xml`.
- Preserve-only: styles, numbering, theme, settings, font table, relationships, content types, unused media, and all other package parts.
- Final build must retain the same package-part inventory and identical SHA-256 values for every preserve-only part.

## Fidelity gates

- Reference remains byte-for-byte unchanged at the recorded SHA-256.
- Final keeps the one-section Letter page system, margins, footer, typography, tables, two-diagram pattern, and status-color semantics.
- Every page must render without clipping, overlapping, broken tables, orphaned headings, or missing page numbers.
- Content changes may alter pagination, but recurring chrome and source-derived styling must remain consistent.
