import fs from "node:fs/promises";
import path from "node:path";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const BUILD_DIR = "C:/Users/LIKKI/Documents/ChatGPT/david/tmp/flywire_go_live_deck";
const OUTPUT = "C:/Users/LIKKI/Documents/ChatGPT/david/output/presentations/Flywire_Build_and_Go_Live_Implementation_Package.pptx";
const RENDER_DIR = path.join(BUILD_DIR, "rendered");
const PDF = "C:/Users/LIKKI/Downloads/Flywire Future State Vision_20260814 (1).pdf";
const BLUEPRINT = "C:/Users/LIKKI/Documents/ChatGPT/david/output/presentations/Flywire_Future_State_Implementation_Blueprint.pptx";

const C = { canvas:"#FFFFFF", ink:"#111111", muted:"#5B6573", panel:"#F6F7F8", rule:"#B8BCC4", accent:"#6DCBF4", strong:"#3D8DFF", pale:"#D0EDFA", green:"#1F8A70", amber:"#D97706", red:"#C2413B" };
const p = Presentation.create({ slideSize:{ width:1280, height:720 } });

function shape(slide, geometry, x,y,w,h, fill="none", line="none", lw=0, name) {
  return slide.shapes.add({ geometry, ...(name?{name}:{}), position:{left:x,top:y,width:w,height:h}, fill, line:{style:"solid",fill:line,width:lw} });
}
function text(slide, value, x,y,w,h, o={}) {
  const s=shape(slide,"textbox",x,y,w,h,o.fill||"none",o.line||"none",o.lineWidth||0,o.name); s.text=value;
  s.text.style={fontSize:o.fontSize||20,typeface:"Arial",color:o.color||C.ink,bold:o.bold||false,italic:o.italic||false,alignment:o.align||"left",verticalAlignment:o.valign||"top",autoFit:o.autoFit||"shrinkText",wrap:"square"}; return s;
}
function title(slide, value, n, kicker="BUILD + GO-LIVE PACKAGE") {
  text(slide,kicker,42,28,430,26,{fontSize:14,bold:true,color:C.muted,autoFit:"none"});
  text(slide,value,42,58,1188,94,{fontSize:38,bold:true}); shape(slide,"straightConnector1",42,156,1196,1,"none",C.rule,1);
  text(slide,String(n).padStart(2,"0"),1180,670,56,24,{fontSize:13,color:C.muted,align:"right",autoFit:"none"});
}
function footer(slide, value="Build-ready design • production readiness • controlled go-live") { text(slide,value,42,671,760,20,{fontSize:11,color:C.muted,autoFit:"none"}); }
function notes(slide, pages="") { slide.speakerNotes.textFrame.setText(`[Sources]\n- ${PDF}${pages?`, ${pages}`:""}\n- ${BLUEPRINT}\n[/Sources]`); }
function panel(slide,x,y,w,h,o={}) { return shape(slide,"rect",x,y,w,h,o.fill||C.panel,o.line||C.rule,o.lineWidth??1,o.name); }
function bullets(slide,items,x,y,w,h,o={}) { return text(slide,items.map(v=>`• ${v}`).join("\n"),x,y,w,h,{fontSize:o.fontSize||18,color:o.color||C.ink}); }
function label(slide,value,x,y,w=260) { text(slide,value.toUpperCase(),x,y,w,24,{fontSize:13,bold:true,color:C.strong,autoFit:"none"}); }
function arrow(slide,x,y,w=46) { shape(slide,"rightArrow",x,y,w,20,C.strong,"none",0); }
function table(slide, headers, rows, widths, x, y, rowH=48, font=15) {
  let xx=x; headers.forEach((h,i)=>{text(slide,h,xx+7,y,widths[i]-14,32,{fontSize:13,bold:true,color:C.muted,autoFit:"shrinkText"});xx+=widths[i];});
  rows.forEach((row,r)=>{let cx=x; panel(slide,x,y+38+r*rowH,widths.reduce((a,b)=>a+b,0),rowH-4,{fill:r%2?C.canvas:C.panel,line:C.rule}); row.forEach((v,i)=>{text(slide,String(v),cx+7,y+45+r*rowH,widths[i]-14,rowH-18,{fontSize:font,bold:i===0});cx+=widths[i];});});
}
function flow(slide, items, y, x=52, totalW=1176) {
  const gap=40, boxW=(totalW-gap*(items.length-1))/items.length;
  items.forEach((it,i)=>{const xx=x+i*(boxW+gap); panel(slide,xx,y,boxW,112,{fill:i===items.length-1?C.pale:C.panel,line:i===items.length-1?C.strong:C.rule}); text(slide,it[0],xx+12,y+16,boxW-24,28,{fontSize:18,bold:true,align:"center"}); text(slide,it[1],xx+12,y+50,boxW-24,48,{fontSize:15,color:C.muted,align:"center"}); if(i<items.length-1)arrow(slide,xx+boxW+5,y+45,30);});
}

