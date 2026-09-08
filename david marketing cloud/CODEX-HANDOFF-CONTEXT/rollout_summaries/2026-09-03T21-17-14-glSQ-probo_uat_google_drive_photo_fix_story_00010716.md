thread_id: 01a06922-0f56-70e3-a5d3-bc614dbcbd9c
updated_at: 2026-09-03T22:01:05+00:00
rollout_path: C:\Users\LIKKI\.codex\sessions\2026\09\04\rollout-2026-09-04T02-47-15-01a06922-0f56-70e3-a5d3-bc614dbcbd9c.jsonl
cwd: \\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical
git_branch: master

# Probo Medical story 00010716 UAT deployment, test setup, and documentation

Rollout context: Salesforce project at `C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical`. The user clarified that testing must use the real `ProboUAT` sandbox, not supplied DevDO links. Production rollback was also requested, but Production authentication expired.

## Task 1: Identify and deploy the Google Drive photo-import fix to ProboUAT

Outcome: success

Preference signals:
- The user explicitly said: "I WANT THE SAME IN UAT FOR THE TEST NOT FORM DEVDO" -> future work must verify the target alias and URL before making changes, and must keep UAT, DevDO, and Production strictly separate.

Key steps:
- `sf org list --json` identified `ProboUAT` as the connected Probo Medical UAT sandbox at `probomedical--uat.sandbox`; `ProboDevDO` is a separate sandbox.
- Read-only UAT checks confirmed the org is a sandbox and contained older versions of `cAuthURIForEval`, `cGoogleAppAuthenticationWithSalesforce`, and `GoogleAuthTestClass`.
- Retrieved the UAT metadata, compared it with the prepared fix, and ran a check-only deployment scoped to exactly three Apex classes.
- Check-only validation succeeded: 3/3 components, 4/4 tests, 0 component errors, and 0 test failures.
- Deployed the same three classes to `ProboUAT` only. Deployment `0AfjH0000000T6rSAE` succeeded with 3/3 components and 4/4 tests passed.

Reusable knowledge:
- The fix carries the exact Evaluation ID through OAuth state instead of selecting the latest Evaluation modified by the user; it validates missing/invalid state, normalizes Drive folder URLs, handles missing folders/files safely, and improves test seams.
- `GoogleAuthTestClass` includes regression coverage for competing Evaluations, folder-ID normalization, missing callback state, missing Drive folder, and file mapping.
- The correct deployment pattern is `sf project deploy start --metadata "ApexClass:cAuthURIForEval" --metadata "ApexClass:cGoogleAppAuthenticationWithSalesforce" --metadata "ApexClass:GoogleAuthTestClass" --test-level RunSpecifiedTests --tests GoogleAuthTestClass --target-org ProboUAT --wait 60 --json`.

Failures and how to do differently:
- An initial retrieve failed because the isolated `sfdx-project.json` referenced a nonexistent `force-app`; creating the directory fixed it.
- A SOQL query initially used nonexistent fields such as `Cap_ID__c`; query the actual schema before reading Evaluation fields.

References:
- UAT alias: `ProboUAT`; DevDO alias: `ProboDevDO`; Production alias: `ProboMedical`.
- UAT deployment ID: `0AfjH0000000T6rSAE`.
- Changed classes: `cAuthURIForEval`, `cGoogleAppAuthenticationWithSalesforce`, `GoogleAuthTestClass`.

## Task 2: Create dedicated UAT test records

Outcome: partial

Key steps:
- Created a tagged UAT Product Item, RMA, Opportunity, and two Evaluations using `sf apex run` against `ProboUAT`.
- Verified Product Item `a06jH0000004E2rQAE`, RMA `a0mjH0000000BWXQA2`, Evaluations `a1tjH0000003n98QAA` (`E-2026-036025`) and `a1tjH0000003n99QAA` (`E-2026-036026`).
- Baseline image fields were blank, and the Product Item had no Drive folder URL.

Failures and how to do differently:
- The manual end-to-end Google Drive test was not completed because a dedicated UAT Drive folder/link was still required. Do not claim the real photo import was verified until the folder is populated and the browser flow is executed.

## Task 3: Production rollback

Outcome: partial

Key steps:
- Built a rollback package from verified pre-deployment Production versions of the same three classes and confirmed file hashes matched.
- Production check-only validation could not start because the saved `ProboMedical` session returned `INVALID_SESSION_ID`.
- Browser login/MFA was opened, but the rollout ended without evidence that Production reauthentication or rollback completed.

Failures and how to do differently:
- Never report the Production rollback as complete without a successful login, deployment result, and post-deployment metadata/test verification.

## Task 4: Produce the old-vs-new Apex code document

Outcome: success

Key steps:
- Created `outputs\case-00010716\Case_00010716_Apex_Code_Changes_Old_vs_New.docx` with side-by-side old/new UAT code, red removals, green additions, all three classes, plain-English explanation, and no folder setup or unrelated metadata.
- Final verification passed: `cAuthURIForEval +11/-1`, `cGoogleAppAuthenticationWithSalesforce +153/-134`, `GoogleAuthTestClass +92/-7`; metadata XML unchanged; no comments or tracked revisions; accessibility audit high=0, medium=0, low=0; table geometry passed.
