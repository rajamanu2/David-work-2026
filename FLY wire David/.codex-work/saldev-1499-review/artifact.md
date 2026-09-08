# SALDEV-1499 architect review template contract

## Reference

- Retained reference: `C:\Users\LIKKI\Downloads\SALDEV-1413-architect-review.docx`
- SHA-256: `9C1A9F936367232B5DD8F9C08C98A6C801259257B220C84E76CE3CFA3937C13F`
- Rendered page count: 5
- Section count: 1
- Visual evidence: `.codex-work\saldev-1499-review\reference-word-export\page-1.png` through `page-5.png`
- Structural evidence: `.codex-work\saldev-1499-review\template-style-evidence.json` plus section, heading, image, field, and footnote audits

## Page system

- US Letter portrait, 8.5 x 11 inches.
- One section, new-page start, one column.
- Margins: 1.0 inch on all sides.
- Same header/footer behavior on all pages; no different first page and no odd/even split.
- Footer is right aligned and reads `FlywirePartial  |  Page` followed by a dynamic PAGE field.

## Typography and color roles

- Typeface: Arial throughout.
- Eyebrow: uppercase, bold, approximately 11-12 pt, blue `#2E75B6`.
- Main title: bold, approximately 25-27 pt, dark navy `#0B2545`, compact line spacing.
- Subtitle: approximately 14 pt, gray `#5E6B7E`.
- Heading 1: bold Arial, approximately 17 pt, blue `#2E75B6`, 12 pt before and 6 pt after, keep with next.
- Heading 2: bold Arial, approximately 13 pt, blue `#2E75B6`, 10 pt before and 5 pt after, keep with next.
- Body: Arial 10.5-11 pt, dark charcoal `#263445`, 1.05-1.1 line spacing.
- Table headers: bold navy on pale gray `#F1F3F6`.
- Failure/blocker: red `#D13232` on pale red `#FCEAEA`.
- Partial/risk: amber `#B97816` on pale amber `#FFF4D9`.
- Pass/confirmed: teal-green `#168A73` on pale green `#E5F3EF`.
- Informational callout: blue/navy on pale blue `#EAF2FB`.

## Lists and tables

- Tables use explicit 6.5-inch geometry, fixed column grids, thin black borders, and 0.08-0.10 inch cell padding.
- Header rows repeat when a table crosses a page.
- Narrative columns are left aligned; status columns are centered and bold where appropriate.
- Rows expand naturally; no fixed row heights.
- The reference uses tables only for comparable status, evidence, phase, test, and approval records.

## Recurring components

- Page 1 title block, five-row metadata table, colored architect-decision callout, and acceptance-outcome matrix.
- Page 2 correction-path narrative, one wide process diagram, centered italic figure caption, and blue design-reading callout.
- Evidence pages combine Heading 1/2 hierarchy, compact evidence tables, and a red blocker callout.
- Release pages use component/action and phase/evidence tables plus an amber production gate.
- Final page contains UAT matrix, approval-gate matrix, and a blue ready-to-paste story-comment box.
- Footer repeats environment and dynamic page number.

## Content flow for SALDEV-1499

1. Title, environment, evidence, decision, boundary, architect decision, and acceptance outcome.
2. Incident mechanism and correction/control path diagram.
3. Live Salesforce implementation evidence: flow state, Apex state, tests, and coverage.
4. Detailed code-review findings and requirement-alignment risks.
5. Focused correction scope, validation sequence, and production boundary.
6. UAT/approval gates and a ready-to-paste team/Jira response.

## Slot map

- Rewrite all body content for SALDEV-1499 while preserving page geometry, style system, footer, and recurring component patterns.
- Replace the SALDEV-1413 title/subtitle/metadata/decision values.
- Replace all 13 source tables with SALDEV-1499-specific tables using the same visual roles; row counts may change where content requires it.
- Replace the source figure with a new SALDEV-1499 process diagram using the same four-stage red/red/amber/green progression and blue reading box.
- Preserve the footer and its PAGE field.
- Remove the SALDEV-1413 body image and body content; do not copy its factual claims into the new document.

## Package preservation

- Preserve the reference file unchanged at its original path.
- Working output must use a different absolute path.
- Preserve section geometry, styles/theme, numbering definitions, footer relationship, and PAGE field.
- Body XML, body tables, document relationships for the replaced figure, core properties, and the replacement image are editable.
- No comments, footnotes, endnotes, or content-control dependencies were observed.
- Reference contains one inline body image and three PAGE field occurrences across footer parts; the final requires one active footer PAGE field for its single section.

## Fidelity gates

- Reference SHA-256 remains unchanged.
- Final remains US Letter portrait with one-inch margins and a recognizably source-derived Arial/navy/blue review system.
- Every final page is exported through Word, rasterized, and inspected at 100 percent.
- No clipping, overlaps, broken tables, undersized type, orphan headings, or footer collisions.
- Status colors retain the same meaning: red blocker, amber risk/gate, green confirmed/pass, blue information.
- Final contains no SALDEV-1413 factual residue, placeholder text, or unsupported deployment claim.
