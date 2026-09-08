({
    onPageReferenceChange: function(component, event, helper) {
        var myPageRef = component.get("v.pageReference");
        var asset2Id = myPageRef.state.c__asset2Id;
        component.set("v.asset2Id", asset2Id);
        helper.createRecord(component, event, helper);
    },
    
    /*
    getTests : function(component, event, helper) {
        helper.fetchTests(component, event, helper);
    },
    */
    
    /* newTest : function(component, event, helper) {
    	// helper.createRecord(component, event, helper);
    },
    */
    
})