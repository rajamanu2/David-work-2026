global class UpdateAccountBatch implements Database.Batchable<sObject>,Schedulable,Database.AllowsCallouts{
    
        String Query;
        
        global Database.QueryLocator start(Database.BatchableContext bc){
    
            Query = 'Select Id, OwnerId, Purchasing_Account_Owner__c, Total_Opportunities__c, Total_Opportunities_Last_90_Days__c, Total_Opportunities_Won__c, Total_Opportunities_Won_YTD__c, Total_Opportunities_Won_Last_90_Days__c, Total_Opportunity_Value__c, Total_Opportunity_Value_Last_90_Days__c, Total_Opportunities_Won_Value__c, Opportunity_Won_Value_YTD__c, Opportunity_Won_Value_Last_90_Days__c, First_Opportunity_Date__c, Most_Recent_Opportunity_Date__c, Total_Opportunity_Value_In_Stock__c, Total_Opportunities_In_Stock__c, Total_Opportunities_YTD__c, Total_Opportunity_Value_YTD__c from Account';                         
            return Database.getQueryLocator(query);
        }
         global void execute(Database.BatchableContext bc, List<Account> accountlist){
                
                 Set<Id> OppAcc = new Set<Id>();
                 for(Account a : accountlist)
                 {
                      OppAcc.add(a.Id);
                      
                 }
                // /* ------------------    Initial Set Up */
                 Decimal amount = 0.00, totOppValueInStock = 0.00, totalOppValue = 0.00,totalOppValue90d= 0.00, totalOppCloseWonValue=0.00 ,totalOppCloseWonValue90day=0.00,totalOppValueInStock=0.00, totalOppCloseWonValueYTD = 0.00, totaloppvalueYTD = 0.00;
             Integer totOppInStock=0, totalopponAccount = 0, totalopp90=0, totaloppCloseWon = 0, totalOppCloseWonYTD = 0, totaloppCloseWon90= 0, totaloppYTD = 0, totalpurch = 0, totalpurchclosewon = 0;

             //Id RTid;
             list<id> SalesOppRecordList = new list<id>(); 
             for (RecordType r : ProboCommonUtils.getRecordTypes('Opportunity')){
                 if (r.DeveloperName == 'Sales_Opportunity'|| r.DeveloperName == 'Big_Iron_Sales_Opportunity' || r.DeveloperName == 'C_Arm_Sales_Opportunity'
                    || r.DeveloperName == 'Parts_Sales_Opportunity' || r.DeveloperName == 'Probe_Sales_Opportunity' || r.DeveloperName == 'Rental_Opportunity'
                     /*|| r.DeveloperName == 'Service_Sales_Opportunity' */|| r.DeveloperName == 'System_Sales_Opportunity'){
                     //RTid = r.Id;
                     SalesOppRecordList.add(r.id);
                         //break
                 }
             }

             Datetime initialdatetime = Datetime.newinstance(3000, 01, 01), closedwonpurchasingdatetime = Datetime.newinstance(3000, 01, 01), closedwonsalesdatetime = Datetime.newinstance(3000, 01, 01), recentdatetime = Datetime.newinstance(1900, 01,01), lastactivityaccounttime = Datetime.newinstance(1900,01,01), lastactivitypurchasingtime = Datetime.newinstance(1900,01,01),currenttaskdatetime = Datetime.newinstance(1900,01,01);
                Date initialdate, recentdate, closedwonpurchasingdate, closedwonsalesdate, lastactivityaccount, lastactivitypurchasing;
             String InitialLeadSource = '';
             List<Opportunity> oppOnAccount=[Select id,CloseDate, RecordTypeId, Opp_Record_Type__c, CreatedDate,Amount,AccountId,StageName,Ship_Date__c, LeadSource From Opportunity Where AccountId IN :OppAcc ORDER BY CreatedDate DESC];
             //list<Opportunity> oppOnAccount2=[Select id,CloseDate, Opp_Record_Type__c, CreatedDate,Amount,AccountId, LeadSource From Opportunity Where AccountId IN :OppAcc and RecordTypeId =: RTid AND id in (Select OpportunityId From OpportunityLineItem where Check_In_Type__c = 'Generic' and (Product_Family__c = 'Ultrasound Probe' OR Product_Family__c = 'Ultrasound System') )];
             list<Opportunity> oppOnAccount2=[Select id,CloseDate, RecordTypeId, Opp_Record_Type__c, CreatedDate,Amount,AccountId, LeadSource From Opportunity Where AccountId IN :OppAcc and RecordTypeId IN :SalesOppRecordList AND id in (Select OpportunityId From OpportunityLineItem where Check_In_Type__c = 'Generic' and (Product_Family__c = 'Ultrasound Probe' OR Product_Family__c = 'Ultrasound System') )];
            // list<Task> TaskList = [select id, ActivityDate, Status, OwnerId, AccountId from Task where AccountId IN:OppAcc AND Status = 'Completed' ORDER BY ActivityDate DESC];
            // list<Event> EventList = [select id, ActivityDateTime, OwnerId, AccountId from Event where AccountId IN:OppAcc ORDER BY ActivityDate DESC];  
             System.debug('QUERIES FROM opp >>>>>>>>> ' + Limits.getQueries());
            
             for (account a:accountlist){
                amount = 0.00; totOppValueInStock = 0.00; totalOppValue = 0.00;totalOppValue90d= 0.00; totalOppCloseWonValue=0.00 ;totalOppCloseWonValue90day=0.00;totalOppValueInStock=0.00; totalOppCloseWonValueYTD = 0.00; totaloppvalueYTD = 0.00;
            totOppInStock=0; totalopponAccount = 0; totalopp90=0; totaloppCloseWon = 0; totalOppCloseWonYTD = 0; totaloppCloseWon90= 0; totaloppYTD = 0; totalpurch = 0; totalpurchclosewon = 0;
                initialdatetime = Datetime.newinstance(3000, 01, 01); recentdatetime = Datetime.newinstance(1900, 01,01); closedwonpurchasingdatetime = Datetime.newinstance(3000, 01, 01); closedwonsalesdatetime = Datetime.newinstance(3000, 01, 01);
                lastactivityaccount = Date.newInstance(1900,01,01); lastactivitypurchasing = Date.newInstance(1900,01,01);
                 initialleadsource = '';
                 //lastactivityaccounttime = Datetime.newinstance(1900,01,01); lastactivitypurchasingtime = Datetime.newinstance(1900,01,01);
                // currenttaskdatetime = datetime.newinstance(1900,01,01);
                 list<task> mostrecenttask = [select id, ActivityDate, Status, OwnerId, AccountId, LastModifiedDate from Task where AccountId =:a.id AND Status = 'Completed' AND OwnerId =: a.OwnerId AND ActivityDate != null AND (NOT Subject LIKE '%Mass Email%') ORDER BY ActivityDate DESC limit 1];
               list<task> mostrecenttaskpurchasing = [select id, ActivityDate, Status, OwnerId, AccountId from Task where AccountId =:a.id AND Status = 'Completed' AND OwnerId =: a.Purchasing_Account_Owner__c AND ActivityDate != null ORDER BY ActivityDate DESC limit 1];
              // list<event> mostrecentevent = [select id, ActivityDate, OwnerId, AccountId from Event where AccountId =:a.id AND OwnerId =: a.OwnerId ORDER BY ActivityDate DESC limit 1];
              // list<event> mostrecenteventpurchasing = [select id, ActivityDate, OwnerId, AccountId from Event where AccountId =:a.id AND OwnerId =: a.Purchasing_Account_Owner__c ORDER BY ActivityDate DESC limit 1];
              system.debug('THIS IS THE PURCHASING OWNER >>> ' + a.Purchasing_Account_Owner__c);
                 system.debug('THIS IS THE MOST RECENT TASK >>> ' + mostrecenttask);
                 system.debug('THIS IS THE MOST RECENT TASK PURCHASING >>> ' + mostrecenttaskpurchasing);
                 if(mostrecenttask.size() > 0){
                     lastactivityaccount = mostrecenttask[0].activitydate;
                 }
                 system.debug('THIS IS THE LAST ACTIVITY ACCOUNT >>>> ' + lastactivityaccount);
                 if(mostrecenttaskpurchasing.size() > 0){
                     lastactivitypurchasing = mostrecenttaskpurchasing[0].activitydate;
                 } 
                 system.debug('THIS IS THE LAST ACTIVITY PURCHASING >>>> ' + lastactivitypurchasing);
            /*     if(mostrecentevent.size() > 0){
                     if(mostrecentevent[0].activitydate > lastactivityaccount){
                         lastactivityaccount = mostrecentevent[0].activitydate;
                     }
                 }
                 if(mostrecenteventpurchasing.size() > 0){
                     if(mostrecenteventpurchasing[0].activitydate > lastactivitypurchasing){
                       lastactivitypurchasing = mostrecenteventpurchasing[0].activitydate;
                     }
                 } */
                 
                 /*
                 if(tasklist.size() > 0){
                     for(task t:tasklist){
                         if(t.AccountId == a.Id){
                             if(t.OwnerId == a.OwnerId){
                                 if(t.ActivityDate != null){
                                     currenttaskdatetime = Datetime.newinstance(t.ActivityDate.year(), t.ActivityDate.month(), t.ActivityDate.day());
                                 }
                                 if(currenttaskdatetime > lastactivityaccounttime){
                                     lastactivityaccounttime = currenttaskdatetime;
                                 }
                             }
                             if(a.Purchasing_Account_Owner__c != null){
                                 if(t.OwnerId == a.Purchasing_Account_Owner__c){
                                     if(t.ActivityDate != null){
                                        currenttaskdatetime = Datetime.newinstance(t.ActivityDate.year(), t.ActivityDate.month(), t.ActivityDate.day());
                                     }
                                     if(currenttaskdatetime > lastactivitypurchasingtime){
                                         lastactivitypurchasingtime = currenttaskdatetime;
                                     }
                                 }
                             }
                         }
                     }
                 }
                 if(eventlist.size() > 0){
                     for(event e:eventlist){
                         if(e.AccountId == a.Id){
                             if(e.OwnerId == a.OwnerId){
                                 if(e.ActivityDateTime != null){
                                    if(e.ActivityDateTime > lastactivityaccounttime){
                                       lastactivityaccounttime = e.ActivityDateTime;
                                   } 
                                 }
                             }
                             if(a.Purchasing_Account_Owner__c != null){
                                 if(e.OwnerId == a.Purchasing_Account_Owner__c){
                                     if(e.ActivityDateTime != null){
                                         if(e.ActivityDateTime > lastactivitypurchasing){
                                           lastactivitypurchasingtime = e.ActivityDateTime;
                                       }
                                     }
                                 }
                             }
                         }
                     }
                 }
                 */
                 
                 for(opportunity o : oppOnAccount)
                {
                    //if(o.Amount != null && o.Opp_Record_Type__c == 'Sales_Opportunity'){
                    if(o.Amount != null && SalesOppRecordList.contains(o.RecordTypeId)){
                      amount = o.amount;
                    }
                    if(o.AccountId == a.Id && o.Opp_Record_Type__c == 'Purchasing_Opportunity'){
                        if(o.StageName == 'Closed Won'){
                            if(o.CloseDate < closedwonpurchasingdatetime){
                              closedwonpurchasingdatetime = o.CloseDate;
                            totalpurchclosewon += 1;
                          }
                        }
                      
                        totalpurch += 1;
                    }
                    //if(o.AccountId == a.Id && o.Opp_Record_Type__c == 'Sales_Opportunity'){
                    if(o.AccountId == a.Id && SalesOppRecordList.contains(o.RecordTypeId)){
                        if (o.CreatedDate > recentdatetime){
                            recentdatetime = o.CreatedDate;
                        }
                        if (o.CreatedDate < initialdatetime){
                            initialdatetime = o.CreatedDate;
                            InitialLeadSource = o.LeadSource;
                        }
                        
                        if(o.CloseDate < closedwonsalesdatetime && o.StageName == 'Closed Won'){
                            closedwonsalesdatetime = o.CloseDate;
                        }
                        totalopponAccount += 1;
                        
                        totalOppValue += Amount; 
                        if(o.CreatedDate.year() == Date.Today().year()){
                            totaloppYTD += 1;
                          totaloppvalueYTD += Amount;
                        }
                        
                        if(o.CreatedDate > (Date.Today() - 90)){
                          totalopp90 += 1;
                          totalOppValue90d += Amount; 
                        }
                        if(o.StageName == 'Closed Won'){
                            totaloppCloseWon += 1;
                          totalOppCloseWonValue += Amount; 
                            if(o.Ship_Date__c != null){
                                if(o.Ship_Date__c.year() == Date.Today().year()){
                                totalOppCloseWonYTD += 1;
                            totalOppCloseWonValueYTD += Amount;
                              }
                              if(o.Ship_Date__c > (Date.Today() - 90)){
                            totaloppCloseWon90 += 1;
                            totalOppCloseWonValue90day += Amount;
                              }
                            }
                            
                        }
                    }
                }
                        
                    for(opportunity o : oppOnAccount2)
                  {
                      if(o.AccountId == a.Id){   
                        
                          totalOppValueInStock += Amount;
                          totOppInStock += 1;     
                        }
                    }
                 
                 if(totaloppOnAccount != null)
                 {
                     a.Total_Opportunities__c = totaloppOnAccount;
                 }
                  
                 if(totalopp90 != null)
                 {
                     a.Total_Opportunities_Last_90_Days__c = totalopp90;
                 }
                 
                 if(totaloppYTD != null)
                 {
                     a.Total_Opportunities_YTD__c = totaloppYTD;
                 }
                 
                 if(totaloppCloseWon != null)
                 {
                     a.Total_Opportunities_Won__c = totaloppCloseWon;
                 }
                 
                 if(totaloppCloseWon90 != null)
                 {
                     a.Total_Opportunities_Won_Last_90_Days__c = totaloppCloseWon90;
                 }
                 
                 if(totaloppCloseWonYTD != null)
                 {
                     a.Total_Opportunities_Won_YTD__c = totaloppCloseWonYTD;
                 }
                 
                 if(totaloppValue != null)
                 {
                     a.Total_Opportunity_Value__c = totaloppValue;
                 }
                 
                 if(totaloppValue90d != null)
                 {
                     a.Total_Opportunity_Value_Last_90_Days__c = totaloppValue90d;
                 }
                 
                 if(totaloppValueYTD != null)
                 {
                     a.Total_Opportunity_Value_YTD__c = totaloppValueYTD;
                 }
                 
                 if(totaloppCloseWonValue != null)
                 {
                     a.Total_Opportunities_Won_Value__c = totaloppCloseWonValue;
                 }
                 
                 if(totaloppCloseWonValueYTD != null)
                 {
                     a.Opportunity_Won_Value_YTD__c = totaloppCloseWonValueYTD;
                 }
                 
                 if(totaloppCloseWonValue90day != null)
                 {
                     a.Opportunity_Won_Value_Last_90_Days__c = totaloppCloseWonValue90day;
                 }
                 
                 if(initialdatetime != null){
                     initialdate = date.newinstance(initialdatetime.year(), initialdatetime.month(), initialdatetime.day());
                 }
                 if(initialdate != null)
                 {
                     a.First_Opportunity_Date__c = initialdate;
                     if(initialdate.year() > 2998){
                         a.First_Opportunity_Date__c = null;
                     }
                     if(InitialLeadSource != null){
                         a.First_Opportunity_Lead_Source__c = InitialLeadSource;
                     }
                 }
                 if(recentdatetime != null){
                     recentdate = date.newinstance(recentdatetime.year(), recentdatetime.month(), recentdatetime.day());
                 }
                 if(recentdate != null)
                 {
                     a.Most_Recent_Opportunity_Date__c = recentdate;
                     if(recentdate.year() < 2000){
                         a.Most_Recent_Opportunity_Date__c = null;
                     }
                 }
              /*   if(lastactivityaccounttime != null){
                     lastactivityaccount = date.newinstance(lastactivityaccounttime.year(), lastactivityaccounttime.month(), lastactivityaccounttime.day());
                 } */
                 system.debug('This is the last activity account >>> ' + lastactivityaccount);
                 if(lastactivityaccount != null)
                 {
                     a.Last_Activity_By_Account_Owner__c = lastactivityaccount;
                     if(lastactivityaccount.year() < 2000){
                         a.Last_Activity_By_Account_Owner__c = null;
                     }
                 }
              /*   if(lastactivitypurchasingtime != null){
                     lastactivitypurchasing = date.newinstance(lastactivitypurchasingtime.year(), lastactivitypurchasingtime.month(), lastactivitypurchasingtime.day());
                 } */
                 system.debug('This is the last activity purchasing >>> ' + lastactivitypurchasing);
                 
                 if(lastactivitypurchasing != null)
                 {
                     a.Last_Activity_By_Purchasing_Owner__c = lastactivitypurchasing;
                     if(lastactivitypurchasing.year() < 2000){
                         a.Last_Activity_By_Purchasing_Owner__c = null;
                     }
                 } 
                 if(closedwonpurchasingdatetime != null){
                     closedwonpurchasingdate = date.newinstance(closedwonpurchasingdatetime.year(), closedwonpurchasingdatetime.month(), 
                                                                closedwonpurchasingdatetime.day());
                 }
                 if(closedwonpurchasingdate != null){
                     a.First_Closed_Won_Purchasing_Date__c = closedwonpurchasingdate;
                     if(closedwonpurchasingdate.year() > 2998){
                         a.First_Closed_Won_Purchasing_Date__c = null;
                     }
                 }
                 
                 if(closedwonsalesdatetime != null){
                     closedwonsalesdate = date.newinstance(closedwonsalesdatetime.year(), closedwonsalesdatetime.month(), 
                                                                closedwonsalesdatetime.day());
                 }
                 if(closedwonsalesdate != null){
                     a.First_Closed_Won_Sales_Date__c = closedwonsalesdate;
                     if(closedwonsalesdate.year() > 2998){
                         a.First_Closed_Won_Sales_Date__c = null;
                     }
                 }
                 
                 if(totOppInStock != null){
                     a.Total_Opportunities_In_Stock__c= totalOpponAccount - totOppInStock;
                 }
                 if(totOppValueInStock != null){
                     a.Total_Opportunity_Value_In_Stock__c= totalOppValue - totOppValueInStock;
                 }
                 if(totalpurch != null){
                     a.Total_Purchasing_Opportunities__c = totalpurch;
                 }
                 if(totalpurchclosewon != null){
                     a.Total_Closed_Won_Purchasing_Opps__c = totalpurchclosewon;
                 }
                 
             } 
            
             update (accountlist);
          
                 
                      System.debug('Update successfully--------------');
                      System.debug('QUERIES FROM end >>>>>>>>> ' + Limits.getQueries());
          }
          global void execute(SchedulableContext sc) {
          UpdateAccountBatch  bc = new UpdateAccountBatch(); 

          database.executebatch(bc,75);
        /* System.schedule('Scheduled Job Accounts 1', '0 0 * * * ?', new UpdateAccountBatch());
          System.schedule('Scheduled Job Accounts 2', '0 15 * * * ?', new UpdateAccountBatch());
          System.schedule('Scheduled Job Accounts 3', '0 30 * * * ?', new UpdateAccountBatch());
          System.schedule('Scheduled Job Accounts 4', '0 45 * * * ?', new UpdateAccountBatch());*/
       }
    
        
    
        global void finish(Database.BatchableContext bc){
            system.debug('This method is required by the interface.');
        }
   }