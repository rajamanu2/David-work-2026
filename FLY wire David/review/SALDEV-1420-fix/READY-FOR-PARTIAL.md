# SALDEV-1420 candidate for Partial

Prepared against a fresh retrieve from FlywirePartial, organization 00DhG0000000jOXUAY, verified as a sandbox. The user subsequently approved deployment. All four components are now deployed and independently verified. See DEPLOYMENT-RESULTS.md for the completed deployment and repeat dry-run results.

## Exact changes

1. EmailTableController: sort groups by start date ascending, subscription term descending for equal dates, then QLE group number and group ID; sort lines by QLE line number with ID ties. Blank dates and sequence values go last. Existing recursive bundle placement, amendment exclusion, text formatting, and template routing remain unchanged.
2. EmailTableControllerTest: require populated outputs instead of conditionally skipping assertions; add mixed-term chronology, equal-term sequence, later non-ramped group, nonalphabetical line order, nested bundle, ungrouped, three template contexts, blank description/rate, and Quote Approval column-order checks. Isolate fixture and test query budgets.
3. Email_Table.Quote_Approval_Field_5: Billing Frequency column position changes from 6 to 5. Subscription Type stays at 6.
4. CPQ_Sales_Permissions: add enabled Apex class access for EmailTableController. All other retrieved entries are preserved.

## Validation

Salesforce check-only job 0AfhG000001eJt0SAE succeeded: checkOnly=true, zero component errors, seven tests passed, zero test failures. Controller coverage is 131/134 lines (97.76%). The exact result is in validation-attempt3-report.json.

Two earlier check-only attempts compiled but encountered query limits in new test fixture setup. These were resolved through test transaction isolation; the final run passed all seven methods.

The readable change set is candidate.diff. candidate-sha256.json identifies the candidate files. baseline contains the pre-change retrieve for comparison and rollback preparation; it is outside the deployable force-app directory. The deployable directory contains exactly the four components and their metadata descriptors.

## Approval and follow-up

The user explicitly approved deployment to FlywirePartial. Deployment 0AfhG000001eM9KSAU succeeded with four components and seven passing tests. Production was not changed.

Target identity, candidate checksums, and baseline drift were checked before deployment. A subsequent retrieve matched all six source files after normalizing only final whitespace, and the existing quote's controller output passed exact row-order assertions in all three contexts. Repeat check-only job 0AfhG000001ePQXSA2 passed seven tests. Business-user access and rendered email acceptance still require verification; see SALDEV-1420-TEST-STEPS.md. No approval submission or email sending was performed.
