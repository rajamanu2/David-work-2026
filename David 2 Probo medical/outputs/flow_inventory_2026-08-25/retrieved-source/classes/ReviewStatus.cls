public  class ReviewStatus {
    ProductItem__c  p;
    String reviewStatus,Name;
    String pitemId;
    public ReviewStatus(ApexPages.StandardController controller) {
         pitemId = ApexPages.currentPage().getParameters().get('CF00NU00000060eU3_lkid');
        // system.debug('pitemId================'+pitemId);
         p =[Select Review_Status__c,Name from ProductItem__c where Id =:pitemId];
         reviewStatus=p.Review_Status__c;
         Name=p.Name;
    }
     public PageReference newReviewStatus() {
        PageReference pr = new PageReference('/a0n/e?&CF00NU00000060eU3_lkid='+pitemId+'&retURL='+pitemId+'&CF00NU00000060eU3='+Name+'&00NU00000060eU2='+reviewStatus);
        pr.getParameters().put('nooverride','1');
        pr.setRedirect(false);
        return pr;
    }
}