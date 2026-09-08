({    
   invoke : function(component, event, helper) {
      
      // Get the attributes from the flow
      var recordId = component.get("v.recordId");
      var vfName = component.get("v.vfName");
      var parameters = component.get("v.parameters") || "";
      
      // Get the Lightning event that opens a record in a new tab
      var urlEvent = $A.get("e.force:navigateToURL");

      var vfUrl = "/apex/" + vfName + "?id=" + recordId + parameters;

      // Navigate to VF
      urlEvent.setParams({
         "url":vfUrl
      });
      urlEvent.fire(); 
   }
})