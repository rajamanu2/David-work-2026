import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const sourcePath = "C:/Users/LIKKI/Downloads/Copy of Copy of Greggs Training Calendar.xlsx";
const outputDir = "C:/Users/LIKKI/Documents/ChatGPT/David 2 Probo medical/.work/training_calendar_dry_run/previews";

await fs.mkdir(outputDir, { recursive: true });
const input = await FileBlob.load(sourcePath);
const workbook = await SpreadsheetFile.importXlsx(input);

const overview = await workbook.inspect({
  kind: "workbook,sheet,table,definedName,drawing",
  maxChars: 12000,
  tableMaxRows: 12,
  tableMaxCols: 12,
  tableMaxCellChars: 160,
});
console.log("===OVERVIEW===");
console.log(overview.ndjson);

const sheets = workbook.worksheets.items;
for (const sheet of sheets) {
  const used = sheet.getUsedRange();
  const region = await workbook.inspect({
    kind: "region",
    sheetId: sheet.name,
    range: used?.address ?? "A1:Z100",
    maxChars: 30000,
    tableMaxRows: 200,
    tableMaxCols: 40,
    tableMaxCellChars: 300,
  });
  console.log(`===SHEET:${sheet.name}===`);
  console.log(region.ndjson);

  const preview = await workbook.render({
    sheetName: sheet.name,
    autoCrop: "all",
    scale: 1.5,
    format: "png",
  });
  const safeName = sheet.name.replace(/[^a-z0-9_-]+/gi, "_");
  await fs.writeFile(path.join(outputDir, `${safeName}.png`), new Uint8Array(await preview.arrayBuffer()));
}
