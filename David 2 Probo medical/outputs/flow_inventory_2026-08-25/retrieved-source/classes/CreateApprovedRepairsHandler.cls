public class CreateApprovedRepairsHandler {
    public static List<Integer> FGetReverseOrder(String f, ProductItem__c item, List<Integer> reverseorder) {
        if (item != null && item.Probe_Type__c == 'Transesophageal') {
            if (f.trim() == 'Array Replacement') {
                reverseorder.add(2);
            } else if (f.trim() == 'Cable Replacement') {
                reverseorder.add(4);
            } else {
                reverseorder.add(ProboConstants.OrderRepairs.get(f.trim()));
            }
        } else {
            reverseorder.add(ProboConstants.OrderRepairs.get(f.trim()));
        }
        return reverseorder;
    }
    public static List<Integer> CGetReverseOrder(String c, ProductItem__c item, List<Integer> reverseorder) {
        // These are the exceptions for the order of repairs for TEE probes.
        if (item != null && item.Probe_Type__c == 'Transesophageal') {
            if (c.trim() == 'Strain Relief Replacement') {
                reverseorder.add(5);
            } else if (c.trim() == 'Connector Housing Replacement') {
                reverseorder.add(28);
            } else if (c.trim() == 'Connector Housing Paint') {
                reverseorder.add(29);
            } else {
                reverseorder.add(ProboConstants.OrderRepairs.get(c.trim()));
            }
        } else {
            reverseorder.add(ProboConstants.OrderRepairs.get(c.trim()));
        }
        return reverseorder;
    }

    public static RepairLists GetRepairLists(string approvedRepairs, ProductItem__c item) {
        RepairLists repairLists = new RepairLists();
        repairLists.cosmeticRepairs = new List<String>();
        repairLists.functionalRepairs = new List<String>();
        repairLists.repairOrder = new List<Integer>();
        repairLists.ApprovedRepairs = '';
        repairLists.declined = '';
        repairLists.declinedList = '';
        System.debug('CC...approve: ' + repairLists.ApprovedRepairs);
        Set<String> approve = new Set<String>();
        List<String> approved = approvedRepairs.split(';');
        approve.addAll(approved);
        
        Set<String> cpossiblerepair = new Set<String>();
        Set<String> fpossiblerepair = new Set<String>();
    
        //Add item to set to avoid dupe
        if (item != null && item.Possible_Cosmetic_Repairs__c != null) {
            cpossiblerepair.addAll(item.Possible_Cosmetic_Repairs__c.split('\n'));
        }

        //Add item to set to avoid dupe
        if (item != null && item.Possible_Functional_Repairs__c != null) {
            fpossiblerepair.addAll(item.Possible_Functional_Repairs__c.split('\n'));
        }

        System.debug('CC...item cos: ' + cpossiblerepair);
        System.debug('CC...item fun: ' + fpossiblerepair);
        System.debug('CC...app:' + approve);

        if (approve.contains('All Repairs Approved')) {
            repairLists.cosmeticRepairs.addall(cpossiblerepair);
            repairLists.functionalRepairs.addall(fpossiblerepair);
            repairLists.declined = 'NONE';
            repairLists.declinedList = 'NONE';
        } else { //  approve does not contain -- if (!approve.contains('All Repairs Approved')) {
            
            for (String a : approve) {
                if (ProboConstants.cosmetic_repair_list.contains(a)) {
                    repairLists.cosmeticRepairs.add(a);
                }
                if (ProboConstants.functional_repair_list.contains(a)) {
                    repairLists.functionalRepairs.add(a);
                }
            }
        }
    
        System.debug('CC...item cos: ' + repairLists.cosmeticRepairs);
        System.debug('CC...item fun: ' + repairLists.functionalRepairs);

        for (String c : cpossiblerepair) {
            System.debug('THIS IS C FOR FNEWREPAIR LOOP >>>> ' + c.trim());
            if(c != null){
                if (!repairLists.cosmeticRepairs.contains(c)) {
                	repairLists.declined += c.trim() + '\n';
                	repairLists.declinedList += c.trim() + ';';
            	}
            	else{
               		repairLists.ApprovedRepairs += c.trim() + ';'; 
               		repairLists.repairOrder = CGetReverseOrder(c, item, repairLists.repairOrder);
           	 	}
            }
            

            
        }

        for (String f : fpossiblerepair) {
            System.debug('THIS IS F FOR FNEWREPAIR LOOP: ' + f.trim());
            if(f != null){
                if (!repairLists.functionalRepairs.contains(f.trim())) {
                	repairLists.declined += f.trim() + '\n';
                	repairLists.declinedlist += f.trim() + ';';
            	}
           		else{
                	repairLists.ApprovedRepairs += f.trim() + ';';
					repairLists.repairOrder = FGetReverseOrder(f, item, repairLists.repairOrder);
            	}
            }
            
        }
        
        if(repairLists.ApprovedRepairs != null && repairLists.declined == ''){
            repairLists.declined = 'NONE';
        }

        System.debug(repairLists.ApprovedRepairs);

        return repairLists;
    }

    public static RMA__c createApproved(RMA__c rma, ProductItem__c item, RepairLists repairLists) {
        rma.Declined_Repairs__c = repairLists.declined;
        
        rma.Needs_to_be_moved_to_this_location__c = repairLists.newlocation;

        Set<String> cannotrepairs = new Set<String>();
        // If one of the listed repairs in the approved repairs is one that doesn't have a price in it,
        // it will check the box for approving repair that cannot be done, and this will generate an error
        // through a validation rule.
        if (rma.Approved_Repairs__c != null && !rma.Approving_repair_that_cannot_be_done__c) {
            if (rma.These_Repairs_Cannot_Be_Done__c != null) {
                List<String> cannotrepairslist = rma.These_Repairs_Cannot_Be_Done__c.split('\n');

                for (String c : cannotrepairslist) {
                    cannotrepairs.add(c.trim());
                }
            }
            if (repairLists.cosmeticRepairs != null) {
                for (String c : repairLists.cosmeticRepairs) {
                    if (cannotrepairs.contains(c.trim())) {
                        rma.Approving_repair_that_cannot_be_done__c = true;
                        break;
                    }
                }
            }

            if (!rma.Approving_repair_that_cannot_be_done__c && repairLists.functionalRepairs != null) {
                for (String f : repairLists.functionalRepairs) {
                    if (cannotrepairs.contains(f.trim())) {
                        rma.Approving_repair_that_cannot_be_done__c = true;
                        break;
                    }
                }
            }
        }

        return rma;
    }
}