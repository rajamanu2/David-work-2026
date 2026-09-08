# SCC-4487 PR Review template contract

## Reference

- Retained reference: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-4179-architect-review.docx`
- SHA-256: `6CD3A83323E24FCE40799F07B7E2A0D0E8960AC060138EF1B827A2DEE7B5E2A9`
- Size: 217,293 bytes
- Pages: 5 (fresh Microsoft Word PDF export)
- Sections: 1
- Visual evidence: `scc4487-pr-review-work\reference-render-word\page-1.png` through `page-5.png`
- Structural evidence: `scc4487-pr-review-work\reference-style-evidence.json`

## Page system

- US Letter, portrait, 8.5 x 11 inches.
- Margins: 1 inch on all sides; usable width 9,360 DXA.
- Header and footer distances: 0.492 inch.
- One section; no different-first-page or odd/even-page treatment.
- Major content units begin on explicit page breaks. Footer is right-aligned and shows environment label, separator, and PAGE field.

## Typography and color

- Typeface: Arial throughout, with both ASCII and hAnsi font mappings.
- Normal: 11 pt, ink `#1F2937`, 0 pt before, 6 pt after, 1.10 line spacing.
- Title label: 10 pt bold uppercase, blue `#2E74B5`.
- Main title: 25 pt bold, navy `#0B2545`.
- Subtitle: 13 pt, muted `#5B6777`.
- Heading 1: 16 pt bold blue, 12 pt before, 6 pt after.
- Heading 2: 13 pt bold blue, 10 pt before, 5 pt after.
- Heading 3: 12 pt bold navy, 8 pt before, 4 pt after.
- Status palette: pass teal `#16836B` / `#E7F5F1`; blocker red `#C53030` / `#FDECEC`; conditional amber `#B7791F` / `#FFF6DE`; information blue `#2E74B5` / `#EAF2FA`.

## Tables and callouts

- Tables are left aligned, fixed layout, 9,360 DXA total width, 120 DXA indent.
- Column widths are content-specific and must sum to 9,360 DXA.
- Cell margins: 80 top, 120 start, 80 bottom, 120 end DXA.
- Header rows use light gray fill, bold navy text, and repeating `w:tblHeader` semantics.
- Status cells use centered bold colored text and matching light fill.
- Callouts are single-cell tables with explicit geometry, colored fill, uppercase 9 pt label, and 11 pt bold navy decision text.
- All data-table header rows must be structurally marked; layout/callout tables must not be falsely marked as data headers.

## Components and content flow

1. Page 1: small review label, large story title, subtitle, five-row metadata block, red architect decision callout, and compact PR review outcome table.
2. Page 2: solution/design heading, one explanatory paragraph, a full-width four-stage process visual with caption/alt text, and blue design-reading callout.
3. Page 3: detailed current-state evidence tables and a red blocker callout.
4. Page 4: implementation boundary plus required modifications, with an amber PR approval gate.
5. Page 5: approval checklist and ready-to-paste review comment.

For SCC-4487, the final document may use four pages if the content fits without shrinking type or creating dense tables. It must not include IT testing, UAT execution steps, test cases, deployment instructions, or post-deployment validation. The document is a PR review only.

## Slot map

- Opening label: replace `ARCHITECT REVIEW` with `PR REVIEW`.
- Main title/subtitle: replace with SCC-4487 and the declarative metadata review boundary.
- Metadata block: replace all values; retain five-row structure and column geometry.
- Decision and status table: rewrite completely for PR findings.
- Diagram: replace with SCC-4487 Account-to-Order metadata path; retain image size, caption pattern, and alt-text treatment.
- Detailed evidence: replace CPNI tables with SCC-4487 component-by-component review evidence.
- Implementation boundary: replace with exact files, formula/FLS/layout requirements, and required PR modifications.
- Final page: replace UAT/test gates with PR approval checklist and ready-to-paste PR comment only.
- Header/footer/page furniture: preserve source-derived formatting; footer environment label may be updated to `GreatPlainsMerge | PR Review`.

## Package preservation

- Reference package contains 25 parts.
- Preserve styles, styles-with-effects, numbering, settings, content types, theme, section geometry, header/footer structure, relationships, and document properties except the intended core-property text updates.
- Body XML and the diagram media/relationship are editable because all review content is story-specific.
- No comments, tracked changes, content controls, footnotes, or endnotes are required.

## Fidelity gates

- Reference hash must remain unchanged.
- Final page geometry, typography, palette, table geometry, callout construction, footer treatment, and page rhythm must remain recognizably source-derived.
- No clipped/overlapping text, broken tables, orphaned headings, unexplained blank pages, or internal tool/citation tokens.
- All final pages must be exported through Microsoft Word and inspected as PNGs because the packaged LibreOffice renderer is blocked by Windows temporary-profile permissions in this workspace.
