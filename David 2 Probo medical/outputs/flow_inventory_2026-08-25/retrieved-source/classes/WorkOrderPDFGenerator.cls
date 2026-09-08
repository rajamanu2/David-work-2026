public class WorkOrderPDFGenerator {
@InvocableMethod
	public static List<String> getWorkOrderPDF(List<ID> ids) {
        for(ID id: ids){
        
        WorkOrder wo = [SELECT id, WorkOrderNumber, Work_Order_PDF_Type__c FROM WorkOrder WHERE Id =: id];
            if(wo.Work_Order_PDF_Type__c=='Field Service Report'){
                        PageReference pdfPage = new PageReference('/apex/Field_Service_Report_PDF');
                        pdfPage.getParameters().put('ID', id);
                     
                ContentDocument cd = new ContentDocument();
                String documentid;
        
                    List<ContentDocumentLink> listContentDocLink = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: id];
                    List<String> listContentDocIds = new List<String> ();
                    List<ContentVersion> listContentVersion = new List<ContentVersion> ();
                
                
                    for(Integer i=0; i<listContentDocLink.size(); i++){
                        String preFormatting = String.valueOf(listContentDocLink[i]);
                        String postFormatting = preFormatting.substringBetween('=', ',');
                        listContentDocIds.add(postFormatting);
                        listContentVersion.add([SELECT Title FROM ContentVersion WHERE ContentDocumentId =: postFormatting]);
                    }
                    
                    system.debug(listContentVersion);
                
                    for(Integer i=0; i<listContentVersion.size(); i++){
                        String preFormatting = String.valueOf(listContentVersion[i]);
                        String postFormatting = preFormatting.subStringBetween('=',',');
                        
                        if(postFormatting == wo.WorkOrderNumber + ' ' + 'FSR PDF'){
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
                        cont.Title = wo.WorkOrderNumber + ' ' + 'FSR PDF';
                        cont.PathOnClient = wo.WorkOrderNumber + ' ' + 'FSR PDF.pdf';
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
                        cont.Title = wo.WorkOrderNumber + ' ' + 'FSR PDF';
                        cont.PathOnClient = wo.WorkOrderNumber + ' ' + 'FSR PDF.pdf';
                        
                        insert cont;
                
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cont.Id].ContentDocumentId;
                        cdl.LinkedEntityId = id;
                        cdl.Visibility = 'AllUsers';
                        cdl.ShareType = 'I';
                        
                        insert cdl;
                    
                    }                
                }
            else if(wo.Work_Order_PDF_Type__c=='Preventative Maintenance Report'){
                
                PageReference pdfPage = new PageReference('/apex/Preventative_Maintenance_Report_PDF');
                pdfPage.getParameters().put('ID', id);
                     
                ContentDocument cd = new ContentDocument();
                String documentid;
        
                    List<ContentDocumentLink> listContentDocLink = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: id];
                    List<String> listContentDocIds = new List<String> ();
                    List<ContentVersion> listContentVersion = new List<ContentVersion> ();
                
                
                    for(Integer i=0; i<listContentDocLink.size(); i++){
                        String preFormatting = String.valueOf(listContentDocLink[i]);
                        String postFormatting = preFormatting.substringBetween('=', ',');
                        listContentDocIds.add(postFormatting);
                        listContentVersion.add([SELECT Title FROM ContentVersion WHERE ContentDocumentId =: postFormatting]);
                    }
                    
                    system.debug(listContentVersion);
                
                    for(Integer i=0; i<listContentVersion.size(); i++){
                        String preFormatting = String.valueOf(listContentVersion[i]);
                        String postFormatting = preFormatting.subStringBetween('=',',');
                        
                        if(postFormatting == wo.WorkOrderNumber + ' ' + 'PMR PDF'){
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
                        cont.Title = wo.WorkOrderNumber + ' ' + 'PMR PDF';
                        cont.PathOnClient = wo.WorkOrderNumber + ' ' + 'PMR PDF.pdf';
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
                        cont.Title = wo.WorkOrderNumber + ' ' + 'PMR PDF';
                        cont.PathOnClient = wo.WorkOrderNumber + ' ' + 'PMR PDF.pdf';
                        
                        insert cont;
                
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cont.Id].ContentDocumentId;
                        cdl.LinkedEntityId = id;
                        cdl.Visibility = 'AllUsers';
                        cdl.ShareType = 'I';
                        
                        insert cdl;
                    
                    }
                }                              
            }
        return ids;
	}
}