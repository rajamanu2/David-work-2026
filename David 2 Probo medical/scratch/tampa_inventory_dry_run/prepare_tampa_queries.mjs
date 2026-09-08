import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/Users/LIKKI/Downloads/Copy of TampaInventory_Dataloader_08172026_BN.xlsx";
const outputDir = "scratch/tampa_inventory_dry_run";
const queryDir = path.join(outputDir, "queries");
const chunkSize = 300;

const excelDateToIso = (value) => {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  return new Date(Date.UTC(1899, 11, 30) + value * 86400000)
    .toISOString()
    .slice(0, 10);
};

const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);
const sheet = workbook.worksheets.getItem("Sheet1");
const values = sheet.getUsedRange().values;
const headers = values[0].map((value) => String(value ?? "").trim());
const index = Object.fromEntries(headers.map((header, column) => [header, column]));
const requiredHeaders = [
  "Asset",
  "Asset2 ID",
  "Location",
  "Sub Location",
  "Current Location",
  "Inventory Count Date",
  "Stock Checked Date",
];
for (const header of requiredHeaders) {
  if (!(header in index)) throw new Error(`Missing required header: ${header}`);
}

const records = values.slice(1).map((row, offset) => {
  const sourceRow = offset + 2;
  const id = String(row[index["Asset2 ID"]] ?? "").trim();
  if (!/^a06[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?$/.test(id)) {
    throw new Error(`Invalid ProductItem__c ID on workbook row ${sourceRow}: ${id}`);
  }
  const subLocationInstruction = String(row[index["Sub Location"]] ?? "").trim();
  if (subLocationInstruction !== "*Blank - Clear Content") {
    throw new Error(`Unexpected Sub Location instruction on workbook row ${sourceRow}: ${subLocationInstruction}`);
  }
  const inventoryCountDate = excelDateToIso(row[index["Inventory Count Date"]]);
  const stockCheckedDate = excelDateToIso(row[index["Stock Checked Date"]]);
  if (!inventoryCountDate || !stockCheckedDate) {
    throw new Error(`Invalid date value on workbook row ${sourceRow}`);
  }
  return {
    sourceRow,
    id,
    asset: String(row[index.Asset] ?? "").trim(),
    location: String(row[index.Location] ?? "").trim(),
    subLocation: null,
    currentLocation: String(row[index["Current Location"]] ?? "").trim(),
    inventoryCountDate,
    stockCheckedDate,
  };
});

const ids = new Set();
const assets = new Set();
for (const record of records) {
  if (ids.has(record.id)) throw new Error(`Duplicate Asset2 ID: ${record.id}`);
  if (assets.has(record.asset)) throw new Error(`Duplicate Asset number: ${record.asset}`);
  ids.add(record.id);
  assets.add(record.asset);
}

await fs.mkdir(queryDir, { recursive: true });
await fs.writeFile(
  path.join(outputDir, "intended_records.json"),
  JSON.stringify(records, null, 2) + "\n",
  "utf8",
);

const queryFields = [
  "Id",
  "Name",
  "Location__c",
  "Sub_Location__c",
  "Current_Location__c",
  "Inventory_Count_Date__c",
  "Stock_Checked__c",
  "LastModifiedDate",
];
const queryFiles = [];
for (let start = 0, chunk = 1; start < records.length; start += chunkSize, chunk += 1) {
  const subset = records.slice(start, start + chunkSize);
  const idList = subset.map((record) => `'${record.id}'`).join(",");
  const soql = `SELECT ${queryFields.join(", ")} FROM ProductItem__c WHERE Id IN (${idList}) ORDER BY Id`;
  const file = `product_items_${String(chunk).padStart(2, "0")}.soql`;
  await fs.writeFile(path.join(queryDir, file), soql + "\n", "utf8");
  queryFiles.push({ file, recordCount: subset.length, queryChars: soql.length });
}

console.log(JSON.stringify({
  workbookRows: records.length,
  uniqueIds: ids.size,
  uniqueAssets: assets.size,
  locationValues: [...new Set(records.map((record) => record.location))],
  inventoryCountDates: [...new Set(records.map((record) => record.inventoryCountDate))],
  stockCheckedDates: [...new Set(records.map((record) => record.stockCheckedDate))],
  queryFiles,
}));

