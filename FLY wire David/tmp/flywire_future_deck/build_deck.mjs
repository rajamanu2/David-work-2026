import fs from "node:fs/promises";
import path from "node:path";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const BUILD_DIR = "C:/Users/LIKKI/Documents/ChatGPT/david/tmp/flywire_future_deck";
const OUTPUT = "C:/Users/LIKKI/Documents/ChatGPT/david/output/presentations/Flywire_Future_State_Implementation_Blueprint.pptx";
const RENDER_DIR = path.join(BUILD_DIR, "rendered");

const C = {
  canvas: "#FFFFFF",
  ink: "#111111",
  muted: "#5B6573",
  panel: "#EDEDED",
  panel2: "#F6F7F8",
  rule: "#B8BCC4",
  accent: "#6DCBF4",
  accentStrong: "#3D8DFF",
  accentPale: "#D0EDFA",
  success: "#1F8A70",
  warning: "#D97706",
  danger: "#C2413B",
};

const presentation = Presentation.create({ slideSize: { width: 1280, height: 720 } });

function addShape(slide, geometry, x, y, w, h, fill = "none", lineFill = "none", lineWidth = 0, name = undefined) {
  return slide.shapes.add({
    geometry,
    ...(name ? { name } : {}),
    position: { left: x, top: y, width: w, height: h },
    fill,
    line: { style: "solid", fill: lineFill, width: lineWidth },
  });
}

function addText(slide, text, x, y, w, h, opts = {}) {
  const box = addShape(slide, "textbox", x, y, w, h, opts.fill || "none", opts.line || "none", opts.lineWidth || 0, opts.name);
  box.text = text;
  box.text.style = {
    fontSize: opts.fontSize || 20,
    typeface: "Arial",
    color: opts.color || C.ink,
    bold: opts.bold || false,
    italic: opts.italic || false,
    alignment: opts.align || "left",
    verticalAlignment: opts.valign || "top",
    autoFit: opts.autoFit || "shrinkText",
    wrap: "square",
  };
  return box;
}

function addTitle(slide, title, number, kicker = "IMPLEMENTATION BLUEPRINT") {
  addText(slide, kicker, 42, 28, 390, 26, { fontSize: 14, bold: true, color: C.muted, autoFit: "none" });
  addText(slide, title, 42, 58, 1188, 94, { fontSize: 38, bold: true, autoFit: "shrinkText" });
  addShape(slide, "straightConnector1", 42, 156, 1196, 1, "none", C.rule, 1);
  addText(slide, String(number).padStart(2, "0"), 1180, 670, 56, 24, { fontSize: 13, color: C.muted, align: "right", autoFit: "none" });
}

function addFooter(slide, text = "Flywire future-state implementation") {
  addText(slide, text, 42, 671, 600, 20, { fontSize: 11, color: C.muted, autoFit: "none" });
}

function addNotes(slide, sources, presenter = "") {
  const notes = [presenter, "", "[Sources]", ...sources.map((s) => `- ${s}`), "[/Sources]"].join("\n");
  slide.speakerNotes.textFrame.setText(notes);
}

function addBulletList(slide, items, x, y, w, h, opts = {}) {
  const text = items.map((item) => `• ${item}`).join("\n");
  return addText(slide, text, x, y, w, h, { fontSize: opts.fontSize || 20, color: opts.color || C.ink, autoFit: "shrinkText" });
}

function addPanel(slide, x, y, w, h, opts = {}) {
  return addShape(slide, "rect", x, y, w, h, opts.fill || C.panel2, opts.line || C.rule, opts.lineWidth ?? 1, opts.name);
}

async function readImage(name) {
  const bytes = await fs.readFile(path.join(BUILD_DIR, name));
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
}

async function addImage(slide, name, x, y, w, h, alt, fit = "contain") {
  const blob = await readImage(name);
  slide.images.add({ blob, contentType: "image/png", alt, fit, position: { left: x, top: y, width: w, height: h } });
}

function addSectionLabel(slide, text, x, y, w = 240) {
  addText(slide, text.toUpperCase(), x, y, w, 24, { fontSize: 13, bold: true, color: C.accentStrong, autoFit: "none" });
}

function addMetric(slide, value, label, x, y, w) {
  addText(slide, value, x, y, w, 58, { fontSize: 42, bold: true, color: C.accentStrong, autoFit: "none" });
  addText(slide, label, x, y + 60, w, 56, { fontSize: 16, color: C.muted });
}

function addFlowArrow(slide, x, y, w, h = 2) {
  const arrow = addShape(slide, "rightArrow", x, y, w, h + 18, C.accentStrong, "none", 0);
  return arrow;
}

