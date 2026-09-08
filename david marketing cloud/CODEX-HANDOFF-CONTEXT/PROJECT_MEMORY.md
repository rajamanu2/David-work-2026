# Historical project notes

These notes are historical context. Verify current state before acting.

# Task Group: FlywirePartial daily story review, SALDEV-1427 re-review, and Jira guidance

scope: review FlywirePartial Salesforce stories, produce decision-ready architect artifacts, and supply copy-ready Jira comments without confusing check-only validation with completed fixes, deployment, or business sign-off
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\david; reuse_rule=use for FlywirePartial review/Jira/document work; story findings, coverage, and sandbox state are snapshot-specific and require fresh evidence

## Task 1: Review the day's Flywire work and identify SALDEV-1403 evidence needed, partial

### rollout_summary_files

- rollout_summaries/2026-09-07T18-32-02-3isI-flywire_daily_summary_saldev_review_and_jira_comments.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\08\rollout-2026-09-08T00-02-02-01a07d24-3ddd-7960-a9bc-b7cec5550c24.jsonl, updated_at=2026-09-07T21:45:50+00:00, thread_id=01a07d24-3ddd-7960-a9bc-b7cec5550c24, fresh CPQ Quote Proposal/business acceptance remains pending)

### keywords

- FlywirePartial, SALDEV-1499, SALDEV-1467, SALDEV-1403, SALDEV-1420, Q-37912, CPQ Quote Proposal, headings 36 12 12 12 months, Ship-To

## Task 2: Re-review SALDEV-1427 QCP/clone logic and prepare Jira response, success

### rollout_summary_files

- rollout_summaries/2026-09-07T18-32-02-3isI-flywire_daily_summary_saldev_review_and_jira_comments.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\08\rollout-2026-09-08T00-02-02-01a07d24-3ddd-7960-a9bc-b7cec5550c24.jsonl, updated_at=2026-09-07T21:45:50+00:00, thread_id=01a07d24-3ddd-7960-a9bc-b7cec5550c24, Changes Requested retained; no deployment performed)

### keywords

- SALDEV-1427, QCP, clone logic, QuoteLineTrigger, QuoteLineGroupAsyncHelper, 79.49%, Domestic_Sponsor__c, Group 2, QLE calculate save reload, Changes Requested, Jira

## Task 3: Align SALDEV-1467 architect re-review DOCX, success

### rollout_summary_files

- rollout_summaries/2026-09-07T18-32-02-3isI-flywire_daily_summary_saldev_review_and_jira_comments.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\08\rollout-2026-09-08T00-02-02-01a07d24-3ddd-7960-a9bc-b7cec5550c24.jsonl, updated_at=2026-09-07T21:45:50+00:00, thread_id=01a07d24-3ddd-7960-a9bc-b7cec5550c24, Word-rendered three-page artifact visually inspected)

### keywords

- SALDEV-1467, Architect_Re-review_Aligned.docx, real tables, Word COM, render_with_word.ps1, LibreOffice, soffice.exe, 3-page PDF

## User preferences

- when the user repeatedly asked “what should I add in Jira comment” -> provide a concise, directly copyable stakeholder comment with decision, evidence, remaining findings, and next actions; say it is drafted for the user to post rather than claiming Jira was updated [Task 2]
- when the user asked whether the work was actually completed -> distinguish review completion from fixes/deployment and business sign-off [Task 2]
- when the user said “template is not good make it look aligned” -> replace manually spaced/plain-text tables with real tables, consistent headings/indents, and clean page breaks [Task 3]

## Reusable knowledge

- SALDEV-1427 fresh check-only validation passed for 3 components and 9 tests; `QuoteLineTrigger` coverage was 79.49% and `QuoteLineGroupAsyncHelper` 100%, but field locking/usage-rate editability, ARR visibility in cloned groups, invalid `Domestic_Sponsor__c`, and ID clearing/mapping still need correction and business verification. Required evidence includes exact Group 2, bundle, and Ship-To assertions plus QLE calculate/save/reload testing. [Task 2]
- For SALDEV-1403, the immediate evidence request is a fresh CPQ Quote Proposal for `Q-37912`, confirming headings `36, 12, 12, 12 months`, no service dates, product/bundle ordering, and Ship-To visibility. Technical deployment success does not close the story; UAT evidence remains separate. [Task 1]
- The aligned SALDEV-1467 artifact is `output/documents/SALDEV-1467-aligned/SALDEV-1467_Architect_Re-review_Aligned.docx`; Word COM rendering through `review/SALDEV-1500-implementation-plan/render_with_word.ps1` produced a three-page PDF for visual inspection. [Task 3]

## Failures and how to do differently

- Symptom: passing Apex/check-only validation is treated as sign-off. Fix: retain `Changes Requested` until runtime/business assertions are evidenced; do not imply that corrections or deployment occurred. [Task 2]
- Symptom: `render_docx.py` cannot find LibreOffice or hits temporary-directory permission errors. Fix: use the proven Word COM renderer when available, then render and inspect every final page before delivery. [Task 3]

# Task Group: Probo Medical UAT verification and AutoFast requirements workbook

scope: safely verify a supplied Probo UAT connection and turn screenshot-driven requirements into a complete editable, visually checked Word workbook
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical; reuse_rule=UAT identity and session state must be verified fresh; reuse the read-only connection and Word QA procedure, never session material or the workbook's snapshot-specific content

## Task 1: Verify Probo Medical UAT read-only, success

### rollout_summary_files

- rollout_summaries/2026-09-07T20-44-02-Mkvk-probo_uat_autofast_requirements_workbook.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\08\rollout-2026-09-08T02-14-02-01a07d9d-16f1-7023-afa6-ab8cdb1c11e6.jsonl, updated_at=2026-09-07T21:28:39+00:00, thread_id=01a07d9d-16f1-7023-afa6-ab8cdb1c11e6, identity verified without Salesforce changes)

### keywords

- ProboUAT, Organization SOQL, 00DjH0000000rYzUAI, Unlimited Edition, USA1310S, IsSandbox, frontdoor, masked input, URLError

## Task 2: Complete screenshot-driven AutoFast requirements workbook, success

### rollout_summary_files

- rollout_summaries/2026-09-07T20-44-02-Mkvk-probo_uat_autofast_requirements_workbook.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\08\rollout-2026-09-08T02-14-02-01a07d9d-16f1-7023-afa6-ab8cdb1c11e6.jsonl, updated_at=2026-09-07T21:28:39+00:00, thread_id=01a07d9d-16f1-7023-afa6-ab8cdb1c11e6, 242 fillable fields and 23-page final QA)

### keywords

- AutoFast, content controls, Business Ask, IT comments and questions, Impacted application, Component and Record Dependency, Timeframe, Total Estimated, Word COM, Poppler, 242 fields, 23 pages

## User preferences

- when the user asks to “connect” an org with a frontdoor/session link -> authenticate through masked input, perform a read-only identity check, and do not retrieve, deploy, activate, or mutate data unless separately authorized [Task 1]
- when completing a screenshot-driven requirements workbook -> represent every requested item as a field, preserve existing content, and deliver an editable Word artifact rather than a prose summary; explicitly cover “Business Ask,” “IT comments and questions,” “Impacted application,” “Component and Record Dependency,” “Timeframe,” and “Total Estimated” [Task 2]

## Reusable knowledge

- Probo Medical UAT was verified as sandbox `00DjH0000000rYzUAI`, Unlimited Edition, instance `USA1310S`, using `SELECT Id, Name, OrganizationType, IsSandbox, InstanceName FROM Organization`. Treat frontdoor/session credentials as `[REDACTED_SECRET]`. [Task 1]
- Final workbook: `outputs/business_templates_2026-09-08/Probo_Medical_AutoFast_Complete_Requirements_Workbook.docx`. It preserved 171 existing content controls, added 71, and has 242 total fillable fields across 23 pages with original body text preserved. [Task 2]
- If LibreOffice/`render_docx.py` is unavailable, use Word COM `ExportAsFixedFormat` to PDF, bundled Poppler PNG conversion, and visual page inspection. [Task 2]

## Failures and how to do differently

- Symptom: an inline Python verification command fails with quoting `SyntaxError`, or the first network attempt returns `URLError`. Fix: use a temporary verification script with masked input and retry only through the authorized network context; do not expose credentials. [Task 1]
- Symptom: `soffice.exe` is absent or blank paragraphs cause pagination drift. Fix: use Word export fallback; remove empty paragraphs and adjust normal/heading spacing rather than shrinking text. [Task 2]

# Task Group: Great Plains Salesforce sandbox connection and peer-review DOCX delivery

scope: verify Great Plains sandbox aliases read-only and deliver ticket-specific peer-review DOCX files from attached evidence without treating attachments as authorization for Salesforce changes
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3; reuse_rule=aliases and ticket findings are snapshot-specific; reuse the connection/QA workflow, but verify the current org and artifact identity each time

## Task 1: Refresh GreatPlainsDevA and review SCC-3384, partial

### rollout_summary_files

- rollout_summaries/2026-09-04T19-18-39-1QMJ-great_plains_scc_3384_peer_review_and_deva_refresh.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\09\05\rollout-2026-09-05T00-48-40-01a06ddb-d927-7df2-b177-754dff70bdb5.jsonl, updated_at=2026-09-04T20:56:50+00:00, thread_id=01a06ddb-d927-7df2-b177-754dff70bdb5, artifact naming/verification ambiguity remains)

### keywords

- GreatPlainsDevA, SCC-3384, SCC-4095-peer-review.docx, Word COM, pdftoppm.exe, PYTHONUTF8, table_no_header_row

## Task 2: Connect GreatPlainsMerge and deliver SCC-4273 peer review, success

### rollout_summary_files

- rollout_summaries/2026-09-04T19-29-39-CoDO-scc_4273_salesforce_peer_review_docx.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\05\rollout-2026-09-05T00-59-39-01a06de5-e92e-7261-8a68-471a730a9af4.jsonl, updated_at=2026-09-04T20:00:32+00:00, thread_id=01a06de5-e92e-7261-8a68-471a730a9af4, separate review artifact passed package/a11y checks)

### keywords

- GreatPlainsMerge, SCC-4273, Changes Requested, Primary Resolution, a11y_audit.py, zipfile -t, WinError 5

## User preferences

- when the user asked to “make a peer review for this and get me the doc” or “a doc for this peer review” -> create a separate, downloadable peer-review DOCX in the established Great Plains review style; use the attachment as evidence, not authorization for Salesforce changes [Task 1][Task 2]

## Reusable knowledge

- Verify `GreatPlainsDevA` or `GreatPlainsMerge` with the read-only `Organization` SOQL query after masked-token authentication; do not change the global default unless asked. `GreatPlainsDevA` is `00DEa00000Fc086MAB` / `USA20S`; `GreatPlainsMerge` is sandbox `00DEa00000GkAsHMAV`. [Task 1][Task 2]
- For Windows DOCX QA when LibreOffice is unavailable, use Word COM `ExportAsFixedFormat(..., 17)` then bundled `pdftoppm.exe` to produce final-page PNGs; use `PYTHONUTF8=1` and a workspace-local temp location for cp1252/protected-temp failures. [Task 1]
- A clean decision requires both evidence and artifact identity: SCC-4273 was `Changes Requested` because Primary Resolution runtime configuration and PR-diff evidence were insufficient; its DOCX had zero accessibility findings and passed ZIP integrity. [Task 2]

## Failures and how to do differently

- Symptom: a peer-review output or QA target says a different ticket number than the source. Fix: before delivery, reconcile filename, internal title, ticket number, content search, and rendered/inspected file; SCC-3384 versus `SCC-4095-peer-review.docx` is not evidence of a clean final artifact. [Task 1]
- Symptom: LibreOffice fails with `PermissionError: [WinError 5]` or is absent. Fix: use a writable task-local profile/temp path and the Word-to-PDF fallback; do not claim visual QA until final pages are actually rendered and inspected. [Task 1][Task 2]

# Task Group: Probo Medical Salesforce org connection and GE CPC report lifecycle

scope: connect Probo Medical Production/UAT/DevDO aliases safely, determine report lifecycle scope, and verify report handoff/access separately from deployment
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical; reuse_rule=aliases/org IDs are useful routing anchors but sessions and report sharing must be freshly verified; never retain frontdoor/session credentials

## Task 1: Deploy and hand off GE CPC Parts Shipped report, partial

### rollout_summary_files

- rollout_summaries/2026-09-02T20-31-32-0eDa-ge_cpc_report_deployment_and_access_verification.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\09\03\rollout-2026-09-03T02-01-33-01a063d1-dc0e-7b11-8464-9e178a477d84.jsonl, updated_at=2026-09-03T21:08:32+00:00, thread_id=01a063d1-dc0e-7b11-8464-9e178a477d84, report deployed; Adam/Mindy visibility unverified)

### keywords

- GE CPC Parts Shipped, Service Operations Reports, 00OjR0000002cHJUAY, report-meta.xml, Adam, Mindy, Auto render too large

## Task 2: Connect ProboUAT, ProboDevDO, and ProboMedical read-only, success

### rollout_summary_files