// 1 Cover
{
 const s=p.slides.add(); s.background.fill=C.canvas; text(s,"FLYWIRE",42,38,220,28,{fontSize:15,bold:true,color:C.strong,autoFit:"none"});
 text(s,"Build and Go-Live\nImplementation Package",42,174,820,208,{fontSize:55,bold:true,autoFit:"none"});
 text(s,"Physical design, delivery matrices, migration, testing, deployment and production acceptance",44,424,800,82,{fontSize:25,color:C.muted});
 panel(s,930,152,250,332,{fill:C.pale,line:"none"}); text(s,"DESIGN\nBUILD\nPROVE\nGO LIVE",964,208,190,210,{fontSize:32,bold:true,autoFit:"none"});
 text(s,"Standalone team implementation deck • August 2026",44,646,560,26,{fontSize:16,color:C.muted,autoFit:"none"}); notes(s,"pages 4-10 and 18-31");
}

// 2
{
 const s=p.slides.add(); title(s,"The model is viable when every design decision is converted into testable production evidence",2);
 text(s,"Architecture defines the destination. Go-live requires physical configuration, executable services, controlled migration and measurable acceptance.",42,178,1160,66,{fontSize:24});
 flow(s,[["DESIGN","Fields, rules, contracts"],["BUILD","Metadata, code, flows"],["PROVE","SIT, UAT, security"],["RELEASE","Cutover and rollback"],["OPERATE","Monitor and reconcile"]],286);
 text(s,"Production definition of done",42,456,300,28,{fontSize:17,bold:true,color:C.strong});
 bullets(s,["No unowned data or integration path","No calculation without a versioned rule","No go-live without reconciliation and rollback evidence"],42,496,760,116,{fontSize:20});
 panel(s,900,468,300,132,{fill:C.pale,line:C.strong}); text(s,"GO-LIVE OUTCOME",920,488,260,24,{fontSize:14,bold:true,color:C.strong,align:"center"}); text(s,"A controlled commercial operating model—not only a working feature.",924,532,252,52,{fontSize:20,bold:true,align:"center"}); footer(s); notes(s,"pages 10, 21, 26 and 31");
}

// 3 traceability
{
 const s=p.slides.add(); title(s,"Every transformation objective maps to a build package and an acceptance gate",3);
 table(s,["OBJECTIVE","IMPLEMENTATION PACKAGE","PRIMARY EVIDENCE","GO-LIVE GATE"],[
  ["Unified platform","Customer hierarchy, master data, integrations","Golden-record match and reconciliation","Duplicate and sync thresholds passed"],
  ["Quote-to-Cash","Product, pricing, approval, document and order services","Scenario tests and calculation comparisons","Commercial UAT signed"],
  ["Contract lifecycle","Repository, clauses, signature, obligations and amendments","Contract lineage and obligation validation","Legal and operations sign-off"],
  ["Reporting","Metric definitions and finance actual reconciliation","ARR/MRR/TCV variance report","Finance tolerance passed"],
  ["Operations","Monitoring, retry, audit and runbooks","Failure simulation and support drill","Operational readiness approved"]
 ],[190,330,330,346],42,186,74,15);
 text(s,"This matrix is the controlling traceability layer: no requirement closes without linked build evidence and an accountable approver.",42,626,1130,34,{fontSize:18,bold:true}); footer(s); notes(s,"pages 6-10, 18, 23-31 and 49");
}

