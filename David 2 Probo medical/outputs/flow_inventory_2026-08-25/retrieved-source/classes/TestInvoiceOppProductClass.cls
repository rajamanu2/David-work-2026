@isTest (seeAllData=true)
public class TestInvoiceOppProductClass {

    @isTest static void testAccountOpportunity_US(){  
        // Fetch an existing Invoice linked to a US opportunity
        Invoice__c inv = [
            SELECT Id, Account__c, Opportunity__c, Physical_Location__c, Entity_Location__c
            FROM Invoice__c
            WHERE Opportunity__c != null
              AND Account__c != null
              AND Opportunity__r.Entity__c = 'Probo-US'
            LIMIT 1
        ];

        PageReference testPage = Page.Invoice_PDF; 
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(inv.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(inv);     
        InvoiceOppProducts ext = new InvoiceOppProducts(sc);

        System.assertNotEquals(null, ext, 'Extension should be instantiated');
    } 
    
    @isTest static void testAccountOpportunity_Canada(){  
        // Fetch an existing Invoice linked to a Canada (Probo-CAD) opportunity
        Invoice__c inv = [
            SELECT Id, Account__c, Opportunity__c, Physical_Location__c, Entity_Location__c, Total_Storage_Days__c
            FROM Invoice__c
            WHERE Opportunity__c != null
              AND Account__c != null
              AND Opportunity__r.Entity__c = 'Probo-CAD'
            LIMIT 1
        ];

        PageReference testPage = Page.Invoice_PDF; 
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Id', String.valueOf(inv.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(inv);     
        InvoiceOppProducts ext = new InvoiceOppProducts(sc);

        System.assertNotEquals(null, ext, 'Extension should be instantiated');
    } 
}