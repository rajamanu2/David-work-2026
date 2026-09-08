public class QuoteLineDeleteHandler {

    public static void resetPriceChangeOnSource(List<SBQQ__QuoteLine__c> deletedLines) {
        Set<Id> sourceIds = new Set<Id>();

        for (SBQQ__QuoteLine__c ql : deletedLines) {
            if (ql.SBQQ__Source__c != null) {
                sourceIds.add(ql.SBQQ__Source__c);
            }
        }

        if (!sourceIds.isEmpty()) {
            // Run asynchronously so the update happens AFTER CPQ's save
            // pipeline finishes upserting the remaining quote lines.
            System.enqueueJob(new ResetPriceChangeJob(sourceIds));
        }
    }

    public class ResetPriceChangeJob implements Queueable {
        private Set<Id> sourceIds;

        public ResetPriceChangeJob(Set<Id> sourceIds) {
            this.sourceIds = sourceIds;
        }

        public void execute(QueueableContext ctx) {
            List<SBQQ__QuoteLine__c> sourceLines = [
                SELECT Id, Price_Change__c
                FROM SBQQ__QuoteLine__c
                WHERE Id IN :sourceIds
                  AND Price_Change__c = true
            ];

            for (SBQQ__QuoteLine__c sl : sourceLines) {
                sl.Price_Change__c = false;
            }

            if (!sourceLines.isEmpty()) {
                SBQQ.TriggerControl.disable();
                update sourceLines;
                SBQQ.TriggerControl.enable();
            }
        }
    }
}