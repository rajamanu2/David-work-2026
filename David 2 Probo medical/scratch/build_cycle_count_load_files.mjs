import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const sourcePath = "C:/Users/LIKKI/Downloads/Copy of 08132026_SLC CycleCount_DateChecked.xlsx";
const slcExportPath = "scratch/salesforce_slc_assets.csv";
const otherExportPath = "scratch/salesforce_non_slc_assets.csv";
const outputDir = "outputs/cycle_count_2026-08-04_load";
const previewDir = "scratch/load_previews";
const targetDate = "2026-08-04";
const asOfDate = "2026-08-18";
const pilotAssetNos = new Set([
  "320818",
  "324974",
  "325085",
  "326112",
  "327495",
  "370360",
  "471914",
  "472598",
  "532161",
  "536027",
]);

const csvEscape = (value) => {
  const text = value == null ? "" : String(value);
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
};

const toCsv = (headers, rows) =>
  [headers, ...rows]
    .map((row) => row.map(csvEscape).join(","))
    .join("\r\n") + "\r\n";

const parseCsv = async (filePath, sheetName) => {
  const text = await fs.readFile(filePath, "utf8");
  const workbook = await Workbook.fromCSV(text, { sheetName });
  return workbook.worksheets.getItem(sheetName).getUsedRange().values;
};

const sourceBlob = await FileBlob.load(sourcePath);
const sourceWorkbook = await SpreadsheetFile.importXlsx(sourceBlob);
const sourceSheet = sourceWorkbook.worksheets.getItem("Sheet1");
const sourceRows = sourceSheet.getUsedRange().values.slice(1);

const slcValues = await parseCsv(slcExportPath, "SLC");
const otherValues = await parseCsv(otherExportPath, "Other");
const headers = slcValues[0];
const index = Object.fromEntries(headers.map((header, column) => [header, column]));
const sfRows = [...slcValues.slice(1), ...otherValues.slice(1)];

const byId = new Map();
const byName = new Map();
for (const row of sfRows) {
  const id = String(row[index.Id]);
  byId.set(id, row);
  byId.set(id.slice(0, 15), row);
  byName.set(String(row[index.Name]), row);
}

