public class DocTrained {

    // custom field URLs hardcoded, DML and SOQL are OK

    Training_Item__c t;
    String Question1;
    String Question1A;
    String Question1B;
    String Question1C;
    String Question1D;
    String Question2;
    String Question2A;
    String Question2B;
    String Question2C;
    String Question2D;
    String Question3;
    String Question3A;
    String Question3B;
    String Question3C;
    String Question3D;
    String Question4;
    String Question4A;
    String Question4B;
    String Question4C;
    String Question4D;
    String Question5;
    String Question5A;
    String Question5B;
    String Question5C;
    String Question5D;
    String name;
    String titemId;
    
    public DocTrained(ApexPages.StandardController controller){

        //titemId = ApexPages.currentPage().getParameters().get('CF00NJ0000002MOgw_lkid');
        titemId = ApexPages.currentPage().getParameters().get('CF00N0B000005u68Q_lkid');
        t =[Select Name, Question_1__c, Question_1_Choice_A__c, Question_1_Choice_B__c, Question_1_Choice_C__c, Question_1_Choice_D__c,  
             Question_2__c, Question_2_Choice_A__c, Question_2_Choice_B__c, Question_2_Choice_C__c, Question_2_Choice_D__c, 
             Question_3__c, Question_3_Choice_A__c, Question_3_Choice_B__c, Question_3_Choice_C__c, Question_3_Choice_D__c, 
             Question_4__c, Question_4_Choice_A__c, Question_4_Choice_B__c, Question_4_Choice_C__c, Question_4_Choice_D__c, 
             Question_5__c, Question_5_Choice_A__c, Question_5_Choice_B__c, Question_5_Choice_C__c, Question_5_Choice_D__c 
             from Training_Item__c where Id =:titemId];  
        name = t.name;
        system.debug('TESTING TESTING TESTING' + titemId);
        Question1=t.Question_1__c;
        Question1A=t.Question_1_Choice_A__c; 
        Question1B=t.Question_1_Choice_B__c; 
        Question1C=t.Question_1_Choice_C__c; 
        Question1D=t.Question_1_Choice_D__c;
        Question2=t.Question_2__c;
        Question2A=t.Question_2_Choice_A__c; 
        Question2B=t.Question_2_Choice_B__c; 
        Question2C=t.Question_2_Choice_C__c; 
        Question2D=t.Question_2_Choice_D__c;
        Question3=t.Question_3__c;
        Question3A=t.Question_3_Choice_A__c; 
        Question3B=t.Question_3_Choice_B__c; 
        Question3C=t.Question_3_Choice_C__c; 
        Question3D=t.Question_3_Choice_D__c;
        Question4=t.Question_4__c;
        Question4A=t.Question_4_Choice_A__c; 
        Question4B=t.Question_4_Choice_B__c; 
        Question4C=t.Question_4_Choice_C__c; 
        Question4D=t.Question_4_Choice_D__c;
        Question5=t.Question_5__c;
        Question5A=t.Question_5_Choice_A__c; 
        Question5B=t.Question_5_Choice_B__c; 
        Question5C=t.Question_5_Choice_C__c; 
        Question5D=t.Question_5_Choice_D__c;

    }
    
    public PageReference newDocTrain(){
        //PageReference pr = new PageReference('/a0i/e?CF00NJ0000002MOgw='+name+'&CF00NJ0000002MOgw_lkid='+titemId+'&retURL='+titemId);
        PageReference pr = new PageReference('/a1b/e?CF00N0B000005u68Q='+name+'&CF00N0B000005u68Q_lkid='+titemId+'&retURL='+titemId);
        pr.getParameters().put('nooverride','1');
        /*pr.getParameters().put('00NJ0000002MPzp', Question1);
        pr.getParameters().put('00NJ0000002MPzu', Question1A);
        pr.getParameters().put('00NJ0000002MPzz', Question1B);
        pr.getParameters().put('00NJ0000002MQ04', Question1C);
        pr.getParameters().put('00NJ0000002MQ09', Question1D);
        pr.getParameters().put('00NJ0000002MQ0E', Question2);
        pr.getParameters().put('00NJ0000002MQ0J', Question2A);
        pr.getParameters().put('00NJ0000002MQ0O', Question2B);
        pr.getParameters().put('00NJ0000002MQ0T', Question2C);
        pr.getParameters().put('00NJ0000002MQ0Y', Question2D);
        pr.getParameters().put('00NJ0000002MQ0d', Question3);
        pr.getParameters().put('00NJ0000002MQ0i', Question3A);
        pr.getParameters().put('00NJ0000002MQ0n', Question3B);
        pr.getParameters().put('00NJ0000002MQ0s', Question3C);
        pr.getParameters().put('00NJ0000002MQ0x', Question3D);
        pr.getParameters().put('00NJ0000002MQ12', Question4);
        pr.getParameters().put('00NJ0000002MQ17', Question4A);
        pr.getParameters().put('00NJ0000002MQ1C', Question4B);
        pr.getParameters().put('00NJ0000002MQ1H', Question4C);
        pr.getParameters().put('00NJ0000002MQ1M', Question4D);
        pr.getParameters().put('00NJ0000002MQ1R', Question5);
        pr.getParameters().put('00NJ0000002MQ1W', Question5A);
        pr.getParameters().put('00NJ0000002MQ1b', Question5B);
        pr.getParameters().put('00NJ0000002MQ1g', Question5C);
        pr.getParameters().put('00NJ0000002MQ1l', Question5D);*/
        pr.getParameters().put('00N0B000005u684', Question1);
        pr.getParameters().put('00N0B000005u680', Question1A);
        pr.getParameters().put('00N0B000005u681', Question1B);
        pr.getParameters().put('00N0B000005u682', Question1C);
        pr.getParameters().put('00N0B000005u683', Question1D);
        pr.getParameters().put('00N0B000005u689', Question2);
        pr.getParameters().put('00N0B000005u685', Question2A);
        pr.getParameters().put('00N0B000005u686', Question2B);
        pr.getParameters().put('00N0B000005u687', Question2C);
        pr.getParameters().put('00N0B000005u688', Question2D);
        pr.getParameters().put('00N0B000005u68E', Question3);
        pr.getParameters().put('00N0B000005u68A', Question3A);
        pr.getParameters().put('00N0B000005u68B', Question3B);
        pr.getParameters().put('00N0B000005u68C', Question3C);
        pr.getParameters().put('00N0B000005u68D', Question3D);
        pr.getParameters().put('00N0B000005u68J', Question4);
        pr.getParameters().put('00N0B000005u68F', Question4A);
        pr.getParameters().put('00N0B000005u68G', Question4B);
        pr.getParameters().put('00N0B000005u68H', Question4C);
        pr.getParameters().put('00N0B000005u68I', Question4D);
        pr.getParameters().put('00N0B000005u68O', Question5);
        pr.getParameters().put('00N0B000005u68K', Question5A);
        pr.getParameters().put('00N0B000005u68L', Question5B);
        pr.getParameters().put('00N0B000005u68M', Question5C);
        pr.getParameters().put('00N0B000005u68N', Question5D);
        pr.setRedirect(false);
        return pr;
    }
}