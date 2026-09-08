public with sharing class OpportunityProductEmailController {
/*    
    public Id opportunityId { get; set; }
    public String templateName { get; set; }
    
    public Boolean hasError { get; private set; }
    public String errorMessage { get; private set; }
    
    private List<ColumnWrapper> cachedColumns;
    private List<ProductGroup> cachedGroupedProducts;
    private Boolean isDataLoaded = false;

    // --- WRAPPER CLASSES ---
    public class ColumnWrapper {
        public String header { get; set; }
        public ColumnWrapper(String h) { this.header = h; }
    }
    
    public class RowWrapper {
        public List<String> cellValues { get; set; }
        public RowWrapper() { cellValues = new List<String>(); }
    }
    
    public class ProductGroup {
        public String productCode { get; set; }
        public List<RowWrapper> rows { get; set; }
        public ProductGroup(String pc) { productCode = pc; rows = new List<RowWrapper>(); }
    }

    // --- LAZY LOAD GETTERS ---
    public List<ColumnWrapper> getColumns() {
        if (!isDataLoaded) loadData();
        return cachedColumns;
    }

    public List<ProductGroup> getGroupedProducts() {
        if (!isDataLoaded) loadData();
        return cachedGroupedProducts;
    }

    // --- MAIN LOGIC ---
    private void loadData() {
        cachedColumns = new List<ColumnWrapper>();
        cachedGroupedProducts = new List<ProductGroup>();
        hasError = false;
        errorMessage = '';
        
        if (opportunityId == null || String.isBlank(templateName)) {
            isDataLoaded = true;
            return;
        }

        try {
            // 1. Fetch Columns
            List<Opportunity_Product_Email_Table__mdt> cmdtColumns = [
                SELECT Field_API_Name__c, Column_Header__c  
                FROM Opportunity_Product_Email_Table__mdt 
                WHERE Email_Template__c = :templateName
                ORDER BY Column_Order__c ASC
            ];
            
            if (cmdtColumns.isEmpty()) {
                isDataLoaded = true;
                return;
            }

            // 2. Build Dynamic SOQL
            Set<String> queryFields = new Set<String>{'ProductCode'};
            
            for (Opportunity_Product_Email_Table__mdt col : cmdtColumns) {
                cachedColumns.add(new ColumnWrapper(col.Column_Header__c));
                
                // DYNAMIC CONCAT LOGIC: Check for 'CONCAT:' prefix
                if (col.Field_API_Name__c.startsWithIgnoreCase('CONCAT:')) {
                    // Extract fields after prefix (e.g., "CONCAT:field1__c,field2__c")
                    String fieldsPart = col.Field_API_Name__c.substringAfter('CONCAT:');
                    List<String> fieldsToConcat = fieldsPart.split(',');
                    
                    for (String f : fieldsToConcat) {
                        queryFields.add(f.trim()); // Add each individual field to the SOQL query
                    }
                } else {
                    queryFields.add(col.Field_API_Name__c);
                }
            }
            
            String qString = 'SELECT Id, ' + String.join(new List<String>(queryFields), ', ') + 
                             ' FROM OpportunityLineItem WHERE OpportunityId = :opportunityId ORDER BY SortOrder ASC';
                             
            List<OpportunityLineItem> lineItems = Database.query(qString);
            
            // 3. Group by ProductCode
            Map<String, List<OpportunityLineItem>> groupedMap = new Map<String, List<OpportunityLineItem>>();
            for (OpportunityLineItem oli : lineItems) {
                String pCode = oli.ProductCode != null ? oli.ProductCode : 'No Product Code';
                if (!groupedMap.containsKey(pCode)) {
                    groupedMap.put(pCode, new List<OpportunityLineItem>());
                }
                groupedMap.get(pCode).add(oli);
            }
            
            // 4. Build Wrapper Structure
            for (String pCode : groupedMap.keySet()) {
                ProductGroup groupWrap = new ProductGroup(pCode);
                
                for (OpportunityLineItem oli : groupedMap.get(pCode)) {
                    RowWrapper rowWrap = new RowWrapper();
                    
                    for (Opportunity_Product_Email_Table__mdt col : cmdtColumns) {
                        String fieldName = col.Field_API_Name__c;
                        String finalCellValue = ''; // Variable to hold the final string for this cell
                        
                        // DYNAMIC CONCAT LOGIC: Process the combined fields
                        if (fieldName.startsWithIgnoreCase('CONCAT:')) {
                            String fieldsPart = fieldName.substringAfter('CONCAT:');
                            List<String> fieldsToConcat = fieldsPart.split(',');
                            List<String> extractedValues = new List<String>(); // Holds non-null values
                            
                            for (String f : fieldsToConcat) {
                                f = f.trim();
                                Object val = null;
                                
                                // Safe extraction (supports both standard and parent-level cross-object fields)
                                if (f.contains('.')) {
                                    List<String> parts = f.split('\\.');
                                    SObject parentObj = oli.getSObject(parts[0]);
                                    if (parentObj != null) val = parentObj.get(parts[1]);
                                } else {
                                    val = oli.get(f);
                                }
                                
                                if (val != null && String.valueOf(val).trim() != '') {
                                    extractedValues.add(String.valueOf(val));
                                }
                            }
                            
                            // Join all valid values with a space (e.g., "Value1 Value2")
                            finalCellValue = String.join(extractedValues, '; ');
                        } 
                        // STANDARD LOGIC: Handle single fields
                        else {
                            Object val = null;
                            if (fieldName.contains('.')) {
                                List<String> parts = fieldName.split('\\.');
                                SObject parentObj = oli.getSObject(parts[0]);
                                if (parentObj != null) val = parentObj.get(parts[1]);
                            } else {
                                val = oli.get(fieldName);
                            }
                            finalCellValue = val != null ? String.valueOf(val) : '';
                        }
                        
                        rowWrap.cellValues.add(finalCellValue);
                    }
                    groupWrap.rows.add(rowWrap);
                }
                cachedGroupedProducts.add(groupWrap);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'OppProductEmailController Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            hasError = true;
            errorMessage = 'We encountered an error generating the product list. Please contact your administrator.';
        } finally {
            isDataLoaded = true;
        }
    } */
}