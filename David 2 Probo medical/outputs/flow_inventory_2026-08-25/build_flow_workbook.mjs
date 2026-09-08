import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";


const outputDir = path.resolve("outputs/flow_inventory_2026-08-25");
const analysis = JSON.parse(
  await fs.readFile(path.join(outputDir, "automation_analysis.json"), "utf8"),
);

const workbook = Workbook.create();
const sheetOrder = [
  "Executive Summary",
  "Flow Catalog",
  "Flow Versions",
  "Flow Details",
  "Consolidation Plan",
  "Connections",
  "Object Map",
  "Code Inventory",
  "Code Overlap",
  "Method & Notes",
];
for (const sheetName of sheetOrder) workbook.worksheets.add(sheetName);
for (const row of analysis.flowCatalog) {
  row["Record Triggered"] = row.Active === "Yes" && row["Start Object"] ? "Yes" : "No";
}
const palette = {
  navy: "#123B5D",
  teal: "#0F6B78",
  cyan: "#DCEFF3",
  lightBlue: "#EAF3F8",
  pale: "#F6F9FB",
  white: "#FFFFFF",
  text: "#172B3A",
  gray: "#627482",
  line: "#D7E0E7",
  green: "#DFF2E1",
  greenText: "#1E6B36",
  amber: "#FFF0CC",
  amberText: "#8A5A00",
  red: "#FCE1E1",
  redText: "#9A2424",
};


function excelColumn(index) {
  let value = index + 1;
  let result = "";
  while (value > 0) {
    const remainder = (value - 1) % 26;
    result = String.fromCharCode(65 + remainder) + result;
    value = Math.floor((value - 1) / 26);
  }
  return result;
}


function normalizeValue(key, value) {
  if (value === undefined || value === null) return null;
  if (
    typeof value === "string" &&
    value &&
    /(Date|Modified|Generated)/i.test(key) &&
    /^\d{4}-\d{2}-\d{2}T/.test(value)
  ) {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }
  if (typeof value === "string" && value.length > 32700) {
    return `${value.slice(0, 32650)}…`;
  }
  return value;
}


function styleTitle(sheet, title, subtitle, lastColumn) {
  sheet.showGridLines = false;
  const titleRange = `A1:${lastColumn}1`;
  const subtitleRange = `A2:${lastColumn}2`;
  sheet.mergeCells(titleRange);
  sheet.mergeCells(subtitleRange);
  sheet.getRange("A1").values = [[title]];
  sheet.getRange("A2").values = [[subtitle]];
  sheet.getRange(titleRange).format = {
    fill: palette.navy,
    font: { bold: true, color: palette.white, size: 16 },
    verticalAlignment: "center",
  };
  sheet.getRange(subtitleRange).format = {
    fill: palette.lightBlue,
    font: { color: palette.gray, italic: true, size: 10 },
    verticalAlignment: "center",
    wrapText: true,
  };
  sheet.getRange(titleRange).format.rowHeight = 28;
  sheet.getRange(subtitleRange).format.rowHeight = 34;
}


function addConditionalText(range, text, fill, fontColor) {
  range.conditionalFormats.add("containsText", {
    text,
    format: { fill, font: { color: fontColor, bold: true } },
  });
}


