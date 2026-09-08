public with sharing class UpdateProductItemCosts {
    // Method to be invoked from the Flow
    @InvocableMethod(label='Update Product Item Costs' description='Updates the Cost__c field on ProductItem__c records based on Opportunity Products')
    public static List<OutputResponse> updateProductItemCosts(List<Request> requests) {
        // Final list to hold the results for each input request
        List<OutputResponse> responses = new List<OutputResponse>();

        // Loop through each request
        for (Request req : requests) {
            // List to hold updated ProductItem__c records for this request
            List<ProductItem__c> updatedProductItems = new List<ProductItem__c>();
            List<Id> associatedProductItemIds = new List<Id>();

            // Create a map of Product ID to Probo_s_Offer__c value
            Map<Id, Decimal> productCostMap = new Map<Id, Decimal>();
            for (OpportunityLineItem oli : req.opportunityProducts) {
                productCostMap.put(oli.Product2Id, oli.Probo_s_Offer__c);
            }

            // Update the ProductItem__c records using the map
            for (ProductItem__c productItem : req.productItems) {
                if (productCostMap.containsKey(productItem.Product_Name__c)) {
                    productItem.Cost__c = productCostMap.get(productItem.Product_Name__c);
                    updatedProductItems.add(productItem);
                    associatedProductItemIds.add(productItem.Id); // Add the Id of the updated ProductItem__c
                }
            }

            // Create an output response object for this request
            OutputResponse response = new OutputResponse();
            response.updatedProductItems = updatedProductItems;
            response.associatedProductItemIds = associatedProductItemIds;
            responses.add(response);
        }

        // Return the list of responses
        return responses;
    }

    // Inner class to handle Flow inputs
    public class Request {
        @InvocableVariable(label='Opportunity Products' description='List of Opportunity Products (OpportunityLineItem)' required=true)
        public List<OpportunityLineItem> opportunityProducts;

        @InvocableVariable(label='Product Items' description='List of ProductItem__c records' required=true)
        public List<ProductItem__c> productItems;
    }

    // Inner class to handle Flow outputs
    public class OutputResponse {
        @InvocableVariable(label='Updated Product Items' description='List of updated ProductItem__c records')
        public List<ProductItem__c> updatedProductItems;

        @InvocableVariable(label='Associated Product Item IDs' description='List of IDs of ProductItem__c records that were associated with a cost')
        public List<Id> associatedProductItemIds;
    }
}