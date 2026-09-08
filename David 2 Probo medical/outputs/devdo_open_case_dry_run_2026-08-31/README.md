# Probo DevDO Open-Case Dry Run

Generated: 2026-08-31

## Decision

Proceed in `ProboDevDO` only after approval and only in small case groups. The sandbox is suitable for building or reproducing 85 of the 113 active open cases once representative sanitized test data and the correct test personas are available. It is not sufficient by itself to complete every case.

This was a read-only feasibility and dependency scan. No Salesforce records, metadata, assignments, activations, deployments, or test data were changed.

## Verified target

- Alias: `ProboDevDO`
- Organization: Probo Medical
- Org ID: `00DiK0000001co1UAA`
- Environment: Sandbox (`IsSandbox = true`)
- Instance: `USA1220S`

## Readiness summary

| Readiness | Cases | Recommendation |
|---|---:|---|
| Buildable after representative test data | 43 | Build in Dev, test, then request separate deployment approval |
| Reproducible after sanitized records and exact steps | 22 | Reproduce and confirm root cause in Dev before proposing a fix |
| Access/persona cases | 11 | Confirm exact user persona and least-privilege acceptance criteria first |
| Reports/dashboards/notifications | 9 | Build in Dev with representative data and folder-sharing personas |
| Managed package/integration | 14 | Partial Dev work only; require sandbox-safe endpoint and sometimes vendor support |
| Data correction/migration | 8 | Rehearse in Dev; production data update requires separate approval and read-back |
| Missing target/acceptance criteria | 6 | Do not begin until requirements are clarified |

Dev-buildable/reproducible subtotal: **85**. Every one of these 85 still needs suitable test records or a test persona before implementation validation.

## Work type summary

| Work type | Cases |
|---|---:|
| Metadata configuration / automation | 43 |
| Defect investigation | 22 |
| Integration / managed package | 14 |
| Access / validation | 11 |
| Reports / dashboards / notifications | 9 |
| Data correction / migration | 8 |
| Clarification / cross-object | 6 |

## High-priority cases to start first after approval

1. **00008361 — FSL calendar appointment delay.** Reproduce using two Service Appointments for the same engineer/day and inspect Assigned Resource, Service Appointment, calendar Event, and dispatch automation timing.
2. **00009312 — Service Appointment details in FSL.** Validate the mobile/dispatcher layout or card behavior and confirm which Service Appointment fields must replace the Work Order details.
3. **00009704 — completed Work Order reopened when RMA completed.** Reproduce the RMA completion transition and trace RMA/Work Order Flows and Work Order triggers. Assert that a completed Work Order remains completed.
4. **00010409 — New Service Appointment button.** Confirm the expected field mappings, action location, record type, and persona; assess reuse of the existing Service Appointment creation Flow.

These are candidate investigation paths, not confirmed root causes.

## Cases that cannot be completed solely in Dev

### Integration or managed package — 14

`00009302`, `00009580`, `00009614`, `00009663`, `00009845`, `00009873`, `00009874`, `00009875`, `00009876`, `00009944`, `00010019`, `00010078`, `00010264`, `00010500`

Use sandbox credentials/endpoints only. Do not invoke production Avalara, Intacct, PandaDoc, Zenkraft, Outlook, or other external endpoints during sandbox testing.

### Production data action after Dev rehearsal — 8

`00009343`, `00009797`, `00010166`, `00010216`, `00010341`, `00010377`, `00010414`, `00010517`

### Requirements blocked — 6

`00009455`, `00009584`, `00009763`, `00010086`, `00010381`, `00010489`

These six need the target object, triggering event, recipients or affected persona, and measurable expected result before any build begins.

## Dev prerequisites

1. Create sanitized representative records in DevDO; the sandbox currently has no representative Case records for these production examples.
2. Confirm the exact persona/profile/permission sets for access and UI cases.
3. Confirm acceptance criteria and reproducible steps for each selected case.
4. For integrations, confirm a sandbox-safe credential/endpoint and vendor test plan.
5. Work in small bundles, starting with the four high-priority cases; run focused regression tests and obtain approval before any production deployment or data action.

## Evidence files

- `case_devdo_dry_run.csv` — one row per active open case with readiness, targets, candidate components, test-data prerequisites, and eventual production-write classification.
- `summary.json` — verified counts and readiness totals.
- `inventory/` — read-only DevDO metadata inventories used by the analysis.