function addDataSheet({
  name,
  title,
  subtitle,
  rows,
  columns,
  widths = {},
  wrap = [],
  dateColumns = [],
  integerColumns = [],
  tableName,
  rowHeight = 22,
}) {
  const sheet = workbook.worksheets.getItem(name);
  const lastCol = excelColumn(columns.length - 1);
  styleTitle(sheet, title, subtitle, lastCol);
  const matrix = [
    columns,
    ...rows.map((row) => columns.map((key) => normalizeValue(key, row[key]))),
  ];
  const endRow = 4 + rows.length;
  sheet.getRange(`A4:${lastCol}${endRow}`).values = matrix;
  sheet.getRange(`A4:${lastCol}4`).format = {
    fill: palette.teal,
    font: { bold: true, color: palette.white, size: 10 },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    wrapText: true,
    borders: { preset: "outside", style: "thin", color: palette.teal },
  };
  sheet.getRange(`A4:${lastCol}4`).format.rowHeight = 36;
  if (rows.length) {
    sheet.getRange(`A5:${lastCol}${endRow}`).format = {
      font: { color: palette.text, size: 9 },
      verticalAlignment: "top",
    };
    sheet.getRange(`A5:${lastCol}${endRow}`).format.rowHeight = rowHeight;
    const table = sheet.tables.add(`A4:${lastCol}${endRow}`, true, tableName);
    table.style = "TableStyleMedium2";
    table.showFilterButton = true;
  }
  for (let index = 0; index < columns.length; index += 1) {
    const key = columns[index];
    const col = excelColumn(index);
    sheet.getRange(`${col}1:${col}${endRow}`).format.columnWidth = widths[key] ?? 16;
    if (wrap.includes(key) && rows.length) {
      sheet.getRange(`${col}5:${col}${endRow}`).format.wrapText = true;
    }
    if (dateColumns.includes(key) && rows.length) {
      sheet.getRange(`${col}5:${col}${endRow}`).format.numberFormat = "yyyy-mm-dd hh:mm";
    }
    if (integerColumns.includes(key) && rows.length) {
      sheet.getRange(`${col}5:${col}${endRow}`).format.numberFormat = "#,##0";
    }
  }
  sheet.freezePanes.freezeRows(4);
  sheet.freezePanes.freezeColumns(Math.min(2, columns.length));
  return { sheet, endRow, columns };
}


const summary = workbook.worksheets.getItem("Executive Summary");
summary.showGridLines = false;
styleTitle(
  summary,
  "Probo Medical — Flow Refactor & Orchestration Analysis",
  "Live production inventory as of 2026-08-25. Read-only analysis of Flow, Apex, Trigger, LWC, and Aura metadata; no Flow or code changes were made.",
  "K",
);
summary.getRange("A4:C4").merge();
summary.getRange("A4").values = [["Live Org Coverage"]];
summary.getRange("A4:C4").format = {
  fill: palette.teal,
  font: { bold: true, color: palette.white, size: 11 },
};
summary.getRange("A5:C5").values = [["Metric", "Value", "Why it matters"]];
summary.getRange("A5:C5").format = {
  fill: palette.cyan,
  font: { bold: true, color: palette.text },
  borders: { preset: "outside", style: "thin", color: palette.line },
};

