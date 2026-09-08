from __future__ import annotations

import json
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / "scc-3384-retrieval" / "force-app" / "main" / "default"
NS = {"m": "http://soap.sforce.com/2006/04/metadata"}


def text(node: ET.Element | None, path: str, default: str | None = None) -> str | None:
    if node is None:
        return default
    found = node.find(path, NS)
    return found.text if found is not None else default


def all_text(node: ET.Element, path: str) -> list[str]:
    return [item.text or "" for item in node.findall(path, NS)]


def parse_field(path: Path) -> dict:
    root = ET.parse(path).getroot()
    values = []
    for value in root.findall("m:valueSet/m:valueSetDefinition/m:value", NS):
        values.append(
            {
                "name": text(value, "m:fullName"),
                "label": text(value, "m:label"),
                "default": text(value, "m:default"),
            }
        )
    dependencies = []
    for setting in root.findall("m:valueSet/m:valueSettings", NS):
        dependencies.append(
            {
                "controlling_values": all_text(setting, "m:controllingFieldValue"),
                "value": text(setting, "m:valueName"),
            }
        )
    return {
        "api_name": text(root, "m:fullName"),
        "label": text(root, "m:label"),
        "type": text(root, "m:type"),
        "required": text(root, "m:required"),
        "length": text(root, "m:length"),
        "visible_lines": text(root, "m:visibleLines"),
        "restricted": text(root, "m:valueSet/m:restricted"),
        "controlling_field": text(root, "m:valueSet/m:controllingField"),
        "value_count": len(values),
        "values": values,
        "dependency_count": len(dependencies),
        "dependencies": dependencies,
    }


def parse_record_type(path: Path) -> dict:
    root = ET.parse(path).getroot()
    picklists = {}
    for picklist in root.findall("m:picklistValues", NS):
        name = text(picklist, "m:picklist") or ""
        picklists[name] = [
            {
                "name": text(value, "m:fullName"),
                "default": text(value, "m:default"),
            }
            for value in picklist.findall("m:values", NS)
        ]
    return {
        "active": text(root, "m:active"),
        "label": text(root, "m:label"),
        "business_process": text(root, "m:businessProcess"),
        "picklists": picklists,
    }


def parse_layout(path: Path) -> dict:
    root = ET.parse(path).getroot()
    sections = []
    for section in root.findall("m:layoutSections", NS):
        rows = []
        for row in section.findall("m:layoutColumns", NS):
            rows.append(
                [
                    {
                        "field": text(item, "m:field"),
                        "behavior": text(item, "m:behavior"),
                        "custom_link": text(item, "m:customLink"),
                    }
                    for item in row.findall("m:layoutItems", NS)
                ]
            )
        sections.append(
            {
                "label": text(section, "m:label"),
                "style": text(section, "m:style"),
                "columns": rows,
            }
        )
    return {"sections": sections}


def parse_flow(path: Path) -> dict:
    root = ET.parse(path).getroot()
    return {
        "status": text(root, "m:status"),
        "process_type": text(root, "m:processType"),
        "object": text(root, "m:start/m:object"),
        "trigger_type": text(root, "m:start/m:triggerType"),
        "record_trigger_type": text(root, "m:start/m:recordTriggerType"),
        "filter_formula": text(root, "m:start/m:filterFormula"),
        "assignment_labels": all_text(root, "m:assignments/m:label"),
        "decision_labels": all_text(root, "m:decisions/m:label"),
        "formulas": [
            {"name": text(formula, "m:name"), "expression": text(formula, "m:expression")}
            for formula in root.findall("m:formulas", NS)
        ],
        "raw_text": " ".join(part.strip() for part in root.itertext() if part.strip()),
    }


