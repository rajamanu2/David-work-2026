public with sharing class ActivityComponentController {

    @AuraEnabled(cacheable=true)
    public static list<ActivityHistory> getActivities(string recordId){
        Account AccountWithActivityHistories = [ SELECT Id, Name, (
                SELECT ActivityDate, ActivityType, Description, CreatedBy.Name, Status, WhatId , Id , Subject , Owner.Name , IsTask , OwnerId ,
                ActivitySubtype , PrimaryWhoId , WhoId , PrimaryWho.Name
                FROM ActivityHistories  ORDER BY ActivityDate DESC,LastModifiedDate DESC LIMIT 500
            )
            FROM Account Where id =: recordId LIMIT 1
        ];

        list<ActivityHistory> activiytHistoryList = new list<ActivityHistory>();
        //list<ActivityClass> activiytClassList = new list<ActivityClass>();
        //activiytHistoryList.addAll(AccountWithActivityHistories.ActivityHistories);
        for(ActivityHistory activityForVar: AccountWithActivityHistories.ActivityHistories){
            if(activityForVar.Owner.Name!='Marketo Admin'){
                activiytHistoryList.add(activityForVar);
            }
        }
        System.debug('activiytHistoryList size: '+ activiytHistoryList.size() );
        /*
        for(ActivityHistory activityForVar : activiytHistoryList){
            ActivityClass activityVar = new ActivityClass();
            activityVar.Id = activityForVar.Id;
            activityVar.ActivityDate = activityForVar.ActivityDate;
            activityVar.Subject = activityForVar.Subject;
            activityVar.IsTask = activityForVar.IsTask;
            activityVar.WhoId = activityForVar.WhoId;
            activityVar.PrimaryWhoId = activityForVar.PrimaryWhoId;
            activityVar.OwnerId = activityForVar.OwnerId;
            activityVar.OwnerId = activityForVar.OwnerId;
            activityVar.OwnerId = activityForVar.OwnerId;
            
            System.debug('activityForVar PrimaryWho.Name: '+ activityForVar.PrimaryWho.Name );
            activiytClassList.add(activityVar);
        }*/


        return activiytHistoryList;
    }
    
    @AuraEnabled(cacheable=true)
    public static KeyActivitiesWrapper getKeyObjectiveActivities(String recordId, Integer numberOfRecords) {
        Account AccountWithActivityHistories = [ SELECT Id, Name, (
                SELECT ActivityDate, ActivityType, Description, CreatedBy.Name, Status, WhatId , Id , Subject , 
                  Owner.Name , IsTask, ActivitySubtype , PrimaryWhoId , WhoId , PrimaryWho.Name,
                  Key_Objective__c, Progress__c
                FROM ActivityHistories  ORDER BY ActivityDate DESC,LastModifiedDate DESC LIMIT 500
            )
            FROM Account Where id = :recordId LIMIT 1
        ];

        list<ActivityHistory> activiytHistoryList = new list<ActivityHistory>();
        for(ActivityHistory activityForVar: AccountWithActivityHistories.ActivityHistories){
            if(activityForVar.Key_Objective__c==true){
                activiytHistoryList.add(activityForVar);
            }
        }
        System.debug('Key_Objective__c activiytHistoryList size: '+ activiytHistoryList.size() );

        List<ActivityHistory> slicedList = (List<ActivityHistory>)sliceResults(activiytHistoryList, numberOfRecords);
        System.debug('open slicedList size: '+ slicedList.size());

        KeyActivitiesWrapper wrapper = new KeyActivitiesWrapper();
        wrapper.activities = slicedList;
        wrapper.count = activiytHistoryList.size();
        return wrapper; 
    }
    
    @AuraEnabled(cacheable=true)
    public static KeyActivitiesWrapper getOpenKeyObjectiveActivities(String recordId, Integer numberOfRecords){
        Account AccountWithActivityHistories = [ SELECT Id, Name, (
                SELECT ActivityDate, ActivityType, Description, CreatedBy.Name, Status, WhatId , Id , Subject , 
                  Owner.Name , IsTask, ActivitySubtype , PrimaryWhoId , WhoId , PrimaryWho.Name,
                  Key_Objective__c , LastModifiedDate, Progress__c
                FROM OpenActivities ORDER BY ActivityDate ASC, LastModifiedDate DESC LIMIT 500
            )
            FROM Account Where id = :recordId LIMIT 1
        ];

        list<OpenActivity> openActiviytList = new list<OpenActivity>();
        for(OpenActivity  activityForVar: AccountWithActivityHistories.OpenActivities){
            if(activityForVar.Key_Objective__c==true){
                openActiviytList.add(activityForVar);
            }
        }
        System.debug('open openActiviytList size: '+ openActiviytList.size());

        List<OpenActivity> slicedList = (List<OpenActivity>)sliceResults(openActiviytList, numberOfRecords);
        System.debug('open slicedList size: '+ slicedList.size());

        KeyActivitiesWrapper wrapper = new KeyActivitiesWrapper();
        wrapper.activities = slicedList;
        wrapper.count = openActiviytList.size();
        return wrapper; 
    }

    private static List<SObject> sliceResults (List<SObject> originalResult, Integer numberOfRecords) {
        List<SObject> slicedList = originalResult.clone();
        while (slicedList.size() > numberOfRecords) {
            slicedList.remove(numberOfRecords);
        }
        return slicedList;
    }

    @AuraEnabled(cacheable=true)
    public static list<OpenActivity> getOpenNonMarketoActivities(string recordId){
        Account AccountWithActivityHistories = [ SELECT Id, Name, (
                SELECT ActivityDate, ActivityType, Description, CreatedBy.Name, Status, WhatId , Id , Subject , 
                  Owner.Name , IsTask , OwnerId ,ActivitySubtype , PrimaryWhoId , WhoId , PrimaryWho.Name,
                  Key_Objective__c , LastModifiedDate
                FROM OpenActivities ORDER BY ActivityDate ASC, LastModifiedDate DESC LIMIT 10
            )
            FROM Account Where id =: recordId LIMIT 100
        ];

        list<OpenActivity> openActiviytList = new list<OpenActivity>();
        for(OpenActivity  activityForVar: AccountWithActivityHistories.OpenActivities){
            if(activityForVar.Owner.Name!='Marketo Admin'){
                openActiviytList.add(activityForVar);
            }
        }
        System.debug('open openActiviytList size: '+ openActiviytList.size() );
        return openActiviytList;
    }

    public class KeyActivitiesWrapper {
        @AuraEnabled
        public List<SObject> activities;
        @AuraEnabled
        public Integer count;
    }
    
    /*
    public class ActivityClass{
        public String Subject;
        public Date ActivityDate;
        public String Id;
        public Boolean IsTask;
        public String PrimaryWhoId;
        public String WhoId;
        public String OwnerId;
        //public String OwnerId;
        //public String OwnerId;

        public ActivityClass(){}
    }*/

}