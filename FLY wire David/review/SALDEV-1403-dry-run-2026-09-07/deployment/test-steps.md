# SALDEV 1403 Partial test steps

The two Data Mappers and the proposal template have been updated in **FlywirePartial**. This guide tests the deployed changes. Production was not changed.

## Start with the reported defect

1. Sign in to the [Flywire Partial sandbox](https://flywire--partial.sandbox.my.salesforce.com).
2. Open [quote Q-37912](https://flywire--partial.sandbox.lightning.force.com/lightning/r/SBQQ__Quote__c/a2NhG000003lAjmUAE/view).
3. Open the quote action menu and select **Generate Document** or **Generate Quote Document**, using the existing stepped-up-pricing action. The action may be under the dropdown beside the visible quote buttons.
4. If template selection is displayed, select **CPQ Quote Proposal**. Complete the existing generation screen and choose its Preview or Generate option.
5. Open the newly generated document. Do not use a previously attached PDF to test this change.
6. Verify four groups in this order:

| Heading | Source group | Expected term |
| --- | --- | ---: |
| Term 1: 36 Months | Group4 | 36 |
| Term 2: 12 Months | Group1 | 12 |
| Term 3: 12 Months | Group2 | 12 |
| Term 4: 12 Months | Group3 | 12 |

7. Confirm no service dates appear in the group headings. Confirm the sequence begins at Term 1, has no skipped/repeated numbers, and restarts at Term 1 when you generate another document.
8. Compare the products in each section with the quote line editor. Products must remain in the correct group and in quote-line order. Bundle children must stay directly beneath their parent, with nested children together. Q-37912 currently has 78 eligible product lines across the four groups.
9. Confirm the **Ship-To Account column is hidden** for this quote because Multiple Ship-To Accounts is No.

## Regression scenarios

Close and reopen the generation screen for each quote so it uses the new quote context. Generate a fresh document each time.

| Quote | Check | Expected result |
| --- | --- | --- |
| Q-37640 | Grouped quote, Ship-To No | Three groups with 12-month terms; 12 product lines; bundle order preserved; no Ship-To column |
| Q-38009 | Ungrouped quote, Ship-To Yes | Original ungrouped layout; nine product lines; Ship-To column visible; no Term/Group heading |
| Q-38023 | Ungrouped quote, Ship-To No | Original ungrouped layout; two product lines; Ship-To column hidden; no Term/Group heading |
| Q-38021 | Ungrouped renewal | Twenty product lines in quote-line order; no Ship-To column; no group heading |
| Q-37723 | Grouped renewal, Ship-To Yes | Five groups and 14 product lines; Ship-To column visible; use this for structure/Ship-To checks only because group subscription terms are missing |
| Q-37780 | Grouped quote, Ship-To No | Five groups and 18 product lines; bundle order and Description formatting correct; use this for structure/Ship-To checks only because group subscription terms are missing |
| Q-38029 | Amendment exclusion | Its current two Amendment lines are excluded, leaving zero eligible product lines; this is an exclusion check only |

Q-37640 is grouped now. Use Q-38009 and Q-38023 for the ungrouped regression checks rather than following the old handoff's Q-37640 assignment.

## Description checks

Use Q-38009, Q-37780, and Q-38021 for Rate Details. Their current eligible lines include two, four, and two populated Rate Details values respectively.

- Rate Details must appear in the Description column, not a separate column.
- The description and rate text should have appropriate spacing, with no blank-value placeholder or literal `NULL`.
- A missing Rate Details value must not add dangling punctuation or an extra trailing separator.
- Applicable Cancellation, Quantity Increase, and Quantity Reduction labels must remain visible.

For positive amendment output, use an existing suitable amendment quote that includes eligible non-Amendment line types. Q-38029 does not provide positive output coverage. Do not change quote data merely to make this exclusion case pass.

## Record the result

Capture the quote number, generated document filename/time, pass/fail, and a screenshot of any incorrect heading or product section. Report the expected versus actual order if a line is misplaced. Do not accept blank XX Months headings as a successful test when a group's subscription term is missing.

Backend verification passed after deployment. Browser-generated document appearance and automatic Word numbering still require these user-facing checks because the automation browser was waiting for Salesforce password sign-in.
