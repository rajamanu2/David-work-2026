public class EmailTableController {
    
    // Inputs from VF component
    public Id quoteId { get; set; }
    public String templateName { get; set; }
    
    public Boolean hasError { get; private set; }
    public String errorMessage { get; private set; }
    
    // ColumnWrapper wrapper stores column headers
    private List<ColumnWrapper> cachedColumns;
    
    // cachedGroupedLines wrapper stores group info 
    // Name, Allow_Product_Ramping__c, SBQQ__StartDate__c, SBQQ__EndDate__c 
    private List<LineGroup> cachedGroupedLines;
    
    private Boolean isDataLoaded = false;
    
    // RowWrapper stores row level info for table
    public class RowWrapper {
        public List<String> cellValues { get; set; }
        public RowWrapper() { cellValues = new List<String>(); }
    }
    
    public class LineGroup {
        public String groupName { get; set; }
        public Boolean showTitle { get; set; }
        public Boolean rampedUp { get; set; }
        public Date startDate { get; set; }
        public Date endDate { get; set; }
        
        public List<RowWrapper> rows { get; set; }
        
        public LineGroup(String gn, Boolean st, Boolean rUp, Date sDate, Date eDate) { 
            this.groupName = gn; 
            this.showTitle = st;
            this.rampedUp = rUp != null ? rUp : false;
            this.startDate = sDate;
            this.endDate = eDate;
            this.rows = new List<RowWrapper>(); 
        }
    }
    
    private class FieldPath {
        private String rawPath;
        private List<String> parts;
        
        public FieldPath(String path) {
            this.rawPath = path.trim();
            this.parts = this.rawPath.split('\\.');
        }
        
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

    public class ColumnWrapper {
        public String header { get; set; }
        private Boolean isConcat;
        private List<FieldPath> paths;
        
        public ColumnWrapper(String header, String apiName) {
            this.header = header;
            this.isConcat = apiName.startsWithIgnoreCase('CONCAT:');
            this.paths = new List<FieldPath>();
            // If field name starts with CONCAT two seprate fields are added in query
            if (this.isConcat) {
                for (String f : apiName.substringAfter('CONCAT:').split(',')) {
                    if (String.isNotBlank(f)) this.paths.add(new FieldPath(f));
                }
            } else {
                this.paths.add(new FieldPath(apiName));
            }
        }
        
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
                return String.join(values, ' ; ');
            }
        }
    }
    
    public List<ColumnWrapper> getColumns() {
        if (!isDataLoaded) loadData();
        return cachedColumns;
    }

    public List<LineGroup> getGroupedLines() {
        if (!isDataLoaded) loadData();
        return cachedGroupedLines;
    }
    
    // 
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
            // Query Quote
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
                'SBQQ__Group__r.Name', 
                'SBQQ__Group__r.Allow_Product_Ramping__c', 
                'SBQQ__Group__r.SBQQ__StartDate__c', 
                'SBQQ__Group__r.SBQQ__EndDate__c'
            };
            
            for (Email_Table__mdt col : rawColumns) {
                String fieldName = col.Field_API_Name__c != null ? col.Field_API_Name__c.trim() : '';
                Boolean isAccountField = fieldName.equalsIgnoreCase('Ship_To_Account__r.Name');
                
                if (isAccountField && !showAccountColumn) {
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
                             ' AND Quote_Line_Type__c  != \'Amendment\' ORDER BY SBQQ__Group__r.Allow_Product_Ramping__c ASC, SBQQ__Group__r.SBQQ__StartDate__c ASC NULLS LAST,SBQQ__ProductName__c ASC';
            List<SBQQ__QuoteLine__c> lineItems = Database.query(qString);
            
            // Group by Group__r.Name Field
            Map<String, List<SBQQ__QuoteLine__c>> groupedMap = new Map<String, List<SBQQ__QuoteLine__c>>();
            
            for (SBQQ__QuoteLine__c ql : lineItems) {
                SObject groupRel = ql.getSObject('SBQQ__Group__r');
                String gName = (groupRel != null && groupRel.get('Name') != null) ? String.valueOf(groupRel.get('Name')) : '';
                
                String key = String.isBlank(gName) ? 'UNGROUPED_HIDDEN_TITLE' : gName;
                
                if (!groupedMap.containsKey(key)) {
                    groupedMap.put(key, new List<SBQQ__QuoteLine__c>());
                }
                groupedMap.get(key).add(ql);
            }
            
            //
            List<String> sortedGroupNames = new List<String>(groupedMap.keySet());
			sortedGroupNames.sort();

			for (String key : sortedGroupNames) {            
                
                Boolean displayTitle = (key != 'UNGROUPED_HIDDEN_TITLE');
                String finalGroupName = displayTitle ? key : '';
                
                // Extract the new Group details from the first line item in this group
                Boolean rUp = false;
                Date sDate = null;
                Date eDate = null;
                
                if (displayTitle && !groupedMap.get(key).isEmpty()) {
                    SBQQ__QuoteLine__c firstLine = groupedMap.get(key)[0];
                    SObject groupRel = firstLine.getSObject('SBQQ__Group__r');
                    if (groupRel != null) {
                        rUp = (Boolean) groupRel.get('Allow_Product_Ramping__c');
                        sDate = (Date) groupRel.get('SBQQ__StartDate__c');
                        eDate = (Date) groupRel.get('SBQQ__EndDate__c');
                    }
                }
                
                // Pass the new variables into the LineGroup wrapper
                LineGroup groupWrap = new LineGroup(finalGroupName, displayTitle, rUp, sDate, eDate);
                
                for (SBQQ__QuoteLine__c ql : groupedMap.get(key)) {
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
}