// 1 — Cover
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addText(slide, "FLYWIRE", 42, 38, 220, 28, { fontSize: 15, bold: true, color: C.accentStrong, autoFit: "none" });
  addText(slide, "Future-State\nImplementation Blueprint", 42, 176, 820, 212, { fontSize: 56, bold: true, autoFit: "none" });
  addText(slide, "Clean data model, governed data flow, service design, controls and delivery roadmap", 44, 430, 780, 76, { fontSize: 25, color: C.muted });
  addPanel(slide, 930, 152, 250, 332, { fill: C.accentPale, line: "none" });
  addText(slide, "ONE\nMODEL", 964, 204, 180, 104, { fontSize: 38, bold: true, color: C.ink, autoFit: "none" });
  addText(slide, "Customer\nQuote\nContract\nRevenue", 966, 348, 180, 108, { fontSize: 20, color: C.ink, autoFit: "none" });
  addText(slide, "Team discussion deck • August 2026", 44, 646, 500, 26, { fontSize: 16, color: C.muted, autoFit: "none" });
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 4-10",
    "C:/Users/LIKKI/Documents/ChatGPT/david/force-app/main/default",
  ]);
}

// 2 — Central idea
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "A single operating model connects customer, quote, contract and revenue data", 2);
  addText(slide, "The implementation is organized around one governed commercial record chain. Every downstream process consumes the same validated data instead of reconstructing meaning in each system.", 42, 176, 760, 92, { fontSize: 24 });
  const labels = ["CUSTOMER", "OPPORTUNITY", "QUOTE", "CONTRACT", "ORDER", "REVENUE"];
  labels.forEach((label, i) => {
    const x = 46 + i * 198;
    addPanel(slide, x, 326, 160, 112, { fill: i === 2 || i === 3 ? C.accentPale : C.panel2, line: C.rule });
    addText(slide, label, x + 8, 350, 144, 30, { fontSize: 14, bold: true, align: "center", valign: "mid", autoFit: "shrinkText" });
    if (i < labels.length - 1) addFlowArrow(slide, x + 162, 369, 34, 2);
  });
  addMetric(slide, "1", "governed customer identity", 42, 510, 260);
  addMetric(slide, "1", "quote-to-contract lifecycle", 360, 510, 260);
  addMetric(slide, "1", "reconciled revenue view", 680, 510, 260);
  addMetric(slide, "0", "silent downstream handoffs", 992, 510, 230);
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 5-6 and 18",
  ]);
}

// 3 — Requirement coverage
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "The blueprint covers all three transformation initiatives in one design", 3);
  const columns = [
    { x: 42, title: "UNIFIED FOUNDATION", items: ["Golden customer and hierarchy", "One product and pricing model", "Governed integration events", "Single reporting definitions"] },
    { x: 446, title: "QUOTE TO CASH", items: ["Guided configuration", "Tier, ramp and term pricing", "Risk-based approvals", "ARR, MRR and TCV", "Proposal and order handoff"] },
    { x: 850, title: "CONTRACT LIFECYCLE", items: ["Contract creation and repository", "Clause, approval and signature", "Account/entity association", "Obligation and status reporting", "Renewal and amendment controls"] },
  ];
  columns.forEach((col, i) => {
    addText(slide, `0${i + 1}`, col.x, 190, 60, 48, { fontSize: 36, bold: true, color: C.accentStrong, autoFit: "none" });
    addText(slide, col.title, col.x, 250, 350, 42, { fontSize: 22, bold: true, autoFit: "none" });
    addShape(slide, "straightConnector1", col.x, 300, 350, 1, "none", C.rule, 1);
    addBulletList(slide, col.items, col.x, 326, 350, 252, { fontSize: 20 });
  });
  addText(slide, "Shared controls: identity • security • audit • data quality • release governance • reconciliation", 42, 612, 1196, 40, { fontSize: 20, bold: true, color: C.ink, align: "center" });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 6-10",
  ]);
}

// 4 — Principles
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Six principles keep the data model, services and process states synchronized", 4);
  const principles = [
    ["01", "Single source of truth", "Each business concept has one authoritative owner and one stable key."],
    ["02", "Configuration over branching", "Pricing and approval policies live in governed rules, not scattered code."],
    ["03", "State drives behavior", "Editability, approvals, documents and handoffs depend on explicit lifecycle states."],
    ["04", "Events carry correlation", "Every downstream message can be retried, traced and reconciled."],
    ["05", "Metrics use one engine", "ARR, MRR, TCV and one-time revenue share versioned calculation inputs."],
    ["06", "Controls ship with features", "Security, audit, tests and rollback are part of every capability."],
  ];
  principles.forEach((p, i) => {
    const row = Math.floor(i / 3);
    const col = i % 3;
    const x = 42 + col * 398;
    const y = 184 + row * 218;
    addText(slide, p[0], x, y, 56, 38, { fontSize: 27, bold: true, color: C.accentStrong, autoFit: "none" });
    addText(slide, p[1], x + 72, y, 300, 34, { fontSize: 21, bold: true, autoFit: "none" });
    addText(slide, p[2], x + 72, y + 50, 300, 98, { fontSize: 18, color: C.muted });
    addShape(slide, "straightConnector1", x, y + 160, 350, 1, "none", C.rule, 1);
  });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 18 and 39-46",
    "C:/Users/LIKKI/Documents/ChatGPT/david/force-app/main/default",
  ]);
}

