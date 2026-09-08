thread_id: 01a0448f-b752-7a30-831f-c3dd43565fab
updated_at: 2026-08-28T16:48:22+00:00
rollout_path: \\?\C:\Users\LIKKI\.codex\sessions\2026\08\28\rollout-2026-08-28T00-21-04-01a0448f-b752-7a30-831f-c3dd43565fab.jsonl
cwd: \\?\C:\Users\LIKKI\Documents\ChatGPT\david
git_branch: master

# Salesforce FlywirePartial connection and SALDEV-1469 Gong ECA verification

Rollout context: Work occurred in `C:\Users\LIKKI\Documents\ChatGPT\david` using PowerShell and Salesforce CLI.

## Task 1: Reconnect FlywirePartial sandbox

Outcome: success

Key steps:
- Preserved the existing `FlywirePartial` alias and project default-org configuration.
- Used masked `sf org login access-token` authentication rather than browser OAuth.
- Verified with a read-only Organization query.

Reusable knowledge:
- `FlywirePartial` is the intended sandbox alias.
- The project uses `force-app`, Salesforce DX API `67.0`, and `https://test.salesforce.com`.
- CLI log access may require elevated permissions because `C:\Users\LIKKI\.sf\sf-*.log` can produce `EPERM`.
- Never expose or retain Salesforce access tokens or frontdoor/session URLs.

## Task 2: SALDEV-1469 Gong integration dry run

Outcome: success

Preference signals:
- The user asked to “dry run this” and the assistant correctly treated it as no-change inspection; future similar work should stop before installation, authorization, deployment, or permission changes.
- The user wanted a detailed guide that could be sent to David; future deliverables should clearly distinguish confirmed facts, pending screen-share checks, stop conditions, and production exclusions.

Key steps:
- Inspected the sandbox user, permission-set assignments, connected apps, metadata, OAuth token state, installed packages, and relevant local metadata.
- Found the Gong integration user as `ada+gong@flywire.com.partial`, active, with API access through the profile and `Gong_Integration` assigned.
- Confirmed `Gong_Integration` grants read/View All access only for Account, Contact, Lead, Opportunity, and `Opportunity_History2__c`, with no create/edit/delete/modify-all permissions.
- Initially found no Gong ECA package in the dry-run state and no Gong OAuth grant; public Gong documentation identified package `0337y000005iObdAAE`, namespace `gongeca`, version `0.1`, identity-only scopes, PKCE, token rotation, and refresh-token IP allowlisting as relevant requirements.
- Produced `flywire-docgen\deliverables\SALDEV-1469_Gong_ECA_Verification_Runbook.docx` with sandbox verification, authorization checkpoints, acceptance criteria, troubleshooting, ownership, and copy-paste Zoom/Jira messages.
- Document QA found no high-severity issues; it was rendered and visually reviewed. It contained no frontdoor token or unrelated OmniStudio content. Structural audits noted eight unmarked table-header rows and raw-URL hyperlink display text.

## Task 3: Verify current package and prepare David handoff

Outcome: success

Key steps:
- Read-only org display confirmed the connected `FlywirePartial` sandbox identity and alias.
- Retrieved the complete installed-package list locally because Salesforce rejects filtering `InstalledSubscriberPackage` by related `NamespacePrefix`; identified `Gong ECA`, package ID `0337y000005iObdAAE`, namespace `gongeca`, version `0.1.0`, build `2`.
- Final guidance correctly states: do not reinstall; screen-share verification should confirm the package, select Sign in with Salesforce against the Partial sandbox, stop at the authorization page for review, and stop on wrong org, unexpected scopes, reconnect prompts, package changes, or OAuth errors.

Failures and how to do differently:
- Plain `sf org display --json` hit `EPERM` on the Salesforce log file; rerun with elevated permissions.
- Queries against `InstalledSubscriberPackage` failed when filtering related package fields (`INVALID_FIELD`); retrieve all installed packages and inspect locally instead.
- Do not claim OAuth authorization or successful Gong login until David performs the interactive test; those items remained pending.

References:
- Verification query: `sf data query --target-org FlywirePartial --query "SELECT Id, Name, OrganizationType, IsSandbox, InstanceName FROM Organization" --json`
- Package verification: `sf data query --target-org FlywirePartial --use-tooling-api --query "SELECT Id, SubscriberPackage.Name, SubscriberPackage.NamespacePrefix, SubscriberPackageVersion.MajorVersion, SubscriberPackageVersion.MinorVersion, SubscriberPackageVersion.PatchVersion, SubscriberPackageVersion.BuildNumber FROM InstalledSubscriberPackage" --json`
- Runbook: `C:\Users\LIKKI\Documents\ChatGPT\david\flywire-docgen\deliverables\SALDEV-1469_Gong_ECA_Verification_Runbook.docx`
- Org evidence: ID `00DhG0000000jOXUAY`, Enterprise Edition sandbox, instance `USA1148S`.
- Official Gong guidance: `https://help.gong.io/docs/about-the-salesforce-external-client-app`
