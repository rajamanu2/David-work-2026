# SCC-4485 PR Review template contract

## Reference

- Absolute reference: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-4179-architect-review.docx`
- SHA-256: `6CD3A83323E24FCE40799F07B7E2A0D0E8960AC060138EF1B827A2DEE7B5E2A9`
- Render evidence: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc4485-pr-review-work\reference-render`
- Page count: 5
- Section count: 1
- Style evidence: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc4485-pr-review-work\reference-style.json`

## Page system

- US Letter portrait, 8.5 x 11 inches.
- Margins: 1 inch on every side.
- Header and footer distance: 0.492 inch.
- One section; no distinct first, odd, or even page pattern.
- Explicit page breaks separate five content pages.
- Footer is right aligned: `GreatPlainsMerge  |  Page {PAGE}` in Arial 9 pt muted gray.

## Typography and color

- Base: Arial 11 pt, dark ink `#1F2937`, 1.10 line spacing, 6 pt after.
- Eyebrow: Arial 10 pt bold, blue `#2E74B5`.
- Title: Arial 25 pt bold, navy `#0B2545`, 4 pt after.
- Subtitle: Arial 13 pt, muted `#5B6777`, 16 pt after.
- Heading 1: Arial 16 pt bold blue, 12 pt before, 6 pt after, keep with next.
- Heading 2: Arial 13 pt bold blue, 10 pt before, 5 pt after, keep with next.
- Heading 3: Arial 12 pt bold navy, 8 pt before, 4 pt after, keep with next.
- Decision/blocker callouts: pale red fill with red label; supporting guidance uses pale blue or pale amber.
- Status language is restrained and explicit: Blocker/Changes Requested in red, Verified in teal, Not reviewed in amber.

## Tables and recurring components

- Usable width: 9360 DXA; tables have fixed DXA grids and 120 DXA indent.
- Cell margins: 80 top, 120 start, 80 bottom, 120 end.
- Header rows use pale gray fill, Arial 9.5 pt navy bold, and `w:tblHeader` repeat markup.
- Body cells use Arial 9.2 pt; status cells are centered, bold, and color coded.
- Metadata block: two columns, 1900/7460 DXA, pale-blue label cells.
- Callout block: one cell, full 9360 DXA width; uppercase 9 pt label plus 11 pt navy bold message.
- One 6.45-inch centered process figure on page 2, with meaningful alt text and a centered italic caption.

## Content flow and editable slots

1. Page 1: `PR REVIEW` eyebrow, SCC-4485 title, read-only review subtitle, five-row metadata block, merge-decision callout, and severity summary table.
2. Page 2: required implementation path, one process diagram, and reviewer interpretation callout.
3. Page 3: detailed PR findings with component/location, severity, issue, impact, and required modification. No IT/UAT test cases.
4. Page 4: component-level change specification, defensive design requirements, and merge checklist. No deployment sequence or test script.
5. Page 5: review evidence and limitations, explicit excluded material, and a ready-to-paste PR comment.

All body content is rewritten for SCC-4485. Page geometry, styles, footer, table system, callout system, color palette, and figure treatment remain source-derived.

## Evidence and scope rules

- Review source: live, read-only GreatPlainsMerge configuration for OmniProcess `SQ/OrderPipeline` v5 and OmniDataTransform `AccountCreation` v1, plus Account schema and aggregate outcomes.
- No repository PR URL, branch, commit, or diff was supplied; do not claim line-by-line source-diff review.
- No IT, integration, UAT, or buy-flow test steps belong in this artifact.
- No org write, deployment, activation, account creation, or permission change is authorized.
- Clearly distinguish direct evidence, reviewer inference, and the missing PR artifact limitation.

## Package preservation and fidelity gates

- Preserve the reference's styles, theme, numbering, section geometry, header/footer relationships, page field, and table/callout visual system.
- Replace the body and figure only; do not modify the retained reference.
- Final output must be a separate DOCX and the reference SHA-256 must remain unchanged.
- Run section, style, image, and accessibility audits on the output.
- Render all final pages through Word-to-PDF plus Poppler and inspect every PNG at 100 percent.
- Fail delivery for clipping, overlap, broken tables, missing figure alt text, unmarked data-table headers, unexplained pagination drift, visible placeholder text, IT-test content, or any claim that a PR diff was reviewed.
