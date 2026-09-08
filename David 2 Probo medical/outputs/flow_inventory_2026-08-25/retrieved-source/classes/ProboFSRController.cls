public class ProboFSRController {
    public WorkOrder wo { get; private set; }
    public List<ServiceAppointment> appointments { get; private set; }
    public List<WorkOrderLineItem> lineItems { get; private set; }

    // Convenience display fields
    public String contactOrLeadName { get; private set; }
    public String workTypeName { get; private set; }

    // Equipment block (from AssetId)
    public String equipmentMakeModel { get; private set; }
    public String equipmentOemSerial { get; private set; }
    public String equipmentSerial { get; private set; }

    public ProboFSRController(ApexPages.StandardController std) {
        // Base Work Order
        wo = (WorkOrder) std.getRecord();

        wo = [
            SELECT Id, Subject, Description, Status,
                   Street, City, State, PostalCode, Country,
                   ContactId, WorkTypeId, Lead__c,
                   AssetId
            FROM WorkOrder
            WHERE Id = :wo.Id
            LIMIT 1
        ];

        // Contact or Lead name (use the one that exists)
        if (wo.ContactId != null) {
            Contact c = [SELECT Name FROM Contact WHERE Id = :wo.ContactId LIMIT 1];
            contactOrLeadName = (c != null) ? c.Name : null;
        } else if ((Id)wo.get('Lead__c') != null) {
            Lead l = [SELECT Name FROM Lead WHERE Id = :((Id)wo.get('Lead__c')) LIMIT 1];
            contactOrLeadName = (l != null) ? l.Name : null;
        }

        // Work Type name (if populated)
        if (wo.WorkTypeId != null) {
            WorkType wt = [SELECT Name FROM WorkType WHERE Id = :wo.WorkTypeId LIMIT 1];
            workTypeName = (wt != null) ? wt.Name : null;
        }

        // Related Service Appointments
        appointments = [
            SELECT Id,
                   AppointmentNumber,
                   ActualStartTime,
                   Status,
                   Labor_Hours__c,
                   Travel_Hours__c,
                   Solution_Remarks__c
            FROM ServiceAppointment
            WHERE Work_Order__c = :wo.Id
            ORDER BY ActualStartTime ASC NULLS LAST
        ];

        // Related Work Order Line Items
        lineItems = [
            SELECT Id,
                   WorkOrderId,
                   Service_Appointment__c,
                   Service_Appointment__r.AppointmentNumber,
                   Line_Type__c,
                   Part_Name_D__c,
                   Serial_No_D__c,
                   Part_Number_D__c
            FROM WorkOrderLineItem
            WHERE WorkOrderId = :wo.Id
            ORDER BY CreatedDate ASC
        ];

        // ---- Equipment (from WorkOrder.AssetId) ----
        if (wo.AssetId != null) {
            // First try the standard Asset object
            try {
                String soql =
                    'SELECT Make_Model__c, OEM_Serial__c, SerialNumber ' +
                    'FROM Asset WHERE Id = \'' + String.valueOf(wo.AssetId) + '\' LIMIT 1';
                SObject a = Database.query(soql);
                if (a != null) {
                    equipmentMakeModel = (String)a.get('Make_Model__c');
                    equipmentOemSerial = (String)a.get('OEM_Serial__c');
                    equipmentSerial    = (String)a.get('SerialNumber');
                }
            } catch (Exception ignore) {
                    // If neither query works, leave equipment fields null
                }
            }
        }
    }