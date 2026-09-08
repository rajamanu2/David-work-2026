# SALDEV-1420 review of all supplied documents

Review date: 7 September 2026. All six supplied DOCX files were checked for substantive text, tables, embedded screenshots, comments, and tracked changes. The four standalone PNGs were also checked; they are two exact duplicate pairs. No original document or Salesforce configuration was modified during this review. This is a requirements and evidence review, not certification of Word pagination or layout.

Conclusion: the approved four-component fix is deployed and passed automated checks, but the source documents do not establish complete business acceptance of that deployed version. The remaining work is targeted UAT and clarification of the Quote Approval description mapping, not a repeat of the completed deployment.

## Findings by document

| Document | What it establishes | Qualification or action |
|---|---|---|
| SALDEV-1420.docx | Main story, acceptance criteria, implementation inventory, August 27 chronological-order clarification, August 28 six-scenario matrix, and September 2 QA comment | Use the explicit August 27 rule: start date ascending, longer subscription term only for equal start dates. The September 2 mixed-term QA wording conflicts with that rule. Its historical QA pass is not sign-off for the September 7 fix. |
| SALDEV-1420 20-August-2026 (1).docx | Three visual examples: ramped groups, mixed groups, and no groups. Term headers and combined Legal description are visible. | It explicitly describes descending subscription-term sorting. That design was superseded by the August 27 clarification. Do not use its term-only sorting as the current acceptance rule. |
| 1 Non-Ramped Group with 2 Ramped Groups - Legal_Education Opp Approval LGL Req #555852 SALDEV-1420 Test Opp.docx | September 2 Legal email shows three tables headed 72, 36, and 36 months, with rate details in Description. | Equal ramped terms do not prove chronology. Source start dates and QLE sequence are not included. Historical bundle row order must be compared with fresh QLE/output evidence. |
| 1 Non-ramped group, 3 ramped groups with different terms - Legal - Education Opp Approval LGL Req #555852 SALDEV-1420 Test Opp.docx | September 2 Legal email shows 72, 36, 24, and 12 months. | This is insufficient to prove correct date-first ordering because group start dates are absent. If it represents the story matrix's 2026/2028/2029 example, expected terms are 72, 24, 12, 36. Retest with dates captured rather than declaring the historical output definitively wrong without its source data. |
| 2 Non-Ramped Groups - Legal - Education Opp Approval LGL Req #555852 SALDEV-1420 Test Opp.docx | Two Legal group tables, both 72 months, and combined Description content. | It shows eStore Implementation Fee before Usage, and Cross Border Payments before Domestic Payments. The retained quote's current QLE order differs; the September 7 live controller check confirmed the corrected order. The old document is not post-fix evidence. |
| Story Test Execution Document for SALDEV-1420.docx | Three metadata tables and 52 embedded screenshots covering older setup, four template previews, no-group, Travel ramped, B2B non-ramped, and amendment scenarios | The later section headed Updated Testing from Ada's comment lists six scenarios and four template labels per scenario but has no accompanying screenshot results or explicit pass/fail results in this supplied copy. Existing screenshots use the older group/date banner. Update expectations and capture fresh results. |

## Corrections and discrepancies

### Quote Approval Description requires a decision

Both the test execution document's written metadata table and its August 14 metadata screenshot show Quote_Approval_Field_7 as CONCAT:SBQQ__Description__c,Rate_Details__c. A fresh read-only query during this review confirms Partial currently has SBQQ__Description__c alone. This mapping already differed before our deployment, and Field 7 was not in the approved four-component package.

This is a confirmed historical-to-current configuration difference, not proof by itself of an unauthorized change or a new regression. The story's explicit Rate Details acceptance wording targets Legal. Ask the story owner whether Quote Approval should also merge Rate Details; then either correct the mapping through an approved change and test it, or update the test document with the intentional exception. Do not silently mark the discrepancy passed.

Legal_field_5 currently uses CONCAT: External_Description__c, Rate_Details__c. Revenue_Approval_Field_6 currently uses CONCAT: SBQQ__Description__c,Rate_Details__c. Both match their document mappings.

### Column order is now corrected

The test document records Billing Frequency and Subscription Type at position 6. The fresh Partial query confirms Billing Frequency is now 5 and Subscription Type remains 6, matching the deployed fix. Update the old table; do not revert the metadata to its duplicate positions.

### Ship-To wording is too broad

The test execution document says a quote without groups will not have a Ship-To column. The controller's condition is Multiple_Ship_to_Accounts__c = Yes, independent of grouping. No groups alone is not a reason to hide that column. Automatic population of the flag is explicitly assigned to another ticket in the main story.

### Amendment test terminology needs precision

The test document calls the filter Transaction Type and lists New/Price Change/Cancellation. The implemented filter uses Quote_Line_Type__c and excludes Amendment. Retest the actual calculated line types and reconcile with intended Opportunity Products; do not treat the example list as an exhaustive whitelist. Historical amendment screenshots do not establish renewal testing.

### Date display and historical design notes

Early story text requests start/end date handling and older screenshots show dates. Later examples show Term-only headers. The supplied documents do not unambiguously state whether the earlier request to display dates was withdrawn. Confirm that the Term-only header is the accepted final presentation if date display is still disputed. The deployed fix changes ordering, not header date presentation.

The main story also retains an old investigation statement that an external Visualforce component cannot be inserted, followed by the implemented EmailTableVFComponent design. Treat the earlier alternatives as historical investigation, not instructions to replace the working component.

The dependency status text and the later note that true ramped testing is possible also reflect different times. Do not infer current SALDEV-1404 status from this exported story; report a current test-data blockage if encountered.

## What has already passed

Evidence from the completed September 7 run in this task:

- Deployment 0AfhG000001eM9KSAU: four components deployed, seven tests passed, no component or test errors.
- Repeat check-only validation 0AfhG000001ePQXSA2: seven tests passed, zero errors; EmailTableController coverage 131/134 lines (97.76%).
- Independent retrieval matched the package after final-whitespace normalization.
- The existing quote's live controller output passed exact row-order assertions in Legal, Quote Approval, and Revenue contexts. Credit Risk shares the Legal context; that does not substitute for a separate Credit Risk rendered-email check.
- CPQ Sales Permissions class access and the corrected Billing Frequency position were deployed. A representative user's access still needs its business test.

## What remains before story closure

1. Resolve the Quote Approval Description/Rate Details discrepancy with the story owner.
2. Populate the six-scenario test matrix with fresh QLE source dates/terms, row sequences, and output evidence across Quote Approval, Legal, Credit Risk, and Revenue. Mark Pass, Fail, or Blocked explicitly.
3. Cover new, amendment, and renewal behavior; reconcile intended Opportunity Products and calculated line types.
4. Verify blank and populated Rate Details, bundle hierarchy, no-group output, Ship-To visibility, and representative CPQ Sales/approver access.
5. Obtain acceptance of the current rendered output. Kirk's August 20 comment records historical review; it does not cover subsequent sorting changes or the September 7 package.

The supplied documents do not demonstrate completion of these post-deployment business steps. Follow ../SALDEV-1420-fix/SALDEV-1420-TEST-STEPS.md for execution details. No new deployment, approval submission, or email send was performed in this document review.

## Review evidence

index.json records all source filenames, image counts, and comments/tracked-change checks. No Word comments or tracked insertions/deletions were found. doc6/image-context.txt maps all 52 test-document images to their surrounding text; the last images belong to the amendment scenario before the later six-scenario section. current-mappings.json records the fresh read-only Partial metadata query. Deployment evidence remains in ../SALDEV-1420-fix/DEPLOYMENT-RESULTS.md.
