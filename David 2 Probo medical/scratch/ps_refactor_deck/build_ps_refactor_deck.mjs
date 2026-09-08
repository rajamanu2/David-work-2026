import fs from "node:fs/promises";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const baseDir = "C:/Users/LIKKI/Documents/ChatGPT/David 2 Probo medical";
const metricsPath = `${baseDir}/scratch/book_v2_update/deck_metrics.json`;
const outputDir = `${baseDir}/outputs/ps_refactor_presentation`;
const finalPptx = `${outputDir}/Probo_Medical_Permission_Set_Refactor_Plan.pptx`;
const previewDir = `${outputDir}/rendered`;

const metrics = JSON.parse(await fs.readFile(metricsPath, "utf8"));

await fs.mkdir(outputDir, { recursive: true });
await fs.mkdir(previewDir, { recursive: true });
await fs.writeFile(
  `${outputDir}/source-notes.txt`,
  [
    "Sources used in deck:",
    "- ProboMedical Salesforce SOQL export: direct PermissionSetAssignment rows, active users, excludes profile-owned permission sets and Permission Set Group assignments.",
    "- Updated workbook: Book v2 - with Direct Permission Sets.xlsx.",
    "- Salesforce org verified as Probo Medical / 00DU0000000LaKoMAK during this workspace session.",
  ].join("\n"),
  "utf8",
);

const W = 1280;
const H = 720;
const frame = { left: 72, top: 54, width: 1136, height: 604 };

const C = {
  navy: "#071C34",
  blue: "#0176D3",
  sky: "#2EAADC",
  pale: "#EAF6FB",
  ink: "#111827",
  slate: "#475569",
  mute: "#64748B",
  line: "#D7DEE8",
  bg: "#F8FBFD",
  white: "#FFFFFF",
  amber: "#F59E0B",
  red: "#DC2626",
  green: "#059669",
  lilac: "#EEF2FF",
};

const deck = Presentation.create({ slideSize: { width: W, height: H } });

function addSlide(title, section = "Permission Set Refactor") {
  const slide = deck.slides.add();
  slide.background.fill = C.bg;
  addText(slide, section.toUpperCase(), frame.left, 26, 420, 22, {
    fontSize: 12,
    bold: true,
    color: C.blue,
    letterSpacing: 1,
  });
  addText(slide, title, frame.left, 54, 970, 88, {
    fontSize: 38,
    bold: true,
    color: C.navy,
  });
  addLine(slide, frame.left, 152, frame.width, C.line, 1);
  addText(slide, "Probo Medical | Salesforce Access Review", frame.left, 680, 460, 18, {
    fontSize: 11,
    color: C.mute,
  });
  return slide;
}

function addText(slide, text, left, top, width, height, style = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    position: { left, top, width, height },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = {
    fontSize: style.fontSize ?? 18,
    bold: style.bold ?? false,
    color: style.color ?? C.ink,
    alignment: style.alignment ?? "left",
  };
  return shape;
}

function addBox(slide, left, top, width, height, opts = {}) {
  const config = {
    geometry: opts.geometry ?? "roundRect",
    position: { left, top, width, height },
    fill: opts.fill ?? C.white,
    line: { style: "solid", fill: opts.line ?? C.line, width: opts.lineWidth ?? 1 },
    shadow: opts.shadow ?? "none",
  };
  if (["rect", "textbox", "roundRect"].includes(config.geometry)) {
    config.borderRadius = opts.borderRadius ?? "rounded-xl";
  }
  return slide.shapes.add(config);
}

function addLine(slide, left, top, width, color = C.line, lineWidth = 1) {
  return slide.shapes.add({
    geometry: "rect",
    position: { left, top, width, height: lineWidth },
    fill: color,
    line: { style: "solid", fill: color, width: 0 },
  });
}

function addKpi(slide, label, value, left, top, width, accent = C.blue) {
  addBox(slide, left, top, width, 116, { fill: C.white, line: "#D9E2EC", shadow: "shadow-sm" });
  addText(slide, String(value), left + 24, top + 18, width - 48, 42, {
    fontSize: 34,
    bold: true,
    color: accent,
  });
  addText(slide, label, left + 24, top + 64, width - 48, 40, {
    fontSize: 16,
    color: C.slate,
  });
}

