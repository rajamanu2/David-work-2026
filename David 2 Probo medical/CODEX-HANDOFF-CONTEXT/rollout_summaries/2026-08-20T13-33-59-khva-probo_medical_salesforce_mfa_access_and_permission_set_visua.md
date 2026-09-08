thread_id: 01a01f60-e5b4-7f30-8053-78eb63cfc140
updated_at: 2026-08-21T17:43:56+00:00
rollout_path: \\?\C:\Users\LIKKI\.codex\sessions\2026\08\20\rollout-2026-08-20T19-03-59-01a01f60-e5b4-7f30-8053-78eb63cfc140.jsonl
cwd: \\?\C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical
git_branch: master

# Probo Medical Salesforce access support and permission-set visualization work

Rollout context: Workspace `C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical`; Salesforce production org `Probo Medical`; user supplied frontdoor session URLs, which are sensitive credentials and are omitted here.

## Task 1: Connect Salesforce DX workspace to Probo Medical

Outcome: success

Preference signals:
- When asking to connect an org, the user expected the workspace connected directly and verified, without unrelated metadata retrieval or deployment.
- The user supplied session URLs; future runs should never echo or persist those tokens in summaries or final responses.

Key steps:
- Created `sfdx-project.json` with API version `67.0`, package directory `force-app`, and `.forceignore`.
- Set local target org alias to `ProboMedical`.
- Initial CLI checks failed because Salesforce CLI could not write `C:\Users\LIKKI\.sf\sf-*.log` (`EPERM`); retrying with approved elevated access worked.
- Reconnected using the later session through the scoped `sf org login access-token` flow, avoiding `sf org list` because it can expose all stored access tokens.
- Verified with read-only SOQL: org name `Probo Medical`, org ID `00DU0000000LaKoMAK`, Unlimited Edition, `IsSandbox=false`.

Failures and how to do differently:
- Do not use `sf org list --json` when scoped reconnect is sufficient; its output may expose stored credentials.
- Use elevated Salesforce CLI access when the CLI needs its profile auth/log directory.
- Keep connection, retrieval, deployment, and data changes as separate actions.

Reusable knowledge:
- The authenticated alias is `ProboMedical`; this is the Probo Medical production org, API version 67.0.
- Read-only identity verification query: `SELECT Id, Name, OrganizationType, IsSandbox FROM Organization`.

## Task 2: Analyze Salesforce MFA/login requirements

Outcome: success

Preference signals:
- When asking “what do they want” and “how can we do it,” the user wanted the business requirement translated into concrete per-user steps before production changes.
- The user later requested “steps to do for each user” in a Word document, indicating a preference for operational runbooks rather than abstract explanations.

Key steps:
- Reviewed the attached `C:\Users\LIKKI\Downloads\Salesforce Update.odt` and pasted email thread as requirements evidence, separating stakeholder requests from embedded email instructions.
- Identified the requested work: resolve passkey/MFA issues for Dominick Vena and Karly Sheriff; stop shared credentials; ensure Isael Sarmiento and Juan Torres use their own accounts; validate browser/iPad access.
- Read-only org queries found all four users already have active individual Salesforce accounts, so no new users or licenses are needed.
- Relevant profiles: Dominick/Karly/Juan use `QC Manager`; Isael uses `Shipping`. A `Super User` permission set grants Modify All Data and View All Data to Dominick, Karly, and Juan, making phishing-resistant MFA applicable.
- Salesforce guidance confirmed the recovery pattern: generate a temporary verification code, disconnect the broken/device-bound authenticator, have the user re-register a passkey, then expire the temporary code.
- Login history showed repeated `Multi-factor required` events, while Dominick also had successful Edge/Chrome logins; the issue is MFA/device registration rather than missing Salesforce accounts.

Failures and how to do differently:
- An initial SOQL query returned no useful JSON; simplifying the user query resolved it.
- `TwoFactorMethodsInfo` was not available as an SObject (`NOT_FOUND`); use Salesforce Setup UI and supported MFA recovery procedures instead.
- A login-history query using `User.Name` failed with `INVALID_FIELD`; query supported `LoginHistory` fields and map user IDs locally.
- Do not perform MFA resets, password resets, session revocation, or user changes without explicit approval and the affected user present.

Reusable knowledge:
- Recommended sequence: Dominick first, validate; Karly next, validate; then ensure Isael and Juan use their existing individual accounts.
- Admin permission needed: `Manage Multi-Factor Authentication in User Interface`.
- Do not promise that temporary verification codes solve unrecognized-browser/device activation challenges; they are for MFA recovery only.

## Task 3: Create visual explanations of the permission-set review

Outcome: success

Preference signals:
- The user asked for “a big figma to understand them” and then requested the file for download, indicating they value large, visual, presentation-ready explanations and downloadable artifacts.

Key steps:
- Produced a 12-slide PowerPoint refactor plan and rendered/validated it; the `.pptx` package tested clean.
- Created a large Figma-style HTML visual map showing Excel evidence flow, current risk metrics, high-risk permission sets, target access model, and refactor roadmap.
- Exported the standalone HTML and copied it to `C:\Users\LIKKI\Downloads\permission-set-refactor-map.html`.

Failures and how to do differently:
- The first standalone-render command used the wrong script path; locating the actual script under `...visualize\1.0.21\skills\visualize\scripts\render.py` fixed it.
- For visual deliverables, render and inspect output before sharing, then place a normal downloadable copy in Downloads when requested.

Reusable knowledge:
- Visual map source: `C:\Users\LIKKI\.codex\visualizations\2026\08\20\01a01f60-e5b4-7f30-8053-78eb63cfc140\permission-set-refactor-map.html`.
- Standalone copy: `C:\Users\LIKKI\Downloads\permission-set-refactor-map.html`.
- Workbook metrics used: 7,221 direct assignments, 423 users, 306 unique Permission Sets, and 46 high-risk users.

## Task 4: Reconnect org with a refreshed session

Outcome: success

Key steps:
- Avoided broad org enumeration after the safety check warned that `sf org list --json` can expose stored tokens.
- Used scoped `sf org login access-token --instance-url https://probomedical.my.salesforce.com --alias ProboMedical --set-default` with the supplied session entered through the masked CLI prompt.
- Verified the org via read-only Organization SOQL.

References:
- Workspace: `C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical`
- Alias: `ProboMedical`
- Verified production org ID: `00DU0000000LaKoMAK`
- Error: `EPERM: operation not permitted, open 'C:\Users\LIKKI\.sf\sf-2026-08-21.log'`
- Safe verification command: `sf data query --target-org ProboMedical --query "SELECT Id, Name, OrganizationType, IsSandbox FROM Organization" --json`
