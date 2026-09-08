import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const root = path.resolve("..");
const inputDir = path.join(root, "scratch", "security_access_export");
const outputDir = path.join(root, "outputs", "security_access_review_2026-08-19");
const outputPath = path.join(outputDir, "Pro_Biomedical_Detailed_User_Permission_Risk_Review_2026-08-19.xlsx");
const previewDir = path.join(root, "scratch", "security_access_previews");
const inspectionPath = path.join(root, "scratch", "security_access_workbook_inspection.json");

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
  return rows;
}

async function readCsvTable(name, optional = false) {
  try {
    const text = await fs.readFile(path.join(inputDir, `${name}.csv`), "utf8");
    const rows = parseCsv(text);
    return { headers: rows.shift() ?? [], rows };
  } catch (error) {
    if (optional && error.code === "ENOENT") return { headers: [], rows: [] };
    throw error;
  }
}

function tableObjects(table) {
  return table.rows.map((row) => Object.fromEntries(table.headers.map((header, index) => [header, row[index] ?? ""])));
}

async function readCsvObjects(name, optional = false) {
  return tableObjects(await readCsvTable(name, optional));
}

const [
  organization,
  users,
  userLogin,
  profiles,
  roles,
  permissionSets,
  permissionSetAssignments,
  permissionSetGroups,
  permissionSetGroupComponents,
  systemPermissionFields,
  objectPermissionTable,
  fieldPermissionSummaryRows,
  setupEntityTable,
  tabSettingTable,
  apexClasses,
  apexPages,
  customPermissions,
  flowDefinitions,
  connectedApplications,
  entityDefinitions,
  appDefinitions,
] = await Promise.all([
  readCsvObjects("organization"),
  readCsvObjects("users"),
  readCsvObjects("user_login"),
  readCsvObjects("profiles"),
  readCsvObjects("roles"),
  readCsvObjects("permission_sets"),
  readCsvObjects("permission_set_assignments"),
  readCsvObjects("permission_set_groups"),
  readCsvObjects("permission_set_group_components"),
  readCsvObjects("system_permission_fields"),
  readCsvTable("object_permissions_rest"),
  readCsvObjects("field_permission_summary"),
  readCsvTable("setup_entity_access_rest"),
  readCsvTable("tab_settings_reconciled"),
  readCsvObjects("apex_classes", true),
  readCsvObjects("apex_pages", true),
  readCsvObjects("custom_permissions", true),
  readCsvObjects("flow_definitions", true),
  readCsvObjects("connected_applications", true),
  readCsvObjects("entity_definitions", true),
  readCsvObjects("app_definitions", true),
]);

const bool = (value) => String(value).toLowerCase() === "true";
const clean = (value) => (value === undefined || value === null ? "" : value);
const dateText = (value) => (value ? value.replace("T", " ").replace(/\.000\+0000$/, " UTC") : "");
const byId = (records, key = "Id") => new Map(records.map((record) => [record[key], record]));
const userById = byId(users);
const profileById = byId(profiles);
const roleById = byId(roles);
const permissionSetById = byId(permissionSets);
const loginByUserId = new Map(userLogin.map((record) => [record.UserId, record]));

function displayPermissionName(apiName) {
  return apiName
    .replace(/^Permissions/, "")
    .replace(/([a-z0-9])([A-Z])/g, "$1 $2")
    .replace(/([A-Z]+)([A-Z][a-z])/g, "$1 $2")
    .trim();
}

function addToMapList(map, key, value) {
  if (!map.has(key)) map.set(key, []);
  map.get(key).push(value);
}

function assignmentType(record) {
  if (record.PermissionSetGroupId) return "Permission Set Group";
  if (bool(record["PermissionSet.IsOwnedByProfile"])) return "Profile Backing Permission Set";
  return "Direct Permission Set";
}

const assignmentsByUser = new Map();
for (const assignment of permissionSetAssignments) addToMapList(assignmentsByUser, assignment.AssigneeId, assignment);

const assignedUserCountByPs = new Map();
for (const assignment of permissionSetAssignments) {
  assignedUserCountByPs.set(assignment.PermissionSetId, (assignedUserCountByPs.get(assignment.PermissionSetId) ?? 0) + 1);
}

const systemChunkFiles = (await fs.readdir(inputDir))
  .filter((name) => /^system_permissions_\d+\.csv$/i.test(name))
  .sort();
const systemGrantsByPs = new Map();
const systemGrantRows = [];
const systemGrantCountByPs = new Map();
const systemGrantCountByPermission = new Map();
for (const fileName of systemChunkFiles) {
  const table = await readCsvTable(fileName.replace(/\.csv$/i, ""));
  const fieldIndexes = table.headers
    .map((header, index) => ({ header, index }))
    .filter(({ header }) => header.startsWith("Permissions"));
  const idIndex = table.headers.indexOf("Id");
  const nameIndex = table.headers.indexOf("Name");
  const labelIndex = table.headers.indexOf("Label");
  const ownedIndex = table.headers.indexOf("IsOwnedByProfile");
  for (const row of table.rows) {
    const psId = row[idIndex];
    const psName = row[nameIndex];
    const psLabel = row[labelIndex];
    const owned = bool(row[ownedIndex]);
    for (const { header, index } of fieldIndexes) {
      if (!bool(row[index])) continue;
      const grant = { psId, psName, psLabel, owned, permission: header };
      addToMapList(systemGrantsByPs, psId, grant);
      systemGrantRows.push([psId, psName, psLabel, owned, permissionSetById.get(psId)?.ProfileId ?? "", permissionSetById.get(psId)?.["Profile.Name"] ?? "", header, displayPermissionName(header)]);
      systemGrantCountByPs.set(psId, (systemGrantCountByPs.get(psId) ?? 0) + 1);
      systemGrantCountByPermission.set(header, (systemGrantCountByPermission.get(header) ?? 0) + 1);
    }
  }
}