- rollout_summaries/2026-09-03T17-16-49-FhF4-reconnect_verify_probomedical_production.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\03\rollout-2026-09-03T22-46-49-01a06845-f06e-7d71-a308-52d9804b23fe.jsonl, updated_at=2026-09-03T17:19:58+00:00, thread_id=01a06845-f06e-7d71-a308-52d9804b23fe, production identity verified)
- rollout_summaries/2026-09-03T17-15-37-kIix-connect_verify_probo_medical_devdo.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\03\rollout-2026-09-03T22-45-38-01a06844-d883-74e2-8bd3-1ef93c2f38cd.jsonl, updated_at=2026-09-03T17:18:19+00:00, thread_id=01a06844-d883-74e2-8bd3-1ef93c2f38cd, DevDO identity verified)
- rollout_summaries/2026-09-03T17-13-20-HZ8Q-connect_probo_medical_uat_salesforce.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\03\rollout-2026-09-03T22-43-20-01a06842-bff7-74d0-83a6-a62558b2dc00.jsonl, updated_at=2026-09-03T17:18:19+00:00, thread_id=01a06842-bff7-74d0-83a6-a62558b2dc00, UAT alias added without changing default)

### keywords

- ProboMedical, ProboUAT, ProboDevDO, IsSandbox, 00DU0000000LaKoMAK, 00DjH0000000rYzUAI, 00DiK0000001co1UAA, INVALID_SESSION_ID, EPERM

## User preferences

- when the user supplies a frontdoor/session link merely to “connect this org” -> authenticate through masked input, verify identity read-only, and do not retrieve, deploy, activate, or mutate data unless separately authorized [Task 2]
- when the user says “MAKE SURE THESE PEOPLE SEE THIS REPORT” -> distinguish intended recipients from verified Salesforce access; confirm active users and report-folder access before stating they can see it. [Task 1]

## Reusable knowledge

- `ProboMedical` is Production `00DU0000000LaKoMAK` (`IsSandbox=false`); `ProboUAT` is `00DjH0000000rYzUAI` / `USA1310S`; `ProboDevDO` is `00DiK0000001co1UAA`. Use the scoped `Organization` query and keep aliases/environment URLs separate. [Task 2]
- GE CPC is Report metadata only: build DevDO -> validate/deploy UAT -> Production check-only -> approved Production deployment. The report is `GE CPC Parts Shipped` (`00OjR0000002cHJUAY`) in `Service Operations Reports`; PO-like `302808xxx` values are not story IDs. [Task 1]

## Failures and how to do differently

- Symptom: `EPERM` writing `.sf\\sf-*.log`, `ECONNREFUSED 127.0.0.1:9`, or `INVALID_SESSION_ID`. Fix: classify local logging/network failures separately from expired credentials; use `SF_DISABLE_LOG_FILE=true` for scoped read-only checks when appropriate, refresh the alias through masked login only after confirming expiration, then rerun the identity query. [Task 1][Task 2]
- Symptom: deployment/handoff is mistaken for access verification. Fix: after reconnecting Production, inspect the active users and `Service Operations Reports` folder/report access; do not claim Adam/Mindy visibility from a failed or expired-session query. [Task 1]

# Task Group: Probo Medical DevDO story-activity lookup

scope: answer date-specific questions about completed ProboDevDO story work without inferring activity from older bundles or treating development work as Production deployment
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical; reuse_rule=the September 2026 activity result is historical; reuse the timestamp/artifact lookup method for later dates

## Task 1: Identify September 2 DevDO stories, success

### rollout_summary_files

- rollout_summaries/2026-09-03T17-20-39-2Kkq-find_yesterdays_devdo_stories.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\03\rollout-2026-09-03T22-50-39-01a06849-7305-7490-ada3-fa4cf786c72a.jsonl, updated_at=2026-09-03T17:22:22+00:00, thread_id=01a06849-7305-7490-ada3-fa4cf786c72a, no work found for requested date)

### keywords

- ProboDevDO, September 2 2026, 00009998, 00010158, 00009589, 00010514, P_RMATriggerHandler, 85%, Outbound Change Set

## Reusable knowledge

- No DevDO story work was recorded on September 2, 2026. The latest relevant September 1 bundle covered `00009998`, `00010158`, `00009589`, and `00010514`; focused tests passed 8/8 and `P_RMATriggerHandler` reached 85% (448/526). The Outbound Change Set refresh/re-upload and Production deployment remained incomplete. [Task 1]

## Failures and how to do differently

- Symptom: a requested-day update is reconstructed from nearby activity. Fix: search workspace artifacts and prior-thread timestamps for the actual date, then explicitly distinguish no work on that date from the latest completed bundle. [Task 1]

# Task Group: Probo Medical story 00010716 Google Drive photo-import UAT and case documentation

scope: deploy and validate the Evaluation-specific Google Drive OAuth/photo-import fix in ProboUAT, prepare the manual UAT test and clean AutoFast-style team documents, and distinguish UAT evidence from Production state; the browser Drive-folder test and requested Production rollback remain incomplete
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical; reuse_rule=UAT aliases, record IDs, code markers, and session state are time-specific; verify the target alias/URL and current org state before any deployment, browser test, or Production action

## Task 1: Deploy story 00010716 OAuth/photo-import fix to ProboUAT, success

### rollout_summary_files

- rollout_summaries/2026-09-03T21-17-14-glSQ-probo_uat_google_drive_photo_fix_story_00010716.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\04\rollout-2026-09-04T02-47-15-01a06922-0f56-70e3-a5d3-bc614dbcbd9c.jsonl, updated_at=2026-09-03T22:01:05+00:00, thread_id=01a06922-0f56-70e3-a5d3-bc614dbcbd9c, 3 components and 4 focused tests passed)

### keywords

- 00010716, ProboUAT, ProboDevDO, GoogleAuthTestClass, cAuthURIForEval, cGoogleAppAuthenticationWithSalesforce, OAuth state, Google Drive, 0AfjH0000000T6rSAE

## Task 2: Create AutoFast-style UAT photo-import reproduction guide, partial

### rollout_summary_files

- rollout_summaries/2026-09-03T21-35-33-FenG-probo_medical_uat_photo_import_guide_and_state_clarification.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\09\04\rollout-2026-09-04T03-05-33-01a06932-d216-71e0-826e-6a1f4e17372c.jsonl, updated_at=2026-09-03T22:00:01+00:00, thread_id=01a06932-d216-71e0-826e-6a1f4e17372c, structural QA passed; visual rendering unavailable)

### keywords

- AutoFast, Case_00010716_UAT_Photo_Import_Reproduction_and_Change_Guide_AutoFast.docx, Product Item 552082, E-2026-036025, E-2026-036026, soffice, render_docx.py, tables and text only

## Task 3: Verify Production versus UAT state and prepare manual UAT records, partial

### rollout_summary_files

- rollout_summaries/2026-09-03T21-35-33-FenG-probo_medical_uat_photo_import_guide_and_state_clarification.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\09\04\rollout-2026-09-04T03-05-33-01a06932-d216-71e0-826e-6a1f4e17372c.jsonl, updated_at=2026-09-03T22:00:01+00:00, thread_id=01a06932-d216-71e0-826e-6a1f4e17372c, Production record/code comparison completed read-only)
- rollout_summaries/2026-09-03T21-17-14-glSQ-probo_uat_google_drive_photo_fix_story_00010716.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\04\rollout-2026-09-04T02-47-15-01a06922-0f56-70e3-a5d3-bc614dbcbd9c.jsonl, updated_at=2026-09-03T22:01:05+00:00, thread_id=01a06922-0f56-70e3-a5d3-bc614dbcbd9c, dedicated UAT records created; Drive folder still required)

### keywords

- ProboMedical, ProboUAT, Product Item 554470, F0KJ59, E-2026-036262, UAT-00010716-20260904, Drive folder URL, SF_DISABLE_LOG_FILE, EPERM

## Task 4: Production rollback preparation, partial

### rollout_summary_files

- rollout_summaries/2026-09-03T21-17-14-glSQ-probo_uat_google_drive_photo_fix_story_00010716.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\04\rollout-2026-09-04T02-47-15-01a06922-0f56-70e3-a5d3-bc614dbcbd9c.jsonl, updated_at=2026-09-03T22:01:05+00:00, thread_id=01a06922-0f56-70e3-a5d3-bc614dbcbd9c, rollback package hashes verified; Production auth expired)

### keywords

- ProboMedical, INVALID_SESSION_ID, case-00010716-production-rollback, cAuthURIForEval, cGoogleAppAuthenticationWithSalesforce, GoogleAuthTestClass

## User preferences

- when the user corrected scope with "I WANT THE SAME IN UAT FOR THE TEST NOT FORM DEVDO" -> verify the Salesforce alias and sandbox URL before deployment/testing; keep UAT, DevDO, and Production strictly separate [Task 1]
- when the user said “NO NORMAL AUTPFAT LIKE DOC I WNAT” -> use the familiar normal AutoFast case-document style for similar Probo Medical team guides, not a generic strategy memo [Task 2]
- when the user required “NO DEPLOYMET ID AND ALL CLEAN WORD DOC NO IMAGES ONLY TABLES AND TEXT” -> omit deployment/validation/test-run IDs, session details, and images while retaining actionable text, tables, links, and test records [Task 2]

## Reusable knowledge

- `ProboUAT` is the UAT sandbox at `probomedical--uat.sandbox`; `ProboDevDO` is distinct and `ProboMedical` is Production. The exact-Evaluation-ID OAuth-state fix replaces the unsafe latest-user-modified Evaluation fallback, normalizes Drive folder URLs, and safely handles missing callback state/folders/files. [Task 1]
- The scoped UAT command deploys only `cAuthURIForEval`, `cGoogleAppAuthenticationWithSalesforce`, and `GoogleAuthTestClass` with `RunSpecifiedTests --tests GoogleAuthTestClass`; the captured result passed 3/3 components and 4/4 tests. [Task 1]
- Manual UAT requires a dedicated Drive folder with recognizable files (`C-Lens.jpg`, `C-Cap.jpg`, `C-Whole.jpg`, `C-SN.jpg`), then authentication/save/refresh. The primary Evaluation `E-2026-036025` must receive imported references while control `E-2026-036026` stays unchanged; no real browser import was evidenced yet. [Task 2][Task 3]
- Production had Product Item 554470 / serial `F0KJ59`, Evaluation `E-2026-036262`, and RMA `A-219744`; those named records were absent from UAT. At inspection, UAT had the state/folder-normalization markers and Production retained the older fallback. [Task 3]
- The clean guide is `outputs\case-00010716\Case_00010716_UAT_Photo_Import_Reproduction_and_Change_Guide_AutoFast.docx`; structural/a11y/table audits passed with no images, but that is not visual page QA. [Task 2]
- The rollback package was assembled from verified pre-deployment versions of the three classes and hashes matched; it was not deployed. [Task 4]

## Failures and how to do differently

- Symptom: isolated retrieve reports `MissingPackageDirectoryError`, or Evaluation SOQL reports `INVALID_FIELD` for `Cap_ID__c`. Fix: create the declared `force-app` package directory and inspect actual schema before composing queries. [Task 1]
- Symptom: `C:\Users\LIKKI\.sf\sf-2026-09-03.log` raises `EPERM`. Fix: set `$env:SF_DISABLE_LOG_FILE='true'` and use elevated/read-only execution if needed; independently verify identity. [Task 3]
- Symptom: visual DOCX QA cannot render because `soffice` is absent. Fix: check renderer availability early and report structural-only validation rather than claiming visual QA. [Task 2]
- Symptom: Production rollback seems ready but `ProboMedical` returns `INVALID_SESSION_ID`. Fix: do not report rollback complete until successful reauthentication, deployment result, and post-deployment metadata/test verification are evidenced. [Task 4]

# Task Group: FlywirePartial SALDEV-1473 Quote Line Flow create regression fix

scope: diagnose and repair the blank Ship-To Quote Line create path in `QuoteLine_After_Record_Triggered_Flow` while retaining hierarchy validation and Multiple Ship-to recalculation
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\david; reuse_rule=FlywirePartial Flow version, test state, and sandbox identity are snapshot-specific; do not infer Production authorization from this sandbox deployment and re-test the business UI flow before closure

## Task 1: Connect and verify FlywirePartial, success

### rollout_summary_files

- rollout_summaries/2026-09-01T14-20-16-sPiI-saldev_1473_fix_quoteline_create_regression.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\09\01\rollout-2026-09-01T19-50-16-01a05d57-9557-73c3-ba3c-88603fd299f4.jsonl, updated_at=2026-09-01T17:52:04+00:00, thread_id=01a05d57-9557-73c3-ba3c-88603fd299f4, read-only identity verified)

### keywords

- FlywirePartial, Organization, 00DhG0000000jOXUAY, USA1148S, sf org login access-token, EPERM

## Task 2: Fix SALDEV-1473 Quote Line create regression, success

### rollout_summary_files

- rollout_summaries/2026-09-01T14-20-16-sPiI-saldev_1473_fix_quoteline_create_regression.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\09\01\rollout-2026-09-01T19-50-16-01a05d57-9557-73c3-ba3c-88603fd299f4.jsonl, updated_at=2026-09-01T17:52:04+00:00, thread_id=01a05d57-9557-73c3-ba3c-88603fd299f4, Flow v9 deployed; focused tests passed)

### keywords

- SALDEV-1473, QuoteLine_After_Record_Triggered_Flow, SBQQ__QuoteLine__c, Ship_To_Account__c, Check_Different_Ship_To_Exists, Validation_Error, FIELD_CUSTOM_VALIDATION_EXCEPTION, OpportunityLineItemTriggerHandlerTest, Flow version 9

