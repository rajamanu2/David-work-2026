# SCC-4166 dry-run summary

## Decision

**NO-GO for the full package.** Do not deploy SCC-4166 to GreatPlainsUAT yet.

The corrected 8-component MTTR core passes check-only validation, but the complete 13-component scope remains blocked by two missing SCC-3384 prerequisites and unrelated profile drift. No metadata was deployed or activated, and no Salesforce records or settings were changed.

## Verified orgs

- Source: `GreatPlainsMerge` (`00DEa00000GkAsHMAV`, sandbox)
- Target: `GreatPlainsUAT` (`00DEa00000FZlLBMA1`, sandbox)
- Source retrieval: `09SEa00000icqSVMAY` (succeeded)

## Source implementation defects repaired locally

1. `Case_Before_Insert_Update_Trigger_Flow` used the same condition for entering and exiting `On Hold – Pending Customer`. The local repair changes the exit rule to current status not equal to hold and prior status equal to hold.
2. `Case.MTTR__c` used `BlankAsZero` while testing whether `MTTR_Minutes__c` is blank. The local repair changes it to `BlankAsBlank` so open/incomplete cases remain blank.

Live read-only evidence showed 20 open GreatPlainsMerge Cases with blank numeric MTTR but text MTTR equal to `0 Hours 0 Minutes`.

## Check-only results

### Corrected core

- Job: `0AfEa00000bbRYbKAM`
- Result: `Succeeded`
- `checkOnly`: `true`
- Components: 8/8 succeeded
- Scope: 6 Case custom fields and 2 Flows
- Apex tests: 0 (`NoTestRun`; no Apex in scope)

### Corrected full scope

- Job: `0AfEa00000bbRbpKAE`
- Result: `Failed`
- `checkOnly`: `true`
- Components: 8/13 succeeded; 5 errors
- Apex tests: 0 (`NoTestRun`; no Apex in scope)
- `rollbackOnError`: `true`

## Five full-scope failures

1. `Case-Case Layout`: missing `Case.Service_Address__c` in GreatPlainsUAT.
2. `Case-Trouble Ticket`: missing `Case.Service_Address__c` in GreatPlainsUAT.
3. `Admin` profile: unknown target user permission `ArchiveArticles`.
4. `Standard` profile: missing `Case.Trouble_Ticket` record type in GreatPlainsUAT.
5. `System Administrator - API Only` profile: unknown target user permission `ArchiveArticles`.

## Component-list correction

The attached story document duplicates `MTTR_Minutes__c` and omits both active Flows plus `Case-Case Layout`. The architecture-complete scope contains 13 unique components:

- 6 Case custom fields
- 2 Flows
- 2 Case layouts
- 3 profiles

## Required repair sequence

1. Approve the two local MTTR repairs.
2. Promote the SCC-3384 prerequisites (`Case.Service_Address__c` and `Case.Trouble_Ticket`) before SCC-4166.
3. Replace the broad profile payloads with a focused permission set or target-aligned profile retrieval; exclude unrelated `ArchiveArticles` drift.
4. Re-run the full check-only validation and require 13/13 success.
5. Run the four business paths in the architect-review document and capture Case/Work Order IDs plus field-level read-back.

