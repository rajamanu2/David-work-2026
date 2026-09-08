import fs from "node:fs/promises";
import path from "node:path";
import { Workbook } from "@oai/artifact-tool";

const baseDir = "scratch/tampa_inventory_dry_run";
const intended = JSON.parse(await fs.readFile(path.join(baseDir, "intended_records.json"), "utf8"));

const resultDir = path.join(baseDir, "query_results");
const files = (await fs.readdir(resultDir))
  .filter((file) => file.endsWith(".csv"))
  .sort();

const currentRows = [];
for (const file of files) {
  const csv = await fs.readFile(path.join(resultDir, file), "utf8");
  const workbook = await Workbook.fromCSV(csv, { sheetName: "Salesforce" });
  const values = workbook.worksheets.getItem("Salesforce").getUsedRange().values;
  const headers = values[0].map((value) => String(value ?? "").trim());
  const index = Object.fromEntries(headers.map((header, column) => [header, column]));
  for (const row of values.slice(1)) {
    currentRows.push(Object.fromEntries(headers.map((header) => [header, row[index[header]] ?? ""])));
  }
}

const normalizeId = (value) => String(value ?? "").trim().slice(0, 15);
const normalize = (value) => (value == null ? "" : String(value).trim());
const currentById = new Map(currentRows.map((row) => [normalizeId(row.Id), row]));

const fieldMappings = [
  { source: "location", api: "Location__c", label: "Location" },
  { source: "subLocation", api: "Sub_Location__c", label: "Sub Location" },
  { source: "currentLocation", api: "Current_Location__c", label: "Current Location" },
  { source: "inventoryCountDate", api: "Inventory_Count_Date__c", label: "Inventory Count Date" },
  { source: "stockCheckedDate", api: "Stock_Checked__c", label: "Stock Checked" },
];

const fieldChangeCounts = Object.fromEntries(fieldMappings.map((field) => [field.api, 0]));
const fieldSameCounts = Object.fromEntries(fieldMappings.map((field) => [field.api, 0]));
const missingIds = [];
const assetMismatches = [];
const changedRows = [];
const noChangeRows = [];
const newerInventoryDates = [];
const newerStockDates = [];
const subLocationValueCounts = new Map();
const locationMismatchCurrentCounts = new Map();
const currentLocationMismatchCategoryCounts = new Map();
const currentInventoryDateCounts = new Map();
const currentStockDateCounts = new Map();
let modifiedOnOrAfter20260818 = 0;
const modifiedOnOrAfter20260818Examples = [];
const modifiedOnOrAfter20260818Ids = new Set();
const currentNonTampaIds = new Set();
const currentNonTampaExamples = [];
let latestLastModifiedDate = "";
const currentLocationMismatchExamples = [];
const locationMismatchExamples = [];
const changePatternCounts = new Map();

for (const wanted of intended) {
  const current = currentById.get(normalizeId(wanted.id));
  if (!current) {
    missingIds.push({ sourceRow: wanted.sourceRow, id: wanted.id, asset: wanted.asset });
    continue;
  }

  if (normalize(current.Name) !== normalize(wanted.asset)) {
    assetMismatches.push({
      sourceRow: wanted.sourceRow,
      id: current.Id,
      workbookAsset: wanted.asset,
      salesforceAsset: current.Name,
    });
  }

  const subLocation = normalize(current.Sub_Location__c);
  const subLocationKey = subLocation || "(blank)";
  subLocationValueCounts.set(subLocationKey, (subLocationValueCounts.get(subLocationKey) ?? 0) + 1);
  const currentInventoryDate = normalize(current.Inventory_Count_Date__c) || "(blank)";
  const currentStockDate = normalize(current.Stock_Checked__c) || "(blank)";
  currentInventoryDateCounts.set(currentInventoryDate, (currentInventoryDateCounts.get(currentInventoryDate) ?? 0) + 1);
  currentStockDateCounts.set(currentStockDate, (currentStockDateCounts.get(currentStockDate) ?? 0) + 1);
  const lastModifiedDate = normalize(current.LastModifiedDate);
  if (lastModifiedDate > latestLastModifiedDate) latestLastModifiedDate = lastModifiedDate;
  if (lastModifiedDate >= "2026-08-18T00:00:00.000+0000") {
    modifiedOnOrAfter20260818 += 1;
    modifiedOnOrAfter20260818Ids.add(normalizeId(current.Id));
    if (modifiedOnOrAfter20260818Examples.length < 30) {
      modifiedOnOrAfter20260818Examples.push({
        id: current.Id,
        asset: current.Name,
        lastModifiedDate,
      });
    }
  }
  const currentLocation = normalize(current.Location__c);
  if (!new Set(["Tampa", "Tampa, FL"]).has(currentLocation)) {
    currentNonTampaIds.add(normalizeId(current.Id));
    if (currentNonTampaExamples.length < 30) {
      currentNonTampaExamples.push({
        id: current.Id,
        asset: current.Name,
        currentLocation: currentLocation || null,
        workbookLocation: wanted.location,
        lastModifiedDate,
      });
    }
  }

  if (normalize(current.Inventory_Count_Date__c) > wanted.inventoryCountDate) {
    newerInventoryDates.push({
      id: current.Id,
      asset: current.Name,
      workbookDate: wanted.inventoryCountDate,
      currentDate: current.Inventory_Count_Date__c,
      lastModifiedDate: current.LastModifiedDate,
    });
  }
  if (normalize(current.Stock_Checked__c) > wanted.stockCheckedDate) {
    newerStockDates.push({
      id: current.Id,
      asset: current.Name,
      workbookDate: wanted.stockCheckedDate,
      currentDate: current.Stock_Checked__c,
      lastModifiedDate: current.LastModifiedDate,
    });
  }

  const changes = [];
  for (const mapping of fieldMappings) {
    const wantedValue = wanted[mapping.source] == null ? "" : normalize(wanted[mapping.source]);
    const currentValue = normalize(current[mapping.api]);
    if (wantedValue === currentValue) {
      fieldSameCounts[mapping.api] += 1;
    } else {
      fieldChangeCounts[mapping.api] += 1;
      changes.push({
        field: mapping.api,
        label: mapping.label,
        from: currentValue || null,
        to: wantedValue || null,
      });
      if (mapping.api === "Current_Location__c" && currentLocationMismatchExamples.length < 20) {
        currentLocationMismatchExamples.push({ id: current.Id, asset: current.Name, from: currentValue || null, to: wantedValue || null });
      }
      if (mapping.api === "Current_Location__c") {
        let category = "other_change";
        if (!currentValue) category = "blank_to_value";
        else if (currentValue.replace(/^FG \| TPA \|/, "TPA | FG |") === wantedValue) category = "reorder_FG_TPA_to_TPA_FG";
        currentLocationMismatchCategoryCounts.set(category, (currentLocationMismatchCategoryCounts.get(category) ?? 0) + 1);
      }
      if (mapping.api === "Location__c" && locationMismatchExamples.length < 20) {
        locationMismatchExamples.push({ id: current.Id, asset: current.Name, from: currentValue || null, to: wantedValue || null });
      }
      if (mapping.api === "Location__c") {
        const key = currentValue || "(blank)";
        locationMismatchCurrentCounts.set(key, (locationMismatchCurrentCounts.get(key) ?? 0) + 1);
      }
    }
  }

  const pattern = changes.map((change) => change.field).sort().join("+") || "(no changes)";
  changePatternCounts.set(pattern, (changePatternCounts.get(pattern) ?? 0) + 1);
  if (changes.length) {
    if (changedRows.length < 30) {
      changedRows.push({
        sourceRow: wanted.sourceRow,
        id: current.Id,
        asset: current.Name,
        changes,
        lastModifiedDate: current.LastModifiedDate,
      });
    }
  } else if (noChangeRows.length < 20) {
    noChangeRows.push({ sourceRow: wanted.sourceRow, id: current.Id, asset: current.Name });
  }
}

