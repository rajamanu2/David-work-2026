import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const root = path.resolve("..");
const inputDir = path.join(root, "scratch", "user_access_export");
const settingsXmlPath = path.join(
  root,
  "scratch",
  "user_access_metadata_project",
  "force-app",
  "main",
  "default",
  "settings",
  "UserManagement.settings-meta.xml",
);
const outputDir = path.join(root, "outputs");
const outputPath = path.join(outputDir, "Pro_Biomedical_User_Access_Inventory_2026-08-18.xlsx");
const previewDir = path.join(root, "scratch", "previews");
const previewPath = path.join(previewDir, "user_access_inventory_summary.png");
const inspectionPath = path.join(root, "scratch", "user_access_workbook_inspection.json");

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
      } else if (ch === '"') {
        quoted = false;
      } else {
        value += ch;
      }
    } else if (ch === '"') {
      quoted = true;
    } else if (ch === ",") {
      row.push(value);
      value = "";
    } else if (ch === "\n") {
      row.push(value.replace(/\r$/, ""));
      rows.push(row);
      row = [];
      value = "";
    } else {
      value += ch;
    }
  }
  if (value.length || row.length) {
    row.push(value.replace(/\r$/, ""));
    rows.push(row);
  }
  return rows;
}

async function readCsv(name) {
  const text = await fs.readFile(path.join(inputDir, `${name}.csv`), "utf8");
  const rows = parseCsv(text);
  const headers = rows.shift() ?? [];
  return rows
    .filter((row) => row.some((cell) => cell !== ""))
    .map((row) => Object.fromEntries(headers.map((header, index) => [header, row[index] ?? ""])));
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
  permissionSetLicenses,
  permissionSetLicenseAssignments,
  userLicenses,
  groups,
  groupMembers,
  queueObjects,
  exportManifest,
] = await Promise.all([
  readCsv("organization"),
  readCsv("users"),
  readCsv("user_login"),
  readCsv("profiles"),
  readCsv("roles"),
  readCsv("permission_sets"),
  readCsv("permission_set_assignments"),
  readCsv("permission_set_groups"),
  readCsv("permission_set_group_components"),
  readCsv("permission_set_licenses"),
  readCsv("permission_set_license_assignments"),
  readCsv("user_licenses"),
  readCsv("groups"),
  readCsv("group_members"),
  readCsv("queue_objects"),
  readCsv("export_manifest"),
]);

const bool = (value) => String(value).toLowerCase() === "true";
const dateText = (value) => (value ? value.replace("T", " ").replace(/\.000\+0000$/, " UTC") : "");
const clean = (value) => (value === null || value === undefined ? "" : value);
const byId = (records) => new Map(records.map((record) => [record.Id, record]));
const userById = byId(users);
const roleById = byId(roles);
const groupById = byId(groups);
const loginByUserId = new Map(userLogin.map((record) => [record.UserId, record]));
const pslById = byId(permissionSetLicenses);

const roleChildren = new Map();
for (const role of roles) {
  if (!role.ParentRoleId) continue;
  if (!roleChildren.has(role.ParentRoleId)) roleChildren.set(role.ParentRoleId, []);
  roleChildren.get(role.ParentRoleId).push(role.Id);
}

function descendantRoleIds(roleId) {
  const result = new Set([roleId]);
  const queue = [roleId];
  while (queue.length) {
    const current = queue.shift();
    for (const child of roleChildren.get(current) ?? []) {
      if (!result.has(child)) {
        result.add(child);
        queue.push(child);
      }
    }
  }
  return result;
}

const membersByGroup = new Map();
for (const member of groupMembers) {
  if (!membersByGroup.has(member.GroupId)) membersByGroup.set(member.GroupId, []);
  membersByGroup.get(member.GroupId).push(member);
}

function usersForRoleGroup(group) {
  if (!group.RelatedId) return [];
  let roleIds;
  if (group.Type === "Role") roleIds = new Set([group.RelatedId]);
  else if (group.Type === "RoleAndSubordinates" || group.Type === "RoleAndSubordinatesInternal") {
    roleIds = descendantRoleIds(group.RelatedId);
  } else return [];
  return users
    .filter((user) => roleIds.has(user.UserRoleId))
    .map((user) => ({ user, basis: group.Type, path: group.Name || group.DeveloperName || group.Id }));
}

function effectiveUsersForGroup(groupId) {
  const found = new Map();

  function addUser(user, basis, parts) {
    const candidate = { user, basis, path: parts.join(" > ") };
    const existing = found.get(user.Id);
    if (!existing || (existing.basis !== "Direct User" && basis === "Direct User")) found.set(user.Id, candidate);
  }

  function expand(currentGroupId, parts, visited, depth) {
    if (visited.has(currentGroupId)) return;
    const nextVisited = new Set(visited);
    nextVisited.add(currentGroupId);
    const currentGroup = groupById.get(currentGroupId);
    if (!currentGroup) return;

    if (["Role", "RoleAndSubordinates", "RoleAndSubordinatesInternal"].includes(currentGroup.Type)) {
      for (const entry of usersForRoleGroup(currentGroup)) {
        addUser(entry.user, entry.basis, [...parts, currentGroup.Name || currentGroup.Id]);
      }
    } else if (currentGroup.Type === "Organization") {
      for (const user of users) addUser(user, "Organization", [...parts, currentGroup.Name || currentGroup.Id]);
    }

    for (const member of membersByGroup.get(currentGroupId) ?? []) {
      if (userById.has(member.UserOrGroupId)) {
        const basis = depth === 0 ? "Direct User" : "Nested Group";
        addUser(userById.get(member.UserOrGroupId), basis, [...parts, userById.get(member.UserOrGroupId).Name]);
      } else if (groupById.has(member.UserOrGroupId)) {
        const nested = groupById.get(member.UserOrGroupId);
        expand(nested.Id, [...parts, nested.Name || nested.DeveloperName || nested.Id], nextVisited, depth + 1);
      }
    }
  }

  const rootGroup = groupById.get(groupId);
  if (rootGroup) expand(groupId, [rootGroup.Name || rootGroup.DeveloperName || rootGroup.Id], new Set(), 0);
  return [...found.values()].sort((a, b) => a.user.Name.localeCompare(b.user.Name));
}

