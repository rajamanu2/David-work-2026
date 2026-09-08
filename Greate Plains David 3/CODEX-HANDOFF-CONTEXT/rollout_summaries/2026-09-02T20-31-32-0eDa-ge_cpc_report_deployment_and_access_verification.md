thread_id: 01a063d1-dc0e-7b11-8464-9e178a477d84
updated_at: 2026-09-03T21:08:32+00:00
rollout_path: \\?\C:\Users\LIKKI\.codex\sessions\2026\09\03\rollout-2026-09-03T02-01-33-01a063d1-dc0e-7b11-8464-9e178a477d84.jsonl
cwd: \\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical
git_branch: master

# Salesforce connection, GE CPC report deployment, handoff, and access follow-up

Rollout context: Work occurred in `C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical`. The user provided a Salesforce frontdoor/session URL, GE CPC workbook and contract files, and wanted a dry-run assessment, DevDO/UAT/Production guidance, a handoff document, an email/ticket message, and confirmation that Adam and Mindy could see the report.

## Task 1: Connect and verify ProboMedical Production

Outcome: success

Preference signals:
- When connecting Salesforce, the user expected the supplied link to be used to connect the org and verify it before further work -> keep authentication separate from retrieval or writes, and verify Production explicitly.
- Session/frontdoor material must not be repeated or stored; treat it as `[REDACTED_SECRET]` and recommend expiry/revocation after use.

Key steps:
- Reused alias `ProboMedical` and masked `sf org login access-token` flow.
- Read-only query verified `Probo Medical`, Unlimited Edition, org ID `00DU0000000LaKoMAK`, `IsSandbox=false`.
- No data, metadata, or configuration changes were made during connection verification.

Failures and how to do differently:
- Existing session expired with `INVALID_SESSION_ID`; browser OAuth can time out with `AuthTimeoutError`.
- Salesforce CLI can fail locally on `.sf` log writes with `EPERM`; use `SF_DISABLE_LOG_FILE=true` for read-only checks when appropriate.

Reusable knowledge:
- Safe identity query: `SELECT Id, Name, OrganizationType, IsSandbox FROM Organization`.
- Avoid `sf org list --json` when it may expose locally stored tokens.

References:
- Alias: `ProboMedical`
- Production org ID: `00DU0000000LaKoMAK`

## Task 2: Assess GE CPC attachments and deployment path

Outcome: partial

Preference signals:
- The user asked for a “dry run” and specifically wanted to know whether the story belonged in DevDO, Production, or both -> provide an environment-by-environment recommendation before writes.
- Attached documents were to be treated as evidence, not authorization.

Key steps:
- Reviewed workbook `C:\Users\LIKKI\Downloads\9-2 Copy of Copy of EPIQ-CPC-Probo System List.xlsx` and contract `C:\Users\LIKKI\Downloads\9-2 GE CPC contract.odt` read-only.
- Workbook contained six tabs, including `MainList` with 1,192 rows including header and model-specific subsets (`CHS-LI`, `Epiq Elite`, `Epiq CVx`, `Epiq 7`, `Epiq 5`).
- Existing report design used Work Orders with Work Order Line Items, GE account/opportunity/PO filters, current fiscal year ship-date filtering, and cost/quantity/asset/part columns.
- The final documented path was DevDO build -> UAT dry-run/deployment -> Production check-only validation -> Production deployment.

Reusable knowledge:
- The GE CPC work was a Salesforce Report metadata change, not an Apex, Flow, object, field, permission, or data-load change.
- The six `302808xxx` values are PO/opportunity references, not an official story number; no official story number was found in supplied/local artifacts.
- Production report: `GE CPC Parts Shipped`, report ID `00OjR0000002cHJUAY`, folder `Service Operations Reports`.

Failures and how to do differently:
- Artifact-tool auto-render failed on large workbook ranges with `Auto render too large`; render bounded ranges instead.
- Do not infer an official ticket/story number from PO numbers or report metadata.

References:
- Workbook tabs and ranges were summarized in `tmp_contract_review\workbook_summary.json`.
- Report metadata source: `force-app\main\default\reports\Service_Operations_Reports\GE_CPC_Parts_Shipped.report-meta.xml`.

## Task 3: Create text-only AutoFast handoff document

Outcome: success with visual-QA limitation

Key steps:
- Created `outputs\ge_cpc_parts_shipped_prod_handoff\GE_CPC_Parts_Shipped_Production_AutoFast_Handoff.docx`.
- Included DevDO/UAT/Production evidence, report configuration, direct links, production non-impact statement, remaining checks, and a ready-to-send note for David.
- Structural checks passed: zero embedded images, zero Figma mentions, no raw frontdoor/session URL, Production report ID present, and accessibility audit reported 0 high/medium/low findings.

Failures and how to do differently:
- DOCX visual rendering could not be completed because LibreOffice/`soffice` was unavailable and the renderer hit Windows `WinError 5` temp-directory permission failures. Do not claim visual QA passed.

References:
- Builder: `scratch\ge_cpc_prod_autofast_doc\build_ge_cpc_prod_autofast_doc.py`
- Deployment evidence in the document includes Production deployment job `0AfjR0000000w0nSAA` and report ID `00OjR0000002cHJUAY`.

## Task 4: Draft ticket/email routing and confirm report visibility

Outcome: partial / uncertain

Preference signals:
- When the user said “MAKE SURE THESE PEOPLE SEE THIS REPORT” and identified Adam and Mindy, the expected default is to address them directly and keep the update in the same ticket thread.
- The user prefers confirmation of actual access rather than assumptions; the final answer should distinguish intended recipients from verified Salesforce access.

Key steps:
- Drafted a ticket/email addressed to Adam and Mindy, with David and existing ticket stakeholders copied, linking the Production report.
- Recommended posting in the original ticket thread so requester/watchers are notified and the record remains centralized.
- Recommended confirming Adam and Mindy can open the report before closing the ticket.

Failures and how to do differently:
- Initial access queries failed on CLI log permissions; after disabling log files, calls hung and then failed with `ECONNREFUSED 127.0.0.1:9` in the sandbox.
- Escalated read-only queries reached Salesforce but returned `INVALID_SESSION_ID`; Adam/Mindy access and folder sharing were not verified.
- Do not state that Adam or Mindy can see the report until their active users and `Service Operations Reports` folder/report access are successfully checked.

Reusable knowledge:
- The report is stored in `Service Operations Reports`; users may need Viewer access to that folder.
- Safe follow-up checks should query active users, the report record, and folder access only after reconnecting `ProboMedical`.

References:
- Production report link: `https://probomedical.my.salesforce.com/lightning/r/Report/00OjR0000002cHJUAY/view`
- Relevant failure: `INVALID_SESSION_ID: Session expired or invalid`
- Local network failure: `connect ECONNREFUSED 127.0.0.1:9`
