({
    initialize : function(component, event, helper) {
        var objectRecordId = component.get("v.objectRecordId");
        console.log('record id in component ' + objectRecordId);
        var action = component.get("v.action");
        console.log('action in component ' + action);
        var objectName = component.get("v.objectName");
        console.log('object name in component ' + objectName);
    }
})