const publicGroups = groups.filter((group) => group.Type === "Regular");
const queues = groups.filter((group) => group.Type === "Queue");
const analyticsGroups = groups.filter((group) => ["PardotUserGroup", "PardotUserRestrictedGroup"].includes(group.Type));

function buildEffectiveRows(targetGroups) {
  const rows = [];
  const byGroup = new Map();
  for (const group of targetGroups) {
    const effective = effectiveUsersForGroup(group.Id);
    byGroup.set(group.Id, effective);
    for (const entry of effective) {
      rows.push([
        group.Id,
        group.Name,
        group.DeveloperName,
        group.Type,
        entry.user.Id,
        entry.user.Username,
        entry.user.Name,
        bool(entry.user.IsActive),
        entry.basis,
        entry.path,
      ]);
    }
  }
  return { rows, byGroup };
}

const publicEffective = buildEffectiveRows(publicGroups);
const queueEffective = buildEffectiveRows(queues);
const analyticsEffective = buildEffectiveRows(analyticsGroups);

const directPsByUser = new Map();
const psgByUser = new Map();
const pslByUser = new Map();
function addToMapList(map, key, value) {
  if (!map.has(key)) map.set(key, []);
  map.get(key).push(value);
}

function assignmentType(record) {
  if (record.PermissionSetGroupId) return "Permission Set Group";
  if (bool(record["PermissionSet.IsOwnedByProfile"])) return "Profile Backing Permission Set";
  return "Direct Permission Set";
}

for (const assignment of permissionSetAssignments) {
  const type = assignmentType(assignment);
  if (type === "Direct Permission Set") addToMapList(directPsByUser, assignment.AssigneeId, assignment);
  if (type === "Permission Set Group") addToMapList(psgByUser, assignment.AssigneeId, assignment);
}
for (const assignment of permissionSetLicenseAssignments) addToMapList(pslByUser, assignment.AssigneeId, assignment);

function reverseEffectiveMap(effectiveByGroup, targetGroups) {
  const result = new Map();
  const groupMap = new Map(targetGroups.map((group) => [group.Id, group]));
  for (const [groupId, entries] of effectiveByGroup.entries()) {
    const group = groupMap.get(groupId);
    for (const entry of entries) addToMapList(result, entry.user.Id, { group, ...entry });
  }
  return result;
}

const publicByUser = reverseEffectiveMap(publicEffective.byGroup, publicGroups);
const queueByUser = reverseEffectiveMap(queueEffective.byGroup, queues);
const analyticsByUser = reverseEffectiveMap(analyticsEffective.byGroup, analyticsGroups);

const uniqueSorted = (values) => [...new Set(values.filter(Boolean))].sort((a, b) => a.localeCompare(b));
const joinNames = (values) => uniqueSorted(values).join("; ");

const userMatrixRows = users.map((user) => {
  const login = loginByUserId.get(user.Id) ?? {};
  const direct = directPsByUser.get(user.Id) ?? [];
  const psg = psgByUser.get(user.Id) ?? [];
  const psl = pslByUser.get(user.Id) ?? [];
  const publicMemberships = publicByUser.get(user.Id) ?? [];
  const queueMemberships = queueByUser.get(user.Id) ?? [];
  const analyticsMemberships = analyticsByUser.get(user.Id) ?? [];
  return [
    user.Id,
    user.Username,
    user.Name,
    bool(user.IsActive),
    user.UserType,
    user["Profile.UserLicense.Name"],
    user["Profile.Name"],
    user["UserRole.Name"],
    user["Manager.Name"],
    user.Department,
    user.Title,
    dateText(user.LastLoginDate),
    login.Id ? bool(login.IsFrozen) : "",
    login.Id ? bool(login.IsPasswordLocked) : "",
    direct.length,
    joinNames(direct.map((record) => record["PermissionSet.Label"] || record["PermissionSet.Name"])),
    psg.length,
    joinNames(psg.map((record) => record["PermissionSetGroup.MasterLabel"] || record["PermissionSetGroup.DeveloperName"])),
    psl.length,
    joinNames(psl.map((record) => record["PermissionSetLicense.MasterLabel"] || record["PermissionSetLicense.DeveloperName"])),
    publicMemberships.length,
    joinNames(publicMemberships.map((record) => record.group.Name)),
    queueMemberships.length,
    joinNames(queueMemberships.map((record) => record.group.Name)),
    analyticsMemberships.length,
    joinNames(analyticsMemberships.map((record) => record.group.Name)),
    `https://probomedical.my.salesforce.com/${user.Id}`,
  ];
});