const intendedById = new Map();
for (const row of sourceRows) {
  const assetNo = String(row[0]);
  const rawId = String(row[1] ?? "");
  const sfRow = /^a06[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?$/.test(rawId)
    ? byId.get(rawId)
    : byName.get(assetNo);
  if (!sfRow) throw new Error(`Unresolved workbook row for Asset No ${assetNo}, ID ${rawId}`);
  const id = String(sfRow[index.Id]);
  intendedById.set(id, sfRow);
}

const records = [...intendedById.values()].sort(
  (a, b) => Number(a[index.Name]) - Number(b[index.Name]),
);
const main = [];
const futureCorrections = [];
const preserveLaterStock = [];

for (const row of records) {
  const currentStock = String(row[index.Stock_Checked__c] ?? "");
  if (currentStock && currentStock > asOfDate) futureCorrections.push(row);
  else if (currentStock && currentStock > targetDate) preserveLaterStock.push(row);
  else main.push(row);
}

const pilot = main.filter((row) => pilotAssetNos.has(String(row[index.Name])));
const pilotIds = new Set(pilot.map((row) => String(row[index.Id])));
const mainRemaining = main.filter((row) => !pilotIds.has(String(row[index.Id])));

const backupHeaders = [
  "Id",
  "Name",
  "Original_Stock_Checked__c",
  "Original_Inventory_Count_Date__c",
  "Location__c",
  "Current_Location__c",
  "Physical_Location__c",
];
const backupRows = records.map((row) => [
  row[index.Id],
  row[index.Name],
  row[index.Stock_Checked__c] || "",
  row[index.Inventory_Count_Date__c] || "",
  row[index.Location__c] || "",
  row[index.Current_Location__c] || "",
  row[index.Physical_Location__c] || "",
]);

const bothDateHeaders = ["Id", "Stock_Checked__c", "Inventory_Count_Date__c"];
const bothDateRows = (inputRows) =>
  inputRows.map((row) => [row[index.Id], targetDate, targetDate]);
const inventoryOnlyHeaders = ["Id", "Inventory_Count_Date__c"];
const inventoryOnlyRows = preserveLaterStock.map((row) => [row[index.Id], targetDate]);

const files = [
  {
    name: "00_rollback_backup_5219.csv",
    headers: backupHeaders,
    rows: backupRows,
  },
  {
    name: "01_pilot_update_10.csv",
    headers: bothDateHeaders,
    rows: bothDateRows(pilot),
  },
  {
    name: "02_main_remaining_update_5199.csv",
    headers: bothDateHeaders,
    rows: bothDateRows(mainRemaining),
  },
  {
    name: "03_future_date_corrections_7.csv",
    headers: bothDateHeaders,
    rows: bothDateRows(futureCorrections),
  },
  {
    name: "04_preserve_later_stock_update_3.csv",
    headers: inventoryOnlyHeaders,
    rows: inventoryOnlyRows,
  },
];

const expectedCounts = [5219, 10, 5199, 7, 3];
if (records.length !== 5219) throw new Error(`Expected 5219 unique records, got ${records.length}`);
if (main.length !== 5209) throw new Error(`Expected 5209 main records, got ${main.length}`);
if (pilot.length !== 10) throw new Error(`Expected 10 pilot records, got ${pilot.length}`);
if (mainRemaining.length !== 5199) throw new Error(`Expected 5199 main remaining, got ${mainRemaining.length}`);
if (futureCorrections.length !== 7) throw new Error(`Expected 7 future corrections, got ${futureCorrections.length}`);
if (preserveLaterStock.length !== 3) throw new Error(`Expected 3 later-stock records, got ${preserveLaterStock.length}`);

const updateIdSets = [pilot, mainRemaining, futureCorrections, preserveLaterStock]
  .map((group) => new Set(group.map((row) => String(row[index.Id]))));
const updateIds = new Set();
for (const set of updateIdSets) {
  for (const id of set) {
    if (updateIds.has(id)) throw new Error(`Duplicate update ID across files: ${id}`);
    updateIds.add(id);
  }
}
if (updateIds.size !== 5219) throw new Error(`Expected 5219 disjoint update IDs, got ${updateIds.size}`);

await fs.mkdir(outputDir, { recursive: true });
await fs.mkdir(previewDir, { recursive: true });

const verification = [];
for (let i = 0; i < files.length; i += 1) {
  const file = files[i];
  if (file.rows.length !== expectedCounts[i]) {
    throw new Error(`${file.name}: expected ${expectedCounts[i]} rows, got ${file.rows.length}`);
  }
  const csv = toCsv(file.headers, file.rows);
  const filePath = path.join(outputDir, file.name);
  await fs.writeFile(filePath, csv, "utf8");

  const checkWorkbook = await Workbook.fromCSV(csv, { sheetName: "Data" });
  const checkSheet = checkWorkbook.worksheets.getItem("Data");
  const checkRange = checkSheet.getUsedRange();
  const checkValues = checkRange.values;
  if (checkValues.length !== file.rows.length + 1) {
    throw new Error(`${file.name}: re-import row-count mismatch`);
  }
  checkRange.format.autofitColumns();
  const inspect = await checkWorkbook.inspect({
    kind: "table",
    sheetId: "Data",
    range: `A1:${file.headers.length === 7 ? "G" : file.headers.length === 3 ? "C" : "B"}${Math.min(15, file.rows.length + 1)}`,
    maxChars: 5000,
    tableMaxRows: 15,
    tableMaxCols: 7,
  });
  verification.push({ file: file.name, rows: file.rows.length, inspect: inspect.ndjson });

  const preview = await checkWorkbook.render({
    sheetName: "Data",
    range: `A1:${file.headers.length === 7 ? "G" : file.headers.length === 3 ? "C" : "B"}${Math.min(15, file.rows.length + 1)}`,
    scale: 1,
    format: "png",
  });
  await fs.writeFile(
    path.join(previewDir, file.name.replace(/\.csv$/i, ".png")),
    new Uint8Array(await preview.arrayBuffer()),
  );
}

console.log(JSON.stringify({
  outputDir,
  targetDate,
  totalUniqueRecords: records.length,
  pilotRows: pilot.length,
  mainRemainingRows: mainRemaining.length,
  futureCorrectionRows: futureCorrections.length,
  preserveLaterStockRows: preserveLaterStock.length,
  preserveLaterStockAssets: preserveLaterStock.map((row) => ({
    id: row[index.Id],
    assetNo: row[index.Name],
    stockChecked: row[index.Stock_Checked__c],
  })),
  futureCorrectionAssets: futureCorrections.map((row) => ({
    id: row[index.Id],
    assetNo: row[index.Name],
    stockChecked: row[index.Stock_Checked__c],
  })),
  verification,
}));
