# SCC 3384 peer review document contract

## Reference

- Retained reference: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-3387-architect-review.docx`
- SHA-256: `022B13FC8B3A8DA8D7DC5F0C96EB5B5AE410979F34ECEB317826B2B9D15AD420`
- Reference render: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc3387-docx-qa`
- Reference page count: 5
- Reference section count: 1
- Section evidence: one Letter portrait section, 8.5 by 11 inches, 1 inch margins, 0.492 inch header and footer distances
- Style evidence: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc3384-work\template-style-evidence.json`
- Package inventory: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\scc3384-work\template-package-inventory.json`

## Page system

- Use one Letter portrait section with 1 inch margins.
- Use page breaks between the decision page, configuration analysis, automation and access analysis, and approval gates.
- Keep the footer right aligned with `GreatPlainsDevA  |  Page` and a Word PAGE field.
- Leave the header empty.

## Typography

- Use Arial throughout.
- Body: 11 pt, dark ink, 1.10 line spacing, 6 pt after.
- Title: Word Title style, 25 pt, bold, black, no rule or paragraph border.
- Eyebrow: 10 pt, bold, black.
- Subtitle: 13 pt, muted gray.
- Heading 1: 16 pt, bold, black, 12 pt before and 6 pt after.
- Heading 2: 13 pt, bold, black, 10 pt before and 5 pt after.
- Table body: 9.2 to 9.5 pt. Table headers: 9.5 pt bold dark navy.

## Tables

- Use thin light gray borders on all outer and internal cell edges.
- Use pale gray or pale blue header fills with dark navy text.
- Use intentional column widths, generous cell margins, vertically centered cells, and repeating header rows.
- Center short result/status cells and apply pale green, amber, or red fills to convey the review result.
- Do not use a one-cell table as a narrative callout. Present decisions as ordinary paragraphs.

## Components and content flow

1. Eyebrow, title, subtitle, review metadata, decision paragraph, and acceptance outcome table.
2. Configuration analysis covering record type, status process, layout, fields, and dependency chains.
3. Automation, data evidence, access evidence, and component boundary.
4. Required approval gates and a ready-to-paste peer-review response.

## Slot map

- Replace all reference body content with SCC-3384 review content.
- Reuse the reference typography scale, table treatment, spacing rhythm, page geometry, and footer pattern, while applying the current black-heading requirement.
- Replace the footer environment label with GreatPlainsDevA.
- Remove the reference diagram and its relationship because SCC-3384 is clearer as compact comparison tables and prose.
- Replace reference core properties with SCC-3384 peer-review metadata.

## Package preservation

- Editable: `word/document.xml`, body image relationship and media part, footer XML, core properties.
- Preserve semantically: `word/styles.xml`, `word/theme/theme1.xml`, `word/numbering.xml`, `word/fontTable.xml`, section geometry, table styles, page field behavior, and all package relationships not made obsolete by removing the reference figure.
- Do not modify the retained reference file.

## Fidelity gates

- The retained reference hash must remain unchanged.
- The final must remain recognizably part of the same Great Plains review series through page geometry, Arial typography, metadata table, evidence tables, and footer treatment.
- The Word Title style must be black and unbordered, even though the older reference used direct navy formatting.
- Every table must have visible light gray borders, padding, and a true repeating header row where applicable.
- Render every final page and confirm no clipping, overlap, blank trailing page, broken table, or footer collision.