const accessMapRows = [];
function addAccess(user, type, accessId, accessName, basis, sourceId = "", pathText = "") {
  accessMapRows.push([
    user.Id,
    user.Username,
    user.Name,
    bool(user.IsActive),
    type,
    accessId,
    accessName,
    basis,
    sourceId,
    pathText,
  ]);
}
for (const user of users) {
  addAccess(user, "Profile", user.ProfileId, user["Profile.Name"], "User.ProfileId");
  addAccess(user, "User License", user["Profile.UserLicenseId"], user["Profile.UserLicense.Name"], "Profile.UserLicenseId");
  if (user.UserRoleId) addAccess(user, "Role", user.UserRoleId, user["UserRole.Name"], "User.UserRoleId");
  for (const record of directPsByUser.get(user.Id) ?? []) {
    addAccess(user, "Direct Permission Set", record.PermissionSetId, record["PermissionSet.Label"] || record["PermissionSet.Name"], "PermissionSetAssignment", record.Id);
  }
  for (const record of psgByUser.get(user.Id) ?? []) {
    addAccess(user, "Permission Set Group", record.PermissionSetGroupId, record["PermissionSetGroup.MasterLabel"] || record["PermissionSetGroup.DeveloperName"], "PermissionSetAssignment", record.Id);
  }
  for (const record of pslByUser.get(user.Id) ?? []) {
    addAccess(user, "Permission Set License", record.PermissionSetLicenseId, record["PermissionSetLicense.MasterLabel"] || record["PermissionSetLicense.DeveloperName"], "PermissionSetLicenseAssign", record.Id);
  }
  for (const record of publicByUser.get(user.Id) ?? []) addAccess(user, "Public Group", record.group.Id, record.group.Name, record.basis, "", record.path);
  for (const record of queueByUser.get(user.Id) ?? []) addAccess(user, "Queue", record.group.Id, record.group.Name, record.basis, "", record.path);
  for (const record of analyticsByUser.get(user.Id) ?? []) addAccess(user, "Analytics Group", record.group.Id, record.group.Name, record.basis, "", record.path);
}
accessMapRows.sort((a, b) => a[2].localeCompare(b[2]) || a[4].localeCompare(b[4]) || String(a[6]).localeCompare(String(b[6])));

const directAssignmentCounts = new Map();
const directActiveCounts = new Map();
const profileBackingCounts = new Map();
for (const record of permissionSetAssignments) {
  const type = assignmentType(record);
  if (type === "Direct Permission Set") {
    directAssignmentCounts.set(record.PermissionSetId, (directAssignmentCounts.get(record.PermissionSetId) ?? 0) + 1);
    if (bool(record["Assignee.IsActive"])) directActiveCounts.set(record.PermissionSetId, (directActiveCounts.get(record.PermissionSetId) ?? 0) + 1);
  } else if (type === "Profile Backing Permission Set") {
    profileBackingCounts.set(record.PermissionSetId, (profileBackingCounts.get(record.PermissionSetId) ?? 0) + 1);
  }
}

const profileUserCounts = new Map();
const roleUserCounts = new Map();
for (const user of users) {
  profileUserCounts.set(user.ProfileId, (profileUserCounts.get(user.ProfileId) ?? 0) + 1);
  if (user.UserRoleId) roleUserCounts.set(user.UserRoleId, (roleUserCounts.get(user.UserRoleId) ?? 0) + 1);
}

const psgAssignmentCounts = new Map();
for (const record of permissionSetAssignments.filter((record) => record.PermissionSetGroupId)) {
  psgAssignmentCounts.set(record.PermissionSetGroupId, (psgAssignmentCounts.get(record.PermissionSetGroupId) ?? 0) + 1);
}
const psgComponentCounts = new Map();
for (const record of permissionSetGroupComponents) {
  psgComponentCounts.set(record.PermissionSetGroupId, (psgComponentCounts.get(record.PermissionSetGroupId) ?? 0) + 1);
}

const pslAssignmentCounts = new Map();
for (const record of permissionSetLicenseAssignments) {
  pslAssignmentCounts.set(record.PermissionSetLicenseId, (pslAssignmentCounts.get(record.PermissionSetLicenseId) ?? 0) + 1);
}

const queueObjectMap = new Map();
for (const record of queueObjects) addToMapList(queueObjectMap, record.QueueId, record.SobjectType);

function directGroupMemberCount(groupId) {
  return (membersByGroup.get(groupId) ?? []).length;
}

const settingsXml = await fs.readFile(settingsXmlPath, "utf8");
const settingsRows = [...settingsXml.matchAll(/<([A-Za-z0-9_]+)>([^<]*)<\/\1>/g)]
  .filter((match) => match[1] !== "UserManagementSettings")
  .map((match) => [match[1], bool(match[2]), "UserManagement.settings-meta.xml"]);

const workbook = Workbook.create();
const summary = workbook.worksheets.add("Summary");
const tableNames = new Set();
const theme = {
  navy: "#16324F",
  teal: "#0B7285",
  cyan: "#D9F0F2",
  light: "#F4F7FA",
  border: "#CBD5E1",
  green: "#DCFCE7",
  red: "#FEE2E2",
  amber: "#FEF3C7",
  text: "#172B4D",
};

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
  let name = base;
  let suffix = 2;
  while (tableNames.has(name)) name = `${base}${suffix++}`;
  tableNames.add(name);
  return name;
}

function normalizeRows(rows, columnCount) {
  return rows.map((row) => Array.from({ length: columnCount }, (_, index) => clean(row[index])));
}

