import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(process.argv[2]));
const sheet = workbook.worksheets.getItem("Open Cases");
const summaryRange = sheet.getRange("A4:Q5");
const table = await workbook.inspect({ kind: "table", sheetId: "Open Cases", range: "A7:S123", include: "values,formulas", tableMaxRows: 5, tableMaxCols: 19, maxChars: 10000 });
const errors = await workbook.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A", options: { useRegex: true, maxResults: 300 }, summary: "final formula error scan" });
console.log(JSON.stringify({ summaryValues: summaryRange.values, summaryFormulas: summaryRange.formulas }));
console.log(table.ndjson);
console.log(errors.ndjson);
