({
     /*
     fetchTests : function(component, event, helper) {
        component.set('v.mycolumns', [
            {label: 'Name', fieldName: 'recordLink', type: 'url', typeAttributes: {label: {fieldName: 'name'}}},
            {label: 'Functional Rating', fieldName: 'Functional_Rating', type: 'text'},
            {label: 'Functional Evaluation', fieldName: 'Functional_Evaluation', type: 'text'},
            {label: 'Fun evaluation', fieldName: 'Fun_evaluation', type: 'text'},
            {label: 'Cosmetic Rating', fieldName: 'Cosmetic_Rating', type: 'text'},
			{label: 'Cosmetic Evaluation', fieldName: 'Cosmetic_Evaluation', type: 'text'},
			{label: 'Cos evaluation', fieldName: 'Cos_evaluation', type: 'text'},
			{label: 'New Repair Evaluation', fieldName: 'Functional_Rating', type: 'text'},
			{label: 'Repair Evaluation', fieldName: 'Repair_Evaluation', type: 'text'},
			{label: 'Test Completed By', fieldName: 'Test_Completed_By', type: 'text'}
        ]);
        var action = component.get("c.getProductTests");
        action.setParams({
            "pItemId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.testList", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    */
    
    createRecord: function(component, event, helper) { 
        var ProductTest;
        var action = component.get('c.createProductTest');
        action.setParams({
            "pItemId" : component.get("v.asset2Id")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                ProductTest = response.getReturnValue();
                
                // Fire event to show the Full Record Create panel
                var createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": "ProductTest__c",
                    "recordTypeId": ProductTest.recordTypeId,
                    "defaultFieldValues": {
                        "Name": ProductTest.name,
                        "Product_Item__c":ProductTest.Product_Item,
                        "Repairs_Completed_Since_Last_Test__c":ProductTest.Repairs_Completed_Since_Last_Test,
                        "Preset__c":ProductTest.Preset,
                        "Airscan_Frequency__c":ProductTest.Airscan_Frequency,
                        "Airscan_Gain__c":ProductTest.Airscan_Gain,
                        "Airscan_Depth__c":ProductTest.Airscan_Depth,
                        "Airscan_Focal_Points__c":ProductTest.Airscan_Focal_Points,
                        "Airscan_Focal_pt_position__c":ProductTest.Airscan_Focal_pt_position,
                        "Probe_Testing_Notes__c":ProductTest.Probe_Testing_Notes,
                        "Phantom_Frequency__c":ProductTest.Phantom_Frequency,
                        "Phantom_Gain__c":ProductTest.Phantom_Gain,
                        "Phantom_Depth_cm__c":ProductTest.Phantom_Depth_cm,
                        "Phantom_Focal_Points__c":ProductTest.Phantom_Focal_Points,
                        "Phantom_Focal_Pt_Position__c":ProductTest.Phantom_Focal_Pt_Position,
                        "Color_Gain__c":ProductTest.Color_Gain,
                        "CW_Gain__c":ProductTest.CW_Gain,
                        "PRF__c":ProductTest.PRF,
                        "Live_3D__c":ProductTest.Live_3D,
                        "Max_allowable_leakage_current__c":ProductTest.Max_allowable_leakage_current,
                        "Probe_Repair_Notes__c":ProductTest.Probe_Repair_Notes,
                        "System_Test_Bed__c":ProductTest.System_Test_Bed,
                        "Product_Avg_Capacitance__c":ProductTest.Product_Avg_Capacitance,
                        "Product_Avg_Sensitivity__c":ProductTest.Product_Avg_Sensitivity,
                        "Capacitance_Lower_Limit__c":ProductTest.Capacitance_Lower_Limit,
                        "Capacitance_Upper_Limit__c":ProductTest.Capacitance_Upper_Limit,
                        "Sensitivity_Lower_Limit__c":ProductTest.Sensitivity_Lower_Limit,
                        "Sensitivity_Upper_Limit__c":ProductTest.Sensitivity_Upper_Limit,
                        "Created_from_Override__c":true
                    }
                });
                createRecordEvent.fire();
            }
        });
        $A.enqueueAction(action);
    }
    
})