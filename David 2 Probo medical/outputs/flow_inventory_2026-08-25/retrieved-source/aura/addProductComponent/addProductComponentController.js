({
    initialize : function(component, event, helper) {
        var opportunityId = component.get("v.opportunityId");
        console.log('opportunity id in component ' + opportunityId);
        var action = component.get("v.action");
        console.log('action in component ' + action);
    }
})