function addDataSheet(name, headers, rows, options = {}) {
  const sheet = workbook.worksheets.add(name);
  sheet.showGridLines = false;
  const normalized = normalizeRows(rows, headers.length);
  const allRows = [headers, ...normalized];
  const lastCol = colName(headers.length - 1);
  const lastRow = allRows.length;
  sheet.getRange(`A1:${lastCol}${lastRow}`).values = allRows;
  const used = sheet.getRange(`A1:${lastCol}${lastRow}`);
  used.format.font = { name: "Aptos", size: options.fontSize ?? 9, color: theme.text };
  used.format.verticalAlignment = "top";
  const header = sheet.getRange(`A1:${lastCol}1`);
  header.format.fill = theme.navy;
  header.format.font = { name: "Aptos Display", size: 10, bold: true, color: "#FFFFFF" };
  header.format.wrapText = true;
  header.format.rowHeight = 30;
  header.format.borders = { preset: "all", style: "thin", color: theme.border };
  if (lastRow > 1) {
    const data = sheet.getRange(`A2:${lastCol}${lastRow}`);
    data.format.borders = { preset: "all", style: "thin", color: "#E2E8F0" };
    const table = sheet.tables.add(`A1:${lastCol}${lastRow}`, true, safeTableName(name));
    table.style = options.tableStyle ?? "TableStyleMedium2";
    table.showFilterButton = true;
    table.showBandedRows = true;
  }
  sheet.freezePanes.freezeRows(1);
  if (options.freezeColumns) sheet.freezePanes.freezeColumns(options.freezeColumns);

  headers.forEach((headerText, index) => {
    const maxLength = Math.max(
      String(headerText).length,
      ...normalized.slice(0, 500).map((row) => String(row[index] ?? "").length),
    );
    const cap = options.wideColumns?.includes(index) ? 65 : 34;
    const width = Math.min(cap, Math.max(10, maxLength + 2));
    sheet.getRange(`${colName(index)}:${colName(index)}`).format.columnWidth = width;
  });
  for (const index of options.wrapColumns ?? []) {
    sheet.getRange(`${colName(index)}:${colName(index)}`).format.wrapText = true;
  }
  for (const index of options.booleanColumns ?? []) {
    if (lastRow > 1) {
      const range = sheet.getRange(`${colName(index)}2:${colName(index)}${lastRow}`);
      range.conditionalFormats.add("cellIs", { operator: "equal", formula: "TRUE", format: { fill: theme.green, font: { color: "#166534" } } });
      range.conditionalFormats.add("cellIs", { operator: "equal", formula: "FALSE", format: { fill: theme.red, font: { color: "#991B1B" } } });
    }
  }
  return sheet;
}

// Create all detailed sheets before the summary formulas reference them.
addDataSheet(
  "User Access Matrix",
  ["User ID", "Username", "User Name", "Active", "User Type", "User License", "Profile", "Role", "Manager", "Department", "Title", "Last Login (UTC)", "Frozen", "Password Locked", "Direct PS Count", "Direct Permission Sets", "PS Group Count", "Permission Set Groups", "PS License Count", "Permission Set Licenses", "Public Group Count", "Public Groups", "Queue Count", "Queues", "Analytics Group Count", "Analytics Groups", "Salesforce User URL"],
  userMatrixRows,
  { freezeColumns: 3, wideColumns: [15, 17, 19, 21, 23, 25, 26], wrapColumns: [15, 17, 19, 21, 23, 25], booleanColumns: [3, 12, 13] },
);

addDataSheet(
  "User Mappings",
  ["User ID", "Username", "User Name", "Active", "Access Type", "Access ID", "Access Name", "Assignment Basis", "Source Assignment ID", "Effective Membership Path"],
  accessMapRows,
  { freezeColumns: 3, wideColumns: [6, 9], wrapColumns: [9], booleanColumns: [3] },
);

const userRows = users.map((user) => {
  const login = loginByUserId.get(user.Id) ?? {};
  return [
    user.Id, user.Username, user.Name, user.FirstName, user.LastName, user.Email, user.Alias, bool(user.IsActive), user.UserType,
    user.ProfileId, user["Profile.Name"], user["Profile.UserLicenseId"], user["Profile.UserLicense.Name"], user.UserRoleId, user["UserRole.Name"],
    user.ManagerId, user["Manager.Name"], user.Department, user.Division, user.Title, user.CompanyName, user.Phone, user.MobilePhone,
    user.TimeZoneSidKey, user.LocaleSidKey, user.LanguageLocaleKey, user.EmailEncodingKey, user.FederationIdentifier,
    dateText(user.CreatedDate), dateText(user.LastLoginDate), dateText(user.LastModifiedDate), login.Id ? bool(login.IsFrozen) : "", login.Id ? bool(login.IsPasswordLocked) : "",
    `https://probomedical.my.salesforce.com/${user.Id}`,
  ];
});
addDataSheet("Users", ["User ID", "Username", "Name", "First Name", "Last Name", "Email", "Alias", "Active", "User Type", "Profile ID", "Profile", "User License ID", "User License", "Role ID", "Role", "Manager ID", "Manager", "Department", "Division", "Title", "Company", "Phone", "Mobile Phone", "Time Zone", "Locale", "Language", "Email Encoding", "Federation Identifier", "Created (UTC)", "Last Login (UTC)", "Last Modified (UTC)", "Frozen", "Password Locked", "Salesforce URL"], userRows, { freezeColumns: 3, wideColumns: [1, 2, 5, 27, 33], booleanColumns: [7, 31, 32] });

addDataSheet("User Login", ["User Login ID", "User ID", "Username", "User Name", "Frozen", "Password Locked", "Last Modified (UTC)"], userLogin.map((record) => {
  const user = userById.get(record.UserId) ?? {};
  return [record.Id, record.UserId, user.Username, user.Name, bool(record.IsFrozen), bool(record.IsPasswordLocked), dateText(record.LastModifiedDate)];
}), { booleanColumns: [4, 5] });

addDataSheet("Profiles", ["Profile ID", "Profile Name", "User License ID", "User License", "User Type", "Description", "Assigned Users", "Created (UTC)", "Last Modified (UTC)", "Salesforce URL"], profiles.map((record) => [record.Id, record.Name, record.UserLicenseId, record["UserLicense.Name"], record.UserType, record.Description, profileUserCounts.get(record.Id) ?? 0, dateText(record.CreatedDate), dateText(record.LastModifiedDate), `https://probomedical.my.salesforce.com/${record.Id}`]), { wideColumns: [1, 5, 9], wrapColumns: [5] });

addDataSheet("Roles", ["Role ID", "Role Name", "Developer Name", "Parent Role ID", "Parent Role", "Direct Users", "Rollup Description", "Opportunity Access for Account Owner", "Case Access for Account Owner", "Contact Access for Account Owner", "Portal Type", "Forecast User ID", "May Forecast Manager Share", "Last Modified (UTC)", "Salesforce URL"], roles.map((record) => [record.Id, record.Name, record.DeveloperName, record.ParentRoleId, record["ParentRole.Name"], roleUserCounts.get(record.Id) ?? 0, record.RollupDescription, record.OpportunityAccessForAccountOwner, record.CaseAccessForAccountOwner, record.ContactAccessForAccountOwner, record.PortalType, record.ForecastUserId, bool(record.MayForecastManagerShare), dateText(record.LastModifiedDate), `https://probomedical.my.salesforce.com/${record.Id}`]), { wideColumns: [1, 6, 14], wrapColumns: [6], booleanColumns: [12] });

