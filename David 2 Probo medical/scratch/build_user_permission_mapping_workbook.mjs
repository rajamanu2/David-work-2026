import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const root = path.resolve("..");
const inputDir = path.join(root, "scratch", "security_access_export");
const outputDir = path.join(root, "outputs", "user_permission_set_mapping_2026-08-20");
const previewDir = path.join(root, "scratch", "user_permission_mapping_previews");
const outputPath = path.join(outputDir, "Pro_Biomedical_User_Permission_Set_Mapping_2026-08-20.xlsx");
const inspectionPath = path.join(root, "scratch", "user_permission_mapping_inspection.json");

await fs.mkdir(outputDir, { recursive: true });
await fs.mkdir(previewDir, { recursive: true });

function parseCsv(text) {
  const rows = [];
  let row = [];
  let value = "";
  let quoted = false;
  for (let i = 0; i < text.length; i += 1) {
    const ch = text[i];
    if (quoted) {
      if (ch === '"' && text[i + 1] === '"') {
        value += '"';
        i += 1;
      } else if (ch === '"') quoted = false;
      else value += ch;
    } else if (ch === '"') quoted = true;
    else if (ch === ",") {
      row.push(value);
      value = "";
    } else if (ch === "\n") {
      row.push(value.replace(/\r$/, ""));
      if (row.some((cell) => cell !== "")) rows.push(row);
      row = [];
      value = "";
    } else value += ch;
  }
  if (value.length || row.length) {
    row.push(value.replace(/\r$/, ""));
    if (row.some((cell) => cell !== "")) rows.push(row);
  }
  if (rows[0]?.[0]?.charCodeAt(0) === 0xfeff) rows[0][0] = rows[0][0].slice(1);
  return rows;
}

async function readTable(name) {
  const text = await fs.readFile(path.join(inputDir, `${name}.csv`), "utf8");
  const rows = parseCsv(text);
  return { headers: rows[0] ?? [], rows: rows.slice(1) };
}

async function readObjects(name) {
  const table = await readTable(name);
  return table.rows.map((row) => Object.fromEntries(table.headers.map((header, index) => [header, row[index] ?? ""])));
}

const bool = (value) => String(value).toLowerCase() === "true";
const dateValue = (value) => {
  if (!value) return null;
  const normalized = value.replace(/([+-]\d{2})(\d{2})$/, "$1:$2");
  const parsed = new Date(normalized);
  return Number.isNaN(parsed.getTime()) ? value : parsed;
};
const displayPermissionName = (apiName) => apiName
  .replace(/^Permissions/, "")
  .replace(/([a-z0-9])([A-Z])/g, "$1 $2")
  .replace(/([A-Z]+)([A-Z][a-z])/g, "$1 $2");
const addToListMap = (map, key, value) => {
  if (!map.has(key)) map.set(key, []);
  map.get(key).push(value);
};

const [users, userLogins, assignments, permissionSets, fieldSummary] = await Promise.all([
  readObjects("users"),
  readObjects("user_login"),
  readObjects("permission_set_assignments"),
  readObjects("permission_sets"),
  readObjects("field_permission_summary"),
]);

const permissionSetById = new Map(permissionSets.map((record) => [record.Id, record]));
const loginByUserId = new Map(userLogins.map((record) => [record.UserId, record]));
const assignmentsByUser = new Map();
for (const assignment of assignments) addToListMap(assignmentsByUser, assignment.AssigneeId, assignment);

const assignmentType = (record) => {
  if (bool(record["PermissionSet.IsOwnedByProfile"])) return "Profile Backing Permission Set";
  if (record.PermissionSetGroupId) return "Permission Set Group";
  return "Direct Permission Set";
};

const systemPermissionsByPs = new Map();
const systemPermissionCountByPs = new Map();
const highRiskApiNames = new Set([
  "PermissionsModifyAllData", "PermissionsManageUsers", "PermissionsManageProfilesPermissionsets",
  "PermissionsModifyMetadata", "PermissionsAuthorApex", "PermissionsAssignPermissionSets",
  "PermissionsManageInternalUsers", "PermissionsManageEncryptionKeys", "PermissionsManageSandboxes",
  "PermissionsCustomizeApplication", "PermissionsManageRoles", "PermissionsManageSharing",
  "PermissionsViewAllData", "PermissionsManagePasswordPolicies", "PermissionsManageConnectedApps",
  "PermissionsManageAuthProviders", "PermissionsBulkApiHardDelete", "PermissionsResetPasswords",
  "PermissionsDataExport", "PermissionsEditReadonlyFields",
]);

