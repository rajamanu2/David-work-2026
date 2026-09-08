public without sharing class P_ClassicNoteTriggerHandler extends GH_TriggerHandlerBase {

    protected override void beforeInsert(){
        System.debug('Not implemented yet');
    }
    protected override void beforeUpdate(){
        System.debug('Not implemented yet');
    }
    protected override void beforeDelete(){
        System.debug('Not implemented yet');
    }
    protected override void afterInsert(){
        setOppDocSigningFields((Map<Id, Note>)newMap);
    }
    protected override void afterUpdate(){
        System.debug('Not implemented yet');
    }
    protected override void afterDelete(){
        System.debug('Not implemented yet');
    }
    protected override void afterUndelete(){
        System.debug('Not implemented yet');
    }

    @TestVisible
    private void setOppDocSigningFields(Map<Id, Note> notesToCheck){

        GH_Logger.debug('start setOppDocSigningFields');
        Map<Id, Map<PandaDocService.PandaDocSigningInfo, Object>> noteSigningInfo =  PandaDocService.parseNotesIntoSigningInfo(notesToCheck.values());

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Id noteId : noteSigningInfo.keySet()){
            GH_Logger.debug('working with noteID: ' + noteId);
            if (!noteSigningInfo.get(noteId).isEmpty()){
                GH_Logger.debug('have signing info');
                Opportunity thisOpp = new Opportunity();
                thisOpp.Id = notesToCheck.get(noteId).ParentId;

                for (PandaDocService.PandaDocSigningInfo theInfoType : noteSigningInfo.get(noteId).keySet()){
                    switch on theInfoType {
                        when SignerName {
                            thisOpp.Customer_Signed_By__c = String.valueOf(noteSigningInfo.get(noteId).get(theInfoType));
                        }
                        when SignedDate {
                            thisOpp.Customer_Signed_Date__c = Date.valueOf(noteSigningInfo.get(noteId).get(theInfoType));
                        }
                        when SignedType {
                            thisOpp.Signature_Type__c = String.valueOf(noteSigningInfo.get(noteId).get(theInfoType));
                        }
                    }
                }
                oppsToUpdate.add(thisOpp);
            }
        }

        GH_Logger.debug(' This many Opps to update: ' + oppsToUpdate.size());
        if (!oppsToUpdate.isEmpty()){
            DatabaseService.updateList(oppsToUpdate);
        }
        GH_Logger.debug('end setOppDocSigningFields');
    }
}