import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const inputPath = "C:/Users/LIKKI/Downloads/Copy of 08132026_SLC CycleCount_DateChecked.xlsx";
const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);
const salesforceCsv = await fs.readFile("scratch/salesforce_slc_assets.csv", "utf8");
const salesforceWorkbook = await Workbook.fromCSV(salesforceCsv, { sheetName: "Salesforce" });
const salesforceValues = salesforceWorkbook.worksheets.getItem("Salesforce").getUsedRange().values;
const salesforceHeaders = salesforceValues[0];
const nonSlcCsv = await fs.readFile("scratch/salesforce_non_slc_assets.csv", "utf8");
const nonSlcWorkbook = await Workbook.fromCSV(nonSlcCsv, { sheetName: "OtherLocations" });
const nonSlcValues = nonSlcWorkbook.worksheets.getItem("OtherLocations").getUsedRange().values;
const salesforceRows = [...salesforceValues.slice(1), ...nonSlcValues.slice(1)];
const sfIndex = Object.fromEntries(salesforceHeaders.map((header, index) => [header, index]));
const sfById = new Map();
for (const row of salesforceRows) {
  const id = String(row[sfIndex.Id]);
  sfById.set(id, row);
  sfById.set(id.slice(0, 15), row);
}
const sfByName = new Map(salesforceRows.map((row) => [String(row[sfIndex.Name]), row]));

const summary = await workbook.inspect({
  kind: "workbook,sheet,table,definedName",
  maxChars: 6000,
  tableMaxRows: 10,
  tableMaxCols: 12,
  tableMaxCellChars: 100,
});
console.log(summary.ndjson);

for (const sheet of workbook.worksheets.items) {
  const used = sheet.getUsedRange();
  if (!used) continue;
  const values = used.values;
  const headers = values[0] ?? [];
  const rows = values.slice(1);
  const excelDate = (serial) => {
    if (typeof serial !== "number") return null;
    return new Date(Date.UTC(1899, 11, 30) + serial * 86400000)
      .toISOString()
      .slice(0, 10);
  };
  const distinct = (index) => [...new Set(rows.map((row) => row[index]))];
  const counts = new Map();
  for (const row of rows) {
    const id = String(row[1] ?? "");
    counts.set(id, (counts.get(id) ?? 0) + 1);
  }
  const duplicateIds = [...counts.entries()].filter(([, count]) => count > 1);
  const malformedIds = rows
    .map((row, index) => ({ row: index + 2, assetNo: row[0], id: String(row[1] ?? "") }))
    .filter(({ id }) => !/^a06[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?$/.test(id));
  const intended = new Map();
  for (const row of rows) {
    const rawId = String(row[1] ?? "");
    const sfRow = /^a06[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?$/.test(rawId)
      ? sfById.get(rawId.slice(0, 15)) ?? sfById.get(rawId)
      : sfByName.get(String(row[0]));
    if (sfRow) intended.set(String(sfRow[sfIndex.Id]), sfRow);
  }
  const targetDate = "2026-08-04";
  const valueCounts = (field) => {
    const index = sfIndex[field];
    const map = new Map();
    for (const row of intended.values()) {
      const value = row[index] == null || row[index] === "" ? null : String(row[index]);
      map.set(value, (map.get(value) ?? 0) + 1);
    }
    return [...map.entries()].sort((a, b) => b[1] - a[1]);
  };
  const compareDate = (field) => {
    const index = sfIndex[field];
    const result = { blank: 0, older: 0, equal: 0, newer: 0 };
    for (const row of intended.values()) {
      const value = row[index] == null || row[index] === "" ? null : String(row[index]);
      if (!value) result.blank += 1;
      else if (value < targetDate) result.older += 1;
      else if (value > targetDate) result.newer += 1;
      else result.equal += 1;
    }
    return result;
  };
  const newerStockCheckedRecords = [...intended.values()]
    .filter((row) => String(row[sfIndex.Stock_Checked__c] ?? "") > targetDate)
    .map((row) => ({
      id: row[sfIndex.Id],
      assetNo: row[sfIndex.Name],
      stockChecked: row[sfIndex.Stock_Checked__c],
      inventoryCountDate: row[sfIndex.Inventory_Count_Date__c] || null,
      location: row[sfIndex.Location__c],
    }))
    .sort((a, b) => String(a.assetNo).localeCompare(String(b.assetNo)));
  const unresolved = [];
  for (const row of rows) {
    const rawId = String(row[1] ?? "");
    const sfRow = /^a06[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?$/.test(rawId)
      ? sfById.get(rawId.slice(0, 15)) ?? sfById.get(rawId)
      : sfByName.get(String(row[0]));
    if (!sfRow) unresolved.push({ assetNo: row[0], asset2Id: rawId });
  }
  console.log(JSON.stringify({
    sheet: sheet.name,
    usedRange: used.address,
    headers,
    dataRows: rows.length,
    uniqueAsset2Ids: counts.size,
    validRows: rows.length - malformedIds.length,
    uniqueValidAsset2Ids: [...counts.keys()].filter((id) => /^a06[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?$/.test(id)).length,
    duplicateRowCount: duplicateIds.reduce((sum, [, count]) => sum + count - 1, 0),
    validDuplicateIdCount: duplicateIds.filter(([id]) => /^a06[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?$/.test(id)).length,
    validDuplicateExtraRows: duplicateIds.filter(([id]) => /^a06[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?$/.test(id)).reduce((sum, [, count]) => sum + count - 1, 0),
    duplicateIds: duplicateIds.slice(0, 30),
    malformedIds,
    matchedUniqueSalesforceRecords: intended.size,
    unresolvedWorkbookRows: unresolved,
    stockCheckedCurrentComparison: compareDate("Stock_Checked__c"),
    inventoryCountCurrentComparison: compareDate("Inventory_Count_Date__c"),
    newerStockCheckedRecords,
    locationCountsForMatchedRecords: valueCounts("Location__c"),
    stockCheckedDates: distinct(2).map((value) => ({ raw: value, iso: excelDate(value) })),
    inventoryCountDates: distinct(3).map((value) => ({ raw: value, iso: excelDate(value) })),
    firstRows: rows.slice(0, 5),
    lastRows: rows.slice(-5),
  }));

  const style = await workbook.inspect({
    kind: "computedStyle",
    sheetId: sheet.name,
    range: "A1:D10",
    maxChars: 10000,
  });
  console.log(style.ndjson);

  const preview = await workbook.render({
    sheetName: sheet.name,
    range: "A1:D30",
    scale: 1,
    format: "png",
  });
  const safeName = sheet.name.replace(/[^a-z0-9_-]+/gi, "_");
  await fs.mkdir("scratch/previews", { recursive: true });
  await fs.writeFile(
    `scratch/previews/${safeName}.png`,
    new Uint8Array(await preview.arrayBuffer()),
  );
}