const catalogEnd = 4 + analysis.flowCatalog.length;
const consolidationEnd = 4 + analysis.consolidationPlan.length;
const connectionEnd = 4 + analysis.connections.length;
const codeEnd = 4 + analysis.codeInventory.length;
const metricRows = [
  ["Flow definitions", `=COUNTA('Flow Catalog'!$B$5:$B$${catalogEnd})`, "All current Flow definitions, active and inactive"],
  ["Active definitions", `=COUNTIF('Flow Catalog'!$D$5:$D$${catalogEnd},\"Yes\")`, "Authoritative ActiveVersionId is populated"],
  ["Active record-triggered flows", `=COUNTIFS('Flow Catalog'!$D$5:$D$${catalogEnd},\"Yes\",'Flow Catalog'!$K$5:$K$${catalogEnd},\"Yes\")`, "Flows currently entering on a Salesforce object"],
  ["Active differs from latest", `=COUNTIFS('Flow Catalog'!$D$5:$D$${catalogEnd},\"Yes\",'Flow Catalog'!$G$5:$G$${catalogEnd},\"No\")`, "Latest draft is not the running version"],
  ["High-priority refactor lanes", `=COUNTIF('Consolidation Plan'!$A$5:$A$${consolidationEnd},\"High\")`, "Object/timing lanes with dense or coded overlap"],
  ["Subflow connections", `=COUNTIF('Connections'!$D$5:$D$${connectionEnd},\"Subflow\")`, "Existing Flow-to-Flow reuse"],
  ["Apex triggers", `=COUNTIF('Code Inventory'!$A$5:$A$${codeEnd},\"Apex Trigger\")`, "Coded object automation requiring joint transaction review"],
  ["Orchestrator flows", analysis.metrics.OrchestratorFlows, "One exists and is currently inactive; Orchestrator is not a universal merge mechanism"],
];
summary.getRange(`A6:C${5 + metricRows.length}`).values = metricRows.map((row) => [row[0], null, row[2]]);
summary.getRange(`B6:B${5 + metricRows.length}`).formulas = metricRows.map((row) => [typeof row[1] === "string" && row[1].startsWith("=") ? row[1] : `=${row[1]}`]);
summary.getRange(`A6:C${5 + metricRows.length}`).format = {
  fill: palette.pale,
  font: { color: palette.text, size: 10 },
  borders: { preset: "inside", style: "thin", color: palette.line },
  verticalAlignment: "center",
};
summary.getRange(`B6:B${5 + metricRows.length}`).format = {
  fill: palette.lightBlue,
  font: { bold: true, color: palette.navy, size: 13 },
  horizontalAlignment: "center",
  numberFormat: "#,##0",
};
summary.getRange(`C6:C${5 + metricRows.length}`).format.wrapText = true;

summary.getRange("E4:K4").merge();
summary.getRange("E4").values = [["Highest-Priority Consolidation Lanes"]];
summary.getRange("E4:K4").format = {
  fill: palette.teal,
  font: { bold: true, color: palette.white, size: 11 },
};
const topLanes = analysis.consolidationPlan.slice(0, 10);
const topHeaders = ["Priority", "Object", "Timing", "Event", "Flows", "Apex", "Recommended target"];
summary.getRange(`E5:K${5 + topLanes.length}`).values = [
  topHeaders,
  ...topLanes.map((row) => [
    row.Priority,
    row.Object,
    row["Trigger Timing"],
    row["Record Event"],
    row["Active Flow Count"],
    row["Apex Trigger Count"],
    row["Recommended Target Pattern"],
  ]),
];
summary.getRange("E5:K5").format = {
  fill: palette.cyan,
  font: { bold: true, color: palette.text },
  wrapText: true,
};
summary.getRange(`E6:K${5 + topLanes.length}`).format = {
  font: { size: 9, color: palette.text },
  verticalAlignment: "top",
  borders: { preset: "inside", style: "thin", color: palette.line },
};
summary.getRange(`K6:K${5 + topLanes.length}`).format.wrapText = true;
summary.getRange(`E6:E${5 + topLanes.length}`).format.horizontalAlignment = "center";
addConditionalText(summary.getRange(`E6:E${5 + topLanes.length}`), "High", palette.red, palette.redText);
addConditionalText(summary.getRange(`E6:E${5 + topLanes.length}`), "Medium", palette.amber, palette.amberText);