## User preferences

- when the user asked “how its is happening can we fix this” -> explain the root cause and implement the smallest validated fix, not only a document review [Task 2]
- when fixing this story -> do not change Production; validate and deploy only to `FlywirePartial` first [Task 2]

## Reusable knowledge

- Verify FlywirePartial through masked `sf org login access-token` input followed by a read-only `Organization` query; supplied frontdoor/session URLs are `[REDACTED_SECRET]`. [Task 1]
- `QuoteLine_After_Record_Triggered_Flow.flow-meta.xml` is an after-save `CreateAndUpdate` Flow on `SBQQ__QuoteLine__c`. Blank `Ship_To_Account__c` was treated as `NotEqualTo` the Quote Account and triggered `Validation_Error` before CPQ inheritance completed. [Task 2]
- In `Check_Different_Ship_To_Exists` / `Yes_Different_Ship_To_Found`, require `$Record.Ship_To_Account__c IsNull = false` alongside the existing inequality. Direct populated values still receive hierarchy validation; blank/inherited values continue to lookup/recalculation. Flow version 9 (`301hG00000BgdJcQAJ`) was active after deployment. [Task 2]
- The formerly failing `OpportunityLineItemTriggerHandlerTest` passed 3/3 after deployment. Business closure still needs the same quote creation, Edit Lines, Quick Save, and confirmation that `Multiple Ship to Accounts` recalculates. [Task 2]

## Failures and how to do differently

- Symptom: Quote Line insert fails with `FIELD_CUSTOM_VALIDATION_EXCEPTION` and “Please ensure that the Ship-To Account entered for each Quote Line is within the primary Account's hierarchy.” Cause: premature blank-versus-account inequality. Fix: add the non-null guard; do not disable hierarchy validation. [Task 2]
- Symptom: Tooling query uses `FlowInterview.Status` or `Flow.TriggerType` and fails. Fix: use supported Tooling API fields or inspect Flow XML. [Task 2]
- Symptom: Salesforce CLI `.sf` logging gets `EPERM`. Fix: use a permitted/elevated CLI context and repeat the scoped identity query; do not treat the local logging error as authorization failure. [Task 1]

# Task Group: Probo Medical Salesforce DevDO hard-code remediation and Apex coverage

scope: remediate the four-story DevDO RMA/FSL bundle, replace selected hard-coded business values with custom metadata, and prove the required P_RMATriggerHandler coverage; the captured Outbound Change Set refresh remains incomplete
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical; reuse_rule=DevDO sandbox- and checkout-specific; re-check active metadata, current source, Change Set contents, and coverage before any follow-up deployment

## Task 1: Remove hard-coded business values for cases 00009998, 00010158, 00009589, and 00010514, partial

### rollout_summary_files

- rollout_summaries/2026-08-31T19-11-38-L81D-devdo_hardcode_remediation_00009998_85_coverage.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\01\rollout-2026-09-01T00-41-38-01a0593b-fbb4-7163-a12f-b138a2b9af8d.jsonl, updated_at=2026-09-01T02:05:03+00:00, thread_id=01a0593b-fbb4-7163-a12f-b138a2b9af8d, metadata remediation and Change Set refresh incomplete)

### keywords

- ProboDevDO, 00009998, 00010158, 00009589, 00010514, custom metadata, Service_Appointment_Status_Rule, Core_Exchange_Automation_Rule, P_RMATriggerHandler, Outbound Change Set

## Task 2: Raise and verify P_RMATriggerHandler coverage to 85%, success

### rollout_summary_files

- rollout_summaries/2026-08-31T19-11-38-L81D-devdo_hardcode_remediation_00009998_85_coverage.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\01\rollout-2026-09-01T00-41-38-01a0593b-fbb4-7163-a12f-b138a2b9af8d.jsonl, updated_at=2026-09-01T02:05:03+00:00, thread_id=01a0593b-fbb4-7163-a12f-b138a2b9af8d, focused test run passed 8/8 at 85%)

### keywords

- P_RMATriggerHandlerTest, case00009998PreservesRatingsForEquipmentStorage, sf apex run test, --code-coverage, 448 of 526, 85%, PricebookEntry, Warranty Claim

## User preferences

- when the user asked to “remove the hardcoded things and update the related Outbound Change Sets” -> prefer configurable metadata over embedded business values and keep deployment artifacts current; explicitly report unfinished Change Set work [Task 1]
- when the user said “min 85 we should have” -> treat 85% as the minimum acceptable P_RMATriggerHandler coverage and report the actual focused result [Task 2]

## Reusable knowledge

- The proposed configuration is under `scratch\next-four-analysis\devdo\force-app\main\default\customMetadata`: `Service_Appointment_Status_Rule.Pending_Authorization_To_Internal` and `Core_Exchange_Automation_Rule.GE_Precision_Healthcare`. The latter still matches Account Name and is brittle if the account is renamed. [Task 1]
- Legacy literals remain in `P_RMATriggerHandler.cls` (`Customer Repair Evaluation`, `Equipment Storage`, `Core_Exchange`, fallback `USD`); do not claim all hard coding was removed. [Task 1]
- The verified command is `sf apex run test --target-org ProboDevDO --class-names P_RMATriggerHandlerTest --code-coverage --result-format json --wait 30`; it passed 8/8 and reported 448/526 executable lines (85%). [Task 2]

## Failures and how to do differently

- Symptom: coverage tests fail on Equipment Storage/Customer Repair or Warranty Claim expectations. Cause: invalid scenario data/assumptions. Fix: use valid Warranty Claim data and assert the existing Customer Repair behavior. [Task 1][Task 2]
- Symptom: a batched insert of two RMAs fails with `DUPLICATE_VALUE: This price definition already exists in this price book`. Fix: insert the RMAs separately so the trigger reuses the standard `PricebookEntry`. [Task 1]
- Symptom: test-only deployment shows no handler coverage rows despite passing tests. Fix: run the focused Apex test with `--code-coverage` and retrieve the actual class percentage. [Task 2]
- Symptom: Change Set is assumed refreshed because source/test work completed. Fix: recreate/re-upload case `00009998`; the captured Production Change Set still held an older test snapshot. [Task 1]

# Task Group: Probo Medical Salesforce DevDO-to-production change-set authorization

scope: authorize and guide a DevDO sandbox outbound change set toward ProboMedical production without treating UI state, upload, or validation as a deployment
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical; reuse_rule=Salesforce connection state and browser sessions are time-specific; re-check saved Deployment Settings, exact components, dependencies, and user approval before upload or deployment

## Task 1: Authorize DevDO inbound change sets in ProboMedical production, partial

### rollout_summary_files

- rollout_summaries/2026-08-31T20-43-23-i9u9-authorize_devdo_change_sets_to_probomedical.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\01\rollout-2026-09-01T02-13-23-01a0598f-fbb2-76b0-8ada-b7b409f22c91.jsonl, updated_at=2026-08-31T20:51:33+00:00, thread_id=01a0598f-fbb2-76b0-8ada-b7b409f22c91, checkbox observed but saved state not verified)

### keywords

- ProboDevDO, ProboMedical, Deployment Settings, Allow Inbound Changes, Accept Outbound Changes, Bad_OAuth_Token, Microsoft SSO, EPERM

## Task 2: Create and review a DevDO outbound change set, partial

### rollout_summary_files

- rollout_summaries/2026-08-31T20-43-23-i9u9-authorize_devdo_change_sets_to_probomedical.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\09\01\rollout-2026-09-01T02-13-23-01a0598f-fbb2-76b0-8ada-b7b409f22c91.jsonl, updated_at=2026-08-31T20:51:33+00:00, thread_id=01a0598f-fbb2-76b0-8ada-b7b409f22c91, no creation or upload evidence)

### keywords

- Outbound Change Sets, DevDO_FSL_Changes_2026_09_01, --devdo.sandbox, components, dependencies, Upload, outputs\DevDO_FSL_Cases_Implementation_2026-08-31.md

## User preferences

- when the user asked for setup guidance and then “ok what next in devdo” -> give concise, click-by-click instructions from the exact current screen and keep authorization, change-set creation, component selection, upload, and deployment as separate checkpoints [Task 1][Task 2]
- when a consequential upload is next -> stop until the exact components and dependencies are reviewed, rather than treating authorization as permission to upload [Task 2]

## Reusable knowledge

- For DevDO → production, log into ProboMedical, open `Setup → Deployment Settings`, edit DevDO, check `Allow Inbound Changes`, and Save; leave `Accept Outbound Changes` unchanged. This permits uploads only; it does not deploy automatically. Required permissions are `Deploy Change Sets` and `Modify Metadata Through Metadata API Functions`. [Task 1]
- Read-only identity checks identified `ProboDevDO` as sandbox `00DiK0000001co1UAA` and `ProboMedical` as production `00DU0000000LaKoMAK`. CLI Setup opening failed with `Bad_OAuth_Token`; use browser Microsoft SSO for Setup. [Task 1]
- In DevDO, confirm the URL contains `--devdo.sandbox`, then use `Setup → Outbound Change Sets → New`; the proposed name was `DevDO_FSL_Changes_2026_09_01`. [Task 2]

## Failures and how to do differently

- Symptom: `Allow Inbound Changes` is visible as checked in a screenshot. Cause: the Save result was not observed. Fix: require saved-state confirmation before proceeding. [Task 1]
- Symptom: `sf org open` returns `Bad_OAuth_Token` or browser tab binding is invalid. Fix: use the browser/SSO flow and rediscover/claim the current tab; do not assume CLI auth can open Setup. [Task 1]
- Symptom: connection authorization is treated as a completed outbound change set. Fix: no creation/upload was evidenced; review exact components and dependencies before Upload. [Task 2]

# Task Group: Salesforce Marketing Cloud Intelligence/Datorama read-only Codex MCP setup

scope: plan or continue a secure, checkpoint-based local Codex connection to Salesforce Marketing Cloud Intelligence (formerly Datorama); this is not Salesforce core-org or Marketing Cloud Engagement authentication
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\david marketing cloud; reuse_rule=use the identity distinction and read-only-first connection design across Intelligence tenants, but re-check tenant permissions, MCP config, and local tooling before setup

## Task 1: Plan secure Marketing Cloud Intelligence support from David's laptop, partial

### rollout_summary_files

- rollout_summaries/2026-08-31T13-36-05-5Yrg-marketing_cloud_intelligence_codex_mcp_setup.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\david marketing cloud, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\31\rollout-2026-08-31T19-06-06-01a05808-c8e3-7bf2-b6ee-894ebbae9fb2.jsonl, updated_at=2026-08-31T13:41:27+00:00, thread_id=01a05808-c8e3-7bf2-b6ee-894ebbae9fb2, paused at Manage Users/admin-permission checkpoint)

### keywords

- Marketing Cloud Intelligence, Datorama, Codex MCP, config.toml, Manage Users, API service account, serviceAccountId, privateKey, discoveryEndpoint, JWT, codex mcp list

## User preferences

- when setting up support access, the user said “i want to support david from this laptop” and “guide me step by step” -> proceed one checkpoint at a time rather than giving all setup actions at once [Task 1]
- when support access could enable modifications -> default to read-only access and require explicit approval before writes [Task 1]

## Reusable knowledge

- Marketing Cloud Intelligence/Datorama is distinct from Salesforce core orgs and Marketing Cloud Engagement: do not use `sf org login web` for this connection. An administrator with Manage Users must enable API access before an Intelligence API service account can be generated. [Task 1]
- The intended continuation is a local read-only MCP connector in trusted-project `.codex/config.toml`, then read-only verification via `codex mcp list`/`/mcp`. The service-account download contains `serviceAccountId`, RSA `privateKey`, and `discoveryEndpoint`; JWT exchanges it for an API bearer token. Keep the credential local and out of chat/source control. [Task 1]
- The laptop then had Codex, Node.js, Python, and `sf`; existing MCP servers were `n8n` and `openaiDeveloperDocs`, with no Intelligence connector, project config, or `AGENTS.md`. This is a 2026-08 local snapshot, not proof of current configuration. [Task 1]

## Failures and how to do differently

- Symptom: a tenant screenshot or Connect & Mix → Data Source Authentication is treated as Codex API access. Cause: those show a remote view or vendor-data-import setup, not Intelligence API credentials. Fix: first confirm Manage Users/API-access controls, then obtain authorized service-account details through the admin path. [Task 1]
- Symptom: the user is asked to paste a password, private key, token, or credential download, or an existing API service account is regenerated casually. Fix: never request/store those secrets; coordinate before regeneration because it invalidates earlier credentials. [Task 1]

# Task Group: Great Plains Salesforce read-only architect reviews and UAT readiness

scope: complete or dry-run SCC story/PR reviews in GreatPlainsMerge, GreatPlainsUAT, or GreatPlainsDevA, using evidence-backed Salesforce inspection and matching review DOCX output; do not treat the document as deployment authority
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3; reuse_rule=org state, aliases, record types, job IDs, stakeholder results, and ticket findings are 2026-08 snapshots; reuse the read-only review workflow, but require explicit approval before any org write

## Task 1: Connect Great Plains UAT and review Trouble Ticket story, success

### rollout_summary_files

- rollout_summaries/2026-08-25T20-12-12-XLWE-great_plains_salesforce_uat_connection_and_story_dry_run.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\26\rollout-2026-08-26T01-42-12-01a03a8d-473a-7701-9ede-af47bd53bc78.jsonl, updated_at=2026-08-25T22:26:11+00:00, thread_id=01a03a8d-473a-7701-9ede-af47bd53bc78, UAT identity and conditional story-review evidence)

