# SCC-3655 architect review template contract

## Reference

- Reference DOCX: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\SCC-3386-architect-review.docx`
- SHA-256: `E60717C3786229BF42C922EDE8804B80C324E583D7704607A54F990EAF54E68E`
- Reference pages: 5
- Sections: 1
- Reference render: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\.codex-qa\scc3655-architect-template\reference-render`
- Style evidence: `C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3\.codex-qa\scc3655-architect-template\template-style-evidence.json`

## Page system

- US Letter portrait: 8.5 x 11 inches.
- Margins: 1 inch on all sides; usable width 6.5 inches / 9360 DXA.
- Header and footer distance: 0.492 inches.
- One section, no first-page or odd/even visual variation.
- Explicit page breaks create five page patterns; no multi-column sections.
- Footer is right aligned, Arial 9 pt, muted gray, with environment label, separator, and a real PAGE field.

## Typography and color

- Primary font: Arial throughout.
- Normal: 11 pt, ink `#1F2937`, 1.10 line spacing, 0 pt before, 6 pt after.
- Heading 1: Arial 16 pt bold, blue `#2E74B5`, 12 pt before, 6 pt after, keep with next.
- Heading 2: Arial 13 pt bold, blue `#2E74B5`, 10 pt before, 5 pt after, keep with next.
- Heading 3: Arial 12 pt bold, navy `#0B2545`, 8 pt before, 4 pt after, keep with next.
- Eyebrow: Arial 10 pt bold uppercase, blue `#2E74B5`.
- Main title: Arial 25 pt bold, navy `#0B2545`, 4 pt after.
- Subtitle: Arial 13 pt, muted `#5B6777`, 16 pt after.
- Table header: Arial 9.5 pt bold navy on light gray `#F2F4F7`.
- Table body: Arial 9.2 pt ink, 1.05 line spacing.
- Status colors: teal `#16836B` on `#E7F5F1`; amber `#B7791F` on `#FFF6DE`; red `#C53030` on `#FDECEC`.
- Informational callout: blue `#2E74B5` on `#EAF2FA`.

## Tables and components

- Tables use Table Grid, fixed layout, left alignment, 120 DXA indent, explicit DXA widths totaling 9360.
- Cell margins: top/bottom 100 DXA; start/end 140 DXA. Cells vertically center; rows expand naturally.
- Header rows repeat across pages.
- Status columns are centered and use semantic fill/color.
- Callouts are one-cell full-width tables with uppercase 9 pt label and navy 11 pt bold message.
- Architecture figure is centered at 6.45 inches wide with a centered muted italic 9 pt caption and descriptive alt text.
- No decorative cover page; page 1 combines title block, metadata, decision callout, and acceptance matrix.

## Content flow and slot map

1. Page 1: eyebrow, SCC title, environment subtitle, five-row metadata table, architect decision callout, acceptance outcome matrix.
2. Page 2: solution path heading and lead, one architecture figure, caption, design-reading callout.
3. Page 3: detailed configuration findings using two or three evidence tables and one persona/security callout.
4. Page 4: runtime/UAT evidence boundary plus a concise numbered execution matrix.
5. Page 5: approval gates and a full-width ready-to-paste story response.

Editable body slots may be rewritten for SCC-3655. The reference's visual components, section geometry, heading ladder, table treatment, callout treatment, figure sizing, footer field pattern, and page rhythm must be retained. The SCC-3386 facts and image must not carry into the new document.

## Package preservation

- Preserve source-derived `word/styles.xml`, `word/theme/theme1.xml`, font table, web settings, numbering baseline, section geometry, and header/footer design patterns.
- The body XML, core properties, footer environment text, relationships to the body image, thumbnail, and body image are editable for the new SCC-3655 content.
- PAGE fields must remain real fields and render with the correct final page number.
- The retained reference must remain byte-for-byte unchanged at the recorded path and hash.

## Fidelity gates

- Five visually coherent pages with the same title hierarchy, palette, table density, callout styling, and footer rhythm as the reference.
- No SCC-3386 text or image may remain.
- No table width may exceed 9360 DXA; no fixed row heights; no clipped, overlapping, boundary-hugging, or awkwardly wrapped text.
- The Gate column must be wide enough to keep its header on one line, improving the reference defect.
- Every final page must be rendered and inspected at 100 percent.
- Accessibility audit must report no findings; figure must include title and alt text; table header rows must repeat.