summary.getRange("A16:K16").merge();
summary.getRange("A16").values = [["Target Architecture Guardrails"]];
summary.getRange("A16:K16").format = {
  fill: palette.navy,
  font: { bold: true, color: palette.white, size: 11 },
};
const guardrails = [
  ["Do not force every object into one universal Flow.", "Separate before-save, after-save, delete, scheduled, and screen behavior because their transaction semantics differ."],
  ["Use one entry Flow per compatible object/timing/event lane.", "Route business domains through autolaunched Subflows; preserve entry criteria, trigger order, async paths, and fault handling."],
  ["Treat Apex and LWC as architecture boundaries.", "Trace Apex triggers and handlers on the same object; preserve Invocable Apex and Flow-screen component contracts during consolidation."],
  ["Use Flow Orchestrator selectively.", "Use it for long-running, multi-user stages and approvals—not to combine same-transaction record automation."],
  ["Prototype and regression-test in a sandbox.", "Create a rule matrix, choose ownership for every write/action, test bulk behavior and recursion, then migrate in controlled waves."],
];
summary.getRange("A17:K21").values = guardrails.map((row) => [row[0], null, null, null, row[1], null, null, null, null, null, null]);
summary.mergeCells("A17:D17");
summary.mergeCells("E17:K17");
for (let row = 18; row <= 21; row += 1) {
  summary.mergeCells(`A${row}:D${row}`);
  summary.mergeCells(`E${row}:K${row}`);
}
summary.getRange("A17:K21").format = {
  fill: palette.pale,
  font: { color: palette.text, size: 10 },
  borders: { preset: "inside", style: "thin", color: palette.line },
  wrapText: true,
  verticalAlignment: "center",
};
summary.getRange("A17:D21").format = {
  fill: palette.teal,
  font: { bold: true, color: palette.white, size: 10 },
  verticalAlignment: "center",
};
summary.getRange("A17:K21").format.rowHeight = 42;
summary.getRange("A1:A21").format.columnWidth = 24;
summary.getRange("B1:B21").format.columnWidth = 12;
summary.getRange("C1:C21").format.columnWidth = 34;
summary.getRange("D1:D21").format.columnWidth = 3;
summary.getRange("E1:E21").format.columnWidth = 12;
summary.getRange("F1:F21").format.columnWidth = 19;
summary.getRange("G1:G21").format.columnWidth = 18;
summary.getRange("H1:H21").format.columnWidth = 16;
summary.getRange("I1:J21").format.columnWidth = 9;
summary.getRange("K1:K21").format.columnWidth = 48;
summary.freezePanes.freezeRows(2);


const catalogColumns = [
  "Definition ID", "API Name", "Label", "Active", "Active Version", "Latest Version", "Active = Latest",
  "Analysis Basis", "Process Type", "Start Object", "Record Triggered", "Record Event", "Trigger Timing", "Run Mode", "Trigger Order",
  "Scheduled Frequency", "API Version", "Managed State", "Version Count", "Total Elements", "Objects Touched",
  "Subflow Calls", "Action Calls", "Screen Components", "Complexity (1-5)", "Consolidation Signal", "Last Modified",
  "Last Modified By", "Description", "Risk Flags",
];
const catalog = addDataSheet({
  name: "Flow Catalog",
  title: "Flow Catalog — Definition-Level Inventory",
  subtitle: "One row per live FlowDefinition. Active state comes from ActiveVersionId; analysis uses the active version when it differs from the latest draft.",
  rows: analysis.flowCatalog,
  columns: catalogColumns,
  tableName: "FlowCatalogTable",
  widths: {
    "Definition ID": 20, "API Name": 36, Label: 36, Active: 9, "Active Version": 12, "Latest Version": 12,
    "Active = Latest": 13, "Analysis Basis": 30, "Process Type": 20, "Start Object": 22, "Record Triggered": 14, "Record Event": 18,
    "Trigger Timing": 20, "Run Mode": 18, "Trigger Order": 12, "Scheduled Frequency": 17, "API Version": 11,
    "Managed State": 14, "Version Count": 12, "Total Elements": 12, "Objects Touched": 13, "Subflow Calls": 12,
    "Action Calls": 12, "Screen Components": 14, "Complexity (1-5)": 14, "Consolidation Signal": 18,
    "Last Modified": 20, "Last Modified By": 20, Description: 52, "Risk Flags": 38,
  },
  wrap: ["Analysis Basis", "Description", "Risk Flags"],
  dateColumns: ["Last Modified"],
  integerColumns: ["Active Version", "Latest Version", "Version Count", "Total Elements", "Objects Touched", "Subflow Calls", "Action Calls", "Screen Components", "Complexity (1-5)"],
  rowHeight: 34,
});
const activeCol = excelColumn(catalogColumns.indexOf("Active"));
const activeLatestCol = excelColumn(catalogColumns.indexOf("Active = Latest"));
const complexityCol = excelColumn(catalogColumns.indexOf("Complexity (1-5)"));
addConditionalText(catalog.sheet.getRange(`${activeCol}5:${activeCol}${catalog.endRow}`), "Yes", palette.green, palette.greenText);
addConditionalText(catalog.sheet.getRange(`${activeCol}5:${activeCol}${catalog.endRow}`), "No", "#E9EEF2", palette.gray);
addConditionalText(catalog.sheet.getRange(`${activeLatestCol}5:${activeLatestCol}${catalog.endRow}`), "No", palette.red, palette.redText);
catalog.sheet.getRange(`${complexityCol}5:${complexityCol}${catalog.endRow}`).conditionalFormats.add("colorScale", {
  colors: [palette.green, palette.amber, palette.red],
  thresholds: ["min", "50%", "max"],
});


