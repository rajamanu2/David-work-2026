@isTest
public class ContractAmenderFlowHandlerTest {
    @isTest
    static void testAmendContract() {
        // 1. Setup Data (Account & Pricebook)
        Account acc = new Account(Name = 'Flywire Test', Separate_Legal_Entity_Tax_ID__c = 'No'); 
        insert acc;
        
        Pricebook2 pb = new Pricebook2(Name = 'CPQ', IsActive = true); 
        insert pb;

        // 2. Setup Contract
        Contract c = new Contract(
            AccountId = acc.Id, 
            Pricebook2Id = pb.Id,
            StartDate = Date.today().addMonths(-1), 
            ContractTerm = 12,
            OwnerExpirationNotice = '30',
            Status = 'FW_Activated_Draft'
        );
        insert c;
       
        // 3. Create MOCK Amendment Records 
      
        Opportunity mockOpp = new Opportunity(
            Name = 'Amendment Opp',
            AccountId = acc.Id,
            SBQQ__AmendedContract__c = c.Id, 
            StageName = 'Discovery/Qualifying',
            CloseDate = Date.today()
        );
        insert mockOpp;

        SBQQ__Quote__c mockQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = mockOpp.Id, 
            SBQQ__Primary__c = true,
            SBQQ__Account__c = acc.Id
        );
        insert mockQuote;

        // 4. Execute the Flow Action
        ContractAmenderFlowHandler.AmendContractRequest request = new ContractAmenderFlowHandler.AmendContractRequest();
        request.contractId = c.Id;
        
        Test.startTest();
        List<ContractAmenderFlowHandler.AmendContractResponse> responses = 
            ContractAmenderFlowHandler.amendContract(new List<ContractAmenderFlowHandler.AmendContractRequest>{request});
        Test.stopTest();

        // 5. Verification
        System.assertNotEquals(0, responses.size(), 'Response list should not be empty');
        System.assertNotEquals(null, responses[0].newOpportunityId, 'The Opp ID should be found by the SOQL query');
    }
}