// 4 deliverables
{
 const s=p.slides.add(); title(s,"Seven synchronized workstreams turn the logical blueprint into a deployable solution",4);
 const streams=[["01","Physical data model","Objects, fields, keys, history"],["02","Application services","Pricing, approval, document, contract"],["03","Integration contracts","APIs, events, retries, reconciliation"],["04","Security and governance","Access, audit, retention, ownership"],["05","Migration","Mapping, cleansing, mock loads, cutover"],["06","Quality assurance","Unit, SIT, UAT, NFR and regression"],["07","Release and operations","Deployment, rollback, monitoring, hypercare"]];
 streams.forEach((a,i)=>{const col=i%2,row=Math.floor(i/2),x=42+col*598,y=178+row*112; text(s,a[0],x,y,54,34,{fontSize:25,bold:true,color:C.strong}); text(s,a[1],x+68,y,260,30,{fontSize:20,bold:true}); text(s,a[2],x+68,y+36,450,50,{fontSize:17,color:C.muted}); shape(s,"straightConnector1",x,y+92,540,1,"none",C.rule,1);});
 footer(s); notes(s,"pages 10, 21, 26 and 31");
}

// 5 physical model matrix
{
 const s=p.slides.add(); title(s,"The physical data model must define storage, ownership, keys and retention for every domain",5);
 table(s,["DOMAIN","PHYSICAL RECORDS","REQUIRED DESIGN","SYSTEM OWNER"],[
  ["Customer","Account, hierarchy, legal entity","Golden ID, match policy, survivorship, history","CRM data steward"],
  ["Product","Product, price book, eligibility","SKU key, effective dates, bundles, attributes","Product operations"],
  ["Quote","Quote, line, schedule, metric snapshot","Version, state, locks, currency, term","Sales operations"],
  ["Approval","Rule, request, step, decision","Priority, persona, SLA, reason, audit","Deal desk"],
  ["Contract","Contract, line, clause, obligation","Entity, accepted version, dates, renewal","Legal operations"],
  ["Execution","Order, event, acknowledgement, variance","Correlation, retry, status, reconciliation","Operations / finance"]
 ],[170,330,400,296],42,182,66,15);
 text(s,"Each field specification must include datatype, requiredness, default, source, validation, editability by state, security and migration rule.",42,626,1140,34,{fontSize:18,bold:true}); footer(s); notes(s,"pages 18, 23-31 and 41-46");
}

// 6 field standard
{
 const s=p.slides.add(); title(s,"A field-level design standard prevents ambiguous configuration and migration defects",6);
 table(s,["ATTRIBUTE","WHAT MUST BE RECORDED","EXAMPLE"],[
  ["Business meaning","Single approved definition and owner","Contract start date"],
  ["Technical definition","Object, API name, datatype and length","Contract.StartDate / Date"],
  ["Behavior","Requiredness, default and state-based editability","Locked after acceptance"],
  ["Quality","Validation, uniqueness and allowed values","End date must follow start date"],
  ["Security","Classification and read/write personas","Legal write; finance read"],
  ["Lineage","Source, transformation and downstream consumers","Accepted quote → contract → finance"],
  ["Operations","History, retention, index and monitoring","History enabled; seven-year retention"]
 ],[220,630,346],42,180,61,16); footer(s); notes(s,"pages 18 and 41-46");
}

// 7 service matrix
{
 const s=p.slides.add(); title(s,"Service boundaries isolate policy decisions from lifecycle execution",7);
 table(s,["SERVICE","RESPONSIBILITY","INPUT / OUTPUT","FAILURE CONTROL"],[
  ["Pricing","Resolve rules and create schedules","Quote context → priced lines","Version pinning and calculation log"],
  ["Metric","Calculate ARR, MRR and TCV","Schedules → metric snapshot","Tolerance comparison"],
  ["Approval","Build and execute approval plan","Quote context → decisions","Locks, recall and audit"],
  ["Document","Generate version-controlled proposal","Approved quote → document","Hash and template version"],
  ["Contract","Create accepted legal records","Signature → contract and obligations","Idempotent creation"],
  ["Integration","Publish, retry and reconcile","Domain event → acknowledgement","Dead-letter and replay"]
 ],[180,360,330,326],42,182,67,15);
 text(s,"Class contracts must define interfaces, methods, transaction boundaries, error codes, logging and test doubles before coding starts.",42,626,1140,34,{fontSize:18,bold:true}); footer(s); notes(s,"pages 23-31");
}

