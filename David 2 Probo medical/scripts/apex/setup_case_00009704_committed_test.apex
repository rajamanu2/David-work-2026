String marker = 'CODEX_CASE_00009704_20260831_' + String.valueOf(Datetime.now().getTime());

Account accountRecord = new Account(Name = marker + '_ACCOUNT');
insert accountRecord;

Product2 productRecord = TestDataFactory.createProduct('Ultrasound Probe', true);
ProductItem__c productItem = TestDataFactory.createProductItem(productRecord.Id, true);

Opportunity completedOpportunity = new Opportunity(
    Name = marker + '_COMPLETED_OPP',
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(30),
    AccountId = accountRecord.Id
);
Opportunity openOpportunity = new Opportunity(
    Name = marker + '_OPEN_OPP',
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(30),
    AccountId = accountRecord.Id
);
insert new List<Opportunity>{ completedOpportunity, openOpportunity };

WorkOrder completedWorkOrder = new WorkOrder(
    Subject = marker + '_COMPLETED_WO',
    Status = 'Completed WO',
    RecordTypeId = '012Ro000001eDqnIAE',
    Country = 'United States',
    AccountId = accountRecord.Id,
    Opportunity__c = completedOpportunity.Id
);
WorkOrder openWorkOrder = new WorkOrder(
    Subject = marker + '_OPEN_WO',
    Status = 'New',
    RecordTypeId = '012Ro000001eDqnIAE',
    Country = 'United States',
    AccountId = accountRecord.Id,
    Opportunity__c = openOpportunity.Id
);
insert new List<WorkOrder>{ completedWorkOrder, openWorkOrder };

completedOpportunity.Related_Work_Order__c = completedWorkOrder.Id;
openOpportunity.Related_Work_Order__c = openWorkOrder.Id;
update new List<Opportunity>{ completedOpportunity, openOpportunity };

RMA__c completedRma = TestDataFactory.createRMA('Warranty Claim', false);
completedRma.ProductItem__c = productItem.Id;
completedRma.Opportunity__c = completedOpportunity.Id;
completedRma.Customer_Expectation__c = 'Customer wants Equipment Back';
completedRma.Quality_Issue_Notes__c = marker;
completedRma.Tracking_number_of_RMA_Item_Received__c = marker + '_COMPLETED';

RMA__c openRma = TestDataFactory.createRMA('Warranty Claim', false);
openRma.ProductItem__c = productItem.Id;
openRma.Opportunity__c = openOpportunity.Id;
openRma.Customer_Expectation__c = 'Customer wants Equipment Back';
openRma.Quality_Issue_Notes__c = marker;
openRma.Tracking_number_of_RMA_Item_Received__c = marker + '_OPEN';
insert new List<RMA__c>{ completedRma, openRma };

completedRma.Date_RMA_Item_Received__c = Date.today();
openRma.Date_RMA_Item_Received__c = Date.today();
update new List<RMA__c>{ completedRma, openRma };

System.debug(LoggingLevel.ERROR,
    'CODEX_RMA_TEST_IDS|' + marker +
    '|ACCOUNT=' + accountRecord.Id +
    '|PRODUCT=' + productRecord.Id +
    '|PRODUCT_ITEM=' + productItem.Id +
    '|COMPLETED_OPP=' + completedOpportunity.Id +
    '|OPEN_OPP=' + openOpportunity.Id +
    '|COMPLETED_WO=' + completedWorkOrder.Id +
    '|OPEN_WO=' + openWorkOrder.Id +
    '|COMPLETED_RMA=' + completedRma.Id +
    '|OPEN_RMA=' + openRma.Id
);
