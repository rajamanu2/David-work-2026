// Read-only synthetic transform inputs; no Salesforce test/business records created.
Integer tested=0;
for(Boolean grouped:new List<Boolean>{true,false}){
    List<Object> rows=new List<Object>(); List<String> expected=new List<String>();
    for(String descriptionText:new List<String>{null,'Base description'}){
        for(String rate:new List<String>{null,'USD 10 per unit'}){
            for(String typ:new List<String>{'New','Renewal','Cancellation','Quantity Increase','Quantity Reduction'}){
                String text=descriptionText==null?'':descriptionText;
                if(rate!=null)text+=(text==''?'':' ')+rate;
                if(typ=='Cancellation'||typ=='Quantity Increase'||typ=='Quantity Reduction')text+=(text==''?'':' ')+'('+typ+')';
                rows.add(new Map<String,Object>{'ProductName'=>'Case'+rows.size(),'LineDescription'=>descriptionText,'RateDetails'=>rate,'QuoteLineType'=>typ});
                expected.add(text);
            }
        }
    }
    Map<String,Object> input=new Map<String,Object>{'QuoteLineGroupsPresent'=>grouped?'true':'false','MultipleShipToAccounts'=>'No'};
    if(grouped)input.put('QuoteLineGroup',new List<Object>{new Map<String,Object>{'Name'=>'Synthetic','Number'=>1,'SubscriptionTerm'=>12,'QuoteLine'=>rows}});
    else input.put('UngroupedLine',rows);
    omnistudio.DRProcessResult result=omnistudio.DRGlobal.processFromApex(input,'CPQQuoteProposalDocumentSteppedUpPricing');
    System.assertEquals(false,result.hasErrors(),'Native transform errors');
    Map<String,Object> output=(Map<String,Object>)result.toJson();
    List<Object> actual;
    if(grouped){
        Object groupValue=output.get('Group');
        Map<String,Object> groupRow=groupValue instanceof List<Object>?(Map<String,Object>)((List<Object>)groupValue)[0]:(Map<String,Object>)groupValue;
        actual=(List<Object>)groupRow.get('QuoteLine');
    }else actual=(List<Object>)output.get('Line');
    System.assertEquals(20,actual.size(),'Case count');
    for(Integer i=0;i<20;i++){
        Map<String,Object> row=(Map<String,Object>)actual[i];
        String value=(String)row.get('LineDescriptionWithType');
        System.assertEquals(expected[i],value==null?'':value,'Description case '+i+' grouped='+grouped);
        tested++;
    }
}
System.debug(LoggingLevel.ERROR,'NATIVE_FORMULA_PASS|'+tested);