const versionColumns = [
  "Flow API Name", "Definition ID", "Version ID", "Version", "Status", "Is Active Version", "Is Latest Version",
  "Process Type", "API Version", "Managed State", "Is Template", "Run Mode", "Trigger Order", "Created Date", "Created By",
  "Last Modified", "Last Modified By", "Label", "Description",
];
const versionsSheet = addDataSheet({
  name: "Flow Versions",
  title: "Flow Versions — Complete Historical Inventory",
  subtitle: "All 3,645 Tooling API Flow versions. Use the active/latest indicators to distinguish runtime versions, latest drafts, obsolete versions, and historical ownership.",
  rows: analysis.flowVersions,
  columns: versionColumns,
  tableName: "FlowVersionsTable",
  widths: {
    "Flow API Name": 36, "Definition ID": 20, "Version ID": 20, Version: 10, Status: 12, "Is Active Version": 14,
    "Is Latest Version": 14, "Process Type": 20, "API Version": 11, "Managed State": 14, "Is Template": 11,
    "Run Mode": 18, "Trigger Order": 12, "Created Date": 20, "Created By": 20, "Last Modified": 20,
    "Last Modified By": 20, Label: 38, Description: 56,
  },
  wrap: ["Description"],
  dateColumns: ["Created Date", "Last Modified"],
  integerColumns: ["Version", "API Version", "Trigger Order"],
  rowHeight: 30,
});
const versionStatusCol = excelColumn(versionColumns.indexOf("Status"));
addConditionalText(versionsSheet.sheet.getRange(`${versionStatusCol}5:${versionStatusCol}${versionsSheet.endRow}`), "Active", palette.green, palette.greenText);
addConditionalText(versionsSheet.sheet.getRange(`${versionStatusCol}5:${versionStatusCol}${versionsSheet.endRow}`), "Draft", palette.amber, palette.amberText);


const detailColumns = [
  "Definition ID", "API Name", "Active", "Analysis Basis", "Start Filters", "Objects", "Fields Referenced", "Actions",
  "Subflows", "Screen Components", "Total Elements", "actionCalls", "apexPluginCalls", "assignments", "collectionProcessors",
  "customErrors", "decisions", "loops", "orchestratedStages", "recordCreates", "recordDeletes", "recordLookups",
  "recordRollbacks", "recordUpdates", "screens", "steps", "subflows", "transforms", "waits",
];
const detailsSheet = addDataSheet({
  name: "Flow Details",
  title: "Flow Details — Elements, Fields, Actions, and Reuse",
  subtitle: "Element-level summary for the running active version, or the latest version when a definition is inactive. Long lists are retained in cells for filtering and audit.",
  rows: analysis.flowDetails,
  columns: detailColumns,
  tableName: "FlowDetailsTable",
  widths: {
    "Definition ID": 20, "API Name": 36, Active: 9, "Analysis Basis": 30, "Start Filters": 55, Objects: 35,
    "Fields Referenced": 60, Actions: 42, Subflows: 42, "Screen Components": 38, "Total Elements": 12,
  },
  wrap: ["Analysis Basis", "Start Filters", "Objects", "Fields Referenced", "Actions", "Subflows", "Screen Components"],
  integerColumns: ["Total Elements", ...detailColumns.slice(11)],
  rowHeight: 46,
});


