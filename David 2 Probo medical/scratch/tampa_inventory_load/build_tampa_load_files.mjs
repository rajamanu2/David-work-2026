import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const sourcePath = "C:/Users/LIKKI/Downloads/Copy of TampaInventory_Dataloader_08172026_BN.xlsx";
const outputDir = "outputs/tampa_inventory_2026-08-17_load";
const queryDir = path.join(outputDir, "preload_query");
const previewDir = "scratch/tampa_inventory_load/previews";
const targetDate = "2026-08-17";
const recentCutoff = "2026-08-18T00:00:00";

const headers = [
  "Id",
  "Location__c",
  "Sub_Location__c",
  "Current_Location__c",
  "Inventory_Count_Date__c",
  "Stock_Checked__c",
];

const csvEscape = (value) => {
  const text = value == null ? "" : String(value);
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
};

const toCsv = (csvHeaders, rows) =>
  [csvHeaders, ...rows]
    .map((row) => row.map(csvEscape).join(","))
    .join("\r\n") + "\r\n";

const excelDateToIso = (value) => {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  return new Date(Date.UTC(1899, 11, 30) + value * 86400000)
    .toISOString()
    .slice(0, 10);
};

const blankToNullSentinel = (value) => {
  const normalized = value == null ? "" : String(value).trim();
  return normalized || "#N/A";
};

const normalizeId = (value) => String(value ?? "").trim().slice(0, 15);
const normalize = (value) => (value == null ? "" : String(value).trim());

const sourceBytes = await fs.readFile(sourcePath);
const sourceSha256 = crypto.createHash("sha256").update(sourceBytes).digest("hex").toUpperCase();
const sourceBlob = await FileBlob.load(sourcePath);
const sourceWorkbook = await SpreadsheetFile.importXlsx(sourceBlob);
const sourceSheet = sourceWorkbook.worksheets.getItem("Sheet1");
const sourceValues = sourceSheet.getUsedRange().values;
const sourceHeaders = sourceValues[0].map((value) => normalize(value));
const sourceIndex = Object.fromEntries(sourceHeaders.map((header, index) => [header, index]));
const requiredSourceHeaders = [
  "Asset",
  "Asset2 ID",
  "Location",
  "Sub Location",
  "Current Location",
  "Inventory Count Date",
  "Stock Checked Date",
];
for (const header of requiredSourceHeaders) {
  if (!(header in sourceIndex)) throw new Error(`Missing source header: ${header}`);
}

const queryFiles = (await fs.readdir(queryDir)).filter((file) => file.endsWith(".csv")).sort();
if (queryFiles.length !== 6) throw new Error(`Expected 6 preload query files, found ${queryFiles.length}`);

const currentRows = [];
for (const file of queryFiles) {
  const csv = await fs.readFile(path.join(queryDir, file), "utf8");
  const workbook = await Workbook.fromCSV(csv, { sheetName: "Salesforce" });
  const values = workbook.worksheets.getItem("Salesforce").getUsedRange().values;
  const currentHeaders = values[0].map((value) => normalize(value));
  const currentIndex = Object.fromEntries(currentHeaders.map((header, index) => [header, index]));
  for (const row of values.slice(1)) {
    currentRows.push(Object.fromEntries(currentHeaders.map((header) => [header, row[currentIndex[header]] ?? ""])));
  }
}

const currentById = new Map();
for (const row of currentRows) {
  const id = normalizeId(row.Id);
  if (currentById.has(id)) throw new Error(`Duplicate Salesforce ID in preload snapshot: ${row.Id}`);
  currentById.set(id, row);
}

const intended = sourceValues.slice(1).map((row, offset) => {
  const sourceRow = offset + 2;
  const sourceId = normalize(row[sourceIndex["Asset2 ID"]]);
  const current = currentById.get(normalizeId(sourceId));
  if (!current) throw new Error(`Workbook row ${sourceRow} not found in preload snapshot: ${sourceId}`);
  const asset = normalize(row[sourceIndex.Asset]);
  if (normalize(current.Name) !== asset) {
    throw new Error(`Asset mismatch on workbook row ${sourceRow}: workbook ${asset}, Salesforce ${current.Name}`);
  }
  const instruction = normalize(row[sourceIndex["Sub Location"]]);
  if (instruction !== "*Blank - Clear Content") {
    throw new Error(`Unexpected Sub Location instruction on row ${sourceRow}: ${instruction}`);
  }
  const inventoryCountDate = excelDateToIso(row[sourceIndex["Inventory Count Date"]]);
  const stockCheckedDate = excelDateToIso(row[sourceIndex["Stock Checked Date"]]);
  if (inventoryCountDate !== targetDate || stockCheckedDate !== targetDate) {
    throw new Error(`Unexpected date on row ${sourceRow}: ${inventoryCountDate}, ${stockCheckedDate}`);
  }
  return {
    sourceRow,
    sourceId,
    id: normalize(current.Id),
    asset,
    location: normalize(row[sourceIndex.Location]),
    currentLocation: normalize(row[sourceIndex["Current Location"]]),
    inventoryCountDate,
    stockCheckedDate,
    before: {
      location: normalize(current.Location__c),
      subLocation: normalize(current.Sub_Location__c),
      currentLocation: normalize(current.Current_Location__c),
      inventoryCountDate: normalize(current.Inventory_Count_Date__c),
      stockCheckedDate: normalize(current.Stock_Checked__c),
      lastModifiedDate: normalize(current.LastModifiedDate),
    },
  };
});

