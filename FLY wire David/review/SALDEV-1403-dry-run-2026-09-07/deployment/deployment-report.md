# SALDEV 1403 Partial deployment result

**Deployed to FlywirePartial on 7 September 2026. Post-deployment backend regression passed. Generated-document visual acceptance remains pending.** Production was not changed.

Verified org: Flywire, sandbox, `00DhG0000000jOXUAY`.

## Applied changes

- GetQuoteProposalDataSteppedUpPricing: four added items for group ordering, grouped/ungrouped line ordering, and the group subscription term mapping.
- CPQQuoteProposalDocumentSteppedUpPricing: two Description formula updates for Rate Details and null-safe spacing while retaining applicable line-type labels.
- CPQ Quote Proposal: published the prepared DOCX as a new version of the existing content document. Its grouped headings use sequential Word numbering and group subscription terms; service-period paragraphs are removed.

New mapper item IDs: `0kdhG0000003FiTQAU`, `0kdhG0000003FiUQAU`, `0kdhG0000003FiVQAU`, `0kdhG0000003FiWQAU`.

Updated formula item IDs: `0kdhG0000002nUTQAY`, `0kdhG0000002m5NQAQ`.

Template record: `2dtPb0000000BwLIAU`. Content document: `069hG000003DZfnQAG`. New content version: **`068hG000003PryiQAC`**. The existing template link resolves to this new version, and its downloaded bytes matched the prepared candidate exactly. The previous content version is retained.

The initial mapper transaction failed its group-order assertion and rolled back. The successful transaction refreshed metadata cache for only the two scoped mappers using Salesforce's Connect API, then passed native assertions for Q-37912 before committing. This was an authorized configuration-record deployment; it was not a Metadata API deployment job.

## Post-deployment verification

**236 of 236 checks passed across eight fresh native Extract/Transform runs and independent read-back.**

An additional **40 native synthetic formula cases passed** for grouped and ungrouped descriptions, covering missing description/rate values and New, Renewal, Cancellation, Quantity Increase, and Quantity Reduction types. This test created no business records. Evidence: [native formula test result](native-formula-test-result.json).

- Q-37912 now returns Group4, Group1, Group2, Group3, with group terms 36, 12, 12, 12.
- All eight scenarios' product output matches captured eligible source product order and multiplicities. The outputs contain 153 eligible product rows in total.
- Description output was checked for every eligible row against its source description, Rate Details, and applicable line-type label.
- Ship-To flags and grouped/ungrouped conditions passed.
- Four mapper records were added, the two expected formulas match the prepared changes, and the other 162 mapper records are unchanged.
- The template remains active and references the uploaded version.

The source baseline comprises 155 quote lines; the two Amendment lines on Q-38029 are excluded. Matching product multiplicities is not an identity-level duplicate-substitution proof because the document payload does not contain quote-line record IDs.

## Remaining business checks

The browser reached Salesforce's password sign-in page, so a freshly generated document was not visually verified in Salesforce. Confirm sequential Term numbering survives group repetition, starts at Term 1 in each document, and shows no dates. Confirm final page/table layout and column visibility using the [test steps](test-steps.md).

Ten groups across Q-37723 and Q-37780 lack subscription terms. Their data was not edited. They remain useful for structure, Rate Details, and Ship-To tests, but not a complete XX Months heading acceptance test. Q-38029 covers amendment exclusion only; positive amendment document output needs a suitable separate case.

## Evidence and recovery

- [Post-deployment results](verification-results.json)
- [Applied mapper receipt](applied-mapper-receipt.json)
- [Template upload receipt](template-upload-receipt.json)
- [Before mapper configuration](before-mapper-items.json)
- [Before template link](before-template-links.json)
- [Before template file](before-template.docx)

If a regression is found, recovery should be limited to the two recorded before-formulas, four created mapper records, and this template content version. The prior template bytes are backed up locally and the prior Salesforce version is retained. Any recovery must refresh these two mapper metadata caches and rerun the focused scenarios; do not restore unrelated historical components.

Salesforce documents the scoped cache operation in [Improving Data Mapper Performance with Caching](https://help.salesforce.com/s/articleView?id=sf.os_cache_for_dataraptors_and_integration_procedures_48057.htm&language=en_US&type=5).
