// Read-only verification: no DML, approval submission, or Messaging calls.
List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c
    WHERE SBQQ__Opportunity2__r.Name = 'SALDEV-1420 Test Opp'];
System.assertEquals(1, quotes.size(), 'Expected one unambiguous story test quote');
Id quoteId = quotes[0].Id;
Map<Id, String> names = new Map<Id, String>();
for (SBQQ__QuoteLine__c line : [SELECT Id, SBQQ__ProductName__c FROM SBQQ__QuoteLine__c
    WHERE SBQQ__Quote__c = :quoteId AND Quote_Line_Type__c != 'Amendment']) {
    names.put(line.Id, line.SBQQ__ProductName__c);
}
System.assert(!names.isEmpty(), 'Expected existing test lines');
for (String context : new List<String>{'Legal','Quote Approval','Revenue Approval'}) {
    EmailTableController c = new EmailTableController();
    c.quoteId = quoteId;
    c.templateName = context;
    List<EmailTableController.LineGroup> groups = c.getGroupedLines();
    System.assertEquals(false, c.hasError, c.errorMessage);
    System.assertEquals(2, groups.size(), 'Expected retained two-group scenario');
    List<List<String>> products = new List<List<String>>();
    for (EmailTableController.LineGroup g : groups) {
        List<String> rowNames = new List<String>();
        for (EmailTableController.RowWrapper row : g.rows) rowNames.add(row.cellValues[0]);
        products.add(rowNames);
    }
    System.assertEquals(new List<String>{'eStore','eStore (Usage)','eStore - Implementation Fee'}, products[0], 'Bundle sequence must follow QLE');
    System.assertEquals(new List<String>{'Domestic Payments','Cross Border Payments'}, products[1], 'Standalone sequence must follow QLE');
    System.debug(LoggingLevel.ERROR, 'SALDEV1420_VERIFY '+JSON.serialize(new Map<String,Object>{'context'=>context,'quoteId'=>quoteId,'products'=>products,'passed'=>true}));
}
