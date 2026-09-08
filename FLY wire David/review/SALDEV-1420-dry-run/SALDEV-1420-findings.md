# SALDEV-1420 dry run findings

Reviewed 7 September 2026. Recommendation: changes requested before acceptance. No deployment, activation, approval submission, or email send was performed. Existing Salesforce metadata and business records were read; the existing Apex test class ran in isolated test transactions. No implementation files were changed.

## Verified environment and execution

- Alias: FlywirePartial. Organization: Flywire. IsSandbox: true. Org ID: 00DhG0000000jOXUAY. Instance: USA1148S.
- Live reads: EmailTableController, EmailTableControllerTest, EmailTableVFComponent, four approval templates, Email_Table__mdt records, story quote groups/lines, and CPQ Sales permission-set access.
- Apex run: 707hG00000MwelQ, started 2026-09-07 16:30:50 UTC. CLI summary reports Passed, 5 passing, 0 failing; the returned method list contains four test methods. EmailTableController coverage: 125 of 134 lines, reported 93%. Test-run coverage across affected code is 77%; this is not a deployment validation result.
- Six local acceptance-rule simulations passed against the story table, including the empty-group case. They test the proposed ordering rule, not Salesforce execution. See check_order.py and order-results.json.
- No Metadata API check-only deployment was submitted. No newly rendered email or complete new/amendment/renewal business UAT was executed.

## Current findings and required work

### 1 QLE line order is not preserved

The live controller's query sorts by RequiredBy ID and product name, and its recursive traversal preserves that ordering within each parent. It does not use SBQQ__Number__c. Keeping children beneath parents is implemented, but sibling and top-level ordering can differ from QLE.

Concrete evidence: the current story quote a2NhG000003xBvNUAU has Domestic Payments at line 4 and Cross Border Payments at line 5 in Group2. The attached two-non-ramped-group email shows Cross Border Payments before Domestic Payments, consistent with the live controller's alphabetical sort. The eStore bundle also has Usage at line 2 and Implementation Fee at line 3, whereas the supplied email shows Implementation Fee before Usage. The historical email and current quote are separate snapshots; no new email was generated in this review.

Required change: order top-level lines and each sibling list by QLE sequence, retain recursive parent/child placement, and add deterministic tie handling. Assert exact product/line ID sequences, including nonalphabetical examples, nested bundles, and ungrouped quotes.

### 2 Group sort has an extra priority before start date

The August 27 clarification says start date ascending, then subscription term descending only when start dates match. The current query instead starts with Allow_Product_Ramping__c ASC, followed by start date and descending term. Thus a later-starting non-ramped group can precede an earlier ramped group. This is a code-level counterexample; that edge case was not present in the current story quote.

Required change: make start date the primary sort and term the second. Use QLE group sequence as a deterministic tie-breaker when date and term match. Decide explicit handling of blank dates. Preserve group identity by ID, which the live implementation already does.

Story example: G4 = 72 months starting 2026; G1 = 24 months starting 2026; G2 = 12 months starting 2028; G3 = 36 months starting 2029. Required output is G4, G1, G2, G3, giving headers 72, 24, 12, 36 months. It is not 72, 36, 24, 12.

The September 2 mixed-term attachment shows 72, 36, 24, 12 months and the QA comment says term-length sorting. This conflicts with the stated acceptance explanation, but the attachment does not show source group dates. Capture those dates with the retest before calling that historical email a proven sort failure. The currently retained story quote has only two non-ramped groups, so it cannot establish the old four-group dates.

### 3 Required permission-set entry is absent

CPQ_Sales_Permissions exists (label CPQ Sales Permissions). The read-only SetupEntityAccess query found no entry for EmailTableController in that permission set. The story explicitly requires that entry as a post-deployment step.

Required change in the future approved package: include the class-access entry and test as a representative CPQ Sales user. This finding does not imply that every user lacks access; profiles or other permission sets may grant it.

### 4 Tests can pass without validating populated results