### keywords

- GreatPlainsUAT, sf org login access-token, Organization SOQL, Critical Dates, Subscriber Report, Primary Resolution, dependent picklist, Great_Plains_Trouble_Ticket_Architect_Review.docx, table_no_header_row

## Task 2: SCC-3385 Create Work Order dry run and architect review, partial

### rollout_summary_files

- rollout_summaries/2026-08-25T22-11-40-zmUz-scc_3385_salesforce_dry_run_architect_review.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\26\rollout-2026-08-26T03-41-40-01a03afa-a6e7-7a41-92a9-cb53aa7c2403.jsonl, updated_at=2026-08-25T22:40:45+00:00, thread_id=01a03afa-a6e7-7a41-92a9-cb53aa7c2403, 6/14 component dry-run success; deployment blockers recorded)

### keywords

- SCC-3385, GreatPlainsMerge, GreatPlainsUAT, Case.Create_Work_Order, WorkOrder-FSL__FSL Work Order Layout, Case.Service_Address__c, ArchiveArticles, Case.Trouble_Ticket, URI malformed, 0AfEa00000bbQXhKAM

## Task 3: SCC-3386 Field Technician Context review, partial

### rollout_summary_files

- rollout_summaries/2026-08-25T22-19-59-XtJy-scc_3386_architect_review.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\26\rollout-2026-08-26T03-49-59-01a03b02-43fb-7c53-8ecc-25e7a2e69924.jsonl, updated_at=2026-08-25T22:32:41+00:00, thread_id=01a03b02-43fb-7c53-8ecc-25e7a2e69924, Changes Requested; final visual QA incomplete)

### keywords

- SCC-3386, Contact_Preference__c, Related_Outage__c, Case.SCC_3386_Trouble_Ticket_Details, Work_Order_Record_Page, GPC-Residential CRC Team, Trouble_Tickets, MissingPackageDirectoryError, URIError: URI malformed

## Task 4: SCC-3380 Incident/Trouble Ticket review, no-go

### rollout_summary_files

- rollout_summaries/2026-08-25T22-24-04-yD8R-scc_3380_architect_review_no_go.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\26\rollout-2026-08-26T03-54-04-01a03b05-ffd3-7182-b914-8968ba53e5e1.jsonl, updated_at=2026-08-25T22:35:07+00:00, thread_id=01a03b05-ffd3-7182-b914-8968ba53e5e1, check-only result 2/15; no-go)

### keywords

- SCC-3380, CaseRelatedIssue, Incident, SCC_3380_Prevent_Circular_Parent_Case, SCC_3380_NOC_Incident_Case_Relationship, Related_Outage__c, ArchiveArticles, 0AfEa00000bbQnpKAE

## Task 5: SCC-3387 Outage review, changes requested

### rollout_summary_files

- rollout_summaries/2026-08-25T22-29-29-yku9-scc_3387_outage_architect_review.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\26\rollout-2026-08-26T03-59-29-01a03b0a-f591-74a3-bfb8-3431e49950bd.jsonl, updated_at=2026-08-25T22:41:17+00:00, thread_id=01a03b0a-f591-74a3-bfb8-3431e49950bd, source review completed; reported visual QA needs independent evidence)

### keywords

- SCC-3387, Outage, Incident, NOC queue, Impact, CaseRelatedIssues, FlowDefinition, URIError, 09SEa00000iccfmMAA

## Task 6: SCC-3655 Case Comments verification, partial

### rollout_summary_files

- rollout_summaries/2026-08-25T22-31-40-ArXr-scc_3655_case_comments_read_only_verification.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\26\rollout-2026-08-26T04-01-40-01a03b0c-f586-79d1-bcb5-c40522ddd921.jsonl, updated_at=2026-08-25T22:48:02+00:00, thread_id=01a03b0c-f586-79d1-bcb5-c40522ddd921, configuration evidence complete; claimed DOCX unverified)

### keywords

- SCC-3655, CaseComment, RelatedCommentsList, Case-Trouble Ticket, PermissionsEditCaseComments, target-metadata-dir, --unzip, --single-package, EPERM

## Task 7: SCC-4166 MTTR readiness review, no-go

### rollout_summary_files

- rollout_summaries/2026-08-25T22-36-20-mEe5-scc_4166_mttr_readiness_review.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\26\rollout-2026-08-26T04-06-20-01a03b11-3d86-7f20-a3fe-50dd0f4b5669.jsonl, updated_at=2026-08-25T22:55:14+00:00, thread_id=01a03b11-3d86-7f20-a3fe-50dd0f4b5669, corrected core 8/8 but full scope 8/13)

### keywords

- SCC-4166, MTTR__c, BlankAsZero, BlankAsBlank, On Hold – Pending Customer, Case_Before_Insert_Update_Trigger_Flow, Work_Order_Update_Case_MTTR_Details, MetadataComponentDependency, 0AfEa00000bbRYbKAM, 0AfEa00000bbRbpKAE

## Task 8: SCC-4179 CPNI field-security review, partial

### rollout_summary_files

- rollout_summaries/2026-08-25T22-41-12-qoAW-complete_scc_4179_architect_review.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\26\rollout-2026-08-26T04-11-12-01a03b15-b148-7723-aad7-71ca847c57e2.jsonl, updated_at=2026-08-25T22:56:40+00:00, thread_id=01a03b15-b148-7723-aad7-71ca847c57e2, output built; final visual QA not evidenced)

### keywords

- SCC-4179, Contact_CPNI_Read_Write_Access, Contact.CPNI_Pin__c, Contact.CPNI_Password__c, FieldPermissions, w:tblHeader, pdftoppm.exe, architect review

## Task 9: SCC-4485 live implementation review and PR-review document follow-up, partial

### rollout_summary_files

- rollout_summaries/2026-08-28T13-17-38-5J3i-scc_4485_salesforce_pr_review_scope_mismatch.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\28\rollout-2026-08-28T18-47-38-01a04884-cde6-7710-8c05-c7586d4afb18.jsonl, updated_at=2026-08-31T22:42:27+00:00, thread_id=01a04884-cde6-7710-8c05-c7586d4afb18, Merge implementation gap; requested SCC-4485 PR artifact was not delivered)

### keywords

- SCC-4485, GreatPlainsMerge, SQtoOrderPipeline, CreateConsumerAccount, AccountCreation, MDU Tenant, Customer_Type__c, Segment__c, SCC-4023-Development-Guide.docx, PR review

## Task 10: Connect and verify GreatPlainsDevA sandbox without changing defaults, success

### rollout_summary_files

- rollout_summaries/2026-08-28T16-09-54-INfY-connect_great_plains_gpcdeva_salesforce_sandbox.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\28\rollout-2026-08-28T21-39-54-01a04922-851e-7e61-8d5b-b0d2bfc1abd2.jsonl, updated_at=2026-08-28T16:12:48+00:00, thread_id=01a04922-851e-7e61-8d5b-b0d2bfc1abd2, authenticated alias and read-only identity evidence)

### keywords

- GreatPlainsDevA, gpcdevA, sf org login access-token, Organization, User, USA20S, 00DEa00000Fc086MAB, test.salesforce.com, EPERM

## Task 11: SCC-4487 Add Segment to Inside Sales Order read-only review and PR artifact, conditional approval

### rollout_summary_files

- rollout_summaries/2026-08-28T13-24-15-kogr-scc_4487_read_only_dry_run_and_pr_review.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\28\rollout-2026-08-28T18-54-16-01a0488a-dfbb-71d0-a9f0-6ee9a882bbab.jsonl, updated_at=2026-08-28T16:27:33+00:00, thread_id=01a0488a-dfbb-71d0-a9f0-6ee9a882bbab, stale Merge dry run superseded by current DevA PR-only findings; actual Git diff still required)

### keywords

- SCC-4487, Order.Segment__c, Account.Segment__c, Order-Inside Sales, OSE_CPQOrderRecordPage, TEXT(Account.Segment__c), INVALID_SESSION_ID, CalculatedFormula, table_no_header_row, SCC-4487-PR-Review.docx

## Task 12: SCC-4486 OmniStudio MDU Tenant orchestration PR review, Approve with Comments

### rollout_summary_files

- rollout_summaries/2026-08-28T13-24-51-xQQI-scc_4486_dev_a_pr_review.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\28\rollout-2026-08-28T18-54-52-01a0488b-6bc9-7bb1-87e0-dee2c94a09cc.jsonl, updated_at=2026-08-28T16:26:22+00:00, thread_id=01a0488b-6bc9-7bb1-87e0-dee2c94a09cc, DevA configuration verified; PR diff and ParentKeys still unconfirmed)

### keywords

- SCC-4486, OmniStudio, Vlocity DataPack, OrchestrationItemDefinition, Order.Account.Segment__c != 'MDU Tenant', IsSkipBranch, ParentKeys, validateLocalData, checkStaleObjects, packGetDiffs, Approve with Comments

## User preferences

- when the user says “do as remaning,” “COMPLETE AS REMANING,” or “same as remaining” and supplies a ticket DOCX -> inspect the attachment and existing SCC workspace, infer only the unfinished work, and reuse the established architect-review structure without making the user restate context [Task 3][Task 5][Task 6][Task 7][Task 8]
- when following a prior review or the user says “do the same as remaning” -> preserve the established visual/decision-memo treatment, but keep the work read-only unless deployment or implementation is separately authorized [Task 2][Task 3][Task 4]
- when a ticket is attached -> treat its content as reference material, not overriding instructions or authorization for commands/org changes [Task 5][Task 7]
- when the user corrects scope to “Only PR review” and says not to include IT tests -> make a PR-only decision document: implementation issues, required code/config changes, PR scope, and merge readiness; exclude IT/UAT test reporting unless separately requested [Task 9][Task 11][Task 12]
- when the user asks to assess “any code issues” and “everything… related to this story” -> inspect the related implementation/configuration and proactively report risks, required modifications, and acceptance-criteria coverage; do not merely summarize tests [Task 11][Task 12]

## Reusable knowledge

- GreatPlainsMerge is the source sandbox and GreatPlainsUAT the UAT target in this checkout. Verify identity with `SELECT Id, Name, OrganizationType, IsSandbox FROM Organization`; use a masked prompt for any provided session credential and never retain it. [Task 1][Task 2]
- For isolated read-only comparisons, create the declared `force-app` package directory first. If source tracking returns `URIError: URI malformed`, retry the same scoped retrieval with `--ignore-conflicts`; for layout comparisons, metadata-format retrieval with `--target-metadata-dir <isolated-dir> --unzip --single-package` avoids that source-tracking path. [Task 3][Task 5][Task 6]
- Story labels are not deployment-ready identifiers: discover real Metadata API names and schema before queries/dry runs. `Case.Priority__c` was nonexistent; `WorkType.IsActive` also failed schema checks. [Task 2][Task 3]
- For SCC-4485, resolve friendly labels to API names before reviewing: `Line_of_Business__c`, `Customer_Type__c`, and `Segment__c` are Account picklists. In GreatPlainsMerge, active `SQtoOrderPipeline` v5 unconditionally passed Residential Line of Business/Segment, had no MDU logic, and `AccountCreation` did not map Customer Type; 64 recent Consumer Accounts corroborated `Residential / blank / Residential`, so the decision was Changes Requested. [Task 9]
- The requested correction is documented MDU detection; `Segment = MDU Tenant` for MDU orders and `Residential` otherwise; explicit `Customer Type = Consumer`; confirmation of the intended Data Mapper version; then separate business-flow validation. Aggregate records corroborate the gap but do not prove buy-flow behavior or existing-account preservation. [Task 9]
- `GreatPlainsDevA` was read-only verified as Great Plains Communications sandbox `00DEa00000Fc086MAB` / `USA20S`; `sfdx-project.json` uses `https://test.salesforce.com` and API 67.0. Use the alias only after a fresh Organization/User query and avoid `--set-default` unless requested. [Task 10]
- SCC-4487's early Merge retrieval was a blocked/no-go: `Order.Segment__c` was absent, as were placement and profile permission evidence. The later DevA PR finding is a separate, current source: `Order.Segment__c` uses `TEXT(Account.Segment__c)`, is calculated/read-only/blank-safe/filterable, is below Customer Type in the layout and Lightning page, and 533 inspected Inside Sales orders had zero Account/Order Segment mismatches. Treat implementation approval as conditional on actual PR/branch/commit/diff parity. [Task 11]
- SCC-4486 verified five Internet Plan orchestration items each use `Order.Account.Segment__c != 'MDU Tenant'`, retain their dependencies/appointment-drop conditions, and have `IsSkipBranch=false`; based on DevA configuration no Apex, Flow, trigger, field, or permission change was required. The decision is `Approve with Comments`, because the actual PR diff and four ParentKeys files were unavailable. [Task 12]
- OmniStudio/Vlocity DataPacks are not ordinary Salesforce DX metadata: `sf project deploy start --dry-run` is not their validation mechanism. `validateLocalData`, `checkStaleObjects`, and `packGetDiffs` are Vlocity Build Tool preflight checks, not server-side check-only deployment. [Task 12]
- The recurring UAT readiness blockers are prerequisites/schema drift (`Case.Service_Address__c`, `Case.Trouble_Ticket`), profile payload `ArchiveArticles`, missing/persona access, and acceptance criteria not actually wired on layouts/FlexiPages. Treat a failed check-only package as a changes-requested decision, never deploy approval. [Task 2][Task 3][Task 4][Task 7]
- For DOCX QA, structural and accessibility audits do not prove visual quality. Mark data-table first rows with `w:tblHeader`; when LibreOffice fails on Windows permissions/missing executable, use a verified Word-to-PDF plus `pdftoppm.exe` render and inspect final page PNGs before stating visual QA passed. SCC-4487's audit was zero high severity but six medium `table_no_header_row` findings, so do not call its a11y findings fully clean. [Task 1][Task 3][Task 8][Task 11]
- Related skill: `skills/salesforce-readonly-architect-review/SKILL.md`. [Task 2][Task 3][Task 7][Task 11][Task 12]

