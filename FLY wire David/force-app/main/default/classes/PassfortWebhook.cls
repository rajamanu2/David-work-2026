/*
 * Receives the passfort webhook data
 * Test class: PassfortTest 
 * */
@RestResource(urlMapping='/passfortwebhook')
global without sharing class PassfortWebhook {

    @HttpPost
    global static void handlePostBatch() {
        Set<String> profileIds = new Set<String>();
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.tostring();
        String logRequestBody = requestBody.length() > 131071 ? requestBody.substring(0, 131072) : requestBody;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {        
            // Deserialize the JSON        
            List<Object> tasksBatch = (List<Object>)JSON.deserializeUntyped(requestBody);
            List<Map<String,Object>> tasksBatchMaps = new List<Map<String,Object>>();

			if (tasksBatch != null && !tasksBatch.isEmpty()) {
				for (Object currentTask : tasksBatch) {
					tasksBatchMaps.add((Map<String,Object>) currentTask);
				}

				for(Map<String,Object> currentTaskMap : tasksBatchMaps) {
                    Map<String, Object> currentData = new  Map<String, Object>();

                    if(currentTaskMap != null && currentTaskMap.get('data') != null) {
                        currentData = (Map<String, Object>)currentTaskMap.get('data');
					}

					if(currentData != null && currentData.get('profile_id') != null) {
                        String profileId = (String)currentData.get('profile_id');
                        profileIds.add(profileId);
					}
				}

                System.debug('PassfortWebhook.handlePost - profileIds found: ');
                for (String currentProfileId : profileIds) {
                    System.debug(currentProfileId);
                }
            }
                    
            res.statuscode = 200;
            Boolean success = !profileIds.isEmpty() ? true : false;
            String msg = !profileIds.isEmpty() ? 'request received' : 'profileIds not found';
            res.responseBody = Blob.valueof(JSON.serialize(new WebhookResponse(success, msg, profileIds)));

            handleProfileIds(logRequestBody, profileIds);
        } catch (Exception e) {
            handleError(500, logRequestBody, e, res, profileIds);
        }
    }

    private static void handleError(Integer resStatus, String logRequestBody, Exception e, RestResponse res, Set<String> profileIds) {
        Passfort_Webhook_Log__c  errorLog = new Passfort_Webhook_Log__c ();
        errorlog.Request_body__c = logRequestBody;
        errorLog.Status__c = 'Error';
        String logMessage = e.getMessage();
        logMessage = logMessage.length() > 131071 ? logMessage.substring(0, 131072) : logMessage;
        errorLog.Message__c = logMessage;
        insert errorLog;

        res.statusCode = resStatus;
        res.responseBody = Blob.valueof(JSON.serialize(new WebhookResponse(false, e.getMessage(), profileIds)));
    }

    private static void handleProfileIds(String reqBody, Set<String> profileIds) {
        PassfortProfileBatchProcessor batchProcessor = new PassfortProfileBatchProcessor(profileIds, reqBody);
        // Max queue size is 50 but can produce CPU time limit exceptions
        Database.executeBatch(batchProcessor, 5);
    }
    
    //Response body
    public class WebhookResponse{
        Boolean success;
        String message;
        Set<String> profileIds;

        public WebHookResponse(Boolean succ, String msg, Set<String> ids) {
            success = succ;
            message = msg;
            profileIds = ids;
        }
    }

    //Custom exception
    public class RequestBodyException extends Exception {}
}