function addMiniBar(slide, label, value, max, left, top, width, color = C.blue) {
  addText(slide, label, left, top, 310, 22, { fontSize: 15, color: C.ink });
  addBox(slide, left + 330, top + 4, width, 12, { fill: "#E5EEF7", line: "none", borderRadius: "rounded-sm" });
  const barWidth = Math.max(4, Math.round((value / max) * width));
  addBox(slide, left + 330, top + 4, barWidth, 12, { fill: color, line: "none", borderRadius: "rounded-sm" });
  addText(slide, String(value), left + 330 + width + 16, top - 2, 70, 22, {
    fontSize: 14,
    bold: true,
    color: C.slate,
  });
}

function addNotes(slide, lines) {
  slide.speakerNotes.textFrame.setText([
    ...lines,
    "",
    "[Sources]",
    "ProboMedical Salesforce PermissionSetAssignment export generated during this workspace session.",
    "Updated workbook: outputs/book_v2_direct_permission_sets/Book v2 - with Direct Permission Sets.xlsx.",
  ]);
  slide.speakerNotes.setVisible(true);
}

// 1
{
  const slide = deck.slides.add();
  slide.background.fill = C.navy;
  addText(slide, "Probo Medical", 72, 56, 380, 34, { fontSize: 24, bold: true, color: C.white });
  addText(slide, "Permission Set Refactor Plan", 72, 168, 760, 130, {
    fontSize: 58,
    bold: true,
    color: C.white,
  });
  addText(
    slide,
    "A practical path to understand current user access, identify over-access, and redesign Salesforce Permission Sets into a controlled model.",
    76,
    328,
    720,
    92,
    { fontSize: 24, color: "#CFE8FF" },
  );
  addBox(slide, 880, 150, 240, 240, { geometry: "ellipse", fill: "#123B63", line: "#2EAADC", lineWidth: 2 });
  addText(slide, "User", 946, 214, 120, 36, { fontSize: 26, bold: true, color: C.white, alignment: "center" });
  addText(slide, "Permission\nSets", 927, 260, 158, 70, { fontSize: 24, bold: true, color: "#A7E6FF", alignment: "center" });
  addLine(slide, 72, 474, 660, "#2EAADC", 3);
  addText(slide, "Prepared for David Okolo | August 2026", 72, 508, 560, 28, { fontSize: 18, color: "#B9DDF4" });
  addNotes(slide, [
    "Open by framing this as an access cleanup and governance discussion, not a blame discussion.",
    "The data shows current direct Permission Set assignment patterns and where to focus refactoring first.",
  ]);
}

// 2
{
  const slide = addSlide("The access model is visible now, but it is too direct-assignment heavy");
  addText(
    slide,
    "The workbook gives a traceable current-state view: who the user is, which Permission Sets they have, and which Permission Sets carry elevated access. The refactor goal is to turn that evidence into cleaner role-based access.",
    82,
    166,
    960,
    72,
    { fontSize: 23, color: C.slate },
  );
  addKpi(slide, "direct Permission Set assignments", metrics.totalDirectAssignments.toLocaleString(), 92, 280, 230, C.blue);
  addKpi(slide, "users with direct assignments", metrics.usersWithDirectPermissionSets, 346, 280, 230, C.sky);
  addKpi(slide, "unique direct Permission Sets", metrics.uniqueDirectPermissionSets, 600, 280, 230, C.green);
  addKpi(slide, "users with high-risk direct access", metrics.highRiskUsers, 854, 280, 250, C.red);
  addText(
    slide,
    "Executive takeaway: the refactor should start with access concentration and high-risk Permission Sets, then move common bundles into a managed target model.",
    114,
    470,
    960,
    64,
    { fontSize: 24, bold: true, color: C.navy, alignment: "center" },
  );
  addNotes(slide, [
    "Use this slide as the headline: the organization now has measurable access evidence.",
    "High-risk direct access means a direct Permission Set assignment grants Modify All Data, View All Data, or similarly elevated access in the export.",
  ]);
}

