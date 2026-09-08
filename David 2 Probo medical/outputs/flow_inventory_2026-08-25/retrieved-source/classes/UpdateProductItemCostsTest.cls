@isTest
(SeeAllData=TRUE)
public class UpdateProductItemCostsTest {
    @isTest
    static void testUpdateProductItemCosts() {
        // Step 1: Create Test Data

        // Retrieve the standard pricebook
        Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
        // Create Products
        Product2 product1 = new Product2(Name = 'Test Product 1', IsActive = true);
        Product2 product2 = new Product2(Name = 'Test Product 2', IsActive = true);
        insert new List<Product2>{product1, product2};

        // Create PricebookEntries
        PricebookEntry pricebookEntry1 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        PricebookEntry pricebookEntry2 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product2.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert new List<PricebookEntry>{pricebookEntry1, pricebookEntry2};

        // Create an Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = standardPricebook.Id,
            Sales_Lead_Source_Detail__c = 'Inbound Call'
        );
        insert opp;

        // Create OpportunityLineItem (Opportunity Products)
        OpportunityLineItem oli1 = new OpportunityLineItem(
			OpportunityId = opp.Id,
            Product2Id = product1.Id,
            UnitPrice = 100,
            Quantity = 1,
            Probo_s_Offer__c = 150 // Custom field
        );
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = product2.Id,
            UnitPrice = 200,
            Quantity = 2,
            Probo_s_Offer__c = 250 // Custom field
        );
        insert new List<OpportunityLineItem>{oli1, oli2};

        // Create ProductItem__c records
        ProductItem__c productItem1 = new ProductItem__c(
            Product_Name__c = product1.Id,
            Cost__c = 0 // Initial value
        );
        ProductItem__c productItem2 = new ProductItem__c(
            Product_Name__c = product2.Id,
            Cost__c = 0 // Initial value
        );
        insert new List<ProductItem__c>{productItem1, productItem2};

        // Step 2: Prepare Inputs for the Invocable Method
        UpdateProductItemCosts.Request request = new UpdateProductItemCosts.Request();
        request.opportunityProducts = new List<OpportunityLineItem>{oli1, oli2};
        request.productItems = new List<ProductItem__c>{productItem1, productItem2};

        // Add to the input request list
        List<UpdateProductItemCosts.Request> requests = new List<UpdateProductItemCosts.Request>{request};

        // Step 3: Invoke the Method
        List<UpdateProductItemCosts.OutputResponse> responses = UpdateProductItemCosts.updateProductItemCosts(requests);

        // Step 4: Assertions
        System.assertEquals(1, responses.size(), 'There should be one response');

        UpdateProductItemCosts.OutputResponse response = responses[0];

        // Check updated ProductItem__c records
        System.assertEquals(2, response.updatedProductItems.size(), 'Two ProductItem__c records should be updated');

        // Check associated ProductItem__c IDs
        System.assertEquals(2, response.associatedProductItemIds.size(), 'Two ProductItem__c IDs should be associated with costs');
        System.assert(response.associatedProductItemIds.contains(productItem1.Id), 'Product Item 1 ID should be in the associated IDs');
        System.assert(response.associatedProductItemIds.contains(productItem2.Id), 'Product Item 2 ID should be in the associated IDs');

        // Verify updated values
        for (ProductItem__c updatedProduct : response.updatedProductItems) {
            if (updatedProduct.Product_Name__c == product1.Id) {
                System.assertEquals(150, updatedProduct.Cost__c, 'Cost__c should match Probo_s_Offer__c for Product 1');
            } else if (updatedProduct.Product_Name__c == product2.Id) {
                System.assertEquals(250, updatedProduct.Cost__c, 'Cost__c should match Probo_s_Offer__c for Product 2');
            } else {
                System.assert(false, 'Unexpected ProductItem__c record updated');
            }
        }
    }
}