# SCC-3385 dry-run summary

## Decision

**NO-GO.** Do not deploy SCC-3385 to GreatPlainsUAT yet.

This was a check-only validation. No metadata was deployed or activated and no Salesforce records were created or changed.

## Validation evidence

- Source org: `GreatPlainsMerge` (`00DEa00000GkAsHMAV`, sandbox)
- Target org: `GreatPlainsUAT` (`00DEa00000FZlLBMA1`, sandbox)
- Check-only job: `0AfEa00000bbQXhKAM`
- Result: `Failed`
- `checkOnly`: `true`
- Package: 14 components / 15 files
- Component successes: 6
- Component errors: 8
- Apex tests: 0 run (no Apex in scope; `NoTestRun`)
- Rollback on error: true

## Package used

The corrected package used the source-org Metadata API names:

- 1 Flow
- 1 Quick Action
- 6 WorkOrder custom fields (five new plus updated `Order__c`)
- 3 layouts
- 3 profiles

The story-listed validation rule was not added to the corrected package because it does not exist in the source org.

## Eight check-only component failures

1. `Case-Trouble Ticket` layout: target has no `Case.Service_Address__c`.
2. `WorkOrder-FSL__FSL Work Order Layout`: target has no `Case.Work_Order__c` related-list relationship.
3. `WorkOrder-Work Order Layout`: target has no `Case.Work_Order__c` related-list relationship.
4. `SCC_3385_Create_Trouble_Ticket_Work_Order` Flow: target has no `Case.Priority__c`.
5. `Admin` profile: unknown target user permission `ArchiveArticles`.
6. `Standard` profile: target has no `Case.Trouble_Ticket` record type.
7. `System Administrator - API Only` profile: unknown target user permission `ArchiveArticles`.
8. `Case.Create_Work_Order` Quick Action: insufficient access on its Flow cross-reference (the referenced Flow failed validation).

## Source implementation defects and story discrepancies

- The story says `Case.SCC_3385_Create_Work_Order`; the source component is `Case.Create_Work_Order`.
- The source Metadata API profile names are `Admin`, `Standard`, and `System Administrator - API Only`, not the three labels/casing in the story.
- `WorkOrder.Order_Required_Except_Trouble_Ticket` does not exist in the source org.
- `WorkOrder.Order__c` is still metadata-required (`required=true`). A Trouble Ticket without an Order cannot create a Work Order, despite the intended exception.
- Neither updated WorkOrder layout contains the five new SCC-3385 fields, so the inherited custom values and work instructions cannot be verified on the Work Order page as described.
- The Flow otherwise contains the intended record-type guard, duplicate lookup/link, required Work Type and Work Instructions inputs, Case-to-WorkOrder mapping, completed Task logging, and success/error screens.
- `FSL__Book_Appointment` remains on the FSL Work Order layout.

## Test-data and prerequisite findings

- Cases `00001082` and `00001083` do not exist in GreatPlainsUAT or GreatPlainsMerge.
- GreatPlainsUAT has all four named Work Types: Comm Fiber Trouble, Resi Coax Trouble, Resi Copper Trouble, and Resi Fiber Trouble.
- GreatPlainsUAT does not have the `Case.Trouble_Ticket` record type.
- GreatPlainsUAT has only standard `Priority`, `Comments`, `Description`, and existing `Order__c` among the Case fields used by the Flow. It lacks `Priority__c`, `Service_Address__c`, `Service_Type__c`, `Subscriber_Report__c`, and `Work_Order__c`.

## Required repair sequence

1. Deploy/validate SCC-3384 prerequisites first: Trouble Ticket record type and all Case fields/relationship used by SCC-3385.
2. Make `WorkOrder.Order__c` optional and add the intended active validation rule that requires Order only outside Trouble Ticket Work Orders.
3. Add the five SCC-3385 WorkOrder fields to both WorkOrder layouts.
4. Retrieve profiles with a tightly scoped manifest or replace profile changes with a focused permission set; remove unrelated `ArchiveArticles` and record-type drift from the payload.
5. Correct the story component names to the actual Metadata API names.
6. Create or identify valid Trouble Ticket test Cases matching the expected values.
7. Re-run the same check-only validation and require 14/14 (or the repaired 15/15) components to pass before any deployment approval.

