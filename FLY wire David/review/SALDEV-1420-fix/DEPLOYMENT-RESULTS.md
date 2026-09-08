# SALDEV-1420 Partial deployment and repeat dry run

Completed on 7 September 2026 following explicit user approval. Target FlywirePartial was verified as Flywire sandbox 00DhG0000000jOXUAY, instance USA1148S. Production was not changed.

| Check | Result | Evidence |
|---|---|---|
| Candidate integrity | All validated file hashes matched | candidate-sha256.json and preflight-result.json |
| Pre-deployment drift | No differences from the saved baseline | predeploy retrieve and preflight-result.json |
| Deployment | Succeeded; four components, seven tests, zero component/test errors; checkOnly=false | 0AfhG000001eM9KSAU, deployment-result.json |
| Independent metadata read-back | Six source files matched after final-whitespace normalization; only the test file's final newline differed | postdeploy retrieve and postdeploy-comparison.json |
| Existing quote controller checks | Passed exact row-order assertions for Legal, Quote Approval, and Revenue Approval | postdeploy-controller-result.json |
| Repeat dry run | Succeeded; seven tests, zero component/test errors; checkOnly=true | 0AfhG000001ePQXSA2, postdeploy-dryrun-result.json |
| Controller coverage | 131 of 134 lines, 97.76% | Repeat dry-run codeCoverage |

The four changed components are EmailTableController, EmailTableControllerTest, Email_Table.Quote_Approval_Field_5, and CPQ_Sales_Permissions. The permission-set read-back includes enabled EmailTableController class access and preserves the remaining retrieved entries. Billing Frequency is column 5. The candidate.diff file describes the approved changes.

The live read-only controller check used quote a2NhG000003xBvNUAU. It confirmed eStore, eStore (Usage), eStore - Implementation Fee in the first group, and Domestic Payments, Cross Border Payments in the second group, across all three table contexts. Credit Risk uses the same Legal context; a separate Credit Risk email render was not performed.

No approval request was submitted, no email was sent, and no business test record was edited by the agent. Salesforce test fixture writes occurred only inside isolated test transactions. Full new/amendment/renewal UAT, actual template/email rendering, representative user access, and Legal acceptance remain business test steps, not completed checks. Follow SALDEV-1420-TEST-STEPS.md.
