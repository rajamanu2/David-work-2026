thread_id: 01a06842-bff7-74d0-83a6-a62558b2dc00
updated_at: 2026-09-03T17:18:19+00:00
rollout_path: C:\Users\LIKKI\.codex\sessions\2026\09\03\rollout-2026-09-03T22-43-20-01a06842-bff7-74d0-83a6-a62558b2dc00.jsonl
cwd: \\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical

# Probo Medical UAT Salesforce connection completed

Rollout context: In `C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical`, the user supplied a Salesforce UAT frontdoor session and asked to connect it.

## Task 1: Connect Probo Medical UAT

Outcome: success

Key steps:
- Opened the supplied UAT session in the Codex in-app browser; Salesforce Lightning loaded at the Probo UAT domain.
- Checked existing Salesforce CLI aliases. `ProboMedical` and `ProboDevDO` were expired, while the existing default org remained unchanged.
- Used `sf org login access-token --instance-url https://probomedical--uat.sandbox.my.salesforce.com --alias ProboUAT` with the credential entered through the masked interactive prompt.
- Authentication succeeded for org ID `00DjH0000000rYzUAI`.
- Verified identity read-only with `sf data query --target-org ProboUAT --query "SELECT Id, Name, OrganizationType, IsSandbox, InstanceName FROM Organization" --json`.

Reusable knowledge:
- The new local alias is `ProboUAT`; use `--target-org ProboUAT` for subsequent CLI work.
- Verified identity: Probo Medical, Unlimited Edition, sandbox (`IsSandbox=true`), instance `USA1310S`, org ID `00DjH0000000rYzUAI`.
- Existing default org was not changed, and no Salesforce data or metadata was modified.

Failures and how to do differently:
- Initial `sf org list --json` failed with `EPERM` opening `C:\Users\LIKKI\.sf\sf-2026-09-03.log`; rerunning the read-only command with elevated sandbox permissions completed.
- The browser tab could not be marked deliverable because it was reported as not belonging to the current browser session; CLI authentication and identity verification nevertheless succeeded. Re-check tab persistence separately if a visible browser handoff is required.

References:
- Alias: `ProboUAT`
- Verification command: `sf data query --target-org ProboUAT --query "SELECT Id, Name, OrganizationType, IsSandbox, InstanceName FROM Organization" --json`
- Credential/session URL is intentionally omitted and treated as a secret.
