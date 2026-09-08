public with sharing class FlowRecordsToJson {

    public class Request {
        @InvocableVariable(required=true)
        public List<SObject> records;
    }

    public class Response {
        @InvocableVariable
        public String json;
    }

    @InvocableMethod(label='Records to JSON')
    public static List<Response> run(List<Request> requests) {
        List<Response> res = new List<Response>();
        for (Request r : requests) {
            Response o = new Response();
            o.json = JSON.serialize(r.records);
            res.add(o);
        }
        return res;
    }
}