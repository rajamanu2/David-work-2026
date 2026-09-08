# Probo Medical Case Story Dry Run

Generated: 2026-08-31  
Target alias: `ProboMedical`  
Verified organization: Probo Medical (`00DU0000000LaKoMAK`)  
Environment: Production (`IsSandbox=false`)  
Mode: Read-only retrieval and analysis; no Salesforce records, permissions, metadata, automation, or configuration were changed.

## Scope and result

- Workbook-scoped unique case numbers: 139
- Production Case matches: 139
- Missing Case records: 0
- Open production Cases: 116
- Closed production Cases: 23
- Case history records: 407
- Feed items: 228
- Feed comments: 48
- Linked files downloaded: 6
- File validation: all six downloads match Salesforce ContentVersion size and MD5 checksum

## Dry-run reconciliation

- 113 active-workbook Cases are open in Salesforce and ready for detailed requirements analysis.
- 19 active-workbook Cases are already closed in Salesforce and require status/scope reconciliation before work.
- 4 workbook-complete Cases are also closed in Salesforce and should be excluded.
- 3 workbook-complete Cases remain open in Salesforce and require owner confirmation before exclusion or closure.

### Active workbook rows already closed in Salesforce

`00009336`, `00009338`, `00009345`, `00009377`, `00009393`, `00009706`, `00010063`, `00010097`, `00010179`, `00010202`, `00010263`, `00010331`, `00010387`, `00010390`, `00010393`, `00010510`, `00010538`, `00010541`, `00010542`

### Workbook-complete rows still open in Salesforce

`00010129`, `00010303`, `00010304`

### Workbook-complete rows closed in Salesforce

`00009449`, `00009914`, `00010147`, `00010281`

## Files

- `cases_all_fields.json`: all readable Case fields for the 139 scoped records.
- `cases_analysis_fields.json`: normalized Case, owner, classification, affected-object, description, and lifecycle fields.
- `case_dry_run_index.csv`: one reconciled row per workbook Case number, including workbook source, production state, evidence counts, and dry-run disposition.
- `summary.json`: aggregate counts, statuses, themes, owners, and evidence totals.
- `related/`: Case history, feed, comments, email, file-link metadata, activities, contacts, team, and milestone exports.
- `files/`: six Salesforce-linked files downloaded from ContentVersion.

## Implementation gate

This retrieval does not authorize implementation. Validate the 22 status exceptions first, then analyze the remaining 113 open Cases by classification, related object, dependencies, acceptance criteria, and current metadata behavior before proposing changes.