// 3
{
  const slide = addSlide("Use the Excel file as a three-sheet evidence chain");
  const x = 104;
  const y = 210;
  const w = 290;
  const h = 170;
  const s1 = addBox(slide, x, y, w, h, { fill: C.white, line: C.blue, lineWidth: 2 });
  const s2 = addBox(slide, x + 380, y, w, h, { fill: C.white, line: C.blue, lineWidth: 2 });
  const s3 = addBox(slide, x + 760, y, w, h, { fill: C.white, line: C.blue, lineWidth: 2 });
  slide.shapes.connect(s1, s2, { fromSide: "right", toSide: "left", kind: "straight", line: { style: "solid", fill: C.blue, width: 2 }, head: { type: "arrow" } });
  slide.shapes.connect(s2, s3, { fromSide: "right", toSide: "left", kind: "straight", line: { style: "solid", fill: C.blue, width: 2 }, head: { type: "arrow" } });
  addText(slide, "Sheet 1", x + 24, y + 24, w - 48, 26, { fontSize: 18, bold: true, color: C.blue });
  addText(slide, "Users / Summary", x + 24, y + 56, w - 48, 32, { fontSize: 24, bold: true, color: C.navy });
  addText(slide, "One row per user; profile, role, manager, title, company, direct Permission Set list and count.", x + 24, y + 100, w - 48, 58, { fontSize: 16, color: C.slate });
  addText(slide, "Sheet 2", x + 404, y + 24, w - 48, 26, { fontSize: 18, bold: true, color: C.blue });
  addText(slide, "Direct Permission Sets", x + 404, y + 56, w - 48, 32, { fontSize: 24, bold: true, color: C.navy });
  addText(slide, "One row per direct assignment; the proof behind the summary counts.", x + 404, y + 100, w - 48, 58, { fontSize: 16, color: C.slate });
  addText(slide, "Sheet 3", x + 784, y + 24, w - 48, 26, { fontSize: 18, bold: true, color: C.blue });
  addText(slide, "Permission Set Details", x + 784, y + 56, w - 48, 32, { fontSize: 24, bold: true, color: C.navy });
  addText(slide, "Permission flags and object/field access; used to explain what each assignment actually grants.", x + 784, y + 100, w - 48, 58, { fontSize: 16, color: C.slate });
  addText(slide, "Boss explanation: this creates traceability from User -> Assigned Permission Set -> Actual Permissions.", 170, 476, 900, 44, { fontSize: 25, bold: true, color: C.navy, alignment: "center" });
  addNotes(slide, [
    "Explain the sheets one by one. Sheet 1 is the executive lookup. Sheet 2 is the assignment proof. Sheet 3 is the control detail used to understand what each Permission Set grants.",
  ]);
}

// 4
{
  const slide = addSlide("Direct Permission Sets reveal the first cleanup candidates");
  const top = metrics.topUsersByDirectPS.slice(0, 8);
  const max = top[0].directPermissionSetCount;
  top.forEach((u, i) => {
    const label = `${u.name}  (${u.profile})`;
    addMiniBar(slide, label, u.directPermissionSetCount, max, 90, 185 + i * 46, 360, i < 3 ? C.red : C.blue);
  });
  addBox(slide, 835, 188, 260, 250, { fill: C.pale, line: "#B9DDF4" });
  addText(slide, "What this means", 862, 216, 210, 32, { fontSize: 24, bold: true, color: C.navy });
  addText(slide, "Users with 50+ direct Permission Sets are hard to explain, hard to audit, and likely include historical one-off access.", 862, 268, 204, 116, { fontSize: 19, color: C.slate });
  addText(slide, "Start review threshold: 20+ direct Permission Sets.", 862, 398, 204, 42, { fontSize: 18, bold: true, color: C.blue });
  addNotes(slide, [
    "This is the access concentration story. The top users have a large number of direct Permission Sets, which makes their access difficult to reason about.",
  ]);
}

