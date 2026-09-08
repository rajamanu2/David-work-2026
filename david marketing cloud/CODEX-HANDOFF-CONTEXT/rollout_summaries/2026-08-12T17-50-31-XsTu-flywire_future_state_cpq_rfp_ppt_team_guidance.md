thread_id: 019ff718-e4ef-7782-ad11-860171944908
updated_at: 2026-08-24T18:18:52+00:00
rollout_path: \\?\C:\Users\LIKKI\.codex\sessions\2026\08\12\rollout-2026-08-12T23-20-31-019ff718-e4ef-7782-ad11-860171944908.jsonl
cwd: \\?\C:\Users\LIKKI\Documents\ChatGPT\david
git_branch: master

# Flywire Salesforce future-state, CPQ RFP, and team messaging analysis

Rollout context: In `C:\Users\LIKKI\Documents\ChatGPT\david`, the agent retrieved FlywirePartial Salesforce metadata, scanned a 58-page Future State Vision PDF and `CPQ RFP.xlsx`, compared both against the org, and drafted guidance on how to present the PPT to David. Work was read-only; no Salesforce changes or deployments were made.

## Task 1: Retrieve FlywirePartial metadata

Outcome: partial

Key steps:
- Identified `FlywirePartial` as the matching connected sandbox and avoided the unrelated default org.
- Created a Salesforce DX project using API 67.0 with source at `force-app/main/default`.
- Generated a broad manifest containing 102 metadata types and 21,868 members.
- Worked around Salesforce’s 10,000-file retrieve limit by splitting into ten manifests capped at 2,500 members.
- Retrieved nine batches successfully, then retrieved batch 1 excluding the malformed `ContentAsset` type.

Reusable knowledge:
- The workspace contains 32,349 retrieved files, approximately 136 MB, including 94 Apex classes, 11 LWC bundles, 3 Aura bundles, 258 objects, and 11,212 reports.
- Salesforce could not retrieve 121 ContentAsset components because `Info8` lacked its required source file.
- Helper scripts are available at `scripts/Split-SalesforceManifest.ps1` and `scripts/Retrieve-SalesforceMetadata.ps1`.
- Salesforce CLI may require elevated execution because of `.sf` logging `EPERM`; PowerShell helper scripts require `ExecutionPolicy Bypass`.

Failures and how to do differently:
- A single broad retrieve failed with `LIMIT_EXCEEDED: Too many files in retrieve call, limit is: 10000`; always chunk large manifests.
- One chunk failed with `Expected source files for type 'ContentAsset'`; isolate or exclude the malformed ContentAsset type and report the omission explicitly.

## Task 2: Assess Future State Vision against Salesforce org

Outcome: success

Key findings:
- The model is technically viable but must be implemented as controlled modernization, not a clean rebuild or big-bang replacement.
- Existing org inventory included 954 quotes, 7,653 quote lines, 438 products, 4,111 contracts, 3,011 orders, 1,990 subscriptions, 85 active CPQ price rules, 17 active approval rules, 116 active flows, 101 unmanaged Apex classes, six unmanaged triggers, and 22% org-wide Apex coverage.
- Reusable foundations include Salesforce CPQ, Advanced Approvals, OmniStudio proposal generation, quote/contract/order/subscription records, contract renewal/amendment automation, and migration external IDs.
- Major gaps are governed ARR/revenue calculation, physical tier/ramp pricing design, full CLM capabilities, resilient integration controls, partner/Experience Cloud quoting, global localization, and test readiness.
- The deck should not claim production readiness while Apex coverage remains 22%.

## Task 3: Scan and compare CPQ RFP workbook

Outcome: success

Key findings:
- The RFP confirms requirements for native bidirectional Salesforce sync, API efficiency, multi-currency/localization, security and compliance, ERP/billing/tax integration, guided selling, nested bundles, fintech pricing, partner margins, amendments/renewals, dynamic documents, multi-tier approvals, Experience Cloud partner quoting, and deal registration.
- Explicit operational targets include 99.9% production availability, p95 quote save/update <=3 seconds, pricing API p95 <=2 seconds, API errors <0.1%, automated retries, no manual transaction reconstruction, RTO <=4 hours, P1 response <=15 minutes, P1 workaround <=2 hours, and P1 restoration <=4 hours.
- The workbook is still draft: blank Presentation Criteria, unresolved budget/OKRs, incomplete requirement questions, unverified vendor research, and no weighted scoring model. Its formulas only generate question numbers; no formula errors were found.
- The RFP mentions approximately 3,000 products, two price books per product, subscription/standalone products, nested bundles, and multi-year stepped-up pricing; the sandbox’s 438 Product records require reconciliation and scale testing.
- The organization currently integrates with NetSuite and expects movement toward Workday, so the target architecture should remain ERP-neutral and include tax integration considerations.

## Task 4: Advise whether/how to present the PPT

Outcome: success

Preference signals:
- When the user asked what to say to David, the response provided a ready-to-send message rather than only analysis -> for similar requests, give concise copy-paste wording.
- The guidance consistently distinguishes a proposed design from an approved production solution -> future stakeholder messaging should clearly state validation status, open decisions, risks, and next steps.

Recommended message framing:
- The PPT is technically viable and suitable for a technical workshop and detailed-design approval.
- It should be described as a proposed implementation/go-live design, not a final approved production baseline.
- Before final approval, confirm vendor/platform choice, ARR consolidation, tier/ramp pricing, CLM scope, Workday/ERP/billing/tax integration, partner quoting, global localization, SLAs/security/DR, migration/rollback controls, and test remediation.
- Recommend a controlled pilot-first rollout rather than big-bang go-live.

References:
- DX project: `C:\Users\LIKKI\Documents\ChatGPT\david\force-app\main\default`
- Manifest: `manifest/package.xml`
- Source PDF: `C:\Users\LIKKI\Downloads\Flywire Future State Vision_20260814 (1).pdf`
- Source workbook: `C:\Users\LIKKI\Downloads\CPQ RFP.xlsx`
- PPT referenced for team discussion: `output/presentations/Flywire_Build_and_Go_Live_Implementation_Package.pptx`
