thread_id: 01a06932-d216-71e0-826e-6a1f4e17372c
updated_at: 2026-09-03T22:00:01+00:00
rollout_path: \\?\C:\Users\LIKKI\.codex\sessions\2026\09\04\rollout-2026-09-04T03-05-33-01a06932-d216-71e0-826e-6a1f4e17372c.jsonl
cwd: \\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical
git_branch: master

# Probo Medical UAT photo-import guide created and Production/UAT state clarified

Rollout context: Work was performed in `C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical` for Case 00010716. The user wanted a clean Word document for the team explaining how to reproduce the Google Drive photo-import regression and what changed, with text and tables only, excluding deployment IDs and sensitive session data.

## Task 1: Create the UAT reproduction and change guide

Outcome: partial

Preference signals:
- The user corrected the initial strategy-memo direction: “NO NORMAL AUTPFAT LIKE DOC I WNAT” -> future documents for this workflow should use the familiar normal AutoFast case-document style rather than a generic polished memo or cover design.
- The user explicitly required “NO DEPLOYMET ID AND ALL CLEAN WORD DOC NO IMAGES ONLY TABLES AND TEXT” -> similar team documents should proactively omit deployment/validation/test-run IDs, credentials/session tokens, and images while retaining actionable text, tables, links, and test records.

Key steps:
- Selected a template initially, then switched to the existing AutoFast reference document after the user correction.
- Created `outputs\case-00010716\Case_00010716_UAT_Photo_Import_Reproduction_and_Change_Guide_AutoFast.docx`.
- The guide covers environment boundary, original defect, technical changes, dedicated UAT records, manual UAT prerequisites/procedure, acceptance criteria, troubleshooting, and a tester execution record.
- It documents changes to `cAuthURIForEval`, `cGoogleAppAuthenticationWithSalesforce`, and `GoogleAuthTestClass`.
- Structural QA passed: accessibility audit reported high=0, medium=0, low=0; image audit found no drawings; all tables passed exact geometry checks; section audit confirmed US Letter portrait with 1-inch margins.

Failures and how to do differently:
- LibreOffice/`soffice` was unavailable, so render-to-PNG visual QA could not be completed. Future document runs should verify `soffice` availability early and disclose skipped visual QA rather than implying a visually verified result.
- The first template choice was misaligned with the user’s expected AutoFast format; inspect existing case documents before selecting a generic template when the user references a familiar prior format.

Reusable knowledge:
- Existing AutoFast style tokens: Calibri body, navy title, blue headings, restrained callouts, exact DXA tables, US Letter portrait, 1-inch margins.
- UAT test records: Product Item 552082, RMA A-218876, primary Evaluation E-2026-036025, control Evaluation E-2026-036026. Manual test requires a dedicated Google Drive folder containing recognizable files such as `C-Lens.jpg`, `C-Cap.jpg`, `C-Whole.jpg`, and `C-SN.jpg`.
- The test must verify the primary Evaluation receives image references and the control Evaluation remains unchanged.

## Task 2: Clarify Production versus UAT record and code state

Outcome: success

Key steps:
- Verified live org identities: `ProboMedical` is Production (`IsSandbox=false`, instance `USA1330`); `ProboUAT` is the UAT sandbox (`IsSandbox=true`, instance `USA1310S`).
- Production contains Product Item 554470, serial `F0KJ59`, linked to Evaluation E-2026-036262 and RMA A-219744; UAT does not contain those Production records.
- Tooling API marker checks showed UAT has Evaluation-state handling and folder normalization, while Production still has the older latest-modified-Evaluation fallback at the time of inspection.
- The investigation concluded the corrected code was in UAT and the email’s issue referred to Production; no records or metadata were changed during the investigation.

Failures and how to do differently:
- Salesforce CLI initially failed because it could not write `C:\Users\LIKKI\.sf\sf-2026-09-03.log`; use `SF_DISABLE_LOG_FILE=true` and elevated/read-only execution when necessary.

References:
- [1] Final document: `outputs\case-00010716\Case_00010716_UAT_Photo_Import_Reproduction_and_Change_Guide_AutoFast.docx`
- [2] Source code diffs: `outputs\case-00010716\01_cAuthURIForEval_old_vs_new.patch`, `02_cGoogleAppAuthenticationWithSalesforce_old_vs_new.patch`, `03_GoogleAuthTestClass_old_vs_new.patch`
- [3] QA commands: `a11y_audit.py`, `table_geometry.py`, `images_audit.py`, `section_audit.py`, `heading_audit.py`
- [4] CLI workaround: `$env:SF_DISABLE_LOG_FILE='true'; sf data query ...`