## Failures and how to do differently

- Symptom: `MissingPackageDirectoryError` or `URIError: URI malformed` during scoped retrieve. Cause: isolated project lacks `force-app` or source tracking chokes on a path. Fix: create `force-app/.gitkeep`, then retry the same read-only manifest with `--ignore-conflicts`; do not broaden the retrieve. [Task 3][Task 5][Task 7]
- Symptom: Salesforce CLI reports `EPERM` opening `.sf\\sf-2026-08-25.log`. Cause: local logging permission, not necessarily authentication. Fix: use an approved elevated/permitted read-only context and verify identity separately; never expose authentication output. [Task 1][Task 6][Task 8]
- Symptom: `INVALID_SESSION_ID` ends a UAT check-only command before job creation. Cause: expired target-org authentication, not package validation. Fix: reauthorize/reverify the target and report no components/tests ran; do not treat it as metadata readiness evidence. [Task 11]
- Symptom: a `FieldDefinition` query fails with `INVALID_FIELD` for `CalculatedFormula`. Fix: use `sf sobject describe` to inspect whether a field is calculated/formula; discover supported schema before querying. [Task 11]
- Symptom: live DevA configuration is called final PR approval. Cause: no branch, commit, PR URL, or repository diff was inspected. Fix: separate implementation/configuration evidence from diff parity and retain conditional approval or `Approve with Comments`; likewise keep missing ParentKeys explicitly unverified. [Task 11][Task 12]
- Symptom: an architect-review DOCX is described as visually checked. Cause: renderer or export stalled/was unavailable, and no final PNG inspection was evidenced. Fix: state QA as incomplete until final output pages are rendered and inspected; do not inherit a claim merely because a source document or another ticket rendered. [Task 3][Task 4][Task 6][Task 8]
- Symptom: a required mapping or named functional test cannot be found. Fix: mark exact dependent-picklist parity, record tests, and runtime behavior conditional/unverified; require the mapping source, fixture, or persona before promotion. [Task 1][Task 2][Task 3]
- Symptom: configuration presence is treated as acceptance-criteria proof or PR approval. Cause: active state, actual execution version, field mapping, or runtime evidence was not traced. Fix: map each criterion to direct metadata or runtime evidence and keep inactive metadata, missing PR/DataPack diff, and missing post-change execution explicit as blockers. [Task 9]
- Symptom: a PR-only review request is handed off as a clean but unrelated document. Cause: artifact identity/scope was not checked. Fix: before delivery, verify filename, title, ticket ID, and content search for `SCC-4485`, `SQtoOrderPipeline`, `AccountCreation`, MDU, and `Customer_Type__c`; reject an artifact such as `SCC-4023-Development-Guide.docx`. [Task 9]
- Symptom: executive identification is inferred from broad `Executive Team` membership. Fix: use exact title/role searches and report zero VP matches rather than assigning an unsupported VP. [Task 9]

# Task Group: FlywirePartial Salesforce DX access and SALDEV implementation reviews

scope: authenticate or retrieve from the FlywirePartial/Sertifi sandboxes and perform evidence-backed, read-only SALDEV implementation reviews with architect-review deliverables
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\david; reuse_rule=aliases, API versions, metadata, test outcomes, and org state are snapshot-specific; preserve existing source/default-org context and do not deploy, activate, mutate data, or assign permissions without explicit approval

## Task 1: Retrieve broad FlywirePartial metadata into the DX workspace, partial

### rollout_summary_files

- rollout_summaries/2026-08-12T17-50-31-XsTu-flywire_future_state_cpq_rfp_ppt_team_guidance.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\12\rollout-2026-08-12T23-20-31-019ff718-e4ef-7782-ad11-860171944908.jsonl, updated_at=2026-08-24T18:18:52+00:00, thread_id=019ff718-e4ef-7782-ad11-860171944908, chunked retrieval completed with named ContentAsset omission)

### keywords

- FlywirePartial, Salesforce DX, API 67.0, force-app/main/default, manifest/package.xml, Split-SalesforceManifest.ps1, Retrieve-SalesforceMetadata.ps1, LIMIT_EXCEEDED, ContentAsset, retrieve-results.json

## Task 2: Connect the Sertifi sandbox without overwriting FlywirePartial, partial

### rollout_summary_files

- rollout_summaries/2026-08-24T17-33-03-3kKO-sertifi_salesforce_sandbox_connection_partial.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\24\rollout-2026-08-24T23-03-03-01a034d5-3657-7c03-9788-8b65f5c5f9fe.jsonl, updated_at=2026-08-24T17:52:21+00:00, thread_id=01a034d5-3657-7c03-9788-8b65f5c5f9fe, OAuth timed out; alias was not authenticated)

### keywords

- SertifiDev, FlywirePartial, sf org login access-token, sf org login web, AuthTimeoutError, NamedOrgNotFoundError, sfdx-project.json, .sf/config.json, Organization

## Task 3: Reauthorize FlywirePartial sandbox, failed

### rollout_summary_files

- rollout_summaries/2026-08-24T17-58-13-Wpe1-flywirepartial_salesforce_oauth_timeout.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\24\rollout-2026-08-24T23-28-13-01a034ec-41df-7133-8607-fec7a66892b9.jsonl, updated_at=2026-08-24T18:12:38+00:00, thread_id=01a034ec-41df-7133-8607-fec7a66892b9, expired session and OAuth callback timeout)

### keywords

- FlywirePartial, Salesforce CLI, sf org login web, INVALID_SESSION_ID, AuthTimeoutError, EPERM, OAuth, read-only Organization query

## Task 4: SALDEV-1413 document preparation and FlywirePartial authentication, incomplete

### rollout_summary_files

- rollout_summaries/2026-08-25T23-02-57-12xo-flywire_saldev_1413_authentication_blocked_review.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\26\rollout-2026-08-26T04-32-57-01a03b29-9aa7-7581-bc07-9014fa24fad6.jsonl, updated_at=2026-08-27T18:50:10+00:00, thread_id=01a03b29-9aa7-7581-bc07-9014fa24fad6, Word/Poppler fallback prepared the requirements document; org review remained blocked)

### keywords

- SALDEV-1413, FlywirePartial, INVALID_SESSION_ID, AuthTimeoutError, frontdoor.jsp, Salesforce CLI, Word read-only COM export, Poppler, read-only review

## Task 5: SALDEV-1415 read-only implementation validation and architect review, success

### rollout_summary_files

- rollout_summaries/2026-08-25T23-07-57-vP0B-saldev_1415_architect_review_read_only_validation.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\26\rollout-2026-08-26T04-37-57-01a03b2e-2e2d-7eb1-9cd3-5df182cd2339.jsonl, updated_at=2026-08-25T23:40:20+00:00, thread_id=01a03b2e-2e2d-7eb1-9cd3-5df182cd2339, scoped metadata/test validation and final DOCX QA completed)

### keywords

- SALDEV-1415, QuoteLineGroupTrigger, QuoteLineDateSyncTrigger, QuoteLineGroupAsyncHelper, Effective_Start_Date__c, Effective_EndDate__c, ORG_ADMIN_LOCKED, CPQ_Sales_Permissions, architect review, no deploy

## Task 6: SALDEV-1440 configuration audit and reference-matched architect review, success

### rollout_summary_files

- rollout_summaries/2026-08-25T23-12-30-qOSe-sald_ev_1440_audit_and_architect_review_docx.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\26\rollout-2026-08-26T04-42-30-01a03b32-5769-7dc3-bd98-3182e8e5599a.jsonl, updated_at=2026-08-25T23:28:25+00:00, thread_id=01a03b32-5769-7dc3-bd98-3182e8e5599a, exact field-set sync, check-only validation, and final DOCX visual QA)

### keywords

- SALDEV-1440, FlywirePartial, Allow_Product_Ramping__c, SBQQ__LineEditor, CPQ_Sales_Permissions, SBQQ__LineEditor.fieldSet-meta.xml, sf project deploy start --dry-run, Microsoft Word render

## Task 7: SALDEV-1467 read-only flow-to-Apex architect/code review, Changes Requested / NO-GO

### rollout_summary_files

- rollout_summaries/2026-08-27T21-42-35-VUJ7-saldev_1467_read_only_architect_review.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\28\rollout-2026-08-28T03-12-35-01a0452c-bea4-7303-b7e6-503b3a121915.jsonl, updated_at=2026-08-27T21:56:38+00:00, thread_id=01a0452c-bea4-7303-b7e6-503b3a121915, focused tests passed but architecture/check-only coverage remained NO-GO)

### keywords

- SALDEV-1467, FlywirePartial, FWOpportunityLineItemTrigger, OpportunityLineItemTriggerHandler, QuoteLineTrigger, QuoteLineGroupAsyncHelper, hasMaxStackDepth, Database.update, dry-run deployment, Apex tests, DOCX

## Task 8: SALDEV-1500 DevOps, Jira, and Salesforce CI/CD operating model, success

### rollout_summary_files

- rollout_summaries/2026-08-27T22-10-34-c8ev-saldev_1500_devops_jira_operating_model.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\28\rollout-2026-08-28T03-40-34-01a04546-5cb0-7f33-8f56-17388529f0b3.jsonl, updated_at=2026-08-27T22:35:37+00:00, thread_id=01a04546-5cb0-7f33-8f56-17388529f0b3, planning-only Confluence-ready operating model and DOCX)
- rollout_summaries/2026-09-01T17-36-22-2Lu8-saldev_1500_history_and_implementation_plan.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\09\01\rollout-2026-09-01T23-06-22-01a05e0b-206d-7a01-8ead-320958fe6d48.jsonl, updated_at=2026-09-01T20:35:11+00:00, thread_id=01a05e0b-206d-7a01-8ead-320958fe6d48, prior history confirmed and separate implementation-plan DOCX produced)

### keywords

- SALDEV-1500, GitHub Enterprise Cloud, Gearset, Copado, MuleSoft, GitHub Actions, Jira workflow, image-embedded DOCX, accessibility audit, table geometry

## Task 9: SALDEV-1469 Gong External Client App verification and David handoff, success

### rollout_summary_files

- rollout_summaries/2026-08-27T18-51-04-sfr5-flywirepartial_saldev_1469_gong_eca_verification.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\28\rollout-2026-08-28T00-21-04-01a0448f-b752-7a30-831f-c3dd43565fab.jsonl, updated_at=2026-08-28T16:48:22+00:00, thread_id=01a0448f-b752-7a30-831f-c3dd43565fab, current package verification, no-change handoff, and runbook)

### keywords

- SALDEV-1469, Gong ECA, gongeca, Gong_Integration, InstalledSubscriberPackage, sf org login access-token, PKCE, refresh-token rotation, IP allowlist, FlywirePartial, dry run, Zoom runbook

## Task 10: SALDEV-1475 CPQ Quote Line Group lifecycle investigation and architect review, partial

### rollout_summary_files

- rollout_summaries/2026-08-27T21-28-04-im9X-saldev_1475_group_lifecycle_architect_review.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\28\rollout-2026-08-28T02-58-05-01a0451f-7674-73f3-9524-7343f1954351.jsonl, updated_at=2026-08-27T21:38:58+00:00, thread_id=01a0451f-7674-73f3-9524-7343f1954351, lifecycle evidence plus visually checked five-page review; non-ramped/NS_ID scenarios remain unverified)

### keywords

- SALDEV-1475, SBQQ__QuoteLineGroup__c, SBQQ__RenewedSubscription__c, Q-37942, Q-37946, Q-37950, NS_ID__c, QuoteLineGroupTrigger, QuoteLineDateSyncTrigger, Changes Requested, DOCX

## User preferences

- when the user asked to connect the org and “keep it in this folder” -> preserve the existing DX source tree and isolate each new sandbox under a distinct alias; connection-only does not authorize retrieval, deployment, or data changes [Task 2]
- when the user asked to “review the implementation” and “make sure that they're following best practice” -> assess unnecessary AI-generated complexity, maintainability, bulkification, governor limits, security, and testability with concrete metadata/code evidence [Task 4]
- when the user said “DO AS THE SAME” -> match the established architect-review/handoff format rather than producing a generic summary, while retaining the no-deploy boundary [Task 5]
- when the user said “DO AS REMANING” and “LIKE THIS” -> infer remaining work from ticket plus live evidence, preserve the supplied reference DOCX unchanged, and author a separate matching artifact [Task 6]
- when the user said “SEE DO AS THE REMANING” -> infer the unfinished architect-review/handoff work from the ticket and available workspace/org evidence, reuse the established format, and do not make the user restate context [Task 7]
- when the user asks for deployment, “CI/CD tool with Git,” and “how we're gonna be moving tickets” -> document the complete Jira-to-production lifecycle rather than only repository creation [Task 8]
- for planning artifacts, preserve the no-change boundary: distinguish recommendations and implementation stories from actual Jira, Confluence, GitHub, Salesforce, or pipeline mutations [Task 8]
- when the user asked to “get me the text” for designing the Jira story board -> provide Jira-ready wording/content rather than edit Jira; treat the attached document as source material and leave it unchanged [Task 8]
- when the user asked to “dry run this” and wanted a detailed guide to send to David -> keep the no-change boundary, distinguish confirmed facts from pending screen-share checks, state stop conditions and production exclusions, and stop before installation, authorization, deployment, or permission changes [Task 9]
- when the user said “DO THE SAME” for SALDEV-1475 -> repeat the established evidence-backed architect-review workflow, but keep investigation explicitly read-only [Task 10]