addDataSheet("Permission Sets", ["Permission Set ID", "API Name", "Label", "Description", "License ID", "License", "Custom", "Owned by Profile", "Profile ID", "Profile", "Namespace", "Type", "Activation Required", "Permission Set Group ID", "Direct Assignments", "Active Direct Users", "Profile-Backing Assignments", "Created (UTC)", "Last Modified (UTC)", "Salesforce URL"], permissionSets.map((record) => [record.Id, record.Name, record.Label, record.Description, record.LicenseId, pslById.get(record.LicenseId)?.MasterLabel ?? "", bool(record.IsCustom), bool(record.IsOwnedByProfile), record.ProfileId, record["Profile.Name"], record.NamespacePrefix, record.Type, bool(record.HasActivationRequired), record.PermissionSetGroupId, directAssignmentCounts.get(record.Id) ?? 0, directActiveCounts.get(record.Id) ?? 0, profileBackingCounts.get(record.Id) ?? 0, dateText(record.CreatedDate), dateText(record.LastModifiedDate), `https://probomedical.my.salesforce.com/${record.Id}`]), { wideColumns: [2, 3, 19], wrapColumns: [3], booleanColumns: [6, 7, 12] });

addDataSheet("PS Assignments", ["Assignment ID", "Assignment Type", "Assignee ID", "Username", "User Name", "User Active", "Permission Set ID", "Permission Set API Name", "Permission Set Label", "Owned by Profile", "Permission Set Group ID", "Permission Set Group API Name", "Permission Set Group Label", "Assignment Active", "Expiration Date"], permissionSetAssignments.map((record) => [record.Id, assignmentType(record), record.AssigneeId, record["Assignee.Username"], record["Assignee.Name"], bool(record["Assignee.IsActive"]), record.PermissionSetId, record["PermissionSet.Name"], record["PermissionSet.Label"], bool(record["PermissionSet.IsOwnedByProfile"]), record.PermissionSetGroupId, record["PermissionSetGroup.DeveloperName"], record["PermissionSetGroup.MasterLabel"], bool(record.IsActive), record.ExpirationDate]), { freezeColumns: 5, wideColumns: [4, 8, 12], booleanColumns: [5, 9, 13] });

addDataSheet("PS Groups", ["PS Group ID", "API Name", "Label", "Description", "Status", "Activation Required", "Namespace", "Component Count", "Assigned Users", "Created (UTC)", "Last Modified (UTC)", "Salesforce URL"], permissionSetGroups.map((record) => [record.Id, record.DeveloperName, record.MasterLabel, record.Description, record.Status, bool(record.HasActivationRequired), record.NamespacePrefix, psgComponentCounts.get(record.Id) ?? 0, psgAssignmentCounts.get(record.Id) ?? 0, dateText(record.CreatedDate), dateText(record.LastModifiedDate), `https://probomedical.my.salesforce.com/${record.Id}`]), { wideColumns: [2, 3, 11], wrapColumns: [3], booleanColumns: [5] });

addDataSheet("PSG Components", ["Component ID", "PS Group ID", "PS Group API Name", "PS Group Label", "Permission Set ID", "Permission Set API Name", "Permission Set Label", "Permission Set Type", "Created (UTC)", "Last Modified (UTC)"], permissionSetGroupComponents.map((record) => [record.Id, record.PermissionSetGroupId, record["PermissionSetGroup.DeveloperName"], record["PermissionSetGroup.MasterLabel"], record.PermissionSetId, record["PermissionSet.Name"], record["PermissionSet.Label"], record["PermissionSet.Type"], dateText(record.CreatedDate), dateText(record.LastModifiedDate)]), { wideColumns: [3, 6] });

addDataSheet("PS Licenses", ["PS License ID", "API Name", "Label", "Status", "Total Licenses", "Used Licenses", "Exported Assignments", "License Key", "Expiration Date", "Expiration Policy", "Supplement License", "Available for Integrations", "Created (UTC)", "Last Modified (UTC)"], permissionSetLicenses.map((record) => [record.Id, record.DeveloperName, record.MasterLabel, record.Status, Number(record.TotalLicenses || 0), Number(record.UsedLicenses || 0), pslAssignmentCounts.get(record.Id) ?? 0, record.PermissionSetLicenseKey, record.ExpirationDate, record.LicenseExpirationPolicy, bool(record.IsSupplementLicense), bool(record.IsAvailableForIntegrations), dateText(record.CreatedDate), dateText(record.LastModifiedDate)]), { wideColumns: [2], booleanColumns: [10, 11] });

addDataSheet("PSL Assignments", ["Assignment ID", "Assignee ID", "Username", "User Name", "User Active", "PS License ID", "PS License API Name", "PS License Label", "Created (UTC)", "Last Modified (UTC)"], permissionSetLicenseAssignments.map((record) => [record.Id, record.AssigneeId, record["Assignee.Username"], record["Assignee.Name"], bool(record["Assignee.IsActive"]), record.PermissionSetLicenseId, record["PermissionSetLicense.DeveloperName"], record["PermissionSetLicense.MasterLabel"], dateText(record.CreatedDate), dateText(record.LastModifiedDate)]), { wideColumns: [3, 7], booleanColumns: [4] });

