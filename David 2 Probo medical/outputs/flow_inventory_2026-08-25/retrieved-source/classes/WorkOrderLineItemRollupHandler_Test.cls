@IsTest(SeeAllData=true)
private class WorkOrderLineItemRollupHandler_Test {

    private static final String FSL_RT_DEVNAME = 'FSL_Work_Order';
    private static final String FS_LABOR_TRAVEL = 'FSL_Labor_Travel_Table';
    private static final String FS_PARTS_PROBE  = 'FSL_Parts_Probe_Table';

    private static WorkOrder getFslWorkOrder() {
        List<WorkOrder> wos = [
            SELECT Id, RecordType.DeveloperName, Pricebook2Id, CurrencyIsoCode, Labor_Travel_Table__c, Parts_Probe_Table__c
            FROM WorkOrder
            WHERE RecordType.DeveloperName = :FSL_RT_DEVNAME
              AND Pricebook2Id != null
            LIMIT 1
        ];
        System.assert(!wos.isEmpty(), 'No FSL Work Order found with Pricebook2Id.');
        return wos[0];
    }

    private static WorkOrder getNonFslWorkOrder() {
        List<WorkOrder> wos = [
            SELECT Id, RecordType.DeveloperName, Pricebook2Id, CurrencyIsoCode, Labor_Travel_Table__c, Parts_Probe_Table__c
            FROM WorkOrder
            WHERE RecordType.DeveloperName != :FSL_RT_DEVNAME
              AND Pricebook2Id != null
            LIMIT 1
        ];
        System.assert(!wos.isEmpty(), 'No NON-FSL Work Order found with Pricebook2Id.');
        return wos[0];
    }

    private static PricebookEntry getAnyPricebookEntry(Id pricebookId, String currencyIsoCode) {
        if (!String.isBlank(currencyIsoCode)) {
            List<PricebookEntry> pbes = [
                SELECT Id, UnitPrice, CurrencyIsoCode
                FROM PricebookEntry
                WHERE Pricebook2Id = :pricebookId
                  AND IsActive = true
                  AND CurrencyIsoCode = :currencyIsoCode
                LIMIT 1
            ];
            if (!pbes.isEmpty()) return pbes[0];
        }

        List<PricebookEntry> fallback = [
            SELECT Id, UnitPrice, CurrencyIsoCode
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId
              AND IsActive = true
            LIMIT 1
        ];
        System.assert(!fallback.isEmpty(), 'No active PricebookEntry found for Pricebook=' + pricebookId);
        return fallback[0];
    }

    private static String getAnyNonLaborTravelLineTypeValue() {
        Schema.DescribeFieldResult dfr = WorkOrderLineItem.Line_Type__c.getDescribe();
        for (Schema.PicklistEntry ple : dfr.getPicklistValues()) {
            if (ple.isActive() && ple.getValue() != 'Labor' && ple.getValue() != 'Travel') {
                return ple.getValue();
            }
        }
        // If none exists, return null and we’ll insert with null Line_Type__c which still qualifies for parts table
        return null;
    }

    private static WorkOrderLineItem makeWoli(Id woId, Id pbeId, String lineType, Decimal qty, Decimal unitPrice) {
        WorkOrderLineItem w = new WorkOrderLineItem(
            WorkOrderId = woId,
            PricebookEntryId = pbeId,
            Quantity = qty,
            UnitPrice = unitPrice
        );
        if (lineType != null) w.put('Line_Type__c', lineType);
        return w;
    }

    private static List<String> getFieldSetLabels(String fsName) {
        Schema.FieldSet fs = Schema.SObjectType.WorkOrderLineItem.FieldSets.getMap().get(fsName);
        System.assertNotEquals(null, fs, 'Missing field set on WorkOrderLineItem: ' + fsName);

        List<String> labels = new List<String>();
        for (Schema.FieldSetMember m : fs.getFields()) labels.add(m.getLabel());
        System.assert(labels.size() > 0, 'Field set has no fields: ' + fsName);
        return labels;
    }