// 8 transaction flow
{
 const s=p.slides.add(); title(s,"One transaction lineage connects configuration to acknowledged financial execution",8);
 flow(s,[["CONFIGURE","Customer, product, terms"],["PRICE","Schedules and metrics"],["APPROVE","Immutable quote version"],["CONTRACT","Signature and obligations"],["EXECUTE","Order and finance ack"]],214);
 const checks=[["Before approval","Product eligibility • required data • pricing completeness"],["Before document","Approved version • template compatibility • metric snapshot"],["Before contract","Signature • entity • dates • currency • accepted terms"],["Before execution","Correlation ID • payload validation • destination readiness"]];
 checks.forEach((a,i)=>{const x=42+(i%2)*598,y=390+Math.floor(i/2)*104; label(s,a[0],x,y,250); text(s,a[1],x,y+32,540,54,{fontSize:17});});
 footer(s); notes(s,"pages 23-31");
}

// 9 approval and pricing
{
 const s=p.slides.add(); title(s,"Pricing and approval are governed by versioned rules and explainable decisions",9);
 flow(s,[["CONTEXT","Customer, product, term, risk"],["RULE EVALUATION","Eligibility, tier, ramp, variance"],["APPROVAL PLAN","Persona, sequence, SLA"],["DECISION","Approve, reject, recall"],["LOCK + AUDIT","Immutable approved version"]],202);
 table(s,["RULE DIMENSION","CONFIGURATION REQUIRED","TEST EVIDENCE"],[
  ["Pricing","Precedence, effective dates, tier/ramp formulas","Expected schedule and totals"],
  ["Revenue metrics","Normalization, term, currency, rounding","ARR/MRR/TCV comparison"],
  ["Approval","Threshold, persona, ordering, exceptions","Resolved route and decision history"],
  ["Change control","Material-change definition and reapproval","Edit lock and resubmission"]
 ],[210,550,436],42,382,58,15); footer(s); notes(s,"pages 23-26");
}

// 10 integration matrix
{
 const s=p.slides.add(); title(s,"Every integration requires an explicit contract, ownership and recoverability model",10);
 table(s,["CONTRACT ELEMENT","REQUIRED DEFINITION","PRODUCTION PROOF"],[
  ["Identity","Endpoint, authentication, authorization, certificate rotation","Successful security test"],
  ["Payload","Schema, version, required fields, semantic ownership","Contract test and sample payload"],
  ["Delivery","Sync/async, ordering, timeout, retry and idempotency","Replay without duplication"],
  ["Traceability","Correlation ID, source version, timestamps and audit","End-to-end trace query"],
  ["Failure handling","Dead-letter, alert, owner, remediation and reprocessing","Failure simulation"],
  ["Reconciliation","Acknowledgement, expected totals, variance and close process","Balanced control report"]
 ],[230,640,326],42,184,66,16);
 footer(s); notes(s,"pages 18, 21, 26, 31, 48-49");
}

// 11 migration flow
{
 const s=p.slides.add(); title(s,"Migration proceeds by governed waves with measurable entry and exit criteria",11);
 flow(s,[["PROFILE","Volume, quality, ownership"],["MAP","Source to target rules"],["CLEANSE","Duplicates and reference data"],["MOCK LOAD","Validate and reconcile"],["CUTOVER","Freeze, final load, verify"]],206);
 text(s,"Wave sequence",42,374,170,28,{fontSize:17,bold:true,color:C.strong});
 const waves=[["Wave 0","Reference data and identities"],["Wave 1","Customers and hierarchies"],["Wave 2","Products and commercial configuration"],["Wave 3","Open quotes, contracts and obligations"],["Wave 4","History, archive and reporting balances"]];
 waves.forEach((a,i)=>{const x=42+i*238; panel(s,x,414,216,112,{fill:i%2?C.canvas:C.panel,line:C.rule}); text(s,a[0],x+12,428,192,24,{fontSize:17,bold:true,color:C.strong}); text(s,a[1],x+12,464,192,48,{fontSize:15,color:C.muted});});
 panel(s,42,560,1196,60,{fill:C.pale,line:C.strong}); text(s,"Exit gate: record counts + control totals + relationship integrity + exception ownership + business sign-off",62,578,1156,28,{fontSize:19,bold:true,align:"center"}); footer(s); notes(s,"pages 10 and 21");
}

