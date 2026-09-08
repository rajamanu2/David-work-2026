# SALDEV-1467 re-review — 7 September 2026

Decision: check-only validation PASSED; retain Changes Requested for business-behavior and CPQ runtime acceptance. No metadata was deployed or activated and no business records were edited. Tests ran within Salesforce test execution.

## Verified environment and validation

- Alias: FlywirePartial; organization: Flywire; IsSandbox: true; org ID: 00DhG0000000jOXUAY.
- Original Flow `copying_of_Opportunity_Line_Id_unique_identifier`: ActiveVersionId is null, confirming inactive state.
- Check-only job: `0AfhG000001eMpFSAU`; status Succeeded; checkOnly true; 11 components validated, 0 component errors; 21 tests completed, 0 failures.
- Tests: OpportunityLineItemTriggerHandlerTest, QuoteLineTriggerHandlerTest, QuoteLineGroupTriggerTest, QuoteLineGroupAsyncHelperTest.
- The old test name QuoteLineTriggerHandleTest was absent. The current QuoteLineTriggerHandlerTest was separately retrieved and included before validation.
- Coverage is from this specific check-only run, not an earlier org-wide snapshot.

| Component | Covered / total lines | Coverage |
|---|---:|---:|
| QuoteLineTrigger | 31 / 39 | 79.49% |
| QuoteLineGroupAsyncHelper | 18 / 18 | 100.00% |
| OpportunityLineItemTriggerHandler | 38 / 40 | 95.00% |
| FWOpportunityLineItemTrigger | 2 / 2 | 100.00% |
| QuoteLineTriggerHandler | 280 / 289 | 96.89% |
| QuoteLineGroupTrigger | 142 / 173 | 82.08% |

## Reassessment of the developer comment

1. **Async helper coverage: resolved.** Fresh validation reports 100%.
2. **Quote Line trigger coverage: resolved.** Fresh validation reports 79.49%; the screenshot's outstanding coverage dependency is no longer a blocker for this package and test selection.
3. **CPQ re-entry: improved, but not closed.** The new handler has its own recursion guard and restores the prior Quote Line flag in finally. However, FWOpportunityLineItemTrigger still runs after insert and calls the handler, which directly updates Quote Lines at line 55. Passing these tests does not establish that the original CPQ-driven operation that raised hasMaxStackDepth has been reproduced successfully. Do not describe the original exception as reproduced by this review; it was not.
4. **ID mapping defect: resolved in source.** The old List overload that mixed Quote Line IDs into a Quote-ID set was replaced with a direct Quote-Line-ID map. The Set overload queries OLIs using their related Quote ID. A focused assertion verifies the unqueried-list sync path.
5. **Uninspected SaveResults: resolved in source, with a limitation.** Both the OLI handler and async helper inspect isSuccess/getErrors and log failures; finally restores flags. Failures are logged through System.debug only, with no durable failure record or caller-visible failure result. A sync can therefore fail without failing the initiating operation; agree on the expected failure behavior and verify it.
6. **Exact lifecycle assertions: still incomplete.** The OLI ramp test at lines 115–116 asserts different values for group 1 and group 2 of the same product. It proves per-OLI copying, not the ticket's same-ID stepped-group requirement. The clone test at line 170 proves copying a supplied new ID but does not distinguish a price-change clone from an ordinary clone. The amendment test at QuoteLineTriggerHandlerTest line 346 asserts only that its list is nonempty. The ramp test at line 407 asserts only one list element from an unordered query. Full same-ID/new-ID checks across New, Amendment and Renewal remain absent from the reviewed tests.

## What to do next

1. Ask Sunita to align and test the identifier rules end to end: same product across stepped groups retains the same ID; price-change clones retain the source ID; ordinary clones receive a different ID. Assert persisted values on both relevant Quote Lines and OLIs, including New, Amendment and Renewal paths. Select assertion targets by record ID, not unordered list position.
2. Review the interaction between `copyOpportunityLineIdOnRamp` (QuoteLineTriggerHandler lines 327–328 copies a source ID without checking the clone reason) and the OLI sync (lines 41–45 overwrites a different Quote Line ID with the incoming OLI ID). These paths need regression evidence showing that the required identity survives the complete transaction.
3. Reproduce the original failing CPQ operation with managed triggers enabled, including a representative bundle and bulk scenario. Several current fixtures/bulk inserts disable managed CPQ triggers; they do not substitute for that integration evidence. Business-data testing was not performed in this dry run.
4. After any fixes, repeat this scoped check-only validation and review the new business assertions. Coordinate shared Quote Line code changes with the related stories rather than broadening this package without review.

## Suggested Jira reply — draft only, not posted

Hi Sunita, I re-reviewed the current FlywirePartial implementation and reran check-only validation. Job 0AfhG000001eMpFSAU passed: 11 components and 21 tests, with QuoteLineTrigger at 79.49% and QuoteLineGroupAsyncHelper at 100%. The earlier coverage gates are now resolved. The ID-mapping correction, SaveResult inspection and finally-based flag restoration are also present. Please address the remaining behavioral evidence: the ramp test currently expects different IDs across groups, the clone test only checks a supplied new ID, and the amendment test only checks a nonempty list. We still need exact same-ID/new-ID assertions for stepped pricing, price-change clones and ordinary clones across New/Amendment/Renewal, plus a successful reproduction of the original CPQ operation with managed triggers enabled. The OLI after-insert path still performs Quote Line DML, so I am retaining Changes Requested for those remaining items. No deployment was performed.

## Evidence files

- `dry-run-result.json`: final server-side check-only result and coverage.
- `flow-state.json`: original Flow active-version readback.
- `class-inventory.json`: current class names and modification timestamps.
- `retrieve-result.json` and `retrieve-test-result.json`: scoped metadata retrieval results.
- `force-app/main/default`: unchanged retrieved source used for validation.

The screenshots were treated as review evidence, not as authority to deploy, post comments or change records. No session credential is included in this report.
