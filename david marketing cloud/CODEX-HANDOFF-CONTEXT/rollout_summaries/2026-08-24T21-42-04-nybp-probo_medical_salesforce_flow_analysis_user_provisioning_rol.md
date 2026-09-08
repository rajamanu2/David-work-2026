thread_id: 01a035b9-321d-7ec1-83ac-ef200a05ce43
updated_at: 2026-09-03T21:30:30+00:00
rollout_path: \\?\C:\Users\LIKKI\.codex\sessions\2026\08\25\rollout-2026-08-25T03-12-04-01a035b9-321d-7ec1-83ac-ef200a05ce43.jsonl
cwd: \\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical
git_branch: master

# Probo Medical Salesforce administration, flow analysis, user provisioning, and scoped rollback

Rollout context: Work occurred in `C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical` against Probo Medical production (`ProboMedical`, org ID `00DU0000000LaKoMAK`) and the DevDO sandbox. Sensitive Salesforce session tokens were supplied and used, but should not be retained.

## Task 1: Connect and verify ProboMedical production

Outcome: success

Preference signals:
- The user asked to connect using supplied frontdoor links and expected direct connection, not unrelated retrieval or deployment.
- The assistant kept authentication and read-only identity verification separate from metadata and data changes.

Key steps:
- Used scoped `sf org login access-token` and verified with an Organization query.
- Confirmed Probo Medical, Unlimited Edition, production (`IsSandbox=false`), org ID `00DU0000000LaKoMAK`.
- A stale session caused `INVALID_SESSION_ID`; refreshed authentication through the user-supplied Production frontdoor session.

Failures and how to do differently:
- Avoid `sf org list --json`, which may expose stored tokens.
- Salesforce CLI can fail with `EPERM` writing `C:\Users\LIKKI\.sf\sf-*.log`; use approved elevated execution.
- Browser OAuth can time out; use the masked access-token flow when available.

Reusable knowledge:
- Workspace uses Salesforce DX API `67.0`, alias `ProboMedical`, and package directory `force-app`.
- Safe identity query: `SELECT Id, Name, OrganizationType, IsSandbox FROM Organization`.

## Task 2: Create Stanley Saint Louis’s Salesforce account

Outcome: success

Preference signals:
- Before production writes, the user accepted an explicit approval gate: `APPROVE CREATE STANLEY`.
- The workflow inspected the similar user and license capacity first, then created and independently verified the account.

Key steps:
- Resolved three Shawn Zelesnick records and selected the active internal `FSL US` user, not portal or inactive records.
- Confirmed no duplicate Stanley account and available licenses.
- Created active user `ssaintlouis@probomedical.com`, alias `ssaintl`, title `Junior Territory Manager`, manager Brad Lawson.
- Applied two Field Service licenses, eight permission sets, `All Internal Users` membership, and an active Service Resource.
- Independently verified all assignments and triggered the password-setup email via `System.resetPassword(..., true)`.

Reusable knowledge:
- Shawn’s relevant configuration was Field Service-oriented: profile `FSL US`, Department `Field Service`, manager Brad Lawson, two Field Service PSLs, eight direct permission sets, public group membership, and active Service Resource.
- Do not copy territories or skills when the source user has none.

References:
- Stanley User ID: `005jR000000BpNOQA0`
- Password reset execution succeeded; final status showed active user and updated `LastPasswordChangeDate`.

## Task 3: Inventory and analyze Flows for consolidation

Outcome: partial

Preference signals:
- The user clarified that the goal is to combine object-level automation, identify overlapping Flow/Apex/LWC logic, and produce an Excel workbook.
- The assistant correctly kept this phase read-only and proposed grouping by object, identifying Subflows, Apex actions, LWC/screen components, and Orchestrator candidates.

