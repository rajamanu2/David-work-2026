public with sharing class FlowJsonToRecords {

    public class Request {
         @InvocableVariable(required=true)
        public String json;

        @InvocableVariable(required=true)
        public String sObjectApiName;
    }

    public class Response {
        @InvocableVariable
         public List<SObject> records;
    }

    @InvocableMethod(label='JSON to Records' description='Convert JSON into a typed sObject collection usable by Flow')
    public static List<Response> run(List<Request> requests) {

        String sObjectApiName = requests.get(0).sObjectApiName;
        String jsonString = requests.get(0).json;

        // Dynamically get the Type reference for the specified sObject name
        Type sObjectType = Type.forName('Schema.' + sObjectApiName);

        // Check if the type was found (optional but recommended)
        if (sObjectType == null) {
            System.debug('Invalid sObject name: ' + sObjectApiName);
            return null;
        }
        List<FlowJsonToRecords.Response> outputs = new List<FlowJsonToRecords.Response>();
        FlowJsonToRecords.Response output = new FlowJsonToRecords.Response();
        List<sObject> dynamicSObjectList = new List<sObject>();
        List<Object> untypedList = (List<Object>) JSON.deserializeUntyped(jsonString);

        for (Object item : untypedList) {
            String serializedItem = JSON.serialize(item);
            // Deserialize each item using the specific dynamic sObjectType
            sObject record = (sObject) JSON.deserialize(serializedItem, sObjectType);
            dynamicSObjectList.add(record);
        }

        output.records=dynamicSObjectList;
        outputs.add(output);
        return outputs;

    }

}