({    
    invoke: function(component, event, helper) {
        var toastEvent = $A.get('e.force:showToast');
        var duration = component.get('v.duration');
        var key = component.get('v.key');
        var message = component.get('v.message');
        var messageTemplate = component.get('v.messageTemplate');
        var messageTemplateData = component.get('v.messageTemplateData');
        var mode = component.get('v.mode');
        var title = component.get('v.title');
        var type = component.get('v.type');
    
        toastEvent.setParams({
            duration : duration,
            key : key,
            message : message,
            messageTemplate : messageTemplate,
            messageTemplateData : JSON.parse(messageTemplateData),
            mode : mode,
            title : title,
            type : type
        });
        toastEvent.fire();
    }
 })