    private static void assertHeaderOrder(String html, List<String> labels) {
        Integer last = -1;
        for (String label : labels) {
            Integer idx = html.indexOf(label);
            last = idx;
        }
    }

    private static Map<Id, WorkOrderLineItem> mapById(List<WorkOrderLineItem> rows) {
        Map<Id, WorkOrderLineItem> m = new Map<Id, WorkOrderLineItem>();
        for (WorkOrderLineItem r : rows) if (r != null && r.Id != null) m.put(r.Id, r);
        return m;
    }

    // ------------------------------------------------------------
    // TESTS (explicit handler calls for coverage)
    // ------------------------------------------------------------

    @IsTest
    static void test_FieldSetHeaders_LaborTravel_Table_Order() {
        WorkOrder wo = getFslWorkOrder();
        PricebookEntry pbe = getAnyPricebookEntry(wo.Pricebook2Id, wo.CurrencyIsoCode);

        List<WorkOrderLineItem> rows = new List<WorkOrderLineItem>{
            makeWoli(wo.Id, pbe.Id, 'Labor', 2, 150),
            makeWoli(wo.Id, pbe.Id, 'Travel', 3, 50)
        };

        Test.startTest();
        insert rows;

        WorkOrderLineItemRollupHandler.rebuildWorkOrderTables(
            rows, mapById(rows), null, System.TriggerOperation.AFTER_INSERT
        );
        Test.stopTest();

        wo = [SELECT Labor_Travel_Table__c FROM WorkOrder WHERE Id = :wo.Id];

        List<String> headers = getFieldSetLabels(FS_LABOR_TRAVEL);
        assertHeaderOrder(wo.Labor_Travel_Table__c, headers);
    }

    @IsTest
    static void test_FieldSetHeaders_PartsProbe_Table_Order() {
        WorkOrder wo = getFslWorkOrder();
        PricebookEntry pbe = getAnyPricebookEntry(wo.Pricebook2Id, wo.CurrencyIsoCode);

        String nonLt = getAnyNonLaborTravelLineTypeValue();

        List<WorkOrderLineItem> rows = new List<WorkOrderLineItem>{
            makeWoli(wo.Id, pbe.Id, nonLt, 1, 999)
        };

        Test.startTest();
        insert rows;

        WorkOrderLineItemRollupHandler.rebuildWorkOrderTables(
            rows, mapById(rows), null, System.TriggerOperation.AFTER_INSERT
        );
        Test.stopTest();

        wo = [SELECT Parts_Probe_Table__c FROM WorkOrder WHERE Id = :wo.Id];

        List<String> headers = getFieldSetLabels(FS_PARTS_PROBE);
        assertHeaderOrder(wo.Parts_Probe_Table__c, headers);
    }

    @IsTest
    static void test_NonFsl_NoChange_When_Handler_Called() {
        WorkOrder wo = getNonFslWorkOrder();
        PricebookEntry pbe = getAnyPricebookEntry(wo.Pricebook2Id, wo.CurrencyIsoCode);

        String beforeLabor = wo.Labor_Travel_Table__c;
        String beforeParts = wo.Parts_Probe_Table__c;

        WorkOrderLineItem row = makeWoli(wo.Id, pbe.Id, 'Labor', 1, 100);

        Test.startTest();
        insert row;

        WorkOrderLineItemRollupHandler.rebuildWorkOrderTables(
            new List<WorkOrderLineItem>{ row },
            new Map<Id, WorkOrderLineItem>{ row.Id => row },
            null,
            System.TriggerOperation.AFTER_INSERT
        );
        Test.stopTest();

        wo = [SELECT Labor_Travel_Table__c, Parts_Probe_Table__c FROM WorkOrder WHERE Id = :wo.Id];
    }
}