const riskRules = [
  ["PermissionsModifyAllData", "System Permission", "Modify All Data", "Critical", 100, "Can create, edit, and delete all organizational data and bypass record-level controls."],
  ["PermissionsManageUsers", "System Permission", "Manage Users", "Critical", 80, "Can create, deactivate, unlock, and administer users."],
  ["PermissionsManageProfilesPermissionsets", "System Permission", "Manage Profiles and Permission Sets", "Critical", 80, "Can change access models and grant further permissions."],
  ["PermissionsModifyMetadata", "System Permission", "Modify Metadata", "Critical", 80, "Can change configuration and metadata through supported APIs."],
  ["PermissionsAuthorApex", "System Permission", "Author Apex", "Critical", 70, "Can create or modify executable Salesforce code."],
  ["PermissionsAssignPermissionSets", "System Permission", "Assign Permission Sets", "Critical", 70, "Can grant additional access to users."],
  ["PermissionsManageInternalUsers", "System Permission", "Manage Internal Users", "Critical", 70, "Can administer internal user accounts."],
  ["PermissionsManageEncryptionKeys", "System Permission", "Manage Encryption Keys", "Critical", 70, "Can manage encryption material and protected-data controls."],
  ["PermissionsManageSandboxes", "System Permission", "Manage Sandboxes", "Critical", 70, "Can create, refresh, and administer sandbox environments."],
  ["PermissionsCustomizeApplication", "System Permission", "Customize Application", "High", 60, "Can change configuration that affects applications and users."],
  ["PermissionsManageRoles", "System Permission", "Manage Roles", "High", 60, "Can change role hierarchy and record access inheritance."],
  ["PermissionsManageSharing", "System Permission", "Manage Sharing", "High", 60, "Can alter sharing rules and record access."],
  ["PermissionsManagePasswordPolicies", "System Permission", "Manage Password Policies", "High", 60, "Can change organization-wide authentication policy."],
  ["PermissionsViewAllData", "System Permission", "View All Data", "High", 50, "Can read all organizational data regardless of sharing."],
  ["PermissionsViewEncryptedData", "System Permission", "View Encrypted Data", "High", 50, "Can view encrypted information where supported."],
  ["PermissionsManageCertificates", "System Permission", "Manage Certificates", "High", 50, "Can administer certificates used for integrations and identity."],
  ["PermissionsManageConnectedApps", "System Permission", "Manage Connected Apps", "High", 50, "Can administer application integrations and OAuth access."],
  ["PermissionsManageAuthProviders", "System Permission", "Manage Auth Providers", "High", 50, "Can change external authentication configuration."],
  ["PermissionsManageLoginAccessPolicies", "System Permission", "Manage Login Access Policies", "High", 50, "Can change policies governing administrative login access."],
  ["PermissionsManageSessionPermissionSets", "System Permission", "Manage Session Permission Sets", "High", 50, "Can administer session-based elevated access."],
  ["PermissionsManageTwoFactor", "System Permission", "Manage Two-Factor Authentication", "High", 50, "Can administer multi-factor authentication settings."],
  ["PermissionsBulkApiHardDelete", "System Permission", "Bulk API Hard Delete", "High", 50, "Can permanently delete data through Bulk API."],
  ["PermissionsResetPasswords", "System Permission", "Reset User Passwords", "High", 40, "Can reset user credentials."],
  ["PermissionsDataExport", "System Permission", "Data Export", "High", 40, "Can export broad organizational datasets."],
  ["PermissionsEditReadonlyFields", "System Permission", "Edit Read-Only Fields", "High", 40, "Can modify otherwise protected audit or read-only fields."],
  ["PermissionsManageIPAddresses", "System Permission", "Manage IP Addresses", "High", 40, "Can change trusted network controls."],
  ["PermissionsPasswordNeverExpires", "System Permission", "Password Never Expires", "Medium", 30, "Weakens credential-expiration controls for the user."],
  ["PermissionsTransferAnyEntity", "System Permission", "Transfer Any Record", "Medium", 30, "Can transfer ownership across broad record types."],
  ["PermissionsViewAllUsers", "System Permission", "View All Users", "Medium", 20, "Can view all user records and related identity details."],
  ["PermissionsApiEnabled", "System Permission", "API Enabled", "Medium", 15, "Allows programmatic API access; validate integration or job need."],
  ["PermissionsViewSetup", "System Permission", "View Setup and Configuration", "Low", 10, "Allows visibility into configuration and security setup."],
  ["OBJECT_MODIFY_ALL", "Object Permission", "Modify All Records on an object", "Critical", 15, "Bypasses sharing and grants full control for one object."],
  ["OBJECT_VIEW_ALL", "Object Permission", "View All Records on an object", "High", 6, "Bypasses sharing and grants read access for one object."],
];
const riskRuleByKey = new Map(riskRules.map((row) => [row[0], { key: row[0], type: row[1], label: row[2], severity: row[3], weight: row[4], rationale: row[5] }]));

const effectiveSystemRows = [];
const effectiveSystemByUser = new Map();
for (const user of users) {
  const permissionSources = new Map();
  for (const assignment of assignmentsByUser.get(user.Id) ?? []) {
    const ps = permissionSetById.get(assignment.PermissionSetId);
    const sourceName = ps?.Label || ps?.Name || assignment.PermissionSetId;
    for (const grant of systemGrantsByPs.get(assignment.PermissionSetId) ?? []) {
      if (!permissionSources.has(grant.permission)) permissionSources.set(grant.permission, new Set());
      permissionSources.get(grant.permission).add(sourceName);
    }
  }
  effectiveSystemByUser.set(user.Id, permissionSources);
}

function indexes(table) {
  return Object.fromEntries(table.headers.map((header, index) => [header, index]));
}
const objectIdx = indexes(objectPermissionTable);
const objectGrantsByPs = new Map();
const objectPermissionCountByPs = new Map();
for (const row of objectPermissionTable.rows) {
  const grant = {
    id: row[objectIdx.Id],
    parentId: row[objectIdx.ParentId],
    object: row[objectIdx.SobjectType],
    read: bool(row[objectIdx.PermissionsRead]),
    create: bool(row[objectIdx.PermissionsCreate]),
    edit: bool(row[objectIdx.PermissionsEdit]),
    delete: bool(row[objectIdx.PermissionsDelete]),
    viewAll: bool(row[objectIdx.PermissionsViewAllRecords]),
    modifyAll: bool(row[objectIdx.PermissionsModifyAllRecords]),
  };
  addToMapList(objectGrantsByPs, grant.parentId, grant);
  objectPermissionCountByPs.set(grant.parentId, (objectPermissionCountByPs.get(grant.parentId) ?? 0) + 1);
}

const effectiveObjectRows = [];
const effectiveObjectByUser = new Map();
for (const user of users) {
  const objectMap = new Map();
  for (const assignment of assignmentsByUser.get(user.Id) ?? []) {
    const ps = permissionSetById.get(assignment.PermissionSetId);
    const sourceName = ps?.Label || ps?.Name || assignment.PermissionSetId;
    for (const grant of objectGrantsByPs.get(assignment.PermissionSetId) ?? []) {
      if (!objectMap.has(grant.object)) {
        objectMap.set(grant.object, { read: false, create: false, edit: false, delete: false, viewAll: false, modifyAll: false, sources: new Set() });
      }
      const target = objectMap.get(grant.object);
      target.read ||= grant.read;
      target.create ||= grant.create;
      target.edit ||= grant.edit;
      target.delete ||= grant.delete;
      target.viewAll ||= grant.viewAll;
      target.modifyAll ||= grant.modifyAll;
      target.sources.add(sourceName);
    }
  }
  effectiveObjectByUser.set(user.Id, objectMap);
}