// 5 — Architecture
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "The target architecture separates experience, orchestration, integration and enterprise platforms", 5);
  await addImage(slide, "integration_architecture.png", 42, 166, 820, 478, "PlantUML target integration architecture");
  addSectionLabel(slide, "WHY THIS SHAPE", 900, 184, 280);
  addBulletList(slide, [
    "One CRM experience for sales, deal desk and customer success",
    "Orchestration owns commercial process; integrations do not",
    "Integration layer handles transformation, retry and correlation",
    "Finance acknowledgements flow back into reconciliation",
    "Reporting consumes governed CRM and data-platform definitions",
  ], 900, 222, 300, 330, { fontSize: 18 });
  addText(slide, "Design rule", 900, 570, 130, 24, { fontSize: 15, bold: true, color: C.accentStrong, autoFit: "none" });
  addText(slide, "No point-to-point integration may silently change the commercial meaning of a record.", 900, 602, 300, 54, { fontSize: 17, bold: true });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 18, 48-49",
    "C:/Users/LIKKI/Documents/ChatGPT/david/tmp/flywire_future_deck/integration_architecture.puml",
  ]);
}

// 6 — Canonical data model
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "The canonical model gives each commercial concept one governed home", 6);
  addSectionLabel(slide, "COMMERCIAL CONFIGURATION", 42, 174, 360);
  addSectionLabel(slide, "APPROVAL, CONTRACT AND EXECUTION", 656, 174, 430);
  await addImage(slide, "data_model_commercial.png", 42, 204, 570, 432, "PlantUML commercial configuration data model");
  await addImage(slide, "data_model_execution.png", 656, 204, 570, 432, "PlantUML approval contract and execution data model");
  addFooter(slide, "PlantUML source is included in the implementation working set");
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 18, 23-31 and 39-46",
    "C:/Users/LIKKI/Documents/ChatGPT/david/tmp/flywire_future_deck/data_model_commercial.puml",
    "C:/Users/LIKKI/Documents/ChatGPT/david/tmp/flywire_future_deck/data_model_execution.puml",
  ]);
}

// 7 — Ownership table
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Ownership rules prevent duplicate truth and uncontrolled updates", 7);
  const headers = ["DOMAIN", "AUTHORITATIVE RECORD", "OWNER", "KEY CONTROL"];
  const rows = [
    ["Customer", "CustomerAccount + LegalEntity", "CRM data steward", "Golden key, hierarchy and match policy"],
    ["Product", "Product + PriceBookEntry", "Product operations", "SKU uniqueness, eligibility and effective dates"],
    ["Commercial", "Quote + QuoteLine + PricingSchedule", "Sales / deal desk", "Version, state, approval and edit locks"],
    ["Contract", "Contract + ContractLine", "Legal / commercial operations", "Accepted terms, entity and obligation integrity"],
    ["Order", "Order + IntegrationEvent", "Operations", "Correlation, acknowledgement and retry status"],
    ["Revenue", "RevenueMetrics + financial actuals", "Finance", "Versioned formula and variance reconciliation"],
  ];
  const xs = [42, 238, 575, 810];
  const ws = [186, 327, 225, 428];
  headers.forEach((h, i) => addText(slide, h, xs[i], 182, ws[i], 36, { fontSize: 14, bold: true, color: C.muted, autoFit: "none" }));
  rows.forEach((row, r) => {
    const y = 226 + r * 67;
    addPanel(slide, 42, y, 1196, 58, { fill: r % 2 === 0 ? C.panel2 : C.canvas, line: C.rule });
    row.forEach((cell, i) => addText(slide, cell, xs[i] + 8, y + 8, ws[i] - 16, 42, { fontSize: i === 0 ? 17 : 16, bold: i === 0 }));
  });
  addText(slide, "Every integration reads from an authoritative record and writes only through an owned service or approved reconciliation path.", 42, 640, 1140, 30, { fontSize: 18, bold: true });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 18 and 41-46",
  ]);
}

// 8 — End-to-end flow
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Data moves forward only after validation and controlled decisions", 8);
  const flow = [
    ["IDENTIFY", "Match customer\nand entity"],
    ["CONFIGURE", "Select product\nand price"],
    ["CALCULATE", "Schedule value\nand metrics"],
    ["DECIDE", "Validate and\napprove"],
    ["COMMIT", "Generate, sign\nand contract"],
    ["RECONCILE", "Order, bill\nand compare"],
  ];
  flow.forEach((f, i) => {
    const x = 42 + i * 198;
    addPanel(slide, x, 210, 164, 124, { fill: i >= 3 ? C.accentPale : C.panel2, line: i >= 3 ? C.accentStrong : C.rule });
    addText(slide, f[0], x + 10, 232, 144, 28, { fontSize: 16, bold: true, align: "center", autoFit: "none" });
    addText(slide, f[1], x + 12, 280, 140, 44, { fontSize: 15, color: C.muted, align: "center" });
    if (i < flow.length - 1) addFlowArrow(slide, x + 166, 260, 30, 2);
  });
  addSectionLabel(slide, "CONTROL GATES", 42, 390, 300);
  const controls = [
    ["01", "Identity", "Golden account, hierarchy and legal entity are resolved."],
    ["02", "Commercial policy", "Product, pricing, term, risk and completeness pass."],
    ["03", "Approval", "Required personas decide; material values remain locked."],
    ["04", "Acceptance", "Proposal and contract reference the approved quote version."],
    ["05", "Reconciliation", "Downstream acknowledgement and financial variance are recorded."],
  ];
  controls.forEach((c, i) => {
    const x = 42 + (i % 3) * 398;
    const y = 430 + Math.floor(i / 3) * 92;
    addText(slide, c[0], x, y, 46, 30, { fontSize: 21, bold: true, color: C.accentStrong, autoFit: "none" });
    addText(slide, c[1], x + 56, y, 180, 26, { fontSize: 18, bold: true, autoFit: "none" });
    addText(slide, c[2], x + 56, y + 30, 300, 48, { fontSize: 15, color: C.muted });
  });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 23-31",
    "C:/Users/LIKKI/Documents/ChatGPT/david/tmp/flywire_future_deck/data_flow.puml",
  ]);
}