const systemChunkFiles = (await fs.readdir(inputDir)).filter((name) => /^system_permissions_\d+\.csv$/i.test(name)).sort();
for (const fileName of systemChunkFiles) {
  const table = await readTable(fileName.replace(/\.csv$/i, ""));
  const idIndex = table.headers.indexOf("Id");
  const permissionIndexes = table.headers.map((header, index) => ({ header, index })).filter(({ header }) => header.startsWith("Permissions"));
  for (const row of table.rows) {
    const psId = row[idIndex];
    for (const { header, index } of permissionIndexes) {
      if (!bool(row[index])) continue;
      addToListMap(systemPermissionsByPs, psId, header);
      systemPermissionCountByPs.set(psId, (systemPermissionCountByPs.get(psId) ?? 0) + 1);
    }
  }
}

const objectCountByPs = new Map();
const objectActionCountsByPs = new Map();
{
  const table = await readTable("object_permissions_rest");
  const idx = Object.fromEntries(table.headers.map((header, index) => [header, index]));
  for (const row of table.rows) {
    const psId = row[idx.ParentId];
    objectCountByPs.set(psId, (objectCountByPs.get(psId) ?? 0) + 1);
    if (!objectActionCountsByPs.has(psId)) objectActionCountsByPs.set(psId, { read: 0, create: 0, edit: 0, delete: 0, viewAll: 0, modifyAll: 0 });
    const counts = objectActionCountsByPs.get(psId);
    if (bool(row[idx.PermissionsRead])) counts.read += 1;
    if (bool(row[idx.PermissionsCreate])) counts.create += 1;
    if (bool(row[idx.PermissionsEdit])) counts.edit += 1;
    if (bool(row[idx.PermissionsDelete])) counts.delete += 1;
    if (bool(row[idx.PermissionsViewAllRecords])) counts.viewAll += 1;
    if (bool(row[idx.PermissionsModifyAllRecords])) counts.modifyAll += 1;
  }
}

const fieldCountByPs = new Map();
for (const record of fieldSummary) fieldCountByPs.set(record.ParentId, (fieldCountByPs.get(record.ParentId) ?? 0) + Number(record.Total || 0));

const setupCountByPs = new Map();
{
  const table = await readTable("setup_entity_access_rest");
  const parentIndex = table.headers.indexOf("ParentId");
  for (const row of table.rows) setupCountByPs.set(row[parentIndex], (setupCountByPs.get(row[parentIndex]) ?? 0) + 1);
}

const tabCountByPs = new Map();
{
  const table = await readTable("tab_settings_reconciled");
  const parentIndex = table.headers.indexOf("ParentId");
  for (const row of table.rows) tabCountByPs.set(row[parentIndex], (tabCountByPs.get(row[parentIndex]) ?? 0) + 1);
}

const userRows = users.map((user) => {
  const userAssignments = assignmentsByUser.get(user.Id) ?? [];
  const direct = userAssignments.filter((record) => assignmentType(record) === "Direct Permission Set");
  const groups = userAssignments.filter((record) => assignmentType(record) === "Permission Set Group");
  const profileBacking = userAssignments.filter((record) => assignmentType(record) === "Profile Backing Permission Set");
  const login = loginByUserId.get(user.Id) ?? {};
  const names = (records, labelField, nameField) => [...new Set(records.map((record) => record[labelField] || record[nameField]).filter(Boolean))].sort().join("; ");
  return [
    user.Id, user.Username, user.Name, user.Email, bool(user.IsActive), user.UserType,
    user["Profile.UserLicense.Name"], user.ProfileId, user["Profile.Name"], user.UserRoleId,
    user["UserRole.Name"], user.ManagerId, user["Manager.Name"], user.Department, user.Division,
    user.Title, user.CompanyName, user.TimeZoneSidKey, user.FederationIdentifier,
    dateValue(user.CreatedDate), dateValue(user.LastLoginDate), dateValue(user.LastModifiedDate),
    login.Id ? bool(login.IsFrozen) : null, login.Id ? bool(login.IsPasswordLocked) : null,
    null, names(direct, "PermissionSet.Label", "PermissionSet.Name"), null,
    names(groups, "PermissionSetGroup.MasterLabel", "PermissionSetGroup.DeveloperName"),
    names(profileBacking, "PermissionSet.Label", "PermissionSet.Name"), null,
    `https://probomedical.my.salesforce.com/${user.Id}`,
  ];
});