const riskHitRows = [];
const riskReasonsByUser = new Map();
const estimatedScoreByUser = new Map();
const modifyAllCountByUser = new Map();
const viewAllCountByUser = new Map();
for (const user of users) {
  const reasons = [];
  let estimatedScore = 0;
  for (const [permission, sources] of effectiveSystemByUser.get(user.Id) ?? []) {
    const rule = riskRuleByKey.get(permission);
    if (!rule) continue;
    riskHitRows.push([user.Id, user.Username, user.Name, bool(user.IsActive), "System Permission", rule.label, permission, "", "", [...sources].sort().join("; "), rule.rationale]);
    reasons.push(`${rule.severity}: ${rule.label}`);
    estimatedScore += rule.weight;
  }
  const modifyAllObjects = [];
  const viewAllObjects = [];
  const modifyAllSources = new Set();
  const viewAllSources = new Set();
  for (const [objectName, grant] of effectiveObjectByUser.get(user.Id) ?? []) {
    if (grant.modifyAll) {
      const rule = riskRuleByKey.get("OBJECT_MODIFY_ALL");
      modifyAllObjects.push(objectName);
      for (const source of grant.sources) modifyAllSources.add(source);
      estimatedScore += rule.weight;
    } else if (grant.viewAll) {
      const rule = riskRuleByKey.get("OBJECT_VIEW_ALL");
      viewAllObjects.push(objectName);
      for (const source of grant.sources) viewAllSources.add(source);
      estimatedScore += rule.weight;
    }
  }
  modifyAllCountByUser.set(user.Id, modifyAllObjects.length);
  viewAllCountByUser.set(user.Id, viewAllObjects.length);
  if (modifyAllObjects.length) {
    const rule = riskRuleByKey.get("OBJECT_MODIFY_ALL");
    riskHitRows.push([user.Id, user.Username, user.Name, bool(user.IsActive), "Object Permission", `Modify All: ${modifyAllObjects.length} objects`, "OBJECT_MODIFY_ALL", "", "", [...modifyAllSources].sort().join("; "), `${rule.rationale} Objects: ${modifyAllObjects.sort().join("; ")}`]);
    reasons.push(`Critical: Modify All on ${modifyAllObjects.length} objects`);
  }
  if (viewAllObjects.length) {
    const rule = riskRuleByKey.get("OBJECT_VIEW_ALL");
    riskHitRows.push([user.Id, user.Username, user.Name, bool(user.IsActive), "Object Permission", `View All: ${viewAllObjects.length} objects`, "OBJECT_VIEW_ALL", "", "", [...viewAllSources].sort().join("; "), `${rule.rationale} Objects: ${viewAllObjects.sort().join("; ")}`]);
    reasons.push(`High: View All on ${viewAllObjects.length} objects`);
  }
  riskReasonsByUser.set(user.Id, reasons.slice(0, 12).join("; "));
  estimatedScoreByUser.set(user.Id, estimatedScore);
}
riskHitRows.sort((a, b) => a[2].localeCompare(b[2]) || a[4].localeCompare(b[4]) || a[5].localeCompare(b[5]));

const profileUserCounts = new Map();
const roleUserCounts = new Map();
for (const user of users) {
  profileUserCounts.set(user.ProfileId, (profileUserCounts.get(user.ProfileId) ?? 0) + 1);
  if (user.UserRoleId) roleUserCounts.set(user.UserRoleId, (roleUserCounts.get(user.UserRoleId) ?? 0) + 1);
}

const fieldPermissionCount = fieldPermissionSummaryRows.reduce((total, row) => total + Number(row.Total || 0), 0);
const fieldPermissionCountByPs = new Map();
for (const row of fieldPermissionSummaryRows) {
  fieldPermissionCountByPs.set(row.ParentId, (fieldPermissionCountByPs.get(row.ParentId) ?? 0) + Number(row.Total || 0));
}
const setupIdx = indexes(setupEntityTable);
const setupAccessCountByPs = new Map();
for (const row of setupEntityTable.rows) {
  const parentId = row[setupIdx.ParentId];
  setupAccessCountByPs.set(parentId, (setupAccessCountByPs.get(parentId) ?? 0) + 1);
}
const tabIdx = indexes(tabSettingTable);
const tabCountByPs = new Map();
for (const row of tabSettingTable.rows) {
  const parentId = row[tabIdx.ParentId];
  tabCountByPs.set(parentId, (tabCountByPs.get(parentId) ?? 0) + 1);
}

const setupEntityNameById = new Map();
for (const record of apexClasses) setupEntityNameById.set(record.Id, record.Name);
for (const record of apexPages) setupEntityNameById.set(record.Id, record.Name);
for (const record of customPermissions) setupEntityNameById.set(record.Id, record.MasterLabel || record.DeveloperName);
for (const record of flowDefinitions) setupEntityNameById.set(record.Id, record.MasterLabel || record.DeveloperName);
for (const record of connectedApplications) setupEntityNameById.set(record.Id, record.Name);
for (const record of entityDefinitions) setupEntityNameById.set(record.DurableId, record.Label || record.QualifiedApiName);
for (const record of appDefinitions) setupEntityNameById.set(record.DurableId, record.Label || record.DeveloperName);

const userAccessOverviewRows = users.map((user) => {
  const assignments = assignmentsByUser.get(user.Id) ?? [];
  const direct = assignments.filter((record) => assignmentType(record) === "Direct Permission Set");
  const psg = assignments.filter((record) => assignmentType(record) === "Permission Set Group");
  const profileBacking = assignments.filter((record) => assignmentType(record) === "Profile Backing Permission Set");
  const names = (records, labelField, nameField) => [...new Set(records.map((record) => record[labelField] || record[nameField]).filter(Boolean))].sort().join("; ");
  return [
    user.Id,
    user.Username,
    user.Name,
    bool(user.IsActive),
    user["Profile.UserLicense.Name"],
    user["Profile.Name"],
    user["UserRole.Name"],
    user.Department,
    user.Title,
    direct.length,
    names(direct, "PermissionSet.Label", "PermissionSet.Name"),
    psg.length,
    names(psg, "PermissionSetGroup.MasterLabel", "PermissionSetGroup.DeveloperName"),
    profileBacking.length,
    names(profileBacking, "PermissionSet.Label", "PermissionSet.Name"),
    effectiveSystemByUser.get(user.Id)?.size ?? 0,
    effectiveObjectByUser.get(user.Id)?.size ?? 0,
    `https://probomedical.my.salesforce.com/${user.Id}`,
  ];
});

