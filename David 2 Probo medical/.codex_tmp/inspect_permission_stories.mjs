import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = process.argv[2];
const outputDir = process.argv[3];
if (!inputPath || !outputDir) throw new Error("Usage: node inspect_permission_stories.mjs <input.xlsx> <output-dir>");

await fs.mkdir(outputDir, { recursive: true });
const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(inputPath));

const overview = await workbook.inspect({
  kind: "workbook,sheet,table",
  maxChars: 12000,
  tableMaxRows: 12,
  tableMaxCols: 12,
  tableMaxCellChars: 180,
});
await fs.writeFile(path.join(outputDir, "overview.ndjson"), overview.ndjson, "utf8");

const extracted = [];
for (const sheet of workbook.worksheets.items) {
  const used = sheet.getUsedRange(true);
  const values = used?.values ?? [];
  const formulas = used?.formulas ?? [];
  const rows = [];
  const caseRows = [];
  for (let r = 0; r < values.length; r += 1) {
    const row = values[r] ?? [];
    const text = row.map((v) => v == null ? "" : String(v)).join(" | ");
    if (/case|story|user|permission|request|000\d{4,}/i.test(text)) {
      rows.push({ rowNumber: r + 1, values: row, formulas: formulas[r] ?? [] });
    }
    const rawCase = row[3];
    if (rawCase !== null && rawCase !== undefined && String(rawCase).trim() !== "" && !/^case number$/i.test(String(rawCase).trim())) {
      caseRows.push({
        rowNumber: r + 1,
        caseNumber: String(rawCase).trim(),
        summary: row[0] ?? null,
        theme: row[1] ?? null,
        productArea: row[2] ?? null,
        processArea: row[4] ?? null,
        status: row[5] ?? row[7] ?? null,
        size: row[6] ?? row[8] ?? null,
        submittedBy: row[7] ?? row[9] ?? null,
        assignedTo: row[8] ?? row[10] ?? null,
        comments: row[9] ?? row[11] ?? null,
        values: row,
      });
    }
  }
  extracted.push({ sheet: sheet.name, rowCount: values.length, columnCount: Math.max(0, ...values.map((r) => r.length)), matchingRows: rows, caseRows });

  if (values.length && values[0]?.length) {
    const previewRows = Math.min(values.length, 50);
    const previewCols = Math.min(Math.max(...values.map((r) => r.length)), 16);
    const endCol = (n) => {
      let s = "";
      while (n > 0) { n -= 1; s = String.fromCharCode(65 + (n % 26)) + s; n = Math.floor(n / 26); }
      return s;
    };
    const preview = await workbook.render({
      sheetName: sheet.name,
      range: `A1:${endCol(previewCols)}${previewRows}`,
      scale: 1,
      format: "png",
    });
    await fs.writeFile(path.join(outputDir, `${sheet.name.replace(/[^a-z0-9_-]+/gi, "_")}.png`), new Uint8Array(await preview.arrayBuffer()));
  }
}

await fs.writeFile(path.join(outputDir, "matching_rows.json"), JSON.stringify(extracted, null, 2), "utf8");
console.log(JSON.stringify(extracted, null, 2));