addDataSheet("User Licenses", ["User License ID", "Name", "Label", "License Definition Key", "Status", "Total Licenses", "Used Licenses", "Used Licenses Updated (UTC)", "Created (UTC)", "Last Modified (UTC)"], userLicenses.map((record) => [record.Id, record.Name, record.MasterLabel, record.LicenseDefinitionKey, record.Status, Number(record.TotalLicenses || 0), Number(record.UsedLicenses || 0), dateText(record.UsedLicensesLastUpdated), dateText(record.CreatedDate), dateText(record.LastModifiedDate)]));

const effectiveHeaders = ["Group ID", "Group Name", "Developer Name", "Group Type", "User ID", "Username", "User Name", "User Active", "Membership Basis", "Resolution Path"];
addDataSheet("Public Groups", ["Group ID", "Group Name", "Developer Name", "Description", "Direct Members", "Effective Users", "Include Bosses", "Email Members", "Email", "Owner ID", "Created (UTC)", "Last Modified (UTC)", "Salesforce URL"], publicGroups.map((record) => [record.Id, record.Name, record.DeveloperName, record.Description, directGroupMemberCount(record.Id), publicEffective.byGroup.get(record.Id)?.length ?? 0, bool(record.DoesIncludeBosses), bool(record.DoesSendEmailToMembers), record.Email, record.OwnerId, dateText(record.CreatedDate), dateText(record.LastModifiedDate), `https://probomedical.my.salesforce.com/${record.Id}`]), { wideColumns: [1, 3, 12], wrapColumns: [3], booleanColumns: [6, 7] });
addDataSheet("Public Group Members", effectiveHeaders, publicEffective.rows, { freezeColumns: 4, wideColumns: [9], wrapColumns: [9], booleanColumns: [7] });

addDataSheet("Queues", ["Queue ID", "Queue Name", "Developer Name", "Description", "Supported Objects", "Direct Members", "Effective Users", "Email Members", "Email", "Owner ID", "Created (UTC)", "Last Modified (UTC)", "Salesforce URL"], queues.map((record) => [record.Id, record.Name, record.DeveloperName, record.Description, joinNames(queueObjectMap.get(record.Id) ?? []), directGroupMemberCount(record.Id), queueEffective.byGroup.get(record.Id)?.length ?? 0, bool(record.DoesSendEmailToMembers), record.Email, record.OwnerId, dateText(record.CreatedDate), dateText(record.LastModifiedDate), `https://probomedical.my.salesforce.com/${record.Id}`]), { wideColumns: [1, 3, 4, 12], wrapColumns: [3, 4], booleanColumns: [7] });
addDataSheet("Queue Objects", ["Queue Object ID", "Queue ID", "Queue Name", "SObject Type"], queueObjects.map((record) => [record.Id, record.QueueId, record["Queue.Name"], record.SobjectType]));
addDataSheet("Queue Members", effectiveHeaders, queueEffective.rows, { freezeColumns: 4, wideColumns: [9], wrapColumns: [9], booleanColumns: [7] });

addDataSheet("Analytics Groups", ["Group ID", "Group Name", "Developer Name", "Group Type", "Description", "Direct Members", "Effective Users", "Created (UTC)", "Last Modified (UTC)", "Salesforce URL"], analyticsGroups.map((record) => [record.Id, record.Name, record.DeveloperName, record.Type, record.Description, directGroupMemberCount(record.Id), analyticsEffective.byGroup.get(record.Id)?.length ?? 0, dateText(record.CreatedDate), dateText(record.LastModifiedDate), `https://probomedical.my.salesforce.com/${record.Id}`]), { wideColumns: [1, 4, 9], wrapColumns: [4] });
addDataSheet("Analytics Members", effectiveHeaders, analyticsEffective.rows, { freezeColumns: 4, wideColumns: [9], wrapColumns: [9], booleanColumns: [7] });

addDataSheet("All Groups", ["Group ID", "Name", "Developer Name", "Description", "Type", "Related ID", "Include Bosses", "Email Members", "Email", "Owner ID", "Direct Members", "Created (UTC)", "Last Modified (UTC)"], groups.map((record) => [record.Id, record.Name, record.DeveloperName, record.Description, record.Type, record.RelatedId, bool(record.DoesIncludeBosses), bool(record.DoesSendEmailToMembers), record.Email, record.OwnerId, directGroupMemberCount(record.Id), dateText(record.CreatedDate), dateText(record.LastModifiedDate)]), { wideColumns: [1, 3], wrapColumns: [3], booleanColumns: [6, 7] });

addDataSheet("Raw Group Members", ["Group Member ID", "Group ID", "Group Name", "Group Developer Name", "Group Type", "Member ID", "Member Kind", "Member Name", "System Modified (UTC)"], groupMembers.map((record) => {
  const memberUser = userById.get(record.UserOrGroupId);
  const memberGroup = groupById.get(record.UserOrGroupId);
  return [record.Id, record.GroupId, record["Group.Name"], record["Group.DeveloperName"], record["Group.Type"], record.UserOrGroupId, memberUser ? "User" : memberGroup ? `Group (${memberGroup.Type})` : "Unresolved", memberUser?.Name ?? memberGroup?.Name ?? "", dateText(record.SystemModstamp)];
}), { wideColumns: [2, 3, 7] });

addDataSheet("User Mgmt Settings", ["Setting API Name", "Enabled", "Source Metadata"], settingsRows, { booleanColumns: [1] });

addDataSheet("Export Manifest", ["Dataset", "Rows", "Source File", "SOQL Query"], exportManifest.map((record) => [record.Dataset, Number(record.Rows || 0), record.File, record.Query]), { wideColumns: [2, 3], wrapColumns: [2, 3] });