const usersForReview = [...users].sort((a, b) => (estimatedScoreByUser.get(b.Id) ?? 0) - (estimatedScoreByUser.get(a.Id) ?? 0) || a.Name.localeCompare(b.Name));
const userRiskReviewRows = usersForReview.map((user) => {
  const assignments = assignmentsByUser.get(user.Id) ?? [];
  const directCount = assignments.filter((record) => assignmentType(record) === "Direct Permission Set").length;
  const psgCount = assignments.filter((record) => assignmentType(record) === "Permission Set Group").length;
  return [
    user.Id,
    user.Username,
    user.Name,
    bool(user.IsActive),
    user.UserType,
    user["Profile.UserLicense.Name"],
    user["Profile.Name"],
    user["UserRole.Name"],
    user.Department,
    user.Title,
    dateText(user.LastLoginDate),
    directCount,
    psgCount,
    assignments.length,
    effectiveSystemByUser.get(user.Id)?.size ?? 0,
    effectiveObjectByUser.get(user.Id)?.size ?? 0,
    "",
    "",
    modifyAllCountByUser.get(user.Id) ?? 0,
    viewAllCountByUser.get(user.Id) ?? 0,
    "",
    "",
    riskReasonsByUser.get(user.Id) ?? "",
    "",
    "Not Reviewed",
    "",
    "",
    "",
    "",
    `https://probomedical.my.salesforce.com/${user.Id}`,
  ];
});

const systemGrantSourceCount = systemGrantRows.length;
const objectPermissionSourceCount = objectPermissionTable.rows.length;
const setupEntitySourceCount = setupEntityTable.rows.length;
const tabSettingSourceCount = tabSettingTable.rows.length;
effectiveSystemByUser.clear();
effectiveObjectByUser.clear();
assignmentsByUser.clear();
objectGrantsByPs.clear();
systemGrantsByPs.clear();
riskReasonsByUser.clear();
estimatedScoreByUser.clear();
modifyAllCountByUser.clear();
viewAllCountByUser.clear();
systemGrantRows.length = 0;
objectPermissionTable.rows = [];
setupEntityTable.rows = [];
tabSettingTable.rows = [];
fieldPermissionSummaryRows.length = 0;
if (global.gc) global.gc();

const workbook = Workbook.create();
const summary = workbook.worksheets.add("Summary");
const theme = {
  navy: "#17324D",
  blue: "#2563EB",
  teal: "#0F766E",
  light: "#F4F7FA",
  border: "#D7E0EA",
  critical: "#FEE2E2",
  criticalText: "#991B1B",
  high: "#FFEDD5",
  highText: "#9A3412",
  medium: "#FEF3C7",
  mediumText: "#92400E",
  low: "#DCFCE7",
  lowText: "#166534",
  text: "#172B4D",
};
const tableNames = new Set();

function colName(index) {
  let n = index + 1;
  let result = "";
  while (n > 0) {
    const rem = (n - 1) % 26;
    result = String.fromCharCode(65 + rem) + result;
    n = Math.floor((n - 1) / 26);
  }
  return result;
}

function safeTableName(sheetName) {
  let base = sheetName.replace(/[^A-Za-z0-9]/g, "") + "Table";
  if (!/^[A-Za-z_]/.test(base)) base = `T${base}`;
  let candidate = base;
  let suffix = 2;
  while (tableNames.has(candidate)) candidate = `${base}${suffix++}`;
  tableNames.add(candidate);
  return candidate;
}

function writeRowsInChunks(sheet, startRowIndex, rows, columnCount, chunkSize = 15000) {
  for (let offset = 0; offset < rows.length; offset += chunkSize) {
    const chunk = rows.slice(offset, offset + chunkSize).map((row) => Array.from({ length: columnCount }, (_, index) => clean(row[index])));
    if (chunk.length) sheet.getRangeByIndexes(startRowIndex + offset, 0, chunk.length, columnCount).values = chunk;
  }
}

function setColumnWidths(sheet, headers, sampleRows, wideColumns = [], wrapColumns = []) {
  headers.forEach((header, index) => {
    const maxLength = Math.max(String(header).length, ...sampleRows.slice(0, 300).map((row) => String(row[index] ?? "").length));
    const cap = wideColumns.includes(index) ? 62 : 30;
    const width = Math.min(cap, Math.max(10, maxLength + 2));
    sheet.getRange(`${colName(index)}1:${colName(index)}${Math.max(2, sampleRows.length + 1)}`).format.columnWidth = width;
  });
  for (const index of wrapColumns) sheet.getRange(`${colName(index)}1:${colName(index)}${Math.max(2, sampleRows.length + 1)}`).format.wrapText = true;
}

function addDataSheet(name, headers, rows, options = {}) {
  const sheet = workbook.worksheets.add(name);
  sheet.showGridLines = false;
  const lastCol = colName(headers.length - 1);
  sheet.getRange(`A1:${lastCol}1`).values = [headers];
  writeRowsInChunks(sheet, 1, rows, headers.length, options.chunkSize ?? 15000);
  const lastRow = rows.length + 1;
  const used = sheet.getRange(`A1:${lastCol}${lastRow}`);
  if (!options.minimalFormat) {
    used.format.font = { name: "Aptos", size: options.fontSize ?? 9, color: theme.text };
    used.format.verticalAlignment = "top";
  }
  const header = sheet.getRange(`A1:${lastCol}1`);
  header.format.fill = theme.navy;
  header.format.font = { name: "Aptos Display", size: 10, bold: true, color: "#FFFFFF" };
  header.format.rowHeight = 30;
  header.format.wrapText = true;
  header.format.borders = { preset: "outside", style: "thin", color: theme.border };
  sheet.freezePanes.freezeRows(1);
  if (options.freezeColumns) sheet.freezePanes.freezeColumns(options.freezeColumns);
  if (rows.length > 0 && options.table !== false && rows.length <= 100000) {
    const table = sheet.tables.add(`A1:${lastCol}${lastRow}`, true, safeTableName(name));
    table.style = options.tableStyle ?? "TableStyleMedium2";
    table.showFilterButton = true;
    table.showBandedRows = true;
  }
  setColumnWidths(sheet, headers, rows, options.wideColumns ?? [], options.wrapColumns ?? []);
  return { sheet, lastRow, lastCol };
}

