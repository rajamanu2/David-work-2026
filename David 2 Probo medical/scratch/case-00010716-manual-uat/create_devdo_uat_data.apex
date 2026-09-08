String runTag = 'DEVDO-UAT-00010716-20260903';

Product2 product = TestDataFactory.createProduct('Ultrasound Probe', false);
product.Name = runTag + ' Product';
product.Probe_Type__c = 'Linear';
insert product;

ProductItem__c productItem = new ProductItem__c(
    Product_Name__c = product.Id,
    Model__c = 'OAuth Callback Test',
    Serial_No__c = runTag,
    Check_In_Type__c = 'Customer Repair',
    Functional_Rating__c = 'B',
    Functional_Notes__c = 'DevDO OAuth UAT',
    Cosmetic_Rating__c = 'C',
    Cosmetic_Notes__c = 'DevDO OAuth UAT',
    PO_Number__c = 'UAT-10716',
    Other_Notes__c = runTag,
    Added_To_Opportunity__c = false,
    Receive_date__c = Date.today()
);
insert productItem;

Account account = TestDataFactory.createAccount(false);
account.Name = runTag + ' Account';
insert account;

RecordType opportunityRecordType = [
    SELECT Id
    FROM RecordType
    WHERE SObjectType = 'Opportunity'
      AND DeveloperName = 'Probe_Sales_Opportunity'
    LIMIT 1
];
Opportunity opportunity = new Opportunity(
    Name = runTag + ' Opportunity',
    AccountId = account.Id,
    CloseDate = Date.today().addDays(30),
    StageName = 'Prospecting',
    RecordTypeId = opportunityRecordType.Id
);
insert opportunity;

Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
PricebookEntry pricebookEntry = new PricebookEntry(
    Pricebook2Id = standardPricebook.Id,
    Product2Id = product.Id,
    IsActive = true,
    UnitPrice = 100
);
insert pricebookEntry;

OpportunityLineItem opportunityLine = new OpportunityLineItem(
    OpportunityId = opportunity.Id,
    Quantity = 1,
    PricebookEntryId = pricebookEntry.Id,
    TotalPrice = 100,
    ProductItem__c = productItem.Id
);
insert opportunityLine;

RecordType rmaRecordType = [
    SELECT Id
    FROM RecordType
    WHERE SObjectType = 'RMA__c'
      AND DeveloperName = 'Customer_Repair_Evaluation'
    LIMIT 1
];
RMA__c rma = new RMA__c(
    RecordTypeId = rmaRecordType.Id,
    ProductItem__c = productItem.Id,
    Opportunity__c = opportunity.Id,
    Quality_Issue_Notes__c = runTag,
    Recommended_Repairs__c = 'Probe Handle Refurbishment',
    Required_Repairs__c = 'Lens Relens',
    Depot_Repair__c = true,
    Other_Notes_Cosmetic__c = 'DevDO OAuth UAT',
    Other_Notes_Functional__c = 'DevDO OAuth UAT',
    Endoscopy_Evaluation_Results__c = 'DevDO OAuth UAT'
);
insert rma;

Evaluation_Natalie__c evaluationA = new Evaluation_Natalie__c(Associated_RMA__c = rma.Id);
insert evaluationA;
Evaluation_Natalie__c evaluationB = new Evaluation_Natalie__c(Associated_RMA__c = rma.Id);
insert evaluationB;

System.debug('UAT_PRODUCT_ITEM=' + productItem.Id);
System.debug('UAT_RMA=' + rma.Id);
System.debug('UAT_EVALUATION_A=' + evaluationA.Id);
System.debug('UAT_EVALUATION_B=' + evaluationB.Id);
