import fs from "node:fs/promises";
import { SpreadsheetFile } from "@oai/artifact-tool";

const filePath = "../outputs/Pro_Biomedical_User_Access_Inventory_2026-08-18.xlsx";
const bytes = await fs.readFile(filePath);
const workbook = await SpreadsheetFile.importXlsx(bytes);
const sheets = await workbook.inspect({ kind: "sheet", include: "id,name" });
const summary = await workbook.inspect({ kind: "table", range: "Summary!A1:F17", include: "values,formulas", tableMaxRows: 20, tableMaxCols: 8 });
const userMatrix = await workbook.inspect({ kind: "table", range: "'User Access Matrix'!A1:Q6", include: "values", tableMaxRows: 10, tableMaxCols: 20 });
const formulaErrors = await workbook.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A", options: { useRegex: true, maxResults: 100 }, summary: "Post-export formula error scan" });

console.log(JSON.stringify({
  bytes: bytes.length,
  sheets: sheets.ndjson,
  summary: summary.ndjson,
  userMatrix: userMatrix.ndjson,
  formulaErrors: formulaErrors.ndjson,
}, null, 2));
