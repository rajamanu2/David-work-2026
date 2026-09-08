public with sharing class SlackHealthcareOppPublisher {

private static final String slackURL = 'https://hooks.slack.com/services/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';

public class Oppty {
@InvocableVariable(label='Opportunity Name')
public String opptyName;
@InvocableVariable(label='Stage')
public String stage;
@InvocableVariable(label='Prev Stage')
public String prevstage;    
}

@InvocableMethod(label='Post Healthcare to Slack')
public static void postHCToSlack(List<oppty> oppties) {
Oppty o = oppties[0]; // If bulk, only post first to avoid overloading Slack channel
Map<string,object> msg = new Map<string,object>();
msg.put('text', 'Opportunity *' + o.opptyName + '* has changed:\nFrom: *' + o.prevstage + '*' + '\nTo: *' + o.stage + '*');
msg.put('mrkdwn', true);
String body = JSON.serialize(msg); 
System.enqueueJob(new QueueableSlackCall(slackURL, 'POST', body));
}

public class QueueableSlackCall implements System.Queueable, Database.AllowsCallouts {

private final String url;
private final String method;
private final String body;

public QueueableSlackCall(String url, String method, String body) {
this.url = url;
this.method = method;
this.body = body;
}

        public void execute(System.QueueableContext ctx) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod(method);
            req.setBody(body);
            Http http = new Http();
            String responseBody;
            if (!Test.isRunningTest()) { // HTTP callout is not allowed in tests
            HttpResponse res = http.send(req);
            responseBody = res.getBody();
		}
	}
}
}