Three business tests wrap assertions in if (!groupedLines.isEmpty()). An empty result can therefore bypass expected group and row assertions. Tests primarily use Legal context and do not prove mixed-term start-date ordering, exact QLE sequence, nested bundle behavior, description/rate formatting, or amendment and renewal acceptance.

Required change: assert non-empty expected results before accessing them; assert exact group headers and row sequences; cover all three metadata contexts used by four templates. Passing coverage does not resolve the functional findings.

### 5 Quote Approval has duplicate column positions

Live metadata assigns order 6 to both Billing Frequency and Subscription Type, and the controller orders only by Column_Order__c. Their relative order is not defined.

Required change: use distinct positions, normally Billing Frequency 5 and Subscription Type 6 if that is the intended layout. Quote Approval Description also currently references SBQQ__Description__c alone, while the test execution document lists a CONCAT mapping. Legal does use the required CONCAT. Reconcile this Quote Approval evidence discrepancy with the intended scope before changing its content.

## What is already configured

- All four queried templates are active and reference EmailTableVFComponent. Quote Approval passes Quote Approval context; Legal and Credit Risk pass Legal; Revenue passes Revenue Approval.
- The current component renders sequential Term headers and suppresses a header for ungrouped lines. It no longer uses the old Group / Ramped Up / dates banner shown in the August screenshots.
- The controller filters Quote_Line_Type__c = Amendment out of the line query.
- Legal Description uses CONCAT: External_Description__c, Rate_Details__c. Blank parts are skipped before joining; no separate Rate Details column exists in the Legal metadata. The supplied emails show merged text.
- Grouping uses group IDs and supports recursive bundle traversal.
- Ship-To column visibility follows Multiple_Ship_to_Accounts__c = Yes. The story explicitly moves automatic population of that flag to another ticket.

These are configuration/source findings, not blanket end-user UAT passes. Dates were requested earlier in the story but are absent from the latest Term-only header and September emails. Confirm whether the later header decision supersedes the earlier date-display request before adding dates back.

## Retest and handoff steps

1. Start from a fresh export of the verified sandbox components. The root force-app copies are stale: old group headers, name-based grouping, and old production-named template bodies remain there. Do not use them as the release baseline.
2. Correct line sequence, group sort priority, missing class access, and duplicate column order in an isolated local package. Keep scope to SALDEV-1420; do not include SALDEV-1403 OmniStudio scripts or unrelated metadata.
3. Strengthen EmailTableControllerTest and rerun it. Use assertions for actual output, not only coverage or absence of exceptions.
4. Retest all six grouping scenarios in the supplied story table across Quote Approval, Legal, Credit Risk, and Revenue. Include a later-starting non-ramped group to expose ramp-flag priority and different group names with equal dates/terms to check ties.
5. For each grouping scenario, capture source group IDs, start dates, terms, QLE sequence, template identity, and corresponding output. Use an existing non-sending preview where available; actual approval submissions or email sends require separate authorization.
6. Verify new, amendment, and renewal cases: unchanged Amendment lines excluded; intended new/price-change/cancellation lines retained; displayed lines reconciled with intended Opportunity Products. Verify no-groups output and nested bundles.
7. Verify populated/blank Rate Details, blank descriptions, punctuation, and duplicate text. Obtain Legal acceptance of the rendered text. Test the intended business-user permissions and Ship-To visibility.
8. Only after the candidate is complete, perform a separately scoped check-only deployment validation if requested. Report it separately from Apex tests and business UAT. Deployment remains prohibited under this request.

## Evidence index

All six supplied DOCX files were text-extracted and reviewed, and the four supplied screenshots were inspected. The August screenshots depict superseded headers; their instructions were treated as source evidence, not execution authorization.

Current sandbox evidence is saved beside this report: live-classes.json, live-component.json, live-templates.json, live-columns.json, live-groups.json, live-lines.json, live-access.json, live-permission-set.json, and apex-test-result.json. EmailTableController.cls and EmailTableControllerTest.cls are isolated copies of the retrieved current bodies. The important live controller sort is at line 168; conditional test assertions occur at lines 88, 113, and 138 of the retrieved test copy.