const riskRuleRows = riskRules.map((row) => [...row, row[0].startsWith("OBJECT_") || systemPermissionFields.some((field) => field.Field === row[0])]);
const riskRulesSheet = addDataSheet("Risk Rules", ["Rule Key", "Grant Type", "Permission / Condition", "Severity", "Weight", "Why It Matters", "Present in Org", "Severity Band", "Minimum Score"], riskRuleRows.map((row, index) => [row[0], row[1], row[2], row[3], row[4], row[5], row[6], index < 4 ? ["Critical", "High", "Medium", "Low"][index] : "", index < 4 ? [100, 50, 20, 0][index] : ""]), { wideColumns: [2, 5], wrapColumns: [2, 5] });

const riskHits = addDataSheet("User Risk Hits", ["User ID", "Username", "User Name", "Active", "Grant Type", "Risk Permission / Object", "Rule Key", "Severity", "Weight", "Source Permission Sets", "Evidence / Why It Matters"], riskHitRows, { freezeColumns: 3, wideColumns: [5, 9, 10], wrapColumns: [5, 9, 10] });
if (riskHitRows.length) {
  const rulesEnd = riskRules.length + 1;
  riskHits.sheet.getRange("H2").formulas = [[`=IFERROR(VLOOKUP(G2,'Risk Rules'!$A$2:$E$${rulesEnd},4,FALSE),"Unscored")`]];
  riskHits.sheet.getRange(`H2:H${riskHits.lastRow}`).fillDown();
  riskHits.sheet.getRange("I2").formulas = [[`=IF(LEFT(G2,7)="OBJECT_",IFERROR(VLOOKUP(G2,'Risk Rules'!$A$2:$E$${rulesEnd},5,FALSE)*VALUE(MID(F2,FIND(": ",F2)+2,FIND(" objects",F2)-FIND(": ",F2)-2)),0),IFERROR(VLOOKUP(G2,'Risk Rules'!$A$2:$E$${rulesEnd},5,FALSE),0))`]];
  riskHits.sheet.getRange(`I2:I${riskHits.lastRow}`).fillDown();
}

const reviewHeaders = ["User ID", "Username", "User Name", "Active", "User Type", "User License", "Profile", "Role", "Department", "Title", "Last Login (UTC)", "Direct PS Count", "PS Group Count", "Assigned PS Rows", "Effective System Permissions", "Objects with Access", "Critical Hits", "High Hits", "Modify All Objects", "View All Objects", "Risk Score", "Risk Level", "Top Risk Reasons", "Suggested Action", "Review Status", "Decision", "Business Eligibility / Justification", "Approved By", "Review Date", "Salesforce URL"];
const review = addDataSheet("User Risk Review", reviewHeaders, userRiskReviewRows, { freezeColumns: 3, wideColumns: [22, 23, 26, 29], wrapColumns: [22, 23, 26] });
const riskHitsEnd = riskHits.lastRow;
if (userRiskReviewRows.length) {
  review.sheet.getRange("Q2").formulas = [[`=COUNTIFS('User Risk Hits'!$A$2:$A$${riskHitsEnd},A2,'User Risk Hits'!$H$2:$H$${riskHitsEnd},"Critical")`]];
  review.sheet.getRange(`Q2:Q${review.lastRow}`).fillDown();
  review.sheet.getRange("R2").formulas = [[`=COUNTIFS('User Risk Hits'!$A$2:$A$${riskHitsEnd},A2,'User Risk Hits'!$H$2:$H$${riskHitsEnd},"High")`]];
  review.sheet.getRange(`R2:R${review.lastRow}`).fillDown();
  review.sheet.getRange("U2").formulas = [[`=SUMIF('User Risk Hits'!$A$2:$A$${riskHitsEnd},A2,'User Risk Hits'!$I$2:$I$${riskHitsEnd})`]];
  review.sheet.getRange(`U2:U${review.lastRow}`).fillDown();
  review.sheet.getRange("V2").formulas = [[`=IF(U2>='Risk Rules'!$I$2,"Critical",IF(U2>='Risk Rules'!$I$3,"High",IF(U2>='Risk Rules'!$I$4,"Medium","Low")))`]];
  review.sheet.getRange(`V2:V${review.lastRow}`).fillDown();
  review.sheet.getRange("X2").formulas = [[`=IF(V2="Critical","Immediate access review",IF(V2="High","Manager and security review",IF(V2="Medium","Validate business need","Monitor or retain if justified")))`]];
  review.sheet.getRange(`X2:X${review.lastRow}`).fillDown();
  review.sheet.getRange(`Y2:Y${review.lastRow}`).dataValidation = { rule: { type: "list", values: ["Not Reviewed", "In Review", "Approved", "Action Required", "Completed"] } };
  review.sheet.getRange(`Z2:Z${review.lastRow}`).dataValidation = { rule: { type: "list", values: ["Retain", "Restrict", "Remove", "Investigate"] } };
  const riskLevelRange = review.sheet.getRange(`V2:V${review.lastRow}`);
  riskLevelRange.conditionalFormats.add("containsText", { text: "Critical", format: { fill: theme.critical, font: { color: theme.criticalText, bold: true } } });
  riskLevelRange.conditionalFormats.add("containsText", { text: "High", format: { fill: theme.high, font: { color: theme.highText, bold: true } } });
  riskLevelRange.conditionalFormats.add("containsText", { text: "Medium", format: { fill: theme.medium, font: { color: theme.mediumText } } });
  riskLevelRange.conditionalFormats.add("containsText", { text: "Low", format: { fill: theme.low, font: { color: theme.lowText } } });
}

addDataSheet("User Access Overview", ["User ID", "Username", "User Name", "Active", "User License", "Profile", "Role", "Department", "Title", "Direct PS Count", "Direct Permission Sets", "PS Group Count", "Permission Set Groups", "Profile-Backing Count", "Profile-Backing Permission Set", "Effective System Permission Count", "Object Types with Access", "Salesforce URL"], userAccessOverviewRows, { freezeColumns: 3, wideColumns: [10, 12, 14, 17], wrapColumns: [10, 12, 14] });

addDataSheet("Users", ["User ID", "Username", "Name", "Email", "Active", "User Type", "User License", "Profile ID", "Profile", "Role ID", "Role", "Manager ID", "Manager", "Department", "Division", "Title", "Company", "Time Zone", "Federation Identifier", "Created (UTC)", "Last Login (UTC)", "Last Modified (UTC)", "Frozen", "Password Locked", "Salesforce URL"], users.map((user) => {
  const login = loginByUserId.get(user.Id) ?? {};
  return [user.Id, user.Username, user.Name, user.Email, bool(user.IsActive), user.UserType, user["Profile.UserLicense.Name"], user.ProfileId, user["Profile.Name"], user.UserRoleId, user["UserRole.Name"], user.ManagerId, user["Manager.Name"], user.Department, user.Division, user.Title, user.CompanyName, user.TimeZoneSidKey, user.FederationIdentifier, dateText(user.CreatedDate), dateText(user.LastLoginDate), dateText(user.LastModifiedDate), login.Id ? bool(login.IsFrozen) : "", login.Id ? bool(login.IsPasswordLocked) : "", `https://probomedical.my.salesforce.com/${user.Id}`];
}), { freezeColumns: 3, wideColumns: [1, 2, 3, 18, 24] });

