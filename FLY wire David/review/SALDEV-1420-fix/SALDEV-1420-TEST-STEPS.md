# SALDEV-1420 test steps in Partial

Use FlywirePartial only. Confirm the browser address contains flywire--partial.sandbox before testing. Run the business checks as a representative CPQ Sales user; administrator-only success does not establish user access. Record the username and permission-set assignment with the results.

## 1 Confirm the deployed setup

1. Open Setup, Permission Sets, CPQ Sales Permissions, Apex Class Access. Confirm EmailTableController is enabled. Confirm the test user is assigned this permission set or the intended equivalent access.
2. Open Setup, Custom Metadata Types, Email Table, Manage Records. Confirm Quote Approval Field 5 has Billing Frequency as its header and Column Order = 5. Subscription Type should remain at 6.
3. Use these four templates for the output checks: Request - Quote Approval Request - AQS; Legal - Approval Request; Credit Risk - Approval Request; Revenue - Approval Request. Their API names are AQS_Quote_Approval_Request, Legal_Approval_Request, Credit_Risk_Approval_Request, and Revenue_Approval_Request. Legal and Credit Risk share the Legal table context.

## 2 Quick check with the retained story quote

The existing SALDEV-1420 Test Opp quote is a2NhG000003xBvNUAU. Open https://flywire--partial.sandbox.lightning.force.com/lightning/r/SBQQ__Quote__c/a2NhG000003xBvNUAU/view and inspect its current lines before using it; another tester may have edited it.

At verification time it has two non-ramped 72-month groups, both starting 1 October 2026. In Edit Lines, confirm the sequence below. Use a non-sending template preview with the appropriate Quote/Opportunity approval record if available in your workflow. For an actual approval email, use your normal sandbox approval process with approved test recipients; a real approval submission changes approval state and can send mail.

Expected output:

| Header | Product order |
|---|---|
| Term 1: 72 months | eStore, eStore (Usage), eStore - Implementation Fee |
| Term 2: 72 months | Domestic Payments, Cross Border Payments |

Pass: headers appear once per group, all five expected lines appear once, bundle children remain beneath eStore, and Domestic Payments precedes Cross Border Payments. Compare output to the current QLE, not an older email screenshot.

## 3 Main mixed-term sorting test

Create a dedicated sandbox test Opportunity and Quote through the normal CPQ workflow, or use an approved test copy. Give it a recognizable SALDEV-1420 UAT name. Use a 72-month quote beginning 1 October 2026. Configure these four groups; use distinctive product/description markers so each group can be recognized in the output.

| QLE group | Ramping | Start date | Subscription term | Expected output position |
|---|---|---|---:|---:|
| G1 | Yes | 2026-10-01 | 24 months | 2 |
| G2 | Yes | 2028-10-01 | 12 months | 3 |
| G3 | Yes | 2029-10-01 | 36 months | 4 |
| G4 | No | 2026-10-01 | 72 months | 1 |

Save and calculate through CPQ. Verify persisted group dates, terms, and line numbers before checking the output; dependent automation can change inputs.

Expected output is G4, G1, G2, G3, with headers Term 1: 72 months; Term 2: 24 months; Term 3: 12 months; Term 4: 36 months. The 36-month group must not jump ahead of the earlier 12-month group. Repeat for all four templates using the appropriate approval record for each.

## 4 Additional ordering scenarios

| Scenario | Action | Expected result |
|---|---|---|
| Three ramped groups | Use successive start dates with terms 12, 6, and 18 months | Chronological 12, 6, 18 output, not descending term order |
| All non-ramped groups | Use equal dates and equal terms; put a Z-named group before an A-named group in QLE | QLE group sequence wins the date/term tie; names do not reorder them |
| Two non-ramped and two ramped | Give both non-ramped groups the full quote term and first start date | Full-term groups appear first in QLE tie order, then ramped groups chronologically |
| Later non-ramped group | If permitted by CPQ, give a non-ramped group a later start than an earlier ramped group | Earlier start appears first regardless of ramping flag |
| No groups | Use an ungrouped quote with deliberately nonalphabetical product order | One flat table with no Term or Group header; QLE line order retained |
| Equal dates, unequal terms | Give two groups the same start but different terms | Longer term first |
| Missing date or sequence | If supported by the UI, leave a group date/sequence blank | Dated/numbered entries sort before missing values; no rendering error |

If a scenario is blocked by a CPQ validation rule, record it as blocked with the error. Do not disable unrelated rules to force test data. The later non-ramped and nested ordering cases also have automated Apex coverage, but UI restrictions should still be recorded.

## 5 Bundle and standalone line order

1. Add a bundle plus at least two standalone products. Arrange standalone products in nonalphabetical order in QLE.
2. Arrange bundle options in nonalphabetical QLE order. Include an available nested bundle if supported by your product catalog.
3. Save, calculate, and inspect the resulting email table for each template.
4. Confirm each parent is followed by its children, each child's descendants remain under it, and sibling/standalone order follows QLE. No line should be duplicated, lost, or moved to another group.

## 6 Description and Rate Details

On a Legal output, test separate lines with: both Description and Rate Details populated; Description only; Rate Details only; and both blank. Use External Description for the Legal description source. Verify one Description column, each value shown once, readable separation, and no trailing separators, NULL text, or placeholder text for missing content. Have Legal confirm formatting is suitable to copy into its contract workflow.

On Quote Approval, confirm Billing Frequency precedes Subscription Type. This change does not alter Quote Approval's description mapping.

## 7 Amendment and renewal regression

1. Use the normal CPQ amendment process on an approved sandbox contract. Include unchanged lines and genuine changed/new/cancelled lines as supported by that contract.
2. Inspect the calculated Quote Line Type values. Lines whose Quote_Line_Type__c is Amendment must be excluded. Eligible changed lines must remain, and their bundle/group order must be correct. Do not try to type a value into Quote Line Type; it is calculated.
3. Reconcile the displayed lines with the intended Opportunity Products as required by the story. Record IDs for any discrepancy.
4. Repeat on a renewal quote. Renewal lines should not disappear merely because they are renewal lines. Verify prices, quantities, descriptions, and order against the quote.
5. If the retained contract/product data cannot support these cases, record the missing prerequisite and leave the case pending rather than marking it passed.

## 8 Ship-To and business-user access

With a valid test setup, verify Ship-To appears when Multiple Ship-to Accounts is Yes and is absent when No. Automatic population of that flag belongs to the separate story; this package does not change it. Verify the actual CPQ Sales tester can render the output without an access error. Check as an approver where the approval workflow requires different access.

## Evidence and acceptance

For each case save the quote ID, template name, tester, source QLE screenshot, group dates/terms, preview or received email, expected result, actual result, and Pass/Fail/Blocked status. Preserve the existing quote inputs before changing scenarios so the screenshots can be reproduced.

Deployment, automated test success, and read-only controller output checks are separate from business acceptance. Sign off only after the required template and new/amendment/renewal checks pass and Legal accepts the output. No approval submissions or emails were sent by the agent as part of deployment verification.