// 12 mapping matrix
{
 const s=p.slides.add(); title(s,"The migration mapping matrix controls lineage, transformation and reconciliation",12);
 table(s,["MAPPING COLUMN","PURPOSE","MANDATORY CONTROL"],[
  ["Source object / field","Identify authoritative origin","Source owner approved"],
  ["Target object / field","Define physical destination","Target design approved"],
  ["Transformation","Default, conversion, split, merge or derivation","Rule version and test case"],
  ["Reference lookup","Resolve customer, product, entity and currency keys","Unmatched exception queue"],
  ["Quality rule","Requiredness, format, uniqueness and relationship","Reject/quarantine policy"],
  ["Reconciliation","Count, amount, hierarchy and status controls","Signed control report"],
  ["Disposition","Migrate, archive, retain read-only or exclude","Legal and business approval"]
 ],[240,610,346],42,180,61,16); footer(s); notes(s,"pages 10 and 21");
}

// 13 security
{
 const s=p.slides.add(); title(s,"Security is designed by persona, lifecycle state and data classification",13);
 table(s,["PERSONA","CREATE / EDIT","APPROVE","SENSITIVE ACCESS","CONTROL"],[
  ["Sales","Draft quote and customer inputs","Submit only","Commercial scope","Ownership and field security"],
  ["Deal desk","Pricing exceptions and schedules","Commercial approval","Pricing and margin","Delegated authority"],
  ["Legal","Terms, clauses and obligations","Legal approval","Contract content","Clause and amendment audit"],
  ["Finance","Metric policy and actuals","Financial approval","Revenue data","Formula and reconciliation control"],
  ["Operations","Order and integration remediation","Operational release","Payload and status","Replay and support audit"],
  ["Administrator","Configuration only","No business approval","Restricted support access","Separation of duties"]
 ],[150,290,160,260,336],42,182,66,14);
 text(s,"Required evidence: permission matrix • sharing model • field classification • access tests • audit retention • privileged-access review",42,626,1140,34,{fontSize:18,bold:true}); footer(s); notes(s,"pages 18 and 39-46");
}

// 14 environments and release
{
 const s=p.slides.add(); title(s,"One controlled promotion path keeps configuration, code and data synchronized",14);
 flow(s,[["DEV","Build and unit test"],["INTEGRATION","Contract and end-to-end test"],["UAT","Business acceptance"],["STAGING","Dress rehearsal"],["PRODUCTION","Controlled activation"]],210);
 const lanes=[["Metadata and code","Version control • peer review • automated validation • deployment manifest"],["Configuration","Rule version • approval • effective date • environment comparison"],["Data","Reference seed • migration package • reconciliation • archive"],["Release evidence","Test results • approvals • runbook • rollback package"]];
 lanes.forEach((a,i)=>{const y=378+i*58; text(s,a[0],42,y,240,34,{fontSize:18,bold:true}); text(s,a[1],300,y,900,34,{fontSize:17,color:C.muted}); shape(s,"straightConnector1",42,y+43,1180,1,"none",C.rule,1);}); footer(s); notes(s,"pages 10 and 21");
}

// 15 test matrix
{
 const s=p.slides.add(); title(s,"Testing proves business outcomes, not only technical execution",15);
 table(s,["TEST LAYER","SCOPE","PASS EVIDENCE","OWNER"],[
  ["Unit","Rules, calculations, services and failure branches","Automated assertions and coverage","Engineering"],
  ["Contract","API/event schemas and backward compatibility","Provider/consumer contract tests","Integration team"],
  ["SIT","Quote through contract, order and finance acknowledgement","Traceable end-to-end scenarios","QA lead"],
  ["Migration","Counts, relationships, quality and financial controls","Signed reconciliation","Data lead"],
  ["UAT","Persona journeys and business exceptions","Business acceptance","Process owners"],
  ["NFR","Performance, scale, security, recovery and observability","Threshold results","Architecture / security"],
  ["Regression","Protected commercial and contract capabilities","Automated release suite","Release manager"]
 ],[170,400,390,236],42,180,61,15); footer(s); notes(s,"pages 10, 21, 26 and 31");
}

// 16 NFR
{
 const s=p.slides.add(); title(s,"Non-functional requirements define whether the solution can operate safely at production scale",16);
 table(s,["QUALITY ATTRIBUTE","TARGET TO CONFIRM","EVIDENCE REQUIRED"],[
  ["Performance","Interactive response and batch completion thresholds","Load and volume test"],
  ["Availability","Business-hours and critical-path service objective","Monitoring and incident model"],
  ["Recoverability","RTO, RPO, backup and restore validation","Recovery exercise"],
  ["Scalability","Quote lines, rules, attributes, events and migration volume","Peak-volume test"],
  ["Security","Authentication, authorization, encryption and vulnerability limits","Security assessment"],
  ["Observability","Logs, metrics, traces, alerts and business reconciliation","Support dashboard and alert drill"],
  ["Maintainability","Configuration ownership, deployment frequency and rollback","Release rehearsal"]
 ],[240,510,446],42,180,61,16); footer(s); notes(s,"pages 18, 23-31 and 49");
}