addDataSheet("Roles", ["Role ID", "Role Name", "Developer Name", "Parent Role ID", "Parent Role", "Direct Users", "Rollup Description", "Opportunity Access for Account Owner", "Case Access for Account Owner", "Contact Access for Account Owner", "Portal Type", "Forecast User ID", "May Forecast Manager Share", "Last Modified (UTC)", "Salesforce URL"], roles.map((role) => [role.Id, role.Name, role.DeveloperName, role.ParentRoleId, role["ParentRole.Name"], roleUserCounts.get(role.Id) ?? 0, role.RollupDescription, role.OpportunityAccessForAccountOwner, role.CaseAccessForAccountOwner, role.ContactAccessForAccountOwner, role.PortalType, role.ForecastUserId, bool(role.MayForecastManagerShare), dateText(role.LastModifiedDate), `https://probomedical.my.salesforce.com/${role.Id}`]), { wideColumns: [1, 6, 14], wrapColumns: [6] });

const profileBackingPsByProfile = new Map(permissionSets.filter((ps) => bool(ps.IsOwnedByProfile) && ps.ProfileId).map((ps) => [ps.ProfileId, ps]));
addDataSheet("Profiles", ["Profile ID", "Profile Name", "User License ID", "User License", "User Type", "Description", "Assigned Users", "Backing Permission Set ID", "Backing Permission Set", "System Permission Grants", "Object Permission Rows", "Field Permission Rows", "Setup Access Rows", "Tab Settings", "Created (UTC)", "Last Modified (UTC)", "Salesforce URL"], profiles.map((profile) => {
  const ps = profileBackingPsByProfile.get(profile.Id);
  return [profile.Id, profile.Name, profile.UserLicenseId, profile["UserLicense.Name"], profile.UserType, profile.Description, profileUserCounts.get(profile.Id) ?? 0, ps?.Id ?? "", ps?.Label ?? ps?.Name ?? "", ps ? systemGrantCountByPs.get(ps.Id) ?? 0 : 0, ps ? objectPermissionCountByPs.get(ps.Id) ?? 0 : 0, ps ? fieldPermissionCountByPs.get(ps.Id) ?? 0 : 0, ps ? setupAccessCountByPs.get(ps.Id) ?? 0 : 0, ps ? tabCountByPs.get(ps.Id) ?? 0 : 0, dateText(profile.CreatedDate), dateText(profile.LastModifiedDate), `https://probomedical.my.salesforce.com/${profile.Id}`];
}), { wideColumns: [1, 5, 16], wrapColumns: [5] });

addDataSheet("Permission Sets", ["Permission Set ID", "API Name", "Label", "Description", "Owned by Profile", "Profile ID", "Profile", "Custom", "Namespace", "Type", "Activation Required", "Assigned User Rows", "System Permission Grants", "Object Permission Rows", "Field Permission Rows", "Setup Access Rows", "Tab Settings", "Created (UTC)", "Last Modified (UTC)", "Salesforce URL"], permissionSets.map((ps) => [ps.Id, ps.Name, ps.Label, ps.Description, bool(ps.IsOwnedByProfile), ps.ProfileId, ps["Profile.Name"], bool(ps.IsCustom), ps.NamespacePrefix, ps.Type, bool(ps.HasActivationRequired), assignedUserCountByPs.get(ps.Id) ?? 0, systemGrantCountByPs.get(ps.Id) ?? 0, objectPermissionCountByPs.get(ps.Id) ?? 0, fieldPermissionCountByPs.get(ps.Id) ?? 0, setupAccessCountByPs.get(ps.Id) ?? 0, tabCountByPs.get(ps.Id) ?? 0, dateText(ps.CreatedDate), dateText(ps.LastModifiedDate), `https://probomedical.my.salesforce.com/${ps.Id}`]), { wideColumns: [2, 3, 19], wrapColumns: [3] });

addDataSheet("PS Assignments", ["Assignment ID", "Assignment Type", "User ID", "Username", "User Name", "User Active", "Permission Set ID", "Permission Set API Name", "Permission Set Label", "Owned by Profile", "PS Group ID", "PS Group API Name", "PS Group Label", "Assignment Active", "Expiration Date"], permissionSetAssignments.map((record) => [record.Id, assignmentType(record), record.AssigneeId, record["Assignee.Username"], record["Assignee.Name"], bool(record["Assignee.IsActive"]), record.PermissionSetId, record["PermissionSet.Name"], record["PermissionSet.Label"], bool(record["PermissionSet.IsOwnedByProfile"]), record.PermissionSetGroupId, record["PermissionSetGroup.DeveloperName"], record["PermissionSetGroup.MasterLabel"], bool(record.IsActive), record.ExpirationDate]), { freezeColumns: 5, wideColumns: [4, 8, 12] });

addDataSheet("PS Groups", ["PS Group ID", "API Name", "Label", "Description", "Status", "Activation Required", "Namespace", "Created (UTC)", "Last Modified (UTC)"], permissionSetGroups.map((record) => [record.Id, record.DeveloperName, record.MasterLabel, record.Description, record.Status, bool(record.HasActivationRequired), record.NamespacePrefix, dateText(record.CreatedDate), dateText(record.LastModifiedDate)]), { wideColumns: [2, 3], wrapColumns: [3] });
addDataSheet("PSG Components", ["Component ID", "PS Group ID", "PS Group API Name", "PS Group Label", "Permission Set ID", "Permission Set API Name", "Permission Set Label", "Permission Set Type", "Created (UTC)", "Last Modified (UTC)"], permissionSetGroupComponents.map((record) => [record.Id, record.PermissionSetGroupId, record["PermissionSetGroup.DeveloperName"], record["PermissionSetGroup.MasterLabel"], record.PermissionSetId, record["PermissionSet.Name"], record["PermissionSet.Label"], record["PermissionSet.Type"], dateText(record.CreatedDate), dateText(record.LastModifiedDate)]), { wideColumns: [3, 6] });

const catalogRows = systemPermissionFields.map((record) => {
  const rule = riskRuleByKey.get(record.Field);
  return [record.Field, displayPermissionName(record.Field), systemGrantCountByPermission.get(record.Field) ?? 0, rule?.severity ?? "", rule?.weight ?? "", rule?.rationale ?? ""];
});
addDataSheet("System Permission Catalog", ["System Permission API", "System Permission", "Permission Set Grants", "Risk Severity", "Risk Weight", "Risk Rationale"], catalogRows, { wideColumns: [1, 5], wrapColumns: [5] });

