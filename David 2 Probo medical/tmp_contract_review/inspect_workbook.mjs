import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "C:/Users/LIKKI/Downloads/9-2 Copy of Copy of EPIQ-CPC-Probo System List.xlsx";
const outputDir = "C:/Users/LIKKI/Documents/ChatGPT/David 2 Probo medical/tmp_contract_review/xlsx_renders";

const input = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(input);
await fs.mkdir(outputDir, { recursive: true });
const summary = [];
for (const sheet of workbook.worksheets.items) {
  const used = sheet.getUsedRange();
  const values = used?.values ?? [];
  const rows = values.length;
  const cols = values.reduce((m, row) => Math.max(m, row.length), 0);
  const nonBlankRows = values.filter((row) => row.some((value) => value !== null && value !== "")).length;
  const headers = values[0] ?? [];
  const sample = values.slice(0, Math.min(rows, 6));
  const tail = values.slice(Math.max(0, rows - 3));
  summary.push({ sheet: sheet.name, usedAddress: used?.address ?? null, rows, cols, nonBlankRows, headers, sample, tail });
  const name = sheet.name.replace(/[^a-zA-Z0-9_-]+/g, "_");
  const previewRange = rows > 0 && cols > 0
    ? `A1:${String.fromCharCode(64 + Math.min(cols, 26))}${Math.min(rows, 45)}`
    : "A1";
  const preview = await workbook.render({
    sheetName: sheet.name,
    range: previewRange,
    scale: 1,
    format: "png",
  });
  await fs.writeFile(`${outputDir}/${name}.png`, new Uint8Array(await preview.arrayBuffer()));
}
await fs.writeFile("./workbook_summary.json", JSON.stringify(summary, null, 2));
console.log(JSON.stringify(summary, null, 2));