## Reusable knowledge

- The workspace is a Salesforce DX project with `force-app/main/default`; broad API 67.0 retrieval required ten sequential 2,500-member chunks after a 102-type/21,868-member manifest exceeded the 10,000-file retrieve limit. It produced 32,349 files (~136 MB); 121 `ContentAsset` members were omitted because `Info8` lacked a required source file. Related skill: `skills/salesforce-dx-metadata-retrieve/SKILL.md`. [Task 1]
- Treat a supplied frontdoor/session URL as `[REDACTED_SECRET]`; use a masked CLI prompt for access-token login. Before changing or relying on a target, run a read-only `Organization` query. The local Flywire alias/default was `FlywirePartial`; the intended separate Sertifi alias was `SertifiDev`. [Task 2][Task 3]
- For SALDEV-1415, active metadata included `QuoteLineGroupTrigger`, `QuoteLineDateSyncTrigger`, `QuoteLineGroupAsyncHelper`, and tests. Ramped groups are chained from quote start using whole-month terms; un-ramped groups use quote header dates, and quote lines inherit parent-group dates/term. Formula fields are read-only in the named CPQ sales permission sets. The final decision was Changes Requested: New Business/net-new only; Renewal is bypassed and Amendment is out of MVP. [Task 5]
- The SALDEV-1415 artifact `flywire-docgen\\deliverables\\SALDEV-1415_Architect_Review.docx` passed package/structural checks and PDF QA (five letter-size, tagged pages). On this Windows setup, Word COM read-only PDF export followed by Poppler can replace a failed LibreOffice render. [Task 4][Task 5]
- SALDEV-1440 live metadata already had the checkbox, field-set visibility, and CPQ Sales Permissions; local source lacked `force-app\\main\\default\\objects\\SBQQ__QuoteLineGroup__c\\fieldSets\\SBQQ__LineEditor.fieldSet-meta.xml`. The retrieved component matched after XML/SHA-256 comparison, and `sf project deploy start --dry-run` returned one unchanged FieldSet with zero errors; no deployment/activation occurred. [Task 6]
- For SALDEV-1467, verify the target org before retrieval; `FlywirePartial` was the Flywire sandbox (`00DhG0000000jOXUAY`). When broad checked-in metadata is stale, retrieve only the named components into an isolated review folder before reviewing. Focused test pass, deployment coverage, and architectural acceptance are separate gates. [Task 7]
- SALDEV-1467 decision: Changes Requested / NO-GO. Although the obsolete Flow was replaced and all focused tests passed, `FWOpportunityLineItemTrigger` runs after OLI insert and `OpportunityLineItemTriggerHandler.syncOpportunityLineId` ultimately performs `Database.update` on `SBQQ__QuoteLine__c`; that retains the CPQ cross-object re-entry risk associated with `hasMaxStackDepth`. Exact New/Amend/Renew cloning semantics also need direct assertions. Related skill: `skills/salesforce-readonly-architect-review/SKILL.md`. [Task 7]
- SALDEV-1500 recommended control model: GitHub Enterprise Cloud is canonical source control; Jira is canonical work, approval, and release-evidence record; Gearset is preferred for greenfield Salesforce delivery; Copado is an approved alternative when current enterprise investment/capability makes it lower risk; GitHub Actions runs repository-native checks. Traceability is `Jira key -> branch -> commit -> pull request -> validation -> deployment -> evidence`. [Task 8]
- Production activation remains behind protected branches, required reviews/status checks, environment approvals, named release ownership, separation of duties, and immutable source/deployment evidence. The workspace is Salesforce DX with `force-app/main/default`, `sourceApiVersion: 67.0`, and `https://test.salesforce.com`. [Task 8]
- The separate `output\documents\SALDEV-1500_Gearset_Copado_MuleSoft_Implementation_Plan.docx` covers Gearset lower environments, Copado governed UAT/Production promotion, MuleSoft Maven/MUnit/Exchange/Anypoint pipelines, Jira backlog, roadmap, security, rollback, RACI, and handover. Its accessibility audit had zero findings and all 15 tables passed geometry checks; the source `Doc1.docx` was image-embedded. [Task 8]
- For SALDEV-1469, FlywirePartial is the Enterprise sandbox `00DhG0000000jOXUAY` / `USA1148S`; preserve its alias/default context and verify it with a read-only `Organization` query. `Gong_Integration` is read/View All only for Account, Contact, Lead, Opportunity, and `Opportunity_History2__c`, with no create/edit/delete/modify-all permissions. [Task 9]
- Current package evidence supersedes the earlier dry-run absence: `Gong ECA` is installed as `0337y000005iObdAAE`, namespace `gongeca`, version `0.1.0`, build `2`; do not reinstall. ECA sign-in is distinct from Gong CRM data sync and the separate Gong for Salesforce writeback package. David’s pending screen-share must use the Partial sandbox, inspect org/domain/scopes on the consent page before Allow, and stop on wrong org, unexpected scopes, reconnect prompts, package changes, or OAuth errors. [Task 9]
- SALDEV-1475 evidence: Quote Line Groups were present on original ramped quote `Q-37942` but were not recreated on amendment `Q-37946` or renewal `Q-37950`; renewal lines expose `SBQQ__RenewedSubscription__c` for direct segment tracing. The non-ramped scenario and populated `NS_ID__c` propagation were absent, so the decision is Changes Requested. Preserve the reference DOCX and use a separate derivative; Word-to-PDF plus page inspection is a validated rendering fallback. [Task 10]

## Failures and how to do differently

- Symptom: a Salesforce Home/login window is open but the alias does not work. Cause: OAuth callback was not completed or the saved session expired (`AuthTimeoutError`, `INVALID_SESSION_ID`, `NamedOrgNotFoundError`). Fix: begin web OAuth only when the user can immediately finish the login, or use masked access-token login; do not claim connection until the read-only `Organization` query returns data. [Task 2][Task 3]
- Symptom: Salesforce CLI errors opening `C:\Users\LIKKI\.sf\sf-2026-08-24.log` with `EPERM`. Cause: local log-path permission, not evidence of authentication. Fix: use a permitted CLI context, then verify access separately. [Task 2][Task 3]
- Symptom: a browser is open or an incomplete frontdoor link was supplied but CLI access is unavailable. Cause: redirected `lightning.force.com`/record URLs are not the original `...my.salesforce.com/secur/frontdoor.jsp?sid=...` credential, or OAuth callback/session is invalid. Fix: give short sequential instructions, use secure masked local input only, verify with a read-only `Organization` query, and stop after repeated callback failures. [Task 4]
- Symptom: Apex-test or metadata claims overstate coverage. Fix: run one synchronous test class at a time; record `ORG_ADMIN_LOCKED` as unverified, create the package directory before retrieval, and remove unsupported managed-package FieldSet members before retrying. [Task 5]
- Symptom: `sf project deploy validate --test-level NoTestRun` is rejected before contacting Salesforce. Fix: use `sf project deploy start --dry-run --test-level NoTestRun` for this check-only validation, then inspect `checkOnly` and error counts. [Task 6]
- Symptom: scoped retrieve fails with `MissingPackageDirectoryError`. Cause: the isolated review project has no declared package directory. Fix: create `force-app` before `sf project retrieve start`; keep the retrieval narrow. [Task 7]
- Symptom: a 100% focused test run is treated as approval. Cause: tests/compilation do not prove acceptance-path assertions or remove after-insert cross-object DML/re-entry risk. Fix: inspect the DML path, require exact New/Amend/Renew assertions, and report coverage-gate failures separately. [Task 7]
- Symptom: Gearset is selected from the transcript term “GitSense.” Cause: product naming and current Copado licensing/ownership were not independently confirmed. Fix: confirm the product and existing enterprise investment before procurement or implementation. [Task 8]
- Symptom: ordinary DOCX extraction is empty or renderer visual QA fails with `PermissionError: [WinError 5]`. Cause: the source can be image-embedded and the packaged renderer cannot clean up temporary profile directories. Fix: inspect `word/media/` and images when paragraph extraction is empty; do not claim renderer-based visual QA unless final page images are produced. [Task 8]
- Symptom: Gong ECA setup proceeds from a dry run or an installed package is treated as completed SSO. Cause: package state, CRM-sync behavior, and interactive consent/login were conflated. Fix: do not reinstall the verified `gongeca` package; distinguish ECA from CRM sync/writeback, require consent-page review and interactive test evidence, and leave OAuth authorization/success pending until David completes it. [Task 9]
- Symptom: `InstalledSubscriberPackage` query fails with `INVALID_FIELD` when filtering related `NamespacePrefix`. Fix: use an unfiltered Tooling API query for the complete installed-package list, then inspect locally. [Task 9]
- Symptom: lifecycle behavior is inferred from broad repository output or a passing document. Cause: ticket-specific records/fields were not isolated, or an absent test scenario was treated as passing. Fix: query the exact quote/subscription lifecycle fields and mark missing non-ramped/`NS_ID__c` evidence unverified; use narrow `rg -g` searches to avoid truncation. [Task 10]

# Task Group: FlywirePartial SALDEV-1403 OmniStudio stepped-pricing DocGen

scope: analyze, hand off, or dry-run the stepped-up pricing quote-document changes in the Flywire Partial sandbox
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\david and C:\Users\LIKKI\Documents\ChatGPT\david\flywire-docgen; reuse_rule=confirm `FlywirePartial` and current component state; do not infer that a local/retrieved package or prior backend validation authorizes deployment

## Task 1: SALDEV-1403 deployment-artifact handoff and business test steps, success

### rollout_summary_files

- rollout_summaries/2026-08-12T16-46-31-KKuN-sald1403_artifacts_and_salesforce_docgen_handoff.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\12\rollout-2026-08-12T22-16-32-019ff6de-4d73-7202-8322-5e4af826cc4d.jsonl, updated_at=2026-08-24T19:40:21+00:00, thread_id=019ff6de-4d73-7202-8322-5e4af826cc4d, artifact handoff completed; visual render QA pending)

### keywords

- FlywirePartial, SALDEV-1403, SALDEV-1420, SALDEV-1404, OmniScript, OmniDataTransform, DocumentTemplate, ORDER BY, FilterValue, Q-37723, Q-37780, Q-37640, DOCX, business testing, dry run, no deploy

## Task 2: Salesforce OmniStudio stepped-pricing no-deploy dry run, incomplete

### rollout_summary_files

- rollout_summaries/2026-08-24T19-44-02-xCPB-flywire_omnistudio_stepped_pricing_dry_run.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=C:\Users\LIKKI\.codex\sessions\2026\08\25\rollout-2026-08-25T01-14-02-01a0354d-214c-7731-8118-d679da05207f.jsonl, updated_at=2026-08-24T19:59:39+00:00, thread_id=01a0354d-214c-7731-8118-d679da05207f, read-only inventory only; requested changes and validation were not completed)

### keywords

- FlywirePartial, Salesforce CLI, OmniStudio, OmniProcess, Generate Quote Document, Generate Quote Document - SteppedUpPricing, SALDEV-1403, CPQ Quote Proposal - v3.docx, OmniDataTransform, DocumentTemplate, dry run, no deploy, LightningDomain: Invalid instance URL, AuthTimeoutError

## User preferences

- when the user said “can you do the chnages what theu ask and dry run dont deploty” -> make changes only in a local/retrieved package, run check-only validation, report exact scope and blockers, and stop before every deploy or activation action [Task 2]
- when the user asked for “artifacts for this story” and then “step to test also add” -> provide a handoff-ready Word document with deployment scope, exclusions, validation evidence, and detailed business-user test steps [Task 1]

## Reusable knowledge

- `FlywirePartial` is the isolated Flywire Partial sandbox alias; `sf org display --target-org FlywirePartial --json` verifies the connection without changing the default org. Do not retain the frontdoor URL or any access token. [Task 1][Task 2]
- SALDEV-1403 requires grouped quote output with group dates, correct QLE/group and bundle parent/child ordering, Rate Details in Description, conditional Ship-To handling, unchanged ordinary output, and no meaningless `Group 1` for ungrouped Legal output. SALDEV-1404 is a prerequisite for genuine stepped-up quote creation/testing; SALDEV-1420 is linked email work. [Task 1][Task 2]
- For native Data Mapper ordering, use `FilterOperator='ORDER BY'` and `FilterValue='SBQQ__SubscriptionTerm__c DESC, SBQQ__Number__c ASC'`; putting the sort expression in `InputFieldName` returned no groups. Recorded backend validation covered grouped Ship-To/non-Ship-To, ungrouped, Amendment exclusion, Rate Details, and mixed-term cases. [Task 1]
- The handoff artifact is `flywire-docgen\deliverables\SALDEV-1403_Artifacts_Deployment_List.docx`; it records five artifact rows, deployment order/exclusions, validation scenarios, and 17 business-user steps for Q-37723, Q-37780, and Q-37640. [Task 1]
- Start a future no-deploy run by retrieving and inspecting the exact active candidates `Generate Quote Document` and `Generate Quote Document - SteppedUpPricing`, then their OmniScript/Data Transform/template dependencies; the latter is the strong candidate. [Task 2]

