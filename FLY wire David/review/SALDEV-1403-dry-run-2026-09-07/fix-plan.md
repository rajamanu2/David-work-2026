# SALDEV 1403 prepared fix

Status: prepared locally for review. No deployment, activation, Salesforce record update, or template upload is authorized by this plan.

## Exact changes

| Component | Prepared change | Purpose |
| --- | --- | --- |
| GetQuoteProposalDataSteppedUpPricing | Add group ORDER BY: `SBQQ__StartDate__c ASC NULLS LAST, SBQQ__SubscriptionTerm__c DESC NULLS LAST, SBQQ__Number__c ASC` | Chronological groups, longest term first when dates match |
| GetQuoteProposalDataSteppedUpPricing | Add grouped quote-line ORDER BY: `SBQQ__Number__c ASC` | Preserve QLE product and bundle order |
| GetQuoteProposalDataSteppedUpPricing | Add ungrouped quote-line ORDER BY: `SBQQ__Number__c ASC` | Correct mixed bundle/standalone and renewal ordering |
| GetQuoteProposalDataSteppedUpPricing | Map `SBQuote:QuoteLineGroup:SBQQ__SubscriptionTerm__c` to `QuoteLineGroup:SubscriptionTerm` | Supply the group term, rather than the product subscription term |
| CPQQuoteProposalDocumentSteppedUpPricing | Replace grouped Description formula on item `0kdhG0000002nUTQAY` | Append Rate Details with null-safe spacing and retain applicable line-type labels |
| CPQQuoteProposalDocumentSteppedUpPricing | Replace ungrouped Description formula on item `0kdhG0000002m5NQAQ` | Apply the same formatting behavior to ungrouped quotes |
| CPQ Quote Proposal DOCX | Replace both grouped headings with sequential Term numbering and `{{SubscriptionTerm}} Months`; remove service-period paragraphs | Meet the latest screenshot clarification |

The exact before/after formulas, existing item identifiers, and new item definitions are in [mapper-change-spec.json](candidate/mapper-change-spec.json). Four new mapper items and two existing formula changes are prepared. No Apex, custom field, or OmniScript change is currently proposed.

The [candidate template](<candidate/CPQ Quote Proposal - SALDEV-1403 - dry-run.docx>) preserves the original tables, grouped/ungrouped sections, Ship-To conditions, and signature content. The existing whole-group mapping and amendment-line filters remain in place.

## Expected result on the reported quote

For Q-37912, group order changes from Group3, Group1, Group2, Group4 to Group4, Group1, Group2, Group3. The document should show:

1. Term 1: 36 Months
2. Term 2: 12 Months
3. Term 3: 12 Months
4. Term 4: 12 Months

No service dates should appear in those headings. Products should retain their QLE order within each group, with bundle children below their parent.

## Evidence already available

The preceding dry run executed eight current-configuration scenarios without mapper runtime errors and completed 55 automated checks. It reproduced ordering defects, tested the exact proposed group sort through read-only SOQL, checked candidate formulas locally, and verified unchanged mapper configuration after the run. Both candidate-template pages were visually inspected after Word rendering. Full evidence is in [dry-run-report.md](dry-run-report.md).

Those results validate the recorded baseline and local candidate checks. They do not establish native execution of the proposed changes.

## Remaining validation before readiness

- Confirm that the native Data Mapper engine accepts and executes the proposed sorting rules and formulas. These records were not exposed by the sandbox Metadata API, so no check-only deployment pass is available.
- Confirm sequential Word numbering survives native DocGen group repetition and conditional branch removal. Each generated document must start at Term 1. This is a candidate approach, not yet a confirmed native solution; if unsupported, a document-payload ordinal must be designed and validated.
- Use grouped test data with subscription terms. Ten groups across Q-37723 and Q-37780 lack them. Do not invent values or silently substitute a product term.
- Verify generated output across grouped/ungrouped, Ship-To Yes/No, new/renewal, and positive amendment scenarios. Q-38029 currently verifies amendment exclusion only. Use Q-38009 and Q-38023 for ungrouped regression; Q-37640 is now grouped.

Current readiness: local changes prepared; native candidate validation and generated-document acceptance pending. Keep deployment and activation on hold.
