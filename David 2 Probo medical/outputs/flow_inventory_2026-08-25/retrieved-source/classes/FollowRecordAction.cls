public with sharing class FollowRecordAction {
    @InvocableMethod(label='Follow Record')
    public static void follow(List<Request> requests) {
        if (requests == null || requests.isEmpty()) return;

        // Build requested follows per user and de duplicate within the same request batch
        Map<Id, Set<Id>> userToRequestedParents = new Map<Id, Set<Id>>();
        for (Request req : requests) {
            if (req == null || req.userId == null || req.recordId == null) continue;
            Set<Id> parents = userToRequestedParents.get(req.userId);
            if (parents == null) {
                parents = new Set<Id>();
                userToRequestedParents.put(req.userId, parents);
            }
            parents.add(req.recordId);
        }
        if (userToRequestedParents.isEmpty()) return;

        Set<Id> allUserIds = new Set<Id>(userToRequestedParents.keySet());

        // For duplicate checking only, collect the union of all requested ParentIds
        Set<Id> allRequestedParentIds = new Set<Id>();
        for (Set<Id> s : userToRequestedParents.values()) allRequestedParentIds.addAll(s);

        // Existing subscriptions for these users and parents to skip duplicates
        Map<Id, Set<Id>> userToExistingRequestedParents = new Map<Id, Set<Id>>();
        if (!allRequestedParentIds.isEmpty()) {
            // LIMIT 1000 required for EntitySubscription queries run by non admins
            for (EntitySubscription es : [
                SELECT Id, SubscriberId, ParentId
                FROM EntitySubscription
                WHERE SubscriberId IN :allUserIds
                AND ParentId IN :allRequestedParentIds
                LIMIT 1000
            ]) {
                Set<Id> existingParents = userToExistingRequestedParents.get(es.SubscriberId);
                if (existingParents == null) {
                    existingParents = new Set<Id>();
                    userToExistingRequestedParents.put(es.SubscriberId, existingParents);
                }
                existingParents.add(es.ParentId);
            }
        }

        // Count current totals per user
        Map<Id, Integer> userToExistingCount = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT SubscriberId sid, COUNT(Id) cnt
            FROM EntitySubscription
            WHERE SubscriberId IN :allUserIds
            GROUP BY SubscriberId
            LIMIT 1000
        ]) {
            userToExistingCount.put((Id)ar.get('sid'), (Integer)ar.get('cnt'));
        }

        // Compute how many new records will actually be inserted per user after removing duplicates
        Map<Id, Integer> userToNewCount = new Map<Id, Integer>();
        for (Id uid : allUserIds) {
            Set<Id> requested = userToRequestedParents.get(uid);
            Set<Id> alreadyHave = userToExistingRequestedParents.containsKey(uid)
                ? userToExistingRequestedParents.get(uid)
                : new Set<Id>();
            Integer netNew = 0;
            for (Id pid : requested) {
                if (!alreadyHave.contains(pid)) netNew++;
            }
            userToNewCount.put(uid, netNew);
        }

        // Determine how many to delete per user so that final total is at most 499
        final Integer MAX_PER_USER = 499;
        Map<Id, Integer> userToDeleteCount = new Map<Id, Integer>();
        Integer totalToDelete = 0;
        for (Id uid : allUserIds) {
            Integer existing = userToExistingCount.containsKey(uid) ? userToExistingCount.get(uid) : 0;
            Integer incoming = userToNewCount.containsKey(uid) ? userToNewCount.get(uid) : 0;
            Integer needToDelete = Math.max(0, existing + incoming - MAX_PER_USER);
            if (needToDelete > 0) {
                userToDeleteCount.put(uid, needToDelete);
                totalToDelete += needToDelete;
            }
        }

        // Collect the specific records to delete, oldest first per user
        List<EntitySubscription> subsToDelete = new List<EntitySubscription>();
        if (totalToDelete > 0) {
            for (Id uid : userToDeleteCount.keySet()) {
                Integer limitPerUser = userToDeleteCount.get(uid);
                if (limitPerUser <= 0) continue;
                // Oldest first. limitPerUser will always be <= 499 by construction.
                List<EntitySubscription> oldest = [
                    SELECT Id
                    FROM EntitySubscription
                    WHERE SubscriberId = :uid
                    ORDER BY CreatedDate ASC
                    LIMIT :limitPerUser
                ];
                subsToDelete.addAll(oldest);
            }
        }

        // Build final insert list skipping any pairs that already exist
        List<EntitySubscription> subsToInsert = new List<EntitySubscription>();
        for (Id uid : allUserIds) {
            Set<Id> requested = userToRequestedParents.get(uid);
            Set<Id> alreadyHave = userToExistingRequestedParents.containsKey(uid)
                ? userToExistingRequestedParents.get(uid)
                : new Set<Id>();

            for (Id pid : requested) {
                if (!alreadyHave.contains(pid)) {
                    subsToInsert.add(new EntitySubscription(SubscriberId = uid, ParentId = pid));
                }
            }
        }

        // Perform DML in the right order
        if (!subsToDelete.isEmpty()) {
            delete subsToDelete;
        }
        if (!subsToInsert.isEmpty()) {
            insert subsToInsert;
        }
    }

    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;

        @InvocableVariable(required=true)
        public Id userId;
    }
}