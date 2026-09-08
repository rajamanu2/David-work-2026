import json
from collections import Counter, defaultdict
from pathlib import Path

base_dir = Path(r"C:\Users\LIKKI\Documents\ChatGPT\David 2 Probo medical")
query_path = base_dir / "scratch" / "book_v2_update" / "direct_permission_sets_all_active.json"
output_path = base_dir / "scratch" / "book_v2_update" / "deck_metrics.json"

with query_path.open("r", encoding="utf-8-sig") as f:
    records = json.load(f)["result"]["records"]

users = {}
by_user = defaultdict(list)
by_ps = defaultdict(list)
by_profile = Counter()
high_risk_users = set()
high_risk_rows = []
super_user_users = set()
waive_mfa_users = set()

for r in records:
    assignee = r.get("Assignee") or {}
    ps = r.get("PermissionSet") or {}
    username = assignee.get("Username") or ""
    profile = (assignee.get("Profile") or {}).get("Name") or ""
    label = ps.get("Label") or ps.get("Name") or ""
    users[username] = {
        "name": assignee.get("Name"),
        "username": username,
        "email": assignee.get("Email"),
        "userType": assignee.get("UserType"),
        "profile": profile,
    }
    by_user[username].append(
        {
            "label": label,
            "apiName": ps.get("Name"),
            "modifyAllData": bool(ps.get("PermissionsModifyAllData")),
            "viewAllData": bool(ps.get("PermissionsViewAllData")),
        }
    )
    by_ps[label].append(username)
    by_profile[profile] += 1
    if ps.get("PermissionsModifyAllData") or ps.get("PermissionsViewAllData"):
        high_risk_users.add(username)
        high_risk_rows.append((username, assignee.get("Name"), label, profile))
    if ps.get("Name") == "Super_User" or label.strip('"') == "Super User":
        super_user_users.add(username)
    if ps.get("Name") == "Waive_MFA" or label == "Waive MFA":
        waive_mfa_users.add(username)

top_users = []
for username, assignments in by_user.items():
    risk_labels = [
        a["label"]
        for a in assignments
        if a["modifyAllData"] or a["viewAllData"] or a["apiName"] in {"Super_User", "Waive_MFA"}
    ]
    top_users.append(
        {
            **users[username],
            "directPermissionSetCount": len(assignments),
            "riskPermissionSets": "; ".join(sorted(set(risk_labels))),
        }
    )
top_users.sort(key=lambda x: (-x["directPermissionSetCount"], x["name"] or ""))

top_ps = [
    {"permissionSet": label, "assignedUsers": len(set(usernames))}
    for label, usernames in by_ps.items()
]
top_ps.sort(key=lambda x: (-x["assignedUsers"], x["permissionSet"]))

risk_ps = []
for label, usernames in by_ps.items():
    sample = next(
        (
            a
            for rows in by_user.values()
            for a in rows
            if a["label"] == label
        ),
        {},
    )
    if sample.get("modifyAllData") or sample.get("viewAllData") or label.strip('"') in {"Super User", "Waive MFA"}:
        risk_ps.append({"permissionSet": label, "assignedUsers": len(set(usernames))})
risk_ps.sort(key=lambda x: (-x["assignedUsers"], x["permissionSet"]))

metrics = {
    "sourceOrg": "ProboMedical",
    "sourceScope": "Active Salesforce users; direct Permission Set assignments; excludes profile-owned Permission Sets and Permission Set Group assignments.",
    "totalDirectAssignments": len(records),
    "usersInDirectAssignmentExport": len(users),
    "usersWithDirectPermissionSets": len(by_user),
    "uniqueDirectPermissionSets": len(by_ps),
    "highRiskDirectAssignments": len(high_risk_rows),
    "highRiskUsers": len(high_risk_users),
    "superUserUsers": len(super_user_users),
    "waiveMfaUsers": len(waive_mfa_users),
    "topUsersByDirectPS": top_users[:12],
    "topPermissionSetsByUserCount": top_ps[:12],
    "riskPermissionSets": risk_ps[:12],
    "assignmentRowsByProfile": [
        {"profile": profile, "assignmentRows": count}
        for profile, count in by_profile.most_common(12)
    ],
    "recommendedThresholds": {
        "reviewUserAtOrAboveDirectPSCount": 20,
        "criticalPermissionNames": ["Super User", "Waive MFA", "Modify All Data", "View All Data"],
    },
}

output_path.write_text(json.dumps(metrics, indent=2), encoding="utf-8")
print(json.dumps(metrics, indent=2))