const coverageRows = [
  ["Purpose", "Security review", "Identify broad access and support a business-owner decision to retain, restrict, remove, or investigate access."],
  ["Target org", "ProboMedical production", `${organization[0]?.Name ?? "Probo Medical"} | ${organization[0]?.Id ?? ""} | ${organization[0]?.OrganizationType ?? ""}`],
  ["Salesforce activity", "Read only", "Queries and exports only. This workbook did not modify users, profiles, roles, permission sets, assignments, or metadata."],
  ["Eligibility", "Not automatically determined", "The workbook flags technical access risk. Business eligibility must be confirmed by the user's manager, system owner, and security/compliance owner."],
  ["Risk scoring", "Editable", "Weights and score thresholds are visible on Risk Rules. Change them to match Pro Biomedical policy; formulas recalculate the review sheet."],
  ["Profile permissions", "Included through backing permission sets", "Profile-backed PermissionSetAssignment and PermissionSet rows are separated from direct permission set assignments."],
  ["System permissions", "Included in Excel", `${systemPermissionFields.length} queryable system-permission fields; effective high-risk grants and source permission sets are shown on User Risk Hits.`],
  ["Object permissions", "Full raw CSV", `${objectPermissionSourceCount} permission-set object grant rows are included beside the workbook as Pro_Biomedical_Object_Permissions_2026-08-19.csv; broad user-level grants are flagged on User Risk Hits.`],
  ["Field permissions", "Full raw CSV", `${fieldPermissionCount} field permission rows are included beside the workbook as Pro_Biomedical_Full_Field_Permissions_2026-08-19.csv; permission-set field counts remain on Profiles and Permission Sets.`],
  ["Setup entity access", "Full raw CSV", `${setupEntitySourceCount} grants are included beside the workbook as Pro_Biomedical_Setup_Entity_Access_2026-08-19.csv.`],
  ["Tab visibility", "Reconciled raw CSV", `${tabSettingSourceCount} unique records are included beside the workbook as Pro_Biomedical_Tab_Visibility_2026-08-19.csv. Salesforce aggregate COUNT() reported 20,022, but query APIs exposed fewer unique records.`],
  ["Permission Set Groups", "Included", "Group definitions, components, and group assignments are included. Effective group permissions are represented by the assigned aggregate PermissionSetId returned by Salesforce."],
  ["Recommended workflow", "Review before restriction", "Filter active Critical/High users, inspect User Risk Hits and source permission sets, document the decision and business justification, then implement approved changes separately with rollback evidence."],
  ["Sensitive data", "Admin use", "Contains usernames, emails, access assignments, federation identifiers, Salesforce record IDs, and security configuration. Store and share appropriately."],
];
addDataSheet("Coverage & Guidance", ["Area", "Status", "Explanation"], coverageRows, { wideColumns: [0, 1, 2], wrapColumns: [0, 1, 2], tableStyle: "TableStyleMedium4", fontSize: 10 });

summary.showGridLines = false;
summary.mergeCells("A1:H1");
summary.getRange("A1").values = [["Pro Biomedical Detailed User Permission & Risk Review"]];
summary.getRange("A1:H1").format.fill = theme.navy;
summary.getRange("A1:H1").format.font = { name: "Aptos Display", size: 20, bold: true, color: "#FFFFFF" };
summary.getRange("A1:H1").format.rowHeight = 38;
summary.mergeCells("A2:H2");
summary.getRange("A2").values = [["Read-only production-org assessment | Generated 2026-08-19 | Review evidence, not an automatic eligibility decision"]];
summary.getRange("A2:H2").format.fill = "#DCEAF7";
summary.getRange("A2:H2").format.font = { italic: true, color: theme.navy };

summary.getRange("A4:B10").values = [
  ["Org detail", "Value"],
  ["Organization", organization[0]?.Name ?? ""],
  ["Org ID", organization[0]?.Id ?? ""],
  ["Type", `${organization[0]?.OrganizationType ?? ""}${bool(organization[0]?.IsSandbox) ? " Sandbox" : " Production"}`],
  ["Instance", organization[0]?.InstanceName ?? ""],
  ["Target alias", "ProboMedical"],
  ["Change activity", "None - read-only export"],
];
summary.getRange("A4:B4").format.fill = theme.teal;
summary.getRange("A4:B4").format.font = { bold: true, color: "#FFFFFF" };
summary.getRange("A4:B10").format.borders = { preset: "all", style: "thin", color: theme.border };

summary.getRange("D4:F4").values = [["Metric", "Workbook Formula", "Exported Value"]];
summary.getRange("D4:F4").format.fill = theme.teal;
summary.getRange("D4:F4").format.font = { bold: true, color: "#FFFFFF" };
const metrics = [
  ["Users", `=COUNTA('Users'!$A$2:$A$${users.length + 1})`, users.length],
  ["Active users", `=COUNTIF('Users'!$E$2:$E$${users.length + 1},1)`, users.filter((user) => bool(user.IsActive)).length],
  ["Profiles", `=COUNTA('Profiles'!$A$2:$A$${profiles.length + 1})`, profiles.length],
  ["Roles", `=COUNTA('Roles'!$A$2:$A$${roles.length + 1})`, roles.length],
  ["Permission sets", `=COUNTA('Permission Sets'!$A$2:$A$${permissionSets.length + 1})`, permissionSets.length],
  ["Permission assignments", `=COUNTA('PS Assignments'!$A$2:$A$${permissionSetAssignments.length + 1})`, permissionSetAssignments.length],
  ["System permission types", `=COUNTA('System Permission Catalog'!$A$2:$A$${catalogRows.length + 1})`, catalogRows.length],
  ["True system-permission grants", `=SUM('Permission Sets'!$M$2:$M$${permissionSets.length + 1})`, systemGrantSourceCount],
  ["Object permission rows", `=SUM('Permission Sets'!$N$2:$N$${permissionSets.length + 1})`, objectPermissionSourceCount],
  ["Source field permission rows", `=SUM('Permission Sets'!$O$2:$O$${permissionSets.length + 1})`, fieldPermissionCount],
  ["Setup entity access rows", `=SUM('Permission Sets'!$P$2:$P$${permissionSets.length + 1})`, setupEntitySourceCount],
  ["User risk hits", `=COUNTA('User Risk Hits'!$A$2:$A$${riskHitRows.length + 1})`, riskHitRows.length],
];
summary.getRange(`D5:D${metrics.length + 4}`).values = metrics.map((row) => [row[0]]);
summary.getRange(`E5:E${metrics.length + 4}`).formulas = metrics.map((row) => [row[1]]);
summary.getRange(`F5:F${metrics.length + 4}`).values = metrics.map((row) => [row[2]]);
summary.getRange(`D4:F${metrics.length + 4}`).format.borders = { preset: "all", style: "thin", color: theme.border };
summary.getRange(`F5:F${metrics.length + 4}`).format.fill = theme.light;