// 5
{
  const slide = addSlide("High-risk access is concentrated enough to review quickly");
  addKpi(slide, "users with Super User", metrics.superUserUsers, 110, 194, 240, C.red);
  addKpi(slide, "users with Waive MFA", metrics.waiveMfaUsers, 380, 194, 240, C.amber);
  addKpi(slide, "high-risk direct assignments", metrics.highRiskDirectAssignments, 650, 194, 270, C.red);
  addKpi(slide, "high-risk users", metrics.highRiskUsers, 950, 194, 210, C.red);
  const risks = metrics.riskPermissionSets.slice(0, 7);
  const max = Math.max(...risks.map((r) => r.assignedUsers));
  risks.forEach((r, i) => {
    addMiniBar(slide, r.permissionSet.replaceAll('"', ""), r.assignedUsers, max, 124, 386 + i * 34, 300, i < 4 ? C.red : C.amber);
  });
  addText(slide, "Priority: prove who truly needs these access paths, remove stale exceptions, and convert repeatable needs into governed bundles.", 850, 392, 300, 126, { fontSize: 22, bold: true, color: C.navy });
  addNotes(slide, [
    "High-risk review can begin immediately because the number of users is manageable compared with the full assignment set.",
    "Waive MFA deserves special attention because it intersects with the current Salesforce access/MFA issue.",
  ]);
}

// 6
{
  const slide = addSlide("Common Permission Sets should become governed access bundles");
  const top = metrics.topPermissionSetsByUserCount.slice(0, 8);
  const max = top[0].assignedUsers;
  top.forEach((p, i) => {
    addMiniBar(slide, p.permissionSet, p.assignedUsers, max, 118, 185 + i * 42, 340, C.blue);
  });
  addText(slide, "Large-repeat Permission Sets are good candidates for Permission Set Groups or persona bundles because many users need the same access pattern.", 895, 206, 245, 150, { fontSize: 21, bold: true, color: C.navy });
  addText(slide, "Refactor rule: if a Permission Set is assigned broadly and always travels with the same neighboring sets, bundle it by job function instead of assigning it one-by-one.", 895, 392, 255, 126, { fontSize: 18, color: C.slate });
  addNotes(slide, [
    "This slide shifts from risk to opportunity. Broadly used Permission Sets may be legitimate, but the assignment model should be governed.",
  ]);
}

// 7
{
  const slide = addSlide("The current pattern mixes baseline access, job access, and exceptions");
  const cols = [
    ["Baseline", "Profile and license provide the minimum access a user needs to enter Salesforce."],
    ["Job access", "Permission Sets were added directly as the business needed more capability."],
    ["Exceptions", "Super User, View All, Modify All, Waive MFA, and admin-like rights sit beside normal access."],
  ];
  cols.forEach((c, i) => {
    const left = 114 + i * 365;
    addBox(slide, left, 206, 300, 230, { fill: i === 2 ? "#FFF7ED" : C.white, line: i === 2 ? "#FDBA74" : C.line });
    addText(slide, c[0], left + 28, 236, 244, 34, { fontSize: 26, bold: true, color: i === 2 ? "#B45309" : C.navy });
    addText(slide, c[1], left + 28, 294, 240, 102, { fontSize: 19, color: C.slate });
  });
  addText(slide, "Refactor objective: separate these layers so access can be approved, explained, and removed cleanly.", 160, 500, 860, 44, { fontSize: 25, bold: true, color: C.navy, alignment: "center" });
  addNotes(slide, [
    "Explain that direct assignment is not automatically wrong. The problem is when normal access, job access, and risky exceptions are all managed the same way.",
  ]);
}

