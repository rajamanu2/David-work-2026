thread_id: 01a0488a-dfbb-71d0-a9f0-6ee9a882bbab
updated_at: 2026-08-28T16:27:33+00:00
rollout_path: \\?\C:\Users\LIKKI\.codex\sessions\2026\08\28\rollout-2026-08-28T18-54-16-01a0488a-dfbb-71d0-a9f0-6ee9a882bbab.jsonl
cwd: \\?\C:\Users\LIKKI\Documents\ChatGPT\Greate Plains David 3
git_branch: master

# SCC-4487 Salesforce review and PR-review artifact

Rollout context: The user provided SCC-4487, “Add Segment to Inside Sales Order,” in the Great Plains Salesforce DX workspace and initially requested a dry run. The work later shifted to a PR Review only, explicitly excluding IT/UAT test execution and deployment.

## Task 1: Read-only metadata dry run

Outcome: partial

Preference signals:
- The user later clarified: “don't just put IT test… Only PR review.” Similar future reviews should focus on implementation/code and metadata quality, not append operational test execution unless requested.

Key steps:
- Confirmed `GreatPlainsMerge` as a Great Plains Communications sandbox (`00DEa00000GkAsHMAV`) using a read-only Organization query.
- `GreatPlainsUAT` authentication was expired; the attempted check-only deployment failed before creating a job with `INVALID_SESSION_ID`.
- Retrieved a narrow SCC-4487 package from Merge into `scc-4487-retrieval`; five components retrieved successfully.
- Source-side evidence initially showed `Account.Segment__c` existed as an editable picklist with `Residential` and `MDU Tenant`, but `Order.Segment__c` was absent. The layout and FlexiPage also lacked Segment placement and the profiles lacked Order field permissions.
- Validated the retrieved XML and wrote `dry-run/SCC-4487-dry-run-summary.md` documenting a blocked/no-go result, no deployment, no org writes, and the UAT authentication blocker.

Failures and how to do differently:
- `sf org list --json` first failed because Salesforce CLI could not open `.sf\\sf-2026-08-28.log` (`EPERM`); rerunning in an approved elevated read-only context worked.
- A FieldDefinition query used unsupported `CalculatedFormula`, producing `INVALID_FIELD`; use `sf sobject describe` to inspect field calculation/formula properties.
- The initial source retrieval required an isolated project with `force-app/.gitkeep`; the narrow retrieve then succeeded, with the missing field explicitly reported rather than inferred.
- Do not treat a failed UAT dry run as evidence of metadata validity; distinguish authentication failure from package readiness.

Reusable knowledge:
- In this checkout, `GreatPlainsMerge` is the source sandbox and `GreatPlainsUAT` is the intended target, but aliases and sessions must be revalidated each run.
- Use a narrow manifest containing `Order.Segment__c`, `Order-Inside Sales`, `OSE_CPQOrderRecordPage`, and the named profiles; retrieve read-only with `--ignore-conflicts` after creating the package directory.
- Story labels are not sufficient API identifiers; discover actual metadata and schema names before queries or validation.

References:
- `scc-4487-retrieval/manifest/package.xml`
- `dry-run/SCC-4487-dry-run-summary.md`
- Exact UAT validation command: `sf project deploy start --dry-run --manifest manifest/package.xml --target-org GreatPlainsUAT --test-level NoTestRun --wait 30 --json`
- Key errors: `Entity of type 'CustomField' named 'Order.Segment__c' cannot be found`; `INVALID_SESSION_ID`.

## Task 2: SCC-4487 PR Review document

Outcome: success, with final repository/PR approval still conditional

Preference signals:
- The user asked to assess “any code issues” and “everything… related to this story,” while matching the previous document, then explicitly narrowed the deliverable to “Only PR review.” Future work should proactively cover all story-related metadata/code concerns while omitting IT/UAT test sections.
- The user wanted the prior Great Plains review treatment reused. The review used `SCC-4179-architect-review.docx` as the visual reference and created a separate `SCC-4487-PR-Review.docx`.

Key steps:
- Reworked the review around the later DevA/current-org findings rather than the earlier stale Merge state.
- The final assistant report stated that `Order.Segment__c` uses `TEXT(Account.Segment__c)`, is calculated/read-only/blank-safe/filterable, is positioned directly below Customer Type on both the Inside Sales layout and Lightning page, and has effective read-only access in all three specified profiles.
- The final report also stated that 533 inspected Inside Sales orders had zero Account/Order Segment mismatches and that no Apex, Flow, trigger, or other code change was required.
- PR approval remained conditional because no branch, commit, PR URL, or actual Git diff was supplied; the artifact therefore records implementation approval subject to PR diff parity.
- Final document checks reported: five letter-size pages, 12 tables with matching explicit geometry, zero high-severity accessibility findings, no forbidden IT/UAT-test terms, and a SHA-256 hash of `002658BB09842189401E278E267F9F6C632466BF9281F989D981BFC723651A8E`.

Failures and how to do differently:
- The first reference render failed on Windows temp-folder permissions (`WinError 5`); rerun with writable task-local `TEMP`/`TMP` directories.
- A PowerShell invocation initially failed due to quoting/parser syntax; use PowerShell call operator syntax (`& 'path-to-python' 'script' ...`).
- The final accessibility audit still reported six medium `table_no_header_row` findings; no evidence shows they were fixed. Treat structural/a11y status as “zero high, six medium” unless the tables are intentionally non-tabular or corrected.
- Do not claim final Git PR approval without an actual branch/commit/diff. Also do not rely on the earlier Merge-state result after the user supplies/currently identifies a different implementation source.

Reusable knowledge:
- For a new review artifact based on a retained DOCX, preserve the reference file unchanged, distill its structure/styles, author a separate document, run structural/a11y/style/table audits, render every page to PNG, and inspect the final pages before claiming visual QA.
- Use the workspace-bundled Python runtime rather than system Python for document tooling.

References:
- Final artifact: `SCC-4487-PR-Review.docx`
- Reference artifact: `SCC-4179-architect-review.docx`
- QA directory: `scc4487-pr-review-work\\deva-final-render-v2`
- Audits: `deva-final-v2-a11y.json`, `deva-final-v2-style-lint.json`
- Final artifact checks: `Pages: 5`; `Page size: 612 x 792 pts (letter)`; `Forbidden-scope terms: None`; `OK: all tables have matching tblW, tblInd, tblGrid, and tcW`.