// 17 cutover
{
 const s=p.slides.add(); title(s,"The cutover runbook controls the point of no return and preserves rollback options",17);
 flow(s,[["READINESS","Approvals and backups"],["FREEZE","Stop controlled changes"],["DEPLOY","Metadata and configuration"],["MIGRATE","Final data and validation"],["ACTIVATE","Users and integrations"]],202);
 const items=[["Decision checkpoint","Proceed only when technical and business control totals pass"],["Rollback trigger","Critical data variance, security defect, failed integration or unacceptable performance"],["Rollback package","Previous metadata, configuration snapshot, data restore steps and communication plan"],["Command center","Named decision authority, workstream leads, incident channel and status cadence"]];
 items.forEach((a,i)=>{const x=42+(i%2)*598,y=382+Math.floor(i/2)*104; label(s,a[0],x,y,260); text(s,a[1],x,y+32,540,58,{fontSize:17});}); footer(s); notes(s,"pages 10 and 21");
}

// 18 gates
{
 const s=p.slides.add(); title(s,"Go-live is approved only when eight evidence gates are green",18);
 const gates=[["01","Scope","Requirements traced"],["02","Design","Physical model approved"],["03","Build","Code and config complete"],["04","Data","Reconciliation passed"],["05","Quality","SIT/UAT/NFR passed"],["06","Security","Access and risks approved"],["07","Operations","Runbooks and monitoring ready"],["08","Cutover","Rehearsal and rollback ready"]];
 gates.forEach((a,i)=>{const col=i%4,row=Math.floor(i/4),x=42+col*299,y=190+row*190; text(s,a[0],x,y,54,36,{fontSize:26,bold:true,color:C.strong}); text(s,a[1],x+65,y,210,34,{fontSize:21,bold:true}); text(s,a[2],x+65,y+45,205,58,{fontSize:17,color:C.muted}); shape(s,"straightConnector1",x,y+122,252,1,"none",C.rule,1);});
 panel(s,42,570,1196,60,{fill:C.pale,line:C.strong}); text(s,"Any red gate blocks production activation; exceptions require named risk acceptance, expiry and remediation owner.",62,588,1156,28,{fontSize:19,bold:true,align:"center"}); footer(s); notes(s,"pages 10, 21, 26 and 31");
}

// 19 RACI
{
 const s=p.slides.add(); title(s,"Accountability is assigned by deliverable and approval—not by meeting attendance",19);
 table(s,["DELIVERABLE","A","R","C","FINAL SIGN-OFF"],[
  ["Physical data model","Enterprise architect","CRM / data lead","Business owners","Architecture review"],
  ["Pricing and approvals","Commercial process owner","Product / engineering","Finance, legal, deal desk","Commercial owner"],
  ["Contract lifecycle","Legal operations","CLM / engineering","Sales and finance","Legal owner"],
  ["Integrations","Integration owner","Integration team","System owners","Architecture + operations"],
  ["Migration","Data owner","Migration team","Business stewards","Data owner"],
  ["Quality and UAT","Program sponsor","QA lead","All workstreams","Business process owners"],
  ["Cutover and go-live","Executive sponsor","Release manager","Security, operations, vendors","Go-live authority"]
 ],[280,190,230,260,236],42,180,61,14); footer(s); notes(s,"pages 10 and 21");
}