// 8
{
  const slide = addSlide("Target model: make access explainable");
  const user = addBox(slide, 100, 252, 170, 78, { fill: C.white, line: C.blue, lineWidth: 2 });
  const profile = addBox(slide, 345, 170, 210, 78, { fill: C.white, line: C.sky, lineWidth: 2 });
  const group = addBox(slide, 620, 156, 250, 92, { fill: C.white, line: C.green, lineWidth: 2 });
  const addon = addBox(slide, 620, 334, 250, 92, { fill: C.white, line: C.blue, lineWidth: 2 });
  const exception = addBox(slide, 940, 170, 230, 112, { fill: "#FFF7ED", line: C.amber, lineWidth: 2 });
  slide.shapes.connect(user, profile, { fromSide: "right", toSide: "left", kind: "elbow", line: { style: "solid", fill: C.blue, width: 2 } });
  slide.shapes.connect(profile, group, { fromSide: "right", toSide: "left", kind: "elbow", line: { style: "solid", fill: C.green, width: 2 } });
  slide.shapes.connect(user, addon, { fromSide: "right", toSide: "left", kind: "elbow", line: { style: "solid", fill: C.blue, width: 2 } });
  slide.shapes.connect(group, exception, { fromSide: "right", toSide: "left", kind: "elbow", line: { style: "dashed", fill: C.amber, width: 2 } });
  addText(slide, "User", 124, 276, 122, 28, { fontSize: 24, bold: true, color: C.navy, alignment: "center" });
  addText(slide, "Profile", 377, 195, 150, 28, { fontSize: 24, bold: true, color: C.navy, alignment: "center" });
  addText(slide, "Permission Set\nGroup", 645, 174, 200, 52, { fontSize: 22, bold: true, color: C.navy, alignment: "center" });
  addText(slide, "Job bundle", 656, 224, 178, 22, { fontSize: 15, color: C.slate, alignment: "center" });
  addText(slide, "Add-on\nPermission Set", 648, 350, 196, 56, { fontSize: 22, bold: true, color: C.navy, alignment: "center" });
  addText(slide, "Small, named need", 668, 404, 150, 20, { fontSize: 15, color: C.slate, alignment: "center" });
  addText(slide, "Exception\nAccess", 968, 188, 175, 56, { fontSize: 23, bold: true, color: "#B45309", alignment: "center" });
  addText(slide, "Time-bound approval + owner + review date", 970, 244, 168, 34, { fontSize: 15, color: "#92400E", alignment: "center" });
  addText(slide, "Class-style rule: users inherit baseline access, receive job bundles, and only get exceptions through a controlled process.", 154, 500, 920, 48, { fontSize: 24, bold: true, color: C.navy, alignment: "center" });
  addNotes(slide, [
    "This is the target-state class diagram. Keep it simple: profile is baseline, Permission Set Groups are job bundles, direct add-ons are limited, exceptions are controlled.",
  ]);
}

// 9
{
  const slide = addSlide("Refactor in four controlled workstreams");
  const steps = [
    ["1. Inventory", "Freeze the evidence baseline and identify high-count, high-risk, and stale assignments."],
    ["2. Design", "Create role bundles by job function and separate add-ons from exceptions."],
    ["3. Migrate", "Pilot with one business group, compare before/after access, then expand."],
    ["4. Govern", "Add owners, approvals, review cadence, and removal rules for exceptions."],
  ];
  steps.forEach((s, i) => {
    const left = 120 + (i % 2) * 520;
    const top = 190 + Math.floor(i / 2) * 190;
    addBox(slide, left, top, 440, 128, { fill: C.white, line: i === 0 ? C.blue : C.line });
    addText(slide, s[0], left + 28, top + 24, 220, 30, { fontSize: 25, bold: true, color: C.blue });
    addText(slide, s[1], left + 28, top + 66, 370, 44, { fontSize: 18, color: C.slate });
  });
  addNotes(slide, [
    "Recommend sequencing: do not migrate everyone at once. Start with evidence and high-risk review, then pilot a group.",
  ]);
}

// 10
{
  const slide = addSlide("Refactor rules keep the cleanup from becoming another one-off cycle");
  const rules = [
    ["Threshold review", "Any user with 20+ direct Permission Sets requires business-owner review."],
    ["Critical access", "Super User, Waive MFA, Modify All Data, and View All Data require named approval."],
    ["Bundle first", "Common access patterns move into Permission Set Groups by job function."],
    ["Exception expiry", "Exception access must have owner, reason, and review date."],
    ["Naming standard", "Permission Sets should identify function, scope, and risk level."],
  ];
  rules.forEach((r, i) => {
    addText(slide, r[0], 120, 170 + i * 76, 260, 28, { fontSize: 22, bold: true, color: C.navy });
    addText(slide, r[1], 410, 170 + i * 76, 650, 36, { fontSize: 19, color: C.slate });
    addLine(slide, 120, 218 + i * 76, 940, C.line, 1);
  });
  addNotes(slide, [
    "This slide gives the boss decision criteria. These rules can become the access governance policy.",
  ]);
}

