# SCC-4486 PR review template contract

## Reference

- Authoritative reference: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-4179-architect-review.docx`
- SHA-256: `6CD3A83323E24FCE40799F07B7E2A0D0E8960AC060138EF1B827A2DEE7B5E2A9`
- Render: 5 pages under `.codex-qa\scc4486-pr-review\reference-render`
- Sections: 1 portrait section; every reference page was visually inspected.

## Page system

- US Letter portrait, 8.5 x 11 inches, 1-inch margins.
- Header and footer distance: 0.492 inch.
- One stable page pattern with five explicit page breaks and right-aligned footer text ending in a real PAGE field.
- The SCC-4486 deliverable may retain the five-page pattern; pagination may change only if needed to prevent clipping.

## Typography and color

- Arial throughout. Normal: 11 pt, ink `#1F2937`, 1.10 line spacing, 6 pt after.
- Eyebrow: 10 pt bold blue `#2E74B5`; title: 25 pt bold navy `#0B2545`; subtitle: 13 pt muted `#5B6777`.
- Heading 1: 16 pt bold blue, 12 pt before / 6 pt after. Heading 2: 13 pt bold blue, 10 pt before / 5 pt after.
- Tables: 9.5 pt body; navy bold header on light gray; real repeating header rows; status cells use red, amber, or teal fills.
- Callouts: single-cell bordered tables with uppercase accent label and navy bold message.

## Tables and components

- Metadata table: 2 columns, 1900/7460 DXA.
- Standard usable width: 9360 DXA. Every table has explicit grid/cell widths and 80/120/80/120 DXA cell margins.
- First page: title block, five-row metadata table, red decision callout, acceptance matrix.
- Second page: Heading 1, short lead paragraph, 6.45-inch inline figure and caption, blue reading callout.
- Third page: detailed finding tables and a red blocker callout.
- Fourth page: component/file-scope table, required-change table, amber evidence-boundary callout.
- Fifth page: PR approval gates and ready-to-paste peer-review response.

## Content slot map

- Rewrite all SCC-4179-specific body text, tables, title metadata, core properties, figure, caption, and footer label for SCC-4486.
- Preserve the reference visual system, section geometry, named styles, numbering definitions, table treatment, header/footer mechanics, and PAGE fields.
- Replace `word/media/image2.png` semantically with the SCC-4486 condition/dependency diagram; preserve the same inline figure role and approximate aspect ratio.
- Do not carry CPNI facts, UAT claims, deployment claims, or test results into the new document.
- State the evidence boundary explicitly: PR diff/files unavailable; live GreatPlainsMerge configuration inspected read-only; GreatPlainsUAT authentication expired; no IT/UAT execution; no deployment or org writes.

## Package preservation

- Preserve-only: `customXml/*`, styles, stylesWithEffects, numbering, theme, font table, web settings, headers, footers, PAGE fields, and unrelated relationships/media.
- Editable: `word/document.xml`, SCC-4486 figure media, document relationships only if the figure insertion requires it, and core/app properties.
- Baseline package contains 25 parts, including three headers, three footers, three PAGE fields, two PNG media parts, styles, numbering, theme, and one customXml group.

## Fidelity gates

- Reference remains byte-for-byte unchanged at the recorded hash.
- Final retains one Letter portrait section, 1-inch margins, Arial hierarchy, explicit table geometry, real headings, repeating table headers, and working PAGE fields.
- Final contains only PR-review findings and required code/configuration modifications; it must not present IT/UAT tests as executed.
- Render every final page through Microsoft Word PDF export plus Poppler PNG conversion because LibreOffice is unavailable, then visually inspect all pages.