const coverageRows = [
  ["Users", "Users; User Login; User Access Matrix", "Included", "All active and inactive User rows returned by Salesforce, with profile, role, license, manager, contact, locale, last-login, frozen, and password-lock status."],
  ["User mappings", "User Mappings", "Included", "Compiled one-row-per-user-access mapping across profile, role, user license, direct permission sets, permission set groups, permission set licenses, public groups, queues, and analytics groups."],
  ["Profiles", "Profiles", "Included", "Profile identity, user license, description, and assigned-user count. Detailed object/field/system permission matrices are outside this assignment-focused workbook."],
  ["Permission Sets", "Permission Sets; PS Assignments", "Included", "All permission sets and all PermissionSetAssignment rows. Profile-backing permission sets are clearly separated from direct permission sets and permission set group assignments."],
  ["Permission Set Groups", "PS Groups; PSG Components; PS Assignments", "Included", "All groups, component permission sets, status, and user assignments."],
  ["Roles", "Roles; User Mappings", "Included", "All roles, hierarchy parent, sharing defaults, and direct assigned-user count."],
  ["Public Groups", "Public Groups; Public Group Members", "Included", "Salesforce Group.Type=Regular. Effective users resolve direct users, nested groups, exact-role groups, and role-and-subordinate groups."],
  ["Queues", "Queues; Queue Objects; Queue Members", "Included", "All Group.Type=Queue rows, supported objects, and effective user memberships."],
  ["Analytics Groups", "Analytics Groups; Analytics Members", "Included with classification note", "Setup has no separate queryable Analytics Group object. The org's PardotUserGroup and PardotUserRestrictedGroup Group records are exported as the analytics-group candidates."],
  ["User Management Settings", "User Mgmt Settings", "Included", "Read-only retrieval of Settings:UserManagement; 19 org-level feature flags are flattened into rows."],
  ["User Mappings Setup page", "User Mappings; Coverage Notes", "Compiled mapping", "No separate queryable base object named User Mapping was exposed. The workbook provides the requested user-to-access mapping from authoritative assignment objects."],
  ["Nested membership resolution", "Public Group Members; Queue Members; Analytics Members", "Included", "Resolution follows GroupMember links and expands role hierarchy groups. Cycles are guarded and each effective user is deduplicated per group."],
  ["Security / privacy", "All sheets", "Admin use", "Contains usernames, emails, phone numbers, federation identifiers, assignment IDs, and access relationships. Store and share as sensitive administrative data."],
  ["Salesforce change activity", "N/A", "None", "All Salesforce actions used for this workbook were read-only queries or metadata retrieval. No org records or metadata were changed."],
];
addDataSheet("Coverage Notes", ["Requested Area", "Workbook Sheet(s)", "Status", "Coverage / Interpretation"], coverageRows, { wideColumns: [0, 1, 3], wrapColumns: [0, 1, 3], tableStyle: "TableStyleMedium4", fontSize: 10 });

summary.showGridLines = false;
summary.mergeCells("A1:H1");
summary.getRange("A1").values = [["Pro Biomedical Salesforce User & Access Inventory"]];
summary.getRange("A1:H1").format.fill = theme.navy;
summary.getRange("A1:H1").format.font = { name: "Aptos Display", size: 20, bold: true, color: "#FFFFFF" };
summary.getRange("A1:H1").format.rowHeight = 36;
summary.mergeCells("A2:H2");
summary.getRange("A2").values = [["Read-only production-org export | Generated 2026-08-18 | Sensitive administrative data"]];
summary.getRange("A2:H2").format.fill = theme.cyan;
summary.getRange("A2:H2").format.font = { italic: true, color: theme.navy };

const org = organization[0] ?? {};
summary.getRange("A4:B10").values = [
  ["Org detail", "Value"],
  ["Organization", org.Name],
  ["Org ID", org.Id],
  ["Type", `${org.OrganizationType}${bool(org.IsSandbox) ? " Sandbox" : " Production"}`],
  ["Instance", org.InstanceName],
  ["Target alias", "ProboMedical"],
  ["Export scope", "Users and access assignments/memberships"],
];
summary.getRange("A4:B4").format.fill = theme.teal;
summary.getRange("A4:B4").format.font = { bold: true, color: "#FFFFFF" };
summary.getRange("A4:B10").format.borders = { preset: "all", style: "thin", color: theme.border };

summary.getRange("D4:F4").values = [["Metric", "Workbook Formula", "Exported Value"]];
summary.getRange("D4:F4").format.fill = theme.teal;
summary.getRange("D4:F4").format.font = { bold: true, color: "#FFFFFF" };
const formulaMetrics = [
  ["Total users", `=COUNTA(Users!$A$2:$A$${users.length + 1})`, users.length],
  ["Active users", `=COUNTIF(Users!$H$2:$H$${users.length + 1},1)`, users.filter((user) => bool(user.IsActive)).length],
  ["Inactive users", `=COUNTA(Users!$H$2:$H$${users.length + 1})-COUNTIF(Users!$H$2:$H$${users.length + 1},1)`, users.filter((user) => !bool(user.IsActive)).length],
  ["Profiles", `=COUNTA(Profiles!$A$2:$A$${profiles.length + 1})`, profiles.length],
  ["Roles", `=COUNTA(Roles!$A$2:$A$${roles.length + 1})`, roles.length],
  ["Permission sets", `=COUNTA('Permission Sets'!$A$2:$A$${permissionSets.length + 1})`, permissionSets.length],
  ["Direct permission assignments", `=COUNTIF('PS Assignments'!$B$2:$B$${permissionSetAssignments.length + 1},"Direct Permission Set")`, permissionSetAssignments.filter((record) => assignmentType(record) === "Direct Permission Set").length],
  ["Permission set group assignments", `=COUNTIF('PS Assignments'!$B$2:$B$${permissionSetAssignments.length + 1},"Permission Set Group")`, permissionSetAssignments.filter((record) => assignmentType(record) === "Permission Set Group").length],
  ["Permission set groups", `=COUNTA('PS Groups'!$A$2:$A$${permissionSetGroups.length + 1})`, permissionSetGroups.length],
  ["Public groups", `=COUNTA('Public Groups'!$A$2:$A$${publicGroups.length + 1})`, publicGroups.length],
  ["Queues", `=COUNTA(Queues!$A$2:$A$${queues.length + 1})`, queues.length],
  ["Analytics group candidates", `=COUNTA('Analytics Groups'!$A$2:$A$${analyticsGroups.length + 1})`, analyticsGroups.length],
  ["Normalized access mappings", `=COUNTA('User Mappings'!$A$2:$A$${accessMapRows.length + 1})`, accessMapRows.length],
];
summary.getRange(`D5:D${formulaMetrics.length + 4}`).values = formulaMetrics.map((row) => [row[0]]);
summary.getRange(`E5:E${formulaMetrics.length + 4}`).formulas = formulaMetrics.map((row) => [row[1]]);
summary.getRange(`F5:F${formulaMetrics.length + 4}`).values = formulaMetrics.map((row) => [row[2]]);
summary.getRange(`D4:F${formulaMetrics.length + 4}`).format.borders = { preset: "all", style: "thin", color: theme.border };
summary.getRange(`F5:F${formulaMetrics.length + 4}`).format.fill = theme.light;