// 11
{
  const slide = addSlide("A phased plan reduces risk while access is being cleaned up");
  const phases = [
    ["0-30 days", "Stabilize", "Validate workbook, review Super User/Waive MFA, identify top 20 high-count users."],
    ["31-60 days", "Design", "Build persona bundles for Sales, QC, Shipping, FSL, Purchasing, and admin groups."],
    ["61-90 days", "Migrate", "Pilot, compare before/after, remove duplicate direct assignments, document approvals."],
  ];
  phases.forEach((p, i) => {
    const left = 112 + i * 354;
    addBox(slide, left, 210, 300, 235, { fill: i === 0 ? C.pale : C.white, line: i === 0 ? C.blue : C.line });
    addText(slide, p[0], left + 26, 236, 220, 26, { fontSize: 22, bold: true, color: C.blue });
    addText(slide, p[1], left + 26, 276, 220, 34, { fontSize: 28, bold: true, color: C.navy });
    addText(slide, p[2], left + 26, 330, 240, 82, { fontSize: 18, color: C.slate });
  });
  addText(slide, "Success measure: fewer direct assignments per user, fewer unmanaged high-risk exceptions, and a repeatable approval path.", 152, 512, 900, 46, { fontSize: 24, bold: true, color: C.navy, alignment: "center" });
  addNotes(slide, [
    "Use this as the implementation path. The first month is not about perfection; it is about control and prioritization.",
  ]);
}

// 12
{
  const slide = addSlide("David can ask for approval on a focused access refactor");
  addText(slide, "Recommended decision", 112, 178, 300, 30, { fontSize: 24, bold: true, color: C.blue });
  addText(slide, "Approve a controlled Permission Set refactor beginning with high-risk users and the highest-count direct assignments.", 112, 224, 760, 68, { fontSize: 30, bold: true, color: C.navy });
  const asks = [
    "Name business owners for Sales, QC, Shipping, FSL, Purchasing, and Admin access.",
    "Approve review of Super User, Waive MFA, Modify All Data, and View All Data assignments.",
    "Allow a pilot migration from direct assignments into governed job bundles.",
  ];
  asks.forEach((a, i) => {
    addBox(slide, 136, 340 + i * 72, 28, 28, { geometry: "ellipse", fill: C.blue, line: "none" });
    addText(slide, String(i + 1), 143, 344 + i * 72, 14, 18, { fontSize: 14, bold: true, color: C.white, alignment: "center" });
    addText(slide, a, 190, 335 + i * 72, 780, 42, { fontSize: 21, color: C.slate });
  });
  addNotes(slide, [
    "Close with a clear ask. David should ask for approval to begin the focused refactor and business-owner review.",
  ]);
}

for (const [i, slide] of deck.slides.items.entries()) {
  const png = await deck.export({ slide, format: "png", scale: 1 });
  await fs.writeFile(`${previewDir}/slide-${String(i + 1).padStart(2, "0")}.png`, new Uint8Array(await png.arrayBuffer()));
  const layout = await slide.export({ format: "layout" });
  await fs.writeFile(`${previewDir}/slide-${String(i + 1).padStart(2, "0")}.layout.json`, await layout.text());
}

const montage = await deck.export({ format: "webp", montage: true, scale: 1 });
await fs.writeFile(`${outputDir}/deck-montage.webp`, new Uint8Array(await montage.arrayBuffer()));

const snapshot = await deck.inspect({ kind: "slide,textbox,shape,chart,notes", maxChars: 16000 });
await fs.writeFile(`${outputDir}/deck-inspect.ndjson`, snapshot.ndjson, "utf8");

const pptx = await PresentationFile.exportPptx(deck);
await pptx.save(finalPptx);

console.log(JSON.stringify({ finalPptx, slideCount: deck.slides.items.length }, null, 2));