const foundIds = intended.length - missingIds.length;
const totalRowsNeedingChange = [...changePatternCounts.entries()]
  .filter(([pattern]) => pattern !== "(no changes)")
  .reduce((sum, [, count]) => sum + count, 0);
const recentAndNonTampaIds = [...modifiedOnOrAfter20260818Ids].filter((id) => currentNonTampaIds.has(id));
const exceptionUnionIds = new Set([...modifiedOnOrAfter20260818Ids, ...currentNonTampaIds]);

const report = {
  generatedAt: new Date().toISOString(),
  mode: "read-only dry run; no Salesforce records changed",
  targetOrg: {
    alias: "ProboMedical",
    orgId: "00DU0000000LaKoMAK",
    name: "Probo Medical",
    isSandbox: false,
    username: "dokolo@probomedical.com",
  },
  source: {
    workbook: "Copy of TampaInventory_Dataloader_08172026_BN.xlsx",
    sheet: "Sheet1",
    workbookRows: intended.length,
    requestedDate: "2026-08-17",
  },
  object: "ProductItem__c",
  fieldMappings,
  identityChecks: {
    queriedRows: currentRows.length,
    foundIds,
    missingIds,
    assetMismatches,
  },
  comparison: {
    totalRowsNeedingChange,
    totalRowsAlreadyMatching: foundIds - totalRowsNeedingChange,
    fieldChangeCounts,
    fieldSameCounts,
    changePatternCounts: [...changePatternCounts.entries()].sort((a, b) => b[1] - a[1]),
    currentSubLocationValueCounts: [...subLocationValueCounts.entries()].sort((a, b) => b[1] - a[1]),
    locationMismatchCurrentValueCounts: [...locationMismatchCurrentCounts.entries()].sort((a, b) => b[1] - a[1]),
    currentLocationMismatchCategoryCounts: [...currentLocationMismatchCategoryCounts.entries()].sort((a, b) => b[1] - a[1]),
    currentInventoryDateCounts: [...currentInventoryDateCounts.entries()].sort((a, b) => b[1] - a[1]),
    currentStockDateCounts: [...currentStockDateCounts.entries()].sort((a, b) => b[1] - a[1]),
    newerInventoryDates,
    newerStockDates,
    recordFreshness: {
      modifiedOnOrAfter20260818,
      latestLastModifiedDate,
      examples: modifiedOnOrAfter20260818Examples,
    },
    exceptionScope: {
      currentNonTampaCount: currentNonTampaIds.size,
      currentNonTampaExamples,
      recentAndNonTampaCount: recentAndNonTampaIds.length,
      recentOrNonTampaUniqueCount: exceptionUnionIds.size,
      standardRowsAfterExceptionReview: foundIds - exceptionUnionIds.size,
    },
    locationMismatchExamples,
    currentLocationMismatchExamples,
    changedRowExamples: changedRows,
    noChangeRowExamples: noChangeRows,
  },
};

await fs.writeFile(
  path.join(baseDir, "dry_run_report.json"),
  JSON.stringify(report, null, 2) + "\n",
  "utf8",
);

console.log(JSON.stringify(report));
if (missingIds.length || assetMismatches.length || currentRows.length !== intended.length) {
  process.exitCode = 1;
}
