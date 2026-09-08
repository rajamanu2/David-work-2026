/*
 * Passfort API calls
 * Test class: PassfortTest 
 * */

public class Passfort {
    
    public static HttpResponse getProfileDetails(String profileId) {
        // Endpoint URL with the profile ID
        //String endpoint = 'https://api.passfort.com/4.0/profiles/' + EncodingUtil.urlEncode(profileId, 'UTF-8');
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:PassfortAPI/profiles/' + EncodingUtil.urlEncode(profileId, 'UTF-8'));
        //req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        //req.setHeader('apikey', apiKey);
        Http http = new Http();
        HTTPResponse res;
        try {
            res = http.send(req);
            System.debug('Profile get Response BODY');
            System.debug(res.getBody());
        } catch(System.CalloutException e) {
            System.debug('Profile get Response Callout error: ' + e);
            res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('getProfileDetails Callout error: ' + e.getMessage());
        }
        return res;
    }
    
    public static HttpResponse getProfileApplications(String profileId) {
        //String endpoint = 'https://api.passfort.com/4.0/profiles/' + EncodingUtil.urlEncode(profileId, 'UTF-8')+'/applications';
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:PassfortAPI/profiles/' + EncodingUtil.urlEncode(profileId, 'UTF-8')+'/applications');
        //req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        //req.setHeader('apikey', apiKey);
        Http http = new Http();
        HTTPResponse res;
        try {
            res = http.send(req);
            System.debug('Profile Applications get Response BODY');
            System.debug(res.getBody());
        } catch(System.CalloutException e) {
            System.debug('Profile Applications get Response Callout error: ' + e);
            res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Callout error: ' + e.getMessage());
        }
        return res;
    }
    
    public static HttpResponse getProductApplication(String profileId, string applicationId) {
        //String endpoint = 'https://api.passfort.com/4.0/profiles/' + EncodingUtil.urlEncode(profileId, 'UTF-8') ;
        //endpoint = endpoint + '/applications/'+EncodingUtil.urlEncode(applicationId, 'UTF-8');
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:PassfortAPI/profiles/' + EncodingUtil.urlEncode(profileId, 'UTF-8')+'/applications'+EncodingUtil.urlEncode(applicationId, 'UTF-8'));
        //req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        //req.setHeader('apikey', apiKey);
        Http http = new Http();
        HTTPResponse res;
        try {
            res = http.send(req);
            System.debug('Profile Application get Response BODY');
            System.debug(res.getBody());
        } catch(System.CalloutException e) {
            System.debug('Profile Application get Response Callout error: ' + e);
            res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Callout error: ' + e.getMessage());
        }
        return res;
    }
    
    
    /*
     //Make it dynamic for the implmentaion
    //static only for POC
    
    //Passfort.uploadDocuments('0018W00001rvWGqQAM');
    public static void uploadDocuments(string accountId){
        
        Account accountVar = new Account();
        accountVar = [select Id , Name, Passfort_Profile_Id__c from Account  where Id =: accountId];
        // Ensure that an Account ID is provided
        if (accountId == null || accountVar.Passfort_Profile_Id__c == null) {
            throw new IllegalArgumentException('Account ID or Passfort_Profile_Id__c cannot be null');
        }
        
        List<ContentDocumentLink> cdls = [SELECT ContentDocumentId   FROM ContentDocumentLink WHERE LinkedEntityId = :accountId];
        Set<Id> documentIds = new Set<Id>();
        for (ContentDocumentLink cdl : cdls) {
            documentIds.add(cdl.ContentDocumentId);
        }
        
        List<ContentVersion> ContentVersiondocuments = [SELECT  Title  , VersionData, ContentBodyId , ContentDocumentId 
                                                        FROM ContentVersion WHERE ContentDocumentId  IN :documentIds
                                                       LIMIT 1];
        for(ContentVersion c1 : ContentVersiondocuments){
            System.debug('documentIds size: '+c1.Title);
        }
        
        System.debug('ContentVersiondocuments size: '+ContentVersiondocuments.size());
        System.debug('documentIds size: '+documentIds.size());
        
        // Access the VersionData (Blob data)
        String fileContent = EncodingUtil.base64Encode(ContentVersiondocuments[0].VersionData);
        String fileName = ContentVersiondocuments[0].Title;
        
        System.debug('File Name:'+fileName);
        string profileId = accountVar.Passfort_Profile_Id__c;
        HTTPResponse response = uploadToPassfort(profileId,fileContent,fileName);
    }


    public static HttpResponse uploadToPassfort(String profileId, String data, String name) {
        // Endpoint URL with the profile ID
        String endpoint = 'https://api.passfort.com/4.0/profiles/' + EncodingUtil.urlEncode(profileId, 'UTF-8') + '/files';
        // Instantiate a new HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', apiKey);

        // Create the JSON request body
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('data', data);
        gen.writeStringField('name', name);
        gen.writeEndObject();
        String requestBody = gen.getAsString();
        req.setBody(requestBody);

        // Create a new HTTP object and send the request
        Http http = new Http();
        HTTPResponse res;
        try {
            res = http.send(req);
            System.debug('API Response BODY');
            System.debug(res.getBody());
        } catch(System.CalloutException e) {
            // Exception handling
            System.debug('Callout error: ' + e);
            res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Callout error: ' + e.getMessage());
        }
        return res;
    }
    
    public static void getDocuments(string accountId){
        
        Account accountVar = new Account();
        accountVar = [select Id , Name, Passfort_Profile_Id__c from Account  where Id =: accountId];
        string profileId = accountVar.Passfort_Profile_Id__c;
        string fileId ='';
        HttpResponse response1 = Passfort.getFileFromPassfort( profileId, fileId);
         // Parse the JSON response
        GETFileResponse fileVar = (GETFileResponse) JSON.deserialize(response1.getBody(), GETFileResponse.class);
        // Convert Base64 String to a Blob
        Blob pdfBlob = EncodingUtil.base64Decode(fileVar.decrypted_data.substringAfter('base64,'));

        // Create the Attachment object
        Attachment attachment = new Attachment();
        attachment.ParentId = accountId; 
        attachment.Name = fileVar.name + '.pdf'; // Set the file name
        attachment.Body = pdfBlob; // Set the Blob as the body of the attachment
        
        // Insert the attachment
        try {
            insert attachment;
            System.debug('Attachment successfully added to the account.');
        } catch (DmlException e) {
            System.debug('An error occurred while inserting the attachment: ' + e);
        }
    }

	public class GETFileResponse {
        public String id;
        public String name;
        public String decrypted_data;
    }
    
    public static HttpResponse getFileFromPassfort(String profileId, String fileId) {
        String endpoint = 'https://api.passfort.com/4.0/profiles/' + EncodingUtil.urlEncode(profileId, 'UTF-8');
        endpoint = endpoint + '/files/'+ EncodingUtil.urlEncode(fileId, 'UTF-8') ;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', apiKey);
        Http http = new Http();
        HTTPResponse res;
        try {
            res = http.send(req);
            // Handle the response as needed
            System.debug('GET FILE API Response BODY');
            System.debug(res.getBody());
        } catch(System.CalloutException e) {
            // Exception handling
            System.debug('GET FILE API Callout error: ' + e);
            res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Callout error: ' + e.getMessage());
        }
        return res;
    }
		//public static string apiKey = '1ec7fcc5511b8d7bff0e459da200769f48f1cd333e4477b4';
     * */
    
}