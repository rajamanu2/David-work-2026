# SALDEV 1403 dry run and local candidate

Date: 7 September 2026. Target: FlywirePartial, Flywire sandbox, org ID `00DhG0000000jOXUAY`.

**Result: the read-only baseline reproduced outstanding defects. Local corrections are prepared, but the candidate has not passed native integration validation and is not ready for deployment approval. Nothing was deployed, activated, uploaded, or changed in Salesforce business/configuration records.**

## Changes prepared locally

The candidate is based on a fresh download of the currently linked proposal file, not on an assumed historical version.

1. Replace both grouped section headings with sequential `Term n: XX Months` headings. Read XX from the group's subscription term. Remove both service-period paragraphs. Dates remain available in data for sorting.
2. Add an Extract sorting rule for groups: Start Date ascending, then Subscription Term descending, then quote group Number ascending. Put missing dates/terms last. The exact SOQL expression was successfully executed read-only against Q-37912.
3. Add Extract sorting rules for grouped and ungrouped quote lines using `SBQQ__Number__c ASC`, preserving QLE order and bundle subtrees in the captured test data.
4. Add the group Subscription Term output mapping; the current payload has product subscription terms but lacks the group-level value required for the heading.
5. Make both Description formulas null-safe, append Rate Details, and retain Cancellation, Quantity Increase, and Quantity Reduction labels. Forty local evaluations of the actual candidate formulas cover missing descriptions/rates and those line types.

The change specification contains four new mapper items and two guarded formula updates. It preserves the whole-group mapping, existing disabled fan-out mappings, amendment exclusion filters, Ship-To conditions, all original product/signature tables, and ungrouped conditional sections. SALDEV-1420 and the historical experimental Apex serializer remain excluded.

Files:

- [Local candidate proposal template](<candidate/CPQ Quote Proposal - SALDEV-1403 - dry-run.docx>)
- [Guarded mapper change specification](candidate/mapper-change-spec.json)
- [Validation results](validation-results.json)
- [Native baseline comparison](native-baseline-findings.json)

The JSON is a reviewable change specification, not an import-ready deployment package. It intentionally includes no write/apply script.

## Fresh findings

Q-37912 currently returns groups as **Group3, Group1, Group2, Group4**. The required order for its dates and terms is **Group4, Group1, Group2, Group3**, yielding:

- Term 1: 36 Months
- Term 2: 12 Months
- Term 3: 12 Months
- Term 4: 12 Months

No explicit ORDER BY rules were found in the 164 captured mapper items. Current native output also differs from QLE line order on Q-37640, Q-37912, Q-37780, and Q-38021. Sorting the 155 captured source lines by QLE Number preserves the bundle subtrees in these fixtures, including nested bundle children.

The current template still contains `{{Name}}` and `Service Period: {{StartDate}} to {{EndDate}}` in both grouped branches. That conflicts with the later screenshot clarification to remove dates and show Term headings.

## Executed baseline scenarios

All eight read-only Extract/Transform executions compiled and completed without mapper errors. These runs used the unchanged current configuration, not the candidate.

| Quote | Current scenario | Output product lines | Current line order matches QLE |
| --- | --- | ---: | --- |
| Q-37640 | Grouped, Ship-To No | 12 | No |
| Q-37912 | Grouped, Ship-To No; reported defect | 78 | No |
| Q-37723 | Grouped renewal, Ship-To Yes | 14 | Yes |
| Q-37780 | Grouped, Ship-To No | 18 | No |
| Q-38009 | Ungrouped new quote, Ship-To Yes | 9 | Yes |
| Q-38023 | Ungrouped new quote, Ship-To No | 2 | Yes |
| Q-38021 | Ungrouped renewal, Ship-To No | 20 | No |
| Q-38029 | Ungrouped amendment, Ship-To No | 0 | Not applicable; amendment lines excluded |

Product-name multiplicities and counts matched the eligible source records within each group/ungrouped section. The payload lacks quote-line record IDs, so this is not an identity-level proof against duplicate substitutions. Q-38029 covers exclusion only; positive amendment-label behavior was checked locally with synthetic formula cases.

Q-37640 is now grouped and must no longer be described as the ordinary ungrouped regression case. Q-38009 and Q-38023 are the replacement ungrouped cases. Ten groups across Q-37723 and Q-37780 have no group subscription term; these remain useful for structure and Ship-To testing but cannot pass the XX Months heading requirement without suitable term data. No data was fabricated or edited.

## Verification and limitations

**55 of 55 automated checks passed.** These cover current-runtime errors/flags, no DML in baseline logs, local candidate structure/scope, exact formula evaluations, source-data ordering, the live SOQL sort, template sections/tables, and post-run state checks. A pass here does not mean the story's business acceptance criteria passed.

Independent read-back confirmed all 164 mapper items unchanged, the template configuration unchanged, and the existing stepped-up OmniScript still active at version 2. No activation command was run. The current template's content link still identifies the same downloaded content version.

The candidate DOCX was exported through Word and both rendered pages were visually inspected. The heading was adjusted to stay with its following table. This verifies the local token template layout, not Salesforce-generated quote output.

The scoped Metadata API retrieval returned component-not-found messages for both mappers and the template. Metadata listings for OmniDataTransform and DocumentTemplate were empty, although the corresponding records were accessible through the data API. Therefore no meaningful Metadata API check-only package could be submitted. The retrieve job's top-level `Succeeded` status must not be interpreted as successful component retrieval; its three component results are failures. The reason these records are not exposed was not established, and no org setting was changed.

Native execution of the proposed mapper changes remains unverified. In particular, acceptance of the mapper ORDER BY configuration and FormulaExpression changes cannot be inferred solely from SOQL/local formula tests. They require a supported native preview/check-only mechanism or a separately authorized isolated implementation.

The candidate uses Word decimal numbering for the sequential Term ordinal, avoiding reuse of quote group Number after sorting. Word renders that numbering correctly in the local template. Salesforce DocGen must still be checked to confirm numbering is preserved when group paragraphs repeat and the inactive Ship-To branch is removed; each generated quote must restart at Term 1. If that engine behavior is not supported, an explicitly generated ordinal in the document payload will be needed. That additional integration has not been introduced or assumed to work.

## Updated handoff expectations

This report supersedes the old handoff's service-date verification instructions and its Q-37640 ungrouped test assignment. The historical handoff is preserved.

For the eventual native candidate test, inspect the generated document for Q-37912 first: Term 1 must be 36 Months, the remaining terms must be 12 Months, and no group service dates may appear. Then verify all eight scenarios above, correct product placement, bundle adjacency, no repeated lines, Rate Details formatting, and Ship-To visibility. Add suitable nonblank-term grouped examples for the full heading matrix and a positive amendment scenario. Generated-document UAT and deployment approval remain pending.

The read-only data export route is documented by Salesforce in [Export or Import an Omnistudio Data Mapper](https://help.salesforce.com/s/articleView?id=xcloud.os_export_or_import_an_omnistudio_data_mapper.htm&language=en_US&type=5). Salesforce also documents [enabling OmniStudio Metadata API support](https://help.salesforce.com/s/articleView?id=sf.os_enable_omnistudio_metadata_api_support.htm&language=en_US); that setting was not modified in this run.
