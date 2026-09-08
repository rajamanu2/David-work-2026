import fs from "node:fs/promises";
import { SpreadsheetFile } from "@oai/artifact-tool";

const bytes = await fs.readFile("../outputs/Pro_Biomedical_User_Access_Inventory_2026-08-18.xlsx");
const workbook = await SpreadsheetFile.importXlsx(bytes);
const sheet = workbook.worksheets.getItem("Summary");
sheet.getRange("H30:H36").formulas = [
  ["=COUNTIF(Users!$H$2:$H$984,TRUE)"],
  ["=COUNTIF(Users!$H$2:$H$984,\"TRUE\")"],
  ["=COUNTIF(Users!$H$2:$H$984,1)"],
  ["=SUMPRODUCT(--(Users!$H$2:$H$984=TRUE))"],
  ["=SUMPRODUCT(--Users!$H$2:$H$984)"],
  ["=SUM(N(Users!$H$2:$H$984))"],
  ["=COUNTIF(Users!$H$2:$H$984,FALSE)"],
];
const inspected = await workbook.inspect({ kind: "table", range: "Summary!H30:H36", include: "values,formulas", tableMaxRows: 10, tableMaxCols: 2 });
console.log(inspected.ndjson);
