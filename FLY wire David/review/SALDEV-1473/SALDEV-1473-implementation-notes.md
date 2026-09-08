# SALDEV-1473 - Implementation Notes

## Status

The Flow fix is deployed and active in `FlywirePartial`. Salesforce check-only validation and post-deployment metadata read-back both passed. Functional QLE validation is still required; no quote or quote-line records were changed or backfilled during deployment.

## Confirmed org state

- Target: `FlywirePartial`
- Org: Flywire Enterprise sandbox (`00DhG0000000jOXUAY`, instance `USA1148S`)
- Flow: `QuoteLine_After_Record_Triggered_Flow`
- Active/latest version: 8 (`301hG00000BfrsBQAR`)
- Previous versions 6 and 7 are `Obsolete`
- Version 7 only changed the trigger from update-only to create-and-update; it did not correct the quote-wide calculation.

## Defect evidence

A read-only sample of the 2,000 most recently modified quote lines from the last 30 days covered 155 quotes. Twenty-four quote headers were set to `No` even though their lines contained a ship-to account different from the quote account. Fifteen of the mismatches included ramped quote lines.

Mismatch distribution:

| Account record type | Mismatches | With ramped lines |
| --- | ---: | ---: |
| B2B | 11 | 7 |
| Education | 11 | 6 |
| Travel | 2 | 2 |

## Root cause

The active Flow evaluates only the quote line that triggered the interview. One line with a different ship-to sets the quote header to `Yes`, but a later line whose ship-to matches the quote account can set it back to `No`. During a multi-line Save/Quick Save, the final header value therefore depends on line processing order. The update-only start condition also misses quote lines that are created without a later update.

## Local implementation

Updated `force-app/main/default/flows/QuoteLine_After_Record_Triggered_Flow.flow-meta.xml` to:

1. Run after both quote-line create and update.
2. Query the entire quote for the first line whose effective ship-to differs from the quote account.
3. Treat a direct `Ship_To_Account__c` as the effective value and fall back to `Parent_Ship_to_Account__c` for child lines used by stepped-up pricing.
4. Set `Multiple_Ship_to_Accounts__c` to `Yes` when a different effective ship-to exists; otherwise set it to `No`.
5. Preserve the current hierarchy validation, Renewal/Upsell logic, and Strategic Partner exception.

## Validation evidence

- XML parsed successfully.
- Expected structure found: `CreateAndUpdate`, two record lookups, six decisions, and six filters in the new quote-wide lookup.
- Salesforce check-only deployment `0AfhG000001bMygSAE` succeeded for one Flow component with zero component errors.
- Test level: `NoTestRun`; no Apex or Flow tests were executed by the validation.
- Deployment `0AfhG000001bPN5SAM` succeeded for one Flow component with zero component errors (`CheckOnly=false`).
- Independent Tooling API read-back confirmed version 8 is active and contains the `CreateAndUpdate` after-save trigger, the six-filter quote-wide lookup, and the expected Yes/No decision routing.
- No quote or quote-line data was changed or backfilled.

## Functional validation result

**PASS - primary acceptance criterion.** On 2026-09-01, `Q-37873` was tested in QLE. The Draft, non-ordered quote contained 44 lines, 32 ramped lines, two direct ship-to accounts, and six lines using the alternate ship-to account. Its header initially showed `Multiple Ship to Accounts = No`. A Quick Save with no line edits triggered active Flow version 8, and the quote header updated to `Yes`. Independent SOQL read-back confirmed `Multiple_Ship_to_Accounts__c = Yes` and the record remained Draft and non-ordered.

## Functional test matrix

| Scenario | Expected result after Save/Quick Save |
| --- | --- |
| Non-stepped quote; every line uses the quote account | Header = `No` |
| Non-stepped quote; at least one line uses another related account | Header = `Yes` |
| Stepped/ramped group; at least one line uses another related account | Header = `Yes` |
| Quote containing both ramped and non-ramped groups with multiple accounts | Header = `Yes` |
| Add a new different-account line without a later edit | Header = `Yes` |
| Change the final different-account line back to the quote account | Header = `No` |
| Child line inherits a different ship-to from its required-by parent | Header = `Yes` |
| Invalid ship-to outside the permitted hierarchy | Existing validation error remains |
| Renewal line type `New` or `Quantity Increase` | Existing Renewal + Upsell behavior remains |
| Strategic Partner quote | Existing exception remains unchanged |

## Scope note

The acceptance criterion covers Save/Quick Save, and this implementation handles create and update. A delete-only recalculation is not part of the current Flow trigger and should be added as a separate requirement if deleting the final different-account line must immediately reset the header without another save/update event.

## Ready-to-paste Jira update

Investigated and fixed SALDEV-1473 in the Flywire Partial sandbox. The QuoteLine after-save Flow calculated the header from each triggering line, so a later same-account line could overwrite `Multiple Ship to Accounts` back to `No`; the active Flow was also update-only. Version 8 now runs on create/update and recalculates from all quote lines, including inherited parent ship-to values used by stepped-up pricing. Check-only validation passed (job `0AfhG000001bMygSAE`), and the deployment succeeded for 1 Flow with 0 errors (job `0AfhG000001bPN5SAM`). Version 8 is active. No quote data was backfilled. QLE functional validation remains for stepped, non-stepped, mixed-group, revert-to-single-account, validation-error, and renewal regression scenarios.