def parse_permission_set(path: Path) -> dict:
    root = ET.parse(path).getroot()
    object_permissions = []
    for item in root.findall("m:objectPermissions", NS):
        object_permissions.append({child.tag.split("}")[-1]: child.text for child in item})
    field_permissions = []
    for item in root.findall("m:fieldPermissions", NS):
        field = text(item, "m:field") or ""
        if field.startswith("Case."):
            field_permissions.append({child.tag.split("}")[-1]: child.text for child in item})
    record_types = []
    for item in root.findall("m:recordTypeVisibilities", NS):
        record_types.append({child.tag.split("}")[-1]: child.text for child in item})
    return {
        "label": text(root, "m:label"),
        "object_permissions": object_permissions,
        "case_field_permissions": field_permissions,
        "record_type_visibilities": record_types,
    }


def parse_validation_rule(path: Path) -> dict:
    root = ET.parse(path).getroot()
    return {
        "name": text(root, "m:fullName"),
        "active": text(root, "m:active"),
        "formula": text(root, "m:errorConditionFormula"),
        "message": text(root, "m:errorMessage"),
    }


field_names = [
    "Service_Type__c",
    "Service_Address__c",
    "Priority__c",
    "Subscriber_Report__c",
    "Primary_Resolution__c",
    "Secondary_Resolution__c",
    "Resolution_Detail__c",
    "Problem_Occurred_Date__c",
    "Problem_Reported_Date__c",
    "Repair_Date__c",
    "Pending_Customer_Start__c",
    "Pending_Customer_End__c",
    "In_Progress_Date__c",
    "Completed_Date__c",
]

result = {
    "fields": {
        name: parse_field(ROOT / "objects" / "Case" / "fields" / f"{name}.field-meta.xml")
        for name in field_names
    },
    "record_type": parse_record_type(
        ROOT / "objects" / "Case" / "recordTypes" / "Trouble_Ticket.recordType-meta.xml"
    ),
    "layout": parse_layout(ROOT / "layouts" / "Case-Trouble Ticket.layout-meta.xml"),
    "flow": parse_flow(ROOT / "flows" / "Case_Date_Update_based_on_status_changes.flow-meta.xml"),
    "permission_set": parse_permission_set(
        ROOT / "permissionsets" / "SCC_3380_NOC_Incident_Case_Relationship.permissionset-meta.xml"
    ),
    "validation_rules": [
        parse_validation_rule(path)
        for path in sorted((ROOT / "objects" / "Case" / "validationRules").glob("*.xml"))
    ],
}

output_path = Path(__file__).with_name("metadata-full.json")
output_path.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")

compact = {
    "fields": {
        name: {
            "label": field["label"],
            "type": field["type"],
            "required": field["required"],
            "length": field["length"],
            "restricted": field["restricted"],
            "controlling_field": field["controlling_field"],
            "value_count": field["value_count"],
            "values": [item["name"] for item in field["values"]],
            "dependency_count": field["dependency_count"],
        }
        for name, field in result["fields"].items()
    },
    "record_type": {
        "active": result["record_type"]["active"],
        "label": result["record_type"]["label"],
        "business_process": result["record_type"]["business_process"],
        "relevant_picklists": {
            name: values
            for name, values in result["record_type"]["picklists"].items()
            if name
            in {
                "Status",
                "Priority",
                "Priority__c",
                "Service_Type__c",
                "Subscriber_Report__c",
                "Primary_Resolution__c",
                "Secondary_Resolution__c",
            }
        },
    },
    "layout": result["layout"],
    "flow": {key: value for key, value in result["flow"].items() if key != "raw_text"},
    "flow_mentions": {
        phrase: phrase in result["flow"]["raw_text"]
        for phrase in [
            "Pending_Customer_Start__c",
            "Pending_Customer_End__c",
            "In_Progress_Date__c",
            "Completed_Date__c",
            "Not Started",
            "Assigned",
            "In Progress",
            "On Hold – GPC",
            "On Hold – Pending Customer",
            "Complete",
            "Canceled",
            "Duplicate",
        ]
    },
    "permission_set": result["permission_set"],
    "validation_rules": result["validation_rules"],
    "full_json": str(output_path),
}

print(json.dumps(compact, indent=2, ensure_ascii=False))
