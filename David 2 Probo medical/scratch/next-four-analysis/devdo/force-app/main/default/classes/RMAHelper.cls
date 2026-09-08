/**
* @author Delagate
* @date 4/5/2021
*
* @description
*/

public without sharing class RMAHelper {
    public static void SetEmailandApprovalFields(List<RMA__c> rmas, Map<Id, RMA__c> oldRmas) {
        for(RMA__c rma : rmas) {
            RMA__c oldRMA =  oldRmas.get(rma.Id);
            if(oldRMA.Field_Service_Engineer__c != rma.Field_Service_Engineer__c && rma.Field_Service_Engineer__c != null) {
                List<String> engineer = rma.Field_Service_Engineer__c.split(' ');String secondPart ='';if(engineer.size () >= 2){secondPart = engineer[1];
                }   
                rma.Field_Service_Engineer_Email__c =  rma.Field_Service_Engineer__c.substring(0,1) + secondPart + '@trisonics.com';
                rma.Field_Service_Engineer_Text__c = rma.Field_Service_Engineer__c; 
            }
            //Add check if approved was changed  
            if(oldRMA.Warranty_Claim_Approved__c != rma.Warranty_Claim_Approved__c || oldRMA.Return_From_Sale_Approval__c != rma.Return_From_Sale_Approval__c || 
               oldRMA.Loaner_Action_Approved__c != rma.Loaner_Action_Approved__c || oldRMA.Rental_Return_Action_Approved__c != rma.Rental_Return_Action_Approved__c){
                    SetFieldsonApproval(rma, oldRMA, 'Warranty_Claim_Approved__c', 'Warranty_Claim_Approved_By__c', 'Time_Warranty_Claim_Approved__c');
            		SetFieldsonApproval(rma, oldRMA, 'Return_from_Sale_Approval__c', 'Return_from_Sale_Action_Approved_By__c', 'Time_Return_from_Sale_Action_Approved__c');
            		SetFieldsonApproval(rma, oldRMA, 'Loaner_Action_Approved__c', 'Loaner_Action_Approved_By__c', 'Time_Warranty_Claim_Approved__c');
            		SetFieldsonApproval(rma, oldRMA, 'Rental_Return_Action_Approved__c', 'Rental_Action_Approved_By__c', 'Time_Rental_Action_Approved__c');
                   
               }
            
        }
    }
    
    //This was not updating the opp. Added code into RMATriggerHandler. This may have caused an extra loop.
    /*public static void AssignDatetoOpp(List<RMA__c> rmas) {
        Map<Id, RMA__c> oppRMAMap = new Map<Id, RMA__c>();
        for(RMA__c rma : rmas) {
            if(rma.RMA_Type__c == 'Customer Repair Evaluation' && rma.Date_Repair_Approved__c != null && rma.Date_Repair_Evaluation_Sent__c != null && rma.Opportunity__r.Date_Repair_Evaluation_Sent__c == null && rma.Opportunity__r.Date_Repair_Approved__c == null) {
                oppRMAMap.put(rma.Opportunity__c, rma);
            }
        }
        List<Opportunity> opps = [SELECT Date_Repair_Evaluation_Sent__c, Date_Repair_Approved__c
                                        FROM Opportunity
                                        WHERE Id in: oppRMAMap.keyset()];
        for(Opportunity opp : opps) {
            RMA__c thisRMA = oppRMAMap.get(opp.Id);opp.Date_Repair_Approved__c = thisRMA.Date_Repair_Approved__c;opp.Date_Repair_Evaluation_Sent__c = thisRMA.Date_Repair_Evaluation_Sent__c;
        }
    }*/
    private static RMA__c SetFieldsonApproval(RMA__c rma, RMA__c oldRMA, string fieldName, string approvedByField, string approvedDateField) {
        if (rma.get(fieldName) != null && oldRMA.get(fieldName) != rma.get(fieldName)){
            rma.put(approvedDateField,DateTime.now());rma.put(approvedByField,UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
        }
        return rma;
    }
    
    
}