// 9 — State model
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "One quote state model governs edits, approvals, documents and downstream handoffs", 9);
  const states = ["DRAFT", "CONFIGURED", "VALIDATED", "APPROVED", "PROPOSAL", "CONTRACTED", "ORDERED", "ACTIVATED"];
  states.forEach((state, i) => {
    const x = 42 + i * 149;
    addPanel(slide, x, 230, 120, 70, { fill: i >= 3 ? C.accentPale : C.panel2, line: i >= 3 ? C.accentStrong : C.rule });
    addText(slide, state, x + 8, 252, 104, 26, { fontSize: 14, bold: true, align: "center", autoFit: "shrinkText" });
    if (i < states.length - 1) addFlowArrow(slide, x + 122, 248, 24, 2);
  });
  addShape(slide, "straightConnector1", 360, 322, 1, 90, "none", C.accentStrong, 2);
  addPanel(slide, 286, 414, 150, 62, { fill: C.accentPale, line: C.accentStrong });
  addText(slide, "PENDING APPROVAL", 296, 434, 130, 24, { fontSize: 14, bold: true, align: "center", autoFit: "shrinkText" });
  addText(slide, "Required after validation when policy thresholds are triggered", 470, 418, 350, 50, { fontSize: 17, color: C.muted });
  addShape(slide, "straightConnector1", 1010, 322, 1, 90, "none", C.accentStrong, 2);
  addPanel(slide, 930, 414, 160, 62, { fill: C.panel2, line: C.rule });
  addText(slide, "AMENDMENT", 942, 434, 136, 24, { fontSize: 15, bold: true, align: "center", autoFit: "none" });
  addText(slide, "Material change returns to validation and approval", 1110, 418, 120, 64, { fontSize: 15, color: C.muted });
  addSectionLabel(slide, "STATE GUARANTEES", 42, 526, 300);
  addText(slide, "Draft permits editing • Pending Approval locks commercial values • Proposal references an immutable approved version • Contracted and Ordered require acknowledged handoffs", 42, 566, 1160, 54, { fontSize: 18, bold: true, align: "center" });
  addText(slide, "Status is behavior—not a label.", 460, 630, 360, 32, { fontSize: 23, bold: true, color: C.accentStrong, align: "center" });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 23, 28-31",
    "C:/Users/LIKKI/Documents/ChatGPT/david/tmp/flywire_future_deck/state_model.puml",
  ]);
}

// 10 — Approval design
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Approval rules are configuration, not hard-coded branching", 10);
  addSectionLabel(slide, "RULE INPUT", 42, 184, 260);
  addPanel(slide, 42, 220, 350, 346, { fill: C.panel2 });
  addBulletList(slide, [
    "Rule key and effective dates",
    "Active flag and priority",
    "Discount / ARR / term thresholds",
    "Product, entity and currency scope",
    "Risk and exception categories",
    "Required persona and sequence",
    "Parallel-group identifier",
    "Human-readable reason template",
  ], 66, 246, 300, 286, { fontSize: 18 });
  addFlowArrow(slide, 412, 360, 70, 4);
  addSectionLabel(slide, "EVALUATION", 500, 184, 260);
  addPanel(slide, 500, 220, 300, 346, { fill: C.accentPale, line: C.accentStrong });
  addText(slide, "Quote Context", 528, 248, 240, 32, { fontSize: 22, bold: true, align: "center", autoFit: "none" });
  addText(slide, "+", 610, 298, 80, 34, { fontSize: 28, bold: true, align: "center", autoFit: "none" });
  addText(slide, "Active Rules", 528, 338, 240, 32, { fontSize: 22, bold: true, align: "center", autoFit: "none" });
  addText(slide, "↓", 610, 386, 80, 34, { fontSize: 28, bold: true, align: "center", autoFit: "none" });
  addText(slide, "Approval Plan", 528, 432, 240, 34, { fontSize: 23, bold: true, color: C.accentStrong, align: "center", autoFit: "none" });
  addText(slide, "ordered steps • parallel groups • reasons • missing approvers", 524, 482, 252, 52, { fontSize: 16, align: "center" });
  addFlowArrow(slide, 820, 360, 70, 4);
  addSectionLabel(slide, "CONTROLLED ACTION", 908, 184, 300);
  addPanel(slide, 908, 220, 300, 346, { fill: C.panel2 });
  addBulletList(slide, [
    "Create approval request",
    "Resolve approvers by persona",
    "Lock commercial values",
    "Record each decision",
    "Notify only required participants",
    "Recall or reject with reason",
    "Unlock through controlled transition",
    "Retain audit history",
  ], 932, 246, 252, 286, { fontSize: 18 });
  addText(slide, "Phase 1 can run in evaluation-only mode before submission is enabled.", 42, 610, 1166, 38, { fontSize: 20, bold: true, color: C.accentStrong, align: "center" });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 23-26",
    "C:/Users/LIKKI/Documents/ChatGPT/david/force-app/main/default",
  ]);
}