const planColumns = [
  "Priority", "Object", "Trigger Timing", "Record Event", "Active Flow Count", "Apex Trigger Count", "Active Flows",
  "Apex Triggers", "Recommended Target Pattern", "Flow Orchestrator Fit", "Next R&D Step",
];
const planSheet = addDataSheet({
  name: "Consolidation Plan",
  title: "Consolidation Plan — Compatible Object/Timing/Event Lanes",
  subtitle: "A safe target is one entry Flow per compatible transaction lane, not one universal Flow per object. Rows combine live Flow density with Apex-trigger overlap.",
  rows: analysis.consolidationPlan,
  columns: planColumns,
  tableName: "ConsolidationPlanTable",
  widths: {
    Priority: 11, Object: 24, "Trigger Timing": 22, "Record Event": 19, "Active Flow Count": 14, "Apex Trigger Count": 14,
    "Active Flows": 68, "Apex Triggers": 36, "Recommended Target Pattern": 72, "Flow Orchestrator Fit": 52, "Next R&D Step": 64,
  },
  wrap: ["Active Flows", "Apex Triggers", "Recommended Target Pattern", "Flow Orchestrator Fit", "Next R&D Step"],
  integerColumns: ["Active Flow Count", "Apex Trigger Count"],
  rowHeight: 72,
});
const priorityCol = excelColumn(planColumns.indexOf("Priority"));
addConditionalText(planSheet.sheet.getRange(`${priorityCol}5:${priorityCol}${planSheet.endRow}`), "High", palette.red, palette.redText);
addConditionalText(planSheet.sheet.getRange(`${priorityCol}5:${priorityCol}${planSheet.endRow}`), "Medium", palette.amber, palette.amberText);
addConditionalText(planSheet.sheet.getRange(`${priorityCol}5:${priorityCol}${planSheet.endRow}`), "Low", palette.green, palette.greenText);


const connectionColumns = ["Source Flow", "Source Active", "Analysis Basis", "Connection Type", "Element", "Target", "Target Found", "Details"];
const connectionSheet = addDataSheet({
  name: "Connections",
  title: "Connections — Subflows, Actions, Apex, and Screen Components",
  subtitle: "Direct dependencies extracted from the active runtime design (or latest inactive design). Object reads/writes are separated into Object Map.",
  rows: analysis.connections,
  columns: connectionColumns,
  tableName: "ConnectionsTable",
  widths: {
    "Source Flow": 38, "Source Active": 12, "Analysis Basis": 30, "Connection Type": 20, Element: 32, Target: 42,
    "Target Found": 14, Details: 52,
  },
  wrap: ["Analysis Basis", "Details"],
  rowHeight: 34,
});


const objectColumns = ["Definition ID", "Flow API Name", "Flow Active", "Analysis Basis", "Object", "Roles", "Start Object", "Process Type"];
const objectSheet = addDataSheet({
  name: "Object Map",
  title: "Object Map — Flow Read/Write/Trigger Footprint",
  subtitle: "One row per Flow/object relationship. Filter by object to see trigger ownership, reads, writes, creates, deletes, choices, and variable usage.",
  rows: analysis.objectMap,
  columns: objectColumns,
  tableName: "ObjectMapTable",
  widths: {
    "Definition ID": 20, "Flow API Name": 38, "Flow Active": 11, "Analysis Basis": 30, Object: 24, Roles: 30,
    "Start Object": 12, "Process Type": 20,
  },
  wrap: ["Analysis Basis", "Roles"],
  rowHeight: 30,
});


