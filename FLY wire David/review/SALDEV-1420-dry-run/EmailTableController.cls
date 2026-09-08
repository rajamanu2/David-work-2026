public with sharing class EmailTableController {
    
    // Inputs from VF component
    public Id quoteId { get; set; }
    public String templateName { get; set; }
    
    public Boolean hasError { get; private set; }
    public String errorMessage { get; private set; }
    
    // ColumnWrapper wrapper stores column headers
    private List<ColumnWrapper> cachedColumns;
    
    // cachedGroupedLines wrapper stores group header 
    private List<LineGroup> cachedGroupedLines;
    
    private Boolean isDataLoaded = false;
    
    // Wrapper class to store the ordered list of text values for a single table row
    public class RowWrapper {
        public List<String> cellValues { get; set; }
        public RowWrapper() { cellValues = new List<String>(); }
    }
    
    // Wrapper class to store a group header
    public class LineGroup {
        public String groupName { get; set; }
        public Boolean showTitle { get; set; }
        public List<RowWrapper> rows { get; set; }
        
        public LineGroup(String gn, Boolean st) { 
            this.groupName = gn; 
            this.showTitle = st;
            this.rows = new List<RowWrapper>(); 
        }
    }

    // Helper class that pre-computes string paths to safely retrieve cross-object or standard field values
    private class FieldPath {
        private String rawPath;
        private List<String> parts;
        
        // Splits the field API name by dots to prepare the cross-object path in memory
        public FieldPath(String path) {
            this.rawPath = path.trim();
            this.parts = this.rawPath.split('\\.');
        }
        
        // Traverses the predefined relationship path on the given record to safely return the final field value
        public Object getValue(SObject record) {
            if (parts.size() == 1) return record.get(rawPath);
            
            SObject currentObj = record;
            for (Integer i = 0; i < parts.size() - 1; i++) {
                currentObj = currentObj.getSObject(parts[i]);
                if (currentObj == null) return null; 
            }
            return currentObj.get(parts[parts.size() - 1]);
        }
    }
    
    // Class pre-compiles Custom Metadata rules to instantly extract formatted cell values
    public class ColumnWrapper {
        public String header { get; set; }
        private Boolean isConcat;
        private List<FieldPath> paths;
        
        // Configures the column type (standard vs. CONCAT) and initializes the necessary FieldPath helpers
        public ColumnWrapper(String header, String apiName) {
            this.header = header;
            this.isConcat = apiName.startsWithIgnoreCase('CONCAT:');
            this.paths = new List<FieldPath>();
            
            if (this.isConcat) {
                for (String f : apiName.substringAfter('CONCAT:').split(',')) {
                    if (String.isNotBlank(f)) this.paths.add(new FieldPath(f));
                }
            } else {
                this.paths.add(new FieldPath(apiName));
            }
        }
        
        // Executes the pre-compiled logic against a Quote Line record to generate the final text for the table cell
        public String extractCellValue(SObject record) {
            if (!this.isConcat) {
                Object val = this.paths[0].getValue(record);
                return val != null ? String.valueOf(val) : '';
            } else {
                List<String> values = new List<String>();
                for (FieldPath fp : this.paths) {
                    Object val = fp.getValue(record);
                    if (val != null && String.valueOf(val).trim() != '') {
                        values.add(String.valueOf(val).trim());
                    }
                }
                return String.join(values, '; ');
            }
        }
    }
    
    // Lazy-load getter that triggers data processing (if needed) and returns the table columns for Visualforce
    public List<ColumnWrapper> getColumns() {
        if (!isDataLoaded) loadData();
        return cachedColumns;
    }
    
    // Lazy-load getter that triggers data processing (if needed) and returns the grouped rows for Visualforce
    public List<LineGroup> getGroupedLines() {
        if (!isDataLoaded) loadData();
        return cachedGroupedLines;
    }
    
    // Main execution that queries Custom Metadata, fetches Quote Lines, and builds the visual data structure
    private void loadData() {
        cachedColumns = new List<ColumnWrapper>();
        cachedGroupedLines = new List<LineGroup>();
        hasError = false;
        errorMessage = '';
        
        if (quoteId == null || String.isBlank(templateName)) {
            isDataLoaded = true;
            return;
        }
        
        try {
            // Query Quote to check Multiple_Ship_to_Accounts__c
            List<SBQQ__Quote__c> quotes = [SELECT Id, Multiple_Ship_to_Accounts__c FROM SBQQ__Quote__c WHERE Id = :quoteId LIMIT 1];
            if (quotes.isEmpty()) return;
            
            String multiAccValue = quotes[0].Multiple_Ship_to_Accounts__c != null ? String.valueOf(quotes[0].Multiple_Ship_to_Accounts__c).trim() : '';
            Boolean showAccountColumn = multiAccValue.equalsIgnoreCase('Yes');
            
            // Fetch Columns from Custom Metadata
            List<Email_Table__mdt> rawColumns = [
                SELECT Field_API_Name__c, Column_Header__c 
                FROM Email_Table__mdt 
                WHERE Email_Template__c = :templateName
                ORDER BY Column_Order__c ASC
            ];
            
            if (rawColumns.isEmpty()) return;
            
            // Prepare Columns and Query String
            Set<String> queryFields = new Set<String>{
                'SBQQ__Group__c',
                'SBQQ__Group__r.SBQQ__SubscriptionTerm__c', 
                'SBQQ__RequiredBy__c'                  
            };
                        
            for (Email_Table__mdt col : rawColumns) {
                String fieldName = col.Field_API_Name__c != null ? col.Field_API_Name__c.trim() : '';
                
                // Skip Account column dynamically based on Quote setup
                if (fieldName.equalsIgnoreCase('Ship_To_Account__r.Name') && !showAccountColumn) {
                    continue; 
                }
                
                ColumnWrapper optimizedCol = new ColumnWrapper(col.Column_Header__c, fieldName);
                cachedColumns.add(optimizedCol);
                for (FieldPath fp : optimizedCol.paths) {
                    queryFields.add(fp.rawPath);
                }
            }
            
            // Query the Quote Lines
            String qString = 'SELECT Id, ' + String.join(new List<String>(queryFields), ', ') + 
                ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteId'+
                ' AND Quote_Line_Type__c != \'Amendment\' ' + 
                ' ORDER BY SBQQ__Group__r.Allow_Product_Ramping__c ASC, SBQQ__Group__r.SBQQ__StartDate__c, SBQQ__Group__r.SBQQ__SubscriptionTerm__c DESC NULLS LAST, SBQQ__Group__r.Name ASC, SBQQ__RequiredBy__c ASC NULLS FIRST, SBQQ__ProductName__c ASC';
            List<SBQQ__QuoteLine__c> lineItems = Database.query(qString);
            
            // Phase 1: Store ALL retrieved Quote Line IDs so we know what is genuinely a Top-Level line
            Set<Id> allLineItemIds = new Set<Id>();
            for (SBQQ__QuoteLine__c ql : lineItems) {
                allLineItemIds.add(ql.Id);
            }

            // Phase 2: Map Hierarchy strictly (Multi-level compatible)
            Set<Id> seenGroups = new Set<Id>();
            List<Id> orderedGroupIds = new List<Id>(); 
            Map<Id, List<SBQQ__QuoteLine__c>> groupToTopLevelLines = new Map<Id, List<SBQQ__QuoteLine__c>>();
            Map<Id, List<SBQQ__QuoteLine__c>> parentToChildren = new Map<Id, List<SBQQ__QuoteLine__c>>();
            Map<Id, Decimal> groupIdToTerm = new Map<Id, Decimal>();

            for (SBQQ__QuoteLine__c ql : lineItems) {
                Id groupId = (Id) ql.get('SBQQ__Group__c');
                Id parentId = (Id) ql.get('SBQQ__RequiredBy__c');
                
                if (!seenGroups.contains(groupId)) {
                    seenGroups.add(groupId);
                    orderedGroupIds.add(groupId);
                    groupToTopLevelLines.put(groupId, new List<SBQQ__QuoteLine__c>());
                    
                    SObject groupRel = ql.getSObject('SBQQ__Group__r');
                    Decimal term = (groupRel != null && groupRel.get('SBQQ__SubscriptionTerm__c') != null) 
                                    ? (Decimal) groupRel.get('SBQQ__SubscriptionTerm__c') : null;
                    groupIdToTerm.put(groupId, term);
                }
                
                // If it has no parent, OR its parent is not part of this quote query, it is a Top-Level line
                if (parentId == null || !allLineItemIds.contains(parentId)) {
                    groupToTopLevelLines.get(groupId).add(ql);
                } else {
                    // Otherwise, map it strictly to its direct parent (works for children, grandchildren, etc.)
                    if (!parentToChildren.containsKey(parentId)) {
                        parentToChildren.put(parentId, new List<SBQQ__QuoteLine__c>());
                    }
                    parentToChildren.get(parentId).add(ql);
                }
            }
            
            Integer termCounter = 1;
            
            // Phase 3: Final Multi-Level Order Assembly
            for (Id groupId : orderedGroupIds) {            
                Boolean displayTitle = (groupId != null);
                String finalGroupName = '';
                
                if (displayTitle) {
                    Decimal termVal = groupIdToTerm.get(groupId);
                    if (termVal != null) {
                        finalGroupName = 'Term ' + termCounter + ': ' + termVal + ' months';
                    } else {
                        finalGroupName = 'Term ' + termCounter; 
                    }
                    termCounter++;
                }
                
                LineGroup groupWrap = new LineGroup(finalGroupName, displayTitle);
                List<SBQQ__QuoteLine__c> orderedLinesForGroup = new List<SBQQ__QuoteLine__c>();
                
                // Use recursion to flatten the N-level hierarchy properly
                if (groupToTopLevelLines.containsKey(groupId)) {
                    for (SBQQ__QuoteLine__c topLevelLine : groupToTopLevelLines.get(groupId)) {
                        flattenHierarchy(topLevelLine, parentToChildren, orderedLinesForGroup);
                    }
                }
                
                // Process the beautifully ordered list into Visualforce Row Wrappers
                for (SBQQ__QuoteLine__c ql : orderedLinesForGroup) {
                    RowWrapper rowWrap = new RowWrapper();
                    for (ColumnWrapper col : cachedColumns) {
                        rowWrap.cellValues.add(col.extractCellValue(ql));
                    }
                    groupWrap.rows.add(rowWrap);
                }
                
                cachedGroupedLines.add(groupWrap);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'QuoteLineEmailController Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            hasError = true;
            errorMessage = 'We encountered an error generating the quote lines. Please contact your administrator.';
        } finally {
            isDataLoaded = true;
        }
    }

    /**
     * Recursive helper method (Depth-First Search) 
     * Ensures perfect multi-level sorting (Parent -> Child 1 -> Grandchildren -> Child 2)
     */
    private void flattenHierarchy(SBQQ__QuoteLine__c currentLine, Map<Id, List<SBQQ__QuoteLine__c>> parentToChildren, List<SBQQ__QuoteLine__c> orderedLines) {
        
        // 1. Add the current line (Parent/Child/Grandchild) to the flattened list
        orderedLines.add(currentLine);
        
        // 2. If this line has its own children, immediately process them before moving to siblings
        if (parentToChildren.containsKey(currentLine.Id)) {
            for (SBQQ__QuoteLine__c childLine : parentToChildren.get(currentLine.Id)) {
                flattenHierarchy(childLine, parentToChildren, orderedLines);
            }
        }
    }
}
