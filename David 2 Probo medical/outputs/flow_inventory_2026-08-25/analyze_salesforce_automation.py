import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
import xml.etree.ElementTree as ET


BASE = Path(__file__).resolve().parent
SOURCE = BASE / "source-data"
RETRIEVED = BASE / "retrieved-source"
FLOW_DIR = RETRIEVED / "flows"


def load_json(path):
    with Path(path).open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def load_records(path):
    return load_json(path)["records"]


def local_name(tag):
    return tag.split("}", 1)[-1]


def xml_to_data(element):
    children = list(element)
    if not children:
        return (element.text or "").strip()
    grouped = defaultdict(list)
    for child in children:
        grouped[local_name(child.tag)].append(xml_to_data(child))
    return {
        key: values[0] if len(values) == 1 else values
        for key, values in grouped.items()
    }


def parse_xml(path):
    return xml_to_data(ET.parse(path).getroot())


def as_list(value):
    if value is None:
        return []
    return value if isinstance(value, list) else [value]


def as_dict(value):
    return value if isinstance(value, dict) else {}


def clean_scalar(value):
    if value is None:
        return ""
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float, str)):
        return value
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def walk_values(value):
    if isinstance(value, dict):
        for key, child in value.items():
            yield key, child
            yield from walk_values(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_values(child)


def flatten_strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from flatten_strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from flatten_strings(child)


def compact_value(value, max_len=180):
    if isinstance(value, dict):
        preferred = [
            "stringValue",
            "booleanValue",
            "numberValue",
            "dateValue",
            "dateTimeValue",
            "elementReference",
        ]
        parts = []
        for key in preferred:
            if key in value:
                parts.append(f"{key}={compact_value(value[key], max_len)}")
        if not parts:
            parts = [f"{k}={compact_value(v, max_len)}" for k, v in value.items()]
        text = "; ".join(parts)
    elif isinstance(value, list):
        text = ", ".join(compact_value(item, max_len) for item in value)
    else:
        text = str(value or "")
    return text if len(text) <= max_len else text[: max_len - 3] + "..."


ELEMENT_KEYS = [
    "actionCalls",
    "apexPluginCalls",
    "assignments",
    "collectionProcessors",
    "customErrors",
    "decisions",
    "loops",
    "orchestratedStages",
    "recordCreates",
    "recordDeletes",
    "recordLookups",
    "recordRollbacks",
    "recordUpdates",
    "screens",
    "steps",
    "subflows",
    "transforms",
    "waits",
]


OBJECT_ROLE_KEYS = {
    "recordCreates": "Create",
    "recordDeletes": "Delete",
    "recordLookups": "Read",
    "recordUpdates": "Update",
    "dynamicChoiceSets": "Choice Read",
}


def flow_details(metadata):
    metadata = as_dict(metadata)
    start_raw = metadata.get("start")
    start = as_dict(as_list(start_raw)[0]) if as_list(start_raw) else {}
    start_object = clean_scalar(start.get("object"))
    record_trigger_type = clean_scalar(start.get("recordTriggerType"))
    trigger_type = clean_scalar(start.get("triggerType"))
    schedule = as_dict(start.get("schedule"))

    element_counts = {key: len(as_list(metadata.get(key))) for key in ELEMENT_KEYS}
    total_elements = sum(element_counts.values()) + (1 if start else 0)

    object_roles = defaultdict(set)
    if start_object:
        object_roles[start_object].add("Trigger")
    for key, role in OBJECT_ROLE_KEYS.items():
        for item in as_list(metadata.get(key)):
            item = as_dict(item)
            obj = clean_scalar(item.get("object"))
            if not obj and clean_scalar(item.get("inputReference")).startswith("$Record"):
                obj = start_object
            if obj:
                object_roles[obj].add(role)
    for variable in as_list(metadata.get("variables")):
        variable = as_dict(variable)
        obj = clean_scalar(variable.get("objectType"))
        if obj:
            object_roles[obj].add("Variable")
    for key, value in walk_values(metadata):
        if key == "object" and isinstance(value, str) and value:
            object_roles[value].add("Reference")

    fields = set()
    for key, value in walk_values(metadata):
        if key == "field" and isinstance(value, str) and value:
            fields.add(value)
    for text in flatten_strings(metadata):
        fields.update(re.findall(r"\$Record(?:__Prior)?\.([A-Za-z0-9_]+)", text))

    actions = []
    for action in as_list(metadata.get("actionCalls")):
        action = as_dict(action)
        actions.append(
            {
                "elementName": clean_scalar(action.get("name")),
                "label": clean_scalar(action.get("label")),
                "actionName": clean_scalar(action.get("actionName")),
                "actionType": clean_scalar(action.get("actionType")),
                "transactionModel": clean_scalar(action.get("flowTransactionModel")),
            }
        )

    apex_plugins = []
    for plugin in as_list(metadata.get("apexPluginCalls")):
        plugin = as_dict(plugin)
        apex_plugins.append(
            {
                "elementName": clean_scalar(plugin.get("name")),
                "label": clean_scalar(plugin.get("label")),
                "apexClass": clean_scalar(
                    plugin.get("apexClass") or plugin.get("actionName") or plugin.get("nameSegment")
                ),
            }
        )

    subflows = []
    for subflow in as_list(metadata.get("subflows")):
        subflow = as_dict(subflow)
        subflows.append(
            {
                "elementName": clean_scalar(subflow.get("name")),
                "label": clean_scalar(subflow.get("label")),
                "flowName": clean_scalar(subflow.get("flowName")),
            }
        )

    screen_components = set()
    for screen in as_list(metadata.get("screens")):
        for key, value in walk_values(screen):
            if key == "extensionName" and isinstance(value, str) and value:
                screen_components.add(value)

    filters = []
    for item in as_list(start.get("filters")):
        item = as_dict(item)
        filters.append(
            " ".join(
                part
                for part in [
                    clean_scalar(item.get("field")),
                    clean_scalar(item.get("operator")),
                    compact_value(item.get("value")),
                ]
                if part
            )
        )

    object_role_rows = [
        {"object": obj, "roles": sorted(roles)}
        for obj, roles in sorted(object_roles.items())
    ]
    return {
        "label": clean_scalar(metadata.get("label")),
        "description": clean_scalar(metadata.get("description")),
        "processType": clean_scalar(metadata.get("processType")),
        "status": clean_scalar(metadata.get("status")),
        "apiVersion": clean_scalar(metadata.get("apiVersion")),
        "runInMode": clean_scalar(metadata.get("runInMode")),
        "triggerOrder": clean_scalar(metadata.get("triggerOrder")),
        "startObject": start_object,
        "recordTriggerType": record_trigger_type,
        "triggerType": trigger_type,
        "scheduledFrequency": clean_scalar(schedule.get("frequency")),
        "scheduledStartDate": clean_scalar(schedule.get("startDate")),
        "scheduledStartTime": clean_scalar(schedule.get("startTime")),
        "startFilterLogic": clean_scalar(start.get("filterLogic")),
        "startFilters": filters,
        "elementCounts": element_counts,
        "totalElements": total_elements,
        "objectRoles": object_role_rows,
        "objects": [row["object"] for row in object_role_rows],
        "fields": sorted(fields),
        "actions": actions,
        "apexPlugins": apex_plugins,
        "subflows": subflows,
        "screenComponents": sorted(screen_components),
        "hasOrchestration": bool(
            as_list(metadata.get("orchestratedStages")) or as_list(metadata.get("steps"))
        ),
    }


def load_composite_metadata(prefix, batches):
    rows = {}
    for batch in range(1, batches + 1):
        path = SOURCE / f"{prefix}_batch_{batch}_response.json"
        if not path.exists():
            continue
        payload = load_json(path)
        for response in payload.get("compositeResponse", []):
            if response.get("httpStatusCode") == 200:
                body = response.get("body", {})
                if body.get("Id") and body.get("Metadata"):
                    rows[body["Id"]] = body
    return rows


definitions = load_records(SOURCE / "flow_definitions.json")
versions = load_records(SOURCE / "flow_versions.json")
version_by_id = {row["Id"]: row for row in versions}
versions_by_definition = defaultdict(list)
for row in versions:
    versions_by_definition[row["DefinitionId"]].append(row)

active_metadata_bodies = load_composite_metadata("active_flow", 2)
gap_metadata_bodies = load_composite_metadata("gap_flow", 3)

definition_name_counts = Counter(row["DeveloperName"] for row in definitions)
xml_metadata_by_name = {}
for path in FLOW_DIR.glob("*.flow-meta.xml"):
    xml_metadata_by_name[path.name.removesuffix(".flow-meta.xml")] = parse_xml(path)

latest_metadata_by_definition = {}
latest_metadata_source = {}
for definition in definitions:
    definition_id = definition["Id"]
    latest_id = definition.get("LatestVersionId")
    api_name = definition["DeveloperName"]
    if latest_id in gap_metadata_bodies:
        latest_metadata_by_definition[definition_id] = gap_metadata_bodies[latest_id]["Metadata"]
        latest_metadata_source[definition_id] = "Tooling metadata"
    elif definition_name_counts[api_name] == 1 and api_name in xml_metadata_by_name:
        latest_metadata_by_definition[definition_id] = xml_metadata_by_name[api_name]
        latest_metadata_source[definition_id] = "Retrieved XML"

flow_catalog = []
flow_details_rows = []
connections = []
object_map = []
definition_context = {}

all_definition_names = {row["DeveloperName"] for row in definitions}

for definition in definitions:
    definition_id = definition["Id"]
    api_name = definition["DeveloperName"]
    active_id = definition.get("ActiveVersionId")
    latest_id = definition.get("LatestVersionId")
    active_row = version_by_id.get(active_id, {})
    latest_row = version_by_id.get(latest_id, {})
    latest_metadata = latest_metadata_by_definition.get(definition_id)
    latest_details = flow_details(latest_metadata) if latest_metadata else None

    if active_id and active_id in active_metadata_bodies:
        analysis_metadata = active_metadata_bodies[active_id]["Metadata"]
        analysis_basis = f"Active v{active_row.get('VersionNumber', '')} (Tooling metadata)"
    elif active_id and active_id == latest_id and latest_metadata:
        analysis_metadata = latest_metadata
        analysis_basis = f"Active v{active_row.get('VersionNumber', '')} ({latest_metadata_source.get(definition_id, 'metadata')})"
    elif not active_id and latest_metadata:
        analysis_metadata = latest_metadata
        analysis_basis = f"Latest inactive v{latest_row.get('VersionNumber', '')} ({latest_metadata_source.get(definition_id, 'metadata')})"
    else:
        analysis_metadata = None
        analysis_basis = "Tooling fields only"

    details = flow_details(analysis_metadata) if analysis_metadata else {
        "label": latest_row.get("MasterLabel") or api_name,
        "description": latest_row.get("Description") or "",
        "processType": active_row.get("ProcessType") or latest_row.get("ProcessType") or "",
        "status": active_row.get("Status") or latest_row.get("Status") or "",
        "apiVersion": active_row.get("ApiVersion") or latest_row.get("ApiVersion") or "",
        "runInMode": active_row.get("RunInMode") or latest_row.get("RunInMode") or "",
        "triggerOrder": active_row.get("TriggerOrder") or latest_row.get("TriggerOrder") or "",
        "startObject": "",
        "recordTriggerType": "",
        "triggerType": "",
        "scheduledFrequency": "",
        "scheduledStartDate": "",
        "scheduledStartTime": "",
        "startFilterLogic": "",
        "startFilters": [],
        "elementCounts": {key: 0 for key in ELEMENT_KEYS},
        "totalElements": 0,
        "objectRoles": [],
        "objects": [],
        "fields": [],
        "actions": [],
        "apexPlugins": [],
        "subflows": [],
        "screenComponents": [],
        "hasOrchestration": False,
    }

    active = bool(active_id)
    active_differs = bool(active_id and active_id != latest_id)
    version_count = len(versions_by_definition.get(definition_id, []))
    last_modified = (
        active_row.get("LastModifiedDate") if active else latest_row.get("LastModifiedDate")
    ) or ""
    managed_state = (
        active_row.get("ManageableState") if active else latest_row.get("ManageableState")
    ) or ""
    complexity_score = min(
        5,
        1
        + (1 if details["totalElements"] >= 15 else 0)
        + (1 if details["totalElements"] >= 35 else 0)
        + (1 if len(details["objects"]) >= 3 else 0)
        + (1 if len(details["subflows"]) + len(details["actions"]) >= 5 else 0),
    )
    risk_flags = []
    if active_differs:
        risk_flags.append("Active version differs from latest")
    if active and not details["description"]:
        risk_flags.append("Active flow has no description")
    if details["totalElements"] >= 35:
        risk_flags.append("High element count")
    if len(details["objects"]) >= 4:
        risk_flags.append("Touches many objects")
    if details["hasOrchestration"]:
        risk_flags.append("Orchestration metadata present")

    row = {
        "Definition ID": definition_id,
        "API Name": api_name,
        "Label": details["label"] or latest_row.get("MasterLabel") or api_name,
        "Active": "Yes" if active else "No",
        "Active Version": active_row.get("VersionNumber") if active else None,
        "Latest Version": latest_row.get("VersionNumber"),
        "Active = Latest": "Yes" if active and active_id == latest_id else ("No" if active else "N/A"),
        "Analysis Basis": analysis_basis,
        "Process Type": details["processType"] or active_row.get("ProcessType") or latest_row.get("ProcessType"),
        "Start Object": details["startObject"],
        "Record Event": details["recordTriggerType"],
        "Trigger Timing": details["triggerType"],
        "Run Mode": details["runInMode"] or active_row.get("RunInMode") or latest_row.get("RunInMode"),
        "Trigger Order": details["triggerOrder"] or active_row.get("TriggerOrder") or latest_row.get("TriggerOrder"),
        "Scheduled Frequency": details["scheduledFrequency"],
        "API Version": details["apiVersion"] or active_row.get("ApiVersion") or latest_row.get("ApiVersion"),
        "Managed State": managed_state,
        "Version Count": version_count,
        "Total Elements": details["totalElements"],
        "Objects Touched": len(details["objects"]),
        "Subflow Calls": len(details["subflows"]),
        "Action Calls": len(details["actions"]) + len(details["apexPlugins"]),
        "Screen Components": len(details["screenComponents"]),
        "Complexity (1-5)": complexity_score,
        "Last Modified": last_modified,
        "Last Modified By": (active_row if active else latest_row).get("LastModifiedBy", {}).get("Name", "") if isinstance((active_row if active else latest_row).get("LastModifiedBy"), dict) else "",
        "Description": details["description"] or latest_row.get("Description") or "",
        "Risk Flags": "; ".join(risk_flags),
    }
    flow_catalog.append(row)

    detail_row = {
        "Definition ID": definition_id,
        "API Name": api_name,
        "Active": row["Active"],
        "Analysis Basis": analysis_basis,
        "Start Filters": " | ".join(details["startFilters"]),
        "Objects": ", ".join(details["objects"]),
        "Fields Referenced": ", ".join(details["fields"]),
        "Actions": ", ".join(sorted({a["actionName"] for a in details["actions"] if a["actionName"]})),
        "Subflows": ", ".join(sorted({s["flowName"] for s in details["subflows"] if s["flowName"]})),
        "Screen Components": ", ".join(details["screenComponents"]),
        "Total Elements": details["totalElements"],
    }
    for key in ELEMENT_KEYS:
        detail_row[key] = details["elementCounts"].get(key, 0)
    flow_details_rows.append(detail_row)

    for object_row in details["objectRoles"]:
        object_map.append(
            {
                "Definition ID": definition_id,
                "Flow API Name": api_name,
                "Flow Active": row["Active"],
                "Analysis Basis": analysis_basis,
                "Object": object_row["object"],
                "Roles": ", ".join(object_row["roles"]),
                "Start Object": "Yes" if object_row["object"] == details["startObject"] else "No",
                "Process Type": row["Process Type"],
            }
        )

    for subflow in details["subflows"]:
        target = subflow["flowName"]
        connections.append(
            {
                "Source Flow": api_name,
                "Source Active": row["Active"],
                "Analysis Basis": analysis_basis,
                "Connection Type": "Subflow",
                "Element": subflow["elementName"],
                "Target": target,
                "Target Found": "Yes" if target in all_definition_names else "No",
                "Details": subflow["label"],
            }
        )
    for action in details["actions"]:
        action_type = action["actionType"] or "Action"
        connections.append(
            {
                "Source Flow": api_name,
                "Source Active": row["Active"],
                "Analysis Basis": analysis_basis,
                "Connection Type": "Apex Action" if action_type.lower() == "apex" else "Built-in Action",
                "Element": action["elementName"],
                "Target": action["actionName"],
                "Target Found": "Review" if action_type.lower() == "apex" else "Platform",
                "Details": " | ".join(filter(None, [action_type, action["label"], action["transactionModel"]])),
            }
        )
    for plugin in details["apexPlugins"]:
        connections.append(
            {
                "Source Flow": api_name,
                "Source Active": row["Active"],
                "Analysis Basis": analysis_basis,
                "Connection Type": "Apex Plugin",
                "Element": plugin["elementName"],
                "Target": plugin["apexClass"],
                "Target Found": "Review",
                "Details": plugin["label"],
            }
        )
    for component in details["screenComponents"]:
        connections.append(
            {
                "Source Flow": api_name,
                "Source Active": row["Active"],
                "Analysis Basis": analysis_basis,
                "Connection Type": "Screen Component",
                "Element": "Screen",
                "Target": component,
                "Target Found": "Review",
                "Details": "LWC or Aura extension",
            }
        )

    definition_context[definition_id] = {
        "definition": definition,
        "catalog": row,
        "details": details,
    }


flow_versions_rows = []
definition_by_id = {row["Id"]: row for row in definitions}
for version in versions:
    definition = definition_by_id.get(version["DefinitionId"], {})
    created_by = version.get("CreatedBy") if isinstance(version.get("CreatedBy"), dict) else {}
    modified_by = version.get("LastModifiedBy") if isinstance(version.get("LastModifiedBy"), dict) else {}
    flow_versions_rows.append(
        {
            "Flow API Name": definition.get("DeveloperName", ""),
            "Definition ID": version.get("DefinitionId", ""),
            "Version ID": version.get("Id", ""),
            "Version": version.get("VersionNumber"),
            "Status": version.get("Status", ""),
            "Is Active Version": "Yes" if version.get("Id") == definition.get("ActiveVersionId") else "No",
            "Is Latest Version": "Yes" if version.get("Id") == definition.get("LatestVersionId") else "No",
            "Process Type": version.get("ProcessType", ""),
            "API Version": version.get("ApiVersion"),
            "Managed State": version.get("ManageableState", ""),
            "Is Template": version.get("IsTemplate", False),
            "Run Mode": version.get("RunInMode", ""),
            "Trigger Order": version.get("TriggerOrder"),
            "Created Date": version.get("CreatedDate", ""),
            "Created By": created_by.get("Name", ""),
            "Last Modified": version.get("LastModifiedDate", ""),
            "Last Modified By": modified_by.get("Name", ""),
            "Label": version.get("MasterLabel", ""),
            "Description": version.get("Description", ""),
        }
    )


def read_text(path):
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


active_record_flows_by_object = defaultdict(list)
for context in definition_context.values():
    if context["catalog"]["Active"] == "Yes" and context["details"]["startObject"]:
        active_record_flows_by_object[context["details"]["startObject"]].append(context)

flow_object_names = sorted({row["Object"] for row in object_map if row["Object"]}, key=len, reverse=True)

apex_classes = {}
for path in (RETRIEVED / "classes").glob("*.cls"):
    text = read_text(path)
    name = path.stem
    object_refs = [
        obj for obj in flow_object_names if re.search(rf"(?<![A-Za-z0-9_]){re.escape(obj)}(?![A-Za-z0-9_])", text)
    ]
    apex_classes[name] = {
        "name": name,
        "text": text,
        "invocable": bool(re.search(r"@InvocableMethod\b", text, re.I)),
        "auraEnabled": bool(re.search(r"@AuraEnabled\b", text, re.I)),
        "objectRefs": sorted(set(object_refs)),
    }

apex_triggers = []
for path in (RETRIEVED / "triggers").glob("*.trigger"):
    text = read_text(path)
    name = path.stem
    match = re.search(r"\btrigger\s+(\w+)\s+on\s+([A-Za-z0-9_]+)\s*\(([^)]*)\)", text, re.I | re.S)
    meta_path = path.with_name(path.name + "-meta.xml")
    status = ""
    if meta_path.exists():
        meta = parse_xml(meta_path)
        status = clean_scalar(meta.get("status"))
    apex_triggers.append(
        {
            "name": name,
            "object": match.group(2) if match else "",
            "events": ", ".join(part.strip() for part in match.group(3).split(",")) if match else "",
            "status": status,
        }
    )

triggers_by_object = defaultdict(list)
for trigger in apex_triggers:
    if trigger["object"]:
        triggers_by_object[trigger["object"]].append(trigger)

def normalize_component(value):
    value = value or ""
    value = value.split(":")[-1]
    value = value.split("/")[-1]
    return value.replace("c-", "", 1) if value.startswith("c-") else value


screen_flow_refs = defaultdict(list)
apex_action_flow_refs = defaultdict(list)
for connection in connections:
    if connection["Connection Type"] == "Screen Component":
        screen_flow_refs[normalize_component(connection["Target"])].append(connection["Source Flow"])
    if connection["Connection Type"] in {"Apex Action", "Apex Plugin"}:
        apex_action_flow_refs[normalize_component(connection["Target"])].append(connection["Source Flow"])

code_inventory = []
code_overlap = []

for trigger in sorted(apex_triggers, key=lambda row: row["name"].lower()):
    flows = [ctx["catalog"]["API Name"] for ctx in active_record_flows_by_object.get(trigger["object"], [])]
    code_inventory.append(
        {
            "Component Type": "Apex Trigger",
            "Component": trigger["name"],
            "Status / Exposure": trigger["status"],
            "Primary Object": trigger["object"],
            "Events / Targets": trigger["events"],
            "Invocable / Flow Screen": "N/A",
            "Direct Flow References": len(flows),
            "Referenced Flows": ", ".join(sorted(flows)),
            "Referenced Apex": "",
            "Objects Referenced": trigger["object"],
        }
    )
    if flows:
        code_overlap.append(
            {
                "Overlap Type": "Apex Trigger + Record-Triggered Flows",
                "Object / Target": trigger["object"],
                "Code Component": trigger["name"],
                "Flow": ", ".join(sorted(flows)),
                "Confidence": "High",
                "Risk": "Multiple automation engines share the same object transaction.",
                "Recommendation": "Trace trigger handler and active Flow order together; assign one owner per business rule before consolidating.",
            }
        )

for name, item in sorted(apex_classes.items(), key=lambda pair: pair[0].lower()):
    direct_flows = sorted(set(apex_action_flow_refs.get(name, [])))
    code_inventory.append(
        {
            "Component Type": "Apex Class",
            "Component": name,
            "Status / Exposure": "Invocable" if item["invocable"] else ("Aura Enabled" if item["auraEnabled"] else "Internal / other"),
            "Primary Object": "",
            "Events / Targets": "",
            "Invocable / Flow Screen": "Yes" if item["invocable"] else "No",
            "Direct Flow References": len(direct_flows),
            "Referenced Flows": ", ".join(direct_flows),
            "Referenced Apex": "",
            "Objects Referenced": ", ".join(item["objectRefs"]),
        }
    )
    for flow_name in direct_flows:
        code_overlap.append(
            {
                "Overlap Type": "Flow Invokes Apex",
                "Object / Target": "",
                "Code Component": name,
                "Flow": flow_name,
                "Confidence": "High",
                "Risk": "Flow behavior depends on coded action and its bulk/error semantics.",
                "Recommendation": "Keep as Apex when logic is computational, integration-heavy, or bulk-sensitive; document inputs/outputs before refactor.",
            }
        )

for bundle_path in sorted((RETRIEVED / "lwc").glob("*")):
    if not bundle_path.is_dir():
        continue
    name = bundle_path.name
    combined = "\n".join(read_text(path) for path in bundle_path.glob("*.*"))
    apex_imports = sorted(set(re.findall(r"@salesforce/apex/([A-Za-z0-9_]+)\.", combined)))
    schema_objects = sorted(set(re.findall(r"@salesforce/schema/([A-Za-z0-9_]+)(?:\.[A-Za-z0-9_]+)?", combined)))
    targets = sorted(set(re.findall(r"<target>([^<]+)</target>", combined)))
    direct_flows = sorted(set(screen_flow_refs.get(name, [])))
    flow_screen = "lightning__FlowScreen" in targets
    code_inventory.append(
        {
            "Component Type": "LWC",
            "Component": name,
            "Status / Exposure": ", ".join(targets),
            "Primary Object": "",
            "Events / Targets": ", ".join(targets),
            "Invocable / Flow Screen": "Yes" if flow_screen else "No",
            "Direct Flow References": len(direct_flows),
            "Referenced Flows": ", ".join(direct_flows),
            "Referenced Apex": ", ".join(apex_imports),
            "Objects Referenced": ", ".join(schema_objects),
        }
    )
    for flow_name in direct_flows:
        code_overlap.append(
            {
                "Overlap Type": "Flow Screen Uses LWC",
                "Object / Target": "",
                "Code Component": name,
                "Flow": flow_name,
                "Confidence": "High",
                "Risk": "Screen Flow contract depends on LWC public properties and Apex imports.",
                "Recommendation": "Preserve component API and regression-test screen inputs/outputs before combining flows.",
            }
        )

for bundle_path in sorted((RETRIEVED / "aura").glob("*")):
    if not bundle_path.is_dir():
        continue
    name = bundle_path.name
    combined = "\n".join(read_text(path) for path in bundle_path.glob("*.*"))
    controllers = sorted(set(re.findall(r"\bcontroller=\"([^\"]+)\"", combined)))
    flow_screen = "lightning:availableForFlowScreens" in combined
    direct_flows = sorted(set(screen_flow_refs.get(name, [])))
    code_inventory.append(
        {
            "Component Type": "Aura",
            "Component": name,
            "Status / Exposure": "Flow Screen" if flow_screen else "Aura bundle",
            "Primary Object": "",
            "Events / Targets": "",
            "Invocable / Flow Screen": "Yes" if flow_screen else "No",
            "Direct Flow References": len(direct_flows),
            "Referenced Flows": ", ".join(direct_flows),
            "Referenced Apex": ", ".join(controllers),
            "Objects Referenced": "",
        }
    )
    for flow_name in direct_flows:
        code_overlap.append(
            {
                "Overlap Type": "Flow Screen Uses Aura",
                "Object / Target": "",
                "Code Component": name,
                "Flow": flow_name,
                "Confidence": "High",
                "Risk": "Screen Flow contract depends on Aura attributes and controller behavior.",
                "Recommendation": "Treat as a migration boundary; preserve attributes or replace with LWC before broad flow consolidation.",
            }
        )


lane_groups = defaultdict(list)
for context in definition_context.values():
    if context["catalog"]["Active"] != "Yes":
        continue
    details = context["details"]
    if not details["startObject"]:
        continue
    lane = (
        details["startObject"],
        details["triggerType"] or "Unspecified timing",
        details["recordTriggerType"] or "Unspecified event",
    )
    lane_groups[lane].append(context)

consolidation_plan = []
for (obj, timing, event), contexts in lane_groups.items():
    flows = sorted(ctx["catalog"]["API Name"] for ctx in contexts)
    trigger_names = sorted(t["name"] for t in triggers_by_object.get(obj, []))
    flow_count = len(flows)
    apex_count = len(trigger_names)
    score = flow_count * 2 + apex_count * 2
    if flow_count >= 4 or score >= 10:
        priority = "High"
    elif flow_count >= 2 or apex_count:
        priority = "Medium"
    else:
        priority = "Low"
    if "Before" in timing:
        pattern = "One before-save entry Flow per object/event lane; consolidate field assignments and use Subflows for reusable calculations."
    elif "After" in timing:
        pattern = "One after-save entry Flow per object/event lane; route business domains to autolaunched Subflows and preserve async paths."
    elif "Delete" in event or "Delete" in timing:
        pattern = "Keep delete handling isolated; consolidate only after verifying cascade, sharing, and recursion behavior."
    else:
        pattern = "Review trigger semantics first; consolidate only flows with compatible timing and transaction behavior."
    if apex_count:
        pattern += " Trace Apex trigger handlers in the same transaction before selecting the final owner for each rule."
    if flow_count <= 1 and not apex_count:
        recommendation = "Retain for now; document ownership and reuse Subflows if shared logic emerges."
    else:
        recommendation = pattern
    flow_list = ", ".join(flows[:30]) + (f" (+{len(flows) - 30} more)" if len(flows) > 30 else "")
    consolidation_plan.append(
        {
            "Priority": priority,
            "Object": obj,
            "Trigger Timing": timing,
            "Record Event": event,
            "Active Flow Count": flow_count,
            "Apex Trigger Count": apex_count,
            "Active Flows": flow_list,
            "Apex Triggers": ", ".join(trigger_names),
            "Recommended Target Pattern": recommendation,
            "Flow Orchestrator Fit": "No for same-transaction consolidation; consider only for long-running, multi-user staged work.",
            "Next R&D Step": "Build a rule matrix by entry criteria, fields written, downstream actions, order, and error handling; then prototype in a sandbox.",
        }
    )

consolidation_plan.sort(
    key=lambda row: (
        {"High": 0, "Medium": 1, "Low": 2}[row["Priority"]],
        -row["Active Flow Count"],
        row["Object"],
        row["Trigger Timing"],
    )
)

catalog_by_name = {row["API Name"]: row for row in flow_catalog}
lane_count_by_flow = {}
for lane in consolidation_plan:
    for name in [part.strip() for part in lane["Active Flows"].split(",") if part.strip() and "(+" not in part]:
        lane_count_by_flow[name] = lane["Active Flow Count"]
for row in flow_catalog:
    count = lane_count_by_flow.get(row["API Name"], 0)
    if row["Active"] == "Yes" and row["Start Object"]:
        row["Consolidation Signal"] = "Strong" if count >= 4 else ("Review" if count >= 2 else "Isolated lane")
    else:
        row["Consolidation Signal"] = "N/A"


metrics = {
    "GeneratedAtUtc": datetime.now(timezone.utc).isoformat(),
    "Org": "Probo Medical",
    "OrgId": "00DU0000000LaKoMAK",
    "Definitions": len(definitions),
    "ActiveDefinitions": sum(1 for row in definitions if row.get("ActiveVersionId")),
    "InactiveDefinitions": sum(1 for row in definitions if not row.get("ActiveVersionId")),
    "ActiveDiffersFromLatest": sum(1 for row in definitions if row.get("ActiveVersionId") and row.get("ActiveVersionId") != row.get("LatestVersionId")),
    "Versions": len(versions),
    "RetrievedFlowXml": len(xml_metadata_by_name),
    "ToolingGapMetadata": len(gap_metadata_bodies),
    "ActiveRecordTriggeredFlows": sum(1 for row in flow_catalog if row["Active"] == "Yes" and row["Start Object"]),
    "ObjectsWithActiveRecordFlows": len(active_record_flows_by_object),
    "ConsolidationLanes": len(consolidation_plan),
    "HighPriorityLanes": sum(1 for row in consolidation_plan if row["Priority"] == "High"),
    "SubflowConnections": sum(1 for row in connections if row["Connection Type"] == "Subflow"),
    "ApexActionConnections": sum(1 for row in connections if row["Connection Type"] in {"Apex Action", "Apex Plugin"}),
    "ScreenComponentConnections": sum(1 for row in connections if row["Connection Type"] == "Screen Component"),
    "OrchestratorFlows": sum(1 for context in definition_context.values() if context["details"]["hasOrchestration"]),
    "ApexClasses": len(apex_classes),
    "ApexTriggers": len(apex_triggers),
    "LWCBundles": sum(1 for path in (RETRIEVED / "lwc").glob("*") if path.is_dir()),
    "AuraBundles": sum(1 for path in (RETRIEVED / "aura").glob("*") if path.is_dir()),
    "CodeOverlapRows": len(code_overlap),
}

process_type_counts = Counter(row["Process Type"] or "Unspecified" for row in flow_catalog)
active_object_counts = Counter(
    row["Start Object"] for row in flow_catalog if row["Active"] == "Yes" and row["Start Object"]
)

analysis = {
    "metrics": metrics,
    "processTypeSummary": [
        {"Process Type": key, "Flow Definitions": value}
        for key, value in process_type_counts.most_common()
    ],
    "activeObjectSummary": [
        {"Object": key, "Active Record-Triggered Flows": value}
        for key, value in active_object_counts.most_common()
    ],
    "flowCatalog": sorted(flow_catalog, key=lambda row: (row["API Name"].lower(), row["Definition ID"])),
    "flowVersions": sorted(flow_versions_rows, key=lambda row: (row["Flow API Name"].lower(), row["Version"] or 0)),
    "flowDetails": sorted(flow_details_rows, key=lambda row: (row["API Name"].lower(), row["Definition ID"])),
    "connections": sorted(connections, key=lambda row: (row["Source Flow"].lower(), row["Connection Type"], row["Target"])),
    "objectMap": sorted(object_map, key=lambda row: (row["Object"], row["Flow API Name"].lower())),
    "consolidationPlan": consolidation_plan,
    "codeInventory": code_inventory,
    "codeOverlap": sorted(code_overlap, key=lambda row: (row["Overlap Type"], row["Object / Target"], row["Code Component"], row["Flow"])),
}

with (BASE / "automation_analysis.json").open("w", encoding="utf-8") as handle:
    json.dump(analysis, handle, indent=2, ensure_ascii=False)

print(json.dumps(metrics, indent=2))