const codeColumns = [
  "Component Type", "Component", "Status / Exposure", "Primary Object", "Events / Targets", "Invocable / Flow Screen",
  "Direct Flow References", "Referenced Flows", "Referenced Apex", "Objects Referenced",
];
const codeSheet = addDataSheet({
  name: "Code Inventory",
  title: "Code Inventory — Apex, Triggers, LWC, and Aura",
  subtitle: "Retrieved code inventory with exact trigger targets, Invocable Apex markers, Flow-screen exposure, direct Flow references, Apex imports, and object-schema references.",
  rows: analysis.codeInventory,
  columns: codeColumns,
  tableName: "CodeInventoryTable",
  widths: {
    "Component Type": 18, Component: 36, "Status / Exposure": 42, "Primary Object": 24, "Events / Targets": 42,
    "Invocable / Flow Screen": 20, "Direct Flow References": 16, "Referenced Flows": 55, "Referenced Apex": 42,
    "Objects Referenced": 55,
  },
  wrap: ["Status / Exposure", "Events / Targets", "Referenced Flows", "Referenced Apex", "Objects Referenced"],
  integerColumns: ["Direct Flow References"],
  rowHeight: 46,
});


const overlapColumns = ["Overlap Type", "Object / Target", "Code Component", "Flow", "Confidence", "Risk", "Recommendation"];
const overlapSheet = addDataSheet({
  name: "Code Overlap",
  title: "Code Overlap — High-Confidence Flow/Apex/LWC Boundaries",
  subtitle: "High-confidence overlaps only: Apex triggers sharing object transactions, direct Flow-to-Apex calls, and Flow-screen component usage.",
  rows: analysis.codeOverlap,
  columns: overlapColumns,
  tableName: "CodeOverlapTable",
  widths: {
    "Overlap Type": 34, "Object / Target": 24, "Code Component": 36, Flow: 60, Confidence: 12, Risk: 58, Recommendation: 68,
  },
  wrap: ["Flow", "Risk", "Recommendation"],
  rowHeight: 58,
});
const confidenceCol = excelColumn(overlapColumns.indexOf("Confidence"));
addConditionalText(overlapSheet.sheet.getRange(`${confidenceCol}5:${confidenceCol}${overlapSheet.endRow}`), "High", palette.green, palette.greenText);


