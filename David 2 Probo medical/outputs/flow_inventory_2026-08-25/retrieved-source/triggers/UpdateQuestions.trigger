trigger UpdateQuestions on Document_Trained_Person__c (before insert, before update) {

    // JMAY: SOQL, DML, hardcoded are fixed - deployed to devint

    set<Id> trainItemIDs = new Set<Id>();
    for (Document_Trained_Person__c dt : trigger.new) {

        if (dt.Training_Item__c != null) {
            trainItemIDs.add(dt.Training_Item__c);
        }
    }

    Map<Id, List<Training_Item__c>> tiIdToTrainItems = new Map<Id, List<Training_Item__c>>();

    for (Training_Item__c r : [
            Select Name, Question_1__c, Question_1_Choice_A__c, Question_1_Choice_B__c,
                    Question_1_Choice_C__c, Question_1_Choice_D__c, Question_2__c, Question_2_Choice_A__c,
                    Question_2_Choice_B__c, Question_2_Choice_C__c, Question_2_Choice_D__c, Question_3__c,
                    Question_3_Choice_A__c, Question_3_Choice_B__c, Question_3_Choice_C__c, Question_3_Choice_D__c,
                    Question_4__c, Question_4_Choice_A__c, Question_4_Choice_B__c, Question_4_Choice_C__c,
                    Question_4_Choice_D__c, Question_5__c, Question_5_Choice_A__c, Question_5_Choice_B__c,
                    Question_5_Choice_C__c, Question_5_Choice_D__c
            from Training_Item__c
            where Id = :trainItemIDs
    ]) {

        if (!tiIdToTrainItems.containsKey(r.Id)) {
            tiIdToTrainItems.put(r.Id, new List<Training_Item__c>());
        }

        tiIdToTrainItems.get(r.Id).add(r);
    }

    // Document trained person is the way training is documented. The questions and answers are on the training item
    // page. These are transferred on to the document training person for the individual person to take the quiz.
    // TODO: This just overwrites the DocTrainedPerson fields if there are multiple Training_Item records since the SOQL is not ordered
    for (Document_Trained_Person__c dt : trigger.new) {

        if (dt.Training_Item__c != null && tiIdToTrainItems.containsKey(dt.Training_Item__c)){

            for (Training_Item__c ti : tiIdToTrainItems.get(dt.Training_Item__c)) {
                dt.Question_1__c = ti.Question_1__c;
                dt.Question_1_Choice_A__c = ti.Question_1_Choice_A__c;
                dt.Question_1_Choice_B__c = ti.Question_1_Choice_B__c;
                dt.Question_1_Choice_C__c = ti.Question_1_Choice_C__c;
                dt.Question_1_Choice_D__c = ti.Question_1_Choice_D__c;
                dt.Question_2__c = ti.Question_2__c;
                dt.Question_2_Choice_A__c = ti.Question_2_Choice_A__c;
                dt.Question_2_Choice_B__c = ti.Question_2_Choice_B__c;
                dt.Question_2_Choice_C__c = ti.Question_2_Choice_C__c;
                dt.Question_2_Choice_D__c = ti.Question_2_Choice_D__c;
                dt.Question_3__c = ti.Question_3__c;
                dt.Question_3_Choice_A__c = ti.Question_3_Choice_A__c;
                dt.Question_3_Choice_B__c = ti.Question_3_Choice_B__c;
                dt.Question_3_Choice_C__c = ti.Question_3_Choice_C__c;
                dt.Question_3_Choice_D__c = ti.Question_3_Choice_D__c;
                dt.Question_4__c = ti.Question_4__c;
                dt.Question_4_Choice_A__c = ti.Question_4_Choice_A__c;
                dt.Question_4_Choice_B__c = ti.Question_4_Choice_B__c;
                dt.Question_4_Choice_C__c = ti.Question_4_Choice_C__c;
                dt.Question_4_Choice_D__c = ti.Question_4_Choice_D__c;
                dt.Question_5__c = ti.Question_5__c;
                dt.Question_5_Choice_A__c = ti.Question_5_Choice_A__c;
                dt.Question_5_Choice_B__c = ti.Question_5_Choice_B__c;
                dt.Question_5_Choice_C__c = ti.Question_5_Choice_C__c;
                dt.Question_5_Choice_D__c = ti.Question_5_Choice_D__c;
            }
        }
    }
}