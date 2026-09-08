public class OpportunityStageControler {

      public Decimal OpportunityShippedMonthtoDate{get;set;}
      public Decimal OpportunityLostMonthtoDate{get;set;}
      public Decimal TotalOpportunityMonthtoDate{get;set;}
      Decimal temp;
      public Decimal WinRateMonthtoDate{get;set;}
      public Decimal WinRateValueMonthtoDate{get;set;}
      public String TotalOpportunityValueMonthtoDate{get;set;}
      public String TotalOpportunityValueShippedMonthtoDate{get;set;}
      //Public Decimal temp1;
      //Public Decimal temp2;
      
      public Decimal OpportunityShippedQuartertoDate{get;set;}
      public Decimal OpportunityLostQuartertoDate{get;set;}
      public Decimal TotalOpportunityQuartertoDate{get;set;}
      Decimal temp1;
      public Decimal WinRateQuartertoDate{get;set;}
      public Decimal WinRateValueQuartertoDate{get;set;}
      public String TotalOpportunityValueQuartertoDate{get;set;}
      public String TotalOpportunityValueShippedQuartertoDate{get;set;}
      //Public Decimal temp3;
      //Public Decimal temp4;
      Public Decimal temp2;
      Public Decimal temp3;
      Public Decimal temp4;
      Public Decimal temp5;
      
      list<Opportunity> opplist;
      list<OpportunityLineItem> opplist1;
      
      list<Opportunity> opplist2;
      list<OpportunityLineItem> opplist3;
      
      list<AggregateResult> opplist4;
      list<AggregateResult> opplist5;
      
      list<AggregateResult> opplist6;
      list<AggregateResult> opplist7;
      
      
      
    public OpportunityStageControler() {
        
        opplist = [select id,StageName from Opportunity where StageName = 'Closed Won' and Ship_Date__c = THIS_MONTH and OwnerId =: UserInfo.getUserId()];
        opplist1 = [select Opportunity.id,Opportunity.StageName from OpportunityLineItem where Opportunity.StageName != 'Closed Won' and Opportunity.Createddate = THIS_MONTH and Opportunity.OwnerId =:UserInfo.getUserId() and ProductItem__r.Generic_Product__c = false];
        
        opplist2 = [select id,StageName from Opportunity where StageName = 'Closed Won' and Ship_Date__c = THIS_QUARTER and OwnerId =: UserInfo.getUserId()];
        opplist3 = [select Opportunity.id,Opportunity.StageName from OpportunityLineItem where Opportunity.StageName != 'Closed Won' and Opportunity.Createddate = THIS_QUARTER and Opportunity.OwnerId =: UserInfo.getUserId() and ProductItem__r.Generic_Product__c = false];
        
        OpportunityShippedMonthtoDate = opplist.size();
        OpportunityLostMonthtoDate = opplist1.size();
        TotalOpportunityMonthtoDate = OpportunityShippedMonthtoDate + OpportunityLostMonthtoDate;
        if(TotalOpportunityMonthtoDate!=0){
            temp = ((OpportunityShippedMonthtoDate/TotalOpportunityMonthtoDate) * 100);
        }else{
            temp = 0;
        }
        WinRateMonthtoDate = temp.setscale(2);
        
        
        OpportunityShippedQuartertoDate = opplist2.size();
        OpportunityLostQuartertoDate = opplist3.size();
        TotalOpportunityQuartertoDate = OpportunityShippedQuartertoDate + OpportunityLostQuartertoDate;
        if(TotalOpportunityQuartertoDate!=0){
            temp1 = ((OpportunityShippedQuartertoDate/TotalOpportunityQuartertoDate) * 100);
        }else{
            temp1 = 0;
        }
        WinRateQuartertoDate = temp1.setscale(2);
        
        
        opplist4 = [select sum(TotalPrice) TotalAmount from OpportunityLineItem where Opportunity.Createddate = THIS_MONTH and Opportunity.OwnerId =: UserInfo.getUserId() and ProductItem__r.Generic_Product__c = false];
        String tempvalue = String.valueOf(opplist4[0].get('TotalAmount'));
        if(tempvalue!=null)
        temp2 = decimal.valueOf(tempvalue);
        //String temovalue1 = (String)
        TotalOpportunityValueMonthtoDate = currency(tempvalue);
        //temp1 = Decimal.valueOf(TotalOpportunityValueMonthtoDate);
        
        
        opplist5 = [select sum(TotalPrice) TotalAmount from OpportunityLineItem where Opportunity.Createddate = THIS_QUARTER and Opportunity.OwnerId =: UserInfo.getUserId() and ProductItem__r.Generic_Product__c = false];
        String tempvalue1 = String.valueOf(opplist5[0].get('TotalAmount'));
        if(tempvalue1!=null)
        temp3 = decimal.valueOf(tempvalue1);
        TotalOpportunityValueQuartertoDate = currency(tempvalue1);
        //temp3 = Decimal.valueOf(TotalOpportunityValueQuartertoDate);
        
        opplist6 = [select sum(Amount) TotalAmount from Opportunity where StageName = 'Closed Won' and Ship_Date__c = THIS_MONTH and OwnerId =: UserInfo.getUserId()];
        String tempvalue2 = String.valueOf(opplist6[0].get('TotalAmount'));
        System.debug('++++++++++++++++++++'+String.valueOf(opplist6[0].get('TotalAmount')));
        if(tempvalue2!=null)
        //System.debug('++++++++++++++++++++'+tempvalue2);
        //test.isRunningTest();
        temp4 = decimal.valueOf(tempvalue2);
        TotalOpportunityValueShippedMonthtoDate = currency(tempvalue2);
        //temp2 = Decimal.valueOf(TotalOpportunityValueShippedMonthtoDate);
        
        opplist7 = [select sum(Amount) TotalAmount from Opportunity where StageName = 'Closed Won' and Ship_Date__c = THIS_QUARTER and OwnerId =: UserInfo.getUserId()];
        String tempvalue3 = String.valueOf(opplist7[0].get('TotalAmount'));
        if(tempvalue3!=null)
        temp5 = decimal.valueOf(tempvalue3);
        TotalOpportunityValueShippedQuartertoDate = currency(tempvalue3);
        //temp4 = Decimal.valueOf(TotalOpportunityValueShippedQuartertoDate);
        
        if(temp2!=null && temp2!=0  && temp4!= null){
            temp = ((temp4/temp2) * 100);
        }else{
            temp = 0;
        }
        WinRateValueMonthtoDate = temp.setscale(2);
        
        if(temp3!=null && temp3!=0  && temp5!= null){
            temp1 = ((temp5/temp3) * 100);
        }else{
            temp1 = 0;
        }
        WinRateValueQuartertoDate = temp1.setscale(2);
        
    }
    public static String currency(String i) {
    String s = ( Decimal.valueOf(i==null||i.trim()==''?'0':i).setScale(2) + 0.001 ).format();
    return s.substring(0,s.length()-1);
}
}