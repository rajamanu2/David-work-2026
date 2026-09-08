import fs from "node:fs/promises";
import path from "node:path";
import { Workbook } from "@oai/artifact-tool";

const mode = process.argv[2] ?? "pilot";
const outputDir = "outputs/tampa_inventory_2026-08-17_load";
const scratchDir = "scratch/tampa_inventory_load";
const fields = [
  "Location__c",
  "Sub_Location__c",
  "Current_Location__c",
  "Inventory_Count_Date__c",
  "Stock_Checked__c",
];

const normalize = (value) => (value == null ? "" : String(value).trim());
const readCsv = async (filePath) => {
  const csv = await fs.readFile(filePath, "utf8");
  const workbook = await Workbook.fromCSV(csv, { sheetName: "Data" });
  const values = workbook.worksheets.getItem("Data").getUsedRange().values;
  const headers = values[0].map((value) => normalize(value));
  return values.slice(1).map((row) =>
    Object.fromEntries(headers.map((header, index) => [header, row[index] ?? ""])),
  );
};

const expectedFiles = mode === "pilot"
  ? [path.join(outputDir, "01_pilot_update_10.csv")]
  : [
      path.join(outputDir, "01_pilot_update_10.csv"),
      path.join(outputDir, "02_main_remaining_update_1788.csv"),
    ];
const actualFiles = mode === "pilot"
  ? [path.join(scratchDir, "pilot_postload.csv")]
  : (await fs.readdir(path.join(scratchDir, "all_postload")))
      .filter((file) => file.endsWith(".csv"))
      .sort()
      .map((file) => path.join(scratchDir, "all_postload", file));

const expectedRows = (await Promise.all(expectedFiles.map(readCsv))).flat();
const actualRows = (await Promise.all(actualFiles.map(readCsv))).flat();
const expectedById = new Map(expectedRows.map((row) => [normalize(row.Id), row]));
const actualById = new Map(actualRows.map((row) => [normalize(row.Id), row]));

const missing = [];
const mismatches = [];
for (const [id, expected] of expectedById) {
  const actual = actualById.get(id);
  if (!actual) {
    missing.push(id);
    continue;
  }
  for (const field of fields) {
    const expectedRaw = normalize(expected[field]);
    const wanted = expectedRaw === "#N/A" ? "" : expectedRaw;
    const found = normalize(actual[field]);
    if (wanted !== found) {
      mismatches.push({ id, asset: normalize(actual.Name), field, expected: wanted || null, actual: found || null });
    }
  }
}

const unexpected = [...actualById.keys()].filter((id) => !expectedById.has(id));
const result = {
  mode,
  expectedRecords: expectedById.size,
  actualRecords: actualById.size,
  missing,
  unexpected,
  mismatches,
  passed:
    expectedById.size === actualById.size &&
    missing.length === 0 &&
    unexpected.length === 0 &&
    mismatches.length === 0,
};

await fs.writeFile(
  path.join(scratchDir, `${mode}_verification.json`),
  JSON.stringify(result, null, 2) + "\n",
  "utf8",
);
console.log(JSON.stringify(result));
if (!result.passed) process.exitCode = 1;

