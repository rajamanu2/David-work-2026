({
    doInit: function (cmp, event, helper) {
        helper.parseState(cmp);
        if (cmp.get("v.action") === "swap") {
            helper.loadWorkOrderItems(cmp);
        }
    },

    handlePick: function (cmp, event, helper) {
        var woiId = event.getSource().get("v.value");
        helper.pickItem(cmp, woiId);
    },

    handleSwapDone: function (cmp, event, helper) {
        console.log("Swap completed, deleting picked WOLI");
        helper.deletePickedWoli(cmp);
    }

});