summary.getRange("A13:B13").values = [["Risk level", "Active users"]];
summary.getRange("A13:B13").format.fill = theme.teal;
summary.getRange("A13:B13").format.font = { bold: true, color: "#FFFFFF" };
const reviewEnd = userRiskReviewRows.length + 1;
summary.getRange("A14:A17").values = [["Critical"], ["High"], ["Medium"], ["Low"]];
summary.getRange("B14").formulas = [[`=COUNTIFS('User Risk Review'!$D$2:$D$${reviewEnd},1,'User Risk Review'!$V$2:$V$${reviewEnd},A14)`]];
summary.getRange("B14:B17").fillDown();
summary.getRange("A13:B17").format.borders = { preset: "all", style: "thin", color: theme.border };
summary.getRange("A14:B14").format.fill = theme.critical;
summary.getRange("A15:B15").format.fill = theme.high;
summary.getRange("A16:B16").format.fill = theme.medium;
summary.getRange("A17:B17").format.fill = theme.low;

summary.mergeCells("A20:H20");
summary.getRange("A20").values = [["Recommended review sequence"]];
summary.getRange("A20:H20").format.fill = theme.navy;
summary.getRange("A20:H20").format.font = { bold: true, color: "#FFFFFF", size: 12 };
summary.getRange("A21:H26").values = [
  ["1", "Filter User Risk Review to Active = TRUE and Risk Level = Critical or High.", "", "", "", "", "", ""],
  ["2", "Open User Risk Hits to see the exact permission, severity, source permission sets, and rationale.", "", "", "", "", "", ""],
  ["3", "Validate broad object access in User Risk Hits and detailed grants in Object/Field/Setup sheets.", "", "", "", "", "", ""],
  ["4", "Record Review Status, Decision, business eligibility/justification, approver, and review date.", "", "", "", "", "", ""],
  ["5", "Obtain manager/system-owner approval before restricting or removing access.", "", "", "", "", "", ""],
  ["6", "Implement approved changes separately with a rollback plan and post-change verification.", "", "", "", "", "", ""],
];
for (let row = 21; row <= 26; row += 1) summary.mergeCells(`B${row}:H${row}`);
summary.getRange("A21:H26").format.borders = { preset: "all", style: "thin", color: theme.border };
summary.getRange("A21:A26").format.fill = "#DCEAF7";
summary.getRange("A21:A26").format.font = { bold: true, color: theme.navy };
summary.getRange("B21:H26").format.wrapText = true;
summary.getRange("A:A").format.columnWidth = 27;
summary.getRange("B:B").format.columnWidth = 48;
summary.getRange("C:C").format.columnWidth = 3;
summary.getRange("D:D").format.columnWidth = 35;
summary.getRange("E:E").format.columnWidth = 22;
summary.getRange("F:F").format.columnWidth = 17;
summary.getRange("G:H").format.columnWidth = 12;
summary.freezePanes.freezeRows(2);

const inspections = {
  sheets: await workbook.inspect({ kind: "sheet", include: "id,name", maxChars: 12000 }),
  summary: await workbook.inspect({ kind: "table", range: "Summary!A1:F17", include: "values,formulas", tableMaxRows: 20, tableMaxCols: 8 }),
  review: await workbook.inspect({ kind: "table", range: "'User Risk Review'!A1:X8", include: "values,formulas", tableMaxRows: 10, tableMaxCols: 24, tableMaxCellChars: 120 }),
  formulaErrors: await workbook.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A", options: { useRegex: true, maxResults: 300 }, summary: "Final formula error scan" }),
  counts: {
    users: users.length,
    activeUsers: users.filter((user) => bool(user.IsActive)).length,
    profiles: profiles.length,
    roles: roles.length,
    permissionSets: permissionSets.length,
    assignments: permissionSetAssignments.length,
    systemPermissionFields: systemPermissionFields.length,
    systemGrantRows: systemGrantRows.length,
    effectiveSystemRows: effectiveSystemRows.length,
    objectPermissionRows: objectPermissionSourceCount,
    effectiveObjectRows: effectiveObjectRows.length,
    fieldPermissionRows: fieldPermissionCount,
    setupEntityRows: setupEntitySourceCount,
    tabSettingRows: tabSettingSourceCount,
    riskHitRows: riskHitRows.length,
  },
};

const previewRanges = {
  Summary: "A1:H26",
  "User Risk Review": "A1:AD15",
  "User Risk Hits": "A1:K15",
  "User Access Overview": "A1:R15",
  Users: "A1:Y12",
  Roles: "A1:O15",
  Profiles: "A1:Q15",
  "Permission Sets": "A1:T15",
  "PS Assignments": "A1:O15",
  "PS Groups": "A1:I15",
  "PSG Components": "A1:J15",
  "System Permission Catalog": "A1:F15",
  "Risk Rules": "A1:I15",
  "Coverage & Guidance": "A1:C15",
};

for (const [sheetName, range] of Object.entries(previewRanges)) {
  const preview = await workbook.render({ sheetName, range, scale: sheetName === "Summary" ? 1 : 0.75, format: "png" });
  const safeName = sheetName.replace(/[^A-Za-z0-9]+/g, "_").replace(/^_|_$/g, "").toLowerCase();
  await fs.writeFile(path.join(previewDir, `${safeName}.png`), new Uint8Array(await preview.arrayBuffer()));
}

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
await fs.copyFile(path.join(inputDir, "field_permissions_rest.csv"), path.join(outputDir, "Pro_Biomedical_Full_Field_Permissions_2026-08-19.csv"));
await fs.copyFile(path.join(inputDir, "object_permissions_rest.csv"), path.join(outputDir, "Pro_Biomedical_Object_Permissions_2026-08-19.csv"));
await fs.copyFile(path.join(inputDir, "setup_entity_access_rest.csv"), path.join(outputDir, "Pro_Biomedical_Setup_Entity_Access_2026-08-19.csv"));
await fs.copyFile(path.join(inputDir, "tab_settings_reconciled.csv"), path.join(outputDir, "Pro_Biomedical_Tab_Visibility_2026-08-19.csv"));
await fs.writeFile(inspectionPath, JSON.stringify(inspections, null, 2), "utf8");

console.log(JSON.stringify({ outputPath, previewDir, inspectionPath, counts: inspections.counts }, null, 2));