Key steps:
- Queried `716` Flow definitions and `3,645` historical Flow versions through the Tooling API.
- Exported source data to `outputs\flow_inventory_2026-08-25\source-data\flow_definitions.json` and `flow_versions.json`.
- Retrieved Flow, ApexClass, ApexTrigger, LWC, and Aura metadata into `outputs\flow_inventory_2026-08-25\retrieved-source`.
- Located reusable analysis artifacts such as `automation_analysis.json`.

Failures and how to do differently:
- Initial retrieval failed because the configured `force-app` directory was missing; creating the directory allowed retrieval to proceed.
- Tooling API fields are object/version-specific: `TriggerType`, `NamespacePrefix`, and some relationship fields produced `INVALID_FIELD`; use `sf sobject describe --use-tooling-api` before constructing broad queries.
- The requested Excel workbook and full consolidation recommendations were not completed in this rollout.

Reusable knowledge:
- Authoritative activation is `FlowDefinition.ActiveVersionId`, not merely Flow metadata status. A Draft version can coexist with an older active version.
- Large metadata retrievals may run silently for several minutes; continue polling the same job rather than starting duplicates.

References:
- `sf data query --use-tooling-api --target-org ProboMedical --query "SELECT Id, DeveloperName, ActiveVersionId, LatestVersionId FROM FlowDefinition ORDER BY DeveloperName"`
- `sf data query --use-tooling-api --target-org ProboMedical --query "SELECT Id, DefinitionId, MasterLabel, VersionNumber, Status, ProcessType, ApiVersion, Description, CreatedDate, LastModifiedDate FROM Flow ORDER BY DefinitionId, VersionNumber"`

## Task 4: Roll back the photo-import Production changes

Outcome: success

Preference signals:
- The user explicitly required: `IT SHOLDNOT EFFECT THE OTHER THINGS IN THE PROD STICK TO OUR CHNAGES ONLY`.
- Future rollback work should scope the package narrowly, validate first, and prove unrelated metadata was untouched.

Key steps:
- Identified exactly three deployed Apex classes: `cAuthURIForEval`, `cGoogleAppAuthenticationWithSalesforce`, and `GoogleAuthTestClass`.
- Built a rollback package from verified pre-deployment files and matched SHA-256 hashes.
- Check-only validation passed 3/3 components and 3/3 tests (`0AfjR0000000wnBSAQ`).
- Quick-deployed the rollback successfully (`0AfjR0000000wqPSAQ`).
- Retrieved Production classes afterward; all six class/metadata files matched the rollback package exactly.
- Post-rollback `GoogleAuthTestClass` passed 3/3 (`707jR000001S2Qc`).
- No Flows, records, permissions, objects, fields, pages, DevDO, UAT, or unrelated Production components were changed.

Failures and how to do differently:
- Initial validation failed because the saved Production session expired (`INVALID_SESSION_ID`); refresh authentication before retrying.
- Read-back retrieval initially failed because the scratch project’s `force-app` directory was absent; create the required directory before retrieve.
- A broad final User query used unsupported fields and failed; simplify queries incrementally.

References:
- Validation job: `0AfjR0000000wnBSAQ`
- Deployment job: `0AfjR0000000wqPSAQ`
- Focused test run: `707jR000001S2Qc`
- Affected classes: `cAuthURIForEval`, `cGoogleAppAuthenticationWithSalesforce`, `GoogleAuthTestClass`

## Task 5: Smoke-test restored Production photo page

Outcome: success

Key steps:
- Selected recent Evaluation `E-2026-036181` with existing RMA and Drive folder.
- Opened `AuthenticationGoogleDrive`; both `Authenticate` and `Save` controls loaded without errors.
- Confirmed the Evaluation `LastModifiedDate` did not change.
- Did not perform the full Google authentication/photo import because it would update a real Production record and required separate approval.

Failures and how to do differently:
- A full photo-import test remains unexecuted; it requires explicit approval and user-completed Google authentication.

References:
- Evaluation ID: `a1tjR0000004CqbQAE`
- Evaluation page: `https://probomedical.my.salesforce.com/apex/AuthenticationGoogleDrive?id=a1tjR0000004CqbQAE`