// 20 roadmap
{
 const s=p.slides.add(); title(s,"A 12-month plan delivers foundations early and delays production risk until evidence is complete",20);
 const phases=[["M1–2","DISCOVER + DESIGN","Process, physical model, vendor boundaries, NFRs"],["M3–5","BUILD FOUNDATION","Customer/product, integration base, pricing and metric engine"],["M5–7","BUILD JOURNEYS","Approvals, documents, contracts, migration tooling"],["M7–9","PROVE","SIT, mock loads, security, performance and UAT"],["M9–10","PILOT","Controlled segment, monitoring and reconciliation"],["M10–12","SCALE + CONSOLIDATE","Remaining waves, hypercare and optimization"]];
 phases.forEach((a,i)=>{const x=42+(i%3)*398,y=184+Math.floor(i/3)*202; text(s,a[0],x,y,100,28,{fontSize:16,bold:true,color:C.strong}); text(s,a[1],x,y+42,350,34,{fontSize:21,bold:true}); text(s,a[2],x,y+88,340,72,{fontSize:17,color:C.muted}); shape(s,"straightConnector1",x,y+174,350,1,"none",C.rule,1);});
 panel(s,42,590,1196,44,{fill:C.pale,line:C.strong}); text(s,"Pilot precedes broad consolidation; scale begins only after metric stability, acknowledged handoffs and support readiness are proven.",60,602,1160,26,{fontSize:18,bold:true,align:"center"}); footer(s); notes(s,"pages 10, 21, 26 and 31");
}

// 21 risks
{
 const s=p.slides.add(); title(s,"The highest delivery risks are controlled through explicit evidence and decision ownership",21);
 table(s,["RISK","EARLY WARNING","CONTROL / RESPONSE","OWNER"],[
  ["Unclear source of truth","Conflicting customer, product or metric values","Approve ownership and reconciliation before build","Data owner"],
  ["Rule explosion","Unbounded pricing or approval combinations","Rule catalog, precedence and scenario limits","Commercial owner"],
  ["Integration fragility","Retries create duplicates or lost status","Idempotency, dead-letter and control totals","Integration owner"],
  ["Migration quality","Unmatched keys and broken relationships","Profiling, cleansing and repeated mock loads","Migration lead"],
  ["Late business acceptance","UAT discovers process gaps","Journey sign-off and early pilot scenarios","Process owners"],
  ["Operational unreadiness","No clear alert or remediation path","Support drill, runbooks and hypercare staffing","Operations lead"]
 ],[240,300,450,206],42,182,67,14); footer(s); notes(s,"pages 10, 21, 26 and 31");
}

// 22 close
{
 const s=p.slides.add(); title(s,"The next decision is to authorize detailed design—not production deployment",22);
 text(s,"First 30 days",42,190,260,34,{fontSize:24,bold:true,color:C.strong});
 bullets(s,["Confirm accountable owners and decision forum","Approve physical design and traceability templates","Baseline volumes, quality, integrations and NFRs","Select pilot journeys and acceptance scenarios","Produce cost, capacity and 12-month delivery baseline"],42,244,520,250,{fontSize:20});
 text(s,"Approval requested",650,190,300,34,{fontSize:24,bold:true,color:C.strong});
 const decisions=[["1","Implementation scope and pilot segment"],["2","Product and contract platform boundaries"],["3","Data ownership and migration authorities"],["4","Go-live gate owners and risk authority"]];
 decisions.forEach((a,i)=>{const y=244+i*70; text(s,a[0],650,y,42,34,{fontSize:25,bold:true,color:C.strong}); text(s,a[1],710,y,460,44,{fontSize:19,bold:true});});
 panel(s,42,558,1196,72,{fill:C.pale,line:C.strong}); text(s,"Expected result: a build-ready backlog, approved physical design, executable test strategy and controlled pilot go-live plan.",68,578,1144,34,{fontSize:21,bold:true,align:"center"}); footer(s); notes(s,"pages 10, 21, 26 and 31");
}

await fs.mkdir(RENDER_DIR,{recursive:true});
for (const [i,s] of p.slides.items.entries()) {
  const stem=`slide-${String(i+1).padStart(2,"0")}`;
  const png=await p.export({slide:s,format:"png",scale:1}); await fs.writeFile(path.join(RENDER_DIR,`${stem}.png`),new Uint8Array(await png.arrayBuffer()));
  const layout=await s.export({format:"layout"}); await fs.writeFile(path.join(RENDER_DIR,`${stem}.layout.json`),await layout.text());
}
const montage=await p.export({format:"webp",montage:true,scale:1}); await fs.writeFile(path.join(BUILD_DIR,"montage.webp"),new Uint8Array(await montage.arrayBuffer()));
const inspect=await p.inspect({kind:"slide,textbox,shape,image,table,chart,notes",maxChars:250000}); await fs.writeFile(`${OUTPUT}.inspect.ndjson`,inspect.ndjson);
const pptx=await PresentationFile.exportPptx(p); await pptx.save(OUTPUT);
