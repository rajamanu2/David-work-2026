/**
 * @description SALDEV-1427 / SALDEV-1467 / SALDEV-1499: Central Handler for SBQQ__QuoteLine__c triggers.
 * Completely eliminates SObjectExceptions by querying all parent relationships explicitly into maps.
 */
public with sharing class QuoteLineTriggerHandler {

    public static Boolean isFirstRun = true;

    public static void copyQuoteLineTypeToBackground(List<SBQQ__QuoteLine__c> newLines) {
        if (newLines == null || newLines.isEmpty()) return;

        for (SBQQ__QuoteLine__c ql : newLines) {
            if (ql == null) continue;

            try {
                if (String.isNotBlank(ql.Quote_Line_Type__c)) {
                    ql.Quote_Line_Type_background__c = ql.Quote_Line_Type__c;
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Formula field Quote_Line_Type__c unqueried on in-memory record: ' + e.getMessage());
            }
        }
    }

    // =========================================================================
    // SALDEV-1499: QUOTE LINE BACKGROUND FIELD & RATE DETAILS AUTOMATION
    // =========================================================================

    public static void processBackgroundFields(List<SBQQ__QuoteLine__c> newLines, Map<Id, SBQQ__QuoteLine__c> oldMap) {
        if (newLines == null || newLines.isEmpty()) return;

        Set<Id> sourceLineIds = new Set<Id>();
        Set<Id> subscriptionIds = new Set<Id>();

        for (SBQQ__QuoteLine__c ql : newLines) {
            if (ql == null) continue;
            if (ql.SBQQ__Source__c != null) {
                sourceLineIds.add(ql.SBQQ__Source__c);
            }
            if (ql.SBQQ__UpgradedSubscription__c != null) {
                subscriptionIds.add(ql.SBQQ__UpgradedSubscription__c);
            }
            if (ql.SBQQ__RenewedSubscription__c != null) {
                subscriptionIds.add(ql.SBQQ__RenewedSubscription__c);
            }
        }

        Map<Id, SBQQ__QuoteLine__c> sourceLineMap = new Map<Id, SBQQ__QuoteLine__c>();
        if (!sourceLineIds.isEmpty()) {
            sourceLineMap = new Map<Id, SBQQ__QuoteLine__c>([
                SELECT Id, Rate_Details__c, Default_Rate_Details__c
                FROM SBQQ__QuoteLine__c
                WHERE Id IN :sourceLineIds
            ]);
        }

        Map<Id, SBQQ__Subscription__c> subMap = new Map<Id, SBQQ__Subscription__c>();
        if (!subscriptionIds.isEmpty()) {
            subMap = new Map<Id, SBQQ__Subscription__c>([
                SELECT Id, Rate_Details__c
                FROM SBQQ__Subscription__c
                WHERE Id IN :subscriptionIds
            ]);
        }

        for (SBQQ__QuoteLine__c ql : newLines) {
            if (ql == null) continue;

            String currentRateDetails = String.isNotBlank(ql.Rate_Details__c) ? ql.Rate_Details__c.trim() : '';
            String defaultRateDetails = String.isNotBlank(ql.Default_Rate_Details__c) ? ql.Default_Rate_Details__c.trim() : '';

            // 1. BASELINE FALLBACK LOGIC
            if (String.isBlank(defaultRateDetails)) {
                if (ql.SBQQ__Source__c != null && sourceLineMap.containsKey(ql.SBQQ__Source__c)) {
                    SBQQ__QuoteLine__c src = sourceLineMap.get(ql.SBQQ__Source__c);
                    if (src != null) {
                        defaultRateDetails = String.isNotBlank(src.Default_Rate_Details__c)
                            ? src.Default_Rate_Details__c.trim()
                            : (String.isNotBlank(src.Rate_Details__c) ? src.Rate_Details__c.trim() : '');
                    }
                } else if (ql.SBQQ__UpgradedSubscription__c != null && subMap.containsKey(ql.SBQQ__UpgradedSubscription__c)) {
                    SBQQ__Subscription__c sub = subMap.get(ql.SBQQ__UpgradedSubscription__c);
                    if (sub != null && String.isNotBlank(sub.Rate_Details__c)) {
                        defaultRateDetails = sub.Rate_Details__c.trim();
                    }
                } else if (ql.SBQQ__RenewedSubscription__c != null && subMap.containsKey(ql.SBQQ__RenewedSubscription__c)) {
                    SBQQ__Subscription__c sub = subMap.get(ql.SBQQ__RenewedSubscription__c);
                    if (sub != null && String.isNotBlank(sub.Rate_Details__c)) {
                        defaultRateDetails = sub.Rate_Details__c.trim();
                    }
                }

                if (String.isNotBlank(defaultRateDetails)) {
                    ql.Default_Rate_Details__c = defaultRateDetails;
                }
            }

            // 2. RATE DETAILS MISMATCH CHECK
            Boolean isBaselineMismatch = false;
            if (String.isNotBlank(defaultRateDetails)) {
                isBaselineMismatch = (currentRateDetails != defaultRateDetails);
            } else if (String.isNotBlank(currentRateDetails)) {
                isBaselineMismatch = true;
            }

            ql.Rate_Details_Changed__c = isBaselineMismatch;
        }
    }

    // =========================================================================
    // SALDEV-1427/1467/1499: AMENDMENT CLONE & PRICE CHANGE HANDLING
    // =========================================================================

    public static void handlePriceChangeOnAmendmentClones(List<SBQQ__QuoteLine__c> records) {
        if (records == null || records.isEmpty()) return;

        Set<Id> quoteIds = new Set<Id>();
        Set<Id> sourceLineIds = new Set<Id>();
        Set<Id> requiredByParentIds = new Set<Id>();

        for (SBQQ__QuoteLine__c ql : records) {
            if (ql == null) continue;
            if (ql.SBQQ__Quote__c != null) {
                quoteIds.add(ql.SBQQ__Quote__c);
            }
            if (ql.SBQQ__Source__c != null) {
                sourceLineIds.add(ql.SBQQ__Source__c);
            }
            if (ql.SBQQ__RequiredBy__c != null) {
                requiredByParentIds.add(ql.SBQQ__RequiredBy__c);
            }
        }

        if (quoteIds.isEmpty() && sourceLineIds.isEmpty() && requiredByParentIds.isEmpty()) return;

        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();
        if (!quoteIds.isEmpty()) {
            quoteMap = new Map<Id, SBQQ__Quote__c>([
                SELECT Id, SBQQ__Type__c, SBQQ__Account__c 
                FROM SBQQ__Quote__c 
                WHERE Id IN :quoteIds
            ]);
        }

        Map<Id, SBQQ__QuoteLine__c> sourceLineMap = new Map<Id, SBQQ__QuoteLine__c>();
        if (!sourceLineIds.isEmpty()) {
            sourceLineMap = new Map<Id, SBQQ__QuoteLine__c>([
                SELECT Id, SBQQ__Product__c, Ship_To_Account__c, Attribute_Code__c, 
                       Payment_Method__c, Transaction_Currency__c, SBQQ__Quote__c
                FROM SBQQ__QuoteLine__c
                WHERE Id IN :sourceLineIds
            ]);
        }

        Map<Id, SBQQ__QuoteLine__c> parentBundleMap = new Map<Id, SBQQ__QuoteLine__c>();
        if (!requiredByParentIds.isEmpty()) {
            parentBundleMap = new Map<Id, SBQQ__QuoteLine__c>([
                SELECT Id, Price_Change__c, SBQQ__Quantity__c, SBQQ__Product__c, SBQQ__Quote__c
                FROM SBQQ__QuoteLine__c 
                WHERE Id IN :requiredByParentIds
            ]);
        }

        Map<Id, Set<String>> activeReplacementsByQuote = new Map<Id, Set<String>>();
        if (!quoteIds.isEmpty()) {
            for (SBQQ__QuoteLine__c ql : [
                SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__Quantity__c, SBQQ__UpgradedSubscription__c, SBQQ__Source__c,
                       Ship_To_Account__c, Attribute_Code__c, Payment_Method__c, Transaction_Currency__c, SBQQ__RequiredBy__c
                FROM SBQQ__QuoteLine__c 
                WHERE SBQQ__Quote__c IN :quoteIds
                  AND SBQQ__Quantity__c > 0
                  AND SBQQ__Product__c != NULL
            ]) {
                if (ql.SBQQ__Source__c != null || ql.SBQQ__UpgradedSubscription__c == null) {
                    String matchKey = buildFullConfigKey(
                        (String)ql.SBQQ__Product__c, 
                        (String)ql.Ship_To_Account__c, 
                        (String)ql.Attribute_Code__c, 
                        (String)ql.Payment_Method__c, 
                        (String)ql.Transaction_Currency__c
                    );
                    if (!activeReplacementsByQuote.containsKey(ql.SBQQ__Quote__c)) {
                        activeReplacementsByQuote.put(ql.SBQQ__Quote__c, new Set<String>());
                    }
                    activeReplacementsByQuote.get(ql.SBQQ__Quote__c).add(matchKey);
                }
            }
        }

        Map<Id, Boolean> parentCalculatedPriceChangeMap = new Map<Id, Boolean>();

        // PASS 1 - EVALUATE PARENT AND STANDALONE LINES FIRST
        for (SBQQ__QuoteLine__c ql : records) {
            if (ql == null) continue;
            SBQQ__Quote__c parentQuote = quoteMap.get(ql.SBQQ__Quote__c);
            Boolean isAmendmentQuote = (parentQuote != null && parentQuote.SBQQ__Type__c == 'Amendment');

            if (isAmendmentQuote && ql.SBQQ__RequiredBy__c == null) {
                String currentLineMatchKey = buildFullConfigKey(
                    (String)ql.SBQQ__Product__c, 
                    (String)ql.Ship_To_Account__c, 
                    (String)ql.Attribute_Code__c, 
                    (String)ql.Payment_Method__c, 
                    (String)ql.Transaction_Currency__c
                );
                
                Set<String> activeReplacements = activeReplacementsByQuote.get(ql.SBQQ__Quote__c);
                Boolean hasMatchingReplacement = (activeReplacements != null && activeReplacements.contains(currentLineMatchKey));

                Boolean isClonedWithConfigChange = false;
                if (ql.SBQQ__Source__c != null && sourceLineMap.containsKey(ql.SBQQ__Source__c)) {
                    SBQQ__QuoteLine__c srcLine = sourceLineMap.get(ql.SBQQ__Source__c);
                    
                    String qlPay = String.valueOf(ql.Payment_Method__c);
                    String srcPay = String.valueOf(srcLine.Payment_Method__c);
                    String qlCurr = String.valueOf(ql.Transaction_Currency__c);
                    String srcCurr = String.valueOf(srcLine.Transaction_Currency__c);
                    String qlAttr = String.valueOf(ql.Attribute_Code__c);
                    String srcAttr = String.valueOf(srcLine.Attribute_Code__c);
                    String qlShip = String.valueOf(ql.Ship_To_Account__c);
                    String srcShip = String.valueOf(srcLine.Ship_To_Account__c);

                    if (qlPay != srcPay || qlCurr != srcCurr || qlAttr != srcAttr || qlShip != srcShip) {
                        isClonedWithConfigChange = true;
                    }
                }

                if (ql.SBQQ__UpgradedSubscription__c == null && (ql.SBQQ__Source__c == null || isClonedWithConfigChange)) {
                    ql.Price_Change__c = false;
                } else if (ql.SBQQ__UpgradedSubscription__c == null && ql.SBQQ__Source__c != null && !isClonedWithConfigChange) {
                    ql.Price_Change__c = true;
                } else if (ql.SBQQ__UpgradedSubscription__c != null && ql.SBQQ__Quantity__c == 0) {
                    ql.Price_Change__c = (hasMatchingReplacement && !isClonedWithConfigChange);
                } else if (ql.SBQQ__UpgradedSubscription__c != null && ql.SBQQ__Quantity__c > 0) {
                    ql.Price_Change__c = false;
                }

                if (ql.Id != null) {
                    parentCalculatedPriceChangeMap.put(ql.Id, ql.Price_Change__c);
                }
            }
        }

        // PASS 2 - EVALUATE CHILD OPTION LINES
        for (SBQQ__QuoteLine__c ql : records) {
            if (ql == null) continue;
            SBQQ__Quote__c parentQuote = quoteMap.get(ql.SBQQ__Quote__c);
            Boolean isAmendmentQuote = (parentQuote != null && parentQuote.SBQQ__Type__c == 'Amendment');

            if (isAmendmentQuote && ql.SBQQ__RequiredBy__c != null) {
                Boolean parentPriceChange = false;
                if (parentCalculatedPriceChangeMap.containsKey(ql.SBQQ__RequiredBy__c)) {
                    parentPriceChange = parentCalculatedPriceChangeMap.get(ql.SBQQ__RequiredBy__c);
                } else if (parentBundleMap.containsKey(ql.SBQQ__RequiredBy__c)) {
                    parentPriceChange = (parentBundleMap.get(ql.SBQQ__RequiredBy__c).Price_Change__c == true);
                }

                if (ql.SBQQ__UpgradedSubscription__c == null && ql.SBQQ__Source__c != null) {
                    ql.Price_Change__c = true;
                } else if (ql.SBQQ__UpgradedSubscription__c != null && ql.SBQQ__Quantity__c == 0) {
                    ql.Price_Change__c = parentPriceChange;
                } else {
                    ql.Price_Change__c = false;
                }
            }
        }
    }

    private static String buildFullConfigKey(String prodId, String shipTo, String attrCode, String payMethod, String curr) {
        String p = String.isNotBlank(prodId) ? prodId : '';
        String s = String.isNotBlank(shipTo) ? shipTo : '';
        String a = String.isNotBlank(attrCode) ? attrCode : '';
        String pm = String.isNotBlank(payMethod) ? payMethod : '';
        String c = String.isNotBlank(curr) ? curr : '';
        return p + '-' + s + '-' + a + '-' + pm + '-' + c;
    }

    public static void copyOpportunityLineIdOnRamp(List<SBQQ__QuoteLine__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) return;

        try {
            Set<Id> quoteIds = new Set<Id>();
            Set<Id> sourceLineIds = new Set<Id>();

            for (SBQQ__QuoteLine__c ql : newRecords) {
                if (ql == null) continue;
                if (ql.SBQQ__Quote__c != null) {
                    quoteIds.add(ql.SBQQ__Quote__c);
                }
                if (ql.SBQQ__Source__c != null) {
                    sourceLineIds.add(ql.SBQQ__Source__c);
                }
            }

            Map<Id, SBQQ__QuoteLine__c> sourceLineMap = new Map<Id, SBQQ__QuoteLine__c>();
            if (!sourceLineIds.isEmpty()) {
                sourceLineMap = new Map<Id, SBQQ__QuoteLine__c>([
                    SELECT Id, Opportunity_Line_Id__c 
                    FROM SBQQ__QuoteLine__c 
                    WHERE Id IN :sourceLineIds AND Opportunity_Line_Id__c != NULL
                ]);
            }

            Map<String, List<String>> group1OrderedIdsMap = new Map<String, List<String>>();
            if (!quoteIds.isEmpty()) {
                for (SBQQ__QuoteLine__c ql : [
                    SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, Opportunity_Line_Id__c, 
                           SBQQ__Group__c, SBQQ__Group__r.SBQQ__Number__c
                    FROM SBQQ__QuoteLine__c 
                    WHERE SBQQ__Quote__c IN :quoteIds 
                      AND Opportunity_Line_Id__c != NULL
                    ORDER BY SBQQ__Group__r.SBQQ__Number__c ASC NULLS FIRST, CreatedDate ASC, Id ASC
                ]) {
                    String prodKey = ql.SBQQ__Quote__c + '-' + ql.SBQQ__Product__c;
                    if (!group1OrderedIdsMap.containsKey(prodKey)) {
                        group1OrderedIdsMap.put(prodKey, new List<String>());
                    }
                    group1OrderedIdsMap.get(prodKey).add(ql.Opportunity_Line_Id__c);
                }
            }

            Map<String, Integer> productOccurrenceCounter = new Map<String, Integer>();

            for (SBQQ__QuoteLine__c ql : newRecords) {
                if (ql == null || ql.SBQQ__Product__c == null) continue;

                if (String.isBlank(ql.Opportunity_Line_Id__c) && ql.SBQQ__Source__c != null && sourceLineMap.containsKey(ql.SBQQ__Source__c)) {
                    ql.Opportunity_Line_Id__c = sourceLineMap.get(ql.SBQQ__Source__c).Opportunity_Line_Id__c;
                    continue;
                }

                String prodKey = ql.SBQQ__Quote__c + '-' + ql.SBQQ__Product__c;
                Integer currentSlot = productOccurrenceCounter.containsKey(prodKey) 
                    ? productOccurrenceCounter.get(prodKey) 
                    : 0;

                if (String.isBlank(ql.Opportunity_Line_Id__c) && group1OrderedIdsMap.containsKey(prodKey)) {
                    List<String> masterIds = group1OrderedIdsMap.get(prodKey);
                    if (currentSlot < masterIds.size()) {
                        ql.Opportunity_Line_Id__c = masterIds.get(currentSlot);
                    } else if (!masterIds.isEmpty()) {
                        ql.Opportunity_Line_Id__c = masterIds.get(0);
                    }
                }

                productOccurrenceCounter.put(prodKey, currentSlot + 1);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'SALDEV-1467 Error in copyOpportunityLineIdOnRamp: ' + e.getMessage());
        }
    }

    // =========================================================================
    // QUOTE LINE ROLLUP & AVERAGE PRICE CALCULATION ENGINE
    // =========================================================================

    public class RollupMapping {
        public String baseField;
        public String rollupField;
        public String operation;
        public String alias;

        public RollupMapping(String baseField, String rollupField, String operation, String alias) {
            this.baseField = baseField;
            this.rollupField = rollupField;
            this.operation = operation;
            this.alias = alias;
        }
    }

    @TestVisible 
    private static List<RollupMapping> mockRollupMappings;

    private static List<RollupMapping> getRollupMappings() {
        if (mockRollupMappings != null) return mockRollupMappings;

        List<RollupMapping> mappings = new List<RollupMapping>();
        Integer aliasCounter = 0;

        for (Quote_Line_Rollup_Field_Mapping__mdt cmdt : Quote_Line_Rollup_Field_Mapping__mdt.getAll().values()) {
            if (String.isNotBlank(cmdt.Field__c) && 
                String.isNotBlank(cmdt.Rollup_Field__c) && 
                String.isNotBlank(cmdt.Type_of_Operation__c)) {
                
                mappings.add(new RollupMapping(
                    cmdt.Field__c, 
                    cmdt.Rollup_Field__c, 
                    cmdt.Type_of_Operation__c,
                    'alias' + aliasCounter 
                ));
                aliasCounter++;
            }
        }
        return mappings;
    }

    public static void calculateRollupField(List<SBQQ__QuoteLine__c> records, Map<Id, SBQQ__QuoteLine__c> oldMap) {
        if (records == null || records.isEmpty()) return;

        try {
            List<RollupMapping> fieldMappings = getRollupMappings();
            if (fieldMappings.isEmpty()) return;

            Set<Id> quoteIds = new Set<Id>();

            for (SBQQ__QuoteLine__c ql : records) {
                if (ql == null) continue;
                if (oldMap == null) {
                    quoteIds.add(ql.SBQQ__Quote__c);
                } else {
                    SBQQ__QuoteLine__c oldQl = oldMap.get(ql.Id);
                    if (oldQl == null) continue;
                    Boolean isChanged = (ql.SBQQ__Product__c != oldQl.SBQQ__Product__c || 
                                         ql.SBQQ__StartDate__c != oldQl.SBQQ__StartDate__c);
                    
                    if (!isChanged) {
                        for (RollupMapping mapping : fieldMappings) {
                            if (ql.get(mapping.baseField) != oldQl.get(mapping.baseField)) {
                                isChanged = true;
                                break;
                            }
                        }
                    }

                    if (isChanged) {
                        quoteIds.add(ql.SBQQ__Quote__c);
                    }
                }
            }

            if (quoteIds.isEmpty()) return;

            String aggQuery = 'SELECT SBQQ__Quote__c, SBQQ__Product__c';
            for (RollupMapping mapping : fieldMappings) {
                String soqlFunction;
                if (mapping.operation.equalsIgnoreCase('Average')) {
                    soqlFunction = 'AVG';
                } else if (mapping.operation.equalsIgnoreCase('Sum')) {
                    soqlFunction = 'SUM';
                } 
                
                aggQuery += ', ' + soqlFunction + '(' + mapping.baseField + ') ' + mapping.alias;
            }
            aggQuery += ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteIds AND SBQQ__Product__c != null GROUP BY SBQQ__Quote__c, SBQQ__Product__c';
            
            List<AggregateResult> aggResults = Database.query(aggQuery);

            Map<String, Map<String, Decimal>> rollupDataMap = new Map<String, Map<String, Decimal>>();
            for (AggregateResult ar : aggResults) {
                String key = (Id)ar.get('SBQQ__Quote__c') + '-' + (Id)ar.get('SBQQ__Product__c');
                Map<String, Decimal> calculatedRollups = new Map<String, Decimal>();
                
                for (RollupMapping mapping : fieldMappings) {
                    calculatedRollups.put(mapping.rollupField, (Decimal)ar.get(mapping.alias));
                }
                rollupDataMap.put(key, calculatedRollups);
            }

            String sortQuery = 'SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__StartDate__c';
            for (RollupMapping mapping : fieldMappings) {
                sortQuery += ', ' + mapping.rollupField;
            }
            sortQuery += ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteIds AND SBQQ__Product__c != null ORDER BY SBQQ__Quote__c, SBQQ__Product__c, SBQQ__StartDate__c ASC NULLS LAST';
            
            List<SBQQ__QuoteLine__c> linesToProcess = Database.query(sortQuery);

            Set<String> processedKeys = new Set<String>();
            Map<Id, SBQQ__QuoteLine__c> recordsToUpdate = new Map<Id, SBQQ__QuoteLine__c>();

            for (SBQQ__QuoteLine__c ql : linesToProcess) {
                String key = ql.SBQQ__Quote__c + '-' + ql.SBQQ__Product__c;
                SBQQ__QuoteLine__c updateObj = new SBQQ__QuoteLine__c(Id = ql.Id);
                Boolean fieldChanged = false;

                if (!processedKeys.contains(key)) {
                    processedKeys.add(key); 
                    
                    Map<String, Decimal> rollups = rollupDataMap.get(key);
                    if (rollups != null) {
                        for (RollupMapping mapping : fieldMappings) {
                            Decimal calculatedValue = rollups.get(mapping.rollupField);
                            if (ql.get(mapping.rollupField) != calculatedValue) {
                                updateObj.put(mapping.rollupField, calculatedValue);
                                fieldChanged = true;
                            }
                        }
                    }
                } else {
                    for (RollupMapping mapping : fieldMappings) {
                        if (ql.get(mapping.rollupField) != null) {
                            updateObj.put(mapping.rollupField, null);
                            fieldChanged = true;
                        }
                    }
                }

                if (fieldChanged) {
                    recordsToUpdate.put(ql.Id, updateObj);
                }
            }

            if (!recordsToUpdate.isEmpty()) {
                Database.update(recordsToUpdate.values(), true);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in QuoteLineTriggerHandler: ' + e.getMessage() + ' on line ' + e.getLineNumber());
            for (SBQQ__QuoteLine__c ql : records) {
                if (ql != null) {
                    ql.addError('An error occurred calculating Quote Line rollups: ' + e.getMessage());
                }
            }
        }
    }
}