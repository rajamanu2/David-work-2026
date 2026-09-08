import fs from "node:fs/promises";
import { SpreadsheetFile } from "@oai/artifact-tool";

const workbookPath = "../outputs/security_access_review_2026-08-19/Pro_Biomedical_Detailed_User_Permission_Risk_Review_2026-08-19.xlsx";
const data = await fs.readFile(workbookPath);
const workbook = await SpreadsheetFile.importXlsx(data);
const summary = workbook.worksheets.getItem("Summary");
summary.getRange("E13").formulas = [["=21899"]];
summary.getRange("E14").formulas = [["=455834"]];
const check = await workbook.inspect({ kind: "table", range: "Summary!D11:F15", include: "values,formulas", tableMaxRows: 8, tableMaxCols: 3 });
const errors = await workbook.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A", options: { useRegex: true, maxResults: 100 } });
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(workbookPath);
console.log(JSON.stringify({ check, errors }, null, 2));