// 11 — Approval class diagram
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Approval services isolate policy decisions from lifecycle execution", 11);
  await addImage(slide, "approval_class_diagram.png", 42, 170, 1196, 346, "PlantUML approval service class diagram");
  const notes = [
    ["Context", "Build one immutable view of quote, line, customer and risk inputs."],
    ["Decision", "Evaluate active rules and produce an explainable approval plan."],
    ["Lifecycle", "Create requests, lock values, record decisions and preserve audit."],
  ];
  notes.forEach((n, i) => {
    const x = 42 + i * 398;
    addText(slide, n[0], x, 534, 350, 30, { fontSize: 21, bold: true, color: C.accentStrong, autoFit: "none" });
    addText(slide, n[1], x, 572, 350, 62, { fontSize: 17, color: C.muted });
  });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 23-26",
    "C:/Users/LIKKI/Documents/ChatGPT/david/tmp/flywire_future_deck/approval_class_diagram.puml",
  ]);
}

// 12 — Pricing & metrics
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Pricing schedules and revenue metrics share one versioned calculation model", 12);
  const stages = [
    ["CATALOGUE", "Product, bundle, eligibility"],
    ["PRICE BOOK", "Currency, list price, dates"],
    ["PRICING RULE", "Tier, ramp, term, exception"],
    ["QUOTE LINE", "Quantity and net price"],
    ["SCHEDULE", "Period-level amount"],
    ["METRICS", "ARR, MRR, TCV, one-time"],
  ];
  stages.forEach((s, i) => {
    const x = 42 + i * 198;
    addPanel(slide, x, 210, 166, 128, { fill: i >= 4 ? C.accentPale : C.panel2, line: i >= 4 ? C.accentStrong : C.rule });
    addText(slide, s[0], x + 10, 230, 146, 28, { fontSize: 16, bold: true, align: "center", autoFit: "none" });
    addText(slide, s[1], x + 12, 274, 142, 48, { fontSize: 15, color: C.muted, align: "center" });
    if (i < stages.length - 1) addFlowArrow(slide, x + 168, 260, 28, 2);
  });
  addPanel(slide, 42, 390, 560, 202, { fill: C.panel2 });
  addSectionLabel(slide, "CALCULATION CONTRACT", 66, 414, 300);
  addBulletList(slide, [
    "Inputs are captured with quote-version and rule-version identifiers",
    "Schedules preserve escalation and ramp-period detail",
    "One-time lines never distort recurring metrics",
    "Currency conversion uses an explicit rate date and source",
  ], 66, 452, 510, 120, { fontSize: 17 });
  addPanel(slide, 632, 390, 576, 202, { fill: C.accentPale, line: C.accentStrong });
  addSectionLabel(slide, "OUTPUT AND RECONCILIATION", 656, 414, 340);
  addText(slide, "ARR = normalized recurring value\nMRR = recurring value ÷ service months\nTCV = sum of all scheduled contract value\nVariance = contracted metric − financial actual", 656, 452, 520, 118, { fontSize: 20, bold: true });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 23-26 and 43",
    "C:/Users/LIKKI/Documents/ChatGPT/david/force-app/main/default",
  ]);
}

// 13 — Product governance
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Product governance separates catalogue, price, packaging and eligibility", 13);
  const layers = [
    ["SELLABLE EXPERIENCE", "Guided selection • compatible options • customer-friendly labels", C.accentPale],
    ["PACKAGING", "Bundles • required/optional components • product relationships", C.panel2],
    ["PRICING", "Price books • currency • effective dates • tier/ramp/term rules", C.panel2],
    ["CATALOGUE", "SKU • product family • lifecycle • billing and revenue classification", C.panel2],
    ["GOVERNANCE", "Owner • approval • data quality • release and audit", C.accentPale],
  ];
  layers.forEach((l, i) => {
    const y = 180 + i * 88;
    addPanel(slide, 82 + i * 26, y, 1030 - i * 52, 66, { fill: l[2], line: i === 0 || i === 4 ? C.accentStrong : C.rule });
    addText(slide, l[0], 110 + i * 26, y + 14, 240, 30, { fontSize: 18, bold: true, color: i === 0 || i === 4 ? C.accentStrong : C.ink, autoFit: "none" });
    addText(slide, l[1], 360 + i * 18, y + 14, 660 - i * 36, 34, { fontSize: 17, color: C.muted });
  });
  addText(slide, "New products enter through a governed lifecycle—not through direct production edits.", 140, 620, 960, 30, { fontSize: 20, bold: true, align: "center" });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 23-26, 33 and 43",
    "C:/Users/LIKKI/Documents/ChatGPT/david/force-app/main/default",
  ]);
}