if (intended.length !== 1798) throw new Error(`Expected 1798 source rows, found ${intended.length}`);
const intendedIds = new Set(intended.map((record) => normalizeId(record.id)));
if (intendedIds.size !== 1798) throw new Error(`Expected 1798 unique IDs, found ${intendedIds.size}`);

for (const record of intended) {
  if (record.location !== "Tampa, FL") throw new Error(`Unexpected Location for ${record.id}: ${record.location}`);
  if (!record.currentLocation || record.currentLocation.length > 255) {
    throw new Error(`Invalid Current Location for ${record.id}: ${record.currentLocation}`);
  }
}

const toUpdateRow = (record) => [
  record.id,
  record.location,
  "#N/A",
  record.currentLocation,
  record.inventoryCountDate,
  record.stockCheckedDate,
];

const isRecent = (record) => record.before.lastModifiedDate >= recentCutoff;
const candidatePool = intended.filter((record) => !isRecent(record));
const chosen = [];
const chosenIds = new Set();
const choose = (label, predicate) => {
  const record = candidatePool.find((candidate) => !chosenIds.has(candidate.id) && predicate(candidate));
  if (!record) throw new Error(`Unable to choose pilot coverage record for ${label}`);
  chosen.push({ label, record });
  chosenIds.add(record.id);
};

choose("clear_nonblank_sub_location", (record) => Boolean(record.before.subLocation));
choose("sub_location_already_blank", (record) => !record.before.subLocation);
choose("normalize_Tampa_to_Tampa_FL", (record) => record.before.location === "Tampa");
choose("move_non_Tampa_to_Tampa_FL", (record) => !new Set(["Tampa", "Tampa, FL"]).has(record.before.location));
choose("populate_blank_current_location", (record) => !record.before.currentLocation);
choose(
  "reorder_FG_TPA_to_TPA_FG",
  (record) => record.before.currentLocation.replace(/^FG \| TPA \|/, "TPA | FG |") === record.currentLocation && record.before.currentLocation !== record.currentLocation,
);
choose(
  "other_current_location_change",
  (record) => record.before.currentLocation && record.before.currentLocation !== record.currentLocation && record.before.currentLocation.replace(/^FG \| TPA \|/, "TPA | FG |") !== record.currentLocation,
);
choose("current_location_already_matches", (record) => record.before.currentLocation === record.currentLocation);
choose("inventory_date_previously_blank", (record) => !record.before.inventoryCountDate);
choose("stock_checked_previously_populated", (record) => Boolean(record.before.stockCheckedDate));

if (chosen.length !== 10 || chosenIds.size !== 10) throw new Error("Pilot selection did not produce 10 unique records");
const pilotRecords = chosen.map(({ record }) => record);
const mainRecords = intended.filter((record) => !chosenIds.has(record.id));
if (mainRecords.length !== 1788) throw new Error(`Expected 1788 main records, found ${mainRecords.length}`);

const rollbackRows = intended.map((record) => [
  record.id,
  blankToNullSentinel(record.before.location),
  blankToNullSentinel(record.before.subLocation),
  blankToNullSentinel(record.before.currentLocation),
  blankToNullSentinel(record.before.inventoryCountDate),
  blankToNullSentinel(record.before.stockCheckedDate),
]);
const files = [
  { name: "00_rollback_backup_1798.csv", rows: rollbackRows },
  { name: "01_pilot_update_10.csv", rows: pilotRecords.map(toUpdateRow) },
  { name: "02_main_remaining_update_1788.csv", rows: mainRecords.map(toUpdateRow) },
];

