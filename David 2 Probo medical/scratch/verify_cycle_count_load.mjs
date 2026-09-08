import fs from "node:fs/promises";
import { Workbook } from "@oai/artifact-tool";

const outputDir = "outputs/cycle_count_2026-08-04_load";
const targetDate = "2026-08-04";

const readCsv = async (filePath, sheetName) => {
  const csv = await fs.readFile(filePath, "utf8");
  const workbook = await Workbook.fromCSV(csv, { sheetName });
  const values = workbook.worksheets.getItem(sheetName).getUsedRange().values;
  const headers = values[0].map(String);
  return values.slice(1).map((row) =>
    Object.fromEntries(headers.map((header, index) => [header, row[index] ?? ""])),
  );
};

const backup = await readCsv(`${outputDir}/00_rollback_backup_5219.csv`, "Backup");
const pilot = await readCsv(`${outputDir}/01_pilot_update_10.csv`, "Pilot");
const main = await readCsv(`${outputDir}/02_main_remaining_update_5199.csv`, "Main");
const future = await readCsv(`${outputDir}/03_future_date_corrections_7.csv`, "Future");
const later = await readCsv(`${outputDir}/04_preserve_later_stock_update_3.csv`, "Later");
const postSlc = await readCsv("scratch/postload_slc_assets.csv", "PostSLC");
const postOther = await readCsv("scratch/postload_non_slc_assets.csv", "PostOther");

const backupById = new Map(backup.map((row) => [String(row.Id), row]));
const postById = new Map([...postSlc, ...postOther].map((row) => [String(row.Id), row]));

const expected = new Map();
for (const row of [...pilot, ...main, ...future]) {
  expected.set(String(row.Id), {
    stockChecked: targetDate,
    inventoryCountDate: targetDate,
  });
}
for (const row of later) {
  const id = String(row.Id);
  const original = backupById.get(id);
  if (!original) throw new Error(`Later-stock record missing from backup: ${id}`);
  expected.set(id, {
    stockChecked: String(original.Original_Stock_Checked__c),
    inventoryCountDate: targetDate,
  });
}

const missing = [];
const stockMismatches = [];
const inventoryMismatches = [];
const locationCounts = new Map();

for (const [id, wanted] of expected) {
  const actual = postById.get(id);
  if (!actual) {
    missing.push(id);
    continue;
  }
  const location = String(actual.Location__c || "(blank)");
  locationCounts.set(location, (locationCounts.get(location) ?? 0) + 1);
  if (String(actual.Stock_Checked__c || "") !== wanted.stockChecked) {
    stockMismatches.push({
      id,
      assetNo: actual.Name,
      expected: wanted.stockChecked,
      actual: actual.Stock_Checked__c || null,
    });
  }
  if (String(actual.Inventory_Count_Date__c || "") !== wanted.inventoryCountDate) {
    inventoryMismatches.push({
      id,
      assetNo: actual.Name,
      expected: wanted.inventoryCountDate,
      actual: actual.Inventory_Count_Date__c || null,
    });
  }
}

const laterVerification = later.map((row) => {
  const actual = postById.get(String(row.Id));
  return {
    id: row.Id,
    assetNo: actual?.Name ?? null,
    stockChecked: actual?.Stock_Checked__c ?? null,
    inventoryCountDate: actual?.Inventory_Count_Date__c ?? null,
  };
});

const receipt = {
  generatedAt: new Date().toISOString(),
  targetOrg: {
    alias: "ProboMedical",
    orgId: "00DU0000000LaKoMAK",
    name: "Probo Medical",
    isSandbox: false,
    username: "dokolo@probomedical.com",
  },
  operation: {
    object: "ProductItem__c",
    sourceRows: 5404,
    uniqueTargetRecords: expected.size,
    targetInventoryCountDate: targetDate,
    targetStockCheckedRecords: 5216,
    preservedLaterStockCheckedRecords: 3,
  },
  jobs: [
    { scope: "pilot", jobId: "750jR0000004cbOQAQ", processed: 10, successful: 10, failed: 0 },
    { scope: "main_remaining", jobId: "750jR0000004PKpQAM", processed: 5199, successful: 5199, failed: 0 },
    { scope: "future_date_corrections", jobId: "750jR0000004iaLQAQ", processed: 7, successful: 7, failed: 0 },
    { scope: "preserve_later_stock", jobId: "750jR0000004ignQAA", processed: 3, successful: 3, failed: 0 },
  ],
  verification: {
    expectedRecords: expected.size,
    foundRecords: expected.size - missing.length,
    missingRecords: missing,
    stockCheckedMismatches: stockMismatches,
    inventoryCountDateMismatches: inventoryMismatches,
    passed: missing.length === 0 && stockMismatches.length === 0 && inventoryMismatches.length === 0,
    preservedLaterRecords: laterVerification,
    locationCounts: [...locationCounts.entries()].sort((a, b) => b[1] - a[1]),
  },
};

await fs.writeFile(
  `${outputDir}/05_load_receipt.json`,
  JSON.stringify(receipt, null, 2) + "\n",
  "utf8",
);

console.log(JSON.stringify(receipt));
if (!receipt.verification.passed) process.exitCode = 1;