const permissionSetRows = permissionSets.map((ps) => {
  const objectCounts = objectActionCountsByPs.get(ps.Id) ?? { read: 0, create: 0, edit: 0, delete: 0, viewAll: 0, modifyAll: 0 };
  const systemPermissions = [...(systemPermissionsByPs.get(ps.Id) ?? [])].sort();
  const highRisk = systemPermissions.filter((name) => highRiskApiNames.has(name)).map(displayPermissionName);
  return [
    ps.Id, ps.Name, ps.Label, ps.Description, bool(ps.IsOwnedByProfile), ps.ProfileId, ps["Profile.Name"],
    bool(ps.IsCustom), ps.Type, ps.NamespacePrefix, bool(ps.HasActivationRequired),
    null, null, null, null, null,
    systemPermissionCountByPs.get(ps.Id) ?? 0, highRisk.join("; "), systemPermissions.map(displayPermissionName).join("; "),
    objectCountByPs.get(ps.Id) ?? 0, objectCounts.read, objectCounts.create, objectCounts.edit, objectCounts.delete,
    objectCounts.viewAll, objectCounts.modifyAll, fieldCountByPs.get(ps.Id) ?? 0,
    setupCountByPs.get(ps.Id) ?? 0, tabCountByPs.get(ps.Id) ?? 0,
    dateValue(ps.CreatedDate), dateValue(ps.LastModifiedDate),
    `https://probomedical.my.salesforce.com/${ps.Id}`,
  ];
});

const sourceCounts = { users: userRows.length, assignments: assignments.length, permissionSets: permissionSetRows.length };
const csvCell = (value) => {
  const normalized = value instanceof Date ? value.toISOString().replace("T", " ").replace(".000Z", " UTC") : value ?? "";
  const text = String(normalized);
  return `"${text.replace(/"/g, '""')}"`;
};
const writeCompactRows = async (fileName, rows, columnCount) => {
  const header = Array.from({ length: columnCount }, (_, index) => `C${index + 1}`).map(csvCell).join(",");
  const body = rows.map((row) => Array.from({ length: columnCount }, (_, index) => csvCell(row[index])).join(",")).join("\n");
  await fs.writeFile(path.join(inputDir, fileName), `${header}\n${body}\n`, "utf8");
};
await writeCompactRows("user_mapping_users_rows.csv", userRows, 31);
await writeCompactRows("permission_set_detail_rows.csv", permissionSetRows, 32);
users.length = 0;
userLogins.length = 0;
assignments.length = 0;
permissionSets.length = 0;
fieldSummary.length = 0;
permissionSetById.clear();
loginByUserId.clear();
assignmentsByUser.clear();
systemPermissionsByPs.clear();
systemPermissionCountByPs.clear();
objectCountByPs.clear();
objectActionCountsByPs.clear();
fieldCountByPs.clear();
setupCountByPs.clear();
tabCountByPs.clear();
userRows.length = 0;
permissionSetRows.length = 0;
if (global.gc) global.gc();

const workbook = Workbook.create();
const theme = { navy: "#17324D", teal: "#0F766E", light: "#EAF2F8", border: "#D7E0EA", text: "#172B4D", inactive: "#FEE2E2" };
const clean = (value) => (value === undefined ? null : value);
const colName = (index) => {
  let value = index + 1;
  let result = "";
  while (value > 0) {
    const remainder = (value - 1) % 26;
    result = String.fromCharCode(65 + remainder) + result;
    value = Math.floor((value - 1) / 26);
  }
  return result;
};

function writeRows(sheet, rows, columnCount, chunkSize = 10000) {
  for (let offset = 0; offset < rows.length; offset += chunkSize) {
    const chunk = rows.slice(offset, offset + chunkSize).map((row) => Array.from({ length: columnCount }, (_, index) => clean(row[index])));
    sheet.getRangeByIndexes(offset + 1, 0, chunk.length, columnCount).values = chunk;
  }
}