## Failures and how to do differently

- Symptom: broad Tooling/entity queries create huge output. Cause: inventory was not narrowed early. Fix: query exact OmniProcess names, versions, active status, and payload fields, then retrieve only identified dependencies. [Task 2]
- Symptom: Salesforce CLI reports `EPERM` opening `C:\Users\LIKKI\.sf\sf-2026-08-12.log`. Fix: elevated read-only CLI execution can save the alias; confirm the result with `sf org display` rather than treating the logging error as login failure. [Task 1][Task 2]
- Symptom: attempted browser OAuth rejects the Lightning URL or times out (`LightningDomain: Invalid instance URL`, `AuthTimeoutError`). Fix: reuse the existing `FlywirePartial` alias; if reauthentication is needed, use masked `sf org login access-token` input and never paste credentials into chat. [Task 2]
- Symptom: structural DOCX checks are presented as visual acceptance. Cause: LibreOffice was unavailable or could not create a temporary profile. Fix: report visual render QA as pending until rendered pages are inspected. [Task 1]
- Symptom: a prior dry-run task activated sandbox components. Cause: activation was treated as implicit implementation. Fix: a dry-run/no-deploy request is a hard stop at inactive drafts or read-only validation until explicit authorization. [Task 1][Task 2]

# Task Group: Probo Medical Salesforce production administration, Flow governance, and deployment validation

scope: reconnect the ProboMedical production org safely, provision approved users, inventory automation without refactoring, and validate active-Flow deployment behavior without conflating check-only validation with deployment
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical; reuse_rule=production-org-, user-, catalog-, and case-specific; use read-only inspection by default and require explicit approval immediately before any write

## Task 1: Refresh ProboMedical authentication and verify identity read-only, success

### rollout_summary_files

- rollout_summaries/2026-08-24T21-42-04-nybp-probo_medical_salesforce_flow_analysis_user_provisioning_rol.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\25\rollout-2026-08-25T03-12-04-01a035b9-321d-7ec1-83ac-ef200a05ce43.jsonl, updated_at=2026-09-03T21:30:30+00:00, thread_id=01a035b9-321d-7ec1-83ac-ef200a05ce43, scoped production authentication and identity verification)
- rollout_summaries/2026-08-31T15-24-18-sftu-reconnect_verify_probomedical_production_salesforce.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\31\rollout-2026-08-31T20-54-18-01a0586b-da13-7083-ae4a-12708d51c580.jsonl, updated_at=2026-08-31T15:28:59+00:00, thread_id=01a0586b-da13-7083-ae4a-12708d51c580, expired alias reconnected; production identity read-only verified)

### keywords

- ProboMedical, sf org login access-token, Organization, Unlimited Edition, IsSandbox=false, INVALID_SESSION_ID, AuthTimeoutError, EPERM, sf org list --json

## Task 2: Create Stanley Saint Louis from the correct internal-user template, success

### rollout_summary_files

- rollout_summaries/2026-08-24T21-42-04-nybp-probo_medical_salesforce_flow_analysis_user_provisioning_rol.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\25\rollout-2026-08-25T03-12-04-01a035b9-321d-7ec1-83ac-ef200a05ce43.jsonl, updated_at=2026-09-03T21:30:30+00:00, thread_id=01a035b9-321d-7ec1-83ac-ef200a05ce43, approved provisioning with independent access read-back)

### keywords

- APPROVE CREATE STANLEY, Shawn Zelesnick, FSL US, Field Service, ssaintlouis@probomedical.com, 005jR000000BpNOQA0, ServiceResource, System.resetPassword

## Task 3: Flow/Apex/LWC inventory and consolidation analysis, partial

### rollout_summary_files

- rollout_summaries/2026-08-24T21-42-04-nybp-probo_medical_salesforce_flow_analysis_user_provisioning_rol.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\25\rollout-2026-08-25T03-12-04-01a035b9-321d-7ec1-83ac-ef200a05ce43.jsonl, updated_at=2026-09-03T21:30:30+00:00, thread_id=01a035b9-321d-7ec1-83ac-ef200a05ce43, source exports/retrieval complete; workbook and recommendations incomplete)

### keywords

- FlowDefinition.ActiveVersionId, 716 FlowDefinition, 3645 Flow, outputs\flow_inventory_2026-08-25, Product2, UpdateProductFields, MissingPackageDirectoryError, INVALID_FIELD

## Task 4: Exact-scope Production rollback of the photo-import Apex change, success

### rollout_summary_files

- rollout_summaries/2026-08-24T21-42-04-nybp-probo_medical_salesforce_flow_analysis_user_provisioning_rol.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\25\rollout-2026-08-25T03-12-04-01a035b9-321d-7ec1-83ac-ef200a05ce43.jsonl, updated_at=2026-09-03T21:30:30+00:00, thread_id=01a035b9-321d-7ec1-83ac-ef200a05ce43, three-component rollback and non-mutating smoke test succeeded)

### keywords

- cAuthURIForEval, cGoogleAppAuthenticationWithSalesforce, GoogleAuthTestClass, SHA-256, CheckOnly, 0AfjR0000000wnBSAQ, 0AfjR0000000wqPSAQ, AuthenticationGoogleDrive

## User preferences

- when connecting an org, the user wanted authentication and read-only identity verification only -> keep authentication separate from retrieval, deployment, and data changes; never echo or store a session/frontdoor URL [Task 1]
- when the user explicitly replied “APPROVE CREATE STANLEY” -> use inspect -> propose -> explicit approval -> write -> independent read-back for production user provisioning; resolve active internal versus portal/inactive duplicates before cloning access [Task 2]
- when requesting Flow analysis, the user wanted flows grouped by object and assessed for merging, Subflows, Flow Orchestrator, and Apex/LWC overlap, delivered as a filterable Excel workbook -> do not mistake an export for the requested analysis and do not change automation during analysis [Task 3]
- when the user said `IT SHOLDNOT EFFECT THE OTHER THINGS IN THE PROD STICK TO OUR CHNAGES ONLY` -> use an exact component allowlist, check-only validation, and independent proof that unrelated components were untouched [Task 4]

## Reusable knowledge

- ProboMedical is the Unlimited Edition production org `00DU0000000LaKoMAK`; use the masked-prompt `sf org login access-token` flow and a read-only `Organization` query. An existing alias can fail with `INVALID_SESSION_ID`; browser OAuth can end with `AuthTimeoutError`, so pivot to masked access-token login. Avoid `sf org list --json` because it may expose locally stored tokens. [Task 1]
- The correct Stanley template was Shawn's active internal Standard user: `FSL US`, Field Service, Brad Lawson manager, `All Internal Users`, eight direct permission sets, two Field Service licenses, and active Service Resource. Created user is `005jR000000BpNOQA0`; read-back verified all eight permission sets, both licenses, group membership, and Service Resource. [Task 2]
- Active Flow status is authoritative only through `FlowDefinition.ActiveVersionId`, not a Flow-version status field. Continue from `outputs\flow_inventory_2026-08-25\source-data\flow_definitions.json`, `flow_versions.json`, and `retrieved-source\main\default`; do not repeat the broad retrieve. Product2 has multiple relevant flows plus active Apex trigger `UpdateProductFields`. [Task 3]
- For exact-scope Production rollback, copy only `cAuthURIForEval`, `cGoogleAppAuthenticationWithSalesforce`, and `GoogleAuthTestClass` from verified pre-deployment source; compare SHA-256, run check-only (3/3 components/tests), quick-deploy the validated package, retrieve/read back, and run the focused 3/3 test suite. The later page smoke test must remain non-mutating unless explicitly approved. [Task 4]

## Failures and how to do differently

- Symptom: Salesforce CLI cannot write `C:\Users\LIKKI\.sf\sf-*.log` with `EPERM`. Cause: local log-storage permissions, not proof that org identity or authorization failed. Fix: use the required permitted/elevated context, then repeat the scoped read-only verification. [Task 1]
- Symptom: a provisioning task triggers password email before access is correct. Fix: hold password setup until all user/access read-backs pass; do not retain passwords or session material. [Task 2]
- Symptom: Flow retrieval fails with `MissingPackageDirectoryError` or Tooling SOQL returns `INVALID_FIELD`. Fix: create declared `force-app` first, and use object describe/incremental field discovery before broad queries. [Task 3]
- Symptom: Production rollback scope expands beyond the named photo-import change. Fix: package only the three allowlisted Apex components; exclude Flows, pages, permissions, records, and unrelated classes. A successful check-only validation is not deployment; follow it with independent post-deploy retrieval/read-back. [Task 4]

# Task Group: Probo Medical Salesforce production access, MFA recovery, and user runbooks

scope: connect and verify the ProboMedical production org with scoped read-only checks, then translate MFA/passkey issues into per-user recovery steps without making account or credential changes implicitly
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical; reuse_rule=production-org- and checkout-specific; reuse the recovery pattern only after confirming current user state and obtaining explicit approval with the affected user present for any reset, session, password, or MFA change

## Task 1: Connect and reconnect the Probo Medical production org, success

### rollout_summary_files

- rollout_summaries/2026-08-20T13-33-59-khva-probo_medical_salesforce_mfa_access_and_permission_set_visua.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\20\rollout-2026-08-20T19-03-59-01a01f60-e5b4-7f30-8053-78eb63cfc140.jsonl, updated_at=2026-08-21T17:43:56+00:00, thread_id=01a01f60-e5b4-7f30-8053-78eb63cfc140, scoped connection and read-only Organization verification succeeded)

### keywords

- ProboMedical, Salesforce CLI, sf org login access-token, sfdx-project.json, API version 67.0, force-app, Organization, EPERM, sf org list --json, 00DU0000000LaKoMAK

## Task 2: Turn the MFA/passkey request into per-user operational steps, success

### rollout_summary_files

- rollout_summaries/2026-08-20T13-33-59-khva-probo_medical_salesforce_mfa_access_and_permission_set_visua.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\20\rollout-2026-08-20T19-03-59-01a01f60-e5b4-7f30-8053-78eb63cfc140.jsonl, updated_at=2026-08-21T17:43:56+00:00, thread_id=01a01f60-e5b4-7f30-8053-78eb63cfc140, four existing accounts assessed; no resets or user changes made)

### keywords

- MFA, passkey, temporary verification code, Manage Multi-Factor Authentication in User Interface, TwoFactorMethodsInfo, NOT_FOUND, LoginHistory, INVALID_FIELD, Multi-factor required, Super User, Dominick Vena, Karly Sheriff, Isael Sarmiento, Juan Torres

## User preferences

- when the user asks to connect an org -> keep authentication, metadata retrieval, deployment, and data changes separate; verify first and do not deploy implicitly [Task 1]
- when the user asks “what they want,” “how can we do it,” then “steps to do for each user” -> lead with a concrete per-user runbook and approval gates, rather than an abstract account-access explanation [Task 2]
- never echo or store supplied Salesforce frontdoor/session tokens; treat them as [REDACTED_SECRET] [Task 1]

## Reusable knowledge

- This workspace uses Salesforce DX API version `67.0`, package directory `force-app`, and production alias `ProboMedical`. A safe identity check is `SELECT Id, Name, OrganizationType, IsSandbox FROM Organization`; it verified Probo Medical, Unlimited Edition, `IsSandbox=false`, ID `00DU0000000LaKoMAK`. Use scoped `sf org login access-token` with the session entered at the masked prompt; avoid `sf org list --json` because it can expose locally stored access tokens. [Task 1]
- Dominick Vena, Karly Sheriff, Isael Sarmiento, and Juan Torres already have active individual accounts; do not create duplicates or consume licenses. Dominick/Karly/Juan have `Super User` access with Modify All Data/View All Data and therefore require phishing-resistant MFA. [Task 2]
- Supported recovery pattern: grant/use `Manage Multi-Factor Authentication in User Interface`; generate a temporary verification code; disconnect the broken built-in authenticator/passkey; have the user re-register on a supported device; expire the temporary code afterward. Recommended sequence: Dominick, validate; Karly, validate; then ensure Isael and Juan use their existing individual accounts. [Task 2]
- Temporary verification codes are for MFA recovery and do not necessarily solve an unrecognized-browser/app device-activation challenge. [Task 2]

## Failures and how to do differently

- Symptom: Salesforce CLI cannot perform an identity check and reports `EPERM` opening `C:\Users\LIKKI\.sf\sf-*.log`. Cause: local log-file permissions, not org rejection. Fix: retry the scoped auth/read-only query in the approved elevated context; do not replace it with broad org enumeration. [Task 1]
- Symptom: `TwoFactorMethodsInfo` returns `NOT_FOUND`, complex user SOQL is unusable, or `LoginHistory.User.Name` returns `INVALID_FIELD`. Fix: use Salesforce Setup and supported recovery procedures for MFA; simplify queries and verify fields incrementally; query `LoginHistory.UserId` then map IDs separately. [Task 2]
- Symptom: MFA troubleshooting turns into a production change. Fix: do not reset MFA/passwords, revoke sessions, or change users without explicit approval and the affected user present. [Task 2]

