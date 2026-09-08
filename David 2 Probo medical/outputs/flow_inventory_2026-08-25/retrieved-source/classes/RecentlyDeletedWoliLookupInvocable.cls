public with sharing class RecentlyDeletedWoliLookupInvocable {
    private static final Integer RECENT_WINDOW_SECONDS = 5;

    public class Request {
        @InvocableVariable(required=true)
        public Id workOrderId;
    }

    public class Response {
        @InvocableVariable
        public Id workOrderId;

        @InvocableVariable
        public String lineIntent;
    }

    @InvocableMethod(label='Get Recently Deleted Work Order Line Item Intent' description='Returns Work Order Id and Line_Intent__c when the current user deleted a Work Order Line Item on that Work Order in the last 10 seconds.')
    public static List<Response> getRecentlyDeletedLineIntent(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        Set<Id> workOrderIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.workOrderId != null) {
                workOrderIds.add(req.workOrderId);
            }
        }

        Map<Id, WorkOrderLineItem> latestDeletedByWo = new Map<Id, WorkOrderLineItem>();
        if (!workOrderIds.isEmpty()) {
            Datetime cutoff = System.now().addSeconds(-RECENT_WINDOW_SECONDS);
            List<WorkOrderLineItem> deletedWolis = [
                SELECT Id, WorkOrderId, Line_Intent__c, LastModifiedDate, LastModifiedById
                FROM WorkOrderLineItem
                WHERE IsDeleted = true
                  AND WorkOrderId IN :workOrderIds
                  AND LastModifiedById = :UserInfo.getUserId()
                  AND LastModifiedDate >= :cutoff
                ORDER BY LastModifiedDate DESC
                ALL ROWS
            ];

            for (WorkOrderLineItem woli : deletedWolis) {
                if (!latestDeletedByWo.containsKey(woli.WorkOrderId)) {
                    latestDeletedByWo.put(woli.WorkOrderId, woli);
                }
            }
        }

        for (Request req : requests) {
            Response res = new Response();
            if (req != null && req.workOrderId != null && latestDeletedByWo.containsKey(req.workOrderId)) {
                WorkOrderLineItem match = latestDeletedByWo.get(req.workOrderId);
                res.workOrderId = match.WorkOrderId;
                res.lineIntent = match.Line_Intent__c;
            }
            responses.add(res);
        }

        return responses;
    }
}