function addSheet(name, headers, rows, tableName, widths, useTable = true) {
  const sheet = workbook.worksheets.add(name);
  sheet.showGridLines = false;
  const lastColumn = colName(headers.length - 1);
  const lastRow = rows.length + 1;
  sheet.getRange(`A1:${lastColumn}1`).values = [headers];
  writeRows(sheet, rows, headers.length);
  const header = sheet.getRange(`A1:${lastColumn}1`);
  header.format.fill = theme.navy;
  header.format.font = { name: "Aptos Display", size: 10, bold: true, color: "#FFFFFF" };
  header.format.rowHeight = 32;
  header.format.wrapText = true;
  sheet.freezePanes.freezeRows(1);
  sheet.freezePanes.freezeColumns(name === "User Permission Sets" ? 5 : 3);
  if (useTable) {
    const table = sheet.tables.add(`A1:${lastColumn}${lastRow}`, true, tableName);
    table.style = "TableStyleMedium2";
    table.showFilterButton = true;
    table.showBandedRows = true;
  }
  headers.forEach((_, columnIndex) => sheet.getRange(`${colName(columnIndex)}1`).format.columnWidth = 20);
  widths.forEach(([columnIndex, width]) => sheet.getRange(`${colName(columnIndex)}1`).format.columnWidth = width);
  return { sheet, lastRow, lastColumn };
}

const userHeaders = [
  "User ID", "Username", "Name", "Email", "Active", "User Type", "User License", "Profile ID", "Profile",
  "Role ID", "Role", "Manager ID", "Manager", "Department", "Division", "Title", "Company", "Time Zone",
  "Federation Identifier", "Created (UTC)", "Last Login (UTC)", "Last Modified (UTC)", "Frozen", "Password Locked",
  "Direct Permission Set Count", "Direct Permission Sets", "Permission Set Group Count", "Permission Set Groups",
  "Profile Backing Permission Set", "Total Assignment Rows", "Salesforce URL",
];
const usersSheet = addSheet("Users", userHeaders, [], "UsersTable", [[1, 38], [2, 28], [3, 38], [8, 28], [10, 26], [12, 26], [15, 28], [18, 34], [25, 70], [27, 55], [28, 45], [30, 55]], false);

const assignmentHeaders = [
  "Assignment ID", "Assignment Type", "User ID", "Username", "User Name", "User Active", "Permission Set ID",
  "Permission Set API Name", "Permission Set Label", "Owned by Profile", "Permission Set Group ID",
  "Permission Set Group API Name", "Permission Set Group Label", "Assignment Active", "Expiration Date",
];
const assignmentSheet = addSheet("User Permission Sets", assignmentHeaders, [], "UserPermissionSetsTable", [[1, 32], [3, 38], [4, 28], [7, 36], [8, 42], [11, 38], [12, 40]], false);

const permissionSetHeaders = [
  "Permission Set ID", "API Name", "Label", "Description", "Owned by Profile", "Profile ID", "Profile", "Custom",
  "Type", "Namespace", "Activation Required", "Assigned User Rows", "Active Assigned Users", "Direct User Assignments",
  "Group Assignment Rows", "Profile Assignment Rows", "System Permission Count", "High-Risk System Permissions",
  "All System Permissions", "Object Permission Rows", "Readable Objects", "Creatable Objects", "Editable Objects",
  "Deletable Objects", "View All Objects", "Modify All Objects", "Field Permission Rows", "Setup Access Rows",
  "Tab Settings", "Created (UTC)", "Last Modified (UTC)", "Salesforce URL",
];
const detailsSheet = addSheet("Permission Set Details", permissionSetHeaders, [], "PermissionSetDetailsTable", [[1, 36], [2, 40], [3, 65], [6, 28], [17, 65], [18, 80], [31, 55]], false);

