import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const sourceCsv = process.argv[2];
const outputXlsx = process.argv[3];
const previewPng = process.argv[4];
const verificationJson = process.argv[5];
if (!sourceCsv || !outputXlsx || !previewPng || !verificationJson) {
  throw new Error("Usage: node build_open_cases_workbook.mjs <source.csv> <output.xlsx> <preview.png> <verification.json>");
}

const csvText = await fs.readFile(sourceCsv, "utf8");
const sourceWorkbook = await Workbook.fromCSV(csvText, { sheetName: "Source" });
const sourceSheet = sourceWorkbook.worksheets.getItem("Source");
const sourceValues = sourceSheet.getUsedRange(true).values;
const headers = sourceValues[0].map((v) => String(v ?? ""));
const column = Object.fromEntries(headers.map((h, i) => [h, i]));

const parseDate = (value) => {
  const match = String(value ?? "").match(/^(\d{2})-(\d{2})-(\d{4}) (\d{2}):(\d{2}):(\d{2})$/);
  if (!match) return null;
  const [, dd, mm, yyyy, hh, min, ss] = match;
  return new Date(Date.UTC(Number(yyyy), Number(mm) - 1, Number(dd), Number(hh), Number(min), Number(ss)));
};

const valueAt = (row, name) => row[column[name]] ?? null;
const sourceRows = sourceValues.slice(1).filter((row) => String(valueAt(row, "SalesforceIsClosed")).toLowerCase() === "false");
sourceRows.sort((a, b) => {
  const statusCompare = String(valueAt(a, "SalesforceStatus")).localeCompare(String(valueAt(b, "SalesforceStatus")));
  return statusCompare || String(valueAt(a, "CaseNumber")).localeCompare(String(valueAt(b, "CaseNumber")));
});

const workbook = Workbook.create();
const sheet = workbook.worksheets.add("Open Cases");
sheet.showGridLines = false;

sheet.getRange("A1:S1").merge();
sheet.getRange("A1").values = [["Probo Medical — Open Production Cases"]];
sheet.getRange("A2:S2").merge();
sheet.getRange("A2").values = [["Read-only production snapshot | ProboMedical | Generated 2026-08-31 | Source: verified Salesforce Case records"]];

const cards = [
  ["A4:B4", "A5:B5", "Total Open", `=COUNTA(A8:A${sourceRows.length + 7})`, "#0F766E"],
  ["D4:E4", "D5:E5", "Claimed", `=COUNTIF(C8:C${sourceRows.length + 7},\"Claimed\")`, "#2563EB"],
  ["G4:H4", "G5:H5", "New", `=COUNTIF(C8:C${sourceRows.length + 7},\"New\")`, "#EA580C"],
  ["J4:K4", "J5:K5", "On Hold", `=COUNTIF(C8:C${sourceRows.length + 7},\"On Hold\")`, "#B45309"],
  ["M4:N4", "M5:N5", "In Progress", `=COUNTIF(C8:C${sourceRows.length + 7},\"In progress\")`, "#15803D"],
  ["P4:Q4", "P5:Q5", "High Priority", `=COUNTIF(D8:D${sourceRows.length + 7},\"High\")`, "#B91C1C"],
];

for (const [labelRange, valueRange, label, formula, color] of cards) {
  sheet.getRange(labelRange).merge();
  sheet.getRange(valueRange).merge();
  sheet.getRange(labelRange.split(":")[0]).values = [[label]];
  sheet.getRange(valueRange.split(":")[0]).formulas = [[formula]];
  sheet.getRange(labelRange).format = {
    fill: color,
    font: { bold: true, color: "#FFFFFF", size: 10 },
    horizontalAlignment: "center",
    verticalAlignment: "center",
  };
  sheet.getRange(valueRange).format = {
    fill: "#F8FAFC",
    font: { bold: true, color, size: 18 },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    borders: { preset: "outside", style: "thin", color },
  };
}

const outputHeaders = [
  "Case Number", "Subject", "Status", "Priority", "Owner", "Classification", "Related Object",
  "Workbook Theme", "Workbook Status", "Workbook Sheet", "Workbook Assigned To", "Created Date",
  "Last Modified Date", "History", "Feed Posts", "Feed Comments", "Files", "Review Flag", "Description",
];

const bodyRows = sourceRows.map((row) => [
  String(valueAt(row, "CaseNumber") ?? ""),
  valueAt(row, "SalesforceSubject"),
  valueAt(row, "SalesforceStatus"),
  valueAt(row, "SalesforcePriority"),
  valueAt(row, "SalesforceOwner"),
  valueAt(row, "SalesforceClassification"),
  valueAt(row, "SalesforceRelatedObject"),
  valueAt(row, "WorkbookTheme"),
  valueAt(row, "WorkbookStatus"),
  valueAt(row, "Sheet"),
  valueAt(row, "WorkbookAssignedTo"),
  parseDate(valueAt(row, "SalesforceCreatedDate")),
  parseDate(valueAt(row, "SalesforceLastModifiedDate")),
  Number(valueAt(row, "HistoryCount") || 0),
  Number(valueAt(row, "FeedItemCount") || 0),
  Number(valueAt(row, "FeedCommentCount") || 0),
  Number(valueAt(row, "FileCount") || 0),
  null,
  valueAt(row, "SalesforceDescription"),
]);

