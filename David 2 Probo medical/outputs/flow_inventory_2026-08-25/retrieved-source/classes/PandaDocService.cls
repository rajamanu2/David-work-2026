public without sharing class PandaDocService {

    public static final String SIGNEDTYPE = 'eSignature';

    public enum PandaDocSigningInfo {SignerName, SignedDate, SignedType}

    public static Map<Id, Map<PandaDocSigningInfo, Object>> parseNotesIntoSigningInfo(List<Note> notesToParse){
        /* parse the Note as follows:
            if the format is:
             - Document {Document name} was signed by {Signer name} - Populate the {Signer Name} into the field `Customer_Signed_By__c`

             if the format is:
             - Document {Document name} has been completed - Populate the date this note is created into the field `Customer_Signed_Date__c`
             - Document {Document name} has been completed - When this is created, also Populate `Signature_Type__c` with "eSigned"
         */

        GH_Logger.debug('Start parseNotesIntoSigningInfo');
        Map<Id, Map<PandaDocSigningInfo, Object>> retInfo = new Map<Id, Map<PandaDocSigningInfo, Object>>();

        for (Note thisNote : notesToParse){

            // we need an Id to build our Map and we have to be on an Opportunity
            if (thisNote.Id != null && thisNote.ParentId.getSobjectType() == Opportunity.getSObjectType()){
                retInfo.put(thisNote.Id, parseNoteBody(thisNote.Body));
            }
        }

        GH_Logger.debug('returning PandaDocSigningInfo: ' + retInfo);
        return retInfo;
    }

    @TestVisible
    private static Map<PandaDocSigningInfo, Object> parseNoteBody(String theBody){

        Map<PandaDocSigningInfo, Object> retInfo = new Map<PandaDocSigningInfo, Object>();

        String signedText = 'was signed by';
        String completedText = 'has been completed';

        if (theBody.containsIgnoreCase(signedText)) {
            String signer = theBody.substring(theBody.indexOfIgnoreCase(signedText) + signedText.length()).trim().removeEnd('.').trim();
            retInfo.put(PandaDocSigningInfo.SignerName, signer);

        } else if (theBody.containsIgnoreCase(completedText)){
            retInfo.put(PandaDocSigningInfo.SignedDate, Date.today());
            retInfo.put(PandaDocSigningInfo.SignedType, SIGNEDTYPE);
        }

        return retInfo;
    }
}