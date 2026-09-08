import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/Users/LIKKI/Downloads/Copy of TampaInventory_Dataloader_08172026_BN.xlsx";
const previewDir = "scratch/tampa_inventory_dry_run/previews";

const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);

const overview = await workbook.inspect({
  kind: "workbook,sheet,table,definedName,drawing",
  maxChars: 10000,
  tableMaxRows: 8,
  tableMaxCols: 20,
  tableMaxCellChars: 120,
});
console.log(JSON.stringify({ section: "overview", ndjson: overview.ndjson }));

await fs.mkdir(previewDir, { recursive: true });

for (const sheet of workbook.worksheets.items) {
  const used = sheet.getUsedRange();
  if (!used) {
    console.log(JSON.stringify({ section: "sheet", sheet: sheet.name, empty: true }));
    continue;
  }

  const values = used.values;
  const formulas = used.formulas;
  const headers = (values[0] ?? []).map((value) => String(value ?? "").trim());
  const rows = values.slice(1);
  const formulaCells = formulas
    .flat()
    .filter((value) => typeof value === "string" && value.startsWith("="))
    .length;

  const columns = headers.map((header, index) => {
    const entries = rows.map((row) => row[index]);
    const blankCount = entries.filter(
      (value) => value == null || String(value).trim() === "",
    ).length;
    const distinct = new Map();
    for (const value of entries) {
      const normalized = value == null || String(value).trim() === "" ? "(blank)" : String(value);
      distinct.set(normalized, (distinct.get(normalized) ?? 0) + 1);
    }
    return {
      index,
      header,
      blankCount,
      nonBlankCount: entries.length - blankCount,
      uniqueCount: distinct.size,
      mostCommon: [...distinct.entries()]
        .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
        .slice(0, 12),
    };
  });

  const duplicateCandidates = [];
  for (const column of columns) {
    if (!/(^id$|asset|serial|name|product|inventory)/i.test(column.header)) continue;
    const counts = new Map();
    for (const row of rows) {
      const raw = row[column.index];
      const key = raw == null ? "" : String(raw).trim();
      if (!key) continue;
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }
    const duplicates = [...counts.entries()].filter(([, count]) => count > 1);
    duplicateCandidates.push({
      header: column.header,
      duplicateValueCount: duplicates.length,
      duplicateExtraRows: duplicates.reduce((sum, [, count]) => sum + count - 1, 0),
      examples: duplicates.slice(0, 20),
    });
  }

  console.log(JSON.stringify({
    section: "sheet",
    sheet: sheet.name,
    usedRange: used.address,
    rowCountIncludingHeader: values.length,
    dataRowCount: rows.length,
    columnCount: headers.length,
    headers,
    formulaCells,
    columns,
    duplicateCandidates,
    firstRows: rows.slice(0, 10),
    lastRows: rows.slice(-5),
  }));

  const lastPreviewRow = Math.min(35, values.length);
  const lastPreviewColumn = Math.min(20, headers.length);
  const columnName = (number) => {
    let n = number;
    let name = "";
    while (n > 0) {
      n -= 1;
      name = String.fromCharCode(65 + (n % 26)) + name;
      n = Math.floor(n / 26);
    }
    return name;
  };
  const previewRange = `A1:${columnName(lastPreviewColumn)}${lastPreviewRow}`;
  const preview = await workbook.render({
    sheetName: sheet.name,
    range: previewRange,
    scale: 1,
    format: "png",
  });
  const safeName = sheet.name.replace(/[^a-z0-9_-]+/gi, "_");
  await fs.writeFile(
    `${previewDir}/${safeName}.png`,
    new Uint8Array(await preview.arrayBuffer()),
  );
  console.log(JSON.stringify({ section: "preview", sheet: sheet.name, previewRange, path: `${previewDir}/${safeName}.png` }));
}

