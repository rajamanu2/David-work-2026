({
    parseState: function (cmp) {
        var pr = cmp.get("v.pageReference");
        if (pr && pr.state) {
            var woId =
                pr.state.c__workOrderId ||
                pr.state.workOrderId ||
                pr.state.recordId ||
                cmp.get("v.workOrderId");

            var action = pr.state.c__action || pr.state.action || cmp.get("v.action") || "add";
            action = (action && action.toLowerCase) ? action.toLowerCase() : "add";

            cmp.set("v.workOrderId", woId);
            cmp.set("v.action", action === "swap" ? "swap" : "add");

            if (action !== "swap") {
                cmp.set("v.selectedWoliId", null);
                cmp.set("v.selectedRows", []);
            }
        }
    },

loadWorkOrderItems: function (cmp) {
    var woId = cmp.get("v.workOrderId");
    if (!woId) {
        cmp.set("v.errorMsg", "No Work Order Id resolved on this page.");
        cmp.set("v.woItems", []);
        return;
    }

    var act = cmp.get("c.getWorkOrderItems");
    act.setParams({ workOrderId: woId });

    act.setCallback(this, function (resp) {
        var state = resp.getState();

        if (state === "SUCCESS") {
            var rows = resp.getReturnValue() || [];

            var items = rows.map(function (w) {
                // Prefer custom fields. Fall back to standard names if needed.
                var partName =
                    (w.Part_Name_D__c && w.Part_Name_D__c.trim && w.Part_Name_D__c.trim()) || w.Part_Name_D__c ||
                    (w.Product2 && w.Product2.Name) ||
                    (w.PricebookEntry && w.PricebookEntry.Product2 && w.PricebookEntry.Product2.Name) ||
                    w.Id;

                var partNumber =
                    (w.Part_Number_D__c && w.Part_Number_D__c.trim && w.Part_Number_D__c.trim()) || w.Part_Number_D__c || "";

                return {
                    id: w.Id,
                    lineNumber: partName,   // bold
                    subLabel: partNumber    // gray
                };
            });

            cmp.set("v.woItems", items);
            cmp.set("v.errorMsg", items.length ? "" : "No Work Order line items found.");
        } else {
            var msg = "Failed to load Work Order line items.";
            try {
                var errs = resp.getError();
                if (errs && errs[0] && errs[0].message) {
                    msg += " " + errs[0].message;
                }
            } catch (e) {}
            cmp.set("v.errorMsg", msg);
            cmp.set("v.woItems", []);
        }
    });

    $A.enqueueAction(act);
},


    // Called by controller from the "Select" buttons
    pickItem: function (cmp, woiId) {
        if (!woiId) { return; }

        var items = cmp.get("v.woItems") || [];
        var found = items.find(function (i) { return i.id === woiId; });

        // Seed search with the PRODUCT NAME (lineNumber now)
        var seedName = found ? (found.subLabel || "") : "";

        cmp.set("v.selectedRows", [{
            Id: woiId,
            Product_Name__c: seedName
        }]);

        cmp.set("v.selectedWoliId", woiId);
    },

    // Called by the LWC after it creates the replacement
    deletePickedWoli: function (cmp) {
        var woliId = cmp.get("v.selectedWoliId");
        if (!woliId) { return; }

        var act = cmp.get("c.deleteWorkOrderLineItem");
        act.setParams({ woliId: woliId });
        act.setCallback(this, function (resp) {
            var state = resp.getState();
            if (state === "SUCCESS" && resp.getReturnValue() === "success") {
                console.log("Old Work Order Line Item deleted: " + woliId);
            } else {
                console.error("Failed to delete old WOLI", resp.getError && resp.getError());
            }
        });
        $A.enqueueAction(act);
    }
});