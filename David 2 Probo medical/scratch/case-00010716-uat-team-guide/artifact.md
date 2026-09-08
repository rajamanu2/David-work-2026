# AutoFast reference execution contract

## Reference

- Retained reference: `C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical\scratch\case-00010716-uat-team-guide\autofast-reference.docx`
- SHA-256: `1FBF407FF7278DDD7F71A3D578EFD8F24540C3F26AF0CF5C1D94C15A82CBBE05`
- Reference title: `AUTOFAST DEVDO VALIDATION & UAT GUIDE`
- Section count: 1
- Reference render: unavailable because LibreOffice/soffice is not installed.
- Structural evidence: section audit, image audit, style inspection, complete paragraph/table inventory, and the existing AutoFast builder scripts.

## Page system

- US Letter portrait, 8.5 x 11 inches.
- One section with 1-inch margins on all sides.
- No different-first-page or odd/even-page behavior.
- Header and footer are plain text/page-number furniture.

## Typography and color

- Normal: Calibri 11 pt, 1.1 line spacing, 6 pt after.
- Title: Calibri 23 pt, bold, navy `0B2545`, 4 pt after.
- Subtitle: Calibri 14 pt, italic, gray `555555`, 14 pt after.
- Heading 1: Calibri 16 pt, bold, blue `2E74B5`, 16 pt before and 8 pt after.
- Heading 2: Calibri 13 pt, bold, blue `2E74B5`, 12 pt before and 6 pt after.
- Heading 3: Calibri 12 pt, bold, dark blue `1F4D78`, 8 pt before and 4 pt after.
- Table header: dark navy fill with white bold text; body rows use white and pale blue banding.

## Lists and tables

- Use tables for repeated step/action/expected-result data and evidence matrices.
- Tables use exact DXA widths, repeated header rows, at least 100 DXA cell padding, and no fixed row heights.
- Use real Word list styles only when necessary; no manually typed bullets.

## Components

- Opening block: large AutoFast title, explanatory subtitle, compact metadata lines, and an architect/implementation determination callout.
- Body: numbered Heading 1 sections, concise prose, and clean tables.
- Footer: `Internal UAT Guide | Page X of Y` using Word fields.
- No visible images, shapes, charts, or screenshots.

## Content flow and slots

1. Case summary and current readiness.
2. Original defect and what changed.
3. Historical reproduction scenario versus current UAT verification.
4. Dedicated UAT records and baseline values.
5. Manual UAT procedure with expected results.
6. Acceptance criteria and automated regression coverage.
7. Troubleshooting and environment impact.
8. Tester execution record and handoff note.

The new guide must replace all DevDO-specific and prior-case operational content. It may reuse the established AutoFast heading, table, callout, spacing, and color patterns.

## Package preservation and fidelity gates

- Preserve page setup, styles, table treatment, numbering definitions, and overall AutoFast rhythm by authoring from a copy of the retained reference.
- Header/footer text may be replaced to match the UAT guide.
- The final file must contain no deployment or validation IDs, no test-run IDs, and no frontdoor/session token.
- Salesforce record IDs and record links are allowed because they are required to execute the dedicated UAT test.
- Final checks: no placeholders, no visible images, no deployment IDs, no sensitive token references, consistent headings, exact table geometry, and readable tables.
