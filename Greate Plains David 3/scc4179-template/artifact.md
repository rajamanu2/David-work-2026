# SCC-4179 architect-review template contract

## Reference

- Reference DOCX: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-3387-architect-review.docx`
- SHA-256: `022B13FC8B3A8DA8D7DC5F0C96EB5B5AE410979F34ECEB317826B2B9D15AD420`
- Page count: 5
- Section count: 1
- Render evidence: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc3387-docx-qa\page-1.png` through `page-5.png`
- Style evidence: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc4179-template-style-evidence.json`

## Page system

- US Letter portrait, 8.5 x 11 inches.
- One section; 1-inch margins on all sides; 0.492-inch header and footer distances.
- No distinct first/even-page treatment. Each major content unit starts on a manual new page.
- Usable content width is 9360 DXA. Footer is right-aligned and reads `GreatPlainsMerge | Page {PAGE}`.

## Typography and color

- Arial throughout.
- Normal: 11 pt, ink `1F2937`, 1.10 line spacing, 6 pt after.
- Eyebrow: 10 pt, bold, blue `2E74B5`, uppercase.
- Title: 25 pt, bold, navy `0B2545`; subtitle: 13 pt, muted `5B6777`.
- Heading 1: 16 pt, bold, blue, 12 pt before/6 pt after; Heading 2: 13 pt, bold, blue, 10/5 pt.
- Table headers: 9.5 pt bold navy on `F2F4F7`; body 9.2-9.5 pt.
- Status fills: pass `E7F5F1`/`16836B`; caution `FFF6DE`/`B7791F`; fail `FDECEC`/`C53030`.
- Callouts use a single full-width cell, 9360 DXA, label at 9 pt uppercase and message at 11 pt bold navy.

## Lists, tables, and figures

- Tables are fixed-width, left-aligned, with 120 DXA table indent and explicit column grid/cell widths totaling 9360 DXA.
- Cell margins: 80 top/bottom and 120 start/end for review tables; vertical alignment centered; rows expand naturally.
- Table header rows repeat across pages.
- Figures are centered at 6.45 inches, followed by centered 9 pt muted italic captions and meaningful alt text.
- Visual diagrams use a 1600 x 1000 light-gray canvas, navy titles, rounded status boxes, directional arrows, and a lower architect-reading panel.

## Content flow and slot map

1. Decision memo: eyebrow, ticket title, subtitle, five-row metadata table, red decision callout, acceptance outcome matrix.
2. Solution and control path: short lead paragraph, one full-width diagram, caption, design-reading callout.
3. Evidence page: comparable access-grant tables and a focused blocker callout.
4. Implementation page: component boundary, release sequence, and production-inventory gate.
5. Approval page: UAT checks, required approval gates, and ready-to-paste architect response.

All body content is rewritten for SCC-4179. The reference's styles, numbering, section geometry, header/footer relationships, theme, and table/figure visual grammar are preserve-only. The reference remains unchanged; the output is built from a working copy with a replaced body.

## Fidelity gates

- Preserve the reference hash, one-section page geometry, Arial hierarchy, navy/blue palette, status colors, right footer, fixed table geometry, callout treatment, and five-page narrative order.
- Inspect every final page at 100% zoom for clipping, table overflow, cramped cells, broken page breaks, missing glyphs, and footer alignment.
- Confirm all figures have alt text, table header rows repeat, no blank trailing page exists, and the final package opens cleanly in Word.
