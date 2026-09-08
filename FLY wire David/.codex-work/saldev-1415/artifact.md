# SALDEV-1415 architect-review template contract

- Reference: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-4179-architect-review.docx`
- SHA-256: `6cd3a83323e24fce40799f07b7e2a0d0e8960ac060138ef1b827a2dee7b5e2a9`
- Render evidence: `.codex-work\saldev-1415\scc-template-word-render\page-1.png` through `page-5.png`; all five pages inspected at full resolution.
- Structure evidence: one portrait section, 33 top-level paragraphs, 13 tables, one inline visual, 25 package parts.

## Page system

- US Letter portrait, 8.50 x 11.00 inches; 1.00-inch margins on all sides.
- One section, new-page start, no different-first-page or odd/even setting.
- Footer role: right-aligned environment label, separator, and dynamic PAGE field; 9 pt gray. Preserve the PAGE field and replace only the environment text.
- No visible header furniture.

## Typography and hierarchy

- Arial is the source typeface throughout.
- Eyebrow: Arial 10 pt bold, uppercase, blue `2E74B5`, 12 pt before and 2 pt after.
- Title: Arial 25 pt bold, navy `0B2545`, 4 pt after.
- Subtitle: Arial 13 pt regular, gray `5B6777`, 16 pt after.
- Heading 1: blue `2E74B5`, approximately 16 pt bold; Heading 2: blue, approximately 13 pt bold.
- Body: Arial 10-11 pt, dark slate; compact paragraph rhythm with clear spacing before section blocks.
- Status colors: red `D32F2F`/pale red `FCE8E8`; green `11856F`/pale green `E4F3EF`; amber `B8750C`/pale amber `FFF4D6`; blue callout `E7F1FB`.

## Components and geometry

- Page 1: eyebrow, large story title, subtitle, 2-column metadata table `[1900, 7460]`, 1-cell architect-decision callout `[9360]`, and 4-column acceptance table `[500, 2150, 1450, 5260]`.
- Page 2: solution summary, labeled control-path visual with red/green/amber stages, caption, and 1-cell design-reading callout.
- Page 3: evidence tables and a full-width blocker callout.
- Page 4: focused implementation scope table `[2100, 3900, 3360]`, release sequence `[1900, 7460]`, and a full-width gate callout.
- Page 5: UAT matrix `[2100, 7260]`, approval gates `[500, 2400, 2200, 4260]`, and a full-width ready-to-paste response callout.
- Tables use 9360 DXA usable width, explicit grids, 120 DXA text-aligned indent, natural row height, medium cell padding, dark slate borders, and pale gray `F1F3F6` headers.

## Content slot map

- Rewrite story title/subtitle, metadata, decision, acceptance outcomes, solution path, evidence, release boundary, UAT gates, and story comment for SALDEV-1415.
- Replace the original CPNI control path with a SALDEV-1415 path: Quote inputs -> Group automation -> Quote-line synchronization -> Release proof.
- Replace environment-specific evidence tables with a current component inventory, test-run evidence, and live quote read-back.
- Reuse the source's table, callout, status-color, heading, caption, and footer patterns.
- Do not carry SCC-4179 facts, Great Plains org names, CPNI fields, or permission-set conclusions into the final document.

## Package preservation

- Preserve styles, theme, font table, numbering, settings, web settings, customXml parts, relationship framework, and footer PAGE field behavior.
- `word/document.xml`, footer environment text, core/app properties, and visual media are editable.
- Source media may be removed or replaced because it depicts SCC-4179-specific CPNI architecture; no stale source image may remain visible.
- No comments, tracked changes, footnotes, or content controls were detected.

## Fidelity gates

- Final must remain a five-page architect-review style report unless content fit requires one additional page; it must not use landscape pages.
- Keep the Arial/blue/navy visual system, status fills, compact evidence tables, callout hierarchy, and dynamic footer page number.
- Inspect every final page for clipped cells, excessive density, broken pagination, missing footer fields, stale SCC-4179 content, or stale source images.
- The retained reference must remain byte-for-byte unchanged.
