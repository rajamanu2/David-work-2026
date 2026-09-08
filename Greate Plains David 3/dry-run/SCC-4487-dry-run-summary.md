# SCC-4487 Check-Only Validation Summary

Date: 2026-08-28  
Decision: **BLOCKED / NO-GO**  
Deployment performed: **No**

## Target and scope

- Source inspected: `GreatPlainsMerge`
  - Organization: Great Plains Communications
  - Org ID: `00DEa00000GkAsHMAV`
  - Type: Unlimited Edition sandbox
- Intended check-only target: `GreatPlainsUAT`
- Expected ticket payload: 6 components
  - `CustomField:Order.Segment__c`
  - `Layout:Order-Inside Sales`
  - `FlexiPage:OSE_CPQOrderRecordPage`
  - `Profile:Admin` (System Administrator)
  - `Profile:System Administrator - API Only`
  - `Profile:Standard` (Standard User)
- Tests requested/executed: `NoTestRun`; 0 Apex tests. This is configuration-only scope.

## Check-only result

The UAT dry-run command was attempted with `sf project deploy start --dry-run` and the focused manifest. Salesforce rejected the request before creating a validation job because the saved `GreatPlainsUAT` session is expired (`INVALID_SESSION_ID`).

- Job ID: **None created**
- Components processed: **0**
- Tests run: **0**
- UAT compilation/validation result: **Unverified**

## Source-package readiness

The focused read-only retrieval from `GreatPlainsMerge` succeeded for 5 of the 6 expected components. Salesforce returned this warning for the missing component:

`Entity of type 'CustomField' named 'Order.Segment__c' cannot be found`

The retrieved metadata also shows:

- `Order-Inside Sales` contains `Customer_Type__c`, followed immediately by `Additional_Information_Online_Form__c`; `Segment__c` is absent.
- `OSE_CPQOrderRecordPage` uses Dynamic Forms and contains `Record.Customer_Type__c`, followed immediately by `Record.Additional_Information_Online_Form__c`; `Record.Segment__c` is absent.
- The three named profiles contain no `Order.Segment__c` field permission.
- All three profiles do contain the `Order-Inside Sales` layout assignment for record type `Order.Inside_Sales`.
- `Account.Segment__c` exists as an editable picklist. Active values include `Residential` and `MDU Tenant` (also `MDU Bulk`, `SFU`, and `Other`).

## Acceptance-criteria assessment

| Acceptance criterion | Result | Evidence |
|---|---|---|
| Segment appears below Customer Type on the Inside Sales order | **Failed in connected source** | Both the layout and Dynamic Forms page place `Additional_Information_Online_Form__c` after Customer Type; Segment is absent. |
| Order Segment mirrors Consumer Account Segment | **Blocked** | `Order.Segment__c` is absent, so the formula cannot be inspected or validated. |
| Residential maps to Residential | **Blocked** | The Account value exists, but the target Order formula field is absent. |
| MDU Tenant maps to MDU Tenant | **Blocked** | The Account value exists, but the target Order formula field is absent. |
| Order Segment is a formula/read-only field | **Failed in connected source** | No `Order.Segment__c` metadata or schema field exists in `GreatPlainsMerge`. |
| Named-profile field access | **Failed in connected source** | No `Order.Segment__c` field permission exists in Admin, API-only Admin, or Standard profiles. |
| Blank handling, reporting, and list-view filtering | **Unverified** | The field is absent and UAT validation could not start. |

## Test-fixture observations

- The ticket example Order `00000312` exists in Merge but has record type `WorkingCart`, not `Inside_Sales`; its Account Segment is blank. It is not a valid fixture for the stated Inside Sales test in this org.
- Merge has 2,708 Inside Sales orders in the aggregate query: 2,653 with blank Account Segment and 55 with Residential.
- No Inside Sales order with Account Segment `MDU Tenant` appeared in the aggregate result, so an MDU Tenant fixture must be identified or created by the authorized test team before functional acceptance testing.

## Required next actions

1. Supply or connect the actual `devA` implementation source, or move the completed SCC-4487 metadata into the reviewed Merge source.
2. Ensure the package contains the formula field, both presentation components, and all three profile permissions.
3. Reauthenticate `GreatPlainsUAT`.
4. Rerun the same six-component check-only validation and record its job ID, component totals, and errors.
5. Perform UI/reporting tests using valid Residential, MDU Tenant, and blank Inside Sales fixtures.

No metadata, records, permissions, assignments, activations, or deployments were changed in either Salesforce org.