const assignmentEnd = sourceCounts.assignments + 1;
if (userRows.length) {
  usersSheet.sheet.getRange("Y2").formulas = [[`=COUNTIFS('User Permission Sets'!$C$2:$C$${assignmentEnd},A2,'User Permission Sets'!$B$2:$B$${assignmentEnd},"Direct Permission Set")`]];
  usersSheet.sheet.getRange(`Y2:Y${usersSheet.lastRow}`).fillDown();
  usersSheet.sheet.getRange("AA2").formulas = [[`=COUNTIFS('User Permission Sets'!$C$2:$C$${assignmentEnd},A2,'User Permission Sets'!$B$2:$B$${assignmentEnd},"Permission Set Group")`]];
  usersSheet.sheet.getRange(`AA2:AA${usersSheet.lastRow}`).fillDown();
  usersSheet.sheet.getRange("AD2").formulas = [[`=COUNTIF('User Permission Sets'!$C$2:$C$${assignmentEnd},A2)`]];
  usersSheet.sheet.getRange(`AD2:AD${usersSheet.lastRow}`).fillDown();
  usersSheet.sheet.getRange(`E2:E${usersSheet.lastRow}`).conditionalFormats.add("cellIs", { operator: "equal", formula: false, format: { fill: theme.inactive, font: { color: "#991B1B" } } });
}

if (permissionSetRows.length) {
  const end = detailsSheet.lastRow;
  detailsSheet.sheet.getRange("L2").formulas = [[`=COUNTIF('User Permission Sets'!$G$2:$G$${assignmentEnd},A2)`]];
  detailsSheet.sheet.getRange(`L2:L${end}`).fillDown();
  detailsSheet.sheet.getRange("M2").formulas = [[`=COUNTIFS('User Permission Sets'!$G$2:$G$${assignmentEnd},A2,'User Permission Sets'!$F$2:$F$${assignmentEnd},TRUE)`]];
  detailsSheet.sheet.getRange(`M2:M${end}`).fillDown();
  detailsSheet.sheet.getRange("N2").formulas = [[`=COUNTIFS('User Permission Sets'!$G$2:$G$${assignmentEnd},A2,'User Permission Sets'!$B$2:$B$${assignmentEnd},"Direct Permission Set")`]];
  detailsSheet.sheet.getRange(`N2:N${end}`).fillDown();
  detailsSheet.sheet.getRange("O2").formulas = [[`=COUNTIFS('User Permission Sets'!$G$2:$G$${assignmentEnd},A2,'User Permission Sets'!$B$2:$B$${assignmentEnd},"Permission Set Group")`]];
  detailsSheet.sheet.getRange(`O2:O${end}`).fillDown();
  detailsSheet.sheet.getRange("P2").formulas = [[`=COUNTIFS('User Permission Sets'!$G$2:$G$${assignmentEnd},A2,'User Permission Sets'!$B$2:$B$${assignmentEnd},"Profile Backing Permission Set")`]];
  detailsSheet.sheet.getRange(`P2:P${end}`).fillDown();
}

const inspections = {
  sheets: await workbook.inspect({ kind: "sheet", include: "id,name", maxChars: 3000 }),
  users: await workbook.inspect({ kind: "table", range: "Users!A1:AE7", include: "values,formulas", tableMaxRows: 7, tableMaxCols: 31, tableMaxCellChars: 100 }),
  assignments: await workbook.inspect({ kind: "table", range: "'User Permission Sets'!A1:O7", include: "values,formulas", tableMaxRows: 7, tableMaxCols: 15, tableMaxCellChars: 100 }),
  details: await workbook.inspect({ kind: "table", range: "'Permission Set Details'!A1:AF7", include: "values,formulas", tableMaxRows: 7, tableMaxCols: 32, tableMaxCellChars: 100 }),
  formulaErrors: await workbook.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A", options: { useRegex: true, maxResults: 100 } }),
  counts: sourceCounts,
};

const previews = [
  ["users_left", "Users", "A1:P12"],
  ["users_right", "Users", "Q1:AE12"],
  ["user_permission_sets", "User Permission Sets", "A1:O15"],
  ["permission_set_details_left", "Permission Set Details", "A1:P12"],
  ["permission_set_details_right", "Permission Set Details", "Q1:AF12"],
];
for (const [fileName, sheetName, range] of previews) {
  const preview = await workbook.render({ sheetName, range, scale: 0.8, format: "png" });
  await fs.writeFile(path.join(previewDir, `${fileName}.png`), new Uint8Array(await preview.arrayBuffer()));
}

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
await fs.writeFile(inspectionPath, JSON.stringify(inspections, null, 2), "utf8");
console.log(JSON.stringify({ outputPath, previewDir, inspectionPath, counts: inspections.counts }, null, 2));