// 14 — Document generation
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Proposal generation consumes the same approved quote model", 14);
  const xPositions = [42, 292, 542, 792, 1042];
  const titles = ["APPROVED QUOTE", "NORMALIZED DATA", "TEMPLATE", "RENDERED PROPOSAL", "SIGNED ARTIFACT"];
  const bodies = ["Immutable version\nApproved values", "Customer + groups\nLines + schedules", "Conditional sections\nReusable fragments", "Client-facing terms\nClear price schedules", "Envelope status\nContent hash"];
  titles.forEach((t, i) => {
    addPanel(slide, xPositions[i], 240, 196, 176, { fill: i === 3 ? C.accentPale : C.panel2, line: i === 3 ? C.accentStrong : C.rule });
    addText(slide, t, xPositions[i] + 12, 262, 172, 38, { fontSize: 16, bold: true, align: "center", autoFit: "shrinkText" });
    addText(slide, bodies[i], xPositions[i] + 16, 322, 164, 70, { fontSize: 16, color: C.muted, align: "center" });
    if (i < titles.length - 1) addFlowArrow(slide, xPositions[i] + 198, 312, 48, 3);
  });
  addPanel(slide, 42, 478, 1196, 120, { fill: C.canvas, line: C.rule });
  addText(slide, "Document controls", 66, 500, 220, 28, { fontSize: 19, bold: true, color: C.accentStrong, autoFit: "none" });
  addText(slide, "Template version • input schema version • quote version • generation timestamp • content hash • signature envelope • retention policy", 66, 544, 1110, 34, { fontSize: 19, bold: true, align: "center" });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 23-26",
    "C:/Users/LIKKI/Documents/ChatGPT/david/force-app/main/default",
  ]);
}

// 15 — CLM handoff
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Contract lifecycle begins with accepted structured data—not a document upload", 15);
  const steps = [
    ["01", "ACCEPT", "Capture signature and accepted quote version"],
    ["02", "CREATE", "Create contract and line records with legal entity"],
    ["03", "VALIDATE", "Verify dates, currency, products and obligations"],
    ["04", "ACTIVATE", "Publish order and billing events"],
    ["05", "MONITOR", "Track obligations, actuals, renewal and amendments"],
  ];
  steps.forEach((s, i) => {
    const x = 42 + i * 238;
    addText(slide, s[0], x, 210, 64, 42, { fontSize: 30, bold: true, color: C.accentStrong, autoFit: "none" });
    addText(slide, s[1], x, 270, 190, 34, { fontSize: 20, bold: true, autoFit: "none" });
    addText(slide, s[2], x, 324, 190, 94, { fontSize: 17, color: C.muted });
    if (i < steps.length - 1) addShape(slide, "straightConnector1", x + 196, 232, 32, 1, "none", C.accentStrong, 2);
  });
  addPanel(slide, 42, 480, 1196, 138, { fill: C.accentPale, line: C.accentStrong });
  addText(slide, "Minimum contract data quality gate", 66, 506, 360, 30, { fontSize: 20, bold: true, color: C.accentStrong, autoFit: "none" });
  addText(slide, "Account and entity match • accepted terms • contract dates • currency • products • recurring value • obligations • source quote version", 66, 554, 1100, 40, { fontSize: 19, bold: true, align: "center" });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 28-31 and 43",
  ]);
}

// 16 — Execution class diagram
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Execution services preserve traceability through contract activation", 16);
  await addImage(slide, "execution_class_diagram.png", 42, 168, 1196, 350, "PlantUML quote execution service class diagram");
  const labels = [
    ["Generate", "Proposal and signature are tied to one quote version."],
    ["Handoff", "Contract and integration events carry stable correlation identifiers."],
    ["Reconcile", "Financial actuals are matched back to contracted metrics."],
  ];
  labels.forEach((l, i) => {
    const x = 42 + i * 398;
    addText(slide, l[0], x, 536, 350, 30, { fontSize: 21, bold: true, color: C.accentStrong, autoFit: "none" });
    addText(slide, l[1], x, 574, 350, 60, { fontSize: 17, color: C.muted });
  });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 28-31 and 49",
    "C:/Users/LIKKI/Documents/ChatGPT/david/tmp/flywire_future_deck/execution_class_diagram.puml",
  ]);
}

// 17 — Integration controls
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Integration events are idempotent, observable and reconcilable", 17);
  const flow = ["CRM CHANGE", "OUTBOX EVENT", "TRANSFORM", "DELIVER", "ACK", "RECONCILE"];
  flow.forEach((label, i) => {
    const x = 42 + i * 198;
    addPanel(slide, x, 214, 164, 100, { fill: i === 5 ? C.accentPale : C.panel2, line: i === 5 ? C.accentStrong : C.rule });
    addText(slide, label, x + 10, 248, 144, 32, { fontSize: 16, bold: true, align: "center", autoFit: "none" });
    if (i < flow.length - 1) addFlowArrow(slide, x + 166, 248, 30, 2);
  });
  const controls = [
    ["Identity", "Correlation ID, source record ID and event version"],
    ["Delivery", "Idempotency key, retry count and terminal status"],
    ["Contract", "Schema version, required fields and validation result"],
    ["Evidence", "Payload hash, timestamp, actor and response reference"],
  ];
  controls.forEach((c, i) => {
    const x = 42 + (i % 2) * 598;
    const y = 388 + Math.floor(i / 2) * 118;
    addText(slide, c[0], x, y, 180, 30, { fontSize: 20, bold: true, color: C.accentStrong, autoFit: "none" });
    addText(slide, c[1], x + 190, y, 380, 54, { fontSize: 17, color: C.muted });
    addShape(slide, "straightConnector1", x, y + 72, 560, 1, "none", C.rule, 1);
  });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 18 and 48-49",
  ]);
}

