thread_id: 01a05d57-9557-73c3-ba3c-88603fd299f4
updated_at: 2026-09-01T17:52:04+00:00
rollout_path: \\?\C:\Users\LIKKI\.codex\sessions\2026\09\01\rollout-2026-09-01T19-50-16-01a05d57-9557-73c3-ba3c-88603fd299f4.jsonl
cwd: \\?\C:\Users\LIKKI\Documents\ChatGPT\david
git_branch: master

# SALDEV-1473 was diagnosed and fixed in the FlywirePartial sandbox

Rollout context: Salesforce DX workspace `C:\Users\LIKKI\Documents\ChatGPT\david`; supplied Salesforce session URL treated as a secret and not repeated.

## Task 1: Connect and verify FlywirePartial

Outcome: success

Key steps:
- Reused alias `FlywirePartial` and authenticated through masked `sf org login access-token` input.
- Read-only `Organization` query verified Flywire / Enterprise Edition sandbox, org ID `00DhG0000000jOXUAY`, instance `USA1148S`.
- No metadata or data changes were made during authentication.

Failures and how to do differently:
- Existing authentication initially produced no identity result; use masked access-token login rather than exposing a frontdoor/session token.
- Salesforce CLI may require elevated/permitted access to its `.sf` log directory when `EPERM` occurs.

## Task 2: Diagnose and fix SALDEV-1473 quote-line create regression

Outcome: success

Preference signals:
- The user asked to “work on this story” and then “how its is happening can we fix this,” indicating they want root-cause explanation plus an implemented, validated fix—not only a document review.
- The agent was expected to avoid Production changes and validate in `FlywirePartial` first; this constraint was explicitly followed.

Key steps:
- Located the active Flow source at `force-app\main\default\flows\QuoteLine_After_Record_Triggered_Flow.flow-meta.xml`.
- Retrieved failed debug log `07LhG000006o9MTUAY.log`; it showed the hierarchy custom error during `OpportunityLineItemTriggerHandlerTest.setupTestData` line 92 while inserting Quote Lines.
- Root cause: new Quote Lines can temporarily have blank `Ship_To_Account__c`; the Flow’s `NotEqualTo` comparison treated blank as different and routed into `Validation_Error` before CPQ finished populating/inheriting Ship-To data.
- Added an `IsNull = false` condition to `Yes_Different_Ship_To_Found`, so direct hierarchy validation runs only when Ship-To is populated. Blank/inherited lines continue through the quote-wide lookup and Multiple Ship-to calculation.
- Candidate check-only deployment succeeded; the formerly failing focused test passed 2/2.
- Deployed only the Flow to `FlywirePartial`; deployment succeeded with zero component/test errors.
- Tooling read-back confirmed Flow version 9 is Active; post-deployment focused tests passed 3/3.

Reusable knowledge:
- Flow trigger is `RecordAfterSave` on `SBQQ__QuoteLine__c` with `CreateAndUpdate`.
- Active Flow version ID: `301hG00000BgdJcQAJ`; FlowDefinition active/latest version matched it.
- Validation error text: `Please ensure that the Ship-To Account entered for each Quote Line is within the primary Account's hierarchy.`
- Follow-up business validation remains needed: Parth should retry the same quote creation, then open Edit Lines and Quick Save to confirm Multiple Ship-to Accounts still recalculates correctly.

Failures and how to do differently:
- Focused test initially failed 3/3 at Quote Line insert; do not disable the hierarchy validation or promote the document while this create-path regression exists.
- `FlowInterview.Status` and `Flow.TriggerType` were invalid SOQL fields; use supported Tooling API fields or inspect metadata XML instead.
- A local XML validation command had quoting errors; the corrected parser command verified the guard, trigger, and status.

References:
- Verification: `sf data query --target-org FlywirePartial --query "SELECT Id, Name, OrganizationType, IsSandbox, InstanceName FROM Organization" --json`
- Test: `sf apex run test --target-org FlywirePartial --tests OpportunityLineItemTriggerHandlerTest --wait 30 --json`
- Deployment: `sf project deploy start --target-org FlywirePartial --source-dir "force-app\main\default\flows\QuoteLine_After_Record_Triggered_Flow.flow-meta.xml" --test-level RunSpecifiedTests --tests OpportunityLineItemTriggerHandlerTest --wait 60 --json`
- Check-only job: `0AfhG000001bYrlSAE`; deployment job: `0AfhG000001bYtNSAU`.