const lastRow = bodyRows.length + 7;
sheet.getRange("A7:S7").values = [outputHeaders];
sheet.getRange(`A8:S${lastRow}`).values = bodyRows;
sheet.getRange("R8").formulas = [["=IF(J8=\"Complete\",\"Review - workbook says Complete\",\"Active backlog\")"]];
sheet.getRange(`R8:R${lastRow}`).fillDown();

const table = sheet.tables.add(`A7:S${lastRow}`, true, "OpenCasesTable");
table.style = "TableStyleMedium2";
table.showFilterButton = true;
table.showBandedRows = true;

sheet.getRange("A1:S1").format = {
  fill: "#14213D",
  font: { bold: true, color: "#FFFFFF", size: 18 },
  horizontalAlignment: "left",
  verticalAlignment: "center",
};
sheet.getRange("A2:S2").format = {
  fill: "#E8EEF7",
  font: { color: "#334155", italic: true, size: 10 },
  horizontalAlignment: "left",
  verticalAlignment: "center",
};
sheet.getRange("A7:S7").format = {
  fill: "#1E3A5F",
  font: { bold: true, color: "#FFFFFF", size: 10 },
  verticalAlignment: "center",
  wrapText: true,
};

sheet.getRange(`A8:S${lastRow}`).format = {
  font: { color: "#1F2937", size: 9 },
  verticalAlignment: "top",
};
sheet.getRange(`B8:B${lastRow}`).format.wrapText = true;
sheet.getRange(`H8:K${lastRow}`).format.wrapText = true;
sheet.getRange(`R8:S${lastRow}`).format.wrapText = true;
sheet.getRange(`L8:M${lastRow}`).format.numberFormat = "yyyy-mm-dd hh:mm";
sheet.getRange(`N8:Q${lastRow}`).format.numberFormat = "#,##0";
sheet.getRange(`A8:A${lastRow}`).format.numberFormat = "@";

sheet.getRange(`C8:C${lastRow}`).conditionalFormats.add("containsText", { text: "Claimed", format: { fill: "#DBEAFE", font: { color: "#1D4ED8", bold: true } } });
sheet.getRange(`C8:C${lastRow}`).conditionalFormats.add("containsText", { text: "New", format: { fill: "#FFEDD5", font: { color: "#C2410C", bold: true } } });
sheet.getRange(`C8:C${lastRow}`).conditionalFormats.add("containsText", { text: "On Hold", format: { fill: "#FEF3C7", font: { color: "#92400E", bold: true } } });
sheet.getRange(`C8:C${lastRow}`).conditionalFormats.add("containsText", { text: "In progress", format: { fill: "#DCFCE7", font: { color: "#166534", bold: true } } });
sheet.getRange(`D8:D${lastRow}`).conditionalFormats.add("containsText", { text: "High", format: { fill: "#FEE2E2", font: { color: "#B91C1C", bold: true } } });
sheet.getRange(`R8:R${lastRow}`).conditionalFormats.add("containsText", { text: "Review", format: { fill: "#FCE7F3", font: { color: "#9D174D", bold: true } } });

sheet.getRange("A1:S1").format.rowHeight = 32;
sheet.getRange("A2:S2").format.rowHeight = 22;
sheet.getRange("A4:Q4").format.rowHeight = 20;
sheet.getRange("A5:Q5").format.rowHeight = 28;
sheet.getRange("A7:S7").format.rowHeight = 34;
sheet.getRange(`A8:S${lastRow}`).format.rowHeight = 34;

const widths = {
  A: 14, B: 40, C: 14, D: 10, E: 22, F: 29, G: 25, H: 38, I: 20, J: 25,
  K: 22, L: 19, M: 19, N: 10, O: 10, P: 12, Q: 8, R: 31, S: 68,
};
for (const [col, width] of Object.entries(widths)) sheet.getRange(`${col}:${col}`).format.columnWidth = width;

sheet.freezePanes.freezeRows(7);
sheet.freezePanes.freezeColumns(2);

await fs.mkdir(path.dirname(outputXlsx), { recursive: true });
await fs.mkdir(path.dirname(previewPng), { recursive: true });

const inspection = await workbook.inspect({
  kind: "workbook,sheet,table",
  maxChars: 12000,
  tableMaxRows: 12,
  tableMaxCols: 19,
  tableMaxCellChars: 120,
});
const keyRange = await workbook.inspect({
  kind: "region",
  sheetId: "Open Cases",
  range: "A1:S15",
  maxChars: 12000,
});
const formulaErrors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 300 },
  summary: "final formula error scan",
});

const preview = await workbook.render({
  sheetName: "Open Cases",
  range: "A1:S24",
  scale: 1,
  format: "png",
});
await fs.writeFile(previewPng, new Uint8Array(await preview.arrayBuffer()));

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputXlsx);

const verification = {
  openRows: sourceRows.length,
  expectedCounts: { total: 116, claimed: 77, new: 15, onHold: 13, inProgress: 11, highPriority: 4 },
  workbookInspection: inspection.ndjson,
  keyRangeInspection: keyRange.ndjson,
  formulaErrorScan: formulaErrors.ndjson,
};
await fs.writeFile(verificationJson, JSON.stringify(verification, null, 2), "utf8");
console.log(JSON.stringify({ outputXlsx, previewPng, openRows: sourceRows.length, lastRow }, null, 2));
