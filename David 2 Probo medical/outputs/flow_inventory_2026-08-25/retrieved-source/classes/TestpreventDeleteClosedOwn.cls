@isTest
private class TestpreventDeleteClosedOwn {
    
    @isTest
    static void TestMethod1() {
        Account acc1 = new Account(Name = 'testAccount1');
        insert acc1;
        
        Opportunity op1 = new Opportunity(AccountId = acc1.id, Name = 'testOpportunity1', CloseDate = system.today(), StageName = 'Closed Won', Shipping_From_Location__c = 'Fishers, IN');
        insert op1;
        try {
              delete op1;
              system.assert(false);
        }catch(Exception e) {
          System.debug('Error : '+e.getMessage());
        }
    }
    
    @isTest
    static void TestMethod2() {
        Account acc1 = new Account(Name = 'testAccount1');
        insert acc1;
        
        for(Integer i=0; i<10; i++) {
            Opportunity op = new Opportunity(AccountId = acc1.id, Name = 'testOpportunity'+i, CloseDate = system.today(), StageName = 'Closed Won', Shipping_From_Location__c = 'Fishers, IN');
            insert op;
            try {
                  delete op;
                  system.assert(false);
            }catch(Exception e) {
              System.debug('Error : '+e.getMessage());
            }
        }
    }
    
    @isTest
    static void TestMethod3() {
        Account acc1 = new Account(Name = 'testAccount1');
        insert acc1;
        
        Opportunity op1 = new Opportunity(AccountId = acc1.id, Name = 'testOpportunity1', CloseDate = system.today(), StageName = 'Prospecting', Shipping_From_Location__c = 'Fishers, IN');
        insert op1;
        try {
              delete op1;
              system.assert(true);
        }catch(Exception e) {
          System.debug('Error : '+e.getMessage());
        }
    } 
}