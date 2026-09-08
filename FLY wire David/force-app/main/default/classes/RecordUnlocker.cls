public class RecordUnlocker { 
    /**
     * Unlocks a single record passed from a Flow and returns a status message.
     * @param recordIds A list of IDs (Flow will pass a list containing just one ID).
     * @return A list containing a single String message ('Success' or the error description).
     */
    @InvocableMethod(
        label='Unlock Single Record' 
        description='Unlocks a single record and returns a success or error message.' 
        category='Record Approvals'
    )
    public static List<String> unlockRecord(List<Id> recordIds) {
        List<String> results = new List<String>();

        // Safely grab the first (and only) ID passed by the Screen Flow
        if (recordIds == null || recordIds.isEmpty() || recordIds[0] == null) {
            results.add('Error: No Record ID was provided.');
            return results;
        }

        Id recordIdToUnlock = recordIds[0];

        // Check if it's already unlocked
        if (!Approval.isLocked(recordIdToUnlock)) {
            results.add('Success: Record is already unlocked.');
            return results;
        }

        // Attempt to unlock
        Approval.UnlockResult unlockResult = Approval.unlock(recordIdToUnlock);
        
        if (unlockResult.isSuccess()) {
            results.add('Success');
        } else {
            // Compile the errors into a readable string for the Flow screen
            String errorMessage = 'Error: ';
            for(Database.Error err : unlockResult.getErrors()) {
                errorMessage += err.getMessage() + ' ';
            }
            results.add(errorMessage);
        }

        // Return the list (containing our single result string) back to the Flow
        return results;
    }


}