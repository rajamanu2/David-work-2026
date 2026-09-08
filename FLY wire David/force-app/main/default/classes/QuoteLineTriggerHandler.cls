public class QuoteLineTriggerHandler {
    public static Boolean isFirstRun = true;

    // Inner class to store dynamic mapping configurations
    public class RollupMapping {
        public String baseField;
        public String rollupField;
        public String operation;
        public String alias; // Used for safe AggregateResult extraction

        public RollupMapping(String baseField, String rollupField, String operation, String alias) {
            this.baseField = baseField;
            this.rollupField = rollupField;
            this.operation = operation;
            this.alias = alias;
        }
    }

    @TestVisible 
    private static List<RollupMapping> mockRollupMappings;

    // Load configuration from Custom Metadata Type (CMDT)
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

    public static void calculateAveragePrice(List<SBQQ__QuoteLine__c> records, Map<Id, SBQQ__QuoteLine__c> oldMap) {
        if (records == null || records.isEmpty()) return;

        try {
            List<RollupMapping> fieldMappings = getRollupMappings();
            if (fieldMappings.isEmpty()) return;

            Set<Id> quoteIds = new Set<Id>();

            // 1. Identify affected Quotes dynamically based on context
            for (SBQQ__QuoteLine__c ql : records) {
                if (oldMap == null) {
                    // INSERT, DELETE, or UNDELETE context
                    quoteIds.add(ql.SBQQ__Quote__c);
                } else {
                    // UPDATE context: Compare old vs new values
                    SBQQ__QuoteLine__c oldQl = oldMap.get(ql.Id);
                    Boolean isChanged = (ql.SBQQ__Product__c != oldQl.SBQQ__Product__c || 
                                         ql.SBQQ__StartDate__c != oldQl.SBQQ__StartDate__c);
                    
                    // Check if any configured custom metadata base field changed
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

            // 2. DYNAMIC DATABASE MATH: Leverage AggregateResult with Scalable Operations
            String aggQuery = 'SELECT SBQQ__Quote__c, SBQQ__Product__c';
            for (RollupMapping mapping : fieldMappings) {
                // Determine the correct SOQL function based on the Picklist value
                String soqlFunction;
                if (mapping.operation.equalsIgnoreCase('Average')) {
                    soqlFunction = 'AVG';
                } else if (mapping.operation.equalsIgnoreCase('Sum')) {
                    soqlFunction = 'SUM';
                } else if (mapping.operation.equalsIgnoreCase('Min')) {
                    soqlFunction = 'MIN';
                } else if (mapping.operation.equalsIgnoreCase('Max')) {
                    soqlFunction = 'MAX';
                } 
                
                aggQuery += ', ' + soqlFunction + '(' + mapping.baseField + ') ' + mapping.alias;
            }
            aggQuery += ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteIds AND SBQQ__Product__c != null GROUP BY SBQQ__Quote__c, SBQQ__Product__c';
            
            List<AggregateResult> aggResults = Database.query(aggQuery);

            // Map aggregated results by Composite Key (QuoteId-ProductId)
            Map<String, Map<String, Decimal>> rollupDataMap = new Map<String, Map<String, Decimal>>();
            for (AggregateResult ar : aggResults) {
                String key = (Id)ar.get('SBQQ__Quote__c') + '-' + (Id)ar.get('SBQQ__Product__c');
                Map<String, Decimal> calculatedRollups = new Map<String, Decimal>();
                
                for (RollupMapping mapping : fieldMappings) {
                    calculatedRollups.put(mapping.rollupField, (Decimal)ar.get(mapping.alias));
                }
                rollupDataMap.put(key, calculatedRollups);
            }

            // 3. DATABASE SORTING: Guarantee the earliest date is first in the list
            String sortQuery = 'SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__StartDate__c';
            for (RollupMapping mapping : fieldMappings) {
                sortQuery += ', ' + mapping.rollupField;
            }
            sortQuery += ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteIds AND SBQQ__Product__c != null ORDER BY SBQQ__Quote__c, SBQQ__Product__c, SBQQ__StartDate__c ASC NULLS LAST';
            
            List<SBQQ__QuoteLine__c> linesToProcess = Database.query(sortQuery);

            // 4. SINGLE FLAT LOOP: Zero nested iterations through data
            Set<String> processedKeys = new Set<String>();
            Map<Id, SBQQ__QuoteLine__c> recordsToUpdate = new Map<Id, SBQQ__QuoteLine__c>();

            for (SBQQ__QuoteLine__c ql : linesToProcess) {
                String key = ql.SBQQ__Quote__c + '-' + ql.SBQQ__Product__c;
                SBQQ__QuoteLine__c updateObj = new SBQQ__QuoteLine__c(Id = ql.Id);
                Boolean fieldChanged = false;

                if (!processedKeys.contains(key)) {
                    // First time seeing this Product: Apply the calculated rollups
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
                    // Subsequent lines for this Product: Clear the rollup fields
                    for (RollupMapping mapping : fieldMappings) {
                        if (ql.get(mapping.rollupField) != null) {
                            updateObj.put(mapping.rollupField, null);
                            fieldChanged = true;
                        }
                    }
                }

                // Only add to DML list if an actual value changed
                if (fieldChanged) {
                    recordsToUpdate.put(ql.Id, updateObj);
                }
            }

            // 5. BULK DML
            if (!recordsToUpdate.isEmpty()) {
                database.update(recordsToUpdate.values(), false);
            }

        } catch (Exception e) {
            System.debug('Error in QuoteLineTriggerHandler: ' + e.getMessage() + ' on line ' + e.getLineNumber());
            for (SBQQ__QuoteLine__c ql : records) {
                ql.addError('An error occurred calculating Quote Line rollups: ' + e.getMessage());
            }
        }
    }
}