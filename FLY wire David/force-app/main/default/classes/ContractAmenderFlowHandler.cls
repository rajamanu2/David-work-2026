public with sharing class ContractAmenderFlowHandler {

    // Define the input structure for the Flow
    public class AmendContractRequest {
        @InvocableVariable(label='Contract ID' required=true)
        public Id contractId;
    }

    // Define the output structure for the Flow
    public class AmendContractResponse {
        @InvocableVariable(label='New Opportunity ID')
        public Id newOpportunityId;
        
        @InvocableVariable(label='New Quote ID')
        public Id newQuoteId;
    }

    // Invocable method called by the Flow
    @InvocableMethod(label='Amend CPQ Contract' description='Creates a new Amendment Opportunity and Quote.')
    public static List<AmendContractResponse> amendContract(List<AmendContractRequest> requestList) {
        List<AmendContractResponse> responseList = new List<AmendContractResponse>();
        
        for (AmendContractRequest request : requestList) {
            AmendContractResponse response = new AmendContractResponse();
            try {
                // Call the standard CPQ ContractManipulationAPI to amend the contract
                Id contractId = request.contractId;
                
                // This call triggers the amendment process and returns the new IDs
                // Output is a JSON string containing the new Opportunity and Quote IDs
                String jsonOutput = SBQQ.ServiceRouter.load(
                    'SBQQ.ContractManipulationAPI.ContractAmender', 
                    contractId, 
                    null
                );
                
                // Parse the JSON output (simplification - actual parsing may be more complex)
                Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(jsonOutput);
                
                // The actual field names in the JSON output may vary based on your CPQ version.
                // Standard CPQ API output usually requires looking up the new records post-amend.
                
                // For a reliable solution, we'll query for the newly created Opportunity/Quote
                // that is linked to the Contract and was created in the last few seconds.
                
                // 1. Get New Opportunity ID
                Opportunity newOpp = [
                    SELECT Id, SBQQ__AmendedContract__c 
                    FROM Opportunity 
                    WHERE SBQQ__AmendedContract__c = :contractId 
                    AND CreatedDate = LAST_N_DAYS:1
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
                response.newOpportunityId = newOpp.Id;

                // 2. Get New Primary Quote ID
                SBQQ__Quote__c newQuote = [
                    SELECT Id 
                    FROM SBQQ__Quote__c 
                    WHERE SBQQ__Opportunity2__c = :newOpp.Id 
                    AND SBQQ__Primary__c = TRUE
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                response.newQuoteId = newQuote.Id;

            } catch (Exception e) {
                // Handle exceptions (e.g., contract not amendable)
                System.debug('Error amending contract: ' + e.getMessage());
            }
            responseList.add(response);
        }
        return responseList;
    }
}