const notes = workbook.worksheets.getItem("Method & Notes");
notes.showGridLines = false;
styleTitle(
  notes,
  "Method, Definitions, and Safe Refactor Sequence",
  "Source scope, interpretation rules, limitations, and recommended next-stage execution gates.",
  "H",
);
const noteRows = [
  ["Source org", "Probo Medical production — Org ID 00DU0000000LaKoMAK", "Verified through a read-only Organization query."],
  ["Flow definitions", "716", "Tooling API FlowDefinition query; ActiveVersionId is the authoritative runtime indicator."],
  ["Flow versions", "3,645", "Tooling API Flow query with status, process type, API version, ownership, dates, run mode, and trigger order."],
  ["Flow metadata", "656 XML + 61 Tooling metadata gap records", "The 61 direct Tooling fetches cover missing source files and duplicate API-name ambiguity."],
  ["Active/latest differences", "33", "Each running active version was fetched separately so the analysis does not substitute a newer draft."],
  ["Code scope", "331 Apex classes; 45 triggers; 35 LWC bundles; 37 Aura bundles", "Retrieved read-only through Metadata API."],
  ["Current Orchestrator", "BIPO_Flow, inactive", "The org contains one Orchestrator definition; it is not currently active."],
  ["Consolidation rule", "Group by object + timing + record event", "Before-save, after-save, delete, scheduled, and screen logic should not be collapsed blindly."],
  ["Apex overlap", "Exact trigger-object and direct Invocable Apex links are high confidence", "Static class object references are retained in Code Inventory as discovery evidence, not proof of duplicate business logic."],
  ["LWC/Aura overlap", "Direct screen extension references are high confidence", "Preserve public properties, Apex imports, navigation behavior, and error contracts."],
  ["Orchestrator guidance", "Use for long-running multi-user stages", "Use entry Flows and Subflows for same-transaction object automation."],
  ["Recommended sequence", "1) rule matrix; 2) target entry/subflow design; 3) sandbox prototype; 4) bulk/recursion tests; 5) controlled migration", "Deactivate old paths only after equivalent behavior and rollback evidence are proven."],
  ["Explicit exclusions", "No Flow/code edits, activation changes, deployment, test execution, or production refactor", "This workbook is analysis and planning only."],
  ["Salesforce Flow Setup", "https://probomedical.lightning.force.com/lightning/setup/Flows/home", "Administrator navigation source."],
];
const notesEnd = 4 + noteRows.length;
notes.getRange(`A4:C${notesEnd}`).values = [["Topic", "Evidence / Rule", "Interpretation"], ...noteRows];
notes.getRange("A4:C4").format = {
  fill: palette.teal,
  font: { bold: true, color: palette.white },
  wrapText: true,
};
notes.getRange(`A5:C${notesEnd}`).format = {
  fill: palette.pale,
  font: { color: palette.text, size: 10 },
  wrapText: true,
  verticalAlignment: "top",
  borders: { preset: "inside", style: "thin", color: palette.line },
};
notes.getRange(`A5:C${notesEnd}`).format.rowHeight = 54;
notes.getRange(`A1:A${notesEnd}`).format.columnWidth = 28;
notes.getRange(`B1:B${notesEnd}`).format.columnWidth = 60;
notes.getRange(`C1:C${notesEnd}`).format.columnWidth = 72;
notes.freezePanes.freezeRows(4);


const summaryCheck = await workbook.inspect({
  kind: "table",
  range: "Executive Summary!A1:K21",
  include: "values,formulas",
  tableMaxRows: 25,
  tableMaxCols: 12,
  maxChars: 6000,
});
console.log("SUMMARY_CHECK");
console.log(summaryCheck.ndjson);
const planCheck = await workbook.inspect({
  kind: "table",
  range: "Consolidation Plan!A1:K15",
  include: "values,formulas",
  tableMaxRows: 15,
  tableMaxCols: 12,
  maxChars: 5000,
});
console.log("PLAN_CHECK");
console.log(planCheck.ndjson);
const formulaErrors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 300 },
  summary: "final formula error scan",
  maxChars: 5000,
});
console.log("FORMULA_ERRORS");
console.log(formulaErrors.ndjson);

const previewDir = path.join(outputDir, "previews");
await fs.mkdir(previewDir, { recursive: true });
const previews = [
  ["Executive Summary", "A1:K21"],
  ["Flow Catalog", "A1:L18"],
  ["Flow Versions", "A1:L18"],
  ["Flow Details", "A1:K18"],
  ["Consolidation Plan", "A1:K16"],
  ["Connections", "A1:H18"],
  ["Object Map", "A1:H18"],
  ["Code Inventory", "A1:J18"],
  ["Code Overlap", "A1:G18"],
  ["Method & Notes", "A1:C18"],
];
for (const [sheetName, range] of previews) {
  const preview = await workbook.render({ sheetName, range, scale: 1, format: "png" });
  const safeName = sheetName.toLowerCase().replace(/[^a-z0-9]+/g, "_");
  await fs.writeFile(
    path.join(previewDir, `${safeName}.png`),
    new Uint8Array(await preview.arrayBuffer()),
  );
}

const workbookPath = path.join(
  outputDir,
  "Probo_Medical_Flow_Refactor_and_Orchestration_Analysis_2026-08-25.xlsx",
);
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(workbookPath);
console.log(`WORKBOOK=${workbookPath}`);