summary.getRange("A13:B13").values = [["Assignment classification", "Rows"]];
summary.getRange("A13:B13").format.fill = theme.teal;
summary.getRange("A13:B13").format.font = { bold: true, color: "#FFFFFF" };
const classRows = [
  ["Direct Permission Set", permissionSetAssignments.filter((record) => assignmentType(record) === "Direct Permission Set").length],
  ["Profile Backing Permission Set", permissionSetAssignments.filter((record) => assignmentType(record) === "Profile Backing Permission Set").length],
  ["Permission Set Group", permissionSetAssignments.filter((record) => assignmentType(record) === "Permission Set Group").length],
  ["Permission Set License", permissionSetLicenseAssignments.length],
];
summary.getRange("A14:B17").values = classRows;
summary.getRange("A13:B17").format.borders = { preset: "all", style: "thin", color: theme.border };

summary.getRange("A20:H20").merge();
summary.getRange("A20").values = [["How to use this workbook"]];
summary.getRange("A20:H20").format.fill = theme.navy;
summary.getRange("A20:H20").format.font = { bold: true, color: "#FFFFFF", size: 12 };
summary.getRange("A21:H25").values = [
  ["1", "Start with User Access Matrix for one row per user and joined access lists.", "", "", "", "", "", ""],
  ["2", "Use User Mappings for filterable one-row-per-access records.", "", "", "", "", "", ""],
  ["3", "Use PS Assignments to distinguish direct assignments, profile-backing permission sets, and permission set group assignments.", "", "", "", "", "", ""],
  ["4", "Use Public Group Members and Queue Members for effective membership resolution paths.", "", "", "", "", "", ""],
  ["5", "Read Coverage Notes before interpreting Analytics Groups or Setup User Mappings.", "", "", "", "", "", ""],
];
for (let row = 21; row <= 25; row += 1) summary.mergeCells(`B${row}:H${row}`);
summary.getRange("A21:H25").format.borders = { preset: "all", style: "thin", color: theme.border };
summary.getRange("B21:H25").format.wrapText = true;
summary.getRange("A21:A25").format.fill = theme.cyan;
summary.getRange("A21:A25").format.font = { bold: true, color: theme.navy };
summary.getRange("A:A").format.columnWidth = 26;
summary.getRange("B:B").format.columnWidth = 44;
summary.getRange("C:C").format.columnWidth = 3;
summary.getRange("D:D").format.columnWidth = 34;
summary.getRange("E:E").format.columnWidth = 24;
summary.getRange("F:F").format.columnWidth = 18;
summary.getRange("G:H").format.columnWidth = 12;
summary.freezePanes.freezeRows(2);

const inspection = {
  sheetList: await workbook.inspect({ kind: "sheet", include: "id,name" }),
  summaryRange: await workbook.inspect({ kind: "table", range: "Summary!A1:F17", include: "values,formulas", tableMaxRows: 20, tableMaxCols: 8 }),
  formulaErrors: await workbook.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A", options: { useRegex: true, maxResults: 100 }, summary: "Formula error scan" }),
  counts: {
    users: users.length,
    activeUsers: users.filter((user) => bool(user.IsActive)).length,
    profiles: profiles.length,
    roles: roles.length,
    permissionSets: permissionSets.length,
    permissionSetAssignments: permissionSetAssignments.length,
    directPermissionAssignments: permissionSetAssignments.filter((record) => assignmentType(record) === "Direct Permission Set").length,
    profileBackingAssignments: permissionSetAssignments.filter((record) => assignmentType(record) === "Profile Backing Permission Set").length,
    permissionSetGroupAssignments: permissionSetAssignments.filter((record) => assignmentType(record) === "Permission Set Group").length,
    permissionSetGroups: permissionSetGroups.length,
    psgComponents: permissionSetGroupComponents.length,
    permissionSetLicenses: permissionSetLicenses.length,
    pslAssignments: permissionSetLicenseAssignments.length,
    publicGroups: publicGroups.length,
    publicEffectiveMemberships: publicEffective.rows.length,
    queues: queues.length,
    queueEffectiveMemberships: queueEffective.rows.length,
    analyticsGroups: analyticsGroups.length,
    analyticsEffectiveMemberships: analyticsEffective.rows.length,
    normalizedAccessMappings: accessMapRows.length,
    userManagementSettings: settingsRows.length,
  },
};

const xlsx = await SpreadsheetFile.exportXlsx(workbook);
await xlsx.save(outputPath);
const preview = await workbook.render({ sheetName: "Summary", autoCrop: "all", scale: 1, format: "png" });
await fs.writeFile(previewPath, new Uint8Array(await preview.arrayBuffer()));
await fs.writeFile(inspectionPath, JSON.stringify(inspection, null, 2), "utf8");

console.log(JSON.stringify({ outputPath, previewPath, inspectionPath, counts: inspection.counts }, null, 2));