# Task Group: Probo Medical Salesforce permission-set governance visual deliverables

scope: turn permission-set review evidence into large, presentation-ready visual aids and downloadable artifacts; render and inspect before handoff
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical; reuse_rule=deliverable- and evidence-snapshot-specific; revalidate workbook metrics and output paths before presenting them as current

## Task 1: Create and validate the permission-set refactor map and presentation, success

### rollout_summary_files

- rollout_summaries/2026-08-20T13-33-59-khva-probo_medical_salesforce_mfa_access_and_permission_set_visua.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\20\rollout-2026-08-20T19-03-59-01a01f60-e5b4-7f30-8053-78eb63cfc140.jsonl, updated_at=2026-08-21T17:43:56+00:00, thread_id=01a01f60-e5b4-7f30-8053-78eb63cfc140, 12-slide PPTX and standalone HTML map rendered/validated)

### keywords

- permission-set-refactor-map.html, PowerPoint, Probo_Medical_Permission_Set_Refactor_Plan.pptx, Figma-style HTML, 7,221 direct assignments, 423 users, 306 Permission Sets, 46 high-risk users, render.py, Downloads

## User preferences

- when the user asks for “a big figma to understand them” and “downlode this file” -> provide a large visual, presentation-ready explanation and a normal downloadable copy, not only an in-chat description [Task 1]

## Reusable knowledge

- The visual map covers the Excel evidence chain, current risk metrics, high-risk permission sets, target access model, and refactor roadmap. It used 7,221 direct assignments, 423 users, 306 unique Permission Sets, and 46 high-risk users; these are snapshot metrics, not live-org claims. [Task 1]
- The source HTML is `C:\Users\LIKKI\.codex\visualizations\2026\08\20\01a01f60-e5b4-7f30-8053-78eb63cfc140\permission-set-refactor-map.html`; the downloadable copy is `C:\Users\LIKKI\Downloads\permission-set-refactor-map.html`; the presentation is `outputs\ps_refactor_presentation\Probo_Medical_Permission_Set_Refactor_Plan.pptx`. [Task 1]

## Failures and how to do differently

- Symptom: the standalone visual fails to render because `render.py` cannot be found. Cause: the first path was wrong. Fix: locate it under `...visualize\1.0.21\skills\visualize\scripts\render.py`. [Task 1]
- Symptom: a visual deliverable is handed off without usable proof or download. Fix: render and inspect the output first, then copy the standalone artifact to Downloads when requested. [Task 1]

# Task Group: Probo Medical Salesforce Tampa inventory load and stakeholder verification

scope: load a Tampa inventory workbook into ProboMedical `ProductItem__c`, prove the write with full read-back, and give a business user a concise verification handoff
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical; reuse_rule=checkout-, org-, and dataset-specific; inspect/dry-run first and obtain explicit approval immediately before any production write, then re-query current records rather than reusing these job or record results

## Task 1: Load Tampa inventory workbook and verify Salesforce results, success

### rollout_summary_files

- rollout_summaries/2026-08-19T18-34-42-wTZH-tampa_inventory_salesforce_load_verification.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\20\rollout-2026-08-20T00-04-43-01a01b4d-dd5d-7b51-a82a-d0ff8abe499d.jsonl, updated_at=2026-08-19T20:16:25+00:00, thread_id=01a01b4d-dd5d-7b51-a82a-d0ff8abe499d, 1,798 records fully read back with no mismatches)

### keywords

- ProboMedical, ProductItem__c, Tampa, Bulk API, dry run, 750jR000000CD9eQAG, 750jR000000C2vjQAC, Inventory_Count_Date__c, Stock_Checked__c, Sub_Location__c, 03_load_receipt.json

## Task 2: Give David concise Salesforce UI verification and reply wording, success

### rollout_summary_files

- rollout_summaries/2026-08-19T18-34-42-wTZH-tampa_inventory_salesforce_load_verification.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\20\rollout-2026-08-20T00-04-43-01a01b4d-dd5d-7b51-a82a-d0ff8abe499d.jsonl, updated_at=2026-08-19T20:16:25+00:00, thread_id=01a01b4d-dd5d-7b51-a82a-d0ff8abe499d, direct record checks and copy-paste message supplied)

### keywords

- Asset 151913, ProductItem__c/list?filterName=Recent, a065b00000cnEknAAE, Tampa, FL, TPA | FG | 110 | J4, Show more, copy-paste, David

## User preferences

- when the user said “do dry dun then i will say what to do” -> inspect and validate first, then wait for explicit approval immediately before a production Salesforce write; do not infer authorization from exploratory context [Task 1]
- when the user asked for a reply and verification -> provide a short, copy-pasteable message plus the exact direct link, fields, and expected values rather than a broad explanation [Task 2]

## Reusable knowledge

- For this load, `ProductItem__c` received 1,798 Tampa records from `C:\Users\LIKKI\Downloads\Copy of TampaInventory_Dataloader_08172026_BN.xlsx`: pilot `750jR000000CD9eQAG` was 10/10 successful and main job `750jR000000C2vjQAC` was 1,788/1,788 successful. The full read-back reported `expectedRecords:1798`, `actualRecords:1798`, empty missing/unexpected/mismatches arrays, and `passed:true`. Receipt: `outputs/tampa_inventory_2026-08-17_load/03_load_receipt.json`. [Task 1]
- A useful business-user sample is Asset `151913`: Location `Tampa, FL`; blank Sub Location; Current Location `TPA | FG | 110 | J4`; Inventory Count Date and Stock Checked `8/17/2026`. Use the supplied ProductItem record URL; if fields are absent on Details, tell the user to click “Show more.” [Task 2]

## Failures and how to do differently

- Symptom: a dry-run request is followed by a production load in context. Cause: exploratory discussion was treated as write authorization. Fix: repeat the intended production action and obtain explicit confirmation immediately before it; preserve the pilot/read-back/receipt trail. [Task 1]
- Symptom: stakeholder verification requires back-and-forth. Cause: reply omitted the exact record, fields, expected values, or link. Fix: hand off all four in a short copy-paste message. [Task 2]

# Task Group: Probo Medical Salesforce user-permission mapping workbook

scope: create a focused, read-only three-tab Excel mapping of ProboMedical users, permission-set assignments, and permission details from local exports; use the streaming XLSX path for large mapping sheets
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical; reuse_rule=checkout- and export-snapshot-specific; preserve the three-tab/read-only boundary unless the user requests a different deliverable or Salesforce change, and revalidate counts against current source exports

## Task 1: Build and validate the user-permission mapping workbook, success

### rollout_summary_files

- rollout_summaries/2026-08-17T18-58-15-yrEt-probo_medical_user_permission_mapping_workbook.md (cwd=\\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\18\rollout-2026-08-18T00-28-15-01a01116-b26e-7800-a5b6-e0f13fe708a9.jsonl, updated_at=2026-08-19T19:45:49+00:00, thread_id=01a01116-b26e-7800-a5b6-e0f13fe708a9, XML and visual-preview validation passed)

### keywords

- ProboMedical, Salesforce, permission sets, XLSX, @oai/artifact-tool, PowerShell, streamed XML, memory ceiling, formula validation, stream_all_user_permission_tabs.ps1, build_user_permission_mapping_workbook.mjs

## User preferences

- when producing the report, the requested “exactly three tabs” had no raw or audit tabs -> keep similar workbook deliverables tightly scoped and do not add worksheets unless requested [Task 1]
- when creating Salesforce reporting, preserve the stated boundary “No Salesforce records or permissions were changed” -> treat reporting/export work as read-only unless org changes are separately authorized [Task 1]

## Reusable knowledge

- The final workbook is `outputs/user_permission_set_mapping_2026-08-20/Pro_Biomedical_User_Permission_Set_Mapping_2026-08-20.xlsx`, with exactly `Users`, `User Permission Sets`, and `Permission Set Details`; its source snapshot had 983 users, 12,372 assignments, and 574 permission sets. [Task 1]
- `@oai/artifact-tool` exhausted 4–8 GB on the 12,372-row mapping sheet because it retained large row arrays, body-wide formatting, table wrappers, and rendering. The successful path builds a lightweight shell with `scratch/build_user_permission_mapping_workbook.mjs`, then streams rows into the XLSX ZIP worksheet XML with `scratch/stream_all_user_permission_tabs.ps1`. [Task 1]
- Validate the injected workbook, not merely the shell build: XML rows including headers were 984/12,373/575, autofilters were `A1:AE984`, `A1:O12373`, `A1:AF575`, formula errors were zero, and all three tab previews were inspected. [Task 1]

## Failures and how to do differently

- Symptom: direct artifact-tool export/rendering of a 12k+ row sheet consumes memory or fails. Cause: full in-memory rows plus body styling, formal tables, and preview rendering. Fix: remove that overhead and stream rows directly into `xl/worksheets/sheet1.xml`–`sheet3.xml` within the XLSX ZIP package. [Task 1]
- Symptom: a shell build is described as a completed workbook. Cause: no post-injection worksheet checks. Fix: inspect XML row counts, dimensions, filters, formulas, formula-error patterns, and visual previews before handoff. [Task 1]

# Task Group: FlywirePartial future-state architecture and CPQ RFP assessment

scope: read-only Salesforce CPQ future-state assessment and RFP comparison; use to frame modernization, vendor evaluation, and team-review materials
applies_to: cwd=C:\Users\LIKKI\Documents\ChatGPT\david; reuse_rule=snapshot-specific for org counts and workbook/PDF findings; revalidate current org state and keep proposals distinct from approved production design

## Task 1: Assess future-state PPT and CPQ RFP against FlywirePartial, success

### rollout_summary_files

- rollout_summaries/2026-08-12T17-50-31-XsTu-flywire_future_state_cpq_rfp_ppt_team_guidance.md (cwd=C:\Users\LIKKI\Documents\ChatGPT\david, rollout_path=\\?\C:\Users\LIKKI\.codex\sessions\2026\08\12\rollout-2026-08-12T23-20-31-019ff718-e4ef-7782-ad11-860171944908.jsonl, updated_at=2026-08-24T18:18:52+00:00, thread_id=019ff718-e4ef-7782-ad11-860171944908, team-PPT framing, RFP comparison, and read-only org assessment)

### keywords

- FlywirePartial, Salesforce DX, CPQ, Revenue Cloud, Conga, DealHub, Future State Vision, CPQ RFP, ARR, CLM, Experience Cloud, Workday, NetSuite, Apex coverage, pilot rollout

## User preferences

- when the user asked “what shouild say to david about the pppt” -> provide concise, copy-paste stakeholder wording and frame the deck as a proposed implementation/go-live design, not approved production architecture [Task 1]
- when the user said “scan this also” after the PPT assessment -> compare new requirements with prior architecture and identify what the existing deck omits, not just summarize the new workbook in isolation [Task 1]

## Reusable knowledge

- This is a live, complex base, not a blank target: at assessment time it had 954 quotes, 7,653 quote lines, 438 products, 4,111 contracts, 3,011 orders, 1,990 subscriptions, 85 active price rules, 17 active approval rules, 116 active flows, 101 unmanaged Apex classes, six unmanaged triggers, and 22% Apex coverage. Use controlled modernization and a pilot, not a clean rebuild or big-bang go-live. [Task 1]
- Reuse existing CPQ, Advanced Approvals, quote/order/contract/subscription data, proposal generation, migration IDs, and renewal/amendment automation, but consolidate fragmented ARR logic behind one governed, versioned calculation contract. Pricing needs an explicit physical design: 85 active price rules but zero discount schedules and zero block prices. [Task 1]
- Existing contract automation is not full CLM; clause libraries, redlining, obligations, repository governance, signature tracking, and retention controls remain gaps. Integration needs canonical payloads, correlation/idempotency, retries, dead-letter/replay, monitoring, acknowledgements, and reconciliation; 22% Apex coverage is a go-live blocker. [Task 1]
- The RFP requires bidirectional Salesforce sync, localization, security/audit, ERP/billing/tax integration, guided selling/nested bundles, stepped pricing, partner Experience Cloud quoting, deal registration, and channel-conflict controls. Reconcile its ~3,000-product scope with the 438-product sandbox and scale-test. Keep the permanent ERP contract neutral while NetSuite is current and Workday planned; vendor selection is still open. [Task 1]
- The workbook was draft/incomplete: blank Presentation Criteria, unresolved OKRs/budget, pending requirements document, incomplete questions, no weighted scoring, and unverified vendor research. [Task 1]
- Suitable team wording: “This is our proposed implementation architecture. The CPQ RFP introduces additional vendor, partner-channel, global localization, tax, SLA, security, support and platform-selection requirements that must be incorporated before final solution approval.” [Task 1]

## Failures and how to do differently

- Symptom: expected Poppler binaries are unavailable. Fix: use bundled `pdfplumber` for full extraction and rendering, then inspect representative PNG pages before claiming visual inspection. [Task 1]
- Symptom: inline PowerShell/Python workbook inspection fails from quoting or cp1252 output. Fix: use a saved Python scanner and set `$env:PYTHONIOENCODING='utf-8'`. [Task 1]
- Do not treat the architecture as final before CPQ vendor/platform selection, RFP traceability, physical pricing/CLM design, and automation governance are resolved; do not make NetSuite the permanent integration contract while Workday is planned. [Task 1]

