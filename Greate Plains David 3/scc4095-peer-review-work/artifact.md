# SCC 4095 peer review document contract

## Reference

- Retained reference: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-3384-peer-review.docx`
- SHA-256: `CC6C5D2465D3281E15C0721FA9318D6866D416C4B667AA32E9AD144059C07907`
- Reference render: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc3384-work\final-render-word-v2`
- Reference page count: 5
- Reference section count: 1
- Style evidence: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc4095-peer-review-work\template-style-evidence.json`

## Page system

- One Letter portrait section, 8.5 by 11 inches, with 1 inch margins.
- Use explicit page breaks to keep the decision, implementation scope, validation evidence, and completion gates distinct.
- Preserve the right-aligned `GreatPlainsDevA  |  Page` footer with a Word PAGE field.
- Keep the header empty.

## Typography

- Arial throughout.
- Body: 11 pt, dark ink, 1.10 line spacing, 6 pt after.
- Title: Word Title style, 25 pt, bold, black, no rule or paragraph border.
- Eyebrow: 10 pt, bold, black.
- Subtitle: 13 pt, black.
- Heading 1: 16 pt, bold, black, 12 pt before and 6 pt after.
- Heading 2: 13 pt, bold, black, 10 pt before and 5 pt after.
- Table body: 9.2 to 9.5 pt. Table headers: 9.5 pt bold dark navy.

## Tables

- Thin light gray borders on all outer and internal edges.
- Pale gray or pale blue header fills with dark navy text.
- Intentional column widths, generous cell margins, vertical centering, and repeating header rows.
- Center short result cells and use pale green, amber, or red status fills.
- Use the opening label and value matrix without a repeating header because it has no semantic header row.

## Components and content flow

1. Eyebrow, title, subtitle, review metadata, decision, and acceptance outcome.
2. Three-component development scope, supporting files, non-scope items, and DevA-to-Merge parity evidence.
3. DevA check-only evidence, test coverage, security observations, and review boundaries.
4. Required completion gates and a ready-to-paste peer-review response.

## Slot map

- Replace all SCC-3384 body content with SCC-4095 peer-review evidence.
- Reuse page geometry, typography, evidence tables, status colors, spacing rhythm, and footer treatment.
- Keep the footer environment label as GreatPlainsDevA.
- Remove all Trouble Ticket-specific tables and prose.
- Replace core properties with SCC-4095 peer-review metadata.

## Package preservation

- Editable: `word/document.xml`, footer text if needed, and core properties.
- Preserve semantically: styles, theme, numbering, font table, section geometry, table treatment, PAGE field behavior, headers, and unrelated relationships.
- Preserve the unused inherited media part; do not introduce any drawing into the new body.
- Do not modify the retained reference file.

## Fidelity gates

- The retained reference hash must remain unchanged.
- The final must remain recognizably part of the Great Plains peer-review series.
- All titles, subtitles, and headings must be black.
- Every evidence table must have visible light gray borders and padding; true header rows must repeat.
- Render and inspect every final page for clipping, overlap, broken tables, blank trailing pages, and footer collisions.
