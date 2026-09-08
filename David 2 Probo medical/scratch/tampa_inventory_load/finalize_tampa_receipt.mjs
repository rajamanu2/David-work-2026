import fs from "node:fs/promises";
import path from "node:path";

const outputDir = "outputs/tampa_inventory_2026-08-17_load";
const plan = JSON.parse(
  await fs.readFile(path.join(outputDir, "load_plan_and_file_verification.json"), "utf8"),
);
const verification = JSON.parse(
  await fs.readFile("scratch/tampa_inventory_load/all_verification.json", "utf8"),
);
if (!verification.passed || verification.expectedRecords !== 1798) {
  throw new Error("Cannot finalize receipt because full post-load verification did not pass");
}

const receipt = {
  generatedAt: new Date().toISOString(),
  source: plan.source,
  targetOrg: {
    alias: "ProboMedical",
    orgId: "00DU0000000LaKoMAK",
    name: "Probo Medical",
    isSandbox: false,
    username: "dokolo@probomedical.com",
  },
  operation: {
    object: "ProductItem__c",
    type: "update",
    approvedScope: "all 1,798 Tampa workbook rows, including the 54 preflight exceptions",
    fields: plan.load.fields,
    targetDate: plan.source.targetDate,
    subLocationResult: "cleared to null on all 1,798 records",
    nullStrategy: plan.load.nullStrategy,
  },
  jobs: [
    {
      scope: "pilot",
      jobId: "750jR000000CD9eQAG",
      state: "JobComplete",
      processed: 10,
      successful: 10,
      failed: 0,
      retries: 0,
    },
    {
      scope: "main_remaining",
      jobId: "750jR000000C2vjQAC",
      state: "JobComplete",
      processed: 1788,
      successful: 1788,
      failed: 0,
      retries: 0,
    },
  ],
  totals: {
    processed: 1798,
    successful: 1798,
    failed: 0,
  },
  verification: {
    queriedRecords: verification.actualRecords,
    expectedRecords: verification.expectedRecords,
    missingRecords: verification.missing,
    unexpectedRecords: verification.unexpected,
    fieldMismatches: verification.mismatches,
    fieldsChecked: [
      "Location__c",
      "Sub_Location__c",
      "Current_Location__c",
      "Inventory_Count_Date__c",
      "Stock_Checked__c",
    ],
    passed: verification.passed,
  },
  artifacts: plan.verification.map(({ file, rows, sha256 }) => ({ file, rows, sha256 })),
};

await fs.writeFile(
  path.join(outputDir, "03_load_receipt.json"),
  JSON.stringify(receipt, null, 2) + "\n",
  "utf8",
);
console.log(JSON.stringify(receipt));