await fs.mkdir(outputDir, { recursive: true });
await fs.mkdir(previewDir, { recursive: true });

const verification = [];
for (const file of files) {
  const csv = toCsv(headers, file.rows);
  const filePath = path.join(outputDir, file.name);
  await fs.writeFile(filePath, csv, "utf8");

  const checkWorkbook = await Workbook.fromCSV(csv, { sheetName: "Data" });
  const checkSheet = checkWorkbook.worksheets.getItem("Data");
  const checkRange = checkSheet.getUsedRange();
  checkRange.format.autofitColumns();
  const checkValues = checkRange.values;
  if (checkValues.length !== file.rows.length + 1) {
    throw new Error(`${file.name}: expected ${file.rows.length + 1} total rows, found ${checkValues.length}`);
  }
  if (checkValues[0].join("|") !== headers.join("|")) throw new Error(`${file.name}: header mismatch`);
  const ids = checkValues.slice(1).map((row) => normalize(row[0]));
  if (new Set(ids).size !== ids.length) throw new Error(`${file.name}: duplicate IDs`);
  if (file.name !== "00_rollback_backup_1798.csv") {
    for (const [index, row] of checkValues.slice(1).entries()) {
      if (normalize(row[2]) !== "#N/A") throw new Error(`${file.name}: Sub_Location__c null marker missing on row ${index + 2}`);
      if (normalize(row[4]) !== targetDate || normalize(row[5]) !== targetDate) {
        throw new Error(`${file.name}: date mismatch on row ${index + 2}`);
      }
    }
  }

  const lastPreviewRow = Math.min(15, checkValues.length);
  const inspect = await checkWorkbook.inspect({
    kind: "table",
    sheetId: "Data",
    range: `A1:F${lastPreviewRow}`,
    maxChars: 7000,
    tableMaxRows: 15,
    tableMaxCols: 6,
  });
  const formulaErrors = await checkWorkbook.inspect({
    kind: "match",
    searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?",
    options: { useRegex: true, maxResults: 100 },
    maxChars: 3000,
  });
  if (formulaErrors.ndjson && !formulaErrors.ndjson.includes('"count":0')) {
    const found = /#REF!|#DIV\/0!|#VALUE!|#NAME\?/.test(formulaErrors.ndjson);
    if (found) throw new Error(`${file.name}: unexpected formula-error token detected`);
  }
  const preview = await checkWorkbook.render({
    sheetName: "Data",
    range: `A1:F${lastPreviewRow}`,
    scale: 1,
    format: "png",
  });
  const previewPath = path.join(previewDir, file.name.replace(/\.csv$/i, ".png"));
  await fs.writeFile(previewPath, new Uint8Array(await preview.arrayBuffer()));

  verification.push({
    file: file.name,
    rows: file.rows.length,
    sha256: crypto.createHash("sha256").update(csv).digest("hex").toUpperCase(),
    inspect: inspect.ndjson,
    previewPath,
  });
}

const metadata = {
  generatedAt: new Date().toISOString(),
  targetOrg: {
    alias: "ProboMedical",
    orgId: "00DU0000000LaKoMAK",
    isSandbox: false,
  },
  source: {
    path: sourcePath,
    sha256: sourceSha256,
    rows: intended.length,
    targetDate,
  },
  load: {
    object: "ProductItem__c",
    operation: "update",
    fields: headers,
    nullStrategy: "Bulk API #N/A sentinel in Sub_Location__c",
    pilotRows: pilotRecords.length,
    mainRows: mainRecords.length,
    allApprovedRows: intended.length,
  },
  pilotCoverage: chosen.map(({ label, record }) => ({
    label,
    id: record.id,
    asset: record.asset,
    before: record.before,
    after: {
      location: record.location,
      subLocation: null,
      currentLocation: record.currentLocation,
      inventoryCountDate: record.inventoryCountDate,
      stockCheckedDate: record.stockCheckedDate,
    },
  })),
  verification,
};
await fs.writeFile(
  path.join(outputDir, "load_plan_and_file_verification.json"),
  JSON.stringify(metadata, null, 2) + "\n",
  "utf8",
);

console.log(JSON.stringify({
  sourceSha256,
  sourceRows: intended.length,
  preloadRows: currentRows.length,
  pilotRows: pilotRecords.length,
  mainRows: mainRecords.length,
  rollbackRows: rollbackRows.length,
  pilotCoverage: metadata.pilotCoverage.map(({ label, id, asset }) => ({ label, id, asset })),
  files: verification.map(({ file, rows, sha256 }) => ({ file, rows, sha256 })),
}));
