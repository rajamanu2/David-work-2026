import json
from pathlib import Path


BASE = Path(__file__).resolve().parent
SOURCE = BASE / "source-data"


def load_records(path: Path):
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)["records"]


definitions = load_records(SOURCE / "flow_definitions.json")
versions = load_records(SOURCE / "flow_versions.json")
version_by_id = {row["Id"]: row for row in versions}
flow_dir = BASE / "retrieved-source" / "flows"
retrieved_names = {
    path.name.removesuffix(".flow-meta.xml")
    for path in flow_dir.glob("*.flow-meta.xml")
}
name_counts = {}
for definition in definitions:
    name_counts[definition["DeveloperName"]] = (
        name_counts.get(definition["DeveloperName"], 0) + 1
    )

active_differences = []
for definition in definitions:
    active_id = definition.get("ActiveVersionId")
    latest_id = definition.get("LatestVersionId")
    if active_id and active_id != latest_id:
        active_row = version_by_id.get(active_id, {})
        latest_row = version_by_id.get(latest_id, {})
        active_differences.append(
            {
                "apiName": definition["DeveloperName"],
                "definitionId": definition["Id"],
                "activeVersionId": active_id,
                "activeVersionNumber": active_row.get("VersionNumber"),
                "latestVersionId": latest_id,
                "latestVersionNumber": latest_row.get("VersionNumber"),
            }
        )

with (SOURCE / "active_flow_diff_index.json").open("w", encoding="utf-8") as handle:
    json.dump(active_differences, handle, indent=2)

for batch_number, offset in enumerate(range(0, len(active_differences), 25), start=1):
    batch = active_differences[offset : offset + 25]
    body = {
        "allOrNone": False,
        "compositeRequest": [
            {
                "method": "GET",
                "url": f"/services/data/v67.0/tooling/sobjects/Flow/{row['activeVersionId']}",
                "referenceId": f"flow_{offset + index + 1:03d}",
            }
            for index, row in enumerate(batch)
        ],
    }
    with (SOURCE / f"active_flow_batch_{batch_number}_request.json").open(
        "w", encoding="utf-8"
    ) as handle:
        json.dump(body, handle, indent=2)

metadata_gaps = []
for definition in definitions:
    api_name = definition["DeveloperName"]
    latest_id = definition.get("LatestVersionId")
    reason = None
    if name_counts[api_name] > 1:
        reason = "Duplicate API name"
    elif api_name not in retrieved_names:
        reason = "Metadata file not retrieved"
    if reason and latest_id:
        latest_row = version_by_id.get(latest_id, {})
        metadata_gaps.append(
            {
                "apiName": api_name,
                "definitionId": definition["Id"],
                "latestVersionId": latest_id,
                "latestVersionNumber": latest_row.get("VersionNumber"),
                "reason": reason,
            }
        )

with (SOURCE / "gap_flow_index.json").open("w", encoding="utf-8") as handle:
    json.dump(metadata_gaps, handle, indent=2)

for batch_number, offset in enumerate(range(0, len(metadata_gaps), 25), start=1):
    batch = metadata_gaps[offset : offset + 25]
    body = {
        "allOrNone": False,
        "compositeRequest": [
            {
                "method": "GET",
                "url": f"/services/data/v67.0/tooling/sobjects/Flow/{row['latestVersionId']}",
                "referenceId": f"gap_{offset + index + 1:03d}",
            }
            for index, row in enumerate(batch)
        ],
    }
    with (SOURCE / f"gap_flow_batch_{batch_number}_request.json").open(
        "w", encoding="utf-8"
    ) as handle:
        json.dump(body, handle, indent=2)

print(
    f"active_differences={len(active_differences)} "
    f"active_batches={(len(active_differences) + 24) // 25} "
    f"metadata_gaps={len(metadata_gaps)} "
    f"gap_batches={(len(metadata_gaps) + 24) // 25}"
)