// 18 — Security & governance
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Security and governance are built into every state transition", 18);
  const areas = [
    ["ACCESS", "Persona-based permissions\nLeast privilege\nSegregation of duties"],
    ["DATA", "Field classification\nEncryption and retention\nGolden-record stewardship"],
    ["PROCESS", "State-based edit locks\nApproval authority\nControlled amendments"],
    ["INTEGRATION", "Named authentication\nSchema validation\nReplay protection"],
    ["AUDIT", "Decision reasons\nPayload hashes\nCorrelation and lineage"],
  ];
  areas.forEach((a, i) => {
    const x = 42 + i * 238;
    addText(slide, String(i + 1).padStart(2, "0"), x, 196, 50, 38, { fontSize: 27, bold: true, color: C.accentStrong, autoFit: "none" });
    addText(slide, a[0], x, 252, 190, 32, { fontSize: 20, bold: true, autoFit: "none" });
    addText(slide, a[1], x, 310, 190, 112, { fontSize: 17, color: C.muted });
  });
  addPanel(slide, 42, 484, 1196, 126, { fill: C.panel2, line: C.rule });
  addText(slide, "Release governance", 66, 508, 260, 30, { fontSize: 21, bold: true, color: C.accentStrong, autoFit: "none" });
  addText(slide, "One source repository • isolated capability packages • automated tests • check-only validation • business UAT • controlled activation • rollback evidence", 66, 554, 1110, 36, { fontSize: 18, bold: true, align: "center" });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 18, 40 and 46",
    "C:/Users/LIKKI/Documents/ChatGPT/david/force-app/main/default",
  ]);
}

// 19 — Component blueprint
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Salesforce implementation components align directly to business capabilities", 19);
  const headers = ["CAPABILITY", "CONFIGURATION", "SERVICE / AUTOMATION", "EVIDENCE"];
  const rows = [
    ["Customer foundation", "Match rules, hierarchy fields", "Account identity service", "Duplicate and hierarchy reports"],
    ["Product & pricing", "Catalogue, price books, pricing rules", "Pricing and schedule service", "Rule-version calculation log"],
    ["Quote approval", "Approval rule metadata, personas", "Decision, lifecycle and lock services", "Approval request, steps and reasons"],
    ["Proposal", "Template and schema versions", "Document generation service", "Document reference and content hash"],
    ["Contract", "Contract types, obligations, clauses", "Contract handoff service", "Quote-to-contract lineage"],
    ["Integration", "Endpoint and event configuration", "Publisher, retry and reconciliation", "Delivery receipt and variance result"],
  ];
  const xs = [42, 258, 548, 902];
  const ws = [206, 280, 344, 336];
  headers.forEach((h, i) => addText(slide, h, xs[i], 176, ws[i], 36, { fontSize: 14, bold: true, color: C.muted, autoFit: "none" }));
  rows.forEach((row, r) => {
    const y = 220 + r * 68;
    addPanel(slide, 42, y, 1196, 59, { fill: r % 2 === 0 ? C.panel2 : C.canvas, line: C.rule });
    row.forEach((cell, i) => addText(slide, cell, xs[i] + 8, y + 8, ws[i] - 16, 42, { fontSize: i === 0 ? 17 : 15, bold: i === 0 }));
  });
  addText(slide, "Naming standard: capability + responsibility. Legacy organization-specific names are not carried forward.", 120, 632, 1000, 26, { fontSize: 17, bold: true, color: C.accentStrong, align: "center" });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 23-31 and 41-46",
    "C:/Users/LIKKI/Documents/ChatGPT/david/force-app/main/default",
  ]);
}

