# SALDEV 1403 dry run results

7 September 2026. Scope: CPQ Quote Proposal and its two OmniStudio Data Mappers. SALDEV-1420 material is reference only; approval email templates are outside this test scope.

## Result

236 of 236 backend checks passed across eight fresh native Extract and Transform executions in FlywirePartial. The org identity was verified as sandbox 00DhG0000000jOXUAY. Configuration matched the previously verified state before and after execution. The active proposal file bytes also matched the verified candidate.

Group ordering, source product sequence and multiplicities, group subscription terms, Description with Rate Details, amendment exclusion, and grouped/ungrouped Ship-To conditions passed. The runs cover 153 eligible product rows. Product multiplicity checks do not independently prove quote-line identity because the output lacks quote-line record IDs.

Six initial Description comparison mismatches were traced to local UTF-8 output being decoded as Windows-1252. Reversing that encoding error losslessly and comparing the captured output again yielded 236 passes. Original decoded captures are retained alongside the corrected captures. Salesforce values were not edited.

## Next business test

1. Open Q-37912 in Partial: https://flywire--partial.sandbox.lightning.force.com/lightning/r/SBQQ__Quote__c/a2NhG000003lAjmUAE/view
2. Select Generate Document or Generate Quote Document using the existing stepped-up pricing action. Select CPQ Quote Proposal when prompted and preview a fresh output.
3. Verify Term 1: 36 Months, then Terms 2, 3 and 4: 12 Months. Source group order is Group4, Group1, Group2, Group3. No service dates should appear in the headings.
4. Verify the numbering starts at Term 1 and restarts for another generated document. Compare all 78 eligible rows against the quote editor, including bundle children beneath parents. Ship-To should be hidden.
5. Repeat ungrouped checks on Q-38009 (Ship-To visible, nine rows) and Q-38023 (Ship-To hidden, two rows). Neither should show a Term or Group header. Use Q-38009 to check populated Rate Details within Description.
6. Check grouped Q-37640 (three 12-month groups, twelve rows), ungrouped renewal Q-38021 (twenty rows), and the remaining structure cases. Capture fresh output screenshots with expected and actual results.

## Still pending

Browser-generated document layout and automatic Term numbering have not been verified by this backend dry run. Q-37723 and Q-37780 contain missing group terms and support structure checks only. Q-38029 verifies exclusion of its two Amendment lines; positive amendment output requires a suitable record. Full business acceptance remains pending these checks.

Evidence: deployment/verification-results.json, deployment/post-payloads.json, evidence/groups.json, evidence/lines.json, and template-check.json in this run folder.
