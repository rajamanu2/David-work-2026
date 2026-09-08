# Strategy Memorandum Template Contract

## Reference

- Retained file: `C:\Users\LIKKI\.codex\plugins\cache\openai-curated-remote\openai-templates\0.1.1\skills\artifact-template-strategy-memorandum\assets\reference.docx`
- SHA-256: `13BD3AE7AEF4B3AE76C5D65200ACD654C922782974DAC18672E973FAD93BD453`
- Recorded Word page count: 9.
- Section count: 1.
- Visual evidence: retained preview PNG plus attempted render logs under this task directory. LibreOffice is not installed on the host, so the canonical renderer cannot produce new template page PNGs.
- Structural evidence: `template-style-evidence.json`, section audit output, paragraph/table inventory, and OOXML package inventory captured during this run.

## Page system

- US Letter portrait, 8.5 x 11 inches.
- Margins: 1 inch on all sides; no gutter.
- Header distance: 0.4896 inch. Footer distance: 0.4917 inch.
- One section, no linked prior header/footer, no different-first-page setting, no odd/even variation.
- The requested side-by-side code comparison may add a landscape section after the portrait executive summary because code readability is an explicit user requirement. Header/footer styling must remain source-derived.

## Typography

- Primary family: Helvetica Neue; the template embeds fonts and uses direct formatting extensively.
- Title: Helvetica Neue, 36 pt, bold, centered, navy `#112075`, 14 pt before and 8 pt after.
- Heading 1: Helvetica Neue, 15 pt, bold, navy `#112075`, 14 pt before and 8 pt after.
- Heading 2: Helvetica Neue, bold, navy `#112075`, 10 pt before and 5 pt after.
- Heading 3: bold, dark gray `#404040`, 7 pt before and 4 pt after.
- Code override: Consolas 7.5-8 pt, single-spaced, with red-tinted old cells and green-tinted new cells. This exception is required for exact code comparison and must be reused consistently.

## Lists and tables

- Preserve the template numbering definitions and table visual language.
- The cover metadata pattern is a 2-column label/value table.
- New code-comparison tables are true 2-column repeated comparisons with explicit equal column widths, repeated `OLD CODE` / `NEW CODE` headers, expandable rows, consistent cell padding, and no fixed row heights.
- Portrait usable width: 6.5 inches. Landscape code section usable width: 9 inches.

## Components and flow

1. Source-derived title page with top rule, title, subtitle, metadata, and confidentiality/page footer.
2. Plain-English executive explanation of the problem and fix.
3. Scope summary covering the three changed Apex classes and unchanged metadata files.
4. Side-by-side diff sections for every changed hunk in each class.
5. Verification and scope notes.

## Slot map

- Title and subtitle: replace the source title placeholders.
- Cover metadata table: replace Author/Team/Prepared for/Date/Status values with verified task metadata; do not invent a personal author.
- Strategy sections and option tables: replace with problem, resolution, class overview, and code comparisons.
- Figures and financial sections: remove because they are unsupported by the user request.
- Header/footer: preserve the source navy rule, document label treatment, confidentiality treatment, and page numbering behavior, adapting only the label text.

## Package preservation

- Preserve the retained reference file unchanged.
- Preserve source theme, styles, numbering, embedded fonts, header/footer relationships, footnotes/endnotes parts, and media unless the new document content explicitly makes an original drawing unused.
- Expected editable/rebuilt parts: `word/document.xml`, section definitions needed for landscape code pages, header/footer visible text, core/app document properties.
- Preserve-only structure hashes were recorded for styles (`50fc11ad...`), numbering (`dfc42a06...`), theme (`742bf86b...`), font table (`b3f922c9...`), and relationship parts.

## Fidelity gates

- Retained reference hash must remain unchanged.
- Final document must retain the navy/blue strategy-memo visual system and Helvetica Neue body hierarchy.
- Every changed Apex hunk must appear exactly once in a side-by-side table.
- No OAuth client secret or unchanged credential line may be reproduced.
- No table may clip code, use fixed row height, or lose wrapping.
- If canonical rendering remains unavailable because LibreOffice is missing, perform structural, text, table-geometry, package, and accessibility audits and disclose the missing render gate.