// 20 — Roadmap
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Delivery moves from evidence to pilot to scalable operating model", 20);
  addShape(slide, "straightConnector1", 78, 348, 1090, 1, "none", C.ink, 2);
  const phases = [
    ["0–6 WEEKS", "DESIGN", "Confirm process, data definitions, ownership, rules, vendor boundaries and acceptance criteria."],
    ["7–16 WEEKS", "PILOT", "Build evaluation-only approval, metric engine, controlled proposal and one integration path."],
    ["4–8 MONTHS", "SCALE", "Enable approval lifecycle, contract handoff, reconciliation and broader product/entity coverage."],
    ["8–12 MONTHS", "CONSOLIDATE", "Migrate remaining users/data, rationalize integrations and establish one release model."],
  ];
  phases.forEach((p, i) => {
    const x = 78 + i * 286;
    addShape(slide, "ellipse", x, 338, 20, 20, i === 0 ? C.accentStrong : C.ink, "none", 0);
    addText(slide, p[0], x, 210, 220, 30, { fontSize: 16, bold: true, color: C.accentStrong, autoFit: "none" });
    addText(slide, p[1], x, 258, 220, 34, { fontSize: 23, bold: true, autoFit: "none" });
    addText(slide, p[2], x, 390, 232, 136, { fontSize: 17, color: C.muted });
  });
  addPanel(slide, 42, 574, 1196, 70, { fill: C.accentPale, line: C.accentStrong });
  addText(slide, "Pilot success gate: explainable approvals + stable metrics + approved document + acknowledged downstream handoff", 62, 596, 1156, 28, { fontSize: 19, bold: true, align: "center" });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 10, 21, 26 and 31",
  ]);
}

// 21 — Quality gates
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "Quality gates prove data, logic and integration integrity before activation", 21);
  const gates = [
    ["01", "MODEL", "Required entities, keys, ownership and lifecycle states are approved."],
    ["02", "RULES", "Boundary values, overlaps, missing approvers and effective dates are tested."],
    ["03", "METRICS", "ARR, MRR, TCV and one-time revenue reconcile across test scenarios."],
    ["04", "SECURITY", "Personas can perform only authorized actions in each state."],
    ["05", "INTEGRATION", "Retry, duplicate delivery, schema failure and acknowledgement paths are proven."],
    ["06", "BUSINESS UAT", "Sales, deal desk, legal, finance and operations accept end-to-end outcomes."],
  ];
  gates.forEach((g, i) => {
    const row = Math.floor(i / 2);
    const col = i % 2;
    const x = 42 + col * 598;
    const y = 178 + row * 146;
    addText(slide, g[0], x, y, 58, 38, { fontSize: 27, bold: true, color: C.accentStrong, autoFit: "none" });
    addText(slide, g[1], x + 74, y, 220, 32, { fontSize: 20, bold: true, autoFit: "none" });
    addText(slide, g[2], x + 74, y + 42, 470, 66, { fontSize: 17, color: C.muted });
    addShape(slide, "straightConnector1", x, y + 116, 550, 1, "none", C.rule, 1);
  });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 21, 26 and 31",
    "C:/Users/LIKKI/Documents/ChatGPT/david/force-app/main/default",
  ]);
}

// 22 — Next steps
{
  const slide = presentation.slides.add();
  slide.background.fill = C.canvas;
  addTitle(slide, "The first 30 days convert this blueprint into an approved implementation backlog", 22);
  const actions = [
    ["WEEK 1", "Confirm ownership", "Name accountable owners for customer, product, quote, contract, integration and metrics."],
    ["WEEK 2", "Validate the model", "Map existing fields and records to the canonical model; identify duplicates and gaps."],
    ["WEEK 3", "Define pilot rules", "Select approval, pricing, metric and document scenarios for the first controlled pilot."],
    ["WEEK 4", "Approve the backlog", "Agree components, acceptance criteria, test data, release gates and decision log."],
  ];
  actions.forEach((a, i) => {
    const x = 42 + i * 298;
    addText(slide, a[0], x, 194, 220, 30, { fontSize: 16, bold: true, color: C.accentStrong, autoFit: "none" });
    addText(slide, a[1], x, 244, 250, 50, { fontSize: 24, bold: true });
    addText(slide, a[2], x, 326, 250, 132, { fontSize: 17, color: C.muted });
  });
  addPanel(slide, 42, 506, 1196, 132, { fill: C.accentPale, line: C.accentStrong });
  addText(slide, "Decisions required from the team", 72, 540, 390, 44, { fontSize: 20, bold: true, color: C.accentStrong, autoFit: "shrinkText" });
  addText(slide, "Pilot segment • source-of-truth owners • approval personas • metric definitions • contract boundary • integration priority • success measures", 470, 538, 720, 52, { fontSize: 17, bold: true, align: "center" });
  addFooter(slide);
  addNotes(slide, [
    "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf, pages 10, 21, 26 and 31",
  ]);
}

await fs.mkdir(RENDER_DIR, { recursive: true });
for (const [index, slide] of presentation.slides.items.entries()) {
  const stem = `slide-${String(index + 1).padStart(2, "0")}`;
  const png = await presentation.export({ slide, format: "png", scale: 1 });
  await fs.writeFile(path.join(RENDER_DIR, `${stem}.png`), new Uint8Array(await png.arrayBuffer()));
  const layout = await slide.export({ format: "layout" });
  await fs.writeFile(path.join(RENDER_DIR, `${stem}.layout.json`), await layout.text());
}

const montage = await presentation.export({ format: "webp", montage: true, scale: 1 });
await fs.writeFile(path.join(BUILD_DIR, "deck-montage.webp"), new Uint8Array(await montage.arrayBuffer()));
await fs.mkdir(path.dirname(OUTPUT), { recursive: true });
const pptx = await PresentationFile.exportPptx(presentation);
await pptx.save(OUTPUT);
console.log(JSON.stringify({ output: OUTPUT, slides: presentation.slides.items.length }));
