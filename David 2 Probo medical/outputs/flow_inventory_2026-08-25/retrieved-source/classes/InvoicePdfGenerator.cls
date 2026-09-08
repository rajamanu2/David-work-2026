public class InvoicePdfGenerator {
    @InvocableMethod
	public static List<String> getInvoicePDF(List<ID> ids) {
        for(ID id: ids){        
        PageReference pdfPage = new PageReference('/apex/Invoice_PDF');
        pdfPage.getParameters().put('ID', id);
             
 		ContentDocument cd = new ContentDocument();
       	String documentid;
        String InvoiceName = String.ValueOf([SELECT Name FROM Invoice__c WHERE Id =: id]);
        InvoiceName = InvoiceName.substringBetween('=', ',');

            List<ContentDocumentLink> listContentDocLink = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: id];
            List<String> listContentDocIds = new List<String> ();
            List<ContentVersion> listContentVersion = new List<ContentVersion> ();
        
        
            for(Integer i=0; i<listContentDocLink.size(); i++){
                String preFormatting = String.valueOf(listContentDocLink[i]);
                String postFormatting = preFormatting.substringBetween('=', ',');
                listContentDocIds.add(postFormatting);
                listContentVersion.add([SELECT Title FROM ContentVersion WHERE ContentDocumentId =: postFormatting LIMIT 1]);
            }
            
            system.debug(listContentVersion);
        
            for(Integer i=0; i<listContentVersion.size(); i++){
                String preFormatting = String.valueOf(listContentVersion[i]);
                String postFormatting = preFormatting.subStringBetween('=',',');
                
                if(postFormatting == InvoiceName + ' ' + 'Invoice PDF'){
                   documentid = listContentDocIds[i];
                }
                
            }
        	System.debug(documentid);
        	
            if(documentid != null){  
                
            ContentVersion cont = new ContentVersion(); 
                if(Test.isRunningTest()) { 
  					cont.VersionData = blob.valueOf('Unit.Test');
        		}
        		else{
        			cont.VersionData = pdfPage.getContentAsPDF();
        		}
                cont.Title = InvoiceName + ' ' + 'Invoice PDF';
                cont.PathOnClient = InvoiceName + ' ' + 'Invoice PDF.pdf';
                cont.ContentDocumentId = documentid;
                cont.ReasonForChange = 'New Version Upladed by User';
                cont.IsMajorVersion = true;
        
            insert cont;
            }
            
            else{
                
            ContentVersion cont = new ContentVersion(); 
                if(Test.isRunningTest()) { 
  					cont.VersionData = blob.valueOf('Unit.Test');
        		}
        		else{
        			cont.VersionData = pdfPage.getContentAsPDF();
        		}
                cont.Title = InvoiceName + ' ' + 'Invoice PDF';
                cont.PathOnClient = InvoiceName + ' ' + 'Invoice PDF.pdf';
                
                insert cont;
        
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cont.Id].ContentDocumentId;
                cdl.LinkedEntityId = id;
                cdl.Visibility = 'AllUsers';
                cdl.ShareType = 'I';
                
                insert cdl;
            
            }
		}
        return ids;
    }    
}