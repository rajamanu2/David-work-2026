public class DataTableServices {
    
    @AuraEnabled(cacheable=true)
    public static DataTableResponse getDataTableColumnsAndRecordsWithQuery(String strObjectName, String strQueryString){                
        system.debug('#### calling getDataTableColumnsAndRecordsWithQuery method');
        //To hold the table headers 
        Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(strObjectName);
        List<DataTableColumns> lstDataColumns = getColumnData(strObjectName, strQueryString);
        
        //The final wrapper response to return to component
        DataTableResponse response = new DataTableResponse();
        
        //Form an SOQL to fetch the data - Set the wrapper instance and return as response
        if(strQueryString != null){            
            response.lstDataTableColumns = lstDataColumns;
            System.debug('#### getRecords method query: ' + strQueryString);
            response.lstDataTableData = Database.query(strQueryString);
        }
        
        return response;
    }
    
    @AuraEnabled(cacheable=true)
    public static DataTableResponse getDataTableColumnsAndRecords(String strObjectName, String strFieldSetName, String strWhereClause){                
        //To hold the table headers 
        List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
        
        //Field to be queried - fetched from fieldset
        List<String> lstFieldsToQuery = new List<String>();
        
        //The final wrapper response to return to component
        DataTableResponse response = new DataTableResponse();
       	
        //Get the fields from FieldSet
        Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();            
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(strFieldSetName);
        
        
        for( Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields() ){
            String label = String.valueOf(eachFieldSetMember.getLabel());
            String dataType = String.valueOf(eachFieldSetMember.getType()).toLowerCase();
            Map<String, Object> typeAttributes = new Map<String, Object>();
            Map<String, String> labelDefinition = new Map<String, String>();
            DataTableColumns datacolumns;
            
            if(dataType == 'datetime'){
                dataType = 'date';
            } else if(dataType == 'double'){
                dataType = 'number';
            }
            
            if(label == 'Record Link') {
                dataType = 'url';
                labelDefinition.put('fieldName', 'Name');
                typeAttributes.put('label', labelDefinition);
                typeAttributes.put('target', '_parent');
            }
            
            //Create a wrapper instance and store label, fieldname and type.
            if(dataType == 'url') {
             	datacolumns = new DataTableColumns( String.valueOf(eachFieldSetMember.getLabel()) , 
                                                    String.valueOf(eachFieldSetMember.getFieldPath()), 
                                                   	dataType,
                                                  	typeAttributes);
                
            }else {
             	datacolumns = new DataTableColumns( String.valueOf(eachFieldSetMember.getLabel()) , 
                                                    String.valueOf(eachFieldSetMember.getFieldPath()), 
                                                    dataType );
            }
			lstDataColumns.add(datacolumns);
            lstFieldsToQuery.add(String.valueOf(eachFieldSetMember.getFieldPath()));
        }
        
        //Form an SOQL to fetch the data - Set the wrapper instance and return as response
        if(! lstDataColumns.isEmpty()){            
            response.lstDataTableColumns = lstDataColumns;
            String query = 'SELECT Id, Name, ' + String.join(lstFieldsToQuery, ',') + ' FROM ' + strObjectName;
            query = query + ' WHERE ' + strWhereClause;
            System.debug('#### getRecords method query: ' + query);
            response.lstDataTableData = Database.query(query);
        }
        
        return response;
    }

   private static List<DataTableColumns> getColumnData(String strObjectName, String queryString) {
       String soqlFields = queryString.subString(queryString.indexOfIgnoreCase('select') + 6, queryString.indexOfIgnoreCase('from')).trim();
       List<String> soqlColumns = soqlFields.split('[,]{1}[\\s]?'); // sanitizes the spacing between commas
       List<Map<String, Object>> tableColumns = new List<Map<String, Object>>();
       Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(strObjectName);
       Map<String, Schema.SObjectField> fieldMap = SObjectTypeObj.getDescribe().fields.getMap();
       DataTableColumns datacolumns;
       List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
       
       for (String fieldName : soqlColumns){
           Schema.DescribeFieldResult field;
           Map<String, Object> fieldColumn = new Map<String, Object>();
           
           // History tables have this field, ignore this one
           if (fieldname == 'created') {
               continue;
           }
           // Handles parent relationships, to a degree
           if (fieldName.contains('.')) {
               System.debug(fieldName);
               String parentReference = fieldName.contains('__r')
                   ? fieldName.substringBeforeLast('__r.') + '__c' // custom objects
                   : fieldName.substringBeforeLast('.') + 'Id'; // standard objects typical schema
               Schema.SObjectType referenceTo = fieldMap.get(parentReference).getDescribe().getReferenceTo().get(0);
               field = referenceTo.getDescribe().fields.getMap().get(fieldName.substringAfterLast('.')).getDescribe();
               system.debug('#### derived parent refernce: ' + parentReference);
               system.debug('#### derived object: ' + referenceTo);
               system.debug('#### derived related field: ' + field);
           } else {
               System.debug(fieldName);
               if (fieldMap.containsKey(fieldName.toLowerCase().trim())) {
                  field = fieldMap.get(fieldName.toLowerCase().trim()).getDescribe(); 
               } else {
                   system.debug('#### unable to find field ' + fieldName + ' in map');
               }
               
           }
           System.debug('getColumnData field info: '+fieldName+' : '+field.getType());
           // Minor validations
           if (
               field.getType() == Schema.DisplayType.ID  // IDs are usually keyFields, so we skip display of this
               || field.getType() == Schema.DisplayType.Reference // References are lookups, need granular formatting so left to UI implementation
               || !field.isAccessible() // Respect FLS
           ) {
               continue;
           }
           // Handles parent relationships, to a degree
           if (fieldName.contains('.')) {
               fieldColumn.put('label', fieldName.substringBeforeLast('.') +' '+ field.getLabel());
               fieldColumn.put('fieldName', fieldName.replace('.', '_')); // handled clientside by DataTableServiceHelper.js
           } else {
               fieldColumn.put('label', field.getLabel());
               fieldColumn.put('fieldName', fieldName);
           }
           // Final assembly
           fieldColumn.put('type', DISPLAY_TYPE_TO_DATATABLE_TYPE_MAP.get(field.getType()));
           tableColumns.add(fieldColumn);
           datacolumns = new DataTableColumns( String.valueOf(fieldColumn.get('label')) , 
                                              String.valueOf(fieldColumn.get('fieldName')), 
                                              String.valueOf(fieldColumn.get('type')));
           lstDataColumns.add(datacolumns);
       }
       //return tableColumns;
       return lstDataColumns;
  }
    
  @AuraEnabled(cacheable=true)
  public static List<String> getFieldNames(String strObjectName, String strFieldSetName) {
        system.debug('#### calling getFieldNames with for object: ' + strObjectName + ' and field set: ' + strFieldSetName);
        List<String> listFieldNames = new List<String>();
        //Get the fields from FieldSet
        Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();            
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(strFieldSetName);
        Map<String, Schema.SobjectField> mapFieldNames = SObjectTypeObj.getDescribe().fields.getMap(); 
        Map<String, String> mapFieldLableToFieldName = new Map<String, String>();
        
        for(Schema.SObjectField field: mapFieldNames.values()) {
            mapFieldLableToFieldName.put(field.getDescribe().getLabel(), field.getDescribe().getName());
        }    
        
        for ( Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields() ){
            String fieldLabel = String.valueOf(eachFieldSetMember.getLabel());
            String fieldName = mapFieldLableToFieldName.get(fieldLabel);
            listFieldNames.add(fieldName);
            system.debug('#### field name: ' + fieldName);
        }
        
        system.debug('#### field name list returned: ' + listFieldNames);
        return listFieldNames;
    }  
    
    public static final Map<Schema.DisplayType, String> DISPLAY_TYPE_TO_DATATABLE_TYPE_MAP = new Map<Schema.DisplayType, String>{
        Schema.DisplayType.address        => 'text',
        Schema.DisplayType.anytype        => 'text',
        Schema.DisplayType.base64         => 'text',
        Schema.DisplayType.Boolean        => 'boolean',
        Schema.DisplayType.Combobox       => 'text',
        Schema.DisplayType.Currency       => 'currency',
        Schema.DisplayType.Date           => 'date-local', // my preference
        Schema.DisplayType.DateTime       => 'date-local', // my preference
        Schema.DisplayType.Double         => 'number',
        Schema.DisplayType.Email          => 'email',
        Schema.DisplayType.ID             => 'text',
        Schema.DisplayType.Integer        => 'number',
        Schema.DisplayType.MultiPicklist  => 'text',
        Schema.DisplayType.Percent        => 'percent',
        Schema.DisplayType.Phone          => 'text',
        Schema.DisplayType.Picklist       => 'text',
        Schema.DisplayType.Reference      => 'text',
        Schema.DisplayType.String         => 'text',
        Schema.DisplayType.TextArea       => 'text',
        Schema.DisplayType.Time           => 'text',
        Schema.DisplayType.URL            => 'url'
    };

    //Wrapper class to hold Columns with headers
    public class DataTableColumns {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled       
        public String fieldName {get;set;}
        @AuraEnabled
        public String type {get;set;}
        @AuraEnabled
        public Map<String, Object> typeAttributes {get;set;}
        
        //Create and set three variables label, fieldname and type as required by the lightning:datatable
        public DataTableColumns(String label, String fieldName, String type){
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;            
        }
        
        public DataTableColumns(String label, String fieldName, String type, Map<String, Object> typeAttributes){
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
            this.typeAttributes = typeAttributes;            
        }
    }
    
    //Wrapper calss to hold response. This response is used in the lightning:datatable component
    public class DataTableResponse {
        @AuraEnabled
        public List<DataTableColumns> lstDataTableColumns {get;set;}
        @AuraEnabled
        public List<sObject> lstDataTableData {get;set;}                
        
        public DataTableResponse(){
            lstDataTableColumns = new List<DataTableColumns>();
            lstDataTableData = new List<sObject>();
        }
    }
    
}