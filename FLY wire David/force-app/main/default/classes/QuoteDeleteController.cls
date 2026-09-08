public with sharing class QuoteDeleteController {

    private Id quoteId;
    public String toastMessage { get; set; }
    public String toastType { get; set; }

    public QuoteDeleteController(ApexPages.StandardController stdController) {
        this.quoteId = stdController.getId();
    }

    public Boolean getHasApexMessages() {
        return ApexPages.hasMessages();
    }

    public PageReference tryDelete() {

        if (isQuoteDeletable()) {
            try {
                // If deletion is successful, redirect to the Opportunity
                Database.delete(quoteId);
                toastType = 'success';
                toastMessage = 'The quote has been successfully deleted.';
            } catch (Exception ex) {
                ApexPages.addMessages(ex);
            }
        }

        return null;
    }

    private Boolean isQuoteDeletable() {
        Boolean isDeletable = true;

        try {
            SBQQ__Quote__c quote = [
                SELECT Id, SBQQ__Opportunity2__r.IsClosed, ApprovalStatus__c, SBQQ__Opportunity2__r.Type
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
                LIMIT 1
            ];

            if (quote.SBQQ__Opportunity2__r.IsClosed) {
                toastType = 'error';
                toastMessage = 'You can\'t delete quotes on closed opportunities.';                
                isDeletable = false;
            }
            if (quote.ApprovalStatus__c == 'Approved' || quote.ApprovalStatus__c == 'Pending' || quote.ApprovalStatus__c == 'Recalled') {
                toastType = 'error';
                toastMessage = 'You can\'t delete quotes that are approved or pending approval.';
                isDeletable = false;
            }
            if (quote.SBQQ__Opportunity2__r.Type != 'New Business') {
                toastType = 'error';
                toastMessage = 'You can only delete quotes on New Business opportunities.';
                isDeletable = false;
            }

        } catch (Exception ex) {
            toastType = 'error';
            toastMessage = 'An unexpected error occurred while checking if the quote can be deleted: ' + ex.getMessage();
            isDeletable = false;
        }
        return isDeletable;
    }
}